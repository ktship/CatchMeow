local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local QuestManager = require(ReplicatedStorage:WaitForChild("QuestSystem"):WaitForChild("QuestManager"))
local QuestData = require(ReplicatedStorage:WaitForChild("QuestSystem"):WaitForChild("QuestData"))

-- UI 생성
local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- [Theme Colors] Sunny Orange
local Colors = {
	Primary = Color3.fromRGB(255, 170, 0), -- 진한 오렌지 (헤더, 강조)
	Background = Color3.fromRGB(245, 240, 230), -- [Modified] 조금 더 진한 크림색
	Card = Color3.fromRGB(255, 255, 255), -- 흰색 (카드)
	Stroke = Color3.fromRGB(254, 230, 133), -- [Modified] 사용자 요청 테두리색
	TextTitle = Color3.fromRGB(90, 60, 50), -- 진한 갈색
	TextBody = Color3.fromRGB(140, 100, 80), -- 중간 갈색
	TextHighlight = Color3.fromRGB(255, 140, 0), -- 오렌지 텍스트
	CloseBtn = Color3.fromRGB(255, 255, 255), -- 닫기 버튼 (배경 x, 아이콘 o)
}

-- 메인 프레임 (투명 컨테이너)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 500) -- [Modified] 화면 중앙 배치 및 크기 확대
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- [Modified] 중앙 기준
mainFrame.Position = UDim2.new(0.5, 0, 0.4, 0) -- [Modified] 화면 중앙보다 약간 위 (카메라 아이콘 겹침 방지)
mainFrame.BackgroundTransparency = 1
mainFrame.Visible = false 
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

-- 1. 헤더 (Header)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Colors.Primary
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

-- 헤더 하단 직각 처리 (바디와 연결)
local headerCover = Instance.new("Frame")
headerCover.Name = "CornerCover"
headerCover.Size = UDim2.new(1, 0, 0, 10)
headerCover.Position = UDim2.new(0, 0, 1, -10)
headerCover.BackgroundColor3 = Colors.Primary
headerCover.BorderSizePixel = 0
headerCover.Parent = header

-- 헤더 아이콘 & 타이틀 (텍스트로 변경)
local headerIcon = Instance.new("TextLabel")
headerIcon.Name = "Icon"
headerIcon.Size = UDim2.new(0, 24, 0, 24)
headerIcon.Position = UDim2.new(0, 15, 0.5, 0)
headerIcon.AnchorPoint = Vector2.new(0, 0.5)
headerIcon.BackgroundTransparency = 1
headerIcon.Text = "📜" -- [Modified] 이모지 아이콘
headerIcon.Font = Enum.Font.GothamBold
headerIcon.TextSize = 28 -- [Modified] 24 -> 28
headerIcon.TextColor3 = Color3.new(1, 1, 1)
headerIcon.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Name = "Title"
headerTitle.Size = UDim2.new(1, -80, 1, 0)
headerTitle.Position = UDim2.new(0, 45, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "퀘스트 목록"
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextSize = 28 -- [Modified] 24 -> 28
headerTitle.TextColor3 = Color3.new(1, 1, 1)
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

-- 닫기 버튼 (원형)
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
body.Parent = mainFrame

local bodyCorner = Instance.new("UICorner")
bodyCorner.CornerRadius = UDim.new(0, 16)
bodyCorner.Parent = body

-- 바디 상단 직각 처리 (헤더와 연결)
local bodyCover = Instance.new("Frame")
bodyCover.Name = "CornerCover"
bodyCover.Size = UDim2.new(1, 0, 0, 10)
bodyCover.Position = UDim2.new(0, 0, 0, 0)
bodyCover.BackgroundColor3 = Colors.Background
bodyCover.BorderSizePixel = 0
bodyCover.Parent = body

-- 탭 메뉴 (Tab Menu)
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -30, 0, 40)
tabContainer.Position = UDim2.new(0.5, 0, 0, 10)
tabContainer.AnchorPoint = Vector2.new(0.5, 0)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = body

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 10)
tabLayout.Parent = tabContainer

local function createTab(name, text, isActive, layoutOrder)
	local tab = Instance.new("TextButton")
	tab.Name = name
	tab.Size = UDim2.new(0.5, -5, 1, 0)
	tab.BackgroundColor3 = isActive and Colors.Primary or Color3.new(1, 1, 1)
	tab.Text = text
	tab.Font = Enum.Font.GothamBold
	tab.TextSize = 22 -- [Modified] 18 -> 22
	tab.TextColor3 = isActive and Color3.new(1, 1, 1) or Colors.TextTitle
	tab.AutoButtonColor = true
	tab.LayoutOrder = layoutOrder
	tab.Parent = tabContainer
	
	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 12)
	tabCorner.Parent = tab
	
	if not isActive then
		local tabStroke = Instance.new("UIStroke")
		tabStroke.Color = Colors.Stroke
		tabStroke.Thickness = 1.5
		tabStroke.Parent = tab
	end
	
	return tab
end

local activeTab = createTab("ActiveTab", "진행 중 (0)", true, 1)
local completedTab = createTab("CompletedTab", "완료됨 (0)", false, 2)

-- 스크롤 프레임 (Quest List)
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "QuestList"
scrollFrame.Size = UDim2.new(1, -30, 1, -70) -- 탭 높이 + 여백 제외
scrollFrame.Position = UDim2.new(0.5, 0, 0, 60)
scrollFrame.AnchorPoint = Vector2.new(0.5, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Colors.Primary
scrollFrame.Parent = body

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 12) -- 카드 간격
listLayout.Parent = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 5)
listPadding.PaddingBottom = UDim.new(0, 20) -- [Modified] 하단 여백 확대
listPadding.PaddingLeft = UDim.new(0, 5) -- [Modified] 좌측 여백 추가
listPadding.PaddingRight = UDim.new(0, 5) -- [Modified] 우측 여백 추가
listPadding.Parent = scrollFrame


-- 사이드 메뉴 컨테이너 (화면 왼쪽 하단)
local menuContainer = Instance.new("Frame")
menuContainer.Name = "MenuContainer"
menuContainer.Size = UDim2.new(0, 50, 0, 300) -- [Modified] Width 60 -> 50 for consistent spacing
menuContainer.Position = UDim2.new(0, 20, 1, -20) -- 왼쪽 하단 여백 20
menuContainer.AnchorPoint = Vector2.new(0, 1) -- 좌측 하단 기준
menuContainer.BackgroundTransparency = 1
menuContainer.Parent = screenGui

local menuLayout = Instance.new("UIListLayout")
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
menuLayout.Padding = UDim.new(0, 10)
menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
menuLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom -- 맨 아래 정렬
menuLayout.Parent = menuContainer

-- 퀘스트 버튼
local questButton = Instance.new("TextButton")
questButton.Name = "QuestButton"
questButton.Size = UDim2.new(0, 50, 0, 50)
questButton.BackgroundColor3 = Color3.fromRGB(180, 110, 70) 
questButton.BackgroundTransparency = 0 
questButton.Text = "📜" 
questButton.TextSize = 25 
questButton.LayoutOrder = 1
questButton.Parent = menuContainer

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = questButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Thickness = 3 -- [Modified] 더 두껍게 (인벤토리 버튼처럼)
btnStroke.Color = Color3.fromRGB(160, 90, 50) -- [Modified] 인벤토리 버튼과 동일한 테두리 색상
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
btnStroke.Parent = questButton

-- 알림 배지 (새 퀘스트 표시)
local notifBadge = Instance.new("TextLabel")
notifBadge.Name = "NotificationBadge"
notifBadge.Size = UDim2.new(0, 18, 0, 18)
notifBadge.Position = UDim2.new(1, -5, 0, -5) -- 우측 상단 걸치기
notifBadge.AnchorPoint = Vector2.new(1, 0)
notifBadge.BackgroundColor3 = Color3.fromRGB(255, 80, 80) 
notifBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
notifBadge.Text = "N"
notifBadge.Font = Enum.Font.GothamBold
notifBadge.TextSize = 12
notifBadge.Visible = false -- 기본 숨김
notifBadge.Parent = questButton

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(1, 0) -- 원형
badgeCorner.Parent = notifBadge

-- 버튼 클릭 이벤트 (퀘스트 버튼)
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

-- 버튼 클릭 이벤트 (퀘스트 버튼)
questButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	backgroundBtn.Visible = mainFrame.Visible -- [Added] 배경 버튼 가시성 동기화
	if mainFrame.Visible then
		notifBadge.Visible = false -- 열면 배지 숨김
	end
end)

-- 닫기 버튼 이벤트
closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	backgroundBtn.Visible = false -- [Added] 배경 버튼 숨김
end)

-- 배경 클릭 시 닫기
backgroundBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	backgroundBtn.Visible = false
end)

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2
uiStroke.Color = Colors.Stroke -- [Modified] 변수 사용
uiStroke.Parent = mainFrame

-- 퀘스트 카드 생성 함수
local function createQuestCard(questId, questState)
	local data = QuestData[questId]
	if not data then return end
	
	local card = Instance.new("Frame")
	card.Name = questId
	card.Size = UDim2.new(1, -6, 0, 0) -- [Modified] 좌우 여백 확보 (Outline 짤림 방지)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Colors.Card
	card.BorderSizePixel = 0 
	card.Parent = scrollFrame
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Colors.Stroke
	cardStroke.Thickness = 2
	cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- [Added] 아웃라인 모드
	cardStroke.Parent = card
	
	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingTop = UDim.new(0, 15)
	cardPadding.PaddingBottom = UDim.new(0, 15)
	cardPadding.PaddingLeft = UDim.new(0, 15)
	cardPadding.PaddingRight = UDim.new(0, 15)
	cardPadding.Parent = card
	
	-- 아이콘 + 타이틀 컨테이너
	local headerContainer = Instance.new("Frame")
	headerContainer.Name = "Header"
	headerContainer.Size = UDim2.new(1, 0, 0, 24)
	headerContainer.BackgroundTransparency = 1
	headerContainer.Parent = card
	
	-- [Removed] 번개 아이콘 제거 (사용자 요청에 의해 삭제됨)
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 1, 0) -- [Modified] 아이콘/화살표 제거로 전체 너비 사용
	title.Position = UDim2.new(0, 0, 0, 0) -- [Modified] 왼쪽 정렬 (아이콘 제거됨)
	title.BackgroundTransparency = 1
	title.Text = data.Title
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24 -- [Modified] 19 -> 24
	title.TextColor3 = Colors.TextTitle
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = headerContainer
	
	-- [Removed] 화살표 아이콘 제거 (사용자 요청에 의해 삭제됨)
	
	-- 설명 (Description)
	local desc = Instance.new("TextLabel")
	desc.Name = "Description"
	desc.Size = UDim2.new(1, 0, 0, 0) -- AutomaticSize
	desc.AutomaticSize = Enum.AutomaticSize.Y
	desc.BackgroundTransparency = 1
	-- [Modified] 설명 텍스트 : QuestData의 Summary 또는 Objectives의 첫번째 설명 사용
	-- 여기서는 간단히 첫번째 목표의 설명을 표시
	local descText = "퀘스트 설명이 없습니다."
	local totalReq = 0
	local currentCount = 0
	
	if type(questState) == "table" and questState.Objectives then
		local obj = questState.Objectives[1]
		if obj then
			descText = obj.Description or "목표를 달성하세요"
			totalReq = obj.RequiredCount or 1
			currentCount = obj.CurrentCount or 0
		end
	end
	
	desc.Text = descText
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 20 -- [Modified] 16 -> 20
	desc.TextColor3 = Colors.TextBody
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.Parent = card
	
	-- 진행도 (Progress)
	local progressContainer = Instance.new("Frame")
	progressContainer.Name = "Progress"
	progressContainer.Size = UDim2.new(1, 0, 0, 20)
	progressContainer.BackgroundTransparency = 1
	progressContainer.Parent = card
	
	-- [Removed] '진행도' 텍스트 제거 (사용자 요청에 의해 삭제됨)
	
	local fractionLabel = Instance.new("TextLabel")
	fractionLabel.Size = UDim2.new(0, 50, 1, 0)
	fractionLabel.Position = UDim2.new(1, 0, 0, 0)
	fractionLabel.AnchorPoint = Vector2.new(1, 0)
	fractionLabel.BackgroundTransparency = 1
	fractionLabel.Text = string.format("%d / %d", currentCount, totalReq)
	fractionLabel.Font = Enum.Font.GothamBold
	fractionLabel.TextSize = 18 -- [Modified] 14 -> 18
	fractionLabel.TextColor3 = Colors.TextHighlight
	fractionLabel.TextXAlignment = Enum.TextXAlignment.Right
	fractionLabel.Parent = progressContainer
	
	-- Progress Bar BG
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, 0, 0, 6)
	barBg.Position = UDim2.new(0, 0, 1, 5)
	barBg.BackgroundColor3 = Color3.fromRGB(255, 245, 230)
	barBg.BorderSizePixel = 0
	barBg.Parent = progressContainer
	
	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(1, 0)
	barBgCorner.Parent = barBg
	
	-- Progress Bar Fill
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	local percent = math.clamp(currentCount / math.max(totalReq, 1), 0, 1)
	barFill.Size = UDim2.new(percent, 0, 1, 0)
	barFill.BackgroundColor3 = Colors.Primary
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	
	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(1, 0)
	barFillCorner.Parent = barFill
	
	-- 카드 레이아웃 (수직 정렬)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = card
	
	-- 리스트 레이아웃 순서 적용을 위해 부모 재설정 (UIListLayout이 형제 요소를 관리하므로)
	headerContainer.LayoutOrder = 1
	desc.LayoutOrder = 2
	progressContainer.LayoutOrder = 3
end


-- UI 업데이트 함수
local function updateUI()
	-- 기존 항목 제거
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	local activeCount = 0
	local completedCount = 0
	
	-- 퀘스트 목록 순회하여 카운트 계산 및 생성
	for questId, questState in pairs(QuestManager.CurrentQuests) do
		if questState.Status == "Active" then
			activeCount = activeCount + 1
			-- [TODO] 현재 탭이 'Active'일 때만 생성
			createQuestCard(questId, questState)
		elseif questState.Status == "Completed" then
			completedCount = completedCount + 1
		end
	end
	
	-- 탭 텍스트 업데이트
	activeTab.Text = string.format("진행 중 (%d)", activeCount)
	completedTab.Text = string.format("완료됨 (%d)", completedCount)
end

-- 퀘스트 업데이트 이벤트 연결
local questUpdateEvent = ReplicatedStorage:WaitForChild("QuestRemotes"):WaitForChild("QuestUpdate")
questUpdateEvent.OnClientEvent:Connect(function(updatedQuests)
	QuestManager.CurrentQuests = updatedQuests
	updateUI()
    
    if not mainFrame.Visible then
        notifBadge.Visible = true
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 1, true)
        TweenService:Create(notifBadge, tweenInfo, {Size = UDim2.new(0, 24, 0, 24)}):Play()
    end
end)

-- J키 토글
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.J then
		mainFrame.Visible = not mainFrame.Visible
		if mainFrame.Visible then
			notifBadge.Visible = false
		end
	end
end)

updateUI()
print("QuestUI Redesigned Initialized")
