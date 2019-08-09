
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	return
end

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
local missingFood, missingFlasks, missingRunes, missingBuffs = {}, {}, {}, {}

local YES = ("|cff20ff20%s|r"):format(YES)
local NO = ("|cffff2020%s|r"):format(NO)

local spells = setmetatable({}, {
	__index = function(t, k)
		if k == nil then return end
		local name = GetSpellInfo(k)
		if not name then
			--print("oRA3: Invalid spell id", k)
			name = "" -- only print once
		end
		t[k] = name
		return name
	end
})

local getVantus, getVantusBoss
do
	local runes = {
		-- Uldir
		[269276] = 2168, -- Taloc
		[269405] = 2167, -- MOTHER
		[269407] = 2169, -- Zek'voz
		[269408] = 2146, -- Fetid Devourer
		[269409] = 2166, -- Vectis
		[269411] = 2195, -- Zul
		[269412] = 2194, -- Mythrax
		[269413] = 2147, -- G'hunn
		-- Battle of Dazar'alor
		[285535] = 2333, -- Champion of the Light
		[285536] = 2325, -- Grong, the Jungle Lord (Horde)
		[289194] = 2340, -- Grong, the Revenant (Alliance)
		[285537] = 2323, -- Jadefire Masters
		[289196] = 2323, -- Jadefire Masters
		[285538] = 2342, -- Opulence
		[285539] = 2330, -- Conclave of the Chosen
		[285540] = 2335, -- King Rastakhan
		[285541] = 2334, -- High Tinker Mekkatorque
		[285542] = 2337, -- Stormwall Blockade
		[285543] = 2343, -- Lady Jaina Proudmoore
		-- Crucible of Storms
		[285900] = 2328, -- The Restless Cabal
		[285901] = 2332, -- Uu'nat, Harbinger of the Void
		-- The Eternal Palace
		[298622] = 2352, -- Abyssal Commander Sivara
		[298640] = 2353, -- Radiance of Aszhara
		[298642] = 2347, -- Blackwater Behemoth
		[298643] = 2354, -- Lady Ashvane
		[298644] = 2351, -- Orgozoa
		[298645] = 2359, -- The Queen's Court
		[298646] = 2349, -- Za'qul, Harbinger of Ny'alotha
		[302914] = 2361, -- Queen Azshara

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
		270058, -- Battle-Scarred Augmentation (BfA)
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
		264760, -- War-Scroll of Intellect
	},
	{ -- Stamina
		21562,  -- Power Word: Fortitude
		264764, -- War-Scroll of Fortitude
	},
	{ -- Attack Power
		6673,   -- Battle Shout
		264761, -- War-Scroll of Battle Shout
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
		[297039] = true, -- crit
		[297034] = true, -- haste
		[297035] = true, -- mastery
		[297037] = true, -- versatility
		[297116] = true, -- agi
		[297117] = true, -- int
		[297118] = true, -- str
		[297040] = true, -- sta (stamina is not gained from feasts now)
		[297119] = true, -- sta (not sure where this comes from, better not be a feast)

		-- Flasks
		[298836] = true, -- agi
		[298837] = true, -- int
		[298839] = true, -- sta
		[298841] = true, -- str

		-- Buffs
		[1459] = true,   -- Arcane Intellect
		[21562] = true,  -- Power Word: Fortitude
		[264761] = true, -- War-Scroll of Battle Shout
	}

	function module:IsBest(id)
		return best[id]
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

	-- XXX this need to be updated for async loading
	local function getStatValue(id)
		local desc = GetSpellDescription(id)
		if desc then
			local value = tonumber(desc:match("%d+")) or 0
			return value >= 75 and tostring(value) or YES
		end
	end

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
					food and (getStatValue(food) or spells[161715]) or NO, -- 161715 = Eating
					flask and (getStatValue(flask) or YES) or NO,
					rune and YES or NO,
					getVantusBoss(vantus) or NO,
					("%d/%d"):format(numBuffs, #buffs),
				}
			end
		end

		return missingFood, missingFlasks, missingRunes, missingBuffs
	end
end
