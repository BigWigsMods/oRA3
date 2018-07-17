
local addonName, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("BattleRes", "AceTimer-3.0")
local L = scope.locale
local coloredNames = oRA.coloredNames

--luacheck: globals GameFontNormal

local resAmount = 0
local badBuffs = {
	27827, -- Spirit of Redemption
	5384, -- Feign Death
}
local theDead = {}
local updateFunc
local brez
local inCombat = false

local function createFrame()
	brez = CreateFrame("Frame", "oRA3BattleResMonitor", UIParent)
	brez:SetPoint("CENTER", UIParent, "CENTER")
	oRA:RestorePosition("oRA3BattleResMonitor")
	brez:SetWidth(140)
	brez:SetHeight(30)
	brez:EnableMouse(true)
	brez:RegisterForDrag("LeftButton")
	brez:SetClampedToScreen(true)
	brez:SetMovable(true)
	brez:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
	brez:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() oRA:SavePosition("oRA3BattleResMonitor") end)
	brez:SetScript("OnEvent", updateFunc)

	local bg = brez:CreateTexture(nil, "PARENT")
	bg:SetAllPoints(brez)
	bg:SetBlendMode("BLEND")
	bg:SetColorTexture(0, 0, 0, 0.3)
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

	local scroll = CreateFrame("ScrollingMessageFrame", nil, brez)
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
local options = {
	type = "group",
	name = L.battleResTitle,
	get = function(k) return module.db.profile[k[#k]] end,
	set = function(k, v)
		module.db.profile[k[#k]] = v
		toggleLock()
		toggleShow()
		module:CheckOpen()
	end,
	args = {
		header = {
			type = "description",
			name = L.battleResHeader.."\n",
			fontSize = "medium",
			order = 0,
		},
		toggle = {
			type = "execute",
			name = L.toggleMonitor,
			func = function()
				if not brez then
					createFrame()
					createFrame = nil
					brez:Hide()
				end
				if not brez:IsShown() then
					toggleLock()
					brez:Show()
				else
					brez:Hide()
				end
			end,
			disabled = function()
				local inInstance, instanceType =  IsInInstance()
				return not module.db.profile.showDisplay or (inInstance and instanceType == "raid")
			end,
			order = 0.5,
		},
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

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("BattleRes", defaults)
	oRA:RegisterModuleOptions("BattleRes", options)
	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
end

function module:OnStartup()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckOpen")
	self:CheckOpen()
end

function module:OnShutdown()
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	self:Close()
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
				if module:UnitBuffByIDs(k, badBuffs) or UnitIsFeignDeath(k) then -- The backup plan, you need one with Blizz
					theDead[k] = nil
				elseif not UnitIsDeadOrGhost(k) and UnitIsConnected(k) and UnitAffectingCombat(k) then
					if v ~= "br" then
						brez.scroll:AddMessage(("%s >> %s"):format(GetSpellLink(20707), coloredNames[k])) -- Soulstone
					end
					theDead[k] = nil
				end
			end
		end
	end

	local timeUpdater = nil
	local function updateStatus()
		local charges = GetSpellCharges(20484) -- Rebirth
		if charges then
			if not inCombat then
				inCombat = true
				wipe(theDead)
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

	function module:CheckOpen()
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
		else
			self:Close()
		end
	end
end

function module:Close()
	if brez then
		brez:Hide()
		brez:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:CancelAllTimers()
		brez.remaining:SetText("0")
		brez.timer:SetText("0:00")
		brez.remaining:SetTextColor(1,1,1)
	end
end

do
	local function getPetOwner(pet, guid)
		if UnitGUID("pet") == guid then
			return UnitName("player")
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

	updateFunc = function()
		local _, event, _, sGuid, name, _, _, tarGuid, tarName, _, _, spellId = CombatLogGetCurrentEventInfo()
		if event == "SPELL_RESURRECT" then
			if spellId == 159931 or spellId == 159956 then -- Gift of Chi-Ji, Dust of Life
				name = getPetOwner(name, sGuid)
			end

			brez.scroll:AddMessage(("%s >> %s"):format(coloredNames[name], coloredNames[tarName]))
			theDead[tarName] = "br"

		elseif event == "SPELL_CAST_SUCCESS" and spellId == 21169 then -- Reincarnation
			brez.scroll:AddMessage(("%s >> %s"):format(GetSpellLink(20608), coloredNames[name]))
			theDead[name] = nil

		-- Lots of lovely checks before adding someone to the deaths table
		elseif event == "UNIT_DIED" and UnitIsPlayer(tarName) and UnitGUID(tarName) == tarGuid and not UnitIsFeignDeath(tarName) and not module:UnitBuffByIDs(tarName, badBuffs) then
			theDead[tarName] = true
		end
	end
end
