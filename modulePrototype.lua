local addon = LibStub("AceAddon-3.0"):GetAddon("oRA3")

local prototype = {}

function prototype:OnInitialize()
	if self.VERSION and self.VERSION > addon.VERSION then
		addon.VERSION = self.VERSION
	end
	if type(self.OnRegister) == "function" then
		self:OnRegister()
		self.OnRegister = nil
	end
end

function prototype:OnDisable()
	if self.VERSION and self.VERSION > addon.VERSION then
		addon.VERSION = self.VERSION
	end
	if type(self.OnModuleDisable) == "function" then
		self:OnModuleDisable()
	end
	self:UnregisterAllEvents()
end

addon:SetDefaultModulePrototype(prototype)

prototype.RegisterEvent = addon.RegisterEvent
prototype.UnregisterEvent = addon.UnregisterEvent
prototype.UnregisterAllEvents = addon.UnregisterAllEvents
prototype.SendComm = addon.SendComm

do
	local UnitName = UnitName
	function prototype:UnitName(unit)
		local name, server = UnitName(unit)
		if server and server ~= "" then
			name = name .."-".. server
		end
		return name
	end
end

