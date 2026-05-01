return {
    Run = function()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        
        local PlaceId = game.PlaceId
        local JobId = game.JobId
        
        local servers = {}
        
        local req = game:HttpGet(
            "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        )
        
        local data = HttpService:JSONDecode(req)
        
        for _, v in pairs(data.data) do
            if v.playing < v.maxPlayers and v.id ~= JobId then
                table.insert(servers, v.id)
            end
        end
        
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1,#servers)])
        else
            TeleportService:Teleport(PlaceId)
        end
    end
}
