--[[
    ANTI-FRIEND — troca de servidor quando amigo/alvo entra
    Delta executor - auto executa após teleporte
]]

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PLACE_ID    = game.PlaceId
local CURRENT_JOB = game.JobId

local alvosEspecificos = {
    ["Cristinaline5"] = true,
    ["suyz7"]         = true,
}

local amigos = {}
local agindo = false

local function fazerRequest(url)
    if syn and syn.request then
        return syn.request({ Url = url, Method = "GET" })
    elseif http_request then
        return http_request({ Url = url, Method = "GET" })
    elseif request then
        return request({ Url = url, Method = "GET" })
    else
        error("executor sem função de request suportada")
    end
end

local function iniciarCliques()
    task.spawn(function()
        local cam = workspace.CurrentCamera
        if not cam then return end

        local largura = cam.ViewportSize.X
        local altura  = cam.ViewportSize.Y
        local x = largura * 0.75
        local y = altura  * 0.50

        local inicio = tick()
        while tick() - inicio < 10 do
            pcall(function()
                if mousemoveabs then mousemoveabs(x, y) end
                if mouse1click then mouse1click() end
            end)
            task.wait(0.1)
        end
    end)
end

local function pegarServidorDiferente()
    local cursor = nil

    for _ = 1, 10 do
        local url = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(PLACE_ID)
        if cursor then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local ok, resp = pcall(function()
            return fazerRequest(url)
        end)

        if not ok or not resp or not resp.Body then
            return nil
        end

        local ok2, data = pcall(function()
            return HttpService:JSONDecode(resp.Body)
        end)

        if not ok2 or not data or not data.data then
            return nil
        end

        local candidatos = {}

        for _, server in ipairs(data.data) do
            if server.id
                and server.id ~= CURRENT_JOB
                and tonumber(server.playing)
                and tonumber(server.maxPlayers)
                and server.playing < server.maxPlayers then
                table.insert(candidatos, server.id)
            end
        end

        if #candidatos > 0 then
            return candidatos[math.random(1, #candidatos)]
        end

        if data.nextPageCursor then
            cursor = data.nextPageCursor
        else
            break
        end
    end

    return nil
end

local function trocarServidor(nome)
    if agindo then return end
    agindo = true

    print("[Anti-Friend] " .. nome .. " detectado — iniciando cliques e buscando servidor...")

    iniciarCliques()

    local novoJobId = pegarServidorDiferente()

    if novoJobId then
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PLACE_ID, novoJobId, LocalPlayer)
        end)

        if not ok then
            warn("[Anti-Friend] falha ao teleportar: " .. tostring(err))
            task.wait(0.5)
            LocalPlayer:Kick("Saindo porque " .. nome .. " entrou")
        end
    else
        warn("[Anti-Friend] nenhum servidor diferente encontrado")
        task.wait(0.5)
        LocalPlayer:Kick("Saindo porque " .. nome .. " entrou")
    end
end

local function ehAlvo(p)
    if p == LocalPlayer then return false end
    if alvosEspecificos[p.Name] then return true end
    if amigos[p.Name] then return true end
    return false
end

local function carregarAmigos()
    local tentativas = 3

    for i = 1, tentativas do
        local ok, pages = pcall(function()
            return Players:GetFriendsAsync(LocalPlayer.UserId)
        end)

        if ok and pages then
            while true do
                local okPage = pcall(function()
                    for _, info in ipairs(pages:GetCurrentPage()) do
                        local nome = info.Username or info.Name
                        if nome then
                            amigos[nome] = true
                        end
                    end
                end)

                if not okPage then break end
                if pages.IsFinished then break end

                local okNext = pcall(function()
                    pages:AdvanceToNextPageAsync()
                end)

                if not okNext then break end
            end

            return true
        end

        warn("[Anti-Friend] tentativa " .. i .. "/3 falhou ao carregar amigos")
        task.wait(2)
    end

    warn("[Anti-Friend] falha ao carregar amigos. Só alvos específicos ativos.")
    return false
end

task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(2)

    print("[Anti-Friend] iniciando — " .. LocalPlayer.Name)

    carregarAmigos()

    for _, p in ipairs(Players:GetPlayers()) do
        if ehAlvo(p) then
            trocarServidor(p.Name)
            return
        end
    end

    Players.PlayerAdded:Connect(function(p)
        if ehAlvo(p) then
            trocarServidor(p.Name)
        end
    end)

    print("[Anti-Friend] ativo e aguardando...")
end)
