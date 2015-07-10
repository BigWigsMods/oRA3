
local DISPLAY_TYPE, DISPLAY_VERSION = "Log", 1

local _, scope = ...
local oRA3 = scope.addon
local L = scope.locale
local oRA3CD = oRA3:GetModule("Cooldowns")

local media = LibStub("LibSharedMedia-3.0")

-- GLOBALS: ChatFontNormal GameTooltip GameTooltip_Hide RAID_CLASS_COLORS

---------------------------------------
-- Display

local prototype = {}

function prototype:OnHide()
	self.scroll:Clear()
end

function prototype:OnSetup(frame)
	if not frame.scroll then
		local scroll = CreateFrame("ScrollingMessageFrame", frame:GetName().."Text", frame)
		scroll:SetAllPoints()
		scroll:SetInsertMode("TOP")
		scroll:SetFading(true)
		scroll:SetFadeDuration(0.2)
		scroll:SetIndentedWordWrap(true)
		scroll:SetHyperlinksEnabled(true)
		scroll:SetMaxLines(128)
		scroll:SetFontObject(ChatFontNormal)
		scroll:SetJustifyH("LEFT")
		scroll:SetScript("OnHyperlinkEnter", function(self, link)
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		end)
		scroll:SetScript("OnHyperlinkLeave",  GameTooltip_Hide)
		frame.scroll = scroll
	end
	self.scroll = frame.scroll

	frame:SetWidth(400)
	frame:SetHeight(140)

	self:UpdateLayout()
end

function prototype:OnDelete()
	oRA3CD.UnregisterAllCallbacks(self)
end

function prototype:UpdateLayout()
	if not self:IsShown() then return end

	local db = self.db
	local scroll = self.scroll
	scroll:Clear()
	scroll:SetInsertMode(db.direction)
	scroll:SetTimeVisible(db.timeVisible)
	scroll:SetFading(db.timeVisible > 0)
	scroll:SetHyperlinksEnabled(db.tooltips)
	scroll:SetFont(media:Fetch("font", db.font), db.fontSize)
	scroll:SetJustifyH(db.justify)
end

---------------------------------------
-- Text

function prototype:AddMessage(player, class, spellId)
	if not self.db.showDisplay then return end
	self:Setup()

	local classColor = RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr or "ffcccccc"
	local icon = GetSpellTexture(spellId)
	local link = GetSpellLink(spellId)
	local timestamp = self.db.timestamp and date("|cffcccccc[%H:%M:%S] ") or ""
	local text = ("%s|c%s%s|r used |T%s:0:0:0:0:64:64:4:60:4:60|t%s"):format(timestamp, classColor, player, icon, link)
	self.scroll:AddMessage(text, 1, 1, 1, 1)
end

function prototype:oRA3CD_StartCooldown(_, guid, player, class, spellId, duration)
	if self.spellDB[spellId] and duration == oRA3CD:GetCooldown(guid, spellId) and oRA3CD:CheckFilter(self, player) then
		self:AddMessage(player, class, spellId)
	end
end

function prototype:oRA3CD_UpdateCharges(_, guid, player, class, spellId, duration, charges, maxCharges, ready)
	if not ready and charges > 0 and self.spellDB[spellId] and oRA3CD:CheckFilter(self, player) then
		self:AddMessage(player, class, spellId)
	end
end

function prototype:TestCooldown(player, class, spellId, duration)
	self:AddMessage(player, class, spellId)
end

---------------------------------------
-- Options

local defaultDB = {
	font = "Friz Quadrata TT",
	fontSize = 14,
	direction = "BOTTOM",
	justify = "LEFT",
	tooltips = true,
	timestamp = true,
	timeVisible = 120,
}

local function GetOptions(self, db)
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
			self:UpdateLayout()
		end,
		args = {
			clear = {
				type = "execute",
				name = L.clear,
				func = function() self.scroll:Clear() end,
				disabled = function() return not self.scroll end,
				order = 0,
				width = "full",
			},
			direction = {
				name = L.direction,
				type = "select",
				values = {
					BOTTOM = L.up,
					TOP = L.down,
				},
				order = 1,
				width = "full",
			},
			justify = {
				name = L.align,
				type = "select",
				values = {
					LEFT = L.left,
					CENTER = L.center,
					RIGHT = L.right,
				},
				order = 1,
				width = "full",
			},
			font = {
				type = "select",
				name = L.font,
				values = media:List("font"),
				itemControl = "DDI-Font",
				order = 2,
				width = "full",
			},
			fontSize = {
				type = "range",
				name = L.fontSize,
				min = 6, max = 24, step = 1,
				order = 3,
				width = "full",
			},
			timeVisible = {
				type = "range",
				name = L.timeVisible,
				min = 0, max = 480, step = 1,
				order = 4,
				width = "full",
			},
			tooltips = {
				type = "toggle",
				name = L.spellTooltip,
				order = 5,
				width = "full",
			},
			timestamp = {
				type = "toggle",
				name = L.timestamp,
				order = 6,
				width = "full",
			},
		}
	}

	return options
end

---------------------------------------
-- API

local function New(name)
	local self = {}
	self.type = DISPLAY_TYPE
	self.defaultDB = defaultDB

	oRA3CD:AddContainer(self)

	for k, v in next, prototype do
		self[k] = v
	end
	oRA3CD.RegisterCallback(self, "OnStartup", "Show")
	oRA3CD.RegisterCallback(self, "OnShutdown", "Hide")
	oRA3CD.RegisterCallback(self, "oRA3CD_StartCooldown")
	oRA3CD.RegisterCallback(self, "oRA3CD_UpdateCharges")

	return self
end

oRA3CD:RegisterDisplayType(DISPLAY_TYPE, L.logDisplay, L.logDisplayDesc, DISPLAY_VERSION, New, GetOptions)

