local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Invite", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

local frame = nil
local db = nil
local peopleToInvite = {}

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

local doActualInvites = nil
local actualInviteFrame = CreateFrame("Frame")
local aiTotal = 0
local function aiOnUpdate(self, elapsed)
	aiTotal = aiTotal + elapsed
	if aiTotal > 2 then
		doActualInvites()
		aiTotal = 0
		self:SetScript("OnUpdate", nil)
	end
end

local function partyMembersChanged()
	if #peopleToInvite > 0 then
		module:UnregisterEvent("PARTY_MEMBERS_CHANGED")
		ConvertToRaid()
		actualInviteFrame:SetScript("OnUpdate", aiOnUpdate)
	end
end

function doActualInvites()
	if not UnitInRaid("player") then
		local pNum = GetNumPartyMembers() + 1 -- 1-5
		if pNum == 5 then
			if #peopleToInvite > 0 then
				ConvertToRaid()
				actualInviteFrame:SetScript("OnUpdate", aiOnUpdate)
			end
		else
			local tmp = {}
			for i = 1, (5 - pNum) do
				local u = table.remove(peopleToInvite)
				if u then tmp[u] = true end
			end
			if #peopleToInvite > 0 then
				module:RegisterEvent("PARTY_MEMBERS_CHANGED", partyMembersChanged)
			end
			for k in pairs(tmp) do
				InviteUnit(k)
			end
		end
		return
	end
	for i, v in ipairs(peopleToInvite) do
		InviteUnit(v)
	end
	for k in pairs(peopleToInvite) do
		peopleToInvite[k] = nil
	end
end

local function doGuildInvites(level, zone, rank)
	for i = 1, GetNumGuildMembers() do
		local name, _, rankIndex, unitLevel, _, unitZone, _, _, online = GetGuildRosterInfo(i)
		if name and online and not UnitInParty(name) and not UnitInRaid(name) then
			if level and level <= unitLevel then
				table.insert(peopleToInvite, name)
			elseif zone and zone == unitZone then
				table.insert(peopleToInvite, name)
			-- See the wowwiki docs for GetGuildRosterInfo, need to add +1 to the rank index
			elseif rank and (rankIndex + 1) <= rank then
				table.insert(peopleToInvite, name)
			end
		end
	end
	doActualInvites()
end

local inviteFrame = CreateFrame("Frame")
local total = 0
local function onUpdate(self, elapsed)
	total = total + elapsed
	if total > 10 then
		doGuildInvites(self.level, self.zone, self.rank)
		self:SetScript("OnUpdate", nil)
		total = 0
	end
end

function module:OnEnable()
	oRA.RegisterCallback(self, "OnGuildRanksUpdate")

	self:RegisterEvent("CHAT_MSG_WHISPER")
end

local function chat(msg, channel)
	SendChatMessage(msg, channel)
	--print(msg .. "#" .. channel)
end

function module:InviteGuild(level)
	chat(("All max level characters will be invited to raid in 10 seconds. Please leave your groups."):format(MAX_PLAYER_LEVEL), "GUILD")
	inviteFrame.level = MAX_PLAYER_LEVEL
	inviteFrame.zone = nil
	inviteFrame.rank = nil
	inviteFrame:SetScript("OnUpdate", onUpdate)
end

function module:InviteZone()
	local currentZone = GetRealZoneText()
	chat(("All characters in %s will be invited to raid in 10 seconds. Please leave your groups."):format(currentZone), "GUILD")
	inviteFrame.level = nil
	inviteFrame.zone = currentZone
	inviteFrame.rank = nil
	inviteFrame:SetScript("OnUpdate", onUpdate)
end

function module:InviteRank(rank, name)
	GuildControlSetRank(rank)
	local _, _, ochat = GuildControlGetRankFlags()
	local channel = ochat and "OFFICER" or "GUILD"
	chat(("All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups."):format(name), channel)
	inviteFrame.level = nil
	inviteFrame.zone = nil
	inviteFrame.rank = rank
	inviteFrame:SetScript("OnUpdate", onUpdate)
end

function module:CHAT_MSG_WHISPER(event, msg, author)
	if db.keyword and msg == db.keyword then
		local isIn, instanceType = IsInInstance()
		local party = GetNumPartyMembers()
		local raid = GetNumRaidMembers()
		local diff = GetDungeonDifficulty()
		if isIn and instanceType == "party" and party == 4 then
			SendChatMessage("<oRA> Sorry, the group is full.", "WHISPER", nil, author)
		--[[elseif isIn and instanceType == "raid" and diff == 1 and raid == 10 then
			SendChatMessage("<oRA> Sorry, the group is full.", "WHISPER", nil, author)
		elseif isIn and instanceType == "raid" and diff == 2 and raid == 25 then
			SendChatMessage("<oRA> Sorry, the group is full.", "WHISPER", nil, author)]]
		elseif party == 4 and raid == 0 then
			table.insert(peopleToInvite, author)
			doActualInvites()
		elseif raid == 40 then
			SendChatMessage("<oRA> Sorry, the group is full.", "WHISPER", nil, author)
		else
			InviteUnit(author)
		end
	end
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
			module:InviteRank(i, ranks[i])
		end)
		button:SetWidth(w)
		frame:AddChild(button)
	end
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
		if type(value) == "string" and value:trim():len() < 2 then value = nil end
		db.keyword = value
		keyword:SetText(value)
	end)
	keyword:SetFullWidth(true)
	
	local kwDescription = AceGUI:Create("Label")
	kwDescription:SetText("Anyone who whispers you the keyword set below will automatically and immediately be invited to your group. If you're in a party and it's full, you will convert to raid automatically if you are the party leader. The keyword will only stop working when you have a full raid of 40 people. Set the keyword box empty to disable keyword invites.")
	kwDescription:SetFullWidth(true)
	kwDescription:SetFontObject(GameFontHighlight)
	
	local guild = AceGUI:Create("Button")
	guild:SetText("Invite guild")
	guild.oRATooltipText = "Invite everyone in your guild at the maximum level."
	guild:SetCallback("OnEnter", onControlEnter)
	guild:SetCallback("OnLeave", onControlLeave)
	guild:SetCallback("OnClick", function()
		module:InviteGuild()
	end)
	guild:SetFullWidth(true)
	
	local zone = AceGUI:Create("Button")
	zone:SetText("Invite zone")
	zone.oRATooltipText = "Invite everyone in your guild who are in the same zone as you."
	zone:SetCallback("OnEnter", onControlEnter)
	zone:SetCallback("OnLeave", onControlLeave)
	zone:SetCallback("OnClick", function()
		module:InviteZone()
	end)
	zone:SetFullWidth(true)
	
	local rankHeader = AceGUI:Create("Heading")
	rankHeader:SetText("Guild rank invites")
	rankHeader:SetFullWidth(true)
	
	local rankDescription = AceGUI:Create("Label")
	rankDescription:SetText("Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites.")
	rankDescription:SetFullWidth(true)
	rankDescription:SetFontObject(GameFontHighlight)

	f:AddChild(guild)
	f:AddChild(zone)
	f:AddChild(kwDescription)
	f:AddChild(keyword)
	f:AddChild(rankHeader)
	f:AddChild(rankDescription)

	updateRankButtons()
end


