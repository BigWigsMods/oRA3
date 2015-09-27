
local addonName, scope = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceTimer-3.0")
scope.addon = addon
local L = scope.locale

-- GLOBALS: oRA3 oRA3Frame RAID_CLASS_COLORS CUSTOM_CLASS_COLORS RaidFrame RaidInfoFrame oRA3DisbandButton oRA3CheckButton
-- GLOBALS: SlashCmdList SLASH_ORA1 SLASH_ORA2 SLASH_ORADISBAND1 BINDING_HEADER_oRA3 BINDING_NAME_TOGGLEORA3
-- GLOBALS: GameFontNormal GameFontNormalSmall GameFontDisableSmall GameFontHighlightSmall
-- GLOBALS: UIPanelWindows PanelTemplates_SetTab PanelTemplates_SetNumTabs PanelTemplates_UpdateTabs
-- GLOBALS: FauxScrollFrame_Update FauxScrollFrame_Update FauxScrollFrame_OnVerticalScroll FauxScrollFrame_GetOffset
-- GLOBALS: StaticPopupDialogs STATICPOPUP_NUMDIALOGS StaticPopup_Show

local CallbackHandler = LibStub("CallbackHandler-1.0")
local LGIST = LibStub("LibGroupInSpecT-1.1")

BINDING_HEADER_oRA3 = addonName
BINDING_NAME_TOGGLEORA3 = L.togglePane

local classColors = setmetatable({UNKNOWN = {r = 0.8, g = 0.8, b = 0.8, colorStr = "ffcccccc"}}, {__index = function(self) return self.UNKNOWN end})
for k, v in next, RAID_CLASS_COLORS do classColors[k] = v end
addon.classColors = classColors

local _testUnits = {
	Wally = "WARRIOR",
	Kingkong = "DEATHKNIGHT",
	Apenuts = "PALADIN",
	Foobar = "DRUID",
	Eric = "WARLOCK",
	Dylan = "ROGUE",
	Hicks = "MAGE",
	Python = "PRIEST",
	Purple = "HUNTER",
	Tor = "SHAMAN",
	Ling = "MONK",
}
addon._testUnits = _testUnits

local coloredNames = setmetatable({}, {__index =
	function(self, key)
		if type(key) == "nil" then return nil end
		local class = select(2, UnitClass(key)) or _testUnits[key]
		if class then
			self[key] = string.format("|c%s%s|r", classColors[class].colorStr, key:gsub("%-.+", ""))
			return self[key]
		else
			return string.format("|cffcccccc<%s>|r", key:gsub("%-.+", ""))
		end
	end
})
addon.coloredNames = coloredNames

addon.util = {}
local util = addon.util
function util.inTable(t, value, subindex)
	for k, v in next, t do
		if subindex then
			if type(v) == "table" and v[subindex] == value then
				return k
			end
		elseif v == value then
			return k
		end
	end
	return nil
end

-- Locals

local playerName = UnitName("player")
local oraFrame = CreateFrame("Frame", "oRA3Frame", UIParent)

local guildMemberList = {} -- Name:RankIndex
local guildRanks = {} -- Index:RankName
local groupMembers = {} -- Index:Name
local tanks = {} -- Index:Name
local playerPromoted = nil

-- couple of local constants used for party size
local UNGROUPED = 0
local INPARTY = 1
local INRAID = 2
local ININSTANCE = 3
local groupStatus = UNGROUPED -- flag indicating groupsize

-- overview drek
local openedList = nil -- index of the current opened List
local contentFrame = nil -- content frame for the views
local scrollheaders = {} -- scrollheader frames
local scrollhighs = {} -- scroll highlights
local secureScrollhighs = {} -- clickable secure scroll highlights

local function actuallyDisband()
	if groupStatus > 0 and groupStatus < 3 and (addon:IsPromoted() or 0) > 1 then
		SendChatMessage("<oRA3> ".. L.disbandingGroupChatMsg, IsInRaid() and "RAID" or "PARTY")
		for _, unit in next, groupMembers do
			if not UnitIsUnit(unit, "player") then
				UninviteUnit(unit)
			end
		end
		addon:ScheduleTimer(LeaveParty, 2)
	end
end

local lists = {}
local panels = {}

local db
local defaults = {
	profile = {
		positions = {},
		showHelpTexts = true,
		toggleWithRaid = true,
		showRoleIcons = true,
		lastSelectedPanel = nil,
		lastSelectedList = nil,
		open = false,
	},
}

local showLists -- implemented down the file
local hideLists -- implemented down the file
local function colorize(input) return string.format("|cfffed000%s|r", input) end
local options = {
	name = "oRA",
	type = "group",
	get = function(info) return db[info[#info]] end,
	set = function(info, value) db[info[#info]] = value end,
	args = {
		general = {
			order = 1,
			type = "group",
			name = "oRA",
			args = {
				toggleWithRaid = {
					type = "toggle",
					name = colorize(L.toggleWithRaid),
					desc = L.toggleWithRaidDesc,
					descStyle = "inline",
					order = 1,
					width = "full",
				},
				showRoleIcons = {
					type = "toggle",
					name = colorize(L.showRoleIcons),
					desc = L.showRoleIconsDesc,
					descStyle = "inline",
					order = 2,
					width = "full",
				},
				showHelpTexts = {
					type = "toggle",
					name = colorize(L.showHelpTexts),
					desc = L.showHelpTextsDesc,
					descStyle = "inline",
					order = 4,
					width = "full",
				},
				slashCommands = {
					type = "group",
					name = L.slashCommandsHeader,
					width = "full",
					inline = true,
					order = 5,
					args = {
						slashCommandHelp = {
							type = "description",
							name = L.slashCommands,
							width = "full",
						},
					},
				},
			},
		},
	}
}
LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("oRA", options, true)
LibStub("AceConfigDialog-3.0"):SetDefaultSize("oRA", 760, 600)

-------------------------------------------------------------------------------
-- Event handling
--

do
	local noEvent = "Module %q tried to register/unregister an event without specifying which event."
	local noFunc = "Module %q tried to register an event with the function '%s' which doesn't exist in the module."

	local eventMap = {}
	oraFrame:SetScript("OnEvent", function(_, event, ...)
		for k,v in next, eventMap[event] do
			if type(v) == "function" then
				v(...)
			else
				k[v](k, ...)
			end
		end
	end)

	function addon:RegisterEvent(event, func)
		if type(event) ~= "string" then error((noEvent):format(self.moduleName)) end
		if (not func and not self[event]) or (type(func) == "string" and not self[func]) then error((noFunc):format(self.moduleName, func or event)) end
		if not eventMap[event] then eventMap[event] = {} end
		eventMap[event][self] = func or event
		oraFrame:RegisterEvent(event)
	end
	function addon:UnregisterEvent(event)
		if type(event) ~= "string" then error((noEvent):format(self.moduleName)) end
		if not eventMap[event] then return end
		eventMap[event][self] = nil
		if not next(eventMap[event]) then
			oraFrame:UnregisterEvent(event)
			eventMap[event] = nil
		end
	end
	function addon:UnregisterAllEvents()
		for k,v in next, eventMap do
			for j in next, v do
				if j == self then
					self:UnregisterEvent(k)
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Init
--

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("oRA3DB", defaults, true)
	LibStub("LibDualSpec-1.0"):EnhanceDatabase(self.db, "oRA")

	-- Comm register
	RegisterAddonMessagePrefix("oRA")

	-- callbackhandler for comm
	self.callbacks = CallbackHandler:New(self)

	local function profileUpdate()
		db = self.db.profile
		self.callbacks:Fire("OnProfileUpdate")
	end

	self.db.RegisterCallback(self, "OnProfileChanged", profileUpdate)
	self.db.RegisterCallback(self, "OnProfileCopied", profileUpdate)
	self.db.RegisterCallback(self, "OnProfileReset", profileUpdate)

	self:RegisterPanel(L.checks, showLists, hideLists)

	options.args.general.args.profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	options.args.general.args.profileOptions.order = 1
	options.args.general.args.profileOptions.args.desc.fontSize = "medium"
	LibStub("LibDualSpec-1.0"):EnhanceOptions(options.args.general.args.profileOptions, self.db)

	local function OnRaidHide()
		if addon:IsEnabled() and db.toggleWithRaid and oRA3Frame then
			HideUIPanel(oRA3Frame)
		end
	end
	RaidFrame:HookScript("OnHide", OnRaidHide)
	if not IsAddOnLoaded("Blizzard_RaidUI") then
		self.rehookAfterRaidUILoad = true
	end

	RaidFrame:HookScript("OnShow", function()
		if addon:IsEnabled() and db.toggleWithRaid then
			addon:ToggleFrame(true)
		end
		if addon.rehookAfterRaidUILoad and IsAddOnLoaded("Blizzard_RaidUI") then
			-- Blizzard_RaidUI overwrites the RaidFrame "OnHide" script squashing the hook registered above, so re-hook.
			addon.rehookAfterRaidUILoad = nil
			RaidFrame:HookScript("OnHide", OnRaidHide)
		end
	end)

	RaidInfoFrame:HookScript("OnShow", function()
		if addon:IsEnabled() and oRA3Frame and oRA3Frame:IsShown() then
			addon.toggle = true
			HideUIPanel(oRA3Frame)
		end
	end)
	RaidInfoFrame:HookScript("OnHide", function()
		if addon:IsEnabled() and addon.toggle then
			addon:ToggleFrame(true)
			addon.toggle = nil
		end
	end)

	db = self.db.profile

	self.OnInitialize = nil
end

function addon:RegisterModuleOptions(name, optionTbl)
	options.args.general.args[name] = optionTbl
end

function addon:OnEnable()
	-- Roster Status Events
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("CHAT_MSG_ADDON", "OnCommReceived")
	LGIST.RegisterCallback(self, "GroupInSpecT_Update")
	LGIST.RegisterCallback(self, "GroupInSpecT_Remove")
	LGIST.RegisterCallback(self, "GroupInSpecT_InspectReady")

	SLASH_ORA1 = "/ora"
	SLASH_ORA2 = "/ora3"
	SlashCmdList.ORA = function()
		LibStub("AceConfigDialog-3.0"):Open("oRA")
	end

	SLASH_ORADISBAND1 = "/radisband"
	SlashCmdList.ORADISBAND = actuallyDisband

	-- init groupStatus
	self:GROUP_ROSTER_UPDATE()
	if IsInGuild() then GuildRoster() end

	if CUSTOM_CLASS_COLORS then
		local function updateClassColors()
			for k, v in next, CUSTOM_CLASS_COLORS do
				classColors[k] = v
			end
			wipe(coloredNames)
		end
		CUSTOM_CLASS_COLORS:RegisterCallback(updateClassColors)
		updateClassColors()
	end
end

function addon:OnDisable()
	self:UnregisterAllEvents()
	HideUIPanel(oRA3Frame) -- nil-safe
end

do
	local unitJoinedParty = '^' .. JOINED_PARTY:gsub("%%s", "(%%S+)") .. '$'
	local unitJoinedRaid = '^' .. ERR_RAID_MEMBER_ADDED_S:gsub("%%s", "(%%S+)") .. '$'
	local unitJoinedInstanceGroup = '^' .. ERR_INSTANCE_GROUP_ADDED_S:gsub("%%s", "(%%S+)") .. '$'
	local difficultyChanged = '^' .. ERR_RAID_DIFFICULTY_CHANGED_S:gsub("%%s", ".-") .. '$'
	function addon:CHAT_MSG_SYSTEM(msg)
		if msg:find(difficultyChanged) then
			-- firing PLAYER_DIFFICULTY_CHANGED outside of instances would be nice ;[
			self.callbacks:Fire("OnDifficultyChanged")
		elseif IsInGroup() then
			local name = msg:match(unitJoinedParty) or msg:match(unitJoinedInstanceGroup) or msg:match(unitJoinedRaid)
			if name and rawget(coloredNames, name) then
				coloredNames[name] = nil
			end
		end
	end
end

-----------------------------------------------------------------------
-- Guild and group roster
--

do
	local playerCache = {}

	local function guidToUnit(guid)
		local info = playerCache[guid]
		if info and UnitGUID(info.unit) == guid then
			return info.unit
		end

		local token = IsInRaid() and "raid%d" or "party%d"
		for i = 1, GetNumGroupMembers() do
			local unit = token:format(i)
			if UnitGUID(unit) == guid then
				return unit
			end
		end
		if UnitGUID("player") == guid then
			return "player"
		end
	end

	function addon:OnGroupJoined()
		for guid, info in next, playerCache do
			-- check for stale entries
			if guid ~= UnitGUID(info.name) then
				self.callbacks:Fire("OnPlayerRemove", guid)
				playerCache[guid] = nil
			end
		end
		self:OnGroupChanged()
		LGIST:Rescan() -- requeue previously inspected players
	end

	function addon:OnGroupChanged()
		for _, player in next, groupMembers do
			local guid = UnitGUID(player)
			local _, class = UnitClass(player)
			if guid and not playerCache[guid] and class then
				local unit = guidToUnit(guid) or ""
				playerCache[guid] = {
					guid = guid,
					unit = unit,
					name = player,
					class = class,
					level = UnitLevel(player),
					glyphs = {},
					talents = {},
				}
				-- initial update with no inspect info
				self.callbacks:Fire("OnPlayerUpdate", guid, unit, playerCache[guid])
			end
		end
	end

	function addon:GroupInSpecT_Update(_, guid, unit, info)
		if not guid or not info.class then return end

		if not playerCache[guid] then
			playerCache[guid] = {
				guid = guid,
				unit = "",
				glyphs = {},
				talents = {},
			}
		end
		local cache = playerCache[guid]
		cache.name = info.name
		cache.class = info.class
		cache.level = UnitLevel(unit)
		cache.unit = unit ~= "player" and unit or guidToUnit(guid) or ""

		if info.global_spec_id and info.global_spec_id > 0 then
			cache.spec = info.global_spec_id

			wipe(cache.glyphs)
			for spellId in next, info.glyphs do
				cache.glyphs[spellId] = true
			end
			wipe(cache.talents)
			for talentId, talentInfo in next, info.talents do
				-- easier to look up by index than to try and check multiple talent spell ids
				local index = 3 * (talentInfo.tier - 1) + talentInfo.column
				cache.talents[index] = talentId
			end
		end
		self.callbacks:Fire("OnPlayerUpdate", guid, unit, cache)
	end

	function addon:GroupInSpecT_Remove(_, guid)
		self.callbacks:Fire("OnPlayerRemove", guid, playerCache[guid])
		playerCache[guid] = nil
	end

	function addon:GroupInSpecT_InspectReady(_, guid, unit)
		self.callbacks:Fire("OnPlayerInspect", guid, unit)
	end

	function addon:InspectGroup()
		LGIST:Rescan()
	end

	function addon:GetPlayerInfo(guid)
		return playerCache[guid]
	end
end

do
	local function isIndexedEqual(a, b)
		if #a ~= #b then return false end
		for i = 1, #a do
			if a[i] ~= b[i] then return false end
		end
		return true
	end
	local function isKeyedEqual(a, b)
		for k, v in next, a do
			if v ~= b[k] then return false end
		end
		for k, v in next, b do
			if v ~= a[k] then return false end
		end
		return true
	end
	local function copyToTable(src, dst)
		wipe(dst)
		for i, v in next, src do
			dst[i] = v
		end
	end

	local tmpRanks = {}
	local tmpMembers = {}
	local Ambiguate = Ambiguate
	function addon:GUILD_ROSTER_UPDATE()
		wipe(tmpRanks)
		wipe(tmpMembers)
		for i = 1, GuildControlGetNumRanks() do
			tmpRanks[#tmpRanks + 1] = GuildControlGetRankName(i)
		end
		for i = 1, GetNumGuildMembers(true) do
			local name, _, rankIndex = GetGuildRosterInfo(i)
			if name then
				tmpMembers[Ambiguate(name, "none")] = rankIndex + 1
			end
		end
		if not isIndexedEqual(tmpRanks, guildRanks) then
			copyToTable(tmpRanks, guildRanks)
			self.callbacks:Fire("OnGuildRanksUpdate", guildRanks)
		end
		if not isKeyedEqual(tmpMembers, guildMemberList) then
			copyToTable(tmpMembers, guildMemberList)
			self.callbacks:Fire("OnGuildMembersUpdate", guildMemberList)
		end
	end
	function addon:GetGuildRanks() return guildRanks end
	function addon:GetGuildMembers() return guildMemberList end
	function addon:IsGuildMember(name) return guildMemberList[name] end
	function addon:GetGroupMembers() return groupMembers end
	function addon:GetGroupStatus() return groupStatus end
	function addon:GetClassMembers(class)
		local tmp = {}
		for i, unit in next, groupMembers do
			if UnitClass(unit) == class then tmp[unit] = true end
		end
		return tmp
	end
	function addon:GetBlizzardTanks() return tanks end

	local tmpGroup = {}
	local tmpTanks = {}

	function addon:GROUP_ROSTER_UPDATE()
		local oldStatus = groupStatus
		groupStatus = IsInGroup(2) and ININSTANCE or IsInRaid() and INRAID or IsInGroup() and INPARTY or UNGROUPED

		wipe(tmpGroup)
		wipe(tmpTanks)
		if IsInRaid() then
			for i = 1, GetNumGroupMembers() do
				local n, _, _, _, _, _, _, _, _, role = GetRaidRosterInfo(i)
				if n then
					tmpGroup[#tmpGroup + 1] = n
					if role == "MAINTANK" then
						tmpTanks[#tmpTanks + 1] = n
					end
				end
			end
		elseif IsInGroup() then
			tinsert(tmpGroup, playerName)
			for i = 1, 4 do
				local n,s = UnitName(("party%d"):format(i))
				if s and s ~= "" then n = n.."-"..s end
				if n then tmpGroup[#tmpGroup + 1] = n end
			end
		end
		if oldStatus ~= groupStatus or not isIndexedEqual(tmpGroup, groupMembers) then
			copyToTable(tmpGroup, groupMembers)
			self:OnGroupChanged()
			self.callbacks:Fire("OnGroupChanged", groupStatus, groupMembers)
		end
		if not isIndexedEqual(tmpTanks, tanks) then
			-- Added this check in case we demote a MT but he still has tank role set as the tanks module
			-- may need to adjust based on preferences.
			copyToTable(tmpTanks, tanks)
			self.callbacks:Fire("OnTanksChanged", tanks)
		end
		if groupStatus == UNGROUPED and oldStatus > groupStatus then
			self:OnShutdown(groupStatus)
			self.callbacks:Fire("OnShutdown", groupStatus)
		elseif oldStatus == UNGROUPED and groupStatus > oldStatus then
			self:OnStartup(groupStatus)
			self.callbacks:Fire("OnStartup", groupStatus)
			self:OnGroupJoined()
		end
		if oldStatus == INPARTY and groupStatus == INRAID then
			self.callbacks:Fire("OnConvertRaid", groupStatus)
		end
		if oldStatus == INRAID and groupStatus == INPARTY then
			self.callbacks:Fire("OnConvertParty", groupStatus)
		end
		if playerPromoted ~= self:IsPromoted() then
			playerPromoted = self:IsPromoted()
			if playerPromoted then
				self:OnPromoted(playerPromoted)
				self.callbacks:Fire("OnPromoted", playerPromoted)
			else
				self:OnDemoted()
				self.callbacks:Fire("OnDemoted")
			end
		end
	end
end

function addon:IsPromoted(name)
	if groupStatus == UNGROUPED then return end

	if not name then name = "player" end
	if UnitIsGroupLeader(name) then
		return 3
	elseif IsEveryoneAssistant() then
		return 1
	elseif UnitIsGroupAssistant(name) then
		return 2
	end
end

-----------------------------------------------------------------------
-- Comm handling
--

function addon:SendComm(...)
	if groupStatus == UNGROUPED then
		addon.callbacks:Fire("OnCommReceived", playerName, ...)
	elseif not UnitInBattleground("player") then
		SendAddonMessage("oRA", strjoin(" ", ...), IsPartyLFG() and "INSTANCE_CHAT" or "RAID")
	end
end

function addon:OnCommReceived(prefix, message, distribution, sender)
	if prefix == "oRA" then
		self.callbacks:Fire("OnCommReceived", Ambiguate(sender, "none"), strsplit(" ", message))
	end
end

-----------------------------------------------------------------------
-- oRA3 main window
--

local function setupGUI()
	local frame = oraFrame
	UIPanelWindows["oRA3Frame"] = { area = "left", pushable = 3, whileDead = 1, yoffset = 12, xoffset = -16 }
	HideUIPanel(oRA3Frame)

	frame:SetWidth(384)
	frame:SetHeight(512)

	frame:SetHitRectInsets(0, 30, 0, 45)
	frame:SetToplevel(true)
	frame:EnableMouse(true)

	local topleft = frame:CreateTexture(nil, "ARTWORK")
	topleft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft")
	topleft:SetWidth(256)
	topleft:SetHeight(256)
	topleft:SetPoint("TOPLEFT")

	local toplefticon = frame:CreateTexture(nil, "BACKGROUND")
	toplefticon:SetWidth(60)
	toplefticon:SetHeight(60)
	toplefticon:SetPoint("TOPLEFT", 7, -6)
	SetPortraitToTexture(toplefticon, "Interface\\WorldMap\\Gear_64Grey")

	local topright = frame:CreateTexture(nil, "ARTWORK")
	topright:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight")
	topright:SetWidth(128)
	topright:SetHeight(256)
	topright:SetPoint("TOPRIGHT")

	local botleft = frame:CreateTexture(nil, "ARTWORK")
	botleft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft")
	botleft:SetWidth(256)
	botleft:SetHeight(256)
	botleft:SetPoint("BOTTOMLEFT")

	local botright = frame:CreateTexture(nil, "ARTWORK")
	botright:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight")
	botright:SetWidth(128)
	botright:SetHeight(256)
	botright:SetPoint("BOTTOMRIGHT")

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -30, -8)

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetWidth(256)
	title:SetHeight(16)
	title:SetPoint("TOP", 4, -16)
	frame.title = title

	local drag = frame:CreateTitleRegion()
	drag:SetAllPoints(title)

	local disband = CreateFrame("Button", "oRA3DisbandButton", frame, "UIPanelButtonTemplate")
	disband:SetWidth(120)
	disband:SetHeight(22)
	disband:SetNormalFontObject(GameFontNormalSmall)
	disband:SetHighlightFontObject(GameFontHighlightSmall)
	disband:SetDisabledFontObject(GameFontDisableSmall)
	disband:SetText(L.disbandGroup)
	disband:SetPoint("TOPLEFT", 72, -37)
	disband:SetScript("OnClick", function()
		if not StaticPopupDialogs["oRA3DisbandGroup"] then
			StaticPopupDialogs["oRA3DisbandGroup"] = {
				text = L.disbandGroupWarning,
				button1 = YES,
				button2 = NO,
				whileDead = 1,
				hideOnEscape = 1,
				timeout = 0,
				OnAccept = actuallyDisband,
				preferredIndex = STATICPOPUP_NUMDIALOGS,
			}
		end
		if IsControlKeyDown() then
			actuallyDisband()
		else
			StaticPopup_Show("oRA3DisbandGroup")
		end
	end)
	if (addon:IsPromoted() or 0) > 1 and not IsInGroup(2) then
		disband:Enable()
	else
		disband:Disable()
	end
	disband.tooltipText = L.disbandGroup
	disband.newbieText = L.disbandGroupDesc

	local consumables = addon:GetModule("Consumables")
	local check = CreateFrame("Button", "oRA3CheckButton", frame, "UIPanelButtonTemplate")
	check:SetWidth(120)
	check:SetHeight(22)
	check:SetNormalFontObject(GameFontNormalSmall)
	check:SetHighlightFontObject(GameFontHighlightSmall)
	check:SetDisabledFontObject(GameFontDisableSmall)
	check:SetText(L.consumables)
	check:SetEnabled(IsInGroup() and (consumables.db.profile.output > 1 or consumables.db.profile.whisper))
	check:SetPoint("TOPRIGHT", -40, -37)
	check:SetScript("OnClick", function()
		consumables:OutputResults(true)
	end)
	check.module = consumables

	local options = CreateFrame("Button", "oRA3OptionsButton", frame)
	options:SetNormalTexture("Interface\\Worldmap\\Gear_64")
	options:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5)
	options:SetHighlightTexture("Interface\\Worldmap\\Gear_64")
	options:GetHighlightTexture():SetTexCoord(0, 0.5, 0, 0.5)
	options:SetSize(16, 16)
	options:SetPoint("RIGHT", title, "RIGHT")
	options:SetScript("OnClick", function()
		LibStub("AceConfigDialog-3.0"):SelectGroup("oRA", "general")
		LibStub("AceConfigDialog-3.0"):Open("oRA")
	end)

	local function selectPanel(self)
		PlaySound("igCharacterInfoTab")
		addon:SelectPanel(self:GetText())
	end
	for i, tab in ipairs(panels) do
		local f = CreateFrame("Button", "oRA3FrameTab"..i, frame, "CharacterFrameTabButtonTemplate")
		if i > 1 then
			f:SetPoint("TOPLEFT", _G["oRA3FrameTab"..(i - 1)], "TOPRIGHT", -16, 0)
		else
			f:SetPoint("BOTTOMLEFT", 11, 49)
		end
		f:SetText(tab.name)
		f:SetScript("OnClick", selectPanel)
		f:SetScale(0.95)

		PanelTemplates_SetNumTabs(frame, i)
	end
	PanelTemplates_SetTab(frame, 1)

	local subframe = CreateFrame("Frame", nil, frame)
	subframe:SetPoint("TOPLEFT", 18, -70)
	subframe:SetPoint("BOTTOMRIGHT", -40, 78)
	contentFrame = subframe


	-- CHECKS GUI

	local listFrame = CreateFrame("Frame", "oRA3ListFrame", subframe)
	listFrame:SetAllPoints(subframe)

	-- Scrolling body
	local sframe = CreateFrame("ScrollFrame", "oRA3ScrollFrame", listFrame, "FauxScrollFrameTemplate")
	sframe:SetPoint("BOTTOMLEFT", listFrame, 0, 33)
	sframe:SetPoint("TOPRIGHT", listFrame, -26, -27)

	local function updScroll() addon:UpdateScroll() end
	sframe:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 16, updScroll)
	end)

	subframe.scrollFrame = sframe
	subframe.listFrame = listFrame

	local sframebottom = CreateFrame("Frame", "oRA3ScrollFrameBottom", listFrame)
	sframebottom:SetPoint("TOPLEFT", sframe, "BOTTOMLEFT", 0, -1)
	sframebottom:SetPoint("BOTTOMRIGHT", subframe, "BOTTOMRIGHT")
	sframebottom:SetFrameLevel(subframe:GetFrameLevel())

	local bar = CreateFrame("Button", nil, sframebottom)
	bar:SetPoint("TOPLEFT", sframebottom, 3, 3)
	bar:SetPoint("TOPRIGHT", sframebottom, -4, 3)
	bar:SetHeight(8)

	local barmiddle = bar:CreateTexture(nil, "BORDER")
	barmiddle:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	barmiddle:SetAllPoints(bar)
	barmiddle:SetTexCoord(0.29296875, 1, 0, 0.25)

	local sframetop = CreateFrame("Frame", "oRA3ScrollFrameTop", listFrame)
	sframetop:SetPoint("TOPLEFT", subframe)
	sframetop:SetPoint("TOPRIGHT", subframe)
	sframetop:SetHeight(27)

	bar = CreateFrame("Button", nil, sframetop)
	bar:SetPoint("BOTTOMLEFT", sframetop, 3, -2)
	bar:SetPoint("BOTTOMRIGHT", sframetop, -4, -2)
	bar:SetHeight(8)

	barmiddle = bar:CreateTexture(nil, "BORDER")
	barmiddle:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	barmiddle:SetAllPoints(bar)
	barmiddle:SetTexCoord(0.29296875, 1, 0, 0.25)

	frame:SetScript("OnShow", function(self)
		PlaySound("igCharacterInfoTab")
		local w = (contentFrame:GetWidth() - 10) / #lists
		for i, list in next, lists do
			list.button:SetWidth(w)
		end
		addon:SelectPanel()
	end)
	frame:SetScript("OnHide", function()
		PlaySound("igMainMenuClose")
		for i, tab in next, panels do
			if type(tab.hide) == "function" then
				tab.hide()
			end
		end
	end)

	local function listButtonClick(self)
		PlaySound("igMainMenuOptionCheckBoxOn")
		addon:SelectList(self.listIndex)
	end
	for i, list in next, lists do
		local f = CreateFrame("Button", "oRA3ListButton"..i, listFrame, "UIPanelButtonTemplate")
		f:SetWidth(20)
		f:SetHeight(21)
		local selected = not db.lastSelectedList and i == 1 or db.lastSelectedList == i
		f:SetNormalFontObject(selected and GameFontHighlightSmall or GameFontNormalSmall)
		f:SetHighlightFontObject(GameFontHighlightSmall)
		f:SetDisabledFontObject(GameFontDisableSmall)
		f:SetText(list.name)
		f.listIndex = i
		f:SetScript("OnClick", listButtonClick)
		if i == 1 then
			f:SetPoint("TOPLEFT", sframe, "BOTTOMLEFT", 5, -6)
		else
			f:SetPoint("LEFT", lists[i - 1].button, "RIGHT")
		end
		list.button = f
	end
end

function addon:ToggleFrame(force)
	if setupGUI then
		setupGUI()
		setupGUI = nil
	end
	if force then
		RaidInfoFrame:Hide()
		ShowUIPanel(oRA3Frame, true)
	else
		ToggleFrame(oRA3Frame)
		if oRA3Frame:IsShown() then
			RaidInfoFrame:Hide()
		end
	end
end

function addon:OnPromoted(promoted)
	if oRA3DisbandButton then
		oRA3DisbandButton:SetEnabled(promoted > 1 and not IsInGroup(2))
	end
end

function addon:OnDemoted()
	if oRA3DisbandButton then
		oRA3DisbandButton:Disable()
	end
end

function addon:OnStartup()
	if oRA3CheckButton then
		oRA3CheckButton:SetEnabled(oRA3CheckButton.module.db.profile.output > 1 or oRA3CheckButton.module.db.profile.whisper)
	end
end

function addon:OnShutdown()
	if oRA3CheckButton then
		oRA3CheckButton:Disable()
	end
end

function addon:SetAllPointsToPanel(frame, aceguihacky)
	if contentFrame then
		frame:SetParent(contentFrame)
		frame:SetPoint("TOPLEFT", contentFrame, 8, aceguihacky and -10 or -4)
		frame:SetPoint("BOTTOMRIGHT", contentFrame, aceguihacky and -10 or -8, aceguihacky and 10 or 6)
	end
end

-----------------------------------------------------------------------
-- Window position saving
--

function addon:SavePosition(name, nosize)
	local f = _G[name]
	local x,y = f:GetLeft(), f:GetTop()
	local s = f:GetEffectiveScale()

	x,y = x*s,y*s

	local opt = db.positions[name]
	if not opt then
		db.positions[name] = {}
		opt = db.positions[name]
	end
	opt.PosX = x
	opt.PosY = y
	if not nosize then
		opt.Width = f:GetWidth()
		opt.Height = f:GetHeight()
	end
end

function addon:RestorePosition(name)
	local f = _G[name]
	local opt = db.positions[name]
	if not opt then
		db.positions[name] = {}
		opt = db.positions[name]
	end

	local x = opt.PosX
	local y = opt.PosY

	local s = f:GetEffectiveScale()

	if not x or not y then
		f:ClearAllPoints()
		f:SetPoint("CENTER", UIParent)
		return false
	end

	x,y = x/s,y/s

	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)

	-- restore height/width if stored
	if opt.Width then
		f:SetWidth(opt.Width)
	end

	if opt.Height then
		f:SetHeight(opt.Height)
	end
	return true
end

-----------------------------------------------------------------------
-- Panel handling
-- (panels are the tabs at the bottom)
--

function addon:RegisterPanel(name, show, hide)
	table.insert(panels, {
		name = name,
		show = show,
		hide = hide
	})
end

function addon:SelectPanel(name, noUpdate)
	self:ToggleFrame(true)
	if not name then
		name = db.lastSelectedPanel or panels[1].name
	end
	db.lastSelectedPanel = name

	local index = 1
	for i, tab in next, panels do
		if tab.name == name then
			index = i
		elseif type(tab.hide) == "function" then
			tab.hide()
		end
	end

	oRA3Frame.title:SetText(name)
	oRA3Frame.selectedTab = index

	PanelTemplates_UpdateTabs(oRA3Frame)

	panels[index].show()

	if not noUpdate then
		UpdateUIPanelPositions(oRA3Frame) -- snap the panel back
	end
end

-----------------------------------------------------------------------
-- List handling
-- (lists are the views in the Checks panel)
--

-- register a list view
-- name (string) - name of the list
-- contents (table) - contents of the list
-- .. tuple - name, width -- contains name of the sortable column and type of the column
function addon:RegisterList(name, contents, ...)
	local newList = {
		name = name,
		contents = contents,
	}
	if select("#", ...) > 0 then
		local cols = {}
		for i = 1, select("#", ...) do
			local cname = select(i, ...)
			if cname then
				cols[#cols + 1] = { name = cname }
			end
		end
		newList.cols = cols
	end
	table.insert(lists, newList)
end

function addon:UpdateList(name)
	if not openedList or not oRA3Frame:IsVisible() then return end
	if lists[openedList].name ~= name then return end
	showLists(true)
end

function addon:SelectList(index)
	openedList = index
	for i, list in next, lists do
		if i == index then
			list.button:SetNormalFontObject(GameFontHighlightSmall)
		else
			list.button:SetNormalFontObject(GameFontNormalSmall)
		end
	end
	showLists()
end

function addon:OpenToList(name)
	self:SelectPanel(L.checks)
	for i, list in next, lists do
		if list.name == name then
			self:SelectList(i)
			break
		end
	end
end

function addon:UpdateScroll( forceSecure )
	local list = lists[openedList]
	local nr = #list.contents
	FauxScrollFrame_Update(contentFrame.scrollFrame, nr, 19, 16, nil, nil, nil, nil, nil, nil, true)
	local highs
	if InCombatLockdown() or forceSecure then
		highs = scrollhighs
	else
		highs = secureScrollhighs
	end
	for i = 1, 19 do
		local j = i + FauxScrollFrame_GetOffset(contentFrame.scrollFrame)
		if j <= nr then
			local unitName = nil
			for k, v in next, scrollheaders do
				if k == 1 then
					unitName = list.contents[j][k]
					v.entries[i]:SetText(coloredNames[unitName])
				else
					v.entries[i]:SetText(list.contents[j][k])
				end
				v.entries[i]:Show()
			end
			if unitName and highs[i].isSecure then
				highs[i]:SetAttribute("type", "macro")
				highs[i]:SetAttribute("macrotext", "/target "..unitName)
			end
			highs[i]:Show()
		else
			for k, v in next, scrollheaders do
				v.entries[i]:Hide()
			end
			highs[i]:Hide()
		end
	end
end

-- Can't be local because it's also used by the Tank module at the moment
function addon:CreateScrollEntry(header)
	local f = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f:SetHeight(16)
	f:SetJustifyH("LEFT")
	f:SetTextColor(1, 1, 1, 1)
	return f
end

local sortIndex -- current index (scrollheader) being sorted
local function sortAsc(a, b) return b[sortIndex] > a[sortIndex] end
local function sortDesc(a, b) return a[sortIndex] > b[sortIndex] end
local function toggleColumn(header)
	local list = lists[openedList]
	local nr = header.headerIndex
	scrollheaders[nr].sortDir = not scrollheaders[nr].sortDir
	sortIndex = nr
	if scrollheaders[nr].sortDir then
		table.sort(list.contents, sortAsc)
	else
		table.sort(list.contents, sortDesc)
	end
	PlaySound("igMainMenuOptionCheckBoxOn")
	addon:UpdateScroll()
end

local function createHighlights( secure )
	local f = scrollheaders[1]
	if not f then return end
	local combat = InCombatLockdown()
	if combat and secure then return end

	local extra = secure and "Secure" or "InSecure"
	local list
	if secure then
		list = secureScrollhighs
	else
		list = scrollhighs
	end
	for i = 1, 19 do
		list[i] = CreateFrame("Button", "oRA3ScrollHigh"..extra..i, contentFrame.listFrame, secure and "SecureActionButtonTemplate" or nil)
		if i == 1 then
			list[i]:SetPoint("TOPLEFT", contentFrame.listFrame, "TOPLEFT", 8, -24)
		else
			list[i]:SetPoint("TOPLEFT", list[i-1], "BOTTOMLEFT")
		end
		list[i]:SetWidth(contentFrame.scrollFrame:GetWidth())
		list[i]:SetHeight(16)
		list[i]:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
		list[i].isSecure = secure
		list[i]:Hide()
	end
end

local function createScrollHeader()
	if not contentFrame then return end
	local nr = #scrollheaders + 1
	local f = CreateFrame("Button", "oRA3ScrollHeader"..nr, contentFrame, "WhoFrameColumnHeaderTemplate")
	f.headerIndex = nr
	f:SetScript("OnClick", toggleColumn)

	local text = f:CreateFontString(nil, nil, "GameFontHighlightSmall")
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	text:SetAllPoints(f)
	f:SetFontString(text)

	scrollheaders[#scrollheaders + 1] = f

	if #scrollheaders == 1 then
		f:SetPoint("TOPLEFT", contentFrame, 1, -2)
	else
		f:SetPoint("LEFT", scrollheaders[#scrollheaders - 1], "RIGHT")
	end

	if #scrollheaders == 1 then
		createHighlights()
		createHighlights(true) -- secure highlights
	end

	local entries = {}
	for i = 1, 19 do
		local text = addon:CreateScrollEntry(f)
		if i == 1 then
			text:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 8, 0)
			text:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -4, 0)
		else
			text:SetPoint("TOPLEFT", entries[i - 1], "BOTTOMLEFT")
			text:SetPoint("TOPRIGHT", entries[i - 1], "BOTTOMRIGHT")
		end
		entries[i] = text
	end
	f.entries = entries
end

local function setScrollHeaderWidth(nr, width)
	scrollheaders[nr]:SetWidth(width)
	_G[scrollheaders[nr]:GetName().."Middle"]:SetWidth(width - 9)
end

local listHeader = ("%s - %%s"):format(L.checks)
function showLists(listUpdated)
	-- hide all scrollheaders per default
	for k, f in next, scrollheaders do
		f:Hide()
	end

	if not openedList then openedList = db.lastSelectedList and lists[db.lastSelectedList] and db.lastSelectedList or 1 end
	db.lastSelectedList = openedList

	local list = lists[openedList]
	if not listUpdated then -- Don't spam this callback when updating the list we're looking at
		addon.callbacks:Fire("OnListSelected", list.name)
	end
	oRA3Frame.title:SetText(listHeader:format(list.name))

	contentFrame.listFrame:Show()
	local count = max(#list.cols + 1, 4) -- +1, we make the name twice as wide, minimum 4, we make 2 columns twice as wide
	local totalwidth = contentFrame.scrollFrame:GetWidth()
	local width = totalwidth / count
	while #list.cols > #scrollheaders do
		createScrollHeader()
	end
	for k, v in next, list.cols do
		scrollheaders[k]:SetText(v.name)
		if k == 1 or #list.cols == 2 then
			setScrollHeaderWidth(k, width * 2)
		else
			setScrollHeaderWidth(k, width)
		end
		scrollheaders[k]:Show()
	end
	addon:UpdateScroll()
end

function hideLists()
	for k, f in next, scrollheaders do
		f:Hide()
	end
	contentFrame.listFrame:Hide()

	if openedList then
		addon.callbacks:Fire("OnListClosed", lists[openedList].name)
	end
	openedList = nil
end

function addon:PLAYER_REGEN_ENABLED()
	if #scrollhighs > 0 then
		if #secureScrollhighs == 0 then
			createHighlights( true )
		end
		for i = 1, 19 do
			scrollhighs[i]:Hide()
			-- reattach to the listframe
			secureScrollhighs[i]:SetParent(contentFrame.listFrame)
			if i == 1 then
				secureScrollhighs[i]:SetPoint("TOPLEFT", contentFrame.listFrame, "TOPLEFT", 8, -24)
			else
				secureScrollhighs[i]:SetPoint("TOPLEFT", secureScrollhighs[i-1], "BOTTOMLEFT")
			end
		end
		if contentFrame.listFrame:IsShown() then self:UpdateScroll() end
	end
end

function addon:PLAYER_REGEN_DISABLED()
	if #scrollhighs > 0 then
		for i = 1, 19 do
			secureScrollhighs[i]:SetParent(UIParent)
			secureScrollhighs[i]:ClearAllPoints() -- detach from the listFrame to prevent taint
			secureScrollhighs[i]:Hide()
		end
		if contentFrame.listFrame:IsShown() then self:UpdateScroll( true ) end -- if the frame is shown force a secure update
	end
end

oRA3 = addon -- Set global

