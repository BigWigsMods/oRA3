local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("RoleIcons")
--local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local L = setmetatable({}, {__index = function(t,k) return k end})

module.VERSION = tonumber(("$Revision: $"):sub(12, -3))

local db = nil
local options = nil

local raidFrameIcons = setmetatable({}, { __index = function(t,i)
	local parent = _G["RaidGroupButton"..i]
	local icon = CreateFrame("Frame", nil, parent)
	icon:SetSize(14, 14)
	icon:SetPoint("RIGHT", parent.subframes.level, "LEFT", 2, 0)
	RaiseFrameLevel(icon)

	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints()
	icon.texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
	icon:Hide()

	t[i] = icon
	return icon
end })

local function updateRaidFrameIcons()
	if not db.enableRaidFrame then return end
	for i = 1, GetNumGroupMembers() do
		local button = _G["RaidGroupButton"..i]
		if button and button.subframes then -- make sure the raid button is set up
			local icon = raidFrameIcons[i]
			local role = UnitGroupRolesAssigned("raid"..i)
			if role and role ~= "NONE" then
				icon.texture:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
				icon:Show()
			else
				icon:Hide()
			end
		end
	end
end

local function colorize(input) return ("|cfffed000%s|r"):format(input) end
local function getOptions()
	if not options then
		options = {
			type = "group",
			name = L["Role Icons"],
			get = function(k) return db[k[#k]] end,
			set = function(k, v) db[k[#k]] = v end,
			args = {
				enableRaidFrame = {
					type = "toggle",
					name = colorize(L["Raid Frame"]),
					desc = L["Show role icons on the Blizzard raid group frames."],
					get = function(k) return db[k[#k]] end,
					set = function(k, v)
						db[k[#k]] = v
						for _, icon in next, raidFrameIcons do
							icon:Hide()
						end
						if RaidFrame:IsShown() and RaidGroupFrame_Update then
							updateRaidFrameIcons()
						end
					end,
					width = "full",
					descStyle = "inline",
					order = 1,
				},
				--[[
				enableReadyCheck = {
					type = "toggle",
					name = colorize(L["Ready Check"]),
					desc = L["Show role icons on the oRA3 ready check window."],
					width = "full",
					descStyle = "inline",
					order = 2,
				},
				--]]
			},
		}
	end
	return options
end

function module:OnRegister()
	local database = oRA.db:RegisterNamespace("RoleIcons", {
		profile = {
			enableRaidFrame = true,
			--enableReadyCheck = true,
		}
	})
	db = database.profile

	oRA.RegisterCallback(self, "OnProfileUpdate", function()
		db = database.profile
	end)
	oRA:RegisterModuleOptions("RoleIcons", getOptions, L["Role Icons"])
end

function module:OnEnable()
	if RaidGroupFrame_Update then
		self:ADDON_LOADED("Blizzard_RaidUI")
		if RaidFrame:IsShown() then
			updateRaidFrameIcons()
		end
	else
		self:RegisterEvent("ADDON_LOADED")
	end
end

function module:ADDON_LOADED(name)
	if name == "Blizzard_RaidUI" then
		self:UnregisterEvent("ADDON_LOADED")
		hooksecurefunc("RaidGroupFrame_Update", updateRaidFrameIcons)
	end
end

