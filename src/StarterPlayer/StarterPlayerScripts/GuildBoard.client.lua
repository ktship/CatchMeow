local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local boardPartName = "GuildBoardPart" 
local zoomDuration = 0.8
local interactionDistance = 60

-- State
local isZoomed = false
local originalCFrame = nil
local controlsDisabled = false

-- Setup Interaction
local function setupBoardInteraction()
	local map = Workspace:WaitForChild("Map", 30)
	if not map then return end
	
	-- [Modified] Bind to ALL Board Parts (4 Faces)
	for _, desc in ipairs(map:GetDescendants()) do
		if desc.Name == boardPartName and desc:IsA("BasePart") then
			local boardPart = desc
			
			local clickDetector = boardPart:FindFirstChildOfClass("ClickDetector")
			if not clickDetector then
				clickDetector = Instance.new("ClickDetector")
				clickDetector.Parent = boardPart
			end
			
			-- Interaction: Camera Zoom
			clickDetector.MouseClick:Connect(function()
				if isZoomed then return end
				zoomToBoard(boardPart)
			end)
		end
	end
end

function zoomToBoard(targetPart)
	isZoomed = true
	originalCFrame = camera.CFrame
	
	-- Calculate Target Camera CFrame
	-- Positioned in front of the board, looking at it.
	-- Board 'Front' is -Z relative to itself (if standard Part).
	-- We want to be roughly 15 studs away from the center for a full view.
	
	-- targetPart CFrame is the center of the Canvas.
	-- We move OUTWARDS from the surface.
	-- The SurfaceGui is on "Front".
	-- So we move in the direction of LookVector * distance? 
	-- If Face is Front, normal is -LookVector? No, Front is -Z.
	-- Let's assume standard orientation.
	
	local targetCFrame = targetPart.CFrame * CFrame.new(0, 0, -35) -- Move 35 studs in front (local -Z is front?)
	-- Wait, if Board Front is -Z... 
	-- CFrame.new(0,0,-18) moves towards -Z.
	-- We want the camera to LOOK AT the board (which faces -Z).
	-- So Camera should Look towards +Z (Back).
	-- Actually, let's just use CFrame.lookAt.
	
	-- Mega Board (60x40) needs more distance
	local camPos = targetPart.Position + (targetPart.CFrame.LookVector * 55) 
	-- If LookVector points INTO the board (Back face?), this puts camera behind.
	-- If SurfaceGui is visible, it's on a visible face.
	-- Usually "Front" face is -Z. 
	-- So LookVector is (0,0,-1).
	-- We want camera at (0,0,-18).
	-- So yes, `targetPart.CFrame * CFrame.new(0,0,-18)`.
	-- And rotate 180?
	-- Let's use simpler lookAt.
	
	targetCFrame = CFrame.lookAt(camPos, targetPart.Position)
	
	-- Tween Camera
	camera.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(camera, TweenInfo.new(zoomDuration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CFrame = targetCFrame}):Play()
	
	-- Disable Controls
	local Controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
	Controls:Disable()
	
	showExitUI()
end

function showExitUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GuildBoardExit"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	local backBtn = Instance.new("TextButton")
	backBtn.Text = "CLOSE"
	backBtn.Size = UDim2.new(0, 200, 0, 60)
	backBtn.Position = UDim2.new(0.5, 0, 0.9, 0)
	backBtn.AnchorPoint = Vector2.new(0.5, 1)
	backBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	backBtn.TextColor3 = Color3.new(1,1,1)
	backBtn.Font = Enum.Font.GothamBold
	backBtn.TextSize = 24
	backBtn.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = backBtn
	
	backBtn.MouseButton1Click:Connect(function()
		exitZoom(screenGui)
	end)
end

function exitZoom(gui)
	if not isZoomed then return end
	
	gui:Destroy()
	
	-- Restore Camera
	TweenService:Create(camera, TweenInfo.new(zoomDuration), {CFrame = originalCFrame}):Play()
	
	wait(zoomDuration)
	camera.CameraType = Enum.CameraType.Custom
	
	-- Enable Controls
	local Controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
	Controls:Enable()
	
	isZoomed = false
end

-- Monitor Map Changes (Re-bind on Lobby generation)
Workspace.ChildAdded:Connect(function(child)
	if child.Name == "Map" then
		wait(1) -- Let it load
		setupBoardInteraction()
	end
end)

setupBoardInteraction()
