local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Create the ScreenGui and Frame for fading
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TransitionUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = gui

local fadeFrame = Instance.new("Frame")
fadeFrame.Name = "FadeFrame"
fadeFrame.Size = UDim2.new(1, 0, 1, 0)
fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
fadeFrame.BackgroundTransparency = 1
fadeFrame.ZIndex = 100
fadeFrame.Parent = screenGui

local transitionEvent = ReplicatedStorage:WaitForChild("HouseTransition", 5)
if not transitionEvent then
	warn("[TransitionUI] HouseTransition RemoteEvent not found!")
	return
end

local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

transitionEvent.OnClientEvent:Connect(function(action)
	if action == "FadeOut" then
		local tween = TweenService:Create(fadeFrame, tweenInfo, {BackgroundTransparency = 0})
		tween:Play()
	elseif action == "FadeIn" then
		local tween = TweenService:Create(fadeFrame, tweenInfo, {BackgroundTransparency = 1})
		tween:Play()
	end
end)
