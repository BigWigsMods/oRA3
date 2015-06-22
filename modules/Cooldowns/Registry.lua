
local _, scope = ...
local oRA3 = scope.addon
local module = oRA3:GetModule("Cooldowns")

--------------------------------------------------------------------------------
-- Layouts
--

local layoutRegistry = {}
local layoutDescriptions = {}
local layoutVersions = {}
local layoutOptionsRegistry = {}
local layoutTypes = {}

function module:RegisterDisplayType(name, description, new, version, options)
	assert(type(name) == "string")
	assert(type(new) == "function")
	assert(type(version) == "number")
	local oldVersion = layoutVersions[name]
	if not oldVersion or oldVersion < version then
		layoutRegistry[name] = new
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

function module:GetDisplayVersion(name)
	return layoutVersions[name]
end

function module:GetDisplayDescription(name)
	return layoutDescriptions[name]
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

function module:CreateDisplay(type, name)
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
