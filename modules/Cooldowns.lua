--------------------------------------------------------------------------------
-- Setup
--

local oRA = LibStub("AceAddon-3.0"):GetAddon("oRA3")
local module = oRA:NewModule("Cooldowns", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("oRA3")
local AceGUI = LibStub("AceGUI-3.0")
local candy = LibStub("LibCandyBar-3.0")
local media = LibStub("LibSharedMedia-3.0")
local LGIST = LibStub("LibGroupInSpecT-1.0", true) or LibStub("LibGroupInSpecT-1.1", true)

module.VERSION = tonumber(("$Revision$"):sub(12, -3))

--------------------------------------------------------------------------------
-- Locals
--

local mTypeBar = media and media.MediaType and media.MediaType.STATUSBAR or "statusbar"
local mTypeFont = media and media.MediaType and media.MediaType.FONT or "font"
local playerName, playerGUID

local glyphCooldowns = {
	[55678] = {6346, 60},      -- Fear Ward, -60sec
	[63229] = {47585, 15},     -- Dispersion, -15sec
	[55455] = {2894, 120},     -- Fire Elemental Totem, -120sec (-40%)
	[63291] = {51514, 10},     -- Hex, -10sec
	[63329] = {871, -120},     -- Shield Wall, +2min
	[63325] = {6544, 15},      -- Heroic Leap, -15sec
	[55688] = {64044, 10},     -- Psychic Horror, -10sec
	[63309] = {48020, 4},      -- Demonic Circle: Teleport, -4sec
	[58058] = {556, 300},      -- Astral Recall, -300sec
	[55441] = {8177, -35},     -- Grounding Totem, +35sec
	[63270] = {51490, 10},     -- Thunderstorm, -10sec
	[63328] = {23920, 5},      -- Spell Reflection, -5sec
	[59219] = {1850, 60},      -- Dash, -60sec
	[58673] = {48792, 90},     -- Icebound Fortitude, -90sec (-50%)
	[56368] = {11129, -45},    -- Combustion, +45sec (+100%)
	[58686] = {47528, 2},      -- Mind Freeze, -2sec
	[116216] = {106839, -10},  -- Skull Bash, +10sec
	[116203] = {16689, 30},    -- Nature's Grasp, -30sec
	[114223] = {61336, 60},    -- Survival Instincts, -60sec
	[56376] = {122, 5},        -- Frost Nova, -5sec
	[62210] = {12042, -90},    -- Arcane Power, +90sec (+100%)
	[115703] = {2139, -4},     -- Counterspell, +4sec
	[54925] = {96231, -5},     -- Rebuke, +5sec
	[56805] = {1766, -4},      -- Kick, +4sec
	[55451] = {57994, -3},     -- Wind Shear, +3sec
	[123391] = {115080, -90},  -- Touch of Death, +90sec
	[63331] = {77606, 30},     -- Dark Simulacrum, -30sec
}

local spells = {
	DRUID = {
		[20484] = 600,  -- Rebirth
		[132158] = 60,  -- Nature's Swiftness
		[61336] = 180,  -- Survival Instincts
		[22812] = 60,   -- Barkskin
		[106839] = 15,  -- Skull Bash
		[78675] = 60,   -- Solar Beam
		[78674] = 15,   -- Starsurge
		[18562] = 15,   -- Swiftmend
		[132469] = 30,  -- Typhoon
		[48505] = 90,   -- Starfall
		[102401] = 15,  -- Wild Charge
		[5211]  = 50,   -- Bash
		[50334] = 180,  -- Berserk
		[5217]  = 30,   -- Tiger's Fury
		[1850]  = 180,  -- Dash
		[740]   = 480,  -- Tranquility
		[77761] = 120,  -- Stampeding Roar
		[102342] = 60, -- Ironbark
		[102359] = 30,  -- Mass Entanglement
	},
	HUNTER = {
		[34477] = 30,   -- Misdirection
		[5384]  = 30,   -- Feign Death
		[781]   = 20,   -- Disengage
		[19263] = 180,  -- Deterrence --- XXX need to figure out how to deal with multiple charges (cd doesn't start until the second charge is used, second charge cd doesn't start until first charge is off cd)
		[147362] = 24,  -- Counter Shot
		[19386] = 45,   -- Wyvern Sting
		[13809] = 30,   -- Ice Trap
		[82941] = 30,   -- Ice Trap + Launcher
		[1499]  = 30,   -- Freezing Trap
		[60192] = 30,   -- Freezing Trap + Launcher
		[19577] = 60,   -- Intimidation
		[82726] = 30,   -- Fervor
		[19574] = 60,   -- Bestial Wrath
		[3045]  = 180,  -- Rapid Fire
		[3674]  = 30,   -- Black Arrow
		[34600] = 30,   -- Snake Trap
		[82948] = 30,   -- Snake Trap + Launcher
		[13813] = 30,   -- Explosive Trap
		[82939] = 30,   -- Explosive Trap + Launcher
		[51753] = 60,   -- Camouflage
		[90355] = 360,  -- Ancient Hysteria
		[160452] = 360, -- Netherwinds
		[126393] = 600, -- Eternal Guardian
		[109248] = 45,  -- Binding Shot
		[109304] = 120, -- Exhilaration
		[121818] = 300, -- Stampede
		[53271] = 45,   -- Master's Call
		-- XXX Pets missing
	},
	MAGE = {
		[45438] = 300,  -- Ice Block
		[2139]  = 24,   -- Counterspell
		[66]    = 300,  -- Invisibility
		[122]   = 25,   -- Frost Nova
		[120]   = 10,   -- Cone of Cold
		[11426] = 25,   -- Ice Barrier
		[12472] = 180,  -- Icy Veins
		[12051] = 120,  -- Evocation
		[31687] = 60,   -- Summon Water Elemental
		[11958] = 180,  -- Cold Snap
		[1953]  = 15,   -- Blink
		[12043] = 90,   -- Presence of Mind
		[12042] = 90,   -- Arcane Power
		[11129] = 45,   -- Combustion
		[31661] = 20,   -- Dragon's Breath
		[44572] = 30,   -- Deep Freeze
		[80353] = 300,  -- Time Warp
		[113724] = 45,  -- Ring of Frost
		[115610] = 25,  -- Temporal Shield
		[102051] = 20,  -- Frostjaw
		[110959] = 90,  -- Greater Invisibility
	},
	PALADIN = {
		[633]   = 600,  -- Lay on Hands
		[1022]  = 300,  -- Hand of Protection
		[498]   = 60,   -- Divine Protection
		[642]   = 300,  -- Divine Shield
		[1044]  = 25,   -- Hand of Freedom
		[1038]  = 120,  -- Hand of Salvation
		[6940]  = 120,  -- Hand of Sacrifice
		[31821] = 180,  -- Devotion Aura
		[31850] = 180,  -- Ardent Defender
		[96231] = 15,   -- Rebuke
		[20066] = 15,   -- Repentance
		[31884] = 180,  -- Avenging Wrath
		[853]   = 60,   -- Hammer of Justice
		[31935] = 15,   -- Avenger's Shield
		[86659] = 180,  -- Guardian of Ancient Kings (Prot)
		[114039] = 30,  -- Hand of Purity
		[105809] = 120, -- Holy Avenger
		[105593] = 30,  -- Fist of Justice
		[114158] = 60,  -- Light's Hammer
		[114157] = 60,  -- Execution Sentence
	},
	PRIEST = {
		[8122]  = 30,   -- Psychic Scream
		[6346]  = 180,  -- Fear Ward
		[34433] = 180,  -- Shadowfiend
		[64843] = 180,  -- Divine Hymn
		[10060] = 120,  -- Power Infusion
		[33206] = 180,  -- Pain Suppression
		[62618] = 180,  -- Power Word: Barrier
		[724]   = 180,  -- Lightwell
		[47788] = 180,  -- Guardian Spirit
		[15487] = 45,   -- Silence
		[47585] = 120,  -- Dispersion
		[88625] = 30,   -- Holy Word: Chastise
		[88685] = 40,   -- Holy Word: Sanctuary
		[19236] = 120,  -- Desperate Prayer
		[586]   = 30,   -- Fade
		[64044] = 120,  -- Psychic Horror
		[73325] = 90,   -- Leap of Faith
		[15286] = 180,  -- Vampiric Embrace
		[81700] = 30,   -- Archangel
		[109964] = 60,  -- Spirit Shell
		[108920] = 30,  -- Void Tendrils
		[123040] = 60,  -- Mindbender
	},
	ROGUE = {
		[5277]  = 180,  -- Evasion
		[1766]  = 15,   -- Kick
		[1856]  = 120,  -- Vanish
		[1725]  = 30,   -- Distract
		[2094]  = 120,  -- Blind
		[31224] = 60,   -- Cloak of Shadows
		[57934] = 30,   -- Tricks of the Trade
		[14185] = 300,  -- Preparation
		[79140] = 120,  -- Vendetta
		[13750] = 180,  -- Adrenaline Rush
		[51690] = 120,  -- Killing Spree
		[14183] = 20,   -- Premeditation
		[51713] = 60,   -- Shadow Dance
		[76577] = 180,  -- Smoke Bomb
		[36554] = 24,   -- Shadowstep
		[1776]  = 10,   -- Gouge
		[408]   = 20,   -- Kidney Shot
		[51690] = 120,  -- Killing Spree
		[51713] = 60,   -- Shadow Dance
		[74001] = 120,  -- Combat Readiness
	},
	SHAMAN = {
		[57994] = 12,   -- Wind Shear
		[20608] = 1800, -- Reincarnation
		[2062]  = 600,  -- Earth Elemental Totem
		[2894]  = 600,  -- Fire Elemental Totem
		[UnitFactionGroup("player") == "Horde" and 2825 or 32182] = 300, -- Bloodlust/Heroism
		[51514] = 45,   -- Hex
		[16188] = 60,   -- Ancestral Swiftness
		[8177]  = 25,   -- Grounding Totem
		[2484]  = 30,   -- Earthbind Totem
		[51490] = 45,   -- Thunderstorm
		[16166] = 90,   -- Elemental Mastery
		[79206] = 120,  -- Spiritwalker's Grace
		[51533] = 120,  -- Feral Spirit
		[30823] = 60,   -- Shamanistic Rage
		[8143]  = 60,   -- Tremor Totem
		[98008] = 180,  -- Spirit Link Totem
		[108280] = 180, -- Healing Tide Totem
		[108281] = 120, -- Ancestral Guidance
		[108273] = 60,  -- Windwalk Totem
		[108271] = 120, -- Astral Shift
		[114049] = 180, -- Ascendance
	},
	WARLOCK = {
		[20707] = 600,  -- Soulstone Resurrection
		[698]   = 120,  -- Ritual of Summoning
		[1122]  = 600,  -- Summon Infernal
		[18540] = 600,  -- Summon Doomguard
		[29858] = 120,  -- Soulshatter
		[29893] = 120,  -- Create Soulwell
		[5484]  = 40,   -- Howl of Terror
		[30283] = 30,   -- Shadowfury
		[48020] = 30,   -- Demonic Circle: Teleport
		[6789]  = 45,   -- Mortal Coil
		[108359] = 120, -- Dark Regeneration
		[110913] = 180, -- Dark Bargain
		[111397] = 30,  -- Blood Horror
		[108482] = 60,  -- Unbound Will
		[108501] = 120, -- Grimoire of Service
		[108505] = 120, -- Archimonde's Vengeance
		[113860] = 120, -- Dark Soul: Misery
		[113861] = 120, -- Dark Soul: Knowledge
		[113858] = 120, -- Dark Soul: Instability
	},
	WARRIOR = {
		[100]   = 20,   -- Charge
		[23920] = 25,   -- Spell Reflection
		[3411]  = 30,   -- Intervene
		[57755] = 30,   -- Heroic Throw
		[1719]  = 180,  -- Recklessness
		[6552]  = 15,   -- Pummel
		[5246]  = 90,   -- Intimidating Shout
		[871]   = 300,  -- Shield Wall
		[64382] = 300,  -- Shattering Throw
		[55694] = 60,   -- Enraged Regeneration
		[12975] = 180,  -- Last Stand
		[46924] = 90,   -- Bladestorm
		[12292] = 60,   -- Bloodbath
		[46968] = 40,   -- Shockwave
		[86346] = 20,   -- Colossus Smash
		[6544]  = 45,   -- Heroic Leap
		[97462] = 180,  -- Rallying Cry
		[114028] = 60,  -- Mass Spell Reflection
		[114029] = 30,  -- Safeguard
		[114030] = 120, -- Vigilance
		[114192] = 180, -- Mocking Banner
	},
	DEATHKNIGHT = {
		[49576] = 25,   -- Death Grip
		[47528] = 15,   -- Mind Freeze
		[47476] = 60,   -- Strangulate
		[48792] = 180,  -- Icebound Fortitude
		[48707] = 45,   -- Anti-Magic Shell
		[61999] = 600,  -- Raise Ally
		[42650] = 600,  -- Army of the Dead
		[49222] = 60,   -- Bone Shield
		[55233] = 60,   -- Vampiric Blood
		[49028] = 90,   -- Dancing Rune Weapon
		[49039] = 120,  -- Lichborne
		[48982] = 30,   -- Rune Tap
		[51271] = 60,   -- Pillar of Frost
		[49206] = 180,  -- Summon Gargoyle
		[46584] = 120,  -- Raise Dead
		[51052] = 120,  -- Anti-Magic Zone
		[57330] = 20,   -- Horn of Winter
		[47568] = 300,  -- Empower Rune Weapon
		[48743] = 120,  -- Death Pact
		[77606] = 60,   -- Dark Simulacrum
		[108199] = 60,  -- Gorefiend's Grasp
		[108194] = 30,  -- Asphyxiate
		[108200] = 60,  -- Remorseless Winter
		[108201] = 120, -- Desecrated Ground
	},
	MONK = {
		[115176] = 180, -- Zen Meditation
		[122278] = 90,  -- Dampen Harm
		[115310] = 180, -- Revival
		[116849] = 120, -- Life Cocoon
		[115203] = 180, -- Fortifying Brew
		[119381] = 45,  -- Leg Sweep
		[122470] = 90,  -- Touch of Karma
		[116705] = 15,  -- Spear Hand Strike
		[116841] = 30,  -- Tiger's Lust
		[116844] = 45,  -- Ring of Peace
		[119392] = 30,  -- Charging Ox Wave
		[122783] = 90,  -- Diffuse Magic
		[115080] = 90,  -- Touch of Death
		[115078] = 15,  -- Paralysis
		[116680] = 45,  -- Thunder Focus Tea
		[101545] = 25,  -- Flying Serpent Kick
		[137562] = 120, -- Nimble Brew
	},
}

local allSpells = {}
local classLookup = {}
for class, spells in next, spells do
	for id, cd in next, spells do
		allSpells[id] = cd
		classLookup[id] = class
	end
end
allSpells[95750] = 600 -- Combat Soulstone
classLookup[95750] = "WARLOCK"

local db = nil
local cdModifiers = {}

local options, restyleBars
local lockDisplay, unlockDisplay, isDisplayLocked, showDisplay, hideDisplay, isDisplayShown
local showPane, hidePane
local combatLog
local textures = media:List(mTypeBar)
local fonts = media:List(mTypeFont)
local function getOptions()
	if not options then
		options = {
			type = "group",
			name = L["Cooldowns"],
			get = function(k) return db[k[#k]] end,
			set = function(k, v)
				local key = k[#k]
				db[key] = v
				if key:find("^bar") then
					restyleBars()
				elseif key == "showDisplay" then
					if v then
						showDisplay()
					else
						hideDisplay()
					end
				elseif key == "lockDisplay" then
					if v then
						lockDisplay()
					else
						unlockDisplay()
					end
				end
			end,
			args = {
				showDisplay = {
					type = "toggle",
					name = L["Show monitor"],
					desc = L["Show or hide the cooldown bar display in the game world."],
					order = 1,
					width = "full",
				},
				lockDisplay = {
					type = "toggle",
					name = L["Lock monitor"],
					desc = L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."],
					order = 2,
					width = "full",
				},
				onlyShowMine = {
					type = "toggle",
					name = L["Only show my own spells"],
					desc = L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."],
					order = 3,
					width = "full",
				},
				neverShowMine = {
					type = "toggle",
					name = L["Never show my own spells"],
					desc = L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."],
					order = 4,
					width = "full",
				},
				separator = {
					type = "description",
					name = " ",
					order = 10,
					width = "full",
				},
				shownow = {
					type = "execute",
					name = L["Open monitor"],
					func = showDisplay,
					width = "full",
					order = 11,
				},
				test = {
					type = "execute",
					name = L["Spawn test bar"],
					func = function()
						module:SpawnTestBar()
					end,
					width = "full",
					order = 12,
				},
				settings = {
					type = "group",
					name = L["Bar Settings"],
					order = 20,
					width = "full",
					inline = true,
					args = {
						barClassColor = {
							type = "toggle",
							name = L["Use class color"],
							order = 13,
						},
						barColor = {
							type = "color",
							name = L["Custom color"],
							get = function() return unpack(db.barColor) end,
							set = function(info, r, g, b)
								db.barColor = {r, g, b, 1}
								restyleBars()
							end,
							order = 14,
							disabled = function() return db.barClassColor end,
						},
						spacer = { type = "description", name = " ", order = 14.5 },
						barHeight = {
							type = "range",
							name = L["Height"],
							order = 15,
							min = 8,
							max = 32,
							step = 1,
						},
						barScale = {
							type = "range",
							name = L["Scale"],
							order = 15,
							min = 0.1,
							max = 5.0,
							step = 0.1,
						},
						barTexture = {
							type = "select",
							name = L["Texture"],
							order = 17,
							values = textures,
							get = function()
								for i, v in next, textures do
									if v == db.barTexture then
										return i
									end
								end
							end,
							set = function(_, v)
								db.barTexture = textures[v]
								restyleBars()
							end,
							itemControl = "DDI-Statusbar",
						},
						barGrowUp = {
							type = "toggle",
							name = L["Grow up"],
							order = 19,
							width = "full",
						},
						show = {
							type = "group",
							name = L["Show"],
							order = 20,
							width = "full",
							inline = true,
							args = {
								barShowIcon = {
									type = "toggle",
									name = L["Icon"],
								},
								barShowDuration = {
									type = "toggle",
									name = L["Duration"],
								},
								barShowUnit = {
									type = "toggle",
									name = L["Unit name"],
								},
								barShowSpell = {
									type = "toggle",
									name = L["Spell name"],
								},
								barShorthand = {
									type = "toggle",
									name = L["Short Spell name"],
								},
							},
						},
					},
				},
				labelSettings = {
					type = "group",
					name = L["Label Text Settings"],
					order = 21,
					width = "full",
					inline = true,
					disabled = function() return not db.barShowUnit and not db.barShowSpell end,
					args = {
						barLabelClassColor = {
							type = "toggle",
							name = L["Use class color"],
							order = 1,
						},
						barLabelColor = {
							type = "color",
							name = L["Custom color"],
							get = function() return unpack(db.barLabelColor) end,
							set = function(info, r, g, b)
								db.barLabelColor = {r, g, b, 1}
								restyleBars()
							end,
							order = 2,
							disabled = function() return (not db.barShowUnit and not db.barShowSpell) or db.barLabelClassColor end,
						},
						spacer = { type = "description", name = " ", order = 3 },
						barLabelFont = {
							type = "select",
							name = L["Font"],
							order = 4,
							values = fonts,
							get = function()
								for i, v in next, fonts do
									if v == db.barLabelFont then
										return i
									end
								end
							end,
							set = function(_, v)
								db.barLabelFont = fonts[v]
								restyleBars()
							end,
							itemControl = "DDI-Font",
						},
						barLabelFontSize = {
							type = "range",
							name = L["Font Size"],
							order = 5,
							min = 6, max = 24, step = 1,
						},
						barLabelOutline = {
							type = "select",
							name = L["Outline"],
							order = 6,
							values = { NONE = NONE, OUTLINE = L["Thin"], THICKOUTLINE = L["Thick"] },
						},
						barLabelAlign = {
							type = "select",
							name = L["Label Align"],
							order = 7,
							values = { LEFT = "Left", CENTER = "Center", RIGHT = "Right" },
						},
					},
				},
				durationSettings = {
					type = "group",
					name = L["Duration Text Settings"],
					order = 22,
					width = "full",
					inline = true,
					disabled = function() return not db.barShowDuration end,
					args = {
						barDurationClassColor = {
							type = "toggle",
							name = L["Use class color"],
							order = 1,
						},
						barDurationColor = {
							type = "color",
							name = L["Custom color"],
							get = function() return unpack(db.barLabelColor) end,
							set = function(info, r, g, b)
								db.barLabelColor = {r, g, b, 1}
								restyleBars()
							end,
							order = 2,
							disabled = function() return not db.barShowDuration or db.barLabelClassColor end,
						},
						spacer = { type = "description", name = " ", order = 3 },
						barDurationFont = {
							type = "select",
							name = L["Font"],
							order = 9,
							values = fonts,
							get = function()
								for i, v in next, fonts do
									if v == db.barDurationFont then
										return i
									end
								end
							end,
							set = function(_, v)
								db.barDurationFont = fonts[v]
								restyleBars()
							end,
							itemControl = "DDI-Font",
						},
						barDurationFontSize = {
							type = "range",
							name = L["Font Size"],
							order = 10,
							min = 6, max = 24, step = 1,
						},
						barDurationOutline = {
							type = "select",
							name = L["Outline"],
							order = 11,
							values = { NONE = NONE, OUTLINE = L["Thin"], THICKOUTLINE = L["Thick"] },
						},
					},
				},
			},
		}
	end
	return options
end
--[[
/script bar=oRA3:GetModule"Cooldowns":GetBars();x=oRA3:GetClassMembers("Druid");for b in pairs(bar)do if b:Get"ora3cd:spell"=="Innervate" then x[b:Get"ora3cd:unit"]=nil end end;SendChatMessage("Innervate!","WHISPER",nil,next(x))
]]
--------------------------------------------------------------------------------
-- GUI
--

do
	local frame = nil
	local tmp = {}
	local group = nil

	local function spellCheckboxCallback(widget, event, value)
		local id = widget:GetUserData("id")
		if not id then return end
		db.spells[id] = value and true or false
	end

	local function showCheckboxTooltip(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_LEFT")
		GameTooltip:SetHyperlink("spell:"..widget:GetUserData("id"))
		GameTooltip:Show()
	end

	local function hideCheckboxTooltip(widget, event)
		GameTooltip:Hide()
	end

	local function sortBySpellName(a, b)
		local spellA = GetSpellInfo(a)
		if not spellA then
			print("oRA: Invalid spell id:", a)
			return
		end
		local spellB = GetSpellInfo(b)
		if not spellB then
			print("oRA: Invalid spell id:", b)
			return
		end
		return spellA < spellB
	end
	local function dropdownGroupCallback(widget, event, key)
		widget:PauseLayout()
		widget:ReleaseChildren()
		if spells[key] then
			wipe(tmp)
			-- Class spells
			for id in next, spells[key] do
				tmp[#tmp + 1] = id
			end
			sort(tmp, sortBySpellName)
			for i, v in next, tmp do
				local name, _, icon = GetSpellInfo(v)
				if name then
					local checkbox = AceGUI:Create("CheckBox")
					checkbox:SetLabel(name)
					checkbox:SetValue(db.spells[v] and true or false)
					checkbox:SetUserData("id", v)
					checkbox:SetCallback("OnValueChanged", spellCheckboxCallback)
					checkbox:SetRelativeWidth(0.5)
					checkbox:SetImage(icon)
					checkbox:SetCallback("OnEnter", showCheckboxTooltip)
					checkbox:SetCallback("OnLeave", hideCheckboxTooltip)
					widget:AddChild(checkbox)
				end
			end
		end
		widget:ResumeLayout()
		-- DoLayout the parent to update the scroll bar for the new height of the dropdowngroup
		frame:DoLayout()
	end

	local function createFrame()
		if frame then return end
		frame = AceGUI:Create("ScrollFrame")
		frame:SetLayout("List")

		local moduleDescription = AceGUI:Create("Label")
		moduleDescription:SetText(L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."])
		moduleDescription:SetFontObject(GameFontHighlight)
		moduleDescription:SetFullWidth(true)

		local classes = {}
		for class in next, spells do
			local color = oRA.classColors[class]
			classes[class] = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, LOCALIZED_CLASS_NAMES_MALE[class])
		end

		group = AceGUI:Create("DropdownGroup")
		group:SetLayout("Flow")
		group:SetTitle(L["Select class"])
		group:SetGroupList(classes)
		group:SetCallback("OnGroupSelected", dropdownGroupCallback)
		local _, playerClass = UnitClass("player")
		group:SetGroup(playerClass)
		group:SetFullWidth(true)

		if oRA.db.profile.showHelpTexts then
			frame:AddChildren(moduleDescription, group)
		else
			frame:AddChild(group)
		end
	end

	function showPane()
		if not frame then createFrame() end
		oRA:SetAllPointsToPanel(frame.frame, true)
		frame.frame:Show()
	end

	function hidePane()
		if frame then
			frame:Release()
			frame = nil
		end
	end
end

--------------------------------------------------------------------------------
-- Bar display
--

local startBar, setupCooldownDisplay, barStopped, stopAll
do
	local display = nil
	local maximum = 10
	local bars = {}
	local visibleBars = {}
	local locked = nil
	local shown = nil
	function isDisplayLocked() return locked end
	function isDisplayShown() return shown end

	function module:GetBars()
		return visibleBars
	end

	local function utf8trunc(text, num)
		local len = 0
		local i = 1
		local text_len = #text
		while len < num and i <= text_len do
			len = len + 1
			local b = text:byte(i)
			if b <= 127 then
				i = i + 1
			elseif b <= 223 then
				i = i + 2
			elseif b <= 239 then
				i = i + 3
			else
				i = i + 4
			end
		end
		return text:sub(1, i-1)
	end

	local shorts = setmetatable({}, {__index =
		function(self, key)
			if type(key) == "nil" then return nil end
			local p1, p2, p3, p4 = string.split(" ", (string.gsub(key,":", " :")))
			if not p2 then
				self[key] = utf8trunc(key, 4)
			elseif not p3 then
				self[key] = utf8trunc(p1, 1) .. utf8trunc(p2, 1)
			elseif not p4 then
				self[key] = utf8trunc(p1, 1) .. utf8trunc(p2, 1) .. utf8trunc(p3, 1)
			else
				self[key] = utf8trunc(p1, 1) .. utf8trunc(p2, 1) .. utf8trunc(p3, 1) .. utf8trunc(p4, 1)
			end
			return self[key]
		end
	})

	local function restyleBar(bar)
		bar:SetHeight(db.barHeight)
		bar:SetIcon(db.barShowIcon and bar:Get("ora3cd:icon") or nil)
		bar:SetTimeVisibility(db.barShowDuration)
		bar:SetScale(db.barScale)
		bar:SetTexture(media:Fetch(mTypeBar, db.barTexture))
		local spell = bar:Get("ora3cd:spell")
		local unit = bar:Get("ora3cd:unit"):gsub("(%a)%-(.*)", "%1")
		if db.barShorthand then spell = shorts[spell] end
		if db.barShowSpell and db.barShowUnit and not db.onlyShowMine then
			bar:SetLabel(("%s: %s"):format(unit, spell))
		elseif db.barShowSpell then
			bar:SetLabel(spell)
		elseif db.barShowUnit and not db.onlyShowMine then
			bar:SetLabel(unit)
		else
			bar:SetLabel()
		end

		--bar.candyBarLabel:SetFontObject("GameFontHighlightSmallOutline")
		bar.candyBarLabel:SetFont(media:Fetch(mTypeFont, db.barLabelFont), db.barLabelFontSize, db.barLabelOutline ~= "NONE" and db.barLabelOutline)
		bar.candyBarLabel:SetJustifyH(db.barLabelAlign)

		--bar.candyBarDuration:SetFontObject("GameFontHighlightSmallOutline")
		bar.candyBarDuration:SetFont(media:Fetch(mTypeFont, db.barDurationFont), db.barDurationFontSize, db.barDurationOutline ~= "NONE" and db.barDurationOutline)

		local c = oRA.classColors[bar:Get("ora3cd:unitclass")]
		if db.barLabelClassColor then
			bar.candyBarLabel:SetTextColor(c.r, c.g, c.b, 1)
		else
			bar.candyBarLabel:SetTextColor(unpack(db.barLabelColor))
		end
		if db.barDurationClassColor then
			bar.candyBarDuration:SetTextColor(c.r, c.g, c.b, 1)
		else
			bar.candyBarDuration:SetTextColor(unpack(db.barDurationColor))
		end
		if db.barClassColor then
			bar:SetColor(c.r, c.g, c.b, 1)
		else
			bar:SetColor(unpack(db.barColor))
		end
	end

	function stopAll()
		for bar in next, visibleBars do
			bar:Stop()
		end
	end

	local function barSorter(a, b)
		return a.remaining < b.remaining and true or false
	end
	local tmp = {}
	local function rearrangeBars()
		wipe(tmp)
		for bar in next, visibleBars do
			tmp[#tmp + 1] = bar
		end
		table.sort(tmp, barSorter)
		local lastBar = nil
		for i, bar in next, tmp do
			bar:ClearAllPoints()
			if i <= maximum then
				if not lastBar then
					if db.barGrowUp then
						bar:SetPoint("BOTTOMLEFT", display, 4, 4)
						bar:SetPoint("BOTTOMRIGHT", display, -4, 4)
					else
						bar:SetPoint("TOPLEFT", display, 4, -4)
						bar:SetPoint("TOPRIGHT", display, -4, -4)
					end
				else
					if db.barGrowUp then
						bar:SetPoint("BOTTOMLEFT", lastBar, "TOPLEFT")
						bar:SetPoint("BOTTOMRIGHT", lastBar, "TOPRIGHT")
					else
						bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT")
						bar:SetPoint("TOPRIGHT", lastBar, "BOTTOMRIGHT")
					end
				end
				lastBar = bar
				bar:Show()
			else
				bar:Hide()
			end
		end
	end

	function restyleBars()
		for bar in next, visibleBars do
			restyleBar(bar)
		end
		rearrangeBars()
	end

	function barStopped(event, bar)
		if visibleBars[bar] then
			visibleBars[bar] = nil
			rearrangeBars()
		end
	end

	local function OnDragHandleMouseDown(self) self.frame:StartSizing("BOTTOMRIGHT") end
	local function OnDragHandleMouseUp(self, button) self.frame:StopMovingOrSizing() end
	local function onResize(self, width, height)
		oRA3:SavePosition("oRA3CooldownFrame")
		maximum = math.floor((height or self:GetHeight()) / db.barHeight)
		-- if we have that many bars shown, hide the ones that overflow
		rearrangeBars()
	end

	local function displayOnMouseDown(self, mouseButton)
		if mouseButton ~= "RightButton" then return end
		InterfaceOptionsFrame_OpenToCategory(L["Cooldowns"])
	end

	local function onDragStart(self) self:StartMoving() end
	local function onDragStop(self)
		self:StopMovingOrSizing()
		oRA3:SavePosition("oRA3CooldownFrame")
	end

	function lockDisplay()
		if locked then return end
		if not display then setupCooldownDisplay() end
		display:EnableMouse(false)
		display:SetMovable(false)
		display:SetResizable(false)
		display:RegisterForDrag()
		display:SetScript("OnSizeChanged", nil)
		display:SetScript("OnDragStart", nil)
		display:SetScript("OnDragStop", nil)
		display:SetScript("OnMouseDown", nil)
		display.drag:Hide()
		display.header:Hide()
		display.bg:SetTexture(0, 0, 0, 0)
		locked = true
	end
	function unlockDisplay()
		if not locked then return end
		if not display then setupCooldownDisplay() end
		display:EnableMouse(true)
		display:SetMovable(true)
		display:SetResizable(true)
		display:RegisterForDrag("LeftButton")
		display:SetScript("OnSizeChanged", onResize)
		display:SetScript("OnDragStart", onDragStart)
		display:SetScript("OnDragStop", onDragStop)
		display:SetScript("OnMouseDown", displayOnMouseDown)
		display.bg:SetTexture(0, 0, 0, 0.3)
		display.drag:Show()
		display.header:Show()
		locked = nil
	end
	function showDisplay()
		if not display then setupCooldownDisplay() end
		display:Show()
		shown = true
	end
	function hideDisplay()
		if not display then return end
		display:Hide()
		shown = nil
	end

	local function setup()
		if display then
			if db.showDisplay then showDisplay() end
			return
		end
		display = CreateFrame("Frame", "oRA3CooldownFrame", UIParent)
		display:SetScript("OnEvent", combatLog)
		display:SetFrameStrata("BACKGROUND")
		display:SetMinResize(100, 20)
		display:SetWidth(200)
		display:SetHeight(148)
		if oRA3:RestorePosition("oRA3CooldownFrame") then
			onResize(display) -- draw the right number of bars
		end
		local bg = display:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(display)
		bg:SetBlendMode("BLEND")
		bg:SetTexture(0, 0, 0, 0.3)
		display.bg = bg
		local header = display:CreateFontString(nil, "OVERLAY")
		header:SetFontObject(GameFontNormal)
		header:SetText(L["Cooldowns"])
		header:SetPoint("BOTTOM", display, "TOP", 0, 4)
		local help = display:CreateFontString(nil, "HIGHLIGHT")
		help:SetFontObject(GameFontNormal)
		help:SetText(L["Right-Click me for options!"])
		help:SetAllPoints(display)
		display.header = header

		local drag = CreateFrame("Frame", nil, display)
		drag.frame = display
		drag:SetFrameLevel(display:GetFrameLevel() + 10) -- place this above everything
		drag:SetWidth(16)
		drag:SetHeight(16)
		drag:SetPoint("BOTTOMRIGHT", display, -1, 1)
		drag:EnableMouse(true)
		drag:SetScript("OnMouseDown", OnDragHandleMouseDown)
		drag:SetScript("OnMouseUp", OnDragHandleMouseUp)
		drag:SetAlpha(0.5)
		display.drag = drag

		local tex = drag:CreateTexture(nil, "OVERLAY")
		tex:SetTexture("Interface\\AddOns\\oRA3\\images\\draghandle")
		tex:SetWidth(16)
		tex:SetHeight(16)
		tex:SetBlendMode("ADD")
		tex:SetPoint("CENTER", drag)

		if db.lockDisplay then
			locked = nil
			lockDisplay()
		else
			locked = true
			unlockDisplay()
		end
		if db.showDisplay then
			shown = true
			showDisplay()
		else
			shown = nil
			hideDisplay()
		end
	end
	setupCooldownDisplay = setup

	local function start(unit, id, name, icon, duration)
		setup()
		local bar
		for b, v in next, visibleBars do
			if b:Get("ora3cd:unit") == unit and b:Get("ora3cd:spell") == name then
				bar = b
				break
			end
		end
		if not bar then
			bar = candy:New("Interface\\AddOns\\oRA3\\images\\statusbar", display:GetWidth(), db.barHeight)
		end
		visibleBars[bar] = true
		bar:Set("ora3cd:unitclass", classLookup[id])
		bar:Set("ora3cd:unit", unit)
		bar:Set("ora3cd:spell", name)
		bar:Set("ora3cd:icon", icon)
		bar:Set("ora3cd:spellid", id)
		bar:SetDuration(duration)
		restyleBar(bar)
		bar:Start()
		rearrangeBars()
	end
	startBar = start
end

--------------------------------------------------------------------------------
-- Module
--

function module:OnRegister()
	local database = oRA.db:RegisterNamespace("Cooldowns", {
		profile = {
			spells = {
				[20484] = true,
				[20608] = true,
				[20707] = true,
				[61999] = true,
				[126393] = true,
			},
			showDisplay = true,
			onlyShowMine = nil,
			neverShowMine = nil,
			lockDisplay = false,
			barShorthand = false,
			barHeight = 14,
			barScale = 1.0,
			barShowIcon = true,
			barShowDuration = true,
			barShowUnit = true,
			barShowSpell = true,
			barClassColor = true,
			barGrowUp = false,
			barLabelAlign = "CENTER",
			barColor = { 0.25, 0.33, 0.68, 1 },
			barTexture = "oRA3",
			barLabelClassColor = false,
			barLabelColor = { 1, 1, 1, 1 },
			barLabelFont = "Friz Quadrata TT",
			barLabelFontSize = 10,
			barLabelOutline = "NONE",
			barDurationClassColor = false,
			barDurationColor = { 1, 1, 1, 1 },
			barDurationFont = "Friz Quadrata TT",
			barDurationFontSize = 10,
			barDurationOutline = "NONE",
		},
	})
	for k, v in next, database.profile.spells do
		if not classLookup[k] then
			database.profile.spells[k] = nil
		end
	end
	db = database.profile

	oRA:RegisterPanel(
		L["Cooldowns"],
		showPane,
		hidePane
	)

	if media then
		media:Register(mTypeBar, "oRA3", "Interface\\AddOns\\oRA3\\images\\statusbar")
	end

	oRA.RegisterCallback(self, "OnStartup")
	oRA.RegisterCallback(self, "OnShutdown")
	oRA.RegisterCallback(self, "OnProfileUpdate", function()
		db = database.profile
	end)
	candy.RegisterCallback(self, "LibCandyBar_Stop", barStopped)
	oRA:RegisterModuleOptions("CoolDowns", getOptions, L["Cooldowns"])

	playerName = UnitName("player")
	playerGUID = UnitGUID("player")

	local _, playerClass = UnitClass("player")
	if playerClass == "SHAMAN" then
		-- GetSpellCooldown returns 0 when UseSoulstone is invoked, so we delay the check
		local function checkCooldown()
			local start, duration = GetSpellCooldown(20608)
			if start > 0 and duration > 1.5 then
				local elapsed = GetTime() - start -- don't resend the full duration if already on cooldown
				module:SendComm("Reincarnation", duration-elapsed)
			end
		end
		hooksecurefunc("UseSoulstone", function()
			if IsInGroup() then
				module:ScheduleTimer(checkCooldown, 1)
			end
		end)
	end
end

function module:IsOnCD(unit, spell)
	local barSpellKey = type(spell) == "string" and "ora3cd:spell" or "ora3cd:spellid"
	for bar in next, self:GetBars() do
		local barUnit = bar:Get("ora3cd:unit")
		if UnitIsUnit(barUnit, unit) and spell == bar:Get(barSpellKey) then
			return true
		end
	end
	return false
end

do
	local spellList, reverseClass = nil, nil
	function module:SpawnTestBar()
		if not spellList then
			spellList = {}
			reverseClass = {}
			for k in next, allSpells do spellList[#spellList + 1] = k end
			for name, class in next, oRA._testUnits do reverseClass[class] = name end
		end
		local spell = spellList[math.random(1, #spellList)]
		local name, _, icon = GetSpellInfo(spell)
		if not name then return end
		local unit = reverseClass[classLookup[spell]]
		local duration = (allSpells[spell] / 30) + math.random(1, 120)
		startBar(unit, spell, name, icon, duration)
	end
end

local function getCooldown(guid, spellId)
	local cd = allSpells[spellId]
	if cdModifiers[guid] and cdModifiers[guid][spellId] then
		cd = cd - cdModifiers[guid][spellId]
	end
	return cd
end

function module:OnStartup()
	setupCooldownDisplay()
	oRA3CooldownFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateCooldownModifiers")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateCooldownModifiers")
	self:RegisterEvent("PLAYER_ALIVE", "UpdateCooldownModifiers")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")

	LGIST.RegisterCallback(self, "GroupInSpecT_Update", "InspectUpdate")
	LGIST.RegisterCallback(self, "GroupInSpecT_Remove", "InspectRemove")

	oRA.RegisterCallback(self, "OnCommReceived")

	self:UpdateCooldownModifiers()
end

function module:OnShutdown()
	self:UnregisterAllEvents()
	oRA3CooldownFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	LGIST.UnregisterAllCallbacks(self)

	stopAll()
	hideDisplay()
	wipe(cdModifiers)
end

function module:OnCommReceived(_, sender, prefix, cd)
	if prefix == "Reincarnation" then
		self:Cooldown(sender, 20608, tonumber(cd))
	end
end

function module:GROUP_ROSTER_UPDATE()
	for bar in next, self:GetBars() do
		if not UnitExists(bar:Get("ora3cd:unit")) then
			bar:Stop()
		end
	end
end

function module:Cooldown(player, spell, cd)
	if type(spell) ~= "number" or type(cd) ~= "number" then error("Spell or number had the wrong type.") end
	if not db.spells[spell] then return end
	if db.onlyShowMine and not UnitIsUnit(player, "player") then return end
	if db.neverShowMine and UnitIsUnit(player, "player") then return end
	if not db.showDisplay then return end
	local spellName, _, icon = GetSpellInfo(spell)
	if not spellName or not icon then return end
	startBar(player, spell, spellName, icon, cd)
end

local function addMod(guid, spell, modifier)
	if modifier == 0 then return end
	if not cdModifiers[guid] then cdModifiers[guid] = {} end
	cdModifiers[guid][spell] = (cdModifiers[guid][spell] or 0) + modifier
end

local talentScanners = {
	PALADIN = function(info)
		if info.spec_index == 3 then -- Retribution
			addMod(info.guid, 31884, 60) -- 60 seconds off Avenging Wrath
		end
	end,
	WARRIOR = function(info)
		if info.talents[103826] then -- Juggernaut
			addMod(info.guid, 100, 8) -- 8 seconds off Charge
		end
	end,
	HUNTER = function(info)
		if info.talents[118675] then -- Crouching Tiger, Hidden Chimera
			addMod(info.guid, 781, 10) -- 10 secs off Disengage
			addMod(info.guid, 19263, 60) -- 60 secs off Deterrence
		end
	end,
	MAGE = function(info)
		if info.talents[110959] then -- Greater Invis
			addMod(info.guid, 66, 210) -- 210 secs off Invisibility
		end
		if info.talents[114003] then -- Invocation
			addMod(info.guid, 12051, 120) -- Evocation goes to 0
		end
	end,
	DRUID = function(info)
		if info.spec_index == 4 then -- Resto
			addMod(info.guid, 740, 300) -- 5min off Tranquility
		end
	end,
}

function module:UpdateCooldownModifiers()
	local info = LGIST:GetCachedInfo(playerGUID)
	if info then
		self:UpdateGroupCooldownModifiers(info)
	end
end

function module:UpdateGroupCooldownModifiers(info)
	if cdModifiers[info.guid] then
		wipe(cdModifiers[info.guid])
	end
	for spellId in next, info.glyphs do
		if glyphCooldowns[spellId] then
			local spell, modifier = unpack(glyphCooldowns[spellId])
			addMod(info.guid, spell, modifier)
		end
	end
	local talentMod = info.class and talentScanners[info.class]
	if talentMod then talentMod(info) end
end

function module:InspectUpdate(_, guid, unit, info)
	self:UpdateGroupCooldownModifiers(info)
end

function module:InspectRemove(_, guid)
	if not guid then return end
  cdModifiers[guid] = nil
end

do
	local function getPetOwner(pet, guid)
		if UnitGUID("pet") == guid then
			return playerName, playerGUID
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

	local IsEncounterInProgress, band, inEncounter = IsEncounterInProgress, bit.band, nil
	local group = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
	function combatLog(_, _, _, event, _, srcGUID, source, srcFlags, _, _, _, _, _, spellId)
		if source and (event == "SPELL_CAST_SUCCESS" or event == "SPELL_RESURRECT") and allSpells[spellId] and band(srcFlags, group) ~= 0 then
			if spellId == 126393 or spellId == 90355 or spellId == 160452 then -- Eternal Guardian/Ancient Hysteria/Netherwinds
				source, srcGUID = getPetOwner(source, srcGUID)
			elseif spellId == 95750 then -- Combat Soulstone, funnel it via normal Soulstone
				spellId = 20707
			end
			module:Cooldown(source, spellId, getCooldown(srcGUID, spellId))
		end

		if not inEncounter and IsEncounterInProgress() then
			inEncounter = true
		elseif inEncounter and not IsEncounterInProgress() then
			inEncounter = nil
			for bar in next, module:GetBars() do
				local spell = bar:Get("ora3cd:spellid")
				if allSpells[spell] > 299 and spell ~= 20608 then -- reset 5min+ cds (but not reincarnation)
					bar:Stop()
				end
			end
		end
	end
end

