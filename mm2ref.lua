-- ══════════════════════════════════════════════════════════════════════════════
-- SILENT AIM + HITBOX — REWRITE BASEADO NO SCAN
--
-- KNIFE: dano = TouchTransmitter no Handle da faca toca Character do alvo
--   → Hitbox expand no HRP do alvo NÃO resolve (servidor valida Character parts)
--   → Solução real: expandir TODAS as BaseParts do character do alvo (torso, limbs)
--     no cliente, pra que o Handle da sua faca encoste nelas naturalmente
--     enquanto você anda perto. Sem teleporte, sem Remote direto.
--
-- GUN: dano = GunClient dispara RemoteEvent|Shoot (dentro da Tool Gun)
--   com argumentos de posição/alvo → servidor faz raycast do GunRaycastAttachment1
--   → Silent aim real: hook no RemoteEvent.OnClientEvent é impossível direto,
--     mas podemos hookear o :FireServer via __newindex / método de mt no remote,
--     ou mais simples e funcional: usar __namecall hook pra interceptar FireServer
--     e substituir os args pelo alvo desejado.
-- ══════════════════════════════════════════════════════════════════════════════

local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
if not RefLib then error("[mm2] ERRO: RefLib nao carregou.") end

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
-- REMOTES (confirmados pelo scanner)
-- ══════════════════════════════════════════════════════════════════════════════

local GunFiredEvent
pcall(function()
    GunFiredEvent = ReplicatedStorage
        :WaitForChild("ClientServices", 5)
        .WeaponService
        :WaitForChild("GunFired", 5)
end)

local GetCoinEvent
pcall(function() GetCoinEvent = ReplicatedStorage.Remotes.Gameplay.GetCoin end)

local UpdateDataClient
pcall(function() UpdateDataClient = ReplicatedStorage:WaitForChild("UpdateDataClient", 3) end)

local PlayerDataChangedBind
pcall(function()
    PlayerDataChangedBind = ReplicatedStorage
        :WaitForChild("Modules", 5)
        :WaitForChild("CurrentRoundClient", 5)
        :WaitForChild("PlayerDataChanged", 5)
end)

local RoleSelectEvent
pcall(function() RoleSelectEvent = ReplicatedStorage.Remotes.Gameplay.RoleSelect end)

local KnifeKillEvent, GunKillEvent
pcall(function() KnifeKillEvent = ReplicatedStorage.Remotes.Gameplay.KnifeKill end)
pcall(function() GunKillEvent   = ReplicatedStorage.Remotes.Gameplay.GunKill   end)

local EliminatePlayerRemote
pcall(function() EliminatePlayerRemote = ReplicatedStorage.Remotes.Gameplay.EliminatePlayer end)

-- ══════════════════════════════════════════════════════════════════════════════
-- CONSTANTES
-- ══════════════════════════════════════════════════════════════════════════════

local KNIFE_NAMES   = { Knife = true }
local GUN_NAMES     = { Gun = true, ["Sheriff's Gun"] = true, Revolver = true, SheriffGun = true, GunDrop = true }
local GUNDROP_NAMES = { GunDrop = true }

-- Quando GunDrop some do workspace, alguém pegou — detecta quem
local function watchGunDropPickup()
    workspace.DescendantRemoving:Connect(function(obj)
        if not GUNDROP_NAMES[obj.Name] then return end
        -- Pequena espera pra gun aparecer no backpack/character do herói
        task.wait(0.15)
        for _, p in ipairs(Players:GetPlayers()) do
            if p == player then continue end
            local bp  = p:FindFirstChild("Backpack")
            local chr = p.Character
            for n in pairs(GUN_NAMES) do
                if (bp  and bp:FindFirstChild(n))
                or (chr and chr:FindFirstChild(n)) then
                    if roleCache[p] ~= "murderer" then
                        roleCache[p] = "hero"
                    end
                    break
                end
            end
        end
        -- Também checa o próprio player
        task.spawn(function()
            local bp  = player:FindFirstChild("Backpack")
            local chr = player.Character
            for n in pairs(GUN_NAMES) do
                if (bp  and bp:FindFirstChild(n))
                or (chr and chr:FindFirstChild(n)) then
                    roleCache[player] = "hero"
                    break
                end
            end
        end)
    end)
end
watchGunDropPickup()

-- Parts do character que o TouchTransmitter da faca verifica (confirmado: Handle toca character)
-- Expandir essas parts aumenta a área de colisão real que o servidor valida
local CHARACTER_HIT_PARTS = {
    "HumanoidRootPart", "UpperTorso", "LowerTorso", "Head",
    "RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg",
    "RightLowerArm", "LeftLowerArm", "RightLowerLeg", "LeftLowerLeg",
    "RightHand", "LeftHand", "RightFoot", "LeftFoot",
    -- R6 fallback
    "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg",
}

local ROLE_COLOR = {
    murderer = Color3.fromRGB(220, 55, 55),
    sheriff  = Color3.fromRGB(55, 180, 220),
    hero     = Color3.fromRGB(255, 165, 0),
    innocent = Color3.fromRGB(80, 210, 80),
    unknown  = Color3.fromRGB(150, 150, 160),
}
local ROLE_LABEL = {
    murderer = "Murderer", sheriff = "Sheriff",
    hero     = "Hero",     innocent = "Innocent", unknown = "?"
}

-- ══════════════════════════════════════════════════════════════════════════════
-- CACHE DE DADOS
-- ══════════════════════════════════════════════════════════════════════════════

local playerDataCache = {}
local roleCache = {}

if PlayerDataChangedBind then
    PlayerDataChangedBind.Event:Connect(function(data)
        if type(data) ~= "table" then return end
        for username, info in pairs(data) do
            playerDataCache[username] = info
        end
    end)
end

local function hookUpdateData(evName)
    pcall(function()
        local ev = ReplicatedStorage:FindFirstChild(evName)
        if ev and ev:IsA("RemoteEvent") then
            ev.OnClientEvent:Connect(function(data)
                if type(data) ~= "table" then return end
                for username, info in pairs(data) do
                    if type(info) == "table" then
                        playerDataCache[username] = info
                    end
                end
            end)
        end
    end)
end
hookUpdateData("UpdateData")
hookUpdateData("UpdateData2")
hookUpdateData("UpdateData3")

-- Limpa cache no início de cada round (scanner confirma RoundStart existe)
pcall(function()
    ReplicatedStorage.Remotes.Gameplay.RoundStart.OnClientEvent:Connect(function()
        playerDataCache = {}
        roleCache = {}
    end)
end)

-- GiveWeapon: servidor envia arma pro player antes do round começar
-- Argumento pode ser o nome da tool ou uma instância — detectamos o papel pelo tipo
pcall(function()
    ReplicatedStorage.Remotes.Gameplay.GiveWeapon.OnClientEvent:Connect(function(weaponArg)
        local name = ""
        if type(weaponArg) == "string" then
            name = weaponArg:lower()
        elseif typeof(weaponArg) == "Instance" then
            name = weaponArg.Name:lower()
        end
        if name:find("knife") then
            roleCache[player] = "murderer"
        elseif name:find("gun") or name:find("sheriff") or name:find("revolver") then
            roleCache[player] = "sheriff"
        end
    end)
end)

-- PlayerDataChanged (RemoteEvent): atualiza dados de TODOS os players
-- Scanner confirmou: RemoteEvent|Remotes.Gameplay.PlayerDataChanged
-- Dispara antes do round com papéis distribuídos
pcall(function()
    ReplicatedStorage.Remotes.Gameplay.PlayerDataChanged.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        for username, info in pairs(data) do
            if type(info) == "table" then
                playerDataCache[username] = info
                -- Se o servidor mandou o papel explícito, atualiza roleCache
                if info.Role then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Name == username then
                            local low = info.Role:lower()
                            if low:find("murder") then roleCache[p] = "murderer"
                            elseif low:find("sheriff") then roleCache[p] = "sheriff"
                            else roleCache[p] = "innocent" end
                        end
                    end
                end
            end
        end
    end)
end)

-- ShowRoleSelectNew: dispara quando o servidor está prestes a distribuir papéis
-- Bom momento pra checar o backpack de todos (a gun/knife pode já estar lá)
pcall(function()
    ReplicatedStorage.Remotes.Gameplay.ShowRoleSelectNew.OnClientEvent:Connect(function()
        task.wait(0.5)  -- pequena espera pra armas serem distribuídas
        for _, p in ipairs(Players:GetPlayers()) do
            local bp  = p:FindFirstChild("Backpack")
            local chr = p.Character
            local function hasIn(c, names)
                if not c then return false end
                for n in pairs(names) do if c:FindFirstChild(n) then return true end end
                return false
            end
            if hasIn(chr, KNIFE_NAMES) or hasIn(bp, KNIFE_NAMES) then
                roleCache[p] = "murderer"
            elseif hasIn(chr, GUN_NAMES) or hasIn(bp, GUN_NAMES) then
                roleCache[p] = "sheriff"
            end
        end
    end)
end)

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
        elseif GUNDROP_NAMES[child.Name] then roleCache[player] = "hero"
        elseif GUN_NAMES[child.Name] then roleCache[player] = "sheriff" end
    end) end
end)

-- Monitora backpack de TODOS os players pra detectar papel antes do round
local function watchPlayerBackpack(p)
    if p == player then return end
    local function onChildAdded(child)
        if KNIFE_NAMES[child.Name] then
            roleCache[p] = "murderer"
        elseif GUNDROP_NAMES[child.Name] then
            roleCache[p] = "hero"    -- inocente pegou gun do chão
        elseif child.Name == "Gun" or child.Name == "Sheriff's Gun"
            or child.Name == "Revolver" or child.Name == "SheriffGun" then
            roleCache[p] = "sheriff" -- sheriff original
        end
    end
    local bp = p:FindFirstChild("Backpack")
    if bp  then bp.ChildAdded:Connect(onChildAdded) end
    local chr = p.Character
    if chr then chr.ChildAdded:Connect(onChildAdded) end
end

-- Reconecta ao respawnar
local function watchPlayerFull(p)
    watchPlayerBackpack(p)
    p.CharacterAdded:Connect(function()
        roleCache[p] = nil  -- reseta papel do round anterior
        task.wait(0.3)
        watchPlayerBackpack(p)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then watchPlayerFull(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= player then watchPlayerFull(p) end
end)

task.defer(function()
    local bp = player:FindFirstChild("Backpack"); if not bp then return end
    for n in pairs(KNIFE_NAMES)  do if bp:FindFirstChild(n) then roleCache[player] = "murderer" end end
    for n in pairs(GUNDROP_NAMES) do if bp:FindFirstChild(n) then roleCache[player] = "hero"     end end
    for _, n in ipairs({"Gun","Sheriff's Gun","Revolver","SheriffGun"}) do
        if bp:FindFirstChild(n) then roleCache[player] = "sheriff" end
    end
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
        if low == "hero"     then return "hero"     end
        if low == "innocent" then return "innocent" end
    end
    if roleCache[p] then return roleCache[p] end
    local attr = p:GetAttribute("Role")
    if attr then
        local low = attr:lower()
        if low:find("murder") then return "murderer" end
        if low:find("sheriff") then return "sheriff" end
        if low:find("hero")   then return "hero"    end
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
    -- GunDrop no inventário = herói (inocente que pegou a gun do chão)
    -- Gun normal = sheriff original
    local function hasGunDrop(c)
        if not c then return false end
        for n in pairs(GUNDROP_NAMES) do if c:FindFirstChild(n) then return true end end
        return false
    end
    local function hasGunOriginal(c)
        if not c then return false end
        local GUN_ORIG = { Gun = true, ["Sheriff's Gun"] = true, Revolver = true, SheriffGun = true }
        for n in pairs(GUN_ORIG) do if c:FindFirstChild(n) then return true end end
        return false
    end
    if hasGunDrop(chr) or hasGunDrop(bp) then return "hero" end
    if hasGunOriginal(chr) or hasGunOriginal(bp) then return "sheriff" end
    return "innocent"
end

local function isArmed(p)
    local r = getRole(p)
    return r == "sheriff" or r == "hero" or r == "murderer"
end

local function findByRole(role)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isAlive(p) and getRole(p) == role then return p end
    end
    return nil
end

-- Retorna qualquer player armado com gun (sheriff ou hero)
local function findArmedWithGun()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isAlive(p) then
            local r = getRole(p)
            if r == "sheriff" or r == "hero" then return p end
        end
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

local function isRoundActive()
    -- GunDrop confirmado pelo scanner como indicador de round ativo
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" then return true end
    end
    -- RoundTimerPart com SurfaceGui (Timer) = round em andamento
    local rtp = workspace:FindFirstChild("RoundTimerPart")
    if rtp and #rtp:GetChildren() > 0 then return true end
    return false
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TOOL HELPERS
-- ══════════════════════════════════════════════════════════════════════════════

local function getGunHandle()
    local bp  = player:FindFirstChild("Backpack")
    local chr = player.Character
    for name in pairs(GUN_NAMES) do
        if bp  then local t = bp:FindFirstChild(name);  if t then local h = t:FindFirstChild("Handle"); if h then return h, t end end end
        if chr then local t = chr:FindFirstChild(name); if t then local h = t:FindFirstChild("Handle"); if h then return h, t end end end
    end
    return nil, nil
end

local function getGunTool()
    local _, t = getGunHandle(); return t
end

local function getKnifeTool()
    local bp  = player:FindFirstChild("Backpack")
    local chr = player.Character
    for name in pairs(KNIFE_NAMES) do
        if bp  and bp:FindFirstChild(name)  then return bp:FindFirstChild(name)  end
        if chr and chr:FindFirstChild(name) then return chr:FindFirstChild(name) end
    end
    return nil
end

local function equipGun()
    local bp  = player:FindFirstChild("Backpack"); if not bp then return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if not hum then return end
    for name in pairs(GUN_NAMES) do
        local t = bp:FindFirstChild(name)
        if t then hum:EquipTool(t); task.wait(0.12); return end
    end
end

local function equipKnife()
    local bp  = player:FindFirstChild("Backpack"); if not bp then return end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if not hum then return end
    for name in pairs(KNIFE_NAMES) do
        local t = bp:FindFirstChild(name)
        if t then hum:EquipTool(t); task.wait(0.12); return end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SILENT AIM
--
-- Como funciona o tiro da gun no MM2 (confirmado pelo scan):
--   GunClient → RemoteEvent|Shoot:FireServer(targetPos, targetInstance)
--   GunServer recebe e faz raycast do GunRaycastAttachment1 → targetPos
--
-- PROBLEMA NO MOBILE:
--   tool:Activate() não funciona no mobile — o GunClient usa TouchTap/TouchLongPress
--   pra detectar o toque, e o Activate() do executor não emula isso.
--   Resultado: o FireServer nunca é chamado, tiro não sai.
--
-- SOLUÇÃO MOBILE:
--   Detectamos o toque na tela via UserInputService.TouchTapInWorld (qualquer toque
--   no mundo 3D = intenção de atirar) e chamamos o FireServer diretamente no
--   Remote|Shoot da gun, substituindo a posição pelo alvo do silent aim.
--   No PC o hook de __namecall continua funcionando normalmente.
-- ══════════════════════════════════════════════════════════════════════════════

local silentAimOn     = false
local silentAimTarget = nil

local _namecallHooked  = false
local _mobileShootConn = nil
local _shootCooldown   = false
local _dumpCapturing   = false
local _dumpCallback    = nil

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function getSilentTarget()
    if silentAimTarget and silentAimTarget.Parent and isAlive(silentAimTarget) then
        return silentAimTarget
    end
    local myRole = getRole()
    if myRole == "sheriff" or myRole == "hero" then
        return findByRole("murderer")
    elseif myRole == "murderer" then
        local hrp = myHRP(); if not hrp then return nil end
        local best, bestD = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and isAlive(p) then
                local ph = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if ph then
                    local d = (hrp.Position - ph.Position).Magnitude
                    if d < bestD then best = p; bestD = d end
                end
            end
        end
        return best
    end
    return nil
end

local function getTargetHitPos(targetPlayer)
    if not targetPlayer then return nil end
    local chr = targetPlayer.Character; if not chr then return nil end
    local head = chr:FindFirstChild("Head")
    if head then return head.Position end
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position end
    return nil
end

local function getTargetInstance(targetPlayer)
    if not targetPlayer then return nil end
    local chr = targetPlayer.Character; if not chr then return nil end
    return chr:FindFirstChild("Head") or chr:FindFirstChild("HumanoidRootPart") or chr
end

-- Busca o Remote|Shoot dentro da gun equipada
local function getShootRemote()
    local chr = player.Character
    local bp  = player:FindFirstChild("Backpack")
    for name in pairs(GUN_NAMES) do
        local tool = (chr and chr:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
        if tool then
            -- Scanner confirmou: RemoteEvent|Shoot|pai:Gun
            local r = tool:FindFirstChild("Shoot")
            if r and r:IsA("RemoteEvent") then return r, tool end
            -- Fallback: qualquer RemoteEvent dentro da gun
            for _, obj in ipairs(tool:GetDescendants()) do
                if obj:IsA("RemoteEvent") then return obj, tool end
            end
        end
    end
    return nil, nil
end

-- Dispara o tiro via tool:Activate() — deixa o GunClient fazer o FireServer
-- O hook __namecall intercepta e substitui os args pelo alvo correto.
-- Assim não precisamos conhecer a assinatura exata do remote.
local function fireSilentShot()
    if _shootCooldown then return end
    local chr = player.Character; if not chr then return end

    -- Acha a gun no character (precisa estar equipada)
    local gunTool = nil
    for name in pairs(GUN_NAMES) do
        local t = chr:FindFirstChild(name)
        if t and t:IsA("Tool") then gunTool = t; break end
    end

    -- Se tiver no backpack, equipa primeiro
    if not gunTool then
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for name in pairs(GUN_NAMES) do
                local t = bp:FindFirstChild(name)
                if t and t:IsA("Tool") then
                    local hum = chr:FindFirstChildOfClass("Humanoid")
                    if hum then
                        pcall(function() hum:EquipTool(t) end)
                        task.wait(0.12)
                        gunTool = chr:FindFirstChild(name)
                    end
                    break
                end
            end
        end
    end

    if not gunTool then return end

    _shootCooldown = true
    -- Activate() faz o GunClient disparar o tiro normalmente.
    -- O hook __namecall vai interceptar o FireServer resultante e redirecionar pro alvo.
    pcall(function() gunTool:Activate() end)
    task.delay(0.7, function() _shootCooldown = false end)
end

-- Silent aim hook
local function hookSilentAim()
    if _namecallHooked then return end
    _namecallHooked = true

    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    pcall(function() setreadonly(mt, false) end)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()

        -- Captura dump
        if _dumpCapturing and method == "FireServer" and self:IsA("RemoteEvent") then
            local par = self.Parent
            if par and par:IsA("Tool") and GUN_NAMES[par.Name] then
                local cb = _dumpCallback
                if cb then cb(self.Name, par.Name, {...}) end
            end
        end

        -- Silent aim
        -- Source confirmado:
        --   PC/MouseLock: FireServer(attachCF_or_nil, GetMouseTargetCFrame()) -> arg2 = CFrame
        --   Mobile:       FireServer(attachCF_or_nil, GetTargetPosition(x,y)) -> arg2 = Vector3
        -- arg1 pode ser nil — GunClient passa nil quando nao acha o attachment no HRP
        -- Substituimos apenas arg2 pelo hitPos do alvo, deixando arg1 como veio
        if silentAimOn and method == "FireServer" and self:IsA("RemoteEvent") then
            local par = self.Parent
            if par and par:IsA("Tool") and GUN_NAMES[par.Name] then
                local target = getSilentTarget()
                local hitPos = target and getTargetHitPos(target)
                if hitPos then
                    local args = {...}
                    local arg1 = args[1]  -- attachCF ou nil, deixa como esta
                    local arg2orig = args[2]
                    local arg2new
                    if typeof(arg2orig) == "CFrame" then
                        arg2new = CFrame.new(hitPos)
                    else
                        arg2new = hitPos  -- Vector3 no mobile
                    end
                    return old_namecall(self, arg1, arg2new)
                end
            end
        end

        -- Hook WeaponService — redireciona mira antes do FireServer
        if silentAimOn then
            if method == "GetMouseTargetCFrame" then
                local target = getSilentTarget()
                local hitPos = target and getTargetHitPos(target)
                if hitPos then return CFrame.new(hitPos) end
            elseif method == "GetTargetPosition" then
                local target = getSilentTarget()
                local hitPos = target and getTargetHitPos(target)
                if hitPos then return hitPos end
            end
        end

        return old_namecall(self, ...)
    end)
end

-- No mobile o GunClient detecta Touch e retorna antes de atirar.
-- Solução: hooka o PreferredInput pra retornar Gamepad em vez de Touch,
-- enganando o GunClient pra executar o caminho do PC normalmente.
local _preferredInputHooked = false
local function hookPreferredInput()
    if _preferredInputHooked then return end
    _preferredInputHooked = true
    local mt = getrawmetatable(UserInputService)
    pcall(function() setreadonly(mt, false) end)
    local old_index = mt.__index
    mt.__index = newcclosure(function(self, key)
        if silentAimOn and key == "PreferredInput" then
            return Enum.PreferredInput.Gamepad  -- engana o GunClient
        end
        return old_index(self, key)
    end)
end

-- No mobile o GunClient já processa TouchTapInWorld sozinho e chama
-- GetTargetPosition(x,y) → FireServer. O hook __namecall já intercepta tudo.
-- startMobileSilentAim só garante que o hook está ativo.
local function startMobileSilentAim()
    -- Nada a fazer — o hook __namecall já cobre GetTargetPosition e FireServer
    -- O GunClient processa o toque via TouchTapInWorld nativamente
end

local function stopMobileSilentAim()
    if _mobileShootConn then
        _mobileShootConn:Disconnect()
        _mobileShootConn = nil
    end
end

local function unhookSilentAim()
    silentAimOn = false
    stopMobileSilentAim()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- HITBOX EXPANDER
-- Expande parts dos outros jogadores e adiciona NoCollisionConstraint entre
-- cada part expandida e as parts do SEU character — sem colisão física com
-- você, mas Touched continua funcionando normalmente.
-- ══════════════════════════════════════════════════════════════════════════════

local hitboxOn      = false
local hitboxSize    = 12
local hitboxVisible = false

-- Cache: { [player] = { {part, origSize, origTransp, noCollConstraints={}}, ... } }
local hitboxCache = {}

-- Retorna lista de BaseParts do character do player local
local function getMyParts()
    local chr = player.Character
    if not chr then return {} end
    local parts = {}
    for _, p in ipairs(chr:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(parts, p) end
    end
    return parts
end

-- Cria NoCollisionConstraint entre duas parts (sem colisão física, Touched intacto)
local function noCollide(partA, partB)
    local nc = Instance.new("NoCollisionConstraint")
    nc.Part0 = partA
    nc.Part1 = partB
    nc.Parent = partA  -- pai na part expandida — some junto quando restaurar
    return nc
end

local function applyHitboxToChar(p)
    if not p or p == player then return end
    local chr = p.Character; if not chr then return end
    if hitboxCache[p] then return end

    local myParts = getMyParts()
    local saved   = {}

    for _, part in ipairs(chr:GetDescendants()) do
        if not part:IsA("BasePart")     then continue end
        if part.Parent:IsA("Accessory") then continue end
        if part.Parent:IsA("Tool")      then continue end

        local origSize   = part.Size
        local origTransp = part.Transparency
        local maxDim     = math.max(origSize.X, origSize.Y, origSize.Z, 0.1)
        local scale      = hitboxSize / maxDim
        local constraints = {}

        if scale > 1 then
            pcall(function() part.Size = origSize * scale end)
        end
        if hitboxVisible then
            pcall(function() part.Transparency = 0.5 end)
        end

        -- NoCollisionConstraint com cada part do SEU character
        for _, myPart in ipairs(myParts) do
            pcall(function()
                table.insert(constraints, noCollide(part, myPart))
            end)
        end

        table.insert(saved, {
            part        = part,
            size        = origSize,
            transp      = origTransp,
            constraints = constraints,
        })
    end

    hitboxCache[p] = saved
end

local function restoreHitboxOfPlayer(p)
    local saved = hitboxCache[p]
    if not saved then return end
    for _, data in ipairs(saved) do
        -- Só restaura se a part ainda existe no jogo
        if data.part and data.part.Parent then
            pcall(function()
                data.part.Size         = data.size
                data.part.Transparency = data.transp
            end)
        end
        for _, nc in ipairs(data.constraints) do
            pcall(function() if nc and nc.Parent then nc:Destroy() end end)
        end
    end
    hitboxCache[p] = nil
end

local function restoreAllHitboxes()
    -- Copia as chaves antes de iterar pra evitar modificar durante loop
    local players = {}
    for p in pairs(hitboxCache) do table.insert(players, p) end
    for _, p in ipairs(players) do restoreHitboxOfPlayer(p) end
    hitboxCache = {}
end

-- Aplica/remove transparência sem alterar tamanho (pra toggle de visibilidade)
local function applyHitboxVisibility(visible)
    for _, saved in pairs(hitboxCache) do
        for _, data in ipairs(saved) do
            if data.part and data.part.Parent then
                pcall(function()
                    data.part.Transparency = visible and 0.5 or data.transp
                end)
            end
        end
    end
end

local function startHitbox()
    for _, p in ipairs(Players:GetPlayers()) do
        applyHitboxToChar(p)
    end
end

local function stopHitbox()
    hitboxOn = false
    restoreAllHitboxes()
end

-- Quando o SEU character muda, os NoCollisionConstraints antigos ficam inválidos
-- Reaplica hitbox em todos pra recriar os constraints com as novas parts
player.CharacterAdded:Connect(function()
    if not hitboxOn then return end
    task.wait(1)
    -- Restaura sem resetar o hitboxOn, e reaplica com as novas parts do player
    for p, saved in pairs(hitboxCache) do
        for _, data in ipairs(saved) do
            for _, nc in ipairs(data.constraints) do
                pcall(function() nc:Destroy() end)
            end
            data.constraints = {}
        end
        hitboxCache[p] = nil
    end
    for _, p in ipairs(Players:GetPlayers()) do
        applyHitboxToChar(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    hitboxCache[p] = nil
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        hitboxCache[p] = nil
        if hitboxOn then task.wait(1); applyHitboxToChar(p) end
    end)
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then
        p.CharacterAdded:Connect(function()
            hitboxCache[p] = nil
            if hitboxOn then task.wait(1); applyHitboxToChar(p) end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- KNIFE AT / SHOOT AT
-- ══════════════════════════════════════════════════════════════════════════════

local function shootAt(targetChar)
    if not targetChar then return false end
    local hrp  = myHRP(); if not hrp then return false end
    local tHRP = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
    if not tHRP then return false end

    local handle, gunTool = getGunHandle()
    if not handle then
        equipGun(); task.wait(0.15)
        handle, gunTool = getGunHandle()
    end
    if not handle then return false end

    local targetPos = tHRP.Position
    -- Aponta HRP pro alvo (necessário pro raycast do servidor)
    hrp.CFrame = CFrame.lookAt(hrp.Position, targetPos)
    task.wait(0.02)

    -- Garante que gun está equipada no character
    local chr = player.Character
    if chr and gunTool and not chr:FindFirstChild(gunTool.Name) then
        local hum = chr:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum:EquipTool(gunTool) end)
            task.wait(0.1)
            handle, gunTool = getGunHandle()
        end
    end

    if gunTool and chr and chr:FindFirstChild(gunTool.Name) then
        pcall(function() gunTool:Activate() end)
        return true
    end

    -- Fallback: FireServer direto no Shoot remote (confirmado pelo scanner)
    if gunTool then
        local shootRemote = gunTool:FindFirstChild("Shoot")
        if shootRemote and shootRemote:IsA("RemoteEvent") then
            pcall(function()
                local head = targetChar:FindFirstChild("Head") or tHRP
                shootRemote:FireServer(head.Position, head)
            end)
            return true
        end
        -- Busca qualquer RemoteEvent dentro da gun
        for _, obj in ipairs(gunTool:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                pcall(function()
                    obj:FireServer(targetPos, tHRP)
                end)
                return true
            end
        end
    end

    return false
end

local function knifeAt(targetChar)
    if not targetChar then return false end
    local hrp  = myHRP(); if not hrp then return false end
    local tHRP = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
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
-- GUN / KNIFE FINDERS
-- ══════════════════════════════════════════════════════════════════════════════

local function findDroppedGuns()
    local found = {}
    -- Scanner confirmou: Part|GunDrop (não Tool)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if GUNDROP_NAMES[obj.Name] and obj:IsA("BasePart") then
            table.insert(found, { tool = obj, handle = obj })
        end
    end
    return found
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COIN FARM
-- ══════════════════════════════════════════════════════════════════════════════

local FARM_FLY_SPEED  = 16
local farmPauseBetween = 0.8

local function findAllCoinServers()
    local coins = {}
    local seen  = {}
    -- Nomes possíveis baseado na estrutura do MM2
    local COIN_NAMES = {
        Coin_Server = true, Coin = true, CoinPart = true,
        MainCoin    = true, CoinValue = true,
    }
    for _, obj in ipairs(workspace:GetDescendants()) do
        if COIN_NAMES[obj.Name] and obj:IsA("BasePart") and not seen[obj] then
            if isValidPos(obj.Position) then
                seen[obj] = true
                table.insert(coins, obj)
            end
        end
    end
    return coins
end

local function flyTo(destination)
    local hrp = myHRP(); if not hrp then return end
    local chr = player.Character; if not chr then return end
    for _, p in ipairs(chr:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
    end
    local startPos = hrp.Position
    local dist     = (destination - startPos).Magnitude
    if dist < 0.5 then return end
    local steps    = math.max(3, math.ceil(dist))
    local stepTime = 1 / FARM_FLY_SPEED
    for i = 1, steps do
        hrp = myHRP(); if not hrp then return end
        local t   = i / steps
        local pos = startPos:Lerp(destination, t)
        hrp.CFrame = CFrame.new(pos)
        task.wait(stepTime)
    end
    hrp = myHRP()
    if hrp then hrp.CFrame = CFrame.new(destination) end
end

local function collectCoin(coinServer)
    if not coinServer or not coinServer.Parent then return end
    flyTo(coinServer.Position)
    local hrp = myHRP()
    if hrp and coinServer.Parent then
        hrp.CFrame = CFrame.new(coinServer.Position + Vector3.new(0.3, 0, 0))
        task.wait(0.05)
        hrp = myHRP()
        if hrp and coinServer.Parent then
            hrp.CFrame = CFrame.new(coinServer.Position)
        end
    end
    if GetCoinEvent then
        pcall(function() GetCoinEvent:FireServer() end)
    end
    task.wait(farmPauseBetween)
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
    local role = getRole(p); local col = ROLE_COLOR[role] or ROLE_COLOR.unknown
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
        local role = getRole(p); local col = ROLE_COLOR[role] or ROLE_COLOR.unknown
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
    local role=getRole(p); local col=ROLE_COLOR[role] or ROLE_COLOR.unknown
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
        local role=getRole(p); local col=ROLE_COLOR[role] or ROLE_COLOR.unknown
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

local secItemEsp = tabESP:Section("item esp (gun)")
local itemEspOn = false; local itemBBs = {}

local function removeItemBB(obj)
    local bb=itemBBs[obj]; if bb and bb.Parent then pcall(function() bb:Destroy() end) end
    itemBBs[obj]=nil
end

local function makeItemBB(obj, adornee)
    if itemBBs[obj] then return end
    if not adornee or not adornee.Parent then return end
    local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,108,0,44)
    bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true; bb.ResetOnSpawn=false
    bb.Adornee=adornee; bb.Parent=adornee
    local nm=Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,22)
    nm.Font=Enum.Font.GothamBold; nm.TextSize=14; nm.TextColor3=ROLE_COLOR.sheriff
    nm.TextStrokeTransparency=0.12; nm.TextXAlignment=Enum.TextXAlignment.Center
    nm.Text="[ GUN ]"; nm.Parent=bb
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
    obj.AncestryChanged:Connect(function()
        if not obj:IsDescendantOf(workspace) then removeItemBB(obj) end
    end)
end

local function scanItems()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if GUNDROP_NAMES[obj.Name] and obj:IsA("BasePart") then
            task.spawn(makeItemBB, obj, obj)
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if not itemEspOn then return end
    task.wait(0.1)
    if GUNDROP_NAMES[obj.Name] and obj:IsA("BasePart") then
        makeItemBB(obj, obj)
    end
end)

local t_item=secItemEsp:Toggle("gun dropped esp", false, function(v)
    itemEspOn=v; if v then scanItems() end
    for _, bb in pairs(itemBBs) do bb.Enabled=v end
end)
ui:CfgRegister("mm2_item_esp", function() return itemEspOn end, function(v) t_item.Set(v) end)

secItemEsp:Button("tp to gun", function()
    if not isAlive(player) then
        ui:Toast("rbxassetid://131165537896572","tp gun","voce esta morto",ROLE_COLOR.unknown); return
    end
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

-- ── SILENT AIM ──────────────────────────────────────────────────────────────
secSheriff:Divider("silent aim (hook fireserver)")

local t_sa = secSheriff:Toggle("silent aim (sem mover camera)", false, function(v)
    silentAimOn = v
    if v then
        hookSilentAim()
        hookPreferredInput()   -- engana GunClient pra não bloquear no mobile
        startMobileSilentAim()
        ui:Toast("rbxassetid://131165537896572","[Silent Aim]",
            "ativo — toque/clique na tela pra atirar",ROLE_COLOR.sheriff)
    else
        unhookSilentAim()
        ui:Toast("rbxassetid://131165537896572","[Silent Aim]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_silentaim", function() return silentAimOn end, function(v) t_sa.Set(v) end)

-- GUI de resultado do dump — aparece na tela com botão copiar
local function showDumpGui(text)
    -- Remove GUI anterior se existir
    local old = player.PlayerGui:FindFirstChild("MM2DumpGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "MM2DumpGui"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = player.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 420, 0, 320)
    frame.Position = UDim2.new(0.5, -210, 0.5, -160)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    frame.BorderSizePixel = 0
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 32)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "GUN DUMP — copie e mande pro dev"
    title.TextColor3 = Color3.fromRGB(200, 200, 210)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -34, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(180, 80, 80)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -76)
    scroll.Position = UDim2.new(0, 8, 0, 36)
    scroll.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -8, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.Position = UDim2.new(0, 4, 0, 4)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Color3.fromRGB(160, 220, 160)
    txt.Font = Enum.Font.Code
    txt.TextSize = 11
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextYAlignment = Enum.TextYAlignment.Top
    txt.TextWrapped = true
    txt.RichText = false
    txt.Parent = scroll

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(1, -16, 0, 32)
    copyBtn.Position = UDim2.new(0, 8, 1, -40)
    copyBtn.BackgroundColor3 = Color3.fromRGB(55, 180, 100)
    copyBtn.BorderSizePixel = 0
    copyBtn.Text = "📋  COPIAR TUDO"
    copyBtn.TextColor3 = Color3.new(1,1,1)
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 13
    copyBtn.Parent = frame
    local copyReady = false
    copyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    copyBtn.Text = "⏳  aguarde 5s..."

    -- Habilita o botão após 5s
    task.delay(5, function()
        pcall(function()
            copyReady = true
            copyBtn.BackgroundColor3 = Color3.fromRGB(55, 180, 100)
            copyBtn.Text = "📋  COPIAR TUDO"
        end)
    end)

    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
    copyBtn.MouseButton1Click:Connect(function()
        if not copyReady then return end
        pcall(function() setclipboard(text) end)
        copyBtn.Text = "✔  COPIADO!"
        copyBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 70)
        task.delay(2, function()
            pcall(function()
                if sg and sg.Parent then sg:Destroy() end
            end)
        end)
    end)
end

-- Botão de dump — captura args reais do GunClient
secSheriff:Button("DUMP gun (equipa gun e clica)", function()
    local gunTool = getGunTool()
    if not gunTool then
        ui:Toast("rbxassetid://131165537896572","Dump","equipa a gun primeiro",ROLE_COLOR.unknown)
        return
    end

    -- Coleta estrutura da gun
    local lines = {}
    local function ln(s) table.insert(lines, tostring(s)) end

    ln("=== MM2 GUN DUMP ===")
    ln("Tool: " .. gunTool.Name)
    ln("--- Descendants ---")
    for _, obj in ipairs(gunTool:GetDescendants()) do
        ln(obj.ClassName .. " | " .. obj.Name .. " | parent: " .. obj.Parent.Name)
    end

    -- Tenta decompile do GunClient
    local gc = gunTool:FindFirstChild("GunClient")
        or gunTool:FindFirstChildWhichIsA("LocalScript")
    if gc then
        ln("--- GunClient: " .. gc.ClassName .. " / " .. gc.Name .. " ---")
        if decompile then
            pcall(function()
                local src = decompile(gc)
                if src and #src > 0 then
                    -- Pega só as primeiras 80 linhas pra não explodir a GUI
                    local i = 0
                    for line in src:gmatch("[^\n]+") do
                        i = i + 1
                        ln(line)
                        if i >= 150 then ln("... (truncado)"); break end
                    end
                end
            end)
        else
            ln("(decompile nao disponivel neste executor)")
        end
    else
        ln("GunClient nao encontrado")
    end

    -- Hook temporário — captura args do próximo tiro real
    -- Usa uma flag global pra se encaixar no hook __namecall já existente
    ln("")
    ln("=== aguardando tiro... ===")
    local resultText = table.concat(lines, "\n")
    showDumpGui(resultText .. "\n\n[Atire uma vez pra capturar os args do FireServer]")

    -- Flag global lida pelo hook __namecall principal
    _dumpCapturing = true
    _dumpCallback = function(remoteName, toolName, args)
        _dumpCapturing = false
        _dumpCallback = nil
        local capLines = {}
        table.insert(capLines, "=== FireServer CAPTURADO ===")
        table.insert(capLines, "Remote: " .. remoteName .. " | Tool: " .. toolName)
        table.insert(capLines, "Qtd args: " .. #args)
        for i, v in ipairs(args) do
            table.insert(capLines, "arg["..i.."] = "..typeof(v).." -> "..tostring(v))
        end
        table.insert(capLines, "=== FIM ===")
        local full = resultText .. "\n\n" .. table.concat(capLines, "\n")
        task.defer(function() showDumpGui(full) end)
    end

    -- Timeout de 30s
    task.delay(30, function()
        if _dumpCapturing then
            _dumpCapturing = false
            _dumpCallback = nil
        end
    end)

    ui:Toast("rbxassetid://131165537896572","[Dump]","atire uma vez — GUI vai atualizar",ROLE_COLOR.sheriff)
end)

-- ── HITBOX EXPANDER ──────────────────────────────────────────────────────────
secSheriff:Divider("hitbox expander — expande todas as parts do character")

local t_hb = secSheriff:Toggle("hitbox expander", false, function(v)
    hitboxOn = v
    if v then
        startHitbox()
        ui:Toast("rbxassetid://131165537896572","[Hitbox]",
            "ativo — "..hitboxSize.."x scale em todas as parts",ROLE_COLOR.sheriff)
    else
        stopHitbox()
        ui:Toast("rbxassetid://131165537896572","[Hitbox]","desativado + restaurado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_hitbox", function() return hitboxOn end, function(v) t_hb.Set(v) end)

local s_hbsize = secSheriff:Slider("tamanho hitbox (studs max)", 4, 40, 12, function(v)
    hitboxSize = v
end)
ui:CfgRegister("mm2_hitboxsize", function() return hitboxSize end, function(v) s_hbsize.Set(v) end)

local t_hbvis = secSheriff:Toggle("mostrar hitbox (debug)", false, function(v)
    hitboxVisible = v
    applyHitboxVisibility(v)  -- aplica imediatamente nas parts já expandidas
end)
ui:CfgRegister("mm2_hitboxvis", function() return hitboxVisible end, function(v) t_hbvis.Set(v) end)

-- ── SHOOT BUTTON ─────────────────────────────────────────────────────────────
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
        if getRole() ~= "sheriff" and getRole() ~= "hero" then
            setBtnState("SEM GUN", T.err)
            task.delay(1.2, function() setBtnState("ATIRAR", ROLE_COLOR.sheriff) end); return
        end
        local m = findByRole("murderer")
        if not m then
            setBtnState("?", Color3.fromRGB(195, 160, 38))
            task.delay(1.2, function() setBtnState("ATIRAR", ROLE_COLOR.sheriff) end); return
        end
        shootCd = true
        setBtnState("...", Color3.fromRGB(80,80,80))
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

-- ── GUN AURA ─────────────────────────────────────────────────────────────────
secSheriff:Divider("gun aura")
local gunAuraOn   = false
local gunAuraDist = 18
local lastGunAura = 0
local gunAuraCD   = 0.8

local function gunAuraLoop()
    while gunAuraOn do
        task.wait(0.1)
        if getRole() ~= "sheriff" and getRole() ~= "hero" then continue end
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
        hrp.CFrame = CFrame.lookAt(hrp.Position, mHRP.Position)
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

-- ── AUTO SHOOT ───────────────────────────────────────────────────────────────
secSheriff:Divider("auto shoot (range livre)")
local autoShootOn=false; local lastShot=0; local shotCD=0.6

local function autoShootLoop()
    while autoShootOn do
        task.wait(0.15)
        if getRole()~="sheriff" and getRole()~="hero" then continue end
        if tick()-lastShot<shotCD then continue end
        local m=findByRole("murderer"); if not m then continue end
        local mHrp=m.Character and m.Character:FindFirstChild("HumanoidRootPart")
        local hrp=myHRP()
        if not mHrp or not hrp then continue end
        if (hrp.Position-mHrp.Position).Magnitude>300 then continue end
        lastShot=tick()
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
    if getRole()~="sheriff" and getRole()~="hero" then
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
    local mh=m.Character and m.Character:FindFirstChild("HumanoidRootPart"); local hrp=myHRP()
    if mh and hrp then hrp.CFrame=mh.CFrame*CFrame.new(0,0,-4)
        ui:Toast("rbxassetid://131165537896572","[TP]","-> "..m.DisplayName,ROLE_COLOR.murderer) end
end)

-- ── MURDERER ─────────────────────────────────────────────────────────────────
local secMurd=tabCombat:Section("murderer")

secMurd:Divider("knife aura (auto swing)")
local knifeAura=false; local knifeRange=12; local knifeCd=0.35
local _knifeAuraConn = nil

local function knifeAuraLoop()
    if _knifeAuraConn then _knifeAuraConn:Disconnect(); _knifeAuraConn = nil end
    task.spawn(function()
        local bp = player:FindFirstChild("Backpack"); if not bp then return end
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if not hum then return end
        for name in pairs(KNIFE_NAMES) do
            local t = bp:FindFirstChild(name)
            if t then hum:EquipTool(t); break end
        end
    end)
    local accum      = 0
    local cachedRole = "unknown"
    local roleTimer  = 0
    local playerHRPs = {}
    _knifeAuraConn = RunService.Heartbeat:Connect(function(dt)
        if not knifeAura then
            _knifeAuraConn:Disconnect(); _knifeAuraConn = nil; return
        end
        accum     = accum + dt
        roleTimer = roleTimer + dt
        if roleTimer >= 0.5 then
            roleTimer  = 0
            cachedRole = getRole()
            playerHRPs = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and isAlive(p) then
                    local ph = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if ph then playerHRPs[p] = ph end
                end
            end
        end
        if accum < knifeCd then return end
        accum = 0
        if cachedRole ~= "murderer" then return end
        local hrp   = myHRP(); if not hrp then return end
        local knife = getKnifeTool(); if not knife then return end
        local hrpPos = hrp.Position
        local best, bestD = nil, knifeRange
        for p, ph in pairs(playerHRPs) do
            if not ph.Parent then playerHRPs[p] = nil; continue end
            local d = (hrpPos - ph.Position).Magnitude
            if d < bestD then best = ph; bestD = d end
        end
        if best then
            local lookCF = CFrame.lookAt(hrpPos, best.Position)
            if math.abs(hrp.CFrame.LookVector:Dot(lookCF.LookVector) - 1) > 0.01 then
                hrp.CFrame = lookCF
            end
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

local secFarm=tabFarm:Section("coin farm")
local farmOn=false; local farmCount=0

local function collectCoinsLoop()
    farmCount=0
    while farmOn do
        if not isRoundActive() then task.wait(3); continue end
        local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not myHRP() or not hum or hum.Health<=0 then task.wait(2); continue end
        local coins = findAllCoinServers()
        if #coins==0 then task.wait(3); continue end
        local myPos = myHRP() and myHRP().Position or Vector3.zero
        table.sort(coins, function(a,b)
            if not(a and a.Parent) then return false end
            if not(b and b.Parent) then return true end
            return (a.Position-myPos).Magnitude < (b.Position-myPos).Magnitude
        end)
        for _, coinPart in ipairs(coins) do
            if not farmOn then break end
            if not coinPart or not coinPart.Parent then continue end
            if not myHRP() then break end
            collectCoin(coinPart)
            farmCount=farmCount+1
        end
        task.wait(2)
    end
end

local t_farm=secFarm:Toggle("auto farm coins", false, function(v)
    farmOn=v
    if v then
        task.spawn(collectCoinsLoop)
        ui:Toast("rbxassetid://131165537896572","[Farm] iniciado","velocidade: "..FARM_FLY_SPEED.." studs/s",Color3.fromRGB(255,210,50))
    else
        ui:Toast("rbxassetid://131165537896572","[Farm] parado","coletadas: "..farmCount,Color3.fromRGB(255,210,50))
    end
end)
ui:CfgRegister("mm2_farm", function() return farmOn end, function(v) t_farm.Set(v) end)

local s_fspd=secFarm:Slider("velocidade (studs/s)", 4, 40, 16, function(v) FARM_FLY_SPEED=v end)
ui:CfgRegister("mm2_farm_speed", function() return FARM_FLY_SPEED end, function(v) s_fspd.Set(v) end)

local s_fpause=secFarm:Slider("pausa entre coins (x0.1s)", 2, 30, 8, function(v) farmPauseBetween = v / 10 end)
ui:CfgRegister("mm2_farm_pause", function() return farmPauseBetween*10 end, function(v) s_fpause.Set(v) end)

secFarm:Button("status do farm", function()
    local coins = findAllCoinServers()
    ui:Toast("rbxassetid://131165537896572",
        farmOn and "[Farm] rodando" or "[Farm] parado",
        "no mapa: "..#coins.."  coletadas: "..farmCount, Color3.fromRGB(255,210,50))
end)

secFarm:Button("collect coins (1x)", function()
    if not myHRP() then return end
    local coins = findAllCoinServers()
    if #coins==0 then
        ui:Toast("rbxassetid://131165537896572","coins","nenhuma coin encontrada no mapa",ROLE_COLOR.unknown); return
    end
    ui:Toast("rbxassetid://131165537896572","[Coins]","coletando "..#coins.."...",Color3.fromRGB(255,210,50))
    task.spawn(function()
        local myPos = myHRP() and myHRP().Position or Vector3.zero
        table.sort(coins, function(a,b)
            if not(a and a.Parent) then return false end
            if not(b and b.Parent) then return true end
            return (a.Position-myPos).Magnitude < (b.Position-myPos).Magnitude
        end)
        local count=0
        for _, coinPart in ipairs(coins) do
            if not coinPart or not coinPart.Parent then continue end
            collectCoin(coinPart); count=count+1
        end
        ui:Toast("rbxassetid://131165537896572","[Coins] feito!","coletadas: "..count,Color3.fromRGB(255,210,50))
    end)
end)

local secGrab=tabFarm:Section("gun grab (inocente)")
local grabOn=false

local function grabLoop()
    while grabOn do
        task.wait(0.6)
        if not isRoundActive() then continue end
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
        "mm2 v9.3  ["..ROLE_LABEL[role].."]",
        "bem-vindo, "..player.DisplayName, ROLE_COLOR[role])
end)
