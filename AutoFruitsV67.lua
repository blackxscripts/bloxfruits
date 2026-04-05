-- V67 | Arquitetura Orientada a Eventos | Engenharia Refinada | Production-Grade

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local PlayerGui = player:WaitForChild("PlayerGui", 5)

local player = Players.LocalPlayer
local CommF = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
local PlaceId = game.PlaceId

-- =========================
-- CONFIG E CONSTANTES
-- =========================
local CONFIG = {
    SCAN_COOLDOWN = 1,
    TELEPORT_DEBOUNCE = 0.5,
    HOP_COOLDOWN = 3,
    HOP_TIMEOUT = 20,
    BACKPACK_CHECK_INTERVAL = 0.2,
    -- Reconexão com Backoff Exponencial
    RECONNECT_MAX_ATTEMPTS = 5,
    RECONNECT_BASE_DELAY = 1,
    RECONNECT_MAX_DELAY = 30,
    RECONNECT_BACKOFF_MULTIPLIER = 2,
    -- Gacha retries
    MAX_GACHA_RETRIES = 3,
    GACHA_RETRY_DELAY = 1,
    -- UI Tween
    TWEEN_DURATION = 0.25,
    -- Notifications
    NOTIFICATION_DURATION = 5,
}

-- =========================
-- CONNECTION RECOVERY (Retry com Exponential Backoff)
-- =========================
local ConnectionRecovery = {}
ConnectionRecovery.state = {}

function ConnectionRecovery:CalculateBackoff(attempt)
    local delay = CONFIG.RECONNECT_BASE_DELAY * (CONFIG.RECONNECT_BACKOFF_MULTIPLIER ^ (attempt - 1))
    return math.min(delay, CONFIG.RECONNECT_MAX_DELAY)
end

function ConnectionRecovery:AttemptWithRetry(operation, opName, maxAttempts)
    maxAttempts = maxAttempts or CONFIG.RECONNECT_MAX_ATTEMPTS

    for attempt = 1, maxAttempts do
        local success, result = pcall(operation)

        if success then
            if attempt > 1 then
                print(("[RECONNECT] %s recuperado após %d tentativa(s)"):format(opName, attempt - 1))
            end
            return true, result
        end

        if attempt < maxAttempts then
            local backoffDelay = self:CalculateBackoff(attempt)
            print(("[RECONNECT] %s falhou (tentativa %d/%d). Aguardando %.2fs antes de retry..."):format(
                opName, attempt, maxAttempts, backoffDelay
            ))
            task.wait(backoffDelay)
        else
            print(("[RECONNECT] %s falhou após %d tentativas. Operação abortada."):format(
                opName, maxAttempts
            ))
        end
    end

    return false, nil
end

function ConnectionRecovery:MonitorConnection()
    if not self.state.monitoring then
        self.state.monitoring = true

        task.spawn(function()
            while self.state.monitoring do
                task.wait(5)

                local commAvailable = pcall(function()
                    return CommF ~= nil
                end)

                if not commAvailable then
                    print("[RECONNECT] CommF perdido. Tentando recuperar...")
                    self:AttemptWithRetry(function()
                        CommF = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
                    end, "CommF Reconnect")
                end
            end
        end)
    end
end

-- =========================
-- LISTA DE FRUTAS (WHITELIST)
-- =========================
local FruitList = {
    "Rocket-Rocket", "Spin-Spin", "Blade-Blade", "Spring-Spring", "Bomb-Bomb", "Smoke-Smoke",
    "Spike-Spike", "Flame-Flame", "Ice-Ice", "Sand-Sand", "Dark-Dark", "Eagle-Eagle",
    "Diamond-Diamond", "Light-Light", "Rubber-Rubber", "Ghost-Ghost", "Magma-Magma",
    "Quake-Quake", "Buddha-Buddha", "Love-Love", "Creation-Creation", "Spider-Spider",
    "Sound-Sound", "Phoenix-Phoenix", "Portal-Portal", "Lightning-Lightning", "Pain-Pain",
    "Blizzard-Blizzard", "Gravity-Gravity", "Mammoth-Mammoth", "T-Rex-T-Rex", "Dough-Dough",
    "Shadow-Shadow", "Venom-Venom", "Gas-Gas", "Spirit-Spirit", "Tiger-Tiger", "Yeti-Yeti",
    "Kitsune-Kitsune", "Control-Control", "Dragon-Dragon"
}

local FruitMap = {}
for _, f in ipairs(FruitList) do
    FruitMap[f] = true
end

-- =========================
-- LOGGER SISTEMA
-- =========================
local Logger = {}
function Logger.Log(level, msg)
    local timestamp = os.date("%H:%M:%S")
    print(("[%s] [%s] %s"):format(timestamp, level, msg))
end

function Logger.Info(msg) Logger.Log("INFO", msg) end

function Logger.Warn(msg) Logger.Log("WARN", msg) end

function Logger.Error(msg) Logger.Log("ERROR", msg) end

-- =========================
-- SISTEMA DE NOTIFICAÇÕES
-- =========================
local Notifications = {}
function Notifications.Send(title, text, duration)
    duration = duration or CONFIG.NOTIFICATION_DURATION
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration,
    })
end

function Notifications.BlackX(text, duration)
    Notifications.Send("BLACK X DIZ:", text, duration)
end

-- =========================
-- FRUIT SCANNER (Detector com Cache)
-- =========================
local FruitScanner = {}
FruitScanner.cache = {}
FruitScanner.lastScanTime = 0

function FruitScanner.IsFruit(obj)
    return obj and obj:IsA("Tool") and obj:FindFirstChild("Handle") and FruitMap[obj.Name] == true
end

function FruitScanner:CacheAdd(fruit)
    self.cache[fruit] = { obj = fruit, time = tick() }
end

function FruitScanner:CacheRemove(fruit)
    self.cache[fruit] = nil
end

function FruitScanner:FindNearestFruit()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest, minDist = nil, math.huge

    for fruit in pairs(self.cache) do
        if fruit and fruit.Parent then
            local dist = (fruit.Handle.Position - root.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = fruit
            end
        else
            self:CacheRemove(fruit)
        end
    end

    if nearest then
        Notifications.BlackX(nearest.Name .. " ENCONTRADA A " .. math.floor(minDist) .. "M")
    end

    return nearest
end

-- Escuta adição de frutas ao workspace (evento em vez de varredura)
workspace.DescendantAdded:Connect(function(obj)
    if FruitScanner.IsFruit(obj) then
        FruitScanner:CacheAdd(obj)
        Logger.Info("Fruta detectada: " .. obj.Name)
    end
end)

workspace.DescendantRemoving:Connect(function(obj)
    if FruitScanner.IsFruit(obj) then
        FruitScanner:CacheRemove(obj)
    end
end)

-- =========================
-- EXECUTOR (Teleporte + Armazenamento)
-- =========================
local Executor = {}
Executor.lastTeleportTime = 0
Executor.isCollecting = false

function Executor.TeleportTo(fruit)
    if not fruit or not fruit.Parent then return false end

    local now = tick()
    if now - Executor.lastTeleportTime < CONFIG.TELEPORT_DEBOUNCE then
        return false
    end

    if Executor.isCollecting then
        return false
    end

    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    Executor.isCollecting = true
    Executor.lastTeleportTime = now

    local success = pcall(function()
        root.CFrame = CFrame.new(fruit.Handle.Position + Vector3.new(0, 3, 0))
    end)

    if success then
        Logger.Info("Teletransportado para: " .. fruit.Name)
    else
        Logger.Error("Falha ao teletransportar para: " .. fruit.Name)
    end

    return success
end

function Executor:StoreCollectedFruits()
    local stored = 0
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if FruitScanner.IsFruit(tool) then
            local success, _ = ConnectionRecovery:AttemptWithRetry(function()
                CommF:InvokeServer("StoreFruit", tool.Name)
            end, "StoreFruit[" .. tool.Name .. "]", 2)

            if success then
                stored = stored + 1
                Logger.Info("Fruta armazenada: " .. tool.Name)
                Notifications.BlackX("VOCÊ ENCONTROU " .. tool.Name .. "!!")
            else
                Logger.Error("Falha ao armazenar: " .. tool.Name)
            end
        end
    end

    Executor.isCollecting = false
    return stored
end

function Executor.CountFruitsInBackpack()
    local count = 0
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if FruitScanner.IsFruit(tool) then
            count = count + 1
        end
    end
    return count
end

-- =========================
-- NETWORK HANDLER (Server Hopping Robusto)
-- =========================
local NetworkHandler = {}
NetworkHandler.visitedServers = {}
NetworkHandler.lastHopTime = 0
NetworkHandler.hopInProgress = false
NetworkHandler.hopTimeout = nil

function NetworkHandler:GetAvailableServers(cursor)
    cursor = cursor or ""
    local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
    end

    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        Logger.Error("Falha ao conectar com API de servidores")
        return nil
    end

    local data = HttpService:JSONDecode(response)
    return data
end

function NetworkHandler:CollectAllServers()
    local allServers = {}
    local cursor = ""
    local pageCount = 0

    while pageCount < 3 do -- Limita a 3 páginas
        local data = self:GetAvailableServers(cursor)
        if not data or not data.data then break end

        for _, server in pairs(data.data) do
            if server.playing < server.maxPlayers and not self.visitedServers[server.id] then
                table.insert(allServers, server.id)
            end
        end

        if not data.nextPageCursor then break end
        cursor = data.nextPageCursor
        pageCount = pageCount + 1
    end

    return allServers
end

function NetworkHandler:Hop()
    if self.hopInProgress then
        Logger.Warn("Hop já em progresso")
        return false
    end

    local now = tick()
    if now - self.lastHopTime < CONFIG.HOP_COOLDOWN then
        Logger.Warn("Cooldown de hop ativo")
        return false
    end

    Notifications.BlackX("SERVER HOP EM 3 SEGUNDOS")
    task.wait(3)

    local servers = self:CollectAllServers()
    if #servers == 0 then
        Logger.Warn("Nenhum servidor disponível")
        return false
    end

    self.hopInProgress = true
    self.lastHopTime = now

    local chosenServer = servers[math.random(#servers)]
    self.visitedServers[chosenServer] = true

    Logger.Info("Pulando para servidor: " .. chosenServer:sub(1, 8) .. "...")

    local success, _ = ConnectionRecovery:AttemptWithRetry(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, chosenServer, player)
    end, "TeleportToPlaceInstance", 2)

    if not success then
        Logger.Error("Falha ao pular para servidor")
        self.hopInProgress = false
    end

    return success
end

-- =========================
-- DETECTOR DE ADM
-- =========================
local AdminDetector = {}
AdminDetector.suspiciousNames = {
    "admin", "mod", "moderator", "staff", "developer", "roblox", "test", "system"
}

function AdminDetector.IsSuspicious(playerName)
    local lowerName = playerName:lower()
    for _, word in ipairs(AdminDetector.suspiciousNames) do
        if lowerName:find(word) then
            return true
        end
    end
    return false
end

function AdminDetector:CheckPlayers()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and self.IsSuspicious(p.Name) then
            Notifications.BlackX("ADM DETECTADO")
            NetworkHandler:Hop()
            return true
        end
    end
    return false
end

Players.PlayerAdded:Connect(function(p)
    if AdminDetector.IsSuspicious(p.Name) then
        Notifications.BlackX("ADM DETECTADO")
        NetworkHandler:Hop()
    end
end)

-- =========================
-- GUI BLACK X (ANIMADA)
-- =========================

local SYSTEM = {
    active = true -- Já inicia ativado
}

local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "BlackX_UI_V6"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 260, 0, 40)
main.Position = UDim2.new(0.5, -130, 0.1, 0)
main.BackgroundColor3 = Color3.fromRGB(10,10,10)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(120, 220, 255)
stroke.Thickness = 1.5

-- Título
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(0.6, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "AUTO FRUITS"
title.TextColor3 = Color3.fromRGB(200,200,200)
title.TextSize = 14
title.Font = Enum.Font.GothamSemibold

-- Divisor
local divider = Instance.new("Frame", main)
divider.Size = UDim2.new(0,1,1,0)
divider.Position = UDim2.new(0.6,0,0,0)
divider.BackgroundColor3 = Color3.fromRGB(60,60,60)
divider.BorderSizePixel = 0

-- Container do toggle
local toggleFrame = Instance.new("Frame", main)
toggleFrame.Size = UDim2.new(0.4, -10, 0, 22)
toggleFrame.Position = UDim2.new(0.6, 5, 0.5, -11)
toggleFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleFrame.BorderSizePixel = 0

local toggleCorner = Instance.new("UICorner", toggleFrame)
toggleCorner.CornerRadius = UDim.new(1,0)

-- Bolinha
local knob = Instance.new("Frame", toggleFrame)
knob.Size = UDim2.new(0,18,0,18)
knob.Position = UDim2.new(0,2,0.5,-9)
knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
knob.BorderSizePixel = 0

local knobCorner = Instance.new("UICorner", knob)
knobCorner.CornerRadius = UDim.new(1,0)

-- Texto ON/OFF
local stateText = Instance.new("TextLabel", main)
stateText.Size = UDim2.new(0.4, 0, 1, 0)
stateText.Position = UDim2.new(0.6, 0, 0, 0)
stateText.BackgroundTransparency = 1
stateText.Text = "ON"
stateText.TextColor3 = Color3.fromRGB(50,255,120)
stateText.TextSize = 14
stateText.Font = Enum.Font.GothamBold

-- Tween config
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function updateToggle(state)
    if state then
        -- ON
        TweenService:Create(knob, tweenInfo, {
            Position = UDim2.new(1, -20, 0.5, -9)
        }):Play()

        TweenService:Create(toggleFrame, tweenInfo, {
            BackgroundColor3 = Color3.fromRGB(20,60,40)
        }):Play()

        stateText.Text = "ON"
        TweenService:Create(stateText, tweenInfo, {
            TextColor3 = Color3.fromRGB(50,255,120)
        }):Play()

    else
        -- OFF
        TweenService:Create(knob, tweenInfo, {
            Position = UDim2.new(0, 2, 0.5, -9)
        }):Play()

        TweenService:Create(toggleFrame, tweenInfo, {
            BackgroundColor3 = Color3.fromRGB(40,20,20)
        }):Play()

        stateText.Text = "OFF"
        TweenService:Create(stateText, tweenInfo, {
            TextColor3 = Color3.fromRGB(255,80,80)
        }):Play()
    end
end

-- Clique
toggleFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        SYSTEM.active = not SYSTEM.active
        updateToggle(SYSTEM.active)
    end
end)

-- Inicial
updateToggle(true)

-- =========================
-- SISTEMA AUTO PIRATES
-- =========================
local AutoPirates = {}
function AutoPirates:JoinPirates()
    if not player.Team or player.Team.Name ~= "Pirates" then
        ConnectionRecovery:AttemptWithRetry(function()
            CommF:InvokeServer("SetTeam", "Pirates")
        end, "SetTeam[Pirates]", 3)
        Logger.Info("Joined Pirates team")
    end
end

task.spawn(function()
    while true do
        task.wait(5) -- Verifica a cada 5 segundos
        AutoPirates:JoinPirates()
    end
end)

-- =========================
-- SISTEMA AUTO REJOIN
-- =========================
local AutoRejoin = {}
AutoRejoin.rejoinAttempts = 0
AutoRejoin.maxRejoinAttempts = 5

function AutoRejoin:Rejoin()
    if self.rejoinAttempts >= self.maxRejoinAttempts then
        Logger.Error("Máximo de tentativas de rejoin atingido")
        return
    end

    self.rejoinAttempts = self.rejoinAttempts + 1
    Logger.Info("Tentando rejoin... Tentativa " .. self.rejoinAttempts)

    local success = pcall(function()
        TeleportService:Teleport(PlaceId, player)
    end)

    if not success then
        Logger.Error("Falha no rejoin")
        task.wait(5)
        self:Rejoin()
    else
        Notifications.BlackX("RECONECTANDO...")
    end
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    Logger.Error("Teleport falhou: " .. errorMessage)
    AutoRejoin:Rejoin()
end)

-- Detectar ErrorPrompt
local CoreGui = game:GetService("CoreGui")
CoreGui.ChildAdded:Connect(function(child)
    if child.Name == "ErrorPrompt" then
        Logger.Error("Erro detectado no jogo")
        AutoRejoin:Rejoin()
    end
end)

-- =========================
-- LOOP PRINCIPAL (EVENT-DRIVEN)
-- =========================
task.spawn(function()
    local consecutiveFailures = 0

    while task.wait(CONFIG.SCAN_COOLDOWN) do
        if not SYSTEM.active or not player.Character then
            continue
        end

        -- Verificar ADM
        AdminDetector:CheckPlayers()

        local fruit = FruitScanner:FindNearestFruit()

        if fruit then
            Logger.Info("Fruta encontrada: " .. fruit.Name)
            consecutiveFailures = 0

            if Executor.TeleportTo(fruit) then
                task.wait(CONFIG.TELEPORT_DEBOUNCE + 0.5)

                local fruitsBefore = Executor.CountFruitsInBackpack()
                local stored = Executor:StoreCollectedFruits()

                if stored == 0 and fruitsBefore > 0 then
                    Logger.Warn("Fruta inválida coletada. Tentando giro novamente...")
                    for giroAttempt = 1, CONFIG.MAX_GACHA_RETRIES do
                        task.wait(CONFIG.GACHA_RETRY_DELAY)
                        local storedRetry = Executor:StoreCollectedFruits()
                        if storedRetry > 0 then
                            Logger.Info("Sucesso no giro #" .. giroAttempt)
                            break
                        elseif giroAttempt == CONFIG.MAX_GACHA_RETRIES then
                            Logger.Error("Falha em armazenar após " ..
                                CONFIG.MAX_GACHA_RETRIES .. " giros. Fazendo hop...")
                            consecutiveFailures = consecutiveFailures + 1
                        end
                    end
                end
            end
        else
            Logger.Info("Nenhuma fruta encontrada. Verificando backpack...")
            Executor:StoreCollectedFruits()

            consecutiveFailures = consecutiveFailures + 1

            if consecutiveFailures >= 1 then
                Logger.Info("Nenhuma fruta após " .. consecutiveFailures .. " ciclo(s). Pulando servidor...")
                NetworkHandler:Hop()
                task.wait(CONFIG.HOP_TIMEOUT)
                consecutiveFailures = 0
            end
        end
    end
end)

Logger.Info("=== SISTEMA INICIADO ===")
Notifications.BlackX("SCRIPT INICIADO COM SUCESSO!")

-- Inicia monitoramento contínuo de reconexão
ConnectionRecovery:MonitorConnection()
Logger.Info("Connection Recovery Monitor ativado")
