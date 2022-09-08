
local DISPLAY_TYPE, DISPLAY_VERSION = "Icons", 1

local _, scope = ...
local oRA3 = scope.addon
local oRA3CD = oRA3:GetModule("Cooldowns")
local L = scope.locale
local classColors = oRA3.classColors

local media = LibStub("LibSharedMedia-3.0")
local Masque = LibStub("Masque", true)

---------------------------------------
-- Icon factory

local IconProvider = {}
do
	local base = CreateFrame("Button")
	local frame_mt = {__index = base}
	local prototype = setmetatable({}, frame_mt)
	local prototype_mt = {__index = prototype}

	IconProvider.callbacks = LibStub("CallbackHandler-1.0"):New(IconProvider)
	local callbacks = IconProvider.callbacks

	local pool = {}

	function prototype:Get(key)
		return self.userdata and self.userdata[key]
	end

	function prototype:Set(key, value)
		if not self.userdata then
			self.userdata = {}
		end
		self.userdata[key] = value
	end

	function prototype:SetIcon(icon)
		self.icon:SetTexture(icon)
	end

	function prototype:SetCount(value, ...)
		if select("#", ...) > 0 then
			self.count:SetFormattedText(value, ...)
		else
			self.count:SetText(value)
		end
	end

	function prototype:SetText(value)
		self.text:SetText(value)
	end

	function prototype:Start(remaining, duration)
		self.chargeCooldown:SetCooldown(0, 0)
		if remaining == 0 then -- :Stop() without the destruction
			self.cooldown:SetCooldown(0, 0)
		else
			local start = GetTime() - (duration - remaining)
			self.cooldown:SetCooldown(start, duration)
		end
	end

	function prototype:Stop()
		callbacks:Fire("IconProvider_Stop", self)

		if self.userdata then wipe(self.userdata) end
		self.cooldown:SetCooldown(0, 0)
		self.chargeCooldown:SetCooldown(0, 0)
		self:SetCount("")
		self:SetText("")
		self:Hide()
		self:ClearAllPoints()
		if self.group then
			self.group:RemoveButton(self)
			self.group = nil
		end
		self:SetParent(nil)

		tinsert(pool, self)
	end

	-- factory api
	local FRAME_COUNT = 0

	local function OnFinish(self)
		self:GetParent():Stop()
	end

	function IconProvider:New(parent)
		local f = tremove(pool)
		if not f then
			FRAME_COUNT = FRAME_COUNT + 1
			local frameName = "oRA3CooldownFrameIconsButton" .. FRAME_COUNT
			local frame = CreateFrame("Button", frameName)
			f = setmetatable(frame, prototype_mt)
			f:SetSize(36, 36)

			local icon = f:CreateTexture(frameName.."Icon", "BACKGROUND")
			icon:SetAllPoints()
			f.icon = icon

			local cooldown = CreateFrame("Cooldown", frameName.."Cooldown", f, "CooldownFrameTemplate")
			cooldown:SetAllPoints()
			cooldown:SetSwipeColor(1, 1, 1, 0.8)
			cooldown:SetHideCountdownNumbers(false)
			cooldown:SetDrawEdge(false)
			cooldown:SetDrawSwipe(true)
			cooldown:SetScript("OnCooldownDone", OnFinish)
			f.cooldown = cooldown

			local chargeCooldown = CreateFrame("Cooldown", frameName.."ChargeCooldown", f, "CooldownFrameTemplate")
			chargeCooldown:SetAllPoints()
			chargeCooldown:SetFrameStrata("TOOLTIP")
			chargeCooldown:SetHideCountdownNumbers(true)
			chargeCooldown:SetDrawEdge(true)
			chargeCooldown:SetDrawSwipe(false)
			f.chargeCooldown = chargeCooldown

			local count = f:CreateFontString(frameName.."Count", "ARTWORK", "NumberFontNormal")
			count:SetPoint("BOTTOMRIGHT", -2, 2)
			count:SetJustifyH("RIGHT")
			f.count = count

			local text = f:CreateFontString(nil, "OVERLAY")
			text:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
			text:SetJustifyH("CENTER")
			text:SetJustifyV("TOP")
			text:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
			text:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT")
			f.text = text
		end

		f:SetParent(parent.frame)
		f:SetSize(36, 36)
		f:SetScale(1)

		-- Masque skinning
		if parent.group then
			f.group = parent.group
			f.group:AddButton(f)
		end

		return f
	end
end

---------------------------------------
-- Display

local prototype = {}

function prototype:OnHide()
	for icon in next, self.icons do
		icon:Set("ora3cd:testunit", nil) -- don't restart bars during shutdown
		icon:Stop()
	end
end

function prototype:OnResize()
	self:UpdateLayout()
end

function prototype:OnDelete()
	oRA3CD.UnregisterAllCallbacks(self)
	IconProvider.UnregisterAllCallbacks(self)
	if self.group then
		self.group:Delete()
	end
end

do
	local DIRECTION_TO_ANCHOR_POINT = {
		down_right = "TOPLEFT",
		down_left = "TOPRIGHT",
		up_right = "BOTTOMLEFT",
		up_left = "BOTTOMRIGHT",
		right_down = "TOPLEFT",
		right_up = "BOTTOMLEFT",
		left_down = "TOPRIGHT",
		left_up = "BOTTOMRIGHT",
	}
	local DIRECTION_TO_POINT = {
		down_right = "TOP",
		down_left = "TOP",
		up_right = "BOTTOM",
		up_left = "BOTTOM",
		right_down = "LEFT",
		right_up = "LEFT",
		left_down = "RIGHT",
		left_up = "RIGHT",
	}
	local DIRECTION_TO_COLUMN_ANCHOR_POINT = {
		down_right = "LEFT",
		down_left = "RIGHT",
		up_right = "LEFT",
		up_left = "RIGHT",
		right_down = "TOP",
		right_up = "BOTTOM",
		left_down = "TOP",
		left_up = "BOTTOM",
	}

	local function getRelativePoint(point)
		if point == "TOP" then
			return "BOTTOM", 0, -1
		elseif point == "BOTTOM" then
			return "TOP", 0, 1
		elseif point == "LEFT" then
			return "RIGHT", 1, 0
		elseif point == "RIGHT" then
			return "LEFT", -1, 0
		end
	end

	local function sortByClass(a, b) -- class > spell name
		if a:Get("ora3cd:class") == b:Get("ora3cd:class") then
			return a:Get("ora3cd:spell") < b:Get("ora3cd:spell")
		else
			return a:Get("ora3cd:class") < b:Get("ora3cd:class")
		end
	end

	local tmp = {}
	function prototype:RearrangeIcons()
		if not self:IsShown() then return end

		wipe(tmp)
		for icon in next, self.icons do
			tmp[#tmp + 1] = icon
		end
		sort(tmp, sortByClass)

		if self.group then
			self.group:ReSkin()
		end

		local db = self.db

		local spacing = db.spacing
		local scale = db.scale
		local direction = db.direction
		local anchor = DIRECTION_TO_ANCHOR_POINT[direction]

		local point = DIRECTION_TO_POINT[direction]
		local relativePoint, xRowDir, yRowDir = getRelativePoint(point)

		local columnPoint = DIRECTION_TO_COLUMN_ANCHOR_POINT[direction]
		local columnRelativePoint, xColDir, yColDir = getRelativePoint(columnPoint)

		local textHeight = db.showText and (db.fontSize * 1.025) or 0 -- just works! (instead of using fs:GetHeight)
		local size = 36 * scale + spacing
		local iconsPerRow, iconsPerColumn
		if point == "LEFT" or point == "RIGHT" then
			iconsPerRow = floor(self:GetWidth() / size)
			iconsPerColumn = floor(self:GetHeight() / (size + textHeight))
		else
			iconsPerRow = floor(self:GetHeight() / size)
			iconsPerColumn = floor(self:GetWidth() / (size + textHeight))
		end

		local last, columnAnchor = nil, nil
		local row, column = 1, 0
		for index, frame in next, tmp do
			column = column + 1
			if column > iconsPerRow then
				row = row + 1
				column = 1
			end

			frame:ClearAllPoints()

			-- restyle the frame
			frame:SetScale(scale)
			frame.text:SetFont(media:Fetch("font", db.font), db.fontSize, db.fontOutline ~= "NONE" and db.fontOutline)
			if not db.showText then
				frame.text:Hide()
			else
				if db.textClassColor then
					local classColor = classColors[frame:Get("ora3cd:class")]
					frame.text:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
				else
					local r, g, b = unpack(db.textColor)
					frame.text:SetTextColor(r, g, b, 1)
				end
				frame.text:Show()
			end
			frame.cooldown:SetHideCountdownNumbers(not db.showCooldownText)

			if row > iconsPerColumn then
				frame:Hide()
			else
				if index == 1 then
					frame:SetPoint(anchor, self:GetContainer(), anchor, 0, 0)
					columnAnchor = frame
				elseif column == 1 then
					frame:SetPoint(columnPoint, columnAnchor, columnRelativePoint, xColDir * spacing, yColDir * (spacing + textHeight))
					columnAnchor = frame
				else
					frame:SetPoint(point, last, relativePoint, xRowDir * spacing, yRowDir * (spacing + textHeight))
				end

				last = frame
				frame:Show()
			end
		end
	end
end

function prototype:UpdateLayout()
	if not next(self.icons) then return end
	for frame in next, self.icons do
		if (not frame:Get("ora3cd:testunit") and not oRA3CD:CheckFilter(self, frame:Get("ora3cd:player"))) or (not self.db.showOffCooldown and frame:Get("ora3cd:ready")) then
			frame:Stop()
		end
	end
	self:RearrangeIcons()
end

function prototype:IconProvider_Stop(_, frame)
	if frame:Get("ora3cd:display") == self then
		self.icons[frame] = nil
		self:UpdateLayout()

		-- show test bars as ready for a bit then hide them
		if self.db.showOffCooldown and frame:Get("ora3cd:testunit") and not frame:Get("ora3cd:ready") then
			local player, spellId = frame:Get("ora3cd:player"), frame:Get("ora3cd:spellid")
			self:CooldownReady(player, player, frame:Get("ora3cd:class"), spellId)
			C_Timer.After(20, function()
				local icon = self:GetCD(player, spellId)
				if icon and icon:Get("ora3cd:ready") then
					icon:Stop()
				end
			end)
		end
	end
end

function prototype:GetCD(guid, spellId)
	for frame in next, self.icons do
		if frame:Get("ora3cd:guid") == guid and frame:Get("ora3cd:spellid") == spellId then
			return frame
		end
	end
end

---------------------------------------
-- Icons

function prototype:TestCooldown(player, class, spellId, remaining)
	if not self.db.showDisplay then return end
	self:Setup()

	local frame = self:GetCD(player, spellId) or IconProvider:New(self)
	self.icons[frame] = true

	local spell, _, icon = GetSpellInfo(spellId)
	frame:Set("ora3cd:guid", player)
	frame:Set("ora3cd:player", player)
	frame:Set("ora3cd:class", class)
	frame:Set("ora3cd:icon", icon)
	frame:Set("ora3cd:spell", spell)
	frame:Set("ora3cd:spellid", spellId)
	frame:Set("ora3cd:display", self)
	frame:Set("ora3cd:testunit", true)

	frame:SetIcon(icon)
	frame:SetText(player)
	frame:Start(remaining, remaining)
	self:UpdateLayout()
end

function prototype:oRA3CD_StartCooldown(_, guid, player, class, spellId, remaining)
	if not self.db.showDisplay then return end
	if not self.spellDB[spellId] or not oRA3CD:CheckFilter(self, player) then return end
	self:Setup()

	local frame = self:GetCD(guid, spellId) or IconProvider:New(self)
	self.icons[frame] = true

	local duration = oRA3CD:GetCooldown(guid, spellId)
	local spell, _, icon = GetSpellInfo(spellId)
	frame:Set("ora3cd:guid", guid)
	frame:Set("ora3cd:player", player)
	frame:Set("ora3cd:class", class)
	frame:Set("ora3cd:icon", icon)
	frame:Set("ora3cd:spell", spell)
	frame:Set("ora3cd:spellid", spellId)
	frame:Set("ora3cd:display", self)

	frame:SetIcon(icon)
	frame:SetText(player)
	frame:Start(remaining, duration)
	self:UpdateLayout()
end

function prototype:oRA3CD_CooldownReady(_, guid, player, class, spellId)
	if not self.spellDB[spellId] or not oRA3CD:CheckFilter(self, player) then return end
	self:CooldownReady(guid, player, class, spellId)
end

function prototype:CooldownReady(guid, player, class, spellId)
	if not self.db.showDisplay or not self.db.showOffCooldown then return end
	self:Setup()

	local frame = self:GetCD(guid, spellId) or IconProvider:New(self)
	self.icons[frame] = true

	local spell, _, icon = GetSpellInfo(spellId)
	frame:Set("ora3cd:guid", guid)
	frame:Set("ora3cd:player", player)
	frame:Set("ora3cd:class", class)
	frame:Set("ora3cd:icon", icon)
	frame:Set("ora3cd:spell", spell)
	frame:Set("ora3cd:spellid", spellId)
	frame:Set("ora3cd:display", self)
	frame:Set("ora3cd:testunit", guid == player)
	frame:Set("ora3cd:ready", true)

	frame:SetIcon(icon)
	frame:SetText(player)
	frame:Start(0)
	self:UpdateLayout()
end

function prototype:oRA3CD_UpdateCharges(_, guid, player, class, spellId, remaining, charges, maxCharges)
	if not self.db.showDisplay then return end

	local frame = self:GetCD(guid, spellId)
	if not frame then return end

	frame:Set("ora3cd:ready", charges > 0)
	frame:SetCount(charges)
	if 0 < charges and charges < maxCharges then
		local duration = oRA3CD:GetCooldown(guid, spellId)
		local start = GetTime() - (duration - remaining)
		frame.chargeCooldown:SetCooldown(start, duration)
	end
end

function prototype:oRA3CD_StopCooldown(_, guid, spellId)
	if not self.db.showDisplay then return end
	for frame in next, self.icons do
		if guid and spellId then
			if frame:Get("ora3cd:spellid") == spellId and frame:Get("ora3cd:guid") == guid then
				frame:Stop()
			end
		elseif frame:Get("ora3cd:spellid") == spellId or frame:Get("ora3cd:guid") == guid then
			frame:Stop()
		end
	end
end

function prototype:oRA3CD_UpdatePlayer(_, guid)
	for frame in next, self.icons do
		if frame:Get("ora3cd:guid") == guid and not oRA3CD:CheckFilter(self, frame:Get("ora3cd:player")) then
			frame:Stop()
		end
	end
	self:UpdatePlayerCooldowns(guid, oRA3CD:GetPlayerFromGUID(guid))
end

---------------------------------------
-- Options

function prototype:UpdatePlayerCooldowns(guid, player, class)
	if oRA3CD:CheckFilter(self, player) then
		for spellId in next, self.spellDB do
			if not self:GetCD(guid, spellId) and oRA3CD:IsSpellUsable(guid, spellId) then
				local cd = oRA3CD:GetRemainingCooldown(guid, spellId)
				if cd > 0 then
					self:oRA3CD_StartCooldown(nil, guid, player, class, spellId, cd)
				else
					self:oRA3CD_CooldownReady(nil, guid, player, class, spellId)
					local charges = oRA3CD:GetCharges(guid, spellId)
					if charges > 0 then
						self:oRA3CD_UpdateCharges(nil, guid, player, class, spellId, oRA3CD:GetRemainingChargeCooldown(guid, spellId), oRA3CD:GetRemainingCharges(guid, spellId), charges, true)
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
	showOffCooldown = false,
	scale = 1,
	spacing = 2,
	direction = "right_down",
	showCooldownText = true,
	showText = true,
	classColor = false,
	textClassColor = false,
	textColor = { 1, 1, 1, 1 },
	font = "Friz Quadrata TT",
	fontSize = 8,
	fontOutline = "NONE"
}

local function GetOptions(self, db)
	local skinList = {}
	if Masque then
		local skins = Masque:GetSkins()
		for id in next, skins do
			skinList[id] = id
		end
	end

	local countdownForCooldowns = GetCVarBool("countdownForCooldowns")

	local options = {
		type = "group",
		get = function(info)
			local key = info[#info]
			if info.type == "color" then
				return unpack(db[key])
			elseif key == "font" then
				for i, v in next, media:List("font") do
					if v == db[key] then return i end
				end
			end
			return db[key]
		end,
		set = function(info, value, g, b, a)
			local key = info[#info]
			if info.type == "color" then
				db[key] = {value, g, b, a or 1}
			elseif key == "font" then
				local list = media:List("font")
				db[key] = list[value]
			else
				db[key] = value
			end
			if key == "showOffCooldown" then
				self:UpdateCooldowns()
			end
			self:UpdateLayout()
		end,
		args = {
			skin = {
				name = L.skin,
				type = "select",
				values = skinList,
				get = function(info) return self.group.db.SkinID or "Blizzard" end,
				set = function(info, value) self.group:SetOption("SkinID", value) end,
				order = 0,
				width = "full",
				hidden = not self.group,
			},
			classColor = {
				name = L.classColorBorder,
				type = "toggle",
				order = 0.1,
				width = "full",
				hidden = not self.group,
			},
			showOffCooldown = {
				type = "toggle",
				name = L.showOffCooldown,
				order = 0.2,
				width = "full",
			},
			direction = {
				name = L.direction,
				type = "select",
				values = {
					down_right = L.directionThen:format(L.down, L.right),
					down_left = L.directionThen:format(L.down, L.left),
					up_right = L.directionThen:format(L.up, L.right),
					up_left = L.directionThen:format(L.up, L.left),
					right_down = L.directionThen:format(L.right, L.down),
					right_up = L.directionThen:format(L.right, L.up),
					left_down = L.directionThen:format(L.left, L.down),
					left_up = L.directionThen:format(L.left, L.up),
				},
				order = 1,
				width = "full",
			},
			spacing = {
				name = L.spacing,
				type = "range", min = -10, softMax = 10, step = 1,
				order = 2,
				width = "full",
			},
			scale = {
				name = L.scale,
				type = "range", min = 0.1, softMax = 10, step = 0.1,
				order = 3,
				width = "full",
			},
			showCooldownText = {
				name = L.showCooldownText,
				desc = L.showCooldownTextDesc,
				descStyle = not countdownForCooldowns and "inline" or nil,
				type = "toggle",
				order = 4,
				width = "full",
				disabled = not countdownForCooldowns,
			},


			textSettings = {
				type = "header",
				name = L.labelTextSettings,
				order = 9,
			},
			showText = {
				type = "toggle",
				name = "Show player name",
				order = 10,
				width = "full",
			},
			textClassColor = {
				type = "toggle",
				name = L.useClassColor,
				order = 11,
				width = "full",
				disabled = function() return not db.showText end,
			},
			textColor = {
				type = "color",
				name = L.customColor,
				disabled = function() return not db.showText or db.textClassColor end,
				order = 12,
				width = "full",
			},
			font = {
				type = "select",
				name = L.font,
				values = media:List("font"),
				itemControl = "DDI-Font",
				order = 13,
				width = "full",
				disabled = function() return not db.showText end,
			},
			fontSize = {
				type = "range",
				name = L.fontSize,
				softMax = 72, max = 200, min = 1, step = 1,
				order = 14,
				width = "full",
				disabled = function() return not db.showText end,
			},
			fontOutline = {
				type = "select",
				name = L.outline,
				values = { NONE = NONE, OUTLINE = L.thin, THICKOUTLINE = L.thick },
				order = 15,
				width = "full",
				disabled = function() return not db.showText end,
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
	self.icons = {}

	oRA3CD:AddContainer(self)

	for k, v in next, prototype do
		self[k] = v
	end

	oRA3CD.RegisterCallback(self, "OnStartup", "Show")
	oRA3CD.RegisterCallback(self, "OnShutdown", "Hide")
	oRA3CD.RegisterCallback(self, "oRA3CD_StartCooldown")
	oRA3CD.RegisterCallback(self, "oRA3CD_StopCooldown")
	oRA3CD.RegisterCallback(self, "oRA3CD_CooldownReady")
	oRA3CD.RegisterCallback(self, "oRA3CD_UpdateCharges")
	oRA3CD.RegisterCallback(self, "oRA3CD_UpdatePlayer")

	IconProvider.RegisterCallback(self, "IconProvider_Stop")

	if Masque then
		self.group = Masque:Group("oRA3 Cooldowns", self.name)
		Masque:Register("oRA3 Cooldowns", function(_, group, skin)
			-- update the border color if enabled
			if group == self.name and self.db.classColor then
				for frame in next, self.icons do
					local color = classColors[frame:Get("ora3cd:class")]
					Masque:GetNormal(frame):SetVertexColor(color.r, color.g, color.b)
				end
			end
		end, self.name)
	end

	return self
end

oRA3CD:RegisterDisplayType(DISPLAY_TYPE, L.iconDisplay, L.iconDisplayDesc, DISPLAY_VERSION, New, GetOptions)
