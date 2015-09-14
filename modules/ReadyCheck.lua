
local addonName, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("ReadyCheck", "AceTimer-3.0")
local L = scope.locale
module.stripservers = true

local _G = _G
local min, max, ceil, floor = math.min, math.max, math.ceil, math.floor
local concat, wipe, sort, tinsert = table.concat, table.wipe, table.sort, table.insert
local tonumber, select, next, ipairs, print = tonumber, select, next, ipairs, print
local UnitIsConnected, UnitIsDeadOrGhost, UnitIsVisible = UnitIsConnected, UnitIsDeadOrGhost, UnitIsVisible
local GetSpellDescription, GetSpellInfo, GetRaidRosterInfo = GetSpellDescription, GetSpellInfo, GetRaidRosterInfo
local GetInstanceInfo, GetNumGroupMembers, GetNumSubgroupMembers = GetInstanceInfo, GetNumGroupMembers, GetNumSubgroupMembers
local GetReadyCheckStatus, GetReadyCheckTimeLeft, GetTime = GetReadyCheckStatus, GetReadyCheckTimeLeft, GetTime
local IsInRaid, IsInGroup, UnitGroupRolesAssigned = IsInRaid, IsInGroup, UnitGroupRolesAssigned
local PlaySoundFile, DoReadyCheck = PlaySoundFile, DoReadyCheck

-- GLOBALS: INLINE_TANK_ICON INLINE_HEALER_ICON INLINE_DAMAGER_ICON SPELL_FAILED_OUT_OF_RANGE SOUND_LABEL YES UNKNOWN
-- GLOBALS: READY_CHECK READY_CHECK_FINISHED READY_CHECK_ALL_READY RAID_MEMBER_NOT_READY RAID_MEMBERS_AFK DISABLE
-- GLOBALS: READY_CHECK_READY_TEXTURE READY_CHECK_NOT_READY_TEXTURE READY_CHECK_AFK_TEXTURE READY_CHECK_WAITING_TEXTURE
-- GLOBALS: GameTooltip GameTooltip_Hide GameFontNormal UIParent UISpecialFrames ChatTypeInfo
-- GLOBALS: CreateFrame UnitClass SendChatMessage ChatFrame_GetMessageEventFilters ChatFrame_AddMessageEventFilter
-- GLOBALS: SlashCmdList SLASH_ORAREADYCHECK1 SLASH_ORAREADYCHECK2 SLASH_ORARAIDCHECK1 SLASH_ORARAIDCHECK2

local consumables = oRA:GetModule("Consumables")

local readycheck = {} -- table containing ready check results
local readygroup = {}
local highgroup = 9
local frame -- will be filled with our GUI frame
local showBuffFrame = false
local availableBuffs = 0
local list = {} -- temp table to concat from
local lastUpdate = 0

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
local clearchecking = nil

local defaults = {
	profile = {
		sound = true,
		showWindow = true,
		autohide = true,
		hideReady = false,
		hideOnCombat = true,
		relayReady = false,
		readyByGroup = true,
		showBuffs = 1,
		showMissingMaxStat = false,
		showMissingRunes = false,
	}
}
local function reanchorBuffs(frame, value) -- don't show an empty space for runes if disabled
	if value then
		frame.FlaskBuff:SetPoint("RIGHT", frame.RuneBuff, "LEFT", 0, 0)
		frame.RuneBuff:Show()
	else
		frame.FlaskBuff:SetPoint("RIGHT", frame.MissingBuffs, "LEFT", 0, 0)
		frame.RuneBuff:Hide()
	end
end
local function colorize(input) return ("|cfffed000%s|r"):format(input) end
local options = {
	type = "group",
	name = READY_CHECK,
	get = function(k) return module.db.profile[k[#k]] end,
	set = function(k, v) module.db.profile[k[#k]] = v end,
	args = {
		sound = {
			type = "toggle",
			name = colorize(SOUND_LABEL),
			desc = L.readyCheckSound,
			descStyle = "inline",
			width = "full",
			order = 1,
		},
		showWindow = {
			type = "toggle",
			name = colorize(L.showWindow),
			desc = L.showWindowDesc,
			descStyle = "inline",
			width = "full",
			order = 2,
		},
		autohide = {
			type = "toggle",
			name = colorize(L.hideWhenDone),
			desc = L.hideWhenDoneDesc,
			descStyle = "inline",
			width = "full",
			order = 3,
		},
		hideOnCombat = {
			type = "toggle",
			name = colorize(L.hideInCombat),
			desc = L.hideInCombatDesc,
			descStyle = "inline",
			width = "full",
			order = 4,
		},
		hideReady = {
			type = "toggle",
			name = colorize(L.hideReadyPlayers),
			desc = L.hideReadyPlayersDesc,
			descStyle = "inline",
			width = "full",
			order = 5,
		},
		relayReady = {
			type = "toggle",
			name = colorize(L.printToRaid),
			desc = L.printToRaidDesc,
			descStyle = "inline",
			width = "full",
			order = 6,
		},
		readyByGroup ={
			type = "toggle",
			name = colorize(L.readyByGroup),
			desc = L.readyByGroupDesc,
			descStyle = "inline",
			width = "full",
			order = 7,
		},
		sep = {
			type = "description",
			name = "",
			order = 9,
		},
		consumables = {
			type = "group",
			name = L.consumables,
			inline = true,
			order = 10,
			args = {
				showBuffs = {
					type = "select",
					name = colorize(L.showBuffs),
					desc = L.showBuffsDesc,
					values = { [0] = DISABLE, [1] = L.showMissingBuffs, [2] = L.showCurrentBuffs },
					--style = "radio",
					get = function()
						local value = module.db.profile.showBuffs
						if value == false then value = 0 end
						return value
					end,
					set = function(_, value)
						if value == 0 then value = false end
						module.db.profile.showBuffs = value
					end,
					order = 1,
				},
				showMissingRunes = {
					type = "toggle",
					name = colorize(L.showMissingRunes),
					desc = L.showMissingRunesDesc,
					descStyle = "inline",
					set = function(info, value)
						module.db.profile.showMissingRunes = value
						for _, frame in next, topMemberFrames do reanchorBuffs(frame, value) end
						for _, frame in next, bottomMemberFrames do reanchorBuffs(frame, value) end
						lastUpdate = 0
					end,
					disabled = function() return not module.db.profile.showBuffs end,
					width = "full",
					order = 2,
				},
				showMissingMaxStat = {
					type = "toggle",
					name = colorize(L.showMissingMaxStat),
					desc = L.showMissingMaxStatDesc,
					descStyle = "inline",
					disabled = function() return not module.db.profile.showBuffs end,
					width = "full",
					order = 3,
				},
			},
		},
	}
}


local function Frame_Tooltip(self)
	if self.name then
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		local unit = self:GetParent().player
		GameTooltip:SetUnitBuff(unit, self.name)
		if self.tooltip then
			GameTooltip:AddLine("\n"..self.tooltip)
		end
		GameTooltip:Show()
	elseif self.tooltip then
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:AddLine(self.tooltip)
		GameTooltip:Show()
	end
end

local addBuffFrame
do
	local function SetSpell(self, id)
		self.tooltip = nil
		if id and id < 0 then id = -id end

		local name, _, icon = GetSpellInfo(id or 0)
		if not name then
			self.name = nil
			self.tooltip = self.defaultTooltip
			self.icon:SetTexture(self.defaultIcon)
			self.icon:SetDesaturated(true)
			self.icon:SetVertexColor(1, 0.5, 0.5, 1) -- red
			if self.text then
				self.text:SetText("")
			end
			return
		end

		self.name = name
		self.icon:SetTexture(icon)
		self.icon:SetDesaturated(false)
		self.icon:SetVertexColor(1, 1, 1, 1) -- restore color
	end

	function addBuffFrame(name, parent, tooltip, icon, ...)
		local frame = CreateFrame("Frame", parent:GetName()..name, parent)
		frame:SetWidth(12)
		frame:SetHeight(12)
		if select("#", ...) > 0 then
			frame:SetPoint(...)
		end

		local texture = frame:CreateTexture(nil, "OVERLAY")
		texture:SetAllPoints()
		texture:SetTexture(icon)
		texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		frame.icon = texture
		frame.defaultIcon = icon
		frame.defaultTooltip = tooltip

		frame:EnableMouse(true)
		frame:SetScript("OnEnter", Frame_Tooltip)
		frame:SetScript("OnLeave", GameTooltip_Hide)
		frame.SetSpell = SetSpell

		return frame
	end
end

local function addIconAndName(frame)
	local rdc = frame:CreateTexture(nil, "OVERLAY")
	rdc:SetWidth(11)
	rdc:SetHeight(11)
	rdc:SetPoint("LEFT", frame)
	frame.IconTexture = rdc

	local rdt = frame:CreateFontString(nil, "OVERLAY")
	rdt:SetJustifyH("LEFT")
	rdt:SetFontObject(GameFontNormal)
	rdt:SetPoint("LEFT", rdc, "RIGHT", 3)
	rdt:SetHeight(14)
	rdt:SetWidth(120)
	frame.NameText = rdt

	-- out of range indicator
	local oor = addBuffFrame("Range", frame, nil, "Interface\\TargetingFrame\\UI-PhasingIcon", "RIGHT", frame, "RIGHT", -6, 0)
	oor.icon:SetTexCoord(0.15625, 0.84375, 0.15625, 0.84375)
	oor.tooltip = SPELL_FAILED_OUT_OF_RANGE
	frame.OutOfRange = oor

	-- missing buffs
	frame.MissingBuffs = addBuffFrame("Buffs", frame, nil, "Interface\\DialogFrame\\DialogIcon-AlertNew-16", "RIGHT", frame, "RIGHT", -6, 0)
	frame.MissingBuffs.icon:SetTexCoord(0, 1, 0, 1)
	frame.RuneBuff = addBuffFrame("Rune", frame, L.noRune, "Interface\\Icons\\inv_misc_rune_12", "RIGHT", frame.MissingBuffs, "LEFT", 0, 0)
	frame.FlaskBuff = addBuffFrame("Flask", frame, L.noFlask, "Interface\\Icons\\trade_alchemy_dpotion_c22")
	reanchorBuffs(frame, module.db.profile.showMissingRunes)

	local food = addBuffFrame("Food", frame, L.noFood, "Interface\\Icons\\spell_misc_food", "RIGHT", frame.FlaskBuff, "LEFT", 0, 0)
	local text = food:CreateFontString(nil, "OVERLAY")
	text:SetPoint("BOTTOMRIGHT")
	text:SetJustifyH("RIGHT")
	text:SetFont("Fonts\\ARIALN.TTF", 8, "OUTLINE")
	food.text = text
	frame.FoodBuff = food

	local bg = frame:CreateTexture(nil, "ARTWORK")
	bg:SetTexture(1, 0, 0, 0.3)
	bg:SetAllPoints(rdt)
	frame.bg = bg
	bg:Hide()
end

local function createTopFrame()
	local num = #topMemberFrames + 1
	local f = CreateFrame("Frame", "oRA3ReadyCheckTopFrame"..num, frame)
	topMemberFrames[num] = f
	local xoff = num % 2 == 0 and 160 or 15
	local yoff = 0 - ((floor(num / 2) + (num % 2)) * 14) - 17
	f:SetWidth(150)
	f:SetHeight(14)
	f:SetPoint("TOPLEFT", frame, "TOPLEFT", xoff, yoff)
	addIconAndName(f)
	return f
end

local function createBottomFrame()
	local num = #bottomMemberFrames + 1
	local f = CreateFrame("Frame", "oRA3ReadyCheckBottomFrame"..num, frame)
	bottomMemberFrames[num] = f
	local xoff = num % 2 == 0 and 152 or 7
	local yoff = 0 - ((floor(num / 2) + (num % 2)) * 14) + 4
	f:SetWidth(150)
	f:SetHeight(14)
	f:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", xoff, yoff)
	addIconAndName(f)
	return f
end

local function getStatValue(id)
	local desc = GetSpellDescription(id)
	if desc then
		local value = tonumber(desc:match("(%d+)")) or 0
		return value >= 75 and value or YES
	end
end

local function setMemberStatus(num, bottom, name, class, update)
	if not name or not class then return end
	local f
	if bottom then
		f = bottomMemberFrames[num] or createBottomFrame()
	else
		f = topMemberFrames[num] or createTopFrame()
	end
	f.player = name

	local ready = true
	if module.db.profile.showBuffs and showBuffFrame and UnitIsConnected(name) and not UnitIsDeadOrGhost(name) and UnitIsVisible(name) then
		f.OutOfRange:Hide()
		if update then
			local food, flask, rune, buffs, numBuffs = consumables:CheckPlayer(name)
			local showMissing = module.db.profile.showBuffs == 1
			local onlyMax = module.db.profile.showMissingMaxStat
			ready = food and flask and (not module.db.profile.showMissingRunes or rune) and true

			if showMissing then
				f.FoodBuff:SetShown(not food)
				f.FlaskBuff:SetShown(not flask)
				f.RuneBuff:SetShown(not rune)
			else
				f.FoodBuff:SetShown(food)
				f.FlaskBuff:SetShown(flask)
				f.RuneBuff:SetShown(rune)
			end
			f.MissingBuffs:Hide()

			f.FoodBuff:SetSpell(food)
			if food then
				f.FoodBuff.text:SetText(getStatValue(food) or "")
				if food < 0 then
					f.FoodBuff:Show()
					ready = false
				elseif onlyMax and not consumables:IsBest(food) then
					f.FoodBuff.tooltip = L.notBestBuff
					ready = false
					if showMissing then
						f.FoodBuff:Show()
					else
						f.FoodBuff.icon:SetDesaturated(true)
						f.FoodBuff.icon:SetVertexColor(1, 0.5, 0.5, 1) -- red
					end
				end
			end

			f.FlaskBuff:SetSpell(flask)
			if flask and onlyMax and not consumables:IsBest(flask) then
				f.FlaskBuff.tooltip = L.notBestBuff
				ready = false
				if showMissing then
					f.FlaskBuff.icon:SetDesaturated(true)
					f.FlaskBuff.icon:SetVertexColor(1, 1, 0.5, 1) -- yellow
					f.FlaskBuff:Show()
				else
					f.FlaskBuff.icon:SetDesaturated(true)
					f.FlaskBuff.icon:SetVertexColor(1, 0.5, 0.5, 1) -- red
				end
			end

			f.RuneBuff:SetSpell(rune)
			if not module.db.profile.showMissingRunes then
				f.RuneBuff:Hide()
			end

			if buffs and numBuffs < availableBuffs then
				wipe(list)
				for k in next, buffs do
					list[#list + 1] = k
				end
				sort(list)
				f.MissingBuffs.tooltip = ("%s: %s"):format(L.missingBuffs, concat(list, ", "))
				f.MissingBuffs:Show()
			end
		end
	else
		f.OutOfRange:SetShown(module.db.profile.showBuffs and showBuffFrame)
		f.MissingBuffs:Hide()
		f.FoodBuff:Hide()
		f.FlaskBuff:Hide()
		f.RuneBuff:Hide()
	end

	local color = oRA.classColors[class]
	local cleanName = name:gsub("%-.+", "*")
	f.NameText:SetFormattedText("%s%s", roleIcons[UnitGroupRolesAssigned(name)], cleanName)
	f.NameText:SetTextColor(color.r, color.g, color.b)
	f:SetAlpha(1)
	f:Show()

	local status = readycheck[name]
	if not status then
		if not UnitIsConnected(name) then
			f:SetAlpha(0.5)
		end
		f.bg:Hide()
		f.IconTexture:SetTexture(nil)
	elseif status == "ready" then
		f.bg:Hide()
		f.IconTexture:SetTexture(READY_CHECK_READY_TEXTURE)
		if module.db.profile.hideReady and ready then
			f:Hide()
		end
	elseif status == "notready" then
		f.bg:Show()
		f.IconTexture:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
	elseif status == "offline" then
		f:SetAlpha(0.5)
		f.bg:Show()
		f.IconTexture:SetTexture(READY_CHECK_AFK_TEXTURE)
	else
		f.bg:Show()
		f.IconTexture:SetTexture(READY_CHECK_WAITING_TEXTURE)
	end
end

local function updateWindow()
	for _, v in next, topMemberFrames do v:Hide() end
	for _, v in next, bottomMemberFrames do v:Hide() end
	frame.bar:Hide()
	frame.MissingGroupBuffs:Hide()

	local promoted = oRA:IsPromoted()
	frame.ready:SetDisabled(not promoted)
	frame.check:SetDisabled(not promoted or IsInGroup(2))

	-- buff check throttle
	local update = nil
	local t = GetTime()
	if t-lastUpdate > 1 then
		lastUpdate = t
		update = true
	end

	local _, type, diff = GetInstanceInfo()
	showBuffFrame = module.db.profile.showBuffs and (type == "raid" or (type == "party" and diff == 8)) -- in raid or challenge mode

	local missingBuffs, numBuffs
	if showBuffFrame then
		_, _, _, missingBuffs, numBuffs, availableBuffs = consumables:CheckGroup()
		-- the first and second return from GetRaidBuffInfo don't always agree
		-- first doesn't take spec into account and second caps with group size
		-- soooo just hide it if we have the most we can (according to the api)
		-- if numBuffs == availableBuffs then
		-- 	missingBuffs = nil
		-- end
		-- XXX actually, availableBuffs seems be lower a lot of the time
	end

	local height = 0
	if IsInRaid() then


		local bottom, top = 0, 0
		for i = 1, GetNumGroupMembers() do
			local name, _, subgroup, _, _, class = GetRaidRosterInfo(i)
			if subgroup < highgroup then
				top = top + 1
				setMemberStatus(top, false, name, class, update)
			else
				bottom = bottom + 1
				setMemberStatus(bottom, true, name, class, update)
			end
		end
		height = ceil(top / 2) * 14 + 43

		-- position the spacer
		if bottom > 0 then
			height = height + 14 + (ceil(bottom / 2) * 14)
			local yoff = 0 - (ceil(top / 2) * 14) - 34
			frame.bar:ClearAllPoints()
			frame.bar:SetPoint("TOPLEFT", frame, 8, yoff)
			frame.bar:SetPoint("TOPRIGHT", frame, -6, yoff)
			frame.bar:Show()
		end
	else
		setMemberStatus(1, false, playerName, playerClass, update)
		for i = 1, GetNumSubgroupMembers() do
			local unit = ("party%d"):format(i)
			local name = module:UnitName(unit)
			local _, class = UnitClass(unit)
			setMemberStatus(i+1, false, name, class, update)
		end
	end

	frame:SetHeight(max(height, 128))

	if missingBuffs and next(missingBuffs) then
		wipe(list)
		for k in next, missingBuffs do
			list[#list + 1] = k
		end
		sort(list)
		frame.MissingGroupBuffs:SetText(concat(list, ", "))
		frame.MissingGroupBuffs:Show()
	end
end

local function createWindow()
	if frame then return end
	frame = CreateFrame("Frame", "oRA3ReadyCheck", UIParent)
	frame:Hide()
	tinsert(UISpecialFrames, "oRA3ReadyCheck") -- Close on ESC

	local f = frame
	f:SetWidth(320)
	f:SetHeight(300)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	if not oRA:RestorePosition("oRA3ReadyCheck") then
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

	local close = CreateFrame("Button", "oRA3ReadyCheckCloseButton", f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 1)
	close:SetScript("OnClick", function(self, button) f:Hide() end)

	local title = f:CreateFontString(nil, "ARTWORK")
	title:SetFontObject(GameFontNormal)
	title:SetPoint("TOPLEFT", 12, -8)
	title:SetPoint("TOPRIGHT", -32, -8)
	title:SetText(L.raidCheck)
	f.title = title

	local ready = CreateFrame("Button", "oRA3ReadyCheckReadyCheckButton", f)
	ready:SetNormalTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
	ready:SetSize(12, 12)
	ready:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -8)
	ready.SetDisabled = function(self, value)
		self:GetNormalTexture():SetDesaturated(value)
		self.disabled = value
	end
	ready:SetScript("OnClick", function(self)
		if not self.disabled then
			DoReadyCheck()
		end
	end)
	ready:SetScript("OnEnter", Frame_Tooltip)
	ready:SetScript("OnLeave", GameTooltip_Hide)
	ready.tooltip = READY_CHECK
	f.ready = ready

	local check = CreateFrame("Button", "oRA3ReadyCheckConsumableCheckButton", f)
	check:SetNormalTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting")
	check:SetSize(12, 12)
	check:SetPoint("LEFT", ready, "RIGHT", 2, 0)
	check.SetDisabled = function(self, value)
		self:GetNormalTexture():SetDesaturated(value)
		self.disabled = value
	end
	check:SetScript("OnClick", function(self)
		if not self.disabled then
			consumables:OutputResults(true)
		end
	end)
	check:SetScript("OnEnter", Frame_Tooltip)
	check:SetScript("OnLeave", GameTooltip_Hide)
	check.tooltip = L.outputMissing
	f.check = check

	local titlebutton = CreateFrame("Button", "oRA3ReadyCheckTitle", f)
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
		oRA:SavePosition("oRA3ReadyCheck")
	end)

	local bar = CreateFrame("Button", nil, f)
	bar:SetPoint("TOPLEFT", f, 8, -150)
	bar:SetPoint("TOPRIGHT", f, -6, -150)
	bar:SetHeight(8)
	f.bar = bar

	local barmiddle = bar:CreateTexture(nil, "BORDER")
	barmiddle:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	barmiddle:SetAllPoints(bar)
	barmiddle:SetTexCoord(0.29296875, 1, 0, 0.25)

	-- missing buffs
	local missingBuffs = CreateFrame("Frame", "oRA3ReadyCheckMissingGroupBuffs", f)

	local text = missingBuffs:CreateFontString(nil, "OVERLAY")
	text:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -2)
	text:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, 2)
	text:SetHeight(24)
	text:SetFontObject(GameFontNormal)
	text:SetJustifyV("TOP")
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	text:SetWordWrap(true)

	missingBuffs.SetText = function(_, message)
		text:SetFormattedText("|TInterface\\DialogFrame\\DialogIcon-AlertNew-16:0|t %s: %s", L.missingBuffs, message)
	end

	f.MissingGroupBuffs = missingBuffs

	-- updater
	local animFader = f:CreateAnimationGroup()
	animFader:SetLooping("NONE")

	local fader = animFader:CreateAnimation("Alpha")
	fader:SetChange(-1)
	fader:SetStartDelay(2.5)
	fader:SetDuration(1)
	fader:SetScript("OnFinished", function(self) f:Hide() end)
	f.animFader = animFader

	local animUpdater = f:CreateAnimationGroup()
	animUpdater:SetLooping("REPEAT")
	animUpdater:SetScript("OnLoop", function(self)
		updateWindow()
		local timer = GetReadyCheckTimeLeft()
		if readychecking and timer > 0.5 then
			title:SetFormattedText("oRA: %s", L.readyCheckSeconds:format(timer))
		elseif not readychecking and not next(readycheck) then
			title:SetFormattedText("oRA: %s", L.raidCheck)
		end
	end)

	local timer = animUpdater:CreateAnimation()
	timer:SetStartDelay(1)
	timer:SetDuration(0.3)
	f.animUpdater = animUpdater

	f:SetScript("OnShow", function(self)
		lastUpdate = 0
		animFader:Stop()
		self:SetAlpha(1)
		animUpdater:Play()
		updateWindow()
	end)
	f:SetScript("OnHide", function(self)
		animUpdater:Stop()
		animFader:Stop()
	end)
end

local function showFrame()
	if not readychecking and module.db.profile.showBuffs == 0 then
		-- print("Showing buffs on the ready check frame is disabled!")
		return
	end

	if createWindow then
		createWindow()
		createWindow = nil
	end
	frame:Hide()
	frame:Show()
end

local sysprint
do
	-- filter all the ready check messages and direct print our own
	local messages = {
		RAID_MEMBER_NOT_READY:gsub("%%s", "(.-)"), -- %s is not ready
		RAID_MEMBERS_AFK:gsub("%%s", "(.-)"),      -- The following players are Away: %s
		READY_CHECK_ALL_READY,                     -- Everyone is Ready
	}
	local system = ChatTypeInfo.SYSTEM

	-- avoid ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM") because it traumatized Funkeh and now he can't stand to even look at it
	-- ugly ass hooks it is! can't even anchor the searches because this is the final decorated output (depending on other hooks)
	local hooks = {}
	local function hookFunc(self, msg, r, g, b, id, ...)
		if readychecking and id == system.id then
			for _, string in next, messages do
				if msg:match(string) then return end
			end
		end
		if id == "oRA" then
			id = system.id
		end
		hooks[self](self, msg, r, g, b, id, ...)
	end

	for i = 1, 10 do
		local frame = _G["ChatFrame"..i]
		hooks[frame] = frame.AddMessage
		frame.AddMessage = hookFunc
	end

	function sysprint(msg)
		-- allow other addons to remove/modify the ready check messages via the filter system
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

		for frame in next, hooks do
			for _, msgType in ipairs(frame.messageTypeList) do
				if msgType == "SYSTEM" then
					frame:AddMessage(msg, system.r, system.g, system.b, "oRA")
					break
				end
			end
		end
	end
end

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("ReadyCheck", defaults)
	oRA:RegisterModuleOptions("ReadyCheck", options)
	self.db.profile.gui = nil -- XXX temp cleanup
end

function module:OnEnable()
	oRA.RegisterCallback(self, "OnGroupChanged")
	-- Ready Check Events
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("READY_CHECK_FINISHED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")

	SLASH_ORAREADYCHECK1 = "/rar"
	SLASH_ORAREADYCHECK2 = "/raready"
	SlashCmdList.ORAREADYCHECK = SlashCmdList.READYCHECK

	SLASH_ORARAIDCHECK1 = "/rarc"
	SLASH_ORARAIDCHECK2 = "/racheck"
	SlashCmdList.ORARAIDCHECK = function()
		local _, type, diff = GetInstanceInfo()
		if module.db.profile.showBuffs and (type == "raid" or (type == "party" and diff == 8)) then -- in raid or challenge mode
			showFrame()
		else
			print(("|cFFFFFF00%s|r"):format(L.notInRaid))
		end
	end
end

function module:PLAYER_REGEN_DISABLED()
	if self.db.profile.hideOnCombat and frame and frame:IsShown() then
		frame:Hide()
	end
end

local function checkReady()
	for name in next, readygroup do
		if readycheck[name] ~= "ready" then
			return
		end
	end
	module:READY_CHECK_FINISHED()
end

function module:OnGroupChanged()
	if not readychecking or not IsInRaid() or not self.db.profile.readyByGroup then return end

	local update = nil
	for i = 1, GetNumGroupMembers() do
		local name, _, group = GetRaidRosterInfo(i)
		if group < highgroup and not readygroup[name] then
			readygroup[name] = true
			update = true
		elseif readygroup[name] then
			readygroup[name] = nil
			update = true
		end
	end

	if update then
		checkReady()
	end
end

function module:READY_CHECK(initiator, duration)
	if self.db.profile.sound then PlaySoundFile("Sound\\interface\\levelup2.ogg", "Master") end

	self:CancelTimer(clearchecking)
	self:CancelTimer(readychecking)
	readychecking = self:ScheduleTimer("READY_CHECK_FINISHED", duration+1) -- for preempted finishes (READY_CHECK_FINISHED fires before READY_CHECK)

	wipe(readycheck)
	wipe(readygroup)
	local promoted = oRA:IsPromoted()
	-- fill with "waiting" and set the initiator to "ready"
	if IsInRaid() then
		local _, _, diff = GetInstanceInfo()
		if diff == 3 or diff == 5 then -- 10 man
			highgroup = 3
		elseif diff == 4 or diff == 6 or diff == 7 then -- 25 man
			highgroup = 6
		elseif diff == 16 then -- 20 man (mythic)
			highgroup = 5
		elseif diff == 14 or diff == 15 then -- 30 man (flex)
			highgroup = 7
		else -- 40 man
			highgroup = 9
		end

		for i = 1, GetNumGroupMembers() do
			local name, _, group, _, _, _, _, online = GetRaidRosterInfo(i)
			if name then -- Can be nil when performed whilst logging on
				local status = not online and "offline" or GetReadyCheckStatus(name)
				readycheck[name] = status
				if group < highgroup then
					readygroup[name] = true
				end
				if (status == "offline" or status == "notready") and (not self.db.profile.readyByGroup or readygroup[name]) then
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
				readygroup[name] = true
				if status == "offline" or status == "notready" then
					sysprint(RAID_MEMBER_NOT_READY:format(name))
				end
			end
		end
	end

	-- show the readycheck result frame
	if self.db.profile.showWindow then
		showFrame()
		frame.title:SetText(READY_CHECK)
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
		if not self.db.profile.readyByGroup or readygroup[name] then
			sysprint(RAID_MEMBER_NOT_READY:format(name))
		end
	end
	if self.db.profile.readyByGroup then
		checkReady()
	end
end

do
	local noReply = {}
	local notReady = {}
	function module:READY_CHECK_FINISHED(preempted)
		if not readychecking or preempted then return end -- is a dungeon group ready check (finish fires first)

		self:CancelTimer(readychecking)
		readychecking = nil
		-- wipe so we can reuse the frame without showing checks (if appropriate)
		clearchecking = self:ScheduleTimer(wipe, 10, readycheck) -- how long to show results?

		wipe(noReply)
		wipe(notReady)
		local members = self.db.profile.readyByGroup and readygroup or readycheck
		for name in next, members do
			local ready = readycheck[name]
			if self.stripservers then -- this is a hook for other addons to enable unambiguous character names
				name = name:gsub("%-.+", "")
			end
			if ready == "waiting" or ready == "offline" then
				noReply[#noReply + 1] = name
			elseif ready == "notready" then
				notReady[#notReady + 1] = name
			end
		end

		local promoted = oRA:IsPromoted()
		local send = self.db.profile.relayReady and promoted and promoted > 1 and IsInRaid() and not IsInGroup(2)
		if #noReply == 0 and #notReady == 0 then
			sysprint(READY_CHECK_ALL_READY)
			if send then
				SendChatMessage(READY_CHECK_ALL_READY, "RAID")
			end
		else
			if #noReply > 0 then
				local playersAway = RAID_MEMBERS_AFK:format(concat(noReply, ", "))
				sysprint(playersAway)
				if send then
					SendChatMessage(playersAway, "RAID")
				end
			end
			if #notReady > 0 then
				local playersNotReady = L.playersNotReady:format(concat(notReady, ", "))
				sysprint(playersNotReady)
				if send then
					SendChatMessage(playersNotReady, "RAID")
				end
			end
		end

		if self.db.profile.showWindow and frame then
			frame.title:SetText(READY_CHECK_FINISHED)
			if self.db.profile.autohide then
				updateWindow()
				frame.animUpdater:Stop()
				frame.animFader:Play()
			end
		end
	end
end

