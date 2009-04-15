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
			x = 0, y = 0,
			alpha = 0.3,
			scale = 1,
			showTankAnchor = true,
		},
	})
	self.db = database.factionrealm
	oRA:RegisterPanel(
		"Tanks",
		showConfig,
		hideConfig
	)
end

function module:OnEnable()
	oRA.RegisterCallback(self, "OnGroupChanged")
	self:CreateAnchor()
	if self.db.showTankAnchor then
		anchor:Show()
	else
		anchor:Hide()
	end
end

function module:OnGroupChanged(event, status, members)
	if status == oRA.INRAID then
		-- we are in a raid setup listenersfor tank windows if we have any
	end
end

function module:CreateAnchor()
	if anchor then return end
	anchor = CreateFrame("Frame","oRA3TankAnchor",UIParent)
	anchor:SetWidth(150)
	anchor:SetHeight(15)
	if self.db.x and self.db.y then
		anchor:SetPoint("CENTER",UIParent,"CENTER",self.db.x, self.db.y)
	else
		anchor:SetPoint("CENTER",UIParent,"CENTER",100, 0)		
	end
	anchor.label = anchor:CreateFontString(nil,"OVERLAY","GameFontNormal")
	anchor.label:SetAllPoints(anchor)
	anchor.label:SetText("Tanks") -- LOCALIZE ME
	anchor:EnableMouse(true)
	anchor:SetMovable(true)
	anchor.locked = true
	anchor.ToggleLock = function(self)
		if not self.locked then
			self:RegisterForDrag()
			self.locked = true
		else 
			self:RegisterForDrag("LeftButton")
			self.locked = false
		end
	end
	anchor:SetScript("OnMouseDown", function(self,button)
		if button == "RightButton" and not InCombatLockdown() then
			self:ToggleLock()
		end
	end)
	anchor:SetScript("OnDragStart", function(self)  
		if not InCombatLockdown() then 
			self:StartMoving() 
		end 
	end)
	anchor:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local scale,pscale = self:GetEffectiveScale(),self:GetParent():GetEffectiveScale()
		local to,anchor,from,x,y = self:GetPoint()
		local gX,gY = self:GetLeft() + self:GetWidth() / 2, self:GetBottom() + self:GetHeight() / 2
		local pX,pY = UIParent:GetLeft() + UIParent:GetWidth() / 2, UIParent:GetBottom() + UIParent:GetHeight() / 2
		local x = (gX * scale) - (pX * pscale)
		local y = (gY * scale) - (pY * pscale)
		x = x/scale
		y = y/scale		
		module.db.x = x
		module.db.y = y
		self:ClearAllPoints()
		self:SetPoint("CENTER",UIParent,"CENTER",module.db.x, module.db.y)
	end)
	anchor:SetScript("OnEnter", function(self)
		if not InCombatLockdown() then
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			if self.locked then
				GameTooltip:AddLine("Right-click to unlock anchor")
			else
				GameTooltip:AddLine("Right-click to lock anchor")
			end
			GameTooltip:AddLine("Left-click to drag")
			GameTooltip:Show()
		end
	end)
	anchor:SetScript("OnLeave", function (self) 
		if not InCombatLockdown() then 
			GameTooltip:Hide() 
		end 
	end)
	anchor:Hide()
end

function module:CreateFrame()
	if frame then return end
	frame = AceGUI:Create("ScrollFrame")
	frame:PauseLayout()
	frame:SetLayout("Flow")
	--[[
	 	Show/Hide Anchor
		Enable Tanks [ ? ] -- do they want oRA3 tank window during the raid?
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
	
	local anchorDesc = AceGUI:Create("Label")
	anchorDesc:SetText("Tank Window Options")
	anchorDesc:SetFullWidth(true)
	
	local show = AceGUI:Create("CheckBox")
	show:SetLabel("Show anchor")
	show:SetValue(self.db.showTankAnchor)
	show:SetCallback("OnValueChanged", function(_,_,value)
		if value then anchor:Show() else anchor:Hide() end
		self.db.showTankAnchor = value
	end)
	show:SetUserData("tooltip", "Show or hide the anchor bar in the game world.")
	show:SetFullWidth(true)
	
	
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

	frame:AddChildren(persistentHeading,anchorDesc,show, moduleDescription, add, delete, sort, box)
	
	frame:ResumeLayout()
	frame:DoLayout()
end

