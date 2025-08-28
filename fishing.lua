-- ADVANCED AUTO FISHING SYSTEM - PERFECTED VERSION
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack")

-- State Management
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

-- Enhanced Precision Config Based on Data Analysis
local PRECISION = {
    checkInterval = 0.016,
    safeMargin = 0.15, -- Increased margin to prevent premature clicking
    responseDelay = 0.08, -- Slower response to prevent rod retraction
    castCooldown = 3,
    uiTimeout = 50, -- UI can take up to 50 seconds to appear
    fishingTimeout = 80, -- Longer timeout based on data
    catchDelay = 3,
    clickCooldown = 0.5 -- Prevent rapid clicking
}

-- Enhanced Purple Theme
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

-- Enhanced Logging System
local function log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logMessage = string.format("[%s] [FISHING PRO] %s", timestamp, tostring(message))
    
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

-- Enhanced Status Updates
local function updateStatus(text, color, icon)
    if statusLabel then
        statusLabel.Text = (icon or "●") .. " " .. text
        statusLabel.TextColor3 = color or THEME.text_secondary
        
        -- Pulse animation for important status
        if icon == "🎯" or icon == "🎣" or icon == "✅" then
            local pulse = TweenService:Create(statusLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                TextTransparency = 0.3
            })
            pulse:Play()
            
            task.wait(2)
            pulse:Cancel()
            statusLabel.TextTransparency = 0
        end
    end
    log(text, icon == "❌" and "ERROR" or (icon == "⚠️" and "WARNING" or "INFO"))
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
    if player.PlayerGui:FindFirstChild("AdvancedFishingHub") then
        player.PlayerGui.AdvancedFishingHub:Destroy()
        task.wait(0.1)
    end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "AdvancedFishingHub"
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
    titleText.Text = "🎣 FISHING HUB PRO+"
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
        text = "▶ START SMART FISHING",
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
    statusLabel.Text = "● Ready for smart fishing"
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
        local targetTitle = minimized and "FISHING PRO" or "🎣 FISHING HUB PRO+"
        
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
    
    updateStatus("Line cast! Waiting for UI... (Cast #" .. totalCasts .. ")", THEME.primary, "🎯")
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

-- Smart indicator control based on data analysis
local function controlIndicator()
    if not autoMode or not fishingInProgress then return end
    
    local fishingUI = getFishingUI()
    if not fishingUI then return end
    
    -- Mark UI as appeared
    if waitingForUI then
        waitingForUI = false
        uiAppeared = true
        updateStatus("UI appeared! Controlling indicator...", THEME.success, "🎣")
        log("Fishing UI appeared - starting control")
    end
    
    local safeArea = fishingUI.safeArea
    local indicator = fishingUI.indicator
    
    local safeY = safeArea.Position.Y.Scale
    local safeHeight = safeArea.Size.Y.Scale
    local indicatorY = indicator.Position.Y.Scale
    
    -- Enhanced safe zone calculation
    local margin = safeHeight * PRECISION.safeMargin
    local safeTop = safeY + margin
    local safeBottom = safeY + safeHeight - margin
    
    local isInSafeZone = indicatorY >= safeTop and indicatorY <= safeBottom
    local currentTime = tick()
    
    -- Smart clicking logic
    if not isInSafeZone and not holdingClick and (currentTime - lastClickTime) > PRECISION.clickCooldown then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        holdingClick = true
        lastClickTime = currentTime
        log(string.format("Started holding click - Indicator: %.3f, Safe: %.3f-%.3f", indicatorY, safeTop, safeBottom))
        
    elseif isInSafeZone and holdingClick and (currentTime - lastClickTime) > PRECISION.responseDelay then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        holdingClick = false
        lastClickTime = currentTime
        log("Released click - indicator in safe zone")
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
                task.wait(0.2)
                TweenService:Create(counter, TweenInfo.new(0.2), {TextSize = originalSize}):Play()
            end
        end
    end
    
    animateCounter(fishCard, fishCount)
    animateCounter(trashCard, trashCount)
    animateCounter(diamondCard, diamondCount)
    
    log(string.format("Stats updated - Fish: %d, Trash: %d, Diamonds: %d", fishCount, trashCount, diamondCount))
end

-- Enhanced loot detection with multiple methods
local function setupLootDetection()
    -- Method 1: Leaderstats monitoring (most reliable based on data)
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
                        
                        -- Reset fishing state after successful catch
                        if fishingInProgress then
                            task.wait(PRECISION.catchDelay)
                            fishingInProgress = false
                            waitingForUI = false
                            uiAppeared = false
                            
                            if holdingClick then
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                                holdingClick = false
                            end
                            
                            updateStatus("Caught something! Preparing next cast...", THEME.success, "✅")
                            log(string.format("Catch completed! %s increased to %s", statName, newValue), "SUCCESS")
                        end
                    end)
                    
                    log(string.format("Monitoring %s stat", statName))
                end
            end
        else
            log("Leaderstats not found", "WARNING")
        end
    end)
    
    -- Method 2: UI disappearance monitoring
    task.spawn(function()
        while true do
            if fishingInProgress and uiAppeared then
                local fishingUI = getFishingUI()
                if not fishingUI then
                    -- UI disappeared - likely caught something
                    log("Fishing UI disappeared - processing catch")
                    task.wait(PRECISION.catchDelay)
                    fishingInProgress = false
                    waitingForUI = false
                    uiAppeared = false
                    
                    if holdingClick then
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        holdingClick = false
                    end
                    
                    updateStatus("Fishing completed! Ready for next cast", THEME.success, "✅")
                end
            end
            task.wait(1)
        end
    end)
end

-- Smart fishing loop with enhanced logic
local function startFishing()
    updateStatus("Initializing smart fishing system...", THEME.warning, "⚙️")
    
    fishingLoop = task.spawn(function()
        while autoMode do
            -- Check for rod
            if not findRod() then
                updateStatus("Please equip a fishing rod!", THEME.danger, "❌")
                task.wait(5)
                continue
            end
            
            -- Cast line if not fishing
            if not fishingInProgress and not waitingForUI then
                local success, reason = castLine()
                if not success then
                    updateStatus("Cast failed: " .. reason, THEME.warning, "⚠️")
                    task.wait(2)
                end
            elseif waitingForUI then
                local elapsed = tick() - lastCastTime
                if elapsed > PRECISION.uiTimeout then
                    log("UI timeout reached - resetting", "WARNING")
                    fishingInProgress = false
                    waitingForUI = false
                    updateStatus("UI timeout - trying again...", THEME.warning, "⚠️")
                else
                    updateStatus(string.format("Waiting for UI... (%.1fs)", elapsed), THEME.accent, "⏳")
                end
            else
                updateStatus("Fishing in progress...", THEME.success, "🎣")
            end
            
            task.wait(1)
        end
    end)
    
    -- Start indicator control
    indicatorConnection = RunService.Heartbeat:Connect(controlIndicator)
    
    updateStatus("Smart Fishing Active!", THEME.success, "🚀")
    log("Smart fishing system started", "SUCCESS")
end

local function stopFishing()
    updateStatus("Stopping fishing system...", THEME.warning, "⏹️")
    
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
    
    updateStatus("Smart Fishing Stopped", THEME.text_secondary, "⏸️")
    log("Fishing system stopped", "SUCCESS")
end

-- Toggle function
local function toggleFishing()
    autoMode = not autoMode
    
    if autoMode then
        toggleBtn.Text = "⏹ STOP FISHING"
        toggleBtn.BackgroundColor3 = THEME.danger
        startFishing()
    else
        toggleBtn.Text = "▶ START SMART FISHING"
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
        
        fishingInProgress = false
        waitingForUI = false
        uiAppeared = false
        
        if holdingClick then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            holdingClick = false
        end
        
        if autoMode then
            task.wait(3)
            updateStatus("Ready after respawn", THEME.success, "✅")
        end
    end)
end

-- Initialize system
local function initialize()
    log("Starting Advanced Fishing System v3.0...", "SUCCESS")
    
    handleCharacter()
    createUI()
    
    if toggleBtn then
        toggleBtn.MouseButton1Click:Connect(toggleFishing)
    end
    
    setupLootDetection()
    updateStats()
    
    if findRod() then
        updateStatus("Ready for smart fishing!", THEME.success, "✅")
    else
        updateStatus("Equip a fishing rod to start", THEME.warning, "⚠️")
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

-- Performance monitor
local function startMonitor()
    task.spawn(function()
        while true do
            task.wait(30)
            
            if autoMode then
                local memoryUsage = gcinfo()
                if memoryUsage > 50000 then
                    collectgarbage("collect")
                    log("Memory cleanup performed")
                end
                
                -- Reset stuck states
                if fishingInProgress and (tick() - lastCastTime) > PRECISION.fishingTimeout then
                    log("Fishing timeout - resetting stuck state", "WARNING")
                    fishingInProgress = false
                    waitingForUI = false
                    uiAppeared = false
                    
                    if holdingClick then
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        holdingClick = false
                    end
                end
                
                -- Log current state for debugging
                if fishingInProgress then
                    local elapsed = tick() - lastCastTime
                    log(string.format("State: Fishing=%s, WaitingUI=%s, UIAppeared=%s, Elapsed=%.1fs", 
                        tostring(fishingInProgress), tostring(waitingForUI), tostring(uiAppeared), elapsed))
                end
            end
        end
    end)
end

-- Main execution
local function main()
    local success, error = pcall(initialize)
    
    if success then
        print("🎣 FISHING HUB PRO+ v3.0 - Loaded Successfully!")
        print("✨ Enhanced with Smart Detection & Perfect Loop!")
        print("📊 Based on Real Data Analysis!")
        startMonitor()
    else
        warn("❌ Failed to initialize: " .. tostring(error))
        
        task.wait(3)
        local retrySuccess, retryError = pcall(initialize)
        if not retrySuccess then
            warn("❌ Retry failed: " .. tostring(retryError))
        else
            print("🔄 Successfully initialized on retry!")
            startMonitor()
        end
    end
end

-- Execute
main()
