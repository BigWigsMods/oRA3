local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "zhCN")
if not L then return end

-- Generic
L["Name"] = "oRA3"
L["Checks"] = "状态检查"
L["Disband Group"] = "解散团队"
L["Options"] = "选项"
L["<oRA3> Disbanding group."] = "<oRA3>正在解散团队"
L["Click to open/close oRA3"] = "打开/关闭 oRA3"
L["Unknown"] = "未知"

-- Ready check module
L["The following players are not ready: %s"] = "下列队员未准备好:%s"
L["Ready check over in %d seconds"] = "就位确认还有%d秒结束"
L["Ready"] = "准备好"
L["Not Ready"] = "未准备好"
L["No Response"] = "未确认"
L["Offline"] = "离线"

-- Durability module
L["Durability"] = "耐久度"
L["Average"] = "平均"
L["Broken"] = "损坏"
L["Minimum"] = "最少"

-- Resistances module
L["Resistances"] = "抗性"
L["Frost"] = "冰霜"
L["Fire"] = "火焰"
L["Shadow"] = "暗影"
L["Nature"] = "自然"
L["Arcane"] = "奥术"

-- Resurrection module
L["%s is ressing %s."] = "%s正在复活%s"

-- Invite module
L["Invite"] = "组队邀请"
L["All max level characters will be invited to raid in 10 seconds. Please leave your groups."] = "公告：公会中所有满级玩家会被在10秒内被邀请，请保持没有队伍！"
L["All characters in %s will be invited to raid in 10 seconds. Please leave your groups."] = "公告：公会中所有在%s的玩家会被在10秒内被邀请，请保持没有队伍！"
L["All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups."] = "公告：公会中所有会阶在%s以上的玩家会被在10秒内被邀请，请保持没有队伍！" 
L["<oRA3> Sorry, the group is full."] = "抱歉，队伍已满。"
L["Invite all guild members of rank %s or higher."] = "邀请公会中所有会阶在%s以上的玩家"
L["Keyword"] = "组队关键字"
L["Anyone who whispers you the keyword set below will automatically and immediately be invited to your group. If you're in a party and it's full, you will convert to raid automatically if you are the party leader. The keyword will only stop working when you have a full raid of 40 people. Set the keyword box empty to disable keyword invites."] = "自动邀请对你密语关键字的玩家。如果你处于小队且为队长，当小队满员后自动转为团队。当团队组满40人，组队关键字自动失效。设置组队关键字为空将自动禁用该功能。"
L["Invite guild"] = "公会邀请"
L["Invite everyone in your guild at the maximum level."] = "邀请公会中满级的玩家"
L["Invite zone"] = "地区邀请"
L["Invite everyone in your guild who are in the same zone as you."] = "邀请公会中在指定地区的玩家"
L["Guild rank invites"] = "会阶邀请"
L["Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites."] = "自动邀请会阶高于等于所选等级的工会成员，按下该按钮会自动在工会和官员频道发送要求10秒内离队待组的消息，10秒后自动开始组人"

-- Promote module
L["Promote"] = "自动提升"
L["Mass promotion"] = "批量提升"
L["Everyone"] = "所有人"
L["Promote everyone automatically."] = "自动提升所有人"
L["Guild"] = "公会"
L["Promote all guild members automatically."] = "自动提升团队中的工会玩家"
L["By guild rank"] = "会阶"
L["Individual promotions"] = "单独提升"
L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."] = "注意，玩家名字区分大小写。添加自动提升玩家只需敲入名字后按回车或者旁边的按钮。在下拉列表中选中一个玩家就可以删除该玩家的自动提升。"
L["Add"] = "添加"
L["Remove"] = "删除"

-- Cooldowns module
L["Cooldowns"] = "冷却监视"
L["Monitor settings"] = "监视器设置"
L["Show monitor"] = "显示"
L["Lock monitor"] = "锁定"
L["Show or hide the cooldown bar display in the game world."] = "是否显示冷却监视器"
L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."] = "锁定后将隐藏监视器的标题并将无法拖曳, 设置大小, 打开设置."
L["Only show my own spells"] = "只显示我的法术冷却"
L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."] = "是否只显示你自己释放的法术的冷却, 这将是一个普通的法术冷却插件."
L["Cooldown settings"] = "冷却选项"
L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."] = "通过下拉列表选择你想要监视的技能冷却。每个职业都有一套可用的监视的技能冷却列表，根据需要取舍。"
L["Select class"] = "选择职业"
-- monitor
L["Bar Settings"] = "计时条设置"
L["Spawn test bar"] = "显示测试计时条"
L["Use class color"] = "使用职业颜色"
L["Bar height"] = "计时条高度"
L["Icon"] = "图标"
L["Show"] = "显示"
L["Duration"] = "耐久度"
L["Unit name"] = "名字"
L["Spell name"] = "技能"
L["Short Spell name"] = "技能缩写"

-- Zone module
L["Zone"] = "地区"

-- Version module
L["Version"] = "版本"



