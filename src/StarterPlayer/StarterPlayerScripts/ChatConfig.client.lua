-- ChatConfig.client.lua
-- 채팅창 크기 조절

local TextChatService = game:GetService("TextChatService")

-- 채팅창 설정이 로드될 때까지 대기
task.wait(1)

local chatWindow = TextChatService:FindFirstChild("ChatWindowConfiguration")
if chatWindow then
	chatWindow.HeightScale = 0.3
	chatWindow.WidthScale = 0.3
end
