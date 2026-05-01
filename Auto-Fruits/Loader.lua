--// LOADER

local Modules = script:WaitForChild("Modules")

local Team = require(Modules.Team)
local Collect = require(Modules.Collect)
local Store = require(Modules.Store)
local ServerHop = require(Modules.ServerHop)
local Rejoin = require(Modules.Rejoin)
local ErrorHandler = require(Modules.ErrorHandler)
local GlobalError = require(Modules.GlobalError)
local MainLoop = require(Modules.MainLoop)

-- Inicializações
GlobalError.Init(Rejoin)
MainLoop.Start(Team, Collect, Store, ServerHop, ErrorHandler)
