local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local QuestData = require(ReplicatedStorage:WaitForChild("QuestSystem"):WaitForChild("QuestData"))

-- [RemoteEvents]
-- 클라이언트와 통신할 이벤트를 담을 폴더 생성
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "QuestRemotes"
remotesFolder.Parent = ReplicatedStorage

local acceptQuestEvent = Instance.new("RemoteEvent")
acceptQuestEvent.Name = "AcceptQuest"
acceptQuestEvent.Parent = remotesFolder

local updateObjectiveEvent = Instance.new("RemoteEvent")
updateObjectiveEvent.Name = "UpdateObjective"
updateObjectiveEvent.Parent = remotesFolder

local completeQuestEvent = Instance.new("RemoteEvent")
completeQuestEvent.Name = "CompleteQuest"
completeQuestEvent.Parent = remotesFolder

local questUpdateEvent = Instance.new("RemoteEvent")
questUpdateEvent.Name = "QuestUpdate"
questUpdateEvent.Parent = remotesFolder

local QuestService = {}
local PlayerQuests = {} -- [PlayerUserId] = { QuestID = {Status = "Active", Objectives = {...}} }

-- 플레이어 접속 시 데이터 로드 (현재는 메모리 저장만 구현)
Players.PlayerAdded:Connect(function(player)
	PlayerQuests[player.UserId] = {}
	-- TODO: DataStore 로드 로직 추가
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerQuests[player.UserId] = nil
	-- TODO: DataStore 저장 로직 추가
end)

-- 퀘스트 수락 처리
acceptQuestEvent.OnServerEvent:Connect(function(player, questId)
	if not QuestData[questId] then return end
	
	local playerQuest = PlayerQuests[player.UserId]
	if not playerQuest then playerQuest = {} PlayerQuests[player.UserId] = playerQuest end
	
	if not playerQuest[questId] then
		playerQuest[questId] = {
			Status = "Active",
			Objectives = {} -- 목표 진행도 초기화
		}
		-- 목표 데이터 초기화
		for _, objective in ipairs(QuestData[questId].Objectives) do
			table.insert(playerQuest[questId].Objectives, {
				Type = objective.Type,
				Target = objective.Target,
				CurrentCount = 0,
				RequiredCount = objective.Count,
                Description = objective.Description
			})
		end
		

		questUpdateEvent:FireClient(player, playerQuest) -- 클라이언트에 상태 전송
	else
		warn(player.Name .. " already has quest: " .. questId)
	end
end)

-- 퀘스트 목표 업데이트 처리
updateObjectiveEvent.OnServerEvent:Connect(function(player, objectiveType, targetId, amount)
    local playerQuest = PlayerQuests[player.UserId]
    if not playerQuest then return end

    local updated = false
    for questId, questState in pairs(playerQuest) do
        if questState.Status == "Active" then
            for _, objective in ipairs(questState.Objectives) do
                if objective.Type == objectiveType and objective.Target == targetId then
                    if objective.CurrentCount < objective.RequiredCount then
                        objective.CurrentCount = math.min(objective.CurrentCount + (amount or 1), objective.RequiredCount)
                        updated = true
                    end
                end
            end
        end
    end

    if updated then
        questUpdateEvent:FireClient(player, playerQuest)
    end
end)

-- 퀘스트 완료 처리
completeQuestEvent.OnServerEvent:Connect(function(player, questId)
    local playerQuest = PlayerQuests[player.UserId]
    if not playerQuest or not playerQuest[questId] then return end

    local questState = playerQuest[questId]
    if questState.Status ~= "Active" then return end

    -- 모든 목표 달성 확인
    local completed = true
    for _, objective in ipairs(questState.Objectives) do
        if objective.CurrentCount < objective.RequiredCount then
            completed = false
            break
        end
    end

    if completed then
        questState.Status = "Completed"
        -- 보상 지급 로직 (QuestData[questId].Rewards 참조)
        local rewards = QuestData[questId].Rewards
        if rewards then
            -- 예: 돈, 경험치, 아이템 지급
            if rewards.Money then
                -- TODO: 플레이어 돈 증가

            end
             if rewards.Exp then
                -- TODO: 경험치 증가

            end
             if rewards.Item then
                -- TODO: 아이템 지급

            end
        end


        questUpdateEvent:FireClient(player, playerQuest)
    end
end)

return QuestService
