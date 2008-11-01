
local addon = LibStub("AceAddon-3.0"):NewAddon("oRA3", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceConsole-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")

addon.util = {}
local util = addon.util

-- Module stuff
addon:SetDefaultModuleState(false) -- all modules disabled by default

-- Locals
local playerName = UnitName("player")

-- couple of local constants used for party size
local UNGROUPED = 0
local INPARTY = 1
local INRAID = 2
addon.groupStatus = UNGROUPED -- flag indicating groupsize
local groupStatus = addon.groupStatus -- local upvalue

local db
local defaults = {
	profile = {
	}
}


local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("oRA3", {
	type = "launcher",
	text = "oRA3",
	icon = [[Interface\Icons\INV_Inscription_MajorGlyph03]],
})

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("oRA3DB", defaults)
	db = self.db.profile
	
	-- callbackhandler for comm
	self.callbacks = CallbackHandler:New(self)
end


function addon:OnEnable()
	-- Comm register
	self:RegisterComm("oRA3")
	
	-- Group Status Events
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE")
	-- init groupStatus
	self:RAID_ROSTER_UPDATE()
end

function addon:OnDisable()
	self:Shutdown()
end

-- keep track of group status
function addon:RAID_ROSTER_UPDATE()
	local oldStatus = groupStatus
	if GetNumRaidMembers() > 0 then
		groupStatus = INRAID
	elseif GetNumPartyMembers() > 0 then
		groupStatus = INPARTY
	else
		groupStatus = UNGROUPED
		-- FIXME:  remove this override
		groupStatus = INRAID
	end
	if groupStatus == UNGROUPED and oldStatus > groupStatus then
		self:Shutdown()
	elseif oldStatus == UNGROUPED and groupStatus > oldStatus then
		self:Startup()
	end
end

function addon:InRaid()
	return groupStatus == INRAID
end

function addon:InParty()
	return groupStatus == INPARTY
end

-- startup and shutdown
function addon:Startup()
	self:ShowGUI()
	for name, module in self:IterateModules() do
		module:Enable()
	end
end

function addon:Shutdown()
	self:HideGUI()
	for name, module in self:IterateModules() do
		module:Disable()
	end
end

-- utility functions

function addon:IsPromoted(name)
	if not name then name = playerName end
	if groupStatus == UNGROUPED then
		return false
	elseif groupStatus == INRAID then
		if name == playerName then return IsRaidLeader() or IsRaidOfficer() end
		local raidNum = GetNumRaidMembers()
		for i=1,raidNum do
			local rname, rank = GetRaidRosterInfo(i)
			if rname == name then return rank > 0 end
		end
	elseif groupStatus == INPARTY then
		local li = GetPartyLeaderIndex()
		return (li == 0 and name == playerName) or (li>0 and name == UnitName("party"..li))
	end
	return false
end

-- comm

function addon:SendComm( ... )
	if groupStatus == UNGROUPED then return end
	self:SendCommMessage("oRA3", self:Serialize(...), "RAID") -- we always send to raid, blizzard will default to party if you're in a party
end

function addon:OnCommReceived(prefix, message, distribution, sender)
	if distribution ~= "RAID" and distribution ~= "PARTY" then return end
	addon:DispatchComm( sender, self:Deserialize(message) )
end

function addon:DispatchComm(sender, ok, commType, ...)
	if ok and type(commType) == "string" then
		self.callbacks:Fire( "OnComm"..commType, sender, ... )
	end
end

-- GUI

function addon:ShowGUI()
	self:SetupGUI()
	oRA3Frame:Show()
	self:UpdateGUI()
end

function addon:HideGUI()
	-- hide gui here
	oRA3Frame:Hide()
end

function addon:SetupGUI()
	if oRA3Frame then return end

	local frame = CreateFrame("Frame", "oRA3Frame", RaidFrame)

	do return end
	
	frame:SetWidth(350)
	frame:SetHeight(425)
	frame:SetPoint("TOPLEFT", RaidFrame, "TOPRIGHT", -50, -12)
	frame:SetFrameStrata("LOW")
end

function addon:UpdateGUI()
	self:SetupGUI()
	if not oRA3Frame:IsVisible() then return end
	-- update the overviews
end


-- Overviews

-- register an overview
-- name (string) - name of the overview Tab
-- refreshfunc - name of the function to call to refresh the overview
-- .. tuple - name, table  -- contains name of the sortable column and table to get the data from, will assume tables indexed by name
function addon:RegisterOverview(name, refreshfunc, ...)
end

function addon:UnregisterOverview(name)
	-- hide and recycle
end


function util:clearTable(t)
	for k, v in pairs(t) do
		t[k] = nil
	end
	return t
end

function util:inTable(t, value)
	for k, v in pairs(t) do
		if v == value then return true end
	end
	return nil
end

