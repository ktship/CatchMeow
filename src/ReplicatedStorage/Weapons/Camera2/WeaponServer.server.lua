local Tool = script.Parent
local Remote = Tool:WaitForChild("FireEvent")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))

local Debris = game:GetService("Debris")

Remote.OnServerEvent:Connect(function(player, targetPosition)
	-- 기본 검증
	if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then return end
	-- Camera2 uses "Camera2" name now, so check for tool match directly
	if player.Character:FindFirstChild("Camera2") ~= Tool then return end
	
	local handle = Tool:FindFirstChild("Handle")
	if not handle then return end
	
	-- 레이캐스팅 (촬영 대상 확인용) - 렌즈 위치에서 시작
	local lens = handle:FindFirstChild("Lens")
	local origin = lens and lens.WorldPosition or handle.Position
	local direction = (targetPosition - origin).Unit
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rayResult = workspace:Raycast(origin, direction * Config.Camera.Range, raycastParams)
	
	if rayResult then
		-- 플래시 효과를 찍히는 쪽에 생성
		local flashPart = Instance.new("Part")
		flashPart.Size = Vector3.new(0.5, 0.5, 0.5)
		flashPart.Position = rayResult.Position
		flashPart.Anchored = true
		flashPart.CanCollide = false
		flashPart.Transparency = 1
		flashPart.Parent = workspace
		
		local flash = Instance.new("PointLight")
		flash.Brightness = 5
		flash.Range = 10
		flash.Color = Color3.new(1, 1, 1)
		flash.Parent = flashPart
		
		Debris:AddItem(flashPart, 0.15) -- 0.15초 후 삭제
		
		-- 무엇을 찍었는지 확인
		local hitPart = rayResult.Instance
		local rootModel = hitPart:FindFirstAncestorOfClass("Model")
		
		if rootModel then
			local objectName = rootModel.Name
			local colorName = rootModel:GetAttribute("ColorName")
			local isMatch = false
			local target = player:GetAttribute("TargetCat")
			
			-- 1. Identify Object
			if objectName == "TrafficCar" then
				objectName = "Car"
				local body = rootModel:FindFirstChild("Body")
				if body then
					colorName = body.BrickColor.Name
				end
			elseif objectName == "Cat" then
				if colorName == target then
					isMatch = true
				end
			end
			
			-- 2. Distance/Size Check
			local dist = (rayResult.Position - origin).Magnitude
			local maxDist = Config.Camera.VerificationDistance or 40
			
			if dist > maxDist then
				isMatch = false
				objectName = objectName .. " (Too Far/Small)"
			end
			
			-- 3. Send Feedback (Log Mode)
			local feedbackEvent = game.ReplicatedStorage.Events:FindFirstChild("PhotoFeedback")
			if feedbackEvent then
				feedbackEvent:FireClient(player, isMatch, target, objectName, colorName)
			end
		end
	end
end)
