--------------------------------------------------------------------------------
-- Setup
--

local addonName, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Cooldowns", "AceTimer-3.0")
local L = scope.locale
local LGIST = LibStub("LibGroupInSpecT-1.1")
local callbacks = LibStub("CallbackHandler-1.0"):New(module)

oRA3CD = module

-- GLOBALS: GameTooltip GameTooltip_Hide StaticPopup_Show StaticPopupDialogs tContains
-- GLOBALS: GameFontHighlight GameFontHighlightLarge LE_PARTY_CATEGORY_INSTANCE FILTERS
-- GLOBALS: CANCEL DISPLAY ENABLE GRAY_FONT_COLOR_CODE HIGHLIGHT_FONT_COLOR_CODE
-- GLOBALS: LOCK LOCALIZED_CLASS_NAMES_MALE NONE OKAY SPELLS SETTINGS TYPE YES
-- GLOBALS: COMBATLOG_OBJECT_AFFILIATION_MINE COMBATLOG_OBJECT_AFFILIATION_PARTY COMBATLOG_OBJECT_AFFILIATION_RAID
-- GLOBALS: COMBATLOG_OBJECT_TYPE_GUARDIAN COMBATLOG_OBJECT_TYPE_PET
-- GLOBALS: ARENA BATTLEGROUND DAMAGER HEALER INSTANCE PARTY RAID ROLE TANK RAID_GROUPS GROUP_NUMBER
-- GLOBALS: oRA3CD SLASH_ORACOOLDOWN1 SLASH_ORACOOLDOWN2 SlashCmdList

--------------------------------------------------------------------------------
-- Locals
--

local activeDisplays = {}
local frame = nil -- main options panel
local showPane, hidePane

local combatLogHandler = CreateFrame("Frame")
local combatOnUpdate = nil

local checkReincarnationCooldown = nil

local infoCache = {}
local cdModifiers, chargeModifiers = {}, {}
local spellsOnCooldown, chargeSpellsOnCooldown = nil, nil
local deadies = {}

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
	[19364] = function(info) -- Crouching Tiger, Hidden Chimera
		addMod(info.guid, 781, 10) -- Disengage
		addMod(info.guid, 19263, 60) -- Deterrence
	end,
	[17591] = function(info) -- Unbreakable Spirit
		addMod(info.guid, 642, 150) -- Divine Shield
		addMod(info.guid, 498, 30) -- Divine Protection
		local divinity = cdModifiers[633] and cdModifiers[633][info.guid] -- relies on glyphs being set first
		addMod(info.guid, 633, divinity and 360 or 300) -- Lay on Hands, (-50%) -300sec / -360sec with Glyph of Divinity
	end,
	[17593] = function(info) -- Clemency
		if info.spec == 66 then -- Protection
			addMod(info.guid, 1038, 0, 2)  -- Hand of Salvation
		end
		addMod(info.guid, 1022, 0, 2)  -- Hand of Protection
		addMod(info.guid, 1044, 0, 2)  -- Hand of Freedom
		addMod(info.guid, 6940, 0, 2)  -- Hand of Sacrifice
	end,
	[15775] = function(info) -- Juggernaut
		addMod(info.guid, 100, 8) -- Charge
	end,
	[16035] = function(info) -- Double Time
		addMod(info.guid, 100, 0, 2) -- Charge
	end,
	[19296] = function(info) -- Archimonde's Darkness
		if info.spec == 265 then -- Affliction
			addMod(info.guid, 113860, 0, 2) -- Dark Soul: Misery
		elseif info.spec == 266 then -- Demonology
			addMod(info.guid, 113861, 0, 2) -- Dark Soul: Knowledge
		elseif info.spec == 267 then -- Destruction
			addMod(info.guid, 113858, 0, 2) -- Dark Soul: Instability
		end
	end,
}

local specCooldowns = {
	[250] = function(info) -- Blood Death Knight
		if info.level >= 100 then
			addMod(info.guid, 49576, 5) -- Death Grip
			addMod(info.guid, 48982, 10) -- Rune Tap
		end
	end,
	[255] = function(info) -- Survival Hunter
		if info.level >= 100 then
			-- -9.9s (33% of 30s) on traps
			addMod(info.guid, 1499, 9.9) -- Freezing Trap
			addMod(info.guid, 13813, 9.9) -- Explosive Trap
			addMod(info.guid, 13809, 9.9) -- Ice Trap
			if info.glyphs[159470] then
				addMod(info.guid, 34600, 9.9) -- Snake Trap
			end
		end
	end,
	[62] = function(info) -- Arcane Mage
		if info.level >= 100 then
			addMod(info.guid, 12051, 30) -- Evocation
		end
	end,
	[63] = function(info) -- Fire Mage
		if info.level >= 100 then
			addMod(info.guid, 2120, 12) -- Flamestrike
		end
	end,
	[268] = function(info) -- Brewmaster Monk
		if info.level >= 100 then
			addMod(info.guid, 115295, 0, 2) -- Guard
			--addMod(info.guid, 101643, 35) -- Transcendence
		end
	end,
	[270] = function(info) -- Mistweaver Monk
		if info.level >= 100 then
			addMod(info.guid, 116849, 20) -- Life Cocoon
			--addMod(info.guid, 101643, 35) -- Transcendence
		end
	end,
	[70] = function(info) -- Retribution Paladin
		if info.level >= 100 then
			addMod(info.guid, 6940, 30) -- Hand of Sacrifice
		end
	end,
	[261] = function(info) -- Subtlety Rogue
		if info.level >= 100 then
			addMod(info.guid, 1856, 30) -- Vanish
		end
	end,
	[267] = function(info) -- Destruction Warlock
		if info.level >= 100 then
			addMod(info.guid, 80240, 5) -- Havoc
		end
	end,

	-- Unused perk mods:
	-- 269 Windwalker Monk: Transcendence -35s
	-- 257 Holy Priest: Chakras -20s
	-- 264 Restoration Shaman: Riptide -1s
}

local glyphCooldowns = {
	[55678] = {6346, 60}, -- Fear Ward, -60sec
	[63229] = {47585, 15}, -- Dispersion, -15sec
	[55455] = {2894, 150}, -- Fire Elemental Totem, -150sec (-50%)
	[63291] = {51514, 10}, -- Hex, -10sec
	[159640] = {51533, 60}, -- Feral Spirit, -60sec
	[159648] = {30823, 60}, -- Shamanistic Rage, -60sec
	[159650] = {79206, 60}, -- Spiritwalker's Grace, -60sec
	[63329] = {871, -120}, -- Shield Wall, +120sec
	[63325] = {52174, 15}, -- Heroic Leap, -15sec
	[55688] = {64044, 10}, -- Psychic Horror, -10sec
	[63309] = {48020, 4}, -- Demonic Circle: Teleport, -4sec
	[146962] = {80240, -35}, -- Havoc, +35sec
	[58058] = {556, 300}, -- Astral Recall, -300sec
	[55441] = {8177, -20}, -- Grounding Totem, +20sec
	[63270] = {51490, 10}, -- Thunderstorm, -10sec
	[63328] = {23920, 5}, -- Spell Reflection, -5sec
	[59219] = {1850, 60}, -- Dash, -60sec
	[58673] = {48792, 90}, -- Icebound Fortitude, -90sec (-50%)
	[56368] = {11129, -45}, -- Combustion, +45sec (+100%)
	[58686] = {47528, 1}, -- Mind Freeze, -1sec
	[116216] = {106839, -5}, -- Skull Bash, +5sec
	[114223] = {61336, 40}, -- Survival Instincts, -40sec
	[56376] = {122, 5}, -- Frost Nova, -5sec
	[146659] = {1953, 0, 2}, -- Blink, 2 charges
	[62210] = {12042, -90}, -- Arcane Power, +90sec (+100%)
	[115703] = {2139, -4}, -- Counterspell, +4sec
	[54925] = {96231, -5}, -- Rebuke, +5sec
	[56805] = {1766, -4}, -- Kick, +4sec
	[55451] = {57994, -3}, -- Wind Shear, +3sec
	[123391] = {115080, -120}, -- Touch of Death, +120sec
	[63331] = {77606, 30}, -- Dark Simulacrum, -30sec
	[59332] = {77575, 60}, -- Outbreak, -60sec
	[54939] = {633, -120}, -- Lay on Hands, +120sec
	[146955] = {31821, 60}, -- Devotion Aura, -60sec
	--[159548] = {31850, 110}, -- Ardent Defender, set to 60sec after 10s
}

-- { cd, level, spec id, talent index, glyph spell id }
local spells = {
	DEATHKNIGHT = {
		[49576] = {25, 55}, -- Death Grip
		[46584] = {60, 56}, -- Raise Dead
		[115989] = {90, 56, nil, 3}, -- Unholy Blight
		[47528] = {15, 57}, -- Mind Freeze
		[49039] = {120, 57, nil, 4}, -- Lichborne
		[51052] = {120, 57, nil, 5}, -- Anti-Magic Zone
		[96268] = {30, 58, nil, 7}, -- Death's Advance
		[47476] = {60, 58, nil, -9}, -- Strangulate
		[108194] = {30, 58, nil, 9}, -- Asphyxiate
		[43265] = {30, 60, nil, -20}, -- Death and Decay
		[48792] = {180, 62}, -- Icebound Fortitude
		[48982] = {40, 64, 250}, -- Rune Tap (2 charges)
		[48707] = {45, 68}, -- Anti-Magic Shell
		[51271] = {60, 68, 251}, -- Pillar of Frost
		[61999] = {600, 72}, -- Raise Ally
		[49028] = {90, 74, 250}, -- Dancing Rune Weapon
		[49206] = {180, 74, 252}, -- Summon Gargoyle
		[48743] = {120, 75, nil, 13}, -- Death Pact
		[47568] = {300, 76}, -- Empower Rune Weapon
		[55233] = {60, 76, 250}, -- Vampiric Blood
		[49222] = {60, 78, 250}, -- Bone Shield
		[42650] = {600, 80}, -- Army of the Dead
		[77575] = {60, 81}, -- Outbreak
		[77606] = {60, 85}, -- Dark Simulacrum
		[108199] = {60, 90, nil, 16}, -- Gorefiend's Grasp
		[108200] = {60, 90, nil, 17}, -- Remorseless Winter
		[108201] = {120, 90, nil, 18}, -- Desecrated Ground
		[152280] = {30, 100, nil, 20}, -- Defile
	},
	DRUID = {
		[18562] = {15, 10, 105}, -- Swiftmend
		[5217]  = {30, 10, 103}, -- Tiger's Fury
		[78674] = {30, 12, 102}, -- Starsurge (3 charges)
		[102280] = {30, 15, nil, 2}, -- Displacer Beast
		[16979] = {15, 15, nil, 3}, -- Wild Charge (Bear)
		[49376] = {15, 15, nil, 3}, -- Wild Charge (Cat)
		[102383] = {15, 15, nil, 3}, -- Wild Charge (Moonkin)
		[102416] = {15, 15, nil, 3}, -- Wild Charge (Aquatic)
		[102417] = {15, 15, nil, 3}, -- Wild Charge (Travel)
		[1850]  = {180, 24}, -- Dash
		[78675] = {60, 28, 102}, -- Solar Beam
		[132158] = {60, 30, nil, 4}, -- Nature's Swiftness
		[108238] = {120, 30, nil, 5}, -- Renewel
		[102351] = {30, 30, nil, 6}, -- Cenarion Ward
		[22812] = {60, 44, {102, 104, 105}}, -- Barkskin
		[102359] = {30, 45, nil, 8}, -- Mass Entanglement
		[132469] = {30, 45, nil, 9}, -- Typhoon
		[50334] = {180, 48, {103, 104}}, -- Berserk
		[20484] = {600, 56}, -- Rebirth
		[61336] = {180, 56, {103, 104}}, -- Survival Instincts
		[33891] = {180, 60, 105, 11}, -- Incarnation: Tree of Life
		[102543] = {180, 60, 103, 11}, -- Incarnation: King of the Jungle
		[102558] = {180, 60, 104, 11}, -- Incarnation: Son of Ursoc
		[102560] = {180, 60, 102, 11}, -- Incarnation: Chosen of Elune
		[33831] = {30, 60, 105, 12}, -- Force of Nature (3 charges)
		[102342] = {60, 64, 105}, -- Ironbark
		[106839] = {15, 64, {103, 104}}, -- Skull Bash
		[740]   = {180, 74, 105}, -- Tranquility
		[99] = {30, 75, nil, 13}, -- Incapacitating Roar
		[102793] = {60, 75, nil, 14}, -- Ursol's Vortex
		[5211] = {50, 75, nil, 15}, -- Mighty Bash
		[48505] = {30, 76, 102}, -- Starfall (3 charges)
		[77761] = {120, 84}, -- Stampeding Roar, Bear
		[77764] = 77761, -- Spampeding Roar, Cat
		[106898] = 77761, -- Spampeding Roar, Misc
		[108291] = {360, 90, nil, 16}, -- Heart of the Wild
		[124974] = {90, 90, nil, 18}, -- Nature's Vigil
		[155835] = {100, 30, 104, 21}, -- Bristling Fur
	},
	HUNTER = {
		[781]   = {20, 14}, -- Disengage
		[147362] = {24, 22}, -- Counter Shot
		[1499]  = {30, 28}, -- Freezing Trap
		[60192] = 1499, -- Freezing Trap + Launcher
		[109248] = {45, 30, nil, 4}, -- Binding Shot
		[19386] = {45, 30, nil, 5}, -- Wyvern Sting
		[19577] = {60, 30, nil, 6}, -- Intimidation
		[5384]  = {30, 32}, -- Feign Death
		[13813] = {30, 38}, -- Explosive Trap
		[82939] = 13813, -- Explosive Trap + Launcher
		[19574] = {60, 40, 253}, -- Bestial Wrath
		[34477] = {30, 42}, -- Misdirection
		[109304] = {120, 45, nil, 7}, -- Exhilaration
		[13809] = {30, 46}, -- Ice Trap
		[82941] = 13809, -- Ice Trap + Launcher
		[3674]  = {30, 50, 255}, -- Black Arrow
		[3045]  = {120, 54, 254}, -- Rapid Fire
		[120679] = {30, 60, nil, 11}, -- Dire Beast
		[34600] = {30, 66, nil, nil, 159470}, -- Snake Trap
		[82948] = 34600, -- Snake Trap + Launcher
		[53271] = {45, 74}, -- Master's Call
		[131894] = {60, 75, nil, 13}, -- A Murder of Crow
		[121818] = {300, 75, nil, 15}, -- Stampede
		[19263] = {180, 78}, -- Deterrence (2 charges)
		[51753] = {60, 85}, -- Camouflage
		[117050] = {15, 90, nil, 16}, -- Glaive Toss
		[109259] = {45, 90, nil, 17}, -- Powershot
		[120360] = {20, 90, nil, 18}, -- Barrage
		-- Pet
		[90355]  = {360, 20}, -- Ancient Hysteria
		[160452] = {360, 20}, -- Netherwinds
		[126393] = {600, 20}, -- Eternal Guardian
		[159956] = {600, 20}, -- Dust of Life
		[159931] = {600, 20}, -- Gift of Chi-Ji
	},
	MAGE = {
		[122]   = {30, 3, nil, -15}, -- Frost Nova
		[1953]  = {15, 7}, -- Blink
		[2139]  = {24, 8}, -- Counterspell
		[31687] = {60, 10, 64}, -- Summon Water Elemental
		[45438] = {300, 15, nil, -1}, -- Ice Block
		[157913] = {45, 15, nil, 1}, -- Evanesce
		[108843] = {25, 15, nil, 2}, -- Blazing Speed
		[108839] = {20, 15, nil, 3}, -- Ice Floes
		[12043] = {90, 22, 62}, -- Presence of Mind
		[120]   = {12, 28, {62, 64}}, -- Cone of Cold
		[108978] = {90, 30, nil, 4}, -- Alter Time
		[11426] = {25, 30, nil, 6}, -- Ice Barrier
		[12472] = {180, 36, 64}, -- Icy Veins
		[12051] = {120, 40}, -- Evocation
		[2120] = {12, 44, 63}, -- Flamestrike
		[113724] = {45, 45, nil, 7}, -- Ring of Frost
		[111264] = {20, 45, nil, 8}, -- Ice Ward
		[102051] = {20, 45, nil, 9}, -- Frostjaw
		[66]    = {300, 56, nil, -10}, -- Invisibility
		[110959] = {90, 60, nil, 10}, -- Greater Invisibility
		[11958] = {180, 60, nil, 12}, -- Cold Snap
		[84714] = {60, 62, 64}, -- Frozen Orb -- XXX Perk reduces CD from Blizzard damage
		[12042] = {90, 62, 62}, -- Arcane Power
		[31661] = {20, 62, 63}, -- Dragon's Breath
		[44572] = {30, 66, 64}, -- Deep Freeze
		[157980] = {25, 75, 62, 15}, -- Supernova (2 charges)
		[157981] = {25, 75, 63, 15}, -- Blast Wave (2 charges)
		[157997] = {25, 75, 64, 15}, -- Ice Nova (2 charges)
		[11129] = {45, 80, 63}, -- Combustion
		[80353] = {300, 84}, -- Time Warp
		[55342]  = {120, 90, nil, 16}, -- Mirror Image
		[152087]  = {90, 100, nil, 20}, -- Prismatic Crystal
		[153626]  = {15, 100, 62, 21}, -- Arcane Orb
		[153561]  = {45, 100, 63, 21}, -- Meteor
		[153561]  = {30, 100, 64, 21}, -- Comet Storm
	},
	MONK = {
		[116841] = {30, 15, nil, 2}, -- Tiger's Lust
		[101545] = {25, 18, 269}, -- Flying Serpent Kick
		[122470] = {90, 22, 269}, -- Touch of Karma
		[115080] = {90, 22}, -- Touch of Death
		[115203] = {180, 24}, -- Fortifying Brew
		[115295] = {30, 26, 268}, -- Guard
		[137562] = {120, 30}, -- Nimble Brew
		[115098] = {15, 30, nil, 4}, -- Chi Wave
		[124081] = {15, 10, nil, 5}, -- Zen Sphere
		[123986] = {15, 30, nil, 6}, -- Chi Burst
		[116705] = {15, 32}, -- Spear Hand Strike
		[115078] = {15, 44}, -- Paralysis
		[115399] = {15, 45, nil, 9}, -- Chi Brew
		[116849] = {120, 50, 270}, -- Life Cocoon
		[116844] = {45, 60, nil, 10}, -- Ring of Peace
		[119392] = {30, 60, nil, 11}, -- Charging Ox Wave
		[119381] = {45, 60, nil, 12}, -- Leg Sweep
		[116680] = {45, 66, 270}, -- Thunder Focus Tea
		[122278] = {90, 75, nil, 14}, -- Dampen Harm
		[122783] = {90, 75, nil, 15}, -- Diffuse Magic
		[115310] = {180, 78, 270}, -- Revival
		[115176] = {180, 82, {268, 269}}, -- Zen Meditation
		[123904] = {180, 90, nil, 17}, -- Invoke Xuen, the White Tiger
		[152173] = {90, 100, {268, 269}}, -- Serenity
		[152175] = {45, 100, 269}, -- Hurricane Strike
	},
	PALADIN = {
		[853]   = {60, 7, nil, -4}, -- Hammer of Justice
		[31935] = {15, 10, 66}, -- Avenger's Shield
		[85499] = {45, 15, nil, 1}, -- Speed of Light
		[633]   = {600, 16}, -- Lay on Hands
		[642]   = {300, 18}, -- Divine Shield
		[498]   = {60, 26}, -- Divine Protection
		[105593] = {30, 30, nil, 4}, -- Fist of Justice
		[20066]  = {15, 30, nil, 5}, -- Repentance
		[115750] = {120, 30, nil, 6}, -- Blinding Light
		[96231] = {15, 36}, -- Rebuke
		[10326] = {15, 46}, -- Turn Evil
		[1022]  = {300, 48}, -- Hand of Protection
		[1044]  = {25, 52}, -- Hand of Freedom
		[31821] = {180, 60, 65}, -- Devotion Aura
		[114039] = {30, 60, nil, 10}, -- Hand of Purity
		[1038]  = {120, 66, 66}, -- Hand of Salvation
		[31850] = {180, 70, 66}, -- Ardent Defender
		[31842] = {180, 72, 65}, -- Avenging Wrath (Holy)
		[31884] = {120, 72, 70}, -- Avenging Wrath (Ret)
		[86659] = {180, 75, 66}, -- Guardian of Ancient Kings (Prot)
		[105809] = {120, 75, nil, 13}, -- Holy Avenger
		[6940]  = {120, 80}, -- Hand of Sacrifice
		[114165] = {20, 90, nil, 16}, -- Holy Prism
		[114158] = {60, 90, nil, 17}, -- Light's Hammer
		[114157] = {60, 90, nil, 18}, -- Execution Sentence
		[152262] = {30, 100, {66, 70}, 20}, -- Seraphim
	},
	PRIEST = {
		[88625] = {30, 10, 257}, -- Holy Word: Chastise
		[88684] = {10, 10, 257}, -- Holy Word: Serenity
		[88685] = {40, 10, 257}, -- Holy Word: Sanctuary
		[19236] = {120, 15, nil, 1}, -- Desperate Prayer
		[112833] = {30, 15, nil, 2}, -- Spectral Guise
		[586]   = {30, 24}, -- Fade
		[724]   = {180, 36, 257}, -- Lightwell
		[34433] = {180, 42, nil, -8}, -- Shadowfiend
		[123040] = {60, 45, nil, 8}, -- Mindbender
		[81700] = {30, 50, 256}, -- Archangel
		[15487] = {45, 52, {256, 258}}, -- Silence
		[6346]  = {180, 54}, -- Fear Ward
		[33206] = {180, 58, 256}, -- Pain Suppression
		[47585] = {120, 60, 258}, -- Dispersion
		[108920] = {30, 60, nil, 10}, -- Void Tendrils
		[8122]  = {45, 60, nil, 11}, -- Psychic Scream
		[62618] = {180, 70, 256}, -- Power Word: Barrier
		[47788] = {180, 70, 257}, -- Guardian Spirit
		[10060] = {120, 75, nil, 14}, -- Power Infusion
		[109964] = {60, 75, 256, 15}, -- Spirit Shell
		[64843] = {180, 78, 257}, -- Divine Hymn
		[64044] = {120, 74, 258}, -- Psychic Horror
		[15286] = {180, 78, 258}, -- Vampiric Embrace
		[73325] = {90, 84}, -- Leap of Faith
		[121135] = {25, 90, {256, 257}, 16}, -- Cascade
		[127632] = {25, 90, 258, 16}, -- Cascade (Shadow)
		[121135] = {15, 90, {256, 257}, 17}, -- Divine Star
		[122121] = {15, 90, 258, 17}, -- Divine Star (Shadow)
		[120517] = {40, 90, {256, 257}, 18}, -- Halo
		[120644] = {40, 90, 258, 18}, -- Halo (Shadow)
	},
	ROGUE = {
		[5277]  = {120, 8}, -- Evasion
		[1766]  = {15, 18}, -- Kick
		[1776]  = {10, 22}, -- Gouge
		[1725]  = {30, 28}, -- Distract
		[74001] = {120, 30, nil, 6}, -- Combat Readiness
		[14183] = {20, 30, 261}, -- Premeditation
		[1856]  = {120, 34}, -- Vanish
		[2094]  = {120, 38}, -- Blind
		[408]   = {20, 40}, -- Kidney Shot
		[13750] = {180, 40, 260}, -- Adrenaline Rush
		[31224] = {60, 58}, -- Cloak of Shadows
		[36554] = {20, 60, nil, 11}, -- Shadowstep
		[14185] = {300, 68}, -- Preparation
		[57934] = {30, 78}, -- Tricks of the Trade
		[79140] = {120, 80, 259}, -- Vendetta
		[51690] = {120, 80, 260}, -- Killing Spree
		[51713] = {60, 80, 261}, -- Shadow Dance
		[51690] = {120, 80, 260}, -- Killing Spree
		[76577] = {180, 85}, -- Smoke
		[137619] = {60, 90, nil, 17}, -- Marked for Death
		[137619] = {120, 100, nil, 20}, -- Shadow Reflection
		[137619] = {20, 100, nil, 21}, -- Shadow Reflection
	},
	SHAMAN = {
		[51490] = {45, 10, 262}, -- Thunderstorm
		[108270] = {60, 15, nil, 2}, -- Stone Bulwark Totem
		[108271] = {90, 15, nil, 3}, -- Astral Shift
		[57994] = {12, 16}, -- Wind Shear
		[2484]  = {30, 26, nil, -5}, -- Earthbind Totem
		[51485] = {30, 30, nil, 5}, -- Earthgrab Totem
		[108273] = {60, 30, nil, 6}, -- Windwalk Totem
		[20608] = {1800, 32}, -- Reincarnation
		[8177]  = {25, 38}, -- Grounding Totem
		[108285] = {180, 45, nil, 7}, -- Call of the ELements
		[8143]  = {60, 54}, -- Tremor Totem
		[2062]  = {300, 58}, -- Earth Elemental Totem
		[51533] = {120, 60, 263}, -- Feral Spirit
		[16166] = {120, 60, nil, 10}, -- Elemental Mastery
		[16188] = {90, 60, nil, 11}, -- Ancestral Swiftness
		[30823] = {60, 65, {262, 263}}, -- Shamanistic Rage
		[108280] = {180, 65, 264}, -- Healing Tide Totem
		[2894]  = {300, 66}, -- Fire Elemental Totem
		[UnitFactionGroup("player") == "Horde" and 2825 or 32182] = {300, 70}, -- Bloodlust/Heroism
		[98008] = {180, 70, 264}, -- Spirit Link Totem
		[51514] = {45, 75}, -- Hex
		[108281] = {120, 75, nil, 14}, -- Ancestral Guidance
		[79206] = {120, 85, {262, 264}}, -- Spiritwalker's Grace
		[114049] = {180, 87}, -- Ascendance (old id, but keeping it for compat as the master option for the 3 merged spells)
		[114050] = 114049, -- Ascendance (Elemental)
		[114051] = 114049, -- Ascendance (Enhancement)
		[114052] = 114049, -- Ascendance (Restoration)
		[157153] = {30, 100, 264, 19}, -- Cloudburst Totem
		[152256] = {300, 100, nil, 20}, -- Storm Elemental Totem
		[152256] = {45, 100, {262, 263}, 21}, -- Liquid Magma
	},
	WARLOCK = {
		[108359] = {120, 15, nil, 1}, -- Dark Regeneration
		[20707] = {600, 18}, -- Soulstone
		[95750] = 20707, -- Soulstone Resurrection (combat)
		[5484]  = {40, 30, nil, 4}, -- Howl of Terror -- XXX CD reduced when player is damaged
		[6789]  = {45, 30, nil, 5}, -- Mortal Coil
		[30283] = {30, 30, nil, 6}, -- Shadowfury
		[80240] = {20, 36, 267}, -- Havoc
		[698]   = {120, 42}, -- Ritual of Summoning
		[108416] = {60, 45, nil, 8}, -- Sacrificial Pact
		[110913] = {180, 45, nil, 9}, -- Dark Bargain
		[1122]  = {600, 49, nil, -21}, -- Summon Infernal
		[18540] = {600, 58, nil, -21}, -- Summon Doomguard
		[111397] = {60, 60, nil, 10}, -- Blood Horror
		[108482] = {120, 60, nil, 12}, -- Unbound Will
		[104773] = {180, 64}, -- Unending Resolve
		[29858] = {120, 66}, -- Soulshatter
		[29893] = {120, 68}, -- Create Soulwell
		[108501] = {120, 75, nil, 14}, -- Grimoire of Service
		[48020] = {30, 76}, -- Demonic Circle: Teleport
		[120451] = {60, 79, 267}, -- Flames of Xoroth
		[113860] = {120, 84, 265}, -- Dark Soul: Misery
		[113861] = {120, 84, 266}, -- Dark Soul: Knowledge
		[113858] = {120, 84, 267}, -- Dark Soul: Instability
		[137587] = {35, 90, nil, 17}, -- Kil'jaden's Cunning
		[108508] = {60, 90, nil, 18}, -- Mannoroth's Fury
		[152108] = {60, 100, nil, 20}, -- Cataclysm
		-- Pet
		[19647]  = {24, 50}, -- Felhunter Spell Lock (Normal, originates from pet)
		[119910] = 19647, -- Felhunter Spell Lock (via Command Demon, originates from player)
		[132409] = 19647, -- Felhunter Sacrifice, Spell Lock
		[119911] = 19647, -- Observer Optical Blast (via Command Demon, originates from player)
		[115781] = 19647, -- Observer Optical Blast (Normal, originates from pet)
		[171140] = 19647, -- Doomguard Shadow Lock (via Command Demon, originates from player)
		[171139] = 19647, -- Doomguard Sacrifice, Shadow Lock
	},
	WARRIOR = {
		[100]   = {20, 3}, -- Charge
		[6552]  = {15, 24}, -- Pummel
		[55694] = {60, 30, nil, 4}, -- Enraged Regeneration
		[12975] = {180, 38, 73}, -- Last Stand
		[871]   = {120, 48, 73}, -- Shield Wall
		[5246]  = {90, 52}, -- Intimidating Shout
		[18499]  = {30, 54}, -- Berserk Rage
		[118038]  = {120, 56, {71, 72}}, -- Die by the Sword
		[107570] = {30, 60, nil, 10}, -- Storm Bolt
		[12328] = {10, 60, 71}, -- Sweeping Strikes
		[118000] = {60, 60, nil, 12}, -- Dragon Roar
		[46968] = {40, 60, nil, 11}, -- Shockwave -- XXX -20s if hits 3 targets
		[23920] = {25, 66, nil, -13}, -- Spell Reflection
		[3411]  = {30, 72, nil, -14}, -- Intervene
		[64382] = {300, 74, nil, nil, 159759}, -- Shattering Throw
		[114028] = {30, 75, nil, 13}, -- Mass Spell Reflection
		[114029] = {30, 75, nil, 14}, -- Safeguard
		[114030] = {120, 75, nil, 15}, -- Vigilance
		[86346] = {20, 81, 71}, -- Colossus Smash
		[97462] = {180, 83, {71, 72}}, -- Rallying Cry
		[52174]  = {45, 85}, -- Heroic Leap
		[1719]  = {180, 87, {71, 72}}, -- Recklessness
		[114192] = {180, 87, 73}, -- Mocking Banner
		[107574] = {180, 90, nil, 16}, -- Avatar
		[12292] = {60, 90, nil, 17}, -- Bloodbath
		[46924] = {60, 90, nil, 18}, -- Bladestorm
		[152277] = {60, 100, nil, 20}, -- Ravager
		[176289] = {45, 100, {71, 72}, 21}, -- Seigebreaker
	},
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
	-- these will always return the charge info with GetSpellCharges
	[78674] = 3, -- Starsurge (3 charges)
	[48505] = 3, -- Starfall (3 charges)
	[33831] = 3, -- Force of Nature (3 charges)
	[19263] = 2, -- Deterrence (2 charges)
	[48982] = 2, -- Rune Tap (2 charges)
	[157980] = 2, -- Supernova (2 charges)
	[157981] = 2, -- Blast Wave (2 charges)
	[157997] = 2, -- Ice Nova (2 charges)
	-- nil without glyph or talent
	--[1953] = 2, -- Blink (2 charges with glyph)
	--[115295] = 2, -- Guard (2 charges with perk)
	--[6940] = 2, -- Hand of Sacrifice (2 charges with talent)
	--[113860] = 2, -- Dark Soul: Misery (2 charges with talent)
	--[113861] = 2, -- Dark Soul: Knowledge (2 charges with talent)
	--[113858] = 2, -- Dark Soul: Instability (2 charges with talent)
	--[100] = 2, -- Charge (2 charges with talent)
}

local mergeSpells = {}
local allSpells = {}
local classLookup = {}
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
		else
			print("oRA3: Invalid spell id", spellId)
		end
	end
end


local function guidToUnit(guid)
	local token = IsInRaid and "raid%d" or "party%d"
	for i = 1, GetNumGroupMembers() do
		local unit = token:format(i)
		if UnitGUID(unit) == guid then
			return unit
		end
	end
	if UnitGUID("player") == guid then
		return "player"
	end
end

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

	local _, level, spec, talent, glyph = unpack(data)
	local usable = (info.level >= level) and
		(not talent or ((talent > 0 and info.talents[talent]) or (talent < 0 and not info.talents[-talent]))) and -- handle talents replacing spells (negative talent index)
		(not glyph or info.glyphs[glyph]) and
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

	local index = info and info.unit:match("raid(%d+)")
	if index then
		local _, _, group = GetRaidRosterInfo(index)
		if db.hideGroup[group] then return end
	end

	local role = info and GetSpecializationRoleByID(info.spec or 0) or UnitGroupRolesAssigned(player)
	if db.hideRoles[role] then return end

	local inInstance, instanceType = IsInInstance() -- this should really act on the display itself
	if inInstance and db.hideInInstance[instanceType] then return end
	if db.hideInInstance.lfg and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return end

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
			for k in next, allSpells do spellList[#spellList + 1] = k end
			for name, class in next, oRA._testUnits do reverseClass[class] = name end
		end

		local spellId = spellList[math.random(1, #spellList)]
		local class = classLookup[spellId]
		local duration = (allSpells[spellId][1] / 30) + math.random(1, 120)
		display:TestCooldown(reverseClass[class], class, spellId, duration)
	end

	local tmp = {}
	local tabStatus, classStatus, filterStatus = { selected = "tab1", scrollvalue = 0 }, { selected = "ALL", scrollvalue = 0 }, { scrollvalue = 0 }
	local displayList = {}
	local classList = nil

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

	StaticPopupDialogs["ORA3_COOLDOWNS_NEW"] = {
		text = L.popupNewDisplay,
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = function(self)
			local name = self.editBox:GetText()
			if activeDisplays[name] then
				StaticPopup_Show("ORA3_COOLDOWNS_ERROR_NAME", name, nil, self.data)
				return
			end
			createDisplay(name, self.data)
		end,
		OnCancel = function(self) showPane() end,
		OnShow = function(self) self.editBox:SetFocus() end,
		EditBoxOnEnterPressed = function(editBox)
			local self = editBox:GetParent()
			local name = editBox:GetText():trim()
			self:Hide()
			if activeDisplays[name] then
				StaticPopup_Show("ORA3_COOLDOWNS_ERROR_NAME", name, nil, self.data)
				return
			end
			createDisplay(name, self.data)
		end,
		EditBoxOnEscapePressed = function(editBox)
			editBox:GetParent():Hide()
			showPane()
		end,
		timeout = 0,
		hideOnEscape = 1,
		exclusive = 1,
		whileDead = 1,
		hasEditBox = 1,
		preferredIndex = 3,
	}

	StaticPopupDialogs["ORA3_COOLDOWNS_ERROR_NAME"] = {
		text = L.popupNameError,
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = function(self) StaticPopup_Show("ORA3_COOLDOWNS_NEW", nil, nil, self.data) end,
		OnCancel = function(self) showPane() end,
		timeout = 0,
		hideOnEscape = 1,
		whileDead = 1,
		exclusive = 1,
		showAlert = 1,
		preferredIndex = 3,
	}

	StaticPopupDialogs["ORA3_COOLDOWNS_DELETE"] = {
		text = L.popupDeleteDisplay,
		button1 = YES,
		button2 = CANCEL,
		OnAccept = function(self) deleteDisplay(self.data) end,
		OnCancel = function(self) showPane() end,
		timeout = 0,
		hideOnEscape = 1,
		whileDead = 1,
		exclusive = 1,
		preferredIndex = 3,
	}

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
		if classLookup[a] == classLookup[b] then
			return GetSpellInfo(a) < GetSpellInfo(b)
		else
			return classLookup[a] < classLookup[b]
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

	local function onOptionChanged(widget, event, value, ...)
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
			-- all spells
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
			-- class spells
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
			group:SetGroupList(classList)
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
			StaticPopup_Show("ORA3_COOLDOWNS_NEW")
		elseif value == "__newcopy" then
			StaticPopup_Show("ORA3_COOLDOWNS_NEW", nil, nil, true)
		elseif value == "__delete" then
			StaticPopup_Show("ORA3_COOLDOWNS_DELETE", CURRENT_DISPLAY, nil, CURRENT_DISPLAY)
		else
			CURRENT_DISPLAY = value
			showPane()
		end
	end

	function showPane()
		if not classList then
			classList = { ALL = L.allSpells }
			for class in next, spells do
				classList[class] = string.format("|c%s%s|r", oRA.classColors[class].colorStr, LOCALIZED_CLASS_NAMES_MALE[class])
			end
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

		if not CURRENT_DISPLAY then
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

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("Cooldowns", {
		profile = {
			spells = {},
			displays = {
				["*"] = {
					showDisplay = true,
					lockDisplay = false,
				}
			},
			filters = {
				["*"] = {
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
	}, L.cooldowns)

	-- persist on reloads
	spellsOnCooldown = self.db.global.spellsOnCooldown
	chargeSpellsOnCooldown = self.db.global.chargeSpellsOnCooldown

	-- convert db, a little awkward due to the "*" defaults
	if not next(self.db.profile.displays) then
		local db = self.db.profile

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
		local settingsDB = db.displays.Default
		settingsDB.type = "Bars"
		settingsDB.showDisplay = true
		settingsDB.lockDisplay = false
		for k, v in next, db do
			if k ~= "displays" and k ~= "spells" and k ~= "filters" and k ~= "enabled" then
				if k:find("^bar") then
					settingsDB[k] = type(db[k]) == "table" and CopyTable(db[k]) or db[k]
				end
				db[k] = nil
			end
		end
		settingsDB.enabled = true

		-- update position
		if oRA.db.profile.positions.oRA3CooldownFrame then
			oRA.db.profile.positions.oRA3CooldownFrameBarsDefault = CopyTable(oRA.db.profile.positions.oRA3CooldownFrame)
			oRA.db.profile.positions.oRA3CooldownFrame = nil
		end

		self:ScheduleTimer(function()
			print("oRA3 Cooldowns has been redesigned and now supports multiple displays and different formats! You can open the options panel with /racd and move it around by dragging the title bar.")
		end, 9)
	end

	for displayName, db in next, self.db.profile.displays do
		local display = self:CreateDisplay(db.type, displayName)
		activeDisplays[displayName] = display
		display:Hide()
	end

	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
	self:RegisterEvent("PLAYER_LOGOUT")

	local _, playerClass = UnitClass("player")
	if playerClass == "SHAMAN" then
		-- GetSpellCooldown returns 0 when UseSoulstone is invoked, so we delay the check
		function checkReincarnationCooldown()
			local start, duration = GetSpellCooldown(20608)
			if start > 0 and duration > 1.5 then
				local elapsed = GetTime() - start -- don't resend the full duration if already on cooldown
				module:SendComm("Reincarnation", duration-elapsed)
			end
		end
		hooksecurefunc("UseSoulstone", function()
			if IsInGroup() then
				module:ScheduleTimer(checkReincarnationCooldown, 1)
			end
		end)
	end

	oRA:RegisterPanel(L.cooldowns, showPane, hidePane)

	SLASH_ORACOOLDOWN1 = "/racd"
	SLASH_ORACOOLDOWN2 = "/racooldown"
	SlashCmdList.ORACOOLDOWN = function()
		oRA:SelectPanel(L.cooldowns)
	end
end

function module:OnStartup(_, groupStatus)
	if not self.db.profile.enabled then return end

	callbacks:Fire("OnStartup")

	oRA.RegisterCallback(self, "OnCommReceived")
	oRA.RegisterCallback(self, "OnGroupChanged")
	self:OnGroupChanged(nil, groupStatus, oRA:GetGroupMembers())

	LGIST.RegisterCallback(self, "GroupInSpecT_Update")
	LGIST.RegisterCallback(self, "GroupInSpecT_Remove")
	LGIST:Rescan()

	--self:RegisterEvent("PLAYER_REGEN_DISABLED")
	--self:RegisterEvent("PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED")
	self:RegisterEvent("UNIT_CONNECTION")
	combatLogHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:ScheduleRepeatingTimer(combatOnUpdate, 0.1)
end

function module:OnShutdown()
	if not self.db.profile.enabled then return end

	callbacks:Fire("OnShutdown")

	oRA.UnregisterCallback(self, "OnCommReceived")
	oRA.UnregisterCallback(self, "OnGroupChanged")

	LGIST.UnregisterAllCallbacks(self)

	--self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	--self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("UNIT_HEALTH")
	self:UnregisterEvent("UNIT_CONNECTION")
	combatLogHandler:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	wipe(combatLogHandler.userdata)
	self:CancelAllTimers()

	wipe(infoCache)
	wipe(cdModifiers)
	wipe(chargeModifiers)
	wipe(deadies)
end

-- db cleanup
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

	function module:PLAYER_LOGOUT()
		-- db settings
		for displayName, display in next, activeDisplays do
			removeDefaults(self.db.profile.displays[displayName], display.defaultDB)
		end

		-- spell cds
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
	end
end

--------------------------------------------------------------------------------
-- Events
--

function module:OnCommReceived(_, sender, prefix, cd)
	if prefix == "Reincarnation" then
		local guid = UnitGUID(sender)
		callbacks:Fire("oRA3CD_StartCooldown", guid, sender, "SHAMAN", 20608, tonumber(cd))
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
				self:RegisterEvent("UNIT_HEALTH")
			end
			if not infoCache[guid] then
				local _, class = UnitClass(player)
				if class then
					infoCache[guid] = {
						guid = guid,
						name = player,
						class = class,
						level = UnitLevel(player),
						glyphs = {},
						talents = {},
						unit = "",
					}
					updateCooldownsByGUID(guid)
				end
			end
		end
	end

	if checkReincarnationCooldown then
		checkReincarnationCooldown()
	end
end

function module:GroupInSpecT_Update(_, guid, unit, info)
	if not guid or not info.class then return end

	if not infoCache[guid] then
		infoCache[guid] = {
			guid = guid,
			name = info.name,
			class = info.class,
			level = UnitLevel(unit),
			glyphs = {},
			talents = {},
			unit = "",
		}
	end

	if info.global_spec_id and info.global_spec_id > 0 then
		local cache = infoCache[guid]
		cache.level = UnitLevel(unit)
		cache.spec = info.global_spec_id
		cache.unit = unit ~= "player" and unit or guidToUnit(guid) or ""

		for _, mods in next, cdModifiers do mods[guid] = nil end
		for _, mods in next, chargeModifiers do mods[guid] = nil end

		wipe(cache.glyphs)
		for spellId in next, info.glyphs do
			if glyphCooldowns[spellId] then
				local spell, modifier = unpack(glyphCooldowns[spellId])
				addMod(guid, spell, modifier)
			end
			cache.glyphs[spellId] = true
		end

		wipe(cache.talents)
		for talentId, talentInfo in next, info.talents do
			if talentCooldowns[talentId] then
				talentCooldowns[talentId](cache)
			end
			-- easier to look up by index than to try and check multiple talent spell ids
			local index = 3 * (talentInfo.tier - 1) + talentInfo.column
			cache.talents[index] = true
		end

		-- handle perks (apply all perks to players at level 100)
		if specCooldowns[cache.spec] then
			specCooldowns[cache.spec](cache)
		end
	end

	updateCooldownsByGUID(guid)
end

function module:GroupInSpecT_Remove(_, guid)
	if not guid then return end

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

function module:UNIT_HEALTH(unit)
	local guid = UnitGUID(unit)
	if guid and deadies[guid] and not UnitIsDeadOrGhost(unit) then
		deadies[guid] = nil
		callbacks:Fire("oRA3CD_UpdatePlayer", guid, self:UnitName(unit))
	end
	if not next(deadies) then
		self:UnregisterEvent("UNIT_HEALTH")
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

	local function resetCooldown(guid, player, spellId, duration, charges)
		local class = classLookup[spellId]
		callbacks:Fire("oRA3CD_StopCooldown", guid, spellId)
		if duration then
			if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
			spellsOnCooldown[spellId][guid] = GetTime() + duration
			callbacks:Fire("oRA3CD_StartCooldown", guid, player, class, spellId, duration)
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
	local scratch = combatLogHandler.userdata

	local inEncounter = nil
	local band = bit.band
	local group = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
	local pet = bit.bor(COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET)

	combatLogHandler:SetScript("OnEvent", function(self, _, _, event, _, srcGUID, source, srcFlags, _, destGUID, destName, dstFlags, _, spellId, spellName, _, ...)
		if event == "UNIT_DIED" then
			if band(dstFlags, group) ~= 0 and UnitIsPlayer(destName) and not UnitIsFeignDeath(destName) then
				callbacks:Fire("oRA3CD_UpdatePlayer", destGUID, destName)
				deadies[destGUID] = true
				module:RegisterEvent("UNIT_HEALTH")
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
					callbacks:Fire("oRA3CD_StartCooldown", srcGUID, source, classLookup[spellId], spellId, expires[1] - t)
				end
				callbacks:Fire("oRA3CD_UpdateCharges", srcGUID, source, classLookup[spellId], spellId, cd, charges, maxCharges)
				return
			end

			if band(srcFlags, pet) > 0 then
				source, srcGUID = getPetOwner(source, srcGUID)
			end

			if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
			local cd = module:GetCooldown(srcGUID, spellId)
			spellsOnCooldown[spellId][srcGUID] = GetTime() + cd

			callbacks:Fire("oRA3CD_StartCooldown", srcGUID, source, classLookup[spellId], spellId, cd)
		end

		-- Special cooldown conditions
		-- XXX should move these to a lookup table to a more performant
		if event == "SPELL_DISPEL" then
			local extraSpellId = ...
			if extraSpellId == 3674 then -- Black Arrow
				resetCooldown(destGUID, destName, extraSpellId)
			end

		elseif event == "SPELL_HEAL" then
			if spellId == 66235 then -- Ardent Defender
				scratch[srcGUID] = true
			end

		elseif event == "SPELL_CAST_SUCCESS" then
			if spellId == 11958 then -- Cold Snap
				local spec = infoCache[srcGUID] and infoCache[srcGUID].spec
				if not spec then return end

				-- reset Ice Block, Presence of Mind, Dragon's Breath, Cone of Cold, Frost Nova
				resetCooldown(srcGUID, source, 45438) -- Ice Block
				if spec == 62 then resetCooldown(srcGUID, source, 12043) end  -- Presence of Mind
				if spec == 63 then resetCooldown(srcGUID, source, 31661) end  -- Dragon's Breath
				if spec == 64 then resetCooldown(srcGUID, source, 120) end  -- Cone of Cold
				if module:IsSpellUsable(srcGUID, 122) then resetCooldown(srcGUID, source, 122) end -- Frost Nova
			end

		elseif event == "SPELL_AURA_APPLIED" then
			if spellId == 48707 then -- Anti-Magic Shell
				local info = infoCache[srcGUID]
				if not info then return end

				local _, amount = ...
				if amount > 0 and info.glyphs[146648] then -- Glyph of Regenerative Magic
					scratch[srcGUID] = amount
				end
			end

		elseif event == "SPELL_AURA_REMOVED" then
			if spellId == 48707 then -- Anti-Magic Shell
				local _, amount = ...
				if amount > 0 and scratch[srcGUID] then
					local cd = module:GetRemainingCooldown(srcGUID, spellId)
					if cd < 41 then
						local maxAbsorb = scratch[srcGUID]
						scratch[srcGUID] = nil

						-- reduce remaining cd (should be ~40s) by half of the remaining absorb % (so 100% left would reduce the cd by 50%, or 20s)
						local cd = cd - (min(amount / maxAbsorb, 1) * 0.5 * cd)
						resetCooldown(srcGUID, source, spellId, cd)
					end
				end
			elseif spellId == 31850 then -- Ardent Defender
				local info = infoCache[srcGUID]
				if not info then return end

				if info.glyphs[159548] and not scratch[srcGUID] then -- Glyph of Ardent Defender
					resetCooldown(srcGUID, source, spellId, 50) -- reset to 60s (less the 10s it was active)
				end
				scratch[srcGUID] = nil
			end

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
			-- Dark Soul: Misery, Knowledge, Instability are reset
			for _, spellId in next, {113860, 113861, 113858} do
				spellsOnCooldown[spellId] = nil
				chargeSpellsOnCooldown[spellId] = nil
				updateCooldownsBySpell(spellId)
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

