-- Variáveis principais
local safeArea
local indicator
local fishing

-- Controle da automação
local autoIndicatorEnabled = false

-- Função para aguardar a criação do fishing no Workspace
local function waitForFishing()
    while not game.Workspace:FindFirstChild("fishing") do
        wait(0.1)
    end
    fishing = game.Workspace.fishing
    safeArea = fishing.bar.safeArea
    indicator = fishing.bar.indicator
end

-- Função para verificar a posição do indicador com mais precisão
local function getIndicatorState()
    if not safeArea or not indicator then return "missing" end

    local safeAreaPos = safeArea.Position.Y.Scale
    local safeAreaSize = safeArea.Size.Y.Scale
    local minSafeAreaSize = 0.05 -- Definir um tamanho mínimo razoável para evitar erros
    local effectiveSafeAreaSize = math.max(safeAreaSize, minSafeAreaSize)
    local margin = math.max(effectiveSafeAreaSize * 0.1, 0.015) -- Ajuste mais fino

    local upperBound = safeAreaPos + effectiveSafeAreaSize - margin
    local lowerBound = safeAreaPos + margin
    local indicatorPos = indicator.Position.Y.Scale

    if indicatorPos < lowerBound then
        return "above"
    elseif indicatorPos > upperBound then
        return "below"
    elseif indicatorPos >= lowerBound and indicatorPos <= upperBound then
        return "center"
    else
        return "out_of_bounds"
    end
end

-- Função para simular cliques mais precisos
local function clickToAdjustIndicator(holdTime)
    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, nil, 0)
    wait(holdTime)
    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, nil, 0)
end

-- Função para garantir que o indicador nunca saia da safeArea
local function ensureIndicatorStaysInSafeArea()
    while autoIndicatorEnabled do
        if not game.Workspace:FindFirstChild("fishing") then
            waitForFishing()
        end

        if not safeArea or not indicator then
            waitForFishing()
        end

        local indicatorState = getIndicatorState()
        local holdTime = 0.007 -- Ajuste fino para precisão

        if indicatorState == "above" then
            clickToAdjustIndicator(holdTime)
            wait(0.008)

        elseif indicatorState == "below" then
            clickToAdjustIndicator(holdTime)
            wait(0.008)

        elseif indicatorState == "out_of_bounds" then
            clickToAdjustIndicator(0.025) -- Correção mais rápida para evitar travamento
            wait(0.03)

        else
            wait(0.03) -- Pequena espera para evitar instabilidades
        end
    end
end

-- Função para criar a GUI funcional
local function createIndicatorGUI()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Evitar duplicação de GUI
    if playerGui:FindFirstChild("IndicatorGUI") then return end

    -- Criar GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "IndicatorGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(0.9, -200, 0.1, 0) -- Posicionado no canto superior direito
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel")
    title.Text = "Indicador Automático"
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Text = "Ativar"
    toggleButton.Size = UDim2.new(0.8, 0, 0.6, 0)
    toggleButton.Position = UDim2.new(0.1, 0, 0.4, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 14
    toggleButton.Parent = frame

    -- Alternar automação do indicador
    toggleButton.MouseButton1Click:Connect(function()
        autoIndicatorEnabled = not autoIndicatorEnabled
        toggleButton.Text = autoIndicatorEnabled and "Desativar" or "Ativar"
        if autoIndicatorEnabled then
            spawn(function()
                ensureIndicatorStaysInSafeArea()
            end)
        end
    end)
end

-- Criar GUI ao iniciar o script
createIndicatorGUI()
