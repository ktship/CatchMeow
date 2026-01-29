-- AssetInitializer.server.lua
-- 이 스크립트는 Tool이 처음 로드될 때 실행되어 필요한 비-스크립트 에셋(Handle, Sound 등)을 생성합니다.
local Tool = script.Parent

if not Tool:FindFirstChild("Handle") then
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	-- 카메라 모양 (약간 박스형)
	handle.Size = Vector3.new(0.8, 0.6, 0.4)
	handle.Color = Color3.new(0.1, 0.1, 0.1)
	handle.Material = Enum.Material.Plastic
	handle.Parent = Tool
	
	local lens = Instance.new("Attachment")
	lens.Name = "Lens"
	lens.Position = Vector3.new(0, 0, -0.2)
	lens.Parent = handle
	
	local sound = Instance.new("Sound")
	sound.Name = "ShutterSound"
	-- 카메라 셔터 소리 (이전에 작동했던 소리)
	sound.SoundId = "rbxassetid://12221976" 
	sound.Volume = 1
	sound.Parent = handle
end

if not Tool:FindFirstChild("FireEvent") then
	local remote = Instance.new("RemoteEvent")
	remote.Name = "FireEvent"
	remote.Parent = Tool
end

script:Destroy() -- 초기화 후 자폭
