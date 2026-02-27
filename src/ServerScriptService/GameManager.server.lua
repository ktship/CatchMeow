-- GameManager.lua
-- ServerScriptService에 위치
-- 게임 라운드 루프 관리

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- [v4.13] INIT CRITICAL EVENTS FIRST (Prevent Infinite Yields)
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
	print("[GameManager] Created 'TakePhoto' BindableEvent")
end

-- PhotoFeedback RemoteEvent (Server-to-Client)
local photoFeedbackEvent = eventsFolder:FindFirstChild("PhotoFeedback")
if not photoFeedbackEvent then
	photoFeedbackEvent = Instance.new("RemoteEvent")
	photoFeedbackEvent.Name = "PhotoFeedback"
	photoFeedbackEvent.Parent = eventsFolder
end

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local MapGenerator = require(game.ServerScriptService:WaitForChild("MapGenerator"))

-- [Fix] Prevent "Teleport Glitch" (Spawning at 0,0,0 then jumping to spawn)
-- Disable AutoLoad so we can manually spawn players ONLY after map is ready.
Players.CharacterAutoLoads = false

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
	-- 0. [초기화] 서버 시작 -> 로비 생성 (Sky Plaza)
	setStatus("Loading Lobby...")
	MapGenerator.GenerateLobby()
	respawnAll() 
	
	-- 1. [자동 이동] 1초 대기 후 산골마을로 이동
	wait(1)
	setStatus("Traveling to Village...")
	MapGenerator.GenerateVillage()
	respawnAll()
	
	while true do
		-- 2. 게임 루프 시작 (산골마을 유지)
		setStatus("Game in Progress")
		timerValue.Value = 0
		wait(5)
	end
end


-- [Fix] Handle Late Joiners
Players.PlayerAdded:Connect(function(player)
	task.wait(1.5) 
	-- 로비나 마을 세팅 중에 들어온 접속자는 gameLoop의 respawnAll()에 의해 먼저 스폰될 것입니다.
	-- Game in Progress 상태에서만 스폰시켜 중복 로딩(이중 이펙트, UI 두 번 초기화)을 방지합니다.
	if statusValue.Value == "Game in Progress" then
		if player and not player.Character then 
			player:LoadCharacter() 
		end
	end
end)

-- 루프 시작
spawn(gameLoop)

return {}
