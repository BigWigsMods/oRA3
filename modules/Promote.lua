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
local factionDb = nil
local charDb = nil

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
	
	self:CreateFrame()
	
	oRA:RegisterOverview(
		"Promotes",
		"Interface\\Icons\\INV_Scroll_03",
		showConfig,
		hideConfig
	)
end

local promote
do
	local function shouldPromote(name)
		if factionDb.promoteAll then return true
		elseif factionDb.promoteGuild and guildMemberList[name] then return true
		elseif guildMemberList[name] and charDb.promoteRank[guildMemberList[name]] then return true
		elseif factionDb.promotes[name] then return true
		end
	end

	local f = CreateFrame("Frame")
	local total = 0
	local firedPromotes = nil
	local promotes = {}
	local function onUpdate(self, elapsed)
		total = total + elapsed
		if total > 1 and next(promotes) then
			for k in pairs(promotes) do
				PromoteToAssistant(k)
				promotes[k] = nil
			end
			firedPromotes = true
			total = 0
		elseif total > 2 and firedPromotes then
			self:RegisterEvent("RAID_ROSTER_UPDATE")
			firedPromotes = nil
			total = 0
			self:SetScript("OnUpdate", nil)
		elseif total > 3 then
			promote()
		end
	end
	function promote()
		for i = 1, GetNumRaidMembers() do
			local n, r = GetRaidRosterInfo(i)
			if n and r == 0 and shouldPromote(n) then
				promotes[n] = true
			end
		end
		total = 0
		if next(promotes) then
			f:UnregisterEvent("RAID_ROSTER_UPDATE")
			f:SetScript("OnUpdate", onUpdate)
		else
			f:SetScript("OnUpdate", nil)
		end
	end
	f:SetScript("OnEvent", function(self)
		if total == 0 then
			self:SetScript("OnUpdate", onUpdate)
		else
			total = 0
		end
	end)

	function module:OnEnable()
		self:RegisterEvent("GUILD_ROSTER_UPDATE")
		f:RegisterEvent("RAID_ROSTER_UPDATE")

		if IsInGuild() then GuildRoster() end
	end
	
	function module:OnDisable()
		f:UnregisterEvent("RAID_ROSTER_UPDATE")
	end
end


function module:GUILD_ROSTER_UPDATE()
	wipe(guildRanks)
	for i = 1, GuildControlGetNumRanks() do
		table.insert(guildRanks, GuildControlGetRankName(i))
	end
	ranks:SetList(guildRanks)
	for i, v in ipairs(guildRanks) do
		ranks:SetItemValue(i, charDb.promoteRank[i])
	end

	wipe(guildMemberList)
	local numGuildMembers = GetNumGuildMembers()
	for i = 1, numGuildMembers do
		local name, rank, rankIndex = GetGuildRosterInfo(i)
		if name then
			guildMemberList[name] = rankIndex
		end
	end
end

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

	local f = AceGUI:Create("SimpleGroup")
	f:SetWidth(340)
	f:SetHeight(400)

	local spacer = AceGUI:Create("Label")
	spacer:SetText(" ")
	spacer.width = "fill"

	local massHeader = AceGUI:Create("Heading")
	massHeader:SetText("Mass promotion")
	massHeader.width = "fill"

	everyone = AceGUI:Create("CheckBox")
	everyone:SetValue(factionDb.promoteAll)
	everyone:SetLabel("Everyone")
	everyone:SetCallback("OnEnter", onControlEnter)
	everyone:SetCallback("OnLeave", onControlLeave)
	everyone:SetCallback("OnValueChanged", function(widget, event, value)
		guild:SetDisabled(value)
		ranks:SetDisabled(value or factionDb.promoteGuild)
		add:SetDisabled(value)
		delete:SetDisabled(value or #factionDb.promotes < 1)
		factionDb.promoteAll = value and true or false
		promote()
	end)
	everyone.oRATooltipText = "Promote everyone automatically."
	everyone.width = "fill"

	guild = AceGUI:Create("CheckBox")
	guild:SetValue(factionDb.promoteGuild)
	guild:SetLabel("Guild")
	guild:SetCallback("OnEnter", onControlEnter)
	guild:SetCallback("OnLeave", onControlLeave)
	guild:SetCallback("OnValueChanged", function(widget, event, value)
		ranks:SetDisabled(value)
		factionDb.promoteGuild = value and true or false
		promote()
	end)
	guild.oRATooltipText = "Promote all guild members automatically."
	guild:SetDisabled(factionDb.promoteAll)
	guild.width = "fill"

	ranks = AceGUI:Create("Dropdown")
	ranks:SetMultiselect(true)
	ranks:SetLabel("By guild rank")
	ranks:SetList(guildRanks)
	ranks:SetCallback("OnValueChanged", function(widget, event, rankIndex, value)
		charDb.promoteRank[rankIndex] = value and true or nil
		promote()
	end)
	ranks:SetDisabled(factionDb.promoteAll or factionDb.promoteGuild)
	ranks.width = "fill"

	local individualHeader = AceGUI:Create("Heading")
	individualHeader:SetText("Individual promotions")
	individualHeader.width = "fill"

	local description = AceGUI:Create("Label")
	description:SetText("Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below.")
	description.width = "fill"

	add = AceGUI:Create("EditBox")
	add:SetLabel("Add")
	add:SetText()
	add:SetCallback("OnEnterPressed", function(widget, event, value)
		if type(value) ~= "string" or value:trim():len() < 3 then return true end
		if util:inTable(factionDb.promotes, value) then return true end
		table.insert(factionDb.promotes, value)
		add:SetText()
		delete:SetList(factionDb.promotes)
		delete:SetDisabled(factionDb.promoteAll or #factionDb.promotes < 1)
		promote()
	end)
	add:SetDisabled(factionDb.promoteAll)
	add.width = "fill"

	delete = AceGUI:Create("Dropdown")
	delete:SetValue("")
	delete:SetLabel("Remove")
	delete:SetList(factionDb.promotes)
	delete:SetCallback("OnValueChanged", function(_, _, value)
		table.remove(factionDb.promotes, value)
		delete:SetList(factionDb.promotes)
		delete:SetValue("")
		delete:SetDisabled(factionDb.promoteAll or #factionDb.promotes < 1)
	end)
	delete:SetDisabled(factionDb.promoteAll or #factionDb.promotes < 1)
	delete.width = "fill"

	f:AddChild(massHeader)
	f:AddChild(everyone)
	f:AddChild(guild)
	f:AddChild(ranks)
	f:AddChild(spacer)
	f:AddChild(individualHeader)
	f:AddChild(description)
	f:AddChild(add)
	f:AddChild(delete)

	frame = f
end

