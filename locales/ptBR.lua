local L = LibStub("AceLocale-3.0"):NewLocale("oRA3", "ptBR")
if not L then return end

-- Generic
L["Name"] = "Nome"
L["Checks"] = "Checar"
L["Disband Group"] = "Debandar grupo"
L["Disbands your current party or raid, kicking everyone from your group, one by one, until you are the last one remaining.\n\nSince this is potentially very destructive, you will be presented with a confirmation dialog. Hold down Control to bypass this dialog."] = "Debanda seu grupo ou raide, removendo todos do seu grupo, um por um, até que você seja o último.\n\nJá que isto é potencialmente muito destrutivo, você receberá um pedido de confirmação. Segure a tecla control para ignorar esta confirmação."
L["Options"] = "Opções"
L["<oRA3> Disbanding group."] = "<oRA3> Desbandar grupo."
L["Are you sure you want to disband your group?"] = "Debandar grupo realmente?"
L["Unknown"] = "Desconhecido"
L["Profile"] = "Perfil"

-- Core

L["Toggle oRA3 Pane"] = "Alternar janela oRA3"
L["Open with raid pane"] = "Abrir com janela de raide"
L.toggleWithRaidDesc = "Abre e fecha o oRA3 automaticamente com a janela de raide da Blizzard. Se você desabilitar esta opção ainda poderá abrir a janela oRA3 usando a tecla de atalho ou um dos comandos de barra, como por exemplo |cff44ff44/radur|r."
L["Show interface help"] = "Exibir ajuda da interface"
L.showHelpTextsDesc = "A interface oRA3 é repleta de textos de ajuda para melhor descrever o que se passa e o que diferentes elementos de interface fazem de fato. Desabilitar esta opção vai removê-los, limitando a poluição visual em cada painel. |cffff4411Requer recarregamento da interface.|r"
L["Ensure guild repairs are enabled for all ranks present in raid"] = "Certifica-se que reparos estejam disponibilizados para todos os postos presentes na raide."
L.ensureRepairDesc = "Se você é o Líder da Guilda, sempre que você se juntar a um grupo de raide e for o líder de raíde ou assistente, você certificar-se-á que reparos de guilda estejam disponíveis ao longo da raide (até 300g). Assim que você deixar o grupo, as configurações serão restaurados ao seu estado original |cffff4411contanto que você não tenha bugado durante a raide.|r"
L.repairEnabled = "Habilita reparos de guilda para %s pela duração desta raide."
L["Show role icons on raid pane"] = "Exibir ícones de função na janela de raide"
L.showRoleIconsDesc = "Exibir ícones de função e o total para cada função na janela de raide da Blizzard. Você terá que abrir a janela de raide novamente para que essas mudanças tenham efeito."

L["Slash commands"] = "Comandos de barra"
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
L["The following players are not ready: %s"] = "Os seguintes jogadores não estão prontos: %s"
L["Ready Check (%d seconds)"] = "Todos prontos? (%d segundos)"
L["Ready"] = "Pronto"
L["Not Ready"] = "Ainda não"
L["No Response"] = "Sem Resposta"
L["Offline"] = "Desconectado"
L["Play the ready check sound using the Master sound channel when a ready check is performed. This will play the sound while \"Sound Effects\" is disabled and at a higher volume."] = "Toca o som de \"Todos prontos?\" usando o canal principal. Isso fará com que o som toque mais alto e até mesmo quando os \"Efeitos sonoros\" estiverem desabilitados."
L["Show window"] = "Exibir janela"
L["Show the window when a ready check is performed."] = "Exibir a janela quando o \"Todos prontos?\" for realizado."
L["Hide window when done"] = "Fecha a janela quando concluído."
L["Automatically hide the window when the ready check is finished."] = "Automaticamente fecha a janela quando \"Todos prontos?\" for concluído."
L["Hide players who are ready"] = "Ocultar jogadores que estão prontos"
L["Hide players that are marked as ready from the window."] = "Ocultar jogadores que estão marcados como pronto"
L["Automatically hide the ready check window when you get in combat."] = "Automaticamente esconde a janela de \"Todos prontos?\" quando entrar em combate."
L["Hide in combat"] = "Ocultar em combate"
L["Relay ready check results to raid chat"] = "Repassar o resultado de \"Todos prontos?\" para o chat de raide"
L["If you are promoted, relay the results of ready checks to the raid chat, allowing raid members to see what the holdup is. Please make sure yourself that only one person has this enabled."] = "Se você tiver assistência, repassa os resultados do \"Todos prontos?\" para o chat de raide, permitindo que os membros vejam o que está atrasando. Por favor certifique-se que apenas uma pessoa tem isso desabilitado."

-- Durability module
L["Durability"] = "Durabilidade"
L["Average"] = "Média"
L["Broken"] = "Quebrado"
L["Minimum"] = "Mínimo"

-- Invite module
L["Invite"] = "Convidar"
L["All max level characters will be invited to raid in 10 seconds. Please leave your groups."] = "Todos os personagens de nível máximo serão convidados para a raide em 10 segundos. Deixem seus grupos, por favor."
L["All characters in %s will be invited to raid in 10 seconds. Please leave your groups."] = "Todos os personagens em %s serão convidados para a raide em 10 segundos. Deixem seus grupos, por favor."
L["All characters of rank %s or higher will be invited to raid in 10 seconds. Please leave your groups."] = "Todos os personagens do posto %s ou superior serão convidados para a raide em 10 segundos. Deixem seus grupos, por favor."
L["<oRA3> Sorry, the group is full."] = "<oRA3> Grupo cheio, sinto muito."
L["Invite all guild members of rank %s or higher."] = "Convida todos os membros da guilda do posto %s ou superior."
L["Keyword"] = "Palavra-chave"
L["When people whisper you the keywords below, they will automatically be invited to your group. If you're in a party and it's full, you will convert to a raid group. The keywords will only stop working when you have a full raid of 40 people. Setting a keyword to nothing will disable it."] = "Quando alguém te sussurrar a palavra-chave abaixo, eles serão automaticamente convidados para seu grupo. Essas palavras só irão parar de funcionar quando você tiver uma raide completa de 40 pessoas. Atribuir uma palavra-chave em branco irá desabilitá-la."
L["Anyone who whispers you this keyword will automatically and immediately be invited to your group."] = "Qualquer um que sussurrar você com essa palavra-chave será automatica e imediatamente convidado para seu grupo."
L["Guild Keyword"] = "Palavra-chave da Guilda"
L["Any guild member who whispers you this keyword will automatically and immediately be invited to your group."] = "Qualquer membro da guilda que te sussurre esta palavra-chave será automatica e imediatamente convidado para seu grupo."
L["Invite guild"] = "Convidar guilda"
L["Invite everyone in your guild at the maximum level."] = "Convidad todos em sua guilda no nível máximo."
L["Invite zone"] = "Convidar zona"
L["Invite everyone in your guild who are in the same zone as you."] = "Convidar todos em sua guilda que estão na mesma zona que você."
L["Guild rank invites"] = "Convites por Posto de Guilda"
L["Clicking any of the buttons below will invite anyone of the selected rank AND HIGHER to your group. So clicking the 3rd button will invite anyone of rank 1, 2 or 3, for example. It will first post a message in either guild or officer chat and give your guild members 10 seconds to leave their groups before doing the actual invites."] = "Clicar em qualquer um desses botões irá convidar qualquer um do posto selecionado E SUPERIORES para seu grupo. Então clicar no terceiro botão irá convidar qualquer um dos postos 1, 2 e 3, por exemplo. Isto colocará primeiramente uma mensagem no chat da guilda ou oficiais e dar aos membros da sua guilda 10 segundos para deixarem seus grupos antes de enviar os convites."
L["Only invite on keyword if in a raid group"] = "Apenas quando em grupo de raide.."

-- Promote module
L["Demote everyone"] = "Demover todos"
L["Demotes everyone in the current group."] = "Demove todos no seu grupo atual."
L["Promote"] = "Promover"
L["Mass promotion"] = "Promoção em massa"
L["Everyone"] = "Todos"
L["Promote everyone automatically."] = "Promover todos automaticamente."
L["Guild"] = "Guilda"
L["Promote all guild members automatically."] = "Promove todos os membros da guilda automaticamente."
L["By guild rank"] = "Por posto na guilda"
L["Individual promotions"] = "Promoções individuais"
L["Note that names are case sensitive. To add a player, enter a player name in the box below and hit Enter or click the button that pops up. To remove a player from being promoted automatically, just click his name in the dropdown below."] = "Note que nomes são sensíveis a caixa. Para adicionar um jogador, entre o nome do jogador na caixa abaixo e tecle Enter ou clique no botão que aparecerá. Para remover um jogador da promoção automática, apenas clique em seu nome na caixa de listagem abaixo."
L["Add"] = "Adicionar"
L["Remove"] = "Remover"

-- Cooldowns module
L["Open monitor"] = "Abrir monitor"
L["Cooldowns"] = "Cooldowns"
L["Monitor settings"] = "Convigurações do Monitor"
L["Show monitor"] = "Exibir monitor"
L["Lock monitor"] = "Travar monitor"
L["Show or hide the cooldown bar display in the game world."] = "Exibe ou esconde o quadro de barra de cooldown no mundo do jogo."
L["Note that locking the cooldown monitor will hide the title and the drag handle and make it impossible to move it, resize it or open the display options for the bars."] = "Note que travar o monitor de cooldown irá esconder o título e a alça para arrastar, tornando impossível movê-lo, redimensioná-lo ou abrir as opções para as barras."
L["Only show my own spells"] = "Exibir apenas minhas próprias habilidades"
L["Toggle whether the cooldown display should only show the cooldown for spells cast by you, basically functioning as a normal cooldown display addon."] = "Alterna quando o quadro de cooldown deve mostrar apenas habilidades lançadas por você, funcionando basicamente como um addon convencional de exibição de cooldown."
L["Cooldown settings"] = "Configurações de Cooldown"
L["Select which cooldowns to display using the dropdown and checkboxes below. Each class has a small set of spells available that you can view using the bar display. Select a class from the dropdown and then configure the spells for that class according to your own needs."] = "Seleciona quais cooldowns exibir usando a caixa de listagem veficação abaixo. Cada classe tem um pequeno conjunto de habilidades disponíveis que você pode visualizar usando o quadro de barra. Selecione uma classe na caixa de listagem e então configure as havilidaeds para aquela classe de acordo com suas necessidades."
L["Select class"] = "Classe"
L["Never show my own spells"] = "Nunca exibir minhas próprias habilidades"
L["Toggle whether the cooldown display should never show your own cooldowns. For example if you use another cooldown display addon for your own cooldowns."] = "Alternar quando o quadro de cooldown jamais deve exibir seus próprios cooldowns. Por exemplo se você usar outro addon para exibir seus próprios cooldowns."

-- monitor
L["Cooldowns"] = "Cooldowns"
L["Right-Click me for options!"] = "Clique-direito para opções!"
L["Bar Settings"] = "Configurações de Barra"
L["Label Text Settings"] = "Configurações para rótulo de texto"
L["Duration Text Settings"] = "Configurações para Texto de Duração"
L["Spawn test bar"] = "Lançar barra de teste"
L["Use class color"] = "Usar cor da classe"
L["Custom color"] = "Cor personalizada"
L["Height"] = "Altura"
L["Scale"] = "Escala"
L["Texture"] = "Textura"
L["Icon"] = "Ícone"
L["Show"] = "Exibir"
L["Duration"] = "Duração"
L["Unit name"] = "Nome de Unidade"
L["Spell name"] = "Nome da habilidade"
L["Short Spell name"] = "Nome reduzido"
L["Font"] = "Fonte"
L["Font Size"] = "Tamanho da Fonte"
L["Label Align"] = "Alinhamento do rótulo"
L["Left"] = "Esquerda"
L["Right"] = "Direita"
L["Center"] = "Centro"
L["Outline"] = "Contorno"
L["Thick"] = "Grosso"
L["Thin"] = "Fino"
L["Grow up"] = "Aumentar"

-- Zone module
L["Zone"] = "Zona"

-- Loot module
L["Leave empty to make yourself Master Looter."] = "Deixe em b ranco para fazer de você o Mestre Saqueador"
L["Let oRA3 to automatically set the loot mode to what you specify below when entering a party or raid."] = "Permite que o oRA3 ajuste automaticamente o método de saque para o qual especificar abaixo sempre que entrar em um grupo ou raide."
L["Set the loot mode automatically when joining a group"] = "Ajuste o método de saque automaticamente quando se juntar a um grupo"

-- Tanks module
L["Tanks"] = "Tanques"
L.tankTabTopText = "Clique em jogadores na lista abaixo para torná-los seus tanques pessoais. Se você quiser ajuda com todas as opções aqui então mova seu mouse sobre o ponto de interrogação."
-- L["Remove"] is defined above
L.deleteButtonHelp = "Remove da lista de tanques. Note que assim que sejam removidos eles não será adicionados novamente pelo restante dessa sessão, a menos que você o faça manualmente."
L["Blizzard Main Tank"] = "Tanque Principal Blizzard"
L.tankButtonHelp = "Determina se este tanque deve ser um Tanque Principal Blizzard."
L["Save"] = "Salvar"
L.saveButtonHelp = "Salva este tanque em sua lista pessoal. Sempre que estiver em grupo com este jogador ele será listado como um tanque pessoal."
L["What is all this?"] = "O que é tudo isso?"
L.tankHelp = "As pessoas no topo da lista são seus tanques pessoais. Eles não são divididos com a raide, e todos podem ter listas pessoais diferentes. Clicar em u nome na lista inferior adiciona um tanque na sua lista pessoal.\n\nClicar on escudo irá tornar tal pessoa em um Tanque Principal Blizzard. Tanques Blizzard são compartilhados entre todos os membros de sua raide e você precisa de assistência para acertar isto.\n\nTanques que aparecen na lista porque outrem o tornou Tanque Principal Blizzard serão removidos da lista quando não o forem mais.\n\nUse a marca de checar verdade para lembrar um tanque entre sessões. A próxima vez que você estiver em uma raide com tal pessoa, ela será automaticamente ajustada como um tanque pessoal."
L["Sort"] = "Ordenar"
L["Click to move this tank up."] = "Clique para mover este tanque para cima."
L["Show"] = "Exibir"
L.showButtonHelp = "Exibir este tanque em sua lista pessoal de tanques. Esta opção só tem efeito local e não irá alterar a condição desses tanques para qualquer outra pessoa em seu grupo."

-- Latency Module
L["Latency"] = "Latência"
L["Home"] = "Local"
L["World"] = "Global"

-- Gear Module
L["Gear"] = "Gear"
L["Item Level"] = "Nível de Item"
L["Missing Gems"] = "Gemas Faltando"
L["Missing Enchants"] = "Encant. Faltando"

-- BattleRes Module
L.battleResTitle = "Monitor de Battle Res"
L.battleResLockDesc = "Ajusta trava do monitor. Isto ira esconder o texto de cabeçalho, fundo e previnir movimento."
L.battleResShowDesc = "Exibir ou esconder o monitor."

