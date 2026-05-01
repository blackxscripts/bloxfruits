--// LOADER FINAL (AJUSTADO PRO SEU REPO)

repeat task.wait() until game:IsLoaded()

local BASE = "https://raw.githubusercontent.com/blackxscripts/bloxfruits/main/Auto-Fruits/Modules/"

local function Load(module)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(BASE .. module .. ".lua"))()
    end)
    
    if success then
        return result
    else
        warn("[Loader Error]:", module)
        return nil
    end
end

-- Modules
local Team = Load("Team")
local Collect = Load("Collect")
local Store = Load("Store")
local ServerHop = Load("ServerHop")
local Rejoin = Load("Rejoin")
local ErrorHandler = Load("ErrorHandler")
local GlobalError = Load("GlobalError")
local MainLoop = Load("MainLoop")

-- Safety check
if not (Team and Collect and Store and ServerHop and Rejoin and ErrorHandler and GlobalError and MainLoop) then
    warn("Erro ao carregar módulos")
    return
end

-- Init
pcall(function()
    GlobalError.Init(Rejoin)
end)

pcall(function()
    MainLoop.Start(Team, Collect, Store, ServerHop, ErrorHandler)
end)
