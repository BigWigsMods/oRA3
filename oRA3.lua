
local addon = LibStub("AceAddon-3.0"):NewAddon("oRA3", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceConsole-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")

addon.util = {}
local util = addon.util

-- Module stuff
addon:SetDefaultModuleState(false) -- all modules disabled by default

-- Locals
local playerName = UnitName("player")

-- couple of local constants used for party size
local UNGROUPED = 0
local INPARTY = 1
local INRAID = 2
addon.groupStatus = UNGROUPED -- flag indicating groupsize
local groupStatus = addon.groupStatus -- local upvalue

local db
local defaults = {
	profile = {
		positions = {},
		attached = true,
		open = true,
	}
}


local ldb = LibStub("LibDataBroker-1.1"):NewDataObject("oRA3", {
	type = "launcher",
	text = "oRA3",
	icon = [[Interface\Icons\INV_Inscription_MajorGlyph03]],
})

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("oRA3DB", defaults)
	db = self.db.profile
	
	-- callbackhandler for comm
	self.callbacks = CallbackHandler:New(self)
end


function addon:OnEnable()
	-- Comm register
	self:RegisterComm("oRA3")
	
	-- Group Status Events
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE")
	-- init groupStatus
	self:RAID_ROSTER_UPDATE()
end

function addon:OnDisable()
	self:Shutdown()
end

-- keep track of group status
function addon:RAID_ROSTER_UPDATE()
	local oldStatus = groupStatus
	if GetNumRaidMembers() > 0 then
		groupStatus = INRAID
	elseif GetNumPartyMembers() > 0 then
		groupStatus = INPARTY
	else
		groupStatus = UNGROUPED
		-- FIXME:  remove this override
		groupStatus = INRAID
	end
	if groupStatus == UNGROUPED and oldStatus > groupStatus then
		self:Shutdown()
	elseif oldStatus == UNGROUPED and groupStatus > oldStatus then
		self:Startup()
	end
end

function addon:InRaid()
	return groupStatus == INRAID
end

function addon:InParty()
	return groupStatus == INPARTY
end

-- startup and shutdown
function addon:Startup()
	self:ShowGUI()
	for name, module in self:IterateModules() do
		module:Enable()
	end
end

function addon:Shutdown()
	self:HideGUI()
	for name, module in self:IterateModules() do
		module:Disable()
	end
end

-- utility functions

function addon:IsPromoted(name)
	if not name then name = playerName end
	if groupStatus == UNGROUPED then
		return false
	elseif groupStatus == INRAID then
		if name == playerName then return IsRaidLeader() or IsRaidOfficer() end
		local raidNum = GetNumRaidMembers()
		for i=1,raidNum do
			local rname, rank = GetRaidRosterInfo(i)
			if rname == name then return rank > 0 end
		end
	elseif groupStatus == INPARTY then
		local li = GetPartyLeaderIndex()
		return (li == 0 and name == playerName) or (li>0 and name == UnitName("party"..li))
	end
	return false
end

-- comm

function addon:SendComm( ... )
	if groupStatus == UNGROUPED then return end
	self:SendCommMessage("oRA3", self:Serialize(...), "RAID") -- we always send to raid, blizzard will default to party if you're in a party
end

function addon:OnCommReceived(prefix, message, distribution, sender)
	if distribution ~= "RAID" and distribution ~= "PARTY" then return end
	addon:DispatchComm( sender, self:Deserialize(message) )
end

function addon:DispatchComm(sender, ok, commType, ...)
	if ok and type(commType) == "string" then
		self.callbacks:Fire( "OnComm"..commType, sender, ... )
	end
end

-- GUI

function addon:ShowGUI()
	self:SetupGUI()
	oRA3Frame:Show()
	self:UpdateGUI()
end

function addon:HideGUI()
	-- hide gui here
	oRA3Frame:Hide()
end


-- The Sliding/Detaching GUI pane is courtsey of Cladhaire and originally from LightHeaded
-- This code was used with permission.

function addon:SetupGUI()
	if oRA3Frame then return end

	local frame = CreateFrame("Frame", "oRA3Frame", RaidFrame)

	frame:SetWidth(640)
	frame:SetHeight(512)
	frame:SetPoint("LEFT", RaidFrame, "RIGHT", 0, 19)
	
	local topleft = frame:CreateTexture(nil, "ARTWORK")
	topleft:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopLeft")
	topleft:SetWidth(128)
	topleft:SetHeight(256)
	topleft:SetPoint("TOPLEFT", 0, 0)

	local topright = frame:CreateTexture(nil, "ARTWORK")
	topright:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopRight")
	topright:SetWidth(140)
	topright:SetHeight(256)
	topright:SetPoint("TOPRIGHT", 0, 0)
	topright:SetTexCoord(0, (140 / 256), 0, 1)

	local top = frame:CreateTexture(nil, "ARTWORK")
	top:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-Top")
	top:SetHeight(256)
	top:SetPoint("TOPLEFT", topleft, "TOPRIGHT", 0, 0)
	top:SetPoint("TOPRIGHT", topright, "TOPLEFT", 0, 0)

	local botleft = frame:CreateTexture(nil, "ARTWORK")
	botleft:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-BotLeft")
	botleft:SetWidth(128)
	botleft:SetHeight(168)
	botleft:SetPoint("BOTTOMLEFT", 0, 0)
	botleft:SetTexCoord(0, 1, 0, (168 / 256))

	local botright = frame:CreateTexture(nil, "ARTWORK")
	botright:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-BotRIght")
	botright:SetWidth(140)
	botright:SetHeight(168)
	botright:SetPoint("BOTTOMRIGHT", 0, 0)
	botright:SetTexCoord(0, (140 / 256), 0, (168 / 256))

	local bot = frame:CreateTexture(nil, "ARTWORK")
	bot:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-Bot")
	bot:SetHeight(168)
	bot:SetPoint("TOPLEFT", botleft, "TOPRIGHT", 0, 0)
	bot:SetPoint("TOPRIGHT", botright, "TOPLEFT", 0, 0)
	bot:SetTexCoord(0, 1, 0, (168 / 256))

	local midleft = frame:CreateTexture(nil, "ARTWORK")
	midleft:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopLeft")
	midleft:SetWidth(128)
	midleft:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT", 0, 0)
	midleft:SetPoint("BOTTOMLEFT", botleft, "TOPLEFT", 0, 0)
	midleft:SetTexCoord(0, 1, (240 / 256), 1)

	local midright = frame:CreateTexture(nil, "ARTWORK")
	midright:SetTexture("Interface\\AddOns\\oRA3\\images\\MidRight")
	midright:SetWidth(140)
	midright:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT", 0, 0)
	midright:SetPoint("BOTTOMRIGHT", botright, "TOPRIGHT", 0, 0)
	midright:SetTexCoord(0, (140 / 256), 0, 1)

	local mid = frame:CreateTexture(nil, "ARTWORK")
	mid:SetTexture("Interface\\AddOns\\oRA3\\images\\Mid")
	mid:SetPoint("TOPLEFT", midleft, "TOPRIGHT", 0, 0)
	mid:SetPoint("BOTTOMRIGHT", midright, "BOTTOMLEFT", 0, 0)
	
	local bg1 = frame:CreateTexture(nil, "BACKGROUND")
	bg1:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
	bg1:SetHeight(64)
	bg1:SetPoint("TOPLEFT", topleft, "TOPLEFT", 5, -4)
	bg1:SetWidth(256)

	local bg2 = frame:CreateTexture(nil, "BACKGROUND")
	bg2:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
	bg2:SetHeight(64)
	bg2:SetPoint("TOPLEFT", bg1, "TOPRIGHT", 0, 0)
	bg2:SetWidth(256)

	local bg3 = frame:CreateTexture(nil, "BACKGROUND")
	bg3:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
	bg3:SetHeight(64)
	bg3:SetPoint("TOPLEFT", bg2, "TOPRIGHT", 0, 0)
	bg3:SetWidth(256)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 5, 4)
	--self:SetFrameTooltip(close, "Click to close the oRA3 GUI")

	local resize = CreateFrame("Button", nil, frame)
	resize:SetNormalTexture("Interface\\AddOns\\oRA3\\images\\Resize")
	resize:GetNormalTexture():SetTexCoord((12 / 32), 1, (12 / 32), 1)
	resize:SetHighlightTexture("Interface\\AddOns\\oRA3\\images\\Resize")
	resize:GetHighlightTexture():SetTexCoord((12 / 32), 1, (12 / 32), 1)
	resize:SetHeight(12)
	resize:SetWidth(12)
	resize:SetPoint("BOTTOMRIGHT", -3, 3)
	--self:SetFrameTooltip(resize, "Click to resize")

	local titlereg = CreateFrame("Button", nil, frame)
	titlereg:SetPoint("TOPLEFT", 5, -5)
	titlereg:SetPoint("TOPRIGHT", 0, 0)
	titlereg:SetHeight(20)
	titlereg:SetScript("OnMouseDown", function(f)
										  local parent = f:GetParent()
										  if parent:IsMovable() then
											  parent:StartMoving()
										  end
									  end)
	titlereg:SetScript("OnMouseUp", function(f)
										local parent = f:GetParent()
										parent:StopMovingOrSizing()
										-- self:SavePosition("oRA3Frame")
									end)

	frame:EnableMouse()
	frame:SetMovable(1)
	frame:SetResizable(1)
	frame:SetMinResize(300, 300)
	frame:SetWidth(400)
	frame:SetFrameLevel(0)
	frame:SetWidth(325)
	frame:SetHeight(450)

	frame.bg1 = bg1
	frame.bg2 = bg2
	frame.bg3 = bg3
	frame.top = top
	frame.bot = bot
	frame.topleft = topleft
	frame.topright = topright
	frame.botleft = botleft
	frame.botright = botright
	frame.close = close
	frame.resize = resize
	frame.mid = mid
	frame.midleft = midleft
	frame.midright = midright
	frame.titlereg = titlereg	
	
	local cos = math.cos
	local pi = math.pi

	-- internal functions
	local function cosineInterpolation(y1, y2, mu)
		return y1+(y2-y1)*(1 - cos(pi*mu))/2
	end

	local min,max = -360, -50
	local steps = 45
	local timeToFade = 1.5
	local mod = 1/timeToFade
	local modifier = 1/steps
	
	local count = 0
	local totalElapsed = 0
	local function onupdate(self, elapsed)   
		count = count + 1
		totalElapsed = totalElapsed + elapsed
		
		if totalElapsed >= timeToFade then
			local temp = max
			max = min
			min = temp
			count = 0
			totalElapsed = 0
			self:SetScript("OnUpdate", nil)
			
			-- Do the frame fading
			if not addon.db.profile.open then
				if oRA3FrameSub.justclosed == true then
					oRA3FrameSub.justclosed = false
					oRA3FrameSub:Hide()
				else
					UIFrameFadeIn(oRA3FrameSub, 0.25, 0, 1)
					oRA3FrameSub:Show()
					addon.db.profile.open = true
					-- FIXME
					-- Select last tab
					-- oRA3:SelectQuestLogEntry()
				end
			end
			return
		elseif count == 1 and addon.db.profile.open then
			UIFrameFadeOut(oRA3FrameSub, 0.25, 1, 0)
			addon.db.profile.open = false
			oRA3FrameSub.justclosed = true
		end
		
		local offset = cosineInterpolation(min, max, mod * totalElapsed)
		self:SetPoint("LEFT", RaidFrame, "RIGHT", offset, 31)
	end	
	
	-- Flip min and max, if we're supposed to be open
	if self.db.profile.open then
		min,max = max,min
	end

	if not frame.handle then
		frame.handle = CreateFrame("Button", nil, frame)
	end

	frame.handle:SetWidth(8)
	frame.handle:SetHeight(128)
	frame.handle:SetPoint("LEFT", frame, "RIGHT", 0, 0)
	frame.handle:SetNormalTexture("Interface\\AddOns\\oRA3\\images\\tabhandle")

	frame.handle:RegisterForClicks("AnyUp")
	frame.handle:SetScript("OnClick", function(self, button)
											frame:SetScript("OnUpdate", onupdate)
											if addon.db.profile.sound then
												PlaySoundFile("Sound\\Doodad\\Karazahn_WoodenDoors_Close_A.wav")
											end

											addon.db.profile.open = not addon.db.profile.open
										end)

	frame.handle:SetScript("OnEnter", function(self)
											--SetCursor("Interface\\AddOns\\oRA3\\images\\cursor")
											SetCursor("INTERACT_CURSOR")
											GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
											GameTooltip:SetText("Click to open/close oRA3")
											GameTooltip:Show()
										end)

	frame.handle:SetScript("OnLeave",function(self)
										   SetCursor(nil)
										   GameTooltip:Hide()
									   end)

	frame.close:SetScript("OnClick", function() 
		if RaidFrame:IsVisible() then
			HideUIPanel(FriendsFrame)
		else
			frame.handle:Click() 
		end
	end)

	local subframe = CreateFrame("Frame", "oRA3FrameSub", oRA3Frame)
	subframe:SetPoint("TOPLEFT", 0, 0)
	subframe:SetPoint("BOTTOMRIGHT", 0, 0)
	subframe:SetAlpha(0)




	local function resizebg(frame)
		local width = frame:GetWidth() - 5
		-- bg1 will be okay due to minresize

		-- We'll resize bg2 up to 256
		local bg2w = width - 256
		local bg3w
		if bg2w > 256 then
			bg3w = bg2w - 256
			bg2w = 256
		end

		if bg2w > 0 then
			frame.bg2:SetWidth(bg2w)
			frame.bg2:SetTexCoord(0, (bg2w / 256), 0, 1)
			frame.bg2:Show()
		else
			frame.bg2:Hide()
		end

		
		if bg3w and bg3w > 0 then
			frame.bg3:SetWidth(bg3w)
			frame.bg3:SetTexCoord(0, (bg3w / 256), 0, 1)
			frame.bg3:Show()
		else
			frame.bg3:Hide()
		end
	end

	oRA3Frame.resizebg = resizebg

	resize:SetScript("OnMouseDown", function(frame)
										oRA3Frame:StartSizing()
										oRA3Frame:SetScript("OnUpdate", resizebg)
									end)
	resize:SetScript("OnMouseUp", function(frame)
									  oRA3Frame:StopMovingOrSizing()
									  oRA3Frame:SetScript("OnUpdate", nil)
									  -- FIXME
									  -- self:SavePosition("oRA3Frame")
									  -- subframe.text:UpdateSize()
									  -- subframe.scroll:UpdateScrollChildRect()
									  oRA3Frame.resizebg(oRA3Frame)
								  end)
	resizebg(frame)
	
	self:LockUnlockFrame()
	
end


function addon:LockUnlockFrame()
	local subframe = oRA3FrameSub

	oRA3Frame:ClearAllPoints()

	if self.db.profile.attached then
		-- Lock the frame
		oRA3Frame.titlereg:Hide()
		oRA3Frame.resize:Hide()
		oRA3Frame.handle:Show()
		oRA3Frame:SetWidth(375) --325
		oRA3Frame:SetHeight(425) -- 450
		oRA3Frame.resizebg(oRA3Frame)
		oRA3Frame:SetFrameStrata("MEDIUM")
		oRA3Frame.close:Show()
		oRA3Frame:SetParent(RaidFrame)

		-- subframe.text:UpdateSize()

		if self.db.profile.open then
			oRA3Frame:SetPoint("LEFT", RaidFrame, "RIGHT", -50, 31)
			subframe:Show()
			subframe:SetAlpha(1)
			subframe.open = true
		else
			oRA3Frame:SetPoint("LEFT", RaidFrame, "RIGHT", -360, 31)
			subframe:Hide()
			subframe:SetAlpha(0)
		end
	else
		-- Unlock the frame
		oRA3Frame.titlereg:Show()
		oRA3Frame.resize:Show()
		oRA3Frame.handle:Hide()
		oRA3Frame:SetFrameStrata("HIGH")
		oRA3Frame.close:Hide()

		-- Make sure we can see the frame
		subframe:Show()
		subframe:SetAlpha(1)

		-- Update the size of the scroll child
		-- subframe.text:UpdateSize()

		-- Restore the position
		self:RestorePosition("oRA3Frame")
	end
end

function addon:SavePosition(name)
    local f = getglobal(name)
    local x,y = f:GetLeft(), f:GetTop()
    local s = f:GetEffectiveScale()
    
    x,y = x*s,y*s
    
	local opt = self.db.profile.positions[name]
	if not opt then 
		self.db.profile.positions[name] = {}
		opt = self.db.profile.positions[name]
	end
    opt.PosX = x
    opt.PosY = y
	opt.Width = f:GetWidth()
	opt.Height = f:GetHeight()
end

function addon:RestorePosition(name)
	local f = getglobal(name)
	local opt = self.db.profile.positions[name]
	if not opt then 
		self.db.profile.positions[name] = {}
		opt = self.db.profile.positions[name]
	end

	local x = opt.PosX
	local y = opt.PosY

    local s = f:GetEffectiveScale()
        
    if not x or not y then
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        return 
    end

    x,y = x/s,y/s

    f:ClearAllPoints()
	f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)

	-- restore height/width if stored
	if opt.Width then
		f:SetWidth(opt.Width)
	end

	if opt.Height then
		f:SetHeight(opt.Height)
	end

	-- Resize the background
	f.resizebg(f)
end

function addon:AttachFrame()
	self:Print("Re-Attaching the oRA3 Frame")

	self.db.profile.attached = true
	self:LockUnlockFrame()
end

function addon:DetachFrame()
	self:Print("Detaching the oRA3 Frame")

	self.db.profile.attached = false
	self:LockUnlockFrame()
end

function addon:ChangeBGAlpha(value)
	value = tonumber(value)

	self.db.profile.bgalpha = value

	local frame = oRA3Frame
	local textures = {
		"topleft",
		"top",
		"topright",
		"midleft",
		"mid",
		"midright",
		"botleft",
		"bot",
		"botright",
		"bg1",
		"bg2",
		"bg3",
		"resize",
		"titlereg",
		"handle",
		"close",
	}

	for k,v in pairs(textures) do
		frame[v]:SetAlpha(value)
	end
end


function addon:UpdateGUI()
	self:SetupGUI()
	if not oRA3Frame:IsVisible() then return end
	-- update the overviews
end


-- Overviews

-- register an overview
-- name (string) - name of the overview Tab
-- refreshfunc - name of the function to call to refresh the overview
-- .. tuple - name, table  -- contains name of the sortable column and table to get the data from
function addon:RegisterOverview(name, refreshfunc, ...)
end

function addon:UnregisterOverview(name)
	-- hide and recycle
end


function util:clearTable(t)
	for k, v in pairs(t) do
		t[k] = nil
	end
	return t
end

function util:inTable(t, value)
	for k, v in pairs(t) do
		if v == value then return true end
	end
	return nil
end

