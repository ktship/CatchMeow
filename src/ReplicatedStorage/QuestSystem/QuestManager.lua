local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local QuestData = require(ReplicatedStorage:WaitForChild("QuestSystem"):WaitForChild("QuestData"))

-- [RemoteEvents]
-- 서버와 통신을 위한 리모트 이벤트 폴더 및 이벤트 생성 (없으면 생성)
local remotesFolder = ReplicatedStorage:FindFirstChild("QuestRemotes")
if not remotesFolder then
	-- 클라이언트에서는 생성 불가, 서버가 생성했다고 가정하고 대기
    -- 실제로는 서버 스크립트가 먼저 실행되어 생성해야 함
	remotesFolder = ReplicatedStorage:WaitForChild("QuestRemotes")
end

local acceptQuestEvent = remotesFolder:WaitForChild("AcceptQuest")
local updateObjectiveEvent = remotesFolder:WaitForChild("UpdateObjective")
local completeQuestEvent = remotesFolder:WaitForChild("CompleteQuest")
local questUpdateEvent = remotesFolder:WaitForChild("QuestUpdate") -- 서버 -> 클라이언트 상태 갱신 알림

local QuestManager = {}
QuestManager.CurrentQuests = {} -- 현재 진행 중인 퀘스트 목록 (로컬 캐시)

-- 퀘스트 수락 요청
function QuestManager.AcceptQuest(questId)
	if QuestData[questId] then
		acceptQuestEvent:FireServer(questId)
	else
		warn("Quest ID not found: " .. tostring(questId))
	end
end

-- 목표 업데이트 요청 (예: 아이템 획득, 사진 촬영 등)
function QuestManager.UpdateObjective(objectiveType, targetId, amount)
	updateObjectiveEvent:FireServer(objectiveType, targetId, amount)
end

-- 퀘스트 완료 요청
function QuestManager.CompleteQuest(questId)
	completeQuestEvent:FireServer(questId)
end

-- 서버로부터 퀘스트 상태 업데이트 수신
questUpdateEvent.OnClientEvent:Connect(function(updatedQuests)
	QuestManager.CurrentQuests = updatedQuests
	-- UI 업데이트 이벤트 발생 등 추가 로직 필요
	print("Quest Updated!", updatedQuests)
end)

return QuestManager
