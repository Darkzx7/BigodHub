local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
local ui = RefLib.new("AutoFish Ultra", "rbxassetid://131165537896572", "af_ultra_safe")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local config = { enabled = false, strikeHandled = false }

local function getUI()
    local gui = player.PlayerGui:FindFirstChild("FishingUI")
    if not gui then return nil, nil, nil end
    local strikePrompt = gui:FindFirstChild("BuoyFrame") and gui.BuoyFrame:FindFirstChild("StrikePrompt")
    local catchingBar  = gui:FindFirstChild("CatchingBar")
    return gui, strikePrompt, catchingBar
end

local function simulateClick(down)
    local center = workspace.CurrentCamera.ViewportSize / 2
    VirtualInput:SendMouseButtonEvent(center.X, center.Y, 0, down, game, 1)
end

local function shouldCast()
    local state   = player:GetAttribute("fishingState")
    local hasBuoy = workspace.Temp:FindFirstChild(player.UserId .. ".buoy")
    local _, _, bar = getUI()
    return not state and not hasBuoy and not (bar and bar.Visible)
end

-- ================================================================
-- MINIGAME SOLVER
-- Mantém o fishIcon dentro do bar.Green segurando/soltando o clique.
-- Não dispara nenhum evento — só controla o MouseButton1 que o
-- UserInputService do cliente legítimo já está escutando.
-- ================================================================
local miniGameConnection = nil

local function startSolver()
    if miniGameConnection then
        miniGameConnection:Disconnect()
        miniGameConnection = nil
    end

    local _, _, catchingBar = getUI()
    if not catchingBar then return end

    local bar      = catchingBar:WaitForChild("Frame"):WaitForChild("Bar"):WaitForChild("Catch"):WaitForChild("Green")
    local fishIcon = catchingBar.Frame.Bar.Catch:WaitForChild("Marker")
    local barSize  = bar.Size.Y.Scale

    miniGameConnection = RunService.Heartbeat:Connect(function()
        local _, _, cb = getUI()

        -- Para quando o minigame fechar
        if not cb or not cb.Visible then
            simulateClick(false)
            miniGameConnection:Disconnect()
            miniGameConnection = nil
            return
        end

        local barY  = bar.Position.Y.Scale
        local fishY = fishIcon.Position.Y.Scale

        -- Peixe dentro da barra verde: segura
        -- Peixe fora: solta (barra cai em direção ao peixe pela gravidade)
        local fishInBar = fishY >= barY and fishY <= (barY + barSize)
        simulateClick(fishInBar)
    end)
end

-- ================================================================
-- LOOP PRINCIPAL
-- ================================================================
task.spawn(function()
    while true do
        task.wait(0.3)

        if not config.enabled then
            config.strikeHandled = false
            if miniGameConnection then
                miniGameConnection:Disconnect()
                miniGameConnection = nil
                simulateClick(false)
            end
            continue
        end

        local _, strikePrompt, catchingBar = getUI()

        -- PRIORIDADE 1: Minigame aberto → solver cuida
        if catchingBar and catchingBar.Visible then
            config.strikeHandled = false
            if not miniGameConnection then
                startSolver()
            end
            continue
        end

        -- PRIORIDADE 2: Strike prompt visível → clica para aceitar
        if strikePrompt and strikePrompt.Visible and not config.strikeHandled then
            config.strikeHandled = true
            simulateClick(true)
            task.wait(0.1)
            simulateClick(false)

            -- Aguarda o minigame abrir
            local waited = 0
            while waited < 3 do
                task.wait(0.1)
                waited += 0.1
                local _, _, cb = getUI()
                if cb and cb.Visible then
                    startSolver()
                    break
                end
            end
            continue
        end

        -- PRIORIDADE 3: Sem bóia → lança a vara
        if shouldCast() then
            config.strikeHandled = false
            simulateClick(true)
            task.wait(0.1)
            simulateClick(false)

            local waited = 0
            while waited < 5 do
                task.wait(0.5)
                waited += 0.5
                if player:GetAttribute("fishingState") == "waiting" then break end
            end
        end
    end
end)

-- ================================================================
-- INTERFACE
-- ================================================================
local tab = ui:Tab("Safe Farm")
local sec = tab:Section("Automação")

sec:Toggle("Ativar Auto-Fish", false, function(v)
    config.enabled = v
    if not v then
        simulateClick(false)
        if miniGameConnection then
            miniGameConnection:Disconnect()
            miniGameConnection = nil
        end
    end
end)

sec:Label("Equipe a vara uma vez e ative o script.")
sec:Label("Cast → Strike → Minigame resolvidos automaticamente.")
