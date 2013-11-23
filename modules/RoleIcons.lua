local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("RoleIcons")
--local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local L = setmetatable({}, {__index = function(t,k) return k end})

module.VERSION = tonumber(("$Revision: $"):sub(12, -3))

local db = nil
local options = nil

local raidFrameCount = {}
local function raidFrameCount_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetText(_G[self.role])
	for i = 1, GetNumGroupMembers() do
		local name, _, group, _, _, _, _, _, _, _, _, groupRole = GetRaidRosterInfo(i)
		if groupRole == self.role then
			-- TODO sort on group
			local line = ("[%d] %s"):format(group, name)
			GameTooltip:AddLine(line, 1, 1, 1)
		end
	end
	GameTooltip:Show()
end

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

local updateRaidFrameIcons
do
	local count = {}
	function updateRaidFrameIcons()
		if not db.enableRaidFrame then return end
		wipe(count)
		for i = 1, GetNumGroupMembers() do
			local button = _G["RaidGroupButton"..i]
			if button and button.subframes then -- make sure the raid button is set up
				local icon = raidFrameIcons[i]
				local role = UnitGroupRolesAssigned("raid"..i)
				if role and role ~= "NONE" then
					icon.texture:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
					icon:Show()
					count[role] = (count[role] or 0) + 1
				else
					icon:Hide()
				end
			end
		end
		for role, button in next, raidFrameCount do
			button.count:SetText(count[role] or 0)
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
						if not v then
							for _, icon in next, raidFrameIcons do
								icon:Hide()
							end
							for _, button in next, raidFrameCount do
								button:Hide()
							end
						else
							if RaidFrame:IsShown() and RaidGroupFrame_Update then
								updateRaidFrameIcons()
							end
							for _, button in next, raidFrameCount do
								button:Show()
							end
						end
					end,
					width = "full",
					descStyle = "inline",
					order = 1,
				},
				enableReadyCheck = {
					type = "toggle",
					name = colorize(L["Ready Check"]),
					desc = L["Show role icons on the oRA3 ready check window."],
					width = "full",
					descStyle = "inline",
					order = 2,
				},
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
	--oRA:RegisterModuleOptions("RoleIcons", getOptions, L["Role Icons"])
end

function module:OnEnable()
	if RaidGroupFrame_Update then
		self:ADDON_LOADED("Blizzard_RaidUI")
	else
		self:RegisterEvent("ADDON_LOADED")
	end
end

function module:ADDON_LOADED(name)
	if name == "Blizzard_RaidUI" then
		self:UnregisterEvent("ADDON_LOADED")

		for i, role in ipairs({"TANK", "HEALER", "DAMAGER"}) do
			local button = CreateFrame("Frame", "oRA3RaidFrameRoleIcon".._G[role], RaidFrame)
			button:SetSize(30, 30)
			button:SetPoint("TOPLEFT", 52 + 30 * (i - 1), 8)
			button.role = role

			local icon = button:CreateTexture(nil, "OVERLAY")
			icon:SetTexture([[Interface\LFGFrame\UI-LFG-ICON-ROLES]])
			icon:SetTexCoord(GetTexCoordsForRole(role))
			icon:SetAllPoints()
			button.icon = icon

			local count = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			count:SetPoint("BOTTOMRIGHT", -2, 2)
			count:SetText(0)
			button.count = count

			button:SetScript("OnEnter", raidFrameCount_OnEnter)
			button:SetScript("OnLeave", GameTooltip_Hide)

			raidFrameCount[role] = button
		end

		hooksecurefunc("RaidGroupFrame_Update", updateRaidFrameIcons)
		if RaidFrame:IsShown() then
			updateRaidFrameIcons()
		end
	end
end

