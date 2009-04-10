--------------------------------------------------------------------------------
-- Setup
--

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Promote", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

--------------------------------------------------------------------------------
-- Locals
--

local factionDb = nil
local charDb = nil
local queuePromotes = nil

--------------------------------------------------------------------------------
-- GUI
--

local ranks, showPane, hidePane
do
	local frame = nil
	-- Widgets (in order of appearance)
	local everyone, guild, add, delete

	local function onControlEnter(widget, event, value)
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
		GameTooltip:AddLine(widget.text:GetText())
		GameTooltip:AddLine(widget:GetUserData("tooltip"), 1, 1, 1, 1)
		GameTooltip:Show()
	end
	local function onControlLeave() GameTooltip:Hide() end

	local function everyoneCallback(widget, event, value)
		guild:SetDisabled(value)
		ranks:SetDisabled(value or factionDb.promoteGuild)
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
		charDb.promoteRank[rankIndex] = value and true or nil
		queuePromotes()
	end

	local function addCallback(widget, event, value)
		if type(value) ~= "string" or value:trim():len() < 3 then return true end
		if util:inTable(factionDb.promotes, value) then return true end
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

	local function createFrame()
		if frame then return end
		frame = AceGUI:Create("ScrollFrame")
		frame:SetLayout("Flow")

		local spacer = AceGUI:Create("Label")
		spacer:SetText(" ")
		spacer:SetFullWidth(true)

		local massHeader = AceGUI:Create("Heading")
		massHeader:SetText(L["Mass promotion"])
		massHeader:SetFullWidth(true)

		everyone = AceGUI:Create("CheckBox")
		everyone:SetValue(factionDb.promoteAll)
		everyone:SetLabel(L["Everyone"])
		everyone:SetCallback("OnEnter", onControlEnter)
		everyone:SetCallback("OnLeave", onControlLeave)
		everyone:SetCallback("OnValueChanged", everyoneCallback)
		everyone:SetUserData("tooltip", L["Promote everyone automatically."])
		everyone:SetFullWidth(true)

		local inGuild = IsInGuild()
		if inGuild then
			guild = AceGUI:Create("CheckBox")
			guild:SetValue(factionDb.promoteGuild)
			guild:SetLabel(L["Guild"])
			guild:SetCallback("OnEnter", onControlEnter)
			guild:SetCallback("OnLeave", onControlLeave)
			guild:SetCallback("OnValueChanged", guildCallback)
			guild:SetUserData("tooltip", L["Promote all guild members automatically."])
			guild:SetDisabled(factionDb.promoteAll)
			guild:SetFullWidth(true)

			ranks = AceGUI:Create("Dropdown")
			ranks:SetMultiselect(true)
			ranks:SetLabel(L["By guild rank"])
			ranks:SetList(oRA:GetGuildRanks())
			ranks:SetCallback("OnValueChanged", ranksCallback)
			ranks:SetDisabled(factionDb.promoteAll or factionDb.promoteGuild)
			ranks:SetFullWidth(true)

			local guildRanks = oRA:GetGuildRanks()
			ranks:SetList(guildRanks)
			for i, v in ipairs(guildRanks) do
				ranks:SetItemValue(i, charDb.promoteRank[i])
			end
		end

		local individualHeader = AceGUI:Create("Heading")
		individualHeader:SetText(L["Individual promotions"])
		individualHeader:SetFullWidth(true)

		local description = AceGUI:Create("Label")
		description:SetText(L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."])
		description:SetFullWidth(true)
		description:SetFontObject(GameFontHighlight)

		add = AceGUI:Create("EditBox")
		add:SetLabel(L["Add"])
		add:SetText()
		add:SetCallback("OnEnterPressed", addCallback)
		add:SetDisabled(factionDb.promoteAll)
		add:SetRelativeWidth(0.5)

		delete = AceGUI:Create("Dropdown")
		delete:SetValue("")
		delete:SetLabel(L["Remove"])
		delete:SetList(factionDb.promotes)
		delete:SetCallback("OnValueChanged", deleteCallback)
		delete:SetDisabled(factionDb.promoteAll or #factionDb.promotes < 1)
		delete:SetRelativeWidth(0.5)

		frame:AddChild(massHeader)
		frame:AddChild(everyone)
		if inGuild then
			frame:AddChild(guild)
			frame:AddChild(ranks)
		end
		frame:AddChild(spacer)
		frame:AddChild(individualHeader)
		frame:AddChild(description)
		frame:AddChild(add)
		frame:AddChild(delete)
	end

	function showPane()
		if not frame then createFrame() end
		oRA:SetAllPointsToPanel(frame.frame)
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
		},
		char = {
			promoteRank = {},
		},
	})
	factionDb = database.factionrealm
	charDb = database.char
	
	oRA:RegisterPanel(
		L["Promote"],
		showPane,
		hidePane
	)
end

do
	local function shouldPromote(name)
		local gML = oRA:GetGuildMembers()
		if factionDb.promoteAll then return true
		elseif factionDb.promoteGuild and gML[name] then return true
		elseif gML[name] and charDb.promoteRank[gML[name]] then return true
		elseif util:inTable(factionDb.promotes, name) then return true
		end
	end

	local f = CreateFrame("Frame")
	local total = 0
	local firedPromotes = nil
	local promotes = {}
	local function onUpdate(self, elapsed)
		total = total + elapsed
		if total < 2 then return end
		if next(promotes) then
			for k in pairs(promotes) do
				PromoteToAssistant(k)
				promotes[k] = nil
			end
			firedPromotes = true
			total = 0
		elseif firedPromotes then
			firedPromotes = nil
			total = 0
			self:SetScript("OnUpdate", nil)
		end
	end
	function queuePromotes()
		if oRA.groupStatus ~= oRA.INRAID then return end
		for i = 1, GetNumRaidMembers() do
			local n, r = GetRaidRosterInfo(i)
			if n and r == 0 and shouldPromote(n) then
				promotes[n] = true
			end
		end
		if next(promotes) then
			f:SetScript("OnUpdate", onUpdate)
		end
	end
	function module:OnGroupChanged(event, status, members)
		if #members > 0 and total == 0 then
			queuePromotes()
		end
	end

	function module:OnEnable()
		oRA.RegisterCallback(self, "OnGroupChanged")
		oRA.RegisterCallback(self, "OnGuildRanksUpdate")
		self:OnGuildRanksUpdate(nil, oRA:GetGuildRanks())
	end
end

function module:OnGuildRanksUpdate(event, r)
	if ranks then
		ranks:SetList(r)
		for i, v in ipairs(r) do
			ranks:SetItemValue(i, charDb.promoteRank[i])
		end
	end
end

