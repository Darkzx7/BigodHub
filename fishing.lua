local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Variáveis essenciais
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack")
local guiRoot = player:WaitForChild("PlayerGui")

-- Estados do script
local autoFishing = false
local autoIndicatorEnabled = false
local fishingTool = nil
local blocker = nil
local holdingClick = false
local fishCount, trashCount, diamondCount = 0, 0, 0

-- Configurações de cores
local COLORS = {
    bg = Color3.fromRGB(15, 15, 15),
    title = Color3.fromRGB(255, 40, 40),
    buttonPrimary = Color3.fromRGB(200, 50, 50),
    buttonSecondary = Color3.fromRGB(60, 60, 60),
    text = Color3.new(1, 1, 1)
}

-- Funções básicas de pesca (inalteradas)
local function equipRod()
    local tool = character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod")
    if tool then
        tool.Parent = character
        task.wait(0.3)
        return tool
    end
    return nil
end

local function launchLine()
    fishingTool = equipRod()
    if fishingTool and fishingTool:IsDescendantOf(character) then
        fishingTool:Activate()
    end
end

local function createBlocker()
    if blocker then blocker:Destroy() end
    
    blocker = Instance.new("TextButton")
    blocker.Name = "FishingBlocker"
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.Position = UDim2.new(0, 0, 0, 0)
    blocker.Text = ""
    blocker.BackgroundTransparency = 1
    blocker.AutoButtonColor = false
    blocker.ZIndex = 9999
    blocker.Parent = guiRoot
    blocker.Visible = false
end

-- Controle do indicador (inalterado)
local function getIndicatorState()
    local fishing = workspace:FindFirstChild("fishing")
    if not fishing then return "missing" end
    
    local bar = fishing:FindFirstChild("bar")
    local safeArea = bar and bar:FindFirstChild("safeArea")
    local indicator = bar and bar:FindFirstChild("indicator")
    if not safeArea or not indicator then return "missing" end

    local safeY = safeArea.Position.Y.Scale
    local safeH = safeArea.Size.Y.Scale
    local indicatorY = indicator.Position.Y.Scale
    
    if indicatorY < safeY or indicatorY > (safeY + safeH) then
        return "out"
    elseif indicatorY < (safeY + safeH * 0.2) or indicatorY > (safeY + safeH * 0.8) then
        return "risk"
    else
        return "safe"
    end
end

-- UI simplificada e robusta
local function createGUI()
    -- Limpar GUI existente
    local oldGUI = guiRoot:FindFirstChild("FishingHUD")
    if oldGUI then oldGUI:Destroy() end

    -- Criar elementos básicos
    local gui = Instance.new("ScreenGui")
    gui.Name = "FishingHUD"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.ResetOnSpawn = false
    gui.Parent = guiRoot

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 250, 0, 200)
    mainFrame.Position = UDim2.new(1, -260, 0.5, -100)
    mainFrame.BackgroundColor3 = COLORS.bg
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui

    Instance.new("UICorner", mainFrame)

    -- Barra de título
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = COLORS.title
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    Instance.new("UICorner", titleBar)

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -40, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.Text = "PESCA AUTOMÁTICA"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextColor3 = COLORS.text
    titleText.TextSize = 14
    titleText.BackgroundTransparency = 1
    titleText.Parent = titleBar

    -- Botão de pesca
    local fishingBtn = Instance.new("TextButton")
    fishingBtn.Size = UDim2.new(0.9, 0, 0, 40)
    fishingBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
    fishingBtn.Text = autoFishing and "DESATIVAR PESCA" or "ATIVAR PESCA"
    fishingBtn.BackgroundColor3 = autoFishing and COLORS.buttonPrimary or COLORS.buttonSecondary
    fishingBtn.TextColor3 = COLORS.text
    fishingBtn.Font = Enum.Font.GothamMedium
    fishingBtn.TextSize = 14
    fishingBtn.Parent = mainFrame
    Instance.new("UICorner", fishingBtn)

    -- Botão de indicador
    local indicatorBtn = Instance.new("TextButton")
    indicatorBtn.Size = UDim2.new(0.9, 0, 0, 40)
    indicatorBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
    indicatorBtn.Text = autoIndicatorEnabled and "DESATIVAR INDICADOR" or "ATIVAR INDICADOR"
    indicatorBtn.BackgroundColor3 = autoIndicatorEnabled and COLORS.buttonPrimary or COLORS.buttonSecondary
    indicatorBtn.TextColor3 = COLORS.text
    indicatorBtn.Font = Enum.Font.GothamMedium
    indicatorBtn.TextSize = 14
    indicatorBtn.Parent = mainFrame
    Instance.new("UICorner", indicatorBtn)

    -- Status
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(0.9, 0, 0, 20)
    statusText.Position = UDim2.new(0.05, 0, 0.8, 0)
    statusText.Text = "Status: Pronto"
    statusText.Font = Enum.Font.Gotham
    statusText.TextColor3 = COLORS.text
    statusText.TextSize = 12
    statusText.BackgroundTransparency = 1
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = mainFrame

    -- Conexões de eventos
    fishingBtn.MouseButton1Click:Connect(function()
        autoFishing = not autoFishing
        fishingBtn.Text = autoFishing and "DESATIVAR PESCA" or "ATIVAR PESCA"
        fishingBtn.BackgroundColor3 = autoFishing and COLORS.buttonPrimary or COLORS.buttonSecondary
        
        if autoFishing then
            createBlocker()
            blocker.Visible = true
            spawn(function()
                while autoFishing do
                    launchLine()
                    task.wait(62)
                end
            end)
        else
            if blocker then blocker.Visible = false end
        end
    end)

    indicatorBtn.MouseButton1Click:Connect(function()
        autoIndicatorEnabled = not autoIndicatorEnabled
        indicatorBtn.Text = autoIndicatorEnabled and "DESATIVAR INDICADOR" or "ATIVAR INDICADOR"
        indicatorBtn.BackgroundColor3 = autoIndicatorEnabled and COLORS.buttonPrimary or COLORS.buttonSecondary
    end)

    return gui
end

-- Loop principal do indicador
RunService.Heartbeat:Connect(function()
    if not autoIndicatorEnabled then return end
    
    local state = getIndicatorState()
    if state == "risk" or state == "out" then
        if not holdingClick then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
            holdingClick = true
        end
    else
        if holdingClick then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
            holdingClick = false
        end
    end
end)

-- Inicialização segura
local function initialize()
    -- Esperar tudo carregar
    task.wait(3)
    
    -- Criar a UI
    local success, err = pcall(createGUI)
    if not success then
        warn("Erro ao criar UI: " .. err)
        task.wait(2)
        initialize() -- Tentar novamente
    end
end

-- Iniciar
initialize()
