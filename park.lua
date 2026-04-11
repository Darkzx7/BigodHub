-- ================================================================
-- CARREGA A REFLIB
-- ================================================================
local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
if not RefLib then error("RefLib nao carregou") end

local ui = RefLib.new("AutoFish", "rbxassetid://131165537896572", "autofish_v2")

-- ================================================================
-- AUTOFISH - BASEADO NO CÓDIGO REAL DO JOGO
-- ================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Carrega os eventos do jogo
local events = require(ReplicatedStorage.Shared.Modules.events)

-- Calcula o validateFishing (igual o servidor faz)
local function getValidateFishing()
    return player.UserId * game.PlaceVersion * 6 / 2
end

-- Configurações
local config = {
    enabled = false,
    autoReel = true,
    autoSell = false,
    fishCaught = 0
}

-- Variáveis de controle
local activeBattle = false
local currentBattleLoop = nil
local lastCastTime = 0
local castDelay = 2

-- ================================================================
-- FUNÇÕES DE PESCA (USANDO OS REMOTES CORRETOS)
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
    if not rod then return false end
    
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    -- Calcula a posição de destino (à frente do personagem)
    local destiny = root.CFrame * CFrame.new(0, 0, -25)
    
    -- Raycast para encontrar a água
    local rayParams = RaycastParams.new()
    rayParams.IgnoreWater = false
    local result = workspace:Raycast(destiny.Position, Vector3.new(0, -50, 0), rayParams)
    
    if result and result.Material == Enum.Material.Water then
        destiny = CFrame.new(result.Position)
    end
    
    -- Dispara o evento createBuoy
    events:Fire("Fish", {
        fishingAction = "createBuoy",
        destiny = destiny.Position,
        validateFishing = getValidateFishing()
    })
    
    return true
end

local function startBattle()
    events:Fire("Fish", {
        fishingAction = "startBattle",
        validateFishing = getValidateFishing()
    })
end

local function finishFish()
    events:Fire("Fish", {
        fishingAction = "fish",
        validateFishing = getValidateFishing()
    })
    config.fishCaught = config.fishCaught + 1
end

local function destroyBuoy()
    events:Fire("Fish", {
        fishingAction = "destroyBuoy",
        validateFishing = getValidateFishing()
    })
end

local function sellAllFish()
    events:Fire("sellFish")
    ui:Toast("rbxassetid://131165537896572", "💰 Venda", "Peixes vendidos!", Color3.fromRGB(255, 200, 100))
end

-- ================================================================
-- SIMULA O MINIGAME DA BARRA (CLIQUE SEGURADO)
-- ================================================================

local function holdClick()
    local VirtualInput = game:GetService("VirtualInputManager")
    VirtualInput:SendMouseButtonEvent(0, 0, 0, true, "Left", 1)
end

local function releaseClick()
    local VirtualInput = game:GetService("VirtualInputManager")
    VirtualInput:SendMouseButtonEvent(0, 0, 0, false, "Left", 1)
end

-- ================================================================
-- MONITORAMENTO DA UI
-- ================================================================

local function setupUIListeners()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then return end
    
    -- Monitora o StrikePrompt (quando o peixe morde)
    local buoyFrame = fishingUI:FindFirstChild("BuoyFrame")
    if buoyFrame then
        local strikePrompt = buoyFrame:FindFirstChild("StrikePrompt")
        if strikePrompt then
            strikePrompt:GetPropertyChangedSignal("Visible"):Connect(function()
                if config.enabled and config.autoReel and strikePrompt.Visible then
                    task.wait(0.1)
                    startBattle()
                end
            end)
        end
    end
    
    -- Monitora a barra de batalha
    local catchingBar = fishingUI:FindFirstChild("CatchingBar")
    if catchingBar then
        catchingBar:GetPropertyChangedSignal("Visible"):Connect(function()
            if config.enabled and catchingBar.Visible then
                activeBattle = true
                
                -- Loop do minigame
                if currentBattleLoop then
                    pcall(function() currentBattleLoop:Disconnect() end)
                    currentBattleLoop = nil
                end
                
                currentBattleLoop = RunService.RenderStepped:Connect(function()
                    if not config.enabled or not activeBattle then
                        if currentBattleLoop then
                            pcall(function() currentBattleLoop:Disconnect() end)
                            currentBattleLoop = nil
                        end
                        releaseClick()
                        return
                    end
                    
                    -- Verifica se a batalha acabou
                    if not catchingBar.Visible then
                        activeBattle = false
                        finishFish()
                        releaseClick()
                        if currentBattleLoop then
                            pcall(function() currentBattleLoop:Disconnect() end)
                            currentBattleLoop = nil
                        end
                        return
                    end
                    
                    -- Encontra os elementos da UI
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
                                
                                -- Segura o clique quando o peixe está dentro da barra
                                local isFishInBar = fishY >= barY and fishY <= (barY + barSize)
                                
                                if isFishInBar then
                                    holdClick()
                                else
                                    releaseClick()
                                end
                            end
                        end
                    end
                end)
            else
                activeBattle = false
                releaseClick()
                if currentBattleLoop then
                    pcall(function() currentBattleLoop:Disconnect() end)
                    currentBattleLoop = nil
                end
            end
        end)
    end
end

-- ================================================================
-- LOOP PRINCIPAL
-- ================================================================

local function mainLoop()
    while config.enabled do
        -- Aguarda o delay entre lançamentos
        local elapsed = os.clock() - lastCastTime
        if elapsed < castDelay then
            task.wait(castDelay - elapsed)
        end
        
        if not config.enabled then break end
        
        -- Verifica se já está pescando
        local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
        local isFishing = fishingUI and fishingUI:FindFirstChild("BuoyFrame") and fishingUI.BuoyFrame.Visible
        
        if not isFishing and not activeBattle then
            local success = castRod()
            if success then
                lastCastTime = os.clock()
            end
        end
        
        task.wait(0.5)
    end
end

-- ================================================================
-- VENDA AUTOMÁTICA
-- ================================================================

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
    setupUIListeners()
    task.spawn(mainLoop)
    if config.autoSell then
        task.spawn(autoSellLoop)
    end
    ui:Toast("rbxassetid://131165537896572", "🎣 AutoFish", "Ativado!", Color3.fromRGB(100, 200, 255))
end

local function stopAutoFish()
    config.enabled = false
    activeBattle = false
    releaseClick()
    destroyBuoy()
    if currentBattleLoop then
        pcall(function() currentBattleLoop:Disconnect() end)
        currentBattleLoop = nil
    end
    ui:Toast("rbxassetid://131165537896572", "🎣 AutoFish", "Desativado", Color3.fromRGB(200, 100, 100))
end

-- ================================================================
-- MENU
-- ================================================================

local tabFarm = ui:Tab("farm")
local secFish = tabFarm:Section("auto fish")

local t_main = secFish:Toggle("auto fish", false, function(v)
    if v then startAutoFish() else stopAutoFish() end
end)

local t_reel = secFish:Toggle("auto reel (puxa quando morde)", true, function(v)
    config.autoReel = v
end)

local t_autosell = secFish:Toggle("auto sell (60s)", false, function(v)
    config.autoSell = v
    if config.enabled and v then
        task.spawn(autoSellLoop)
    end
end)

local s_delay = secFish:Slider("delay entre pescas (s)", 1, 5, 2, function(v)
    castDelay = v
end)

secFish:Button("vender todos os peixes", function()
    sellAllFish()
end)

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

print("[AutoFish] Carregado! Use a aba 'farm' no menu")
