-- ============================================
-- DK HUB V19 - AUTOFISH FIXED
-- ============================================
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("=== DK Hub v19 - FIXED ===")

-- ============================================
-- CONFIG
-- ============================================
local Config = {
    AutoCast = false,
    HookMeter_Enabled = true,
    HookMeter_ClickDelay = 0.15,
    MG2_Enabled = true,
    MG2_OverlapThreshold = 0.65,
    RecastDelay = 0.8, -- Delay após captura
}

-- ============================================
-- STATS
-- ============================================
local Stats = {
    Catches = 0,
    Streak = 0
}

-- ============================================
-- STATE
-- ============================================
local State = {
    Fishing = false,
    InMinigame = false,
    LastCast = 0,
    HookMeterActive = false,
    LastCircleClicked = nil
}

-- MG2 State - CONTROLE PRECISO DE CLICK
local MG2 = {
    RedMarker = nil,
    SafeZone = nil,
    LastClickTime = 0,
    WasInZone = false, -- Estava na zona no último frame?
    ClickedInThisEntry = false -- Já clicou nesta entrada?
}

-- ============================================
-- LOADER UI
-- ============================================
local function CreateLoader()
    local LoaderGui = Instance.new("ScreenGui")
    LoaderGui.Name = "DKHubLoader"
    LoaderGui.ResetOnSpawn = false
    LoaderGui.DisplayOrder = 999
    LoaderGui.IgnoreGuiInset = true
    LoaderGui.Parent = playerGui
    
    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.Position = UDim2.new(0, 0, 0, 0)
    Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Background.BorderSizePixel = 0
    Background.ZIndex = 1
    Background.Parent = LoaderGui
    
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(0, 300, 0, 250)
    Container.Position = UDim2.new(0.5, -150, 0.5, -125)
    Container.BackgroundTransparency = 1
    Container.ZIndex = 2
    Container.Parent = LoaderGui
    
    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 120, 0, 120)
    Icon.Position = UDim2.new(0.5, -60, 0, 20)
    Icon.BackgroundTransparency = 1
    Icon.Image = "rbxassetid://97019295918694"
    Icon.ImageTransparency = 1
    Icon.ZIndex = 3
    Icon.Parent = Container
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Position = UDim2.new(0, 0, 0, 150)
    Title.BackgroundTransparency = 1
    Title.Text = "DK HUB"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 24
    Title.Font = Enum.Font.Code
    Title.TextTransparency = 1
    Title.ZIndex = 3
    Title.Parent = Container
    
    local LoadingText = Instance.new("TextLabel")
    LoadingText.Size = UDim2.new(1, 0, 0, 20)
    LoadingText.Position = UDim2.new(0, 0, 0, 190)
    LoadingText.BackgroundTransparency = 1
    LoadingText.Text = "> loading"
    LoadingText.TextColor3 = Color3.fromRGB(150, 150, 150)
    LoadingText.TextSize = 12
    LoadingText.Font = Enum.Font.Code
    LoadingText.TextTransparency = 1
    LoadingText.ZIndex = 3
    LoadingText.Parent = Container
    
    local BarContainer = Instance.new("Frame")
    BarContainer.Size = UDim2.new(0, 200, 0, 2)
    BarContainer.Position = UDim2.new(0.5, -100, 0, 220)
    BarContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    BarContainer.BorderSizePixel = 0
    BarContainer.BackgroundTransparency = 1
    BarContainer.ZIndex = 3
    BarContainer.Parent = Container
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    ProgressBar.BorderSizePixel = 0
    ProgressBar.ZIndex = 4
    ProgressBar.Parent = BarContainer
    
    local fadeIn = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    TweenService:Create(Icon, fadeIn, {ImageTransparency = 0}):Play()
    task.wait(0.2)
    
    TweenService:Create(Title, fadeIn, {TextTransparency = 0}):Play()
    task.wait(0.2)
    
    TweenService:Create(LoadingText, fadeIn, {TextTransparency = 0}):Play()
    TweenService:Create(BarContainer, fadeIn, {BackgroundTransparency = 0}):Play()
    
    local loadingSteps = {
        {text = "> initializing core", progress = 0.2},
        {text = "> loading modules", progress = 0.4},
        {text = "> connecting services", progress = 0.6},
        {text = "> setting up hooks", progress = 0.8},
        {text = "> ready", progress = 1.0}
    }
    
    for _, step in ipairs(loadingSteps) do
        LoadingText.Text = step.text
        TweenService:Create(ProgressBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
            {Size = UDim2.new(step.progress, 0, 1, 0)}):Play()
        task.wait(0.4)
    end
    
    task.wait(0.5)
    
    local fadeOut = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(Background, fadeOut, {BackgroundTransparency = 1}):Play()
    TweenService:Create(Icon, fadeOut, {ImageTransparency = 1}):Play()
    TweenService:Create(Title, fadeOut, {TextTransparency = 1}):Play()
    TweenService:Create(LoadingText, fadeOut, {TextTransparency = 1}):Play()
    TweenService:Create(BarContainer, fadeOut, {BackgroundTransparency = 1}):Play()
    TweenService:Create(ProgressBar, fadeOut, {BackgroundTransparency = 1}):Play()
    
    task.wait(0.6)
    LoaderGui:Destroy()
end

CreateLoader()

-- ============================================
-- MAIN UI
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DKHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 140)
MainFrame.Position = UDim2.new(1, -210, 0.5, -70)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 1
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 4)
Corner.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 4)
HeaderCorner.Parent = Header

local HeaderBottom = Instance.new("Frame")
HeaderBottom.Size = UDim2.new(1, 0, 0, 4)
HeaderBottom.Position = UDim2.new(0, 0, 1, -4)
HeaderBottom.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
HeaderBottom.BorderSizePixel = 0
HeaderBottom.Parent = Header

local Icon = Instance.new("ImageLabel")
Icon.Size = UDim2.new(0, 30, 0, 30)
Icon.Position = UDim2.new(0, 10, 0, 10)
Icon.BackgroundTransparency = 1
Icon.Image = "rbxassetid://97019295918694"
Icon.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 18)
Title.Position = UDim2.new(0, 45, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "DK Hub"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.TextSize = 13
Title.Font = Enum.Font.Code
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -50, 0, 14)
Subtitle.Position = UDim2.new(0, 45, 0, 28)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "MushYO"
Subtitle.TextColor3 = Color3.fromRGB(120, 120, 120)
Subtitle.TextSize = 10
Subtitle.Font = Enum.Font.Code
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 18, 0, 18)
CloseBtn.Position = UDim2.new(1, -24, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.Code
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 3)
CloseCorner.Parent = CloseBtn

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 60)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
StatusLabel.BorderSizePixel = 0
StatusLabel.Text = "> idle"
StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 3)
StatusCorner.Parent = StatusLabel

local StatusPadding = Instance.new("UIPadding")
StatusPadding.PaddingLeft = UDim.new(0, 8)
StatusPadding.Parent = StatusLabel

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 35)
ToggleBtn.Position = UDim2.new(0, 10, 0, 100)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "[off] autofish"
ToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
ToggleBtn.TextSize = 11
ToggleBtn.Font = Enum.Font.Code
ToggleBtn.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 3)
ToggleCorner.Parent = ToggleBtn

local Running = false

-- ============================================
-- HELPERS
-- ============================================
function UpdateStatus(text, color)
    StatusLabel.Text = "> " .. text
    StatusLabel.TextColor3 = color or Color3.fromRGB(100, 200, 100)
end

function QuickClick()
    local screenSize = workspace.CurrentCamera.ViewportSize
    local centerX = screenSize.X / 2
    local centerY = screenSize.Y / 2
    
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
end

function ClickAt(x, y)
    VirtualInputManager:SendMouseMoveEvent(x, y, game)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

-- ============================================
-- AUTO CAST - CORRIGIDO
-- ============================================
function AutoCast()
    if not Config.AutoCast then return end
    if State.Fishing or State.HookMeterActive or State.InMinigame then return end
    
    -- Delay após captura
    if tick() - State.LastCast < Config.RecastDelay then return end
    
    UpdateStatus("casting...", Color3.fromRGB(100, 150, 255))
    
    local success = pcall(function()
        local RemoteEvent = ReplicatedStorage:FindFirstChild("Modules")
        if RemoteEvent then
            RemoteEvent = RemoteEvent:FindFirstChild("Events")
            if RemoteEvent then
                RemoteEvent = RemoteEvent:FindFirstChild("RemoteEvent")
                if RemoteEvent then
                    RemoteEvent:FireServer("Throw", 0.95)
                end
            end
        end
    end)
    
    if success then
        State.LastCast = tick()
        State.Fishing = true
        print("🎣 Vara lançada")
    end
end

-- ============================================
-- HOOK METER
-- ============================================
function HandleHookMeter()
    if not Config.HookMeter_Enabled then return end
    
    local hookMeter = playerGui:FindFirstChild("HookMeter")
    if not hookMeter then
        if State.HookMeterActive then
            State.HookMeterActive = false
            State.InMinigame = false
            State.LastCircleClicked = nil
        end
        return
    end
    
    for _, obj in pairs(hookMeter:GetDescendants()) do
        if not obj:IsA("ImageButton") or not obj.Visible then continue end
        
        local circle = obj:FindFirstChild("AnimatedWhiteCircle")
        if not circle or not circle.Visible then continue end
        if State.LastCircleClicked == obj then continue end
        
        State.HookMeterActive = true
        State.InMinigame = true
        State.LastCircleClicked = obj
        
        UpdateStatus("hooking...", Color3.fromRGB(255, 200, 100))
        
        task.wait(Config.HookMeter_ClickDelay)
        
        local pos = obj.AbsolutePosition
        local size = obj.AbsoluteSize
        ClickAt(pos.X + size.X/2, pos.Y + size.Y/2)
        
        task.wait(0.3)
        return
    end
end

-- ============================================
-- MG2 - CATCH INDICATOR
-- ============================================
function HandleCatchIndicator()
    if not Config.MG2_Enabled then return end
    
    local catchIndicator = playerGui:FindFirstChild("CatchIndicator")
    
    if not catchIndicator or not catchIndicator.Enabled then
        if State.InMinigame then
            State.InMinigame = false
            State.Fishing = false
            MG2.RedMarker = nil
            MG2.SafeZone = nil
            MG2.WasInZone = false
            MG2.ClickedInThisEntry = false
        end
        return
    end
    
    State.InMinigame = true
    
    if MG2.SafeZone and MG2.RedMarker then
        return
    end
    
    for _, obj in pairs(catchIndicator:GetDescendants()) do
        if not obj:IsA("Frame") or not obj.Visible then continue end
        
        local color = obj.BackgroundColor3
        local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
        
        -- Red Marker (barra que se move)
        if (r >= 235 and r <= 250) and (g >= 75 and g <= 95) and (b >= 75 and b <= 95) then
            if not MG2.RedMarker then
                MG2.RedMarker = obj
                print("✅ RedMarker encontrado")
            end
        -- SafeZone (área verde)
        elseif (r >= 60 and r <= 74) and (g >= 190 and g <= 210) and (b >= 110 and b <= 130) then
            if not MG2.SafeZone then
                MG2.SafeZone = obj
                print("✅ SafeZone encontrada")
            end
        end
    end
end

-- ============================================
-- MG2 LOOP - UM CLICK POR ENTRADA
-- ============================================
RunService.RenderStepped:Connect(function()
    if not Running or not Config.MG2_Enabled then return end
    if not MG2.RedMarker or not MG2.SafeZone then return end
    if not MG2.RedMarker.Visible or not MG2.SafeZone.Visible then return end
    
    local redPos = MG2.RedMarker.AbsolutePosition
    local redSize = MG2.RedMarker.AbsoluteSize
    local zonePos = MG2.SafeZone.AbsolutePosition
    local zoneSize = MG2.SafeZone.AbsoluteSize
    
    local redLeft = redPos.X
    local redRight = redPos.X + redSize.X
    local zoneLeft = zonePos.X
    local zoneRight = zonePos.X + zoneSize.X
    
    local overlapStart = math.max(redLeft, zoneLeft)
    local overlapEnd = math.min(redRight, zoneRight)
    local overlapWidth = math.max(0, overlapEnd - overlapStart)
    local overlapPercent = overlapWidth / redSize.X
    
    local isInZone = overlapPercent >= Config.MG2_OverlapThreshold
    
    -- DETECTA TRANSIÇÃO: SAIU -> ENTROU
    if isInZone and not MG2.WasInZone then
        -- Acabou de ENTRAR na zona
        MG2.ClickedInThisEntry = false
        print("🎯 Entrou na zona!")
    end
    
    -- CLICA APENAS UMA VEZ POR ENTRADA
    if isInZone and not MG2.ClickedInThisEntry then
        QuickClick()
        MG2.ClickedInThisEntry = true
        MG2.LastClickTime = tick()
        
        UpdateStatus(string.format("mg2: %.0f%% ✓", overlapPercent * 100), Color3.fromRGB(100, 255, 100))
        print(string.format("✅ CLICK! Overlap: %.0f%%", overlapPercent * 100))
        
    elseif isInZone and MG2.ClickedInThisEntry then
        -- Ainda na zona mas já clicou
        UpdateStatus("mg2: waiting exit...", Color3.fromRGB(100, 150, 255))
        
    elseif not isInZone then
        -- Fora da zona
        UpdateStatus("mg2: waiting...", Color3.fromRGB(120, 120, 120))
    end
    
    -- DETECTA TRANSIÇÃO: DENTRO -> FORA
    if not isInZone and MG2.WasInZone then
        print("🚪 Saiu da zona!")
    end
    
    -- Atualiza estado anterior
    MG2.WasInZone = isInZone
end)

-- ============================================
-- EVENTS
-- ============================================
pcall(function()
    local RemoteEvent = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Events"):WaitForChild("RemoteEvent")

    RemoteEvent.OnClientEvent:Connect(function(event, ...)
        if event == "FishCaught" or event == "Catch" then
            Stats.Streak = Stats.Streak + 1
            Stats.Catches = Stats.Catches + 1
            
            State.Fishing = false
            State.HookMeterActive = false
            State.InMinigame = false
            State.LastCircleClicked = nil
            State.LastCast = tick() -- IMPORTANTE: Marca o tempo da captura
            
            MG2.RedMarker = nil
            MG2.SafeZone = nil
            MG2.WasInZone = false
            MG2.ClickedInThisEntry = false
            
            UpdateStatus(string.format("caught! #%d", Stats.Catches), Color3.fromRGB(100, 255, 100))
            print(string.format("🐟 Peixe capturado! Total: %d", Stats.Catches))
            
        elseif event == "ResetRodState" then
            Stats.Streak = 0
            State.Fishing = false
            State.HookMeterActive = false
            State.InMinigame = false
            State.LastCircleClicked = nil
            
            MG2.RedMarker = nil
            MG2.SafeZone = nil
            MG2.WasInZone = false
            MG2.ClickedInThisEntry = false
            
            UpdateStatus("reset", Color3.fromRGB(255, 100, 100))
        end
    end)
end)

-- ============================================
-- UI CONTROLS
-- ============================================
ToggleBtn.MouseButton1Click:Connect(function()
    Running = not Running
    Config.AutoCast = Running
    
    if Running then
        ToggleBtn.Text = "[on] autofish"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
        ToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        -- RESET COMPLETO
        State.Fishing = false
        State.InMinigame = false
        State.HookMeterActive = false
        State.LastCircleClicked = nil
        State.LastCast = 0 -- IMPORTANTE: Reseta para permitir cast imediato
        
        MG2.RedMarker = nil
        MG2.SafeZone = nil
        MG2.WasInZone = false
        MG2.ClickedInThisEntry = false
        
        UpdateStatus("starting...", Color3.fromRGB(100, 200, 100))
        
        -- Lança imediatamente
        task.wait(0.3)
        AutoCast()
        
    else
        ToggleBtn.Text = "[off] autofish"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        ToggleBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        
        UpdateStatus("idle", Color3.fromRGB(120, 120, 120))
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Running = false
    ScreenGui:Destroy()
end)

CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    CloseBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
end)

ToggleBtn.MouseEnter:Connect(function()
    if not Running then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    end
end)

ToggleBtn.MouseLeave:Connect(function()
    if not Running then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end)

-- ============================================
-- LOOPS
-- ============================================
task.spawn(function()
    while task.wait(0.1) do
        if Running then
            pcall(AutoCast)
        end
    end
end)

task.spawn(function()
    while task.wait(0.015) do
        if Running then
            pcall(HandleHookMeter)
        end
    end
end)

task.spawn(function()
    while task.wait(0.01) do
        if Running then
            pcall(HandleCatchIndicator)
        end
    end
end)

print("✅ DK Hub v19 ready")
print("✓ Auto recast fixed")
print("✓ MG2: single click per entry")
