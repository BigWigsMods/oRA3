local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Invite", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

local guildMemberList = {}
local guildRanks = {}

local frame = nil

function module:OnRegister()
	self:CreateFrame()
	self.db = oRA.db:RegisterNamespace("Invite", {
		global = {
			keyword = nil,
		},
	})
end

function module:OnEnable()
	--frame:Show()
	self:RegisterEvent("GUILD_ROSTER_UPDATE")

	if IsInGuild() then GuildRoster() end
end

function module:OnDisable()

end

function module:GUILD_ROSTER_UPDATE()
	for k in pairs(guildRanks) do guildRanks[k] = nil end
	for i = 1, GuildControlGetNumRanks() do
		table.insert(guildRanks, GuildControlGetRankName(i))
	end
	for k, v in pairs(guildMemberList) do guildMemberList[k] = nil end
	local numGuildMembers = GetNumGuildMembers()
	for i = 1, numGuildMembers do
		local name = GetGuildRosterInfo(i)
		if name then
			guildMemberList[name] = true
		end
	end
end

--[[---------------------------------

   ( Invite guild )
   .-- Invites everyone in the guild at MAX_LEVEL 
   
   ( Invite zone  )
   .-- Invites all guild members in your current zone
   
   ( Guild Master )
   ( Officer      )
   ( Class Leader )
   ( Member       ) 
   ( Initiate     )
   .-- Basically one button per guild rank


-----------------------------------]]

local function onControlEnter(widget, event, value)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(widget.frame, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:AddLine(widget.text:GetText())
	GameTooltip:AddLine(widget.oRATooltipText, 1, 1, 1, 1)
	GameTooltip:Show()
end
local function onControlLeave() GameTooltip:Hide() end

function module:CreateFrame()
	if frame then return end
--[[
	local f = AceGUI:Create("Frame")
	f:SetTitle("Invite")
	--f:SetLayout("Flow")
	f:SetWidth(340)
	f:SetHeight(400)
]]
	frame = f
end

