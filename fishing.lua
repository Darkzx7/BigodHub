-- Variáveis principais
local safeArea = game.Workspace.fishing.bar.safeArea
local indicator = game.Workspace.fishing.bar.indicator

-- Controle da automação
local autoFishingEnabled = false

-- Função para equipar a vara de pesca
local function equipRod()
    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    local character = player.Character or player.CharacterAdded:Wait()

    local rod = backpack:FindFirstChild("Fishing Rod")
    if rod then
        rod.Parent = character
        print("Fishing Rod equipada")
    else
        print("Fishing Rod não encontrada no inventário")
    end
end

-- Função para jogar a vara na água
local function throwRod()
    local character = game.Players.LocalPlayer.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        local rod = character:FindFirstChild("Fishing Rod")
        if rod then
            rod:Activate() -- Simula o uso da ferramenta
            print("Vara jogada na água")
        else
            print("Fishing Rod não equipada")
        end
    else
        print("Humanoid não encontrado")
    end
end

-- Função principal para automação de equipar e jogar
local function autoEquipAndThrow()
    if not autoFishingEnabled then return end

    -- Equipar e jogar a vara de pesca de forma rápida e direta
    equipRod()
    throwRod()
    wait(60) -- Aguardar até a barrinha aparecer
end

-- Função para criar GUI funcional
local function createFishingGUI()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Evitar duplicação de GUI
    if playerGui:FindFirstChild("FishingGUI") then return end

    -- Criar GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishingGUI"
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
    title.Text = "Pesca Automática"
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

    -- Alternar automação da pesca
    toggleButton.MouseButton1Click:Connect(function()
        autoFishingEnabled = not autoFishingEnabled
        toggleButton.Text = autoFishingEnabled and "Desativar" or "Ativar"
        if autoFishingEnabled then
            spawn(function()
                while autoFishingEnabled do
                    autoEquipAndThrow()
                end
            end)
        end
    end)
end

-- Criar GUI ao iniciar o script
createFishingGUI()
