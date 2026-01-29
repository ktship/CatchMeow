-- AimController.client.lua
-- StarterGui/AimSystem/AimController.client.lua

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- 레이저 시각 효과
local visualFolder = Instance.new("Folder")
visualFolder.Name = "AimVisuals"
visualFolder.Parent = workspace

mouse.TargetFilter = visualFolder

local laserBeam = Instance.new("Part")
laserBeam.Name = "LaserBeam"
laserBeam.Anchored = true
laserBeam.CanCollide = false
laserBeam.CanQuery = false
laserBeam.CanTouch = false
laserBeam.Material = Enum.Material.Neon
laserBeam.Color = Color3.new(1, 0, 0) 
laserBeam.Transparency = 0.4
laserBeam.Size = Vector3.new(0.05, 0.05, 1)

local targetDot = Instance.new("Part")
targetDot.Name = "TargetDot"
targetDot.Shape = Enum.PartType.Ball
targetDot.Size = Vector3.new(0.3, 0.3, 0.3)
targetDot.Anchored = true
targetDot.CanCollide = false
targetDot.CanQuery = false
targetDot.CanTouch = false
targetDot.Material = Enum.Material.Neon
targetDot.Color = Color3.new(1, 0, 0)
targetDot.Transparency = 0.2

-- GUI 생성 (사격 불가 표시용)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimInterface"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local warningLabel = Instance.new("TextLabel")
warningLabel.Name = "WarningLabel"
warningLabel.Text = "🚫 BLOCKED"
warningLabel.Size = UDim2.new(0, 100, 0, 20)
warningLabel.BackgroundTransparency = 1
warningLabel.TextColor3 = Color3.new(1, 0, 0) -- 빨간 글씨
warningLabel.TextStrokeTransparency = 0 -- 검은 테두리
warningLabel.Font = Enum.Font.GothamBold
warningLabel.TextSize = 14
warningLabel.Visible = false
warningLabel.Parent = screenGui

local function onCharacterAdded(char)
	-- 맵이 로드될 때까지 대기 (고스트 레이저 방지)
	local map = workspace:WaitForChild("Map", 10)
	if not map then
		warn("[AimController] Map not found, skipping aim system")
		return
	end
	
	local humanoid = char:WaitForChild("Humanoid", 10)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then return end
	
	-- 관절 찾기
	local neck = nil
	local waist = nil
	local rSh = nil -- 오른쪽 어깨 (팔 조준용)
	local headPart = nil
	
	-- R15 Check
	local upperTorso = char:WaitForChild("UpperTorso", 2)
	local r15 = false
	if upperTorso then
		r15 = true
		local head = char:WaitForChild("Head", 2)
		headPart = head
		neck = head and head:WaitForChild("Neck", 2)
		waist = upperTorso and upperTorso:WaitForChild("Waist", 2)
		
		-- R15 오른쪽 어깨
		local rUpperArm = char:WaitForChild("RightUpperArm", 2)
		if rUpperArm then rSh = rUpperArm:WaitForChild("RightShoulder", 2) end
	else
		-- R6 Check
		local head = char:WaitForChild("Head", 2)
		headPart = head
		local torso = char:WaitForChild("Torso", 2)
		neck = torso and torso:WaitForChild("Neck", 2)
		waist = root:WaitForChild("RootJoint", 2)
		
		-- R6 오른쪽 어깨
		rSh = torso:WaitForChild("Right Shoulder", 2)
	end
	
	if not neck then return end
	
	local neckC0 = neck.C0
	local waistC0 = (waist and waist.C0) or CFrame.new()
	local rShC0 = (rSh and rSh.C0) or CFrame.new()
	
	RunService:BindToRenderStep("AimController", Enum.RenderPriority.Camera.Value + 1, function()
		if not char.Parent or humanoid.Health <= 0 then 
			RunService:UnbindFromRenderStep("AimController")
			laserBeam.Parent = nil
			targetDot.Parent = nil
			warningLabel:Destroy() -- 라벨도 삭제
			return 
		end
		
		local hitPos = mouse.Hit.Position
		local isProne = char:GetAttribute("IsProne") == true
		
		-- 1. 레이저 사이트 업데이트
		laserBeam.Parent = visualFolder
		targetDot.Parent = visualFolder
		targetDot.Position = hitPos
		
		-- 1. 레이저 사이트 업데이트
		laserBeam.Parent = visualFolder
		targetDot.Parent = visualFolder
		targetDot.Position = hitPos
		
		-- [수정] 레이저 시작점을 Head가 아닌 총구(Muzzle)로 변경
		local startPos = headPart.Position -- 기본값 (무기 없으면 눈에서)
		
		local tool = char:FindFirstChildWhichIsA("Tool")
		if tool then
			local handle = tool:FindFirstChild("Handle")
			if handle then
				local muzzle = handle:FindFirstChild("Muzzle")
				if muzzle then
					startPos = muzzle.WorldPosition
				else
					-- Muzzle이 없으면 핸들에서 약간 앞으로
					startPos = (handle.CFrame * CFrame.new(0, 0, -1)).Position 
				end
			end
		end
		
		local distance = (hitPos - startPos).Magnitude
		laserBeam.Size = Vector3.new(0.05, 0.05, distance)
		laserBeam.CFrame = CFrame.new(startPos, hitPos) * CFrame.new(0, 0, -distance/2)
		
		-- 3. 사격 가능 여부 판단
		local toTarget = (hitPos - root.Position).Unit
		local forward = root.CFrame.LookVector
		local dot = forward:Dot(toTarget)
		
		-- 엎드렸을 때(Prone)는 앞을 보기 힘드므로 각도 제한이 다를 수 있음
		-- 하지만 일단 동일하게 적용 (엎드려서도 90도 좌우는 가능하다고 가정)
		local minDot = isProne and 0.2 or -0.1 -- 엎드리면 뒤는 절대 못 봄 (좀 더 빡빡하게 0.2)
		local isAimingValid = dot > minDot
		
		char:SetAttribute("CanShoot", isAimingValid)
		
		-- 시각 효과 업데이트
		if isAimingValid then
			-- 정상
			laserBeam.Color = Color3.new(1, 0, 0) 
			laserBeam.Transparency = 0.4
			
			targetDot.Color = Color3.new(1, 0, 0)
			targetDot.Transparency = 0.2
			
			warningLabel.Visible = false
		else
			-- 불가
			laserBeam.Color = Color3.new(0.5, 0.5, 0.5) 
			laserBeam.Transparency = 0.8
			
			targetDot.Color = Color3.new(0, 0, 0)
			targetDot.Transparency = 0.5
			
			warningLabel.Visible = true
			warningLabel.Position = UDim2.new(0, mouse.X + 15, 0, mouse.Y + 15)
		end
		
		-- 2. 상체 회전 (IK - LookAt)
		local rootCF = root.CFrame
		local offset = rootCF:PointToObjectSpace(hitPos)
		
		local totalPitch = math.atan2(offset.Y, -offset.Z)
		local totalYaw = math.atan2(offset.X, -offset.Z)
		
		-- [수정] 엎드리기 보정
		if isProne then
			-- 엎드리면 몸이 -90도(앞으로) 쏠려있음.
			-- 앞을 보려면 고개를 +90도 들어야 함.
			-- AimController는 서 있는 기준 Pitch를 계산하므로, 여기에 보정값을 더해줘야 함.
			totalPitch = totalPitch + math.rad(80) -- 90도까지는 아니고 80도 정도 보정
			
			-- 엎드렸을 때는 Pitch 제한도 다름 (땅 밑으로는 못 봄)
			-- 상한을 2.2(약 125도)까지 늘려서 위쪽을 더 볼 수 있게 함
			totalPitch = math.clamp(totalPitch, -0.5, 2.2) 
		else
			totalPitch = math.clamp(totalPitch, -1.5, 1.5)
		end
		
		totalYaw = math.clamp(totalYaw, -1.4, 1.4) 			
		
		if r15 and upperTorso then
			-- 1) 허리(Waist) 배분
			local waistYaw = 0
			local waistPitch = 0
			
			if isProne then
				-- 엎드렸을 때는 허리를 좌우로 돌리면 몸이 꼬임 (Yaw = 0)
				-- 하지만 상하(Pitch)는 허용해야 고개를 들 수 있음 (User Feedback)
				waistYaw = 0
				
				-- 엎드렸을 때는 허리 Pitch 제한을 좀 더 유연하게
				-- 엎드린 상태에서 Pitch는 등을 젖히는 동작
				-- [수정] 최소값을 양수(0.4)로 두어 항상 약간 젖힌 자세 유지 (땅 파묻힘 방지)
				waistPitch = math.clamp(totalPitch * 0.5, 0.4, 1.4) 
			else
				-- 서 있을 때: 기존 로직
				waistYaw = math.clamp(totalYaw * 0.6, -0.7, 0.7)
				
				-- 뒤쪽 보기 방지
				local maxWaistPitch = 0.7
				if isAimingValid == false or dot < 0.5 then
					maxWaistPitch = 0.1 
				end
				
				waistPitch = math.clamp(totalPitch * 0.6, -0.6, maxWaistPitch)
			end
			
			-- ... (나머지 로직은 그대로)
			
			-- 2) 목(Neck) 배분
			-- 나머지를 목이 담당 (Total - Waist)
			local neckYaw = math.clamp(totalYaw - waistYaw, -1.4, 1.4) -- 목은 좌우 80도까지 가능
			local neckPitch = math.clamp(totalPitch - waistPitch, -1.0, 1.0)
			
			-- 허리 적용 (-yaw 부호 유지)
			if waist then
				local targetWaist = waistC0 * CFrame.Angles(waistPitch, -waistYaw, 0)
				waist.C0 = waist.C0:Lerp(targetWaist, 0.3)
			end
			
			-- 목 적용 (-yaw 부호 유지)
			local targetNeck = neckC0 * CFrame.Angles(neckPitch, -neckYaw, 0)
			neck.C0 = neck.C0:Lerp(targetNeck, 0.3)
			
			-- 팔 보정
			if rSh then
				-- [수정] Over-rotation 해결
				-- 팔은 UpperTorso에 붙어있으므로, Waist가 회전한 만큼 이미 회전되어 있음.
				-- 따라서 팔은 (전체 필요 각도 - Waist가 해준 각도)만큼만 더 돌면 됨.
				
				local armPitch = (totalPitch - waistPitch) 
				local armYaw = (totalYaw - waistYaw) * 1.5 -- 팔 가동범위 증폭을 위해 계수 유지하되 기본 로직은 차감
				-- 다만 armYaw가 단순히 차감만 하면 몸통 범위 내에서는 0이 되어 팔이 뻣뻣해 보일 수 있음.
				-- 하지만 정확도를 위해서는 차감이 맞음. 
				-- 사용자의 "팔도 회전되니깐" 요구를 맞추려면, Waist가 한계에 도달했을 때 팔이 더 움직여야 함.
				-- (Total - Waist) 공식이 정확히 그 역할을 함. (Waist가 멈추면 값이 커짐)
				
				-- 계수 1.5는 팔을 좀 더 과장되게 꺾기 위함이었으나, 정확성을 위해 1.0으로 할지 고민.
				-- 일단 '더 회전되어버린 느낌'을 잡아야 하므로 정직하게 계산.
				armYaw = totalYaw - waistYaw
				armPitch = totalPitch - waistPitch -- Pitch도 동일
				
				-- Y/Z축 동시 적용 (확실한 스윙)
				-- 각도가 작아질 수 있으므로 약간의 보정(1.2배) 정도는 허용
				local targetSh = rShC0 * CFrame.Angles(armPitch, -armYaw, -armYaw)
				rSh.C0 = rSh.C0:Lerp(targetSh, 0.3)
			end
			
		else
			-- R6
			
			-- 1) 허리 배분 (R6는 RootJoint가 허리 역할)
			local waistYaw = math.clamp(totalYaw * 0.5, -0.7, 0.7)
			-- R6 RootJoint Pitch는 전체 몸을 기울이니 조심. 보통 안 쓰는 게 나을 수도 있지만 살짝 적용.
			-- R6 Pitch는 보통 Neck과 Shoulder에서 처리함.
			local waistPitch = 0 
			
			-- 2) 목 배분
			local neckYaw = math.clamp(totalYaw - waistYaw, -1.5, 1.5)
			local neckPitch = math.clamp(totalPitch - waistPitch, -1.2, 1.2) -- Pitch는 목이 다 함
			
			if waist then
				-- R6 RootJoint는 Y축이 회전 아닐 수 있음. 보통 Y축 맞음.
				local targetWaist = waistC0 * CFrame.Angles(0, -waistYaw, 0)
				waist.C0 = waist.C0:Lerp(targetWaist, 0.3)
			end
			
			-- 목 적용
			local targetNeck = neckC0 * CFrame.Angles(neckPitch, -neckYaw, 0) -- Yaw 추가 시도
			-- R6 Neck C0가 CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) 꼴이라 축이 다를 수 있음.
			-- 보통 R6에서 고개를 돌리려면 Y축 회전을 줌.
			if rSh then
				-- R6 팔: Torso가 RootJoint(Waist)에 의해 돌아갔음.
				-- Torso Yaw = waistYaw.
				-- Arm should be Total - Waist.
				local armYaw = totalYaw - waistYaw
				local armPitch = totalPitch -- R6 WaistPitch가 0이므로 Total 그대로 씀
				
				-- R6 어깨도 좌우 회전 추가 (Y, Z 동시 적용)
				local targetSh = rShC0 * CFrame.Angles(armPitch, -armYaw, -armYaw)
				rSh.C0 = rSh.C0:Lerp(targetSh, 0.3)
			end
		end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)
