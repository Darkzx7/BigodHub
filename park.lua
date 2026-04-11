local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
local ui = RefLib.new("AutoFish Final", "rbxassetid://131165537896572", "af_fix_v3")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local events = require(ReplicatedStorage.Shared.Modules.events)

local config = {
    enabled = false,
    autoReel = true,
    castDelay = 3, -- Aumentado para evitar spam
}

-- Impede o spam verificando o atributo real do jogo
local function isFishing()
    return player:GetAttribute("fishingState") ~= nil 
end

local function getValidate()
    return player.UserId * game.PlaceVersion * 6 / 2
end

-- ================================================================
-- SOLVER DE MINIGAME (LÓGICA DE PULSO)
-- ================================================================
local function solveMinigame()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then return end
    
    local catchingBar = fishingUI:WaitForChild("CatchingBar", 2)
    local bar = catchingBar.Frame.Bar.Catch.Green
    local fish = catchingBar.Frame.Bar.Catch.Marker

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not config.enabled or not catchingBar.Visible then
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            connection:Disconnect()
            return
        end

        local barY = bar.Position.Y.Scale
        local barSize = bar.Size.Y.Scale
        local fishY = fish.Position.Y.Scale
        
        -- Centro da barra verde
        local barCenter = barY + (barSize / 2)

        -- Se o peixe estiver ACIMA do centro (Y menor), solta. 
        -- Se estiver ABAIXO (Y maior), clica/segura.
        if fishY > barCenter then
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        else
            -- Pequeno delay ou "tap" para não cair rápido demais
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end)
end

-- ================================================================
-- LANÇAMENTO E LISTENERS
-- ================================================================

local function castRod()
    if isFishing() then return end -- TRAVA ANTI-SPAM
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local destiny = (char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -20)).Position
    
    events:Fire("Fish", {
        fishingAction = "createBuoy",
        destiny = destiny,
        validateFishing = getValidate()
    })
end

-- Monitoramento via Attributes (Mais seguro que UI)
player:GetAttributeChangedSignal("fishingState"):Connect(function()
    local state = player:GetAttribute("fishingState")
    
    if config.enabled then
        if state == "waiting" then
            -- Peixe mordeu? O jogo muda o estado ou a UI do StrikePrompt aparece
        elseif state == "battle" then
            task.wait(0.1)
            solveMinigame()
        end
    end
end)

-- Listener específico para o "Strike" (Mordida)
task.spawn(function()
    local fishingUI = player.PlayerGui:WaitForChild("FishingUI")
    fishingUI.BuoyFrame.StrikePrompt:GetPropertyChangedSignal("Visible"):Connect(function()
        if config.enabled and fishingUI.BuoyFrame.StrikePrompt.Visible then
            task.wait(0.2)
            events:Fire("Fish", {fishingAction = "startBattle", validateFishing = getValidate()})
        end
    end)
end)

-- Loop de lançamento
task.spawn(function()
    while true do
        if config.enabled and not isFishing() then
            castRod()
            task.wait(config.castDelay)
        end
        task.wait(1)
    end
end)

-- ================================================================
-- UI
-- ================================================================
local tab = ui:Tab("Farm")
local sec = tab:Section("Auto Fish")

sec:Toggle("Ativar Script", false, function(v)
    config.enabled = v
    if not v then VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1) end
end)

sec:Slider("Delay", 2, 5, 3, function(v) config.castDelay = v end)
