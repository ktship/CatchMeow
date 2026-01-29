-- MapGenerator.lua
-- ServerScriptService에 위치해야 합니다.
-- 게임 시작 시 도시 맵을 생성합니다.

local MapGenerator = {}

local Config = require(game.ReplicatedStorage:WaitForChild("Config"))

local function createPart(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

function MapGenerator.Generate()
	print("Generating City Map...")
	
	-- 기존 맵 초기화
	local mapFolder = workspace:FindFirstChild("Map")
	if mapFolder then mapFolder:Destroy() end
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace

	local mapSize = Config.Map.Size
	local halfSize = mapSize / 2
	local groundY = 0
	
	-- 1. 바닥 생성
	createPart("Ground", Vector3.new(mapSize, 1, mapSize), Vector3.new(0, groundY, 0), Color3.fromRGB(50, 60, 50), Enum.Material.Grass, mapFolder)

	-- 2. 도로 시스템 생성 (격자 형태)
	local roadWidth = Config.Map.RoadWidth
	local blockSize = 60 -- 블록 크기
	local roadsFolder = Instance.new("Folder")
	roadsFolder.Name = "Roads"
	roadsFolder.Parent = mapFolder

	-- 가로/세로 도로 생성
	for x = -halfSize + blockSize/2, halfSize - blockSize/2, blockSize do
		createPart("RoadV", Vector3.new(roadWidth, 1.1, mapSize), Vector3.new(x, groundY+0.05, 0), Color3.fromRGB(40, 40, 40), Enum.Material.Asphalt, roadsFolder)
	end
	for z = -halfSize + blockSize/2, halfSize - blockSize/2, blockSize do
		createPart("RoadH", Vector3.new(mapSize, 1.1, roadWidth), Vector3.new(0, groundY+0.05, z), Color3.fromRGB(40, 40, 40), Enum.Material.Asphalt, roadsFolder)
	end
	
	-- 3. 건물 및 구조물 배치
	local buildingsFolder = Instance.new("Folder")
	buildingsFolder.Name = "Buildings"
	buildingsFolder.Parent = mapFolder
	
	local carsFolder = Instance.new("Folder")
	carsFolder.Name = "Vehicles"
	carsFolder.Parent = mapFolder
	
	-- 각 블록 내부 공간에 건물이나 주차장 배치
	for x = -halfSize + blockSize/2, halfSize - blockSize/2, blockSize do
		for z = -halfSize + blockSize/2, halfSize - blockSize/2, blockSize do
			-- 블록 중심 좌표
			local centerX = x + blockSize/2
			local centerZ = z + blockSize/2
			
			-- 도로와 겹치지 않는 유효 건축 영역
			if centerX < halfSize and centerZ < halfSize then
				-- 랜덤하게 건물 또는 공터 결정
				local rand = math.random()
				
				if rand > 0.3 then -- 70% 확률로 건물
					MapGenerator.CreateBuilding(centerX, groundY + 1, centerZ, buildingsFolder)
				elseif rand > 0.1 then -- 20% 확률로 주차장(차량)
					MapGenerator.CreateParkingLot(centerX, groundY + 1, centerZ, carsFolder)
				end
			end
		end
	end
	
	-- 5. 스폰 위치 생성 (가장자리에서 중앙을 바라보도록)
	MapGenerator.CreateSpawnLocations(mapFolder, mapSize)
	
	-- 6. 다리 생성 (중앙을 가로지르는)
	MapGenerator.CreateBridge(mapFolder)
	
	print("City Map Generated!")
end

-- 스폰 위치 생성 함수 (도로 위 코너에 배치)
function MapGenerator.CreateSpawnLocations(parent, mapSize)
	local halfSize = mapSize / 2
	-- 도로가 있는 가장자리 코너에 배치 (건물과 겹치지 않음)
	local cornerOffset = halfSize - 10
	
	-- 4개 코너에 스폰 위치 생성 (도로 위)
	local spawnPositions = {
		{pos = Vector3.new(-cornerOffset, 1, -cornerOffset), lookAt = Vector3.new(0, 1, 0)}, -- 북서
		{pos = Vector3.new(cornerOffset, 1, -cornerOffset), lookAt = Vector3.new(0, 1, 0)},  -- 북동
		{pos = Vector3.new(-cornerOffset, 1, cornerOffset), lookAt = Vector3.new(0, 1, 0)},  -- 남서
		{pos = Vector3.new(cornerOffset, 1, cornerOffset), lookAt = Vector3.new(0, 1, 0)},   -- 남동
	}
	
	for i, spawnData in ipairs(spawnPositions) do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn" .. i
		spawn.Size = Vector3.new(6, 1, 6)
		spawn.CFrame = CFrame.lookAt(spawnData.pos, spawnData.lookAt)
		spawn.Anchored = true
		spawn.CanCollide = false
		spawn.Neutral = true -- 모든 플레이어 스폰 가능
		spawn.Material = Enum.Material.ForceField
		spawn.Transparency = 0.5
		spawn.Parent = parent
	end
end

function MapGenerator.CreateBuilding(x, y, z, parent)
	local width = math.random(20, 35)
	local depth = math.random(20, 35)
	local height = math.random(15, 45) -- 1층~3층 높이 다양하게
	
	local buildingColor = Color3.fromHSV(math.random(), 0.5, 0.7)
	
	local model = Instance.new("Model")
	model.Name = "Building"
	model.Parent = parent
	
	-- 메인 건물
	local mainPart = createPart("Main", Vector3.new(width, height, depth), Vector3.new(x, y + height/2, z), buildingColor, Enum.Material.Concrete, model)
	
	-- 옥상 테두리 (커버 포인트)
	local rimHeight = 2
	local rimThick = 1
	createPart("Rim1", Vector3.new(width, rimHeight, rimThick), Vector3.new(x, y + height + rimHeight/2, z - depth/2 + rimThick/2), buildingColor, Enum.Material.Concrete, model)
	createPart("Rim2", Vector3.new(width, rimHeight, rimThick), Vector3.new(x, y + height + rimHeight/2, z + depth/2 - rimThick/2), buildingColor, Enum.Material.Concrete, model)
	createPart("Rim3", Vector3.new(rimThick, rimHeight, depth - rimThick*2), Vector3.new(x - width/2 + rimThick/2, y + height + rimHeight/2, z), buildingColor, Enum.Material.Concrete, model)
	createPart("Rim4", Vector3.new(rimThick, rimHeight, depth - rimThick*2), Vector3.new(x + width/2 - rimThick/2, y + height + rimHeight/2, z), buildingColor, Enum.Material.Concrete, model)
	
	-- 창문 및 문 (장식)
	local door = createPart("Door", Vector3.new(6, 8, 1), Vector3.new(x, y + 4, z - depth/2 - 0.5), Color3.new(0.3, 0.2, 0.1), Enum.Material.Wood, model)
end

function MapGenerator.CreateParkingLot(x, y, z, parent)
	-- 차 배치
	local carCount = math.random(1, 2)
	for i = 1, carCount do
		local offsetX = math.random(-10, 10)
		local offsetZ = math.random(-10, 10)
		MapGenerator.CreateCar(x + offsetX, y, z + offsetZ, parent)
	end
	
	-- 오토바이 배치
	local bikeCount = math.random(0, 2)
	for i = 1, bikeCount do
		local offsetX = math.random(-10, 10)
		local offsetZ = math.random(-10, 10)
		MapGenerator.CreateBike(x + offsetX, y, z + offsetZ, parent)
	end
end

function MapGenerator.CreateCar(x, y, z, parent)
	local model = Instance.new("Model")
	model.Name = "Car"
	model.Parent = parent
	
	local bodyColor = Color3.fromHSV(math.random(), 0.8, 0.8)
	
	-- 차체
	createPart("Body", Vector3.new(6, 3, 10), Vector3.new(x, y + 2.5, z), bodyColor, Enum.Material.Metal, model)
	createPart("Roof", Vector3.new(5, 2, 6), Vector3.new(x, y + 5, z), bodyColor, Enum.Material.Metal, model)
	
	-- 바퀴
	local wheelColor = Color3.new(0.1, 0.1, 0.1)
	createPart("WheelFL", Vector3.new(1, 2, 2), Vector3.new(x - 3, y + 1, z - 3), wheelColor, Enum.Material.Rubber, model)
	createPart("WheelFR", Vector3.new(1, 2, 2), Vector3.new(x + 3, y + 1, z - 3), wheelColor, Enum.Material.Rubber, model)
	createPart("WheelBL", Vector3.new(1, 2, 2), Vector3.new(x - 3, y + 1, z + 3), wheelColor, Enum.Material.Rubber, model)
	createPart("WheelBR", Vector3.new(1, 2, 2), Vector3.new(x + 3, y + 1, z + 3), wheelColor, Enum.Material.Rubber, model)
end

function MapGenerator.CreateBike(x, y, z, parent)
	local model = Instance.new("Model")
	model.Name = "Motorcycle"
	model.Parent = parent
	
	local color = Color3.new(0.8, 0.1, 0.1)
	
	-- 몸체
	createPart("Body", Vector3.new(1.5, 2, 5), Vector3.new(x, y + 1.5, z), color, Enum.Material.Metal, model)
	
	-- 바퀴
	local wheelColor = Color3.new(0.1, 0.1, 0.1)
	createPart("WheelF", Vector3.new(0.5, 2, 2), Vector3.new(x, y + 1, z - 2.5), wheelColor, Enum.Material.Rubber, model)
	createPart("WheelB", Vector3.new(0.5, 2, 2), Vector3.new(x, y + 1, z + 2.5), wheelColor, Enum.Material.Rubber, model)
end

function MapGenerator.CreateBridge(parent)
	-- 맵을 가로지르는 고가 다리
	local bridgeHeight = 20
	local bridgeWidth = 12
	local mapSize = Config.Map.Size
	
	local model = Instance.new("Model")
	model.Name = "Bridge"
	model.Parent = parent
	
	-- 다리 상판
	createPart("Deck", Vector3.new(mapSize, 2, bridgeWidth), Vector3.new(0, bridgeHeight, 0), Color3.new(0.6, 0.6, 0.6), Enum.Material.Concrete, model)
	
	-- 다리 기둥 (몇 군데)
	for x = -mapSize/2 + 20, mapSize/2 - 20, 60 do
		createPart("Pillar", Vector3.new(4, bridgeHeight, 4), Vector3.new(x, bridgeHeight/2, 0), Color3.new(0.5, 0.5, 0.5), Enum.Material.Concrete, model)
	end
	
	-- 접근 계단 (양 끝에)
	local rampLength = 30
	local rampHeight = bridgeHeight
	
	-- 서쪽 램프
	local rampW = createPart("RampW", Vector3.new(rampLength, 2, bridgeWidth), Vector3.new(-mapSize/2 + rampLength/2, bridgeHeight/2, 0), Color3.new(0.6, 0.6, 0.6), Enum.Material.Concrete, model)
	rampW.Orientation = Vector3.new(0, 0, math.deg(math.atan2(bridgeHeight, rampLength)))
	
	-- 동쪽 램프
	local rampE = createPart("RampE", Vector3.new(rampLength, 2, bridgeWidth), Vector3.new(mapSize/2 - rampLength/2, bridgeHeight/2, 0), Color3.new(0.6, 0.6, 0.6), Enum.Material.Concrete, model)
	rampE.Orientation = Vector3.new(0, 0, -math.deg(math.atan2(bridgeHeight, rampLength)))
end

return MapGenerator
