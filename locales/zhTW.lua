local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "zhTW")
if not L then return end

-- Generic
L["Name"] = "名稱"
L["Checks"] = "檢查"
L["Disband Group"] = "解散團隊"
L["Disbands your current party or raid, kicking everyone from your group, one by one, until you are the last one remaining.\n\nSince this is potentially very destructive, you will be presented with a confirmation dialog. Hold down Control to bypass this dialog."] = "解散你現在的隊伍或團隊，從團隊中逐一踢除每一個人，直到剩下你一個。\n\n由於這非常具有破壞性，你會看到一個確認對話框。按住控制隱藏此對話框。"
L["Options"] = "設定"
L["<oRA3> Disbanding group."] = "<oRA3>正在解散團隊"
L["Are you sure you want to disband your group?"] = "你確定要解散團隊?"
L["Unknown"] = "未知"
L["Profile"] = "設定檔"

-- Core

L["Toggle oRA3 Pane"] = "切換oRA3面板"
L["Open with raid pane"] = "跟著團隊面板開啟"
L.toggleWithRaidDesc = "一起跟著內建團隊面板自動開啟和關閉。如果你禁用這設定，你扔然可以用按鍵綁定或是/命令來開啟oRA3面板,列如|cff44ff44/radur|r。"
L["Show interface help"] = "顯示介面幫助"
L.showHelpTextsDesc = "oRA3介面充滿幫助性的文字來引導將要做什麼做更好的描述以及不同的介面組成事實上在做什麼。禁用這設定將會移除，限制在各面板雜亂的訊息，|cffff4411在某些面板需要重新載入介面。|r"
L["Ensure guild repairs are enabled for all ranks present in raid"] = "為所有在團隊裡出席的階級啟用公會修裝"
L.ensureRepairDesc = "如果你是公會會長，任何時候你加入到團隊且是隊長或是被提升，你可以啟用公會修裝直到團隊結束(最多300g)。萬一你離開團隊，設定就會被還原到原始狀態|cffff4411預防你在團隊期間不會破產。|r"
L.repairEnabled = "啟用%s公會修裝直到團隊結束。"
L["Show role icons on raid pane"] = true
L.showRoleIconsDesc = "Show role icons and the total count for each role on the Blizzard raid pane. You will need to reopen the raid pane for changes to this setting to take effect."

L["Slash commands"] = "/指令"
L.slashCommands = [[
oRA3誇示/指令範圍來幫助你在快節奏的團隊中。假如你不再徘迴在舊的CTRA日子，這裡有一些參考。所有/指令有各種速記也有長的，為了方便，更多描述在某些情況會被取代。

|cff44ff44/radur|r - 開啟耐久度列表。
|cff44ff44/ragear|r - 開啟裝備檢查列表。
|cff44ff44/ralag|r - 開始延遲列表。
|cff44ff44/razone|r - 開啟區域列表。
|cff44ff44/radisband|r - 立刻解散團隊，不經過確認。
|cff44ff44/raready|r - 執行準備確認。
|cff44ff44/rainv|r - 邀請所有公會成員。
|cff44ff44/razinv|r - 邀請在相同區域的公會成員。
|cff44ff44/rarinv <階級名稱>|r - 邀請你輸入的公會階級成員。
]]

-- Ready check module
L["The following players are not ready: %s"] = "下列隊員未準備好:%s"
L["Ready Check (%d seconds)"] = "準備確認(%d秒)"
L["Ready"] = "準備好"
L["Not Ready"] = "未準備好"
L["No Response"] = "未確認"
L["Offline"] = "離線"
L["Play the ready check sound using the Master sound channel when a ready check is performed. This will play the sound while \"Sound Effects\" is disabled and at a higher volume."] = "當準備確認進行中時使用主要聲音頻道播放準備確認音效。即使\"音效\"被禁用也會也會撥放"
L["Show window"] = "顯示視窗"
L["Show the window when a ready check is performed."] = "當準備確認執行顯示視窗。"
L["Hide window when done"] = "完成時隱藏"
L["Automatically hide the window when the ready check is finished."] = "當準備確認完成時自動隱藏。"
L["Hide players who are ready"] = "隱藏已經準備好的玩家"
L["Hide players that are marked as ready from the window."] = "從視窗中隱藏已經準備好的玩家。"
L["Automatically hide the ready check window when you get in combat."] = "進入戰鬥時自動隱藏準備視窗"
L["Hide in combat"] = "戰鬥中隱藏"
L["Relay ready check results to raid chat"] = "發送準備結果到團隊頻道"
L["If you are promoted, relay the results of ready checks to the raid chat, allowing raid members to see what the holdup is. Please make sure yourself that only one person has this enabled."] = "如果你被提升，發送準備結果到團隊頻道，讓團隊成員看見有什麼阻塞。請自行確認只有一個人啟用。"

-- Durability module
L["Durability"] = "耐久度"
L["Average"] = "平均"
L["Broken"] = "損壞"
L["Minimum"] = "最少"

-- Invite module
L["Invite"] = "邀請"
L["All max level characters will be invited to raid in 10 seconds. Please leave your groups."] = "公告：公會中所有滿級玩家會被在10秒內被邀請，請保持沒有隊伍！"
L["All characters in %s will be invited to raid in 10 seconds. Please leave your groups."] = "公告：公會中所有在%s的玩家會被在10秒內被邀請，請保持沒有隊伍！"
L["All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups."] = "公告：公會中所有階級在%s以上的玩家會被在10秒內被邀請，請保持沒有隊伍！"
L["<oRA3> Sorry, the group is full."] = "抱歉，隊伍已滿。"
L["Invite all guild members of rank %s or higher."] = "邀請公會中所有階級在%s以上的玩家"
L["Keyword"] = "關鍵字"
L["When people whisper you the keywords below, they will automatically be invited to your group. If you're in a party and it's full, you will convert to a raid group. The keywords will only stop working when you have a full raid of 40 people. Setting a keyword to nothing will disable it."] = "當玩家密語你關鍵字，將會自動邀請到隊伍。如果你在隊伍並且滿了，將會轉成團隊。當組滿40人關鍵字將會失效。沒設定關鍵字時禁用。"
L["Anyone who whispers you this keyword will automatically and immediately be invited to your group."] = "當玩家密語你關鍵字，將會自動邀請到隊伍。"
L["Guild Keyword"] = "公會關鍵字"
L["Any guild member who whispers you this keyword will automatically and immediately be invited to your group."] = "任何公會成員密語你關鍵字將會自動邀請到團隊。"
L["Invite guild"] = "公會邀請"
L["Invite everyone in your guild at the maximum level."] = "邀請公會中滿級的玩家"
L["Invite zone"] = "區域邀請"
L["Invite everyone in your guild who are in the same zone as you."] = "邀請在相同區域的公會成員。"
L["Guild rank invites"] = "階級邀請"
L["Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites."] = "自動邀請階級高於等於所選等級的公會成員，按下該按鈕會自動在公會和幹部頻道發送要求10秒內離隊待組的消息，10秒後自動開始組人。"
L["Only invite on keyword if in a raid group"] = "如果在團隊隊伍只使用關鍵字邀請"

-- Promote module
L["Demote everyone"] = "降級所有人"
L["Demotes everyone in the current group."] = "降級在目前隊伍的所有人"
L["Promote"] = "晉升"
L["Mass promotion"] = "大量晉升"
L["Everyone"] = "所有人"
L["Promote everyone automatically."] = "自動晉升所有人"
L["Guild"] = "公會"
L["Promote all guild members automatically."] = "自動晉升所有公會成員"
L["By guild rank"] = "根據公會階級"
L["Individual promotions"] = "單獨晉升"
L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."] = "注意，玩家名字區分大小寫。要新增玩家,在輸入框輸入玩家名稱按下Enter或是點擊彈出的按鈕。在下拉列表中選中一個玩家就可以刪除該玩家的自動晉升。"
L["Add"] = "增加"
L["Remove"] = "刪除"

-- Cooldowns module
L["Open monitor"] = "開啟監視器"
L["Cooldowns"] = "冷卻監視"
L["Monitor settings"] = "監視器設定"
L["Show monitor"] = "顯示監視器"
L["Lock monitor"] = "鎖定監視器"
L["Show or hide the cooldown bar display in the game world."] = "在遊戲世界裡顯示或隱藏冷卻條顯示"
L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."] = "鎖定後將隱藏監視器的標題並將無法拖曳，設定大小，打開設定。"
L["Only show my own spells"] = "只顯示我的法術"
L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."] = "是否只顯示你自己施放的法術的冷卻，這將是一個普通的法術冷卻插件。"
L["Cooldown settings"] = "冷卻設定"
L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."] = "通過下拉列表選擇你想要監視的技能冷卻。每個職業都有一套可用的監視的技能冷卻列表，根據需要取捨。"
L["Select class"] = "選擇職業"
L["Never show my own spells"] = "不顯示我的法術"
L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."] = "是否顯示你的法術冷卻。來說如果你使用其它插件來顯示你的冷卻。"

-- monitor
L["Cooldowns"] = "冷卻"
L["Right-Click me for options!"] = "右鍵點擊設定"
L["Bar Settings"] = "計時條設定"
L["Text Settings"] = "文字設定"
L["Spawn test bar"] = "顯示測試計時條"
L["Use class color"] = "使用職業顏色"
L["Custom color"] = "自訂顏色"
L["Height"] = "高"
L["Scale"] = "縮放"
L["Texture"] = "材質"
L["Icon"] = "圖示"
L["Show"] = "顯示"
L["Duration"] = "時間"
L["Unit name"] = "名字"
L["Spell name"] = "技能"
L["Short Spell name"] = "技能縮寫"
L["Label Font"] = "標記字型"
L["Label Font Size"] = "標記字型大小"
L["Label Align"] = "標記對齊"
L["Left"] = "左"
L["Right"] = "右"
L["Center"] = "中"
L["Duration Font"] = "時間字型"
L["Duration Font Size"] = "時間字型大小"
L["Grow up"] = "向上遞增"

-- Zone module
L["Zone"] = "區域"

-- Loot module
L["Leave empty to make yourself Master Looter."] = "保留空白讓你分配戰利品。"
L["Let oRA3 to automatically set the loot mode to what you specify below when entering a party or raid."] = "當你進入隊伍或團隊，自動讓oRA3設定捨取模式，下面指定。"
L["Set the loot mode automatically when joining a group"] = "加入一個團隊自動設定捨取模式"

-- Tanks module
L["Tanks"] = "坦克"
L.tankTabTopText = "點擊下方列表將其設為坦克. 將鼠標移動到按鈕上可看到操作提示."
-- L["Remove"] is defined above
L.deleteButtonHelp = "從坦克名單移除。"
L["Blizzard Main Tank"] = "內建主坦克"
L.tankButtonHelp = "切換是否這坦克應該為內建主坦克。"
L["Save"] = "儲存"
L.saveButtonHelp = "儲存坦克在你個人名單。只要你在團隊裡面有這玩家，他就會被編排作為個人坦克。"
L["What is all this?"] = "到底怎麼回事?"
L.tankHelp = "在置頂名單的人是你個人排序的坦克。他們並不分享給團隊，並且任何人可以擁有不同的個人坦克名單。在置底名單點選一個名稱增加他們到你個人坦克名單。\n\n在盾圖示上點擊就會讓那人成為內建主坦克。內建坦克是團隊所有人中所共享並且你必須被晉升來做切換。\n\n在名單出現的坦克基於某些人讓他們成為內建坦克，當他們不再是內建主坦克就會從名單移除。\n\n在這期間使用檢查標記來儲存。下一次團隊裡有那人，他會自動的被設定為個人坦克。"
L["Sort"] = "排序"
L["Click to move this tank up."] = "點擊往上移動坦克。"
L["Show"] = "顯示"
L.showButtonHelp = "在你個人的坦克排列中顯示這個坦克. 此項只對本地有效, 不會影響團隊中其他人的配置"

-- Latency Module
L["Latency"] = "延遲"
L["Home"] = "家"
L["World"] = "世界"

-- Gear Module
L["Gear"] = "裝備"
L["Item Level"] = "物品等級"
L["Missing Gems"] = "缺少寶石"
L["Missing Enchants"] = "缺少附魔"

