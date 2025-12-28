local screengui = Instance.new("ScreenGui")
screengui.Name = "OrbCollectorUI"
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
title.Text = "orb collector"
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
speed.Text = "velocidade: alta"
speed.TextColor3 = Color3.new(0.6, 0.6, 1)
speed.BackgroundTransparency = 1
speed.Font = Enum.Font.Code
speed.TextSize = 11
speed.TextXAlignment = Enum.TextXAlignment.Left

local farming = false
local player = game.Players.LocalPlayer
local connections = {}
local character = nil

print("orb collector carregado ✨")

local function updatestatus(msg)
    status.Text = "status: " .. msg
end

-- palavras-chave para identificar orbes/luzes
local orbkeywords = {
    "light", "orb", "luz", "sphere", "ball", "glow", 
    "particle", "collect", "pickup", "item"
}

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

local function teleporttoorb(orbobj)
    if not orbobj or not orbobj.Parent then return false end
    
    character = player.Character or player.CharacterAdded:Wait()
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    setnoclip(true)
    
    local targetPos = orbobj.Position
    if orbobj:IsA("Part") or orbobj:IsA("MeshPart") then
        targetPos = targetPos + Vector3.new(0, 2, 0)
    end
    
    hrp.CFrame = CFrame.new(targetPos)
    hrp.Velocity = Vector3.new()
    hrp.RotVelocity = Vector3.new()
    
    return true
end

local function isorb(obj)
    if not obj:IsA("BasePart") then return false end
    
    local name = obj.Name:lower()
    for _, keyword in pairs(orbkeywords) do
        if name:find(keyword) then
            return true
        end
    end
    
    -- verifica se tem PointLight ou SpotLight (orbes geralmente emitem luz)
    if obj:FindFirstChildOfClass("PointLight") or obj:FindFirstChildOfClass("SpotLight") then
        return true
    end
    
    return false
end

local function findorbfolders()
    local orbfolders = {}
    
    -- busca em workspace
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Folder") or obj:IsA("Model") then
            local name = obj.Name:lower()
            for _, keyword in pairs(orbkeywords) do
                if name:find(keyword) then
                    table.insert(orbfolders, obj)
                    break
                end
            end
        end
    end
    
    -- se não encontrou, busca por pastas comuns
    local commonfolders = {"Items", "Collectibles", "Drops", "Spawns", "Assets"}
    for _, foldername in pairs(commonfolders) do
        local folder = workspace:FindFirstChild(foldername)
        if folder then
            table.insert(orbfolders, folder)
        end
    end
    
    return orbfolders
end

local function findorbs()
    local orbs = {}
    
    -- busca direto no workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if isorb(obj) then
            table.insert(orbs, obj)
        end
    end
    
    return orbs
end

local function fastcollectorbs(orbsfolder)
    if not orbsfolder or not orbsfolder.Parent then return end
    
    character = player.Character or player.CharacterAdded:Wait()
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return end
    
    for _, obj in pairs(orbsfolder:GetDescendants()) do
        if not farming then break end
        
        if isorb(obj) and obj.Parent then
            setnoclip(true)
            hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0))
            
            wait(0.03)
            break
        end
    end
end

local function setupneworbmonitoring(folder)
    if not folder then return end
    
    local conn = folder.DescendantAdded:Connect(function(neworb)
        if farming and isorb(neworb) then
            wait(0.03)
            teleporttoorb(neworb)
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
    
    spawn(function()
        while farming do
            local orbfolders = findorbfolders()
            
            if #orbfolders == 0 then
                updatestatus("buscando...")
                
                -- busca orbes diretamente
                local orbs = findorbs()
                if #orbs > 0 then
                    updatestatus("coletando")
                    for _, orb in pairs(orbs) do
                        if not farming then break end
                        if orb and orb.Parent then
                            teleporttoorb(orb)
                            wait(0.03)
                        end
                    end
                end
                
                wait(1)
            else
                updatestatus("farmando")
                
                for _, folder in pairs(orbfolders) do
                    if not farming then break end
                    if folder and folder.Parent then
                        setupneworbmonitoring(folder)
                    end
                end
                
                while farming do
                    local anyfolderexists = false
                    
                    for _, folder in pairs(orbfolders) do
                        if not farming then break end
                        
                        if folder and folder.Parent then
                            anyfolderexists = true
                            fastcollectorbs(folder)
                        end
                    end
                    
                    if not anyfolderexists then
                        break
                    end
                    
                    wait(0.03)
                end
                
                wait(0.05)
            end
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
