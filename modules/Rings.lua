
local addonName, scope = ...
local oRA3 = scope.addon
local module = oRA3:NewModule("Rings", "AceTimer-3.0")
local L = scope.locale

local media = LibStub("LibSharedMedia-3.0")
local Masque = LibStub("Masque", true)

local ShowOverlayGlow = LibStub("LibButtonGlow-1.0").ShowOverlayGlow
local HideOverlayGlow = LibStub("LibButtonGlow-1.0").HideOverlayGlow

local DEFAULT_SOUND = "Interface\\AddOns\\oRA3\\media\\twinkle.ogg"
media:Register("sound", "oRA3: Twinkle", DEFAULT_SOUND)

local db = nil

--- Specialization to Ring Item
-- 124634 Thorasus (dps-str)
-- 124635 Nithramus (dps-int)
-- 124636 Maalus (dps-agi)
-- 124637 Santus (tank)
-- 124638 Etheralus (healer)
local specToRing = {
	-- Death Knight
	[250] = 124637, -- Blood
	[251] = 124634, -- Frost
	[252] = 124634, -- Unholy
	-- Druid
	[102] = 124635, -- Balance
	[103] = 124636, -- Feral
	[104] = 124637, -- Guardian
	[105] = 124638, -- Restoration
	-- Hunter
	[253] = 124636, -- Beast Mastery
	[254] = 124636, -- Marksmanship
	[255] = 124636, -- Survival
	-- Mage
	[62] = 124635, -- Arcane
	[63] = 124635, -- Fire
	[64] = 124635, -- Frost
	-- Monk
	[268] = 124637, -- Brewmaster
	[270] = 124638, -- Mistweaver
	[269] = 124636, -- Windwalker
	-- Paladin
	[65] = 124638, -- Holy
	[66] = 124637, -- Protection
	[70] = 124634, -- Retribution
	-- Priest
	[256] = 124638, -- Discipline
	[257] = 124638, -- Holy
	[258] = 124635, -- Shadow
	-- Rogue
	[259] = 124636, -- Assassination
	[260] = 124636, -- Combat
	[261] = 124636, -- Subtlety
	-- Shaman
	[262] = 124635, -- Elemental
	[263] = 124636, -- Enhancement
	[264] = 124638, -- Restoration
	-- Warlock
	[265] = 124635, -- Affliction
	[266] = 124635, -- Demonology
	[267] = 124635, -- Destruction
	-- Warrior
	[71] = 124634, -- Arms
	[72] = 124634, -- Fury
	[73] = 124637, -- Protection
}

--- Ring Spell to Role
local ringToRole = {
	-- auras
	[187616] = 3, -- Nithramus
	[187617] = 1, -- Sanctus
	[187618] = 2, -- Etheralus
	[187619] = 3, -- Thorasus
	[187620] = 3, -- Maalus
	-- casts
	[187611] = 3, -- Nithramus
	[187612] = 2, -- Etheralus
	[187613] = 1, -- Sanctus
	[187614] = 3, -- Thorasus
	[187615] = 3, -- Maalus
}

---------------------------------------
-- Icons

local CreateIcon
do
	local function GetRingCooldown(id)
		if not id then return end
		for slot = 11, 12 do
			if GetInventoryItemID("player", slot) == id then
				return GetInventoryItemCooldown("player", slot)
			end
		end
	end

	local function OnShow(self)
		HideOverlayGlow(self)
		if self.start then
			local t = GetTime()
			local remaining = self.finish - t
			if self.cooldown:GetDrawEdge() or remaining < 1 then
				self.start = nil
				self.finish = nil
				self.text:SetText(self.name)
			else
				self.cooldown:SetReverse(false)
				self.cooldown:SetDrawEdge(false)
				self.cooldown:SetDrawSwipe(true)
				self.cooldown:SetCooldown(t, remaining)
			end
		else
			self.text:SetText(self.name)
			-- is your ring already on cooldown?
			local tree = GetSpecialization() or 0
			local spec, _, _, _, _, role = GetSpecializationInfo(tree)
			if role == self.role then
				local start, duration = GetRingCooldown(specToRing[spec])
				if start and start > 0 then
					self.cooldown:SetReverse(true)
					self.cooldown:SetDrawEdge(false)
					self.cooldown:SetDrawSwipe(true)
					self.cooldown:SetCooldown(start, duration)
					self.start = start
					self.finish = self.start + duration
				end
			end
		end
	end

	local function OnCooldownDone(self)
		OnShow(self:GetParent())
	end

	local function Start(self, player)
		local started = nil
		local t = GetTime()
		if self.start and t > self.finish then -- sanity check
			self.start = nil
			self.finish = nil
		end
		if not self.start then
			self.text:SetText(oRA3.coloredNames[player])
			self.start = t
			self.finish = self.start + 120
			started = true
		end

		if self:IsShown() then
			local tree = GetSpecialization() or 0
			local spec, _, _, _, _, role = GetSpecializationInfo(tree)
			local isMine = role == self.role

			local start = isMine and GetRingCooldown(specToRing[spec])
			local triggered = not start or (start > 0 and abs(start-t) < 1) -- show glow if not equipped (start == nil)

			-- prioritize keeping the displayed cd in sync with your ring
			if isMine and triggered and start and self.start ~= start then
				self.text:SetText(oRA3.coloredNames[player])
				self.start = start
				self.finish = self.start + 120
				started = true
			end
			if started then
				if isMine and not triggered then
					-- no cd shown, activated but not in range, set on cd (edge only) without activation glow
					self.cooldown:SetReverse(false)
					self.cooldown:SetDrawEdge(true)
					self.cooldown:SetDrawSwipe(false)
					self.cooldown:SetCooldown(self.start, 120)
				else
					self.cooldown:SetReverse(true)
					self.cooldown:SetDrawEdge(false)
					self.cooldown:SetDrawSwipe(true)
					self.cooldown:SetCooldown(self.start, 15)
					ShowOverlayGlow(self)

					if not db.soundForMe or isMine then
						local sound = media:Fetch("sound", db.soundFile) or DEFAULT_SOUND
						PlaySoundFile(sound, "master")
					end
				end
			end
		end
	end

	local function UpdateClicks(self)
		local tree = GetSpecialization() or 0
		local spec, _, _, _, _, role = GetSpecializationInfo(tree)
		local ring = spec and specToRing[spec]

		if role == self.role and db.clickable and ring then
			local itemName = GetItemInfo(ring)
			if itemName then
				local text = ("/cast %s"):format(itemName)
				if self:GetAttribute("macrotext") ~= text then
					self:SetAttribute("macrotext", text)
					self:EnableMouse(true)
				end
			else
				-- had itemName return nil on reload while shown, item cache miss?
				module:ScheduleTimer(self.UpdateClicks, 5, self)
			end
		elseif self:GetAttribute("macrotext") ~= nil then
			self:SetAttribute("macrotext", nil)
			self:EnableMouse(false)
		end
	end

	function CreateIcon(role, parent, texture)
		local name = _G[role]
		local frameName = "oRA3RingsFrame"..name.."Button"
		local f = CreateFrame("Button", frameName, parent, "SecureActionButtonTemplate")
		f:SetSize(64, 64)
		f.name = name
		f.role = role

		f:EnableMouse(false)
		f:RegisterForClicks("LeftButtonDown")
		f:SetAttribute("type", "macro")
		UpdateClicks(f)

		f:SetScript("OnShow", OnShow)
		f:SetScript("OnEvent", UpdateClicks)
		f:RegisterEvent("PLAYER_TALENT_UPDATE")

		local icon = f:CreateTexture(frameName.."Icon", "BACKGROUND")
		icon:SetAllPoints()
		icon:SetTexture(texture)
		f.icon = icon

		local cooldown = CreateFrame("Cooldown", frameName.."Cooldown", f, "CooldownFrameTemplate")
		cooldown:SetHideCountdownNumbers(false)
		cooldown:SetDrawEdge(false)
		cooldown:SetDrawSwipe(true)
		cooldown:SetEdgeTexture("Interface\\AddOns\\oRA3\\media\\edge2") -- blizzard texture was too subtle
		cooldown:SetScript("OnCooldownDone", OnCooldownDone)
		f.cooldown = cooldown

		local text = f:CreateFontString(nil, "OVERLAY")
		text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		text:SetTextColor(1, 1, 1, 1)
		text:SetJustifyH("CENTER")
		text:SetJustifyV("TOP")
		text:SetShadowColor(0, 0, 0, 1)
		text:SetShadowOffset(1, -1)
		text:SetPoint("TOPLEFT", f, "BOTTOMLEFT")
		text:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT")
		text:SetText(name)
		f.text = text

		f.Start = Start
		f.UpdateClicks = UpdateClicks

		-- Masque skinning
		if module.group then
			module.group:AddButton(f)
		end

		return f
	end
end

---------------------------------------
-- Display

local display = {
	icons = {},
}

local function shouldShow()
	return db.showDisplay and IsInGroup() and not UnitInBattleground("player") and (not db.showInRaid or IsInRaid())
end

local function toggleShow(force)
	if InCombatLockdown() then
		module:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	if shouldShow() or force then
		if db.lockDisplay then
			display:Lock()
		else
			display:Unlock()
		end
		display:Show()
		display:UpdateLayout()
	else
		display:Hide()
	end
end

function display:Lock()
	if not db.showDisplay then return end
	if not self.frame then return end
	local frame = self.frame
	frame:EnableMouse(false)
	frame:SetMovable(false)
	frame:SetResizable(false)
	frame:RegisterForDrag()
	frame.bg:SetTexture(0, 0, 0, 0)
	frame.header:Hide()
end

function display:Unlock()
	if not db.showDisplay then return end
	if not self.frame then return end
	local frame = self.frame
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:RegisterForDrag("LeftButton")
	frame.bg:SetTexture(0, 0, 0, 0.3)
	frame.header:Show()
end

function display:Show()
	if not db.showDisplay then return end
	if not self.frame then return self:Setup() end
	self.frame:Show()
	self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function display:Hide()
	if not self.frame then return end
	self.frame:Hide()
	self.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	for _, icon in next, self.icons do
		icon.text:SetText(icon.name)
	end
end

do
	local band = bit.band
	local group = bit.bor(_G.COMBATLOG_OBJECT_AFFILIATION_MINE, _G.COMBATLOG_OBJECT_AFFILIATION_PARTY, _G.COMBATLOG_OBJECT_AFFILIATION_RAID)
	local function combatLogHandler(self, _, _, event, _, _, source, srcFlags, _, _, target, _, _, spellId, spellName)
		if ringToRole[spellId] and band(srcFlags, group) ~= 0 then
			local id = ringToRole[spellId]
			local icon = display.icons[id]
			if event == "SPELL_AURA_APPLIED" then
				-- aura to determine when the effect actually happens
				icon:Start(source)
			elseif event == "SPELL_CAST_SUCCESS" and db.announce and IsInRaid() and not IsInGroup(2) then
				-- announce on cast because it's easy and doesn't affect anything
				local text = L.activatedRing:format(source:gsub("%-.+", ""), GetSpellLink(spellId), icon.name)
				SendChatMessage(text, "RAID")
			end
		end
	end

	function display:Setup()
		local padding = 10

		local frame = CreateFrame("Frame", "oRA3RingsFrame", UIParent)
		frame:SetScale(db.scale)
		frame:SetHitRectInsets(-padding, -padding, -padding, -padding)
		frame:SetFrameStrata("BACKGROUND")
		frame:SetClampedToScreen(true)
		frame:SetSize(64, 64)

		tinsert(self.icons, CreateIcon("TANK", frame, "Interface\\Icons\\inv_60legendary_ring1b"))
		tinsert(self.icons, CreateIcon("HEALER", frame, "Interface\\Icons\\inv_60legendary_ring1a"))
		tinsert(self.icons, CreateIcon("DAMAGER", frame, "Interface\\Icons\\inv_60legendary_ring1c"))

		local bg = frame:CreateTexture(nil, "BACKGROUND")
		bg:SetPoint("TOPLEFT", frame, -padding, padding)
		bg:SetPoint("BOTTOMRIGHT", frame, padding, -padding)
		bg:SetTexture(0, 0, 0, 0.3)
		frame.bg = bg

		-- wish this didn't scale, but font strings don't have their own scale property to compensate D; oh well
		local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		header:SetText(L.legendaryRings)
		header:SetPoint("BOTTOM", bg, "TOP", 0, 2)
		frame.header = header

		local help = frame:CreateFontString(nil, "HIGHLIGHT", "GameFontNormal")
		help:SetText(L.rightClick)
		help:SetWordWrap(true)
		help:SetJustifyV("TOP")
		help:SetPoint("TOP", bg, "BOTTOM", 0, -2)
		frame.help = help

		frame:SetScript("OnEvent", combatLogHandler)
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			oRA3:SavePosition("oRA3RingsFrame", true)
		end)
		frame:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then
				LibStub("AceConfigDialog-3.0"):Open("oRA")
				LibStub("AceConfigDialog-3.0"):SelectGroup("oRA", "general", "Rings")
			end
		end)

		self.frame = frame

		oRA3:RestorePosition("oRA3RingsFrame")

		toggleShow()
	end
end

function display:UpdateLayout()
	if not self.frame or not self.frame:IsShown() then return end
	if db.clickable and InCombatLockdown() then
		module:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	if module.group then
		module.group:ReSkin()
	end

	self.frame:SetScale(db.scale)
	oRA3:RestorePosition("oRA3RingsFrame") -- don't move around when changing stuff, plz

	local spacing = db.spacing
	local textHeight = db.showText and (db.fontSize * 1.025) or 0 -- just works! (instead of using fs:GetHeight)
	local growDown = db.direction == "VERTICAL"

	local left, right, top, bottom = nil, nil, nil, nil
	local last = nil
	for index = 1, #self.icons do
		local frame = self.icons[index]
		frame:ClearAllPoints()
		frame:UpdateClicks()

		frame.text:SetFont(media:Fetch("font", db.font), db.fontSize, db.fontOutline ~= "NONE" and db.fontOutline)
		frame.text:SetShown(db.showText)
		frame.cooldown:SetHideCountdownNumbers(not db.showCooldownText)

		local showIcon = (index == 1 and db.showTank) or (index == 2 and db.showHealer) or (index == 3 and db.showDamager)
		if not showIcon then
			frame:Hide()
		else
			if not last then
				frame:SetPoint("TOPLEFT")
				top, left = frame:GetTop(), frame:GetLeft()
			elseif growDown then
				frame:SetPoint("TOP", last, "BOTTOM", 0, -1 * (spacing + textHeight))
			else
				frame:SetPoint("LEFT", last, "RIGHT", spacing, 0)
			end
			bottom, right = frame:GetBottom(), frame:GetRight()

			last = frame
			frame:Show()
		end
	end
	if right then
		self.frame:SetWidth(right - left)
		self.frame:SetHeight(top - bottom + textHeight)
	end
end

function module:PLAYER_REGEN_ENABLED()
	if InCombatLockdown() then return end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")

	toggleShow()
end

---------------------------------------
-- Options

local defaults = {
	profile = {
		showDisplay = true,
		lockDisplay = false,
		showInRaid = true,
		announce = false,
		clickable = false,
		showTank = true,
		showHealer = true,
		showDamager = true,
		sound = true,
		soundForMe = true,
		soundFile = "oRA3: Twinkle",
		direction = "HORIZONTAL",
		scale = 1,
		spacing = 2,
		showText = true,
		showCooldownText = true,
		font = "Friz Quadrata TT",
		fontSize = 11,
		fontOutline = "NONE"
	}
}

local function colorize(input) return ("|cfffed000%s|r"):format(input) end
local options = {
	type = "group",
	name = L.legendaryRings,
	get = function(info) return db[info[#info]] end,
	set = function(info, value)
		local key = info[#info]
		db[key] = value
		toggleShow()
	end,
	args = {
		header = {
			type = "description",
			name = L.battleResHeader.."\n",
			fontSize = "medium",
			order = 0,
		},
		toggle = {
			type = "execute",
			name = L.toggleMonitor,
			func = function()
				if InCombatLockdown() then return end
				if not display.frame then
					display:Setup()
				end
				if not display.frame:IsShown() then
					toggleShow(true)
				else
					display:Hide()
				end
			end,
			disabled = function() return not db.showDisplay or shouldShow() end,
			order = 0.5,
		},
		showDisplay = {
			type = "toggle",
			name = colorize(L.showMonitor),
			desc = L.battleResShowDesc,
			descStyle = "inline",
			width = "full",
			order = 1,
		},
		lockDisplay = {
			type = "toggle",
			name = colorize(L.lockMonitor),
			desc = L.battleResLockDesc,
			descStyle = "inline",
			width = "full",
			order = 2,
		},
		showInRaid = {
			type = "toggle",
			name = colorize(L.onlyRaids),
			desc = L.onlyRaidsDesc,
			descStyle = "inline",
			width = "full",
			order = 3,
		},
		announce = {
			type = "toggle",
			name = colorize(L.announce),
			desc = L.announceDesc,
			descStyle = "inline",
			width = "full",
			order = 4,
		},
		clickable = {
			type = "toggle",
			name = colorize(L.clickable),
			desc = L.clickableDesc,
			descStyle = "inline",
			width = "full",
			order = 4.5,
		},
		show = {
			type = "group",
			name = L.showRings,
			inline = true,
			order = 5,
			args = {
				showTank = {
					type = "toggle",
					name = TANK,
					order = 1,
				},
				showHealer = {
					type = "toggle",
					name = HEALER,
					order = 2,
				},
				showDamager = {
					type = "toggle",
					name = DAMAGER,
					width = "half",
					order = 3,
				},
			}
		},
		sound = {
			type = "group",
			name = L.sound,
			inline = true,
			order = 6,
			args = {
				sound = {
					type = "toggle",
					name = colorize(ENABLE),
					desc = L.soundDesc,
					descStyle = "inline",
					width = "full",
					order = 1,
				},
				soundForMe = {
					type = "toggle",
					name = colorize(L.onlyMyRing),
					desc = L.onlyMyRingDesc,
					descStyle = "inline",
					disabled = function() return not db.sound end,
					width = "full",
					order = 2,
				},
				soundFile = {
					type = "select",
					name = L.sound,
					values = media:List("sound"),
					itemControl = "DDI-Sound",
					get = function(info)
						local key = info[#info]
						for i, v in next, media:List("sound") do
							if v == db[key] then
									return i
							end
						end
					end,
					set = function(info, value)
						local list = media:List("sound")
						db[info[#info]] = list[value]
					end,
					disabled = function() return not db.sound end,
					width = "full",
					order = 3,
				},
			}
		},
		display = {
			type = "group",
			name = L.displaySettings,
			inline = true,
			order = 9,
			get = function(info)
				local key = info[#info]
				if key == "font" then
					for i, v in next, media:List("font") do
						if v == db[key] then return i end
					end
				end
				return db[key]
			end,
			set = function(info, value)
				local key = info[#info]
				if key == "font" then
					local list = media:List("font")
					db[key] = list[value]
				else
					db[key] = value
				end
				display:UpdateLayout()
			end,
			args = {
				skin = {
					type = "select",
					name = L.skin,
					values = function()
						local skinList = {}
						for id in next, Masque:GetSkins() do
							skinList[id] = id
						end
						return skinList
					end,
					get = function(info) return module.group.db.SkinID or "Blizzard" end,
					set = function(info, value) module.group:SetOption("SkinID", value) end,
					hidden = function() return not module.group end,
					width = "full",
					order = 0,
				},
				direction = {
					type = "select",
					name = L.orientation,
					values = { HORIZONTAL = L.horizontal, VERTICAL = L.vertical },
					width = "full",
					order = 0.5,
				},
				scale = {
					type = "range", min = 0.1, softMax = 10, step = 0.01,
					name = L.scale,
					width = "full",
					order = 1,
				},
				spacing = {
					type = "range", min = -10, softMax = 10, step = 1,
					name = L.spacing,
					width = "full",
					order = 2,
				},
				showText = {
					type = "toggle",
					name = colorize(L.showText),
					desc = L.showTextDesc,
					descStyle = "inline",
					width = "full",
					order = 4,
				},
				showCooldownText = {
					type = "toggle",
					name = colorize(L.showCooldownText),
					desc = L.showCooldownTextDesc,
					descStyle = "inline",
					disabled = function() return not GetCVarBool("countdownForCooldowns") end, -- if the setting is off, SetHideCountdownNumbers does nothing
					width = "full",
					order = 5,
				},
				font = {
					type = "select",
					name = L.font,
					values = media:List("font"),
					itemControl = "DDI-Font",
					disabled = function() return not db.showText end,
					width = "full",
					order = 6,
				},
				fontSize = {
					type = "range",
					name = L.fontSize,
					min = 6, max = 24, step = 1,
					disabled = function() return not db.showText end,
					width = "full",
					order = 7,
				},
				fontOutline = {
					type = "select",
					name = L.outline,
					values = { NONE = NONE, OUTLINE = L.thin, THICKOUTLINE = L.thick },
					disabled = function() return not db.showText end,
					width = "full",
					order = 8,
				},
			}
		}
	}
}

function module:OnProfileUpdate()
	db = module.db.profile

	if oRA3.db.profile.positions.oRA3CooldownFrameRingsRings then
		local old = oRA3.db.profile.positions.oRA3CooldownFrameRingsRings

		oRA3.db.profile.positions.oRA3RingsFrame = {
			PosX = old.PosX,
			PosY = old.PosY,
		}

		-- if you had any icons wrap, set it vertical
		local size = 64 * db.scale + db.spacing
		if floor(old.Width / size) < 3 then
			db.direction = "VERTICAL"
		end

		oRA3.db.profile.positions.oRA3CooldownFrameRingsRings = nil
	end

	toggleShow()
end

function module:OnRegister()
	self.db = oRA3.db:RegisterNamespace("Rings", defaults)
	oRA3.RegisterCallback(self, "OnProfileUpdate")
	oRA3:RegisterModuleOptions("Rings", options)

	oRA3.RegisterCallback(self, "OnStartup", "ToggleShow")
	oRA3.RegisterCallback(self, "OnShutdown", "ToggleShow")
	oRA3.RegisterCallback(self, "OnConvertRaid", "ToggleShow")
	oRA3.RegisterCallback(self, "OnConvertParty", "ToggleShow")

	if Masque then
		module.group = Masque:Group("oRA3", "Legendary Rings")
	end

	self:OnProfileUpdate()
end

function module:ToggleShow()
	toggleShow()
end
