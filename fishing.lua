local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configurações de estilo atualizadas
local COLORS = {
    bg = Color3.fromRGB(10, 10, 15),
    bgSecondary = Color3.fromRGB(20, 20, 30),
    accent = Color3.fromRGB(255, 60, 60),
    accentHover = Color3.fromRGB(255, 80, 80),
    text = Color3.new(0.9, 0.9, 0.9),
    textSecondary = Color3.fromRGB(180, 180, 180),
    highlight = Color3.fromRGB(40, 40, 60)
}

local FONTS = {
    title = Enum.Font.GothamBlack,
    header = Enum.Font.GothamBold,
    body = Enum.Font.GothamMedium,
    button = Enum.Font.GothamBold
}

-- Variáveis de estado (mantidas as mesmas)
local autoFishing = false
local autoIndicatorEnabled = false
local minimized = false
local fishingTool = nil
local blocker = nil
local holdingClick = false
local fishCount, trashCount, diamondCount = 0, 0, 0
local status
local fishIcon, trashIcon, diamondIcon
local elementsToToggle = {}
local toggleFishingFromKey
local heartbeatConnection

-- Funções auxiliares de UI
local function createRoundedFrame(parent, size, position, bgColor, cornerRadius)
    local frame = Instance.new("Frame", parent)
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = bgColor
    frame.BackgroundTransparency = bgColor == nil and 1 or 0
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(cornerRadius or 0.2, 0)
    
    return frame
end

local function createTextLabel(parent, text, size, position, font, textSize, textColor)
    local label = Instance.new("TextLabel", parent)
    label.Text = text
    label.Size = size
    label.Position = position
    label.Font = font
    label.TextSize = textSize
    label.TextColor3 = textColor
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    return label
end

local function createButton(parent, text, size, position)
    local button = Instance.new("TextButton", parent)
    button.Text = text
    button.Size = size
    button.Position = position
    button.Font = FONTS.button
    button.TextSize = 14
    button.TextColor3 = COLORS.text
    button.BackgroundColor3 = COLORS.accent
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0.15, 0)
    
    -- Efeito hover moderno
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = COLORS.accentHover,
            TextColor3 = Color3.new(1, 1, 1)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = COLORS.accent,
            TextColor3 = COLORS.text
        }):Play()
    end)
    
    -- Efeito de clique
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = COLORS.highlight,
            TextColor3 = Color3.new(0.8, 0.8, 0.8)
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = COLORS.accentHover,
            TextColor3 = Color3.new(1, 1, 1)
        }):Play()
    end)
    
    return button
end

local function createLootCounter(parent)
    local container = createRoundedFrame(parent, UDim2.new(0.9, 0, 0, 50), 
        UDim2.new(0.05, 0, 0, 80), COLORS.bgSecondary, 0.15)
    
    -- Adicionando sombra (efeito moderno)
    local shadow = Instance.new("ImageLabel", container)
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.BackgroundTransparency = 1
    shadow.ZIndex = -1
    
    -- Divisores entre os itens
    local divider1 = Instance.new("Frame", container)
    divider1.Size = UDim2.new(0, 1, 0.6, 0)
    divider1.Position = UDim2.new(0.33, 0, 0.2, 0)
    divider1.BackgroundColor3 = COLORS.highlight
    divider1.BorderSizePixel = 0
    
    local divider2 = divider1:Clone()
    divider2.Parent = container
    divider2.Position = UDim2.new(0.66, 0, 0.2, 0)
    
    -- Ícones de loot
    fishIcon = createTextLabel(container, "🐟 0", UDim2.new(0.3, 0, 1, 0), 
        UDim2.new(0, 0, 0, 0), FONTS.body, 18, COLORS.text)
    fishIcon.TextXAlignment = Enum.TextXAlignment.Center
    
    trashIcon = createTextLabel(container, "🗑️ 0", UDim2.new(0.3, 0, 1, 0), 
        UDim2.new(0.34, 0, 0, 0), FONTS.body, 18, COLORS.text)
    trashIcon.TextXAlignment = Enum.TextXAlignment.Center
    
    diamondIcon = createTextLabel(container, "💎 0", UDim2.new(0.3, 0, 1, 0), 
        UDim2.new(0.67, 0, 0, 0), FONTS.body, 18, COLORS.text)
    diamondIcon.TextXAlignment = Enum.TextXAlignment.Center
    
    table.insert(elementsToToggle, container)
    return container
end

local function createStatusBar(parent)
    local container = createRoundedFrame(parent, UDim2.new(0.9, 0, 0, 30), 
        UDim2.new(0.05, 0, 0, 40), COLORS.bgSecondary, 0.15)
    
    status = createTextLabel(container, "STATUS: INATIVO", UDim2.new(1, -20, 1, 0), 
        UDim2.new(0, 10, 0, 0), FONTS.header, 14, COLORS.text)
    
    -- Indicador de status (ponto colorido)
    local statusDot = Instance.new("Frame", container)
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(1, -15, 0.5, -4)
    statusDot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
    
    table.insert(elementsToToggle, container)
    return container
end

local function updateStatus(text, color)
    status.Text = "STATUS: " .. string.upper(text)
    
    local dot = status.Parent:FindFirstChildOfClass("Frame")
    if dot then
        TweenService:Create(dot, TweenInfo.new(0.3), {
            BackgroundColor3 = color or Color3.fromRGB(150, 150, 150)
        }):Play()
    end
end

local function createMainUI()
    local gui = Instance.new("ScreenGui", guiRoot)
    gui.Name = "FishingHUD"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Frame principal com efeito de vidro
    local mainFrame = createRoundedFrame(gui, UDim2.new(0, 300, 0, 300), 
        UDim2.new(1, -320, 0.3, 0), COLORS.bg)
    mainFrame.BackgroundTransparency = 0.2
    
    -- Efeito de blur (opcional, apenas se o jogo permitir)
    local blur = Instance.new("BlurEffect", mainFrame)
    blur.Name = "FrameBlur"
    blur.Size = 8
    blur.Enabled = false -- Pode ser ativado se quiser
    
    -- Barra de título com gradiente
    local titleBar = createRoundedFrame(mainFrame, UDim2.new(1, 0, 0, 40), 
        UDim2.new(0, 0, 0, 0), COLORS.accent)
    titleBar.ZIndex = 2
    
    local title = createTextLabel(titleBar, "BIGODE FISHING", UDim2.new(1, -40, 1, 0), 
        UDim2.new(0, 15, 0, 0), FONTS.title, 18, COLORS.text)
    
    -- Botão de minimizar moderno
    local minimizeBtn = createRoundedFrame(titleBar, UDim2.new(0, 26, 0, 26), 
        UDim2.new(1, -30, 0.5, -13), COLORS.highlight, 1)
    minimizeBtn.ZIndex = 3
    
    local minimizeIcon = createTextLabel(minimizeBtn, "-", UDim2.new(1, 0, 1, 0), 
        UDim2.new(0, 0, 0, 0), FONTS.header, 18, COLORS.text)
    minimizeIcon.TextXAlignment = Enum.TextXAlignment.Center
    
    minimizeBtn.MouseButton1Click:Connect(function()
        toggleMinimize(mainFrame, minimizeIcon)
    end)
    
    -- Adicionando elementos ao frame principal
    createStatusBar(mainFrame)
    createLootCounter(mainFrame)
    
    -- Botões de ação
    local btnFishing = createButton(mainFrame, "ATIVAR PESCA AUTOMÁTICA", 
        UDim2.new(0.9, 0, 0, 40), UDim2.new(0.05, 0, 0, 140))
    table.insert(elementsToToggle, btnFishing)
    
    local btnIndicator = createButton(mainFrame, "ATIVAR INDICADOR AUTOMÁTICO", 
        UDim2.new(0.9, 0, 0, 40), UDim2.new(0.05, 0, 0, 190))
    btnIndicator.BackgroundColor3 = COLORS.highlight
    table.insert(elementsToToggle, btnIndicator)
    
    -- Rodapé com aviso
    local footer = createTextLabel(mainFrame, "Pressione P para ativar/desativar rapidamente", 
        UDim2.new(0.9, 0, 0, 30), UDim2.new(0.05, 0, 1, -35), FONTS.body, 12, COLORS.textSecondary)
    footer.TextXAlignment = Enum.TextXAlignment.Center
    table.insert(elementsToToggle, footer)
    
    -- Conectando os botões às funções existentes
    btnFishing.MouseButton1Click:Connect(function()
        toggleFishingFromKey(btnFishing)
    end)
    
    btnIndicator.MouseButton1Click:Connect(function()
        autoIndicatorEnabled = not autoIndicatorEnabled
        btnIndicator.Text = autoIndicatorEnabled and "DESATIVAR INDICADOR" or "ATIVAR INDICADOR AUTOMÁTICO"
        btnIndicator.BackgroundColor3 = autoIndicatorEnabled and COLORS.accent or COLORS.highlight
        
        if autoIndicatorEnabled then
            ensureIndicatorControl()
        else
            stopHolding()
        end
    end)
    
    return gui
end

-- Função de animação de loot atualizada
local function animateLoot(icon)
    local originalSize = icon.TextSize
    local originalPos = icon.Position
    
    -- Animação mais suave com escalonamento
    TweenService:Create(icon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextSize = originalSize + 4,
        Position = originalPos - UDim2.new(0, 0, 0.05, 0)
    }):Play()
    
    task.wait(0.15)
    
    TweenService:Create(icon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextSize = originalSize,
        Position = originalPos
    }):Play()
end

-- Atualização da função toggleMinimize para a nova UI
local function toggleMinimize(frame, minimizeIcon)
    minimized = not minimized
    
    for _, ui in ipairs(elementsToToggle) do
        if ui ~= frame and ui.Parent == frame then
            ui.Visible = not minimized
        end
    end
    
    frame.Size = minimized and UDim2.new(0, 50, 0, 50) or UDim2.new(0, 300, 0, 300)
    minimizeIcon.Text = minimized and "+" or "-"
    
    -- Ajustar posição do botão de minimizar quando minimizado
    if minimized then
        minimizeIcon.Parent.Position = UDim2.new(0.5, -13, 0.5, -13)
    else
        minimizeIcon.Parent.Position = UDim2.new(1, -30, 0.5, -13)
    end
end
