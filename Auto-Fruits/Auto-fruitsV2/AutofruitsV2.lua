--// BLACK X SCRIPTS™
--// AUTO FRUITS V2
--// TOTALMENTE AUTOMÁTICO | SEM UI

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlaceId = game.PlaceId

repeat task.wait() until Player.Character

local Character = Player.Character
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

--// LISTA DE PRIORIDADE

local FruitList = {
    "Dragon-Dragon",
    "Kitsune-Kitsune",
    "Yeti-Yeti",
    "Tiger-Tiger",
    "Spirit-Spirit",
    "Gas-Gas",
    "Venom-Venom",
    "Shadow-Shadow",
    "Dough-Dough",
    "T-Rex-T-Rex",
    "Mammoth-Mammoth",
    "Gravity-Gravity",
    "Blizzard-Blizzard",
    "Pain-Pain",
    "Lightning-Lightning",
    "Control-Control",
    "Portal-Portal",
    "Phoenix-Phoenix",
    "Sound-Sound",
    "Spider-Spider",
    "Creation-Creation",
    "Love-Love",
    "Buddha-Buddha",
    "Quake-Quake",
    "Magma-Magma",
    "Ghost-Ghost",
    "Rubber-Rubber",
    "Light-Light",
    "Diamond-Diamond",
    "Eagle-Eagle",
    "Dark-Dark",
    "Sand-Sand",
    "Ice-Ice",
    "Flame-Flame",
    "Spike-Spike",
    "Smoke-Smoke",
    "Bomb-Bomb",
    "Spring-Spring",
    "Blade-Blade",
    "Spin-Spin",
    "Rocket-Rocket"
}

--// ENTRAR EM PIRATAS

pcall(function()
    game:GetService("ReplicatedStorage")
        .Remotes
        .CommF_:InvokeServer("SetTeam", "Pirates")
end)

--// ATUALIZAR PERSONAGEM

local function UpdateCharacter()
    Character = Player.Character or Player.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

--// TWEEN

local function TweenTo(Position)
    UpdateCharacter()

    local Distance = (HumanoidRootPart.Position - Position).Magnitude
    local Speed = 325

    local Tween = TweenService:Create(
        HumanoidRootPart,
        TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear),
        {
            CFrame = CFrame.new(Position)
        }
    )

    Tween:Play()
    Tween.Completed:Wait()
end

--// PEGAR TODAS AS FRUTAS

local function GetFruits()
    local Fruits = {}

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") then

            for Index, FruitName in ipairs(FruitList) do

                if string.find(v.Name, FruitName) then

                    table.insert(Fruits, {
                        Tool = v,
                        Name = v.Name,
                        Position = v.Handle.Position,
                        Priority = Index
                    })

                    break
                end
            end
        end
    end

    return Fruits
end

--// ORDENAR RARIDADE

local function SortFruits(Fruits)

    table.sort(Fruits, function(a, b)
        return a.Priority < b.Priority
    end)

    return Fruits
end

--// GUARDAR FRUTA

local function StoreFruit(Name)

    pcall(function()

        local Tool =
            Player.Backpack:FindFirstChild(Name)
            or Character:FindFirstChild(Name)

        if Tool then

            game:GetService("ReplicatedStorage")
                .Remotes
                .CommF_:InvokeServer(
                    "StoreFruit",
                    Tool:GetAttribute("OriginalName") or Tool.Name
                )
        end
    end)
end

--// COLETAR FRUTA

local function CollectFruit(Data)

    if not Data then
        return
    end

    if not Data.Tool or not Data.Tool.Parent then
        return
    end

    TweenTo(Data.Position)

    task.wait(0.4)

    pcall(function()

        firetouchinterest(
            HumanoidRootPart,
            Data.Tool.Handle,
            0
        )

        firetouchinterest(
            HumanoidRootPart,
            Data.Tool.Handle,
            1
        )
    end)

    task.wait(1)

    StoreFruit(Data.Tool.Name)
end

--// SERVER HOP

local function ServerHop()

    local Success, Response = pcall(function()

        return game:HttpGet(
            "https://games.roblox.com/v1/games/" ..
            PlaceId ..
            "/servers/Public?sortOrder=Asc&limit=100"
        )
    end)

    if not Success then
        return
    end

    local Data = HttpService:JSONDecode(Response)

    local Servers = {}

    for _, Server in pairs(Data.data) do

        if Server.playing < Server.maxPlayers
        and Server.id ~= game.JobId then

            table.insert(Servers, Server.id)
        end
    end

    if #Servers > 0 then

        TeleportService:TeleportToPlaceInstance(
            PlaceId,
            Servers[math.random(1, #Servers)],
            Player
        )
    end
end

--// LOOP PRINCIPAL

while task.wait(2) do

    local Fruits = GetFruits()

    if #Fruits > 0 then

        Fruits = SortFruits(Fruits)

        for _, Fruit in ipairs(Fruits) do

            if Fruit.Tool
            and Fruit.Tool.Parent then

                CollectFruit(Fruit)

                task.wait(1)
            end
        end

    else
        ServerHop()
    end
end
