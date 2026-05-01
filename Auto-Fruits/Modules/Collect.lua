return {
    Run = function()
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")
        
        local LocalPlayer = Players.LocalPlayer
        local found = false
        
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Tool") and string.find(v.Name:lower(), "fruit") then
                found = true
                
                pcall(function()
                    repeat task.wait()
                        LocalPlayer.Character:PivotTo(v.Handle.CFrame)
                    until not v or not v.Parent
                end)
            end
        end
        
        return found
    end
}
