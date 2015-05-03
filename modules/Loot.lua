
local addonName, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Loot", "AceTimer-3.0")
local L = scope.locale

local db
local defaults = {
	profile = {
		enable = false,
		party = {
			method = "group", -- Group Loot
			threshold = 2, -- Green (should be blizzard default setting)
		},
		raid = {
			method = "master", -- master looter
			threshold = 2, -- Green (should be blizzard default setting)
		},
	}
}

local options
local function getOptions()
	if not options then
		options = {
			type = "group",
			name = LOOT_METHOD,
			args = {
				enable = {
					type = "toggle",
					name = L.autoLootMethod,
					desc = L.autoLootMethodDesc,
					get = function() return db.enable end,
					set = function(k, v) db.enable = v end,
					order = 1,
					width = "full",
				},
				raid = {
					order = 2,
					type = "group",
					name = RAID,
					inline = true,
					get = function( k ) return db.raid[k.arg] end,
					set = function( k, v ) db.raid[k.arg] = v end,
					disabled = function() return not db.enable end,
					width = "full",
					args = {
						method = {
							type = "select", name = LOOT_METHOD,
							arg = "method",
							values = {
								needbeforegreed = LOOT_NEED_BEFORE_GREED,
								freeforall = LOOT_FREE_FOR_ALL,
								roundrobin = LOOT_ROUND_ROBIN,
								master = LOOT_MASTER_LOOTER,
								group = LOOT_GROUP_LOOT,
								personalloot = LOOT_PERSONAL_LOOT,
							}
						},
						threshold = {
							type = "select", name = LOOT_THRESHOLD,
							arg = "threshold",
							values = {
								[2] = ITEM_QUALITY2_DESC,
								[3] = ITEM_QUALITY3_DESC,
								[4] = ITEM_QUALITY4_DESC,
								[5] = ITEM_QUALITY5_DESC,
								[6] = ITEM_QUALITY6_DESC,
							},
						},
						master = {
							type = "input", name = MASTER_LOOTER, desc = L.makeLootMaster,
							arg = "master",
						},
					},
				},
				party = {
					order = 3,
					type = "group",
					name = PARTY,
					inline = true,
					get = function( k ) return db.party[k.arg] end,
					set = function( k, v ) db.party[k.arg] = v end,
					disabled = function() return not db.enable end,
					width = "full",
					args = {
						method = {
							type = "select", name = LOOT_METHOD,
							arg = "method",
							values = {
								needbeforegreed = LOOT_NEED_BEFORE_GREED,
								freeforall = LOOT_FREE_FOR_ALL,
								roundrobin = LOOT_ROUND_ROBIN,
								master = LOOT_MASTER_LOOTER,
								group = LOOT_GROUP_LOOT,
								personalloot = LOOT_PERSONAL_LOOT,
							}
						},
						threshold = {
							type = "select", name = LOOT_THRESHOLD,
							arg = "threshold",
							values = {
								[2] = ITEM_QUALITY2_DESC,
								[3] = ITEM_QUALITY3_DESC,
								[4] = ITEM_QUALITY4_DESC,
								[5] = ITEM_QUALITY5_DESC,
								[6] = ITEM_QUALITY6_DESC,
							}
						},
						master = {
							type = "input", name = MASTER_LOOTER, desc = L.makeLootMaster,
							arg = "master",
						},
					},
				},
			},
		}
	end
	return options
end

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("Loot", defaults)
	db = self.db.profile

	oRA.RegisterCallback(self, "OnPromoted", "SetLoot")
	oRA.RegisterCallback(self, "OnGroupChanged")
	oRA.RegisterCallback(self, "OnProfileUpdate", function()
		db = self.db.profile
	end)

	oRA:RegisterModuleOptions("Loot", getOptions, LOOT_METHOD)
end

do
	local prevStatus = 0
	function module:OnGroupChanged(_, groupStatus)
		if groupStatus ~= prevStatus then
			prevStatus = groupStatus
			if groupStatus > 0 then
				self:SetLoot()
			end
		end
	end
end

do
	local function updateLoot(self)
		self.timer = nil
		if UnitIsGroupLeader("player") then
			local method, threshold, master
			if IsInRaid() then
				method = db.raid.method
				threshold = db.raid.threshold
				master = db.raid.master
			else
				method = db.party.method
				threshold = db.party.threshold
				master = db.party.master
			end
			if not master or master == "" then master = UnitName("player") end
			local current = GetLootMethod()
			if current and current == method then return end
			SetLootMethod(method, master, threshold)
			if method == "master" or method == "group" then
				self:ScheduleTimer(SetLootThreshold, 2, threshold)
			end
			-- SetLootMethod("method"[,"masterPlayer" or ,threshold])
			-- method  "group", "freeforall", "master", "neeedbeforegreed", "roundrobin", "personalloot".
			-- threshold  0 poor  1 common  2 uncommon  3 rare  4 epic  5 legendary  6 artifact
		end
	end

	function module:SetLoot()
		if db.enable and not self.timer and IsInGroup() then
			-- Delay loot setting, hopefully fixes #154.
			self.timer = self:ScheduleTimer(updateLoot, 2, self)
		end
	end
end
