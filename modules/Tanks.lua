
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	return
end

local addonName, scope = ...
local oRA = scope.addon
local util = oRA.util
local module = oRA:NewModule("Tanks")
local L = scope.locale

-- luacheck: globals READY_CHECK_READY_TEXTURE FauxScrollFrame_Update
-- luacheck: globals FauxScrollFrame_OnVerticalScroll FauxScrollFrame_GetOffset

local frame = nil
local indexedTanks = {} -- table containing the final tank list
local namedTanks = {} -- table containing current active tanks by name
local tmpTanks = {} -- temp tank table reused
local namedPersistent = {} -- table containing named persistent list filled from db.persistentTanks
local allIndexedTanks = {} -- table containing the top scroll sorted list of indexed tanks
local sessionTanks = {} -- Tanks you pushed to the top for this session
local namedHidden = {} -- Named hidden tanks for this session
local deletedTanks = {}

-- Lists containing the scrolling rows of tanks in the GUI
local top = {}
local bottom = {}

local function showConfig()
	if not frame then module:CreateFrame() end
	oRA:SetAllPointsToPanel(frame)
	frame:Show()
	module:UpdateScrolls()
end

local function hideConfig()
	if frame then
		frame:Hide()
	end
end

function module:OnRegister()
	local database = oRA.db:RegisterNamespace("Tanks", {
		factionrealm = {
			persistentTanks = {},
		},
	})
	self.db = database.factionrealm
	oRA:RegisterPanel(
		L.tanks,
		showConfig,
		hideConfig
	)
	for k, tank in next, self.db.persistentTanks do
		namedPersistent[tank] = true
		sessionTanks[tank] = true
		allIndexedTanks[#allIndexedTanks + 1] = tank
	end
	oRA.RegisterCallback(self, "OnTanksChanged")
	oRA.RegisterCallback(self, "OnGroupChanged")
	oRA.RegisterCallback(self, "OnPromoted")
	oRA.RegisterCallback(self, "OnDemoted")
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED", "CheckRoleAssignments")
end

local function sortTanks()
	wipe(indexedTanks)
	for k, tank in next, allIndexedTanks do
		if namedTanks[tank] and not namedHidden[tank] then
			indexedTanks[#indexedTanks + 1] = tank
		end
	end
	if IsInRaid() then
		oRA.callbacks:Fire("OnTanksUpdated", indexedTanks)
	end
end

function module:OnPromoted(event, status)
	if not frame then return end
	for k, v in next, top do
		v.tank:Enable()
		if v.stank and not InCombatLockdown() then
			v.stank:Enable()
		end
	end
end

function module:OnDemoted(event)
	if not frame then return end
	for k, v in next, top do
		v.tank:Disable()
		if v.stank and not InCombatLockdown() then
			v.stank:Disable()
		end
	end
end

function module:OnGroupChanged(event, status, members, updateSort)
	if IsInRaid() then
		wipe(tmpTanks)
		for tank, v in pairs(namedTanks) do
			tmpTanks[tank] = v
		end
		for k, tank in next, members do
			-- mix in the persistentTanks
			if namedPersistent[tank] and not namedTanks[tank] then
				updateSort = true
				namedTanks[tank] = true
			end
			tmpTanks[tank] = nil
		end
		-- remove obsolete tanks
		for tank, v in pairs(tmpTanks) do -- remove members nolonger in the group
			updateSort = true
			namedTanks[tank] = nil
		end
		if updateSort then
			sortTanks()
		end
		if frame and frame:IsVisible() then
			self:UpdateScrolls()
		end
	end
end

function module:OnTanksChanged(event, tanks, updateSort)
	wipe(tmpTanks)
	for tank, v in pairs(namedTanks) do
		tmpTanks[tank] = v
	end
	for k, tank in next, tanks do
		if not namedTanks[tank] then
			allIndexedTanks[#allIndexedTanks + 1] = tank
			updateSort = true
			namedTanks[tank] = true
		end
		tmpTanks[tank] = nil
	end
	for tank, v in pairs(tmpTanks) do
		-- remove any leftover tanks that are not persistent or set for the session
		if not namedPersistent[tank] and not sessionTanks[tank] then
			for kk, vv in next, allIndexedTanks do
				if vv == tank then
					table.remove(allIndexedTanks, kk)
					break
				end
			end
			updateSort = true
			namedTanks[tank] = nil
		end
	end
	if updateSort then
		sortTanks()
	end
	if frame and frame:IsVisible() then
		self:UpdateScrolls()
	end
end

function module:CheckRoleAssignments()
	if IsInRaid() then
		local updateSort = false
		local members = oRA:GetGroupMembers()
		for k,member in next, members do
			local tank = GetPartyAssignment("MAINTANK", member)
			--[[ IF requested at a later to auto-remove non tank role from tank list this can accomplish that.
			if role ~= "TANK" and util.inTable(allIndexedTanks, member) then
				for k, v in next, allIndexedTanks do
					if v == member and not namedPersistent[member] then
						table.remove(allIndexedTanks, k)
					end
				end
				if not namedPersistent[member] then
					sessionTanks[member] = nil
					namedTanks[member] = nil
					updateSort = true
				end
			end
			--]]
			if tank and not deletedTanks[member] and not util.inTable(allIndexedTanks, member) then
				allIndexedTanks[#allIndexedTanks + 1] = member
				sessionTanks[member] = true
				namedTanks[member] = true
				updateSort = true
			end
		end
		if updateSort then
			module:OnGroupChanged("OnGroupChanged", nil, oRA:GetGroupMembers())
			module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks(), true)
			module:UpdateScrolls()
		end
	end
end


local function OnEnter(self)
	if not oRA.db.profile.showHelpTexts then return end
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:AddLine(self.tooltipTitle)
	GameTooltip:AddLine(self.tooltipText, 1, 1, 1, 1)
	GameTooltip:Show()
end
local function OnLeave(self)
	GameTooltip:Hide()
end

local function createButton(parent, template)
	local button = CreateFrame("Button", nil, parent, template)
	button:SetWidth(16)
	button:SetHeight(16)
	button:SetScript("OnLeave", OnLeave)
	button:SetScript("OnEnter", OnEnter)
	button:SetHighlightTexture(131128) --"Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar"

	local image = button:CreateTexture(nil, "BACKGROUND")
	button.icon = image
	image:SetAllPoints(button)
	return button
end

local function topScrollDeleteClick(self)
	local value = self:GetParent().unitName
	local btanks = oRA:GetBlizzardTanks()
	if util.inTable(btanks, value) then return end
	-- remove from persistent if in there
	for k, v in next, module.db.persistentTanks do
		if v == value then
			table.remove(module.db.persistentTanks, k)
			break
		end
	end
	namedPersistent[value] = nil
	-- remove from the list
	for k, v in next, allIndexedTanks do
		if v == value then
			table.remove(allIndexedTanks, k)
		end
	end
	sessionTanks[value] = nil
	deletedTanks[value] = true
	PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
	-- update
	module:OnGroupChanged("OnGroupChanged", nil, oRA:GetGroupMembers())
	module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks())
end

local function topScrollHiddenClick(self)
	local value = self:GetParent().unitName
	if namedHidden[value] then
		namedHidden[value] = nil
		PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
	else
		namedHidden[value] = true
		PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
	end
	module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks(), true)
end

local function topScrollSaveClick(self)
	local value = self:GetParent().unitName
	local k = util.inTable(module.db.persistentTanks, value)
	if k then
		PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
		table.remove(module.db.persistentTanks, k)
		namedPersistent[value] = nil
	else
		PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
		namedPersistent[value] = true
		wipe(module.db.persistentTanks)
		for _, v in next, allIndexedTanks do
			if namedPersistent[v] then
				module.db.persistentTanks[#module.db.persistentTanks + 1] = v
			end
		end
	end
	module:OnGroupChanged("OnGroupChanged", nil, oRA:GetGroupMembers())
	module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks())
end

local function topScrollUpClick(self)
	local k = util.inTable(allIndexedTanks, self.unitName)
	local temp = allIndexedTanks[k]
	if k == 1 then
		allIndexedTanks[k] = allIndexedTanks[#allIndexedTanks]
		allIndexedTanks[#allIndexedTanks] = temp
	else
		allIndexedTanks[k] = allIndexedTanks[k - 1]
		allIndexedTanks[k - 1] = temp
	end
	wipe(module.db.persistentTanks)
	for _, v in next, allIndexedTanks do
		if namedPersistent[v] then
			module.db.persistentTanks[#module.db.persistentTanks + 1] = v
		end
	end
	PlaySound(1115) -- SOUNDKIT.U_CHAT_SCROLL_BUTTON
	module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks(), true)
end

local function bottomScrollClick(self)
	local value = self.unitName
	if util.inTable(allIndexedTanks, value) then return true end
	allIndexedTanks[#allIndexedTanks + 1] = value
	sessionTanks[value] = true
	namedTanks[value] = true
	deletedTanks[value]= nil
	PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
	module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks(), true)
	module:UpdateScrolls()
end

function module:CreateFrame()
	frame = CreateFrame("Frame")

	local centerBar = CreateFrame("Button", nil, frame)
	centerBar:SetPoint("BOTTOMLEFT", frame, -5, 139)
	centerBar:SetPoint("BOTTOMRIGHT", frame, 5, 139)
	centerBar:SetHeight(8)

	local texture = centerBar:CreateTexture(nil, "BORDER")
	texture:SetTexture(130968) --"Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar"
	texture:SetAllPoints(centerBar)
	texture:SetTexCoord(0.29296875, 1, 0, 0.25)

	local topBar = nil
	if oRA.db.profile.showHelpTexts then
		topBar = CreateFrame("Button", nil, frame)
		topBar:SetPoint("TOPLEFT", frame, -5, -42)
		topBar:SetPoint("TOPRIGHT", frame, 5, -42)
		topBar:SetHeight(8)
		texture = topBar:CreateTexture(nil, "BORDER")
		texture:SetTexture(130968) --"Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar"
		texture:SetAllPoints(topBar)
		texture:SetTexCoord(0.29296875, 1, 0, 0.25)
	end

	frame.topscroll = CreateFrame("ScrollFrame", "oRA3TankTopScrollFrame", frame, "FauxScrollFrameTemplate")
	if oRA.db.profile.showHelpTexts then
		frame.topscroll:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 4, 2)
	else
		frame.topscroll:SetPoint("TOPLEFT", frame, -5, -4)
	end
	frame.topscroll:SetPoint("BOTTOMRIGHT", centerBar, "TOPRIGHT", -25, -2)

	frame.bottomscroll = CreateFrame("ScrollFrame", "oRA3TankBottomScrollFrame", frame, "FauxScrollFrameTemplate")
	frame.bottomscroll:SetPoint("TOPLEFT", centerBar, "BOTTOMLEFT", 4, 2)
	frame.bottomscroll:SetPoint("BOTTOMRIGHT", frame, -20, 0)

	if oRA.db.profile.showHelpTexts then
		local help = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		help:SetJustifyH("LEFT")
		help:SetPoint("TOPLEFT")
		help:SetPoint("BOTTOMRIGHT", topBar, "TOPRIGHT", -32, 0)
		help:SetText(L.tankTabTopText)

		local helpButton = createButton(frame)
		helpButton:SetWidth(24)
		helpButton:SetHeight(24)
		helpButton:SetPoint("TOPRIGHT", -4, -8)
		helpButton.icon:SetTexture(132048) --"Interface\\GossipFrame\\ActiveQuestIcon"
		helpButton.tooltipTitle = L.whatIsThis
		helpButton.tooltipText = L.tankHelp
	end

	-- 10 top
	-- 9 bottom
	for i = 1, 10 do
		local t = CreateFrame("Button", nil, frame)
		t:SetHeight(16)
		t:SetHighlightTexture(131128) --"Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar"
		t:SetScript("OnClick", topScrollUpClick)
		t:SetScript("OnLeave", OnLeave)
		t:SetScript("OnEnter", OnEnter)
		t.tooltipTitle = L.sort
		t.tooltipText = L.moveTankUp

		if i == 1 then
			t:SetPoint("TOPLEFT", frame.topscroll)
			t:SetPoint("TOPRIGHT", frame.topscroll)
		else
			t:SetPoint("TOPLEFT", top[i - 1], "BOTTOMLEFT")
			t:SetPoint("TOPRIGHT", top[i - 1], "BOTTOMRIGHT")
		end

		local hidden = CreateFrame("CheckButton", "oRA3TankHideButton"..i, t, "UICheckButtonTemplate")
		hidden:SetPoint("TOPLEFT", t)
		hidden:SetWidth(16)
		hidden:SetHeight(16)
		hidden:SetScript("OnLeave", OnLeave)
		hidden:SetScript("OnEnter", OnEnter)
		hidden:SetScript("OnClick", topScrollHiddenClick)
		hidden.tooltipTitle = L.Show
		hidden.tooltipText = L.showButtonHelp
		t.hidden = hidden

		local name = oRA:CreateScrollEntry(t)
		name:SetPoint("TOPLEFT", hidden, "TOPRIGHT", 4, 0)
		name:SetText(L.name)
		t.label = name

		local delete = createButton(t)
		delete:SetPoint("TOPRIGHT", t)
		delete.icon:SetTexture(136813) --"Interface\\RaidFrame\\ReadyCheck-NotReady"
		delete:SetScript("OnClick", topScrollDeleteClick)
		delete.tooltipTitle = L.Remove
		delete.tooltipText = L.deleteButtonHelp
		t.delete = delete

		local tank = createButton(t)
		tank:SetPoint("TOPRIGHT", delete, "TOPLEFT", -2, 0)
		tank.icon:SetTexture("Interface\\AddOns\\oRA3\\media\\maintank")
		if oRA:IsPromoted() then
			tank:Enable()
		else
			tank:Disable()
		end
		tank.tooltipTitle = L.blizzMainTank
		tank.tooltipText = L.tankButtonHelp
		t.tank = tank

		if not InCombatLockdown() then
			local stank = createButton(t, "SecureActionButtonTemplate")
			stank:SetPoint("TOPRIGHT", delete, "TOPLEFT", -2, 0)
			stank.icon:SetTexture("Interface\\AddOns\\oRA3\\media\\maintank")
			stank:SetAttribute("type", "maintank")
			stank:SetAttribute("action", "toggle")
			if oRA:IsPromoted() then
				stank:Enable()
			else
				stank:Disable()
			end
			stank.tooltipTitle = L.blizzMainTank
			stank.tooltipText = L.tankButtonHelp
			t.stank = stank
			t.tank:Hide()
		end

		local save = createButton(t)
		save:SetPoint("TOPRIGHT", tank, "TOPLEFT", -2, 0)
		save.icon:SetTexture(136814) -- "Interface\\RaidFrame\\ReadyCheck-Ready"
		save:SetScript("OnClick", topScrollSaveClick)
		save.tooltipTitle = L.Save
		save.tooltipText = L.saveButtonHelp
		t.save = save

		top[i] = t
	end

	for i = 1, 9 do
		local b = CreateFrame("Button", nil, frame)
		b:SetHeight(16)
		b:SetHighlightTexture(131128) --"Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar"
		b:SetScript("OnClick", bottomScrollClick)
		if i == 1 then
			b:SetPoint("TOPLEFT", frame.bottomscroll, 0, 1)
			b:SetPoint("TOPRIGHT", frame.bottomscroll, 0, 1)
		else
			b:SetPoint("TOPLEFT", bottom[i - 1], "BOTTOMLEFT")
			b:SetPoint("TOPRIGHT", bottom[i - 1], "BOTTOMRIGHT")
		end
		local name = oRA:CreateScrollEntry(b)
		name:SetPoint("TOPLEFT", b)
		name:SetPoint("BOTTOMRIGHT", b)
		name:SetText(L.name)
		b.label = name
		b.unitName = L.name
		bottom[i] = b
	end

	local function updTopScroll() module:UpdateTopScroll() end
	local function updBottomScroll() module:UpdateBottomScroll() end
	frame.topscroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 16, updTopScroll)
	end)
	frame.bottomscroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 16, updBottomScroll)
	end)
	self.CreateFrame = nil
end

function module:UpdateScrolls()
	self:UpdateTopScroll()
	self:UpdateBottomScroll()
end

function module:UpdateTopScroll()
	if not frame then return end
	local nr = #allIndexedTanks
	local btanks = oRA:GetBlizzardTanks()
	FauxScrollFrame_Update(frame.topscroll, nr, 10, 16, nil, nil, nil, nil, nil, nil, true)
	for i, v in next, top do
		local j = i + FauxScrollFrame_GetOffset(frame.topscroll)
		if j <= nr then
			local name = allIndexedTanks[j]
			if util.inTable(btanks, name) then
				v.tank:SetAlpha(1)
				if v.stank then v.stank:SetAlpha(1) end
				v.delete:SetAlpha(.3)
				v.delete:Disable()
			else
				v.tank:SetAlpha(.3)
				if v.stank then v.stank:SetAlpha(.3) end
				v.delete:SetAlpha(1)
				v.delete:Enable()
			end
			if namedPersistent[name] then
				v.save:SetAlpha(1)
			else
				v.save:SetAlpha(.3)
			end
			v.hidden:SetChecked(not namedHidden[name])
			v.unitName = name
			if not InCombatLockdown() and v.stank then
				v.stank:SetAttribute("unit", name)
			end
			v.label:SetText(oRA.coloredNames[name])
			v:Show()
		else
			v:Hide()
		end
	end
end

function module:PLAYER_REGEN_ENABLED()
	if not frame then return end

	for i = 1, 10 do
		top[i].tank:Hide()
		if not top[i].stank then
			local stank = createButton(top[i], "SecureActionButtonTemplate")
			stank:SetPoint("TOPRIGHT", top[i].delete, "TOPLEFT", -2, 0)
			stank.icon:SetTexture("Interface\\AddOns\\oRA3\\media\\maintank")
			stank:SetAttribute("type", "maintank")
			stank:SetAttribute("action", "toggle")
			stank.tooltipTitle = L.blizzMainTank
			stank.tooltipText = L.tankButtonHelp
			top[i].stank = stank
		end
		-- reattach to the frame
		top[i].stank:SetParent(top[i])
		top[i].stank:SetPoint("TOPRIGHT", top[i].delete, "TOPLEFT", -2, 0)
		top[i].stank:Show()
		if oRA:IsPromoted() then
			top[i].stank:Enable()
		else
			top[i].stank:Disable()
		end
	end
	if frame:IsShown() then self:UpdateTopScroll() end
end

function module:PLAYER_REGEN_DISABLED()
	if not frame then return end

	for i = 1, 10 do
		top[i].stank:SetParent(UIParent)
		top[i].stank:ClearAllPoints() -- detach from the frame to prevent taint
		top[i].stank:Hide()
		top[i].tank:Show()
	end
end

do
	local order = {
		WARRIOR = 1,
		PALADIN = 2,
		DRUID = 3,
		DEATHKNIGHT = 4,
		MONK = 5,
		DEMONHUNTER = 6,
		WARLOCK = 7,
		HUNTER = 8,
		ROGUE = 9,
		MAGE = 10,
		PRIEST = 11,
		SHAMAN = 12,
	}
	local function sort(a, b)
		local _, aC = UnitClass(a)
		local _, bC = UnitClass(b)
		return (order[bC] or 0) > (order[aC] or 0)
	end

	local ngroup = {}

	function module:UpdateBottomScroll()
		if not frame then return end
		local group = oRA:GetGroupMembers()
		wipe(ngroup)
		for	k, v in pairs(group) do
			if not namedTanks[v] then -- only add not in the tanklist
				ngroup[#ngroup + 1] = v
			end
		end
		table.sort(ngroup, sort)
		local nr = #ngroup
		FauxScrollFrame_Update(frame.bottomscroll, nr, 9, 16, nil, nil, nil, nil, nil, nil, true)
		for i, v in next, bottom do
			local j = i + FauxScrollFrame_GetOffset(frame.bottomscroll)
			if j <= nr then
				v.unitName = ngroup[j]
				v.label:SetText(oRA.coloredNames[ngroup[j]])
				v:Show()
			else
				v:Hide()
			end
		end
	end
end

function oRA:GetSortedTanks()
	return indexedTanks
end
