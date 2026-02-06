local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local ASSET_ID = 8189863148
local ASSET_NAME = "Bungeoppang"

-- Create Assets folder if not exists
local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
if not assetsFolder then
	assetsFolder = Instance.new("Folder")
	assetsFolder.Name = "Assets"
	assetsFolder.Parent = ReplicatedStorage
end

local function createProceduralFallback()
	local model = Instance.new("Model")
	model.Name = ASSET_NAME
	
	-- 몸통
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.2, 0.8, 1.8)
	body.Shape = Enum.PartType.Ball
	body.Color = Color3.fromRGB(255, 170, 80)
	body.Material = Enum.Material.Concrete
	body.Anchored = false
	body.CanCollide = true
	body.Parent = model
	
	-- PrimaryPart 설정
	model.PrimaryPart = body
	
	-- 꼬리
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.4, 0.8, 0.8)
	tail.Shape = Enum.PartType.Wedge
	tail.Color = Color3.fromRGB(255, 170, 80)
	tail.Material = Enum.Material.Concrete
	tail.Anchored = false
	tail.CanCollide = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = tail
	weld.Parent = body
	tail.CFrame = body.CFrame * CFrame.new(0, 0, 1.0) * CFrame.Angles(math.rad(90), 0, 0)
	tail.Parent = model
	
	-- 디테일 (지느러미, 눈) - 용접 필요
	local function addDetail(name, size, cf, color, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		if shape then p.Shape = shape end
		p.Color = color
		p.Material = Enum.Material.Concrete
		p.Anchored = false
		p.CanCollide = false
		p.CFrame = body.CFrame * cf
		p.Parent = model
		
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = p
		w.Parent = body
		return p
	end
	
	-- 지느러미
	addDetail("FinTop", Vector3.new(0.2, 0.4, 0.6), CFrame.new(0, 0.5, 0), Color3.fromRGB(255, 170, 80), Enum.PartType.Wedge)
	addDetail("FinBottom", Vector3.new(0.2, 0.4, 0.6), CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(180), 0, 0), Color3.fromRGB(255, 170, 80), Enum.PartType.Wedge)
	
	-- 눈
	addDetail("EyeL", Vector3.new(0.1, 0.1, 0.1), CFrame.new(-0.6, 0.1, -0.5), Color3.fromRGB(0, 0, 0), Enum.PartType.Ball)
	addDetail("EyeR", Vector3.new(0.1, 0.1, 0.1), CFrame.new(0.6, 0.1, -0.5), Color3.fromRGB(0, 0, 0), Enum.PartType.Ball)
	
	return model
end

-- Try to load asset
-- 1. Check if it already exists (Manually placed by user)
if assetsFolder:FindFirstChild(ASSET_NAME) then
	print("[AssetLoader] Found existing '" .. ASSET_NAME .. "' in Assets folder. Skipping load.")
	return
end

-- 2. Try to load from Roblox (Server-side)
local success, model = pcall(function()
	return InsertService:LoadAsset(ASSET_ID)
end)

if success and model then
	print("[AssetLoader] Loaded asset container for " .. ASSET_ID)
	
	-- LoadAsset returns a Model containing the asset(s).
	local assetItem = model:GetChildren()[1]
	
	if assetItem then
		-- Clean up the loaded item to ensure it's ready for use
		if assetItem:IsA("Model") or assetItem:IsA("BasePart") or assetItem:IsA("MeshPart") then
			assetItem.Name = ASSET_NAME
			assetItem.Parent = assetsFolder
			
			-- Ensure Anchored is correct for World Item (Anchored) or Inventory (will be cloned)
			-- We'll keep it as default status. Users will Clone() and modify properties.
			
			print("[AssetLoader] Successfully extracted and saved '" .. ASSET_NAME .. "' to ReplicatedStorage.Assets")
		else
			warn("[AssetLoader] Asset " .. ASSET_ID .. " is not a Model/Part. It is: " .. assetItem.ClassName)
			-- Fallback
			local fallback = createProceduralFallback()
			fallback.Parent = assetsFolder
		end
	else
		warn("[AssetLoader] Asset container was empty.")
		local fallback = createProceduralFallback()
		fallback.Parent = assetsFolder
	end
	
	model:Destroy() -- Wrapper
else
	warn("[AssetLoader] Failed to load Asset ID " .. ASSET_ID .. ". Error: " .. tostring(model))
	warn("[AssetLoader] Using Procedural Fallback.")
	
	local fallback = createProceduralFallback()
	fallback.Parent = assetsFolder
end
