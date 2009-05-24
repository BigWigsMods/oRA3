local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "deDE")

if not L then return end

-- Generic
L["Name"] = "Name"
L["Checks"] = "Checks"
L["Disband Group"] = "Gruppe auflösen"
L["Options"] = "Optionen"
L["<oRA3> Disbanding group."] = "<oRA3> Gruppe aufgelöst."
L["Click to open/close oRA3"] = "Klicken, um oRA3 zu öffnen / schließen."
L["Unknown"] = "Unbekannt"

L["WARLOCK"] = "Hexenmeister"
L["WARRIOR"] = "Krieger"
L["HUNTER"] = "Jäger"
L["MAGE"] = "Magier"
L["PRIEST"] = "Priester"
L["DRUID"] = "Druide"
L["PALADIN"] = "Paladin"
L["SHAMAN"] = "Schamane"
L["ROGUE"] = "Schurke"
L["DEATHKNIGHT"] = "Todesritter"

-- Ready check module
L["The following players are not ready: %s"] = "Die folgenden Spieler sind nicht bereit: %s"
L["Ready Check (%d seconds)"] = "Bereitschaftscheck (%d Sekunden)"
L["Ready"] = "Bereit"
L["Not Ready"] = "Nicht bereit"
L["No Response"] = "Keine Antwort"
L["Offline"] = "Offline"

-- Durability module
L["Durability"] = "Haltbarkeit"
L["Average"] = "Durchschnitt"
L["Broken"] = "Kaputt"
L["Minimum"] = "Minimum"

-- Resistances module
L["Resistances"] = "Widerstände"
L["Frost"] = "Frost"
L["Fire"] = "Feuer"
L["Shadow"] = "Schatten"
L["Nature"] = "Natur"
L["Arcane"] = "Arkan"

-- Resurrection module
L["%s is ressing %s."] = "%s belebt %s."

-- Invite module
L["Invite"] = "Einladen"
L["All max level characters will be invited to raid in 10 seconds. Please leave your groups."] = "Alle Charaktere auf Maximallevel werden in 10 Sekunden in den Raid eingeladen. Bitte verlasst Eure Gruppen."
L["All characters in %s will be invited to raid in 10 seconds. Please leave your groups."] = "Alle Charaktere in %s werden in 10 Sekunden in den Raid eingeladen. Bitte verlasst Eure Gruppen."
L["All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups."] = "Alle Charaktere des Rangs %s oder höher werden in 10 Sekunden in den Raid eingeladen. Bitte verlasst Eure Gruppen." 
L["<oRA3> Sorry, the group is full."] = "<oRA3> Sorry, die Gruppe ist voll."
L["Invite all guild members of rank %s or higher."] = "Läd alle Gildenmitglieder des Rangs %s oder höher ein."
L["Keyword"] = "Schlüsselwort"
L["When people whisper you the keywords below, they will automatically be invited to your group. If you're in a party and it's full, you will convert to a raid group. The keywords will only stop working when you have a full raid of 40 people. Setting a keyword to nothing will disable it."] = "Wenn Spieler Dir das unten aufgeführte Schlüsselwort zuflüstern, werden sie automatisch in deine Gruppe eingeladen. Wenn du in einer bereits vollen Gruppe bist, wird diese in eine Raidgruppe umgewandelt. Die Schlüsselwortmethode funktioniert so lange, bis der Raid volle 40 Mann erreicht hat. Wenn nichts als Schlüsselwort angegeben wird, wird die Methode ausgeschalten."
L["Anyone who whispers you this keyword will automatically and immediately be invited to your group."] = "Jeder, der Dir dieses Schlüsselwort zuflüstert, wird automatisch und sofort in deine Gruppe eingeladen."
L["Guild Keyword"] = "Gildenschlüsselwort"
L["Any guild member who whispers you this keyword will automatically and immediately be invited to your group."] = "Jedes Gildenmitglied, das Dir dieses Schlüsselwort zuflüstert, wird automatisch und sofort in deine Gruppe eingeladen."
L["Invite guild"] = "Gilde einladen"
L["Invite everyone in your guild at the maximum level."] = "Läd jeden in deiner Gilde ein, der auf Maximallevel ist."
L["Invite zone"] = "Zone einladen"
L["Invite everyone in your guild who are in the same zone as you."] = "Läd jeden in deiner Gilde ein, der sich in der selben Zone wie Du aufhält."
L["Guild rank invites"] = "Gildenränge einladen"
L["Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites."] = "Sobald Du auf einen der unteren Buttons klickst, werden alle Mitglieder des ausgewählten Rangs UND DARÜBERLIEGENDE in deine Gruppe eingeladen. Dementsprechend läd z.B. das Klicken auf den dritten Button jeden des Rangs 1, 2 und 3 ein. Dies wird zudem entweder eine Nachricht im Gilden- oder Offizierschat auslösen, die deinen Gildenmitgliedern 10 Sekunden Zeit gibt, ihre Gruppen zu verlassen, bevor sie wirklich eingeladen werden."

-- Promote module
L["Promote"] = "Befördern"
L["Mass promotion"] = "Massenbeförderung"
L["Everyone"] = "Jeder"
L["Promote everyone automatically."] = "Befördert automatisch jeden."
L["Guild"] = "Gilde"
L["Promote all guild members automatically."] = "Befördert automatisch alle Gildenmitglieder."
L["By guild rank"] = "Nach Gildenrang"
L["Individual promotions"] = "Individuelle Beförderungen"
L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."] = "Beachte, dass Spielernamen abhängig von Groß- und Kleinschreibung sowie Sonderzeichen sind. Um einen Spieler hinzuzufügen, musst Du seinen Namen in der untenstehenden Box eingeben und Enter oder den aufpoppenden Button drücken. Um einen Spieler zu entfernen, musst Du nur seinen Namen im Dropdown Menü anklicken."
L["Add"] = "Hinzufügen"
L["Remove"] = "Entfernen"

-- Cooldowns module
L["Cooldowns"] = "Cooldowns"
L["Monitor settings"] = "Einstellungen der Anzeige"
L["Show monitor"] = "Anzeige einschalten"
L["Lock monitor"] = "Anzeige sperren"
L["Show or hide the cooldown bar display in the game world."] = "Zeigt oder versteckt die Anzeige der Cooldowns in der Spielwelt."
L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."] = "Beachte, dass das Sperren der Anzeige den Titel versteckt und die Möglichkeiten entfernt, die Größe zu ändern, die Anzeige zu bewegen oder die Leistenoptionen aufzurufen."
L["Only show my own spells"] = "Nur eigene Zaubersprüche anzeigen"
L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."] = "Entscheidet, ob nur eigene Abklingzeiten angezeigt werden sollen. Funktioniert wie ein normales Addon zur Anzeige eigener Cooldowns."
L["Cooldown settings"] = "Einstellungen der Cooldowns"
L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."] = "Wähle über das untenstehende Dropdown Menü und die Checkboxen, welche Cooldowns angezeigt werden sollen. Jede Klasse verfügt über ein paar voreingestellte Zaubersprüche, deren Cooldowns dann über die Anzeige eingesehen werden können. Wähle eine Klasse und markiere dann die Sprüche, die deinen Vorlieben entsprechen."
L["Select class"] = "Klasse wählen"
L["Never show my own spells"] = "Niemals eigene Zaubersprüche anzeigen"
L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."] = "Entscheidet, ob nur die Abklingzeiten anderer Spieler angezeigt werden sollen. Nützlich, wenn Du z.B. zur Anzeige deiner Cooldowns ein anderes Addon nutzt."
-- monitor
L["Right-Click me for options!"] = "Rechts-klicken für Optionen!"
L["Bar Settings"] = "Leisteneinstellungen"
L["Spawn test bar"] = "Testleiste erzeugen"
L["Use class color"] = "Klassenfarben"
L["Height"] = "Höhe"
L["Scale"] = "Skalierung"
L["Texture"] = "Textur"
L["Icon"] = "Symbol"
L["Show"] = "Anzeigen"
L["Duration"] = "Dauer"
L["Unit name"] = "Spielername"
L["Spell name"] = "Zauberspruch"
L["Short Spell name"] = "Zauberspruch abkürzen"

-- Zone module
L["Zone"] = "Zone"

-- Version module
L["Version"] = "Version"