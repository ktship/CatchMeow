local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- [Added] NPC 이름 Localization 테이블 (서버 사이드)
local NPCNames = {
	["Grandpa"] = "앉아있는 노인",
	["Chef"] = "요리사",
}
-- RemoteFunction 생성 및 설정
local dialogueSystemFolder = ReplicatedStorage:FindFirstChild("DialogueSystem")
if not dialogueSystemFolder then
	dialogueSystemFolder = Instance.new("Folder")
	dialogueSystemFolder.Name = "DialogueSystem"
	dialogueSystemFolder.Parent = ReplicatedStorage
end

local startDialogueFunc = dialogueSystemFolder:FindFirstChild("StartDialogue")
if not startDialogueFunc then
	startDialogueFunc = Instance.new("RemoteFunction")
	startDialogueFunc.Name = "StartDialogue"
	startDialogueFunc.Parent = dialogueSystemFolder
end

local selectChoiceEvent = dialogueSystemFolder:FindFirstChild("SelectChoice")
if not selectChoiceEvent then
	selectChoiceEvent = Instance.new("RemoteEvent")
	selectChoiceEvent.Name = "SelectChoice"
	selectChoiceEvent.Parent = dialogueSystemFolder
end

-- DialogueManager 로드 (Lazy Loading)
local DialogueManager

--[=[
    StartDialogue 핸들러
    - 클라이언트가 NPC와 대화를 시도할 때 호출됨
]=]

-- [Added] Reverse Lookup for NPC Names (Display Name -> Key)
local function getNPCKeyFromDisplayName(displayName)
	for key, name in pairs(NPCNames) do
		if name == displayName then
			return key
		end
	end
	return displayName -- 매핑되지 않으면 그대로 반환
end

startDialogueFunc.OnServerInvoke = function(player, npcName)
	-- [Fixed] 클라이언트가 Display Name을 보내줄 수도 있으므로 Key로 변환
	local realNPCName = getNPCKeyFromDisplayName(npcName)
	
	-- print("[DialogueServer] " .. player.Name .. " requested dialogue with " .. npcName .. " (Key: " .. realNPCName .. ")")
	
	if not DialogueManager then
		local module = dialogueSystemFolder:FindFirstChild("DialogueManager")
		if module then
			DialogueManager = require(module)
		else
			warn("[DialogueServer] DialogueManager module NOT found in " .. dialogueSystemFolder:GetFullName())
			return nil
		end
	end
	
	return DialogueManager.StartDialogue(player, realNPCName)
end

--[=[
    SelectChoice 핸들러
    - 대화 중 선택지를 골랐을 때 상태 업데이트 등 처리
]=]
selectChoiceEvent.OnServerEvent:Connect(function(player, npcName, choiceData)
	-- 상태 저장(SetState)이나 아이템 지급 등의 서버 사이드 로직 처리
	if choiceData.SetState then
		local npcKey = npcName or "Unknown"
		local stateKey = "ST_" .. npcKey
		player:SetAttribute(stateKey, choiceData.SetState)
		-- print("[DialogueServer] Updated state for " .. player.Name .. " (" .. tostring(npcName) .. ") -> " .. tostring(choiceData.SetState))
	end

	-- 아이템 지급 예시 (GrandpaData에는 Action 필드가 없지만 확장성을 위해)
	if choiceData.Action == "GiveItem" and choiceData.ItemID then
		if _G.InventoryManager then
			_G.InventoryManager.AddItem(player, choiceData.ItemID, choiceData.Amount or 1)
		end
	end
end)


--[=[
    NPC 설정 (자동화)
    - Workspace 내의 NPC를 찾아 ProximityPrompt 추가
]=]
local function setupNPC(npcModel)
	if not npcModel:IsA("Model") then return end
	
	-- 상호작용 가능한 파트 찾기 (HRP -> Torso -> Head -> PrimaryPart)
	local interactPart = npcModel:FindFirstChild("HumanoidRootPart")
		or npcModel:FindFirstChild("Torso")
		or npcModel:FindFirstChild("UpperTorso")
		or npcModel:FindFirstChild("Head")
		or npcModel.PrimaryPart
	
	if not interactPart then
		warn("[DialogueServer] No interactable part found for NPC: " .. npcModel.Name)
		return
	end
	
	-- 이미 Prompt가 있는지 확인
	if interactPart:FindFirstChild("DialoguePrompt") then return end
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DialoguePrompt"
	prompt.ActionText = "대화하기"
	-- [Modified] Localization 적용
	local displayName = NPCNames[npcModel.Name] or npcModel.Name
	prompt.ObjectText = displayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = interactPart
	
	-- print("[DialogueServer] Added ProximityPrompt to " .. npcModel.Name .. " (attached to " .. interactPart.Name .. ")")
end

-- NPC 찾기 및 설정
local function scanForNPCs()
	-- print("[DialogueServer] Scanning for NPCs...")
	
	-- 1. NPCs 폴더 확인 (고정된 폴더)
	local npcsFolder = workspace:FindFirstChild("NPCs")
	if npcsFolder then
		for _, npc in ipairs(npcsFolder:GetChildren()) do
			setupNPC(npc)
		end
		npcsFolder.ChildAdded:Connect(setupNPC)
	end
	
	-- 2. Map 폴더 확인 (동적 생성)
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then
		-- 맵이 아직 없으면 생성을 대기
		-- print("[DialogueServer] Waiting for Map folder...")
		mapFolder = workspace:WaitForChild("Map", 10) 
	end
	
	if mapFolder then
		-- print("[DialogueServer] Map folder found. Scanning internal NPCs...")
		-- 맵 안의 모든 모델을 검색 (Grandpa가 바로 자식이 아닐 수도 있음. 하지만 보통 자식임)
		for _, child in ipairs(mapFolder:GetChildren()) do
			if child:IsA("Model") and (child.Name == "Grandpa" or child.Name == "Chef") then
				setupNPC(child)
			end
		end
		
		-- 맵이 재생성될 수도 있으므로 ChildAdded 연결
		mapFolder.ChildAdded:Connect(function(child)
			if child:IsA("Model") and (child.Name == "Grandpa" or child.Name == "Chef") then
				setupNPC(child)
			end
		end)
	else
		warn("[DialogueServer] Map folder not found after timeout.")
	end

	-- 3. 혹시 모를 전역 검색 (최후의 수단)
	local grandpa = workspace:FindFirstChild("Grandpa", true) -- Recursive
	if grandpa then setupNPC(grandpa) end
end

-- 초기화 시 실행 (맵 시스템 로딩 시간 고려하여 약간 지연)
task.delay(3, scanForNPCs) -- 1초 -> 3초로 늘림

-- 맵이 리셋되는 경우(ClearMap)를 대비해 Workspace.ChildAdded로 Map 감지
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Map" then
		task.wait(1) -- 맵 내부 로딩 대기
		-- print("[DialogueServer] New Map detected. Rescanning...")
		-- 새 맵의 자식들 스캔
		for _, grandChild in ipairs(child:GetChildren()) do
			if grandChild:IsA("Model") and (grandChild.Name == "Grandpa" or grandChild.Name == "Chef") then
				setupNPC(grandChild)
			end
		end
		-- 새 맵에도 이벤트 연결
		child.ChildAdded:Connect(function(newObj)
			if newObj:IsA("Model") and (newObj.Name == "Grandpa" or newObj.Name == "Chef") then
				setupNPC(newObj)
			end
		end)
	end
end)

-- print("[DialogueServer] Initialized")
