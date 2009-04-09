local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Tanks", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

local classes = {
	Hezekiah = "WARRIOR",
	Jitter = "WARRIOR",
	Kaostechno = "PALADIN",
	Shekowaffle = "DRUID",
	Tubbygold = "WARLOCK",
}

local hexColors = {}
for k, v in pairs(RAID_CLASS_COLORS) do
	hexColors[k] = "|cff" .. string.format("%02x%02x%02x", v.r * 255, v.g * 255, v.b * 255)
end

local coloredNames = setmetatable({}, {__index =
	function(self, key)
		if type(key) == "nil" then return nil end
		local class = classes[key] or select(2, UnitClass(key))
		if class then
			self[key] = hexColors[class]  .. key .. "|r"
		else
			self[key] = "|cffcccccc<"..key..">|r"
		end
		return self[key]
	end
})

local tanks = {
	"Hezekiah",
	"Jitter",
	"Kaostechno",
	"Shekowaffle",
	"Tubbygold",
}

local function showConfig()
	if not frame then module:CreateFrame() end
	oRA:SetAllPointsToPanel(frame.frame)
	frame.frame:Show()
end

local function hideConfig()
	if frame then
		frame:Release()
		frame = nil
	end
end

function module:OnRegister()
	local database = oRA.db:RegisterNamespace("Tanks", {
		factionrealm = {
			persistentTanks = {},
		},
	})
	db = database.factionrealm.persistentTanks
	oRA:RegisterPanel(
		"Tanks",
		showConfig,
		hideConfig
	)
end

function module:CreateFrame()
	if frame then return end
	frame = AceGUI:Create("ScrollFrame")
	frame:SetLayout("Flow")

	local persistentHeading = AceGUI:Create("Heading")
	persistentHeading:SetText("Persistent tanks")
	persistentHeading:SetFullWidth(true)

	local moduleDescription = AceGUI:Create("Label")
	moduleDescription:SetText("Persistent tanks are players you always want present in the sort list. If they're made main tanks by anyone, you'll automatically sort them according to your own preference.")
	moduleDescription:SetFullWidth(true)
	moduleDescription:SetFontObject(GameFontHighlight)

	local add = AceGUI:Create("EditBox")
	add:SetLabel(L["Add"])
	add:SetText()
	add:SetCallback("OnEnterPressed", function(widget, event, value)
		print("add tank")
	end)
	add:SetRelativeWidth(0.5)

	local delete = AceGUI:Create("Dropdown")
	delete:SetValue("")
	delete:SetLabel(L["Remove"])
	delete:SetList(db)
	delete:SetCallback("OnValueChanged", function(_, _, value)
		print("remove tank")
	end)
	delete:SetRelativeWidth(0.5)
	
	local sort = AceGUI:Create("Heading")
	sort:SetText("Sort")
	sort:SetFullWidth(true)

	local box = AceGUI:Create("SimpleGroup")
	box:SetLayout("Flow")
	box:SetFullWidth(true)

	local format = "%d. %s"
	for i, v in ipairs(tanks) do
		local up = AceGUI:Create("Button")
		up:SetText("Up")
		up:SetWidth(50)
		local down = AceGUI:Create("Button")
		down:SetText("Down")
		down:SetWidth(50)
		local label = AceGUI:Create("Label")
		label:SetText(format:format(i, coloredNames[v]))
		label:SetFontObject(GameFontHighlightLarge)
		box:AddChild(up)
		box:AddChild(down)
		box:AddChild(label)
	end

	frame:AddChild(persistentHeading)
	frame:AddChild(moduleDescription)
	frame:AddChild(add)
	frame:AddChild(delete)
	frame:AddChild(sort)
	frame:AddChild(box)
end

