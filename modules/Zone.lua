local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Zone")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

local zones = {}

local tip = nil

local function createTooltip()
	tip = CreateFrame("GameTooltip")
	tip:SetOwner(WorldFrame, "ANCHOR_NONE")
	local lcache, rcache = {}, {}
	for i=1,30 do
		lcache[i], rcache[i] = tip:CreateFontString(), tip:CreateFontString()
		lcache[i]:SetFontObject(GameFontNormal); rcache[i]:SetFontObject(GameFontNormal)
		tip:AddFontStrings(lcache[i], rcache[i])
	end

	-- GetText cache tables, provide fast access to the tooltip's text
	tip.L = setmetatable({}, {
		__index = function(t, key)
			if tip:NumLines() >= key and lcache[key] then
				local v = lcache[key]:GetText()
				t[key] = v
				return v
			end
			return nil
		end,
	})
	local orig = tip.SetUnit
	tip.SetUnit = function(self, ...)
		self:ClearLines() -- Ensures tooltip's NumLines is reset
		for i in pairs(self.L) do self.L[i] = nil end -- Flush the metatable cache
		if not self:IsOwned(WorldFrame) then self:SetOwner(WorldFrame, "ANCHOR_NONE") end
		return orig(self, ...)
	end
end

function module:OnRegister()
	oRA:RegisterList(
		L["Zone"],
		zones,
		L["Name"],
		L["Zone"]
	)
	oRA.RegisterCallback(self, "OnListSelected")
	oRA.RegisterCallback(self, "OnGroupChanged")
	oRA.RegisterCallback(self, "OnStartup", "UpdateZoneList")
end

function module:OnListSelected(event, list)
	if list == L["Zone"] then
		self:UpdateZoneList()
	end
end

function module:OnGroupChanged(event, status, members)
	self:UpdateZoneList()
	oRA:UpdateList(L["Zone"])
end

local function addPlayer( name, zone )
	local k = util:inTable(zones, name, 1)
	if not k then
		table.insert(zones, { name } )
		k = util:inTable(zones, name, 1)
	end
	zone = zone or L["Unknown"]
	zones[k][2] = zone
end

function module:UpdateZoneList()
	if oRA.groupStatus == oRA.INRAID then
		for i = 1, GetNumRaidMembers() do
			local name, _, _, _, _, _, zone = GetRaidRosterInfo(i)
			addPlayer(name, zone)
		end
	elseif oRA.groupStatus == oRA.INPARTY then
		if not tip then
			createTooltip()
		end
		addPlayer( UnitName("player"), GetZoneText())
		for i = 1, MAX_PARTY_MEMBERS do
			if GetPartyMember(i) then
				local name = UnitName("party"..i)
				if name then
					tip:SetUnit("party"..i)
					local zone = tip.L[3]
					addPlayer(name, zone)
				end
			end
		end
	end
end
