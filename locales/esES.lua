
if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end
local _, tbl = ...
local L = tbl.locale

-- Generic
L.name = "Nombre"
L.checks = "Comprobar"
L.disbandGroup = "Disolver grupo"
L.disbandGroupDesc = "Disuelve tu grupo o raid actual, expulsando cada uno de tu grupo, uno a uno, hasta que seas el último restante.\n\Esto es algo potencialmente muy destructivo, se mostrará un diálogo de confirmación. Presiona la tecla Control para saltar este diálogo."
L.options = "Opciones"
L.disbandingGroupChatMsg = "Disolver grupo."
L.disbandGroupWarning = "¿Estás seguro que quieres disolver tu grupo?"
L.unknown = "Desconocido"
L.profile = "Perfil"

-- Core

L.togglePane = "Panel oRA3 on/off"
L.toggleWithRaid = "Abrir con panel de raid"
L.toggleWithRaidDesc = "Abre y cierra el panel de oRA3 automáticamente con el panel de raid de Blizzard. Si desactivas esta opción puedes seguir abriendo el panel de oRA3 usando comandos, como por ejemplo |cff44ff44/radur|r."
L.showHelpTexts = "Mostrar ayuda"
L.showHelpTextsDesc = "La interfaz de ayuda de oRA3 es muy útil, su intención es describir mejor que hace cada cosa y que están haciendo acualmente cada elemento de la interfaz. Desactivando esta opción los eliminarás, limitando la confusión en cada panel. |cffff4411Requiere recargar la interfaz en algunos paneles.|r"
L.ensureRepair = "Asegurarse que las reparaciones de hermandad están activadas para todos los rangos presentes en la raid"
L.ensureRepairDesc = "Si eres el Maestro de la hermandad, cada vez que entres a un grupo de raid y seas el líder o ayudante, con esto te asegurarás que las reparaciones de hermandad están activadas para la duración de la raid (hasta 300g). Una vez dejes el grupo, los ajustes serán restaurados a su estado original |cffff4411siempre que no te caigas durante la raid.|r"
L.repairEnabled = "Activadas reparaciones de hermandad de %s para la duración de esta raid."
L.showRoleIcons = "Mostrar iconos de rol en el panel de raid"
L.showRoleIconsDesc = "Muestra iconos de rol y la cantidad total de cada uno en el panel de raid de Blizzard. Necesitarás reabrir el panel de raid para que los cambios tengan efecto."

L.slashCommandsHeader = "Comandos"
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
L.notReady = "Los siguientes jugadores no están listos: %s"
L.readyCheckSeconds = "Comprobar listos (%d segundos)"
L.ready = "Listos"
L.notReady = "No listos"
L.noResponse = "No reponden"
L.offline = "Desconectado"
L.readyCheckSound = "Reproduce el sonido de comprobar listos usando el canal principal de sonido cuando un comprobar listos es ejecutado. Esto reproducirá el sonido mientras \"Efectos de sonido\" está desactivado y con un volumen más alto."
L.showWindow = "Mostrar ventana"
L.showWindowDesc = "Muestra la ventana cuando un comprobar listos es ejecutado."
L.hideWhenDone = "Oculta la ventana cuando termine"
L.hideWhenDoneDesc = "Automáticamente oculta la ventana cuando el comprobar listos haya finalizado."
L.hideReadyPlayers = "Ocultar jugadores que estén listos"
L.hideReadyPlayersDesc = "Ocultar jugadores que están marcados como listos de la ventana."
L.hideInCombatDesc = "Automáticamente oculta la ventana de comprobar listos cuando entras en combate."
L.hideInCombat = "Ocultar en combate"
L.printToRaid = "Mostrar los resultados del comprobar listos al chat de raid"
L.printToRaidDesc = "Si eres ayudante, mostrar los resultados del comprobar listos en el chat de raid, permitiendo a los miembros ver quien está listo o no. Por favor asegurate que sólo una persona tenga esta opción activada."

-- Durability module
L.durability = "Durabilidad"
L.average = "Promedio"
L.broken = "Roto"
L.minimum = "Mínimo"

-- Invite module
L.invite = "Invitar"
L.invitePrintMaxLevel = "Todos los jugadores con el nivel máximo serán invitados a la raid en 10 segundos. Por favor, dejar vuestros grupos."
L.invitePrintZone = "Todos los jugadores en %s serán invitados a la raid en 10 segundos. Por favor, dejar vuestros grupos."
L.invitePrintRank = "Todos los jugadores con rango %s o superior serán invitados a la raid en 10 segundos. Por favor, dejar vuestros grupos."
L.invitePrintGroupIsFull = "Lo siento, el grupo esta completo."
L.inviteGuildRankDesc = "Invita a todos los miembros de la hermandad de rango %s o superior."
L.keyword = "Palabra clave"
L.inviteDesc = "Cuando la gente te susurre la palabra clave de abajo, serán invitados automáticamente a tu grupo. Si estás en un grupo y está completo, convertirás el grupo a una banda. La palabra clave sólo parará de funcionar cuando tengas una banda completa de 40 personas. Si dejas la palabra clave en blanco desactivarás esta opción."
L.keywordDesc = "Cualquiera que te susurre esta palabra clave sera inmediata y automáticamente invitado a tu grupo."
L.guildKeyword = "Palabra clave de hermandad"
L.guildKeywordDesc = "Un miembro de la hermandad que te susurre esta palabra clave será inmediata y automáticamente invitado a tu grupo."
L.inviteGuild = "Invitar hermandad"
L.inviteGuildDesc = "Invita a cualquiera de tu hermandad con el nivel máximo."
L.inviteZone = "Invitar zona"
L.inviteZoneDesc = "Invita a cualquiera de tu hermandad que esté en la misma zona que tu."
L.guildRankInvites = "Invitaciones de hermandad por rango"
L.guildRankInvitesDesc = "Clicando cualquiera de los botones de abajo invitarás a cualquiera con el rango seleccionado Y SUPERIOR a tu grupo. Así que clicando en el 3er botón invitarás a cualquiera con rango 1, 2 o 3, por ejemplo. Primero mostrará un mensaje tanto en el chat de hermandad como en el de oficiales y dejará 10 segundos a los miembros para dejar sus grupos antes de hacer el invite masivo."
L.inviteInRaidOnly = "Sólo invitar con palabra clave si es un grupo de raid"

-- Promote module
L.demoteEveryone = "Degradar a todos"
L.demoteEveryoneDesc = "Degrada a todos en el grupo actual."
L.promote = "Promoc. a ayudante"
L.massPromotion = "Promocionar a ayudante masivamente"
L.promoteEveryone = "Todos"
L.promoteEveryoneDesc = "Promociona a ayudante a todos automáticamente"
L.promoteGuild = "Hermandad"
L.promoteGuildDesc = "Promociona a ayudante a todos los miembros de hermandad automáticamente."
L.byGuildRank = "Por rango de hermandad"
L.individualPromotions = "Promocionar a ayudante individualmente"
L.individualPromotionsDesc = "Ten en cuenta que los nombres distinguen mayúsculas. Para añadir un jugador, introduce el nombre del jugador en el recuadro de abajo y presiona Enter o clica el botón que aparece. Para quitar a un jugador que ha sido promocionado a ayudante automáticamente, sólo clica su nombre en la lista desplegable de abajo."
L.add = "Añadir"
L.remove = "Quitar"

-- Cooldowns module
L.openMonitor = "Abrir el monitor"
L.monitorSettings = "Ajustes del monitor"
L.showMonitor = "Mostrar monitor"
L.lockMonitor = "Bloquear el monitor"
L.showMonitorDesc = "Muestra u oculta la ventana de barras de CDs en el juego."
L.lockMonitorDesc = "Ten en cuenta que bloqueando el monitor de CDs ocultarás el título y el arrastre y lo harás imposible de mover, escalar o abrir la ventana de opciones de las barras."
L.onlyMyOwnSpells = "Sólo mostrar mis propios hechizos"
L.onlyMyOwnSpellsDesc = "Alternar si la ventana CDs sólo debe mostrar el CD de los hechizos lanzados por ti, básicamente funciona como un complemento de la ventana de CDs normal."
L.cooldownSettings = "Ajustes de CDs"
L.selectClassDesc = "Selecciona que CDs se mostrarán usando la lista desplegable y las casillas de abajo. Cada clase tiene un pequeño ajuste de hechizos disponible que puedes ver usando la ventana de barras. Selecciona una clase de la lista desplegable y configura los hechizos para cada clase de acuerdo cono tus propias necesidades."
L.selectClass = "Seleccionar clase"
L.neverShowOwnSpells = "Nunca mostrar mis propios hechizos"
L.neverShowOwnSpellsDesc = "Alternar si la ventana de CDs nunca debería mostrar tus CDs. Por ejemplo si usas otro addon de CDs para tus propios CDs."

-- monitor
L.rightClick = "Clic derecho en mí para opciones!"
L.barSettings = "Ajustes de barra"
L.labelTextSettings = "Ajustes de texto de etiqueta"
L.durationTextSettings = "Ajustes de texto de duración"
L.spawnTestBar = "Mostrar barra de prueba"
L.useClassColor = "Usar color de clase"
L.customColor = "Color personalizado"
L.height = "Altura"
L.scale = "Escala"
L.texture = "Textura"
L.icon = "Icono"
L.duration = "Duración"
L.unitName = "Nombre de unidad"
L.spellName = "Nombre de hechizo"
L.shortSpellName = "Nombre corto de hechizo"
L.font = "Fuente"
L.fontSize = "Tamaño de fuente"
L.labelAlign = "Alinear etiqueta"
L.left = "Izquierda"
L.right = "Derecha"
L.center = "Centro"
L.outline = "Contorno"
L.thick = "Grueso"
L.thin = "Delgado"
L.growUpwards = "Crecer"

-- Zone module
L.zone = "Zona"

-- Loot module
L.makeLootMaster = "Dejar vacío para asegurarte Maestro despojador"
L.autoLootMethodDesc = "Deja a oRA3 ajustar automáticamente el modo de loteo que tu especifiques para cuando entres a un grupo o raid."
L.autoLootMethod = "Ajustar automáticamente el modo de loteo cuando entres a un grupo."

-- Tanks module
L.tanks = "Tanques"
L.tankTabTopText = "Clica en la lista de abajo los jugadores para definirlos como tanques. Si quieres ayudar con todas las opciones aquí, entonces mueve el ratón sobre el signo de interrogación."
L.deleteButtonHelp = "Quitar de la lista de tanques. Ten en cuenta que una vez quitado no volverá a ser añadido en el resto de la sesión a menos que tu manualmente lo vuelvas a agregar."
L.blizzMainTank = "Tanque principal Blizzard"
L.tankButtonHelp = "Alternar si este tanque debería ser un tanque principal de Blizzard."
L.save = "Guardar"
L.saveButtonHelp = "Guarda este tanque en tu lista personal. Siempre que estés en grupo con este jugador, el será listado como un tanque personal."
L.whatIsThis = "¿Qué es todo esto?"
L.tankHelp = "La gente en la lista de los mejores tiene ordenados tus tanques personales. Ellos no serán compartidos con la raid, cualquiera puede tener su propia lista de tanques personales. Clicando un nombre en la lista de abajo agregará este a tu lista de tanques personales.\n\nClicando en el icono de escudo hará que esa persona sea un tanque principal de Blizzard. Los tanques principales de Blizzard son compartidos con el resto de la raid y tienes que ser ayudante para hacerlo.\n\nLos tanques que aparecen en la lista debido a que alguien los marca como tanques principales de Blizzard serán quitados de la lista cuando ellos dejen de ser tanques principales de Blizzard.\n\nUsa la marca verde de verificación para guardar un tanque entre sesiones. La próxima vez que estés en una raid con esa persona, el automáticamente será marcado como un tanque personal."
L.sort = "Corto"
L.moveTankUp = "Clic para mover arriba este tanque."
L.show = "Mostrar"
L.showButtonHelp = "Muestra este tanque en la ventana de tu lista personal de tanques. Esta opción sólo tiene efecto local y no cambiará el estado de este tanque para nadie en tu grupo."

-- Latency Module
L.latency = "Latencia"
L.home = "Local"
L.world = "Mundo"

-- Gear Module
L.gear = "Equipo"
L.itemLevel = "Nivel de equipo"
L.missingGems = "Gemas faltantes"
L.missingEnchants = "Encantamientos faltantes"

-- BattleRes Module
L.battleResTitle = "Monitor de Res en combate"
L.battleResLockDesc = "Activa el bloqueo del monitor. Esto ocultará el texto de cabecera, fondo, y previene que se mueva."
L.battleResShowDesc = "Cambia entre mostrar u ocultar el monitor."


