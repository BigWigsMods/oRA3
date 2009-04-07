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
		[26994] = 1200, -- Rebirth
		[29166] = 360, -- Innervate
		[17116] = 180, -- Nature's Swiftness
		[5209] = 180, -- Challenging Roar
	},
	HUNTER = {
		[34477] = 30, -- Misdirect
		[5384] = 30, -- Feign Death
	},
	MAGE = {
		[45438] = 300, -- Iceblock
		[2139] = 24, -- Counterspell
	},
	PALADIN = {
		[19752] = 1200, -- Divine Intervention
		[642] = 300, -- Divine Shield
		[10278] = 300, -- Hand of Protection
		[6940] = 120, -- Hand of Sacrifice
		[498] = 300, -- Divine Protection
		[633] = 1200, -- Lay on Hands
	},
	PRIEST = {
		[33206] = 180, -- Pain Suppression
		[47788] = 180, -- Guardian Spirit
		[6346] = 180, -- Fear Ward
	},
	ROGUE = {
		[31224] = 90, -- Cloak of Shadows
		[38768] = 10, -- Kick
		[1725] = 30, -- Distract
	},
	SHAMAN = {
		[bloodlustId] = 600, -- Bloodlust/Heroism
		[20608] = 3600, -- Reincarnation
		[16190] = 300, -- Mana Tide Totem
		[2894] = 1200, -- Fire Elemental Totem
		[2062] = 1200, -- Earth Elemental Totem
		[16188] = 180, -- Nature's Swiftness
	},
	WARLOCK = {
		[27239] = 1800, -- Soulstone Resurrection
		[29858] = 300, -- Soulshatter
	},
	WARRIOR = {
		[871] = 300, -- Shield Wall
		[12975] = 300, -- Last Stand
		[6554] = 10, -- Pummel
		[1161] = 180, -- Challenging Shout
	},
	--[[DEATHKNIGHT = {
		[] = x, -- Army of the Dead
		[] = x, -- Raise Ally
		[] = x, -- Dancing Rune Weapon
		[] = x, -- Summon Gargoyle
		[] = x, -- Strangulate
		[] = x, -- Death Grip
		[] = x, -- Unbreakable Armor
	},]]
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
				[26994] = true,
				[19752] = true,
				[20608] = true,
				[27239] = true,
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

local tmp = {}
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
		wipe(tmp)
		for id in pairs(spells[class]) do
			table.insert(tmp, id)
		end
		table.sort(tmp)
		for i, v in ipairs(tmp) do
			local name = GetSpellInfo(v)
			local checkbox = AceGUI:Create("CheckBox")
			checkbox:SetLabel(name)
			checkbox:SetValue(v)
			checkbox.oRACooldownID = v
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

