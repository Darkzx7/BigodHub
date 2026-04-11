local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
local ui = RefLib.new("AutoFish V4", "rbxassetid://131165537896572", "af_v4_final")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local events = require(ReplicatedStorage.Shared.Modules.events)

local config = {
    enabled = false,
    castDelay = 4,
    minGameTime = 42 -- O servidor exige pelo menos 40s para não dar kick
}

local function getValidate()
    return player.UserId * game.PlaceVersion * 6 / 2
end

-- ================================================================
-- SOLVER COM CONTROLE DE INÉRCIA (Para a barra não passar direto)
-- ================================================================
local function solveMinigame()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then return end
    
    local catchingBar = fishingUI:WaitForChild("CatchingBar")
    local bar = catchingBar.Frame.Bar.Catch.Green
    local fish = catchingBar.Frame.Bar.Catch.Marker
    local startTime = os.clock()

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not config.enabled or not catchingBar.Visible then
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            connection:Disconnect()
            return
        end

        local barY = bar.Position.Y.Scale
        local fishY = fish.Position.Y.Scale
        local barSize = bar.Size.Y.Scale
        local targetY = fishY - (barSize / 2)

        -- SISTEMA ANTI-KICK: Se estiver quase ganhando muito rápido, 
        -- o script "erra" de propósito para enrolar o tempo até dar 41 segundos.
        local elapsed = os.clock() - startTime
        if elapsed < config.minGameTime then
            -- Se o progresso estiver muito alto (barra quase no topo), 
            -- nós forçamos a barra a sair de cima do peixe pra não terminar antes de 40s
            local progress = catchingBar.Frame.Progress.Catch.Bar.Position.Y.Scale
            if progress < 0.2 then 
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                return 
            end
        end

        -- Controle suave: Se a barra estiver abaixo do peixe, sobe (segura)
        if barY > targetY then
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        else
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end)
end

-- ================================================================
-- LANÇAMENTO COM CHECAGEM DE ESTADO REAL
-- ================================================================
local function castRod()
    -- Checa se já existe uma boia no Workspace ou se o atributo está ativo
    local hasBuoy = workspace.Temp:FindFirstChild(player.UserId .. ".buoy")
    if hasBuoy or player:GetAttribute("fishingState") ~= nil then return end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- Joga a vara exatamente onde o jogo espera
    local root = char.HumanoidRootPart
    local destiny = (root.CFrame * CFrame.new(0, -2, -25)).Position
    
    events:Fire("Fish", {
        fishingAction = "createBuoy",
        destiny = destiny,
        validateFishing = getValidate()
    })
end

-- Monitoramento de Mordida
task.spawn(function()
    while true do
        if config.enabled then
            local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
            if fishingUI and fishingUI.BuoyFrame.StrikePrompt.Visible then
                task.wait(0.5) -- Delay humano para morder
                events:Fire("Fish", {fishingAction = "startBattle", validateFishing = getValidate()})
            end
        end
        task.wait(0.5)
    end
end)

-- Loop Principal
task.spawn(function()
    while true do
        if config.enabled then
            local state = player:GetAttribute("fishingState")
            if not state then
                castRod()
            elseif state == "battle" then
                -- O solver já é chamado pelo sinal ou loop de UI
                if not activeBattle then
                    activeBattle = true
                    solveMinigame()
                    repeat task.wait(1) until player:GetAttribute("fishingState") == nil
                    activeBattle = false
                end
            end
        end
        task.wait(1.5)
    end
end)

-- ================================================================
-- MENU
-- ================================================================
local tab = ui:Tab("Main")
local sec = tab:Section("Fisga Automática")

sec:Toggle("Ligar AutoFish", false, function(v)
    config.enabled = v
    if not v then VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1) end
end)

sec:Label("Aviso: O script enrola a luta para")
sec:Label("evitar o Kick de 40 segundos.")
