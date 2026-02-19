local Tool = script.Parent
local Remote = Tool:WaitForChild("FireEvent")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))

local Debris = game:GetService("Debris")

Remote.OnServerEvent:Connect(function(player, targetPosition)
	print("[Photo Debug] OnServerEvent")
	-- 기본 검증
	if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then return end
	if player.Character:FindFirstChild(Config.Camera.Name) ~= Tool then return end
	
	local handle = Tool:FindFirstChild("Handle")
	if not handle then return end
	
	-- 레이캐스팅 (촬영 대상 확인용) - 렌즈 위치에서 시작
	local lens = handle:FindFirstChild("Lens")
	local origin = lens and lens.WorldPosition or handle.Position
	local direction = (targetPosition - origin).Unit
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	-- [Added] Photo Count Tracking for Dialogue
	-- Increment regardless of what is hit, as Client saves every photo
	local currentCount = player:GetAttribute("PhotoCount") or 0
	player:SetAttribute("PhotoCount", currentCount + 1)
	print("[Photo Debug] currentCount", currentCount)

	local rayResult = workspace:Raycast(origin, direction * Config.Camera.Range, raycastParams)

	if rayResult then
		print("[Photo Debug] rayResult")

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
			print("[Photo Debug] rootModel", rootModel)

			local objectName = rootModel.Name
			local isMatch = false
			local target = player:GetAttribute("TargetCat")
			
			-- UUID Check
			local MapGenerator = require(game.ServerScriptService.MapGenerator)
			local targetUUID = MapGenerator.TargetCatUUID
			
			-- Debug Logs
			print("[Photo Debug] User:", player.Name)
			print("[Photo Debug] Target:", target or "Nil")
			print("[Photo Debug] Object:", objectName)
			print("[Photo Debug] TargetUUID:", targetUUID or "Nil")
			
			-- ID Validation (유일한 매칭 로직)
			if target and target == objectName then
				isMatch = true
				print(">> MATCH BY DIRECT ID!")
			end
			
			print("[Photo Debug] IsMatch Result:", isMatch)
			print("---------------------------------")
			
			-- Send Feedback
			local feedbackEvent = game.ReplicatedStorage.Events:FindFirstChild("PhotoFeedback")
			if feedbackEvent then
				feedbackEvent:FireClient(player, isMatch, target, objectName)
			end
		end
	end
end)
