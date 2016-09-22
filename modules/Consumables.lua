
local _, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Consumables", "AceTimer-3.0")
local L = scope.locale

local tonumber, print, next, select = tonumber, print, next, select
local format = string.format
local tconcat, sort, wipe = table.concat, table.sort, table.wipe
local GetSpellInfo, GetSpellDescription = GetSpellInfo, GetSpellDescription
local UnitIsUnit, IsInGroup, IsInRaid, IsInInstance = UnitIsUnit, IsInGroup, IsInRaid, IsInInstance
local UnitBuff, UnitName, UnitIsConnected, UnitIsVisible = UnitBuff, UnitName, UnitIsConnected, UnitIsVisible
local GetTime, UnitIsDeadOrGhost = GetTime, UnitIsDeadOrGhost

--luacheck: globals oRA3CheckButton ChatFrame_AddMessageEventFilter ChatThrottleLib

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

local getRune
do
	local runes = {
		spells[224001], -- Defiled Augmentation
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
		spells[188031], -- Flask of the Whispered Pact    (Intellect)
		spells[188033], -- Flask of the Seventh Demon     (Agility)
		spells[188034], -- Flask of the Countless Armies  (Strength)
		spells[188035], -- Flask of Ten Thousand Scars    (Stamina)
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
	local eating = spells[192002] -- Food & Drink (Eating)
	local wellFed = spells[19705] -- Well Fed
	-- local food = {
	-- 	-- crit
	-- 	[201223] = 225,
	-- 	[225597] = 300,
	-- 	[225602] = 375,
	-- 	-- mastery
	-- 	[201332] = 225,
	-- 	[225599] = 300,
	-- 	[225604] = 375,
	-- 	-- haste
	-- 	[201330] = 225,
	-- 	[225598] = 300,
	-- 	[225603] = 375,
	-- 	-- versatility
	-- 	[201334] = 225,
	-- 	[225600] = 300,
	-- 	[225605] = 375,
	-- -- aoe damage
	-- 	[201336] = true, -- ~10k
	-- 	[225601] = true, -- ~13.5k
	-- 	[201336] = true, -- ~17k
	-- }

	function getFood(player)
		-- return 17 is the stat value
		local id = select(11, UnitBuff(player, wellFed))
		if id then
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
		L.rune
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
	-- 375 stat food
	local maxFoods = {
		[225602] = true, -- crit
		[225604] = true, -- mastery
		[225603] = true, -- haste
		[225605] = true, -- versatility
		-- need 200 stat / 300 stamina ids
	}
	-- 1300 stat flask
	local maxFlasks = {
		[188031] = true, -- Flask of the Whispered Pact    (Intellect)
		[188033] = true, -- Flask of the Seventh Demon     (Agility)
		[188034] = true, -- Flask of the Countless Armies  (Strength)
		[188035] = true, -- Flask of Ten Thousand Scars    (Stamina)
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
						local flask = getFlask(player)
						local _, _, _, _, _, _, expires = UnitBuff(player, spells[flask])
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
	if cache and t-cache[4] < PLAYER_CHECK_THROTTLE then
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

	cache[1] = food
	cache[2] = flask
	cache[3] = rune
	cache[4] = t

	return food, flask, rune
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
				local food, flask, rune = self:CheckPlayer(player)

				consumablesList[#consumablesList + 1] = {
					player:gsub("%-.*", ""),
					food and (getStatValue(food) or spells[161715]) or NO, -- 161715 = Eating
					flask and (getStatValue(flask) or YES) or NO,
					rune and YES or NO,
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
