
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local originalCameraType = nil
local originalFieldOfView = nil
local cameraTween = nil
local currentNPC = nil
local dialogueSystem = ReplicatedStorage:WaitForChild("DialogueSystem")
local startDialogueFunc = dialogueSystem:WaitForChild("StartDialogue")
local selectChoiceEvent = dialogueSystem:WaitForChild("SelectChoice")

-- UI 요소 생성
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DialogueUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.8, 0, 0.25, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.7, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
mainFrame.Visible = false
mainFrame.Parent = screenGui

local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(0.3, 0, 0.2, 0)
nameLabel.Position = UDim2.new(0.02, 0, -0.1, 0)
nameLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 20
nameLabel.Font = Enum.Font.GothamBold
nameLabel.Text = "Speaker"
nameLabel.Parent = mainFrame

local textLabel = Instance.new("TextLabel")
textLabel.Name = "DialogueText"
textLabel.Size = UDim2.new(0.96, 0, 0.7, 0)
textLabel.Position = UDim2.new(0.02, 0, 0.2, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
textLabel.TextSize = 18
textLabel.Font = Enum.Font.Gotham
textLabel.TextWrapped = true
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.Text = ""
textLabel.Parent = mainFrame

local choiceContainer = Instance.new("Frame")
choiceContainer.Name = "Choices"
choiceContainer.Size = UDim2.new(0.4, 0, 0.5, 0)
choiceContainer.Position = UDim2.new(0.3, 0, -0.6, 0)
choiceContainer.BackgroundTransparency = 1
choiceContainer.Visible = false
choiceContainer.Parent = mainFrame

local nextIndicator = Instance.new("ImageLabel")
nextIndicator.Name = "NextIndicator"
nextIndicator.Size = UDim2.new(0.05, 0, 0.1, 0)
nextIndicator.Position = UDim2.new(0.92, 0, 0.85, 0)
nextIndicator.BackgroundTransparency = 1
nextIndicator.Image = "rbxassetid://6031763426"
nextIndicator.Parent = mainFrame
local blinkTween = TweenService:Create(nextIndicator, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.5})
blinkTween:Play()

-- 대화 상태 변수
local isDialogueActive = false
local currentDialogueData = nil
local currentNodeId = nil
local currentNode = nil

-- 타이팅 효과 함수
local function typeText(targetText)
	textLabel.MaxVisibleGraphemes = 0
	textLabel.Text = targetText
	local length = utf8.len(targetText)
	for i = 1, length do
		textLabel.MaxVisibleGraphemes = i
		task.wait(0.03)
		if not isDialogueActive or textLabel.Text ~= targetText then break end
	end
end

-- 대화 종료
local function endDialogue()
	isDialogueActive = false
	mainFrame.Visible = false
	choiceContainer.Visible = false
	if cameraTween then cameraTween:Cancel() end
	if originalCameraType then
		camera.CameraType = originalCameraType
		camera.FieldOfView = originalFieldOfView or 70
	end
	currentNPC = nil
end

-- 카메라 포커스 업데이트
local function updateCameraFocus(targetModel)
	if not targetModel then return end
	local head = targetModel:FindFirstChild("Head") or targetModel.PrimaryPart
	if not head then return end
	if not originalCameraType then
		originalCameraType = camera.CameraType
		originalFieldOfView = camera.FieldOfView
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local currentCameraPos = camera.CFrame.Position
	local targetPos = head.Position + (currentCameraPos - head.Position).Unit * 6 + Vector3.new(0, 1.5, 0)
	local targetCF = CFrame.lookAt(targetPos, head.Position)
	if cameraTween then cameraTween:Cancel() end
	cameraTween = TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
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
	nameLabel.Text = currentNode.Speaker or "???"
	
	local speakerName = currentNode.Speaker
	if speakerName == "나" or speakerName == player.Name or speakerName == "Player" then
		updateCameraFocus(player.Character)
	else
		updateCameraFocus(currentNPC)
	end
	
	typeText(currentNode.Text)
	
	if currentNode.Choices then
		choiceContainer.Visible = true
		nextIndicator.Visible = false
		for _, child in ipairs(choiceContainer:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end
		local layout = Instance.new("UIListLayout")
		layout.Parent = choiceContainer
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 5)
		
		for i, choice in ipairs(currentNode.Choices) do
			local btn = Instance.new("TextButton")
			btn.Name = "ChoiceBtn" .. i
			btn.Size = UDim2.new(1, 0, 0, 40)
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 16
			btn.Font = Enum.Font.GothamSemibold
			btn.Text = choice.Text
			btn.LayoutOrder = i
			btn.Parent = choiceContainer
			
			btn.MouseButton1Click:Connect(function()
				if choice.Action then
					selectChoiceEvent:FireServer(currentDialogueData.NPCName, {ChoiceIndex = i, Action = choice.Action})
				end
				if choice.Next then
					proceedToNext(choice.Next)
				else
					endDialogue()
				end
			end)
		end
	else
		choiceContainer.Visible = false
		nextIndicator.Visible = true
	end
	
	if currentNode.SetState then
		selectChoiceEvent:FireServer(currentDialogueData.NPCName, {SetState = currentNode.SetState})
	end
end

-- 다음 노드로 진행
proceedToNext = function(overrideNextId)
	if not isDialogueActive then return end
	
	local nextId = overrideNextId or (currentNode and currentNode.Next)
	if not nextId then
		endDialogue()
		return
	end
	
	if currentDialogueData.Nodes[nextId] then
		currentNodeId = nextId
		currentNode = currentDialogueData.Nodes[nextId]
		showCurrentNode()
	else
		warn("Next node not found: " .. tostring(nextId))
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
		currentNodeId = startNodeId
		currentNode = currentDialogueData.Nodes[startNodeId]
		mainFrame.Visible = true
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
		proceedToNext()
	end
end)

-- ProximityPrompt 감지
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, playerWhoTriggered)
	if playerWhoTriggered ~= player then return end
	if prompt.Name == "DialoguePrompt" then
		startDialogue(prompt.ObjectText, prompt:FindFirstAncestorWhichIsA("Model"))
	end
end)

print("DialogueUI Initialized")
