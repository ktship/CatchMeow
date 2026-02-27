-- ItemGenerator.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
if not itemsFolder then
	itemsFolder = Instance.new("Folder")
	itemsFolder.Name = "Items"
	itemsFolder.Parent = ReplicatedStorage
end

local function createModel(name, partsCallback)
	if itemsFolder:FindFirstChild(name) then return end
	local model = Instance.new("Model")
	model.Name = name
	partsCallback(model)
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildOfClass("BasePart")
	end
	model.Parent = itemsFolder
end

-- 1. CatCan (고양이 통조림)
createModel("CatCan", function(model)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(1.2, 2, 2) -- x축이 높이
	base.Color = Color3.fromRGB(180, 180, 180) -- 은색 캔
	base.Material = Enum.Material.Metal
	base.CFrame = CFrame.Angles(0, 0, math.rad(90))
	base.Parent = model
	
	-- 라벨 (표면에 이미지 데칼 추가)
	local label = Instance.new("Part")
	label.Name = "Label"
	label.Shape = Enum.PartType.Cylinder
	label.Size = Vector3.new(0.8, 2.05, 2.05)
	label.Color = Color3.fromRGB(255, 140, 50) -- 주황색 라벨
	label.Material = Enum.Material.SmoothPlastic
	label.CFrame = CFrame.Angles(0, 0, math.rad(90))
	label.Parent = model
	
	-- 고양이 발자국 데칼 (통조림 앞/뒤 표시용)
	local decal1 = Instance.new("Decal")
	decal1.Texture = "rbxassetid://11767069582" -- 발자국 이미지
	decal1.Face = Enum.NormalId.Top -- 실린더의 곡면에 맞게 (X축 방향이 높이이므로 좌/우면 중 하나)
	decal1.Parent = label
	
	local decal2 = decal1:Clone()
	decal2.Face = Enum.NormalId.Bottom
	decal2.Parent = label
	
	-- 캔 윗면 (조금 더 밝은 은색 테두리 효과)
	local topRim = Instance.new("Part")
	topRim.Name = "TopRim"
	topRim.Shape = Enum.PartType.Cylinder
	topRim.Size = Vector3.new(0.1, 1.9, 1.9)
	topRim.Color = Color3.fromRGB(220, 220, 220)
	topRim.Material = Enum.Material.Metal
	-- Cylinder의 X축이 높이이므로 X방향으로 오프셋을 줍니다.
	topRim.CFrame = CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(0.55, 0, 0)
	topRim.Parent = model
	
	-- 캔 따개(손잡이)
	local pullTab = Instance.new("Part")
	pullTab.Name = "PullTab"
	pullTab.Size = Vector3.new(0.3, 0.05, 0.5)
	pullTab.Color = Color3.fromRGB(200, 200, 200)
	pullTab.Material = Enum.Material.Metal
	-- 윗면에 얹기 위해 원래 자세(CFrame) 기준으로 회전 후 윗면(Y축)에 붙임
	pullTab.CFrame = CFrame.new(0, 0.6, 0.65)
	pullTab.Parent = model

	local w1 = Instance.new("WeldConstraint"); w1.Part0 = base; w1.Part1 = label; w1.Parent = base
	local w2 = Instance.new("WeldConstraint"); w2.Part0 = base; w2.Part1 = topRim; w2.Parent = base
	local w3 = Instance.new("WeldConstraint"); w3.Part0 = base; w3.Part1 = pullTab; w3.Parent = base
	
	model.PrimaryPart = base
end)

-- 2. CatChuru (고양이 츄르)
createModel("CatChuru", function(model)
	local stick = Instance.new("Part")
	stick.Name = "Stick"
	stick.Size = Vector3.new(0.15, 2.5, 0.4)
	stick.Color = Color3.fromRGB(255, 100, 130) -- 조금 더 화사한 핑크색으로 변경
	stick.Material = Enum.Material.SmoothPlastic
	stick.Parent = model
	
	-- 아랫부분 둥근 마감
	local bottom = Instance.new("Part")
	bottom.Name = "Bottom"
	bottom.Shape = Enum.PartType.Cylinder
	bottom.Size = Vector3.new(0.15, 0.4, 0.4)
	bottom.Color = Color3.fromRGB(255, 100, 130)
	bottom.Material = Enum.Material.SmoothPlastic
	bottom.CFrame = CFrame.new(0, -1.25, 0) -- 츄르 막대 하단에 부착. 회전하지 않음
	bottom.Parent = model
	
	-- 윗부분 뜯는 곳(절취선 봉제선 느낌)
	local topSeal = Instance.new("Part")
	topSeal.Name = "TopSeal"
	topSeal.Size = Vector3.new(0.16, 0.3, 0.42)
	topSeal.Color = Color3.fromRGB(255, 140, 170)
	topSeal.Material = Enum.Material.Plastic
	topSeal.CFrame = CFrame.new(0, 1.25, 0)
	topSeal.Parent = model
	
	-- 츄르 중앙 라벨 느낌
	local centerLabel = Instance.new("Part")
	centerLabel.Name = "CenterLabel"
	centerLabel.Size = Vector3.new(0.16, 1.2, 0.41)
	centerLabel.Color = Color3.fromRGB(255, 255, 255)
	centerLabel.Material = Enum.Material.SmoothPlastic
	centerLabel.CFrame = CFrame.new(0, 0, 0)
	centerLabel.Parent = model

	local w1 = Instance.new("WeldConstraint"); w1.Part0 = stick; w1.Part1 = bottom; w1.Parent = stick
	local w2 = Instance.new("WeldConstraint"); w2.Part0 = stick; w2.Part1 = topSeal; w2.Parent = stick
	local w3 = Instance.new("WeldConstraint"); w3.Part0 = stick; w3.Part1 = centerLabel; w3.Parent = stick
	
	model.PrimaryPart = stick
end)

-- 3. SpeedBoost (에너지 드링크)
createModel("SpeedBoost", function(model)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(2.5, 1, 1) -- 얇고 긴 캔
	base.Color = Color3.fromRGB(50, 100, 255) -- 파란색 캔
	base.Material = Enum.Material.Metal
	base.CFrame = CFrame.Angles(0, 0, math.rad(90))
	base.Parent = model
	
	-- 음료수 라벨
	local label = Instance.new("Part")
	label.Name = "Label"
	label.Shape = Enum.PartType.Cylinder
	label.Size = Vector3.new(1.8, 1.02, 1.02)
	label.Color = Color3.fromRGB(20, 20, 20) -- 검정색 라벨
	label.Material = Enum.Material.SmoothPlastic
	label.CFrame = CFrame.Angles(0, 0, math.rad(90))
	label.Parent = model
	
	-- 포인트 데칼 (에너지 표시 역할)
	local decal1 = Instance.new("Decal")
	decal1.Texture = "rbxassetid://11767069582" -- 발자국 이미지 혹은 번개 모양 등
	decal1.Face = Enum.NormalId.Top
	decal1.Parent = label
	
	local topRim = Instance.new("Part")
	topRim.Name = "TopRim"
	topRim.Shape = Enum.PartType.Cylinder
	topRim.Size = Vector3.new(0.1, 0.95, 0.95)
	topRim.Color = Color3.fromRGB(200, 200, 200)
	topRim.Material = Enum.Material.Metal
	topRim.CFrame = CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(1.2, 0, 0)
	topRim.Parent = model

	local w1 = Instance.new("WeldConstraint"); w1.Part0 = base; w1.Part1 = label; w1.Parent = base
	local w2 = Instance.new("WeldConstraint"); w2.Part0 = base; w2.Part1 = topRim; w2.Parent = base

	model.PrimaryPart = base
end)

-- 4. Stick (나뭇가지/통나무)
createModel("Stick", function(model)
	local wood = Instance.new("Part")
	wood.Name = "Wood"
	wood.Shape = Enum.PartType.Cylinder
	wood.Size = Vector3.new(3, 0.5, 0.5)
	wood.Color = Color3.fromRGB(110, 70, 30)
	wood.Material = Enum.Material.Wood
	-- 다른 축 방향으로 회전시키기 (Z축 기준 90도 회전 삭제 -> Y/Z축 등 다른 형태로 세움)
	wood.CFrame = CFrame.Angles(math.rad(90), 0, 0)
	wood.Parent = model
	
	-- 곁가지 1 (비스듬히 자연스럽게)
	local branch1 = Instance.new("Part")
	branch1.Name = "Branch1"
	branch1.Shape = Enum.PartType.Cylinder
	branch1.Size = Vector3.new(1.2, 0.15, 0.15)
	branch1.Color = Color3.fromRGB(110, 70, 30)
	branch1.Material = Enum.Material.Wood
	branch1.CFrame = wood.CFrame * CFrame.new(0.5, 0.4, 0) * CFrame.Angles(0, 0, math.rad(30))
	branch1.Parent = model
	
	-- 곁가지 2
	local branch2 = Instance.new("Part")
	branch2.Name = "Branch2"
	branch2.Shape = Enum.PartType.Cylinder
	branch2.Size = Vector3.new(0.8, 0.1, 0.1)
	branch2.Color = Color3.fromRGB(110, 70, 30)
	branch2.Material = Enum.Material.Wood
	branch2.CFrame = wood.CFrame * CFrame.new(-0.7, -0.25, 0) * CFrame.Angles(0, 0, math.rad(-45))
	branch2.Parent = model

	local w1 = Instance.new("WeldConstraint"); w1.Part0 = wood; w1.Part1 = branch1; w1.Parent = wood
	local w2 = Instance.new("WeldConstraint"); w2.Part0 = wood; w2.Part1 = branch2; w2.Parent = wood
	
	model.PrimaryPart = wood
end)

print("[ItemGenerator] All dummy item models have been created in ReplicatedStorage.Items")
