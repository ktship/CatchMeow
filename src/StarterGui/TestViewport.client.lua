local ReplicatedStorage = game:GetService("ReplicatedStorage")
task.wait(3)
local items = ReplicatedStorage:FindFirstChild("Items")
if not items then return end
local bp = items:FindFirstChild("Bungeoppang")
if bp then
    print("[TestViewport] Bungeoppang found!")
    for _, d in ipairs(bp:GetDescendants()) do
        if d:IsA("BasePart") then
            print("[TestViewport] Part Name:", d.Name, "Trans:", d.Transparency, "LocalTrans:", d.LocalTransparencyModifier)
        end
    end
end
