
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui") -- [Added] CoreGui 제어용

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local originalCameraType = nil
local originalFieldOfView = nil
local cameraTween = nil
local currentNPC = nil
local dialogueSystem = ReplicatedStorage:WaitForChild("DialogueSystem")
local startDialogueFunc = dialogueSystem:WaitForChild("StartDialogue")
local selectChoiceEvent = dialogueSystem:WaitForChild("SelectChoice")

-- [Added] 퀘스트 매니저 연동
local QuestManager = require(ReplicatedStorage:WaitForChild("QuestSystem"):WaitForChild("QuestManager"))

-- UI 요소 생성
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DialogueUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- [Premium] 메인 프레임 (Cozy Apricot 스타일) - 카드 형태 통합 컨테이너
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.8, 0, 0, 0) -- AutomaticSize Y 적용됨
mainFrame.AutomaticSize = Enum.AutomaticSize.Y
mainFrame.AnchorPoint = Vector2.new(0.5, 1) -- 하단 중앙 기준
mainFrame.Position = UDim2.new(0.5, 0, 0.9, 0) -- 화면 하단 배치
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 240) -- [Apricot] 매우 연한 살구색 배경
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2 -- 조금 더 두껍게
mainStroke.Color = Color3.fromRGB(255, 200, 150) -- [Apricot] 부드러운 오렌지 테두리
mainStroke.Transparency = 0 -- 완전 불투명
mainStroke.Parent = mainFrame

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 220)) -- [Apricot] 따뜻한 느낌의 그라데이션
})
mainGradient.Rotation = 90
mainGradient.Parent = mainFrame

-- [Added] ContentFrame (투명 컨테이너, AutoSize Y, ListLayout 적용)
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 0, 0)
contentFrame.AutomaticSize = Enum.AutomaticSize.Y
contentFrame.BackgroundTransparency = 1
contentFrame.Position = UDim2.new(0, 0, 0, 0)
contentFrame.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 25) -- 텍스트와 선택지 사이 간격
contentLayout.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 35) -- 이름표 공간 확보
contentPadding.PaddingBottom = UDim.new(0, 25)
contentPadding.PaddingLeft = UDim.new(0, 30)
contentPadding.PaddingRight = UDim.new(0, 30)
contentPadding.Parent = contentFrame

-- NameLabel 설정 (ContentFrame 밖, MainFrame의 직접 자식)
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(0, 0, 0, 36)
nameLabel.AutomaticSize = Enum.AutomaticSize.X
nameLabel.Position = UDim2.new(0, 25, 0, -18) -- 프레임 상단에 걸치도록 음수값 사용
nameLabel.AnchorPoint = Vector2.new(0, 0)
nameLabel.BackgroundColor3 = Color3.fromRGB(255, 160, 110) -- [Apricot] 생기 있는 오렌지
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 24
nameLabel.Font = Enum.Font.GothamBold
nameLabel.Text = "Speaker"
nameLabel.Parent = mainFrame 

local namePadding = Instance.new("UIPadding") -- 텍스트 좌우 여백
namePadding.PaddingLeft = UDim.new(0, 15)
namePadding.PaddingRight = UDim.new(0, 15)
namePadding.Parent = nameLabel

local nameCorner = Instance.new("UICorner")
nameCorner.CornerRadius = UDim.new(0, 8)
nameCorner.Parent = nameLabel

local nameStroke = Instance.new("UIStroke")
nameStroke.Thickness = 2
nameStroke.Color = Color3.fromRGB(180, 100, 60) 
nameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
nameStroke.Parent = nameLabel

-- 대사 텍스트 Label
local textLabel = Instance.new("TextLabel")
textLabel.Name = "DialogueText"
textLabel.LayoutOrder = 1
textLabel.Size = UDim2.new(1, 0, 0, 0) -- 높이 자동
textLabel.AutomaticSize = Enum.AutomaticSize.Y
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(90, 60, 50) -- [Apricot] 따뜻한 딥 브라운 텍스트
textLabel.TextSize = 25
textLabel.Font = Enum.Font.GothamMedium
textLabel.TextWrapped = true
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.Text = ""
textLabel.Parent = contentFrame 

-- [Premium] 선택지 컨테이너 (리스트 형태)
local choiceList = Instance.new("Frame")
choiceList.Name = "ChoiceList"
choiceList.LayoutOrder = 2
choiceList.Size = UDim2.new(1, 0, 0, 0) -- 높이는 내부 버튼에 따라 자동 조절
choiceList.AutomaticSize = Enum.AutomaticSize.Y
choiceList.BackgroundTransparency = 1
choiceList.Parent = contentFrame

local choiceLayout = Instance.new("UIListLayout")
choiceLayout.SortOrder = Enum.SortOrder.LayoutOrder
choiceLayout.Padding = UDim.new(0, 10) -- 버튼 사이 간격
choiceLayout.Parent = choiceList

-- Next Indicator (화살표) - 선택지가 없을 때만 표시
local nextIndicator = Instance.new("ImageLabel")
nextIndicator.Name = "NextIndicator"
nextIndicator.Size = UDim2.new(0, 24, 0, 24)
nextIndicator.AnchorPoint = Vector2.new(1, 1)
nextIndicator.Position = UDim2.new(1, -5, 1, -5) -- 우측 하단 구석
nextIndicator.BackgroundTransparency = 1
nextIndicator.Image = "rbxassetid://6031763426"
nextIndicator.ImageColor3 = Color3.fromRGB(180, 100, 60)
nextIndicator.Parent = mainFrame -- MainFrame의 직접 자식 (ContentFrame 밖)

local blinkTween = TweenService:Create(nextIndicator, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.6})
blinkTween:Play()

-- [Premium] 이벤트 알림 창 (Cozy Apricot 스타일)
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Size = UDim2.new(0, 400, 0, 0) -- [AutomaticSize] 0에서 시작
notificationFrame.AutomaticSize = Enum.AutomaticSize.Y -- [AutomaticSize] 컨텐츠에 따라 높이 자동 조절
notificationFrame.Position = UDim2.new(0.5, -200, -0.2, 0) -- 화면 상단 바깥에서 시작
notificationFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 240) -- [Apricot] 배경색 동일
notificationFrame.BackgroundTransparency = 0.1
notificationFrame.Visible = false
notificationFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 20)
notifCorner.Parent = notificationFrame

local notifStroke = Instance.new("UIStroke")
notifStroke.Thickness = 2
notifStroke.Color = Color3.fromRGB(255, 200, 150) -- [Apricot] 오렌지 테두리
notifStroke.Parent = notificationFrame

-- [Added] 텍스트 여백 확보를 위한 패딩 추가
local notifPadding = Instance.new("UIPadding")
notifPadding.PaddingTop = UDim.new(0, 15)
notifPadding.PaddingBottom = UDim.new(0, 15)
notifPadding.PaddingLeft = UDim.new(0, 20)
notifPadding.PaddingRight = UDim.new(0, 20)
notifPadding.Parent = notificationFrame

local notifLabel = Instance.new("TextLabel")
notifLabel.Name = "Message"
notifLabel.Size = UDim2.new(1, 0, 0, 0) -- [AutomaticSize] 높이 자동
notifLabel.AutomaticSize = Enum.AutomaticSize.Y
notifLabel.BackgroundTransparency = 1
notifLabel.TextColor3 = Color3.fromRGB(90, 60, 50) -- [Apricot] 다크 브라운 텍스트
notifLabel.TextSize = 24
notifLabel.Font = Enum.Font.GothamMedium -- [Modified] 본문은 Medium으로 변경
notifLabel.TextWrapped = true
notifLabel.Text = ""
notifLabel.LayoutOrder = 2 -- [Added] 레이아웃 순서
notifLabel.Parent = notificationFrame

-- [Added] 제목 표시용 레이블 추가
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 30) -- 고정 높이
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(180, 100, 60) -- [Apricot] 제목은 진한 오렌지/갈색
titleLabel.TextSize = 28
titleLabel.Font = Enum.Font.GothamBold -- [Added] 제목은 Bold
titleLabel.TextTransparency = 0
titleLabel.Text = ""
titleLabel.LayoutOrder = 1 -- [Added] 레이아웃 순서
titleLabel.Parent = notificationFrame

-- [Added] UIListLayout으로 제목과 내용 자동 배치
local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Padding = UDim.new(0, 5) -- 제목과 내용 사이 간격
notifLayout.Parent = notificationFrame

-- 대화 상태 변수
local isDialogueActive = false
local currentDialogueData = nil
local currentNodeId = nil
local currentNode = nil
local hiddenGuis = {} -- [Added] 대화 중 숨겨진 GUI 목록 저장
local disabledPrompts = {} -- [Added] 대화 중 비활성화된 ProximityPrompt 목록 저장
local mainTween = nil
-- local mainPositionTween = nil -- [Removed] AutoSize 사용으로 불필요
-- local choiceFadeTween = nil -- [Removed]
local isChoiceSelecting = false -- [Added] 중복 클릭 방지용 플래그
local isTyping = false -- [Added] 현재 타이핑 중인지 확인
local skipTyping = false -- [Added] 타이핑 스킵 요청 플래그
local notifTween = nil -- [Added] 알림 애니메이션용 트윈

-- 알림 표시 함수 (기존 동일)
local function showNotification(title, message)
	if not message or message == "" then return end
	
	notificationFrame.Visible = true
	titleLabel.Text = title or "알림" -- 제목이 없으면 기본값
	notifLabel.Text = message
	
	notificationFrame.Position = UDim2.new(0.5, -200, -0.2, 0) -- 초기화
	
	if notifTween then notifTween:Cancel() end
	
	-- 등장 (Slide Down)
	notifTween = TweenService:Create(notificationFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -200, 0.1, 0) -- 상단 10% 위치로 이동
	})
	notifTween:Play()
	
	-- 4초 후 퇴장 (Slide Up)
	task.delay(4, function()
		if notificationFrame.Visible then
			local outTween = TweenService:Create(notificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, -200, -0.2, 0)
			})
			outTween:Play()
			outTween.Completed:Connect(function()
				notificationFrame.Visible = false
			end)
		end
	end)
end

-- 타이팅 효과 함수
local function typeText(targetText)
	isTyping = true
	skipTyping = false
	textLabel.MaxVisibleGraphemes = 0
	textLabel.Text = targetText -- 이 시점에 TextBounds 이벤트 발생하여 CanvasSize 업데이트됨
	
	-- AutomaticSize가 작동하므로 별도 사이즈 조절 불필요
	
	local length = utf8.len(targetText)
	
	for i = 1, length do
		if skipTyping then
			textLabel.MaxVisibleGraphemes = -1 -- 전체 표시
			break
		end
		textLabel.MaxVisibleGraphemes = i
		task.wait(0.03)
		if not isDialogueActive or textLabel.Text ~= targetText then 
			isTyping = false
			return 
		end
	end
	isTyping = false
	skipTyping = false
end

local function endDialogue()
	if not isDialogueActive then return end
	
	if currentNode and currentNode.Notification then
		showNotification(currentNode.NotificationTitle, currentNode.Notification)
	end
	
	-- [Added] 대화 종료 시 퀘스트 시작 트리거 확인
	if currentNode and currentNode.StartQuest then
		QuestManager.AcceptQuest(currentNode.StartQuest)
	end
	
	isDialogueActive = false
	isTyping = false -- [Added] 초기화
	skipTyping = false 
	
	-- 퇴장 애니메이션
	if mainTween then mainTween:Cancel() end
	mainTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.2, 0), -- 아래로 사라짐
		BackgroundTransparency = 1
	})
	mainTween:Play()
	task.delay(0.5, function() mainFrame.Visible = false end)
	
	-- 선택지 초기화
	for _, child in ipairs(choiceList:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	if cameraTween then cameraTween:Cancel() end
	if originalCameraType then
		camera.CameraType = originalCameraType
		camera.FieldOfView = originalFieldOfView or 70
	end

	-- [Added] 숨겼던 GUI 복구
	for _, gui in ipairs(hiddenGuis) do
		if gui and gui:IsA("ScreenGui") then
			gui.Enabled = true
		end
	end
	hiddenGuis = {}

	-- [Added] 비활성화했던 상호작용 버튼(ProximityPrompt) 복구
	for _, prompt in ipairs(disabledPrompts) do
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = true
		end
	end
	disabledPrompts = {}

	-- [Added] Backpack 복구
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)

	currentNPC = nil
end

-- 카메라 포커스 업데이트 (기존 유지)
local function updateCameraFocus(targetModel)
	if not targetModel then return end
	
	local head = targetModel:FindFirstChild("Head") or targetModel.PrimaryPart
	local root = targetModel:FindFirstChild("HumanoidRootPart") 
		or targetModel:FindFirstChild("Torso") 
		or targetModel:FindFirstChild("UpperTorso") 
		or targetModel.PrimaryPart 
		or head 
		
	if not head or not root then 
		warn("Cannot find Head or RootPart for camera focus on " .. targetModel.Name)
		return 
	end
	
	if not originalCameraType then
		originalCameraType = camera.CameraType
		originalFieldOfView = camera.FieldOfView
	end
	camera.CameraType = Enum.CameraType.Scriptable

	local rootCF = root.CFrame
	local lookVec = rootCF.LookVector
	local rightVec = rootCF.RightVector
	
	local targetPos = root.Position + (lookVec * 4.5) + (rightVec * 2.0) + Vector3.new(0, 0.5, 0)
	local targetCF = CFrame.lookAt(targetPos, head.Position)
	
	if cameraTween then cameraTween:Cancel() end
	cameraTween = TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		CFrame = targetCF,
		FieldOfView = 40 
	})
	cameraTween:Play()
end

-- Forward declaration
local proceedToNext

-- 현재 노드 표시
local function showCurrentNode()
	if not currentNode then return end
	isChoiceSelecting = false -- [Added] 선택 상태 초기화
	
	local speakerName = currentNode.Speaker or "???"
	if speakerName == "Player" or speakerName == "나" or speakerName == player.Name then
		nameLabel.Text = player.DisplayName
		updateCameraFocus(player.Character) 
	else
		nameLabel.Text = speakerName
		updateCameraFocus(currentNPC) 
	end
	
	local rawText = currentNode.Text or ""
	local processedText = string.gsub(rawText, "{PlayerName}", player.DisplayName)
	
	-- 이전 선택지 제거
	for _, child in ipairs(choiceList:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end
	
	-- [Fixed] 선택지 컨테이너 크기 초기화 (MainFrame 크기 복구를 위해)
	choiceList.Size = UDim2.new(1, 0, 0, 0)
	choiceList.AutomaticSize = Enum.AutomaticSize.Y 
	
	typeText(processedText)
	
	if currentNode.Choices then
		-- [Modified] 대화가 다 나오고 0.5초 뒤에 선택지 표시 (1 -> 0.5)
		task.wait(0.5)
		
		nextIndicator.Visible = false
		
		-- [Modified] 애니메이션을 위해 먼저 크기 0으로 설정 및 AutomaticSize 해제
		choiceList.AutomaticSize = Enum.AutomaticSize.None
		choiceList.Size = UDim2.new(1, 0, 0, 0)
		choiceList.ClipsDescendants = true
		
		local totalHeight = 0
		local spacing = 10 -- choiceLayout.Padding
		
		for i, choice in ipairs(currentNode.Choices) do
			local btn = Instance.new("TextButton")
			btn.Name = "ChoiceBtn" .. i
			btn.Size = UDim2.new(1, 0, 0, 50) -- 높이 조정
			btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- [Modified] 완전 흰색 배경
			btn.TextColor3 = Color3.fromRGB(80, 50, 40) -- [Modified] 진한 갈색 텍스트
			btn.TextSize = 24 -- [Modified] 글자 크기 증가 (유지)
			btn.Font = Enum.Font.GothamMedium 
			btn.Text = "  ▶  " .. choice.Text -- [Modified] 화살표 아이콘 추가
			btn.TextXAlignment = Enum.TextXAlignment.Left 
			btn.AutoButtonColor = false
			btn.Parent = choiceList
			
			-- [Added] 텍스트 여백
			local btnPadding = Instance.new("UIPadding")
			btnPadding.PaddingLeft = UDim.new(0, 15)
			btnPadding.PaddingRight = UDim.new(0, 15)
			btnPadding.Parent = btn

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 12)
			btnCorner.Parent = btn

			local btnStroke = Instance.new("UIStroke")
			btnStroke.Thickness = 1.5 -- 얇고 깔끔하게
			btnStroke.Color = Color3.fromRGB(255, 200, 100) -- [Modified] 연한 오렌지
			btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			btnStroke.Parent = btn
			
			-- [Premium] 버튼 호버 애니메이션
			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 250, 240)}):Play()
				TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 160, 50)}):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 200, 100)}):Play()
			end)
			
			btn.MouseButton1Click:Connect(function()
				if isChoiceSelecting then return end 
				isChoiceSelecting = true 
				
				if choice.Action then
					selectChoiceEvent:FireServer(currentDialogueData.NPCName, {ChoiceIndex = i, Action = choice.Action})
				end
				if choice.Next then proceedToNext(choice.Next) else endDialogue() end
			end)
			
			-- 높이 계산
			totalHeight = totalHeight + 50 + ((i > 1) and spacing or 0)
		end
		
		-- [Added] 펼쳐지는 애니메이션 (쑤욱!)
		-- MainFrame이 AutomaticSize=Y이므로 ChoiceList가 커지면 MainFrame도 커질 것임.
		TweenService:Create(choiceList, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, totalHeight + 5) -- 약간 여유
		}):Play()
		
		-- 애니메이션 후 AutomaticSize 복구 (안정성)
		task.delay(0.5, function()
			if choiceList and choiceList.Parent then
				choiceList.AutomaticSize = Enum.AutomaticSize.Y
				choiceList.ClipsDescendants = false
			end
		end)
	else
		nextIndicator.Visible = true
	end
	
	if currentNode.SetState then
		selectChoiceEvent:FireServer(currentDialogueData.NPCName, {SetState = currentNode.SetState})
	end
end

-- 다음 노드로 진행
proceedToNext = function(overrideNextId)
	if not isDialogueActive or isTyping then return end 
	
	-- 선택지가 있는데 스페이스바/클릭으로 넘어가려 하면 무시
	if currentNode.Choices and not overrideNextId then return end
	
	local nextId = overrideNextId or (currentNode and currentNode.Next)
	if not nextId then endDialogue() return end
	
	if currentDialogueData.Nodes[nextId] then
		currentNodeId = nextId
		currentNode = currentDialogueData.Nodes[nextId]
		showCurrentNode()
	else
		endDialogue()
	end
end

-- 대화 시작 메인 함수
local function startDialogue(npcName, npcModel)
	if isDialogueActive then return end
	local result = startDialogueFunc:InvokeServer(npcName)
	if not result then warn("Failed to start dialogue with " .. npcName) return end
	
	isDialogueActive = true
	currentDialogueData = result.DialogueData
	currentDialogueData.NPCName = result.NPCName or npcName
	currentNPC = npcModel or workspace:FindFirstChild(npcName, true)
	
	if not currentDialogueData or not currentDialogueData.Nodes then
		endDialogue()
		return
	end
	
	local startNodeId = nil
	for id, node in pairs(currentDialogueData.Nodes) do
		if string.find(id, "_1$") then
			startNodeId = id
			break
		end
	end
	if not startNodeId then startNodeId = next(currentDialogueData.Nodes) end
	
	if startNodeId then
		-- [Added] 무게 해제 등
		if player.Character then
			local hum = player.Character:FindFirstChild("Humanoid")
			if hum then hum:UnequipTools() end
		end
		player:GetMouse().Icon = ""
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

		-- [Added] 다른 ScreenGui 숨기기
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			for _, gui in ipairs(playerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.Name ~= "DialogueUI" and gui.Enabled then
					table.insert(hiddenGuis, gui)
					gui.Enabled = false
				end
			end
		end

		-- [Added] 모든 상호작용 버튼(ProximityPrompt) 숨김
		for _, prompt in ipairs(workspace:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") and prompt.Enabled then
				table.insert(disabledPrompts, prompt)
				prompt.Enabled = false
			end
		end

		currentNodeId = startNodeId
		currentNode = currentDialogueData.Nodes[startNodeId]
		
		-- [Premium] 등장 애니메이션
		mainFrame.Visible = true
		mainFrame.BackgroundTransparency = 1
		mainFrame.Position = UDim2.new(0.5, 0, 1.2, 0) -- 아래에서 시작
		
		if mainTween then mainTween:Cancel() end
		mainTween = TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.9, 0), -- 최종 위치
			BackgroundTransparency = 0.1
		})
		mainTween:Play()

		showCurrentNode()
	else
		endDialogue()
	end
end

-- 입력 처리
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not isDialogueActive then return end
	-- gameProcessed 체크를 제거하거나 완화: UI 클릭 시에도 반응해야 함
	-- 단, 버튼 클릭(gameProcessed=true)과 충돌 방지 필요?
	-- 여기서는 단순 스킵이므로, 버튼이 아직 생성되지 않은 시점(타이핑 중)이라면 gameProcessed 무관하게 처리 가능
	-- 하지만 버튼 생성 후 클릭이면 버튼 이벤트가 우선
	
	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isTyping then
			-- [Modified] 타이핑 중이면 항상 스킵 가능 (선택지 유무 무관)
			skipTyping = true
		else
			-- 타이핑이 끝난 상태
			-- 선택지가 있으면 클릭/스페이스바 진행 금지 (버튼 클릭 강제)
			if currentNode and currentNode.Choices then return end
			
			-- 다음 대화로 진행 (gameProcessed일 경우 무시 - 예: 버튼 클릭 등)
			if not gameProcessed then
				proceedToNext()
			end
		end
	end
end)

-- ProximityPrompt 감지
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, playerWhoTriggered)
	if playerWhoTriggered ~= player then return end
	if prompt.Name == "DialoguePrompt" then
		startDialogue(prompt.ObjectText, prompt:FindFirstAncestorWhichIsA("Model"))
	end
end)

print("DialogueUI Initialized (Unified Card Design)")
