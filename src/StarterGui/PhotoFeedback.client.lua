local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local events = ReplicatedStorage:WaitForChild("Events")
local photoFeedbackEvent = events:WaitForChild("PhotoFeedback")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. Create HUD for Mission
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PhotoFeedbackHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local missionFrame = Instance.new("Frame")
missionFrame.Size = UDim2.new(0, 200, 0, 40)
missionFrame.Position = UDim2.new(0.5, -100, 0, 10) -- Top Center
missionFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
missionFrame.BackgroundTransparency = 0.5
missionFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = missionFrame

local missionText = Instance.new("TextLabel")
missionText.Size = UDim2.new(1, 0, 1, 0)
missionText.BackgroundTransparency = 1
missionText.TextColor3 = Color3.fromRGB(255, 255, 255)
missionText.TextSize = 18
missionText.Font = Enum.Font.GothamBold
missionText.Text = "Mission: Find Cat"
missionText.Parent = missionFrame

-- Update Mission Text
local function updateMission()
	local target = player:GetAttribute("TargetCat")
	if target then
		missionText.Text = "Mission: Find " .. target .. " Cat"
		
		-- Optional: Color Code
		if target == "Orange" then missionText.TextColor3 = Color3.fromRGB(255, 180, 50)
		elseif target == "White" then missionText.TextColor3 = Color3.fromRGB(255, 255, 255)
		elseif target == "Black" then missionText.TextColor3 = Color3.fromRGB(100, 100, 100) -- Light Grey for readability
		elseif target == "Grey" then missionText.TextColor3 = Color3.fromRGB(180, 180, 180)
		end
	end
end

-- Listen for attribute change
player:GetAttributeChangedSignal("TargetCat"):Connect(updateMission)
-- Initial check
updateMission()


-- 2. Feedback (moved to PhotoGallery)
-- photoFeedbackEvent listener removed to prevent auto-logging.
