local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
if not RefLib then error("[EggCollector] RefLib failed to load.") end

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local player         = Players.LocalPlayer
local playerGui      = player:WaitForChild("PlayerGui")

-- ── PERSISTENT COLLECTED COUNTER (executor writefile/readfile) ───────────────
local SAVE_FILE = "egg_collector_save.json"

local function saveCollected(n)
    pcall(function() writefile(SAVE_FILE, tostring(n)) end)
end

local function loadCollected()
    local ok, data = pcall(function() return readfile(SAVE_FILE) end)
    if ok and data then
        local n = tonumber(data)
        if n then return n end
    end
    return 0
end

local UI_ASSET_ID = "rbxassetid://131165537896572"
local ui = RefLib.new("egg collector", UI_ASSET_ID, "egg_collector_cfg")

-- ══════════════════════════════════════════════════════════════════════════════
-- ZONES
-- ══════════════════════════════════════════════════════════════════════════════

local ZONES = {
    { name = "Zone A",  pos = Vector3.new(-207, 4,   872) },
    { name = "Zone B",  pos = Vector3.new( 100, 18,  600) },
    { name = "Zone C",  pos = Vector3.new(  -6, 16,  490) },
    { name = "Zone D",  pos = Vector3.new(-120, 8,   650) },
    { name = "Zone E",  pos = Vector3.new( 420, 6,   720) },
    { name = "Zone F",  pos = Vector3.new( -64, 19,  350) },
    { name = "Zone G",  pos = Vector3.new(-250, 25,  820) },
    { name = "Zone H",  pos = Vector3.new( 160, 24,  900) },
}

local ZONE_RADIUS          = 140
local ZONE_WAIT            = 20
local COLLECT_DELAY        = 0.50
local MANUAL_COLLECT_DELAY = 0.015
local VOID_THRESHOLD       = -30

-- Raio de detecção de proximidade (ao se mover pelo mapa)
local PROXIMITY_RADIUS     = 80

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

local collectOn       = false
local proximityOn     = false   -- toggle separado para proximity collector
local collected       = 0
local collectDelay    = COLLECT_DELAY
local statusLbl       = nil
local lastSafePos     = nil

-- ══════════════════════════════════════════════════════════════════════════════
-- CORE HELPERS
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

-- Void protection
RunService.Heartbeat:Connect(function()
    local hrp = myHRP()
    if hrp and hrp.Position.Y > 10 then
        lastSafePos = hrp.CFrame
    end
end)

RunService.Heartbeat:Connect(function()
    local hrp = myHRP()
    if hrp and hrp.Position.Y < VOID_THRESHOLD and lastSafePos then
        hrp.CFrame = lastSafePos
    end
end)

local function hasGroundAt(pos)
    local params1 = RaycastParams.new()
    params1.FilterType = Enum.RaycastFilterType.Exclude
    pcall(function() params1.FilterDescendantsInstances = { player.Character } end)
    local hit1 = workspace:Raycast(
        Vector3.new(pos.X, pos.Y + 60, pos.Z),
        Vector3.new(0, -200, 0),
        params1
    )
    if hit1 then return true end

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

    if pos.Y < VOID_THRESHOLD then
        showToast("Zone skipped", "Position below void threshold", "warn", 2)
        return false
    end

    if not hasGroundAt(pos) then
        showToast("Zone skipped", "No ground detected", "warn", 2)
        return false
    end

    local fallback = hrp.CFrame
    setCollision(false)
    hrp.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)

    for _ = 1, 6 do
        task.wait()
        hrp = myHRP()
        if not hrp then setCollision(true); return false end
        if hrp.Position.Y < VOID_THRESHOLD then
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
    saveCollected(collected)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- EGG FOLDER DETECTION & SCAN
-- Varre GetDescendants() do folder inteiro — sem filtro de radius.
-- Único filtro: Y > VOID_THRESHOLD (segurança).
-- ══════════════════════════════════════════════════════════════════════════════

local eggSpawnFolder = nil

local function detectEggFolder()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "EggTemplate" and obj.Parent and obj.Parent ~= workspace then
            local ovo = obj:FindFirstChild("Ovo") or obj:FindFirstChild("Ovo2")
            if ovo and ovo:IsA("BasePart") then
                eggSpawnFolder = obj.Parent
                return eggSpawnFolder
            end
        end
    end
    return nil
end

-- Retorna TODOS os eggs do folder, ordenados por distância ao centro dado.
-- center = pode ser zona ou posição do jogador; sem corte por radius.
local function findAllEggs(center)
    local folder = eggSpawnFolder or detectEggFolder()
    if not folder or not folder.Parent then
        eggSpawnFolder = nil
        folder = detectEggFolder()
        if not folder then return {} end
    end

    local eggs = {}
    local seen  = {}

    for _, obj in ipairs(folder:GetDescendants()) do
        pcall(function()
            if obj.Name == "EggTemplate" and not seen[obj] and obj.Parent then
                local ovo = obj:FindFirstChild("Ovo") or obj:FindFirstChild("Ovo2")
                if ovo and ovo:IsA("BasePart") and ovo.Position.Y > VOID_THRESHOLD then
                    seen[obj] = true
                    local dist = (ovo.Position - center).Magnitude
                    table.insert(eggs, { model = obj, part = ovo, pos = ovo.Position, dist = dist })
                end
            end
        end)
    end

    table.sort(eggs, function(a, b) return a.dist < b.dist end)
    return eggs
end

-- Filtra findAllEggs por radius ao redor de center (para uso no proximity)
local function findEggsInRadius(center, radius)
    local all = findAllEggs(center)
    local out = {}
    for _, e in ipairs(all) do
        if e.dist <= radius then
            table.insert(out, e)
        end
    end
    return out
end

local function collectEgg(eggData)
    local hrp = myHRP(); if not hrp then return false end
    if not eggData.model.Parent then return false end
    local part = eggData.model:FindFirstChild("Ovo") or eggData.model:FindFirstChild("Ovo2")
    if not part or not part.Parent then return false end

    local target = part.Position + Vector3.new(0, 2.5, 0)

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
-- PROXIMITY COLLECTOR
-- Loop paralelo e independente. Roda sempre que proximityOn = true.
-- Não interfere no auto farm — ambos podem rodar juntos.
-- A cada 0.5s verifica eggs dentro de PROXIMITY_RADIUS do jogador e coleta.
-- ══════════════════════════════════════════════════════════════════════════════

local proximityThread = nil

local function startProximityLoop()
    if proximityThread then return end
    proximityThread = task.spawn(function()
        while proximityOn do
            if isAlive() then
                local hrp = myHRP()
                if hrp then
                    local nearby = findEggsInRadius(hrp.Position, PROXIMITY_RADIUS)
                    for _, eggData in ipairs(nearby) do
                        if not proximityOn then break end
                        if not isAlive() then break end
                        if collectEgg(eggData) then
                            collected = collected + 1
                            updateStatus()
                        end
                        task.wait(0.05)
                    end
                end
            end
            task.wait(0.5)
        end
        proximityThread = nil
    end)
end

local function stopProximityLoop()
    proximityOn   = false
    proximityThread = nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MAIN AUTO FARM LOOP
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

                -- Varre folder inteiro, ordenado por distância à zona
                local eggs = findAllEggs(zone.pos)

                if #eggs > 0 then
                    foundAny = true
                    showToast(zone.name .. " — " .. #eggs .. " egg(s)", "Collecting...", "egg", 2.5)
                    for _, eggData in ipairs(eggs) do
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
-- INLINE NUMERIC INPUT
-- ══════════════════════════════════════════════════════════════════════════════

local function makeNumericInput(currentVal, minVal, maxVal, onConfirm)
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

    local topStrip = Instance.new("Frame")
    topStrip.Size             = UDim2.new(1, 0, 0, 2)
    topStrip.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    topStrip.BorderSizePixel  = 0
    topStrip.BackgroundTransparency = 0.3
    topStrip.Parent           = card

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

    input.FocusLost:Connect(function(enter)
        if enter then confirm() end
    end)

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
-- LOAD SAVED DATA
-- ══════════════════════════════════════════════════════════════════════════════

task.spawn(function()
    local saved = loadCollected()
    if saved > 0 then
        collected = saved
        updateStatus()
        showToast("Progress restored", "Loaded " .. saved .. " collected eggs", "success", 3.5)
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- UI TABS
-- ══════════════════════════════════════════════════════════════════════════════

local tab = ui:Tab("eggs", UI_ASSET_ID)
local sec = tab:Section("auto egg collector")

local statusBtn = sec:Button("collected: 0", function() end)
task.spawn(function()
    task.wait(0.1)
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

sec:Divider("proximity")

local t_proximity = sec:Toggle("proximity collect  (ao se mover)", false, function(v)
    proximityOn = v
    if v then
        startProximityLoop()
        showToast("Proximity ON", "Raio: " .. PROXIMITY_RADIUS .. " studs", "egg", 3)
    else
        stopProximityLoop()
        showToast("Proximity OFF", "Coleta por proximidade parada", "info", 2.5)
    end
end)
ui:CfgRegister("egg_proximity", function() return proximityOn end, function(v) t_proximity.Set(v) end)

sec:Divider("delay")

local currentDelayTicks = 10

local sliderRef = sec:Slider("delay  (x0.05s)  —  click value to type", 1, 20, currentDelayTicks, function(v)
    currentDelayTicks = v
    collectDelay = v * 0.05
end)
ui:CfgRegister("egg_delay", function() return currentDelayTicks end, function(v) sliderRef.Set(v) end)

task.spawn(function()
    task.wait(0.15)
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text == tostring(currentDelayTicks) then
            if obj.TextSize and obj.TextSize <= 16 then
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
            local list = findAllEggs(z.pos)
            if #list == 0 then
                showToast(z.name .. " — empty", "No eggs found", "warn", 3)
                return
            end
            for _, eggData in ipairs(list) do
                if collectEgg(eggData) then collected = collected + 1 end
                updateStatus()
                task.wait(MANUAL_COLLECT_DELAY)
            end
            showToast(z.name .. " — done", "Total: " .. collected, "success", 3)
        end)
    end)
end

sec:Divider("utils")

sec:Button("reset counter", function()
    collected = 0
    updateStatus()
    pcall(function() writefile(SAVE_FILE, "0") end)
    showToast("Counter reset", "Cleared — save wiped", "info", 2.5)
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
