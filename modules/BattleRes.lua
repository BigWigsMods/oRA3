
local addonName, scope = ...
local oRA = scope.addon
local util = oRA.util
local module = oRA:NewModule("BattleRes", "AceTimer-3.0")
local L = scope.locale

local resAmount = 0
local redemption, feign = (GetSpellInfo(27827)), (GetSpellInfo(5384))
local theDead = {}
local updateFunc
local brez
local inCombat = false

local function createFrame()
	brez = CreateFrame("Frame", "oRA3BattleResMonitor", UIParent)
	brez:SetPoint("CENTER", UIParent, "CENTER")
	oRA3:RestorePosition("oRA3BattleResMonitor")
	brez:SetWidth(140)
	brez:SetHeight(30)
	brez:EnableMouse(true)
	brez:RegisterForDrag("LeftButton")
	brez:SetClampedToScreen(true)
	brez:SetMovable(true)
	brez:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
	brez:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() oRA3:SavePosition("oRA3BattleResMonitor") end)
	brez:SetScript("OnEvent", updateFunc)

	local bg = brez:CreateTexture(nil, "PARENT")
	bg:SetAllPoints(brez)
	bg:SetBlendMode("BLEND")
	bg:SetTexture(0, 0, 0, 0.3)
	brez.background = bg

	local header = brez:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetWidth(200)
	header:SetHeight(20)
	header:SetPoint("BOTTOM", brez, "TOP")
	header:SetJustifyH("CENTER")
	header:SetText(L.battleResTitle)
	brez.header = header

	local timer = brez:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge2")
	timer:SetWidth(200)
	timer:SetHeight(20)
	timer:SetPoint("RIGHT", brez, "RIGHT", -20, 0)
	timer:SetTextColor(1,1,1)
	timer:SetJustifyH("RIGHT")
	timer:SetText("0:00")
	brez.timer = timer

	local remaining = brez:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge2")
	remaining:SetWidth(200)
	remaining:SetHeight(20)
	remaining:SetPoint("LEFT", brez, "LEFT", 20, 0)
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
		brez.background:Hide()
	else
		brez:EnableMouse(true)
		brez.header:Show()
		brez.background:Show()
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
			name = L.battleResTitle,
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
					name = colorize(L.showMonitor),
					desc = L.battleResShowDesc,
					width = "full",
					descStyle = "inline",
					order = 1,
				},
				lock = {
					type = "toggle",
					name = colorize(L.lockMonitor),
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
	oRA:RegisterModuleOptions("BattleRes", getOptions, L.battleResTitle)
	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
end

function module:OnStartup()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:ZONE_CHANGED_NEW_AREA()
end

do
	local GetTime, GetSpellCharges = GetTime, GetSpellCharges
	local function updateTime()
		local charges, maxCharges, started, duration = GetSpellCharges(20484) -- Rebirth
		if not charges then return end
		local time = duration - (GetTime() - started)
		local m = floor(time/60)
		local s = mod(time, 60)
		brez.timer:SetFormattedText("%d:%02d", m, s)

		if next(theDead) then
			for k, v in next, theDead do
				if UnitBuff(k, redemption) or UnitBuff(k, feign) or UnitIsFeignDeath(k) then -- The backup plan, you need one with Blizz
					theDead[k] = nil
				elseif not UnitIsDeadOrGhost(k) and UnitIsConnected(k) and UnitAffectingCombat(k) then
					if v ~= "br" then
						local _, class = UnitClass(k)
						local tbl = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS -- Support custom class color addons, if installed
						local s = class and tbl[class] or GRAY_FONT_COLOR -- Failsafe, rarely UnitClass can return nil
						local shortName = k:gsub("%-.+", "*")
						if class == "SHAMAN" then
							brez.scroll:AddMessage(
								("|cFF71d5ff|Hspell:20608|h%s|h|r >> |cFF%02x%02x%02x%s|r"):format(
									GetSpellInfo(20608), s.r * 255, s.g * 255, s.b * 255, shortName
								)
							)
						else
							brez.scroll:AddMessage(
								("|cFF71d5ff|Hspell:20707|h%s|h|r >> |cFF%02x%02x%02x%s|r"):format(
									GetSpellInfo(20707), s.r * 255, s.g * 255, s.b * 255, shortName
								)
							)
						end
					end
					theDead[k] = nil
				end
			end
		end
	end

	local timeUpdater = nil
	local function updateStatus()
		local charges, maxCharges, started, duration = GetSpellCharges(20484) -- Rebirth
		if charges then
			if not inCombat then
				inCombat = true
				theDead = {}
				timeUpdater = module:ScheduleRepeatingTimer(updateTime, 1)
				brez:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
				brez.scroll:Clear()
			end
			if charges ~= resAmount then
				resAmount = charges
				brez.remaining:SetText(resAmount)
				if charges == 0 then
					brez.remaining:SetTextColor(1,0,0)
				else
					brez.remaining:SetTextColor(0,1,0)
				end
			end
		elseif inCombat and not charges then
			inCombat = false
			resAmount = 0
			brez:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			module:CancelTimer(timeUpdater)
			brez.remaining:SetText(resAmount)
			brez.timer:SetText("0:00")
			brez.remaining:SetTextColor(1,1,1)
		end
	end

	function module:ZONE_CHANGED_NEW_AREA()
		local _, type = GetInstanceInfo()
		if type == "raid" and self.db.profile.showDisplay then
			if not inCombat then self:CancelAllTimers() end

			if not brez then
				createFrame()
				createFrame = nil
			end
			toggleLock()
			toggleShow()

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
		brez.remaining:SetTextColor(1,1,1)
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

	updateFunc = function(_, _, _, event, _, sGuid, name, _, _, tarGuid, tarName, _, _, spellId)
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
				("|cFF%02x%02x%02x%s|r >> |cFF%02x%02x%02x%s|r"):format(
					s.r * 255, s.g * 255, s.b * 255, shortName, t.r * 255, t.g * 255, t.b * 255, shortTarName
				)
			)
			theDead[tarName] = "br"

		-- Lots of lovely checks before adding someone to the deaths table
		elseif event == "UNIT_DIED" and UnitIsPlayer(tarName) and UnitGUID(tarName) == tarGuid and not UnitIsFeignDeath(tarName) and not UnitBuff(tarName, redemption) and not UnitBuff(tarName, feign) then 
			theDead[tarName] = true
		end
	end
end

