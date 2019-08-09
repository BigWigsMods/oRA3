
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	return
end

local addonName, scope = ...
local oRA = scope.addon
local util = oRA.util
local module = oRA:NewModule("Zone")
local L = scope.locale

-- luacheck: globals GameFontNormal

local zones = {}
local factionList = {}
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

-- GetZone and UPDATE_FACTIOn were taken from LibDogTag by Ckknight with permission.
local LEVEL_start = "^" .. (type(LEVEL) == "string" and LEVEL or "Level")
local PVP = type(PVP) == "string" and PVP or "PvP"
local function GetZone(unit)
	if UnitIsVisible(unit) then
		return nil
	end
	if not UnitIsConnected(unit) then
		return nil
	end
	tip:SetUnit(unit)
	local left_2 = tip.L[2]
	local left_3 = tip.L[3]
	if not left_2 or not left_3 then
		return nil
	end
	local hasGuild = not left_2:find(LEVEL_start)
	local factionText = not hasGuild and left_3 or tip.L[4]
	if factionText == PVP then
		factionText = nil
	end
	local hasFaction = factionText and not UnitPlayerControlled(unit) and not UnitIsPlayer(unit) and (UnitFactionGroup(unit) or factionList[factionText])
	if hasGuild and hasFaction then
		return tip.L[5]
	elseif hasGuild or hasFaction then
		return tip.L[4]
	else
		return left_3
	end
end


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

function module:OnEnable()
	self:RegisterEvent("UPDATE_FACTION")
	self:UPDATE_FACTION()
end

function module:OnListSelected(event, list)
	if list == L.zone then
		self:UpdateZoneList()
	end
end

-- UPDATE_FACTION and getZone were taken from LibDogTag by ckknight with permission.
local in_UPDATE_FACTION = false
function module:UPDATE_FACTION()
	if in_UPDATE_FACTION then return end
	in_UPDATE_FACTION = true
	for i = 1, GetNumFactions() do
		local name,_,_,_,_,_,_,_,isHeader,isCollapsed = GetFactionInfo(i)
		if isHeader == 1 then
			if isCollapsed == 1 then
				local numFactions = GetNumFactions()
				ExpandFactionHeader(i)
				numFactions = GetNumFactions() - numFactions
				for j = i + 1, i + numFactions do
					name = GetFactionInfo(j)
					factionList[name] = true
				end
				CollapseFactionHeader(i)
			end
		elseif name then
			factionList[name] = true
		end
	end
	in_UPDATE_FACTION = false
end

function module:OnGroupChanged()
	oRA:UpdateList(L.zone)
end

local function addPlayer(name, zone)
	if not name then return end
	local k = util.inTable(zones, name, 1)
	if not k then
		zones[#zones + 1] = { name }
		k = #zones
	end
	zone = zone or L.unknown
	zones[k][2] = zone
end

function module:UpdateZoneList()
	wipe(zones)
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local name, _, _, _, _, _, zone = GetRaidRosterInfo(i)
			addPlayer(name, zone)
		end
	elseif IsInGroup() then
		if not tip then
			createTooltip()
			createTooltip = nil
		end
		addPlayer(UnitName("player"), GetRealZoneText())
		for i = 1, 5 do
			if i < GetNumSubgroupMembers() + 1 then
				local name = UnitName("party"..i)
				local zone = GetZone("party"..i)
				addPlayer(name, zone)
			end
		end
	else
		addPlayer(UnitName("player"), GetRealZoneText())
	end
end
