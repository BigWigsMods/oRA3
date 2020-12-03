
local _, scope = ...

scope.cooldownData = {}
local data = scope.cooldownData

data.cdModifiers = {}
local cdModifiers = data.cdModifiers
data.chargeModifiers = {}
local chargeModifiers = data.chargeModifiers
data.syncSpells = {}
local syncSpells = data.syncSpells

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

data.talentCooldowns = {
	-- Death Knight
	[22014] = function(info) -- Blood: Anti-Magic Barrier
		addMod(info.guid, 48707, 20) -- Anti-Magic Shell
	end,
	[19226] = function(info) -- Blood: Tightening Grasp
		addMod(info.guid, 108199, 30) -- Gorefiend's Grasp
	end,

	-- Demon Hunter
	[21869] = function(info) -- Havoc: Unleashed Power
		addMod(info.guid, 179057, 20) -- Chaos Nova
	end,
	[21901] = function(info) -- Havoc: Momentum
		addMod(info.guid, 198793, 5) -- Vengeful Retreat
	end,
	[22502] = function(info) -- Vengeance: Abyssal Strike
		addMod(info.guid, 189110, 8) -- Infernal Strike
	end,
	[22510] = function(info) -- Vengeance: Quickened Sigils
		addMod(info.guid, 202137, 12) -- Sigil of Silence
		addMod(info.guid, 204596, 6)  -- Sigil of Flame
		addMod(info.guid, 207684, 18) -- Sigil of Misery
		-- TODO this also affects the Kyrian Covenant power
	end,

	-- Druid
	[22364] = function(info, playerGUID) -- Feral: Predator
		-- The cooldown on Tiger's Fury resets when a
		-- target dies with one of your Bleed effects active
		if info.guid == playerGUID then
			syncSpells[5217] = true -- Tiger's Fury
		end
	end,
	[21713] = function(info) -- Guardian: Survival of the Fittest
		addMod(info.guid, 22812, 20) -- Barkskin
		addMod(info.guid, 61336, 60) -- Survival Instincts
	end,
	[21716] = function(info) -- Restoration: Inner Peace
		addMod(info.guid, 740, 60) -- Tranquility
	end,

	-- Hunter
	[19348] = function(info, playerGUID) -- All: Natural Mending
		-- Focus you spend reduces the remaining
		-- cooldown on Exhilaration by 1 sec.
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
	[23072] = function(info) -- Arcane: Master of Time
		addMod(info.guid, 342245, 30) -- Alter Time
	end,
	[22448] = function(info) -- Ice Ward
		addMod(info.guid, 122, 0, 2) -- Frost Nova
	end,

	-- Monk
	[19304] = function(info) -- Celerity
		addMod(info.guid, 109132, 5, 3) -- Roll
	end,
	[19993] = function(info) -- Tiger Tail Sweep
		addMod(info.guid, 119381, 10) -- Leg Sweep
	end,

	-- Paladin
	[22433] = function(info) -- Unbreakable Spirit (-30%)
		addMod(info.guid, 642, 90) -- Divine Shield
		addMod(info.guid, 633, 180) -- Lay on Hands

		if info.spec == 65 then
			addMod(info.guid, 498, 18) -- Divine Protection (Holy)
		elseif info.spec == 66 then
			addMod(info.guid, 31850, 36) -- Ardent Defender (Protection)
		elseif info.spec == 70 then
			addMod(info.guid, 184662, 36) -- Shield of Vengeance (Retribution)
		end
	end,
	[22434] = function(info) -- Cavalier
		addMod(info.guid, 190784, 0, 2) -- Divine Steed
	end,

	-- Priest
	[19759] = function(info) -- Disciple: Psychic Voice
		addMod(info.guid, 8122, 30) -- Psychic Scream
	end,
	[21750] = function(info) -- Holy: Psychic Voice
		addMod(info.guid, 8122, 30) -- Psychic Scream
	end,
	[22325] = function(info, playerGUID) -- Holy: Angel's Mercy
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
		addMod(info.guid, 195457, 15) -- Grappling Hook
	end,
	[22114] = function(info) -- Outlaw: Blinding Powder
		addMod(info.guid, 2094, 30) -- Blind
	end,
	[22336] = function(info) -- Subtlety: Enveloping Shadows
		addMod(info.guid, 185313, 0, 2) -- Shadow Dance
	end,

	-- Shaman
	[21970] = function(info) -- Enhancement: Elemental Spirits
		addMod(info.guid, 51533, 30) -- Feral Spirit
	end,
	[22492] = function(info) -- Restoration: Graceful Spirit
		addMod(info.guid, 79206, 60) -- Spiritwalker's Grace
	end,

	-- Warlock
	[22047] = function(info) -- Darkfury
		addMod(info.guid, 30283, 15) -- Shadowfury
	end,
	[23139] = function(info) -- Affliction: Dark Caller
		addMod(info.guid, 205180, 60) -- Summon Darkglare
	end,

	-- Warrior
	[19676] = function(info) -- Double Time
		addMod(info.guid, 100, 3, 2) -- Charge
	end,
	[22627] = function(info) -- Bounding Stride
		addMod(info.guid, 52174, 15) -- Heroic Leap
	end,
	[21204] = function(info, playerGUID) -- Anger Management
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
			elseif info.spec == 73 then -- Protection
				syncSpells[107574] = true -- Avatar
				syncSpells[871] = true -- Shield Wall
			end
		end
	end,
	[22488] = function(info) -- Protection: Bolster
		addMod(info.guid, 12975, 60) -- Last Stand
	end,
}

-- Properly handle spell ranks this time around
data.levelCooldowns = {
	DEATHKNIGHT = function(info)
		if info.spec == 250 then
			if info.level >= 44 then
				addMod(info.guid, 194679, 0, 2) -- Rune Tap
			end
		elseif info.spec == 251 then
			if info.level >= 49 then
				addMod(info.guid, 275699, 15) -- Apocalypse
			end
			if info.level >= 29 then
				addMod(info.guid, 46584, 90) -- Raise Dead
			end
		end
	end,
	DEMONHUNTER = function(info)
		if info.level >= 42 then
			addMod(info.guid, 188501, 30) -- Fel Rush
		end
		if info.spec == 577 then
			if info.level >= 28 then
				addMod(info.guid, 195072, 0, 2) -- Fel Rush
			end
			if info.level >= 47 then
				addMod(info.guid, 196718, 120) -- Darkness
			end
			if info.level >= 48 then
				addMod(info.guid, 187827, 60) -- Metamorphosis
			end
		elseif info.spec == 581 then
			if info.level >= 20 then
				addMod(info.guid, 187827, 60) -- Metamorphosis
			end
			if info.level >= 27 then
				addMod(info.guid, 258920, 15) -- Immolation Aura
			end
			if info.level >= 28 then
				addMod(info.guid, 189110, 0, 2) -- Infernal Strike
			end
			if info.level >= 33 then
				addMod(info.guid, 207684, 90) -- Sigil of Misery
			end
			if info.level >= 48 then
				addMod(info.guid, 187827, 60) -- Metamorphosis
			end
			if info.level >= 48 then
				addMod(info.guid, 202137, 60) -- Sigil of Silence
			end
		end
	end,
	DRUID = function(info)
		if info.spec == 104 then -- Guardian
			if info.level >= 39 then
				addMod(info.guid, 22842, 0, 2) -- Frenzied Regen
			end
			if info.level >= 47 then
				addMod(info.guid, 61336, 0, 2) -- Survival Instincts
			end
			if info.level >= 49 then
				addMod(info.guid, 106898, 60) -- Stampeding Roar
			end
		end
	end,
	HUNTER = function(info)
		if info.spec == 253 then -- Beast Master
			if info.level >= 56 then -- Improved Traps
				addMod(info.guid, 187650, 5) -- Freezing Trap
				addMod(info.guid, 187698, 5) -- Tar Trap
			end
		elseif info.spec == 255 then -- Survival
			if info.level >= 38 then
				addMod(info.guid, 190925, 10) -- Harpoon
			end
		end
	end,
	MAGE = function(info)
		if info.spec == 62 then -- Arcane
			if info.level >= 43 then
				addMod(info.guid, 12051, 90) -- Evocation
			end
		elseif info.spec == 63 then -- Fire
			if info.level >= 38 then
				addMod(info.guid, 31661, 2) -- Dragon's Breath
			end
		elseif info.spec == 64 then -- Frost
			if info.level >= 54 then
				addMod(info.guid, 235219, 30) -- Cold Snap
			end
		end
	end,
	MONK = function(info)
		if info.level >= 9 then
			addMod(info.guid, 109132, 0, 2) -- Roll
		end
		if info.level >= 56 then
			addMod(info.guid, 115078, 15) -- Paralysis
		end
		if info.spec ~= 268 then
			if info.level >= 28 then
				-- Starting CD is 420
				addMod(info.guid, 115203, -60) -- Fortifying Brew
			end
			if info.level >= 48 then
				-- Final CD is 180
				addMod(info.guid, 115203, 240) -- Fortifying Brew
			end
		end
		if info.spec == 269 then
			if info.level >= 54 then
				addMod(info.guid, 101545, 5) -- Flying Serpent Kick
			end
		end
	end,
	PALADIN = function(info)
		if info.level >= 43 then
			addMod(info.guid, 31884, 60) -- Avenging Wrath
		end
		if info.level >= 49 then
			addMod(info.guid, 190784, 15) -- Divine Steed
		end
	end,
	ROGUE = function(info)
		if info.level >= 31 then
			addMod(info.guid, 2983, 60) -- Sprint
		end
		if info.spec == 260 and info.level >= 56 then
			addMod(info.guid, 195457, 15) -- Grappling Hook
		end
	end,
	SHAMAN = function(info)
		if info.level >= 56 then
			addMod(info.guid, 51514, 10) -- Hex
		end
	end,
	WARRIOR = function(info)
		if info.spec == 71 then -- Arms
			if info.level >= 37 then
				addMod(info.guid, 167105, 45) -- Colossus Smash
			end
			if info.level >= 42 then
				addMod(info.guid, 260708, 15) -- Sweeping Strikes
			end
			if info.level >= 52 then
				addMod(info.guid, 118038, 60) -- Die by the Sword
			end
		elseif info.spec == 72 then -- Fury
			if info.level >= 32 then
				addMod(info.guid, 184364, 60) -- Enraged Regeneration
			end
		end
	end,
}

data.combatResSpells = {
	[20484] = true, -- Rebirth
	[95750] = true, -- Soulstone Resurrection
	[61999] = true, -- Raise Ally
}

data.chargeSpells = {
	-- Death Knight
	[194679] = 1, -- Rune Tap (Blood) (2 at 44)
	[221699] = 2, -- Blood Tap (Blood talent)
	-- Demon Hunter
	[195072] = 2, -- Fel Rush (Havoc)
	[189110] = 1, -- Infernal Strike (Vengeance) (2 at 28)
	-- Druid
	[61336] = 1, -- Survival Instincts
	[22842] = 1, -- Frenzied Regeneration
	[274281] = 3, -- New Moon (Balance talent)
	-- Hunter
	[259495] = 1, -- Wildfire Bomb
	-- Mage
	[122] = 1, -- Frost Nova
	[212653] = 2, -- Shimmer
	[108839] = 3, -- Ice Floes
	-- Monk
	[109132] = 1, -- Roll
	[122281] = 2, -- Healing Elixir (Talent)
	-- Paladin
	[190784] = 1, -- Divine Steed
	-- Rogue
	[36554] = 2, -- Shadowstep
	[185313] = 1, -- Shadow Dance
	-- Warrior
	[100] = 1, -- Charge
	[198304] = 2, -- Intercept
}

-- { cd, level, spec id, talent index, sync, race }
-- level can be a hash of spec=level for talents in different locations
-- spec id can be a table of specs and is optional if level or talent are a table
-- talent index can be negative to indicate a talent replaces the spell
--   and can be a hash of spec=index for talents in different locations
-- sync will register SPELL_UPDATE_COOLDOWN and send "CooldownUpdate" syncs
--   with the cd (for dynamic cooldowns with hard to track conditions)
data.spells = {
	DEATHKNIGHT = {
		[43265] = {30, 3, nil, {[250]=false,[251]=false,[252]=-18}}, -- Death and Decay
		[49576] = {25, 5, 250}, -- Death Grip
		[47528] = {15, 7}, -- Mind Freeze
		[48707] = {60, 9}, -- Anti-Magic Shell
		[46584] = {120, 12}, -- Raise Dead
		[275699] = {90, 19, 252}, -- Apocalypse
		[127344] = {15, 19}, -- Corpse Exploder
		[196770] = {20, 19, 251}, -- Remorseless Winder
		[194679] = {25, 19, 250}, -- Rune Tap (2 charges)
		[221562] = {45, 21, 250}, -- Asphyxiate
		[51271] = {45, 29, 251}, -- Pillar of Frost
		[55233] = {90, 29, 250}, -- Vampiric Blood
		[63560] = {60, 32, 252}, -- Dark Transformation
		[108199] = {120, 32, 250}, -- Gorefiend's Grasp
		[49039] = {120, 33}, -- Lichborne
		[49028] = {120, 34, 250}, -- Dancing Rune Weapon
		[48792] = {180, 38}, -- Icebound Fortitude
		[61999] = {600, 39}, -- Raise Ally
		[42650] = {480, 44, 252}, -- Army of the Dead
		[279302] = {180, 44, 251}, -- Frostwyrm's Fury
		[51052] = {120, 47}, -- Anti-Magic Zone
		[47568] = {120, 48, 251}, -- Empower Rune Weapon
		[327574] = {120, 54}, -- Sacrificial Pact

		[206931] = {30, 15, 250, 2}, -- Blooddrinker
		[219809] = {60, 15, 250, 3}, -- Tombstone
		[274156] = {30, 25, 250, 6}, -- Consumption
		[57330] = {45, 25, 251, 6}, -- Horn of Winter
		[115989] = {45, 25, 252, 6}, -- Unholy Blight
		[108194] = {45, 30, nil, {[251]=8, [252]=9}}, -- Asphyxiate
		[207167] = {60, 30, 251, 9}, -- Blinding Sleet
		[221699] = {60, 30, 250, 9}, -- Blood Tap (2 charges)
		[212552] = {60, 40, nil, {[250]=15, [251]=14, [252]=14}}, -- Wraith Walk
		[48743] = {120, 45, nil, {[250]=17, [251]=15, [252]=15}}, -- Death Pact
		[152280] = {20, 45, 252, 18}, -- Defile
		[49206] = {180, 50, 252, 20}, -- Summon Gargoyle
		[152279] = {120, 50, 251, 21}, -- Breath of Sindragosa
		[194844] = {60, 50, 250, 21}, -- Bonestorm
		[207289] = {75, 50, 252, 21}, -- Unholy Assault
	},
	DEMONHUNTER = {
		[179057] = {60, 1, 577}, -- Chaos Nova
		[195072] = {10, 1, 577}, -- Fel Rush
		[204021] = {60, 1, 581}, -- Fiery Brand
		[189110] = {20, 1, 581}, -- Infernal Strike
		[187827] = {300, 1, 581}, -- Metamorphosis (Vengeance)
		[200166] = 187827, -- Metamorphosis (Havoc)
		[188501] = {60, 1}, -- Spectral Sight
		[198793] = {25, 1, 577}, -- Vengeful Retreat
		[212084] = {60, 11, 581}, -- Fel Devastation
		[204596] = {30, 12, 581}, -- Sigil of Flame
		[258920] = {30, 14}, -- Immolation Aura
		[278326] = {10, 17}, -- Consume Magic
		[207684] = {180, 21, 581}, -- Sigil of Misery
		[183752] = {15, 29}, -- Disrupt
		[198589] = {60, 33, 577}, -- Blur
		[217832] = {45, 34}, -- Imprison
		[196718] = {300, 39, 577}, -- Darkness
		[202137] = {120, 39, 581}, -- Sigil of Silence

		[232893] = {15, 15, nil, 3}, -- Felblade
		[342817] = {20, 30, 577, 9}, -- Glaive Tempest
		[196555] = {180, 35, 577, 12}, -- Netherwalk
		[258860] = {20, 40, 577, 15}, -- Essence Break
		[202138] = {90, 40, 581, 15}, -- Sigil of Chains
		[211881] = {30, 45, 577, 18}, -- Fel Eruption
		[263648] = {30, 45, 581, 18}, -- Soul Barrier
		[258925] = {60, 50, 577, 21}, -- Fel Barrage
		[320341] = {90, 50, 581, 21}, -- Bulk Extraction
	},
	DRUID = {
		[1850] = {120, 6}, -- Dash
		[5217] = {30, 12, 103}, -- Tiger's Fury
		[102342] = {90, 12, 105}, -- Ironbark
		[22842] = {36, 21, nil, {[102]=8,[103]=8,[104]=false,[105]=8}}, -- Frenzied Regeneration (2 charges at 39)
		[22812] = {60, 24}, -- Barkskin
		[106839] = {15, 26, {103, 104}}, -- Skull Bash
		[78675] = {60, 26, 102}, -- Solar Beam
		[99] = {30, 28, 104}, -- Incapacitating Roar
		[132469] = {30, 28, 102}, -- Typhoon
		[61391] = 132469, -- Typhoon (actual event)
		[102793] = {60, 28, nil, {[102]=9,[103]=9,[104]=9,[105]=false}}, -- Ursol's Vortex
		[20484] = {600, 29}, -- Rebirth
		[61336] = {180, 32, {103, 104}}, -- Survival Instincts (2 charges at 47)
		[106951] = {180, 34, 103, -15}, -- Berserk
		[740] = {180, 37, 105}, -- Tranquility
		[194223] = {180, 39, 102, -15}, -- Celestial Alignment
		[2908] = {10, 41}, -- Soothe
		[29166] = {180, 42, {102, 105}}, -- Innervate
		[106898] = {120, 43}, -- Stampeding Roar
		-- [77761] = 106898, -- Stampeding Roar (Guardian, 60s)
		-- [77764] = 106898, -- Stampeding Roar (Feral, 120s)
		[132158] = {60, 58, 105}, -- Nature's Swiftness

		[202425] = {45, 15, 102, 2}, -- Warrior of Elune
		[205636] = {60, 15, 102, 3}, -- Force of Nature
		[155835] = {40, 15, 104, 3}, -- Bristling Fur
		[102351] = {30, 15, 105, 3}, -- Cenarion Ward
		[252216] = {45, 25, nil, 4}, -- Tiger Dash
		[108238] = {90, 25, nil, 5}, -- Renewel
		[132302] = {15, 25, nil, 6}, -- Wild Charge
		[16979]  = 132302, -- Wild Charge (Bear)
		[49376]  = 132302, -- Wild Charge (Cat)
		[102383] = 132302, -- Wild Charge (Moonkin)
		[102416] = 132302, -- Wild Charge (Aquatic)
		[102417] = 132302, -- Wild Charge (Travel)
		[5211]   = {50, 35, nil, 10}, -- Mighty Bash
		[102359] = {30, 35, nil, 11}, -- Mass Entanglement
		[319454] = {300, 35, nil, 12}, -- Heart of the Wild
		[102560] = {180, 40, 102, 15}, -- Incarnation: Chosen of Elune
		[102543] = {180, 40, 103, 15}, -- Incarnation: King of the Jungle
		[102558] = {180, 40, 104, 15}, -- Incarnation: Guardian of Ursoc
		[203651] = {60, 45, 105, 18}, -- Overgrowth
		[202770] = {60, 50, 102, 20}, -- Fury of Elune
		[274837] = {45, 50, 103, 21}, -- Feral Frenzy
		[274281] = {25, 50, 102, 21}, -- New Moon (3 charges)
		[80313] = {45, 50, 104, 21}, -- Lunar Beam
		[33891]  = {180, 40, 105, 15}, -- Incarnation: Tree of Life
		[197721] = {90, 50, 21}, -- Flourish
	},
	HUNTER = {
		[781] = {20, 4}, -- Disengage
		[186257] = {180, 5}, -- Aspect of the Cheetah
		[136] = {10, 5}, -- Mend Pet
		[5384] = {30, 6}, -- Feign Death
		[186265] = {180, 8}, -- Aspect of the Turtle
		[109304] = {120, 9}, -- Exhilaration
		[187650] = {30, 10}, -- Freezing Trap
		[186387] = {30, 12, 254}, -- Bursting Shot
		[190925] = {30, 14, 255}, -- Harpoon
		[147362] = {24, 18, {253, 254}}, -- Counter Shot
		[187707] = {15, 18, 255}, -- Muzzle
		[61648] = {180, 19}, -- Aspect of the Chameleon
		[1543] = {20, 19}, -- Flare
		[19574] = {90, 20, 253}, -- Bestial Wrath
		-- [257044] = {20, 20, 254}, -- Rapid Fire (Lethal Shots randomly reduces it)
		[259495] = {18, 20, 255}, -- Wildfire Bomb
		[270335] = 259495, -- Shrapnel Bomb (20: Wildfire Infusion)
		[270323] = 259495, -- Pheromone Bomb (20: Wildfire Infusion)
		[271045] = 259495, -- Volatile Bomb (20: Wildfire Infusion)
		[187698] = {30, 21, 255}, -- Tar Trap
		[186289] = {90, 24, 255}, -- Aspect of the Eagle
		[34477] = {30, 27}, -- Misdirection
		[19577] = {60, 33, {253,255}}, -- Intimidation
		[266779] = {120, 34, 255}, -- Coordinated Assault
		[288613] = {120, 34, 254}, -- Trueshot
		[19801] = {10, 37}, -- Tranquilizing Shot
		[193530] = {120, 38, 253}, -- Aspect of the Wild

		[212431] = {30, 25, 254, 6}, -- Explosive Shot
		[199483] = {60, 30, nil, 9}, -- Camouflage
		[162488] = {30, 35, 255, 11}, -- Steel Trap
		[131894] = {60, {[253]=35,[254]=15,[255]=35}, nil, {[253]=12,[254]=3,[255]=12}, true}, -- A Murder of Crows
		[109248] = {45, 40, nil, {[253]=15,[254]=false,[255]=15}}, -- Binding Shot
		[120360] = {20, {[253]=35,[254]=25}, nil, {[253]=17,[254]=5}}, -- Barrage
		[260402] = {60, 45, 254, 18}, -- Double Tap
		[201430] = {120, 45, 253, 18}, -- Stampede
		[269751] = {40, 45, 255, 18}, -- Flanking Strike
		[321530] = {60, 50, 253, 21}, -- Bloodshed
		[260243] = {45, 50, 254, 21}, -- Volley
		[259391] = {20, 50, 255, 21}, -- Chakrams

		-- Command Pet XXX Not sure how do deal with these for available cds
		[53271] = {45, 22}, -- Master's Call (Cunning)
		[264735] = {180, 22}, -- Survival of the Fittest (Tenacity)
		[272678] = {360, 22}, -- Primal Rage (Ferocity)
	},
	MAGE = {
		[45438] = {240, 22}, -- Ice Block
		[122] = {30, 3}, -- Frost Nova
		[1953] = {15, 4, nil, -5}, -- Blink
		-- [342247] = {60, {[62]=19,[63]=58,[64]=58}}, -- Alter Time -- XXX same spell id to cancel the effect
		[2139] = {24, 7}, -- Counterspell
		[31687] = {30, 12, 64, -2}, -- Summon Water Elemental
		[120] = {12, 18, 64}, -- Cone of Cold
		[235450] = {25, 21, 62}, -- Prismatic Barrier
		[235313] = {25, 21, 63}, -- Blazing Barrier
		[11426] = {25, 21, 64}, -- Ice Barrier
		[33395] = {25, 23, 62}, -- Freeze (Pet)
		[31661] = {20, 27, 63}, -- Dragon's Breath
		[12051] = {180, 27, 62}, -- Evocation
		[12042] = {120, 29, 62}, -- Arcane Power
		[12472] = {180, 29, 64}, -- Icy Veins
		[190319] = {120, 29, 63}, -- Combustion
		[321507] = {45, 33, 62}, -- Touch of the Magi
		[66] = {300, 34}, -- Invisibility
		[84714] = {60, 38, 64}, -- Frozen Orb
		[205025] = {60, 42, 62}, -- Presence of Mind
		[235219] = {300, 42, 64}, -- Cold Snap
		[55342]  = {120, 44}, -- Mirror Image
		[110959] = {120, 47, 62}, -- Greater Invisibility
		[80353] = {300, 49}, -- Time Warp

		[205022] = {10, 15, 62, 3}, -- Arcane Familiar
		[157997] = {25, 15, 64, 3}, -- Ice Nova
		[212653] = {15, 25, nil, 5}, -- Shimmer (2 charges)
		[157981] = {25, 25, 63, 6}, -- Blast Wave
		[108839] = {20, 25, 64, 6}, -- Ice Floes (3 charges)
		[116011] = {120, 30, nil, 9}, -- Rune of Power
		[257537] = {45, 35, 64, 12}, -- Ebonbolt
		[113724] = {45, 40, nil, 15}, -- Ring of Frost
		[153626] = {20, 45, 62, 17}, -- Arcane Orb
		[157980] = {25, 45, 62, 18}, -- Supernova
		[44457]  = {12, 45, 63, 18}, -- Living Bomb
		[153595] = {30, 45, 64, 18}, -- Comet Storm
		[153561] = {45, 50, 63, 21}, -- Meteor
		[205021] = {75, 50, 64, 20}, -- Ray of Frost
	},
	MONK = {
		[109132] = {20, 3, nil, -5}, -- Roll
		[119381] = {60, 6}, -- Leg Sweep
		[115080] = {180, 10}, -- Touch of Death
		[169340] = {90, 17}, -- Touch of Fatality
		[116705] = {15, 18, {268, 269}}, -- Spear Hand Strike
		[101545] = {25, 21, 269}, -- Flying Serpent Kick
		[115078] = {45, 22}, -- Paralysis
		[116680] = {30, 23, 270}, -- Thunder Focus Tea
		[322507] = {60, 27, 268}, -- Celestial Brew
		[116849] = {120, 27, 270}, -- Life Cocoon
		[115203] = {360, 28}, -- Fortifying Brew (Brewmaster)
		[243435] = 115203, -- Fortifying Brew (Windwalker, Mistweaver)
		[122470] = {90, 29, 269}, -- Touch of Karma
		[115176] = {300, 34, 268}, -- Zen Meditation
		[132578] = {180, 42, 268}, -- Invoke Niuzao, the Black Ox
		[123904] = {120, 42, 269}, -- Invoke Xuen, the White Tiger
		[322118] = {180, 42, 270, -18}, -- Invoke Yu'lon, the Jade Serpent
		[115310] = {180, 46, 270}, -- Revival
		[324312] = {30, 54, 268}, -- Clash

		[115008] = {20, 25, nil, 5}, -- Chi Torpedo
		[116841] = {30, 25, nil, 6}, -- Tiger's Lust
		[115399] = {120, 30, 268, 9}, -- Black Ox Brew
		[115288] = {60, 30, 269, 9}, -- Energizing Elixir
		[197908] = {90, 30, 270, 9}, -- Mana Tea
		[115315] = {10, 35, 268, 11}, -- Summon Black Ox Statue
		[198898] = {30, 35, 270, 11}, -- Song of Chi-Ji
		[116844] = {45, 35, nil, 12}, -- Ring of Peace
		[122281] = {30, 40, nil, {[268]=14,[270]=16}}, -- Healing Elixir
		[122783] = {90, 40, {269,270}, 14}, -- Diffuse Magic
		[122278] = {120, 40, nil, 15}, -- Dampen Harm
		[325153] = {60, 45, 268, 18}, -- Exploding Keg
		[325197] = {180, 45, 270, 18}, -- Invoke Chi-Ji, the Red Crane
		[152173] = {90, 50, 269, 21}, -- Serenity
	},
	PALADIN = {
		[853] = {60, 5}, -- Hammer of Justice
		[633] = {600, 9}, -- Lay on Hands
		[642] = {300, 10}, -- Divine Shield
		[190784] = {60, 17}, -- Divine Steed
		[183218] = {30, 18, 70}, -- Hand of Hindrance
		[1044] = {25, 22}, -- Blessing of Freedom
		[10326] = {15, 24}, -- Turn Evil
		[498] = {60, 26, {65, 66}}, -- Divine Protection
		[184662] = {120, 26, 70}, -- Shield of Vengeance
		[96231] = {15, 27, {66, 70}}, -- Rebuke
		[6940] = {120, 32}, -- Blessing of Sacrifice
		[31884] = {180, 37, nil, {[65]=-17}}, -- Avenging Wrath
		[31821] = {180, 39, 65}, -- Aura Mastery
		[86659] = {300, 39, 66}, -- Guardian of Ancient Kings
		[255937] = {45, 39, 70}, -- Wake of Ashes
		[1022] = {300, 41, nil, {[66]=-15}}, -- Blessing of Protection
		[31850] = {120, 42, 66}, -- Ardent Defender

		[114158] = {60, 15, 65, 3}, -- Light's Hammer
		[327193] = {90, 25, 66, 6}, -- Moment of Glory
		[343527] = {60, 15, 70, 3}, -- Execution Sentence
		[114165] = {20, 25, 65, 14}, -- Holy Prism
		[20066] = {15, 30, nil, 8}, -- Repentance
		[115750] = {90, 30, nil, 9}, -- Blinding Light
		[204018] = {180, 35, 66, 12}, -- Blessing of Spellwarding
		[105809] = {180, 40, nil, 14}, -- Holy Avenger
		[152262] = {45, 40, nil, 15}, -- Seraphim
		[216331] = {120, 45, 65, 17}, -- Avenging Crusader
		[205191] = {60, 35, 70, 15}, -- Eye for an Eye
		[231895] = 31884, -- Crusade (Replaces Avenging Wrath has the same CD)
		[343721] = {60, 50, 70, 21}, -- Final Reckoning
	},
	PRIEST = {
		[8122] = {60, 7, nil, {[258]=-11}}, -- Psychic Scream
		[19236] = {90, 8}, -- Desperate Prayer
		[586] = {30, 9}, -- Fade
		[47585] = {120, 16, 258}, -- Dispersion
		[34433] = {180, 20, {256, 258}, {[256]=-8,[258]=-17}}, -- Shadowfiend
		[194509] = {20, 23, 256}, -- Power Word: Radiance
		[88625] = {60, 23, 257}, -- Holy Word: Chastise
		[15286] = {120, 25, 258}, -- Vampiric Embrace
		[15487] = {45, 29, 258}, -- Silence
		[47788] = {180, 30, 257}, -- Guardian Spirit
		[33206] = {180, 38, 256}, -- Pain Suppression
		[47536] = {90, 41, 256}, -- Rapture
		[34861] = {60, 41, 257}, -- Holy Word: Sanctify
		[32375] = {45, 42}, -- Mass Dispel
		[62618] = {180, 44, 256}, -- Power Word: Barrier
		[64843] = {180, 44, 257}, -- Divine Hymn
		[64901] = {300, 47, 257}, -- Symbol of Hope
		[73325] = {90, 49}, -- Leap of Faith
		[10060] = {120, 58}, -- Power Infusion

		[123040] = {60, {[256]=30,[258]=45}, nil, {[256]=8,[258]=17}}, -- Mindbender
		[200174] = 123040, -- Mindbender (Shadow)
		[205369] = {30, 35, 258, 11}, -- Mind Bomb
		[204263] = {45, 35, {256, 257}, 12}, -- Shining Force
		[64044] = {45, 35, 258, 12}, -- Psychic Horror
		[120517] = {40, 45, {256, 257}, 18}, -- Halo
		[109964] = {60, 50, 256, 20}, -- Spirit Shell
		[200183] = {120, 50, 257, 20}, -- Apotheosis
		[246287] = {90, 50, 256, 21}, -- Evangelism
		[265202] = {720, 50, 257, 21}, -- Holy Word: Salvation
		[193223] = {90, 50, 258, 21}, -- Surrender to Madness
	},
	ROGUE = {
		-- Restless Blades (Outlaw, 41): Finishing moves reduce the remaining cooldown
		-- of Adrenaline Rush, Between the Eyes, Sprint, Grappling Hook, Ghostly
		-- Strike, Marked for Death, Blade Rush, Killing Spree, and Vanish by 1 sec
		-- per combo point spent.

		[2983] = {120, 5}, -- Sprint
		[1766] = {15, 6}, -- Kick
		[185311] = {30, 8}, -- Crimson Vial
		[408] = {20, 13}, -- Kidney Shot
		[36554] = {30, 18, {259,261}}, -- Shadowstep
		[195457] = {60, 18, 260, nil, true}, -- Grappling Hook
		[13877] = {30, 19, 260}, -- Blade Flurry
		[5277] = {120, 21}, -- Evasion
		[185313] = {60, 22, 261, nil, true}, -- Shadow Dance - 41 Deepening Shadows: Your finishing moves reduce the remaining cooldown on Shadow Dance per combo point spent.
		[1856] = {120, 23, nil, nil, {[260]=true}}, -- Vanish
		[1725] = {30, 28}, -- Distract
		[212283] = {30, 29, 261}, -- Symbols of Death
		[1966] = {15, 34}, -- Feint
		[2094] = {120, 39}, -- Blind
		[79140] = {120, 42, 259}, -- Vendetta
		[13750] = {180, 42, 260, nil, true}, -- Adrenaline Rush
		[121471] = {180, 42, 261}, -- Shadow Blades
		[1776]  = {15, 46, 260}, -- Gouge
		[31224] = {120, 47}, -- Cloak of Shadows
		[57934] = {30, 48}, -- Tricks of the Trade
		[114018] = {360, 49}, -- Shroud of Concealment

		[196937] = {35, 15, 260, 3, true}, -- Ghostly Strike
		[137619] = {60, 30, nil, 12, true}, -- Marked for Death
		[200806] = {45, 45, 259, 18}, -- Exsanguinate
		[343142] = {90, 45, 260, 18}, -- Dreadblades
		[271877] = {45, 50, 260, 20, true}, -- Blade Rush
		[51690] = {120, 50, 260, 21, true}, -- Killing Spree
		[280719] = {45, 50, 261, 20, true}, -- Secret Technique
		[277925] = {60, 50, 261, 21}, -- Shuriken Tornado
	},
	SHAMAN = {
		[2484] = {30, 5}, -- Earthbind Totem
		[20608] = {1800, 8}, -- Reincarnation
		[21169] = 20608, -- Reincarnation (Resurrection)
		[57994] = {12, 12}, -- Wind Shear
		[192058] = {60, 23}, -- Capacitor Totem
		[198067] = {150, 34, 262, -11}, -- Fire Elemental
		[51533] = {120, 34, 263}, -- Feral Spirit
		[198103] = {300, 37, 262}, -- Earth Elemental
		[108280] = {180, 38, 264}, -- Healing Tide Totem
		[51514] = {30, 41}, -- Hex (Frog)
		[211004] = 51514, -- Spider
		[211015] = 51514, -- Cockroach
		[277778] = 51514, -- Zandalari Tendonripper
		[309328] = 51514, -- Living Honey
		[210873] = 51514, -- Compy
		[211010] = 51514, -- Snake
		[269352] = 51514, -- Skeletal Hatchling
		[277784] = 51514, -- Wicker Mongrel
		[108271] = {90, 42}, -- Astral Shift
		[98008] = {180, 43, 264}, -- Spirit Link Totem
		[58875] = {60, 44, 263}, -- Spirit Walk
		[79206] = {120, 44, {262,264}}, -- Spiritwalker's Grace
		[8143] = {60, 47}, -- Tremor Totem
		[UnitFactionGroup("player") == "Horde" and 2825 or 32182] = {300, 48}, -- Bloodlust/Heroism
		[51490] = {45, 49, 262}, -- Thunderstorm

		[342243] = {30, 15, 262, 3}, -- Static Discharge
		[320125] = {30, 25, 262, 5}, -- Echoing Shock
		[342240] = {15, 25, 263, 6}, -- Ice Strike
		[51485] = {30, 30, 264, 8}, -- Earthgrab Totem
		[192249] = {150, 35, 262, 11}, -- Storm Elemental
		[198838] = {60, 35, 264, 11}, -- Earthen Wall Totem
		[192222] = {60, 35, 262, 12}, -- Liquid Magma Totem
		[207399] = {300, 35, 264, 12}, -- Ancestral Protection Totem
		[108281] = {120, 40, 262, 14}, -- Ancestral Guidance
		[196884] = {30, 40, 263, 14}, -- Feral Lunge
		[192077] = {120, 40, nil, 15}, -- Wind Rush Totem
		[210714] = {30, 45, 262, 18}, -- Icefury
		[191634] = {60, {[262]=50,[263]=45}, nil, {[262]=20,[263]=17}}, -- Stormkeeper (Elemental)
		[320137] = 191634, -- Stormkeeper (Enhancement)
		[197214] = {40, 45, 263, 18}, -- Sundering
		[157153] = {30, 45, 264, 18}, -- Cloudburst Totem
		[114049] = {180, 50, nil, 21}, -- Ascendance (old id, but keeping it for compat as the master option for the 3 merged spells)
		[114050] = 114049, -- Ascendance (Elemental)
		[114051] = 114049, -- Ascendance (Enhancement)
		[114052] = 114049, -- Ascendance (Restoration)
	},
	WARLOCK = {
		[104773] = {180, 4}, -- Unending Resolve
		[333889] = {180, 22}, -- Fel Domination
		[80240] = {30, 27, 267}, -- Havoc
		[19647] = {24, 29}, -- Spell Lock (Felhunter)
		[119910] = 19647, -- Spell Lock (Command Demon)
		[132409] = 19647, -- Spell Lock (Grimoire of Sacrifice Command Demon)
		[698] = {120, 33}, -- Ritual of Summoning
		[30283] = {60, 38}, -- Shadowfury
		[205180] = {180, 42, 265}, -- Summon Darkglare
		[265187] = {90, 42, 266}, -- Summon Demonic Tyrant
		[1122] = {180, 42, 267}, -- Summon Infernal
		[29893] = {120, 47}, -- Create Soulwell
		[20707] = {600, 32}, -- Soulstone
		[95750] = 20707, -- Soulstone Resurrection (combat)

		[267211] = {30, 15, 266, 2}, -- Bilescourge Bombers
		[267171] = {60, 15, 266, 3}, -- Demonic Strength
		[264130] = {30, 25, 266, 5}, -- Power Siphon
		[108416] = {60, 30, nil, 9}, -- Dark Pact
		[205179] = {45, 35, 265, 11}, -- Phantom Singularity
		[278350] = {20, 35, 265, 12}, -- Vile Taint
		[264119] = {45, 35, 266, 12}, -- Summon Vilefiend
		[152108] = {30, 35, 267, 12}, -- Cataclysm
		[6789] = {45, 40, nil, 14}, -- Mortal Coil
		[5484] = {40, 40, nil, 15}, -- Howl of Terror
		[111898] = {120, 45, 266, 18}, -- Grimoire: Felguard
		[113860] = {120, 50, 265, 21}, -- Dark Soul: Misery
		[267217] = {180, 50, 266, 21}, -- Nether Portal
		[113858] = {120, 50, 267, 21}, -- Dark Soul: Instability
	},
	WARRIOR = {
		[100] = {20, 2}, -- Charge
		[6552] = {15, 7}, -- Pummel
		[167105] = {90, 19, 71}, -- Colossus Smash
		[12323] = {30, 21, {71,72}}, -- Piercing Howl
		[46968] = {40, 21, 73}, -- Shockwave
		[260708] = {45, 22, 71, -15}, -- Sweeping Strikes
		[118038] = {180, 23, 71}, -- Die by the Sword
		[184364] = {180, 23, 72}, -- Enraged Regeneration
		[871] = {240, 23, 73}, -- Shield Wall
		[1160] = {45, 27, 73}, -- Demoralizing Shout
		[18499] = {60, 29}, -- Berserk Rage
		[52174] = {45, 33}, -- Heroic Leap
		[5246] = {90, 34}, -- Intimidating Shout
		[227847] = {90, {[71]=38,[72]=45}, nil, {[71]=-21,[72]=18}}, -- Bladestorm (Arms)
		[12975] = {180, 38, 73}, -- Last Stand
		[1719] = {90, 38, 72}, -- Recklessness
		[64382] = {180, 41}, -- Shattering Throw
		[3411] = {30, 43}, -- Intervene
		[97462] = {180, 46}, -- Rallying Cry
		[23920] = {25, 47, 73}, -- Spell Reflection
		[1161] = {240, 54}, -- Challenging Shout

		[260643] = {21, 15, 71, 3}, -- Skullsplitter
		[107570] = {30, 25, nil, 6}, -- Storm Bolt
		[262161] = {45, 40, 71, 14}, -- Warbreaker
		[118000] = {35, {[72]=45,[73]=30}, nil, {[72]=17,[73]=9}}, -- Dragon Roar
		[107574] = {90, {[71]=45,[73]=32}, nil, {[71]=17,[73]=false}}, -- Avatar (Protection always has it)
		[262228] = {60, 45, 71, 18}, -- Deadly Calm
		[152277] = {45, {[71]=50,[73]=45}, nil, {[71]=21,[73]=18}}, -- Ravager (Arms)
		[228920] = 152277, -- Ravager (Protection)
		[46924] = 227847, -- Bladestorm (Fury talent 18)
		[280772] = {30, 50, 72, 21}, -- Siegebreaker
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
		[59752] = {120, 1, nil, nil, nil, "Human"}, -- Will to Survive (Human)
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
		[287712] = {150, 1, nil, nil, nil, "KulTiran"}, -- Haymaker (Kul Tiran)
		[291944] = {150, 1, nil, nil, nil, "ZandalariTroll"}, -- Regeneratin' (Zandalari Troll)
		[312411] = {90, 1, nil, nil, nil, "Vulpera"}, -- Bag of Tricks (Vulpera)
		[312924] = {180, 1, nil, nil, nil, "Mechgnome"}, -- Hyper Organic Light Originator (Mechgnome)
	}
}
