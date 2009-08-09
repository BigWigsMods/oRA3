local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "zhTW")
if not L then return end

-- Generic
L["Name"] = "名稱"
L["Checks"] = "狀態檢查"
L["Disband Group"] = "解散團隊"
L["Options"] = "選項"
L["<oRA3> Disbanding group."] = "<oRA3>正在解散團隊"
L["Click to open/close oRA3"] = "打開/關閉 oRA3"
L["Unknown"] = "未知"
-- Core
L["You can configure some options here. All the actual actions are done from the panel at the RaidFrame."] = "你可以在這做一些設定。所有的實際動作從團隊框架面板中完成。"

-- Ready check module
L["The following players are not ready: %s"] = "下列隊員未準備好:%s"
L["Ready check over in %d seconds"] = "就位確認還有%d秒結束"
L["Ready"] = "準備好"
L["Not Ready"] = "未準備好"
L["No Response"] = "未確認"
L["Offline"] = "離線"
L["Play a sound when a ready check is performed."] = "準備確認時播放音效。"
L["GUI"] = "面板"
L["Show the oRA3 Ready Check GUI when a ready check is performed."] = "準備確認時顯示oRA3準備確認面板。"
L["Auto Hide"] = "自動隱藏"
L["Automatically hide the oRA3 Ready Check GUI when a ready check is finished."] = "準備確認完成時自動隱藏oRA3準備確認面板。"

-- Durability module
L["Durability"] = "耐久度"
L["Average"] = "平均"
L["Broken"] = "損壞"
L["Minimum"] = "最少"

-- Resistances module
L["Resistances"] = "抗性"
L["Frost"] = "冰霜"
L["Fire"] = "火焰"
L["Shadow"] = "暗影"
L["Nature"] = "自然"
L["Arcane"] = "秘法"

-- Resurrection module
L["%s is ressing %s."] = "%s正在復活%s"

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

-- Promote module
L["Promote"] = "自動提升"
L["Mass promotion"] = "批量提升"
L["Everyone"] = "所有人"
L["Promote everyone automatically."] = "自動提升所有人"
L["Guild"] = "公會"
L["Promote all guild members automatically."] = "自動提升團隊中的公會成員"
L["By guild rank"] = "根據階級"
L["Individual promotions"] = "單獨提升"
L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."] = "注意，玩家名字區分大小寫。要新增玩家,在輸入框輸入玩家名稱按下Enter或是點擊彈出的按鈕。在下拉列表中選中一個玩家就可以刪除該玩家的自動提升。"
L["Add"] = "增加"
L["Remove"] = "刪除"

-- Cooldowns module
L["Cooldowns"] = "冷卻監視"
L["Monitor settings"] = "監視器設定"
L["Show monitor"] = "顯示"
L["Lock monitor"] = "鎖定"
L["Show or hide the cooldown bar display in the game world."] = "是否顯示冷卻監視器"
L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."] = "鎖定後將隱藏監視器的標題並將無法拖曳，設定大小，打開設定。"
L["Only show my own spells"] = "只顯示我的法術冷卻"
L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."] = "是否只顯示你自己施放的法術的冷卻，這將是一個普通的法術冷卻插件。"
L["Cooldown settings"] = "冷卻選項"
L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."] = "通過下拉列表選擇你想要監視的技能冷卻。每個職業都有一套可用的監視的技能冷卻列表，根據需要取捨。"
L["Select class"] = "選擇職業"
L["Never show my own spells"] = "從不顯示我的法術"
L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."] = "是否顯示你的法術冷卻。來說如果你使用其它插件來顯示你的冷卻。"
-- monitor
L["Right-Click me for options!"] = "右鍵點擊設定"
L["Bar Settings"] = "計時條設定"
L["Spawn test bar"] = "顯示測試計時條"
L["Use class color"] = "使用職業顏色"
L["Height"] = "高"
L["Scale"] = "縮放"
L["Texture"] = "材質"
L["Icon"] = "圖示"
L["Show"] = "顯示"
L["Duration"] = "時間"
L["Unit name"] = "名字"
L["Spell name"] = "技能"
L["Short Spell name"] = "技能縮寫"
L["Label Align"] = "標記對齊"
L["Left"] = "左"
L["Right"] = "右"
L["Center"] = "中"

-- Zone module
L["Zone"] = "區域"

-- Version module
L["Version"] = "版本"

-- Loot module
L["Leave empty to make yourself Master Looter."] = "留空使自己分配戰利品。"
