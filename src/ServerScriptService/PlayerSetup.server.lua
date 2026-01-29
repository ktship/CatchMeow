-- PlayerSetup.lua
-- ServerScriptService에 위치
-- 플레이어 접속 및 캐릭터 스폰 처리

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

-- 모듈 로드 대기
local TeamManager
-- 순환 의존성 방지를 위해 단순 require 대신 지연 로딩 패턴 사용 가능하지만,
-- 여기서는 초기화 순서를 보장한다는 전제로 진행
-- 실제로는 GameManager가 이들을 조율하는 것이 좋음

local function onCharacterAdded(player, character)
	character:WaitForChild("Humanoid")
	
	-- 스폰 위치는 SpawnLocation 사용 (MapGenerator에서 생성)
	
	-- 2. 무기(카메라) 지급
	local weaponName = Config.Camera.Name
	
	-- 비동기로 무기 지급 시도 (다른 작업 차단 방지)
	spawn(function()
		-- 1. Weapons 폴더 대기 (최대 30초)
		local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons", 30)
		if not weaponsFolder then
			warn("[PlayerSetup] Weapons folder not found in ReplicatedStorage after 30s")
			return
		end
		
		-- 2. 무기 대기 (최대 30초)
		local weapon = weaponsFolder:WaitForChild(weaponName, 30)
		if weapon then
			local newWeapon = weapon:Clone()
			newWeapon.Parent = player.Backpack
			
			-- 캐릭터가 존재하면 손에 쥐어주기
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid:EquipTool(newWeapon)
			end
			print("[PlayerSetup] Weapon given to " .. player.Name)
		else
			warn("[PlayerSetup] Weapon '" .. weaponName .. "' not found in Weapons folder")
		end
	end)
	
	-- 3. 캐릭터 외형 팀 컬러 적용 (선택 사항)
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.MaxHealth = 100
		humanoid.Health = 100
	end
	
	-- 팀 색상 의류 적용 예시 (간단하게 상의 색상 변경)
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			-- part.BrickColor = player.TeamColor -- 너무 전체가 바뀌면 이상할 수 있음
		end
	end
	
	-- 리스폰 처리
	humanoid.Died:Connect(function()
		wait(Config.Game.RespawnTime)
		player:LoadCharacter()
	end)
end

local function onPlayerAdded(player)
	-- 팀 배정
	if TeamManager then
		TeamManager.AssignTeam(player)
	end
	
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	
	-- 처음 접속 시 캐릭터 로드
	-- player:LoadCharacter() -- 자동 로드되므로 필요 없을 수 있음
end

-- 외부에서 초기화 호출
local function Initialize()
	TeamManager = require(ServerScriptService:WaitForChild("TeamManager"))
	Config = require(ReplicatedStorage:WaitForChild("Config"))
	
	-- 이미 접속한 플레이어 처리
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	
	Players.PlayerAdded:Connect(onPlayerAdded)
end

-- 스크립트로 실행될 경우 자동 초기화, 모듈로 사용될 경우 함수 반환
-- 여기서는 Script로 실행된다고 가정하고 바로 실행
if script.Name == "PlayerSetup" and script:IsA("Script") then
	Initialize()
end

return {
	Initialize = Initialize
}
