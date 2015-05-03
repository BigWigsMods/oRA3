
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
			master = "",
		},
		raid = {
			method = "master", -- master looter
			threshold = 2, -- Green (should be blizzard default setting)
			master = "",
		},
	}
}

local options
local function getOptions()
	if not options then
		options = {
			type = "group",
			name = LOOT_METHOD,
			get = function(info)
				local cat, key = info[#info-1], info[#info]
				return db[cat][key]
			end,
			set = function(info, value)
				local cat, key = info[#info-1], info[#info]
				db[cat][key] = value
				module:SetLoot()
			end,
			disabled = function() return not db.enable end,
			args = {
				enable = {
					type = "toggle",
					name = L.autoLootMethod,
					desc = L.autoLootMethodDesc,
					get = function(info) return db.enable end,
					set = function(info, value)
						db.enable = value
						module:SetLoot()
					end,
					disabled = false,
					order = 1,
					width = "full",
				},
				raid = {
					order = 2,
					type = "group",
					name = RAID,
					inline = true,
					width = "full",
					args = {
						method = {
							type = "select", name = LOOT_METHOD,
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
							values = {
								[2] = ITEM_QUALITY_COLORS[2].hex .. ITEM_QUALITY2_DESC,
								[3] = ITEM_QUALITY_COLORS[3].hex .. ITEM_QUALITY3_DESC,
								[4] = ITEM_QUALITY_COLORS[4].hex .. ITEM_QUALITY4_DESC,
								[5] = ITEM_QUALITY_COLORS[5].hex .. ITEM_QUALITY5_DESC,
								[6] = ITEM_QUALITY_COLORS[6].hex .. ITEM_QUALITY6_DESC,
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
					width = "full",
					args = {
						method = {
							type = "select", name = LOOT_METHOD,
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
							values = {
								[2] = ITEM_QUALITY_COLORS[2].hex .. ITEM_QUALITY2_DESC,
								[3] = ITEM_QUALITY_COLORS[3].hex .. ITEM_QUALITY3_DESC,
								[4] = ITEM_QUALITY_COLORS[4].hex .. ITEM_QUALITY4_DESC,
								[5] = ITEM_QUALITY_COLORS[5].hex .. ITEM_QUALITY5_DESC,
								[6] = ITEM_QUALITY_COLORS[6].hex .. ITEM_QUALITY6_DESC,
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
			if GetLootMethod() ~= method then
				if method == "master" then
					if master == "" then
						master = UnitName("player")
					end
					SetLootMethod(method, master, 1)
				else
					SetLootMethod(method)
				end
				self:ScheduleTimer(SetLootThreshold, 2, threshold)
			end
		end
	end

	function module:SetLoot()
		if db.enable and not self.timer and IsInGroup() then
			-- Delay loot setting, hopefully fixes #154.
			self.timer = self:ScheduleTimer(updateLoot, 2, self)
		end
	end
end
