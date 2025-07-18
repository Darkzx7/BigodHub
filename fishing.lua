local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

-- Configurações de estilo atualizadas
local STYLE = {
    COLORS = {
        primary = Color3.fromRGB(231, 76, 60),
        secondary = Color3.fromRGB(41, 41, 41),
        accent = Color3.fromRGB(192, 57, 43),
        text = Color3.fromRGB(240, 240, 240),
        dark = Color3.fromRGB(25, 25, 25),
        success = Color3.fromRGB(46, 204, 113),
        warning = Color3.fromRGB(241, 196, 15),
        danger = Color3.fromRGB(231, 76, 60)
    },
    
    FONTS = {
        title = Enum.Font.GothamBlack,
        subtitle = Enum.Font.GothamMedium,
        body = Enum.Font.Gotham,
        bold = Enum.Font.GothamBold
    },
    
    TEXT_SIZES = {
        title = 24,
        subtitle = 16,
        body = 14,
        small = 12
    },
    
    CORNER_RADIUS = UDim.new(0, 8),
    ELEVATION = 5, -- Sombra dos elementos
    TRANSITION_TIME = 0.2 -- Tempo padrão para animações
}

-- Variáveis globais
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack")
local guiRoot = player:WaitForChild("PlayerGui")

local autoFishing = false
local autoIndicatorEnabled = false
local minimized = false
local fishingTool = nil
local blocker = nil
local holdingClick = false
local fishCount, trashCount, diamondCount = 0, 0, 0

-- Elementos da UI que serão criados
local status
local fishIcon, trashIcon, diamondIcon
local elementsToToggle = {}
local toggleFishingFromKey
local heartbeatConnection
local userAvatar = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150" -- URL para avatar do usuário

-- Função para criar elementos com estilo consistente
local function createStyledElement(className, properties)
    local element = Instance.new(className)
    
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    
    -- Aplicar estilos padrão baseados no tipo de elemento
    if className == "TextLabel" or className == "TextButton" or className == "TextBox" then
        element.Font = STYLE.FONTS.body
        element.TextColor3 = STYLE.COLORS.text
        element.TextSize = STYLE.TEXT_SIZES.body
        element.BackgroundTransparency = 1
    end
    
    if className == "Frame" then
        element.BackgroundColor3 = STYLE.COLORS.secondary
        element.BorderSizePixel = 0
    end
    
    if className == "TextButton" then
        element.AutoButtonColor = false
        element.TextColor3 = STYLE.COLORS.text
    end
    
    return element
end

-- Função para aplicar efeito de elevação (sombra)
local function applyElevation(element)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.BackgroundTransparency = 1
    shadow.ZIndex = element.ZIndex - 1
    shadow.Parent = element.Parent or element
end

-- Função para criar um ícone circular (para o avatar do usuário)
local function createCircleIcon(parent, size, position)
    local frame = createStyledElement("Frame", {
        Name = "AvatarFrame",
        Size = size,
        Position = position,
        BackgroundColor3 = STYLE.COLORS.dark,
        Parent = parent
    })
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(1, 0)
    
    local image = createStyledElement("ImageLabel", {
        Name = "AvatarImage",
        Size = UDim2.new(0.9, 0, 0.9, 0),
        Position = UDim2.new(0.05, 0, 0.05, 0),
        BackgroundTransparency = 1,
        Parent = frame
    })
    
    local cornerImage = Instance.new("UICorner", image)
    cornerImage.CornerRadius = UDim.new(1, 0)
    
    return image
end

-- Função para carregar o avatar do usuário
local function loadUserAvatar(avatarFrame)
    local userId = player.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size150x150
    
    Players:GetUserThumbnailAsync(userId, thumbType, thumbSize, function(content, isReady)
        if isReady then
            avatarFrame.Image = content
        else
            avatarFrame.Image = "rbxassetid://0" -- Imagem padrão caso falhe
        end
    end)
end

-- Função para animar elementos (genérica)
local function animateElement(element, properties, duration, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(
        duration or STYLE.TRANSITION_TIME,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(element, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Função para animar ícones de loot (atualizada)
local function animateLoot(icon)
    animateElement(icon, {TextSize = 18}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.wait(0.15)
    animateElement(icon, {TextSize = 14}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)
end

-- Função para atualizar os visuais de loot (atualizada)
local function updateLootVisual()
    fishIcon.Text = "🐟 " .. fishCount
    trashIcon.Text = "🗑️ " .. trashCount
    diamondIcon.Text = "💎 " .. diamondCount
    
    animateLoot(fishIcon)
    animateLoot(trashIcon)
    animateLoot(diamondIcon)
end

-- Função para aplicar efeito hover em botões (atualizada)
local function applyHoverEffect(button)
    local originalColor = button.BackgroundColor3
    
    button.MouseEnter:Connect(function()
        animateElement(button, {
            BackgroundColor3 = originalColor:Lerp(Color3.new(1, 0.3, 0.3), 0.1),
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset + 2)
        })
    end)
    
    button.MouseLeave:Connect(function()
        animateElement(button, {
            BackgroundColor3 = originalColor,
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset - 2)
        })
    end)
end

-- Função para atualizar o estado do botão de pesca (atualizada)
local function updateFishingButtonState(btn, active)
    local color = active and STYLE.COLORS.success or STYLE.COLORS.primary
    animateElement(btn, {BackgroundColor3 = color})
end

-- Função para minimizar/maximizar a UI (atualizada)
local function toggleMinimize(frame, minimizeBtn)
    minimized = not minimized
    
    for _, ui in ipairs(elementsToToggle) do
        if ui:IsA("Frame") then
            animateElement(ui, {Size = minimized and UDim2.new(0, 0, 0, 0) or ui.Size}, 0.3)
            task.wait(0.1)
        else
            ui.Visible = not minimized
        end
    end
    
    animateElement(frame, {
        Size = minimized and UDim2.new(0, 50, 0, 50) or UDim2.new(0, 280, 0, 320)
    }, 0.3)
    
    minimizeBtn.Text = minimized and "+" or "-"
end

-- Função para criar o cabeçalho da UI com o perfil do usuário
local function createHeader(parentFrame)
    local header = createStyledElement("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = STYLE.COLORS.primary,
        Parent = parentFrame
    })
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)
    applyElevation(header)
    
    -- Título
    local title = createStyledElement("TextLabel", {
        Name = "Title",
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(0.6, 0, 0, 30),
        Text = "BIGODE HUB",
        Font = STYLE.FONTS.title,
        TextSize = STYLE.TEXT_SIZES.title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    -- Subtítulo
    local subtitle = createStyledElement("TextLabel", {
        Name = "Subtitle",
        Position = UDim2.new(0, 15, 0, 35),
        Size = UDim2.new(0.6, 0, 0, 20),
        Text = "Pesca Automática v3.5",
        Font = STYLE.FONTS.subtitle,
        TextSize = STYLE.TEXT_SIZES.small,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    -- Avatar do usuário
    local avatarContainer = createStyledElement("Frame", {
        Name = "AvatarContainer",
        Position = UDim2.new(1, -50, 0.5, -20),
        Size = UDim2.new(0, 40, 0, 40),
        BackgroundTransparency = 1,
        Parent = header
    })
    
    local avatarImage = createCircleIcon(avatarContainer, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
    loadUserAvatar(avatarImage)
    
    -- Badge de status (canto do avatar)
    local statusBadge = createStyledElement("Frame", {
        Name = "StatusBadge",
        Position = UDim2.new(0.8, 0, 0.8, 0),
        Size = UDim2.new(0.2, 0, 0.2, 0),
        BackgroundColor3 = STYLE.COLORS.success,
        Parent = avatarImage
    })
    Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(1, 0)
    
    return header
end

-- Função para criar a seção de status e contadores
local function createStatusSection(parentFrame)
    local section = createStyledElement("Frame", {
        Name = "StatusSection",
        Position = UDim2.new(0, 10, 0, 70),
        Size = UDim2.new(1, -20, 0, 80),
        BackgroundTransparency = 1,
        Parent = parentFrame
    })
    
    -- Status da pesca
    status = createStyledElement("TextLabel", {
        Name = "StatusLabel",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        Text = "Status: Inativo",
        Font = STYLE.FONTS.bold,
        TextSize = STYLE.TEXT_SIZES.body,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    -- Contêiner de loot
    local lootContainer = createStyledElement("Frame", {
        Name = "LootContainer",
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = STYLE.COLORS.dark,
        Parent = section
    })
    Instance.new("UICorner", lootContainer).CornerRadius = STYLE.CORNER_RADIUS
    
    -- Divisores
    local divider1 = createStyledElement("Frame", {
        Name = "Divider1",
        Position = UDim2.new(0.33, 0, 0.1, 0),
        Size = UDim2.new(0, 1, 0.8, 0),
        BackgroundColor3 = STYLE.COLORS.secondary,
        Parent = lootContainer
    })
    
    local divider2 = createStyledElement("Frame", {
        Name = "Divider2",
        Position = UDim2.new(0.66, 0, 0.1, 0),
        Size = UDim2.new(0, 1, 0.8, 0),
        BackgroundColor3 = STYLE.COLORS.secondary,
        Parent = lootContainer
    })
    
    -- Ícones de loot
    fishIcon = createStyledElement("TextLabel", {
        Name = "FishIcon",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.33, 0, 1, 0),
        Text = "🐟 0",
        Font = STYLE.FONTS.bold,
        TextSize = STYLE.TEXT_SIZES.body,
        Parent = lootContainer
    })
    
    trashIcon = createStyledElement("TextLabel", {
        Name = "TrashIcon",
        Position = UDim2.new(0.33, 0, 0, 0),
        Size = UDim2.new(0.33, 0, 1, 0),
        Text = "🗑️ 0",
        Font = STYLE.FONTS.bold,
        TextSize = STYLE.TEXT_SIZES.body,
        Parent = lootContainer
    })
    
    diamondIcon = createStyledElement("TextLabel", {
        Name = "DiamondIcon",
        Position = UDim2.new(0.66, 0, 0, 0),
        Size = UDim2.new(0.33, 0, 1, 0),
        Text = "💎 0",
        Font = STYLE.FONTS.bold,
        TextSize = STYLE.TEXT_SIZES.body,
        Parent = lootContainer
    })
    
    table.insert(elementsToToggle, section)
    return section
end

-- Função para criar os botões de controle
local function createControlButtons(parentFrame)
    local buttonContainer = createStyledElement("Frame", {
        Name = "ButtonContainer",
        Position = UDim2.new(0, 10, 0, 160),
        Size = UDim2.new(1, -20, 0, 120),
        BackgroundTransparency = 1,
        Parent = parentFrame
    })
    
    -- Botão de pesca automática
    local btnFishing = createStyledElement("TextButton", {
        Name = "FishingButton",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = STYLE.COLORS.primary,
        Text = "ATIVAR PESCA AUTOMÁTICA",
        Font = STYLE.FONTS.bold,
        TextSize = STYLE.TEXT_SIZES.body,
        Parent = buttonContainer
    })
    Instance.new("UICorner", btnFishing).CornerRadius = STYLE.CORNER_RADIUS
    applyHoverEffect(btnFishing)
    applyElevation(btnFishing)
    
    btnFishing.MouseButton1Click:Connect(function()
        toggleFishingFromKey(btnFishing)
    end)
    
    -- Botão de indicador automático
    local btnIndicator = createStyledElement("TextButton", {
        Name = "IndicatorButton",
        Position = UDim2.new(0, 0, 0, 45),
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = STYLE.COLORS.secondary,
        Text = "ATIVAR INDICADOR AUTOMÁTICO",
        Font = STYLE.FONTS.bold,
        TextSize = STYLE.TEXT_SIZES.body,
        Parent = buttonContainer
    })
    Instance.new("UICorner", btnIndicator).CornerRadius = STYLE.CORNER_RADIUS
    applyHoverEffect(btnIndicator)
    applyElevation(btnIndicator)
    
    btnIndicator.MouseButton1Click:Connect(function()
        autoIndicatorEnabled = not autoIndicatorEnabled
        btnIndicator.Text = autoIndicatorEnabled and "DESATIVAR INDICADOR" or "ATIVAR INDICADOR AUTOMÁTICO"
        
        if autoIndicatorEnabled then
            ensureIndicatorControl()
            animateElement(btnIndicator, {BackgroundColor3 = STYLE.COLORS.accent})
        else
            stopHolding()
            animateElement(btnIndicator, {BackgroundColor3 = STYLE.COLORS.secondary})
        end
    end)
    
    -- Botão de minimizar
    local minimizeBtn = createStyledElement("TextButton", {
        Name = "MinimizeButton",
        Position = UDim2.new(0, 0, 0, 90),
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundColor3 = STYLE.COLORS.dark,
        TextColor3 = STYLE.COLORS.text,
        Text = "MINIMIZAR",
        Font = STYLE.FONTS.subtitle,
        TextSize = STYLE.TEXT_SIZES.small,
        Parent = buttonContainer
    })
    Instance.new("UICorner", minimizeBtn).CornerRadius = STYLE.CORNER_RADIUS
    applyHoverEffect(minimizeBtn)
    
    table.insert(elementsToToggle, buttonContainer)
    return buttonContainer, minimizeBtn
end

-- Função para criar o rodapé
local function createFooter(parentFrame)
    local footer = createStyledElement("Frame", {
        Name = "Footer",
        Position = UDim2.new(0, 10, 1, -40),
        Size = UDim2.new(1, -20, 0, 30),
        BackgroundTransparency = 1,
        Parent = parentFrame
    })
    
    local warningText = createStyledElement("TextLabel", {
        Name = "WarningText",
        Size = UDim2.new(1, 0, 1, 0),
        Text = "Caso bugue ou pare de funcionar, execute o script novamente",
        Font = STYLE.FONTS.subtitle,
        TextSize = STYLE.TEXT_SIZES.small,
        TextColor3 = STYLE.COLORS.warning,
        TextWrapped = true,
        Parent = footer
    })
    
    table.insert(elementsToToggle, footer)
    return footer
end

-- Função principal para criar a UI (atualizada)
local function createGUI()
    local gui = Instance.new("ScreenGui", guiRoot)
    gui.Name = "FishingHUD"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.ResetOnSpawn = false
    
    local mainFrame = createStyledElement("Frame", {
        Position = UDim2.new(1, -300, 0.3, 0),
        Size = UDim2.new(0, 280, 0, 320),
        BackgroundColor3 = STYLE.COLORS.secondary,
        Parent = gui
    })
    Instance.new("UICorner", mainFrame).CornerRadius = STYLE.CORNER_RADIUS
    applyElevation(mainFrame)
    
    -- Criação das seções da UI
    createHeader(mainFrame)
    createStatusSection(mainFrame)
    local _, minimizeBtn = createControlButtons(mainFrame)
    createFooter(mainFrame)
    
    -- Configuração do minimizar
    minimizeBtn.MouseButton1Click:Connect(function()
        toggleMinimize(mainFrame, minimizeBtn)
    end)
    
    -- Conexão com eventos remotos para atualizar os contadores
    ReplicatedStorage.Remotes.RemoteEvents.replicatedValue.OnClientEvent:Connect(function(data)
        if data and data.fishing then
            fishCount = data.fishing.Fish or 0
            trashCount = data.fishing.Trash or 0
            diamondCount = data.fishing.Diamond or 0
            updateLootVisual()
        end
    end)
    
    return mainFrame
end

-- Função para equipar a vara de pesca (atualizada com feedback visual)
local function equipRod()
    local tool = character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod")
    
    if tool then
        tool.Parent = character
        status.Text = "Status: Equipando vara..."
        animateElement(status, {TextColor3 = STYLE.COLORS.warning})
        
        local equipTime = 0.5
        local startTime = tick()
        
        while tick() - startTime < equipTime do
            local progress = (tick() - startTime) / equipTime
            status.Text = string.format("Status: Equipando... (%d%%)", math.floor(progress * 100))
            task.wait(0.05)
        end
        
        status.Text = "Status: Vara equipada!"
        animateElement(status, {TextColor3 = STYLE.COLORS.success})
        task.wait(0.5)
        
        return tool
    else
        status.Text = "Status: Vara não encontrada!"
        animateElement(status, {TextColor3 = STYLE.COLORS.danger})
        return nil
    end
end

-- Função para lançar a linha (atualizada com animação)
local function launchLine()
    fishingTool = equipRod()
    
    if fishingTool and fishingTool:IsDescendantOf(character) then
        status.Text = "Status: Lançando linha..."
        animateElement(status, {TextColor3 = STYLE.COLORS.warning})
        
        -- Simular animação de lançamento
        for i = 1, 3 do
            status.Text = "Status: Lançando linha" .. string.rep(".", i)
            task.wait(0.2)
        end
        
        fishingTool:Activate()
        status.Text = "Status: Linha lançada!"
        animateElement(status, {TextColor3 = STYLE.COLORS.success})
        
        -- Efeito visual de onda
        local waveEffect = Instance.new("TextLabel", status)
        waveEffect.Text = "~~~"
        waveEffect.Size = UDim2.new(1, 0, 1, 0)
        waveEffect.Position = UDim2.new(0, 0, 0, 0)
        waveEffect.BackgroundTransparency = 1
        waveEffect.TextColor3 = Color3.fromRGB(100, 180, 255)
        waveEffect.Font = Enum.Font.GothamBold
        waveEffect.TextSize = 16
        
        animateElement(waveEffect, {Position = UDim2.new(1, 0, 0, 0)}, 1.5)
        task.wait(1.5)
        waveEffect:Destroy()
    else
        status.Text = "Status: Falha ao lançar!"
        animateElement(status, {TextColor3 = STYLE.COLORS.danger})
    end
end

-- Função para criar o bloqueador de input (atualizada)
local function createBlocker()
    if blocker then blocker:Destroy() end
    
    blocker = Instance.new("Frame", guiRoot)
    blocker.Name = "FishingBlocker"
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.Position = UDim2.new(0, 0, 0, 0)
    blocker.BackgroundColor3 = Color3.new(0, 0, 0)
    blocker.BackgroundTransparency = 0.7
    blocker.ZIndex = 9998
    blocker.Visible = false
    
    local label = Instance.new("TextLabel", blocker)
    label.Size = UDim2.new(1, 0, 0, 50)
    label.Position = UDim2.new(0, 0, 0.5, -25)
    label.Text = "PESCA AUTOMÁTICA ATIVA"
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 24
    label.TextCo
