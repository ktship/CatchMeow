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

-- UI 생성
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 인벤토리 버튼 (우측 중단)
local invButton = Instance.new("TextButton")
invButton.Name = "InventoryButton"
invButton.Size = UDim2.new(0, 60, 0, 60)
invButton.Position = UDim2.new(1, -80, 0.5, -30) -- 우측 중앙 위쪽
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
winCorner.CornerRadius = UDim.new(0, 16)
winCorner.Parent = invWindow

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
			
			-- Accessory 내부의 Handle과 그 자식들을 복사해서 새 모델에 넣음
			local handle = sourceItem:FindFirstChild("Handle")
			if handle then
				local newHandle = handle:Clone()
				newHandle.Name = "Handle"
				newHandle.Anchored = true
				newHandle.CanCollide = false
				newHandle.Parent = model
				model.PrimaryPart = newHandle
				
				-- 크기 확대 (2.5배)
				local scale = 3
				newHandle.Size = newHandle.Size * scale
				local mesh = newHandle:FindFirstChildOfClass("SpecialMesh")
				if mesh then
					mesh.Scale = mesh.Scale * scale
				end
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
				part:PivotTo(CFrame.new(0,0,0) * CFrame.Angles(math.rad(90), 0, 0))
			else
				part.CFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(90), 0, 0)
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
	else
		print("[InventoryUI] destroyPreviewModel called but no model.")
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
			-- 허공이거나 유효한 지면이 없으면 안 보임
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
				model:PivotTo(CFrame.new(0,0,0) * CFrame.Angles(math.rad(-20), math.rad(45), 0))
			elseif model:IsA("Accessory") then
				print("[InventoryUI] Valid Bungeoppang Accessory found")
				local handle = model:FindFirstChild("Handle") or model:FindFirstChildWhichIsA("BasePart")
				
				if handle then
					print("[InventoryUI] Handle found: " .. handle.Name)
					
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
						-- 명시적으로 0으로 설정
						handle.Transparency = 0
					end
				else
					warn("[InventoryUI] NO Handle found in Accessory! Creating fallback part.")
					local p = Instance.new("Part")
					p.Name = "FallbackHandle"
					p.Size = Vector3.new(1.5, 1.5, 1.5)
					p.Color = Color3.fromRGB(255, 0, 0) -- Red for error
					p.CFrame = CFrame.new(0,0,0)
					p.Parent = model
				end
			else
				warn("[InventoryUI] Bungeoppang is neither Model nor Accessory? Type: " .. model.ClassName)
				model.CFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(-20), math.rad(45), 0)
			end
			model.Parent = slotViewport
		else
			-- Fallback
			local part = Instance.new("Part")
			part.Size = Vector3.new(1.5, 1.5, 1.5)
			part.Color = Color3.fromRGB(255, 170, 80)
			part.Parent = slotViewport
		end
	elseif itemId == "CatTrap" then
		-- Try to clone from Workspace
		local source = workspace:FindFirstChild("CatTrap")
		if source then
			local model = source:Clone()
			
			-- Center it
			local targetCF = CFrame.new(0,0,0) * CFrame.Angles(0, math.rad(45), 0)
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
			part.CFrame = CFrame.Angles(0, math.rad(45), 0)
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
		invWindow.Visible = false
		
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
local isOpen = false
local function toggleInventory()
	isOpen = not isOpen
	invWindow.Visible = isOpen
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
		-- 서버에 아이템 배치 요청 (레이캐스트 결과 위치 사용)
		placeEvent:FireServer(selectedSlot, result.Position)
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
	isOpen = false
	invWindow.Visible = false
end)

updateEvent.OnClientEvent:Connect(function(newInventory)
	print("[InventoryUI] Received inventory update. Item Count: " .. #newInventory)
	for i, v in ipairs(newInventory) do
		print(" - Slot " .. i .. ": " .. v.ItemId .. " x" .. v.Count)
	end
	inventory = newInventory
	refreshUI()
end)

-- [Added] Request initial data immediately on load to prevent race conditions
print("[InventoryUI] Requesting initial inventory...")
requestUpdateEvent:FireServer()

print("[InventoryUI] Initialized")
