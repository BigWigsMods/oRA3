
local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("BattleRes", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

module.VERSION = tonumber(("$Revision: 712 $"):sub(12, -3))

local resAmount = 1
local ticker = 0
local timeToGo = 0
local redemption, feign = (GetSpellInfo(27827)), (GetSpellInfo(5384))
local theDead = {}
local updateFunc
local brez
local inCombat = false
local IsEncounterInProgress = IsEncounterInProgress

local function createFrame()
	brez = CreateFrame("Frame", "oRA3BattleResMonitor", UIParent)
	brez:SetPoint("CENTER", UIParent, "CENTER")
	brez:SetWidth(100)
	brez:SetHeight(25)
	brez:EnableMouse(true)
	brez:RegisterForDrag("LeftButton")
	brez:SetClampedToScreen(true)
	brez:SetMovable(true)
	brez:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
	brez:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() oRA3:SavePosition("oRA3BattleResMonitor") end)
	brez:SetScript("OnEvent", updateFunc)

	local header = brez:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetSize(0,0)
	header:SetPoint("BOTTOM", brez, "TOP")
	header:SetJustifyH("CENTER")
	header:SetText(L.battleResTitle)
	brez.header = header

	local timer = brez:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	timer:SetSize(0,0)
	timer:SetPoint("RIGHT", brez, "RIGHT")
	timer:SetTextColor(1,1,1)
	timer:SetJustifyH("RIGHT")
	timer:SetText("0:00")
	brez.timer = timer

	local remaining = brez:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	remaining:SetSize(0,0)
	remaining:SetPoint("LEFT", brez, "LEFT")
	remaining:SetTextColor(1,1,1)
	remaining:SetJustifyH("LEFT")
	remaining:SetText("0")
	brez.remaining = remaining

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
	brez.scroll = scroll
end

local function toggleLock()
	if not brez then return end
	if module.db.profile.lock then
		brez:EnableMouse(false)
		brez.header:Hide()
	else
		brez:EnableMouse(true)
		brez.header:Show()
	end
end

local function toggleShow()
	if not brez then return end
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
				module:ZONE_CHANGED_NEW_AREA()
			end,
			args = {
				showDisplay = {
					type = "toggle",
					name = colorize(L["Show monitor"]),
					desc = L.battleResShowDesc,
					width = "full",
					descStyle = "inline",
					order = 1,
				},
				lock = {
					type = "toggle",
					name = colorize(L["Lock monitor"]),
					desc = L.battleResLockDesc,
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
	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
end

function module:OnStartup()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:ZONE_CHANGED_NEW_AREA()
end

do
	local function addOne()
		resAmount = resAmount + 1
		brez.remaining:SetText(resAmount)
		ticker = 0
	end

	local function updateTime()
		ticker = ticker + 1
		local time = timeToGo - ticker
		local m = floor(time/60)
		local s = mod(time, 60)
		brez.timer:SetFormattedText("%d:%02d", m, s)

		if next(theDead) then
			for k in next, theDead do
				if UnitBuff(k, redemption) or UnitBuff(k, feign) or UnitIsFeignDeath(k) then -- The backup plan, you need one with Blizz
					theDead[k] = nil
				elseif not UnitIsDeadOrGhost(k) and UnitIsConnected(k) and UnitAffectingCombat(k) then
					resAmount = resAmount - 1
					brez.remaining:SetText(resAmount)
					theDead[k] = nil
				end
			end
		end
	end

	local countUpdater, timeUpdater = nil, nil
	local function updateStatus()
		if not inCombat and IsEncounterInProgress() then
			inCombat = true
			wipe(theDead)
			resAmount = 1
			ticker = 0
			brez.remaining:SetText(resAmount)
			-- XXX fix mythic scaling
			local _, _, _, _, _, _, _, _, instanceGroupSize = GetInstanceInfo()
			timeToGo = (90/instanceGroupSize)*60
			countUpdater = module:ScheduleRepeatingTimer(addOne, timeToGo)
			timeUpdater = module:ScheduleRepeatingTimer(updateTime, 1)
			brez:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			brez.scroll:Clear()
		elseif inCombat and not IsEncounterInProgress() then
			inCombat = false
			brez:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			module:CancelTimer(countUpdater)
			module:CancelTimer(timeUpdater)
			brez.remaining:SetText("0")
			brez.timer:SetText("0:00")
		end
	end

	function module:ZONE_CHANGED_NEW_AREA()
		local _, type = GetInstanceInfo()
		if type == "raid" and self.db.profile.showDisplay then
			if not inCombat then self:CancelAllTimers() end

			if not brez then
				createFrame()
				createFrame = nil
				self:ScheduleTimer(function()
					print("|cFF33FF99oRA3|r: We've added a new Battle Res Monitor! It will show how many resses you have available, and the time remaining until you gain another res.")
					print("|cFF33FF99oRA3|r: As it's brand new it may be buggy. We're looking for input and tweaking it as required.")
				end, 5)
			end
			toggleLock()
			toggleShow()
			oRA3:RestorePosition("oRA3BattleResMonitor")

			self:ScheduleRepeatingTimer(updateStatus, 0.1)
		end
	end
end

function module:OnShutdown()
	if brez then
		brez:Hide()
		brez:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		module:CancelAllTimers()
		brez.remaining:SetText("0")
		brez.timer:SetText("0:00")
	end
end

do
	local function getPetOwner(pet, guid)
		if UnitGUID("pet") == guid then
			return module:UnitName("player")
		end

		local owner
		if IsInRaid() then
			for i=1, GetNumGroupMembers() do
				if UnitGUID(("raid%dpet"):format(i)) == guid then
					owner = ("raid%d"):format(i)
					break
				end
			end
		else
			for i=1, GetNumSubgroupMembers() do
				if UnitGUID(("party%dpet"):format(i)) == guid then
					owner = ("party%d"):format(i)
					break
				end
			end
		end
		if owner then
			return module:UnitName(owner)
		end
		return pet
	end

	updateFunc = function(_, _, _, event, ...)
		local _, sGuid, name, _, _, tarGuid, tarName, _, _, spellId, spellName = ...
		if event == "SPELL_RESURRECT" then
			if spellId == 126393 then -- Eternal Guardian
				name = getPetOwner(name, sGuid)
			end

			local tbl = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS -- Support custom class color addons, if installed
			local _, class = UnitClass(tarName)
			local t = class and tbl[class] or GRAY_FONT_COLOR -- Failsafe, rarely UnitClass can return nil
			_, class = UnitClass(name)
			local s = class and tbl[class] or GRAY_FONT_COLOR -- Failsafe, rarely UnitClass can return nil
			local shortName = name:gsub("%-.+", "*")
			local shortTarName = tarName:gsub("%-.+", "*")
			brez.scroll:AddMessage(
				("|Hplayer:%s|h|cFF%02x%02x%02x%s|r|h >> |Hplayer:%s|h|cFF%02x%02x%02x%s|r|h"):format(
					name, s.r * 255, s.g * 255, s.b * 255, shortName, tarName, t.r * 255, t.g * 255, t.b * 255, shortTarName
				)
			)

		-- Lots of lovely checks before adding someone to the deaths table
		elseif event == "UNIT_DIED" and UnitIsPlayer(tarName) and UnitGUID(tarName) == tarGuid and not UnitIsFeignDeath(tarName) and not UnitBuff(tarName, redemption) and not UnitBuff(tarName, feign) then 
			theDead[tarName] = true
		end
	end
end

