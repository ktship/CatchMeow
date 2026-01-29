local Tool = script.Parent
local Player = game:GetService("Players").LocalPlayer
local Mouse = Player:GetMouse()
local Remote = Tool:WaitForChild("FireEvent")
local Handle = Tool:WaitForChild("Handle")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Config"))

local isEquipped = false
local isTakingPhoto = false

Tool.Equipped:Connect(function()
	isEquipped = true
	-- 카메라 아이콘 (임시로 기본 십자선 사용, 원하는 ID로 교체 가능)
	Mouse.Icon = "rbxasset://textures/Cursors/Crosshair.png"
end)

Tool.Unequipped:Connect(function()
	isEquipped = false
	Mouse.Icon = ""
end)

Tool.Activated:Connect(function()
	if not isEquipped then return end
	if isTakingPhoto then return end
	
	isTakingPhoto = true
	
	-- 서버로 촬영 요청 (위치만 전송)
	Remote:FireServer(Mouse.Hit.Position)
	
	-- 클라이언트 측 효과 (셔터 소리)
	if Handle:FindFirstChild("ShutterSound") then
		Handle.ShutterSound:Play()
	end
	
	wait(Config.Camera.ShutterSpeed)
	
	isTakingPhoto = false
end)

Tool.Deactivated:Connect(function()
	isTakingPhoto = false
end)
