-- MapGenerator.lua
-- ServerScriptService에 위치해야 합니다.
print("[MapGenerator] SCRIPT START - Reading file...")
-- 게임 시작 시 도시 맵을 생성합니다.
print("[MapGenerator] Loaded v4.27d (Faster Search + Steady FOV)")

local HttpService = game:GetService("HttpService")

local MapGenerator = {}

-- [Hoisted Constants] Cat Variety Data
if not _G.FoodClaims then
	_G.FoodClaims = setmetatable({}, {__mode = "k"}) -- [v4.12] Global Singleton Lock
end
local FoodClaims = _G.FoodClaims 
local CAT_COLORS = {
	White = Color3.fromRGB(245, 245, 245),
	Black = Color3.fromRGB(30, 30, 30),
	Orange = Color3.fromRGB(220, 140, 60),
	Grey = Color3.fromRGB(120, 120, 120),
	Cream = Color3.fromRGB(240, 230, 200),
	Brown = Color3.fromRGB(100, 70, 50),
	DarkGrey = Color3.fromRGB(60, 60, 60),
}

local CAT_EYE_COLORS = {
	Color3.fromRGB(0, 220, 255), -- Cyan
	Color3.fromRGB(100, 255, 100), -- Green
	Color3.fromRGB(255, 220, 0), -- Yellow
	Color3.fromRGB(255, 150, 0), -- Amber
}

local CAT_PATTERN_TYPES = {"Solid", "Tuxedo", "Spotted", "Calico", "Pointed", "Tabby"}

local Config = require(game.ReplicatedStorage:WaitForChild("Config"))
local DataStoreService = game:GetService("DataStoreService")
local CityMapStore
local success, result = pcall(function()
	return DataStoreService:GetDataStore("CityMapData_v1")
end)

if success then
	CityMapStore = result
else
	warn("⚠️ DataStore Service Unavailable (Publish Place to fix): " .. tostring(result))
end

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

-- [Helper] Safely get position from Model, Part, or Accessory
local function getItemPos(item)
	if not item then return nil end
	if item:IsA("PVInstance") then
		return item:GetPivot().Position
	elseif item:IsA("Accessory") and item:FindFirstChild("Handle") then
		return item.Handle.Position
	end
	return nil
end

function MapGenerator.ClearMap()
	local mapFolder = workspace:FindFirstChild("Map")
	if mapFolder then mapFolder:Destroy() end
end

-- 조명 설정 (눈부심 제거)
function MapGenerator.SetupLighting()
	local Lighting = game:GetService("Lighting")
	
	-- 1. Remove Glare Effects & Force Zero Bloom
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("PostEffect") then
			child:Destroy()
		end
	end
	
	local noBloom = Instance.new("BloomEffect")
	noBloom.Name = "NoBloom"
	noBloom.Intensity = 0
	noBloom.Size = 0
	noBloom.Threshold = 100
	noBloom.Enabled = true
	noBloom.Parent = Lighting
	
	-- 2. Neutral Lighting Settings
	Lighting.GlobalShadows = true
	Lighting.Brightness = 2
	Lighting.ClockTime = 14 -- Afternoon
	Lighting.ExposureCompensation = 0 
	Lighting.Ambient = Color3.fromRGB(150, 150, 150)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
	
	-- [Critical] Disable PBR Reflections (Prevents "Glow" popping in)
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
end

-- 로비 생성 (Grand Indoor Hall - High Ceiling 1st Floor)
function MapGenerator.GenerateLobby()
	-- 기존 맵 초기화
	MapGenerator.ClearMap()
	
	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace
	
	local lobbyY = 200 -- Sky Lobby Height
	local lobbyWidth = 160 -- Expanded for 30 players
	local lobbyDepth = 160
	local ceilingHeight = 60 -- Taller ceiling for grander feel
	
	-- print("Generating Grand Indoor Lobby (Expanded & Open)...")
	
	-- [Lighting Fix] Remove "Dazzling" Effects (Bloom, Glare)
	MapGenerator.SetupLighting()
	
	-- 1. 바닥 (Floor) - Lighter Wood
	createPart("LobbyFloor", Vector3.new(lobbyWidth, 1, lobbyDepth), Vector3.new(0, lobbyY, 0), Color3.fromRGB(220, 190, 150), Enum.Material.WoodPlanks, mapFolder)
	
	-- 2. 천장 (Ceiling) - Darker
	createPart("LobbyCeiling", Vector3.new(lobbyWidth, 1, lobbyDepth), Vector3.new(0, lobbyY + ceilingHeight, 0), Color3.fromRGB(60, 60, 70), Enum.Material.Concrete, mapFolder)
	
	-- 3. 벽 (Walls)
	local wallColor = Color3.fromRGB(230, 230, 220)
	local wallMat = Enum.Material.Concrete
	
	-- Back Wall (North)
	createPart("WallBack", Vector3.new(lobbyWidth, ceilingHeight, 2), Vector3.new(0, lobbyY + ceilingHeight/2, -lobbyDepth/2), wallColor, wallMat, mapFolder)
	-- Front Wall (South)
	createPart("WallFront", Vector3.new(lobbyWidth, ceilingHeight, 2), Vector3.new(0, lobbyY + ceilingHeight/2, lobbyDepth/2), wallColor, wallMat, mapFolder)
	-- Left Wall (West)
	createPart("WallLeft", Vector3.new(2, ceilingHeight, lobbyDepth), Vector3.new(-lobbyWidth/2, lobbyY + ceilingHeight/2, 0), wallColor, wallMat, mapFolder)
	-- Right Wall (East)
	createPart("WallRight", Vector3.new(2, ceilingHeight, lobbyDepth), Vector3.new(lobbyWidth/2, lobbyY + ceilingHeight/2, 0), wallColor, wallMat, mapFolder)
	
	-- 4. 기둥 (Pillars) - REMOVED (User Request: "Stuffy")
	
	-- 5. 조명 (Ceiling Lights)
	local lightFolder = Instance.new("Folder")
	lightFolder.Name = "LobbyLights"
	lightFolder.Parent = mapFolder
	
	-- Simplify lighting grid since no pillars
	local lightSpace = 40
	local halfW = lobbyWidth/2 - 20
	local halfD = lobbyDepth/2 - 20
	
	for x = -halfW, halfW, lightSpace do
		for z = -halfD, halfD, lightSpace do
			local lightPart = createPart("CeilingLamp", Vector3.new(8, 1, 8), Vector3.new(x, lobbyY + ceilingHeight - 1, z), Color3.fromRGB(255, 255, 200), Enum.Material.Neon, lightFolder)
			local pointLight = Instance.new("PointLight")
			pointLight.Range = 70
			pointLight.Brightness = 1.0
			pointLight.Parent = lightPart
		end
	end
	
	-- 6. 길드 게시판 (로비 중앙 배치 - 4면)
	MapGenerator.CreateNoticeBoard(0, lobbyY, 0, mapFolder)
	
	-- 7. 스폰 (남쪽에서 중앙을 바라봄)
	local spawnZ = 60 -- Distance from center
	local spawnPos = Vector3.new(0, lobbyY + 2, spawnZ)
	local centerPos = Vector3.new(0, lobbyY, 0)
	
	MapGenerator.CreateSpawnLocations(mapFolder, 100, spawnPos, centerPos)
end

-- 게임 맵 생성 (Ground Village)
function MapGenerator.GenerateProcedural()
	-- 기존 맵(로비 등) 초기화
	MapGenerator.ClearMap()

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace

	-- 기본 Baseplate 제거
	local baseplate = workspace:FindFirstChild("Baseplate") or workspace:FindFirstChild("BasePlate")
	if baseplate then baseplate:Destroy() end

	local mapSize = Config.Map.Size
	local halfSize = mapSize / 2
	local blockSize = 10
	
	local groundFolder = Instance.new("Folder")
	groundFolder.Name = "Ground"
	groundFolder.Parent = mapFolder
	
	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "Roads"
	roadFolder.Parent = mapFolder
	
	local buildingsFolder = Instance.new("Folder")
	buildingsFolder.Name = "Buildings"
	buildingsFolder.Parent = mapFolder

	-- math.randomseed(os.time())
	-- math.randomseed(os.time())
	local seed = os.time() -- [Modified] Dynamic Seed for true randomness
	math.randomseed(seed)

	-- Road Parameters (Winding)
	local roadWidth = Config.Map.Road.Width
	local roadAmplitude = Config.Map.Road.Amplitude
	local roadFrequency = Config.Map.Road.Frequency
	local roadBlockSize = Config.Map.Road.BlockSize
	
	local function getRoadX(z)
		return roadAmplitude * math.sin(z * roadFrequency)
	end
	
	-- ... (Height logic shared or copied - keeping inline for now)
	-- [Reverted] Back to Single-Pass Generation
	
	local function getHeight(x, z)
		local noiseScale = 60
		local heightScale = 10 -- [Modified] Reduced from 20 to 10
		local noiseVal = math.noise(x / noiseScale + seed, z / noiseScale + seed, 0) * heightScale
		local dist = math.sqrt(x^2 + z^2)
		local valleyFactor = (dist / halfSize) ^ 2
		local mountainHeight = valleyFactor * 15 -- [Modified] Reduced from 30 to 15
		local flatRadius = 80
		local innerFlatRadius = 40
		local centerDamp = 1
		if dist < innerFlatRadius then centerDamp = 0
		elseif dist < flatRadius then
			local t = (dist - innerFlatRadius) / (flatRadius - innerFlatRadius)
			centerDamp = t * t * (3 - 2 * t)
		end
		local baseHeight = (noiseVal + mountainHeight) * centerDamp
		local roadX = getRoadX(z)
		local distToRoad = math.abs(x - roadX)
		
		-- [Modified] Force Flatness near Road to prevent clipping
		if distToRoad < 16 then -- Increased from 12 to 16 for safety
			return 0
		end
		
		local roadInfluence = 45
		if distToRoad < roadInfluence then
			local t = distToRoad / roadInfluence
			t = t * t * (3 - 2 * t) 
			baseHeight = baseHeight * t
		end
		return math.floor(baseHeight)
	end
	
	local function generateTerrainBlock(x, z, size, overrideY)
		local y = overrideY or getHeight(x, z)
		local color
		local material = Enum.Material.Plastic
		if y < 3 then color = Color3.fromRGB(75, 151, 75); material = Enum.Material.Grass
		elseif y < 30 then color = Color3.fromRGB(50, 120, 50); material = Enum.Material.Grass
		else color = Color3.fromRGB(90, 100, 110); material = Enum.Material.Slate end
		createPart("Terrain", Vector3.new(size, size*4, size), Vector3.new(x + size/2, y - size*2, z + size/2), color, material, groundFolder)
	end

	-- [Data Export] Collection Table
	local mapExportData = {} -- {Type, X, Y, Z, [Extra...]} 1=Terrain, 2=Road, 3=House
	
	-- Helper for export
	local function exportTerrain(x, y, z, size)
		table.insert(mapExportData, {1, x, y, z, size})
	end
	
	local function exportRoad(x, y, z)
		table.insert(mapExportData, {2, x, y, z})
	end
	
	local function exportHouse(x, y, z, lx, lz, r, g, b)
		table.insert(mapExportData, {3, x, y, z, lx, lz, r, g, b})
	end

	-- [Modified] Two-Pass Generation for Limited House Count
	local potentialHouseSpots = {}

	-- Adaptive Generation Loop (Phase 1: Terrain + Spot Collection)
	for x = -halfSize, halfSize - blockSize, blockSize do
		for z = -halfSize, halfSize - blockSize, blockSize do
			local centerX = x + blockSize/2
			local centerZ = z + blockSize/2
			local roadX = getRoadX(centerZ)
			local distToRoad = math.abs(centerX - roadX)
			
			-- 1. Always generate Natural Terrain (10x10)
			generateTerrainBlock(x, z, blockSize)
			local h = getHeight(x, z)
			exportTerrain(x + blockSize/2, h, z + blockSize/2, blockSize)

			-- 2. Check for Road (Phase 1)
			if distToRoad < (roadWidth / 2) + 15 then
				for subX = x, x + blockSize - roadBlockSize, roadBlockSize do
					for subZ = z, z + blockSize - roadBlockSize, roadBlockSize do
						local subCenterX = subX + roadBlockSize/2
						local subCenterZ = subZ + roadBlockSize/2
						local subRoadX = getRoadX(subCenterZ)
						local subDist = math.abs(subCenterX - subRoadX)
						
						if subDist < roadWidth / 2 then
							-- Generate Road ON TOP of the terrain (Raised to 0.51 to touch ground at Y=0)
							createPart("RoadBlock", Vector3.new(roadBlockSize, 1, roadBlockSize), Vector3.new(subCenterX, 0.51, subCenterZ), Color3.fromRGB(60, 60, 60), Enum.Material.Asphalt, roadFolder)
							-- Optional: RoadBed
							exportRoad(subCenterX, 0.51, subCenterZ)
						end
						-- Removing the 'else' branch: No more tiny terrain blocks!
					end
				end
			end
			
			-- 3. Check House Spot Candidate
			local spawnRangeMin = (roadWidth / 2) + 10
			local spawnRangeMax = (roadWidth / 2) + 60
			
			if distToRoad > spawnRangeMin and distToRoad < spawnRangeMax then
				-- Check Height (Natural Flatness)
				local y = h -- Reuse height
				
				-- Only add if terrain is naturally flat (e.g. < 4)
				if y < 4 then
					table.insert(potentialHouseSpots, {x = centerX, y = y, z = centerZ})
				end
			end
		end
	end
	
	-- [Phase 2] Spawn Houses at Fixed Coordinates (User Request)
	-- [Phase 2] Spawn Houses at Fixed Coordinates (User Request)
	local fixedHouseLocations = {
		{x = -40, z = -7, color = Color3.fromRGB(255, 0, 0)},   -- Red House
		{x = 43, z = 13, color = Color3.fromRGB(0, 0, 255)}      -- Blue House
	}
	
	for _, spot in ipairs(fixedHouseLocations) do
		-- Calculate Height at this specific spot
		local y = getHeight(spot.x, spot.z)
		
		-- Spawn with Color
		local house = MapGenerator.CreateBuilding(spot.x, y, spot.z, buildingsFolder, spot.color)
		
		-- Rotation Logic
		if house and house.PrimaryPart then
			local slope = roadAmplitude * roadFrequency * math.cos(spot.z * roadFrequency)
			local roadX = getRoadX(spot.z)
			local lookDir
			if spot.x > roadX then
				lookDir = Vector3.new(-1, 0, slope) -- Right Side
			else
				lookDir = Vector3.new(1, 0, -slope) -- Left Side
			end
			local currentPos = house.PrimaryPart.Position
			local targetPos = currentPos + lookDir
			house:PivotTo(CFrame.lookAt(currentPos, targetPos))
			
			-- Export House with Color
			local c = spot.color
			exportHouse(spot.x, y, spot.z, lookDir.X, lookDir.Z, c.R, c.G, c.B)
			
			-- [Added] Bench next to Blue House (Closer to Road, Aligned)
			if spot.color.B > 0.9 and spot.color.R < 0.1 then
				local benchZ = spot.z - 18
				local benchX = spot.x - 22 -- Closer to road
				
				local bench = createPart("Bench", Vector3.new(2, 1.5, 6), Vector3.new(benchX, y + 0.75, benchZ), Color3.fromRGB(130, 90, 50), Enum.Material.Wood, mapFolder)
				
				-- Align with Road Logic
				-- Slope dx/dz = A * f * cos(z * f)
				local s = roadAmplitude * roadFrequency * math.cos(benchZ * roadFrequency)
				local tangent = Vector3.new(s, 0, 1) -- Road Tangent
				bench.CFrame = CFrame.lookAt(bench.Position, bench.Position + tangent)
				
				-- [Added] Grandfather NPC sitting on bench
				-- Offset slightly up (seat surface + hip height). Bench Top is ~ y+1.5. Hips ~ +1.
				local sitCF = bench.CFrame * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, math.rad(-90), 0)
				MapGenerator.SpawnGrandpa(sitCF, mapFolder)
			end
			
			-- [Added] Street Stall (Pojangmacha) near Red House
			if spot.color.R > 0.9 and spot.color.B < 0.1 then
				-- Red House Detected -> Place Stall nearby (e.g. Left side, closer to road)
				local stallZ = spot.z + 18
				local stallX = spot.x + 22 -- Opposite direction of blue house logic roughly
				-- Find Road Y at this spot? Or just use Y (Ground).
				-- Call Helper
				local stall = MapGenerator.CreateStreetStall(stallX, y, stallZ, mapFolder)
				
				-- Align to road?
				if stall and stall.PrimaryPart then
					local s = roadAmplitude * roadFrequency * math.cos(stallZ * roadFrequency)
					local tangent = Vector3.new(s, 0, 1)
					stall:PivotTo(CFrame.lookAt(stall.PrimaryPart.Position, stall.PrimaryPart.Position + tangent) * CFrame.Angles(0, math.rad(90), 0))
					
					-- [Added] Busy Chef NPC
					-- Position: Behind the counter.
					-- Stall Counter is at (x, y+3, z). Depth 4.
					-- "Behind" means towards the road? No, Stall faces Road. Chef stands BEHIND counter, facing Road.
					-- Stall Forward = Road Side. Back = Service Side.
					-- We rotated Stall 90 deg relative to Tangent (Road).
					-- Let's place Chef 3 studs "Back" from Stall Center.
					-- Let's place Chef 3 studs "Back" from Stall Center.
					local chefOffset = stall.PrimaryPart.CFrame.LookVector * -3
					local chefPos = stall.PrimaryPart.Position + chefOffset
					-- Height: Ground (y + 3 is counter top, so y + 1 is torso center).
					
					-- [Fixed] Target must be at same Height (y) to avoid looking up (Pitch) -> Leaning Back
					local targetLook = Vector3.new(stall.PrimaryPart.Position.X, y, stall.PrimaryPart.Position.Z)
					local chefCF = CFrame.lookAt(Vector3.new(chefPos.X, y, chefPos.Z), targetLook)
					MapGenerator.SpawnChef(chefCF, mapFolder)
				end
			end
			-- [DISABLED] User Request: No auto-generated trees
			-- for i = 1, 3 do
			-- 	local attempts = 0
			-- 	local placed = false
			-- 	while attempts < 5 and not placed do
			-- 		attempts += 1
			-- 		local treeOffsetX = math.random(-40, 40)
			-- 		local treeOffsetZ = math.random(-40, 40)
			-- 		-- Avoid placing inside house (simple check: keep distance > 18)
			-- 		if math.abs(treeOffsetX) > 18 or math.abs(treeOffsetZ) > 18 then
			-- 			local tx, ty, tz = spot.x + treeOffsetX, y, spot.z + treeOffsetZ
			-- 			local style = math.random(1, 3) -- [Restored] Random Style
						
			-- 			MapGenerator.SpawnTree(tx, ty, tz, mapFolder, style)
			-- 			table.insert(mapExportData, {4, tx, ty, tz, style}) -- Type 4 = Tree
			-- 			placed = true
			-- 		end
			-- 	end
			-- end
		end
	end
	
	-- Create Tunnels at both ends
	MapGenerator.CreateTunnels(mapFolder, mapSize)
	
	-- 스폰 위치 (Village Spawn)
	MapGenerator.CreateSpawnLocations(mapFolder, mapSize, Vector3.new(0, 8, 0)) -- Ground Spawn

	-- 경계
	MapGenerator.CreateBoundaryZone(mapFolder, mapSize)
	
	-- [Added] Wandering Cats
	local catsFolder = Instance.new("Folder")
	catsFolder.Name = "Cats"
	catsFolder.Parent = mapFolder

	for i = 1, 110 do
		local cx = math.random(-mapSize/2 + 20, mapSize/2 - 20)
		local cz = math.random(-mapSize/2 + 20, mapSize/2 - 20)
		-- 지형 높이 계산하여 정확한 위치에 스폰
		local groundY = getHeight(cx, cz) 
		local catCF = CFrame.new(cx, groundY + 1, cz) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
		MapGenerator.SpawnCat(catCF, catsFolder)
	end
	
	-- [Added] World Items (Disabled temporarily)
	--[[
	local itemsFolder = Instance.new("Folder")
	itemsFolder.Name = "WorldItems"
	itemsFolder.Parent = mapFolder
	
	for i = 1, 20 do
		local iz = math.random(-mapSize/2 + 30, mapSize/2 - 30)
		local roadX = roadAmplitude * math.sin(iz * roadFrequency)
		local offsetX = (math.random() > 0.5) and (roadWidth/2 + 5) or -(roadWidth/2 + 5)
		local ix = roadX + offsetX
		
		MapGenerator.SpawnWorldItem("Stick", Vector3.new(ix, 2, iz), itemsFolder)
	end
	]]
	
	-- [CACHE & EXPORT]
	MapGenerator.CurrentData = mapExportData
	return mapExportData
end

function MapGenerator.LoadMapFromData(mapData)
	print("Loading Map from DataStore...")
	MapGenerator.ClearMap()
	MapGenerator.CurrentData = mapData -- Cache loaded data too

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace

	-- 기본 Baseplate 제거
	local baseplate = workspace:FindFirstChild("Baseplate") or workspace:FindFirstChild("BasePlate")
	if baseplate then baseplate:Destroy() end
	
	local mapSize = Config.Map.Size
	local blockSize = 10
	local roadBlockSize = Config.Map.Road.BlockSize
	
	local groundFolder = Instance.new("Folder")
	groundFolder.Name = "Ground"
	groundFolder.Parent = mapFolder
	
	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "Roads"
	roadFolder.Parent = mapFolder
	
	local buildingsFolder = Instance.new("Folder")
	buildingsFolder.Name = "Buildings"
	buildingsFolder.Parent = mapFolder
	
	-- Reconstruct Map
	for _, item in ipairs(mapData) do
		local typeId = item[1]
		local x, y, z = item[2], item[3], item[4]
		
		if typeId == 1 then -- Terrain
			local size = item[5] or 10 -- [Added] Load size (default 10)
			local color
			local material = Enum.Material.Plastic
			if y < 3 then color = Color3.fromRGB(75, 151, 75); material = Enum.Material.Grass
			elseif y < 30 then color = Color3.fromRGB(50, 120, 50); material = Enum.Material.Grass
			else color = Color3.fromRGB(90, 100, 110); material = Enum.Material.Slate end
			createPart("Terrain", Vector3.new(size, 40, size), Vector3.new(x, y - 20, z), color, material, groundFolder)
			
		elseif typeId == 2 then -- Road
			createPart("RoadBlock", Vector3.new(2, 1, 2), Vector3.new(x, y, z), Color3.fromRGB(60, 60, 60), Enum.Material.Asphalt, roadFolder)
			-- Removed RoadBed reconstruction for now to keep consistent
			-- createPart("RoadBed", Vector3.new(2, 20, 2), Vector3.new(x, y - 10, z), Color3.fromRGB(100, 80, 60), Enum.Material.Slate, groundFolder)
			
		elseif typeId == 3 then -- House {3, x, y, z, lx, lz, r, g, b}
			local lx, lz = item[5], item[6]
			local color = nil
			if item[7] then
				color = Color3.new(item[7], item[8], item[9])
			end
			
			local house = MapGenerator.CreateBuilding(x, y, z, buildingsFolder, color)
			if house and house.PrimaryPart then
				local currentPos = house.PrimaryPart.Position
				local targetPos = currentPos + Vector3.new(lx, 0, lz)
				house:PivotTo(CFrame.lookAt(currentPos, targetPos))
			end

			-- [Added] Bench next to Blue House (Reconstruct)
			if item[9] and item[9] > 0.9 and item[7] < 0.1 then 
				-- Blue House Side (Forward + Aligned)
				local benchZ = z - 18
				local benchX = x - 22
				local bench = createPart("Bench", Vector3.new(2, 1.5, 6), Vector3.new(benchX, y + 0.75, benchZ), Color3.fromRGB(130, 90, 50), Enum.Material.Wood, mapFolder)
				
				-- Recalculate Slope (Config required)
				local amp = Config.Map.Road.Amplitude
				local freq = Config.Map.Road.Frequency
				local s = amp * freq * math.cos(benchZ * freq)
				local tangent = Vector3.new(s, 0, 1)
				bench.CFrame = CFrame.lookAt(bench.Position, bench.Position + tangent)
				
				-- [Added] Grandfather NPC (Reconstruct)
				local sitCF = bench.CFrame * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, math.rad(-90), 0)
				MapGenerator.SpawnGrandpa(sitCF, mapFolder)
				MapGenerator.SpawnGrandpa(sitCF, mapFolder)
			end
			
			-- [Added] Street Stall (Reconstruct near Red House)
			if item[7] > 0.9 and item[9] < 0.1 then -- Red R > 0.9, B < 0.1
				local stallZ = z + 18
				local stallX = x + 22 
				local stall = MapGenerator.CreateStreetStall(stallX, y, stallZ, mapFolder)
				
				local amp = Config.Map.Road.Amplitude
				local freq = Config.Map.Road.Frequency
				local s = amp * freq * math.cos(stallZ * freq)
				local tangent = Vector3.new(s, 0, 1)
				if stall and stall.PrimaryPart then
					stall:PivotTo(CFrame.lookAt(stall.PrimaryPart.Position, stall.PrimaryPart.Position + tangent) * CFrame.Angles(0, math.rad(90), 0))
					
					-- [Added] Busy Chef NPC (Reconstruct)
					local chefOffset = stall.PrimaryPart.CFrame.LookVector * -3
					local chefPos = stall.PrimaryPart.Position + chefOffset
					
					-- [Fixed] Look horizontal
					local targetLook = Vector3.new(stall.PrimaryPart.Position.X, y, stall.PrimaryPart.Position.Z)
					local chefCF = CFrame.lookAt(Vector3.new(chefPos.X, y, chefPos.Z), targetLook)
					MapGenerator.SpawnChef(chefCF, mapFolder)
				end
			end
			
		elseif typeId == 4 then -- [Modified] Tree with Style
			-- Legacy Support: If style missing, pick random instead of default 1
			local style = item[5] or math.random(1, 3) 
			MapGenerator.SpawnTree(x, y, z, groundFolder, style)
		end
	end
	
	MapGenerator.CreateSpawnLocations(mapFolder, mapSize, Vector3.new(0, 8, 0))
	MapGenerator.CreateBoundaryZone(mapFolder, mapSize)
	MapGenerator.CreateTunnels(mapFolder, mapSize) -- [Added] Regenerate Tunnels
	
	-- [Added] Wandering Cats
	local catsFolder = Instance.new("Folder")
	catsFolder.Name = "Cats"
	catsFolder.Parent = mapFolder

	for i = 1, 110 do
		-- Note: getHeight is not available here, but LoadMapFromData usually assumes flat near road or uses saved height.
		-- For simplicity, keeping it at 100 -> 110.
		local cx = math.random(-mapSize/2 + 20, mapSize/2 - 20)
		local cz = math.random(-mapSize/2 + 20, mapSize/2 - 20)
		local catCF = CFrame.new(cx, 1, cz) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
		MapGenerator.SpawnCat(catCF, catsFolder)
	end
end

-- 터널 생성 (Shared)
function MapGenerator.CreateTunnels(parent, mapSize)
	local halfSize = mapSize / 2
	local roadWidth = Config.Map.Road.Width
	local roadAmplitude = Config.Map.Road.Amplitude
	local roadFrequency = Config.Map.Road.Frequency
	
	local function getRoadX(z)
		return roadAmplitude * math.sin(z * roadFrequency)
	end
	
	local function createTunnel(z, roadX)
		local tunnelModel = Instance.new("Model")
		tunnelModel.Name = "Tunnel"
		tunnelModel.Parent = parent
		
		local tWidth = roadWidth + 10
		local tHeight = 20
		local tLength = 10
		local wallThickness = 4
		
		createPart("WallL", Vector3.new(wallThickness, tHeight, tLength), Vector3.new(roadX - roadWidth/2 - wallThickness/2, tHeight/2, z), Color3.fromRGB(80, 80, 80), Enum.Material.Concrete, tunnelModel)
		createPart("WallR", Vector3.new(wallThickness, tHeight, tLength), Vector3.new(roadX + roadWidth/2 + wallThickness/2, tHeight/2, z), Color3.fromRGB(80, 80, 80), Enum.Material.Concrete, tunnelModel)
		createPart("Ceiling", Vector3.new(tWidth + wallThickness*2, wallThickness, tLength), Vector3.new(roadX, tHeight + wallThickness/2, z), Color3.fromRGB(80, 80, 80), Enum.Material.Concrete, tunnelModel)
		createPart("TunnelVoid", Vector3.new(tWidth - 2, tHeight, 2), Vector3.new(roadX, tHeight/2, z), Color3.fromRGB(0, 0, 0), Enum.Material.Neon, tunnelModel)
	end
	
	createTunnel(-halfSize + 5, getRoadX(-halfSize + 5))
	createTunnel(halfSize - 5, getRoadX(halfSize - 5))
end



-- 할아버지 NPC 생성 (Standard R6 Style)
function MapGenerator.SpawnGrandpa(locationCF, parent)
	local model = Instance.new("Model")
	model.Name = "Grandpa"
	model.Parent = parent
	
	-- Humanoid for "Character" look
	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- Hide Name
	hum.Parent = model
	
	-- Colors
	local skinColor = Color3.fromRGB(240, 200, 180)
	local shirtColor = Color3.fromRGB(200, 200, 200)
	local pantsColor = Color3.fromRGB(80, 70, 60)
	local hairColor = Color3.fromRGB(150, 150, 150)
	
	-- Helper
	local function makePart(name, size, color, cf)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = locationCF * cf
		p.Parent = model
		return p
	end
	
	-- 1. Torso (2x2x1)
	-- Pivot is center of bench seat (y+1.8). Torso Center is higher.
	-- Bench Y is "Seat Surface". Torso Center is +1 (Half Torso).
	local torso = makePart("Torso", Vector3.new(2, 2, 1), shirtColor, CFrame.new(0, 1.0, 0))
	
	-- 2. Head (1.25x1.25x1.25) + Mesh
	local head = makePart("Head", Vector3.new(1, 1, 1), skinColor, CFrame.new(0, 2.5, 0))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	
	-- Hair (Block Hat)
	local hair = makePart("Hair", Vector3.new(1.3, 0.4, 1.3), hairColor, CFrame.new(0, 3.2, 0))
	
	-- 3. Arms (1x2x1)
	makePart("Left Arm", Vector3.new(1, 2, 1), shirtColor, CFrame.new(-1.5, 1.0, 0))
	makePart("Right Arm", Vector3.new(1, 2, 1), shirtColor, CFrame.new(1.5, 1.0, 0))
	
	-- 4. Legs (1x2x1) - Sitting (Standard R6 Sit: Legs forward)
	-- Torso Bottom is at 0.0 offset. Leg starts there.
	-- Leg Center would be Z+1 (Forward), Y+0 (Level with Torso bottom? No slightly down?)
	-- Actually: Hip is Torso Bottom. Leg is attached there.
	-- If Leg is horizontal, Center is Z=1.
	makePart("Left Leg", Vector3.new(1, 2, 1), pantsColor, CFrame.new(-0.5, 0.0, -1.0) * CFrame.Angles(math.rad(-90), 0, 0))
	makePart("Right Leg", Vector3.new(1, 2, 1), pantsColor, CFrame.new(0.5, 0.0, -1.0) * CFrame.Angles(math.rad(-90), 0, 0))
end

-- 포장마차 생성
function MapGenerator.CreateStreetStall(x, y, z, parent)
	local model = Instance.new("Model")
	model.Name = "StreetStall"
	model.Parent = parent
	
	-- Colors
	local tentColor = Color3.fromRGB(230, 80, 50) -- Red/Orange Tent
	local metalColor = Color3.fromRGB(180, 180, 180) -- Silver/Metal
	local woodColor = Color3.fromRGB(200, 150, 100) -- Light Wood Counter
	
	-- Helper
	local function addPart(name, size, pos, color, mat, folder)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Color = color
		p.Material = mat
		p.Anchored = true
		p.Parent = folder
		return p
	end
	
	-- 1. Counter (Table)
	-- height ~ 3 studs
	local counterH = 3
	local counterW = 8
	local counterD = 4
	local counter = addPart("Counter", Vector3.new(counterW, 0.5, counterD), Vector3.new(x, y + counterH, z), woodColor, Enum.Material.Wood, model)
	model.PrimaryPart = counter
	
	-- Legs (4)
	local legH = counterH - 0.25
	local legSize = 0.4
	addPart("LegFL", Vector3.new(legSize, legH, legSize), Vector3.new(x - counterW/2 + 0.5, y + legH/2, z - counterD/2 + 0.5), metalColor, Enum.Material.Metal, model)
	addPart("LegFR", Vector3.new(legSize, legH, legSize), Vector3.new(x + counterW/2 - 0.5, y + legH/2, z - counterD/2 + 0.5), metalColor, Enum.Material.Metal, model)
	addPart("LegBL", Vector3.new(legSize, legH, legSize), Vector3.new(x - counterW/2 + 0.5, y + legH/2, z + counterD/2 - 0.5), metalColor, Enum.Material.Metal, model)
	addPart("LegBR", Vector3.new(legSize, legH, legSize), Vector3.new(x + counterW/2 - 0.5, y + legH/2, z + counterD/2 - 0.5), metalColor, Enum.Material.Metal, model)
	
	-- 2. Tent Poles (4 Corners, taller)
	local poleH = 7
	local poleY = y + poleH/2
	local poleOffset = 0.2
	addPart("PoleFL", Vector3.new(0.2, poleH, 0.2), Vector3.new(x - counterW/2 + poleOffset, poleY, z - counterD/2 + poleOffset), metalColor, Enum.Material.Metal, model)
	addPart("PoleFR", Vector3.new(0.2, poleH, 0.2), Vector3.new(x + counterW/2 - poleOffset, poleY, z - counterD/2 + poleOffset), metalColor, Enum.Material.Metal, model)
	addPart("PoleBL", Vector3.new(0.2, poleH, 0.2), Vector3.new(x - counterW/2 + poleOffset, poleY, z + counterD/2 - poleOffset), metalColor, Enum.Material.Metal, model)
	addPart("PoleBR", Vector3.new(0.2, poleH, 0.2), Vector3.new(x + counterW/2 - poleOffset, poleY, z + counterD/2 - poleOffset), metalColor, Enum.Material.Metal, model)
	
	-- 3. Roof (Canvas)
	local roof = addPart("Roof", Vector3.new(counterW + 1, 0.5, counterD + 1), Vector3.new(x, poleY + poleH/2 + 0.25, z), tentColor, Enum.Material.Fabric, model)
	
	-- Stripes (Optional visual detail: White blocks?)
	addPart("Stripe", Vector3.new(counterW + 1.2, 0.6, 1), Vector3.new(x, y + poleH, z), Color3.fromRGB(240, 240, 240), Enum.Material.Fabric, model)
	
	-- 4. Wheels (Cart style)
	local wheelSize = 2.5
	local wheelZ = z
	local wheelOffset = counterW/2
	local w1 = addPart("WheelL", Vector3.new(0.5, wheelSize, wheelSize), Vector3.new(x - wheelOffset, y + wheelSize/2, z), Color3.fromRGB(20, 20, 20), Enum.Material.Rubber, model)
	w1.Shape = Enum.PartType.Cylinder
	w1.Orientation = Vector3.new(0, 0, 90)
	
	local w2 = addPart("WheelR", Vector3.new(0.5, wheelSize, wheelSize), Vector3.new(x + wheelOffset, y + wheelSize/2, z), Color3.fromRGB(20, 20, 20), Enum.Material.Rubber, model)
	w2.Shape = Enum.PartType.Cylinder
	w2.Orientation = Vector3.new(0, 0, 90)
	
	-- 5. Food Props
	-- Tteokbokki Plate (Red)
	addPart("Plate", Vector3.new(1.5, 0.2, 1), Vector3.new(x - 1.5, y + counterH + 0.35, z + 0.5), Color3.fromRGB(255, 255, 255), Enum.Material.Plastic, model)
	addPart("Food", Vector3.new(1.2, 0.2, 0.8), Vector3.new(x - 1.5, y + counterH + 0.55, z + 0.5), Color3.fromRGB(200, 50, 0), Enum.Material.Neon, model) -- Spicy Red
	
	-- Odeng Pot (Metal + Sticks)
	addPart("Pot", Vector3.new(1.2, 0.6, 1.2), Vector3.new(x + 1.5, y + counterH + 0.5, z + 0.5), Color3.fromRGB(150, 150, 150), Enum.Material.Metal, model)
	-- Sticks
	for i = 1, 3 do
		addPart("Stick", Vector3.new(0.1, 0.8, 0.1), Vector3.new(x + 1.2 + (i*0.2), y + counterH + 1.0, z + 0.5), Color3.fromRGB(200, 180, 150), Enum.Material.Wood, model)
	end
	
	return model
end

-- 나무 생성 (3 Random Styles)
function MapGenerator.SpawnTree(x, y, z, parent, style)
	style = style or 1
	
	local model = Instance.new("Model")
	model.Name = "Tree_Type" .. style
	model.Parent = parent
	
	if style == 1 then
		-- Style 1: Round Oak (Existing)
		local trunkHeight = math.random(13, 17)
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		-- [Fixed] Cylinder Size X is Height when rotated 90 Z
		trunk.Size = Vector3.new(trunkHeight, 3, 3)
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Position = Vector3.new(x, y + trunkHeight/2 - 2, z)
		trunk.Orientation = Vector3.new(0, 0, 90)
		trunk.Color = Color3.fromRGB(80, 50, 30)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = model
		
		-- Leaves (Balls with Cylinder Trunk works best turned sideways? Yes Z axis usually)
		-- Re-verify Cylinder orientation. 0,0,90 puts height on X?
		-- Visuals were fine before, keeping logic.
		
		local leafColor = Color3.fromRGB(math.random(60, 100), math.random(150, 200), math.random(60, 100))
		local topY = y + trunkHeight - 2
		
		local function makeLeaf(size, pos)
			local leaf = Instance.new("Part")
			leaf.Size = Vector3.new(size, size, size)
			leaf.Shape = Enum.PartType.Ball
			leaf.Position = pos
			leaf.Color = leafColor
			leaf.Material = Enum.Material.Grass
			leaf.Anchored = true
			leaf.Parent = model
		end
		makeLeaf(14, Vector3.new(x, topY, z))
		for i = 1, 3 do
			makeLeaf(8, Vector3.new(x + math.random(-4,4), topY + math.random(-2,4), z + math.random(-4,4)))
		end
		
	elseif style == 2 then
		print("DEBUG: Executing Style 2 block (Pine)")
		-- Style 2: Simple Pine (2 Blocks + Visible Trunk)
		local trunkHeight = math.random(12, 16)
		local trunk = Instance.new("Part")
		trunk.Size = Vector3.new(2, trunkHeight, 2)
		trunk.Position = Vector3.new(x, y + trunkHeight/2, z) -- Sit on ground
		trunk.Color = Color3.fromRGB(60, 40, 20)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = model
		
		local leafColor = Color3.fromRGB(30, 80, 40)
		local leafMat = Enum.Material.Grass
		
		-- Two distinct blocks for leaves
		-- 1. Bottom Block (Wide) - Starts higher up to show trunk
		local bottomY = y + trunkHeight * 0.4 -- Start 40% up the trunk
		local bottomSize = 10
		local bottomH = 6
		
		local b1 = Instance.new("Part")
		b1.Size = Vector3.new(bottomSize, bottomH, bottomSize)
		b1.Position = Vector3.new(x, bottomY + bottomH/2, z)
		b1.Color = leafColor
		b1.Material = leafMat
		b1.Anchored = true
		b1.Parent = model
		
		-- 2. Top Block (Narrower)
		local topSize = 6
		local topH = 6
		local b2 = Instance.new("Part")
		b2.Size = Vector3.new(topSize, topH, topSize)
		b2.Position = Vector3.new(x, bottomY + bottomH + topH/2, z) -- Stacked on top
		b2.Color = leafColor
		b2.Material = leafMat
		b2.Anchored = true
		b2.Parent = model
		
	elseif style == 3 then
		print("DEBUG: Executing Style 3 block (Birch)")
		-- Style 3: Birch/Poplar (Tall, Thin, White-ish)
		local trunkHeight = math.random(16, 22)
		local trunk = Instance.new("Part")
		-- [Fixed] Cylinder Size X is Height when rotated 90 Z
		trunk.Size = Vector3.new(trunkHeight, 1.5, 1.5)
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Position = Vector3.new(x, y + trunkHeight/2 - 1, z)
		trunk.Orientation = Vector3.new(0, 0, 90)
		trunk.Color = Color3.fromRGB(220, 220, 200) -- Whiteish
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = model
		
		local leafColor = Color3.fromRGB(230, 180, 80) -- Autumn/Yellowish or Light Green? Let's go Bright Green
		leafColor = Color3.fromRGB(100, 200, 100)
		
		local topY = y + trunkHeight - 4
		-- Tall cluster
		local leaf = Instance.new("Part")
		leaf.Size = Vector3.new(6, 12, 6)
		leaf.Position = Vector3.new(x, topY + 4, z)
		leaf.Shape = Enum.PartType.Block -- Boxy tall tree
		leaf.Color = leafColor
		leaf.Material = Enum.Material.Grass
		leaf.Anchored = true
		leaf.Parent = model
	end
end

function MapGenerator.GenerateVillage()
	if not CityMapStore then
		print("⚠️ DataStore invalid. Generating new procedural map (Not Saving)...")
		MapGenerator.GenerateProcedural()
		return
	end

	local success, savedMap = pcall(function()
		return CityMapStore:GetAsync("Map_v1")
	end)
	
	-- if success and savedMap then
	if false then -- [FORCE RESET] Ignore saved data to regenerate terrain correctly
		print("✅ Found saved map data! Loading...")
		MapGenerator.LoadMapFromData(savedMap)
		
		
		-- [Removed] PopulateTreesIfMissing (Obsolete)
	else
		print("❌ No saved map. Generating new procedural map... (Not Saving)")
		local mapData = MapGenerator.GenerateProcedural()
		
		-- [Modified] Do NOT Auto-Save. Wait for Button Click.
		-- Map is generated and cached in MapGenerator.CurrentData automatically by GenerateProcedural
	end
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
	
	-- 잔디밭 (Large Plaza - 100x100)
	local parkSize = 100
	createPart("Grass", Vector3.new(parkSize, 0.5, parkSize), Vector3.new(x, y + 0.25, z), Color3.fromRGB(60, 160, 60), Enum.Material.Grass, model)
	
	-- 분수대 (중앙)
	MapGenerator.CreateFountain(x, y + 0.5, z, model)
	
	-- 길드 게시판 (남쪽 배치)
	MapGenerator.CreateNoticeBoard(x, y + 0.5, z + 35, model)
	
	-- 나무 배치 (4면 가장자리)
	-- 나무 배치 (4면 가장자리)
	-- 나무 배치 (4면 가장자리)
	-- [DISABLED] User Request: No auto-generated trees in park
	-- local treeOffset = 40
	-- MapGenerator.SpawnTree(x - treeOffset, y, z - treeOffset, model, math.random(1, 3))
	-- MapGenerator.SpawnTree(x + treeOffset, y, z - treeOffset, model, math.random(1, 3))
	-- MapGenerator.SpawnTree(x - treeOffset, y, z + treeOffset, model, math.random(1, 3))
	-- MapGenerator.SpawnTree(x + treeOffset, y, z + treeOffset, model, math.random(1, 3))
	
	-- 벤치 (더 많이 배치)
	local benchDist = 20
	createPart("Bench1", Vector3.new(8, 1.5, 2), Vector3.new(x - benchDist, y + 0.75, z), Color3.fromRGB(130, 90, 50), Enum.Material.Wood, model)
	createPart("Bench2", Vector3.new(8, 1.5, 2), Vector3.new(x + benchDist, y + 0.75, z), Color3.fromRGB(130, 90, 50), Enum.Material.Wood, model)
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
	
	-- [Added] Physical Boundary Walls
	local wallHeight = 50
	local wallThickness = 1
	local wallColor = Color3.fromRGB(150, 150, 150)
	local wallTransparency = 0.5
	
	local wallData = {
		-- 북쪽 벽
		{pos = Vector3.new(0, wallHeight/2, -halfSize), size = Vector3.new(mapSize, wallHeight, wallThickness)},
		-- 남쪽 벽
		{pos = Vector3.new(0, wallHeight/2, halfSize), size = Vector3.new(mapSize, wallHeight, wallThickness)},
		-- 서쪽 벽
		{pos = Vector3.new(-halfSize, wallHeight/2, 0), size = Vector3.new(wallThickness, wallHeight, mapSize)},
		-- 동쪽 벽
		{pos = Vector3.new(halfSize, wallHeight/2, 0), size = Vector3.new(wallThickness, wallHeight, mapSize)},
	}
	
	for i, data in ipairs(wallData) do
		local wall = Instance.new("Part")
		wall.Name = "BoundaryWall" .. i
		wall.Size = data.size
		wall.Position = data.pos
		wall.Color = wallColor
		wall.Transparency = wallTransparency
		wall.Material = Enum.Material.SmoothPlastic
		wall.Anchored = true
		wall.CanCollide = true
		wall.Parent = boundaryFolder
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
function MapGenerator.CreateSpawnLocations(parent, mapSize, overridePos, lookAtTarget)
	-- [Modified] Create Single Safe Spawn Point
	-- If overridePos is provided (e.g. for Lobby), use it. Otherwise default to ground center.
	local defaultPos = Vector3.new(0, 8, -30)
	local safePos = overridePos or defaultPos
	
	-- Determine LookAt
	-- If lookAtTarget provided, use it.
	local facePos = lookAtTarget 
	if not facePos then
		-- Default fall back: Look Forward (-Z) relative to spawn
		facePos = safePos + Vector3.new(0, 0, -10)
	end
	
	-- Ensure Y is same to avoid looking up/down
	local lookAtFlat = Vector3.new(facePos.X, safePos.Y, facePos.Z)
	
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.lookAt(safePos, lookAtFlat)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Neutral = true
	spawn.Transparency = 1 
	spawn.Parent = parent
	
	-- [Fix] Remove "Tornado/Star" Decal
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then decal:Destroy() end
	
	-- [Fix] Cleanup Stray SpawnLocations in Workspace
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("SpawnLocation") and child ~= spawn then
			child:Destroy()
		end
	end
end

-- 게시판 생성 (Central 4-Sided Kiosk)
function MapGenerator.CreateNoticeBoard(x, y, z, parent)
	local model = Instance.new("Model")
	model.Name = "GuildBoardModel"
	model.Parent = parent
	
	-- 4면 게시판 (Central Pillar Style)
	local coreSize = 20 -- Width/Depth
	local coreHeight = 20 -- [Modified] Height halved
	local legHeight = 0   -- [Modified] Attached to ground (No legs)
	
	-- 1. 중앙 기둥/코어
	createPart("CoreMain", Vector3.new(coreSize, coreHeight, coreSize), Vector3.new(x, y + legHeight + coreHeight/2, z), Color3.fromRGB(80, 60, 40), Enum.Material.WoodPlanks, model)
	
	-- 2. 지붕 (Pagoda Style / Overhang)
	local roofSize = coreSize + 10
	createPart("Roof", Vector3.new(roofSize, 2, roofSize), Vector3.new(x, y + legHeight + coreHeight + 1, z), Color3.fromRGB(60, 40, 30), Enum.Material.Slate, model)
	
	-- 3. 4면 Canvas & GUI
	-- offsets for 4 faces: Front(Z+), Back(Z-), Right(X+), Left(X-)
	-- Wait, Front in Roblox is usually -Z. Let's align logically.
	
	local faces = {
		{id="Front", pos=Vector3.new(0, 0, -coreSize/2 - 0.2), rot=Vector3.new(0, 0, 0)},     -- Looking at -Z face
		{id="Back",  pos=Vector3.new(0, 0, coreSize/2 + 0.2),  rot=Vector3.new(0, 180, 0)},   -- Looking at +Z face
		{id="Right", pos=Vector3.new(coreSize/2 + 0.2, 0, 0),  rot=Vector3.new(0, -90, 0)},   -- Looking at +X face
		{id="Left",  pos=Vector3.new(-coreSize/2 - 0.2, 0, 0), rot=Vector3.new(0, 90, 0)},  -- Looking at -X face
	}
	
	for _, face in ipairs(faces) do
	local canvas = createPart("Canvas_"..face.id, Vector3.new(coreSize - 2, coreHeight - 4, 0.4), 
			Vector3.new(x + face.pos.X, y + legHeight + coreHeight/2, z + face.pos.Z), 
			Color3.fromRGB(230, 220, 210), Enum.Material.SmoothPlastic, model) -- Softer color
		
		canvas.Orientation = face.rot
		canvas.Name = "GuildBoardPart" -- Shared Name for Script interaction
		
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 80
		detector.Parent = canvas
		
		-- SurfaceGui
		local gui = Instance.new("SurfaceGui")
		gui.Name = "BoardGui"
		gui.Face = Enum.NormalId.Front -- Oriented with Part
		gui.CanvasSize = Vector2.new(1000, 2000) -- Portrait mode
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.LightInfluence = 1.0 -- 조명 영향 100% (눈부심 제거, 종이 질감)
		gui.Parent = canvas
		
		-- Content (Simplified for 4 sides)
		-- Content (Simplified for 4 sides)
		local title = Instance.new("TextLabel")
		title.Text = "NOTICE\n(" .. face.id .. ")"
		title.Size = UDim2.new(1, 0, 0.15, 0) -- Slightly taller area
		title.Position = UDim2.new(0, 0, 0.05, 0) -- [Modified] Top Padding
		title.BackgroundTransparency = 1
		title.TextColor3 = Color3.fromRGB(200, 50, 50)
		title.TextSize = 90 -- Slightly smaller to fit padding
		title.Font = Enum.Font.LuckiestGuy
		title.Parent = gui
		
		local img = Instance.new("ImageLabel")
		img.Image = "rbxassetid://9024035651"
		img.Size = UDim2.new(0.9, 0, 0.6, 0) -- Larger Image
		img.Position = UDim2.new(0.05, 0, 0.25, 0) -- Moved down
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = gui
		
		-- [Modified] Removed Bottom Text ("Find the Hidden Cats!") as requested
	end
end

function MapGenerator.CreateBuilding(x, y, z, parent, roofColorOverride)
	-- 레고 스타일 집 (다양성 추가)
	local houseWidth = math.random(18, 24)
	local houseDepth = math.random(16, 22)
	local floorHeight = 8 -- 각 층 높이
	local roofHeight = 6 -- 지붕 높이
	
	-- 층수 결정 (1층 고정)
	local floors = 1 -- math.random(1, 2)
	
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
	
	local wallColor = wallColors[math.random(1, #wallColors)]
	local roofColor = roofColorOverride or roofColors[math.random(1, #roofColors)]
	
	-- [Adjustment] If specific roof color is requested, make walls white to highlight it
	if roofColorOverride then
		wallColor = Color3.fromRGB(255, 255, 255)
	end
	
	local windowColor = Color3.fromRGB(100, 150, 200) -- 파란 창문
	local doorColor = Color3.fromRGB(80, 50, 30) -- 갈색 문
	
	local model = Instance.new("Model")
	model.Name = "House"
	model.Parent = parent
	
	-- 1층 벽 (SmoothPlastic -> Plastic)
	local floor1 = createPart("Floor1", Vector3.new(houseWidth, floorHeight, houseDepth), 
		Vector3.new(x, y + floorHeight/2, z), wallColor, Enum.Material.Plastic, model)
	model.PrimaryPart = floor1
	
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
	local roofMat = Enum.Material.Plastic -- [Modified] Less vivid than SmoothPlastic
	
	-- 지붕 왼쪽 면
	local roofLeft = createPart("RoofLeft", Vector3.new(houseWidth + roofOverhang*2, roofThick, houseDepth/2 + roofOverhang), 
		Vector3.new(x, y + totalWallHeight + roofHeight/2, z - houseDepth/4), roofColor, roofMat, model)
	roofLeft.Orientation = Vector3.new(-30, 0, 0) -- 기울기
	
	-- 지붕 오른쪽 면
	local roofRight = createPart("RoofRight", Vector3.new(houseWidth + roofOverhang*2, roofThick, houseDepth/2 + roofOverhang), 
		Vector3.new(x, y + totalWallHeight + roofHeight/2, z + houseDepth/4), roofColor, roofMat, model)
	roofRight.Orientation = Vector3.new(30, 0, 0) -- 반대쪽 기울기
	
	-- 지붕 꼭대기 (마감 - 작은 틈 메우기)
	createPart("RoofTop", Vector3.new(houseWidth + roofOverhang*2, roofThick, roofThick), 
		Vector3.new(x, y + totalWallHeight + roofHeight, z), roofColor, roofMat, model)
	
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
	
	return model
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

-- 요리사 NPC 생성 (Busy Animation)
function MapGenerator.SpawnChef(locationCF, parent)
	local model = Instance.new("Model")
	model.Name = "Chef"
	model.Parent = parent
	
	-- Humanoid
	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model
	
	-- Colors
	local skinColor = Color3.fromRGB(240, 200, 180)
	local shirtColor = Color3.fromRGB(255, 255, 255) -- White
	local apronColor = Color3.fromRGB(200, 50, 50) -- Red Apron
	local pantsColor = Color3.fromRGB(50, 50, 50) -- Black Pants
	
	-- Helper
	local function makePart(name, size, color, cf)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = locationCF * cf
		p.Parent = model
		return p
	end
	
	-- Body Parts (R6)
	-- Pivot is Ground Level.
	local torso = makePart("Torso", Vector3.new(2, 2, 1), shirtColor, CFrame.new(0, 3, 0))
	local head = makePart("Head", Vector3.new(1, 1, 1), skinColor, CFrame.new(0, 4.5, 0))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	
	-- Chef Hat (Tall Cylinder)
	local hat = makePart("ChefHat", Vector3.new(1, 1.2, 1), Color3.new(1,1,1), CFrame.new(0, 5.2, 0))
	-- Using Special Mesh for clean look
	local hatMesh = Instance.new("SpecialMesh")
	hatMesh.MeshType = Enum.MeshType.Head -- Use Head shape stretched for puffy look
	hatMesh.Scale = Vector3.new(1.2, 2, 1.2)
	hatMesh.Parent = hat
	
	-- Arms
	local lArm = makePart("Left Arm", Vector3.new(1, 2, 1), shirtColor, CFrame.new(-1.5, 3, 0))
	local rArm = makePart("Right Arm", Vector3.new(1, 2, 1), shirtColor, CFrame.new(1.5, 3, 0))
	
	-- Legs
	makePart("Left Leg", Vector3.new(1, 2, 1), pantsColor, CFrame.new(-0.5, 1, 0))
	makePart("Right Leg", Vector3.new(1, 2, 1), pantsColor, CFrame.new(0.5, 1, 0))
	
	-- Apron (Visual Part) (Attached to Torso logic)
	makePart("Apron", Vector3.new(2.1, 2.5, 0.2), apronColor, CFrame.new(0, 2.5, -0.6))
	
	-- Tool (Spatula)
	local spatula = makePart("Spatula", Vector3.new(0.2, 1.5, 0.4), Color3.new(0.5,0.5,0.5), CFrame.new(1.5, 2, -1.5) * CFrame.Angles(math.rad(45), 0, 0))
	spatula.Parent = rArm -- Attach to arm conceptually

	-- Animation Loop (Task)
	task.spawn(function()
		local t = 0
		while model and model.Parent do
			t = t + 0.1
			task.wait(0.05)
			
			-- Animate Arms (Chopping / Stirring)
			-- Right Arm (Stirring): Higher Y (3.8) to clear counter
			local stirY = math.sin(t * 10) * 0.3
			local stirZ = math.cos(t * 10) * 0.3
			rArm.CFrame = locationCF * CFrame.new(1.5, 3.8 + stirY, -0.5 + stirZ) * CFrame.Angles(math.rad(80 + stirY*20), 0, 0)
			
			-- Spatula follows arm (Simple offset)
			spatula.CFrame = rArm.CFrame * CFrame.new(0, -1, -0.5) * CFrame.Angles(math.rad(90), 0, 0)
			
			-- Left Arm (Holding Pot/Pan High)
			lArm.CFrame = locationCF * CFrame.new(-1.5, 3.8, -0.5) * CFrame.Angles(math.rad(80), 0, math.rad(10))
			
			-- Head Bob
			head.CFrame = locationCF * CFrame.new(0, 4.5 + math.abs(math.sin(t*5)*0.05), 0)
			hat.CFrame = head.CFrame * CFrame.new(0, 1.2, 0) -- Update Hat relative to head? No, relative to world + offset
			-- Wait, head moves. Hat should follow.
			hat.CFrame = head.CFrame * CFrame.new(0, 0.7, 0)
			
			-- Torso Twist (Busy look)
			local twist = math.sin(t * 2) * 0.1
			torso.CFrame = locationCF * CFrame.new(0, 3, 0) * CFrame.Angles(0, twist, 0)
			
			-- Apron Follows Torso roughly
			local apron = model:FindFirstChild("Apron")
			if apron then
				apron.CFrame = torso.CFrame * CFrame.new(0, -0.5, -0.6)
			end
		end
	end)
end

-- 월드 아이템 생성 (픽업 가능)
function MapGenerator.SpawnWorldItem(itemId, position, parent)
	local ItemData = require(game.ReplicatedStorage:WaitForChild("ItemData"))
	local itemDef = ItemData.GetItem(itemId)
	if not itemDef then return end
	
	-- 지면 높이 찾기 (레이캐스트)
	-- [DEBUG] Road Check (Optional check removed for cleanliness)

	local rayResult = workspace:Raycast(position + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0))
	local groundY = position.Y
	if rayResult then
		groundY = rayResult.Position.Y + 0.5 -- 적당히 띄움 (테이블 위에 놓을 수 있게 충돌체 고려)
		-- print("Spawned Item " .. itemId .. " at Ground Y: " .. groundY)
	else
		-- print("Failed raycast for " .. itemId .. ", using default Y: " .. groundY)
	end
	
	local part -- Declare part here, will be assigned in conditionals
	-- 아이템별 외형 설정
	if itemId == "Stick" then
		part = Instance.new("Part")
		part.Name = "WorldItem_" .. itemId
		part.Size = Vector3.new(0.2, 0.2, 1.5)
		part.Color = Color3.fromRGB(90, 60, 30)
		part.Material = Enum.Material.Wood
		part.CFrame = CFrame.new(position.X, groundY + 0.1, position.Z) * CFrame.Angles(0, math.random() * math.pi, math.rad(10))
		part.Anchored = true
		part.CanCollide = false
		part.Parent = parent
		
		-- [Added] Food Tag for AI
		if itemId == "Bungeoppang" or itemId == "Stick" then -- Stick isn't food but tagging for consistency
			part:SetAttribute("IsFood", true)
		end
	elseif itemId == "Bungeoppang" then
		-- 붕어빵 (From Assets)
		local assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets", 5)
		local sourceItem = assets and assets:FindFirstChild("Bungeoppang")
		
		if sourceItem then
			print("[MapGenerator] SpawnWorldItem Called. UUID: " .. HttpService:GenerateGUID(false))
			local model = sourceItem:Clone()
			
			-- [v4.25b] Support both Part and Accessory/Model
			local targetHandle = nil
			if model:IsA("BasePart") then
				targetHandle = model
			elseif model:IsA("Accessory") then
				targetHandle = model:FindFirstChild("Handle")
			elseif model:IsA("Model") then
				targetHandle = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
			end

			if targetHandle then
				-- [v4.25a] Restore 2.5x Scaling
				local scaleCount = 2.5
				if targetHandle:IsA("BasePart") then
					targetHandle.Size = targetHandle.Size * scaleCount
				end
				local mesh = targetHandle:FindFirstChildOfClass("SpecialMesh")
				if mesh then
					mesh.Scale = mesh.Scale * scaleCount
				end

				targetHandle.CFrame = CFrame.new(position.X, groundY - 0.4, position.Z) * CFrame.fromOrientation(math.rad(-40.997), math.rad(175.114), math.rad(-10.472))
				targetHandle.Anchored = true
				targetHandle.CanCollide = false
			end
			
			-- Model Wrapper (for Highlight and consistency)
			local wrapperModel = Instance.new("Model")
			wrapperModel.Name = "WorldItem_" .. itemId
			wrapperModel.Parent = parent
			model.Parent = wrapperModel
			if targetHandle then wrapperModel.PrimaryPart = targetHandle end
			wrapperModel:SetAttribute("IsFood", true)
			
			part = targetHandle or (model:IsA("BasePart") and model) -- ClickDetector 부착 대상
			print(string.format("[MapGenerator] Spawned Item. Sibling Count in WorldItems: %d", #parent:GetChildren()))
		else
			-- Fallback (Simple Part) if Asset not ready
			part = Instance.new("Part")
			part.Name = "WorldItem_" .. itemId
			part.Size = Vector3.new(1.5, 1.5, 1.5)
			part.Color = Color3.fromRGB(255, 170, 80)
			part.Position = Vector3.new(position.X, groundY + 0.5, position.Z)
			part.Anchored = true
			part.Parent = parent
		end
	else

		part = Instance.new("Part")
		part.Name = "WorldItem_" .. itemId
		part.Size = Vector3.new(1, 1, 1)
		part.Color = Color3.fromRGB(200, 200, 200)
		part.Position = Vector3.new(position.X, groundY + 0.5, position.Z)
		part.Anchored = true
		part.Parent = parent
	end
	
	-- 아이템 ID 저장
	if part then
		part:SetAttribute("ItemId", itemId)
	else
		warn("[MapGenerator] Failed to assign 'part' for itemId: " .. tostring(itemId))
		return
	end
	
	-- ClickDetector 추가 (마우스 호버 + 클릭으로 획득)
	-- ClickDetector는 기본적으로 손 모양 커서를 표시함
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 10 -- 10 stud 이내에서만 클릭 가능
	clickDetector.Parent = part
	
	-- 외곽선 글로우 효과 (Highlight 사용)
	local highlight = Instance.new("Highlight")
	highlight.Name = "ItemHighlight"
	highlight.FillTransparency = 1 -- 내부 채우기 없음
	highlight.OutlineTransparency = 0 -- 외곽선 완전 표시
	highlight.OutlineColor = Color3.fromRGB(255, 255, 100) -- 밝은 노란색
	highlight.Adornee = part
	highlight.Enabled = false
	highlight.Parent = part
	
	-- 호버 이벤트 (외곽선 활성화)
	clickDetector.MouseHoverEnter:Connect(function()
		highlight.Enabled = true
	end)
	clickDetector.MouseHoverLeave:Connect(function()
		highlight.Enabled = false
	end)
	
	-- 클릭 이벤트 (InventoryManager에서 처리)
	task.defer(function()
		if _G.InventoryManager then
			_G.InventoryManager.SetupWorldItem(part, itemId, clickDetector)
		end
	end)
	
	return part
end


-- 고양이 NPC 생성 (Wandering AI)
function MapGenerator.SpawnCat(locationCF, parent)
	local catId = HttpService:GenerateGUID(false)
	local shortId = string.sub(catId, 1, 4)
	-- [DEBUG] Verify Memory Table Sharing
	-- print(string.format("[AI] %s Spawned. FoodClaims Table: %s", shortId, tostring(FoodClaims)))
	
	local model = Instance.new("Model")
	model.Name = "Cat_" .. shortId
	model.Parent = parent
	
	-- Humanoid
	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model
	
	-- [Variety Logic] - Colors & Patterns
	local selectedPattern = CAT_PATTERN_TYPES[math.random(1, #CAT_PATTERN_TYPES)]
	
	-- Base Setup
	local baseColor = CAT_COLORS.White
	local accentColor = CAT_COLORS.White
	local eyeColor = CAT_EYE_COLORS[math.random(1, #CAT_EYE_COLORS)]
	
	if selectedPattern == "Solid" then
		local keys = {"White", "Black", "Orange", "Grey", "Cream", "Brown"}
		baseColor = CAT_COLORS[keys[math.random(1, #keys)]]
		accentColor = baseColor
	elseif selectedPattern == "Tuxedo" then
		baseColor = (math.random() > 0.5) and CAT_COLORS.Black or CAT_COLORS.Grey
		accentColor = CAT_COLORS.White
	elseif selectedPattern == "Spotted" then
		baseColor = CAT_COLORS.White
		local keys = {"Black", "Orange", "Grey", "Brown"}
		accentColor = CAT_COLORS[keys[math.random(1, #keys)]]
	elseif selectedPattern == "Calico" then
		baseColor = CAT_COLORS.White
	elseif selectedPattern == "Pointed" then
		baseColor = CAT_COLORS.Cream
		accentColor = CAT_COLORS.Brown
	elseif selectedPattern == "Tabby" then
		baseColor = (math.random() > 0.5) and CAT_COLORS.Orange or CAT_COLORS.Grey
		accentColor = (baseColor == CAT_COLORS.Orange) and CAT_COLORS.Brown or CAT_COLORS.DarkGrey
	end
	
	-- Set Attribute for Mission
	model:SetAttribute("Pattern", selectedPattern)
	
	-- Helper
	local function makePart(name, size, color, cf, parentPart)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.CanCollide = (name == "Torso")
		p.CFrame = locationCF * cf
		p.Parent = model
		
		if parentPart then
			p.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = parentPart
			weld.Part1 = p
			weld.Parent = p
		else
			p.Anchored = true
		end
		
		return p
	end
	
	-- Model Creation
	local torso = makePart("Torso", Vector3.new(1, 1, 2), baseColor, CFrame.new(0, 1.5, 0))
	model.PrimaryPart = torso

	-- Spots for Spotted/Calico
	if selectedPattern == "Spotted" or selectedPattern == "Calico" then
		for i = 1, math.random(2, 4) do
			local spotColor = accentColor
			if selectedPattern == "Calico" then
				spotColor = (math.random() > 0.5) and CAT_COLORS.Orange or CAT_COLORS.Black
			end
			local spotSize = Vector3.new(math.random(4, 7)/10, 0.05, math.random(5, 8)/10)
			-- Z-fighting 방지를 위해 몸통 표면에서 0.02 stud 띄우고, 각 얼룩마다 미세하게 높이를 다르게 설정 (i * 0.001)
			local surfaceOffset = 0.52 + (i * 0.001)
			local spotOffsetRel = CFrame.new((math.random()>0.5 and surfaceOffset or -surfaceOffset), math.random(-4, 4)/10, math.random(-8, 8)/10) * CFrame.Angles(0, 0, math.rad(90))
			makePart("Spot"..i, spotSize, spotColor, CFrame.new(0, 1.5, 0) * spotOffsetRel, torso)
		end
	elseif selectedPattern == "Tuxedo" then
		-- 가슴 패치도 Z-fighting 방지를 위해 조금 더 띄움 (-1.01 -> -1.02)
		makePart("ChestPatch", Vector3.new(0.6, 0.8, 0.05), CAT_COLORS.White, CFrame.new(0, 1.5, -1.02), torso)
	end
	
	-- Head
	local headColor = (selectedPattern == "Pointed") and accentColor or baseColor
	-- [v4.23e] Fix: Pass 'torso' to weld Head to Body
	-- [v4.23l] Revert: Head is Anchored again for manual animation
	local head = makePart("Head", Vector3.new(0.8, 0.8, 0.8), headColor, CFrame.new(0, 2.2, -0.8))
	-- Move eyes and ears relative to head initial CFrame for the helper
	makePart("EyeL", Vector3.new(0.15, 0.15, 0.05), eyeColor, CFrame.new(-0.2, 2.3, -1.21), head)
	makePart("EyeR", Vector3.new(0.15, 0.15, 0.05), eyeColor, CFrame.new(0.2, 2.3, -1.21), head)
	
	-- Ears
	makePart("EarL", Vector3.new(0.2, 0.4, 0.2), headColor, CFrame.new(-0.25, 2.7, -0.8), head)
	makePart("EarR", Vector3.new(0.2, 0.4, 0.2), headColor, CFrame.new(0.25, 2.7, -0.8), head)
	
	-- Tail
	local tailLength = 1.2
	local tailColor = (selectedPattern == "Pointed") and accentColor or baseColor
	-- [v4.23e] Fix: Pass 'torso' to weld Tail to Body
	-- [v4.23l] Revert: Tail is Anchored again for manual animation
	local tail = makePart("Tail", Vector3.new(0.2, 0.2, tailLength), tailColor, CFrame.new(0, 2.0, 1.0) * CFrame.Angles(math.rad(45), 0, 0))
	
	-- Legs
	local legSize = Vector3.new(0.3, 1, 0.3)
	local useSocks = (selectedPattern == "Tuxedo") or (math.random() > 0.7)
	
	local function makeLeg(name, cf)
		local legColor = (selectedPattern == "Pointed") and accentColor or baseColor
		local l = makePart(name, legSize, legColor, cf)
		if useSocks then
			makePart(name.."Sock", Vector3.new(0.32, 0.2, 0.32), CAT_COLORS.White, cf * CFrame.new(0, -0.4, 0), l)
		end
		return l
	end
	
	local legFL = makeLeg("FL", CFrame.new(-0.35, 0.5, -0.8))
	local legFR = makeLeg("FR", CFrame.new(0.35, 0.5, -0.8))
	local legBL = makeLeg("BL", CFrame.new(-0.35, 0.5, 0.8))
	local legBR = makeLeg("BR", CFrame.new(0.35, 0.5, 0.8))

	-- AI Loop (Non-blocking Physics + State Machine)
	task.spawn(function()
		-- print(string.format("[AI] %s THREAD START", shortId))
		local speed = 8 -- studs/sec
		local state = "Idle" -- Idle, Moving, MovingToFood, Eating
		local targetPos = nil
		local targetFood = nil
		
		-- Idle Timer
		local idleTimer = 0
		local idleDuration = math.random(2, 5)
		local searchCooldown = 0 -- [v4.4] Prevent rapid re-search
		
		-- [v3.9/v4.0/v4.2/v4.3] Centralized State Reset & Visual Cleanupck physics position independently of visual animation
		local cleanPos = torso.Position
		
		local attCat = Instance.new("Attachment")
		attCat.Name = "AttCat"
		attCat.Parent = head
		
		local targetAtt = Instance.new("Attachment")
		targetAtt.Name = "AttTarget"
		targetAtt.Parent = workspace.Terrain
		
		local targetBeam = Instance.new("Beam")
		targetBeam.Name = "LockOnBeam"
		targetBeam.Attachment0 = attCat
		targetBeam.Attachment1 = targetAtt
		targetBeam.Width0 = 0.2
		targetBeam.Width1 = 0.2
		targetBeam.FaceCamera = true
		targetBeam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0)) -- Yellow
		targetBeam.LightEmission = 1
		targetBeam.Enabled = false
		targetBeam.Parent = head

		-- [v4.26f] FOV Visualization - Stable Source on Torso
		local attFOVSource = Instance.new("Attachment")
		attFOVSource.Name = "AttFOVSource"
		attFOVSource.Position = Vector3.new(0, 0.7, -0.8) -- Eye level
		attFOVSource.Parent = torso

		-- [v4.26l] Create Smooth Sector FOV Surface (8 segments for smooth arc)
		local fovSurfaces = {}
		for i = 1, 8 do
			local b = Instance.new("Beam")
			b.Name = "FOVSector_" .. i
			b.Attachment0 = attFOVSource
			local att = Instance.new("Attachment")
			att.Name = "AttSectorTarget_" .. i
			att.Parent = workspace.Terrain
			b.Attachment1 = att
			b.Width0 = 0
			b.Width1 = 4.0 -- Recalculated for 11.25deg slices at 20 studs
			b.Transparency = NumberSequence.new(0.8)
			b.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
			b.FaceCamera = false
			b.Enabled = false -- [v4.27a] Disabled by default
			b.Parent = torso
			table.insert(fovSurfaces, {att = att, beam = b})
		end
		
		-- [v3.9/v4.0/v4.2/v4.3] Centralized State Reset & Visual Cleanup
		local function transitionToIdle(reason)
			state = "Idle"
			idleTimer = 0
			if targetBeam then targetBeam.Enabled = false end
			if targetFood and targetFood.Parent then
				-- [v4.3] Restore pickup if we were eating it
				local cd = targetFood:FindFirstChildOfClass("ClickDetector")
				if cd then cd.MaxActivationDistance = 32 end -- Default range
				
				-- [v4.8] Release Memory Lock
				if FoodClaims[targetFood] == catId then
					FoodClaims[targetFood] = nil
					targetFood:SetAttribute("ClaimedBy", nil)
					print(string.format("[AI] %s RELEASED Memory Lock on %s", shortId, targetFood.Name))
				elseif FoodClaims[targetFood] then
					print(string.format("[AI] %s WANTED release %s but Lock held by %s. (My Claim? %s)", shortId, targetFood.Name, tostring(FoodClaims[targetFood]), tostring(targetFood:GetAttribute("ClaimedBy"))))
				end
				
				-- Clear attributes for visual sync
				if targetFood:GetAttribute("ClaimRequest") == catId then
					targetFood:SetAttribute("ClaimRequest", nil)
				end
				if targetFood:GetAttribute("EatingBy") == catId then
					targetFood:SetAttribute("EatingBy", nil)
				end
			end
			targetFood = nil
			-- searchCooldown = 1.0 -- [v4.8] Removed cooldown as memory lock is instant
		end
		
		-- Food Search Timer
		local searchTimer = math.random() * 0.5 
		
		-- [v4.27b] FOV Pulse Timer
		local fovPulseTimer = 0
		
		-- Raycast Params
		local rayParams = RaycastParams.new()
		-- [v4.25o] 덫이나 다른 고양이 등을 제외하여 오동작(천익 점프 등) 방지
		local function updateRayParams()
			local excludeList = {parent} -- 기본적으로 Cats 폴더 제외
			-- [Fix] CatTrap을 제외 목록에서 제거하여 AI가 덫을 장애물/지형으로 인식하게 함
			-- local CollectionService = game:GetService("CollectionService")
			-- local traps = CollectionService:GetTagged("CatTrap")
			-- for _, trap in ipairs(traps) do table.insert(excludeList, trap) end
			rayParams.FilterDescendantsInstances = excludeList
		end
		updateRayParams()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		
		-- [v4.25s] 벽/장애물 감지용 (덫 포함)
		local obstacleRayParams = RaycastParams.new()
		obstacleRayParams.FilterDescendantsInstances = {model} -- 자기 자신만 제외
		obstacleRayParams.FilterType = Enum.RaycastFilterType.Exclude
		
		-- [v4.25s] Safety Cleanup: 강제로 물리 상태 초기화 (찌거기 버그 방지)
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = true end
		end
		hum.PlatformStand = false
		
		-- [v4.25o] 덫 진입 상태 관리용
		local enteredEntrance = false
		local targetDebugPart = nil
		local isGhostMode = false -- [Optimization] 불필요한 GetDescendants 호출 방지
		
		local TICK_RATE = 0.05
		
		local nextXZ = cleanPos -- [v4.23e] Initialize nextXZ outside loop for persistence
		-- [v4.25b] Logic Rotation: Store heading separately to prevent animation accumulation
		local logicRotation = torso.CFrame.Rotation
		
		while model and model.Parent do
			task.wait(TICK_RATE)
			local currentPos = cleanPos -- [v2.4] Use clean physics position as base
			
			-- [v4.23e] PHYSICS MOVED TO TOP (To avoid skipping)
			-- Prepare Physics Vars
			if not model:GetAttribute("VerticalVelocity") then
				model:SetAttribute("VerticalVelocity", 0)
				model:SetAttribute("IsJumping", false)
			end
			
			local vVel = model:GetAttribute("VerticalVelocity") or 0
			local isJumping = model:GetAttribute("IsJumping") == true
			local gravity = 80
			local jumpPower = 35
			local groundThreshold = 2.5
			local maxJumpHeight = 3 
			
			-- Check Ground at Next XZ
			local rayOrigin = Vector3.new(nextXZ.X, currentPos.Y + 5, nextXZ.Z)
			local rayDir = Vector3.new(0, -20, 0)
			local rayRes = workspace:Raycast(rayOrigin, rayDir, rayParams)
			
			local groundHeight = 0
			if rayRes then
				groundHeight = rayRes.Position.Y + 1.5
			else
				groundHeight = currentPos.Y - 1 
			end
			
			local finalY = currentPos.Y
			
			if not isJumping then
				-- JUMP START CHECK
				local heightDiff = groundHeight - currentPos.Y
				
				if heightDiff > maxJumpHeight then
					-- Unreachable
					-- [v4.27f] Don't abandon CatTrap target when near entrance
					-- 덫 근처에서 바닥 높이 차이로 인해 잘못된 "도달 불가" 판정 방지
					local nearTrap = false
					if targetFood and targetFood.Name == "CatTrap" then
						local distToTrap = (currentPos - targetFood:GetPivot().Position).Magnitude
						if distToTrap < 10 then
							nearTrap = true
						end
					end
					
					if state ~= "Eating" and not nearTrap then
						transitionToIdle("Unreachable")
						nextXZ = currentPos 
						finalY = currentPos.Y
						idleDuration = 0.5 
					end
					-- nearTrap인 경우 멈추지 않고 계속 이동 허용 
				elseif heightDiff > groundThreshold and heightDiff <= maxJumpHeight then
					isJumping = true
					vVel = jumpPower
				else
					-- GROUND STICK
					local diff = groundHeight - currentPos.Y
					
					if diff < -2 then
						isJumping = true
					else
						if diff > 0 and diff > maxJumpHeight then
							nextXZ = currentPos
							finalY = currentPos.Y
						else
							finalY = currentPos.Y + (diff * 0.3)
							if math.abs(finalY - groundHeight) < 0.2 then
								finalY = groundHeight
							end
						end
					end
				end
			end
			
			if isJumping then
				vVel = vVel - (gravity * TICK_RATE)
				finalY = currentPos.Y + (vVel * TICK_RATE)
				
				if finalY <= groundHeight then
					finalY = groundHeight
					vVel = 0
					isJumping = false
				end
				
				model:SetAttribute("VerticalVelocity", vVel)
				model:SetAttribute("IsJumping", isJumping)
			end
			
			-- Update Transform
			cleanPos = Vector3.new(nextXZ.X, finalY, nextXZ.Z)
			
			-- [v4.25q] 가둬진 상태에서는 물리 엔진(Weld)이 위치를 제어하도록 함
			if state == "Trapped" then
				cleanPos = torso.Position
				logicRotation = torso.CFrame.Rotation
			else
				-- [v4.25b] Reset orientation from logicRotation BEFORE applying animations
				torso.CFrame = CFrame.new(cleanPos) * logicRotation
			end
			
			-- [v4.23h] Sync Logic Base
			currentPos = cleanPos
			nextXZ = currentPos
			
			-- Timers
			idleTimer += TICK_RATE
			searchTimer += TICK_RATE
			
			-- 1. State Logic
			local isTrapped = model:GetAttribute("IsTrapped")
			if isTrapped then
				state = "Trapped"
			end

			if state == "Trapped" then
				-- [v4.25q] 가둬진 상태: 움직이지 않고 제자리에서 애니메이션만
				nextXZ = currentPos
				transitionToIdle = function() end -- 상태 전이 금지
				if targetDebugPart then targetDebugPart:Destroy(); targetDebugPart = nil end
			elseif state == "Idle" then
				-- Search for food every 0.25 seconds
				if searchTimer >= 0.25 and searchCooldown <= 0 then
					searchTimer = 0
					
					-- [v4.25l] 통합 검색 리스트 (WorldItems + 덫)
					local searchList = {}
					local worldItems = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WorldItems")
					if worldItems then
						for _, item in ipairs(worldItems:GetChildren()) do table.insert(searchList, item) end
					end
					
					-- [New] 미끼가 있는 덫 추가
					for _, obj in ipairs(workspace:GetChildren()) do
						if obj.Name == "CatTrap" and obj:GetAttribute("BaitItem") then
							table.insert(searchList, obj)
						end
					end
					
					if #searchList > 0 then
						local closestFood = nil
						local minDist = 40 -- [v4.25l] 덫 유인을 위해 범위를 다시 40으로 증가 (기존 20)
						
						for _, item in ipairs(searchList) do
							-- [v4.23o] Assign Unique ID for Debugging
							if not item:GetAttribute("RefID") then
								item:SetAttribute("RefID", HttpService:GenerateGUID(false):sub(1, 8))
							end
							
							-- [v4.8] Check Centralized Memory Lock
							local isLocked = (FoodClaims[item] ~= nil)
							local eatingBy = item:GetAttribute("EatingBy")
							
							if item:GetAttribute("IsFood") and not isLocked and not eatingBy then
								local pos = getItemPos(item)
								if pos then
									local dirToFood = (pos - torso.Position).Unit
									local dot = torso.CFrame.LookVector:Dot(dirToFood)
									
									-- [v4.26d] Use 90-degree cone (Dot product > 0.707)
									if dot > 0.707 then
										local dist = (torso.Position - pos).Magnitude
										if dist < minDist then
											minDist = dist
											closestFood = item
										end
									end
								end
							end
						end
						
						if closestFood then
							local foodPos = getItemPos(closestFood) -- [v4.10] Restored definition
							if foodPos then
								-- [v4.8] ATOMIC MEMORY LOCK
								if FoodClaims[closestFood] == nil then
									-- INSTANT LOCK
									FoodClaims[closestFood] = catId
									closestFood:SetAttribute("ClaimedBy", catId) -- Visual Sync
									
									print(string.format("[AI] %s LOCKED %s (%s) in Memory [Table: %s]", shortId, closestFood.Name, tostring(closestFood:GetAttribute("RefID")), tostring(FoodClaims)))
									targetFood = closestFood
									state = "MovingToFood"
									
									-- [v3.8] Visuals
									targetAtt.WorldPosition = foodPos
									targetBeam.Enabled = true -- [v4.25c] Restored targeting beam
								else
									-- Already Locked
									-- print(string.format("[AI] %s IGNORED %s (Locked by %s)", shortId, closestFood.Name, tostring(FoodClaims[closestFood])))
								end
							end
						end
					end
				end -- [v4.18] Close searchTimer

				
				if state == "Idle" and idleTimer >= idleDuration then
					-- Switch to Moving (Normal Wander)
					local range = 30
					local rx = math.random(-range, range)
					local rz = math.random(-range, range)
					
					-- Find Target
					local searchOrigin = currentPos + Vector3.new(rx, 50, rz)
					local rayRes = workspace:Raycast(searchOrigin, Vector3.new(0, -100, 0), rayParams)
					
					if rayRes then
						targetPos = rayRes.Position + Vector3.new(0, 1.5, 0)
						state = "Moving"
					else
						-- Retry Idle
						idleTimer = 0
						idleDuration = 1
					end
				end
			elseif state == "Moving" and targetPos then
				local dirVector = (targetPos - currentPos)
				local flatDir = Vector3.new(dirVector.X, 0, dirVector.Z)
				
				if flatDir.Magnitude < 0.5 then
					-- Reached Goal
					state = "Idle"
					idleTimer = 0
					idleDuration = math.random(3, 8)
				else
					-- [v4.25s] 장애물 회피 (Wander State)
					local dir = flatDir.Unit
					local step = speed * TICK_RATE
					
					-- 단일 레이캐스트 (머리 높이에서 발사)
					local checkDist = math.min(flatDir.Magnitude, 3.0)
					local rayOrigin = currentPos + Vector3.new(0, 1.0, 0) -- 머리 높이
					local hitResult = workspace:Raycast(rayOrigin, dir * checkDist, obstacleRayParams)
					
					if hitResult then
						local isTrapPart = hitResult.Instance:FindFirstAncestor("CatTrap") ~= nil
						if isTrapPart then
							-- 덫 감지: 뒤로 물러남
							state = "Idle"
							idleTimer = 0
							idleDuration = 1
							nextXZ = currentPos - dir * 1.5
						else
							-- 일반 장애물: 멈춤
							state = "Idle"
							idleTimer = 0
							idleDuration = 1
							nextXZ = currentPos
						end
					else
						nextXZ = currentPos + dir * step
					end
					
					-- Rotation (Only when moving)
					-- [v4.22] Safety check for degenerate lookAt
					if (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(currentPos.X, 0, currentPos.Z)).Magnitude > 0.1 then
						local lookCF = CFrame.lookAt(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))
						logicRotation = lookCF.Rotation -- [v4.25b] Save only to logicRotation
					end
				end
				
			elseif state == "MovingToFood" then
				-- [v4.23n] Ghost Eating Fix: Check if food still exists properly
				if not targetFood or not targetFood.Parent then
					print(string.format("[AI] %s ABORT: %s is gone (Despawned/Destroyed)", shortId, targetFood and targetFood.Name or "nil"))
					transitionToIdle("FoodDespawned")
				
				-- [v4.8] Verify Memory Lock
				elseif FoodClaims[targetFood] ~= catId then
					print(string.format("[AI] %s ALERT: Lost Memory Lock on %s! Held by: %s", shortId, targetFood and targetFood.Name or "nil", tostring(FoodClaims[targetFood])))
					transitionToIdle("LockLost")
				else
					-- [v4.2] Give up if SOMEONE ELSE starts eating our target
					local eater = targetFood:GetAttribute("EatingBy")
					if eater and eater ~= catId then
						print(string.format("[AI] %s ABORT: %s is being eaten by %s", shortId, targetFood.Name, tostring(eater)))
						transitionToIdle("ClaimedByOther")
					else
						-- [v3.9] Validate Position (Despawn check)
						local foodPos = getItemPos(targetFood)
						if not foodPos then
							print(string.format("[AI] %s ABORT: Cannot find position for %s (Despawned?)", shortId, targetFood.Name))
							transitionToIdle("FoodDespawned")
						else
							-- [v4.25p] 덫 진입 로직 정상적인 else 위치로 복구
							local moveTarget = foodPos
							local moveTarget = foodPos
							if targetFood.Name == "CatTrap" then
								-- [DEBUG] Trace Targeting
								if tick() % 1 < 0.1 then
									print(string.format("[AI TRAP DEBUG] Cat %s processing Trap Logic", shortId))
								end
								
								local partEnter = targetFood:FindFirstChild("PartEnter", true)
								if partEnter then
									local pivot = targetFood:GetPivot()
									local gatePos = partEnter.Position
									local flatGatePos = Vector3.new(gatePos.X, pivot.Position.Y, gatePos.Z)
									
									local dirOut = (flatGatePos - pivot.Position)
									dirOut = (dirOut.Magnitude < 0.1) and pivot.LookVector or dirOut.Unit
									
									-- 입구 웨이포인트 (6스터드 밖)
									local entranceWaypoint = flatGatePos + dirOut * 6
									
									local distToBait = (currentPos - foodPos).Magnitude
									local distToWaypoint = (currentPos - entranceWaypoint).Magnitude
									
									-- [Optimization] 고스트 모드: 상태 변화 시에만 호출
									if (distToBait < 12) and not isGhostMode then
										isGhostMode = true
										-- [v4.25r] 물리 충돌 복구: 벽 뚫기 방지
										-- 대신 점프와 등반만 제한하여 얌전히 걷도록 유도
										hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
										hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
									elseif distToBait >= 12 and isGhostMode then
										isGhostMode = false
										hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
										hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
									end

									-- [v4.25p] 경로 유도 강화
									if not enteredEntrance then
										moveTarget = entranceWaypoint
										if distToWaypoint < 1.5 then enteredEntrance = true end
									end
									if distToBait > 20 then enteredEntrance = false end
								end
							end

							-- [Debug Visual]
							if not targetDebugPart then
								targetDebugPart = Instance.new("Part")
								targetDebugPart.Name = "AI_DEBUG_" .. shortId
								targetDebugPart.Shape = Enum.PartType.Ball
								targetDebugPart.Size = Vector3.new(1.2, 1.2, 1.2)
								targetDebugPart.Color = Color3.fromRGB(255, 0, 0)
								targetDebugPart.Material = Enum.Material.Neon
								targetDebugPart.Transparency = 0.5
								targetDebugPart.Anchored = true
								targetDebugPart.CanCollide = false
								targetDebugPart.CanQuery = false -- [v4.25v] Raycast 무시 (자기가 만든 빨간 점에 막히는 문제 해결)
								targetDebugPart.CanTouch = false
								targetDebugPart.Parent = workspace
							end
							targetDebugPart.Position = moveTarget
							
							-- [v4.25s] 장애물 회피 (Wall Check)
							-- 이동 방향으로 레이캐스트를 쏴서 벽이 있으면 멈춤 (CFrame 이동의 단점 보완)
							local dirVector = (moveTarget - currentPos)
							local flatDir = Vector3.new(dirVector.X, 0, dirVector.Z)
							local distToMove = flatDir.Magnitude
							local checkDist = math.min(distToMove, 2.0) -- 최대 2스터드 앞까지 검사
							
							-- [v4.25y] Dynamic Raycast Distance for Traps
							-- 덫 내부가 좁아서 2스터드 앞을 검사하면 뒷벽(BackWall)에 걸려 멈춰버림.
							-- 따라서 덫 근처에서는 검사 거리를 줄여서 더 깊이 들어갈 수 있게 함.
							if targetFood and targetFood.Name == "CatTrap" then
								-- 입구 근처(3스터드 이내)에서는 검사 거리를 0.5스터드로 단축
								if distToMove < 3.0 then
									checkDist = math.min(distToMove, 0.5)
								end
							end
							
							-- [v4.25u] Raycast 높이 상향 (바닥 턱 걸림 방지) & Food 무시
							local rayOrigin = currentPos + Vector3.new(0, 0.5, 0)
							local blocked = false
							
							-- 단일 레이캐스트
							local hitResult = workspace:Raycast(rayOrigin, flatDir.Unit * checkDist, obstacleRayParams)
							
							if hitResult then
								-- 1. PartEnter(Open) 통과
								if hitResult.Instance.Name == "PartEnter" and hitResult.Instance.CanCollide == false then
									blocked = false
								-- 2. Target Food의 Descendant
								elseif targetFood and hitResult.Instance:IsDescendantOf(targetFood) then
									if targetFood.Name == "CatTrap" then
										-- 입구/바닥은 통과
										if hitResult.Instance.Name == "PartEnter" or hitResult.Instance.Name == "TrapFloor" then
											blocked = false
										elseif hitResult.Normal.Y > 0.5 then
											blocked = false
										else
											blocked = true -- 벽
										end
									else
										blocked = false -- 일반 음식
									end
								else
									blocked = true -- 기타 장애물
								end
							end

							if not blocked then
								-- Move Step
								local dir = flatDir.Unit
								local step = speed * TICK_RATE
								nextXZ = currentPos + dir * step
							else
								-- blocked -> 제자리 멈춤 (미끄러짐 방지)
								nextXZ = currentPos
							end
							
							-- Rotation
							local lookCF = CFrame.lookAt(currentPos, Vector3.new(foodPos.X, currentPos.Y, foodPos.Z))
							logicRotation = lookCF.Rotation 
							
							-- [v3.9] Update WorldPosition for accuracy
							targetAtt.WorldPosition = foodPos
							
							-- [v4.25m] 도착 판정 (먹기 시작)
							local distToFoodActual = (foodPos - currentPos).Magnitude
							if distToFoodActual < 1.8 then
								if targetDebugPart then targetDebugPart:Destroy(); targetDebugPart = nil end
								
								-- [v4.23n] Final Existence Check
								if not targetFood or not targetFood.Parent then
									transitionToIdle("FoodDespawnedAtLastMoment")
								elseif FoodClaims[targetFood] == catId then
									state = "Eating"
									enteredEntrance = false 
									idleTimer = 0
									
									-- [v4.2] Set Exclusive Eating Attribute
									targetFood:SetAttribute("EatingBy", catId)
									print(string.format("[AI] %s STARTED EATING %s (%s) -> EatingBy Locked", shortId, targetFood.Name, tostring(targetFood:GetAttribute("RefID"))))
									
									-- [v4.3] Disable Pickup for players
									local cd = targetFood:FindFirstChildOfClass("ClickDetector")
									if cd then cd.MaxActivationDistance = 0 end
									
									-- [v4.25c] Restored targeting beam cleanup
									targetBeam.Enabled = false
									
									-- [VISUAL FEEDBACK]
									local heartGUI = Instance.new("BillboardGui")
									heartGUI.Name = "HappyHeart"
									heartGUI.Size = UDim2.new(2, 0, 2, 0)
									heartGUI.Adornee = head
									heartGUI.StudsOffset = Vector3.new(0, 2, 0)
									heartGUI.Parent = head
									
									local label = Instance.new("TextLabel")
									label.BackgroundTransparency = 1
									label.Size = UDim2.new(1, 0, 1, 0)
									label.Text = "❤️"
									label.TextScaled = true
									label.Parent = heartGUI
									
									task.delay(2.5, function()
										if heartGUI then heartGUI:Destroy() end
									end)
								else
									transitionToIdle("ClaimLostAtLastMoment")
								end
							end
					end
				end -- [v4.18] Close searchTimer
			end
			elseif state == "Eating" then
				idleTimer += TICK_RATE 
				
				-- [v4.8] Continuous Lock Check
				-- [v4.23n] Ignore if already destroyed (Self-Cleanup Phase)
				if targetFood and targetFood.Parent and FoodClaims[targetFood] ~= catId then
					print(string.format("[AI] %s ABORT EATING. Lock stolen by %s", shortId, tostring(FoodClaims[targetFood])))
					transitionToIdle("LockStolenWhileEating")
					return 
				end
				
				-- [v4.23z] Reverted to 5s (Middle ground)
				if idleTimer >= 5.0 and targetFood and targetFood.Parent and FoodClaims[targetFood] == catId then
					print(string.format("[AI] %s FINISHED EATING %s (%s)", shortId, targetFood.Name, tostring(targetFood:GetAttribute("RefID"))))
					
					-- [v4.25m] CatTrap인 경우 파괴하지 않고 포획 신호 전달
					if targetFood.Name == "CatTrap" then
						targetFood:SetAttribute("CaptureSignal", catId)
					else
						targetFood:Destroy()
					end
					
					FoodClaims[targetFood] = nil -- Clean memory
				end
				

				
				if idleTimer >= 5.5 then
					state = "Idle"
					idleTimer = 0
					idleDuration = 5
					if targetFood then FoodClaims[targetFood] = nil end
					targetFood = nil
				end

			end -- Close State Machine (Idle/Moving/Eating)
			
			
			-- [v4.23i] REMOVED DUPLICATE PHYSICS BLOCK

			
			
			
			
			
			
			
			-- [v4.26m] Update FOV Visualization (Eye Level Radar)
			local fovDist = 20
			local rawHeading = logicRotation * Vector3.new(0,0,-1)
			local baseHeading = Vector3.new(rawHeading.X, 0, rawHeading.Z).Unit 
			
			local eyeY = cleanPos.Y + 0.7 -- [v4.26m] Raised to eye level
			local eyeBase = Vector3.new(cleanPos.X, eyeY, cleanPos.Z)
			
			-- [v4.26i] Change up vector to (1, 0, 0) as requested
			local lookCF = CFrame.lookAt(eyeBase, eyeBase + baseHeading, Vector3.new(1, 0, 0))
			
			-- Force root attachment orientation
			attFOVSource.WorldCFrame = lookCF

			-- [v4.27d] FOV Visibility Logic (Steady, not pulsing)
			-- Conditions: food within 30 studs AND cat is not eating
			local foodNearby = false
			local worldItems = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WorldItems")
			if worldItems then
				for _, item in ipairs(worldItems:GetChildren()) do
					if item:GetAttribute("IsFood") then
						local foodPos = getItemPos(item)
						if foodPos and (foodPos - cleanPos).Magnitude <= 30 then
							foodNearby = true
							break
						end
					end
				end
			end
			
			local showFOV = foodNearby and state ~= "Eating"

			-- [v4.26l] Update 8-segment Sector Surface (Smooth Arc)
			-- Scale: 90 degrees total / 8 segments = 11.25 degrees per segment
			-- Centers: -39.375, -28.125, -16.875, -5.625, 5.625, 16.875, 28.125, 39.375
			for i = 1, 8 do
				local segment = fovSurfaces[i]
				segment.beam.Enabled = showFOV
				
				if showFOV then
					local angle = -45 + (11.25 * (i - 0.5))
					local dir = CFrame.Angles(0, math.rad(-angle), 0) * baseHeading
					local targetPos = eyeBase + (dir * fovDist)
					segment.att.WorldCFrame = CFrame.lookAt(targetPos, targetPos + baseHeading, Vector3.new(1,0,0))
				end
			end

			-- Reuse t logic
			local t = tick() * 15
			local isMoving = (state == "Moving" or state == "MovingToFood")
			local isEating = (state == "Eating")
			
			-- [Added] Torso Override for Eating Motion
			if isEating then
				local eatCycle = math.sin(t * 0.6) -- Slow rhythmic cycle
				-- [v2.4] Translation BEFORE Rotation to ensure strictly vertical lowering
				torso.CFrame = torso.CFrame * CFrame.new(0, -0.15 * (eatCycle + 1), 0)
				torso.CFrame = torso.CFrame * CFrame.Angles(math.rad(-10 * (eatCycle + 1)), 0, 0)
			end
			
			-- [v4.24b] Leg Animation (Restored)
			if isMoving then
				local angle = math.rad(20) * math.sin(t)
				legFL.CFrame = torso.CFrame * CFrame.new(-0.35, -1, -0.8) * CFrame.Angles(angle, 0, 0)
				legFR.CFrame = torso.CFrame * CFrame.new(0.35, -1, -0.8) * CFrame.Angles(-angle, 0, 0)
				legBL.CFrame = torso.CFrame * CFrame.new(-0.35, -1, 0.8) * CFrame.Angles(-angle, 0, 0)
				legBR.CFrame = torso.CFrame * CFrame.new(0.35, -1, 0.8) * CFrame.Angles(angle, 0, 0)
			else
				legFL.CFrame = torso.CFrame * CFrame.new(-0.35, -1, -0.8)
				legFR.CFrame = torso.CFrame * CFrame.new(0.35, -1, -0.8)
				legBL.CFrame = torso.CFrame * CFrame.new(-0.35, -1, 0.8)
				legBR.CFrame = torso.CFrame * CFrame.new(0.35, -1, 0.8)
			end
			
			-- Head
			if isEating then
				local chewBob = math.sin(t * 1.5) * 0.15 -- Faster chewing bob
				-- Tilt forward (Negative X)
				head.CFrame = torso.CFrame * CFrame.new(0, 0.7 + chewBob, -0.8) * CFrame.Angles(math.rad(-15 - chewBob * 5), 0, 0)
			else
				head.CFrame = torso.CFrame * CFrame.new(0, 0.7, -0.8)
			end
			
			-- 꼬리 애니메이션
			local tailAngle = 45 + math.sin(t)*15
			local tailOffset = Vector3.new(0, 0.5, 1.0)
			local tailLength = 1.2
			tail.CFrame = torso.CFrame * CFrame.new(tailOffset) * CFrame.Angles(math.rad(tailAngle), 0, 0) * CFrame.new(0, 0, tailLength/2)
			
			
		end
			
		end
	)
end

return MapGenerator
