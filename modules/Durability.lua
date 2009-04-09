
-- Durability is transmitted when the player dies or zones or closes a merchant window
-- Durability information will be available from the oRA3 gui for everyone.

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Durability", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

local durability = {} 

function module:OnRegister()
	-- should register durability table with the oRA3 core GUI for sortable overviews
	oRA:RegisterList(
		L["Durability"],
		durability,
		L["Name"],
		L["Average"],
		L["Minimum"],
		L["Broken"]
	)
end

function module:OnEnable()
	oRA.RegisterCallback(self, "OnCommDurability") -- evil hax to pass our module self
	oRA.RegisterCallback(self, "OnStartup") 
	oRA.RegisterCallback(self, "OnShutdown")
	
	for i = 1, 40 do
		table.insert(durability, { UnitName("player")..i, math.random(1, 100), math.random(1, 100), math.random(1, 100) } )
	end
end

function module:OnDisable()
	oRA:UnregisterList(L["Durability"])
	oRA.UnregisterCallback(self, "OnCommDurability")
	oRA.UnregisterCallback(self, "OnStartup")
	oRA.UnregisterCallback(self, "OnShutdown")
end

function module:OnStartup()

	wipe(durability)
	
	self:RegisterEvent("PLAYER_DEAD", "CheckDurability")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckDurability")
	self:RegisterEvent("MERCHANT_CLOSED", "CheckDurability")
	
	self:CheckDurability()
end

function module:OnShutdown()
	self:UnregisterEvent("PLAYER_DEAD")
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	self:UnregisterEvent("MERCHANT_CLOSED")
end

local oldperc, oldbroken, oldminimum = 0,0,0

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
	local k = util:inTable(durability, sender, 1)
	if not k then
		table.insert(durability, { sender } )
		k = util:inTable(durability, sender, 1)
	end
	durability[k][2] = perc
	durability[k][3] = minimum
	durability[k][4] = broken

	oRA:UpdateList(L["Durability"])
end

