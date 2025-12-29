local screengui = Instance.new("ScreenGui")
screengui.Name = "DekaCollectorUI"
screengui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Parent = screengui
frame.Size = UDim2.new(0, 160, 0, 100)
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
title.Text = "deka collector"
title.TextColor3 = Color3.new(0, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Code
title.TextSize = 14

local startbtn = Instance.new("TextButton")
startbtn.Parent = frame
startbtn.Size = UDim2.new(0.8, 0, 0, 25)
startbtn.Position = UDim2.new(0.1, 0, 0, 30)
startbtn.Text = "iniciar farm"
startbtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
startbtn.BorderSizePixel = 1
startbtn.BorderColor3 = Color3.new(0.4, 0.4, 0.4)
startbtn.TextColor3 = Color3.new(1, 1, 1)
startbtn.Font = Enum.Font.Code
startbtn.TextSize = 12

local status = Instance.new("TextLabel")
status.Parent = frame
status.Size = UDim2.new(0.8, 0, 0, 20)
status.Position = UDim2.new(0.1, 0, 0, 60)
status.Text = "status: pronto"
status.TextColor3 = Color3.new(0.8, 0.8, 0.8)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left

local speed = Instance.new("TextLabel")
speed.Parent = frame
speed.Size = UDim2.new(0.8, 0, 0, 20)
speed.Position = UDim2.new(0.1, 0, 0, 80)
speed.Text = "velocidade: normal"
speed.TextColor3 = Color3.new(0.6, 0.6, 1)
speed.BackgroundTransparency = 1
speed.Font = Enum.Font.Code
speed.TextSize = 11
speed.TextXAlignment = Enum.TextXAlignment.Left

local farming = false
local player = game.Players.LocalPlayer
local connections = {}
local character = nil

print("deka collector carregado ✨")

local function updatestatus(msg)
    status.Text = "status: " .. msg
end

local function setnoclip(enabled)
    if character then
        local hum = character:FindFirstChild("Humanoid")
        if hum then
            if enabled then
                hum:ChangeState(11)
            else
                -- Reseta o estado do humanoid para permitir pular novamente
                hum:ChangeState(8)
                wait(0.1)
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            end
        end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not enabled
                if not enabled then
                    part.Velocity = Vector3.new()
                    part.RotVelocity = Vector3.new()
                end
            end
        end
    end
end

local function teleporttolight(lightobj)
    if not lightobj or not lightobj.Parent then return false end
    
    character = player.Character or player.CharacterAdded:Wait()
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    setnoclip(true)
    
    local targetPos = lightobj.Position
    if lightobj:IsA("Part") or lightobj:IsA("MeshPart") then
        targetPos = targetPos + Vector3.new(0, 2, 0)
    end
    
    hrp.CFrame = CFrame.new(targetPos)
    hrp.Velocity = Vector3.new()
    hrp.RotVelocity = Vector3.new()
    
    return true
end

local function setuplightmonitoring()
    local monitoredfolders = {}
    
    local lightsfolder = workspace:FindFirstChild("LightsLocal")
    if not lightsfolder then 
        return monitoredfolders 
    end
    
    for _, child in pairs(lightsfolder:GetChildren()) do
        if child.Name:find("LightTemplate") or child.Name == "LightTemplate" then
            table.insert(monitoredfolders, child)
        end
    end
    
    return monitoredfolders
end

local lastcollectedtime = 0

local function fastcollectlights(templatefolder)
    if not templatefolder or not templatefolder.Parent then return false end
    
    -- Verifica se já coletou recentemente (cooldown)
    if tick() - lastcollectedtime < 0.5 then
        return false
    end
    
    character = player.Character or player.CharacterAdded:Wait()
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then 
        return false
    end
    
    -- Procura apenas UM orbe disponível
    for _, lightobj in pairs(templatefolder:GetChildren()) do
        if not farming then break end
        
        if lightobj.Name:lower() == "part" and (lightobj:IsA("Part") or lightobj:IsA("MeshPart")) and lightobj.Parent then
            setnoclip(true)
            hrp.CFrame = CFrame.new(lightobj.Position + Vector3.new(0, 2, 0))
            hrp.Velocity = Vector3.new()
            hrp.RotVelocity = Vector3.new()
            
            lastcollectedtime = tick()
            
            -- Espera 0.3 segundos no orbe para coletar
            wait(0.3)
            return true
        end
    end
    
    return false
end

local function setupnewlightmonitoring(templatefolder)
    if not templatefolder then return end
    
    local conn = templatefolder.ChildAdded:Connect(function(newlight)
        if farming and newlight.Name:lower() == "part" and (newlight:IsA("Part") or newlight:IsA("MeshPart")) then
            wait(0.3)
            teleporttolight(newlight)
            wait(0.3)
        end
    end)
    
    table.insert(connections, conn)
end

local function startcontinuousfarm()
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
    
    -- busca imediata no mapa todo logo que ativa
    spawn(function()
        while farming do
            local monitoredfolders = setuplightmonitoring()
            
            if #monitoredfolders == 0 then
                updatestatus("buscando...")
            else
                updatestatus("farmando")
                
                for _, templatefolder in pairs(monitoredfolders) do
                    if not farming then break end
                    if templatefolder and templatefolder.Parent then
                        setupnewlightmonitoring(templatefolder)
                    end
                end
                
                while farming do
                    local anyfolderexists = false
                    local collected = false
                    
                    for _, templatefolder in pairs(monitoredfolders) do
                        if not farming then break end
                        
                        if templatefolder and templatefolder.Parent then
                            anyfolderexists = true
                            -- Se conseguiu coletar um orbe, para o loop
                            if fastcollectlights(templatefolder) then
                                collected = true
                                break
                            end
                        end
                    end
                    
                    if not anyfolderexists then
                        break
                    end
                    
                    -- Se não coletou nada, espera um pouco antes de verificar de novo
                    if not collected then
                        wait(0.3)
                    end
                end
            end
            
            wait(0.5)
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
end

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

if player.Character then
    character = player.Character
end
