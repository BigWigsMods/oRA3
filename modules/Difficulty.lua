local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("Difficulty", "AceTimer-3.0")

module.VERSION = tonumber(("$Revision$"):sub(12, -3))

function module:OnRegister()
	local defaults = {
		profile = {
		}
	}

	self.db = oRA.db:RegisterNamespace("Difficulty", defaults)
	oRA.RegisterCallback(self, "OnShutdown")

	hooksecurefunc("SetRaidDifficultyID", function(difficultyID)
		if difficultyID > 13 and difficultyID < 17 then
			module.db.profile.prevRaidDifficulty = difficultyID
		end
	end)
end

do
	local function restoreDifficulty()
		if not IsInGroup() then
			local diff = module.db.profile.prevRaidDifficulty
			if GetRaidDifficultyID() ~= diff then
				SetRaidDifficultyID(diff)
			end
		end
	end
	function module:OnEnable()
		if module.db.profile.prevRaidDifficulty and not IsInGroup() then
			-- GROUP_JOINED fires ~3s after PLAYER_LOGIN when you first login, so IsInGroup() is false until then
			self:ScheduleTimer(restoreDifficulty, 4)
		end
	end
end

function module:OnShutdown()
	if self.db.profile.prevRaidDifficulty then
		if not IsInInstance() then -- don't change on leaving group while still in the instance
			SetRaidDifficultyID(self.db.profile.prevRaidDifficulty)
			self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
		else
			self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnShutdown")
		end
	end
end

