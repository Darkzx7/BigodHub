-- ================================================================
-- MM2 WORKSPACE SCANNER
-- Cola no executor durante uma partida do MM2
-- Aperta o botão SCAN e copia o resultado pra mandar pro Claude
-- ================================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local player       = Players.LocalPlayer

-- ── UI simples sem lib externa ────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "MM2Scanner"; sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true; sg.DisplayOrder = 999
sg.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 110)
frame.Position = UDim2.new(0.5, -160, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
frame.BorderSizePixel = 0
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(220, 220, 255)
title.Text = "MM2 Scanner — aperte SCAN durante a partida"
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -10, 0, 20)
status.Position = UDim2.new(0, 5, 0, 30)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(160, 160, 180)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "aguardando..."
status.Parent = frame

local function makeBtn(text, color, posX, width)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, width, 0, 34)
    b.Position = UDim2.new(0, posX, 0, 68)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local btnScan  = makeBtn("SCAN",  Color3.fromRGB(60, 120, 220), 8,   148)
local btnCopy  = makeBtn("COPY",  Color3.fromRGB(40, 160, 80),  162, 148)
btnCopy.Text = "COPY (sem resultado)"

local lastResult = ""

-- ── Funções auxiliares ────────────────────────────────────────────
local function safeName(obj)
    return pcall(function() return obj.Name end) and obj.Name or "?"
end

local function safeClass(obj)
    return pcall(function() return obj.ClassName end) and obj.ClassName or "?"
end

local function isPlayerChar(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == obj then return true end
    end
    return false
end

-- ── SCAN ──────────────────────────────────────────────────────────
local function doScan()
    status.Text = "escaneando..."
    task.wait(0.05)

    local lines = {}
    local function add(s) table.insert(lines, s) end

    -- ── 1. Filhos diretos do workspace (onde GunDrop aparece) ─────
    add("=== WORKSPACE CHILDREN ===")
    for _, obj in ipairs(workspace:GetChildren()) do
        pcall(function()
            if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Tool") then
                if not isPlayerChar(obj)
                and obj.Name ~= "Camera"
                and obj.Name ~= "Terrain"
                and not Players:GetPlayerFromCharacter(obj) then
                    local childCount = #obj:GetChildren()
                    add(safeClass(obj).."|"..safeName(obj).."|children:"..childCount)
                end
            end
        end)
    end

    -- ── 2. Tools em todo workspace ────────────────────────────────
    add("=== ALL TOOLS IN WORKSPACE ===")
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("Tool") then
                local parentName = obj.Parent and safeName(obj.Parent) or "nil"
                local parentClass = obj.Parent and safeClass(obj.Parent) or "nil"
                add("Tool|"..safeName(obj).."|pai_nome:"..parentName.."|pai_class:"..parentClass)
            end
        end)
    end

    -- ── 3. RemoteEvents e RemoteFunctions (para descobrir remotes) ─
    add("=== REMOTES (ReplicatedStorage) ===")
    local rs = game:GetService("ReplicatedStorage")
    for _, obj in ipairs(rs:GetDescendants()) do
        pcall(function()
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
                local path = safeName(obj)
                local cur = obj.Parent
                for _=1,6 do
                    if not cur or cur == rs then break end
                    path = safeName(cur).."."..path
                    cur = cur.Parent
                end
                add(safeClass(obj).."|"..path)
            end
        end)
    end

    -- ── 4. Roles dos players (PlayerDataChanged cache) ────────────
    add("=== PLAYER DATA ===")
    for _, p in ipairs(Players:GetPlayers()) do
        pcall(function()
            local role = p:GetAttribute("Role") or "?"
            local alive = p:GetAttribute("Alive")
            local chr = p.Character
            local hasKnife, hasGun = false, false
            if chr then
                hasKnife = chr:FindFirstChild("Knife") ~= nil
                hasGun   = chr:FindFirstChild("Gun") ~= nil
            end
            local bp = p:FindFirstChild("Backpack")
            if bp then
                hasKnife = hasKnife or bp:FindFirstChild("Knife") ~= nil
                hasGun   = hasGun   or bp:FindFirstChild("Gun") ~= nil
            end
            add("Player|"..p.Name.."|role_attr:"..(role or "nil").."|alive:"..(tostring(alive)).."|knife:"..tostring(hasKnife).."|gun:"..tostring(hasGun))
        end)
    end

    -- ── 5. Keywords no workspace ──────────────────────────────────
    add("=== KEYWORD SEARCH (gun/knife/drop/coin) ===")
    local kws = {"gun","knife","drop","coin","sheriff","murder","throw","shoot","weapon"}
    local seen = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if seen[obj] then return end
            local n = safeName(obj):lower()
            for _, kw in ipairs(kws) do
                if n:find(kw, 1, true) then
                    seen[obj] = true
                    local parentName = obj.Parent and safeName(obj.Parent) or "nil"
                    add(safeClass(obj).."|"..safeName(obj).."|pai:"..parentName)
                    break
                end
            end
        end)
    end

    -- ── 6. RemoteEvents/Functions na gun se equipada ──────────────
    add("=== GUN TOOL REMOTES (se equipada) ===")
    local chr = player.Character
    if chr then
        for _, obj in ipairs(chr:GetDescendants()) do
            pcall(function()
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("Script") or obj:IsA("LocalScript") then
                    add(safeClass(obj).."|"..safeName(obj).."|pai:"..safeName(obj.Parent))
                end
            end)
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            pcall(function()
                add("Backpack_Tool|"..safeName(tool))
                for _, obj in ipairs(tool:GetDescendants()) do
                    pcall(function()
                        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("LocalScript") then
                            add("  "..safeClass(obj).."|"..safeName(obj))
                        end
                    end)
                end
            end)
        end
    end

    if #lines == 0 then
        add("Nada encontrado — rode durante uma partida com items no chao")
    end

    lastResult = table.concat(lines, "\n")
    status.Text = "✓ "..#lines.." linhas — clique COPY"
    btnCopy.Text = "COPY ("..#lines.." linhas)"
    print("[MM2 Scanner]\n"..lastResult)
end

-- ── Botões ────────────────────────────────────────────────────────
btnScan.Activated:Connect(function()
    btnScan.Text = "..."
    btnScan.BackgroundColor3 = Color3.fromRGB(40,40,60)
    local ok, err = pcall(doScan)
    if not ok then
        status.Text = "erro: "..tostring(err)
        print("[MM2 Scanner ERROR] "..tostring(err))
    end
    btnScan.Text = "SCAN"
    btnScan.BackgroundColor3 = Color3.fromRGB(60,120,220)
end)

btnCopy.Activated:Connect(function()
    if lastResult == "" then
        status.Text = "faça o SCAN primeiro!"
        return
    end
    local copied = false
    if type(setclipboard)=="function" then pcall(function() setclipboard(lastResult); copied=true end) end
    if not copied and type(toclipboard)=="function" then pcall(function() toclipboard(lastResult); copied=true end) end
    if not copied and type(Clipboard)=="table" then pcall(function() Clipboard:Set(lastResult); copied=true end) end
    if copied then
        btnCopy.Text = "COPIADO!"
        btnCopy.BackgroundColor3 = Color3.fromRGB(180,140,20)
        task.wait(2)
        btnCopy.Text = "COPY"
        btnCopy.BackgroundColor3 = Color3.fromRGB(40,160,80)
        status.Text = "copiado — cole no chat do Claude"
    else
        status.Text = "clipboard nao suportado — veja o console"
    end
end)

-- Fecha com X
local btnX = Instance.new("TextButton")
btnX.Size = UDim2.new(0,20,0,20)
btnX.Position = UDim2.new(1,-22,0,4)
btnX.BackgroundColor3 = Color3.fromRGB(180,50,50)
btnX.BorderSizePixel=0; btnX.Text="✕"
btnX.Font=Enum.Font.GothamBold; btnX.TextSize=11
btnX.TextColor3=Color3.new(1,1,1); btnX.Parent=frame
Instance.new("UICorner",btnX).CornerRadius=UDim.new(0,4)
btnX.Activated:Connect(function() sg:Destroy() end)
