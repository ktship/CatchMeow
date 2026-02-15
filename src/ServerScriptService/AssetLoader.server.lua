local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

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
		if Config.Debug and Config.Debug.ShowLogs then
			-- print("[AssetLoader] Found existing '" .. info.Name .. "'. Skipping.")
		end
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
				-- [Fix] 만약 Accessory라면 Handle만 추출하여 Part/Model로 변환
				if assetItem:IsA("Accessory") then
					local handle = assetItem:FindFirstChild("Handle") or assetItem:FindFirstChildWhichIsA("BasePart")
					if handle then
						handle.Name = info.Name
						handle.Parent = assetsFolder
						-- 필요없는 속성 제거/초기화
						handle.Anchored = true
						handle.CanCollide = false
						-- 기존 Accessory 삭제
						assetItem:Destroy()
						assetItem = handle -- 참조 업데이트
					else
						-- 핸들이 없으면 그냥 씀 (Fallback)
						assetItem.Name = info.Name
						assetItem.Parent = assetsFolder
					end
				else
					assetItem.Name = info.Name
					assetItem.Parent = assetsFolder
				end
			end
			modelContainer:Destroy()
		end
	end
	
	if not assetItem then
		if Config.Debug and Config.Debug.ShowLogs then
			-- print("[AssetLoader] Creating fallback for '" .. info.Name .. "'")
		end
		local fallback = info.Fallback()
		fallback.Parent = assetsFolder
	end
end

if Config.Debug and Config.Debug.ShowLogs then
	-- print("[AssetLoader] Assets initialization complete.")
end
