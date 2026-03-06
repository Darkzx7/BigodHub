--[[ ================================================================
  mm2_ui.lua — Murder Mystery 2  v9.1 (scanner-fixed)

  FIXES v9.1 (baseado no scanner real do servidor):
  ─ Coin Farm: agora busca Coin_Server (part com Touched real)
      estrutura real: CoinContainer > Coin_Server > CoinVisual
  ─ Gun Grab/ESP/TP: GunDrop é Part em ResearchFacility, não Tool
      busca por GetDescendants com nome GunDrop em todo workspace
  ─ Shoot/Silent Aim: hook em Tool.Activated via __namecall
      GunFired é só efeito visual — tiro real = Activated + physics
  ─ Hitbox Expander: continua igual (funciona via HRP client-side)
================================================================ --]]

local LIB_URL = "https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua"
local RefLib
pcall(function() RefLib = loadstring(game:HttpGet(LIB_URL, true))() end)
if not RefLib then error("[mm2] nao foi possivel carregar a UI lib") end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local cam    = workspace.CurrentCamera

local ui = RefLib.new("mm2 v16", "rbxassetid://131165537896572", "ref_mm2v16")

-- ══════════════════════════════════════════════════════════════════════════════
-- REMOTES REAIS (confirmados pelo scanner)
-- ══════════════════════════════════════════════════════════════════════════════

local GunFiredEvent, CoinCollectedEvent, RoleSelectEvent

pcall(function()
    -- scanner confirmou: ClientServices.WeaponService.GunFired
    GunFiredEvent = ReplicatedStorage:WaitForChild("ClientServices", 5)
        :WaitForChild("WeaponService", 5)
        :WaitForChild("GunFired", 5)
end)
pcall(function()
    CoinCollectedEvent = ReplicatedStorage.Remotes.Gameplay.CoinCollected
end)
pcall(function()
    RoleSelectEvent = ReplicatedStorage.Remotes.Gameplay.RoleSelect
end)

-- KnifeKill e GunKill (BindableEvents confirmados pelo scanner)
local KnifeKillEvent, GunKillEvent
pcall(function() KnifeKillEvent = ReplicatedStorage.Remotes.Gameplay.KnifeKill end)
pcall(function() GunKillEvent   = ReplicatedStorage.Remotes.Gameplay.GunKill   end)

-- EliminatePlayer (RemoteFunction confirmado pelo scanner)
local EliminatePlayerRemote
pcall(function() EliminatePlayerRemote = ReplicatedStorage.Remotes.Gameplay.EliminatePlayer end)

-- ══════════════════════════════════════════════════════════════════════════════
-- CONSTANTES
-- ══════════════════════════════════════════════════════════════════════════════

local KNIFE_NAMES   = { Knife = true }
local GUN_NAMES     = { Gun = true, ["Sheriff's Gun"] = true, Revolver = true, SheriffGun = true }
-- FIX: scanner mostrou que a gun dropada no mapa é Part chamada "GunDrop"
-- pai: ResearchFacility (ou qualquer mapa). NÃO é um Tool.
local GUNDROP_NAMES = { GunDrop = true }

-- FIX: estrutura real das coins confirmada pelo scanner:
-- Model|CoinContainer > Part|Coin_Server > Part|CoinVisual > MeshPart|MainCoin
-- O Touched server-side está em Coin_Server, então é ELA que devemos tocar
local COIN_SERVER_NAME = "Coin_Server"
local COIN_CONTAINER   = "CoinContainer"

local ROLE_COLOR = {
    murderer = Color3.fromRGB(220, 55, 55),
    sheriff  = Color3.fromRGB(55, 180, 220),
    innocent = Color3.fromRGB(80, 210, 80),
    unknown  = Color3.fromRGB(150, 150, 160),
}
local ROLE_LABEL = {
    murderer = "Murderer", sheriff = "Sheriff",
    innocent = "Innocent", unknown = "?"
}

-- ══════════════════════════════════════════════════════════════════════════════
-- CACHE DE DADOS (PlayerDataChanged)
-- ══════════════════════════════════════════════════════════════════════════════

local playerDataCache = {}
local roleCache = {}

local PlayerDataChangedEvent = nil
pcall(function()
    PlayerDataChangedEvent = ReplicatedStorage.Remotes.Gameplay.PlayerDataChanged
end)

if PlayerDataChangedEvent then
    PlayerDataChangedEvent.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        for username, info in pairs(data) do
            playerDataCache[username] = info
        end
    end)
end

if RoleSelectEvent then
    RoleSelectEvent.OnClientEvent:Connect(function(roleName)
        if not roleName then return end
        local low = tostring(roleName):lower()
        if low:find("murder") then roleCache[player] = "murderer"
        elseif low:find("sheriff") then roleCache[player] = "sheriff"
        else roleCache[player] = "innocent" end
    end)
end

player.CharacterAdded:Connect(function()
    playerDataCache = {}
    roleCache[player] = nil
    local bp = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
    if bp then bp.ChildAdded:Connect(function(child)
        if KNIFE_NAMES[child.Name] then roleCache[player] = "murderer"
        elseif GUN_NAMES[child.Name] then roleCache[player] = "sheriff" end
    end) end
end)
task.defer(function()
    local bp = player:FindFirstChild("Backpack"); if not bp then return end
    for n in pairs(KNIFE_NAMES) do if bp:FindFirstChild(n) then roleCache[player] = "murderer" end end
    for n in pairs(GUN_NAMES)   do if bp:FindFirstChild(n) then roleCache[player] = "sheriff"  end end
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════════════════════════

local function isAlive(p)
    local data = playerDataCache[p.Name]
    if data then return data.Dead ~= true end
    local alive = p:GetAttribute("Alive")
    if alive ~= nil then return alive == true end
    local chr = p.Character
    local hum = chr and chr:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function getRole(p)
    p = p or player
    local data = playerDataCache[p.Name]
    if data and data.Role then
        local low = data.Role:lower()
        if low == "murderer" then return "murderer" end
        if low == "sheriff"  then return "sheriff"  end
        if low == "innocent" then return "innocent" end
    end
    if roleCache[p] then return roleCache[p] end
    local attr = p:GetAttribute("Role")
    if attr then
        local low = attr:lower()
        if low:find("murder") then return "murderer" end
        if low:find("sheriff") then return "sheriff" end
        if low:find("innocent") then return "innocent" end
    end
    local bp  = p:FindFirstChild("Backpack")
    local chr = p.Character
    local function hasIn(c, names)
        if not c then return false end
        for n in pairs(names) do if c:FindFirstChild(n) then return true end end
        return false
    end
    if hasIn(chr, KNIFE_NAMES) or hasIn(bp, KNIFE_NAMES) then return "murderer" end
    if hasIn(chr, GUN_NAMES)   or hasIn(bp, GUN_NAMES)   then return "sheriff"  end
    return "innocent"
end

local function findByRole(role)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isAlive(p) and getRole(p) == role then return p end
    end
    return nil
end

local function myHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function isValidPos(pos)
    if not pos then return false end
    if pos ~= pos then return false end
    return pos.Magnitude < 100000
end

-- ══════════════════════════════════════════════════════════════════════════════
-- FIX: COIN FINDERS — busca Coin_Server (part com Touched real)
-- Estrutura real (scanner): CoinContainer > Coin_Server > CoinVisual > MainCoin
-- O servidor registra a coleta via Touched em Coin_Server
-- ══════════════════════════════════════════════════════════════════════════════

local function findAllCoinServers()
    local coins = {}
    local seen  = {}
    -- Busca todos Coin_Server no workspace inteiro
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == COIN_SERVER_NAME and obj:IsA("BasePart") then
            if obj.Parent and not seen[obj] and isValidPos(obj.Position) then
                seen[obj] = true
                table.insert(coins, obj)
            end
        end
    end
    return coins
end

-- ══════════════════════════════════════════════════════════════════════════════
-- FIX: GUN DROP FINDERS — GunDrop é Part, não Tool
-- Scanner: Part|GunDrop|pai:ResearchFacility
-- Precisa buscar GetDescendants em todo workspace por nome "GunDrop"
-- ══════════════════════════════════════════════════════════════════════════════

local function findDroppedGuns()
    local found = {}
    -- Busca GunDrop (Part do mapa — confirmado pelo scanner)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if GUNDROP_NAMES[obj.Name] and obj:IsA("BasePart") then
            table.insert(found, { tool = obj, handle = obj })
        end
    end
    -- Fallback: Tool com nome de gun que esteja dropado (não num backpack/char)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and GUN_NAMES[obj.Name] then
            local inBackpack = false
            local p = obj.Parent
            if p then
                if p:IsA("Backpack") then inBackpack = true end
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character == p then inBackpack = true; break end
                end
            end
            if not inBackpack then
                local h = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
                if h then table.insert(found, { tool = obj, handle = h }) end
            end
        end
    end
    return found
end

local function findDroppedKnives()
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and KNIFE_NAMES[obj.Name] then
            local inBackpack = false
            local p = obj.Parent
            if p then
                if p:IsA("Backpack") then inBackpack = true end
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character == p then inBackpack = true; break end
                end
            end
            if not inBackpack then
                local h = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
                if h then table.insert(found, { tool = obj, handle = h }) end
            end
        end
    end
    return found
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SILENT AIM v2 — hook Tool.Activated no frame certo
--
-- Como funciona no MM2:
--   O LocalScript da gun usa Tool.Activated para iniciar o tiro.
--   Internamente ele faz um Raycast da câmera para calcular o alvo.
--   Se no frame do Activated o CFrame da câmera aponta pro murderer,
--   o Raycast acerta ele — mesmo que visualmente você esteja olhando pra outro lugar.
--
-- Método: hook __namecall intercepta "Activate" na Tool da gun.
--   No frame exato do Activate: rotaciona a câmera pro murderer,
--   deixa o Activate acontecer normalmente, restaura a câmera 1 frame depois.
-- ══════════════════════════════════════════════════════════════════════════════

local silentAimOn    = false
local _namecallHook  = nil
local _newcc = (type(newcclosure) == "function") and newcclosure or function(f) return f end

local function getSilentTarget()
    local m = findByRole("murderer")
    if m and m.Character then
        return m.Character:FindFirstChild("HumanoidRootPart")
            or m.Character:FindFirstChild("Head")
    end
    return nil
end

local function startSilentAim()
    if _namecallHook then return end
    if type(getrawmetatable) ~= "function"
    or type(setreadonly) ~= "function"
    or type(getnamecallmethod) ~= "function" then
        warn("[mm2] executor sem suporte a hooks — silent aim indisponivel"); return
    end
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNC = rawget(mt, "__namecall")
        setreadonly(mt, false)
        rawset(mt, "__namecall", _newcc(function(self, ...)
            local method = getnamecallmethod()
            -- Hook no Activate da Tool (gun)
            if silentAimOn and method == "Activate" then
                -- Verifica se é a tool da gun do player
                local isGunTool = false
                if typeof(self) == "Instance" and self:IsA("Tool") then
                    if GUN_NAMES[self.Name] then isGunTool = true end
                end
                if isGunTool then
                    local target = getSilentTarget()
                    if target then
                        -- Rotaciona câmera para o alvo no frame do Activate
                        local savedCF = cam.CFrame
                        local eyePos  = cam.CFrame.Position
                        cam.CFrame    = CFrame.new(eyePos, target.Position)
                        -- Restaura 1 frame depois (invisível para outros)
                        task.defer(function()
                            pcall(function() cam.CFrame = savedCF end)
                        end)
                    end
                end
            end
            -- Hook FireServer genérico (cobertura extra para executors que usam isso)
            if silentAimOn and method == "FireServer" then
                pcall(function()
                    local target = getSilentTarget()
                    if not target then return end
                    local args = { ... }
                    -- Se o primeiro arg parece uma posição, substitui pelo alvo
                    if args[1] and typeof(args[1]) == "Vector3" then
                        args[1] = target.Position
                    end
                    return oldNC(self, table.unpack(args))
                end)
            end
            return oldNC(self, ...)
        end))
        setreadonly(mt, true)
        _namecallHook = oldNC
    end)
end

local function stopSilentAim()
    if not _namecallHook then return end
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        rawset(mt, "__namecall", _namecallHook)
        setreadonly(mt, true)
    end)
    _namecallHook = nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- HITBOX EXPANDER — expande HRP de todos os players
-- Funciona porque o servidor usa posição client-side para validar hits
-- ══════════════════════════════════════════════════════════════════════════════

local hitboxOn      = false
local hitboxSize    = 12
local hitboxTargets = {}
local _hbConn       = nil

local knifeHitboxOn   = false
local knifeHitboxSize = 15
local _knifeOrigSize  = nil
local _knifeHbConn    = nil

local function applyHitbox(p)
    if not p or p == player then return end
    local chr = p.Character; if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if not hitboxTargets[p] then
        hitboxTargets[p] = { size = hrp.Size, collide = hrp.CanCollide }
    end
    pcall(function()
        hrp.Size       = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        hrp.CanCollide = false
    end)
end

local function removeHitbox(p)
    if not p then return end
    local orig = hitboxTargets[p]; if not orig then return end
    local chr = p.Character
    if chr then
        local hrp = chr:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function()
            hrp.Size       = orig.size
            hrp.CanCollide = orig.collide
        end) end
    end
    hitboxTargets[p] = nil
end

local function removeAllHitboxes()
    for p in pairs(hitboxTargets) do removeHitbox(p) end
end

local function startHitbox()
    if _hbConn then _hbConn:Disconnect() end
    _hbConn = RunService.Heartbeat:Connect(function()
        if not hitboxOn then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == player then continue end
            applyHitbox(p)
        end
    end)
end

local function stopHitbox()
    if _hbConn then _hbConn:Disconnect(); _hbConn = nil end
    removeAllHitboxes()
end

Players.PlayerRemoving:Connect(function(p) removeHitbox(p) end)
for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        hitboxTargets[p] = nil
        if hitboxOn then task.wait(1); applyHitbox(p) end
    end)
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if hitboxOn then task.wait(1); applyHitbox(p) end
    end)
end)

-- ── Knife Hitbox ──────────────────────────────────────────────────────────────

local function getKnifeTool()
    local chr = player.Character
    if chr then
        for name in pairs(KNIFE_NAMES) do
            local t = chr:FindFirstChild(name); if t then return t end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for name in pairs(KNIFE_NAMES) do
            local t = bp:FindFirstChild(name); if t then return t end
        end
    end
    return nil
end

local function applyKnifeHitbox()
    local knife = getKnifeTool(); if not knife then return end
    local h = knife:FindFirstChild("Handle"); if not h then return end
    if not _knifeOrigSize then
        _knifeOrigSize = { size = h.Size, collide = h.CanCollide }
    end
    pcall(function()
        h.Size       = Vector3.new(knifeHitboxSize, knifeHitboxSize, knifeHitboxSize)
        h.CanCollide = false
    end)
end

local function removeKnifeHitbox()
    local knife = getKnifeTool()
    if knife then
        local h = knife:FindFirstChild("Handle")
        if h and _knifeOrigSize then
            pcall(function()
                h.Size       = _knifeOrigSize.size
                h.CanCollide = _knifeOrigSize.collide
            end)
        end
    end
    _knifeOrigSize = nil
end

local function startKnifeHitbox()
    if _knifeHbConn then _knifeHbConn:Disconnect() end
    _knifeHbConn = RunService.Heartbeat:Connect(function()
        if not knifeHitboxOn then return end
        applyKnifeHitbox()
    end)
end

local function stopKnifeHitbox()
    if _knifeHbConn then _knifeHbConn:Disconnect(); _knifeHbConn = nil end
    removeKnifeHitbox()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- GUN TOOLS
-- ══════════════════════════════════════════════════════════════════════════════

local function getGunHandle()
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for name in pairs(GUN_NAMES) do
            local tool = bp:FindFirstChild(name)
            if tool then
                local h = tool:FindFirstChild("Handle")
                if h then return h, tool end
            end
        end
    end
    local chr = player.Character
    if chr then
        for name in pairs(GUN_NAMES) do
            local tool = chr:FindFirstChild(name)
            if tool then
                local h = tool:FindFirstChild("Handle")
                if h then return h, tool end
            end
        end
    end
    return nil, nil
end

local function getGunTool()
    local _, t = getGunHandle(); return t
end

local function equipGun()
    local bp  = player:FindFirstChild("Backpack"); if not bp then return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for name in pairs(GUN_NAMES) do
        local t = bp:FindFirstChild(name)
        if t then hum:EquipTool(t); task.wait(0.12); return end
    end
end

local function getNearbyWorkspacePart(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local chars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(chars, p.Character) end
    end
    params.FilterDescendantsInstances = chars
    local result = workspace:Raycast(pos + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0), params)
    if result and result.Instance then return result.Instance end
    local best, bestD = nil, 25
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local d = (obj.Position - pos).Magnitude
            if d < bestD then best = obj; bestD = d end
        end
    end
    return best
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SHOOT — método principal: Activate direto na Tool (como clique real)
--
-- Por que isso funciona melhor que firesignal(GunFired):
--   GunFired é um RemoteEvent CLIENT-SIDE apenas (efeito visual da trajetória).
--   O tiro real é processado pelo LocalScript quando Tool.Activated dispara.
--   Ativar a tool diretamente = exatamente o que acontece com clique real.
--   Com silent aim ativo (câmera apontando pro alvo), o Raycast interno acerta.
-- ══════════════════════════════════════════════════════════════════════════════

local function shootAt(targetChar)
    if not targetChar then return false end
    local hrp  = myHRP(); if not hrp then return false end
    local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
               or targetChar:FindFirstChild("Head")
    if not tHRP then return false end

    local handle, gunTool = getGunHandle()
    if not handle then
        equipGun(); task.wait(0.15)
        handle, gunTool = getGunHandle()
    end
    if not handle then return false end

    -- Aponta HRP e câmera para o alvo (necessário para Raycast interno da gun)
    local targetPos = tHRP.Position
    hrp.CFrame = CFrame.lookAt(hrp.Position, targetPos)
    pcall(function()
        cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
    end)
    task.wait(0.02)

    local ok = false

    -- Método 1: Activate direto na Tool (= clique real do jogador)
    -- Com câmera apontada pro alvo, o Raycast interno acerta
    if gunTool then
        pcall(function()
            gunTool:Activate()
            ok = true
        end)
    end

    -- Método 2: firesignal no GunFired com origem no alvo
    -- (backup para executors que suportam firesignal)
    if not ok then
        pcall(function()
            local targetPart = getNearbyWorkspacePart(targetPos)
            firesignal(GunFiredEvent.OnClientEvent,
                handle,
                targetPos,
                targetPos + Vector3.new(0, -1, 0),
                targetPart or tHRP
            )
            ok = true
        end)
    end

    -- Método 3: tiro normal com firesignal, origem real
    if not ok then
        pcall(function()
            local targetPart = getNearbyWorkspacePart(targetPos)
            firesignal(GunFiredEvent.OnClientEvent,
                handle,
                handle.Position,
                targetPos,
                targetPart or tHRP
            )
            ok = true
        end)
    end

    -- Restaura câmera após tudo
    task.defer(function()
        pcall(function() cam.CFrame = cam.CFrame end)
    end)

    return ok
end

-- ══════════════════════════════════════════════════════════════════════════════
-- KNIFE
-- ══════════════════════════════════════════════════════════════════════════════

local function equipKnife()
    local bp  = player:FindFirstChild("Backpack"); if not bp then return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for name in pairs(KNIFE_NAMES) do
        local t = bp:FindFirstChild(name)
        if t then hum:EquipTool(t); task.wait(0.12); return end
    end
end

local function knifeAt(targetChar)
    if not targetChar then return false end
    local hrp  = myHRP(); if not hrp then return false end
    local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
               or targetChar:FindFirstChild("Head")
    if not tHRP then return false end
    local knife = getKnifeTool()
    if not knife then equipKnife(); task.wait(0.15); knife = getKnifeTool() end
    if not knife then return false end
    hrp.CFrame = CFrame.lookAt(hrp.Position, tHRP.Position)
    task.wait(0.03)
    pcall(function() knife:Activate() end)
    return true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- FIX: COIN FARM — teleporta para Coin_Server (part com Touched real)
-- Estrutura real: Model|CoinContainer > Part|Coin_Server > Part|CoinVisual
-- O Touched server-side está em Coin_Server — é ela que deve ser tocada
-- ══════════════════════════════════════════════════════════════════════════════

local function collectCoin(coinServer)
    if not coinServer or not coinServer.Parent then return end
    local hrp = myHRP(); if not hrp then return end
    local pos = coinServer.Position

    -- Teleporta diretamente dentro da Coin_Server (trigger Touched)
    local offsets = {
        Vector3.new(0, 0, 0),
        Vector3.new(0, 0.5, 0),
        Vector3.new(0, -0.5, 0),
        Vector3.new(0.3, 0, 0),
    }
    for _, off in ipairs(offsets) do
        hrp = myHRP(); if not hrp then return end
        if not coinServer.Parent then return end
        hrp.CFrame = CFrame.new(pos + off)
        task.wait(0.05)
    end

    -- Tenta BindableEvent local (UpdateDataClient confirmado no scanner)
    pcall(function()
        local upd = ReplicatedStorage:FindFirstChild("UpdateDataClient")
        if upd and upd:IsA("BindableEvent") then
            upd:Fire()
        end
    end)

    -- Tenta CoinCollected RemoteEvent
    if CoinCollectedEvent then
        pcall(function()
            if CoinCollectedEvent:IsA("RemoteEvent") then
                CoinCollectedEvent:FireServer()
            end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TEMA
-- ══════════════════════════════════════════════════════════════════════════════
local T = {
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
    for _, p in ipairs(Players:GetPlayers()) do if isAlive(p) then alive = alive + 1 end end
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
        ui:Toast("rbxassetid://131165537896572","scan","nenhum killer/sheriff detectado",ROLE_COLOR.unknown); return
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
    hl.FillColor=col; hl.OutlineColor=Color3.new(1,1,1); hl.FillTransparency=0.42
    hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee=chr; hl.Parent=chr
    local bb = Instance.new("BillboardGui")
    bb.Size=UDim2.new(0,130,0,40); bb.StudsOffset=Vector3.new(0,3.2,0)
    bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Adornee=hrp; bb.Parent=hrp
    local nm = Instance.new("TextLabel")
    nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,20)
    nm.Font=Enum.Font.GothamBold; nm.TextSize=13; nm.TextColor3=Color3.new(1,1,1)
    nm.TextStrokeTransparency=0.12; nm.TextXAlignment=Enum.TextXAlignment.Center
    nm.Text=p.DisplayName; nm.Parent=bb
    local rl = Instance.new("TextLabel")
    rl.BackgroundTransparency=1; rl.Size=UDim2.new(1,0,0,14); rl.Position=UDim2.new(0,0,0,22)
    rl.Font=Enum.Font.GothamSemibold; rl.TextSize=11; rl.TextColor3=col
    rl.TextStrokeTransparency=0.2; rl.TextXAlignment=Enum.TextXAlignment.Center
    rl.Text="["..ROLE_LABEL[role].."]"; rl.Parent=bb
    roleEspCache[p] = {hl=hl, bb=bb, nm=nm, rl=rl}
end

RunService.RenderStepped:Connect(function()
    if not roleEspOn then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        if not isAlive(p) then removeRoleEsp(p); continue end
        if not roleEspCache[p] then buildRoleEsp(p) end
        local d = roleEspCache[p]; if not d then continue end
        local role = getRole(p); local col = ROLE_COLOR[role]
        d.hl.FillColor=col; d.rl.TextColor3=col
        d.rl.Text="["..ROLE_LABEL[role].."]"; d.nm.Text=p.DisplayName
    end
end)
Players.PlayerRemoving:Connect(removeRoleEsp)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then p.CharacterAdded:Connect(function()
        removeRoleEsp(p); task.wait(1); if roleEspOn then buildRoleEsp(p) end
    end) end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1); if roleEspOn then buildRoleEsp(p) end
    end)
end)

local t_rEsp = secInfo:Toggle("role esp", false, function(v)
    roleEspOn=v; if not v then for p in pairs(roleEspCache) do removeRoleEsp(p) end end
end)
ui:CfgRegister("mm2_role_esp", function() return roleEspOn end, function(v) t_rEsp.Set(v) end)

local secMove = tabMain:Section("movement")
local DEF_WS = 16; local speedOn = false; local speedVal = 26
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
local s_spd = secMove:Slider("speed (studs/s)", 8, 80, 26, function(v)
    speedVal=v; if speedOn then applySpeed() end
end)
ui:CfgRegister("mm2_spd_val", function() return speedVal end, function(v) s_spd.Set(v) end)

local jumpOn=false; local jumpConn=nil
local t_jump = secMove:Toggle("infinite jump", false, function(v)
    jumpOn=v; if jumpConn then jumpConn:Disconnect(); jumpConn=nil end
    if v then jumpConn=UserInputService.JumpRequest:Connect(function()
        local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
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

end -- MAIN

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: ESP
-- ══════════════════════════════════════════════════════════════════════════════
do

local secESP = tabESP:Section("player esp")
local espOn = false; local espMax = 300; local espCache = {}

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
    if p ~= player then p.CharacterAdded:Connect(function()
        removeESP(p); task.wait(1); if espOn then buildESP(p) end
    end) end
end

local t_esp=secESP:Toggle("player esp (por papel)", false, function(v)
    espOn=v; if not v then for p in pairs(espCache) do removeESP(p) end end
end)
ui:CfgRegister("mm2_esp", function() return espOn end, function(v) t_esp.Set(v) end)
local s_dist=secESP:Slider("distancia max (studs)", 50, 1000, 300, function(v) espMax=v end)
ui:CfgRegister("mm2_esp_dist", function() return espMax end, function(v) s_dist.Set(v) end)

-- ──────────────────────────────────────────────────────────────────────────────
-- FIX: ITEM ESP — GunDrop é Part, não Tool
-- Scanner confirmou: Part|GunDrop|pai:ResearchFacility
-- Busca por nome "GunDrop" em BaseParts + Tools dropadas de knife
-- ──────────────────────────────────────────────────────────────────────────────
local secItemEsp = tabESP:Section("item esp (knife + gun)")
local itemEspOn = false; local itemBBs = {}

local function removeItemBB(obj)
    local bb=itemBBs[obj]; if bb and bb.Parent then pcall(function() bb:Destroy() end) end
    itemBBs[obj]=nil
end

local function makeItemBB(obj, adornee, isKnife)
    if itemBBs[obj] then return end
    if not adornee or not adornee.Parent then return end
    local col   = isKnife and ROLE_COLOR.murderer or ROLE_COLOR.sheriff
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
    itemBBs[obj] = bb

    local conn; conn=RunService.RenderStepped:Connect(function()
        if not itemEspOn or not bb.Parent then conn:Disconnect(); return end
        local hrp=myHRP()
        if hrp and adornee and adornee.Parent then
            dl.Text=math.floor((hrp.Position-adornee.Position).Magnitude).."m"
        end
    end)

    -- Remove ESP quando o objeto sair do workspace
    obj.AncestryChanged:Connect(function()
        if not obj:IsDescendantOf(workspace) then removeItemBB(obj) end
    end)
end

local function scanItems()
    -- FIX: GunDrop (Part do mapa) — confirmado pelo scanner
    for _, obj in ipairs(workspace:GetDescendants()) do
        if GUNDROP_NAMES[obj.Name] and obj:IsA("BasePart") then
            task.spawn(makeItemBB, obj, obj, false)
        end
        -- Knives dropadas (Tool)
        if obj:IsA("Tool") and KNIFE_NAMES[obj.Name] then
            local inBp = false
            local p = obj.Parent
            if p and p:IsA("Backpack") then inBp = true end
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Character == p then inBp = true; break end
            end
            if not inBp then
                local h = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
                if h then task.spawn(makeItemBB, obj, h, true) end
            end
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if not itemEspOn then return end
    task.wait(0.1)
    if GUNDROP_NAMES[obj.Name] and obj:IsA("BasePart") then
        makeItemBB(obj, obj, false)
    elseif obj:IsA("Tool") and KNIFE_NAMES[obj.Name] then
        local h = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
        if h then makeItemBB(obj, h, true) end
    end
end)

local t_item=secItemEsp:Toggle("knife + gun dropped esp", false, function(v)
    itemEspOn=v; if v then scanItems() end
    for _, bb in pairs(itemBBs) do bb.Enabled=v end
end)
ui:CfgRegister("mm2_item_esp", function() return itemEspOn end, function(v) t_item.Set(v) end)

secItemEsp:Button("tp to knife", function()
    local hrp=myHRP(); if not hrp then return end
    local knives = findDroppedKnives()
    local best, bestD = nil, math.huge
    for _, k in ipairs(knives) do
        local d = (hrp.Position - k.handle.Position).Magnitude
        if d < bestD then best = k.handle; bestD = d end
    end
    if best then
        hrp.CFrame = CFrame.new(best.Position + Vector3.new(0,3,0))
        ui:Toast("rbxassetid://131165537896572","[Knife] tp","encontrada! "..math.floor(bestD).."m",ROLE_COLOR.murderer)
    else
        ui:Toast("rbxassetid://131165537896572","tp knife","nenhuma knife dropada",ROLE_COLOR.unknown)
    end
end)

-- FIX: TP Gun — agora busca GunDrop (Part) além de Tool
secItemEsp:Button("tp to gun", function()
    local hrp=myHRP(); if not hrp then return end
    local guns = findDroppedGuns()
    local best, bestD = nil, math.huge
    for _, g in ipairs(guns) do
        local d = (hrp.Position - g.handle.Position).Magnitude
        if d < bestD then best = g.handle; bestD = d end
    end
    if best then
        hrp.CFrame = CFrame.new(best.Position + Vector3.new(0,3,0))
        ui:Toast("rbxassetid://131165537896572","[Gun] tp","encontrada! "..math.floor(bestD).."m",ROLE_COLOR.sheriff)
    else
        ui:Toast("rbxassetid://131165537896572","tp gun","nenhuma gun dropada no mapa",ROLE_COLOR.unknown)
    end
end)

end -- ESP

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: COMBAT
-- ══════════════════════════════════════════════════════════════════════════════
do

local secSheriff = tabCombat:Section("sheriff")

-- ── Silent Aim ────────────────────────────────────────────────────────────────
secSheriff:Divider("silent aim")
local t_sa = secSheriff:Toggle("silent aim (auto mira)", false, function(v)
    silentAimOn = v
    if v then
        startSilentAim()
        ui:Toast("rbxassetid://131165537896572","[Silent Aim]",
            "ativo — hook em Tool.Activate",ROLE_COLOR.sheriff)
    else
        stopSilentAim()
        ui:Toast("rbxassetid://131165537896572","[Silent Aim]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_silentaim", function() return silentAimOn end, function(v) t_sa.Set(v) end)

-- ── Hitbox Expander ───────────────────────────────────────────────────────────
secSheriff:Divider("hitbox expander")
local t_hb = secSheriff:Toggle("hitbox expander (todos players)", false, function(v)
    hitboxOn = v
    if v then
        startHitbox()
        ui:Toast("rbxassetid://131165537896572","[Hitbox]","players com hitbox "..hitboxSize.."x",ROLE_COLOR.sheriff)
    else
        stopHitbox()
        ui:Toast("rbxassetid://131165537896572","[Hitbox]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_hitbox", function() return hitboxOn end, function(v) t_hb.Set(v) end)
local s_hbsize = secSheriff:Slider("tamanho hitbox players (studs)", 4, 40, 12, function(v)
    hitboxSize = v
    if hitboxOn then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local chr = p.Character
                local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function()
                    hrp.Size       = Vector3.new(v,v,v)
                    hrp.CanCollide = false
                end) end
            end
        end
    end
end)
ui:CfgRegister("mm2_hitboxsize", function() return hitboxSize end, function(v) s_hbsize.Set(v) end)

-- ── Botão de tiro ─────────────────────────────────────────────────────────────
secSheriff:Divider("botao de tiro (mobile safe)")

local shootBtnGui = nil; local shootBtnOn = false; local shootCd = false

local function destroyShootBtn()
    if shootBtnGui and shootBtnGui.Parent then pcall(function() shootBtnGui:Destroy() end) end
    shootBtnGui = nil
end

local function buildShootBtn()
    destroyShootBtn()
    local sg = Instance.new("ScreenGui")
    sg.Name="MM2ShootBtn"; sg.ResetOnSpawn=false
    sg.IgnoreGuiInset=true; sg.DisplayOrder=99
    sg.Parent=player.PlayerGui

    local card = Instance.new("Frame")
    card.Size=UDim2.new(0,110,0,56)
    card.Position=UDim2.new(1,-120,1,-220)
    card.BackgroundColor3=T.panel; card.BackgroundTransparency=0.08
    card.BorderSizePixel=0; card.Parent=sg
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
    local stroke=Instance.new("UIStroke"); stroke.Color=ROLE_COLOR.sheriff
    stroke.Thickness=1.5; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Parent=card

    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,0,14)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Gotham; lbl.TextSize=9
    lbl.TextColor3=T.sub; lbl.TextXAlignment=Enum.TextXAlignment.Center
    lbl.Text="SHERIFF"; lbl.Position=UDim2.new(0,0,0,4); lbl.Parent=card

    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(1,-10,0,30); btn.Position=UDim2.new(0,5,0,20)
    btn.BackgroundColor3=ROLE_COLOR.sheriff; btn.BorderSizePixel=0
    btn.Text="ATIRAR"; btn.Font=Enum.Font.GothamBold; btn.TextSize=14
    btn.TextColor3=Color3.new(1,1,1); btn.AutoButtonColor=true; btn.Parent=card
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)

    shootBtnGui = sg

    local function setBtnState(text, color)
        if not btn.Parent then return end
        btn.Text=text; btn.BackgroundColor3=color
    end

    btn.Activated:Connect(function()
        if shootCd then return end
        if getRole() ~= "sheriff" then
            setBtnState("SEM GUN", T.err)
            task.delay(1.2, function() setBtnState("ATIRAR", ROLE_COLOR.sheriff) end); return
        end
        local m = findByRole("murderer")
        if not m then
            setBtnState("?", T.warn)
            task.delay(1.2, function() setBtnState("ATIRAR", ROLE_COLOR.sheriff) end); return
        end
        shootCd = true
        setBtnState("...", Color3.fromRGB(80,80,80))

        local mHRP = m.Character and (m.Character:FindFirstChild("HumanoidRootPart") or m.Character:FindFirstChild("Head"))
        if mHRP then
            pcall(function()
                cam.CFrame = CFrame.new(cam.CFrame.Position, mHRP.Position)
            end)
        end

        local ok = shootAt(m.Character)
        setBtnState(ok and "FIRED!" or "FALHOU", ok and T.ok or T.err)
        task.wait(1)
        setBtnState("ATIRAR", ROLE_COLOR.sheriff)
        shootCd = false
    end)
end

local t_btn = secSheriff:Toggle("shoot button (mobile safe)", false, function(v)
    shootBtnOn=v
    if v then buildShootBtn()
        ui:Toast("rbxassetid://131165537896572","[Btn]","canto inf-direito",ROLE_COLOR.sheriff)
    else destroyShootBtn() end
end)
ui:CfgRegister("mm2_shootbtn", function() return shootBtnOn end, function(v) t_btn.Set(v) end)
player.CharacterAdded:Connect(function()
    if shootBtnOn then task.wait(1); buildShootBtn() end
end)

-- ── Gun Aura ──────────────────────────────────────────────────────────────────
secSheriff:Divider("gun aura")
local gunAuraOn   = false
local gunAuraDist = 18
local lastGunAura = 0
local gunAuraCD   = 0.8

local function gunAuraLoop()
    while gunAuraOn do
        task.wait(0.1)
        if getRole() ~= "sheriff" then continue end
        if tick() - lastGunAura < gunAuraCD then continue end

        local m = findByRole("murderer"); if not m then continue end
        local mChr = m.Character; if not mChr then continue end
        local mHRP = mChr:FindFirstChild("HumanoidRootPart"); if not mHRP then continue end
        local hrp = myHRP(); if not hrp then continue end

        local dist = (hrp.Position - mHRP.Position).Magnitude
        if dist > gunAuraDist then
            hrp.CFrame = mHRP.CFrame * CFrame.new(0, 0, -(gunAuraDist * 0.6))
            task.wait(0.08)
            hrp = myHRP(); if not hrp then continue end
        end

        local targetPos = mHRP.Position
        hrp.CFrame = CFrame.lookAt(hrp.Position, targetPos)
        pcall(function()
            cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
        end)
        task.wait(0.04)

        lastGunAura = tick()
        shootAt(mChr)
    end
end

local t_ga = secSheriff:Toggle("gun aura (tp + silent aim + shoot)", false, function(v)
    gunAuraOn = v
    if v then
        task.spawn(gunAuraLoop)
        ui:Toast("rbxassetid://131165537896572","[Gun Aura]",
            "ativo — tp+mira+tiro no murderer",ROLE_COLOR.sheriff)
    else
        ui:Toast("rbxassetid://131165537896572","[Gun Aura]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_gunaura", function() return gunAuraOn end, function(v) t_ga.Set(v) end)

local s_gacd = secSheriff:Slider("gun aura cooldown (x0.1s)", 2, 30, 8, function(v)
    gunAuraCD = v / 10
end)
ui:CfgRegister("mm2_gacd", function() return gunAuraCD*10 end, function(v) s_gacd.Set(v) end)

-- ── Auto Shoot ────────────────────────────────────────────────────────────────
secSheriff:Divider("auto shoot (range livre)")
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
        if (hrp.Position-mHrp.Position).Magnitude>300 then continue end
        lastShot=tick()
        pcall(function()
            cam.CFrame = CFrame.new(cam.CFrame.Position, mHrp.Position)
        end)
        shootAt(m.Character)
    end
end

local t_as=secSheriff:Toggle("auto shoot murderer", false, function(v)
    autoShootOn=v
    if v then task.spawn(autoShootLoop)
        ui:Toast("rbxassetid://131165537896572","[Auto Shoot]","ativo",ROLE_COLOR.sheriff)
    else ui:Toast("rbxassetid://131165537896572","[Auto Shoot]","desativado",ROLE_COLOR.unknown) end
end)
ui:CfgRegister("mm2_autoshoot", function() return autoShootOn end, function(v) t_as.Set(v) end)
local s_scd=secSheriff:Slider("cooldown (x0.1s)", 1, 20, 6, function(v) shotCD=v/10 end)
ui:CfgRegister("mm2_shot_cd", function() return shotCD*10 end, function(v) s_scd.Set(v) end)

secSheriff:Divider("manual")
secSheriff:Button("atirar no murderer (1x)", function()
    if getRole()~="sheriff" then
        ui:Toast("rbxassetid://131165537896572","[Shoot]","voce nao e xerife",ROLE_COLOR.unknown); return end
    local m=findByRole("murderer")
    if not m then
        ui:Toast("rbxassetid://131165537896572","[Shoot]","murderer nao detectado",ROLE_COLOR.unknown); return end
    local mH = m.Character and m.Character:FindFirstChild("HumanoidRootPart")
    if mH then pcall(function()
        cam.CFrame = CFrame.new(cam.CFrame.Position, mH.Position)
    end) end
    local ok=shootAt(m.Character)
    ui:Toast("rbxassetid://131165537896572","[Shoot]",
        (ok and "disparado" or "falhou").." -> "..m.DisplayName, ROLE_COLOR.sheriff)
end)

secSheriff:Button("tp para murderer", function()
    local m=findByRole("murderer")
    if not m then
        ui:Toast("rbxassetid://131165537896572","tp","murderer nao detectado",ROLE_COLOR.unknown); return end
    local mh=m.Character and m.Character:FindFirstChild("HumanoidRootPart"); local hrp=myHRP()
    if mh and hrp then hrp.CFrame=mh.CFrame*CFrame.new(0,0,-4)
        ui:Toast("rbxassetid://131165537896572","[TP]","-> "..m.DisplayName,ROLE_COLOR.murderer) end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- MURDERER
-- ─────────────────────────────────────────────────────────────────────────────
local secMurd=tabCombat:Section("murderer")

secMurd:Divider("knife hitbox (aura de range)")
local t_kh = secMurd:Toggle("knife hitbox expander", false, function(v)
    knifeHitboxOn = v
    if v then
        startKnifeHitbox()
        ui:Toast("rbxassetid://131165537896572","[Knife Hitbox]",
            "ativo — handle "..knifeHitboxSize.." studs",ROLE_COLOR.murderer)
    else
        stopKnifeHitbox()
        ui:Toast("rbxassetid://131165537896572","[Knife Hitbox]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_knifehitbox", function() return knifeHitboxOn end, function(v) t_kh.Set(v) end)
local s_khs = secMurd:Slider("tamanho handle knife (studs)", 4, 40, 15, function(v)
    knifeHitboxSize = v
    if knifeHitboxOn then applyKnifeHitbox() end
end)
ui:CfgRegister("mm2_knifehitboxsize", function() return knifeHitboxSize end, function(v) s_khs.Set(v) end)

secMurd:Divider("knife aura (auto swing)")
local knifeAura=false; local knifeRange=12; local knifeCd=0.35
local _knifeAuraConn = nil

local function knifeAuraLoop()
    if _knifeAuraConn then _knifeAuraConn:Disconnect(); _knifeAuraConn = nil end
    equipKnife()
    local accum = 0
    _knifeAuraConn = RunService.Heartbeat:Connect(function(dt)
        if not knifeAura then
            _knifeAuraConn:Disconnect(); _knifeAuraConn = nil; return
        end
        accum = accum + dt
        if accum < knifeCd then return end
        accum = 0
        if getRole() ~= "murderer" then return end
        local hrp = myHRP(); if not hrp then return end
        local knife = getKnifeTool(); if not knife then return end
        local best, bestD = nil, knifeRange
        for _, p in ipairs(Players:GetPlayers()) do
            if p == player then continue end
            local ph = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if not ph or not isAlive(p) then continue end
            local d = (hrp.Position - ph.Position).Magnitude
            if d < bestD then best = p; bestD = d end
        end
        if best then
            local bHRP = best.Character and best.Character:FindFirstChild("HumanoidRootPart")
            if bHRP then hrp.CFrame = CFrame.lookAt(hrp.Position, bHRP.Position) end
            pcall(function() knife:Activate() end)
        end
    end)
end

local t_ka=secMurd:Toggle("knife aura", false, function(v)
    knifeAura=v
    if v then
        knifeAuraLoop()
        ui:Toast("rbxassetid://131165537896572","[Knife Aura]","ativo",ROLE_COLOR.murderer)
    else
        if _knifeAuraConn then _knifeAuraConn:Disconnect(); _knifeAuraConn=nil end
        ui:Toast("rbxassetid://131165537896572","[Knife Aura]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_knifeaura", function() return knifeAura end, function(v) t_ka.Set(v) end)
local s_kr=secMurd:Slider("range aura (studs)", 4, 60, 12, function(v) knifeRange=v end)
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

secMurd:Button("matar mais proximo", function()
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
    local sh=s.Character and s.Character:FindFirstChild("HumanoidRootPart"); local hrp=myHRP()
    if sh and hrp then hrp.CFrame=sh.CFrame*CFrame.new(0,0,-4)
        ui:Toast("rbxassetid://131165537896572","[TP]","-> "..s.DisplayName,ROLE_COLOR.sheriff) end
end)

local secCI=tabCombat:Section("info")
secCI:Button("quem e o murderer / sheriff", function()
    local m=findByRole("murderer"); local s=findByRole("sheriff"); local alive=0
    for _, p in ipairs(Players:GetPlayers()) do if isAlive(p) then alive=alive+1 end end
    ui:Toast("rbxassetid://131165537896572",
        "M: "..(m and m.DisplayName or "?").."  |  S: "..(s and s.DisplayName or "?"),
        "vivos: "..alive, ROLE_COLOR.unknown)
end)

end -- COMBAT

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: FARM
-- ══════════════════════════════════════════════════════════════════════════════
do

-- ─────────────────────────────────────────────────────────────────────────────
-- FIX: COIN FARM — usa findAllCoinServers() em vez de findAllCoins()
-- Teleporta para Coin_Server (BasePart com Touched real do servidor)
-- A estrutura real é: CoinContainer > Coin_Server > CoinVisual > MainCoin
-- ─────────────────────────────────────────────────────────────────────────────
local secFarm=tabFarm:Section("coin farm")
local farmOn=false; local farmDelay=1.2; local farmCount=0

local function collectCoinsLoop()
    farmCount=0
    while farmOn do
        local hrp=myHRP()
        local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 then task.wait(2); continue end

        local coins = findAllCoinServers()  -- FIX: busca Coin_Server
        if #coins==0 then task.wait(3); continue end

        local myPos=hrp.Position
        table.sort(coins, function(a,b)
            if not(a and a.Parent) then return false end
            if not(b and b.Parent) then return true end
            return (a.Position-myPos).Magnitude < (b.Position-myPos).Magnitude
        end)

        for _, coinPart in ipairs(coins) do
            if not farmOn then break end
            if not coinPart or not coinPart.Parent then continue end
            hrp=myHRP(); if not hrp then break end
            collectCoin(coinPart); farmCount=farmCount+1
            task.wait(farmDelay)
        end
        task.wait(1.5)
    end
end

local t_farm=secFarm:Toggle("auto farm coins", false, function(v)
    farmOn=v
    if v then task.spawn(collectCoinsLoop)
        ui:Toast("rbxassetid://131165537896572","[Farm] iniciado","delay: "..farmDelay.."s",Color3.fromRGB(255,210,50))
    else ui:Toast("rbxassetid://131165537896572","[Farm] parado","coletadas: "..farmCount,Color3.fromRGB(255,210,50)) end
end)
ui:CfgRegister("mm2_farm", function() return farmOn end, function(v) t_farm.Set(v) end)

local s_fd=secFarm:Slider("delay por coin (x0.1s)", 5, 30, 12, function(v) farmDelay=v/10 end)
ui:CfgRegister("mm2_farm_delay", function() return farmDelay*10 end, function(v) s_fd.Set(v) end)

secFarm:Button("status do farm", function()
    local coins = findAllCoinServers()
    ui:Toast("rbxassetid://131165537896572",
        farmOn and "[Farm] rodando" or "[Farm] parado",
        "no mapa: "..#coins.."  coletadas: "..farmCount, Color3.fromRGB(255,210,50))
end)

secFarm:Button("collect coins (1x)", function()
    local hrp=myHRP(); if not hrp then return end
    local coins = findAllCoinServers()
    if #coins==0 then
        ui:Toast("rbxassetid://131165537896572","coins","nenhuma Coin_Server encontrada",ROLE_COLOR.unknown); return end
    ui:Toast("rbxassetid://131165537896572","[Coins]","coletando "..#coins.."...",Color3.fromRGB(255,210,50))
    task.spawn(function()
        local myPos=hrp.Position
        table.sort(coins, function(a,b)
            if not(a and a.Parent) then return false end
            if not(b and b.Parent) then return true end
            return (a.Position-myPos).Magnitude < (b.Position-myPos).Magnitude
        end)
        local count=0
        for _, coinPart in ipairs(coins) do
            if not coinPart or not coinPart.Parent then continue end
            collectCoin(coinPart); count=count+1; task.wait(farmDelay)
        end
        ui:Toast("rbxassetid://131165537896572","[Coins] feito!","coletadas: "..count,Color3.fromRGB(255,210,50))
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- FIX: GUN GRAB — busca GunDrop (Part) em todo workspace
-- Scanner: Part|GunDrop|pai:ResearchFacility
-- ─────────────────────────────────────────────────────────────────────────────
local secGrab=tabFarm:Section("gun grab (inocente)")
local grabOn=false

local function grabLoop()
    while grabOn do
        task.wait(0.6)
        if getRole()=="murderer" then continue end
        local hrp=myHRP(); if not hrp then continue end
        if getGunTool() then continue end

        local best, bestD=nil, math.huge
        for _, g in ipairs(findDroppedGuns()) do
            local d = (hrp.Position - g.handle.Position).Magnitude
            if d < bestD then best = g.handle; bestD = d end
        end

        if best then
            hrp=myHRP(); if not hrp then continue end
            local savedCF = hrp.CFrame

            -- Tp para a GunDrop (Part do mapa — Touched registra a pegada)
            hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 2.5, 0))
            task.wait(0.35)

            hrp = myHRP(); if not hrp then continue end
            hrp.CFrame = savedCF
            task.wait(0.3)
        end
    end
end

local t_grab=secGrab:Toggle("auto pegar gun (vai e volta)", false, function(v)
    grabOn=v
    if v then task.spawn(grabLoop)
        ui:Toast("rbxassetid://131165537896572","[Gun Grab]","buscando GunDrop...",ROLE_COLOR.sheriff)
    else ui:Toast("rbxassetid://131165537896572","[Gun Grab]","desativado",ROLE_COLOR.unknown) end
end)
ui:CfgRegister("mm2_grab", function() return grabOn end, function(v) t_grab.Set(v) end)

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

local secAfk=tabFarm:Section("anti-afk")
local afkOn=false; local afkConn=nil
local t_afk=secAfk:Toggle("anti-afk", false, function(v)
    afkOn=v; if afkConn then afkConn:Disconnect(); afkConn=nil end
    if v then
        afkConn=RunService.Heartbeat:Connect(function()
            pcall(function()
                VirtualUser:Button2Down(Vector2.zero,cam.CFrame)
                VirtualUser:Button2Up(Vector2.zero,cam.CFrame)
            end)
        end)
        ui:Toast("rbxassetid://131165537896572","[Anti-AFK]","ativo",Color3.fromRGB(200,200,255))
    else ui:Toast("rbxassetid://131165537896572","[Anti-AFK]","desativado",ROLE_COLOR.unknown) end
end)
ui:CfgRegister("mm2_afk", function() return afkOn end, function(v) t_afk.Set(v) end)

end -- FARM

-- ══════════════════════════════════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════════════════════════════════
ui:BuildConfigTab(tabCfg, "ref_mm2v16")

task.delay(0.9, function()
    local role=getRole()
    ui:Toast("rbxassetid://131165537896572",
        "mm2 v9.1 scanner-fixed  ["..ROLE_LABEL[role].."]",
        "bem-vindo, "..player.DisplayName, ROLE_COLOR[role])
end)
