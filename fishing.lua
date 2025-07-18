local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configurações de estilo
local COLORS = {
    bg = Color3.fromRGB(30, 30, 35),
    title = Color3.fromRGB(180, 180, 190),
    button = Color3.fromRGB(50, 50, 60),
    button_active = Color3.fromRGB(80, 80, 90),
    text = Color3.fromRGB(220, 220, 230),
    accent = Color3.fromRGB(100, 100, 110)
}

local FONTS = {
    title = Enum.Font.SourceSansBold,
    main = Enum.Font.SourceSans,
    buttons = Enum.Font.SourceSansSemibold
}

-- Variáveis de estado
local autoMode = false -- Combina pesca e indicador
local fishingTool = nil
local holdingClick = false
local minimized = false
local fishCount, trashCount, diamondCount = 0, 0, 0

-- Elementos da UI
local mainFrame, toggleBtn, statusLabel, lootContainer
local elementsToToggle = {}

-- Função para criar sombra
local function createShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.BackgroundTransparency = 1
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

-- Função para criar botão estilizado
local function createStyledButton(name, text, size, position, parent)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = COLORS.button
    button.TextColor3 = COLORS.text
    button.Font = FONTS.buttons
    button.TextSize = 14
    button.Text = text
    button.AutoButtonColor = false
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    -- Efeitos hover
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = COLORS.button_active,
            TextColor3 = Color3.new(1, 1, 1)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = COLORS.button,
            TextColor3 = COLORS.text
        }):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = COLORS.button_active
        }):Play()
    end)
    
    createShadow(button)
    return button
end

-- Função para criar a estrutura principal da UI
local function createMainUI()
    -- Limpar UI existente
    local oldUI = player.PlayerGui:FindFirstChild("BGHubFishing")
    if oldUI then oldUI:Destroy() end
    
    -- Criar container principal
    local gui = Instance.new("ScreenGui")
    gui.Name = "BGHubFishing"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.ResetOnSpawn = false
    gui.Parent = player.PlayerGui
    
    -- Frame principal
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 280, 0, 180)
    mainFrame.Position = UDim2.new(1, -300, 0.5, -90)
    mainFrame.BackgroundColor3 = COLORS.bg
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    createShadow(mainFrame)
    
    -- Barra de título
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = COLORS.accent
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.Position = UDim2.new(0.1, 0, 0, 0)
    titleText.Text = "BG HUB - PESCA"
    titleText.Font = FONTS.title
    titleText.TextColor3 = COLORS.title
    titleText.TextSize = 16
    titleText.BackgroundTransparency = 1
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Botão de minimizar
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
    minimizeBtn.Position = UDim2.new(1, -32, 0.5, -13)
    minimizeBtn.BackgroundColor3 = COLORS.button
    minimizeBtn.TextColor3 = COLORS.text
    minimizeBtn.Font = FONTS.buttons
    minimizeBtn.TextSize = 16
    minimizeBtn.Text = "-"
    minimizeBtn.Parent = titleBar
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = minimizeBtn
    
    -- Botão principal de controle
    toggleBtn = createStyledButton("ToggleBtn", "Auto Farm", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.05, 0, 0.2, 0), mainFrame)
    table.insert(elementsToToggle, toggleBtn)
    
    -- Status
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0.9, 0, 0, 20)
    statusLabel.Position = UDim2.new(0.05, 0, 0.55, 0)
    statusLabel.Text = "Status: Inativo"
    statusLabel.Font = FONTS.main
    statusLabel.TextColor3 = COLORS.text
    statusLabel.TextSize = 14
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    table.insert(elementsToToggle, statusLabel)
    
    -- Container de loot
    lootContainer = Instance.new("Frame")
    lootContainer.Name = "LootContainer"
    lootContainer.Size = UDim2.new(0.9, 0, 0, 30)
    lootContainer.Position = UDim2.new(0.05, 0, 0.75, 0)
    lootContainer.BackgroundColor3 = COLORS.accent
    lootContainer.BackgroundTransparency = 0.9
    lootContainer.Parent = mainFrame
    table.insert(elementsToToggle, lootContainer)
    
    local lootCorner = Instance.new("UICorner")
    lootCorner.CornerRadius = UDim.new(0, 6)
    lootCorner.Parent = lootContainer
    
    -- Configurar layout do loot
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 15)
    layout.Parent = lootContainer
    
    -- Adicionar ícones de loot (serão atualizados depois)
    local fishIcon = Instance.new("TextLabel")
    fishIcon.Name = "FishIcon"
    fishIcon.Size = UDim2.new(0, 80, 0, 30)
    fishIcon.Text = "🐟 0"
    fishIcon.Font = FONTS.main
    fishIcon.TextColor3 = COLORS.text
    fishIcon.TextSize = 14
    fishIcon.BackgroundTransparency = 1
    fishIcon.Parent = lootContainer
    
    local trashIcon = Instance.new("TextLabel")
    trashIcon.Name = "TrashIcon"
    trashIcon.Size = UDim2.new(0, 80, 0, 30)
    trashIcon.Text = "🗑️ 0"
    trashIcon.Font = FONTS.main
    trashIcon.TextColor3 = COLORS.text
    trashIcon.TextSize = 14
    trashIcon.BackgroundTransparency = 1
    trashIcon.Parent = lootContainer
    
    local diamondIcon = Instance.new("TextLabel")
    diamondIcon.Name = "DiamondIcon"
    diamondIcon.Size = UDim2.new(0, 80, 0, 30)
    diamondIcon.Text = "💎 0"
    diamondIcon.Font = FONTS.main
    diamondIcon.TextColor3 = COLORS.text
    diamondIcon.TextSize = 14
    diamondIcon.BackgroundTransparency = 1
    diamondIcon.Parent = lootContainer
    
    -- Função de minimizar
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        for _, element in ipairs(elementsToToggle) do
            element.Visible = not minimized
        end
        
        if minimized then
            mainFrame.Size = UDim2.new(0, 60, 0, 40)
            minimizeBtn.Text = "+"
            minimizeBtn.Position = UDim2.new(0.5, -13, 0.5, -13)
        else
            mainFrame.Size = UDim2.new(0, 280, 0, 180)
            minimizeBtn.Text = "-"
            minimizeBtn.Position = UDim2.new(1, -32, 0.5, -13)
        end
    end)
    
    return gui
end

-- Funções essenciais de pesca
local function equipRod()
    local tool = character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod")
    if tool then
        tool.Parent = character
        task.wait(0.3) -- Tempo para equipar
        return tool
    end
    return nil
end

local function launchLine()
    fishingTool = equipRod()
    if fishingTool and fishingTool:IsDescendantOf(character) then
        fishingTool:Activate()
        statusLabel.Text = "Status: Linha lançada!"
    end
end

-- Bloqueador de clicks
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
    blocker.Parent = player.PlayerGui
    blocker.Visible = false
end

-- Controle do indicador
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
    
    -- Margens ajustáveis
    local margin = safeH * 0.15
    local warningMargin = safeH * 0.3
    
    if indicatorY < (safeY - margin) or indicatorY > (safeY + safeH + margin) then
        return "out"
    elseif indicatorY < (safeY + warningMargin) or indicatorY > (safeY + safeH - warningMargin) then
        return "warning"
    else
        return "safe"
    end
end

-- Sistema combinado de pesca e indicador
local function toggleAutoMode()
    autoMode = not autoMode
    
    if autoMode then
        -- Modo ativado
        toggleBtn.Text = "Disable Auto Farm"
        statusLabel.Text = "Status: Automático"
        createBlocker()
        blocker.Visible = true
        
        -- Iniciar loop de pesca
        spawn(function()
            while autoMode do
                launchLine()
                task.wait(62) -- Intervalo entre pescas
            end
        end)
        
        -- Iniciar controle do indicador
        RunService.Heartbeat:Connect(function()
            if not autoMode then return end
            
            local state = getIndicatorState()
            if state == "warning" or state == "out" then
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
    else
        -- Modo desativado
        toggleBtn.Text = "Auto Farm"
        statusLabel.Text = "Status: Inativo"
        if blocker then blocker.Visible = false end
        if holdingClick then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
            holdingClick = false
        end
    end
    
    -- Atualizar aparência do botão
    TweenService:Create(toggleBtn, TweenInfo.new(0.3), {
        BackgroundColor3 = autoMode and COLORS.button_active or COLORS.button,
        TextColor3 = autoMode and Color3.new(1, 1, 1) or COLORS.text
    }):Play()
end

-- Atualizar contadores de loot
local function updateLootCounts()
    local fishIcon = lootContainer:FindFirstChild("FishIcon")
    local trashIcon = lootContainer:FindFirstChild("TrashIcon")
    local diamondIcon = lootContainer:FindFirstChild("DiamondIcon")
    
    if fishIcon then fishIcon.Text = "🐟 "..fishCount end
    if trashIcon then trashIcon.Text = "🗑️ "..trashCount end
    if diamondIcon then diamondIcon.Text = "💎 "..diamondCount end
    
    -- Animação simples
    spawn(function()
        local originalSize = fishIcon.TextSize
        TweenService:Create(fishIcon, TweenInfo.new(0.15), {TextSize = originalSize + 4}):Play()
        TweenService:Create(trashIcon, TweenInfo.new(0.15), {TextSize = originalSize + 4}):Play()
        TweenService:Create(diamondIcon, TweenInfo.new(0.15), {TextSize = originalSize + 4}):Play()
        task.wait(0.15)
        TweenService:Create(fishIcon, TweenInfo.new(0.15), {TextSize = originalSize}):Play()
        TweenService:Create(trashIcon, TweenInfo.new(0.15), {TextSize = originalSize}):Play()
        TweenService:Create(diamondIcon, TweenInfo.new(0.15), {TextSize = originalSize}):Play()
    end)
end

-- Conexão com eventos do jogo
local function connectGameEvents()
    ReplicatedStorage.Remotes.RemoteEvents.replicatedValue.OnClientEvent:Connect(function(data)
        if data and data.fishing then
            fishCount = data.fishing.Fish or fishCount
            trashCount = data.fishing.Trash or trashCount
            diamondCount = data.fishing.Diamond or diamondCount
            updateLootCounts()
        end
    end)
    
    -- Função para esperar o personagem de forma segura
local function waitForCharacter()
    local maxAttempts = 10
    local attempts = 0
    
    while attempts < maxAttempts do
        if player.Character then
            return player.Character
        end
        attempts += 1
        task.wait(1) -- Esperar 1 segundo entre tentativas
    end
    return nil
end

-- Inicialização completa revisada
local function initialize()
    -- Esperar o personagem de forma segura
    character = waitForCharacter()
    
    if not character then
        warn("Falha ao carregar personagem após 10 segundos")
        return
    end

    -- Verificar se a GUI já existe
    if player.PlayerGui:FindFirstChild("BGHubFishing") then
        player.PlayerGui.BGHubFishing:Destroy()
    end

    -- Criar UI com tratamento de erro
    local success, err = pcall(function()
        createMainUI()
        connectGameEvents()
        
        -- Configurar botão principal
        toggleBtn.MouseButton1Click:Connect(toggleAutoMode)
        
        -- Atualizar contadores iniciais
        updateLootCounts()
        
        -- Verificar equipamento inicial
        if character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod") then
            statusLabel.Text = "Status: Pronto para pescar"
        else
            statusLabel.Text = "Status: Sem vara de pesca"
        end
    end)
    
    if not success then
        warn("Erro na inicialização: " .. err)
        -- Tentar novamente após 5 segundos
        task.wait(5)
        initialize()
    end
end

-- Conexão segura de eventos de personagem
local function setupCharacterEvents()
    player.CharacterAdded:Connect(function(char)
        character = char
        if autoMode then
            task.wait(1) -- Esperar personagem carregar completamente
            local tool = equipRod()
            if not tool then
                statusLabel.Text = "Status: Sem vara de pesca"
            end
        end
    end)
end

-- Modificação na função equipRod para mais segurança
local function equipRod()
    if not character then return nil end
    
    local tool = character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod")
    if tool then
        tool.Parent = character
        task.wait(0.3)
        return tool
    end
    return nil
end

-- Iniciar o script com proteção completa
local function safeStart()
    local success, err = pcall(function()
        setupCharacterEvents()
        initialize()
    end)
    
    if not success then
        warn("Erro no início do script: " .. err)
        task.wait(3)
        safeStart() -- Tentar novamente após 3 segundos
    end
end

-- Iniciar
safeStart()
