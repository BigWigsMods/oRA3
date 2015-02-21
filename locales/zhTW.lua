
if GetLocale() ~= "zhTW" then return end
local _, tbl = ...
local L = tbl.locale

-- Generic
L.name = "名稱"
L.checks = "檢查"
L.disbandGroup = "解散團隊"
L.disbandGroupDesc = "解散你現在的隊伍或團隊，從團隊中逐一踢除每一個人，直到剩下你一個。\n\n由於這非常具有破壞性，你會看到一個確認對話框。按住控制隱藏此對話框。"
L.options = "設定"
L.disbandingGroupChatMsg = "正在解散團隊"
L.disbandGroupWarning = "你確定要解散團隊?"
L.unknown = "未知"
L.profile = "設定檔"

-- Core

L.togglePane = "切換oRA3面板"
L.toggleWithRaid = "跟著團隊面板開啟"
L.toggleWithRaidDesc = "一起跟著內建團隊面板自動開啟和關閉。如果你禁用這設定，你扔然可以用按鍵綁定或是/命令來開啟oRA3面板,列如|cff44ff44/radur|r。"
L.showHelpTexts = "顯示介面幫助"
L.showHelpTextsDesc = "oRA3介面充滿幫助性的文字來引導將要做什麼做更好的描述以及不同的介面組成事實上在做什麼。禁用這設定將會移除，限制在各面板雜亂的訊息，|cffff4411在某些面板需要重新載入介面。|r"
L.ensureRepair = "為所有在團隊裡出席的階級啟用公會修裝"
L.ensureRepairDesc = "如果你是公會會長，任何時候你加入到團隊且是隊長或是被提升，你可以啟用公會修裝直到團隊結束(最多300g)。萬一你離開團隊，設定就會被還原到原始狀態|cffff4411預防你在團隊期間不會破產。|r"
L.repairEnabled = "啟用%s公會修裝直到團隊結束。"
L.showRoleIcons = "在團隊面板顯示角色圖示"
L.showRoleIconsDesc = "顯示角色圖示與各角色總數在內建團隊面板。妳需要重新開起團隊面板來讓設定生效。"

L.slashCommands = "/指令"
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
L.notReady = "下列隊員未準備好:%s"
L.readyCheckSeconds = "準備確認(%d秒)"
L.ready = "準備好"
L.notReady = "未準備好"
L.noResponse = "未確認"
L.offline = "離線"
L.readyCheckSound = "當準備確認進行中時使用主要聲音頻道播放準備確認音效。即使\"音效\"被禁用也會也會撥放"
L.showWindow = "顯示視窗"
L.showWindowDesc = "當準備確認執行顯示視窗。"
L.hideWhenDone = "完成時隱藏"
L.hideWhenDoneDesc = "當準備確認完成時自動隱藏。"
L.hideReadyPlayers = "隱藏已經準備好的玩家"
L.hideReadyPlayersDesc = "從視窗中隱藏已經準備好的玩家。"
L.hideInCombatDesc = "進入戰鬥時自動隱藏準備視窗"
L.hideInCombat = "戰鬥中隱藏"
L.printToRaid = "發送準備結果到團隊頻道"
L.printToRaidDesc = "如果你被提升，發送準備結果到團隊頻道，讓團隊成員看見有什麼阻塞。請自行確認只有一個人啟用。"

-- Durability module
L.durability = "耐久度"
L.average = "平均"
L.broken = "損壞"
L.minimum = "最少"

-- Invite module
L.invite = "邀請"
L.invitePrintMaxLevel = "公告：公會中所有滿級玩家會被在10秒內被邀請，請保持沒有隊伍！"
L.invitePrintZone = "公告：公會中所有在%s的玩家會被在10秒內被邀請，請保持沒有隊伍！"
L.invitePrintRank = "公告：公會中所有階級在%s以上的玩家會被在10秒內被邀請，請保持沒有隊伍！"
L.invitePrintGroupIsFull = "抱歉，隊伍已滿。"
L.inviteGuildRankDesc = "邀請公會中所有階級在%s以上的玩家"
L.keyword = "關鍵字"
L.inviteDesc = "當玩家密語你關鍵字，將會自動邀請到隊伍。如果你在隊伍並且滿了，將會轉成團隊。當組滿40人關鍵字將會失效。沒設定關鍵字時禁用。"
L.keywordDesc = "當玩家密語你關鍵字，將會自動邀請到隊伍。"
L.guildKeyword = "公會關鍵字"
L.guildKeywordDesc = "任何公會成員密語你關鍵字將會自動邀請到團隊。"
L.inviteGuild = "公會邀請"
L.inviteGuildDesc = "邀請公會中滿級的玩家"
L.inviteZone = "區域邀請"
L.inviteZoneDesc = "邀請在相同區域的公會成員。"
L.guildRankInvites = "階級邀請"
L.guildRankInvitesDesc = "自動邀請階級高於等於所選等級的公會成員，按下該按鈕會自動在公會和幹部頻道發送要求10秒內離隊待組的消息，10秒後自動開始組人。"
L.inviteInRaidOnly = "如果在團隊隊伍只使用關鍵字邀請"

-- Promote module
L.demoteEveryone = "降級所有人"
L.demoteEveryoneDesc = "降級在目前隊伍的所有人"
L.promote = "晉升"
L.massPromotion = "大量晉升"
L.promoteEveryone = "所有人"
L.promoteEveryoneDesc = "自動晉升所有人"
L.promoteGuild = "公會"
L.promoteGuildDesc = "自動晉升所有公會成員"
L.byGuildRank = "根據公會階級"
L.individualPromotions = "單獨晉升"
L.individualPromotionsDesc = "注意，玩家名字區分大小寫。要新增玩家,在輸入框輸入玩家名稱按下Enter或是點擊彈出的按鈕。在下拉列表中選中一個玩家就可以刪除該玩家的自動晉升。"
L.add = "增加"
L.remove = "刪除"

-- Cooldowns module
L.openMonitor = "開啟監視器"
L.monitorSettings = "監視器設定"
L.showMonitor = "顯示監視器"
L.lockMonitor = "鎖定監視器"
L.showMonitorDesc = "在遊戲世界裡顯示或隱藏冷卻條顯示"
L.lockMonitorDesc = "鎖定後將隱藏監視器的標題並將無法拖曳，設定大小，打開設定。"
L.onlyMyOwnSpells = "只顯示我的法術"
L.onlyMyOwnSpellsDesc = "是否只顯示你自己施放的法術的冷卻，這將是一個普通的法術冷卻插件。"
L.cooldownSettings = "冷卻設定"
L.selectClassDesc = "通過下拉列表選擇你想要監視的技能冷卻。每個職業都有一套可用的監視的技能冷卻列表，根據需要取捨。"
L.selectClass = "選擇職業"
L.neverShowOwnSpells = "不顯示我的法術"
L.neverShowOwnSpellsDesc = "是否顯示你的法術冷卻。來說如果你使用其它插件來顯示你的冷卻。"

-- monitor
L.cooldowns = "冷卻"
L.rightClick = "右鍵點擊設定"
L.barSettings = "計時條設定"
L.labelTextSettings = "標籤文字設定"
L.durationTextSettings = "持續時間文字設定"
L.spawnTestBar = "顯示測試計時條"
L.useClassColor = "使用職業顏色"
L.customColor = "自訂顏色"
L.height = "高"
L.scale = "縮放"
L.texture = "材質"
L.icon = "圖示"
L.duration = "時間"
L.unitName = "名字"
L.spellName = "技能"
L.shortSpellName = "技能縮寫"
L.labelAlign = "標記對齊"
L.left = "左"
L.right = "右"
L.center = "中"
L.outline = "輪廓"
L.thick = "粗"
L.thin = "細"
L.growUpwards = "向上遞增"

-- Zone module
L.zone = "區域"

-- Loot module
L.makeLootMaster = "保留空白讓你分配戰利品。"
L.autoLootMethodDesc = "當你進入隊伍或團隊，自動讓oRA3設定捨取模式，下面指定。"
L.autoLootMethod = "加入一個團隊自動設定捨取模式"

-- Tanks module
L.tanks = "坦克"
L.tankTabTopText = "點擊下方列表將其設為坦克. 將鼠標移動到按鈕上可看到操作提示."
L.deleteButtonHelp = "從坦克名單移除。"
L.blizzMainTank = "內建主坦克"
L.tankButtonHelp = "切換是否這坦克應該為內建主坦克。"
L.save = "儲存"
L.saveButtonHelp = "儲存坦克在你個人名單。只要你在團隊裡面有這玩家，他就會被編排作為個人坦克。"
L.whatIsThis = "到底怎麼回事?"
L.tankHelp = "在置頂名單的人是你個人排序的坦克。他們並不分享給團隊，並且任何人可以擁有不同的個人坦克名單。在置底名單點選一個名稱增加他們到你個人坦克名單。\n\n在盾圖示上點擊就會讓那人成為內建主坦克。內建坦克是團隊所有人中所共享並且你必須被晉升來做切換。\n\n在名單出現的坦克基於某些人讓他們成為內建坦克，當他們不再是內建主坦克就會從名單移除。\n\n在這期間使用檢查標記來儲存。下一次團隊裡有那人，他會自動的被設定為個人坦克。"
L.sort = "排序"
L.moveTankUp = "點擊往上移動坦克。"
L.show = "顯示"
L.showButtonHelp = "在你個人的坦克排列中顯示這個坦克. 此項只對本地有效, 不會影響團隊中其他人的配置"

-- Latency Module
L.latency = "延遲"
L.home = "家"
L.world = "世界"

-- Gear Module
L.gear = "裝備"
L.itemLevel = "物品等級"
L.missingGems = "缺少寶石"
L.missingEnchants = "缺少附魔"

-- BattleRes Module
L.battleResTitle = "戰鬥復活監視器"
L.battleResLockDesc = "切換鎖定監視器。這會隱藏標題文字、背景並預防移動。"
L.battleResShowDesc = "切換顯示或隱藏監視器。"

