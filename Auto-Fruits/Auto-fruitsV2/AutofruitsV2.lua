-- Auto Fruits robusto para Blox Fruits
-- 100% automático, sem GUI, com ESP de imagem de fruta e server hop quando não encontrar frutas.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local AutoFruit = {}

AutoFruit.Config = {
    ScanDelay = 1.2,
    CollectDistance = 5,
    MoveDuration = 1.2,
    MaxMoveRetries = 3,
    HopCooldown = 10,
    MaxServerHopAttempts = 6,
    Islands = {
        -- Caso queira forçar a ida para uma ilha pirata conhecida, adicione aqui.
        PirateIsland = Vector3.new(-3650, 5, 1150),
    },
    FruitRarityOrder = {"Mythic", "Legendary", "Rare", "Uncommon", "Common"},
    FruitNames = {
        -- As frutas devem ser listadas com raridade exata. Adicione ou ajuste conforme o jogo.
        Bomb = "Common",
        Spike = "Common",
        Smoke = "Common",
        Rocket = "Common",
        Spin = "Common",
        Chop = "Uncommon",
        Flame = "Uncommon",
        Spring = "Uncommon",
        Buddha = "Uncommon",
        Diamond = "Rare",
        Dark = "Rare",
        Quake = "Rare",
        Kilo = "Rare",
        Barrier = "Rare",
        Venom = "Legendary",
        Phoenix = "Legendary",
        Gravity = "Legendary",
        Light = "Legendary",
        Control = "Legendary",
        Soul = "Mythic",
        Dough = "Mythic",
        Love = "Mythic",
        Dragon = "Mythic",
    },
    FruitIcons = {
        -- Substitua estes IDs pelos IDs corretos de imagem das frutas do repositório.
        Default = "rbxassetid://0",
        Bomb = "rbxassetid://0",
        Spike = "rbxassetid://0",
        Smoke = "rbxassetid://0",
        Rocket = "rbxassetid://0",
        Spin = "rbxassetid://0",
        Chop = "rbxassetid://0",
        Flame = "rbxassetid://0",
        Spring = "rbxassetid://0",
        Buddha = "rbxassetid://0",
        Diamond = "rbxassetid://0",
        Dark = "rbxassetid://0",
        Quake = "rbxassetid://0",
        Kilo = "rbxassetid://0",
        Barrier = "rbxassetid://0",
        Venom = "rbxassetid://0",
        Phoenix = "rbxassetid://0",
        Gravity = "rbxassetid://0",
        Light = "rbxassetid://0",
        Control = "rbxassetid://0",
        Soul = "rbxassetid://0",
        Dough = "rbxassetid://0",
        Love = "rbxassetid://0",
        Dragon = "rbxassetid://0",
    },
    RarityColors = {
        Common = Color3.fromRGB(255, 255, 255),
        Uncommon = Color3.fromRGB(0, 255, 128),
        Rare = Color3.fromRGB(0, 170, 255),
        Legendary = Color3.fromRGB(255, 120, 0),
        Mythic = Color3.fromRGB(255, 32, 178),
        Unknown = Color3.fromRGB(190, 190, 190),
    },
}

AutoFruit.State = {
    Running = false,
    ServerHistory = {},
    CurrentTarget = nil,
    LastHop = 0,
    EspMap = {},
}

function AutoFruit:SafeWait(seconds)
    local target = tick() + (seconds or 0.2)
    while tick() < target and self.State.Running do
        RunService.Heartbeat:Wait()
    end
end

function AutoFruit:GetFruitRarity(fruitName)
    return self.Config.FruitNames[fruitName] or "Unknown"
end

function AutoFruit:GetFruitIcon(fruitName)
    return self.Config.FruitIcons[fruitName] or self.Config.FruitIcons.Default
end

function AutoFruit:IsFruitPart(instance)
    if not instance or not instance.Parent then
        return false
    end
    local name = instance.Name:lower()
    if name == "fruit" or name:find("fruit") then
        return true
    end
    if instance:IsA("BasePart") and instance.Parent and instance.Parent.Name:lower():find("fruit") then
        return true
    end
    return false
end

function AutoFruit:CollectFruitInstances()
    local fruits = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if self:IsFruitPart(obj) then
            if obj:IsA("BasePart") then
                local candidate = obj
                if candidate.Transparency < 1 and candidate.CanCollide then
                    table.insert(fruits, candidate)
                else
                    table.insert(fruits, candidate)
                end
            end
        end
    end
    return fruits
end

function AutoFruit:BuildFruitData(part)
    if not part or not part:IsA("BasePart") then
        return nil
    end
    local fruitName = part.Name
    if fruitName:lower():find("fruit") and part.Parent then
        -- O objeto pode ser o modelo ou a própria parte. Ajuste para nome real.
        if part.Parent and part.Parent.Name ~= "" and part.Parent ~= workspace then
            fruitName = part.Parent.Name
        end
    end
    local rarity = self:GetFruitRarity(fruitName)
    local position = part.Position
    local distance = math.huge
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        distance = (LocalPlayer.Character.HumanoidRootPart.Position - position).Magnitude
    end
    return {
        Instance = part,
        Name = fruitName,
        Rarity = rarity,
        Distance = distance,
        Icon = self:GetFruitIcon(fruitName),
    }
end

function AutoFruit:SortFruits(a, b)
    local rarityA = a.Rarity
    local rarityB = b.Rarity
    local priorityA = table.find(self.Config.FruitRarityOrder, rarityA) or #self.Config.FruitRarityOrder + 1
    local priorityB = table.find(self.Config.FruitRarityOrder, rarityB) or #self.Config.FruitRarityOrder + 1
    if priorityA ~= priorityB then
        return priorityA < priorityB
    end
    return a.Distance < b.Distance
end

function AutoFruit:FindBestFruit()
    local rawFruits = self:CollectFruitInstances()
    local fruits = {}
    for _, part in ipairs(rawFruits) do
        local fruitData = self:BuildFruitData(part)
        if fruitData and fruitData.Instance and fruitData.Instance.Parent then
            table.insert(fruits, fruitData)
        end
    end
    table.sort(fruits, function(a, b)
        return self:SortFruits(a, b)
    end)
    return fruits
end

function AutoFruit:ClearEsp()
    for instance, gui in pairs(self.State.EspMap) do
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    self.State.EspMap = {}
end

function AutoFruit:CreateEsp(fruit)
    if not fruit or not fruit.Instance or not fruit.Instance.Parent then
        return
    end
    if self.State.EspMap[fruit.Instance] then
        return
    end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AutoFruitESP"
    billboard.Adornee = fruit.Instance
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 120, 0, 120)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.Parent = fruit.Instance

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local icon = Instance.new("ImageLabel")
    icon.Name = "FruitIcon"
    icon.Size = UDim2.new(0, 80, 0, 80)
    icon.Position = UDim2.new(0.5, -40, 0, 5)
    icon.BackgroundTransparency = 1
    icon.Image = fruit.Icon or self.Config.FruitIcons.Default
    icon.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "FruitName"
    title.Size = UDim2.new(1, -10, 0, 28)
    title.Position = UDim2.new(0, 5, 0, 80)
    title.BackgroundTransparency = 1
    title.Text = fruit.Name
    title.TextColor3 = self.Config.RarityColors[fruit.Rarity] or self.Config.RarityColors.Unknown
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame

    self.State.EspMap[fruit.Instance] = billboard
end

function AutoFruit:UpdateEsp(fruits)
    local current = {}
    for _, fruit in ipairs(fruits) do
        if fruit.Instance and fruit.Instance.Parent then
            self:CreateEsp(fruit)
            current[fruit.Instance] = true
        end
    end
    for instance, gui in pairs(self.State.EspMap) do
        if not current[instance] or not instance.Parent then
            if gui and gui.Parent then gui:Destroy() end
            self.State.EspMap[instance] = nil
        end
    end
end

function AutoFruit:GetBestTarget()
    local fruits = self:FindBestFruit()
    self:UpdateEsp(fruits)
    return fruits[1]
end

function AutoFruit:MoveTo(position)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    local root = LocalPlayer.Character.HumanoidRootPart
    local distance = (root.Position - position).Magnitude
    if distance <= self.Config.CollectDistance then
        return true
    end
    local tweenInfo = TweenInfo.new(math.clamp(distance / 16, 0.8, self.Config.MoveDuration), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local targetCFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    local success, err = pcall(function()
        local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
    end)
    if not success then
        root.CFrame = targetCFrame
    end
    return (root.Position - position).Magnitude <= self.Config.CollectDistance + 2
end

function AutoFruit:TeleportToPirateIsland()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    local goal = self.Config.Islands.PirateIsland
    if not goal then
        return
    end
    local root = LocalPlayer.Character.HumanoidRootPart
    local success, err = pcall(function()
        root.CFrame = CFrame.new(goal)
    end)
    if not success then
        warn("AutoFruit: não conseguiu teletransportar para ilha pirata:", err)
    end
    self:SafeWait(0.8)
end

function AutoFruit:TryCollect(fruit)
    if not fruit or not fruit.Instance or not fruit.Instance.Parent then
        return false
    end
    local targetPart = fruit.Instance
    local attempts = 0
    while attempts < self.Config.MaxMoveRetries and self.State.Running do
        attempts = attempts + 1
        local reached = self:MoveTo(targetPart.Position)
        if not reached then
            continue
        end
        self.State.CurrentTarget = fruit
        self:SafeWait(0.25)
        if targetPart and targetPart.Parent then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - targetPart.Position).Magnitude
                if dist <= self.Config.CollectDistance + 3 then
                    pcall(function()
                        firetouchinterest(targetPart, root, 0)
                        firetouchinterest(targetPart, root, 1)
                    end)
                end
            end
        end
        self:SafeWait(1.1)
        if not targetPart or not targetPart.Parent then
            return true
        end
    end
    return false
end

function AutoFruit:GetServerList()
    local placeId = game.PlaceId
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
    local response = nil
    local success, message = pcall(function()
        response = HttpService:GetAsync(url)
    end)
    if not success or not response then
        warn("AutoFruit: Falha ao buscar lista de servidores:", message)
        return {}
    end
    local data = nil
    success, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    if not success or type(data) ~= "table" then
        warn("AutoFruit: resposta inválida de servidor")
        return {}
    end
    local servers = {}
    for _, entry in ipairs(data.data or {}) do
        if entry and entry.id and entry.playing and (not self.State.ServerHistory[entry.id]) then
            table.insert(servers, entry)
        end
    end
    return servers
end

function AutoFruit:ServerHop()
    if tick() - self.State.LastHop < self.Config.HopCooldown then
        return
    end
    self.State.LastHop = tick()
    local servers = self:GetServerList()
    if #servers == 0 then
        return
    end
    local candidate = servers[math.random(1, #servers)]
    if not candidate or not candidate.id then
        return
    end
    self.State.ServerHistory[candidate.id] = true
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, candidate.id, LocalPlayer)
    end)
    if not success then
        warn("AutoFruit: erro ao trocar servidor:", err)
    end
end

function AutoFruit:HasActiveFruit()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if self:IsFruitPart(obj) then
            return true
        end
    end
    return false
end

function AutoFruit:RunLoop()
    while self.State.Running do
        if not LocalPlayer or not LocalPlayer.Character then
            self:SafeWait(1)
            continue
        end
        if not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            self:SafeWait(1)
            continue
        end
        local target = self:GetBestTarget()
        if target then
            self:TryCollect(target)
            self.State.CurrentTarget = nil
            self:SafeWait(0.4)
            continue
        end
        self:SafeWait(1)
        if not self:HasActiveFruit() then
            self:ServerHop()
            self:SafeWait(5)
        end
    end
    self:ClearEsp()
end

function AutoFruit:Start()
    if self.State.Running then
        return
    end
    self.State.Running = true
    self.State.ServerHistory = self.State.ServerHistory or {}
    self:SafeWait(0.1)
    task.spawn(function()
        self:RunLoop()
    end)
end

function AutoFruit:Stop()
    self.State.Running = false
    self:ClearEsp()
end

-- inicializa automaticamente
AutoFruit:Start()

return AutoFruit
