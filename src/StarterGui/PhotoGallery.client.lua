local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local itemOffset = 0 -- For ScrollingFrame layout

-- 1. Create UI
-- print("--- [PhotoGallery] STARTING UI CREATION ---")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PhotoGalleryGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10 
screenGui.IgnoreGuiInset = true 
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Cleanup duplicate GUIs (Fixes issue where script checks the wrong/hidden GUI)
for _, child in ipairs(player.PlayerGui:GetChildren()) do
	if child.Name == "PhotoGalleryGui" and child ~= screenGui then
		child:Destroy()
	end
end

-- print("--- [PhotoGallery] ScreenGui Created in PlayerGui ---")

-- Open Button (Album)
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenGalleryBtn"
openBtn.Size = UDim2.new(0, 100, 0, 40)
openBtn.Position = UDim2.new(1, -230, 1, -50) -- [Modified] Shifted Left
openBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.Text = "Album 📸"
openBtn.TextScaled = true
openBtn.Parent = screenGui
openBtn.BorderSizePixel = 0
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = openBtn

-- [Added] Save Map Button (Next to Album)
local saveBtn = Instance.new("TextButton")
saveBtn.Name = "SaveMapBtn"
saveBtn.Size = UDim2.new(0, 100, 0, 40)
saveBtn.Position = UDim2.new(1, -120, 1, -50) -- [Modified] Original Album Position (Bottom Right)
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Text = "Save Map 💾"
saveBtn.TextScaled = true
saveBtn.BorderSizePixel = 0
saveBtn.Parent = screenGui

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 8)
saveCorner.Parent = saveBtn

saveBtn.MouseButton1Click:Connect(function()
	local events = ReplicatedStorage:WaitForChild("Events")
	local remote = events:FindFirstChild("SaveMapDebug")
	if remote then
		remote:FireServer()
		saveBtn.Text = "Saved!"
		task.wait(2)
		saveBtn.Text = "Save Map 💾"
	end
end)

-- [Added] Tree Planter Toggle
local isPlanting = false
local plantBtn = Instance.new("TextButton")
plantBtn.Name = "PlantTreeBtn"
plantBtn.Size = UDim2.new(0, 40, 0, 40)
plantBtn.Position = UDim2.new(1, -120, 1, -100) -- [Modified] Moved Up (Row 2), Aligned right
plantBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50) -- Green
plantBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plantBtn.Text = "🌲"
plantBtn.TextScaled = true
plantBtn.BorderSizePixel = 0
plantBtn.Parent = screenGui

local plantCorner = Instance.new("UICorner")
plantCorner.CornerRadius = UDim.new(0, 8)
plantCorner.Parent = plantBtn

-- [Added] Delete Tree Button
local isDeleting = false
local deleteBtn = Instance.new("TextButton")
deleteBtn.Name = "DeleteTreeBtn"
deleteBtn.Size = UDim2.new(0, 40, 0, 40)
deleteBtn.Position = UDim2.new(1, -170, 1, -100) -- [Modified] Moved Up (Row 2), Left of Plant
deleteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red
deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteBtn.Text = "🪓"
deleteBtn.TextScaled = true
deleteBtn.BorderSizePixel = 0
deleteBtn.Parent = screenGui

local delCorner = Instance.new("UICorner")
delCorner.CornerRadius = UDim.new(0, 8)
delCorner.Parent = deleteBtn

-- Toggle Functions
local function updateButtons()
	if isPlanting then
		plantBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		deleteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		screenGui:SetAttribute("Mode", "Plant")
	elseif isDeleting then
		plantBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		deleteBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Bright Red
		screenGui:SetAttribute("Mode", "Delete")
	else
		plantBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		deleteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		screenGui:SetAttribute("Mode", "None")
	end
end

plantBtn.MouseButton1Click:Connect(function()
	isPlanting = not isPlanting
	isDeleting = false -- Mutually exclusive
	updateButtons()
end)

deleteBtn.MouseButton1Click:Connect(function()
	isDeleting = not isDeleting
	isPlanting = false -- Mutually exclusive
	updateButtons()
end)

-- Planting Logic (Click Listener)
-- Logic (Click Listener)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if (not isPlanting and not isDeleting) then return end
	if gameProcessed then return end -- Ignore UI clicks
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mouse = player:GetMouse()
		local ray = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {player.Character}
		
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
		
		if result and result.Instance then
			local events = ReplicatedStorage:WaitForChild("Events")
			
			if isPlanting then
				-- PLANT Logic
				local plantRemote = events:FindFirstChild("PlantTree")
				if plantRemote then
					plantRemote:FireServer(result.Position)
				end
				
			elseif isDeleting then
				-- DELETE Logic
				-- Check if clicked object is part of a Tree
				local model = result.Instance:FindFirstAncestorOfClass("Model")
				if model and model.Name:match("Tree_Type") then
					-- Found a tree!
					local removeRemote = events:FindFirstChild("RemoveTree")
					if removeRemote then
						-- Send Position of Tree Pivot (Center) for server verification
						local pos = model:GetPivot().Position
						removeRemote:FireServer(pos)
						
						-- Optional: Simple client prediction visual? 
						-- No, let server handle it to ensure sync.
					end
				end
			end
		end
	end
end)

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
local function createPhoto(data)
	-- data can be a Target (old) or {CFrame, Position} (new)
	if not data then return end
	
	local subjectName = "Scene"
	local captureCFrame
	
	-- Handle legacy or new format
	if typeof(data) == "Instance" then
		-- Fallback for direct object capture (if needed, but we are switching to scene)
		return -- Skip legacy for now
	elseif typeof(data) == "table" and data.CFrame then
		captureCFrame = data.CFrame
	else
		return
	end

	-- Create ViewportFrame
	local photoFrame = Instance.new("Frame")
	photoFrame.BackgroundColor3 = Color3.fromRGB(255, 248, 220) 
	photoFrame.BorderSizePixel = 0
	
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(0.9, 0, 0.75, 0)
	viewport.Position = UDim2.new(0.05, 0, 0.05, 0)
	viewport.BackgroundColor3 = Color3.fromRGB(135, 206, 235) -- Sky Blue
	viewport.BorderSizePixel = 0
	viewport.Parent = photoFrame
	
	-- Setup Lighting
	viewport.Ambient = Color3.fromRGB(150, 150, 150)
	viewport.LightColor = Color3.fromRGB(255, 255, 240)
	viewport.LightDirection = Vector3.new(1, -1, 1)

	-- Define Capture Box (Area in front of camera)
	-- Range set to 100 studs default, 300 studs for Zoom
	local isZoom = (data.FOV or 70) < 50
	local range = isZoom and 300 or 100
	
	local boxSize = Vector3.new(80, 50, range) 
	-- Center it range/2 in front of camera
	local boxCFrame = captureCFrame * CFrame.new(0, 0, -range/2)
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {player.Character} -- Don't capture self

	local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)
	
	-- World Model for physics/rendering context (optional but good practice)
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport
	
	local partCount = 0
	
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			-- only visible parts
			if part.Transparency < 1 then
				-- Clone
				local clone = part:Clone()
				clone:ClearAllChildren() -- Remove scripts/joints
				clone.Anchored = true
				clone.CanCollide = false
				
				-- Relative Position Logic:
				-- We want to keep the scene layout relative to the CaptureBox center.
				-- Map WorldPosition -> RelativePosition
				-- NewCFrame = RelativeOffset
				local relativeCF = boxCFrame:Inverse() * part.CFrame
				clone.CFrame = relativeCF
				clone.Parent = worldModel
				partCount = partCount + 1
			end
		end
	end
	
	-- Setup Camera
	local cam = Instance.new("Camera")
	cam.Parent = viewport
	viewport.CurrentCamera = cam
	
	-- Position Camera relative to the scene
	-- The original camera (captureCFrame) was 25 studs behind the box center.
	-- Relative Camera Pos = boxCFrame:Inverse() * captureCFrame
	-- This should result in CFrame.new(0, 0, 25) if calculations are perfect.
	local relativeCamCF = boxCFrame:Inverse() * captureCFrame
	cam.CFrame = relativeCamCF
	
	-- Apply Zoom (FOV)
	cam.FieldOfView = data.FOV or 70

	local caption = Instance.new("TextLabel")
	caption.Size = UDim2.new(1, 0, 0.2, 0)
	caption.Position = UDim2.new(0, 0, 0.8, 0)
	caption.BackgroundTransparency = 1
	local pos = captureCFrame.Position
	local posStr = string.format("(%d, %d, %d)", math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
	
	caption.Text = string.format("%d Objs at %s", partCount, posStr)
	if partCount == 0 then
		caption.Text = "No Objects (Terrain Invisible!)"
		caption.TextColor3 = Color3.fromRGB(255, 0, 0)
	end
	caption.Font = Enum.Font.IndieFlower
	caption.TextSize = 18
	caption.TextColor3 = Color3.fromRGB(0, 0, 0)
	caption.Parent = photoFrame
	photoFrame.Parent = scroller
	
	-- Update ScrollCanvas
	scroller.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y)
	
	-- Notify User
	StarterGui:SetCore("SendNotification", {
		Title = "Photo Saved! 📸",
		Text = "Check your Album.",
		Duration = 2
	})
	
	-- [Added] Click to Verify Log
	-- Add Button covering the frame
	local verifyBtn = Instance.new("TextButton")
	verifyBtn.Name = "VerifyBtn"
	verifyBtn.Size = UDim2.new(1, 0, 1, 0)
	verifyBtn.BackgroundTransparency = 1
	verifyBtn.Text = ""
	verifyBtn.Parent = photoFrame
	
	verifyBtn.MouseButton1Click:Connect(function()
		local isMatch = photoFrame:GetAttribute("IsMatch")
		local target = photoFrame:GetAttribute("Target")
		local obj = photoFrame:GetAttribute("Object")
		local col = photoFrame:GetAttribute("Color")
		
		if target then
			-- Verification Data Exists
			local result = isMatch and "O (Success)" or "X (Fail)"
			local capturedInfo = obj or "Unknown"
			if col then capturedInfo = col .. " " .. capturedInfo end
			
			print("🔎 Verifying Photo...")
			print("   Target: " .. tostring(target))
			print("   Captured: " .. capturedInfo)
			print("   Result: " .. result)
		else
			print("🔎 Scene Photo (No Verification Data)")
		end
	end)
end

-- Listen for Event
local events = ReplicatedStorage:WaitForChild("Events", 10)
if events then
	local takePhoto = events:WaitForChild("TakePhoto", 10)
	if takePhoto then
		takePhoto.Event:Connect(createPhoto)
	end
	
	-- [Added] Listen for Verification Feedback and attach to latest photo
	local photoFeedback = events:WaitForChild("PhotoFeedback", 10)
	if photoFeedback then
		photoFeedback.OnClientEvent:Connect(function(isMatch, target, objectName, colorName)
			-- Find latest photo (Last child in scroller? Grid sorts by name? Frame names are default)
			-- Usually newest is last added if Grid sorting is Default (LayoutOrder 0).
			-- Check children count.
			local frames = scroller:GetChildren()
			local latestFrame = nil
			-- Filter for Frames only (ignore layout/constraints)
			local photoFrames = {}
			for _, child in ipairs(frames) do
				if child:IsA("Frame") then
					table.insert(photoFrames, child)
				end
			end
			
			-- Sort by Age? We just created it, so it's likely the last one found or inserted.
			-- Let's assume the most recent child is the one.
			-- Ideally we'd map ID, but for now assumption works if latency is low.
			if #photoFrames > 0 then
				latestFrame = photoFrames[#photoFrames]
			end
			
			if latestFrame then
				latestFrame:SetAttribute("IsMatch", isMatch)
				latestFrame:SetAttribute("Target", target)
				latestFrame:SetAttribute("Object", objectName)
				latestFrame:SetAttribute("Color", colorName)
				-- print("Attached Verification Data to Photo")
			end
		end)
	end
end
