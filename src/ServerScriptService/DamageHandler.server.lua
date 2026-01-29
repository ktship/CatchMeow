-- DamageHandler.lua
-- ServerScriptService에 위치
-- 플레이어 사망 감지 및 점수(Kills/Deaths) 기록

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 킬 피드용 RemoteEvent 생성
local killFeedEvent = ReplicatedStorage:FindFirstChild("KillFeedEvent")
if not killFeedEvent then
	killFeedEvent = Instance.new("RemoteEvent")
	killFeedEvent.Name = "KillFeedEvent"
	killFeedEvent.Parent = ReplicatedStorage
end

local function onPlayerAdded(player)
	-- Leaderstats 설정
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats
	
	local deaths = Instance.new("IntValue")
	deaths.Name = "Deaths"
	deaths.Value = 0
	deaths.Parent = leaderstats
	
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		
		humanoid.Died:Connect(function()
			-- 사망자 데스 증가
			deaths.Value = deaths.Value + 1
			
			-- 킬러 확인 (WeaponServer에서 생성한 creator 태그)
			local creatorTag = humanoid:FindFirstChild("creator")
			if creatorTag and creatorTag.Value then
				local killer = creatorTag.Value
				local killerStats = killer:FindFirstChild("leaderstats")
				if killerStats then
					killerStats.Kills.Value = killerStats.Kills.Value + 1
				end
				
				-- 킬 피드 전송
				killFeedEvent:FireAllClients(killer.Name, player.Name)
			else
				-- 자살 또는 환경 요인
				killFeedEvent:FireAllClients(nil, player.Name)
			end
		end)
	end)
end

-- 기존 플레이어 처리
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

return {}
