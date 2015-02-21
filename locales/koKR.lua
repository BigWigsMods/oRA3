
if GetLocale() ~= "koKR" then return end
local _, tbl = ...
local L = tbl.locale

-- Generic
L.name = "이름"
L.checks = "체크"
L.disbandGroup = "파티 해산"
L.disbandGroupDesc = "당신이 구성하고 있는 파티/공격대를 모두 해산시킵니다. 각 파티/공대원들은 자동적으로 추방이 되어 솔로 상태가 됩니다."
L.options = "옵션"
L.disbandingGroupChatMsg = "파티를 해산합니다."
L.disbandGroupWarning = "정말로 당신의 파티/공격대를 해산하겠습니까?"
L.unknown = "알수 없음"
L.profile = "프로필"

-- Core

L.togglePane = "oRA3 패널 전환"
L.toggleWithRaid = "공격대 패널과 함께 열기"
L.toggleWithRaidDesc = "공격대 패널을 열거나 닫을때 oRA3 패널도 같이 열거나 닫히도록 합니다. 따로 커맨드 명령어나 단축키 지정으로도 열수 있습니다."
L.showHelpTexts = "인터페이스 도움말 보기"
L.showHelpTextsDesc = "oRA3 패널창에서 도움말을 표시합니다."
L.ensureRepair = "공격대에서 현재 모든 등급에 대해 길드 수리가 활성화 되어있는지 확인"
L.ensureRepairDesc = "당신이 만약 길드 관리자이며 팀에 합류하였고 지휘관 또는 승급자라면, 길드원의 수리비에 대해 길드 수리비(최대 300골드)를 지원하도록 설정 가능합니다. |cffff4411당신이 공격대를 떠난다면 적용되지 않으니 파산등의 걱정은 하지마세요 :)|r"
L.repairEnabled = "이 공격대에서 %s 에 대해 길드 수리를 활성화합니다."

L.slashCommands = "슬러쉬 명령어"

-- Ready check module
L.notReady = "준비가 되지 않은 플레이어: %s"
L.readyCheckSeconds = "준비 확인 (%d 초)"
L.ready = "준비 완료"
L.notReady = "준비 안됨"
L.noResponse = "응답 없음"
L.offline = "오프라인"
L.showWindow = "창 표시"
L.showWindowDesc = "전투 준비 확인시 창을 표시합니다."
L.hideWhenDone = "완료시 창 닫기"
L.hideWhenDoneDesc = "전투 준비 확인이 완료시 자동적으로 창을 닫습니다."
L.hideReadyPlayers = "준비된 플레이어 숨김"
L.hideReadyPlayersDesc = "창에 준비가된 플레이어에게 표시를 하지 않습니다."
L.hideInCombatDesc = "전투중일 경우, 전투 준비 확인창을 자동으로 숨깁니다."
L.hideInCombat = "전투시 숨김"
L.printToRaid = "준비 확인 결과를 공격대 대화창으로 알림"
L.printToRaidDesc = "당신이 공격대장 또는 승급자일 경우에 전투 준비 확인 결과를 공격대 대화창으로 출력하도록 합니다."

-- Durability module
L.durability = "내구도"
L.average = "평균"
L.broken = "파손"
L.minimum = "최소"

-- Resurrection module
L["%s is ressing %s."] = "%s 가 %s 를 부활중입니다."

-- Invite module
L.invite = "초대"
L.invitePrintMaxLevel = "10초 동안 최대 레벨 이상인 길드원들을 공격대에 초대합니다. 파티에서 나와 주세요."
L.invitePrintZone = "10초 동안 %s 내의 모든 길드원을 공격대에 초대합니다. 파티에서 나와 주세요."
L.invitePrintRank = "10초 동안 %s 등급 이상인 길드원들을 공격대에 초대합니다. 파티에서 나와 주세요."
L.invitePrintGroupIsFull = "죄송합니다. 공격대의 정원이 찼습니다."
L.inviteGuildRankDesc = "%s 등급 이상인 모든 길드원을 공격대에 초대합니다."
L.keyword = "키워드"
L.inviteDesc = "아래 키워드로 사람들이 당신에게 귓속말시에 자동으로 당신의 파티에 초대됩니다. 만약 당신이 파티중이며 5명일경우 자동으로 공격대로 전환됩니다. 공격대가 40명이 찰경우에는 키워드 작동이 더이상되지 않습니다."
L.keywordDesc = "설정된 키워드로 귓속말을 하면 즉시 자동으로 자신의 공격대로 초대합니다."
L.guildKeyword = "길드 키워드"
L.guildKeywordDesc = "모든 길드원이 키워드로 당신에게 귓속말시에 자동으로 즉시 파티에 초대됩니다."
L.inviteGuild = "길드원 초대"
L.inviteGuildDesc = "길드내 최대 레벨의 모든 길드원을 공격대에 초대합니다."
L.inviteZone = "지역 초대"
L.inviteZoneDesc = "현재 지역 내의 모든 길드원을 공격대에 초대합니다."
L.guildRankInvites = "길드 등급 초대"
L.guildRankInvitesDesc = "지정된 등급 이상의 모든 길드원을 공격대에 초대합니다."

-- Promote module
L.demoteEveryone = "모두 강등"
L.demoteEveryoneDesc = "현재 파티/공격대의 모두를 강등시킵니다."
L.promote = "승급"
L.massPromotion = "집단 승급"
L.promoteEveryone = "모든 사람"
L.promoteEveryoneDesc = "자동적으로 모든 사람을 승급합니다."
L.promoteGuild = "길드"
L.promoteGuildDesc = "자동적으로 모든 길드원을 승급합니다."
L.byGuildRank = "길드 등급별"
L.individualPromotions = "개별적 승급"
L.individualPromotionsDesc = "이름은 대소문자를 구분합니다. 플레이어를 추가하려면, 아래의 상자에 플레이어 이름을 입력하고 엔터키를 눌리거나 팝업 버튼을 클릭하세요. 플레이어를 자동으로 제거하려면 승급이 되어야하며 아래의 드롭 다운에서 그의 이름을 클릭하면 됩니다."
L.add = "추가"
L.remove = "삭제"

-- Cooldowns module
L.openMonitor = "모니터 열기"
L.monitorSettings = "모니터 설정"
L.showMonitor = "모니터 표시"
L.lockMonitor = "모니터 잠금"
L.showMonitorDesc = "게임 환경안에 재사용 대기시간 바를 표시하거나 숨깁니다."
L.lockMonitorDesc = "크기를 조정하거나 바에 대한 표시 옵션을 엽니다. 재사용 대기시간 모니터의 제목을 드래그로 이동 가능하며 모니터 잠금시 제목을 숨깁니다."
L.onlyMyOwnSpells = "자신의 기술만 표시"
L.onlyMyOwnSpellsDesc = "일반적인 주문의 재사용 대기시간이나 자신의 주문의 재사용 대기시간을 전환합니다."
L.cooldownSettings = "재사용 대기시간 설정"
L.selectClassDesc = "선택한 주문에 대한 재사용 대기시간을 표시합니다."
L.selectClass = "직업 선택"
L.neverShowOwnSpells = "자신의 기술을 표시하지 않음"
L.neverShowOwnSpellsDesc = "자신의 재사용 대기시간의 표시하지 않도록 전환합니다. 예를 들어 보통 다른 애드온으로 자신의 재사용 대기시간을 표시를 합니다."

-- monitor
L.cooldowns = "재사용 대기시간"
L.rightClick = "옵션 설정은 우-클릭!"
L.barSettings = "바 설정"
L.spawnTestBar = "테스트 바 표시"
L.useClassColor = "직업 색상 사용"
L.customColor = "사용자 색상"
L.height = "높이"
L.scale = "크기"
L.texture = "텍스쳐"
L.icon = "아이콘"
L.show = "보기"
L.duration = "지속 시간"
L.unitName = "유닛 이름"
L.spellName = "주문 이름"
L.shortSpellName = "짧은 주문 이름"
L.labelAlign = "Label 정렬"
L.left = "좌측"
L.right = "우측"
L.center = "중앙"
L.growUpwards = "성장 방향"

-- Zone module
L.zone = "지역"

-- Loot module
L.autoLootMethodDesc = "파티나 공격대에 참여시 자동적으로 전리품 획득 방식을 oRA3을 통해 설정합니다."
L.autoLootMethod = "참가한 그룹이 있을때 자동적으로 전리품 획득 방식을 설정합니다."
L.makeLootMaster = "자신이 담당자 획득이면 비워 둡니다."

-- Tanks module
L.tanks = "탱커"
L.tankTabTopText = "하단의 목록에서 플레이어를 클릭하여 개인적인 탱커를 지정합니다. 만약에 옵션에 대한 도움이 필요하다면 물음표 표시에 마우스를 올려놓으세요."
L.deleteButtonHelp = "탱커 목록에서 삭제합니다."
L.blizzMainTank = "블리자드 메인 탱커"
L.tankButtonHelp = "여기 탱커를 블리자드 탱커로 전환합니다."
L.save = "저장"
L.saveButtonHelp = "개인적인 탱커 목록을 저장합니다. 개인적인 탱커 목록을 그룹화합니다."
L.whatIsThis = "이것 모두 무엇입니까? :D"
L.tankHelp = "위의 목록에 있는 사람들은 당신이 개인적으로 정렬시킨 탱커들입니다 그들을 공격대원과 공유하지 않으며 각 공격대원들은 자신이 원하는 탱커를 지정하여 개인적인 목록을 가질수 있습니다. 하단의 목록에서 이름을 클릭하면 개인 탱커 목록에 추가됩니다.\n\n방패 아이콘을 클릭하면 그 사람은 블리자드의 메인 탱커(방어 전담)으로 될것입니다. 블리자드 탱커(방어 전담)으로 지정시 모든 공격대원에게 공유됩니다.\n\n녹색 체크 표시를 사용하여 탱커를 저장합니다. 다음번에 당신이 그 사람과 함께 공격대에 참여할시 그는 개인적인 탱커로 자동으로 설정됩니다."
L.sort = "정렬"
L.moveTankUp = "탱커를 위로 이동하려면 클릭하세요."
L.show = "표시"
L.showButtonHelp = "이 탱커를 정렬 탱커 목록에 표시를 합니다. 이 옵션은 당신에게만 적용되며 그룹에서 다른 사람의 탱커가 변경되지 않습니다."

