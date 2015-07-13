
local _, scope = ...
local oRA3 = scope.addon
local module = oRA3:GetModule("Cooldowns")

--------------------------------------------------------------------------------
-- Layouts
--

local layoutRegistry = {}
local layoutNames = {}
local layoutDescriptions = {}
local layoutVersions = {}
local layoutOptionsRegistry = {}
local layoutTypes = {}

function module:RegisterDisplayType(name, localizedName, description, version, new, options)
	assert(type(name) == "string")
	assert(type(new) == "function")
	assert(type(version) == "number")
	local oldVersion = layoutVersions[name]
	if not oldVersion or oldVersion < version then
		layoutRegistry[name] = new
		layoutNames[name] = localizedName
		layoutDescriptions[name] = description
		layoutVersions[name] = version
		if type(options) == "function" then
			layoutOptionsRegistry[name] = function(display, db)
				local tab = assert(options(display, db), "Invalid options table for "..name)
				return tab
			end
		end

		wipe(layoutTypes)
		for layout in next, layoutRegistry do
			layoutTypes[#layoutTypes+1] = layout
		end
		sort(layoutTypes)
	end
end

function module:GetDisplayOptionsTable(display)
	local options = layoutOptionsRegistry[display.type]
	if options then
		return options(display, display.db)
	end
end

function module:GetDisplayInfo(name)
	return layoutNames[name], layoutDescriptions[name], layoutVersions[name]
end

function module:IterateDisplayTypes()
	return next, layoutTypes, nil
end

local function copyDefaults(dst, src)
	if src == nil then return end
	for k, v in next, src do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then
				dst[k] = {}
			end
			copyDefaults(dst[k], v)
		else
			if dst[k] == nil then
				dst[k] = v
			end
		end
	end
end

-- XXX locales as of r895
local translateType = {
	--esES
	["Barras"] = "Bars",
	["Iconos"] = "Icons",
	["Grupos de iconos"] = "Icon Groups",
	["Registro"] = "Log",
	--deDE
	["Leisten"] = "Bars",
	["Icon Gruppen"] = "Icon Groups",
	--frFR
	["Barres"] = "Bars",
	["Icônes"] = "Icons",
	["Groupes d'icônes"] = "Icon Groups",
	["Journal"] = "Log",
}

function module:CreateDisplay(type, name)
	-- XXX I dun fucked up and localized my unique index
	if not layoutRegistry[type] and translateType[type] then
		local newType = translateType[type]
		local db = module.db.profile.displays[name]
		if db.type and db.type == type then
			db.type = newType
		end
		type = newType
	end
	if layoutRegistry[type] then
		local display = layoutRegistry[type](name)
		display.name = name
		display.type = type
		display.moduleName = ("Cooldowns: %s"):format(type)
		display.version = layoutVersions[type]

		-- init db
		local moduleDB = module.db.profile
		local db = moduleDB.displays[name]

		-- reset settings on type change
		if db.type and db.type ~= type then
			wipe(db)
			db.showDisplay = true
			db.lockDisplay = false
		end
		db.type = type

		copyDefaults(db, display.defaultDB)
		display.db = db

		if not moduleDB.spells[name] then
			moduleDB.spells[name] = {}
		end
		local spellDB = moduleDB.spells[name]
		for spellId in next, spellDB do -- clean up
			if not GetSpellInfo(spellId) then
				spellDB[spellId] = nil
			end
		end
		display.spellDB = spellDB

		display.filterDB = moduleDB.filters[name]

		return display
	else
		error(format("Attempt to instantiate unknown display type '%s'", type), 0)
	end
end

--------------------------------------------------------------------------------
--- Bar styles
-- These are taken from BigWigs and use the same API, meaning you can use the
-- same style with both BW and oRA3. Register your style with the follow code:
-- oRA3CD:RegisterBarStyle("Style name", settings_table)
--
-- GLOBALS: ElvUI Tukui

local barStyles = {
	Default = {
		apiVersion = 1,
		version = 1,
		GetSpacing = function(bar)
			local display = bar:Get("ora3cd:display")
			return display and display.db.barGap
		end,
		ApplyStyle = function(bar) end,
		BarStopped = function(bar) end,
		GetStyleName = function() return DEFAULT end,
	}
}

local barStyleRegister = {}

function module:GetBarStyles()
	return barStyles
end

function module:GetBarStyleList()
	return barStyleRegister
end

do
	local currentAPIVersion = 1
	local errorWrongAPI = "The bar style API version is now %d; the bar style %q needs to be updated for this version of oRA3."
	local errorMismatchedData = "The given style data does not seem to be a Big Wigs/oRA3 bar styler."
	local errorAlreadyExist = "Trying to register %q as a bar styler, but it already exists."
	function module:RegisterBarStyle(key, styleData)
		if type(key) ~= "string" then error(errorMismatchedData) end
		if type(styleData) ~= "table" then error(errorMismatchedData) end
		if type(styleData.version) ~= "number" then error(errorMismatchedData) end
		if type(styleData.apiVersion) ~= "number" then error(errorMismatchedData) end
		if type(styleData.GetStyleName) ~= "function" then error(errorMismatchedData) end
		if styleData.apiVersion ~= currentAPIVersion then error(errorWrongAPI:format(currentAPIVersion, key)) end
		if barStyles[key] and barStyles[key].version == styleData.version then error(errorAlreadyExist:format(key)) end
		if not barStyles[key] or barStyles[key].version < styleData.version then
			barStyles[key] = styleData
			barStyleRegister[key] = styleData:GetStyleName()
		end
	end
end

do
	-- !Beautycase styling, based on !Beatycase by Neal "Neave" @ WowI, texture made by Game92 "Aftermathh" @ WowI

	local textureNormal = "Interface\\AddOns\\oRA3\\images\\beautycase"

	local backdropbc = {
		bgFile = "Interface\\Buttons\\WHITE8x8",
		insets = {top = 1, left = 1, bottom = 1, right = 1},
	}

	local function createBorder(self)
		local border = UIParent:CreateTexture(nil, "OVERLAY")
		border:SetParent(self)
		border:SetTexture(textureNormal)
		border:SetWidth(12)
		border:SetHeight(12)
		border:SetVertexColor(1, 1, 1)
		return border
	end

	local freeBorderSets = {}

	local function freeStyle(bar)
		local borders = bar:Get("ora3cd:beautycase:borders")
		if borders then
			for i, border in next, borders do
				border:SetParent(UIParent)
				border:Hide()
			end
			freeBorderSets[#freeBorderSets + 1] = borders
		end
	end

	local function styleBar(bar)
		local bd = bar.candyBarBackdrop

		bd:SetBackdrop(backdropbc)
		bd:SetBackdropColor(.1, .1, .1, 1)

		bd:ClearAllPoints()
		bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
		bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
		bd:Show()

		local borders = nil
		if #freeBorderSets > 0 then
			borders = tremove(freeBorderSets)
			for i, border in next, borders do
				border:SetParent(bar.candyBarBar)
				border:ClearAllPoints()
				border:Show()
			end
		else
			borders = {}
			for i = 1, 8 do
				borders[i] = createBorder(bar.candyBarBar)
			end
		end
		for i, border in next, borders do
			if i == 1 then
				border:SetTexCoord(0, 1/3, 0, 1/3)
				border:SetPoint("TOPLEFT", -18, 4)
			elseif i == 2 then
				border:SetTexCoord(2/3, 1, 0, 1/3)
				border:SetPoint("TOPRIGHT", 4, 4)
			elseif i == 3 then
				border:SetTexCoord(0, 1/3, 2/3, 1)
				border:SetPoint("BOTTOMLEFT", -18, -4)
			elseif i == 4 then
				border:SetTexCoord(2/3, 1, 2/3, 1)
				border:SetPoint("BOTTOMRIGHT", 4, -4)
			elseif i == 5 then
				border:SetTexCoord(1/3, 2/3, 0, 1/3)
				border:SetPoint("TOPLEFT", borders[1], "TOPRIGHT")
				border:SetPoint("TOPRIGHT", borders[2], "TOPLEFT")
			elseif i == 6 then
				border:SetTexCoord(1/3, 2/3, 2/3, 1)
				border:SetPoint("BOTTOMLEFT", borders[3], "BOTTOMRIGHT")
				border:SetPoint("BOTTOMRIGHT", borders[4], "BOTTOMLEFT")
			elseif i == 7 then
				border:SetTexCoord(0, 1/3, 1/3, 2/3)
				border:SetPoint("TOPLEFT", borders[1], "BOTTOMLEFT")
				border:SetPoint("BOTTOMLEFT", borders[3], "TOPLEFT")
			elseif i == 8 then
				border:SetTexCoord(2/3, 1, 1/3, 2/3)
				border:SetPoint("TOPRIGHT", borders[2], "BOTTOMRIGHT")
				border:SetPoint("BOTTOMRIGHT", borders[4], "TOPRIGHT")
			end
		end

		bar:Set("ora3cd:beautycase:borders", borders)
	end

	barStyles.BeautyCase = {
		apiVersion = 1,
		version = 1,
		GetSpacing = function(bar) return 10 end,
		ApplyStyle = styleBar,
		BarStopped = freeStyle,
		GetStyleName = function() return "!Beautycase" end,
	}
end

do
	-- MonoUI
	local backdropBorder = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	}

	local function removeStyle(bar)
		bar:SetHeight(14)
		bar.candyBarBackdrop:Hide()

		local tex = bar:Get("ora3cd:restoreicon")
		if tex then
			local icon = bar.candyBarIconFrame
			icon:ClearAllPoints()
			icon:SetPoint("TOPLEFT")
			icon:SetPoint("BOTTOMLEFT")
			bar:SetIcon(tex)

			bar.candyBarIconFrameBackdrop:Hide()
		end

		bar.candyBarDuration:ClearAllPoints()
		bar.candyBarDuration:SetPoint("RIGHT", bar.candyBarBar, "RIGHT", -2, 0)

		bar.candyBarLabel:ClearAllPoints()
		bar.candyBarLabel:SetPoint("TOPLEFT", bar.candyBarBar, "TOPLEFT", 2, 0)
		bar.candyBarLabel:SetPoint("BOTTOMRIGHT", bar.candyBarBar, "BOTTOMRIGHT", -2, 0)
	end

	local function styleBar(bar)
		bar:SetHeight(6)

		local bd = bar.candyBarBackdrop

		bd:SetBackdrop(backdropBorder)
		bd:SetBackdropColor(.1,.1,.1,1)
		bd:SetBackdropBorderColor(0,0,0,1)

		bd:ClearAllPoints()
		bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
		bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2)
		bd:Show()

		if bar:Get("ora3cd:display").db.barShowIcon then
			local icon = bar.candyBarIconFrame
			local tex = icon.icon
			bar:SetIcon(nil)
			icon:SetTexture(tex)
			icon:ClearAllPoints()
			icon:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", -5, 0)
			icon:SetSize(16, 16)
			icon:Show() -- XXX temp
			bar:Set("ora3cd:restoreicon", tex)

			local iconBd = bar.candyBarIconFrameBackdrop
			iconBd:SetBackdrop(backdropBorder)
			iconBd:SetBackdropColor(.1,.1,.1,1)
			iconBd:SetBackdropBorderColor(0,0,0,1)

			iconBd:ClearAllPoints()
			iconBd:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
			iconBd:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
			iconBd:Show()
		end

		bar.candyBarLabel:SetJustifyH("LEFT")
		bar.candyBarLabel:ClearAllPoints()
		bar.candyBarLabel:SetPoint("LEFT", bar, "LEFT", 4, 10)

		bar.candyBarDuration:SetJustifyH("RIGHT")
		bar.candyBarDuration:ClearAllPoints()
		bar.candyBarDuration:SetPoint("RIGHT", bar, "RIGHT", -4, 10)

		--bar:SetTexture(media:Fetch("statusbar", "Blizzard"))
	end

	barStyles.MonoUI = {
		apiVersion = 1,
		version = 2,
		GetSpacing = function(bar) return 15 end,
		ApplyStyle = styleBar,
		BarStopped = removeStyle,
		GetStyleName = function() return "MonoUI" end,
	}
end

do
	-- Tukui
	local C = Tukui and Tukui[2]
	local backdrop = {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		tile = false, tileSize = 0, edgeSize = 1,
	}
	local borderBackdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	}

	local function removeStyle(bar)
		local bd = bar.candyBarBackdrop
		bd:Hide()
		bd.tukiborder:Hide()
		bd.tukoborder:Hide()
	end

	local function styleBar(bar)
		local bd = bar.candyBarBackdrop
		bd:SetBackdrop(backdrop)

		if C then
			bd:SetBackdropColor(unpack(C.Medias.BackdropColor))
			bd:SetBackdropBorderColor(unpack(C.Medias.BorderColor))
			bd:SetOutside(bar)
		else
			bd:SetBackdropColor(0.1,0.1,0.1)
			bd:SetBackdropBorderColor(0.5,0.5,0.5)
			bd:ClearAllPoints()
			bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
			bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2)
		end

		if not bd.tukiborder then
			local border = CreateFrame("Frame", nil, bd)
			if C then
				border:SetInside(bd, 1, 1)
			else
				border:SetPoint("TOPLEFT", bd, "TOPLEFT", 1, -1)
				border:SetPoint("BOTTOMRIGHT", bd, "BOTTOMRIGHT", -1, 1)
			end
			border:SetFrameLevel(3)
			border:SetBackdrop(borderBackdrop)
			border:SetBackdropBorderColor(0, 0, 0)
			bd.tukiborder = border
		else
			bd.tukiborder:Show()
		end

		if not bd.tukoborder then
			local border = CreateFrame("Frame", nil, bd)
			if C then
				border:SetOutside(bd, 1, 1)
			else
				border:SetPoint("TOPLEFT", bd, "TOPLEFT", -1, 1)
				border:SetPoint("BOTTOMRIGHT", bd, "BOTTOMRIGHT", 1, -1)
			end
			border:SetFrameLevel(3)
			border:SetBackdrop(borderBackdrop)
			border:SetBackdropBorderColor(0, 0, 0)
			bd.tukoborder = border
		else
			bd.tukoborder:Show()
		end

		bd:Show()
	end

	barStyles.TukUI = {
		apiVersion = 1,
		version = 3,
		GetSpacing = function(bar) return 7 end,
		ApplyStyle = styleBar,
		BarStopped = removeStyle,
		GetStyleName = function() return "TukUI" end,
	}
end

do
	-- ElvUI
	local E = ElvUI and ElvUI[1]
	local backdropBorder = {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	}

	local function removeStyle(bar)
		bar:SetHeight(14)

		local bd = bar.candyBarBackdrop
		bd:Hide()
		if bd.iborder then
			bd.iborder:Hide()
			bd.oborder:Hide()
		end

		local tex = bar:Get("ora3cd:restoreicon")
		if tex then
			local icon = bar.candyBarIconFrame
			icon:ClearAllPoints()
			icon:SetPoint("TOPLEFT")
			icon:SetPoint("BOTTOMLEFT")
			bar:SetIcon(tex)

			local iconBd = bar.candyBarIconFrameBackdrop
			iconBd:Hide()
			if iconBd.iborder then
				iconBd.iborder:Hide()
				iconBd.oborder:Hide()
			end
		end
	end

	local function styleBar(bar)
		bar:SetHeight(20)

		local bd = bar.candyBarBackdrop

		if E then
			bd:SetTemplate("Transparent")
			bd:SetOutside(bar)
			if not E.PixelMode and bd.iborder then
				bd.iborder:Show()
				bd.oborder:Show()
			end
		else
			bd:SetBackdrop(backdropBorder)
			bd:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
			bd:SetBackdropBorderColor(0, 0, 0)

			bd:ClearAllPoints()
			bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
			bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
		end

		if bar:Get("ora3cd:display").db.barShowIcon then
			local icon = bar.candyBarIconFrame
			local tex = icon.icon
			bar:SetIcon(nil)
			icon:SetTexture(tex)
			icon:ClearAllPoints()
			icon:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", E and (E.PixelMode and -1 or -5) or -1, 0)
			icon:SetSize(20, 20)
			icon:Show() -- XXX temp
			bar:Set("ora3cd:restoreicon", tex)

			local iconBd = bar.candyBarIconFrameBackdrop

			if E then
				iconBd:SetTemplate("Transparent")
				iconBd:SetOutside(bar.candyBarIconFrame)
				if not E.PixelMode and iconBd.iborder then
					iconBd.iborder:Show()
					iconBd.oborder:Show()
				end
			else
				iconBd:SetBackdrop(backdropBorder)
				iconBd:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
				iconBd:SetBackdropBorderColor(0, 0, 0)

				iconBd:ClearAllPoints()
				iconBd:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
				iconBd:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
			end
			iconBd:Show()
		end

		bd:Show()
	end

	barStyles.ElvUI = {
		apiVersion = 1,
		version = 2,
		GetSpacing = function(bar) return E and (E.PixelMode and 4 or 8) or 4 end,
		ApplyStyle = styleBar,
		BarStopped = removeStyle,
		GetStyleName = function() return "ElvUI" end,
	}
end

for k, v in next, barStyles do
	barStyleRegister[k] = v:GetStyleName()
end
