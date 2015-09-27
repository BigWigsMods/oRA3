
-- Gear status is requested/transmitted when opening the list.

local addonName, scope = ...
local oRA = scope.addon
local inTable = oRA.util.inTable
local module = oRA:NewModule("Gear")
local L = scope.locale

local gearTbl = {}
local syncList = {} -- list of people we have syncs from

function module:OnRegister()
	oRA:RegisterList(
		L.gear,
		gearTbl,
		L.name,
		L.itemLevel,
		L.missingGems,
		L.missingEnchants
	)
	oRA.RegisterCallback(self, "OnShutdown")
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnCommReceived")
	oRA.RegisterCallback(self, "OnGroupChanged")
	oRA.RegisterCallback(self, "OnPlayerInspect")

	SLASH_ORAGEAR1 = "/ragear"
	SlashCmdList.ORAGEAR = function()
		oRA:OpenToList(L.gear)
	end
end

function module:OnGroupChanged(_, _, members)
	for index = #gearTbl, 1, -1 do
		local player = gearTbl[index][1]
		if not inTable(members, player) then
			tremove(gearTbl, index)
			syncList[player] = nil
		end
	end
	oRA:UpdateList(L.gear)
end

function module:OnShutdown()
	wipe(gearTbl)
	wipe(syncList)
end

do
	local prev = 0
	function module:OnListSelected(_, list)
		if list == L.gear then
			local t = GetTime()
			if t-prev > 15 then
				prev = t
				self:SendComm("QueryGear")
			end
		end
	end
end

-- we're just piggy-backing off Cooldowns (and any other inspect request)
-- should probably handle requeueing people that give us incomplete info
-- but odds are something will trigger it for us (eg, mouseover talent scanning)
function module:OnPlayerInspect(_, guid, unit)
	local player = self:UnitName(unit)
	if not player or syncList[player] or not CheckInteractDistance(unit, 1) then return end
	if inTable(gearTbl, player, 1) then return end

	local enchants, gems, ilvl = self:ScanGear(unit, 1)
	if ilvl and ilvl > 0 then
		local k = inTable(gearTbl, player, 1)
		if not k then
			k = #gearTbl + 1
			gearTbl[k] = { player }
		end
		gearTbl[k][2] = floor(tonumber(ilvl))
		gearTbl[k][3] = tonumber(gems)
		gearTbl[k][4] = tonumber(enchants)

		oRA:UpdateList(L.gear)
	end
end

function module:OnCommReceived(_, sender, prefix, ilvl, gems, enchants)
	if prefix == "QueryGear" then
		local missingEnchants, emptySockets, equipped = self:ScanGear("player", 0)
		self:SendComm("Gear", floor(equipped), emptySockets, missingEnchants)
	elseif prefix == "Gear" then
		local k = inTable(gearTbl, sender, 1)
		if not k then
			k = #gearTbl + 1
			gearTbl[k] = { sender }
		end
		gearTbl[k][2] = tonumber(ilvl)
		gearTbl[k][3] = tonumber(gems)
		gearTbl[k][4] = tonumber(enchants)

		oRA:UpdateList(L.gear)
		syncList[sender] = true
	end
end

do
	-- Let the game figure out the item level
	local tooltip = CreateFrame("GameTooltip", "oRA3GearTooltipScanner", nil, "GameTooltipTemplate")
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")

	local ITEM_LEVEL_PATTERN = "^"..ITEM_LEVEL:gsub("%%d", "(.-)").."$"
	function module:GetItemLevel(unit, slot)
		local item = tooltip:SetInventoryItem(unit, slot, true)
		if not item then return 0 end
		for i = 2, tooltip:NumLines() do
			local text = _G["oRA3GearTooltipScannerTextLeft"..i]:GetText()
			local ilvl = text and text:match(ITEM_LEVEL_PATTERN)
			if ilvl then
				return tonumber(ilvl)
			end
		end
		return 0
	end
end

do
	local statsTable = {}
	local enchantableItems = {
		false, -- INVSLOT_HEAD -- 1
		true, -- INVSLOT_NECK -- 2
		false, -- INVSLOT_SHOULDER -- 3
		false, -- INVSLOT_BODY -- 4
		false, -- INVSLOT_CHEST -- 5
		false, -- INVSLOT_WAIST -- 6
		false, -- INVSLOT_LEGS -- 7
		false, -- INVSLOT_FEET -- 8
		false, -- INVSLOT_WRIST -- 9
		false, -- INVSLOT_HAND -- 10
		true, -- INVSLOT_FINGER1 -- 11
		true, -- INVSLOT_FINGER2 -- 12
		false, -- INVSLOT_TRINKET1 -- 13
		false, -- INVSLOT_TRINKET2 -- 14
		true, -- INVSLOT_BACK -- 15
		true, -- INVSLOT_MAINHAND -- 16
		false, -- INVSLOT_OFFHAND -- 17
	}
	function module:ScanGear(unit, count)
		if count > 5 then return end
		local isInspecting = unit ~= "player"

		local missingEnchants, emptySockets, averageItemLevel, missingSlots = 0, 0, 0, 0
		local hasOffhand = false
		for i = 1, 17 do
			local itemLink = GetInventoryItemLink(unit, i)
			if not itemLink then
				missingSlots = missingSlots + 1
			elseif i ~= 4 then -- skip the shirt
				-- http://www.wowpedia.org/ItemString
				-- item:itemId:enchantId:jewelId1:jewelId2:jewelId3:jewelId4:suffixId:uniqueId:linkLevel:reforgeId:upgradeId
				local enchant, gem1, gem2, gem3, gem4 = itemLink:match("item:%d+:(%d+):(%d+):(%d+):(%d+):(%d+):")

				-- Handle missing enchants
				if enchantableItems[i] and enchant == "0" then
					missingEnchants = missingEnchants + 1
				end

				-- Handle missing gems
				local totalItemSockets = 0

				wipe(statsTable)
				GetItemStats(itemLink, statsTable)
				for k, v in next, statsTable do
					if k:find("EMPTY_SOCKET_", nil, true) then
						totalItemSockets = totalItemSockets + v
					end
				end

				local filledSockets = (gem1 ~= "0" and 1 or 0) + (gem2 ~= "0" and 1 or 0) + (gem3 ~= "0" and 1 or 0) + (gem4 ~= "0" and 1 or 0)
				local finalCount = totalItemSockets - filledSockets
				if finalCount > 0 then
					emptySockets = emptySockets + finalCount
				end

				-- Handle item level
				if isInspecting then
					local itemLevel = self:GetItemLevel(unit, i)
					averageItemLevel = averageItemLevel + itemLevel

					if i == 17 then
						hasOffhand = true
					end
				end
			end
		end

		if not isInspecting then
			local _, equipped = GetAverageItemLevel()
			averageItemLevel = equipped
		elseif averageItemLevel == 0 or missingSlots > 2 then -- shirt + off hand
			-- try and filter out people still out of range
			self:ScanGear(unit, count + 1)
			return
		else
			averageItemLevel = averageItemLevel / (hasOffhand and 16 or 15)
		end

		return missingEnchants, emptySockets, averageItemLevel
	end
end

