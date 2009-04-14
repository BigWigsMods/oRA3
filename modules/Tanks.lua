local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Tanks", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

local frame = nil
local anchor = nil

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
			anchor = { x=0, y=0 },
			alpha = 0.3,
			scale = 1,
			showTankFrames = true,
		},
	})
	self.db = database.factionrealm.persistentTanks
	oRA:RegisterPanel(
		"Tanks",
		showConfig,
		hideConfig
	)
end

function module:OnEnable()
	oRA.RegisterCallback(self, "OnGroupChanged")
end

function module:OnGroupChanged(event, status, members)
	if status == oRA.INRAID then
		-- We are now in a raid, create the anchor if we should
		if self.db.showTankFrames then
			self:CreateAnchor()
		end
	else
		if anchor then
			anchor:Hide()
		end
	end
end

function module:CreateAnchor()
	if anchor then return end
	anchor = CreateFrame("Frame","oRA3TankAnchor",UIParent)
	anchor:SetWidth(150)
	anchor:SetHeight(15)
	anchor:SetAlpha(db.alpha)
	anchor:SetScale(db.scale)
	anchor:SetPoint("CENTER",UIParent,"CENTER",db.anchor.x, db.anchor.y)
	anchor.label = anchor:CreateFontString(nil,"OVERLAY","GameFontSmall")
	anchor.label:SetAllPoints(anchor)
	anchor.label:SetText("Tanks") -- LOCALIZE ME
	anchor.labe:Show()
	anchor:SetBackdrop({
		bgFile = [[Interface/Tooltips/UI-Tooltip-Background]], 
	 	edgeFile = [[Interface/Tooltips/UI-Tooltip-Border]], 
	 	tile = false, tileSize = 16, edgeSize = 8, 
	 	insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})
	anchor:SetBackdropColor(0,0,0,0.3)
	anchor:EnableMouse(true)
	anchor:SetMovable(true)
	anchor.locked = false
	anchor.ToggleLock = function(self)
		if locked then
			self:SetMovable(true)
			self:RegisterForDrag("LeftButton")
			self.locked = false
		else 
			self:SetMovable(false)
			self:RegisterForDrag(nil)
			self.locked = true			
		end
	end
	anchor:SetScript("OnMouseDown", function(self,button)
		if button == "RightButton" then
			self:ToggleLock()
		end
	end)
	anchor:SetScript("OnDragStart", function(self)  
		if not InCombatLockdown() then 
			self:StartMoving() 
		end 
	end)
	anchor:SetScript("OnDragStop", function(self)
		local scale = self:GetEffectiveScale()
		module.db.anchor.x = self:GetLeft() * scale
		module.db.anchor.y = self:GetTop() * scale		
	end)
	anchor:SetScript("OnEnter", function(self)
		if not InCombatLockdown() then
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:AddLine("Right-click to unlock anchor")
			GameTooltip:AddLine("Left-click to drag")
		end
	end)
	anchor:SetScript("OnLeave", function (self) 
		if not InCombatLockdown() then 
			GameTooltip:Hide() 
		end 
	end)
end

function module:CreateFrame()
	if frame then return end
	frame = AceGUI:Create("ScrollFrame")
	frame:PauseLayout()
	frame:SetLayout("Flow")
	--[[
		Show Tanks [ ? ] -- do they want oRA3 tank window
			-- Show/Hide Anchor
		Persistent Tanks 
			-- List of Tanks
			-- Sorting,
				1. Alpha or Index
				2. Asending/Descening
				3. Groups i.e. dont show if the tank is in sub group 6-8 for instance
				4. Group By Class/Role/Group
		Look and Feel
			-- Colors, Highlighting, Scale, Texture options
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

