-- BGDhub Fishing Script v3.2 - Error-Safe Fixed Version
-- Copyright 2k25

-- Safe service getting with error handling
local function getService(serviceName)
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    if success then
        return service
    else
        warn("Failed to get service: " .. serviceName)
        return nil
    end
end

local Players = getService("Players")
local ReplicatedStorage = getService("ReplicatedStorage")
local VirtualInputManager = getService("VirtualInputManager")
local TweenService = getService("TweenService")
local RunService = getService("RunService")

if not Players or not VirtualInputManager or not TweenService or not RunService then
    error("Critical services not available!")
    return
end

local player = Players.LocalPlayer
if not player then
    error("LocalPlayer not found!")
    return
end

local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack", 10)

if not backpack then
    error("Backpack not found!")
    return
end

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

-- Safe logging System
local function log(message, level)
    local success, _ = pcall(function()
        level = level or "INFO"
        local timestamp = os.date and os.date("%H:%M:%S") or "00:00:00"
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
    end)
    
    if not success then
        print("[BGDhub] " .. tostring(message))
    end
end

-- Status Updates with safety
local function updateStatus(text, color, icon)
    local success, _ = pcall(function()
        if statusLabel and statusLabel.Parent then
            statusLabel.Text = (icon or "") .. " " .. text
            statusLabel.TextColor3 = color or THEME.text_secondary
            
            -- Pulse animation for important status
            if TweenService and (icon == "🎯" or icon == "🎣" or icon == "✅") then
                local pulse = TweenService:Create(statusLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                    TextTransparency = 0.3
                })
                pulse:Play()
                
                task.spawn(function()
                    task.wait(2)
                    if pulse then
                        pulse:Cancel()
                    end
                    if statusLabel and statusLabel.Parent then
                        statusLabel.TextTransparency = 0
                    end
                end)
            end
        end
    end)
    
    log(text, icon == "❌" and "ERROR" or (icon == "⚠️" and "WARNING" or "INFO"))
end

-- Safe Reset Function
local function resetFishingState(reason)
    local success, _ = pcall(function()
        log("Resetting fishing state: " .. reason)
        
        if holdingClick and VirtualInputManager then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            holdingClick = false
        end
        
        fishingInProgress = false
        waitingForUI = false
        uiAppeared = false
        lastClickTime = 0
        
        -- Aguardar um pouco antes do próximo lance
        task.wait(PRECISION.catchDelay * 1.5)
    end)
    
    if not success then
        log("Error in resetFishingState", "ERROR")
    end
end

-- Create Enhanced Button with safety
local function createButton(parent, config)
    local success, button = pcall(function()
        local btn = Instance.new("TextButton")
        btn.Name = config.name or "Button"
        btn.Size = config.size or UDim2.new(0, 200, 0, 40)
        btn.Position = config.position or UDim2.new(0, 0, 0, 0)
        btn.BackgroundColor3 = config.color or THEME.primary
        btn.BorderSizePixel = 0
        btn.Text = config.text or "Button"
        btn.TextColor3 = THEME.text_primary
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = config.textSize or 14
        btn.AutoButtonColor = false
        btn.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = btn
        
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
        gradient.Parent = btn
        
        local glow = Instance.new("UIStroke")
        glow.Color = THEME.glow
        glow.Thickness = 2
        glow.Transparency = 0.7
        glow.Parent = btn
        
        -- Enhanced hover effects with safety
        btn.MouseEnter:Connect(function()
            if TweenService then
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    Size = UDim2.new(config.size.X.Scale, config.size.X.Offset + 5, config.size.Y.Scale, config.size.Y.Offset + 2)
                }):Play()
                TweenService:Create(glow, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
            end
        end)
        
        btn.MouseLeave:Connect(function()
            if TweenService then
                TweenService:Create(btn, TweenInfo.new(0.2), {Size = config.size}):Play()
                TweenService:Create(glow, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
            end
        end)
        
        return btn
    end)
    
    if success then
        return button
    else
        log("Error creating button", "ERROR")
        return nil
    end
end

-- Create Stat Card with safety
local function createStatCard(parent, config)
    local success, card = pcall(function()
        local c = Instance.new("Frame")
        c.Name = config.name
        c.Size = UDim2.new(0, 85, 1, 0)
        c.BackgroundColor3 = THEME.bg_card
        c.BorderSizePixel = 0
        c.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = c
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = config.color or THEME.border
        stroke.Thickness = 1
        stroke.Transparency = 0.8
        stroke.Parent = c
        
        local icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(1, 0, 0.55, 0)
        icon.Position = UDim2.new(0, 0, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = config.icon
        icon.TextColor3 = config.color or THEME.text_secondary
        icon.TextSize = 18
        icon.Font = Enum.Font.SourceSansBold
        icon.TextXAlignment = Enum.TextXAlignment.Center
        icon.TextYAlignment = Enum.TextYAlignment.Center
        icon.Parent = c
        
        local counter = Instance.new("TextLabel")
        counter.Name = "Counter"
        counter.Size = UDim2.new(1, 0, 0.45, 0)
        counter.Position = UDim2.new(0, 0, 0.55, 0)
        counter.BackgroundTransparency = 1
        counter.Text = "0"
        counter.TextColor3 = THEME.text_primary
        counter.TextSize = 16
        counter.Font = Enum.Font.SourceSansBold
        counter.TextXAlignment = Enum.TextXAlignment.Center
        counter.TextYAlignment = Enum.TextYAlignment.Center
        counter.Parent = c
        
        return c
    end)
    
    if success then
        return card
    else
        log("Error creating stat card", "ERROR")
        return nil
    end
end

-- Create Enhanced UI with safety
local function createUI()
    local success, _ = pcall(function()
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
        
        -- Animated border glow with safety
        task.spawn(function()
            while mainFrame and mainFrame.Parent do
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
        titleText.Font = Enum.Font.SourceSansBold
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
        minimizeBtn.Font = Enum.Font.SourceSansBold
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
        statusLabel.Font = Enum.Font.SourceSans
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
        if fishCard then fishCard.Position = UDim2.new(0, 0, 0, 0) end
        
        local trashCard = createStatCard(statsFrame, {
            name = "TrashCard", 
            icon = "🗑️",
            color = THEME.warning
        })
        if trashCard then trashCard.Position = UDim2.new(0, 95, 0, 0) end
        
        local diamondCard = createStatCard(statsFrame, {
            name = "DiamondCard",
            icon = "💎", 
            color = THEME.accent
        })
        if diamondCard then diamondCard.Position = UDim2.new(0, 190, 0, 0) end
        
        -- Minimize functionality with safety
        local elementsToHide = {toggleBtn, statusContainer, statsFrame}
        
        minimizeBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            
            local targetSize = minimized and UDim2.new(0, 240, 0, 55) or UDim2.new(0, 360, 0, 240)
            local targetText = minimized and "+" or "─"
            local targetTitle = minimized and "BGD" or "BGDhub"
            
            if TweenService then
                TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                    Size = targetSize
                }):Play()
            end
            
            for _, element in pairs(elementsToHide) do
                if element and element.Parent then
                    element.Visible = not minimized
                end
            end
            
            minimizeBtn.Text = targetText
            titleText.Text = targetTitle
        end)
        
        log("Enhanced UI created successfully", "SUCCESS")
    end)
    
    if not success then
        log("Error creating UI", "ERROR")
    end
end

-- Enhanced Fishing Functions with safety
local function findRod()
    local success, rod = pcall(function()
        return character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod")
    end)
    
    if success then
        return rod
    else
        return nil
    end
end

local function equipRod()
    local success, rod = pcall(function()
        local r = findRod()
        if r then
            if r.Parent == backpack then
                r.Parent = character
                task.wait(0.5)
                log("Rod equipped successfully")
            end
            return r
        end
        return nil
    end)
    
    if success then
        return rod
    else
        log("Error equipping rod", "ERROR")
        return nil
    end
end

-- Smart cast line with safety
local function castLine()
    local success, result = pcall(function()
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
    end)
    
    if success then
        return result
    else
        return false, "Cast error"
    end
end

-- Enhanced UI detection with safety
local function getFishingUI()
    local success, ui = pcall(function()
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
    end)
    
    if success then
        return ui
    else
        return nil
    end
end

-- Enhanced Indicator Control with safety
local function controlIndicator()
    local success, _ = pcall(function()
        if not autoMode or not fishingInProgress or not VirtualInputManager then return end
        
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
        local margin = safeHeight * 0.05
        local safeTop = safeY + margin
        local safeBottom = safeY + safeHeight - margin
        
        local currentTime = tick()
        local timeSinceLastClick = currentTime - lastClickTime
        
        -- Zona de conforto mais ampla
        local isInComfortZone = indicatorY >= (safeY + safeHeight * 0.2) and indicatorY <= (safeY + safeHeight * 0.8)
        
        -- Sistema de clique contínuo mais eficiente
        if not isInComfortZone then
            if not holdingClick and timeSinceLastClick > 0.016 then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                holdingClick = true
                lastClickTime = currentTime
                
            elseif holdingClick and timeSinceLastClick > 0.033 then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                task.wait(0.016)
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
    end)
    
    if not success then
        log("Error in controlIndicator", "ERROR")
    end
end

-- Enhanced stats update with safety
local function updateStats()
    local success, _ = pcall(function()
        if not statsFrame or not statsFrame.Parent then return end
        
        local fishCard = statsFrame:FindFirstChild("FishCard")
        local trashCard = statsFrame:FindFirstChild("TrashCard")
        local diamondCard = statsFrame:FindFirstChild("DiamondCard")
        
        local function animateCounter(card, newValue)
            if card and card.Parent then
                local counter = card:FindFirstChild("Counter")
                if counter and counter.Parent then
                    counter.Text = tostring(newValue)
                    
                    -- Bounce animation with safety
                    if TweenService then
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
        end
        
        animateCounter(fishCard, fishCount)
        animateCounter(trashCard, trashCount)
        animateCounter(diamondCard, diamondCount)
        
        log(string.format("Stats updated - Fish: %d, Trash: %d, Diamonds: %d", fishCount, trashCount, diamondCount))
    end)
    
    if not success then
        log("Error updating stats", "ERROR")
    end
end

-- Enhanced loot detection with safety
local function setupLootDetection()
    task.spawn(function()
        local success, _ = pcall(function()
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
        
        if not success then
            log("Error setting up loot detection", "ERROR")
        end
    end)
    
    -- Enhanced UI disappearance monitoring with safety
    task.spawn(function()
        while true do
            local success, _ = pcall(function()
                if fishingInProgress and uiAppeared then
                    local fishingUI = getFishingUI()
                    if not fishingUI then
                        log("Fishing UI disappeared - processing catch")
                        resetFishingState("UI disappeared")
                    end
                end
            end)
            
            if not success then
                log("Error in UI monitoring", "ERROR")
            end
            
            task.wait(0.5)
        end
    end)
end

-- Smart fishing loop with safety
local function startFishing()
    updateStatus("Inicializando sistema de pesca inteligente...", THEME.warning, "⚙️")
    
    fishingLoop = task.spawn(function()
        while autoMode do
            local success, _ = pcall(function()
                -- Check for rod
                if not findRod() then
                    updateStatus("Por favor, equipe uma vara de pescar!", THEME.danger, "❌")
                    task.wait(5)
                    return
                end
                
                -- Cast line if not fishing
                if not fishingInProgress and not waitingForUI then
                    local castSuccess, reason = castLine()
                    if not castSuccess then
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
            end)
            
            if not success then
                log("Error in fishing loop", "ERROR")
            end
            
            task.wait(1)
        end
    end)
    
    -- Start indicator control with safety
    if RunService then
        indicatorConnection = RunService.Heartbeat:Connect(controlIndicator)
    end
    
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
    
    if holdingClick and VirtualInputManager then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        holdingClick = false
    end
    
    fishingInProgress = false
    waitingForUI = false
    uiAppeared = false
    
    updateStatus("Pesca Inteligente Parada", THEME.text_secondary, "⏸️")
    log("Fishing system stopped", "SUCCESS")
end

-- Toggle function with safety
local function toggleFishing()
    local success, _ = pcall(function()
        autoMode = not autoMode
        
        if autoMode then
            if toggleBtn then
                toggleBtn.Text = "PARAR PESCA"
                toggleBtn.BackgroundColor3 = THEME.danger
            end
            startFishing()
        else
            if toggleBtn then
                toggleBtn.Text = "INICIAR PESCA"
                toggleBtn.BackgroundColor3 = THEME.success
            end
            stopFishing()
        end
        
        log("Fishing toggled: " .. (autoMode and "ON" or "OFF"))
    end)
    
    if not success then
        log("Error toggling fishing", "ERROR")
    end
end

-- Character management with safety
local function handleCharacter()
    local success, _ = pcall(function()
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
    end)
    
    if not success then
        log("Error setting up character handling", "ERROR")
    end
end

-- Advanced Monitor with safety
local function startAdvancedMonitor()
    task.spawn(function()
        while true do
            local success, _ = pcall(function()
                if autoMode and fishingInProgress and uiAppeared then
                    local fishingUI = getFishingUI()
                    
                    if fishingUI then
                        local indicator = fishingUI.indicator
                        local safeArea = fishingUI.safeArea
                        
                        if indicator and safeArea then
                            local indicatorY = indicator.Position.Y.Scale
                            local safeY = safeArea.Position.Y.Scale
                            local safeHeight = safeArea.Size.Y.Scale
                            
                            local isVeryOutside = indicatorY < (safeY - 0.2) or indicatorY > (safeY + safeHeight + 0.2)
                            
                            if isVeryOutside then
                                log("Indicator very far from safe zone - forcing correction", "WARNING")
                                
                                if not holdingClick and VirtualInputManager then
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
            end)
            
            if not success then
                log("Error in advanced monitor", "ERROR")
            end
            
            task.wait(1)
        end
    end)
end

-- Initialize system with safety
local function initialize()
    local success, result = pcall(function()
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
    end)
    
    if success then
        return result
    else
        log("Error initializing system", "ERROR")
        return false
    end
end

-- Cleanup with safety
if player then
    player.AncestryChanged:Connect(function()
        if not player.Parent and autoMode then
            stopFishing()
        end
    end)
end

-- Main execution with safety
local function main()
    local success, error = pcall(initialize)
    
    if success then
        print("🎣 BGDhub Fishing v3.2 - Carregado com Sucesso!")
        print("✨ Sistema Inteligente com Controle Aprimorado!")
        print("🎯 Safe Zone Otimizada - Versão Error-Safe!")
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

-- Execute the script safely
main()
