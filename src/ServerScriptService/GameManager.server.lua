-- GameManager.lua
-- ServerScriptService에 위치
-- 게임 라운드 루프 관리

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local MapGenerator = require(game.ServerScriptService:WaitForChild("MapGenerator"))
local TeamManager = require(game.ServerScriptService:WaitForChild("TeamManager"))

-- 상태 값 (클라이언트 표시용)
local statusValue = ReplicatedStorage:FindFirstChild("GameStatus")
if not statusValue then
	statusValue = Instance.new("StringValue")
	statusValue.Name = "GameStatus"
	statusValue.Parent = ReplicatedStorage
end

local timerValue = ReplicatedStorage:FindFirstChild("TimeLeft")
if not timerValue then
	timerValue = Instance.new("IntValue")
	timerValue.Name = "TimeLeft"
	timerValue.Parent = ReplicatedStorage
end

-- Events Folder
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = ReplicatedStorage
end

-- TakePhoto BindableEvent (Client-to-Client)
local takePhotoEvent = eventsFolder:FindFirstChild("TakePhoto")
if not takePhotoEvent then
	takePhotoEvent = Instance.new("BindableEvent")
	takePhotoEvent.Name = "TakePhoto"
	takePhotoEvent.Parent = eventsFolder
end

-- Helper 함수
local function setStatus(msg)
	statusValue.Value = msg
end

local function respawnAll()
	for _, player in pairs(Players:GetPlayers()) do
		player:LoadCharacter()
	end
end

-- 메인 게임 루프
local function gameLoop()
	-- 시작하자마자 로딩 중임을 알림
	setStatus("Loading System...")
	wait(1)

	while true do
		-- 1. 인터미션 (대기 시간)
		setStatus("Starting in...")
		for i = Config.Game.IntermissionDuration, 1, -1 do
			setStatus("Starting in " .. i)
			timerValue.Value = i
			wait(1)
		end
		
		-- 2. 라운드 준비
		setStatus("Generating Map...")
		wait(1)
		MapGenerator.Generate() -- 새 맵 생성
		TeamManager.Initialize() -- 팀 재설정 (균형 맞추기 등 필요시)
		
		-- 플레이어 재소환
		respawnAll()
		
		-- 3. 라운드 시작
		setStatus("Game in Progress")
		local roundTime = Config.Game.RoundDuration
		
		for i = roundTime, 1, -1 do
			timerValue.Value = i
			
			-- 승리 조건 체크 (예: 한 팀 전멸 확인)
			-- 여기서는 간단히 시간제한만 적용
			
			wait(1)
		end
		
		-- 4. 라운드 종료 및 승자 판정
		setStatus("Round Over!")
		
		-- 점수 확인
		local redKills = 0
		local blueKills = 0
		
		for _, player in pairs(Players:GetPlayers()) do
			if player.Team and player:FindFirstChild("leaderstats") then
				if player.Team.Name == "Red Team" then
					redKills = redKills + player.leaderstats.Kills.Value
				elseif player.Team.Name == "Blue Team" then
					blueKills = blueKills + player.leaderstats.Kills.Value
				end
			end
		end
		
		if redKills > blueKills then
			setStatus("Red Team Wins!")
		elseif blueKills > redKills then
			setStatus("Blue Team Wins!")
		else
			setStatus("Draw!")
		end
		
		wait(5) -- 결과 보여주기
		
		-- 점수 리셋 (다음 라운드를 위해)
		for _, player in pairs(Players:GetPlayers()) do
			if player:FindFirstChild("leaderstats") then
				player.leaderstats.Kills.Value = 0
				player.leaderstats.Deaths.Value = 0
			end
		end
	end
end

-- 루프 시작
spawn(gameLoop)

return {}
