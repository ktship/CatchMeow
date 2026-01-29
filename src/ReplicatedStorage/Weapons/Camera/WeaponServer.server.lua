local Tool = script.Parent
local Remote = Tool:WaitForChild("FireEvent")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))

local Debris = game:GetService("Debris")

Remote.OnServerEvent:Connect(function(player, targetPosition)
	-- 기본 검증
	if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then return end
	if player.Character:FindFirstChild(Config.Camera.Name) ~= Tool then return end
	
	local handle = Tool:FindFirstChild("Handle")
	if not handle then return end
	
	-- 레이캐스팅 (촬영 대상 확인용)
	local origin = handle.Position
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
		local humanoid = hitPart.Parent:FindFirstChild("Humanoid") or hitPart.Parent.Parent:FindFirstChild("Humanoid")
		
		if humanoid then
			-- 플레이어를 찍었을 때의 로직 (예: 이름 출력)
			print(player.Name .. " captured " .. humanoid.Parent.Name)
		end
	end
end)
