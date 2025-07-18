local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ESTILOS MODERNOS
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

-- VARIÁVEIS DE ESTADO
local autoFishing = false
local autoIndicatorEnabled = false
local minimized = false
local fishingTool = nil
local holdingClick = false
local fishCount, trashCount, diamondCount = 0, 0, 0
local status, fishIcon, trashIcon, diamondIcon
local elementsToToggle = {}
local toggleFishingFromKey
local heartbeatConnection

-- FUNÇÕES DE UI (BASE)
local function createRoundedFrame(parent, size, position, bgColor, cornerRadius)
    local frame = Instance.new("Frame", parent)
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = bgColor or COLORS.bg
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(cornerRadius or 0.2, 0)
    return frame
end

local function createTextLabel(parent, text, size, position, font, textSize, textColor)
    local label = Instance.new("TextLabel", parent)
    label.Text = text
    label.Size = size
    label.Position = position
    label.Font = font or FONTS.body
    label.TextSize = textSize or 14
    label.TextColor3 = textColor or COLORS.text
    label.BackgroundTransparency = 1
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
    Instance.new("UICorner", button).CornerRadius = UDim.new(0.15, 0)
    
    -- Efeito hover
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.accentHover}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.accent}):Play()
    end)
    return button
end
-- SEÇÃO DE PERFIL (HOME)
local function createProfileSection(parent)
    local profileFrame = createRoundedFrame(parent, UDim2.new(0.9, 0, 0, 100), 
        UDim2.new(0.05, 0, 0, 50), COLORS.bgSecondary, 0.15)
    
    -- Avatar + Nome
    local player = Players.LocalPlayer
    local avatar = Instance.new("ImageLabel", profileFrame)
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0, 10, 0.5, -25)
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=150&height=150"
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local username = createTextLabel(profileFrame, player.Name, UDim2.new(0, 200, 0, 20), 
        UDim2.new(0, 70, 0.3, 0), FONTS.header, 16, COLORS.text)
    
    -- Status do Servidor
    local serverInfo = createTextLabel(profileFrame, "🔹 "..#Players:GetPlayers().."/"..game.PrivateServerMaxPlayers.." jogadores", 
        UDim2.new(0, 200, 0, 16), UDim2.new(0, 70, 0.6, 0), FONTS.body, 12, COLORS.textSecondary)
    
    table.insert(elementsToToggle, profileFrame)
    return profileFrame
end

-- ATUALIZAR STATUS DO SERVIDOR (OPCIONAL)
local function updateServerInfo()
    while task.wait(10) do
        local playersText = "🔹 "..#Players:GetPlayers().."/"..game.PrivateServerMaxPlayers.." jogadores"
        if profileFrame and profileFrame:FindFirstChild("TextLabel") then
            profileFrame.TextLabel.Text = playersText
        end
    end
end

-- CONTADORES DE LOOT (FISH/TRASH/DIAMOND)
local function createLootCounters(parent)
    local lootFrame = createRoundedFrame(parent, UDim2.new(0.9, 0, 0, 50), 
        UDim2.new(0.05, 0, 0, 160), COLORS.bgSecondary, 0.15)
    
    -- Ícones
    fishIcon = createTextLabel(lootFrame, "🐟 0", UDim2.new(0.3, 0, 1, 0), UDim2.new(0, 0, 0, 0), FONTS.body, 18, COLORS.text)
    trashIcon = createTextLabel(lootFrame, "🗑️ 0", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.34, 0, 0, 0), FONTS.body, 18, COLORS.text)
    diamondIcon = createTextLabel(lootFrame, "💎 0", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.67, 0, 0, 0), FONTS.body, 18, COLORS.text)
    
    table.insert(elementsToToggle, lootFrame)
    return lootFrame
end

-- BOTÕES PRINCIPAIS (PESCA/INDICADOR)
local function createActionButtons(parent)
    local btnFishing = createButton(parent, "ATIVAR PESCA", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.05, 0, 0, 220))
    local btnIndicator = createButton(parent, "INDICADOR AUTO", UDim2.new(0.9, 0, 0, 40), UDim2.new(0.05, 0, 0, 270))
    
    -- Conectar funções existentes
    btnFishing.MouseButton1Click:Connect(function()
        toggleFishingFromKey(btnFishing)
    end)
    
    btnIndicator.MouseButton1Click:Connect(function()
        autoIndicatorEnabled = not autoIndicatorEnabled
        btnIndicator.Text = autoIndicatorEnabled and "DESATIVAR INDICADOR" or "INDICADOR AUTO"
        if autoIndicatorEnabled then
            ensureIndicatorControl()
        else
            stopHolding()
        end
    end)
    
    table.insert(elementsToToggle, btnFishing)
    table.insert(elementsToToggle, btnIndicator)
end

-- FUNÇÃO PRINCIPAL PARA CRIAR UI
local function createModernUI()
    local gui = Instance.new("ScreenGui", player.PlayerGui)
    gui.Name = "BigodeFishingUI"
    
    local mainFrame = createRoundedFrame(gui, UDim2.new(0, 300, 0, 400), 
        UDim2.new(1, -320, 0.5, -200), COLORS.bg)
    
    -- Adicionar seções
    createProfileSection(mainFrame)
    createLootCounters(mainFrame)
    createActionButtons(mainFrame)
    
    -- Iniciar atualização de status
    spawn(updateServerInfo)
    return gui
end
