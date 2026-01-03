-- FISCH EVENT FINDER - CONCEITO BASE
-- Este é um exemplo educacional de como funcionaria a lógica

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local GAME_ID = 16732694052 -- ID do Fisch
local CHECK_INTERVAL = 30 -- Segundos entre checagens

-- Configurações
local Config = {
    TargetEvents = {
        "Megalodon",
        "Great White Shark",
        "Whale Shark",
        "Great Hammerhead Shark"
    },
    AutoJoin = false, -- Mudar para true para entrar automaticamente
    NotifyOnFind = true
}

-- Função para notificar
local function Notify(title, text, duration)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5
    })
end

-- Função para verificar eventos no servidor atual
local function CheckCurrentServer()
    -- NOTA: Você precisaria adaptar isso baseado em como o Fisch
    -- armazena informações de eventos. Possíveis locais:
    
    -- 1. ReplicatedStorage
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- 2. Workspace (procurar por modelos de eventos)
    local Workspace = game:GetService("Workspace")
    
    -- 3. Remotes/Events específicos do jogo
    -- Exemplo genérico:
    for _, eventName in ipairs(Config.TargetEvents) do
        -- Verificar no Workspace
        if Workspace:FindFirstChild(eventName) then
            return true, eventName
        end
        
        -- Verificar em pastas comuns
        local NPCs = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Active")
        if NPCs and NPCs:FindFirstChild(eventName) then
            return true, eventName
        end
    end
    
    return false, nil
end

-- Função para obter lista de servidores (requer API externa ou servidor HTTP)
local function GetServerList()
    -- IMPORTANTE: Roblox não permite verificar outros servidores diretamente
    -- Você precisaria de:
    -- 1. Um servidor HTTP externo que consulta a API do Roblox
    -- 2. Ou usar serviços de terceiros (discord bots, etc)
    
    -- Exemplo conceitual:
    local success, result = pcall(function()
        -- Isso NÃO funciona diretamente no Roblox
        -- Seria feito via servidor externo
        return HttpService:GetAsync("https://games.roblox.com/v1/games/"..GAME_ID.."/servers/Public?limit=100")
    end)
    
    if success then
        local data = HttpService:JSONDecode(result)
        return data.data
    end
    
    return {}
end

-- Função principal de busca
local function ServerHopper()
    print("[FISCH FINDER] Iniciando busca por eventos...")
    Notify("Fisch Finder", "Buscando servidores com eventos...", 3)
    
    local servers = GetServerList()
    
    for i, server in ipairs(servers) do
        if server.playing < server.maxPlayers then
            -- Aqui você precisaria de uma forma de verificar o servidor
            -- sem entrar nele, o que não é possível nativamente
            print("Servidor "..i..": "..server.id.." - "..server.playing.."/"..server.maxPlayers)
        end
    end
    
    -- Alternativa: Verificar servidor atual
    local hasEvent, eventName = CheckCurrentServer()
    if hasEvent then
        Notify("Evento Encontrado!", eventName.." está ativo neste servidor!", 10)
        print("[FISCH FINDER] Evento encontrado: "..eventName)
    end
end

-- Sistema de auto-hop entre servidores
local function AutoServerHop()
    local servers = GetServerList()
    
    for _, server in ipairs(servers) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            local success = pcall(function()
                TeleportService:TeleportToPlaceInstance(GAME_ID, server.id, Players.LocalPlayer)
            end)
            
            if success then
                print("[FISCH FINDER] Teleportando para servidor: "..server.id)
                break
            end
            
            wait(1) -- Delay entre tentativas
        end
    end
end

-- Loop principal
spawn(function()
    while wait(CHECK_INTERVAL) do
        local hasEvent, eventName = CheckCurrentServer()
        
        if hasEvent then
            Notify("🦈 Evento Ativo!", eventName, 5)
            
            if Config.AutoJoin then
                -- Já está no servidor com evento
                print("[FISCH FINDER] Você já está em um servidor com evento!")
            end
        else
            if Config.AutoJoin then
                print("[FISCH FINDER] Nenhum evento encontrado, pulando para outro servidor...")
                AutoServerHop()
            end
        end
    end
end)

-- Comando manual
Notify("Fisch Event Finder", "Script carregado! Monitorando eventos...", 5)
print("[FISCH FINDER] Sistema iniciado. Checando a cada "..CHECK_INTERVAL.." segundos.")

-- Retornar funções para uso manual
return {
    CheckNow = CheckCurrentServer,
    ServerHop = AutoServerHop,
    Config = Config
}
