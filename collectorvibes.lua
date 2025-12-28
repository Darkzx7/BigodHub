local screengui = Instance.new("ScreenGui")
screengui.Name = "OrbCollectorUI"
screengui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Parent = screengui
frame.Size = UDim2.new(0, 180, 0, 130)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 20)
title.Position = UDim2.new(0, 0, 0, 5)
title.Text = "orb detector"
title.TextColor3 = Color3.new(0, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Code
title.TextSize = 14

local detectbtn = Instance.new("TextButton")
detectbtn.Parent = frame
detectbtn.Size = UDim2.new(0.85, 0, 0, 25)
detectbtn.Position = UDim2.new(0.075, 0, 0, 30)
detectbtn.Text = "detectar próximo"
detectbtn.BackgroundColor3 = Color3.new(0.2, 0.5, 0.2)
detectbtn.BorderSizePixel = 1
detectbtn.BorderColor3 = Color3.new(0.4, 0.4, 0.4)
detectbtn.TextColor3 = Color3.new(1, 1, 1)
detectbtn.Font = Enum.Font.Code
detectbtn.TextSize = 11

local startbtn = Instance.new("TextButton")
startbtn.Parent = frame
startbtn.Size = UDim2.new(0.85, 0, 0, 25)
startbtn.Position = UDim2.new(0.075, 0, 0, 60)
startbtn.Text = "iniciar farm"
startbtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
startbtn.BorderSizePixel = 1
startbtn.BorderColor3 = Color3.new(0.4, 0.4, 0.4)
startbtn.TextColor3 = Color3.new(1, 1, 1)
startbtn.Font = Enum.Font.Code
startbtn.TextSize = 12

local status = Instance.new("TextLabel")
status.Parent = frame
status.Size = UDim2.new(0.85, 0, 0, 20)
status.Position = UDim2.new(0.075, 0, 0, 90)
status.Text = "status: pronto"
status.TextColor3 = Color3.new(0.8, 0.8, 0.8)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left

local speed = Instance.new("TextLabel")
speed.Parent = frame
speed.Size = UDim2.new(0.85, 0, 0, 20)
speed.Position = UDim2.new(0.075, 0, 0, 110)
speed.Text = "distância: 50m"
speed.TextColor3 = Color3.new(0.6, 0.6, 1)
speed.BackgroundTransparency = 1
speed.Font = Enum.Font.Code
speed.TextSize = 11
speed.TextXAlignment = Enum.TextXAlignment.Left

local farming = false
local detecting = false
local player = game.Players.LocalPlayer
local connections = {}
local character = nil
local detectionrange = 50
local targetnames = {} -- vai armazenar os nomes detectados

print("orb detector carregado ✨")
print("aperte F9 para ver o console")

local function updatestatus(msg)
    status.Text = "status: " .. msg
end

local function detectnearbyobjects()
    character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then
        print("❌ HumanoidRootPart não encontrado")
        return
    end
    
    print("\n" .. string.rep("=", 60))
    print("🔍 DETECTANDO OBJETOS PRÓXIMOS (" .. detectionrange .. "m)")
    print(string.rep("=", 60))
    
    local mypos = hrp.Position
    local found = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= hrp then
            local distance = (obj.Position - mypos).Magnitude
            
            if distance <= detectionrange then
                local info = {
                    name = obj.Name,
                    classname = obj.ClassName,
                    distance = math.floor(distance * 10) / 10,
                    position = obj.Position,
                    path = obj:GetFullName(),
                    parent = obj.Parent and obj.Parent.Name or "nil",
                    haslight = obj:FindFirstChildOfClass("PointLight") ~= nil or obj:FindFirstChildOfClass("SpotLight") ~= nil
                }
                table.insert(found, info)
            end
        end
    end
    
    -- ordena por distância
    table.sort(found, function(a, b) return a.distance < b.distance end)
    
    if #found == 0 then
        print("❌ Nenhum objeto encontrado próximo")
    else
        print("✓ Encontrados " .. #found .. " objetos:")
        print("")
        
        for i, info in ipairs(found) do
            if i <= 20 then -- mostra os 20 mais próximos
                print(string.format("[%d] Nome: %s", i, info.name))
                print(string.format("    Tipo: %s", info.classname))
                print(string.format("    Distância: %.1fm", info.distance))
                print(string.format("    Pai: %s", info.parent))
                print(string.format("    Tem luz: %s", info.haslight and "SIM ✨" or "não"))
                print(string.format("    Caminho: %s", info.path))
                print("")
            end
        end
        
        if #found > 20 then
            print("... e mais " .. (#found - 20) .. " objetos")
        end
    end
    
    print(string.rep("=", 60))
    print("💡 Achou o orbe? Copie o NOME EXATO dele!")
    print(string.rep("=", 60) .. "\n")
end

local function setnoclip(enabled)
    if character then
        local hum = character:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState(11)
            hum.PlatformStand = true
        end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not enabled
                part.Velocity = Vector3.new()
                part.RotVelocity = Vector3.new()
            end
        end
    end
end

local function teleporttoobj(obj)
    if not obj or not obj.Parent then return false end
    
    character = player.Character or player.CharacterAdded:Wait()
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    setnoclip(true)
    
    local targetPos = obj.Position + Vector3.new(0, 2, 0)
    hrp.CFrame = CFrame.new(targetPos)
    hrp.Velocity = Vector3.new()
    hrp.RotVelocity = Vector3.new()
    
    return true
end

local function istarget(obj)
    if not obj:IsA("BasePart") then return false end
    
    -- se ainda não temos nomes específicos, não coleta nada
    if #targetnames == 0 then return false end
    
    local name = obj.Name
    for _, targetname in pairs(targetnames) do
        if name == targetname then
            return true
        end
    end
    
    return false
end

local function findtargets()
    local targets = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if istarget(obj) then
            table.insert(targets, obj)
        end
    end
    
    return targets
end

local function startcontinuousfarm()
    if #targetnames == 0 then
        updatestatus("detecte primeiro!")
        print("⚠️ Use o botão DETECTAR PRÓXIMO primeiro!")
        return
    end
    
    farming = true
    startbtn.Text = "parar farm"
    startbtn.BackgroundColor3 = Color3.new(0.6, 0, 0)
    updatestatus("ativo")
    
    character = player.Character or player.CharacterAdded:Wait()
    setnoclip(true)
    
    for _, conn in pairs(connections) do
        if conn then conn:Disconnect() end
    end
    connections = {}
    
    print("🚀 Farm iniciado! Procurando: " .. table.concat(targetnames, ", "))
    
    -- monitora novos objetos
    local conn = workspace.DescendantAdded:Connect(function(obj)
        if farming and istarget(obj) then
            wait(0.05)
            teleporttoobj(obj)
        end
    end)
    table.insert(connections, conn)
    
    spawn(function()
        while farming do
            local targets = findtargets()
            
            if #targets == 0 then
                updatestatus("buscando...")
            else
                updatestatus("coletando")
                
                for _, target in pairs(targets) do
                    if not farming then break end
                    if target and target.Parent then
                        teleporttoobj(target)
                        wait(0.05)
                    end
                end
            end
            
            wait(0.1)
        end
    end)
end

local function stopfarm()
    farming = false
    startbtn.Text = "iniciar farm"
    startbtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    
    setnoclip(false)
    
    for _, conn in pairs(connections) do
        if conn then conn:Disconnect() end
    end
    connections = {}
    
    updatestatus("parado")
    print("⏹️ Farm parado")
end

detectbtn.MouseButton1Click:Connect(function()
    if not detecting then
        detecting = true
        detectbtn.Text = "detectando..."
        detectbtn.BackgroundColor3 = Color3.new(0.5, 0.5, 0)
        
        spawn(function()
            detectnearbyobjects()
            
            wait(1)
            detecting = false
            detectbtn.Text = "detectar próximo"
            detectbtn.BackgroundColor3 = Color3.new(0.2, 0.5, 0.2)
            
            print("\n💬 Digite no chat para adicionar nome:")
            print('exemplo: /addorb NomeDoOrbe')
        end)
    end
end)

startbtn.MouseButton1Click:Connect(function()
    if farming then
        stopfarm()
    else
        spawn(startcontinuousfarm)
    end
end)

player.CharacterAdded:Connect(function(char)
    character = char
    if not farming then
        setnoclip(false)
    end
end)

-- comando para adicionar nome do orbe
player.Chatted:Connect(function(msg)
    if msg:sub(1, 8):lower() == "/addorb " then
        local orbname = msg:sub(9)
        if orbname ~= "" then
            table.insert(targetnames, orbname)
            print("✓ Adicionado: " .. orbname)
            print("Alvos atuais: " .. table.concat(targetnames, ", "))
            updatestatus(#targetnames .. " alvos")
        end
    elseif msg:lower() == "/clearorbs" then
        targetnames = {}
        print("🗑️ Lista de alvos limpa")
        updatestatus("pronto")
    elseif msg:lower() == "/listorbs" then
        if #targetnames > 0 then
            print("📋 Alvos configurados:")
            for i, name in ipairs(targetnames) do
                print(string.format("  [%d] %s", i, name))
            end
        else
            print("❌ Nenhum alvo configurado")
        end
    end
end)

if player.Character then
    character = player.Character
end

print("\n📖 INSTRUÇÕES:")
print("1. Chegue perto do orbe/luz (menos de 50m)")
print("2. Clique em 'DETECTAR PRÓXIMO'")
print("3. Veja o console (F9) e encontre o nome do orbe")
print("4. Digite no chat: /addorb NomeExatoDoOrbe")
print("5. Clique em 'INICIAR FARM'")
print("\nComandos extras:")
print("  /listorbs - ver alvos configurados")
print("  /clearorbs - limpar lista de alvos")
print(string.rep("=", 60))
