
if GetLocale() ~= "zhCN" then return end
local _, tbl = ...
local L = tbl.locale

-- Generic
L.checks = "检查"
L.disbandGroup = "解散团队"
L.disbandGroupDesc = "解散当前的小队或团队, 会将所有人踢出队伍, 直到只省下你一个人. 由于潜在的危险, 你会看到一个确认框. 按住CTRL跳过确认."
L.options = "选项"
L.disbandingGroupChatMsg = "正在解散团队"
L.disbandGroupWarning = "你确认要解散团队么?"
L.unknown = "未知"

-- Ready check module
L.notReady = "下列队员未准备好:%s"
L.readyCheckSeconds = "就位确认还有%d秒结束"
L.ready = "准备好"
L.notReady = "未准备好"
L.noResponse = "未确认"
L.offline = "离线"

-- Durability module
L.durability = "耐久度"
L.average = "平均"
L.broken = "损坏"
L.minimum = "最少"

-- Invite module
L.invite = "邀请"
L.invitePrintMaxLevel = "公告：公会中所有满级玩家会被在10秒内被邀请，请保持没有队伍！"
L.invitePrintZone = "公告：公会中所有在%s的玩家会被在10秒内被邀请，请保持没有队伍！"
L.invitePrintRank = "公告：公会中所有会阶在%s以上的玩家会被在10秒内被邀请，请保持没有队伍！"
L.invitePrintGroupIsFull = "抱歉，队伍已满。"
L.inviteGuildRankDesc = "邀请公会中所有会阶在%s以上的玩家"
L.keyword = "组队关键字"
L.inviteDesc = "当有人密语以下关键字后, 他将会被自动邀请加入你的队伍. 如果你不在一个小队或队伍已达到上限, 插件将自动转换为团队. 团队满40人后此功能会失效. 留空为禁止"
L.keywordDesc = "任何人密语你这个关键字会被邀请至你的队伍"
L.guildKeyword = "工会关键字"
L.guildKeywordDesc = "任何工会成员密语这个关键字会被邀请至你的队伍"
L.inviteGuild = "公会邀请"
L.inviteGuildDesc = "邀请公会中满级的玩家"
L.inviteZone = "地区邀请"
L.inviteZoneDesc = "邀请公会中在指定地区的玩家"
L.guildRankInvites = "会阶邀请"
L.guildRankInvitesDesc = "自动邀请会阶高于等于所选等级的工会成员，按下该按钮会自动在工会和官员频道发送要求10秒内离队待组的消息，10秒后自动开始组人"

-- Promote module
L.demoteEveryone = "降级所有人"
L.demoteEveryoneDesc = "降级在目前群组的所有人"
L.promote = "提升"
L.massPromotion = "批量提升"
L.promoteEveryone = "所有人"
L.promoteEveryoneDesc = "自动提升所有人"
L.promoteGuild = "公会"
L.promoteGuildDesc = "自动提升团队中的工会玩家"
L.byGuildRank = "会阶"
L.individualPromotions = "单独提升"
L.individualPromotionsDesc = "注意，玩家名字区分大小写。添加自动提升玩家只需敲入名字后按回车或者旁边的按钮。在下拉列表中选中一个玩家就可以删除该玩家的自动提升。"
L.add = "添加"
L.remove = "删除"

-- Cooldowns module
L.monitorSettings = "监视器设置"
L.showMonitor = "显示"
L.lockMonitor = "锁定"
L.showMonitorDesc = "是否显示冷却监视器"
L.lockMonitorDesc = "锁定后将隐藏监视器的标题并将无法拖曳, 设置大小, 打开设置."
L.onlyMyOwnSpells = "只显示我的法术冷却"
L.onlyMyOwnSpellsDesc = "是否只显示你自己释放的法术的冷却, 这将是一个普通的法术冷却插件."
L.cooldownSettings = "冷却选项"
L.selectClassDesc = "通过下拉列表选择你想要监视的技能冷却。每个职业都有一套可用的监视的技能冷却列表，根据需要取舍。"
L.selectClass = "选择职业"
L.neverShowOwnSpells = "不显示我的法术"
L.neverShowOwnSpellsDesc = "冷却显示器将不显示你的法术冷却. 例如你用冷却监视插件时可以勾选本项."

-- monitor
L.cooldowns = "冷却"
L.rightClick = "右键打开设置"
L.barSettings = "计时条设置"
L.spawnTestBar = "显示测试计时条"
L.useClassColor = "使用职业颜色"
L.height = "高度"
L.scale = "缩放"
L.texture = "材质"
L.icon = "图标"
L.duration = "时间"
L.unitName = "名字"
L.spellName = "技能"
L.shortSpellName = "技能缩写"
L.labelAlign = "标签位置"
L.left = "左"
L.right = "右"
L.center = "中间"
L.growUpwards = "向上递增"

-- Zone module
L.zone = "地区"

-- Loot module
 L.makeLootMaster = "留空表示设置你自己为拾取者"

-- Tanks module
L.tanks = "坦克"
L.tankTabTopText = "点击下方列表将其设为坦克. 将鼠标移动到按钮上可看到操作提示."


L.deleteButtonHelp = "从坦克名单移除。"
L.blizzMainTank = "内建主坦克"
L.tankButtonHelp = "切换是否这坦克应该为内建主坦克。"
L.save = "储存"
L.saveButtonHelp = "储存坦克在你个人名单。只要你在团队里面有这玩家，他就会被编排作为个人坦克。"
L.whatIsThis = "到底怎麽回事?"
L.tankHelp = "在置顶名单的人是你个人排序的坦克。他们并不分享给团队，并且任何人可以拥有不同的个人坦克名单。在置底名单点选一个名称增加他们到你个人坦克名单。\n\n在盾图示上点击就会让那人成为内建主坦克。内建坦克是团队所有人中所共享并且你必须被晋升来做切换。\n\n在名单出现的坦克基於某些人让他们成为内建坦克，当他们不再是内建主坦克就会从名单移除。\n\n在这期间使用检查标记来储存。下一次团队里有那人，他会自动的被设定为个人坦克。"
L.sort = "排序"
L.moveTankUp = "点击往上移动坦克。"
L.show = "显示"
L.showButtonHelp = "在你个人的坦克排列中显示这个坦克. 此项只对本地有效, 不会影响团队中其他人的配置"



