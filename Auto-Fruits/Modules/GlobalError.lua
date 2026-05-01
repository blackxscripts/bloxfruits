return {
    Init = function(Rejoin)
        local CoreGui = game:GetService("CoreGui")
        
        CoreGui:WaitForChild("RobloxPromptGui").promptOverlay.ChildAdded:Connect(function()
            Rejoin.Run()
        end)
    end
}
