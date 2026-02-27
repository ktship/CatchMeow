local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- 메인 화면 UI 컨테이너
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainCoinGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 우측 상단 코인 표시 배경 프레임
local balanceFrame = Instance.new("Frame")
balanceFrame.Name = "BalanceFrame"
balanceFrame.Size = UDim2.new(0, 150, 0, 40)
balanceFrame.AnchorPoint = Vector2.new(1, 0)
balanceFrame.Position = UDim2.new(1, -20, 0, 20) -- 우측 상단 여백 (20px)
balanceFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 240)
balanceFrame.Parent = screenGui

local balanceCorner = Instance.new("UICorner")
balanceCorner.CornerRadius = UDim.new(0, 12)
balanceCorner.Parent = balanceFrame

local balanceStroke = Instance.new("UIStroke")
balanceStroke.Thickness = 2
balanceStroke.Color = Color3.fromRGB(255, 200, 150)
balanceStroke.Parent = balanceFrame

-- 코인 아이콘 (골드 코인)
local balanceIcon = Instance.new("ImageLabel")
balanceIcon.Name = "BalanceIcon"
balanceIcon.Size = UDim2.new(0, 24, 0, 24)
balanceIcon.Position = UDim2.new(0, 10, 0.5, -12)
balanceIcon.BackgroundTransparency = 1
balanceIcon.Image = "rbxassetid://15589362394" -- 유저 지정 골드 코인 이미지 ID
balanceIcon.Parent = balanceFrame

-- 코인 개수 라벨
local balanceLabel = Instance.new("TextLabel")
balanceLabel.Name = "BalanceLabel"
balanceLabel.Size = UDim2.new(1, -50, 1, 0)
balanceLabel.Position = UDim2.new(0, 45, 0, 0)
balanceLabel.BackgroundTransparency = 1
balanceLabel.TextColor3 = Color3.fromRGB(180, 100, 60)
balanceLabel.TextSize = 20
balanceLabel.Font = Enum.Font.GothamBold
balanceLabel.TextXAlignment = Enum.TextXAlignment.Left
balanceLabel.Text = "0"
balanceLabel.Parent = balanceFrame

-- leaderstats 코인 수치 실시간 연동
task.spawn(function()
	-- leaderstats 가 로드될 때까지 대기
	local leaderstats = player:WaitForChild("leaderstats", 15)
	if leaderstats then
		local coin = leaderstats:WaitForChild("Coin", 10)
		if coin then
			-- 초기값 설정
			balanceLabel.Text = tostring(coin.Value)
			
			-- 값이 변경될 때마다 UI 업데이트
			coin.Changed:Connect(function(newValue)
				balanceLabel.Text = tostring(newValue)
				
				-- 코인 획득 시 팝 애메이션 (옵션)
				local originalSize = balanceFrame.Size
				game:GetService("TweenService"):Create(balanceFrame, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {
					Size = originalSize + UDim2.new(0, 10, 0, 4)
				}):Play()
			end)
		end
	end
end)

-- 테스트용 코인 추가 버튼
local testAddCoinButton = Instance.new("TextButton")
testAddCoinButton.Name = "TestAddCoinButton"
testAddCoinButton.Size = UDim2.new(0, 100, 0, 40)
testAddCoinButton.AnchorPoint = Vector2.new(1, 0)
testAddCoinButton.Position = UDim2.new(1, -180, 0, 20) -- 기존 코인 프레임 옆
testAddCoinButton.BackgroundColor3 = Color3.fromRGB(200, 255, 200)
testAddCoinButton.Text = "Test +100"
testAddCoinButton.Font = Enum.Font.GothamBold
testAddCoinButton.TextSize = 16
testAddCoinButton.TextColor3 = Color3.fromRGB(50, 100, 50)
testAddCoinButton.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = testAddCoinButton

testAddCoinButton.MouseButton1Click:Connect(function()
	local testEvent = ReplicatedStorage:WaitForChild("AddTestCoin", 5)
	if testEvent then
		testEvent:FireServer()
	end
end)

print("MainCoinGui Initialized")
