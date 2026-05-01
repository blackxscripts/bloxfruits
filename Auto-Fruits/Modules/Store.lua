return {
    Run = function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        
        local LocalPlayer = Players.LocalPlayer
        
        for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and string.find(v.Name:lower(), "fruit") then
                pcall(function()
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", v.Name)
                end)
            end
        end
    end
}
