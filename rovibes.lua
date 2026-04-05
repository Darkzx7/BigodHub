local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
if not RefLib then error("[EggCollector] RefLib failed to load.") end

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local player         = Players.LocalPlayer
local playerGui      = player:WaitForChild("PlayerGui")

local UI_ASSET_ID = "rbxassetid://131165537896572"

local ui = RefLib.new("egg collector", UI_ASSET_ID, "egg_collector_cfg")

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
toastHolder.Name                  = "Holder"
toastHolder.Size                  = UDim2.new(0, 300, 1, 0)
toastHolder.Position              = UDim2.new(1, -312, 0, 0)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent                = toastGui

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
    prog.Size             = UDim2.new(1, 0, 0, 2)
    prog.Position         = UDim2.new(0, 0, 1, -2)
    prog.BackgroundColor3 = c.accent
    prog.BorderSizePixel  = 0
    prog.BackgroundTransparency = 0.4
    prog.Parent           = frame

    frame.Position = UDim2.new(1, 16, 0, 0)
    TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
    }):Play()

    TweenService:Create(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()

    task.delay(duration, function()
        local fadeInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quart)
        TweenService:Create(frame,    fadeInfo, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(titleLbl, fadeInfo, { TextTransparency = 1 }):Play()
        TweenService:Create(bodyLbl,  fadeInfo, { TextTransparency = 1 }):Play()
        TweenService:Create(bar,      fadeInfo, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(icon,     fadeInfo, { ImageTransparency = 1 }):Play()
        task.wait(0.32)
        frame:Destroy()
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ESTADO
-- ══════════════════════════════════════════════════════════════════════════════

local collectOn    = false
local collected    = 0
local skipped      = 0
local collectDelay = COLLECT_DELAY
local statusLabel  = nil

-- ══════════════════════════════════════════════════════════════════════════════
-- FUNÇÕES CORE
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

-- ══════════════════════════════════════════════════════════════════════════════
-- SCANNER — busca APENAS dentro da folder de spawn dos ovos
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

local function findEggsNear(center, radius)
    local folder = eggSpawnFolder or detectEggFolder()
    if not folder or not folder.Parent then
        eggSpawnFolder = nil
        folder = detectEggFolder()
        if not folder then return {} end
    end

    local eggs = {}
    local seen  = {}

    for _, obj in ipairs(folder:GetChildren()) do
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
-- LOOP PRINCIPAL
-- ══════════════════════════════════════════════════════════════════════════════

local function collectLoop()
    collected = 0
    skipped   = 0
    updateStatus()

    if not eggSpawnFolder then detectEggFolder() end

    while collectOn do
        if not isAlive() then
            showToast("Aguardando", "Morto — aguardando respawn...", "error", 3)
            task.wait(2)
            continue
        end

        for _, zone in ipairs(ZONES) do
            if not collectOn then break end
            if not isAlive() then break end

            teleportTo(zone.pos)
            showToast("→ "..zone.name, "Escaneando ovos...", "info", 2.5)

            local waited   = 0
            local foundAny = false

            while collectOn and waited < ZONE_WAIT do
                if not isAlive() then break end

                local eggs = findEggsNear(zone.pos, ZONE_RADIUS)

                if #eggs > 0 then
                    foundAny = true
                    showToast(zone.name.." — "..#eggs.." ovo(s)", "Coletando...", "egg", 3)

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
                end

                task.wait(2)
                waited = waited + 2
            end

            if not foundAny then
                showToast(zone.name.." — vazia", "Próxima zona...", "warn", 2)
            else
                showToast(zone.name.." — ok", "Total: "..collected.." coletados", "success", 2.5)
            end

            task.wait(0.5)
        end

        if collectOn then
            showToast("Ciclo completo", "Coletados: "..collected.." | Reiniciando...", "success", 3.5)
            task.wait(1.5)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NUMERIC INPUT POPUP
-- ══════════════════════════════════════════════════════════════════════════════

local function makeNumericInput(currentVal, minVal, maxVal, onConfirm)
    local popup = Instance.new("ScreenGui")
    popup.Name           = "NumericInput"
    popup.ResetOnSpawn   = false
    popup.DisplayOrder   = 99999
    popup.IgnoreGuiInset = true
    popup.Parent         = playerGui

    local backdrop = Instance.new("Frame")
    backdrop.Size                   = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.55
    backdrop.BorderSizePixel        = 0
    backdrop.Parent                 = popup

    local box = Instance.new("Frame")
    box.AnchorPoint      = Vector2.new(0.5, 0.5)
    box.Size             = UDim2.new(0, 240, 0, 130)
    box.Position         = UDim2.new(0.5, 0, 0.5, 0)
    box.BackgroundColor3 = Color3.fromRGB(18, 12, 32)
    box.BorderSizePixel  = 0
    box.Parent           = popup
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke")
    stroke.Color        = Color3.fromRGB(160, 100, 255)
    stroke.Thickness    = 1.2
    stroke.Transparency = 0.3
    stroke.Parent       = box

    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(30, 18, 54)
    header.BorderSizePixel  = 0
    header.Parent           = box
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

    local headerFix = Instance.new("Frame")
    headerFix.Size             = UDim2.new(1, 0, 0, 12)
    headerFix.Position         = UDim2.new(0, 0, 1, -12)
    headerFix.BackgroundColor3 = Color3.fromRGB(30, 18, 54)
    headerFix.BorderSizePixel  = 0
    headerFix.Parent           = header

    local headerIcon = Instance.new("ImageLabel")
    headerIcon.Size                   = UDim2.new(0, 18, 0, 18)
    headerIcon.Position               = UDim2.new(0, 10, 0.5, -9)
    headerIcon.BackgroundTransparency = 1
    headerIcon.Image                  = UI_ASSET_ID
    headerIcon.ImageColor3            = Color3.fromRGB(180, 130, 255)
    headerIcon.Parent                 = header

    local headerLbl = Instance.new("TextLabel")
    headerLbl.Size               = UDim2.new(1, -36, 1, 0)
    headerLbl.Position           = UDim2.new(0, 32, 0, 0)
    headerLbl.BackgroundTransparency = 1
    headerLbl.Font               = Enum.Font.GothamBold
    headerLbl.TextSize           = 12
    headerLbl.TextColor3         = Color3.fromRGB(200, 160, 255)
    headerLbl.TextXAlignment     = Enum.TextXAlignment.Left
    headerLbl.Text               = "Delay entre ovos  ("..minVal.."–"..maxVal.." ticks)"
    headerLbl.Parent             = header

    local input = Instance.new("TextBox")
    input.Size             = UDim2.new(1, -20, 0, 34)
    input.Position         = UDim2.new(0, 10, 0, 44)
    input.BackgroundColor3 = Color3.fromRGB(28, 18, 48)
    input.BorderSizePixel  = 0
    input.Font             = Enum.Font.GothamBold
    input.TextSize         = 16
    input.TextColor3       = Color3.new(1, 1, 1)
    input.PlaceholderText  = tostring(currentVal)
    input.Text             = tostring(currentVal)
    input.ClearTextOnFocus = true
    input.Parent           = box
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 7)

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color     = Color3.fromRGB(130, 80, 210)
    inputStroke.Thickness = 1
    inputStroke.Parent    = input

    local hint = Instance.new("TextLabel")
    hint.Size                = UDim2.new(1, -20, 0, 14)
    hint.Position            = UDim2.new(0, 10, 0, 80)
    hint.BackgroundTransparency = 1
    hint.Font                = Enum.Font.Gotham
    hint.TextSize            = 10
    hint.TextColor3          = Color3.fromRGB(130, 100, 170)
    hint.TextXAlignment      = Enum.TextXAlignment.Left
    hint.Text                = "1 tick = 0.05s   |   atual: "..currentVal.." ticks = "..(currentVal*0.05).."s"
    hint.Parent              = box

    local function confirm()
        local num = tonumber(input.Text)
        if num then
            num = math.clamp(math.floor(num), minVal, maxVal)
            onConfirm(num)
        end
        popup:Destroy()
    end

    local btnOk = Instance.new("TextButton")
    btnOk.Size             = UDim2.new(0, 100, 0, 28)
    btnOk.Position         = UDim2.new(0.5, -104, 1, -36)
    btnOk.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    btnOk.BorderSizePixel  = 0
    btnOk.Font             = Enum.Font.GothamBold
    btnOk.TextSize         = 12
    btnOk.TextColor3       = Color3.new(1, 1, 1)
    btnOk.Text             = "Confirmar"
    btnOk.Parent           = box
    Instance.new("UICorner", btnOk).CornerRadius = UDim.new(0, 7)
    btnOk.Activated:Connect(confirm)

    local btnCancel = Instance.new("TextButton")
    btnCancel.Size             = UDim2.new(0, 100, 0, 28)
    btnCancel.Position         = UDim2.new(0.5, 4, 1, -36)
    btnCancel.BackgroundColor3 = Color3.fromRGB(50, 28, 72)
    btnCancel.BorderSizePixel  = 0
    btnCancel.Font             = Enum.Font.GothamBold
    btnCancel.TextSize         = 12
    btnCancel.TextColor3       = Color3.fromRGB(170, 130, 220)
    btnCancel.Text             = "Cancelar"
    btnCancel.Parent           = box
    Instance.new("UICorner", btnCancel).CornerRadius = UDim.new(0, 7)
    btnCancel.Activated:Connect(function() popup:Destroy() end)

    backdrop.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            popup:Destroy()
        end
    end)

    input.FocusLost:Connect(function(enter)
        if enter then confirm() end
    end)

    task.wait(0.05)
    input:CaptureFocus()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI TABS
-- ══════════════════════════════════════════════════════════════════════════════

local tab = ui:Tab("eggs", UI_ASSET_ID)
local sec = tab:Section("auto egg collector — RoVibes")

statusLabel = sec:Button("collected: 0   skipped: 0", function() end)

sec:Divider("farm")

local t_collect = sec:Toggle("auto collect eggs", false, function(v)
    collectOn = v
    if v then
        task.spawn(collectLoop)
        showToast("Farm Iniciado", "Varrendo "..#ZONES.." zonas — 20s por zona", "success", 4)
    else
        showToast("Farm Parado", "Total coletado: "..collected, "info", 3)
    end
end)
ui:CfgRegister("egg_collect", function() return collectOn end, function(v) t_collect.Set(v) end)

sec:Divider("delay entre ovos")

local currentDelayTicks = 7

local sliderRef = sec:Slider("delay (x0.05s)", 1, 20, currentDelayTicks, function(v)
    currentDelayTicks = v
    collectDelay = v * 0.05
end)
ui:CfgRegister("egg_delay", function() return currentDelayTicks end, function(v) sliderRef.Set(v) end)

sec:Button("✎ inserir valor de delay", function()
    makeNumericInput(currentDelayTicks, 1, 20, function(val)
        currentDelayTicks = val
        collectDelay = val * 0.05
        sliderRef.Set(val)
        showToast("Delay atualizado", val.." ticks = "..(val*0.05).."s por ovo", "egg", 2.5)
    end)
end)

sec:Divider("teleporte manual")

for _, zone in ipairs(ZONES) do
    local z = zone
    sec:Button("→ "..z.name, function()
        if not isAlive() then
            showToast("Erro", "Você está morto", "error", 2)
            return
        end
        teleportTo(z.pos)
        showToast("→ "..z.name, "Coletando ovos na área...", "egg", 3)
        task.spawn(function()
            local eggs = findEggsNear(z.pos, ZONE_RADIUS)
            if #eggs == 0 then
                showToast(z.name.." — vazia", "Nenhum ovo encontrado", "warn", 3)
                return
            end
            for _, eggData in ipairs(eggs) do
                if collectEgg(eggData) then collected = collected + 1
                else skipped = skipped + 1 end
                updateStatus()
                task.wait(collectDelay)
            end
            showToast(z.name.." — ok", "Coletados: "..collected.." total", "success", 3)
        end)
    end)
end

sec:Divider("utils")
sec:Button("resetar contador", function()
    collected = 0; skipped = 0; updateStatus()
    showToast("Contador zerado", "De volta ao zero", "info", 2)
end)

sec:Button("detectar pasta de ovos", function()
    eggSpawnFolder = nil
    local folder = detectEggFolder()
    if folder then
        showToast("Pasta detectada", folder.Name.." ("..#folder:GetChildren().." filhos)", "success", 3.5)
    else
        showToast("Não encontrado", "Nenhum EggTemplate no workspace", "error", 3.5)
    end
end)

local tabCfg = ui:Tab("config", UI_ASSET_ID)
ui:BuildConfigTab(tabCfg, "egg_collector_cfg")
