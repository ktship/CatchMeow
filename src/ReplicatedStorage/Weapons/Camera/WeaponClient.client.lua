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
	
	-- [New] 촬영 대상 식별 (퀘스트용)
	local target = Mouse.Target
	local targetModel = nil
	if target then
		-- 모델 찾기 (NPC 등)
		targetModel = target:FindFirstAncestor("Grandpa") -- 이름으로 명시적 검색
		if not targetModel then
			targetModel = target:FindFirstAncestor("Bungeoppang")
		end
		
		-- 만약 이름으로 못 찾았으면 일반적 모델 검색
		if not targetModel then
			targetModel = target:FindFirstAncestorWhichIsA("Model")
			-- 플레이어 자신은 제외
			if targetModel == character then targetModel = nil end
		end
	end
	
	-- 1. 서버로 촬영 요청 (위치 + 타겟 전송)
	Remote:FireServer(Mouse.Hit.Position, targetModel)
	
	-- 2. 갤러리 저장 요청 (클라이언트 -> 클라이언트)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local events = ReplicatedStorage:WaitForChild("Events", 10) -- [Fixed] WaitForChild
	if events then
		local takePhotoEvent = events:WaitForChild("TakePhoto", 10) -- [Fixed] WaitForChild
		if takePhotoEvent then
			print("[WeaponClient] Firing TakePhoto Event...") -- [Added] Debug
			
			-- Area Capture + FOV (Zoom)
			local character = Player.Character
			-- (Capture CFrame Logic)
			local head = character and character:FindFirstChild("Head")
			local captureCFrame
			
			if head then
				captureCFrame = CFrame.lookAt(head.Position, Mouse.Hit.Position)
			else
				captureCFrame = workspace.CurrentCamera.CFrame
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
			print("[WeaponClient] TakePhoto Event Fired!") 
		else
			warn("[WeaponClient] TakePhoto Event NOT found!")
		end
	else
		warn("[WeaponClient] Events folder NOT found!")
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
