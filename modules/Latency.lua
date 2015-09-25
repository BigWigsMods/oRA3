
-- Latency is requested/transmitted when opening the list.
-- This module is a display wrapper for LibLatency.

local addonName, scope = ...
local oRA = scope.addon
local inTable = oRA.util.inTable
local module = oRA:NewModule("Latency")
local L = scope.locale
local LL = LibStub("LibLatency")

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
	oRA.RegisterCallback(self, "OnCommReceived") -- XXX compat
	oRA.RegisterCallback(self, "OnGroupChanged")

	SLASH_ORALATENCY1 = "/ralag"
	SLASH_ORALATENCY2 = "/ralatency"
	SlashCmdList.ORALATENCY = function()
		oRA:OpenToList(L.latency)
	end
end

function module:OnGroupChanged(_, _, members)
	for index = #latency, 1, -1 do
		local player = latency[index][1]
		if not inTable(members, player) then
			tremove(latency, index)
		end
	end
	oRA:UpdateList(L.latency)
end

function module:OnShutdown()
	wipe(latency)
end

do
	local prev = 0
	function module:OnListSelected(_, list)
		if list == L.latency then
			LL:RequestLatency()
			-- XXX compat
			local t = GetTime()
			if t-prev > 15 then
				prev = t
				self:SendComm("QueryLag")
			end
		end
	end
end

do
	local function update(latencyHome, latencyWorld, player, channel)
		if channel == "GUILD" then return end

		local k = inTable(latency, player, 1)
		if not k then
			k = #latency + 1
			latency[k] = { player }
		end
		latency[k][2] = latencyHome
		latency[k][3] = latencyWorld

		oRA:UpdateList(L.latency)
	end
	LL:Register(module, update)

	-- XXX compat
	function module:OnCommReceived(_, sender, prefix, latencyHome, latencyWorld)
		if prefix == "QueryLag" then
			local _, _, latencyHome, latencyWorld = GetNetStats()
			self:SendComm("Lag", latencyHome, latencyWorld)
		elseif prefix == "Lag" then
			update(latencyHome, latencyWorld, sender)
		end
	end
end

