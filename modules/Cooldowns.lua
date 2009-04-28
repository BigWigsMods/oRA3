--------------------------------------------------------------------------------
-- Setup
--

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Cooldowns", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")
local candy = LibStub("LibCandyBar-3.0")

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
		[62757] = 1800, -- Call Stabled Pet
	},
	MAGE = {
		[45438] = 300, -- Iceblock
		[2139] = 24, -- Counterspell
		[31687] = 180, -- Summon Water Elemental
		[12051] = 240, -- Evocation
	},
	PALADIN = {
		[19752] = 1200, -- Divine Intervention
		[642] = 300, -- Divine Shield
		[64205] = 120, -- Divine Sacrifice
		[498] = 180, -- Divine Protection
		[10278] = 300, -- Hand of Protection
		[6940] = 120, -- Hand of Sacrifice
		[633] = 1200, -- Lay on Hands
	},
	PRIEST = {
		[33206] = 180, -- Pain Suppression
		[47788] = 180, -- Guardian Spirit
		[6346] = 180, -- Fear Ward
		[64843] = 600, -- Divine Hymn
		[64901] = 360, -- Hymn of Hope
		[34433] = 300, -- Shadowfiend
		[10060] = 120, -- Power Infusion
		[47585] = 180, -- Dispersion
	},
	ROGUE = {
		[31224] = 90, -- Cloak of Shadows
		[38768] = 10, -- Kick
		[1725] = 30, -- Distract
		[13750] = 180, -- Adrenaline Rush
		[13877] = 120, -- Blade Flurry
		[14177] = 180, -- Cold Blood
		[11305] = 180, -- Sprint
		[26889] = 180, -- Vanish
	},
	SHAMAN = {
		[bloodlustId] = 300, -- Bloodlust/Heroism
		[20608] = 3600, -- Reincarnation
		[16190] = 300, -- Mana Tide Totem
		[2894] = 1200, -- Fire Elemental Totem
		[2062] = 1200, -- Earth Elemental Totem
		[16188] = 180, -- Nature's Swiftness
	},
	WARLOCK = {
		[27239] = 1800, -- Soulstone Resurrection
		[29858] = 300, -- Soulshatter
		[47241] = 180, -- Metamorphosis
		[18708] = 900, -- Fel Domination
		[698] = 120, -- Ritual of Summoning
		[58887] = 300, -- Ritual of Souls
	},
	WARRIOR = {
		[871] = 300, -- Shield Wall
		[1719] = 300, -- Recklessness
		[20230] = 300, -- Retaliation
		[12975] = 180, -- Last Stand
		[6554] = 10, -- Pummel
		[1161] = 180, -- Challenging Shout
		[5246] = 180, -- Intimidating Shout
		[64380] = 300, -- Shattering Throw (could be 64382)
		[55694] = 180, -- Enraged Regeneration
	},
	DEATHKNIGHT = {
		[42650] = 1200, -- Army of the Dead
		[61999] = 900, -- Raise Ally
		[49028] = 90, -- Dancing Rune Weapon
		[49206] = 180, -- Summon Gargoyle
		[47476] = 120, -- Strangulate
		[49576] = 35, -- Death Grip
		[51271] = 120, -- Unbreakable Armor
		[55233] = 120, -- Vampiric Blood
		[49222] = 120, -- Bone Shield
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

local lockDisplay, unlockDisplay, isDisplayLocked, showDisplay, hideDisplay, isDisplayShown
local showPane, hidePane
do
	local frame = nil
	local tmp = {}
	local group = nil

	local function spellCheckboxCallback(widget, event, value)
		local id = widget:GetUserData("id")
		if not id then return end
		db.spells[id] = value and true or nil
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
				if not name then break end
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
		db.showDisplay = value
		if value then
			showDisplay()
		else
			hideDisplay()
		end
	end
	local function onlyMineCallback(widget, event, value)
		db.onlyShowMine = value
	end
	local function lockCallback(widget, event, value)
		db.lockDisplay = value
		if value then
			lockDisplay()
		else
			unlockDisplay()
		end
	end

	local function createFrame()
		if frame then return end
		frame = AceGUI:Create("ScrollFrame")
		frame:PauseLayout() -- pause here to stop excessive DoLayout invocations

		local monitorHeading = AceGUI:Create("Heading")
		monitorHeading:SetText(L["Monitor settings"])
		monitorHeading:SetFullWidth(true)
		
		local show = AceGUI:Create("CheckBox")
		show:SetLabel(L["Show monitor"])
		show:SetValue(db.showDisplay)
		show:SetCallback("OnEnter", onControlEnter)
		show:SetCallback("OnLeave", onControlLeave)
		show:SetCallback("OnValueChanged", showCallback)
		show:SetUserData("tooltip", L["Show or hide the cooldown bar display in the game world."])
		show:SetFullWidth(true)
		
		local lock = AceGUI:Create("CheckBox")
		lock:SetLabel(L["Lock monitor"])
		lock:SetValue(db.lockDisplay)
		lock:SetCallback("OnEnter", onControlEnter)
		lock:SetCallback("OnLeave", onControlLeave)
		lock:SetCallback("OnValueChanged", lockCallback)
		lock:SetUserData("tooltip", L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."])
		lock:SetFullWidth(true)

		local only = AceGUI:Create("CheckBox")
		only:SetLabel(L["Only show my own spells"])
		only:SetValue(db.onlyShowMine)
		only:SetCallback("OnEnter", onControlEnter)
		only:SetCallback("OnLeave", onControlLeave)
		only:SetCallback("OnValueChanged", onlyMineCallback)
		only:SetUserData("tooltip", L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."])
		only:SetFullWidth(true)

		local cooldownHeading = AceGUI:Create("Heading")
		cooldownHeading:SetText(L["Cooldown settings"])
		cooldownHeading:SetFullWidth(true)
		
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

		frame:AddChildren(monitorHeading, show, lock, only, cooldownHeading, moduleDescription, group)

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
	local function onTestClick() module:SpawnTestBar() end
	local function colorChanged(widget, event, r, g, b)
		db.barColor = {r, g, b, 1}
		if not db.barClassColor then
			restyleBars()
		end
	end
	local function toggleChanged(widget, event, value)
		local key = widget:GetUserData("key")
		if not key then return end
		db[key] = value
		restyleBars()
	end
	local function heightChanged(widget, event, value)
		db.barHeight = value
		restyleBars()
	end

	local function show()
		local frame = AceGUI:Create("Frame")
		frame:SetCallback("OnClose", frame.Release)
		frame:SetTitle(L["Bar Settings"])
		frame:SetStatusText("")
		frame:SetLayout("Flow")
		frame:SetWidth(240)
		frame:SetHeight(280)

		local test = AceGUI:Create("Button")
		test:SetText(L["Spawn test bar"])
		test:SetCallback("OnClick", onTestClick)
		test:SetFullWidth(true)

		local classColor = AceGUI:Create("CheckBox")
		classColor:SetValue(db.barClassColor)
		classColor:SetLabel(L["Use class color"])
		classColor:SetUserData("key", "barClassColor")
		classColor:SetCallback("OnValueChanged", toggleChanged)
		classColor:SetRelativeWidth(0.7)

		local picker = AceGUI:Create("ColorPicker")
		picker:SetHasAlpha(false)
		picker:SetCallback("OnValueConfirmed", colorChanged)
		picker:SetRelativeWidth(0.3)
		picker:SetColor(unpack(db.barColor))

		local height = AceGUI:Create("Slider")
		height:SetLabel(L["Bar height"])
		height:SetValue(db.barHeight)
		height:SetSliderValues(8, 32, 1)
		height:SetCallback("OnValueChanged", heightChanged)
		height:SetFullWidth(true)

		local header = AceGUI:Create("Heading")
		header:SetText(L["Show"])
		header:SetFullWidth(true)
		
		local icon = AceGUI:Create("CheckBox")
		icon:SetValue(db.barShowIcon)
		icon:SetLabel(L["Icon"])
		icon:SetUserData("key", "barShowIcon")
		icon:SetCallback("OnValueChanged", toggleChanged)
		icon:SetRelativeWidth(0.5)
		
		local duration = AceGUI:Create("CheckBox")
		duration:SetValue(db.barShowDuration)
		duration:SetLabel(L["Duration"])
		duration:SetUserData("key", "barShowDuration")
		duration:SetCallback("OnValueChanged", toggleChanged)
		duration:SetRelativeWidth(0.5)
		
		local unit = AceGUI:Create("CheckBox")
		unit:SetValue(db.barShowUnit)
		unit:SetLabel(L["Unit name"])
		unit:SetUserData("key", "barShowUnit")
		unit:SetCallback("OnValueChanged", toggleChanged)
		unit:SetRelativeWidth(0.5)
		
		local spell = AceGUI:Create("CheckBox")
		spell:SetValue(db.barShowSpell)
		spell:SetLabel(L["Spell name"])
		spell:SetUserData("key", "barShowSpell")
		spell:SetCallback("OnValueChanged", toggleChanged)
		spell:SetRelativeWidth(0.5)
		
		local short = AceGUI:Create("CheckBox")
		short:SetValue(db.barShorthand)
		short:SetLabel(L["Short Spell name"])
		short:SetUserData("key", "barShorthand")
		short:SetCallback("OnValueChanged", toggleChanged)
		--short:SetRelativeWidth(0.5)
		
		frame:AddChildren(test, classColor, picker, height, header, icon, duration, unit, spell, short)
		
		frame:Show()
	end
	showBarConfig = show
end

--------------------------------------------------------------------------------
-- Bar display
--

local startBar, setupCooldownDisplay, barStopped
do
	local display = nil
	local maximum = 10
	local bars = {}
	local visibleBars = {}
	local locked = nil
	local shown = nil
	function isDisplayLocked() return locked end
	function isDisplayShown() return shown end

	local function utf8trunc(text, num)
		local len = 0
		local i = 1
		local text_len = #text
		while len < num and i <= text_len do
			len = len + 1
			local b = text:byte(i)
			if b <= 127 then
				i = i + 1
			elseif b <= 223 then
				i = i + 2
			elseif b <= 239 then
				i = i + 3
			else
				i = i + 4
			end
		end
		return text:sub(1, i-1)
	end

	-- FIXME: metatable this
	local shorts = {}
	local function getShorty(name)
		if not shorts[name] then
			local p1, p2, p3, p4 = string.split(" ", (string.gsub(name,":", " :")))
			if not p2 then
				shorts[name] = utf8trunc(name, 4)
			elseif not p3 then
				shorts[name] = utf8trunc(p1, 1) .. utf8trunc(p2, 1)
			elseif not p4 then
				shorts[name] = utf8trunc(p1, 1) .. utf8trunc(p2, 1)	.. utf8trunc(p3, 1)
			else
				shorts[name] = utf8trunc(p1, 1) .. utf8trunc(p2, 1) .. utf8trunc(p3, 1) .. utf8trunc(p4, 1)
			end
		end
		return shorts[name]
	end
	
	local function restyleBar(bar)
		bar:SetHeight(db.barHeight)
		bar:SetIcon(db.barShowIcon and bar.icon or nil)
		bar:SetTimeVisibility(db.barShowDuration)
		local spell = bar.spell
		if db.barShorthand then spell = getShorty(spell) end
		if db.barShowSpell and db.barShowUnit then
			bar:SetLabel(("%s: %s"):format(bar.unit, spell))
		elseif db.barShowSpell then
			bar:SetLabel(spell)
		elseif db.barShowUnit then
			bar:SetLabel(bar.unit)
		else
			bar:SetLabel()
		end
		if db.barClassColor then
			local c = RAID_CLASS_COLORS[bar.unitclass]
			bar:SetColor(c.r, c.g, c.b, 1)
		else
			bar:SetColor(unpack(db.barColor))
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
					bar:SetPoint("TOPLEFT", display, 4, -4)
					bar:SetPoint("TOPRIGHT", display, -4, -4)
				else
					bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT")
					bar:SetPoint("TOPRIGHT", lastBar, "BOTTOMRIGHT")
				end
				lastBar = bar
				bar:Show()
			else
				bar:Hide()
			end
		end
	end

	function barStopped(event, bar)
		visibleBars[bar] = nil
		rearrangeBars()
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
		if button == "RightButton" then showBarConfig() end
	end
	
	local function onDragStart(self) self:StartMoving() end
	local function onDragStop(self)
		self:StopMovingOrSizing()
		local s = display:GetEffectiveScale()
		db.x = display:GetLeft() * s
		db.y = display:GetTop() * s
	end
	local function onEnter(self)
		if not next(visibleBars) then self.help:Show() end
	end
	local function onLeave(self) self.help:Hide() end

	function lockDisplay()
		if locked then return end
		display:EnableMouse(false)
		display:SetMovable(false)
		display:SetResizable(false)
		display:RegisterForDrag()
		display:SetScript("OnSizeChanged", nil)
		display:SetScript("OnDragStart", nil)
		display:SetScript("OnDragStop", nil)
		display:SetScript("OnMouseDown", nil)
		display:SetScript("OnEnter", nil)
		display:SetScript("OnLeave", nil)
		display.drag:Hide()
		display.header:Hide()
		display.bg:SetTexture(0, 0, 0, 0)
		locked = true
	end
	function unlockDisplay()
		if not locked then return end
		display:EnableMouse(true)
		display:SetMovable(true)
		display:SetResizable(true)
		display:RegisterForDrag("LeftButton")
		display:SetScript("OnSizeChanged", onResize)
		display:SetScript("OnDragStart", onDragStart)
		display:SetScript("OnDragStop", onDragStop)
		display:SetScript("OnMouseDown", displayOnMouseDown)
		display:SetScript("OnEnter", onEnter)
		display:SetScript("OnLeave", onLeave)
		display.bg:SetTexture(0, 0, 0, 0.3)
		display.drag:Show()
		display.header:Show()
		locked = nil
	end
	function showDisplay()
		display:Show()
		shown = true
	end
	function hideDisplay()
		display:Hide()
		shown = nil
	end

	local function setup()
		display = CreateFrame("Frame", "oRA3CooldownFrame", UIParent)
		display:SetWidth(db.width)
		display:SetHeight(db.height)
		display:SetMinResize(100, 20)
		if db.x and db.y then
			local s = display:GetEffectiveScale()
			display:ClearAllPoints()
			display:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.x / s, db.y / s)
		else
			display:SetPoint("LEFT", UIParent, 200, 0)
		end
		local bg = display:CreateTexture(nil, "PARENT")
		bg:SetAllPoints(display)
		bg:SetBlendMode("BLEND")
		bg:SetTexture(0, 0, 0, 0.3)
		display.bg = bg
		local header = display:CreateFontString(nil, "OVERLAY")
		header:SetFontObject(GameFontNormal)
		header:SetText("Cooldowns")
		header:SetPoint("BOTTOM", display, "TOP", 0, 4)
		local help = display:CreateFontString(nil, "OVERLAY")
		help:SetFontObject(GameFontNormal)
		help:SetText("Right-Click me for options!")
		help:SetAllPoints(display)
		help:Hide()
		display.help = help
		display.header = header

		local drag = CreateFrame("Frame", nil, display)
		drag.frame = display
		drag:SetFrameLevel(display:GetFrameLevel() + 10) -- place this above everything
		drag:SetWidth(16)
		drag:SetHeight(16)
		drag:SetPoint("BOTTOMRIGHT", display, -1, 1)
		drag:EnableMouse(true)
		drag:SetScript("OnMouseDown", OnDragHandleMouseDown)
		drag:SetScript("OnMouseUp", OnDragHandleMouseUp)
		drag:SetAlpha(0.5)
		display.drag = drag

		local tex = drag:CreateTexture(nil, "BACKGROUND")
		tex:SetTexture("Interface\\AddOns\\oRA3\\images\\draghandle")
		tex:SetWidth(16)
		tex:SetHeight(16)
		tex:SetBlendMode("ADD")
		tex:SetPoint("CENTER", drag)

		if db.lockDisplay then
			locked = nil
			lockDisplay()
		else
			locked = true
			unlockDisplay()
		end
		if db.showDisplay then
			shown = true
			showDisplay()
		else
			shown = nil
			hideDisplay()
		end
	end
	setupCooldownDisplay = setup
	
	local function start(unit, id, name, icon, duration)
		local bar = candy:New("Interface\\AddOns\\oRA3\\images\\statusbar", db.width, db.barHeight)
		visibleBars[bar] = true
		bar.unitclass = classLookup[id]
		bar.unit = unit
		bar.spell = name
		bar.icon = icon
		bar:SetDuration(duration)
		restyleBar(bar)
		bar:Start()
		rearrangeBars()
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
			showDisplay = false,
			onlyShowMine = nil,
			lockDisplay = false,
			width = 200,
			height = 148,
			barShorthand = false,
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
		local name = GetSpellInfo(spell)
		if name then broadcastSpells[name] = spell end
	end
	
	setupCooldownDisplay()
	
	oRA.RegisterCallback(self, "OnCommCooldown")
	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
	
	candy:RegisterCallback("LibCandyBar_Stop", barStopped)
end

do
	local spellList, reverseClass = nil, nil
	function module:SpawnTestBar()
		if not spellList then
			spellList = {}
			reverseClass = {}
			for k in pairs(allSpells) do table.insert(spellList, k) end
			for name, class in pairs(oRA._testUnits) do reverseClass[class] = name end
		end
		local spell = spellList[math.random(1, #spellList)]
		local name, _, icon = GetSpellInfo(spell)
		if not name then return end
		local unit = reverseClass[classLookup[spell]]
		local duration = (allSpells[spell] / 30) + math.random(1, 120)
		startBar(unit, spell, name, icon, duration)
	end
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
	--print("We got a cooldown for " .. tostring(spell) .. " (" .. tostring(cd) .. ") from " .. tostring(sender))
	if type(spell) ~= "number" or type(cd) ~= "number" then error("Spell or number had the wrong type.") end
	if not db.spells[spell] then return end
	local name, _, icon = GetSpellInfo(spell)
	if not name or not icon then return end
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

