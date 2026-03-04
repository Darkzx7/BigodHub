--[[
	mm2_ui.lua — Murder Mystery 2
	Depende da ref_lib.lua no GitHub.
	Troque LIB_URL pela URL raw do seu repositório.
--]]

local LIB_URL = ""https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua"

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
local player           = Players.LocalPlayer

-- ── UI ────────────────────────────────────────────────────────────────────────
local ui = RefLib.new("mm2", "rbxassetid://131165537896572", "ref_mm2_ui")

-- ── Role detection ────────────────────────────────────────────────────────────
-- No MM2 o papel é detectado pelo item que o player carrega:
--   Murderer  = tem "Knife"  no Backpack ou no Character
--   Sheriff   = tem "Gun" / "Sheriff's Gun" / "Revolver"
--   Innocent  = nenhum dos dois
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
local tabMain = ui:Tab("main")
local tabESP  = ui:Tab("esp")
local tabCfg  = ui:Tab("config")

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

	-- Distância em tempo real
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
	return n == "coin" or n == "goldcoin"
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
