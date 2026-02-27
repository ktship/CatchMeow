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

-- [Theme Colors] Sunny Orange (QuestUI/InventoryUI와 통일)
local Colors = {
	Primary = Color3.fromRGB(255, 170, 0), -- 진한 오렌지 (헤더, 강조)
	Background = Color3.fromRGB(245, 240, 230), -- 진한 크림색 (바디)
	Card = Color3.fromRGB(255, 255, 255), -- 흰색 (카드, 슬롯)
	Stroke = Color3.fromRGB(254, 230, 133), -- 연한 오렌지 (테두리)
	TextTitle = Color3.new(1, 1, 1), -- 헤더 타이틀 (흰색)
	TextBody = Color3.fromRGB(140, 100, 80), -- 중간 갈색
	TextHighlight = Color3.fromRGB(255, 140, 0), -- 오렌지 텍스트
	CloseBtn = Color3.fromRGB(255, 255, 255), -- 닫기 버튼
}

-- 앨범 버튼 (좌측 하단, 퀘스트/인벤토리 옆)
-- QuestButton: X=20, InventoryButton: X=90
-- AlbumButton: X=160 (70 간격)
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenGalleryBtn"
openBtn.Size = UDim2.new(0, 50, 0, 50) -- [Modified] Reduced Size to match Inventory
openBtn.Position = UDim2.new(0, 160, 1, -20)
openBtn.AnchorPoint = Vector2.new(0, 1)
openBtn.BackgroundColor3 = Color3.fromRGB(255, 220, 100) -- [Modified] 통일된 색상 (InventoryButton과 동일)
openBtn.Text = "🏞️" -- [Modified] 텍스트 제거, 아이콘 변경 (사진 느낌)
openBtn.TextSize = 35 -- [Modified] Reduced Icon Size
openBtn.Font = Enum.Font.GothamBold
openBtn.AutoButtonColor = true
openBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = openBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Thickness = 3
btnStroke.Color = Color3.fromRGB(160, 90, 50) -- [Modified] 통일된 테두리 색상
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
btnStroke.Parent = openBtn

-- [Added] Save Map Button (Debug - Moved to Top Right)
local saveBtn = Instance.new("TextButton")
saveBtn.Name = "SaveMapBtn"
saveBtn.Size = UDim2.new(0, 100, 0, 40)
saveBtn.Position = UDim2.new(1, -120, 0, 60) -- Top Right (Moved down)
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

-- [Added] Tree Planter Toggle (Debug - Moved Top Right)
local isPlanting = false
local plantBtn = Instance.new("TextButton")
plantBtn.Name = "PlantTreeBtn"
plantBtn.Size = UDim2.new(0, 40, 0, 40)
plantBtn.Position = UDim2.new(1, -120, 0, 110)
plantBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
plantBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plantBtn.Text = "🌲"
plantBtn.TextScaled = true
plantBtn.BorderSizePixel = 0
plantBtn.Parent = screenGui

local plantCorner = Instance.new("UICorner")
plantCorner.CornerRadius = UDim.new(0, 8)
plantCorner.Parent = plantBtn

-- [Added] Delete Tree Button (Debug - Moved Top Right)
local isDeleting = false
local deleteBtn = Instance.new("TextButton")
deleteBtn.Name = "DeleteTreeBtn"
deleteBtn.Size = UDim2.new(0, 40, 0, 40)
deleteBtn.Position = UDim2.new(1, -170, 0, 110)
deleteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
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
		deleteBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		screenGui:SetAttribute("Mode", "Delete")
	else
		plantBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		deleteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		screenGui:SetAttribute("Mode", "None")
	end
end

plantBtn.MouseButton1Click:Connect(function()
	isPlanting = not isPlanting
	isDeleting = false
	updateButtons()
end)

deleteBtn.MouseButton1Click:Connect(function()
	isDeleting = not isDeleting
	isPlanting = false
	updateButtons()
end)


-- Gallery Window (Re-styled)
-- 메인 프레임 (투명 컨테이너)
local window = Instance.new("Frame")
window.Name = "GalleryWindow"
window.Size = UDim2.new(0, 600, 1, -180) -- [Modified] 위아래 여백 유지 풀스크린
window.Position = UDim2.new(0.5, 0, 0.5, 0) -- [Modified] 정중앙 배치
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundTransparency = 1
window.Visible = false
window.Parent = screenGui

local winStroke = Instance.new("UIStroke")
winStroke.Thickness = 2
winStroke.Color = Colors.Stroke
winStroke.Parent = window

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 16)
winCorner.Parent = window

-- 1. 헤더 (Header)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Colors.Primary
header.BorderSizePixel = 0
header.Parent = window

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

local headerCover = Instance.new("Frame")
headerCover.Name = "CornerCover"
headerCover.Size = UDim2.new(1, 0, 0, 10)
headerCover.Position = UDim2.new(0, 0, 1, -10)
headerCover.BackgroundColor3 = Colors.Primary
headerCover.BorderSizePixel = 0
headerCover.Parent = header

-- 헤더 아이콘 & 타이틀
local headerIcon = Instance.new("TextLabel")
headerIcon.Name = "Icon"
headerIcon.Size = UDim2.new(0, 24, 0, 24)
headerIcon.Position = UDim2.new(0, 15, 0.5, 0)
headerIcon.AnchorPoint = Vector2.new(0, 0.5)
headerIcon.BackgroundTransparency = 1
headerIcon.Text = "🏞️"
headerIcon.Font = Enum.Font.GothamBold
headerIcon.TextSize = 28
headerIcon.TextColor3 = Color3.new(1, 1, 1)
headerIcon.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.Name = "Title"
headerTitle.Size = UDim2.new(1, -80, 1, 0)
headerTitle.Position = UDim2.new(0, 45, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "나의 앨범"
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextSize = 28
headerTitle.TextColor3 = Colors.TextTitle
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

-- 닫기 버튼
local closeBtn = Instance.new("ImageButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -15, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.BackgroundColor3 = Color3.new(1, 1, 1)
closeBtn.BackgroundTransparency = 0.8
closeBtn.Image = "rbxassetid://3926305904" -- X icon
closeBtn.ImageRectOffset = Vector2.new(284, 4)
closeBtn.ImageRectSize = Vector2.new(24, 24)
closeBtn.ImageColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

-- 2. 바디 (Content Area)
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -50) -- 헤더 제외
body.Position = UDim2.new(0, 0, 0, 50)
body.BackgroundColor3 = Colors.Background
body.BorderSizePixel = 0
body.Parent = window

local bodyCorner = Instance.new("UICorner")
bodyCorner.CornerRadius = UDim.new(0, 16)
bodyCorner.Parent = body

local bodyCover = Instance.new("Frame")
bodyCover.Name = "CornerCover"
bodyCover.Size = UDim2.new(1, 0, 0, 10)
bodyCover.Position = UDim2.new(0, 0, 0, 0)
bodyCover.BackgroundColor3 = Colors.Background
bodyCover.BorderSizePixel = 0
bodyCover.Parent = body

-- 배경 클릭 시 닫기 위한 버튼 (투명)
local backgroundBtn = Instance.new("TextButton")
backgroundBtn.Name = "BackgroundButton"
backgroundBtn.Size = UDim2.new(1, 0, 1, 0)
backgroundBtn.Position = UDim2.new(0, 0, 0, 0)
backgroundBtn.BackgroundTransparency = 1
backgroundBtn.Text = ""
backgroundBtn.Visible = false
backgroundBtn.ZIndex = 0
backgroundBtn.Parent = screenGui


-- Scrolling Frame (Grid) - Moved inside Body
local scroller = Instance.new("ScrollingFrame")
scroller.Size = UDim2.new(1, -20, 1, -20)
scroller.Position = UDim2.new(0, 10, 0, 10) -- Padding 10
scroller.BackgroundTransparency = 1
scroller.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto size later
scroller.ScrollBarThickness = 4
scroller.ScrollBarImageColor3 = Colors.Primary
scroller.Parent = body

-- Grid Layout
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 180, 0, 180)
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.SortOrder = Enum.SortOrder.LayoutOrder -- [Added] 순서 보장 (신규 사진 뒤로)
grid.Parent = scroller

-- Open/Close Logic (Updated)
openBtn.MouseButton1Click:Connect(function()
	window.Visible = not window.Visible
	backgroundBtn.Visible = window.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
	window.Visible = false
	backgroundBtn.Visible = false
end)

-- Modified Background Button Logic (Prevent closing in Select Mode)
backgroundBtn.MouseButton1Click:Connect(function()
	if screenGui:GetAttribute("SelectMode") then return end -- Prevent closing
	window.Visible = false
	backgroundBtn.Visible = false
end)

-- 2. Capture Logic
local function createPhoto(data)
	print("[PhotoGallery] Photo Captured! Processing visual...")
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
	
	local seenModels = {} -- [Added] Track models to avoid duplicate cloning (e.g. Character parts)
	
	for _, part in ipairs(parts) do
		-- [Added] Check if part belongs to a Character (Model with Humanoid)
		local character = part.Parent
		-- [Modified] Include Chef (No Humanoid) as a Character
		if character and character:IsA("Model") and (character:FindFirstChild("Humanoid") or character.Name == "Chef") then
			-- It's a Character! Clone only once.
			if not seenModels[character] then
				seenModels[character] = true
				
				local clone = character:Clone()
				
				-- Cleanup Scripts/Physics from Character
				for _, child in ipairs(clone:GetDescendants()) do 
					if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Sound") then
						child:Destroy()
					end
				end
				-- Ensure Anchored for ViewportFrame
				for _, child in ipairs(clone:GetDescendants()) do
					if child:IsA("BasePart") then
						child.Anchored = true
						child.CanCollide = false
					end
				end
				
				-- Relative Position Logic for Model
				-- Pivot entire model using CFrame math
				-- [Modified] Robust Pivot Logic (Works even without PrimaryPart)
				local targetPivot = character:GetPivot()
				local relativeCF = boxCFrame:Inverse() * targetPivot
				clone:PivotTo(relativeCF)
				
				clone.Parent = worldModel
				partCount = partCount + 1
			end
			-- Skip individual parts of character
			continue
		end
	
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			-- [Modified] Allow Transparent parts IF they have a Decal/Texture (e.g. Special Cat Side Panels)
			local hasTexture = part:FindFirstChildWhichIsA("Decal") or part:FindFirstChildWhichIsA("Texture")
			
			if part.Transparency < 1 or hasTexture then
				-- Clone
				local clone = part:Clone()
				
				-- [Modified] Don't use ClearAllChildren(), it deletes Decals!
				-- Only remove Physics/Scripts
				for _, child in ipairs(clone:GetChildren()) do
					if child:IsA("JointInstance") or child:IsA("WeldConstraint") or child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Sound") then
						child:Destroy()
					end
				end
				
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
	
	-- SelectOverlay (선택 모드에서만 보임)
	local selectOverlay = Instance.new("TextButton")
	selectOverlay.Name = "SelectOverlay"
	selectOverlay.Size = UDim2.new(1, 0, 1, 0)
	selectOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	selectOverlay.BackgroundTransparency = 0.6
	selectOverlay.Text = "선택하기"
	selectOverlay.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectOverlay.TextSize = 24
	selectOverlay.Font = Enum.Font.GothamBold
	selectOverlay.Visible = screenGui:GetAttribute("SelectMode") == true
	selectOverlay.Parent = photoFrame
	
	selectOverlay.MouseButton1Click:Connect(function()
		if not screenGui:GetAttribute("SelectMode") then return end
		
		local isMatch = photoFrame:GetAttribute("IsMatch")
		local target = photoFrame:GetAttribute("Target")
		local obj = photoFrame:GetAttribute("Object")
		
		print("--- Photo Selected ---")
		print("Object:", obj)
		print("Target:", target)
		print("IsMatch:", isMatch)
		print("----------------------")
		
		-- Fire to Server
		local events = ReplicatedStorage:FindFirstChild("Events")
		if events then
			local photoSelected = events:FindFirstChild("PhotoSelected")
			if photoSelected then
				photoSelected:FireServer(isMatch, target)
			end
		end
		
		-- Close Gallery and Reset Mode
		window.Visible = false
		backgroundBtn.Visible = false
		screenGui:SetAttribute("SelectMode", nil)
	end)
end

-- SelectMode 변경 감지
screenGui:GetAttributeChangedSignal("SelectMode"):Connect(function()
	local isSelectMode = screenGui:GetAttribute("SelectMode") == true
	
	-- UI 전환
	openBtn.Visible = not isSelectMode
	closeBtn.Visible = not isSelectMode
	
	if isSelectMode then
		headerTitle.Text = "사진을 선택하세요"
		header.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		headerCover.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		headerIcon.Text = "✅"
	else
		headerTitle.Text = "나의 앨범"
		header.BackgroundColor3 = Colors.Primary
		headerCover.BackgroundColor3 = Colors.Primary
		headerIcon.Text = "🏞️"
	end
	
	-- 오버레이 표시/숨김
	for _, child in ipairs(scroller:GetChildren()) do
		if child:IsA("Frame") then
			local overlay = child:FindFirstChild("SelectOverlay")
			if overlay then
				overlay.Visible = isSelectMode
			end
		end
	end
end)


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
		photoFeedback.OnClientEvent:Connect(function(isMatch, target, objectName)
			print("[PhotoGallery] Feedback - Target:", target, "Object:", objectName, "IsMatch:", isMatch)
			-- Find latest photo
			local frames = scroller:GetChildren()
			local latestFrame = nil
			local photoFrames = {}
			for _, child in ipairs(frames) do
				if child:IsA("Frame") then
					table.insert(photoFrames, child)
				end
			end
			
			if #photoFrames > 0 then
				latestFrame = photoFrames[#photoFrames]
			end
			
			if latestFrame then
				latestFrame:SetAttribute("IsMatch", isMatch)
				latestFrame:SetAttribute("Target", target)
				latestFrame:SetAttribute("Object", objectName)
				
				-- Update visual caption for feedback
				local caption = latestFrame:FindFirstChild("TextLabel")
				if caption then -- Assuming TextLabel is caption
					if isMatch then
						caption.Text = "✅ " .. (objectName or "Unknown")
						caption.TextColor3 = Color3.fromRGB(0, 150, 0)
					else
						caption.Text = "📷 " .. (objectName or "Unknown")
						caption.TextColor3 = Color3.fromRGB(50, 50, 50)
					end
				end
			end
		end)
	end
end
