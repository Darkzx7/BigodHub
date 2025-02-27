-- Função para exibir uma notificação moderna no canto inferior direito
local function showNotification(message, duration)
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Cria uma tela para a notificação
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = playerGui
    
    -- Cria a caixa de notificação
    local notification = Instance.new("TextLabel")
    notification.Text = message
    notification.Size = UDim2.new(0, 250, 0, 60)
    notification.Position = UDim2.new(1, -270, 1, -80) -- Canto inferior direito
    notification.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.Font = Enum.Font.GothamBold
    notification.TextSize = 20
    notification.BorderSizePixel = 0
    notification.BackgroundTransparency = 0.2
    notification.TextWrapped = true
    notification.Parent = screenGui
    
    -- Efeito de fade in
    notification.TextTransparency = 1
    for i = 1, 0, -0.1 do
        notification.TextTransparency = i
        wait(0.05)
    end

    -- Delay de duração da mensagem
    wait(duration)

    -- Efeito de fade out
    for i = 0, 1, 0.1 do
        notification.TextTransparency = i
        wait(0.05)
    end
    
    -- Remove a notificação
    screenGui:Destroy()
end

-- Função para copiar a mensagem de erro para o clipboard (apenas para debug)
local function copyToClipboard(message)
    print("Erro copiado para clipboard: " .. message)
end

-- Função para carregar e executar o script com log de erros
local function executeScript(scriptName, url)
    local success, errorMessage = pcall(function()
        local scriptCode = game:HttpGet(url)
        loadstring(scriptCode)()
    end)
    
    if not success then
        showNotification("Erro ao carregar: " .. scriptName, 5)
        copyToClipboard("Erro no " .. scriptName .. ": " .. errorMessage)
        print("Erro no script " .. scriptName .. ": " .. errorMessage)
    else
        print(scriptName .. " carregado com sucesso.")
    end
end

-- Função principal para carregar os scripts com delay de carregamento
local function loadScripts()
    -- Exibe a notificação de carregamento
    showNotification("Carregando scripts...", 3)

    wait(2)  -- Delay inicial para o efeito de carregamento

    -- Links dos scripts do Pastebin (atualizados)
    local fishingScriptURL = "https://pastebin.com/raw/mJAfPsrj"  -- Novo link para o script de automação da vara de pesca
    local indicatorScriptURL = "https://pastebin.com/raw/rSMQFjip"  -- Novo link para o script de controle do indicador

    -- Carregar e executar os scripts
    executeScript("Automação da Vara de Pesca", fishingScriptURL)
    wait(1)  -- Delay entre os carregamentos
    executeScript("Controle do Indicador", indicatorScriptURL)

    -- Exibe "By Dxka" após o carregamento dos scripts
    showNotification("By Dekazz", 3)
    wait(2)

    -- Notificação de sucesso após o carregamento completo
    showNotification("Scripts carregados com sucesso! Use e abuse.", 4)
end

-- Iniciar o processo de carregamento
loadScripts()
