local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "itIT")
if not L then return end

-- Generic
L["Name"] = "Nome"
L["Checks"] = "Controlli"
L["Disband Group"] = "Sciogli Incursione"
L["Disbands your current party or raid, kicking everyone from your group, one by one, until you are the last one remaining.\n\nSince this is potentially very destructive, you will be presented with a confirmation dialog. Hold down Control to bypass this dialog."] = "Sciogli la tua spedizione o incursione attuale, espellendo chiunque dal tuo gruppo, uno per uno, fino a che non sarai l'ultimo rimasto.\n\nDato che questa azione è potenzialmente molto distruttiva, ti verrà presentata una finesta di conferma. Tieni premuto Control per eliminare questa finestra."
L["Options"] = "Opzioni"
L["<oRA3> Disbanding group."] = "<oRA3> Scioglimento gruppo"
L["Are you sure you want to disband your group?"] = "Sei sicuro di voler sciogliere il tuo gruppo?"
L["Unknown"] = "Sconosciuto"
L["Profile"] = "Profilo"

-- Core

L["Toggle oRA3 Pane"] = "Attiva pannello oRA3"
L["Open with raid pane"] = "Attiva con il pannello incursione"
L.toggleWithRaidDesc = "Apre e chiude automaticamente il pannello di oRA3 insieme a quello Blizzard per le incursioni. Se disabiliti questa opzione puoi sempre aprire il pannello di oRA3 usando il tasto assegnato oppure con il comando slash, per esempio |cff44ff44/radur|r."
L["Show interface help"] = "Mostra aiuti interfaccia"
L.showHelpTextsDesc = "L'interfaccia di oRA3 è piena di testi utili per descrivere meglio che sta succedendo e che cosa facciano esattamente i vari elementi dell'interfaccia. Disabilitare questa opzione rimuove questi aiuti, limitando il disordine nei vari pannelli. |cffff4411Richiede il ricaricamento dell'interfaccia in alcuni pannelli.|r"
L["Ensure guild repairs are enabled for all ranks present in raid"] = "Assicura che le riparazioni di gilda sono abilitate per tutti i ranghi presenti nell'incursione"
L.ensureRepairDesc = "Se sei il Capogilda, quando entri in un gruppo d'incursione e sei o il capoincursione oppure vieni promosso, viene assicurato che tu lo sarai per tutta la durata dell'incursione (fino a 300 giorni). Quando esci dal gruppo, verrà tutto ripristinato ai valori predefiniti |cffff4411a patto che tu non abbia subito crash del gioco durante l'incursione.|r"
L.repairEnabled = "Abilita le riparazioni di gilda per %s per tutta la durata di questa incursione."
L["Show role icons on raid pane"] = "Mostra icona di ruolo nel pannello Incursione"
L.showRoleIconsDesc = "Mostra l'icona del ruolo e il conteggio totale di ogni ruolo nel pannello Incursione della Blizzard. Devi riaprire il pannello incursione per applicare le modifiche."

L["Slash commands"] = "Comandi Slash"
L.slashCommands = [[
oRA3 dispone di una serie di comandi slash per aiutarti a configurare velocemente le incursioni. Se non eri presente quando c'era CTRA, ecco una piccola lista. Tutti i comandi slash hanno varie scorciatoie ma anche versioni più lunghe, e descrizioni alternative in alcuni casi.

|cff44ff44/radur|r - Apre la lista di Integrità.
|cff44ff44/ragear|r - Apre la lista del Controllo Equipaggiamento.
|cff44ff44/ralag|r - Apre la lista della latenza.
|cff44ff44/razone|r - Apre la lista delle Zone.
|cff44ff44/radisband|r - Sciogli immediatamente l'incursione, senza nessuna verifica.
|cff44ff44/raready|r - Esegue un'appello.
|cff44ff44/rainv|r - Invita tutta la gilda nel tuo gruppo.
|cff44ff44/razinv|r - Invita i membri di gilda nella tua stessa zona.
|cff44ff44/rarinv <rank name>|r - Invita i membri di gilda di un determinato Grado.
]]

-- Ready check module
L["The following players are not ready: %s"] = "I seguenti giocatori non sono pronti: %s"
L["Ready Check (%d seconds)"] = "Appello (%d secondi)"
L["Ready"] = "Pronto"
L["Not Ready"] = "Non Pronto"
L["No Response"] = "Nessuna Risposta"
L["Offline"] = "Disconnesso"
L["Play the ready check sound using the Master sound channel when a ready check is performed. This will play the sound while \"Sound Effects\" is disabled and at a higher volume."] = "Esegui il suono dell'appello usando il dispositivo principale quando viene eseguito un'appello. Verrà eseguito il suono quando l'opzione \"Effetti audio\" è disabilitata e ad un volume maggiore."
L["Show window"] = "Mostra Finestra"
L["Show the window when a ready check is performed."] = "Mostra la finestra quando viene eseguito un'appello."
L["Hide window when done"] = "Nascondi la finestra quando terminato"
L["Automatically hide the window when the ready check is finished."] = "Nascondi automaticamente la finestra quando l'appello è terminato."
L["Hide players who are ready"] = "Nascondi giocatori che sono pronti"
L["Hide players that are marked as ready from the window."] = "Nascondi i giocatori che sono segnalati dalla finestra come pronti."
L["Automatically hide the ready check window when you get in combat."] = "Nascondi automaticamente la finestra dell'appello quando entri in combattimento."
L["Hide in combat"] = "Nascondi in combattimento"
L["Relay ready check results to raid chat"] = "Visualizza i risultati dell'appello nella chat d'incursione"
L["If you are promoted, relay the results of ready checks to the raid chat, allowing raid members to see what the holdup is. Please make sure yourself that only one person has this enabled."] = "Se sei stato promosso, visualizza i risultati degli appelli nella chat d'incursione, permettendo a tutti i membri dell'incursione di sapere chi è che li sta facendo ritardare. Assicurati che solo una persona abbia attivato questa opzione."

-- Durability module
L["Durability"] = "Integrità"
L["Average"] = "Media"
L["Broken"] = "Rotto"
L["Minimum"] = "Minimo"

-- Invite module
L["Invite"] = "Invita"
L["All max level characters will be invited to raid in 10 seconds. Please leave your groups."] = "Tutti i personaggi di livello massimo verranno invitati nell'incursione tra 10 secondi. Per favore uscite dai vostri gruppi."
L["All characters in %s will be invited to raid in 10 seconds. Please leave your groups."] = "Tutti i personaggi nella zona %s verranno invitati nell'incursione tra 10 secondi. Per favore uscite dai vostri gruppi."
L["All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups."] = "Tutti i personaggi di grado %s o maggiore verranno invitati nell'incursione tra 10 secondi. Per favore uscite dai vostri gruppi."
L["<oRA3> Sorry, the group is full."] = "<oRA3> Spiacente, il gruppo è completo."
L["Invite all guild members of rank %s or higher."] = "Invita tutti i membri di gilda di grado %s o maggiore."
L["Keyword"] = "Parola chiave"
L["When people whisper you the keywords below, they will automatically be invited to your group. If you're in a party and it's full, you will convert to a raid group. The keywords will only stop working when you have a full raid of 40 people. Setting a keyword to nothing will disable it."] = "Quando qualcuno ti sussurrerà la parola chiave, verranno automaticamente invitati nel tuo gruppo. Se sei in un gruppo ed è pieno, verrà convertito in un gruppo d'incursione. La parola chiave smetterà di funzionare sontanto quando il tuo gruppo sarà di 40 unità. Questa funzione verrà disabilitata quando non si imposterà nessuna Parola Chiave."
L["Anyone who whispers you this keyword will automatically and immediately be invited to your group."] = "Chiunque ti sussurrerà questa parola verrà invitato instantaneamente ed automaticamente nel tuo gruppo."
L["Guild Keyword"] = "Parola chiave di Gilda"
L["Any guild member who whispers you this keyword will automatically and immediately be invited to your group."] = "Qualsiasi membro di Gilda che ti sussurrerà questa parola verrà invitato instantaneamente ed automaticamente nel tuo gruppo."
L["Invite guild"] = "Invita Gilda"
L["Invite everyone in your guild at the maximum level."] = "Invita tutti i membri di gilda di livello massimo."
L["Invite zone"] = "Invita zona"
L["Invite everyone in your guild who are in the same zone as you."] = "Invita tutti i membri di gilda che sono nella tua stessa zona"
L["Guild rank invites"] = "Inviti Grado di Gilda"
L["Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites."] = "Cliccando su uno dei pulsanti sottostanti inviterà chiunque abbia quel rango E TUTTI QUELLI DI RANGO SUPERIORE nel tuo gruppo. Quindi, cliccando sul terzo pulsante inviterà chiunque abbia il rango 1, 2 e 3. Verrà inviato un'avviso nella chat di gilda e degli ufficialie darà 10 secondi di tempo a tutti i mebri per uscire dai loro gruppi prima di essere invitati nel tuo."
L["Only invite on keyword if in a raid group"] = "Invita soltanto con Parola Chiave se sei in un gruppo incursione"

-- Promote module
L["Demote everyone"] = "Degrada tutti"
L["Demotes everyone in the current group."] = "Degrada tutti nel gruppo attuale."
L["Promote"] = "Promuovi"
L["Mass promotion"] = "Promozione di massa"
L["Everyone"] = "Chiunque"
L["Promote everyone automatically."] = "Promuovi tutti automaticamente"
L["Guild"] = "Gilda"
L["Promote all guild members automatically."] = "Promuove automaticamente tutti i membri di Gilda"
L["By guild rank"] = "Per Rango di Gilda"
L["Individual promotions"] = "Promozione individuale"
L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."] = "Attenzione: i nomi sono case sensitive. Per aggiungere un giocatore, scrivi il suo nome nel riquadro sottostante e premi Invio oppure clicca sul pulsante che apparirà. Per rimuovere un giocatore dalla lista dei promossi automaticamente, basta cliccare sul suo nome nel menù a scomparsa sotto."
L["Add"] = "Aggiungi"
L["Remove"] = "Rimuovi"

-- Cooldowns module
L["Open monitor"] = "Apri monitor"
L["Cooldowns"] = "Recuperi"
L["Monitor settings"] = "Impostazioni monitor"
L["Show monitor"] = "Mostra monitor"
L["Lock monitor"] = "Blocca monitor"
L["Show or hide the cooldown bar display in the game world."] = "Mostra o nascondi la barra del recupero nel mondo di gioco."
L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."] = "Bloccare il monitor dei recuperi nasconderà la barra del titolo e l'angolo per muovere il riquadro, rendendo impossibile muoverlo, riposizionarlo ed ingrandirlo ed anche di mostrare le opzioni della barra."
L["Only show my own spells"] = "Mostra solo i miei incantesimi"
L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."] = "Attiva la visualizzazione dei recuperi solo per i tuoi incantesimi, rendendolo di fatto un semplice addon per monitorare i recuperi."
L["Cooldown settings"] = "Impostazioni Recuperi"
L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."] = "Seleziona quali recuperi mostrare usando il menù a tendina e i segni di spunta sottostanti. Ogni classe ha un certo numero di incantesimi disponibili per poterne vedere i tempi di recupero. Seleziona una classe dal menù a scomparsa e poi configura quali incantesimi di classe monitorare per i tuoi bisogni."
L["Select class"] = "Seleziona classe"
L["Never show my own spells"] = "Non mostrare mai i miei incantesimi"
L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."] = "Attiva o no la visualizzazione sul monitor dei recuperi di quelli relativi ai tuoi incantesimi o abilità. Per esempio, se usi un'altro addon per tenere traccia dei tuoi recuperi."

-- monitor
L["Cooldowns"] = "Recuperi"
L["Right-Click me for options!"] = "Clic_Destro su di me per le opzioni!"
L["Bar Settings"] = "Impostazioni Barra"
L["Text Settings"] = "Impostazioni Testo"
L["Label Text Settings"] = "Impostazioni Testo Etichetta"
L["Spawn test bar"] = "Prova barra di test"
L["Use class color"] = "Usa il colore di classe"
L["Custom color"] = "Colore personalizzato"
L["Height"] = "Altezza"
L["Scale"] = "Scalatura"
L["Texture"] = "Texture"
L["Icon"] = "Icona"
L["Show"] = "Mostra"
L["Duration"] = "Durata"
L["Unit name"] = "Nome unità"
L["Spell name"] = "Nome Abilità"
L["Short Spell name"] = "Nome abilità corto"
L["Label Font"] = "Carattere Etichetta"
L["Label Font Size"] = "Dimensione Carattere Etichetta"
L["Label Align"] = "Allinea Etichetta"
L["Left"] = "Sinistra"
L["Right"] = "Destra"
L["Center"] = "Centro"
L["Duration Font"] = "Durata Carattere"
L["Duration Font Size"] = "Dimensione Durata Carattere"
L["Grow up"] = "Crescente"

-- Zone module
L["Zone"] = "Zona"

-- Loot module
L["Leave empty to make yourself Master Looter."] = "Lascia vuoto per impostare te stesso come Responsabile del Bottino."
L["Let oRA3 to automatically set the loot mode to what you specify below when entering a party or raid."] = "Lascia che sia oRA3 ad impostare automaticamente la modalità di depredamento con le modalità impostate successivamente quando entri in un gruppo od incursione."
L["Set the loot mode automatically when joining a group"] = "imposta automaticamente la modalità di depredamento quando entri in un gruppo o incursione"

-- Tanks module
L["Tanks"] = "Difensori"
L.tankTabTopText = "Clic sui giocatori nella lista seguente per renderli dei difensori personali. Se hai bisogno di aiuto con tutte le opzioni disponibili muovi il mouse sul punto di domanda."
-- L["Remove"] is defined above
L.deleteButtonHelp = "Rimuovi dalla lista dei Difensori. Attenzione: una volta rimosso un giocatore dalla lista, non verrà riaggiunto automaticamente per tutta la durata della sessione, a meno di riaggiungerlo manualmente."
L["Blizzard Main Tank"] = "Difensori Principali Blizzard"
L.tankButtonHelp = "Attiva per rendere il Difensore un Difensore Principale Blizzard."
L["Save"] = "Salva"
L.saveButtonHelp = "Salva il Difensore nella tua lista personale. Ogni volta che sarai in gruppo con questo giocatore verrà elencato come tank personale."
L["What is all this?"] = "Cos'é questo?"
L.tankHelp = "I giocatori in questa lista sono i tuoi difeosori personali preferiti. Non sono condivisi con il resto dell'incursione e ognuno può avere la sua propria lista. Cliccare su un nome della lista lo aggiungerà alla tua lista di Difensori Personali.\n\nCliccare sull'icona dello Scudo renderà il giocatore un Difensore Principale Blizzard. I Difensori Blizzard sono condivisi tra tutti i membri del gruppo e devi essere promosso per attivare questa funzione.\n\nI Difensori che appaiono in questa lista perché sono stati resi tali da altre persone verranno rimossi quando non saranno più dei Difensori Principali Blizzard.\n\nUsate il segno di spunta verde per salvare il difensore tra due diverse sessioni. La volta successiva che sarai in gruppo con quel giocatore, verrà automaticamente impostato come Difensore Personale."
L["Sort"] = "Ordina"
L["Click to move this tank up."] = "Clicca per portare in alto questo difensore"
L["Show"] = "Mostra"
L.showButtonHelp = "Mostra questo difensore nella tua lista personale. Questa opzione ha solo effetto locale e non cambierà lo status dei difensori della tua incursione."

-- Latency Module
L["Latency"] = "Latenza"
L["Home"] = "Locale"
L["World"] = "Reame"

-- Gear Module
L["Gear"] = "Armatura"
L["Item Level"] = "Livello Oggetto"
L["Missing Gems"] = "Gemme Mancanti"
L["Missing Enchants"] = "Incantamenti Mancanti"

