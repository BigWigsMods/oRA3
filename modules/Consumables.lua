
local _, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Consumables", "AceTimer-3.0")
local L = scope.locale

local format = string.format
local tconcat, sort, wipe = table.concat, table.sort, table.wipe
local GetSpellInfo = GetSpellInfo
local UnitIsUnit, IsInGroup, IsInRaid, IsInInstance = UnitIsUnit, IsInGroup, IsInRaid, IsInInstance
local UnitName, UnitIsConnected, UnitIsVisible = UnitName, UnitIsConnected, UnitIsVisible
local GetTime, UnitIsDeadOrGhost = GetTime, UnitIsDeadOrGhost

--luacheck: globals oRA3CheckButton ChatFrame_AddMessageEventFilter

local GROUP_CHECK_THROTTLE = 0.8
local PLAYER_CHECK_THROTTLE = 0.3

local consumablesList = {}
local playerBuffs = {}
local missingFood, missingFlasks, missingRunes, missingBuffs = {}, {}, {}, {}

local YES = ("|cff20ff20%s|r"):format(L.yes)
local NO = ("|cffff2020%s|r"):format(L.no)

local spells = setmetatable({}, {
	__index = function(t, k)
		if k == nil then return end
		local name = GetSpellInfo(k)
		if not name then
			print("oRA3: Invalid spell id", k)
			name = "" -- only print once
		end
		t[k] = name
		return name
	end
})

local getVantus, getVantusBoss
do
	local runes = {
		-- Castle Nathria
		[311445] = 2393, -- Shriekwing
		[311446] = 2428, -- Hungering Destroyer
		[311448] = 2422, -- Sun King's Salvation
		[311447] = 2418, -- Artificer Xy'mox
		[311449] = 2420, -- Lady Inerva Darkvein
		[311450] = 2426, -- The Council of Blood
		[311451] = 2394, -- Sludgefist
		[311452] = 2425, -- Stone Legion Generals
		[334131] = 2424, -- Sire Denathrius
		[334132] = 2429, -- Huntsman Altimor
		-- Sanctum of Domination
		[354384] = 2435, -- The Tarragrue
		[354385] = 2442, -- The Eye of the Jailer
		[354386] = 2439, -- The Nine
		[354387] = 2444, -- Remnant of Ner'zhul
		[354388] = 2445, -- Soulrender Dormazain
		[354389] = 2443, -- Painsmith Raznal
		[354390] = 2446, -- Guardian of the First Ones
		[354391] = 2447, -- Fatescribe Roh-Kalo
		[354392] = 2440, -- Kel'Thuzad
		[354393] = 2441, -- Sylvanas Windrunner
		-- Sepulcher of the First Ones
		[359893] = 2458, -- Vigilant Guardian (Progenitor Defense System)
		[367121] = 2465, -- Skolex, the Insatiable Ravener
		[367124] = 2470, -- Artificer Xy'mox
		[367126] = 2459, -- Dausegne, the Fallen Oracle
		[367128] = 2460, -- Prototype Pantheon
		[367130] = 2461, -- Lihuvim, Principal Architect
		[367132] = 2463, -- Halondrus the Reclaimer
		[367134] = 2469, -- Anduin Wrynn
		[367136] = 2457, -- Lords of Dread
		[367140] = 2467, -- Rygelon
		[367143] = 2464, -- The Jailer, Zovaal
	}

	local buffs = {}
	for k in next, runes do
		buffs[#buffs + 1] = k
	end

	function getVantus(player)
		local _, _, id = module:UnitBuffByIDs(player, buffs)
		if id then
			return id
		end
		return false
	end

	function getVantusBoss(runeId)
		local ejId = runes[runeId]
		if not ejId then
			return false
		end
		return (EJ_GetEncounterInfo(ejId))
	end
end

local getRune
do
	local runes = {
		270058, -- Battle-Scarred Augmentation
		347901, -- Veiled Augmentation
	}

	function getRune(player)
		local _, _, id = module:UnitBuffByIDs(player, runes)
		if id then
			return id
		end
		return false
	end
end

local getFlask
do
	local flasks = {
		251836, -- Flask of the Currents
		251837, -- Flask of Endless Fathoms
		251838, -- Flask of the Vast Horizon
		251839, -- Flask of the Undertow
		298836, -- Greater Flask of the Currents
		298837, -- Greater Flask of Endless Fathoms
		298839, -- Greater Flask of the Vast Horizon
		298841, -- Greater Flask of the Undertow
		-- Shadowlands
		307166, -- Eternal Flask (Cauldron)
		307185, -- Spectral Flask of Power
		307187, -- Spectral Stamina Flask
	}

	function getFlask(player)
		local _, expires, id = module:UnitBuffByIDs(player, flasks)
		if id then
			return id, expires
		end
		return false
	end
end

local getFood
do
	local eating = { spells[192002] } -- Food & Drink (Eating)
	local wellFed = { spells[19705] } -- Well Fed

	function getFood(player)
		local _, _, id = module:UnitBuffByNames(player, wellFed)
		if id then
			return id
		else -- should probably map food -> well fed buffs but bleeh
			_, _, id = module:UnitBuffByNames(player, eating)
			if id then
				return -id -- negative value for eating, not well fed yet
			end
		end
		return false
	end
end

local raidBuffs = {
	{ -- Intellect
		1459,   -- Arcane Intellect
	},
	{ -- Stamina
		21562,  -- Power Word: Fortitude
	},
	{ -- Attack Power
		6673,   -- Battle Shout
	},
}
local raidBuffNames = {
	ITEM_MOD_INTELLECT_SHORT,
	ITEM_MOD_STAMINA_SHORT,
	ITEM_MOD_ATTACK_POWER_SHORT,
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
		L.vantus,
		L.raidBuffs
	)

	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnListClosed")
	oRA.RegisterCallback(self, "OnShutdown")

	SLASH_ORABUFFS1 = "/rabuffs"
	SLASH_ORABUFFS2 = "/rab"
	SlashCmdList.ORABUFFS = function()
		oRA:OpenToList(L.buffs)
	end
end

do
	local timer = nil
	function module:OnListSelected(_, list)
		if list == L.buffs then
			self:CheckGroup()
			if not timer then
				timer = self:ScheduleRepeatingTimer("CheckGroup", 1)
			end
		elseif timer then
			self:CancelTimer(timer)
			timer = nil
		end
	end
	function module:OnListClosed(_, list)
		if timer then
			self:CancelTimer(timer)
			timer = nil
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
	local best = {
		-- Food
		[308434] = true, -- crit
		[308488] = true, -- haste
		[308506] = true, -- mastery
		[308514] = true, -- versatility
		[308525] = true, -- stamina
		[327709] = true, -- agi
		[327708] = true, -- int
		[327706] = true, -- str

		-- Flasks
		[307166] = true, -- Eternal Flask (Cauldron)
		[307185] = true, -- Spectral Flask of Power
		[307187] = true, -- Spectral Stamina Flask

		-- Buffs
		[1459] = true,  -- Arcane Intellect
		[21562] = true, -- Power Word: Fortitude
		[6637] = true,  -- Battle Shout
	}

	function module:IsBest(id)
		return best[id]
	end

	local food = {
		--- BfA
		-- Deserts
		[257408] = 8, -- crit
		[257413] = 8, -- haste
		[257418] = 8, -- mastery
		[257422] = 8, -- versatility
		[288074] = 17, -- stamina
		-- Large Meals
		[257410] = 10, -- crit
		[297039] = 14, -- crit
		[257415] = 10, -- haste
		[297034] = 14, -- haste
		[257420] = 10, -- mastery
		[297035] = 14, -- mastery
		[257424] = 10, -- versatility
		[297037] = 14, -- versatility
		[288075] = 22, -- stamina
		[297040] = 29, -- stamina
		-- Galley Banquet
		[259448] = 11, -- agi
		[259449] = 11, -- int
		[259452] = 11, -- str
		-- Boralus Blood Sausage
		[290467] = 13, -- agi
		[290468] = 13, -- int
		[290469] = 13, -- str
		-- Bountiful Captain's Feast / Sanguinated Feast
		[259454] = 15, -- agi
		[259455] = 15, -- int
		[259456] = 15, -- str
		-- F.E.A.S.T.
		[297116] = 19, -- agi
		[297117] = 19, -- int
		[297118] = 19, -- str

		--- Shadowlands
		-- Light Meals
		[308430] = 18, -- crit
		[308474] = 18, -- haste
		[308504] = 18, -- mastery
		[308509] = 18, -- versatility
		[308520] = 14, -- stamina
		-- Large Meals
		[308434] = 30, -- crit
		[308488] = 30, -- haste
		[308506] = 30, -- mastery
		[308514] = 30, -- versatility
		[308525] = 22, -- stamina
		-- Surprisingly Palatable Feast
		[327705] = 18, -- agi
		[327704] = 18, -- int
		[327701] = 18, -- str
		-- Feast of Gluttonous Hedonism
		[327709] = 20, -- agi
		[327708] = 20, -- int
		[327706] = 20, -- str
	}

	function module:GetFoodValue(id)
		return food[id]
	end

	local flasks = {
		[251836] = 25, [251837] = 25, [251838] = 25, [251839] = 25, -- Flask (BfA)
		[298836] = 38, [298837] = 38, [298839] = 38, [298841] = 38, -- Greater Flask (BfA)
		[307166] = 70, -- Eternal Flask (Cauldron)
		[307185] = 70, -- Spectral Flask of Power
		[307187] = 105, -- Spectral Stamina Flask
	}

	function module:GetFlaskValue(id)
		return flasks[id]
	end
end

-------------------
-- Output Results

do
	local function send(name, text)
		SendChatMessage(("oRA3> %s"):format(text), "WHISPER", nil, name)
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

		local noFood, noFlasks, noRunes, noBuffs = self:CheckGroup()

		local db = self.db.profile
		if db.whisper then
			local t = GetTime()

			for _, player in next, oRA:GetGroupMembers() do
				wipe(warnings)

				if db.checkFood and noFood[player] then
					warnings[#warnings + 1] = L.noFood
				end

				if db.checkFlask then
					if noFlasks[player] then
						warnings[#warnings + 1] = L.noFlask
					else
						local _, expires = getFlask(player)
						local remaining = expires and (expires - t) or 0
						if remaining > 0 and remaining < 600 then -- triggers weirdly sometimes, not sure why
							whisper(player, L.flaskExpires)
						end
					end
				end

				if db.checkRune and noRunes[player] then
					warnings[#warnings + 1] = L.noRune
				end

				if #warnings > 0 then
					whisper(player, tconcat(warnings, ", "))
				end
			end
		end

		if db.checkFood then
			out(L.noFood, noFood)
		end
		if db.checkFlask then
			out(L.noFlask, noFlasks)
		end
		if db.checkRune then
			out(L.noRune, noRunes)
		end
		if db.checkBuffs then
			out(L.missingBuffs, noBuffs)
		end
	end
end

-------------------
-- Player Check

function module:CheckPlayer(player)
	local cache = playerBuffs[player]
	local t = GetTime()
	if cache and t-cache[0] < PLAYER_CHECK_THROTTLE then
		return unpack(cache)
	end

	if not cache then
		playerBuffs[player] = {}
		cache = playerBuffs[player]
	end

	local flask = getFlask(player)
	local food = getFood(player)
	local rune = getRune(player)
	local vantus = getVantus(player)
	local buffs = cache[5] or {}
	for i = 1, #raidBuffs do
		local _, _, id = self:UnitBuffByIDs(player, raidBuffs[i])
		buffs[i] = id or false
	end

	cache[0] = t
	cache[1] = food
	cache[2] = flask
	cache[3] = rune
	cache[4] = vantus
	cache[5] = buffs

	return food, flask, rune, vantus, buffs
end

-------------------
-- Group Check

do
	local prev = 0

	function module:CheckGroup()
		local t = GetTime()
		if t-prev < GROUP_CHECK_THROTTLE then
			return missingFood, missingFlasks, missingRunes, missingBuffs
		end
		prev = t

		wipe(consumablesList)
		wipe(missingFlasks)
		wipe(missingFood)
		wipe(missingRunes)
		wipe(missingBuffs)

		local groupMembers = oRA:GetGroupMembers()
		if not groupMembers[1] then groupMembers[1] = UnitName("player") end
		for _, player in next, groupMembers do
			if UnitIsConnected(player) and not UnitIsDeadOrGhost(player) and UnitIsVisible(player) then
				local food, flask, rune, vantus, buffs = self:CheckPlayer(player)
				local numBuffs = 0

				if not food then
					missingFood[player] = true
				end

				if not flask then
					missingFlasks[player] = true
				end

				if not rune then
					missingRunes[player] = true
				end

				for i = 1, #buffs do
					if not buffs[i] then
						missingBuffs[raidBuffNames[i]] = true
					else
						numBuffs = numBuffs + 1
					end
				end

				consumablesList[#consumablesList + 1] = {
					player:gsub("%-.*", ""),
					food and (food < 0 and spells[161715] or self:GetFoodValue(food) or YES) or NO, -- 161715 = Eating
					flask and (self:GetFlaskValue(flask) or YES) or NO,
					rune and YES or NO,
					getVantusBoss(vantus) or NO,
					("%d/%d"):format(numBuffs, #buffs),
				}
			end
		end

		return missingFood, missingFlasks, missingRunes, missingBuffs
	end
end
