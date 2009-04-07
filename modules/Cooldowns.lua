local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Cooldowns", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

local frame = nil

local function showConfig()
	frame.frame:SetParent(_G["oRA3FrameSub"])
	frame.frame:SetPoint("TOPLEFT", _G["oRA3FrameSub"], "TOPLEFT", 0, -60)
	frame.frame:SetPoint("BOTTOMRIGHT", _G["oRA3FrameSub"], "BOTTOMRIGHT", -4, 4)
	frame.frame:Show()
end

local function hideConfig()
	frame.frame:Hide()
end

function module:OnRegister()
	self:CreateFrame()

	oRA:RegisterOverview(
		"Cooldowns",
		"Interface\\Icons\\Spell_ChargePositive",
		showConfig,
		hideConfig
	)
end

local spells = {
	WARRIOR = {
		sw = "Shield Wall",
	},
	PALADIN = {
		di = "Divine Intervention",
	},
}

function module:CreateFrame()
	if frame then return end

	local f = AceGUI:Create("ScrollFrame")
	frame = f

	local classes = AceGUI:Create("DropdownGroup")
	classes:SetTitle("Select class")
	classes:SetGroupList({
		WARRIOR = "Warrior",
		PALADIN = "Paladin",
	})
	classes:SetCallback("OnGroupSelected", function(widget, event, group)
		for id, spell in pairs(spells[group]) do
			local checkbox = AceGUI:Create("CheckBox")
			checkbox:SetLabel(spell)
			checkbox:SetFullWidth(true)
			widget:AddChild(checkbox)
		end
	end)
	classes:SetGroup("WARRIOR")
	classes:SetFullWidth(true)
	f:AddChild(classes)
end













