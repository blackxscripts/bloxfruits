return {
    Run = function()
        local TeleportService = game:GetService("TeleportService")
        task.wait(3)
        TeleportService:Teleport(game.PlaceId)
    end
}
