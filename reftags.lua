-- ref_tags.lua v4
-- visual clean: texto solto, sem fundo, sem borda, sem ícones
-- aura aplicada no próprio texto
-- localplayer também recebe tag

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
        color  = Color3.fromRGB(255, 215, 215),
        glow   = Color3.fromRGB(190, 35, 35),
        effect = "owner",
        font   = Enum.Font.Arcade,
        size   = 18,
    },

    dev = {
        color  = Color3.fromRGB(255, 235, 235),
        glow   = Color3.fromRGB(210, 35, 35), -- vermelho
        effect = "dev",
        font   = Enum.Font.Arcade,
        size   = 18,
    },

    pecinha = {
        color  = Color3.fromRGB(20, 20, 20),  -- preto
        glow   = Color3.fromRGB(90, 90, 90),
        effect = "pecinha",
        font   = Enum.Font.Arcade,
        size   = 18,
    },

    vip = {
        color  = Color3.fromRGB(255, 255, 255),
        glow   = Color3.fromRGB(90, 220, 120),
        effect = "vip",
        font   = Enum.Font.Arcade,
        size   = 17,
    },

    homie = {
        color  = Color3.fromRGB(240, 240, 240),
        glow   = Color3.fromRGB(130, 130, 150),
        effect = nil,
        font   = Enum.Font.Arcade,
        size   = 17,
    },

    user = {
        color  = Color3.fromRGB(230, 230, 230),
        glow   = Color3.fromRGB(110, 110, 120),
        effect = nil,
        font   = Enum.Font.Arcade,
        size   = 16,
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

local function getTag(p)
    return FIXED_TAGS[p.UserId] or savedTags[p.UserId]
end

local function getRole(name)
    return ROLES[name] or ROLES.user
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

local function makeLabel(parent, text, font, size, color, transparency, zindex, pos, anchor, width, height)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0, width or 220, 0, height or 32)
    lbl.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
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

    -- sombra bem suave
    local shadowFar = makeLabel(
        root, tagName, role.font, role.size, Color3.fromRGB(0, 0, 0),
        0.55, 1, UDim2.new(0.5, 0, 0.5, 3), nil, 260, 36
    )

    local shadowMid = makeLabel(
        root, tagName, role.font, role.size, role.glow,
        0.40, 2, UDim2.new(0.5, 0, 0.5, 1), nil, 250, 34
    )

    local main = makeLabel(
        root, tagName, role.font, role.size, role.color,
        0.00, 4, UDim2.new(0.5, 0, 0.5, 0), nil, 240, 32
    )

    local shine = makeLabel(
        root, tagName, role.font, role.size, Color3.fromRGB(255, 255, 255),
        0.88, 5, UDim2.new(0.5, 0, 0.5, -1), nil, 240, 32
    )

    local stroke = addStroke(main, role.glow, 1.2, 0.35)

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

        local pulse = 0.5 + 0.5 * math.sin(t * 2.2)

        refs.shadowMid.TextColor3 = role.glow:Lerp(Color3.fromRGB(255, 80, 80), pulse * 0.45)
        refs.shadowFar.TextTransparency = 0.62 - pulse * 0.05
        refs.shadowMid.TextTransparency = 0.42 - pulse * 0.08
        refs.stroke.Transparency = 0.38 - pulse * 0.10
        refs.shine.TextTransparency = 0.90 - pulse * 0.06

        refs.shadowMid.Position = UDim2.new(0.5, 0, 0.5, 1 + math.sin(t * 2.0) * 0.5)
        refs.shadowFar.Position = UDim2.new(0.5, 0, 0.5, 3 + math.sin(t * 1.7) * 0.5)
    end)
end

local function startDevEffect(p, refs, role)
    disconnectEffect(p)

    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt

        local pulse  = 0.5 + 0.5 * math.sin(t * 3.2)
        local pulse2 = 0.5 + 0.5 * math.sin(t * 6.0)

        refs.shadowMid.TextColor3 = role.glow:Lerp(Color3.fromRGB(255, 95, 95), pulse * 0.55)
        refs.shadowFar.TextColor3 = Color3.fromRGB(0, 0, 0)
        refs.shadowMid.TextTransparency = 0.34 - pulse * 0.10
        refs.shadowFar.TextTransparency = 0.58 - pulse2 * 0.04
        refs.stroke.Transparency = 0.28 - pulse * 0.10
        refs.stroke.Thickness = 1.15 + pulse * 0.35
        refs.shine.TextTransparency = 0.90 - pulse * 0.08

        -- leve tremidinha tech, mas discreta
        refs.main.Position      = UDim2.new(0.5, math.sin(t * 7.5) * 0.4, 0.5, 0)
        refs.shine.Position     = UDim2.new(0.5, math.sin(t * 7.5) * 0.5, 0.5, -1)
        refs.shadowMid.Position = UDim2.new(0.5, math.sin(t * 7.5) * 0.8, 0.5, 1)
        refs.shadowFar.Position = UDim2.new(0.5, math.sin(t * 7.5) * 1.0, 0.5, 3)
    end)
end

local function startPecinhaEffect(p, refs, role)
    disconnectEffect(p)

    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt

        local pulse = 0.5 + 0.5 * math.sin(t * 2.0)

        refs.shadowMid.TextColor3 = role.glow
        refs.shadowFar.TextColor3 = Color3.fromRGB(0, 0, 0)
        refs.shadowMid.TextTransparency = 0.30 - pulse * 0.05
        refs.shadowFar.TextTransparency = 0.52 - pulse * 0.03
        refs.stroke.Transparency = 0.48 - pulse * 0.08
        refs.shine.TextTransparency = 0.96

        -- quase parado, elegante
        refs.main.Position      = UDim2.new(0.5, 0, 0.5, 0)
        refs.shadowMid.Position = UDim2.new(0.5, 0, 0.5, 1)
        refs.shadowFar.Position = UDim2.new(0.5, 0, 0.5, 3)
    end)
end

local function startVipEffect(p, refs, role)
    disconnectEffect(p)

    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt

        local pulse = 0.5 + 0.5 * math.sin(t * 2.4)

        refs.shadowMid.TextColor3 = role.glow
        refs.shadowMid.TextTransparency = 0.38 - pulse * 0.06
        refs.shadowFar.TextTransparency = 0.62 - pulse * 0.04
        refs.stroke.Transparency = 0.42 - pulse * 0.08
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
-- CRIAR BILLBOARD
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
    bb.Size = UDim2.new(0, 260, 0, 36)
    bb.StudsOffset = Vector3.new(0, 3.55, 0)
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
    if not billboardsOn then return end

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

    local secSet = tab:Section("atribuir tag", true)
    secSet:Divider("buscar player")

    local targetPlayer = nil
    local card = secSet:AvatarCard()

    secSet:TextInput("nick", "username ou displayname", function(text, enter)
        if not enter then return end

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
        color  = textColor or Color3.new(1, 1, 1),
        glow   = color or Color3.new(1, 1, 1),
        effect = effect,
        font   = Enum.Font.Arcade,
        size   = 17,
    }
end

function TagSystem.getTag(userId)
    return FIXED_TAGS[userId] or savedTags[userId]
end

return TagSystem
