
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

-- [Premium] 메인 프레임 (Cozy Apricot 스타일)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.8, 0, 0.28, 0)
mainFrame.Position = UDim2.new(0.1, 0, 1.1, 0) -- 시작 위치
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 240) -- [Apricot] 매우 연한 살구색 배경
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1.5
mainStroke.Color = Color3.fromRGB(255, 200, 150) -- [Apricot] 부드러운 오렌지 테두리
mainStroke.Transparency = 0.4
mainStroke.Parent = mainFrame

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 220)) -- [Apricot] 따뜻한 느낌의 그라데이션
})
mainGradient.Rotation = 90
mainGradient.Parent = mainFrame

-- [Premium] 화자 이름 배지
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(0, 200, 0, 50)
nameLabel.Position = UDim2.new(0, 20, 0, -60)
nameLabel.BackgroundColor3 = Color3.fromRGB(255, 160, 110) -- [Apricot] 생기 있는 오렌지
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 28
nameLabel.Font = Enum.Font.GothamBold
nameLabel.Text = "Speaker"
nameLabel.Parent = mainFrame

local nameCorner = Instance.new("UICorner")
nameCorner.CornerRadius = UDim.new(0, 10)
nameCorner.Parent = nameLabel

local nameStroke = Instance.new("UIStroke")
nameStroke.Thickness = 2
nameStroke.Color = Color3.fromRGB(180, 100, 60) -- [Apricot] 짙은 갈색/오렌지 외곽선으로 또렷하게
nameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
nameStroke.Parent = nameLabel

-- 대사 텍스트
-- 대사 텍스트 스크롤 프레임 [Added]
local textScroll = Instance.new("ScrollingFrame")
textScroll.Name = "TextScroll"
textScroll.Size = UDim2.new(0.94, 0, 0.75, 0)
textScroll.Position = UDim2.new(0.03, 0, 0.2, 0)
textScroll.BackgroundTransparency = 1
textScroll.BorderSizePixel = 0
textScroll.ScrollBarThickness = 6
textScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 150) -- [Apricot] 스크롤바 색상
textScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
textScroll.AutomaticCanvasSize = Enum.AutomaticSize.None -- [Modified] 수동 제어
textScroll.Parent = mainFrame

local textLabel = Instance.new("TextLabel")
textLabel.Name = "DialogueText"
textLabel.Size = UDim2.new(1, -10, 0, 0) -- [Modified] 높이는 자동 조절 (AutomaticSize)
textLabel.AutomaticSize = Enum.AutomaticSize.Y
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(90, 60, 50) -- [Apricot] 따뜻한 딥 브라운 텍스트
textLabel.TextSize = 26
textLabel.Font = Enum.Font.GothamMedium
textLabel.TextWrapped = true
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.Text = ""
textLabel.Parent = textScroll -- [Modified] 스크롤 프레임 안에 배치

-- [Added] 텍스트 크기에 따라 스크롤 영역 자동 업데이트
textLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
	textScroll.CanvasSize = UDim2.new(0, 0, 0, textLabel.TextBounds.Y + 30) -- 여유분 30px
	-- 자동 스크롤 (선택 사항: 텍스트가 길어지면 맨 아래로? 아니면 맨 위 유지?)
	-- 보통 대화창은 읽으면서 내려가므로, 사용자가 스크롤하도록 둠.
	-- 단, 처음 텍스트가 세팅될 때는 위치를 초기화하는 게 좋음 (typeText에서 처리)
end)

-- [Premium] 선택지 컨테이너 및 디자인
local choiceContainer = Instance.new("CanvasGroup") -- [Premium] 그룹 페이딩을 위해 CanvasGroup 사용
choiceContainer.Name = "Choices"
choiceContainer.Size = UDim2.new(0.4, 0, 0.4, 0) -- [Optimized] 화면 기준 크기 설정
choiceContainer.Position = UDim2.new(0.5, 0, 0.6, 0) -- [Optimized] 대화창 바로 위 시작 위치 (AnchorPoint 적용 예정)
choiceContainer.AnchorPoint = Vector2.new(0.5, 1) -- [Optimized] 하단 중앙 기준
choiceContainer.BackgroundTransparency = 1
choiceContainer.GroupTransparency = 1 -- 시작은 투명하게
choiceContainer.Visible = false
choiceContainer.ZIndex = 10 -- [Optimized] 대화창보다 위에 오도록 설정
choiceContainer.Parent = screenGui -- [Optimized] MainFrame에서 분리하여 독립 배치

local nextIndicator = Instance.new("ImageLabel")
nextIndicator.Name = "NextIndicator"
nextIndicator.Size = UDim2.new(0, 30, 0, 30)
nextIndicator.Position = UDim2.new(0.95, -15, 0.85, -15)
nextIndicator.BackgroundTransparency = 1
nextIndicator.Image = "rbxassetid://6031763426"
nextIndicator.Parent = mainFrame
local blinkTween = TweenService:Create(nextIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.5, Position = UDim2.new(0.95, -15, 0.88, -15)})
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
local mainPositionTween = nil -- [Added] 대화창 위치 이동용 트윈
local choiceFadeTween = nil -- [Added] 선택지 페이드용 트윈
local isChoiceSelecting = false -- [Added] 중복 클릭 방지용 플래그
local isTyping = false -- [Added] 현재 타이핑 중인지 확인
local skipTyping = false -- [Added] 타이핑 스킵 요청 플래그
local notifTween = nil -- [Added] 알림 애니메이션용 트윈

-- 알림 표시 함수
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
	
	-- 스크롤 위치 초기화 (맨 위로)
	textScroll.CanvasPosition = Vector2.new(0, 0)
	
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
		Position = UDim2.new(0.1, 0, 1.1, 0),
		BackgroundTransparency = 1
	})
	mainTween:Play()
	task.delay(0.5, function() mainFrame.Visible = false end)
	choiceContainer.Visible = false

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

-- 카메라 포커스 업데이트
local function updateCameraFocus(targetModel)
	if not targetModel then return end
	
	-- [Modified] 화자의 얼굴을 비추는 카메라 (숄더뷰/정면뷰)
	-- 타겟(말하는 사람)의 얼굴이 잘 보이도록 정면에서 약간 측면에 카메라 배치
	
	local head = targetModel:FindFirstChild("Head") or targetModel.PrimaryPart
	-- [Modified] 루트 파트 탐색 강화 (R6, R15, 기타 모델 호환)
	local root = targetModel:FindFirstChild("HumanoidRootPart") 
		or targetModel:FindFirstChild("Torso") 
		or targetModel:FindFirstChild("UpperTorso") 
		or targetModel.PrimaryPart 
		or head -- 최후의 수단으로 Head 사용
		
	if not head or not root then 
		warn("Cannot find Head or RootPart for camera focus on " .. targetModel.Name)
		return 
	end
	
	if not originalCameraType then
		originalCameraType = camera.CameraType
		originalFieldOfView = camera.FieldOfView
	end
	camera.CameraType = Enum.CameraType.Scriptable

	-- 카메라 위치: 타겟의 정면(LookVector) 4.5스터드 앞 + 오른쪽(RightVector) 2스터드 (약간 대각선)
	-- 높이는 Head 위치보다 살짝 위 또는 동일하게
	-- [Fixed] root.CFrame이 없는 경우 대비 (BasePart인지 확인)
	local rootCF = root.CFrame
	local lookVec = rootCF.LookVector
	local rightVec = rootCF.RightVector
	
	local targetPos = root.Position + (lookVec * 4.5) + (rightVec * 2.0) + Vector3.new(0, 0.5, 0)
	
	local targetCF = CFrame.lookAt(targetPos, head.Position) -- 타겟의 머리를 바라봄
	
	if cameraTween then cameraTween:Cancel() end
	cameraTween = TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		CFrame = targetCF,
		FieldOfView = 40 -- 얼굴 집중을 위해 FOV 축소
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
		updateCameraFocus(player.Character) -- 플레이어 비춤
	else
		nameLabel.Text = speakerName
		updateCameraFocus(currentNPC) -- NPC 비춤
	end
	
	local rawText = currentNode.Text or ""
	local processedText = string.gsub(rawText, "{PlayerName}", player.DisplayName)
	
	typeText(processedText)
	
	if currentNode.Choices then
		-- [Added] 선택지가 있을 때: 대화창을 위로 올림
		if mainPositionTween then mainPositionTween:Cancel() end
		mainPositionTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.1, 0, 0.55, 0) -- 위로 이동
		})
		mainPositionTween:Play()

		nextIndicator.Visible = false
		choiceContainer.Visible = true
		choiceContainer.GroupTransparency = 1 -- 페이드 시작을 위해 투명화
		choiceContainer.Position = UDim2.new(0.5, 0, 0.9, 0) -- [Modified] 애니메이션 시작 위치 (대화창 아래)
		
		for _, child in ipairs(choiceContainer:GetChildren()) do
			if not child:IsA("UIListLayout") then child:Destroy() end
		end
		
		local layout = choiceContainer:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.Parent = choiceContainer
		
		for i, choice in ipairs(currentNode.Choices) do
			local btn = Instance.new("TextButton")
			btn.Name = "ChoiceBtn" .. i
			btn.Size = UDim2.new(1, 0, 0, 55)
			btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- [Modified] 완전 흰색 배경
			btn.TextColor3 = Color3.fromRGB(80, 50, 40) -- [Modified] 진한 갈색 텍스트
			btn.TextSize = 22
			btn.Font = Enum.Font.GothamMedium -- [Modified] Medium 폰트
			btn.Text = "  ▶  " .. choice.Text -- [Modified] 화살표 아이콘 추가
			btn.TextXAlignment = Enum.TextXAlignment.Left -- [Modified] 왼쪽 정렬
			btn.AutoButtonColor = false
			btn.Parent = choiceContainer
			
			-- [Added] 텍스트 여백
			local btnPadding = Instance.new("UIPadding")
			btnPadding.PaddingLeft = UDim.new(0, 20)
			btnPadding.Parent = btn

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 12)
			btnCorner.Parent = btn

			local btnStroke = Instance.new("UIStroke")
			btnStroke.Thickness = 2.5 -- [Modified] 두꺼운 테두리
			btnStroke.Color = Color3.fromRGB(255, 210, 80) -- [Modified] 밝은 오렌지/옐로우 테두리
			btnStroke.Transparency = 0
			btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			btnStroke.Parent = btn
			
			-- [Added] 그림자 효과 (버튼 아래에 위치) 
			-- 간단히 Stroke의 두께감으로 표현하거나, 별도 Shadow 프레임 사용 가능
			-- 여기서는 깔끔함을 위해 Stroke 위주로 하되, 버튼 자체에 DropShadow 패딩을 줄 수도 있음.
			
			-- [Premium] 버튼 호버 애니메이션
			btn.MouseEnter:Connect(function()
				-- 호버 시 약간 줌인 + 배경색 미색
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 250, 240)}):Play()
				TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 180, 50)}):Play() -- 테두리 진해짐
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 210, 80)}):Play()
			end)
			
			btn.MouseButton1Click:Connect(function()
				if isChoiceSelecting then return end -- [Added] 이미 선택 중이면 무시
				isChoiceSelecting = true -- [Added] 선택 시작
				
				-- [Optimized] 즉시 숨기기
				choiceContainer.Visible = false
				choiceContainer.GroupTransparency = 1
				if choiceFadeTween then choiceFadeTween:Cancel() end
				
				if choice.Action then
					selectChoiceEvent:FireServer(currentDialogueData.NPCName, {ChoiceIndex = i, Action = choice.Action})
				end
				if choice.Next then proceedToNext(choice.Next) else endDialogue() end
			end)
		end
		
		-- [Added] 타이핑 종료 후 여운(0.3초) 대기 및 페이드인 애니메이션 (0.5초)
		task.wait(0.3)
		if choiceFadeTween then choiceFadeTween:Cancel() end
		choiceFadeTween = TweenService:Create(choiceContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.85, 0) -- [Modified] 대화창(0.55 + 0.28 = 0.83) 바로 아래인 0.85 위치까지 올라옴
		})
		choiceFadeTween:Play()
	else
		-- [Added] 선택지가 없을 때: 대화창을 원래 위치(아래)로 내림
		if mainPositionTween then mainPositionTween:Cancel() end
		mainPositionTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.1, 0, 0.68, 0) -- 원래 위치 복귀
		})
		mainPositionTween:Play()

		choiceContainer.Visible = false
		nextIndicator.Visible = true
	end
	
	if currentNode.SetState then
		selectChoiceEvent:FireServer(currentDialogueData.NPCName, {SetState = currentNode.SetState})
	end
end

-- 다음 노드로 진행
proceedToNext = function(overrideNextId)
	if not isDialogueActive or isTyping then return end -- 타이핑 중이면 자동 진행 막음
	
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
		-- [Added] 무개 해제, 마우스 리셋, Backpack 숨김
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

		-- [Added] 모든 상호작용 버튼(ProximityPrompt) 숨김 및 비활격화
		for _, prompt in ipairs(workspace:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") and prompt.Enabled then
				table.insert(disabledPrompts, prompt)
				prompt.Enabled = false
			end
		end

		-- [Added] 월드 상의 조준선(AimVisuals) 숨김 (있을 경우)
		local aimVisuals = workspace:FindFirstChild("AimVisuals")
		if aimVisuals then
			for _, part in ipairs(aimVisuals:GetChildren()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
		end

		currentNodeId = startNodeId
		currentNode = currentDialogueData.Nodes[startNodeId]
		
		-- [Premium] 등장 애니메이션
		mainFrame.Visible = true
		mainFrame.BackgroundTransparency = 1
		mainFrame.Position = UDim2.new(0.1, 0, 1.1, 0)
		
		if mainTween then mainTween:Cancel() end
		mainTween = TweenService:Create(mainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.1, 0, 0.68, 0), -- [Modified] 0.55 -> 0.68 (다시 하단으로 복귀)
			BackgroundTransparency = 0.2
		})
		mainTween:Play()

		showCurrentNode()
	else
		endDialogue()
	end
end

-- 입력 처리
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not isDialogueActive or gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if choiceContainer.Visible then return end
		
		if isTyping then
			-- [Added] 타이핑 즉시 완료 (스킵)
			skipTyping = true
		else
			-- 다음 대화로 진행
			proceedToNext()
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

print("DialogueUI Initialized (Premium Design)")
