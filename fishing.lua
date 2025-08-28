-- ADVANCED AUTO FISHING SYSTEM - PERFECT VERSION
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack")

-- State
local autoMode = false
local holdingClick = false
local minimized = false
local fishCount = 0
local trashCount = 0
local diamondCount = 0
local totalCasts = 0
local lastCastTime = 0
local fishingInProgress = false
local lastClickTime = 0
local waitingForCatch = false

-- Connections
local indicatorConnection = nil
local fishingLoop = nil
local catchConnection = nil

-- UI Elements
local gui = nil
local mainFrame = nil
local toggleBtn = nil
local statusLabel = nil
local statsFrame = nil

-- Precision Config
local PRECISION = {
    checkInterval = 0.016,
    safeMargin = 0.12,
    responseDelay = 0.03,
    castCooldown = 2.5,
    fishingTimeout = 60,
    catchDelay = 2
}

-- Purple Theme
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
    local logMessage = string.format("[%s] [AUTO FISHING] %s", timestamp, tostring(message))
    
    if level == "ERROR" then
        warn(logMessage)
    else
        print(logMessage)
    end
end

-- Update Status
local function updateStatus(text, color, icon)
    if statusLabel then
        statusLabel.Text = (icon or "●") .. " " .. text
        statusLabel.TextColor3 = color or THEME.text_secondary
        
        -- Animate status change
        local tween = TweenService:Create(statusLabel, TweenInfo.new(0.3), {
            TextTransparency = 0
        })
        tween:Play()
    end
    log(text)
end

-- Create Modern Button with Glow
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
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button
    
    -- Gradient effect
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
    
    -- Glow effect
    local glow = Instance.new("UIStroke")
    glow.Color = THEME.glow
    glow.Thickness = 2
    glow.Transparency = 0.7
    glow.Parent = button
    
    -- Hover Effects
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(button, TweenInfo.new(0.2), {
            Size = UDim2.new(config.size.X.Scale, config.size.X.Offset + 5, config.size.Y.Scale, config.size.Y.Offset + 2)
        })
        local glowTween = TweenService:Create(glow, TweenInfo.new(0.2), {
            Transparency = 0.3
        })
        hoverTween:Play()
        glowTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local hoverTween = TweenService:Create(button, TweenInfo.new(0.2), {
            Size = config.size
        })
        local glowTween = TweenService:Create(glow, TweenInfo.new(0.2), {
            Transparency = 0.7
        })
        hoverTween:Play()
        glowTween:Play()
    end)
    
    return button
end

-- Create Enhanced Stat Card
local function createStatCard(parent, config)
    local card = Instance.new("Frame")
    card.Name = config.name
    card.Size = UDim2.new(0, 85, 1, 0)
    card.BackgroundColor3 = THEME.bg_card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    -- Subtle glow
    local stroke = Instance.new("UIStroke")
    stroke.Color = config.color or THEME.border
    stroke.Thickness = 1
    stroke.Transparency = 0.8
    stroke.Parent = card
    
    -- Icon with glow
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
    
    -- Counter
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
    -- Clean old UI
    if player.PlayerGui:FindFirstChild("AdvancedFishingHub") then
        player.PlayerGui.AdvancedFishingHub:Destroy()
        task.wait(0.1)
    end
    
    -- Main Container
    gui = Instance.new("ScreenGui")
    gui.Name = "AdvancedFishingHub"
    gui.ResetOnSpawn = false
    gui.Parent = player.PlayerGui
    
    -- Main Frame with enhanced styling
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 340, 0, 220)
    mainFrame.Position = UDim2.new(1, -360, 0.5, -110)
    mainFrame.BackgroundColor3 = THEME.bg_primary
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    -- Enhanced corner radius
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = mainFrame
    
    -- Glowing border
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = THEME.primary
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.5
    mainStroke.Parent = mainFrame
    
    -- Animated glow effect
    task.spawn(function()
        while mainFrame.Parent do
            for i = 1, 60 do
                if mainStroke and mainStroke.Parent then
                    mainStroke.Transparency = 0.3 + (math.sin(i * 0.1) * 0.2)
                end
                task.wait(0.05)
            end
        end
    end)
    
    -- Header with gradient
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = THEME.bg_secondary
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    -- Purple gradient
    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, THEME.primary),
        ColorSequenceKeypoint.new(0.5, THEME.secondary),
        ColorSequenceKeypoint.new(1, THEME.accent)
    }
    headerGradient.Rotation = 90
    headerGradient.Parent = header
    
    -- Title with glow effect
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.Position = UDim2.new(0.05, 0, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎣 FISHING HUB PRO"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextColor3 = THEME.text_primary
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.TextYAlignment = Enum.TextYAlignment.Center
    titleText.Parent = header
    
    -- Minimize Button
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
    
    -- Toggle Button with enhanced styling
    toggleBtn = createButton(mainFrame, {
        name = "ToggleButton",
        size = UDim2.new(0.9, 0, 0, 48),
        position = UDim2.new(0.05, 0, 0.28, 0),
        text = "▶ START AUTO FISHING",
        textSize = 16,
        color = THEME.success
    })
    
    -- Status Container with glow
    local statusContainer = Instance.new("Frame")
    statusContainer.Size = UDim2.new(0.9, 0, 0, 30)
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
    statusLabel.Text = "● Ready to fish"
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextColor3 = THEME.text_secondary
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    statusLabel.Parent = statusContainer
    
    -- Stats Frame
    statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(0.9, 0, 0, 45)
    statsFrame.Position = UDim2.new(0.05, 0, 0.75, 0)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = mainFrame
    
    -- Stat Cards with manual positioning
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
    
    -- Minimize Function
    local elementsToHide = {toggleBtn, statusContainer, statsFrame}
    
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        local targetSize = minimized and UDim2.new(0, 220, 0, 50) or UDim2.new(0, 340, 0, 220)
        local targetText = minimized and "+" or "─"
        local targetTitle = minimized and "FISHING HUB" or "🎣 FISHING HUB PRO"
        
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
    
    log("Enhanced Purple UI created successfully")
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

local function castLine()
    local currentTime = tick()
    if currentTime - lastCastTime < PRECISION.castCooldown then
        return false
    end
    
    if fishingInProgress or waitingForCatch then
        return false
    end
    
    local rod = equipRod()
    if rod and rod.Parent == character then
        rod:Activate()
        lastCastTime = currentTime
        fishingInProgress = true
        waitingForCatch = false
        totalCasts = totalCasts + 1
        
        updateStatus("Casting line... (Cast #" .. totalCasts .. ")", THEME.primary, "🎯")
        log("Line cast successfully (Cast #" .. totalCasts .. ")")
        
        -- Reset fishing after timeout
        task.spawn(function()
            task.wait(PRECISION.fishingTimeout)
            if fishingInProgress then
                fishingInProgress = false
                waitingForCatch = false
                log("Fishing timeout - resetting")
            end
        end)
        
        return true
    else
        updateStatus("No fishing rod found!", THEME.danger, "❌")
        return false
    end
end

-- Enhanced Indicator Control
local function getFishingUI()
    local fishing = workspace:FindFirstChild("fishing")
    if not fishing then return nil end
    
    local bar = fishing:FindFirstChild("bar")
    if not bar then return nil end
    
    return {
        safeArea = bar:FindFirstChild("safeArea"),
        indicator = bar:FindFirstChild("indicator")
    }
end

local function controlIndicator()
    if not autoMode then return end
    
    local fishingUI = getFishingUI()
    if not fishingUI or not fishingUI.safeArea or not fishingUI.indicator then 
        return 
    end
    
    local safeArea = fishingUI.safeArea
    local indicator = fishingUI.indicator
    
    local safeY = safeArea.Position.Y.Scale
    local safeHeight = safeArea.Size.Y.Scale
    local indicatorY = indicator.Position.Y.Scale
    
    local margin = safeHeight * PRECISION.safeMargin
    local safeTop = safeY + margin
    local safeBottom = safeY + safeHeight - margin
    
    local needsClick = indicatorY < safeTop or indicatorY > safeBottom
    local currentTime = tick()
    
    if needsClick and not holdingClick and (currentTime - lastClickTime) > PRECISION.responseDelay then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        holdingClick = true
        lastClickTime = currentTime
        
    elseif not needsClick and holdingClick and (currentTime - lastClickTime) > PRECISION.responseDelay then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        holdingClick = false
        lastClickTime = currentTime
    end
end

-- Enhanced Stats Update with Animation
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
                
                -- Animate the update
                local originalSize = counter.TextSize
                counter.TextSize = originalSize + 4
                
                TweenService:Create(counter, TweenInfo.new(0.3), {
                    TextSize = originalSize
                }):Play()
            end
        end
    end
    
    animateCounter(fishCard, fishCount)
    animateCounter(trashCard, trashCount)
    animateCounter(diamondCard, diamondCount)
end

-- Enhanced Loot Detection
local function setupLootDetection()
    -- Method 1: Remote Events
    task.spawn(function()
        local success, err = pcall(function()
            local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
            if remoteEvents then
                local replicatedValue = remoteEvents:FindFirstChild("replicatedValue")
                if replicatedValue then
                    replicatedValue.OnClientEvent:Connect(function(data)
                        if data and type(data) == "table" then
                            local updated = false
                            
                            if data.fishing then
                                fishCount = data.fishing.Fish or fishCount
                                trashCount = data.fishing.Trash or trashCount
                                diamondCount = data.fishing.Diamond or diamondCount
                                updated = true
                            elseif data.Fish or data.Trash or data.Diamond then
                                fishCount = data.Fish or fishCount
                                trashCount = data.Trash or trashCount
                                diamondCount = data.Diamond or diamondCount
                                updated = true
                            end
                            
                            if updated then
                                updateStats()
                                log("Stats updated: Fish=" .. fishCount .. ", Trash=" .. trashCount .. ", Diamonds=" .. diamondCount)
                                
                                -- Reset fishing state after catch
                                task.wait(PRECISION.catchDelay)
                                fishingInProgress = false
                                waitingForCatch = false
                            end
                        end
                    end)
                    log("Loot detection (RemoteEvents) connected")
                end
            end
        end)
        
        if not success then
            log("RemoteEvents loot detection failed: " .. tostring(err))
        end
    end)
    
    -- Method 2: Leaderstats monitoring
    task.spawn(function()
        local success, err = pcall(function()
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                local fish = leaderstats:FindFirstChild("Fish")
                local trash = leaderstats:FindFirstChild("Trash") 
                local diamond = leaderstats:FindFirstChild("Diamond")
                
                if fish then
                    fish.Changed:Connect(function(newValue)
                        fishCount = tonumber(newValue) or fishCount
                        updateStats()
                        fishingInProgress = false
                        waitingForCatch = false
                        log("Fish count updated: " .. fishCount)
                    end)
                end
                
                if trash then
                    trash.Changed:Connect(function(newValue)
                        trashCount = tonumber(newValue) or trashCount
                        updateStats()
                        fishingInProgress = false
                        waitingForCatch = false
                        log("Trash count updated: " .. trashCount)
                    end)
                end
                
                if diamond then
                    diamond.Changed:Connect(function(newValue)
                        diamondCount = tonumber(newValue) or diamondCount
                        updateStats()
                        fishingInProgress = false
                        waitingForCatch = false
                        log("Diamond count updated: " .. diamondCount)
                    end)
                end
                
                log("Loot detection (leaderstats) connected")
            end
        end)
        
        if not success then
            log("Leaderstats loot detection failed: " .. tostring(err))
        end
    end)
    
    -- Method 3: UI monitoring for catch completion
    task.spawn(function()
        while true do
            if fishingInProgress and not waitingForCatch then
                local fishingUI = getFishingUI()
                if not fishingUI or not fishingUI.safeArea then
                    -- Fishing UI disappeared, likely caught something
                    waitingForCatch = true
                    task.wait(PRECISION.catchDelay)
                    fishingInProgress = false
                    waitingForCatch = false
                    log("Fishing completed - UI disappeared")
                end
            end
            task.wait(0.5)
        end
    end)
end

-- Enhanced Auto Fishing Loop
local function startFishing()
    updateStatus("Initializing fishing system...", THEME.warning, "⚙️")
    
    fishingLoop = task.spawn(function()
        while autoMode do
            -- Check for rod
            if not findRod() then
                updateStatus("Please equip a fishing rod!", THEME.danger, "❌")
                task.wait(5)
                continue
            end
            
            -- Cast line if not fishing
            if not fishingInProgress and not waitingForCatch then
                local success = castLine()
                if success then
                    updateStatus("Fishing in progress... 🎣", THEME.success, "🎣")
                else
                    task.wait(1)
                end
            else
                updateStatus("Waiting for catch... ⏳", THEME.accent, "⏳")
            end
            
            task.wait(1)
        end
    end)
    
    -- Start indicator control
    indicatorConnection = RunService.Heartbeat:Connect(controlIndicator)
    
    updateStatus("Auto Fishing Active! 🚀", THEME.success, "🚀")
    log("Fishing system started successfully")
end

local function stopFishing()
    updateStatus("Stopping fishing...", THEME.warning, "⏹️")
    
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
    waitingForCatch = false
    updateStatus("Auto Fishing Stopped", THEME.text_secondary, "⏸️")
    log("Fishing system stopped")
end

-- Toggle Function
local function toggleFishing()
    autoMode = not autoMode
    
    if autoMode then
        toggleBtn.Text = "⏹ STOP FISHING"
        toggleBtn.BackgroundColor3 = THEME.danger
        startFishing()
    else
        toggleBtn.Text = "▶ START AUTO FISHING"
        toggleBtn.BackgroundColor3 = THEME.success
        stopFishing()
    end
    
    log("Fishing toggled: " .. (autoMode and "ON" or "OFF"))
end

-- Character Management
local function handleCharacter()
    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        backpack = player:WaitForChild("Backpack")
        log("Character respawned - resetting states")
        
        fishingInProgress = false
        waitingForCatch = false
        
        if autoMode then
            task.wait(3)
            updateStatus("Ready after respawn", THEME.success, "✅")
        end
    end)
end

-- Initialize System
local function initialize()
    log("Starting Advanced Fishing System v2.0...")
    
    handleCharacter()
    createUI()
    
    if toggleBtn then
        toggleBtn.MouseButton1Click:Connect(toggleFishing)
    end
    
    setupLootDetection()
    updateStats()
    
    -- Initial status
    if findRod() then
        updateStatus("Ready to fish! 🎣", THEME.success, "✅")
    else
        updateStatus("Equip a fishing rod to start", THEME.warning, "⚠️")
    end
    
    log("System initialized successfully!")
    return true
end

-- Cleanup
player.AncestryChanged:Connect(function()
    if not player.Parent and autoMode then
        stopFishing()
    end
end)

-- Performance Monitor
local function startMonitor()
    task.spawn(function()
        while true do
            task.wait(30)
            
            if autoMode then
                -- Memory cleanup
                local memoryUsage = gcinfo()
                if memoryUsage > 50000 then
                    collectgarbage("collect")
                    log("Memory cleanup performed")
                end
                
                -- Reset stuck states
                if fishingInProgress and (tick() - lastCastTime) > PRECISION.fishingTimeout then
                    fishingInProgress = false
                    waitingForCatch = false
                    log("Reset stuck fishing state")
                end
            end
        end
    end)
end

-- Main Execution
local function main()
    local success, error = pcall(initialize)
    
    if success then
        print("🎣 FISHING HUB PRO v2.0 - Loaded Successfully!")
        print("✨ Enhanced with Purple Theme & Perfect Auto-Loop!")
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
