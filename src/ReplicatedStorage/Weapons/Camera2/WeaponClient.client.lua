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
	Mouse.Icon = "rbxasset://textures/Cursors/Crosshair.png"
	
	-- print("[WeaponClient] Equipped Tool:", Tool.Name)
	
	-- Camera 2 Feature: Flashlight & Zoom Viewfinder
	if Tool.Name == "Camera2" then
		-- Flashlight
		local light = Handle:FindFirstChild("Flashlight")
		if not light then
			light = Instance.new("SpotLight")
			light.Name = "Flashlight"
			light.Brightness = 20
			light.Range = 60
			light.Angle = 45
			light.Color = Color3.fromRGB(255, 255, 230)
			light.Parent = Handle
		end
		light.Enabled = true
	else
		-- Determine if using Camera 1: Force remove any accidental light
		local light = Handle:FindFirstChild("Flashlight")
		if light then
			light:Destroy()
		end
	end
end)

Tool.Unequipped:Connect(function()
	isEquipped = false
	Mouse.Icon = ""
	
	-- Turn off Flashlight
	local light = Handle:FindFirstChild("Flashlight")
	if light then
		light.Enabled = false
	end
end)

Tool.Activated:Connect(function()
	if not isEquipped then return end
	if isTakingPhoto then return end
	
	-- Check if Stunned or Album Open
	local character = Player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid and humanoid.PlatformStand then
			return
		end
	end
	
	-- Check if Album is open (Don't shoot if viewing gallery)
	local pGui = Player:FindFirstChild("PlayerGui")
	if pGui then
		local galleryGui = pGui:FindFirstChild("PhotoGalleryGui")
		if galleryGui then
			local window = galleryGui:FindFirstChild("GalleryWindow")
			if window and window.Visible then
				return -- Album is open, do not take photo
			end
		end
	end
	
	isTakingPhoto = true
	
	-- 1. 서버로 촬영 요청 (위치만 전송 - 기존 로직 유지)
	Remote:FireServer(Mouse.Hit.Position)
	
	-- 2. 갤러리 저장 요청 (클라이언트 -> 클라이언트)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local events = ReplicatedStorage:FindFirstChild("Events")
	if events then
		local takePhotoEvent = events:FindFirstChild("TakePhoto")
		if takePhotoEvent then
			-- Area Capture + FOV (Zoom)
			local character = Player.Character
			local head = character and character:FindFirstChild("Head")
			local captureCFrame
			
			if head then
				captureCFrame = CFrame.lookAt(head.Position, Mouse.Hit.Position)
			else
				captureCFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, Mouse.Hit.Position)
			end
			
			-- Camera 2 has Zoom (Lower FOV)
			local fov = 70 -- Default Wide
			if Tool.Name == "Camera2" then
				fov = 30 -- Zoomed In
			end
			
			takePhotoEvent:Fire({
				CFrame = captureCFrame,
				Position = captureCFrame.Position,
				FOV = fov
			})
			
			-- print("[Camera] Captured. FOV:", fov)
		end
	end
	
	-- 3. 클라이언트 측 효과 (셔터 소리)
	if Handle:FindFirstChild("ShutterSound") then
		Handle.ShutterSound:Play()
	end
	
	wait(Config.Camera.ShutterSpeed)
	
	isTakingPhoto = false
end)

Tool.Deactivated:Connect(function()
	isTakingPhoto = false
end)
