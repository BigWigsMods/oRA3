
local addonName, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Invite", "AceTimer-3.0")
local L = scope.locale
local AceGUI = LibStub("AceGUI-3.0")

-- GLOBALS: BNET_CLIENT_WOW FULL_PLAYER_NAME LE_PARTY_CATEGORY_INSTANCE NUM_LE_LFG_CATEGORYS MAX_PLAYER_LEVEL_TABLE
-- GLOBALS: GameFontHighlight PLAYER_DIFFICULTY1 PLAYER_DIFFICULTY2 PLAYER_DIFFICULTY6 RAID_DIFFICULTY
-- GLOBALS: SlashCmdList SLASH_ORAINVITE_GUILD1 SLASH_ORAINVITE_GUILD2 SLASH_ORAINVITE_ZONE1 SLASH_ORAINVITE_ZONE2
-- GLOBALS: SLASH_ORAINVITE_RANK1 SLASH_ORAINVITE_RANK2

local frame = nil
local db = nil
local peopleToInvite = {}
local rankButtons = {}
local difficultyDropdown, updateDifficultyDropdown = nil, nil -- a lot of effort for simply keeping the dialog in sync with the setting
local playerRealm = GetRealmName()
local playerFaction = UnitFactionGroup("player")

local function canInvite()
	return not IsInGroup() or oRA:IsPromoted()
end

local function showConfig()
	if not frame then module:CreateFrame() end
	oRA:SetAllPointsToPanel(frame.frame, true)
	frame.frame:Show()
end

local function hideConfig()
	if frame then
		frame:ReleaseChildren()
		frame:Release()
		frame = nil
		wipe(rankButtons)
	end
end

local doActualInvites = nil
do
	local function waitForRaid()
		if IsInRaid() then
			doActualInvites()
		else
			module:ScheduleTimer(waitForRaid, 1)
		end
	end

	local function waitForParty()
		if IsInGroup() then
			if not IsInRaid() then
				ConvertToRaid()
			end
			module:ScheduleTimer(waitForRaid, 1)
		else
			module:ScheduleTimer(waitForParty, 1)
		end
	end

	local function invite(player)
		if type(player) == "number" then
			BNInviteFriend(player)
		else
			InviteUnit(player)
		end
	end

	function doActualInvites()
		if #peopleToInvite == 0 then return end

		if not IsInRaid() then
			local pNum = GetNumSubgroupMembers() + 1 -- 1-5
			if pNum == 5 then
				-- party is full, convert to raid and invite the rest
				ConvertToRaid()
				module:ScheduleTimer(waitForRaid, 1)
			else
				-- invite people until the party is full
				for i = 1, math.min(5 - pNum, #peopleToInvite) do
					local player = tremove(peopleToInvite)
					invite(player)
				end
				-- invite the rest
				if #peopleToInvite > 0 then
					if not IsInGroup() then
						-- need someone to accept an invite before we can make a raid
						module:ScheduleTimer(waitForParty, 1)
					else
						ConvertToRaid()
						module:ScheduleTimer(waitForRaid, 1)
					end
				end
			end
		else
			for _, player in next, peopleToInvite do
				invite(player)
			end
			wipe(peopleToInvite)
		end
	end
end

local function doGuildInvites(level, zone, rank)
	for i = 1, GetNumGuildMembers() do
		local name, _, rankIndex, unitLevel, _, unitZone, _, _, online = GetGuildRosterInfo(i)
		if name and online then
			local unit = Ambiguate(name, "none")
			if not UnitInParty(unit) and not UnitInRaid(unit) and not UnitIsUnit(unit, "player") then
				if level and level <= unitLevel then
					peopleToInvite[#peopleToInvite + 1] = name
				elseif zone and zone == unitZone then
					peopleToInvite[#peopleToInvite + 1] = name
				elseif rank and rankIndex <= rank then
					peopleToInvite[#peopleToInvite + 1] = name
				end
			end
		end
	end
	doActualInvites()
end

local function inviteGuild()
	if not canInvite() then return end
	GuildRoster()
	local maxLevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
	SendChatMessage(L.invitePrintMaxLevel, "GUILD")
	module:ScheduleTimer(doGuildInvites, 10, maxLevel, nil, nil)
end

local function inviteZone()
	if not canInvite() then return end
	GuildRoster()
	local currentZone = GetRealZoneText()
	SendChatMessage((L.invitePrintZone):format(currentZone), "GUILD")
	module:ScheduleTimer(doGuildInvites, 10, nil, currentZone, nil)
end

local function inviteRank(rank, name)
	if not canInvite() then return end
	GuildRoster()
	GuildControlSetRank(rank)
	local _, _, ochat = GuildControlGetRankFlags()
	local channel = ochat and "OFFICER" or "GUILD"
	SendChatMessage((L.invitePrintRank):format(name), channel)
	module:ScheduleTimer(doGuildInvites, 10, nil, nil, rank-1)
end

local function inviteRankCommand(input)
	if not canInvite() or type(input) ~= "string" then return end
	input = input:lower()
	for index, rank in next, oRA:GetGuildRanks() do
		if rank:lower():find(input, nil, true) then
			inviteRank(index, rank)
			return
		end
	end
end

function module:OnRegister()
	local database = oRA.db:RegisterNamespace("Invite", {
		global = {
			keyword = nil,
			raidonly = false,
		},
	})
	db = database.global

	oRA:RegisterPanel(
		L.invite,
		showConfig,
		hideConfig
	)
	oRA.RegisterCallback(self, "OnGuildRanksUpdate")
	oRA.RegisterCallback(self, "OnStartup", updateDifficultyDropdown)
	oRA.RegisterCallback(self, "OnShutdown", updateDifficultyDropdown)
	oRA.RegisterCallback(self, "OnDifficultyChanged", updateDifficultyDropdown)

	SLASH_ORAINVITE_GUILD1 = "/rainv"
	SLASH_ORAINVITE_GUILD2 = "/rainvite"
	SlashCmdList.ORAINVITE_GUILD = inviteGuild

	SLASH_ORAINVITE_ZONE1 = "/razinv"
	SLASH_ORAINVITE_ZONE2 = "/razinvite"
	SlashCmdList.ORAINVITE_ZONE = inviteZone

	SLASH_ORAINVITE_RANK1 = "/rarinv"
	SLASH_ORAINVITE_RANK2 = "/rarinvite"
	SlashCmdList.ORAINVITE_RANK = inviteRankCommand
end

local function isInQueue()
	-- LFG
	for i=1, NUM_LE_LFG_CATEGORYS do
		local mode = GetLFGMode(i)
		if mode and mode ~= "lfgparty" then
			return true
		end
	end

	-- PvP
	for i=1, GetMaxBattlefieldID() do
		local status = GetBattlefieldStatus(i)
		if status and status ~= "none" then
			return true
		end
	end
end

local function getBattleNetToon(presenceId)
	local friendIndex = BNGetFriendIndex(presenceId)
	for i = 1, BNGetNumFriendToons(friendIndex) do
		local _, toonName, client, realmName, realmId, faction, _, _, _, _, _, _, _, _, _, toonId = BNGetFriendToonInfo(friendIndex, i)
		if client == BNET_CLIENT_WOW and faction == playerFaction and realmId > 0 then
			if realmName ~= "" and realmName ~= playerRealm then
				-- To my knowledge there is no API for trimming server names. I can only guess this is what Blizzard uses internally.
				realmName = realmName:gsub("[%s%-]", "")
				toonName = FULL_PLAYER_NAME:format(toonName, realmName)
			end
			return toonName, toonId
		end
	end
end

local function shouldInvite(msg, sender)
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) or isInQueue() then
		return false
	end

	msg = msg:trim():lower()
	local keyword = db.keyword and db.keyword:lower()
	local guildkeyword = db.guildkeyword and db.guildkeyword:lower()

	return msg == keyword or (msg == guildkeyword and oRA:IsGuildMember(sender))
end

local function handleWhisper(msg, sender, _, _, _, _, _, _, _, _, _, _, presenceId)
	if not canInvite() then return end
	if db.raidonly and not IsInRaid() then return end
	if presenceId > 0 then
		local id
		sender, id = getBattleNetToon(presenceId)
		if not id then return end
	end
	sender = Ambiguate(sender, "none")
	if shouldInvite(msg, sender) then
		local inInstance, instanceType = IsInInstance()
		if (inInstance and instanceType == "party" and GetNumSubgroupMembers() == 4) or GetNumGroupMembers() == 40 then
			local groupIsFull = ("<oRA3> %s"):format(L.invitePrintGroupIsFull)
			if presenceId > 0 then
				BNSendWhisper(presenceId, groupIsFull)
			else
				SendChatMessage(groupIsFull, "WHISPER", nil, sender)
			end
		else
			peopleToInvite[#peopleToInvite + 1] = sender
			doActualInvites()
		end
	end
end

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_BN_WHISPER", handleWhisper)
	self:RegisterEvent("CHAT_MSG_WHISPER", handleWhisper)
	self:RegisterEvent("PARTY_LEADER_CHANGED", updateDifficultyDropdown)
end

local function onControlEnter(widget, event, value)
	if not oRA.db.profile.showHelpTexts then return end
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
	GameTooltip:AddLine(widget.text and widget.text:GetText() or widget.label:GetText())
	GameTooltip:AddLine(widget:GetUserData("tooltip"), 1, 1, 1, 1)
	GameTooltip:Show()
end
local function onControlLeave() GameTooltip:Hide() end

local function updateRankButtons()
	if not frame then return end
	if not IsInGuild() then
		frame:ResumeLayout()
		frame:DoLayout()
		return
	end
	frame:PauseLayout()
	for i, button in next, rankButtons do
		button:Release()
	end
	wipe(rankButtons)
	local ranks = oRA:GetGuildRanks()
	for i = 1, #ranks do
		local rankName = ranks[i]
		local button = AceGUI:Create("Button")
		button:SetText(rankName)
		button:SetUserData("tooltip", L.inviteGuildRankDesc:format(rankName))
		button:SetUserData("rank", i)
		button:SetCallback("OnEnter", onControlEnter)
		button:SetCallback("OnLeave", onControlLeave)
		button:SetCallback("OnClick", function()
			inviteRank(i, rankName)
		end)
		button:SetRelativeWidth(0.33)
		table.insert(rankButtons, button)
		frame:AddChild(button)
	end
	frame:ResumeLayout()
	frame:DoLayout()
end

function module:OnGuildRanksUpdate(event, ranks)
	updateRankButtons()
end

local function saveKeyword(widget, event, value)
	if type(value) == "string" and value:trim():len() < 2 then value = nil end
	local key = widget:GetUserData("key")
	if value then value = value:lower() end
	db[key] = value
	widget:SetText(value)
end

function updateDifficultyDropdown()
	if not frame then return end
	if not IsInGroup() or UnitIsGroupLeader("player") then
		difficultyDropdown:SetDisabled(false)
	else
		difficultyDropdown:SetDisabled(true)
	end
	difficultyDropdown:SetValue(GetRaidDifficultyID())
	frame:ResumeLayout()
	frame:DoLayout()
end

local function difficultyCallback(widget, event, index, value)
	SetRaidDifficulties(true, index)
end

local function raidOnlyCallback(widget, event, value)
	db.raidonly = value and true or false
end

function module:CreateFrame()
	if frame then return end
	local inGuild = IsInGuild()
	frame = AceGUI:Create("ScrollFrame")
	frame:PauseLayout()
	frame:SetLayout("Flow")

	local modes = {
		[14] = PLAYER_DIFFICULTY1,
		[15] = PLAYER_DIFFICULTY2,
		[16] = PLAYER_DIFFICULTY6,
	}
	local difficulty = AceGUI:Create("Dropdown")
	difficulty:SetMultiselect(false)
	difficulty:SetLabel(RAID_DIFFICULTY)
	difficulty:SetList(modes)
	difficulty:SetValue(GetRaidDifficultyID())
	difficulty:SetCallback("OnValueChanged", difficultyCallback)
	difficulty:SetFullWidth(true)
	difficulty:SetDisabled(IsInGroup() and not UnitIsGroupLeader("player"))
	difficultyDropdown = difficulty

	local kwDescription = AceGUI:Create("Label")
	kwDescription:SetText(L.inviteDesc)
	kwDescription:SetFullWidth(true)
	kwDescription:SetFontObject(GameFontHighlight)

	local keyword = AceGUI:Create("EditBox")
	keyword:SetLabel(L.keyword)
	keyword:SetText(db.keyword)
	keyword:SetUserData("key", "keyword")
	keyword:SetUserData("tooltip", L.keywordDesc)
	keyword:SetCallback("OnEnter", onControlEnter)
	keyword:SetCallback("OnLeave", onControlLeave)
	keyword:SetCallback("OnEnterPressed", saveKeyword)
	keyword:SetRelativeWidth(0.5)

	local guildonlykeyword = AceGUI:Create("EditBox")
	guildonlykeyword:SetLabel(L.guildKeyword)
	guildonlykeyword:SetText(db.guildkeyword)
	guildonlykeyword:SetUserData("key", "guildkeyword")
	guildonlykeyword:SetUserData("tooltip", L.guildKeywordDesc)
	guildonlykeyword:SetCallback("OnEnter", onControlEnter)
	guildonlykeyword:SetCallback("OnLeave", onControlLeave)
	guildonlykeyword:SetCallback("OnEnterPressed", saveKeyword)
	guildonlykeyword:SetRelativeWidth(0.5)

	local raidonly = AceGUI:Create("CheckBox")
	raidonly:SetLabel(L.inviteInRaidOnly)
	raidonly:SetValue(db.raidonly)
	raidonly:SetCallback("OnValueChanged", raidOnlyCallback)
	raidonly:SetFullWidth(true)

	local guild, zone, rankHeader, rankDescription
	if inGuild then
		guild = AceGUI:Create("Button")
		guild:SetText(L.inviteGuild)
		guild:SetUserData("tooltip", L.inviteGuildDesc)
		guild:SetCallback("OnEnter", onControlEnter)
		guild:SetCallback("OnLeave", onControlLeave)
		guild:SetCallback("OnClick", inviteGuild)
		guild:SetFullWidth(true)

		zone = AceGUI:Create("Button")
		zone:SetText(L.inviteZone)
		zone:SetUserData("tooltip", L.inviteZoneDesc)
		zone:SetCallback("OnEnter", onControlEnter)
		zone:SetCallback("OnLeave", onControlLeave)
		zone:SetCallback("OnClick", inviteZone)
		zone:SetFullWidth(true)

		rankHeader = AceGUI:Create("Heading")
		rankHeader:SetText(L.guildRankInvites)
		rankHeader:SetFullWidth(true)

		rankDescription = AceGUI:Create("Label")
		rankDescription:SetText(L.guildRankInvitesDesc)
		rankDescription:SetFullWidth(true)
		rankDescription:SetFontObject(GameFontHighlight)
	end

	if inGuild then
		if oRA.db.profile.showHelpTexts then
			frame:AddChildren(difficulty, guild, zone, kwDescription, keyword, guildonlykeyword, raidonly, rankHeader, rankDescription)
		else
			frame:AddChildren(difficulty, guild, zone, keyword, guildonlykeyword, raidonly, rankHeader)
		end
	else
		if oRA.db.profile.showHelpTexts then
			frame:AddChildren(difficulty, kwDescription, keyword, raidonly)
		else
			frame:AddChild(difficulty, keyword, raidonly)
		end
	end

	-- updateRankButtons will ResumeLayout and DoLayout
	updateRankButtons()
end

