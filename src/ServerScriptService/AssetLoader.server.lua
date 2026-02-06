local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Asset Table
local ASSETS_TO_LOAD = {
	{
		ID = 8189863148,
		Name = "Bungeoppang",
		Fallback = function()
			local model = Instance.new("Model")
			model.Name = "Bungeoppang"
			local body = Instance.new("Part")
			body.Name = "Body"
			body.Size = Vector3.new(1.2, 0.8, 1.8)
			body.Shape = Enum.PartType.Ball
			body.Color = Color3.fromRGB(255, 170, 80)
			body.Material = Enum.Material.Concrete
			body.Parent = model
			model.PrimaryPart = body
			return model
		end
	}
}

-- Create Assets folder if not exists
local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
if not assetsFolder then
	assetsFolder = Instance.new("Folder")
	assetsFolder.Name = "Assets"
	assetsFolder.Parent = ReplicatedStorage
end

for _, info in ipairs(ASSETS_TO_LOAD) do
	if assetsFolder:FindFirstChild(info.Name) then
		print("[AssetLoader] Found existing '" .. info.Name .. "'. Skipping.")
		continue
	end
	
	local assetItem = nil
	if info.ID > 0 then
		local success, modelContainer = pcall(function()
			return InsertService:LoadAsset(info.ID)
		end)
		
		if success and modelContainer then
			assetItem = modelContainer:GetChildren()[1]
			if assetItem then
				assetItem.Name = info.Name
				assetItem.Parent = assetsFolder
			end
			modelContainer:Destroy()
		end
	end
	
	if not assetItem then
		print("[AssetLoader] Creating fallback for '" .. info.Name .. "'")
		local fallback = info.Fallback()
		fallback.Parent = assetsFolder
	end
end

print("[AssetLoader] Assets initialization complete.")
