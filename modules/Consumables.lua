
local _, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Consumables", "AceTimer-3.0")
local L = scope.locale

local format = string.format
local tconcat, sort, wipe = table.concat, table.sort, table.wipe
local GetSpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
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
		local name = GetSpellName(k)
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
		-- Vault of the Incarnates
		[384192] = 2480, [384201] = 2480, [384203] = 2480, -- Eranog
		[384214] = 2486, [384215] = 2486, [384216] = 2486, -- The Primal Council
		[384208] = 2500, [384209] = 2500, [384210] = 2500, -- Terros
		[384221] = 2482, [384220] = 2482, [384222] = 2482, -- Sennarth
		[384227] = 2502, [384228] = 2502, [384229] = 2502, -- Dathea
		[384239] = 2491, [384240] = 2491, [384241] = 2491, -- Kurog
		[384233] = 2493, [384234] = 2493, [384235] = 2493, -- Diurna
		[384245] = 2499, [384246] = 2499, [384247] = 2499, -- Raszageth

		-- Aberrus
		[409626] = 2524, [411523] = 2524, [411526] = 2524, -- Assault of the Zaqali
		[409618] = 2523, [411536] = 2523, [411537] = 2523, -- Echo of Neltharion
		[409619] = 2522, [411469] = 2522, [411507] = 2522, [411513] = 2522, -- Kazzara, the Hellforged
		[409640] = 2527, [411534] = 2527, [411535] = 2527, -- Magmorax
		[409627] = 2525, [411527] = 2525, [411528] = 2525, -- Rashok, the Elder
		[409644] = 2520, [411538] = 2520, [411539] = 2520, -- Scalecommander Sarkareth
		[409622] = 2529, [411514] = 2529, [411515] = 2529, -- The Amalgamation Chamber
		[409624] = 2530, [411516] = 2530, [411517] = 2530, -- The Forgotten Experiments
		[409638] = 2532, [411530] = 2532, [411532] = 2532, -- The Vigilant Steward, Zskarn

		-- Amirdrassil
		[425905] = 2564, [425934] = 2564, [425943] = 2564, -- Gnarlroot
		[425906] = 2554, [425935] = 2554, [425944] = 2554, -- Igira the Cruel
		[425907] = 2557, [425936] = 2557, [425945] = 2557, -- Volcoross
		[425908] = 2555, [425937] = 2555, [425946] = 2555, -- Council of Dreams
		[425909] = 2553, [425938] = 2553, [425947] = 2553, -- Larodar, Keeper of the Flame
		[425910] = 2556, [425939] = 2556, -- Nymue, Weaver of the Cycle (XXX missing r3?)
		[425911] = 2563, [425940] = 2563, [425951] = 2563, -- Smolderon
		[425912] = 2565, [425941] = 2565, [425948] = 2565, -- Tindral Sageswift
		[425913] = 2519, [425949] = 2519, [425942] = 2519, -- Fyrakk
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
		367405, -- Eternal Augmentation
		393438, -- Draconic Augmentation
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
		-- Shadowlands
		307166, -- Eternal Flask (Cauldron)
		307185, -- Spectral Flask of Power
		307187, -- Spectral Stamina Flask
		-- Dragonflight
		370652, -- Phial of Static Empowerment
		371036, -- Phial of Icy Preservation
		371172, -- Phial of Tepid Versatility
		371186, -- Charged Phial of Alacrity
		371204, -- Phial of Still Air
		371339, -- Phial of Elemental Chaos
		371354, -- Phial of the Eye in the Storm
		371386, -- Phial of Charged Isolation
		373257, -- Phial of Glacial Fury
		374000, -- Iced Phial of Corrupting Rage
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
	{ -- Attack Power
		6673,   -- Battle Shout
	},
	{ -- Stamina
		21562,  -- Power Word: Fortitude
	},
	{ -- Intellect
		1459,   -- Arcane Intellect
	},
	{ -- Versatility
		1126,   -- Mark of the Wild
	},
}
local raidBuffNames = {
	(GetSpellName(6673)),  -- ITEM_MOD_ATTACK_POWER_SHORT,
	(GetSpellName(21562)), -- ITEM_MOD_STAMINA_SHORT,
	(GetSpellName(1459)),  -- ITEM_MOD_INTELLECT_SHORT,
	(GetSpellName(1126)),  -- ITEM_MOD_VERSATILITY,
}
local raidBuffProviders = {
	"WARRIOR",
	"PRIEST",
	"MAGE",
	"DRUID",
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
	oRA:SetListSort(L.buffs,
		{[YES] = 1, [NO] = 0},
		{[YES] = 1, [NO] = 0},
		{[YES] = 1, [NO] = 0},
		{[NO] = ""},
		{ -- these are currently clamped, but just in case
			["1/1"] = 1, ["2/1"] = 2, ["3/1"] = 3, ["4/1"] = 4, ["0/1"] = 0,
			["1/2"] = 1, ["2/2"] = 2, ["3/2"] = 3, ["4/2"] = 4, ["0/2"] = 0,
			["1/3"] = 1, ["2/3"] = 2, ["3/3"] = 3, ["4/3"] = 4, ["0/3"] = 0,
			["1/4"] = 1, ["2/4"] = 2, ["3/4"] = 3, ["4/4"] = 4, ["0/4"] = 0,
		}
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
		[396092] = true, -- Fated Fortune Cookie/Feast (76 primary stat)
		[382145] = true, -- haste
		[382146] = true, -- crit
		[382149] = true, -- vers
		[382150] = true, -- mastery
		[382152] = true, -- haste/crit
		[382153] = true, -- haste/vers
		[382154] = true, -- haste/mastery
		[382155] = true, -- crit/vers
		[382156] = true, -- crit/mastery
		[382157] = true, -- vers/mastery

		-- Flasks
		[373257] = true, -- Phial of Glacial Fury
		[371172] = true, -- Phial of Tepid Versatility
		[371339] = true, -- Phial of Elemental Chaos
		[370652] = true, -- Phial of Static Empowerment
		[371354] = true, -- Phial of the Eye in the Storm
		[374000] = true, -- Iced Phial of Corrupting Rage
		[371386] = true, -- Phial of Charged Isolation

		-- Rune
		[393438] = true, -- Draconic Augmentation
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

		--- Dragonflight
		[382145] = 70, -- haste
		[382146] = 70, -- crit
		[382149] = 70, -- vers
		[382150] = 45, -- mastery
		[382152] = 45, -- haste/crit
		[382153] = 45, -- haste/vers
		[382154] = 45, -- haste/mastery
		[382155] = 45, -- crit/vers
		[382156] = 45, -- crit/mastery
		[382157] = 45, -- vers/mastery
		[382230] = 22, -- str
		[382231] = 22, -- agi
		[382232] = 22, -- int
		[382234] = 32, -- str
		[382235] = 32, -- agi
		[382236] = 32, -- int
		[382246] = 60, -- sta
		[382247] = 90, -- sta
		[393372] = 176, -- Feast (+lowest stat)
		[396092] = 76, -- Fated Fortune Cookie/Feast (+primary stat)
	}

	function module:GetFoodValue(id)
		return food[id]
	end

	local flasks = {
		[251836] = 39, [251837] = 39, [251838] = 39, [251839] = 39, -- Flask (BfA)
		[298836] = 59, [298837] = 59, [298839] = 59, [298841] = 59, -- Greater Flask (BfA)
		[307185] = 69, -- Spectral Flask of Power
		[307187] = 104, -- Spectral Stamina Flask
		-- XXX Dragonflight flasks are all over the place, just show the buff texture?
		-- allowing a tooltip for food and flasks would be good
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
		if oRA:HasClassMembers(raidBuffProviders[i]) then
			local _, _, id = self:UnitBuffByIDs(player, raidBuffs[i])
			buffs[i] = id or false
		else
			buffs[i] = nil
		end
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

		local numRaidBuffs = 0
		for i = 1, #raidBuffs do
			if oRA:HasClassMembers(raidBuffProviders[i]) then
				numRaidBuffs = numRaidBuffs + 1
			end
		end

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

				for i = 1, #raidBuffs do
					if buffs[i] then
						numBuffs = numBuffs + 1
					elseif buffs[i] == false then -- missing while available
						missingBuffs[raidBuffNames[i]] = true
					end
				end

				consumablesList[#consumablesList + 1] = {
					player:gsub("%-.*", ""),
					food and (food < 0 and spells[161715] or self:GetFoodValue(food) or YES) or NO, -- 161715 = Eating
					flask and (self:GetFlaskValue(flask) or YES) or NO,
					rune and YES or NO,
					getVantusBoss(vantus) or NO,
					("%d/%d"):format(numBuffs, numRaidBuffs),
				}
			else
				consumablesList[#consumablesList + 1] = {
					player:gsub("%-.*", ""),
					nil,
					nil,
					nil,
					nil,
					nil,
				}
			end
		end

		return missingFood, missingFlasks, missingRunes, missingBuffs
	end
end
