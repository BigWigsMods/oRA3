--------------------------------------------------------------------------------
-- Setup
--

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Cooldowns", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")
local candy = LibStub("LibCandyBar-3.0")
local media = LibStub("LibSharedMedia-3.0")

module.VERSION = tonumber(("$Revision$"):sub(12, -3))

--------------------------------------------------------------------------------
-- Locals
--

local mType = media and media.MediaType and media.MediaType.STATUSBAR or "statusbar"
local playerName = UnitName("player")
local _, playerClass = UnitClass("player")
local bloodlustId = UnitFactionGroup("player") == "Alliance" and 32182 or 2825

local glyphCooldowns = {
	[55455] = {2894, 300},   -- Fire Elemental Totem, 5min
	[58618] = {47476, 20},   -- Strangulate, 20sec
	[56373] = {31687, 30},   -- Summon Water Elemental, 30sec
	[63229] = {47585, 45},   -- Dispersion, 45sec
	[63329] = {871, 120},    -- Shield Wall, 2min
	[57903] = {5384, 5},     -- Feign Death, 5sec
	[57858] = {5209, 30},    -- Challenging Roar, 30sec
	[55678] = {6346, 60},    -- Fear Ward, 60sec
	[58376] = {12975, 60},   -- Last Stand, 1min
	[57955] = {48788, 300},  -- Lay on Hands, 5min
}

local spells = {
	DRUID = {
		[48477] = 600,  -- Rebirth
		[29166] = 180,  -- Innervate
		[17116] = 180,  -- Nature's Swiftness
		[5209] = 180,   -- Challenging Roar
		[61336] = 180,  -- Survival Instincts
		[22812] = 60,   -- Barkskin
	},
	HUNTER = {
		[34477] = 30,   -- Misdirect
		[5384] = 30,    -- Feign Death
		[62757] = 300,  -- Call Stabled Pet
		[781] = 25,     -- Disengage
		[34490] = 20,   -- Silencing Shot
	},
	MAGE = {
		[45438] = 300,  -- Iceblock
		[2139] = 24,    -- Counterspell
		[31687] = 180,  -- Summon Water Elemental
		[12051] = 240,  -- Evocation
		[66] = 180,     -- Invisibility
	},
	PALADIN = {
		[19752] = 600,  -- Divine Intervention
		[642] = 300,    -- Divine Shield
		[64205] = 120,  -- Divine Sacrifice
		[498] = 180,    -- Divine Protection
		[10278] = 300,  -- Hand of Protection
		[6940] = 120,   -- Hand of Sacrifice
		[48788] = 1200, -- Lay on Hands
	},
	PRIEST = {
		[33206] = 180,  -- Pain Suppression
		[47788] = 180,  -- Guardian Spirit
		[6346] = 180,   -- Fear Ward
		[64843] = 480,  -- Divine Hymn
		[64901] = 360,  -- Hymn of Hope
		[34433] = 300,  -- Shadowfiend
		[10060] = 120,  -- Power Infusion
		[47585] = 180,  -- Dispersion
	},
	ROGUE = {
		[31224] = 90,   -- Cloak of Shadows
		[38768] = 10,   -- Kick
		[1725] = 30,    -- Distract
		[13750] = 180,  -- Adrenaline Rush
		[13877] = 120,  -- Blade Flurry
		[14177] = 180,  -- Cold Blood
		[11305] = 180,  -- Sprint
		[26889] = 180,  -- Vanish
	},
	SHAMAN = {
		[bloodlustId] = 300, -- Bloodlust/Heroism
		[20608] = 1800, -- Reincarnation
		[16190] = 300,  -- Mana Tide Totem
		[2894] = 600,   -- Fire Elemental Totem
		[2062] = 600,   -- Earth Elemental Totem
		[16188] = 180,  -- Nature's Swiftness
		[57994] = 6,    -- Wind Shear
	},
	WARLOCK = {
		-- [47883] = 900, -- Soulstone Resurrection, removed this spellcast_success is hit with 6203 for all ranks
		[6203] = 900,   -- Soulstone
		[29858] = 180,  -- Soulshatter
		[47241] = 180,  -- Metamorphosis
		[18708] = 900,  -- Fel Domination
		[698] = 120,    -- Ritual of Summoning
		[58887] = 300,  -- Ritual of Souls
	},
	WARRIOR = {
		[871] = 300,    -- Shield Wall
		[1719] = 300,   -- Recklessness
		[20230] = 300,  -- Retaliation
		[12975] = 180,  -- Last Stand
		[6554] = 10,    -- Pummel
		[1161] = 180,   -- Challenging Shout
		[5246] = 180,   -- Intimidating Shout
		[64380] = 300,  -- Shattering Throw (could be 64382)
		[55694] = 180,  -- Enraged Regeneration
		[72] = 12,      -- Shield Bash
	},
	DEATHKNIGHT = {
		[48792] = 120,  -- Icebound Fortitude
		[42650] = 600,  -- Army of the Dead
		[61999] = 600,  -- Raise Ally
		[49028] = 90,   -- Dancing Rune Weapon
		[49206] = 180,  -- Summon Gargoyle
		[47476] = 120,  -- Strangulate
		[49576] = 35,   -- Death Grip
		[51271] = 120,  -- Unbreakable Armor
		[55233] = 120,  -- Vampiric Blood
		[49222] = 120,  -- Bone Shield
		[47528] = 10,   -- Mind Freeze
		[48707] = 45,   -- Anti-Magic Shell
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
		classes[class] = hexColors[class] .. LOCALIZED_CLASS_NAMES_MALE[class] .. "|r"
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
		db.spells[id] = value and true or false
	end

	local function dropdownGroupCallback(widget, event, key)
		widget:PauseLayout()
		widget:ReleaseChildren()
		wipe(tmp)
		if spells[key] then
			-- Class spells
			for id in pairs(spells[key]) do
				tmp[#tmp + 1] = id
			end
			table.sort(tmp) -- ZZZ Sorted by spell ID, oh well!
			for i, v in next, tmp do
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
	local function neverMineCallback(widget, event, value)
		db.neverShowMine = value
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
		
		local never = AceGUI:Create("CheckBox")
		never:SetLabel(L["Never show my own spells"])
		never:SetValue(db.neverShowMine)
		never:SetCallback("OnEnter", onControlEnter)
		never:SetCallback("OnLeave", onControlLeave)
		never:SetCallback("OnValueChanged", neverMineCallback)
		never:SetUserData("tooltip", L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."])
		never:SetFullWidth(true)

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

		frame:AddChildren(monitorHeading, show, lock, only, never, cooldownHeading, moduleDescription, group)

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
	local function scaleChanged(widget, event, value)
		db.barScale = value
		restyleBars()
	end
	local function textureChanged(widget, event, value)
		local list = media:List(mType)
		db.barTexture = list[value]
		restyleBars()
	end
	local function alignChanged(widget, event, value)
		db.barLabelAlign = value
		restyleBars()
	end
	
	local plainFrame = nil
	local function show()
		if not plainFrame then
			plainFrame = AceGUI:Create("Window")
			plainFrame:SetWidth(240)
			plainFrame:SetHeight(380)
			plainFrame:SetPoint("CENTER", UIParent, "CENTER")
			plainFrame:SetTitle( L["Bar Settings"] )
			plainFrame:SetLayout("Fill")

			local group = AceGUI:Create("ScrollFrame")
			group:SetLayout("Flow")
			group:SetFullWidth(true)
			
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
			height:SetLabel(L["Height"])
			height:SetValue(db.barHeight)
			height:SetSliderValues(8, 32, 1)
			height:SetCallback("OnValueChanged", heightChanged)
			height:SetRelativeWidth(0.5)
			height.editbox:Hide()
			
			local scale = AceGUI:Create("Slider")
			scale:SetLabel(L["Scale"])
			scale:SetValue(db.barScale)
			scale:SetSliderValues(0.1, 5.0, 0.1)
			scale:SetCallback("OnValueChanged", scaleChanged)
			scale:SetRelativeWidth(0.5)
			scale.editbox:Hide()

			local tex = AceGUI:Create("Dropdown")
			local list = media:List(mType)
			local selected = nil
			for k, v in pairs(list) do
				if v == db.barTexture then
					selected = k
				end
			end
			tex:SetList(media:List(mType))
			tex:SetValue(selected)
			tex:SetLabel(L["Texture"])
			tex:SetCallback("OnValueChanged", textureChanged)
			tex:SetFullWidth(true)
			
			local align = AceGUI:Create("Dropdown")
			align:SetList( { ["LEFT"] = L["Left"], ["CENTER"] = L["Center"], ["RIGHT"] = L["Right"] } )
			align:SetValue( db.barLabelAlign )
			align:SetLabel(L["Label Align"])
			align:SetCallback("OnValueChanged", alignChanged)
			align:SetFullWidth(true)
			
			local growup = AceGUI:Create("CheckBox")
			growup:SetValue(db.cooldownBarGrowUp)
			growup:SetLabel(L["Grow up"])
			growup:SetUserData("key", "barGrowUp")
			growup:SetCallback("OnValueChanged", toggleChanged)

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
			
			group:AddChildren(test, classColor, picker, height, scale, tex, align, growup, header, icon, duration, unit, spell, short)
			plainFrame:AddChildren(group)
		end
		plainFrame:Show()
	end
	showBarConfig = show
end

--------------------------------------------------------------------------------
-- Bar display
--

local startBar, setupCooldownDisplay, barStopped, stopAll
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

	local shorts = setmetatable({}, {__index =
		function(self, key)
			if type(key) == "nil" then return nil end
			local p1, p2, p3, p4 = string.split(" ", (string.gsub(key,":", " :")))
			if not p2 then
				self[key] = utf8trunc(key, 4)
			elseif not p3 then
				self[key] = utf8trunc(p1, 1) .. utf8trunc(p2, 1)
			elseif not p4 then
				self[key] = utf8trunc(p1, 1) .. utf8trunc(p2, 1) .. utf8trunc(p3, 1)
			else
				self[key] = utf8trunc(p1, 1) .. utf8trunc(p2, 1) .. utf8trunc(p3, 1) .. utf8trunc(p4, 1)
			end
			return self[key]
		end
	})
	
	local function restyleBar(bar)
		bar:SetHeight(db.barHeight)
		bar:SetIcon(db.barShowIcon and bar:Get("ora3cd:icon") or nil)
		bar:SetTimeVisibility(db.barShowDuration)
		bar:SetScale(db.barScale)
		bar:SetTexture(media:Fetch(mType, db.barTexture))
		local spell = bar:Get("ora3cd:spell")
		if db.barShorthand then spell = shorts[spell] end
		if db.barShowSpell and db.barShowUnit and not db.onlyShowMine then
			bar:SetLabel(("%s: %s"):format(bar:Get("ora3cd:unit"), spell))
		elseif db.barShowSpell then
			bar:SetLabel(spell)
		elseif db.barShowUnit and not db.onlyShowMine then
			bar:SetLabel(bar:Get("ora3cd:unit"))
		else
			bar:SetLabel()
		end
		bar.candyBarLabel:SetJustifyH(db.barLabelAlign)
		if db.barClassColor then
			local c = RAID_CLASS_COLORS[bar:Get("ora3cd:unitclass")]
			bar:SetColor(c.r, c.g, c.b, 1)
		else
			bar:SetColor(unpack(db.barColor))
		end
	end
	
	
	function stopAll()
		for bar in pairs(visibleBars) do
			bar:Stop()
		end
	end
	
	local function barSorter(a, b)
		return a.remaining < b.remaining and true or false
	end
	local tmp = {}
	local function rearrangeBars()
		wipe(tmp)
		for bar in pairs(visibleBars) do
			tmp[#tmp + 1] = bar
		end
		table.sort(tmp, barSorter)
		local lastBar = nil
		for i, bar in next, tmp do
			bar:ClearAllPoints()
			if i <= maximum then
				if not lastBar then
					if db.barGrowUp then
						bar:SetPoint("BOTTOMLEFT", display, 4, 4)
						bar:SetPoint("BOTTOMRIGHT", display, -4, 4)
					else
						bar:SetPoint("TOPLEFT", display, 4, -4)
						bar:SetPoint("TOPRIGHT", display, -4, -4)
					end
				else
					if db.barGrowUp then
						bar:SetPoint("BOTTOMLEFT", lastBar, "TOPLEFT")
						bar:SetPoint("BOTTOMRIGHT", lastBar, "TOPRIGHT")
					else
						bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT")
						bar:SetPoint("TOPRIGHT", lastBar, "BOTTOMRIGHT")
					end
				end
				lastBar = bar
				bar:Show()
			else
				bar:Hide()
			end
		end
	end

	function restyleBars()
		for bar in pairs(visibleBars) do
			restyleBar(bar)
		end
		rearrangeBars()
	end
	
	function barStopped(event, bar)
		if visibleBars[bar] then
			visibleBars[bar] = nil
			rearrangeBars()
		end
	end

	local function OnDragHandleMouseDown(self) self.frame:StartSizing("BOTTOMRIGHT") end
	local function OnDragHandleMouseUp(self, button) self.frame:StopMovingOrSizing() end
	local function onResize(self, width, height)
		oRA3:SavePosition("oRA3CooldownFrame")
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
		oRA3:SavePosition("oRA3CooldownFrame")
	end
	local function onEnter(self)
		if not next(visibleBars) then self.help:Show() end
	end
	local function onLeave(self) self.help:Hide() end

	function lockDisplay()
		if locked then return end
		if not display then setupCooldownDisplay() end
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
		if not display then setupCooldownDisplay() end
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
		if not display then setupCooldownDisplay() end
		display:Show()
		shown = true
	end
	function hideDisplay()
		if not display then return end
		display:Hide()
		shown = nil
	end

	local function setup()
		if display then
			if db.showDisplay then showDisplay() end
			return
		end
		display = CreateFrame("Frame", "oRA3CooldownFrame", UIParent)
		display:SetMinResize(100, 20)
		display:SetWidth(200)
		display:SetHeight(148)
		oRA3:RestorePosition("oRA3CooldownFrame")
		local bg = display:CreateTexture(nil, "PARENT")
		bg:SetAllPoints(display)
		bg:SetBlendMode("BLEND")
		bg:SetTexture(0, 0, 0, 0.3)
		display.bg = bg
		local header = display:CreateFontString(nil, "OVERLAY")
		header:SetFontObject(GameFontNormal)
		header:SetText(L["Cooldowns"])
		header:SetPoint("BOTTOM", display, "TOP", 0, 4)
		local help = display:CreateFontString(nil, "OVERLAY")
		help:SetFontObject(GameFontNormal)
		help:SetText(L["Right-Click me for options!"])
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
		local bar
		for b, v in pairs(visibleBars) do
			if b:Get("ora3cd:unit") == unit and b:Get("ora3cd:spell") == name then
				bar = b
				break;
			end
		end
		if not bar then
			bar = candy:New("Interface\\AddOns\\oRA3\\images\\statusbar", display:GetWidth(), db.barHeight)
		end
		visibleBars[bar] = true
		bar:Set("ora3cd:unitclass", classLookup[id])
		bar:Set("ora3cd:unit", unit)
		bar:Set("ora3cd:spell", name)
		bar:Set("ora3cd:icon", icon)
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
				[6203] = true,
				[19752] = true,
				[20608] = true,
				[27239] = true,
			},
			showDisplay = true,
			onlyShowMine = nil,
			neverShowMine = nil,
			lockDisplay = false,
			barShorthand = false,
			barHeight = 14,
			barScale = 1.0,
			barShowIcon = true,
			barShowDuration = true,
			barShowUnit = true,
			barShowSpell = true,
			barClassColor = true,
			barGrowUp = false,
			barLabelAlign = "CENTER",
			barColor = { 0.25, 0.33, 0.68, 1 },
			barTexture = "oRA3",
		},
	})
	for k, v in pairs(database.profile.spells) do
		if not classLookup[k] then
			database.profile.spells[k] = nil
		end
	end
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
	
	if media then
		media:Register(mType, "oRA3", "Interface\\AddOns\\oRA3\\images\\statusbar")
	end
	
	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
	candy.RegisterCallback(self, "LibCandyBar_Stop", barStopped)
end

do
	local spellList, reverseClass = nil, nil
	function module:SpawnTestBar()
		if not spellList then
			spellList = {}
			reverseClass = {}
			for k in pairs(allSpells) do spellList[#spellList + 1] = k end
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
	setupCooldownDisplay()
	oRA.RegisterCallback(self, "OnCommCooldown")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateCooldownModifiers")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateCooldownModifiers")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UpdateCooldownModifiers()
	if playerClass == "SHAMAN" then
		local resTime = GetTime()
		local ankhs = GetItemCount(17030)
		self:RegisterEvent("PLAYER_ALIVE", function()
			resTime = GetTime()
			self:UpdateCooldownModifiers()
		end)
		self:RegisterEvent("BAG_UPDATE", function()
			if (GetTime() - (resTime or 0)) > 1 then return end
			local newankhs = GetItemCount(17030)
			if newankhs == (ankhs - 1) then
				oRA:SendComm("Cooldown", 20608, getCooldown(20608)) -- Spell ID + CD in seconds
			end
			ankhs = newankhs
		end)
	else
		self:RegisterEvent("PLAYER_ALIVE", "UpdateCooldownModifiers")
	end
end

function module:OnShutdown()
	stopAll()
	hideDisplay()
	oRA.UnregisterCallback(self, "OnCommCooldown")
	self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function module:OnCommCooldown(commType, sender, spell, cd)
	--print("We got a cooldown for " .. tostring(spell) .. " (" .. tostring(cd) .. ") from " .. tostring(sender))
	if type(spell) ~= "number" or type(cd) ~= "number" then error("Spell or number had the wrong type.") end
	if not db.spells[spell] then return end
	if db.onlyShowMine and sender ~= playerName then return end
	if db.neverShowMine and sender == playerName then return end
	if not db.showDisplay then return end
	local name, _, icon = GetSpellInfo(spell)
	if not name or not icon then return end
	startBar(sender, spell, name, icon, cd)
end

local function addMod(s, m)
	if m == 0 then return end
	if not cdModifiers[s] then
		cdModifiers[s] = m
	else
		cdModifiers[s] = cdModifiers[s] + m
	end
end

local function getRank(tab, talent)
	local _, _, _, _, rank = GetTalentInfo(tab, talent)
	return rank or 0
end

local talentScanners = {
	PALADIN = function()
		addMod(10278, getRank(2, 4) * 60)
		addMod(48788, getRank(1, 8) * 120)
		local rank = getRank(2, 14)
		addMod(642, rank * 30)
		addMod(498, rank * 30)
	end,
	SHAMAN = function()
		addMod(20608, getRank(3, 3) * 600)
	end,
	WARRIOR = function()
		local rank = getRank(3, 13)
		addMod(871, rank * 30)
		addMod(1719, rank * 30)
		addMod(20230, rank * 30)
	end,
	DEATHKNIGHT = function()
		addMod(49576, getRank(3, 6) * 5)
		addMod(42650, getRank(3, 13) * 120)
	end,
	HUNTER = function()
		addMod(781, getRank(3, 11) * 2)
	end,
	MAGE = function()
		local rank = getRank(1, 24)
		addMod(12051, rank * 60)
		if rank > 0 then
			local percent = rank * 15
			local currentCd = getCooldown(66)
			addMod(66, (currentCd * percent) / 100)
		end
	end,
	PRIEST = function()
		local rank = getRank(1, 23)
		if rank > 0 then
			local percent = rank * 10
			local currentCd = getCooldown(10060)
			addMod(10060, (currentCd * percent) / 100)
			currentCd = getCooldown(33206)
			addMod(33206, (currentCd * percent) / 100)
		end
	end,
	ROGUE = function()
		addMod(11305, getRank(2, 7) * 30)
		addMod(1725, getRank(3, 26) * 5)
		local rank = getRank(3, 7)
		addMod(26889, rank * 30)
		addMod(31224, rank * 15)
	end,
}

function module:UpdateCooldownModifiers()
	wipe(cdModifiers)
	for i = 1, GetNumGlyphSockets() do
		local enabled, _, spellId = GetGlyphSocketInfo(i)
		if enabled and spellId and glyphCooldowns[spellId] then
			local info = glyphCooldowns[spellId]
			addMod(info[1], info[2])
		end
	end
	if talentScanners[playerClass] then
		talentScanners[playerClass]()
	end
end

function module:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell)
	if unit ~= "player" then return end
	if broadcastSpells[spell] then
		local spellId = broadcastSpells[spell]
		oRA:SendComm("Cooldown", spellId, getCooldown(spellId)) -- Spell ID + CD in seconds
	end
end

function module:COMBAT_LOG_EVENT_UNFILTERED(event, _, clueevent, _, source, _, _, _, _, spellId, spellName)
	if clueevent ~= "SPELL_RESURRECT" and clueevent ~= "SPELL_CAST_SUCCESS" then return end
	if not source or source == playerName then return end
	if allSpells[spellId] and util:inTable(oRA:GetGroupMembers(), source) then -- FIXME: use bitflag to check groupmembers
		self:OnCommCooldown("RAID", source, spellId, allSpells[spellId])
	end
end


