local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = script.Parent

-- UI 요소 생성 (코드로 생성하거나 Rojo의 .model.json 사용 가능)
-- 여기서는 코드로 생성하되, 기존 로직 유지
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0, 200, 0, 50)
statusFrame.Position = UDim2.new(0.5, -100, 0, 10)
statusFrame.BackgroundTransparency = 0.5
statusFrame.BackgroundColor3 = Color3.new(0, 0, 0)
statusFrame.BorderSizePixel = 0
statusFrame.Parent = gui

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

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0, 250, 0, 80)
statsFrame.Position = UDim2.new(0, 20, 1, -100)
statsFrame.BackgroundTransparency = 0.5
statsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
statsFrame.Parent = gui

local healthLabel = Instance.new("TextLabel")
healthLabel.Size = UDim2.new(1, -20, 0.5, 0)
healthLabel.Position = UDim2.new(0, 10, 0, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
healthLabel.TextSize = 24
healthLabel.TextXAlignment = Enum.TextXAlignment.Left
healthLabel.Text = "Health: 100"
healthLabel.Parent = statsFrame

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.new(1, -20, 0.5, 0)
ammoLabel.Position = UDim2.new(0, 10, 0.5, 0)
ammoLabel.BackgroundTransparency = 1
ammoLabel.TextColor3 = Color3.new(1, 1, 0)
ammoLabel.TextSize = 24
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.Text = "Ammo: --/--"
ammoLabel.Parent = statsFrame

-- 데이터 바인딩
local gameStatus = ReplicatedStorage:WaitForChild("GameStatus")
local timeLeft = ReplicatedStorage:WaitForChild("TimeLeft")

gameStatus.Changed:Connect(function(val)
	statusLabel.Text = val
end)

timeLeft.Changed:Connect(function(val)
	local mins = math.floor(val / 60)
	local secs = val % 60
	timerLabel.Text = string.format("%02d:%02d", mins, secs)
end)

RunService.RenderStepped:Connect(function()
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		local hum = player.Character.Humanoid
		healthLabel.Text = string.format("Health: %d", math.floor(hum.Health))
	else
		healthLabel.Text = "Health: 0"
	end
	
	-- 무기 찾기 (Tool이 Character에 있으면 장착 중)
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	if tool then
		ammoLabel.Text = "Weapon: " .. tool.Name
	else
		ammoLabel.Text = "Weapon: None"
	end
end)
