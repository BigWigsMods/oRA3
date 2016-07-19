
local addonName, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("GuildRepairs")
local L = scope.locale

-- luacheck: globals ChatTypeInfo DEFAULT_CHAT_FRAME

local db = nil
local processedRanks = {}

local function updateRepairs()
	if next(processedRanks) then
		module:OnShutdown()
		module:OnGroupChanged(nil, oRA:GetGroupStatus(), oRA:GetGroupMembers())
	end
end
local function colorize(input) return ("|cfffed000%s|r"):format(input) end
local options = {
	type = "group",
	name = L.guildRepairs,
	args = {
		ensureRepair = {
			type = "toggle",
			name = colorize(L.ensureRepair),
			desc = L.ensureRepairDesc,
			descStyle = "inline",
			get = function() return db.ensureRepair end,
			set = function(info, value)
				db.ensureRepair = value
				updateRepairs()
			end,
			order = 1,
			width = "full",
		},
		amount = {
			type = "input",
			name = colorize(L.repairAmount),
			desc = L.repairAmountDesc,
			get = function() return tostring(db.amount) end,
			set = function(info, value)
				local oldAmount = db.amount
				db.amount = tonumber(value) or 500
				if oldAmount ~= db.amount then
					updateRepairs()
				end
			end,
			order = 2,
		}
	}
}

function module:OnProfileUpdate()
	db = self.db.profile
	-- migrate settings
	if oRA.db.profile.ensureRepair ~= nil then
		db.ensureRepair = oRA.db.profile.ensureRepair
		oRA.db.profile.ensureRepair = nil
		oRA.db.profile.repairFlagStorage = nil
		oRA.db.profile.repairAmountStorage = nil
	end
end

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("GuildRepairs", {
		profile = {
			ensureRepair = false,
			amount = 500, -- previous default was the guild leader's item level
			repairFlagStorage = {},
			repairAmountStorage = {},
		}
	})
	oRA.RegisterCallback(self, "OnProfileUpdate")
	self:OnProfileUpdate()
	oRA:RegisterModuleOptions("GuildRepairs", options)
end

function module:OnEnable()
	oRA.RegisterCallback(self, "OnPromoted")
	oRA.RegisterCallback(self, "OnDemoted")
	oRA.RegisterCallback(self, "OnGroupChanged")
	oRA.RegisterCallback(self, "OnConvertParty", "OnShutdown")
	oRA.RegisterCallback(self, "OnShutdown")
end

-----------------------------------------------------------------------
-- Ensure guild repairs
--

function module:OnPromoted()
	self:OnGroupChanged(nil, oRA:GetGroupStatus(), oRA:GetGroupMembers())
end

function module:OnDemoted()
	if next(processedRanks) then
		self:OnShutdown()
	end
end

function module:OnGroupChanged(_, status, members)
	if not db.ensureRepair or not IsGuildLeader() or status < 2 or (oRA:IsPromoted() or 0) < 2 then return end
	if status == 3 then -- don't enable for LFR or BGs
		if next(processedRanks) then -- disable for premades
			self:OnShutdown()
		end
		return
	end

	for _, name in next, members do
		local rankIndex = oRA:IsGuildMember(name)
		if rankIndex and not processedRanks[rankIndex] then
			processedRanks[rankIndex] = true
			GuildControlSetRank(rankIndex)
			local repair = select(15, GuildControlGetRankFlags())
			if not repair then
				db.repairFlagStorage[rankIndex] = true
				GuildControlSetRankFlag(15, true)
				local c = ChatTypeInfo["SYSTEM"]
				local rankName = GuildControlGetRankName(rankIndex)
				DEFAULT_CHAT_FRAME:AddMessage(L.repairEnabled:format(rankName), c.r, c.g, c.b)
			end
			local maxAmount = GetGuildBankWithdrawGoldLimit() or 0
			if maxAmount == 0 then
				db.repairAmountStorage[rankIndex] = true
				SetGuildBankWithdrawGoldLimit(db.amount)
			end
		end
	end
end

function module:OnShutdown()
	if IsGuildLeader() then
		for rankIndex in next, processedRanks do
			GuildControlSetRank(rankIndex)
			if db.repairFlagStorage[rankIndex] then
				GuildControlSetRankFlag(15, false)
			end
			if db.repairAmountStorage[rankIndex] then
				SetGuildBankWithdrawGoldLimit(0)
			end
		end
	end
	wipe(db.repairAmountStorage)
	wipe(db.repairFlagStorage)
	wipe(processedRanks)
end
