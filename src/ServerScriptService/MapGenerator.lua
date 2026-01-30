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
	print("Generating Rural Valley Map with Flat Building Pads & Winding Road...")

	-- 기존 맵 초기화
	local mapFolder = workspace:FindFirstChild("Map")
	if mapFolder then mapFolder:Destroy() end
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace

	-- 기본 Baseplate 제거
	local baseplate = workspace:FindFirstChild("Baseplate") or workspace:FindFirstChild("BasePlate")
	if baseplate then baseplate:Destroy() end

	local mapSize = Config.Map.Size -- 200
	local halfSize = mapSize / 2
	local blockSize = 10 -- Main coarse grid size

	local groundFolder = Instance.new("Folder")
	groundFolder.Name = "Ground"
	groundFolder.Parent = mapFolder
	
	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "Roads"
	roadFolder.Parent = mapFolder
	
	local buildingsFolder = Instance.new("Folder")
	buildingsFolder.Name = "Buildings"
	buildingsFolder.Parent = mapFolder

	math.randomseed(os.time())
	local seed = math.random(1, 10000)

	-- Road Parameters (Winding) - From Config
	local roadWidth = Config.Map.Road.Width
	local roadAmplitude = Config.Map.Road.Amplitude
	local roadFrequency = Config.Map.Road.Frequency
	local roadBlockSize = Config.Map.Road.BlockSize

	local function getRoadX(z)
		return roadAmplitude * math.sin(z * roadFrequency)
	end

	-- 지형 높이 함수
	local function getHeight(x, z)
		local noiseScale = 60
		local heightScale = 20
		local noiseVal = math.noise(x / noiseScale + seed, z / noiseScale + seed, 0) * heightScale

		local dist = math.sqrt(x^2 + z^2)
		local valleyFactor = (dist / halfSize) ^ 2
		local mountainHeight = valleyFactor * 30 -- Reduced height
		
		-- Flatten Center Logic
		local flatRadius = 80
		local innerFlatRadius = 40
		local centerDamp = 1
		
		if dist < innerFlatRadius then
			centerDamp = 0
		elseif dist < flatRadius then
			local t = (dist - innerFlatRadius) / (flatRadius - innerFlatRadius)
			centerDamp = t * t * (3 - 2 * t)
		end
		
		local baseHeight = (noiseVal + mountainHeight) * centerDamp
		
		-- Road Flattening Logic
		local roadX = getRoadX(z)
		local distToRoad = math.abs(x - roadX)
		local roadInfluence = 45
		
		if distToRoad < roadInfluence then
			local t = distToRoad / roadInfluence
			t = t * t * (3 - 2 * t) 
			baseHeight = baseHeight * t
		end

		return math.floor(baseHeight)
	end
	
	-- Helper to generate a single terrain block (of any size)
	local function generateTerrainBlock(x, z, size)
		local y = getHeight(x, z)
		
		local color
		local material = Enum.Material.Plastic

		if y < 3 then
			color = Color3.fromRGB(75, 151, 75)
			material = Enum.Material.Grass
		elseif y < 30 then
			color = Color3.fromRGB(50, 120, 50)
			material = Enum.Material.Grass
		else
			color = Color3.fromRGB(90, 100, 110)
			material = Enum.Material.Slate
		end

		createPart("Terrain", Vector3.new(size, size*4, size), Vector3.new(x + size/2, y - size*2, z + size/2), color, material, groundFolder)
	end

	-- Adaptive Generation Loop
	-- Iterate carefully using the coarse block size
	for x = -halfSize, halfSize - blockSize, blockSize do
		for z = -halfSize, halfSize - blockSize, blockSize do
			
			local centerX = x + blockSize/2
			local centerZ = z + blockSize/2
			
			-- Check if this large block is near the road
			-- We need to check minimal distance to the road curve within this Z range
			-- Simple check: Evaluate roadX at centerZ.
			
			local roadX = getRoadX(centerZ)
			local distToRoad = math.abs(centerX - roadX)
			
			-- Conservative Check: RoadWidth/2 + BlockSize (diagonal approx) + Buffer
			-- If close to road, SUBDIVIDE.
			if distToRoad < (roadWidth / 2) + 15 then
				
				-- SUBDIVIDE into 2x2 blocks
				for subX = x, x + blockSize - roadBlockSize, roadBlockSize do
					for subZ = z, z + blockSize - roadBlockSize, roadBlockSize do
						
						local subCenterX = subX + roadBlockSize/2
						local subCenterZ = subZ + roadBlockSize/2
						
						local subRoadX = getRoadX(subCenterZ)
						local subDist = math.abs(subCenterX - subRoadX)
						
						if subDist < roadWidth / 2 then
							-- ROAD BLOCK
							createPart("RoadBlock", Vector3.new(roadBlockSize, 1, roadBlockSize), Vector3.new(subCenterX, 0.5, subCenterZ), Color3.fromRGB(60, 60, 60), Enum.Material.Asphalt, roadFolder)
							-- Filler under road
							createPart("RoadBed", Vector3.new(roadBlockSize, 20, roadBlockSize), Vector3.new(subCenterX, 0 - 10, subCenterZ), Color3.fromRGB(100, 80, 60), Enum.Material.Slate, groundFolder)
						else
							-- TERRAIN BLOCK (Small)
							generateTerrainBlock(subX, subZ, roadBlockSize)
						end
					end
				end
				
			else
				-- FAR FROM ROAD: Generate Single Large Block (Optimized)
				generateTerrainBlock(x, z, blockSize)
				
				-- REMOVED House and Tree generation per user request.
				-- Only Terrain and Road remaining.
			end
		end
	end

	-- Tunnels at ends
	local function createTunnel(z, roadX)
		local tunnelModel = Instance.new("Model")
		tunnelModel.Name = "Tunnel"
		tunnelModel.Parent = mapFolder
		
		-- Tunnel Frame Dimensions
		local tWidth = roadWidth + 10
		local tHeight = 20
		local tLength = 10
		local wallThickness = 4
		
		-- Left Wall
		createPart("WallL", Vector3.new(wallThickness, tHeight, tLength), Vector3.new(roadX - roadWidth/2 - wallThickness/2, tHeight/2, z), Color3.fromRGB(80, 80, 80), Enum.Material.Concrete, tunnelModel)
		-- Right Wall
		createPart("WallR", Vector3.new(wallThickness, tHeight, tLength), Vector3.new(roadX + roadWidth/2 + wallThickness/2, tHeight/2, z), Color3.fromRGB(80, 80, 80), Enum.Material.Concrete, tunnelModel)
		-- Ceiling
		createPart("Ceiling", Vector3.new(tWidth + wallThickness*2, wallThickness, tLength), Vector3.new(roadX, tHeight + wallThickness/2, z), Color3.fromRGB(80, 80, 80), Enum.Material.Concrete, tunnelModel)
		
		-- Black Void (Blockade)
		local voidPart = createPart("TunnelVoid", Vector3.new(tWidth - 2, tHeight, 2), Vector3.new(roadX, tHeight/2, z), Color3.fromRGB(0, 0, 0), Enum.Material.Neon, tunnelModel)
		
	end
	
	-- Create Tunnels at both ends
	-- Slightly inside the map so player sees them before falling off
	-- Map halfSize is 100. Let's place at +/- 95
	createTunnel(-halfSize + 5, getRoadX(-halfSize + 5))
	createTunnel(halfSize - 5, getRoadX(halfSize - 5))

	-- 스폰 위치
	MapGenerator.CreateSpawnLocations(mapFolder, mapSize)

	-- 경계
	MapGenerator.CreateBoundaryZone(mapFolder, mapSize)

	print("Rural Valley Map Generated!")
end
-- 가로등 배치
function MapGenerator.CreateStreetLamps(parent, mapSize, roadWidth, blockSize)
	local lampsFolder = Instance.new("Folder")
	lampsFolder.Name = "StreetLamps"
	lampsFolder.Parent = parent
	
	local halfSize = mapSize / 2
	
	-- 격자 도로를 따라 배치 (교차로 제외)
	for x = -halfSize + blockSize/2, halfSize - blockSize/2, blockSize do
		for z = -halfSize + blockSize/2, halfSize - blockSize/2, blockSize do
			-- 블록 네 모퉁이에 가로등 배치
			local offset = blockSize/2 - 4 -- 도로 경계에서 약간 안쪽
			
			-- 4개 코너
			MapGenerator.CreateLamp(x - offset, 0, z - offset, lampsFolder)
			MapGenerator.CreateLamp(x + offset, 0, z - offset, lampsFolder)
			MapGenerator.CreateLamp(x - offset, 0, z + offset, lampsFolder)
			MapGenerator.CreateLamp(x + offset, 0, z + offset, lampsFolder)
		end
	end
end

function MapGenerator.CreateLamp(x, y, z, parent)
	local model = Instance.new("Model")
	model.Name = "StreetLamp"
	model.Parent = parent
	
	-- 기둥
	createPart("Pole", Vector3.new(1, 12, 1), Vector3.new(x, y + 6, z), Color3.fromRGB(50, 50, 50), Enum.Material.Metal, model)
	
	-- 헤드 (ㄱ자 형태)
	createPart("Arm", Vector3.new(3, 1, 1), Vector3.new(x + 1, y + 11.5, z), Color3.fromRGB(50, 50, 50), Enum.Material.Metal, model)
	
	-- 불빛 (꺼짐)
	local lightPart = createPart("Light", Vector3.new(1, 0.5, 1), Vector3.new(x + 2, y + 11, z), Color3.fromRGB(200, 200, 200), Enum.Material.Plastic, model)
	-- PointLight 제거됨
end

-- 나무 생성
function MapGenerator.CreateTree(x, y, z, parent)
	local model = Instance.new("Model")
	model.Name = "Tree"
	model.Parent = parent
	
	-- 줄기
	local trunkHeight = math.random(6, 9)
	createPart("Trunk", Vector3.new(2, trunkHeight, 2), Vector3.new(x, y + trunkHeight/2, z), Color3.fromRGB(100, 60, 30), Enum.Material.Wood, model)
	
	-- 나뭇잎 (구형)
	local leavesSize = math.random(8, 12)
	local leaves = createPart("Leaves", Vector3.new(leavesSize, leavesSize, leavesSize), Vector3.new(x, y + trunkHeight + leavesSize/3, z), Color3.fromRGB(50, 150, 50), Enum.Material.Plastic, model)
	leaves.Shape = Enum.PartType.Ball
end

-- 우편함 생성
function MapGenerator.CreateMailbox(x, y, z, parent)
	local model = Instance.new("Model")
	model.Name = "Mailbox"
	model.Parent = parent
	
	-- 기둥
	createPart("Post", Vector3.new(0.5, 3, 0.5), Vector3.new(x, y + 1.5, z), Color3.fromRGB(200, 200, 200), Enum.Material.Metal, model)
	
	-- 박스
	createPart("Box", Vector3.new(1.5, 1, 2), Vector3.new(x, y + 3, z), Color3.fromRGB(50, 50, 200), Enum.Material.Plastic, model)
	
	-- 깃발
	createPart("Flag", Vector3.new(0.2, 0.8, 0.2), Vector3.new(x + 0.8, y + 3.5, z), Color3.fromRGB(200, 50, 50), Enum.Material.Plastic, model)
end

-- 공원 생성
function MapGenerator.CreatePark(x, y, z, parent)
	local model = Instance.new("Model")
	model.Name = "Park"
	model.Parent = parent
	
	-- 잔디밭 (약간 솟아오름)
	local parkSize = 40
	createPart("Grass", Vector3.new(parkSize, 0.5, parkSize), Vector3.new(x, y + 0.25, z), Color3.fromRGB(60, 160, 60), Enum.Material.Grass, model)
	
	-- 분수대 (중앙)
	MapGenerator.CreateFountain(x, y + 0.5, z, model)
	
	-- 나무 배치 (4면)
	local treeOffset = 15
	MapGenerator.CreateTree(x - treeOffset, y, z - treeOffset, model)
	MapGenerator.CreateTree(x + treeOffset, y, z - treeOffset, model)
	MapGenerator.CreateTree(x - treeOffset, y, z + treeOffset, model)
	MapGenerator.CreateTree(x + treeOffset, y, z + treeOffset, model)
	
	-- 벤치 (생략 가능하지만 간단하게)
	createPart("Bench1", Vector3.new(6, 1.5, 2), Vector3.new(x, y + 0.75, z - 10), Color3.fromRGB(130, 90, 50), Enum.Material.Wood, model)
	createPart("Bench2", Vector3.new(6, 1.5, 2), Vector3.new(x, y + 0.75, z + 10), Color3.fromRGB(130, 90, 50), Enum.Material.Wood, model)
end

-- 분수대 생성
function MapGenerator.CreateFountain(x, y, z, parent)
	local model = Instance.new("Model")
	model.Name = "Fountain"
	model.Parent = parent
	
	-- 받침대
	createPart("Base", Vector3.new(12, 1, 12), Vector3.new(x, y + 0.5, z), Color3.fromRGB(200, 200, 200), Enum.Material.Concrete, model)
	
	-- 물통
	local pool = createPart("Pool", Vector3.new(10, 1.5, 10), Vector3.new(x, y + 1.25, z), Color3.fromRGB(50, 150, 255), Enum.Material.Plastic, model)
	pool.Transparency = 0.3
	
	-- 중앙 기둥
	createPart("Pillar", Vector3.new(2, 5, 2), Vector3.new(x, y + 2.5, z), Color3.fromRGB(220, 220, 220), Enum.Material.Concrete, model)
	
	-- 물 뿜기 (파티클 대신 파트로 표현)
	local waterTop = createPart("WaterTop", Vector3.new(4, 0.5, 4), Vector3.new(x, y + 5, z), Color3.fromRGB(100, 200, 255), Enum.Material.Plastic, model)
end

-- 경계 구역 생성 함수 (맵 바깥에 경고 구역)
function MapGenerator.CreateBoundaryZone(parent, mapSize)
	local halfSize = mapSize / 2
	local warningWidth = 15 -- 붉은 경고 구역 너비
	local groundY = 0
	
	local boundaryFolder = Instance.new("Folder")
	boundaryFolder.Name = "Boundary"
	boundaryFolder.Parent = parent
	
	-- 붉은 경고 구역 (맵 바깥쪽 4면)
	local warningColor = Color3.fromRGB(150, 30, 30)
	local totalWidth = mapSize + warningWidth -- 경고 구역 포함 전체 너비
	local warningPositions = {
		-- 북쪽 (맵 바깥)
		{pos = Vector3.new(0, groundY + 0.6, -halfSize - warningWidth/2), size = Vector3.new(totalWidth, 0.5, warningWidth)},
		-- 남쪽 (맵 바깥)
		{pos = Vector3.new(0, groundY + 0.6, halfSize + warningWidth/2), size = Vector3.new(totalWidth, 0.5, warningWidth)},
		-- 서쪽 (맵 바깥)
		{pos = Vector3.new(-halfSize - warningWidth/2, groundY + 0.6, 0), size = Vector3.new(warningWidth, 0.5, mapSize)},
		-- 동쪽 (맵 바깥)
		{pos = Vector3.new(halfSize + warningWidth/2, groundY + 0.6, 0), size = Vector3.new(warningWidth, 0.5, mapSize)},
	}
	
	for i, data in ipairs(warningPositions) do
		local warning = Instance.new("Part")
		warning.Name = "WarningZone" .. i
		warning.Size = data.size
		warning.Position = data.pos
		warning.Color = warningColor
		warning.Material = Enum.Material.Neon
		warning.Transparency = 0.3
		warning.Anchored = true
		warning.CanCollide = true -- 플레이어가 밟을 수 있게
		warning.Parent = boundaryFolder
		
		warning:SetAttribute("DamageZone", true)
	end
	
	-- 킬 브릭 (바닥 아래)
	local killBrick = Instance.new("Part")
	killBrick.Name = "KillBrick"
	killBrick.Size = Vector3.new(mapSize * 3, 10, mapSize * 3)
	killBrick.Position = Vector3.new(0, -100, 0)
	killBrick.Color = Color3.new(0, 0, 0)
	killBrick.Transparency = 1
	killBrick.Anchored = true
	killBrick.CanCollide = false
	killBrick.Parent = boundaryFolder
	killBrick:SetAttribute("KillZone", true)
end

-- 스폰 위치 생성 함수 (마을 중앙 광장 근처)
function MapGenerator.CreateSpawnLocations(parent, mapSize)
	-- 중앙 근처 4곳에 배치
	local offset = 10
	local spawnY = 8 -- 지형 높이 고려하여 약간 띄움 (레이캐스트 등으로 정확히 할 수도 있음)
	
	local spawnPositions = {
		{pos = Vector3.new(0, spawnY, -offset), lookAt = Vector3.new(0, spawnY, 0)}, -- 북
		{pos = Vector3.new(0, spawnY, offset), lookAt = Vector3.new(0, spawnY, 0)},  -- 남
		{pos = Vector3.new(-offset, spawnY, 0), lookAt = Vector3.new(0, spawnY, 0)}, -- 서
		{pos = Vector3.new(offset, spawnY, 0), lookAt = Vector3.new(0, spawnY, 0)},  -- 동
	}
	
	for i, spawnData in ipairs(spawnPositions) do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn" .. i
		spawn.Size = Vector3.new(6, 1, 6)
		spawn.CFrame = CFrame.lookAt(spawnData.pos, spawnData.lookAt)
		spawn.Anchored = true
		spawn.CanCollide = false
		spawn.Neutral = true
		spawn.Transparency = 1 -- 투명하게 숨김
		spawn.Parent = parent
	end
end

function MapGenerator.CreateBuilding(x, y, z, parent)
	-- 레고 스타일 집 (다양성 추가)
	local houseWidth = math.random(18, 24)
	local houseDepth = math.random(16, 22)
	local floorHeight = 8 -- 각 층 높이
	local roofHeight = 6 -- 지붕 높이
	
	-- 층수 결정 (1층 또는 2층)
	local floors = math.random(1, 2)
	
	-- 색상 팔레트 (너무 밝지 않게 조정)
	local wallColors = {
		Color3.fromRGB(220, 220, 220), -- White (Dartkened)
		Color3.fromRGB(230, 230, 210), -- Beige
		Color3.fromRGB(140, 170, 200), -- Sand Blue
		Color3.fromRGB(240, 220, 140), -- Light Yellow
		Color3.fromRGB(180, 200, 160), -- Light Green
	}
	local roofColors = {
		Color3.fromRGB(180, 40, 40), -- Red
		Color3.fromRGB(40, 80, 150), -- Blue
		Color3.fromRGB(40, 90, 40),  -- Green
		Color3.fromRGB(50, 50, 50),  -- Black
		Color3.fromRGB(100, 60, 40), -- Brown
	}
	
	local wallColor = wallColors[math.random(#wallColors)]
	local roofColor = roofColors[math.random(#roofColors)]
	local windowColor = Color3.fromRGB(100, 150, 200) -- 파란 창문
	local doorColor = Color3.fromRGB(80, 50, 30) -- 갈색 문
	
	local model = Instance.new("Model")
	model.Name = "House"
	model.Parent = parent
	
	-- 1층 벽 (SmoothPlastic -> Plastic)
	createPart("Floor1", Vector3.new(houseWidth, floorHeight, houseDepth), 
		Vector3.new(x, y + floorHeight/2, z), wallColor, Enum.Material.Plastic, model)
	
	-- 2층 벽 (있을 경우)
	if floors == 2 then
		createPart("Floor2", Vector3.new(houseWidth, floorHeight, houseDepth), 
			Vector3.new(x, y + floorHeight + floorHeight/2, z), wallColor, Enum.Material.Plastic, model)
	end
	
	-- 총 벽 높이 계산
	local totalWallHeight = floorHeight * floors
	
	-- 삼각 지붕 (Wedge 대신 두 개의 기울어진 파트로 표현)
	local roofThick = 1.5
	local roofOverhang = 2 -- 지붕이 벽 밖으로 튀어나오는 정도
	
	-- 지붕 왼쪽 면
	local roofLeft = createPart("RoofLeft", Vector3.new(houseWidth + roofOverhang*2, roofThick, houseDepth/2 + roofOverhang), 
		Vector3.new(x, y + totalWallHeight + roofHeight/2, z - houseDepth/4), roofColor, Enum.Material.Plastic, model)
	roofLeft.Orientation = Vector3.new(-30, 0, 0) -- 기울기
	
	-- 지붕 오른쪽 면
	local roofRight = createPart("RoofRight", Vector3.new(houseWidth + roofOverhang*2, roofThick, houseDepth/2 + roofOverhang), 
		Vector3.new(x, y + totalWallHeight + roofHeight/2, z + houseDepth/4), roofColor, Enum.Material.Plastic, model)
	roofRight.Orientation = Vector3.new(30, 0, 0) -- 반대쪽 기울기
	
	-- 지붕 꼭대기 (마감 - 작은 틈 메우기)
	createPart("RoofTop", Vector3.new(houseWidth + roofOverhang*2, roofThick, roofThick), 
		Vector3.new(x, y + totalWallHeight + roofHeight, z), roofColor, Enum.Material.Plastic, model)
	
	-- 1층 창문들 (앞면) - 불 꺼진 창문
	local windowSize = Vector3.new(3, 4, 0.5)
	local darkWindowColor = Color3.fromRGB(30, 40, 50) -- 어두운 색
	createPart("Window1F_L", windowSize, Vector3.new(x - houseWidth/4, y + floorHeight/2, z - houseDepth/2 - 0.2), darkWindowColor, Enum.Material.Plastic, model)
	createPart("Window1F_R", windowSize, Vector3.new(x + houseWidth/4, y + floorHeight/2, z - houseDepth/2 - 0.2), darkWindowColor, Enum.Material.Plastic, model)
	
	-- 2층 창문들 (앞면, 2층일 때만)
	if floors == 2 then
		createPart("Window2F_L", windowSize, Vector3.new(x - houseWidth/4, y + floorHeight + floorHeight/2, z - houseDepth/2 - 0.2), darkWindowColor, Enum.Material.Plastic, model)
		createPart("Window2F_R", windowSize, Vector3.new(x + houseWidth/4, y + floorHeight + floorHeight/2, z - houseDepth/2 - 0.2), darkWindowColor, Enum.Material.Plastic, model)
	end
	
	-- 문 (앞면 중앙)
	createPart("Door", Vector3.new(4, 6, 0.5), Vector3.new(x, y + 3, z - houseDepth/2 - 0.2), doorColor, Enum.Material.Wood, model)
	
	-- 굴뚝 (랜덤 위치)
	local chimneySize = Vector3.new(2, 5, 2)
	local chimneyX = (math.random() > 0.5) and (x + houseWidth/3) or (x - houseWidth/3) -- 왼쪽 또는 오른쪽
	createPart("Chimney", chimneySize, Vector3.new(chimneyX, y + totalWallHeight + roofHeight + 1, z), Color3.fromRGB(100, 80, 70), Enum.Material.Brick, model)
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
