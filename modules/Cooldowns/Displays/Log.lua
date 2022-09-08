
local DISPLAY_TYPE, DISPLAY_VERSION = "Log", 1

local _, scope = ...
local oRA3 = scope.addon
local L = scope.locale
local coloredNames = oRA3.coloredNames
local oRA3CD = oRA3:GetModule("Cooldowns")

local media = LibStub("LibSharedMedia-3.0")

-- luacheck: globals ChatFontNormal

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

function prototype:AddMessage(spellId, player, target)
	if not self.db.showDisplay then return end
	self:Setup()

	local icon = GetSpellTexture(spellId)
	local link = GetSpellLink(spellId)
	local timestamp = self.db.timestamp and date("|cffcccccc[%H:%M:%S] ") or ""

	if target and player ~= target and UnitIsPlayer(target) then
		local text = ("%s%s used |T%s:0:0:0:0:64:64:4:60:4:60|t%s on %s"):format(timestamp, coloredNames[player], icon, link, coloredNames[target])
		self.scroll:AddMessage(text, 1, 1, 1, 1)
	else
		local text = ("%s%s used |T%s:0:0:0:0:64:64:4:60:4:60|t%s"):format(timestamp, coloredNames[player], icon, link)
		self.scroll:AddMessage(text, 1, 1, 1, 1)
	end
end

function prototype:oRA3CD_SpellUsed(_, spellId, srcGUID, srcName, dstGUID, dstName)
	if self.spellDB[spellId] and oRA3CD:CheckFilter(self, srcName) then
		self:AddMessage(spellId, srcName, dstName)
	end
end

function prototype:TestCooldown(player, class, spellId, duration)
	self:AddMessage(spellId, player, random(1, 3) == 1 and UnitName("player"))
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
				softMax = 72, max = 200, min = 1, step = 1,
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
	oRA3CD.RegisterCallback(self, "oRA3CD_SpellUsed")

	return self
end

oRA3CD:RegisterDisplayType(DISPLAY_TYPE, L.logDisplay, L.logDisplayDesc, DISPLAY_VERSION, New, GetOptions)
