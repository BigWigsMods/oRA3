
local _, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Consumables", "AceTimer-3.0")
local L = scope.locale

local tonumber, print, next, select = tonumber, print, next, select
local format = string.format
local tconcat, sort, wipe = table.concat, table.sort, table.wipe
local GetSpellInfo, GetSpellDescription = GetSpellInfo, GetSpellDescription
local UnitIsUnit, IsInGroup, IsInRaid, IsInInstance = UnitIsUnit, IsInGroup, IsInRaid, IsInInstance
local UnitName, UnitIsConnected, UnitIsVisible = UnitName, UnitIsConnected, UnitIsVisible
local GetTime, UnitIsDeadOrGhost = GetTime, UnitIsDeadOrGhost

--luacheck: globals oRA3CheckButton ChatFrame_AddMessageEventFilter

local GROUP_CHECK_THROTTLE = 0.8
local PLAYER_CHECK_THROTTLE = 0.3

local consumablesList = {}
local playerBuffs = {}
local missingFood, missingFlasks, missingRunes = {}, {}, {}

local YES = ("|cff20ff20%s|r"):format(YES)
local NO = ("|cffff2020%s|r"):format(NO)

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
		-- Emerald Nightmare
		[192761] = 1703, -- Nythndra
		[192765] = 1744, -- Elerethe
		[191464] = 1667, -- Ursoc
		[192762] = 1738, -- Il'gynoth
		[192763] = 1704, -- Dragons
		[192766] = 1750, -- Cenarius
		[192764] = 1726, -- Xavius
		-- Trial of Valor
		[229174] = 1819, -- Odyn
		[229175] = 1830, -- Guarm
		[229176] = 1829, -- Helya
		-- Nighthold
		[192767] = 1706, -- Skorpyron
		[192768] = 1725, -- Chronomatic Anomaly
		[192769] = 1731, -- Trilliax
		[192770] = 1751, -- Aluriel
		[192771] = 1762, -- Tichondrius
		[192773] = 1713, -- Krosus
		[192772] = 1761, -- Tel'arn
		[192774] = 1732, -- Etraeus
		[192775] = 1743, -- Elisande
		[192776] = 1737, -- Gul'dan
		-- Tomb of Sargeras
		[237821] = 1862, -- Goroth
		[237828] = 1867, -- Demonic Inquisition
		[237824] = 1856, -- Harjatan
		[237826] = 1861, -- Sassz'ine
		[237822] = 1903, -- Sisters of the Moon
		[237827] = 1896, -- The Desolate Host
		[237823] = 1897, -- Maiden of Vigilance
		[237820] = 1873, -- Fallen Avatar
		[237825] = 1898, -- Kil'jaeden
		-- Antorus
		[250153] = 1992, -- Garothi Worldbreaker
		[250156] = 1987, -- Felhounds of Sargeras
		[250167] = 1997, -- Antoran High Command
		[250160] = 1985, -- Portal Keeper Hasabel
		[250150] = 2025, -- Eonar the Lifebinder
		[250158] = 2009, -- Imonar the Soulhunter
		[250148] = 2004, -- Kin'garoth
		[250165] = 1983, -- Varimathras
		[250163] = 1986, -- The Coven of Shivarra
		[250144] = 1984, -- Aggramar
		[250146] = 2031, -- Argus the Unmaker
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
		224001, -- Defiled Augmentation (Legion)
		-- 270058, -- Battle-Scarred Augmentation (BfA)
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
		-- Legion
		188031, -- Flask of the Whispered Pact    (Intellect)
		188033, -- Flask of the Seventh Demon     (Agility)
		188034, -- Flask of the Countless Armies  (Strength)
		188035, -- Flask of Ten Thousand Scars    (Stamina)
		-- BfA
		-- 251836, -- Flask of the Currents          (Agility)
		-- 251837, -- Flask of Endless Fathoms       (Intellect)
		-- 251838, -- Flask of the Vast Horizon      (Stamina)
		-- 251839, -- Flask of the Undertow          (Strength)
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
		L.vantus
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
	local maxFoods = {
		[225602] = true, -- crit
		[225603] = true, -- haste
		[225604] = true, -- mastery
		[225605] = true, -- versatility
		[201638] = true, -- str
		[201639] = true, -- agi
		[201640] = true, -- int
		-- [201641] = true, -- sta
		[185736] = true, -- versatility (Sugar-Crusted Fish Feast, gives +1%)
		-- [257410] = true, -- crit
		-- [257415] = true, -- haste
		-- [257420] = true, -- mastery
		-- [257424] = true, -- versatility
		-- [259454] = true, -- agi
		-- [259455] = true, -- int
		-- [259456] = true, -- str
		-- -- [259457] = true, -- sta
	}
	-- 1300 stat flask
	local maxFlasks = {
		[188031] = true, -- Flask of the Whispered Pact    (Intellect)
		[188033] = true, -- Flask of the Seventh Demon     (Agility)
		[188034] = true, -- Flask of the Countless Armies  (Strength)
		[188035] = true, -- Flask of Ten Thousand Scars    (Stamina)
		-- [251836] = true, -- Flask of the Currents          (Agility)
		-- [251837] = true, -- Flask of Endless Fathoms       (Intellect)
		-- [251838] = true, -- Flask of the Vast Horizon      (Stamina)
		-- [251839] = true, -- Flask of the Undertow          (Strength)
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

		local noFood, noFlasks, noRunes = self:CheckGroup()

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
						local flask, expires = getFlask(player)
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
	end
end

-------------------
-- Player Check

function module:CheckPlayer(player)
	local cache = playerBuffs[player]
	local t = GetTime()
	if cache and t-cache[0] < PLAYER_CHECK_THROTTLE then
		local food, flask, rune = unpack(cache)
		return food, flask, rune
	end
	if not cache then
		playerBuffs[player] = {}
		cache = playerBuffs[player]
	end

	local flask = getFlask(player)
	local food = getFood(player)
	local rune = getRune(player)
	local vantus = getVantus(player)

	cache[0] = t
	cache[1] = food
	cache[2] = flask
	cache[3] = rune
	cache[4] = vantus

	return food, flask, rune, vantus
end

-------------------
-- Group Check

do
	local prev = 0

	local function getStatValue(id)
		local desc = GetSpellDescription(id)
		if desc then
			local value = tonumber(desc:match("%d+")) or 0
			return value >= 75 and value or YES
		end
	end

	function module:CheckGroup()
		local t = GetTime()
		if t-prev < GROUP_CHECK_THROTTLE then
			return missingFood, missingFlasks, missingRunes
		end
		prev = t

		wipe(consumablesList)
		wipe(missingFlasks)
		wipe(missingFood)
		wipe(missingRunes)

		local groupMembers = oRA:GetGroupMembers()
		if not groupMembers[1] then groupMembers[1] = UnitName("player") end
		for _, player in next, groupMembers do
			if UnitIsConnected(player) and not UnitIsDeadOrGhost(player) and UnitIsVisible(player) then
				local food, flask, rune, vantus = self:CheckPlayer(player)

				consumablesList[#consumablesList + 1] = {
					player:gsub("%-.*", ""),
					food and (getStatValue(food) or spells[161715]) or NO, -- 161715 = Eating
					flask and (getStatValue(flask) or YES) or NO,
					rune and YES or NO,
					getVantusBoss(vantus) or NO,
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
			end
		end

		return missingFood, missingFlasks, missingRunes
	end
end
