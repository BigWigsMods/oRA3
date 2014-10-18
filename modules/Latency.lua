
-- Latency is requested/transmitted when opening the list.
-- Latency information will be available from the oRA3 gui for everyone.

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Latency")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

module.VERSION = tonumber(("$Revision$"):sub(12, -3))

local latency = {}

function module:OnRegister()
	oRA:RegisterList(
		L["Latency"],
		latency,
		L["Name"],
		L["Home"],
		L["World"]
	)
	oRA.RegisterCallback(self, "OnShutdown")
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnCommReceived")
	oRA.RegisterCallback(self, "OnGroupChanged")

	SLASH_ORALATENCY1 = "/ralag"
	SLASH_ORALATENCY2 = "/ralatency"
	SlashCmdList.ORALATENCY = function()
		oRA:OpenToList(L["Latency"])
	end
end

function module:OnGroupChanged()
	oRA:UpdateList(L["Latency"])
end

function module:OnShutdown()
	wipe(latency)
end

do
	local prev = 0
	function module:OnListSelected(event, list)
		if list == L["Latency"] then
			local t = GetTime()
			if t-prev > 7 then
				prev = t
				self:SendComm("QueryLag")
			end
		end
	end
end

do
	local prev = 0
	function module:OnCommReceived(_, sender, prefix, latencyHome, latencyWorld)
		if prefix == "QueryLag" then
			local t = GetTime()
			if t-prev > 7 then
				prev = t
				local _, _, latencyHome, latencyWorld = GetNetStats() -- average world latency
				self:SendComm("Lag", latencyHome, latencyWorld)
			end
		elseif prefix == "Lag" then
			local k = util.inTable(latency, sender, 1)
			if not k then
				k = #latency + 1
				latency[k] = { sender }
			end
			latency[k][2] = tonumber(latencyHome)
			latency[k][3] = tonumber(latencyWorld)

			oRA:UpdateList(L["Latency"])
		end
	end
end

