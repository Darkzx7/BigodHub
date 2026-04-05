local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
if not RefLib then error("[EggCollector] RefLib failed to load.") end

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local player         = Players.LocalPlayer
local playerGui      = player:WaitForChild("PlayerGui")

local UI_ASSET_ID = "rbxassetid://131165537896572"

local ui = RefLib.new("egg collector", UI_ASSET_ID, "egg_collector_cfg")

-- ══════════════════════════════════════════════════════════════════════════════
-- ZONES
-- ══════════════════════════════════════════════════════════════════════════════

local ZONES = {
    { name = "Zone A",  pos = Vector3.new(-207, 4,   872) },
    { name = "Zone B",  pos = Vector3.new( 280, 9,   480) },
    { name = "Zone C",  pos = Vector3.new(  -6, 16,  490) },
    { name = "Zone D",  pos = Vector3.new(-120, 8,   650) },
    { name = "Zone E",  pos = Vector3.new( 420, 6,   720) },
    { name = "Zone F",  pos = Vector3.new( -64, 19,  350) },
    { name = "Zone G",  pos = Vector3.new(-250, 25,  820) },
    { name = "Zone H",  pos = Vector3.new( 160, 24,  900) },
}

local ZONE_RADIUS   = 140
local ZONE_WAIT     = 20
local COLLECT_DELAY = 0.35

-- ══════════════════════════════════════════════════════════════════════════════
-- TOAST SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════

local toastGui = Instance.new("ScreenGui")
toastGui.Name           = "EggToasts"
toastGui.ResetOnSpawn   = false
toastGui.IgnoreGuiInset = true
toastGui.DisplayOrder   = 9999
toastGui.Parent         = playerGui

local toastHolder = Instance.new("Frame")
toastHolder.Name                   = "Holder"
toastHolder.Size                   = UDim2.new(0, 300, 1, 0)
toastHolder.Position               = UDim2.new(1, -312, 0, 0)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent                 = toastGui

local toastLayout = Instance.new("UIListLayout")
toastLayout.SortOrder         = Enum.SortOrder.LayoutOrder
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Padding           = UDim.new(0, 6)
toastLayout.Parent            = toastHolder

local toastPad = Instance.new("UIPadding")
toastPad.PaddingBottom = UDim.new(0, 18)
toastPad.Parent        = toastHolder

local TOAST_COLORS = {
    info    = { bg = Color3.fromRGB(22,  16,  38),  accent = Color3.fromRGB(160, 100, 255) },
    success = { bg = Color3.fromRGB(18,  12,  36),  accent = Color3.fromRGB(180, 130, 255) },
    warn    = { bg = Color3.fromRGB(30,  18,  48),  accent = Color3.fromRGB(210, 160, 255) },
    error   = { bg = Color3.fromRGB(40,  14,  50),  accent = Color3.fromRGB(220,  80, 255) },
    egg     = { bg = Color3.fromRGB(26,  14,  46),  accent = Color3.fromRGB(200, 120, 255) },
}

local function showToast(title, body, kind, duration)
    kind     = kind or "info"
    duration = duration or 3.5
    local c  = TOAST_COLORS[kind] or TOAST_COLORS.info

    local frame = Instance.new("Frame")
    frame.Size                   = UDim2.new(1, 0, 0, 62)
    frame.BackgroundColor3       = c.bg
    frame.BorderSizePixel        = 0
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants       = true
    frame.Parent                 = toastHolder
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 9)

    local stroke = Instance.new("UIStroke")
    stroke.Color        = c.accent
    stroke.Thickness    = 1
    stroke.Transparency = 0.6
    stroke.Parent       = frame

    local icon = Instance.new("ImageLabel")
    icon.Size                   = UDim2.new(0, 24, 0, 24)
    icon.Position               = UDim2.new(0, 10, 0, 10)
    icon.BackgroundTransparency = 1
    icon.Image                  = UI_ASSET_ID
    icon.ImageColor3            = c.accent
    icon.Parent                 = frame

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 2, 1, -14)
    bar.Position         = UDim2.new(0, 38, 0, 7)
    bar.BackgroundColor3 = c.accent
    bar.BorderSizePixel  = 0
    bar.Parent           = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size                = UDim2.new(1, -56, 0, 22)
    titleLbl.Position            = UDim2.new(0, 46, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font                = Enum.Font.GothamBold
    titleLbl.TextSize            = 12
    titleLbl.TextColor3          = c.accent
    titleLbl.TextXAlignment      = Enum.TextXAlignment.Left
    titleLbl.Text                = title
    titleLbl.Parent              = frame

    local bodyLbl = Instance.new("TextLabel")
    bodyLbl.Size                 = UDim2.new(1, -56, 0, 18)
    bodyLbl.Position             = UDim2.new(0, 46, 0, 30)
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Font                 = Enum.Font.Gotham
    bodyLbl.TextSize             = 11
    bodyLbl.TextColor3           = Color3.fromRGB(195, 170, 230)
    bodyLbl.TextXAlignment       = Enum.TextXAlignment.Left
    bodyLbl.Text                 = body
    bodyLbl.Parent               = frame

    local prog = Instance.new("Frame")
    prog.Size                   = UDim2.new(1, 0, 0, 2)
    prog.Position               = UDim2.new(0, 0, 1, -2)
    prog.BackgroundColor3       = c.accent
    prog.BorderSizePixel        = 0
    prog.BackgroundTransparency = 0.4
    prog.Parent                 = frame

    frame.Position = UDim2.new(1, 16, 0, 0)
    TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
    }):Play()
    TweenService:Create(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()

    task.delay(duration, function()
        local fi = TweenInfo.new(0.28, Enum.EasingStyle.Quart)
        TweenService:Create(frame,    fi, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(titleLbl, fi, { TextTransparency = 1 }):Play()
        TweenService:Create(bodyLbl,  fi, { TextTransparency = 1 }):Play()
        TweenService:Create(bar,      fi, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(icon,     fi, { ImageTransparency = 1 }):Play()
        task.wait(0.32)
        frame:Destroy()
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════════════════════════════════

local collectOn    = false
local collected    = 0
local collectDelay = COLLECT_DELAY
local statusLbl    = nil   -- TextLabel reference updated directly

-- ══════════════════════════════════════════════════════════════════════════════
-- CORE
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

-- ── VOID PROTECTION ──────────────────────────────────────────────────────────
-- lastSafePos: updated every frame while alive and Y > 10.
-- voidWatchdog: permanent loop that snaps back if Y drops below VOID_THRESHOLD.
-- teleportTo: casts ray BOTH from above (for tall geometry) AND from below
--   (for terrain/water) before committing; also waits multiple frames after
--   teleport and verifies Y is stable before returning true.
-- ─────────────────────────────────────────────────────────────────────────────

local VOID_THRESHOLD = -30   -- Y below this = void
local lastSafePos    = nil   -- last known good CFrame

-- Track safe position continuously
RunService.Heartbeat:Connect(function()
    local hrp = myHRP()
    if hrp and hrp.Position.Y > 10 then
        lastSafePos = hrp.CFrame
    end
end)

-- Watchdog: if we fall into void, snap back immediately
RunService.Heartbeat:Connect(function()
    local hrp = myHRP()
    if hrp and hrp.Position.Y < VOID_THRESHOLD and lastSafePos then
        hrp.CFrame = lastSafePos
    end
end)

local function hasGroundAt(pos)
    -- Ray 1: exclude character, catches BaseParts and Terrain
    local params1 = RaycastParams.new()
    params1.FilterType = Enum.RaycastFilterType.Exclude
    pcall(function()
        params1.FilterDescendantsInstances = { player.Character }
    end)
    local hit1 = workspace:Raycast(
        Vector3.new(pos.X, pos.Y + 60, pos.Z),
        Vector3.new(0, -200, 0),
        params1
    )
    if hit1 then return true end

    -- Ray 2: terrain only — catches water floors that Ray 1 may miss
    local params2 = RaycastParams.new()
    params2.FilterType = Enum.RaycastFilterType.Include
    pcall(function() params2.FilterDescendantsInstances = { workspace.Terrain } end)
    local hit2 = workspace:Raycast(
        Vector3.new(pos.X, pos.Y + 60, pos.Z),
        Vector3.new(0, -200, 0),
        params2
    )
    return hit2 ~= nil
end

local function teleportTo(pos)
    local hrp = myHRP(); if not hrp then return false end

    -- Hard Y floor
    if pos.Y < VOID_THRESHOLD then
        showToast("Zone skipped", "Position below void threshold", "warn", 2)
        return false
    end

    -- Ground check before committing
    if not hasGroundAt(pos) then
        showToast("Zone skipped", "No ground detected", "warn", 2)
        return false
    end

    -- Save current safe pos in case we need to revert
    local fallback = hrp.CFrame

    setCollision(false)
    hrp.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)

    -- Wait up to 6 frames, checking each frame if we're falling into void
    for _ = 1, 6 do
        task.wait()
        hrp = myHRP()
        if not hrp then setCollision(true); return false end
        if hrp.Position.Y < VOID_THRESHOLD then
            -- Revert immediately
            hrp.CFrame = fallback
            setCollision(true)
            showToast("Teleport reverted", "Fell into void — skipped", "warn", 2.5)
            return false
        end
    end

    setCollision(true)
    return true
end

local function updateStatus()
    if statusLbl then
        statusLbl.Text = "collected: " .. collected
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- EGG FOLDER DETECTION & SCAN
-- Detects the spawn folder once, then scans ALL descendants of that folder
-- (children + sub-folders) so nothing is missed
-- ══════════════════════════════════════════════════════════════════════════════

local eggSpawnFolder = nil

local function detectEggFolder()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "EggTemplate" and obj.Parent and obj.Parent ~= workspace then
            local ovo = obj:FindFirstChild("Ovo") or obj:FindFirstChild("Ovo2")
            if ovo and ovo:IsA("BasePart") then
                -- Cache the top-level folder (parent of parent if nested)
                local folder = obj.Parent
                -- Walk up one more level if the direct parent is also not workspace
                -- to get the root egg container
                eggSpawnFolder = folder
                return eggSpawnFolder
            end
        end
    end
    return nil
end

local function findEggsNear(center, radius)
    local folder = eggSpawnFolder or detectEggFolder()
    if not folder or not folder.Parent then
        eggSpawnFolder = nil
        folder = detectEggFolder()
        if not folder then return {} end
    end

    local eggs = {}
    local seen  = {}

    -- GetDescendants covers children AND sub-folder children
    for _, obj in ipairs(folder:GetDescendants()) do
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

-- Build a flat list of unique egg positions across the ENTIRE folder
-- so the loop can teleport to clusters inside sub-folders too
local function getAllEggClusters()
    local folder = eggSpawnFolder or detectEggFolder()
    if not folder or not folder.Parent then return {} end

    local positions = {}
    local seen = {}
    for _, obj in ipairs(folder:GetDescendants()) do
        pcall(function()
            if obj.Name == "EggTemplate" and not seen[obj] and obj.Parent then
                local ovo = obj:FindFirstChild("Ovo") or obj:FindFirstChild("Ovo2")
                if ovo and ovo:IsA("BasePart") then
                    seen[obj] = true
                    table.insert(positions, { model = obj, part = ovo, pos = ovo.Position })
                end
            end
        end)
    end
    return positions
end

local function collectEgg(eggData)
    local hrp = myHRP(); if not hrp then return false end
    if not eggData.model.Parent then return false end
    local part = eggData.model:FindFirstChild("Ovo") or eggData.model:FindFirstChild("Ovo2")
    if not part or not part.Parent then return false end

    local target = part.Position + Vector3.new(0, 2.5, 0)

    -- Hard void guard on egg position
    if target.Y < VOID_THRESHOLD then return false end
    if not hasGroundAt(part.Position) then return false end

    local fallback = hrp.CFrame
    setCollision(false)
    hrp.CFrame = CFrame.new(target)
    task.wait(0.06)
    hrp = myHRP()
    if hrp and hrp.Position.Y < VOID_THRESHOLD then
        hrp.CFrame = fallback
        setCollision(true)
        return false
    end
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

-- ══════════════════════════════════════════════════════════════════════════════
-- MAIN LOOP
-- For each zone: teleport, recheck every 2s up to 20s.
-- Also teleports directly to any egg found inside sub-folders of the egg container.
-- ══════════════════════════════════════════════════════════════════════════════

local function collectLoop()
    collected = 0
    updateStatus()

    if not eggSpawnFolder then detectEggFolder() end

    while collectOn do
        if not isAlive() then
            showToast("Waiting", "Dead — waiting for respawn...", "error", 3)
            task.wait(2)
            continue
        end

        for _, zone in ipairs(ZONES) do
            if not collectOn then break end
            if not isAlive() then break end

            local ok = teleportTo(zone.pos)
            if not ok then continue end

            showToast("→ " .. zone.name, "Scanning for eggs...", "info", 2)

            local waited   = 0
            local foundAny = false

            while collectOn and waited < ZONE_WAIT do
                if not isAlive() then break end

                -- 1) collect eggs near zone center (covers default spawn positions)
                local eggs = findEggsNear(zone.pos, ZONE_RADIUS)

                -- 2) also pull ALL eggs in the entire folder and teleport to any
                --    that are far from zone center but still exist (sub-folder eggs)
                local allEggs = getAllEggClusters()
                local merged  = {}
                local inZone  = {}
                for _, e in ipairs(eggs) do inZone[e.model] = true end
                for _, e in ipairs(allEggs) do
                    if not inZone[e.model] then
                        -- only pick up eggs not already in the zone list
                        -- and only if their position is safe
                        if e.pos.Y > -40 then
                            table.insert(merged, e)
                        end
                    end
                end
                -- zone eggs first (already nearby), then extras
                local toCollect = {}
                for _, e in ipairs(eggs)   do table.insert(toCollect, e) end
                for _, e in ipairs(merged) do table.insert(toCollect, e) end

                if #toCollect > 0 then
                    foundAny = true
                    showToast(zone.name .. " — " .. #toCollect .. " egg(s)", "Collecting...", "egg", 2.5)
                    for _, eggData in ipairs(toCollect) do
                        if not collectOn then break end
                        if not isAlive() then break end
                        if collectEgg(eggData) then
                            collected = collected + 1
                            updateStatus()
                        end
                        task.wait(collectDelay)
                    end
                end

                task.wait(2)
                waited = waited + 2
            end

            if not foundAny then
                showToast(zone.name .. " — empty", "Moving on...", "warn", 1.8)
            else
                showToast(zone.name .. " — done", "Total: " .. collected, "success", 2)
            end

            task.wait(0.4)
        end

        if collectOn then
            showToast("Cycle complete", "Collected: " .. collected .. " | Restarting...", "success", 3)
            task.wait(1)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- INLINE NUMERIC INPUT — overlays on top of the slider row itself
-- Called by passing the slider's parent frame; renders inside a floating panel
-- anchored below the slider label, same width.
-- ══════════════════════════════════════════════════════════════════════════════

local function makeNumericInput(currentVal, minVal, maxVal, onConfirm)
    -- Full-screen dismiss layer
    local popup = Instance.new("ScreenGui")
    popup.Name           = "DelayInput"
    popup.ResetOnSpawn   = false
    popup.DisplayOrder   = 99999
    popup.IgnoreGuiInset = true
    popup.Parent         = playerGui

    local backdrop = Instance.new("Frame")
    backdrop.Size                   = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.6
    backdrop.BorderSizePixel        = 0
    backdrop.Parent                 = popup

    -- Compact floating card — no header bar, just a clean input
    local card = Instance.new("Frame")
    card.AnchorPoint      = Vector2.new(0.5, 0.5)
    card.Size             = UDim2.new(0, 220, 0, 92)
    card.Position         = UDim2.new(0.5, 0, 0.5, 0)
    card.BackgroundColor3 = Color3.fromRGB(16, 10, 30)
    card.BorderSizePixel  = 0
    card.ClipsDescendants = true
    card.Parent           = popup
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color        = Color3.fromRGB(140, 80, 255)
    cardStroke.Thickness    = 1
    cardStroke.Transparency = 0.25
    cardStroke.Parent       = card

    -- Thin top accent strip
    local topStrip = Instance.new("Frame")
    topStrip.Size             = UDim2.new(1, 0, 0, 2)
    topStrip.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    topStrip.BorderSizePixel  = 0
    topStrip.BackgroundTransparency = 0.3
    topStrip.Parent           = card

    -- Label above input
    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(1, -16, 0, 18)
    lbl.Position            = UDim2.new(0, 8, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Font                = Enum.Font.Gotham
    lbl.TextSize            = 10
    lbl.TextColor3          = Color3.fromRGB(150, 110, 210)
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.Text                = "delay  ·  " .. minVal .. " – " .. maxVal .. " ticks  ·  1 tick = 0.05s"
    lbl.Parent              = card

    -- Input box
    local input = Instance.new("TextBox")
    input.Size             = UDim2.new(1, -16, 0, 32)
    input.Position         = UDim2.new(0, 8, 0, 28)
    input.BackgroundColor3 = Color3.fromRGB(28, 16, 50)
    input.BorderSizePixel  = 0
    input.Font             = Enum.Font.GothamBold
    input.TextSize         = 18
    input.TextColor3       = Color3.fromRGB(220, 200, 255)
    input.PlaceholderText  = tostring(currentVal)
    input.Text             = tostring(currentVal)
    input.ClearTextOnFocus = true
    input.TextXAlignment   = Enum.TextXAlignment.Center
    input.Parent           = card
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color     = Color3.fromRGB(120, 70, 200)
    inputStroke.Thickness = 1
    inputStroke.Parent    = input

    -- Equivalence hint below input (updates live as user types)
    local eqLbl = Instance.new("TextLabel")
    eqLbl.Size                = UDim2.new(1, -16, 0, 14)
    eqLbl.Position            = UDim2.new(0, 8, 0, 62)
    eqLbl.BackgroundTransparency = 1
    eqLbl.Font                = Enum.Font.Gotham
    eqLbl.TextSize            = 10
    eqLbl.TextColor3          = Color3.fromRGB(130, 100, 180)
    eqLbl.TextXAlignment      = Enum.TextXAlignment.Center
    eqLbl.Text                = "= " .. string.format("%.2f", currentVal * 0.05) .. "s per egg"
    eqLbl.Parent              = card

    -- Live update equivalence
    input:GetPropertyChangedSignal("Text"):Connect(function()
        local n = tonumber(input.Text)
        if n then
            n = math.clamp(math.floor(n), minVal, maxVal)
            eqLbl.Text = "= " .. string.format("%.2f", n * 0.05) .. "s per egg"
        else
            eqLbl.Text = "enter a number"
        end
    end)

    local function confirm()
        local num = tonumber(input.Text)
        if num then
            num = math.clamp(math.floor(num), minVal, maxVal)
            onConfirm(num)
        end
        popup:Destroy()
    end

    -- Enter key confirms
    input.FocusLost:Connect(function(enter)
        if enter then confirm() end
    end)

    -- Click outside dismisses
    backdrop.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            popup:Destroy()
        end
    end)

    task.wait(0.05)
    input:CaptureFocus()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI TABS
-- ══════════════════════════════════════════════════════════════════════════════

local tab = ui:Tab("eggs", UI_ASSET_ID)
local sec = tab:Section("auto egg collector")

-- Status label: we create a Button (since Label may not exist in RefLib),
-- then grab the underlying TextLabel so we can update it directly
local statusBtn = sec:Button("collected: 0", function() end)
-- Walk the button's frame children to find the TextLabel and cache it
task.spawn(function()
    task.wait(0.1)  -- wait one frame for RefLib to parent the element
    -- RefLib buttons are typically a Frame > TextLabel structure in playerGui
    -- We search playerGui for a TextLabel whose text matches our initial value
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Text == "collected: 0" then
            statusLbl = gui
            break
        end
    end
end)

sec:Divider("farm")

local t_collect = sec:Toggle("auto collect", false, function(v)
    collectOn = v
    if v then
        task.spawn(collectLoop)
        showToast("Farm started", "Scanning " .. #ZONES .. " zones", "success", 3.5)
    else
        showToast("Farm stopped", "Total collected: " .. collected, "info", 3)
    end
end)
ui:CfgRegister("egg_collect", function() return collectOn end, function(v) t_collect.Set(v) end)

sec:Divider("delay")

local currentDelayTicks = 7

-- Slider — clicking the displayed value badge opens the inline input
local sliderRef = sec:Slider("delay  (x0.05s)  —  click value to type", 1, 20, currentDelayTicks, function(v)
    currentDelayTicks = v
    collectDelay = v * 0.05
end)
ui:CfgRegister("egg_delay", function() return currentDelayTicks end, function(v) sliderRef.Set(v) end)

-- Attach click handler to the slider's value label (the number badge RefLib renders)
-- RefLib sliders render a TextLabel or TextButton showing the current value.
-- We search for it by walking the slider's container after a short delay.
task.spawn(function()
    task.wait(0.15)
    -- Find all TextLabels/TextButtons that show the tick count (initially "7")
    -- and are children of a slider frame — make them clickable
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text == tostring(currentDelayTicks) then
            -- Heuristic: slider value labels are short numeric strings in small frames
            if obj.TextSize and obj.TextSize <= 16 then
                -- Wrap in a transparent button overlay
                local btn = Instance.new("TextButton")
                btn.Size                   = UDim2.new(1, 0, 1, 0)
                btn.BackgroundTransparency = 1
                btn.Text                   = ""
                btn.ZIndex                 = obj.ZIndex + 1
                btn.Parent                 = obj
                btn.Activated:Connect(function()
                    makeNumericInput(currentDelayTicks, 1, 20, function(val)
                        currentDelayTicks = val
                        collectDelay = val * 0.05
                        sliderRef.Set(val)
                        showToast("Delay updated", val .. " ticks = " .. string.format("%.2f", val * 0.05) .. "s", "egg", 2.5)
                    end)
                end)
                break
            end
        end
    end
end)

sec:Divider("manual teleport")

for _, zone in ipairs(ZONES) do
    local z = zone
    sec:Button("→ " .. z.name, function()
        if not isAlive() then
            showToast("Error", "You are dead", "error", 2)
            return
        end
        local ok = teleportTo(z.pos)
        if not ok then return end
        showToast("→ " .. z.name, "Collecting eggs nearby...", "egg", 3)
        task.spawn(function()
            local eggs = findEggsNear(z.pos, ZONE_RADIUS)
            local all  = getAllEggClusters()
            -- merge: eggs near zone + all folder eggs (de-dup)
            local seen = {}
            local list  = {}
            for _, e in ipairs(eggs) do seen[e.model] = true; table.insert(list, e) end
            for _, e in ipairs(all)  do
                if not seen[e.model] and e.pos.Y > -40 then
                    table.insert(list, e)
                end
            end
            if #list == 0 then
                showToast(z.name .. " — empty", "No eggs found", "warn", 3)
                return
            end
            for _, eggData in ipairs(list) do
                if collectEgg(eggData) then collected = collected + 1 end
                updateStatus()
                task.wait(collectDelay)
            end
            showToast(z.name .. " — done", "Total: " .. collected, "success", 3)
        end)
    end)
end

sec:Divider("utils")

sec:Button("reset counter", function()
    collected = 0
    updateStatus()
    showToast("Counter reset", "Back to zero", "info", 2)
end)

sec:Button("detect egg folder", function()
    eggSpawnFolder = nil
    local folder = detectEggFolder()
    if folder then
        showToast("Folder detected", folder.Name .. " — " .. #folder:GetDescendants() .. " descendants", "success", 3.5)
    else
        showToast("Not found", "No EggTemplate in workspace", "error", 3.5)
    end
end)

local tabCfg = ui:Tab("config", UI_ASSET_ID)
ui:BuildConfigTab(tabCfg, "egg_collector_cfg")
