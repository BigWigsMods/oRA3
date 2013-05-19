
-- Latency is requested/transmitted when opening the list.
-- Latency information will be available from the oRA3 gui for everyone.

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Latency", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

module.VERSION = tonumber(("$Revision: $"):sub(12, -3))

local latency = {}

function module:OnRegister()
	oRA:RegisterList(
		L["Latency"],
		latency,
		L["Name"],
		L["Latency"]
	)
	oRA.RegisterCallback(self, "OnShutdown")
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnCommLatencyRequestUpdate")
	oRA.RegisterCallback(self, "OnCommLatency")

	self:RegisterChatCommand("ralag", "OpenLatencyCheck")
	self:RegisterChatCommand("ralatency", "OpenLatencyCheck")
end

function module:OnShutdown()
	wipe(latency)
end

function module:OpenLatencyCheck()
	oRA:OpenToList(L["Latency"])
end

-- throttled updates when checking the list
do
	local prev = 0
	function module:OnListSelected(event, list)
		if list == L["Latency"] then
			local t = GetTime()
			if t-prev > 10 then
				prev = t
				oRA:SendComm("LatencyRequestUpdate")
			end
		end
	end
end

do
	local prev = 0
	function module:OnCommLatencyRequestUpdate()
		local t = GetTime()
		if t-prev > 5 then
			prev = t
			self:CheckLatency()
		end
	end
end

function module:CheckLatency()
	local _, _, _, latencyWorld = GetNetStats() -- average world latency
	oRA:SendComm("Latency", latencyWorld)
end

-- Latency answer
function module:OnCommLatency(commType, sender, latencyWorld)
	local k = util:inTable(latency, sender, 1)
	if not k then
		latency[#latency + 1] = { sender, latencyWorld }
	else
		latency[k][2] = latencyWorld
	end
	oRA:UpdateList(L["Latency"])
end

