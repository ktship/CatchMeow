-- CatTrapHandler.server.lua
-- CatTrap의 상태(Idle, Setting, Catched)를 관리하는 스크립트입니다.
-- Workspace에 "CatTrap"이라는 이름의 모델이 있어야 하며, 그 안에 "PartEnter"라는 파트가 있어야 합니다.
-- "Cat"이라는 자식이 있으면 Catched 상태에서 보이게 됩니다.

local Workspace = game:GetService("Workspace")

-- 설정
local TRAP_NAME = "CatTrap"
local PART_ENTER_NAME = "PartEnter"
local CAT_MODEL_NAME = "Cat"
local SETTING_Y_HEIGHT = 4 -- [Reset] 높이 4로 복구 (사용자 요청)

-- 상태 정의
local States = {
	IDLE = "Idle",
	SETTING = "Setting",
	CATCHED = "Catched"
}

local CatTrapHandler = {}
CatTrapHandler.CurrentState = States.IDLE

-- 덫 찾기 (없으면 기다림)
function CatTrapHandler:Initialize()
	self.TrapModel = Workspace:WaitForChild(TRAP_NAME, 10)
	
	if not self.TrapModel then
		warn("[CatTrapHandler] '" .. TRAP_NAME .. "' 모델을 Workspace에서 찾을 수 없습니다. 스크립트 대기 중...")
		self.TrapModel = Workspace:WaitForChild(TRAP_NAME) -- 무한 대기
	end
	
	self.PartEnter = self.TrapModel:WaitForChild(PART_ENTER_NAME, 10)
	if not self.PartEnter then
		warn("[CatTrapHandler] '" .. TRAP_NAME .. "' 모델 안에 '" .. PART_ENTER_NAME .. "' 파트가 없습니다.")
		return
	end
	
	-- [Fix] PartEnter의 자식 파트들을 PartEnter에 용접(Weld)하여 같이 움직이게 함
	-- Roblox에서는 단순히 자식이라고 해서 같이 움직이지 않음 (물리적 연결 필요)
	for _, child in ipairs(self.PartEnter:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = self.PartEnter
			weld.Part1 = child
			weld.Parent = child
		end
	end
	
	-- 원래 위치 저장 (Idle/Catched 상태 복귀용) - 상대 좌표 사용
	-- [Fix] Pivot(모델 중심) 기준으로 PartEnter의 상대 위치 저장
	-- 그래야 설치 후 위치가 바뀌어도 제대로 동작함
	self.ModelPivot = self.TrapModel:GetPivot()
	self.PartEnterOffset = self.ModelPivot:Inverse() * self.PartEnter.CFrame
	
	-- 고양이 모델 (선택 사항)
	self.CatModel = self.TrapModel:FindFirstChild(CAT_MODEL_NAME)
	
	-- 테스트용 ProximityPrompt 생성
	self:CreateDebugPrompt()
	
	-- 초기 상태 설정
	self:SetState(States.IDLE)
end

function CatTrapHandler:SetState(newState)
	print("[CatTrapHandler] 상태 변경: " .. self.CurrentState .. " -> " .. newState)
	self.CurrentState = newState
	
	-- 현재 모델 위치 (Pivot) 가져오기
	local currentPivot = self.TrapModel:GetPivot()
	
	if newState == States.IDLE then
		-- Idle: 일반 상태
		-- PartEnter 복귀
		if self.PartEnter then
			self.PartEnter.CFrame = currentPivot * self.PartEnterOffset
			self.PartEnter.Transparency = 0
			self.PartEnter.CanCollide = true
		end
		-- 고양이 숨김
		if self.CatModel then
			self:SetModelTransparency(self.CatModel, 1) -- 투명하게
		end
		
	elseif newState == States.SETTING then
		-- Setting: 설치 중/준비 상태
		-- PartEnter 위로 올림 (Y = 4)
		if self.PartEnter then
			-- Pivot 기준, Offset 적용 + Y축 4 이동 (Local)
			-- 만약 World Y=4를 원했다면 다르게 짜야겠지만, 보통 "올린다"는 의미
			local targetCFrame = currentPivot * self.PartEnterOffset * CFrame.new(0, SETTING_Y_HEIGHT, 0)
			self.PartEnter.CFrame = targetCFrame
		end
		-- 고양이 숨김 (혹시 모르니)
		if self.CatModel then
			self:SetModelTransparency(self.CatModel, 1)
		end
		
	elseif newState == States.CATCHED then
		-- Catched: 잡힌 상태
		-- PartEnter 복귀 (닫힘)
		if self.PartEnter then
			self.PartEnter.CFrame = currentPivot * self.PartEnterOffset
		end
		-- 고양이 보임
		if self.CatModel then
			self:SetModelTransparency(self.CatModel, 0) -- 보이게
		else
			warn("[CatTrapHandler] Catched 상태이지만 '" .. CAT_MODEL_NAME .. "' 모델이 없습니다.")
		end
	end
end

-- 모델 투명도 조절 헬퍼 함수
function CatTrapHandler:SetModelTransparency(model, transparency)
	if model:IsA("BasePart") then
		model.Transparency = transparency
	elseif model:IsA("Model") or model:IsA("Folder") then
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("BasePart") or child:IsA("Decal") then
				child.Transparency = transparency
			end
		end
	end
end

-- 디버깅용 상호작용 (User Verification)
function CatTrapHandler:CreateDebugPrompt()
	local promptPart = self.TrapModel.PrimaryPart or self.PartEnter
	
	if not promptPart then
		warn("[CatTrapHandler] ProximityPrompt를 붙일 파트가 없습니다!")
		return
	end
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Cat Trap"
	prompt.ActionText = "Toggle State"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 20 -- 거리 증가
	prompt.RequiresLineOfSight = false -- 벽 뒤에서도 보이게
	prompt.Enabled = false -- [Fix] 기본 비활성화 (설치 후 InventoryManager에서 활성화)
	prompt.Parent = promptPart
	
	-- print("[CatTrapHandler] '" .. promptPart.Name .. "'에 ProximityPrompt 생성 완료.")
	
	prompt.Triggered:Connect(function()
		-- print("[CatTrapHandler] E키 눌림! 상태 변경 시도 중...")
		if self.CurrentState == States.IDLE then
			self:SetState(States.SETTING)
		elseif self.CurrentState == States.SETTING then
			self:SetState(States.CATCHED)
		else
			self:SetState(States.IDLE)
		end
	end)
end

-- 실행
task.spawn(function()
	-- print("[CatTrapHandler] 스크립트 시작됨. CatTrap 찾는 중...")
	CatTrapHandler:Initialize()
	
	-- [New] Attribute 기반 상태 변경 감지 (InventoryManager에서 제어)
	if CatTrapHandler.TrapModel then
		CatTrapHandler.TrapModel:GetAttributeChangedSignal("TargetState"):Connect(function()
			local targetState = CatTrapHandler.TrapModel:GetAttribute("TargetState")
			if targetState and States[string.upper(targetState)] then
				CatTrapHandler:SetState(targetState)
			end
		end)
	end
end)

return CatTrapHandler
