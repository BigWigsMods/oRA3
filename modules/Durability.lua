
-- Durability is requested/transmitted when opening the list.
-- This module is a display wrapper for LibDurability.

local addonName, scope = ...
local oRA = scope.addon
local util = oRA.util
local module = oRA:NewModule("Durability")
local L = scope.locale
local LD = LibStub("LibDurability")

local durability = {}

function module:OnRegister()
	-- should register durability table with the oRA3 core GUI for sortable overviews
	oRA:RegisterList(
		L.durability,
		durability,
		L.name,
		L.durability,
		L.broken
	)
	oRA.RegisterCallback(self, "OnShutdown")
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnCommReceived") -- XXX compat
	oRA.RegisterCallback(self, "OnGroupChanged")

	SLASH_ORADURABILITY1 = "/radur"
	SLASH_ORADURABILITY2 = "/radurability"
	SlashCmdList.ORADURABILITY = function()
		oRA:OpenToList(L.durability)
	end
end

function module:OnGroupChanged()
	oRA:UpdateList(L.durability)
end

function module:OnShutdown()
	wipe(durability)
end

function module:OnListSelected(event, list)
	if list == L.durability then
		LD:RequestDurability()
		self:SendComm("RequestUpdate") -- XXX compat
	end
end

do
	local function update(percent, broken, player)
		local k = util.inTable(durability, player, 1)
		if not k then
			durability[#durability + 1] = { player }
			k = #durability
		end
		durability[k][2] = floor(tonumber(percent))
		durability[k][3] = tonumber(broken)

		oRA:UpdateList(L.durability)
	end
	LD:Register(module, update)

	-- XXX compat
	function module:OnCommReceived(_, sender, prefix, perc, minimum, broken)
		if prefix == "RequestUpdate" then
			local perc, broken = LD:GetDurability()
			self:SendComm("Durability", perc, perc, broken)
		elseif prefix == "Durability" then
			update(perc, broken, sender)
		end
	end
end

