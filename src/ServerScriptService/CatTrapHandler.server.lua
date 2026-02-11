-- CatTrapHandler.server.lua
-- CatTrap의 상태(Idle, Setting, Catched)를 관리하고 고양이를 포획하는 시스템입니다.
-- [v4.25l] Multi-trap 지원 및 자동 포획(Capture) 로직 추가

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- 설정
local TRAP_NAME = "CatTrap"
local TRAP_TAG = "CatTrap"
local PART_ENTER_NAME = "PartEnter"
local CAT_MODEL_NAME = "Cat"
local SETTING_Y_HEIGHT = 4

-- 상태 정의
local States = {
	IDLE = "Idle",
	SETTING = "Setting",
	CATCHED = "Catched"
}

--------------------------------------------------------------------------------
-- CatTrap 클래스
--------------------------------------------------------------------------------
local CatTrap = {}
CatTrap.__index = CatTrap

function CatTrap.new(model)
	local self = setmetatable({}, CatTrap)
	self.Model = model
	
	-- [v4.28] 최우선순위: 클릭 회수 기능 먼저 설정 (지연 방지)
	self:SetupInteraction()
	
	CollectionService:AddTag(model, TRAP_TAG) -- [v4.25o] Tag for AI optimization
	self.PartEnter = model:WaitForChild(PART_ENTER_NAME, 5)
	self.CurrentState = model:GetAttribute("TargetState") or States.IDLE
	self.BaitModel = nil
	
	if not self.PartEnter then 
		warn("[CatTrap] Critical error: PartEnter not found! Interaction might work but trap logic will fail.")
		return self -- [v4.28] 그래도 self는 반환해서 Pickup은 되게 함
	end
	
	-- 초기화: PartEnter의 자식들 용접
	for _, child in ipairs(self.PartEnter:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = self.PartEnter
			weld.Part1 = child
			weld.Parent = child
		end
	end
	
	-- [v4.25z] Fix Floating Trap: Lower by 0.2 studs
	-- 사용자가 덫이 살짝 떠있다고 제보하여 강제로 0.2스터드 내림
	-- print("[CatTrapHandler] Before PivotTo: Y=" .. tostring(model:GetPivot().Position.Y))
	model:PivotTo(model:GetPivot() * CFrame.new(0, -0.2, 0))
	-- print("[CatTrapHandler] After PivotTo: Y=" .. tostring(model:GetPivot().Position.Y))
	
	-- 상대 좌표 저장 (위치 조정 후 저장해야 정확함)
	local modelPivot = model:GetPivot()
	self.PartEnterOffset = modelPivot:Inverse() * self.PartEnter.CFrame
	
	-- 비주얼: 고양이 모델
	self.CatModelVisual = model:FindFirstChild(CAT_MODEL_NAME)
	if self.CatModelVisual then
		for _, desc in ipairs(self.CatModelVisual:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.CanCollide = false
				desc.CanQuery = false -- [v4.25t] Raycast 무시 (AI가 장애물로 인식하지 않게)
				desc.CanTouch = false
				desc.Anchored = true
			end
		end
	end
	
	-- [v4.25u] Enforce collision on structure (Walls, Floor, etc.)
	-- This ensures AI Raycast detects the walls as obstacles
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			-- Exclude Special Parts
			local isVisual = (self.CatModelVisual and desc:IsDescendantOf(self.CatModelVisual))
			local isEnter = (self.PartEnter and (desc == self.PartEnter or desc:IsDescendantOf(self.PartEnter)))
			local isHumanoidRootPart = (desc.Name == "HumanoidRootPart")
			
			-- [v4.25x] Internal Triggers (발판, 미끼)는 물리적 충돌 제거
			local isTrigger = (desc.Name == "PartCatch" or desc.Name == "BaitPoint" or desc.Name == "Trigger" or desc.Name == "TrapFloor")
			
			if not isVisual and not isEnter and not isHumanoidRootPart and not isTrigger then
				desc.CanCollide = true
				desc.CanQuery = true
				
				-- [v4.25x] Ensure hollow parts are not treated as solid blocks
				if desc:IsA("MeshPart") then
					desc.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
				end
			elseif isTrigger then
				-- 발판 등은 밟아도 걸리지 않게 통과 처리
				desc.CanCollide = false
				desc.CanQuery = false
				desc.CanTouch = true
			end
		end
	end

	-- 초기 상태 적용 (Attribute와 동기화)
	self:ApplyState(self.CurrentState)
	
	-- 미끼 있으면 초기화
	local initialBait = model:GetAttribute("BaitItem")
	if initialBait then
		self:AddBaitVisual(initialBait)
	end
	
	-- 디버그 프롬프트
	self:CreateDebugPrompt()
	
	-- 속성 변경 감지
	model:GetAttributeChangedSignal("TargetState"):Connect(function()
		local target = model:GetAttribute("TargetState")
		if target and target ~= self.CurrentState then
			self:ApplyState(target)
		end
	end)
	
	model:GetAttributeChangedSignal("BaitItem"):Connect(function()
		local bait = model:GetAttribute("BaitItem")
		if bait then
			self:AddBaitVisual(bait)
			model:SetAttribute("IsFood", true) -- [v4.25m] AI가 음식을 찾을 수 있게 태그 추가
		else
			if self.BaitModel then
				self.BaitModel:Destroy()
				self.BaitModel = nil
			end
			model:SetAttribute("IsFood", nil) -- 미끼 없으면 태그 제거
		end
	end)

	-- [v4.25m] 고양이 AI로부터의 포획 신호 감지 (다 먹었을 때)
	model:GetAttributeChangedSignal("CaptureSignal"):Connect(function()
		local catId = model:GetAttribute("CaptureSignal")
		if catId and self.CurrentState == States.SETTING then
			print("[CatTrap] CAPTURE SIGNAL RECEIVED: " .. tostring(catId))
			self:PerformCapture(catId)
			model:SetAttribute("CaptureSignal", nil) -- 신호 리셋
		end
	end)

	-- [v4.28] 초기 상태 결정 (설치 시 설정된 상태가 있으면 존중, 없으면 IDLE)
	local startState = model:GetAttribute("TargetState") or States.IDLE
	self:ApplyState(startState)
	model:SetAttribute("TargetState", startState)
	model:SetAttribute("BaitItem", nil)
	model:SetAttribute("CaptureSignal", nil)

	-- [v4.28] Click to Pickup (Bungeoppang Style)
	self.IsPickingUp = false -- [v4.28] 중복 회수 방지용 데드락/데분스
	self:SetupInteraction()
	
	-- print("[CatTrap] New trap object created and initialized to IDLE for: " .. model:GetFullName())
	return self
end

function CatTrap:SetupInteraction()
	local model = self.Model
	
	-- [v4.28] 클릭 가능한 부품들 정의 (정적 파트들 위주)
	local candidates = {"Wall", "Body", "TrapFloor", "Center", "Floor", "Frame", "Base"}
	local setupCount = 0

	local function applyInteraction(part)
		if not part or not part:IsA("BasePart") then return end
		-- [v4.28] 모든 파트 클릭 허용 (문 포함)
		-- if part.Name == "PartEnter" then return end -- 이전 제외 로직 제거

		-- 클릭 가능하게 속성 강제 조정 (매우 중요)
		part.CanQuery = true
		part.CanTouch = true
		if part.Transparency == 1 then part.Transparency = 0.99 end
		
		-- [Fix] 기존 PickupDetector가 있으면 일단 제거 (신선한 연결을 위해)
		local old = part:FindFirstChild("PickupDetector")
		if old then old:Destroy() end

		-- ClickDetector 추가
		local cd = Instance.new("ClickDetector")
		cd.Name = "PickupDetector"
		cd.MaxActivationDistance = 32 -- [v4.28] 거리 상향 (20 -> 32)
		cd.Parent = part
		
		-- 클릭 이벤트 연결
		cd.MouseClick:Connect(function(player)
			-- print("[CatTrap] MouseClick detected on " .. part.Name .. " by " .. player.Name)
			self:Pickup(player)
		end)
		setupCount = setupCount + 1
	end

	-- 1. [v4.29] 모든 BasePart에 전부 ClickDetector 설치 (이름 무관)
	-- 기존 코드는 FindFirstChild로 하나씩만 찾아서 나머지 벽/바닥이 클릭 안되는 문제 발생
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			-- 이름 필터링 (필요하다면 여기서 제외)
			-- if desc.Name == "PartEnter" then ... end -- (이제 포함함)
			applyInteraction(desc)
		end
	end

	-- 2. Highlight 추가 (호버 피드백)
	local hl = model:FindFirstChild("PickupHighlight") or Instance.new("Highlight")
	hl.Name = "PickupHighlight"
	hl.FillTransparency = 0.7 -- 살짝 채워서 더 눈에 띄게
	hl.OutlineTransparency = 0
	hl.OutlineColor = Color3.fromRGB(255, 220, 0) -- 더 밝은 노란색
	hl.FillColor = Color3.fromRGB(255, 255, 100)
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = model
	hl.Enabled = false
	hl.Parent = model

	-- 하이라이트 제어 (모든 파트의 ClickDetector에 연결)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("ClickDetector") and desc.Name == "PickupDetector" then
			desc.MouseHoverEnter:Connect(function() hl.Enabled = true end)
			desc.MouseHoverLeave:Connect(function() hl.Enabled = false end)
		end
	end
	
	-- print("[CatTrap] SetupInteraction complete. Detectors created: " .. setupCount)
end

function CatTrap:Pickup(player)
	if self.IsPickingUp then return end -- 이미 회수 중이면 종료
	self.IsPickingUp = true
	
	-- print("[CatTrap] Pickup requested by " .. player.Name .. " for model: " .. self.Model:GetFullName())
	-- [v4.28] 더 넓은 범위에서 고양이 탐색 및 해제
	local trapPivot = self.Model:GetPivot()
	local region = Region3.new(trapPivot.Position - Vector3.new(5, 5, 5), trapPivot.Position + Vector3.new(5, 5, 5))
	local parts = workspace:FindPartsInRegion3(region, nil, 50)
	
	for _, p in ipairs(parts) do
		if p.Parent and p.Parent:IsA("Model") and p.Parent:GetAttribute("IsTrapped") then
			-- print("[CatTrap] Releasing cat: " .. p.Parent.Name)
			p.Parent:SetAttribute("IsTrapped", false)
			
			local weld = p.Parent:FindFirstChild("TrapWeld", true)
			if weld then weld:Destroy() end
		end
	end

	-- 2. 미끼 제거
	self.Model:SetAttribute("BaitItem", nil)
	
	-- 3. 인벤토리 추가
	if _G.InventoryManager and _G.InventoryManager.AddItem then
		local success = _G.InventoryManager.AddItem(player, "CatTrap", 1)
		if success then
			-- 4. 덫 제거 (traps 테이블에서도 제거될 것임 - Heartbeat)
			-- print("[CatTrap] Successfully returned to inventory. Destroying model.")
			self.Model:Destroy()
		else
			warn("[CatTrap] Failed to add trap to inventory for " .. player.Name)
		end
	else
		warn("[CatTrap] InventoryManager.AddItem not found! Cannot pickup.")
	end
end

function CatTrap:SetModelTransparency(model, transparency)
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") or child:IsA("Decal") then
			child.Transparency = transparency
		end
	end
end

function CatTrap:ApplyState(newState)
	self.CurrentState = newState
	local currentPivot = self.Model:GetPivot()
	
	if newState == States.IDLE then
		if self.PartEnter then
			self.PartEnter.CFrame = currentPivot * self.PartEnterOffset
			self.PartEnter.Transparency = 0
			self.PartEnter.CanCollide = true -- 닫히면 충돌 활성
		end
		if self.CatModelVisual then self:SetModelTransparency(self.CatModelVisual, 1) end
		
	elseif newState == States.SETTING then
		if self.PartEnter then
			self.PartEnter.CFrame = currentPivot * self.PartEnterOffset * CFrame.new(0, SETTING_Y_HEIGHT, 0)
			self.PartEnter.CanCollide = false -- [v4.25n] 열려 있을 때는 충돌 무시 (고양이 진기 방지)
		end
		if self.CatModelVisual then self:SetModelTransparency(self.CatModelVisual, 1) end
		
	elseif newState == States.CATCHED then
		if self.PartEnter then
			self.PartEnter.CFrame = currentPivot * self.PartEnterOffset
			self.PartEnter.CanCollide = true -- 포획 시 문 닫히며 충돌 활성
		end
		-- [v4.25q] 실제 NPC가 가둬져 있다면 가짜 비주얼은 숨김
		local hasRealCat = false
		local torso = self.Model:FindFirstChild("Torso") -- PerformCapture에서 이동시킨 파트
		if torso and torso:FindFirstChild("TrapWeld") then
			hasRealCat = true
		end
		
		if self.CatModelVisual then 
			self:SetModelTransparency(self.CatModelVisual, hasRealCat and 1 or 0) 
		end
	end
end

function CatTrap:CreateDebugPrompt()
	local promptPart = self.Model.PrimaryPart or self.PartEnter
	if not promptPart then return end
	
	local prompt = promptPart:FindFirstChildWhichIsA("ProximityPrompt") or Instance.new("ProximityPrompt")
	prompt.ObjectText = "Cat Trap"
	prompt.ActionText = "Toggle State"
	prompt.MaxActivationDistance = 15
	prompt.Enabled = false
	prompt.Parent = promptPart
	
	prompt.Triggered:Connect(function()
		if self.CurrentState == States.IDLE then
			self.Model:SetAttribute("TargetState", States.SETTING)
		elseif self.CurrentState == States.SETTING then
			self.Model:SetAttribute("TargetState", States.CATCHED)
		else
			self.Model:SetAttribute("TargetState", States.IDLE)
		end
	end)
end

function CatTrap:AddBaitVisual(baitItemId)
	if self.BaitModel then self.BaitModel:Destroy() end
	
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local items = ReplicatedStorage:FindFirstChild("Items")
	
	local sourceItem = (items and items:FindFirstChild(baitItemId)) or (assets and assets:FindFirstChild(baitItemId))
	local baitPart = nil
	
	if sourceItem then
		if sourceItem:IsA("Model") then baitPart = sourceItem:Clone()
		elseif sourceItem:IsA("BasePart") then baitPart = sourceItem:Clone()
		elseif sourceItem:IsA("Accessory") then
			local handle = sourceItem:FindFirstChild("Handle")
			if handle then
				baitPart = handle:Clone()
				baitPart:ClearAllChildren()
			end
		end
	end
	
	if not baitPart then
		baitPart = Instance.new("Part")
		baitPart.Size = Vector3.new(1, 0.5, 1)
		baitPart.Color = Color3.fromRGB(255, 170, 0)
		baitPart.Material = Enum.Material.Food
	end
	
	local currentPivot = self.Model:GetPivot()
	local targetCFrame = nil
	
	if baitItemId == "Bungeoppang" then
		local scale = 2.5
		if baitPart:IsA("BasePart") then baitPart.Size *= scale end
		local mesh = baitPart:FindFirstChildOfClass("SpecialMesh")
		if mesh then mesh.Scale *= scale end
		targetCFrame = currentPivot * CFrame.new(-2.5, -1.6, 0) * CFrame.Angles(math.rad(40.9), math.rad(-175.1), math.rad(10.4))
	else
		targetCFrame = currentPivot * CFrame.new(0, -0.5, 0)
	end
	
	if baitPart:IsA("Model") then baitPart:PivotTo(targetCFrame) else baitPart.CFrame = targetCFrame end
	baitPart.Anchored = false
	baitPart.CanCollide = false
	baitPart.Parent = self.Model
	
	local anchor = self.Model.PrimaryPart or self.PartEnter
	if anchor then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = anchor
		weld.Part1 = (baitPart:IsA("Model") and baitPart.PrimaryPart) or baitPart
		weld.Parent = baitPart
	end
	self.BaitModel = baitPart
end

-- [v4.25q] 덫 안의 고양이 NPC를 찾아 포획 (파괴하지 않고 가둠)
function CatTrap:PerformCapture(targetCatId)
	local trapPos = self.Model:GetPivot().Position
	-- [v4.28] 범위를 살짝 넓히고 더 견고한 탐색
	local region = Region3.new(trapPos - Vector3.new(12, 6, 12), trapPos + Vector3.new(12, 6, 12))
	local parts = workspace:FindPartsInRegion3(region, nil, 100)
	
	local targetCatModel = nil
	for _, p in ipairs(parts) do
		if p.Name == "Torso" and p.Parent and p.Parent:IsA("Model") then
			local catModel = p.Parent
			-- [v4.28] Name 또는 ID 매칭 (앞부분 4자기 매칭)
			if targetCatId and (string.find(catModel.Name, string.sub(targetCatId, 1, 4)) or catModel:GetAttribute("RefID") == targetCatId) then
				targetCatModel = catModel
				break
			end
		end
	end
	
	-- Fallback: 그냥 근처에 있는 고양이 아무나
	if not targetCatModel then
		for _, p in ipairs(parts) do
			if p.Name == "Torso" and p.Parent and p.Parent:IsA("Model") then
				local catModel = p.Parent
				if string.match(catModel.Name, "^Cat_") then
					targetCatModel = catModel
					break
				end
			end
		end
	end

	if targetCatModel then
		print("[CatTrap] CAPTURING NPC (LIVE): " .. targetCatModel.Name)
		
		-- 1. NPC에 상태 부여
		targetCatModel:SetAttribute("IsTrapped", true)
		
		-- 2. 덫 내부로 위치 조정 및 용접
		local trapPivot = self.Model:GetPivot()
		local targetCF = trapPivot * CFrame.new(0, -0.2, 0)
		targetCatModel:PivotTo(targetCF)
		
		-- 용접
		local torso = targetCatModel:FindFirstChild("Torso")
		local anchor = self.Model.PrimaryPart or self.PartEnter
		if torso and anchor then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "TrapWeld"
			weld.Part0 = anchor
			weld.Part1 = torso
			weld.Parent = torso
			-- print("[CatTrap] NPC Welded to Trap.")
		end
		
		-- [호버 하이라이트 수정] 포획된 고양이가 ClickDetector를 가리지 않도록
		for _, desc in ipairs(targetCatModel:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.CanQuery = false
			end
		end
	else
		warn("[CatTrap] Capture Signal received but NO CAT FOUND in region! Closing trap anyway.")
	end

	-- [v4.28] CRITICAL: 고양이를 찾았든 못 찾았든 덫은 무조건 닫고 미끼는 제거한다.
	-- (고양이가 이미 사라졌거나 렉으로 못 찾은 경우에도 덫이 열려있어서 생기는 버그 방지)
	
	-- 3. 덫 상태 변경 (CATCHED로 변경하여 문을 닫음)
	self.Model:SetAttribute("TargetState", States.CATCHED)
	self:ApplyState(States.CATCHED) -- 즉시 적용 강제
	
	-- 4. 미끼 소모
	self.Model:SetAttribute("BaitItem", nil)
	
	-- 5. 가짜 고양이 비주얼 비활성화 
	if self.CatModelVisual then
		self:SetModelTransparency(self.CatModelVisual, targetCatModel and 1 or 0)
	end
end

-- [v4.25m] 주기적 업데이트 (고장 방지용 Fallback 포획도 유지 가능)
function CatTrap:Update()
	-- 현재는 CaptureSignal 위주로 동작하므로 특별한 주기적 로직은 필요 없음
	-- (추후 근처에 고양이가 오래 머물면 강제 포획하는 등의 로직 추가 가능)
end

--------------------------------------------------------------------------------
-- Manager 로직
--------------------------------------------------------------------------------
local traps = {}

local function registerTrap(model)
	if not model or not model.Parent then return end
	if not model:IsDescendantOf(workspace) then return end 
	
	-- [v4.28] 중복 등록 원천 차단 (Atomic check)
	if traps[model] then return end
	
	-- 임시 마커 삽입 (Yield 하기 전에 선점)
	traps[model] = "PENDING"
	
	-- print("[CatTrapManager] Registering trap: " .. model:GetFullName())
	local trapObj = CatTrap.new(model)
	
	if trapObj then
		traps[model] = trapObj
		-- print("[CatTrapManager] SUCCESS: Trap registered.")
	else
		traps[model] = nil -- 실패 시 마커 제거
		warn("[CatTrapManager] FAILED: Could not create trap object for " .. model.Name)
	end
end

-- 기존 덫 등록
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj.Name == TRAP_NAME and obj:IsA("Model") then
		registerTrap(obj)
	end
end

-- 새로 배치되는 덫 등록 (CollectionService + ChildAdded 이중 감지로 안정성 극대화)
CollectionService:GetInstanceAddedSignal(TRAP_TAG):Connect(registerTrap)

workspace.ChildAdded:Connect(function(obj)
	if obj.Name == TRAP_NAME and obj:IsA("Model") then
		task.delay(0.1, function()
			registerTrap(obj)
		end)
	end
end)

-- 이미 태그가 붙어있는 경우 (서버 시작 시)
for _, obj in ipairs(CollectionService:GetTagged(TRAP_TAG)) do
	registerTrap(obj)
end

-- 주기적 업데이트 (고양이 포획 체크)
RunService.Heartbeat:Connect(function()
	for model, trap in pairs(traps) do
		-- [v4.28] Workspace에 있을 때만 업데이트 및 유지
		if not model.Parent or not model:IsDescendantOf(workspace) then
			-- [v4.28] Assets 폴더로 이동된 원본은 추적 목록에서 제외 (복제용으로만 사용)
			traps[model] = nil
			-- print("[CatTrapManager] Unregistered trap (Moved or Destroyed): " .. model.Name)
		else
			trap:Update()
		end
	end
end)

return CatTrap
