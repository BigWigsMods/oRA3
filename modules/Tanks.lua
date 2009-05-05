local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Tanks", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

local frame = nil
local indexedTanks = {}
local namedTanks = {}
local tmpTanks = {}

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
	self.db = database.factionrealm
	oRA:RegisterPanel(
		"Tanks",
		showConfig,
		hideConfig
	)
	
	oRA.RegisterCallback(self, "OnTanksChanged")
	oRA.RegisterCallback(self, "OnGroupChanged")
end

local function sortTanks()
	wipe(indexedTanks)
	-- FIXME: use the true sorted tanks based on config
	for tank, v in pairs(namedTanks) do 
		table.insert(indexedTanks, tank)
	end
	oRA.callbacks:Fire("OnTanksUpdated", indexedTanks)
end

function module:OnGroupChanged(event, status, members)
	local updateSort = nil
	if status == oRA.INRAID then
		for k, tank in ipairs(members) do
			-- mix in the persistantTanks
			if self.db.persistantTanks[tank] and not namedTanks[tank] then
				updateSort = true
				namedTanks[tank] = true
			end
		end
		if updateSort then
			sortTanks()
		end
	end
end

function module:OnTanksChanged(event, tanks)
	local updateSort = nil
	for k, tank in ipairs(tanks) do
		if not namedTanks[tank] then
			updateSort = true
			namedTanks[tank] = true
		end
	end
	if updateSort then
		sortTanks()
	end
end

function module:CreateFrame()
	if frame then return end
	frame = AceGUI:Create("ScrollFrame")
	frame:PauseLayout()
	frame:SetLayout("Flow")
	--[[
		Persistent Tanks 
			-- List of Personal Tanks
			-- Sorting,
				1. Alpha or Index
				2. Asending/Descening
				3. Groups i.e. dont show if the tank is in sub group 6-8 for instance
				4. Group By Class/Role/Group
	--]]
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

	-- ZZZ Possibly use clickable labels instead? With a modifier key to move down,
	-- ZZZ and default to moving up, or something like that.
	local format = "%d. %s"
	local i = 1
	for name, class in pairs(oRA._testUnits) do
		local up = AceGUI:Create("Icon")
		up:SetImage("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up", 0.25, 0.75, 0.25, 0.75)
		up:SetImageSize(16, 16)
		up:SetWidth(20)
		up:SetHeight(20)
		local down = AceGUI:Create("Icon")
		down:SetImage("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up", 0.25, 0.75, 0.25, 0.75)
		down:SetImageSize(16, 16)
		down:SetWidth(20)
		down:SetHeight(20)
		local label = AceGUI:Create("Label")
		label:SetText(format:format(i, oRA.coloredNames[name]))
		label:SetFontObject(GameFontHighlightLarge)
		local spacer = AceGUI:Create("Label")
		spacer:SetText("")
		spacer:SetFullWidth(true)
		box:AddChildren(up, down, label, spacer)
		i = i + 1
	end

	frame:AddChildren(persistentHeading, moduleDescription, add, delete, sort, box)
	
	frame:ResumeLayout()
	frame:DoLayout()
end

