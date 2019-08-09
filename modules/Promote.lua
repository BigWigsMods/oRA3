
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	return
end

--------------------------------------------------------------------------------
-- Setup
--

local addonName, scope = ...
local oRA = scope.addon
local util = oRA.util
local module = oRA:NewModule("Promote", "AceTimer-3.0")
local L = scope.locale
local AceGUI = LibStub("AceGUI-3.0")

-- luacheck: globals GameFontHighlight

--------------------------------------------------------------------------------
-- Locals
--

local guildRankDb = nil
local factionDb = nil
local queuePromotes = nil
local dontPromoteThisSession = {}
local hasSetEveryoneAssistant = nil -- prevent re-enabling if changed later

--------------------------------------------------------------------------------
-- GUI
--

local ranks, showPane, hidePane, demoteButton
do
	local frame = nil
	-- Widgets (in order of appearance)
	local everyone, guild, add, delete

	local function onControlEnter(widget, event, value)
		if not oRA.db.profile.showHelpTexts then return end
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
		GameTooltip:AddLine(widget.text:GetText())
		GameTooltip:AddLine(widget:GetUserData("tooltip"), 1, 1, 1, 1)
		GameTooltip:Show()
	end
	local function onControlLeave() GameTooltip:Hide() end

	local function everyoneCallback(widget, event, value)
		if guild then
			guild:SetDisabled(value)
			ranks:SetDisabled(value or factionDb.promoteGuild)
		end
		add:SetDisabled(value)
		delete:SetDisabled(value or #factionDb.promotes < 1)
		factionDb.promoteAll = value and true or false
		queuePromotes()
	end

	local function guildCallback(widget, event, value)
		ranks:SetDisabled(value)
		factionDb.promoteGuild = value and true or false
		queuePromotes()
	end

	local function ranksCallback(widget, event, rankIndex, value)
		guildRankDb[rankIndex] = value and true or nil
		queuePromotes()
	end

	local function addCallback(widget, event, value)
		if type(value) ~= "string" then return true end
		if util.inTable(factionDb.promotes, value) then return true end
		table.insert(factionDb.promotes, value)
		add:SetText()
		delete:SetList(factionDb.promotes)
		delete:SetDisabled(factionDb.promoteAll or #factionDb.promotes < 1)
		queuePromotes()
	end

	local function deleteCallback(widget, event, value)
		table.remove(factionDb.promotes, value)
		delete:SetList(factionDb.promotes)
		delete:SetValue("")
		delete:SetDisabled(factionDb.promoteAll or #factionDb.promotes < 1)
	end

	local function demoteRaid()
		if not UnitIsGroupLeader("player") then return end
		if IsEveryoneAssistant() then
			SetEveryoneIsAssistant(false)
		end
		for i = 1, GetNumGroupMembers() do
			local name, rank = GetRaidRosterInfo(i)
			if name and rank == 1 then
				DemoteAssistant(name)
			end
		end
		--wipe(dontPromoteThisSession)
	end

	local function createFrame()
		if frame then return end
		frame = AceGUI:Create("ScrollFrame")
		frame:SetLayout("List")

		local spacer = AceGUI:Create("Label")
		spacer:SetText(" ")

		demoteButton = AceGUI:Create("Button")
		demoteButton:SetText(L.demoteEveryone)
		demoteButton:SetUserData("tooltip", L.demoteEveryoneDesc)
		demoteButton:SetCallback("OnEnter", onControlEnter)
		demoteButton:SetCallback("OnLeave", onControlLeave)
		demoteButton:SetCallback("OnClick", demoteRaid)
		demoteButton:SetFullWidth(true)
		demoteButton:SetDisabled(not IsInRaid() or not UnitIsGroupLeader("player"))

		local massHeader = AceGUI:Create("Heading")
		massHeader:SetText(L.massPromotion)
		massHeader:SetFullWidth(true)

		everyone = AceGUI:Create("CheckBox")
		everyone:SetValue(factionDb.promoteAll)
		everyone:SetLabel(L.promoteEveryone)
		everyone:SetCallback("OnEnter", onControlEnter)
		everyone:SetCallback("OnLeave", onControlLeave)
		everyone:SetCallback("OnValueChanged", everyoneCallback)
		everyone:SetUserData("tooltip", L.promoteEveryoneDesc)
		--everyone:SetUserData("tooltip", L["Set \"Make Everyone Assistant\" automatically."])
		everyone:SetFullWidth(true)

		if guildRankDb then
			guild = AceGUI:Create("CheckBox")
			guild:SetValue(factionDb.promoteGuild)
			guild:SetLabel(L.promoteGuild)
			guild:SetCallback("OnEnter", onControlEnter)
			guild:SetCallback("OnLeave", onControlLeave)
			guild:SetCallback("OnValueChanged", guildCallback)
			guild:SetUserData("tooltip", L.promoteGuildDesc)
			guild:SetDisabled(factionDb.promoteAll)
			guild:SetFullWidth(true)

			local guildRanks = oRA:GetGuildRanks()
			ranks = AceGUI:Create("Dropdown")
			ranks:SetMultiselect(true)
			ranks:SetLabel(L.byGuildRank)
			ranks:SetList(guildRanks)
			for i, v in next, guildRanks do
				ranks:SetItemValue(i, guildRankDb[i])
			end
			ranks:SetCallback("OnValueChanged", ranksCallback)
			ranks:SetDisabled(factionDb.promoteAll or factionDb.promoteGuild)
			ranks:SetFullWidth(true)
		end

		local individualHeader = AceGUI:Create("Heading")
		individualHeader:SetText(L.individualPromotions)
		individualHeader:SetFullWidth(true)

		local description = AceGUI:Create("Label")
		description:SetText(L.individualPromotionsDesc)
		description:SetFontObject(GameFontHighlight)
		description:SetFullWidth(true)

		add = AceGUI:Create("EditBox")
		add:SetLabel(L.add)
		add:SetText()
		add:SetCallback("OnEnterPressed", addCallback)
		add:SetDisabled(factionDb.promoteAll)
		add:SetFullWidth(true)

		delete = AceGUI:Create("Dropdown")
		delete:SetValue("")
		delete:SetLabel(L.remove)
		delete:SetList(factionDb.promotes)
		delete:SetCallback("OnValueChanged", deleteCallback)
		delete:SetDisabled(factionDb.promoteAll or #factionDb.promotes < 1)
		delete:SetFullWidth(true)

		if guildRankDb then
			if oRA.db.profile.showHelpTexts then
				frame:AddChildren(demoteButton, massHeader, everyone, guild, ranks, spacer, individualHeader, description, add, delete)
			else
				frame:AddChildren(demoteButton, massHeader, everyone, guild, ranks, spacer, individualHeader, add, delete)
			end
		else
			if oRA.db.profile.showHelpTexts then
				frame:AddChildren(demoteButton, massHeader, everyone, spacer, individualHeader, description, add, delete)
			else
				frame:AddChildren(demoteButton, massHeader, everyone, spacer, individualHeader, add, delete)
			end
		end
	end

	function showPane()
		if not frame then createFrame() end
		oRA:SetAllPointsToPanel(frame.frame, true)
		frame.frame:Show()
	end

	function hidePane()
		if frame then
			frame:Release()
			frame = nil
		end
	end
end

--------------------------------------------------------------------------------
-- Module
--

function module:OnRegister()
	local database = oRA.db:RegisterNamespace("Promote", {
		factionrealm = {
			promotes = {},
			promoteAll = nil,
			promoteGuild = nil,
			promoteRank = {
				['*'] = {},
			},
		},
	})
	factionDb = database.factionrealm

	oRA:RegisterPanel(
		L.promote,
		showPane,
		hidePane
	)
	oRA.RegisterCallback(self, "OnGroupChanged")
	oRA.RegisterCallback(self, "OnGuildRanksUpdate")
	oRA.RegisterCallback(self, "OnPromoted", "OnGroupChanged")
	hooksecurefunc("DemoteAssistant", function(player)
		if module:IsEnabled() then
			dontPromoteThisSession[player] = true
		end
	end)
end

do
	local function shouldPromote(name)
		if dontPromoteThisSession[name] then return false end
		if UnitIsInMyGuild(name) then
			if factionDb.promoteGuild then return true end
			local rank = oRA:IsGuildMember(name)
			if guildRankDb and guildRankDb[rank] then
				return true
			end
		end
		if util.inTable(factionDb.promotes, name) then
			return true
		end
	end

	local promotes, scheduled = {}, nil
	local function doPromotes()
		for name in next, promotes do
			PromoteToAssistant(name)
		end
		wipe(promotes)
		scheduled = nil
	end

	function queuePromotes()
		if not IsInRaid() or not UnitIsGroupLeader("player") then return end
		if factionDb.promoteAll then
			if not IsEveryoneAssistant() and not hasSetEveryoneAssistant then
				SetEveryoneIsAssistant(true)
				hasSetEveryoneAssistant = true
			end
		else
			if hasSetEveryoneAssistant then
				SetEveryoneIsAssistant(false)
				hasSetEveryoneAssistant = nil
			end
			if not IsEveryoneAssistant() then
				for i = 1, GetNumGroupMembers() do
					local name, rank = GetRaidRosterInfo(i)
					if name and rank == 0 and shouldPromote(name) then
						promotes[name] = true
					end
				end
				if not scheduled and next(promotes) then
					scheduled = module:ScheduleTimer(doPromotes, 2)
				end
			end
		end
	end
	function module:OnGroupChanged()
		if demoteButton then
			demoteButton:SetDisabled(not IsInRaid() or not UnitIsGroupLeader("player"))
		end
		queuePromotes()
	end

	function module:OnEnable()
		self:OnGuildRanksUpdate(nil, oRA:GetGuildRanks())
		self:RegisterEvent("GUILD_ROSTER_UPDATE")
		self:ScheduleTimer("OnGroupChanged", 5)
	end
end

function module:GUILD_ROSTER_UPDATE()
	if IsInGuild() then
		local guildName = GetGuildInfo("player")
		guildRankDb = factionDb.promoteRank and factionDb.promoteRank[guildName]
	end
end

function module:OnGuildRanksUpdate(_, guildRanks)
	if ranks then
		ranks:SetList(guildRanks)
		for i, v in next, guildRanks do
			ranks:SetItemValue(i, guildRankDb[i])
		end
	end
end
