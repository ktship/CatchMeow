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
	CollectionService:AddTag(model, TRAP_TAG) -- [v4.25o] Tag for AI optimization
	self.PartEnter = model:WaitForChild(PART_ENTER_NAME, 5)
	self.CurrentState = model:GetAttribute("TargetState") or States.IDLE
	self.BaitModel = nil
	
	if not self.PartEnter then return nil end
	
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
	print("[CatTrapHandler] Before PivotTo: Y=" .. tostring(model:GetPivot().Position.Y))
	model:PivotTo(model:GetPivot() * CFrame.new(0, -0.2, 0))
	print("[CatTrapHandler] After PivotTo: Y=" .. tostring(model:GetPivot().Position.Y))
	
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
	
	return self
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
	local sourceItem = assets and assets:FindFirstChild(baitItemId)
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
	local region = Region3.new(trapPos - Vector3.new(10, 5, 10), trapPos + Vector3.new(10, 5, 10))
	local parts = workspace:FindPartsInRegion3(region, nil, 50)
	
	local targetCatModel = nil
	for _, p in ipairs(parts) do
		if p.Name == "Torso" and p.Parent and p.Parent:IsA("Model") then
			local catModel = p.Parent
			if targetCatId and string.find(catModel.Name, string.sub(targetCatId, 1, 4)) then
				targetCatModel = catModel
				break
			end
		end
	end
	
	-- Fallback
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
		
		-- 1. NPC에 상태 부여 (AI가 움직임을 멈추도록 함)
		targetCatModel:SetAttribute("IsTrapped", true)
		
		-- 2. 덫 내부로 위치 조정 및 용접
		-- 덫의 입구 안쪽 살짝 뒤로 배치
		local trapPivot = self.Model:GetPivot()
		local targetCF = trapPivot * CFrame.new(0, -0.2, 0) -- 덫 바닥 중앙 부근
		targetCatModel:PivotTo(targetCF)
		
		-- 용접 (고정)
		local torso = targetCatModel:FindFirstChild("Torso")
		local anchor = self.Model.PrimaryPart or self.PartEnter
		if torso and anchor then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "TrapWeld"
			weld.Part0 = anchor
			weld.Part1 = torso
			weld.Parent = torso
			print("[CatTrap] NPC Welded to Trap.")
		end
		
		-- 3. 덫 상태 변경
		self.Model:SetAttribute("TargetState", States.CATCHED)
		
		-- 4. 미끼 소모
		self.Model:SetAttribute("BaitItem", nil)
		
		-- 5. 가짜 고양이 비주얼 비활성화 (NPC가 들어왔으므로)
		if self.CatModelVisual then
			self:SetModelTransparency(self.CatModelVisual, 1)
		end
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
	if traps[model] then return end
	local trapObj = CatTrap.new(model)
	if trapObj then
		traps[model] = trapObj
		print("[CatTrapManager] Registered new trap: " .. model:GetFullName())
	end
end

-- 기존 덫 등록
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj.Name == TRAP_NAME and obj:IsA("Model") then
		registerTrap(obj)
	end
end

-- 새로 배치되는 덫 등록
workspace.DescendantAdded:Connect(function(obj)
	if obj.Name == TRAP_NAME and obj:IsA("Model") then
		registerTrap(obj)
	end
end)

-- 주기적 업데이트 (고양이 포획 체크)
RunService.Heartbeat:Connect(function()
	for model, trap in pairs(traps) do
		if not model.Parent then
			traps[model] = nil
		else
			trap:Update()
		end
	end
end)

return CatTrap
