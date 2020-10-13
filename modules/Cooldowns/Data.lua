
local _, scope = ...

scope.cooldownData = {}
local data = scope.cooldownData

data.cdModifiers = {}
local cdModifiers = data.cdModifiers
data.chargeModifiers = {}
local chargeModifiers = data.chargeModifiers
data.syncSpells = {}
local syncSpells = {}

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
	[21866] = function(info, playerGUID) -- Havoc: Cycle of Hatred
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
	[22364] = function(info, playerGUID) -- Feral: Predator
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
	[19348] = function(info, playerGUID) -- All: Natural Mending
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
	[21204] = function(info, playerGUID) -- All: Anger Management
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

data.combatResSpells = {
	[20484] = true, -- Rebirth
	[95750] = true, -- Soulstone Resurrection
	[61999] = true, -- Raise Ally
}

data.chargeSpells = {
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

-- { cd, level, spec id, talent index, sync, race }
-- level can be a hash of spec=level for talents in different locations
-- spec id can be a table of specs and is optional if level or talent are a table
-- talent index can be negative to indicate a talent replaces the spell
--   and can be a hash of spec=index for talents in different locations
-- sync will register SPELL_UPDATE_COOLDOWN and send "CooldownUpdate" syncs
--   with the cd (for dynamic cooldowns with hard to track conditions)
data.spells = {
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
		[6940] = {120, 56, {65, 66}}, -- Blessing of Sacrifice
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
