-- ================================================================
-- AUTOFISH v1.0 - Funcional para o sistema de pesca
-- ================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- Carrega os eventos
local events = require(ReplicatedStorage.Shared.Modules.events)

-- Configurações
local autoFishEnabled = false
local autoReelEnabled = true  -- Puxa automaticamente quando o peixe morde
local perfectCatchEnabled = true  -- Tenta pegar no ponto perfeito
local autoSellEnabled = false  -- Vende os peixes automaticamente

-- Variáveis de controle
local isFishing = false
local isInBattle = false
local currentTool = nil
local lastCastTime = 0
local castDelay = 3  -- Delay entre lançamentos (segundos)
local fishCaught = 0

-- GUI de status
local statusGui = nil

-- ================================================================
-- FUNÇÕES DE UTILIDADE
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

local function equipFishingRod()
    local rod = getFishingRod()
    if not rod then
        warn("[AutoFish] Vara de pesca não encontrada!")
        return false
    end
    
    local char = player.Character
    if char and rod.Parent ~= char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(rod)
            task.wait(0.5)
        end
    end
    
    return true
end

local function castRod()
    local rod = getFishingRod()
    if not rod then return false end
    
    -- Ativa a vara (lança a linha)
    rod:Activate()
    return true
end

-- ================================================================
-- MECÂNICA DE PESCA AUTOMÁTICA
-- ================================================================

local function findFishingUI()
    local fishingUI = player.PlayerGui:FindFirstChild("FishingUI")
    if not fishingUI then return nil end
    
    return {
        buoyFrame = fishingUI:FindFirstChild("BuoyFrame"),
        catchingBar = fishingUI:FindFirstChild("CatchingBar"),
        strikePrompt = fishingUI and fishingUI:FindFirstChild("BuoyFrame") and fishingUI.BuoyFrame:FindFirstChild("StrikePrompt")
    }
end

-- Simula o clique para puxar o peixe
local function pullFish()
    -- Simula o botão de puxar (MouseButton1 ou R2 no controle)
    VirtualInput:SendMouseButtonEvent(0, 0, 0, true, "Left", 1)
    task.wait(0.05)
    VirtualInput:SendMouseButtonEvent(0, 0, 0, false, "Left", 1)
end

-- Mantém pressionado durante a batalha
local function holdPull()
    VirtualInput:SendMouseButtonEvent(0, 0, 0, true, "Left", 1)
end

local function releasePull()
    VirtualInput:SendMouseButtonEvent(0, 0, 0, false, "Left", 1)
end

-- Controle da barra de progresso (sistema de "batalha")
local function manageFishingBattle()
    local fishingUI = findFishingUI()
    if not fishingUI or not fishingUI.catchingBar then return end
    
    -- Encontra os elementos da UI
    local catchFrame = fishingUI.catchingBar:FindFirstChild("Frame")
    if not catchFrame then return end
    
    local catchContainer = catchFrame:FindFirstChild("Bar")
    if not catchContainer then return end
    
    local greenBar = catchContainer:FindFirstChild("Green")  -- A barra verde que você controla
    local marker = catchContainer:FindFirstChild("Marker")  -- O peixe (marcador)
    local progress = catchFrame:FindFirstChild("Progress")
    
    if not greenBar or not marker then return end
    
    -- Loop de controle da barra
    local battleLoop = nil
    local holding = false
    
    battleLoop = RunService.RenderStepped:Connect(function()
        if not autoFishEnabled or not isInBattle then
            if battleLoop then battleLoop:Disconnect() end
            return
        end
        
        -- Pega a posição atual
        local barY = greenBar.Position.Y.Scale
        local fishY = marker.Position.Y.Scale
        local barSize = greenBar.Size.Y.Scale
        
        -- Lógica: segura quando o peixe está dentro da barra verde
        local isFishInBar = fishY >= barY and fishY <= (barY + barSize)
        
        if perfectCatchEnabled then
            -- Tenta manter o peixe exatamente no centro da barra
            local centerY = barY + (barSize / 2)
            local offset = fishY - centerY
            
            if math.abs(offset) > 0.05 then
                if offset > 0 then
                    -- Peixe abaixo do centro -> solta
                    if holding then
                        releasePull()
                        holding = false
                    end
                else
                    -- Peixe acima do centro -> segura
                    if not holding then
                        holdPull()
                        holding = true
                    end
                end
            else
                -- No centro, mantém o estado atual
                if not holding and isFishInBar then
                    holdPull()
                    holding = true
                elseif holding and not isFishInBar then
                    releasePull()
                    holding = false
                end
            end
        else
            -- Modo simples: só segura quando o peixe está na barra
            if isFishInBar then
                if not holding then
                    holdPull()
                    holding = true
                end
            else
                if holding then
                    releasePull()
                    holding = false
                end
            end
        end
        
        -- Verifica se a batalha acabou (UI sumiu)
        if not fishingUI.catchingBar.Visible then
            isInBattle = false
            if battleLoop then battleLoop:Disconnect() end
            fishCaught = fishCaught + 1
            releasePull()
        end
    end)
    
    return battleLoop
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
            -- Quando o StrikePrompt aparece, o peixe mordeu!
            strikePrompt:GetPropertyChangedSignal("Visible"):Connect(function()
                if autoFishEnabled and strikePrompt.Visible and autoReelEnabled then
                    task.wait(0.1)  -- Pequeno delay pra dar tempo de ver a animação
                    pullFish()
                end
            end)
        end
    end
    
    -- Monitora quando a batalha começa (CatchingBar aparece)
    local catchingBar = fishingUI:FindFirstChild("CatchingBar")
    if catchingBar then
        catchingBar:GetPropertyChangedSignal("Visible"):Connect(function()
            if autoFishEnabled and catchingBar.Visible then
                isInBattle = true
                manageFishingBattle()
            end
        end)
    end
end

-- ================================================================
-- LOOP PRINCIPAL DO AUTOFISH
-- ================================================================

local function autoFishLoop()
    while autoFishEnabled do
        -- Espera o delay entre lançamentos
        local elapsed = os.clock() - lastCastTime
        if elapsed < castDelay then
            task.wait(castDelay - elapsed)
        end
        
        if not autoFishEnabled then break end
        
        -- Verifica se está pescando
        local fishingUI = findFishingUI()
        if fishingUI and fishingUI.buoyFrame and fishingUI.buoyFrame.Visible then
            -- Já está pescando
            task.wait(1)
        else
            -- Equipa a vara se necessário
            if not getFishingRod() then
                task.wait(2)
            end
            
            -- Lança a linha
            local success = castRod()
            if success then
                lastCastTime = os.clock()
                
                -- Atualiza status
                if statusGui then
                    statusGui:FindFirstChild("StatusText").Text = "🎣 Pesca lançada..."
                end
            end
        end
        
        task.wait(0.5)
    end
end

-- ================================================================
-- SISTEMA DE VENDA AUTOMÁTICA
-- ================================================================

local function sellAllFish()
    -- Dispara o evento de venda
    events:Fire("sellFish")
    
    if statusGui then
        local sellText = statusGui:FindFirstChild("SellText")
        if sellText then
            sellText.Text = "💰 Vendeu todos os peixes!"
            task.delay(3, function()
                if sellText then sellText.Text = "" end
            end)
        end
    end
end

local function autoSellLoop()
    while autoFishEnabled and autoSellEnabled do
        task.wait(60)  -- Vende a cada 60 segundos
        if autoFishEnabled and autoSellEnabled then
            sellAllFish()
        end
    end
end

-- ================================================================
-- GUI DE STATUS
-- ================================================================

local function createStatusGUI()
    -- Remove GUI antiga se existir
    if statusGui then statusGui:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFishStatus"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 220, 0, 120)
    mainFrame.Position = UDim2.new(0, 10, 0, 100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = "🎣 AUTO FISH"
    title.TextColor3 = Color3.fromRGB(100, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = mainFrame
    
    -- Status
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.Position = UDim2.new(0, 0, 0, 28)
    statusText.BackgroundTransparency = 1
    statusText.Text = "⚪ Desativado"
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 12
    statusText.Parent = mainFrame
    
    -- Peixes pescados
    local fishCountText = Instance.new("TextLabel")
    fishCountText.Name = "FishCount"
    fishCountText.Size = UDim2.new(1, 0, 0, 20)
    fishCountText.Position = UDim2.new(0, 0, 0, 48)
    fishCountText.BackgroundTransparency = 1
    fishCountText.Text = "🐟 Peixes: 0"
    fishCountText.TextColor3 = Color3.fromRGB(200, 255, 200)
    fishCountText.Font = Enum.Font.Gotham
    fishCountText.TextSize = 12
    fishCountText.Parent = mainFrame
    
    -- Venda automática
    local sellText = Instance.new("TextLabel")
    sellText.Name = "SellText"
    sellText.Size = UDim2.new(1, 0, 0, 20)
    sellText.Position = UDim2.new(0, 0, 0, 68)
    sellText.BackgroundTransparency = 1
    sellText.Text = autoSellEnabled and "🔄 Venda automática: ON" or "💰 Venda automática: OFF"
    sellText.TextColor3 = Color3.fromRGB(255, 200, 100)
    sellText.Font = Enum.Font.Gotham
    sellText.TextSize = 11
    sellText.Parent = mainFrame
    
    -- Botão de vender
    local sellBtn = Instance.new("TextButton")
    sellBtn.Size = UDim2.new(0.45, 0, 0, 25)
    sellBtn.Position = UDim2.new(0.03, 0, 0, 90)
    sellBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    sellBtn.Text = "VENDER"
    sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sellBtn.Font = Enum.Font.GothamBold
    sellBtn.TextSize = 12
    sellBtn.Parent = mainFrame
    Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 4)
    
    sellBtn.MouseButton1Click:Connect(function()
        sellAllFish()
    end)
    
    -- Botão de fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.45, 0, 0, 25)
    closeBtn.Position = UDim2.new(0.52, 0, 0, 90)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.Text = "FECHAR"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = mainFrame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        statusGui = nil
    end)
    
    -- Atualiza contador
    task.spawn(function()
        while screenGui and screenGui.Parent do
            fishCountText.Text = "🐟 Peixes pescados: " .. fishCaught
            task.wait(1)
        end
    end)
    
    return screenGui
end

-- ================================================================
-- FUNÇÃO PRINCIPAL
-- ================================================================

local function startAutoFish()
    if autoFishEnabled then return end
    
    autoFishEnabled = true
    isFishing = false
    isInBattle = false
    fishCaught = 0
    
    -- Cria GUI de status
    statusGui = createStatusGUI()
    
    -- Configura listeners da UI
    setupUIListeners()
    
    -- Inicia o loop principal
    task.spawn(autoFishLoop)
    
    -- Inicia venda automática se ativada
    if autoSellEnabled then
        task.spawn(autoSellLoop)
    end
    
    -- Atualiza status
    if statusGui then
        statusGui:FindFirstChild("StatusText").Text = "🟢 ATIVO - Pesca automática"
    end
    
    print("[AutoFish] Iniciado!")
end

local function stopAutoFish()
    autoFishEnabled = false
    isInBattle = false
    
    if statusGui then
        statusGui:FindFirstChild("StatusText").Text = "🔴 DESATIVADO"
        task.delay(2, function()
            if statusGui then statusGui:Destroy() end
            statusGui = nil
        end)
    end
    
    -- Solta o botão se estiver segurando
    releasePull()
    
    print("[AutoFish] Parado!")
end

-- ================================================================
-- EXPORTAÇÃO PARA O MENU
-- ================================================================

-- Se você tem um menu (RefLib), adicione isso:
-- local tabFarm = ui:Tab("farm")
-- local secFish = tabFarm:Section("auto fish")

-- Toggle principal
-- secFish:Toggle("auto fish (automático)", false, function(v)
--     if v then startAutoFish() else stopAutoFish() end
-- end)

-- secFish:Toggle("auto reel (puxa quando morde)", true, function(v) autoReelEnabled = v end)
-- secFish:Toggle("perfect catch (tenta ponto perfeito)", true, function(v) perfectCatchEnabled = v end)
-- secFish:Toggle("auto sell (vende a cada minuto)", false, function(v) autoSellEnabled = v end)

-- secFish:Slider("delay entre pescas (s)", 1, 10, 3, function(v) castDelay = v end)

-- secFish:Button("vender todos os peixes agora", function() sellAllFish() end)

-- Retorna as funções para uso externo
return {
    start = startAutoFish,
    stop = stopAutoFish,
    sell = sellAllFish,
    isRunning = function() return autoFishEnabled end
}
