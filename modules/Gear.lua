
-- Gear status is requested/transmitted when opening the list.

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Gear")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

module.VERSION = tonumber(("$Revision$"):sub(12, -3))

local gearTbl = {}

function module:OnRegister()
	oRA:RegisterList(
		L["Gear"],
		gearTbl,
		L["Name"],
		L["Item Level"],
		L["Missing Gems"],
		L["Missing Enchants"]
	)
	oRA.RegisterCallback(self, "OnShutdown")
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnCommReceived")
	oRA.RegisterCallback(self, "OnGroupChanged")

	SLASH_ORAGEAR1 = "/ragear"
	SlashCmdList.ORAGEAR = function()
		oRA:OpenToList(L["Gear"])
	end
end

function module:OnGroupChanged()
	oRA:UpdateList(L["Gear"])
end

function module:OnShutdown()
	wipe(gearTbl)
end

do
	local prev = 0
	function module:OnListSelected(event, list)
		if list == L["Gear"] then
			local t = GetTime()
			if t-prev > 20 then
				prev = t
				self:SendComm("QueryGear")
			end
		end
	end
end

do
	local prev = 0
	local enchantableItems = {
		false, -- INVSLOT_HEAD -- 1
		false, -- INVSLOT_NECK -- 2
		true, -- INVSLOT_SHOULDER -- 3
		false, -- INVSLOT_BODY -- 4
		true, -- INVSLOT_CHEST -- 5
		false, -- INVSLOT_WAIST -- 6
		true, -- INVSLOT_LEGS -- 7
		true, -- INVSLOT_FEET -- 8
		true, -- INVSLOT_WRIST -- 9
		true, -- INVSLOT_HAND -- 10
		false, -- INVSLOT_FINGER1 -- 11
		false, -- INVSLOT_FINGER2 -- 12
		false, -- INVSLOT_TRINKET1 -- 13
		false, -- INVSLOT_TRINKET2 -- 14
		true, -- INVSLOT_BACK -- 15
		true, -- INVSLOT_MAINHAND -- 16
		true, -- INVSLOT_OFFHAND -- 17
	}
	function module:OnCommReceived(_, sender, prefix, ilvl, gems, enchants)
		if prefix == "QueryGear" then
			local t = GetTime()
			if t-prev > 20 then
				prev = t

				local all, equipped = GetAverageItemLevel()
				local missingEnchants, emptySockets = 0, 0

				for i = 1, 17 do
					local itemLink = GetInventoryItemLink("player", i)
					if itemLink then
						-- http://www.wowpedia.org/ItemString
						-- item:itemId:enchantId:jewelId1:jewelId2:jewelId3:jewelId4:suffixId:uniqueId:linkLevel:reforgeId:upgradeId
						local enchant, gem1, gem2, gem3, gem4 = itemLink:match("item:%d+:(%d+):(%d+):(%d+):(%d+):(%d+):")

						-- Handle missing enchants
						if enchantableItems[i] and enchant == "0" then
							missingEnchants = missingEnchants + 1
						end

						-- Handle missing gems
						local totalItemSockets = 0
						-- WAIST, add +1 as the belt buckle doesn't contribute to the EMPTY_SOCKET_GEM entries
						if i == 6 then
							totalItemSockets = 1
						end

						local statsTable = GetItemStats(itemLink)
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
					end
				end

				self:SendComm("Gear", floor(equipped), emptySockets, missingEnchants)
			end
		elseif prefix == "Gear" then
			local k = util.inTable(gearTbl, sender, 1)
			if not k then
				k = #gearTbl + 1
				gearTbl[k] = { sender }
			end
			gearTbl[k][2] = tonumber(ilvl)
			gearTbl[k][3] = tonumber(gems)
			gearTbl[k][4] = tonumber(enchants)

			oRA:UpdateList(L["Gear"])
		end
	end
end

