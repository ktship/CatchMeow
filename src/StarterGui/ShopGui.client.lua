local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- UI 컨테이너 생성
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUIPanel"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true -- [Added] 상단바 시스템 여백 제거 (전체화면 기준)
screenGui.Enabled = false -- 기본적으로 숨김 상태
screenGui.DisplayOrder = 50 -- [Fixed] 최상단 배치
screenGui.Parent = player:WaitForChild("PlayerGui")

-- [Fixed] 중복 생성된 GUI 제거 (리스폰 시 꼬임 방지)
for _, child in ipairs(player.PlayerGui:GetChildren()) do
	if child.Name == "ShopUIPanel" and child ~= screenGui then
		child:Destroy()
	end
end

-- 배경 클릭 시 닫히도록 하는 투명 버튼
local bgButton = Instance.new("TextButton")
bgButton.Name = "BackgroundButton"
bgButton.Size = UDim2.new(1, 0, 1, 0)
bgButton.BackgroundTransparency = 1
bgButton.Text = ""
bgButton.Parent = screenGui


-- [Premium] 메인 프레임 (Cozy Apricot 스타일)
local mainFrame = Instance.new("CanvasGroup")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 500, 1, -180)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5) 
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- 화면 중앙
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 240) -- [Apricot] 배경
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

-- 클릭 흡수용 버튼 (CanvasGroup은 Active만으로 클릭 차단이 안될 수 있음)
local clickSink = Instance.new("TextButton")
clickSink.Name = "ClickSink"
clickSink.Size = UDim2.new(1, 0, 1, 0)
clickSink.BackgroundTransparency = 1
clickSink.Text = ""
clickSink.ZIndex = 1
clickSink.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2 
mainStroke.Color = Color3.fromRGB(255, 200, 150) -- [Apricot] 테두리
mainStroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(180, 100, 60)
titleLabel.TextSize = 32
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "상점"
titleLabel.Parent = mainFrame

-- 취소(닫기) 버튼 X 표시
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -10, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 110)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 24
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0) -- 원형
closeCorner.Parent = closeBtn

-- 내 코인 잔액 표시창
local balanceFrame = Instance.new("Frame")
balanceFrame.Name = "BalanceFrame"
balanceFrame.Size = UDim2.new(0, 100, 0, 40)
balanceFrame.AnchorPoint = Vector2.new(0, 0) -- 왼쪽을 기준으로 정렬
balanceFrame.Position = UDim2.new(0, 10, 0, 10) -- 상점 창 왼쪽 위 끝부분 여백 10 지점
balanceFrame.BackgroundColor3 = Color3.fromRGB(255, 230, 200)
balanceFrame.Parent = mainFrame

local balanceCorner = Instance.new("UICorner")
balanceCorner.CornerRadius = UDim.new(0, 12)
balanceCorner.Parent = balanceFrame

local balanceIcon = Instance.new("ImageLabel")
balanceIcon.Name = "BalanceIcon"
balanceIcon.Size = UDim2.new(0, 24, 0, 24)
balanceIcon.Position = UDim2.new(0, 8, 0.5, -12)
balanceIcon.BackgroundTransparency = 1
balanceIcon.Image = "rbxassetid://15589362394" -- 유저 지정 골드 코인 이미지 ID
balanceIcon.Parent = balanceFrame

local balanceLabel = Instance.new("TextLabel")
balanceLabel.Name = "BalanceLabel"
balanceLabel.Size = UDim2.new(1, -36, 1, 0)
balanceLabel.Position = UDim2.new(0, 36, 0, 0)
balanceLabel.BackgroundTransparency = 1
balanceLabel.TextColor3 = Color3.fromRGB(180, 100, 60)
balanceLabel.TextSize = 18
balanceLabel.Font = Enum.Font.GothamBold
balanceLabel.TextXAlignment = Enum.TextXAlignment.Left
balanceLabel.Text = "0"
balanceLabel.Parent = balanceFrame

-- leaderstats 코인 연동
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local coin = leaderstats:WaitForChild("Coin", 5)
		if coin then
			balanceLabel.Text = tostring(coin.Value)
			coin.Changed:Connect(function(newValue)
				balanceLabel.Text = tostring(newValue)
			end)
		end
	end
end)


-- 아이템 목록 스크롤 프레임
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ItemList"
scrollFrame.Size = UDim2.new(1, -40, 1, -80)
scrollFrame.Position = UDim2.new(0, 20, 0, 60)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 150, 120)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto-adjusted
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0, 4)
scrollPadding.PaddingRight = UDim.new(0, 8) -- 스크롤바 영역 고려
scrollPadding.PaddingTop = UDim.new(0, 4)
scrollPadding.PaddingBottom = UDim.new(0, 4)
scrollPadding.Parent = scrollFrame

-- 구매 연출 애니메이션 (화면 중앙 강조)
local function playPurchaseAnimation(itemId, name)
	local animFrame = Instance.new("Frame")
	animFrame.Name = "PurchaseAnimFrame"
	animFrame.Size = UDim2.new(1, 0, 1, 0)
	animFrame.BackgroundTransparency = 1
	animFrame.ZIndex = 100
	animFrame.Parent = screenGui
	
	-- 번쩍이는 배경 효과
	local flashBG = Instance.new("Frame")
	flashBG.Size = UDim2.new(1, 0, 1, 0)
	flashBG.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
	flashBG.BackgroundTransparency = 0.5
	flashBG.ZIndex = 100
	flashBG.Parent = animFrame
	TweenService:Create(flashBG, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	
	-- 컨테이너 (풀사이즈, UIScale로 애니메이션)
	local itemContainer = Instance.new("Frame")
	itemContainer.Size = UDim2.new(0, 250, 0, 250)
	itemContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	itemContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	itemContainer.BackgroundColor3 = Color3.fromRGB(255, 248, 230)
	itemContainer.BackgroundTransparency = 0.1
	itemContainer.ZIndex = 101
	itemContainer.Parent = animFrame
	
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0
	uiScale.Parent = itemContainer
	
	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 24)
	containerCorner.Parent = itemContainer
	
	local containerStroke = Instance.new("UIStroke")
	containerStroke.Thickness = 4
	containerStroke.Color = Color3.fromRGB(255, 220, 100)
	containerStroke.Parent = itemContainer
	
	-- 아이템 모델 ViewportFrame
	local vpFrame = Instance.new("ViewportFrame")
	vpFrame.Size = UDim2.new(1, 0, 1, 0)
	vpFrame.BackgroundTransparency = 1
	vpFrame.ZIndex = 102
	vpFrame.Parent = itemContainer
	
	local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
	local itemModel = itemsFolder and itemsFolder:FindFirstChild(itemId)
	if not itemModel then
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		itemModel = assets and assets:FindFirstChild(itemId)
	end
	
	local rsConnection
	if itemModel then
		local cloned = itemModel:Clone()
		local displayModel = cloned
		
		if cloned:IsA("Accessory") or cloned:IsA("Tool") then
			displayModel = cloned:FindFirstChild("Handle") or cloned:FindFirstChildWhichIsA("BasePart")
			if displayModel then
				displayModel.Parent = nil
			end
			cloned:Destroy()
		end
		
		if not displayModel then
			displayModel = Instance.new("Part")
			displayModel.Size = Vector3.new(1.5, 1.5, 1.5)
			displayModel.Color = Color3.fromRGB(150, 150, 150)
		end
		
		-- 투명도 강제 보정
		if displayModel:IsA("BasePart") and displayModel.Transparency > 0.9 then
			displayModel.Transparency = 0
		elseif displayModel:IsA("Model") then
			for _, part in ipairs(displayModel:GetDescendants()) do
				if part:IsA("BasePart") and part.Transparency > 0.9 then
					part.Transparency = 0
				end
			end
		end
		
		local maxDim = 2
		if displayModel:IsA("Model") then
			displayModel:PivotTo(CFrame.new(Vector3.zero))
			if itemId == "CatCan" or itemId == "SpeedBoost" then
				displayModel:PivotTo(CFrame.new(Vector3.zero) * CFrame.Angles(0, 0, math.rad(90)))
			end
			local size = displayModel:GetExtentsSize()
			maxDim = math.max(size.X, size.Y, size.Z)
		elseif displayModel:IsA("BasePart") then
			displayModel.CFrame = CFrame.new(Vector3.zero)
			local size = displayModel.Size
			maxDim = math.max(size.X, size.Y, size.Z)
		end
		displayModel.Parent = vpFrame
		
		local camera = Instance.new("Camera")
		local zoomFactor = 1.0
		if itemId == "Bungeoppang" then zoomFactor = 0.7 end
		camera.CFrame = CFrame.new(Vector3.new(0, 0.5, 1.5).Unit * (maxDim * zoomFactor), Vector3.zero)
		vpFrame.CurrentCamera = camera
		camera.Parent = vpFrame
		
		-- 회전 애니메이션
		local angle = 0
		rsConnection = RunService.RenderStepped:Connect(function(dt)
			if not vpFrame.Parent then
				if rsConnection then rsConnection:Disconnect() end
				return
			end
			angle = angle + dt * 0.8
			local offset = CFrame.Angles(0, angle, 0)
			camera.CFrame = CFrame.lookAt(
				offset * (Vector3.new(0, 0.2, 1).Unit * (maxDim * zoomFactor)),
				Vector3.zero
			)
		end)
	end
	
	-- 텍스트
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0, 400, 0, 60)
	nameLbl.Position = UDim2.new(0.5, -200, 1, 20)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3 = Color3.fromRGB(240, 100, 60)
	nameLbl.TextStrokeTransparency = 0
	nameLbl.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.TextSize = 40
	nameLbl.Font = Enum.Font.GothamBlack
	nameLbl.Text = name .. " 구매 완료!"
	nameLbl.ZIndex = 103
	nameLbl.Parent = itemContainer
	
	-- 등장 애니메이션 (UIScale 팝업)
	TweenService:Create(uiScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	}):Play()
	
	-- 체류 및 퇴장
	task.delay(1.5, function()
		TweenService:Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Scale = 0
		}):Play()
		
		task.delay(0.5, function()
			if rsConnection then rsConnection:Disconnect() end
			animFrame:Destroy()
		end)
	end)
end

-- 실제 아이템 카드 생성 함수
local function createItemCard(itemId, name, price, desc)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 100)
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	card.Parent = scrollFrame
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Thickness = 1
	cardStroke.Color = Color3.fromRGB(255, 220, 180)
	cardStroke.Parent = card
	
	-- 아이콘 (ViewportFrame 적용)
	local vpFrame = Instance.new("ViewportFrame")
	vpFrame.Size = UDim2.new(0, 80, 0, 80)
	vpFrame.Position = UDim2.new(0, 10, 0, 10)
	vpFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	vpFrame.Parent = card
	
	local vpCorner = Instance.new("UICorner")
	vpCorner.CornerRadius = UDim.new(0, 8)
	vpCorner.Parent = vpFrame
	
	local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
	local itemModel = itemsFolder and itemsFolder:FindFirstChild(itemId)
	if not itemModel then
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		itemModel = assets and assets:FindFirstChild(itemId)
	end
	
	if itemModel then
		local cloned = itemModel:Clone()
		local displayModel = cloned
		
		if cloned:IsA("Accessory") or cloned:IsA("Tool") then
			displayModel = cloned:FindFirstChild("Handle") or cloned:FindFirstChildWhichIsA("BasePart")
			if displayModel then
				displayModel.Parent = nil
			end
			cloned:Destroy()
		end
		
		if not displayModel then
			displayModel = Instance.new("Part")
			displayModel.Size = Vector3.new(1.5, 1.5, 1.5)
			displayModel.Color = Color3.fromRGB(150, 150, 150)
		end
		
		-- 투명도 강제 보정 (ViewportFrame에서 안 보이는 현상 방지)
		if displayModel:IsA("BasePart") and displayModel.Transparency > 0.9 then
			displayModel.Transparency = 0
		elseif displayModel:IsA("Model") then
			for _, part in ipairs(displayModel:GetDescendants()) do
				if part:IsA("BasePart") and part.Transparency > 0.9 then
					part.Transparency = 0
				end
			end
		end
		
		local maxDim = 2
		if displayModel:IsA("Model") then
			displayModel:PivotTo(CFrame.new(Vector3.zero))
			if itemId == "CatCan" or itemId == "SpeedBoost" then
				displayModel:PivotTo(CFrame.new(Vector3.zero) * CFrame.Angles(0, 0, math.rad(90)))
			end
			local size = displayModel:GetExtentsSize()
			maxDim = math.max(size.X, size.Y, size.Z)
		elseif displayModel:IsA("BasePart") then
			displayModel.CFrame = CFrame.new(Vector3.zero)
			local size = displayModel.Size
			maxDim = math.max(size.X, size.Y, size.Z)
		end
		
		displayModel.Parent = vpFrame
		
		local camera = Instance.new("Camera")
		local zoomFactor = 1.1
		if itemId == "Bungeoppang" then zoomFactor = 0.8 end -- 붕어빵일 경우 특별히 더 크게 확대 (1.1 -> 0.8)
		
		camera.CFrame = CFrame.new(Vector3.new(1.5, 1, 1.5).Unit * (maxDim * zoomFactor), Vector3.zero)
		vpFrame.CurrentCamera = camera
		camera.Parent = vpFrame
		
		-- 회전 애니메이션
		local angle = 0
		RunService.RenderStepped:Connect(function(dt)
			if not vpFrame.Parent or not screenGui.Enabled then return end
			angle = angle + dt * 0.5
			local offset = CFrame.Angles(0, angle, 0)
			local rotZoom = 1.2
			if itemId == "Bungeoppang" then rotZoom = 0.9 end
			
			camera.CFrame = CFrame.new(offset * (Vector3.new(0, 0.4, 1).Unit * (maxDim * rotZoom)))
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, Vector3.zero)
		end)
	else
		-- 모델 없는 경우의 임시 아이콘 지원
		local fallbackIcon = Instance.new("ImageLabel")
		fallbackIcon.Size = UDim2.new(1, 0, 1, 0)
		fallbackIcon.BackgroundTransparency = 1
		fallbackIcon.Image = "rbxassetid://15589362394" -- 골드코인처럼 더미아이콘
		fallbackIcon.Parent = vpFrame
	end
	
	-- 아이템 이름
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -220, 0, 30)
	nameLbl.Position = UDim2.new(0, 100, 0, 10)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3 = Color3.fromRGB(80, 50, 40)
	nameLbl.TextSize = 22
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Text = name
	nameLbl.Parent = card
	
	-- 설명
	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(1, -220, 0, 40)
	descLbl.Position = UDim2.new(0, 100, 0, 45)
	descLbl.BackgroundTransparency = 1
	descLbl.TextColor3 = Color3.fromRGB(150, 120, 100)
	descLbl.TextSize = 15
	descLbl.Font = Enum.Font.GothamMedium
	descLbl.TextWrapped = true
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextYAlignment = Enum.TextYAlignment.Top
	descLbl.Text = desc
	descLbl.Parent = card
	
	-- 구매 버튼
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 100, 0, 40)
	buyBtn.AnchorPoint = Vector2.new(1, 0.5)
	buyBtn.Position = UDim2.new(1, -10, 0.5, 0)
	buyBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 120)
	buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.TextSize = 18
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.Text = price .. " 구매"
	buyBtn.Parent = card
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = buyBtn
	
	buyBtn.MouseButton1Click:Connect(function()
		local leaderstats = player:FindFirstChild("leaderstats")
		local currentCoin = 0
		if leaderstats and leaderstats:FindFirstChild("Coin") then
			currentCoin = leaderstats.Coin.Value
		end
		
		if currentCoin >= tonumber(price) then
			-- 구매가 가능할 때의 클라이언트 측 연출
			playPurchaseAnimation(itemId, name)
			
			-- 이후 서버쪽으로 실제 구매 처리 요청
			local eventsInfo = ReplicatedStorage:FindFirstChild("Events")
			local buyEvent = eventsInfo and eventsInfo:FindFirstChild("BuyItem")
			if buyEvent then
				buyEvent:FireServer(itemId)
			end
		else
			-- 코인이 부족할 때의 피드백 연출 (버튼 흔들리고 빨강색)
			buyBtn.Text = "코인 부족!"
			buyBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
			
			local originalPos = buyBtn.Position
			TweenService:Create(buyBtn, TweenInfo.new(0.05, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 4, true), {
				Position = originalPos + UDim2.new(0, 5, 0, 0)
			}):Play()
			
			task.delay(1, function()
				buyBtn.Text = price .. " 구매"
				buyBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 120)
				buyBtn.Position = originalPos
			end)
		end
	end)
end

-- UI 연동 및 애니메이션 처리
local function openShop()
	-- 카메라 원상복구 및 배낭(Backpack) 숨김 등
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	
	mainFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
	mainFrame.GroupTransparency = 1
	TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		GroupTransparency = 0
	}):Play()
end

local isShopClosing = false

local function closeShop()
	if isShopClosing then return end
	isShopClosing = true
	
	TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.55, 0),
		GroupTransparency = 1
	}):Play()
	
	task.delay(0.3, function()
		screenGui.Enabled = false
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		isShopClosing = false
	end)
end

closeBtn.MouseButton1Click:Connect(closeShop)
bgButton.MouseButton1Click:Connect(closeShop)

screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if screenGui.Enabled then
		openShop()
	end
end)

local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local shopItems = {"CatTrap", "Bungeoppang", "CatCan", "CatChuru", "Stick", "SpeedBoost"}

for _, itemId in ipairs(shopItems) do
	local data = ItemData.GetItem(itemId)
	if data then
		createItemCard(itemId, data.Name, tostring(data.Price), data.Description)
	end
end

print("ShopGui Initialized")
