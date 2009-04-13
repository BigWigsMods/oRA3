--------------------------------------------------------------------------------
-- Setup
--

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Cooldowns", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

--------------------------------------------------------------------------------
-- Locals
--

local _, playerClass = UnitClass("player")
local bloodlustId = UnitFactionGroup("player") == "Alliance" and 32182 or 2825

local spells = {
	DRUID = {
		[26994] = 1200, -- Rebirth
		[29166] = 360, -- Innervate
		[17116] = 180, -- Nature's Swiftness
		[5209] = 180, -- Challenging Roar
	},
	HUNTER = {
		[34477] = 30, -- Misdirect
		[5384] = 30, -- Feign Death
	},
	MAGE = {
		[45438] = 300, -- Iceblock
		[2139] = 24, -- Counterspell
	},
	PALADIN = {
		[19752] = 1200, -- Divine Intervention
		[642] = 300, -- Divine Shield
		[10278] = 300, -- Hand of Protection
		[6940] = 120, -- Hand of Sacrifice
		[498] = 300, -- Divine Protection
		[633] = 1200, -- Lay on Hands
	},
	PRIEST = {
		[33206] = 180, -- Pain Suppression
		[47788] = 180, -- Guardian Spirit
		[6346] = 180, -- Fear Ward
	},
	ROGUE = {
		[31224] = 90, -- Cloak of Shadows
		[38768] = 10, -- Kick
		[1725] = 30, -- Distract
	},
	SHAMAN = {
		[bloodlustId] = 600, -- Bloodlust/Heroism
		[20608] = 3600, -- Reincarnation
		[16190] = 300, -- Mana Tide Totem
		[2894] = 1200, -- Fire Elemental Totem
		[2062] = 1200, -- Earth Elemental Totem
		[16188] = 180, -- Nature's Swiftness
	},
	WARLOCK = {
		[27239] = 1800, -- Soulstone Resurrection
		[29858] = 300, -- Soulshatter
	},
	WARRIOR = {
		[871] = 300, -- Shield Wall
		[12975] = 300, -- Last Stand
		[6554] = 10, -- Pummel
		[1161] = 180, -- Challenging Shout
	},
	DEATHKNIGHT = {
		[42650] = 1200, -- Army of the Dead
		[61999] = 300, -- Raise Ally
		[49028] = 180, -- Dancing Rune Weapon
		[49206] = 180, -- Summon Gargoyle
		[49916] = 120, -- Strangulate
		[49576] = 35, -- Death Grip
		[51271] = 60, -- Unbreakable Armor
	},
}

local allSpells = {}
local classLookup = {}
for class, spells in pairs(spells) do
	for id, cd in pairs(spells) do
		allSpells[id] = cd
		classLookup[id] = class
	end
end

local classes = {}
do
	local hexColors = {}
	for k, v in pairs(RAID_CLASS_COLORS) do
		hexColors[k] = "|cff" .. string.format("%02x%02x%02x", v.r * 255, v.g * 255, v.b * 255)
	end
	for class in pairs(spells) do
		classes[class] = hexColors[class] .. L[class] .. "|r"
	end
	wipe(hexColors)
	hexColors = nil
end

local db = nil
local cdModifiers = {}
local broadcastSpells = {}

--------------------------------------------------------------------------------
-- GUI
--

local function onControlEnter(widget, event, value)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
	GameTooltip:AddLine(widget.text and widget.text:GetText() or widget.label:GetText())
	GameTooltip:AddLine(widget:GetUserData("tooltip"), 1, 1, 1, 1)
	GameTooltip:Show()
end
local function onControlLeave() GameTooltip:Hide() end

local showPane, hidePane
do
	local frame = nil
	local tmp = {}
	local group = nil

	local function spellCheckboxCallback(widget, event, value)
		local id = widget:GetUserData("id")
		if not id then return end
		db.spells[id] = value and true or nil
		--widget:SetValue(value)
	end

	local function dropdownGroupCallback(widget, event, key)
		widget:PauseLayout()
		widget:ReleaseChildren()
		wipe(tmp)
		if spells[key] then
			-- Class spells
			for id in pairs(spells[key]) do
				table.insert(tmp, id)
			end
			table.sort(tmp) -- ZZZ Sorted by spell ID, oh well!
			for i, v in ipairs(tmp) do
				local name = GetSpellInfo(v)
				local checkbox = AceGUI:Create("CheckBox")
				checkbox:SetLabel(name)
				checkbox:SetValue(db.spells[v] and true or false)
				checkbox:SetUserData("id", v)
				checkbox:SetCallback("OnValueChanged", spellCheckboxCallback)
				checkbox:SetFullWidth(true)
				widget:AddChild(checkbox)
			end
		end
		widget:ResumeLayout()
		-- DoLayout the parent to update the scroll bar for the new height of the dropdowngroup
		frame:DoLayout()
	end

	local function showCallback(widget, event, value)
		db.showCooldowns = value and true or nil
	end
	local function onlyMineCallback(widget, event, value)
		db.onlyShowMine = value and true or nil
	end

	local function createFrame()
		if frame then return end
		frame = AceGUI:Create("ScrollFrame")
		frame:PauseLayout() -- pause here to stop excessive DoLayout invocations

		local show = AceGUI:Create("CheckBox")
		show:SetLabel("Show cooldown monitor")
		show:SetValue(db.showCooldowns)
		show:SetCallback("OnEnter", onControlEnter)
		show:SetCallback("OnLeave", onControlLeave)
		show:SetCallback("OnValueChanged", showCallback)
		show:SetUserData("tooltip", "Show or hide the cooldown bar display in the game world.")
		show:SetFullWidth(true)

		local only = AceGUI:Create("CheckBox")
		only:SetLabel("Only show my own spells")
		only:SetValue(db.onlyShowMine)
		only:SetCallback("OnEnter", onControlEnter)
		only:SetCallback("OnLeave", onControlLeave)
		only:SetCallback("OnValueChanged", onlyMineCallback)
		only:SetUserData("tooltip", "Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon.")
		only:SetFullWidth(true)

		local moduleDescription = AceGUI:Create("Label")
		moduleDescription:SetText(L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."])
		moduleDescription:SetFullWidth(true)
		moduleDescription:SetFontObject(GameFontHighlight)

		group = AceGUI:Create("DropdownGroup")
		group:SetTitle(L["Select class"])
		group:SetGroupList(classes)
		group:SetCallback("OnGroupSelected", dropdownGroupCallback)
		group.dropdown:SetWidth(120)
		group:SetGroup(playerClass)
		group:SetFullWidth(true)

		frame:AddChildren(show, only, moduleDescription, group)

		-- resume and update layout
		frame:ResumeLayout()
		frame:DoLayout()
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
-- Bar config window
--

local restyleBars
local showBarConfig
do
	local function onTestClick(widget, event)
		module:SpawnTestBar()
	end
	
	local function colorChanged(widget, event, r, g, b)
		db.barColor = {r, g, b, 1}
		if not db.barClassColor then
			restyleBars()
		end
	end
	
	local function toggleChanged(widget, event, value)
		local key = widget:GetUserData("key")
		db[key] = value and true or nil
		restyleBars()
	end
	
	local function heightChanged(widget, event, value)
		db.barHeight = value
		restyleBars()
	end

	local function show()
		local frame = AceGUI:Create("Frame")
		frame:SetTitle("Bar Settings")
		frame:SetStatusText("")
		frame:SetLayout("Flow")
		frame:SetWidth(240)
		frame:SetHeight(260)
		
		local test = AceGUI:Create("Button")
		test:SetText("Spawn test bar")
		test:SetCallback("OnClick", onTestClick)
		test:SetFullWidth(true)
		
		local classColor = AceGUI:Create("CheckBox")
		classColor:SetValue(db.barClassColor)
		classColor:SetLabel("Use class color")
		classColor:SetUserData("key", "barClassColor")
		classColor:SetCallback("OnValueChanged", toggleChanged)
		classColor:SetRelativeWidth(0.5)
		
		local picker = AceGUI:Create("ColorPicker")
		picker:SetLabel("Select bar color")
		picker:SetHasAlpha(false)
		picker:SetCallback("OnValueConfirmed", colorChanged)
		picker:SetRelativeWidth(0.5)
		picker:SetColor(unpack(db.barColor))

		local height = AceGUI:Create("Slider")
		height:SetLabel("Bar height")
		height:SetValue(db.barHeight)
		height:SetSliderValues(8, 32, 1)
		height:SetCallback("OnValueChanged", heightChanged)
		height:SetFullWidth(true)

		local header = AceGUI:Create("Heading")
		header:SetText("Show")
		header:SetFullWidth(true)
		
		local icon = AceGUI:Create("CheckBox")
		icon:SetValue(db.barShowIcon)
		icon:SetLabel("Icon")
		icon:SetUserData("key", "barShowIcon")
		icon:SetCallback("OnValueChanged", toggleChanged)
		icon:SetRelativeWidth(0.5)
		
		local duration = AceGUI:Create("CheckBox")
		duration:SetValue(db.barShowDuration)
		duration:SetLabel("Duration")
		duration:SetUserData("key", "barShowDuration")
		duration:SetCallback("OnValueChanged", toggleChanged)
		duration:SetRelativeWidth(0.5)
		
		local unit = AceGUI:Create("CheckBox")
		unit:SetValue(db.barShowUnit)
		unit:SetLabel("Unit name")
		unit:SetUserData("key", "barShowUnit")
		unit:SetCallback("OnValueChanged", toggleChanged)
		unit:SetRelativeWidth(0.5)
		
		local spell = AceGUI:Create("CheckBox")
		spell:SetValue(db.barShowSpell)
		spell:SetLabel("Spell name")
		spell:SetUserData("key", "barShowSpell")
		spell:SetCallback("OnValueChanged", toggleChanged)
		spell:SetRelativeWidth(0.5)
		
		frame:AddChildren(test, classColor, picker, height, header, icon, duration, unit, spell)
		
		frame:Show()
	end
	showBarConfig = show
end

--------------------------------------------------------------------------------
-- Bar display
--

local startBar, setupCooldownDisplay
do
	local display = nil
	local maximum = 10
	local bars = {}
	local visibleBars = {}
	
	local function restyleBar(bar)
		bar:SetHeight(db.barHeight)
		if db.barShowIcon then
			bar.bar:SetPoint("TOPLEFT", bar.icon, "TOPRIGHT")
			bar.bar:SetPoint("BOTTOMLEFT", bar.icon, "BOTTOMRIGHT")
			bar.icon:SetWidth(db.barHeight)
			bar.icon:Show()
		else
			bar.bar:SetPoint("TOPLEFT", bar)
			bar.bar:SetPoint("BOTTOMLEFT", bar)
			bar.icon:Hide()
		end
		if db.barShowDuration then bar.time:Show()
		else bar.time:Hide() end
		if db.barShowUnit then bar.unit:Show()
		else bar.unit:Hide() end
		if db.barShowSpell then bar.label:Show()
		else bar.label:Hide() end
		if db.barClassColor then
			local c = RAID_CLASS_COLORS[bar.unitclass]
			bar.bar:SetStatusBarColor(c.r, c.g, c.b, 1)
		else
			bar.bar:SetStatusBarColor(unpack(db.barColor))
		end
	end
	
	function restyleBars()
		for bar in pairs(visibleBars) do
			restyleBar(bar)
		end
	end
	
	local function barSorter(a, b)
		return a.remaining < b.remaining and true or false
	end
	local tmp = {}
	local function rearrangeBars()
		wipe(tmp)
		for bar in pairs(visibleBars) do
			table.insert(tmp, bar)
		end
		table.sort(tmp, barSorter)
		local lastBar = nil
		for i, bar in ipairs(tmp) do
			if i <= maximum then
				if not lastBar then
					bar:SetPoint("TOPLEFT", display, "TOPLEFT", 4, -4)
					bar:SetPoint("TOPRIGHT", display, "TOPRIGHT", -4, -4)
				else
					bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT", 0, 0)
					bar:SetPoint("TOPRIGHT", lastBar, "BOTTOMRIGHT", 0, 0)
				end
				lastBar = bar
				bar:Show()
			else
				bar:Hide()
			end
		end
	end

	local function OnDragHandleMouseDown(self) self.frame:StartSizing("BOTTOMRIGHT") end
	local function OnDragHandleMouseUp(self, button) self.frame:StopMovingOrSizing() end
	local function onResize(self, width, height)
		db.width = width
		db.height = height
		maximum = math.floor(height / db.barHeight)
		-- if we have that many bars shown, hide the ones that overflow
		rearrangeBars()
	end
	
	local function displayOnMouseDown(self, button)
		if button == "RightButton" then
			showBarConfig()
		end
	end
	
	local function setup()
		display = CreateFrame("Frame", "oRA3CooldownFrame", UIParent)
		display:SetWidth(db.width)
		display:SetHeight(db.height)
		display:EnableMouse()
		display:SetMovable(true)
		display:SetResizable(true)
		display:SetMinResize(100, 20)
		display:RegisterForDrag("LeftButton")
		display:SetScript("OnSizeChanged", onResize)
		display:SetScript("OnDragStart", function(self) self:StartMoving() end)
		display:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			local s = display:GetEffectiveScale()
			db.x = display:GetLeft() * s
			db.y = display:GetTop() * s
		end)
		display:SetScript("OnMouseDown", displayOnMouseDown)
		if db.x and db.y then
			local s = display:GetEffectiveScale()
			display:ClearAllPoints()
			display:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.x / s, db.y / s)
		else
			display:SetPoint("LEFT", UIParent, "LEFT", 200, 0)
		end
		local bg = display:CreateTexture(nil, "PARENT")
		bg:SetAllPoints(display)
		bg:SetBlendMode("BLEND")
		bg:SetTexture(0, 0, 0, 0.3)
		local header = display:CreateFontString(nil, "OVERLAY")
		header:SetFontObject(GameFontNormal)
		header:SetText("Cooldowns")
		header:SetPoint("BOTTOM", display, "TOP", 0, 4)

		local drag = CreateFrame("Frame", nil, display)
		drag.frame = display
		drag:SetFrameLevel(display:GetFrameLevel() + 10) -- place this above everything
		drag:SetWidth(16)
		drag:SetHeight(16)
		drag:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -1, 1)
		drag:EnableMouse(true)
		drag:SetScript("OnMouseDown", OnDragHandleMouseDown)
		drag:SetScript("OnMouseUp", OnDragHandleMouseUp)
		drag:SetAlpha(0.5)
		display.drag = drag

		local tex = drag:CreateTexture(nil, "BACKGROUND")
		tex:SetTexture("Interface\\AddOns\\oRA3\\media\\draghandle")
		tex:SetWidth(16)
		tex:SetHeight(16)
		tex:SetBlendMode("ADD")
		tex:SetPoint("CENTER", drag, "CENTER", 0, 0)

		display:Show()
	end
	setupCooldownDisplay = setup

	local counter = 1
	local function getBar()
		local bar = next(bars)
		if bar then
			bars[bar] = nil
			return bar
		end
		local frame = CreateFrame("Frame", "oRA3CooldownBar_" .. counter, display)
		counter = counter + 1
		frame:SetScale(1)
		frame:SetMovable(1)
		frame:Hide()

		local icon = frame:CreateTexture(nil, "BACKGROUND")
		icon:SetPoint("TOPLEFT", frame)
		icon:SetPoint("BOTTOMLEFT", frame)
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		frame.icon = icon

		local statusbar = CreateFrame("StatusBar", nil, frame)
		statusbar:SetPoint("TOPRIGHT", frame)
		statusbar:SetPoint("BOTTOMRIGHT", frame)
		statusbar:SetStatusBarTexture("Interface\\AddOns\\oRA3\\media\\statusbar")
		frame.bar = statusbar

		local bg = statusbar:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetTexture("Interface\\AddOns\\oRA3\\media\\statusbar")
		bg:SetVertexColor(0.5, 0.5, 0.5, 0.3)

		local time = statusbar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallOutline")
		time:SetPoint("RIGHT", statusbar, -2, 0)
		frame.time = time

		local unit = statusbar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallOutline")
		unit:SetPoint("LEFT", statusbar, 2, 0)
		frame.unit = unit

		local name = statusbar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallOutline")
		name:SetAllPoints(frame)
		name:SetJustifyH("CENTER")
		name:SetJustifyV("MIDDLE")
		frame.label = name

		return frame
	end

	local function stop(bar)
		bar:SetScript("OnUpdate", nil)
		bars[bar] = true
		visibleBars[bar] = nil
		bar:Hide()
		rearrangeBars()
	end

	local function onUpdate(self, elapsed)
		--[[self.total = self.total + elapsed
		if self.total < 0.2 then return end
		self.total = 0]] -- Throttle updates a bit perhaps?
		-- We just need to make sure that the throttle is small enough
		-- so the bars don't jitter.
		local t = GetTime()
		if t >= self.exp then
			stop(self)
		else
			local time = self.exp - t
			self.remaining = time
			self.bar:SetValue(time)
			self.time:SetFormattedText(SecondsToTimeAbbrev(time))
		end
	end

	local function start(unit, id, name, icon, duration)
		local bar = getBar()
		bar.unitclass = classLookup[id]
		bar.icon:SetTexture(icon)
		bar.bar:SetMinMaxValues(0, duration)
		bar.unit:SetText(unit)
		bar.label:SetText(name)
		bar.exp = GetTime() + duration
		bar.remaining = duration
		restyleBar(bar)
		visibleBars[bar] = true
		bar:SetScript("OnUpdate", onUpdate)
		rearrangeBars()
		bar:Show()
	end
	startBar = start
end

--------------------------------------------------------------------------------
-- Module
--

function module:OnRegister()
	local database = oRA.db:RegisterNamespace("Cooldowns", {
		profile = {
			spells = {
				[26994] = true,
				[19752] = true,
				[20608] = true,
				[27239] = true,
			},
			showCooldowns = true,
			onlyShowMine = nil,
			width = 200,
			height = 148,
			--
			barHeight = 14,
			barShowIcon = true,
			barShowDuration = true,
			barShowUnit = true,
			barShowSpell = true,
			barClassColor = true,
			barColor = { 0.25, 0.33, 0.68, 1 },
		},
	})
	db = database.profile

	oRA:RegisterPanel(
		L["Cooldowns"],
		showPane,
		hidePane
	)

	-- These are the spells we broadcast to the raid
	for spell, cd in pairs(spells[playerClass]) do
		broadcastSpells[GetSpellInfo(spell)] = spell
	end
	
	setupCooldownDisplay()
end

do
	local spellList = {}
	for k in pairs(allSpells) do table.insert(spellList, k) end
	local reverseClass = {}
	for name, class in pairs(oRA._testUnits) do reverseClass[class] = name end
	function module:SpawnTestBar()
		local spell = spellList[math.random(1, #spellList)]
		local unit = reverseClass[classLookup[spell]]
		local name, _, icon = GetSpellInfo(spell)
		local duration = (allSpells[spell] / 30) + math.random(1, 120)
		startBar(unit, spell, name, icon, duration)
	end
end

function module:OnEnable()
	oRA.RegisterCallback(self, "OnCommCooldown")
	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
end

function module:OnDisable()
	oRA.UnregisterCallback(self, "OnCommCooldown")
	oRA.UnregisterCallback(self, "OnStartup")
	oRA.UnregisterCallback(self, "OnShutdown")
end

local function getCooldown(spellId)
	local cd = spells[playerClass][spellId]
	if cdModifiers[spellId] then
		cd = cd - cdModifiers[spellId]
	end
	return cd
end

function module:OnStartup()
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	if playerClass == "SHAMAN" then
		local resTime = GetTime()
		local ankhs = GetItemCount(17030)
		self:RegisterEvent("PLAYER_ALIVE", function()
			resTime = GetTime()
		end)
		self:RegisterEvent("BAG_UPDATE", function()
			if (GetTime() - (resTime or 0)) > 1 then return end
			local newankhs = GetItemCount(17030)
			if newankhs == (ankhs - 1) then
				oRA:SendComm("Cooldown", 20608, getCooldown(20608)) -- Spell ID + CD in seconds
			end
			ankhs = newankhs
		end)
	end

	self:CHARACTER_POINTS_CHANGED()
end

function module:OnShutdown()
	self:UnregisterAllEvents()
end

function module:OnCommCooldown(commType, sender, spell, cd)
	print("We got a cooldown for " .. tostring(spell) .. " (" .. tostring(cd) .. ") from " .. tostring(sender))
	if type(spell) ~= "number" or type(cd) ~= "number" then error("Spell or number had the wrong type.") end
	if not db.spells[spell] then return end
	local name, _, icon = GetSpellInfo(spell)
	if not icon then return end
	startBar(sender, spell, name, icon, cd)
end

function module:CHARACTER_POINTS_CHANGED()
	if playerClass == "PALADIN" then
		local _, _, _, _, rank = GetTalentInfo(2, 5)
		cdModifiers[10278] = rank * 60
	elseif playerClass == "SHAMAN" then
		local _, _, _, _, rank = GetTalentInfo(3, 3)
		cdModifiers[20608] = rank * 600
	elseif playerClass == "WARRIOR" then
		local _, _, _, _, rank = GetTalentInfo(3, 13)
		cdModifiers[871] = rank * 30
	end
end

function module:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell)
	if unit ~= "player" then return end
	if broadcastSpells[spell] then
		local spellId = broadcastSpells[spell]
		oRA:SendComm("Cooldown", spellId, getCooldown(spellId)) -- Spell ID + CD in seconds
	end
end

