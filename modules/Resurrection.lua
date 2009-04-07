local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("Resurrection", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local res = LibStub("LibResComm-1.0")

local textFormat = "%s is ressing %s."
local text = nil

local f = CreateFrame("Frame")
local function onUpdate(self, elapsed)
	local n = UnitName("mouseover")
	local is, resser = res:IsUnitBeingRessed("mouseover")
	if n and is then
		local x, y = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		text:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
		text:SetText(textFormat:format(resser, n))
		text:Show()
	else
		self:SetScript("OnUpdate", nil)
		text:Hide()
	end
end

function module:OnRegister()
	text = UIParent:CreateFontString("oRA3ResurrectionAlert", "OVERLAY", GameFontHighlightLarge)
	text:SetFontObject(GameFontHighlightLarge)
	text:SetTextColor(0.7, 0.7, 0.2, 0.8)
end

function module:OnEnable()
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end

function module:UPDATE_MOUSEOVER_UNIT()
	if not UnitIsPlayer("mouseover") or not UnitIsFriend("mouseover", "player") then return end
	--print("MOUSEOVER_UNIT")
	if not UnitIsDeadOrGhost("mouseover") or not UnitIsCorpse("mouseover") then return end
	f:SetScript("OnUpdate", onUpdate)
end

