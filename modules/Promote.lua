local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Promote", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

local guildMemberList = {}
local guildRanks = {}

local frame = nil
-- Widgets (in order of appearance)
local everyone, guild, ranks, add, delete

local individualPromotions = {
	"Player #1",
	"Player #2",
	"Player #3",
}

function module:OnRegister()
	self:CreateFrame()
end

function module:OnEnable()
	frame:Show()
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	--self:RegisterEvent("RAID_ROSTER_UPDATE", "CheckPromotes")

	if IsInGuild() then GuildRoster() end
end

function module:OnDisable()

end

function module:GUILD_ROSTER_UPDATE()
	for k in pairs(guildRanks) do guildRanks[k] = nil end
	for i = 1, GuildControlGetNumRanks() do
		table.insert(guildRanks, GuildControlGetRankName(i))
	end
	ranks:SetList(guildRanks)
	for i, v in ipairs(guildRanks) do
		ranks:SetItemValue(i, true)
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

   ---- Mass promotion       ----

   [ ] Everyone
   [ ] Guild

   By guild rank
   [ Guild Master    V ]
   
   ---- Personal promotions  ----
   
   Add
   [                   ]
   
   Remove
   [ <name>          V ]

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

	local f = AceGUI:Create("Frame")
	f:SetTitle("Promote")
	--f:SetLayout("Flow")
	f:SetWidth(340)
	f:SetHeight(400)

--[[	local massHeader = AceGUI:Create("Heading")
	massHeader:SetText("Mass promotion")]]

	everyone = AceGUI:Create("CheckBox")
	everyone:SetLabel("Everyone")
	everyone:SetCallback("OnEnter", onControlEnter)
	everyone:SetCallback("OnLeave", onControlLeave)
	everyone:SetCallback("OnValueChanged", function(widget, event, value)
		guild:SetDisabled(value)
		ranks:SetDisabled(value)
		add:SetDisabled(value)
		delete:SetDisabled(value)
	end)
	everyone.oRATooltipText = "Promote everyone automatically."

	guild = AceGUI:Create("CheckBox")
	guild:SetLabel("Guild")
	guild:SetCallback("OnEnter", onControlEnter)
	guild:SetCallback("OnLeave", onControlLeave)
	guild:SetCallback("OnValueChanged", function(widget, event, value)
		ranks:SetDisabled(value)
	end)
	guild.oRATooltipText = "Promote all guild members automatically."

	ranks = AceGUI:Create("Dropdown")
	ranks:SetMultiselect(true)
	ranks:SetLabel("By guild rank")
	ranks:SetList(guildRanks)
	ranks:SetCallback("OnValueChanged", function(widget,event,...)
		AceLibrary("AceConsole-2.0"):PrintLiteral(...)
	end)

--[[	local individualHeader = AceGUI:Create("Heading")
	individualHeader:SetText("Individual promotions")]]

	add = AceGUI:Create("EditBox")
	add:SetLabel("Add")
	add:SetCallback("OnEnterPressed", function(widget, event, value)
		if type(value) ~= "string" or value:trim():len() < 3 then return true end
		if util:inTable(individualPromotions, value) then return true end
		table.insert(individualPromotions, value)
		add:SetText()
		delete:SetList(individualPromotions)
	end)

	delete = AceGUI:Create("Dropdown")
	delete:SetValue("")
	delete:SetLabel("Remove")
	delete:SetList(individualPromotions)
	delete:SetCallback("OnValueChanged", function(_, _, value)
		table.remove(individualPromotions, value)
		delete:SetList(individualPromotions)
		delete:SetValue("")
	end)

	--f:AddChild(massHeader)
	f:AddChild(everyone)
	f:AddChild(guild)
	f:AddChild(ranks)
	--f:AddChild(individualHeader)
	f:AddChild(add)
	f:AddChild(delete)

	frame = f
end

