
local addonName, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("RoleIcons")

local countIcons -- frame containing the totals by role

local updateIcons
do
	local roleIcons = setmetatable({}, { __index = function(t,i)
		local parent = _G["RaidGroupButton"..i]
		local icon = CreateFrame("Frame", nil, parent)
		icon:SetSize(14, 14)
		icon:SetPoint("RIGHT", parent.subframes.level, "LEFT", 2, 0)
		RaiseFrameLevel(icon)

		local texture = icon:CreateTexture(nil, "ARTWORK")
		texture:SetAllPoints()
		texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		icon.texture = texture

		icon:Hide()

		t[i] = icon
		return icon
	end })

	local count = {}
	function updateIcons()
		if not oRA.db.profile.showRoleIcons then
			countIcons:Hide()
			for _,icon in next, roleIcons do
				icon:Hide()
			end
			return
		end
		if not IsInRaid() then
			countIcons:Hide()
			return
		end

		wipe(count)
		for i = 1, GetNumGroupMembers() do
			local button = _G["RaidGroupButton"..i]
			if button and button.subframes then -- make sure the raid button is set up
				local icon = roleIcons[i]
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
		countIcons:Show()
	end
end

local createCountIcons
do
	local roster = {}
	for i=1,NUM_RAID_GROUPS do roster[i] = {} end
	local function sortColoredNames(a, b) return a:sub(11) < b:sub(11) end
	local function onEnter(self)
		local role = self.role
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		GameTooltip:SetText(_G["INLINE_" .. role .. "_ICON"] .. _G[role])
		for i = 1, GetNumGroupMembers() do
			local name, _, group, _, _, class, _, _, _, _, _, groupRole = GetRaidRosterInfo(i)
			if name and groupRole == role then
				local color = oRA.classColors[class]
				local coloredName = ("|cff%02x%02x%02x%s"):format(color.r * 255, color.g * 255, color.b * 255, name:gsub("%-.+", "*"))
				tinsert(roster[group], coloredName)
			end
		end
		for group, list in ipairs(roster) do
			sort(list, sortColoredNames)
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

			local texture = frame:CreateTexture(nil, "OVERLAY")
			texture:SetTexture([[Interface\LFGFrame\UI-LFG-ICON-ROLES]])
			texture:SetTexCoord(GetTexCoordsForRole(role))
			texture:SetAllPoints()
			frame.texture = texture

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

function module:OnRegister()
	self:RegisterEvent("ADDON_LOADED")
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

