local script = script

local QuestData = {}

-- Episodes 폴더 내의 모든 모듈을 로드하여 QuestData에 병합
local episodesFolder = script.Parent:WaitForChild("Episodes")

for _, module in ipairs(episodesFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		local episodeData = require(module)
		
		-- 병합 로직 (ID 중복 체크)
		for questId, data in pairs(episodeData) do
			if QuestData[questId] then
				warn("Duplicate Quest ID found in " .. module.Name .. ": " .. questId)
			else
				QuestData[questId] = data
			end
		end
	end
end

return QuestData
