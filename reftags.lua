-- ref_tags.lua v3
-- sistema de tags melhorado
-- visual: texto solto acima do nick, sem cápsula, sem borda de billboard
-- aura aplicada no próprio texto
-- funciona também no localplayer

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player       = Players.LocalPlayer
local pg           = player:WaitForChild("PlayerGui")

-- ──────────────────────────────────────────────────────────────
-- ROLES
-- ──────────────────────────────────────────────────────────────
local ROLES = {
    owner = {
        color  = Color3.fromRGB(180, 20, 20),
        text   = Color3.fromRGB(255, 235, 235),
        icon   = "♔",
        effect = "owner",
        font   = Enum.Font.GothamBlack,
        size   = 16,
    },

    dev = {
        color  = Color3.fromRGB(15, 60, 210),
        text   = Color3.fromRGB(210, 235, 255),
        icon   = "⚡",
        effect = "dev",
        font   = Enum.Font.Code,
        size   = 15,
    },

    pecinha = {
        color  = Color3.fromRGB(12, 12, 12),
        text   = Color3.fromRGB(255, 170, 215),
        icon   = "☯",
        effect = "pecinha",
        font   = Enum.Font.GothamBold,
        size   = 16,
    },

    vip = {
        color  = Color3.fromRGB(80, 210, 110),
        text   = Color3.fromRGB(215, 255, 225),
        icon   = "✦",
        effect = "vip",
        font   = Enum.Font.GothamBold,
        size   = 15,
    },

    homie = {
        color  = Color3.fromRGB(170, 170, 190),
        text   = Color3.fromRGB(225, 225, 235),
        icon   = "~",
        effect = nil,
        font   = Enum.Font.GothamBold,
        size   = 15,
    },

    user = {
        color  = Color3.fromRGB(45, 45, 55),
        text   = Color3.fromRGB(190, 190, 205),
        icon   = "",
        effect = nil,
        font   = Enum.Font.GothamBold,
        size   = 14,
    },
}

-- ──────────────────────────────────────────────────────────────
-- FIXED TAGS — coloque seus userIds aqui
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
local billboards  = {}
local effectConns = {}
local billboardsOn = true

local function getTag(p)
    return FIXED_TAGS[p.UserId] or savedTags[p.UserId]
end

local function getRole(name)
    return ROLES[name] or ROLES.user
end

local function lerpColor(a, b, t)
    return a:Lerp(b, t)
end

local function disconnectEffect(p)
    local conn = effectConns[p]
    if conn then
        conn:Disconnect()
        effectConns[p] = nil
    end
end

local function removeBillboard(p)
    disconnectEffect(p)

    local bb = billboards[p]
    if bb and bb.Parent then
        bb:Destroy()
    end

    billboards[p] = nil
end

local function makeTextLabel(parent, props)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel = 0
    lbl.Size = props.Size or UDim2.new(1, 0, 1, 0)
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.Position = props.Position or UDim2.new(0.5, 0, 0.5, 0)
    lbl.TextScaled = false
    lbl.RichText = false
    lbl.TextWrapped = false
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.ZIndex = props.ZIndex or 1
    lbl.Font = props.Font or Enum.Font.GothamBold
    lbl.TextSize = props.TextSize or 15
    lbl.Text = props.Text or ""
    lbl.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
    lbl.TextTransparency = props.TextTransparency or 0
    lbl.Rotation = props.Rotation or 0
    lbl.Parent = parent

    return lbl
end

local function setupGradient(label, colors, rotation)
    local g = Instance.new("UIGradient")
    g.Rotation = rotation or 0
    g.Color = ColorSequence.new(colors)
    g.Parent = label
    return g
end

local function setupStroke(label, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    s.Color = color
    s.Thickness = thickness
    s.Transparency = transparency or 0
    s.Parent = label
    return s
end

local function buildTextSet(container, tagName, role)
    local text = (role.icon ~= "" and (role.icon .. " " .. tagName) or tagName)

    local root = Instance.new("Frame")
    root.Name = "tag_root"
    root.BackgroundTransparency = 1
    root.Size = UDim2.new(1, 0, 1, 0)
    root.Parent = container

    local auraBackFar = makeTextLabel(root, {
        Text = text,
        Font = role.font,
        TextSize = role.size,
        TextColor3 = role.color,
        TextTransparency = 0.70,
        Position = UDim2.new(0.5, 0, 0.5, 2),
        ZIndex = 1,
        Size = UDim2.new(1, 40, 1, 20),
    })

    local auraBack = makeTextLabel(root, {
        Text = text,
        Font = role.font,
        TextSize = role.size,
        TextColor3 = role.color,
        TextTransparency = 0.45,
        Position = UDim2.new(0.5, 0, 0.5, 1),
        ZIndex = 2,
        Size = UDim2.new(1, 30, 1, 16),
    })

    local main = makeTextLabel(root, {
        Text = text,
        Font = role.font,
        TextSize = role.size,
        TextColor3 = role.text,
        TextTransparency = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        ZIndex = 4,
        Size = UDim2.new(1, 20, 1, 12),
    })

    local shine = makeTextLabel(root, {
        Text = text,
        Font = role.font,
        TextSize = role.size,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextTransparency = 0.82,
        Position = UDim2.new(0.5, 0, 0.5, -1),
        ZIndex = 5,
        Size = UDim2.new(1, 20, 1, 12),
    })

    local softStroke = setupStroke(main, role.color, 1.1, 0.30)

    return {
        root = root,
        main = main,
        shine = shine,
        auraBack = auraBack,
        auraBackFar = auraBackFar,
        softStroke = softStroke,
    }
end

-- ──────────────────────────────────────────────────────────────
-- EFEITOS NO TEXTO
-- ──────────────────────────────────────────────────────────────
local function startOwnerTextEffect(p, refs)
    disconnectEffect(p)

    local t = 0
    local g1 = setupGradient(refs.main, {
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 245, 245)),
        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(255, 170, 170)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 235, 235)),
    }, 0)

    refs.softStroke.Color = Color3.fromRGB(255, 90, 70)

    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt

        local pulse = 0.5 + 0.5 * math.sin(t * 3.2)
        local flick = math.noise(t * 10, 0, 0) * 0.5 + 0.5

        refs.auraBack.TextTransparency = 0.38 - pulse * 0.10
        refs.auraBackFar.TextTransparency = 0.68 - pulse * 0.08
        refs.auraBack.Position = UDim2.new(0.5, math.sin(t * 5) * 1.5, 0.5, 1 + math.cos(t * 3) * 1.5)
        refs.auraBackFar.Position = UDim2.new(0.5, math.cos(t * 4) * 2, 0.5, 2 + math.sin(t * 2.7) * 2)

        refs.auraBack.TextColor3 = lerpColor(
            Color3.fromRGB(180, 20, 20),
            Color3.fromRGB(255, 120, 40),
            flick
        )

        refs.auraBackFar.TextColor3 = lerpColor(
            Color3.fromRGB(120, 10, 10),
            Color3.fromRGB(255, 70, 20),
            pulse
        )

        refs.shine.TextTransparency = 0.80 - pulse * 0.12
        refs.shine.Position = UDim2.new(0.5, 0, 0.5, -1 - pulse * 1.5)
        refs.softStroke.Transparency = 0.22 - pulse * 0.10
        g1.Offset = Vector2.new((t * 0.22) % 1, 0)
    end)
end

local function startDevTextEffect(p, refs)
    disconnectEffect(p)

    local t = 0
    local g1 = setupGradient(refs.main, {
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(235, 248, 255)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(140, 215, 255)),
        ColorSequenceKeypoint.new(0.70, Color3.fromRGB(90, 150, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(235, 248, 255)),
    }, 0)

    refs.softStroke.Color = Color3.fromRGB(90, 175, 255)

    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt

        local pulse = 0.5 + 0.5 * math.sin(t * 4.2)
        local pulse2 = 0.5 + 0.5 * math.sin(t * 8.0)

        refs.auraBack.TextColor3 = lerpColor(
            Color3.fromRGB(15, 60, 210),
            Color3.fromRGB(80, 210, 255),
            pulse
        )

        refs.auraBackFar.TextColor3 = lerpColor(
            Color3.fromRGB(10, 35, 120),
            Color3.fromRGB(120, 220, 255),
            pulse2
        )

        refs.auraBack.TextTransparency = 0.34 - pulse * 0.08
        refs.auraBackFar.TextTransparency = 0.62 - pulse2 * 0.08

        refs.auraBack.Position = UDim2.new(0.5, math.sin(t * 9) * 2, 0.5, math.cos(t * 11) * 1.5)
        refs.auraBackFar.Position = UDim2.new(0.5, math.cos(t * 7) * 3, 0.5, 2 + math.sin(t * 6) * 2)

        refs.shine.TextTransparency = 0.78 - pulse * 0.18
        refs.shine.Position = UDim2.new(0.5, math.sin(t * 6) * 1, 0.5, -1)

        refs.softStroke.Transparency = 0.25 - pulse * 0.12
        refs.softStroke.Thickness = 1.0 + pulse * 0.9
        g1.Offset = Vector2.new((t * 0.45) % 1, 0)
    end)
end

local function startPecinhaTextEffect(p, refs)
    disconnectEffect(p)

    local t = 0
    local g1 = setupGradient(refs.main, {
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 240, 248)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 170, 215)),
        ColorSequenceKeypoint.new(0.70, Color3.fromRGB(255, 120, 190)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 240, 248)),
    }, 0)

    refs.softStroke.Color = Color3.fromRGB(255, 105, 180)

    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt

        local pulse = 0.5 + 0.5 * math.sin(t * 3.1)
        local pulse2 = 0.5 + 0.5 * math.sin(t * 2.4 + 1.3)

        refs.auraBack.TextColor3 = lerpColor(
            Color3.fromRGB(255, 110, 190),
            Color3.fromRGB(255, 170, 215),
            pulse
        )

        refs.auraBackFar.TextColor3 = lerpColor(
            Color3.fromRGB(35, 20, 30),
            Color3.fromRGB(255, 120, 210),
            pulse2
        )

        refs.auraBack.TextTransparency = 0.30 - pulse * 0.10
        refs.auraBackFar.TextTransparency = 0.58 - pulse2 * 0.12

        refs.auraBack.Position = UDim2.new(0.5, math.sin(t * 2.4) * 2, 0.5, 0)
        refs.auraBackFar.Position = UDim2.new(0.5, math.cos(t * 2.1) * 3, 0.5, 2 + math.sin(t * 2.8) * 2)

        refs.shine.TextTransparency = 0.82 - pulse * 0.10
        refs.shine.Position = UDim2.new(0.5, 0, 0.5, -1 - math.sin(t * 2) * 1)

        refs.softStroke.Transparency = 0.20 - pulse * 0.08
        refs.softStroke.Thickness = 1.0 + pulse * 0.5
        g1.Offset = Vector2.new((t * 0.15) % 1, 0)
    end)
end

local function startVipTextEffect(p, refs)
    disconnectEffect(p)

    local t = 0
    local g1 = setupGradient(refs.main, {
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(240, 255, 240)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(120, 255, 160)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(240, 255, 240)),
    }, 0)

    refs.softStroke.Color = Color3.fromRGB(90, 255, 140)

    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt

        local pulse = 0.5 + 0.5 * math.sin(t * 2.5)

        refs.auraBack.TextTransparency = 0.45 - pulse * 0.08
        refs.auraBackFar.TextTransparency = 0.70 - pulse * 0.06
        refs.auraBack.Position = UDim2.new(0.5, 0, 0.5, 0)
        refs.auraBackFar.Position = UDim2.new(0.5, 0, 0.5, 2)

        refs.shine.TextTransparency = 0.86 - pulse * 0.08
        refs.softStroke.Transparency = 0.35 - pulse * 0.10
        g1.Offset = Vector2.new((t * 0.18) % 1, 0)
    end)
end

local function applyEffect(p, refs, role)
    if role.effect == "owner" then
        startOwnerTextEffect(p, refs)
    elseif role.effect == "dev" then
        startDevTextEffect(p, refs)
    elseif role.effect == "pecinha" then
        startPecinhaTextEffect(p, refs)
    elseif role.effect == "vip" then
        startVipTextEffect(p, refs)
    else
        disconnectEffect(p)
    end
end

-- ──────────────────────────────────────────────────────────────
-- CRIAR / ATUALIZAR BILLBOARD
-- ──────────────────────────────────────────────────────────────
local function createBillboard(p)
    removeBillboard(p)

    local c = p.Character
    if not c then
        return
    end

    local head = c:FindFirstChild("Head")
    if not head then
        return
    end

    local tagName = getTag(p)
    if not tagName then
        return
    end

    local role = getRole(tagName)

    local bb = Instance.new("BillboardGui")
    bb.Name = "ref_tag_bb"
    bb.Size = UDim2.new(0, 230, 0, 44)
    bb.StudsOffset = Vector3.new(0, 3.45, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = 250
    bb.ResetOnSpawn = false
    bb.Adornee = head
    bb.Parent = head

    local refs = buildTextSet(bb, tagName, role)
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
local TagSystem = {}

function TagSystem.init(lib)
    local T   = lib.Theme
    local tab = lib:Tab("tags")

    -- ── atribuir ──
    local secSet = tab:Section("atribuir tag", true)
    secSet:Divider("buscar player")

    local targetPlayer = nil
    local card = secSet:AvatarCard()

    secSet:TextInput("nick", "username ou displayname", function(text, enter)
        if not enter then
            return
        end

        local low = tostring(text):lower()
        local found = nil

        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(low, 1, true) or p.DisplayName:lower():find(low, 1, true) then
                found = p
                break
            end
        end

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

    -- ── lista ──
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

    -- ── visibilidade ──
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
end

function TagSystem.addRole(name, color, textColor, icon, effect)
    ROLES[name] = {
        color  = color,
        text   = textColor or Color3.new(1, 1, 1),
        icon   = icon or "",
        effect = effect,
        font   = Enum.Font.GothamBold,
        size   = 15,
    }
end

function TagSystem.getTag(userId)
    return FIXED_TAGS[userId] or savedTags[userId]
end

return TagSystem
