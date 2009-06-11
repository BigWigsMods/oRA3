local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "ruRU")
if not L then return end

-- Generic
L["Name"] = "Имя"
L["Checks"] = "Проверка"
L["Disband Group"] = "Распустить группу"
L["Options"] = "Настройки"
L["<oRA3> Disbanding group."] = "<oRA3> группа распущена."
L["Click to open/close oRA3"] = "Кликните чтобы открыть/закрыть oRA3"
L["Unknown"] = "Неизвестно"

L["WARLOCK"] = "Чернокнижник"
L["WARRIOR"] = "Воин"
L["HUNTER"] = "Охотник"
L["MAGE"] = "Маг"
L["PRIEST"] = "Жрец"
L["DRUID"] = "Друид"
L["PALADIN"] = "Паладин"
L["SHAMAN"] = "Шаман"
L["ROGUE"] = "Разбойник"
L["DEATHKNIGHT"] = "Рыцарь смерти"

-- Core
L["You can configure some options here. All the actual actions are done from the panel at the RaidFrame."] = "Вы здесь можете настроить некоторые опции. Все остальные действия выполняются с панели окна рейда."

-- Ready check module
L["The following players are not ready: %s"] = "Следующие игроки не готовы: %s"
L["Ready Check (%d seconds)"] = "Проверка готовности (%d секунд)"
L["Ready"] = "Готов"
L["Not Ready"] = "Не готов"
L["No Response"] = "Нет ответа"
L["Offline"] = "Вышел из сети"
L["Play a sound when a ready check is performed."] = "Проиграть звук при выполнении проверги готовности."
L["GUI"] = "Интерфейс"
L["Show the oRA3 Ready Check GUI when a ready check is performed."] = "Показать интерфейс проверки готовности oRA3 при выполнении проверки."
L["Auto Hide"] = "Авто скрытие"
L["Automatically hide the oRA3 Ready Check GUI when a ready check is finished."] = "Автоматически скрывать интерфейс проверки готовности oRA3 после завершения проверки."

-- Durability module
L["Durability"] = "Прочность"
L["Average"] = "Среднее"
L["Broken"] = "Сломан"
L["Minimum"] = "Минимум"

-- Resistances module
L["Resistances"] = "Сопротивление"
L["Frost"] = "Лёд"
L["Fire"] = "Огонь"
L["Shadow"] = "Тёмная"
L["Nature"] = "Природа"
L["Arcane"] = "Тайная"

-- Resurrection module
L["%s is ressing %s."] = "%s воскрешает |3-3(%s)"

-- Invite module
L["Invite"] = "Пригласить"
L["All max level characters will be invited to raid in 10 seconds. Please leave your groups."] = "Все персонаж максимального уровеня будут приглашены в рейда через 10 секунд. Пожалуйста, выйдите из своих групп."
L["All characters in %s will be invited to raid in 10 seconds. Please leave your groups."] = "Все персонаж в %s будут приглашены в рейда через 10 секунд. Пожалуйста, выйдите из своих групп."
L["All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups."] = "Все персонаж со званием %s и выше, будут приглашены в рейда через 10 секунд. Пожалуйста, выйдите из своих групп."
L["<oRA3> Sorry, the group is full."] = "<oRA3> Ивените, группа уже набрана."
L["Invite all guild members of rank %s or higher."] = "Пригласить всех участников гильдии со званием %s и выше."
L["Keyword"] = "Ключевое слово"
L["When people whisper you the keywords below, they will automatically be invited to your group. If you're in a party and it's full, you will convert to a raid group. The keywords will only stop working when you have a full raid of 40 people. Setting a keyword to nothing will disable it."] = "Когда игрок вам шепнёт ключевое слово приведённое ниже, он будет автоматически приглашен в вашу группу. Если вы находитесь в группе, и она полностью заполнена, вам нужно будет преобразовать её в рейд. Ключевые слова перестанут работать только когда у вас будет полный рейд из 40 человек. Для отключения приглашений, оставьте поле ключевых слов пустым."
L["Anyone who whispers you this keyword will automatically and immediately be invited to your group."] = "Каждый кто шепнёт вам данное ключевое слово будет автоматически и немедленно приглашен в вашу группу\рейд."
L["Guild Keyword"] = "Кл.слово для гильдии"
L["Any guild member who whispers you this keyword will automatically and immediately be invited to your group."] = "Любой участник гильдии, который шепнёт вам данное ключевое слово будет автоматически и немедленно приглашен в вашу группу\рейд."
L["Invite guild"] = "Пригласить гильдию"
L["Invite everyone in your guild at the maximum level."] = "Пригласить всех с вашей гильдии с максимальным уровнем."
L["Invite zone"] = "Пригласить с зоны"
L["Invite everyone in your guild who are in the same zone as you."] = "Пригласить всех с вашей гильдии кто находиться в тойже зоне что и вы."
L["Guild rank invites"] = "Пригласить по рангу гильдии"
L["Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites."] = "При нажатии любой из кнопок ниже, пригласит любого из выбранных званий и выше в вашу группу. К примеру нажав кнопку 3, пригласит всех кто со званием 1, 2 или 3. Изначально будет выведено сообщение в канал гильдии или офицерский канал, что даст членам вашей гильдии 10 секунд, для того чтобы они покинули свои группы, прежде чем вы начнёте приглашать их."

-- Promote module
L["Promote"] = "Произвести"
L["Mass promotion"] = "Масс повышение"
L["Everyone"] = "Всех"
L["Promote everyone automatically."] = "Произвести всех автоматически"
L["Guild"] = "Гильдия"
L["Promote all guild members automatically."] = "Произвести всех участников гильдии автоматически"
L["By guild rank"] = "По рангу гильдии"
L["Individual promotions"] = "Индивидуальное повышение"
L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."] = "Помните, что имена чувствительны к регистру. Чтобы добавить игрока, введите имя игрока в поле ниже и нажмите Enter или нажмите на кнопку, что появиться при вводе. Чтобы удалить игрока из автоматического повышения, нажмите на его имя в раскрывающимся списке ниже."
L["Add"] = "Добавить"
L["Remove"] = "Удалить"

-- Cooldowns module
L["Cooldowns"] = "Перезарядки"
L["Monitor settings"] = "Настройки мониторинга"
L["Show monitor"] = "Показать мониторинг"
L["Lock monitor"] = "Фиксировать мониторинг"
L["Show or hide the cooldown bar display in the game world."] = "Показать или скрыть панель перезарядок в игравом мире."
L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."] = "Помните, что блокировка мониторинга перезарядки скроет заголовок и якорь для перемещения, что сделает его невозможным для перемещения, изменения размера или открытия панели настроек."
L["Only show my own spells"] = "Показывать только мои заклинания"
L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."] = "Переключение отображения перезарядки только для заклинаний применённых вами, в противоположном случии, будет функционировать как обычный аддон отображения перезарядок."
L["Cooldown settings"] = "Настройки перезарядки"
L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."] = "Выберите, какие перезарядки отображать, с помощью раскрывающегося блока и ячеек ниже. Каждый класс имеет небольшой набор доступных заклинаний, которые можно просматривать используя панель отображения. Выберите один класс из раскрывающегося блока, а затем настроить заклинания для этого класса в соответствии с вашими потребностями."
L["Select class"] = "Выберите класс"
L["Never show my own spells"] = "Не показывать мои способности"
L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."] = "Отключает отображение перезарядки ваших способностей. К примеру если для отображения перезарядок ваших способностей вы используете другой аддон."
-- monitor
L["Right-Click me for options!"] = "[Правый-клик] открывает настройки."
L["Bar Settings"] = "Настройка панели"
L["Spawn test bar"] = "Запустить тест панель"
L["Use class color"] = "Окраска класса"
L["Height"] = "Высота"
L["Scale"] = "Масштаб"
L["Texture"] = "Текстура"
L["Icon"] = "Иконка"
L["Show"] = "Показать"
L["Duration"] = "Длительность"
L["Unit name"] = "Персонаж"
L["Spell name"] = "Заклинание"
L["Short Spell name"] = "Сокр. заклинание"
L["Label Align"] = "Выравнивать"
L["Left"] = "Влева"
L["Right"] = "Вправа"
L["Center"] = "По центру"

-- Zone module
L["Zone"] = "Зона"

-- Version module
L["Version"] = "Версия"

-- Loot module
 L["Leave empty to make yourself Master Looter."] = "Оставьте пустыми чтобы сделать себя ответственным за добычу."