
local addon = LibStub("AceAddon-3.0"):NewAddon("oRA3", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceConsole-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")
_G.oRA3 = addon -- Debug

local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

local hexColors = {}
for k, v in pairs(RAID_CLASS_COLORS) do
	hexColors[k] = "|cff" .. string.format("%02x%02x%02x", v.r * 255, v.g * 255, v.b * 255)
end
local _testUnits = {
	Wally = "WARRIOR",
	Kingkong = "DEATHKNIGHT",
	Apenuts = "PALADIN",
	Foobar = "DRUID",
	Eric = "WARLOCK",
}
addon._testUnits = _testUnits
local coloredNames = setmetatable({}, {__index =
	function(self, key)
		if type(key) == "nil" then return nil end
		local class = _testUnits[key] or select(2, UnitClass(key))
		if class then
			self[key] = hexColors[class]  .. key .. "|r"
		else
			self[key] = "|cffcccccc<"..key..">|r"
		end
		return self[key]
	end
})
addon.coloredNames = coloredNames

addon.util = {}
local util = addon.util

-- Locals
local playerName = UnitName("player")
local guildMemberList = {} -- Name:RankIndex
local guildRanks = {} -- Index:RankName
local groupMembers = {} -- Index:Name
local playerPromoted = nil

-- couple of local constants used for party size
local UNGROUPED = 0
local INPARTY = 1
local INRAID = 2
addon.UNGROUPED = UNGROUPED
addon.INPARTY = INPARTY
addon.INRAID = INRAID
addon.groupStatus = UNGROUPED -- flag indicating groupsize
local groupStatus = addon.groupStatus -- local upvalue

-- overview drek
local openedPanel = nil -- name of the current opened Panel
local openedList = nil -- name of the current opened List in the List panel
local contentFrame = nil -- content frame for the views
local lastTab = 0 -- last tab in the list
local scrollheaders = {} -- scrollheader frames
local listbuttons = {} -- check list buttons
local sortIndex -- current index (scrollheader) being sorted
local selectedTab = 1
local scrollhighs = {} -- scroll highlights


addon.lists = {}
addon.panels = {}

local db
local defaults = {
	profile = {
		positions = {},
		open = false,
	}
}

local selectList -- implemented down the file
local showLists -- implemented down the file
local hideLists -- implemented down the file



function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("oRA3DB", defaults, "Default")
	db = self.db.profile
	
	-- callbackhandler for comm
	self.callbacks = CallbackHandler:New(self)
	
	self:RegisterPanel(L["Checks"], showLists, hideLists)

end

function addon:OnEnable()
	self:ShowGUI()
	-- Comm register
	self:RegisterComm("oRA3")
	
	-- Roster Status Events
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	
	-- init groupStatus
	self:RAID_ROSTER_UPDATE()
	if IsInGuild() then GuildRoster() end
end

function addon:OnDisable()
	self:HideGUI()
end

function addon:OnStartup()
end

function addon:OnShutdown()
end

function addon:OnPromoted()
	if oRA3Disband then
		oRA3Disband:Enable()
	end
end

function addon:OnDemoted()
	if oRA3Disband then
		oRA3Disband:Disable()
	end
end

do
	local unitJoinedRaid = '^' .. ERR_RAID_MEMBER_ADDED_S:gsub("%%s", "(%%S+)") .. '$'
	function addon:CHAT_MSG_SYSTEM(event, msg)
		if not UnitInRaid("player") then return end
		local name = select(3, msg:find(unitJoinedRaid))
		if not name then return end
		if rawget(coloredNames, name) then
			coloredNames[name] = nil
		end
	end
end

do
	local function isIndexedEqual(a, b)
		if #a ~= #b then return false end
		for i, v in ipairs(a) do
			if v ~= b[i] then return false end
		end
		return true
	end
	local function isKeyedEqual(a, b)
		local aC, bC = 0, 0
		for k in pairs(a) do aC = aC + 1 end
		for k in pairs(b) do bC = bC + 1 end
		if aC ~= bC then return false end
		for k, v in pairs(a) do
			if not b[k] or v ~= b[k] then return false end
		end
		return true
	end
	local function copyToTable(src, dst)
		wipe(dst)
		for i, v in pairs(src) do dst[i] = v end
	end

	local tmpRanks = {}
	local tmpMembers = {}
	function addon:GUILD_ROSTER_UPDATE()
		wipe(tmpRanks)
		wipe(tmpMembers)
		for i = 1, GuildControlGetNumRanks() do
			table.insert(tmpRanks, GuildControlGetRankName(i))
		end
		local numGuildMembers = GetNumGuildMembers()
		for i = 1, numGuildMembers do
			local name, _, rankIndex = GetGuildRosterInfo(i)
			if name then tmpMembers[name] = rankIndex + 1 end
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
	
	local tmpGroup = {}
	function addon:RAID_ROSTER_UPDATE()
		local oldStatus = groupStatus
		if GetNumRaidMembers() > 0 then
			groupStatus = INRAID
		elseif GetNumPartyMembers() > 0 then
			groupStatus = INPARTY
		else
			groupStatus = UNGROUPED
		end

		addon.groupStatus = groupStatus

		wipe(tmpGroup)
		if groupStatus == INRAID then
			for i = 1, GetNumRaidMembers() do
				local n = GetRaidRosterInfo(i)
				if n then table.insert(tmpGroup, n) end
			end
		elseif groupStatus == INPARTY then
			table.insert(tmpGroup, playerName)
			for i = 1, 4 do
				local n = UnitName("party" .. i)
				if n then table.insert(tmpGroup, n) end
			end
		end
		if oldStatus ~= groupStatus or not isIndexedEqual(tmpGroup, groupMembers) then
			copyToTable(tmpGroup, groupMembers)
			self.callbacks:Fire("OnGroupChanged", groupStatus, groupMembers)
		end
		if groupStatus == UNGROUPED and oldStatus > groupStatus then
			self:OnShutdown()
			self.callbacks:Fire("OnShutdown", groupStatus)
		elseif oldStatus == UNGROUPED and groupStatus > oldStatus then
			self:OnStartup()
			self.callbacks:Fire("OnStartup", groupStatus)
		end
		if playerPromoted ~= self:IsPromoted() then
			playerPromoted = self:IsPromoted()
			if playerPromoted then
				self:OnPromoted()
				self.callbacks:Fire("OnPromoted", playerPromoted)
			else
				self:OnDemoted()
				self.callbacks:Fire("OnDemoted", playerPromoted)
			end
		end
		self:AdjustPanelInset()
	end
end

function addon:InRaid()
	return groupStatus == INRAID
end

function addon:InParty()
	return groupStatus == INPARTY
end

function addon:DisbandGroup()
	if not self:IsPromoted() then return end
	local pName = UnitName("player")
	SendChatMessage(L["<oRA3> Disbanding group."], self:InRaid() and "RAID" or "PARTY")
	if self:InRaid() then
		for i = 1, GetNumRaidMembers() do
			local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
			if online and name ~= pName then
				UninviteUnit(name)
			end
		end
	else
		for i = MAX_PARTY_MEMBERS, 1, -1 do
			if GetPartyMember(i) then
				UninviteUnit(UnitName("party"..i))
			end
		end
	end
	LeaveParty()
end

function addon:ShowOptions()
	self:Print("Implement ME!")
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

-- Comm handling

function addon:SendComm( ... )
	if groupStatus == UNGROUPED then return end
	self:SendCommMessage("oRA3", self:Serialize(...), "RAID") -- we always send to raid, blizzard will default to party if you're in a party
end

function addon:OnCommReceived(prefix, message, distribution, sender)
	if distribution ~= "RAID" and distribution ~= "PARTY" then return end
	addon:DispatchComm(sender, self:Deserialize(message))
end

function addon:DispatchComm(sender, ok, commType, ...)
	if ok and type(commType) == "string" then
		self.callbacks:Fire("OnComm"..commType, sender, ...)
	end
end

-- GUI

function addon:ShowGUI()
	self:SetupGUI()
	oRA3Frame:Show()
	self:UpdateGUI(openedPanel)
end

function addon:HideGUI()
	-- hide gui here
	oRA3Frame:Hide()
end


-- The Sliding/Detaching GUI pane is courtsey of Cladhaire and originally from LightHeaded
-- This code was used with permission.

function addon:SetupGUI()
	if oRA3Frame then return end

	local frame = CreateFrame("Frame", "oRA3Frame", RaidFrame)

	frame:SetWidth(640)
	frame:SetHeight(512)
	frame:SetPoint("LEFT", RaidFrame, "RIGHT", 0, 19)
	
	local topleft = frame:CreateTexture(nil, "ARTWORK")
	topleft:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopLeft")
	topleft:SetWidth(128)
	topleft:SetHeight(256)
	topleft:SetPoint("TOPLEFT", 0, 0)

	local topright = frame:CreateTexture(nil, "ARTWORK")
	topright:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopRight")
	topright:SetWidth(140)
	topright:SetHeight(256)
	topright:SetPoint("TOPRIGHT", 0, 0)
	topright:SetTexCoord(0, (140 / 256), 0, 1)

	local top = frame:CreateTexture(nil, "ARTWORK")
	top:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-Top")
	top:SetHeight(256)
	top:SetPoint("TOPLEFT", topleft, "TOPRIGHT", 0, 0)
	top:SetPoint("TOPRIGHT", topright, "TOPLEFT", 0, 0)

	local botleft = frame:CreateTexture(nil, "ARTWORK")
	botleft:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-BotLeft")
	botleft:SetWidth(128)
	botleft:SetHeight(168)
	botleft:SetPoint("BOTTOMLEFT", 0, 0)
	botleft:SetTexCoord(0, 1, 0, (168 / 256))

	local botright = frame:CreateTexture(nil, "ARTWORK")
	botright:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-BotRIght")
	botright:SetWidth(140)
	botright:SetHeight(168)
	botright:SetPoint("BOTTOMRIGHT", 0, 0)
	botright:SetTexCoord(0, (140 / 256), 0, (168 / 256))

	local bot = frame:CreateTexture(nil, "ARTWORK")
	bot:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-Bot")
	bot:SetHeight(168)
	bot:SetPoint("TOPLEFT", botleft, "TOPRIGHT", 0, 0)
	bot:SetPoint("TOPRIGHT", botright, "TOPLEFT", 0, 0)
	bot:SetTexCoord(0, 1, 0, (168 / 256))

	local midleft = frame:CreateTexture(nil, "ARTWORK")
	midleft:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopLeft")
	midleft:SetWidth(128)
	midleft:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT", 0, 0)
	midleft:SetPoint("BOTTOMLEFT", botleft, "TOPLEFT", 0, 0)
	midleft:SetTexCoord(0, 1, (240 / 256), 1)

	local midright = frame:CreateTexture(nil, "ARTWORK")
	midright:SetTexture("Interface\\AddOns\\oRA3\\images\\MidRight")
	midright:SetWidth(140)
	midright:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT", 0, 0)
	midright:SetPoint("BOTTOMRIGHT", botright, "TOPRIGHT", 0, 0)
	midright:SetTexCoord(0, (140 / 256), 0, 1)

	local mid = frame:CreateTexture(nil, "ARTWORK")
	mid:SetTexture("Interface\\AddOns\\oRA3\\images\\Mid")
	mid:SetPoint("TOPLEFT", midleft, "TOPRIGHT", 0, 0)
	mid:SetPoint("BOTTOMRIGHT", midright, "BOTTOMLEFT", 0, 0)
	
	local bg1 = frame:CreateTexture(nil, "BACKGROUND")
	bg1:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
	bg1:SetHeight(64)
	bg1:SetPoint("TOPLEFT", topleft, "TOPLEFT", 5, -4)
	bg1:SetWidth(256)

	local bg2 = frame:CreateTexture(nil, "BACKGROUND")
	bg2:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
	bg2:SetHeight(64)
	bg2:SetPoint("TOPLEFT", bg1, "TOPRIGHT", 0, 0)
	bg2:SetWidth(256)

	local bg3 = frame:CreateTexture(nil, "BACKGROUND")
	bg3:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
	bg3:SetHeight(64)
	bg3:SetPoint("TOPLEFT", bg2, "TOPRIGHT", 0, 0)
	bg3:SetWidth(256)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 5, 4)
	--self:SetFrameTooltip(close, "Click to close the oRA3 GUI")

	local resize = CreateFrame("Button", nil, frame)
	resize:SetNormalTexture("Interface\\AddOns\\oRA3\\images\\Resize")
	resize:GetNormalTexture():SetTexCoord((12 / 32), 1, (12 / 32), 1)
	resize:SetHighlightTexture("Interface\\AddOns\\oRA3\\images\\Resize")
	resize:GetHighlightTexture():SetTexCoord((12 / 32), 1, (12 / 32), 1)
	resize:SetHeight(12)
	resize:SetWidth(12)
	resize:SetPoint("BOTTOMRIGHT", -3, 3)
	--self:SetFrameTooltip(resize, "Click to resize")

	local titlereg = CreateFrame("Button", nil, frame)
	titlereg:SetPoint("TOPLEFT", 5, -5)
	titlereg:SetPoint("TOPRIGHT", 0, 0)
	titlereg:SetHeight(20)
	titlereg:SetScript("OnMouseDown", function(f)
		local parent = f:GetParent()
		if parent:IsMovable() then
			parent:StartMoving()
		end
	end)
	titlereg:SetScript("OnMouseUp", function(f)
		local parent = f:GetParent()
		parent:StopMovingOrSizing()
		-- self:SavePosition("oRA3Frame")
	end)
									
	local title = frame:CreateFontString(nil, "ARTWORK")
	title:SetFontObject(GameFontNormal)
	title:SetPoint("TOP", 0, -6)
	title:SetText("oRA3")

	
	
	frame:EnableMouse()
	frame:SetMovable(1)
	frame:SetResizable(1)
	frame:SetMinResize(300, 300)
	frame:SetWidth(400)
	frame:SetFrameLevel(0)
	frame:SetWidth(325)
	frame:SetHeight(450)

	frame.bg1 = bg1
	frame.bg2 = bg2
	frame.bg3 = bg3
	frame.top = top
	frame.bot = bot
	frame.topleft = topleft
	frame.topright = topright
	frame.botleft = botleft
	frame.botright = botright
	frame.close = close
	frame.resize = resize
	frame.mid = mid
	frame.midleft = midleft
	frame.midright = midright
	frame.titlereg = titlereg
	frame.title = title
	
	local cos = math.cos
	local pi = math.pi

	-- internal functions
	local function cosineInterpolation(y1, y2, mu)
		return y1+(y2-y1)*(1 - cos(pi*mu))/2
	end

	local min,max = -360, -50
	local steps = 45
	local timeToFade = 1.5
	local mod = 1/timeToFade
	local modifier = 1/steps
	
	local count = 0
	local totalElapsed = 0
	local function onupdate(self, elapsed)   
		count = count + 1
		totalElapsed = totalElapsed + elapsed
		
		if totalElapsed >= timeToFade then
			local temp = max
			max = min
			min = temp
			count = 0
			totalElapsed = 0
			self:SetScript("OnUpdate", nil)
			
			-- Do the frame fading
			if not db.open then
				if oRA3FrameSub.justclosed == true then
					oRA3FrameSub.justclosed = false
					oRA3FrameSub:Hide()
				else
					UIFrameFadeIn(oRA3FrameSub, 0.25, 0, 1)
					oRA3FrameSub:Show()
					db.open = true
					-- FIXME
					-- Select last tab
					-- oRA3:SelectQuestLogEntry()
				end
			end
			return
		elseif count == 1 and db.open then
			UIFrameFadeOut(oRA3FrameSub, 0.25, 1, 0)
			db.open = false
			oRA3FrameSub.justclosed = true
		end
		
		local offset = cosineInterpolation(min, max, mod * totalElapsed)
		self:SetPoint("LEFT", RaidFrame, "RIGHT", offset, 31)
	end	
	
	-- Flip min and max, if we're supposed to be open
	if db.open then
		min,max = max,min
	end

	if not frame.handle then
		frame.handle = CreateFrame("Button", nil, frame)
	end

	frame.handle:SetWidth(8)
	frame.handle:SetHeight(128)
	frame.handle:SetPoint("LEFT", frame, "RIGHT", 0, 0)
	frame.handle:SetNormalTexture("Interface\\AddOns\\oRA3\\images\\tabhandle")

	frame.handle:RegisterForClicks("AnyUp")
	frame.handle:SetScript("OnClick", function(self, button)
		frame:SetScript("OnUpdate", onupdate)
		if db.sound then
			PlaySoundFile("Sound\\Doodad\\Karazahn_WoodenDoors_Close_A.wav")
		end
		db.oraopen = not db.oraopen --unused for now
	end)

	frame.handle:SetScript("OnEnter", function(self)
		SetCursor("INTERACT_CURSOR")
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText("Click to open/close oRA3")
		GameTooltip:Show()
	end)

	frame.handle:SetScript("OnLeave",function(self)
		SetCursor(nil)
		GameTooltip:Hide()
	end)

	frame.close:SetScript("OnClick", function() 
		if RaidFrame:IsVisible() then
			HideUIPanel(FriendsFrame)
		else
			frame.handle:Click() 
		end
	end)

	local subframe = CreateFrame("Frame", "oRA3FrameSub", oRA3Frame)
	--subframe:SetPoint("TOPLEFT", 40, -56)
	subframe:SetPoint("TOPLEFT", 14, -56)
	subframe:SetPoint("BOTTOMRIGHT", -1, 3)
	subframe:SetAlpha(0)

	contentFrame = subframe
	local backdrop = {
		-- bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
		bgFile = [[Interface\AddOns\oRA3\images\tiled-noise-2]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		tile = true, edgeSize = 16, tileSize = 64,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	}
	contentFrame:SetBackdrop(backdrop)
	contentFrame:SetBackdropColor(0.08, 0.08, 0.08)
	contentFrame:SetBackdropBorderColor(.8, .8, .8)

	local disband = CreateFrame("Button", "oRA3Disband", contentFrame, "UIPanelButtonTemplate")
	disband:SetWidth(115)
	disband:SetHeight(21)
	disband:SetNormalFontObject(GameFontNormalSmall)
	disband:SetHighlightFontObject(GameFontHighlightSmall)
	disband:SetDisabledFontObject(GameFontDisableSmall)
	disband:SetText(L["Disband Group"])
	disband:SetPoint("BOTTOMLEFT", contentFrame, "TOPLEFT", 4, 11)
	disband:SetScript("OnClick", function() self:DisbandGroup() end)
	disband:Disable() -- will get enabled on startup

	local options = CreateFrame("Button", "oRA3Options", contentFrame, "UIPanelButtonTemplate")
	options:SetWidth(115)
	options:SetHeight(21)
	options:SetNormalFontObject(GameFontNormalSmall)
	options:SetHighlightFontObject(GameFontHighlightSmall)
	options:SetDisabledFontObject(GameFontDisableSmall)
	options:SetText(L["Options"])
	options:SetPoint("BOTTOMRIGHT", contentFrame, "TOPRIGHT", -6, 11)
	options:SetScript( "OnClick", function()  self:ShowOptions() end )
	
	
	oRA3Frame.oRAtabs = {} -- setup the tab listing
	self:SetupPanels() -- fill the tab listing

	local listFrame = CreateFrame("ScrollFrame", "oRA3ListFrame", contentFrame)
	listFrame:SetAllPoints(contentFrame)
	
	-- Scrolling body
	local sframe = CreateFrame("ScrollFrame", "oRA3ScrollFrame", listFrame, "FauxScrollFrameTemplate")
	sframe:SetPoint("BOTTOMLEFT", listFrame, "BOTTOMLEFT", 0, 30)
	sframe:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", -26, -25)
	contentFrame.scrollFrame = sframe
	contentFrame.listFrame = listFrame
	local function updateScroll()
		self:UpdateScrollContents()
	end
	
	sframe:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 16, updateScroll)
	end)

	local sframebottom = CreateFrame("Frame", "oRA3ScrollFrameBottom", listFrame)
	sframebottom:SetPoint("TOPLEFT", sframe, "BOTTOMLEFT", 0, 0)
	sframebottom:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 0)
	sframebottom:SetFrameLevel(contentFrame:GetFrameLevel())
	sframebottom:SetBackdrop(backdrop)
	sframebottom:SetBackdropBorderColor(.8, .8, .8)
	sframebottom:SetBackdropColor(0,0,0,0)
	
	local sframetop = CreateFrame("Frame", "oRA3ScrollFrameTop", listFrame)
	sframetop:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
	sframetop:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, 0)
	sframetop:SetHeight(27)
	sframetop:SetBackdrop(backdrop)
	sframetop:SetBackdropBorderColor(.8, .8, .8)
	sframetop:SetBackdropColor(0,0,0,0)

	sframe:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 16, function() addon:UpdateScroll() end )
	end)

	local function resizebg(frame)
		local width = frame:GetWidth() - 5
		-- bg1 will be okay due to minresize

		-- We'll resize bg2 up to 256
		local bg2w = width - 256
		local bg3w
		if bg2w > 256 then
			bg3w = bg2w - 256
			bg2w = 256
		end

		if bg2w > 0 then
			frame.bg2:SetWidth(bg2w)
			frame.bg2:SetTexCoord(0, (bg2w / 256), 0, 1)
			frame.bg2:Show()
		else
			frame.bg2:Hide()
		end

		
		if bg3w and bg3w > 0 then
			frame.bg3:SetWidth(bg3w)
			frame.bg3:SetTexCoord(0, (bg3w / 256), 0, 1)
			frame.bg3:Show()
		else
			frame.bg3:Hide()
		end
	end

	oRA3Frame:SetScript("OnShow", function() addon:UpdateGUI() end )
	
	oRA3Frame.resizebg = resizebg

	resize:SetScript("OnMouseDown", function(frame)
		oRA3Frame:StartSizing()
		oRA3Frame:SetScript("OnUpdate", resizebg)
	end)
	resize:SetScript("OnMouseUp", function(frame)
		oRA3Frame:StopMovingOrSizing()
		oRA3Frame:SetScript("OnUpdate", nil)
		-- FIXME
		-- self:SavePosition("oRA3Frame")
		-- subframe.text:UpdateSize()
		-- subframe.scroll:UpdateScrollChildRect()
		oRA3Frame.resizebg(oRA3Frame)
	end)
	resizebg(frame)
	
	self:UpdateFrameStatus()
	
	self:SelectPanel()
end


function addon:AdjustPanelInset()
	if oRA3Frame then
		if self:InRaid() then
			contentFrame:SetPoint("TOPLEFT", 40, -56)
		else
			contentFrame:SetPoint("TOPLEFT", 14, -56)
		end
		if openedOverview  == L["Checks"] then
			showLists()
		end
	end
end

function addon:SetAllPointsToPanel(frame)
	if contentFrame then
		frame:SetParent(contentFrame)
		frame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 8, -4)
		frame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -4, 6)
	end
end


function addon:UpdateFrameStatus()
	local subframe = oRA3FrameSub

	oRA3Frame:ClearAllPoints()

	-- Lock the frame
	oRA3Frame.titlereg:Hide()
	oRA3Frame.resize:Hide()
	oRA3Frame.handle:Show()
	oRA3Frame:SetWidth(375)
	oRA3Frame:SetHeight(425) 
	oRA3Frame.resizebg(oRA3Frame)
	oRA3Frame:SetFrameStrata("MEDIUM")
	oRA3Frame.close:Show()
	oRA3Frame:SetParent(RaidFrame)

	if db.open then
		oRA3Frame:SetPoint("LEFT", RaidFrame, "RIGHT", -50, 31)
		subframe:Show()
		subframe:SetAlpha(1)
		subframe.open = true
	else
		oRA3Frame:SetPoint("LEFT", RaidFrame, "RIGHT", -360, 31)
		subframe:Hide()
		subframe:SetAlpha(0)
	end
end

function addon:SavePosition(name, nosize)
    local f = getglobal(name)
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
	local f = getglobal(name)
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
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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

	if type(f.resizebg) == "function" then
		-- Resize the background
		f.resizebg(f)
	end
	return true
end


local function sortAsc(a, b) return b[sortIndex] > a[sortIndex] end
local function sortDesc(a, b) return a[sortIndex] > b[sortIndex] end

function addon:SortColumn(nr)
	local list = self.lists[openedList]
	scrollheaders[nr].sortDir = not scrollheaders[nr].sortDir
	sortIndex = nr
	if scrollheaders[nr].sortDir then
		table.sort(list.contents, sortAsc)
	else
		table.sort(list.contents, sortDesc)
	end
	self:UpdateScroll()
end

function addon:UpdateScroll()
	local list = self.lists[openedList]
	local nr = #list.contents
	FauxScrollFrame_Update(contentFrame.scrollFrame, nr, 19, 16)
	for i = 1, 19 do
		local j = i + FauxScrollFrame_GetOffset(contentFrame.scrollFrame)
		if j <= nr then
			for k, v in ipairs(scrollheaders) do
				if k == 1 then
					v.entries[i]:SetText(coloredNames[list.contents[j][k]])
				else
					v.entries[i]:SetText(list.contents[j][k])
				end
				v.entries[i]:Show()
			end
			scrollhighs[i]:Show()
		else
			for k, v in ipairs(scrollheaders) do
				v.entries[i]:Hide()
			end
			scrollhighs[i]:Hide()
		end
	end
end

function addon:SetScrollHeaderWidth( nr, width )
	if not scrollheaders[nr] then return end
	scrollheaders[nr]:SetWidth(width)
	getglobal(scrollheaders[nr]:GetName().."Middle"):SetWidth(width-9)
end

function addon:CreateScrollHeader()
	if not contentFrame then return end
	local nr = #scrollheaders + 1
	local f = CreateFrame("Button", "oRA3ScrollHeader"..nr, contentFrame, "WhoFrameColumnHeaderTemplate")
	f:SetScript("OnClick", function() self:SortColumn(nr) end)
	table.insert( scrollheaders, f)
	
	if #scrollheaders == 1 then
		f:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 1, -2)
	else
		f:SetPoint("LEFT", scrollheaders[#scrollheaders - 1], "RIGHT")
	end
	
	local entries = {}
	-- create childs
	local text = self:CreateScrollEntry(f)
	text:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 8, 0 )
	text:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -4, 0)
	entries[1] = text
	
	if #scrollheaders == 1 then
		scrollhighs[1] = CreateFrame("Button", "oRA3ScrollHigh1", contentFrame.listFrame)
		scrollhighs[1]:SetPoint("TOPLEFT", entries[1], "TOPLEFT", 0, 0)
		scrollhighs[1]:SetWidth(contentFrame.scrollFrame:GetWidth())
		scrollhighs[1]:SetHeight(16)
		scrollhighs[1]:SetHighlightTexture( [[Interface\FriendsFrame\UI-FriendsFrame-HighlightBar]] )
	end

	for i = 2, 19 do
		text = self:CreateScrollEntry(f)
		text:SetPoint("TOPLEFT", entries[i-1], "BOTTOMLEFT")
		text:SetPoint("TOPRIGHT", entries[i-1], "BOTTOMRIGHT")
		entries[i] = text
		if #scrollheaders == 1 then
			scrollhighs[i] = CreateFrame("Button", "oRA3ScrollHigh"..i, contentFrame.listFrame)
			scrollhighs[i]:SetPoint("TOPLEFT", entries[i], "TOPLEFT", 0, 0)
			scrollhighs[i]:SetWidth(contentFrame.scrollFrame:GetWidth())
			scrollhighs[i]:SetHeight(16)
			scrollhighs[i]:SetHighlightTexture( [[Interface\FriendsFrame\UI-FriendsFrame-HighlightBar]] )
		end
	end
	f.entries = entries
end

function addon:CreateScrollEntry( header )
	f = header:CreateFontString(nil,"OVERLAY")
	f:SetHeight(16)
	f:SetFontObject(GameFontNormalSmall)
	f:SetJustifyH("LEFT")
	f:SetTextColor(1, 1, 1, 1)
	f:ClearAllPoints()

	return f
end


function addon:CreateListButton(name)
	if not contentFrame then return end
	local nr = #listbuttons + 1
	local f = CreateFrame("Button", "oRA3ListButton"..nr, contentFrame.listFrame, "UIPanelButtonTemplate")
	f:SetWidth(90)
	f:SetHeight(21)
	f:SetNormalFontObject(GameFontNormalSmall)
	f:SetHighlightFontObject(GameFontHighlightSmall)
	f:SetDisabledFontObject(GameFontDisableSmall)
	f:SetText(name)
	f:SetScript("OnClick", function() self:SelectList(name) end)
	table.insert( listbuttons, f)
	
	if #listbuttons == 1 then
		f:SetPoint("TOPLEFT", contentFrame.scrollFrame, "BOTTOMLEFT", 4, -4)
	else
		f:SetPoint("LEFT", listbuttons[#listbuttons - 1], "RIGHT")
	end
	return f
end

function addon:UpdateGUI( name )
	self:SetupGUI()
	if not openedPanel then
		openedPanel = self.panels[1].name
	end
	if not oRA3Frame:IsVisible() or (name and openedOverview ~= name) then return end
	-- update the overviews
	self:SelectPanel(openedPanel)
end


-- Panels

-- register a panel
function addon:RegisterPanel(name, show, hide)
	self.panels[name] = {
		name = name,
		show = show,
		hide = hide
	}
	table.insert(self.panels, self.panels[name]) -- used to ipairs loop
	self:SetupPanel(name)
end

function addon:UnregisterPanel(name)
	if oRA3Frame and oRA3Frame.oRAtabs[name] then
		oRA3Frame.oRAtabs[name]:Hide()
		if openedPanel == name then
			openedPanel = nil
			self:UpdateGUI()
		end
	end
end

function addon:SetupPanels()
	for k, v in ipairs(self.panels) do
		self:SetupPanel(v.name)
	end
end

local function selectPanel(self)
	addon:SelectPanel(self.tabName)
end


-- register a list view
-- name (string) - name of the list
-- contents (table) - contents of the list
-- .. tuple - name, width  -- contains name of the sortable column and type of the column
function addon:RegisterList(name, contents, ...)
	self.lists[name] = {
		name = name,
		contents = contents,
	}
	if select("#", ...) > 0 then
		self.lists[name].cols = {}
		for i = 1, select("#", ...) do
			local cname = select(i, ...)
			if cname then
				table.insert( self.lists[name].cols, { name = cname } )
			end
		end
	end
	table.insert(self.lists, self.lists[name]) -- used to ipairs loop
	self:SetupList(name)
end

function addon:UnregisterList(name)
	if openedList == name then
		openedList = nil
		self:UpdateGUI()
	end
end

function addon:UpdateList(name)
	if not oRA3Frame:IsVisible() then return end
	if openedPanel ~= L["Checks"] then return end
	if openedList ~= name then return end
	showLists()
end

function addon:SetupList(name)
	local list = self.lists[name]
	if not list.button then
		list.button = self:CreateListButton(name)
	end
end

function addon:SetupLists()
	for k, v in ipairs(self.lists) do
		self:SetupList(v.name)
	end
end

local function selectlist(self)
	addon:SelectList(self.tabName)
end

local function tabOnShow(self) PanelTemplates_TabResize(self, 0) end

function addon:SetupPanel(name)
	if not oRA3Frame then return end

	if not oRA3Frame.oRAtabs[name] then
		lastTab = lastTab + 1
		local f = CreateFrame("Button", "oRA3FrameTab"..lastTab, oRA3Frame, "CharacterFrameTabButtonTemplate")
		f:ClearAllPoints()
		if lastTab > 1 then
			f:SetPoint("TOPLEFT", _G["oRA3FrameTab"..(lastTab-1)], "TOPRIGHT", -16, 0)
		else
			f:SetPoint("TOPLEFT", contentFrame, "BOTTOMLEFT", 0, -1)
		end
		f.tabName = name
		f:SetText(name)
		f:SetParent(contentFrame)
		f:SetScript("OnClick", selectPanel)
		f:SetScript("OnShow", tabOnShow)
		
		oRA3Frame.oRAtabs[name] = f
		if not oRA3Frame.selectedTab then
			oRA3Frame.selectedTab = 1
		end
		PanelTemplates_SetNumTabs(oRA3Frame, lastTab)
		PanelTemplates_UpdateTabs(oRA3Frame)
	end
	oRA3Frame.oRAtabs[name]:Show()
end

function addon:SelectPanel(name)
	if not contentFrame then return end
	if not name then name = self.panels[1].name end
	local panel = self.panels[name]
	if not panel then return end -- should not happen?
	openedPanel = name
	
	selectedTab = 1
	for k, v in ipairs(self.panels) do
		if v.name ~= name and type(v.hide) == "function" then
			v.hide()
		end
		if v.name == name then
			selectedTab = k
		end
	end
	
	oRA3Frame.title:SetText(name)
	oRA3Frame.selectedTab = selectedTab
	PanelTemplates_UpdateTabs(oRA3Frame)
	
	panel.show()
end

function addon:SelectList( name )
	openedList = name
	for k, v in ipairs(self.lists) do
		if v.name == openedList then
			v.button:SetNormalFontObject(GameFontHighlightSmall)
		else
			v.button:SetNormalFontObject(GameFontNormalSmall)
		end
	end
	showLists()
end


function showLists()
	addon:SetupLists()
	
	-- hide all scrollheaders per default
	for k, f in ipairs(scrollheaders) do
		f:Hide()
	end
	
	if not openedList then
		openedList = addon.lists[1].name
		addon:SelectList(openedList)
		return -- recursive protection
	end
	
	oRA3Frame.title:SetText(openedPanel.." - "..openedList)
	
	local list = addon.lists[openedList]
	if not list then return end
	
	contentFrame.listFrame:Show()
	contentFrame.scrollFrame:Show()
	local count = #list.cols + 1 -- +1, we make the name twice as wide
	local totalwidth = contentFrame.scrollFrame:GetWidth()
	local width = totalwidth/count
	while( #list.cols > #scrollheaders ) do
		addon:CreateScrollHeader()
	end	
	for k, v in ipairs(list.cols) do
		scrollheaders[k]:SetText(v.name)
		if k == 1 then
			addon:SetScrollHeaderWidth(k, width*2)
		else
			addon:SetScrollHeaderWidth(k, width)
		end
		scrollheaders[k]:Show()
	end
	addon:UpdateScroll()
end

function hideLists()
	for k, f in ipairs(scrollheaders) do
		f:Hide()
	end
	contentFrame.listFrame:Hide()
	contentFrame.scrollFrame:Hide()
end


function util:inTable(t, value, subindex)
	for k, v in pairs(t) do
		if subindex then
			if type(v) == "table" and v[subindex] == value then return k end
		elseif v == value then return k end
	end
	return nil
end

