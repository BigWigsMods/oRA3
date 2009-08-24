local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Tanks", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")

module.VERSION = tonumber(("$Revision$"):sub(12, -3))

local frame = nil
local indexedTanks = {}
local namedTanks = {}
local tmpTanks = {}
local namedPersistent = {}
local topscrolls = {}
local bottomscrolls = {}

local function showConfig()
	if not frame then module:CreateFrame() end
	oRA:SetAllPointsToPanel(frame)
	frame:Show()
	module:UpdateScrolls()
end

local function hideConfig()
	if frame then
		frame:Hide()
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
	for k, tank in ipairs(self.db.persistentTanks) do
		namedPersistent[tank] = true
	end
	oRA.RegisterCallback(self, "OnTanksChanged")
	oRA.RegisterCallback(self, "OnGroupChanged")
end

local function sortTanks()
	wipe(indexedTanks)
	for k, tank in ipairs(module.db.persistentTanks) do
		if namedTanks[tank] then
			table.insert(indexedTanks, tank)
		end
	end
	if oRA.groupStatus == oRA.INRAID then
		oRA.callbacks:Fire("OnTanksUpdated", indexedTanks)
	end
end

function module:OnGroupChanged(event, status, members, updateSort)
	if status == oRA.INRAID then
		wipe(tmpTanks)
		for tank, v in pairs(namedTanks) do
			tmpTanks[tank] = v
		end
		for k, tank in ipairs(members) do
			-- mix in the persistantTanks
			if namedPersistent[tank] and not namedTanks[tank] then
				updateSort = true
				namedTanks[tank] = true
			end
			tmpTanks[tank] = nil
		end
		-- remove obsolete tanks
		for tank, v in pairs(tmpTanks) do -- remove members nolonger in the group
			updateSort = true
			namedTanks[tank] = nil
		end
		if updateSort then
			sortTanks()
		end
		if frame and frame:IsVisible() then
			self:UpdateScrolls()
		end
	end
end

function module:OnTanksChanged(event, tanks, updateSort)
	wipe(tmpTanks)
	for tank, v in pairs(namedTanks) do
		tmpTanks[tank] = v
	end
	for k, tank in ipairs(tanks) do
		if not namedTanks[tank] then
			table.insert(module.db.persistentTanks, tank)
			namedPersistent[tank] = true
			updateSort = true
			namedTanks[tank] = true
		end
		tmpTanks[tank] = nil
	end
	for tank, v in pairs(tmpTanks) do
		if not namedPersistent[tank] then -- remove any leftover tanks that are not persistent
			updateSort = true
			namedTanks[tank] = nil
		end
	end
	if updateSort then
		sortTanks()
	end
	if frame and frame:IsVisible() then
		self:UpdateScrolls()
	end
end

local function OnEnter(this)
	this.highlight:Show()
end
	
local function OnLeave(this)
	this.highlight:Hide()
end

local function CreateButton( name, parent, template)
		local frame = CreateFrame("Button", name, parent, template)
		frame:SetWidth(16)
		frame:SetHeight(16)
		frame:EnableMouse(true)
		frame:SetScript("OnLeave", OnLeave)
		frame:SetScript("OnEnter", OnEnter)
		
		
		local image = frame:CreateTexture(nil,"BACKGROUND")
		frame.icon = image
		image:SetAllPoints(frame)
		
		local highlight = frame:CreateTexture(nil,"OVERLAY")
		frame.highlight = highlight
		highlight:SetAllPoints(frame)
		highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
		highlight:SetTexCoord(0,1,0.23,0.77)
		highlight:SetBlendMode("ADD")
		highlight:Hide()
		return frame
end


function module:CreateFrame()
	if frame then return end
	
	frame = CreateFrame("Frame")

	local bar = CreateFrame("Button", nil, frame )
	frame.middlebar = bar
	bar:Show()
	bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -5, 142)
	bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 142)
	bar:SetHeight(8)

	local barmiddle = bar:CreateTexture(nil, "BORDER")
	barmiddle:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	barmiddle:SetAllPoints(bar)
	barmiddle:SetTexCoord(0.29296875, 1, 0, 0.25)
	
	bar = CreateFrame("Button", nil, frame )
	frame.topbar = bar
	bar:Show()
	bar:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, -42)
	bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -42)
	bar:SetHeight(8)

	barmiddle = bar:CreateTexture(nil, "BORDER")
	barmiddle:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	barmiddle:SetAllPoints(bar)
	barmiddle:SetTexCoord(0.29296875, 1, 0, 0.25)

	frame.topscroll = CreateFrame("ScrollFrame", "oRA3TankTopScrollFrame", frame, "FauxScrollFrameTemplate")
	frame.topscroll:SetPoint("TOPLEFT", frame.topbar, "BOTTOMLEFT", 4, 2)
	frame.topscroll:SetPoint("BOTTOMRIGHT", frame.middlebar, "TOPRIGHT", -22, -2)

	frame.bottomscroll = CreateFrame("ScrollFrame", "oRA3TankBottomScrollFrame", frame, "FauxScrollFrameTemplate")
	frame.bottomscroll:SetPoint("TOPLEFT", frame.middlebar, "BOTTOMLEFT", 4, 2) 
	frame.bottomscroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0)
	
	local help = frame:CreateFontString(nil, "ARTWORK")
	help:SetFontObject(GameFontNormal)
	help:SetPoint("TOPLEFT", 0, 0)
	help:SetPoint("BOTTOMRIGHT", frame.topbar, "TOPRIGHT")
	help:SetText("Top List: Sorted Tanks. Bottom List: Potential Tanks.\nClick people on the bottom list to put them in the top list.")

	-- 10 top
	-- 9 bottom
	for i = 1, 10 do
		topscrolls[i] = CreateFrame("Button", nil, frame)
		topscrolls[i]:SetHeight(16)
		-- topscrolls[i]:SetHighlightTexture( [[Interface\FriendsFrame\UI-FriendsFrame-HighlightBar]] )
		if i == 1 then
			topscrolls[i]:SetPoint("TOPLEFT", frame.topscroll, "TOPLEFT")
			topscrolls[i]:SetPoint("TOPRIGHT", frame.topscroll, "TOPRIGHT")
		else
			topscrolls[i]:SetPoint("TOPLEFT", topscrolls[i-1], "BOTTOMLEFT")
			topscrolls[i]:SetPoint("TOPRIGHT", topscrolls[i-1], "BOTTOMRIGHT")
		end
		topscrolls[i].nametext = oRA:CreateScrollEntry(topscrolls[i])
		topscrolls[i].nametext:SetPoint("TOPLEFT", topscrolls[i], "TOPLEFT")
		topscrolls[i].nametext:SetText(L["Name"])
		
		topscrolls[i].deletebutton = CreateButton("oRA3TankTopScrollDelete"..i, topscrolls[i])
		topscrolls[i].deletebutton:SetPoint("TOPRIGHT", topscrolls[i], "TOPRIGHT")
		topscrolls[i].deletebutton.icon:SetTexture("Interface\\AddOns\\oRA3\\images\\close")
		topscrolls[i].deletebutton:SetScript("OnClick", function(self)
			local value = topscrolls[i].unitName
			local btanks = oRA:GetBlizzardTanks()
			if util:inTable( btanks, value) then return end
			for k, v in ipairs(module.db.persistentTanks) do
				if v == value then
					table.remove(module.db.persistentTanks, k)
					break
				end
			end
			namedPersistent[value] = nil
			module:OnGroupChanged("OnGroupChanged", oRA.groupStatus, oRA:GetGroupMembers() )
			module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks() )
		end)
		topscrolls[i].tankbutton = CreateButton("oRA3TankTopScrollTank"..i, topscrolls[i], "SecureActionButtonTemplate")
		topscrolls[i].tankbutton:SetPoint("TOPRIGHT", topscrolls[i].deletebutton, "TOPLEFT", -2, 0)
		topscrolls[i].tankbutton.icon:SetTexture("Interface\\RaidFrame\\UI-RaidFrame-MainTank")
		topscrolls[i].tankbutton.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		topscrolls[i].tankbutton:SetAttribute("type", "maintank")
		topscrolls[i].tankbutton:SetAttribute("action", "toggle")
		
		topscrolls[i].downbutton = CreateButton("oRA3TankTopScrollDown"..i, topscrolls[i])
		topscrolls[i].downbutton:SetPoint("TOPRIGHT", topscrolls[i].tankbutton, "TOPLEFT", -2, 0)
		topscrolls[i].downbutton.icon:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
		topscrolls[i].downbutton.icon:SetTexCoord(0.25, 0.75, 0.25, 0.75)
		topscrolls[i].downbutton:SetScript("OnClick", function(self)
			if self.disabled then return end
			local value = topscrolls[i].unitName
			local k = util:inTable( module.db.persistentTanks, value)
			local temp = module.db.persistentTanks[k]
			module.db.persistentTanks[k] = module.db.persistentTanks[k+1]
			module.db.persistentTanks[k+1] = temp
			module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks(), true)
		end)
		
		
		topscrolls[i].upbutton = CreateButton("oRA3TankTopScrollUp"..i, topscrolls[i])
		topscrolls[i].upbutton:SetPoint("TOPRIGHT", topscrolls[i].downbutton, "TOPLEFT", -2, 0)
		topscrolls[i].upbutton.icon:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
		topscrolls[i].upbutton.icon:SetTexCoord(0.25, 0.75, 0.25, 0.75)
		topscrolls[i].upbutton:SetScript("OnClick", function(self)
			if self.disabled then return end
			local value = topscrolls[i].unitName
			local k = util:inTable( module.db.persistentTanks, value)
			local temp = module.db.persistentTanks[k]
			module.db.persistentTanks[k] = module.db.persistentTanks[k-1]
			module.db.persistentTanks[k-1] = temp
			module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks(), true)
		end)
	end
	
	for i = 1, 9 do
		bottomscrolls[i] = CreateFrame("Button", nil, frame)
		bottomscrolls[i]:SetHeight(16)
		bottomscrolls[i]:SetHighlightTexture( [[Interface\FriendsFrame\UI-FriendsFrame-HighlightBar]] )
		bottomscrolls[i]:EnableMouse(true)
		bottomscrolls[i]:SetScript("OnClick", function( self ) 
			local value = self.unitName
			if util:inTable( module.db.persistentTanks, value) then return true end
			table.insert(module.db.persistentTanks, value)
			namedPersistent[value] = true
			namedTanks[value] =true
			module:OnTanksChanged("OnTanksChanged", oRA:GetBlizzardTanks() )
		end)
		if i == 1 then
			bottomscrolls[i]:SetPoint("TOPLEFT", frame.bottomscroll, "TOPLEFT")
			bottomscrolls[i]:SetPoint("TOPRIGHT", frame.bottomscroll, "TOPRIGHT")
		else
			bottomscrolls[i]:SetPoint("TOPLEFT", bottomscrolls[i-1], "BOTTOMLEFT")
			bottomscrolls[i]:SetPoint("TOPRIGHT", bottomscrolls[i-1], "BOTTOMRIGHT")
		end
		bottomscrolls[i].nametext = oRA:CreateScrollEntry(bottomscrolls[i])
		bottomscrolls[i].nametext:SetPoint("TOPLEFT", bottomscrolls[i], "TOPLEFT")
		bottomscrolls[i].nametext:SetPoint("BOTTOMRIGHT", bottomscrolls[i], "BOTTOMRIGHT")
		bottomscrolls[i].nametext:SetText(L["Name"])
		bottomscrolls[i].unitName = L["Name"]
	end
	
	local function updTopScroll() module:UpdateTopScroll() end
	local function updBottomScroll() module:UpdateBottomScroll() end
	
	frame.topscroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 16, updTopScroll )
	end)
	
	frame.bottomscroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 16, updBottomScroll )
	end)
end

function module:UpdateScrolls()
	self:UpdateTopScroll()
	self:UpdateBottomScroll()
end

local ngroup = {}
function module:UpdateTopScroll()
	if not frame then return end
	local list = self.db.persistentTanks
	local nr = #list
	local btanks = oRA:GetBlizzardTanks()
	FauxScrollFrame_Update(frame.topscroll, nr, 10, 16)
	for i = 1, 10 do
		local j = i + FauxScrollFrame_GetOffset(frame.topscroll)
		if j <= nr then
			if j == 1 then
				topscrolls[i].upbutton:SetAlpha(.3)
				topscrolls[i].upbutton:EnableMouse(false)
			else
				topscrolls[i].upbutton:SetAlpha(1)
				topscrolls[i].upbutton:EnableMouse(true)
			end
			if j == nr then
				topscrolls[i].downbutton:SetAlpha(.3)
				topscrolls[i].downbutton:EnableMouse(false)
			else
				topscrolls[i].downbutton:SetAlpha(1)
				topscrolls[i].downbutton:EnableMouse(true)
			end
			if util:inTable( btanks, list[j]) then
				topscrolls[i].tankbutton:SetAlpha(1)
				--topscrolls[i].tankbutton:EnableMouse(true)
				topscrolls[i].deletebutton:SetAlpha(.3)
				topscrolls[i].deletebutton:EnableMouse(false)
			else
				topscrolls[i].tankbutton:SetAlpha(.3)
				--topscrolls[i].tankbutton:EnableMouse(false)
				topscrolls[i].deletebutton:SetAlpha(1)
				topscrolls[i].deletebutton:EnableMouse(true)
			end
			topscrolls[i].unitName = list[j]
			topscrolls[i].tankbutton:SetAttribute("unit", list[j])
			topscrolls[i].nametext:SetText(oRA.coloredNames[list[j]])
			topscrolls[i]:Show()
		else
			topscrolls[i]:Hide()
		end
	end
end

function module:UpdateBottomScroll()
	if not frame then return end
	local group = oRA:GetGroupMembers()
	wipe(ngroup)
	for	k, v in pairs(group) do
		if not namedPersistent[v] then -- only add not in the tanklist
			table.insert(ngroup, v)
		end
	end
	local nr = #ngroup
	FauxScrollFrame_Update(frame.bottomscroll, nr, 9, 16)
	for i = 1, 9 do
		local j = i + FauxScrollFrame_GetOffset(frame.bottomscroll)
		if j <= nr then
			bottomscrolls[i].unitName = ngroup[j]
			bottomscrolls[i].nametext:SetText(oRA.coloredNames[ngroup[j]])
			bottomscrolls[i]:Show()
		else
			bottomscrolls[i]:Hide()
		end
	end
end

function oRA:GetSortedTankList()
	return indexedTanks
end

