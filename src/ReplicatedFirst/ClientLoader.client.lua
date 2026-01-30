-- ClientLoader.client.lua
-- Placed in ReplicatedFirst to run IMMEDIATELY upon game load
-- Handles early feature disabling (Chat, aggressive UI cleanup)

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Remove Default Loading Screen (Standard practice to prove RF is running)
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- print("ClientLoader running from ReplicatedFirst (Instant Disable)")

-- 1. Disable New TextChatService (Instant)
if TextChatService:FindFirstChild("ChatWindowConfiguration") then
	TextChatService.ChatWindowConfiguration.Enabled = false
end
if TextChatService:FindFirstChild("ChatInputBarConfiguration") then
	TextChatService.ChatInputBarConfiguration.Enabled = false
end

TextChatService.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ChatWindowConfiguration") or descendant:IsA("ChatInputBarConfiguration") then
		descendant.Enabled = false
	end
end)

-- 2. CoreGui (TopBar Chat Icon) Disable Logic
-- ReplicatedFirst runs extremely early, so SetCoreGuiEnabled might fail initially until CoreScripts load.
-- We must retry aggressively.

task.spawn(function()
	local success = false
	local start = tick()
	
	-- Retry loop: rapidly try to disable Core Chat
	while (tick() - start) < 10 do -- Try for 10 seconds max
		success = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		end)
		
		if success then
			-- Verification: Check if it stuck? (Optional, but usually pcall success is enough)
			-- print("CoreGui Chat Disabled Successfully")
		end
		
		task.wait(0.05) -- Very fast retry (20 times per sec)
	end
	
	-- Long-term Watchdog (Just in case it gets re-enabled)
	while true do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) -- Optional: Clean look
		end)
		task.wait(2)
	end
end)

-- 3. Legacy Chat System Cleanup (Aggressive)
task.spawn(function()
	local player = Players.LocalPlayer
	if not player then
		Players.PlayerAdded:Wait()
		player = Players.LocalPlayer
	end
	
	local playerGui = player:WaitForChild("PlayerGui")
	
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "Chat" then
			RunService.Stepped:Wait() -- Destroy next frame
			child:Destroy()
		end
	end)
	
	-- Initial check in case we missed event
	local existing = playerGui:FindFirstChild("Chat")
	if existing then existing:Destroy() end
end)
