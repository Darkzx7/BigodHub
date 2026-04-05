local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
if not RefLib then error("[EggCollector] RefLib falhou ao carregar.") end

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

local ui = RefLib.new("egg collector", "rbxassetid://131165537896572", "egg_collector_cfg")

-- ══════════════════════════════════════════════════════════════════════════════
-- ZONAS DO MAPA — RoVibes
-- Posições retiradas do scanner. Edite os Vector3 se mudar de servidor.
-- ══════════════════════════════════════════════════════════════════════════════

local ZONES = {
    { name = "Zona A",  pos = Vector3.new(-207, 4,  872) },
    { name = "Zona B",  pos = Vector3.new( 190, 9,  563) },
    { name = "Zona C",  pos = Vector3.new(  -6, 16, 563) },
    { name = "Zona D",  pos = Vector3.new( -57, 8,  672) },
    { name = "Zona E",  pos = Vector3.new( 343, 6,  762) },
    { name = "Zona F",  pos = Vector3.new( -64, 19, 454) },
    { name = "Zona G",  pos = Vector3.new(-137, 25, 781) },
    { name = "Zona H",  pos = Vector3.new(-209, 24, 774) },
}

-- ══════════════════════════════════════════════════════════════════════════════
-- ESTADO
-- ══════════════════════════════════════════════════════════════════════════════

local collectOn = false
local collected = 0
local skipped   = 0
local cooldown  = 0.35   -- segundos entre cada egg
local eggLabel  = nil

-- ══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════════════════════════

local function myHRP()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function isAlive()
    local chr = player.Character; if not chr then return false end
    local hum = chr:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function setCollision(on)
    local chr = player.Character; if not chr then return end
    for _, p in ipairs(chr:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.CanCollide = on end) end
    end
end

local function teleportTo(pos)
    local hrp = myHRP(); if not hrp then return end
    setCollision(false)
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    task.wait(0.08)
    setCollision(true)
end

-- Busca EggTemplates num raio em volta de uma posição
local function findEggsNear(center, radius)
    local eggs = {}
    local seen  = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj.Name == "EggTemplate" and not seen[obj] and obj.Parent then
                local ovo = obj:FindFirstChild("Ovo") or obj:FindFirstChild("Ovo2")
                if ovo and ovo:IsA("BasePart") then
                    local dist = (ovo.Position - center).Magnitude
                    if dist <= radius then
                        seen[obj] = true
                        table.insert(eggs, { model = obj, part = ovo, pos = ovo.Position })
                    end
                end
            end
        end)
    end
    -- Ordena pelos mais próximos
    table.sort(eggs, function(a, b)
        return (a.pos - center).Magnitude < (b.pos - center).Magnitude
    end)
    return eggs
end

-- Coleta um egg: teleporta em cima + oscilação pra garantir Touched
local function collectEgg(eggData)
    local hrp = myHRP(); if not hrp then return false end
    if not eggData.model.Parent then return false end
    local part = eggData.model:FindFirstChild("Ovo") or eggData.model:FindFirstChild("Ovo2")
    if not part or not part.Parent then return false end

    local target = part.Position + Vector3.new(0, 2.5, 0)
    setCollision(false)
    hrp.CFrame = CFrame.new(target)
    task.wait(0.06)
    hrp = myHRP()
    if hrp then
        hrp.CFrame = CFrame.new(target + Vector3.new(0.4, 0, 0))
        task.wait(0.05)
        hrp = myHRP()
        if hrp then hrp.CFrame = CFrame.new(target) end
        task.wait(0.05)
    end
    setCollision(true)
    return true
end

local function updateStatus()
    if eggLabel then
        eggLabel.Set("coletados: "..collected.."   pulados: "..skipped)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- LOOP PRINCIPAL — visita cada zona, coleta eggs em volta, repete
-- ══════════════════════════════════════════════════════════════════════════════

local ZONE_RADIUS = 120  -- studs — raio de busca em cada zona

local function collectLoop()
    collected = 0
    skipped   = 0
    updateStatus()

    while collectOn do
        if not isAlive() then task.wait(1); continue end

        local anyFound = false

        for _, zone in ipairs(ZONES) do
            if not collectOn then break end
            if not isAlive() then break end

            -- Teleporta pra zona
            teleportTo(zone.pos)
            task.wait(0.15)

            -- Coleta todos os eggs nessa zona
            local eggs = findEggsNear(zone.pos, ZONE_RADIUS)

            if #eggs > 0 then
                anyFound = true
                ui:Toast("rbxassetid://131165537896572",
                    "[Eggs] "..zone.name,
                    #eggs.." egg(s) encontrado(s) — coletando...",
                    Color3.fromRGB(255, 200, 50))

                for _, eggData in ipairs(eggs) do
                    if not collectOn then break end
                    if not isAlive() then break end
                    if collectEgg(eggData) then
                        collected = collected + 1
                    else
                        skipped = skipped + 1
                    end
                    updateStatus()
                    task.wait(cooldown)
                end
            end
        end

        -- Após varrer todas as zonas
        if collectOn then
            local msg = anyFound
                and "ciclo completo — "..collected.." coletados | rescaneando..."
                or  "nenhum egg em nenhuma zona — aguardando respawn..."
            ui:Toast("rbxassetid://131165537896572", "[Eggs]", msg, Color3.fromRGB(100, 220, 100))
            task.wait(anyFound and 2 or 5)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════════════════════════════════

local tab = ui:Tab("ovos", "rbxassetid://131165537896572")
local sec = tab:Section("auto coletor — RoVibes")

eggLabel = sec:Button("coletados: 0   pulados: 0", function() end)

sec:Divider("farm")

local t_collect = sec:Toggle("auto coletar eggs", false, function(v)
    collectOn = v
    if v then
        task.spawn(collectLoop)
        ui:Toast("rbxassetid://131165537896572", "[Eggs] iniciado",
            "varrendo "..#ZONES.." zonas do mapa...", Color3.fromRGB(255, 200, 50))
    else
        ui:Toast("rbxassetid://131165537896572", "[Eggs] parado",
            "total coletados: "..collected, Color3.fromRGB(150, 150, 160))
    end
end)
ui:CfgRegister("egg_collect", function() return collectOn end, function(v) t_collect.Set(v) end)

local s_cd = sec:Slider("delay entre eggs (x0.05s)", 1, 20, 7, function(v)
    cooldown = v * 0.05
end)
ui:CfgRegister("egg_cooldown", function() return cooldown / 0.05 end, function(v) s_cd.Set(v) end)

sec:Divider("teleporte manual — zonas")

for _, zone in ipairs(ZONES) do
    local z = zone  -- captura pro closure
    sec:Button("ir para "..z.name, function()
        if not isAlive() then
            ui:Toast("rbxassetid://131165537896572", "[TP]", "voce esta morto", Color3.fromRGB(200,80,80))
            return
        end
        teleportTo(z.pos)
        ui:Toast("rbxassetid://131165537896572", "[TP] "..z.name,
            "teleportado | coletando eggs proximos...", Color3.fromRGB(100, 200, 255))
        -- Coleta imediata na zona mesmo sem o loop ativo
        task.spawn(function()
            local eggs = findEggsNear(z.pos, ZONE_RADIUS)
            if #eggs == 0 then
                ui:Toast("rbxassetid://131165537896572", "[TP] "..z.name,
                    "nenhum egg nessa zona", Color3.fromRGB(160,160,180))
                return
            end
            for _, eggData in ipairs(eggs) do
                if collectEgg(eggData) then collected = collected + 1
                else skipped = skipped + 1 end
                updateStatus()
                task.wait(cooldown)
            end
            ui:Toast("rbxassetid://131165537896572", "[TP] "..z.name.." feito",
                "coletados: "..collected, Color3.fromRGB(100, 220, 100))
        end)
    end)
end

sec:Divider("config")
sec:Button("resetar contador", function()
    collected = 0; skipped = 0; updateStatus()
    ui:Toast("rbxassetid://131165537896572", "[Eggs]", "contador zerado", Color3.fromRGB(160,160,200))
end)

local tabCfg = ui:Tab("config", "rbxassetid://131165537896572")
ui:BuildConfigTab(tabCfg, "egg_collector_cfg")
