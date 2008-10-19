
-- Unlike oRA2 there are no real durability checks.
-- Durability is transmitted when the player dies or zones or closes a merchant window
-- Durability information will be available from the oRA3 gui for everyone.

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("Durability", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

-- TODO: make sure these tables are cleaned up a bit from old members

-- following tables are all indexed by name
local tperc = {} -- average durability %
local tbroken = {} -- # broken items
local tminimum = {} -- minimum durability %

-- function pointer for the overview refresh button
local refreshfunc

function module:OnEnable()
	-- Durability Events
	self:RegisterEvent("PLAYER_DEAD", "CheckDurability")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckDurability")
	self:RegisterEvent("MERCHANT_CLOSED", "CheckDurability")

	oRA.RegisterCallback(self, "OnCommDurability") -- evil hax to pass our module self
	oRA.RegisterCallback(self, "OnCommCheckDurability") 

	-- should register durability table with the oRA3 core GUI for sortable overviews
	-- TODO: localization crapola drek
	oRA:RegisterOverview(L["Durability"], refreshfunc, L["avg"], tperc, L["min"], tminimum, L["broken"], tbroken)
	
	self:CheckDurability()
end

function module:OnDisable()
	oRA:UnregisterOverview(L["Durability"])
	oRA.UnregisterCallback(self, "OnCommDurability")
	oRA.UnregisterCallback(self, "OnCommCheckDurability")
end

local oldperc, oldbroken, oldminimum = 0,0,0
local override = false
local lastCheck = 0

function module:CheckDurability(event)
	local perc, cur, max, broken, imin, imax, vmin = 0, 0, 0, 0, 0, 0, 100
	for i=1,18 do
		imin, imax = GetInventoryItemDurability( i )
		if imin and imax then
			vmin = math.min( math.floor(imin/imax * 100), vmin)
			if imin == 0 then broken = broken + 1 end
			cur = cur + imin
			max = max + imax			
		end
	end
	perc = math.floor(cur / max * 100)

	if oldperc ~= perc or oldbroken ~= broken or oldminimum ~= vmin or override then
		override = false
		oldperc = perc
		oldbroken = broken
		oldminimum = vmin
		oRA:SendComm("Durability", perc, vmin, broken) -- durability here is not localized on purpose, we don't localize comm transmissions
	end
end

-- Durability answer
function module:OnCommDurability(commType, sender, perc, minimum, broken)
	tperc[sender] = perc.."%"
	tminimum[sender] = minimum.."%"
	tbroken[sender] = broken
	oRA:UpdateGUI()
end

-- Forced durability check
function module:OnCommCheckDurability(commType, sender)
	local t = time()
	if t - lastCheck > 30 then -- only do this once every 30 seconds.
		lastCheck = t
		override = true
		self:CheckDurability()
	end
end

function refreshfunc()
	oRA:SendComm("CheckDurability")
end
