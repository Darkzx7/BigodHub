-- reftags.lua

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local player = Players.LocalPlayer
local pg     = player:WaitForChild("PlayerGui")

local GIST_RAW      = "https://gist.githubusercontent.com/Darkzx7/dc0facdd3b84b21871cb711da0b3a8b3/raw/tags.json"
local GIST_ID       = "dc0facdd3b84b21871cb711da0b3a8b3"
local GITHUB_TOKEN  = "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"
local SYNC_INTERVAL = 15

local ROLES = {
    owner = { color = Color3.fromRGB(255,232,232), glow = Color3.fromRGB(190,35,35),   effect = "owner",   font = Enum.Font.Arcade, size = 20 },
    dev   = { color = Color3.fromRGB(255,245,245), glow = Color3.fromRGB(255,35,35),   effect = "dev",     font = Enum.Font.Arcade, size = 22 },
    pecinha={ color = Color3.fromRGB(18,18,18),    glow = Color3.fromRGB(95,95,95),    effect = "pecinha", font = Enum.Font.Arcade, size = 21 },
    vip   = { color = Color3.fromRGB(255,255,255), glow = Color3.fromRGB(90,220,120),  effect = "vip",     font = Enum.Font.Arcade, size = 19 },
    homie = { color = Color3.fromRGB(242,242,242), glow = Color3.fromRGB(130,130,150), effect = nil,       font = Enum.Font.Arcade, size = 19 },
    user  = { color = Color3.fromRGB(232,232,232), glow = Color3.fromRGB(110,110,120), effect = nil,       font = Enum.Font.Arcade, size = 18 },
}

local FIXED_TAGS = {
    [2450152162] = "pecinha",
    [5049907844] = "dev",
}

local remoteTags   = {}
local billboards   = {}
local effectConns  = {}
local billboardsOn = true
local scriptUsers  = {}

-- declarado cedo para buildDevPanel poder referenciar
local TagSystem = {}

-- ──────────────────────────────────────────────────────────────
-- gist
-- ──────────────────────────────────────────────────────────────
local function parseGist(raw)
    if not raw or raw == "" or raw == "{}" then return {} end
    local t = {}
    for uid, role in raw:gmatch('"(%d+)"%s*:%s*"([^"]+)"') do
        t[tonumber(uid)] = role
    end
    return t
end

local function serializeTags(t)
    local parts = {}
    for uid, role in pairs(t) do
        table.insert(parts, '"' .. tostring(uid) .. '":"' .. role .. '"')
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function readGist()
    local ok, result = pcall(function()
        return game:HttpGet(GIST_RAW .. "?nocache=" .. tostring(os.clock()), true)
    end)
    if ok and result then
        remoteTags = parseGist(result)
    end
end

local function writeGist(tagsTable)
    local body    = serializeTags(tagsTable)
    local payload = '{"files":{"tags.json":{"content":' .. HttpService:JSONEncode(body) .. '}}}'
    local reqFn   = (syn and syn.request) or (http and http.request) or request
    if not reqFn then return false end
    local ok, res = pcall(reqFn, {
        Url     = "https://api.github.com/gists/" .. GIST_ID,
        Method  = "PATCH",
        Headers = { ["Authorization"] = "token " .. GITHUB_TOKEN, ["Content-Type"] = "application/json" },
        Body    = payload,
    })
    return ok and res and res.StatusCode == 200
end

readGist()

-- ──────────────────────────────────────────────────────────────
-- helpers
-- ──────────────────────────────────────────────────────────────
local function getTag(p)
    if FIXED_TAGS[p.UserId] then return FIXED_TAGS[p.UserId] end
    if remoteTags[p.UserId] then return remoteTags[p.UserId] end
    if scriptUsers[p.UserId] then return "user" end
    return nil
end

local function getRole(name)
    return ROLES[name] or ROLES.user
end

local function isLocalDev()
    return FIXED_TAGS[player.UserId] == "dev" or remoteTags[player.UserId] == "dev"
end

local function disconnectEffect(p)
    if effectConns[p] then effectConns[p]:Disconnect() effectConns[p] = nil end
end

local function removeBillboard(p)
    disconnectEffect(p)
    if billboards[p] and billboards[p].Parent then billboards[p]:Destroy() end
    billboards[p] = nil
end

local function createSimple(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function tw(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
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
    s.Color = col or Color3.fromRGB(255,255,255)
    s.Parent = inst
    return s
end

local function findPlayerByText(text)
    local low = tostring(text or ""):lower()
    if low == "" then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(low,1,true) or p.DisplayName:lower():find(low,1,true) then return p end
    end
    return nil
end

local function makeLabel(parent, text, font, size, color, transparency, zindex, pos, width, height)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size               = UDim2.new(0, width or 280, 0, height or 36)
    lbl.AnchorPoint        = Vector2.new(0.5, 0.5)
    lbl.Position           = pos or UDim2.new(0.5,0,0.5,0)
    lbl.Font               = font
    lbl.TextSize           = size
    lbl.Text               = text
    lbl.TextColor3         = color
    lbl.TextTransparency   = transparency or 0
    lbl.TextXAlignment     = Enum.TextXAlignment.Center
    lbl.TextYAlignment     = Enum.TextYAlignment.Center
    lbl.ZIndex             = zindex or 1
    lbl.Parent             = parent
    return lbl
end

local function addStroke(label, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    s.Color           = color
    s.Thickness       = thickness
    s.Transparency    = transparency or 0
    s.Parent          = label
    return s
end

local function buildTextVisual(bb, tagName, role)
    local root = Instance.new("Frame")
    root.Name = "tag_root"
    root.BackgroundTransparency = 1
    root.Size   = UDim2.new(1,0,1,0)
    root.Parent = bb

    local shadowFar = makeLabel(root, tagName, role.font, role.size, Color3.fromRGB(0,0,0),       0.56, 1, UDim2.new(0.5,0,0.5,4),  320, 42)
    local shadowMid = makeLabel(root, tagName, role.font, role.size, role.glow,                   0.38, 2, UDim2.new(0.5,0,0.5,2),  312, 40)
    local main      = makeLabel(root, tagName, role.font, role.size, role.color,                  0.00, 4, UDim2.new(0.5,0,0.5,0),  304, 38)
    local shine     = makeLabel(root, tagName, role.font, role.size, Color3.fromRGB(255,255,255), 0.90, 5, UDim2.new(0.5,0,0.5,-1), 304, 38)
    local stroke    = addStroke(main, role.glow, 1.25, 0.34)

    return { root=root, shadowFar=shadowFar, shadowMid=shadowMid, main=main, shine=shine, stroke=stroke }
end

-- ──────────────────────────────────────────────────────────────
-- efeitos
-- ──────────────────────────────────────────────────────────────
local function startOwnerEffect(p, refs, role)
    disconnectEffect(p)
    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t += dt
        local pulse = 0.5 + 0.5 * math.sin(t * 2.35)
        refs.shadowMid.TextColor3       = role.glow:Lerp(Color3.fromRGB(255,88,88), pulse*0.45)
        refs.shadowFar.TextTransparency = 0.62 - pulse*0.05
        refs.shadowMid.TextTransparency = 0.34 - pulse*0.08
        refs.stroke.Transparency        = 0.28 - pulse*0.10
        refs.shine.TextTransparency     = 0.90 - pulse*0.05
        refs.main.Position      = UDim2.new(0.5,0,0.5,0)
        refs.shadowMid.Position = UDim2.new(0.5,0,0.5, 2+math.sin(t*2.0)*0.6)
        refs.shadowFar.Position = UDim2.new(0.5,0,0.5, 4+math.sin(t*1.7)*0.5)
    end)
end

local function startDevEffect(p, refs, role)
    disconnectEffect(p)
    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t += dt
        local pulse  = 0.5 + 0.5*math.sin(t*3.8)
        local pulse2 = 0.5 + 0.5*math.sin(t*7.2+0.7)
        local shake  = math.sin(t*18)*0.8
        local shake2 = math.cos(t*14)*1.2
        local flash  = 0.5 + 0.5*math.sin(t*11)
        refs.shadowMid.TextColor3       = role.glow:Lerp(Color3.fromRGB(255,110,110), pulse*0.65)
        refs.shadowFar.TextColor3       = Color3.fromRGB(70,0,0)
        refs.shadowMid.TextTransparency = 0.20 - pulse*0.08
        refs.shadowFar.TextTransparency = 0.48 - pulse2*0.06
        refs.stroke.Transparency        = 0.16 - pulse*0.08
        refs.stroke.Thickness           = 1.3 + pulse*0.9
        refs.shine.TextTransparency     = 0.84 - flash*0.10
        refs.main.Position      = UDim2.new(0.5, shake*0.45,  0.5, 0)
        refs.shine.Position     = UDim2.new(0.5, shake*0.55,  0.5, -1)
        refs.shadowMid.Position = UDim2.new(0.5, shake2,      0.5, 2)
        refs.shadowFar.Position = UDim2.new(0.5, shake2*1.25, 0.5, 4)
        refs.main.Rotation      = math.sin(t*6.5)*0.35
        refs.shine.Rotation     = math.sin(t*6.5)*0.45
        refs.shadowMid.Rotation = math.sin(t*6.5)*0.55
        refs.shadowFar.Rotation = math.sin(t*6.5)*0.75
    end)
end

local function startPecinhaEffect(p, refs, role)
    disconnectEffect(p)
    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t += dt
        local pulse = 0.5 + 0.5*math.sin(t*2.1)
        refs.shadowMid.TextColor3       = role.glow
        refs.shadowFar.TextColor3       = Color3.fromRGB(0,0,0)
        refs.shadowMid.TextTransparency = 0.28 - pulse*0.04
        refs.shadowFar.TextTransparency = 0.50 - pulse*0.03
        refs.stroke.Transparency        = 0.46 - pulse*0.08
        refs.shine.TextTransparency     = 0.97
        refs.main.Position      = UDim2.new(0.5,0,0.5,0)
        refs.shadowMid.Position = UDim2.new(0.5,0,0.5,2)
        refs.shadowFar.Position = UDim2.new(0.5,0,0.5,4)
    end)
end

local function startVipEffect(p, refs, role)
    disconnectEffect(p)
    local t = 0
    effectConns[p] = RunService.RenderStepped:Connect(function(dt)
        t += dt
        local pulse = 0.5 + 0.5*math.sin(t*2.5)
        refs.shadowMid.TextColor3       = role.glow
        refs.shadowMid.TextTransparency = 0.36 - pulse*0.06
        refs.shadowFar.TextTransparency = 0.60 - pulse*0.04
        refs.stroke.Transparency        = 0.40 - pulse*0.08
        refs.shine.TextTransparency     = 0.92 - pulse*0.04
    end)
end

local function applyEffect(p, refs, role)
    if     role.effect == "owner"   then startOwnerEffect(p, refs, role)
    elseif role.effect == "dev"     then startDevEffect(p, refs, role)
    elseif role.effect == "pecinha" then startPecinhaEffect(p, refs, role)
    elseif role.effect == "vip"     then startVipEffect(p, refs, role)
    else   disconnectEffect(p) end
end

-- ──────────────────────────────────────────────────────────────
-- billboard
-- ──────────────────────────────────────────────────────────────
local function createBillboard(p)
    removeBillboard(p)
    local tagName = getTag(p)
    if not tagName then return end
    local c = p.Character
    if not c then return end
    local head = c:FindFirstChild("Head")
    if not head then return end
    local role = getRole(tagName)
    local bb = Instance.new("BillboardGui")
    bb.Name           = "ref_tag_bb"
    bb.Size           = UDim2.new(0,320,0,42)
    bb.StudsOffset    = Vector3.new(0,3.75,0)
    bb.AlwaysOnTop    = true
    bb.LightInfluence = 0
    bb.MaxDistance    = 250
    bb.ResetOnSpawn   = false
    bb.Adornee        = head
    bb.Parent         = head
    local refs = buildTextVisual(bb, tagName, role)
    applyEffect(p, refs, role)
    billboards[p] = bb
end

local function refreshBillboard(p)
    removeBillboard(p)
    if billboardsOn then createBillboard(p) end
end

-- ──────────────────────────────────────────────────────────────
-- sync
-- ──────────────────────────────────────────────────────────────
local function startSync()
    task.spawn(function()
        while true do
            task.wait(SYNC_INTERVAL)
            readGist()
            for _, p in ipairs(Players:GetPlayers()) do
                refreshBillboard(p)
            end
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
-- watch players
-- ──────────────────────────────────────────────────────────────
local function watchPlayer(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.35)
        if billboardsOn then createBillboard(p) end
    end)
    if p.Character then
        task.spawn(function()
            task.wait(0.35)
            if billboardsOn then createBillboard(p) end
        end)
    end
end

scriptUsers[player.UserId] = true

for _, p in ipairs(Players:GetPlayers()) do task.spawn(watchPlayer, p) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(p)
    removeBillboard(p)
    billboards[p] = nil
    scriptUsers[p.UserId] = nil
end)

-- ──────────────────────────────────────────────────────────────
-- painel dev
-- ──────────────────────────────────────────────────────────────
local function buildDevPanel()
    local existing = pg:FindFirstChild("ref_tag_panel")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "ref_tag_panel"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 999
    sg.Parent         = pg

    local BASE_H   = 210
    local ITEM_H   = 26

    local panel = createSimple("Frame", {
        Size             = UDim2.new(0, 260, 0, BASE_H),
        Position         = UDim2.new(1, -278, 0.5, -105),
        BackgroundColor3 = Color3.fromRGB(18, 18, 20),
        BorderSizePixel  = 0,
        Parent           = sg,
    })
    makeCorner(panel, 12)
    makeStroke(panel, 1, 0.3, Color3.fromRGB(255, 40, 40))

    createSimple("TextLabel", {
        Size                   = UDim2.new(1,-40,0,28),
        Position               = UDim2.new(0,12,0,10),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.Arcade,
        Text                   = "ref tags",
        TextSize               = 16,
        TextColor3             = Color3.fromRGB(255,80,80),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = panel,
    })

    local closeBtn = createSimple("TextButton", {
        Size             = UDim2.new(0,24,0,24),
        Position         = UDim2.new(1,-32,0,8),
        BackgroundColor3 = Color3.fromRGB(40,20,20),
        BorderSizePixel  = 0,
        Font             = Enum.Font.GothamBold,
        Text             = "x",
        TextSize         = 12,
        TextColor3       = Color3.fromRGB(200,200,200),
        AutoButtonColor  = false,
        Parent           = panel,
    })
    makeCorner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local nickBox = createSimple("TextBox", {
        Size              = UDim2.new(1,-24,0,30),
        Position          = UDim2.new(0,12,0,48),
        BackgroundColor3  = Color3.fromRGB(28,28,32),
        BorderSizePixel   = 0,
        Font              = Enum.Font.Gotham,
        PlaceholderText   = "nick / displayname",
        Text              = "",
        TextSize          = 13,
        TextColor3        = Color3.fromRGB(220,220,220),
        PlaceholderColor3 = Color3.fromRGB(90,90,100),
        ClearTextOnFocus  = false,
        Parent            = panel,
    })
    makeCorner(nickBox, 7)

    local roleNames = {}
    for name in pairs(ROLES) do table.insert(roleNames, name) end
    table.sort(roleNames)

    local selectedRole = "user"
    local dropdownOpen = false

    local dropDisplay = createSimple("TextButton", {
        Size             = UDim2.new(1,-24,0,30),
        Position         = UDim2.new(0,12,0,86),
        BackgroundColor3 = Color3.fromRGB(28,28,32),
        BorderSizePixel  = 0,
        Font             = Enum.Font.Gotham,
        Text             = "role: " .. selectedRole,
        TextSize         = 13,
        TextColor3       = Color3.fromRGB(220,220,220),
        AutoButtonColor  = false,
        Parent           = panel,
    })
    makeCorner(dropDisplay, 7)

    local dropList = createSimple("Frame", {
        Size             = UDim2.new(1,-24,0, #roleNames * ITEM_H),
        Position         = UDim2.new(0,12,0,118),
        BackgroundColor3 = Color3.fromRGB(22,22,26),
        BorderSizePixel  = 0,
        Visible          = false,
        ZIndex           = 10,
        Parent           = panel,
    })
    makeCorner(dropList, 7)
    makeStroke(dropList, 1, 0.5, Color3.fromRGB(255,40,40))

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent    = dropList

    for i, name in ipairs(roleNames) do
        local btn = createSimple("TextButton", {
            Size             = UDim2.new(1,0,0,ITEM_H),
            BackgroundColor3 = Color3.fromRGB(22,22,26),
            BorderSizePixel  = 0,
            Font             = Enum.Font.Gotham,
            Text             = name,
            TextSize         = 13,
            TextColor3       = Color3.fromRGB(200,200,200),
            AutoButtonColor  = false,
            LayoutOrder      = i,
            ZIndex           = 11,
            Parent           = dropList,
        })
        btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3=Color3.fromRGB(40,20,20)}, 0.1) end)
        btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3=Color3.fromRGB(22,22,26)}, 0.1) end)
        btn.MouseButton1Click:Connect(function()
            selectedRole     = name
            dropDisplay.Text = "role: " .. selectedRole
            dropList.Visible = false
            dropdownOpen     = false
            tw(panel, {Size=UDim2.new(0,260,0,BASE_H)}, 0.15)
        end)
    end

    dropDisplay.MouseButton1Click:Connect(function()
        dropdownOpen     = not dropdownOpen
        dropList.Visible = dropdownOpen
        tw(panel, {Size=UDim2.new(0,260,0, dropdownOpen and (BASE_H + #roleNames*ITEM_H) or BASE_H)}, 0.15)
    end)

    local status = createSimple("TextLabel", {
        Size                   = UDim2.new(1,-24,0,18),
        Position               = UDim2.new(0,12,0,124),
        BackgroundTransparency = 1,
        Font                   = Enum.Font.Gotham,
        Text                   = "",
        TextSize               = 12,
        TextColor3             = Color3.fromRGB(120,120,130),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = panel,
    })

    local function setStatus(msg, good)
        status.Text       = msg
        status.TextColor3 = good and Color3.fromRGB(80,200,100) or Color3.fromRGB(220,70,70)
    end

    local applyBtn = createSimple("TextButton", {
        Size             = UDim2.new(0,112,0,32),
        Position         = UDim2.new(0,12,0,148),
        BackgroundColor3 = Color3.fromRGB(160,30,30),
        BorderSizePixel  = 0,
        Font             = Enum.Font.GothamBold,
        Text             = "aplicar",
        TextSize         = 13,
        TextColor3       = Color3.fromRGB(255,255,255),
        AutoButtonColor  = false,
        Parent           = panel,
    })
    makeCorner(applyBtn, 8)
    applyBtn.MouseEnter:Connect(function() tw(applyBtn, {BackgroundColor3=Color3.fromRGB(190,40,40)}, 0.1) end)
    applyBtn.MouseLeave:Connect(function() tw(applyBtn, {BackgroundColor3=Color3.fromRGB(160,30,30)}, 0.1) end)
    applyBtn.MouseButton1Click:Connect(function()
        local target = findPlayerByText(nickBox.Text)
        if not target then setStatus("player nao encontrado", false) return end
        if FIXED_TAGS[target.UserId] then setStatus("tag fixa, nao pode alterar", false) return end
        local ok, err = TagSystem.setTag(target.UserId, selectedRole)
        if ok then setStatus(target.DisplayName .. " -> " .. selectedRole, true)
        else setStatus(err or "erro", false) end
    end)

    local removeBtn = createSimple("TextButton", {
        Size             = UDim2.new(0,112,0,32),
        Position         = UDim2.new(1,-124,0,148),
        BackgroundColor3 = Color3.fromRGB(35,35,42),
        BorderSizePixel  = 0,
        Font             = Enum.Font.GothamBold,
        Text             = "remover",
        TextSize         = 13,
        TextColor3       = Color3.fromRGB(200,200,200),
        AutoButtonColor  = false,
        Parent           = panel,
    })
    makeCorner(removeBtn, 8)
    removeBtn.MouseEnter:Connect(function() tw(removeBtn, {BackgroundColor3=Color3.fromRGB(55,55,65)}, 0.1) end)
    removeBtn.MouseLeave:Connect(function() tw(removeBtn, {BackgroundColor3=Color3.fromRGB(35,35,42)}, 0.1) end)
    removeBtn.MouseButton1Click:Connect(function()
        local target = findPlayerByText(nickBox.Text)
        if not target then setStatus("player nao encontrado", false) return end
        if FIXED_TAGS[target.UserId] then setStatus("tag fixa, nao pode remover", false) return end
        local ok, err = TagSystem.removeTag(target.UserId)
        if ok then setStatus("tag removida: " .. target.DisplayName, true)
        else setStatus(err or "erro", false) end
    end)

    -- drag
    local dragging, dragStart, startPos = false, nil, nil
    panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
-- tag system api
-- ──────────────────────────────────────────────────────────────
function TagSystem.setTag(userId, role)
    if FIXED_TAGS[userId] then return false, "tag fixa" end
    if not ROLES[role] then return false, "role invalida" end
    remoteTags[userId] = role
    local ok = writeGist(remoteTags)
    if not ok then return false, "erro ao salvar no gist" end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then refreshBillboard(p) break end
    end
    return true
end

function TagSystem.removeTag(userId)
    if FIXED_TAGS[userId] then return false, "tag fixa" end
    remoteTags[userId] = nil
    local ok = writeGist(remoteTags)
    if not ok then return false, "erro ao salvar no gist" end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then refreshBillboard(p) break end
    end
    return true
end

function TagSystem.getTag(userId)
    return FIXED_TAGS[userId] or remoteTags[userId] or "user"
end

function TagSystem.addFixed(userId, role)
    FIXED_TAGS[userId] = role
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then refreshBillboard(p) break end
    end
end

function TagSystem.addRole(name, color, textColor, effect)
    ROLES[name] = {
        color  = textColor or Color3.new(1,1,1),
        glow   = color or Color3.new(1,1,1),
        effect = effect,
        font   = Enum.Font.Arcade,
        size   = 19,
    }
end

-- ──────────────────────────────────────────────────────────────
-- integração reflib
-- ──────────────────────────────────────────────────────────────
function TagSystem.init(lib)
    local T   = lib.Theme
    local tab = lib:Tab("tags")

    local secVis = tab:Section("visibilidade")
    secVis:Toggle("mostrar tags", true, function(v)
        billboardsOn = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do createBillboard(p) end
        else
            for _, p in ipairs(Players:GetPlayers()) do removeBillboard(p) end
        end
    end)

    local secDev = tab:Section("gerenciar")
    secDev:Button("abrir painel de tags", function()
        if not isLocalDev() then readGist() end
        if isLocalDev() then
            buildDevPanel()
        else
            lib:Toast(lib._icon, "tags", "sem permissao", T.Bad)
        end
    end)

    lib:Toast(lib._icon, "ref tags", "sistema de tags carregado", T.Accent)
    startSync()
end

return TagSystem
