local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "enUS", true)

-- Generic
L["Name"] = true
L["Checks"] = true
L["Disband Group"] = true
L["Disbands your current party or raid, kicking everyone from your group, one by one, until you are the last one remaining.\n\nSince this is potentially very destructive, you will be presented with a confirmation dialog. Hold down Control to bypass this dialog."] = true
L["Options"] = true
L["<oRA3> Disbanding group."] = true
L["Are you sure you want to disband your group?"] = true
L["Unknown"] = true
L["Profile"] = true

-- Core

L["Toggle oRA3 Pane"] = true
L["Open with raid pane"] = true
L.toggleWithRaidDesc = "Opens and closes the oRA3 pane automatically along with the Blizzard raid pane. If you disable this option you can still open the oRA3 pane using the keybinding or with one of the slash commands, such as |cff44ff44/radur|r."
L["Show interface help"] = true
L.showHelpTextsDesc = "The oRA3 interface is full of helpful texts intended to better describe what is going on and what the different interface elements actually do. Disabling this option will remove them, limiting the clutter on each pane. |cffff4411Requires a interface reload on some panes.|r"
L["Ensure guild repairs are enabled for all ranks present in raid"] = true
L.ensureRepairDesc = "If you are the Guild Master, whenever you join a raid group and are the leader or promoted, you will ensure that guild repairs are enabled for the duration of the raid (up to 300g). Once you leave the group, the flags will be restored to their original state |cffff4411provided you have not crashed during the raid.|r"
L.repairEnabled = "Enabled guild repairs for %s for the duration of this raid."
L["Show role icons on raid pane"] = true
L.showRoleIconsDesc = "Show role icons and the total count for each role on the Blizzard raid pane. You will need to reopen the raid pane for changes to this setting to take effect."

L["Slash commands"] = true
L.slashCommands = [[
oRA3 sports a range of slash commands to aid you in fast-paced raiding. In case you weren't around in the old CTRA days, here's a little reference. All of the slash commands have various shorthands and also longer, more descriptive alternatives in some cases, for convenience.

|cff44ff44/radur|r - Opens the durability list.
|cff44ff44/ragear|r - Opens the gear check list.
|cff44ff44/ralag|r - Opens the latency list.
|cff44ff44/razone|r - Opens the zone list.
|cff44ff44/radisband|r - Instantly disbands the raid with no verification.
|cff44ff44/raready|r - Performs a ready check.
|cff44ff44/rainv|r - Invites the whole guild to your group.
|cff44ff44/razinv|r - Invites guild members in the same zone as you.
|cff44ff44/rarinv <rank name>|r - Invites guild members of the given rank.
]]

-- Ready check module
L["The following players are not ready: %s"] = true
L["Ready Check (%d seconds)"] = true
L["Ready"] = true
L["Not Ready"] = true
L["No Response"] = true
L["Offline"] = true
L["Play the ready check sound using the Master sound channel when a ready check is performed. This will play the sound while \"Sound Effects\" is disabled and at a higher volume."] = true
L["Show window"] = true
L["Show the window when a ready check is performed."] = true
L["Hide window when done"] = true
L["Automatically hide the window when the ready check is finished."] = true
L["Hide players who are ready"] = true
L["Hide players that are marked as ready from the window."] = true
L["Automatically hide the ready check window when you get in combat."] = true
L["Hide in combat"] = true
L["Relay ready check results to raid chat"] = true
L["If you are promoted, relay the results of ready checks to the raid chat, allowing raid members to see what the holdup is. Please make sure yourself that only one person has this enabled."] = true

-- Durability module
L["Durability"] = true
L["Average"] = true
L["Broken"] = true
L["Minimum"] = true

-- Invite module
L["Invite"] = true
L["All max level characters will be invited to raid in 10 seconds. Please leave your groups."] = true
L["All characters in %s will be invited to raid in 10 seconds. Please leave your groups."] = true
L["All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups."] = true
L["<oRA3> Sorry, the group is full."] = true
L["Invite all guild members of rank %s or higher."] = true
L["Keyword"] = true
L["When people whisper you the keywords below, they will automatically be invited to your group. If you're in a party and it's full, you will convert to a raid group. The keywords will only stop working when you have a full raid of 40 people. Setting a keyword to nothing will disable it."] = true
L["Anyone who whispers you this keyword will automatically and immediately be invited to your group."] = true
L["Guild Keyword"] = true
L["Any guild member who whispers you this keyword will automatically and immediately be invited to your group."] = true
L["Invite guild"] = true
L["Invite everyone in your guild at the maximum level."] = true
L["Invite zone"] = true
L["Invite everyone in your guild who are in the same zone as you."] = true
L["Guild rank invites"] = true
L["Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites."] = true
L["Only invite on keyword if in a raid group"] = true

-- Promote module
L["Demote everyone"] = true
L["Demotes everyone in the current group."] = true
L["Promote"] = true
L["Mass promotion"] = true
L["Everyone"] = true
L["Promote everyone automatically."] = true
L["Guild"] = true
L["Promote all guild members automatically."] = true
L["By guild rank"] = true
L["Individual promotions"] = true
L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."] = true
L["Add"] = true
L["Remove"] = true

-- Cooldowns module
L["Open monitor"] = true
L["Cooldowns"] = true
L["Monitor settings"] = true
L["Show monitor"] = true
L["Lock monitor"] = true
L["Show or hide the cooldown bar display in the game world."] = true
L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."] = true
L["Only show my own spells"] = true
L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."] = true
L["Cooldown settings"] = true
L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."] = true
L["Select class"] = true
L["Never show my own spells"] = true
L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."] = true

-- monitor
L["Cooldowns"] = true
L["Right-Click me for options!"] = true
L["Bar Settings"] = true
L["Label Text Settings"] = true
L["Duration Text Settings"] = true
L["Spawn test bar"] = true
L["Use class color"] = true
L["Custom color"] = true
L["Height"] = true
L["Scale"] = true
L["Texture"] = true
L["Icon"] = true
L["Show"] = true
L["Duration"] = true
L["Unit name"] = true
L["Spell name"] = true
L["Short Spell name"] = true
L["Font"] = true
L["Font Size"] = true
L["Label Align"] = true
L["Left"] = true
L["Right"] = true
L["Center"] = true
L["Outline"] = true
L["Thick"] = true
L["Thin"] = true
L["Grow up"] = true

-- Zone module
L["Zone"] = true

-- Loot module
L["Leave empty to make yourself Master Looter."] = true
L["Let oRA3 to automatically set the loot mode to what you specify below when entering a party or raid."] = true
L["Set the loot mode automatically when joining a group"] = true

-- Tanks module
L["Tanks"] = true
L.tankTabTopText = "Click on players in the bottom list to make them a personal tank. If you want help with all the options here then move your mouse over the question mark."
-- L["Remove"] is defined above
L.deleteButtonHelp = "Remove from the tank list. Please note once removed they will not be re-added for the remainder of this session unless you manually re-add the tank."
L["Blizzard Main Tank"] = true
L.tankButtonHelp = "Toggle whether this tank should be a Blizzard Main Tank."
L["Save"] = true
L.saveButtonHelp = "Saves this tank on your personal list. Any time you are grouped with this player he will be listed as a personal tank."
L["What is all this?"] = true
L.tankHelp = "The people in the top list are your personal sorted tanks. They are not shared with the raid, and everyone can have different personal tank lists. Clicking a name in the bottom list adds them to your personal tank list.\n\nClicking on the shield icon will make that person a Blizzard Main Tank. Blizzard tanks are shared between all members of your raid and you have to be promoted to toggle it.\n\nTanks that appear on the list due to someone else making them a Blizzard Main Tank will be removed from the list when they are no longer a Blizzard Main Tank.\n\nUse the green check mark to save a tank between sessions. The next time you are in a raid with that person, he will automatically be set as a personal tank."
L["Sort"] = true
L["Click to move this tank up."] = true
L["Show"] = true
L.showButtonHelp = "Show this tank in your personal sorted tank display. This option only has effect locally and will not change this tanks status for anyone else in your group."

-- Latency Module
L["Latency"] = true
L["Home"] = true
L["World"] = true

-- Gear Module
L["Gear"] = true
L["Item Level"] = true
L["Missing Gems"] = true
L["Missing Enchants"] = true

