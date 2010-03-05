local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "enUS", true)

-- Generic
L["Name"] = true
L["Checks"] = true
L["Disband Group"] = true
L["Disbands your current party or raid, kicking everyone from your group, one by one, until you are the last one remaining.\n\nSince this is potentially very destructive, you will be presented with a confirmation dialog. Hold down Control to bypass this dialog."] = true
L["Options"] = true
L["<oRA3> Disbanding group."] = true
L["Are you sure you want to disband your group?"] = true
L["Click to open/close oRA3"] = true
L["Unknown"] = true

-- Core
L["You can configure some options here. All the actual actions are done from the panel at the RaidFrame."] = true

-- Ready check module
L["The following players are not ready: %s"] = true
L["Ready Check (%d seconds)"] = true
L["Ready"] = true
L["Not Ready"] = true
L["No Response"] = true
L["Offline"] = true
L["Play a sound when a ready check is performed."] = true
L["GUI"] = true
L["Show the oRA3 Ready Check GUI when a ready check is performed."] = true
L["Auto Hide"] = true
L["Automatically hide the oRA3 Ready Check GUI when a ready check is finished."] = true

-- Durability module
L["Durability"] = true
L["Average"] = true
L["Broken"] = true
L["Minimum"] = true

-- Resistances module
L["Resistances"] = true
L["Frost"] = true
L["Fire"] = true
L["Shadow"] = true
L["Nature"] = true
L["Arcane"] = true

-- Resurrection module
L["%s is ressing %s."] = true

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
L["Spawn test bar"] = true
L["Use class color"] = true
L["Height"] = true
L["Scale"] = true
L["Texture"] = true
L["Icon"] = true
L["Show"] = true
L["Duration"] = true
L["Unit name"] = true
L["Spell name"] = true
L["Short Spell name"] = true
L["Label Align"] = true
L["Left"] = true
L["Right"] = true
L["Center"] = true
L["Grow up"] = true

-- Zone module
L["Zone"] = true

-- Loot module
 L["Leave empty to make yourself Master Looter."] = true
 
-- Tanks module
L["Tanks"] = true
L["Top List: Sorted Tanks. Bottom List: Potential Tanks."] = true
-- L["Remove"] is defined above
L.deleteButtonHelp = "Remove from the tank list."
L["Blizzard Main Tank"] = true
L.tankButtonHelp = "Toggle whether this tank should be a Blizzard Main Tank."
L["Save"] = true
L.saveButtonHelp = "Saves this tank on your personal list. Any time you are grouped with this player he will be listed as a personal tank."
L["What is all this?"] = true
L.tankHelp = "The people in the top list are your personal sorted tanks. They are not shared with the raid, and everyone can have different personal tank lists. Clicking a name in the bottom list adds them to your personal tank list.\n\nClicking on the shield icon will make that person a Blizzard Main Tank. Blizzard tanks are shared between all members of your raid and you have to be promoted to toggle it.\n\nTanks that appear on the list due to someone else making them a Blizzard Main Tank will be removed from the list when they are no longer a Blizzard Main Tank.\n\nUse the check mark to save a tank between sessions. The next time you are in a raid with that person, he will automatically be set as a personal tank."
L["Sort"] = true
L["Click to move this tank up."] = true
L["Hide"] = true
L.hideButtonHelp = "Hide this tank from the tankframes."
