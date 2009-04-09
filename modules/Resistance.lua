
-- Resistance is transmitted after the player changes his gear.
-- Resistance information will be available from the oRA3 gui for everyone.
local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Resistance")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

local resistances = {}

local f -- frame defined later

function module:OnRegister()
	oRA:RegisterList(
		L["Resistances"],
		resistances, 
		L["Name"], 
		L["Frost"],
		L["Fire"],
		L["Shadow"],
		L["Nature"],
		L["Arcane"]
	)
end

function module:OnEnable()
	oRA.RegisterCallback(self, "OnCommResistance")
	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
end

function module:OnDisable()
	oRA:UnregisterList(L["Resistances"])
	oRA.UnregisterCallback(self, "OnCommResistance")
	oRA.UnregisterCallback(self, "OnStartup")
	oRA.UnregisterCallback(self, "OnShutdown")
end

function module:OnStartup()
	wipe(resistances)
	f:RegisterEvent("UNIT_INVENTORY_CHANGED")
	f:RegisterEvent("UNIT_RESISTANCES")
	self:CheckResistance()
end

function module:OnShutdown()
	f:UnregisterEvent("UNIT_INVENTORY_CHANGED")
	f:UnregisterEvent("UNIT_RESISTANCES")
end

do
	f = CreateFrame("Frame")
	local total = 0
	local function onUpdate(self, elapsed)
		total = total + elapsed
		if total > 2 then
			module:CheckResistance()
			total = 0
			self:SetScript("OnUpdate", nil)
		end
	end
	f:SetScript("OnEvent", function(self, event, unit)
		if unit and unit ~= "player" then return end
		if total > 0 then
			total = 0
		else
			self:SetScript("OnUpdate", onUpdate)
		end
	end)

	local ret = {}
	function module:CheckResistance()
		wipe(ret)
		for i = 2, 6 do
			local _, r = UnitResistance("player", i)
			table.insert(ret, r)
		end
		oRA:SendComm("Resistance", unpack(ret))
	end
end

-- Resistance answer
function module:OnCommResistance(commType, sender, fr, nr, frr, sr, ar)
	local k = util:inTable(resistances, sender, 1)
	if not k then
		table.insert(resistances, { sender } )
		k = util:inTable(resistances, sender, 1)
	end
	resistances[k][2] = fr
	resistances[k][3] = nr
	resistances[k][4] = frr
	resistances[k][5] = sr
	resistances[k][6] = ar
	
	oRA:UpdateList(L["Resistances"])
end

