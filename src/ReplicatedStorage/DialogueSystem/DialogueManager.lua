local DialogueManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- NPC별 대화 모듈 캐싱
local NPCModules = {}

--[=[
    StartDialogue
    - 플레이어와 특정 NPC 간의 대화를 시작합니다.
    - 현재 상황(인벤토리, 퀘스트 진행도)을 판단하여 적절한 대사를 출력합니다.
]=]
function DialogueManager.StartDialogue(player, npcName)
    print("[DialogueManager] StartDialogue called for: " .. tostring(npcName))

    local npcDataFolder = ReplicatedStorage:FindFirstChild("DialogueSystem") and ReplicatedStorage.DialogueSystem:FindFirstChild("NPCData")
    
    if not npcDataFolder then
        warn("[DialogueManager] DialogueSystem/NPCData folder not found!")
        return nil
    end

    -- 에피소드별로 NPC 데이터가 분리될 수 있으므로, 재귀적으로 찾거나 명시적인 경로가 필요할 수 있음.
    -- 현재는 Episode_Bungeoppang 폴더 내에 있다고 가정하고 검색
    local npcModuleScript = nil
    
    -- 간단한 검색 로직: 모든 하위 폴더를 뒤져서 npcName + "Data" 모듈을 찾음
    for _, episodeFolder in ipairs(npcDataFolder:GetChildren()) do
        if episodeFolder:IsA("Folder") then
             npcModuleScript = episodeFolder:FindFirstChild(npcName .. "Data")
             if npcModuleScript then break end
        end
    end

    if not npcModuleScript then
        warn("[DialogueManager] Data module for NPC '" .. npcName .. "' not found!")
        return nil
    end

    -- 모듈 로드 (첫 로드 시 캐싱)
    if not NPCModules[npcName] then
        NPCModules[npcName] = require(npcModuleScript)
    end
    local npcModule = NPCModules[npcName]

    -- 2. 해당 NPC에게 저장된 유저의 개별 상태 읽기
    -- 기본값은 "ST_IDLE" (많은 NPC 데이터가 IDLE을 기본으로 함)
    local savedStateKey = "ST_" .. npcName
    local savedState = player:GetAttribute(savedStateKey) or npcModule.DefaultState or "ST_IDLE"
    
    -- 3. [핵심] 종합 판단 로직 실행 (GetActualState)
    -- 인벤토리, 다른 NPC 상태 등을 종합하여 '진짜' 현재 상태를 결정
    local actualState = savedState
    if npcModule.GetActualState then
        actualState = npcModule.GetActualState(player, savedState)
    end
    
    print("[DialogueManager] " .. player.Name .. " talks to " .. npcName .. " | Saved: " .. savedState .. " -> Actual: " .. actualState)

    -- 4. 대화 데이터 가져오기 (Dialogue 필드가 없으면 모듈 자체를 사용)
    local dialogueData
    if npcModule.Dialogue then
        dialogueData = npcModule.Dialogue[actualState]
    else
        dialogueData = npcModule[actualState]
    end
    
    if not dialogueData then
        warn("[DialogueManager] No dialogue data for state: " .. tostring(actualState))
        return nil
    end

    -- 첫 번째 노드 반환 (클라이언트 UI에서 처리하도록 데이터만 넘김)
    -- 실제 UI 표시는 클라이언트 스크립트에서 처리해야 함
    
    local result = {
        NPCName = npcName, -- [중요] 반드시 인자로 받은 npcName을 반환해야 함
        State = actualState,
        DialogueData = dialogueData
    }
    
    print("[DialogueManager] Returning data, NPCName: " .. tostring(result.NPCName))
    return result
end

return DialogueManager
