
if GetLocale() ~= "ptBR" then return end
local _, tbl = ...
local L = tbl.locale

-- Generic
L.name = "Nome"
L.checks = "Checar"
L.disbandGroup = "Debandar grupo"
L.disbandGroupDesc = "Debanda seu grupo ou raide, removendo todos do seu grupo, um por um, até que você seja o último.\n\nJá que isto é potencialmente muito destrutivo, você receberá um pedido de confirmação. Segure a tecla control para ignorar esta confirmação."
L.options = "Opções"
L.disbandingGroupChatMsg = "Desbandar grupo."
L.disbandGroupWarning = "Debandar grupo realmente?"
L.unknown = "Desconhecido"
L.profile = "Perfil"

-- Core

L.togglePane = "Alternar janela oRA3"
L.toggleWithRaid = "Abrir com janela de raide"
L.toggleWithRaidDesc = "Abre e fecha o oRA3 automaticamente com a janela de raide da Blizzard. Se você desabilitar esta opção ainda poderá abrir a janela oRA3 usando a tecla de atalho ou um dos comandos de barra, como por exemplo |cff44ff44/radur|r."
L.showHelpTexts = "Exibir ajuda da interface"
L.showHelpTextsDesc = "A interface oRA3 é repleta de textos de ajuda para melhor descrever o que se passa e o que diferentes elementos de interface fazem de fato. Desabilitar esta opção vai removê-los, limitando a poluição visual em cada painel. |cffff4411Requer recarregamento da interface.|r"
L.ensureRepair = "Certifica-se que reparos estejam disponibilizados para todos os postos presentes na raide."
L.ensureRepairDesc = "Se você é o Líder da Guilda, sempre que você se juntar a um grupo de raide e for o líder de raíde ou assistente, você certificar-se-á que reparos de guilda estejam disponíveis ao longo da raide (até 300g). Assim que você deixar o grupo, as configurações serão restaurados ao seu estado original |cffff4411contanto que você não tenha bugado durante a raide.|r"
L.repairEnabled = "Habilita reparos de guilda para %s pela duração desta raide."
L.showRoleIcons = "Exibir ícones de função na janela de raide"
L.showRoleIconsDesc = "Exibir ícones de função e o total para cada função na janela de raide da Blizzard. Você terá que abrir a janela de raide novamente para que essas mudanças tenham efeito."

L.slashCommandsHeader = "Comandos de barra"
L.slashCommands = [[
oRA3 disponibiliza uma série de comandos de barra para te ajudar em um ritmo acelerado de raide. Caso você não tenha usado nos tempos do CTRA, aqui vai uma pequena referência. Todos os comandos de barra possuem diversos versões mais curtas ou longas, alternativas mais descritivas em alguns casos, para sua conveniência.

|cff44ff44/radur|r - Abre a lista de durabilidade.
|cff44ff44/ragear|r - Abre a guia de verificação de gear.
|cff44ff44/ralag|r - Abre a lista de latência.
|cff44ff44/razone|r - Abre a lista de zonas.
|cff44ff44/radisband|r - Instantaneamente debanda a raide sem verificação.
|cff44ff44/raready|r - Verifica se todos estão prontos.
|cff44ff44/rainv|r - Convida toda a guilda para seu grupo.
|cff44ff44/razinv|r - Convida membros da guilda na mesma zona que você.
|cff44ff44/rarinv <nome-do-posto>|r - Convida membros da guilda de um dado posto.
]]

-- Ready check module
L.notReady = "Os seguintes jogadores não estão prontos: %s"
L.readyCheckSeconds = "Todos prontos? (%d segundos)"
L.ready = "Pronto"
L.notReady = "Ainda não"
L.noResponse = "Sem Resposta"
L.offline = "Desconectado"
L.readyCheckSound = "Toca o som de \"Todos prontos?\" usando o canal principal. Isso fará com que o som toque mais alto e até mesmo quando os \"Efeitos sonoros\" estiverem desabilitados."
L.showWindow = "Exibir janela"
L.showWindowDesc = "Exibir a janela quando o \"Todos prontos?\" for realizado."
L.hideWhenDone = "Fecha a janela quando concluído."
L.hideWhenDoneDesc = "Automaticamente fecha a janela quando \"Todos prontos?\" for concluído."
L.hideReadyPlayers = "Ocultar jogadores que estão prontos"
L.hideReadyPlayersDesc = "Ocultar jogadores que estão marcados como pronto"
L.hideInCombatDesc = "Automaticamente esconde a janela de \"Todos prontos?\" quando entrar em combate."
L.hideInCombat = "Ocultar em combate"
L.printToRaid = "Repassar o resultado de \"Todos prontos?\" para o chat de raide"
L.printToRaidDesc = "Se você tiver assistência, repassa os resultados do \"Todos prontos?\" para o chat de raide, permitindo que os membros vejam o que está atrasando. Por favor certifique-se que apenas uma pessoa tem isso desabilitado."

-- Durability module
L.durability = "Durabilidade"
L.average = "Média"
L.broken = "Quebrado"
L.minimum = "Mínimo"

-- Invite module
L.invite = "Convidar"
L.invitePrintMaxLevel = "Todos os personagens de nível máximo serão convidados para a raide em 10 segundos. Deixem seus grupos, por favor."
L.invitePrintZone = "Todos os personagens em %s serão convidados para a raide em 10 segundos. Deixem seus grupos, por favor."
L.invitePrintRank = "Todos os personagens do posto %s ou superior serão convidados para a raide em 10 segundos. Deixem seus grupos, por favor."
L.invitePrintGroupIsFull = "Grupo cheio, sinto muito."
L.inviteGuildRankDesc = "Convida todos os membros da guilda do posto %s ou superior."
L.keyword = "Palavra-chave"
L.inviteDesc = "Quando alguém te sussurrar a palavra-chave abaixo, eles serão automaticamente convidados para seu grupo. Essas palavras só irão parar de funcionar quando você tiver uma raide completa de 40 pessoas. Atribuir uma palavra-chave em branco irá desabilitá-la."
L.keywordDesc = "Qualquer um que sussurrar você com essa palavra-chave será automatica e imediatamente convidado para seu grupo."
L.guildKeyword = "Palavra-chave da Guilda"
L.guildKeywordDesc = "Qualquer membro da guilda que te sussurre esta palavra-chave será automatica e imediatamente convidado para seu grupo."
L.inviteGuild = "Convidar guilda"
L.inviteGuildDesc = "Convidad todos em sua guilda no nível máximo."
L.inviteZone = "Convidar zona"
L.inviteZoneDesc = "Convidar todos em sua guilda que estão na mesma zona que você."
L.guildRankInvites = "Convites por Posto de Guilda"
L.guildRankInvitesDesc = "Clicar em qualquer um desses botões irá convidar qualquer um do posto selecionado E SUPERIORES para seu grupo. Então clicar no terceiro botão irá convidar qualquer um dos postos 1, 2 e 3, por exemplo. Isto colocará primeiramente uma mensagem no chat da guilda ou oficiais e dar aos membros da sua guilda 10 segundos para deixarem seus grupos antes de enviar os convites."
L.inviteInRaidOnly = "Apenas quando em grupo de raide.."

-- Promote module
L.demoteEveryone = "Demover todos"
L.demoteEveryoneDesc = "Demove todos no seu grupo atual."
L.promote = "Promover"
L.massPromotion = "Promoção em massa"
L.promoteEveryone = "Todos"
L.promoteEveryoneDesc = "Promover todos automaticamente."
L.promoteGuild = "Guilda"
L.promoteGuildDesc = "Promove todos os membros da guilda automaticamente."
L.byGuildRank = "Por posto na guilda"
L.individualPromotions = "Promoções individuais"
L.individualPromotionsDesc = "Note que nomes são sensíveis a caixa. Para adicionar um jogador, entre o nome do jogador na caixa abaixo e tecle Enter ou clique no botão que aparecerá. Para remover um jogador da promoção automática, apenas clique em seu nome na caixa de listagem abaixo."
L.add = "Adicionar"
L.remove = "Remover"

-- Cooldowns module
L.openMonitor = "Abrir monitor"
L.monitorSettings = "Convigurações do Monitor"
L.showMonitor = "Exibir monitor"
L.lockMonitor = "Travar monitor"
L.showMonitorDesc = "Exibe ou esconde o quadro de barra de cooldown no mundo do jogo."
L.lockMonitorDesc = "Note que travar o monitor de cooldown irá esconder o título e a alça para arrastar, tornando impossível movê-lo, redimensioná-lo ou abrir as opções para as barras."
L.onlyMyOwnSpells = "Exibir apenas minhas próprias habilidades"
L.onlyMyOwnSpellsDesc = "Alterna quando o quadro de cooldown deve mostrar apenas habilidades lançadas por você, funcionando basicamente como um addon convencional de exibição de cooldown."
L.cooldownSettings = "Configurações de Cooldown"
L.selectClassDesc = "Seleciona quais cooldowns exibir usando a caixa de listagem veficação abaixo. Cada classe tem um pequeno conjunto de habilidades disponíveis que você pode visualizar usando o quadro de barra. Selecione uma classe na caixa de listagem e então configure as havilidaeds para aquela classe de acordo com suas necessidades."
L.selectClass = "Classe"
L.neverShowOwnSpells = "Nunca exibir minhas próprias habilidades"
L.neverShowOwnSpellsDesc = "Alternar quando o quadro de cooldown jamais deve exibir seus próprios cooldowns. Por exemplo se você usar outro addon para exibir seus próprios cooldowns."

-- monitor
L.cooldowns = "Cooldowns"
L.rightClick = "Clique-direito para opções!"
L.barSettings = "Configurações de Barra"
L.labelTextSettings = "Configurações para rótulo de texto"
L.durationTextSettings = "Configurações para Texto de Duração"
L.spawnTestBar = "Lançar barra de teste"
L.useClassColor = "Usar cor da classe"
L.customColor = "Cor personalizada"
L.height = "Altura"
L.scale = "Escala"
L.texture = "Textura"
L.icon = "Ícone"
L.duration = "Duração"
L.unitName = "Nome de Unidade"
L.spellName = "Nome da habilidade"
L.shortSpellName = "Nome reduzido"
L.font = "Fonte"
L.fontSize = "Tamanho da Fonte"
L.labelAlign = "Alinhamento do rótulo"
L.left = "Esquerda"
L.right = "Direita"
L.center = "Centro"
L.outline = "Contorno"
L.thick = "Grosso"
L.thin = "Fino"
L.growUpwards = "Aumentar"

-- Zone module
L.zone = "Zona"

-- Loot module
L.makeLootMaster = "Deixe em b ranco para fazer de você o Mestre Saqueador"
L.autoLootMethodDesc = "Permite que o oRA3 ajuste automaticamente o método de saque para o qual especificar abaixo sempre que entrar em um grupo ou raide."
L.autoLootMethod = "Ajuste o método de saque automaticamente quando se juntar a um grupo"

-- Tanks module
L.tanks = "Tanques"
L.tankTabTopText = "Clique em jogadores na lista abaixo para torná-los seus tanques pessoais. Se você quiser ajuda com todas as opções aqui então mova seu mouse sobre o ponto de interrogação."
L.deleteButtonHelp = "Remove da lista de tanques. Note que assim que sejam removidos eles não será adicionados novamente pelo restante dessa sessão, a menos que você o faça manualmente."
L.blizzMainTank = "Tanque Principal Blizzard"
L.tankButtonHelp = "Determina se este tanque deve ser um Tanque Principal Blizzard."
L.save = "Salvar"
L.saveButtonHelp = "Salva este tanque em sua lista pessoal. Sempre que estiver em grupo com este jogador ele será listado como um tanque pessoal."
L.whatIsThis = "O que é tudo isso?"
L.tankHelp = "As pessoas no topo da lista são seus tanques pessoais. Eles não são divididos com a raide, e todos podem ter listas pessoais diferentes. Clicar em u nome na lista inferior adiciona um tanque na sua lista pessoal.\n\nClicar on escudo irá tornar tal pessoa em um Tanque Principal Blizzard. Tanques Blizzard são compartilhados entre todos os membros de sua raide e você precisa de assistência para acertar isto.\n\nTanques que aparecen na lista porque outrem o tornou Tanque Principal Blizzard serão removidos da lista quando não o forem mais.\n\nUse a marca de checar verdade para lembrar um tanque entre sessões. A próxima vez que você estiver em uma raide com tal pessoa, ela será automaticamente ajustada como um tanque pessoal."
L.sort = "Ordenar"
L.moveTankUp = "Clique para mover este tanque para cima."
L.show = "Exibir"
L.showButtonHelp = "Exibir este tanque em sua lista pessoal de tanques. Esta opção só tem efeito local e não irá alterar a condição desses tanques para qualquer outra pessoa em seu grupo."

-- Latency Module
L.latency = "Latência"
L.home = "Local"
L.world = "Global"

-- Gear Module
L.gear = "Gear"
L.itemLevel = "Nível de Item"
L.missingGems = "Gemas Faltando"
L.missingEnchants = "Encant. Faltando"

-- BattleRes Module
L.battleResTitle = "Monitor de Battle Res"
L.battleResLockDesc = "Ajusta trava do monitor. Isto ira esconder o texto de cabeçalho, fundo e previnir movimento."
L.battleResShowDesc = "Exibir ou esconder o monitor."

