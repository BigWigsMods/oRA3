
local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
if oRA then return end -- Disabled
local util = oRA.util
local module = oRA:NewModule("BattleRes", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

module.VERSION = tonumber(("$Revision: 712 $"):sub(12, -3))

local resAmount = 1
local ticker = 0
local timeToGo = 0
local redemption, feign = (GetSpellInfo(27827)), (GetSpellInfo(5384))
local theDead = {}

local brez = CreateFrame("Frame", "oRA3BattleResMonitor", UIParent)
brez:SetPoint("CENTER", UIParent, "CENTER")
brez:SetWidth(100)
brez:SetHeight(25)
brez:EnableMouse(true)
brez:RegisterForDrag("LeftButton")
brez:SetClampedToScreen(true)
brez:SetMovable(true)
brez:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
brez:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() oRA3:SavePosition("oRA3BattleResMonitor") end)

local header = brez:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header:SetSize(0,0)
header:SetPoint("BOTTOM", brez, "TOP")
header:SetJustifyH("CENTER")
header:SetText("Battle Res Monitor")

local timer = brez:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
timer:SetSize(0,0)
timer:SetPoint("RIGHT", brez, "RIGHT")
timer:SetTextColor(1,1,1)
timer:SetJustifyH("RIGHT")
timer:SetText("0:00")

local remaining = brez:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
remaining:SetSize(0,0)
remaining:SetPoint("LEFT", brez, "LEFT")
remaining:SetTextColor(1,1,1)
remaining:SetJustifyH("LEFT")
remaining:SetText("0")

local scroll = CreateFrame("ScrollingMessageFrame", "TESTT", brez)
scroll:SetPoint("TOP", brez, "BOTTOM")
scroll:SetFontObject(GameFontNormal)
scroll:SetWidth(1920)
scroll:SetHeight(40)
scroll:SetMaxLines(3)
scroll:SetFading(false)
scroll:SetTextColor(1,1,1)
scroll:SetJustifyH("CENTER")
scroll:SetInsertMode("TOP")
scroll:Show()

local function toggleLock()
	if module.db.profile.lock then
		brez:EnableMouse(false)
		header:Hide()
	else
		brez:EnableMouse(true)
		header:Show()
	end
end

local function toggleShow()
	if module.db.profile.showDisplay then
		brez:Show()
	else
		brez:Hide()
	end
end

local defaults = {
	profile = {
		showDisplay = true,
		lock = false,
	}
}
local function colorize(input) return ("|cfffed000%s|r"):format(input) end
local options
local function getOptions()
	if not options then
		options = {
			type = "group",
			name = "Res Monitor",
			get = function(k) return module.db.profile[k[#k]] end,
			set = function(k, v)
				module.db.profile[k[#k]] = v
				toggleLock()
				toggleShow()
			end,
			args = {
				showDisplay = {
					type = "toggle",
					name = colorize(L["Show monitor"]),
					desc = "Show",
					width = "full",
					descStyle = "inline",
					order = 1,
				},
				lock = {
					type = "toggle",
					name = colorize(L["Lock monitor"]),
					desc = "Lock",
					width = "full",
					descStyle = "inline",
					order = 2,
				},
			}
		}
	end
	return options
end

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("BattleRes", defaults)
	oRA:RegisterModuleOptions("BattleRes", getOptions, "Res Monitor")
	oRA.RegisterCallback(self, "OnShutdown")
end

--[[
difficultyID 14 (Normal flex10-30, previously "Flex")
difficultyID 15 (Heroic flex10-30, new)
difficultyID 16 (Mythic 20, new)
difficultyID 17 (Looking For Raid flex10-30, new)
]]

function module:OnEnable()
	toggleLock()
	toggleShow()
	oRA3:RestorePosition("oRA3BattleResMonitor")
	self:RegisterEvent("ENCOUNTER_START")
	self:RegisterEvent("ENCOUNTER_END")
end

local function addOne()
	resAmount = resAmount + 1
	remaining:SetText(resAmount)
	ticker = 0
	print"oRA3: adding a res"
end

local function updateTime()
	ticker = ticker + 1
	local time = timeToGo - ticker
	local m = floor(time/60)
	local s = mod(time, 60)
	timer:SetFormattedText("%d:%02d", m, s)

	if next(theDead) then
		for k in next, theDead do
			if UnitBuff(k, redemption) or UnitBuff(k, feign) or UnitIsFeignDeath(k) then -- The backup plan, you need one with Blizz
				theDead[k] = nil
			elseif not UnitIsDeadOrGhost(k) and UnitIsConnected(k) and UnitAffectingCombat(k) then
				resAmount = resAmount - 1
				remaining:SetText(resAmount)
				theDead[k] = nil
			end
		end
	end
end

function module:ENCOUNTER_START()
	if not IsInGroup() or not self.db.profile.showDisplay then return end

	resAmount = 1
	ticker = 0
	remaining:SetText(resAmount)
	timeToGo = (90/GetNumGroupMembers())*60
	self:ScheduleRepeatingTimer(addOne, timeToGo)
	self:ScheduleRepeatingTimer(updateTime, 1)
	print("oRA3: Gaining a res every", timeToGo, "seconds.")
	brez:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	scroll:Clear()
end

function module:ENCOUNTER_END()
	brez:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	print("oRA3: Resses back to normal.")
	self:CancelAllTimers()
	remaining:SetText("0")
	timer:SetText("0:00")
end

function module:ZONE_CHANGED_NEW_AREA()
	if not IsEncounterInProgress() then
		self:ENCOUNTER_END() -- Son, did you just ragequit?
	end
end

function module:OnShutdown()
	
end

brez:SetScript("OnEvent", function(_, _, _, event, ...)
	local _, sGuid, name, _, _, tarGuid, tarName, _, _, spellId, spellName = ...
	if event == "SPELL_RESURRECT" then
		print("oRA3:", event, ...)

		local tbl = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS -- Support custom class color addons, if installed
		local _, class = UnitClass(tarName)
		local t = class and tbl[class] or GRAY_FONT_COLOR -- Failsafe, rarely UnitClass can return nil
		_, class = UnitClass(name)
		local s = class and tbl[class] or GRAY_FONT_COLOR -- Failsafe, rarely UnitClass can return nil
		local shortName = name:gsub("%-.+", "*")
		local shortTarName = tarName:gsub("%-.+", "*")
		scroll:AddMessage(
			("|Hplayer:%s|h|cFF%02x%02x%02x[%s]|r|h >> |cFF71d5ff|Hspell:%d|h[%s]|h|r >> |Hplayer:%s|h|cFF%02x%02x%02x[%s]|r|h"):format(
				name, s.r * 255, s.g * 255, s.b * 255, shortName, spellId, spellName, tarName, t.r * 255, t.g * 255, t.b * 255, shortTarName
			)
		)

		--[[local origPlayer = "Unknown"
		for i = 1, GetNumGroupMembers() do
			if UnitGUID(("raid%dpet"):format(i)) == sGuid then
				origPlayer = GetRaidRosterInfo(i)
			end
		end
		local tbl = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS -- Support custom class color addons, if installed
		local _, class = UnitClass(tarName)
		local t = class and tbl[class] or GRAY_FONT_COLOR -- Failsafe, rarely UnitClass can return nil
		_, class = UnitClass(origPlayer)
		local s = class and tbl[class] or GRAY_FONT_COLOR -- Failsafe, rarely UnitClass can return nil
		print("|cFF33FF99bRez|r: ", ("|Hplayer:"..origPlayer.."|h|cFF%02x%02x%02x["..origPlayer:gsub("%-.+", "*").." ("..name..")]|r|h"):format(s.r * 255, s.g * 255, s.b * 255), ">>",
			"|cFF71d5ff|Hspell:126393|h["..spellName.."]|h|r", ">>",
			("|Hplayer:"..tarName.."|h|cFF%02x%02x%02x["..tarName:gsub("%-.+", "*").."]|r|h"):format(t.r * 255, t.g * 255, t.b * 255)
		)]]

	-- Lots of lovely checks before adding someone to the deaths table
	elseif event == "UNIT_DIED" and UnitIsPlayer(tarName) and UnitGUID(tarName) == tarGuid and not UnitIsFeignDeath(tarName) and not UnitBuff(tarName, redemption) and not UnitBuff(tarName, feign) then 
		theDead[tarName] = true
	end
end)

