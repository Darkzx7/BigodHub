local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
local ui = RefLib.new("AutoFish Ultra", "rbxassetid://131165537896572", "af_ultra_safe")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local events = require(ReplicatedStorage.Shared.Modules.events)

local config = {
    enabled = false,
    minWaitToBattle = 40.5, -- O floatDebounce do seu servidor é 40.
    lastCast = 0
}

local function getValidate()
    return player.UserId * game.PlaceVersion * 6 / 2
end

-- ================================================================
-- SOLVER COM CONTROLE DE SEGURANÇA (BRAIN MODULE)
-- ================================================================
local function solveMinigame()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then return end
    
    local catchingBar = fishingUI:WaitForChild("CatchingBar")
    local bar = catchingBar.Frame.Bar.Catch.Green
    local fish = catchingBar.Frame.Bar.Catch.Marker
    local progressFill = catchingBar.Frame.Progress.Catch.Bar
    
    local battleStartTime = os.clock()

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
        local progress = progressFill.Position.Y.Scale -- 0 é cheio, 1 é vazio
        
        local elapsed = os.clock() - battleStartTime

        -- CONTROLE DE SEGURANÇA: Se o progresso estiver quase no fim (perto de 0)
        -- Mas ainda não deu os 41 segundos de luta, nós flutuamos fora do peixe.
        if elapsed < config.minWaitToBattle and progress < 0.15 then
            -- Força erro proposital para segurar o tempo
            if barY < 0.5 then
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            else
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            end
            return
        end

        -- LÓGICA DE MANUTENÇÃO (Tenta manter o peixe no topo da barra verde)
        if barY + (barSize * 0.2) > fishY then
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        else
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        end
    end)
end

-- ================================================================
-- HANDLER DE EVENTOS (SYNC COM O SERVIDOR)
-- ================================================================

-- Detecta a mordida e respeita o tempo de espera do servidor
local function handleStrike()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI or not fishingUI.BuoyFrame.StrikePrompt.Visible then return end
    
    local timeSinceCast = os.clock() - config.lastCast
    
    -- O servidor dá kick se startBattle for chamado antes de 40s do cast (Linha 188 do seu código)
    if timeSinceCast < 40.2 then
        return -- Espera o tempo mínimo antes de puxar
    end
    
    events:Fire("Fish", {
        fishingAction = "startBattle",
        validateFishing = getValidate()
    })
    
    task.wait(0.5)
    solveMinigame()
end

-- Loop de Lançamento (Só joga se estiver "limpo" no servidor)
task.spawn(function()
    while true do
        if config.enabled then
            local state = player:GetAttribute("fishingState")
            local hasBuoy = workspace.Temp:FindFirstChild(player.UserId .. ".buoy")
            
            if not state and not hasBuoy then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    config.lastCast = os.clock()
                    local destiny = (char.HumanoidRootPart.CFrame * CFrame.new(0, -3, -25)).Position
                    
                    events:Fire("Fish", {
                        fishingAction = "createBuoy",
                        destiny = destiny,
                        validateFishing = getValidate()
                    })
                end
            elseif state == "waiting" then
                handleStrike()
            end
        end
        task.wait(1)
    end
end)

-- ================================================================
-- INTERFACE
-- ================================================================
local tab = ui:Tab("Safe Farm")
local sec = tab:Section("Configurações Anti-Ban")

sec:Toggle("Ativar Auto-Fish v5", false, function(v)
    config.enabled = v
    if not v then VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1) end
end)

sec:Label("DICA: Este script é LENTO por segurança.")
sec:Label("Ele espera 40s por peixe para evitar o kick.")
