
local addonName, scope = ...
local oRA3 = scope.addon
local module = oRA3:NewModule("Rings")
local oRA3CD = oRA3:GetModule("Cooldowns")
local L = scope.locale

local media = LibStub("LibSharedMedia-3.0")
local Masque = LibStub("Masque", true)

-- GLOBALS: ActionButton_ShowOverlayGlow ActionButton_HideOverlayGlow InterfaceOptionsFrame_OpenToCategory
-- GLOBALS: TANK HEALER DAMAGE RAID_CLASS_COLORS

---------------------------------------
-- Icons

local CreateIcon
do
	local function OnCooldownDone(self)
		local f = self:GetParent()
		if f.start then -- active finish
			ActionButton_HideOverlayGlow(f)
			f.start = nil
			self:SetReverse(false)
			self:SetCooldown(GetTime(), 105) -- 2min less the 15 duration
		else -- cd finish
			f.text:SetText(f.name)
		end
	end

	local function Start(self, player)
		local _, class = UnitClass(player)
		local color = class and RAID_CLASS_COLORS[class].colorStr or "ffcccccc"
		self.text:SetFormattedText("|c%s%s|r", color, player:gsub("%-.+", "*"))

		self.start = GetTime()
		self.cooldown:SetReverse(true)
		self.cooldown:SetCooldown(self.start, 15)
		ActionButton_ShowOverlayGlow(self)
	end

	function CreateIcon(name, parent, texture)
		local frameName = "oRA3RingsIcon"..name
		local f = CreateFrame("Button", frameName, parent)
		f:SetSize(64, 64)
		f:SetScale(1)
		f.name = name

		local icon = f:CreateTexture(frameName.."Icon", "BACKGROUND")
		icon:SetAllPoints()
		icon:SetTexture(texture)
		f.icon = icon

		local cooldown = CreateFrame("Cooldown", frameName.."Cooldown", f, "CooldownFrameTemplate")
		cooldown:SetAllPoints()
		cooldown:SetSwipeColor(1, 1, 1, 0.8)
		cooldown:SetHideCountdownNumbers(false)
		cooldown:SetDrawEdge(false)
		cooldown:SetDrawSwipe(true)
		cooldown:SetScript("OnCooldownDone", OnCooldownDone)
		f.cooldown = cooldown

		local text = f:CreateFontString(nil, "OVERLAY")
		text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		text:SetTextColor(1, 1, 1, 1)
		text:SetJustifyH("CENTER")
		text:SetJustifyV("TOP")
		text:SetPoint("TOPLEFT", f, "BOTTOMLEFT")
		text:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT")
		f.text = text

		f.Start = Start

		-- Masque skinning
		if module.group then
			module.group:AddButton(f)
		end

		f.text:SetText(name)

		return f
	end
end

---------------------------------------
-- Display

local display = {
	name = "Rings",
	type = "Rings",
	db = nil,
	icons = {},
}

do
	local rings = {
		[187616] = 3, -- Nithramus (int dps)
		[187617] = 1, -- Sanctus (tank)
		[187618] = 2, -- Etheralus (healer)
		[187619] = 3, -- Thorasus (str dps)
		[187620] = 3, -- Maalus (agi dps)
	}
	local throttle = {}

	local combatLogHandler = CreateFrame("Frame")
	combatLogHandler:SetScript("OnEvent", function(self, _, _, event, _, _, source, _, _, _, target, _, _, spellId, spellName)
		if event == "SPELL_AURA_APPLIED" and rings[spellId] then
			local ring = rings[spellId]
			local t = GetTime()
			if t > (throttle[ring] or 0) then
				throttle[ring] = t + 119
				display.icons[ring]:Start(source)
			end
		end
	end)

	function display:OnShow()
		combatLogHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:OnResize()
	end

	function display:OnHide()
		combatLogHandler:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		for _, icon in next, self.icons do
			icon.text:SetText(icon.name)
		end
		wipe(throttle)
	end
end

function display:OnSetup(frame)
	tinsert(self.icons, CreateIcon(TANK, frame, "Interface\\Icons\\inv_60legendary_ring1b"))
	tinsert(self.icons, CreateIcon(HEALER, frame, "Interface\\Icons\\inv_60legendary_ring1a"))
	tinsert(self.icons, CreateIcon(DAMAGER, frame, "Interface\\Icons\\inv_60legendary_ring1c"))

	frame:SetSize(200, 124)
	frame:SetMinResize(100, 20)
	frame.header:SetText(L.legendaryRings)
	frame:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" then
			InterfaceOptionsFrame_OpenToCategory(L.legendaryRings)
		end
	end)
end

function display:OnResize()
	if not self:IsShown() then return end

	if module.group then
		module.group:ReSkin()
	end

	local db = self.db

	local spacing = db.spacing
	local scale = db.scale

	-- right then down direction
	local anchor = "TOPLEFT"
	local point = "LEFT"
	local relativePoint, xRowDir, yRowDir = "RIGHT", 1, 0
	local columnPoint = "TOP"
	local columnRelativePoint, xColDir, yColDir = "BOTTOM", 0, -1

	local textHeight = db.showText and (db.fontSize * 1.025) or 0 -- just works! (instead of using fs:GetHeight)
	local size = 64 * scale + spacing
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
	for index = 1, #self.icons do
		local frame = self.icons[index]
		frame:ClearAllPoints()

		frame:SetScale(scale)
		frame.text:SetFont(media:Fetch("font", db.font), db.fontSize, db.fontOutline ~= "NONE" and db.fontOutline)
		frame.text:SetShown(db.showText)
		frame.cooldown:SetHideCountdownNumbers(not db.showCooldownText)

		local showIcon = (index == 1 and db.showTank) or (index == 2 and db.showHealer) or (index == 3 and db.showDamager)
		if showIcon then
			column = column + 1
			if column > iconsPerRow then
				row = row + 1
				column = 1
			end
		end

		if row > iconsPerColumn or not showIcon then
			frame:Hide()
		else
			if not last then
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

---------------------------------------
-- Options

local defaults = {
	profile = {
		showDisplay = true,
		lockDisplay = false,
		showTank = true,
		showHealer = true,
		showDamager = true,
		scale = 1,
		spacing = 2,
		showText = true,
		showCooldownText = true,
		font = "Friz Quadrata TT",
		fontSize = 11,
		fontOutline = "NONE"
	}
}
local function colorize(input) return ("|cfffed000%s|r"):format(input) end
local function GetOptions()
	local skinList = {}
	if Masque then
		local skins = Masque:GetSkins()
		for id in next, skins do
			skinList[id] = id
		end
	end

	local options = {
		type = "group",
		name = L.legendaryRings,
		get = function(info) return module.db.profile[info[#info]] end,
		set = function(info, value)
			local key = info[#info]
			module.db.profile[key] = value
			if key == "showDisplay" then
				if value then
					display:Show()
				else
					display:Hide()
				end
			elseif key == "lockDisplay" then
				if value then
					display:Lock()
				else
					display:Unlock()
				end
			else
				display:OnResize()
			end
		end,
		args = {
			showDisplay = {
				type = "toggle",
				name = colorize(L.showMonitor),
				desc = L.battleResShowDesc,
				width = "full",
				descStyle = "inline",
				order = 1,
			},
			lockDisplay = {
				type = "toggle",
				name = colorize(L.lockMonitor),
				desc = L.battleResLockDesc,
				width = "full",
				descStyle = "inline",
				order = 2,
			},
			show = {
				type = "group",
				name = L.showRings,
				inline = true,
				order = 5,
				args = {
					showTank = {
						type = "toggle",
						name = TANK,
						order = 1,
					},
					showHealer = {
						type = "toggle",
						name = HEALER,
						order = 2,
					},
					showDamager = {
						type = "toggle",
						name = DAMAGER,
						order = 3,
					},
				}
			},
			display = {
				type = "group",
				name = L.displaySettings,
				inline = true,
				order = 9,
				get = function(info)
					local key = info[#info]
					if key == "font" then
						for i, v in next, media:List("font") do
							if v == module.db.profile[key] then return i end
						end
					end
					return module.db.profile[key]
				end,
				set = function(info, value)
					local key = info[#info]
					if key == "font" then
						local list = media:List("font")
						module.db.profile[key] = list[value]
					else
						module.db.profile[key] = value
					end
					display:OnResize()
				end,
				args = {
					skin = {
						name = L.skin,
						type = "select",
						values = skinList,
						get = function(info) return module.group.db.SkinID or "Blizzard" end,
						set = function(info, value) module.group:SetOption("SkinID", value) end,
						order = 0,
						width = "full",
						hidden = not module.group,
					},
					scale = {
						name = L.scale,
						type = "range", min = 0.1, softMax = 10, step = 0.1,
						order = 1,
						width = "full",
					},
					spacing = {
						name = L.spacing,
						type = "range", min = -10, softMax = 10, step = 1,
						order = 2,
						width = "full",
					},
					showText = {
						type = "toggle",
						name = colorize(L.showText),
						desc = L.showTextDesc,
						descStyle = "inline",
						order = 4,
						width = "full",
					},
					showCooldownText = {
						type = "toggle",
						name = L.showCooldownText,
						desc = L.showCooldownTextDesc,
						order = 5,
						width = "full",
						disabled = function() return not GetCVarBool("countdownForCooldowns") end,
					},
					font = {
						type = "select",
						name = L.font,
						values = media:List("font"),
						itemControl = "DDI-Font",
						order = 6,
						width = "full",
						disabled = function() return not module.db.profile.showText end,
					},
					fontSize = {
						type = "range",
						name = L.fontSize,
						min = 6, max = 24, step = 1,
						order = 7,
						width = "full",
						disabled = function() return not module.db.profile.showText end,
					},
					fontOutline = {
						type = "select",
						name = L.outline,
						values = { NONE = NONE, OUTLINE = L.thin, THICKOUTLINE = L.thick },
						order = 8,
						width = "full",
						disabled = function() return not module.db.profile.showText end,
					},
				}
			}
		}
	}
	return options
end

function module:OnProfileUpdate()
	display.db = module.db.profile
	if display.db.showDisplay then
		display:Show()
	else
		display:Hide()
	end
	if display.db.lockDisplay then
		display:Lock()
	else
		display:Unlock()
	end
	display:OnResize()
end

function module:OnRegister()
	self.db = oRA3.db:RegisterNamespace("Rings", defaults)
	oRA3:RegisterModuleOptions("Rings", GetOptions, L.legendaryRings)
	oRA3.RegisterCallback(self, "OnProfileUpdate")
	oRA3.RegisterCallback(self, "OnStartup")
	oRA3.RegisterCallback(self, "OnShutdown")

	if Masque then
		module.group = Masque:Group("oRA3 Cooldowns", "Legendary Rings")
	end

	display.db = module.db.profile
	oRA3CD:AddContainer(display)
	display:Hide()
end

function module:OnStartup()
	display:Show()
end

function module:OnShutdown()
	display:Hide()
end

