local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
local ui = RefLib.new("autofish parkvoice", "rbxassetid://131165537896572", "af_ultra_safe")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInput = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local events = require(ReplicatedStorage.Shared.Modules.events)

local config = {
    enabled = false,
    strikeHandled = false,
    autoSell = false,
    autoSellInterval = 300,
    lastSell = 0,
}

local function getUI()
    local gui = player.PlayerGui:FindFirstChild("FishingUI")
    if not gui then return nil, nil, nil end
    local strikePrompt = gui:FindFirstChild("BuoyFrame") and gui.BuoyFrame:FindFirstChild("StrikePrompt")
    local catchingBar  = gui:FindFirstChild("CatchingBar")
    return gui, strikePrompt, catchingBar
end

local function simulateClick(down)
    local center = workspace.CurrentCamera.ViewportSize / 2
    VirtualInput:SendMouseButtonEvent(center.X, center.Y, 0, down, game, 1)
end

local function shouldCast()
    local state   = player:GetAttribute("fishingState")
    local hasBuoy = workspace.Temp:FindFirstChild(player.UserId .. ".buoy")
    local _, _, bar = getUI()
    return not state and not hasBuoy and not (bar and bar.Visible)
end

local function sellAll()
    events:Fire("sellFish")
    config.lastSell = os.clock()
end

-- ================================================================
-- minigame solver
-- ================================================================
local miniGameConnection = nil

local function startSolver()
    if miniGameConnection then
        miniGameConnection:Disconnect()
        miniGameConnection = nil
    end

    local _, _, catchingBar = getUI()
    if not catchingBar then return end

    local bar      = catchingBar:WaitForChild("Frame"):WaitForChild("Bar"):WaitForChild("Catch"):WaitForChild("Green")
    local fishIcon = catchingBar.Frame.Bar.Catch:WaitForChild("Marker")
    local barSize  = bar.Size.Y.Scale

    miniGameConnection = RunService.Heartbeat:Connect(function()
        local _, _, cb = getUI()

        if not cb or not cb.Visible then
            simulateClick(false)
            miniGameConnection:Disconnect()
            miniGameConnection = nil
            return
        end

        local barY      = bar.Position.Y.Scale
        local fishY     = fishIcon.Position.Y.Scale
        local barCenter = barY + (barSize / 2)

        if fishY < barCenter then
            simulateClick(true)
        else
            simulateClick(false)
        end
    end)
end

-- ================================================================
-- main loop
-- ================================================================
task.spawn(function()
    while true do
        task.wait(0.3)

        if not config.enabled then
            config.strikeHandled = false
            if miniGameConnection then
                miniGameConnection:Disconnect()
                miniGameConnection = nil
                simulateClick(false)
            end
            continue
        end

        if config.autoSell and (os.clock() - config.lastSell) >= config.autoSellInterval then
            sellAll()
        end

        local _, strikePrompt, catchingBar = getUI()

        if catchingBar and catchingBar.Visible then
            config.strikeHandled = false
            if not miniGameConnection then
                startSolver()
            end
            continue
        end

        if strikePrompt and strikePrompt.Visible and not config.strikeHandled then
            config.strikeHandled = true
            simulateClick(true)
            task.wait(0.1)
            simulateClick(false)

            local waited = 0
            while waited < 3 do
                task.wait(0.1)
                waited += 0.1
                local _, _, cb = getUI()
                if cb and cb.Visible then
                    startSolver()
                    break
                end
            end
            continue
        end

        if shouldCast() then
            config.strikeHandled = false
            simulateClick(true)
            task.wait(0.1)
            simulateClick(false)

            local waited = 0
            while waited < 5 do
                task.wait(0.5)
                waited += 0.5
                if player:GetAttribute("fishingState") == "waiting" then break end
            end
        end
    end
end)

-- ================================================================
-- ui
-- ================================================================
local tab = ui:Tab("farm")
local fishSec = tab:Section("auto fish")

fishSec:Toggle("enable", false, function(v)
    config.enabled = v
    if not v then
        simulateClick(false)
        if miniGameConnection then
            miniGameConnection:Disconnect()
            miniGameConnection = nil
        end
    end
end)

local sellSec = tab:Section("sell")

sellSec:Toggle("auto sell", false, function(v)
    config.autoSell = v
end)

sellSec:Slider("interval (seconds)", 60, 600, 300, function(v)
    config.autoSellInterval = v
end)

sellSec:Button("sell all", function()
    sellAll()
end)
