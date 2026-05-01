return {
    Join = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Pirates")
        end)
    end
}
