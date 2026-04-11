-- reftags.lua
-- sistema de tags clean + painel dev
-- texto solto acima do nick, sem cápsula, sem emoji
-- localplayer também recebe tag
-- dev recebe painel próprio para gerenciar tags

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local pg     = player:WaitForChild("PlayerGui")

-- ──────────────────────────────────────────────────────────────
-- ROLES
-- ──────────────────────────────────────────────────────────────
local ROLES = {
    owner = {
        color  = Color3.fromRGB(255, 232, 232),
        glow   = Color3.fromRGB(190, 35, 35),
        effect = "owner",
        font   = Enum.Font.Arcade,
        size   = 20,
    },

    dev = {
        color  = Color3.fromRGB(255, 245, 245),
        glow   = Color3.fromRGB(255, 35, 35),
        effect = "dev",
        font   = Enum.Font.Arcade,
        size   = 22,
    },

    pecinha = {
        color  = Color3.fromRGB(18, 18, 18),
        glow   = Color3.fromRGB(95, 95, 95),
        effect = "pecinha",
        font   = Enum.Font.Arcade,
        size   = 21,
    },

    vip = {
        color  = Color3.fromRGB(255, 255, 255),
        glow   = Color3.fromRGB(90, 220, 120),
        effect = "vip",
        font   = Enum.Font.Arcade,
        size   = 19,
    },

    homie = {
        color  = Color3.fromRGB(242, 242, 242),
        glow   = Color3.fromRGB(130, 130, 150),
        effect = nil,
        font   = Enum.Font.Arcade,
        size   = 19,
    },

    user = {
        color  = Color3.fromRGB(232, 232, 232),
        glow   = Color3.fromRGB(110, 110, 120),
        effect = nil,
        font   = Enum.Font.Arcade,
        size   = 18,
    },
}

-- ──────────────────────────────────────────────────────────────
-- FIXED TAGS
-- ──────────────────────────────────────────────────────────────
local FIXED_TAGS = {
    [2450152162] = "pecinha",
    [5049907844] = "dev",
}

-- ──────────────────────────────────────────────────────────────
-- PERSISTÊNCIA
-- ──────────────────────────────────────────────────────────────
local SAVE_DIR  = "ref_tags"
local SAVE_FILE = SAVE_DIR .. "/tags.json"

local fsOk = type(isfolder)   == "function"
          and type(readfile)   == "function"
          and type(writefile)  == "function"
          and type(makefolder) == "function"

if fsOk and not isfolder(SAVE_DIR) then
    pcall(makefolder, SAVE_DIR)
end

local function loadSaved()
    if not fsOk then
        return _G._ref_tags_data or {}
    end

    local ok, raw = pcall(readfile, SAVE_FILE)
    if not ok or not raw or raw == "" then
        return {}
    end

    local t = {}
    for uid, role in raw:gmatch('"(%d+)":"([^"]+)"') do
        t[tonumber(uid)] = role
    end
    return t
end

local function saveTags(t)
    local parts = {}
    for uid, role in pairs(t) do
        table.insert(parts, '"' .. tostring(uid) .. '":"' .. role .. '"')
    end

    local json = "{" .. table.concat(parts, ",") .. "}"

    if not fsOk then
        _G._ref_tags_data = t
        return
    end

    pcall(writefile, SAVE_FILE, json)
end

local savedTags = loadSaved()

-- ──────────────────────────────────────────────────────────────
-- ESTADO
-- ──────────────────────────────────────────────────────────────
local billboards   = {}
local effectConns  = {}
local billboardsOn = true
local devPanelGui  = nil

-- ──────────────────────────────────────────────────────────────
-- HELPERS
-- ──────────────────────────────────────────────────────────────
local function getTag(p)
    return FIXED_TAGS[p.UserId] or savedTags[p.UserId]
end

local function getRole(name)
    return ROLES[name] or ROLES.user
end

local function isLocalDev()
    return getTag(player) == "dev"
end

local function disconnectEffect(p)
    if effectConns[p] then
        effectConns[p]:Disconnect()
        effectConns[p] = nil
    end
end

local function removeBillboard(p)
    disconnectEffect(p)

    if billboards[p] and billboards[p].Parent then
        billboards[p]:Destroy()
    end

    billboards[p] = nil
end

local function createSimple(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function tween(obj, props, t, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function makeCorner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
    return c
end

local function makeStroke(inst, th, tr, col)
    local s = Instance.new("UIStroke")
    s.Thickness = th or 1
    s.Transparency = tr or 0.5
    s.Color = col or Color3.fromRGB(255, 255, 255)
    s.Parent = inst
    return s
end

local function findPlayerByText(text)
    local low = tostring(text or ""):lower()
    if low == "" then
        return nil
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(low, 1, true) or p.DisplayName:lower():find(low, 1, true) then
            return p
        end
    end

    return nil
end

local function makeLabel(parent, text, font, size, color, transparency, zindex, pos, width, height)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0, width or 280, 0, height or 36)
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.Position = pos or UDim2.new(0.5, 0, 0.5, 0)
    lbl.Font = font
    lbl.TextSize = size
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.TextTransparency = transparency or 0
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.ZIndex = zindex or 1
    lbl.Parent = parent
    return lbl
end

local function addStroke(label, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    s.Color = color
    s.Thickness = thickness
    s.Transparency = transparency or 0
    s.Parent = label
    return s
end

local function buildTextVisual(bb, tagName, role)
    local root = Instance.new("Frame")
    root.Name = "tag_root"
    root.BackgroundTransparency = 1
    root.Size = UDim2.new(1, 0, 1, 0)
    root.Parent = bb

    local shadowFar = makeLabel(
        root, tagName, role.font, role.size, Color3.fromRGB(0, 0, 0),
        0.56, 1, UDim2.new(0.5, 0, 0.5, 4), 320, 42
    )

    local shadowMid = makeLabel(
        root, tagName, role.font, role.size, role.glow,
        0.38, 2, UDim2.new(0.5, 0, 0.5, 2), 312, 40
    )

    local main = makeLabel(
        root, tagName, role.font, role.size, role.color,
        0.00, 4, UDim2.new(0.5, 0, 0.5, 0), 304, 38
    )

    local shine = makeLabel(
        root, tagName, role.font, role.size, Color3.fromRGB(255, 255, 255),
        0.90, 5, UDim2.new(0.5, 0, 0.5, -1), 304, 38
    )

    local stroke = addStroke(main, role.glow, 1.25, 0.34)

    return {
        root      = root,
        shadowFar = shadowFar,
        shadowMid = shadowMid,
        main      = main,
        shine     = shine,
        stroke    = stroke,
    }
end

-- ──────────────────────────────────────────────────────────────
-- EFEITOS
-- ──────────────────────────────────────────────────────────────
local function startOwnerEffect(p, refs, role)
    disconnectEffect(p)

    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        local pulse = 0.5 + 0.5 * math.sin(t * 2.35)

        refs.shadowMid.TextColor3 = role.glow:Lerp(Color3.fromRGB(255, 88, 88), pulse * 0.45)
        refs.shadowFar.TextTransparency = 0.62 - pulse * 0.05
        refs.shadowMid.TextTransparency = 0.34 - pulse * 0.08
        refs.stroke.Transparency = 0.28 - pulse * 0.10
        refs.shine.TextTransparency = 0.90 - pulse * 0.05

        refs.main.Position      = UDim2.new(0.5, 0, 0.5, 0)
        refs.shadowMid.Position = UDim2.new(0.5, 0, 0.5, 2 + math.sin(t * 2.0) * 0.6)
        refs.shadowFar.Position = UDim2.new(0.5, 0, 0.5, 4 + math.sin(t * 1.7) * 0.5)
    end)
end

local function startDevEffect(p, refs, role)
    disconnectEffect(p)

    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt

        local pulse  = 0.5 + 0.5 * math.sin(t * 3.8)
        local pulse2 = 0.5 + 0.5 * math.sin(t * 7.2 + 0.7)
        local shake  = math.sin(t * 18) * 0.8
        local shake2 = math.cos(t * 14) * 1.2
        local flash  = 0.5 + 0.5 * math.sin(t * 11)

        refs.shadowMid.TextColor3 = role.glow:Lerp(Color3.fromRGB(255, 110, 110), pulse * 0.65)
        refs.shadowFar.TextColor3 = Color3.fromRGB(70, 0, 0)

        refs.shadowMid.TextTransparency = 0.20 - pulse * 0.08
        refs.shadowFar.TextTransparency = 0.48 - pulse2 * 0.06
        refs.stroke.Transparency = 0.16 - pulse * 0.08
        refs.stroke.Thickness = 1.3 + pulse * 0.9
        refs.shine.TextTransparency = 0.84 - flash * 0.10

        refs.main.Position      = UDim2.new(0.5, shake * 0.45, 0.5, 0)
        refs.shine.Position     = UDim2.new(0.5, shake * 0.55, 0.5, -1)
        refs.shadowMid.Position = UDim2.new(0.5, shake2, 0.5, 2)
        refs.shadowFar.Position = UDim2.new(0.5, shake2 * 1.25, 0.5, 4)

        refs.main.Rotation      = math.sin(t * 6.5) * 0.35
        refs.shine.Rotation     = math.sin(t * 6.5) * 0.45
        refs.shadowMid.Rotation = math.sin(t * 6.5) * 0.55
        refs.shadowFar.Rotation = math.sin(t * 6.5) * 0.75
    end)
end

local function startPecinhaEffect(p, refs, role)
    disconnectEffect(p)

    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        local pulse = 0.5 + 0.5 * math.sin(t * 2.1)

        refs.shadowMid.TextColor3 = role.glow
        refs.shadowFar.TextColor3 = Color3.fromRGB(0, 0, 0)
        refs.shadowMid.TextTransparency = 0.28 - pulse * 0.04
        refs.shadowFar.TextTransparency = 0.50 - pulse * 0.03
        refs.stroke.Transparency = 0.46 - pulse * 0.08
        refs.shine.TextTransparency = 0.97

        refs.main.Position      = UDim2.new(0.5, 0, 0.5, 0)
        refs.shadowMid.Position = UDim2.new(0.5, 0, 0.5, 2)
        refs.shadowFar.Position = UDim2.new(0.5, 0, 0.5, 4)
    end)
end

local function startVipEffect(p, refs, role)
    disconnectEffect(p)

    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        local pulse = 0.5 + 0.5 * math.sin(t * 2.5)

        refs.shadowMid.TextColor3 = role.glow
        refs.shadowMid.TextTransparency = 0.36 - pulse * 0.06
        refs.shadowFar.TextTransparency = 0.60 - pulse * 0.04
        refs.stroke.Transparency = 0.40 - pulse * 0.08
        refs.shine.TextTransparency = 0.92 - pulse * 0.04
    end)
end

local function applyEffect(p, refs, role)
    if role.effect == "owner" then
        startOwnerEffect(p, refs, role)
    elseif role.effect == "dev" then
        startDevEffect(p, refs, role)
    elseif role.effect == "pecinha" then
        startPecinhaEffect(p, refs, role)
    elseif role.effect == "vip" then
        startVipEffect(p, refs, role)
    else
        disconnectEffect(p)
    end
end

-- ──────────────────────────────────────────────────────────────
-- BILLBOARD
-- ──────────────────────────────────────────────────────────────
local function createBillboard(p)
    removeBillboard(p)

    local c = p.Character
    if not c then return end

    local head = c:FindFirstChild("Head")
    if not head then return end

    local tagName = getTag(p)
    if not tagName then return end

    local role = getRole(tagName)

    local bb = Instance.new("BillboardGui")
    bb.Name = "ref_tag_bb"
    bb.Size = UDim2.new(0, 320, 0, 42)
    bb.StudsOffset = Vector3.new(0, 3.75, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = 250
    bb.ResetOnSpawn = false
    bb.Adornee = head
    bb.Parent = head

    local refs = buildTextVisual(bb, tagName, role)
    applyEffect(p, refs, role)

    billboards[p] = bb
end

local function refreshBillboard(p)
    removeBillboard(p)
    if billboardsOn then
        createBillboard(p)
    end
end

-- ──────────────────────────────────────────────────────────────
-- DEV PANEL
-- ──────────────────────────────────────────────────────────────
local TagSystem = {}

local function destroyDevPanel()
    if devPanelGui and devPanelGui.Parent then
        devPanelGui:Destroy()
    end
    devPanelGui = nil
end

local function createDevPanel(lib)
    destroyDevPanel()

    if not isLocalDev() then
        return
    end

    local T = lib.Theme

    local sg = createSimple("ScreenGui", {
        Name = "ref_dev_tag_panel",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1001,
        Parent = pg,
    })

    local main = createSimple("Frame", {
        Size = UDim2.new(0, 270, 0, 190),
        Position = UDim2.new(1, -290, 0, 90),
        BackgroundColor3 = T.Panel,
        BorderSizePixel = 0,
        Parent = sg,
    })
    makeCorner(main, 12)
    makeStroke(main, 1.2, 0.22, Color3.fromRGB(255, 45, 45))

    local title = createSimple("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 10, 0, 8),
        Font = Enum.Font.Arcade,
        Text = "dev tags",
        TextSize = 17,
        TextColor3 = Color3.fromRGB(255, 242, 242),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = main,
    })

    local nickBox = createSimple("TextBox", {
        Size = UDim2.new(1, -20, 0, 32),
        Position = UDim2.new(0, 10, 0, 42),
        BackgroundColor3 = T.Panel2,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        PlaceholderText = "nick / displayname",
        Text = "",
        TextSize = 13,
        TextColor3 = T.Text,
        PlaceholderColor3 = T.Sub,
        ClearTextOnFocus = false,
        Parent = main,
    })
    makeCorner(nickBox, 8)

    local roleBox = createSimple("TextBox", {
        Size = UDim2.new(1, -20, 0, 32),
        Position = UDim2.new(0, 10, 0, 82),
        BackgroundColor3 = T.Panel2,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        PlaceholderText = "role: dev / pecinha / vip / homie / user / owner",
        Text = "dev",
        TextSize = 13,
        TextColor3 = T.Text,
        PlaceholderColor3 = T.Sub,
        ClearTextOnFocus = false,
        Parent = main,
    })
    makeCorner(roleBox, 8)

    local status = createSimple("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 10, 0, 120),
        Font = Enum.Font.Gotham,
        Text = "ready",
        TextSize = 12,
        TextColor3 = T.Sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = main,
    })

    local closeBtn = createSimple("TextButton", {
        Size = UDim2.new(0, 26, 0, 22),
        Position = UDim2.new(1, -34, 0, 8),
        BackgroundColor3 = T.Panel2,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "x",
        TextSize = 12,
        TextColor3 = T.Text,
        AutoButtonColor = false,
        Parent = main,
    })
    makeCorner(closeBtn, 7)

    local applyBtn = createSimple("TextButton", {
        Size = UDim2.new(0, 118, 0, 34),
        Position = UDim2.new(0, 10, 0, 146),
        BackgroundColor3 = Color3.fromRGB(170, 35, 35),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "aplicar",
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
        Parent = main,
    })
    makeCorner(applyBtn, 8)

    local removeBtn = createSimple("TextButton", {
        Size = UDim2.new(0, 118, 0, 34),
        Position = UDim2.new(0, 142, 0, 146),
        BackgroundColor3 = Color3.fromRGB(70, 70, 82),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "remover",
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
        Parent = main,
    })
    makeCorner(removeBtn, 8)

    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(85, 30, 30) }, 0.12)
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundColor3 = T.Panel2 }, 0.12)
    end)
    closeBtn.MouseButton1Click:Connect(destroyDevPanel)

    applyBtn.MouseEnter:Connect(function()
        tween(applyBtn, { BackgroundColor3 = Color3.fromRGB(190, 45, 45) }, 0.12)
    end)
    applyBtn.MouseLeave:Connect(function()
        tween(applyBtn, { BackgroundColor3 = Color3.fromRGB(170, 35, 35) }, 0.12)
    end)

    removeBtn.MouseEnter:Connect(function()
        tween(removeBtn, { BackgroundColor3 = Color3.fromRGB(90, 90, 102) }, 0.12)
    end)
    removeBtn.MouseLeave:Connect(function()
        tween(removeBtn, { BackgroundColor3 = Color3.fromRGB(70, 70, 82) }, 0.12)
    end)

    local dragging, dragStart, startPos = false, nil, nil
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    applyBtn.MouseButton1Click:Connect(function()
        if not isLocalDev() then
            status.Text = "sem permissao"
            status.TextColor3 = T.Bad
            return
        end

        local target = findPlayerByText(nickBox.Text)
        local role = tostring(roleBox.Text):lower()

        if not target then
            status.Text = "player nao encontrado"
            status.TextColor3 = T.Bad
            return
        end

        if not ROLES[role] then
            status.Text = "role invalida"
            status.TextColor3 = T.Bad
            return
        end

        local ok, err = TagSystem.setTag(target.UserId, role)
        if ok then
            refreshBillboard(target)
            status.Text = target.DisplayName .. " -> " .. role
            status.TextColor3 = T.Good
        else
            status.Text = err or "erro"
            status.TextColor3 = T.Bad
        end
    end)

    removeBtn.MouseButton1Click:Connect(function()
        if not isLocalDev() then
            status.Text = "sem permissao"
            status.TextColor3 = T.Bad
            return
        end

        local target = findPlayerByText(nickBox.Text)
        if not target then
            status.Text = "player nao encontrado"
            status.TextColor3 = T.Bad
            return
        end

        local ok, err = TagSystem.removeTag(target.UserId)
        if ok then
            removeBillboard(target)
            status.Text = "tag removida de " .. target.DisplayName
            status.TextColor3 = T.Good
        else
            status.Text = err or "erro"
            status.TextColor3 = T.Bad
        end
    end)

    devPanelGui = sg
end

-- ──────────────────────────────────────────────────────────────
-- WATCH PLAYERS
-- ──────────────────────────────────────────────────────────────
local function watchPlayer(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.35)
        if billboardsOn then
            createBillboard(p)
        end
    end)

    if p.Character then
        task.spawn(function()
            task.wait(0.35)
            if billboardsOn then
                createBillboard(p)
            end
        end)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(watchPlayer, p)
end

Players.PlayerAdded:Connect(watchPlayer)

Players.PlayerRemoving:Connect(function(p)
    removeBillboard(p)
    billboards[p] = nil
end)

RunService.Heartbeat:Connect(function()
    if not billboardsOn then
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        local bb = billboards[p]
        local hasTag = getTag(p) ~= nil

        if hasTag then
            if not bb or not bb.Parent then
                createBillboard(p)
            end
        else
            if bb then
                removeBillboard(p)
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────────────
-- INTEGRAÇÃO REFLIB
-- ──────────────────────────────────────────────────────────────
function TagSystem.init(lib)
    _G.__last_ref_lib = lib

    local T   = lib.Theme
    local tab = lib:Tab("tags")

    local secSet = tab:Section("atribuir tag", true)
    secSet:Divider("buscar player")

    local targetPlayer = nil
    local card = secSet:AvatarCard()

    secSet:TextInput("nick", "username ou displayname", function(text, enter)
        if not enter then return end

        local found = findPlayerByText(text)
        targetPlayer = found
        card.Set(found)

        if not found then
            lib:Toast(lib._icon, "tags", "player não encontrado", T.Bad)
        end
    end)

    local roleNames = {}
    for name in pairs(ROLES) do
        table.insert(roleNames, name)
    end
    table.sort(roleNames)

    local selectedRole = roleNames[1]
    secSet:Dropdown("role", roleNames, selectedRole, function(v)
        selectedRole = v
    end)

    secSet:Divider("ações")

    secSet:Button("aplicar tag", function()
        if not targetPlayer then
            lib:Toast(lib._icon, "tags", "selecione um player", T.Bad)
            return
        end

        if FIXED_TAGS[targetPlayer.UserId] then
            lib:Toast(lib._icon, "tags", "tag fixa — não pode alterar", T.Bad)
            return
        end

        savedTags[targetPlayer.UserId] = selectedRole
        saveTags(savedTags)
        refreshBillboard(targetPlayer)

        lib:Toast(lib._icon, "tags", targetPlayer.DisplayName .. " → " .. selectedRole, T.Accent)
    end)

    secSet:Button("remover tag", function()
        if not targetPlayer then
            lib:Toast(lib._icon, "tags", "selecione um player", T.Bad)
            return
        end

        if FIXED_TAGS[targetPlayer.UserId] then
            lib:Toast(lib._icon, "tags", "tag fixa — não pode remover", T.Bad)
            return
        end

        savedTags[targetPlayer.UserId] = nil
        saveTags(savedTags)
        removeBillboard(targetPlayer)

        lib:Toast(lib._icon, "tags", "tag removida: " .. targetPlayer.DisplayName, T.Sub)
    end)

    local secList = tab:Section("tags ativas", true)
    local listLbl = secList:Label("nenhuma tag registrada")

    local function refreshList()
        local lines = {}

        for uid, role in pairs(FIXED_TAGS) do
            local name = "[" .. uid .. "]"
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == uid then
                    name = p.DisplayName
                    break
                end
            end
            table.insert(lines, "★ " .. name .. " → " .. role .. " (fixo)")
        end

        for uid, role in pairs(savedTags) do
            local name = "[" .. uid .. "]"
            for _, p in ipairs(Players:GetPlayers()) do
                if p.UserId == uid then
                    name = p.DisplayName
                    break
                end
            end
            table.insert(lines, "• " .. name .. " → " .. role)
        end

        listLbl.Set(#lines > 0 and table.concat(lines, "\n") or "nenhuma tag registrada")
    end

    refreshList()

    secList:Button("atualizar lista", refreshList)
    secList:Button("limpar tags salvas", function()
        savedTags = {}
        saveTags(savedTags)

        for _, p in ipairs(Players:GetPlayers()) do
            if not FIXED_TAGS[p.UserId] then
                removeBillboard(p)
            end
        end

        refreshList()
        lib:Toast(lib._icon, "tags", "tags salvas removidas", T.Sub)
    end)

    local secVis = tab:Section("visibilidade")
    secVis:Toggle("mostrar tags acima da cabeça", true, function(v)
        billboardsOn = v

        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                createBillboard(p)
            end
        else
            for _, p in ipairs(Players:GetPlayers()) do
                removeBillboard(p)
            end
        end
    end)

    lib:Toast(lib._icon, "ref tags", "sistema de tags carregado", T.Accent)

    task.spawn(function()
        task.wait(0.2)
        createDevPanel(lib)
    end)
end

-- ──────────────────────────────────────────────────────────────
-- API PÚBLICA
-- ──────────────────────────────────────────────────────────────
function TagSystem.setTag(userId, role)
    if FIXED_TAGS[userId] then
        return false, "tag fixa"
    end

    if not ROLES[role] then
        return false, "role inválida"
    end

    savedTags[userId] = role
    saveTags(savedTags)

    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then
            refreshBillboard(p)
            break
        end
    end

    if userId == player.UserId then
        task.spawn(function()
            task.wait(0.15)
            if role == "dev" and _G.__last_ref_lib then
                createDevPanel(_G.__last_ref_lib)
            elseif role ~= "dev" then
                destroyDevPanel()
            end
        end)
    end

    return true
end

function TagSystem.removeTag(userId)
    if FIXED_TAGS[userId] then
        return false, "tag fixa"
    end

    savedTags[userId] = nil
    saveTags(savedTags)

    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then
            removeBillboard(p)
            break
        end
    end

    if userId == player.UserId then
        destroyDevPanel()
    end

    return true
end

function TagSystem.addFixed(userId, role)
    FIXED_TAGS[userId] = role

    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then
            refreshBillboard(p)
            break
        end
    end

    if userId == player.UserId and role == "dev" and _G.__last_ref_lib then
        task.spawn(function()
            task.wait(0.15)
            createDevPanel(_G.__last_ref_lib)
        end)
    end
end

function TagSystem.addRole(name, color, textColor, icon, effect)
    ROLES[name] = {
        color  = textColor or Color3.new(1, 1, 1),
        glow   = color or Color3.new(1, 1, 1),
        effect = effect,
        font   = Enum.Font.Arcade,
        size   = 19,
    }
end

function TagSystem.getTag(userId)
    return FIXED_TAGS[userId] or savedTags[userId]
end

return TagSystem
