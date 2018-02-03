--------------------------------------------------------------------------------
-- Setup
--

local _, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Cooldowns", "AceTimer-3.0")
local L = scope.locale
local callbacks = LibStub("CallbackHandler-1.0"):New(module)
local LibDialog = LibStub("LibDialog-1.0")

-- luacheck: globals GameFontHighlight GameFontHighlightLarge GameTooltip_Hide

--------------------------------------------------------------------------------
-- Locals
--

local activeDisplays = {}
local frame = nil -- main options panel
local showPane, hidePane

local combatLogHandler = CreateFrame("Frame")
local combatOnUpdate = nil

local infoCache = {}
local cdModifiers, chargeModifiers = {}, {}
local spellsOnCooldown, chargeSpellsOnCooldown = nil, nil
local deadies = {}
local playerGUID = UnitGUID("player")
local _, playerClass = UnitClass("player")

local function round(num, q)
	q = 10^(q or 3)
	return floor(num * q + .5) / q
end

local function addMod(guid, spell, modifier, charges)
	if modifier ~= 0 then
		if not cdModifiers[spell] then cdModifiers[spell] = {} end
		cdModifiers[spell][guid] = (cdModifiers[spell][guid] or 0) + modifier -- amount is subtracted from the base cd
	end
	if charges then
		if not chargeModifiers[spell] then chargeModifiers[spell] = {} end
		chargeModifiers[spell][guid] = charges
	end
end

local talentCooldowns = {
	-- Death Knight
	[19227] = function(info) -- Blood: Tightening Grasp
		addMod(info.guid, 108199, 60) -- Gorefiend's Grasp
	end,
	[22024] = function(info) -- Unholy: All Will Serve
		addMod(info.guid, 46584, 60) -- Raise Dead
	end,
	[22022] = function(info) -- Lingering Apparition
		addMod(info.guid, 212552, 15) -- Wraith Walk
	end,
	-- Demon Hunter
	[21870] = function(info) -- Unleashed Power
		addMod(info.guid, 179057, 20) -- Chaos Nova
	end,
	-- Demon Hunter
	[22511] = function(info) -- Quickened Sigils
		addMod(info.guid, 202137, 12) -- Sigil of Silence
		addMod(info.guid, 207684, 12) -- Sigil of Misery
	end,
	-- Druid
	[22424] = function(info) -- Guardian: Guttural Roars
		addMod(info.guid, 106898, 60) -- Stampeding Roar
	end,
	[22422] = function(info) -- Guardian: Survival of the Fittest
		addMod(info.guid, 22812, 20) -- Barkskin
		addMod(info.guid, 61336, 60) -- Survival Instincts
	end,
	[18569] = function(info) -- Resto: Prosperity
		addMod(info.guid, 18562, 5, 2) -- Swiftmend
	end,
	[21713] = function(info) -- Resto: Inner Peace
		addMod(info.guid, 740, 60) -- Tranquility
	end,
	[21651] = function(info) -- Resto: Stonebark
		addMod(info.guid, 102342, 30) -- Ironbark
	end,
	-- Hunter
	[19361] = function(info) -- Survival: Improved Traps
		addMod(info.guid, 187650, 4.5) -- Freezing Trap (15%)
		addMod(info.guid, 187698, 15) -- Tar Trap (50%)
		addMod(info.guid, 191433, 15) -- Explosve Trap (50%)
	end,
	-- Mage
	[16025] = function(info) -- Cold Snap
		addMod(info.guid, 45438, 0, 2) -- Ice Block
	end,
	[22471] = function(info) -- Ice Ward
		addMod(info.guid, 122, 0, 2)
	end,
	-- Paladin
	[17567] = function(info) -- Holy: Unbreakable Spirit (-30%)
		addMod(info.guid, 642, 100) -- Divine Shield
		addMod(info.guid, 498, 20) -- Divine Protection
		addMod(info.guid, 633, 200) -- Lay on Hands
	end,
	-- Priest
	[22094] = function(info) -- Disc/Shadow: Psychic Voice
		addMod(info.guid, 8122, 30)
	end,
	-- Shaman
	[22492] = function(info) -- Resto: Graceful Spirit
		addMod(info.guid, 79206, 60) -- Spiritwalker's Grace
	end,
	-- Warlock
	[21182] = function(info) -- Grimoire of Supremacy
		addMod(info.guid, 1122, 180) -- Summon Infernal
		addMod(info.guid, 18540, 180) -- Summon Doomguard
	end,
	-- Warrior
	[22409] = function(info) -- Arms/Fury: Double Time
		addMod(info.guid, 100, 3, 2) -- Charge
	end,
	[22627] = function(info) -- Bounding Stride
		addMod(info.guid, 52174, 15) -- Heroic Leap
	end,
}

-- { cd, level, spec id, talent index, sync, race }
-- spec id can be a table of specs
-- talent index can be negative to indicate a talent replaces the spell
--   and can be a hash of spec=index for talents in different locations
-- sync will register SPELL_UPDATE_COOLDOWN and send "CooldownUpdate" syncs
--   with the cd (for dynamic cooldowns with hard to track conditions)
local spells = {
	DEATHKNIGHT = {
		[221562] = {45, 55, 250}, -- Asphyxiate
		[49576] = {25, 55}, -- Death Grip
		[46584] = {60, 55, 252}, -- Raise Dead
		[48707] = {60, 57}, -- Anti-Magic Shell
		[43265] = {30, 56, {250, 252}}, -- Death and Decay
		[49028] = {180, 57, 250}, -- Dancing Rune Weapon
		[47568] = {180, 57, 251, -8}, -- Empower Rune Weapon
		[51271] = {60, 57, 251, nil, true}, -- Pillar of Frost (Frost): (7) Your Frost Strike, Frostscythe, and Obliterate critical strikes reduce the remaining cooldown  by 1 sec.
		[196770] = {20, 57, 251}, -- Remorseless Winder
		[55233] = {90, 57, 250, nil, true}, -- Vampiric Blood (Blood): (11) Spending Runic Power will decrease the remaining cooldown by 2 sec per 10 Runic Power.
		[212552] = {60, 60}, -- Wraith Walk
		[47528] = {15, 62}, -- Mind Freeze
		[108199] = {180, 64, 250}, -- Gorefiend's Grasp
		[48792] = {180, 65, {251, 252}}, -- Icebound Fortitude
		[61999] = {600, 72}, -- Raise Ally
		[63560] = {60, 74, 252}, -- Dark Transformation
		[49206] = {180, 75, 252}, -- Summon Gargoyle
		[42650] = {600, 82, 252}, -- Army of the Dead

		[206931] = {30, 56, 250, 3}, -- Blooddrinker
		[207317] = {10, 57, 252, 4}, -- Epidemic (3 charges)
		[57330] = {30, 57, 251, 6}, -- Horn of Winter
		[221699] = {60, 58, 250, 8, false}, -- Blood Tap (2 charges) (Blood): (8) Recharge time reduced by 1 sec whenever a Bone Shield charge is consumed. XXX Charge syncing NYI
		[207127] = {180, 58, 251, 8}, -- Hungering Rune Weapon
		[108194] = {45, 60, 252, 11}, -- Asphyxiate
		[207319] = {60, 75, 252, 14}, -- Corpse Shield
		[194679] = {25, 90, 250, 17}, -- Rune Tap (2 charges)
		[194844] = {60, 100, 250, 19}, -- Bonestorm
		[207349] = {180, 100, 252, 19}, -- Dark Arbiter
		[206977] = {120, 100, 250, 20}, -- Blood Mirror
		[152279] = {120, 100, 251, 20}, -- Breath of Sindragosa
		[152280] = {30, 100, 252, 20}, -- Defile
		[194913] = {15, 100, 251, 21}, -- Glacial Advance
		[130736] = {45, 100, 252, 21}, -- Soul Reaper
	},
	DEMONHUNTER = {
		-- [198589] = {60, 1, 577, -10}, -- Blur XXX No SPELL_CAST_SUCCESS
		[183752] = {15, 1}, -- Consume Magic
		[179057] = {60, 1, 577}, -- Chaos Nova
		[196718] = {180, 1, 577}, -- Darkness
		[218256] = {20, 100, 581}, -- Empower Wards
		[204021] = {60, 1, 581}, -- Fiery Brand
		[200166] = {300, 1, 577}, -- Metamorphosis (Havoc)
		[187827] = {180, 1, 581}, -- Metamorphosis (Vengeance)
		[207684] = {60, 100, 581}, -- Sigil of Misery
		[202137] = {60, 100, 581}, -- Sigil of Silence

		[211881] = {35, 102, nil, {[577]=14,[581]=9}}, -- Fel Eruption, 106 Havoc / 102 Vengeance
		[196555] = {90, 104, 577, 0000}, -- Netherwalk
		[202138] = {120, 106, 581, 14}, -- Sigil of Chains
		[207810] = {120, 110, 581, 20}, -- Nether Bond
		[227225] = {20, 110, 581, 21}, -- Soul Barrier
	},
	DRUID = {
		[5217]  = {30, 12, 103, nil, true}, -- Tiger's Fury (Feral): (1) The cooldown resets when a target dies with one of your Bleed effects active.
		[18562] = {30, 12, 105}, -- Swiftmend
		[1850]  = {180, 24}, -- Dash
		[20484] = {600, 56}, -- Rebirth
		[78675] = {60, 28, 102}, -- Solar Beam
		[99] = {30, 28, 104}, -- Incapacitating Roar
		[22812] = {60, 36, {102, 104, 105}}, -- Barkskin
		[61336] = {180, 40, {103, 104}}, -- Survival Instincts (2 charges)
		[106951] = {180, 48, 103, -14}, -- Berserk
		[102793] = {60, 48, 105}, -- Ursol's Vortex
		[29166] = {180, 50, {102, 105}}, -- Innervate
		[22842] = {24, 50, 104}, -- Frenzied Regeneration (2 charges)
		[102342] = {90, 52, 105}, -- Ironbark
		[194223] = {180, 64, 102, -14}, -- Celestial Alignment
		[106839] = {15, 64, {103, 104}}, -- Skull Bash
		[740]   = {180, 72, 105}, -- Tranquility
		[106898] = {120, 83, {103, 104}}, -- Stampeding Roar

		[205636] = {60, 15, 102, 1}, -- Force of Nature
		[202425] = {45, 15, 102, 2}, -- Warrior of Elune
		[155835] = {40, 15, 104, 2}, -- Bristling Fur
		[102351] = {30, 15, 105, 2}, -- Cenarion Ward
		[108238] = {120, 30, {102, 103, 105}, 4}, -- Renewel
		[102280] = {30, 30, nil, 5}, -- Displacer Beast
		[132302] = {15, 30, nil, 6}, -- Wild Charge
		[16979] = 132302, -- Wild Charge (Bear)
		[49376] = 132302, -- Wild Charge (Cat)
		[102383] = 132302, -- Wild Charge (Moonkin)
		[102416] = 132302, -- Wild Charge (Aquatic)
		[102417] = 132302, -- Wild Charge (Travel)
		-- XXX 45 talents add spells exclusive to other specs...WHATDO?!
		[5211] = {50, 60, nil, 10}, -- Mighty Bash
		[102359] = {30, 60, nil, 11}, -- Mass Entanglement
		[132469] = {30, 60, nil, 12}, -- Typhoon
		[61391] = 132469, -- Typhoon (actual event)
		[102560] = {180, 75, 102, 14}, -- Incarnation: Chosen of Elune
		[102543] = {180, 75, 103, 14}, -- Incarnation: King of the Jungle
		[102558] = {180, 75, 104, 14}, -- Incarnation: Guardian of Ursoc
		[33891]  = {180, 75, 105, 14}, -- Incarnation: Tree of Life
		[202359] = {80, 90, 102, 17}, -- Astral Communion
		[202360] = {15, 90, 102, 18}, -- Blessing of the Ancients
		[202060] = {45, 90, 103, 18}, -- Elune's Guidance
		[202770] = {90, 100, 102, 19}, -- Fury of Elune
		[204066] = {90, 100, 104, 20}, -- Lunar Beam
		[197721] = {60, 100, 105, 21}, -- Flourish
	},
	HUNTER = {
		[136] = {10, 1}, -- Mend Pet
		[186257] = {180, 5}, -- Aspect of the Cheetah
		[781] = {20, 14, {253, 254}, nil, true}, -- Disengage (not-Survival): (8) Your ability critical strikes have a 10% chance to reset the remaining cooldown.
		[193530] = {120, 18, 253}, -- Aspect of the Wild
		[186387] = {30, 22, 254}, -- Bursting Shot
		[190925] = {20, 22, 255, nil, true}, -- Harpoon (Survival): (8) Your ability critical strikes have a 10% chance to reset the remaining cooldown.
		[147362] = {24, 24, {253, 254}}, -- Counter Shot
		[187707] = {15, 24, 255}, -- Muzzle
		[187650] = {30, 28, 255, -12}, -- Freezing Trap
		[5384]  = {30, 32}, -- Feign Death
		[109304] = {120, 36, {253, 255}, nil, true}, -- Exhilaration (Marksman): After you kill a target, the remaining cooldown is reduced by 30 sec.
		[1543] = {20, 38}, -- Flare
		[61648] = {180, 40}, -- Aspect of the Chameleon
		[19574] = {90, 40, 253}, -- Bestial Wrath
		[193526] = {180, 40, 254}, -- Trueshot
		[34477] = {30, 42, {253, 254}}, -- Misdirection
		[187698] = {30, 42, 255}, -- Tar Trap
		[186289] = {120, 44, 255}, -- Aspect of the Eagle
		[191433] = {30, 48, 255}, -- Explosive Trap
		[186265] = {180, 50}, -- Aspect of the Turtle

		[206505] = {60, 30, 255, 4, true}, -- A Murder of Crows (Survival): (4) If the target dies while under attack, the cooldown is reset.
		[201078] = {90, 30, 255, 6}, -- Snake Hunter
		[212431] = {30, 60, 254, 10}, -- Explosive Shot
		[194277] = {15, 60, 255, 10}, -- Caltrops
		[206817] = {30, 60, 254, 11}, -- Sentinel (2 charges)
		[162488] = {60, 60, 255, 12}, -- Steel Trap
		[109248] = {45, 75, {253, 254}, 13}, -- Binding Shot
		[191241] = {30, 75, 255, 13}, -- Sticky Bomb
		[19386] = {45, 75, {253, 254}, 14}, -- Wyvern Sting
		[19577] = {60, 75, 253, 15}, -- Intimidation
		[199483] = {60, 75, {254, 255}, 15}, -- Camouflage
		[131894] = {60, 90, {253, 254}, 16, true}, -- A Murder of Crows (not-Survival): (16) If the target dies while under attack, the cooldown is reset.
		[120360] = {20, 90, {253, 254}, 17}, -- Barrage
		[194855] = {30, 90, 255, 17}, -- Dragonsfire Grenade
		[194386] = {90, 90, {253, 254}, 18}, -- Volley
		[201430] = {180, 100, 253, 19}, -- Stampede
		[194407] = {60, 100, 255, 19}, -- Splitting Cobra
		-- Pet
		[90355]  = {360, 20}, -- Ancient Hysteria
		[160452] = {360, 20}, -- Netherwinds
		[126393] = {600, 20}, -- Eternal Guardian
		[159956] = {600, 20}, -- Dust of Life
		[159931] = {600, 20}, -- Gift of Chi-Ji
	},
	MAGE = {
		[122]   = {30, 3, nil}, -- Frost Nova
		[1953]  = {15, 7, nil, -4}, -- Blink
		[31687] = {60, 10, 64}, -- Summon Water Elemental
		[11426] = {25, 16}, -- Ice Barrier
		[195676] = {30, 24, 62}, -- Displacement
		[31661] = {20, 62, 63}, -- Dragon's Breath
		[45438] = {300, 26, nil}, -- Ice Block
		[135029] = {25, 32, 64}, -- Water Jet
		[190319] = {120, 28, 63}, -- Combustion
		[2139]  = {24, 34}, -- Counterspell
		[120]   = {12, 36, 64}, -- Cone of Cold
		[12051] = {120, 40, 62}, -- Evocation
		[12472] = {180, 40, 64}, -- Icy Veins
		[12042] = {90, 44, 62}, -- Arcane Power
		[110959] = {120, 50, 62}, -- Greater Invisibility
		[66]    = {300, 50, {63, 64}}, -- Invisibility
		[80353] = {300, 65}, -- Time Warp
		[84714] = {60, 83, 64}, -- Frozen Orb

		[205021] = {60, 15, 64, 1}, -- Ray of Frost
		[205025] = {60, 15, 62, 2}, -- Presence of Mind
		[212653] = {15, 30, nil, 4}, -- Shimmer
		[55342]  = {120, 45, nil, 7}, -- Mirror Image
		[116011] = {120, 45, nil, 8}, -- Rune of Power (2 charges)
		[157980] = {25, 60, 62, 10}, -- Supernova
		[157981] = {25, 60, 63, 10}, -- Blast Wave
		[157997] = {25, 60, 64, 10}, -- Ice Nova
		[205032] = {40, 60, 62, 11}, -- Charged Up
		[205029] = {40, 60, 63, 11}, -- Flame On
		[205030] = {30, 60, 64, 11}, -- Frozen Touch
		[108839] = {20, 60, nil, 13}, -- Ice Floes (3 charges)
		[113724] = {45, 60, nil, 14}, -- Ring of Frost
		[44457]  = {12, 90, 63, 16}, -- Living Bomb
		[198929] = {9, 90, 63, 20}, -- Cinderstorm
		[153626] = {20, 100, 62, 21}, -- Arcane Orb
		[153561] = {45, 100, 63, 21}, -- Meteor
		[153595] = {30, 100, 64, 21}, -- Comet Storm
	},
	MONK = {
		[101545] = {25, 10, 269}, -- Flying Serpent Kick
		[122470] = {90, 22, 269}, -- Touch of Karma
		[115203] = {420, 24, 268}, -- Fortifying Brew
		[115080] = {120, 24, 269}, -- Touch of Death
		[116849] = {180, 28, 270}, -- Life Cocoon
		[116705] = {15, 32, {268, 269}}, -- Spear Hand Strike
		[115078] = {15, 48}, -- Paralysis
		[116680] = {30, 54, 270}, -- Thunder Focus Tea
		[115176] = {300, 65, 268}, -- Zen Meditation
		[115310] = {180, 65, 270}, -- Revival

		[197945] = {20, 15, 270, 3}, -- Mistwalk (2 charges)
		[116841] = {30, 30, nil, 5}, -- Tiger's Lust
		[115288] = {60, 45, 269, 7}, -- Energizing Elixir
		[115399] = {90, 45, 269, 8}, -- Black Ox Brew
		[116844] = {45, 60, nil, 10}, -- Ring of Peace
		[198898] = {30, 60, 270, 11}, -- Song of Chi-Ji
		[119381] = {45, 60, nil, 12}, -- Leg Sweep
		[122783] = {120, 75, nil, 14}, -- Diffuse Magic
		[122278] = {120, 75, nil, 15}, -- Dampen Harm
		[132578] = {180, 90, 268, 17}, -- Invoke Niuzao, the Black Ox
		[123904] = {180, 90, 269, 17}, -- Invoke Xuen, the White Tiger
		[198664] = {180, 90, 270, 17}, -- Invoke Chi-Ji, the Red Crane
		[152173] = {90, 100, 269, 21}, -- Serenity
	},
	PALADIN = {
		[853] = {60, 5, nil, nil, true}, -- Hammer of Justice: (7) Judgement reduces the remaining cooldown by 10 sec.
		[31935] = {15, 10, 66, nil, true}, -- Avenger's Shield (Protection): When you avoid a melee attack or use Hammer of the Righteous, you have a 15% chance to reset the remaining cooldown.
		[642] = {300, 18}, -- Divine Shield
		[633] = {600, 22}, -- Lay on Hands
		[1044] = {25, 52}, -- Blessing of Freedom
		[498] = {60, 26, {65, 66}}, -- Divine Protection
		[96231] = {15, 36, {66, 70}}, -- Rebuke
		[1022] = {300, 48, nil, {[66]=-10}}, -- Blessing of Protection
		[6940] = {150, 56, {65, 66}}, -- Blessing of Sacrifice
		[31821] = {180, 65, 65}, -- Aura Mastery
		[31850] = {120, 65, 66}, -- Ardent Defender
		[31842] = {120, 72, 65}, -- Avenging Wrath (Holy)
		[31884] = {120, 72, {65, 70}}, -- Avenging Wrath (Prot/Ret)
		[86659] = {300, 83, 66}, -- Guardian of Ancient Kings

		[114158] = {60, 15, 65, 2}, -- Light's Hammer
		[20066] = {15, 45, nil, 8}, -- Repentance
		[115750] = {90, 30, nil, 9}, -- Blinding Light
		[204018] = {180, 60, 66, 10}, -- Blessing of Spellwarding
		[105809] = {120, 75, 65, 14}, -- Holy Avenger
		[114165] = {20, 75, 65, 15}, -- Holy Prism
		[205191] = {60, 75, 70, 14}, -- Eye for an Eye
		[204150] = {300, 90, 66, 16}, -- Aegis of Light
		[152262] = {30, 100, 66, 20}, -- Seraphim
	},
	PRIEST = {
		[8122]  = {60, 12, {256, 258}, {[258]=-7}}, -- Psychic Scream
		[586]   = {30, 38}, -- Fade
		[32375] = {15, 72}, -- Mass Dispel
		[34433] = {180, 40, {256, 258}, {[256]=-12,[258]=-18}}, -- Shadowfiend
		[47536] = {120, 50, 256}, -- Rapture
		[15487] = {45, 50, 258}, -- Silence
		[47788] = {240, 54, 257, nil, true}, -- Guardian Spirit (Holy): (11) When Guardian Spirit expires without saving the target from death, reduce its remaining cooldown to 120 seconds.
		[33206] = {240, 56, 256}, -- Pain Suppression
		[47585] = {120, 58, 258}, -- Dispersion
		[62618] = {180, 65, 256}, -- Power Word: Barrier
		[15286] = {180, 65, 258}, -- Vampiric Embrace
		[64843] = {180, 76, 257}, -- Divine Hymn
		[73325] = {90, 83, {256, 257}}, -- Leap of Faith

		[19236] = {90, 30, 257, 6}, -- Desperate Prayer
		[204263] = {60, 45, {256, 257}, 7}, -- Shining Force
		[205369] = {30, 45, 258, 7}, -- Mind Bomb
		[123040] = {60, 60, {256, 258}, {[256]=12,[258]=18}}, -- Mindbender (Disc: 60, Shadow: 90)
		[200174] = 123040, -- Mindbender (Shadow)
		[64901] = {360, 60, 257, 12}, -- Hymn of Hope
		[10060] = {120, 75, {256, 258}, {[256]=14,[258]=16}}, -- Power Infusion (Disc: 75, Shadow: 90)
		[120517] = {40, 90, {256, 257}, 18}, -- Halo
		[200183] = {180, 100, 257, 19}, -- Apotheosis
	},
	ROGUE = {
		-- True Bearing (Outlaw) For the duration of Roll the Bones, each time you use a finishing move, you reduce the remaining cooldown on .. by 2 sec per combo point spent.
		[5277]  = {120, 8, {259, 261}}, -- Evasion
		[199754] = {120, 10, 260, nil, true}, -- Riposte (True Bearing)
		[36554] = {30, 13, 261}, -- Shadowstep
		[185311] = {30, 14}, -- Crimson Vial
		[1766] = {15, 18}, -- Kick
		[1776]  = {10, 22, 260}, -- Gouge
		[2983] = {60, 26, nil, nil, true}, -- Sprint (True Bearing)
		[1725] = {30, 28}, -- Distract
		[1856] = {120, 32, nil, nil, true}, -- Vanish (True Bearing)
		[2094] = {120, 38, {260, 261}, nil, true}, -- Blind (True Bearing)
		[408] = {20, 40, {259, 261}}, -- Kidney Shot
		[31224] = {60, 58, nil, nil, true}, -- Cloak of Shadows (True Bearing)
		[57934] = {30, 64}, -- Tricks of the Trade
		[79140] = {120, 72, 259}, -- Vendetta
		[13750] = {180, 72, 260, nil, true}, -- Adrenaline Rush (True Bearing)
		[121471] = {180, 72, 261}, -- Shadow Blades

		[195457] = {30, 30, 260, 4, true}, -- Grappling Hook (True Bearing)
		[185767] = {60, 90, 260, 16, true}, -- Cannonball Barrage (True Bearing)
		[200806] = {45, 90, 259, 18}, -- Exsanguinate
		[51690] = {120, 90, 260, 18, true}, -- Killing Spree (True Bearing)
		[137619] = {60, 100, nil, 20, true}, -- Marked for Death: (20) Cooldown reset if the target dies within 1 min.
	},
	SHAMAN = {
		[51514] = {39, 42, nil, -9}, -- Hex
		[108271] = {90, 44}, -- Astral Shift
		[51490] = {45, 16, 262}, -- Thunderstorm
		[57994] = {12, 22}, -- Wind Shear
		[20608] = {1800, 32}, -- Reincarnation
		[21169] = 20608, -- Reincarnation (Resurrection)
		[198067] = {300, 48, 262, -16}, -- Fire Elemental
		[51533] = {120, 48, 263}, -- Feral Spirit
		[108280] = {180, 54, 264}, -- Healing Tide Totem
		[98008] = {180, 62, 264}, -- Spirit Link Totem
		[UnitFactionGroup("player") == "Horde" and 2825 or 32182] = {300, 65}, -- Bloodlust/Heroism
		[198103] = {120, 72, 262}, -- Earth Elemental
		[58875] = {60, 72, 262}, -- Spirit Walk
		[79206] = {120, 72, 264}, -- Spiritwalker's Grace

		[201898] = {45, 15, 263, 1}, -- Windsong
		[192063] = {15, 30, {262, 264}, 4}, -- Gust of Wind
		[108281] = {120, 30, {262, 264}, {[262]=5, [264]=11}}, -- Ancestral Guidance (Ele: 30, Resto: 60)
		[196884] = {30, 30, 263, 5}, -- Feral Lunge
		[192077] = {120, 30, nil, 6}, -- Wind Rush Totem
		[192058] = {45, 45, nil, 7}, -- Lightning Surge Totem
		[51485] = {30, 45, nil, 8}, -- Earthgrab Totem
		[196932] = {30, 45, nil, 9}, -- Voodoo Totem
		[207399] = {300, 75, 264, 13}, -- Ancestral Protection Totem
		[198838] = {60, 75, 264, 14}, -- Earthen Shield Totem
		[16166] = {120, 90, 262, 16}, -- Elemental Mastery
		[192249] = {300, 90, 262, 17}, -- Storm Elemental
		[157153] = {30, 90, 264, 17}, -- Cloudburst Totem
		[197214] = {40, 90, 263, 18}, -- Sundering
		[114049] = {180, 100, nil, 19}, -- Ascendance (old id, but keeping it for compat as the master option for the 3 merged spells)
		[114050] = 114049, -- Ascendance (Elemental)
		[114051] = 114049, -- Ascendance (Enhancement)
		[114052] = 114049, -- Ascendance (Restoration)
	},
	WARLOCK = {
		[20707] = {600, 18}, -- Soulstone
		[95750] = 20707, -- Soulstone Resurrection (combat)
		[1122]  = {180, 50}, -- Summon Infernal
		[18540] = {180, 58}, -- Summon Doomguard
		[104773] = {180, 62}, -- Unending Resolve
		[29893] = {120, 65}, -- Create Soulwell
		[698]   = {120, 72}, -- Ritual of Summoning

		[152108] = {45, 30, 267, 5}, -- Cataclysm
		[6789]  = {45, 45, nil, 8}, -- Mortal Coil
		[5484]  = {40, 45, 265, 9}, -- Howl of Terror
		[30283] = {30, 45, {266, 267}, 9}, -- Shadowfury
		[196098] = {120, 60, nil, 12}, -- Soul Harvest
		[48020] = {30, 75, nil, 13}, -- Demonic Circle: Teleport
		[108416] = {60, 75, nil, 15}, -- Dark Pact
		-- Pet
		[19647]  = {24, 50}, -- Felhunter Spell Lock (Normal, originates from pet)
		[119910] = 19647,    -- Felhunter Spell Lock (via Command Demon, originates from player)
		[171138] = 19647,    -- Doomguard Shadow Lock (Normal, originates from pet)
		[171140] = 19647,    -- Doomguard Shadow Lock (via Command Demon, originates from player)
	},
	WARRIOR = {
		[100]   = {20, 3}, -- Charge
		[184364] = {120, 12, 72}, -- Enraged Regeneration
		[6552]  = {15, 24}, -- Pummel
		[52174]  = {45, 26}, -- Heroic Leap
		[12975] = {180, 36, 73, nil, true}, -- Last Stand (Anger Management)
		[18499]  = {60, 40}, -- Berserk Rage
		[871]   = {240, 48, 73, nil, true}, -- Shield Wall (Anger Management)
		[118038]  = {180, 50, 71}, -- Die by the Sword
		[1160] = {90, 50, 73}, -- Demoralizing Shout
		[1719] = {60, 60, nil, nil, true}, -- Battle Cry (Anger Management)
		[23920] = {25, 65, 73}, -- Spell Reflection
		[5246]  = {90, 70, {71, 72}}, -- Intimidating Shout
		[198304] = {15, 72, 73}, -- Intercept
		[227847] = {90, 75, 71, -21}, -- Bladestorm
		[97462] = {180, 83, {71, 72}}, -- Commanding Shout

		[46968] = {40, 30, nil, {[71]=4,[72]=4,[73]=1}, true}, -- Shockwave: Cooldown reduced by 20 sec if it strikes at least 3 targets.
		[107570] = {30, 30, nil, {[71]=5,[72]=5,[73]=2}}, -- Storm Bolt
		[107574] = {90, 45, nil, 9}, -- Avatar
		[12292] = {30, 90, 72, 16}, -- Bloodbath
		-- Anger Management (Arms/Protection): (19) Every 10 Rage you spend reduces the remaining cooldown on Battle Cry, Last Stand, and Shield Wall by 1 sec.
		[46924] = {90, 100, 72, 19}, -- Bladestorm
		[152277] = {60, 100, {71, 73}, 21}, -- Ravager
		[228920] = 152277, -- Ravager (Prot)
		[118000] = {25, 100, 72, 21}, -- Dragon Roar
	},
	RACIAL = {
		--  Arcane Torrent (Blood Elf)
		[28730] = {90, 1, nil, nil, nil, "BloodElf"}, -- Mage, Warlock
		[25046] = 28730,  -- Rogue
		[50613] = 28730,  -- Death Knight
		[69179] = 28730,  -- Warrior
		[80483] = 28730,  -- Hunter
		[129597] = 28730, -- Monk
		[155145] = 28730, -- Paladin
		[202719] = 28730, -- Demon Hunter
		[232633] = 28730, -- Priest
		-- Gift of the Naaru (Draenei)
		[28880] = {180, 1, nil, nil, nil, "Draenei"}, -- Warrior
		[59542] = 28880,  -- Paladin
		[59543] = 28880,  -- Hunter
		[59544] = 28880,  -- Priest
		[59545] = 28880,  -- Death Knight
		[59547] = 28880,  -- Shaman
		[59548] = 28880,  -- Mage
		[121093] = 28880, -- Monk
		-- Blood Fury (Orc)
		[33697] = {120, 1, nil, nil, nil, "Orc"}, -- Shaman, Monk (Attack power and spell power)
		[20572] = 33697, -- Warrior, Hunter, Rogue, Death Knight (Attack power)
		[33702] = 33697, -- Mage, Warlock (Spell power)
		--
		[20594] = {120, 1, nil, nil, nil, "Dwarf"}, -- Stoneform (Dwarf)
		[20589] = {60, 1, nil, nil, nil, "Gnome"}, -- Escape Artist (Gnome)
		[69041] = {90, 1, nil, nil, nil, "Goblin"}, -- Rocket Barrage (Goblin)
		[69070] = {90, 1, nil, nil, nil, "Goblin"}, -- Rocket Jump (Goblin)
		[255654] = {120, 1, nil, nil, nil, "HighmountainTauren"}, -- Bull Rush (Highmountain Tauren)
		[59752] = {120, 1, nil, nil, nil, "Human"}, -- Every Man for Himself (Human)
		[255647] = {150, 1, nil, nil, nil, "LightforgedDraenei"}, -- Light's Judgement (Lightforged Draenei)
		[58984] = {120, 1, nil, nil, nil, "NightElf"}, -- Shadowmeld (Night Elf)
		[260364] = {180, 1, nil, nil, nil, "Nightborne"}, -- Arcane Pulse (Nightborne)
		[107079] = {120, 1, nil, nil, nil, "Pandaren"}, -- Quaking Palm (Pandaren)
		[20549] = {90, 1, nil, nil, nil, "Tauren"}, -- War Stomp (Tauren)
		[26297] = {180, 1, nil, nil, nil, "Troll"}, -- Berserking (Troll)
		[7744] = {120, 1, nil, nil, nil, "Scourge"}, -- Will of the Forsaken (Undead)
		[20577] = {120, 1, nil, nil, nil, "Scourge"}, -- Cannibalize (Undead)
		[256948] = {120, 1, nil, nil, nil, "VoidElf"}, -- Spatial Rift (Void Elf)
		[68992] = {120, 1, nil, nil, nil, "Worgen"}, -- Darkflight (Worgen)
	}
}

local combatResSpells = {
	[20484] = true,  -- Rebirth
	[95750] = true,  -- Soulstone Resurrection
	[61999] = true,  -- Raise Ally
	[126393] = true, -- Eternal Guardian
	[159956] = true, -- Dust of Life
	[159931] = true, -- Gift of Chi-Ji
}

local chargeSpells = {
	-- Death Knight
	[207317] = 2, -- Epidemic
	[221699] = 2, -- Blood Tap
	[194679] = 2, -- Rune Tap
	-- Druid
	[61336] = 2, -- Survival Instincts
	[22842] = 2, -- Frenzied Regeneration
	-- Hunter
	[206817] = 2, -- Sentinel
	-- Mage
	[212653] = 2, -- Shimmer
	[116011] = 2, -- Rune of Power
	[108839] = 3, -- Ice Floes
	-- Monk
	[197945] = 2, -- Mistwalk
	-- Warrior
	[198304] = 2, -- Intercept
}


local mergeSpells = {}
local allSpells = {}
local classLookup = {}
local syncSpells = {}
for class, classSpells in next, spells do
	for spellId, info in next, classSpells do
		if type(info) == "number" then
			-- merge multiple ids into one option
			mergeSpells[spellId] = info
			info = classSpells[info]
			classSpells[spellId] = nil
		end
		if GetSpellInfo(spellId) then
			allSpells[spellId] = info
			classLookup[spellId] = class
			if class == playerClass and info[5] then
				syncSpells[spellId] = true -- info[4] or true
			end
		else
			print("oRA3: Invalid spell id", spellId)
		end
	end
end
module.classLookup = classLookup
module.allSpells = allSpells


function module:GetPlayerFromGUID(guid)
	if infoCache[guid] then
		return infoCache[guid].name, infoCache[guid].class
	end
end

function module:IsSpellUsable(guid, spellId)
	local info = infoCache[guid]
	if not info then return end
	local data = spells[info.class][spellId]
	if not data then return false end

	local _, level, spec, talent, _, race = unpack(data)
	if type(talent) == "table" then
		talent = talent[info.spec]
		-- we already matched the spec, so just decide based on talent
		if talent ~= nil then
			spec = nil
		end
	end
	local usable = (info.level >= level) and (not race or info.race == race) and
		(not talent or ((talent > 0 and info.talents[talent]) or (talent < 0 and not info.talents[-talent]))) and -- handle talents replacing spells (negative talent index)
		(not spec or spec == info.spec or (type(spec) == "table" and tContains(spec, info.spec)))

	return usable
end

function module:CheckFilter(display, player)
	-- returns => true = show, nil = hide
	if not UnitExists(player) then return end
	local db = display.filterDB
	local info = infoCache[UnitGUID(player)]
	local isMe = UnitIsUnit(player, "player")

	if db.showOnlyMine and not isMe then return end
	if db.neverShowMine and isMe then return end
	if db.hideDead and UnitIsDeadOrGhost(player) then return end
	if db.hideOffline and not UnitIsConnected(player) then return end
	--if db.hideOutOfCombat and InCombatLockdown() and not UnitAffectingCombat(player) then return end
	if db.hideOutOfRange and not isMe and not UnitInRange(player) then return end
	--if db.hideNameList[player] then return end

	local group = IsInRaid() and "raid" or IsInGroup() and "party" or "solo"
	if db.hideInGroup[group] then return end

	local role = info and GetSpecializationRoleByID(info.spec or 0) or UnitGroupRolesAssigned(player)
	if db.hideRoles[role] then return end

	local inInstance, instanceType = IsInInstance() -- this should really act on the display itself
	if inInstance and db.hideInInstance[instanceType] then return end
	if db.hideInInstance.lfg and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return end

	local index = info and info.unit:match("raid(%d+)")
	if index then
		local _, _, group = GetRaidRosterInfo(index)
		if db.hideGroup[group] then return end
	end

	return true
end

function module:GetCooldown(guid, spellId)
	local cd = allSpells[spellId][1]
	if cdModifiers[spellId] and cdModifiers[spellId][guid] then
		cd = cd - cdModifiers[spellId][guid]
	end
	return cd
end

function module:GetRemainingCooldown(guid, spellId)
	if spellsOnCooldown[spellId] and spellsOnCooldown[spellId][guid] then
		local remaining = spellsOnCooldown[spellId][guid] - GetTime()
		return remaining or 0
	end
	return 0
end

function module:GetCharges(guid, spellId)
	return chargeModifiers[spellId] and chargeModifiers[spellId][guid] or chargeSpells[spellId] or 0
end

function module:GetRemainingCharges(guid, spellId)
	local charges = self:GetCharges(guid, spellId)
	if charges > 0 and chargeSpellsOnCooldown[spellId] and chargeSpellsOnCooldown[spellId][guid] then
		return charges - #chargeSpellsOnCooldown[spellId][guid]
	end
	return charges
end

function module:GetRemainingChargeCooldown(guid, spellId)
	local expires = chargeSpellsOnCooldown[spellId] and chargeSpellsOnCooldown[spellId][guid]
	if expires and #expires > 0 then
		return expires[1] - GetTime()
	end
	return self:GetCooldown(guid, spellId)
end


local function updatePlayerCooldownsBySpell(info, spellId)
	local guid, name, class = info.guid, info.name, info.class

	if module:IsSpellUsable(guid, spellId) then
		local cd = module:GetRemainingCooldown(guid, spellId)
		if cd > 0 then
			callbacks:Fire("oRA3CD_StartCooldown", guid, name, class, spellId, cd)
		else
			callbacks:Fire("oRA3CD_CooldownReady", guid, name, class, spellId)
		end
	end

	local maxCharges = module:GetCharges(guid, spellId)
	if maxCharges > 0 then
		callbacks:Fire("oRA3CD_UpdateCharges", guid, name, class, spellId, module:GetRemainingChargeCooldown(guid, spellId), module:GetRemainingCharges(guid, spellId), maxCharges, true)
	end
end

local function updateCooldownsBySpell(spellId)
	callbacks:Fire("oRA3CD_StopCooldown", nil, spellId)
	for _, info in next, infoCache do
		updatePlayerCooldownsBySpell(info, spellId)
	end
end

local function updateCooldownsByGUID(guid)
	local info = infoCache[guid]
	for spellId in next, spells[info.class] do
		callbacks:Fire("oRA3CD_StopCooldown", guid, spellId)
		updatePlayerCooldownsBySpell(info, spellId)
	end
end

local function updateCooldowns()
	for guid in next, infoCache do
		updateCooldownsByGUID(guid)
	end
end


--------------------------------------------------------------------------------
-- Options
--

do
	local ACR = LibStub("AceConfigRegistry-3.0")
	local ACD = LibStub("AceConfigDialog-3.0")
	local AceGUI = LibStub("AceGUI-3.0")
	local CURRENT_DISPLAY = "Default"

	local spellList, reverseClass = nil, {}
	local function SpawnTestBar()
		local display = CURRENT_DISPLAY and activeDisplays[CURRENT_DISPLAY]
		if not display or type(display.TestCooldown) ~= "function" then return end

		if not spellList then
			spellList = {}
			for k in next, allSpells do
				if classLookup[k] ~= "RACIAL" then
					spellList[#spellList + 1] = k
				end
			end
			for name, class in next, oRA._testUnits do
				reverseClass[class] = name
			end
		end

		local spellId = spellList[math.random(1, #spellList)]
		local class = classLookup[spellId]
		local duration = (allSpells[spellId][1] / 30) + math.random(1, 120)
		display:TestCooldown(reverseClass[class], class, spellId, duration)
	end

	local tmp = {}
	local tabStatus, classStatus, filterStatus = { selected = "tab1", scrollvalue = 0 }, { selected = "ALL", scrollvalue = 0 }, { scrollvalue = 0 }
	local displayList = {}
	local classList, classListOrder = nil, nil

	-- Create/Delete

	local function createDisplay(name, copy)
		if copy then -- copy layout from current display
			local db = 	module.db.profile
			db.displays[name] = CopyTable(db.displays[CURRENT_DISPLAY])
			db.spells[name] = CopyTable(db.spells[CURRENT_DISPLAY])
			db.filters[name] = CopyTable(db.filters[CURRENT_DISPLAY])

			db.displays[name].showDisplay = true
			db.displays[name].lockDisplay = false
		end

		local display = module:CreateDisplay(activeDisplays[CURRENT_DISPLAY].type, name)
		activeDisplays[name] = display
		display:Show()

		if copy then
			updateCooldowns()
		end

		-- refresh panel
		CURRENT_DISPLAY = name
		tabStatus.selected = "tab1"
		classStatus.selected = "ALL"
		showPane()
	end

	local function deleteDisplay(name)
		if name == "Default" then
			print("Please don't delete the default display :(")
			return
		end
		local display = activeDisplays[name]
		display:Hide()
		if type(display.Delete) == "function" then
			display:Delete()
		end
		activeDisplays[name] = nil
		module.db.profile.displays[name] = nil
		module.db.profile.spells[name] = nil
		module.db.profile.filters[name] = nil

		-- refresh panel
		if CURRENT_DISPLAY == name then
			CURRENT_DISPLAY = "Default"
		end
		tabStatus.selected = "tab1"
		showPane()
	end

	local function convertDisplay(name, dtype)
		if not activeDisplays[name] or not module:GetDisplayInfo(dtype) then
			error(format("Failed to convert to display type '%s'", dtype), 0)
		end

		local x, y, w, h
		if activeDisplays[CURRENT_DISPLAY].GetPosition then
			x, y, w, h = activeDisplays[CURRENT_DISPLAY]:GetPosition()
		end

		activeDisplays[name]:Hide()
		if type(activeDisplays[name].Delete) == "function" then
			activeDisplays[name]:Delete()
		end

		local display = module:CreateDisplay(dtype, name)
		activeDisplays[name] = display
		display:Show()

		if display.SetPosition then
			display:SetPosition(x, y, w, h)
		end
		updateCooldowns()

		-- refresh panel
		CURRENT_DISPLAY = name
		--tabStatus.selected = "tab1"
		classStatus.selected = "ALL"
		showPane()
	end

	-- StaticPopupDialogs

	LibDialog:Register("ORA3_COOLDOWNS_NEW", { -- data: copy_current_display
		text = L.popupNewDisplay,
		buttons = {
			{
				text = OKAY,
				on_click = function(self, data)
					local name = self.editboxes[1]:GetText():trim()
					if activeDisplays[name] then
						LibDialog:Spawn("ORA3_COOLDOWNS_ERROR_NAME", {name, data})
						return
					end
					createDisplay(name, data)
				end,
			},
			{ text = CANCEL, },
		},
		editboxes = {
			{ auto_focus = true, },
		},
		on_show = function(self, data) showPane() end,
		no_close_button = true,
		hide_on_escape = true,
		show_while_dead = true,
	})

	LibDialog:Register("ORA3_COOLDOWNS_ERROR_NAME", { -- data: {invalid_display_name, copy_current_display}
		icon = [[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]],
		buttons = {
			{ text = OKAY, on_click = function(self, data) LibDialog:Spawn("ORA3_COOLDOWNS_NEW", data[2]) end, },
			{ text = CANCEL, },
		},
		on_show = function(self, data)
			showPane()
			self.text:SetFormattedText(L.popupNameError, data[1])
		end,
		no_close_button = true,
		hide_on_escape = true,
		show_while_dead = true,
	})

	LibDialog:Register("ORA3_COOLDOWNS_DELETE", { -- data: display_name
		buttons = {
			{ text = YES, on_click = function(self, data) deleteDisplay(data) end, },
			{ text = CANCEL, },
		},
		on_show = function(self, data)
			showPane()
			self.text:SetFormattedText(L.popupDeleteDisplay, data)
		end,
		no_close_button = true,
		hide_on_escape = true,
		show_while_dead = true,
	})

	-- Utility

	local function buildDisplayList()
		wipe(displayList)
		wipe(tmp) -- use tmp as our sort table
		for displayName in next, activeDisplays do
			tmp[#tmp+1] = displayName
			local enabled = activeDisplays[displayName].db.showDisplay
			local color = not enabled and GRAY_FONT_COLOR_CODE or HIGHLIGHT_FONT_COLOR_CODE
			displayList[displayName] = ("%s%s|r"):format(color, displayName)
		end
		sort(tmp)

		displayList["__new"] = L.createNewDisplay
		tmp[#tmp+1] = "__new"
		if CURRENT_DISPLAY then
			displayList["__newcopy"] = L.copyDisplay:format(CURRENT_DISPLAY)
			tmp[#tmp+1] = "__newcopy"
			if CURRENT_DISPLAY ~= "Default" then
				displayList["__delete"] = L.deleteDisplay:format(CURRENT_DISPLAY)
				tmp[#tmp+1] = "__delete"
			end
		end

		return displayList, tmp
	end

	local function sortBySpellName(a, b)
		return GetSpellInfo(a) < GetSpellInfo(b)
	end

	local function sortByClass(a, b)
		local classA, classB = classLookup[a], classLookup[b]
		-- push racials to the top
		if classA == "RACIAL" then classA = "ARACIAL" end
		if classB == "RACIAL" then classB = "ARACIAL" end
		if classA == classB then
			return GetSpellInfo(a) < GetSpellInfo(b)
		else
			return classA < classB
		end
	end

	-- Callbacks

	local function onOptionEnter(widget, event)
		if widget:GetUserData("desc") then
			GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
			GameTooltip:SetText(widget:GetUserData("name"), 1, .82, 0, true)
			GameTooltip:AddLine(widget:GetUserData("desc"), 1, 1, 1, true)
			if widget:GetUserData("desc2") then
				GameTooltip:AddLine(widget:GetUserData("desc2"), 0.5, 0.5, 0.8, true)
			end
			GameTooltip:Show()
		elseif widget:GetUserData("name") then
			GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
			GameTooltip:SetText(widget:GetUserData("name"), 1, .82, 0, true)
			GameTooltip:Show()
		elseif widget:GetUserData("id") then
			GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(widget:GetUserData("id"))
			GameTooltip:Show()
		end
	end

	local function onSpellOptionChanged(widget, event, value)
		local spellId = widget:GetUserData("id")
		local display = activeDisplays[CURRENT_DISPLAY]
		display.spellDB[spellId] = value and true or nil
		if type(display.OnSpellOptionChanged) == "function" then
			display:OnSpellOptionChanged(spellId, value)
		end
	end

	local function onFilterOptionChanged(widget, event, value)
		local key = widget:GetUserData("key")
		local display = activeDisplays[CURRENT_DISPLAY]
		local mvalue = widget:GetUserData("value")
		if mvalue then
			display.filterDB[key][mvalue] = value
		else
			display.filterDB[key] = value
		end
		if type(display.OnFilterOptionChanged) == "function" then
			display:OnFilterOptionChanged(key, value)
		end
		showPane()
	end

	local function onOptionChanged(widget, event, value)
		local key = widget:GetUserData("key")
		if key then
			local display = activeDisplays[CURRENT_DISPLAY]
			display.db[key] = value
			if key == "showDisplay" then
				if value then
					display:Show()
					updateCooldowns()
				else
					display:Hide()
				end
			elseif key == "lockDisplay" then
				if value then
					display:Lock()
				else
					display:Unlock()
				end
			end
			showPane()
		end
	end

	local function addOptionToggle(key, name, desc, disabled)
		local db = activeDisplays[CURRENT_DISPLAY].db
		local control = AceGUI:Create("CheckBox")
		control:SetFullWidth(true)
		control:SetLabel(name)
		control:SetValue(db[key] and true or false)
		control:SetUserData("key", key)
		control:SetUserData("name", name)
		control:SetUserData("desc", desc)
		control:SetCallback("OnValueChanged", onOptionChanged)
		control:SetDisabled(disabled)
		return control
	end

	local function addOptionButton(name, func, disabled)
		local control = AceGUI:Create("Button")
		control:SetFullWidth(true)
		control:SetText(name)
		control:SetCallback("OnClick", func)
		control:SetDisabled(disabled)
		return control
	end

	local function addFilterOptionToggle(key, name, desc, disabled)
		local db = activeDisplays[CURRENT_DISPLAY].filterDB
		local control = addOptionToggle(key, name, desc, disabled)
		control:SetValue(db[key] and true or false)
		control:SetCallback("OnValueChanged", onFilterOptionChanged)
		control:SetCallback("OnEnter", onOptionEnter)
		control:SetCallback("OnLeave", GameTooltip_Hide)
		return control
	end

	local function addFilterOptionMultiselect(key, name, desc, values, disabled)
		local db = activeDisplays[CURRENT_DISPLAY].filterDB
		local control = AceGUI:Create("InlineGroup")
		control:SetLayout("Flow")
		control:SetTitle(name)
		control:SetFullWidth(true)

		wipe(tmp)
		for value in next, values do
			tmp[#tmp + 1] = value
		end
		sort(tmp)

		control:PauseLayout()
		for i = 1, #tmp do
			local value = tmp[i]
			local text = values[value]
			local checkbox = AceGUI:Create("CheckBox")
			checkbox:SetRelativeWidth(0.5)
			checkbox:SetLabel(text)
			checkbox:SetDisabled(disabled)
			checkbox:SetValue(db[key][value] and true or false)
			checkbox:SetUserData("key", key)
			checkbox:SetUserData("value", value)
			checkbox:SetCallback("OnValueChanged", onFilterOptionChanged)
			checkbox:SetUserData("name", name)
			checkbox:SetUserData("desc", desc)
			checkbox:SetUserData("desc2", text)
			checkbox:SetCallback("OnEnter", onOptionEnter)
			checkbox:SetCallback("OnLeave", GameTooltip_Hide)
			control:AddChild(checkbox)
		end
		control:ResumeLayout()
		control:DoLayout()

		return control
	end

	local function onDropdownGroupSelected(widget, event, key)
		widget:PauseLayout()
		widget:ReleaseChildren()

		local display = activeDisplays[CURRENT_DISPLAY]
		if key == "ALL" then
			-- selected spells
			wipe(tmp)
			if display then
				for id, value in next, display.spellDB do
					if value then tmp[#tmp + 1] = id end
				end
			end
			if #tmp == 0 then
				local control = AceGUI:Create("Label")
				control:SetFullWidth(true)
				control:SetFontObject(GameFontHighlight)
				control:SetText("\n"..L.noSpells)
				widget:AddChild(control)
			else
				sort(tmp, sortByClass)
				for _, spellId in ipairs(tmp) do
					local name, _, icon = GetSpellInfo(spellId)
					if name then
						local color = oRA.classColors[classLookup[spellId]]
						local checkbox = AceGUI:Create("CheckBox")
						checkbox:SetRelativeWidth(1)
						checkbox:SetLabel(string.format("|c%s%s|r", color.colorStr, name))
						checkbox:SetValue(true)
						checkbox:SetImage(icon)
						checkbox:SetUserData("id", spellId)
						checkbox:SetCallback("OnValueChanged", onSpellOptionChanged)
						checkbox:SetCallback("OnEnter", onOptionEnter)
						checkbox:SetCallback("OnLeave", GameTooltip_Hide)
						widget:AddChild(checkbox)
					end
				end
			end

		elseif spells[key] then
			wipe(tmp)
			for id in next, spells[key] do
				tmp[#tmp + 1] = id
			end
			sort(tmp, sortBySpellName)
			for _, spellId in ipairs(tmp) do
				local name, _, icon = GetSpellInfo(spellId)
				if name then
					local checkbox = AceGUI:Create("CheckBox")
					checkbox:SetRelativeWidth(0.5)
					checkbox:SetLabel(name)
					checkbox:SetValue(display.spellDB[spellId] and true or false)
					checkbox:SetImage(icon)
					checkbox:SetUserData("id", spellId)
					checkbox:SetCallback("OnValueChanged", onSpellOptionChanged)
					checkbox:SetCallback("OnEnter", onOptionEnter)
					checkbox:SetCallback("OnLeave", GameTooltip_Hide)
					widget:AddChild(checkbox)
				end
			end
		end

		widget:ResumeLayout()
		widget:DoLayout()
		frame:DoLayout() -- update the scroll height
	end

	local function onTabGroupSelected(widget, event, value)
		widget:ReleaseChildren()

		if value == "tab1" then -- Spells
			local scroll = AceGUI:Create("ScrollFrame")
			scroll:SetLayout("List")
			scroll:SetFullWidth(true)
			scroll:SetFullHeight(true)

			if oRA.db.profile.showHelpTexts then
				local moduleDescription = AceGUI:Create("Label")
				moduleDescription:SetText(L.selectClassDesc)
				moduleDescription:SetFontObject(GameFontHighlight)
				moduleDescription:SetFullWidth(true)

				scroll:AddChild(moduleDescription)
			end

			local group = AceGUI:Create("DropdownGroup")
			group:SetStatusTable(classStatus)
			group:SetLayout("Flow")
			group:SetFullWidth(true)
			group:SetTitle(L.selectClass)
			group:SetDropdownWidth(165)
			group:SetGroupList(classList, classListOrder)
			group:SetCallback("OnGroupSelected", onDropdownGroupSelected)
			group:SetGroup(classStatus.selected)

			scroll:AddChild(group)
			widget:AddChild(scroll)

		elseif value == "tab2" then -- Settings
			local options = module:GetDisplayOptionsTable(activeDisplays[CURRENT_DISPLAY]) -- options table updated with the current display's db
			if options then
				-- hackery ! need a container so ACD doesn't break things
				local container = AceGUI:Create("SimpleGroup")
				container.type = "oRASimpleGroup" -- we want ACD to create a scrollframe
				container:SetFullHeight(true)
				container:SetFullWidth(true)

				-- have to use :Open (and ACR) instead of just :FeedGroup because some widget types (range, color) call :Open to refresh on change
				ACR:RegisterOptionsTable("oRACooldownsDisplayOptions", options)
				ACD:Open("oRACooldownsDisplayOptions", container)

				widget:AddChild(container)
			end

		elseif value == "tab3" then -- Filters
			local scroll = AceGUI:Create("ScrollFrame")
			scroll:SetStatusTable(filterStatus)
			scroll:SetLayout("List")
			scroll:SetFullWidth(true)
			scroll:SetFullHeight(true)

			-- if oRA.db.profile.showHelpTexts then
			-- 	local moduleDescription = AceGUI:Create("Label")
			-- 	moduleDescription:SetText("Filters are a blacklist, enable options to prevent cooldowns from showing.")
			-- 	moduleDescription:SetFontObject(GameFontHighlight)
			-- 	moduleDescription:SetFullWidth(true)
			--
			-- 	scroll:AddChild(moduleDescription)
			-- end

			local db = activeDisplays[CURRENT_DISPLAY].filterDB
			scroll:AddChild(addFilterOptionToggle("showOnlyMine", L.onlyMyOwnSpells, L.onlyMyOwnSpellsDesc, db.neverShowMine))
			scroll:AddChild(addFilterOptionToggle("neverShowMine", L.neverShowOwnSpells, L.neverShowOwnSpellsDesc, db.showOnlyMine))
			scroll:AddChild(addFilterOptionToggle("hideDead", L.hideDead))
			scroll:AddChild(addFilterOptionToggle("hideOffline", L.hideOffline))
			--scroll:AddChild(addFilterOptionToggle("hideOutOfCombat", L.hideOutOfCombat))
			scroll:AddChild(addFilterOptionToggle("hideOutOfRange", L.hideOutOfRange))
			scroll:AddChild(addFilterOptionMultiselect("hideRoles", ROLE, L.hideRolesDesc, { TANK = TANK, HEALER = HEALER, DAMAGER = DAMAGER }))
			scroll:AddChild(addFilterOptionMultiselect("hideInGroup", GROUP, L.hideInGroupDesc, { party = PARTY, raid = RAID })) -- , solo = SOLO
			scroll:AddChild(addFilterOptionMultiselect("hideInInstance", INSTANCE, L.hideInInstanceDesc, {
				raid = RAID, party = PARTY, lfg = "LFG",
				pvp = BATTLEGROUND, arena = ARENA,
			}))
			scroll:AddChild(addFilterOptionMultiselect("hideGroup", RAID_GROUPS, L.hideGroupDesc, {
				[1] = GROUP_NUMBER:format(1), [2] = GROUP_NUMBER:format(2), [3] = GROUP_NUMBER:format(3), [4] = GROUP_NUMBER:format(4),
				[5] = GROUP_NUMBER:format(5), [6] = GROUP_NUMBER:format(6), [7] = GROUP_NUMBER:format(7), [8] = GROUP_NUMBER:format(8),
			}))

			widget:AddChild(scroll)
		end
	end

	local function onDisplayChanged(widget, event, value)
		if value == "__new" then
			LibDialog:Spawn("ORA3_COOLDOWNS_NEW")
		elseif value == "__newcopy" then
			LibDialog:Spawn("ORA3_COOLDOWNS_NEW", true)
		elseif value == "__delete" then
			LibDialog:Spawn("ORA3_COOLDOWNS_DELETE", CURRENT_DISPLAY)
		else
			CURRENT_DISPLAY = value
			showPane()
		end
	end

	function showPane()
		if not classList then
			classList = { ALL = L.allSpells, RACIAL = "|cffe0e0e0".."Racial Spells".."|r" }
			classListOrder = {}
			for class in next, spells do
				if class ~= "RACIAL" then
					classList[class] = string.format("|c%s%s|r", oRA.classColors[class].colorStr, LOCALIZED_CLASS_NAMES_MALE[class])
					classListOrder[#classListOrder + 1] = class
				end
			end
			table.sort(classListOrder)
			table.insert(classListOrder, 1, "ALL")
			table.insert(classListOrder, 2, "RACIAL")
		end
		if not frame then
			frame = AceGUI:Create("SimpleGroup")
			frame:SetLayout("Flow")
			frame:SetFullWidth(true)

			if not IsInGroup() then
				module:OnStartup()
			end
		end
		frame:ReleaseChildren()

		if not module.db.profile.enabled then
			local text = AceGUI:Create("Label")
			text:SetFullWidth(true)
			text:SetFontObject(GameFontHighlightLarge)
			text:SetText("\n".."Module disabled")
			text.label:SetJustifyH("CENTER")

			frame:AddChildren(text)

			oRA:SetAllPointsToPanel(frame.frame, true)
			frame.frame:Show()
			return
		end

		if not activeDisplays[CURRENT_DISPLAY] then
			CURRENT_DISPLAY = "Default"
		end
		local display = activeDisplays[CURRENT_DISPLAY]

		local list = AceGUI:Create("Dropdown")
		list:SetRelativeWidth(0.5)
		list:SetLabel(DISPLAY)
		list:SetList(buildDisplayList())
		list:SetValue(CURRENT_DISPLAY)
		list:SetCallback("OnValueChanged", onDisplayChanged)

		wipe(tmp)
		local typeDescription = ""
		for _, type in module:IterateDisplayTypes() do
			local name, desc = module:GetDisplayInfo(type)
			tmp[type] = name
			if desc and desc ~= "" then
				typeDescription = ("%s|cff20ff20%s|r: %s\n"):format(typeDescription, name, desc)
			end
		end

		local dtype = AceGUI:Create("Dropdown")
		dtype:SetRelativeWidth(0.5)
		dtype:SetLabel(TYPE)
		dtype:SetList(tmp)
		dtype:SetValue(display and display.type)
		dtype:SetCallback("OnValueChanged", function(_, _, value)
			convertDisplay(CURRENT_DISPLAY, value)
		end)
		dtype:SetCallback("OnEnter", onOptionEnter)
		dtype:SetCallback("OnLeave", GameTooltip_Hide)
		dtype:SetUserData("name", L.displayTypes)
		dtype:SetUserData("desc", ("%s\n|cffff2020%s|r"):format(typeDescription, L.popupConvertDisplay))
		dtype:SetDisabled(not display or not display.db.showDisplay)

		local enable = addOptionToggle("showDisplay", ENABLE, L.showMonitorDesc, not display)
		enable:SetRelativeWidth(0.25)
		local lock = addOptionToggle("lockDisplay", LOCK, L.lockMonitorDesc, not display or not display.db.showDisplay)
		lock:SetRelativeWidth(0.25)
		local test = addOptionButton(L.test, SpawnTestBar, not display or not display.db.showDisplay or not display.TestCooldown)
		test:SetRelativeWidth(0.5)

		local tabs = AceGUI:Create("TabGroup")
		tabs:SetStatusTable(tabStatus)
		tabs:SetLayout("Flow")
		tabs:SetFullWidth(true)
		tabs:SetFullHeight(true)
		tabs:SetTabs({
			{ text = SPELLS, value = "tab1" },
			{ text = SETTINGS, value = "tab2", not module:GetDisplayOptionsTable(display) },
			{ text = FILTERS, value = "tab3" },
		})
		tabs:SetCallback("OnGroupSelected", onTabGroupSelected)
		tabs:SelectTab(tabStatus.selected)

		frame:AddChildren(list, dtype, enable, lock, test, tabs)

		oRA:SetAllPointsToPanel(frame.frame, true)
		frame.frame:Show()
	end

	function hidePane()
		if frame then
			frame:Release()
			frame = nil

			if not IsInGroup() then
				module:OnShutdown()
			end
		end
	end

	function module:OpenDisplayOptions(display)
		if display then
			CURRENT_DISPLAY = display.name
		end
		tabStatus.selected = "tab1"
		oRA:SelectPanel(L.cooldowns, true)
	end
end

--------------------------------------------------------------------------------
-- Module
--

local function upgradeDB(db)
	-- convert db, a little awkward due to the "*" defaults
	if not next(db.displays) then

		-- set spells
		local spellDB = {}
		for k, v in next, db.spells do
			spellDB[k] = v or nil
		end
		db.spells = { Default = spellDB }

		-- set filters
		local filterDB = db.filters.Default
		filterDB.onlyShowMine = db.onlyShowMine
		filterDB.neverShowMine = db.neverShowMine

		-- set up a display with our old bar settings
		local displayDB = db.displays.Default
		displayDB.type = "Bars"
		displayDB.showDisplay = true
		displayDB.lockDisplay = false
		for k, v in next, db do
			if k ~= "displays" and k ~= "spells" and k ~= "filters" then
				if k:find("^bar") then
					displayDB[k] = type(db[k]) == "table" and CopyTable(db[k]) or db[k]
				end
				db[k] = nil
			end
		end

		db.enabled = true

		-- update position
		if oRA.db.profile.positions.oRA3CooldownFrame then
			oRA.db.profile.positions.oRA3CooldownFrameBarsDefault = CopyTable(oRA.db.profile.positions.oRA3CooldownFrame)
			oRA.db.profile.positions.oRA3CooldownFrame = nil
		end

		module:ScheduleTimer(function()
			print("oRA3 Cooldowns has been redesigned and now supports multiple displays and different formats! You can open the options panel with /racd and move it around by dragging the title bar.")
		end, 9)
	end

	-- remove unused spells from the db
	for displayName, dspells in next, db.spells do
		for spell in next, dspells do
			if not classLookup[spell] then
				dspells[spell] = nil
			end
		end
	end
end

function module:OnProfileUpdate(event)
	-- tear down displays
	self:OnShutdown()
	for displayName, display in next, activeDisplays do
		display:Hide()
		if type(display.OnDelete) == "function" then
			display:OnDelete()
		end
		display.frame = nil
		activeDisplays[displayName] = nil
	end

	-- make sure the db is converted
	upgradeDB(self.db.profile)

	-- build displays
	for displayName, db in next, self.db.profile.displays do
		local display = self:CreateDisplay(db.type, displayName)
		activeDisplays[displayName] = display
		display:Hide()
	end
	if IsInGroup() then
		self:OnStartup()
	end

	-- update options
	if frame then
		frame = frame:Release()
		showPane()
	end
end

do
	local function removeDefaults(db, defaults)
		if not db or not defaults then return end
		for k, v in next, defaults do
			if type(v) == "table" and type(db[k]) == "table" then
				removeDefaults(db[k], v)
				if next(db[k]) == nil then
					db[k] = nil
				end
			else
				if db[k] == defaults[k] then
					db[k] = nil
				end
			end
		end
	end

	function module:OnProfileShutdown()
		-- clean up display db defaults (ideally, the logic for this would be in Registery.lua)
		for displayName, display in next, activeDisplays do
			removeDefaults(self.db.profile.displays[displayName], display.defaultDB)
		end
	end
end

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("Cooldowns", {
		profile = {
			spells = {},
			displays = {
				["**"] = {
					showDisplay = true,
					lockDisplay = false,
				}
			},
			filters = {
				["**"] = {
					showOnlyMine = false,
					neverShowMine = false,
					hideDead = false,
					hideOffline = false,
					--hideOutOfCombat = false,
					hideOutOfRange = false,
					hideRoles = {
						TANK = false,
						HEALER = false,
						DAMAGER = false,
					},
					hideInGroup = {
						raid = false, party = false, solo = false,
					},
					hideInInstance = {
						raid = false, party = false, lfg = false,
						pvp = false, arena = false,
					},
					--hideNameList = {},
					hideGroup = {
						[1] = false, [2] = false, [3] = false, [4] = false,
						[5] = false, [6] = false, [7] = false, [8] = false,
					},
				}
			},
			enabled = true,
		},
		global = {
			spellsOnCooldown = {},
			chargeSpellsOnCooldown = {},
		},
	})

	oRA:RegisterModuleOptions("Cooldowns", {
		type = "group",
		name = L.cooldowns,
		args = {
			enabled = {
				type = "toggle",
				name = ("|cfffed000%s|r"):format(ENABLE),
				desc = L.cooldownsEnableDesc,
				descStyle = "inline",
				get = function(info) return self.db.profile.enabled end,
				set = function(info, value)
					self:OnShutdown()
					self.db.profile.enabled = value
					if value and (IsInGroup() or (frame and frame:IsShown())) then
						self:OnStartup()
					end
					if frame and frame:IsShown() then
						showPane()
					end
				end,
				width = "full",
				order = 1,
			},
			settings = {
				type = "execute",
				name = "Open Settings",
				func = function() self:OpenDisplayOptions("Default") end,
				order = 2,
			},
		}
	})

	self.db.RegisterCallback(self, "OnProfileShutdown")
	oRA.RegisterCallback(self, "OnProfileUpdate")
	self:OnProfileUpdate()

	-- persist cds on reloads
	spellsOnCooldown = self.db.global.spellsOnCooldown
	if not spellsOnCooldown then -- why. WHY!?
		self.db.global.spellsOnCooldown = {}
		spellsOnCooldown = self.db.global.spellsOnCooldown
	end
	chargeSpellsOnCooldown = self.db.global.chargeSpellsOnCooldown
	if not chargeSpellsOnCooldown then
		self.db.global.chargeSpellsOnCooldown = {}
		chargeSpellsOnCooldown = self.db.global.chargeSpellsOnCooldown
	end
	if not self.db.global.lastTime or self.db.global.lastTime > GetTime() then -- probably restarted or crashed, trash times
		wipe(spellsOnCooldown)
		wipe(chargeSpellsOnCooldown)
	end
	self.db.global.lastTime = nil

	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
	self:RegisterEvent("PLAYER_LOGOUT")

	oRA:RegisterPanel(L.cooldowns, showPane, hidePane)

	SLASH_ORACOOLDOWN1 = "/racd"
	SLASH_ORACOOLDOWN2 = "/racooldown"
	SlashCmdList.ORACOOLDOWN = function()
		oRA:SelectPanel(L.cooldowns)
	end
end

function module:OnStartup(_, groupStatus)
	if not self.db.profile.enabled then return end
	self.enabled = true

	if next(syncSpells) then
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	end

	callbacks:Fire("OnStartup")

	oRA.RegisterCallback(self, "OnCommReceived")
	oRA.RegisterCallback(self, "OnGroupChanged")
	self:OnGroupChanged(nil, groupStatus, oRA:GetGroupMembers())

	oRA.RegisterCallback(self, "OnPlayerUpdate")
	oRA.RegisterCallback(self, "OnPlayerRemove")
	oRA:InspectGroup()

	--self:RegisterEvent("PLAYER_REGEN_DISABLED")
	--self:RegisterEvent("PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED")
	self:RegisterEvent("UNIT_CONNECTION")
	combatLogHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:ScheduleRepeatingTimer(combatOnUpdate, 0.1)
end

function module:OnShutdown()
	if not self.enabled then return end
	self.enabled = nil

	callbacks:Fire("OnShutdown")

	oRA.UnregisterCallback(self, "OnCommReceived")
	oRA.UnregisterCallback(self, "OnGroupChanged")
	oRA.UnregisterCallback(self, "OnPlayerUpdate")
	oRA.UnregisterCallback(self, "OnPlayerRemove")

	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
	--self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	--self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
	self:UnregisterEvent("UNIT_CONNECTION")
	combatLogHandler:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	wipe(combatLogHandler.userdata)
	self:CancelAllTimers()

	wipe(infoCache)
	wipe(cdModifiers)
	wipe(chargeModifiers)
	wipe(deadies)
end

function module:PLAYER_LOGOUT()
	self:OnProfileShutdown()

	-- cleanup db spell cds
	local t = GetTime()
	for spellId, players in next, spellsOnCooldown do
		if next(players) == nil then
			spellsOnCooldown[spellId] = nil
		end
	end
	for spellId, players in next, chargeSpellsOnCooldown do
		for guid, expires in next, players do
			for i, e in next, expires do
				if e < t then
					tremove(expires, i)
				end
			end
			if next(expires) == nil then
				players[guid] = nil
			end
		end
		if next(players) == nil then
			chargeSpellsOnCooldown[spellId] = nil
		end
	end
	self.db.global.lastTime = t
end

--------------------------------------------------------------------------------
-- Events
--

function module:SPELL_UPDATE_COOLDOWN()
	for spellId in next, syncSpells do
		local expiry = spellsOnCooldown[spellId] and spellsOnCooldown[spellId][playerGUID]
		if expiry then
			local start, duration = GetSpellCooldown(spellId)
			if start > 0 and duration > 0 then
				if (start + duration + 0.1) < expiry then -- + 0.1 to avoid updating on trivial differences
					local cd =  duration - (GetTime() - start)
					module:SendComm("CooldownUpdate", spellId, round(cd)) -- round to the precision of GetTime (%.3f)
				end
			else -- off cooldown
				module:SendComm("CooldownUpdate", spellId, 0)
			end
		end
	end
end

local checkReincarnationCooldown = nil
do
	if playerClass == "SHAMAN" then
		function checkReincarnationCooldown()
			local start, duration = GetSpellCooldown(20608)
			if start > 0 and duration > 1.5 then
				local cd =  duration - (GetTime() - start)
				module:SendComm("Reincarnation", round(cd))
			end
		end
	end
end

function module:OnCommReceived(_, sender, prefix, spellId, cd)
	if prefix == "CooldownUpdate" then
		local guid = UnitGUID(sender)
		local name, class = self:GetPlayerFromGUID(guid)
		cd = tonumber(cd)
		spellId = tonumber(spellId)
		if cd > 0 then
			if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
			spellsOnCooldown[spellId][guid] = GetTime() + cd
			callbacks:Fire("oRA3CD_StartCooldown", guid, name, class, spellId, cd)
		else
			if spellsOnCooldown[spellId] and spellsOnCooldown[spellId][guid] then
				spellsOnCooldown[spellId][guid] = nil
			end
			callbacks:Fire("oRA3CD_StopCooldown", guid, spellId)
			callbacks:Fire("oRA3CD_CooldownReady", guid, name, class, spellId)
		end

	elseif prefix == "Reincarnation" then
		local guid = UnitGUID(sender)
		local name = self:GetPlayerFromGUID(guid)
		cd = tonumber(spellId)
		spellId = 20608
		if self:GetRemainingCooldown(guid, spellId) == 0 then
			if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
			spellsOnCooldown[spellId][guid] = GetTime() + cd
			callbacks:Fire("oRA3CD_StartCooldown", guid, name, "SHAMAN", spellId, cd)
		end
	end
end

function module:OnGroupChanged(_, groupStatus, groupMembers)
	if groupStatus == 0 then return end -- OnShutdown should handle it

	for _, player in next, groupMembers do
		local guid = UnitGUID(player)
		if guid then
			if UnitIsDeadOrGhost(player) and not UnitIsFeignDeath(player) and not deadies[guid] then
				deadies[guid] = true
				callbacks:Fire("oRA3CD_UpdatePlayer", guid, player)
				self:RegisterEvent("UNIT_HEALTH_FREQUENT")
			end
		end
	end

	if checkReincarnationCooldown then
		checkReincarnationCooldown()
	end
end

function module:OnPlayerUpdate(_, guid, unit, info)
	for _, mods in next, cdModifiers do mods[guid] = nil end
	for _, mods in next, chargeModifiers do mods[guid] = nil end

	for talentIndex, talentId in next, info.talents do
		if talentCooldowns[talentId] then
			talentCooldowns[talentId](info)
		end
	end

	infoCache[guid] = info
	updateCooldownsByGUID(guid)
end

function module:OnPlayerRemove(_, guid)
	callbacks:Fire("oRA3CD_StopCooldown", guid)

	-- purge info
	for _, t in next, spellsOnCooldown do t[guid] = nil end
	for _, t in next, chargeSpellsOnCooldown do t[guid] = nil end
	for _, t in next, cdModifiers do t[guid] = nil end
	for _, t in next, chargeModifiers do t[guid] = nil end
	infoCache[guid] = nil
	deadies[guid] = nil
end

function module:UNIT_CONNECTION(unit, hasConnected)
	local guid = UnitGUID(unit)
	if guid then
		 -- UnitIsConnected doesn't update with the event apparently
		self:ScheduleTimer(callbacks.Fire, 1, callbacks, "oRA3CD_UpdatePlayer", guid, self:UnitName(unit))
	end
end

function module:UNIT_HEALTH_FREQUENT(unit)
	local guid = UnitGUID(unit)
	if guid and deadies[guid] and not UnitIsDeadOrGhost(unit) then
		deadies[guid] = nil
		callbacks:Fire("oRA3CD_UpdatePlayer", guid, self:UnitName(unit))
	end
	if not next(deadies) then
		self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
	end
end

do
	local function getPetOwner(pet, guid)
		if UnitGUID("pet") == guid then
			return UnitName("player"), UnitGUID("player")
		end

		local owner
		if IsInRaid() then
			for i=1, GetNumGroupMembers() do
				if UnitGUID(("raid%dpet"):format(i)) == guid then
					owner = ("raid%d"):format(i)
					break
				end
			end
		else
			for i=1, GetNumSubgroupMembers() do
				if UnitGUID(("party%dpet"):format(i)) == guid then
					owner = ("party%d"):format(i)
					break
				end
			end
		end
		if owner then
			return module:UnitName(owner), UnitGUID(owner)
		end
		return pet, guid
	end

	local function resetCooldown(info, spellId, remaining, charges)
		local guid, player, class = info.guid, info.name, info.class
		callbacks:Fire("oRA3CD_StopCooldown", guid, spellId)
		if remaining and remaining > 0 then
			if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
			spellsOnCooldown[spellId][guid] = GetTime() + remaining
			callbacks:Fire("oRA3CD_StartCooldown", guid, player, class, spellId, remaining)
		else
			if spellsOnCooldown[spellId] and spellsOnCooldown[spellId][guid] then
				spellsOnCooldown[spellId][guid] = nil
			end
			callbacks:Fire("oRA3CD_CooldownReady", guid, player, class, spellId)
			if charges then
				callbacks:Fire("oRA3CD_UpdateCharges", guid, player, class, spellId, module:GetCooldown(guid, spellId), charges, charges)
			end
		end
	end

	combatLogHandler.userdata = {}
	-- local scratch = combatLogHandler.userdata
	local specialEvents = {
		SPELL_CAST_SUCCESS = {
			[200166] = function(srcGUID) -- Metamorphosis (Havoc)
				local info = infoCache[srcGUID]
				if info and info.talents[18] then -- Demon Reborn
					resetCooldown(info, 179057) -- Chaos Nova
					resetCooldown(info, 198589) -- Blur
				end
			end,
		},
		SPELL_AURA_REMOVED = {
			[206005] = function(_, dstGUID) -- Dream Simulacrum (Xavius Encounter)
				local info = infoCache[dstGUID]
				if info then
					for spellId in next, spells[info.class] do
						if module:GetRemainingCooldown(dstGUID, spellId) > 0 then
							resetCooldown(info, spellId)
						end
					end
				end
			end,
		},
	}

	local inEncounter = nil
	local band = bit.band
	local group = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
	local pet = bit.bor(COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET)

	combatLogHandler:SetScript("OnEvent", function(self, _, _, event, _, srcGUID, source, srcFlags, _, destGUID, destName, dstFlags, _, spellId, spellName, _, ...)
		if event == "UNIT_DIED" then
			if band(dstFlags, group) ~= 0 and UnitIsPlayer(destName) and not UnitIsFeignDeath(destName) then
				callbacks:Fire("oRA3CD_UpdatePlayer", destGUID, destName)
				deadies[destGUID] = true
				module:RegisterEvent("UNIT_HEALTH_FREQUENT")
			end
			return
		end

		if source and (event == "SPELL_CAST_SUCCESS" or event == "SPELL_RESURRECT") and allSpells[spellId] and band(srcFlags, group) ~= 0 then
			if mergeSpells[spellId] then
				spellId = mergeSpells[spellId]
			end

			if combatResSpells[spellId] and inEncounter then
				-- tracking by spell cast isn't very useful in an encounter because it only counts when accepted
				return
			end

			if band(srcFlags, pet) > 0 then
				source, srcGUID = getPetOwner(source, srcGUID)
			end
			if not infoCache[srcGUID] then return end
			local class = infoCache[srcGUID].class

			callbacks:Fire("oRA3CD_SpellUsed", spellId, srcGUID, source, destGUID, destName)
			if module:GetCharges(srcGUID, spellId) > 0 then
				if not chargeSpellsOnCooldown[spellId] then chargeSpellsOnCooldown[spellId] = { [srcGUID] = {} }
				elseif not chargeSpellsOnCooldown[spellId][srcGUID] then chargeSpellsOnCooldown[spellId][srcGUID] = {} end
				local expires = chargeSpellsOnCooldown[spellId][srcGUID]

				local t = GetTime()
				local cd = module:GetCooldown(srcGUID, spellId)
				expires[#expires + 1] = (expires[#expires] or t) + cd
				local maxCharges = module:GetCharges(srcGUID, spellId)
				local charges = maxCharges - #expires
				if charges == 0 then
					if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
					spellsOnCooldown[spellId][srcGUID] = expires[1]
					callbacks:Fire("oRA3CD_StartCooldown", srcGUID, source, class, spellId, expires[1] - t)
				end
				callbacks:Fire("oRA3CD_UpdateCharges", srcGUID, source, class, spellId, cd, charges, maxCharges)
			else
				if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
				local cd = module:GetCooldown(srcGUID, spellId)
				spellsOnCooldown[spellId][srcGUID] = GetTime() + cd
				callbacks:Fire("oRA3CD_StartCooldown", srcGUID, source, class, spellId, cd)
			end
		end

		-- Special cooldown conditions
		local func = specialEvents[event] and specialEvents[event][spellId]
		if func then
			func(srcGUID, destGUID, spellId, ...)
		end
	end)

	local playerStates = {}
	local STATUS_RANGE, STATUS_COMBAT = 1, 2
	function module:PLAYER_REGEN_DISABLED()
		for guid, status in next, playerStates do
			if band(status, STATUS_COMBAT) == STATUS_COMBAT then
				callbacks:Fire("oRA3CD_UpdatePlayer", guid, infoCache[guid].name)
			end
		end
	end

	local total = 0
	local IsEncounterInProgress = IsEncounterInProgress
	combatOnUpdate = function(self)
		local t = GetTime() + 0.05

		-- check spell cds
		for spellId, players in next, spellsOnCooldown do
			for guid, expires in next, players do
				if expires < t then
					players[guid] = nil
					local info = infoCache[guid]
					if info then
						callbacks:Fire("oRA3CD_CooldownReady", guid, info.name, info.class, spellId)
					end
				end
			end
		end

		-- update spell charge cds
		for spellId, players in next, chargeSpellsOnCooldown do
			for guid, expires in next, players do
				local info = infoCache[guid]
				if not info then
					players[guid] = nil
				else
					local changed = nil
					for i = #expires, 1, -1 do
						if expires[i] < t then
							changed = true
							tremove(expires, i)
						end
					end
					if changed then
						local maxCharges = module:GetCharges(guid, spellId)
						if maxCharges > 0 then
							local charges = maxCharges - #expires
							callbacks:Fire("oRA3CD_UpdateCharges", guid, info.name, info.class, spellId, module:GetCooldown(guid, spellId), charges, maxCharges, true)
						end
					end
				end
			end
		end

		-- encounter checking for cd resets
		if not inEncounter and IsEncounterInProgress() then
			inEncounter = true
			-- reset combat reses
			for spellId in next, combatResSpells do
				spellsOnCooldown[spellId] = nil
				updateCooldownsBySpell(spellId)
			end
		elseif inEncounter and not IsEncounterInProgress() then
			inEncounter = nil
			-- reset 3min+ cds (except Reincarnation)
			for spellId, info in next, allSpells do
				if info[1] >= 180 and spellId ~= 20608 then
					spellsOnCooldown[spellId] = nil
					chargeSpellsOnCooldown[spellId] = nil
					updateCooldownsBySpell(spellId)
				end
			end
		end

		-- track non-event driven player states (combat and range)
		if t - total > 1 then
			total = t
			for guid, info in next, infoCache do
				local player = info.name
				local status = nil
				if UnitInRange(player) then status = (status or 0) + STATUS_RANGE end
				if UnitAffectingCombat(player) then status = (status or 0) + STATUS_COMBAT end
				if playerStates[guid] ~= status then
					playerStates[guid] = status
					callbacks:Fire("oRA3CD_UpdatePlayer", guid, player)
				end
			end
		end
	end
end

_G.oRA3CD = module -- set global
