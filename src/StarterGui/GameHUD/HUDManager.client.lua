local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui") -- [Added]

local player = Players.LocalPlayer
local gui = script.Parent

-- [Added] 기본 체력바 제거 (우측 상단)
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- UI 요소 생성 (코드로 생성하거나 Rojo의 .model.json 사용 가능)
-- 여기서는 코드로 생성하되, 기존 로직 유지
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0, 200, 0, 50)
statusFrame.Position = UDim2.new(0.5, -100, 0, 10)
statusFrame.BackgroundTransparency = 0.5
statusFrame.BackgroundColor3 = Color3.new(0, 0, 0)
statusFrame.BorderSizePixel = 0
statusFrame.Parent = gui
statusFrame.Visible = false -- [Modified] Hidden by default (User Request)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.6, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextScaled = true
statusLabel.Text = "Waiting..."
statusLabel.Parent = statusFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 0.4, 0)
timerLabel.Position = UDim2.new(0, 0, 0.6, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.new(1, 1, 0)
timerLabel.TextScaled = true
timerLabel.Text = "00:00"
timerLabel.Parent = statusFrame

-- 데이터 바인딩
local gameStatus = ReplicatedStorage:WaitForChild("GameStatus")
local timeLeft = ReplicatedStorage:WaitForChild("TimeLeft")

gameStatus.Changed:Connect(function(val)
	statusLabel.Text = val
	-- statusFrame.Visible = (val ~= "") -- [Modified] Always hidden
end)

timeLeft.Changed:Connect(function(val)
	local mins = math.floor(val / 60)
	local secs = val % 60
	timerLabel.Text = string.format("%02d:%02d", mins, secs)
end)

-- [Added] 캐릭터 머리 위 체력 표시 (BillboardGui - 체력바 형태)
local function createOverheadUI(character)
	local head = character:WaitForChild("Head", 5)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not head or not humanoid then return end
	
	-- 기존 UI가 있다면 제거
	if head:FindFirstChild("HealthOverhead") then
		head.HealthOverhead:Destroy()
	end

	local bbGui = Instance.new("BillboardGui")
	bbGui.Name = "HealthOverhead"
	bbGui.Adornee = head
	bbGui.Size = UDim2.new(0, 80, 0, 10) -- [Modified] 바 형태에 맞는 크기 (가로 80, 세로 10)
	bbGui.StudsOffset = Vector3.new(0, 1.5, 0) -- [Modified] 높이 낮춤 (2.5 -> 1.5)
	bbGui.AlwaysOnTop = true
	bbGui.Parent = head
	
	-- 배경 프레임 (검은색)
	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "Background"
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = bbGui
	
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0) -- 둥근 모서리
	bgCorner.Parent = bgFrame
	
	-- 체력바 프레임 (녹색)
	local barFrame = Instance.new("Frame")
	barFrame.Name = "HealthBar"
	barFrame.Size = UDim2.new(1, 0, 1, 0) -- 초기값 (나중에 업데이트)
	barFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 100) -- 밝은 녹색
	barFrame.BorderSizePixel = 0
	barFrame.Parent = bgFrame
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barFrame
	
	-- 테두리 (선택 사항, 깔끔함을 위해 추가)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 1
	uiStroke.Color = Color3.new(0, 0, 0)
	uiStroke.Parent = bgFrame
	
	-- 체력 변경 이벤트 연결
	local function updateHealth()
		local health = humanoid.Health
		local maxHealth = humanoid.MaxHealth
		if maxHealth <= 0 then return end
		
		local percent = math.clamp(health / maxHealth, 0, 1)
		
		-- [Modified] 체력이 40% 이하일 때만 표시
		if percent <= 0.4 then
			bbGui.Enabled = true
			
			-- 부드러운 트윈 효과 (크기)
			game:GetService("TweenService"):Create(barFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(percent, 0, 1, 0)
			}):Play()
			
			-- [Modified] 0%에 가까울수록 빨간색 (Green -> Red 그라데이션)
			-- Hue: 0.33(Green) -> 0(Red)
			local hue = percent * 0.33
			local color = Color3.fromHSV(hue, 0.9, 0.9)
			
			game:GetService("TweenService"):Create(barFrame, TweenInfo.new(0.3), {BackgroundColor3 = color}):Play()
		else
			bbGui.Enabled = false
		end
	end
	
	humanoid.HealthChanged:Connect(updateHealth)
	updateHealth() -- 초기 실행
end

-- 캐릭터 생성 시 연결
player.CharacterAdded:Connect(createOverheadUI)
if player.Character then
	createOverheadUI(player.Character)
end
