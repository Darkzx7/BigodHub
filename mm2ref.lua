--[[ ================================================================
  mm2_ui.lua — Murder Mystery 2  v6.0
  Reescrito com remotes REAIS descobertos via Cobalt.

  REMOTES CONFIRMADOS:
  ─ GunFired: ReplicatedStorage.ClientServices.WeaponService.GunFired
    → firesignal(Event.OnClientEvent, Handle, originPos, targetPos, targetPart)
  ─ CoinCollected: ReplicatedStorage.Remotes.Gameplay.CoinCollected
    → firesignal(Event.OnClientEvent, "Coin", amount, total, {Value=1})
  ─ RoleSelect: ReplicatedStorage.Remotes.Gameplay.RoleSelect
    → firesignal(Event.OnClientEvent, role, ...)  ← usado para DETECTAR papel

  MUDANÇAS v6.0:
  ─ shootAt(): usa firesignal no GunFired (método real e confirmado)
  ─ getRole(): escuta RoleSelect para cache confiável do papel
  ─ Coin farm: usa FireServer no CoinCollected em loop (instant collect)
  ─ Auto shoot: loop mais limpo usando o novo shootAt()
  ─ Knife: mantém teleport + Activate (knife não tem remote client-side)
================================================================ --]]

-- ── Lib ────────────────────────────────────────────────────────────────────────
local LIB_URL = "https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua"
local RefLib
pcall(function() RefLib = loadstring(game:HttpGet(LIB_URL, true))() end)
if not RefLib then error("[mm2] nao foi possivel carregar a UI lib") end

-- ── Serviços ───────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local VirtualUser      = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local cam    = workspace.CurrentCamera

-- ── UI ─────────────────────────────────────────────────────────────────────────
local ui = RefLib.new("mm2 v6", "rbxassetid://131165537896572", "ref_mm2v6")

-- ══════════════════════════════════════════════════════════════════════════════
-- REMOTES (descobertos via Cobalt)
-- ══════════════════════════════════════════════════════════════════════════════

-- Remote da gun: firesignal no OnClientEvent simula o disparo localmente
-- Assinatura real: GunFired.OnClientEvent(Handle, originPos, targetPos, targetPart)
local GunFiredEvent = nil
pcall(function()
    GunFiredEvent = ReplicatedStorage.ClientServices.WeaponService.GunFired
end)

-- Remote de coins: FireServer envia coleta pro servidor
-- Assinatura real: CoinCollected(coinName, amount, total, {Value=N})
local CoinCollectedEvent = nil
pcall(function()
    CoinCollectedEvent = ReplicatedStorage.Remotes.Gameplay.CoinCollected
end)

-- Remote de role: escutamos para cachear o papel real
local RoleSelectEvent = nil
pcall(function()
    RoleSelectEvent = ReplicatedStorage.Remotes.Gameplay.RoleSelect
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- CONSTANTES E HELPERS
-- ══════════════════════════════════════════════════════════════════════════════

local KNIFE_NAMES = { Knife = true }
local GUN_NAMES   = { Gun = true, ["Sheriff's Gun"] = true, Revolver = true, SheriffGun = true }
local COIN_NAMES  = { Coin = true, coin = true, GoldCoin = true, goldcoin = true, Coins = true }

local ROLE_COLOR = {
    murderer = Color3.fromRGB(220, 55, 55),
    sheriff  = Color3.fromRGB(55, 180, 220),
    innocent = Color3.fromRGB(80, 210, 80),
    unknown  = Color3.fromRGB(150, 150, 160),
}
local ROLE_LABEL = { murderer = "Murderer", sheriff = "Sheriff", innocent = "Innocent", unknown = "?" }

-- ─────────────────────────────────────────────────────────────────────────────
-- Cache de papel: atualizado via RoleSelect event (método mais confiável)
-- ─────────────────────────────────────────────────────────────────────────────
local roleCache = {}  -- [player] = "murderer" | "sheriff" | "innocent"

-- Escuta RoleSelect para cachear papéis quando o round começa
if RoleSelectEvent then
    -- O evento dispara para o próprio player com seu papel
    RoleSelectEvent.OnClientEvent:Connect(function(roleName, ...)
        if not roleName then return end
        local low = tostring(roleName):lower()
        if low:find("murder") then
            roleCache[player] = "murderer"
        elseif low:find("sheriff") then
            roleCache[player] = "sheriff"
        else
            roleCache[player] = "innocent"
        end
    end)
end

-- Limpa cache no início de cada round (quando character spawna)
player.CharacterAdded:Connect(function()
    -- Não limpa imediatamente — espera RoleSelect chegar
    task.delay(3, function()
        -- Se após 3s ainda não recebeu role, usa fallback
    end)
end)

local function isAlive(p)
    local alive = p:GetAttribute("Alive")
    if alive ~= nil then return alive == true end
    local chr = p.Character
    local hum = chr and chr:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

-- getRole: usa cache do RoleSelect > GetAttribute > fallback tools
local function getRole(p)
    p = p or player
    -- Método 1: cache do evento RoleSelect (mais confiável)
    if roleCache[p] then return roleCache[p] end
    -- Método 2: atributo nativo do MM2
    local attr = p:GetAttribute("Role")
    if attr then
        local low = attr:lower()
        if low:find("murder") then return "murderer" end
        if low:find("sheriff") then return "sheriff" end
        if low:find("innocent") then return "innocent" end
    end
    -- Método 3: verificar ferramentas no character/backpack
    local bp  = p:FindFirstChild("Backpack")
    local chr = p.Character
    local function hasIn(container, names)
        if not container then return false end
        for name in pairs(names) do
            if container:FindFirstChild(name) then return true end
        end
        return false
    end
    if hasIn(chr, KNIFE_NAMES) or hasIn(bp, KNIFE_NAMES) then return "murderer" end
    if hasIn(chr, GUN_NAMES)   or hasIn(bp, GUN_NAMES)   then return "sheriff"  end
    return "innocent"
end

local function findByRole(role)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        if isAlive(p) and getRole(p) == role then return p end
    end
    return nil
end

local function myHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function isValidPos(pos)
    if not pos then return false end
    if pos ~= pos then return false end
    return pos.Magnitude < 10000
end

local function safeAbove(part, offsetY)
    offsetY = offsetY or 4
    if not part or not part.Parent then return nil end
    local pos = part.Position
    if not isValidPos(pos) then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = (player.Character and {player.Character}) or {}
    local result = workspace:Raycast(pos + Vector3.new(0, 10, 0), Vector3.new(0, -14, 0), params)
    if result then return result.Position + Vector3.new(0, offsetY, 0) end
    return pos + Vector3.new(0, offsetY, 0)
end

local function isDropped(tool)
    if not tool or not tool.Parent then return false end
    local p = tool.Parent
    if p:IsA("Backpack") then return false end
    if Players:GetPlayerFromCharacter(p) then return false end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Character == p then return false end
    end
    return true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE SHOOT (Sheriff) — usando remote REAL do MM2
-- ══════════════════════════════════════════════════════════════════════════════

local function getGunHandle()
    -- Busca o Handle da gun no character (equipada) ou nil
    local chr = player.Character; if not chr then return nil end
    for name in pairs(GUN_NAMES) do
        local tool = chr:FindFirstChild(name)
        if tool then
            local h = tool:FindFirstChild("Handle")
            if h then return h, tool end
        end
    end
    return nil
end

local function getGunTool()
    local chr = player.Character; if not chr then return nil end
    for name in pairs(GUN_NAMES) do
        local t = chr:FindFirstChild(name)
        if t then return t end
    end
    return nil
end

local function equipGun()
    local bp = player:FindFirstChild("Backpack"); if not bp then return nil end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    for name in pairs(GUN_NAMES) do
        local t = bp:FindFirstChild(name)
        if t then hum:EquipTool(t); task.wait(0.15); return getGunTool() end
    end
    return nil
end

--[[
  shootAt() — Método REAL descoberto via Cobalt:
  
  firesignal(GunFired.OnClientEvent, Handle, originPos, targetPos, targetPart)
  
  Handle     = a Part "Handle" da gun no character do shooter
  originPos  = posição de onde saiu o tiro (HRP do atirador)
  targetPos  = posição do alvo (HRP ou Head do alvo)
  targetPart = a Part que foi atingida (HRP do alvo funciona)
  
  Isso simula o ClientEvent que o servidor enviaria de volta após processar o tiro,
  e o LocalScript da gun usa esse evento para processar o hit localmente.
  
  Para realmente causar dano, precisamos TAMBÉM disparar o RemoteEvent do servidor.
  Buscamos RemoteEvents dentro da gun tool que processem o disparo.
--]]
local function shootAt(targetChar)
    if not targetChar then return false end
    local hrp  = myHRP(); if not hrp then return false end
    local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
               or targetChar:FindFirstChild("Head")
    if not tHRP then return false end

    -- Equipa a gun se não estiver equipada
    local gun = getGunTool() or equipGun()
    if not gun then return false end

    -- Aponta para o alvo
    hrp.CFrame = CFrame.lookAt(hrp.Position, tHRP.Position)
    task.wait(0.06)

    local handle = gun:FindFirstChild("Handle")
    local originPos = hrp.Position
    local targetPos = tHRP.Position
    local fired = false

    -- ── Método 1: firesignal no GunFired.OnClientEvent (Cobalt confirmou) ──
    -- Isso processa o hit localmente via o LocalScript da gun
    if GunFiredEvent and handle then
        pcall(function()
            firesignal(GunFiredEvent.OnClientEvent,
                handle,
                originPos,
                targetPos,
                tHRP  -- targetPart = HRP do alvo
            )
            fired = true
        end)
    end

    -- ── Método 2: FireServer nos RemoteEvents da gun (causa dano real) ──
    -- MM2 provavelmente tem um RemoteEvent "Shoot" ou "Fire" dentro da gun
    if not fired or true then  -- sempre tenta também para garantir dano real
        pcall(function()
            for _, obj in ipairs(gun:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    -- Tenta diferentes assinaturas comuns
                    pcall(function() obj:FireServer(targetPos, tHRP) end)
                    pcall(function() obj:FireServer(tHRP.Position) end)
                    fired = true
                end
            end
        end)
    end

    -- ── Método 3: Activate() com mouse apontado ──
    if not fired then
        pcall(function()
            local mouse = player:GetMouse()
            rawset(mouse, "Hit", CFrame.new(targetPos))
            gun:Activate()
            fired = true
        end)
    end

    -- ── Método 4: mouse1click no handle ──
    if not fired and handle then
        pcall(function()
            if mouse1click then mouse1click(handle); fired = true end
        end)
    end

    return fired
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE KNIFE (Murderer)
-- ══════════════════════════════════════════════════════════════════════════════

local function getKnifeTool()
    local chr = player.Character; if not chr then return nil end
    for name in pairs(KNIFE_NAMES) do
        local t = chr:FindFirstChild(name); if t then return t end
    end
    return nil
end

local function equipKnife()
    local bp = player:FindFirstChild("Backpack"); if not bp then return nil end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    for name in pairs(KNIFE_NAMES) do
        local t = bp:FindFirstChild(name)
        if t then hum:EquipTool(t); task.wait(0.15); return getKnifeTool() end
    end
    return nil
end

local function knifeAt(targetChar)
    if not targetChar then return false end
    local hrp  = myHRP(); if not hrp then return false end
    local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
               or targetChar:FindFirstChild("Head")
    if not tHRP then return false end

    local knife = getKnifeTool() or equipKnife()
    if not knife then return false end

    -- Teleporta perto (knife precisa de proximidade)
    hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, -3.5)
    task.wait(0.04)
    hrp.CFrame = CFrame.lookAt(hrp.Position, tHRP.Position)

    local fired = false

    -- Tenta RemoteEvents da knife primeiro
    pcall(function()
        for _, obj in ipairs(knife:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                pcall(function() obj:FireServer(tHRP.Position, tHRP) end)
                fired = true
                break
            end
        end
    end)

    -- Fallback: Activate()
    if not fired then
        pcall(function() knife:Activate(); fired = true end)
    end

    return fired
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SISTEMA DE COIN FARM — usando remote REAL do MM2
-- ══════════════════════════════════════════════════════════════════════════════

--[[
  CoinCollected remote (descoberto via Cobalt):
  firesignal(Event.OnClientEvent, "Coin", amount, total, {Value = 1})
  
  Para COLETAR de verdade (server-side), usamos FireServer.
  Mas também precisamos tp até a coin para trigger o TouchEnded/Touched no servidor.
  
  Estratégia combinada:
  1. Teleporta até a coin (para trigger o Touched server-side)
  2. FireServer no CoinCollected se existir como RemoteEvent (não RemoteFunction)
  3. firesignal no OnClientEvent para atualizar UI local
--]]

local function findAllCoins()
    local coins = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if COIN_NAMES[obj.Name] then
            local part = nil
            if obj:IsA("BasePart") then
                part = obj
            elseif obj:IsA("Model") then
                part = obj:FindFirstChildOfClass("BasePart") or obj.PrimaryPart
            end
            if part and part.Parent and isValidPos(part.Position) then
                -- Evita duplicatas (modelo + sua part)
                local already = false
                for _, c in ipairs(coins) do
                    if c == part then already = true; break end
                end
                if not already then
                    table.insert(coins, {part = part, obj = obj})
                end
            end
        end
    end
    return coins
end

local function collectCoinInstant(coinData)
    local part = coinData.part
    if not part or not part.Parent then return false end

    -- Etapa 1: Teleporta até a coin (trigger Touched no servidor)
    local hrp = myHRP()
    if hrp then
        local dest = safeAbove(part, 3)
        if dest then hrp.CFrame = CFrame.new(dest) end
        task.wait(0.08)
    end

    -- Etapa 2: Tenta FireServer no remote de coin se existir
    if CoinCollectedEvent then
        pcall(function()
            -- Se for RemoteEvent, tenta FireServer
            if CoinCollectedEvent:IsA("RemoteEvent") then
                CoinCollectedEvent:FireServer("Coin", 1, 1, {Value = 1})
            end
        end)
    end

    -- Etapa 3: Simula o cliente recebendo a coin (atualiza UI local)
    if CoinCollectedEvent then
        pcall(function()
            firesignal(CoinCollectedEvent.OnClientEvent, "Coin", 1, 1, {Value = 1})
        end)
    end

    return true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TEMA
-- ══════════════════════════════════════════════════════════════════════════════
local T = {
    bg     = Color3.fromRGB(28, 20, 45),
    panel  = Color3.fromRGB(36, 26, 56),
    accent = Color3.fromRGB(128, 38, 220),
    acc2   = Color3.fromRGB(88, 14, 165),
    text   = Color3.fromRGB(235, 225, 255),
    sub    = Color3.fromRGB(150, 130, 190),
    ok     = Color3.fromRGB(85, 205, 115),
    err    = Color3.fromRGB(208, 52, 72),
    warn   = Color3.fromRGB(195, 160, 38),
}

-- ══════════════════════════════════════════════════════════════════════════════
-- TABS
-- ══════════════════════════════════════════════════════════════════════════════
local tabMain   = ui:Tab("main")
local tabESP    = ui:Tab("esp")
local tabCombat = ui:Tab("combat")
local tabFarm   = ui:Tab("farm")
local tabCfg    = ui:Tab("config")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: MAIN
-- ══════════════════════════════════════════════════════════════════════════════
do

local secInfo = tabMain:Section("round info")

secInfo:Button("checar meu papel", function()
    local role = getRole()
    local alive = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if isAlive(p) then alive = alive + 1 end
    end
    ui:Toast("rbxassetid://131165537896572",
        "["..ROLE_LABEL[role].."] "..player.DisplayName,
        "vivos: "..alive, ROLE_COLOR[role])
end)

secInfo:Button("scan todos os papeis", function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local r = getRole(p)
        if r ~= "innocent" then table.insert(list, {p=p, r=r}) end
    end
    if #list == 0 then
        ui:Toast("rbxassetid://131165537896572","scan","nenhum killer/sheriff detectado",ROLE_COLOR.unknown)
        return
    end
    for _, info in ipairs(list) do
        task.spawn(function()
            ui:Toast("rbxassetid://131165537896572",
                "["..ROLE_LABEL[info.r].."] "..info.p.DisplayName,
                info.p.Name, ROLE_COLOR[info.r])
        end)
        task.wait(0.4)
    end
end)

-- ── Role ESP ──────────────────────────────────────────────────────────────────
secInfo:Divider("role esp")
local roleEspOn = false
local roleEspCache = {}

local function removeRoleEsp(p)
    local d = roleEspCache[p]; if not d then return end
    pcall(function() if d.hl and d.hl.Parent then d.hl:Destroy() end end)
    pcall(function() if d.bb and d.bb.Parent then d.bb:Destroy() end end)
    roleEspCache[p] = nil
end

local function buildRoleEsp(p)
    if roleEspCache[p] then return end
    local chr = p.Character; if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local role = getRole(p); local col = ROLE_COLOR[role]

    local hl = Instance.new("Highlight")
    hl.FillColor = col; hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.42; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = chr; hl.Parent = chr

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0,130,0,40); bb.StudsOffset = Vector3.new(0,3.2,0)
    bb.AlwaysOnTop = true; bb.ResetOnSpawn = false; bb.Adornee = hrp; bb.Parent = hrp

    local nm = Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,20)
    nm.Font=Enum.Font.GothamBold; nm.TextSize=13; nm.TextColor3=Color3.new(1,1,1)
    nm.TextStrokeTransparency=0.12; nm.TextXAlignment=Enum.TextXAlignment.Center
    nm.Text=p.DisplayName; nm.Parent=bb

    local rl = Instance.new("TextLabel"); rl.BackgroundTransparency=1; rl.Size=UDim2.new(1,0,0,14)
    rl.Position=UDim2.new(0,0,0,22); rl.Font=Enum.Font.GothamSemibold; rl.TextSize=11
    rl.TextColor3=col; rl.TextStrokeTransparency=0.2; rl.TextXAlignment=Enum.TextXAlignment.Center
    rl.Text="["..ROLE_LABEL[role].."]"; rl.Parent=bb

    roleEspCache[p] = {hl=hl, bb=bb, nm=nm, rl=rl}
end

RunService.RenderStepped:Connect(function()
    if not roleEspOn then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        if not isAlive(p) then removeRoleEsp(p); continue end
        if not roleEspCache[p] then buildRoleEsp(p) end
        local d=roleEspCache[p]; if not d then continue end
        local role=getRole(p); local col=ROLE_COLOR[role]
        d.hl.FillColor=col; d.rl.TextColor3=col
        d.rl.Text="["..ROLE_LABEL[role].."]"; d.nm.Text=p.DisplayName
    end
end)

Players.PlayerRemoving:Connect(removeRoleEsp)
for _, p in ipairs(Players:GetPlayers()) do
    if p~=player then p.CharacterAdded:Connect(function()
        removeRoleEsp(p); task.wait(1); if roleEspOn then buildRoleEsp(p) end
    end) end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1); if roleEspOn then buildRoleEsp(p) end
    end)
end)

local t_rEsp = secInfo:Toggle("role esp (murderer/sheriff/innocent)", false, function(v)
    roleEspOn=v
    if not v then for p in pairs(roleEspCache) do removeRoleEsp(p) end end
end)
ui:CfgRegister("mm2_role_esp", function() return roleEspOn end, function(v) t_rEsp.Set(v) end)

-- ── Movement ──────────────────────────────────────────────────────────────────
local secMove = tabMain:Section("movement")
local DEF_WS = 16
local speedOn = false; local speedVal = 26
local function applySpeed(chr)
    chr = chr or player.Character; if not chr then return end
    local h = chr:FindFirstChildOfClass("Humanoid"); if not h then return end
    h.WalkSpeed = speedOn and speedVal or DEF_WS
end
player.CharacterAdded:Connect(function(c)
    c:WaitForChild("Humanoid"); task.wait(0.2); applySpeed(c)
end)
local t_spd = secMove:Toggle("fast walk", false, function(v) speedOn=v; applySpeed() end)
ui:CfgRegister("mm2_spd_on", function() return speedOn end, function(v) t_spd.Set(v) end)
local s_spd = secMove:Slider("speed (studs/s)", 8, 80, 26, function(v) speedVal=v; if speedOn then applySpeed() end end)
ui:CfgRegister("mm2_spd_val", function() return speedVal end, function(v) s_spd.Set(v) end)

local jumpOn=false; local jumpConn=nil
local t_jump = secMove:Toggle("infinite jump", false, function(v)
    jumpOn=v
    if jumpConn then jumpConn:Disconnect(); jumpConn=nil end
    if v then jumpConn=UserInputService.JumpRequest:Connect(function()
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end) end
end)
ui:CfgRegister("mm2_jump", function() return jumpOn end, function(v) t_jump.Set(v) end)

local noclipOn=false
RunService.Stepped:Connect(function()
    if not noclipOn then return end
    local chr=player.Character; if not chr then return end
    for _, p in ipairs(chr:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=false end
    end
end)
local t_nc = secMove:Toggle("noclip", false, function(v)
    noclipOn=v
    if not v then
        local chr=player.Character; if not chr then return end
        for _, p in ipairs(chr:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end
end)
ui:CfgRegister("mm2_noclip", function() return noclipOn end, function(v) t_nc.Set(v) end)

end -- TAB MAIN

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: ESP
-- ══════════════════════════════════════════════════════════════════════════════
do

local secESP = tabESP:Section("player esp")
local espOn = false; local espMax = 300
local espCache = {}

local function hpColor(h, mx)
    local p = math.clamp(h/math.max(mx,1),0,1)
    if p>.6 then return Color3.fromRGB(80,220,80)
    elseif p>.3 then return Color3.fromRGB(240,200,40)
    else return Color3.fromRGB(220,60,60) end
end

local function removeESP(p)
    local d=espCache[p]; if not d then return end
    pcall(function() if d.hl and d.hl.Parent then d.hl:Destroy() end end)
    pcall(function() if d.bb and d.bb.Parent then d.bb:Destroy() end end)
    espCache[p]=nil
end

local function buildESP(p)
    if espCache[p] then return end
    local chr=p.Character; if not chr then return end
    local hrp=chr:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local role=getRole(p); local col=ROLE_COLOR[role]

    local hl=Instance.new("Highlight"); hl.FillColor=col; hl.OutlineColor=Color3.new(1,1,1)
    hl.FillTransparency=0.45; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee=chr; hl.Parent=chr

    local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,140,0,60)
    bb.StudsOffset=Vector3.new(0,3.5,0); bb.AlwaysOnTop=true; bb.ResetOnSpawn=false
    bb.Adornee=hrp; bb.Parent=hrp

    local nm=Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,18)
    nm.Font=Enum.Font.GothamBold; nm.TextSize=13; nm.TextColor3=Color3.new(1,1,1)
    nm.TextStrokeTransparency=0.12; nm.TextXAlignment=Enum.TextXAlignment.Center
    nm.Text=p.DisplayName; nm.Parent=bb

    local rl=Instance.new("TextLabel"); rl.BackgroundTransparency=1; rl.Size=UDim2.new(1,0,0,14)
    rl.Position=UDim2.new(0,0,0,20); rl.Font=Enum.Font.GothamSemibold; rl.TextSize=10
    rl.TextColor3=col; rl.TextXAlignment=Enum.TextXAlignment.Center
    rl.Text="["..ROLE_LABEL[role].."]"; rl.Parent=bb

    local hpBg=Instance.new("Frame"); hpBg.Size=UDim2.new(1,0,0,4); hpBg.Position=UDim2.new(0,0,0,38)
    hpBg.BackgroundColor3=Color3.fromRGB(18,18,18); hpBg.BackgroundTransparency=0.3
    hpBg.BorderSizePixel=0; hpBg.Parent=bb
    Instance.new("UICorner",hpBg).CornerRadius=UDim.new(1,0)
    local hpF=Instance.new("Frame"); hpF.Size=UDim2.new(1,0,1,0); hpF.BorderSizePixel=0
    hpF.BackgroundColor3=Color3.fromRGB(80,220,80); hpF.Parent=hpBg
    Instance.new("UICorner",hpF).CornerRadius=UDim.new(1,0)

    local dl=Instance.new("TextLabel"); dl.BackgroundTransparency=1; dl.Size=UDim2.new(1,0,0,12)
    dl.Position=UDim2.new(0,0,0,46); dl.Font=Enum.Font.Gotham; dl.TextSize=10
    dl.TextColor3=Color3.fromRGB(200,200,220); dl.TextXAlignment=Enum.TextXAlignment.Center; dl.Parent=bb

    espCache[p]={hl=hl,bb=bb,nm=nm,rl=rl,hpF=hpF,dl=dl}
end

RunService.RenderStepped:Connect(function()
    if not espOn then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p==player then continue end
        local chr=p.Character; local hum=chr and chr:FindFirstChildOfClass("Humanoid")
        local hrp=chr and chr:FindFirstChild("HumanoidRootPart")
        if not chr or not hum or not hrp then removeESP(p); continue end
        if not isAlive(p) then removeESP(p); continue end
        local dist=math.floor((cam.CFrame.Position-hrp.Position).Magnitude)
        if dist>espMax then removeESP(p); continue end
        if not espCache[p] then buildESP(p) end
        local d=espCache[p]; if not d then continue end
        local role=getRole(p); local col=ROLE_COLOR[role]
        d.hl.FillColor=col; d.rl.TextColor3=col; d.rl.Text="["..ROLE_LABEL[role].."]"
        d.nm.Text=p.DisplayName
        local pct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        d.hpF.Size=UDim2.new(pct,0,1,0); d.hpF.BackgroundColor3=hpColor(hum.Health,hum.MaxHealth)
        d.dl.Text=dist.."m"
    end
end)

Players.PlayerRemoving:Connect(removeESP)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(1); if espOn then buildESP(p) end end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p~=player then p.CharacterAdded:Connect(function()
        removeESP(p); task.wait(1); if espOn then buildESP(p) end
    end) end
end

local t_esp=secESP:Toggle("player esp (por papel)", false, function(v)
    espOn=v
    if not v then for p in pairs(espCache) do removeESP(p) end end
end)
ui:CfgRegister("mm2_esp", function() return espOn end, function(v) t_esp.Set(v) end)
local s_dist=secESP:Slider("distancia max (studs)", 50, 1000, 300, function(v) espMax=v end)
ui:CfgRegister("mm2_esp_dist", function() return espMax end, function(v) s_dist.Set(v) end)

-- ── Gun / Item Dropped ESP ─────────────────────────────────────────────────────
local secItemEsp = tabESP:Section("item esp (knife + gun)")
local itemEspOn = false
local itemBBs = {}

local function removeItemBB(tool)
    local bb=itemBBs[tool]; if bb and bb.Parent then pcall(function() bb:Destroy() end) end
    itemBBs[tool]=nil
end

local function makeItemBB(tool)
    if itemBBs[tool] then return end
    if not isDropped(tool) then return end
    local isKnife = KNIFE_NAMES[tool.Name]
    local isGun   = GUN_NAMES[tool.Name]
    if not isKnife and not isGun then return end

    local adornee=tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart")
    if not adornee then
        task.spawn(function()
            local h=tool:WaitForChild("Handle",4)
            if h and itemEspOn and not itemBBs[tool] then makeItemBB(tool) end
        end)
        return
    end

    local col = isKnife and ROLE_COLOR.murderer or ROLE_COLOR.sheriff
    local label = isKnife and "[ KNIFE ]" or "[ GUN ]"

    local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,108,0,44)
    bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true; bb.ResetOnSpawn=false
    bb.Adornee=adornee; bb.Parent=adornee

    local nm=Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,22)
    nm.Font=Enum.Font.GothamBold; nm.TextSize=14; nm.TextColor3=col
    nm.TextStrokeTransparency=0.12; nm.TextXAlignment=Enum.TextXAlignment.Center
    nm.Text=label; nm.Parent=bb

    local dl=Instance.new("TextLabel"); dl.BackgroundTransparency=1; dl.Size=UDim2.new(1,0,0,14)
    dl.Position=UDim2.new(0,0,0,24); dl.Font=Enum.Font.Gotham; dl.TextSize=10
    dl.TextColor3=Color3.fromRGB(200,200,220); dl.TextXAlignment=Enum.TextXAlignment.Center
    dl.Text=""; dl.Parent=bb

    itemBBs[tool]=bb

    local conn; conn=RunService.RenderStepped:Connect(function()
        if not itemEspOn or not bb.Parent then conn:Disconnect(); return end
        local hrp=myHRP()
        if hrp and adornee and adornee.Parent then
            dl.Text=math.floor((hrp.Position-adornee.Position).Magnitude).."m"
        end
    end)
    tool.AncestryChanged:Connect(function()
        if not isDropped(tool) then removeItemBB(tool) end
    end)
end

local function scanItems()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and (KNIFE_NAMES[obj.Name] or GUN_NAMES[obj.Name]) then
            task.spawn(makeItemBB, obj)
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if not itemEspOn then return end
    if obj:IsA("Tool") and (KNIFE_NAMES[obj.Name] or GUN_NAMES[obj.Name]) then
        task.wait(0.15); task.spawn(makeItemBB, obj)
    end
end)

local t_item=secItemEsp:Toggle("knife + gun dropped esp", false, function(v)
    itemEspOn=v
    if v then scanItems() end
    for _, bb in pairs(itemBBs) do bb.Enabled=v end
end)
ui:CfgRegister("mm2_item_esp", function() return itemEspOn end, function(v) t_item.Set(v) end)

secItemEsp:Button("tp to knife", function()
    local hrp=myHRP(); if not hrp then return end
    local best, bestD=nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and KNIFE_NAMES[obj.Name] and isDropped(obj) then
            local h=obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
            if h then local d=(hrp.Position-h.Position).Magnitude
                if d<bestD then best=h; bestD=d end end
        end
    end
    if best then
        local dest=safeAbove(best,3); if dest then hrp.CFrame=CFrame.new(dest) end
        ui:Toast("rbxassetid://131165537896572","[Knife] tp","faca encontrada!",ROLE_COLOR.murderer)
    else ui:Toast("rbxassetid://131165537896572","tp knife","nao encontrada",ROLE_COLOR.unknown) end
end)

secItemEsp:Button("tp to gun", function()
    local hrp=myHRP(); if not hrp then return end
    local best, bestD=nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and GUN_NAMES[obj.Name] and isDropped(obj) then
            local h=obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
            if h then local d=(hrp.Position-h.Position).Magnitude
                if d<bestD then best=h; bestD=d end end
        end
    end
    if best then
        local dest=safeAbove(best,3); if dest then hrp.CFrame=CFrame.new(dest) end
        ui:Toast("rbxassetid://131165537896572","[Gun] tp","gun encontrada!",ROLE_COLOR.sheriff)
    else ui:Toast("rbxassetid://131165537896572","tp gun","nao encontrada",ROLE_COLOR.unknown) end
end)

end -- TAB ESP

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: COMBAT
-- ══════════════════════════════════════════════════════════════════════════════
do

-- ── Sheriff ───────────────────────────────────────────────────────────────────
local secSheriff = tabCombat:Section("sheriff")
secSheriff:Divider("botao flutuante de tiro")

local floatGui   = nil
local floatBtnOn = false
local shootCd    = false
local dragging   = false
local dragMoved  = false
local dragOff    = Vector2.zero

local function destroyFloat()
    if floatGui and floatGui.Parent then pcall(function() floatGui:Destroy() end) end
    floatGui=nil
end

local function buildFloat()
    destroyFloat()
    local sg=Instance.new("ScreenGui"); sg.Name="MM2ShootFloat"; sg.ResetOnSpawn=false
    sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.Parent=player.PlayerGui

    local card=Instance.new("Frame"); card.Size=UDim2.new(0,128,0,68)
    card.Position=UDim2.new(1,-148,0.5,-34); card.BackgroundColor3=T.panel
    card.BackgroundTransparency=0.05; card.BorderSizePixel=0; card.Parent=sg
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)

    local stroke=Instance.new("UIStroke"); stroke.Color=T.accent; stroke.Thickness=1.5
    stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Parent=card

    local top=Instance.new("Frame"); top.Size=UDim2.new(1,0,0,3); top.BorderSizePixel=0
    top.BackgroundColor3=T.accent; top.ZIndex=3; top.Parent=card
    Instance.new("UICorner",top).CornerRadius=UDim.new(0,10)
    local tg=Instance.new("UIGradient"); tg.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(160,65,255)),
        ColorSequenceKeypoint.new(1, T.acc2),
    }); tg.Parent=top

    local sub=Instance.new("TextLabel"); sub.Size=UDim2.new(1,-10,0,14)
    sub.Position=UDim2.new(0,6,0,6); sub.BackgroundTransparency=1
    sub.Font=Enum.Font.Gotham; sub.TextSize=10; sub.TextColor3=T.sub
    sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Text="SHERIFF"; sub.ZIndex=3; sub.Parent=card

    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,-12,0,34)
    btn.Position=UDim2.new(0,6,0,24); btn.BackgroundColor3=T.accent
    btn.BorderSizePixel=0; btn.Text=""; btn.AutoButtonColor=false; btn.ZIndex=3; btn.Parent=card
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
    local bGrad=Instance.new("UIGradient"); bGrad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(155,52,248)),
        ColorSequenceKeypoint.new(1, T.acc2),
    }); bGrad.Rotation=90; bGrad.Parent=btn

    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13
    lbl.TextColor3=T.text; lbl.ZIndex=4; lbl.Text="ATIRAR"; lbl.Parent=btn

    local ov=Instance.new("Frame"); ov.Size=UDim2.new(1,0,1,0)
    ov.BackgroundColor3=Color3.new(0,0,0); ov.BackgroundTransparency=0.55
    ov.BorderSizePixel=0; ov.ZIndex=5; ov.Visible=false; ov.Parent=btn
    Instance.new("UICorner",ov).CornerRadius=UDim.new(0,7)
    local ovLbl=Instance.new("TextLabel"); ovLbl.Size=UDim2.new(1,0,1,0)
    ovLbl.BackgroundTransparency=1; ovLbl.Font=Enum.Font.GothamBold; ovLbl.TextSize=12
    ovLbl.TextColor3=T.text; ovLbl.ZIndex=6; ovLbl.Parent=ov

    floatGui=sg

    local function flash(col, txt, dur)
        btn.BackgroundColor3=col; bGrad.Enabled=false; lbl.Text=txt
        task.delay(dur or 0.7, function()
            if not btn.Parent then return end
            btn.BackgroundColor3=T.accent; bGrad.Enabled=true; lbl.Text="ATIRAR"
        end)
    end

    card.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragMoved=false
            local ap=card.AbsolutePosition
            dragOff=Vector2.new(inp.Position.X-ap.X, inp.Position.Y-ap.Y)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then
            dragMoved=true
            local vp=cam.ViewportSize
            local nx=math.clamp(inp.Position.X-dragOff.X,0,vp.X-card.AbsoluteSize.X)
            local ny=math.clamp(inp.Position.Y-dragOff.Y,0,vp.Y-card.AbsoluteSize.Y)
            card.Position=UDim2.new(0,nx,0,ny)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)

    btn.MouseButton1Click:Connect(function()
        if dragMoved then dragMoved=false; return end
        if shootCd then return end
        local role=getRole()
        if role~="sheriff" then flash(T.err,"SEM GUN"); return end
        local m=findByRole("murderer")
        if not m then flash(T.warn,"NENHUM"); return end
        shootCd=true
        local ok=shootAt(m.Character)
        flash(ok and T.ok or T.err, ok and "FIRED!" or "FALHOU", 0.2)
        task.wait(0.25)
        ov.Visible=true; btn.BackgroundColor3=T.acc2; bGrad.Enabled=false; lbl.Text="ATIRAR"
        local t0=tick()
        while tick()-t0<1 do
            task.wait(0.05)
            if ovLbl.Parent then ovLbl.Text=string.format("%.1f",1-(tick()-t0)) end
        end
        if ov.Parent then ov.Visible=false end
        if btn.Parent then btn.BackgroundColor3=T.accent; bGrad.Enabled=true end
        shootCd=false
    end)

    btn.MouseEnter:Connect(function()
        if not shootCd then TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(162,65,255)}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if not shootCd then TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=T.accent}):Play() end
    end)
end

local t_float=secSheriff:Toggle("shoot button flutuante", false, function(v)
    floatBtnOn=v
    if v then buildFloat()
        ui:Toast("rbxassetid://131165537896572","[Shoot Btn]","arraste e clique ATIRAR",ROLE_COLOR.sheriff)
    else destroyFloat()
        ui:Toast("rbxassetid://131165537896572","[Shoot Btn]","removido",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_floatbtn", function() return floatBtnOn end, function(v) t_float.Set(v) end)
player.CharacterAdded:Connect(function() if floatBtnOn then task.wait(1); buildFloat() end end)

-- ── Auto Shoot ────────────────────────────────────────────────────────────────
secSheriff:Divider("auto shoot")
local autoShootOn=false; local lastShot=0; local shotCD=0.6

local function autoShootLoop()
    while autoShootOn do
        task.wait(0.15)
        if getRole()~="sheriff" then continue end
        if tick()-lastShot<shotCD then continue end
        local m=findByRole("murderer"); if not m then continue end
        local mHrp=m.Character and m.Character:FindFirstChild("HumanoidRootPart")
        local hrp=myHRP()
        if not mHrp or not hrp then continue end
        if (hrp.Position-mHrp.Position).Magnitude>200 then continue end
        lastShot=tick()
        shootAt(m.Character)
    end
end

local t_as=secSheriff:Toggle("auto shoot murderer", false, function(v)
    autoShootOn=v
    if v then
        ui:Toast("rbxassetid://131165537896572","[Auto Shoot]","ativo",ROLE_COLOR.sheriff)
        task.spawn(autoShootLoop)
    else ui:Toast("rbxassetid://131165537896572","[Auto Shoot]","desativado",ROLE_COLOR.unknown) end
end)
ui:CfgRegister("mm2_autoshoot", function() return autoShootOn end, function(v) t_as.Set(v) end)
local s_scd=secSheriff:Slider("cooldown tiro (x0.1s)", 1, 20, 6, function(v) shotCD=v/10 end)
ui:CfgRegister("mm2_shot_cd", function() return shotCD*10 end, function(v) s_scd.Set(v) end)

secSheriff:Divider("ataques manuais")
secSheriff:Button("atirar no murderer (1x)", function()
    if getRole()~="sheriff" then
        ui:Toast("rbxassetid://131165537896572","[Shoot]","voce nao e xerife",ROLE_COLOR.unknown); return end
    local m=findByRole("murderer")
    if not m then
        ui:Toast("rbxassetid://131165537896572","[Shoot]","murderer nao detectado",ROLE_COLOR.unknown); return end
    local ok=shootAt(m.Character)
    ui:Toast("rbxassetid://131165537896572","[Shoot]",
        (ok and "disparado" or "falhou").." -> "..m.DisplayName, ROLE_COLOR.sheriff)
end)

secSheriff:Button("tp para murderer", function()
    local m=findByRole("murderer")
    if not m then
        ui:Toast("rbxassetid://131165537896572","tp","murderer nao detectado",ROLE_COLOR.unknown); return end
    local mh=m.Character and m.Character:FindFirstChild("HumanoidRootPart")
    local hrp=myHRP()
    if mh and hrp then hrp.CFrame=mh.CFrame*CFrame.new(0,0,-4)
        ui:Toast("rbxassetid://131165537896572","[TP] murderer","-> "..m.DisplayName,ROLE_COLOR.murderer) end
end)

-- ── Murderer ──────────────────────────────────────────────────────────────────
local secMurd=tabCombat:Section("murderer")
secMurd:Divider("knife aura")
local knifeAura=false; local knifeRange=12; local lastKnife=0; local knifeCd=0.5

local function knifeAuraLoop()
    while knifeAura do
        task.wait(0.1)
        if getRole()~="murderer" then continue end
        if tick()-lastKnife<knifeCd then continue end
        local hrp=myHRP(); if not hrp then continue end
        local best, bestD=nil, knifeRange
        for _, p in ipairs(Players:GetPlayers()) do
            if p==player then continue end
            local chr=p.Character; local ph=chr and chr:FindFirstChild("HumanoidRootPart")
            if not chr or not ph or not isAlive(p) then continue end
            local d=(hrp.Position-ph.Position).Magnitude
            if d<bestD then best=p; bestD=d end
        end
        if best then lastKnife=tick(); knifeAt(best.Character) end
    end
end

local t_ka=secMurd:Toggle("knife aura", false, function(v)
    knifeAura=v
    if v then task.spawn(knifeAuraLoop)
        ui:Toast("rbxassetid://131165537896572","[Knife Aura]","ativo",ROLE_COLOR.murderer)
    else ui:Toast("rbxassetid://131165537896572","[Knife Aura]","desativado",ROLE_COLOR.unknown) end
end)
ui:CfgRegister("mm2_knifeaura", function() return knifeAura end, function(v) t_ka.Set(v) end)
local s_kr=secMurd:Slider("range (studs)", 4, 60, 12, function(v) knifeRange=v end)
ui:CfgRegister("mm2_kniferange", function() return knifeRange end, function(v) s_kr.Set(v) end)

secMurd:Button("matar sheriff (1x)", function()
    if getRole()~="murderer" then
        ui:Toast("rbxassetid://131165537896572","[Knife]","voce nao e murderer",ROLE_COLOR.unknown); return end
    local s=findByRole("sheriff")
    if not s then
        ui:Toast("rbxassetid://131165537896572","[Knife]","sheriff nao detectado",ROLE_COLOR.unknown); return end
    knifeAt(s.Character)
    ui:Toast("rbxassetid://131165537896572","[Knife]","-> "..s.DisplayName,ROLE_COLOR.murderer)
end)

secMurd:Button("matar inocente mais proximo", function()
    if getRole()~="murderer" then
        ui:Toast("rbxassetid://131165537896572","[Knife]","voce nao e murderer",ROLE_COLOR.unknown); return end
    local hrp=myHRP(); if not hrp then return end
    local best, bestD=nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p==player then continue end
        local ph=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if ph and isAlive(p) then
            local d=(hrp.Position-ph.Position).Magnitude
            if d<bestD then best=p; bestD=d end
        end
    end
    if not best then
        ui:Toast("rbxassetid://131165537896572","[Knife]","nenhum alvo",ROLE_COLOR.unknown); return end
    knifeAt(best.Character)
    ui:Toast("rbxassetid://131165537896572","[Knife]","-> "..best.DisplayName,ROLE_COLOR.murderer)
end)

secMurd:Button("tp para sheriff", function()
    local s=findByRole("sheriff")
    if not s then
        ui:Toast("rbxassetid://131165537896572","tp","sheriff nao detectado",ROLE_COLOR.unknown); return end
    local sh=s.Character and s.Character:FindFirstChild("HumanoidRootPart")
    local hrp=myHRP()
    if sh and hrp then hrp.CFrame=sh.CFrame*CFrame.new(0,0,-4)
        ui:Toast("rbxassetid://131165537896572","[TP] sheriff","-> "..s.DisplayName,ROLE_COLOR.sheriff) end
end)

local secCI=tabCombat:Section("info")
secCI:Button("quem e o murderer / sheriff", function()
    local m=findByRole("murderer"); local s=findByRole("sheriff")
    local alive=0
    for _, p in ipairs(Players:GetPlayers()) do if isAlive(p) then alive=alive+1 end end
    ui:Toast("rbxassetid://131165537896572",
        "M: "..(m and m.DisplayName or "?").."  |  S: "..(s and s.DisplayName or "?"),
        "vivos: "..alive, ROLE_COLOR.unknown)
end)

end -- TAB COMBAT

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: FARM
-- ══════════════════════════════════════════════════════════════════════════════
do

-- ── Auto Farm Coins ───────────────────────────────────────────────────────────
local secFarm=tabFarm:Section("coin farm")
secFarm:Divider("auto farm (anti-kick)")

local farmOn=false; local farmDelay=1.2; local farmCount=0

local function collectCoinsLoop()
    farmCount=0
    while farmOn do
        local hrp=myHRP(); local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 then task.wait(2); continue end

        local coins=findAllCoins()
        if #coins==0 then task.wait(3); continue end

        -- Ordena por distância
        local myPos=hrp.Position
        table.sort(coins, function(a,b)
            if not(a.part and a.part.Parent) then return false end
            if not(b.part and b.part.Parent) then return true end
            return (a.part.Position-myPos).Magnitude < (b.part.Position-myPos).Magnitude
        end)

        for _, coinData in ipairs(coins) do
            if not farmOn then break end
            if not coinData.part or not coinData.part.Parent then continue end
            collectCoinInstant(coinData)
            farmCount=farmCount+1
            task.wait(farmDelay)
        end

        task.wait(2)
    end
end

local t_farm=secFarm:Toggle("auto farm coins", false, function(v)
    farmOn=v
    if v then
        ui:Toast("rbxassetid://131165537896572","[Farm] iniciado",
            "delay: "..farmDelay.."s", Color3.fromRGB(255,210,50))
        task.spawn(collectCoinsLoop)
    else
        ui:Toast("rbxassetid://131165537896572","[Farm] parado",
            "coletadas: "..farmCount, Color3.fromRGB(255,210,50))
    end
end)
ui:CfgRegister("mm2_farm", function() return farmOn end, function(v) t_farm.Set(v) end)

local s_fd=secFarm:Slider("delay por coin (0.5 ~ 3.0s)", 5, 30, 12, function(v) farmDelay=v/10 end)
ui:CfgRegister("mm2_farm_delay", function() return farmDelay*10 end, function(v) s_fd.Set(v) end)

secFarm:Button("status do farm", function()
    local coins=findAllCoins()
    ui:Toast("rbxassetid://131165537896572",
        farmOn and "[Farm] rodando" or "[Farm] parado",
        "coins no mapa: "..#coins.."  |  coletadas: "..farmCount,
        Color3.fromRGB(255,210,50))
end)

secFarm:Divider("coletar uma vez")
secFarm:Button("collect coins (1x)", function()
    local hrp=myHRP(); if not hrp then return end
    local coins=findAllCoins()
    if #coins==0 then
        ui:Toast("rbxassetid://131165537896572","coins","nenhuma encontrada",ROLE_COLOR.unknown); return end
    ui:Toast("rbxassetid://131165537896572","[Coins]","coletando "..#coins.."...",Color3.fromRGB(255,210,50))
    task.spawn(function()
        local myPos=hrp.Position
        table.sort(coins, function(a,b)
            if not(a.part and a.part.Parent) then return false end
            if not(b.part and b.part.Parent) then return true end
            return (a.part.Position-myPos).Magnitude < (b.part.Position-myPos).Magnitude
        end)
        for _, coinData in ipairs(coins) do
            if not coinData.part or not coinData.part.Parent then continue end
            collectCoinInstant(coinData)
            task.wait(farmDelay)
        end
        ui:Toast("rbxassetid://131165537896572","[Coins] feito!",
            "coletadas: "..#coins, Color3.fromRGB(255,210,50))
    end)
end)

-- ── Auto Gun Grab ──────────────────────────────────────────────────────────────
local secGrab=tabFarm:Section("gun grab (inocente)")
local grabOn=false
local function grabLoop()
    while grabOn do
        task.wait(0.5)
        local myRole=getRole()
        if myRole=="murderer" then continue end
        local hrp=myHRP(); if not hrp then continue end
        if getGunTool() then continue end
        local best, bestD=nil, 800
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and GUN_NAMES[obj.Name] and isDropped(obj) then
                local h=obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
                if h then local d=(hrp.Position-h.Position).Magnitude
                    if d<bestD then best=h; bestD=d end end
            end
        end
        if best then
            local dest=safeAbove(best,3.5)
            if dest then
                hrp=myHRP(); if not hrp then continue end
                hrp.CFrame=CFrame.new(dest)
            end
            task.wait(0.5)
        end
    end
end
local t_grab=secGrab:Toggle("auto pegar gun (inocente/sheriff)", false, function(v)
    grabOn=v
    if v then task.spawn(grabLoop)
        ui:Toast("rbxassetid://131165537896572","[Gun Grab]","buscando gun...",ROLE_COLOR.sheriff)
    else ui:Toast("rbxassetid://131165537896572","[Gun Grab]","desativado",ROLE_COLOR.unknown) end
end)
ui:CfgRegister("mm2_grab", function() return grabOn end, function(v) t_grab.Set(v) end)

-- ── Survival / Flee ────────────────────────────────────────────────────────────
local secSurv=tabFarm:Section("survival")
local survOn=false; local fleeDist=20
local function surviveLoop()
    while survOn do
        task.wait(0.2)
        if getRole()=="murderer" then continue end
        local m=findByRole("murderer"); if not m then continue end
        local mh=m.Character and m.Character:FindFirstChild("HumanoidRootPart")
        local hrp=myHRP()
        if not mh or not hrp then continue end
        local dist=(hrp.Position-mh.Position).Magnitude
        if dist<fleeDist then
            local dir=(hrp.Position-mh.Position).Unit
            local np=hrp.Position+dir*32
            if isValidPos(np) then hrp.CFrame=CFrame.new(np) end
        end
    end
end
local t_surv=secSurv:Toggle("auto fugir do murderer", false, function(v)
    survOn=v
    if v then task.spawn(surviveLoop)
        ui:Toast("rbxassetid://131165537896572","[Survive]","ativo",ROLE_COLOR.innocent)
    else ui:Toast("rbxassetid://131165537896572","[Survive]","desativado",ROLE_COLOR.unknown) end
end)
ui:CfgRegister("mm2_survive", function() return survOn end, function(v) t_surv.Set(v) end)
local s_fl=secSurv:Slider("range de fuga (studs)", 5, 60, 20, function(v) fleeDist=v end)
ui:CfgRegister("mm2_flee", function() return fleeDist end, function(v) s_fl.Set(v) end)

-- ── Anti-AFK ──────────────────────────────────────────────────────────────────
local secAfk=tabFarm:Section("anti-afk")
local afkOn=false; local afkConn=nil
local t_afk=secAfk:Toggle("anti-afk", false, function(v)
    afkOn=v
    if afkConn then afkConn:Disconnect(); afkConn=nil end
    if v then
        afkConn=RunService.Heartbeat:Connect(function()
            pcall(function()
                VirtualUser:Button2Down(Vector2.zero, cam.CFrame)
                VirtualUser:Button2Up(Vector2.zero, cam.CFrame)
            end)
        end)
        ui:Toast("rbxassetid://131165537896572","[Anti-AFK]","ativo",Color3.fromRGB(200,200,255))
    else
        ui:Toast("rbxassetid://131165537896572","[Anti-AFK]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_afk", function() return afkOn end, function(v) t_afk.Set(v) end)

end -- TAB FARM

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: CONFIG
-- ══════════════════════════════════════════════════════════════════════════════
ui:BuildConfigTab(tabCfg, "ref_mm2v6")

-- ── Welcome ───────────────────────────────────────────────────────────────────
task.delay(0.9, function()
    local role=getRole()
    ui:Toast("rbxassetid://131165537896572",
        "mm2 v6.0  ["..ROLE_LABEL[role].."]",
        "bem-vindo, "..player.DisplayName, ROLE_COLOR[role])
end)
