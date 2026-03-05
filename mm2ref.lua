--[[ ================================================================
  mm2_ui.lua — Murder Mystery 2  v9.0

  NOVO v9.0:
  ─ Silent Aim: hook no Camera.CFrame redireciona mira pro murderer
      funciona com qualquer clique manual na gun (invisível pra outros)
  ─ Hitbox Expander: aumenta HRP do murderer no cliente
      bala do servidor SEMPRE acerta (Roblox usa posição client-side para Raycast)
  ─ Gun Aura (Sheriff): tp + silent aim loop automático no murderer
  ─ PlayerDataChanged: getRole/isAlive 100% precisos via dado real do servidor
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

local ui = RefLib.new("mm2 v14b", "rbxassetid://131165537896572", "ref_mm2v14b")

-- ══════════════════════════════════════════════════════════════════════════════
-- REMOTES REAIS (Cobalt)
-- ══════════════════════════════════════════════════════════════════════════════

-- GunFired: firesignal(Event.OnClientEvent, Handle, originPos, targetPos, targetPart)
-- Handle    = player.Backpack.Gun.Handle
-- targetPart= BasePart do workspace perto do alvo (Raycast result)
local GunFiredEvent, CoinCollectedEvent, RoleSelectEvent

pcall(function()
    GunFiredEvent = ReplicatedStorage.ClientServices.WeaponService.GunFired
end)
pcall(function()
    CoinCollectedEvent = ReplicatedStorage.Remotes.Gameplay.CoinCollected
end)
pcall(function()
    RoleSelectEvent = ReplicatedStorage.Remotes.Gameplay.RoleSelect
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- CONSTANTES
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
local ROLE_LABEL = {
    murderer = "Murderer", sheriff = "Sheriff",
    innocent = "Innocent", unknown = "?"
}

-- ══════════════════════════════════════════════════════════════════════════════
-- CACHE DE DADOS (PlayerDataChanged — fonte REAL e mais confiável do MM2)
-- Formato: playerDataCache[username] = { Role="Sheriff", Dead=false, Coins=N }
-- Atualizado em tempo real pelo servidor a cada mudança de estado
-- ══════════════════════════════════════════════════════════════════════════════

local playerDataCache = {}  -- [username] = { Role, Dead, Coins, ... }
local roleCache = {}        -- fallback via RoleSelect

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
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════════════════════════

-- isAlive: usa PlayerDataChanged (Dead field) como fonte primária
local function isAlive(p)
    local data = playerDataCache[p.Name]
    if data then return data.Dead ~= true end
    -- fallback
    local alive = p:GetAttribute("Alive")
    if alive ~= nil then return alive == true end
    local chr = p.Character
    local hum = chr and chr:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

-- getRole: usa PlayerDataChanged (Role field) como fonte primária
-- Role vem como "Sheriff", "Murderer", "Innocent" — exatamente como o MM2 envia
local function getRole(p)
    p = p or player
    -- Método 1: PlayerDataChanged (mais confiável — dado real do servidor)
    local data = playerDataCache[p.Name]
    if data and data.Role then
        local low = data.Role:lower()
        if low == "murderer" then return "murderer" end
        if low == "sheriff"  then return "sheriff"  end
        if low == "innocent" then return "innocent" end
    end
    -- Método 2: cache do RoleSelect
    if roleCache[p] then return roleCache[p] end
    -- Método 3: atributo nativo
    local attr = p:GetAttribute("Role")
    if attr then
        local low = attr:lower()
        if low:find("murder") then return "murderer" end
        if low:find("sheriff") then return "sheriff" end
        if low:find("innocent") then return "innocent" end
    end
    -- Método 4: ferramentas no character/backpack
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

local function isDropped(tool)
    if not tool or not tool.Parent then return false end
    local p = tool.Parent
    -- Se está num Backpack → não dropado
    if p:IsA("Backpack") then return false end
    -- Se está no character de algum player → não dropado (equipado)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Character == p then return false end
    end
    -- Se o pai é um player diretamente → não dropado
    if p:IsA("Player") then return false end
    return true
end

-- ── Item Finders ─────────────────────────────────────────────────────────────
-- MM2 pode dropar armas como: Tool direto, Model>Tool, ou Model com BaseParts
-- Estratégia: busca por nome em TODOS os descendentes sem restrição de tipo pai

local function findDroppedItems(nameTable)
    local found = {}
    local seen  = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if seen[obj] then continue end
        seen[obj] = true
        -- Aceita Tool OU Model com nome de arma
        if (obj:IsA("Tool") or obj:IsA("Model")) and nameTable[obj.Name] then
            if isDropped(obj) then
                -- Tenta pegar Handle, senão pega qualquer BasePart
                local h = obj:FindFirstChild("Handle")
                       or obj:FindFirstChildWhichIsA("BasePart")
                       or obj:FindFirstChildOfClass("BasePart")
                if h then
                    table.insert(found, {tool=obj, handle=h})
                end
            end
        end
    end
    -- Fallback extra: busca pelo nome "Handle" dentro de qualquer coisa
    -- que não seja character/backpack — pega gun mesmo sem nome conhecido
    return found
end

local function findDroppedGuns()   return findDroppedItems(GUN_NAMES)   end
local function findDroppedKnives() return findDroppedItems(KNIFE_NAMES) end

-- ══════════════════════════════════════════════════════════════════════════════
-- SILENT AIM
-- Como funciona:
--   O servidor do MM2 usa um Raycast partindo da câmera/HRP do cliente
--   para validar o tiro. Se antes de clicar nós rotacionamos o CFrame da
--   câmera para apontar pro alvo, o Raycast do servidor acerta mesmo que
--   visualmente o jogador esteja olhando pra outro lado.
--   Restauramos o CFrame original após 1 frame para ser imperceptível.
-- ══════════════════════════════════════════════════════════════════════════════

local silentAimOn    = false
local _origCamCF     = nil
local _saConn        = nil
local _namecallHook  = nil  -- hook __namecall

local function getSilentAimTarget()
    local m = findByRole("murderer")
    if m and m.Character then return m.Character end
    return nil
end

-- Silent Aim REAL via __namecall hook
-- Como funciona:
--   O LocalScript da gun chama workspace:FindPartOnRayWithIgnoreList() ou
--   workspace:Raycast() para calcular onde a bala vai.
--   Hookeamos __namecall no workspace para interceptar qualquer chamada
--   de Raycast/FindPartOnRay e substituir a direção pelo alvo.
--   Resultado: a bala vai pro alvo independente de onde você está olhando.
--   Zero teleporte, zero movimento — invisível para outros jogadores.
local function startSilentAim()
    if _namecallHook then return end  -- já hookado

    local mouse = player:GetMouse()

    -- Hook principal via __namecall no workspace
    -- Intercepta: Raycast, FindPartOnRay, FindPartOnRayWithIgnoreList
    local mt = getrawmetatable(game)
    local oldNamecall = rawget(mt, "__namecall")
    setreadonly(mt, false)

    rawset(mt, "__namecall", newcclosure(function(self, ...)
        if not silentAimOn then return oldNamecall(self, ...) end

        local method = getnamecallmethod()
        -- Intercepta apenas chamadas de Raycast no workspace
        if (method == "Raycast" or method == "FindPartOnRay"
        or method == "FindPartOnRayWithIgnoreList"
        or method == "FindPartOnRayWithWhitelist") and self == workspace then

            local targetChar = getSilentAimTarget()
            if targetChar then
                local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
                          or targetChar:FindFirstChild("Head")
                if tHRP then
                    local args = {...}
                    -- args[1] = origin (Ray ou Vector3), args[2] = direction/ignorelist
                    -- Substitui a direção para apontar pro alvo
                    if method == "Raycast" then
                        -- workspace:Raycast(origin, direction, params)
                        local origin = args[1]
                        if typeof(origin) == "Vector3" then
                            local dir = (tHRP.Position - origin).Unit * 1000
                            return oldNamecall(self, origin, dir, args[3])
                        end
                    elseif method == "FindPartOnRay" then
                        -- workspace:FindPartOnRay(Ray, ignoreInstance, ...)
                        local ray = args[1]
                        if typeof(ray) == "Ray" then
                            local newDir = (tHRP.Position - ray.Origin).Unit * 1000
                            local newRay = Ray.new(ray.Origin, newDir)
                            return oldNamecall(self, newRay, args[2], args[3], args[4])
                        end
                    elseif method == "FindPartOnRayWithIgnoreList" then
                        local ray = args[1]
                        if typeof(ray) == "Ray" then
                            local newDir = (tHRP.Position - ray.Origin).Unit * 1000
                            local newRay = Ray.new(ray.Origin, newDir)
                            return oldNamecall(self, newRay, args[2], args[3], args[4])
                        end
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end))

    setreadonly(mt, true)
    _namecallHook = oldNamecall

    -- Também faz rawset no Mouse.Hit como camada extra
    _saConn = RunService.RenderStepped:Connect(function()
        if not silentAimOn then return end
        local targetChar = getSilentAimTarget()
        if not targetChar then return end
        local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
                  or targetChar:FindFirstChild("Head")
        if tHRP then
            pcall(function() rawset(mouse, "Hit", CFrame.new(tHRP.Position)) end)
            pcall(function() rawset(mouse, "Target", tHRP) end)
        end
    end)
end

local function stopSilentAim()
    if _saConn then _saConn:Disconnect(); _saConn = nil end
    -- Restaura __namecall original
    if _namecallHook then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            rawset(mt, "__namecall", _namecallHook)
            setreadonly(mt, true)
        end)
        _namecallHook = nil
    end
    pcall(function()
        local mouse = player:GetMouse()
        rawset(mouse, "Hit", nil)
        rawset(mouse, "Target", nil)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- KNIFE HITBOX EXPANDER (Handle da knife)
-- Como funciona:
--   Expande o Handle.Size da sua própria knife localmente.
--   O servidor usa Touched no Handle para registrar o hit.
--   Um Handle maior = área de swing muito maior = acerta de longe.
--   Diferente de tp — você swinga normalmente, só a área é maior.
--
-- HITBOX nos players (HRP):
--   Expande HRP de todos os players localmente.
--   Útil para gun (bala acerta hitbox maior) e knife swing.
-- ══════════════════════════════════════════════════════════════════════════════

local hitboxOn      = false
local hitboxSize    = 12
local hitboxTargets = {}
local _hbConn       = nil

-- Knife handle expander
local knifeHitboxOn   = false
local knifeHitboxSize = 15  -- studs (Handle da knife fica enorme)
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
        hrp.Size      = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        hrp.CanCollide = false  -- remove colisão física do hitbox expandido
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
            -- Hitbox APENAS no murderer (impostor)
            if getRole(p) == "murderer" then
                applyHitbox(p)
            else
                if hitboxTargets[p] then removeHitbox(p) end
            end
        end
    end)
end

local function stopHitbox()
    if _hbConn then _hbConn:Disconnect(); _hbConn = nil end
    removeAllHitboxes()
end

-- Expande o Handle da knife do próprio player
local function applyKnifeHitbox()
    local knife = getKnifeTool()
    if not knife then return end
    local h = knife:FindFirstChild("Handle"); if not h then return end
    if not _knifeOrigSize then
        _knifeOrigSize = { size = h.Size, collide = h.CanCollide }
    end
    pcall(function()
        h.Size       = Vector3.new(knifeHitboxSize, knifeHitboxSize, knifeHitboxSize)
        h.CanCollide = false  -- sem colisão física no handle expandido
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

-- ══════════════════════════════════════════════════════════════════════════════
-- SHOOT — firesignal EXATO do Cobalt
--
-- Assinatura real:
--   firesignal(GunFired.OnClientEvent,
--     player.Backpack.Gun.Handle,   ← vem do BACKPACK
--     originPos,                    ← posição da gun
--     targetPos,                    ← posição do alvo
--     someWorkspaceBasePart         ← BasePart do mapa via Raycast
--   )
-- ══════════════════════════════════════════════════════════════════════════════

local function getNearbyWorkspacePart(pos)
    -- Raycast de cima pra baixo (replica hit no chão/parede)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local chars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(chars, p.Character) end
    end
    params.FilterDescendantsInstances = chars

    local result = workspace:Raycast(pos + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0), params)
    if result and result.Instance then return result.Instance end

    -- Fallback brute-force
    local best, bestD = nil, 25
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local d = (obj.Position - pos).Magnitude
            if d < bestD then best = obj; bestD = d end
        end
    end
    return best
end

-- Pega Handle da gun — procura Backpack primeiro (como o Cobalt capturou)
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

local function shootAt(targetChar)
    if not targetChar or not GunFiredEvent then return false end

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

    -- Aponta HRP para o alvo (necessário para alguns LocalScripts da gun)
    hrp.CFrame = CFrame.lookAt(hrp.Position, tHRP.Position)
    task.wait(0.03)

    local targetPos  = tHRP.Position
    local targetPart = getNearbyWorkspacePart(targetPos)

    -- Estratégia 1: originPos = exatamente no alvo (bala nasce no alvo = hit instantâneo)
    -- O LocalScript da gun usa originPos apenas para efeito visual da trajetória.
    -- O servidor usa Touched no projétil — se o projétil começa no HRP, Touched dispara.
    local ok = false
    pcall(function()
        firesignal(GunFiredEvent.OnClientEvent,
            handle,
            targetPos,          -- origin = posição do alvo (bala nasce no alvo)
            targetPos + Vector3.new(0, -1, 0),  -- target levemente abaixo
            targetPart or tHRP
        )
        ok = true
    end)

    -- Estratégia 2: tiro normal com origem real mas apontando pro alvo
    -- (funciona se o servidor usa Raycast com distância grande)
    if not ok then
        pcall(function()
            firesignal(GunFiredEvent.OnClientEvent,
                handle,
                handle.Position,
                targetPos,
                targetPart or tHRP
            )
            ok = true
        end)
    end

    -- Estratégia 3: teleporta handle para o alvo momentaneamente
    -- (força Touched no HRP do target com o projétil)
    pcall(function()
        if gunTool then
            local savedCF = handle.CFrame
            handle.CFrame = CFrame.new(targetPos)
            task.wait(0.05)
            pcall(function() handle.CFrame = savedCF end)
        end
    end)

    -- Estratégia 4: tenta todos RemoteEvents da gun com várias assinaturas
    if gunTool then
        pcall(function()
            for _, obj in ipairs(gunTool:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    pcall(function() obj:FireServer(targetPos, tHRP, handle.Position) end)
                    pcall(function() obj:FireServer(tHRP, targetPos) end)
                    pcall(function() obj:FireServer(targetPos) end)
                end
            end
        end)
    end

    return ok
end

-- ══════════════════════════════════════════════════════════════════════════════
-- KNIFE
-- ══════════════════════════════════════════════════════════════════════════════

local function getKnifeTool()
    local chr = player.Character; if not chr then return nil end
    for name in pairs(KNIFE_NAMES) do
        local t = chr:FindFirstChild(name); if t then return t end
    end
    local bp = player:FindFirstChild("Backpack"); if not bp then return nil end
    for name in pairs(KNIFE_NAMES) do
        local t = bp:FindFirstChild(name); if t then return t end
    end
    return nil
end

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

    -- Aponta para o alvo e ativa swing normalmente
    -- O hitbox expandido do Handle garante que o Touched do servidor dispare
    hrp.CFrame = CFrame.lookAt(hrp.Position, tHRP.Position)
    task.wait(0.03)
    pcall(function() knife:Activate() end)

    -- Tenta RemoteEvents como camada extra (sem teleporte)
    pcall(function()
        for _, obj in ipairs(knife:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                pcall(function() obj:FireServer(tHRP.Position, tHRP) end)
            end
        end
    end)

    return true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COIN FARM
-- ══════════════════════════════════════════════════════════════════════════════

local function findAllCoins()
    local coins = {}
    local seen  = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if COIN_NAMES[obj.Name] then
            local part = nil
            if obj:IsA("BasePart") then
                part = obj
            elseif obj:IsA("Model") then
                part = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
            end
            if part and part.Parent and not seen[part] and isValidPos(part.Position) then
                seen[part] = true
                table.insert(coins, part)
            end
        end
    end
    return coins
end

local function collectCoin(coinPart)
    if not coinPart or not coinPart.Parent then return end
    local hrp = myHRP(); if not hrp then return end

    -- Teleporta diretamente para DENTRO da coin (trigger Touched server-side)
    -- Tenta 3x com offsets para garantir que o Touched dispare
    local pos = coinPart.Position
    local offsets = {
        Vector3.new(0, 0, 0),       -- dentro da coin
        Vector3.new(0, 0.5, 0),     -- levemente acima
        Vector3.new(0, -0.5, 0),    -- levemente abaixo
    }
    for _, off in ipairs(offsets) do
        hrp = myHRP(); if not hrp then return end
        if not coinPart.Parent then return end
        hrp.CFrame = CFrame.new(pos + off)
        task.wait(0.06)
    end

    -- Tenta FireServer se CoinCollected for RemoteEvent
    if CoinCollectedEvent then
        pcall(function()
            if CoinCollectedEvent:IsA("RemoteEvent") then
                CoinCollectedEvent:FireServer("Coin", 1, 1, {Value = 1})
            end
        end)
        -- Atualiza UI local
        pcall(function()
            firesignal(CoinCollectedEvent.OnClientEvent, "Coin", 1, 1, {Value = 1})
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

local secItemEsp = tabESP:Section("item esp (knife + gun)")
local itemEspOn = false; local itemBBs = {}

local function removeItemBB(tool)
    local bb=itemBBs[tool]; if bb and bb.Parent then pcall(function() bb:Destroy() end) end
    itemBBs[tool]=nil
end

local function makeItemBB(tool)
    if itemBBs[tool] then return end
    if not isDropped(tool) then return end
    local isKnife=KNIFE_NAMES[tool.Name]; local isGun=GUN_NAMES[tool.Name]
    if not isKnife and not isGun then return end
    local adornee = tool:FindFirstChild("Handle")
                 or tool:FindFirstChildWhichIsA("BasePart")
                 or tool:FindFirstChildOfClass("BasePart")
    if not adornee then
        task.spawn(function()
            task.wait(2)  -- espera a tool carregar
            local h = tool:FindFirstChild("Handle")
                   or tool:FindFirstChildOfClass("BasePart")
            if h and itemEspOn and not itemBBs[tool] then makeItemBB(tool) end
        end); return
    end
    local col=isKnife and ROLE_COLOR.murderer or ROLE_COLOR.sheriff
    local label=isKnife and "[ KNIFE ]" or "[ GUN ]"
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
    -- Usa os finders robustos que checam dentro de Models também
    for _, g in ipairs(findDroppedGuns()) do
        task.spawn(makeItemBB, g.tool)
    end
    for _, k in ipairs(findDroppedKnives()) do
        task.spawn(makeItemBB, k.tool)
    end
    -- Fallback: GetDescendants completo
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

-- ─────────────────────────────────────────────────────────────────────────────
-- SHERIFF
-- ─────────────────────────────────────────────────────────────────────────────
local secSheriff = tabCombat:Section("sheriff")

-- ── Silent Aim ────────────────────────────────────────────────────────────────
secSheriff:Divider("silent aim")
-- Silent aim redireciona a câmera para o murderer no frame exato do clique.
-- O servidor usa o CFrame da câmera para o Raycast de hit — então acerta
-- mesmo que visualmente você esteja olhando pra outro lugar.
local t_sa = secSheriff:Toggle("silent aim (auto mira)", false, function(v)
    silentAimOn = v
    if v then
        startSilentAim()
        ui:Toast("rbxassetid://131165537896572","[Silent Aim]",
            "ativo — clique normal na gun pra atirar",ROLE_COLOR.sheriff)
    else
        stopSilentAim()
        ui:Toast("rbxassetid://131165537896572","[Silent Aim]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_silentaim", function() return silentAimOn end, function(v) t_sa.Set(v) end)

-- ── Hitbox Expander ───────────────────────────────────────────────────────────
secSheriff:Divider("hitbox expander")
-- Aumenta o HRP do murderer localmente. Como o servidor usa posição client-side
-- para validar hits, um HRP enorme = impossível de errar com qualquer tiro.
-- Hitbox só no murderer (pra gun acertar mais fácil)
local t_hb = secSheriff:Toggle("hitbox expander (murderer)", false, function(v)
    hitboxOn = v
    if v then
        startHitbox()
        ui:Toast("rbxassetid://131165537896572","[Hitbox]","murderer hitbox "..hitboxSize.."x",ROLE_COLOR.sheriff)
    else
        stopHitbox()
        ui:Toast("rbxassetid://131165537896572","[Hitbox]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_hitbox", function() return hitboxOn end, function(v) t_hb.Set(v) end)
local s_hbsize = secSheriff:Slider("tamanho hitbox murderer (studs)", 4, 40, 12, function(v)
    hitboxSize = v
    if hitboxOn then
        local m = findByRole("murderer")
        if m and m.Character then
            local hrp = m.Character:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function()
                hrp.Size = Vector3.new(v,v,v)
                hrp.CanCollide = false
            end) end
        end
    end
end)
ui:CfgRegister("mm2_hitboxsize", function() return hitboxSize end, function(v) s_hbsize.Set(v) end)

-- ── Botão de tiro — mobile safe (.Activated) ──────────────────────────────────
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
    card.Position=UDim2.new(1,-120,1,-220)  -- canto inf-direito, longe do joystick
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

        -- Aplica silent aim manual antes do firesignal
        local mHRP = m.Character and (m.Character:FindFirstChild("HumanoidRootPart") or m.Character:FindFirstChild("Head"))
        if mHRP then
            pcall(function()
                local savedCF = cam.CFrame
                cam.CFrame = CFrame.new(cam.CFrame.Position, mHRP.Position)
                task.defer(function() pcall(function() cam.CFrame = savedCF end) end)
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
        if (hrp.Position-mHrp.Position).Magnitude>300 then continue end
        lastShot=tick()
        -- Aplica silent aim antes de atirar
        pcall(function()
            local saved = cam.CFrame
            cam.CFrame = CFrame.new(cam.CFrame.Position, mHrp.Position)
            task.defer(function() pcall(function() cam.CFrame = saved end) end)
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
    -- Silent aim manual
    local mH = m.Character and m.Character:FindFirstChild("HumanoidRootPart")
    if mH then pcall(function()
        local s=cam.CFrame; cam.CFrame=CFrame.new(cam.CFrame.Position,mH.Position)
        task.defer(function() pcall(function() cam.CFrame=s end) end)
    end) end
    local ok=shootAt(m.Character)
    ui:Toast("rbxassetid://131165537896572","[Shoot]",
        (ok and "disparado" or "falhou").." -> "..m.DisplayName, ROLE_COLOR.sheriff)
end)



-- ─────────────────────────────────────────────────────────────────────────────
-- MURDERER
-- ─────────────────────────────────────────────────────────────────────────────
local secMurd=tabCombat:Section("murderer")

-- Knife handle hitbox expander
secMurd:Divider("knife hitbox (aura de range)")
-- Expande o Handle da sua knife. O servidor usa Touched no Handle
-- para registrar o hit — Handle maior = range maior sem teleporte.
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
local knifeAura=false; local knifeRange=12; local lastKnife=0; local knifeCd=0.35

local _knifeAuraConn = nil  -- Heartbeat connection (sem task.wait = sem lag)

local function knifeAuraLoop()
    -- Para conexão anterior se existir
    if _knifeAuraConn then _knifeAuraConn:Disconnect(); _knifeAuraConn = nil end

    -- Pre-equipa a knife uma vez
    equipKnife()

    local accum = 0
    _knifeAuraConn = RunService.Heartbeat:Connect(function(dt)
        if not knifeAura then
            _knifeAuraConn:Disconnect(); _knifeAuraConn = nil; return
        end

        accum = accum + dt
        if accum < knifeCd then return end  -- respeita cooldown sem yield
        accum = 0

        if getRole() ~= "murderer" then return end

        local hrp = myHRP(); if not hrp then return end
        local knife = getKnifeTool(); if not knife then return end

        -- Acha alvo mais próximo dentro do range
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
            if bHRP then
                -- Aponta pro alvo (CFrame direto, sem yield)
                hrp.CFrame = CFrame.lookAt(hrp.Position, bHRP.Position)
            end
            -- Activate diretamente — sem task.spawn, sem task.wait
            -- Heartbeat já roda fora do render loop, é seguro
            pcall(function() knife:Activate() end)
        end
    end)
end

local t_ka=secMurd:Toggle("knife aura", false, function(v)
    knifeAura=v
    if v then
        knifeAuraLoop()  -- inicia direto (já usa Heartbeat internamente)
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



local secCI=tabCombat:Section("info")
secCI:Button("quem e o murderer / sheriff", function()
    local m=findByRole("murderer"); local s=findByRole("sheriff"); local alive=0
    for _, p in ipairs(Players:GetPlayers()) do if isAlive(p) then alive=alive+1 end end
    ui:Toast("rbxassetid://131165537896572",
        "M: "..(m and m.DisplayName or "?").."  |  S: "..(s and s.DisplayName or "?"),
        "vivos: "..alive, ROLE_COLOR.unknown)
end)

secCI:Button("[DEBUG] scan + copy", function()
    local ok, err = pcall(function()
        local lines = {}
        local seen  = {}

        -- Tools/Models dropados
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if seen[obj] then continue end
                if not obj or not obj.Parent then continue end
                pcall(function()
                    if obj:IsA("Tool") or obj:IsA("Model") then
                        if isDropped(obj) then
                            seen[obj] = true
                            table.insert(lines, "DROPPED|"..obj.ClassName.."|"..tostring(obj.Name).."|pai:"..tostring(obj.Parent.Name))
                        end
                    end
                end)
            end
        end)

        -- Keywords
        pcall(function()
            local kws = {"gun","knife","coin","handle","weapon","sheriff","murder"}
            for _, obj in ipairs(workspace:GetDescendants()) do
                if seen[obj] then continue end
                if not obj or not obj.Parent then continue end
                pcall(function()
                    local n = obj.Name:lower()
                    for _, kw in ipairs(kws) do
                        if n:find(kw,1,true) then
                            seen[obj] = true
                            table.insert(lines, "KW|"..obj.ClassName.."|"..tostring(obj.Name).."|pai:"..tostring(obj.Parent.Name))
                            break
                        end
                    end
                end)
            end
        end)

        -- Roles
        pcall(function()
            for u, d in pairs(playerDataCache) do
                if d and d.Role then
                    table.insert(lines, "ROLE|"..tostring(u).."|"..tostring(d.Role))
                end
            end
        end)

        if #lines == 0 then
            table.insert(lines, "vazio - rode durante partida com items no chao")
        end

        local output = table.concat(lines, "
")
        print("[MM2]
"..output)

        -- clipboard
        pcall(function()
            local fns = {setclipboard, toclipboard}
            for _, fn in ipairs(fns) do
                if type(fn) == "function" then
                    fn(output); break
                end
            end
        end)

        ui:Toast("rbxassetid://131165537896572","[Debug] "..#lines.." items","copiado!",ROLE_COLOR.sheriff)
    end)
    if not ok then
        ui:Toast("rbxassetid://131165537896572","[Debug] erro",tostring(err),ROLE_COLOR.err)
        print("[MM2 DEBUG ERROR] "..tostring(err))
    end
end)

end -- COMBAT

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: FARM
-- ══════════════════════════════════════════════════════════════════════════════
do

local secFarm=tabFarm:Section("coin farm")
local farmOn=false; local farmDelay=1.2; local farmCount=0

local function collectCoinsLoop()
    farmCount=0
    while farmOn do
        local hrp=myHRP()
        local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 then task.wait(2); continue end

        local coins=findAllCoins()
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
    local coins=findAllCoins()
    ui:Toast("rbxassetid://131165537896572",
        farmOn and "[Farm] rodando" or "[Farm] parado",
        "no mapa: "..#coins.."  coletadas: "..farmCount, Color3.fromRGB(255,210,50))
end)

secFarm:Button("collect coins (1x)", function()
    local hrp=myHRP(); if not hrp then return end
    local coins=findAllCoins()
    if #coins==0 then
        ui:Toast("rbxassetid://131165537896572","coins","nenhuma encontrada",ROLE_COLOR.unknown); return end
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

local secGrab=tabFarm:Section("gun grab (inocente)")
local grabOn=false

local function grabLoop()
    while grabOn do
        task.wait(0.6)
        if getRole()=="murderer" then continue end
        local hrp=myHRP(); if not hrp then continue end
        if getGunTool() then continue end  -- já tem gun

        -- Acha a gun dropada mais próxima (inclui guns dentro de Models)
        local best, bestD=nil, math.huge
        for _, g in ipairs(findDroppedGuns()) do
            local d = (hrp.Position - g.handle.Position).Magnitude
            if d < bestD then best = g.handle; bestD = d end
        end

        if best then
            hrp=myHRP(); if not hrp then continue end

            -- Salva posição original ANTES de qualquer tp
            local savedCF = hrp.CFrame

            -- Tp para cima da gun (pega a gun)
            hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 2.5, 0))
            task.wait(0.35)  -- tempo suficiente para o Touched registrar e equip acontecer

            -- Volta para a posição original
            hrp = myHRP(); if not hrp then continue end
            hrp.CFrame = savedCF

            task.wait(0.3)
        end
    end
end

local t_grab=secGrab:Toggle("auto pegar gun (vai e volta)", false, function(v)
    grabOn=v
    if v then task.spawn(grabLoop)
        ui:Toast("rbxassetid://131165537896572","[Gun Grab]","buscando gun...",ROLE_COLOR.sheriff)
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
ui:BuildConfigTab(tabCfg, "ref_mm2v14b")

task.delay(0.9, function()
    local role=getRole()
    ui:Toast("rbxassetid://131165537896572",
        "mm2 v14b.0  ["..ROLE_LABEL[role].."]",
        "bem-vindo, "..player.DisplayName, ROLE_COLOR[role])
end)
