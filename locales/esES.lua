
if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end
local _, tbl = ...
local L = tbl.locale

L["add"] = "Añadir"
L["align"] = "Alineación" -- Needs review
L["allSpells"] = "Todos los hechizos seleccionados" -- Needs review
L["average"] = "Promedio"
L["backgroundColor"] = "Color de fondo" -- Needs review
L["barDisplay"] = "Barras" -- Needs review
L["barDisplayDesc"] = "Visualización de barra simple." -- Needs review
L["barSettings"] = "Ajustes de barra"
L["battleResHeader"] = "El monitor solo se mostrará mientras estás en un grupo en una estancia de banda." -- Needs review
L["battleResLockDesc"] = "Activa el bloqueo del monitor. Esto ocultará el texto de cabecera, fondo y previene que se mueva." -- Needs review
L["battleResShowDesc"] = "Cambia entre mostrar u ocultar el monitor."
L["battleResTitle"] = "Monitor de Res en combate"
L["blizzMainTank"] = "Tanque principal Blizzard"
L["broken"] = "Roto"
-- L["buffs"] = "Buffs"
L["byGuildRank"] = "Por rango de hermandad"
L["center"] = "Centro"
-- L["checkBuffs"] = "Check Buffs"
-- L["checkBuffsDesc"] = "Include raid buffs when checking buffs."
-- L["checkFlaskDesc"] = "Include flasks when checking buffs."
-- L["checkFoodDesc"] = "Include food buffs when checking buffs."
-- L["checkReadyCheck"] = "Check on ready check"
-- L["checkReadyCheckDesc"] = "Check buffs when a ready check is performed when promoted in a non-LFG instance group."
-- L["checkRuneDesc"] = "Include augment runes when checking buffs."
L["checks"] = "Compr." -- Needs review
L["classColorBorder"] = "Bordes de color de clase" -- Needs review
L["clear"] = "Limpiar" -- Needs review
-- L["consumables"] = "Consumable Check"
L["cooldowns"] = "CDs" -- Needs review
L["cooldownsEnableDesc"] = "Desactivando este módulo lo prevendrá de usar cualquier recursos para hacer un seguimiento de los CDs mientras se esté en un grupo." -- Needs review
L["copyDisplay"] = "|cff02ff02Copiar %s|r" -- Needs review
L["createNewDisplay"] = "|cff02ff02Crear nueva visualización|r" -- Needs review
L["customColor"] = "Color personalizado"
L["dead"] = "muerto" -- Needs review
L["deleteButtonHelp"] = "Quitar de la lista de tanques. Ten en cuenta que una vez quitado no volverán a ser añadidos en el resto de la sesión a menos que tu manualmente lo vuelvas a agregar." -- Needs review
L["deleteDisplay"] = "|cffff0202Borrar %s|r" -- Needs review
L["demoteEveryone"] = "Degradar a todos"
L["demoteEveryoneDesc"] = "Degrada a todos en el grupo actual."
L["direction"] = "Dirección" -- Needs review
L["directionThen"] = "%s entonces %s" -- Needs review
L["disabledAlpha"] = "Transparencia de barra desactivada" -- Needs review
L["disbandGroup"] = "Disolver grupo"
L["disbandGroupDesc"] = [=[Disuelve tu grupo o banda actual, expulsando a cada uno de tu grupo, uno a uno, hasta que seas el último restante.
Esto es algo potencialmente muy destructivo, se mostrará un diálogo de confirmación. Presiona la tecla Control para saltar este diálogo.]=] -- Needs review
L["disbandGroupWarning"] = "¿Estás seguro que quieres disolver tu grupo?"
L["disbandingGroupChatMsg"] = "Disolviendo grupo." -- Needs review
L["displayTypes"] = "Tipos de visualizaciones" -- Needs review
L["down"] = "Abajo" -- Needs review
L["durability"] = "Durabilidad"
L["duration"] = "Duración"
L["durationTextSettings"] = "Ajustes de duración del texto" -- Needs review
L["fill"] = "Llenar barra" -- Needs review
L["filtersDesc"] = "Establecer qué excluir de mostrar." -- Needs review
-- L["flask"] = "Flask"
-- L["flaskExpires"] = "Your flask is expiring in less than 10 minutes"
L["font"] = "Fuente"
L["fontSize"] = "Tamaño de fuente"
-- L["food"] = "Food"
L["gap"] = "Margen entre barras" -- Needs review
L["gear"] = "Equipo"
-- L["group"] = "Group"
L["groupSpells"] = "Mantener los hechizos ordenados por clase" -- Needs review
L["growUpwards"] = "Crecer hacia arriba" -- Needs review
L["guildKeyword"] = "Palabra clave de hermandad"
L["guildKeywordDesc"] = "Un miembro de la hermandad que te susurre esta palabra clave será inmediatamente y automáticamente invitado a tu grupo." -- Needs review
L["guildRankInvites"] = "Invitaciones de hermandad por rango"
L["guildRankInvitesDesc"] = "Clicando cualquiera de los botones de abajo invitarás a cualquiera con el rango seleccionado Y SUPERIOR a tu grupo. Así que clicando en el 3er botón invitarás a cualquiera con rango 1, 2 o 3, por ejemplo. Primero mostrará un mensaje tanto en el chat de hermandad como en el de oficiales y dejará 10 segundos a los miembros para dejar sus grupos antes de hacer el invite masivo." -- Needs review
L["height"] = "Altura"
L["hideDead"] = "Ocultar muertos" -- Needs review
L["hideGroupDesc"] = "Ocultar CDs de jugadores en este grupo." -- Needs review
L["hideInCombat"] = "Ocultar en combate"
L["hideInCombatDesc"] = "Automáticamente oculta la ventana de comprobar listos cuando entras en combate."
-- L["hideInGroupDesc"] = "Hide cooldowns in this type of group."
L["hideInInstanceDesc"] = "Ocultar CDs en este tipo de instancia." -- Needs review
L["hideOffline"] = "Ocultar desconectados" -- Needs review
L["hideOutOfCombat"] = "Ocultar fuera de combate" -- Needs review
L["hideOutOfRange"] = "Ocultar fuera de rango" -- Needs review
L["hideReadyPlayers"] = "Ocultar jugadores que estén listos"
L["hideReadyPlayersDesc"] = "Ocultar jugadores que están marcados como listos de la ventana."
L["hideRolesDesc"] = "Ocultar CDs de jugadores en este rol" -- Needs review
L["hideWhenDone"] = "Oculta la ventana cuando termine"
L["hideWhenDoneDesc"] = "Automáticamente oculta la ventana cuando el comprobar listos haya finalizado."
L["home"] = "Local"
L["icon"] = "Icono"
L["iconDisplay"] = "Iconos" -- Needs review
L["iconDisplayDesc"] = "Visualización de iconos simple" -- Needs review
L["iconGroupDisplay"] = "Grupos de iconos" -- Needs review
L["iconGroupDisplayDesc"] = "Mostrar todos los lanzamientos de un hechizo juntos en un icono." -- Needs review
L["individualPromotions"] = "Promocionar a ayudante individualmente"
L["individualPromotionsDesc"] = "Ten en cuenta que los nombres distinguen mayúsculas. Para añadir un jugador, introduce el nombre del jugador en el recuadro de abajo y presiona Intro o clica el botón que aparece. Para quitar a un jugador que ha sido promocionado a ayudante automáticamente, sólo clica su nombre en la lista desplegable de abajo." -- Needs review
L["invite"] = "Invitar"
L["inviteDesc"] = "Cuando la gente te susurre la palabra clave de abajo, serán invitados automáticamente a tu grupo. Si estás en un grupo y está completo, convertirás el grupo a una banda. La palabra clave sólo parará de funcionar cuando tengas una banda completa de 40 personas. Si dejas la palabra clave en blanco desactivarás esta opción."
L["inviteGuild"] = "Invitar hermandad"
L["inviteGuildDesc"] = "Invita a cualquiera de tu hermandad con el nivel máximo."
L["inviteGuildRankDesc"] = "Invita a todos los miembros de la hermandad de rango %s o superior." -- Needs review
L["inviteInRaidOnly"] = "Sólo invitar con palabra clave si es un grupo de banda" -- Needs review
--L.inviteGroupIsFull = "The group is currently full."
L["invitePrintMaxLevel"] = "Todos los jugadores con el nivel máximo serán invitados a la banda en 10 segundos. Por favor, dejad vuestros grupos."
L["invitePrintRank"] = "Todos los jugadores con rango %s o superior serán invitados a la banda en 10 segundos. Por favor, dejad vuestros grupos."
-- L["invitePrintRankOnly"] = "All characters of rank %s will be invited to raid in 10 seconds. Please leave your groups."
L["invitePrintZone"] = "Todos los jugadores en %s serán invitados a la banda en 10 segundos. Por favor, dejad vuestros grupos."
L["inviteZone"] = "Invitar zona"
L["inviteZoneDesc"] = "Invita a cualquiera de tu hermandad que esté en la misma zona que tu."
L["itemLevel"] = "Nivel de equipo"
L["keyword"] = "Palabra clave"
L["keywordDesc"] = "Cualquiera que te susurre esta palabra clave sera inmediatamente y automáticamente invitado a tu grupo." -- Needs review
-- L["keywordMultiDesc"] = "You can use multiple keywords by separating them with a ; (semicolon)."
L["labelTextSettings"] = "Ajustes de texto de etiqueta"
L["latency"] = "Latencia"
L["left"] = "Izquierda"
L["lockMonitor"] = "Bloquear el monitor"
L["lockMonitorDesc"] = "Ten en cuenta que bloqueando el monitor de tiempos de reutilización ocultarás el título, el arrastre y lo harás imposible de mover, escalar o abrir la ventana de opciones de las barras." -- Needs review
L["logDisplay"] = "Registro" -- Needs review
L["logDisplayDesc"] = "Un simple marco donde los mensajes son enviados cuando se usa un hechizo." -- Needs review
L["massPromotion"] = "Promocionar a ayudante masivamente"
L["minimum"] = "Mínimo"
-- L["missingBuffs"] = "Missing Buffs"
L["missingEnchants"] = "Encantamientos faltantes"
L["missingGems"] = "Gemas faltantes"
L["moveTankUp"] = "Clica para mover arriba este tanque." -- Needs review
L["name"] = "Nombre"
L["neverShowOwnSpells"] = "Nunca mostrar mis propios hechizos"
L["neverShowOwnSpellsDesc"] = "Alternar si la ventana de tiempos de reutilización nunca debería mostrar los tuyos. Por ejemplo si usas otro accesorio para mostrar los tuyos." -- Needs review
-- L["noFlask"] = "No Flask"
-- L["noFood"] = "Not Well Fed"
L["noResponse"] = "Sin respuesta" -- Needs review
-- L["noRune"] = "No Augment Rune"
L["noSpells"] = "¡No se han seleccionado hechizos!" -- Needs review
-- L["notBestBuff"] = "Not the highest stat consumable available"
-- L["notInRaid"] = "You are not in a raid instance."
L["notReady"] = "No listos"
L["offline"] = "Desconectado"
L["onlyMyOwnSpells"] = "Sólo mostrar mis propios hechizos"
L["onlyMyOwnSpellsDesc"] = "Alternar si la ventana CDs sólo debe mostrar el CD de los hechizos lanzados por ti, básicamente funciona como un complemento de la ventana de CDs normal."
L["options"] = "Opciones"
L["outline"] = "Contorno"
-- L["outOfRange"] = "Player out of range"
-- L["output"] = "Output"
-- L["outputDesc"] = "Display results in group chat, otherwise results are printed to your default chat frame."
-- L["outputMissing"] = "Output Missing"
L["playersNotReady"] = "Los siguientes jugadores no están listos: %s" -- Needs review
L["playerStatus"] = "Estado de Jugador" -- Needs review
L["popupConvertDisplay"] = "¡Cambiando el tipo de visualización reiniciará las opciones especificas!" -- Needs review
L["popupDeleteDisplay"] = "¿Borrar visualización '%s'?" -- Needs review
L["popupNameError"] = [=[Ya hay una visualización llamada '%s'.
Por favor, elige otro nombre.]=] -- Needs review
L["popupNewDisplay"] = "Introduce el nombre para la nueva visualización" -- Needs review
L["printToRaid"] = "Mostrar los resultados del comprobar listos al chat de banda" -- Needs review
L["printToRaidDesc"] = "Si eres ayudante, mostrar los resultados del comprobar listos en el chat de banda, permitiendo a los miembros ver quien está listo o no. Por favor asegúrate que sólo una persona tenga esta opción activada." -- Needs review
L["profile"] = "Perfil"
L["promote"] = "Promoc. a ayudante"
L["promoteEveryone"] = "Todos"
L["promoteEveryoneDesc"] = "Promociona a ayudante a todos automáticamente"
L["promoteGuild"] = "Hermandad"
L["promoteGuildDesc"] = "Promociona a ayudante a todos los miembros de hermandad automáticamente."
-- L["raidBuffs"] = "Raid Buffs"
-- L["raidCheck"] = "Raid Check"
L["range"] = "rango" -- Needs review
L["ready"] = "Listos"
-- L["readyByGroup"] = "Relay ready check results based on raid difficulty"
-- L["readyByGroupDesc"] = "Ignore players that are in groups outside of the max player size for the instance difficulty, for example, ignore players in groups 5-8 in Mythic mode raids. The ready check will finish when all of the players in relevant groups are ready."
L["readyCheckSeconds"] = "Comprobar listos (%d segundos)"
L["readyCheckSound"] = "Reproduce el sonido de comprobar listos usando el canal principal de sonido cuando un comprobar listos es ejecutado. Esto reproducirá el sonido mientras \"Efectos de sonido\" está desactivado y con un volumen más alto."
L["remove"] = "Quitar"
-- L["reportAlways"] = "Report always"
-- L["reportIfYou"] = "Report if started by you"
L["right"] = "Derecha"
L["rightClick"] = "¡Clic derecho en mí para opciones!" -- Needs review
-- L["rune"] = "Rune"
L["save"] = "Guardar"
L["saveButtonHelp"] = "Guarda este tanque en tu lista personal. Siempre que estés en grupo con este jugador, él será listado como un tanque personal." -- Needs review
L["scale"] = "Escala"
L["selectClass"] = "Seleccionar clase"
L["selectClassDesc"] = "Selecciona cuáles de tus tiempos de reutilización se mostrarán usando la lista desplegable y las casillas de abajo. Cada clase tiene un pequeño ajuste de hechizos disponible que puedes ver usando la ventana de barras. Selecciona una clase de la lista desplegable y configura los hechizos para cada clase de acuerdo con tus propias necesidades." -- Needs review
-- L["self"] = "Self"
L["shortSpellName"] = "Nombre corto de hechizo"
L["show"] = "Mostrar"
-- L["showBuffs"] = "Show buffs"
--[==[ L["showBuffsDesc"] = [=[Show icons for food, flask, and rune buffs for each player and text below the ready check frame for missing raid buffs.

|cffffff33Show missing buffs|r will only show icons if the player is missing buffs.

|cffffff33Show current buffs|r will only show icons for buffs a player has.]=] ]==]
L["showButtonHelp"] = "Muestra este tanque en la ventana de tu lista personal de tanques. Esta opción sólo tiene efecto local y no cambiará el estado de este tanque para nadie en tu grupo."
L["showCooldownText"] = "Mostrar texto de CD" -- Needs review
L["showCooldownTextDesc"] = "Mostrar el texto de CD de Blizzard" -- Needs review
-- L["showCurrentBuffs"] = "Show current buffs"
L["showHelpTexts"] = "Mostrar ayuda"
L["showHelpTextsDesc"] = "La interfaz de ayuda de oRA3 es muy útil, su intención es describir mejor que hace cada cosa y que están haciendo acualmente cada elemento de la interfaz. Desactivando esta opción los eliminarás, limitando la confusión en cada panel. |cffff4411Requiere recargar la interfaz en algunos paneles.|r"
-- L["showMissingBuffs"] = "Show missing buffs"
-- L["showMissingMaxStat"] = "Show lesser consumables as missing"
-- L["showMissingMaxStatDesc"] = "Show icons for food and flask buffs with a different color to indicate it is not the highest stat value available."
-- L["showMissingRunes"] = "Show Augment Runes"
-- L["showMissingRunesDesc"] = "Include showing an icon for Augment Rune buffs."
L["showMonitor"] = "Mostrar monitor"
L["showMonitorDesc"] = "Muestra u oculta la ventana de barras de tiempos de reutilización en el juego." -- Needs review
L["showOffCooldown"] = "Mostrar hechizos que no están en tiempo de reutilización" -- Needs review
L["showRoleIcons"] = "Mostrar iconos de rol en el panel de raid"
L["showRoleIconsDesc"] = "Muestra iconos de rol y la cantidad total de cada uno en el panel de banda de Blizzard. Necesitarás reabrir el panel de banda para que los cambios tengan efecto." -- Needs review
-- L["showVantus"] = "Show Vantus Runes"
-- L["showVantusDesc"] = "Include showing an icon for Vantus Rune buffs. This icon will always be shown if the player has a Vantus Rune buff."
L["showWindow"] = "Mostrar ventana"
L["showWindowDesc"] = "Muestra la ventana cuando un comprobar listos es ejecutado."
L["skin"] = "Tema Masque" -- Needs review
L["slashCommands"] = [=[oRA3 tiene una serie de comandos que agilizan la tarea de administrar la banda. En el caso de que no esté familiarizado con el viejo CTRA, aquí se muestra una pequeña referencia. Todos los comandos tienen formas cortas y otras más largas, alternativas más descriptivas en algunos casos, según sea conveniente.

|cff44ff44/radur|r - Abre el panel de durabilidad.
|cff44ff44/ragear|r - Abre el panel de chequeo de equipo.
|cff44ff44/ralag|r - Abre el panel de latencia.
|cff44ff44/razone|r - Abre el panel de zona.
|cff44ff44/radisband|r - Disuelve la banda instantáneamente sin verificación.
|cff44ff44/raready|r - Realiza un Comprobar listos.
|cff44ff44/rainv|r - Invita a toda la hermandad a tu grupo.
|cff44ff44/razinv|r - Invita a los miembros de hermandad que están en la misma zona que tu.
|cff44ff44/rarinv <rank name>|r - Invita a los miembros de hermandad de un rango determinado.
]=] -- Needs review
L["slashCommandsHeader"] = "Comandos"
L["sort"] = "Ordenar" -- Needs review
L["spacing"] = "Espaciado" -- Needs review
L["spellName"] = "Nombre de hechizo"
L["spellTooltip"] = "Mostrar descripciones emergentes de hechizos" -- Needs review
-- L["statusColor"] = "Status color"
L["style"] = "Estilo de barra" -- Needs review
L["tankButtonHelp"] = "Alternar si este tanque debería ser un tanque principal de Blizzard."
L["tankHelp"] = [=[
La gente en la lista superior son tus tanques personales ordenados.. Ellos no serán compartidos con la banda, cualquiera puede tener su propia lista de tanques personales. Haciendo clic sobre un nombre en la lista de abajo agregará a ese a tu lista de tanques personales.

Haciendo clic en el icono de escudo hará que esa persona sea un tanque principal de Blizzard. Los tanques principales de Blizzard son compartidos con el resto de la banda y tienes que ser ayudante para hacerlo.

Los tanques que aparecen en la lista debido a que alguien los marca como tanques principales de Blizzard serán quitados de la lista cuando ellos dejen de serlo.

Usa la marca verde de verificación para guardar un tanque entre sesiones. La próxima vez que estés en una banda con esa persona, él automáticamente será marcado como un tanque personal.]=] -- Needs review
L["tanks"] = "Tanques"
L["tankTabTopText"] = "Haz clic en la lista de abajo los jugadores para definirlos como tanques. Si quieres ayuda con todas las opciones de aquí, entonces mueve el ratón sobre el signo de interrogación." -- Needs review
L["test"] = "Test" -- Needs review
L["texture"] = "Textura"
L["thick"] = "Grueso"
L["thin"] = "Delgado"
L["timestamp"] = "Marca de tiempo" -- Needs review
L["timeVisible"] = "Tiempo visible (0 = siempre)" -- Needs review
-- L["toggleMonitor"] = "Toggle monitor"
L["togglePane"] = "Panel oRA3 activado/desactivado" -- Needs review
L["toggleWithRaid"] = "Abrir con el panel de banda" -- Needs review
L["toggleWithRaidDesc"] = "Abre y cierra el panel de oRA3 automáticamente con el panel de banda de Blizzard. Si desactivas esta opción puedes seguir abriendo el panel de oRA3 usando comandos, como por ejemplo |cff44ff44/radur|r." -- Needs review
L["unitName"] = "Nombre de unidad"
L["unknown"] = "Desconocido"
L["up"] = "Arriba" -- Needs review
L["useClassColor"] = "Usar color de clase"
-- L["useStatusColor"] = "Use status color"
-- L["useStatusColorDesc"] = "Change the bar color when a player is out of range, dead, or offline."
L["vantus"] = "Vantus"
L["whatIsThis"] = "¿Qué es todo esto?"
-- L["whisperMissing"] = "Whisper missing"
-- L["whisperMissingDesc"] = "Whisper players that are missing buffs."
L["world"] = "Mundo"
L["zone"] = "Zona"
