
local DISPLAY_TYPE, DISPLAY_VERSION = "Icon Groups", 1

local _, scope = ...
local oRA3 = scope.addon
local oRA3CD = oRA3:GetModule("Cooldowns")
local L = scope.locale
local classColors = oRA3.classColors

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

	function prototype:SetIcon(texture)
		self.icon:SetTexture(texture)
	end

	function prototype:SetCount(value, ...)
		if select("#", ...) > 0 then
			self.count:SetFormattedText(value, ...)
		else
			self.count:SetText(value)
		end
	end

	function prototype:Start(remaining, duration)
		local start = GetTime() - (duration - remaining)
		self.cooldown:SetCooldown(start, duration)
	end

	function prototype:Stop()
		self.cooldown:SetCooldown(0, 0)
	end

	function prototype:Remove()
		callbacks:Fire("IconProvider_Stop", self)

		self:Stop()
		if self.userdata then wipe(self.userdata) end
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

	local function OnEnter(self)
		if self.UpdateTooltip then
			self:UpdateTooltip()
		end
	end

	function IconProvider:New(parent)
		local f = tremove(pool)
		if not f then
			FRAME_COUNT = FRAME_COUNT + 1
			local frameName = "oRA3CooldownFrameIconGroupButton" .. FRAME_COUNT
			local frame = CreateFrame("Button", frameName)
			f = setmetatable(frame, prototype_mt)
			f:SetSize(36, 36)
			f:SetScript("OnEnter", OnEnter)
			f:SetScript("OnLeave", GameTooltip_Hide)

			local icon = f:CreateTexture(frameName.."Icon", "BACKGROUND")
			icon:SetAllPoints()
			f.icon = icon

			local count = f:CreateFontString(frameName.."Count", "ARTWORK", "NumberFontNormal")
			count:SetPoint("BOTTOMRIGHT", -2, 2)
			count:SetJustifyH("RIGHT")
			f.count = count

			local cooldown = CreateFrame("Cooldown", frameName.."Cooldown", f, "CooldownFrameTemplate")
			cooldown:SetAllPoints()
			cooldown:SetSwipeColor(1, 1, 1, 0.8)
			cooldown:SetHideCountdownNumbers(true)
			cooldown:SetDrawEdge(false)
			cooldown:SetDrawSwipe(true)
			cooldown:SetScript("OnCooldownDone", OnFinish)
			f.cooldown = cooldown
		end

		f:SetParent(parent:GetContainer())
		f:SetSize(36, 36)
		f:SetScale(1)
		f:SetIcon("inv_misc_questionmark")
		f:SetCount("")

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
	for _, icon in next, self.icons do
		icon:Remove()
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

---------------------------------------
-- Icons

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
	function prototype:UpdateLayout()
		wipe(tmp)
		for _, icon in next, self.icons do
			tmp[#tmp + 1] = icon
		end
		if #tmp == 0 then return end
		sort(tmp, sortByClass)

		if self.group then
			self.group:ReSkin()
		end

		local spacing = self.db.spacing
		local scale = self.db.scale
		local direction = self.db.direction
		local anchor = DIRECTION_TO_ANCHOR_POINT[direction]

		local point = DIRECTION_TO_POINT[direction]
		local relativePoint, xRowDir, yRowDir = getRelativePoint(point)

		local columnPoint = DIRECTION_TO_COLUMN_ANCHOR_POINT[direction]
		local columnRelativePoint, xColDir, yColDir = getRelativePoint(columnPoint)

		local size = 36 * scale + spacing
		local iconsPerRow, iconsPerColumn
		if point == "LEFT" or point == "RIGHT" then
			iconsPerRow = floor(self:GetWidth() / size)
			iconsPerColumn = floor(self:GetHeight() / size)
		else
			iconsPerRow = floor(self:GetHeight() / size)
			iconsPerColumn = floor(self:GetWidth() / size)
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
			frame:SetScale(scale)
			frame.cooldown:SetHideCountdownNumbers(not self.db.showCooldownText)

			if row > iconsPerColumn then
				frame:Hide()
			else
				if index == 1 then
					frame:SetPoint(anchor, self:GetContainer(), anchor, 0, 0)
					columnAnchor = frame
				elseif column == 1 then
					frame:SetPoint(columnPoint, columnAnchor, columnRelativePoint, xColDir * spacing, yColDir * spacing)
					columnAnchor = frame
				else
					frame:SetPoint(point, last, relativePoint, xRowDir * spacing, yRowDir * spacing)
				end

				last = frame
				frame:Show()
			end
		end
	end
end

local function UpdateTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(self:Get("ora3cd:spell"))

	local spellId = self:Get("ora3cd:spellid")
	for guid, player in next, self:Get("ora3cd:players") do
		local ready = READY
		if oRA3CD:GetPlayerFromGUID(guid) then
			local cd = oRA3CD:GetRemainingCooldown(guid, spellId)
			local maxCharges = oRA3CD:GetCharges(guid, spellId)
			if cd == 0 and maxCharges > 0 then
				local charges = oRA3CD:GetRemainingCharges(guid, spellId)
				if charges < maxCharges then
					local chargeRemaining = oRA3CD:GetRemainingChargeCooldown(guid, spellId)
					ready = ("(%d) %s |cffff7f3f%s|r"):format(charges, ready, SecondsToTime(chargeRemaining, nil, nil, 2, true))
				else
					ready = ("(%d) %s"):format(charges, ready)
				end
			end
			local status = not UnitIsConnected(player) and L.offline or UnitIsDeadOrGhost(player) and L.dead or (IsInGroup() and not UnitInRange(player)) and L.range
			if status then
				GameTooltip:AddDoubleLine(
					("%s (%s)"):format(player:gsub("-.*", ""), status), cd == 0 and ready or ("|cffff2020%s|r"):format(SecondsToTime(cd, nil, nil, 2, true)),
					0.8, 0.8, 0.8, 0.8, 0.8, 0.8
				)
			else
				GameTooltip:AddDoubleLine(
					player:gsub("-.*", ""), cd == 0 and ("|cff20ff20%s|r"):format(ready) or ("|cffff2020%s|r"):format(SecondsToTime(cd, nil, nil, 2, true)),
					1, 1, 1, 1, 1, 1
				)
			end
		end
	end

	GameTooltip:Show()
end

local function CreateIcon(parent, class, spellId)
	local icon = IconProvider:New(parent)
	icon.UpdateTooltip = UpdateTooltip

	local spell, _, texture = GetSpellInfo(spellId)
	icon:Set("ora3cd:class", class)
	icon:Set("ora3cd:icon", texture)
	icon:Set("ora3cd:spell", spell)
	icon:Set("ora3cd:spellid", spellId)
	icon:Set("ora3cd:display", parent)
	icon:Set("ora3cd:players", {})

	icon:SetIcon(texture)
	icon:SetCount("")

	return icon
end

function prototype:Update(icon)
	local players = icon:Get("ora3cd:players")
	if not next(players) then
		icon:Remove()
		return
	end

	local spellId = icon:Get("ora3cd:spellid")
	local available, cd = 0, nil

	for guid, player in next, players do
		if UnitIsConnected(player) and not UnitIsDeadOrGhost(player) and (not IsInGroup() or UnitIsVisible(player)) then
			local remaining = oRA3CD:GetRemainingCooldown(guid, spellId)
			if remaining == 0 then
				local charges = oRA3CD:GetRemainingCharges(guid, spellId)
				if charges == 0 then charges = 1 end
				available = available + charges
			elseif not cd or remaining < cd then
				cd = remaining
			end
		end
	end

	if available == 0 then
		if cd then
			local duration = oRA3CD.allSpells[spellId][1] -- use the base cd
			icon:Start(cd, duration)
		end
		icon.icon:SetDesaturated(not cd)
	else
		icon:Stop()
		icon.icon:SetDesaturated(false)
	end
	icon:SetCount(available > 0 and available or "")
end

function prototype:IconProvider_Stop(_, frame)
	if frame:Get("ora3cd:display") == self then
		local spellId = frame:Get("ora3cd:spellid")
		self.icons[spellId] = nil
		self:UpdateLayout()
	end
end

---------------------------------------
-- Callbacks

--[[
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
	frame:Set("ora3cd:spellid", spellId)
	frame:Set("ora3cd:display", self)
	frame:Set("ora3cd:testunit", true)

	frame:SetIcon(icon)
	frame:SetDuration(remaining)
	frame:Start()
	self:UpdateLayout()
end
--]]

function prototype:UpdateCooldown(event, guid, player, class, spellId)
	if not self.db.showDisplay then return end
	if not self.spellDB[spellId] or not oRA3CD:CheckFilter(self, player) then return end
	self:Setup()

	local icon = self.icons[spellId]
	if not icon then
		icon = CreateIcon(self, class, spellId)
		self.icons[spellId] = icon
		self:UpdateLayout()
	end

	local players = icon:Get("ora3cd:players")
	players[guid] = player

	self:Update(icon)
end

function prototype:oRA3CD_UpdatePlayer(_, guid, player)
	if not self.db.showDisplay then return end

	if oRA3CD:CheckFilter(self, player) then
		for spellId, icon in next, self.icons do
			local players = icon:Get("ora3cd:players")
			if players[guid] then
				self:Update(icon)
			end
		end
	else -- filtered
		self:oRA3CD_StopCooldown(nil, guid)
	end
end

function prototype:oRA3CD_StopCooldown(_, guid, spellId)
	if not self.db.showDisplay then return end
	if spellId and (not self.spellDB[spellId] or not self.icons[spellId]) then return end

	local icon = self.icons[spellId]
	if icon then
		if not guid then
			icon:Remove()
		else
			local players = icon:Get("ora3cd:players")
			if players[guid] then
				players[guid] = nil
				self:Update(icon)
			end
		end
	else
		-- no spellId, check all icons
		for spell, frame in next, self.icons do
			local players = frame:Get("ora3cd:players")
			if players[guid] then
				players[guid] = nil
				self:Update(frame)
			end
		end
	end
end

---------------------------------------
-- Options

function prototype:UpdateCooldowns()
	local groupMembers = oRA3:GetGroupMembers()
	if not next(groupMembers) then groupMembers[1] = UnitName("player") end
	for _, player in next, groupMembers do
		local guid = UnitGUID(player)
		if oRA3CD:CheckFilter(self, player) then
			local _, class = UnitClass(player)
			for spellId in next, self.spellDB do
				if oRA3CD:IsSpellUsable(guid, spellId) then
					self:UpdateCooldown(nil, guid, player, class, spellId)
				end
			end
		else -- filtered
			self:oRA3CD_StopCooldown(nil, guid)
		end
	end
end

function prototype:OnSpellOptionChanged(spellId, value)
	if not value and self.icons[spellId] then
		self.icons[spellId]:Remove()
	end
	self:UpdateCooldowns()
end

function prototype:OnFilterOptionChanged(key, value)
	self:UpdateCooldowns()
end

local defaultDB = {
	scale = 1,
	spacing = 2,
	direction = "right_down",
	classColor = false,
	showCooldownText = true,
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
			end
			return db[key]
		end,
		set = function(info, value, g, b, a)
			local key = info[#info]
			if info.type == "color" then
				db[key] = {value, g, b, a or 1}
			else
				db[key] = value
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
				order = 0.5,
				width = "full",
				hidden = not self.group,
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
	oRA3CD.RegisterCallback(self, "oRA3CD_StartCooldown", "UpdateCooldown")
	oRA3CD.RegisterCallback(self, "oRA3CD_CooldownReady", "UpdateCooldown")
	oRA3CD.RegisterCallback(self, "oRA3CD_UpdateCharges", "UpdateCooldown")
	oRA3CD.RegisterCallback(self, "oRA3CD_UpdatePlayer")
	oRA3CD.RegisterCallback(self, "oRA3CD_StopCooldown")

	IconProvider.RegisterCallback(self, "IconProvider_Stop")

	if Masque then
		self.group = Masque:Group("oRA3 Cooldowns", self.name)
		Masque:Register("oRA3 Cooldowns", function(_, group, skin)
			-- update the border color if enabled
			if group == self.name and self.db.classColor then
				for _, frame in next, self.icons do
					local color = classColors[frame:Get("ora3cd:class")]
					Masque:GetNormal(frame):SetVertexColor(color.r, color.g, color.b)
				end
			end
		end, self.name)
	end

	return self
end

oRA3CD:RegisterDisplayType(DISPLAY_TYPE, L.iconGroupDisplay, L.iconGroupDisplayDesc, DISPLAY_VERSION, New, GetOptions)
