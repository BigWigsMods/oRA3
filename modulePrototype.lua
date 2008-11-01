local addon = LibStub("AceAddon-3.0"):GetAddon("oRA3")

local prototype = {}

function prototype:OnInitialize()
	if type(self.OnRegister) == "function" then
		self:OnRegister()
	end
end
