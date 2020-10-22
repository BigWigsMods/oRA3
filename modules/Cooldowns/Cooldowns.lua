--------------------------------------------------------------------------------
-- Setup
--

local _, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Cooldowns", "AceTimer-3.0")
local L = scope.locale
local cooldownData = scope.cooldownData
local callbacks = LibStub("CallbackHandler-1.0"):New(module)
local LibDialog = LibStub("LibDialog-1.0")

-- luacheck: globals GameFontHighlight GameFontHighlightLarge GameTooltip_Hide CombatLogGetCurrentEventInfo

--------------------------------------------------------------------------------
-- Locals
--

local activeDisplays = {}
local frame = nil -- main options panel
local showPane, hidePane

local combatLogHandler = CreateFrame("Frame")
local combatOnUpdate = nil

local infoCache = {}
local spellsOnCooldown, chargeSpellsOnCooldown = nil, nil
local deadies = {}
local playerGUID = UnitGUID("player")
local _, playerClass = UnitClass("player")
local instanceType, instanceDifficulty = nil, nil

local spells = cooldownData.spells
local syncSpells = cooldownData.syncSpells
local levelCooldowns = cooldownData.levelCooldowns
local talentCooldowns = cooldownData.talentCooldowns
local chargeSpells, combatResSpells = cooldownData.chargeSpells, cooldownData.combatResSpells
local cdModifiers, chargeModifiers = cooldownData.cdModifiers, cooldownData.chargeModifiers

local mergeSpells = {}
local allSpells = {}
module.allSpells = allSpells
local classLookup = {}
module.classLookup = classLookup

for class, classSpells in next, cooldownData.spells do
	for spellId, info in next, classSpells do
		if type(info) == "number" then
			-- merge multiple ids into one option
			mergeSpells[spellId] = info
			info = classSpells[info]
			classSpells[spellId] = nil
		end
		if info then
			if C_Spell.DoesSpellExist(spellId) then
				allSpells[spellId] = info
				classLookup[spellId] = class
			else
				print("oRA3: Invalid spell id", spellId)
			end
		end
	end
end

local function round(num, q)
	q = 10^(q or 3)
	return floor(num * q + .5) / q
end

function module:GetPlayerFromGUID(guid)
	if infoCache[guid] then
		return infoCache[guid].name, infoCache[guid].class
	end
end

function module:IsSpellUsable(guid, spellId)
	local info = infoCache[guid]
	if not info then return end
	local data = spells[info.class][spellId]
	if not data then return false end

	local _, level, spec, talent, _, race = unpack(data)
	if type(talent) == "table" then
		talent = talent[info.spec]
		if talent == nil then
			return false
		end
		if type(level) == "table" then
			level = level[info.spec]
		end
		-- we already matched the spec
		spec = nil
	end

	return (info.level >= level) and (not race or info.race == race) and
		(not talent or ((talent > 0 and info.talents[talent]) or (talent < 0 and not info.talents[-talent]))) and -- handle talents replacing spells (negative talent index)
		(not spec or spec == info.spec or (type(spec) == "table" and tContains(spec, info.spec)))
end

function module:CheckFilter(display, player)
	-- returns => true = show, nil = hide
	if not UnitExists(player) then return end
	local db = display.filterDB
	local info = infoCache[UnitGUID(player)]
	local isMe = UnitIsUnit(player, "player")

	if db.showOnlyMine and not isMe then return end
	if db.neverShowMine and isMe then return end
	if db.hideDead and UnitIsDeadOrGhost(player) then return end
	if db.hideOffline and not UnitIsConnected(player) then return end
	--if db.hideOutOfCombat and InCombatLockdown() and not UnitAffectingCombat(player) then return end
	if db.hideOutOfRange and not isMe and not UnitInRange(player) then return end
	--if db.hideNameList[player] then return end

	local group = IsInRaid() and "raid" or IsInGroup() and "party" or "solo"
	if db.hideInGroup[group] then return end

	local role = info and GetSpecializationRoleByID(info.spec or 0) or UnitGroupRolesAssigned(player)
	if db.hideRoles[role] then return end

	-- this should probably act on the display itself
	if db.hideInInstance[instanceType] then return end
	if db.hideInInstance.lfg and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return end

	local index = info and info.unit:match("raid(%d+)")
	if index then
		local _, _, subgroup = GetRaidRosterInfo(index)
		if db.hideGroup[subgroup] then return end
	end

	return true
end

function module:GetCooldown(guid, spellId)
	local cd = allSpells[spellId][1]
	if cdModifiers[spellId] and cdModifiers[spellId][guid] then
		cd = cd - cdModifiers[spellId][guid]
	end
	return cd
end

function module:GetRemainingCooldown(guid, spellId)
	if spellsOnCooldown[spellId] and spellsOnCooldown[spellId][guid] then
		local remaining = spellsOnCooldown[spellId][guid] - GetTime()
		return remaining or 0
	end
	return 0
end

function module:GetCharges(guid, spellId)
	return chargeModifiers[spellId] and chargeModifiers[spellId][guid] or chargeSpells[spellId] or 0
end

function module:GetRemainingCharges(guid, spellId)
	local charges = self:GetCharges(guid, spellId)
	if charges > 0 and chargeSpellsOnCooldown[spellId] and chargeSpellsOnCooldown[spellId][guid] then
		return charges - #chargeSpellsOnCooldown[spellId][guid]
	end
	return charges
end

function module:GetRemainingChargeCooldown(guid, spellId)
	local expires = chargeSpellsOnCooldown[spellId] and chargeSpellsOnCooldown[spellId][guid]
	if expires and #expires > 0 then
		return expires[1] - GetTime()
	end
	return self:GetCooldown(guid, spellId)
end


local function updatePlayerCooldownsBySpell(info, spellId)
	local guid, name, class = info.guid, info.name, info.class

	if module:IsSpellUsable(guid, spellId) then
		local cd = module:GetRemainingCooldown(guid, spellId)
		if cd > 0 then
			callbacks:Fire("oRA3CD_StartCooldown", guid, name, class, spellId, cd)
		else
			callbacks:Fire("oRA3CD_CooldownReady", guid, name, class, spellId)
		end
	end

	local maxCharges = module:GetCharges(guid, spellId)
	if maxCharges > 0 then
		callbacks:Fire("oRA3CD_UpdateCharges", guid, name, class, spellId, module:GetRemainingChargeCooldown(guid, spellId), module:GetRemainingCharges(guid, spellId), maxCharges, true)
	end
end

local function updateCooldownsBySpell(spellId)
	callbacks:Fire("oRA3CD_StopCooldown", nil, spellId)
	for _, info in next, infoCache do
		updatePlayerCooldownsBySpell(info, spellId)
	end
end

local function updateCooldownsByGUID(guid)
	local info = infoCache[guid]
	for spellId in next, spells[info.class] do
		callbacks:Fire("oRA3CD_StopCooldown", guid, spellId)
		updatePlayerCooldownsBySpell(info, spellId)
	end
end

local function updateCooldowns()
	for guid in next, infoCache do
		updateCooldownsByGUID(guid)
	end
end


--------------------------------------------------------------------------------
-- Options
--

do
	local ACR = LibStub("AceConfigRegistry-3.0")
	local ACD = LibStub("AceConfigDialog-3.0")
	local AceGUI = LibStub("AceGUI-3.0")
	local CURRENT_DISPLAY = "Default"

	local spellList, reverseClass = nil, {}
	local function SpawnTestBar()
		local display = CURRENT_DISPLAY and activeDisplays[CURRENT_DISPLAY]
		if not display or type(display.TestCooldown) ~= "function" then return end

		if not spellList then
			spellList = {}
			for k in next, allSpells do
				if classLookup[k] ~= "RACIAL" then
					spellList[#spellList + 1] = k
				end
			end
			for name, class in next, oRA._testUnits do
				reverseClass[class] = name
			end
		end

		local spellId = spellList[math.random(1, #spellList)]
		local class = classLookup[spellId]
		local duration = (allSpells[spellId][1] / 30) + math.random(1, 120)
		display:TestCooldown(reverseClass[class], class, spellId, duration)
	end

	local tmp = {}
	local tabStatus, classStatus, filterStatus = { selected = "tab1", scrollvalue = 0 }, { selected = "ALL", scrollvalue = 0 }, { scrollvalue = 0 }
	local displayList = {}
	local classList, classListOrder = nil, nil

	-- Create/Delete

	local function createDisplay(name, copy)
		if copy then -- copy layout from current display
			local db = 	module.db.profile
			db.displays[name] = CopyTable(db.displays[CURRENT_DISPLAY])
			db.spells[name] = CopyTable(db.spells[CURRENT_DISPLAY])
			db.filters[name] = CopyTable(db.filters[CURRENT_DISPLAY])

			db.displays[name].showDisplay = true
			db.displays[name].lockDisplay = false
		end

		local display = module:CreateDisplay(activeDisplays[CURRENT_DISPLAY].type, name)
		activeDisplays[name] = display
		display:Show()

		if copy then
			updateCooldowns()
		end

		-- refresh panel
		CURRENT_DISPLAY = name
		tabStatus.selected = "tab1"
		classStatus.selected = "ALL"
		showPane()
	end

	local function deleteDisplay(name)
		if name == "Default" then
			print("Please don't delete the default display :(")
			return
		end
		local display = activeDisplays[name]
		display:Hide()
		if type(display.Delete) == "function" then
			display:Delete()
		end
		activeDisplays[name] = nil
		module.db.profile.displays[name] = nil
		module.db.profile.spells[name] = nil
		module.db.profile.filters[name] = nil

		-- refresh panel
		if CURRENT_DISPLAY == name then
			CURRENT_DISPLAY = "Default"
		end
		tabStatus.selected = "tab1"
		showPane()
	end

	local function convertDisplay(name, dtype)
		if not activeDisplays[name] or not module:GetDisplayInfo(dtype) then
			error(format("Failed to convert to display type '%s'", dtype), 0)
		end

		local x, y, w, h
		if activeDisplays[CURRENT_DISPLAY].GetPosition then
			x, y, w, h = activeDisplays[CURRENT_DISPLAY]:GetPosition()
		end

		activeDisplays[name]:Hide()
		if type(activeDisplays[name].Delete) == "function" then
			activeDisplays[name]:Delete()
		end

		local display = module:CreateDisplay(dtype, name)
		activeDisplays[name] = display
		display:Show()

		if display.SetPosition then
			display:SetPosition(x, y, w, h)
		end
		updateCooldowns()

		-- refresh panel
		CURRENT_DISPLAY = name
		--tabStatus.selected = "tab1"
		classStatus.selected = "ALL"
		showPane()
	end

	-- StaticPopupDialogs

	LibDialog:Register("ORA3_COOLDOWNS_NEW", { -- data: copy_current_display
		text = L.popupNewDisplay,
		buttons = {
			{
				text = OKAY,
				on_click = function(self, data)
					local name = self.editboxes[1]:GetText():trim()
					if activeDisplays[name] then
						LibDialog:Spawn("ORA3_COOLDOWNS_ERROR_NAME", {name, data})
						return
					end
					createDisplay(name, data)
				end,
			},
			{ text = CANCEL, },
		},
		editboxes = {
			{ auto_focus = true, },
		},
		on_show = function(self, data) showPane() end,
		no_close_button = true,
		hide_on_escape = true,
		show_while_dead = true,
	})

	LibDialog:Register("ORA3_COOLDOWNS_ERROR_NAME", { -- data: {invalid_display_name, copy_current_display}
		icon = [[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]],
		buttons = {
			{ text = OKAY, on_click = function(self, data) LibDialog:Spawn("ORA3_COOLDOWNS_NEW", data[2]) end, },
			{ text = CANCEL, },
		},
		on_show = function(self, data)
			showPane()
			self.text:SetFormattedText(L.popupNameError, data[1])
		end,
		no_close_button = true,
		hide_on_escape = true,
		show_while_dead = true,
	})

	LibDialog:Register("ORA3_COOLDOWNS_DELETE", { -- data: display_name
		buttons = {
			{ text = YES, on_click = function(self, data) deleteDisplay(data) end, },
			{ text = CANCEL, },
		},
		on_show = function(self, data)
			showPane()
			self.text:SetFormattedText(L.popupDeleteDisplay, data)
		end,
		no_close_button = true,
		hide_on_escape = true,
		show_while_dead = true,
	})

	-- Utility

	local function buildDisplayList()
		wipe(displayList)
		wipe(tmp) -- use tmp as our sort table
		for displayName in next, activeDisplays do
			tmp[#tmp+1] = displayName
			local enabled = activeDisplays[displayName].db.showDisplay
			local color = not enabled and GRAY_FONT_COLOR_CODE or HIGHLIGHT_FONT_COLOR_CODE
			displayList[displayName] = ("%s%s|r"):format(color, displayName)
		end
		sort(tmp)

		displayList["__new"] = L.createNewDisplay
		tmp[#tmp+1] = "__new"
		if CURRENT_DISPLAY then
			displayList["__newcopy"] = L.copyDisplay:format(CURRENT_DISPLAY)
			tmp[#tmp+1] = "__newcopy"
			if CURRENT_DISPLAY ~= "Default" then
				displayList["__delete"] = L.deleteDisplay:format(CURRENT_DISPLAY)
				tmp[#tmp+1] = "__delete"
			end
		end

		return displayList, tmp
	end

	local function sortBySpellName(a, b)
		return GetSpellInfo(a) < GetSpellInfo(b)
	end

	local function sortByClass(a, b)
		local classA, classB = classLookup[a], classLookup[b]
		-- push racials to the top
		if classA == "RACIAL" then classA = "ARACIAL" end
		if classB == "RACIAL" then classB = "ARACIAL" end
		if classA == classB then
			return GetSpellInfo(a) < GetSpellInfo(b)
		else
			return classA < classB
		end
	end

	-- Callbacks

	local function onOptionEnter(widget, event)
		if widget:GetUserData("desc") then
			GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
			GameTooltip:SetText(widget:GetUserData("name"), 1, .82, 0, true)
			GameTooltip:AddLine(widget:GetUserData("desc"), 1, 1, 1, true)
			if widget:GetUserData("desc2") then
				GameTooltip:AddLine(widget:GetUserData("desc2"), 0.5, 0.5, 0.8, true)
			end
			GameTooltip:Show()
		elseif widget:GetUserData("name") then
			GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
			GameTooltip:SetText(widget:GetUserData("name"), 1, .82, 0, true)
			GameTooltip:Show()
		elseif widget:GetUserData("id") then
			GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(widget:GetUserData("id"))
			GameTooltip:Show()
		end
	end

	local function onSpellOptionChanged(widget, event, value)
		local spellId = widget:GetUserData("id")
		local display = activeDisplays[CURRENT_DISPLAY]
		display.spellDB[spellId] = value and true or nil
		if type(display.OnSpellOptionChanged) == "function" then
			display:OnSpellOptionChanged(spellId, value)
		end
	end

	local function onFilterOptionChanged(widget, event, value)
		local key = widget:GetUserData("key")
		local display = activeDisplays[CURRENT_DISPLAY]
		local mvalue = widget:GetUserData("value")
		if mvalue then
			display.filterDB[key][mvalue] = value
		else
			display.filterDB[key] = value
		end
		if type(display.OnFilterOptionChanged) == "function" then
			display:OnFilterOptionChanged(key, value)
		end
		showPane()
	end

	local function onOptionChanged(widget, event, value)
		local key = widget:GetUserData("key")
		if key then
			local display = activeDisplays[CURRENT_DISPLAY]
			display.db[key] = value
			if key == "showDisplay" then
				if value then
					display:Show()
					updateCooldowns()
				else
					display:Hide()
				end
			elseif key == "lockDisplay" then
				if value then
					display:Lock()
				else
					display:Unlock()
				end
			end
			showPane()
		end
	end

	local function addOptionToggle(key, name, desc, disabled)
		local db = activeDisplays[CURRENT_DISPLAY].db
		local control = AceGUI:Create("CheckBox")
		control:SetFullWidth(true)
		control:SetLabel(name)
		control:SetValue(db[key] and true or false)
		control:SetUserData("key", key)
		control:SetUserData("name", name)
		control:SetUserData("desc", desc)
		control:SetCallback("OnValueChanged", onOptionChanged)
		control:SetDisabled(disabled)
		return control
	end

	local function addOptionButton(name, func, disabled)
		local control = AceGUI:Create("Button")
		control:SetFullWidth(true)
		control:SetText(name)
		control:SetCallback("OnClick", func)
		control:SetDisabled(disabled)
		return control
	end

	local function addFilterOptionToggle(key, name, desc, disabled)
		local db = activeDisplays[CURRENT_DISPLAY].filterDB
		local control = addOptionToggle(key, name, desc, disabled)
		control:SetValue(db[key] and true or false)
		control:SetCallback("OnValueChanged", onFilterOptionChanged)
		control:SetCallback("OnEnter", onOptionEnter)
		control:SetCallback("OnLeave", GameTooltip_Hide)
		return control
	end

	local function addFilterOptionMultiselect(key, name, desc, values, disabled)
		local db = activeDisplays[CURRENT_DISPLAY].filterDB
		local control = AceGUI:Create("InlineGroup")
		control:SetLayout("Flow")
		control:SetTitle(name)
		control:SetFullWidth(true)

		wipe(tmp)
		for value in next, values do
			tmp[#tmp + 1] = value
		end
		sort(tmp)

		control:PauseLayout()
		for i = 1, #tmp do
			local value = tmp[i]
			local text = values[value]
			local checkbox = AceGUI:Create("CheckBox")
			checkbox:SetRelativeWidth(0.5)
			checkbox:SetLabel(text)
			checkbox:SetDisabled(disabled)
			checkbox:SetValue(db[key][value] and true or false)
			checkbox:SetUserData("key", key)
			checkbox:SetUserData("value", value)
			checkbox:SetCallback("OnValueChanged", onFilterOptionChanged)
			checkbox:SetUserData("name", name)
			checkbox:SetUserData("desc", desc)
			checkbox:SetUserData("desc2", text)
			checkbox:SetCallback("OnEnter", onOptionEnter)
			checkbox:SetCallback("OnLeave", GameTooltip_Hide)
			control:AddChild(checkbox)
		end
		control:ResumeLayout()
		control:DoLayout()

		return control
	end

	local function onDropdownGroupSelected(widget, event, key)
		widget:PauseLayout()
		widget:ReleaseChildren()

		local display = activeDisplays[CURRENT_DISPLAY]
		if key == "ALL" then
			-- selected spells
			wipe(tmp)
			if display then
				for id, value in next, display.spellDB do
					if value then tmp[#tmp + 1] = id end
				end
			end
			if #tmp == 0 then
				local control = AceGUI:Create("Label")
				control:SetFullWidth(true)
				control:SetFontObject(GameFontHighlight)
				control:SetText("\n"..L.noSpells)
				widget:AddChild(control)
			else
				sort(tmp, sortByClass)
				for _, spellId in ipairs(tmp) do
					local name, _, icon = GetSpellInfo(spellId)
					if name then
						local color = oRA.classColors[classLookup[spellId]]
						local checkbox = AceGUI:Create("CheckBox")
						checkbox:SetRelativeWidth(1)
						checkbox:SetLabel(string.format("|c%s%s|r", color.colorStr, name))
						checkbox:SetValue(true)
						checkbox:SetImage(icon)
						checkbox:SetUserData("id", spellId)
						checkbox:SetCallback("OnValueChanged", onSpellOptionChanged)
						checkbox:SetCallback("OnEnter", onOptionEnter)
						checkbox:SetCallback("OnLeave", GameTooltip_Hide)
						widget:AddChild(checkbox)
					end
				end
			end

		elseif spells[key] then
			wipe(tmp)
			for id in next, spells[key] do
				tmp[#tmp + 1] = id
			end
			sort(tmp, sortBySpellName)
			for _, spellId in ipairs(tmp) do
				local name, _, icon = GetSpellInfo(spellId)
				if name then
					local checkbox = AceGUI:Create("CheckBox")
					checkbox:SetRelativeWidth(0.5)
					checkbox:SetLabel(name)
					checkbox:SetValue(display.spellDB[spellId] and true or false)
					checkbox:SetImage(icon)
					checkbox:SetUserData("id", spellId)
					checkbox:SetCallback("OnValueChanged", onSpellOptionChanged)
					checkbox:SetCallback("OnEnter", onOptionEnter)
					checkbox:SetCallback("OnLeave", GameTooltip_Hide)
					widget:AddChild(checkbox)
				end
			end
		end

		widget:ResumeLayout()
		widget:DoLayout()
		frame:DoLayout() -- update the scroll height
	end

	local function onTabGroupSelected(widget, event, value)
		widget:ReleaseChildren()

		if value == "tab1" then -- Spells
			local scroll = AceGUI:Create("ScrollFrame")
			scroll:SetLayout("List")
			scroll:SetFullWidth(true)
			scroll:SetFullHeight(true)

			if oRA.db.profile.showHelpTexts then
				local moduleDescription = AceGUI:Create("Label")
				moduleDescription:SetText(L.selectClassDesc)
				moduleDescription:SetFontObject(GameFontHighlight)
				moduleDescription:SetFullWidth(true)

				scroll:AddChild(moduleDescription)
			end

			local group = AceGUI:Create("DropdownGroup")
			group:SetStatusTable(classStatus)
			group:SetLayout("Flow")
			group:SetFullWidth(true)
			group:SetTitle(L.selectClass)
			group:SetDropdownWidth(165)
			group:SetGroupList(classList, classListOrder)
			group:SetCallback("OnGroupSelected", onDropdownGroupSelected)
			group:SetGroup(classStatus.selected)

			scroll:AddChild(group)
			widget:AddChild(scroll)

		elseif value == "tab2" then -- Settings
			local options = module:GetDisplayOptionsTable(activeDisplays[CURRENT_DISPLAY]) -- options table updated with the current display's db
			if options then
				-- hackery ! need a container so ACD doesn't break things
				local container = AceGUI:Create("SimpleGroup")
				container.type = "oRASimpleGroup" -- we want ACD to create a scrollframe
				container:SetFullHeight(true)
				container:SetFullWidth(true)

				-- have to use :Open (and ACR) instead of just :FeedGroup because some widget types (range, color) call :Open to refresh on change
				ACR:RegisterOptionsTable("oRACooldownsDisplayOptions", options)
				ACD:Open("oRACooldownsDisplayOptions", container)

				widget:AddChild(container)
			end

		elseif value == "tab3" then -- Filters
			local scroll = AceGUI:Create("ScrollFrame")
			scroll:SetStatusTable(filterStatus)
			scroll:SetLayout("List")
			scroll:SetFullWidth(true)
			scroll:SetFullHeight(true)

			-- if oRA.db.profile.showHelpTexts then
			-- 	local moduleDescription = AceGUI:Create("Label")
			-- 	moduleDescription:SetText("Filters are a blacklist, enable options to prevent cooldowns from showing.")
			-- 	moduleDescription:SetFontObject(GameFontHighlight)
			-- 	moduleDescription:SetFullWidth(true)
			--
			-- 	scroll:AddChild(moduleDescription)
			-- end

			local db = activeDisplays[CURRENT_DISPLAY].filterDB
			scroll:AddChild(addFilterOptionToggle("showOnlyMine", L.onlyMyOwnSpells, L.onlyMyOwnSpellsDesc, db.neverShowMine))
			scroll:AddChild(addFilterOptionToggle("neverShowMine", L.neverShowOwnSpells, L.neverShowOwnSpellsDesc, db.showOnlyMine))
			scroll:AddChild(addFilterOptionToggle("hideDead", L.hideDead))
			scroll:AddChild(addFilterOptionToggle("hideOffline", L.hideOffline))
			--scroll:AddChild(addFilterOptionToggle("hideOutOfCombat", L.hideOutOfCombat))
			scroll:AddChild(addFilterOptionToggle("hideOutOfRange", L.hideOutOfRange))
			scroll:AddChild(addFilterOptionMultiselect("hideRoles", ROLE, L.hideRolesDesc, { TANK = TANK, HEALER = HEALER, DAMAGER = DAMAGER }))
			scroll:AddChild(addFilterOptionMultiselect("hideInGroup", GROUP, L.hideInGroupDesc, { party = PARTY, raid = RAID })) -- , solo = SOLO
			scroll:AddChild(addFilterOptionMultiselect("hideInInstance", INSTANCE, L.hideInInstanceDesc, {
				none = NONE, raid = RAID, party = PARTY, lfg = "LFG",
				pvp = BATTLEGROUND, arena = ARENA,
			}))
			scroll:AddChild(addFilterOptionMultiselect("hideGroup", RAID_GROUPS, L.hideGroupDesc, {
				[1] = GROUP_NUMBER:format(1), [2] = GROUP_NUMBER:format(2), [3] = GROUP_NUMBER:format(3), [4] = GROUP_NUMBER:format(4),
				[5] = GROUP_NUMBER:format(5), [6] = GROUP_NUMBER:format(6), [7] = GROUP_NUMBER:format(7), [8] = GROUP_NUMBER:format(8),
			}))

			widget:AddChild(scroll)
		end
	end

	local function onDisplayChanged(widget, event, value)
		if value == "__new" then
			LibDialog:Spawn("ORA3_COOLDOWNS_NEW")
		elseif value == "__newcopy" then
			LibDialog:Spawn("ORA3_COOLDOWNS_NEW", true)
		elseif value == "__delete" then
			LibDialog:Spawn("ORA3_COOLDOWNS_DELETE", CURRENT_DISPLAY)
		else
			CURRENT_DISPLAY = value
			showPane()
		end
	end

	function showPane()
		if not classList then
			classList = { ALL = L.allSpells, RACIAL = "|cffe0e0e0".."Racial Spells".."|r" }
			classListOrder = {}
			for class in next, spells do
				if class ~= "RACIAL" then
					classList[class] = string.format("|c%s%s|r", oRA.classColors[class].colorStr, LOCALIZED_CLASS_NAMES_MALE[class])
					classListOrder[#classListOrder + 1] = class
				end
			end
			table.sort(classListOrder)
			table.insert(classListOrder, 1, "ALL")
			table.insert(classListOrder, 2, "RACIAL")
		end
		if not frame then
			frame = AceGUI:Create("SimpleGroup")
			frame:SetLayout("Flow")
			frame:SetFullWidth(true)

			if not IsInGroup() then
				module:OnStartup()
			end
		end
		frame:ReleaseChildren()

		if not module.db.profile.enabled then
			local text = AceGUI:Create("Label")
			text:SetFullWidth(true)
			text:SetFontObject(GameFontHighlightLarge)
			text:SetText("\n".."Module disabled")
			text.label:SetJustifyH("CENTER")

			frame:AddChildren(text)

			oRA:SetAllPointsToPanel(frame.frame, true)
			frame.frame:Show()
			return
		end

		if not activeDisplays[CURRENT_DISPLAY] then
			CURRENT_DISPLAY = "Default"
		end
		local display = activeDisplays[CURRENT_DISPLAY]

		local list = AceGUI:Create("Dropdown")
		list:SetRelativeWidth(0.5)
		list:SetLabel(DISPLAY)
		list:SetList(buildDisplayList())
		list:SetValue(CURRENT_DISPLAY)
		list:SetCallback("OnValueChanged", onDisplayChanged)

		wipe(tmp)
		local typeDescription = ""
		for _, type in module:IterateDisplayTypes() do
			local name, desc = module:GetDisplayInfo(type)
			tmp[type] = name
			if desc and desc ~= "" then
				typeDescription = ("%s|cff20ff20%s|r: %s\n"):format(typeDescription, name, desc)
			end
		end

		local dtype = AceGUI:Create("Dropdown")
		dtype:SetRelativeWidth(0.5)
		dtype:SetLabel(TYPE)
		dtype:SetList(tmp)
		dtype:SetValue(display and display.type)
		dtype:SetCallback("OnValueChanged", function(_, _, value)
			convertDisplay(CURRENT_DISPLAY, value)
		end)
		dtype:SetCallback("OnEnter", onOptionEnter)
		dtype:SetCallback("OnLeave", GameTooltip_Hide)
		dtype:SetUserData("name", L.displayTypes)
		dtype:SetUserData("desc", ("%s\n|cffff2020%s|r"):format(typeDescription, L.popupConvertDisplay))
		dtype:SetDisabled(not display or not display.db.showDisplay)

		local enable = addOptionToggle("showDisplay", ENABLE, L.showMonitorDesc, not display)
		enable:SetRelativeWidth(0.25)
		local lock = addOptionToggle("lockDisplay", LOCK, L.lockMonitorDesc, not display or not display.db.showDisplay)
		lock:SetRelativeWidth(0.25)
		local test = addOptionButton(L.test, SpawnTestBar, not display or not display.db.showDisplay or not display.TestCooldown)
		test:SetRelativeWidth(0.5)

		local tabs = AceGUI:Create("TabGroup")
		tabs:SetStatusTable(tabStatus)
		tabs:SetLayout("Flow")
		tabs:SetFullWidth(true)
		tabs:SetFullHeight(true)
		tabs:SetTabs({
			{ text = SPELLS, value = "tab1" },
			{ text = SETTINGS, value = "tab2", not module:GetDisplayOptionsTable(display) },
			{ text = FILTERS, value = "tab3" },
		})
		tabs:SetCallback("OnGroupSelected", onTabGroupSelected)
		tabs:SelectTab(tabStatus.selected)

		frame:AddChildren(list, dtype, enable, lock, test, tabs)

		oRA:SetAllPointsToPanel(frame.frame, true)
		frame.frame:Show()
	end

	function hidePane()
		if frame then
			frame:Release()
			frame = nil

			if not IsInGroup() then
				module:OnShutdown()
			end
		end
	end

	function module:OpenDisplayOptions(display)
		if display then
			CURRENT_DISPLAY = display.name
		end
		tabStatus.selected = "tab1"
		oRA:SelectPanel(L.cooldowns, true)
	end
end

--------------------------------------------------------------------------------
-- Module
--

local function upgradeDB(db)
	-- convert db, a little awkward due to the "*" defaults
	if not next(db.displays) then

		-- set spells
		local spellDB = {}
		for k, v in next, db.spells do
			spellDB[k] = v or nil
		end
		db.spells = { Default = spellDB }

		-- set filters
		local filterDB = db.filters.Default
		filterDB.onlyShowMine = db.onlyShowMine
		filterDB.neverShowMine = db.neverShowMine

		-- set up a display with our old bar settings
		local upgraded = nil
		local displayDB = db.displays.Default
		displayDB.type = "Bars"
		displayDB.showDisplay = true
		displayDB.lockDisplay = false
		for k, v in next, db do
			if k ~= "displays" and k ~= "spells" and k ~= "filters" then
				if k:find("^bar") then
					displayDB[k] = type(db[k]) == "table" and CopyTable(db[k]) or db[k]
					upgraded = true
				end
				db[k] = nil
			end
		end

		db.enabled = true

		-- update position
		if oRA.db.profile.positions.oRA3CooldownFrame then
			oRA.db.profile.positions.oRA3CooldownFrameBarsDefault = CopyTable(oRA.db.profile.positions.oRA3CooldownFrame)
			oRA.db.profile.positions.oRA3CooldownFrame = nil
		end

		if upgraded then -- don't show for new profiles
			module:ScheduleTimer(function()
				print("oRA3 Cooldowns has been redesigned and now supports multiple displays and different formats! You can open the options panel with /racd and move it around by dragging the title bar.")
			end, 9)
		end
	end

	-- remove unused spells from the db
	for displayName, dspells in next, db.spells do
		for spell in next, dspells do
			-- Special case for Bloodlust/Heroism. Each id isn't set for the opposite
			-- faction so they would get pruned from profiles shared between factions.
			if not classLookup[spell] and spell ~= 2825 and spell ~= 32182 then
				dspells[spell] = nil
			end
		end
	end
end

function module:OnProfileUpdate(event)
	-- tear down displays
	self:OnShutdown()
	for displayName, display in next, activeDisplays do
		display:Hide()
		if type(display.OnDelete) == "function" then
			display:OnDelete()
		end
		display.frame = nil
		activeDisplays[displayName] = nil
	end

	-- make sure the db is converted
	upgradeDB(self.db.profile)

	-- build displays
	for displayName, db in next, self.db.profile.displays do
		local display = self:CreateDisplay(db.type, displayName)
		activeDisplays[displayName] = display
		display:Hide()
	end
	if IsInGroup() then
		self:OnStartup()
	end

	-- update options
	if frame then
		frame = frame:Release()
		showPane()
	end
end

do
	local function removeDefaults(db, defaults)
		if not db or not defaults then return end
		for k, v in next, defaults do
			if type(v) == "table" and type(db[k]) == "table" then
				removeDefaults(db[k], v)
				if next(db[k]) == nil then
					db[k] = nil
				end
			else
				if db[k] == defaults[k] then
					db[k] = nil
				end
			end
		end
	end

	function module:OnProfileShutdown()
		-- clean up display db defaults (ideally, the logic for this would be in Registery.lua)
		for displayName, display in next, activeDisplays do
			removeDefaults(self.db.profile.displays[displayName], display.defaultDB)
		end
	end
end

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("Cooldowns", {
		profile = {
			spells = {},
			displays = {
				["**"] = {
					showDisplay = true,
					lockDisplay = false,
				}
			},
			filters = {
				["**"] = {
					showOnlyMine = false,
					neverShowMine = false,
					hideDead = false,
					hideOffline = false,
					--hideOutOfCombat = false,
					hideOutOfRange = false,
					hideRoles = {
						TANK = false,
						HEALER = false,
						DAMAGER = false,
					},
					hideInGroup = {
						raid = false, party = false, solo = false,
					},
					hideInInstance = {
						none = false, raid = false, party = false, lfg = false,
						pvp = false, arena = false,
					},
					--hideNameList = {},
					hideGroup = {
						[1] = false, [2] = false, [3] = false, [4] = false,
						[5] = false, [6] = false, [7] = false, [8] = false,
					},
				}
			},
			enabled = true,
		},
		global = {
			spellsOnCooldown = {},
			chargeSpellsOnCooldown = {},
		},
	})

	oRA:RegisterModuleOptions("Cooldowns", {
		type = "group",
		name = L.cooldowns,
		args = {
			enabled = {
				type = "toggle",
				name = ("|cfffed000%s|r"):format(ENABLE),
				desc = L.cooldownsEnableDesc,
				descStyle = "inline",
				get = function(info) return self.db.profile.enabled end,
				set = function(info, value)
					self:OnShutdown()
					self.db.profile.enabled = value
					if value and (IsInGroup() or (frame and frame:IsShown())) then
						self:OnStartup()
					end
					if frame and frame:IsShown() then
						showPane()
					end
				end,
				width = "full",
				order = 1,
			},
			settings = {
				type = "execute",
				name = "Open Settings",
				func = function() self:OpenDisplayOptions("Default") end,
				order = 2,
			},
		}
	})

	self.db.RegisterCallback(self, "OnProfileShutdown")
	oRA.RegisterCallback(self, "OnProfileUpdate")
	self:OnProfileUpdate()

	-- persist cds on reloads
	spellsOnCooldown = self.db.global.spellsOnCooldown
	if not spellsOnCooldown then -- why. WHY!?
		self.db.global.spellsOnCooldown = {}
		spellsOnCooldown = self.db.global.spellsOnCooldown
	end
	chargeSpellsOnCooldown = self.db.global.chargeSpellsOnCooldown
	if not chargeSpellsOnCooldown then
		self.db.global.chargeSpellsOnCooldown = {}
		chargeSpellsOnCooldown = self.db.global.chargeSpellsOnCooldown
	end
	if not self.db.global.lastTime or self.db.global.lastTime > GetTime() then -- probably restarted or crashed, trash times
		wipe(spellsOnCooldown)
		wipe(chargeSpellsOnCooldown)
	end
	self.db.global.lastTime = nil

	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LOGOUT")

	oRA:RegisterPanel(L.cooldowns, showPane, hidePane)

	SLASH_ORACOOLDOWN1 = "/racd"
	SLASH_ORACOOLDOWN2 = "/racooldown"
	SlashCmdList.ORACOOLDOWN = function()
		oRA:SelectPanel(L.cooldowns)
	end
end

function module:OnStartup(_, groupStatus)
	if not self.db.profile.enabled then return end
	self.enabled = true

	if next(syncSpells) then
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	end

	callbacks:Fire("OnStartup")

	oRA.RegisterCallback(self, "OnCommReceived")
	oRA.RegisterCallback(self, "OnGroupChanged")
	self:OnGroupChanged(nil, groupStatus, oRA:GetGroupMembers())

	oRA.RegisterCallback(self, "OnPlayerUpdate")
	oRA.RegisterCallback(self, "OnPlayerRemove")
	oRA:InspectGroup()

	--self:RegisterEvent("PLAYER_REGEN_DISABLED")
	--self:RegisterEvent("PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED")
	self:RegisterEvent("UNIT_CONNECTION")
	combatLogHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:ScheduleRepeatingTimer(combatOnUpdate, 0.1)
end

function module:OnShutdown()
	if not self.enabled then return end
	self.enabled = nil

	callbacks:Fire("OnShutdown")

	oRA.UnregisterCallback(self, "OnCommReceived")
	oRA.UnregisterCallback(self, "OnGroupChanged")
	oRA.UnregisterCallback(self, "OnPlayerUpdate")
	oRA.UnregisterCallback(self, "OnPlayerRemove")

	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
	--self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	--self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("UNIT_HEALTH")
	self:UnregisterEvent("UNIT_CONNECTION")
	combatLogHandler:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	wipe(combatLogHandler.userdata)
	self:CancelAllTimers()

	wipe(infoCache)
	wipe(cdModifiers)
	wipe(chargeModifiers)
	wipe(deadies)
end

function module:PLAYER_LOGOUT()
	self:OnProfileShutdown()

	-- cleanup db spell cds
	local t = GetTime()
	for spellId, players in next, spellsOnCooldown do
		if next(players) == nil then
			spellsOnCooldown[spellId] = nil
		end
	end
	for spellId, players in next, chargeSpellsOnCooldown do
		for guid, expires in next, players do
			for i, e in next, expires do
				if e < t then
					tremove(expires, i)
				end
			end
			if next(expires) == nil then
				players[guid] = nil
			end
		end
		if next(players) == nil then
			chargeSpellsOnCooldown[spellId] = nil
		end
	end
	self.db.global.lastTime = t
end

function module:PLAYER_ENTERING_WORLD()
	_, instanceType, instanceDifficulty = GetInstanceInfo()
end

--------------------------------------------------------------------------------
-- Events
--

function module:SPELL_UPDATE_COOLDOWN()
	for spellId in next, syncSpells do
		local expiry = spellsOnCooldown[spellId] and spellsOnCooldown[spellId][playerGUID]
		if expiry then
			local start, duration = GetSpellCooldown(spellId)
			if start > 0 and duration > 0 then
				if (start + duration + 0.1) < expiry then -- + 0.1 to avoid updating on trivial differences
					local cd =  duration - (GetTime() - start)
					module:SendComm("CooldownUpdate", spellId, round(cd)) -- round to the precision of GetTime (%.3f)
				end
			else -- off cooldown
				module:SendComm("CooldownUpdate", spellId, 0)
			end
		end
	end
end

function module:OnCommReceived(_, sender, prefix, spellId, cd)
	if prefix == "CooldownUpdate" then
		local guid = UnitGUID(sender)
		if not guid then return end
		local name, class = self:GetPlayerFromGUID(guid)
		cd = tonumber(cd)
		spellId = tonumber(spellId)
		if cd > 0 then
			if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
			spellsOnCooldown[spellId][guid] = GetTime() + cd
			callbacks:Fire("oRA3CD_StartCooldown", guid, name, class, spellId, cd)
		else
			if spellsOnCooldown[spellId] and spellsOnCooldown[spellId][guid] then
				spellsOnCooldown[spellId][guid] = nil
			end
			callbacks:Fire("oRA3CD_StopCooldown", guid, spellId)
			callbacks:Fire("oRA3CD_CooldownReady", guid, name, class, spellId)
		end

	elseif prefix == "Reincarnation" then
		local guid = UnitGUID(sender)
		if not guid then return end
		local name = self:GetPlayerFromGUID(guid)
		cd = tonumber(spellId)
		spellId = 20608
		if self:GetRemainingCooldown(guid, spellId) == 0 then
			if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
			spellsOnCooldown[spellId][guid] = GetTime() + cd
			callbacks:Fire("oRA3CD_StartCooldown", guid, name, "SHAMAN", spellId, cd)
		end
	end
end

function module:OnGroupChanged(_, groupStatus, groupMembers)
	if groupStatus == 0 then return end -- OnShutdown should handle it

	for _, player in next, groupMembers do
		local guid = UnitGUID(player)
		if guid then
			if UnitIsDeadOrGhost(player) and not UnitIsFeignDeath(player) and not deadies[guid] then
				deadies[guid] = true
				callbacks:Fire("oRA3CD_UpdatePlayer", guid, player)
				self:RegisterEvent("UNIT_HEALTH")
			end
		end
	end

	if playerClass == "SHAMAN" then
		local start, duration = GetSpellCooldown(20608)
		if start > 0 and duration > 1.5 then
			local cd = duration - (GetTime() - start)
			self:SendComm("Reincarnation", round(cd))
		end
	end
end

function module:OnPlayerUpdate(_, guid, unit, info)
	for _, mods in next, cdModifiers do mods[guid] = nil end
	for _, mods in next, chargeModifiers do mods[guid] = nil end
	infoCache[guid] = info

	if guid == playerGUID then
		self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
		wipe(syncSpells)
		for spellId, data in next, spells[playerClass] do
			if data[5] and self:IsSpellUsable(info.guid, spellId) then
				syncSpells[spellId] = true
			end
		end
	end

	if levelCooldowns[info.class] then
		levelCooldowns[info.class](info)
	end

	for talentIndex, talentId in next, info.talents do
		if talentCooldowns[talentId] then
			talentCooldowns[talentId](info, playerGUID)
		end
	end

	if guid == playerGUID and next(syncSpells) then
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	end

	updateCooldownsByGUID(guid)
end

function module:OnPlayerRemove(_, guid)
	callbacks:Fire("oRA3CD_StopCooldown", guid)

	-- purge info
	for _, t in next, spellsOnCooldown do t[guid] = nil end
	for _, t in next, chargeSpellsOnCooldown do t[guid] = nil end
	for _, t in next, cdModifiers do t[guid] = nil end
	for _, t in next, chargeModifiers do t[guid] = nil end
	infoCache[guid] = nil
	deadies[guid] = nil
end

function module:UNIT_CONNECTION(unit, hasConnected)
	local guid = UnitGUID(unit)
	if guid then
		 -- UnitIsConnected doesn't update with the event apparently
		self:ScheduleTimer(callbacks.Fire, 1, callbacks, "oRA3CD_UpdatePlayer", guid, self:UnitName(unit))
	end
end

function module:UNIT_HEALTH(unit)
	local guid = UnitGUID(unit)
	if guid and deadies[guid] and not UnitIsDeadOrGhost(unit) then
		deadies[guid] = nil
		callbacks:Fire("oRA3CD_UpdatePlayer", guid, self:UnitName(unit))
	end
	if not next(deadies) then
		self:UnregisterEvent("UNIT_HEALTH")
	end
end

do
	local function getPetOwner(pet, guid)
		if UnitGUID("pet") == guid then
			return UnitName("player"), UnitGUID("player")
		end

		local owner
		if IsInRaid() then
			for i=1, GetNumGroupMembers() do
				if UnitGUID(("raid%dpet"):format(i)) == guid then
					owner = ("raid%d"):format(i)
					break
				end
			end
		else
			for i=1, GetNumSubgroupMembers() do
				if UnitGUID(("party%dpet"):format(i)) == guid then
					owner = ("party%d"):format(i)
					break
				end
			end
		end
		if owner then
			return module:UnitName(owner), UnitGUID(owner)
		end
		return pet, guid
	end

	local function resetCooldown(info, spellId, change, charges)
		local guid, player, class = info.guid, info.name, info.class
		local remaining = module:GetRemainingCooldown(guid, spellId)
		if remaining == 0 then return end -- Don't need to do anything

		callbacks:Fire("oRA3CD_StopCooldown", guid, spellId)
		if change then
			remaining = remaining - change
			if remaining < 0 then -- don't restart it
				return resetCooldown(info, spellId)
			end
			if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
			spellsOnCooldown[spellId][guid] = GetTime() + remaining
			callbacks:Fire("oRA3CD_StartCooldown", guid, player, class, spellId, remaining)
		else
			if spellsOnCooldown[spellId] and spellsOnCooldown[spellId][guid] then
				spellsOnCooldown[spellId][guid] = nil
			end
			callbacks:Fire("oRA3CD_CooldownReady", guid, player, class, spellId)
			if charges then
				callbacks:Fire("oRA3CD_UpdateCharges", guid, player, class, spellId, module:GetCooldown(guid, spellId), charges, charges)
			end
		end
	end

	combatLogHandler.userdata = {}
	local scratch = combatLogHandler.userdata

	local specialEvents = setmetatable({}, {__index=function(t, k)
		t[k] = {}
		return t[k]
	end})

	-- Death Knight

	local function armyOfTheDamned(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[19] == 22030 then -- Army of the Damned
			resetCooldown(info, 42650, 5) -- Army of the Dead
			resetCooldown(info, 275699, 1) -- Apocalypse
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[207317] = armyOfTheDamned -- Epidemic

	-- Death Coil
	specialEvents.SPELL_CAST_SUCCESS[47541] = function(srcGUID)
		armyOfTheDamned(srcGUID)

		local info = infoCache[srcGUID]
		if info and info.talents[20] == 21208 then -- Red Thirst
			resetCooldown(info, 55233, 6) -- Vampiric Blood
		end
	end

	-- Death Strike
	specialEvents.SPELL_CAST_SUCCESS[49998] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[20] == 21208 then -- Red Thirst
			local amount = 6.75
			if info.level >= 58 then -- Ossuary
				-- While you have at least 5 Bone Shield charges, the cost of Death Strike is reduced by 5 Runic Power.
				local _, _, stacks = AuraUtil.FindAura(function(spellIdToFind, ...)
					local spellId = select(12, ...)
					return spellIdToFind == spellId
				end, info.unit, "HELPFUL", 195181)
				if stacks and stacks > 4 then
					amount = 6
				end
			end
			resetCooldown(info, 55233, amount) -- Vampiric Blood
		end
	end

	-- Sacrificial Pact
	specialEvents.SPELL_CAST_SUCCESS[327574] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[20] == 21208 then -- Red Thirst
			resetCooldown(info, 55233, 3) -- Vampiric Blood
		end
	end

	-- Raise Ally
	specialEvents.SPELL_CAST_SUCCESS[61999] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[20] == 21208 then -- Red Thirst
			resetCooldown(info, 55233, 4.5)-- Vampiric Blood
		end
	end

	specialEvents.SPELL_AURA_APPLIED_DOSE[195181] = function(srcGUID, _, _, _, amount) -- Bone Shield
		local info = infoCache[srcGUID]
		if info and info.talents[9] then -- Blood Tap
			scratch[srcGUID] = amount
		end
	end
	specialEvents.SPELL_AURA_REMOVED_DOSE[195181] = function(srcGUID, _, _, _, amount) -- Bone Shield
		local info = infoCache[srcGUID]
		if info and info.talents[9] then -- Blood Tap
			scratch[srcGUID] = amount
			resetCooldown(info, 221699, 2) -- Blood Tap
		end
	end
	specialEvents.SPELL_AURA_REMOVED[195181] = function(srcGUID) -- Bone Shield
		local info = infoCache[srcGUID]
		if info and info.talents[9] then -- Blood Tap
			if scratch[srcGUID] == 1 then
				-- Wish _DOSE filed for 1->0
				-- Hopefully it didn't just drop off at 1
				resetCooldown(info, 221699, 2) -- Blood Tap
			end
		end
	end

	local function icecap(srcGUID, _, spellId, ...)
		local info = infoCache[srcGUID]
		if info and scratch[srcGUID] then -- Icecap
			-- only count it once x.x
			local id = 3
			if spellId == 222024 or spellId == 66198 then
				id = 1
			elseif spellId == 222026 or spellId == 66196 then
				id = 2
			end
			if scratch[srcGUID][id] then
				local crit = select(7, ...)
				if crit then
					resetCooldown(info, 51271, 4) -- Pillar of Frost
				end
				scratch[srcGUID][id] = nil
			end
		end
	end
	specialEvents.SPELL_DAMAGE[207230] = icecap -- Frostscythe
	specialEvents.SPELL_DAMAGE[222024] = icecap -- Obliterate
	specialEvents.SPELL_DAMAGE[66198] = icecap -- Obliterate Off-Hand
	specialEvents.SPELL_DAMAGE[222026] = icecap -- Frost Strike
	specialEvents.SPELL_DAMAGE[66196] = icecap -- Frost Strike Off-Hand

	local function icecapCast(srcGUID, _, spellId)
		local info = infoCache[srcGUID]
		if info and info.talents[19] then -- Icecap
			if not scratch[srcGUID] then scratch[srcGUID] = {} end
			local id = 3
			if spellId == 222024 or spellId == 66198 then
				id = 1
			elseif spellId == 222026 or spellId == 66196 then
				id = 2
			end
			scratch[srcGUID][id] = true
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[49020] = icecapCast -- Obliterate
	specialEvents.SPELL_CAST_SUCCESS[49143] = icecapCast -- Frost Strike
	specialEvents.SPELL_CAST_SUCCESS[207230] = icecapCast -- Frostscythe

	-- Demon Hunter

	-- Vengeful Retreat
	specialEvents.SPELL_DAMAGE[198813] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[20] then -- Momentum
			local t = GetTime()
			if t-(scratch[srcGUID] or 0) > 2 then
				scratch[srcGUID] = t
				resetCooldown(info, 198793, 5) -- Vengeful Retreat
			end
		end
	end

	-- Druid
	-- TODO Handle Incarnation/Berserk

	-- Hunter

	-- Barbed Shot
	specialEvents.SPELL_CAST_SUCCESS[185358] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.level > 33 then -- Bestial Wrath (Rank 2)
			-- Bestial Wrath's remaining cooldown is reduced
			-- by 12 sec each time you use Barbed Shot
			resetCooldown(info, 19574, 12) -- Bestial Wrath
		end
	end

	local function callingTheShots(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[19] then -- Calling the Shots
			resetCooldown(info, 288613, 2.5) -- Trueshot
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[185358] = callingTheShots -- Arcane Shot
	specialEvents.SPELL_CAST_SUCCESS[257620] = callingTheShots -- Multi-Shot (Marksmanship)

	local function beastialWrath2(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.level > 31 then -- Carve (Rank 2)
			-- Carve reduces the remaining cooldown on
			-- Wildfire Bomb by 1 sec for each target hit, up to 5.
			if not scratch[srcGUID] then scratch[srcGUID] = {} end
			local t = GetTime()
			if t-(scratch[srcGUID][0] or 0) > 1 then
				wipe(scratch[srcGUID])
			end
			scratch[srcGUID][0] = t
			scratch[srcGUID][1] = (scratch[srcGUID][1] or 0) + 1

			if scratch[srcGUID][1] < 6 then
				resetCooldown(info, 259495, 1) -- Wildfire Bomb
			end
		end
	end
	specialEvents.SPELL_DAMAGE[187708] = beastialWrath2 -- Carve
	specialEvents.SPELL_DAMAGE[212436] = beastialWrath2 -- Butchery

	-- Mage

	-- Alter Time
	specialEvents.SPELL_AURA_REMOVED[342246] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talent[4] == 23072 then -- Master of Time
			resetCooldown(info, 1953)
		end
	end

	-- Cold Snap
	specialEvents.SPELL_CAST_SUCCESS[235219] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info then
			resetCooldown(info, 120) -- Cone of Cold
			resetCooldown(info, 122) -- Frost Nova
			resetCooldown(info, 11426) -- Ice Barrier
		end
	end

	-- Blizzard
	specialEvents.SPELL_DAMAGE[190356] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info then
			if info.level > 46 then -- Blizzard (Rank 2)
				-- Each time Blizzard deals damage, the cooldown
				-- of Frozen Orb is reduced by 0.5 sec
				resetCooldown(info, 84714, 0.5) -- Frozen Orb
			end
		end
	end

	local function kindling(srcGUID, ...)
		local critical = select(9, ...)
		if not critical then return end

		local info = infoCache[srcGUID]
		if info and info.talents[19] then -- Kindling
			resetCooldown(info, 190319, 1) -- Combustion
		end
	end
	specialEvents.SPELL_DAMAGE[133] = kindling -- Fireball
	specialEvents.SPELL_DAMAGE[11366] = kindling -- Pyroblast
	specialEvents.SPELL_DAMAGE[108853] = kindling -- Fire Blast
	specialEvents.SPELL_DAMAGE[257541] = kindling -- Phoenix Flames

	-- Monk

	-- Keg Smash
	specialEvents.SPELL_CAST_SUCCESS[121253] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info then
			local amount = info.talents[21] and 5 or 3
			resetCooldown(info, 322507, amount) -- Celestial Brew
			resetCooldown(info, 115203, amount) -- Fortifying Brew
			resetCooldown(info, 115399, amount) -- Black Ox Brew
		end
	end

	-- Tiger Palm (Brewmaster)
	specialEvents.SPELL_CAST_SUCCESS[100780] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.spec == 268 then
			resetCooldown(info, 322507, 1) -- Celestial Brew
			resetCooldown(info, 115203, 1) -- Fortifying Brew
			resetCooldown(info, 115399, 1) -- Black Ox Brew
		end
	end

	-- Black Ox Brew
	specialEvents.SPELL_CAST_SUCCESS[115399] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info then
			resetCooldown(info, 322507) -- Celestial Brew
		end
	end

	-- Paladin

	local function fistOfJustice(srcGUID, _, spellId)
		local info = infoCache[srcGUID]
		if info then
			if info.talents[7] then -- Fist of Justice
				-- Each Holy Power spent reduces the remaining
				-- cooldown on Hammer of Justice by 2 sec.
				local amount = spellId == 215661 and 10 or 6 -- Justicar's Vengeance is 5, everything else is 3
				resetCooldown(info, 853, amount) -- Hammer of Justice
			end
			if info.talents[20] == 21202 then -- Righteous Protector
				-- Each Holy Power spent reduces the remaining
				-- cooldown on Avenging Wrath and Guardian of
				-- Ancient Kings by 1 sec.
				resetCooldown(info, 31884, 3) -- Avenging Wrath
				resetCooldown(info, 86659, 3) -- Guardian of Ancient Kings
			end
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[210191] = fistOfJustice -- Word of Glory
	specialEvents.SPELL_CAST_SUCCESS[53600] = fistOfJustice -- Shield of the Righteous
	specialEvents.SPELL_CAST_SUCCESS[85222] = fistOfJustice -- Light of Dawn
	specialEvents.SPELL_CAST_SUCCESS[53385] = fistOfJustice -- Divine Storm
	specialEvents.SPELL_CAST_SUCCESS[85256] = fistOfJustice -- Templar's Verdict
	specialEvents.SPELL_CAST_SUCCESS[267798] = fistOfJustice -- Execution Sentence
	specialEvents.SPELL_CAST_SUCCESS[215661] = fistOfJustice -- Justicar's Vengeance

	-- Priest

	local function holyWordChastise(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.level > 26 then -- Holy Words
			local amount = 4
			if info.talents[19] then -- Light of the Naaru
				amount = 5
			elseif info.talents[20] and scratch[srcGUID.."ap"] then -- Apotheosis active
				amount = 12
			end
			resetCooldown(info, 88625, amount) -- Holy Word: Chastise
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[585] = holyWordChastise -- Smite

	-- Prayer of Healing
	specialEvents.SPELL_CAST_SUCCESS[596] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.level > 26 then -- Holy Words
			local amount = 6
			if info.talents[19] then -- Light of the Naaru
				amount = 8
			elseif info.talents[20] and scratch[srcGUID.."ap"] then -- Apotheosis active
				amount = 18
			end
			resetCooldown(info, 34861, amount) -- Holy Word: Sanctify
		end
	end

	-- Renew
	specialEvents.SPELL_CAST_SUCCESS[139] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.level > 26 then -- Holy Words
			local amount = 2
			if info.talents[19] then -- Light of the Naaru
				amount = 3
			elseif info.talents[20] and scratch[srcGUID.."ap"] then -- Apotheosis active
				amount = 6
			end
			resetCooldown(info, 34861, amount) -- Holy Word: Sanctify
		end
	end

	local function holyWordSalvation(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[21] then
			resetCooldown(info, 265202, 30) -- Holy Word: Salvation
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[2050] = holyWordSalvation -- Holy Word: Serenity
	specialEvents.SPELL_CAST_SUCCESS[34861] = holyWordSalvation -- Holy Word: Sanctify

	-- Guardian Spirit
	specialEvents.SPELL_AURA_APPLIED[47788] = function(srcGUID)
		scratch[srcGUID.."gs"] = GetTime()
	end
	specialEvents.SPELL_AURA_REMOVED[47788] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[8] and scratch[srcGUID.."gs"] then -- Guardian Angel
			-- When Guardian Spirit expires without saving
			-- the target from death, reduce its remaining
			-- cooldown to 60 seconds.
			if GetTime() - scratch[srcGUID.."gs"] > 9.7 then
				resetCooldown(info, 47788, 60)
			end
		end
		scratch[srcGUID] = nil
	end

	-- Apotheosis
	specialEvents.SPELL_AURA_APPLIED[200183] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info then
			scratch[srcGUID.."ap"] = true
			resetCooldown(info, 34861) -- Holy Word: Sanctify
			resetCooldown(info, 88625) -- Holy Word: Chastise
		end
	end
	specialEvents.SPELL_AURA_REMOVED[200183] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info then
			scratch[srcGUID.."ap"] = nil
		end
	end

	-- Rogue

	-- Marked for Death
	specialEvents.SPELL_AURA_APPLIED[137619] = function(srcGUID, destGUID)
		local info = infoCache[srcGUID]
		if info then
			scratch[srcGUID..destGUID] = GetTime()
		end
	end
	specialEvents.SPELL_AURA_REMOVED[137619] = function(srcGUID, destGUID)
		local info = infoCache[srcGUID]
		if info and scratch[srcGUID..destGUID] then
			if GetTime() - scratch[srcGUID..destGUID] < 59.7 then
				resetCooldown(info, 137619) -- Marked for Death
			end
			scratch[srcGUID..destGUID] = nil
		end
	end

	-- Shaman

	-- Capacitor Totem
	specialEvents.SPELL_CAST_SUCCESS[192058] = function(srcGUID)
		scratch[srcGUID] = 0
	end

	-- Static Charge
	specialEvents.SPELL_AURA_APPLIED[118905] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[9] then -- Static Charge
			scratch[srcGUID] = scratch[srcGUID] + 1
			if scratch[srcGUID] < 5 then
				resetCooldown(info, 192058, 5) -- Capacitor Totem
			end
		end
	end

	-- Earth Shock
	specialEvents.SPELL_CAST_SUCCESS[8042] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[16] then -- Surge of Power
			scratch[srcGUID.."sp"] = GetTime()
		end
	end

	-- Lava Burst
	specialEvents.SPELL_CAST_SUCCESS[51505] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and scratch[srcGUID.."sp"] and GetTime()-scratch[srcGUID.."sp"] < 14.7 then -- Surge of Power
			if info.talents[11] then
				resetCooldown(info, 192249, 6) -- Storm Elemental
			else
				resetCooldown(info, 198067, 6) -- Fire Elemental
			end
		end
	end

	-- Warrior

	-- Shockwave
	specialEvents.SPELL_CAST_SUCCESS[46968] = function(srcGUID)
		scratch[srcGUID] = 0
	end
	specialEvents.SPELL_DAMAGE[46968] = function(srcGUID)
		local info = infoCache[srcGUID]
		if info and info.talents[14] and scratch[srcGUID] then -- Rumbling Earth
			scratch[srcGUID] = scratch[srcGUID] + 1
			if scratch[srcGUID] > 2 then
				resetCooldown(info, 46968, 15) -- Shockwave
				scratch[srcGUID] = nil
			end
		end
	end

	--- Anger Management
	-- All
	-- XXX fml this doesn't actually fire
	-- specialEvents.SPELL_ENERGIZE[163201] = function(srcGUID, _, _, amount, over) -- Execute
	-- 	local info = infoCache[srcGUID]
	-- 	if info and info.talents[18] and info.spec ~= 72 then -- Execute is a generator for Fury
	-- 		local rage = (amount + (over or 0)) / 0.2 -- 20% is refunded
	-- 		local per = info.spec == 73 and 10 or 20
	-- 		local amount = rage/per

	-- 		if info.spec == 71 then
	-- 			if info.talents[14] then
	-- 				resetCooldown(info, 262161, amount) -- Warbreaker
	-- 			else
	-- 				resetCooldown(info, 167105, amount) -- Colossus Smash
	-- 			end
	-- 			resetCooldown(info, 227847, amount) -- Blade Storm
	-- 		elseif info.spec == 73 then
	-- 			resetCooldown(info, 107574, amount) -- Avatar
	-- 			resetCooldown(info, 871, amount) -- Shield Wall
	-- 		end
	-- 	end
	-- end
	-- Potential to drift 1-2s per execute :\
	specialEvents.SPELL_CAST_SUCCESS[163201] = function(srcGUID) -- Execute
		local info = infoCache[srcGUID]
		if info and info.talents[18] and info.spec ~= 72 then -- Execute is a generator for Fury
			local rage = 30 -- 20-40 /wrists
			local per = info.spec == 73 and 10 or 20
			local amount = rage/per

			if info.spec == 71 then
				if info.talents[14] then
					resetCooldown(info, 262161, amount) -- Warbreaker
				else
					resetCooldown(info, 167105, amount) -- Colossus Smash
				end
				resetCooldown(info, 227847, amount) -- Blade Storm
			elseif info.spec == 73 then
				resetCooldown(info, 107574, amount) -- Avatar
				resetCooldown(info, 871, amount) -- Shield Wall
			end
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[190456] = function(srcGUID) -- Ignore Pain
		local info = infoCache[srcGUID]
		if info and info.talents[18] then
			local rage = info.spec == 72 and 60 or 40
			local per = info.spec == 73 and 10 or 20
			local amount = rage/per

			if info.spec == 71 then
				if info.talents[14] then
					resetCooldown(info, 262161, amount) -- Warbreaker
				else
					resetCooldown(info, 167105, amount) -- Colossus Smash
				end
				resetCooldown(info, 227847, amount) -- Blade Storm
			elseif info.spec == 72 then
				resetCooldown(info, 1719, amount) -- Recklessness
			elseif info.spec == 73 then
				resetCooldown(info, 107574, amount) -- Avatar
				resetCooldown(info, 871, amount) -- Shield Wall
			end
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[2565] = function(srcGUID) -- Shield Block
		local info = infoCache[srcGUID]
		if info and info.talents[18] then
			local rage = 30
			local per = info.spec == 73 and 10 or 20
			local amount = rage/per

			if info.spec == 71 then
				if info.talents[14] then
					resetCooldown(info, 262161, amount) -- Warbreaker
				else
					resetCooldown(info, 167105, amount) -- Colossus Smash
				end
				resetCooldown(info, 227847, amount) -- Blade Storm
			elseif info.spec == 72 then
				resetCooldown(info, 1719, amount) -- Recklessness
			elseif info.spec == 73 then
				resetCooldown(info, 107574, amount) -- Avatar
				resetCooldown(info, 871, amount) -- Shield Wall
			end
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[1464] = function(srcGUID) -- Slam
		local info = infoCache[srcGUID]
		if info and info.talents[18] then
			local rage = 20
			local per = info.spec == 73 and 10 or 20
			local amount = rage/per

			if info.spec == 71 then
				if info.talents[14] then
					resetCooldown(info, 262161, amount) -- Warbreaker
				else
					resetCooldown(info, 167105, amount) -- Colossus Smash
				end
				resetCooldown(info, 227847, amount) -- Blade Storm
			elseif info.spec == 72 then
				resetCooldown(info, 1719, amount) -- Recklessness
			elseif info.spec == 73 then
				resetCooldown(info, 107574, amount) -- Avatar
				resetCooldown(info, 871, amount) -- Shield Wall
			end
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[202168] = function(srcGUID) -- Impending Victory
		local info = infoCache[srcGUID]
		if info and info.talents[18] then
			local rage = 10
			local per = info.spec == 73 and 10 or 20
			local amount = rage/per

			if info.spec == 71 then
				if info.talents[14] then
					resetCooldown(info, 262161, amount) -- Warbreaker
				else
					resetCooldown(info, 167105, amount) -- Colossus Smash
				end
				resetCooldown(info, 227847, amount) -- Blade Storm
			elseif info.spec == 72 then
				resetCooldown(info, 1719, amount) -- Recklessness
			elseif info.spec == 73 then
				resetCooldown(info, 107574, amount) -- Avatar
				resetCooldown(info, 871, amount) -- Shield Wall
			end
		end
	end
	-- Arms
	specialEvents.SPELL_CAST_SUCCESS[12294] = function(srcGUID) -- Mortal Strike
		local info = infoCache[srcGUID]
		if info and info.talents[18] then
			local rage = 30
			local per = 20
			local amount = rage/per

			if info.talents[14] then
				resetCooldown(info, 262161, amount) -- Warbreaker
			else
				resetCooldown(info, 167105, amount) -- Colossus Smash
			end
			resetCooldown(info, 227847, amount) -- Blade Storm
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[772] = function(srcGUID) -- Rend
		local info = infoCache[srcGUID]
		if info and info.talents[18] then
			local rage = 30
			local per = 20
			local amount = rage/per

			if info.talents[14] then
				resetCooldown(info, 262161, amount) -- Warbreaker
			else
				resetCooldown(info, 167105, amount) -- Colossus Smash
			end
			resetCooldown(info, 227847, amount) -- Blade Storm
		end
	end
	specialEvents.SPELL_CAST_SUCCESS[845] = function(srcGUID) -- Cleave
		local info = infoCache[srcGUID]
		if info and info.talents[18] then
			local rage = 20
			local per = 20
			local amount = rage/per

			if info.talents[14] then
				resetCooldown(info, 262161, amount) -- Warbreaker
			else
				resetCooldown(info, 167105, amount) -- Colossus Smash
			end
			resetCooldown(info, 227847, amount) -- Blade Storm
		end
	end
	-- Fury
	specialEvents.SPELL_CAST_SUCCESS[184367] = function(srcGUID) -- Rampage
		local info = infoCache[srcGUID]
		if info and info.talents[18] then
			local rage = 80
			local per = 20
			local amount = rage/per

			resetCooldown(info, 1719, amount) -- Recklessness
		end
	end
	-- Protection
	specialEvents.SPELL_CAST_SUCCESS[6572] = function(srcGUID) -- Revenge
		local info = infoCache[srcGUID]
		if info and info.talents[18] then
			local rage = 20
			local per = 10
			local amount = rage/per
			-- XXX how does this work with free Revenges
			resetCooldown(info, 107574, amount) -- Avatar
			resetCooldown(info, 871, amount) -- Shield Wall
		end
	end

	-- Misc

	-- Dream Simulacrum (Xavius Encounter)
	specialEvents.SPELL_AURA_REMOVED[206005] = function(_, dstGUID)
		local info = infoCache[dstGUID]
		if info then
			for spellId in next, spells[info.class] do
				if module:GetRemainingCooldown(dstGUID, spellId) > 0 then
					resetCooldown(info, spellId)
				end
			end
		end
	end

	-- stop autovivification
	setmetatable(specialEvents, nil)


	local encounterResetsCooldowns = {
		[14] = true, -- Normal
		[15] = true, -- Heroic
		[16] = true, -- Mythic
	}
	local inEncounter = nil

	local band = bit.band
	local group = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
	local pet = bit.bor(COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET)

	local function handler(_, event, _, srcGUID, source, srcFlags, _, destGUID, destName, dstFlags, _, spellId, spellName, _, ...)
		if event == "UNIT_DIED" then
			if band(dstFlags, group) ~= 0 and UnitIsPlayer(destName) and not UnitIsFeignDeath(destName) then
				callbacks:Fire("oRA3CD_UpdatePlayer", destGUID, destName)
				deadies[destGUID] = true
				module:RegisterEvent("UNIT_HEALTH")
			end
			return
		end

		if source and (event == "SPELL_CAST_SUCCESS" or event == "SPELL_RESURRECT") and allSpells[spellId] and band(srcFlags, group) ~= 0 then
			if mergeSpells[spellId] then
				spellId = mergeSpells[spellId]
			end

			if combatResSpells[spellId] and (encounterResetsCooldowns[inEncounter] or instanceDifficulty == 8) then
				-- tracking by spell cast isn't very useful in non-legacy raid encounters and mythic+ because it only counts when accepted
				return
			end

			if band(srcFlags, pet) > 0 then
				source, srcGUID = getPetOwner(source, srcGUID)
			end
			if not infoCache[srcGUID] then return end
			local class = infoCache[srcGUID].class

			callbacks:Fire("oRA3CD_SpellUsed", spellId, srcGUID, source, destGUID, destName)
			if module:GetCharges(srcGUID, spellId) > 0 then
				if not chargeSpellsOnCooldown[spellId] then chargeSpellsOnCooldown[spellId] = { [srcGUID] = {} }
				elseif not chargeSpellsOnCooldown[spellId][srcGUID] then chargeSpellsOnCooldown[spellId][srcGUID] = {} end
				local expires = chargeSpellsOnCooldown[spellId][srcGUID]

				local t = GetTime()
				local cd = module:GetCooldown(srcGUID, spellId)
				expires[#expires + 1] = (expires[#expires] or t) + cd
				local maxCharges = module:GetCharges(srcGUID, spellId)
				local charges = maxCharges - #expires
				if charges == 0 then
					if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
					spellsOnCooldown[spellId][srcGUID] = expires[1]
					callbacks:Fire("oRA3CD_StartCooldown", srcGUID, source, class, spellId, expires[1] - t)
				end
				callbacks:Fire("oRA3CD_UpdateCharges", srcGUID, source, class, spellId, cd, charges, maxCharges)
			else
				if not spellsOnCooldown[spellId] then spellsOnCooldown[spellId] = {} end
				local cd = module:GetCooldown(srcGUID, spellId)
				spellsOnCooldown[spellId][srcGUID] = GetTime() + cd
				callbacks:Fire("oRA3CD_StartCooldown", srcGUID, source, class, spellId, cd)
			end
		end

		-- Special cooldown conditions
		local func = specialEvents[event] and specialEvents[event][spellId]
		if func then
			func(srcGUID, destGUID, spellId, ...)
		end
	end
	combatLogHandler:SetScript("OnEvent", function()
		handler(CombatLogGetCurrentEventInfo())
	end)


	local playerStates = {}
	local STATUS_RANGE, STATUS_COMBAT = 1, 2
	function module:PLAYER_REGEN_DISABLED()
		for guid, status in next, playerStates do
			if band(status, STATUS_COMBAT) == STATUS_COMBAT then
				callbacks:Fire("oRA3CD_UpdatePlayer", guid, infoCache[guid].name)
			end
		end
	end

	local total = 0
	local IsEncounterInProgress = IsEncounterInProgress
	combatOnUpdate = function(self)
		local t = GetTime() + 0.05

		-- check spell cds
		for spellId, players in next, spellsOnCooldown do
			for guid, expires in next, players do
				if expires < t then
					players[guid] = nil
					local info = infoCache[guid]
					if info then
						callbacks:Fire("oRA3CD_CooldownReady", guid, info.name, info.class, spellId)
					end
				end
			end
		end

		-- update spell charge cds
		for spellId, players in next, chargeSpellsOnCooldown do
			for guid, expires in next, players do
				local info = infoCache[guid]
				if not info then
					players[guid] = nil
				else
					local changed = nil
					for i = #expires, 1, -1 do
						if expires[i] < t then
							changed = true
							tremove(expires, i)
						end
					end
					if changed then
						local maxCharges = module:GetCharges(guid, spellId)
						if maxCharges > 0 then
							local charges = maxCharges - #expires
							callbacks:Fire("oRA3CD_UpdateCharges", guid, info.name, info.class, spellId, module:GetCooldown(guid, spellId), charges, maxCharges, true)
						end
					end
				end
			end
		end

		-- encounter checking for cd resets
		if not inEncounter and IsEncounterInProgress() then
			inEncounter = instanceDifficulty
			if encounterResetsCooldowns[instanceDifficulty] then
				-- reset combat reses
				for spellId in next, combatResSpells do
					spellsOnCooldown[spellId] = nil
					updateCooldownsBySpell(spellId)
				end
			end
		elseif inEncounter and not IsEncounterInProgress() then
			inEncounter = nil
			if encounterResetsCooldowns[instanceDifficulty] then
				-- reset 3min+ cds (except Reincarnation)
				for spellId, info in next, allSpells do
					if info[1] >= 180 and spellId ~= 20608 then
						spellsOnCooldown[spellId] = nil
						chargeSpellsOnCooldown[spellId] = nil
						updateCooldownsBySpell(spellId)
					end
				end
			end
		end

		-- track non-event driven player states (combat and range)
		if t - total > 1 then
			total = t
			for guid, info in next, infoCache do
				local player = info.name
				local status = nil
				if UnitInRange(player) then status = (status or 0) + STATUS_RANGE end
				if UnitAffectingCombat(player) then status = (status or 0) + STATUS_COMBAT end
				if playerStates[guid] ~= status then
					playerStates[guid] = status
					callbacks:Fire("oRA3CD_UpdatePlayer", guid, player)
				end
			end
		end
	end
end

_G.oRA3CD = module -- set global
