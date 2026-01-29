local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local gui = script.Parent
local event = ReplicatedStorage:WaitForChild("KillFeedEvent")

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 300, 0.5, 0)
container.Position = UDim2.new(1, -310, 0, 10)
container.BackgroundTransparency = 1
container.Parent = gui

local listLayout = Instance.new("UIListLayout")
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = container

event.OnClientEvent:Connect(function(killerName, victimName)
	local msg = ""
	if killerName then
		msg = killerName .. " [KILLED] " .. victimName
	else
		msg = victimName .. " [DIED]"
	end
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 25)
	label.BackgroundTransparency = 0.5
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "  " .. msg .. "  "
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Parent = container
	
	Debris:AddItem(label, 5) -- 5초 후 사라짐
end)
