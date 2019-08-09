
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	return
end

--------------------------------------------------------------------------------
-- Setup
--

local _, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Cooldowns", "AceTimer-3.0")
local L = scope.locale
local callbacks = LibStub("CallbackHandler-1.0"):New(module)
local LibDialog = LibStub("LibDialog-1.0")

-- luacheck: globals GameFontHighlight GameFontHighlightLarge GameTooltip_Hide CombatLogGetCurrentEventInfo

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
local syncSpells = {}
local spellsOnCooldown, chargeSpellsOnCooldown = nil, nil
local deadies = {}
local playerGUID = UnitGUID("player")
local _, playerClass = UnitClass("player")
local instanceType, instanceDifficulty = nil, nil

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
	[22014] = function(info) -- Blood: Anti-Magic Barrier
		addMod(info.guid, 48707, 15) -- Anti-Magic Shell
	end,
	[19226] = function(info) -- Blood: Tightening Grasp
		addMod(info.guid, 108199, 30) -- Gorefiend's Grasp
	end,

	-- Demon Hunter
	[21869] = function(info) -- Havoc: Unleashed Power
		addMod(info.guid, 179057, 20) -- Chaos Nova
	end,
	-- [21864] = function(info) -- Havoc: Desperate Instincts
	-- 	-- You automatically trigger Blur when you fall below 35% health.
	-- 	if info.guid == playerGUID then
	-- 		syncSpells[198589] = true -- Blur
	-- 	end
	-- end,
	[21866] = function(info) -- Havoc: Cycle of Hatred
		-- When Chaos Strike refunds Fury, it also reduces the cooldown of
		-- Metamorphosis by 3 sec.
		if info.guid == playerGUID then
			syncSpells[200166] = true -- Metamorphosis
		end
	end,
	[21870] = function(info) -- Havoc: Master of the Glaive
		addMod(info.guid, 185123, 0, 2) -- Throw Glaive
	end,
	[22502] = function(info) -- Vengeance: Abyssal Strike
		addMod(info.guid, 189110, 8) -- Inferal Strike
	end,
	[22510] = function(info) -- Vengeance: Quickened Sigils
		addMod(info.guid, 202137, 12) -- Sigil of Silence
		addMod(info.guid, 204596, 6)  -- Sigil of Flame
		addMod(info.guid, 207684, 18) -- Sigil of Misery
		if info.talents[15] then
			addMod(info.guid, 202138, 18) -- Sigil of Chains
		end
	end,

	-- Druid
	[22157] = function(info) -- Balance: Guardian Affinity
		addMod(info.guid, 22842, 0, 1) -- Frenzied Regeneration
	end,
	[22364] = function(info) -- Feral: Predator
		-- The cooldown on Tiger's Fury resets when a target dies with one of your
		-- Bleed effects active
		if info.guid == playerGUID then
			syncSpells[5217] = true -- Tiger's Fury
		end
	end,
	[22158] = function(info) -- Feral: Guardian Affinity
		addMod(info.guid, 22842, 0, 1) -- Frenzied Regeneration
	end,
	[22160] = function(info) -- Restoration: Guardian Affinity
		addMod(info.guid, 22842, 0, 1) -- Frenzied Regeneration
	end,
	[21713] = function(info) -- Guardian: Survival of the Fittest
		addMod(info.guid, 22812, 30) -- Barkskin
		addMod(info.guid, 61336, 60) -- Survival Instincts
	end,
	[21716] = function(info) -- Restoration: Inner Peace
		addMod(info.guid, 740, 60) -- Tranquility
	end,
	[18585] = function(info) -- Restoration: Stonebark
		addMod(info.guid, 102342, 15) -- Ironbark
	end,
	-- Guardian: Adjust cooldowns
	[22419] = function(info) -- Brambles
		addMod(info.guid, 22812, -30) -- Barkskin
		addMod(info.guid, 61336, -120) -- Survival Instincts
		if info.level >= 80 then
			addMod(info.guid, 106898, 60) -- Stampeding Roar
		end
	end,
	[22418] = function(info) -- Blood Frenzy
		addMod(info.guid, 22812, -30) -- Barkskin
		addMod(info.guid, 61336, -120) -- Survival Instincts
		if info.level >= 80 then
			addMod(info.guid, 106898, 60) -- Stampeding Roar
		end
	end,
	[22420] = function(info) -- Bristling Fur
		addMod(info.guid, 22812, -30) -- Barkskin
		addMod(info.guid, 61336, -120) -- Survival Instincts
		if info.level >= 80 then
			addMod(info.guid, 106898, 60) -- Stampeding Roar
		end
	end,

	-- Hunter
	[19348] = function(info) -- All: Natural Mending
		-- Focus you spend reduces the remaining cooldown on Exhilaration by 1 sec.
		if info.guid == playerGUID then
			syncSpells[109304] = true -- Exhilaration
		end
	end,
	[22268] = function(info) -- All: Born To Be Wild
		addMod(info.guid, 186257, 36) -- Aspect of the Cheetah
		addMod(info.guid, 186265, 36) -- Aspect of the Turtle
		if info.spec == 255 then -- Survival
			addMod(info.guid, 186289, 18) -- Aspect of the Eagle
		end
	end,
	[21997] = function(info) -- Survival: Guerrilla Tactics
		addMod(info.guid, 259495, 0, 2) -- Wildfire Bomb
	end,

	-- Mage
	[22448] = function(info) -- Ice Ward
		addMod(info.guid, 122, 0, 2) -- Frost Nova
	end,
	[23072] = function(info)
		addMod(info.guid, 235450, 25) -- Primastic Barrier (removes cd)
	end,

	-- Monk
	[19304] = function(info) -- Celerity
		addMod(info.guid, 109132, 5, 3) -- Roll
	end,
	[19993] = function(info) -- Tiger Tail Sweep
		addMod(info.guid, 119381, 10) -- Leg Sweep
	end,

	-- Paladin
	[17575] = function(info) -- Holy: Cavalier
		addMod(info.guid, 190784, 0, 2) -- Divine Steed
	end,
	[22434] = function(info) -- Protection: Cavalier
		addMod(info.guid, 190784, 0, 2) -- Divine Steed
	end,
	[22185] = function(info) -- Retribution: Cavalier
		addMod(info.guid, 190784, 0, 2) -- Divine Steed
	end,
	[22176] = function(info) -- Holy: Unbreakable Spirit (-30%)
		addMod(info.guid, 642, 100) -- Divine Shield
		addMod(info.guid, 633, 200) -- Lay on Hands
		addMod(info.guid, 498, 18) -- Divine Protection
	end,
	[22705] = function(info) -- Protection: Unbreakable Spirit (-30%)
		addMod(info.guid, 642, 100) -- Divine Shield
		addMod(info.guid, 633, 200) -- Lay on Hands
		addMod(info.guid, 31850, 36) -- Ardent Defender
	end,
	[22595] = function(info) -- Retribution: Unbreakable Spirit (-30%)
		addMod(info.guid, 642, 100) -- Divine Shield
		addMod(info.guid, 633, 200) -- Lay on Hands
		addMod(info.guid, 184662, 36) -- Shield of Vengeance
	end,

	-- Priest
	[22094] = function(info) -- Disc/Holy: Psychic Voice
		addMod(info.guid, 8122, 30) -- Psychic Scream
	end,
	[22325] = function(info) -- Holy: Angel's Mercy
		-- Damage you take reduces the cooldown of Desperate Prayer, based on the
		-- amount of damage taken.
		if info.guid == playerGUID then
			syncSpells[19236] = true -- Desperate Prayer
		end
	end,
	[23374] = function(info) -- Shadow: San'layn
		addMod(info.guid, 15286, 45) -- Vampiric Embrace
	end,
	[21976] = function(info) -- Shadow: Intangibility
		addMod(info.guid, 47585, 30) -- Dispersion
	end,
	[23137] = function(info) -- Shadow: Last Word
		addMod(info.guid, 15487, 15) -- Silence
	end,

	-- Rogue
	[19237] = function(info) -- Outlaw: Retractable Hook
		addMod(info.guid, 195457, 30) -- Grappling Hook
	end,
	[19237] = function(info) -- Outlaw: Blinding Powder
		addMod(info.guid, 2094, 30) -- Blind
	end,
	[22336] = function(info) -- Subtlety: Enveloping Shadows
		addMod(info.guid, 185313, 0, 3) -- Shadow Dance
	end,

	-- Shaman
	[22492] = function(info) -- Resto: Graceful Spirit
		addMod(info.guid, 79206, 60) -- Spiritwalker's Grace
	end,

	-- Warlock
	[22047] = function(info) -- All: Darkfury
		addMod(info.guid, 30283, 15) -- Shadowfury
	end,

	-- Warrior
	[21204] = function(info) -- All: Anger Management
		-- Rage you spend reduces the remaining cooldown on [Spell] by 1 sec.
		if info.guid == playerGUID then
			if info.spec == 71 then -- Arms
				if info.talents[14] then
					syncSpells[262161] = true -- Warbreaker
				else
					syncSpells[167105] = true -- Colossus Smash
				end
				syncSpells[227847] = true -- Bladestorm
			elseif info.spec == 72 then -- Fury
				syncSpells[1719] = true -- Recklessness
			elseif info.spec == 73 then -- Prot
				syncSpells[107574] = true -- Avatar
				syncSpells[12975] = true -- Last Stand
				syncSpells[871] = true -- Shield Wall
				syncSpells[1160] = true -- Demoralizing Shout
			end
		end
	end,
	[22627] = function(info) -- Arms/Fury: Bounding Stride
		addMod(info.guid, 52174, 15) -- Heroic Leap
	end,
	[19676] = function(info) -- Arms/Fury: Double Time
		addMod(info.guid, 100, 3, 2) -- Charge
	end,
	[22629] = function(info) -- Protection: Bounding Stride
		addMod(info.guid, 52174, 15) -- Heroic Leap
	end,
	[22488] = function(info) -- Protection: Bolster
		addMod(info.guid, 12975, 60) -- Last Stand
	end,
}

-- { cd, level, spec id, talent index, sync, race }
-- level can be a hash of spec=level for talents in different locations
-- spec id can be a table of specs and is optional if level or talent are a table
-- talent index can be negative to indicate a talent replaces the spell
--   and can be a hash of spec=index for talents in different locations
-- sync will register SPELL_UPDATE_COOLDOWN and send "CooldownUpdate" syncs
--   with the cd (for dynamic cooldowns with hard to track conditions)
local spells = {
	DEATHKNIGHT = {
		[221562] = {45, 1, 250}, -- Asphyxiate
		[49576] = {25, 55}, -- Death Grip
		[46584] = {30, 55, 252}, -- Raise Dead
		[48707] = {60, 57}, -- Anti-Magic Shell
		[43265] = {30, 56, {250, 252}}, -- Death and Decay
		[49028] = {120, 57, 250}, -- Dancing Rune Weapon
		[47568] = {120, 57, 251}, -- Empower Rune Weapon
		[51271] = {45, 57, 251}, -- Pillar of Frost
		[196770] = {20, 57, 251}, -- Remorseless Winder
		[55233] = {90, 57, 250}, -- Vampiric Blood
		[47528] = {15, 62}, -- Mind Freeze
		[108199] = {120, 64, 250}, -- Gorefiend's Grasp
		[48792] = {180, 65, {251, 252}}, -- Icebound Fortitude
		[61999] = {600, 72}, -- Raise Ally
		[63560] = {60, 74, 252}, -- Dark Transformation
		[275699] = {120, 75, 252}, -- Apocalypse
		[42650] = {600, 82, 252, nil, true}, -- Army of the Dead

		[206931] = {30, 56, 250, 2}, -- Blooddrinker
		[210764] = {60, 56, 250, 3, true}, -- Rune Strike (2 charges) XXX Charge syncing NYI!
		[274156] = {45, 57, 250, 6}, -- Consumption
		[57330] = {45, 57, 251, 6}, -- Horn of Winter
		[115989] = {10, 57, 252, 6}, -- Unholy Blight
		[219809] = {60, 58, 250, 9}, -- Tombstone
		[207167] = {60, 58, 251, 9}, -- Blinding Sleet
		[108194] = {45, 60, nil, {[251]=8, [252]=9}}, -- Asphyxiate
		[194679] = {25, 60, 250, 12}, -- Rune Tap (2 charges)
		[130736] = {45, 60, 252, 12}, -- Soul Reaper
		[212552] = {60, 75, nil, {[250]=15, [251]=14, [252]=14}}, -- Wraith Walk
		[48743] = {90, 75, {251,252}, 15}, -- Death Pact
		[194913] = {6, 90, 251, 17}, -- Glacial Advance
		[152280] = {30, 90, 252, 17}, -- Defile
		[279302] = {180, 90, 251, 18}, -- Frostwyrm's Fury
		[207289] = {75, 100, 252, 20}, -- Unholy Frenzy
		[194844] = {60, 100, 250, 21}, -- Bonestorm
		[152279] = {120, 100, 251, 21}, -- Breath of Sindragosa
		[49206] = {180, 75, 252, 21}, -- Summon Gargoyle
	},
	DEMONHUNTER = {
		[198589] = {60, 1, 577}, -- Blur
		[179057] = {60, 1, 577}, -- Chaos Nova
		[183752] = {15, 1}, -- Disrupt
		[195072] = {10, 1, 577}, -- Fel Rush
		[204021] = {60, 1, 581}, -- Fiery Brand
		[217832] = {45, 1}, -- Imprison
		[189110] = {20, 1, 581}, -- Infernal Strike
		[200166] = {240, 1, 577}, -- Metamorphosis (Havoc)
		[187827] = {180, 1, 581}, -- Metamorphosis (Vengeance)
		[204596] = {30, 1, 581}, -- Sigil of Flame
		[214743] = {60, 1, 577}, -- Soul Carver
		[188501] = {30, 1}, -- Spectral Sight
		[185123] = {9, 1, 577}, -- Throw Glaive (Havoc)
		[198793] = {25, 1, 577}, -- Vengeful Retreat
		[196718] = {180, 100, 577}, -- Darkness
		[202137] = {60, 101, 581}, -- Sigil of Silence
		[278326] = {10, 103}, -- Consume Magic
		[207684] = {60, 105, 581}, -- Sigil of Misery

		[258925] = {60, 102, 577, 9}, -- Fel Barrage
		[232893] = {15,  102, 581, 9}, -- Felblade
		[196555] = {120, 104, 577, 12}, -- Netherwalk
		[202138] = {90, 106, 581, 15}, -- Sigil of Chains
		[211881] = {30, 108, 577, 18}, -- Fel Eruption
		[212084] = {60, 108, 581, 18}, -- Fel Devastation
		[206491] = {120, 110, 577, 21}, -- Nemesis
		[263648] = {30, 110, 581, 21}, -- Soul Barrier
	},
	DRUID = {
		[1850] = {120, 8, nil, -4}, -- Dash
		[5217] = {30, 13, 103}, -- Tiger's Fury
		[22812] = {60, 26, {102, 104, 105}}, -- Barkskin (Guardian CD is 90s)
		[99] = {30, 28, 104, -5}, -- Incapacitating Roar
		[61336] = {120, 36, {103, 104}}, -- Survival Instincts (2 charges) (Guardian CD is 240s)
		[106951] = {180, 40, 103, -15}, -- Berserk
		[22842] = {36, 40, nil, {[102]=8,[103]=8,[104]=false},[105]=8}, -- Frenzied Regeneration (2 charges at lv63) (Granted via Guardian Affinity)
		[20484] = {600, 42}, -- Rebirth
		[194223] = {180, 48, 102, -15}, -- Celestial Alignment
		[29166] = {180, 50, {102, 105}}, -- Innervate
		[106898] = {120, 50, {103, 104}}, -- Stampeding Roar
		[77761] = 106898, -- Stampeding Roar (Guardian, 60s)
		[77764] = 106898, -- Stampeding Roar (Feral, 120s)
		[102342] = {60, 54, 105}, -- Ironbark
		[2908] = {10, 56}, -- Soothe
		[78675] = {60, 60, 102}, -- Solar Beam
		[102793] = {60, 63, 105}, -- Ursol's Vortex
		[106839] = {15, 70, {103, 104}}, -- Skull Bash
		[740] = {180, 80, 105}, -- Tranquility

		[202425] = {45, 15, 102, 2}, -- Warrior of Elune
		[155835] = {40, 15, 104, 3}, -- Bristling Fur
		[102351] = {30, 15, 105, 3}, -- Cenarion Ward
		[205636] = {60, 15, 102, 3}, -- Force of Nature
		[252216] = {45, 30, nil, 4}, -- Tiger Dash
		[102793] = {60, 30, 104, 5}, -- Ursol's Vortex
		[108238] = {90, 30, {102, 103, 105}, 5}, -- Renewel
		[132302] = {15, 30, nil, 6}, -- Wild Charge
		[16979]  = 132302, -- Wild Charge (Bear)
		[49376]  = 132302, -- Wild Charge (Cat)
		[102383] = 132302, -- Wild Charge (Moonkin)
		[102416] = 132302, -- Wild Charge (Aquatic)
		[102417] = 132302, -- Wild Charge (Travel)
		[5211]   = {50, 60, nil, 10}, -- Mighty Bash
		[102359] = {30, 60, nil, 11}, -- Mass Entanglement
		[132469] = {30, 60, nil, 12}, -- Typhoon
		[61391]  = 132469, -- Typhoon (actual event)
		[102560] = {180, 75, 102, 15}, -- Incarnation: Chosen of Elune
		[102558] = {180, 75, 104, 15}, -- Incarnation: Guardian of Ursoc
		[102543] = {180, 75, 103, 15}, -- Incarnation: King of the Jungle
		[33891]  = {180, 75, 105, 15}, -- Incarnation: Tree of Life
		[202770] = {60, 100, 102, 20}, -- Fury of Elune
		[204066] = {75, 100, 104, 20}, -- Lunar Beam
		[274281] = {25, 100, 102, 21}, -- New Moon (3 charges)
		[274837] = {45, 100, 103, 21}, -- Feral Frenzy
		[197721] = {90, 100, 105, 21}, -- Flourish
	},
	HUNTER = {
		[781] = {20, 8}, -- Disengage (30s base, reduced by 10s at 85)
		[136] = {10, 13}, -- Mend Pet
		[187650] = {30, 18}, -- Freezing Trap
		[19574] = {90, 20, 253, nil, true}, -- Bestial Wrath: Bestial Wrath's remaining cooldown is reduced by 12 sec each time you use Barbed Shot.
		-- [257044] = {20, 20, 254}, -- Rapid Fire (XXX CD reduced with Lethal Shots talent randomly and by 60% during Trueshot)
		[186257] = {180, 22}, -- Aspect of the Cheetah
		[190925] = {20, 14, 255}, -- Harpoon (30s base, reduced by 10s at 65)
		[259495] = {18, 20, 255}, -- Wildfire Bomb
		[270335] = 259495, -- Shrapnel Bomb (20: Wildfire Infusion)
		[270323] = 259495, -- Pheromone Bomb (20: Wildfire Infusion)
		[271045] = 259495, -- Volatile Bomb (20: Wildfire Infusion)
		[109304] = {120, 24}, -- Exhilaration
		[186387] = {30, 26, 254}, -- Bursting Shot
		[19577] = {60, 26, {253,255}}, -- Intimidation
		[5384] = {30, 28}, -- Feign Death
		[147362] = {24, 32, {253, 254}}, -- Counter Shot
		[187707] = {15, 32, 255}, -- Muzzle
		[187698] = {30, 36, 255}, -- Tar Trap
		[1543] = {20, 38}, -- Flare
		[61648] = {180, 40}, -- Aspect of the Chameleon
		[266779] = {120, 40, 255}, -- Coordinated Assault
		[193530] = {120, 40, 253}, -- Aspect of the Wild
		[193526] = {180, 40, 254}, -- Trueshot
		[34477] = {30, 42}, -- Misdirection
		[186289] = {90, 54, 255}, -- Aspect of the Eagle
		[186265] = {180, 70}, -- Aspect of the Turtle

		[212431] = {30, 30, 254, 6, true}, -- Explosive Shot
		[199483] = {60, 45, nil, 9}, -- Camouflage
		[131894] = {60, {[253]=60,[254]=15,[255]=60}, nil, {[253]=12,[254]=3,[255]=12}, true}, -- A Murder of Crows
		[162488] = {30, 60, 255, 11}, -- Steel Trap
		[109248] = {45, 75, nil, 15}, -- Binding Shot
		[120360] = {20, 90, {253, 254}, 17}, -- Barrage
		[201430] = {180, 90, 253, 18}, -- Stampede
		[260402] = {60, 90, 254, 18}, -- Double Tap
		[269751] = {40, 90, 255, 18}, -- Flanking Strike
		[194407] = {90, 100, 253, 21}, -- Splitting Cobra
		[198670] = {30, 100, 254, 21}, -- Piercing Shot
		[259391] = {20, 100, 255, 21}, -- Chakrams
		-- Command Pet XXX Not sure how do deal with these for available cds
		[53271] = {45, 20}, -- Master's Call (Cunning)
		[264735] = {360, 20}, -- Survival of the Fittest (Tenacity)
		[272678] = {360, 20}, -- Primal Rage (Ferocity)
	},
	MAGE = {
		[45438] = {240, 50}, -- Ice Block
		[122] = {30, 5}, -- Frost Nova
		[31687] = {30, 12, 64, -2}, -- Summon Water Elemental
		[1953] = {15, 16, nil, -5}, -- Blink
		[12051] = {180, 20, 62}, -- Evocation
		[2139] = {24, 22}, -- Counterspell
		[235313] = {25, 26, 63}, -- Blazing Barrier
		[11426] = {25, 26, 64}, -- Ice Barrier
		[235450] = {25, 26, 62}, -- Prismatic Barrier
		[31661] = {20, 32, 63}, -- Dragon's Breath
		[33395] = {25, 32, 62}, -- Freeze
		[120] = {12, 34, 64}, -- Cone of Cold
		[12042] = {90, 40, 62}, -- Arcane Power
		[190319] = {120, 40, 63}, -- Combustion
		[12472] = {180, 40, 64}, -- Icy Veins
		[66] = {300, 42}, -- Invisibility
		[195676] = {30, 48, 62}, -- Displacement
		[45438] = {240, 50}, -- Ice Block
		[235219] = {300, 52, 64}, -- Cold Snap
		[205025] = {60, 54, 62}, -- Presence of Mind
		[84714] = {60, 57, 64}, -- Frozen Orb
		[110959] = {120, 65, 62}, -- Greater Invisibility
		[80353] = {300, 80}, -- Time Warp

		[205022] = {10, 15, 62, 3}, -- Arcane Familiar
		[157997] = {25, 15, 64, 3}, -- Ice Nova
		[212653] = {15, 30, nil, 5}, -- Shimmer
		[157981] = {25, 30, 63, 6}, -- Blast Wave
		[108839] = {20, 30, 64, 6}, -- Ice Floes (3 charges)
		[55342]  = {120, 45, nil, 8}, -- Mirror Image
		[116011] = {120, 45, nil, 9}, -- Rune of Power (2 charges)
		[205032] = {40, 60, 62, 11}, -- Charged Up
		[257537] = {45, 60, 64, 12}, -- Ebonbolt
		[257541] = {30, 60, 63, 12}, -- Phoenix Flames (3 charges)
		[157980] = {25, 60, 62, 12}, -- Supernova
		[113724] = {45, 75, nil, 15}, -- Ring of Frost
		[153595] = {30, 90, 64, 18}, -- Comet Storm
		[44457]  = {12, 90, 63, 18}, -- Living Bomb
		[205021] = {75, 100, 64, 20}, -- Ray of Frost
		[153626] = {20, 100, 62, 21}, -- Arcane Orb
		[153561] = {45, 100, 63, 21}, -- Meteor
	},
	MONK = {
		[109132] = {20, 5, nil, -5}, -- Roll
		[115078] = {45, 25}, -- Paralysis
		[115080] = {120, 32, 269}, -- Touch of Death
		[116705] = {15, 35, {268, 269}}, -- Spear Hand Strike
		[116849] = {120, 35, 270}, -- Life Cocoon
		[101545] = {25, 48, 269}, -- Flying Serpent Kick
		[116680] = {30, 50, 270}, -- Thunder Focus Tea
		[119381] = {60, 52}, -- Leg Sweep
		[115203] = {420, 55, 268}, -- Fortifying Brew (Brewmaster)
		[243435] = {90, 55, 270}, -- Fortifying Brew (Mistweaver)
		[122470] = {90, 55, 269}, -- Touch of Karma
		[115176] = {300, 65, 268}, -- Zen Meditation
		[115310] = {180, 70, 270}, -- Revival

		[115008] = {20, 30, nil, 5}, -- Chi Torpedo
		[116841] = {30, 30, nil, 6}, -- Tiger's Lust
		[115288] = {60, 45, 269, 9}, -- Energizing Elixir
		[115399] = {120, 45, 268, 9}, -- Black Ox Brew
		[197908] = {90, 45, 270, 9}, -- Mana Tea
		[115315] = {10, 60, 268, 11}, -- Summon Black Ox Statue
		[198898] = {30, 60, 270, 11}, -- Song of Chi-Ji
		[116844] = {45, 60, nil, 12}, -- Ring of Peace
		[122783] = {120, 75, {269,270}, 14}, -- Diffuse Magic
		[122278] = {120, 75, nil, 15}, -- Dampen Harm
		[198664] = {180, 90, 270, 18}, -- Invoke Chi-Ji, the Red Crane
		[132578] = {180, 90, 268, 18}, -- Invoke Niuzao, the Black Ox
		[123904] = {120, 90, 269, 18}, -- Invoke Xuen, the White Tiger
		[152173] = {90, 100, 269, 21}, -- Serenity
	},
	PALADIN = {
		[853] = {60, 8}, -- Hammer of Justice
		[642] = {300, 18}, -- Divine Shield
		[183218] = {30, 24, 70}, -- Hand of Hindrance
		[190784] = {45, 28}, -- Divine Steed
		[184662] = {120, 32, 70}, -- Shield of Vengeance
		[498] = {60, 32, {65, 66}}, -- Divine Protection
		[96231] = {15, 35, {66, 70}}, -- Rebuke
		[1044] = {25, 38}, -- Blessing of Freedom
		[1022] = {300, 48, nil, {[66]=-12}}, -- Blessing of Protection
		[31850] = {120, 50, 66}, -- Ardent Defender
		[633] = {600, 55}, -- Lay on Hands
		[6940] = {150, 56, {65, 66}}, -- Blessing of Sacrifice
		[31821] = {180, 70, 65}, -- Aura Mastery
		[86659] = {300, 70, 66}, -- Guardian of Ancient Kings
		[31884] = {120, 80}, -- Avenging Wrath

		[114158] = {60, 15, 65, 3}, -- Light's Hammer
		[267798] = {30, 15, 70, 3}, -- Execution Sentence
		[204035] = {120, 30, 66, 6}, -- Bastion of Light
		[20066] = {15, 45, nil, 8}, -- Repentance
		[115750] = {90, 45, nil, 9}, -- Blinding Light
		[204018] = {180, 60, 66, 12}, -- Blessing of Spellwarding
		[255937] = {45, 60, 70, 12}, -- Wake of Ashes
		[114165] = {20, 75, 65, 14}, -- Holy Prism
		[205191] = {60, 75, 70, 15}, -- Eye for an Eye
		[105809] = {90, 75, 65, 15}, -- Holy Avenger
		[204150] = {300, 90, 66, 18}, -- Aegis of Light
		[231895] = 31884, -- Crusade
		[152262] = {45, 100, 66, 21}, -- Seraphim
	},
	PRIEST = {
		[8122] = {60, 18, nil, {[258]=-11}}, -- Psychic Scream
		[19236] = {90, 26, {256,257}}, -- Desperate Prayer
		[15286] = {120, 28, 258}, -- Vampiric Embrace
		[586] = {30, 44}, -- Fade
		[32375] = {45, 80}, -- Mass Dispel
		[34433] = {180, 40, {256, 258}, {[256]=-8,[258]=-17}}, -- Shadowfiend
		[33206] = {180, 48, 256}, -- Pain Suppression
		[47536] = {90, 50, 256}, -- Rapture
		[194509] = {20, 52, 256}, -- Power Word: Radiance
		[15487] = {45, 52, 258}, -- Silence
		[47788] = {180, 44, 257}, -- Guardian Spirit
		[47585] = {120, 48, 258}, -- Dispersion
		[73325] = {90, 63}, -- Leap of Faith
		[64843] = {180, 70, 257}, -- Divine Hymn
		[62618] = {180, 70, 256, -20}, -- Power Word: Barrier
		[64901] = {300, 84, 257}, -- Symbol of Hope

		[123040] = {60, {[256]=45,[258]=90}, nil, {[256]=8,[258]=17}}, -- Mindbender
		[200174] = 123040, -- Mindbender (Shadow)
		[205369] = {30, 60, 258, 11}, -- Mind Bomb
		[64044] = {45, 60, 258, 12}, -- Psychic Horror
		[204263] = {60, 45, {256, 257}, 12}, -- Shining Force
		[120517] = {40, 90, {256, 257}, 18}, -- Halo
		[200183] = {120, 100, 257, 20}, -- Apotheosis
		[280711] = {60, 100, 258, 20}, -- Dark Ascension
		[271466] = {180, 100, 256, 20}, -- Luminous Barrier
		[246287] = {90, 100, 258, 21}, -- Evangelism
		[265202] = {720, 100, 257, 21}, -- Holy Word: Salvation
		[193223] = {180, 100, 258, 21}, -- Surrender to Madness
	},
	ROGUE = {
		-- Restless Blades (Outlaw, 50): Finishing moves reduce the remaining cooldown
		-- of Adrenaline Rush, Between the Eyes, Sprint, Grappling Hook, Ghostly
		-- Strike, Marked for Death, Blade Rush, Killing Spree, and Vanish by 1 sec
		-- per combo point spent.
		[36554] = {30, 22, {259,261}}, -- Shadowstep
		[185311] = {30, 16}, -- Crimson Vial
		[1766] = {15, 18}, -- Kick
		[199804] = {30, 20, 260, nil, true}, -- Between the Eyes
		[195457] = {60, 22, 260, nil, true}, -- Grappling Hook
		[2094] = {120, 24}, -- Blind
		[5277] = {120, 26, {259,261}}, -- Evasion
		[199754] = {120, 26, 260}, -- Riposte
		[2983] = {60, 32, nil, nil, {[260]=true}}, -- Sprint (120s base, reduced by 60s at 66)
		[1776]  = {15, 34, 260}, -- Gouge
		[408] = {20, 34, {259, 261}}, -- Kidney Shot
		[212283] = {30, 36, 261}, -- Symbols of Death
		[1725] = {30, 38}, -- Distract
		[185313] = {60, 40, 261, nil, true}, -- Shadow Dance - Your finishing moves reduce the remaining cooldown on Shadow Dance
		[1966] = {15, 44}, -- Feint
		[1856] = {120, 48, nil, nil, {[260]=true}}, -- Vanish
		[121471] = {180, 56, 261}, -- Shadow Blades
		[79140] = {120, 56, 259}, -- Vendetta
		[13877] = {25, 63, 260}, -- Blade Flurry
		[114018] = {360, 68}, -- Shroud of Concealment
		[57934] = {30, 70}, -- Tricks of the Trade
		[13750] = {180, 56, 260, nil, true}, -- Adrenaline Rush
		[31224] = {120, 80}, -- Cloak of Shadows

		[196937] = {35, 15, 260, 3, true}, -- Ghostly Strike
		[137619] = {60, 45, nil, 20, true}, -- Marked for Death - Cooldown reset if the target dies within 1 min.
		[200806] = {45, 90, 259, 18}, -- Exsanguinate
		[271877] = {45, 100, 260, 20, true}, -- Blade Rush
		[51690] = {120, 100, 260, 21, true}, -- Killing Spree
		[280719] = {45, 100, 261, 20, true}, -- Secret Technique
		[277925] = {60, 100, 261, 21}, -- Shuriken Tornado
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
		[19647] = {24, 35}, -- Spell Lock (Felhunter)
		[119910] = 19647, -- Spell Lock (Command Demon)
		[132409] = 19647, -- Spell Lock (Grimoire of Sacrifice Command Demon)
		[80240] = {30, 40, 267}, -- Havoc
		[698] = {120, 42}, -- Ritual of Summoning
		[20707] = {600, 44}, -- Soulstone
		[95750] = 20707, -- Soulstone Resurrection (combat)
		[104773] = {180, 54}, -- Unending Resolve
		[205180] = {180, 58, 265}, -- Summon Darkglare
		[1122] = {180, 58, 267}, -- Summon Infernal
		[30283] = {60, 60}, -- Shadowfury
		[29893] = {120, 65}, -- Create Soulwell
		[265187] = {90, 80, 266}, -- Summon Demonic Tyranic

		[267211] = {30, 15, 266, 3}, -- Bilescourge Bombers
		[264130] = {30, 30, 266, 5}, -- Power Siphon
		[108416] = {60, 45, nil, 9}, -- Dark Pact
		[205179] = {45, 60, 265, 11}, -- Phantom Singularity
		[152108] = {30, 60, 267, 12}, -- Cataclysm
		[264119] = {45, 60, 266, 12}, -- Summon Vilefiend
		[48020] = {10, 75, nil, 12}, -- Demonic Circle: Teleport
		[6789] = {45, 75, nil, 14}, -- Mortal Coil
		[111898] = {120, 90, 266, 18}, -- Grimoire: Felguard
		[113860] = {120, 100, 265, 21}, -- Dark Soul: Misery
		[267217] = {180, 100, 266, 21}, -- Nether Portal
		[113858] = {120, 100, 267, 21}, -- Dark Soul: Instability
	},
	WARRIOR = {
		[100] = {20, 3}, -- Charge
		[260708] = {30, 22, 71}, -- Sweeping Strikes
		[6552] = {15, 24}, -- Pummel
		[52174] = {45, 26}, -- Heroic Leap
		[198304] = {20, 28, 73}, -- Intercept
		[12975] = {180, 32, 73}, -- Last Stand
		[118038] = {180, 36, 71}, -- Die by the Sword
		[184364] = {120, 36, 72}, -- Enraged Regeneration
		[18499] = {60, 44}, -- Berserk Rage
		[1160] = {45, 48, 73}, -- Demoralizing Shout
		[167105] = {45, 50, 71}, -- Colossus Smash
		[1719] = {60, 50, 72}, -- Recklessness
		[46968] = {40, 50, 73}, -- Shockwave
		[871] = {240, 55, 73}, -- Shield Wall
		[227847] = {90, 65, 71, -21}, -- Bladestorm
		[5246] = {90, 70}, -- Intimidating Shout
		[23920] = {25, 70, 73}, -- Spell Reflection
		[97462] = {180, 80}, -- Rallying Cry

		[260643] = {21, 15, 71, 3}, -- Skullsplitter
		[107570] = {30, {[71]=30,[72]=30,[73]=75}, nil, {[71]=6,[72]=6,[73]=15}}, -- Storm Bolt
		[262161] = {45, 75, 71, 14}, -- Warbreaker
		[107574] = {90, 90, nil, {[71]=17,[73]=false}}, -- Avatar -- Protection always has it, Arms can talent into it
		[118000] = {35, {[72]=90,[73]=45}, nil, {[72]=17,[73]=9}}, -- Dragon Roar
		[46924] = {60, 90, 72, 18}, -- Bladestorm
		[152277] = {60, 100, {71, 73}, 21}, -- Ravager (Arms)
		[228920] = 152277, -- Ravager (Protection)
		[280772] = {30, 100, 72, 21}, -- Siegebreaker
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
		-- Ancestral Call (Mag'har Orc)
		[274738] = {120, 1, nil, nil, nil, "MagharOrc"},
		[274739] = 274738, -- Rictus of the Laughing Skull
		[274740] = 274738, -- Zeal of the Burning Blade
		[274741] = 274738, -- Ferocity of the Frostwolf
		[274742] = 274738, -- Might of the Blackrock
		--
		[273104] = {120, 1, nil, nil, nil, "DarkIronDwarf"}, -- Fireblood (Dark Iron Dwarf)
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
}

local chargeSpells = {
	-- Death Knight
	[210764] = 2, -- Rune Strike (Blood talent)
	[194679] = 2, -- Rune Tap (Blood talent)
	-- Demon Hunter
	[195072] = 2, -- Fel Rush (Havoc)
	[189110] = 2, -- Infernal Strike (Vengeance)
	-- Druid
	[61336] = 2, -- Survival Instincts
	[22842] = 2, -- Frenzied Regeneration
	[274281] = 3, -- New Moon
	-- Mage
	[212653] = 2, -- Shimmer
	[116011] = 2, -- Rune of Power
	[108839] = 3, -- Ice Floes
	[257541] = 3, -- Phoenix Flames
	-- Monk
	[109132] = 2, -- Roll
	-- Rogue
	[13877] = 2, -- Blade Flurry
	[36554] = 2, -- Shadowstep
	[185313] = 2, -- Shadow Dance
	-- Warrior
	[198304] = 2, -- Intercept
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
		if info then
			if C_Spell.DoesSpellExist(spellId) then
				allSpells[spellId] = info
				classLookup[spellId] = class
			else
				print("oRA3: Invalid spell id", spellId)
			end
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
		if talent == nil then
			return false
		end
		if type(level) == "table" then
			level = level[info.spec]
		end
		-- we already matched the spec
		spec = nil
	end

	return (info.level >= level) and (not race or info.race == race) and
		(not talent or ((talent > 0 and info.talents[talent]) or (talent < 0 and not info.talents[-talent]))) and -- handle talents replacing spells (negative talent index)
		(not spec or spec == info.spec or (type(spec) == "table" and tContains(spec, info.spec)))
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

	-- this should probably act on the display itself
	if db.hideInInstance[instanceType] then return end
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
				none = NONE, raid = RAID, party = PARTY, lfg = "LFG",
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
		local upgraded = nil
		local displayDB = db.displays.Default
		displayDB.type = "Bars"
		displayDB.showDisplay = true
		displayDB.lockDisplay = false
		for k, v in next, db do
			if k ~= "displays" and k ~= "spells" and k ~= "filters" then
				if k:find("^bar") then
					displayDB[k] = type(db[k]) == "table" and CopyTable(db[k]) or db[k]
					upgraded = true
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

		if upgraded then -- don't show for new profiles
			module:ScheduleTimer(function()
				print("oRA3 Cooldowns has been redesigned and now supports multiple displays and different formats! You can open the options panel with /racd and move it around by dragging the title bar.")
			end, 9)
		end
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
						none = false, raid = false, party = false, lfg = false,
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
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
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

function module:PLAYER_ENTERING_WORLD()
	_, instanceType, instanceDifficulty = GetInstanceInfo()
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

function module:OnCommReceived(_, sender, prefix, spellId, cd)
	if prefix == "CooldownUpdate" then
		local guid = UnitGUID(sender)
		if not guid then return end
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
		if not guid then return end
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

	if playerClass == "SHAMAN" then
		local start, duration = GetSpellCooldown(20608)
		if start > 0 and duration > 1.5 then
			local cd = duration - (GetTime() - start)
			self:SendComm("Reincarnation", round(cd))
		end
	end
end

function module:OnPlayerUpdate(_, guid, unit, info)
	for _, mods in next, cdModifiers do mods[guid] = nil end
	for _, mods in next, chargeModifiers do mods[guid] = nil end
	infoCache[guid] = info

	if guid == playerGUID then
		self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
		wipe(syncSpells)
		for spellId, data in next, spells[playerClass] do
			if data[5] and self:IsSpellUsable(info.guid, spellId) then
				syncSpells[spellId] = true
			end
		end
	end

	for talentIndex, talentId in next, info.talents do
		if talentCooldowns[talentId] then
			talentCooldowns[talentId](info)
		end
	end

	if guid == playerGUID and next(syncSpells) then
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	end

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
	local scratch = combatLogHandler.userdata

	local specialEvents = setmetatable({}, {__index=function(t, k)
		t[k] = {}
		return t[k]
	end})

	-- Death Knight

	-- Death Strike
	specialEvents.SPELL_CAST_SUCCESS[49998] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[20] == 21208 then -- Red Thirst
			local remaining = module:GetRemainingCooldown(srcGUID, 55233) -- Vampiric Blood
			if remaining > 0 then
				resetCooldown(info, 55233, remaining - 4.5)
			end
		end
	end

	local function armyOfTheDamned(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[19] then -- Army of the Damned
			local remaining = module:GetRemainingCooldown(srcGUID, 42650) -- Army of the Dead
			if remaining > 0 then
				resetCooldown(info, 42650, remaining - 5)
			end
			remaining = module:GetRemainingCooldown(srcGUID, 275699) -- Apocalypse
			if remaining > 0 then
				resetCooldown(info, 275699, remaining - 1)
			end
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[47541] = armyOfTheDamned -- Death Coil
	specialEvents.SPELL_CAST_SUCCESS[207317] = armyOfTheDamned -- Epidemic

	local function icecap(srcGUID, _, spellId, ...)
		local info = infoCache[srcGUID]
		if info and scratch[srcGUID] then -- Icecap
			-- only count it once x.x
			local id = 3
			if spellId == 222024 or spellId == 66198 then
				id = 1
			elseif spellId == 222026 or spellId == 66196 then
				id = 2
			end
			if scratch[srcGUID][id] then
				local remaining = module:GetRemainingCooldown(srcGUID, 51271) -- Pillar of Frost
				if remaining > 0 then
					resetCooldown(info, 51271, remaining - 1)
				end
				scratch[srcGUID][id] = nil
			end
		end
	end
	specialEvents.SPELL_DAMAGE[207230] = icecap -- Frostscythe
	specialEvents.SPELL_DAMAGE[222024] = icecap -- Obliterate
	specialEvents.SPELL_DAMAGE[66198] = icecap -- Obliterate Off-Hand
	specialEvents.SPELL_DAMAGE[222026] = icecap -- Frost Strike
	specialEvents.SPELL_DAMAGE[66196] = icecap -- Frost Strike Off-Hand

	local function icecapCast(srcGUID, _, spellId)
		local info = infoCache[srcGUID]
		if info and info.talents[19] then -- Icecap
			if not scratch[srcGUID] then scratch[srcGUID] = {} end
			local id = 3
			if spellId == 222024 or spellId == 66198 then
				id = 1
			elseif spellId == 222026 or spellId == 66196 then
				id = 2
			end
			scratch[srcGUID][id] = true
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[49020] = icecapCast -- Obliterate
	specialEvents.SPELL_CAST_SUCCESS[49143] = icecapCast -- Frost Strike
	specialEvents.SPELL_CAST_SUCCESS[207230] = icecapCast -- Frostscythe

	-- Demon Hunter

	-- Vengeful Retreat
	specialEvents.SPELL_DAMAGE[198813] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[20] then -- Momentum
			local t = GetTime()
			if t-(scratch[srcGUID] or 0) > 2 then
				scratch[srcGUID] = t
				resetCooldown(info, 198793, module:GetRemainingCooldown(srcGUID, 198793) - 5) -- Vengeful Retreat
			end
		end
	end

	-- Hunter

	local function callingTheShots(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[19] then -- Calling the Shots
			local remaining = module:GetRemainingCooldown(srcGUID, 193526) -- Trueshot
			if remaining > 0 then
				resetCooldown(info, 193526, remaining - 2.5)
			end
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[185358] = callingTheShots -- Arcane Shot
	specialEvents.SPELL_CAST_SUCCESS[257620] = callingTheShots -- Multi-Shot (Marksmanship)

	-- Mage

	-- Cold Snap
	specialEvents.SPELL_CAST_SUCCESS[235219] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info then
			resetCooldown(info, 120) -- Cone of Cold
			resetCooldown(info, 122) -- Frost Nova
			resetCooldown(info, 11426) -- Ice Barrier
		end
	end

	local function kindling(srcGUID, ...)
		local critical = select(9, ...)
		if not critical then return end

		local info = infoCache[srcGUID]
		if info and info.talents[19] then -- Kindling
			local remaining = module:GetRemainingCooldown(srcGUID, 190319) -- Combustion
			if remaining > 0 then
				resetCooldown(info, 190319, remaining - 1)
			end
		end
	end
	specialEvents.SPELL_DAMAGE[133] = kindling -- Fireball
	specialEvents.SPELL_DAMAGE[11366] = kindling -- Pyroblast
	specialEvents.SPELL_DAMAGE[108853] = kindling -- Fire Blast
	specialEvents.SPELL_DAMAGE[257541] = kindling -- Phoenix Flames

	-- Monk

	-- Keg Smash
	specialEvents.SPELL_CAST_SUCCESS[121253] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info then
			local remaining = module:GetRemainingCooldown(srcGUID, 115203) -- Fortifying Brew
			if remaining > 0 then
				resetCooldown(info, 115203, remaining - 4)
			end
			remaining = module:GetRemainingCooldown(srcGUID, 115399) -- Black Ox Brew
			if remaining > 0 then
				resetCooldown(info, 115399, remaining - 4)
			end
		end
	end

	-- Tiger Palm (Brewmaster)
	specialEvents.SPELL_CAST_SUCCESS[100780] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.spec == 268 then
			local remaining = module:GetRemainingCooldown(srcGUID, 115203) -- Fortifying Brew
			if remaining > 0 then
				resetCooldown(info, 115203, remaining - 1)
			end
			remaining = module:GetRemainingCooldown(srcGUID, 115399) -- Black Ox Brew
			if remaining > 0 then
				resetCooldown(info, 115399, remaining - 1)
			end
		end
	end

	-- Priest

	local function holyWordSalvation(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[21] then
			local remaining = module:GetRemainingCooldown(srcGUID, 265202) -- Holy Word: Salvation
			if remaining > 0 then
				resetCooldown(info, 265202, remaining - 30)
			end
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[2050] = holyWordSalvation -- Holy Word: Serenity
	specialEvents.SPELL_CAST_SUCCESS[34861] = holyWordSalvation -- Holy Word: Sanctify

	-- Guardian Spirit
	specialEvents.SPELL_AURA_APPLIED[47788] = function(srcGUID)
		scratch[srcGUID] = GetTime()
	end
	specialEvents.SPELL_AURA_REMOVED[47788] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[8] and scratch[srcGUID] then -- Guardian Angel
			if GetTime() - scratch[srcGUID] > 9.7 then
				resetCooldown(info, 47788, 60)
			end
		end
		scratch[srcGUID] = nil
	end

	-- Paladin

	-- Shield of the Righteous
	specialEvents.SPELL_CAST_SUCCESS[53600] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[20] then -- Righteous Protector
			local remaining = module:GetRemainingCooldown(srcGUID, 31884) -- Avenging Wrath
			if remaining > 0 then
				resetCooldown(info, 31884, remaining - 3)
			end
		end
	end

	local function fistOfJustice(srcGUID, _, spellId)
		local info = infoCache[srcGUID]
		if info and info.talents[7] then -- Fist of Justice
			local remaining = module:GetRemainingCooldown(srcGUID, 853) -- Hammer of Justice
			if remaining > 0 then
				if info.spec == 65 then -- Holy
					resetCooldown(info, 853, remaining - 10)
				elseif info.spec == 66 then -- Protection
					resetCooldown(info, 853, remaining - 6)
				elseif info.spec == 70 then -- Retribution
					-- Inquisition = 84963, can be 1-3. ffffuuuuu
					local hp = spellId == 215661 and 5 or 3
					resetCooldown(info, 853, remaining - (hp * 2))
				end
			end
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[53385] = fistOfJustice -- Divine Storm
	specialEvents.SPELL_CAST_SUCCESS[84963] = fistOfJustice -- Inquisition
	specialEvents.SPELL_CAST_SUCCESS[85256] = fistOfJustice -- Templar's Verdict
	specialEvents.SPELL_CAST_SUCCESS[210191] = fistOfJustice -- Word of Glory
	specialEvents.SPELL_CAST_SUCCESS[215661] = fistOfJustice -- Justicar's Vengeance
	specialEvents.SPELL_CAST_SUCCESS[267798] = fistOfJustice -- Execution Sentence
	specialEvents.SPELL_CAST_SUCCESS[275773] = fistOfJustice -- Judgement (Holy)
	specialEvents.SPELL_CAST_SUCCESS[275779] = fistOfJustice -- Judgement (Protection)

	-- Warrior

	-- Shockwave
	specialEvents.SPELL_CAST_SUCCESS[46968] = function(srcGUID)
		scratch[srcGUID] = 0
	end
	specialEvents.SPELL_DAMAGE[46968] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[14] and scratch[srcGUID] then -- Rumbling Earth
			scratch[srcGUID] = scratch[srcGUID] + 1
			if scratch[srcGUID] > 2 then
				resetCooldown(info, 46968, module:GetRemainingCooldown(srcGUID, 46968) - 15) -- Shockwave
				scratch[srcGUID] = nil
			end
		end
	end

	-- Misc

	-- Dream Simulacrum (Xavius Encounter)
	specialEvents.SPELL_AURA_REMOVED[206005] = function(_, dstGUID)
		local info = infoCache[dstGUID]
		if info then
			for spellId in next, spells[info.class] do
				if module:GetRemainingCooldown(dstGUID, spellId) > 0 then
					resetCooldown(info, spellId)
				end
			end
		end
	end

	-- stop autovivification
	setmetatable(specialEvents, nil)


	local encounterResetsCooldowns = {
		[14] = true, -- Normal
		[15] = true, -- Heroic
		[16] = true, -- Mythic
	}
	local inEncounter = nil

	local band = bit.band
	local group = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
	local pet = bit.bor(COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET)

	local function handler(_, event, _, srcGUID, source, srcFlags, _, destGUID, destName, dstFlags, _, spellId, spellName, _, ...)
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

			if combatResSpells[spellId] and (encounterResetsCooldowns[inEncounter] or instanceDifficulty == 8) then
				-- tracking by spell cast isn't very useful in non-legacy raid encounters and mythic+ because it only counts when accepted
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
	end
	combatLogHandler:SetScript("OnEvent", function()
		handler(CombatLogGetCurrentEventInfo())
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
			inEncounter = instanceDifficulty
			if encounterResetsCooldowns[instanceDifficulty] then
				-- reset combat reses
				for spellId in next, combatResSpells do
					spellsOnCooldown[spellId] = nil
					updateCooldownsBySpell(spellId)
				end
			end
		elseif inEncounter and not IsEncounterInProgress() then
			inEncounter = nil
			if encounterResetsCooldowns[instanceDifficulty] then
				-- reset 3min+ cds (except Reincarnation)
				for spellId, info in next, allSpells do
					if info[1] >= 180 and spellId ~= 20608 then
						spellsOnCooldown[spellId] = nil
						chargeSpellsOnCooldown[spellId] = nil
						updateCooldownsBySpell(spellId)
					end
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
