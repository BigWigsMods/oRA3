
-- Resistance is transmitted after the player changes his gear.
-- Resistance information will be available from the oRA3 gui for everyone.
local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local util = oRA.util
local module = oRA:NewModule("Resistance")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")

local names = {}
local frost = {}
local nature = {}
local shadow = {}
local fire = {}
local arcane = {}

local f -- frame defined later

function module:OnRegister()
	oRA:RegisterList(
		L["Resistances"],
		L["Name"], names,
		L["Frost"], frost,
		L["Fire"], fire,
		L["Shadow"], shadow,
		L["Nature"], nature,
		L["Arcane"], arcane
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
	local k = util:inTable(names, sender)
	if not k then
		table.insert(names, sender)
		k = util:inTable(names, sender)
	end
	fire[k] = fr
	nature[k] = nr
	frost[k] = frr
	shadow[k] = sr
	arcane[k] = ar
	
	oRA:UpdateList(L["Resistances"])
end

