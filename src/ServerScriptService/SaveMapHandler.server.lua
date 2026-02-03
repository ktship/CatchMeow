-- SaveMapHandler.server.lua
-- Creates Remote and handles save request

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local MapGenerator = require(ServerScriptService.MapGenerator)

local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = ReplicatedStorage
end

local saveEvent = eventsFolder:FindFirstChild("SaveMapDebug")
if not saveEvent then
	saveEvent = Instance.new("RemoteEvent")
	saveEvent.Name = "SaveMapDebug"
	saveEvent.Parent = eventsFolder
end

if not plantEvent then
	plantEvent = Instance.new("RemoteEvent")
	plantEvent.Name = "PlantTree"
	plantEvent.Parent = eventsFolder
end

local removeEvent = eventsFolder:FindFirstChild("RemoveTree")
if not removeEvent then
	removeEvent = Instance.new("RemoteEvent")
	removeEvent.Name = "RemoveTree"
	removeEvent.Parent = eventsFolder
end

saveEvent.OnServerEvent:Connect(function(player)
	print("💾 [Debug] User requested Map Save/Export.")
	
	local data = MapGenerator.CurrentData
	if not data then
		warn("⚠️ No Map Data found in Cache! Generating now to export...")
		data = MapGenerator.GenerateProcedural() -- Force regen if missing? Safety fallback.
	end
	
	if data then
		-- 1. Print JSON (for copy-paste)
		local json = HttpService:JSONEncode(data)
		print("----- [DEBUG] MAP DATA EXPORT START -----")
		print(json)
		print("----- [DEBUG] MAP DATA EXPORT END -----")
		
		-- 2. Force Save to DataStore (just in case)
		local DataStoreService = game:GetService("DataStoreService")
		local CityMapStore = DataStoreService:GetDataStore("CityMapData_v1")
		
		local success, err = pcall(function()
			CityMapStore:SetAsync("Map_v1", data)
		end)
		
		if success then
			print("✅ [Debug] Forced Save to DataStore successful!")
		else
			warn("❌ [Debug] Failed to save to DataStore: " .. tostring(err))
		end
	end
end)

plantEvent.OnServerEvent:Connect(function(player, position)
	if not position then return end
	
	-- Verify Map
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then return end
	local groundFolder = mapFolder:FindFirstChild("Ground") or mapFolder
	
	-- Pick Random Style
	local style = math.random(1, 3)
	
	-- Create Visual Tree
	local success, err = pcall(function()
		MapGenerator.SpawnTree(position.X, position.Y, position.Z, groundFolder, style)
	end)
	if not success then
		warn("❌ Failed to spawn tree: " .. tostring(err))
		-- Fallback to old name if something is really weird, or just error.
	end
	
	-- Save to Data {4, x, y, z, style}
	if MapGenerator.CurrentData then
		table.insert(MapGenerator.CurrentData, {4, position.X, position.Y, position.Z, style})
		print("🌲 Manually planted tree (Style " .. style .. ") at", position)
	end
end)

removeEvent.OnServerEvent:Connect(function(player, position)
	if not position then return end
	print("🪓 Request to remove tree at", position)
	
	-- 1. Remove from Data (CurrentData)
	if MapGenerator.CurrentData then
		local targetIndex = nil
		for i, item in ipairs(MapGenerator.CurrentData) do
			if item[1] == 4 then -- Is Tree
				local tx, ty, tz = item[2], item[3], item[4]
				-- Distance Check (Ignore Y axis because Model Pivot might be higher than ground pos)
				local dist2D = math.sqrt((tx - position.X)^2 + (tz - position.Z)^2)
				
				if dist2D < 2.0 then -- Allow small leeway
					targetIndex = i
					break
				end
			end
		end
		
		if targetIndex then
			table.remove(MapGenerator.CurrentData, targetIndex)
			print("✅ Removed tree from saved data.")
		else
			warn("⚠️ Could not find tree in saved data at that position (might be legacy or offset).")
		end
	end
	
	-- 2. Remove Visuals
	local mapFolder = workspace:FindFirstChild("Map")
	if mapFolder then
		local groundFolder = mapFolder:FindFirstChild("Ground") or mapFolder
		local closestDist = 2.0
		local closestTree = nil
		
		for _, child in ipairs(groundFolder:GetChildren()) do
			if child.Name:match("Tree_Type") then
				-- Check primary part or calculate center
				local pos = child:GetPivot().Position
				-- Check flat distance mainly? or full 3D. 3D is fine.
				local dist = (pos - position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestTree = child
				end
			end
		end
		
		if closestTree then
			closestTree:Destroy()
			print("🗑️ Visual tree model destroyed.")
		else
			warn("⚠️ No visual tree model found near click.")
		end
	end
end)
