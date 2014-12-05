local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "esES") or LibStub("AceLocale-3.0"):NewLocale("oRA3", "esMX")
if not L then return end

-- Generic
L["Name"] = "Nombre"
L["Checks"] = "Comprobar"
L["Disband Group"] = "Disolver grupo"
L["Disbands your current party or raid, kicking everyone from your group, one by one, until you are the last one remaining.\n\nSince this is potentially very destructive, you will be presented with a confirmation dialog. Hold down Control to bypass this dialog."] = "Disuelve tu grupo o raid actual, expulsando cada uno de tu grupo, uno a uno, hasta que seas el último restante.\n\Esto es algo potencialmente muy destructivo, se mostrará un diálogo de confirmación. Presiona la tecla Control para saltar este diálogo."
L["Options"] = "Opciones"
L["<oRA3> Disbanding group."] = "<oRA3> Disolver grupo."
L["Are you sure you want to disband your group?"] = "¿Estás seguro que quieres disolver tu grupo?"
L["Unknown"] = "Desconocido"
L["Profile"] = "Perfil"

-- Core

L["Toggle oRA3 Pane"] = "Panel oRA3 on/off"
L["Open with raid pane"] = "Abrir con panel de raid"
L.toggleWithRaidDesc = "Abre y cierra el panel de oRA3 automáticamente con el panel de raid de Blizzard. Si desactivas esta opción puedes seguir abriendo el panel de oRA3 usando comandos, como por ejemplo |cff44ff44/radur|r."
L["Show interface help"] = "Mostrar ayuda"
L.showHelpTextsDesc = "La interfaz de ayuda de oRA3 es muy útil, su intención es describir mejor que hace cada cosa y que están haciendo acualmente cada elemento de la interfaz. Desactivando esta opción los eliminarás, limitando la confusión en cada panel. |cffff4411Requiere recargar la interfaz en algunos paneles.|r"
L["Ensure guild repairs are enabled for all ranks present in raid"] = "Asegurarse que las reparaciones de hermandad están activadas para todos los rangos presentes en la raid"
L.ensureRepairDesc = "Si eres el Maestro de la hermandad, cada vez que entres a un grupo de raid y seas el líder o ayudante, con esto te asegurarás que las reparaciones de hermandad están activadas para la duración de la raid (hasta 300g). Una vez dejes el grupo, los ajustes serán restaurados a su estado original |cffff4411siempre que no te caigas durante la raid.|r"
L.repairEnabled = "Activadas reparaciones de hermandad de %s para la duración de esta raid."
L["Show role icons on raid pane"] = "Mostrar iconos de rol en el panel de raid"
L.showRoleIconsDesc = "Muestra iconos de rol y la cantidad total de cada uno en el panel de raid de Blizzard. Necesitarás reabrir el panel de raid para que los cambios tengan efecto."

L["Slash commands"] = "Comandos"
L.slashCommands = [[
oRA3 tiene una serie de comandos que agilizan la tarea de administrar la raid. En el caso de que no esté familiarizado con el viejo CTRA, aquí se muestra una pequeña referencia. Todos los comandos tienen atajos y otros más largos, alternativas más descriptivas en algunos casos, según sea conveniente.

|cff44ff44/radur|r - Abre el panel de durabilidad.
|cff44ff44/ragear|r - Abre el panel de chequeo de equipo.
|cff44ff44/ralag|r - Abre el panel de latencia.
|cff44ff44/razone|r - Abre el panel de zona.
|cff44ff44/radisband|r - Disuelve la raid instantáneamente sin verificación.
|cff44ff44/raready|r - Realiza un Comprobar listos.
|cff44ff44/rainv|r - Invita a toda la hermandad a tu grupo.
|cff44ff44/razinv|r - Invita a los miembros de hermandad que están en la misma zona que tu.
|cff44ff44/rarinv <rank name>|r - Invita a los miembros de hermandad de un rango determinado.
]]

-- Ready check module
L["The following players are not ready: %s"] = "Los siguientes jugadores no están listos: %s"
L["Ready Check (%d seconds)"] = "Comprobar listos (%d segundos)"
L["Ready"] = "Listos"
L["Not Ready"] = "No listos"
L["No Response"] = "No reponden"
L["Offline"] = "Desconectado"
L["Play the ready check sound using the Master sound channel when a ready check is performed. This will play the sound while \"Sound Effects\" is disabled and at a higher volume."] = "Reproduce el sonido de comprobar listos usando el canal principal de sonido cuando un comprobar listos es ejecutado. Esto reproducirá el sonido mientras \"Efectos de sonido\" está desactivado y con un volumen más alto."
L["Show window"] = "Mostrar ventana"
L["Show the window when a ready check is performed."] = "Muestra la ventana cuando un comprobar listos es ejecutado."
L["Hide window when done"] = "Oculta la ventana cuando termine"
L["Automatically hide the window when the ready check is finished."] = "Automáticamente oculta la ventana cuando el comprobar listos haya finalizado."
L["Hide players who are ready"] = "Ocultar jugadores que estén listos"
L["Hide players that are marked as ready from the window."] = "Ocultar jugadores que están marcados como listos de la ventana."
L["Automatically hide the ready check window when you get in combat."] = "Automáticamente oculta la ventana de comprobar listos cuando entras en combate."
L["Hide in combat"] = "Ocultar en combate"
L["Relay ready check results to raid chat"] = "Mostrar los resultados del comprobar listos al chat de raid"
L["If you are promoted, relay the results of ready checks to the raid chat, allowing raid members to see what the holdup is. Please make sure yourself that only one person has this enabled."] = "Si eres ayudante, mostrar los resultados del comprobar listos en el chat de raid, permitiendo a los miembros ver quien está listo o no. Por favor asegurate que sólo una persona tenga esta opción activada."

-- Durability module
L["Durability"] = "Durabilidad"
L["Average"] = "Promedio"
L["Broken"] = "Roto"
L["Minimum"] = "Mínimo"

-- Invite module
L["Invite"] = "Invitar"
L["All max level characters will be invited to raid in 10 seconds. Please leave your groups."] = "Todos los jugadores con el nivel máximo serán invitados a la raid en 10 segundos. Por favor, dejar vuestros grupos."
L["All characters in %s will be invited to raid in 10 seconds. Please leave your groups."] = "Todos los jugadores en %s serán invitados a la raid en 10 segundos. Por favor, dejar vuestros grupos."
L["All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups."] = "Todos los jugadores con rango %s o superior serán invitados a la raid en 10 segundos. Por favor, dejar vuestros grupos."
L["<oRA3> Sorry, the group is full."] = "<oRA3> Lo siento, el grupo esta completo."
L["Invite all guild members of rank %s or higher."] = "Invita a todos los miembros de la hermandad de rango %s o superior."
L["Keyword"] = "Palabra clave"
L["When people whisper you the keywords below, they will automatically be invited to your group. If you're in a party and it's full, you will convert to a raid group. The keywords will only stop working when you have a full raid of 40 people. Setting a keyword to nothing will disable it."] = "Cuando la gente te susurre la palabra clave de abajo, serán invitados automáticamente a tu grupo. Si estás en un grupo y está completo, convertirás el grupo a una banda. La palabra clave sólo parará de funcionar cuando tengas una banda completa de 40 personas. Si dejas la palabra clave en blanco desactivarás esta opción."
L["Anyone who whispers you this keyword will automatically and immediately be invited to your group."] = "Cualquiera que te susurre esta palabra clave sera inmediata y automáticamente invitado a tu grupo."
L["Guild Keyword"] = "Palabra clave de hermandad"
L["Any guild member who whispers you this keyword will automatically and immediately be invited to your group."] = "Un miembro de la hermandad que te susurre esta palabra clave será inmediata y automáticamente invitado a tu grupo."
L["Invite guild"] = "Invitar hermandad"
L["Invite everyone in your guild at the maximum level."] = "Invita a cualquiera de tu hermandad con el nivel máximo."
L["Invite zone"] = "Invitar zona"
L["Invite everyone in your guild who are in the same zone as you."] = "Invita a cualquiera de tu hermandad que esté en la misma zona que tu."
L["Guild rank invites"] = "Invitaciones de hermandad por rango"
L["Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites."] = "Clicando cualquiera de los botones de abajo invitarás a cualquiera con el rango seleccionado Y SUPERIOR a tu grupo. Así que clicando en el 3er botón invitarás a cualquiera con rango 1, 2 o 3, por ejemplo. Primero mostrará un mensaje tanto en el chat de hermandad como en el de oficiales y dejará 10 segundos a los miembros para dejar sus grupos antes de hacer el invite masivo."
L["Only invite on keyword if in a raid group"] = "Sólo invitar con palabra clave si es un grupo de raid"

-- Promote module
L["Demote everyone"] = "Degradar a todos"
L["Demotes everyone in the current group."] = "Degrada a todos en el grupo actual."
L["Promote"] = "Promover ayudante"
L["Mass promotion"] = "Promover ayudante masivamente"
L["Everyone"] = "Todos"
L["Promote everyone automatically."] = "Promueve ayudante a todos automáticamente"
L["Guild"] = "Hermandad"
L["Promote all guild members automatically."] = "Promueve ayudante a todos los miembros de hermandad automáticamente."
L["By guild rank"] = "Por rango de hermandad"
L["Individual promotions"] = "Promover ayudante individualmente"
L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."] = "Ten en cuenta que los nombres distinguen mayúsculas. Para añadir un jugador, introduce el nombre del jugador en el recuadro de abajo y presiona Enter o clica el botón que aparece. Para quitar a un jugador que ha sido promovido ayudante automáticamente, sólo clica su nombre en la lista desplegable de abajo."
L["Add"] = "Añadir"
L["Remove"] = "Quitar"

-- Cooldowns module
L["Open monitor"] = "Abrir el monitor"
L["Cooldowns"] = "CDs"
L["Monitor settings"] = "Ajustes del monitor"
L["Show monitor"] = "Mostrar monitor"
L["Lock monitor"] = "Bloquear el monitor"
L["Show or hide the cooldown bar display in the game world."] = "Muestra u oculta la ventana de barras de CDs en el juego."
L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."] = "Ten en cuenta que bloqueando el monitor de CDs ocultarás el título y el arrastre y lo harás imposible de mover, escalar o abrir la ventana de opciones de las barras."
L["Only show my own spells"] = "Sólo mostrar mis propios hechizos"
L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."] = "Alternar si la ventana CDs sólo debe mostrar el CD de los hechizos lanzados por ti, básicamente funciona como un complemento de la ventana de CDs normal."
L["Cooldown settings"] = "Ajustes de CDs"
L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."] = "Selecciona que CDs se mostrarán usando la lista desplegable y las casillas de abajo. Cada clase tiene un pequeño ajuste de hechizos disponible que puedes ver usando la ventana de barras. Selecciona una clase de la lista desplegable y configura los hechizos para cada clase de acuerdo cono tus propias necesidades."
L["Select class"] = "Seleccionar clase"
L["Never show my own spells"] = "Nunca mostrar mis propios hechizos"
L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."] = "Alternar si la ventana de CDs nunca debería mostrar tus CDs. Por ejemplo si usas otro addon de CDs para tus propios CDs."

-- monitor
L["Cooldowns"] = "CDs"
L["Right-Click me for options!"] = "Clic derecho en mí para opciones!"
L["Bar Settings"] = "Ajustes de barra"
L["Label Text Settings"] = "Ajustes de texto de etiqueta"
L["Duration Text Settings"] = "Ajustes de texto de duración"
L["Spawn test bar"] = "Mostrar barra de prueba"
L["Use class color"] = "Usar color de clase"
L["Custom color"] = "Color personalizado"
L["Height"] = "Altura"
L["Scale"] = "Escala"
L["Texture"] = "Textura"
L["Icon"] = "Icono"
L["Show"] = "Mostrar"
L["Duration"] = "Duración"
L["Unit name"] = "Nombre de unidad"
L["Spell name"] = "Nombre de hechizo"
L["Short Spell name"] = "Nombre corto de hechizo"
L["Font"] = "Fuente"
L["Font Size"] = "Tamaño de fuente"
L["Label Align"] = "Alinear etiqueta"
L["Left"] = "Izquierda"
L["Right"] = "Derecha"
L["Center"] = "Centro"
L["Outline"] = "Contorno"
L["Thick"] = "Grueso"
L["Thin"] = "Delgado"
L["Grow up"] = "Crecer"

-- Zone module
L["Zone"] = "Zona"

-- Loot module
L["Leave empty to make yourself Master Looter."] = "Dejar vacío para asegurarte Maestro despojador"
L["Let oRA3 to automatically set the loot mode to what you specify below when entering a party or raid."] = "Deja a oRA3 ajustar automáticamente el modo de loteo que tu especifiques para cuando entres a un grupo o raid."
L["Set the loot mode automatically when joining a group"] = "Ajustar automáticamente el modo de loteo cuando entres a un grupo."

-- Tanks module
L["Tanks"] = "Tanques"
L.tankTabTopText = "Clica en la lista de abajo los jugadores para definirlos como tanques. Si quieres ayudar con todas las opciones aquí, entonces mueve el ratón sobre el signo de interrogación."
-- L["Remove"] is defined above
L.deleteButtonHelp = "Quitar de la lista de tanques. Ten en cuenta que una vez quitado no volverá a ser añadido en el resto de la sesión a menos que tu manualmente lo vuelvas a agregar."
L["Blizzard Main Tank"] = "Tanque principal Blizzard"
L.tankButtonHelp = "Alternar si este tanque debería ser un tanque principal de Blizzard."
L["Save"] = "Guardar"
L.saveButtonHelp = "Guarda este tanque en tu lista personal. Siempre que estés en grupo con este jugador, el será listado como un tanque personal."
L["What is all this?"] = "¿Qué es todo esto?"
L.tankHelp = "La gente en la lista de los mejores tiene ordenados tus tanques personales. Ellos no serán compartidos con la raid, cualquiera puede tener su propia lista de tanques personales. Clicando un nombre en la lista de abajo agregará este a tu lista de tanques personales.\n\nClicando en el icono de escudo hará que esa persona sea un tanque principal de Blizzard. Los tanques principales de Blizzard son compartidos con el resto de la raid y tienes que ser ayudante para hacerlo.\n\nLos tanques que aparecen en la lista debido a que alguien los marca como tanques principales de Blizzard serán quitados de la lista cuando ellos dejen de ser tanques principales de Blizzard.\n\nUsa la marca verde de verificación para guardar un tanque entre sesiones. La próxima vez que estés en una raid con esa persona, el automáticamente será marcado como un tanque personal."
L["Sort"] = "Corto"
L["Click to move this tank up."] = "Clic para mover arriba este tanque."
L["Show"] = "Mostrar"
L.showButtonHelp = "Muestra este tanque en la ventana de tu lista personal de tanques. Esta opción sólo tiene efecto local y no cambiará el estado de este tanque para nadie en tu grupo."

-- Latency Module
L["Latency"] = "Latencia"
L["Home"] = "Local"
L["World"] = "Mundo"

-- Gear Module
L["Gear"] = "Equipo"
L["Item Level"] = "Nivel de equipo"
L["Missing Gems"] = "Gemas faltantes"
L["Missing Enchants"] = "Encantamientos faltantes"

-- BattleRes Module
L.battleResTitle = "Monitor de Res en combate"
L.battleResLockDesc = "Activa el bloqueo del monitor. Esto ocultará el texto de cabecera, fondo, y previene que se mueva."
L.battleResShowDesc = "Cambia entre mostrar u ocultar el monitor."


