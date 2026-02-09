-- InventoryUI.client.lua
-- 인벤토리 UI (별도 창 + 토글 버튼 + 아이템 사용 모드)
-- StarterGui에 위치
-- [v4.23s] Preview Debug Mode (Green)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local events = ReplicatedStorage:WaitForChild("Events")
local updateEvent = events:WaitForChild("UpdateInventory")
local useEvent = events:WaitForChild("UseItem")

local placeEvent = events:FindFirstChild("PlaceItem")
if not placeEvent then
	placeEvent = Instance.new("RemoteEvent")
	placeEvent.Name = "PlaceItem"
	placeEvent.Parent = events
end

local requestUpdateEvent = events:WaitForChild("RequestInventoryUpdate")

local inventory = {} -- 로컬 캐시
local isUseMode = false -- 아이템 사용 모드
local selectedSlot = nil -- 선택된 슬롯 인덱스
local isOpen = false -- [v4.25k] 전역 상태 동기화를 위해 상단으로 이동

-- UI 생성
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 인벤토리 버튼 (우측 중단)
local invButton = Instance.new("TextButton")
invButton.Name = "InventoryButton"
invButton.Size = UDim2.new(0, 60, 0, 60)
invButton.Position = UDim2.new(1, -80, 0.8, -30) -- [v4.25j] 우측 하단으로 고정 위치 이동
invButton.AnchorPoint = Vector2.new(0, 0)
invButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
invButton.Text = "🎒"
invButton.TextSize = 32
invButton.Font = Enum.Font.GothamBold
invButton.TextColor3 = Color3.new(1, 1, 1)
invButton.Parent = screenGui



local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = invButton

-- 인벤토리 창
local invWindow = Instance.new("Frame")
invWindow.Name = "InventoryWindow"
invWindow.Size = UDim2.new(0, 400, 0, 300)
invWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
invWindow.AnchorPoint = Vector2.new(0.5, 0.5)
invWindow.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
invWindow.Visible = false
invWindow.Parent = screenGui

local winCorner = Instance.new("UICorner")
winCorner.Parent = invWindow

-- [v4.25k] 인벤토리 가시성 및 버튼 상태 통합 관리 함수
local function setInventoryVisible(visible)
	isOpen = visible
	invWindow.Visible = isOpen
	if isOpen then
		invButton.BackgroundColor3 = Color3.fromRGB(100, 100, 150) -- 열림 (강조)
	else
		invButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80) -- 닫힘 (기본)
	end
end

-- 타이틀
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "🎒 인벤토리"
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = invWindow

-- 닫기 버튼
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = invWindow

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- 슬롯 컨테이너
local slotContainer = Instance.new("Frame")
slotContainer.Name = "SlotContainer"
slotContainer.Size = UDim2.new(1, -20, 1, -60)
slotContainer.Position = UDim2.new(0, 10, 0, 50)
slotContainer.BackgroundTransparency = 1
slotContainer.Parent = invWindow

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 70, 0, 70)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = slotContainer

-- 사용 모드 힌트 UI
local useModeHint = Instance.new("TextLabel")
useModeHint.Name = "UseModeHint"
useModeHint.Size = UDim2.new(0, 300, 0, 50)
useModeHint.Position = UDim2.new(0.5, 0, 0, 80)
useModeHint.AnchorPoint = Vector2.new(0.5, 0)
useModeHint.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
useModeHint.Text = "🎯 지형을 클릭해서 아이템 배치 (ESC 취소)"
useModeHint.TextSize = 18
useModeHint.Font = Enum.Font.GothamBold
useModeHint.TextColor3 = Color3.new(1, 1, 1)
useModeHint.Visible = false
useModeHint.Parent = screenGui

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 10)
hintCorner.Parent = useModeHint

-- 3D 월드 프리뷰 모델 (마우스 위치에 따라 지형 위에 표시)
local previewModel = nil

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
	elseif itemId == "CatTreat" then
		local part = Instance.new("Part")
		part.Name = "ItemPreview"
		part.Size = Vector3.new(0.5, 0.3, 0.5)
		part.Color = Color3.fromRGB(255, 150, 100)
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.Parent = workspace
		
		local highlight = Instance.new("Highlight")
		highlight.FillTransparency = 0.5
		highlight.FillColor = Color3.fromRGB(255, 200, 150)
		highlight.OutlineTransparency = 0
		highlight.OutlineColor = Color3.fromRGB(255, 200, 100)
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
			print("[InventoryUI] Created Preview Model: " .. tostring(previewModel))
			
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
				print("[InventoryUI] Preview Init Rotation: " .. tostring(handle.Orientation))
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
		-- CatTrap Visual (Real Model)
		local source = workspace:FindFirstChild("CatTrap")
		local part = nil
		
		if source then
			part = source:Clone()
			part.Name = "ItemPreview"
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
		highlight.FillTransparency = 0.5
		highlight.FillColor = Color3.fromRGB(0, 255, 0)
		highlight.OutlineTransparency = 0
		highlight.OutlineColor = Color3.fromRGB(0, 255, 100)
		highlight.Parent = part
		
		previewModel = part
	else
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

-- 프리뷰 제거 함수
local function destroyPreviewModel()
	if previewModel then
		print("[InventoryUI] Destroying Preview Model: " .. tostring(previewModel))
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
				-- [Fix] CatTrap은 바닥에 평평하게 (사용자 요청: Y축 90도)
				rotation = CFrame.Angles(0, math.rad(90), 0)
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
			
			local isBait = (currentItemId == "Bungeoppang" or currentItemId == "CatTreat")
			updateTrapHighlight(isBait, trapModel)

			-- Model이든 Part이든 PivotTo 사용
			if previewModel:IsA("Model") then
				previewModel:PivotTo(CFrame.new(targetPos) * rotation)
			else
				previewModel.CFrame = CFrame.new(targetPos) * rotation
			end
			
			-- 투명도 설정 함수 (보임)
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
			setTransparency(previewModel, 0)
			
		else
			-- [v4.25d] 허공일 때 하이라이트 끄기
			if _G.BaitHighlight then _G.BaitHighlight.Enabled = false end
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
			
			if previewModel then
				setTransparency(previewModel, 1) -- 숨김
			end
		end
	end
end)

-- 슬롯 생성 함수
local function createSlot(index, itemId, count)
	local itemDef = ItemData.GetItem(itemId)
	if not itemDef then return end
	
	print("[InventoryUI] Creating slot for " .. itemId)
	
	local slot = Instance.new("TextButton")
	slot.Name = "Slot_" .. index
	slot.Size = UDim2.new(0, 70, 0, 70)
	slot.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
	slot.Text = ""
	slot.LayoutOrder = index
	slot.Parent = slotContainer
	
	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 8)
	slotCorner.Parent = slot
	
	-- 3D 아이템 표시 (ViewportFrame)
	local slotViewport = Instance.new("ViewportFrame")
	slotViewport.Name = "ItemViewport"
	slotViewport.Size = UDim2.new(1, -10, 0.7, 0)
	slotViewport.Position = UDim2.new(0, 5, 0, 5)
	slotViewport.BackgroundTransparency = 1
	slotViewport.Active = false
	slotViewport.Interactable = false
	slotViewport.Parent = slot
	
	print("[InventoryUI] ViewportFrame created. Parent: " .. tostring(slotViewport.Parent))
	
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
	if itemId == "Stick" then
		local part = Instance.new("Part")
		-- 월드 아이템 비율: 0.2 x 0.2 x 1.5 (가늘고 긴 막대)
		part.Size = Vector3.new(0.15, 0.15, 1) -- 작게
		part.Color = Color3.fromRGB(90, 60, 30)
		part.Material = Enum.Material.Wood
		-- 대각선으로 기울여서 잘 보이게
		part.CFrame = CFrame.Angles(math.rad(30), math.rad(45), math.rad(20))
		part.Parent = slotViewport
	elseif itemId == "CatTreat" then
		local part = Instance.new("Part")
		part.Size = Vector3.new(1.5, 1, 1.5) -- 3배 확대
		part.Color = Color3.fromRGB(255, 150, 100)
		part.Material = Enum.Material.SmoothPlastic
		part.Parent = slotViewport
	elseif itemId == "SpeedBoost" then
		local part = Instance.new("Part")
		part.Size = Vector3.new(1, 2.5, 1) -- 3배 확대
		part.Color = Color3.fromRGB(100, 200, 255)
		part.Material = Enum.Material.Neon
		part.Parent = slotViewport
		part.Material = Enum.Material.Neon
		part.Parent = slotViewport
	elseif itemId == "Bungeoppang" then
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
				print("[InventoryUI] Valid Bungeoppang Model found")
				model.Name = "InventoryItem"
				model:PivotTo(CFrame.new(0,0,0) * CFrame.Angles(math.rad(-20), math.rad(45), 0))
				model.Parent = slotViewport
			elseif model:IsA("Accessory") then
				print("[InventoryUI] Valid Bungeoppang Accessory found")
				local handle = model:FindFirstChild("Handle") or model:FindFirstChildWhichIsA("BasePart")
				
				if handle then
					print("[InventoryUI] Handle found: " .. handle.Name)
					
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
				print("[InventoryUI] Valid Bungeoppang Part found")
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
		-- Try to clone from Workspace
		local source = workspace:FindFirstChild("CatTrap")
		if source then
			local model = source:Clone()
			
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
		local part = Instance.new("Part")
		part.Size = Vector3.new(1.5, 1.5, 1.5) -- 3배 확대
		part.Color = Color3.fromRGB(150, 150, 150)
		part.Parent = slotViewport
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
	countLabel.TextSize = 14
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextColor3 = Color3.new(1, 1, 1)
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.Parent = slot
	
	-- 클릭 시 사용 모드 진입
	slot.MouseButton1Click:Connect(function()
		-- 인벤토리 창 닫기
		setInventoryVisible(false) -- [v4.25k] 통합 함수 사용
		
		-- 사용 모드 진입
		isUseMode = true
		selectedSlot = index
		useModeHint.Text = "🎯 " .. itemDef.Name .. " 배치할 곳 클릭 (ESC 취소)"
		useModeHint.Visible = true
		
		-- 3D 월드 프리뷰 생성
		createPreviewModel(itemId)
		
		-- 마우스 커서를 손 모양으로 변경
		mouse.Icon = "rbxasset://SystemCursors/PointingHand"
	end)
	
	-- 호버 효과
	slot.MouseEnter:Connect(function()
		slot.BackgroundColor3 = Color3.fromRGB(100, 100, 130)
	end)
	slot.MouseLeave:Connect(function()
		slot.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
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
local function cancelUseMode()
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
	
	-- UI 위 클릭은 무시
	local guiObjects = playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
	if #guiObjects > 0 then return end
	
	-- 유효한 지면 클릭 확인
	local mouseRay = mouse.UnitRay
	local result = getValidGroundRaycast(mouseRay.Origin, mouseRay.Direction * 1000)
	
	if result then
		-- 서버에 아이템 배치 요청 (레이캐스트 결과 위치 사용 + [New] 클릭된 대상 전달)
		-- 덫에 미끼를 놓는 경우를 위해 클릭된 파트(result.Instance)도 함께 보냄
		placeEvent:FireServer(selectedSlot, result.Position, result.Instance)
		cancelUseMode()
	end
end)

-- ESC로 사용 모드 취소
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Escape and isUseMode then
		cancelUseMode()
	end
end)

-- 이벤트 연결
invButton.MouseButton1Click:Connect(toggleInventory)
closeBtn.MouseButton1Click:Connect(function()
	setInventoryVisible(false) -- [v4.25k] 통합 함수 사용
end)
-- [Debug] 아이템 회전 조절 UI
local function createDebugUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "ItemRotationDebug"
	screen.Parent = playerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 150)
	frame.Position = UDim2.new(0.8, 0, 0.1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.Parent = screen
	
	local xVal, yVal, zVal = -90, 0, 0 -- 초기값 (기존 코드 기준)
	
	local function updateRotation()
		local foundCount = 0
		
		-- [Debug] PlayerGui 전체를 뒤져서 모든 ViewportFrame의 아이템을 회전시킵니다.
		local allDescendants = playerGui:GetDescendants()
		for _, vp in ipairs(allDescendants) do
			if vp:IsA("ViewportFrame") then
				-- 카메라 제외한 실제 아이템(BasePart/Model) 찾기
				local targetItem = nil
				for _, child in ipairs(vp:GetChildren()) do
					if (child:IsA("BasePart") or child:IsA("Model")) and not child:IsA("Camera") then
						targetItem = child
						break
					end
				end
				
				if targetItem then
					foundCount = foundCount + 1
					local cf = CFrame.new(0,0,0) * CFrame.Angles(math.rad(xVal), math.rad(yVal), math.rad(zVal))
					if targetItem:IsA("Model") then
						targetItem:PivotTo(cf)
					elseif targetItem:IsA("BasePart") then
						targetItem.CFrame = cf
					end
				end
			end
		end
		
		print(string.format("[Debug] Update Rotation: %.1f, %.1f, %.1f (Items Updated: %d)", xVal, yVal, zVal, foundCount))
	end
	
	local function createControl(name, yPos, getter, setter)
		local label = Instance.new("TextLabel")
		label.Text = name
		label.Size = UDim2.new(0.2, 0, 0, 30)
		label.Position = UDim2.new(0, 5, 0, yPos)
		label.TextColor3 = Color3.new(1,1,1)
		label.BackgroundTransparency = 1
		label.Parent = frame
		
		local minusBtn = Instance.new("TextButton")
		minusBtn.Text = "-"
		minusBtn.Size = UDim2.new(0, 30, 0, 30)
		minusBtn.Position = UDim2.new(0.2, 5, 0, yPos)
		minusBtn.Parent = frame
		
		local input = Instance.new("TextBox")
		input.Text = tostring(getter())
		input.Size = UDim2.new(0.3, -10, 0, 30)
		input.Position = UDim2.new(0.4, 0, 0, yPos)
		input.Parent = frame
		
		local plusBtn = Instance.new("TextButton")
		plusBtn.Text = "+"
		plusBtn.Size = UDim2.new(0, 30, 0, 30)
		plusBtn.Position = UDim2.new(0.7, 5, 0, yPos)
		plusBtn.Parent = frame
		
		local function update(val)
			setter(val)
			input.Text = tostring(val)
			updateRotation()
		end
		
		minusBtn.MouseButton1Click:Connect(function() update(getter() - 10) end)
		plusBtn.MouseButton1Click:Connect(function() update(getter() + 10) end)
		input.FocusLost:Connect(function()
			local n = tonumber(input.Text)
			if n then update(n) else input.Text = tostring(getter()) end
		end)

		return input
	end
	
	local xInput = createControl("X", 10, function() return xVal end, function(v) xVal = v end)
	local yInput = createControl("Y", 45, function() return yVal end, function(v) yVal = v end)
	local zInput = createControl("Z", 80, function() return zVal end, function(v) zVal = v end)
	
	local resetBtn = Instance.new("TextButton")
	resetBtn.Text = "RESET (-90,0,0)"
	resetBtn.Size = UDim2.new(0.9, 0, 0, 30)
	resetBtn.Position = UDim2.new(0.05, 0, 0, 115)
	resetBtn.Parent = frame
	resetBtn.MouseButton1Click:Connect(function()
		xVal, yVal, zVal = -90, 0, 0
		xInput.Text = "-90"; yInput.Text = "0"; zInput.Text = "0"
		updateRotation()
	end)
	
	updateRotation() -- 초기 적용
	
	-- [Fix] UI 갱신 시에도 회전값 적용되도록 글로벌 변수에 저장하여 접근
	_G.DebugUpdateRotation = updateRotation
end

-- [Debug] 실행 (필요 시 주석 해제하여 사용)
-- createDebugUI()

updateEvent.OnClientEvent:Connect(function(newInventory)
	print("[InventoryUI] Received inventory update. Item Count: " .. #newInventory)
	for i, v in ipairs(newInventory) do
		print(" - Slot " .. i .. ": " .. v.ItemId .. " x" .. v.Count)
	end
	inventory = newInventory
	refreshUI()
	
	-- [Debug] UI 갱신 후 회전값 다시 적용 (약간의 딜레이 필요할 수 있음)
	if _G.DebugUpdateRotation then
		task.delay(0.1, function()
			_G.DebugUpdateRotation()
		end)
	end
end)

-- [Added] Request initial data immediately on load to prevent race conditions
print("[InventoryUI] Requesting initial inventory...")
requestUpdateEvent:FireServer()

print("[InventoryUI] Initialized")
