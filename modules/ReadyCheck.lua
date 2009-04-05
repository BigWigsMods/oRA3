local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("ReadyCheck", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
orar = module
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

local readycheck -- table containing ready check results
local frame -- will be filled with our GUI frame

local readyAuthor = "" -- author of the current readycheck
local playerName = UnitName("player")
local playerClass = select(2,UnitClass("player"))
local noreply, notready = "", "" -- result of ready check strings
local topMemberFrames, bottomMemberFrames = {}, {} -- ready check member frames

-- local constants
local RD_RAID_MEMBERS_NOTREADY = L["The following players are not ready: %s"]
local RD_READY_CHECK_OVER_IN = L["Ready check over in %d seconds"]
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

	-- init readycheck handling
	if not readycheck then readycheck = {} end
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
	local name = oRA:InRaid() and UnitName("raid"..id) or UnitName("party"..id)
	if confirm == 1 then -- ready
		readycheck[name] = RD_READY
	elseif readycheck[name] ~= RD_OFFLINE then -- not ready, ignore offline
		readycheck[name] = RD_NOTREADY
	end
	self:UpdateGUI()
end


function module:READY_CHECK_FINISHED(event)
	-- close the frame after 5 seconds
	self:ScheduleTimer("HideGUI", 5)
	if frame then
		frame.timer = 0
		frame.timerText:SetText(READY_CHECK_FINISHED)
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
	frame:Show()
end

function module:HideGUI()
	if not frame then return end
	
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
		for i = 1, num, 1 do
			local rname, _, subgroup, _, _, fileName, _, online = GetRaidRosterInfo(i)
			if subgroup > 5 then
				bottomnum = bottomnum + 1
				self:SetMemberStatus(bottomnum, true, rname, fileName)
			else
				topnum = topnum + 1
				self:SetMemberStatus(topnum, false, rname, fileName)
			end
		end
	else
		num = 1
		self:SetMemberStatus(num, playerName, playerClass)
		for i =1, MAX_PARTY_MEMBERS, 1 do
			if GetPartyMember(i) then
				num = num + 1
				topnum = topnum + 1
				self:SetMemberStatus(num, true, UnitName("party"..i), select(2,UnitClass("party"..i)) )
			end
		end
	end

	local height = math.max( ( math.ceil(bottomnum/2) *14 ) + (math.ceil(topnum/2)*14) + 84, 300)
	frame:SetHeight(height)
	
	-- position the spacer
	local yoff = ((math.ceil(topnum/2)*14) + 70) * -1
	frame.bar:ClearAllPoints()
	frame.bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, yoff)
	frame.bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, yoff)

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

function module:SetupGUI()
	if frame then return end

	frame = CreateFrame("Frame", "oRA3ReadyCheck", UIParent)
	table.insert(_G["UISpecialFrames"], "oRA3ReadyCheck") -- close on esc
	
	frame:SetPoint("BOTTOMLEFT", ReadyCheckFrame, "TOPLEFT", 6, -10)
	frame:SetPoint("BOTTOMRIGHT", ReadyCheckFrame, "TOPRIGHT", -6, -10)	
	frame:SetHeight( 300 )

	local topleft = frame:CreateTexture(nil, "BORDER")
	topleft:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopLeft")
	topleft:SetWidth(128)
	topleft:SetHeight(256)
	topleft:SetPoint("TOPLEFT", 0, 0)

	local topright = frame:CreateTexture(nil, "BORDER")
	topright:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopRight")
	topright:SetWidth(140)
	topright:SetHeight(256)
	topright:SetPoint("TOPRIGHT", 0, 0)
	topright:SetTexCoord(0, (140 / 256), 0, 1)

	local top = frame:CreateTexture(nil, "BORDER")
	top:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-Top")
	top:SetHeight(256)
	top:SetPoint("TOPLEFT", topleft, "TOPRIGHT", 0, 0)
	top:SetPoint("TOPRIGHT", topright, "TOPLEFT", 0, 0)
	
	local botleft = frame:CreateTexture(nil, "BORDER")
	botleft:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-BotLeft")
	botleft:SetWidth(128)
	botleft:SetHeight(168)
	botleft:SetPoint("BOTTOMLEFT", 0, 0)
	botleft:SetTexCoord(0, 1, 0, (168 / 256))

	local botright = frame:CreateTexture(nil, "BORDER")
	botright:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-BotRIght")
	botright:SetWidth(140)
	botright:SetHeight(168)
	botright:SetPoint("BOTTOMRIGHT", 0, 0)
	botright:SetTexCoord(0, (140 / 256), 0, (168 / 256))

	local bot = frame:CreateTexture(nil, "BORDER")
	bot:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-Bot")
	bot:SetHeight(168)
	bot:SetPoint("TOPLEFT", botleft, "TOPRIGHT", 0, 0)
	bot:SetPoint("TOPRIGHT", botright, "TOPLEFT", 0, 0)
	bot:SetTexCoord(0, 1, 0, (168 / 256))

	local bg1 = frame:CreateTexture(nil, "BACKGROUND")
	bg1:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScoreFrame-TopBackground")
	bg1:SetHeight(64)
	bg1:SetPoint("TOPLEFT", topleft, "TOPLEFT", 5, -4)
	bg1:SetPoint("TOPRIGHT", topright, "TOPRIGHT", -5, -4)	


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
	
	
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 5, 4)
	
	local headerText = frame:CreateFontString(nil, "OVERLAY")
	headerText:SetPoint("TOP", frame, "TOP", 0, -5)
	headerText:SetFontObject(GameFontNormal)
	headerText:SetText(READY_CHECK)
	
	local timerText = frame:CreateFontString(nil, "OVERLAY")
	timerText:SetPoint("TOP", frame, "TOP", 0, -35)
	timerText:SetFontObject(GameFontNormal)
	timerText:SetText("test")
	frame.timerText = timerText
	
	frame:SetScript("OnUpdate", function(this,elapsed)
				if this.timer and this.timer > 0 then
					this.timer = this.timer - elapsed
					if this.oldtimer - this.timer >= 1  or this.oldtimer == -1 then
						this.oldtimer = this.timer
						timerText:SetText( string.format(RD_READY_CHECK_OVER_IN, floor(this.timer) ) )
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
	local yoff = bottom and 0 or -50
	if num % 2 == 0 then xoff = 160	end
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
