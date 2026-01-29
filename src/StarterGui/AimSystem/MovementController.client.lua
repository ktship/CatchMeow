-- MovementController.client.lua
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- 설정
local PRONE_KEY = "ProneAction"
local NORMAL_SPEED = 16
local PRONE_SPEED = 4 -- 8에서 4로 감속 (느리게 기어가듯)
local PRONE_JUMP = 0

local isProne = false

-- 엎드리기 자세 제어용 변수
local rootJoint = nil
local originalC0 = nil
local originalHipHeight = 2 -- 기본값 (나중에 읽어옴)

-- 캐릭터 초기화 함수
local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	
	originalHipHeight = humanoid.HipHeight -- 원래 높이 저장
	
	-- R15의 경우 LowerTorso의 Root, R6의 경우 HumanoidRootPart의 RootJoint
	-- R15 Check
	local lowerTorso = char:FindFirstChild("LowerTorso")
	if lowerTorso then
		rootJoint = lowerTorso:FindFirstChild("Root")
	else
		-- R6 Check
		rootJoint = root:FindFirstChild("RootJoint")
	end
	
	if rootJoint then
		originalC0 = rootJoint.C0
	end
	
	-- 사망 시 리셋
	humanoid.Died:Connect(function()
		isProne = false
		ContextActionService:UnbindAction(PRONE_KEY)
	end)
end

-- 엎드리기 토글
local function toggleProne(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		if not rootJoint then return end
		
		isProne = not isProne
		character:SetAttribute("IsProne", isProne)
		
		if isProne then
			-- 엎드리기 상태 진입
			humanoid.WalkSpeed = PRONE_SPEED
			humanoid.JumpPower = PRONE_JUMP
			
			-- 자세 변경 (RootJoint 90도 회전 - 눕기)
			local goalC0 = originalC0 * CFrame.Angles(math.rad(-90), 0, 0) -- R15/R6 -90도가 엎드림
			
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(rootJoint, tweenInfo, {C0 = goalC0}):Play()
			
			-- 시야 낮추기
			TweenService:Create(humanoid, tweenInfo, {CameraOffset = Vector3.new(0, -2, 0)}):Play()
			
			-- 힙 높이 낮추기 (복구)
			local targetHip = math.max(0, originalHipHeight - 1.3) 
			TweenService:Create(humanoid, tweenInfo, {HipHeight = targetHip}):Play() 
			
			-- [수정] 1. 다리 충돌 끄기 (물리 충돌 방지)
			-- 애니메이션은 유지하되, 팔다리가 땅을 쳐도 튕기지 않게 함
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "Head" then
					part.CanCollide = false
				end
			end
			
		else
			-- 일어서기
			humanoid.WalkSpeed = NORMAL_SPEED
			humanoid.JumpPower = NORMAL_JUMP
			
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(rootJoint, tweenInfo, {C0 = originalC0}):Play()
			
			TweenService:Create(humanoid, tweenInfo, {CameraOffset = Vector3.new(0, 0, 0)}):Play()
			
			-- 힙 높이 복구
			TweenService:Create(humanoid, tweenInfo, {HipHeight = originalHipHeight}):Play()
			
			-- 충돌 복구
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "Head" then
					part.CanCollide = true
				end
			end
		end
	end
end

-- 초기화
if player.Character then 
	setupCharacter(player.Character) 
end
player.CharacterAdded:Connect(function(c)
	setupCharacter(c)
end)

-- 키 바인딩
ContextActionService:BindAction(PRONE_KEY, toggleProne, true, Enum.KeyCode.X)
ContextActionService:SetTitle(PRONE_KEY, "Prone")

-- 애니메이션 속도 제어
local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function()
	if not isProne or not humanoid then return end
	
	-- 엎드렸을 때는 애니메이션 속도를 느리게 (0.5배)
	-- 기본 Animate가 계속 속도를 덮어씌우려 하므로 반복적으로 적용
	local tracks = humanoid:GetPlayingAnimationTracks()
	for _, track in pairs(tracks) do
		-- 이동 애니메이션만 느리게 하고 싶다면 이름 확인 필요하지만,
		-- 엎드렸을 때 전반적으로 느려지는 게 자연스러움
		if track.Speed > 0.6 then -- 이미 느려진 건 건드리지 않음 (0 확인)
			track:AdjustSpeed(0.5)
		end
	end
end)
