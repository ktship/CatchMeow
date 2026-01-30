-- ChatDisabler.server.lua
-- Placed in ServerScriptService
-- Authoritatively disables TextChatService components for ALL players

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

-- print("[Server] Disabling Chat System...")

-- 1. Disable New TextChatService Configurations
local function disableChatConfig()
	-- Wait for configurations to exist (they are auto-created)
	local chatWindow = TextChatService:FindFirstChild("ChatWindowConfiguration")
	if not chatWindow then
		chatWindow = Instance.new("ChatWindowConfiguration")
		chatWindow.Parent = TextChatService
	end
	chatWindow.Enabled = false

	local chatInput = TextChatService:FindFirstChild("ChatInputBarConfiguration")
	if not chatInput then
		chatInput = Instance.new("ChatInputBarConfiguration")
		chatInput.Parent = TextChatService
	end
	chatInput.Enabled = false
	
	print("[Server] TextChatService Config Disabled")
end

disableChatConfig()

-- Ensure they stay disabled if something tries to re-enable them
TextChatService.ChildAdded:Connect(function(child)
	if child:IsA("ChatWindowConfiguration") or child:IsA("ChatInputBarConfiguration") then
		child.Enabled = false
	end
end)

-- 2. Legacy Chat Disable (LoadDefaultChat = false)
-- This is usually done in Game Settings, but we can try to influence it here.
-- Note: Setting Players.CharacterAutoLoads = false (which we did in GameManager) also affects legacy chat loading timing.

-- 3. Force Client Disable via PlayerGui
-- (Backup: Send signal to clients or remove Chat GUI from Server side if it replicates)
Players.PlayerAdded:Connect(function(player)
	player:WaitForChild("PlayerGui").ChildAdded:Connect(function(child)
		if child.Name == "Chat" then
			wait()
			child:Destroy()
		end
	end)
end)
