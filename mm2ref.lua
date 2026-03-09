-- ══════════════════════════════════════════════════════════════════════════════
-- MM2 v17 — SILENT AIM REESCRITO + ESP SEM HP + SHOOT BUTTON FIXADO
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

local ui = RefLib.new("mm2 v17", "rbxassetid://131165537896572", "ref_mm2v17")

-- ══════════════════════════════════════════════════════════════════════════════
-- REMOTES
-- ══════════════════════════════════════════════════════════════════════════════

local GetCoinEvent
pcall(function() GetCoinEvent = ReplicatedStorage.Remotes.Gameplay.GetCoin end)

local PlayerDataChangedBind
pcall(function()
    PlayerDataChangedBind = ReplicatedStorage
        :WaitForChild("Modules", 5)
        :WaitForChild("CurrentRoundClient", 5)
        :WaitForChild("PlayerDataChanged", 5)
end)

local RoleSelectEvent
pcall(function() RoleSelectEvent = ReplicatedStorage.Remotes.Gameplay.RoleSelect end)

-- ══════════════════════════════════════════════════════════════════════════════
-- CONSTANTES
-- ══════════════════════════════════════════════════════════════════════════════

local KNIFE_NAMES   = { Knife = true }
local GUN_NAMES     = { Gun = true, ["Sheriff's Gun"] = true, Revolver = true, SheriffGun = true, GunDrop = true }
local GUNDROP_NAMES = { GunDrop = true }

local CHARACTER_HIT_PARTS = {
    "HumanoidRootPart", "UpperTorso", "LowerTorso", "Head",
    "RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg",
    "RightLowerArm", "LeftLowerArm", "RightLowerLeg", "LeftLowerLeg",
    "RightHand", "LeftHand", "RightFoot", "LeftFoot",
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
-- CACHE
-- ══════════════════════════════════════════════════════════════════════════════

local playerDataCache = {}
local roleCache       = {}

if PlayerDataChangedBind then
    PlayerDataChangedBind.Event:Connect(function(data)
        if type(data) ~= "table" then return end
        for username, info in pairs(data) do playerDataCache[username] = info end
    end)
end

local function hookUpdateData(evName)
    pcall(function()
        local ev = ReplicatedStorage:FindFirstChild(evName)
        if ev and ev:IsA("RemoteEvent") then
            ev.OnClientEvent:Connect(function(data)
                if type(data) ~= "table" then return end
                for username, info in pairs(data) do
                    if type(info) == "table" then playerDataCache[username] = info end
                end
            end)
        end
    end)
end
hookUpdateData("UpdateData")
hookUpdateData("UpdateData2")
hookUpdateData("UpdateData3")

pcall(function()
    ReplicatedStorage.Remotes.Gameplay.RoundStart.OnClientEvent:Connect(function()
        playerDataCache = {}; roleCache = {}
    end)
end)

pcall(function()
    ReplicatedStorage.Remotes.Gameplay.GiveWeapon.OnClientEvent:Connect(function(weaponArg)
        local name = ""
        if type(weaponArg) == "string" then name = weaponArg:lower()
        elseif typeof(weaponArg) == "Instance" then name = weaponArg.Name:lower() end
        if name:find("knife") then roleCache[player] = "murderer"
        elseif name:find("gun") or name:find("sheriff") or name:find("revolver") then roleCache[player] = "sheriff" end
    end)
end)

pcall(function()
    ReplicatedStorage.Remotes.Gameplay.PlayerDataChanged.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        for username, info in pairs(data) do
            if type(info) == "table" then
                playerDataCache[username] = info
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

pcall(function()
    ReplicatedStorage.Remotes.Gameplay.ShowRoleSelectNew.OnClientEvent:Connect(function()
        task.wait(0.5)
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
    playerDataCache = {}; roleCache[player] = nil
    local bp = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
    if bp then bp.ChildAdded:Connect(function(child)
        if KNIFE_NAMES[child.Name] then roleCache[player] = "murderer"
        elseif GUNDROP_NAMES[child.Name] then roleCache[player] = "hero"
        elseif GUN_NAMES[child.Name] then roleCache[player] = "sheriff" end
    end) end
end)

local function watchPlayerBackpack(p)
    if p == player then return end
    local function onChildAdded(child)
        if KNIFE_NAMES[child.Name] then roleCache[p] = "murderer"
        elseif GUNDROP_NAMES[child.Name] then roleCache[p] = "hero"
        elseif child.Name == "Gun" or child.Name == "Sheriff's Gun"
            or child.Name == "Revolver" or child.Name == "SheriffGun" then
            roleCache[p] = "sheriff" end
    end
    local bp = p:FindFirstChild("Backpack")
    if bp  then bp.ChildAdded:Connect(onChildAdded) end
    local chr = p.Character
    if chr then chr.ChildAdded:Connect(onChildAdded) end
end

local function watchPlayerFull(p)
    watchPlayerBackpack(p)
    p.CharacterAdded:Connect(function()
        roleCache[p] = nil; task.wait(0.3); watchPlayerBackpack(p)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= player then watchPlayerFull(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= player then watchPlayerFull(p) end end)

-- Detecta GunDrop pickup
workspace.DescendantRemoving:Connect(function(obj)
    if not GUNDROP_NAMES[obj.Name] then return end
    task.wait(0.15)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == player then continue end
        local bp  = p:FindFirstChild("Backpack")
        local chr = p.Character
        for n in pairs(GUN_NAMES) do
            if (bp  and bp:FindFirstChild(n))
            or (chr and chr:FindFirstChild(n)) then
                if roleCache[p] ~= "murderer" then roleCache[p] = "hero" end
                break
            end
        end
    end
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

local function isRoundActive()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" then return true end
    end
    local rtp = workspace:FindFirstChild("RoundTimerPart")
    if rtp and #rtp:GetChildren() > 0 then return true end
    return false
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TOOL HELPERS
-- ══════════════════════════════════════════════════════════════════════════════

local function getGunTool()
    local bp  = player:FindFirstChild("Backpack")
    local chr = player.Character
    for name in pairs(GUN_NAMES) do
        if chr then local t = chr:FindFirstChild(name); if t then return t end end
        if bp  then local t = bp:FindFirstChild(name);  if t then return t end end
    end
    return nil
end

local function getKnifeTool()
    local bp  = player:FindFirstChild("Backpack")
    local chr = player.Character
    for name in pairs(KNIFE_NAMES) do
        if chr and chr:FindFirstChild(name) then return chr:FindFirstChild(name) end
        if bp  and bp:FindFirstChild(name)  then return bp:FindFirstChild(name)  end
    end
    return nil
end

local function equipTool(tool)
    local chr = player.Character; if not chr then return false end
    local hum = chr:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    pcall(function() hum:EquipTool(tool) end)
    task.wait(0.12)
    return chr:FindFirstChild(tool.Name) ~= nil
end

local function ensureEquipped(tool)
    if not tool then return nil end
    local chr = player.Character; if not chr then return nil end
    if chr:FindFirstChild(tool.Name) then return tool end
    equipTool(tool)
    chr = player.Character; if not chr then return nil end
    return chr:FindFirstChild(tool.Name)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SILENT AIM — REESCRITO COMPLETAMENTE
-- ══════════════════════════════════════════════════════════════════════════════
-- 
-- Estratégia em CAMADAS (as duas funcionam em paralelo):
--
-- CAMADA 1 — Hook __namecall
--   Intercepta QUALQUER FireServer de RemoteEvent que seja filho de uma Gun tool.
--   Substitui o 2º argumento (posição/CFrame do alvo) pelo head do murderer.
--   Isso cobre PC (MouseLock) e Mobile (TouchTap processado pelo GunClient).
--
-- CAMADA 2 — FireServer direto no Remote interno da gun
--   Quando o jogador aperta o shoot button (ou a função fireSilentShot é chamada),
--   buscamos o RemoteEvent "Shoot" dentro da gun equipada e chamamos FireServer
--   diretamente com os args corretos. Isso garante que o tiro SAI mesmo se o
--   GunClient bloquear o Activate() no mobile.
--
-- PREDIÇÃO DE POSIÇÃO
--   Em vez de usar somente a posição atual, adicionamos um offset de velocidade
--   estimada do alvo (velocity * 0.12s lookahead) pra compensar o lag de rede.
-- ══════════════════════════════════════════════════════════════════════════════

local silentAimOn      = false
local silentAimTarget  = nil  -- forçar alvo específico (nil = auto)
local _namecallHooked  = false
local _lastShotTime    = 0

-- Cache de posição anterior do alvo pra calcular velocidade
local _prevTargetPos   = {}
local _prevTargetTime  = {}

local function getPredictedPos(targetPlayer)
    if not targetPlayer then return nil end
    local chr = targetPlayer.Character; if not chr then return nil end
    local head = chr:FindFirstChild("Head")
    local hrp  = chr:FindFirstChild("HumanoidRootPart")
    local part = head or hrp
    if not part then return nil end

    local now     = tick()
    local curPos  = part.Position
    local prevPos = _prevTargetPos[targetPlayer]
    local prevT   = _prevTargetTime[targetPlayer]

    local predicted = curPos
    if prevPos and prevT and (now - prevT) > 0.01 and (now - prevT) < 0.5 then
        local vel     = (curPos - prevPos) / (now - prevT)
        local lookahead = 0.12  -- segundos de predição
        predicted = curPos + vel * lookahead
    end

    _prevTargetPos[targetPlayer]  = curPos
    _prevTargetTime[targetPlayer] = now

    return predicted
end

local function getSilentTarget()
    -- Alvo manual tem prioridade
    if silentAimTarget and silentAimTarget.Parent and isAlive(silentAimTarget) then
        return silentAimTarget
    end
    -- Auto: se for sheriff/hero → mira no murderer
    local myRole = getRole()
    if myRole == "sheriff" or myRole == "hero" then
        return findByRole("murderer")
    end
    -- Murderer: mira no mais próximo
    if myRole == "murderer" then
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

-- Busca TODOS os RemoteEvents dentro de uma gun tool (pode ter mais de um)
local function getGunRemotes(tool)
    if not tool then return {} end
    local remotes = {}
    -- Prioriza "Shoot" pelo nome
    local shootRE = tool:FindFirstChild("Shoot")
    if shootRE and shootRE:IsA("RemoteEvent") then
        table.insert(remotes, shootRE)
    end
    -- Coleta todos os outros RemoteEvents como fallback
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("RemoteEvent") and obj ~= shootRE then
            table.insert(remotes, obj)
        end
    end
    return remotes
end

-- Dispara o tiro diretamente via FireServer no Remote da gun
-- Esta é a abordagem mais confiável pra mobile
local function fireDirectShot()
    local target = getSilentTarget()
    if not target then return false end

    local hitPos = getPredictedPos(target)
    if not hitPos then return false end

    -- Tenta pegar a gun equipada primeiro, senão equipa do backpack
    local gunTool = getGunTool()
    if not gunTool then return false end

    -- Garante que está equipada no character
    local chr = player.Character
    if chr and not chr:FindFirstChild(gunTool.Name) then
        local equipped = ensureEquipped(gunTool)
        if not equipped then
            -- Fallback: pega do backpack de novo depois de equipar
            gunTool = getGunTool()
            if not gunTool then return false end
        end
    end

    -- Aponta HRP pro alvo (ajuda o raycast do servidor)
    local hrp = myHRP()
    if hrp then
        pcall(function()
            hrp.CFrame = CFrame.lookAt(hrp.Position, hitPos)
        end)
        task.wait(0.02)
    end

    -- Tenta Activate() primeiro (PC/Gamepad)
    if chr and chr:FindFirstChild(gunTool.Name) then
        pcall(function() gunTool:Activate() end)
        -- O hook __namecall vai redirecionar o FireServer resultante
        return true
    end

    -- Fallback Mobile: FireServer direto nos remotes da gun
    local remotes = getGunRemotes(gunTool)
    if #remotes > 0 then
        local targetHead = target.Character and (
            target.Character:FindFirstChild("Head") or
            target.Character:FindFirstChild("HumanoidRootPart")
        )
        -- Tenta diferentes assinaturas conhecidas do GunClient
        for _, re in ipairs(remotes) do
            pcall(function()
                -- Assinatura 1: FireServer(attachCF, targetCFrame) — PC MouseLock
                re:FireServer(nil, CFrame.new(hitPos))
            end)
            task.wait(0.03)
            pcall(function()
                -- Assinatura 2: FireServer(attachCF, targetPos) — Mobile
                re:FireServer(nil, hitPos)
            end)
            task.wait(0.03)
            if targetHead then
                pcall(function()
                    -- Assinatura 3: FireServer(targetPos, targetInstance)
                    re:FireServer(hitPos, targetHead)
                end)
            end
            break  -- só precisa do primeiro (Shoot)
        end
        return true
    end

    return false
end

-- Hook principal de __namecall
-- Intercepta qualquer FireServer de RemoteEvent dentro de uma gun
-- e substitui os argumentos de posição pelo alvo do silent aim
local function hookSilentAim()
    if _namecallHooked then return end
    _namecallHooked = true

    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    pcall(function() setreadonly(mt, false) end)

    mt.__namecall = newcclosure(function(self, ...)
        if self == nil then return old_namecall(self, ...) end

        local method = getnamecallmethod()

        -- Só nos interessa FireServer
        if method ~= "FireServer" then
            return old_namecall(self, ...)
        end

        -- Verifica se é um RemoteEvent filho de uma gun
        local ok, isRE = pcall(function() return self:IsA("RemoteEvent") end)
        if not (ok and isRE) then return old_namecall(self, ...) end

        if not silentAimOn then return old_namecall(self, ...) end

        -- Verifica se o pai (ou avô) é uma gun tool
        local parent = self.Parent
        local isGunRemote = false
        if parent then
            local parOk, parIsTool = pcall(function() return parent:IsA("Tool") end)
            if parOk and parIsTool and GUN_NAMES[parent.Name] then
                isGunRemote = true
            end
            -- Também verifica 2 níveis acima (remote dentro de ModuleScript dentro da tool)
            if not isGunRemote then
                local gp = parent.Parent
                if gp then
                    local gpOk, gpIsTool = pcall(function() return gp:IsA("Tool") end)
                    if gpOk and gpIsTool and GUN_NAMES[gp.Name] then
                        isGunRemote = true
                    end
                end
            end
        end

        if not isGunRemote then return old_namecall(self, ...) end

        -- É um tiro! Redireciona pro alvo.
        local target = getSilentTarget()
        local hitPos = target and getPredictedPos(target)

        if not hitPos then return old_namecall(self, ...) end

        local args = {...}

        -- Detecta o tipo dos argumentos originais e substitui o de posição
        -- arg1 pode ser nil (attachment CFrame) ou Vector3/CFrame
        -- arg2 é a posição/CFrame do alvo — É ESTE que substituímos
        local newArgs = {}

        if #args == 0 then
            -- Sem args — manda posição direto
            return old_namecall(self, CFrame.new(hitPos))
        elseif #args == 1 then
            -- Um arg — pode ser a posição
            if typeof(args[1]) == "CFrame" then
                newArgs = { CFrame.new(hitPos) }
            elseif typeof(args[1]) == "Vector3" then
                newArgs = { hitPos }
            else
                -- Tipo desconhecido, preserva arg1 e adiciona posição
                newArgs = { args[1], hitPos }
            end
        elseif #args >= 2 then
            -- Dois+ args: preserva arg1, substitui arg2 pela posição do alvo
            newArgs[1] = args[1]  -- attachment CFrame (pode ser nil)
            if typeof(args[2]) == "CFrame" then
                newArgs[2] = CFrame.new(hitPos)
            else
                newArgs[2] = hitPos
            end
            -- Preserva args restantes
            for i = 3, #args do newArgs[i] = args[i] end
        end

        return old_namecall(self, table.unpack(newArgs))
    end)
end

-- Hook de GetMouseTargetCFrame e GetTargetPosition pra cobrir o caminho
-- do GunClient antes do FireServer (alguns executores não pegam o __namecall cedo)
local _indexHooked = false
local function hookGunClientMethods()
    if _indexHooked then return end
    _indexHooked = true

    -- Hook no UserInputService pra enganar o GunClient a usar o caminho de PC no mobile
    local uisMt = getrawmetatable(UserInputService)
    pcall(function() setreadonly(uisMt, false) end)
    local oldUisIndex = uisMt.__index

    uisMt.__index = newcclosure(function(self, key)
        -- Faz o GunClient achar que está no PC/Gamepad, não no mobile
        -- Isso faz ele usar GetMouseTargetCFrame em vez de GetTargetPosition(x,y)
        if silentAimOn then
            if key == "TouchEnabled"    then return false end
            if key == "KeyboardEnabled" then return true  end
            if key == "PreferredInput"  then return Enum.PreferredInput.Gamepad end
        end
        return oldUisIndex(self, key)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- KNIFE HELPERS
-- ══════════════════════════════════════════════════════════════════════════════

local function knifeAt(targetChar)
    if not targetChar then return false end
    local hrp  = myHRP(); if not hrp then return false end
    local tHRP = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
    if not tHRP then return false end
    local knife = getKnifeTool()
    if not knife then
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for name in pairs(KNIFE_NAMES) do
                local t = bp:FindFirstChild(name)
                if t then equipTool(t); knife = getKnifeTool(); break end
            end
        end
    end
    if not knife then return false end
    hrp.CFrame = CFrame.lookAt(hrp.Position, tHRP.Position)
    task.wait(0.03)
    pcall(function() knife:Activate() end)
    return true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- HITBOX EXPANDER
-- ══════════════════════════════════════════════════════════════════════════════

local hitboxOn      = false
local hitboxSize    = 12
local hitboxVisible = false
local hitboxCache   = {}

local function getMyParts()
    local chr = player.Character; if not chr then return {} end
    local parts = {}
    for _, p in ipairs(chr:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(parts, p) end
    end
    return parts
end

local function noCollide(partA, partB)
    local nc = Instance.new("NoCollisionConstraint")
    nc.Part0 = partA; nc.Part1 = partB; nc.Parent = partA
    return nc
end

local function applyHitboxToChar(p)
    if not p or p == player then return end
    local chr = p.Character; if not chr then return end
    if hitboxCache[p] then return end
    local myParts = getMyParts(); local saved = {}
    for _, part in ipairs(chr:GetDescendants()) do
        if not part:IsA("BasePart") then continue end
        if part.Parent:IsA("Accessory") then continue end
        if part.Parent:IsA("Tool") then continue end
        local origSize = part.Size; local origTransp = part.Transparency
        local maxDim = math.max(origSize.X, origSize.Y, origSize.Z, 0.1)
        local scale  = hitboxSize / maxDim; local constraints = {}
        if scale > 1 then pcall(function() part.Size = origSize * scale end) end
        if hitboxVisible then pcall(function() part.Transparency = 0.5 end) end
        for _, myPart in ipairs(myParts) do
            pcall(function() table.insert(constraints, noCollide(part, myPart)) end)
        end
        table.insert(saved, { part = part, size = origSize, transp = origTransp, constraints = constraints })
    end
    hitboxCache[p] = saved
end

local function restoreHitboxOfPlayer(p)
    local saved = hitboxCache[p]; if not saved then return end
    for _, data in ipairs(saved) do
        if data.part and data.part.Parent then
            pcall(function() data.part.Size = data.size; data.part.Transparency = data.transp end)
        end
        for _, nc in ipairs(data.constraints) do
            pcall(function() if nc and nc.Parent then nc:Destroy() end end)
        end
    end
    hitboxCache[p] = nil
end

local function restoreAllHitboxes()
    local players = {}
    for p in pairs(hitboxCache) do table.insert(players, p) end
    for _, p in ipairs(players) do restoreHitboxOfPlayer(p) end
    hitboxCache = {}
end

local function applyHitboxVisibility(visible)
    for _, saved in pairs(hitboxCache) do
        for _, data in ipairs(saved) do
            if data.part and data.part.Parent then
                pcall(function() data.part.Transparency = visible and 0.5 or data.transp end)
            end
        end
    end
end

local function startHitbox()
    for _, p in ipairs(Players:GetPlayers()) do applyHitboxToChar(p) end
end

local function stopHitbox()
    hitboxOn = false; restoreAllHitboxes()
end

player.CharacterAdded:Connect(function()
    if not hitboxOn then return end
    task.wait(1)
    for p, saved in pairs(hitboxCache) do
        for _, data in ipairs(saved) do
            for _, nc in ipairs(data.constraints) do pcall(function() nc:Destroy() end) end
            data.constraints = {}
        end
        hitboxCache[p] = nil
    end
    for _, p in ipairs(Players:GetPlayers()) do applyHitboxToChar(p) end
end)

Players.PlayerRemoving:Connect(function(p) hitboxCache[p] = nil end)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        hitboxCache[p] = nil
        if hitboxOn then task.wait(1); applyHitboxToChar(p) end
    end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then p.CharacterAdded:Connect(function()
        hitboxCache[p] = nil
        if hitboxOn then task.wait(1); applyHitboxToChar(p) end
    end) end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- GUN / COIN FINDERS
-- ══════════════════════════════════════════════════════════════════════════════

local function findDroppedGuns()
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if GUNDROP_NAMES[obj.Name] and obj:IsA("BasePart") then
            table.insert(found, { tool = obj, handle = obj })
        end
    end
    return found
end

local function findAllCoinServers()
    local coins = {}; local seen = {}
    local COIN_NAMES = { Coin_Server=true, Coin=true, CoinPart=true, MainCoin=true, CoinValue=true }
    for _, obj in ipairs(workspace:GetDescendants()) do
        if COIN_NAMES[obj.Name] and obj:IsA("BasePart") and not seen[obj] then
            if isValidPos(obj.Position) then seen[obj]=true; table.insert(coins, obj) end
        end
    end
    return coins
end

-- ══════════════════════════════════════════════════════════════════════════════
-- COIN FARM
-- ══════════════════════════════════════════════════════════════════════════════

local FARM_FLY_SPEED   = 16
local farmPauseBetween = 0.8

local function flyTo(destination)
    local hrp = myHRP(); if not hrp then return end
    local chr = player.Character; if not chr then return end
    for _, p in ipairs(chr:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
    end
    local startPos = hrp.Position
    local dist = (destination - startPos).Magnitude
    if dist < 0.5 then return end
    local steps = math.max(3, math.ceil(dist)); local stepTime = 1 / FARM_FLY_SPEED
    for i = 1, steps do
        hrp = myHRP(); if not hrp then return end
        hrp.CFrame = CFrame.new(startPos:Lerp(destination, i / steps))
        task.wait(stepTime)
    end
    hrp = myHRP(); if hrp then hrp.CFrame = CFrame.new(destination) end
end

local function collectCoin(coinServer)
    if not coinServer or not coinServer.Parent then return end
    flyTo(coinServer.Position)
    local hrp = myHRP()
    if hrp and coinServer.Parent then
        hrp.CFrame = CFrame.new(coinServer.Position + Vector3.new(0.3, 0, 0))
        task.wait(0.05)
        hrp = myHRP()
        if hrp and coinServer.Parent then hrp.CFrame = CFrame.new(coinServer.Position) end
    end
    if GetCoinEvent then pcall(function() GetCoinEvent:FireServer() end) end
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
local roleEspOn = false; local roleEspCache = {}

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
    bb.Size=UDim2.new(0,130,0,30); bb.StudsOffset=Vector3.new(0,3.2,0)
    bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Adornee=hrp; bb.Parent=hrp
    local nm = Instance.new("TextLabel")
    nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,20)
    nm.Font=Enum.Font.GothamBold; nm.TextSize=13; nm.TextColor3=Color3.new(1,1,1)
    nm.TextStrokeTransparency=0.12; nm.TextXAlignment=Enum.TextXAlignment.Center
    nm.Text=p.DisplayName; nm.Parent=bb
    local rl = Instance.new("TextLabel")
    rl.BackgroundTransparency=1; rl.Size=UDim2.new(1,0,0,14); rl.Position=UDim2.new(0,0,0,18)
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
-- TAB: ESP — SEM BARRA DE HP
-- ══════════════════════════════════════════════════════════════════════════════
do

local secESP = tabESP:Section("player esp")
local espOn = false; local espMax = 300; local espCache = {}

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
    -- Highlight
    local hl=Instance.new("Highlight"); hl.FillColor=col; hl.OutlineColor=Color3.new(1,1,1)
    hl.FillTransparency=0.45; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee=chr; hl.Parent=chr
    -- BillboardGui: nome + papel + distância (sem HP bar)
    local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,130,0,46)
    bb.StudsOffset=Vector3.new(0,3.5,0); bb.AlwaysOnTop=true; bb.ResetOnSpawn=false
    bb.Adornee=hrp; bb.Parent=hrp
    local nm=Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,18)
    nm.Font=Enum.Font.GothamBold; nm.TextSize=13; nm.TextColor3=Color3.new(1,1,1)
    nm.TextStrokeTransparency=0.12; nm.TextXAlignment=Enum.TextXAlignment.Center
    nm.Text=p.DisplayName; nm.Parent=bb
    local rl=Instance.new("TextLabel"); rl.BackgroundTransparency=1; rl.Size=UDim2.new(1,0,0,14)
    rl.Position=UDim2.new(0,0,0,20); rl.Font=Enum.Font.GothamSemibold; rl.TextSize=11
    rl.TextColor3=col; rl.TextXAlignment=Enum.TextXAlignment.Center
    rl.Text="["..ROLE_LABEL[role].."]"; rl.Parent=bb
    local dl=Instance.new("TextLabel"); dl.BackgroundTransparency=1; dl.Size=UDim2.new(1,0,0,12)
    dl.Position=UDim2.new(0,0,0,34); dl.Font=Enum.Font.Gotham; dl.TextSize=10
    dl.TextColor3=Color3.fromRGB(200,200,220); dl.TextXAlignment=Enum.TextXAlignment.Center; dl.Parent=bb
    espCache[p]={hl=hl,bb=bb,nm=nm,rl=rl,dl=dl}
end

RunService.RenderStepped:Connect(function()
    if not espOn then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p==player then continue end
        local chr=p.Character; local hrp=chr and chr:FindFirstChild("HumanoidRootPart")
        local hum=chr and chr:FindFirstChildOfClass("Humanoid")
        if not chr or not hum or not hrp then removeESP(p); continue end
        if not isAlive(p) then removeESP(p); continue end
        local dist=math.floor((cam.CFrame.Position-hrp.Position).Magnitude)
        if dist>espMax then removeESP(p); continue end
        if not espCache[p] then buildESP(p) end
        local d=espCache[p]; if not d then continue end
        local role=getRole(p); local col=ROLE_COLOR[role] or ROLE_COLOR.unknown
        d.hl.FillColor=col; d.rl.TextColor3=col; d.rl.Text="["..ROLE_LABEL[role].."]"
        d.nm.Text=p.DisplayName; d.dl.Text=dist.."m"
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
    if GUNDROP_NAMES[obj.Name] and obj:IsA("BasePart") then makeItemBB(obj, obj) end
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
secSheriff:Divider("silent aim")

local t_sa = secSheriff:Toggle("silent aim (PC + Mobile)", false, function(v)
    silentAimOn = v
    if v then
        hookSilentAim()       -- hook __namecall (intercepta FireServer)
        hookGunClientMethods() -- hook UserInputService (engana o GunClient no mobile)
        ui:Toast("rbxassetid://131165537896572","[Silent Aim]",
            "ativo — toque/clique em qualquer lugar pra atirar",ROLE_COLOR.sheriff)
    else
        ui:Toast("rbxassetid://131165537896572","[Silent Aim]","desativado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_silentaim", function() return silentAimOn end, function(v) t_sa.Set(v) end)

-- ── HITBOX EXPANDER ──────────────────────────────────────────────────────────
secSheriff:Divider("hitbox expander")

local t_hb = secSheriff:Toggle("hitbox expander", false, function(v)
    hitboxOn = v
    if v then
        startHitbox()
        ui:Toast("rbxassetid://131165537896572","[Hitbox]",
            "ativo — "..hitboxSize.."x scale",ROLE_COLOR.sheriff)
    else
        stopHitbox()
        ui:Toast("rbxassetid://131165537896572","[Hitbox]","desativado + restaurado",ROLE_COLOR.unknown)
    end
end)
ui:CfgRegister("mm2_hitbox", function() return hitboxOn end, function(v) t_hb.Set(v) end)

local s_hbsize = secSheriff:Slider("tamanho hitbox (studs max)", 4, 40, 12, function(v) hitboxSize = v end)
ui:CfgRegister("mm2_hitboxsize", function() return hitboxSize end, function(v) s_hbsize.Set(v) end)

local t_hbvis = secSheriff:Toggle("mostrar hitbox (debug)", false, function(v)
    hitboxVisible = v; applyHitboxVisibility(v)
end)
ui:CfgRegister("mm2_hitboxvis", function() return hitboxVisible end, function(v) t_hbvis.Set(v) end)

-- ── SHOOT BUTTON (integrado ao silent aim) ───────────────────────────────────
-- O botão chama fireDirectShot() que:
--  1. Tenta Activate() na gun equipada → o hook __namecall redireciona o FireServer
--  2. Se falhar (mobile sem activate), FireServer direto no Remote "Shoot" da gun
secSheriff:Divider("shoot button (mobile + pc)")

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
    lbl.Text="SHERIFF / SILENT AIM"; lbl.Position=UDim2.new(0,0,0,4); lbl.Parent=card
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
        local myRole = getRole()
        if myRole ~= "sheriff" and myRole ~= "hero" then
            setBtnState("SEM GUN", T.err)
            task.delay(1.2, function() setBtnState("ATIRAR", ROLE_COLOR.sheriff) end); return
        end
        local gunTool = getGunTool()
        if not gunTool then
            setBtnState("SEM GUN", T.err)
            task.delay(1.2, function() setBtnState("ATIRAR", ROLE_COLOR.sheriff) end); return
        end
        local target = getSilentTarget()
        if not target then
            setBtnState("SEM ALVO", T.warn)
            task.delay(1.2, function() setBtnState("ATIRAR", ROLE_COLOR.sheriff) end); return
        end
        shootCd = true
        setBtnState("...", Color3.fromRGB(80,80,80))
        -- Garante silent aim ativo pra esse tiro
        local wasSilentAim = silentAimOn
        silentAimOn = true
        hookSilentAim()
        hookGunClientMethods()
        local ok = fireDirectShot()
        if not wasSilentAim then silentAimOn = false end
        setBtnState(ok and "FIRED!" or "FALHOU", ok and T.ok or T.err)
        task.wait(0.9)
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
        -- Usa silent aim pra atirar
        local wasSA = silentAimOn; silentAimOn = true
        hookSilentAim(); hookGunClientMethods()
        fireDirectShot()
        if not wasSA then silentAimOn = false end
    end
end

local t_ga = secSheriff:Toggle("gun aura (tp + silent aim + shoot)", false, function(v)
    gunAuraOn = v
    if v then
        task.spawn(gunAuraLoop)
        ui:Toast("rbxassetid://131165537896572","[Gun Aura]","ativo",ROLE_COLOR.sheriff)
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
secSheriff:Divider("auto shoot")
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
        local wasSA = silentAimOn; silentAimOn = true
        hookSilentAim(); hookGunClientMethods()
        fireDirectShot()
        if not wasSA then silentAimOn = false end
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
    local wasSA = silentAimOn; silentAimOn = true
    hookSilentAim(); hookGunClientMethods()
    local ok = fireDirectShot()
    if not wasSA then silentAimOn = false end
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
    local accum=0; local cachedRole="unknown"; local roleTimer=0; local playerHRPs={}
    _knifeAuraConn = RunService.Heartbeat:Connect(function(dt)
        if not knifeAura then _knifeAuraConn:Disconnect(); _knifeAuraConn=nil; return end
        accum=accum+dt; roleTimer=roleTimer+dt
        if roleTimer>=0.5 then
            roleTimer=0; cachedRole=getRole(); playerHRPs={}
            for _, p in ipairs(Players:GetPlayers()) do
                if p~=player and isAlive(p) then
                    local ph=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if ph then playerHRPs[p]=ph end
                end
            end
        end
        if accum<knifeCd then return end
        accum=0
        if cachedRole~="murderer" then return end
        local hrp=myHRP(); if not hrp then return end
        local knife=getKnifeTool(); if not knife then return end
        local hrpPos=hrp.Position; local best,bestD=nil,knifeRange
        for p,ph in pairs(playerHRPs) do
            if not ph.Parent then playerHRPs[p]=nil; continue end
            local d=(hrpPos-ph.Position).Magnitude
            if d<bestD then best=ph; bestD=d end
        end
        if best then
            local lookCF=CFrame.lookAt(hrpPos,best.Position)
            if math.abs(hrp.CFrame.LookVector:Dot(lookCF.LookVector)-1)>0.01 then
                hrp.CFrame=lookCF
            end
            pcall(function() knife:Activate() end)
        end
    end)
end

local t_ka=secMurd:Toggle("knife aura", false, function(v)
    knifeAura=v
    if v then knifeAuraLoop()
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
    local best,bestD=nil,math.huge
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
            collectCoin(coinPart); farmCount=farmCount+1
        end
        task.wait(2)
    end
end

local t_farm=secFarm:Toggle("auto farm coins", false, function(v)
    farmOn=v
    if v then task.spawn(collectCoinsLoop)
        ui:Toast("rbxassetid://131165537896572","[Farm] iniciado","vel: "..FARM_FLY_SPEED.."s/s",Color3.fromRGB(255,210,50))
    else ui:Toast("rbxassetid://131165537896572","[Farm] parado","coletadas: "..farmCount,Color3.fromRGB(255,210,50)) end
end)
ui:CfgRegister("mm2_farm", function() return farmOn end, function(v) t_farm.Set(v) end)
local s_fspd=secFarm:Slider("velocidade (studs/s)", 4, 40, 16, function(v) FARM_FLY_SPEED=v end)
ui:CfgRegister("mm2_farm_speed", function() return FARM_FLY_SPEED end, function(v) s_fspd.Set(v) end)
local s_fpause=secFarm:Slider("pausa entre coins (x0.1s)", 2, 30, 8, function(v) farmPauseBetween=v/10 end)
ui:CfgRegister("mm2_farm_pause", function() return farmPauseBetween*10 end, function(v) s_fpause.Set(v) end)
secFarm:Button("status do farm", function()
    local coins=findAllCoinServers()
    ui:Toast("rbxassetid://131165537896572",
        farmOn and "[Farm] rodando" or "[Farm] parado",
        "mapa: "..#coins.."  coletadas: "..farmCount, Color3.fromRGB(255,210,50))
end)
secFarm:Button("collect coins (1x)", function()
    if not myHRP() then return end
    local coins=findAllCoinServers()
    if #coins==0 then
        ui:Toast("rbxassetid://131165537896572","coins","nenhuma coin encontrada",ROLE_COLOR.unknown); return end
    ui:Toast("rbxassetid://131165537896572","[Coins]","coletando "..#coins.."...",Color3.fromRGB(255,210,50))
    task.spawn(function()
        local myPos=myHRP() and myHRP().Position or Vector3.zero
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
            local d=(hrp.Position-g.handle.Position).Magnitude
            if d<bestD then best=g.handle; bestD=d end
        end
        if best then
            hrp=myHRP(); if not hrp then continue end
            local savedCF=hrp.CFrame
            hrp.CFrame=CFrame.new(best.Position+Vector3.new(0,2.5,0))
            task.wait(0.35); hrp=myHRP(); if not hrp then continue end
            hrp.CFrame=savedCF; task.wait(0.3)
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
ui:BuildConfigTab(tabCfg, "ref_mm2v17")

task.delay(0.9, function()
    local role=getRole()
    ui:Toast("rbxassetid://131165537896572",
        "mm2 v17  ["..ROLE_LABEL[role].."]",
        "bem-vindo, "..player.DisplayName, ROLE_COLOR[role])
end)
