-- ================================================================
-- CARREGA A REFLIB
-- ================================================================
local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
local ui = RefLib.new("AutoFish v2", "rbxassetid://131165537896572", "autofish_config")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- Carrega os módulos reais do jogo
local events = require(ReplicatedStorage.Shared.Modules.events)

-- Configurações
local config = {
    enabled = false,
    autoReel = true,
    fishCaught = 0,
    castDelay = 2
}

local activeBattle = false
local lastCastTime = 0

-- Função para validar a pesca (Obrigatória para não ser Kickado)
local function getValidate()
    return player.UserId * game.PlaceVersion * 6 / 2
end

-- ================================================================
-- LÓGICA DE LANÇAMENTO
-- ================================================================

local function getRod()
    return (player.Character and player.Character:FindFirstChild("Fishing Rod")) or (player.Backpack:FindFirstChild("Fishing Rod"))
end

local function castRod()
    local rod = getRod()
    if not rod or not player.Character then return false end
    
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- Calcula posição na frente do player e faz raycast pra água
    local castPos = (root.CFrame * CFrame.new(0, 0, -25)).Position
    
    events:Fire("Fish", {
        fishingAction = "createBuoy",
        destiny = castPos,
        validateFishing = getValidate()
    })
    return true
end

-- ================================================================
-- MINIGAME SOLVER (A MÁGICA)
-- ================================================================

local function solveMinigame()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI or not fishingUI.CatchingBar.Visible then return end

    local bar = fishingUI.CatchingBar.Frame.Bar.Catch.Green
    local fish = fishingUI.CatchingBar.Frame.Bar.Catch.Marker
    
    -- Loop de RenderStepped para precisão máxima
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not config.enabled or not fishingUI.CatchingBar.Visible then
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1) -- Solta o clique
            connection:Disconnect()
            activeBattle = false
            return
        end

        local barY = bar.Position.Y.Scale
        local barSize = bar.Size.Y.Scale
        local fishY = fish.Position.Y.Scale

        -- Se o peixe estiver ABAIXO da barra (Y maior), precisamos subir (Segurar Clique)
        -- Nota: No Roblox UI, 0 é topo, 1 é fundo.
        if fishY > (barY + (barSize / 2)) then
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1) -- Segura
        else
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1) -- Solta
        end
    end)
end

-- ================================================================
-- MONITORAMENTO DA UI
-- ================================================================

local function setupListeners()
    local fishingUI = player.PlayerGui:WaitForChild("FishingUI")
    
    -- 1. Detectar quando o peixe morde (StrikePrompt)
    fishingUI.BuoyFrame.StrikePrompt:GetPropertyChangedSignal("Visible"):Connect(function()
        if config.enabled and config.autoReel and fishingUI.BuoyFrame.StrikePrompt.Visible then
            task.wait(0.1)
            events:Fire("Fish", {fishingAction = "startBattle", validateFishing = getValidate()})
        end
    end)

    -- 2. Detectar início da barra de batalha
    fishingUI.CatchingBar:GetPropertyChangedSignal("Visible"):Connect(function()
        if config.enabled and fishingUI.CatchingBar.Visible then
            activeBattle = true
            solveMinigame()
        end
    end)
end

-- ================================================================
-- LOOP PRINCIPAL
-- ================================================================

task.spawn(function()
    setupListeners()
    while true do
        if config.enabled then
            local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
            local isFishing = fishingUI and (fishingUI.BuoyFrame.Visible or fishingUI.CatchingBar.Visible)

            if not isFishing and (os.clock() - lastCastTime) > config.castDelay then
                if castRod() then
                    lastCastTime = os.clock()
                end
            end
        end
        task.wait(1)
    end
end)

-- ================================================================
-- INTERFACE
-- ================================================================

local tab = ui:Tab("Principal")
local farm = tab:Section("Auto Farm")

farm:Toggle("Ativar Auto Fish", false, function(v)
    config.enabled = v
    if not v then
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end)

farm:Slider("Delay entre pescas", 1, 5, 2, function(v)
    config.castDelay = v
end)

farm:Button("Vender Peixes", function()
    events:Fire("sellFish")
end)

ui:Toast("rbxassetid://131165537896572", "AutoFish", "Script Carregado com Sucesso!")
