
-- Latency is requested/transmitted when opening the list.
-- Latency information will be available from the oRA3 gui for everyone.

local addonName, scope = ...
local oRA = scope.addon
local util = oRA.util
local module = oRA:NewModule("Latency")
local L = scope.locale

local latency = {}

function module:OnRegister()
	oRA:RegisterList(
		L.latency,
		latency,
		L.name,
		L.home,
		L.world
	)
	oRA.RegisterCallback(self, "OnShutdown")
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnCommReceived")
	oRA.RegisterCallback(self, "OnGroupChanged")

	SLASH_ORALATENCY1 = "/ralag"
	SLASH_ORALATENCY2 = "/ralatency"
	SlashCmdList.ORALATENCY = function()
		oRA:OpenToList(L.latency)
	end
end

function module:OnGroupChanged()
	oRA:UpdateList(L.latency)
end

function module:OnShutdown()
	wipe(latency)
end

do
	local prev = 0
	function module:OnListSelected(event, list)
		if list == L.latency then
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

			oRA:UpdateList(L.latency)
		end
	end
end

