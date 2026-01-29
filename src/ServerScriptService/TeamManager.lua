-- TeamManager.lua
-- ServerScriptService에 위치
-- 팀 생성 및 플레이어 팀 배정 관리

local TeamManager = {}
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage:WaitForChild("Config"))

function TeamManager.Initialize()
	-- 기존 팀 초기화
	for _, team in pairs(Teams:GetTeams()) do
		team:Destroy()
	end
	
	-- 팀 생성
	local redTeam = Instance.new("Team")
	redTeam.Name = Config.Teams.Red.Name
	redTeam.TeamColor = BrickColor.new(Config.Teams.Red.Color)
	redTeam.AutoAssignable = false
	redTeam.Parent = Teams
	
	local blueTeam = Instance.new("Team")
	blueTeam.Name = Config.Teams.Blue.Name
	blueTeam.TeamColor = BrickColor.new(Config.Teams.Blue.Color)
	blueTeam.AutoAssignable = false
	blueTeam.Parent = Teams
	
	print("Teams Initialized")
end

function TeamManager.AssignTeam(player)
	local redTeam = Teams:FindFirstChild(Config.Teams.Red.Name)
	local blueTeam = Teams:FindFirstChild(Config.Teams.Blue.Name)
	
	-- 팀이 아직 생성되지 않았으면 생성 (Initialize 호출)
	if not redTeam or not blueTeam then
		TeamManager.Initialize()
		redTeam = Teams:FindFirstChild(Config.Teams.Red.Name)
		blueTeam = Teams:FindFirstChild(Config.Teams.Blue.Name)
	end
	
	local redCount = #redTeam:GetPlayers()
	local blueCount = #blueTeam:GetPlayers()
	
	if redCount <= blueCount then
		player.Team = redTeam
		player.TeamColor = redTeam.TeamColor
	else
		player.Team = blueTeam
		player.TeamColor = blueTeam.TeamColor
	end
	
	print(player.Name .. " assigned to " .. player.Team.Name)
end

function TeamManager.GetSpawnLocation(player)
	-- 맵 가장자리에서 스폰하되, 중앙(건물) 방향을 바라보도록 설정
	local mapSize = Config.Map.Size
	local spawnOffset = mapSize / 2 - 25 -- 가장자리에서 약간 안쪽
	
	-- 랜덤한 방향 선택 (북/남/동/서)
	local side = math.random(1, 4)
	local spawnPos
	
	if side == 1 then
		-- 북쪽 (-Z)
		spawnPos = Vector3.new(math.random(-20, 20), 5, -spawnOffset)
	elseif side == 2 then
		-- 남쪽 (+Z)
		spawnPos = Vector3.new(math.random(-20, 20), 5, spawnOffset)
	elseif side == 3 then
		-- 서쪽 (-X)
		spawnPos = Vector3.new(-spawnOffset, 5, math.random(-20, 20))
	else
		-- 동쪽 (+X)
		spawnPos = Vector3.new(spawnOffset, 5, math.random(-20, 20))
	end
	
	-- 맵 중앙(0,5,0)을 바라보는 CFrame 반환
	local centerPos = Vector3.new(0, 5, 0)
	return CFrame.lookAt(spawnPos, centerPos)
end

return TeamManager
