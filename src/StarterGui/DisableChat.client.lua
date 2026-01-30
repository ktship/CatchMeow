-- DisableChat.client.lua
-- StarterGui에 위치 (확실한 실행 보장)
-- 모든 채팅 시스템을 강제로, 지속적으로 비활성화합니다.

local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

print("DisableChat script initialized (StarterGui)")

-- 1. CoreGui (탑바 채팅 아이콘) 비활성화 루프
task.spawn(function()
	while true do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		end)
		task.wait(1)
	end
end)

-- 2. 신형 TextChatService 비활성화 루프
task.spawn(function()
	while true do
		if TextChatService:FindFirstChild("ChatWindowConfiguration") then
			TextChatService.ChatWindowConfiguration.Enabled = false
		end
		if TextChatService:FindFirstChild("ChatInputBarConfiguration") then
			TextChatService.ChatInputBarConfiguration.Enabled = false
		end
		task.wait(1)
	end
end)

-- 3. 구형 Legacy Chat UI 강제 삭제 루프
task.spawn(function()
	while true do
		local player = Players.LocalPlayer
		if player then
			local playerGui = player:FindFirstChild("PlayerGui")
			if playerGui then
				local chatGui = playerGui:FindFirstChild("Chat")
				if chatGui then
					chatGui:Destroy() -- 발견 즉시 삭제
					print("Legacy Chat Gui destroyed")
				end
			end
		end
		task.wait(1)
	end
end)
