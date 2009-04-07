local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Cooldowns", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")
local bc = LibStub("LibBabble-Class-3.0"):GetUnstrictLookupTable()

local _, playerClass = UnitClass("player")

local bloodlustId = UnitFactionGroup("player") == "Alliance" and 32182 or 2825

local spells = {
	DRUID = {
		rebirth = { GetSpellInfo(26994), 1200 },
		innervate = { GetSpellInfo(29166), 360 },
	},
	HUNTER = {
		misdirect = { GetSpellInfo(34477), 30 },
		fd = { GetSpellInfo(5384), 30 },
	},
	MAGE = {
		iceblock = { GetSpellInfo(45438), 300 },
	},
	PALADIN = {
		di = { GetSpellInfo(19752), 1200 },
	},
	PRIEST = {
		pain = { GetSpellInfo(33206), 180 },
		guardian = { GetSpellInfo(47788), 180 },
		fw = { GetSpellInfo(6346), 180 },
	},
	ROGUE = {
		distract = { GetSpellInfo(1725), 30 },
	},
	SHAMAN = {
		bl = { GetSpellInfo(bloodlustId), 600 },
		reinc = { GetSpellInfo(20608), 3600 },
		manatide = { GetSpellInfo(16190), 300 },
	},
	WARLOCK = {
		soulstone = { GetSpellInfo(27239), 1800 },
		shatter = { GetSpellInfo(29858), 300 },
	},
	WARRIOR = {
		shieldwall = { GetSpellInfo(871), 300 },
		laststand = { GetSpellInfo(12975), 300 },
	},
}

local classes = {}
for k in pairs(spells) do
	classes[k] = bc[k]
end

local frame = nil
local db = nil

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
	local database = oRA.db:RegisterNamespace("Cooldowns", {
		profile = {
			spells = {
				rebirth = true,
				di = true,
				reinc = true,
				soulstone = true,
			},
		},
	})
	db = database.profile
	
	self:CreateFrame()

	oRA:RegisterOverview(
		"Cooldowns",
		"Interface\\Icons\\Spell_ChargePositive",
		showConfig,
		hideConfig
	)
end

function module:CreateFrame()
	if frame then return end

	local f = AceGUI:Create("ScrollFrame")
	frame = f

	local moduleDescription = AceGUI:Create("Label")
	moduleDescription:SetText("Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs.")
	moduleDescription:SetFullWidth(true)
	moduleDescription:SetFontObject(GameFontHighlight)

	local function spellCheckboxCallback(widget, event, value)
		if not widget.oRACooldownID then return end
		db.spells[widget.oRACooldownID] = value and true or nil
		widget:SetValue(value)
	end

	local group = AceGUI:Create("DropdownGroup")
	group:SetTitle()
	group:SetGroupList(classes)
	group:SetCallback("OnGroupSelected", function(widget, event, class)
		widget:ReleaseChildren()
		for id, spellDetails in pairs(spells[class]) do
			local checkbox = AceGUI:Create("CheckBox")
			checkbox:SetLabel(spellDetails[1])
			checkbox:SetValue(db.spells[id])
			checkbox.oRACooldownID = id
			checkbox:SetCallback("OnValueChanged", spellCheckboxCallback)
			checkbox:SetFullWidth(true)
			widget:AddChild(checkbox)
		end
	end)
	group.dropdown:SetWidth(100)
	group:SetGroup(playerClass)
	group:SetFullWidth(true)
	f:AddChild(moduleDescription)
	f:AddChild(group)
end

