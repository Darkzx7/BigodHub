-- ================================================================
-- CARREGA A REFLIB (seu loader)
-- ================================================================
local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
if not RefLib then error("RefLib nao carregou") end

-- ================================================================
-- CRIA O MENU
-- ================================================================
local ui = RefLib.new("AutoFish", "rbxassetid://131165537896572", "autofish_v1")

-- ================================================================
-- AUTOFISH - SISTEMA COMPLETO
-- ================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- Tenta carregar os eventos do jogo
local events = nil
pcall(function()
    events = require(ReplicatedStorage.Shared.Modules.events)
end)

-- Configurações
local config = {
    enabled = false,
    autoReel = true,
    perfectCatch = true,
    autoSell = false,
    castDelay = 3,
    fishCaught = 0
}

-- Variáveis de controle
local lastCastTime = 0
local isInBattle = false
local holding = false

-- ================================================================
-- FUNÇÕES PRINCIPAIS
-- ================================================================

local function getFishingRod()
    local char = player.Character
    if char then
        local rod = char:FindFirstChild("Fishing Rod")
        if rod then return rod end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        local rod = bp:FindFirstChild("Fishing Rod")
        if rod then return rod end
    end
    return nil
end

local function castRod()
    local rod = getFishingRod()
    if rod then
        rod:Activate()
        return true
    end
    return false
end

local function pullFish()
    VirtualInput:SendMouseButtonEvent(0, 0, 0, true, "Left", 1)
    task.wait(0.05)
    VirtualInput:SendMouseButtonEvent(0, 0, 0, false, "Left", 1)
end

local function holdPull()
    if not holding then
        holding = true
        VirtualInput:SendMouseButtonEvent(0, 0, 0, true, "Left", 1)
    end
end

local function releasePull()
    if holding then
        holding = false
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, "Left", 1)
    end
end

local function sellAllFish()
    if events then
        events:Fire("sellFish")
        ui:Toast("rbxassetid://131165537896572", "💰 Venda", "Peixes vendidos!", Color3.fromRGB(255, 200, 100))
    end
end

-- ================================================================
-- MONITORAMENTO DA UI DO JOGO
-- ================================================================

local function setupListeners()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then return end
    
    -- Monitora o StrikePrompt (peixe mordeu)
    local buoyFrame = fishingUI:FindFirstChild("BuoyFrame")
    if buoyFrame then
        local strikePrompt = buoyFrame:FindFirstChild("StrikePrompt")
        if strikePrompt then
            strikePrompt:GetPropertyChangedSignal("Visible"):Connect(function()
                if config.enabled and strikePrompt.Visible and config.autoReel then
                    task.wait(0.1)
                    pullFish()
                end
            end)
        end
    end
    
    -- Monitora a batalha (CatchingBar)
    local catchingBar = fishingUI:FindFirstChild("CatchingBar")
    if catchingBar then
        catchingBar:GetPropertyChangedSignal("Visible"):Connect(function()
            if config.enabled and catchingBar.Visible then
                isInBattle = true
                
                -- Loop da batalha
                local battleLoop = RunService.RenderStepped:Connect(function()
                    if not config.enabled or not isInBattle then
                        battleLoop:Disconnect()
                        releasePull()
                        return
                    end
                    
                    if not catchingBar.Visible then
                        isInBattle = false
                        config.fishCaught = config.fishCaught + 1
                        releasePull()
                        battleLoop:Disconnect()
                        return
                    end
                    
                    -- Pega os elementos da UI
                    local catchFrame = catchingBar:FindFirstChild("Frame")
                    if catchFrame then
                        local catchContainer = catchFrame:FindFirstChild("Bar")
                        if catchContainer then
                            local greenBar = catchContainer:FindFirstChild("Green")
                            local marker = catchContainer:FindFirstChild("Marker")
                            
                            if greenBar and marker then
                                local barY = greenBar.Position.Y.Scale
                                local fishY = marker.Position.Y.Scale
                                local barSize = greenBar.Size.Y.Scale
                                
                                local isFishInBar = fishY >= barY and fishY <= (barY + barSize)
                                
                                if config.perfectCatch then
                                    local centerY = barY + (barSize / 2)
                                    local offset = fishY - centerY
                                    
                                    if offset > 0.05 then
                                        releasePull()
                                    elseif offset < -0.05 then
                                        holdPull()
                                    elseif isFishInBar then
                                        holdPull()
                                    else
                                        releasePull()
                                    end
                                else
                                    if isFishInBar then
                                        holdPull()
                                    else
                                        releasePull()
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end
end

-- ================================================================
-- LOOP PRINCIPAL
-- ================================================================

local function mainLoop()
    while config.enabled do
        local elapsed = os.clock() - lastCastTime
        if elapsed < config.castDelay then
            task.wait(config.castDelay - elapsed)
        end
        
        if not config.enabled then break end
        
        local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
        local isFishing = fishingUI and fishingUI:FindFirstChild("BuoyFrame") and fishingUI.BuoyFrame.Visible
        
        if not isFishing and not isInBattle then
            if getFishingRod() then
                castRod()
                lastCastTime = os.clock()
            end
        end
        
        task.wait(0.5)
    end
end

local function autoSellLoop()
    while config.enabled and config.autoSell do
        task.wait(60)
        if config.enabled and config.autoSell then
            sellAllFish()
        end
    end
end

-- ================================================================
-- CONTROLE PRINCIPAL
-- ================================================================

local function startAutoFish()
    if config.enabled then return end
    config.enabled = true
    config.fishCaught = 0
    setupListeners()
    task.spawn(mainLoop)
    if config.autoSell then
        task.spawn(autoSellLoop)
    end
    ui:Toast("rbxassetid://131165537896572", "🎣 AutoFish", "Ativado!", Color3.fromRGB(100, 200, 255))
end

local function stopAutoFish()
    config.enabled = false
    isInBattle = false
    releasePull()
    ui:Toast("rbxassetid://131165537896572", "🎣 AutoFish", "Desativado", Color3.fromRGB(200, 100, 100))
end

-- ================================================================
-- CONSTRUÇÃO DO MENU
-- ================================================================

local tabFarm = ui:Tab("farm")
local secFish = tabFarm:Section("auto fish")

-- Toggle principal
local t_main = secFish:Toggle("auto fish", false, function(v)
    if v then startAutoFish() else stopAutoFish() end
end)

-- Configurações
local t_reel = secFish:Toggle("auto reel", true, function(v)
    config.autoReel = v
end)

local t_perfect = secFish:Toggle("perfect catch", true, function(v)
    config.perfectCatch = v
end)

local t_autosell = secFish:Toggle("auto sell (60s)", false, function(v)
    config.autoSell = v
    if config.enabled and v then
        task.spawn(autoSellLoop)
    end
end)

local s_delay = secFish:Slider("delay entre pescas (s)", 1, 10, 3, function(v)
    config.castDelay = v
end)

secFish:Button("vender agora", function()
    sellAllFish()
end)

-- Status em tempo real
local statusLabel = secFish:Label("Status: ⚪ Parado")

task.spawn(function()
    while true do
        if config.enabled then
            statusLabel.Set(string.format("Status: 🟢 Ativo | Peixes: %d", config.fishCaught))
        else
            statusLabel.Set(string.format("Status: ⚪ Parado | Total: %d", config.fishCaught))
        end
        task.wait(1)
    end
end)

-- ================================================================
-- SALVAR CONFIGURAÇÕES (opcional)
-- ================================================================
ui:CfgRegister("autofish_enabled", function() return config.enabled end, function(v) t_main.Set(v) end)
ui:CfgRegister("autofish_reel", function() return config.autoReel end, function(v) t_reel.Set(v) end)
ui:CfgRegister("autofish_perfect", function() return config.perfectCatch end, function(v) t_perfect.Set(v) end)
ui:CfgRegister("autofish_sell", function() return config.autoSell end, function(v) t_autosell.Set(v) end)
ui:CfgRegister("autofish_delay", function() return config.castDelay end, function(v) s_delay.Set(v) end)

print("[AutoFish] Carregado! Abra o menu na aba 'farm'")
