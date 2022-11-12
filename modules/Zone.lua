
local addonName, scope = ...
local oRA = scope.addon
local util = oRA.util
local module = oRA:NewModule("Zone")
local L = scope.locale

local UNKNOWN = ("|cff999999%s|r"):format(_G.UNKNOWN)
local OFFLINE = ("|cff999999%s|r"):format(_G.PLAYER_OFFLINE)

local zones = {}

function module:OnRegister()
	oRA:RegisterList(
		L.zone,
		zones,
		L.name,
		L.zone
	)

	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnGroupChanged")
	oRA.RegisterCallback(self, "OnStartup", "UpdateZoneList")

	SLASH_ORAZONE1 = "/razone"
	SLASH_ORAZONE2 = "/raz"
	SlashCmdList.ORAZONE = function()
		oRA:OpenToList(L.zone)
	end
end

function module:OnListSelected(_, list)
	if list == L.zone then
		self:UpdateZoneList()
	end
end

function module:OnGroupChanged()
	oRA:UpdateList(L.zone)
end

function module:UpdateZoneList()
	wipe(zones)
	if IsInGroup() then
		for i = 1, GetNumGroupMembers() do
			local name, _, _, _, _, _, zone = GetRaidRosterInfo(i)
			if not UnitIsConnected(name) then -- GetRaidRosterInfo is slow to mark offline
				zone = OFFLINE
			elseif not zone then
				zone = UNKNOWN
			end
			zones[#zones + 1] = { name, zone }
		end
	else
		local name, zone = UnitName("player"), GetRealZoneText() or UNKNOWN
		zones[#zones + 1] = { name, zone }
	end
end
