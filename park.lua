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
    lastCast = 0,
    isCasting = false,     -- FIX: evita cast duplo (race condition)
}

local function getValidate()
    return player.UserId * game.PlaceVersion * 6 / 2
end

-- ================================================================
-- SOLVER (lógica correta baseada no cliente original)
-- ================================================================
local function solveMinigame()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then return end

    -- FIX: WaitForChild com timeout em vez de assumir que já está visível
    local catchingBar = fishingUI:WaitForChild("CatchingBar", 5)
    if not catchingBar or not catchingBar.Visible then
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        return
    end

    local bar      = catchingBar.Frame.Bar.Catch.Green
    local fishIcon = catchingBar.Frame.Bar.Catch.Marker
    local progressFill = catchingBar.Frame.Progress.Catch.Bar

    -- FIX: barSize lido UMA vez (igual ao cliente original: bar.Size.Y.Scale)
    local barSize = bar.Size.Y.Scale

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not config.enabled or not catchingBar.Visible then
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            connection:Disconnect()
            return
        end

        local barY      = bar.Position.Y.Scale
        local fishY     = fishIcon.Position.Y.Scale

        -- FIX: progressY lido via Size (como o servidor define), não Position
        -- No cliente original: progressFill começa em Position.Y = 0.9 e vai a 0
        -- A leitura correta do "quão cheio está" é 1 - progressFill.Position.Y.Scale
        local progressY = progressFill.Position.Y.Scale -- 0 = cheio (ganhou), 1 = vazio (perdeu)

        -- FIX: lógica de colisão correta (igual ao startBattle do cliente original)
        -- fishY >= barY AND fishY <= barY + barSize → peixe DENTRO da barra
        local fishInBar = fishY >= barY and fishY <= (barY + barSize)

        if fishInBar then
            -- Peixe dentro da barra: segura o clique para subir a barra com o peixe
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        else
            -- Peixe fora: solta para deixar a barra cair em direção ao peixe
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end

        -- Partida acabou (progressY chegou a 0 ou 1): o gameLoop do cliente já chama endFishing
        -- Só precisamos desconectar nosso heartbeat quando a UI some
    end)
end

-- ================================================================
-- HANDLER DE STRIKE com retry loop (sem return cego)
-- ================================================================
local function handleStrike()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then return end

    -- FIX: loop de retry em vez de return cego quando ainda não deu 40s
    while config.enabled do
        local state = player:GetAttribute("fishingState")
        if state ~= "waiting" then return end -- saiu do estado certo

        local timeSinceCast = os.clock() - config.lastCast

        if timeSinceCast >= 40.2 then
            break -- pronto para chamar startBattle
        end

        -- Espera o tempo restante em pequenos incrementos
        task.wait(0.25)
    end

    if not config.enabled then return end

    -- Verifica novamente se ainda está em "waiting" após a espera
    if player:GetAttribute("fishingState") ~= "waiting" then return end

    events:Fire("Fish", {
        fishingAction = "startBattle",
        validateFishing = getValidate()
    })

    -- FIX: solveMinigame espera a UI abrir em vez de task.wait(0.5) fixo
    task.spawn(solveMinigame)
end

-- ================================================================
-- LOOP PRINCIPAL com debounce de cast correto
-- ================================================================
task.spawn(function()
    while true do
        task.wait(0.25) -- FIX: 0.25s em vez de 1s, evita perder janela de estado

        if not config.enabled then continue end

        local state  = player:GetAttribute("fishingState")
        local hasBuoy = workspace.Temp:FindFirstChild(player.UserId .. ".buoy")

        -- Estado: sem bóia e sem estado → hora de lançar
        if not state and not hasBuoy and not config.isCasting then
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end

            -- FIX: flag isCasting evita disparar createBuoy duas vezes
            config.isCasting = true
            config.lastCast = os.clock()

            local destiny = (char.HumanoidRootPart.CFrame * CFrame.new(0, -3, -25)).Position

            events:Fire("Fish", {
                fishingAction = "createBuoy",
                destiny = destiny,
                validateFishing = getValidate()
            })

            -- Limpa a flag após 3s (tempo suficiente para o servidor confirmar)
            task.delay(3, function()
                config.isCasting = false
            end)

        -- Estado: servidor confirmou a bóia, aguardando mordida
        elseif state == "waiting" then
            -- Só trata a mordida se a UI de strike estiver visível
            local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
            if fishingUI and fishingUI.BuoyFrame.StrikePrompt.Visible then
                task.spawn(handleStrike)
                -- Espera sair do estado "waiting" para não spammar handleStrike
                while config.enabled and player:GetAttribute("fishingState") == "waiting" do
                    task.wait(0.25)
                end
            end
        end
    end
end)

-- ================================================================
-- INTERFACE
-- ================================================================
local tab = ui:Tab("Safe Farm")
local sec = tab:Section("Configurações Anti-Ban")

sec:Toggle("Ativar Auto-Fish v5", false, function(v)
    config.enabled = v
    config.isCasting = false
    if not v then
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end)

sec:Label("Espera 40s por peixe — sincronizado com o servidor.")
sec:Label("Lança novamente automaticamente após cada captura.")
