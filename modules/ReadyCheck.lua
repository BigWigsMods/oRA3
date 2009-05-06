local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("ReadyCheck", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

module.VERSION = tonumber(("$Revision$"):sub(12, -3))

local readycheck = {} -- table containing ready check results
local frame -- will be filled with our GUI frame

local readyAuthor = "" -- author of the current readycheck
local playerName = UnitName("player")
local playerClass = select(2,UnitClass("player"))
local noreply, notready = "", "" -- result of ready check strings
local topMemberFrames, bottomMemberFrames = {}, {} -- ready check member frames

-- local constants
local RD_RAID_MEMBERS_NOTREADY = L["The following players are not ready: %s"]
local RD_READY_CHECK_OVER_IN = L["Ready Check (%d seconds)"]
local RD_READY = L["Ready"]
local RD_NOTREADY = L["Not Ready"]
local RD_NORESPONSE = L["No Response"]
local RD_OFFLINE = L["Offline"]

function module:OnEnable()
	-- Ready Check Events
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("READY_CHECK_FINISHED")

	self:RegisterChatCommand("rar", DoReadyCheck)
	self:RegisterChatCommand("raready", DoReadyCheck)
end

function module:READY_CHECK(event, name, duration)
	if not oRA:IsPromoted() then return end

	wipe(readycheck)
	-- fill with default 'no response' 
	if oRA:InRaid() then
		for i = 1, GetNumRaidMembers(), 1 do
			local rname, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
			readycheck[rname] = online and RD_NORESPONSE or RD_OFFLINE
		end
	else
		readycheck[playerName] = -1
		for i =1, MAX_PARTY_MEMBERS, 1 do
			if GetPartyMember(i) then
				readycheck[UnitName("party"..i)] = RD_NORESPONSE
			end
		end
	end
	readycheck[name] = RD_READY -- the sender is always ready
	readyAuthor = name

	-- show the readycheck result frame	
	self:ShowGUI()
	frame.timer = duration
	frame.oldtimer = -1
	self:UpdateGUI()
end

function module:READY_CHECK_CONFIRM(event, id, confirm)
	-- this event only fires when promoted, no need to check
	--oRA:Print(event, id, confirm)
	local name = oRA:InRaid() and UnitName("raid"..id) or UnitName("party"..id)
	if confirm == 1 then -- ready
		readycheck[name] = RD_READY
	elseif readycheck[name] ~= RD_OFFLINE then -- not ready, ignore offline
		readycheck[name] = RD_NOTREADY
	end
	self:UpdateGUI()
end


function module:READY_CHECK_FINISHED(event)
	if frame then
		frame.fadeTimer = 1
		frame.timer = 0
		frame.title:SetText(READY_CHECK_FINISHED)
	end
	
	-- report if promoted
	if not oRA:IsPromoted() then return end
	-- report results

	noreply, notready = "", ""
	for name, ready in pairs(readycheck) do
		if ready == RD_NORESPONSE then
			if noreply ~= "" then noreply = noreply..", " end
			noreply = noreply..name
		elseif ready == RD_NOTREADY then
			if notready ~= "" then notready = notready.."," end
			notready = notready..name
		end
	end

	local info = ChatTypeInfo["SYSTEM"]
	if readyAuthor ~= playerName then -- mimic true readycheck results for assistants/leader that did not start the readycheck
		DEFAULT_CHAT_FRAME:AddMessage(READY_CHECK_FINISHED, info.r, info.g, info.b, info.id)
		if noreply ~= "" then
			DEFAULT_CHAT_FRAME:AddMessage(string.format(RAID_MEMBERS_AFK, noreply), info.r, info.g, info.b, info.id)
		elseif notready == "" and noreply == "" then
			DEFAULT_CHAT_FRAME:AddMessage(READY_CHECK_ALL_READY, info.r, info.g, info.b, info.id)
		elseif noreply == "" then
			DEFAULT_CHAT_FRAME:AddMessage(READY_CHECK_NO_AFK, info.r, info.g, info.b, info.id)
		end
	end
	if notready ~= "" then
		DEFAULT_CHAT_FRAME:AddMessage(string.format(RD_RAID_MEMBERS_NOTREADY, notready), info.r, info.g, info.b, info.id)
	end
end

-- GUI

function module:ShowGUI()
	self:SetupGUI()
	frame:SetAlpha(1) -- if we happen to have a readycheck while we're hiding
	frame.fadeTimer = nil -- if we happend to have a readycheck while we're hiding
	frame:Show()
end

function module:HideGUI()
	if not frame then return end
	frame:SetAlpha(1) -- reset
	frame.fadeTimer = nil -- reset
	frame:Hide()
end

function module:SetMemberStatus(num, bottom, name, class)
	local f
	if bottom then
		f = bottomMemberFrames[num] or self:CreateMemberFrame(num, bottom)
	else
		f = topMemberFrames[num] or self:CreateMemberFrame(num, bottom)
	end
	local color = RAID_CLASS_COLORS[class]
	f.NameText:SetText(name)
	f.NameText:SetTextColor(color.r, color.g, color.b)
	f:SetAlpha(1)
	f:Show()
	if readycheck[name] == RD_READY then
		f.IconTexture:SetTexture(READY_CHECK_READY_TEXTURE)
	elseif readycheck[name] == RD_NOTREADY then
		f.IconTexture:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
	elseif readycheck[name] == RD_OFFLINE then
		f:SetAlpha(.5)
		f.IconTexture:SetTexture(READY_CHECK_AFK_TEXTURE)
	else
		f.IconTexture:SetTexture(READY_CHECK_WAITING_TEXTURE)
	end
end

function module:UpdateGUI()
	self:SetupGUI()
	-- loop and update
	local num, f, bottomnum, topnum
	bottomnum = 0
	topnum = 0
	if oRA:InRaid() then
		num = GetNumRaidMembers()
		local diff = GetCurrentDungeonDifficulty()
		local highgroup = 8 -- 40 man it
		if diff and diff == 1 then -- normal
			highgroup = 2
		elseif diff and diff == 2 then -- heroic
			highgroup = 5
		end
		
		for i = 1, num, 1 do
			local rname, _, subgroup, _, _, fileName, _, online = GetRaidRosterInfo(i)
			if subgroup > highgroup then
				bottomnum = bottomnum + 1
				self:SetMemberStatus(bottomnum, true, rname, fileName)
			else
				topnum = topnum + 1
				self:SetMemberStatus(topnum, false, rname, fileName)
			end
		end
	else
		num = 1
		topnum = 1
		self:SetMemberStatus(num, false, playerName, playerClass)
		for i =1, MAX_PARTY_MEMBERS, 1 do
			if GetPartyMember(i) then
				num = num + 1
				topnum = topnum + 1
				self:SetMemberStatus(num, false, UnitName("party"..i), select(2,UnitClass("party"..i)) )
			end
		end
	end

	local height = math.max( ( math.ceil(bottomnum/2) *14 ) + (math.ceil(topnum/2)*14) + 66, 128)
	frame:SetHeight(height)
	
	-- position the spacer
	local yoff = ((math.ceil(topnum/2)*14) + 52) * -1
	frame.bar:ClearAllPoints()
	frame.bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, yoff)
	frame.bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, yoff)

	if bottomnum == 0 then
		frame.bar:Hide()
	else
		frame.bar:Show()
	end
	
	bottomnum = bottomnum + 1
	while( bottomMemberFrames[bottomnum] ) do
		bottomMemberFrames[bottomnum]:Hide()
		bottomnum = bottomnum + 1
	end
	
	topnum = topnum + 1 
	while( topMemberFrames[topnum] ) do
		topMemberFrames[topnum]:Hide()
		topnum = topnum + 1
	end

end

-- /script oRA3:GetModule("ReadyCheck"):ShowGUI()

function module:SetupGUI()
	if frame then return end

	frame = CreateFrame("Frame", "oRA3ReadyCheck", UIParent)
	local f = frame
	f:SetPoint("BOTTOM", UIParent, "CENTER", 0, 30 )
	f:SetWidth( 320 )
	f:SetHeight( 300 )
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)

	local titlebg = f:CreateTexture(nil, "BACKGROUND")
	titlebg:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Title-Background]])
	titlebg:SetPoint("TOPLEFT", 9, -6)
	titlebg:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -28, -24)
	
	local dialogbg = f:CreateTexture(nil, "BACKGROUND")
	dialogbg:SetTexture([[Interface\Tooltips\UI-Tooltip-Background]])
	dialogbg:SetPoint("TOPLEFT", 8, -24)
	dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
	dialogbg:SetVertexColor(0, 0, 0, .75)
	
	local topleft = f:CreateTexture(nil, "BORDER")
	topleft:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	topleft:SetWidth(64)
	topleft:SetHeight(64)
	topleft:SetPoint("TOPLEFT")
	topleft:SetTexCoord(0.501953125, 0.625, 0, 1)
	
	local topright = f:CreateTexture(nil, "BORDER")
	topright:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	topright:SetWidth(64)
	topright:SetHeight(64)
	topright:SetPoint("TOPRIGHT")
	topright:SetTexCoord(0.625, 0.75, 0, 1)
	
	local top = f:CreateTexture(nil, "BORDER")
	top:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	top:SetHeight(64)
	top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
	top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
	top:SetTexCoord(0.25, 0.369140625, 0, 1)
	
	local bottomleft = f:CreateTexture(nil, "BORDER")
	bottomleft:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	bottomleft:SetWidth(64)
	bottomleft:SetHeight(64)
	bottomleft:SetPoint("BOTTOMLEFT")
	bottomleft:SetTexCoord(0.751953125, 0.875, 0, 1)
	
	local bottomright = f:CreateTexture(nil, "BORDER")
	bottomright:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	bottomright:SetWidth(64)
	bottomright:SetHeight(64)
	bottomright:SetPoint("BOTTOMRIGHT")
	bottomright:SetTexCoord(0.875, 1, 0, 1)
	
	local bottom = f:CreateTexture(nil, "BORDER")
	bottom:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	bottom:SetHeight(64)
	bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
	bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")
	bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)
	
	local left = f:CreateTexture(nil, "BORDER")
	left:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	left:SetWidth(64)
	left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
	left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")
	left:SetTexCoord(0.001953125, 0.125, 0, 1)
	
	local right = f:CreateTexture(nil, "BORDER")
	right:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	right:SetWidth(64)
	right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")
	right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
	right:SetTexCoord(0.1171875, 0.2421875, 0, 1)
	
	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 1)
	close:SetScript("OnClick", function(self, button) f:Hide() end)
	
	local title = f:CreateFontString(nil, "ARTWORK")
	title:SetFontObject(GameFontNormal)
	title:SetPoint("TOPLEFT", 12, -8)
	title:SetPoint("TOPRIGHT", -32, -8)
	title:SetText(READY_CHECK)
	f.title = title
	
	local titlebutton = CreateFrame("Button", nil, f)
	titlebutton:SetPoint("TOPLEFT", titlebg)
	titlebutton:SetPoint("BOTTOMRIGHT", titlebg)
	titlebutton:RegisterForDrag("LeftButton")
	titlebutton:SetScript("OnDragStart", function()
		f.moving = true
		f:StartMoving()
	end)
	titlebutton:SetScript("OnDragStop", function()
		f.moving = nil
		f:StopMovingOrSizing()
	end)

	local bar = CreateFrame("Button", nil, frame )
	frame.bar = bar
	bar:Show()
	bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -150)
	bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -150)
	bar:SetHeight(8)

	local barmiddle = bar:CreateTexture(nil, "BORDER")
	barmiddle:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	barmiddle:SetAllPoints(bar)
	barmiddle:SetTexCoord(0.29296875, 1, 0, 0.25)
	
	frame:SetScript("OnUpdate", function(this,elapsed)
				if this.timer and this.timer > 0 then
					this.timer = this.timer - elapsed
					if this.oldtimer - this.timer >= 1  or this.oldtimer == -1 then
						this.oldtimer = this.timer
						title:SetText( string.format(RD_READY_CHECK_OVER_IN, floor(this.timer) ) )
					end
				end
				if this.fadeTimer and this.fadeTimer > 0 then
					this.fadeTimer = this.fadeTimer - elapsed
					if this.fadeTimer <= 0 then
						module:HideGUI()
					else
						this:SetAlpha(this.fadeTimer)
					end
				end
		end )
end


function module:CreateMemberFrame(num, bottom)
	local fname = "oRA3ReadyCheckMember"
	if bottom then
		fname = fname .. "Bottom"
	else
		fname = fname .. "Top"
	end
	fname = fname..num

	local f = CreateFrame("Frame", fname, frame)
	if bottom then
		bottomMemberFrames[num] = f
	else
		topMemberFrames[num] = f
	end
	
	local xoff = bottom and 7 or 15
	local yoff = bottom and 0 or -32
	if num % 2 == 0 then xoff = 160 end
	yoff = yoff + ((math.floor(num/2) + (num % 2)) * -14)
	
	f:SetWidth( 150)
	f:SetHeight(14)
	if bottom then
		f:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", xoff, yoff ) -- fixme relative to the marker
	else
		f:SetPoint("TOPLEFT", frame, "TOPLEFT", xoff, yoff)
	end
	
	local rdc = CreateFrame("Frame", fname.."Icon", f, "ReadyCheckStatusTemplate")
	f.Icon = rdc
	f.IconTexture = _G[fname.."IconTexture"]
	rdc:SetWidth(11)
	rdc:SetHeight(11)
	rdc:SetPoint("LEFT", f, "LEFT")
	
	local rdt = f:CreateFontString(fname.."Name","OVERLAY")
	f.NameText = rdt
	rdt:SetJustifyH("LEFT")
	rdt:SetFontObject(GameFontNormal)
	rdt:SetPoint("LEFT", f.Icon, "RIGHT", 3 )
	rdt:SetHeight(14)
	rdt:SetWidth(136)
	
	return f
end
