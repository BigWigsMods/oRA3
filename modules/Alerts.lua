
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

local combatLogHandler = CreateFrame("Frame")
local GetOptions

local LE_PARTY_CATEGORY_INSTANCE = _G.LE_PARTY_CATEGORY_INSTANCE
local bit_band, bit_bor = bit.band, bit.bor
local tconcat = table.concat

local outputValues = { -- channel list
	["self"] = L["Self"],
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

local FULL_PLAYER_NAME = _G.FULL_PLAYER_NAME
local UNKNOWN = ("(%s)"):format(_G.UNKNOWN)
local soulstoneList = {}

local combatLogMap = {}
combatLogMap.SPELL_CAST_START = {
	-- Feasts
	[160740] = "Feast", -- Feast of Blood (+75)
	[160914] = "Feast", -- Feast of the Waters (+75)
	[175215] = "Feast", -- Savage Feast (+100)
}
combatLogMap.SPELL_CAST_SUCCESS = {
	-- Repair Bots
	[22700] = "Repair",  -- Field Repair Bot 74A
	[44389] = "Repair",  -- Field Repair Bot 110G
	[54711] = "Repair",  -- Scrapbot
	[67826] = "Repair",  -- Jeeves
	[157066] = "Repair", -- Walter
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
	-- Mass Resurrection
	[212056] = "MassResurrection", -- Absolution (Paladin)
	[212048] = "MassResurrection", -- Ancestral Vision (Shaman)
	[212036] = "MassResurrection", -- Mass Resurrection (Priest)
	[212051] = "MassResurrection", -- Reawaken (Monk)
	[212040] = "MassResurrection", -- Revitalize (Druid)
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
	[185245] = "Taunt", -- Torment (Demon Hunter)
	-- Pet Taunts
	[17735] = "TauntPet",   -- Suffering (Warlock Pet)
	[2649] = "TauntPet",    -- Growl (Hunter Pet)
	[196727] = "TauntMiss", -- Provoke (Niuzao, Monk Pet)
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
	[176248] = "Portal", -- Stormshield
	[176242] = "Portal", -- Warspear
	[120146] = "Portal", -- Dalaran (Crater)
	[224871] = "Portal", -- Dalaran (Broken Isles)

	-- Instant Rituals
	[29893] = "Feast", -- Create Soulwell (Warlock)
	[43987] = "Feast", -- Conjure Refreshment Table (Mage)
}
combatLogMap.SPELL_RESURRECT = {
	["*"] = "Resurrect",
	-- Combat Res
	[20484] = "CombatResurrect",  -- Rebirth (Druid)
	[61999] = "CombatResurrect",  -- Raise Ally (Death Knight)
	[95750] = "CombatResurrect",  -- Soulstone Resurrection (Warlock)
	[126393] = "CombatResurrect", -- Eternal Guardian (Hunter Quilen Pet)
	[159931] = "CombatResurrect", -- Dust to Life (Hunter Moth Pet)
	[159956] = "CombatResurrect", -- Gift of Chi-Ji (Hunter Crane Pet)
}
combatLogMap.SPELL_AURA_REMOVED = {
	[20707] = "Soulstone",  --  Buff removed on death
}
combatLogMap.SPELL_DISPEL = {
	["*"] = "Dispel",
	[32375] = "MassDispel", -- friendly dispel? (the main spell id, next two trigger off it)
	[39897] = "MassDispel", -- offensive dispel?
	[32592] = "MassDispel", -- why are there so many ids?!
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
-- Used to map guardians to their owners.
combatLogMap.SPELL_SUMMON = {
	["*"] = "AssignOwner",
	-- [42651]  = "AssignOwner", -- Army of the Dead (Death Knight)
	-- [192222] = "AssignOwner", -- Liquid Magma Totem (Shaman)
	-- [188592] = "AssignOwner", -- Fire Elemental (Shaman)
	-- [157299] = "AssignOwner", -- Storm Elemental (Shaman)
	-- [60478] = "AssignOwner",  -- Summon Doonguard (Warlock)
	-- [111685] = "AssignOwner", -- Summon Infernal (Warlock)
	-- [132578] = "AssignOwner", -- Invoke Niuzao, the Black Ox (Monk)
}

-- cache pet owner names
local petOwnerMap = {}

function module:Spam(key, msg)
	if not msg or msg == "" then return end
	if not self.db.profile[key] then return end

	local output = (self.db.profile.outputs[key] or self.db.profile.output):lower()
	local fallback = nil

	local isInstanceGroup = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)

	local chatMsg = msg:gsub("|Hicon:%d+:dest|h|TInterface.TargetingFrame.UI%-RaidTargetingIcon_(%d).blp:0|t|h", "{rt%1}") -- replace icon textures
	chatMsg = chatMsg:gsub("|Hplayer:.-|h%[(.-)%]|h", "%1") -- remove player links
	chatMsg = chatMsg:gsub("|c%x%x%x%x%x%x%x%x([^%|].-)|r", "%1") -- remove color

	if not IsInGroup() then
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
	elseif not outputValues[output] then
		local index = GetChannelName(output:sub(2))
		if index > 0 then
			SendChatMessage(chatMsg, "CHANNEL", nil, index)
		else
			fallback = true
		end
	end

	if output == "self" or (self.db.profile.fallback and fallback) then
		print(("|Hora:%s|h|cff33ff99oRA3|r|h: %s"):format(chatMsg:gsub("|", "@"), msg))
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


local UpdatePets
do -- COMBAT_LOG_EVENT_UNFILTERED
	function module:UNIT_PET(unit)
		local pet = UnitGUID(unit .. "pet")
		if pet then
			local name, server = UnitName(unit)
			if server and server ~= "" then
				name = FULL_PLAYER_NAME:format(name, server)
			end
			petOwnerMap[pet] = name
		end
	end

	function UpdatePets()
		for unit in oRA:IterateGroup() do
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

	local function getName(name, guid)
		local petOwner = petOwnerMap[guid]
		if petOwner then
			petOwner = module.db.profile.playerLink and ("|Hplayer:%s|h[%s]|h"):format(petOwner, petOwner:gsub("%-.*", "")) or petOwner:gsub("%-.*", "")
			return L["%s's %s"]:format(petOwner, name or UNKNOWN)
		elseif name and UnitIsPlayer(name) then
			return module.db.profile.playerLink and ("|Hplayer:%s|h[%s]|h"):format(name, name:gsub("%-.*", "")) or name:gsub("%-.*", "")
		end
		return name or UNKNOWN
	end

	local extraUnits = {"target", "focus", "focustarget", "mouseover", "boss1", "boss2", "boss3", "boss4", "boss5"}
	local function getUnit(guid)
		for _, unit in ipairs(extraUnits) do
			if UnitGUID(unit) == guid then return unit end
		end

		for unit in oRA:IterateGroup() do
			local target = ("%starget"):format(unit)
			if UnitGUID(target) == guid then return target end
		end
	end

	-- stuff I pulled out of my fork of Deadened (Antiarc probably did most of the immunity coding, pretty old stuff)
	local immunities = {
		[(GetSpellInfo(642))] = true, -- Divine Shield
		[(GetSpellInfo(710))] = true, -- Banish
		[(GetSpellInfo(1022))] = true, -- Blessing of Protection
		[(GetSpellInfo(204018))] = true, -- Blessing of Spellwarding
		[(GetSpellInfo(33786))] = true, -- Cyclone (PvP)
		[(GetSpellInfo(45438))] = true, -- Ice Block
		[(GetSpellInfo(217832))] = true, -- Imprision (PvP)
	}
	local function getMissReason(unit)
		for immunity in next, immunities do
			local name, _, _, _, _, _, expires = UnitBuff(unit, immunity)
			if name then
				expires = expires and tonumber(("%.1f"):format(expires - GetTime())) or 0
				if expires < 1 then expires = nil end
				return name, expires
			end
		end
	end

	-- aaand where all the magic happens
	local FILTER_GROUP = bit_bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
	combatLogHandler:SetScript("OnEvent", function(self, _, _, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, spellId, spellName, _, extraSpellId, extraSpellName)
		-- first check if someone died
		if event == "UNIT_DIED" or event == "UNIT_DESTROYED" then
			if soulstoneList[dstName] then
				soulstoneList[dstName] = GetTime() + 60 -- if you hold onto it for more than a minute...prolly don't care
			end
			petOwnerMap[dstGUID] = nil -- army (DIED), totems (DESTROYED)
			return
		end

		local e = combatLogMap[event]
		local handler = e and (e[spellId] or e["*"])
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
			elseif handler == "Interrupt" then
				-- ignore players getting interrupted
				if bit_band(dstFlags, FILTER_GROUP) ~= 0 then
					return
				end
			elseif handler == "InterruptCast" then -- not casting alert
				local unit = getUnit(dstGUID)
				if not unit or UnitCastingInfo(unit) then return end
			elseif handler == "InterruptMiss" and extraSpellId == "IMMUNE" then
				local unit = getUnit(dstGUID)
				if not unit or not UnitCastingInfo(unit) then return end -- don't care if the mob is immune if it's not casting
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

			-- format output strings
			local srcOutput = ("%s|cff40ff40%s|r"):format(getIconString(srcRaidFlags), getName(srcName, srcGUID))
			local dstOutput = ("%s|cffff4040%s|r"):format(getIconString(dstRaidFlags), getName(dstName, dstGUID))
			local spellOutput = module.db.profile.spellLink and GetSpellLink(spellId) or ("|cff71d5ff%s|r"):format(spellName)
			local extraSpellOuput
			if tonumber(extraSpellId) then -- kind of hacky, pretty print the extra spell for interrupts/breaks/dispels
				extraSpellOuput = module.db.profile.spellLink and GetSpellLink(extraSpellId) or ("|cff71d5ff%s|r"):format(extraSpellName)
			elseif (extraSpellId ~= "BUFF" and extraSpellId ~= "DEBUFF") then
				extraSpellOuput = extraSpellId
			end

			-- execute!
			return module[handler](module, srcOutput, dstOutput, spellOutput, extraSpellOuput)
		end

	end)
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

function module:TauntMiss(srcOutput, dstOutput, spellOutput, extraSpell)
	self:Spam("taunt", L["%s missed %s on %s (%s)"]:format(srcOutput, spellOutput, dstOutput, _G["ACTION_SPELL_MISSED_"..extraSpell]))
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
	self:Spam("interrupt", L["%s missed %s on %s (%s)"]:format(srcOutput, spellOutput, dstOutput, L["Not casting"]))
end

function module:InterruptMiss(srcOutput, dstOutput, spellOutput, extraSpell)
	self:Spam("interrupt", L["%s missed %s on %s (%s)"]:format(srcOutput, spellOutput, dstOutput, _G["ACTION_SPELL_MISSED_"..extraSpell]))
end

function module:InterruptImmune(srcOutput, dstOutput, spellOutput, extraSpell)
	self:Spam("interrupt", L["%s missed %s on %s (%s)"]:format(srcOutput, spellOutput, dstOutput, extraSpell))
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

do
	--- Soulstone
	-- Kind of convoluted x.x When someone losses a Soulstone buff, :Soulstone
	-- gets called and we set an initial entry to check for their death since we
	-- don't know if it just wore off normally. If UNIT_DIED fires before our
	-- "buffer" entry expires, we update the entry with a 60s expiry. If that
	-- player becomes alive (not UnitIsDead) in that time period, we report
	-- them as having used the Soulstone!

	local spiritOfRedemption = GetSpellInfo(27827)
	local feignDeath = GetSpellInfo(5384)

	local soulstoneLink, soulstone = (GetSpellLink(20707)), ("|cff71d5ff%s|r"):format((GetSpellInfo(20707)))

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
				elseif not UnitIsDead(name) and UnitIsConnected(name) and not UnitIsFeignDeath(name) and not UnitBuff(name, feignDeath) and not UnitBuff(name, spiritOfRedemption) then
					soulstoneList[name] = nil
					name = module.db.profile.playerLink and ("|Hplayer:%s|h[%s]|h"):format(name, name:gsub("%-.*", "")) or name:gsub("%-.*", "")
					local srcOutput = ("|cff40ff40%s|r"):format(name)
					local spellOutput = module.db.profile.spellLink and soulstoneLink or soulstone
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
-- Init

function module:OnRegister()
	self.db = oRA.db:RegisterNamespace("Alerts", {
		profile = {
			crowdControl = true,
			misdirect = true,
			taunt = false,
			tauntPet = false,
			interrupt = false,
			dispel = false,
			combatRes = true,
			portal = true,
			repair = true,
			feast = true,
			summon = true,
			resurrect = false,

			output = "self",
			separateOutputs = false,
			outputs = {},

			enableForWorld = false,
			enableForBattleground = false,
			enableForArena = false,
			enableForParty = true,
			enableForRaid = true,
			enableForLFG = false,

			playerLink = false,
			spellLink = true,
			icons = true,
			groupOnly = true,
			disableForLFG = true,
			fallback = true,
		}
	})
	oRA:RegisterModuleOptions("Alerts", GetOptions)

	-- Enable shift-clicking the line to print in chat. Raw hooked because
	-- otherwise SetItemRef will also fire on other |H's in the message.
	local orig_SetItemRef = SetItemRef
	SetItemRef = function(link, ...)
		if strsub(link, 1, 3) ~= "ora" then
			return orig_SetItemRef(link, ...)
		end
		if not IsShiftKeyDown() then return end

		local _, msg = strsplit(":", link, 2)
		msg = msg:gsub("@", "|")
		local editBox = _G.ChatEdit_ChooseBoxForSend()
		if editBox:IsShown() and editBox:GetText() ~= "" then
			editBox:Insert(" "..msg)
		else
			_G.ChatEdit_ActivateChat(editBox)
			editBox:SetText(msg)
		end
	end
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckEnable")
	self:RegisterEvent("CHANNEL_UI_UPDATE", "UpdateChatChannels")

	self:CheckEnable()
end

function module:PLAYER_ENTERING_WORLD()
	wipe(petOwnerMap) -- clear out the cache every now and again
	self:UpdateChatChannels()
	self:CheckEnable()
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
		combatLogHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		UpdatePets()
	else
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:UnregisterEvent("GROUP_ROSTER_UPDATE")
		self:UnregisterEvent("UNIT_PET")
		combatLogHandler:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end


---------------------------------------
-- Options

do
	local channels = {}
	local function updateChannels()
		wipe(channels)
		for i = 1, GetNumDisplayChannels() do
			local name, _, _, _, _, _, category = GetChannelDisplayInfo(i)
			if category == "CHANNEL_CATEGORY_CUSTOM" then
				channels[name] = name
			end
		end
	end

	function module:GetChatChannels()
		return channels
	end

	function module:UpdateChatChannels()
		updateChannels()
		LibStub("AceConfigRegistry-3.0"):NotifyChange("oRA3")
	end
end

local function createAlertSettings(alertKey, alertName, alertDescription, alertOrder)
	if module.db.profile.separateOutputs then
		return {
			--name = alertName,
			name = "", -- side effect of a blank inline group name is no border? i'll take it
			type = "group",
			inline = true,
			order = alertOrder,
			args = {
				enable = {
					name = alertName,
					desc = alertDescription,
					type = "toggle",
					get = function(info) return module.db.profile[alertKey] end,
					set = function(info, value) module.db.profile[alertKey] = value end,
					order = 10,
				},
				outputSelect = {
					name = L["Output"],
					desc = L["Set where the alert output is sent."],
					type = "select",
					values = outputValuesWithChannels,
					get = function(info) return module.db.profile.outputs[alertKey] or module.db.profile.output end,
					set = function(info, value) module.db.profile.outputs[alertKey] = value:lower() end,
					disabled = function() return not module.db.profile[alertKey] end,
					order = 20,
				},
			},
		}
	else
		return {
			type = "toggle",
			name = alertName,
			desc = alertDescription,
			get = function(info) return module.db.profile[alertKey] end,
			set = function(info, value) module.db.profile[alertKey] = value end,
			order = alertOrder,
		}
	end
end

function GetOptions()
	local self = module
	wipe(outputValuesWithChannels)
	for k,v in next, outputValues do
		outputValuesWithChannels[k] = v
	end
	for k in next, self:GetChatChannels() do
		local index, name = GetChannelName(k)
		outputValuesWithChannels["c"..k] = ("/%d %s"):format(index, name)
		--outputValuesWithChannels["c"..k] = "Channel: "..k
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

					spellLink = {
						name = L["Use Spell Links"],
						desc = L["Display spell names as clickable spell links."],
						type = "toggle",
						order = 40,
					},
					playerLink = {
						name = L["Use Player Links"],
						desc = L["Display player names as clickable player links."],
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

				},
			},

			combatAlerts = {
				name = L["Combat Alerts"],
				desc = L["Set what is reported to chat."],
				type = "group",
				order = 2,
				args = {
					crowdControl = createAlertSettings("crowdControl", L["Crowd Control"], L["Report when a player breaks a crowd control effect."], 1),
					misdirect = createAlertSettings("misdirect", L["Misdirects"], L["Report who gains Misdirection."], 2),
					taunt = createAlertSettings("taunt", L["Taunts"], L["Report taunts."], 3),
					tauntPet = createAlertSettings("tauntPet", L["Pet Taunts"], L["Report pet taunts."], 4),
					interrupt = createAlertSettings("interrupt", L["Interrupts"], L["Report interrupts."], 5),
					dispel = createAlertSettings("dispel", L["Dispels"], L["Report dispels and Spellsteal."], 6),
					combatRes = createAlertSettings("combatRes", L["Combat Resurrections"], L["Report combat resurrections."], 7),
				},
			},

			noncombatAlerts = {
				name = L["Noncombat Alerts"],
				desc = L["Set what is reported to chat."],
				type = "group",
				order = 3,
				args = {
					feast = createAlertSettings("feast", L["Consumables"], L["Report when a player uses a feast."], 1),
					repair = createAlertSettings("repair", L["Repair Bots"], L["Report when a player uses a repair bot."], 2),
					portal = createAlertSettings("portal", L["Portals"], L["Report when a Mage opens a portal."], 3),
					summon = createAlertSettings("summon", L["Rituals"], L["Report when a player needs assistance summoning an object."], 4),
					resurrect = createAlertSettings("resurrect", L["Resurrections"], L["Report resurrections."], 5),
				},
			},

		},
	}
	return options
end
