local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack")
local guiRoot = player:WaitForChild("PlayerGui")

-- Configurações atualizadas
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

-- Cores modernizadas
local COLORS = {
    bg = Color3.fromRGB(10, 10, 10),
    title = Color3.fromRGB(255, 50, 50),
    buttonPrimary = Color3.fromRGB(200, 50, 50),
    buttonSecondary = Color3.fromRGB(40, 40, 40),
    text = Color3.new(0.9, 0.9, 0.9),
    accent = Color3.fromRGB(80, 80, 80),
    profileBg = Color3.fromRGB(20, 20, 20)
}

-- Efeitos de sombra
local function applyShadow(object)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Size = UDim2.new(1, 14, 1, 14)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.BackgroundTransparency = 1
    shadow.ZIndex = object.ZIndex - 1
    shadow.Parent = object
    return shadow
end

-- Função para criar avatar circular
local function createProfilePicture(parent, size, position)
    local profileFrame = Instance.new("Frame")
    profileFrame.Name = "ProfileFrame"
    profileFrame.Size = size
    profileFrame.Position = position
    profileFrame.BackgroundColor3 = COLORS.profileBg
    profileFrame.BorderSizePixel = 0
    profileFrame.ZIndex = 10
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = profileFrame
    
    local profileImage = Instance.new("ImageLabel")
    profileImage.Name = "ProfileImage"
    profileImage.Size = UDim2.new(0.9, 0, 0.9, 0)
    profileImage.Position = UDim2.new(0.05, 0, 0.05, 0)
    profileImage.BackgroundTransparency = 1
    profileImage.ZIndex = 11
    
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(1, 0)
    corner2.Parent = profileImage
    
    -- Carregar imagem do avatar
    local userId = player.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
    
    profileImage.Image = content
    profileImage.Parent = profileFrame
    profileFrame.Parent = parent
    
    -- Adicionar borda decorativa
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.Size = UDim2.new(1, 0, 1, 0)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 0
    border.ZIndex = 12
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.title),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
    })
    gradient.Rotation = 90
    gradient.Parent = border
    
    local corner3 = Instance.new("UICorner")
    corner3.CornerRadius = UDim.new(1, 0)
    corner3.Parent = border
    
    border.Parent = profileFrame
    
    applyShadow(profileFrame)
    
    return profileFrame
end

-- Função para criar rótulo de usuário
local function createUserLabel(parent, size, position)
    local userFrame = Instance.new("Frame")
    userFrame.Name = "UserFrame"
    userFrame.Size = size
    userFrame.Position = position
    userFrame.BackgroundTransparency = 1
    
    local userName = Instance.new("TextLabel")
    userName.Name = "UserName"
    userName.Size = UDim2.new(1, 0, 0.6, 0)
    userName.Position = UDim2.new(0, 0, 0, 0)
    userName.Text = player.Name
    userName.Font = Enum.Font.GothamBold
    userName.TextColor3 = COLORS.text
    userName.TextSize = 16
    userName.TextXAlignment = Enum.TextXAlignment.Left
    userName.BackgroundTransparency = 1
    
    local userStatus = Instance.new("TextLabel")
    userStatus.Name = "UserStatus"
    userStatus.Size = UDim2.new(1, 0, 0.4, 0)
    userStatus.Position = UDim2.new(0, 0, 0.6, 0)
    userStatus.Text = "Status: Online"
    userStatus.Font = Enum.Font.Gotham
    userStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    userStatus.TextSize = 12
    userStatus.TextXAlignment = Enum.TextXAlignment.Left
    userStatus.BackgroundTransparency = 1
    
    userName.Parent = userFrame
    userStatus.Parent = userFrame
    userFrame.Parent = parent
    
    return userFrame
end

-- Função para criar a área do perfil
local function createProfileSection(parent)
    local profileSection = Instance.new("Frame")
    profileSection.Name = "ProfileSection"
    profileSection.Size = UDim2.new(1, -20, 0, 70)
    profileSection.Position = UDim2.new(0, 10, 0, 10)
    profileSection.BackgroundTransparency = 1
    
    -- Foto de perfil
    local profilePic = createProfilePicture(profileSection, UDim2.new(0, 50, 0, 50), UDim2.new(0, 0, 0, 0))
    
    -- Informações do usuário
    local userLabel = createUserLabel(profileSection, UDim2.new(0.7, 0, 1, 0), UDim2.new(0, 60, 0, 0))
    
    profileSection.Parent = parent
    return profileSection
end

-- Função para criar botão moderno
local function createModernButton(parent, text, size, position, isPrimary)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = isPrimary and COLORS.buttonPrimary or COLORS.buttonSecondary
    button.TextColor3 = COLORS.text
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.Text = text
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    applyShadow(button)
    
    -- Efeito hover
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = isPrimary and Color3.fromRGB(220, 60, 60) or Color3.fromRGB(60, 60, 60)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = isPrimary and COLORS.buttonPrimary or COLORS.buttonSecondary
        }):Play()
    end)
    
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = isPrimary and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(30, 30, 30)
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            BackgroundColor3 = isPrimary and Color3.fromRGB(220, 60, 60) or Color3.fromRGB(60, 60, 60)
        }):Play()
    end)
    
    button.Parent = parent
    return button
end

-- Função para criar a GUI principal (continua na parte 2)

-- Continuação do script...

-- Função para criar a GUI principal
local function createGUI()
    local gui = Instance.new("ScreenGui", guiRoot)
    gui.Name = "FishingHUD"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    -- Frame principal
    local mainFrame = Instance.new("Frame", gui)
    mainFrame.Name = "MainFrame"
    mainFrame.Position = UDim2.new(1, -300, 0.3, 0)
    mainFrame.Size = UDim2.new(0, 300, 0, 350)
    mainFrame.BackgroundColor3 = COLORS.bg
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local mainCorner = Instance.new("UICorner", mainFrame)
    mainCorner.CornerRadius = UDim.new(0, 12)
    
    applyShadow(mainFrame)

    -- Barra de título
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = COLORS.title
    titleBar.BorderSizePixel = 0
    
    local titleCorner = Instance.new("UICorner", titleBar)
    titleCorner.CornerRadius = UDim.new(0, 12)
    
    local titleText = Instance.new("TextLabel", titleBar)
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.Position = UDim2.new(0.15, 0, 0, 0)
    titleText.Text = "BIGODE HUB v3.5"
    titleText.Font = Enum.Font.GothamBlack
    titleText.TextColor3 = Color3.new(1, 1, 1)
    titleText.TextSize = 16
    titleText.BackgroundTransparency = 1
    titleText.TextXAlignment = Enum.TextXAlignment.Left

    -- Botão de minimizar
    local minimizeBtn = Instance.new("TextButton", titleBar)
    minimizeBtn.Name = "MinimizeButton"
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -35, 0.5, -15)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 16
    minimizeBtn.Text = "-"
    
    local minimizeCorner = Instance.new("UICorner", minimizeBtn)
    minimizeCorner.CornerRadius = UDim.new(1, 0)
    
    -- Efeitos do botão minimizar
    applyHoverEffect(minimizeBtn)

    -- Seção de perfil do usuário
    local profileSection = createProfileSection(mainFrame)
    table.insert(elementsToToggle, profileSection)

    -- Status da pesca
    status = Instance.new("TextLabel", mainFrame)
    status.Name = "StatusLabel"
    status.Position = UDim2.new(0, 15, 0, 90)
    status.Size = UDim2.new(1, -30, 0, 20)
    status.BackgroundTransparency = 1
    status.Text = "Status: Inativo"
    status.TextColor3 = COLORS.text
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 14
    status.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(elementsToToggle, status)

    -- Contador de itens
    local lootBox = Instance.new("Frame", mainFrame)
    lootBox.Name = "LootBox"
    lootBox.Position = UDim2.new(0.05, 0, 0, 120)
    lootBox.Size = UDim2.new(0.9, 0, 0, 40)
    lootBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    
    local lootCorner = Instance.new("UICorner", lootBox)
    lootCorner.CornerRadius = UDim.new(0, 8)
    
    local lootLayout = Instance.new("UIListLayout", lootBox)
    lootLayout.FillDirection = Enum.FillDirection.Horizontal
    lootLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    lootLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    lootLayout.Padding = UDim.new(0, 15)
    
    fishIcon = Instance.new("TextLabel", lootBox)
    fishIcon.Name = "FishIcon"
    fishIcon.Size = UDim2.new(0, 80, 0, 30)
    fishIcon.BackgroundTransparency = 1
    fishIcon.TextColor3 = COLORS.text
    fishIcon.Font = Enum.Font.GothamBold
    fishIcon.TextSize = 14
    fishIcon.Text = "🐟 0"

    trashIcon = Instance.new("TextLabel", lootBox)
    trashIcon.Name = "TrashIcon"
    trashIcon.Size = UDim2.new(0, 80, 0, 30)
    trashIcon.BackgroundTransparency = 1
    trashIcon.TextColor3 = COLORS.text
    trashIcon.Font = Enum.Font.GothamBold
    trashIcon.TextSize = 14
    trashIcon.Text = "🗑️ 0"

    diamondIcon = Instance.new("TextLabel", lootBox)
    diamondIcon.Name = "DiamondIcon"
    diamondIcon.Size = UDim2.new(0, 80, 0, 30)
    diamondIcon.BackgroundTransparency = 1
    diamondIcon.TextColor3 = COLORS.text
    diamondIcon.Font = Enum.Font.GothamBold
    diamondIcon.TextSize = 14
    diamondIcon.Text = "💎 0"

    table.insert(elementsToToggle, lootBox)

    -- Botão de pesca automática
    local fishingBtn = createModernButton(mainFrame, "ATIVAR PESCA AUTOMÁTICA", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.05, 0, 0, 170), true)
    table.insert(elementsToToggle, fishingBtn)

    fishingBtn.MouseButton1Click:Connect(function()
        toggleFishingFromKey(fishingBtn)
    end)

    -- Botão de indicador automático
    local indicatorBtn = createModernButton(mainFrame, "ATIVAR INDICADOR AUTOMÁTICO", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.05, 0, 0, 220), false)
    table.insert(elementsToToggle, indicatorBtn)

    indicatorBtn.MouseButton1Click:Connect(function()
        autoIndicatorEnabled = not autoIndicatorEnabled
        indicatorBtn.Text = autoIndicatorEnabled and "DESATIVAR INDICADOR" or "ATIVAR INDICADOR AUTOMÁTICO"
        
        if autoIndicatorEnabled then
            ensureIndicatorControl()
        else
            stopHolding()
        end
    end)

    -- Mensagem de aviso
    local warningLabel = Instance.new("TextLabel", mainFrame)
    warningLabel.Name = "WarningLabel"
    warningLabel.Position = UDim2.new(0.05, 0, 1, -40)
    warningLabel.Size = UDim2.new(0.9, 0, 0, 30)
    warningLabel.Text = "Caso bugue ou pare de pescar, execute o script novamente!"
    warningLabel.Font = Enum.Font.Gotham
    warningLabel.TextSize = 11
    warningLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    warningLabel.BackgroundTransparency = 1
    warningLabel.TextWrapped = true
    warningLabel.TextYAlignment = Enum.TextYAlignment.Center
    table.insert(elementsToToggle, warningLabel)

    -- Função de minimizar
    minimizeBtn.MouseButton1Click:Connect(function()
        toggleMinimize(mainFrame, minimizeBtn)
    end)

    -- Conectar eventos remotos para atualizar contadores
    ReplicatedStorage.Remotes.RemoteEvents.replicatedValue.OnClientEvent:Connect(function(data)
        if data and data.fishing then
            fishCount = data.fishing.Fish or 0
            trashCount = data.fishing.Trash or 0
            diamondCount = data.fishing.Diamond or 0
            updateLootVisual()
        end
    end)

    return gui
end

-- Função para animação de loot (atualizada)
local function animateLoot(icon)
    local originalSize = icon.TextSize
    TweenService:Create(icon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextSize = originalSize + 4,
        TextColor3 = Color3.new(1, 1, 1)
    }):Play()
    
    task.wait(0.15)
    
    TweenService:Create(icon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextSize = originalSize,
        TextColor3 = COLORS.text
    }):Play()
end

-- Função para atualizar visual dos itens
local function updateLootVisual()
    fishIcon.Text = "🐟 " .. fishCount
    trashIcon.Text = "🗑️ " .. trashCount
    diamondIcon.Text = "💎 " .. diamondCount
    
    animateLoot(fishIcon)
    animateLoot(trashIcon)
    animateLoot(diamondIcon)
end

-- Função para alternar minimizar (atualizada)
local function toggleMinimize(frame, minimizeBtn)
    minimized = not minimized
    
    for _, ui in ipairs(elementsToToggle) do
        ui.Visible = not minimized
    end
    
    if minimized then
        frame:TweenSize(UDim2.new(0, 50, 0, 50), "Out", "Quad", 0.3, true)
        minimizeBtn.Text = "+"
        
        -- Centralizar ícone quando minimizado
        minimizeBtn.Position = UDim2.new(0.5, -15, 0.5, -15)
    else
        frame:TweenSize(UDim2.new(0, 300, 0, 350), "Out", "Quad", 0.3, true)
        minimizeBtn.Text = "-"
        minimizeBtn.Position = UDim2.new(1, -35, 0.5, -15)
    end
end

-- Restante das funções originais permanecem inalteradas
-- (equipRod, launchLine, createBlocker, startHolding, stopHolding, getIndicatorState, etc.)

-- Mostrar introdução animada (continua na parte 3)

-- Continuação do script...

-- Função para mostrar introdução animada (atualizada)
local function showAnimatedIntro(callback)
    local introGui = Instance.new("ScreenGui", guiRoot)
    introGui.Name = "BigodeIntro"
    introGui.IgnoreGuiInset = true
    introGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local container = Instance.new("Frame", introGui)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = COLORS.bg
    container.BorderSizePixel = 0

    -- Logo central
    local logoContainer = Instance.new("Frame", container)
    logoContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    logoContainer.Position = UDim2.new(0.5, 0, 0.4, 0)
    logoContainer.Size = UDim2.new(0, 0, 0, 0)
    logoContainer.BackgroundTransparency = 1

    local logoText = Instance.new("TextLabel", logoContainer)
    logoText.AnchorPoint = Vector2.new(0.5, 0.5)
    logoText.Position = UDim2.new(0.5, 0, 0.5, 0)
    logoText.Size = UDim2.new(0, 400, 0, 60)
    logoText.Text = "BIGODE HUB"
    logoText.Font = Enum.Font.GothamBlack
    logoText.TextColor3 = COLORS.title
    logoText.TextSize = 0 -- Começa invisível
    logoText.BackgroundTransparency = 1
    logoText.TextTransparency = 1

    local versionText = Instance.new("TextLabel", logoContainer)
    versionText.AnchorPoint = Vector2.new(0.5, 0.5)
    versionText.Position = UDim2.new(0.5, 0, 0.5, 30)
    versionText.Size = UDim2.new(0, 400, 0, 24)
    versionText.Text = "PESCA AUTOMÁTICA v3.5"
    versionText.Font = Enum.Font.GothamMedium
    versionText.TextColor3 = Color3.fromRGB(200, 200, 200)
    versionText.TextSize = 0 -- Começa invisível
    versionText.BackgroundTransparency = 1
    versionText.TextTransparency = 1

    -- Barra de progresso
    local progressBarBack = Instance.new("Frame", container)
    progressBarBack.AnchorPoint = Vector2.new(0.5, 0.5)
    progressBarBack.Position = UDim2.new(0.5, 0, 0.6, 0)
    progressBarBack.Size = UDim2.new(0, 300, 0, 12)
    progressBarBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    progressBarBack.BorderSizePixel = 0
    Instance.new("UICorner", progressBarBack).CornerRadius = UDim.new(1, 0)

    local progressBarFill = Instance.new("Frame", progressBarBack)
    progressBarFill.Size = UDim2.new(0, 0, 1, 0)
    progressBarFill.BackgroundColor3 = COLORS.title
    progressBarFill.BorderSizePixel = 0
    Instance.new("UICorner", progressBarFill).CornerRadius = UDim.new(1, 0)

    -- Efeito de partículas
    local particles = Instance.new("Frame", container)
    particles.Size = UDim2.new(1, 0, 1, 0)
    particles.BackgroundTransparency = 1

    -- Animação de entrada
    logoContainer:TweenSize(UDim2.new(0, 420, 0, 100), "Out", "Back", 0.8)

    TweenService:Create(logoText, TweenInfo.new(0.8), {
        TextSize = 42,
        TextTransparency = 0,
        TextStrokeTransparency = 0.7
    }):Play()

    task.wait(0.3)

    TweenService:Create(versionText, TweenInfo.new(0.8), {
        TextSize = 16,
        TextTransparency = 0
    }):Play()

    -- Animação da barra de progresso
    for i = 1, 100 do
        progressBarFill:TweenSize(UDim2.new(i/100, 0, 1, 0), "Out", "Quad", 0.02, true)
        
        -- Adicionar partículas aleatórias durante o carregamento
        if i % 15 == 0 then
            local particle = Instance.new("TextLabel", particles)
            particle.Text = "✧"
            particle.TextColor3 = COLORS.title
            particle.TextSize = math.random(14, 22)
            particle.Position = UDim2.new(0, math.random(0, 1200), 0, math.random(0, 700))
            particle.BackgroundTransparency = 1
            
            spawn(function()
                TweenService:Create(particle, TweenInfo.new(0.5), {
                    Position = UDim2.new(0, particle.Position.X.Offset + math.random(-50, 50), 
                    0, particle.Position.Y.Offset + math.random(-50, 50)),
                    TextTransparency = 1
                }):Play()
                task.wait(0.5)
                particle:Destroy()
            end)
        end
        
        task.wait(0.02)
    end

    task.wait(0.5)

    -- Animação de saída
    TweenService:Create(logoText, TweenInfo.new(0.6), {
        TextSize = 0,
        TextTransparency = 1
    }):Play()

    TweenService:Create(versionText, TweenInfo.new(0.6), {
        TextSize = 0,
        TextTransparency = 1
    }):Play()

    TweenService:Create(progressBarBack, TweenInfo.new(0.6), {
        BackgroundTransparency = 1
    }):Play()

    TweenService:Create(progressBarFill, TweenInfo.new(0.6), {
        BackgroundTransparency = 1
    }):Play()

    logoContainer:TweenSize(UDim2.new(0, 0, 0, 0), "In", "Back", 0.6)

    task.wait(0.6)
    introGui:Destroy()
    
    if callback then 
        callback()
    end
end

-- Conexão de tecla para ativar/desativar pesca
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        local gui = guiRoot:FindFirstChild("FishingHUD")
        if gui then
            local btn = gui:FindFirstChild("MainFrame"):FindFirstChild("FishingButton")
            if btn then 
                toggleFishingFromKey(btn) 
            end
        end
    end
end)

-- Função para alternar pesca via tecla/botão
toggleFishingFromKey = function(buttonRef)
    if autoFishing then
        autoFishing = false
        status.Text = "Status: Inativo"
        if buttonRef then 
            buttonRef.Text = "ATIVAR PESCA AUTOMÁTICA"
            TweenService:Create(buttonRef, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.buttonPrimary
            }):Play()
        end
        if blocker then blocker.Visible = false end
        stopHolding()
    else
        autoFishing = true
        status.Text = "Status: Automático"
        if not blocker then createBlocker() end
        blocker.Visible = true
        if buttonRef then 
            buttonRef.Text = "DESATIVAR PESCA"
            TweenService:Create(buttonRef, TweenInfo.new(0.3), {
                BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            }):Play()
        end
        
        spawn(function()
            while autoFishing do
                launchLine()
                task.wait(62)
            end
        end)
    end
end

-- Inicialização
showAnimatedIntro(function()
    createGUI()
    
    -- Atualizar contadores iniciais
    updateLootVisual()
    
    -- Verificar se já tem vara equipada
    if character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod") then
        status.Text = "Status: Pronto para pescar"
    end
end)

-- Funções originais mantidas (não mostradas aqui para evitar repetição):
-- equipRod, launchLine, createBlocker, startHolding, stopHolding, 
-- getIndicatorState, ensureIndicatorControl, onCharacterAdded

-- Continuação do script com funções inalteradas --

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
        status.Text = "Status: Linha lançada!"
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

local function startHolding()
    if not holdingClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
        holdingClick = true
    end
end

local function stopHolding()
    if holdingClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
        holdingClick = false
    end
end

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
    local effectiveSize = math.max(safeH, 0.05)
    local margin = math.max(effectiveSize * 0.1, 0.015)
    local bufferApproach = effectiveSize * 0.06
    local bufferRisk = effectiveSize * 0.04
    local top = safeY + effectiveSize - margin
    local bottom = safeY + margin
    local approachingTop = top - bufferApproach
    local atRiskTop = top - bufferRisk
    local approachingBottom = bottom + bufferApproach
    local atRiskBottom = bottom + bufferRisk

    if indicatorY < approachingBottom or indicatorY > approachingTop then
        if indicatorY < atRiskBottom or indicatorY > atRiskTop then
            if indicatorY < bottom or indicatorY > top then
                return "out"
            end
            return "atRisk"
        end
        return "approaching"
    else
        return "safe"
    end
end

local function ensureIndicatorControl()
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not autoIndicatorEnabled then return end
        
        local state = getIndicatorState()
        if state == "approaching" or state == "atRisk" then
            startHolding()
        elseif state == "safe" then
            stopHolding()
        elseif state == "out" then
            startHolding()
        end
    end)
end

local function onCharacterAdded(char)
    character = char
    if autoFishing then
        task.wait(1)
        equipRod()
    end
end

-- Conexão de eventos
player.CharacterAdded:Connect(onCharacterAdded)

-- Função applyHoverEffect original mantida
local function applyHoverEffect(button)
    local originalColor = button.BackgroundColor3
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = originalColor:Lerp(Color3.new(1, 0.3, 0.3), 0.1)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = originalColor
        }):Play()
    end)
end

-- Função updateFishingButtonState original mantida
local function updateFishingButtonState(btn, active)
    local color = active and Color3.fromRGB(220, 60, 60) or COLORS.buttonPrimary
    TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = color}):Play()
end
