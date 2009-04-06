local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Invite", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

local frame = nil
local db = nil

local function showConfig()
	frame.frame:SetParent(_G["oRA3FrameSub"])
	frame.frame:SetPoint("TOPLEFT", _G["oRA3FrameSub"], "TOPLEFT", -28, -58)
	frame.frame:SetPoint("BOTTOMRIGHT", _G["oRA3FrameSub"], "BOTTOMRIGHT", -12, 0)
	frame.frame:Show()
end

local function hideConfig()
	frame.frame:Hide()
end

function module:OnRegister()
	local database = oRA.db:RegisterNamespace("Invite", {
		global = {
			keyword = nil,
		},
	})
	db = database.global

	self:CreateFrame()

	oRA:RegisterOverview(
		"Invite",
		"Interface\\Icons\\Spell_ChargePositive",
		showConfig,
		hideConfig
	)
end

local function onControlEnter(widget, event, value)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
	GameTooltip:AddLine(widget.text:GetText())
	GameTooltip:AddLine(widget.oRATooltipText, 1, 1, 1, 1)
	GameTooltip:Show()
end
local function onControlLeave() GameTooltip:Hide() end

local rankButtonFormat = "%d. %s"
local function updateRankButtons()
	for i = 1, #frame.children do
		local widget = frame.children[i]
		if widget.oRAGuildRank then
			table.remove(frame.children, i)
			widget.oRAGuildRank = nil
			widget.oRATooltipText = nil
			widget:Release()
		end
	end
	local ranks = oRA:GetGuildRanks()
	local w = frame.frame:GetWidth() / 3
	for i = 1, #ranks do
		local button = AceGUI:Create("Button")
		button:SetText(rankButtonFormat:format(i, ranks[i]))
		button.oRATooltipText = ("Invite all guild members of rank %s or higher."):format(ranks[i])
		button.oRAGuildRank = i
		button:SetCallback("OnEnter", onControlEnter)
		button:SetCallback("OnLeave", onControlLeave)
		button:SetCallback("OnClick", function()
			-- inviteRank(i)
		end)
		button:SetWidth(w)
		--button:SetFullWidth(true)
		frame:AddChild(button)
	end
end

function module:OnEnable()
	oRA.RegisterCallback(self, "OnGuildRanksUpdate")
end

function module:OnGuildRanksUpdate(event, ranks)
	updateRankButtons()
end

function module:CreateFrame()
	if frame then return end

	local f = AceGUI:Create("SimpleGroup")
	f:SetLayout("Flow")
	f:SetWidth(340)
	f:SetHeight(400)
	frame = f

	local keyword = AceGUI:Create("EditBox")
	keyword:SetLabel("Keyword")
	keyword:SetText(db.keyword)
	keyword:SetCallback("OnEnterPressed", function(widget, event, value)
		if type(value) ~= "string" or value:trim():len() < 2 then return true end
		db.keyword = value
	end)
	keyword:SetFullWidth(true)
	
	local kwDescription = AceGUI:Create("Label")
	kwDescription:SetText("Anyone who whispers you the keyword set below will automatically and immediately be invited to your group. If you're in a party and it's full, you will convert to raid automatically if you are the party leader. The keyword will only stop working when you have a full raid of 40 people. Set the keyword box empty to disable keyword invites.")
	kwDescription:SetFullWidth(true)
	
	local guild = AceGUI:Create("Button")
	guild:SetText("Invite guild")
	guild.oRATooltipText = "Invite everyone in your guild at the maximum level."
	guild:SetCallback("OnEnter", onControlEnter)
	guild:SetCallback("OnLeave", onControlLeave)
	guild:SetCallback("OnClick", function()
	
	end)
	guild:SetFullWidth(true)
	
	local zone = AceGUI:Create("Button")
	zone:SetText("Invite zone")
	zone.oRATooltipText = "Invite everyone in your guild who are in the same zone as you."
	zone:SetCallback("OnEnter", onControlEnter)
	zone:SetCallback("OnLeave", onControlLeave)
	zone:SetCallback("OnClick", function()
	
	end)
	zone:SetFullWidth(true)
	
	local rankHeader = AceGUI:Create("Heading")
	rankHeader:SetText("Guild rank invites")
	rankHeader:SetFullWidth(true)
	
	local rankDescription = AceGUI:Create("Label")
	rankDescription:SetText("Clicking any of the buttons below will invite anyone of the selected rank OR HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites.")
	rankDescription:SetFullWidth(true)

	f:AddChild(guild)
	f:AddChild(zone)
	f:AddChild(kwDescription)
	f:AddChild(keyword)
	f:AddChild(rankHeader)
	f:AddChild(rankDescription)

	updateRankButtons()
end


