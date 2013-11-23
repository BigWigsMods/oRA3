local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("RoleIcons")

module.VERSION = tonumber(("$Revision$"):sub(12, -3))

local countIcons
local raidIcons = setmetatable({}, { __index = function(t,i)
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

local updateIcons
do
	local count = {}
	function updateIcons()
		wipe(count)
		for i = 1, GetNumGroupMembers() do
			local button = _G["RaidGroupButton"..i]
			if button and button.subframes then -- make sure the raid button is set up
				local icon = raidIcons[i]
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
		for role, icon in next, countIcons.icons do
			icon.count:SetText(count[role] or 0)
		end
	end
end

local createCountIcons
do
	local roster = { [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {}, [8] = {} }
	local function onEnter(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		GameTooltip:SetText(_G["INLINE_" .. self.role .. "_ICON"] .. _G[self.role])
		for i = 1, GetNumGroupMembers() do
			local name, _, group, _, _, _, _, _, _, _, _, groupRole = GetRaidRosterInfo(i)
			if groupRole == self.role then
				tinsert(roster[group], name)
			end
		end
		for group, list in ipairs(roster) do
			sort(list)
			for _, name in ipairs(list) do
				GameTooltip:AddLine(("[%d] %s"):format(group, name), 1, 1, 1)
			end
			wipe(list)
		end
		GameTooltip:Show()
	end

	function createCountIcons()
		countIcons = CreateFrame("Frame", "oRA3RaidFrameRoleIcons", RaidFrame)
		countIcons:SetPoint("TOPLEFT", 51, 8)
		countIcons:SetSize(30, 30)

		countIcons.icons = {}
		for i, role in ipairs({"TANK", "HEALER", "DAMAGER"}) do
			local frame = CreateFrame("Frame", nil, countIcons)
			frame:SetPoint("LEFT", 30 * (i - 1) - 2 * (i - 1), 0)
			frame:SetSize(30, 30)

			local icon = frame:CreateTexture(nil, "OVERLAY")
			icon:SetTexture([[Interface\LFGFrame\UI-LFG-ICON-ROLES]])
			icon:SetTexCoord(GetTexCoordsForRole(role))
			icon:SetAllPoints()
			frame.icon = icon

			local count = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			count:SetPoint("BOTTOMRIGHT", -2, 2)
			count:SetText(0)
			frame.count = count

			frame.role = role
			frame:SetScript("OnEnter", onEnter)
			frame:SetScript("OnLeave", GameTooltip_Hide)

			countIcons.icons[role] = frame
		end
	end
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

		createCountIcons()
		if RaidFrame:IsShown() then
			updateIcons()
		end

		hooksecurefunc("RaidGroupFrame_Update", updateIcons)
	end
end

