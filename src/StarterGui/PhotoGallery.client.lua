local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local itemOffset = 0 -- For ScrollingFrame layout

-- 1. Create UI
print("--- [PhotoGallery] STARTING UI CREATION ---")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PhotoGalleryGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10 -- Ensure it's on top of everything
screenGui.IgnoreGuiInset = true -- Ignore top bar
screenGui.Parent = player:WaitForChild("PlayerGui")
print("--- [PhotoGallery] ScreenGui Created in PlayerGui ---")

-- Open Button (Restored)
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenGalleryBtn"
openBtn.Size = UDim2.new(0, 100, 0, 40)
openBtn.Position = UDim2.new(1, -120, 1, -50) -- Bottom Right
openBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.Text = "Album 📸"
openBtn.TextScaled = true
openBtn.Parent = screenGui
print("--- [PhotoGallery] Button Created ---")
openBtn.BorderSizePixel = 0
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = openBtn

-- Gallery Window (Hidden by default)
local window = Instance.new("Frame")
window.Name = "GalleryWindow"
window.Size = UDim2.new(0, 600, 0, 400)
window.Position = UDim2.new(0.5, -300, 0.5, -200)
window.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
window.Visible = false
window.Parent = screenGui
window.BorderSizePixel = 0
local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 12)
winCorner.Parent = window

-- Title
local title = Instance.new("TextLabel")
title.Text = "My Photos"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = window

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "X"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = window
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Scrolling Frame (Grid)
local scroller = Instance.new("ScrollingFrame")
scroller.Size = UDim2.new(1, -20, 1, -60)
scroller.Position = UDim2.new(0, 10, 0, 50)
scroller.BackgroundTransparency = 1
scroller.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto size later
scroller.Parent = window

-- Grid Layout
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 180, 0, 180)
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.Parent = scroller

-- Open/Close Logic
openBtn.MouseButton1Click:Connect(function()
	window.Visible = not window.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
	window.Visible = false
end)

-- 2. Capture Logic
local function createPhoto(target)
	if not target then return end
	
	-- Find Model or Part
	local subject = target
	if target:IsA("BasePart") and target.Parent:IsA("Model") and not target.Parent:IsA("Workspace") then
		subject = target.Parent -- Capture entire model (e.g. Car, Character)
	end
	
	-- Create ViewportFrame
	local photoFrame = Instance.new("Frame")
	photoFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 220) -- Polaroid-ish
	photoFrame.BorderSizePixel = 0
	
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(0.9, 0, 0.75, 0)
	viewport.Position = UDim2.new(0.05, 0, 0.05, 0)
	viewport.BackgroundColor3 = Color3.fromRGB(150, 200, 250) -- Sky Blue BG
	viewport.BorderSizePixel = 0
	viewport.Parent = photoFrame
	
	local caption = Instance.new("TextLabel")
	caption.Size = UDim2.new(1, 0, 0.2, 0)
	caption.Position = UDim2.new(0, 0, 0.8, 0)
	caption.BackgroundTransparency = 1
	caption.Text = subject.Name
	caption.Font = Enum.Font.IndieFlower -- Handwriting style
	caption.TextSize = 18
	caption.TextColor3 = Color3.fromRGB(0, 0, 0)
	caption.Parent = photoFrame
	
	-- Clone & Clean Subject
	local clone = subject:Clone()
	
	-- Sanitize: Modify parts for Viewport
	if clone:IsA("Model") then
		local cf, size = clone:GetBoundingBox()
		
		-- Center model at 0,0,0
		clone:PivotTo(CFrame.new())
		
		-- Setup Camera
		local cam = Instance.new("Camera")
		cam.Parent = viewport
		viewport.CurrentCamera = cam
		
		-- Position Camera to see the whole object
		local maxDim = math.max(size.X, size.Y, size.Z)
		local dist = maxDim * 1.5
		cam.CFrame = CFrame.new(Vector3.new(dist, dist*0.5, dist), Vector3.new(0, 0, 0))
		
	elseif clone:IsA("BasePart") then
		clone.CFrame = CFrame.new() -- Center
		clone.Anchored = true
		
		local cam = Instance.new("Camera")
		cam.Parent = viewport
		viewport.CurrentCamera = cam
		
		local maxDim = math.max(clone.Size.X, clone.Size.Y, clone.Size.Z)
		local dist = maxDim * 2.5
		cam.CFrame = CFrame.new(Vector3.new(dist, dist, dist), Vector3.new(0, 0, 0))
	end
	
	clone.Parent = viewport
	photoFrame.Parent = scroller
	
	-- Update ScrollCanvas
	scroller.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y)
	
	-- Notify User
	StarterGui:SetCore("SendNotification", {
		Title = "Photo Saved! 📸",
		Text = "Check your Album.",
		Duration = 2
	})
end

-- Listen for Event
local events = ReplicatedStorage:WaitForChild("Events", 10)
if events then
	local takePhoto = events:WaitForChild("TakePhoto", 10)
	if takePhoto then
		takePhoto.Event:Connect(createPhoto)
		print("[PhotoGallery] Listening for photos...")
	end
end
