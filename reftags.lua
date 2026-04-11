-- ref_tags.lua v2
-- Sistema de tags com efeitos visuais únicos por role
-- Uso: local Tags = loadstring(...)()  →  Tags.init(lib)

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player       = Players.LocalPlayer
local pg           = player:WaitForChild("PlayerGui")

-- ──────────────────────────────────────────────────────────────
-- ROLES
-- ──────────────────────────────────────────────────────────────
local ROLES = {
    owner   = { color = Color3.fromRGB(180, 20,  20),  text = Color3.fromRGB(255, 210, 210), icon = "♔",  effect = "owner"   },
    dev     = { color = Color3.fromRGB(15,  60,  210), text = Color3.fromRGB(190, 220, 255), icon = "⚡", effect = "dev"     },
    pecinha = { color = Color3.fromRGB(12,  12,  12),  text = Color3.fromRGB(255, 160, 210), icon = "☯",  effect = "pecinha" },
    vip     = { color = Color3.fromRGB(80,  210, 110), text = Color3.fromRGB(10,  30,  10),  icon = "✦",  effect = nil       },
    homie   = { color = Color3.fromRGB(170, 170, 190), text = Color3.fromRGB(20,  20,  30),  icon = "~",  effect = nil       },
    user    = { color = Color3.fromRGB(45,  45,  55),  text = Color3.fromRGB(180, 180, 195), icon = "",   effect = nil       },
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

if fsOk and not isfolder(SAVE_DIR) then pcall(makefolder, SAVE_DIR) end

local function loadSaved()
    if not fsOk then return _G._ref_tags_data or {} end
    local ok, raw = pcall(readfile, SAVE_FILE)
    if not ok or not raw or raw == "" then return {} end
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
    if not fsOk then _G._ref_tags_data = t; return end
    pcall(writefile, SAVE_FILE, json)
end

local savedTags = loadSaved()

-- ──────────────────────────────────────────────────────────────
-- ESTADO
-- ──────────────────────────────────────────────────────────────
local billboards   = {}
local effectConns  = {}
local effectObjs   = {}
local billboardsOn = true
local hasDrawing   = typeof(Drawing) ~= "nil"

local function getTag(p)   return FIXED_TAGS[p.UserId] or savedTags[p.UserId] end
local function getRole(n)  return ROLES[n] or ROLES["user"] end

-- ──────────────────────────────────────────────────────────────
-- DRAWING HELPERS
-- ──────────────────────────────────────────────────────────────
local function toScreen(pos)
    local sp, vis = workspace.CurrentCamera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), vis, sp.Z
end

local function newCircle(color, radius, transparency, sides)
    local d = Drawing.new("Circle")
    d.Visible = false; d.Filled = true
    d.NumSides = sides or 64
    d.Color = color; d.Radius = radius
    d.Transparency = transparency or 0
    return d
end

local function newLine(color, thickness, transparency)
    local d = Drawing.new("Line")
    d.Visible = false; d.Color = color
    d.Thickness = thickness or 1
    d.Transparency = transparency or 0
    return d
end

local function destroyDrawing(d)
    if not d then return end
    pcall(function() d:Remove() end)
    pcall(function() d:Destroy() end)
end

local function stopEffect(p)
    if effectConns[p] then effectConns[p]:Disconnect(); effectConns[p] = nil end
    local o = effectObjs[p]; if not o then return end
    for _, d in ipairs(o) do destroyDrawing(d) end
    effectObjs[p] = nil
end

-- ──────────────────────────────────────────────────────────────
-- EFEITO: OWNER
-- chamas vermelhas/laranja subindo + aura pulsante dupla
-- ──────────────────────────────────────────────────────────────
local function startOwnerEffect(p)
    if not hasDrawing then return end

    local aura1 = newCircle(Color3.fromRGB(160, 10, 10),  46, 0.80)
    local aura2 = newCircle(Color3.fromRGB(255, 60, 20),  30, 0.68)

    local PCOUNT = 16
    local particles = {}
    local FIRE_COLORS = {
        Color3.fromRGB(255, 25,  25),
        Color3.fromRGB(255, 100, 15),
        Color3.fromRGB(255, 200, 30),
        Color3.fromRGB(200, 15,  15),
    }
    for i = 1, PCOUNT do
        local d = newCircle(FIRE_COLORS[math.random(#FIRE_COLORS)], math.random(2, 7), 0)
        table.insert(particles, {
            d       = d,
            ox      = math.random(-26, 26),
            phase   = math.random() * math.pi * 2,
            speed   = math.random(38, 88),
            life    = math.random(),
            maxLife = 0.5 + math.random() * 0.65,
        })
    end

    local all = { aura1, aura2 }
    for _, pt in ipairs(particles) do table.insert(all, pt.d) end
    effectObjs[p] = all

    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        local c    = p.Character
        local head = c and c:FindFirstChild("Head")
        if not head or not billboardsOn then
            aura1.Visible = false; aura2.Visible = false
            for _, pt in ipairs(particles) do pt.d.Visible = false end
            return
        end
        local sp, vis = toScreen(head.Position + Vector3.new(0, 1.7, 0))
        if not vis then
            aura1.Visible = false; aura2.Visible = false
            for _, pt in ipairs(particles) do pt.d.Visible = false end
            return
        end

        local pulse = 1 + 0.13 * math.sin(t * 4.5)
        aura1.Radius = 48 * pulse; aura1.Position = sp; aura1.Visible = true
        aura2.Radius = 30 * pulse; aura2.Position = sp; aura2.Visible = true

        for _, pt in ipairs(particles) do
            pt.life = pt.life + dt
            if pt.life >= pt.maxLife then
                pt.life    = 0
                pt.maxLife = 0.45 + math.random() * 0.65
                pt.ox      = math.random(-26, 26)
                pt.phase   = math.random() * math.pi * 2
                pt.speed   = math.random(35, 85)
                pt.d.Radius = math.random(2, 7)
                pt.d.Color  = FIRE_COLORS[math.random(#FIRE_COLORS)]
            end
            local prog  = pt.life / pt.maxLife
            local rise  = pt.speed * prog
            local sway  = math.sin(pt.phase + t * 3.2) * 11 * prog
            pt.d.Position     = sp + Vector2.new(pt.ox + sway, -rise - 16)
            pt.d.Transparency = 0.15 + prog * 0.80
            pt.d.Visible      = true
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
-- EFEITO: DEV
-- aura azul elétrica + arcos + partículas orbitando
-- ──────────────────────────────────────────────────────────────
local function startDevEffect(p)
    if not hasDrawing then return end

    local aura1 = newCircle(Color3.fromRGB(15,  70,  220), 46, 0.78)
    local aura2 = newCircle(Color3.fromRGB(100, 200, 255), 28, 0.68)

    local ARC_COUNT = 10
    local arcs = {}
    for i = 1, ARC_COUNT do
        local ln = newLine(Color3.fromRGB(80, 190, 255), 1.5, 0)
        table.insert(arcs, { d = ln, phase = (i / ARC_COUNT) * math.pi * 2 })
    end

    local ORB_COUNT = 10
    local orbs = {}
    for i = 1, ORB_COUNT do
        local col = i % 2 == 0
            and Color3.fromRGB(120, 220, 255)
            or  Color3.fromRGB(200, 240, 255)
        local d = newCircle(col, math.random(2, 4), 0.35)
        table.insert(orbs, {
            d     = d,
            angle = (i / ORB_COUNT) * math.pi * 2,
            r     = 30 + math.random(-6, 6),
            phase = math.random() * math.pi * 2,
            spd   = (1 + math.random()) * (math.random() > .5 and 1 or -1),
        })
    end

    local all = { aura1, aura2 }
    for _, a in ipairs(arcs) do table.insert(all, a.d) end
    for _, o in ipairs(orbs) do table.insert(all, o.d) end
    effectObjs[p] = all

    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        local c    = p.Character
        local head = c and c:FindFirstChild("Head")
        if not head or not billboardsOn then
            aura1.Visible = false; aura2.Visible = false
            for _, a in ipairs(arcs) do a.d.Visible = false end
            for _, o in ipairs(orbs) do o.d.Visible = false end
            return
        end
        local sp, vis = toScreen(head.Position + Vector3.new(0, 1.7, 0))
        if not vis then
            aura1.Visible = false; aura2.Visible = false
            for _, a in ipairs(arcs) do a.d.Visible = false end
            for _, o in ipairs(orbs) do o.d.Visible = false end
            return
        end

        local pulse = 1 + 0.09 * math.sin(t * 5)
        aura1.Radius = 48 * pulse; aura1.Position = sp; aura1.Visible = true
        aura2.Radius = 28 * pulse; aura2.Position = sp; aura2.Visible = true

        -- arcos elétricos com jitter
        for _, a in ipairs(arcs) do
            local ang    = a.phase + t * 2.8
            local jitter = (math.random() - 0.5) * 12
            local R      = 38 + math.sin(t * 9 + a.phase) * 9
            a.d.From         = sp
            a.d.To           = Vector2.new(sp.X + math.cos(ang)*R + jitter, sp.Y + math.sin(ang)*R + jitter)
            a.d.Transparency = 0.25 + 0.55 * math.abs(math.sin(t * 7 + a.phase))
            a.d.Visible      = true
        end

        -- orbs orbitando
        for _, o in ipairs(orbs) do
            o.angle = o.angle + o.spd * dt
            local wobble = math.sin(t * 2 + o.phase) * 5
            local r = o.r + wobble
            o.d.Position     = Vector2.new(sp.X + math.cos(o.angle)*r, sp.Y + math.sin(o.angle)*r)
            o.d.Transparency = 0.25 + 0.45 * math.abs(math.sin(t + o.phase))
            o.d.Visible      = true
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
-- EFEITO: PECINHA
-- aura rosa pulsante + yin-yang girando em órbita + pétalas
-- ──────────────────────────────────────────────────────────────
local function startPecinhaEffect(p)
    if not hasDrawing then return end

    local aura1 = newCircle(Color3.fromRGB(255, 70,  160), 50, 0.76)
    local aura2 = newCircle(Color3.fromRGB(10,  10,  10),  32, 0.58)

    -- yin-yang: círculo branco base + semicírculo preto + dois bolinhos
    local yy_white = newCircle(Color3.fromRGB(235, 235, 235), 13, 0.0, 64)
    local yy_black = newCircle(Color3.fromRGB(10,  10,  10),  6,  0.0, 64)  -- metade escura
    local yy_wht2  = newCircle(Color3.fromRGB(235, 235, 235), 6,  0.0, 64)  -- metade clara
    local yy_dot_w = newCircle(Color3.fromRGB(235, 235, 235), 2.5, 0.0, 32)
    local yy_dot_b = newCircle(Color3.fromRGB(10,  10,  10),  2.5, 0.0, 32)

    -- outline rosa do yin-yang
    local yy_ring = newCircle(Color3.fromRGB(255, 100, 180), 14, 0.5, 64)
    yy_ring.Filled = false
    -- Drawing Circle sem fill pode não existir em todos executors, mas tentamos

    -- pétalas orbitando
    local PETALS = 9
    local petals = {}
    for i = 1, PETALS do
        local col = i % 2 == 0
            and Color3.fromRGB(255, 120, 200)
            or  Color3.fromRGB(200, 50,  130)
        local d = newCircle(col, math.random(2, 5), 0.25)
        table.insert(petals, {
            d     = d,
            angle = (i / PETALS) * math.pi * 2,
            r     = 30 + math.random(-5, 5),
            phase = math.random() * math.pi * 2,
            spd   = 0.8 + math.random() * 0.5,
        })
    end

    local all = { aura1, aura2, yy_white, yy_black, yy_wht2, yy_dot_w, yy_dot_b, yy_ring }
    for _, pt in ipairs(petals) do table.insert(all, pt.d) end
    effectObjs[p] = all

    local t = 0
    local YY_ORBIT_SPD = 1.1   -- velocidade de órbita do yin-yang
    local YY_ORBIT_R   = 22    -- raio de órbita
    local YY_SELF_SPD  = 2.5   -- velocidade de rotação do próprio yin-yang

    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        local c    = p.Character
        local head = c and c:FindFirstChild("Head")
        if not head or not billboardsOn then
            aura1.Visible  = false; aura2.Visible = false
            yy_white.Visible=false; yy_black.Visible=false; yy_wht2.Visible=false
            yy_dot_w.Visible=false; yy_dot_b.Visible=false; yy_ring.Visible=false
            for _, pt in ipairs(petals) do pt.d.Visible = false end
            return
        end
        local sp, vis = toScreen(head.Position + Vector3.new(0, 1.7, 0))
        if not vis then
            aura1.Visible  = false; aura2.Visible = false
            yy_white.Visible=false; yy_black.Visible=false; yy_wht2.Visible=false
            yy_dot_w.Visible=false; yy_dot_b.Visible=false; yy_ring.Visible=false
            for _, pt in ipairs(petals) do pt.d.Visible = false end
            return
        end

        -- aura: rosa e preta pulsam em fase oposta
        local pulse  = 1 + 0.11 * math.sin(t * 3.8)
        local pulse2 = 1 + 0.11 * math.sin(t * 3.8 + math.pi)
        aura1.Radius = 52 * pulse;  aura1.Position = sp; aura1.Visible = true
        aura2.Radius = 34 * pulse2; aura2.Position = sp; aura2.Visible = true

        -- yin-yang orbitando ao redor da tag
        local orbitAngle = t * YY_ORBIT_SPD
        local yyX = sp.X + math.cos(orbitAngle) * YY_ORBIT_R
        local yyY = sp.Y + math.sin(orbitAngle) * YY_ORBIT_R - 22

        -- auto-rotação: deslocamentos internos giram com o tempo
        local selfAngle = t * YY_SELF_SPD
        local innerOff  = 6.5

        local cx = math.cos(selfAngle) * innerOff
        local cy = math.sin(selfAngle) * innerOff

        yy_white.Position  = Vector2.new(yyX, yyY); yy_white.Visible = true
        yy_ring.Position   = Vector2.new(yyX, yyY); yy_ring.Visible  = true

        yy_black.Position  = Vector2.new(yyX + cx,  yyY + cy);  yy_black.Visible  = true
        yy_wht2.Position   = Vector2.new(yyX - cx,  yyY - cy);  yy_wht2.Visible   = true
        yy_dot_b.Position  = Vector2.new(yyX + cx,  yyY + cy);  yy_dot_b.Visible  = true
        yy_dot_w.Position  = Vector2.new(yyX - cx,  yyY - cy);  yy_dot_w.Visible  = true

        -- pétalas
        for _, pt in ipairs(petals) do
            pt.angle = pt.angle + pt.spd * dt
            local wobble = math.sin(t * 2.2 + pt.phase) * 4
            local r = pt.r + wobble
            pt.d.Position     = Vector2.new(sp.X + math.cos(pt.angle)*r, sp.Y + math.sin(pt.angle)*r)
            pt.d.Transparency = 0.15 + 0.45 * math.abs(math.sin(t * 1.8 + pt.phase))
            pt.d.Visible      = true
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
-- CRIAR / REMOVER BILLBOARD
-- ──────────────────────────────────────────────────────────────
local function removeBillboard(p)
    stopEffect(p)
    if billboards[p] and billboards[p].Parent then billboards[p]:Destroy() end
    billboards[p] = nil
end

local function createBillboard(p)
    removeBillboard(p)
    local c = p.Character; if not c then return end
    local head = c:FindFirstChild("Head"); if not head then return end
    local tagName = getTag(p); if not tagName then return end
    local role    = getRole(tagName)

    -- BillboardGui
    local bb = Instance.new("BillboardGui")
    bb.Name         = "ref_tag_bb"
    bb.Size         = UDim2.new(0, 112, 0, 24)
    bb.StudsOffset  = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop  = true
    bb.ResetOnSpawn = false
    bb.Adornee      = head
    bb.Parent       = head

    local bg = Instance.new("Frame")
    bg.BackgroundColor3 = role.color
    bg.Size             = UDim2.new(1, 0, 1, 0)
    bg.BorderSizePixel  = 0
    bg.Parent           = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 999)
    corner.Parent = bg

    -- stroke colorido por role
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 1.4
    stroke.Color = tagName == "owner"   and Color3.fromRGB(255, 80,  60)
               or tagName == "dev"     and Color3.fromRGB(80,  190, 255)
               or tagName == "pecinha" and Color3.fromRGB(255, 80,  180)
               or Color3.fromRGB(255, 255, 255)
    stroke.Transparency = tagName == "owner" or tagName == "dev" or tagName == "pecinha"
                         and 0.15 or 0.70
    stroke.Parent = bg

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size                   = UDim2.new(1, -6, 1, 0)
    lbl.Position               = UDim2.new(0, 3, 0, 0)
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 11
    lbl.TextColor3             = role.text
    lbl.TextXAlignment         = Enum.TextXAlignment.Center
    lbl.Text                   = (role.icon ~= "" and role.icon .. " " or "") .. tagName
    lbl.Parent                 = bg

    -- glow pulsante no texto (roles especiais)
    if role.effect then
        local ts = Instance.new("UIStroke")
        ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        ts.Thickness    = 1
        ts.Color        = role.text
        ts.Transparency = 0.5
        ts.Parent       = lbl
        TweenService:Create(ts,
            TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Transparency = 0.0 }
        ):Play()
    end

    billboards[p] = bb

    -- inicia efeito Drawing
    if     role.effect == "owner"   then startOwnerEffect(p)
    elseif role.effect == "dev"     then startDevEffect(p)
    elseif role.effect == "pecinha" then startPecinhaEffect(p)
    end
end

local function refreshBillboard(p)
    removeBillboard(p)
    if billboardsOn then createBillboard(p) end
end

-- ──────────────────────────────────────────────────────────────
-- WATCH PLAYERS
-- ──────────────────────────────────────────────────────────────
local function watchPlayer(p)
    if p == player then return end
    p.CharacterAdded:Connect(function()
        task.wait(0.6)
        if billboardsOn then createBillboard(p) end
    end)
    if p.Character then
        task.spawn(function() task.wait(0.6); if billboardsOn then createBillboard(p) end end)
    end
end

for _, p in ipairs(Players:GetPlayers()) do task.spawn(watchPlayer, p) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(p)
    removeBillboard(p); billboards[p] = nil
end)

-- recria billboard se personagem respawnou
RunService.Heartbeat:Connect(function()
    if not billboardsOn then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        local bb = billboards[p]
        if bb and not bb.Parent then
            billboards[p] = nil; stopEffect(p); createBillboard(p)
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
    local card         = secSet:AvatarCard()

    local nickInput = secSet:TextInput("nick", "username ou displayname", function(text, enter)
        if not enter then return end
        local low = text:lower(); local found = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                if p.Name:lower():find(low,1,true) or p.DisplayName:lower():find(low,1,true) then
                    found = p; break
                end
            end
        end
        targetPlayer = found; card.Set(found)
        if not found then lib:Toast(lib._icon,"tags","player não encontrado",T.Bad) end
    end)

    local roleNames = {}
    for name in pairs(ROLES) do table.insert(roleNames, name) end
    table.sort(roleNames)
    local selectedRole = roleNames[1]
    secSet:Dropdown("role", roleNames, selectedRole, function(v) selectedRole = v end)

    secSet:Divider("ações")

    secSet:Button("aplicar tag", function()
        if not targetPlayer then lib:Toast(lib._icon,"tags","selecione um player",T.Bad); return end
        if FIXED_TAGS[targetPlayer.UserId] then lib:Toast(lib._icon,"tags","tag fixa — não pode alterar",T.Bad); return end
        savedTags[targetPlayer.UserId] = selectedRole
        saveTags(savedTags)
        refreshBillboard(targetPlayer)
        lib:Toast(lib._icon,"tags",targetPlayer.DisplayName.." → "..selectedRole,T.Accent)
    end)

    secSet:Button("remover tag", function()
        if not targetPlayer then lib:Toast(lib._icon,"tags","selecione um player",T.Bad); return end
        if FIXED_TAGS[targetPlayer.UserId] then lib:Toast(lib._icon,"tags","tag fixa — não pode remover",T.Bad); return end
        savedTags[targetPlayer.UserId] = nil
        saveTags(savedTags)
        removeBillboard(targetPlayer)
        lib:Toast(lib._icon,"tags","tag removida: "..targetPlayer.DisplayName,T.Sub)
    end)

    -- ── lista ──
    local secList = tab:Section("tags ativas", true)
    local listLbl = secList:Label("nenhuma tag registrada")

    local function refreshList()
        local lines = {}
        for uid, role in pairs(FIXED_TAGS) do
            local name = "["..uid.."]"
            for _, p in ipairs(Players:GetPlayers()) do if p.UserId==uid then name=p.DisplayName end end
            table.insert(lines, "★ "..name.." → "..role.." (fixo)")
        end
        for uid, role in pairs(savedTags) do
            local name = "["..uid.."]"
            for _, p in ipairs(Players:GetPlayers()) do if p.UserId==uid then name=p.DisplayName end end
            table.insert(lines, "• "..name.." → "..role)
        end
        listLbl.Set(#lines > 0 and table.concat(lines, "\n") or "nenhuma tag registrada")
    end
    refreshList()

    secList:Button("atualizar lista", refreshList)
    secList:Button("limpar tags salvas", function()
        savedTags = {}; saveTags(savedTags)
        for _, p in ipairs(Players:GetPlayers()) do
            if not FIXED_TAGS[p.UserId] then removeBillboard(p) end
        end
        refreshList()
        lib:Toast(lib._icon,"tags","tags salvas removidas",T.Sub)
    end)

    -- ── visibilidade ──
    local secVis = tab:Section("visibilidade")
    secVis:Toggle("mostrar tags acima da cabeça", true, function(v)
        billboardsOn = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do if p ~= player then createBillboard(p) end end
        else
            for _, p in ipairs(Players:GetPlayers()) do removeBillboard(p) end
        end
    end)

    lib:Toast(lib._icon, "ref tags", "sistema de tags carregado", T.Accent)
end

-- ──────────────────────────────────────────────────────────────
-- API PÚBLICA
-- ──────────────────────────────────────────────────────────────
function TagSystem.setTag(userId, role)
    if FIXED_TAGS[userId]  then return false, "tag fixa" end
    if not ROLES[role]     then return false, "role inválida" end
    savedTags[userId] = role; saveTags(savedTags)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then refreshBillboard(p) end
    end
    return true
end

function TagSystem.removeTag(userId)
    if FIXED_TAGS[userId] then return false, "tag fixa" end
    savedTags[userId] = nil; saveTags(savedTags)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then removeBillboard(p) end
    end
    return true
end

function TagSystem.addFixed(userId, role) FIXED_TAGS[userId] = role end

function TagSystem.addRole(name, color, textColor, icon, effect)
    ROLES[name] = { color=color, text=textColor or Color3.new(1,1,1), icon=icon or "", effect=effect }
end

function TagSystem.getTag(userId)
    return FIXED_TAGS[userId] or savedTags[userId]
end

return TagSystem
