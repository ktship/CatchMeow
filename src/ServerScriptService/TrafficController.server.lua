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

-- Function to spawn a single car
local function spawnCar()
	local car = Instance.new("Part")
	car.Name = "TrafficCar"
	car.Size = Vector3.new(6, 4, 10) -- Boxy car
	car.Color = Color3.fromHSV(math.random(), 0.7, 0.9) -- Random bright color
	car.Material = Enum.Material.Metal
	car.Anchored = true -- We move it via CFrame script (Kinematic)
	car.CanCollide = false -- Ghost car to prevent blocking players physically (for now)
	car.CastShadow = true
	
	-- Start at North End (z = -halfSize)
	local startZ = -halfSize
	
	car:SetAttribute("CurrentZ", startZ)
	
	car.Parent = carsFolder
	
	-- Collision Handling
	local hitDebounce = {}
	
	-- Note: Touched doesn't fire reliably for CFrame moved Anchored parts interacting with players.
	-- We will handle collision in the main loop using GetPartsInPart
	
	car:SetAttribute("CurrentZ", startZ)
	car.Parent = carsFolder
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
		task.wait(5)
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
		if car:IsA("BasePart") then
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
				
				local currentPos = Vector3.new(currentX, 2.5, nextZ) -- Height slightly above road
				local lookPos = Vector3.new(lookX, 2.5, lookZ)
				
				car.CFrame = CFrame.lookAt(currentPos, lookPos)
				
				-- COLLISION CHECK (Spatial Query)
				local parts = workspace:GetPartsInPart(car, overlapParams)
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
							
							local flingDir = (rootPart.Position - car.Position).Unit
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
