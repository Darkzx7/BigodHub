--[[
	mm2_ui.lua — Script para Murder Mystery 2
	Usa a ref_lib do GitHub como UI base.

	COMO USAR:
	  1. Suba ref_lib.lua no seu repositório GitHub
	  2. Substitua a URL abaixo pela URL raw do seu arquivo
	  3. Execute este script no executor

	URL raw = https://raw.githubusercontent.com/SEU_USER/SEU_REPO/main/ref_lib.lua
--]]

-- ── Carrega a lib do GitHub ────────────────────────────────────────────────────
local LIB_URL = "https://raw.githubusercontent.com/SEU_USER/SEU_REPO/main/ref_lib.lua"

local RefLib
local ok, err = pcall(function()
	RefLib = loadstring(game:HttpGet(LIB_URL, true))()
end)

if not ok or not RefLib then
	-- Fallback: tenta carregar de _G caso o ref_ui universal já tenha rodado
	if _G.RefLib then
		RefLib = _G.RefLib
	else
		error("[mm2_ui] falhou ao carregar ref_lib: " .. tostring(err))
	end
end

-- ── Serviços ──────────────────────────────────────────────────────────────────
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local player          = Players.LocalPlayer

-- ── Cria a janela MM2 ─────────────────────────────────────────────────────────
-- RefLib.new(nome, iconId, nomeGui)
-- nomeGui é único por script — não conflita com o ref_ui universal
local ui = RefLib.new("mm2", "rbxassetid://131165537896572", "ref_mm2_ui")

-- ── Detecta papéis do MM2 ─────────────────────────────────────────────────────
local function getMM2Role()
	-- O MM2 guarda o papel em lighting ou em valores do personagem, dependendo da versão
	-- Tenta os caminhos mais comuns
	local char = player.Character
	if not char then return "unknown" end

	-- Método 1: IntValue "Role" no personagem
	local roleVal = char:FindFirstChild("Role") or char:FindFirstChild("role")
	if roleVal and roleVal.Value then
		return tostring(roleVal.Value)
	end

	-- Método 2: tag no personagem (StringValue "RoleTag")
	local tag = char:FindFirstChild("RoleTag")
	if tag then return tag.Value end

	-- Método 3: verifica pelo nome da equipe
	if player.Team then return player.Team.Name:lower() end

	return "unknown"
end

local function getAliveCount()
	local count = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if hum.Health > 0 then count = count + 1 end
		end
	end
	return count
end

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local mainTab   = ui:Tab("main")
local espTab    = ui:Tab("esp")
local configTab = ui:Tab("config")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: MAIN
-- ══════════════════════════════════════════════════════════════════════════════
do
	-- Seção de info do round
	local infoSec = mainTab:Section("round info")
	infoSec:Divider("status")

	-- Label de papel (atualiza a cada segundo via toggle fake de refresh)
	local roleBtn = infoSec:Button("check my role", function()
		local role = getMM2Role()
		local alive = getAliveCount()
		ui:Toast(
			"rbxassetid://131165537896572",
			"role: " .. role,
			"players alive: " .. alive,
			role == "murderer" and Color3.fromRGB(220,60,60)
				or role == "sheriff" and Color3.fromRGB(60,180,220)
				or Color3.fromRGB(120,80,255)
		)
	end)

	-- ── MURDERER ──────────────────────────────────────────────────────────────
	infoSec:Divider("murderer")

	-- Highlight todos os innocents (útil pra murderer ver quem está escondido)
	local innocentEsp    = false
	local innocentData   = {}
	local INNOCENT_COLOR = Color3.fromRGB(80, 220, 80)
	local SHERIFF_COLOR  = Color3.fromRGB(60, 180, 220)

	local function removeInnHL(p)
		if innocentData[p] and innocentData[p].Parent then innocentData[p]:Destroy() end
		innocentData[p] = nil
	end
	local function applyInnHL(p)
		if innocentData[p] then return end
		local char = p.Character
		if not char then return end
		local hl = Instance.new("Highlight")
		hl.FillColor          = INNOCENT_COLOR
		hl.OutlineColor       = Color3.fromRGB(255,255,255)
		hl.FillTransparency   = 0.45
		hl.OutlineTransparency = 0
		hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee            = char
		hl.Parent             = char
		innocentData[p]       = hl
	end
	local function refreshInnHL()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				if innocentEsp then applyInnHL(p) else removeInnHL(p) end
			end
		end
	end

	local t_innEsp = infoSec:Toggle("player highlight (all)", false, function(v)
		innocentEsp = v
		refreshInnHL()
	end)
	ui:CfgRegister("mm2_inn_esp", function() return innocentEsp end, function(v) t_innEsp.Set(v) end)

	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			task.wait(1)
			if innocentEsp then applyInnHL(p) end
		end)
	end)
	Players.PlayerRemoving:Connect(removeInnHL)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			p.CharacterAdded:Connect(function()
				task.wait(1)
				if innocentEsp then applyInnHL(p) end
			end)
		end
	end

	-- Knife drop ESP: mostra onde a faca caiu no chão
	-- A faca no MM2 é um Tool chamado "Knife" no workspace quando dropada
	local knifeEsp   = false
	local knifeConns = {}
	local knifeBBs   = {}

	local function removeKnifeBB(tool)
		if knifeBBs[tool] and knifeBBs[tool].Parent then knifeBBs[tool]:Destroy() end
		knifeBBs[tool] = nil
	end

	local function watchKnife(tool)
		if not tool:IsA("Tool") then return end
		if tool.Name ~= "Knife" then return end
		if knifeBBs[tool] then return end

		-- Espera o handle aparecer
		local handle = tool:FindFirstChildOfClass("BasePart") or tool:WaitForChild("Handle", 3)
		if not handle then return end

		local bb = Instance.new("BillboardGui")
		bb.Size         = UDim2.new(0, 80, 0, 36)
		bb.StudsOffset  = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop  = true
		bb.ResetOnSpawn = false
		bb.Adornee      = handle
		bb.Parent       = handle

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size      = UDim2.new(1, 0, 1, 0)
		lbl.Font      = Enum.Font.GothamBold
		lbl.TextSize  = 13
		lbl.TextColor3 = Color3.fromRGB(220, 60, 60)
		lbl.TextStrokeTransparency = 0.2
		lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		lbl.Text      = "🔪 knife"
		lbl.Parent    = bb

		bb.Enabled    = knifeEsp
		knifeBBs[tool] = bb

		tool.AncestryChanged:Connect(function()
			if not tool.Parent then removeKnifeBB(tool) end
		end)
	end

	-- Varre workspace por facas existentes e novas
	local function scanKnives()
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Tool") and obj.Name == "Knife" then
				task.spawn(watchKnife, obj)
			end
		end
	end

	table.insert(knifeConns, workspace.DescendantAdded:Connect(function(obj)
		if knifeEsp then
			task.spawn(watchKnife, obj)
		end
	end))

	local t_knifeEsp = infoSec:Toggle("knife esp", false, function(v)
		knifeEsp = v
		if v then scanKnives() end
		for tool, bb in pairs(knifeBBs) do
			bb.Enabled = v
		end
	end)
	ui:CfgRegister("mm2_knife_esp", function() return knifeEsp end, function(v) t_knifeEsp.Set(v) end)

	-- ── SHERIFF ───────────────────────────────────────────────────────────────
	infoSec:Divider("sheriff / innocent")

	-- Gun drop ESP: mesmo esquema da faca mas pra gun
	local gunEsp   = false
	local gunBBs   = {}

	local function removeGunBB(tool)
		if gunBBs[tool] and gunBBs[tool].Parent then gunBBs[tool]:Destroy() end
		gunBBs[tool] = nil
	end

	local function watchGun(tool)
		if not tool:IsA("Tool") then return end
		if tool.Name ~= "Sheriff's Gun" and tool.Name ~= "Gun" then return end
		if gunBBs[tool] then return end

		local handle = tool:FindFirstChildOfClass("BasePart") or tool:WaitForChild("Handle", 3)
		if not handle then return end

		local bb = Instance.new("BillboardGui")
		bb.Size         = UDim2.new(0, 80, 0, 36)
		bb.StudsOffset  = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop  = true
		bb.ResetOnSpawn = false
		bb.Adornee      = handle
		bb.Parent       = handle

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size       = UDim2.new(1, 0, 1, 0)
		lbl.Font       = Enum.Font.GothamBold
		lbl.TextSize   = 13
		lbl.TextColor3 = Color3.fromRGB(60, 180, 220)
		lbl.TextStrokeTransparency = 0.2
		lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		lbl.Text       = "🔫 gun"
		lbl.Parent     = bb

		bb.Enabled   = gunEsp
		gunBBs[tool] = bb

		tool.AncestryChanged:Connect(function()
			if not tool.Parent then removeGunBB(tool) end
		end)
	end

	local function scanGuns()
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Tool") and (obj.Name == "Sheriff's Gun" or obj.Name == "Gun") then
				task.spawn(watchGun, obj)
			end
		end
	end

	workspace.DescendantAdded:Connect(function(obj)
		if gunEsp then task.spawn(watchGun, obj) end
	end)

	local t_gunEsp = infoSec:Toggle("gun esp", false, function(v)
		gunEsp = v
		if v then scanGuns() end
		for _, bb in pairs(gunBBs) do bb.Enabled = v end
	end)
	ui:CfgRegister("mm2_gun_esp", function() return gunEsp end, function(v) t_gunEsp.Set(v) end)

	-- ── COINS ─────────────────────────────────────────────────────────────────
	infoSec:Divider("coins")

	-- Coin ESP: mostra moedas no mapa com BillboardGui
	local coinEsp  = false
	local coinBBs  = {}

	local function removeCoinBB(part)
		if coinBBs[part] and coinBBs[part].Parent then coinBBs[part]:Destroy() end
		coinBBs[part] = nil
	end

	local function isCoin(obj)
		-- Moedas no MM2 costumam ser Parts/Models com nome "Coin" ou "GoldCoin"
		return obj.Name == "Coin" or obj.Name == "GoldCoin" or obj.Name == "coin"
	end

	local function watchCoin(obj)
		local part = obj:IsA("BasePart") and obj
			or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
		if not part then return end
		if coinBBs[part] then return end

		local bb = Instance.new("BillboardGui")
		bb.Size         = UDim2.new(0, 60, 0, 28)
		bb.StudsOffset  = Vector3.new(0, 2.5, 0)
		bb.AlwaysOnTop  = true
		bb.ResetOnSpawn = false
		bb.Adornee      = part
		bb.Parent       = part

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size       = UDim2.new(1, 0, 1, 0)
		lbl.Font       = Enum.Font.GothamBold
		lbl.TextSize   = 12
		lbl.TextColor3 = Color3.fromRGB(255, 210, 50)
		lbl.TextStrokeTransparency = 0.2
		lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		lbl.Text       = "💰"
		lbl.Parent     = bb

		bb.Enabled    = coinEsp
		coinBBs[part] = bb

		obj.AncestryChanged:Connect(function()
			if not obj.Parent then removeCoinBB(part) end
		end)
	end

	local function scanCoins()
		for _, obj in ipairs(workspace:GetDescendants()) do
			if isCoin(obj) then task.spawn(watchCoin, obj) end
		end
	end

	workspace.DescendantAdded:Connect(function(obj)
		if coinEsp and isCoin(obj) then task.spawn(watchCoin, obj) end
	end)

	local t_coinEsp = infoSec:Toggle("coin esp", false, function(v)
		coinEsp = v
		if v then scanCoins() end
		for _, bb in pairs(coinBBs) do bb.Enabled = v end
	end)
	ui:CfgRegister("mm2_coin_esp", function() return coinEsp end, function(v) t_coinEsp.Set(v) end)

	-- ── MOVEMENT ──────────────────────────────────────────────────────────────
	local moveSec = mainTab:Section("movement")
	moveSec:Divider("speed")

	local DEFAULT_SPEED = 16
	local speedOn  = false
	local curSpeed = DEFAULT_SPEED

	local function applySpeed()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = speedOn and curSpeed or DEFAULT_SPEED end
	end

	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		task.wait()
		applySpeed()
	end)

	local t_spd = moveSec:Toggle("fast walk", false, function(v)
		speedOn = v; applySpeed()
	end)
	ui:CfgRegister("mm2_speed_on", function() return speedOn end, function(v) t_spd.Set(v) end)

	local s_spd = moveSec:Slider("speed", 8, 80, 24, function(v)
		curSpeed = v
		if speedOn then applySpeed() end
	end)
	ui:CfgRegister("mm2_speed_val", function() return curSpeed end, function(v) s_spd.Set(v) end)

	moveSec:Divider("jump")
	local jumpOn   = false
	local jumpConn = nil
	local t_jump = moveSec:Toggle("infinite jump", false, function(v)
		jumpOn = v
		if jumpConn then jumpConn:Disconnect() jumpConn = nil end
		if v then
			jumpConn = UserInputService.JumpRequest:Connect(function()
				local c = player.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			end)
		end
	end)
	ui:CfgRegister("mm2_infjump", function() return jumpOn end, function(v) t_jump.Set(v) end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: ESP AVANÇADO
-- ══════════════════════════════════════════════════════════════════════════════
do
	local sec = espTab:Section("players")
	sec:Divider("highlight")

	-- ESP com distância e HP, igual ao universal mas separado pro MM2
	local espOn    = false
	local espData  = {}
	local maxDist  = 300
	local camera   = workspace.CurrentCamera

	local function hpCol(hp, max)
		local pct = math.clamp(hp / math.max(max,1), 0, 1)
		if pct > 0.6 then return Color3.fromRGB(80,220,80)
		elseif pct > 0.3 then return Color3.fromRGB(240,200,40)
		else return Color3.fromRGB(220,60,60) end
	end

	local function removeESP(p)
		local d = espData[p]; if not d then return end
		if d.hl  and d.hl.Parent  then d.hl:Destroy()  end
		if d.bb  and d.bb.Parent  then d.bb:Destroy()  end
		espData[p] = nil
	end

	local function createESP(p)
		if espData[p] then return end
		local char = p.Character; if not char then return end
		local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

		local hl = Instance.new("Highlight")
		hl.FillColor          = Color3.fromRGB(120,80,255)
		hl.OutlineColor       = Color3.fromRGB(255,255,255)
		hl.FillTransparency   = 0.45
		hl.OutlineTransparency = 0
		hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = char; hl.Parent = char

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0,120,0,48); bb.StudsOffset = Vector3.new(0,3,0)
		bb.AlwaysOnTop = true; bb.ResetOnSpawn = false
		bb.Adornee = hrp; bb.Parent = hrp

		local nm = Instance.new("TextLabel")
		nm.BackgroundTransparency = 1; nm.Size = UDim2.new(1,0,0,18)
		nm.Font = Enum.Font.GothamBold; nm.TextSize = 13
		nm.TextColor3 = Color3.fromRGB(255,255,255)
		nm.TextStrokeTransparency = 0.2; nm.TextStrokeColor3 = Color3.fromRGB(0,0,0)
		nm.TextXAlignment = Enum.TextXAlignment.Center; nm.Text = p.DisplayName; nm.Parent = bb

		local hpBg = Instance.new("Frame"); hpBg.Size = UDim2.new(1,0,0,4)
		hpBg.Position = UDim2.new(0,0,0,20); hpBg.BackgroundColor3 = Color3.fromRGB(25,25,25)
		hpBg.BackgroundTransparency = 0.3; hpBg.BorderSizePixel = 0; hpBg.Parent = bb
		local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(1,0); uc.Parent = hpBg
		local hpFill = Instance.new("Frame"); hpFill.Size = UDim2.new(1,0,1,0)
		hpFill.BackgroundColor3 = Color3.fromRGB(80,220,80); hpFill.BorderSizePixel = 0; hpFill.Parent = hpBg
		local uc2 = Instance.new("UICorner"); uc2.CornerRadius = UDim.new(1,0); uc2.Parent = hpFill

		local dl = Instance.new("TextLabel")
		dl.BackgroundTransparency = 1; dl.Size = UDim2.new(1,0,0,14)
		dl.Position = UDim2.new(0,0,0,28); dl.Font = Enum.Font.Gotham; dl.TextSize = 10
		dl.TextColor3 = Color3.fromRGB(200,200,220); dl.TextStrokeTransparency = 0.3
		dl.TextStrokeColor3 = Color3.fromRGB(0,0,0); dl.TextXAlignment = Enum.TextXAlignment.Center; dl.Parent = bb

		espData[p] = {hl=hl, bb=bb, nm=nm, hpBg=hpBg, hpFill=hpFill, dl=dl}
	end

	RunService.RenderStepped:Connect(function()
		if not espOn then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p == player then continue end
			local char = p.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			if not char or not hum or not hrp or hum.Health <= 0 then removeESP(p); continue end
			local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)
			if dist > maxDist then removeESP(p); continue end
			if not espData[p] then createESP(p) end
			local d = espData[p]; if not d then continue end
			d.nm.Text = p.DisplayName
			local pct = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
			d.hpFill.Size = UDim2.new(pct,0,1,0)
			d.hpFill.BackgroundColor3 = hpCol(hum.Health, hum.MaxHealth)
			d.dl.Text = dist.."m"
		end
	end)

	Players.PlayerRemoving:Connect(removeESP)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			p.CharacterAdded:Connect(function()
				removeESP(p); task.wait(1)
				if espOn then createESP(p) end
			end)
		end
	end
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			task.wait(1)
			if espOn then createESP(p) end
		end)
	end)

	local t_esp = sec:Toggle("player esp", false, function(v)
		espOn = v
		if not v then for p in pairs(espData) do removeESP(p) end end
	end)
	ui:CfgRegister("mm2_esp_on", function() return espOn end, function(v) t_esp.Set(v) end)

	local s_dist = sec:Slider("max distance", 50, 1000, 300, function(v) maxDist = v end)
	ui:CfgRegister("mm2_esp_dist", function() return maxDist end, function(v) s_dist.Set(v) end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: CONFIG
-- ══════════════════════════════════════════════════════════════════════════════
-- BuildConfigTab monta a seção de save/load/dropdown automaticamente
-- O segundo argumento é o nome da pasta onde salva os configs (separado do ref_ui universal)
ui:BuildConfigTab(configTab, "ref_mm2")

-- ── Toast de boas-vindas ──────────────────────────────────────────────────────
task.delay(0.5, function()
	ui:Toast(
		"rbxassetid://131165537896572",
		"mm2 ui carregado",
		"bem-vindo, " .. player.DisplayName,
		Color3.fromRGB(120, 80, 255)
	)
end)
