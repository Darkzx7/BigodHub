
-- BGDhub Fishing Script v3.2 - Enhanced Fixed Version
-- Copyright 2k25
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack")

-- Global Variables
local autoMode = false
local holdingClick = false
local minimized = false
local fishCount = 0
local trashCount = 0
local diamondCount = 0
local totalCasts = 0
local lastCastTime = 0
local fishingInProgress = false
local waitingForUI = false
local uiAppeared = false
local lastClickTime = 0

-- Connections
local indicatorConnection = nil
local fishingLoop = nil
local uiWatcher = nil
local catchWatcher = nil

-- UI Elements
local gui = nil
local mainFrame = nil
local toggleBtn = nil
local statusLabel = nil
local statsFrame = nil

-- Enhanced Configuration for Better Performance
local PRECISION = {
    checkInterval = 0.008,
    safeMargin = 0.05,
    responseDelay = 0.016,
    castCooldown = 2.5,
    uiTimeout = 30,
    fishingTimeout = 60,
    catchDelay = 2,
    clickCooldown = 0.016
}

-- Theme
local THEME = {
    primary = Color3.fromRGB(138, 43, 226),
    secondary = Color3.fromRGB(147, 112, 219),
    accent = Color3.fromRGB(186, 85, 211),
    success = Color3.fromRGB(102, 205, 170),
    warning = Color3.fromRGB(255, 193, 7),
    danger = Color3.fromRGB(220, 53, 69),
    bg_primary = Color3.fromRGB(25, 25, 35),
    bg_secondary = Color3.fromRGB(35, 35, 50),
    bg_tertiary = Color3.fromRGB(45, 45, 65),
    bg_card = Color3.fromRGB(40, 40, 60),
    text_primary = Color3.fromRGB(255, 255, 255),
    text_secondary = Color3.fromRGB(200, 200, 220),
    text_muted = Color3.fromRGB(150, 150, 170),
    border = Color3.fromRGB(138, 43, 226),
    glow = Color3.fromRGB(186, 85, 211)
}

-- Logging System
local function log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s] [BGDhub] %s", timestamp, tostring(message))
    
    if level == "ERROR" then
        warn(logMessage)
    elseif level == "SUCCESS" then
        print("✅ " .. logMessage)
    elseif level == "WARNING" then
        warn("⚠️ " .. logMessage)
    else
        print(logMessage)
    end
end

-- Status Updates
local function updateStatus(text, color, icon)
    if statusLabel then
        statusLabel.Text = (icon or "") .. " " .. text
        statusLabel.TextColor3 = color or THEME.text_secondary
        
        -- Pulse animation for important status
        if icon == "🎯" or icon == "🎣" or icon == "✅" then
            local pulse = TweenService:Create(statusLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                TextTransparency = 0.3
            })
            pulse:Play()
            
            task.spawn(function()
                task.wait(2)
                pulse:Cancel()
                if statusLabel then
                    statusLabel.TextTransparency = 0
                end
            end)
        end
    end
    log(text, icon == "❌" and "ERROR" or (icon == "⚠️" and "WARNING" or "INFO"))
end

-- Reset Function
local function resetFishingState(reason)
    log("Resetting fishing state: " .. reason)
    
    if holdingClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        holdingClick = false
    end
    
    fishingInProgress = false
    waitingForUI = false
    uiAppeared = false
    lastClickTime = 0
    
    -- Aguardar um pouco antes do próximo lance
    task.wait(PRECISION.catchDelay * 1.5)
end

-- Create Enhanced Button
local function createButton(parent, config)
    local button = Instance.new("TextButton")
    button.Name = config.name or "Button"
    button.Size = config.size or UDim2.new(0, 200, 0, 40)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = config.color or THEME.primary
    button.BorderSizePixel = 0
    button.Text = config.text or "Button"
    button.TextColor3 = THEME.text_primary
    button.Font = Enum.Font.GothamBold
    button.TextSize = config.textSize or 14
    button.AutoButtonColor = false
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, config.color or THEME.primary),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(
            math.min(255, (config.color or THEME.primary).R * 255 + 30),
            math.min(255, (config.color or THEME.primary).G * 255 + 30),
            math.min(255, (config.color or THEME.primary).B * 255 + 30)
        ))
    }
    gradient.Rotation = 45
    gradient.Parent = button
    
    local glow = Instance.new("UIStroke")
    glow.Color = THEME.glow
    glow.Thickness = 2
    glow.Transparency = 0.7
    glow.Parent = button
    
    -- Enhanced hover effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            Size = UDim2.new(config.size.X.Scale, config.size.X.Offset + 5, config.size.Y.Scale, config.size.Y.Offset + 2)
        }):Play()
        TweenService:Create(glow, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {Size = config.size}):Play()
        TweenService:Create(glow, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
    end)
    
    return button
end

-- Create Stat Card with Animations
local function createStatCard(parent, config)
    local card = Instance.new("Frame")
    card.Name = config.name
    card.Size = UDim2.new(0, 85, 1, 0)
    card.BackgroundColor3 = THEME.bg_card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = config.color or THEME.border
    stroke.Thickness = 1
    stroke.Transparency = 0.8
    stroke.Parent = card
    
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 0.55, 0)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = config.icon
    icon.TextColor3 = config.color or THEME.text_secondary
    icon.TextSize = 18
    icon.Font = Enum.Font.GothamBold
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.TextYAlignment = Enum.TextYAlignment.Center
    icon.Parent = card
    
    local counter = Instance.new("TextLabel")
    counter.Name = "Counter"
    counter.Size = UDim2.new(1, 0, 0.45, 0)
    counter.Position = UDim2.new(0, 0, 0.55, 0)
    counter.BackgroundTransparency = 1
    counter.Text = "0"
    counter.TextColor3 = THEME.text_primary
    counter.TextSize = 16
    counter.Font = Enum.Font.GothamBold
    counter.TextXAlignment = Enum.TextXAlignment.Center
    counter.TextYAlignment = Enum.TextYAlignment.Center
    counter.Parent = card
    
    return card
end

-- Create Enhanced UI
local function createUI()
    if player.PlayerGui:FindFirstChild("BGDhubFishing") then
        player.PlayerGui.BGDhubFishing:Destroy()
        task.wait(0.1)
    end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "BGDhubFishing"
    gui.ResetOnSpawn = false
    gui.Parent = player.PlayerGui
    
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 360, 0, 240)
    mainFrame.Position = UDim2.new(1, -380, 0.5, -120)
    mainFrame.BackgroundColor3 = THEME.bg_primary
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = THEME.primary
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.5
    mainStroke.Parent = mainFrame
    
    -- Animated border glow
    task.spawn(function()
        while mainFrame.Parent do
            for i = 1, 100 do
                if mainStroke and mainStroke.Parent then
                    mainStroke.Transparency = 0.3 + (math.sin(i * 0.1) * 0.2)
                end
                task.wait(0.05)
            end
        end
    end)
    
    -- Enhanced Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 55)
    header.BackgroundColor3 = THEME.bg_secondary
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, THEME.primary),
        ColorSequenceKeypoint.new(0.5, THEME.secondary),
        ColorSequenceKeypoint.new(1, THEME.accent)
    }
    headerGradient.Rotation = 90
    headerGradient.Parent = header
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.Position = UDim2.new(0.05, 0, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "BGDhub"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextColor3 = THEME.text_primary
    titleText.TextSize = 19
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextYAlignment = Enum.TextYAlignment.Center
    titleText.Parent = header
    
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
    minimizeBtn.Position = UDim2.new(1, -42, 0.5, -17)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.BackgroundTransparency = 0.1
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = "─"
    minimizeBtn.TextColor3 = THEME.text_primary
    minimizeBtn.TextSize = 18
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = header
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(1, 0)
    minCorner.Parent = minimizeBtn
    
    -- Enhanced Toggle Button
    toggleBtn = createButton(mainFrame, {
        name = "ToggleButton",
        size = UDim2.new(0.9, 0, 0, 50),
        position = UDim2.new(0.05, 0, 0.28, 0),
        text = "INICIAR PESCA",
        textSize = 16,
        color = THEME.success
    })
    
    -- Enhanced Status Container
    local statusContainer = Instance.new("Frame")
    statusContainer.Size = UDim2.new(0.9, 0, 0, 35)
    statusContainer.Position = UDim2.new(0.05, 0, 0.58, 0)
    statusContainer.BackgroundColor3 = THEME.bg_tertiary
    statusContainer.BorderSizePixel = 0
    statusContainer.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusContainer
    
    local statusStroke = Instance.new("UIStroke")
    statusStroke.Color = THEME.border
    statusStroke.Thickness = 1
    statusStroke.Transparency = 0.7
    statusStroke.Parent = statusContainer
    
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 1, 0)
    statusLabel.Position = UDim2.new(0, 5, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Pronto para pescar"
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextColor3 = THEME.text_secondary
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    statusLabel.Parent = statusContainer
    
    -- Enhanced Stats Frame
    statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(0.9, 0, 0, 50)
    statsFrame.Position = UDim2.new(0.05, 0, 0.75, 0)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = mainFrame
    
    local fishCard = createStatCard(statsFrame, {
        name = "FishCard",
        icon = "🐟",
        color = THEME.success
    })
    fishCard.Position = UDim2.new(0, 0, 0, 0)
    
    local trashCard = createStatCard(statsFrame, {
        name = "TrashCard", 
        icon = "🗑️",
        color = THEME.warning
    })
    trashCard.Position = UDim2.new(0, 95, 0, 0)
    
    local diamondCard = createStatCard(statsFrame, {
        name = "DiamondCard",
        icon = "💎", 
        color = THEME.accent
    })
    diamondCard.Position = UDim2.new(0, 190, 0, 0)
    
    -- Minimize functionality
    local elementsToHide = {toggleBtn, statusContainer, statsFrame}
    
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        local targetSize = minimized and UDim2.new(0, 240, 0, 55) or UDim2.new(0, 360, 0, 240)
        local targetText = minimized and "+" or "─"
        local targetTitle = minimized and "BGD" or "BGDhub"
        
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Size = targetSize
        }):Play()
        
        for _, element in pairs(elementsToHide) do
            if element then
                element.Visible = not minimized
            end
        end
        
        minimizeBtn.Text = targetText
        titleText.Text = targetTitle
    end)
    
    log("Enhanced UI created successfully", "SUCCESS")
end

-- Enhanced Fishing Functions
local function findRod()
    return character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod")
end

local function equipRod()
    local rod = findRod()
    if rod then
        if rod.Parent == backpack then
            rod.Parent = character
            task.wait(0.5)
            log("Rod equipped successfully")
        end
        return rod
    end
    return nil
end

-- Smart cast line with proper state management
local function castLine()
    local currentTime = tick()
    if currentTime - lastCastTime < PRECISION.castCooldown then
        return false, "Cooldown active"
    end
    
    if fishingInProgress or waitingForUI then
        return false, "Already fishing"
    end
    
    local rod = equipRod()
    if not rod or rod.Parent ~= character then
        return false, "No rod available"
    end
    
    rod:Activate()
    lastCastTime = currentTime
    fishingInProgress = true
    waitingForUI = true
    uiAppeared = false
    totalCasts = totalCasts + 1
    
    updateStatus("Linha lançada! Aguardando UI... (Cast #" .. totalCasts .. ")", THEME.primary, "🎯")
    log("Line cast successfully - Cast #" .. totalCasts)
    
    return true, "Success"
end

-- Enhanced UI detection based on data analysis
local function getFishingUI()
    local fishing = workspace:FindFirstChild("fishing")
    if not fishing then return nil end
    
    local bar = fishing:FindFirstChild("bar")
    if not bar then return nil end
    
    local safeArea = bar:FindFirstChild("safeArea")
    local indicator = bar:FindFirstChild("indicator")
    
    if not safeArea or not indicator then return nil end
    
    return {
        fishing = fishing,
        bar = bar,
        safeArea = safeArea,
        indicator = indicator
    }
end

-- Enhanced Indicator Control Function
local function controlIndicator()
    if not autoMode or not fishingInProgress then return end
    
    local fishingUI = getFishingUI()
    if not fishingUI then return end
    
    -- Mark UI as appeared
    if waitingForUI then
        waitingForUI = false
        uiAppeared = true
        updateStatus("UI apareceu! Controlando indicador...", THEME.success, "🎣")
        log("Fishing UI appeared - starting control")
    end
    
    local safeArea = fishingUI.safeArea
    local indicator = fishingUI.indicator
    
    local safeY = safeArea.Position.Y.Scale
    local safeHeight = safeArea.Size.Y.Scale
    local indicatorY = indicator.Position.Y.Scale
    
    -- Enhanced safe zone calculation with reduced margin
    local margin = safeHeight * 0.05  -- Reduzido de 0.15 para 0.05
    local safeTop = safeY + margin
    local safeBottom = safeY + safeHeight - margin
    local centerY = safeY + (safeHeight / 2)
    
    local currentTime = tick()
    local timeSinceLastClick = currentTime - lastClickTime
    
    -- Zona de conforto mais ampla
    local isInComfortZone = indicatorY >= (safeY + safeHeight * 0.2) and indicatorY <= (safeY + safeHeight * 0.8)
    
    -- Sistema de clique contínuo mais eficiente
    if not isInComfortZone then
        if not holdingClick and timeSinceLastClick > 0.016 then  -- Reduzido para 16ms
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            holdingClick = true
            lastClickTime = currentTime
            
        -- Clique pulsante para manter na zona
        elseif holdingClick and timeSinceLastClick > 0.033 then  -- 33ms para clique pulsante
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            task.wait(0.016)  -- Pausa mínima
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            lastClickTime = currentTime
        end
        
    elseif isInComfortZone and holdingClick and timeSinceLastClick > 0.05 then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        holdingClick = false
        lastClickTime = currentTime
    end
    
    -- Forçar indicador para centro se muito fora
    if indicatorY < safeY - 0.1 or indicatorY > (safeY + safeHeight + 0.1) then
        if not holdingClick then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            holdingClick = true
            lastClickTime = currentTime
        end
    end
end

-- Enhanced stats update with animations
local function updateStats()
    if not statsFrame then return end
    
    local fishCard = statsFrame:FindFirstChild("FishCard")
    local trashCard = statsFrame:FindFirstChild("TrashCard")
    local diamondCard = statsFrame:FindFirstChild("DiamondCard")
    
    local function animateCounter(card, newValue)
        if card then
            local counter = card:FindFirstChild("Counter")
            if counter then
                counter.Text = tostring(newValue)
                
                -- Bounce animation
                local originalSize = counter.TextSize
                TweenService:Create(counter, TweenInfo.new(0.2), {TextSize = originalSize + 6}):Play()
                task.spawn(function()
                    task.wait(0.2)
                    if counter and counter.Parent then
                        TweenService:Create(counter, TweenInfo.new(0.2), {TextSize = originalSize}):Play()
                    end
                end)
            end
        end
    end
    
    animateCounter(fishCard, fishCount)
    animateCounter(trashCard, trashCount)
    animateCounter(diamondCard, diamondCount)
    
    log(string.format("Stats updated - Fish: %d, Trash: %d, Diamonds: %d", fishCount, trashCount, diamondCount))
end

-- Enhanced loot detection with improved reset
local function setupLootDetection()
    task.spawn(function()
        local leaderstats = player:WaitForChild("leaderstats", 10)
        if leaderstats then
            log("Leaderstats found - setting up loot detection")
            
            local stats = {
                Fish = leaderstats:FindFirstChild("Fish"),
                Trash = leaderstats:FindFirstChild("Trash"),
                Diamond = leaderstats:FindFirstChild("Diamond")
            }
            
            for statName, stat in pairs(stats) do
                if stat then
                    stat.Changed:Connect(function(newValue)
                        if statName == "Fish" then
                            fishCount = tonumber(newValue) or fishCount
                        elseif statName == "Trash" then
                            trashCount = tonumber(newValue) or trashCount
                        elseif statName == "Diamond" then
                            diamondCount = tonumber(newValue) or diamondCount
                        end
                        
                        updateStats()
                        
                        -- Enhanced reset after capture
                        if fishingInProgress then
                            updateStatus("Capturou algo! Resetando sistema...", THEME.success, "✅")
                            log(string.format("Catch completed! %s increased to %s", statName, newValue), "SUCCESS")
                            resetFishingState("Successful catch")
                        end
                    end)
                    
                    log(string.format("Monitoring %s stat", statName))
                end
            end
        else
            log("Leaderstats not found", "WARNING")
        end
    end)
    
    -- Enhanced UI disappearance monitoring
    task.spawn(function()
        while true do
            if fishingInProgress and uiAppeared then
                local fishingUI = getFishingUI()
                if not fishingUI then
                    -- UI disappeared - likely caught something
                    log("Fishing UI disappeared - processing catch")
                    resetFishingState("UI disappeared")
                end
            end
            task.wait(0.5)
        end
    end)
end

-- Smart fishing loop with enhanced logic
local function startFishing()
    updateStatus("Inicializando sistema de pesca inteligente...", THEME.warning, "⚙️")
    
    fishingLoop = task.spawn(function()
        while autoMode do
            -- Check for rod
            if not findRod() then
                updateStatus("Por favor, equipe uma vara de pescar!", THEME.danger, "❌")
                task.wait(5)
                continue
            end
            
            -- Cast line if not fishing
            if not fishingInProgress and not waitingForUI then
                local success, reason = castLine()
                if not success then
                    updateStatus("Falha no lance: " .. reason, THEME.warning, "⚠️")
                    task.wait(2)
                end
            elseif waitingForUI then
                local elapsed = tick() - lastCastTime
                if elapsed > PRECISION.uiTimeout then
                    log("UI timeout reached - resetting", "WARNING")
                    resetFishingState("UI timeout")
                else
                    updateStatus(string.format("Aguardando UI... (%.1fs)", elapsed), THEME.accent, "⏳")
                end
            else
                updateStatus("Pescando em progresso...", THEME.success, "🎣")
            end
            
            task.wait(1)
        end
    end)
    
    -- Start indicator control
    indicatorConnection = RunService.Heartbeat:Connect(controlIndicator)
    
    updateStatus("Pesca Inteligente Ativa!", THEME.success, "🚀")
    log("Smart fishing system started", "SUCCESS")
end

local function stopFishing()
    updateStatus("Parando sistema de pesca...", THEME.warning, "⏹️")
    
    if indicatorConnection then
        indicatorConnection:Disconnect()
        indicatorConnection = nil
    end
    
    if fishingLoop then
        task.cancel(fishingLoop)
        fishingLoop = nil
    end
    
    if holdingClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        holdingClick = false
    end
    
    fishingInProgress = false
    waitingForUI = false
    uiAppeared = false
    
    updateStatus("Pesca Inteligente Parada", THEME.text_secondary, "⏸️")
    log("Fishing system stopped", "SUCCESS")
end

-- Toggle function
local function toggleFishing()
    autoMode = not autoMode
    
    if autoMode then
        toggleBtn.Text = "PARAR PESCA"
        toggleBtn.BackgroundColor3 = THEME.danger
        startFishing()
    else
        toggleBtn.Text = "INICIAR PESCA"
        toggleBtn.BackgroundColor3 = THEME.success
        stopFishing()
    end
    
    log("Fishing toggled: " .. (autoMode and "ON" or "OFF"))
end

-- Character management
local function handleCharacter()
    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        backpack = player:WaitForChild("Backpack")
        log("Character respawned - resetting states")
        
        resetFishingState("Character respawned")
        
        if autoMode then
            task.wait(3)
            updateStatus("Pronto após respawn", THEME.success, "✅")
        end
    end)
end

-- Advanced Monitor with Auto-Correction
local function startAdvancedMonitor()
    task.spawn(function()
        while true do
            task.wait(1)
            
            if autoMode and fishingInProgress and uiAppeared then
                local fishingUI = getFishingUI()
                
                if fishingUI then
                    local indicator = fishingUI.indicator
                    local safeArea = fishingUI.safeArea
                    
                    if indicator and safeArea then
                        local indicatorY = indicator.Position.Y.Scale
                        local safeY = safeArea.Position.Y.Scale
                        local safeHeight = safeArea.Size.Y.Scale
                        
                        -- Verificar se está muito fora da zona por muito tempo
                        local isVeryOutside = indicatorY < (safeY - 0.2) or indicatorY > (safeY + safeHeight + 0.2)
                        
                        if isVeryOutside then
                            log("Indicator very far from safe zone - forcing correction", "WARNING")
                            
                            if not holdingClick then
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                holdingClick = true
                                lastClickTime = tick()
                            end
                        end
                    end
                end
            end
            
            -- Memory cleanup
            if autoMode then
                local memoryUsage = gcinfo()
                if memoryUsage > 50000 then
                    collectgarbage("collect")
                    log("Memory cleanup performed")
                end
                
                -- Reset stuck states
                if fishingInProgress and (tick() - lastCastTime) > PRECISION.fishingTimeout then
                    log("Fishing timeout - resetting stuck state", "WARNING")
                    resetFishingState("Fishing timeout")
                end
            end
        end
    end)
end

-- Initialize system
local function initialize()
    log("Starting Advanced Fishing System v3.2...", "SUCCESS")
    
    handleCharacter()
    createUI()
    
    if toggleBtn then
        toggleBtn.MouseButton1Click:Connect(toggleFishing)
    end
    
    setupLootDetection()
    updateStats()
    startAdvancedMonitor()
    
    if findRod() then
        updateStatus("Pronto para pesca inteligente!", THEME.success, "✅")
    else
        updateStatus("Equipe uma vara para começar", THEME.warning, "⚠️")
    end
    
    log("System initialized successfully!", "SUCCESS")
    return true
end

-- Cleanup
player.AncestryChanged:Connect(function()
    if not player.Parent and autoMode then
        stopFishing()
    end
end)

-- Main execution function
local function main()
    local success, error = pcall(initialize)
    
    if success then
        print("🎣 BGDhub Fishing v3.2 - Carregado com Sucesso!")
        print("✨ Sistema Inteligente com Controle Aprimorado!")
        print("🎯 Safe Zone Otimizada para Máxima Precisão!")
    else
        warn("❌ Falha ao inicializar: " .. tostring(error))
        
        task.wait(3)
        local retrySuccess, retryError = pcall(initialize)
        if not retrySuccess then
            warn("❌ Falha na segunda tentativa: " .. tostring(retryError))
        else
            print("🔄 Inicializado com sucesso na segunda tentativa!")
        end
    end
end

-- Execute the script
main()
```

