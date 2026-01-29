# Roblox 총싸움 게임 설치 가이드

이 문서는 생성된 Luau 스크립트들을 사용하여 Roblox Studio에서 게임을 설정하는 방법을 설명합니다.

## 설치 방법 (자동 스크립트 사용)

이 프로젝트는 편의를 위해 `Setup` 스크립트들을 포함하고 있습니다. 다음 단계를 따라주세요.

### 1단계: 파일 배치

Roblox Studio를 열고 `ServerScriptService`에 다음 스크립트(Script)들을 생성하고 내용을 붙여넣으세요.

1. **Config** (이름을 `Config`로 지정하고, 생성 후 `ReplicatedStorage`로 이동시키세요!)
   - `ReplicatedStorage`에 `ModuleScript`를 만들고 이름을 `Config`로 변경한 뒤 내용을 붙여넣는 것이 정석입니다.
2. **Setup 스크립트들** (이것들은 한 번 실행하고 삭제하거나 그냥 두어도 됩니다)
   - `WeaponSetup` (Script) -> ServerScriptService
   - `UISetup` (Script) -> ServerScriptService
3. **게임 로직 스크립트들**
   - `MapGenerator` (ModuleScript) -> ServerScriptService
   - `TeamManager` (ModuleScript) -> ServerScriptService
   - `DamageHandler` (Script) -> ServerScriptService
   - `PlayerSetup` (Script) -> ServerScriptService (이름을 PlayerSetup으로)
   - `GameManager` (Script) -> ServerScriptService

> **주의:** `MapGenerator`와 `TeamManager`는 다른 스크립트에서 `require`로 불러오기 때문에 반드시 **ModuleScript**로 생성해야 합니다. 나머지는 일반 **Script**입니다.

### 2단계: 파일 구조 확인

최종적으로 다음과 같은 구조가 되어야 합니다:

- **Workspace**: (비어있음, 스크립트 실행 시 Map 생성됨)
- **ReplicatedStorage**
  - `Config` (ModuleScript)
- **ServerScriptService**
  - `MapGenerator` (ModuleScript)
  - `TeamManager` (ModuleScript)
  - `DamageHandler` (Script)
  - `GameManager` (Script)
  - `PlayerSetup` (Script)
  - `WeaponSetup` (Script)
  - `UISetup` (Script)

### 3단계: 실행 및 테스트

1. Roblox Studio 상단의 `Play` 버튼을 누릅니다.
2. `Setup` 스크립트들이 자동으로 실행되어 다음 작업들이 수행됩니다:
   - `Weapons` 폴더와 `Auto Rifle` 도구가 `ReplicatedStorage`에 생성됨
   - `GameHUD`, `KillFeed`가 `StarterGui`에 생성됨 (플레이 전에 생성되거나 리스폰 시 보임)
   - 도시 맵이 생성됨
3. 플레이어가 스폰되고 자동으로 팀이 배정되며 무기가 지급됩니다.

## 게임 설정 변경

`ReplicatedStorage/Config` 스크립트를 열어 게임 설정을 변경할 수 있습니다.
- **Map Size**: 맵 크기 변경
- **Teams**: 팀 이름 및 색상 변경
- **Weapon**: 데미지, 발사 속도, 장탄수 등 변경
- **Game**: 라운드 시간, 리스폰 시간 변경

## 문제 해결

- **무기가 안 보이나요?** `WeaponSetup`이 정상적으로 실행되었는지 Output 창을 확인하세요.
- **맵이 안 생기나요?** `GameManager`가 `MapGenerator`를 호출하는지 확인하세요.
- **오류 발생 시**: `View` 탭 -> `Output` 창을 열어 빨간색 에러 메시지를 확인하세요.
