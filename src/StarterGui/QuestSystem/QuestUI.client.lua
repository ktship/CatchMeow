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

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0.5, 0) -- [Modified] 높이를 화면 비율(50%)로 변경
mainFrame.AnchorPoint = Vector2.new(0, 1) -- [Modified] 좌측 하단 기준
mainFrame.Position = UDim2.new(0.02, 0, 1, -80) -- [Modified] 버튼 바로 위에 위치 (겹침 방지)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 240) -- [Apricot] 테마
mainFrame.BackgroundTransparency = 0.1
mainFrame.Visible = false -- 초기에는 숨김 (버튼이나 J키로 토글)
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainFrame

-- [Added] 사이드 메뉴 컨테이너 (화면 왼쪽 하단)
local menuContainer = Instance.new("Frame")
menuContainer.Name = "MenuContainer"
menuContainer.Size = UDim2.new(0, 60, 0, 300)
menuContainer.Position = UDim2.new(0, 20, 1, -20) -- 왼쪽 하단 여백 20
menuContainer.AnchorPoint = Vector2.new(0, 1) -- 좌측 하단 기준
menuContainer.BackgroundTransparency = 1
menuContainer.Parent = screenGui

local menuLayout = Instance.new("UIListLayout")
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
menuLayout.Padding = UDim.new(0, 10)
menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
menuLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom -- [Modified] 맨 아래 정렬
menuLayout.Parent = menuContainer

-- [Added] 퀘스트 버튼 (텍스트/이모지 기반으로 변경)
local questButton = Instance.new("TextButton")
questButton.Name = "QuestButton"
questButton.Size = UDim2.new(0, 50, 0, 50)
questButton.BackgroundColor3 = Color3.fromRGB(180, 110, 70) -- [Apricot] 더 진한 갈색/오렌지 (아이콘 대비)
questButton.BackgroundTransparency = 0 -- 배경 불투명하게 변경 (잘 보이도록)
questButton.Text = "📜" -- 이모지 아이콘
questButton.TextSize = 25 -- [Modified] 아이콘 크기 조금 줄임 (30 -> 25)
questButton.LayoutOrder = 1
questButton.Parent = menuContainer

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = questButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Thickness = 2
btnStroke.Color = Color3.fromRGB(255, 200, 150) -- [Apricot] 테두리
btnStroke.Parent = questButton

-- [Added] 알림 배지 (새 퀘스트 표시)
local notifBadge = Instance.new("TextLabel")
notifBadge.Name = "NotificationBadge"
notifBadge.Size = UDim2.new(0, 18, 0, 18)
notifBadge.Position = UDim2.new(1, -5, 0, -5) -- 우측 상단 걸치기
notifBadge.AnchorPoint = Vector2.new(1, 0)
notifBadge.BackgroundColor3 = Color3.fromRGB(255, 80, 80) -- 빨간색
notifBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
notifBadge.Text = "N"
notifBadge.Font = Enum.Font.GothamBold
notifBadge.TextSize = 12
notifBadge.Visible = false -- 기본 숨김
notifBadge.Parent = questButton

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(1, 0) -- 원형
badgeCorner.Parent = notifBadge

-- 버튼 클릭 이벤트
questButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	if mainFrame.Visible then
		notifBadge.Visible = false -- 열면 배지 숨김
	end
end)

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(255, 200, 150)
uiStroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "퀘스트 목록"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 24
titleLabel.TextColor3 = Color3.fromRGB(180, 100, 60)
titleLabel.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "QuestList"
scrollFrame.Size = UDim2.new(0.9, 0, 0.85, -40)
scrollFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ScrollBarThickness = 4
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

-- 퀘스트 항목 생성 함수
local function createQuestItem(questId, questState)
	local data = QuestData[questId]
	if not data then return end
	
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = questId
	itemFrame.Size = UDim2.new(1, 0, 0, 80) -- 기본 높이
	itemFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	itemFrame.BackgroundTransparency = 0.5
	itemFrame.Parent = scrollFrame
	
	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 8)
	itemCorner.Parent = itemFrame
	
	local qTitle = Instance.new("TextLabel")
	qTitle.Size = UDim2.new(1, -10, 0, 25)
	qTitle.Position = UDim2.new(0, 5, 0, 5)
	qTitle.BackgroundTransparency = 1
	qTitle.Text = data.Title
	qTitle.Font = Enum.Font.GothamSemibold
	qTitle.TextSize = 18
	qTitle.TextColor3 = Color3.fromRGB(90, 60, 50)
	qTitle.TextXAlignment = Enum.TextXAlignment.Left
	qTitle.Parent = itemFrame
	
	-- 목표 표시
	local objectivesText = ""
    local objectivesInfo = nil
    -- QuestState가 테이블이면 Objectives를 가져오고, 아니면 빈 테이블 처리
    if type(questState) == "table" and questState.Objectives then
        objectivesInfo = questState.Objectives
    end

    if objectivesInfo then
        for _, obj in ipairs(objectivesInfo) do
            local current = obj.CurrentCount or 0
            local required = obj.RequiredCount or 1
            local desc = obj.Description or "목표"
            objectivesText = objectivesText .. string.format("- %s (%d/%d)\n", desc, current, required)
        end
    end
	
	local qDesc = Instance.new("TextLabel")
	qDesc.Size = UDim2.new(1, -10, 0, 40)
	qDesc.Position = UDim2.new(0, 5, 0, 30)
	qDesc.BackgroundTransparency = 1
	qDesc.Text = objectivesText
	qDesc.Font = Enum.Font.Gotham
	qDesc.TextSize = 14
	qDesc.TextColor3 = Color3.fromRGB(120, 90, 80)
	qDesc.TextXAlignment = Enum.TextXAlignment.Left
	qDesc.TextYAlignment = Enum.TextYAlignment.Top
	qDesc.TextWrapped = true
	qDesc.Parent = itemFrame
end

-- UI 업데이트 함수
local function updateUI()
	-- 기존 항목 제거
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- 퀘스트 목록 순회 및 생성
	for questId, questState in pairs(QuestManager.CurrentQuests) do
		if questState.Status == "Active" then
			createQuestItem(questId, questState)
		end
	end
end

-- 퀘스트 업데이트 이벤트 연결
-- QuestManager가 업데이트 될 때마다 호출되어야 함 (QuestManager에 Signal 추가 필요)
-- 임시로 Polling 또는 RemoteEvent 직접 연결 (여기서는 Remote 직접 연결)
local questUpdateEvent = ReplicatedStorage:WaitForChild("QuestRemotes"):WaitForChild("QuestUpdate")
questUpdateEvent.OnClientEvent:Connect(function(updatedQuests)
	-- QuestManager 상태도 갱신
	QuestManager.CurrentQuests = updatedQuests
	updateUI()
    
    -- 알림 표시 (창이 닫혀있으면 배지 표시)
    if not mainFrame.Visible then
        notifBadge.Visible = true
        
        -- 약간의 튀는 애니메이션
        local originalSize = UDim2.new(0, 18, 0, 18)
        local popSize = UDim2.new(0, 24, 0, 24)
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 1, true)
        TweenService:Create(notifBadge, tweenInfo, {Size = popSize}):Play()
    end
end)

-- J키 토글
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.J then
		mainFrame.Visible = not mainFrame.Visible
		if mainFrame.Visible then
			notifBadge.Visible = false -- 열면 배지 숨김
		end
	end
end)

updateUI() -- 초기화
print("QuestUI Initialized")
