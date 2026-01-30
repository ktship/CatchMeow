local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

-- Car Parameters
-- These map properties must match MapGenerator EXACTLY
local mapSize = Config.Map.Size
local halfSize = mapSize / 2
local roadAmp = Config.Map.Road.Amplitude
local roadFreq = Config.Map.Road.Frequency
local carSpeed = 30 -- Speed in studs per second

local carsFolder = workspace:FindFirstChild("Cars")
if not carsFolder then
	carsFolder = Instance.new("Folder")
	carsFolder.Name = "Cars"
	carsFolder.Parent = workspace
end

-- Math Helper for Road Path
local function getRoadX(z)
	return roadAmp * math.sin(z * roadFreq)
end

-- Function to spawn a detailed car
local function spawnCar()
	local model = Instance.new("Model")
	model.Name = "TrafficCar"
	
	-- 1. Main Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(6, 3, 10) -- Slightly lower body
	body.Color = Color3.fromHSV(math.random(), 0.7, 0.9)
	body.Material = Enum.Material.Plastic
	body.Anchored = true
	body.CanCollide = false
	body.CastShadow = true
	body.Parent = model
	model.PrimaryPart = body
	
	-- 2. Cabin/Roof
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(5, 1.5, 5)
	roof.Color = body.Color
	roof.Material = Enum.Material.Plastic
	roof.Anchored = true
	roof.CanCollide = false
	roof.CFrame = body.CFrame * CFrame.new(0, 2.25, 0)
	roof.Parent = model
	
	-- 3. Wheels (4x)
	local wheelSize = 3.5 -- Bigger wheels (2.5 -> 3.5)
	local wheelWidth = 1.2 -- Slightly wider too
	local wheelOffsets = {
		Vector3.new(-3, -1.5, -3), -- Front Left
		Vector3.new(3, -1.5, -3),  -- Front Right
		Vector3.new(-3, -1.5, 3),  -- Back Left
		Vector3.new(3, -1.5, 3),   -- Back Right
	}
	
	for _, offset in ipairs(wheelOffsets) do
		local wheel = Instance.new("Part")
		wheel.Name = "Wheel"
		wheel.Shape = Enum.PartType.Cylinder
		-- Cylinder: X is height (width), Y/Z are radius (diameter)
		wheel.Size = Vector3.new(wheelWidth, wheelSize, wheelSize)
		wheel.Color = Color3.new(0.1, 0.1, 0.1)
		wheel.Material = Enum.Material.Rubber
		wheel.Anchored = true
		wheel.CanCollide = false
		-- Rotate 90 deg on Z to make cylinder face sideways
		-- Cylinder X axis is height, aligning with Body RightVector (X). No rotation needed.
		wheel.CFrame = body.CFrame * CFrame.new(offset)
		wheel.Parent = model
	end
	
	-- 4. Lights
	-- Headlights (Front)
	local lightSize = Vector3.new(1, 0.5, 0.2)
	local hLeft = Instance.new("Part")
	hLeft.Name = "Headlight"
	hLeft.Size = lightSize
	hLeft.Color = Color3.new(1, 1, 0.8) -- Warm White
	hLeft.Material = Enum.Material.Neon
	hLeft.Anchored = true
	hLeft.CanCollide = false
	hLeft.CFrame = body.CFrame * CFrame.new(-2, 0.5, -5.1) -- Front face
	hLeft.Parent = model
	
	local hRight = hLeft:Clone()
	hRight.CFrame = body.CFrame * CFrame.new(2, 0.5, -5.1)
	hRight.Parent = model
	
	-- Taillights (Back)
	local tLeft = hLeft:Clone()
	tLeft.Name = "Taillight"
	tLeft.Color = Color3.new(1, 0, 0) -- Red
	tLeft.CFrame = body.CFrame * CFrame.new(-2, 0.5, 5.1) -- Back face
	tLeft.Parent = model
	
	local tRight = tLeft:Clone()
	tRight.CFrame = body.CFrame * CFrame.new(2, 0.5, 5.1)
	tRight.Parent = model

	-- Start at North End (z = -halfSize)
	local startZ = -halfSize
	
	model:SetAttribute("CurrentZ", startZ)
	model.Parent = carsFolder
end

-- Game Status Check
local gameStatus = ReplicatedStorage:WaitForChild("GameStatus")

-- Interval Loop: Spawn every 5 seconds
task.spawn(function()
	while true do
		-- Only spawn if game is in progress
		if gameStatus.Value == "Game in Progress" then
			spawnCar()
		end
		-- Random spawn interval: 4 to 8 seconds
		task.wait(math.random(4, 8))
	end
end)

-- Cleanup when game ends/restarts
gameStatus.Changed:Connect(function(newStatus)
	if newStatus ~= "Game in Progress" then
		-- Clear all cars immediately
		for _, car in ipairs(carsFolder:GetChildren()) do
			car:Destroy()
		end
	end
end)

-- Shared Collision Debounce (Global or per car? Per car logic is better, but global loop is fine)
local GLOBAL_DEBOUNCE = {}

-- Movement Loop: Heartbeat
RunService.Heartbeat:Connect(function(dt)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {carsFolder} -- Don't detect other cars
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	for _, car in ipairs(carsFolder:GetChildren()) do
		if car:IsA("Model") and car.PrimaryPart then
			local root = car.PrimaryPart
			local currentZ = car:GetAttribute("CurrentZ") or -halfSize
			
			-- Move forward
			local nextZ = currentZ + (carSpeed * dt)
			
			-- Check if reached end
			if nextZ > halfSize then
				car:Destroy()
			else
				-- Update Position
				car:SetAttribute("CurrentZ", nextZ)
				
				-- Calculate Path
				local currentX = getRoadX(nextZ)
				
				-- Look ahead for rotation
				local lookZ = nextZ + 1
				local lookX = getRoadX(lookZ)
				
				-- Adjusted height: 4.5 (Lifted suspension)
				local currentPos = Vector3.new(currentX, 4.5, nextZ) 
				local lookPos = Vector3.new(lookX, 4.5, lookZ)
				
				local targetCFrame = CFrame.lookAt(currentPos, lookPos)
				
				-- Move Model
				car:PivotTo(targetCFrame)
				
				-- COLLISION CHECK (Spatial Query on Body)
				local parts = workspace:GetPartsInPart(root, overlapParams)
				for _, part in ipairs(parts) do
					local character = part.Parent
					local humanoid = character:FindFirstChild("Humanoid")
					local rootPart = character:FindFirstChild("HumanoidRootPart")
					
						if humanoid and rootPart and humanoid.Health > 0 then
							-- Check for Spawn Protection (ForceField)
							if character:FindFirstChildOfClass("ForceField") then
								-- Skip collision if player is invincible
								return 
							end

							if not GLOBAL_DEBOUNCE[character] then
								GLOBAL_DEBOUNCE[character] = true
								
								print("Hit Character:", character.Name)
							
							-- 1. Damage
							humanoid:TakeDamage(40)
							
							-- 2. Physics Fling
							-- Set Network Owner to Server temporarily to ensure force applies
							-- (Requires Unanchored handle? Character is unanchored)
							if rootPart:CanSetNetworkOwnership() then
								rootPart:SetNetworkOwner(nil) -- Server takes control
							end
							
							humanoid.PlatformStand = true -- Free fall physics
							
							local flingDir = (rootPart.Position - root.Position).Unit
							-- Higher Jump: Up 100 -> 150. Horizontal force unchanged (50).
							local flingForce = flingDir * 50 + Vector3.new(0, 150, 0)
							
							-- Use Velocity directly for instant snap
							rootPart.AssemblyLinearVelocity = flingForce
							
						-- Clear visual tumble (X/Z axes dominant): 4 to 8 radians/sec
						local function sign() return math.random() > 0.5 and 1 or -1 end
						local spinX = (math.random(40, 80) / 10) * sign()
						local spinY = (math.random(5, 10) / 10) * sign() -- Low Y spin
						local spinZ = (math.random(40, 80) / 10) * sign()
						
						rootPart.AssemblyAngularVelocity = Vector3.new(spinX, spinY, spinZ)
							
							-- Visual Effect: Stun Halo (3D Spinning Stars)
							local head = character:FindFirstChild("Head")
							local stunModel
							
							if head then
								stunModel = Instance.new("Model")
								stunModel.Name = "StunEffect"
								
								-- 1. Center Part (Spinner)
								local spinner = Instance.new("Part")
								spinner.Name = "Spinner"
								spinner.Size = Vector3.new(0.5, 0.5, 0.5)
								spinner.Transparency = 1
								spinner.CanCollide = false
								spinner.Massless = true
								spinner.CFrame = head.CFrame * CFrame.new(0, 2, 0)
								spinner.Parent = stunModel
								
								-- 2. Constraint (Motor)
								local attHead = Instance.new("Attachment")
								attHead.Name = "AttStunHead"
								attHead.Position = Vector3.new(0, 2, 0) -- Relative to Head Center
								attHead.Axis = Vector3.new(0, 1, 0) -- Axis points UP (Crown to Sky)
								attHead.Parent = head
								
								local attSpinner = Instance.new("Attachment")
								attSpinner.Name = "AttSpinner"
								attSpinner.Axis = Vector3.new(0, 1, 0) -- Axis points UP
								attSpinner.Parent = spinner
								
								local hinge = Instance.new("HingeConstraint")
								hinge.Attachment0 = attHead
								hinge.Attachment1 = attSpinner
								hinge.ActuatorType = Enum.ActuatorType.Motor
								hinge.AngularVelocity = 10 -- Faster Scale (5 -> 10)
								hinge.MotorMaxTorque = math.huge
								hinge.Parent = spinner
								
								-- 3. Stars (3 count)
								local starCount = 3
								local radius = 2.5
								
								for i = 1, starCount do
									local angle = math.rad((360 / starCount) * i)
									local x = math.cos(angle) * radius
									local z = math.sin(angle) * radius
									
									local starAtt = Instance.new("Attachment")
									starAtt.Position = Vector3.new(x, 0, z)
									starAtt.Parent = spinner
									
									local billboard = Instance.new("BillboardGui")
									billboard.Name = "Star"
									-- Size Halved (2 -> 1 Stud)
									billboard.Size = UDim2.new(1, 0, 1, 0) 
									billboard.Adornee = starAtt
									billboard.AlwaysOnTop = true
									billboard.Parent = spinner -- Parent to part handles cleanup
									
									local img = Instance.new("ImageLabel")
									img.BackgroundTransparency = 1
									img.Size = UDim2.new(1, 0, 1, 0)
									img.Image = "rbxassetid://1266170131" -- Original Star Texture
									img.ImageColor3 = Color3.fromRGB(255, 230, 50) -- Yellow
									img.Parent = billboard
								end
								
								stunModel.Parent = character
							end
							
							-- Release control back to client after fling
							-- Stun Duration: 3 seconds (User Request)
							-- Release control back to client after fling
							-- Stun Duration: 3 seconds (User Request)
							task.delay(3, function()
								humanoid.PlatformStand = false
								GLOBAL_DEBOUNCE[character] = nil
								if rootPart:CanSetNetworkOwnership() then
									-- Reverting to auto/nil usually fine, the client will grab it back
									rootPart:SetNetworkOwner(nil) 
								end
								
								-- Extend visual effect slightly to cover the 'Getting Up' animation (1.5s delay)
								-- (User feedback: Stars vanish but can't move for 1-2s. GettingUp state locks movement)
								task.delay(1.5, function()
									if stunModel then
										stunModel:Destroy()
									end
									-- Cleanup head attachment if it survived
									local oldAtt = head:FindFirstChild("AttStunHead")
									if oldAtt then oldAtt:Destroy() end
								end)
							end)
						end
					end
				end
			end
		end
	end
end)

print("Traffic Controller Started: Cars spawning every 5s")
