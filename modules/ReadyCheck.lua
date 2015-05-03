
local addonName, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("ReadyCheck", "AceTimer-3.0")
local L = scope.locale

local readycheck = {} -- table containing ready check results
local frame -- will be filled with our GUI frame

local playerName = UnitName("player")
local _, playerClass = UnitClass("player")
local topMemberFrames, bottomMemberFrames = {}, {} -- ready check member frames

local roleIcons = {
	TANK = INLINE_TANK_ICON,
	HEALER = INLINE_HEALER_ICON,
	DAMAGER = INLINE_DAMAGER_ICON,
	NONE = "",
}

local readychecking = nil

local defaults = {
	profile = {
		sound = true,
		gui = true,
		autohide = true,
		hideReady = false,
		hideOnCombat = true,
		relayReady = false
	}
}
local function colorize(input) return ("|cfffed000%s|r"):format(input) end
local options
local function getOptions()
	if not options then
		options = {
			type = "group",
			name = READY_CHECK,
			get = function(k) return module.db.profile[k[#k]] end,
			set = function(k, v) module.db.profile[k[#k]] = v end,
			args = {
				sound = {
					type = "toggle",
					name = colorize(SOUND_LABEL),
					desc = L.readyCheckSound,
					width = "full",
					descStyle = "inline",
					order = 1,
				},
				gui = {
					type = "toggle",
					name = colorize(L.showWindow),
					desc = L.showWindowDesc,
					width = "full",
					descStyle = "inline",
					order = 2,
				},
				autohide = {
					type = "toggle",
					name = colorize(L.hideWhenDone),
					desc = L.hideWhenDoneDesc,
					width = "full",
					descStyle = "inline",
					order = 3,
				},
				hideOnCombat = {
					type = "toggle",
					name = colorize(L.hideInCombat),
					desc = L.hideInCombatDesc,
					width = "full",
					descStyle = "inline",
					order = 4,
				},
				hideReady = {
					type = "toggle",
					name = colorize(L.hideReadyPlayers),
					desc = L.hideReadyPlayersDesc,
					width = "full",
					descStyle = "inline",
					order = 5,
				},
				relayReady = {
					type = "toggle",
					name = colorize(L.printToRaid),
					desc = L.printToRaidDesc,
					order = 6,
					descStyle = "inline",
					width = "full",
				},
			}
		}
	end
	return options
end

local function addIconAndName(frame)
	local rdc = frame:CreateTexture(nil, "OVERLAY")
	frame.IconTexture = rdc
	rdc:SetWidth(11)
	rdc:SetHeight(11)
	rdc:SetPoint("LEFT", frame)

	local rdt = frame:CreateFontString(nil, "OVERLAY")
	frame.NameText = rdt
	rdt:SetJustifyH("LEFT")
	rdt:SetFontObject(GameFontNormal)
	rdt:SetPoint("LEFT", rdc, "RIGHT", 3)
	rdt:SetHeight(14)
	rdt:SetWidth(120)

	local bg = frame:CreateTexture(nil, "ARTWORK")
	bg:SetTexture(1, 0, 0, 0.3)
	bg:SetAllPoints(rdt)
	frame.bg = bg
	bg:Hide()
end

local function createTopFrame()
	local f = CreateFrame("Frame", nil, frame)
	table.insert(topMemberFrames, f)
	local num = #topMemberFrames
	local xoff = num % 2 == 0 and 160 or 15
	local yoff = 0 - ((math.floor(num / 2) + (num % 2)) * 14) - 17
	f:SetWidth(150)
	f:SetHeight(14)
	f:SetPoint("TOPLEFT", frame, "TOPLEFT", xoff, yoff)
	addIconAndName(f)
	return f
end

local function createBottomFrame()
	local f = CreateFrame("Frame", nil, frame)
	table.insert(bottomMemberFrames, f)
	local num = #bottomMemberFrames
	local xoff = num % 2 == 0 and 152 or 7
	local yoff = 0 - ((math.floor(num / 2) + (num % 2)) * 14) + 4
	f:SetWidth(150)
	f:SetHeight(14)
	f:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", xoff, yoff)
	addIconAndName(f)
	return f
end

local function setMemberStatus(num, bottom, name, class)
	if not name or not class then return end
	local f
	if bottom then
		f = bottomMemberFrames[num] or createBottomFrame()
	else
		f = topMemberFrames[num] or createTopFrame()
	end
	local color = oRA.classColors[class]
	local cleanName = name:gsub("%-.+", "*")
	f.NameText:SetFormattedText("%s%s", roleIcons[UnitGroupRolesAssigned(name)], cleanName)
	f.NameText:SetTextColor(color.r, color.g, color.b)
	f:SetAlpha(1)

	local status = readycheck[name]
	if status == "ready" then
		f.bg:Hide()
		f.IconTexture:SetTexture(READY_CHECK_READY_TEXTURE)
		if module.db.profile.hideReady then
			f:Hide()
		end
	elseif status == "notready" then
		f.bg:Show()
		f.IconTexture:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
	elseif status == "offline" then
		f:SetAlpha(.5)
		f.bg:Show()
		f.IconTexture:SetTexture(READY_CHECK_AFK_TEXTURE)
	else
		f.bg:Show()
		f.IconTexture:SetTexture(READY_CHECK_WAITING_TEXTURE)
	end
	f:Show()
end

local function updateWindow()
	for _, v in next, topMemberFrames do v:Hide() end
	for _, v in next, bottomMemberFrames do v:Hide() end
	frame.bar:Hide()

	local height = 0
	if IsInRaid() then
		local _, _, diff = GetInstanceInfo()
		local highgroup
		if diff == 3 or diff == 5 then -- 10 man
			highgroup = 3
		elseif diff == 4 or diff == 6 or diff == 7 then -- 25 man
			highgroup = 6
		elseif diff == 16 then -- 20 man
			highgroup = 5
		elseif diff == 14 or diff == 15 then
			highgroup = 7
		else -- 40 man
			highgroup = 9
		end

		local bottom, top = 0, 0
		for i = 1, GetNumGroupMembers() do
			local name, _, subgroup, _, _, class = GetRaidRosterInfo(i)
			if subgroup < highgroup then
				top = top + 1
				setMemberStatus(top, false, name, class)
			else
				bottom = bottom + 1
				setMemberStatus(bottom, true, name, class)
			end
		end
		height = math.ceil(top / 2) * 14 + 43

		-- position the spacer
		if bottom > 0 then
			height = height + 14 + (math.ceil(bottom / 2) * 14)
			local yoff = 0 - (math.ceil(top / 2) * 14) - 34
			frame.bar:ClearAllPoints()
			frame.bar:SetPoint("TOPLEFT", frame, 8, yoff)
			frame.bar:SetPoint("TOPRIGHT", frame, -6, yoff)
			frame.bar:Show()
		end
	else
		setMemberStatus(1, false, playerName, playerClass)
		for i = 1, GetNumSubgroupMembers() do
			local unit = ("party%d"):format(i)
			local name = module:UnitName(unit)
			local _, class = UnitClass(unit)
			setMemberStatus(i+1, false, name, class)
		end
	end

	frame:SetHeight(math.max(height, 128))
end

local function createWindow()
	if frame then return end
	frame = CreateFrame("Frame", "oRA3ReadyCheck", UIParent)

	local f = frame
	f:SetWidth(320)
	f:SetHeight(300)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	if not oRA3:RestorePosition("oRA3ReadyCheck") then
		f:ClearAllPoints()
		f:SetPoint("CENTER", UIParent, 0, 180)
	end

	local titlebg = f:CreateTexture(nil, "BACKGROUND")
	titlebg:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Title-Background]])
	titlebg:SetPoint("TOPLEFT", 9, -6)
	titlebg:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -28, -24)

	local dialogbg = f:CreateTexture(nil, "BACKGROUND")
	dialogbg:SetTexture([[Interface\Tooltips\UI-Tooltip-Background]])
	dialogbg:SetPoint("TOPLEFT", 8, -24)
	dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
	dialogbg:SetVertexColor(0, 0, 0, .75)

	local topleft = f:CreateTexture(nil, "BORDER")
	topleft:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	topleft:SetWidth(64)
	topleft:SetHeight(64)
	topleft:SetPoint("TOPLEFT")
	topleft:SetTexCoord(0.501953125, 0.625, 0, 1)

	local topright = f:CreateTexture(nil, "BORDER")
	topright:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	topright:SetWidth(64)
	topright:SetHeight(64)
	topright:SetPoint("TOPRIGHT")
	topright:SetTexCoord(0.625, 0.75, 0, 1)

	local top = f:CreateTexture(nil, "BORDER")
	top:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	top:SetHeight(64)
	top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
	top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
	top:SetTexCoord(0.25, 0.369140625, 0, 1)

	local bottomleft = f:CreateTexture(nil, "BORDER")
	bottomleft:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	bottomleft:SetWidth(64)
	bottomleft:SetHeight(64)
	bottomleft:SetPoint("BOTTOMLEFT")
	bottomleft:SetTexCoord(0.751953125, 0.875, 0, 1)

	local bottomright = f:CreateTexture(nil, "BORDER")
	bottomright:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	bottomright:SetWidth(64)
	bottomright:SetHeight(64)
	bottomright:SetPoint("BOTTOMRIGHT")
	bottomright:SetTexCoord(0.875, 1, 0, 1)

	local bottom = f:CreateTexture(nil, "BORDER")
	bottom:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	bottom:SetHeight(64)
	bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
	bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")
	bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)

	local left = f:CreateTexture(nil, "BORDER")
	left:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	left:SetWidth(64)
	left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
	left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")
	left:SetTexCoord(0.001953125, 0.125, 0, 1)

	local right = f:CreateTexture(nil, "BORDER")
	right:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	right:SetWidth(64)
	right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")
	right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
	right:SetTexCoord(0.1171875, 0.2421875, 0, 1)

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 1)
	close:SetScript("OnClick", function(self, button) f:Hide() end)

	local title = f:CreateFontString(nil, "ARTWORK")
	title:SetFontObject(GameFontNormal)
	title:SetPoint("TOPLEFT", 12, -8)
	title:SetPoint("TOPRIGHT", -32, -8)
	title:SetText(READY_CHECK)
	f.title = title

	local titlebutton = CreateFrame("Button", nil, f)
	titlebutton:SetPoint("TOPLEFT", titlebg)
	titlebutton:SetPoint("BOTTOMRIGHT", titlebg)
	titlebutton:RegisterForDrag("LeftButton")
	titlebutton:SetScript("OnDragStart", function()
		f.moving = true
		f:StartMoving()
	end)
	titlebutton:SetScript("OnDragStop", function()
		f.moving = nil
		f:StopMovingOrSizing()
		oRA3:SavePosition("oRA3ReadyCheck")
	end)

	local bar = CreateFrame("Button", nil, frame)
	frame.bar = bar
	bar:SetPoint("TOPLEFT", frame, 8, -150)
	bar:SetPoint("TOPRIGHT", frame, -6, -150)
	bar:SetHeight(8)

	local barmiddle = bar:CreateTexture(nil, "BORDER")
	barmiddle:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	barmiddle:SetAllPoints(bar)
	barmiddle:SetTexCoord(0.29296875, 1, 0, 0.25)


	local animFader = f:CreateAnimationGroup()
	animFader:SetLooping("NONE")

	local fader = animFader:CreateAnimation("Alpha")
	fader:SetChange(-1)
	fader:SetStartDelay(2.5)
	fader:SetDuration(1)
	fader:SetScript("OnFinished", function(self) f:Hide() end)

	local animUpdater = f:CreateAnimationGroup()
	animUpdater:SetLooping("REPEAT")
	animUpdater:SetScript("OnLoop", function(self)
		local timer = GetReadyCheckTimeLeft()
		if timer > 0 then
			title:SetText(L.readyCheckSeconds:format(timer))
		else
			title:SetText(READY_CHECK_FINISHED)
			self:Stop()
			if module.db.profile.autohide then
				animFader:Play()
			end
		end
	end)

	local timer = animUpdater:CreateAnimation()
	timer:SetStartDelay(1)
	timer:SetDuration(0.3)

	f:SetScript("OnShow", function(self)
		animFader:Stop()
		title:SetText(READY_CHECK)
		self:SetAlpha(1)
		animUpdater:Play()
		updateWindow()
		module:RegisterEvent("GROUP_ROSTER_UPDATE", updateWindow) -- pick up group changes
	end)
	f:SetScript("OnHide", function(self)
		module:UnregisterEvent("GROUP_ROSTER_UPDATE")
		animUpdater:Stop()
		animFader:Stop()
	end)
end

local function sysprint(msg)
	local filters = ChatFrame_GetMessageEventFilters("CHAT_MSG_SYSTEM")
	if filters then
		for _, func in next, filters do
			local filter, newMsg = func(nil, "CHAT_MSG_SYSTEM", msg)
			if filter then
				return true
			elseif newMsg then
				msg = newMsg
			end
		end
	end

	local info = ChatTypeInfo["SYSTEM"]
	for i=1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		for _, msgType in ipairs(frame.messageTypeList) do
			if msgType == "SYSTEM" then
				frame:AddMessage(msg, info.r, info.g, info.b, info.id)
				break
			end
		end
	end
end

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("ReadyCheck", defaults)
	oRA:RegisterModuleOptions("ReadyCheck", getOptions, READY_CHECK)
end

function module:OnEnable()
	-- Ready Check Events
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("READY_CHECK_FINISHED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")

	SLASH_ORAREADYCHECK1 = "/rar"
	SLASH_ORAREADYCHECK2 = "/raready"
	SlashCmdList.ORAREADYCHECK = SlashCmdList.READYCHECK
end

function module:PLAYER_REGEN_DISABLED()
	if not self.db.profile.hideOnCombat or not frame then return end
	frame:Hide()
end

function module:READY_CHECK(initiator, duration)
	if self.db.profile.sound then PlaySoundFile("Sound\\interface\\levelup2.ogg", "Master") end

	self:CancelTimer(readychecking)
	readychecking = self:ScheduleTimer("READY_CHECK_FINISHED", duration+1) -- for preempted finishes (READY_CHECK_FINISHED fires before READY_CHECK)

	wipe(readycheck)
	local promoted = oRA:IsPromoted()
	-- fill with default "No Response" and set the initiator "Ready"
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
			if name then -- Can be nil when performed whilst logging on
				local status = not online and "offline" or GetReadyCheckStatus(name)
				readycheck[name] = status
				if not promoted and (status == "offline" or status == "notready") then
					sysprint(RAID_MEMBER_NOT_READY:format(name))
				end
			end
		end
	else
		readycheck[playerName] = GetReadyCheckStatus("player")
		for i = 1, GetNumSubgroupMembers() do
			local unit = ("party%d"):format(i)
			local name = self:UnitName(unit)
			if name and name ~= UNKNOWN then
				local status = not UnitIsConnected(unit) and "offline" or GetReadyCheckStatus(name)
				readycheck[name] = status
				if not promoted and (status == "offline" or status == "notready") then
					sysprint(RAID_MEMBER_NOT_READY:format(name))
				end
			end
		end
	end

	-- show the readycheck result frame
	if self.db.profile.gui then
		createWindow()
		frame:Hide()
		frame:Show()
	end
end

function module:READY_CHECK_CONFIRM(unit, ready)
	if not readychecking then return end
	if unit:find("party", nil, true) and IsInRaid() then return end -- prevent multiple prints if you're in their party
	local name = self:UnitName(unit)
	if not name then return end

	if ready then
		readycheck[name] = "ready"
	elseif readycheck[name] ~= "offline" then -- not ready, ignore offline
		readycheck[name] = "notready"
		if not oRA:IsPromoted() then
			sysprint(RAID_MEMBER_NOT_READY:format(name))
		end
	end
	if self.db.profile.gui and frame then
		updateWindow()
	end
end

do
	local noReply = {}
	local notReady = {}
	module.stripservers = true
	function module:READY_CHECK_FINISHED(preempted)
		if not readychecking or preempted then return end -- is a dungeon group ready check

		self:CancelTimer(readychecking)
		readychecking = nil

		wipe(noReply)
		wipe(notReady)
		for name, ready in next, readycheck do
			if module.stripservers then -- this is a hook for other addons to enable unambiguous character names
				name = name:gsub("%-.*$", "")
			end
			if ready == "waiting" or ready == "offline" then
				noReply[#noReply + 1] = name
			elseif ready == "notready" then
				notReady[#notReady + 1] = name
			end
		end

		local promoted = oRA:IsPromoted()
		local send = self.db.profile.relayReady and promoted and promoted > 1 and IsInRaid() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
		if #noReply == 0 and #notReady == 0 then
			if not promoted then
				sysprint(READY_CHECK_ALL_READY)
			elseif send then
				SendChatMessage(READY_CHECK_ALL_READY, "RAID")
			end
		else
			if #noReply > 0 then
				local afk = RAID_MEMBERS_AFK:format(table.concat(noReply, ", "))
				if not promoted then
					sysprint(afk)
				elseif send then
					SendChatMessage(afk, "RAID")
				end
			end
			if #notReady > 0 then
				local no = L.playersNotReady:format(table.concat(notReady, ", "))
				if not promoted then
					sysprint(no)
				elseif send then
					SendChatMessage(no, "RAID")
				end
			end
		end
	end
end

