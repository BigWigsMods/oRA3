
if not GetAddOnEnableState then return end -- WoD only

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("BattleRes")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

module.VERSION = tonumber(("$Revision: 712 $"):sub(12, -3))

local initialAmount = 1
local f = CreateFrame("Frame")

function module:OnRegister()
	oRA.RegisterCallback(self, "OnShutdown")
end

--[[
difficultyID 14 (Normal flex10-30, previously "Flex")
difficultyID 15 (Heroic flex10-30, new)
difficultyID 16 (Mythic 20, new)
difficultyID 17 (Looking For Raid flex10-30, new)
]]

function module:OnEnable()
	self:RegisterEvent("ENCOUNTER_START")
	self:RegisterEvent("ENCOUNTER_END")
end

function module:ENCOUNTER_START()
	print("oRA3:", initialAmount, GetNumGroupMembers())
	print("oRA3: Gaining a res every", (90/GetNumGroupMembers())*60, "seconds.")
	f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function module:ENCOUNTER_END()
	f:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	print("oRA3: Resses back to normal.")
end

function module:OnShutdown()
	
end

f:SetScript("OnEvent", function(_, _, _, event, ...)
	if event == "SPELL_RESURRECT" then
		print("oRA3:", event, ...)
	end
end)

