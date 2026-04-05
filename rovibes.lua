local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
if not RefLib then error("[EggCollector] RefLib failed to load.") end

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local player         = Players.LocalPlayer
local playerGui      = player:WaitForChild("PlayerGui")

local ui = RefLib.new("egg collector", "rbxassetid://131165537896572", "egg_collector_cfg")

-- ══════════════════════════════════════════════════════════════════════════════
-- ZONES — RoVibes (positions from scanner)
-- ══════════════════════════════════════════════════════════════════════════════

local ZONES = {
    { name = "Zone A",  pos = Vector3.new(-207, 4,  872) },
    { name = "Zone B",  pos = Vector3.new( 190, 9,  563) },
    { name = "Zone C",  pos = Vector3.new(  -6, 16, 563) },
    { name = "Zone D",  pos = Vector3.new( -57, 8,  672) },
    { name = "Zone E",  pos = Vector3.new( 343, 6,  762) },
    { name = "Zone F",  pos = Vector3.new( -64, 19, 454) },
    { name = "Zone G",  pos = Vector3.new(-137, 25, 781) },
    { name = "Zone H",  pos = Vector3.new(-209, 24, 774) },
}

local ZONE_RADIUS   = 120   -- stud radius per zone
local ZONE_WAIT     = 60    -- seconds to wait in zone before moving on if no eggs
local COLLECT_DELAY = 0.35  -- seconds between each egg

-- ══════════════════════════════════════════════════════════════════════════════
-- TOAST NOTIFICATION SYSTEM — custom, replaces RefLib toast
-- ══════════════════════════════════════════════════════════════════════════════

local toastGui = Instance.new("ScreenGui")
toastGui.Name = "EggToasts"
toastGui.ResetOnSpawn = false
toastGui.IgnoreGuiInset = true
toastGui.DisplayOrder = 9999
toastGui.Parent = playerGui

local toastHolder = Instance.new("Frame")
toastHolder.Name = "Holder"
toastHolder.Size = UDim2.new(0, 320, 1, 0)
toastHolder.Position = UDim2.new(1, -330, 0, 0)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = toastGui

local toastLayout = Instance.new("UIListLayout")
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastHolder

local toastPad = Instance.new("UIPadding")
toastPad.PaddingBottom = UDim.new(0, 16)
toastPad.PaddingRight  = UDim.new(0, 0)
toastPad.Parent = toastHolder

local TOAST_COLORS = {
    info    = { bg = Color3.fromRGB(30,  30,  45),  accent = Color3.fromRGB(80, 140, 255) },
    success = { bg = Color3.fromRGB(20,  40,  30),  accent = Color3.fromRGB(60, 210, 110) },
    warn    = { bg = Color3.fromRGB(45,  35,  15),  accent = Color3.fromRGB(255, 190, 50) },
    error   = { bg = Color3.fromRGB(45,  20,  20),  accent = Color3.fromRGB(220, 70,  70) },
    egg     = { bg = Color3.fromRGB(35,  25,  50),  accent = Color3.fromRGB(200, 130, 255) },
}

local function showToast(title, body, kind, duration)
    kind     = kind or "info"
    duration = duration or 3.5
    local c  = TOAST_COLORS[kind] or TOAST_COLORS.info

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 56)
    frame.BackgroundColor3 = c.bg
    frame.BorderSizePixel  = 0
    frame.BackgroundTransparency = 1
    frame.Parent = toastHolder
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    -- Left accent bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, -12)
    bar.Position = UDim2.new(0, 6, 0, 6)
    bar.BackgroundColor3 = c.accent
    bar.BorderSizePixel = 0
    bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -24, 0, 20)
    titleLbl.Position = UDim2.new(0, 16, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = c.accent
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title
    titleLbl.Parent = frame

    -- Body
    local bodyLbl = Instance.new("TextLabel")
    bodyLbl.Size = UDim2.new(1, -24, 0, 18)
    bodyLbl.Position = UDim2.new(0, 16, 0, 28)
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Font = Enum.Font.Gotham
    bodyLbl.TextSize = 11
    bodyLbl.TextColor3 = Color3.fromRGB(190, 190, 210)
    bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
    bodyLbl.Text = body
    bodyLbl.Parent = frame

    -- Slide in
    frame.Position = UDim2.new(1, 20, 0, 0)
    frame.BackgroundTransparency = 0
    TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
    }):Play()

    -- Auto dismiss
    task.delay(duration, function()
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(titleLbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        TweenService:Create(bodyLbl,  TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        TweenService:Create(bar,      TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        task.wait(0.35)
        frame:Destroy()
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════════════════════════════════

local collectOn    = false
local collected    = 0
local skipped      = 0
local collectDelay = COLLECT_DELAY
local statusLabel  = nil

-- ══════════════════════════════════════════════════════════════════════════════
-- CORE FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════════════

local function myHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function isAlive()
    local chr = player.Character; if not chr then return false end
    local hum = chr:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function setCollision(on)
    local chr = player.Character; if not chr then return end
    for _, p in ipairs(chr:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.CanCollide = on end) end
    end
end

local function teleportTo(pos)
    local hrp = myHRP(); if not hrp then return end
    setCollision(false)
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    task.wait(0.1)
    setCollision(true)
end

local function findEggsNear(center, radius)
    local eggs = {}
    local seen  = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj.Name == "EggTemplate" and not seen[obj] and obj.Parent then
                local ovo = obj:FindFirstChild("Ovo") or obj:FindFirstChild("Ovo2")
                if ovo and ovo:IsA("BasePart") then
                    local dist = (ovo.Position - center).Magnitude
                    if dist <= radius then
                        seen[obj] = true
                        table.insert(eggs, { model = obj, part = ovo, pos = ovo.Position })
                    end
                end
            end
        end)
    end
    table.sort(eggs, function(a, b)
        return (a.pos - center).Magnitude < (b.pos - center).Magnitude
    end)
    return eggs
end

local function collectEgg(eggData)
    local hrp = myHRP(); if not hrp then return false end
    if not eggData.model.Parent then return false end
    local part = eggData.model:FindFirstChild("Ovo") or eggData.model:FindFirstChild("Ovo2")
    if not part or not part.Parent then return false end

    local target = part.Position + Vector3.new(0, 2.5, 0)
    setCollision(false)
    hrp.CFrame = CFrame.new(target)
    task.wait(0.06)
    hrp = myHRP()
    if hrp then
        hrp.CFrame = CFrame.new(target + Vector3.new(0.4, 0, 0))
        task.wait(0.05)
        hrp = myHRP()
        if hrp then hrp.CFrame = CFrame.new(target) end
        task.wait(0.05)
    end
    setCollision(true)
    return true
end

local function updateStatus()
    if statusLabel then
        statusLabel.Set("collected: "..collected.."   skipped: "..skipped)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MAIN LOOP — teleport to zone, wait up to 60s for eggs, move on
-- ══════════════════════════════════════════════════════════════════════════════

local function collectLoop()
    collected = 0
    skipped   = 0
    updateStatus()

    while collectOn do
        if not isAlive() then
            showToast("Waiting", "Dead — waiting for respawn...", "error", 3)
            task.wait(2)
            continue
        end

        for _, zone in ipairs(ZONES) do
            if not collectOn then break end
            if not isAlive() then break end

            -- Teleport to zone
            teleportTo(zone.pos)
            showToast("Moved to "..zone.name, "Scanning for eggs nearby...", "info", 3)

            -- Wait up to ZONE_WAIT seconds for eggs to appear
            local waited    = 0
            local foundAny  = false

            while collectOn and waited < ZONE_WAIT do
                if not isAlive() then break end

                local eggs = findEggsNear(zone.pos, ZONE_RADIUS)

                if #eggs > 0 then
                    foundAny = true
                    showToast(zone.name.." — "..#eggs.." egg(s)", "Collecting...", "egg", 4)

                    for _, eggData in ipairs(eggs) do
                        if not collectOn then break end
                        if not isAlive() then break end
                        if collectEgg(eggData) then
                            collected = collected + 1
                        else
                            skipped = skipped + 1
                        end
                        updateStatus()
                        task.wait(collectDelay)
                    end

                    -- After collecting, keep watching this zone for new spawns
                    -- until the zone wait expires
                end

                task.wait(4)  -- recheck every 4s within the zone
                waited = waited + 4
            end

            if not foundAny then
                showToast(zone.name.." — no eggs", "Moving to next zone...", "warn", 3)
            else
                showToast(zone.name.." — done", "Total collected: "..collected, "success", 3)
            end

            task.wait(1)
        end

        -- Full cycle complete
        if collectOn then
            showToast("Cycle complete", "Collected: "..collected.." | Restarting...", "success", 4)
            task.wait(2)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NUMERIC INPUT POPUP — shows when user clicks the value next to slider
-- ══════════════════════════════════════════════════════════════════════════════

local function makeNumericInput(currentVal, minVal, maxVal, onConfirm)
    local popup = Instance.new("ScreenGui")
    popup.Name = "NumericInput"
    popup.ResetOnSpawn = false
    popup.DisplayOrder = 99999
    popup.IgnoreGuiInset = true
    popup.Parent = playerGui

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0
    backdrop.Parent = popup

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 220, 0, 110)
    box.Position = UDim2.new(0.5, -110, 0.5, -55)
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
    box.BorderSizePixel = 0
    box.Parent = popup
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 140, 255)
    stroke.Thickness = 1.5
    stroke.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 28)
    lbl.Position = UDim2.new(0, 0, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(160, 180, 255)
    lbl.Text = "Enter value ("..minVal.." – "..maxVal..")"
    lbl.Parent = box

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 0, 32)
    input.Position = UDim2.new(0, 10, 0, 38)
    input.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    input.BorderSizePixel = 0
    input.Font = Enum.Font.GothamBold
    input.TextSize = 14
    input.TextColor3 = Color3.new(1, 1, 1)
    input.PlaceholderText = tostring(currentVal)
    input.Text = tostring(currentVal)
    input.ClearTextOnFocus = true
    input.Parent = box
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    local function confirm()
        local num = tonumber(input.Text)
        if num then
            num = math.clamp(math.floor(num), minVal, maxVal)
            onConfirm(num)
        end
        popup:Destroy()
    end

    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -20, 0, 28)
    btnRow.Position = UDim2.new(0, 10, 0, 76)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent = box

    local btnOk = Instance.new("TextButton")
    btnOk.Size = UDim2.new(0.48, 0, 1, 0)
    btnOk.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
    btnOk.BorderSizePixel = 0
    btnOk.Font = Enum.Font.GothamBold
    btnOk.TextSize = 12
    btnOk.TextColor3 = Color3.new(1,1,1)
    btnOk.Text = "OK"
    btnOk.Parent = btnRow
    Instance.new("UICorner", btnOk).CornerRadius = UDim.new(0, 6)
    btnOk.Activated:Connect(confirm)

    local btnCancel = Instance.new("TextButton")
    btnCancel.Size = UDim2.new(0.48, 0, 1, 0)
    btnCancel.Position = UDim2.new(0.52, 0, 0, 0)
    btnCancel.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
    btnCancel.BorderSizePixel = 0
    btnCancel.Font = Enum.Font.GothamBold
    btnCancel.TextSize = 12
    btnCancel.TextColor3 = Color3.new(1,1,1)
    btnCancel.Text = "Cancel"
    btnCancel.Parent = btnRow
    Instance.new("UICorner", btnCancel).CornerRadius = UDim.new(0, 6)
    btnCancel.Activated:Connect(function() popup:Destroy() end)

    input.FocusLost:Connect(function(enter)
        if enter then confirm() end
    end)

    task.wait(0.05)
    input:CaptureFocus()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════════════════════════════════

local tab = ui:Tab("eggs", "rbxassetid://131165537896572")
local sec = tab:Section("auto egg collector — RoVibes")

statusLabel = sec:Button("collected: 0   skipped: 0", function() end)

sec:Divider("farm")

local t_collect = sec:Toggle("auto collect eggs", false, function(v)
    collectOn = v
    if v then
        task.spawn(collectLoop)
        showToast("Egg Farm Started", "Scanning "..#ZONES.." zones — 60s per zone", "success", 4)
    else
        showToast("Egg Farm Stopped", "Total collected: "..collected, "info", 3)
    end
end)
ui:CfgRegister("egg_collect", function() return collectOn end, function(v) t_collect.Set(v) end)

-- Slider + numeric input button side by side
sec:Divider("delay between eggs")

local currentDelayTicks = 7  -- default: 7 * 0.05 = 0.35s

local sliderRef = sec:Slider("delay (x0.05s)  [ click # to type ]", 1, 20, currentDelayTicks, function(v)
    currentDelayTicks = v
    collectDelay = v * 0.05
end)
ui:CfgRegister("egg_delay", function() return currentDelayTicks end, function(v) sliderRef.Set(v) end)

-- Button next to slider that opens numeric input
sec:Button("✎ type delay value  (current: "..currentDelayTicks..")", function()
    makeNumericInput(currentDelayTicks, 1, 20, function(val)
        currentDelayTicks = val
        collectDelay = val * 0.05
        sliderRef.Set(val)
        showToast("Delay updated", val.." ticks = "..(val*0.05).."s per egg", "info", 2.5)
    end)
end)

sec:Divider("manual teleport + collect")

for _, zone in ipairs(ZONES) do
    local z = zone
    sec:Button("→ "..z.name, function()
        if not isAlive() then
            showToast("Can't teleport", "You are dead", "error", 2)
            return
        end
        teleportTo(z.pos)
        showToast("Teleported to "..z.name, "Collecting eggs nearby...", "egg", 3)
        task.spawn(function()
            local eggs = findEggsNear(z.pos, ZONE_RADIUS)
            if #eggs == 0 then
                showToast(z.name.." — empty", "No eggs found in this zone", "warn", 3)
                return
            end
            for _, eggData in ipairs(eggs) do
                if collectEgg(eggData) then collected = collected + 1
                else skipped = skipped + 1 end
                updateStatus()
                task.wait(collectDelay)
            end
            showToast(z.name.." — done", "Collected: "..collected.." total", "success", 3)
        end)
    end)
end

sec:Divider("utils")
sec:Button("reset counter", function()
    collected = 0; skipped = 0; updateStatus()
    showToast("Counter reset", "Back to zero", "info", 2)
end)

local tabCfg = ui:Tab("config", "rbxassetid://131165537896572")
ui:BuildConfigTab(tabCfg, "egg_collector_cfg")
