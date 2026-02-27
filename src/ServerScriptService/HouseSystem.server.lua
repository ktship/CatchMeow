local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CollectionService = game:GetService("CollectionService")

-- Create RemoteEvent for UI Transition
local transitionEvent = Instance.new("RemoteEvent")
transitionEvent.Name = "HouseTransition"
transitionEvent.Parent = ReplicatedStorage

-- Store original positions
local playerOriginalPositions = {}

-- Temporary room generation
local houseInteriorSpawn = nil

local function getOrCreateHouseInterior()
	if houseInteriorSpawn then return houseInteriorSpawn end
	
	-- Create a simple room at Y = 500
	local roomModel = Instance.new("Model")
	roomModel.Name = "TempHouseInterior"
	roomModel.Parent = workspace
	
	local x, y, z = 0, 500, 0
	
	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(30, 1, 30)
	floor.Position = Vector3.new(x, y, z)
	floor.Color = Color3.fromRGB(130, 90, 60)
	floor.Material = Enum.Material.WoodPlanks
	floor.Anchored = true
	floor.Parent = roomModel
	
	-- Walls
	local wallColor = Color3.fromRGB(240, 230, 210) -- 따뜻한 벽지 색상
	local function createWall(size, pos)
		local wall = Instance.new("Part")
		wall.Size = size
		wall.Position = pos
		wall.Color = wallColor
		wall.Material = Enum.Material.Plastic
		wall.Anchored = true
		wall.Parent = roomModel
	end
	
	createWall(Vector3.new(30, 15, 1), Vector3.new(x, y + 8, z - 15)) -- Back
	createWall(Vector3.new(30, 15, 1), Vector3.new(x, y + 8, z + 15)) -- Front
	createWall(Vector3.new(1, 15, 30), Vector3.new(x - 15, y + 8, z)) -- Left
	createWall(Vector3.new(1, 15, 30), Vector3.new(x + 15, y + 8, z)) -- Right
	
	-- Roof
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(30, 1, 30)
	roof.Position = Vector3.new(x, y + 16, z)
	roof.Color = Color3.fromRGB(200, 200, 200)
	roof.Anchored = true
	roof.Parent = roomModel
	
	-- Exit Door
	local exitDoor = Instance.new("Part")
	exitDoor.Name = "ExitDoor"
	exitDoor.Size = Vector3.new(5, 8, 1)
	exitDoor.Position = Vector3.new(x, y + 4.5, z + 14.5)
	exitDoor.Color = Color3.fromRGB(80, 50, 30)
	exitDoor.Material = Enum.Material.Wood
	exitDoor.Anchored = true
	exitDoor.Parent = roomModel
	
	local exitPrompt = Instance.new("ProximityPrompt")
	exitPrompt.ActionText = "나가기"
	exitPrompt.ObjectText = "문"
	exitPrompt.RequiresLineOfSight = false
	exitPrompt.MaxActivationDistance = 8
	exitPrompt.Parent = exitDoor
	
	CollectionService:AddTag(exitDoor, "HouseExit")
	
	-- 내부 소품 추가 (침대, 러그 등)
	local rug = Instance.new("Part")
	rug.Name = "Rug"
	rug.Size = Vector3.new(12, 0.2, 10)
	rug.Position = Vector3.new(x, y + 0.6, z)
	rug.Color = Color3.fromRGB(200, 100, 100)
	rug.Material = Enum.Material.Fabric
	rug.Anchored = true
	rug.Parent = roomModel
	
	local bed = Instance.new("Part")
	bed.Name = "Bed"
	bed.Size = Vector3.new(6, 2, 8)
	bed.Position = Vector3.new(x - 8, y + 1.5, z - 7)
	bed.Color = Color3.fromRGB(255, 255, 255)
	bed.Material = Enum.Material.Fabric
	bed.Anchored = true
	bed.Parent = roomModel

	local desk = Instance.new("Part")
	desk.Name = "Desk"
	desk.Size = Vector3.new(8, 3, 4)
	desk.Position = Vector3.new(x + 8, y + 2, z - 8)
	desk.Color = Color3.fromRGB(100, 70, 40)
	desk.Material = Enum.Material.Wood
	desk.Anchored = true
	desk.Parent = roomModel
	
	-- Spawn Point (Inside room)
	houseInteriorSpawn = Vector3.new(x, y + 3, z + 5)
	
	-- Add some basic point light
	local lightPart = Instance.new("Part")
	lightPart.Size = Vector3.new(2, 0.5, 2)
	lightPart.Position = Vector3.new(x, y + 15, z)
	lightPart.Color = Color3.fromRGB(255, 255, 200)
	lightPart.Material = Enum.Material.Neon
	lightPart.Anchored = true
	lightPart.Parent = roomModel
	
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 1.5
	light.Color = Color3.fromRGB(255, 240, 200)
	light.Parent = lightPart
	
	return houseInteriorSpawn
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local door = prompt.Parent
	if not door then return end
	
	if CollectionService:HasTag(door, "HouseDoor") then
		-- Entering House
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hrp = char.HumanoidRootPart
			-- 문 앞의 약간 떨어진 위치를 저장하여 퇴장 시 문에 끼이지 않게 함
			playerOriginalPositions[player.UserId] = hrp.CFrame * CFrame.new(0, 0, 4)
			
			-- Fade Out
			transitionEvent:FireClient(player, "FadeOut")
			task.wait(0.5) -- Wait for fade
			
			local interiorSpawn = getOrCreateHouseInterior()
			hrp.CFrame = CFrame.new(interiorSpawn)
			
			-- Fade In
			transitionEvent:FireClient(player, "FadeIn")
		end
		
	elseif CollectionService:HasTag(door, "HouseExit") then
		-- Exiting House
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hrp = char.HumanoidRootPart
			local originalCFrame = playerOriginalPositions[player.UserId]
			
			if originalCFrame then
				transitionEvent:FireClient(player, "FadeOut")
				task.wait(0.5)
				
				hrp.CFrame = originalCFrame
				playerOriginalPositions[player.UserId] = nil -- clear
				
				transitionEvent:FireClient(player, "FadeIn")
			else
				-- Fallback if no saved position
				transitionEvent:FireClient(player, "FadeOut")
				task.wait(0.5)
				hrp.CFrame = CFrame.new(0, 10, 0)
				transitionEvent:FireClient(player, "FadeIn")
			end
		end
	end
end)

-- Cleanup on leave
game.Players.PlayerRemoving:Connect(function(player)
	playerOriginalPositions[player.UserId] = nil
end)
