
local addonName, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Consumables", "AceTimer-3.0")
local L = scope.locale

local _G = _G
local tonumber, print, next, ipairs, select, type = tonumber, print, next, ipairs, select, type
local band, bor, lshift, format, max = bit.band, bit.bor, bit.lshift, string.format, math.max
local tconcat, sort, wipe = table.concat, table.sort, table.wipe
local GetSpellInfo, GetSpellTexture, GetSpellDescription = GetSpellInfo, GetSpellTexture, GetSpellDescription
local UnitIsUnit, IsInGroup, IsInRaid, IsInInstance = UnitIsUnit, IsInGroup, IsInRaid, IsInInstance
local UnitBuff, UnitName, UnitIsConnected, UnitIsVisible = UnitBuff, UnitName, UnitIsConnected, UnitIsVisible
local GetTime, GetRaidBuffInfo, UnitIsDeadOrGhost = GetTime, GetRaidBuffInfo, UnitIsDeadOrGhost

-- GLOBALS: ChatThrottleLib ChatFrame_AddMessageEventFilter SendChatMessage
-- GLOBALS: DISABLE YES NO NUM_LE_RAID_BUFF_TYPES LE_PARTY_CATEGORY_INSTANCE
-- GLOBALS: SlashCmdList, SLASH_ORABUFFS1 SLASH_ORABUFFS2 SLASH_ORABUFFS3 oRA3CheckButton

local GROUP_CHECK_THROTTLE = 0.8
local PLAYER_CHECK_THROTTLE = 0.3

local consumablesList = {}
local playerBuffs = {}
local auraBuffs = {}
local missingFood, missingFlasks, missingRunes, missingBuffs = {}, {}, {}, {}
local numRaidBuffs, numAvailableBuffs = 0, 0

local YES = ("|cff20ff20%s|r"):format(YES)
local NO = ("|cffff2020%s|r"):format(NO)

local spells = setmetatable({}, {
	__index = function(t, k)
		if k == nil then return end
		local name, _, texture = GetSpellInfo(k)
		if not name then
			print("oRA3: Invalid spell id", k)
			name = "" -- only print once
		end
		t[k] = name
		return name
	end
})

local getRune
do
	local runes = {
		spells[175456], -- Hyper Augmentation (Agility)
		spells[175439], -- Stout Augmentation (Strength)
		spells[175457], -- Focus Augmentation (Intellect)
	}

	function getRune(player)
		for _, spellName in next, runes do
			local id = select(11, UnitBuff(player, spellName))
			if id then
				return id
			end
		end
		return false
	end
end

local getFlask
do
	local flasks = {
		spells[156073], -- Draenic Agility Flask
		spells[156070], -- Draenic Intellect Flask
		spells[156071], -- Draenic Strength Flask
		spells[156077], -- Draenic Stamina Flask
		spells[156064], -- Greater Draenic Agility Flask
		spells[156079], -- Greater Draenic Intellect Flask
		spells[156080], -- Greater Draenic Strength Flask
		spells[156084], -- Greater Draenic Stamina Flask
		--spells[176151], -- Whispers of Insanity (Oralius' Whispering Crystal)
	}

	function getFlask(player)
		for _, spellName in next, flasks do
			local id = select(11, UnitBuff(player, spellName))
			if id then
				return id
			end
		end
		return false
	end
end

local getFood
do
	local eating = spells[433] -- Food (Eating)
	local wellFed = spells[19705] -- Well Fed
	local foods = {
		[180745] = { -- crit
			[75] = 160724,
			[100] = 160889,
			[125] = 180745,
		},
		[180749] = { -- multistrike
			[75] = 160832,
			[100] = 160900,
			[125] = 180749,
		},
		[180748] = { -- haste
			[75] = 160726,
			[100] = 160893,
			[125] = 180748,
		},
		[180746] = { -- versatility
			[75] = 160839,
			[100] = 160902,
			[125] = 180746,
		},
		[180750] = { -- mastery
			[75] = 160793,
			[100] = 160897,
			[125] = 180750,
		},
		[180747] = { -- stamina
			[112] = 160600,
			[150] = 160883,
			[187] = 180747,
		},
	}

	function getFood(player)
		-- thanks blizzard for using the same id with a modifer for 75/100/125 food
		local id, _, _, _, value = select(11, UnitBuff(player, wellFed))
		if id then
			if foods[id] and value then
				-- return an id for the food with the proper stat value (also account for Pandaren)
				return foods[id][value] or foods[id][value / 2] or id
			end
			return id
		else -- should probably map food -> well fed buffs but bleeh
			id = select(11, UnitBuff(player, eating))
			if id then
				return -id -- negative value for eating, not well fed yet
			end
		end
		return false
	end
end

local raidBuffs = {
	{ -- Stats
		1126,   -- Mark of the Wild
		20217,  -- Blessing of Kings
		115921, -- Legacy of the Emperor
		116781, -- Legacy of the White Tiger
		69378,  -- Blessing of Forgotten Kings (Leatherworking)
		159988, -- Bark of the Wild (pet)
		160017, -- Blessing of Kongs (pet)
		90363,  -- Embrace of the Shale Spider (pet)
		160077, -- Strength of the Earth (pet)
		160206, -- Lone Wolf: Power of the Primates
	},
	{ -- Stamina
		21562,  -- Power Word: Fortitude
		469,    -- Commanding Shout
		166928, -- Blood Pact
		111922, -- Fortitude (Inscription)
		50256,  -- Invigorating Roar (pet)
		90364,  -- Qiraji Fortitude (pet)
		160003, -- Savage Vigor (pet)
		160014, -- Sturdiness (pet)
		160199, -- Lone Wolf: Fortitude of the Bear
	},
	{ -- Attack Power
		6673,  -- Battle Shout
		57330, -- Horn of Winter
		19506, -- Trueshot Aura
	},
	{ -- Haste
		55610,  -- Unholy Aura
		49868,  -- Mind Quickening
		113742, -- Swiftblade's Cunning
		116956, -- Grace of Air
		128432, -- Cackling Howl (pet)
		135678, -- Energizing Spores (pet)
		160003, -- Savage Vigor (pet)
		160074, -- Speed of the Swarm (pet)
		160203, -- Lone Wolf: Haste of the Hyena
	},
	{ -- Spell Power
		1459,   -- Arcane Brilliance
		61316,  -- Dalaran Brilliance
		109773, -- Dark Intent
		90364,  -- Qiraji Fortitude (pet)
		128433, -- Serpent's Cunning (pet)
		126309, -- Still Water (pet)
		160205, -- Lone Wolf: Wisdom of the Serpent
	},
	{ -- Critical Strike
		1459,   -- Arcane Brilliance
		61316,  -- Dalaran Brilliance
		17007,  -- Leader of the Pack
		116781, -- Legacy of the White Tiger
		97229,  -- Bellowing Roar (pet)
		90363,  -- Embrace of the Shale Spider (pet)
		126373, -- Fearless Roar (pet)
		24604,  -- Furious Howl (pet)
		90309,  -- Terrifying Roar (pet)
		126309, -- Still Water (pet)
		128997, -- Spirit Beast Blessing (pet)
		160052, -- Strength of the Pack (pet)
		160200, -- Lone Wolf: Ferocity of the Raptor
	},
	{ -- Mastery
		19740,  -- Blessing of Might
		116956, -- Grace of Air
		24907,  -- Moonkin Aura
		155522, -- Power of the Grave
		160039, -- Keen Senses (pet)
		160073, -- Plainswalking (pet)
		93435,  -- Roar of Courage (pet)
		128997, -- Spirit Beast Blessing (pet)
		160198, -- Lone Wolf: Grace of the Cat
	},
	{ -- Multistrike
		49868,  -- Mind Quickening
		109773, -- Dark Intent
		113742, -- Swiftblade's Cunning
		166916, -- Windflurry
		24844,  -- Breath of the Winds (pet)
		58604,  -- Double Bite (pet)
		159736, -- Duality (pet)
		54644,  -- Frost Breath (pet)
		50519,  -- Sonic Focus (pet)
		34889,  -- Spry Attacks (pet)
		57386,  -- Wild Strength (pet)
		172968, -- Lone Wolf: Quickness of the Dragonhawk
	},
	{ -- Versatility
		1126,   -- Mark of the Wild
		55610,  -- Unholy Aura
		167187, -- Sanctity Aura
		167188, -- Inspiring Presence
		50518,  -- Chitinous Armor (pet)
		160045, -- Defensive Quills (pet)
		173035, -- Grace (pet)
		35290,  -- Indomitable (pet)
		159735, -- Tenacity (pet)
		160077, -- Strength of the Earth (pet)
		57386,  -- Wild Strength (pet)
		172967, -- Lone Wolf: Versatility of the Ravager
	}
}

---------------------------------------
-- Options

local function colorize(input) return ("|cfffed000%s|r"):format(input) end
local options = {
	type = "group",
	name = L.consumables,
	get = function(info) return module.db.profile[info[#info]] end,
	set = function(info, value) module.db.profile[info[#info]] = value end,
	args = {
		checkReadyCheck = {
			type = "select",
			name = colorize(L.checkReadyCheck),
			desc = L.checkReadyCheckDesc,
			values = { DISABLE, L.reportIfYou, L.reportAlways },
			order = 1,
		},
		output = {
			type = "select",
			name = colorize(L.output),
			desc = L.outputDesc,
			values = { DISABLE, L.self, L.group },
			set = function(info, value)
				module.db.profile.output = value
				if oRA3CheckButton then
					oRA3CheckButton:SetEnabled(value > 1 or module.db.profile.whisper)
				end
			end,
			order = 2
		},
		whisper = {
			type = "toggle",
			name = colorize(L.whisperMissing),
			desc = L.whisperMissingDesc,
			descStyle = "inline",
			set = function(info, value)
				module.db.profile.whisper = value
				if oRA3CheckButton then
					oRA3CheckButton:SetEnabled(module.db.profile.output > 1 or value)
				end
			end,
			order = 3,
			width = "full",
		},
		checks = {
			name = L.checkBuffs,
			type = "group",
			inline = true,
			order = 4,
			args = {
				checkFood = {
					type = "toggle",
					name = L.food,
					desc = L.checkFoodDesc,
					order = 1,
				},
				checkFlask = {
					type = "toggle",
					name = L.flask,
					desc = L.checkFlaskDesc,
					order = 2,
				},
				checkRune = {
					type = "toggle",
					name = L.rune,
					desc = L.checkRuneDesc,
					order = 3,
				},
				checkBuffs = {
					type = "toggle",
					name = L.raidBuffs,
					desc = L.checkBuffsDesc,
					order = 4,
				},
			},
		}, -- checks
	},
}

---------------------------------------
-- Module

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("Consumables", {
		profile = {
			checkFood = true,
			checkFlask = true,
			checkRune = false,
			checkBuffs = true,
			output = 1, -- 1 = disabled
			checkReadyCheck = 2, -- 2 = started by you
			whisper = false,
		}
	})
	oRA:RegisterModuleOptions("Consumables", options)

	oRA:RegisterList(
		L.buffs,
		consumablesList,
		L.name,
		L.food,
		L.flask,
		L.rune,
		L.raidBuffs
	)

	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnListClosed")
	oRA.RegisterCallback(self, "OnGroupChanged", "UpdateList")

	SLASH_ORABUFFS1 = "/rabuffs"
	SLASH_ORABUFFS2 = "/rab"
	SlashCmdList.ORABUFFS = function()
		oRA:OpenToList(L.buffs)
	end
end

do
	local function sortList(a, b)
		local a_buffs = (a[2] == NO and 0 or 1) + (a[3] == NO and 0 or 1) + (a[4] == NO and 0 or 1) + tonumber(a[5]:match("^%d"))
		local b_buffs = (b[2] == NO and 0 or 1) + (b[3] == NO and 0 or 1) + (b[4] == NO and 0 or 1) + tonumber(b[5]:match("^%d"))
		if a_buffs < b_buffs then
			return true
		elseif a_buffs > b_buffs then
			return false
		elseif a[1] < b[1] then
			return true
		end
		return false
	end

	function module:UpdateList()
		self:CheckGroup()
		sort(consumablesList, sortList)
		oRA:UpdateList(L.buffs)
	end
end

do
	local updater = nil
	function module:OnListSelected(_, list)
		if list == L.buffs then
			if not updater then
				updater = self:ScheduleRepeatingTimer("UpdateList", 1)
				self:UpdateList()
			end
		elseif updater then
			self:CancelTimer(updater)
			updater = nil
		end
	end

	function module:OnListClosed(_, list)
		if updater then
			self:CancelTimer(updater)
			updater = nil
		end
	end
end

function module:OnStartup()
	self:RegisterEvent("READY_CHECK")
end

function module:OnShutdown()
	wipe(playerBuffs)
	wipe(consumablesList)
	wipe(missingFlasks)
	wipe(missingFood)
	wipe(missingRunes)
	wipe(missingBuffs)
	wipe(auraBuffs)
	numRaidBuffs, numAvailableBuffs = 0, 0
end

function module:READY_CHECK(sender)
	-- 1 = never, 2 = by you, 3 = always
	if self.db.profile.checkReadyCheck == 3 or (self.db.profile.checkReadyCheck == 2 and UnitIsUnit(sender, "player")) then
		self:OutputResults()
	end
end

---------------------------------------
-- API

do
	-- 125 stat food
	local maxFoods = {
		[180745] = true, -- crit
		[180749] = true, -- multistrike
		[180748] = true, -- haste
		[180746] = true, -- versatility
		[180750] = true, -- mastery
		[180747] = true, -- stamina
	}
	-- 250 stat flask
	local maxFlasks = {
		[156064] = true, -- Greater Draenic Agility Flask
		[156079] = true, -- Greater Draenic Intellect Flask
		[156080] = true, -- Greater Draenic Strength Flask
		[156084] = true, -- Greater Draenic Stamina Flask
	}

	function module:IsBest(id)
		return maxFoods[id] or maxFlasks[id]
	end
end

-------------------
-- Output Results

do
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg)
		if msg:sub(1, 5) == "oRA3>" then return true end
	end)

	local function send(name, text)
		ChatThrottleLib:SendChatMessage("BULK", "oRA", ("oRA3> %s"):format(text), "WHISPER", nil, name)
	end
	local function whisper(name, text)
		module:ScheduleTimer(send, 0.2, name, text) -- send after print spam
	end

	local list = {}
	local function out(title, tbl)
		if next(tbl) then
			wipe(list)
			for k in next, tbl do
				list[#list + 1] = k:gsub("%-.*", "")
			end
			sort(list)
			if module.db.profile.output == 3 then -- group
				SendChatMessage(format("%s (%d): %s", title, #list, tconcat(list, ", ")), IsInRaid() and "RAID" or "PARTY")
			elseif module.db.profile.output == 2 then -- self
				print(format("|cff33ff99oRA3|r: |cffff8040%s (%d)|r: %s", title, #list, tconcat(list, ", ")))
			end
		end
	end

	local warnings = {}
	function module:OutputResults(force)
		if not force then -- default restrictions for auto announcing
			if not IsInGroup() or IsInGroup(LE_PARTY_CATEGORY_INSTANCE) or not IsInInstance() then return end
			if not oRA:IsPromoted() or oRA:IsPromoted() == 1 then return end
		end

		local missingFood, missingFlasks, missingRunes, missingBuffs = self:CheckGroup()

		local db = self.db.profile
		if db.whisper then
			local t = GetTime()

			for _, player in next, oRA:GetGroupMembers() do
				wipe(warnings)

				if db.checkFood and missingFood[player] then
					warnings[#warnings + 1] = L.noFood
				end

				if db.checkFlask then
					if missingFlasks[player] then
						warnings[#warnings + 1] = L.noFlask
					else
						local flask = getFlask(player)
						local _, _, _, _, _, duration, expires = UnitBuff(player, spells[flask])
						local remaining = expires and (expires - t) or 0
						if remaining > 0 and remaining < 600 then -- triggers weirdly sometimes, not sure why
							whisper(player, L.flaskExpires)
						end
					end
				end

				if db.checkRune and missingRunes[player] then
					warnings[#warnings + 1] = L.noRune
				end

				if #warnings > 0 then
					whisper(player, tconcat(warnings, ", "))
				end
			end
		end

		if db.checkFood then
			out(L.noFood, missingFood)
		end
		if db.checkFlask then
			out(L.noFlask, missingFlasks)
		end
		if db.checkRune then
			out(L.noRune, missingRunes)
		end
		if db.checkBuffs then
			out(L.missingBuffs, missingBuffs)
		end
	end
end

-------------------
-- Player Check

do
	function module:CheckPlayer(player)
		local cache = playerBuffs[player]
		local t = GetTime()
		if cache and t-cache[6] < PLAYER_CHECK_THROTTLE then
			local food, flask, rune, buffs, numBuffs = unpack(cache)
			return food, flask, rune, next(buffs) and buffs or false, numBuffs
		end
		if not cache then
			playerBuffs[player] = {}
			cache = playerBuffs[player]
		end

		local flask = getFlask(player)
		local food = getFood(player)
		local rune = getRune(player)
		local buffs = cache[4] or {}
		wipe(buffs)

		local numBuffs = 0
		local mask, bit = GetRaidBuffInfo(), 1
		for i = 1, NUM_LE_RAID_BUFF_TYPES do
			local found = nil
			for _, spellId in next, raidBuffs[i] do
				local name, _, _, _, _, duration = UnitBuff(player, spells[spellId])
				if name then
					numBuffs = numBuffs + 1
					found = true
					if duration == 0 then
						auraBuffs[i] = true
					end
					break
				end
			end
			if band(mask, bit) ~= 0 and not found then
				local key = _G[("RAID_BUFF_%d"):format(i)]
				buffs[key] = i
			end
			bit = lshift(bit, 1)
		end

		cache[1] = food
		cache[2] = flask
		cache[3] = rune
		cache[4] = buffs
		cache[5] = numBuffs
		cache[6] = t

		return food, flask, rune, next(buffs) and buffs or false, numBuffs
	end
end

-------------------
-- Group Check

do
	local prev = 0

	local function getStatValue(id)
		local desc = GetSpellDescription(id)
		if desc then
			local value = tonumber(desc:match("(%d+)")) or 0
			return value >= 75 and value or YES
		end
	end

	function module:CheckGroup()
		local t = GetTime()
		if t-prev < GROUP_CHECK_THROTTLE then
			return missingFood, missingFlasks, missingRunes, missingBuffs, numRaidBuffs, numAvailableBuffs
		end
		prev = t

		wipe(consumablesList)
		wipe(missingFlasks)
		wipe(missingFood)
		wipe(missingRunes)
		wipe(missingBuffs)
		wipe(auraBuffs)

		numRaidBuffs = 0
		numAvailableBuffs = select(2, GetRaidBuffInfo())
		local groupMembers = oRA:GetGroupMembers()
		if not groupMembers[1] then groupMembers[1] = UnitName("player") end
		for _, player in next, groupMembers do
			if UnitIsConnected(player) and not UnitIsDeadOrGhost(player) and UnitIsVisible(player) then
				local food, flask, rune, buffs, numBuffs = self:CheckPlayer(player)

				consumablesList[#consumablesList + 1] = {
					player:gsub("%-.*", ""),
					food and (getStatValue(food) or spells[161715]) or NO, -- 161715 = Eating
					flask and (getStatValue(flask) or YES) or NO,
					rune and YES or NO,
					("%d/%d"):format(numBuffs, max(numBuffs, numAvailableBuffs)),
				}

				if not food then
					missingFood[player] = true
				end

				if not flask then
					missingFlasks[player] = true
				end

				if not rune then
					missingRunes[player] = true
				end

				if numRaidBuffs < numBuffs then
					numRaidBuffs = numBuffs
				end
				if buffs then
					for k, i in next, buffs do
						missingBuffs[k] = i
					end
				end
			end
		end

		-- filter out aura buffs for players that are out of range
		if next(missingBuffs) then
			for k in next, auraBuffs do
				local key = _G[("RAID_BUFF_%d"):format(k)]
				missingBuffs[key] = nil
			end
		end

		if numAvailableBuffs < numRaidBuffs then
			numAvailableBuffs = numRaidBuffs
		end

		return missingFood, missingFlasks, missingRunes, missingBuffs, numRaidBuffs, numAvailableBuffs
	end
end

--@do-not-package@
do
	-- working on a more reliable method than GetRaidBuffInfo (which doesn't take spec into account)
	local buffProviders = {
		{ -- 1 Stats
			{102, 9}, {103, 9}, {104, 9}, {105, 9}, -- Druid (+Versatility)
			{268, 6}, {269, 6}, {270, 6}, -- Monk (BrM/WW +Crit)
			65, 66, 70, -- Paladin
		},
		{ -- 2 Stamina
			256, 257, 258, -- Priest
			-265, -266, -267, -- Warlock
			71, 72, 73, -- Warrior
		},
		{ -- 3 Attack Power
			250, 251, 252, -- DK
			253, 254, 255, -- Hunter
			71, 72, 73, -- Warrior
		},
		{ -- 4 Haste
			-258, -- Shadow Priest (+Multistrike)
			-251, -252, -- Unholy/Frost DK (+Versatility)
			-259, -260, -261, -- Rogue (+Multistrike)
			-262, -263, -264, -- Shaman (+Mastery)
		},
		{ -- 5 Spell Power
			{62, 6}, {63, 6}, {64, 6}, -- Mage (+Crit)
			{265, 8}, {266, 8}, {267, 8}, -- Warlock (+Multistrike)
		},
		{ -- 6 Critical Strike
			-103, -- Feral Druid
			{268, 1}, {269, 1}, -- BrM/WW Monk (+Stats)
			{62, 5}, {63, 5}, {64, 5}, -- Mage (+Spell Power)
		},
		{ -- 7 Mastery
			-250, -- Blood DK
			-102, -- Balance Druid
			-262, -263, -264, -- Shaman (+Haste)
			65, 66, 70, -- Paladin
		},
		{ -- 8 Multistrike
			-269, -- WW Monk
			-258, -- Shadow Priest (+Haste)
			-259, -260, -261, -- Rogue
			{265, 5}, {266, 5}, {267, 5}, -- Warlock (+Spell Power)
		},
		{ -- 9 Versatility
			-70, -- Ret Paladin
			-251, -252, -- Unholy/Frost DK (+Haste)
			-71, -72, -- Arms/Fury Warrior
			{102, 1}, {103, 1}, {104, 1}, {105, 1}, -- Druid (+Stats)
		}
	}

	-- XXX DEBUG --[[
	local CLASS_NAMES = _G.LOCALIZED_CLASS_NAMES_MALE
	local TESTPLAYERS = {
		Wally = {class="WARRIOR",spec=73},
		Kingkong = {class="DEATHKNIGHT",spec=250},

		Ling = {class="MONK",spec=270},
		Apenuts = {class="PALADIN",spec=65},
		Python = {class="PRIEST",spec=256},

		Foobar = {class="DRUID",spec=102},
		Eric = {class="WARLOCK",spec=265},
		Hicks = {class="MAGE",spec=62},
		Dylan = {class="ROGUE",spec=260},
		Purple = {class="HUNTER",spec=253},
		Red = {class="HUNTER",spec=254},
		Blue = {class="HUNTER",spec=255},
		Tor = {class="SHAMAN",spec=263},
	}
	local TESTGROUP = {
		"Wally", "Kingkong",
		"Ling", "Apenuts", --"Python",
		"Foobar", "Eric", "Hicks", "Purple", "Blue", --"Tor",
	}
	-- XXX DEBUG --]]

	-- this should only be calculated each time the group roster changes
	local function getRaidBuffInfo()
		print("GetRaidBuffInfo")
		local test = not IsInGroup()
		-- record what we got
		local complete = true
		local specs = {}
		local hunters = 0
		print("scanning roster")
		local members = test and TESTGROUP or oRA:GetGroupMembers()
		for _, player in next, members do
			local guid = UnitGUID(player)
			local info = test and TESTPLAYERS[player] or oRA:GetPlayerInfo(guid)
			if info.spec then
				specs[info.spec] = (specs[info.spec] or 0) + 1
				local _, specName, _, _, _, _, class = _G.GetSpecializationInfoByID(info.spec)
				print("  +", player, specName, CLASS_NAMES[class])
			else
				complete = false
				print("  ?", player)
			end
			if info.class == "HUNTER" then
				hunters = hunters + 1
			end
		end

		-- order buffs by number of players that can provide it (ascending)
		local providers, sorted = {}, {}
		for index = 1, #buffProviders do
			providers[index] = 0
			sorted[index] = index
			for _, spec in next, buffProviders[index] do
				if type(spec) == "table" then spec = spec[1] end
				if specs[spec] then
					providers[index] = providers[index] or 0 + 1
				end
			end
		end
		sort(sorted, function(a, b)
			return providers[a] < providers[b]
		end)

		-- figure out what we need
		local mask, count = 0, 0
		for _, index in ipairs(sorted) do
			print("checking", _G["RAID_BUFF_"..index])
			local bit = 2^(index - 1)
			if band(mask, bit) ~= bit then
				local buff = buffProviders[index]
				local found = false
				-- check for passive buffs first
				for _, spec in next, buff do
					-- negative spec = aura provider, doesn't count against pool
					if type(spec) == "number" and spec < 0 and specs[-spec] then
						local _, specName, _, _, _, _, class = _G.GetSpecializationInfoByID(-spec)
						print("  found", specName, CLASS_NAMES[class], "(passive)")
						found = true
						break
					end
				end
				-- check if we have a player to cover it, preferring specs we have multiple of
				if not found then
					local f, s = nil, nil
					for i, spec in next, buff do
						if type(spec) == "table" then spec = spec[1] end
						local n = specs[spec]
						if n and (not s or n > specs[s]) then
							s = spec
							f = i
						end
					end
					if f then
						found = true
						local spec = buff[f]
						-- some buffs provide multiple things, account for that
						if type(spec) == "table" then
							local also = spec[2]
							spec = spec[1]
							mask = bor(mask, 2^(also - 1))
							local _, specName, _, _, _, _, class = _G.GetSpecializationInfoByID(spec)
							print("  found", specName, CLASS_NAMES[class], "+", _G["RAID_BUFF_"..also])
						else
							local _, specName, _, _, _, _, class = _G.GetSpecializationInfoByID(spec)
							print("  found", specName, CLASS_NAMES[class])
						end
						specs[spec] = specs[spec] - 1
						if specs[spec] == 0 then
							specs[spec] = nil
						end
					end
				end
				-- do we have a hunter to cover the buff?
				if not found and hunters > 0 then
					found = true
					hunters = hunters - 1
					print("  found (Hunter)")
				end
				-- count it
				if found then
					mask = bor(mask, bit)
					count = count + 1
				else
					print("  not found")
				end
			else -- already added
				print("  already provided")
				count = count + 1
			end
		end
		print("done", mask, count)
		return mask, count
	end
	_G.ORARBI = getRaidBuffInfo
end
--@end-do-not-package@