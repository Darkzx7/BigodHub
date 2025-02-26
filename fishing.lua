-- Variáveis principais
local autoFishingEnabled = false
local fishingCooldown = 60 -- Tempo estimado para o peixe fisgar após jogar a vara

-- Equipar a vara automaticamente
local function equipRod()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character or player.CharacterAdded:Wait()

    local rod = backpack and backpack:FindFirstChild("Fishing Rod")
    if rod then
        rod.Parent = character
        print("Vara equipada.")
    else
        print("Vara não encontrada no inventário.")
    end
end

-- Jogar a vara na água
local function throwRod()
    local character = game.Players.LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        local rod = character:FindFirstChild("Fishing Rod")
        if rod then
            rod:Activate() -- Simula o uso da ferramenta
            print("Vara jogada na água.")
        else
            print("Fishing Rod não equipada.")
        end
    else
        print("Humanoid não encontrado.")
    end
end

-- Automação completa para pesca
local function startFishingAutomation()
    while autoFishingEnabled do
        equipRod()
        wait(1) -- Pequeno intervalo para garantir o equipamento
        throwRod()
        print("Aguardando peixe fisgar...")
        wait(fishingCooldown) -- Tempo estimado para o peixe fisgar (60 segundos)
        wait(3) -- Tempo para captura final do peixe
    end
end

-- Criar GUI com botão principal
local function createFishingGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FishingGUI"
    gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.3, 0, 0.2, 0)
    frame.Position = UDim2.new(0.35, 0, 0.4, 0)
    frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "dxkzz Fishing"
    titleLabel.TextScaled = true
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0.8, 0, 0.4, 0)
    toggleButton.Position = UDim2.new(0.1, 0, 0.5, 0)
    toggleButton.Text = "Ativar Pesca Automática"
    toggleButton.TextScaled = true
    toggleButton.BackgroundColor3 = Color3.new(0, 0.6, 0)
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Parent = frame

    toggleButton.MouseButton1Click:Connect(function()
        autoFishingEnabled = not autoFishingEnabled
        if autoFishingEnabled then
            toggleButton.Text = "Desativar Pesca Automática"
            toggleButton.BackgroundColor3 = Color3.new(0.6, 0, 0)
            print("Pesca automática ativada.")
            startFishingAutomation()
        else
            toggleButton.Text = "Ativar Pesca Automática"
            toggleButton.BackgroundColor3 = Color3.new(0, 0.6, 0)
            print("Pesca automática desativada.")
        end
    end)
end

-- Executar o GUI
createFishingGUI()
