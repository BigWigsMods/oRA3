
-- Inventory information is sent on request by anyone in the raid.
-- Inventory information is only visible to addons which use the API. No oRA3 UI has been added.
--
-- Sample code request for item inventory:
-- 	SendAddonMessage("oRA3", addon:Serialize("InventoryCount", "Healthstone"), "RAID")
-- Serialize() is an Ace 3 library function.
-- Alternatively:
--	SendAddonMessage("oRA3", "^1^SInventoryCount^SHealthstone^^"), "RAID")
--
-- Sample code receive reply:
-- addon:RegisterEvent("CHAT_MSG_ADDON", "CHAT_MSG_ADDON")
--	function addon:CHAT_MSG_ADDON(CHAT_MSG_ADDON, prefix, message, distribution, sender)
-- 		if prefix == "oRA3" and distribution == "RAID" and message and message:find("SInventoryItem") then
--			local itemname, numitems = select(3, message:find("SInventoryItem%^S(.+)%^N(%d+)^"))
--			addon:DOSTUFF(sender, itemname, numitems)
--		end
-- end
--
-- Added 13th April 2011 by Daniel Barron - RaidBuffStatus addon author.

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("Inventory", "AceEvent-3.0")

module.VERSION = tonumber(("$Revision$"):sub(12, -3))

function module:OnRegister()
	oRA.RegisterCallback(self, "OnCommInventoryCount")
end

function module:OnCommInventoryCount(commType, sender, item)
	if item then
		oRA:SendComm("InventoryItem", item, GetItemCount(item))
	end
end
