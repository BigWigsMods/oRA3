
-- Gear status is requested/transmitted when opening the list.

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
if oRA then return end -- DISABLED
local util = oRA.util
local module = oRA:NewModule("Gear")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

module.VERSION = tonumber(("$Revision: $"):sub(12, -3))

local gearTbl = {}

function module:OnRegister()
	oRA:RegisterList(
		"GEAR",
		gearTbl,
		L["Name"],
		"LVL",
		"MISSING GEMS",
		"MISSING ENCH"
	)
	oRA.RegisterCallback(self, "OnShutdown")
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnCommReceived")

	SLASH_ORALATENCY1 = "/ragear"
	SlashCmdList.ORAGEAR = function()
		oRA:OpenToList("GEAR")
	end
end

function module:OnShutdown()
	wipe(gearTbl)
end

do
	local prev = 0
	function module:OnListSelected(event, list)
		if list == "GEAR" then
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
					if not itemLink then
						print(i)
					else
						local enchant, gem1, gem2, gem3, gem4 = itemLink:match("item:%d+:(%d+):(%d+):(%d+):(%d+):(%d+)")
						if enchantableItems[i] and enchant == "0" then
							missingEnchants = missingEnchants + 1
						end
					end
				end

				self:SendComm("Gear", floor(equipped), emptySockets, missingEnchants)
			end
		elseif prefix == "Gear" then
			local k = util:inTable(gearTbl, sender, 1)
			if not k then
				k = #gearTbl + 1
				gearTbl[k] = { sender }
			end
			gearTbl[k][2] = ilvl
			gearTbl[k][3] = gems
			gearTbl[k][4] = enchants

			oRA:UpdateList("GEAR")
		end
	end
end

