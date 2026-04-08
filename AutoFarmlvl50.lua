-- BLACK X SCRIPTS™ | Auto Farm System V1 (Stable)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "BLACK X SCRIPTS | Auto Farm Lv 50",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by BLACK X SCRIPTS™",
    ConfigurationSaving = {Enabled = true, FolderName = "AutoFarm", FileName = "Config"},
    KeySystem = false
})

local MainTab = Window:CreateTab("Main", 4483362458)

local System = {
    AutoFarm = false,
    Mon = "",
    LevelQuest = 0,
    NameQuest = "",
    CFrameQuest = nil,
    CFrameMon = nil,
    Target = nil,
    CachedMelee = nil,
    UsedCodes = {},
    LastCode = 0,
    LastQuest = 0
}

-- Character
local function GetChar()
    local p = game.Players.LocalPlayer
    repeat task.wait() until p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    return p.Character
end

-- Quest detect
local function HasQuest()
    pcall(function()
        return game.Players.LocalPlayer.PlayerGui.Main.Quest.Visible
    end)
end

-- Quest check
local function CheckQuest()
    local lvl = game.Players.LocalPlayer.Data.Level.Value

    if lvl <= 9 then
        System.Mon = "Bandit"
        System.LevelQuest = 1
        System.NameQuest = "BanditQuest1"
        System.CFrameQuest = CFrame.new(1059,15,1550)
        System.CFrameMon = CFrame.new(1045,27,1560)

    elseif lvl <= 14 then
        System.Mon = "Monkey"
        System.LevelQuest = 1
        System.NameQuest = "JungleQuest"
        System.CFrameQuest = CFrame.new(-1598,35,153)
        System.CFrameMon = CFrame.new(-1448,67,11)

    elseif lvl <= 29 then
        System.Mon = "Gorilla"
        System.LevelQuest = 2
        System.NameQuest = "JungleQuest"
        System.CFrameQuest = CFrame.new(-1598,35,153)
        System.CFrameMon = CFrame.new(-1129,40,-525)

    elseif lvl <= 39 then
        System.Mon = "Pirate"
        System.LevelQuest = 1
        System.NameQuest = "BuggyQuest1"
        System.CFrameQuest = CFrame.new(-1141,4,3831)
        System.CFrameMon = CFrame.new(-1103,13,3896)

    else
        System.Mon = "Brute"
        System.LevelQuest = 2
        System.NameQuest = "BuggyQuest1"
        System.CFrameQuest = CFrame.new(-1141,4,3831)
        System.CFrameMon = CFrame.new(-1140,14,4322)
    end
end

-- TP
local function TP(cf)
    local hrp = GetChar().HumanoidRootPart
    if (hrp.Position - cf.Position).Magnitude > 30 then
        hrp.CFrame = cf
    end
end

-- Target
local function FindTarget()
    local hrp = GetChar().HumanoidRootPart
    local closest, dist = nil, math.huge

    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == System.Mon and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 then
                local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = v
                end
            end
        end
    end

    System.Target = closest
end

-- Weapon
local function AutoWeapon()
    local char = GetChar()
    local tool = char:FindFirstChildOfClass("Tool")

    if not tool or tool.ToolTip ~= "Melee" then
        if System.CachedMelee and System.CachedMelee.Parent then
            char.Humanoid:EquipTool(System.CachedMelee)
        else
            for _,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
                if v.ToolTip == "Melee" then
                    System.CachedMelee = v
                    char.Humanoid:EquipTool(v)
                    break
                end
            end
        end
    end

    tool = char:FindFirstChildOfClass("Tool")
    if tool then tool:Activate() end
end

-- Auto Code
local function AutoCode()
    if tick() - System.LastCode < 20 then return end
    System.LastCode = tick()

    if game.Players.LocalPlayer.Data.Level.Value < 50 then
        local codes = {"SUB2GAMERROBOT_EXP1","Bluxxy"}

        for _,c in pairs(codes) do
            if not System.UsedCodes[c] then
                pcall(function()
                    game:GetService("ReplicatedStorage").Remotes.Redeem:InvokeServer(c)
                end)
                System.UsedCodes[c] = true
                task.wait(1)
            end
        end
    end
end

-- Main Loop
local function Start()
    task.spawn(function()
        while System.AutoFarm do
            task.wait(0.3)

            pcall(function()
                if game.Players.LocalPlayer.Data.Level.Value >= 50 then
                    System.AutoFarm = false
                    return
                end

                CheckQuest()

                if tick() - System.LastQuest > 2 then
                    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StartQuest", System.NameQuest, System.LevelQuest)
                    System.LastQuest = tick()
                end

                FindTarget()

                if System.Target then
                    local pos = System.Target.HumanoidRootPart.Position
                    TP(CFrame.new(pos.X, pos.Y + 20, pos.Z))
                else
                    TP(System.CFrameMon)
                end

                AutoWeapon()
                AutoCode()
            end)
        end
    end)
end

-- Toggle
MainTab:CreateToggle({
    Name = "Auto Farm Lv 50 (Melee)",
    CurrentValue = false,
    Callback = function(v)
        System.AutoFarm = v
        if v then Start() end
    end
})

Rayfield:LoadConfiguration()
