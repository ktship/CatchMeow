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
	-- 맵의 양 끝을 각 팀의 스폰 지점으로 설정
	local mapSize = Config.Map.Size
	local spawnOffset = mapSize / 2 - 20
	
	if player.Team.Name == Config.Teams.Red.Name then
		-- Red Team: 북쪽 (-Z)
		return CFrame.new(math.random(-20, 20), 5, -spawnOffset)
	else
		-- Blue Team: 남쪽 (+Z)
		return CFrame.new(math.random(-20, 20), 5, spawnOffset)
	end
end

return TeamManager
