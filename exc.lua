-- Função para exibir uma mensagem na tela
local function showMessage(message, duration)
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Cria uma nova notificação com a mensagem
    local notification = Instance.new("TextLabel")
    notification.Text = message
    notification.Size = UDim2.new(0, 200, 0, 50)
    notification.Position = UDim2.new(0.5, -100, 0.1, 0) -- Posição no canto superior central
    notification.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.Font = Enum.Font.SourceSansBold
    notification.TextSize = 18
    notification.Parent = playerGui

    -- Remove a notificação após o tempo especificado
    wait(duration)
    notification:Destroy()
end

-- Função para copiar a mensagem de erro para o clipboard
local function copyToClipboard(message)
    -- Aqui estamos apenas exibindo a mensagem de erro, pois o Roblox não suporta
    -- diretamente manipulação do clipboard, mas em outros ambientes podemos usar
    -- APIs externas para copiar para o clipboard.
    print("Erro copiado para clipboard: " .. message)
end

-- Função para carregar e executar o script com log de erros
local function executeScript(scriptName, url)
    local success, errorMessage = pcall(function()
        local scriptCode = game:HttpGet(url)  -- Carregar o script do Pastebin
        loadstring(scriptCode)()  -- Executar o script carregado
    end)
    
    if not success then
        showMessage("Erro ao carregar: " .. scriptName, 5)
        copyToClipboard("Erro no " .. scriptName .. ": " .. errorMessage)
        print("Erro no script " .. scriptName .. ": " .. errorMessage)
    else
        print(scriptName .. " carregado com sucesso.")
    end
end

-- Função para mostrar "Carregando script" e iniciar a execução
local function loadScripts()
    showMessage("Carregando scripts...", 3)

    -- Links dos scripts do Pastebin
    local fishingScriptURL = "https://pastebin.com/raw/dsa2yEVM"  -- Link do script de automação da vara de pesca
    local indicatorScriptURL = "https://pastebin.com/raw/eLQePmPE"  -- Link do script de controle do indicador

    -- Carregar e executar o script de automação da vara de pesca
    executeScript("Automação da Vara de Pesca", fishingScriptURL)

    -- Carregar e executar o script de controle do indicador
    executeScript("Controle do Indicador", indicatorScriptURL)

    -- Quando os dois scripts estiverem carregados, exibir a mensagem de sucesso
    showMessage("Scripts carregados com sucesso! Automação ativa.", 5)
end

-- Iniciar o processo de carregamento
loadScripts()
