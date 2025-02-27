
local _, scope = ...

scope.cooldownData = {}
local data = scope.cooldownData

-- Spell Data

data.cdModifiers = {}
local cdModifiers = data.cdModifiers
data.chargeModifiers = {}
local chargeModifiers = data.chargeModifiers
data.syncSpells = {}
local syncSpells = data.syncSpells

local playerGUID = UnitGUID("player")

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
	[96174] = function(info) -- Class: Anti-Magic Barrier
		addMod(info.guid, 48707, 20) -- Anti-Magic Shell
	end,
	[96175] = function(info) -- Class: Acclimation
		addMod(info.guid, 48792, 20) -- Icebound Fortitude
	end,
	[96186] = function(info) -- Class: Death's Reach
		-- Reset on exp/honor kills
		if info.guid == playerGUID then
			syncSpells[43265] = true
		end
	end,
	[96184] = function(info) -- Class: Death's Echo
		addMod(info.guid, 43265, 0, 2) -- Death and Decay
		addMod(info.guid, 48265, 0, 2) -- Death's Advance
		addMod(info.guid, 49576, 0, 2) -- Death Grip
	end,
	[96265] = function(info) -- Blood: Tightening Grasp
		addMod(info.guid, 108199, 30) -- Gorefiend's Grasp
	end,
	[96263] = function(info) -- Blood: Red Thirst
		-- Reduces the cooldown on Vampiric Blood by 1s per 10 rp spent.
		if info.guid == playerGUID then
			syncSpells[55233] = true -- Vampiric Blood
		end
	end,
	[96229] = function(info) -- Frost: Empower Rune Weapon
		if info.talents[96178] then -- Empower Rune Weapon (Class talent)
			addMod(info.guid, 47568, 0, 2) -- Empower Rune Weapon
		end
	end,
	[96325] = function(info) -- Unholy: Raise Dead
		addMod(info.guid, 46584, 90) -- Raise Dead (spell override)
	end,
	[96331] = function(info, rank) -- Unholy: Unholy Command
		addMod(info.guid, 63560, rank * 8) -- Dark Transformation
	end,
	[96287] = function(info) -- Unholy: Army of the Damned
		addMod(info.guid, 275699, 45) -- Apocalypse
	end,

	-- Demon Hunter
	[112928] = function(info) -- Class: Blazing Path
		addMod(info.guid, 195072, 0, 2)  -- Fel Rush
	end,
	[112858] = function(info) -- Class: Improved Sigil of Misery
		addMod(info.guid, 207684, 30) -- Sigil of Misery
	end,
	[112914] = function(info, rank) -- Class: Erratic Felheart
		addMod(info.guid, 195072, rank) -- Fel Rush
	end,
	[112919] = function(info) -- Class: Pitch Black
		addMod(info.guid, 196718, 120) -- Darkness
	end,
	[117757] = function(info, rank) -- Class: Rush of Chaos
		addMod(info.guid, 187827, rank * 30) -- Metamorphosis
	end,
	[112944] = function(info) -- Havoc: Tactical Retreat
		addMod(info.guid, 198793, 5) -- Vengeful Retreat
	end,
	[117741] = function(info) -- Havoc: A Fire Inside
		addMod(info.guid, 258920, 0, 2) -- Immolation Aura
	end,
	[112866] = function(info) -- Vengeance: Meteoric Strike
		addMod(info.guid, 189110, 10) -- Infernal Strike
	end,
	[112901] = function(info) -- Vengeance: Darkglare Boon
		-- When Fel Devastation finishes fully channeling,
		-- it refreshes 20-40% of it's cooldown
		if info.guid == playerGUID then
			syncSpells[212084] = true -- Fel Devastation
		end
	end,
	[112876] = function(info) -- Vengeance: Down in Flames
		addMod(info.guid, 204021, 15, 2) -- Fiery Brand
	end,
	[117760] = function(info) -- Vengeance: Illuminated Sigils
		addMod(info.guid, 202137, 0, 2) -- Sigil of Silence
		addMod(info.guid, 204596, 0, 2) -- Sigil of Flame
		addMod(info.guid, 207684, 0, 2) -- Sigil of Misery
		addMod(info.guid, 202138, 0, 2) -- Sigil of Chains
		addMod(info.guid, 390163, 0, 2) -- Elysian Decree
	end,

	-- Druid
	[114298] = function(info) -- Class: Incessant Tempest
		addMod(info.guid, 132469, 5) -- Typhoon
	end,
	[103308] = function(info) -- Class: Improved Stampeding Roar
		addMod(info.guid, 106898, 60) -- Stampeding Roar
	end,
	[109856] = function(info) -- Balance: Orbital Strike
		addMod(info.guid, 194223, 60) -- Celestial Alignment
	end,
	[109864] = function(info) -- Balance: Elune's Guidance
		if info.talents[109838] then
			addMod(info.guid, 391528, 60) -- Convoke the Spirits
		end
	end,
	[109847] = function(info) -- Balance: Radiant Moonlight
		addMod(info.guid, 202770, 15) -- Fury of Elune
	end,
	[103186] = function(info) -- Feral: Predator
		-- The cooldown on Tiger's Fury resets when a
		-- target dies with one of your Bleed effects active
		if info.guid == playerGUID then
			syncSpells[5217] = true -- Tiger's Fury
		end
	end,
	[103166] = function(info) -- Feral: Berserk: Heart of the Lion
		-- Each combo point spent reduces the cooldown
		-- of Berserk by 0.5 sec.
		if info.guid == playerGUID then
			if info.talents[103178] then -- Incarnation: Avatar of Ashamane
				syncSpells[102543] = true
			else
				syncSpells[106951] = true -- Berserk
			end
		end
	end,
	[103176] = function(info) -- Feral: Ashamane's Guidance
		if info.talents[103177] then
			addMod(info.guid, 391528, 60) -- Convoke the Spirits
		end
	end,
	[103192] = function(info) -- Guardian: Improved Survival Instincts
		addMod(info.guid, 61336, 0, 2) -- Survival Instincts
	end,
	[103229] = function(info) -- Guardian: Innate Resolve
		addMod(info.guid, 22842, 0, 2) -- Frenzied Regeneration
	end,
	[103226] = function(info, rank) -- Guardian: Reinvigoration
		addMod(info.guid, 22842, rank * 7.2) -- Frenzied Regeneration
	end,
	[103210] = function(info, rank) -- Guardian: Survival of the Fittest
		addMod(info.guid, 22812, rank * 9) -- Barkskin
		addMod(info.guid, 61336, rank * 27) -- Survival Instincts
	end,
	[103199] = function(info) -- Guardian: Ursoc's Guidance
		if info.talents[103200] then
			addMod(info.guid, 391528, 60) -- Convoke the Spirits
		end
	end,
	[103102] = function(info) -- Restoration: Passing Seasons
		addMod(info.guid, 132158, 12) -- Nature's Swiftness
	end,
	[103107] = function(info) -- Restoration: Inner Peace
		addMod(info.guid, 740, 30) -- Tranquility
	end,
	[103139] = function(info) -- Restoration: Improved Ironbark
		addMod(info.guid, 102342, 20) -- Ironbark
	end,
	[103118] = function(info) -- Restoration: Cenarius' Guidance
		if info.talents[103119] then
			addMod(info.guid, 391528, 60) -- Convoke the Spirits
		end
	end,

	-- Evoker
	[87584] = function(info) -- Class: Forger of Mountains
		addMod(info.guid, 358385, 30) -- Landslide
	end,
	[87701] = function(info) -- Class: Obsidian Bulwark
		addMod(info.guid, 363916, 0, 2) -- Obsidian Scales
	end,
	[87585] = function(info) -- Class: Clobbering Sweep
		addMod(info.guid, 368970, 45) -- Tail Swipe
	end,
	[87586] = function(info) -- Class: Heavy Wingbeats
		addMod(info.guid, 357214, 45) -- Wing Buffet
	end,
	[87686] = function(info) -- Class: Aerial Mastery
		addMod(info.guid, 358267, 0, 2) -- Hover
	end,
	[87680] = function(info) -- Class: Fire Within
		addMod(info.guid, 374348, 30) -- Renewing Blaze
	end,
	[87667] = function(info) -- Devatation: Imposing Presence
		addMod(info.guid, 351338, 20) -- Quell
	end,
	[87654] = function(info) -- Devatation: Onyx Legacy
		addMod(info.guid, 357210, 60) -- Deep Breath
	end,
	[87601] = function(info) -- Preservation: Just in Time
		-- Cooldown is reduced by 2s each time you
		-- cast an Essence ability.
		if info.guid == playerGUID then
			syncSpells[357170] = true -- Time Dilation
		end
	end,
	[87619] = function(info) -- Preservation: Temporal Artificer
		addMod(info.guid, 363534, 60) -- Rewind
	end,

	-- Hunter
	[100636] = function(info, rank) -- Class: Improved Traps
		local cdMod = rank * 2.5
		addMod(info.guid, 187650, cdMod) -- Freezing Trap
		addMod(info.guid, 187698, cdMod) -- Tar Trap
		addMod(info.guid, 162488, cdMod) -- Steel Trap
		addMod(info.guid, 236776, cdMod) -- High Explosive Trap
	end,
	[100522] = function(info) -- Class: Lone Survivor
		addMod(info.guid, 264735, 30)   -- Survival of the Fittest
	end,
	[100638] = function(info) -- Class: Natural Mending
		-- Focus you spend reduces the remaining
		-- cooldown on Exhilaration by 1 sec.
		if info.guid == playerGUID then
			syncSpells[109304] = true -- Exhilaration
		end
	end,
	[100646] = function(info, rank) -- Class: Born To Be Wild
		local cdMod = rank * 18
		addMod(info.guid, 186257, cdMod) -- Aspect of the Cheetah
		addMod(info.guid, 186265, cdMod) -- Aspect of the Turtle
		addMod(info.guid, 264735, cdMod) -- Survival of the Fittest
		if info.spec == 255 then -- Survival
			addMod(info.guid, 186289, rank * 9) -- Aspect of the Eagle
		end
	end,
	[100609] = function(info) -- Marksmanship: Calling the Shots
		-- Every 50 Focus spent reduces the cooldown
		-- of Trueshot by 2.5 sec.
		if info.guid == playerGUID then
			syncSpells[288613] = true -- Trueshot
		end
	end,
	[100563] = function(info, rank) -- Survival: Explosives Expert
		addMod(info.guid, 259495, rank) -- Wildfire Bomb
	end,
	[100572] = function(info) -- Survival: Guerrilla Tactics
		addMod(info.guid, 259495, 0, 2) -- Wildfire Bomb
	end,

	-- Mage
	[80182] = function(info) -- Class: Winter's Protection
		addMod(info.guid, 45438, 20) -- Ice Block
	end,
	[80159] = function(info) -- Class: Master of Time
		addMod(info.guid, 342245, 10) -- Alter Time
	end,
	[80145] = function(info) -- Class: Volatile Detonation
		addMod(info.guid, 157981, 5) -- Blast Wave
	end,
	[80153] = function(info, rank) -- Class: Flow of Time
		if info.talents[80163] then
			addMod(info.guid, 212653, rank) -- Shimmer
		else
			addMod(info.guid, 157981, rank) -- Blink
		end
	end,
	[80142] = function(info) -- Class: Ice Ward
		addMod(info.guid, 122, 0, 2) -- Frost Nova
	end,
	[80217] = function(info) -- Frost: Icy Propulsion
		-- Cooldown is reduced by 1s each time your
		-- single target spells crit.
		if info.guid == playerGUID then
			syncSpells[12472] = true -- Icy Veins
		end
	end,

	-- Monk
	[101531] = function(info) -- Class: Improved Roll
		addMod(info.guid, 109132, 0, info.talents[101503] and 3 or 2) -- Roll
		addMod(info.guid, 115008, 0, 2) -- Chi Torpedo
	end,
	[101414] = function(info, rank) -- Class: Tiger Tail Sweep
		addMod(info.guid, 119381, rank * 5) -- Leg Sweep
	end,
	[101505] = function(info) -- Class: Improved Paralysis
		addMod(info.guid, 119381, 15) -- Paralysis
	end,
	[101503] = function(info) -- Class: Celerity
		addMod(info.guid, 109132, 5, info.talents[101531] and 3 or 2) -- Roll
	end,
	[101497] = function(info) -- Class: Expeditious Fortification
		addMod(info.guid, 115203, 120) -- Fortifying Brew
	end,
	[101521] = function(info) -- Class: Fatal Touch
		addMod(info.guid, 115080, 45) -- Touch of Death
	end,
	[101471] = function(info) -- Brewmaster: Improved Purifying Brew
		addMod(info.guid, 119582, 0, 2) -- Purifying Brew
	end,
	[101439] = function(info) -- Brewmaster: Fundamental Observation
		addMod(info.guid, 115176, 75) -- Zen Meditation
	end,
	[101448] = function(info) -- Brewmaster: Light Brewing
		addMod(info.guid, 119582, 4) -- Purifying Brew
		addMod(info.guid, 322507, 12) -- Celestial Brew
	end,
	[101442] = function(info) -- Brewmaster: Face Palm
		-- Tiger Palm has a 50% chance to reduce the remaining cooldown
		--  of your Brews by 1 sec.
		if info.guid == playerGUID then
			syncSpells[115203] = true -- Fortifying Brew
			syncSpells[119582] = true -- Purifying Brew
			syncSpells[322507] = true -- Celestial Brew
			syncSpells[115399] = true -- Black Ox Brew
		end
	end,
	[101446] = function(info) -- Brewmaster: Anvil & Stave
		-- Each time you dodge or an enemy misses you, the remaining
		-- cooldown on your Brews is reduced by 0.5 sec. This effect
		-- can only occur once every 3 sec.
		if info.guid == playerGUID then
			syncSpells[115203] = true -- Fortifying Brew
			syncSpells[119582] = true -- Purifying Brew
			syncSpells[322507] = true -- Celestial Brew
			syncSpells[115399] = true -- Black Ox Brew
		end
	end,
	[101431] = function(info) -- Windwalker: Meridian Strikes
		-- Each time you Combo Strike, the cooldown of
		-- Touch of Death is reduced by 0.35 sec.
		if info.guid == playerGUID then
			syncSpells[115080] = true -- Touch of Death
		end
	end,
	[101481] = function(info) -- Mistweaver: Xuen's Bond
		-- Abilities that activate Combo Strikes reduce the cooldown
		-- of Inboke Xuen by 0.1 sec.
		if info.guid == playerGUID then
			syncSpells[123904] = true -- Invoke Xuen, the White Tiger
		end
	end,
	[114297] = function(info) -- Mistweaver: Burst of Life
		addMod(info.guid, 116849, 20) -- Life Cocoon
	end,
	[101381] = function(info) -- Mistweaver: Gift of the Celestials
		addMod(info.guid, 322118, 120) -- Invoke Yu'lon, the Jade Serpent
	end,

	-- Paladin
	[102592] = function(info) -- Class: Cavalier
		addMod(info.guid, 190784, 0, 2) -- Divine Steed
	end,
	[102593] = function(info) -- Class: Avenging Wrath
		addMod(info.guid, 190784, 0, 2) -- Divine Steed
	end,
	[102595] = function(info) -- Class: Sacrifice of the Just
		addMod(info.guid, 6940, 60) -- Blessing of Sacrifice
	end,
	[102603] = function(info) -- Class: Unbreakable Spirit (-30%)
		addMod(info.guid, 642, 90) -- Divine Shield
		if info.spec == 65 then -- Holy
			addMod(info.guid, 498, 18) -- Divine Protection
		elseif info.spec == 70 then -- Retribution
			addMod(info.guid, 184662, 18) -- Shield of Vengeance
			addMod(info.guid, 498, 27) -- Divine Protection
		end
		addMod(info.guid, 633, 180) -- Lay on Hands
	end,
	[102606] = function(info) -- Class: Improved Blessing of Protection
		addMod(info.guid, 1022, 60) -- Blessing of Protection
	end,
	[115467] = function(info) -- Class: Quickened Evocation
		addMod(info.guid, 375576, 15) -- Divine Toll
	end,
	[102547] = function(info) -- Holy: Unwavering Spirit
		addMod(info.guid, 31821, 30) -- Aura Mastery
	end,

	-- Priest
	[103845] = function(info) -- Class: Psychic Voice
		addMod(info.guid, 8122, 15) -- Psychic Scream
	end,
	[103852] = function(info) -- Class: Move with Grace
		addMod(info.guid, 73325, 30) -- Leap of Faith
	end,
	[103840] = function(info) -- Class: San'layn
		addMod(info.guid, 15286, 30) -- Vampiric Embrace
	end,
	[103825] = function(info) -- Class: Angel's Mercy
		addMod(info.guid, 19236, 30) -- Desperate Prayer
	end,
	[103836] = function(info, rank) -- Class: Improved Fade
		addMod(info.guid, 586, rank * 5) -- Fade
	end,
	[103721] = function(info) -- Discipline: Light's Promise
		addMod(info.guid, 194509, 0, 2) -- Power Word: Radiance
	end,
	[103714] = function(info) -- Discipline: Protector of the Fall
		addMod(info.guid, 33206, 0, 2) -- Pain Suppression
	end,
	[103720] = function(info) -- Discipline: Bright Pupil
		addMod(info.guid, 194509, 5)  -- Power Word: Radiance
	end,
	[103794] = function(info) -- Shadow: Last Word
		addMod(info.guid, 15487, 15)  -- Silence
	end,
	[103801] = function(info) -- Shadow: Intangibility
		addMod(info.guid, 47585, 30) -- Dispersion
	end,
	[103797] = function(info) -- Shadow: Malediction
		addMod(info.guid, 341374, 15) -- Damnation
		addMod(info.guid, 263165, 15) -- Void Torrent
	end,

	-- Rogue
	[117740] = function(info) -- Class: Airborne Irritant
		addMod(info.guid, 2094, 60) -- Blind
	end,
	[112617] = function(info) -- Class: Shadowstep
		if info.spec == 259 or info.spec == 261 then -- Baseline for Assasination and Subtlety
			addMod(info.guid, 36554, 0, 2) -- Shadowstep
		end
	end,
	[112636] = function(info) -- Class: Improved Sprint
		addMod(info.guid, 2983, 60) -- Sprint
	end,
	[117145] = function(info) -- Class: Graceful Guile
		addMod(info.guid, 1966, 0, 2) -- Feint
	end,
	[117144] = function(info) -- Class: Stillshroud
		addMod(info.guid, 114018, 180) -- Shroud of Concealment
	end,
	[112569] = function(info) -- Outlaw: Retractable Hook
		addMod(info.guid, 195457, 15) -- Grappling Hook
	end,
	[112529] = function(info) -- Outlaw: Blinding Powder
		addMod(info.guid, 2094, 30) -- Blind
	end,
	[112536] = function(info) -- Outlaw: Float like a Butterfly
		-- Restless Blades affects addition skills
		if info.guid == playerGUID then
			syncSpells[5277] = true -- Evasion
			syncSpells[1966] = true -- Feint
		end
	end,
	[112616] = function(info) -- Subtlety: Quick Decisions
		addMod(info.guid, 36554, 6) -- Shadowstep
	end,
	[112589] = function(info) -- Subtlety: Swift Death
		addMod(info.guid, 212283, 5) -- Symbols of Death
	end,
	[112612] = function(info) -- Subtlety: Deepening Shadows
		if info.guid == playerGUID then
			syncSpells[185313] = true -- Shadow Dance
		end
	end,
	[112590] = function(info) -- Subtlety: Without a Trace
		addMod(info.guid, 1856, 0, 2) -- Vanish
	end,

	-- Shaman
	[101944] = function(info) -- Class: Planes Traveler
		addMod(info.guid, 108271, 30) -- Astral Shift
	end,
	[101979] = function(info) -- Class: Brimming with Life
		-- Reincarnation cools down faster while at full health
		if info.guid == playerGUID then
			syncSpells[21169] = true -- Reincarnation
		end
	end,
	[101971] = function(info) -- Class: Voodoo Mastery
		addMod(info.guid, 51514, 15) -- Hex
	end,
	[101954] = function(info) -- Class: Graceful Spirit
		addMod(info.guid, 79206, 30) -- Spiritwalker's Grace
	end,
	[102002] = function(info) -- Class: Totemic Surge
		-- all totem abilities -3s
		--[[
		addMod(info.guid, 0000, 3)

		[2484] = {30, 5}, -- Earthbind Totem
		[192058] = {60, 1, nil, 101961}, -- Capacitor Totem
		[5394] = {30, 1, nil, 101998}, -- Healing Stream Totem
		[8143] = {60, 1, nil, 101958}, -- Tremor Totem
		[51485] = {30, 1, nil, 101975}, -- Earthgrab Totem
		[192077] = {120, 1, nil, 101976}, -- Wind Rush Totem
		[383013] = {45, 1, nil, 101989}, -- Poison Cleansing Totem
		[383019] = {60, 1, nil, 101991}, -- Tranquil Air Totem
		[383017] = {30, 1, nil, 101992}, -- Stoneskin Totem
		--]]
	end,
	[101984] = function(info) -- Class: Go with the Flow
		addMod(info.guid, 58875, 10) -- Spirit Walk
		addMod(info.guid, 192063, 5) -- Gust of Wind
	end,
	[101994] = function(info) -- Class: Thunderstruck
		addMod(info.guid, 51490, 5) -- Spirit Walk
	end,
	[101986] = function(info) -- Class: Call of the Elements
		addMod(info.guid, 108285, 60) -- Totemic Recall
	end,
	[101876] = function(info, rank) -- Elemental: Oath of the Far Seer
		addMod(info.guid, 114049, rank * 30) -- Ascendance
	end,
	[101900] = function(info, rank) -- Restoration: Healing Stream Totem
		if info.talents[101998] then
			addMod(info.guid, 5394, 0, 2)
		end
	end,
	[114811] = function(info) -- Restoration: Current Control
		addMod(info.guid, 108280, 30) -- Healing Tide Totem
	end,

	-- Warlock
	[91440] = function(info) -- Class: Fel Pact
		addMod(info.guid, 333889, 30) -- Fel Domination
	end,
	[91443] = function(info) -- Class: Teachings of the Satyr
		addMod(info.guid, 327884, 15) -- Amplify Curse
	end,
	[91467] = function(info) -- Class: Dark Accord
		addMod(info.guid, 104773, 45) -- Unending Resolve
	end,
	[91445] = function(info) -- Class: Frequent Donor
		addMod(info.guid, 108416, 15) -- Dark Pact
	end,
	[91451] = function(info) -- Class: Darkfury
		addMod(info.guid, 30283, 15) -- Shadowfury
	end,
	[91421] = function(info) -- Class: Resolute Barrier
		-- damage that does atleast 5% max hp reduces the cd of UR by 10s once every 25s
		if info.guid == playerGUID then
			syncSpells[104773] = true -- Unending Resolve
		end
	end,
	[91428] = function(info, rank) -- Afflication: Soul-Eater's Gluttony
		addMod(info.guid, 386997, rank * 15) -- Soul Rot
	end,
	[91505] = function(info) -- Afflication: Grand Warlock's Design
		addMod(info.guid, 205180, 30) -- Summon Darkglare
	end,
	[91508] = function(info) -- Demonology: Grand Warlock's Design
		addMod(info.guid, 265187, 30) -- Summon Demonic Tyrant
	end,
	[91471] = function(info) -- Destruction: Grand Warlock's Design
		addMod(info.guid, 1122, 60) -- Summon Infernal
	end,

	-- Warrior
	[112191] = function(info) -- Class: Concussive Blows
		addMod(info.guid, 6552, 1) -- Pummel
	end,
	[112219] = function(info) -- Class: Bounding Stride
		addMod(info.guid, 52174, 15) -- Heroic Leap
	end,
	[112218] = function(info) -- Class: Honed Reflexes
		addMod(info.guid, 6552, 1) -- Pummel
	end,
	[112249] = function(info) -- Class: Double Time
		addMod(info.guid, 100, 3, 2) -- Charge
	end,
	[112221] = function(info) -- Class: Uproar
		addMod(info.guid, 384318, 30) -- Thunderous Roar
	end,
	[112315] = function(info) -- Arms: Valor in Victory
		addMod(info.guid, 118038, 30) -- Die By the Sword
	end,
	-- [112258] = function(info) -- Fury: Storm of Steel
	-- 	addMod(info.guid, 152277, 0, 2) -- Ravager
	-- end,
	[112115] = function(info) -- Protection: Bolster
		addMod(info.guid, 12975, 60) -- Last Stand
	end,
	[112165] = function(info) -- Protection: Defender's Aegis
		addMod(info.guid, 871, 30, 2) -- Shield Wall
	end,
	-- [112303] = function(info) -- Protection: Storm of Steel
	-- 	addMod(info.guid, 152277, 0, 2) -- Ravager
	-- end,
}

-- Specialization passive / spell ranks
data.levelCooldowns = {
	PALADIN = function(info)
		if info.spec == 70 then
			addMod(info.guid, 31884, 60) -- Avenging Wrath
			addMod(info.guid, 498, -30) -- Divine Protection
		end
	end,
	ROGUE = function(info)
		if info.spec == 260 and info.level >= 16 and info.guid == playerGUID then
			-- Restless Blades
			-- Finishing moves reduce the remaining cooldown
			-- of man Rogue skills by 1 sec per combo point
			-- spent.
			syncSpells[13750] = true -- Adrenaline Rush
			syncSpells[13877] = true -- Blade Flurry
			syncSpells[271877] = true -- Blade Rush
			syncSpells[196937] = true -- Ghostly Strike
			syncSpells[195457] = true -- Grappling Hook
			syncSpells[381989] = true -- Keep It Rolling
			syncSpells[51690] = true -- Killing Spree
			syncSpells[315508] = true -- Roll the Bones
			syncSpells[2983] = true -- Sprint
			syncSpells[1856] = true -- Vanish
		end
	end,
}

data.combatResSpells = {
	[20484] = true, -- Rebirth
	[95750] = true, -- Soulstone Resurrection
	[61999] = true, -- Raise Ally
	[391054] = true, -- Intercession
	-- Engineering
	[345130] = true, -- Disposable Spectrophasic Reanimator
	[385403] = true, -- Tinker: Arclight Vital Correctors
}

data.chargeSpells = {
	-- Death Knight
	[43265] = 1, -- Death and Decay
	[48265] = 1, -- Death's Advance
	[49576] = 1, -- Death Grip
	[194679] = 2, -- Rune Tap (Blood)
	[221699] = 2, -- Blood Tap (Blood)
	[47568] = 1, -- Empower Rune Weapon
	-- Demon Hunter
	[195072] = 2, -- Fel Rush (Havoc)
	[258920] = 1, -- Immolation Aura
	[189110] = 1, -- Infernal Strike (Vengeance)
	[204021] = 1, -- Fiery Brand (Vengeance)
	[202137] = 1, -- Sigil of Silence
	[204596] = 1, -- Sigil of Flame
	[207684] = 1, -- Sigil of Misery
	[202138] = 1, -- Sigil of Chains
	[390163] = 1, -- Elysian Decree
	-- Druid
	[61336] = 1, -- Survival Instincts
	[22842] = 1, -- Frenzied Regeneration
	[274281] = 3, -- New Moon
	-- Evoker
	[363916] = 1, -- Obsidian Scales
	[358267] = 1, -- Hover
	-- Hunter
	[259495] = 1, -- Wildfire Bomb
	-- Mage
	[122] = 1, -- Frost Nova
	[212653] = 2, -- Shimmer
	[108839] = 3, -- Ice Floes
	-- Monk
	[109132] = 1, -- Roll
	[115008] = 1, -- Chi Torpedo
	[119582] = 1, -- Purifying Brew
	[122281] = 2, -- Healing Elixir
	-- Paladin
	[190784] = 1, -- Divine Steed
	-- Priest
	[121536] = 3, -- Angelic Feather
	[194509] = 1, -- Power Word: Radiance
	[33206] = 1, -- Pain Suppression
	-- Rogue
	[1966] = 1, -- Feint
	[36554] = 1, -- Shadowstep
	[185313] = 1, -- Shadow Dance
	[1856] = 1, -- Vanish
	[385424] = 3, -- Serrated Bone Spike
	-- Shaman
	[5394] = 1, -- Healing Stream Totem
	-- Warrior
	[100] = 1, -- Charge
	-- [152277] = 1, -- Ravager
	[871] = 1, -- Shield Wall
}

-- { cd, level, spec id, talent entry id, sync, race }
-- level can be a hash of spec=level for talents in different locations
-- spec id can be a table of specs and is optional if level or talent are a table
-- talent entry id can be negative to indicate a talent replaces the spell
--   and can be a hash of spec=id for spec talents
-- sync will register SPELL_UPDATE_COOLDOWN and send "CooldownUpdate" syncs
--   with the cd (for dynamic cooldowns with hard to track conditions)
data.spells = {
	DEATHKNIGHT = {
		[43265] = {30, 3, nil, {[250]=false,[251]=false,[252]=-96315}}, -- Death and Decay
		[49576] = {25, 5}, -- Death Grip
		[48265] = {45, 9}, -- Death's Advance
		[49039] = {120, 9}, -- Lichborne
		[61999] = {600, 19}, -- Raise Ally

		[46584] = {120, 1, nil, 96201}, -- Raise Dead
		[47528] = {15, 1, nil, 96211}, -- Mind Freeze
		[48707] = {60, 1, nil, 96199}, -- Anti-Magic Shell
		[207167] = {60, 1, nil, 96172}, -- Blinding Sleet
		[327574] = {120, 1, nil, 96203}, -- Sacrificial Pact
		[48792] = {180, 1, nil, 96213}, -- Icebound Fortitude
		[51052] = {120, 1, nil, 96194}, -- Anti-Magic Zone
		[221562] = {45, 1, nil, 96193}, -- Asphyxiate
		[48743] = {120, 1, nil, 96206}, -- Death Pact
		[212552] = {60, 1, nil, 96207}, -- Wraith Walk
		[47568] = {120, 1, nil, {[250]=96178,[251]={96178,96229},[252]=96178}}, -- Empower Rune Weapon
		[383269] = {120, 1, nil, 96177}, -- Abomination Limb

		[55233] = {90, 1, 250, 96308}, -- Vampiric Blood
		[194679] = {25, 1, 250, 96278}, -- Rune Tap (2 charges)
		[49028] = {120, 1, 250, 96269}, -- Dancing Rune Weapon
		[274156] = {30, 1, 250, 96275}, -- Consumption
		[206931] = {30, 1, 250, 96276}, -- Blooddrinker
		[221699] = {60, 1, 250, 96274}, -- Blood Tap (2 charges)
		[219809] = {60, 1, 250, 96270}, -- Tombstone
		[108199] = {120, 1, 250, 96267}, -- Gorefiend's Grasp
		[194844] = {60, 1, 250, 96258}, -- Bonestorm

		[196770] = {20, 1, 251, 96242}, -- Remorseless Winder
		[51271] = {45, 1, 251, 96234}, -- Pillar of Frost
		[57330] = {45, 1, 251, 96240}, -- Horn of Winter
		[305392] = {45, 1, 251, 96228}, -- Chill Streak
		[279302] = {180, 1, 251, 96224}, -- Frostwyrm's Fury
		[152279] = {120, 1, 251, 96222}, -- Breath of Sindragosa

		[63560] = {60, 1, 252, 96324}, -- Dark Transformation
		[115989] = {45, 1, 252, 96296}, -- Unholy Blight
		[275699] = {90, 1, 252, 96322}, -- Apocalypse
		[152280] = {20, 1, 252, 96315}, -- Defile
		[390279] = {90, 1, 252, 96293}, -- Vile Contagion
		[42650] = {480, 1, 252, 96333}, -- Army of the Dead
		[49206] = {180, 1, 252, 96311}, -- Summon Gargoyle
		[207289] = {75, 1, 252, 96285}, -- Unholy Assault
	},
	DEMONHUNTER = {
		[195072] = {10, 1}, -- Fel Rush
		[189110] = {20, 1, 581}, -- Infernal Strike
		[188501] = {30, 1}, -- Spectral Sight
		[204596] = {30, 10}, -- Sigil of Flame
		[258920] = {30, 14}, -- Immolation Aura
		[198589] = {60, 18}, -- Blur
		[212800] = 198589,
		[183752] = {15, 20}, -- Disrupt
		[187827] = {180, 20}, -- Metamorphosis (Vengeance)
		[200166] = 187827, -- Metamorphosis (Havoc)
		[211881] = {30, 45, 577}, -- Fel Eruption (Havoc)

		[198793] = {25, 1, nil, 112853}, -- Vengeful Retreat
		[207684] = {120, 1, nil, 112589}, -- Sigil of Misery
		[217832] = {45, 1, nil, 112927}, -- Imprison
		[179057] = {45, 1, nil, 112911}, -- Chaos Nova
		[278326] = {10, 1, nil, 112926}, -- Consume Magic
		[196718] = {300, 1, nil, 112921}, -- Darkness
		[370965] = {90, 1, nil, 112837}, -- The Hunt
		[390163] = {60, 1, nil, 117755}, -- Elysian Decree

		[196555] = {180, 1, 577, 115247}, -- Netherwalk
		[342817] = {25, 1, 577, 117763}, -- Glaive Tempest
		[258860] = {40, 1, 577, 112956}, -- Essence Break
		[258925] = {90, 1, 577, 117742}, -- Fel Barrage

		[212084] = {40, 1, 581, 112908}, -- Fel Devastation
		[204021] = {60, 1, 581, 112864}, -- Fiery Brand
		[202137] = {60, 1, 581, 112904}, -- Sigil of Silence
		[320341] = {60, 1, 581, 112869}, -- Bulk Extraction
		[263648] = {30, 1, 581, 112870}, -- Soul Barrier
		[202138] = {60, 1, 581, 112867}, -- Sigil of Chains
		[214743] = {60, 1, 581, 112898}, -- Soul Carver
	},
	DRUID = {
		[1850] = {120, 6}, -- Dash
		[22812] = {60, 10}, -- Barkskin
		[20484] = {600, 19}, -- Rebirth
		[391528] = {120, 1, nil, {[102]=109838,[103]=103177,[104]=103200,[105]=103119}}, -- Convoke the Spirits

		[22842] = {36, 1, nil, 103298}, -- Frenzied Regeneration
		[252216] = {45, 1, nil, 103275}, -- Tiger Dash
		[132302] = {15, 1, nil, 103276}, -- Wild Charge
		[102401] = 132302, -- Wild Charge (Caster)
		[16979]  = 132302, -- Wild Charge (Bear)
		[49376]  = 132302, -- Wild Charge (Cat)
		[102383] = 132302, -- Wild Charge (Moonkin)
		[102416] = 132302, -- Wild Charge (Aquatic)
		[102417] = 132302, -- Wild Charge (Travel)
		[106839] = {15, 1, nil, 103302}, -- Skull Bash
		[2908] = {10, 1, nil, 103307}, -- Soothe
		[132469] = {30, 1, nil, 103287}, -- Typhoon
		[61391] = 132469, -- Typhoon (actual event)
		[106898] = {120, 1, nil, 103312}, -- Stampeding Roar
		-- [77761] = 106898, -- Stampeding Roar (Guardian, 60s)
		-- [77764] = 106898, -- Stampeding Roar (Feral, 120s)
		[99] = {30, 1, nil, 103316}, -- Incapacitating Roar
		[5211] = {50, 1, nil, 103315}, -- Mighty Bash
		[102359] = {30, 1, nil, 103322}, -- Mass Entanglement
		[102793] = {60, 1, nil, 103321}, -- Ursol's Vortex
		[108238] = {90, 1, nil, 103310}, -- Renewel
		[29166] = {180, 1, nil, 103323}, -- Innervate
		[319454] = {300, 1, nil, 103309}, -- Heart of the Wild
		[124974] = {90, 1, nil, 103324}, -- Nature's Vigil

		[78675] = {60, 1, 102, 109867}, -- Solar Beam
		[205636] = {60, 1, 102, 109844}, -- Force of Nature
		[202425] = {45, 1, 102, 114648}, -- Warrior of Elune
		[194223] = {180, 1, 102, 109849}, -- Celestial Alignment
		[202359] = {60, 1, 102, 109871}, -- Astral Communion
		[102560] = {180, 1, 102, 109839}, -- Incarnation: Chosen of Elune
		[202770] = {60, 1, 102, 109859}, -- Fury of Elune
		[274281] = {20, 1, 102, 109860}, -- New Moon (3 charges)

		[5217] = {30, 1, 103, 103188}, -- Tiger's Fury
		[61336] = {180, 1, nil, {[103]=103180,[104]=103193}}, -- Survival Instincts
		[106951] = {180, 1, nil, {[103]={103162,-103178}}}, -- Berserk
		[391888] = {25, 1, nil, {[103]=103175,[105]=103123}}, -- Adaptive Swarm
		[102543] = {180, 1, 103, 103178}, -- Incarnation: Avatar of Ashamane
		[274837] = {45, 1, 103, 103170}, -- Feral Frenzy

		[155835] = {40, 1, 104, 103230},  -- Bristling Fur
		-- [50334] = {180, 1, 104, 103216}, -- Berserk: Ravage -- XXX does this use the base berserk id?
		[80313] = {45, 1, 104, 103222}, -- Pulverize
		[102558] = {180, 1, 104, 103201}, -- Incarnation: Guardian of Ursoc
		[200851] = {60, 1, 104, 103207}, -- Rage of the Sleeper
		[204066] = {60, 1, 104, 114700}, -- Lunar Beam

		[132158] = {60, 1, 105, 103101}, -- Nature's Swiftness
		[102351] = {30, 1, 105, 103104}, -- Cenarion Ward
		[740] = {180, 1, 105, 103108}, -- Tranquility
		[102342] = {90, 1, 105, 103141}, -- Ironbark
		[203651] = {60, 1, 105, 103115}, -- Overgrowth
		[33891]  = {180, 1, 105, 103120}, -- Incarnation: Tree of Life
		[197721] = {60, 1, 105, 103136}, -- Flourish
		[392160] = {20, 1, 105, 103133}, -- Invigorate
	},
	EVOKER = {
		[357210] = {120, 1}, -- Deep Breath
		[358267] = {35, 1}, -- Hover
		[390386] = {300, 60}, -- Fury of the Aspects

		[358385] = {90, 1, nil, 87708}, -- Landslide
		[363916] = {90, 1, nil, 87702}, -- Obsidian Scales
		[360995] = {24, 1, nil, 87715}, -- Verdant Embrace
		[351338] = {40, 1, nil, 87692}, -- Quell
		[374251] = {60, 1, nil, 87700}, -- Cauterizing Flame
		[370553] = {120, 1, nil, 87713}, -- Tip the Scales
		[360806] = {15, 1, nil, 87587}, -- Sleep Walk
		[372048] = {120, 1, nil, 87695}, -- Oppressing Roar
		[370665] = {60, 1, nil, 87685}, -- Rescue
		[374348] = {90, 1, nil, 87679}, -- Renewing Blaze
		[374968] = {120, 1, nil, 87676}, -- Time Spiral
		[374227] = {120, 1, nil, 87682}, -- Zephyr

		[375087] = {120, 1, nil, 87665}, -- Dragonrage

		[363534] = {240, 1, nil, 87612}, -- Rewind
		[357170] = {60, 1, nil, 87613}, -- Time Dilation
		[370960] = {180, 1, nil, 87594}, -- Emerald Communion
		[359816] = {120, 1, nil, 87597}, -- Dream Flight
		[370537] = {90, 1, nil, 87603}, -- Stasis
	},
	HUNTER = {
		[781] = {20, 4}, -- Disengage
		[186257] = {180, 5}, -- Aspect of the Cheetah
		[136] = {10, 5}, -- Mend Pet
		[5384] = {30, 6}, -- Feign Death
		[186265] = {180, 8}, -- Aspect of the Turtle
		[109304] = {120, 9}, -- Exhilaration
		[187650] = {30, 10}, -- Freezing Trap
		[1543] = {20, 19}, -- Flare
		[19574] = {90, 20, 253}, -- Bestial Wrath
		-- Command Pet XXX Not sure how do deal with these for available cds
		[53271] = {45, 28}, -- Master's Call (Cunning)
		[272682] = 53271, -- Command Pet
		[388035] = {120, 1}, -- Fortitude of the Bear (Tenacity)
		[272679] = 388035, -- Command Pet
		[264667] = {360, 48}, -- Primal Rage (Ferocity)
		[272678] = 264667, -- Command Pet

		[187707] = {15, 1, 255, 100543}, -- Muzzle
		[147362] = {24, 1, {253,254}, 100624}, -- Counter Shot
		[187698] = {30, 1, nil, 100641}, -- Tar Trap
		[34477] = {30, 1, nil, 100637}, -- Misdirection
		[264735] = {180, 1, nil, 100523}, -- Survival of the Fittest
		[19801] = {10, 1, nil, 100617}, -- Tranquilizing Shot
		[236776] = {40, 1, nil, 100620}, -- High Explosive Trap
		[19577] = {60, 1, nil, 100621}, -- Intimidation
		[109248] = {45, 1, nil, 100650}, -- Binding Shot
		[213691] = {30, 1, nil, 100651}, -- Scatter Shot
		[199483] = {60, 1, nil, 100647}, -- Camouflage
		[162488] = {25, 1, nil, 100618}, -- Steel Trap
		[375891] = {45, 1, nil, 100628}, -- Death Chakram
		[201430] = {120, 1, nil, 100629}, -- Stampede
		[212431] = {30, 1, nil, 100626}, -- Explosive Shot
		[120360] = {20, 1, nil, 100526}, -- Barrage

		[131894] = {60, 1, 253, 100657, true}, -- A Murder of Crows
		[321530] = {60, 1, 253, 100525}, -- Bloodshed
		[392060] = {60, 1, nil, {[253]=100652,[254]=100590}}, -- Wailing Arrow
		[359844] = {120, 1, 235, 100682}, -- Call of the Wild

		[186387] = {30, 1, 254, 100577}, -- Bursting Shot
		[260243] = {45, 1, 254, 100595}, -- Volley
		[288613] = {120, 1, 254, 100587}, -- Trueshot
		[400456] = {45, 1, 254, 100534}, -- Salvo

		[259495] = {18, 1, 255, 100568}, -- Wildfire Bomb
		[270335] = 259495, -- Shrapnel Bomb (Wildfire Infusion)
		[270323] = 259495, -- Pheromone Bomb (Wildfire Infusion)
		[271045] = 259495, -- Volatile Bomb (Wildfire Infusion)
		[190925] = {30, 1, 255, 100546}, -- Harpoon
		[186289] = {90, 1, 255, 100562}, -- Aspect of the Eagle
		[269751] = {40, 1, 255, 100545}, -- Flanking Strike
		[266779] = {120, 1, 255, 100570}, -- Coordinated Assault
		-- [203415] = {45, 1, 255, 100557, true}, -- Fury of the Eagle (random resets)
		[360966] = {90, 1, 255, 100571}, -- Spearhead
	},
	MAGE = {
		[122] = {30, 3}, -- Frost Nova
		[1953] = {15, 4, nil, -80163}, -- Blink
		[2139] = {24, 7}, -- Counterspell
		[120] = {12, 18}, -- Cone of Cold
		[80353] = {300, 49}, -- Time Warp

		[235450] = {25, 1, 62, 80180}, -- Prismatic Barrier
		[235313] = {25, 1, 63, 80178}, -- Blazing Barrier
		[11426] = {25, 1, 64, 80176}, -- Ice Barrier
		[45438] = {240, 1, nil, 80181}, -- Ice Block
		[66] = {300, 1, nil, 80177}, -- Invisibility
		[55342] = {120, 1, nil, 80183}, -- Mirror Image
		[116011] = {45, 1, nil, 80171}, -- Rune of Power
		[342245] = {60, 1, nil, 80174}, -- Alter Time
		[383121] = {60, 1, nil, 80164}, -- Mass Polymorph
		[113724] = {45, 1, nil, 80144}, -- Ring of Frost
		[157997] = {25, 1, nil, 80186}, -- Ice Nova
		[108839] = {20, 1, nil, 80162}, -- Ice Floes (3 charges)
		[212653] = {25, 1, nil, 80163}, -- Shimmer (2 charges)
		[157981] = {30, 1, nil, 80160}, -- Blast Wave
		[110959] = {120, 1, nil, 80152}, -- Greater Invisibility
		[31661] = {45, 1, nil, 80147}, -- Dragon's Breath
		[382440] = {60, 1, nil, 80141}, -- Shifting Power -- XXX ...
		[389713] = {45, 1, nil, 80148}, -- Displacement
		[153561] = {45, 1, nil, 80145}, -- Meteor

		[153626] = {20, 1, 62, 80308}, -- Arcane Orb
		[365350] = {90, 1, 62, 80299}, -- Arcane Surge
		[205022] = {10, 1, 62, 80207}, -- Arcane Familiar
		[205025] = {45, 1, 62, 80208}, -- Presence of Mind
		[321507] = {45, 1, 62, 80302}, -- Touch of the Magi
		[157980] = {25, 1, 62, 80290}, -- Supernova
		[12051] = {90, 1, 62, 80209}, -- Evocation
		[376103] = {30, 1, 62, 80304}, -- Radiant Spark

		[190319] = {120, 1, 63, 80275}, -- Combustion
		[44457]  = {12, 1, 63, 80260}, -- Living Bomb

		[84714] = {60, 1, 64, 80242}, -- Frozen Orb
		[235219] = {300, 1, 64, 80239}, -- Cold Snap
		[31687] = {30, 1, 64, 80237}, -- Summon Water Elemental
		[33395] = {25, 23, 64, 80237}, -- Freeze (Water Elemental)
		[257537] = {45, 1, 64, 80245}, -- Ebonbolt
		[12472] = {180, 1, 64, 80235}, -- Icy Veins
		[153595] = {30, 1, 64, 80249}, -- Comet Storm
		[205021] = {75, 1, 64, 80226}, -- Ray of Frost
	},
	MONK = {
		[109132] = {20, 3, nil, -101502}, -- Roll
		[119381] = {60, 6}, -- Leg Sweep
		[115080] = {180, 10}, -- Touch of Death
		[169340] = {90, 17}, -- Touch of Fatality

		[116841] = {30, 1, nil, 101507}, -- Tiger's Lust
		[115078] = {45, 1, nil, 101506}, -- Paralysis
		[116705] = {15, 1, nil, 101504}, -- Spear Hand Strike
		[115203] = {360, 1, nil, 101496}, -- Fortifying Brew (Brewmaster)
		[243435] = 115203, -- Fortifying Brew (Windwalker, Mistweaver)
		[116844] = {45, 1, nil, 101516}, -- Ring of Peace
		[115008] = {20, 1, nil, 101502}, -- Chi Torpedo
		[122783] = {90, 1, nil, 101515}, -- Diffuse Magic
		[122278] = {120, 1, nil, 101522}, -- Dampen Harm
		[115313] = {10, 1, nil, 101532}, -- Summon Jade Serpent Statue
		[388686] = {120, 1, nil, 101519}, -- SUmmon White Tiger Statue
		[115315] = {10, 1, nil, 101535}, -- Summon Black Ox Statue

		[119582] = {20, 1, 268, 101453}, -- Purifying Brew
		[322507] = {60, 1, 268, 101463}, -- Celestial Brew
		[115176] = {300, 1, 268, 101547}, -- Zen Meditation
		[324312] = {30, 1, 268, 101440}, -- Clash
		[115181] = {15, 1, 268, 101464}, -- Breath of Fire
		[115399] = {120, 1, 268, 101450}, -- Black Ox Brew
		[132578] = {180, 1, 268, 101544}, -- Invoke Niuzao, the Black Ox
		[386276] = {60, 1, nil, {[268]=101552,[269]=101485}}, -- Bonedust Brew
		[325153] = {60, 1, 268, 101542}, -- Exploding Keg
		[387184] = {120, 1, 268, 101539}, -- Weapons of Order

		[122470] = {90, 1, 269, 101420}, -- Touch of Karma
		[101545] = {25, 1, 269, 101432}, -- Flying Serpent Kick
		-- [152173] = {90, 1, 269, 101428}, -- Serenity
		[392983] = {40, 1, 269, 101491}, -- Strike of the Windlord
		[123904] = {120, 1, 269, 101473}, -- Invoke Xuen, the White Tiger

		[116849] = {120, 1, 270, 101390}, -- Life Cocoon
		[116680] = {30, 1, 270, 101410}, -- Thunder Focus Tea
		[115310] = {180, 1, 270, 101378}, -- Revival
		[388615] = {180, 1, 270, 101377}, -- Restoral
		[198898] = {30, 1, 270, 101360}, -- Song of Chi-Ji
		[325197] = {180, 1, 270, 101396}, -- Invoke Chi-Ji, the Red Crane
		[322118] = {180, 1, 270, 101397}, -- Invoke Yu'lon, the Jade Serpent
		[197908] = {90, 1, 270, 101379}, -- Mana Tea
	},
	PALADIN = {
		[853] = {60, 5}, -- Hammer of Justice
		[642] = {300, 10}, -- Divine Shield
		[391054] = {600, 19}, -- Intercession
		[498] = {60, 26, {65,70}}, -- Divine Protection

		[633] = {600, 1, nil, 102583}, -- Lay on Hands
		[1044] = {25, 1, nil, 102587}, -- Blessing of Freedom
		[10326] = {15, 1, nil, 102623}, -- Turn Evil
		[190784] = {45, 1, nil, 102625}, -- Divine Steed
		[20066] = {15, 1, nil, 102582}, -- Repentance
		[115750] = {90, 1, nil, 102584}, -- Blinding Light
		[96231] = {15, 1, nil, 102591}, -- Rebuke
		[31884] = {120, 1, nil, 102593}, -- Avenging Wrath
		[231895] = 31884, -- Avenging Wrath: Might / Sanctified Wrath / Crusade
		[6940] = {120, 1, nil, 102602}, -- Blessing of Sacrifice
		[1022] = {300, 1, nil, 102604}, -- Blessing of Protection
		[375576] = {60, 1, nil, 102465}, -- Divine Toll

		[31821] = {180, 1, 65, 102548}, -- Aura Mastery
		[210294] = {30, 1, 65, 102551}, -- Divine Favor
		[414273] = {90, 1, 65, 115876}, -- Hand of Divinity
		[114158] = {60, 1, 65, 102561}, -- Light's Hammer
		[114165] = {20, 1, 65, 102560}, -- Holy Prism
		[216331] = {60, 1, 65, 102568}, -- Avenging Crusader
		[148039] = {30, 1, 65, 115882}, -- Barrier of Faith
		[414170] = {60, 1, 65, 102563}, -- Daybreak
		[388007] = {45, 1, 65, 116183}, -- Blessing of Summer
		[200652] = {90, 1, 65, 102573}, -- Tyr's Deliverance

		[31850] = {120, 1, 66, 102445}, -- Ardent Defender
		[204018] = {300, 1, 66, 11886}, -- Blessing of Spellwarding
		[389539] = {120, 1, 66, 102447}, -- Sentinel
		[378974] = {120, 1, 66, 102454}, -- Bastion of Light
		[86659] = {300, 1, 66, 102456}, -- Guardian of Ancient Kings
		[387174] = {45, 1, 66, 102466}, -- Eye of Tyr
		[327193] = {90, 1, 66, 102474}, -- Moment of Glory

		[184662] = {60, 1, 70, 102519}, -- Shield of Vengeance
		[343721] = {60, 1, 70, 102513}, -- Final Reckoning
		[343527] = {60, 1, 70, 115435}, -- Execution Sentence
		[255937] = {30, 1, 70, 115043}, -- Wake of Ashes
	},
	PRIEST = {
		[8122] = {60, 7}, -- Psychic Scream
		[19236] = {90, 8}, -- Desperate Prayer
		[586] = {30, 9}, -- Fade

		[34433] = {180, 1, nil, {[256]={103865,-103710},[257]=103865,[258]={103865,-103788}}}, -- Shadowfiend
		[121536] = {20, 1, nil, 103853}, -- Angelic Feather
		[73325] = {90, 1, nil, 103868}, -- Leap of Faith
		[108920] = {60, 1, nil, 103859}, -- Void Tendrils
		[205364] = {30, 1, nil, 103678}, -- Dominate Mind
		[32375] = {120, 1, nil, 103849}, -- Mass Dispel
		[10060] = {120, 1, nil, 103844}, -- Power Infusion
		[15286] = {120, 1, nil, 114735}, -- Vampiric Embrace
		[120517] = {40, 1, nil, 103827}, -- Halo
		[122121] = {15, 1, nil, 103828}, -- Divine Star
		[375901] = {45, 1, nil, 103837}, -- Mindgames
		[373481] = {15, 1, nil, 103822}, -- Power Word: Life
		[108968] = {300, 1, nil, 103820}, -- Void Shift

		[194509] = {20, 1, 256, 103722}, -- Power Word: Radiance
		[33206] = {180, 1, 256, 103713}, -- Pain Suppression
		[62618] = {180, 1, 256, 103687}, -- Power Word: Barrier
		[271466] = {180, 1, 256, 116182}, -- Luminous Barrier
		[47536] = {90, 1, 256, 103727}, -- Rapture
		[421453] = {240, 1, 256, 103700}, -- Ultimate Penitence
		[472433] = {90, 1, 256, 103691}, -- Evangelism
		[123040] = {60, 1, nil, {[256]=103710,[258]=103788}}, -- Mindbender
		[200174] = 123040, -- Mindbender (Shadow)

		[2050] = {60, 1, 257, 103775}, -- Holy Word: Serenity
		[34861] = {60, 1, 257, 103766}, -- Holy Word: Sanctify
		[47788] = {180, 1, 257, 103774}, -- Guardian Spirit
		[88625] = {60, 1, 257, 103776}, -- Holy Word: Chastise
		[372616] = {60, 1, 257, 103777}, -- Empyreal Blaze
		[64843] = {180, 1, 257, 103755}, -- Divine Hymn
		[64901] = {180, 1, 257, 103751}, -- Symbol of Hope
		[265202] = {720, 1, 257, 103742}, -- Holy Word: Salvation
		[200183] = {120, 1, 257, 103743}, -- Apotheosis
		[372835] = {120, 1, 257, 103733}, -- Lightwell
		[372760] = {60, 1, 257, 103675}, -- Divine Word

		[47585] = {120, 1, 258, 103806}, -- Dispersion
		[15487] = {45, 1, 258, 103792}, -- Silence
		[64044] = {45, 1, 258, 103793}, -- Psychic Horror
		[263346] = {30, 1, 258, 103790}, -- Dark Void
		[391109] = {60, 1, 258, 103680}, -- Dark Ascension
		[228260] = {120, 1, 258, 103674}, -- Void Eruption
		[205385] = {30, 1, 258, 103803}, -- Shadow Crash
		[341374] = {60, 1, 258, 103796}, -- Damnation
		[263165] = {60, 1, 258, 103679}, -- Void Torrent
	},
	ROGUE = {
		[2983] = {120, 5}, -- Sprint
		[1766] = {15, 6}, -- Kick
		[185311] = {30, 8}, -- Crimson Vial
		[1966] = {15, 12}, -- Feint
		[408] = {20, 13}, -- Kidney Shot
		[13877] = {30, 13, 260}, -- Blade Flurry
		[195457] = {45, 16, 260}, -- Grappling Hook
		[315508] = {45, 19, 260}, -- Roll the Bones
		[1856] = {120, 23}, -- Vanish
		[1725] = {30, 28}, -- Distract
		[212283] = {30, 29, 261}, -- Symbols of Death
		[114018] = {360, 49}, -- Shroud of Concealment

		[5938] = {30, 1, nil, 112630}, -- Shiv
		[2094] = {120, 1, nil, 112572}, -- Blind
		[31224] = {120, 1, nil, 112585}, -- Cloak of Shadows
		[5277] = {120, 1, nil, 112657}, -- Evasion
		[1776]  = {20, 1, nil, 112631}, -- Gouge
		[36554] = {30, 1, nil, {[259]=false,[260]=112583,[261]=false}}, -- Shadowstep
		[57934] = {30, 1, nil, 112574}, -- Tricks of the Trade
		[385616] = {45, 1, nil, 112525}, -- Echoing Reprimand
		[381623] = {60, 1, nil, 112648}, -- Thistle Tea
		[382245] = {45, 1, nil, 112639}, -- Cold Blood
		[185313] = {60, 1, nil, 112577}, -- Shadow Dance

		[360194] = {120, 1, 259, 112662}, -- Deathmark
		[200806] = {180, 1, 259, 112672}, -- Exsanguinate
		[385408] = {90, 1, nil, {[259]=112507,[260]=112565,[261]=112592}, true}, -- Sepsis
		[385424] = {30, 1, 259, 112506}, -- Serrated Bone Spike
		[385627] = {60, 1, 259, 114736}, -- Kingsbane
		[381802] = {45, 1, 259, 112667}, -- Indiscriminate Carnage

		[13750] = {180, 1, 260, 112545}, -- Adrenaline Rush
		[196937] = {35, 1, 260, 112564}, -- Ghostly Strike
		[271877] = {45, 1, 260, 112530}, -- Blade Rush
		[381989] = {420, 1, 260, 112538}, -- Keep It Rolling
		[51690] = {90, 1, 260, 117149}, -- Killing Spree

		[121471] = {120, 1, 261, 112614}, -- Shadow Blades
		[277925] = {60, 1, 261, 112604}, -- Shuriken Tornado
		[384631] = {90, 1, 261, 112606}, -- Flagellation
		[426591] = {45, 1, 261, 117169}, -- Goremaw's Bite
	},
	SHAMAN = {
		[2484] = {30, 5}, -- Earthbind Totem
		[20608] = {1800, 8}, -- Reincarnation
		[21169] = 20608, -- Reincarnation (Resurrection)
		[UnitFactionGroup("player") == "Horde" and 2825 or 32182] = {300, 48}, -- Bloodlust/Heroism

		[108271] = {120, 1, nil, 101945}, -- Astral Shift
		[57994] = {12, 1, nil, 101957}, -- Wind Shear
		[198103] = {300, 1, nil, 101952}, -- Earth Elemental
		[192058] = {60, 1, nil, 101961}, -- Capacitor Totem
		[5394] = {30, 1, nil, {[262]=101998,[263]=101998,[264]={101998,-101933,101900}}}, -- Healing Stream Totem
		[8143] = {60, 1, nil, 101958}, -- Tremor Totem
		[51485] = {30, 1, nil, 101975}, -- Earthgrab Totem
		[192077] = {120, 1, nil, 101976}, -- Wind Rush Totem
		[51514] = {30, 1, nil, 101972}, -- Hex (Frog)
		[211004] = 51514, -- Spider
		[211015] = 51514, -- Cockroach
		[277778] = 51514, -- Zandalari Tendonripper
		[309328] = 51514, -- Living Honey
		[210873] = 51514, -- Compy
		[211010] = 51514, -- Snake
		[269352] = 51514, -- Skeletal Hatchling
		[277784] = 51514, -- Wicker Mongrel
		[79206] = {120, 1, nil, 101955}, -- Spiritwalker's Grace
		[51490] = {45, 1, nil, 101995}, -- Thunderstorm
		[192063] = {30, 1, nil, 101982}, -- Gust of Wind
		[58875] = {60, 1, nil, 101983}, -- Spirit Walk
		[108281] = {120, 1, nil, 102000}, -- Ancestral Guidance
		[305483] = {45, 1, nil, 101993}, -- Lightning Lasso
		[383013] = {45, 1, nil, 101989}, -- Poison Cleansing Totem
		[108285] = {180, 1, nil, 101987}, -- Totemic Recall
		[378081] = {60, 1, nil, 101997}, -- Nature's Swiftness
		[383019] = {60, 1, nil, 101991}, -- Tranquil Air Totem
		[383017] = {30, 1, nil, 101992}, -- Stoneskin Totem

		[192249] = {150, 1, 262, 101849}, -- Storm Elemental
		[198067] = {150, 1, 262, 101850}, -- Fire Elemental
		[210714] = {30, 1, 262, 101870}, -- Icefury
		[191634] = {60, 1, nil, {[262]=101860,[264]=101901}}, -- Stormkeeper (Elemental)
		[383009] = 191634, -- Stormkeeper (Restoration)
		[114049] = {180, 1, nil, {[262]=101877,[263]=114291,[264]=101942}}, -- Ascendance
		[114050] = 114049, -- Ascendance (Elemental)
		[114051] = 114049, -- Ascendance (Enhancement)
		[114052] = 114049, -- Ascendance (Restoration)
		[192222] = {60, 1, 262, 101884}, -- Liquid Magma Totem

		[196884] = {30, 1, 263, 101810}, -- Feral Lunge
		[342240] = {15, 1, 263, 101821}, -- Ice Strike
		[384352] = {90, 1, 263, 101824}, -- Doom Winds
		[197214] = {40, 1, 263, 101841}, -- Sundering
		[51533] = {90, 1, 263, 101838}, -- Feral Spirit

		[98008] = {180, 1, 264, 101913}, -- Spirit Link Totem
		[157153] = {45, 1, 264, 101933}, -- Cloudburst Totem (replaces Healing Stream Totem)
		[108280] = {180, 1, 264, 101912}, -- Healing Tide Totem
		[16191] = {180, 1, 264, 101929}, -- Mana Tide Totem
		[207399] = {300, 1, 264, 101930}, -- Ancestral Protection Totem
		[198838] = {60, 1, 264, 101931}, -- Earthen Wall Totem
	},
	WARLOCK = {
		[104773] = {180, 4}, -- Unending Resolve
		[20707] = {600, 14}, -- Soulstone
		[95750] = 20707, -- Soulstone Resurrection (combat)
		[19647] = {24, 23}, -- Spell Lock (Felhunter)
		[119910] = 19647, -- Spell Lock (Command Demon)
		[132409] = 19647, -- Spell Lock (Grimoire of Sacrifice Command Demon)
		[698] = {120, 33}, -- Ritual of Summoning
		[29893] = {120, 47}, -- Create Soulwell

		[333889] = {180, 1, nil, 91439}, -- Fel Domination
		[5484] = {40, 1, nil, 91458}, -- Howl of Terror
		[6789] = {45, 1, nil, 91457}, -- Mortal Coil
		[327884] = {60, 1, nil, 91442}, -- Amplify Curse
		[108416] = {60, 1, nil, 91444}, -- Dark Pact
		[30283] = {60, 1, nil, 91452}, -- Shadowfury
		[384069] = {15, 1, nil, 91450}, -- Shadowflame

		[205179] = {45, 1, 265, 91557}, -- Phantom Singularity
		[278350] = {30, 1, 265, 91556}, -- Vile Taint
		[205180] = {120, 1, 265, 91554}, -- Summon Darkglare
		[386997] = {60, 1, 265, 91578}, -- Soul Rot

		[264119] = {45, 1, 266, 91538}, -- Summon Vilefiend
		[267211] = {30, 1, 266, 91541}, -- Bilescourge Bombers
		[267171] = {60, 1, 266, 91540}, -- Demonic Strength
		[264130] = {30, 1, 266, 91521}, -- Power Siphon
		[111898] = {120, 1, 266, 91531}, -- Grimoire: Felguard
		[267217] = {180, 1, 266, 91515}, -- Nether Portal
		[265187] = {90, 1, 266, 91550}, -- Summon Demonic Tyrant
		[386833] = {45, 1, 266, 115460}, -- Guillotine

		[80240] = {30, 1, 267, 91493}, -- Havoc
		[196447] = {25, 1, 267, 91586}, -- Channel Demonfire
		[152108] = {30, 1, 267, 91487}, -- Cataclysm
		[1122] = {180, 1, 267, 91502}, -- Summon Infernal
	},
	WARRIOR = {
		[260708] = {30, 1}, -- Sweeping Strikes
		[100] = {20, 2}, -- Charge
		[6552] = {15, 7}, -- Pummel

		[18499] = {60, 1, nil, {[71]={112239,-112211},[72]={112239,-112211},[73]={112239,-112211}}}, -- Berserker Rage
		[3411] = {30, 1, nil, 112186}, -- Intervene
		[97462] = {180, 1, nil, 112188}, -- Rallying Cry
		[384100] = {60, 1, nil, 112211}, -- Berserker Shout
		[12323] = {30, 1, nil, 112210}, -- Piercing Howl
		[23920] = {25, 1, nil, 112253}, -- Spell Reflection
		[52174] = {45, 1, nil, 112208}, -- Heroic Leap
		[5246] = {90, 1, nil, 112252}, -- Intimidating Shout
		[64382] = {180, 1, nil, 112214}, -- Shattering Throw
		[384110] = {45, 1, nil, 112215}, -- Wrecking Throw
		[107570] = {30, 1, nil, 112198}, -- Storm Bolt
		[383762] = {180, 1, nil, 112220}, -- Bitter Immunity
		[107574] = {90, 1, nil, 112232}, -- Avatar
		[384318] = {90, 1, nil, 112223}, -- Thunderous Roar
		[376079] = {90, 1, nil, 112247}, -- Spear of Bastion
		[46968] = {40, 1, nil, 112242}, -- Shockwave

		[118038] = {120, 1, 71, 112128}, -- Die by the Sword
		[167105] = {45, 1, nil, {[71]={112144,112139}}}, -- Colossus Smash
		[262161] = 167105, -- Warbreaker
		[260643] = {21, 1, 71, 112133}, -- Skullsplitter
		[227847] = {90, 1, nil, 112314}, -- Bladestorm

		[184364] = {120, 1, 72, 112264}, -- Enraged Regeneration
		[1719] = {90, 1, 72, 112281}, -- Recklessness
		[385059] = {45, 1, 72, 112289}, -- Odyn's Fury
		-- [152277] = {90, 1, nil, {[72]=112256,[73]=112304}}, -- Ravager
		-- [228920] = 152277, -- Ravager (Protection)

		[1160] = {45, 1, 73, 112159}, -- Demoralizing Shout
		[12975] = {180, 1, 73, 112151}, -- Last Stand
		[1161] = {120, 1, nil, {[73]={112163,-112161}}}, -- Challenging Shout
		[386071] = {90, 1, 73, 112161}, -- Disrupting Shout
		[871] = {210, 1, 73, 112167}, -- Shield Wall
		[392966] = {90, 1, 73, 112110}, -- Spell Block
		[385952] = {45, 1, 73, 112173}, -- Shield Charge
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
		[357214] = {90, 1, nil, nil, nil, "Dracthyr"}, -- Wing Buffet (Dracthyr)
		[368970] = {90, 1, nil, nil, nil, "Dracthyr"}, -- Tail Swipe (Dracthyr)
	}
}


-- Combat Log Event Modifiers

data.userdata = {}
local scratch = data.userdata

data.specialEvents = {}
local specialEvents = setmetatable(data.specialEvents, {__index=function(t, k)
	t[k] = {}
	return t[k]
end})

local infoCache = {}
local resetCooldown = nil

data.SetupCLEU = function(playerTable, resetFunc)
	infoCache = playerTable
	resetCooldown = resetFunc
end

-- Death Knight

-- Mind Freeze
specialEvents.SPELL_INTERRUPT[47528] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[96173] then -- Coldthirst
		resetCooldown(info, 47528, 3) -- Mind Freeze
	end
end

-- Death Coil
specialEvents.SPELL_CAST_SUCCESS[47541] = function(srcGUID)
	local info = infoCache[srcGUID]
	if not info then return end

	if info.talents[96263] then -- Red Thirst
		resetCooldown(info, 55233, 3) -- Vampiric Blood
	end
	if info.talents[96287] then -- Army of the Damned
		resetCooldown(info, 42650, 5) -- Army of the Dead
	end
end

-- Death Strike
specialEvents.SPELL_CAST_SUCCESS[49998] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[96263] then -- Red Thirst
		local amount = 4.5
		if info.talents[96277] then -- Ossuary
			-- While you have at least 5 Bone Shield charges, the
			-- cost of Death Strike is reduced by 5 Runic Power.
			local stacks = scratch[srcGUID] -- bone shield stacks
			if stacks and stacks > 4 then
				amount = 4
			end
		end
		resetCooldown(info, 55233, amount) -- Vampiric Blood
	end
end

-- Sacrificial Pact
specialEvents.SPELL_CAST_SUCCESS[327574] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[96263] then -- Red Thirst
		resetCooldown(info, 55233, 2) -- Vampiric Blood
	end
end

-- Raise Ally
specialEvents.SPELL_CAST_SUCCESS[61999] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[96263] then -- Red Thirst
		resetCooldown(info, 55233, 3)-- Vampiric Blood
	end
end

-- Bonestorm
specialEvents.SPELL_AURA_APPLIED[194844] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[96263] then -- Red Thirst
		scratch[srcGUID .. "bs"] = GetTime()
	end
end
specialEvents.SPELL_AURA_REMOVED[194844] = function(srcGUID)
	local t = scratch[srcGUID .. "bs"]
	if t then
		scratch[srcGUID .. "bs"] = nil
		local duration = math.floor(GetTime() - t) -- 1s of Bonestorm = 10 rp
		if duration > 0 and infoCache[srcGUID] then
			resetCooldown(infoCache[srcGUID], 55233, duration) -- Vampiric Blood
		end
	end
end

-- Bone Shield
specialEvents.SPELL_AURA_APPLIED_DOSE[195181] = function(srcGUID, _, _, _, amount)
	local info = infoCache[srcGUID]
	if not info then return end

	scratch[srcGUID] = amount
end
specialEvents.SPELL_AURA_REMOVED_DOSE[195181] = function(srcGUID, _, _, _, amount)
	local info = infoCache[srcGUID]
	if not info then return end

	scratch[srcGUID] = amount

	if info.talents[96274] then -- Blood Tap
		resetCooldown(info, 221699, 2) -- Blood Tap
	end
	if info.talents[96260] then -- Insatiable Blade
		resetCooldown(info, 49028, 5) -- Dancing Rune Weapon
	end
end
specialEvents.SPELL_AURA_REMOVED[195181] = function(srcGUID)
	local info = infoCache[srcGUID]
	if not info then return end

	if scratch[srcGUID] == 1 then
		-- Wish _DOSE filed for 1->0
		-- Hopefully it didn't just drop off at 1
		if info.talents[96274] then -- Blood Tap
			resetCooldown(info, 221699, 2) -- Blood Tap
		end
		if info.talents[96260] then -- Insatiable Blade
			resetCooldown(info, 49028, 5) -- Dancing Rune Weapon
		end
	end

	scratch[srcGUID] = nil
end

local function icecapCast(srcGUID, _, spellId)
	local info = infoCache[srcGUID]
	if info and info.talents[96162] then -- Icecap
		if not scratch[srcGUID .. "ic"] then scratch[srcGUID .. "ic"] = {} end
		local id = 0
		if spellId == 222024 or spellId == 66198 then
			id = 1
		elseif spellId == 222026 or spellId == 66196 then
			id = 2
		end
		scratch[srcGUID .. "ic"][id] = true
	end
end
specialEvents.SPELL_CAST_SUCCESS[49020] = icecapCast -- Obliterate
specialEvents.SPELL_CAST_SUCCESS[49143] = icecapCast -- Frost Strike

local function icecap(srcGUID, _, spellId, ...)
	local info = infoCache[srcGUID]
	if info and scratch[srcGUID .. "ic"] then -- Icecap
		-- only count it once x.x
		local id = 0
		if spellId == 222024 or spellId == 66198 then
			id = 1
		elseif spellId == 222026 or spellId == 66196 then
			id = 2
		end
		if scratch[srcGUID .. "ic"][id] then
			local crit = select(7, ...)
			if crit then
				resetCooldown(info, 51271, 2) -- Pillar of Frost
			end
			scratch[srcGUID .. "ic"][id] = nil
		end
	end
end
specialEvents.SPELL_DAMAGE[222024] = icecap -- Obliterate
specialEvents.SPELL_DAMAGE[66198] = icecap -- Obliterate Off-Hand
specialEvents.SPELL_DAMAGE[222026] = icecap -- Frost Strike
specialEvents.SPELL_DAMAGE[66196] = icecap -- Frost Strike Off-Hand

-- Demon Hunter

-- Metamorphosis
specialEvents.SPELL_AURA_REMOVED[187827] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[117765] then -- Restless Hunter (Havoc)
		resetCooldown(info, 195072, nil, 1) -- Fel Rush
	end
end

-- Cycle of Binding
local function sigils(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[112878] then -- Cycle of Binding
		resetCooldown(info, 202137, 3) -- Sigil of Silence
		resetCooldown(info, 204596, 3) -- Sigil of Flame
		resetCooldown(info, 207684, 3) -- Sigil of Misery
		resetCooldown(info, 202138, 3) -- Sigil of Chains
		resetCooldown(info, 390163, 3) -- Elysian Decree
	end
end
specialEvents.SPELL_AURA_APPLIED[204490] = sigils -- Sigil of Silence
specialEvents.SPELL_AURA_APPLIED[204598] = sigils -- Sigil of Flame
specialEvents.SPELL_AURA_APPLIED[207685] = sigils -- Sigil of Misery
specialEvents.SPELL_AURA_APPLIED[204843] = sigils -- Sigil of Chains
specialEvents.SPELL_DAMAGE[389860] = sigils -- Elysian Decree

-- Druid

-- Solar Beam
specialEvents.SPELL_INTERRUPT[78675] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[109845] then -- Light of the Sun
		resetCooldown(info, 78675, 15) -- Solar Beam
	end
end

-- TODO Dreamstate
-- Tranquility
-- specialEvents.SPELL_CAST_SUCCESS[740] = function(srcGUID)
-- 	local info = infoCache[srcGUID]
-- 	if info and info.talents[103106] then -- Dreamstate
-- 		-- reduce a bunch of spells by 20s? 5s/tick?
-- 	end
-- end

-- Regrowth
specialEvents.SPELL_HEAL[8936] = function(srcGUID, _, _, _, _, _, _, _, _, critical)
	if not critical then return end

	local info = infoCache[srcGUID]
	if info and info.talents[103118] and info.talents[103120] then -- Cenarius' Guidance / Incarnation
		resetCooldown(info, 33891, 1) -- Incarnation: Tree of Life
	end
end

-- Lifebloom
specialEvents.SPELL_AURA_REMOVED[33763] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[103118] and info.talents[103120] then -- Cenarius' Guidance / Incarnation
		resetCooldown(info, 33891, 2) -- Incarnation: Tree of Life
	end
end

-- Evoker

-- Oppressing Roar
specialEvents.SPELL_DISPEL[372048] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[87687] then -- Overawe
		resetCooldown(info, 372048, 20) -- Oppressing Roar
	end
end


-- Hunter

-- Barbed Shot
specialEvents.SPELL_CAST_SUCCESS[185358] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[100524] then -- Barbed Wrath
		-- Bestial Wrath's remaining cooldown is reduced
		-- by 12 sec each time you use Barbed Shot
		resetCooldown(info, 19574, 12) -- Bestial Wrath
	end
end


-- TODO Calling the Shots

local function frenzyStrikes(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[100548] then -- Frenzy Strikes
		-- Reduce the remaining cooldown by 1 sec
		-- for each target hit, up to 5.
		if not scratch[srcGUID] then scratch[srcGUID] = {} end
		local t = GetTime()
		if t-(scratch[srcGUID][0] or 0) > 1 then
			wipe(scratch[srcGUID])
		end
		scratch[srcGUID][0] = t
		scratch[srcGUID][1] = (scratch[srcGUID][1] or 0) + 1

		if scratch[srcGUID][1] < 6 then
			resetCooldown(info, 269751, 1) -- Wildfire Bomb
			resetCooldown(info, 259495, 1) -- Flanking Strike
		end
	end
end
specialEvents.SPELL_DAMAGE[187708] = frenzyStrikes -- Carve
specialEvents.SPELL_DAMAGE[212436] = frenzyStrikes -- Butchery

-- Coordinated Assault
specialEvents.SPELL_AURA_APPLIED[266779] = function(srcGUID)
	local info = infoCache[srcGUID]
	if not info then return end

	if info.talents[100510] then -- Bombardier
		resetCooldown(info, 269751) -- Wildfire Bomb
	end
	if info.talents[100528] then -- Coordinated Kill
		-- add 50% reduction
		local cdMod = info.talents[100563] and 7.5 or 9
		addMod(info.guid, 259495, cdMod) -- Wildfire Bomb
	end
end
specialEvents.SPELL_AURA_REMOVED[266779] = function(srcGUID)
	local info = infoCache[srcGUID]
	if not info then return end

	if info.talents[100510] then -- Bombardier
		resetCooldown(info, 269751) -- Wildfire Bomb
	end
	if info.talents[100528] then -- Coordinated Kill
		-- remove 50% reduction
		local cdMod = info.talents[100563] and 7.5 or 9
		addMod(info.guid, 259495, -cdMod) -- Wildfire Bomb
	end
end

-- Fury of the Eagle
specialEvents.SPELL_DAMAGE[203415] = function(srcGUID, _, _, _, _, _, _, _, _, critical)
	local info = infoCache[srcGUID]
	if info and info.talents[100533] and critical then -- Ruthless Marauder
		resetCooldown(info, 269751, 0.5) -- Wildfire Bomb
		resetCooldown(info, 259495, 0.5) -- Flanking Strike
	end
end

-- Mage

-- Counterspell
specialEvents.SPELL_INTERRUPT[2139] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[80161] then -- Quick Witted
		resetCooldown(info, 2139, 4) -- Counterspell
	end
end

-- TODO Mirror Image Reduplication 80185 -10s
-- SPELL_SUMMON -> UNIT_DIED UNIT_DESTROYED UNIT_DISSIPATES ?

-- Alter Time
specialEvents.SPELL_AURA_APPLIED[342246] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info then
		scratch[srcGUID .. "at"] = GetTime()
	end
end
specialEvents.SPELL_AURA_REMOVED[342246] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info then
		if info.talents[80159] then -- Master of Time
			resetCooldown(info, 1953) -- Blink
		end
		if scratch[srcGUID .. "at"] then
			-- Fix the cooldown when casting again to relocate
			local duration = GetTime() - scratch[srcGUID .. "at"]
			if duration > 0 and duration < 10.2 then
				resetCooldown(info, 342245, duration) -- Alter Time
			end
		end
	end
	scratch[srcGUID .. "at"] = nil
end

local function timeManipulation(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[80189] then -- Time Manipulation
		resetCooldown(info, 122, 1) -- Frost Nova
		resetCooldown(info, 383121, 1) -- Mass Polymorph
		resetCooldown(info, 113724, 1) -- Ring of Frost
		resetCooldown(info, 1953, 1) -- Ice Nova
		if info.talents[80143] then -- Freezing Cold
			resetCooldown(info, 120, 1) -- Cone of Cold
		end
		resetCooldown(info, 1953, 1) -- Dragon's Breath
	end
end
specialEvents.SPELL_CAST_SUCCESS[108853] = timeManipulation -- Fire Blast
-- specialEvents.SPELL_CAST_SUCCESS[5143] = timeManipulation -- Clearcasting Arcane Missiles
-- specialEvents.SPELL_CAST_SUCCESS[30455] = timeManipulation -- Ice Lance on Frozen targets

-- Shifting Power
specialEvents.SPELL_AURA_APPLIED[382440] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info then
		scratch[srcGUID] = GetTime()
	end
end
specialEvents.SPELL_AURA_REMOVED[382440] = function(srcGUID)
	if not scratch[srcGUID] then return end

	local info = infoCache[srcGUID]
	if info then
		-- Every 1 sec, reduce the remaining cooldown of your abilities by 3 sec.
		local duration = math.floor(GetTime() - scratch[srcGUID])
		if duration > 0 and duration < 5 then
			for spellId in next, data.spells.MAGE do
				resetCooldown(info, spellId, duration * 3)
			end
		end
	end
	scratch[srcGUID] = nil
end

-- Clearcasting
local function clearcasting(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[80196] then -- Orb Barrage
		resetCooldown(info, 153626, 2) -- Arcane Orb
	end
end
specialEvents.SPELL_AURA_REMOVED_DOSE[79684] = clearcasting
specialEvents.SPELL_AURA_REMOVED[79684] = clearcasting

-- Cold Snap
specialEvents.SPELL_CAST_SUCCESS[235219] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info then
		resetCooldown(info, 11426) -- Ice Barrier
		resetCooldown(info, 122) -- Frost Nova
		resetCooldown(info, 120) -- Cone of Cold
		resetCooldown(info, 45438) -- Ice Block
	end
end

-- Blizzard
specialEvents.SPELL_DAMAGE[190356] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[80233] then -- Ice Caller
		-- Each time Blizzard deals damage, the cooldown
		-- of Frozen Orb is reduced by 0.5 sec
		resetCooldown(info, 84714, 0.5) -- Frozen Orb
	end
end

local function kindling(srcGUID, ...)
	local critical = select(9, ...)
	if not critical then return end

	local info = infoCache[srcGUID]
	if info and info.talents[80265] then -- Kindling
		resetCooldown(info, 190319, 1) -- Combustion
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
	if not info then return end

	if info.talents[101467] then -- Sal'salabim's Strength
		resetCooldown(info, 115181) -- Breath of Fire
	end
	if info.talents[101543] then -- Walk with the Ox
		resetCooldown(info, 132578, 0.25) -- Invoke Niuzao, the Black Ox
	end
end

local function shuffleAbilities(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[101543] then -- Walk with the Ox
		resetCooldown(info, 132578, 0.25) -- Invoke Niuzao, the Black Ox
	end
end
specialEvents.SPELL_CAST_SUCCESS[100784] = shuffleAbilities -- Blackout Kick
specialEvents.SPELL_CAST_SUCCESS[101546] = shuffleAbilities -- Spinning Crane Kick

-- Black Ox Brew
specialEvents.SPELL_CAST_SUCCESS[115399] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info then
		resetCooldown(info, 119582, nil, 2) -- Purifying Brew
		resetCooldown(info, 322507) -- Celestial Brew
	end
end

-- Paladin

local function holyPowerSpenders(srcGUID, _, spellId)
	local info = infoCache[srcGUID]
	if info then
		-- local hp = spellId == 215661 and 5 or 3 -- Justicar's Vengeance is 5, everything else is 3
		local hp = 3
		if info.talents[102589] then -- Fist of Justice (Class)
			-- Each Holy Power spent reduces the
			-- remaining cooldown on Hammer of
			-- Justice by 1 sec.
			resetCooldown(info, 853, hp) -- Hammer of Justice
		end
		if info.talents[102556] then -- Tirion's Devotion (Holy)
			-- Lay on Hands' cooldown is reduced by
			-- 1.5 sec per Holy Power spent
			resetCooldown(info, 633, hp * 1.5) -- Lay on Hands
		end
		if info.talents[102433] then -- Resolute Defender (Protection)
			-- Each 3 Holy Power you spend reduces
			-- the cooldown of Ardent Defender and
			-- Divine Shield by 1.0 sec.
			local amount = hp / 3 * 1.0
			resetCooldown(info, 31850, amount) -- Ardent Defender
			resetCooldown(info, 642, amount) -- Divine Shield
		end
		if info.talents[102440] then -- Righteous Protector (Protection)
			-- Each Holy Power spent reduces the
			-- remaining cooldown on Avenging
			-- Wrath and Guardian of Ancient Kings
			-- by 2.0 sec.
			local amount = hp * 2.0
			resetCooldown(info, 31884, amount) -- Avenging Wrath
			resetCooldown(info, 86659, amount) -- Guardian of Ancient Kings
		end
	end
end
specialEvents.SPELL_CAST_SUCCESS[210191] = holyPowerSpenders -- Word of Glory
specialEvents.SPELL_CAST_SUCCESS[53600] = holyPowerSpenders  -- Shield of the Righteous
specialEvents.SPELL_CAST_SUCCESS[85222] = holyPowerSpenders  -- Light of Dawn
specialEvents.SPELL_CAST_SUCCESS[53385] = holyPowerSpenders  -- Divine Storm
specialEvents.SPELL_CAST_SUCCESS[85256] = holyPowerSpenders -- Templar's Verdict
specialEvents.SPELL_CAST_SUCCESS[383328] = holyPowerSpenders -- Final Verdict
specialEvents.SPELL_CAST_SUCCESS[215661] = holyPowerSpenders -- Justicar's Vengeance

-- Priest

local function manipulation(srcGUID)
	local info = infoCache[srcGUID]
	if not info then return end

	if info.talents[103818] then -- Manipulation
		local rank = info.talents[103818]
		resetCooldown(info, 375901, rank * 0.5) -- Mindgames
	end
	if info.talents[103695] then -- Void Summoner
		resetCooldown(info, 34433, 4) -- Shadowfiend
		resetCooldown(info, 123040, 2) -- Mindbender
	end
end
specialEvents.SPELL_CAST_SUCCESS[8092] = manipulation -- Mind Blast
specialEvents.SPELL_CAST_SUCCESS[47540] = manipulation -- Penance

-- Smite
specialEvents.SPELL_CAST_SUCCESS[585] = function(srcGUID)
	local info = infoCache[srcGUID]
	if not info then return end

	if info.level > 26 then -- Holy Words
		local cdMod = 4
		if info.talents[103764] then -- Light of the Naaru
			cdMod = cdMod + info.talents[103764] / 10 * cdMod
		elseif info.talents[103743] and scratch[srcGUID .. "ap"] then -- Apotheosis active
			cdMod = 12
		end
		resetCooldown(info, 88625, cdMod) -- Holy Word: Chastise
	end
	if info.talents[103818] then -- Manipulation
		local rank = info.talents[103818]
		resetCooldown(info, 375901, rank * 0.5) -- Mindgames
	end
	if info.talents[103695] then -- Void Summoner
		resetCooldown(info, 34433, 4) -- Shadowfiend
		resetCooldown(info, 123040, 2) -- Mindbender
	end
end


-- Power Word: Shield
specialEvents.SPELL_CAST_SUCCESS[17] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[103714] then -- Disciple: Protector of the Frail
		resetCooldown(info, 33206, 3) -- Pain Suppression
	end
end

-- Penance
local function penanceBolt(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[103699] then
		resetCooldown(info, 421453, 1) -- Ultimate Penitence
	end
end
specialEvents.SPELL_DAMAGE[47666] = penanceBolt
specialEvents.SPELL_HEAL[47750] = penanceBolt

-- Heal/Flash Heal
local function hwSerenity(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.level > 26 then -- Holy Words
		local cdMod = 6
		if info.talents[103764] then -- Light of the Naaru
			cdMod = cdMod + info.talents[103764] / 10 * cdMod
		elseif info.talents[103743] and scratch[srcGUID .. "ap"] then -- Apotheosis active
			cdMod = 18
		end
		resetCooldown(info, 2050, cdMod) -- Holy Word: Serenity
	end
end
specialEvents.SPELL_CAST_SUCCESS[2060] = hwSerenity -- Heal
specialEvents.SPELL_CAST_SUCCESS[2061] = hwSerenity -- Flash Heal

-- Prayer of Healing
specialEvents.SPELL_CAST_SUCCESS[596] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.level > 26 then -- Holy Words
		local cdMod = 6
		if info.talents[103764] then -- Light of the Naaru
			cdMod = cdMod + info.talents[103764] / 10 * cdMod
		elseif info.talents[103743] and scratch[srcGUID .. "ap"] then -- Apotheosis active
			cdMod = 18
		end
		resetCooldown(info, 34861, cdMod) -- Holy Word: Sanctify
	end
end

-- Renew
specialEvents.SPELL_CAST_SUCCESS[139] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.level > 26 then -- Holy Words
		local cdMod = 2
		if info.talents[103764] then -- Light of the Naaru
			cdMod = cdMod + info.talents[103764] / 10 * cdMod
		elseif info.talents[103743] and scratch[srcGUID .. "ap"] then -- Apotheosis active
			cdMod = 6
		end
		resetCooldown(info, 34861, cdMod) -- Holy Word: Sanctify
	end
end

local function holyWordSalvation(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[103742] then
		resetCooldown(info, 265202, 15) -- Holy Word: Salvation
	end
end
specialEvents.SPELL_CAST_SUCCESS[2050] = holyWordSalvation -- Holy Word: Serenity
specialEvents.SPELL_CAST_SUCCESS[34861] = holyWordSalvation -- Holy Word: Sanctify

-- Guardian Spirit
specialEvents.SPELL_AURA_APPLIED[47788] = function(srcGUID)
	scratch[srcGUID .. "gs"] = GetTime()
end
specialEvents.SPELL_AURA_REMOVED[47788] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[103773] and scratch[srcGUID .. "gs"] then -- Guardian Angel
		-- When Guardian Spirit expires without saving
		-- the target from death, reduce its remaining
		-- cooldown to 60 seconds.
		if GetTime() - scratch[srcGUID .. "gs"] > 9.7 then
			resetCooldown(info, 47788, 110) -- 180 - 10 - 60
		end
	end
	scratch[srcGUID .. "gs"] = nil
end

-- Symbol of Hope
specialEvents.SPELL_CAST_SUCCESS[64901] = function(srcGUID)
	for _, info in next, infoCache do
		if info.class == "DEATHKNIGHT" then
			resetCooldown(info, 48792, 30) -- Icebound Fortitude
		elseif info.class == "DEMONHUNTER" then
			if info.spec == 577 then
				resetCooldown(info, 198589, 30) -- Blur
			elseif info.spec == 581 then
				resetCooldown(info, 204021, 30) -- Fiery Brand
			end
		elseif info.class == "DRUID" then
			resetCooldown(info, 22812, 30) -- Fiery Brand
		elseif info.class == "EVOKER" then
			resetCooldown(info, 363916, 30) -- Obsidian Scales
		elseif info.class == "HUNTER" then
			resetCooldown(info, 109304, 30) -- Exhilaration
		elseif info.class == "MAGE" then
			resetCooldown(info, 55342, 30) -- Mirror Image
		elseif info.class == "MONK" then
			resetCooldown(info, 115203, 30) -- Fortifying Brew
		elseif info.class == "PALADIN" then
			if info.spec == 65 then
				resetCooldown(info, 498, 30) -- Divine Protection
			elseif info.spec == 66 then
				resetCooldown(info, 31850, 30) -- Ardent Defender
			elseif info.spec == 70 then
				resetCooldown(info, 184662, 30) -- Shield of Vengeance
			end
		elseif info.class == "PRIEST" then
			resetCooldown(info, 19236, 30) -- Desperate Prayer
		elseif info.class == "ROGUE" then
			resetCooldown(info, 185311, 30) -- Crimson Vial
		elseif info.class == "SHAMAN" then
			resetCooldown(info, 108271, 30) -- Astral Shift
		elseif info.class == "WARLOCK" then
			resetCooldown(info, 104773, 30) -- Unending Resolve
		elseif info.class == "WARRIOR" then
			if info.spec == 71 then
				resetCooldown(info, 118038, 30) -- Die by the Sword
			elseif info.spec == 72 then
				resetCooldown(info, 184364, 30) -- Enraged Regeneration
			elseif info.spec == 73 then
				resetCooldown(info, 871, 30) -- Shield Wall
			end
		end
	end
end

-- Apotheosis
specialEvents.SPELL_AURA_APPLIED[200183] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info then
		scratch[srcGUID .. "ap"] = true
		resetCooldown(info, 2050) -- Holy Word: Serenty
		resetCooldown(info, 34861) -- Holy Word: Sanctify
		resetCooldown(info, 88625) -- Holy Word: Chastise
	end
end
specialEvents.SPELL_AURA_REMOVED[200183] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info then
		scratch[srcGUID .. "ap"] = nil
	end
end

-- Rogue

-- Vanish
specialEvents.SPELL_CAST_SUCCESS[1856] = function(srcGUID, destGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[112594] then -- Invigorating Shadowdust (Sub)
		local rank = info.talents[112594]
		-- Vanish reduces the remaining cooldown of your other Rogue abilities by 15.0 sec.
		for spellId in next, data.spells.ROGUE do
			if spellId ~= 1856 then
				resetCooldown(info, spellId, rank * 15)
			end
		end
	end
end

-- Shaman

-- Capacitor Totem
specialEvents.SPELL_CAST_SUCCESS[192058] = function(srcGUID)
	scratch[srcGUID] = 0
end

-- Static Charge
specialEvents.SPELL_AURA_APPLIED[118905] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[101960] then -- Static Charge
		scratch[srcGUID] = scratch[srcGUID] + 1
		if scratch[srcGUID] < 5 then
			resetCooldown(info, 192058, 5) -- Capacitor Totem
		end
	end
end

-- Totemic Recall
specialEvents.SPELL_CAST_SUCCESS[375956] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info then
		local totems = scratch[srcGUID .. "totems"]
		if totems and totems[1] then
			resetCooldown(info, totems[1])
			if info.talents[101985] and totems[2] then -- Creation Core
				resetCooldown(info, totems[2])
			end
		end
	end
end

local function totemCasts(srcGUID, _, spellId)
	local info = infoCache[srcGUID]
	if info and info.talents[101987] then -- Totemic Recall
		local totems = scratch[srcGUID .. "totems"] or {}
		totems[2] = totems[1]
		totems[1] = spellId
		scratch[srcGUID .. "totems"] = totems
	end
end
specialEvents.SPELL_CAST_SUCCESS[375956] = totemCasts -- Vesper Totem
specialEvents.SPELL_CAST_SUCCESS[324386] = totemCasts -- Vesper Totem
specialEvents.SPELL_CAST_SUCCESS[355580] = totemCasts -- Static Field Totem
specialEvents.SPELL_CAST_SUCCESS[204336] = totemCasts -- Grounding Totem
specialEvents.SPELL_CAST_SUCCESS[204331] = totemCasts -- Counterstrike Totem
specialEvents.SPELL_CAST_SUCCESS[204330] = totemCasts -- Skyfury Totem
specialEvents.SPELL_CAST_SUCCESS[383019] = totemCasts -- Tranquil Air Totem
specialEvents.SPELL_CAST_SUCCESS[383017] = totemCasts -- Stoneskin Totem
specialEvents.SPELL_CAST_SUCCESS[383013] = totemCasts -- Poison Cleansing Totem
specialEvents.SPELL_CAST_SUCCESS[198838] = totemCasts -- Earthen Wall Totem
specialEvents.SPELL_CAST_SUCCESS[192222] = totemCasts -- Liquid Magma Totem
specialEvents.SPELL_CAST_SUCCESS[192077] = totemCasts -- Wind Rush Totem
specialEvents.SPELL_CAST_SUCCESS[192058] = totemCasts -- Capacitor Totem
specialEvents.SPELL_CAST_SUCCESS[157153] = totemCasts -- Cloudburst Totem
specialEvents.SPELL_CAST_SUCCESS[51485] = totemCasts  -- Earthgrab Totem
specialEvents.SPELL_CAST_SUCCESS[8512] = totemCasts   -- Windfury Totem (no cd? but counted on Totemic Surge)
specialEvents.SPELL_CAST_SUCCESS[8143] = totemCasts   -- Tremor Totem
specialEvents.SPELL_CAST_SUCCESS[2484] = totemCasts   -- Earthbind Totem
specialEvents.SPELL_CAST_SUCCESS[3599] = totemCasts   -- Searing Totem
specialEvents.SPELL_CAST_SUCCESS[5394] = totemCasts   -- Healing Stream Totem
specialEvents.SPELL_CAST_SUCCESS[108270] = totemCasts -- Stone Bulwark Totem
specialEvents.SPELL_CAST_SUCCESS[108273] = totemCasts -- Windwalk Totem
specialEvents.SPELL_CAST_SUCCESS[114893] = totemCasts -- Stone Bulwark
specialEvents.SPELL_CAST_SUCCESS[196932] = totemCasts -- Voodoo Totem

-- Surge of Power
local function sopStarters(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[101873] then -- Surge of Power
		scratch[srcGUID .. "sp"] = GetTime()
	end
end
specialEvents.SPELL_CAST_SUCCESS[8042] = sopStarters -- Earth Shock
specialEvents.SPELL_CAST_SUCCESS[117014] = sopStarters -- Elemental Blast
specialEvents.SPELL_CAST_SUCCESS[61882] = sopStarters -- Earthquake

local function sopCasts(srcGUID, _, spellId)
	local info = infoCache[srcGUID]
	if info and scratch[srcGUID .. "sp"] then -- Surge of Power
		if spellId == 51505 and GetTime() - scratch[srcGUID .. "sp"] < 14.7 then -- Lava Burst
			resetCooldown(info, 192249, 6) -- Storm Elemental
			resetCooldown(info, 198067, 6) -- Fire Elemental
		end
		scratch[srcGUID .. "sp"] = nil
	end
end
specialEvents.SPELL_CAST_SUCCESS[188389] = sopCasts -- Flame Shock
specialEvents.SPELL_CAST_SUCCESS[188196] = sopCasts -- Lightning Bolt
specialEvents.SPELL_CAST_SUCCESS[188443] = sopCasts -- Chain Lightning
specialEvents.SPELL_CAST_SUCCESS[51505] = sopCasts -- Lava Burst
specialEvents.SPELL_CAST_SUCCESS[196840] = sopCasts -- Frost Shock

-- Warrior

-- Shockwave
specialEvents.SPELL_CAST_SUCCESS[46968] = function(srcGUID)
	scratch[srcGUID .. "sw"] = 0
end
specialEvents.SPELL_DAMAGE[46968] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[112241] and scratch[srcGUID .. "sw"] then -- Rumbling Earth
		scratch[srcGUID .. "sw"] = scratch[srcGUID .. "sw"] + 1
		if scratch[srcGUID .. "sw"] > 2 then
			resetCooldown(info, 46968, 15) -- Shockwave
			scratch[srcGUID .. "sw"] = nil
		end
	end
end

-- Thunderclap
specialEvents.SPELL_CAST_SUCCESS[6343] = function(srcGUID)
	scratch[srcGUID .. "tc"] = 0
end
specialEvents.SPELL_DAMAGE[6343] = function(srcGUID)
	local info = infoCache[srcGUID]
	if info and info.talents[112162] and scratch[srcGUID .. "tc"] then -- Thunderlord
		scratch[srcGUID .. "tc"] = scratch[srcGUID .. "tc"] + 1
		resetCooldown(info, 1160, 1.5) -- Demoralizing Shout
		if scratch[srcGUID .. "tc"] > 2 then
			scratch[srcGUID .. "tc"] = nil
		end
	end
end

--- Anger Management
-- All
-- XXX fml this doesn't actually fire
-- specialEvents.SPELL_ENERGIZE[163201] = function(srcGUID, _, _, amount, over) -- Execute
-- 	local info = infoCache[srcGUID]
-- 	if info and info.talents[18] and info.spec ~= 72 then -- Execute is a generator for Fury
-- 		local rage = (amount + (over or 0)) / 0.2 -- 20% is refunded
-- 		local per = info.spec == 73 and 10 or 20
-- 		local amount = rage/per

-- 		if info.spec == 71 then
-- 			resetCooldown(info, 167105, amount) -- Colossus Smash
-- 			resetCooldown(info, 227847, amount) -- Blade Storm
-- 		elseif info.spec == 73 then
-- 			resetCooldown(info, 107574, amount) -- Avatar
-- 			resetCooldown(info, 871, amount) -- Shield Wall
-- 		end
-- 	end
-- end
specialEvents.SPELL_CAST_SUCCESS[163201] = function(srcGUID) -- Execute
	local info = infoCache[srcGUID]
	if info and (info.talents[112143] or info.talents[112166]) then -- Anger Management
		local rage = 30 -- 20-40 /wrists Potential to drift 1-2s per execute :\
		local per = info.spec == 73 and 10 or 20
		local amount = rage/per

		if info.spec == 71 then
			resetCooldown(info, 167105, amount) -- Colossus Smash
			resetCooldown(info, 227847, amount) -- Blade Storm
		elseif info.spec == 73 then
			resetCooldown(info, 107574, amount) -- Avatar
			resetCooldown(info, 871, amount) -- Shield Wall
		end
	end
end
specialEvents.SPELL_CAST_SUCCESS[2565] = function(srcGUID) -- Shield Block
	local info = infoCache[srcGUID]
	if info and (info.talents[112143] or info.talents[112285] or info.talents[112166]) then -- Anger Management
		local rage = 30
		local per = info.spec == 73 and 10 or 20
		local amount = rage/per

		if info.spec == 71 then
			resetCooldown(info, 167105, amount) -- Colossus Smash
			resetCooldown(info, 227847, amount) -- Blade Storm
		elseif info.spec == 72 then
			resetCooldown(info, 1719, amount) -- Recklessness
			-- resetCooldown(info, 152277, amount) -- Ravager
		elseif info.spec == 73 then
			resetCooldown(info, 107574, amount) -- Avatar
			resetCooldown(info, 871, amount) -- Shield Wall
		end
	end
end
specialEvents.SPELL_CAST_SUCCESS[1464] = function(srcGUID) -- Slam
	local info = infoCache[srcGUID]
	if info and (info.talents[112143] or info.talents[112285] or info.talents[112166]) then -- Anger Management
		local rage = 20
		local per = info.spec == 73 and 10 or 20
		local amount = rage/per

		if info.spec == 71 then
			resetCooldown(info, 167105, amount) -- Colossus Smash
			resetCooldown(info, 227847, amount) -- Blade Storm
		elseif info.spec == 72 then
			resetCooldown(info, 1719, amount) -- Recklessness
			-- resetCooldown(info, 152277, amount) -- Ravager
		elseif info.spec == 73 then
			resetCooldown(info, 107574, amount) -- Avatar
			resetCooldown(info, 871, amount) -- Shield Wall
		end
	end
end
specialEvents.SPELL_CAST_SUCCESS[202168] = function(srcGUID) -- Impending Victory
	local info = infoCache[srcGUID]
	if info and (info.talents[112143] or info.talents[112285] or info.talents[112166]) then -- Anger Management
		local rage = 10
		local per = info.spec == 73 and 10 or 20
		local amount = rage/per

		if info.spec == 71 then
			resetCooldown(info, 167105, amount) -- Colossus Smash
			resetCooldown(info, 227847, amount) -- Blade Storm
		elseif info.spec == 72 then
			resetCooldown(info, 1719, amount) -- Recklessness
			-- resetCooldown(info, 152277, amount) -- Ravager
		elseif info.spec == 73 then
			resetCooldown(info, 107574, amount) -- Avatar
			resetCooldown(info, 871, amount) -- Shield Wall
		end
	end
end
-- Arms
specialEvents.SPELL_CAST_SUCCESS[12294] = function(srcGUID) -- Mortal Strike
	local info = infoCache[srcGUID]
	if info and info.talents[112143] then -- Anger Management
		local rage = 30
		local per = 20
		local amount = rage/per

		resetCooldown(info, 167105, amount) -- Colossus Smash
		resetCooldown(info, 227847, amount) -- Blade Storm
	end
end
specialEvents.SPELL_CAST_SUCCESS[772] = function(srcGUID) -- Rend
	local info = infoCache[srcGUID]
	if info and info.talents[112143] then -- Anger Management
		local rage = 30
		local per = 20
		local amount = rage/per

		resetCooldown(info, 167105, amount) -- Colossus Smash
		resetCooldown(info, 227847, amount) -- Blade Storm
	end
end
specialEvents.SPELL_CAST_SUCCESS[845] = function(srcGUID) -- Cleave
	local info = infoCache[srcGUID]
	if info and info.talents[112143] then -- Anger Management
		local rage = 20
		local per = 20
		local amount = rage/per

		resetCooldown(info, 167105, amount) -- Colossus Smash
		resetCooldown(info, 227847, amount) -- Blade Storm
	end
end
specialEvents.SPELL_CAST_SUCCESS[1680] = function(srcGUID) -- Whirlwind
	local info = infoCache[srcGUID]
	if info and info.talents[112143] then -- Anger Management
		local rage = 30
		if info.talents[114293] then -- Class: Barbaric Training
			rage = rage + 10
		end
		if info.talents[112119] then -- Storm of Swords
			rage = rage + 20
		end
		local per = info.spec == 73 and 10 or 20
		local amount = rage/per

		resetCooldown(info, 167105, amount) -- Colossus Smash
		resetCooldown(info, 227847, amount) -- Blade Storm
	end
end
-- Fury
specialEvents.SPELL_CAST_SUCCESS[184367] = function(srcGUID) -- Rampage
	local info = infoCache[srcGUID]
	if info and info.talents[112285] then -- Anger Management
		local rage = 80
		local per = 20
		local amount = rage/per

		resetCooldown(info, 1719, amount) -- Recklessness
		-- resetCooldown(info, 152277, amount) -- Ravager
	end
end
-- Protection
specialEvents.SPELL_CAST_SUCCESS[6572] = function(srcGUID) -- Revenge
	local info = infoCache[srcGUID]
	if info and info.talents[112166] then -- Anger Management
		local rage = info.talents[112244] and 30 or 20 -- Class: Barbaric Training
		local per = 10
		local amount = rage/per

		-- XXX how does this work with free Revenges
		resetCooldown(info, 107574, amount) -- Avatar
		resetCooldown(info, 871, amount) -- Shield Wall
	end
end

-- stop autovivification
setmetatable(specialEvents, nil)
