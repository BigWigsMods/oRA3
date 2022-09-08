
local DISPLAY_TYPE, DISPLAY_VERSION = "Bars", 1

local _, scope = ...
local oRA3 = scope.addon
local oRA3CD = oRA3:GetModule("Cooldowns")
local L = scope.locale
local classColors = oRA3.classColors

local candy = LibStub("LibCandyBar-3.0")
local media = LibStub("LibSharedMedia-3.0")

local DEFAULT_BAR = "Interface\\AddOns\\oRA3\\media\\statusbar"
media:Register("statusbar", "oRA3", DEFAULT_BAR)

local barStyles = oRA3CD:GetBarStyles()

local After = C_Timer.After

---------------------------------------
-- Display

local prototype = {}

function prototype:OnHide()
	for bar in next, self.bars do
		bar:Set("ora3cd:testunit", nil) -- don't restart bars during shutdown
		bar:Stop()
	end
end

function prototype:OnSetup()
	candy.RegisterCallback(self, "LibCandyBar_Stop")
end

function prototype:OnResize()
	self:RearrangeBars()
end

function prototype:OnDelete()
	oRA3CD.UnregisterAllCallbacks(self)
	candy.UnregisterAllCallbacks(self)
	self:UnregisterAllEvents()
end

---------------------------------------
-- Bars

function prototype:LibCandyBar_Stop(_, frame)
	if frame:Get("ora3cd:display") == self then
		self.bars[frame] = nil
		local styler = frame:Get("ora3cd:barstyle")
		if styler then
			barStyles[styler].BarStopped(frame)
		end
		self:RearrangeBars()

		-- show test bars as ready for a bit then hide them
		if self.db.showOffCooldown and frame:Get("ora3cd:testunit") then
			local player, spellId = frame:Get("ora3cd:player"), frame:Get("ora3cd:spellid")
			self:CooldownReady(player, player, frame:Get("ora3cd:class"), spellId)
			After(20, function()
				local bar = self:GetBar(player, spellId)
				if bar and bar:Get("ora3cd:ready") then
					bar:Stop()
				end
			end)
		end
	end
end

do
	local tmp = {}

	local function sortByRemaining(a, b) -- remaining > class > spell name
		if a:Get("ora3cd:ready") and b:Get("ora3cd:ready") then
			if a:Get("ora3cd:class") == b:Get("ora3cd:class") then
				if a:Get("ora3cd:spell") == b:Get("ora3cd:spell") then
					return a:Get("ora3cd:player") < b:Get("ora3cd:player")
				end
				return a:Get("ora3cd:spell") < b:Get("ora3cd:spell")
			else
				return a:Get("ora3cd:class") < b:Get("ora3cd:class")
			end
		elseif a:Get("ora3cd:ready") or b:Get("ora3cd:ready") then
			return a:Get("ora3cd:ready") and not b:Get("ora3cd:ready") -- ready on top
		end
		return a.remaining < b.remaining
	end

	local function sortByGroup(a, b) -- class > spell name > remaining
		if a:Get("ora3cd:class") == b:Get("ora3cd:class") then
			if a:Get("ora3cd:spell") == b:Get("ora3cd:spell") then
				if a:Get("ora3cd:ready") and b:Get("ora3cd:ready") then
					return a:Get("ora3cd:player") < b:Get("ora3cd:player")
				elseif a:Get("ora3cd:ready") or b:Get("ora3cd:ready") then
					return a:Get("ora3cd:ready") and not b:Get("ora3cd:ready") -- ready on top
				end
				return a.remaining < b.remaining
			else
				return a:Get("ora3cd:spell") < b:Get("ora3cd:spell")
			end
		else
			return a:Get("ora3cd:class") < b:Get("ora3cd:class")
		end
	end

	function prototype:RearrangeBars()
		if not self:IsShown() then return end

		local db = self.db

		wipe(tmp)
		for bar in next, self.bars do
			tmp[#tmp + 1] = bar
		end
		sort(tmp, db.groupSpells and sortByGroup or sortByRemaining)

		local container = self:GetContainer()
		local lastBar = nil
		local stopBars = nil
		for index, bar in next, tmp do
			local spacing = barStyles[db.barStyle].GetSpacing(bar) or 0
			bar:ClearAllPoints()
			if not stopBars then
				if not lastBar then
					if db.barGrowUp then
						bar:SetPoint("BOTTOMLEFT", container, 4, 4)
						bar:SetPoint("BOTTOMRIGHT", container, -4, 4)
					else
						bar:SetPoint("TOPLEFT", container, 4, -4)
						bar:SetPoint("TOPRIGHT", container, -4, -4)
					end
				else
					if db.barGrowUp then
						bar:SetPoint("BOTTOMLEFT", lastBar, "TOPLEFT", 0, spacing)
						bar:SetPoint("BOTTOMRIGHT", lastBar, "TOPRIGHT", 0, spacing)
					else
						bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT", 0, -spacing)
						bar:SetPoint("TOPRIGHT", lastBar, "BOTTOMRIGHT", 0, -spacing)
					end
				end
				-- we don't know the bar height because of styles, so draw bars until we're out of the display
				if (db.barGrowUp and (bar:GetTop() < self:GetTop())) or (not db.barGrowUp and (bar:GetBottom() > self:GetBottom())) then
					lastBar = bar
					bar:Show()
				else
					stopBars = true
					bar:ClearAllPoints()
					bar:Hide()
				end
			else
				bar:Hide()
			end
		end
	end
end

do
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

	local shorts = setmetatable({}, { __index = function(self, key)
		if type(key) == "nil" then return end
		local p1, p2, p3, p4 = strsplit(" ", (key:gsub(":", " :")))
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
	end })

	function prototype:UpdateBarStatus(bar)
		local db = self.db
		local player = bar:Get("ora3cd:player")
		local status = UnitExists(player) and (not UnitIsConnected(player) and L.offline or UnitIsDeadOrGhost(player) and L.dead or (IsInGroup() and not UnitInRange(player)) and L.range)
		local spell = bar:Get("ora3cd:spell")
		if db.barShorthand then spell = shorts[spell] end

		-- update color
		if status and db.barColorStatus then
			local r, g, b, a = unpack(db.barStatusColor)
			bar:SetColor(r, g, b, a or 1)
		elseif db.barClassColor then
			local classColor = classColors[bar:Get("ora3cd:class")] or classColors.UNKNOWN
			bar:SetColor(classColor.r, classColor.g, classColor.b, 1)
		else
			local r, g, b, a = unpack(db.barColor)
			bar:SetColor(r, g, b, a or 1)
		end

		-- update label
		local unit = player:gsub("%-.+", "")
		local charges = bar:Get("ora3cd:charges")
		if tonumber(charges) and charges > 0 then
			if db.barShowSpell then
				spell = ("%s (%s)"):format(spell, charges)
			elseif db.barShowUnit then
				unit = ("%s (%s)"):format(unit, charges)
			end
		end
		if status and db.barShowStatus then
			if db.barShowSpell then
				spell = ("%s (%s)"):format(spell, status)
			elseif db.barShowUnit then
				unit = ("%s (%s)"):format(unit, status)
			end
		end
		if db.barShowSpell and db.barShowUnit then
			bar:SetLabel(("%s: %s"):format(unit, spell))
		elseif db.barShowSpell then
			bar:SetLabel(spell)
		elseif db.barShowUnit then
			bar:SetLabel(unit)
		else
			bar:SetLabel()
		end
	end
end

function prototype:RestyleBar(bar)
	local db = self.db

	local barStyle = bar:Get("ora3cd:barstyle")
	if barStyle and barStyle ~= db.barStyle then
		barStyles[barStyle].BarStopped(bar)
		bar.candyBarBackdrop:Hide()
	end
	barStyle = db.barStyle
	bar:Set("ora3cd:barstyle", barStyle)

	local classColor = classColors[bar:Get("ora3cd:class")] or classColors.UNKNOWN

	bar:SetScale(db.barScale)
	bar:SetHeight(db.barHeight)
	bar:SetIcon(db.barShowIcon and bar:Get("ora3cd:icon"))
	bar:SetTexture(media:Fetch("statusbar", db.barTexture))
	bar:SetFill(db.barFill and not bar:Get("ora3cd:ready"))

	bar.candyBarBackground:SetVertexColor(unpack(db.barColorBG))

	bar.candyBarLabel:SetFont(media:Fetch("font", db.barLabelFont), db.barLabelFontSize, db.barLabelOutline ~= "NONE" and db.barLabelOutline)
	bar.candyBarLabel:SetJustifyH(db.barLabelAlign)
	if db.barLabelClassColor then
		bar.candyBarLabel:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	else
		bar.candyBarLabel:SetTextColor(unpack(db.barLabelColor))
	end

	bar.candyBarDuration:SetFont(media:Fetch("font", db.barDurationFont), db.barDurationFontSize, db.barDurationOutline ~= "NONE" and db.barDurationOutline)
	if db.barDurationClassColor then
		bar.candyBarDuration:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	else
		bar.candyBarDuration:SetTextColor(unpack(db.barDurationColor))
	end
	bar:SetTimeVisibility(db.barShowDuration and not bar:Get("ora3cd:ready")) -- show cd text for charges?

	if barStyle == "Default" then
		bar.candyBarDuration:SetJustifyH(db.barDurationAlign)
	end

	self:UpdateBarStatus(bar)

	barStyles[barStyle].ApplyStyle(bar)
end

function prototype:GetBar(guid, spellId)
	for bar in next, self.bars do
		if bar:Get("ora3cd:guid") == guid and bar:Get("ora3cd:spellid") == spellId then
			return bar
		end
	end
end

function prototype:UpdateLayout()
	if not next(self.bars) then return end
	for bar in next, self.bars do
		if (not bar:Get("ora3cd:testunit") and not oRA3CD:CheckFilter(self, bar:Get("ora3cd:player"))) or (not self.db.showOffCooldown and bar:Get("ora3cd:ready")) then
			bar:Stop()
		else
			self:RestyleBar(bar)
		end
	end
	self:RearrangeBars()
end

---------------------------------------
-- Callbacks

function prototype:TestCooldown(player, class, spellId, remaining)
	if not self.db.showDisplay then return end
	self:Setup()

	local bar = self:GetBar(player, spellId) or candy:New(DEFAULT_BAR, self:GetWidth(), self.db.barHeight)
	self.bars[bar] = true

	local spell, _, icon = GetSpellInfo(spellId)
	bar:Set("ora3cd:guid", player)
	bar:Set("ora3cd:player", player)
	bar:Set("ora3cd:class", class)
	bar:Set("ora3cd:spell", spell)
	bar:Set("ora3cd:icon", icon)
	bar:Set("ora3cd:spellid", spellId)
	bar:Set("ora3cd:display", self)
	bar:Set("ora3cd:ready", nil)
	bar:Set("ora3cd:testunit", true)

	bar:SetDuration(remaining)
	bar:SetFill(self.db.barFill)
	bar.paused = nil
	bar:Start()
	self:RestyleBar(bar)
	self:RearrangeBars()
end

function prototype:oRA3CD_StartCooldown(_, guid, player, class, spellId, remaining)
	if not self.db.showDisplay then return end
	if not self.spellDB[spellId] or not oRA3CD:CheckFilter(self, player) then return end
	self:Setup()

	local bar = self:GetBar(guid, spellId) or candy:New(DEFAULT_BAR, self:GetWidth(), self.db.barHeight)
	self.bars[bar] = true

	local duration = oRA3CD:GetCooldown(guid, spellId)
	local spell, _, icon = GetSpellInfo(spellId)
	bar:Set("ora3cd:guid", guid)
	bar:Set("ora3cd:player", player)
	bar:Set("ora3cd:class", class)
	bar:Set("ora3cd:spell", spell)
	bar:Set("ora3cd:icon", icon)
	bar:Set("ora3cd:spellid", spellId)
	bar:Set("ora3cd:display", self)
	bar:Set("ora3cd:ready", nil)

	bar:SetDuration(remaining)
	bar:SetFill(self.db.barFill)
	bar.paused = nil
	bar:Start(duration)
	self:RestyleBar(bar)
	self:RearrangeBars()
end

function prototype:oRA3CD_CooldownReady(_, guid, player, class, spellId)
	if not self.spellDB[spellId] or not oRA3CD:CheckFilter(self, player) then return end
	self:CooldownReady(guid, player, class, spellId)
end

function prototype:CooldownReady(guid, player, class, spellId)
	if not self.db.showDisplay or not self.db.showOffCooldown then return end
	self:Setup()

	local bar = self:GetBar(guid, spellId) or candy:New(DEFAULT_BAR, self:GetWidth(), self.db.barHeight)
	self.bars[bar] = true

	local spell, _, icon = GetSpellInfo(spellId)
	bar:Set("ora3cd:guid", guid)
	bar:Set("ora3cd:player", player)
	bar:Set("ora3cd:class", class)
	bar:Set("ora3cd:spell", spell)
	bar:Set("ora3cd:icon", icon)
	bar:Set("ora3cd:spellid", spellId)
	bar:Set("ora3cd:display", self)
	bar:Set("ora3cd:ready", true)

	bar:SetDuration(10) -- just some arbitrary value
	bar.fill = false -- don't flash
	bar.paused = nil
	bar:Start()
	bar:Pause()
	self:RestyleBar(bar)
	self:RearrangeBars()
end

function prototype:oRA3CD_UpdateCharges(_, guid, player, class, spellId, remaining, charges, maxCharges)
	if not self.db.showDisplay then return end

	local bar = self:GetBar(guid, spellId)
	if bar then
		bar:Set("ora3cd:charges", charges)
		bar:Set("ora3cd:maxCharges", maxCharges)
		if charges > 0 then
			bar:Set("ora3cd:ready", true)
		end
		self:RestyleBar(bar)
	end
end

function prototype:oRA3CD_StopCooldown(_, guid, spellId)
	if not self.db.showDisplay then return end
	for bar in next, self.bars do
		if guid and spellId then
			if bar:Get("ora3cd:spellid") == spellId and bar:Get("ora3cd:guid") == guid then
				bar:Stop()
			end
		elseif bar:Get("ora3cd:spellid") == spellId or bar:Get("ora3cd:guid") == guid then
			bar:Stop()
		end
	end
end

function prototype:oRA3CD_UpdatePlayer(_, guid)
	for bar in next, self.bars do
		if bar:Get("ora3cd:guid") == guid then
			if oRA3CD:CheckFilter(self, bar:Get("ora3cd:player")) then
				self:UpdateBarStatus(bar)
			else
				bar:Stop()
			end
		end
	end
	self:UpdatePlayerCooldowns(guid, oRA3CD:GetPlayerFromGUID(guid))
end

---------------------------------------
-- Options

function prototype:UpdatePlayerCooldowns(guid, player, class)
	if oRA3CD:CheckFilter(self, player) then
		for spellId in next, self.spellDB do
			if not self:GetBar(guid, spellId) and oRA3CD:IsSpellUsable(guid, spellId) then
				local cd = oRA3CD:GetRemainingCooldown(guid, spellId)
				if cd > 0 then
					self:oRA3CD_StartCooldown(nil, guid, player, class, spellId, cd)
				else
					self:oRA3CD_CooldownReady(nil, guid, player, class, spellId)
					local charges = oRA3CD:GetCharges(guid, spellId)
					if charges > 0 then
						self:oRA3CD_UpdateCharges(nil, guid, player, class, spellId, 0, oRA3CD:GetRemainingCharges(guid, spellId), charges, true)
					end
				end
			end
		end
	else -- filtered!
		self:oRA3CD_StopCooldown(nil, guid)
	end
end

function prototype:UpdateCooldowns()
	self:UpdateLayout()
	local groupMembers = oRA3:GetGroupMembers()
	if not next(groupMembers) then groupMembers[1] = UnitName("player") end
	for _, player in next, groupMembers do
		local guid = UnitGUID(player)
		local _, class = UnitClass(player)
		self:UpdatePlayerCooldowns(guid, player, class)
	end
end

function prototype:OnSpellOptionChanged(spellId, value)
	if not value then
		self:oRA3CD_StopCooldown(nil, nil, spellId)
	end
	self:UpdateCooldowns()
end

function prototype:OnFilterOptionChanged(key, value)
	self:UpdateCooldowns()
end

local defaultDB = {
	barStyle = "Default",
	showOffCooldown = false,
	groupSpells = false,
	barScale = 1,
	barHeight = 14,
	barGap = 0,
	barFill = false,
	barGrowUp = false,
	barTexture = "oRA3",
	barClassColor = true,
	barColor = { 0.25, 0.33, 0.68, 1 },
	barColorBG = { 0.5, 0.5, 0.5, 0.3 },
	barColorStatus = true,
	barStatusColor = { 0.8, 0.8, 0.8, 0.2 },
	barShowIcon = true,
	barShowDuration = true,
	barShowUnit = true,
	barShowSpell = true,
	barShowStatus = false,
	barShorthand = false,
	barLabelAlign = "LEFT",
	barLabelClassColor = false,
	barLabelColor = { 1, 1, 1, 1 },
	barLabelFont = "Friz Quadrata TT",
	barLabelFontSize = 10,
	barLabelOutline = "NONE",
	barDurationAlign = "RIGHT",
	barDurationClassColor = false,
	barDurationColor = { 1, 1, 1, 1 },
	barDurationFont = "Friz Quadrata TT",
	barDurationFontSize = 10,
	barDurationOutline = "NONE",
}

local outlines = { NONE = NONE, OUTLINE = L.thin, THICKOUTLINE = L.thick }
local alignment = { LEFT = L.left, CENTER = L.center, RIGHT = L.right }

local function GetOptions(self, db)
	local options = {
		type = "group",
		get = function(info)
			local key = info[#info]
			if key == "barTexture" then
				for i, v in next, media:List("statusbar") do
					if v == db[key] then return i end
				end
			elseif key == "barLabelFont" or key == "barDurationFont" then
				for i, v in next, media:List("font") do
					if v == db[key] then return i end
				end
			elseif info.type == "color" then
				return unpack(db[key])
			end
			return db[key]
		end,
		set = function(info, value, g, b, a)
			local key = info[#info]
			if key == "barTexture" then
				local list = media:List("statusbar")
				db[key] = list[value]
			elseif key == "barLabelFont" or key == "barDurationFont" then
				local list = media:List("font")
				db[key] = list[value]
			elseif info.type == "color" then
				db[key] = {value, g, b, a or 1}
			else
				db[key] = value
			end
			if key == "showOffCooldown" then
				self:UpdateCooldowns()
			end
			self:UpdateLayout()
		end,
		args = {
			barStyle = {
				type = "select",
				name = L.style,
				values = oRA3CD:GetBarStyleList(),
				order = 1,
				width = "full",
			},
			showOffCooldown = {
				type = "toggle",
				name = L.showOffCooldown,
				order = 2,
				width = "full",
			},
			groupSpells = {
				type = "toggle",
				name = L.groupSpells,
				order = 3,
				width = "full",
			},
			barSettings = {
				type = "header",
				name = L.barSettings,
				order = 4,
			},
			barTexture = {
				type = "select",
				name = L.texture,
				values = media:List("statusbar"),
				itemControl = "DDI-Statusbar",
				order = 11,
				width = "full",
			},
			barClassColor = {
				type = "toggle",
				name = L.useClassColor,
				order = 12,
				width = "full",
			},
			barColor = {
				type = "color",
				name = L.customColor,
				disabled = function() return db.barClassColor end,
				order = 13,
				width = "full",
			},
			barColorBG = {
				type = "color", hasAlpha = true,
				name = L.backgroundColor,
				order = 14,
				width = "full",
			},
			barColorStatus = {
				type = "toggle",
				name = L.useStatusColor,
				desc = L.useStatusColorDesc,
				order = 14.5,
				width = "full",
			},
			barStatusColor = {
				type = "color", hasAlpha = true,
				name = L.statusColor,
				disabled = function() return not db.barColorStatus end,
				order = 14.6,
				width = "full",
			},
			barHeight = {
				type = "range",
				name = L.height,
				min = 8, max = 32, step = 1,
				order = 15,
				disabled = function() return db.barStyle ~= "Default" end,
				width = "full",
			},
			barGap = {
				type = "range",
				name = L.gap,
				min = 0, max = 5, step = 1,
				order = 16,
				disabled = function() return db.barStyle ~= "Default" end,
				width = "full",
			},
			barGrowUp = {
				type = "toggle",
				name = L.growUpwards,
				order = 17,
				width = "full",
			},
			barFill = {
				type = "toggle",
				name = L.fill,
				order = 18,
				width = "full",
			},
			show = {
				type = "group",
				name = L.show,
				inline = true,
				order = 19,
				args = {
					barShowIcon = {
						type = "toggle",
						name = L.icon,
						order = 1,
					},
					barShowUnit = {
						type = "toggle",
						name = L.unitName,
						order = 2,
					},
					barShowSpell = {
						type = "toggle",
						name = L.spellName,
						order = 3,
					},
					barShowDuration = {
						type = "toggle",
						name = L.duration,
						order = 4,
					},
					barShowStatus = {
						type = "toggle",
						name = L.playerStatus,
						order = 5,
					},
					barShorthand = {
						type = "toggle",
						name = L.shortSpellName,
						order = 6,
					},
				},
			},


			labelTextSettings = {
				type = "header",
				name = L.labelTextSettings,
				order = 20,
			},
			barLabelClassColor = {
				type = "toggle",
				name = L.useClassColor,
				disabled = function() return not db.barShowUnit and not db.barShowSpell end,
				order = 21,
				width = "full",
			},
			barLabelColor = {
				type = "color",
				name = L.customColor,
				disabled = function() return (not db.barShowUnit and not db.barShowSpell) or db.barLabelClassColor end,
				order = 22,
				width = "full",
			},
			barLabelFont = {
				type = "select",
				name = L.font,
				values = media:List("font"),
				itemControl = "DDI-Font",
				disabled = function() return not db.barShowUnit and not db.barShowSpell end,
				order = 23,
				width = "full",
			},
			barLabelFontSize = {
				type = "range",
				name = L.fontSize,
				softMax = 72, max = 200, min = 1, step = 1,
				disabled = function() return not db.barShowUnit and not db.barShowSpell end,
				order = 24,
				width = "full",
			},
			barLabelOutline = {
				type = "select",
				name = L.outline,
				values = outlines,
				disabled = function() return not db.barShowUnit and not db.barShowSpell end,
				order = 25,
				width = "full",
			},
			barLabelAlign = {
				type = "select",
				name = L.align,
				values = alignment,
				disabled = function() return not db.barShowUnit and not db.barShowSpell end,
				order = 26,
				width = "full",
			},


			durationTextSettings = {
				type = "header",
				name = L.durationTextSettings,
				order = 30,
			},
			barDurationClassColor = {
				type = "toggle",
				name = L.useClassColor,
				disabled = function() return not db.barShowDuration end,
				order = 31,
				width = "full",
			},
			barDurationColor = {
				type = "color",
				name = L.customColor,
				disabled = function() return not db.barShowDuration or db.barDurationClassColor end,
				order = 32,
				width = "full",
			},
			barDurationFont = {
				type = "select",
				name = L.font,
				values = media:List("font"),
				itemControl = "DDI-Font",
				disabled = function() return not db.barShowDuration end,
				order = 33,
				width = "full",
			},
			barDurationFontSize = {
				type = "range",
				name = L.fontSize,
				softMax = 72, max = 200, min = 1, step = 1,
				disabled = function() return not db.barShowDuration end,
				order = 34,
				width = "full",
			},
			barDurationOutline = {
				type = "select",
				name = L.outline,
				values = outlines,
				disabled = function() return not db.barShowDuration end,
				order = 35,
				width = "full",
			},
			barDurationAlign = {
				type = "select",
				name = L.align,
				values = alignment,
				disabled = function() return not db.barShowDuration or db.barStyle ~= "Default" end,
				order = 36,
				width = "full",
			},
		},
	}

	return options
end

---------------------------------------
-- API

local function New(name)
	local self = {}
	self.name = name
	self.type = DISPLAY_TYPE
	self.defaultDB = defaultDB
	self.bars = {}

	oRA3CD:AddContainer(self)

	for k, v in next, prototype do
		self[k] = v
	end

	self.RegisterEvent = oRA3.RegisterEvent
	self.UnregisterEvent = oRA3.UnregisterEvent
	self.UnregisterAllEvents = oRA3.UnregisterAllEvents

	oRA3CD.RegisterCallback(self, "OnStartup", "Show")
	oRA3CD.RegisterCallback(self, "OnShutdown", "Hide")
	oRA3CD.RegisterCallback(self, "oRA3CD_StartCooldown")
	oRA3CD.RegisterCallback(self, "oRA3CD_StopCooldown")
	oRA3CD.RegisterCallback(self, "oRA3CD_CooldownReady")
	oRA3CD.RegisterCallback(self, "oRA3CD_UpdateCharges")
	oRA3CD.RegisterCallback(self, "oRA3CD_UpdatePlayer")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateCooldowns") -- instance filter
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED", "UpdateCooldowns") -- role filter

	return self
end

oRA3CD:RegisterDisplayType(DISPLAY_TYPE, L.barDisplay, L.barDisplayDesc, DISPLAY_VERSION, New, GetOptions)
