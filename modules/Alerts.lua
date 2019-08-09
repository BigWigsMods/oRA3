
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	return
end

local _, scope = ...
local oRA = scope.addon
local module = oRA:NewModule("Alerts", "AceTimer-3.0")
-- local L = scope.locale
local L = setmetatable({}, { -- XXX update locale!
	__index = function(t, k)
		t[k] = k
		return k
	end,
})
local classColors = oRA.classColors

local combatLogHandler = CreateFrame("Frame")
local GetOptions

local LE_PARTY_CATEGORY_INSTANCE = _G.LE_PARTY_CATEGORY_INSTANCE
local bit_band, bit_bor = bit.band, bit.bor
local tconcat = table.concat

local outputValues = { -- channel list
	-- ["self"] = L["Self"],
	["say"] = _G.SAY,
	--["yell"] = _G.YELL,
	["group"] = _G.GROUP,
	["party"] = _G.PARTY,
	["raid"] = _G.RAID,
	["raid_warning"] = _G.RAID_WARNING,
	["guild"] = _G.GUILD,
	["officer"] = _G.OFFICER,
	--["channel"] = _G.CHANNEL,
}
local outputValuesWithChannels = {} -- channel list with custom channels mixed in

local UNKNOWN = ("(%s)"):format(_G.UNKNOWN)
local soulstoneList = {}

local combatLogMap = {}
combatLogMap.SPELL_CAST_SUCCESS = {
	-- Repair Bots
	[22700] = "Repair",  -- Field Repair Bot 74A
	[44389] = "Repair",  -- Field Repair Bot 110G
	[54711] = "Repair",  -- Scrapbot
	[67826] = "Repair",  -- Jeeves
	[157066] = "Repair", -- Walter
	[199109] = "Repair", -- Auto-Hammer
	-- Summoning
	[698] = "Summon", -- Ritual of Summoning (Warlock)
	-- Misdirects
	[34477] = "Misdirect", -- Misdirection (Hunter)
	[57934] = "Misdirect", -- Tricks of the Trade (Rogue)
	-- AoE Taunts
	[108199] = "TauntCast",  -- Gorefiend's Grasp (Death Knight)
	-- Interrupts
	[47528] = "InterruptCast", -- Mind Freeze (Death Knight)
	[106839] = "InterruptCast",-- Skull Bash (Druid)
	[147362] = "InterruptCast",-- Counter Shot (Hunter)
	[187707] = "InterruptCast",-- Muzzle (Hunter)
	[2139] = "InterruptCast",  -- Counterspell (Mage)
	[15487] = "InterruptCast", -- Silence (Priest)
	[1766] = "InterruptCast",  -- Kick (Rogue)
	[57994] = "InterruptCast", -- Wind Shear (Shaman)
	[6552] = "InterruptCast",  -- Pummel (Warrior)
	[96231] = "InterruptCast", -- Rebuke (Paladin)
	[183752] = "InterruptCast",-- Consume Magic (Demon Hunter)
	-- Reincarnation
	[21169] = "Reincarnation", -- Reincarnation
	[199115] = "Reincarnation", -- Failure Detection Pylon
	-- Mass Resurrection
	[212056] = "MassResurrection", -- Absolution (Paladin)
	[212048] = "MassResurrection", -- Ancestral Vision (Shaman)
	[212036] = "MassResurrection", -- Mass Resurrection (Priest)
	[212051] = "MassResurrection", -- Reawaken (Monk)
	[212040] = "MassResurrection", -- Revitalize (Druid)
	-- Bloodlust
	[2825] = "Bloodlust", -- Bloodlust
	[32182] = "Bloodlust", -- Heroism
	[80353] = "Bloodlust", -- Time Warp
	[264667] = "Bloodlust", -- Primal Rage
	[178207] = "Bloodlust", -- Drums of Fury (WoD)
	[230935] = "Bloodlust", -- Drums of the Mountain (Legion)
	[256740] = "Bloodlust", -- Drums of the Maelstrom (BfA)
	[292686] = "Bloodlust", -- Mallet of Thunderous Skins (BfA)
}
combatLogMap.SPELL_AURA_APPLIED = {
	-- Taunts
	[355] = "Taunt",    -- Taunt (Warrior)
	[6795] = "Taunt",   -- Growl (Druid)
	[51399] = "Taunt",  -- Death Grip (Death Knight)
	[56222] = "Taunt",  -- Dark Command (Death Knight)
	[62124] = "Taunt",  -- Hand of Reckoning (Paladin)
	[116189] = "Taunt", -- Provoke (Monk)
	[118635] = "TauntAE", -- Provoke (Monk, Black Ox Statue)
	[185245] = "Taunt", -- Torment (Vengeance Demon Hunter)
	[281854] = "Taunt", -- Torment (Havoc Demon Hunter)
	-- Pet Taunts
	[17735] = "TauntPet",   -- Suffering (Warlock Pet)
	[2649] = "TauntPet",    -- Growl (Hunter Pet)
	[196727] = "TauntPet", -- Provoke (Niuzao, Monk Pet)
}
combatLogMap.SPELL_CREATE = {
	-- Portals
	[11419] = "Portal", -- Darnassus
	[32266] = "Portal", -- Exodar
	[11416] = "Portal", -- Ironforge
	[11417] = "Portal", -- Orgrimmar
	[33691] = "Portal", -- Shattrath (Alliance)
	[35717] = "Portal", -- Shattrath (Horde)
	[32267] = "Portal", -- Silvermoon
	[10059] = "Portal", -- Stormwind
	[11420] = "Portal", -- Thunder Bluff
	[11418] = "Portal", -- Undercity
	[49360] = "Portal", -- Theramore
	[49361] = "Portal", -- Stonard
	[53142] = "Portal", -- Dalaran (Northrend)
	[88345] = "Portal", -- Tol Barad (Alliance)
	[88346] = "Portal", -- Tol Barad (Horde)
	[132620] = "Portal",-- Vale Blossom (Alliance)
	[132626] = "Portal",-- Vale Blossom (Horde)
	[176244] = "Portal", -- Warspear
	[176246] = "Portal", -- Stormshield
	[120146] = "Portal", -- Dalaran (Crater)
	[224871] = "Portal", -- Dalaran (Broken Isles)
	[281400] = "Portal", -- Boralus
	[281402] = "Portal", -- Dazar'alor
	-- Feasts
	[201351] = "Feast", -- Hearty Feast (+18)
	[201352] = "Feast", -- Lavish Suramar Feast (+22)
	[259409] = "Feast", -- Galley Banquet (+75)
	[259410] = "Feast", -- Bountiful Captain's Feast (+100)
	[286050] = "Feast", -- Sanguinated Feast (+100)
	[297048] = "Feast", -- Famine Evaluator And Snack Table (+131)
	-- Instant Rituals
	[29893] = "Feast", -- Create Soulwell (Warlock)
	[190336] = "Feast", -- Conjure Refreshment (Mage)
	[276972] = "Feast", -- Mystical Cauldron
	[298861] = "Feast", -- Greater Mystical Cauldron
}
combatLogMap.SPELL_RESURRECT = {
	["*"] = "Resurrect",
	-- Mass Resurrection
	[212056] = false, -- Absolution (Paladin)
	[212048] = false, -- Ancestral Vision (Shaman)
	[212036] = false, -- Mass Resurrection (Priest)
	[212051] = false, -- Reawaken (Monk)
	[212040] = false, -- Revitalize (Druid)
	-- Combat Res
	[20484] = "CombatResurrect",  -- Rebirth (Druid)
	[61999] = "CombatResurrect",  -- Raise Ally (Death Knight)
	[95750] = "CombatResurrect",  -- Soulstone Resurrection (Warlock)
	[265116] = "CombatResurrect", -- Unstable Temporal Time Shifter (Engineer)
}
combatLogMap.SPELL_AURA_REMOVED = {
	[20707] = "Soulstone",  --  Buff removed on death
}
combatLogMap.SPELL_DISPEL = {
	["*"] = "Dispel",
	[115310] = "MassDispel", -- Revival (Monk)
	-- Mass Dispel (Priest)
	[32375] = "MassDispel",
	[39897] = "MassDispel",
	[32592] = "MassDispel",
	-- Arcane Torrent
	[28730] = "MassDispel",  -- Mage, Warlock
	[25046] = "MassDispel",  -- Rogue
	[50613] = "MassDispel",  -- Death Knight
	[69179] = "MassDispel",  -- Warrior
	[80483] = "MassDispel",  -- Hunter
	[129597] = "MassDispel", -- Monk
	[155145] = "MassDispel", -- Paladin
	[202719] = "MassDispel", -- Demon Hunter
	[232633] = "MassDispel", -- Priest
}
combatLogMap.SPELL_STOLEN = combatLogMap.SPELL_DISPEL
combatLogMap.SPELL_INTERRUPT = {
	["*"] = "Interrupt",
}
combatLogMap.SPELL_MISSED = {
	-- Interrupts
	[47528] = "InterruptMiss", -- Mind Freeze (Death Knight)
	[106839] = "InterruptMiss",-- Skull Bash (Druid)
	[147362] = "InterruptMiss",-- Counter Shot (Hunter)
	[187707] = "InterruptMiss",-- Muzzle (Hunter)
	[2139] = "InterruptMiss",  -- Counterspell (Mage)
	[15487] = "InterruptMiss", -- Silence (Priest)
	[1766] = "InterruptMiss",  -- Kick (Rogue)
	[57994] = "InterruptMiss", -- Wind Shear (Shaman)
	[6552] = "InterruptMiss",  -- Pummel (Warrior)
	[96231] = "InterruptMiss", -- Rebuke (Paladin)
	[183752] = "InterruptMiss",-- Consume Magic (Demon Hunter)
	-- Pet Interrupts
	[19647] = "InterruptMiss",  -- Felhunter Spell Lock (Normal, originates from pet)
	[119910] = "InterruptMiss", -- Felhunter Spell Lock (via Command Demon, originates from player)
	[171138] = "InterruptMiss", -- Doomguard Shadow Lock (Normal, originates from pet)
	[171140] = "InterruptMiss", -- Doomguard Shadow Lock (via Command Demon, originates from player)
	-- Taunts
	[355] = "TauntMiss",    -- Taunt (Warrior)
	[6795] = "TauntMiss",   -- Growl (Druid)
	[51399] = "TauntMiss",  -- Death Grip (Death Knight)
	[56222] = "TauntMiss",  -- Dark Command (Death Knight)
	[62124] = "TauntMiss",  -- Hand of Reckoning (Paladin)
	[115546] = "TauntMiss", -- Provoke (Monk)
	[185245] = "TauntMiss", -- Torment (Demon Hunter)
	-- Pet Taunts
	[17735] = "TauntMiss",  -- Suffering (Warlock Pet)
	[2649] = "TauntMiss",   -- Growl (Hunter Pet)
	[196727] = "TauntMiss", -- Provoke (Monk Pet, Niuzao)
}
-- Crowd Control
combatLogMap.SPELL_AURA_BROKEN_SPELL = {
	[3355] = "CrowdControl",   -- Freezing Trap (Hunter)
	[19386] = "CrowdControl",  -- Wyvern Sting (Hunter)
	[200108] = "CrowdControl", -- Ranger's Net (Hunter)
	[6358] = "CrowdControl",   -- Seduction (Warlock Pet)
	[115268] = "CrowdControl", -- Mesmerize (Warlock Pet)
	[118699] = "CrowdControl", -- Fear (Warlock)
	[130616] = "CrowdControl", -- Fear (Warlock Glyph)
	[9484] = "CrowdControl",   -- Shackle Undead (Priest)
	[51514] = "CrowdControl",  -- Hex (Shaman)
	[196942] = "CrowdControl", -- Hex - Voodo Totemn (Shaman)
	[20066] = "CrowdControl",  -- Repentance (Paladin)
	[118] = "CrowdControl",    -- Polymorph (Mage)
	[28271] = "CrowdControl",  -- Polymorph Turtle (Mage)
	[28272] = "CrowdControl",  -- Polymorph Pig (Mage)
	[61305] = "CrowdControl",  -- Polymorph Black Cat (Mage)
	[61721] = "CrowdControl",  -- Polymorph Rabbit (Mage)
	[61780] = "CrowdControl",  -- Polymorph Turkey (Mage)
	[126819] = "CrowdControl", -- Polymorph Porcupine (Mage)
	[161354] = "CrowdControl", -- Polymorph Monkey (Mage)
	[161372] = "CrowdControl", -- Polymorph Peacock (Mage)
	[161353] = "CrowdControl", -- Polymorph Polar Bear Cub (Mage)
	[161355] = "CrowdControl", -- Polymorph Penguin (Mage)
	[339] = "CrowdControl",    -- Entangling Roots (Druid)
	[2094] = "CrowdControl",   -- Blind (Rogue)
	[6770] = "CrowdControl",   -- Sap (Rogue)
	[115078] = "CrowdControl", -- Paralysis (Monk)
	[217832] = "CrowdControl", -- Imprision (Demon Hunter)
	[207685] = "CrowdControl", -- Sigil of Misery (Demon Hunter)
}
combatLogMap.SPELL_AURA_BROKEN = combatLogMap.SPELL_AURA_BROKEN_SPELL -- for SWING_DAMAGE breaks

combatLogMap.SPELL_SUMMON = {
	["*"] = "AssignOwner", -- Used to map guardians to their owners
	-- Reaves
	[200205] = "Repair", -- Auto-Hammer Mode
	[200211] = "Reincarnation", -- Failure Detection Mode
	[200216] = "Feast", -- Snack Distribution Mode (+10 versatility)
}

-- cache pet owner names
local petOwnerMap = {}

function module:Spam(key, msg)
	if not msg or msg == "" then return end
	if not self.db.profile[key] then return end

	local output = (self.db.profile.outputs[key] or self.db.profile.output):lower()
	local chatframe = _G.DEFAULT_CHAT_FRAME
	local fallback = nil

	local isInstanceGroup = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)

	local chatMsg = msg:gsub("|Hicon:%d+:dest|h|TInterface.TargetingFrame.UI%-RaidTargetingIcon_(%d).blp:0|t|h", "{rt%1}") -- replace icon textures
	chatMsg = chatMsg:gsub("|Hplayer:.-|h(.-)|h", "%1") -- remove player links
	chatMsg = chatMsg:gsub("|c%x%x%x%x%x%x%x%x([^|].-)|r", "%1") -- remove color

	if not IsInGroup() and outputValues[output] then
		fallback = true
	elseif output == "say" or output == "yell" then
		SendChatMessage(chatMsg, output)
	elseif output == "group" then
		if isInstanceGroup then
			if not self.db.profile.disableForLFG then
				SendChatMessage(chatMsg, "INSTANCE_CHAT")
			else
				fallback = true
			end
		else
			SendChatMessage(chatMsg, "RAID")
		end
	elseif output == "raid" then
		if IsInRaid() and (not self.db.profile.disableForLFG or not isInstanceGroup) then
			SendChatMessage(chatMsg, isInstanceGroup and "INSTANCE_CHAT" or "RAID")
		else
			fallback = true
		end
	elseif output == "raid_warning" then
		if IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or IsEveryoneAssistant()) then
			SendChatMessage(chatMsg, output)
		else
			fallback = true
		end
	elseif output == "party" then
		if not self.db.profile.disableForLFG or not isInstanceGroup then
			SendChatMessage(chatMsg, isInstanceGroup and "INSTANCE_CHAT" or "PARTY")
		else
			fallback = true
		end
	elseif output == "guild" then
		if IsInGuild() then
			SendChatMessage(chatMsg, output)
		else
			fallback = true
		end
	elseif output == "officer" then
		if IsInGuild() then
			SendChatMessage(chatMsg, output)
		else
			fallback = true
		end
	elseif not outputValues[output] and output ~= "self" then
		local type = output:sub(1,1)
		local index = tonumber(output:sub(2))
		output = "self"
		if index then
			if type == "c" and GetChannelName(index) > 0 then
				SendChatMessage(chatMsg, "CHANNEL", nil, index)
			elseif type == "t" then
				local frame = _G["ChatFrame"..index]
				if frame and frame ~= _G.COMBATLOG and (frame.isDocked or select(7, _G.GetChatWindowInfo(index))) then
					chatframe = frame
				end
			end
		end
	end

	if output == "self" or (self.db.profile.fallback and fallback) then
		chatframe:AddMessage(("|Hgarrmission:oRA:%s|h|cff33ff99oRA3|r|h: %s"):format(chatMsg:gsub("|", "@"), msg))
	end
end

-- Multi-target stuff
do
	local targets = {}

	local function spam(key, index, message, ...)
		local args = {...} -- ugh, pick the table out of the args and join it
		for i,v in ipairs(args) do
			if type(v) == "table" then
				args[i] = tconcat(v, ", ")
				break
			end
		end
		module:Spam(key, message:format(unpack(args)))
		targets[index] = nil
	end

	function module:SpamMultiCast(key, source, dest, spell)
		if not self.db.profile[key] then return end
		local index = source..spell
		if not targets[index] then
			targets[index] = {}
			self:ScheduleTimer(spam, 0.2, key, index, L["%s cast %s on %s"], source, spell, targets[index])
		end
		tinsert(targets[index], dest)
	end

	function module:SpamMultiRemoved(key, source, dest, spell, extra)
		if not self.db.profile[key] then return end
		local index = source..spell..extra
		if not targets[index] then
			targets[index] = {}
			self:ScheduleTimer(spam, 0.2, key, index, L["%s on %s removed by %s's %s"], extra, targets[index], source, spell)
		end
		tinsert(targets[index], dest)
	end
end


local function getClassColor(name)
	if name and module.db.profile.classColor then
		local _, class = UnitClass(name)
		if class then
			return classColors[class].colorStr
		end
	end
end

local UpdatePets
do -- COMBAT_LOG_EVENT_UNFILTERED
	function module:UNIT_PET(unit)
		local pet = UnitGUID(unit .. "pet")
		if pet then
			petOwnerMap[pet] = self:UnitName(unit)
		end
	end

	function UpdatePets()
		for unit in module:IterateGroup() do
			module:UNIT_PET(unit)
		end
	end

	-- return an icon if set in the unit's raid flags
	local COMBATLOG_OBJECT_RAIDTARGET_MASK, TEXT_MODE_A_STRING_DEST_ICON = COMBATLOG_OBJECT_RAIDTARGET_MASK, TEXT_MODE_A_STRING_DEST_ICON
	local raidTargetIcon = {}
	for i = 1, 8 do
		raidTargetIcon[_G["COMBATLOG_OBJECT_RAIDTARGET"..i]] = i
	end

	local function getIconString(flags)
		if module.db.profile.icons then
			local num = bit_band(flags, COMBATLOG_OBJECT_RAIDTARGET_MASK)
			local index = raidTargetIcon[num]
			if index then
				return TEXT_MODE_A_STRING_DEST_ICON:format(index, _G["COMBATLOG_ICON_RAIDTARGET"..index])
			end
		end
		return ""
	end

	local FILTER_FRIENDLY_PLAYERS = bit_bor(COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_REACTION_FRIENDLY)
	local function getName(name, guid, flags, color)
		local petOwner = petOwnerMap[guid]
		if petOwner then
			petOwner = ("|c%s|Hplayer:%s|h%s|h|r"):format(getClassColor(petOwner) or color, petOwner, petOwner:gsub("%-.*", ""))
			return L["%s's %s"]:format(petOwner, name or UNKNOWN)
		elseif name and bit_band(flags, FILTER_FRIENDLY_PLAYERS) == FILTER_FRIENDLY_PLAYERS then
			return ("|c%s|Hplayer:%s|h%s|h|r"):format(getClassColor(name) or color, name, name:gsub("%-.*", ""))
		end
		return ("|c%s%s|r"):format(color, name or UNKNOWN)
	end

	local extraUnits = {"target", "focus", "focustarget", "mouseover", "boss1", "boss2", "boss3", "boss4", "boss5"}
	for i = 1, 40 do extraUnits[#extraUnits + 1] = "nameplate"..i end
	local function getUnit(guid)
		for i = 1, #extraUnits do
			local unit = extraUnits[i]
			if UnitGUID(unit) == guid then return unit end
		end

		for unit in module:IterateGroup() do
			local target = unit.."target"
			if UnitGUID(target) == guid then return target end
		end
	end

	local immunities = {
		642, -- Divine Shield
		710, -- Banish
		1022, -- Blessing of Protection
		204018, -- Blessing of Spellwarding
		5277, -- Evasion
		31224, -- Cloak of Shadows
		33786, -- Cyclone (PvP)
		45438, -- Ice Block
		104773, -- Unending Resolve
		186265, -- Aspect of the Turtle
		196555, -- Netherwalk
		221527, -- Imprision (PvP)
	}
	local function getMissReason(unit)
		local name, expires = module:UnitBuffByIDs(unit, immunities)
		if name then
			if expires then
				expires = tonumber(("%.1f"):format(expires - GetTime()))
				if expires < 1 then expires = nil end
			end
			return name, expires
		end
	end

	local function isCasting(unit)
		if not unit then return end

		local name, _, _, _, _, _, _, notInterruptible, spellId = UnitCastingInfo(unit)
		if name then
			return spellId, not notInterruptible
		end

		name, _, _, _, _, _, notInterruptible, spellId = UnitChannelInfo(unit)
		if name then
			return spellId, not notInterruptible
		end
	end

	-- aaand where all the magic happens
	local FILTER_GROUP = bit_bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
	combatLogHandler:SetScript("OnEvent", function()
		local _, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, spellId, spellName, _, extraSpellId = CombatLogGetCurrentEventInfo()

		-- first check if someone died
		if event == "UNIT_DIED" or event == "UNIT_DESTROYED" then
			if soulstoneList[dstName] then
				soulstoneList[dstName] = GetTime() + 60 -- if you hold onto it for more than a minute...prolly don't care
			end
			petOwnerMap[dstGUID] = nil -- army (DIED), totems (DESTROYED)
			return
		end

		local e = combatLogMap[event]
		if not e then return end

		local handler = e[spellId]
		if handler == nil then handler = e["*"] end -- can be false to ignore
		if handler and (not module.db.profile.groupOnly or bit_band(bit_bor(srcFlags, dstFlags), FILTER_GROUP) ~= 0) then
			-- special cases
			if handler == "AssignOwner" then
				if bit_band(srcFlags, FILTER_GROUP) ~= 0 then
					petOwnerMap[dstGUID] = srcName
				end
				return
			elseif handler == "Soulstone" then
				module:Soulstone(dstName)
				return
			elseif handler == "Dispel" then
				if extraSpellId == 1604 then -- Dazed
					return
				end
			elseif handler == "Interrupt" then
				-- ignore players getting interrupted
				if bit_band(dstFlags, FILTER_FRIENDLY_PLAYERS) == FILTER_FRIENDLY_PLAYERS then
					return
				end
			elseif handler == "InterruptCast" then -- not casting alert
				local unit = getUnit(dstGUID)
				if not unit then return end

				local casting, interruptible = isCasting(unit)
				if casting then
					if interruptible then
						-- wait for SPELL_INTERRUPT or SPELL_MISSED
						return
					end

					-- handle uninterruptible casts (no SPELL_MISSED)
					event = "SPELL_MISSED"
					handler = "InterruptImmune"
					extraSpellId = L["%s is uninterruptible"]:format(GetSpellLink(casting))
				end
			elseif handler == "InterruptMiss" then
				local unit = getUnit(dstGUID)
				if isCasting(unit) then
					-- check if the miss was due to an immunity buff on the target
					local reason, timeleft = getMissReason(unit)
					if reason then
						handler = "InterruptImmune"
						if timeleft then
							extraSpellId = ("%s - %s, %ss remaining"):format(_G.ACTION_SPELL_MISSED_IMMUNE, reason, timeleft)
						else
							extraSpellId = ("%s - %s"):format(_G.ACTION_SPELL_MISSED_IMMUNE, reason)
						end
					end
				end
			end

			-- format output strings
			local srcOutput = ("%s%s"):format(getIconString(srcRaidFlags), getName(srcName, srcGUID, srcFlags, "ff40ff40"))
			local dstOutput = ("%s%s"):format(getIconString(dstRaidFlags), getName(dstName, dstGUID, dstFlags, "ffff4040"))
			local spellOutput = GetSpellLink(spellId)
			local extraSpellOuput = nil
			if event == "SPELL_DISPEL" or event == "SPELL_STOLEN" or event == "SPELL_INTERRUPT" or event == "SPELL_AURA_BROKEN_SPELL" then
				extraSpellOuput = GetSpellLink(extraSpellId)
			elseif event == "SPELL_MISSED" then
				extraSpellOuput = extraSpellId -- missType
			end

			-- execute!
			return module[handler](module, srcOutput, dstOutput, spellOutput, extraSpellOuput)
		end

	end)

	-- Codex handling
	local prev = nil
	function module:UNIT_SPELLCAST_SUCCEEDED(unit, spellCastGUID, spellId)
		if (spellId == 226241 or spellId == 256230) and spellCastGUID ~= prev then -- Codex of the Tranquil/Quiet Mind
			prev = spellCastGUID
			local srcName, srcGUID, srcRaidFlags = self:UnitName(unit), UnitGUID(unit), 0
			local icon = GetRaidTargetIndex(unit)
			if icon then
				srcRaidFlags = _G["COMBATLOG_OBJECT_RAIDTARGET" .. icon] or 0
			end
			local srcOutput = ("%s|cff40ff40%s|r"):format(getIconString(srcRaidFlags), getName(srcName, srcGUID, 0, getClassColor(srcName) or "ff40ff40"))
			local spellOutput = GetSpellLink(spellId)
			self:Codex(srcOutput, nil, spellOutput)
		end
	end
end

---------------------------------------
-- Spell handlers

function module:CrowdControl(srcOutput, dstOutput, spellOutput, extraSpellOuput)
	if extraSpellOuput then -- SPELL_AURA_BROKEN_SPELL
		self:Spam("crowdControl", L["%s on %s removed by %s's %s"]:format(spellOutput, dstOutput, srcOutput, extraSpellOuput))
	else -- SPELL_AURA_BROKEN
		self:Spam("crowdControl", L["%s on %s removed by %s"]:format(spellOutput, dstOutput, srcOutput))
	end
end

function module:Misdirect(srcOutput, dstOutput, spellOutput)
	self:Spam("misdirect", L["%s cast %s on %s"]:format(srcOutput, spellOutput, dstOutput))
end

function module:Taunt(srcOutput, dstOutput, spellOutput)
	self:Spam("taunt", L["%s cast %s on %s"]:format(srcOutput, spellOutput, dstOutput))
end

function module:TauntPet(srcOutput, dstOutput, spellOutput)
	self:Spam("tauntPet", L["%s cast %s on %s"]:format(srcOutput, spellOutput, dstOutput))
end

function module:TauntCast(srcOutput, _, spellOutput)
	self:Spam("taunt", L["%s cast %s"]:format(srcOutput, spellOutput))
end

function module:TauntAE(srcOutput, dstOutput, spellOutput)
	self:SpamMultiCast("taunt", srcOutput, dstOutput, spellOutput)
end

function module:TauntMiss(srcOutput, dstOutput, spellOutput, missType)
	self:Spam("taunt", L["%s missed %s on %s (%s)"]:format(srcOutput, spellOutput, dstOutput, _G["ACTION_SPELL_MISSED_"..missType]))
end

function module:Dispel(srcOutput, dstOutput, spellOutput, extraSpellOuput)
	self:Spam("dispel", L["%s on %s removed by %s's %s"]:format(extraSpellOuput, dstOutput, srcOutput, spellOutput))
end

function module:MassDispel(srcOutput, dstOutput, spellOutput, extraSpellOuput)
	self:SpamMultiRemoved("dispel", srcOutput, dstOutput, spellOutput, extraSpellOuput)
end

function module:Interrupt(srcOutput, dstOutput, spellOutput, extraSpellOuput)
	self:Spam("interrupt", L["%s's %s interrupted %s's %s"]:format(srcOutput, spellOutput, dstOutput, extraSpellOuput))
end

function module:InterruptCast(srcOutput, dstOutput, spellOutput)
	self:Spam("interruptMiss", L["%s missed %s on %s (%s)"]:format(srcOutput, spellOutput, dstOutput, L["Not casting"]))
end

function module:InterruptMiss(srcOutput, dstOutput, spellOutput, missType)
	self:Spam("interruptMiss", L["%s missed %s on %s (%s)"]:format(srcOutput, spellOutput, dstOutput, _G["ACTION_SPELL_MISSED_"..missType]))
end

function module:InterruptImmune(srcOutput, dstOutput, spellOutput, extraSpellOuput)
	self:Spam("interruptMiss", L["%s missed %s on %s (%s)"]:format(srcOutput, spellOutput, dstOutput, extraSpellOuput))
end

do
	local function setAlive(dstOutput)
		for name in next, soulstoneList do
			if dstOutput:find(name:gsub("%-.*", ""), nil, true) then
				soulstoneList[name] = nil
			end
		end
	end

	function module:Resurrect(srcOutput, dstOutput, spellOutput)
		setAlive(dstOutput)
		self:Spam("resurrect", L["%s cast %s on %s"]:format(srcOutput, spellOutput, dstOutput))
	end

	function module:MassResurrection(srcOutput, _, spellOutput)
		wipe(soulstoneList)
		self:Spam("resurrect", L["%s cast %s"]:format(srcOutput, spellOutput))
	end

	function module:CombatResurrect(srcOutput, dstOutput, spellOutput)
		setAlive(dstOutput)
		--local key = UnitAffectingCombat("player") and "combatRes" or "resurrect"
		self:Spam("combatRes", L["%s cast %s on %s"]:format(srcOutput, spellOutput, dstOutput))
	end

	function module:Reincarnation(srcOutput, dstOutput, spellOutput)
		-- setAlive(dstOutput)
		self:Spam("combatRes", L["%s used %s"]:format(srcOutput, spellOutput))
	end
end

function module:Bloodlust(srcOutput, _, spellOutput)
	self:Spam("bloodlust", L["%s cast %s"]:format(srcOutput, spellOutput))
end

function module:Portal(srcOutput, _, spellOutput)
	self:Spam("portal", L["%s used %s"]:format(srcOutput, spellOutput))
end

function module:Repair(srcOutput, _, spellOutput)
	self:Spam("repair", L["%s used %s"]:format(srcOutput, spellOutput))
end

function module:Feast(srcOutput, _, spellOutput)
	self:Spam("feast", L["%s used %s"]:format(srcOutput, spellOutput))
end

function module:Summon(srcOutput, _, spellOutput)
	self:Spam("summon", L["%s is casting %s"]:format(srcOutput, spellOutput))
end

function module:Codex(srcOutput, _, spellOutput)
	self:Spam("codex", L["%s used %s"]:format(srcOutput, spellOutput))
end

do
	--- Soulstone
	-- Kind of convoluted x.x When someone losses a Soulstone buff, :Soulstone
	-- gets called and we set an initial entry to check for their death since we
	-- don't know if it just wore off normally. If UNIT_DIED fires before our
	-- "buffer" entry expires, we update the entry with a 60s expiry. If that
	-- player becomes alive (not UnitIsDead) in that time period, we report
	-- them as having used the Soulstone!

	local buffs = {
		27827, -- Spirit of Redemption
		5384, -- Feign Death
	}

	local total = 0
	local function checkDead(self, elapsed)
		total = elapsed + total
		if total > 1 then
			total = 0

			if not IsEncounterInProgress() then
				wipe(soulstoneList)
			end

			local now = GetTime()
			for name, expires in next, soulstoneList do
				if now > expires or UnitIsGhost(name) or not UnitIsConnected(name) then -- expired (waited 60 seconds, now i don't care) or released or dc'd
					soulstoneList[name] = nil
				elseif not UnitIsDead(name) and UnitIsConnected(name) and not UnitIsFeignDeath(name) and not module:UnitBuffByIDs(name, buffs) then
					soulstoneList[name] = nil
					local srcOutput = ("|c%s|Hplayer:%s|h%s|h|r"):format(getClassColor(name) or "ff40ff40", name, name:gsub("%-.*", ""))
					local spellOutput = GetSpellLink(20707) -- Soulstone
					module:Spam("combatRes", L["%s used %s"]:format(srcOutput, spellOutput))
				end
			end

			if not next(soulstoneList) then
				self:SetScript("OnUpdate", nil)
			end
		end
	end

	function module:Soulstone(name)
		if not name or not self.db.profile.combatRes then return end
		soulstoneList[name] = GetTime() + .2 -- buffer for UNIT_DIED to fire
		combatLogHandler:SetScript("OnUpdate", checkDead)
	end
end


---------------------------------------
-- Who pulled?

do
	local encounter = nil
	local encounterStart = 0

	function module:UNIT_FLAGS(unit)
		if (unit == "player" or unit:match("^raid") or unit:match("^party")) and UnitAffectingCombat(unit) then
			if encounter and GetTime() - encounterStart < 15 then -- timeout for safety's sake
				local name = self:UnitName(unit:gsub("pet$", ""))
				local source = ("|c%s|Hplayer:%s|h%s|h|r"):format(getClassColor(name) or "ff40ff40", name, name:gsub("%-.*", ""))
				local boss = ("|cffff8000%s|r"):format(encounter) -- would be nice to turn this into proper EJ link
				self:Spam("pulled", L["%s engaged %s"]:format(source, boss))
			end
			encounter = nil
			self:UnregisterEvent("UNIT_FLAGS")
		end
	end

	function module:ENCOUNTER_START(_, name)
		encounter = name
		encounterStart = GetTime()
		self:RegisterEvent("UNIT_FLAGS")
	end
end


---------------------------------------
-- Init

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("Alerts", {
		profile = {
			pulled = true,
			crowdControl = true,
			misdirect = true,
			taunt = false,
			tauntPet = false,
			interrupt = false,
			interruptMiss = false,
			dispel = false,
			combatRes = true,
			bloodlust = true,
			portal = true,
			repair = true,
			feast = true,
			summon = true,
			resurrect = false,
			codex = true,

			output = "self",
			separateOutputs = false,
			outputs = {},

			enableForWorld = false,
			enableForBattleground = false,
			enableForArena = false,
			enableForParty = true,
			enableForRaid = true,
			enableForLFG = false,

			classColor = true,
			icons = true,
			groupOnly = true,
			disableForLFG = true,
			fallback = true,
		}
	})
	oRA:RegisterModuleOptions("Alerts", GetOptions)

	-- Enable shift-clicking the line to print in chat.
	hooksecurefunc("SetItemRef", function(link)
		local _, ora, msg = strsplit(":", link, 3)
		if ora == "oRA" and IsShiftKeyDown() then
			msg = msg:gsub("@", "|")
			local editBox = _G.ChatEdit_ChooseBoxForSend()
			_G.ChatEdit_ActivateChat(editBox)
			editBox:SetText(msg)
		end
	end)
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckEnable")

	self:CheckEnable()
end

function module:PLAYER_ENTERING_WORLD()
	petOwnerMap = {} -- clear out the cache every now and again
	UpdatePets()
end

function module:CheckEnable()
	local enable = false
	local _, instanceType = GetInstanceInfo()
	if instanceType == "pvp" then
		enable = self.db.profile.enableForBattleground
	elseif instanceType == "arena" then
		enable = self.db.profile.enableForArena
	elseif instanceType == "party" or instanceType == "scenario" then
		enable = self.db.profile.enableForParty
	elseif instanceType == "raid" then
		enable = self.db.profile.enableForRaid
	elseif instanceType == "none" then
		enable = self.db.profile.enableForWorld
	end
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and not self.db.profile.enableForLFG then
		enable = false
	end

	if enable then
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("GROUP_ROSTER_UPDATE", UpdatePets)
		self:RegisterEvent("UNIT_PET")
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:RegisterEvent("ENCOUNTER_START")
		combatLogHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		UpdatePets()
	else
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:UnregisterEvent("GROUP_ROSTER_UPDATE")
		self:UnregisterEvent("UNIT_PET")
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:UnregisterEvent("ENCOUNTER_START")
		combatLogHandler:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end


---------------------------------------
-- Options

local createAlertSettings do
	local order = 0
	function createAlertSettings(key, name, desc)
		order = order + 1
		if module.db.profile.separateOutputs then
			return {
				type = "group",
				--name = name,
				name = "", -- side effect of a blank inline group name is no border? i'll take it
				inline = true,
				order = order,
				args = {
					enable = {
						type = "toggle",
						name = name,
						desc = desc,
						get = function(info) return module.db.profile[key] end,
						set = function(info, value) module.db.profile[key] = value end,
						order = 10,
					},
					outputSelect = {
						type = "select",
						name = L["Output"],
						desc = L["Set where the alert output is sent."],
						values = outputValuesWithChannels,
						get = function(info) return module.db.profile.outputs[key] or module.db.profile.output end,
						set = function(info, value) module.db.profile.outputs[key] = value:lower() end,
						disabled = function() return not module.db.profile[key] end,
						order = 20,
					},
				},
			}
		else
			return {
				type = "toggle",
				name = name,
				desc = desc,
				get = function(info) return module.db.profile[key] end,
				set = function(info, value) module.db.profile[key] = value end,
				order = order,
			}
		end
	end
end

function GetOptions()
	local self = module

	wipe(outputValuesWithChannels)
	for k,v in next, outputValues do
		outputValuesWithChannels[k] = v
	end
	for i = 1, GetNumDisplayChannels() do
		local name, _, _, index, _, _, category = GetChannelDisplayInfo(i)
		if index and category == "CHANNEL_CATEGORY_CUSTOM" then
			outputValuesWithChannels["c"..index] = ("/%d %s"):format(index, name)
		end
	end
	for i = 1, _G.NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		local _, _, _, _, _, _, shown = _G.GetChatWindowInfo(i)
		if frame ~= _G.COMBATLOG and (shown or frame.isDocked) then
			local key = frame == _G.DEFAULT_CHAT_FRAME and "self" or "t"..i
			outputValuesWithChannels[key] = L["ChatFrame: %s"]:format(frame.name)
		end
	end

	local options = {
		name = L["Alerts"],
		type = "group",
		childGroups = "tab",
		get = function(info) return self.db.profile[info[#info]] end,
		set = function(info, value) self.db.profile[info[#info]] = value end,
		args = {

			general = {
				name = _G.GENERAL,
				type = "group",
				order = 1,
				args = {

					enabledZones = {
						order = 10,
						type = "group",
						inline = true,
						name = L["Enabled Zones"],
						--desc = L["Select the type of zones that have alerts enabled."],
						set = function(info, value)
							self.db.profile[info[#info]] = value
							self:CheckEnable()
						end,
						args = {
							enableForWorld = {
								order = 1,
								type = "toggle",
								name = _G.CHANNEL_CATEGORY_WORLD,
								desc = L["Enable alerts while in the open world."],
							},
							enableForBattleground = {
								order = 2,
								type = "toggle",
								name = _G.BATTLEFIELDS,
								desc = L["Enable alerts while in a battleground."],
							},
							enableForArena = {
								order = 3,
								type = "toggle",
								name = _G.ARENA,
								desc = L["Enable alerts while in an arena."],
							},
							enableForParty = {
								order = 4,
								type = "toggle",
								name = _G.PARTY,
								desc = L["Enable alerts while in a party instance."],
							},
							enableForRaid = {
								order = 5,
								type = "toggle",
								name = _G.RAID,
								desc = L["Enable alerts while in a raid instance."],
							},
							enableForLFG = {
								order = 6,
								type = "toggle",
								name = _G.LFG_TITLE,
								desc = L["Enable alerts while in a looking for group instance."],
							},
						},
					},

					output = {
						order = 20,
						type = "group",
						inline = true,
						name = L["Output"],
						args = {
							output = {
								name = L["Default Output"],
								desc = L["Set where the alert output is sent if not set individually."],
								type = "select",
								values = outputValuesWithChannels,
								get = function(info) return self.db.profile.output end,
								set = function(info, value)
									self.db.profile.output = value:lower()
								end,
								order = 1,
							},
							separateOutputs = {
								name = L["Separate Outputs"],
								desc = L["Allow setting the output on a per-alert basis"],
								type = "toggle",
								order = 2
							},
							reset = {
								name = L["Reset Outputs"],
								desc = L["Reset all individual alert outputs to use the default output."],
								type = "execute",
								func = function() wipe(self.db.profile.outputs) end,
								disabled = function() return not self.db.profile.separateOutputs end,
								order = 3,
							},
						},
					},

					classColor = {
						name = L["Use Class Colors"],
						desc = L["Use class colored names for people in your group instead of using source/target colors."],
						type = "toggle",
						order = 41,
					},
					icons = {
						name = L["Use Raid Target Icons"],
						desc = L["Show associated raid target icons as part of the alert."],
						type = "toggle",
						order = 42,
					},
					groupOnly = {
						name = L["Group Only"],
						desc = L["Only report events from players in your group."],
						type = "toggle",
						order = 43,
					},
					disableForLFG = {
						name = L["No Spam in LFG"],
						desc = L["Don't send alerts to chat in looking for group instances."],
						type = "toggle",
						disabled = function() return not self.db.profile.enableForLFG end,
						order = 44,
					},
					fallback = {
						name = L["Fallback Output to Self"],
						desc = L["Print to the chat window if unable to send to the specified output."],
						type = "toggle",
						order = 45,
					},
					clickNote = {
						name = "\n"..L["Tip: Shift-click \"oRA3\" in chat to copy the line into the chat edit box so you can easily send the message to your group!"],
						type = "description",
						fontSize = "medium",
						order = 60,
					},

				},
			},

			combatAlerts = {
				name = L["Combat Alerts"],
				desc = L["Set what is reported to chat."],
				type = "group",
				order = 2,
				args = {
					crowdControl = createAlertSettings("crowdControl", L["Crowd Control"], L["Report when a player breaks a crowd control effect."]),
					misdirect = createAlertSettings("misdirect", L["Misdirects"], L["Report who gains Misdirection."]),
					taunt = createAlertSettings("taunt", L["Taunts"], L["Report taunts."]),
					tauntPet = createAlertSettings("tauntPet", L["Pet Taunts"], L["Report pet taunts."]),
					interrupt = createAlertSettings("interrupt", L["Interrupts"], L["Report interrupts."]),
					interruptMiss = createAlertSettings("interruptMiss", L["Missed Interrupts"], L["Report missed interrupts."]),
					dispel = createAlertSettings("dispel", L["Dispels"], L["Report dispels and Spellsteal."]),
					combatRes = createAlertSettings("combatRes", L["Combat Resurrections"], L["Report combat resurrections."]),
					bloodlust = createAlertSettings("bloodlust", L["Bloodlust"], L["Report Bloodlust casts."]),
					pulled = createAlertSettings("pulled", L["Started Encounter"], L["Report the first person to go into combat when starting a boss encounter."]),
				},
			},

			noncombatAlerts = {
				name = L["Noncombat Alerts"],
				desc = L["Set what is reported to chat."],
				type = "group",
				order = 3,
				args = {
					feast = createAlertSettings("feast", L["Consumables"], L["Report when a player uses a feast."]),
					repair = createAlertSettings("repair", L["Repair Bots"], L["Report when a player uses a repair bot."]),
					portal = createAlertSettings("portal", L["Portals"], L["Report when a Mage opens a portal."]),
					summon = createAlertSettings("summon", L["Rituals"], L["Report when a player needs assistance summoning an object."]),
					resurrect = createAlertSettings("resurrect", L["Resurrections"], L["Report resurrections."]),
					codex = createAlertSettings("codex", L["Codex"], L["Report when a player uses a Codex of the Tranquil Mind."]),
				},
			},

		},
	}
	return options
end
