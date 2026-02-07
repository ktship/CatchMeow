-- InventoryManager.server.lua
-- 서버 측 인벤토리 관리
-- ServerScriptService에 위치

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

-- 플레이어별 인벤토리 저장 (세션 기반, 저장 안 함)
local PlayerInventories = {}

-- RemoteEvents 생성
local eventsFolder = ReplicatedStorage:WaitForChild("Events")

local pickupEvent = Instance.new("RemoteEvent")
pickupEvent.Name = "PickupItem"
pickupEvent.Parent = eventsFolder

local useEvent = Instance.new("RemoteEvent")
useEvent.Name = "UseItem"
useEvent.Parent = eventsFolder

local updateEvent = Instance.new("RemoteEvent")
updateEvent.Name = "UpdateInventory"
updateEvent.Parent = eventsFolder

local buyEvent = Instance.new("RemoteEvent")
buyEvent.Name = "BuyItem"
buyEvent.Parent = eventsFolder

-- 인벤토리에 아이템 추가
local function addItem(player, itemId, count)
	count = count or 1
	local itemDef = ItemData.GetItem(itemId)
	if not itemDef then 
		warn("[InventoryManager] Unknown Item ID: " .. tostring(itemId))
		return false 
	end
	
	local inv = PlayerInventories[player]
	if not inv then 
		warn("[InventoryManager] No inventory for player: " .. player.Name)
		return false 
	end
	
	print("[InventoryManager] Adding " .. count .. "x " .. itemId .. " to " .. player.Name)
	
	-- 기존 슬롯 찾기
	for _, slot in ipairs(inv) do
		if slot.ItemId == itemId then
			local space = itemDef.MaxStack - slot.Count
			local toAdd = math.min(count, space)
			slot.Count = slot.Count + toAdd
			count = count - toAdd
			if count <= 0 then break end
		end
	end
	
	-- 남은 수량 새 슬롯에 추가
	if count > 0 then
		table.insert(inv, {ItemId = itemId, Count = count})
	end
	
	-- 변경 사항 전송
	print("[InventoryManager] Inventory updated for " .. player.Name)
	updateEvent:FireClient(player, inv)
	
	return true
end

-- 아이템 사용
local function useItem(player, slotIndex)
	local inv = PlayerInventories[player]
	if not inv or not inv[slotIndex] then return end
	
	local slot = inv[slotIndex]
	local itemDef = ItemData.GetItem(slot.ItemId)
	if not itemDef then return end
	
	-- 효과 적용
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	
	if itemDef.Effect == "SpeedUp" and humanoid then
		humanoid.WalkSpeed = humanoid.WalkSpeed + 8
		task.delay(10, function()
			if humanoid and humanoid.Parent then
				humanoid.WalkSpeed = math.max(16, humanoid.WalkSpeed - 8)
			end
		end)
		print(player.Name .. " used " .. itemDef.Name .. " - Speed Up!")
	elseif itemDef.Effect == "LureCat" then
		-- TODO: 고양이 유인 효과
		print(player.Name .. " used " .. itemDef.Name .. " - Lure Cat!")
	else
		print(player.Name .. " used " .. itemDef.Name)
	end
	
	-- 수량 감소
	slot.Count = slot.Count - 1
	if slot.Count <= 0 then
		table.remove(inv, slotIndex)
	end
	
	updateEvent:FireClient(player, inv)
end

-- 아이템 구매
local function buyItem(player, itemId)
	local itemDef = ItemData.GetItem(itemId)
	if not itemDef then return end
	
	-- TODO: 화폐 시스템 연동 (현재는 무료)
	-- local stats = player:FindFirstChild("leaderstats")
	-- if stats and stats.Coins.Value >= itemDef.Price then
	--     stats.Coins.Value = stats.Coins.Value - itemDef.Price
	--     addItem(player, itemId, 1)
	-- end
	
	-- 테스트: 무조건 지급
	addItem(player, itemId, 1)
	print(player.Name .. " bought " .. itemDef.Name)
end

-- 월드 아이템 클릭 처리 (ClickDetector 사용)
local function setupWorldItem(itemPart, itemId, clickDetector)
	if not clickDetector then
		clickDetector = itemPart:FindFirstChildOfClass("ClickDetector")
	end
	if not clickDetector then return end
	
	clickDetector.MouseClick:Connect(function(player)
		-- [v4.3] Block pickup if being eaten by a cat
		if itemPart:GetAttribute("EatingBy") then
			warn("[InventoryManager] Item is being eaten and cannot be picked up.")
			return 
		end
		
		if addItem(player, itemId, 1) then
			-- 아이템 제거
			itemPart:Destroy()
		end
	end)
end


-- 플레이어 초기화
Players.PlayerAdded:Connect(function(player)
	PlayerInventories[player] = {}
	
	-- 기본 아이템 지급: 붕어빵 1개
	addItem(player, "Bungeoppang", 1)
	
	-- 클라이언트에 인벤토리 전송
	updateEvent:FireClient(player, PlayerInventories[player])
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerInventories[player] = nil
end)

-- 기존 플레이어 처리
for _, player in ipairs(Players:GetPlayers()) do
	PlayerInventories[player] = {}
	addItem(player, "Bungeoppang", 1)
	updateEvent:FireClient(player, PlayerInventories[player])
end

-- Remote 이벤트 연결
useEvent.OnServerEvent:Connect(function(player, slotIndex)
	useItem(player, slotIndex)
end)

buyEvent.OnServerEvent:Connect(function(player, itemId)
	buyItem(player, itemId)
end)

local requestUpdateEvent = eventsFolder:FindFirstChild("RequestInventoryUpdate")
if not requestUpdateEvent then
	requestUpdateEvent = Instance.new("RemoteEvent")
	requestUpdateEvent.Name = "RequestInventoryUpdate"
	requestUpdateEvent.Parent = eventsFolder
end

requestUpdateEvent.OnServerEvent:Connect(function(player)
	local inv = PlayerInventories[player]
	if inv then
		print("[InventoryManager] Resending inventory to " .. player.Name .. " (Request)")
		updateEvent:FireClient(player, inv)
	else
		-- 초기화되지 않았으면 초기화 후 전송
		PlayerInventories[player] = {}
		addItem(player, "Bungeoppang", 1)
		updateEvent:FireClient(player, PlayerInventories[player])
	end
end)

-- 아이템 배치 (PlaceItem)
local placeEvent = eventsFolder:FindFirstChild("PlaceItem")
if not placeEvent then
	placeEvent = Instance.new("RemoteEvent")
	placeEvent.Name = "PlaceItem"
	placeEvent.Parent = eventsFolder
end

placeEvent.OnServerEvent:Connect(function(player, slotIndex, position)
	-- [v4.23q] Server-Side Debounce/Cooldown
	if player:GetAttribute("PlaceCooldown") then return end
	player:SetAttribute("PlaceCooldown", true)
	task.delay(0.5, function() 
		if player then player:SetAttribute("PlaceCooldown", nil) end 
	end)

	local inv = PlayerInventories[player]
	if not inv or not inv[slotIndex] then return end
	
	local slot = inv[slotIndex]
	local itemId = slot.ItemId
	local itemDef = ItemData.GetItem(itemId)
	if not itemDef then return end
	
	-- 거리 체크 (너무 멀리 배치 방지)
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local dist = (char.HumanoidRootPart.Position - position).Magnitude
		if dist > 50 then return end -- 50 stud 이내만 허용
	end
	
	-- 월드에 아이템 생성
	local itemsFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WorldItems")
	if not itemsFolder then
		itemsFolder = Instance.new("Folder")
		itemsFolder.Name = "WorldItems"
		itemsFolder.Parent = workspace:FindFirstChild("Map") or workspace
	end
	
	-- MapGenerator 사용해서 아이템 생성
	local MapGenerator = require(game.ServerScriptService:FindFirstChild("MapGenerator"))
	if MapGenerator and MapGenerator.SpawnWorldItem then
		MapGenerator.SpawnWorldItem(itemId, position, itemsFolder)
	end
	
	-- 인벤토리에서 제거
	slot.Count = slot.Count - 1
	if slot.Count <= 0 then
		table.remove(inv, slotIndex)
	end
	
	updateEvent:FireClient(player, inv)
	print(player.Name .. " placed " .. itemDef.Name .. " at " .. tostring(position))
end)

-- 외부에서 호출 가능하도록 모듈화
_G.InventoryManager = {
	AddItem = addItem,
	SetupWorldItem = setupWorldItem,
}

print("[InventoryManager] Initialized")
