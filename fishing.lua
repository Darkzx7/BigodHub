-- ADVANCED AUTO FISHING SYSTEM - FIXED VERSION
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

-- Connections
local indicatorConnection = nil
local fishingLoop = nil

-- UI Elements
local gui = nil
local mainFrame = nil
local toggleBtn = nil
local statusLabel = nil
local statsFrame = nil

-- Precision Config
local PRECISION = {
    checkInterval = 0.016,
    safeMargin = 0.08,
    responseDelay = 0.05,
    castCooldown = 3,
    fishingTimeout = 70
}

-- Modern Theme
local THEME = {
    primary = Color3.fromRGB(88, 101, 242),
    secondary = Color3.fromRGB(114, 137, 218),
    success = Color3.fromRGB(67, 181, 129),
    warning = Color3.fromRGB(250, 166, 26),
    danger = Color3.fromRGB(237, 66, 69),
    bg_primary = Color3.fromRGB(32, 34, 37),
    bg_secondary = Color3.fromRGB(40, 43, 48),
    bg_tertiary = Color3.fromRGB(47, 49, 54),
    text_primary = Color3.fromRGB(255, 255, 255),
    text_secondary = Color3.fromRGB(185, 187, 190),
    text_muted = Color3.fromRGB(114, 118, 125),
    accent = Color3.fromRGB(255, 255, 255),
    border = Color3.fromRGB(79, 84, 92)
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
    end
    log(text)
end

-- Create Modern Button
local function createButton(parent, config)
    local button = Instance.new("TextButton")
    button.Name = config.name or "Button"
    button.Size = config.size or UDim2.new(0, 200, 0, 40)
    button.Position = config.position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = config.color or THEME.primary
    button.BorderSizePixel = 0
    button.Text = config.text or "Button"
    button.TextColor3 = THEME.text_primary
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = config.textSize or 14
    button.AutoButtonColor = false
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.border
    stroke.Thickness = 1
    stroke.Transparency = 0.8
    stroke.Parent = button
    
    -- Hover Effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(
                math.min(255, config.color.R * 255 + 20),
                math.min(255, config.color.G * 255 + 20), 
                math.min(255, config.color.B * 255 + 20)
            )
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = config.color
        }):Play()
    end)
    
    return button
end

-- Create Stat Card
local function createStatCard(parent, config)
    local card = Instance.new("Frame")
    card.Name = config.name
    card.Size = UDim2.new(0, 85, 1, 0)
    card.BackgroundColor3 = THEME.bg_secondary
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card
    
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 0.6, 0)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = config.icon
    icon.TextColor3 = config.color or THEME.text_secondary
    icon.TextSize = 16
    icon.Font = Enum.Font.Gotham
    icon.Parent = card
    
    local counter = Instance.new("TextLabel")
    counter.Name = "Counter"
    counter.Size = UDim2.new(1, 0, 0.4, 0)
    counter.Position = UDim2.new(0, 0, 0.6, 0)
    counter.BackgroundTransparency = 1
    counter.Text = "0"
    counter.TextColor3 = THEME.text_primary
    counter.TextSize = 14
    counter.Font = Enum.Font.GothamBold
    counter.Parent = card
    
    return card
end

-- Create Advanced UI
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
    
    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 200)
    mainFrame.Position = UDim2.new(1, -340, 0.5, -100)
    mainFrame.BackgroundColor3 = THEME.bg_primary
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = THEME.primary
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.7
    mainStroke.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = THEME.bg_secondary
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, THEME.primary),
        ColorSequenceKeypoint.new(1, THEME.secondary)
    }
    headerGradient.Rotation = 45
    headerGradient.Parent = header
    
    -- Title
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.Position = UDim2.new(0.05, 0, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎣 ADVANCED FISHING"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextColor3 = THEME.text_primary
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = header
    
    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -38, 0.5, -15)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.BackgroundTransparency = 0.9
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = "─"
    minimizeBtn.TextColor3 = THEME.text_primary
    minimizeBtn.TextSize = 16
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = header
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(1, 0)
    minCorner.Parent = minimizeBtn
    
    -- Toggle Button
    toggleBtn = createButton(mainFrame, {
        name = "ToggleButton",
        size = UDim2.new(0.9, 0, 0, 45),
        position = UDim2.new(0.05, 0, 0.3, 0),
        text = "▶ START AUTO FISHING",
        textSize = 14,
        color = THEME.success
    })
    
    -- Status Container
    local statusContainer = Instance.new("Frame")
    statusContainer.Size = UDim2.new(0.9, 0, 0, 25)
    statusContainer.Position = UDim2.new(0.05, 0, 0.6, 0)
    statusContainer.BackgroundColor3 = THEME.bg_tertiary
    statusContainer.BorderSizePixel = 0
    statusContainer.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusContainer
    
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 1, 0)
    statusLabel.Position = UDim2.new(0, 5, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "● Ready to fish"
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextColor3 = THEME.text_secondary
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = statusContainer
    
    -- Stats Frame
    statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(0.9, 0, 0, 40)
    statsFrame.Position = UDim2.new(0.05, 0, 0.78, 0)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = mainFrame
    
    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceEvenly
    statsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    statsLayout.Padding = UDim.new(0, 8)
    statsLayout.Parent = statsFrame
    
    -- Stat Cards
    createStatCard(statsFrame, {
        name = "FishCard",
        icon = "🐟",
        color = THEME.success
    })
    
    createStatCard(statsFrame, {
        name = "TrashCard",
        icon = "🗑️",
        color = THEME.warning
    })
    
    createStatCard(statsFrame, {
        name = "DiamondCard",
        icon = "💎",
        color = THEME.primary
    })
    
    -- Minimize Function
    local elementsToHide = {toggleBtn, statusContainer, statsFrame}
    
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        local targetSize = minimized and UDim2.new(0, 200, 0, 45) or UDim2.new(0, 320, 0, 200)
        local targetText = minimized and "+" or "─"
        local targetTitle = minimized and "FISHING" or "🎣 ADVANCED FISHING"
        
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {
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
    
    log("Advanced UI created successfully")
end

-- Fishing Functions
local function findRod()
    return character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod")
end

local function equipRod()
    local rod = findRod()
    if rod then
        if rod.Parent == backpack then
            rod.Parent = character
            task.wait(0.5)
            log("Rod equipped")
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
    
    if fishingInProgress then
        return false
    end
    
    local rod = equipRod()
    if rod and rod.Parent == character then
        rod:Activate()
        lastCastTime = currentTime
        fishingInProgress = true
        totalCasts = totalCasts + 1
        
        updateStatus("Casting line... 🎣", THEME.primary, "🎯")
        log("Line cast successfully (Cast #" .. totalCasts .. ")")
        
        task.spawn(function()
            task.wait(PRECISION.fishingTimeout)
            if fishingInProgress then
                fishingInProgress = false
                log("Fishing timeout reached")
            end
        end)
        
        return true
    else
        updateStatus("No fishing rod found!", THEME.danger, "❌")
        return false
    end
end

-- Indicator Control
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

-- Update Stats
local function updateStats()
    if not statsFrame then return end
    
    local fishCard = statsFrame:FindFirstChild("FishCard")
    local trashCard = statsFrame:FindFirstChild("TrashCard")
    local diamondCard = statsFrame:FindFirstChild("DiamondCard")
    
    if fishCard then
        local counter = fishCard:FindFirstChild("Counter")
        if counter then counter.Text = tostring(fishCount) end
    end
    
    if trashCard then
        local counter = trashCard:FindFirstChild("Counter")
        if counter then counter.Text = tostring(trashCount) end
    end
    
    if diamondCard then
        local counter = diamondCard:FindFirstChild("Counter")
        if counter then counter.Text = tostring(diamondCount) end
    end
end

-- Loot Detection
local function setupLootDetection()
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
                                fishingInProgress = false
                            end
                        end
                    end)
                    log("Loot detection connected")
                end
            end
        end)
        
        if not success then
            log("Loot detection failed: " .. tostring(err))
        end
    end)
end

-- Auto Fishing
local function startFishing()
    updateStatus("Starting fishing system...", THEME.warning, "⚙️")
    
    fishingLoop = task.spawn(function()
        while autoMode do
            if not findRod() then
                updateStatus("Please equip a fishing rod!", THEME.danger, "❌")
                task.wait(5)
                continue
            end
            
            if not fishingInProgress then
                local success = castLine()
                if success then
                    updateStatus("Fishing in progress... 🎣", THEME.success, "🎣")
                else
                    task.wait(3)
                end
            end
            
            task.wait(2)
        end
    end)
    
    indicatorConnection = RunService.Heartbeat:Connect(controlIndicator)
    
    updateStatus("Auto Fishing Active! 🚀", THEME.success, "🚀")
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
    updateStatus("Auto Fishing Stopped", THEME.text_secondary, "⏸️")
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
end

-- Character Management
local function handleCharacter()
    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        backpack = player:WaitForChild("Backpack")
        log("Character respawned")
        
        if autoMode then
            task.wait(3)
            fishingInProgress = false
        end
    end)
end

-- Initialize System
local function initialize()
    log("Starting Advanced Fishing System...")
    
    handleCharacter()
    createUI()
    
    if toggleBtn then
        toggleBtn.MouseButton1Click:Connect(toggleFishing)
    end
    
    setupLootDetection()
    updateStats()
    
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
                local memoryUsage = gcinfo()
                if memoryUsage > 50000 then
                    collectgarbage("collect")
                end
                
                if fishingInProgress and (tick() - lastCastTime) > PRECISION.fishingTimeout then
                    fishingInProgress = false
                end
            end
        end
    end)
end

-- Main Execution
local function main()
    local success, error = pcall(initialize)
    
    if success then
        print("🎣 ADVANCED FISHING HUB - Loaded Successfully!")
        startMonitor()
    else
        warn("❌ Failed to initialize: " .. tostring(error))
        
        task.wait(3)
        local retrySuccess, retryError = pcall(initialize)
        if not retrySuccess then
            warn("❌ Retry failed: " .. tostring(retryError))
        end
    end
end

-- Execute
main()
