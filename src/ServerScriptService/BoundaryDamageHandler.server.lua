-- BoundaryDamageHandler.server.lua
-- ServerScriptService에 위치
-- 경고 구역 데미지 및 킬존 처리 (위치 기반)

local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))

-- 설정
local DAMAGE_PER_SECOND = 10
local TICK_RATE = 0.5
local WARNING_ZONE_WIDTH = 15 -- MapGenerator의 warningWidth와 동일해야 함

local mapSize = Config.Map.Size
local halfSize = mapSize / 2
local safeZone = halfSize -- 맵 경계까지는 안전 (200/2 = 100)

-- 플레이어가 경고 구역에 있는지 확인
local function isInWarningZone(position)
	local x, z = math.abs(position.X), math.abs(position.Z)
	-- 맵 밖이거나 경고 구역 내
	return x > safeZone or z > safeZone
end

-- 플레이어가 맵 밖인지 확인 (낙사 체크)
local function isOutOfBounds(position)
	return position.Y < -50
end

-- 데미지 루프
while true do
	task.wait(TICK_RATE)
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and root and humanoid.Health > 0 then
				local pos = root.Position
				
				-- 낙사 체크
				if isOutOfBounds(pos) then
					humanoid.Health = 0
				-- 경고 구역 체크
				elseif isInWarningZone(pos) then
					humanoid:TakeDamage(DAMAGE_PER_SECOND * TICK_RATE)
				end
			end
		end
	end
end
