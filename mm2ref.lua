--[[
	mm2_ui.lua — Murder Mystery 2
	Depende da ref_lib.lua no GitHub.
	Troque LIB_URL pela URL raw do seu repositório.
--]]

local LIB_URL = "https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua"

local RefLib
local ok, err = pcall(function()
	RefLib = loadstring(game:HttpGet(LIB_URL, true))()
end)
if not ok or not RefLib then
	error("[mm2] falhou ao carregar ref_lib: " .. tostring(err))
end

-- ── Serviços ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local player           = Players.LocalPlayer

-- ── UI ────────────────────────────────────────────────────────────────────────
local ui = RefLib.new("mm2", "rbxassetid://131165537896572", "ref_mm2_ui")

-- ── Role detection ────────────────────────────────────────────────────────────
local function getPlayerRole(p)
	p = p or player
	local bp  = p:FindFirstChild("Backpack")
	local chr = p.Character
	local function has(name)
		if bp  and bp:FindFirstChild(name)  then return true end
		if chr and chr:FindFirstChild(name) then return true end
		return false
	end
	if has("Knife") then return "murderer" end
	if has("Gun") or has("Sheriff's Gun") or has("Revolver") then return "sheriff" end
	return "innocent"
end

-- Encontra o murderer (player com faca) excluindo o proprio jogador
local function findMurderer()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local role = getPlayerRole(p)
			if role == "murderer" then
				local chr = p.Character
				local hum = chr and chr:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then return p end
			end
		end
	end
	return nil
end

-- Encontra o xerife excluindo o proprio jogador
local function findSheriff()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local role = getPlayerRole(p)
			if role == "sheriff" then
				local chr = p.Character
				local hum = chr and chr:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then return p end
			end
		end
	end
	return nil
end

local ROLE_COLOR = {
	murderer = Color3.fromRGB(220, 60,  60),
	sheriff  = Color3.fromRGB(60,  180, 220),
	innocent = Color3.fromRGB(80,  220, 80),
	unknown  = Color3.fromRGB(150, 150, 150),
}
local ROLE_ICON = {
	murderer = "Murderer",
	sheriff  = "Sheriff",
	innocent = "Innocent",
	unknown  = "?",
}

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local tabMain   = ui:Tab("main")
local tabESP    = ui:Tab("esp")
local tabCombat = ui:Tab("combat")
local tabFarm   = ui:Tab("farm")
local tabCfg    = ui:Tab("config")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: MAIN
-- ══════════════════════════════════════════════════════════════════════════════
do

-- ── Round Info ────────────────────────────────────────────────────────────────
local secInfo = tabMain:Section("round info")
secInfo:Divider("my role")

secInfo:Button("check my role", function()
	local role  = getPlayerRole()
	local alive = 0
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if h and h.Health > 0 then alive = alive + 1 end
	end
	local col = ROLE_COLOR[role] or ROLE_COLOR.unknown
	ui:Toast("rbxassetid://131165537896572",
		"[" .. ROLE_ICON[role] .. "] " .. role,
		"vivos: " .. alive .. "  |  " .. player.DisplayName, col)
end)

secInfo:Button("scan all roles", function()
	local found = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local role = getPlayerRole(p)
		if role ~= "innocent" then
			table.insert(found, {p=p, role=role})
		end
	end
	if #found == 0 then
		ui:Toast("rbxassetid://131165537896572", "scan roles",
			"nenhum murderer/sheriff detectado", ROLE_COLOR.innocent)
		return
	end
	for _, info in ipairs(found) do
		local col = ROLE_COLOR[info.role]
		task.spawn(function()
			ui:Toast("rbxassetid://131165537896572",
				"[" .. ROLE_ICON[info.role] .. "] " .. info.p.DisplayName,
				"@" .. info.p.Name, col)
		end)
		task.wait(0.35)
	end
end)

-- ── Role ESP ──────────────────────────────────────────────────────────────────
secInfo:Divider("role esp")

local roleEspOn  = false
local roleEspData = {}

local function removeRoleEsp(p)
	local d = roleEspData[p]; if not d then return end
	if d.hl and d.hl.Parent then d.hl:Destroy() end
	if d.bb and d.bb.Parent then d.bb:Destroy() end
	roleEspData[p] = nil
end

local function createRoleEsp(p)
	if roleEspData[p] then return end
	local char = p.Character; if not char then return end
	local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	local role = getPlayerRole(p)
	local col  = ROLE_COLOR[role]

	local hl = Instance.new("Highlight")
	hl.FillColor = col; hl.OutlineColor = Color3.fromRGB(255,255,255)
	hl.FillTransparency = 0.40; hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = char; hl.Parent = char

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0,130,0,38); bb.StudsOffset = Vector3.new(0,3.2,0)
	bb.AlwaysOnTop = true; bb.ResetOnSpawn = false; bb.Adornee = hrp; bb.Parent = hrp

	local nm = Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,18)
	nm.Font=Enum.Font.GothamBold; nm.TextSize=13; nm.TextColor3=Color3.fromRGB(255,255,255)
	nm.TextStrokeTransparency=0.15; nm.TextStrokeColor3=Color3.fromRGB(0,0,0)
	nm.TextXAlignment=Enum.TextXAlignment.Center; nm.Text=p.DisplayName; nm.Parent=bb

	local rl = Instance.new("TextLabel"); rl.BackgroundTransparency=1; rl.Size=UDim2.new(1,0,0,14)
	rl.Position=UDim2.new(0,0,0,20); rl.Font=Enum.Font.GothamSemibold; rl.TextSize=11
	rl.TextColor3=col; rl.TextStrokeTransparency=0.2; rl.TextStrokeColor3=Color3.fromRGB(0,0,0)
	rl.TextXAlignment=Enum.TextXAlignment.Center
	rl.Text="[" .. ROLE_ICON[role] .. "]"; rl.Parent=bb

	roleEspData[p] = {hl=hl, bb=bb, nm=nm, rl=rl}
end

RunService.RenderStepped:Connect(function()
	if not roleEspOn then return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p == player then continue end
		local char = p.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not char or not hum or hum.Health <= 0 then removeRoleEsp(p); continue end
		if not roleEspData[p] then createRoleEsp(p) end
		local d = roleEspData[p]; if not d then continue end
		local role = getPlayerRole(p); local col = ROLE_COLOR[role]
		d.hl.FillColor = col; d.rl.TextColor3 = col
		d.rl.Text = "[" .. ROLE_ICON[role] .. "]"; d.nm.Text = p.DisplayName
	end
end)

Players.PlayerRemoving:Connect(removeRoleEsp)
for _, p in ipairs(Players:GetPlayers()) do
	if p ~= player then p.CharacterAdded:Connect(function()
		removeRoleEsp(p); task.wait(1); if roleEspOn then createRoleEsp(p) end
	end) end
end
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function() task.wait(1); if roleEspOn then createRoleEsp(p) end end)
end)

local t_roleEsp = secInfo:Toggle("role esp", false, function(v)
	roleEspOn = v
	if not v then for p in pairs(roleEspData) do removeRoleEsp(p) end end
end)
ui:CfgRegister("mm2_role_esp", function() return roleEspOn end, function(v) t_roleEsp.Set(v) end)

-- ── Items (faca/gun dropados) ─────────────────────────────────────────────────
local secItems = tabMain:Section("items")
secItems:Divider("knife / gun")

local itemEspOn = false
local itemBBs   = {}

local function isTrackedItem(obj)
	if not (obj:IsA("Tool") or obj:IsA("Model")) then return false end
	local n = obj.Name
	return n == "Knife" or n == "Gun" or n == "Sheriff's Gun" or n == "Revolver"
end

local function getItemColor(name)
	if name == "Knife" then return Color3.fromRGB(220,60,60), "[Knife]" end
	return Color3.fromRGB(60,180,220), "[Gun]"
end

local function removeItemBB(tool)
	if itemBBs[tool] and itemBBs[tool].Parent then itemBBs[tool]:Destroy() end
	itemBBs[tool] = nil
end

local function makeItemBB(tool)
	if itemBBs[tool] then return end
	local adornee = tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart")
	if not adornee then
		task.spawn(function()
			local h = tool:WaitForChild("Handle", 3)
			if h and itemEspOn and not itemBBs[tool] then makeItemBB(tool) end
		end)
		return
	end
	local col, label = getItemColor(tool.Name)

	local bb = Instance.new("BillboardGui")
	bb.Size=UDim2.new(0,100,0,40); bb.StudsOffset=Vector3.new(0,3.5,0)
	bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Adornee=adornee; bb.Parent=adornee
	bb.Enabled = itemEspOn

	local nm = Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,20)
	nm.Font=Enum.Font.GothamBold; nm.TextSize=13; nm.TextColor3=col
	nm.TextStrokeTransparency=0.15; nm.TextStrokeColor3=Color3.fromRGB(0,0,0)
	nm.TextXAlignment=Enum.TextXAlignment.Center; nm.Text=label; nm.Parent=bb

	local dl = Instance.new("TextLabel"); dl.BackgroundTransparency=1; dl.Size=UDim2.new(1,0,0,14)
	dl.Position=UDim2.new(0,0,0,22); dl.Font=Enum.Font.Gotham; dl.TextSize=10
	dl.TextColor3=Color3.fromRGB(200,200,220); dl.TextStrokeTransparency=0.3
	dl.TextStrokeColor3=Color3.fromRGB(0,0,0); dl.TextXAlignment=Enum.TextXAlignment.Center
	dl.Text=""; dl.Parent=bb

	itemBBs[tool] = bb

	RunService.RenderStepped:Connect(function()
		if not itemEspOn or not bb.Parent then return end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and adornee and adornee.Parent then
			dl.Text = math.floor((hrp.Position - adornee.Position).Magnitude) .. "m"
		end
	end)

	tool.AncestryChanged:Connect(function()
		if not tool.Parent then removeItemBB(tool) end
	end)
end

local function scanItems()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if isTrackedItem(obj) then task.spawn(makeItemBB, obj) end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local bp = p:FindFirstChild("Backpack")
		if bp then for _, obj in ipairs(bp:GetChildren()) do
			if isTrackedItem(obj) then task.spawn(makeItemBB, obj) end
		end end
	end
end

workspace.DescendantAdded:Connect(function(obj)
	if itemEspOn and isTrackedItem(obj) then task.spawn(makeItemBB, obj) end
end)
Players.PlayerAdded:Connect(function(p)
	local bp = p:WaitForChild("Backpack")
	bp.ChildAdded:Connect(function(obj)
		if itemEspOn and isTrackedItem(obj) then task.spawn(makeItemBB, obj) end
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do
	local bp = p:FindFirstChild("Backpack")
	if bp then bp.ChildAdded:Connect(function(obj)
		if itemEspOn and isTrackedItem(obj) then task.spawn(makeItemBB, obj) end
	end) end
end

local t_itemEsp = secItems:Toggle("knife + gun esp", false, function(v)
	itemEspOn = v
	if v then scanItems() end
	for _, bb in pairs(itemBBs) do bb.Enabled = v end
end)
ui:CfgRegister("mm2_item_esp", function() return itemEspOn end, function(v) t_itemEsp.Set(v) end)

local function tpToItem(name)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Tool") and (obj.Name == name or (name == "Gun" and (obj.Name == "Sheriff's Gun" or obj.Name == "Revolver"))) then
			local h = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
			if h then
				hrp.CFrame = CFrame.new(h.Position + Vector3.new(0,3,0))
				return true
			end
		end
	end
	return false
end

secItems:Button("tp to knife", function()
	if tpToItem("Knife") then
		ui:Toast("rbxassetid://131165537896572", "[Knife] teleportado", "faca encontrada!", ROLE_COLOR.murderer)
	else
		ui:Toast("rbxassetid://131165537896572", "tp to knife", "faca nao encontrada", ROLE_COLOR.unknown)
	end
end)

secItems:Button("tp to gun", function()
	if tpToItem("Gun") then
		ui:Toast("rbxassetid://131165537896572", "[Gun] teleportado", "gun encontrada!", ROLE_COLOR.sheriff)
	else
		ui:Toast("rbxassetid://131165537896572", "tp to gun", "gun nao encontrada", ROLE_COLOR.unknown)
	end
end)

-- ── Coins ─────────────────────────────────────────────────────────────────────
local secCoins = tabMain:Section("coins")
secCoins:Divider("esp + collect")

local coinEspOn = false
local coinBBs   = {}

local function isCoin(obj)
	local n = obj.Name:lower()
	return n == "coin" or n == "goldcoin" or n == "value" or n:find("coin")
end

local function removeCoinBB(part)
	if coinBBs[part] and coinBBs[part].Parent then coinBBs[part]:Destroy() end
	coinBBs[part] = nil
end

local function makeCoinBB(obj)
	local part = obj:IsA("BasePart") and obj
		or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
	if not part or coinBBs[part] then return end

	local bb = Instance.new("BillboardGui")
	bb.Size=UDim2.new(0,40,0,28); bb.StudsOffset=Vector3.new(0,2.5,0)
	bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Adornee=part; bb.Parent=part; bb.Enabled=coinEspOn

	local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0)
	lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextColor3=Color3.fromRGB(255,210,50)
	lbl.TextStrokeTransparency=0.15; lbl.TextStrokeColor3=Color3.fromRGB(0,0,0)
	lbl.TextXAlignment=Enum.TextXAlignment.Center; lbl.Text="$"; lbl.Parent=bb

	coinBBs[part] = bb
	obj.AncestryChanged:Connect(function() if not obj.Parent then removeCoinBB(part) end end)
end

local function scanCoins()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if isCoin(obj) then task.spawn(makeCoinBB, obj) end
	end
end

workspace.DescendantAdded:Connect(function(obj)
	if coinEspOn and isCoin(obj) then task.spawn(makeCoinBB, obj) end
end)

local t_coinEsp = secCoins:Toggle("coin esp", false, function(v)
	coinEspOn = v
	if v then scanCoins() end
	for _, bb in pairs(coinBBs) do bb.Enabled = v end
end)
ui:CfgRegister("mm2_coin_esp", function() return coinEspOn end, function(v) t_coinEsp.Set(v) end)

secCoins:Button("collect all coins", function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local coins = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if isCoin(obj) then
			local part = obj:IsA("BasePart") and obj
				or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
			if part then table.insert(coins, part) end
		end
	end
	if #coins == 0 then
		ui:Toast("rbxassetid://131165537896572", "coins", "nenhuma moeda no mapa", ROLE_COLOR.unknown)
		return
	end
	ui:Toast("rbxassetid://131165537896572", "[Coins] coletando", tostring(#coins) .. " moedas...", Color3.fromRGB(255,210,50))
	task.spawn(function()
		for _, part in ipairs(coins) do
			if part and part.Parent then
				hrp.CFrame = CFrame.new(part.Position); task.wait(0.07)
			end
		end
		ui:Toast("rbxassetid://131165537896572", "[Coins] done", "coleta finalizada!", Color3.fromRGB(255,210,50))
	end)
end)

-- ── Movement ──────────────────────────────────────────────────────────────────
local secMove = tabMain:Section("movement")
secMove:Divider("speed")

local DEFAULT_SPEED = 16
local speedOn = false; local curSpeed = 24
local function applySpeed()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = speedOn and curSpeed or DEFAULT_SPEED end
end
player.CharacterAdded:Connect(function(c) c:WaitForChild("Humanoid"); task.wait(); applySpeed() end)

local t_spd = secMove:Toggle("fast walk", false, function(v) speedOn=v; applySpeed() end)
ui:CfgRegister("mm2_speed_on",  function() return speedOn  end, function(v) t_spd.Set(v) end)
local s_spd = secMove:Slider("speed", 8, 80, 24, function(v) curSpeed=v; if speedOn then applySpeed() end end)
ui:CfgRegister("mm2_speed_val", function() return curSpeed end, function(v) s_spd.Set(v) end)

secMove:Divider("misc")
local jumpOn=false; local jumpConn=nil
local t_jump = secMove:Toggle("infinite jump", false, function(v)
	jumpOn=v
	if jumpConn then jumpConn:Disconnect(); jumpConn=nil end
	if v then jumpConn = UserInputService.JumpRequest:Connect(function()
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end) end
end)
ui:CfgRegister("mm2_infjump", function() return jumpOn end, function(v) t_jump.Set(v) end)

local noclipOn = false
RunService.Stepped:Connect(function()
	if not noclipOn then return end
	local char = player.Character; if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
	end
end)
local t_noclip = secMove:Toggle("noclip", false, function(v)
	noclipOn = v
	if not v then
		local char = player.Character; if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = true end
		end
	end
end)
ui:CfgRegister("mm2_noclip", function() return noclipOn end, function(v) t_noclip.Set(v) end)

end -- TAB MAIN

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: ESP
-- ══════════════════════════════════════════════════════════════════════════════
do

local sec    = tabESP:Section("players")
local espOn  = false
local espData = {}
local maxDist = 300
local camera  = workspace.CurrentCamera

local function hpCol(hp, mxh)
	local pct = math.clamp(hp/math.max(mxh,1),0,1)
	if pct > 0.6 then return Color3.fromRGB(80,220,80)
	elseif pct > 0.3 then return Color3.fromRGB(240,200,40)
	else return Color3.fromRGB(220,60,60) end
end

local function removeESP(p)
	local d=espData[p]; if not d then return end
	if d.hl and d.hl.Parent then d.hl:Destroy() end
	if d.bb and d.bb.Parent then d.bb:Destroy() end
	espData[p]=nil
end

local function createESP(p)
	if espData[p] then return end
	local char=p.Character; if not char then return end
	local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	local role=getPlayerRole(p); local col=ROLE_COLOR[role]

	local hl=Instance.new("Highlight"); hl.FillColor=col; hl.OutlineColor=Color3.fromRGB(255,255,255)
	hl.FillTransparency=0.45; hl.OutlineTransparency=0
	hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee=char; hl.Parent=char

	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,130,0,56); bb.StudsOffset=Vector3.new(0,3.4,0)
	bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Adornee=hrp; bb.Parent=hrp

	local nm=Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,0,0,18)
	nm.Font=Enum.Font.GothamBold; nm.TextSize=13; nm.TextColor3=Color3.fromRGB(255,255,255)
	nm.TextStrokeTransparency=0.15; nm.TextStrokeColor3=Color3.fromRGB(0,0,0)
	nm.TextXAlignment=Enum.TextXAlignment.Center; nm.Text=p.DisplayName; nm.Parent=bb

	local rl=Instance.new("TextLabel"); rl.BackgroundTransparency=1; rl.Size=UDim2.new(1,0,0,14)
	rl.Position=UDim2.new(0,0,0,18); rl.Font=Enum.Font.GothamSemibold; rl.TextSize=10
	rl.TextColor3=col; rl.TextStrokeTransparency=0.2; rl.TextStrokeColor3=Color3.fromRGB(0,0,0)
	rl.TextXAlignment=Enum.TextXAlignment.Center; rl.Text="["..ROLE_ICON[role].."]"; rl.Parent=bb

	local hpBg=Instance.new("Frame"); hpBg.Size=UDim2.new(1,0,0,4); hpBg.Position=UDim2.new(0,0,0,35)
	hpBg.BackgroundColor3=Color3.fromRGB(25,25,25); hpBg.BackgroundTransparency=0.3; hpBg.BorderSizePixel=0; hpBg.Parent=bb
	local uc=Instance.new("UICorner"); uc.CornerRadius=UDim.new(1,0); uc.Parent=hpBg
	local hpFill=Instance.new("Frame"); hpFill.Size=UDim2.new(1,0,1,0)
	hpFill.BackgroundColor3=Color3.fromRGB(80,220,80); hpFill.BorderSizePixel=0; hpFill.Parent=hpBg
	local uc2=Instance.new("UICorner"); uc2.CornerRadius=UDim.new(1,0); uc2.Parent=hpFill

	local dl=Instance.new("TextLabel"); dl.BackgroundTransparency=1; dl.Size=UDim2.new(1,0,0,12)
	dl.Position=UDim2.new(0,0,0,43); dl.Font=Enum.Font.Gotham; dl.TextSize=10
	dl.TextColor3=Color3.fromRGB(200,200,220); dl.TextStrokeTransparency=0.3
	dl.TextStrokeColor3=Color3.fromRGB(0,0,0); dl.TextXAlignment=Enum.TextXAlignment.Center; dl.Parent=bb

	espData[p]={hl=hl,bb=bb,nm=nm,rl=rl,hpBg=hpBg,hpFill=hpFill,dl=dl}
end

RunService.RenderStepped:Connect(function()
	if not espOn then return end
	for _, p in ipairs(Players:GetPlayers()) do
		if p==player then continue end
		local char=p.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
		local hrp=char and char:FindFirstChild("HumanoidRootPart")
		if not char or not hum or not hrp or hum.Health<=0 then removeESP(p); continue end
		local dist=math.floor((camera.CFrame.Position-hrp.Position).Magnitude)
		if dist>maxDist then removeESP(p); continue end
		if not espData[p] then createESP(p) end
		local d=espData[p]; if not d then continue end
		local role=getPlayerRole(p); local col=ROLE_COLOR[role]
		d.hl.FillColor=col; d.rl.TextColor3=col; d.rl.Text="["..ROLE_ICON[role].."]"; d.nm.Text=p.DisplayName
		local pct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
		d.hpFill.Size=UDim2.new(pct,0,1,0); d.hpFill.BackgroundColor3=hpCol(hum.Health,hum.MaxHealth)
		d.dl.Text=dist.."m"
	end
end)

Players.PlayerRemoving:Connect(removeESP)
for _, p in ipairs(Players:GetPlayers()) do
	if p~=player then p.CharacterAdded:Connect(function()
		removeESP(p); task.wait(1); if espOn then createESP(p) end
	end) end
end
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function() task.wait(1); if espOn then createESP(p) end end)
end)

local t_esp=sec:Toggle("player esp (role color)", false, function(v)
	espOn=v
	if not v then for p in pairs(espData) do removeESP(p) end end
end)
ui:CfgRegister("mm2_esp_on",   function() return espOn    end, function(v) t_esp.Set(v)   end)
local s_dist=sec:Slider("max distance", 50, 1000, 300, function(v) maxDist=v end)
ui:CfgRegister("mm2_esp_dist", function() return maxDist  end, function(v) s_dist.Set(v)  end)

end -- TAB ESP

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: COMBAT
-- ══════════════════════════════════════════════════════════════════════════════
do

-- ── Sheriff: Auto Shoot ───────────────────────────────────────────────────────
local secSheriff = tabCombat:Section("sheriff")
secSheriff:Divider("auto shoot")

local autoShootOn   = false
local autoShootConn = nil
local lastShotTime  = 0
local SHOT_COOLDOWN = 0.6  -- segundos entre tiros

-- Tenta atirar no alvo usando a gun equipada
local function tryShoot(targetChar)
	local myChar = player.Character
	if not myChar then return end
	local hrp = myChar:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Verifica se tem gun equipada
	local gun = myChar:FindFirstChild("Gun")
		or myChar:FindFirstChild("Sheriff's Gun")
		or myChar:FindFirstChild("Revolver")
	if not gun then
		-- Tenta pegar do backpack
		local bp = player.Backpack
		gun = bp and (bp:FindFirstChild("Gun") or bp:FindFirstChild("Sheriff's Gun") or bp:FindFirstChild("Revolver"))
		if gun then
			-- Equipa a arma
			player.Character.Humanoid:EquipTool(gun)
			task.wait(0.15)
			gun = myChar:FindFirstChild("Gun")
				or myChar:FindFirstChild("Sheriff's Gun")
				or myChar:FindFirstChild("Revolver")
		end
	end
	if not gun then return end

	local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
		or targetChar:FindFirstChild("Head")
	if not targetHrp then return end

	-- Aponta camera / character na direção do alvo e dispara
	local dist = (hrp.Position - targetHrp.Position).Magnitude
	if dist > 250 then return end  -- fora do alcance

	-- Usa FireServer se disponível (método mais confiável)
	local fired = false
	pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		-- Procura RemoteEvent de tiro no ReplicatedStorage
		for _, v in ipairs(rs:GetDescendants()) do
			if v:IsA("RemoteEvent") and (
				v.Name:lower():find("shoot") or
				v.Name:lower():find("fire") or
				v.Name:lower():find("gun") or
				v.Name:lower():find("bullet")
			) then
				v:FireServer(targetHrp.Position, targetHrp)
				fired = true
				break
			end
		end
	end)

	-- Fallback: ativa evento Activated da tool diretamente
	if not fired then
		pcall(function()
			-- Posiciona o HRP olhando para o alvo antes de atirar
			hrp.CFrame = CFrame.lookAt(hrp.Position, targetHrp.Position)
			gun:Activate()
		end)
	end
end

local function autoShootLoop()
	while autoShootOn do
		task.wait(0.1)
		local myRole = getPlayerRole()
		if myRole ~= "sheriff" then continue end
		if tick() - lastShotTime < SHOT_COOLDOWN then continue end

		local murderer = findMurderer()
		if not murderer then continue end

		local mChar = murderer.Character
		local mHum  = mChar and mChar:FindFirstChildOfClass("Humanoid")
		if not mChar or not mHum or mHum.Health <= 0 then continue end

		-- Verifica distancia
		local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local mHrp  = mChar:FindFirstChild("HumanoidRootPart")
		if not myHrp or not mHrp then continue end
		local dist = (myHrp.Position - mHrp.Position).Magnitude
		if dist > 200 then continue end

		lastShotTime = tick()
		tryShoot(mChar)
	end
end

local t_autoShoot = secSheriff:Toggle("auto shoot murderer", false, function(v)
	autoShootOn = v
	if v then
		local myRole = getPlayerRole()
		if myRole ~= "sheriff" then
			ui:Toast("rbxassetid://131165537896572", "[Auto Shoot]",
				"voce nao e xerife!", ROLE_COLOR.unknown)
		else
			ui:Toast("rbxassetid://131165537896572", "[Auto Shoot] ativado",
				"atirando no murderer automaticamente", ROLE_COLOR.sheriff)
		end
		task.spawn(autoShootLoop)
	else
		ui:Toast("rbxassetid://131165537896572", "[Auto Shoot] desativado", "", ROLE_COLOR.unknown)
	end
end)
ui:CfgRegister("mm2_autoshoot", function() return autoShootOn end, function(v) t_autoShoot.Set(v) end)

local s_shotCd = secSheriff:Slider("cooldown (s x10)", 1, 30, 6, function(v)
	SHOT_COOLDOWN = v / 10
end)
ui:CfgRegister("mm2_shot_cd", function() return SHOT_COOLDOWN * 10 end, function(v) s_shotCd.Set(v) end)

secSheriff:Divider("shoot button flutuante")

-- ── Floating Shoot Button ─────────────────────────────────────────────────────
-- Cria um botão arrastável na tela que, ao clicar, atira no murderer
local floatBtn      = nil
local floatBtnOn    = false
local floatDragging = false
local floatDragOff  = Vector2.new(0, 0)
local shootCooldown = false

local function destroyFloatBtn()
	if floatBtn and floatBtn.Parent then floatBtn:Destroy() end
	floatBtn = nil
end

local function createFloatBtn()
	destroyFloatBtn()

	local sg = Instance.new("ScreenGui")
	sg.Name = "MM2ShootBtn"; sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = player.PlayerGui

	-- Frame externo (sombra / borda)
	local shadow = Instance.new("Frame")
	shadow.Size = UDim2.new(0, 108, 0, 108)
	shadow.Position = UDim2.new(0, 60, 0.5, -54)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.4
	shadow.BorderSizePixel = 0
	shadow.Parent = sg
	Instance.new("UICorner", shadow).CornerRadius = UDim.new(1, 0)

	-- Botão principal
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 100, 0, 100)
	btn.Position = UDim2.new(0, 4, 0, 4)
	btn.BackgroundColor3 = Color3.fromRGB(30, 120, 220)
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = shadow
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

	-- Gradiente
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 180, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20,  80, 200)),
	})
	grad.Rotation = 120; grad.Parent = btn

	-- Ícone de mira (🎯) + label
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0.55, 0)
	icon.Position = UDim2.new(0, 0, 0.05, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "🔫"; icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.Parent = btn

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0.35, 0)
	lbl.Position = UDim2.new(0, 0, 0.63, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "SHOOT"; lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeTransparency = 0.3
	lbl.Parent = btn

	-- Cooldown overlay (escurece o botão durante recarga)
	local cdOverlay = Instance.new("Frame")
	cdOverlay.Size = UDim2.new(1, 0, 1, 0)
	cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cdOverlay.BackgroundTransparency = 1
	cdOverlay.BorderSizePixel = 0
	cdOverlay.ZIndex = 5
	cdOverlay.Visible = false
	cdOverlay.Parent = btn
	Instance.new("UICorner", cdOverlay).CornerRadius = UDim.new(1, 0)

	local cdLbl = Instance.new("TextLabel")
	cdLbl.Size = UDim2.new(1, 0, 1, 0)
	cdLbl.BackgroundTransparency = 1
	cdLbl.Font = Enum.Font.GothamBold; cdLbl.TextScaled = true
	cdLbl.TextColor3 = Color3.fromRGB(255, 255, 100)
	cdLbl.ZIndex = 6; cdLbl.Parent = cdOverlay

	floatBtn = sg

	-- ── Drag ──────────────────────────────────────────────────────────────────
	btn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			floatDragging = true
			local absPos = shadow.AbsolutePosition
			floatDragOff = Vector2.new(
				inp.Position.X - absPos.X,
				inp.Position.Y - absPos.Y
			)
		end
	end)

	UserInputService.InputChanged:Connect(function(inp)
		if not floatDragging then return end
		if inp.UserInputType == Enum.UserInputType.MouseMovement
		or inp.UserInputType == Enum.UserInputType.Touch then
			local vp = workspace.CurrentCamera.ViewportSize
			local nx = math.clamp(inp.Position.X - floatDragOff.X, 0, vp.X - shadow.AbsoluteSize.X)
			local ny = math.clamp(inp.Position.Y - floatDragOff.Y, 0, vp.Y - shadow.AbsoluteSize.Y)
			shadow.Position = UDim2.new(0, nx, 0, ny)
		end
	end)

	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			floatDragging = false
		end
	end)

	-- ── Click: dispara ─────────────────────────────────────────────────────────
	btn.MouseButton1Click:Connect(function()
		if floatDragging then return end  -- ignora clique ao soltar drag
		if shootCooldown then return end

		local myRole = getPlayerRole()
		if myRole ~= "sheriff" then
			-- Pisca vermelho: não é xerife
			btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
			lbl.Text = "NO GUN"
			task.delay(0.8, function()
				btn.BackgroundColor3 = Color3.fromRGB(30, 120, 220)
				lbl.Text = "SHOOT"
			end)
			return
		end

		local murderer = findMurderer()
		if not murderer then
			btn.BackgroundColor3 = Color3.fromRGB(150, 150, 40)
			lbl.Text = "??"
			task.delay(0.8, function()
				btn.BackgroundColor3 = Color3.fromRGB(30, 120, 220)
				lbl.Text = "SHOOT"
			end)
			return
		end

		-- Dispara!
		shootCooldown = true
		tryShoot(murderer.Character)

		-- Feedback visual: pisca verde → cooldown overlay
		btn.BackgroundColor3 = Color3.fromRGB(40, 200, 80)
		lbl.Text = "💥"
		task.wait(0.15)

		-- Cooldown visual (1s)
		btn.BackgroundColor3 = Color3.fromRGB(30, 120, 220)
		lbl.Text = "SHOOT"
		cdOverlay.Visible = true
		cdOverlay.BackgroundTransparency = 0.45
		local cdTime = 1.0
		local elapsed = 0
		local step = 0.05
		while elapsed < cdTime do
			task.wait(step)
			elapsed = elapsed + step
			local remaining = math.ceil(cdTime - elapsed)
			cdLbl.Text = tostring(remaining)
		end
		cdOverlay.Visible = false
		shootCooldown = false
		lbl.Text = "SHOOT"
	end)

	-- Tooltip ao hover
	btn.MouseEnter:Connect(function()
		if not shootCooldown then
			TweenService:Create(btn, TweenInfo.new(0.12), {Size = UDim2.new(0,106,0,106), Position = UDim2.new(0,-3,0,-3)}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {Size = UDim2.new(0,100,0,100), Position = UDim2.new(0,4,0,4)}):Play()
	end)
end

local t_floatBtn = secSheriff:Toggle("shoot button flutuante", false, function(v)
	floatBtnOn = v
	if v then
		createFloatBtn()
		ui:Toast("rbxassetid://131165537896572", "[Shoot Btn] criado",
			"arraste o botão pela tela e clique pra atirar", ROLE_COLOR.sheriff)
	else
		destroyFloatBtn()
		ui:Toast("rbxassetid://131165537896572", "[Shoot Btn] removido", "", ROLE_COLOR.unknown)
	end
end)
ui:CfgRegister("mm2_floatbtn", function() return floatBtnOn end, function(v) t_floatBtn.Set(v) end)

-- Garante que o botão é destruído ao respawnar
player.CharacterAdded:Connect(function()
	if floatBtnOn then task.wait(1); createFloatBtn() end
end)

secSheriff:Divider("tp & aim")

secSheriff:Button("tp to murderer", function()
	local murderer = findMurderer()
	if not murderer then
		ui:Toast("rbxassetid://131165537896572", "tp murderer", "nenhum murderer detectado", ROLE_COLOR.unknown)
		return
	end
	local mHrp = murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")
	local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if mHrp and myHrp then
		myHrp.CFrame = mHrp.CFrame * CFrame.new(0, 0, -4)
		ui:Toast("rbxassetid://131165537896572", "[TP] murderer",
			"teleportado para " .. murderer.DisplayName, ROLE_COLOR.murderer)
	end
end)

secSheriff:Button("shoot murderer (once)", function()
	local myRole = getPlayerRole()
	if myRole ~= "sheriff" then
		ui:Toast("rbxassetid://131165537896572", "[Shoot]", "voce nao e xerife!", ROLE_COLOR.unknown)
		return
	end
	local murderer = findMurderer()
	if not murderer then
		ui:Toast("rbxassetid://131165537896572", "[Shoot]", "murderer nao detectado", ROLE_COLOR.unknown)
		return
	end
	tryShoot(murderer.Character)
	ui:Toast("rbxassetid://131165537896572", "[Shoot] disparado!",
		"alvo: " .. murderer.DisplayName, ROLE_COLOR.sheriff)
end)

-- ── Murderer: Knife Aura ──────────────────────────────────────────────────────
local secMurd = tabCombat:Section("murderer")
secMurd:Divider("knife aura")

local knifeAuraOn    = false
local knifeAuraRange = 12
local knifeAuraCd    = 0.5
local lastKnifeTime  = 0

local function tryThrowKnife(targetChar)
	local myChar = player.Character
	if not myChar then return end
	local hrp = myChar:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local knife = myChar:FindFirstChild("Knife")
	if not knife then
		local bp = player.Backpack
		knife = bp and bp:FindFirstChild("Knife")
		if knife then
			player.Character.Humanoid:EquipTool(knife)
			task.wait(0.1)
			knife = myChar:FindFirstChild("Knife")
		end
	end
	if not knife then return end

	local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
		or targetChar:FindFirstChild("Head")
	if not targetHrp then return end

	-- Tenta FireServer do knife
	local fired = false
	pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		for _, v in ipairs(rs:GetDescendants()) do
			if v:IsA("RemoteEvent") and (
				v.Name:lower():find("knife") or
				v.Name:lower():find("throw") or
				v.Name:lower():find("kill") or
				v.Name:lower():find("stab")
			) then
				v:FireServer(targetHrp.Position, targetHrp)
				fired = true
				break
			end
		end
	end)

	if not fired then
		pcall(function()
			hrp.CFrame = CFrame.lookAt(hrp.Position, targetHrp.Position)
			knife:Activate()
		end)
	end
end

local function knifeAuraLoop()
	while knifeAuraOn do
		task.wait(0.1)
		local myRole = getPlayerRole()
		if myRole ~= "murderer" then continue end
		if tick() - lastKnifeTime < knifeAuraCd then continue end

		local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not myHrp then continue end

		-- Encontra inocente mais próximo dentro do range
		local closest, closestDist = nil, knifeAuraRange
		for _, p in ipairs(Players:GetPlayers()) do
			if p == player then continue end
			local chr = p.Character
			local hum = chr and chr:FindFirstChildOfClass("Humanoid")
			local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
			if not chr or not hum or not hrp or hum.Health <= 0 then continue end
			local dist = (myHrp.Position - hrp.Position).Magnitude
			if dist < closestDist then
				closest = p; closestDist = dist
			end
		end

		if closest then
			lastKnifeTime = tick()
			tryThrowKnife(closest.Character)
		end
	end
end

local t_knifeAura = secMurd:Toggle("knife aura (auto kill nearby)", false, function(v)
	knifeAuraOn = v
	if v then
		local myRole = getPlayerRole()
		if myRole ~= "murderer" then
			ui:Toast("rbxassetid://131165537896572", "[Knife Aura]",
				"voce nao e murderer!", ROLE_COLOR.unknown)
		else
			ui:Toast("rbxassetid://131165537896572", "[Knife Aura] ativado",
				"matando jogadores proximos", ROLE_COLOR.murderer)
		end
		task.spawn(knifeAuraLoop)
	else
		ui:Toast("rbxassetid://131165537896572", "[Knife Aura] desativado", "", ROLE_COLOR.unknown)
	end
end)
ui:CfgRegister("mm2_knife_aura", function() return knifeAuraOn end, function(v) t_knifeAura.Set(v) end)

local s_knifeRange = secMurd:Slider("range (studs)", 4, 50, 12, function(v)
	knifeAuraRange = v
end)
ui:CfgRegister("mm2_knife_range", function() return knifeAuraRange end, function(v) s_knifeRange.Set(v) end)

secMurd:Divider("tp & target")

secMurd:Button("tp to sheriff", function()
	local sheriff = findSheriff()
	if not sheriff then
		ui:Toast("rbxassetid://131165537896572", "tp sheriff", "nenhum sheriff detectado", ROLE_COLOR.unknown)
		return
	end
	local sHrp  = sheriff.Character and sheriff.Character:FindFirstChild("HumanoidRootPart")
	local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if sHrp and myHrp then
		myHrp.CFrame = sHrp.CFrame * CFrame.new(0, 0, -4)
		ui:Toast("rbxassetid://131165537896572", "[TP] sheriff",
			"teleportado para " .. sheriff.DisplayName, ROLE_COLOR.sheriff)
	end
end)

secMurd:Button("kill sheriff (once)", function()
	local myRole = getPlayerRole()
	if myRole ~= "murderer" then
		ui:Toast("rbxassetid://131165537896572", "[Kill]", "voce nao e murderer!", ROLE_COLOR.unknown)
		return
	end
	local sheriff = findSheriff()
	if not sheriff then
		ui:Toast("rbxassetid://131165537896572", "[Kill]", "sheriff nao detectado", ROLE_COLOR.unknown)
		return
	end
	tryThrowKnife(sheriff.Character)
	ui:Toast("rbxassetid://131165537896572", "[Kill] knife!",
		"alvo: " .. sheriff.DisplayName, ROLE_COLOR.murderer)
end)

-- ── Geral combat ─────────────────────────────────────────────────────────────
local secGen = tabCombat:Section("geral")
secGen:Divider("utilidades")

secGen:Button("listar alvos vivos", function()
	local murderer = findMurderer()
	local sheriff  = findSheriff()
	local alive    = 0
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
		if h and h.Health > 0 then alive = alive + 1 end
	end
	local mName = murderer and murderer.DisplayName or "desconhecido"
	local sName = sheriff and sheriff.DisplayName or "desconhecido"
	ui:Toast("rbxassetid://131165537896572", "murderer: " .. mName,
		"sheriff: " .. sName .. "  |  vivos: " .. alive, ROLE_COLOR.unknown)
end)

end -- TAB COMBAT

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: FARM
-- ══════════════════════════════════════════════════════════════════════════════
do

local secAutoFarm = tabFarm:Section("auto farm")
secAutoFarm:Divider("coin farm automático")

local farmOn      = false
local farmLoop    = nil
local farmDelay   = 0.08
local farmCoinsCollected = 0

-- Auto farm: TP para cada coin continuamente
local function startFarm()
	farmCoinsCollected = 0
	while farmOn do
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then task.wait(1); continue end

		local coins = {}
		for _, obj in ipairs(workspace:GetDescendants()) do
			local n = obj.Name:lower()
			if n == "coin" or n == "goldcoin" or (n:find("coin") and not n:find("bb")) then
				local part = obj:IsA("BasePart") and obj
					or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
				if part and part.Parent then table.insert(coins, part) end
			end
		end

		if #coins == 0 then
			task.wait(1)
			continue
		end

		-- Ordena por distância (pega os mais próximos primeiro)
		local myPos = hrp.Position
		table.sort(coins, function(a, b)
			return (a.Position - myPos).Magnitude < (b.Position - myPos).Magnitude
		end)

		for _, part in ipairs(coins) do
			if not farmOn then break end
			if part and part.Parent then
				hrp.CFrame = CFrame.new(part.Position)
				farmCoinsCollected = farmCoinsCollected + 1
				task.wait(farmDelay)
			end
		end

		task.wait(0.5)
	end
end

local t_farm = secAutoFarm:Toggle("auto farm coins", false, function(v)
	farmOn = v
	if v then
		ui:Toast("rbxassetid://131165537896572", "[Farm] iniciado",
			"coletando moedas automaticamente...", Color3.fromRGB(255,210,50))
		task.spawn(startFarm)
	else
		ui:Toast("rbxassetid://131165537896572", "[Farm] parado",
			"total coletado: " .. farmCoinsCollected .. " coins", Color3.fromRGB(255,210,50))
	end
end)
ui:CfgRegister("mm2_farm_on", function() return farmOn end, function(v) t_farm.Set(v) end)

local s_farmDelay = secAutoFarm:Slider("delay ms (menor = mais rápido)", 1, 30, 8, function(v)
	farmDelay = v / 100
end)
ui:CfgRegister("mm2_farm_delay", function() return farmDelay * 100 end, function(v) s_farmDelay.Set(v) end)

secAutoFarm:Button("status do farm", function()
	if farmOn then
		ui:Toast("rbxassetid://131165537896572", "[Farm] rodando",
			"coins coletadas nessa sessão: " .. farmCoinsCollected, Color3.fromRGB(255,210,50))
	else
		ui:Toast("rbxassetid://131165537896572", "[Farm] parado",
			"ative o toggle acima para iniciar", ROLE_COLOR.unknown)
	end
end)

-- ── Gun Grab Auto ────────────────────────────────────────────────────────────
local secGunGrab = tabFarm:Section("gun grab")
secGunGrab:Divider("auto pegar arma")

local gunGrabOn = false
local gunGrabConn = nil

local function startGunGrab()
	while gunGrabOn do
		task.wait(0.3)
		-- Só pega se inocente (sem role) e se a gun esta dropada no mapa
		local myRole = getPlayerRole()
		if myRole ~= "innocent" then task.wait(0.5); continue end

		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Tool") and (obj.Name == "Gun" or obj.Name == "Sheriff's Gun" or obj.Name == "Revolver") then
				local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
				if handle then
					hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0,2,0))
					task.wait(0.15)
					break
				end
			end
		end
	end
end

local t_gunGrab = secGunGrab:Toggle("auto pegar gun dropada", false, function(v)
	gunGrabOn = v
	if v then
		ui:Toast("rbxassetid://131165537896572", "[GunGrab] ativo",
			"buscando gun dropada no mapa...", ROLE_COLOR.sheriff)
		task.spawn(startGunGrab)
	else
		ui:Toast("rbxassetid://131165537896572", "[GunGrab] desativado", "", ROLE_COLOR.unknown)
	end
end)
ui:CfgRegister("mm2_gun_grab", function() return gunGrabOn end, function(v) t_gunGrab.Set(v) end)

-- ── AFK Farm ─────────────────────────────────────────────────────────────────
local secAfk = tabFarm:Section("afk")
secAfk:Divider("anti-afk")

local afkOn = false
local afkConn = nil

local t_afk = secAfk:Toggle("anti-afk", false, function(v)
	afkOn = v
	if afkConn then afkConn:Disconnect(); afkConn = nil end
	if v then
		afkConn = RunService.Heartbeat:Connect(function()
			local VU = pcall(function()
				game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
				task.wait()
				game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			end)
		end)
		ui:Toast("rbxassetid://131165537896572", "[Anti-AFK] ativo",
			"nao sera kickado por inatividade", Color3.fromRGB(200,200,255))
	else
		ui:Toast("rbxassetid://131165537896572", "[Anti-AFK] desativado", "", ROLE_COLOR.unknown)
	end
end)
ui:CfgRegister("mm2_afk", function() return afkOn end, function(v) t_afk.Set(v) end)

-- ── Round Survival ───────────────────────────────────────────────────────────
local secSurv = tabFarm:Section("survival")
secSurv:Divider("sobrevivência")

-- Loop que mantém o jogador fugindo do murderer quando é inocente
local surviveOn  = false
local FLEE_DIST  = 20  -- distância mínima do murderer

local function surviveLoop()
	while surviveOn do
		task.wait(0.2)
		local myRole = getPlayerRole()
		if myRole == "murderer" then task.wait(0.5); continue end

		local murderer = findMurderer()
		if not murderer then continue end

		local mChar = murderer.Character
		local mHrp  = mChar and mChar:FindFirstChild("HumanoidRootPart")
		local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not mHrp or not myHrp then continue end

		local dist = (myHrp.Position - mHrp.Position).Magnitude
		if dist < FLEE_DIST then
			-- Foge na direção oposta
			local fleeDir = (myHrp.Position - mHrp.Position).Unit
			local newPos  = myHrp.Position + fleeDir * 30
			myHrp.CFrame = CFrame.new(newPos)
		end
	end
end

local t_survive = secSurv:Toggle("auto flee murderer", false, function(v)
	surviveOn = v
	if v then
		ui:Toast("rbxassetid://131165537896572", "[Survive] ativo",
			"fugindo automaticamente do murderer", ROLE_COLOR.innocent)
		task.spawn(surviveLoop)
	else
		ui:Toast("rbxassetid://131165537896572", "[Survive] desativado", "", ROLE_COLOR.unknown)
	end
end)
ui:CfgRegister("mm2_survive", function() return surviveOn end, function(v) t_survive.Set(v) end)

local s_fleeRange = secSurv:Slider("flee range (studs)", 5, 60, 20, function(v)
	FLEE_DIST = v
end)
ui:CfgRegister("mm2_flee_range", function() return FLEE_DIST end, function(v) s_fleeRange.Set(v) end)

end -- TAB FARM

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB: CONFIG
-- ══════════════════════════════════════════════════════════════════════════════
ui:BuildConfigTab(tabCfg, "ref_mm2")

-- ── Toast boas-vindas ─────────────────────────────────────────────────────────
task.delay(0.8, function()
	local role = getPlayerRole()
	ui:Toast("rbxassetid://131165537896572",
		"mm2 loaded  [" .. ROLE_ICON[role] .. "]",
		"bem-vindo, " .. player.DisplayName,
		ROLE_COLOR[role])
end)
