
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	return
end

-- Durability is requested/transmitted when opening the list.
-- This module is a display wrapper for LibDurability.

local addonName, scope = ...
local oRA = scope.addon
local inTable = oRA.util.inTable
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
	oRA.RegisterCallback(self, "OnGroupChanged")

	SLASH_ORADURABILITY1 = "/radur"
	SLASH_ORADURABILITY2 = "/radurability"
	SlashCmdList.ORADURABILITY = function()
		oRA:OpenToList(L.durability)
	end
end

function module:OnGroupChanged(_, _, members)
	for index = #durability, 1, -1 do
		local player = durability[index][1]
		if not inTable(members, player) then
			tremove(durability, index)
		end
	end
	oRA:UpdateList(L.durability)
end


function module:OnShutdown()
	wipe(durability)
end

function module:OnListSelected(_, list)
	if list == L.durability then
		-- Fill the list with all players
		for unit in self:IterateGroup() do
			local player = self:UnitName(unit)
			if player then
				local k = inTable(durability, player, 1)
				if not k then
					k = #durability + 1
					durability[k] = { player }
				end
			end
		end

		LD:RequestDurability()
	end
end

do
	local function update(percent, broken, player)
		local k = inTable(durability, player, 1)
		if not k then
			durability[#durability + 1] = { player }
			k = #durability
		end
		durability[k][2] = floor(tonumber(percent))
		durability[k][3] = tonumber(broken)

		oRA:UpdateList(L.durability)
	end
	LD:Register(module, update)
end
