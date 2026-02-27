-- InventoryUI.client.lua
-- 인벤토리 UI (별도 창 + 토글 버튼 + 아이템 사용 모드)
-- StarterGui에 위치
-- [v4.23s] Preview Debug Mode (Green)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local events = ReplicatedStorage:WaitForChild("Events")
local updateEvent = events:WaitForChild("UpdateInventory")
local useEvent = events:WaitForChild("UseItem")

local placeEvent = events:WaitForChild("PlaceItem", 10)
if not placeEvent then
	warn("[InventoryUI] PlaceItem RemoteEvent not found!")
end

local requestUpdateEvent = events:WaitForChild("RequestInventoryUpdate")

local inventory = {} -- 로컬 캐시
local isUseMode = false -- 아이템 사용 모드
local selectedSlot = nil -- 선택된 슬롯 인덱스
local isOpen = false -- [인벤토리 열림 상태]
local canPlace = true -- [충돌 감지] 설치 가능 여부

-- UI 생성
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true -- [Added] Roblox 상단바 (TopBar) 무시하고 화면 전체에 딱 맞춤
screenGui.Parent = playerGui

-- [Theme Colors] Sunny Orange (QuestUI와 통일)
local Colors = {
	Primary = Color3.fromRGB(255, 170, 0), -- 진한 오렌지 (헤더, 강조)
	Background = Color3.fromRGB(245, 240, 230), -- [Modified] 조금 더 진한 크림색
	Card = Color3.fromRGB(255, 255, 255), -- 흰색 (카드, 슬롯)
	Stroke = Color3.fromRGB(254, 230, 133), -- [Modified] 사용자 요청 테두리색
	TextTitle = Color3.new(1, 1, 1), -- 헤더 타이틀 (흰색)
	TextBody = Color3.fromRGB(140, 100, 80), -- 중간 갈색
	TextHighlight = Color3.fromRGB(255, 140, 0), -- 오렌지 텍스트
	CloseBtn = Color3.fromRGB(255, 255, 255), -- 닫기 버튼
}

-- 인벤토리 버튼 (우측 중단)
-- 인벤토리 버튼 (우측 중단)
local invButton = Instance.new("TextButton")
invButton.Name = "InventoryButton"
invButton.Size = UDim2.new(0, 50, 0, 50) 
invButton.Position = UDim2.new(0, 90, 1, -20) 
invButton.AnchorPoint = Vector2.new(0, 1) 
invButton.BackgroundColor3 = Color3.fromRGB(255, 220, 100) -- [Modified] 더 밝게 (Bright Yellow-Orange)
invButton.Text = "🎒" 
invButton.TextSize = 35 -- [Modified] 아이콘 크기 확대 (25 -> 35)
invButton.Font = Enum.Font.GothamBold
invButton.AutoButtonColor = true
invButton.Parent = screenGui

local btnStroke = Instance.new("UIStroke") 
btnStroke.Thickness = 3 -- [Modified] 더 두껍게
btnStroke.Color = Color3.fromRGB(160, 90, 50) -- [Modified] 적당히 진한 갈색 (너무 어둡지 않게)
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- [Added] 테두리 모드 명시
btnStroke.Parent = invButton

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = invButton

-- 메인 프레임 (투명 컨테이너)
local invWindow = Instance.new("Frame")
invWindow.Name = "InventoryWindow"
invWindow.Size = UDim2.new(0, 320, 1, -180) -- [Modified] 위아래 90px씩 여백 (총 180px 제외)
invWindow.Position = UDim2.new(0.5, 0, 0.5, 0) -- [Modified] 정중앙 배치
invWindow.AnchorPoint = Vector2.new(0.5, 0.5)
invWindow.BackgroundTransparency = 1
invWindow.Visible = false
invWindow.Parent = screenGui

local winStroke = Instance.new("UIStroke") -- [Added] 창 테두리
winStroke.Thickness = 2
winStroke.Color = Colors.Stroke 
winStroke.Parent = invWindow

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 16)
winCorner.Parent = invWindow

-- 1. 헤더 (Header)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Colors.Primary
header.BorderSizePixel = 0
header.Parent = invWindow

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

-- 헤더 하단 직각 처리
local headerCover = Instance.new("Frame")
headerCover.Name = "CornerCover"
headerCover.Size = UDim2.new(1, 0, 0, 10)
headerCover.Position = UDim2.new(0, 0, 1, -10)
headerCover.BackgroundColor3 = Colors.Primary
headerCover.BorderSizePixel = 0
headerCover.Parent = header

-- 헤더 아이콘 (텍스트로 변경)
local headerIcon = Instance.new("TextLabel")
headerIcon.Name = "Icon"
headerIcon.Size = UDim2.new(0, 24, 0, 24)
headerIcon.Position = UDim2.new(0, 15, 0.5, 0)
headerIcon.AnchorPoint = Vector2.new(0, 0.5)
headerIcon.BackgroundTransparency = 1
headerIcon.Text = "🎒"
headerIcon.Font = Enum.Font.GothamBold
headerIcon.TextSize = 28 -- [Modified] 24 -> 28
headerIcon.TextColor3 = Color3.new(1, 1, 1)
headerIcon.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Name = "Title"
headerTitle.Size = UDim2.new(1, -80, 1, 0)
headerTitle.Position = UDim2.new(0, 45, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "인벤토리"
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextSize = 28 -- [Modified] 24 -> 28
headerTitle.TextColor3 = Colors.TextTitle
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

-- 닫기 버튼
local closeBtn = Instance.new("ImageButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -15, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.BackgroundColor3 = Color3.new(1, 1, 1)
closeBtn.BackgroundTransparency = 0.8
closeBtn.Image = "rbxassetid://3926305904" -- X icon
closeBtn.ImageRectOffset = Vector2.new(284, 4)
closeBtn.ImageRectSize = Vector2.new(24, 24)
closeBtn.ImageColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

-- 2. 바디 (Content Area)
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -50) -- 헤더 높이 제외
body.Position = UDim2.new(0, 0, 0, 50)
body.BackgroundColor3 = Colors.Background
body.BorderSizePixel = 0
body.Parent = invWindow

local bodyCorner = Instance.new("UICorner")
bodyCorner.CornerRadius = UDim.new(0, 16)
bodyCorner.Parent = body

-- 바디 상단 직각 처리
local bodyCover = Instance.new("Frame")
bodyCover.Name = "CornerCover"
bodyCover.Size = UDim2.new(1, 0, 0, 10)
bodyCover.Position = UDim2.new(0, 0, 0, 0)
bodyCover.BackgroundColor3 = Colors.Background
bodyCover.BorderSizePixel = 0
bodyCover.Parent = body


-- 배경 클릭 시 닫기 위한 버튼 (투명)
local backgroundBtn = Instance.new("TextButton")
backgroundBtn.Name = "BackgroundButton"
backgroundBtn.Size = UDim2.new(1, 0, 1, 0)
backgroundBtn.Position = UDim2.new(0, 0, 0, 0)
backgroundBtn.BackgroundTransparency = 1
backgroundBtn.Text = ""
backgroundBtn.Visible = false
backgroundBtn.ZIndex = 0 -- 메인 프레임보다 뒤에 위치
backgroundBtn.Parent = screenGui

-- [v4.25k] 인벤토리 가시성 및 버튼 상태 통합 관리 함수
local function setInventoryVisible(visible)
	isOpen = visible
	invWindow.Visible = isOpen
	backgroundBtn.Visible = isOpen -- [Added] 배경 버튼 가시성 동기화
	if isOpen then
		invButton.BackgroundColor3 = Color3.fromRGB(255, 240, 150) -- [Modified] 열림 (매우 밝음)
	else
		invButton.BackgroundColor3 = Color3.fromRGB(255, 220, 100) -- [Modified] 닫힘 (밝은 옐로우오렌지)
	end
end

-- 배경 클릭 시 닫기
backgroundBtn.MouseButton1Click:Connect(function()
	setInventoryVisible(false)
end)

-- 슬롯 컨테이너 (바디 내부로 이동)
local slotContainer = Instance.new("Frame")
slotContainer.Name = "SlotContainer"
slotContainer.Size = UDim2.new(1, -40, 1, -40) -- 여백 20씩
slotContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
slotContainer.AnchorPoint = Vector2.new(0.5, 0.5)
slotContainer.BackgroundTransparency = 1
slotContainer.Parent = body

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 70, 0, 70)
gridLayout.CellPadding = UDim2.new(0, 15, 0, 15) -- 간격 조금 늘림
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- [Modified] 왼쪽 정렬 (사용자 요청)
gridLayout.Parent = slotContainer

-- 사용 모드 힌트 UI
local useModeHint = Instance.new("TextLabel")
useModeHint.Name = "UseModeHint"
useModeHint.Size = UDim2.new(0, 300, 0, 50)
useModeHint.Position = UDim2.new(0.5, 0, 0, 80)
useModeHint.AnchorPoint = Vector2.new(0.5, 0)
useModeHint.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
useModeHint.Text = "🎯 지형을 클릭해서 아이템 배치 (ESC 취소)"
useModeHint.TextSize = 22 -- [Modified] 18 -> 22
useModeHint.Font = Enum.Font.GothamBold
useModeHint.TextColor3 = Color3.new(1, 1, 1)
useModeHint.Visible = false
useModeHint.Parent = screenGui

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 10)
hintCorner.Parent = useModeHint

-- 3D 월드 프리뷰 모델 (마우스 위치에 따라 지형 위에 표시)
local previewModel = nil

-- [헬퍼] 투명도 설정 함수 (중복 제거)
local function setTransparency(obj, t)
	if obj:IsA("BasePart") then
		obj.Transparency = t
	end
	for _, child in ipairs(obj:GetDescendants()) do
		if child:IsA("BasePart") or child:IsA("Decal") then
			child.Transparency = t
		end
	end
end

-- 3D 프리뷰 아이템 생성 함수
local function createPreviewModel(itemId)
	-- 기존 프리뷰 제거
	if previewModel then
		previewModel:Destroy()
		previewModel = nil
	end
	
	-- 나뭇가지 프리뷰
	if itemId == "Stick" then
		local part = Instance.new("Part")
		part.Name = "ItemPreview"
		part.Size = Vector3.new(0.2, 0.2, 1.5)
		part.Color = Color3.fromRGB(90, 60, 30)
		part.Material = Enum.Material.Wood
		part.Anchored = true
		part.CanCollide = false
		part.CFrame = CFrame.Angles(0, 0, math.rad(10))
		part.Parent = workspace
		
		-- 외곽선 글로우 효과 (Highlight)
		local highlight = Instance.new("Highlight")
		highlight.Name = "PreviewHighlight"
		highlight.FillTransparency = 0.5 -- 반투명
		highlight.FillColor = Color3.fromRGB(255, 255, 150)
		highlight.OutlineTransparency = 0
		highlight.OutlineColor = Color3.fromRGB(255, 255, 100) -- 밝은 노란색
		highlight.Parent = part
		
		previewModel = part
	elseif itemId == "Bungeoppang" then
		-- 붕어빵 (From Assets)
		local assets = ReplicatedStorage:WaitForChild("Assets", 5)
		local sourceItem = assets and assets:FindFirstChild("Bungeoppang")
		
		if sourceItem then
			local model = Instance.new("Model")
			model.Name = "ItemPreview"
			
			-- [v4.25c] Support both Part and Accessory/Model
			local cloned = sourceItem:Clone()
			local targetHandle = nil
			
			if cloned:IsA("BasePart") then
				targetHandle = cloned
			elseif cloned:IsA("Accessory") then
				targetHandle = cloned:FindFirstChild("Handle")
			elseif cloned:IsA("Model") then
				targetHandle = cloned.PrimaryPart or cloned:FindFirstChildWhichIsA("BasePart")
			end

			if targetHandle then
				targetHandle.Name = "Handle"
				targetHandle.Anchored = true
				targetHandle.CanCollide = false
				targetHandle.Parent = model
				model.PrimaryPart = targetHandle
				
				-- 크기 확대 (3배) - 붕어빵을 좀 더 잘 보이게
				local scale = 3
				if targetHandle:IsA("BasePart") then
					targetHandle.Size = targetHandle.Size * scale
				end
				local mesh = targetHandle:FindFirstChildOfClass("SpecialMesh")
				if mesh then
					mesh.Scale = mesh.Scale * scale
				end
				
				-- 불필요한 원본 제거
				if cloned ~= targetHandle then cloned:Destroy() end
			else
				cloned:Destroy()
			end
			
			model.Parent = workspace
			
			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 0.5
			highlight.FillColor = Color3.fromRGB(255, 220, 150)
			highlight.OutlineTransparency = 0
			highlight.OutlineColor = Color3.fromRGB(255, 200, 100)
			highlight.Parent = model
			
			previewModel = model

			
			-- [v4.23s] Visual Debug: Preview is GREEN
			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 0.5
			highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Green
			highlight.OutlineTransparency = 0
			highlight.OutlineColor = Color3.fromRGB(0, 255, 100)
			highlight.Parent = model
			local handle = model.PrimaryPart
			if handle then
				-- 사용자 요청 정밀 각도 (-40.997, 175.114, -10.472)
				handle.CFrame = CFrame.fromOrientation(math.rad(-40.997), math.rad(175.114), math.rad(-10.472))

			end
		else
			-- Fallback
			local part = Instance.new("Part")
			part.Name = "ItemPreview"
			part.Size = Vector3.new(1.5, 1.5, 1.5)
			part.Color = Color3.fromRGB(255, 170, 80)
			part.Anchored = true
			part.CanCollide = false
			part.Parent = workspace
			previewModel = part
		end
	elseif itemId == "CatTrap" then
		-- Items 폴더 우선 확인
		local items = ReplicatedStorage:FindFirstChild("Items")
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local source = (items and items:FindFirstChild("CatTrap")) or (assets and assets:FindFirstChild("CatTrap")) or workspace:FindFirstChild("CatTrap")
		local part = nil
		
		if source then
			part = source:Clone()
			part.Name = "ItemPreview"
			
			-- [충돌 감지용] 문을 올리기 전에 크기 측정
			local size = part:GetExtentsSize()

			_G.TrapSize = size
			
			-- 3D Preview: Reset position to 0,0,0
			-- [Fix] 회전 (X축 90도)
			if part:IsA("Model") then
				part:PivotTo(CFrame.new(0,0,0) * CFrame.Angles(0, math.rad(90), 0))
				
				-- [New] Setting 상태(문 열림)로 보이게 하기
				local partEnter = part:FindFirstChild("PartEnter")
				if partEnter then
					-- 로컬 좌표계 기준 위로 4 스터드 이동 (Setting 상태)
					-- 모델이 회전되어 있으므로 CFrame.new(0, 4, 0)을 곱하면 월드 기준 위로 감
					-- PartEnter가 모델의 일부이므로, 모델 Pivot 기준 상대 이동을 해야 함
					-- 단순하게 PartEnter의 CFrame을 위로 올림
					partEnter.CFrame = partEnter.CFrame * CFrame.new(0, 4, 0)
					
					-- 자식들도 같이 이동 (Weld가 없으므로 수동 이동)
					for _, child in ipairs(partEnter:GetChildren()) do
						if child:IsA("BasePart") then
							-- 상대 위치 유지하면서 부모 따라가기 (약간 복잡할 수 있음)
							-- 쉐이프가 단순하다면 그냥 부모 CFrame 복사해도 됨
							child.CFrame = child.CFrame * CFrame.new(0, 4, 0)
						end
					end
				end
			else
				part.CFrame = CFrame.new(0,0,0) * CFrame.Angles(0, math.rad(90), 0)
				part.Anchored = true
				part.CanCollide = false
			end
		else
			-- Fallback
			part = Instance.new("Part")
			part.Name = "ItemPreview"
			part.Size = Vector3.new(2, 2, 2)
			part.Color = Color3.fromRGB(139, 69, 19) -- SaddleBrown
			part.Material = Enum.Material.Wood
			part.Anchored = true
			part.CanCollide = false
		end
		
		part.Parent = workspace
		
		local highlight = Instance.new("Highlight")
		highlight.Name = "PlacementHighlight"
		highlight.FillTransparency = 0.5
		highlight.FillColor = Color3.fromRGB(0, 255, 0)
		highlight.OutlineTransparency = 0
		highlight.OutlineColor = Color3.fromRGB(0, 255, 100)
		highlight.Parent = part
		
		previewModel = part
	else
		local items = ReplicatedStorage:FindFirstChild("Items")
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local sourceItem = (items and items:FindFirstChild(itemId)) or (assets and assets:FindFirstChild(itemId))
		
		if sourceItem then
			local cloned = sourceItem:Clone()
			
			if cloned:IsA("Accessory") then
				local handle = cloned:FindFirstChild("Handle")
				if handle then
					handle.Parent = nil
					cloned:Destroy()
					cloned = handle
				end
			end
			
			cloned.Name = "ItemPreview"
			
			for _, desc in ipairs(cloned:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Anchored = true
					desc.CanCollide = false
				end
			end
			if cloned:IsA("BasePart") then
				cloned.Anchored = true
				cloned.CanCollide = false
			end
			
			cloned.Parent = workspace
			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 0.5
			highlight.FillColor = Color3.fromRGB(255, 220, 150)
			highlight.OutlineTransparency = 0
			highlight.Parent = cloned
			previewModel = cloned
		end
		
		if not previewModel then
			local part = Instance.new("Part")
			part.Name = "ItemPreview"
			part.Size = Vector3.new(0.5, 0.5, 0.5)
			part.Color = Color3.fromRGB(150, 150, 150)
			part.Anchored = true
			part.CanCollide = false
			part.Parent = workspace
			
			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 0.5
			highlight.FillColor = Color3.fromRGB(200, 200, 200)
			highlight.OutlineTransparency = 0
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.Parent = part
			
			previewModel = part
		end
	end
end

-- 프리뷰 제거 함수
local function destroyPreviewModel()
	if previewModel then

		previewModel:Destroy()
		previewModel = nil
	end
	
	-- [v4.25d] 하이라이트 정리
	if _G.BaitHighlight then
		_G.BaitHighlight.Enabled = false
	end
end

-- 유효한 지면 찾기 (동적 오브젝트 무시)
local function getValidGroundRaycast(origin, direction)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local catsFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Cats")
	rayParams.FilterDescendantsInstances = {previewModel, player.Character, catsFolder} -- 플레이어, 프리뷰, 고양이 폴더 제외
	
	local currentOrigin = origin
	local currentDirection = direction
	
	-- 최대 5번까지 관통 시도 (고양이, 차 등이 겹쳐있을 경우 대비)
	for i = 1, 5 do
		local result = workspace:Raycast(currentOrigin, currentDirection, rayParams)
		if not result then return nil end
		
		local hitPart = result.Instance
		local isDynamic = false
		
		-- 동적 오브젝트 판별 조건
		if not hitPart.Anchored then isDynamic = true end -- 움직이는 파트
		if hitPart.Parent:FindFirstChildOfClass("Humanoid") then isDynamic = true end -- NPC/플레이어
		if hitPart.Parent:IsA("Model") and hitPart.Parent:FindFirstChildOfClass("VehicleSeat") then isDynamic = true end -- 차량
		
		-- [v4.25d] 덫은 미끼 설치를 위해 레이캐스트 대상에 포함 (무시하지 않음)
		if hitPart:FindFirstAncestor("CatTrap") then isDynamic = false end
		
		if isDynamic then
			-- 동적 오브젝트면 무시 목록에 추가하고 다시 레이캐스트
			local filterList = rayParams.FilterDescendantsInstances
			table.insert(filterList, hitPart.Parent) -- 모델 전체 무시
			rayParams.FilterDescendantsInstances = filterList
			
			-- 관통 후 다시 쏘기
			-- (원래 로직 대신, 그냥 FilterDescendantsInstances 업데이트 후 처음부터 다시 쏴도 됨. 
			--  하지만 direction이 길면 성능상 그냥 제외하고 다시 쏘는게 편함)
		else
			-- 정적 지면 발견
			return result
		end
	end
	
	return nil
end

-- 마우스 위치에 프리뷰 업데이트
local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function()
	if isUseMode and previewModel then
		-- 마우스가 가리키는 방향으로 레이캐스트
		local mouseRay = mouse.UnitRay
		-- getValidGroundRaycast 함수 필요 (파일 상단에 이미 정의되어 있다고 가정)
		local result = getValidGroundRaycast(mouseRay.Origin, mouseRay.Direction * 1000)
		
		if result then
			local targetPos = result.Position + Vector3.new(0, 0, 0) -- 바닥 보정
			
			-- 아이템별 회전값 분기
			local rotation = CFrame.Angles(0, 0, 0)
			
			-- 현재 선택된 아이템 ID 찾기
			local currentItemId = nil
			if selectedSlot and inventory[selectedSlot] then
				currentItemId = inventory[selectedSlot].ItemId
			end
			
			if currentItemId == "Bungeoppang" then
				-- 붕어빵 전용 회전
				rotation = CFrame.fromOrientation(math.rad(-40.997), math.rad(175.114), math.rad(-10.472))
			elseif currentItemId == "CatTrap" then
				-- [동기화] 서버와 동일하게 플레이어를 바라보는 방향으로 회전
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local lookAt = CFrame.lookAt(targetPos, Vector3.new(hrp.Position.X, targetPos.Y, hrp.Position.Z))
					local rx, ry, rz = lookAt:ToOrientation()
					rotation = CFrame.Angles(0, ry, 0)
				else
					rotation = CFrame.Angles(0, math.rad(90), 0)
				end
			else
				-- 기타 아이템 (기본 평평 + Y축 회전값 없음)
				rotation = CFrame.Angles(0, 0, 0)
			end
			
			-- [v4.25d] 덫 외곽선 하이라이트 (미끼 설치 가능 피드백)
			local trapModel = result.Instance:FindFirstAncestor("CatTrap")
			local function updateTrapHighlight(isBait, trap)
				-- 전역 highlight 변수 사용 (없으면 생성)
				if not _G.BaitHighlight then
					local h = Instance.new("Highlight")
					h.Name = "BaitHighlight"
					h.FillTransparency = 0.5
					h.FillColor = Color3.fromRGB(0, 255, 0) -- Green
					h.OutlineColor = Color3.fromRGB(0, 255, 100)
					h.OutlineTransparency = 0
					h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- [Fix] 가려지지 않게 설정
					h.Parent = screenGui -- [Fix] Parent 설정 (screenGui는 파일 상단에 정의됨)
					_G.BaitHighlight = h
				end
				
				local h = _G.BaitHighlight
				if isBait and trap then
					-- [v4.25d] Setting 상태일 때만 하이라이트 표시
					-- [v4.25e] TargetState가 nil인 경우도 대비 (IDLE 등)
					local currentState = trap:GetAttribute("TargetState")
					if currentState == "Setting" then
						h.Adornee = trap
						h.Enabled = true
					else
						h.Enabled = false
					end
				else
					h.Enabled = false
				end
			end
			
			local isBait = (currentItemId == "Bungeoppang")
			updateTrapHighlight(isBait, trapModel)
			
			-- [충돌 감지] 다른 오브젝트와 겹치는지 확인
			canPlace = true -- 전역 변수 업데이트
			if currentItemId == "CatTrap" and _G.TrapSize then
				-- [거리 체크] 캐릭터 근처에만 설치 가능 (15 스터드 이내)
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local distance = (targetPos - hrp.Position).Magnitude
					if distance > 10 then
						canPlace = false
					end
				end
				
				-- [충돌 체크] 다른 오브젝트와 겹치는지
				if canPlace then
					local overlapParams = OverlapParams.new()
					overlapParams.FilterType = Enum.RaycastFilterType.Exclude
					overlapParams.FilterDescendantsInstances = {previewModel, player.Character}
					
					-- 실제 크기보다 살짝 작게 (0.2) 잡아서 끼임 방지
					local boundSize = _G.TrapSize - Vector3.new(0.2, 0.2, 0.2)
					local centerOffset = Vector3.new(0, _G.TrapSize.Y / 2, 0)
					
					local overlaps = workspace:GetPartBoundsInBox(CFrame.new(targetPos + centerOffset), boundSize, overlapParams)
					
					for _, p in ipairs(overlaps) do
						if not p:IsA("Terrain") and p.CanCollide then
							canPlace = false
							break
						end
					end
				end
			end
			
			-- 하이라이트 색상 업데이트 (녹색/빨간색)
			local highlight = previewModel:FindFirstChild("PlacementHighlight")
			if highlight then
				if canPlace then
					highlight.FillColor = Color3.fromRGB(0, 255, 0) -- 녹색 (설치 가능)
					highlight.OutlineColor = Color3.fromRGB(0, 255, 100)
				else
					highlight.FillColor = Color3.fromRGB(255, 0, 0) -- 빨간색 (설치 불가)
					highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
				end
			end

			-- Model이든 Part이든 PivotTo 사용
			if previewModel:IsA("Model") then
				previewModel:PivotTo(CFrame.new(targetPos) * rotation)
			else
				previewModel.CFrame = CFrame.new(targetPos) * rotation
			end
			
			setTransparency(previewModel, 0)
			
		else
			-- [허공] 하이라이트 끄기 + 프리뷰 숨김
			if _G.BaitHighlight then _G.BaitHighlight.Enabled = false end
			if previewModel then
				setTransparency(previewModel, 1)
			end
		end
	end
end)

-- [Fix] cancelUseMode 포워드 선언 (createSlot 내 ContextActionService 콜백에서 참조하기 위함)
local cancelUseMode

-- 슬롯 생성 함수
local function createSlot(index, itemId, count)
	local itemDef = ItemData.GetItem(itemId)
	if not itemDef then return end
	

	
	local slot = Instance.new("TextButton")
	slot.Name = "Slot_" .. index
	slot.Size = UDim2.new(0, 70, 0, 70)
	slot.BackgroundColor3 = Colors.Card -- [Modified] 카드 색상 (흰색)
	slot.BorderSizePixel = 0 -- [Added] 기본 테두리 제거
	slot.Text = ""
	slot.LayoutOrder = index
	slot.Parent = slotContainer
	
	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 12) -- [Modified] 조금 더 둥글게
	slotCorner.Parent = slot

	local slotStroke = Instance.new("UIStroke")
	slotStroke.Thickness = 2
	slotStroke.Color = Colors.Stroke -- [Modified] 연한 오렌지 테두리
	slotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- [Added] 아웃라인 모드
	slotStroke.Parent = slot
	
	-- 3D 아이템 표시 (ViewportFrame)
	local slotViewport = Instance.new("ViewportFrame")
	slotViewport.Name = "ItemViewport"
	slotViewport.Size = UDim2.new(1, -10, 0.7, 0)
	slotViewport.Position = UDim2.new(0, 5, 0, 5)
	slotViewport.BackgroundTransparency = 1
	slotViewport.Active = false
	slotViewport.Interactable = false
	slotViewport.Parent = slot
	

	
	local slotCamera = Instance.new("Camera")
	slotCamera.FieldOfView = 50 -- 조금 더 넓게
	
	if itemId == "Bungeoppang" then
		-- 붕어빵은 모델이 크므로 카메라를 조금 더 앞으로 당김 (6배 확대에 맞게 조정)
		slotCamera.CFrame = CFrame.new(Vector3.new(0, 0, 4.0), Vector3.new(0, 0, 0)) 
	elseif itemId == "CatTrap" then
		-- CatTrap (Size 2x2x2) needs camera further back
		slotCamera.CFrame = CFrame.new(Vector3.new(0, 1.5, 9.0), Vector3.new(0, 0, 0))
	else
		slotCamera.CFrame = CFrame.new(Vector3.new(0, 0, 1), Vector3.new(0, 0, 0)) -- 기본값
	end
	slotCamera.Parent = slotViewport
	slotViewport.CurrentCamera = slotCamera
	
	-- 아이템별 3D 모델 생성 (월드 아이템과 동일한 비율)
	if itemId == "Bungeoppang" then
		-- 붕어빵 (From Assets)
		local assets = ReplicatedStorage:WaitForChild("Assets", 5)
		local sourceItem = assets and assets:FindFirstChild("Bungeoppang")
		
		if sourceItem then
			local model = sourceItem:Clone() -- 복제!
			
			if not model then
				warn("[InventoryUI] Failed to clone Bungeoppang asset")
				-- Fallback
				local part = Instance.new("Part")
				part.Size = Vector3.new(1.5, 1.5, 1.5)
				part.Color = Color3.fromRGB(255, 170, 80)
				part.Parent = slotViewport
				return
			end

			if model:IsA("Model") then
				if Config.Debug and Config.Debug.ShowLogs then print("[InventoryUI] Valid Bungeoppang Model found") end
				model.Name = "InventoryItem"
				model:PivotTo(CFrame.new(0,0,0) * CFrame.Angles(math.rad(-20), math.rad(45), 0))
				model.Parent = slotViewport
			elseif model:IsA("Accessory") then
				if Config.Debug and Config.Debug.ShowLogs then print("[InventoryUI] Valid Bungeoppang Accessory found") end
				local handle = model:FindFirstChild("Handle") or model:FindFirstChildWhichIsA("BasePart")
				
				if handle then
					if Config.Debug and Config.Debug.ShowLogs then print("[InventoryUI] Handle found: " .. handle.Name) end
					
					-- 액세서리에서 핸들만 추출 (Accessory 동작 방지)
					handle.Name = "InventoryItem"
					handle.Parent = slotViewport -- Viewport에 직접 넣음
					model:Destroy() -- 껍데기 제거
					model = handle -- 참조 변경
					
					-- 크기 초대형 확대 (6.0배)
					local scale = 6.0
					handle.Size = handle.Size * scale
					local mesh = handle:FindFirstChildOfClass("SpecialMesh")
					if mesh then
						mesh.Scale = mesh.Scale * scale
					end

					-- 인벤토리에서는 눕혀진 윗면이 보이도록 -90도 세움
					-- X축 -90도: 사용자가 요청한 각도 (윗면 정면 추정)
					-- Z축 0도: 정방향
					handle.CFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(-90), 0, 0)
					handle.Anchored = true
					
					-- 투명도 체크 및 강제 설정
					if handle.Transparency > 0.9 then
						warn("[InventoryUI] Handle is transparent (".. handle.Transparency .."). Force setting to 0.")
						handle.Transparency = 0
					else
						handle.Transparency = 0
					end
				else
					warn("[InventoryUI] NO Handle found in Accessory! Creating fallback part.")
					local p = Instance.new("Part")
					p.Name = "InventoryItem" -- 이름 표준화
					p.Size = Vector3.new(1.5, 1.5, 1.5)
					p.Color = Color3.fromRGB(255, 0, 0) -- Red for error
					p.CFrame = CFrame.new(0,0,0)
					p.Parent = slotViewport
					if model then model:Destroy() end
				end
			else
				-- Part (BasePart) 처리 - 이제 AssetLoader에서 Part로 변환됨

				model.Name = "InventoryItem"
				
				-- 크기 초대형 확대 (6.0배)
				local scale = 6.0
				model.Size = model.Size * scale
				local mesh = model:FindFirstChildOfClass("SpecialMesh")
				if mesh then
					mesh.Scale = mesh.Scale * scale
				end

				-- 인벤토리에서는 눕혀진 윗면이 보이도록 설정 (사용자 요청 값 적용)
				model.CFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(-120), math.rad(15), math.rad(15))
				model.Anchored = true
				model.Transparency = 0
				model.Parent = slotViewport
			end
		else
			-- Fallback
			local part = Instance.new("Part")
			part.Name = "InventoryItem"
			part.Size = Vector3.new(1.5, 1.5, 1.5)
			part.Color = Color3.fromRGB(255, 170, 80)
			part.CFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(-120), math.rad(15), math.rad(15))
			part.Parent = slotViewport
		end
	elseif itemId == "CatTrap" then
		-- Items 폴더 우선 확인 (Viewport)
		local items = ReplicatedStorage:FindFirstChild("Items")
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local source = (items and items:FindFirstChild("CatTrap")) or (assets and assets:FindFirstChild("CatTrap")) or workspace:FindFirstChild("CatTrap")
		
		if source then
			local model = source:Clone()
			
			-- 불필요한 요소 정리 (하이라이트, 클릭감지 등)
			for _, desc in ipairs(model:GetDescendants()) do
				if desc:IsA("Highlight") or desc:IsA("ClickDetector") or desc:IsA("ProximityPrompt") then
					desc:Destroy()
				elseif desc:IsA("BasePart") then
					desc.Anchored = true
					desc.CanCollide = false
				end
			end
			
			-- Center it (사용자 요청 값 적용: 0, -140, 0)
			local targetCF = CFrame.new(0,0,0) * CFrame.Angles(math.rad(0), math.rad(-140), math.rad(0))
			if model:IsA("Model") then
				model:PivotTo(targetCF)
			else
				model.CFrame = targetCF
				model.Anchored = true
			end
			model.Parent = slotViewport
		else
			-- Fallback Box
			local part = Instance.new("Part")
			part.Size = Vector3.new(2, 2, 2)
			part.Color = Color3.fromRGB(139, 69, 19) -- SaddleBrown
			part.Material = Enum.Material.Wood
			part.CFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(0), math.rad(-140), math.rad(0))
			part.Parent = slotViewport
		end
	else
		local items = ReplicatedStorage:FindFirstChild("Items")
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local sourceItem = (items and items:FindFirstChild(itemId)) or (assets and assets:FindFirstChild(itemId))

		if sourceItem then
			local model = sourceItem:Clone()
			
			if model:IsA("Accessory") then
				local handle = model:FindFirstChild("Handle")
				if handle then
					handle.Parent = nil
					model:Destroy()
					model = handle
				end
			end
			
			model.Name = "InventoryItem"
			
			if model:IsA("Model") then
				for _, desc in ipairs(model:GetDescendants()) do
					if desc:IsA("BasePart") then desc.Anchored = true end
				end
				model:PivotTo(CFrame.new(Vector3.zero))
				-- CatCan, SpeedBoost: Z축 90도 회전 (상점과 동일)
				if itemId == "CatCan" or itemId == "SpeedBoost" then
					model:PivotTo(CFrame.new(Vector3.zero) * CFrame.Angles(0, 0, math.rad(90)))
				end
			elseif model:IsA("BasePart") then
				model.Anchored = true
				model.CFrame = CFrame.new(Vector3.zero)
				-- CatCan, SpeedBoost: Z축 90도 회전 (상점과 동일)
				if itemId == "CatCan" or itemId == "SpeedBoost" then
					model.CFrame = CFrame.new(Vector3.zero) * CFrame.Angles(0, 0, math.rad(90))
				end
			end
			
			model.Parent = slotViewport
			
			-- adjust camera to fit
			local maxDim = 2
			if model:IsA("Model") then
				local size = model:GetExtentsSize()
				maxDim = math.max(size.X, size.Y, size.Z)
			elseif model:IsA("BasePart") then
				maxDim = math.max(model.Size.X, model.Size.Y, model.Size.Z)
			end
			slotCamera.CFrame = CFrame.new(Vector3.new(0, maxDim*0.2, maxDim*1.5), Vector3.zero)
		else
			local part = Instance.new("Part")
			part.Size = Vector3.new(1.5, 1.5, 1.5) -- 3배 확대
			part.Color = Color3.fromRGB(150, 150, 150)
			part.Parent = slotViewport
		end
	end
	
	-- [New] ThumbnailCamera Support
	local model = slotViewport:FindFirstChildWhichIsA("Model") or slotViewport:FindFirstChildWhichIsA("BasePart")
	if model and model ~= slotCamera then
		local thumbCam = model:FindFirstChild("ThumbnailCamera") 
			or model:FindFirstChild("Camera") 
			or model:FindFirstChild("ThumbnailConfiguration")
			
		if thumbCam then
			if thumbCam:IsA("Camera") then
				slotCamera.CFrame = thumbCam.CFrame
			elseif thumbCam:IsA("Configuration") then
				local actualCam = thumbCam:FindFirstChildWhichIsA("Camera")
				if actualCam then
					slotCamera.CFrame = actualCam.CFrame
				end
			end
		end
	end
	
	-- 수량
	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.Size = UDim2.new(1, -5, 0.3, 0)
	countLabel.Position = UDim2.new(0, 0, 0.7, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = "x" .. count
	countLabel.TextSize = 18 -- [Modified] 14 -> 18
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextColor3 = Color3.fromRGB(120, 90, 80) -- [Modified] 진한 갈색 (가독성)
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.Parent = slot
	
	-- 클릭 시 사용 모드 진입
	slot.MouseButton1Click:Connect(function()
		-- 인벤토리 창 닫기
		setInventoryVisible(false) -- [v4.25k] 통합 함수 사용
		
		-- 사용 모드 진입
		isUseMode = true
		selectedSlot = index
		useModeHint.Text = "🎯 " .. itemDef.Name .. " 배치할 곳 클릭 (우클릭 취소)"
		useModeHint.Visible = true
		
		-- 3D 월드 프리뷰 생성
		createPreviewModel(itemId)
		
		-- 마우스 커서를 손 모양으로 변경
		mouse.Icon = "rbxasset://SystemCursors/PointingHand"
	end)
	
	-- 호버 효과 (부드러운 크림색으로 변경)
	slot.MouseEnter:Connect(function()
		slot.BackgroundColor3 = Color3.fromRGB(245, 245, 240) -- [Modified] hover color
	end)
	slot.MouseLeave:Connect(function()
		slot.BackgroundColor3 = Colors.Card -- [Modified] original color
	end)
end

-- UI 갱신
local function refreshUI()
	-- 기존 슬롯 제거
	for _, child in ipairs(slotContainer:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- 새 슬롯 생성
	for i, slot in ipairs(inventory) do
		createSlot(i, slot.ItemId, slot.Count)
	end
end

-- 토글 함수
local function toggleInventory()
	setInventoryVisible(not isOpen) -- [v4.25k] 통합 함수 사용
end

-- 사용 모드 취소
cancelUseMode = function()
	isUseMode = false
	selectedSlot = nil
	useModeHint.Visible = false
	-- 마우스 커서 복원
	mouse.Icon = ""
	-- 3D 프리뷰 정리
	destroyPreviewModel()
end

-- 마우스 클릭 처리 (사용 모드)
mouse.Button1Down:Connect(function()
	if not isUseMode or not selectedSlot then return end
	
	-- UI 위 클릭은 무시 (단, 사용 모드 힌트 UI는 제외)
	local guiObjects = playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
	local realGuiCount = 0
	for _, obj in ipairs(guiObjects) do
		-- useModeHint(힌트 텍스트), FadeFrame(화면 전환 효과용 전체 덮개) 무시
		if obj ~= useModeHint and not obj:IsDescendantOf(useModeHint) and obj.Name ~= "FadeFrame" then
			realGuiCount = realGuiCount + 1
		end
	end
	if realGuiCount > 0 then return end
	
	-- 유효한 지면 클릭 확인
	local mouseRay = mouse.UnitRay
	local result = getValidGroundRaycast(mouseRay.Origin, mouseRay.Direction * 1000)
	
	if result then
		-- [충돌 감지] 설치 불가 상태면 무시
		if not canPlace then
			return
		end
		
		-- 서버에 아이템 배치 요청
		placeEvent:FireServer(selectedSlot, result.Position, result.Instance)
		cancelUseMode()
	end
end)

-- [New Fix] 마우스 우클릭으로 사용 모드 취소 (Roblox 시스템상 ESC 차단 불가)
mouse.Button2Down:Connect(function()
	if isUseMode then
		cancelUseMode()
	end
end)

-- 이벤트 연결
invButton.MouseButton1Click:Connect(toggleInventory)
closeBtn.MouseButton1Click:Connect(function()
	setInventoryVisible(false) -- [v4.25k] 통합 함수 사용
end)


updateEvent.OnClientEvent:Connect(function(newInventory)
	if Config.Debug and Config.Debug.ShowLogs then
		print("[InventoryUI] Received inventory update. Item Count: " .. #newInventory)
		for i, v in ipairs(newInventory) do
			print(" - Slot " .. i .. ": " .. v.ItemId .. " x" .. v.Count)
		end
	end
	inventory = newInventory
	refreshUI()
end)

requestUpdateEvent:FireServer()


