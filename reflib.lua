--[[
	ref_lib.lua — UI Library standalone
	Uso:
		local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USER/SEU_REPO/main/ref_lib.lua"))()
		local ui = RefLib.new("meu script")
		local tab = ui:Tab("geral")
		local sec = tab:Section("opcoes")
		sec:Toggle("hack", false, function(v) end)
		sec:Slider("speed", 8, 100, 16, function(v) end)
		sec:Button("teleport", function() end)
		sec:TextInput("nick", "placeholder", function(text, enter) end)
	
	A lib retorna uma janela completa com:
	  - Ícone arrastável + toggle minimizar
	  - RightShift para minimizar/abrir
	  - Tabs na sidebar
	  - Sections com auto-resize
	  - Toggle, Slider, Button, TextInput, Divider, SplitButton, AvatarCard
	  - Toast notifications: ui:Toast(icon, titulo, subtitulo, color)
	  - ConfigRegistry: ui:CfgRegister(key, getfn, setfn)
	  - Seção de config pronta: ui:BuildConfigTab(tabObj)
--]]

local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local player          = Players.LocalPlayer
local pg              = player:WaitForChild("PlayerGui")

-- ── helpers internos ──────────────────────────────────────────────────────────
local function _tween(obj, props, t, style, dir)
	t = t or 0.15
	TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end
local function _corner(inst, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = inst; return c
end
local function _stroke(inst, th, tr, col)
	local s = Instance.new("UIStroke")
	s.Thickness = th or 1; s.Transparency = tr or 0.65
	s.Color = col or Color3.fromRGB(255,255,255)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst; return s
end
local function _pad(inst, p)
	local d = Instance.new("UIPadding")
	local u = UDim.new(0, p or 10)
	d.PaddingLeft = u; d.PaddingRight = u; d.PaddingTop = u; d.PaddingBottom = u
	d.Parent = inst; return d
end
local function _drag(handle, frame)
	local dragging, ds, sp = false, nil, nil
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; ds = inp.Position; sp = frame.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - ds
			frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
end

-- ── RefLib ────────────────────────────────────────────────────────────────────
local RefLib = {}
RefLib.__index = RefLib

function RefLib.new(name, iconId, guiName)
	local self = setmetatable({}, RefLib)

	-- Tema padrão (pode ser substituído antes de criar tabs)
	self.Theme = {
		Panel  = Color3.fromRGB(18, 18, 22),
		Panel2 = Color3.fromRGB(22, 22, 27),
		Stroke = Color3.fromRGB(255, 255, 255),
		Text   = Color3.fromRGB(235, 235, 240),
		Sub    = Color3.fromRGB(170, 170, 180),
		Accent = Color3.fromRGB(120, 80, 255),
		Line   = Color3.fromRGB(60, 60, 72),
	}

	self._name          = name or "ref"
	self._icon          = iconId or "rbxassetid://131165537896572"
	self._guiName       = guiName or ("ref_ui_" .. (name or "script"):lower():gsub("%s","_"))
	self._configReg     = {}
	self._activeTab     = {btn = nil, page = nil}

	-- Destroi instância anterior
	local old = pg:FindFirstChild(self._guiName)
	if old then old:Destroy() end

	self:_buildGui()
	return self
end

-- ── GUI base ──────────────────────────────────────────────────────────────────
function RefLib:_buildGui()
	local T = self.Theme

	local sg = Instance.new("ScreenGui")
	sg.Name = self._guiName; sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 999; sg.Parent = pg
	self._sg = sg

	-- Ícone
	local icon = Instance.new("ImageButton")
	icon.Name = "IconBtn"; icon.Size = UDim2.new(0,52,0,52)
	icon.Position = UDim2.new(0,16,0.5,-26)
	icon.BackgroundColor3 = T.Panel2; icon.Image = self._icon
	icon.ScaleType = Enum.ScaleType.Fit; icon.AutoButtonColor = false
	icon.ZIndex = 10; icon.Parent = sg
	_corner(icon, 14); _stroke(icon, 1, 0.70, T.Stroke); _drag(icon, icon)
	icon.MouseEnter:Connect(function() _tween(icon,{BackgroundColor3=Color3.fromRGB(34,34,46)},0.12) end)
	icon.MouseLeave:Connect(function() _tween(icon,{BackgroundColor3=T.Panel2},0.12) end)
	self._icon_btn = icon

	-- Main
	local main = Instance.new("Frame")
	main.Name = "Main"; main.Size = UDim2.new(0,540,0,380)
	main.Position = UDim2.new(0.5,-270,0.5,-190)
	main.BackgroundColor3 = T.Panel; main.ZIndex = 1; main.Parent = sg
	_corner(main, 14); _stroke(main, 1, 0.75, T.Stroke)

	local sh = Instance.new("ImageLabel")
	sh.BackgroundTransparency=1; sh.Image="rbxassetid://1316045217"
	sh.ImageTransparency=0.90; sh.ImageColor3=Color3.fromRGB(0,0,0)
	sh.ScaleType=Enum.ScaleType.Slice; sh.SliceCenter=Rect.new(10,10,118,118)
	sh.Size=UDim2.new(1,34,1,34); sh.Position=UDim2.new(0,-17,0,-17); sh.ZIndex=0; sh.Parent=main
	self._main = main

	-- Topbar
	local tb = Instance.new("Frame")
	tb.Size = UDim2.new(1,0,0,48); tb.BackgroundColor3 = T.Panel2; tb.Parent = main
	_corner(tb, 14)
	local al = Instance.new("Frame"); al.BackgroundColor3=T.Accent; al.BorderSizePixel=0
	al.Size=UDim2.new(1,0,0,1); al.Position=UDim2.new(0,0,1,-1); al.BackgroundTransparency=0.35; al.Parent=tb

	-- Ícone no centro da topbar
	local ti = Instance.new("ImageLabel"); ti.BackgroundTransparency=1
	ti.Size=UDim2.new(0,28,0,28); ti.AnchorPoint=Vector2.new(0.5,0.5)
	ti.Position=UDim2.new(0.5,0,0.5,0); ti.Image=self._icon
	ti.ScaleType=Enum.ScaleType.Fit; ti.Parent=tb

	-- Botão minimizar
	local mb = Instance.new("TextButton")
	mb.Size=UDim2.new(0,36,0,28); mb.Position=UDim2.new(1,-48,0.5,-14)
	mb.BackgroundColor3=T.Panel; mb.Text="–"; mb.Font=Enum.Font.GothamSemibold
	mb.TextSize=18; mb.TextColor3=T.Text; mb.AutoButtonColor=false; mb.Parent=tb
	_corner(mb,9); _stroke(mb,1,0.82,T.Stroke)
	mb.MouseEnter:Connect(function() _tween(mb,{BackgroundColor3=Color3.fromRGB(28,28,36)},0.12) end)
	mb.MouseLeave:Connect(function() _tween(mb,{BackgroundColor3=T.Panel},0.12) end)
	_drag(tb, main)
	self._minBtn = mb

	-- User panel (bottom-left)
	local up = Instance.new("Frame"); up.Name="UserPanel"
	up.Size=UDim2.new(0,160,0,56); up.Position=UDim2.new(0,0,1,-56)
	up.BackgroundColor3=T.Panel; up.ZIndex=3; up.ClipsDescendants=true; up.BorderSizePixel=0; up.Parent=main
	local utl = Instance.new("Frame"); utl.Size=UDim2.new(1,0,0,1)
	utl.BackgroundColor3=T.Line; utl.BackgroundTransparency=0.4; utl.BorderSizePixel=0; utl.ZIndex=4; utl.Parent=up
	local av = Instance.new("ImageLabel"); av.Name="Avatar"
	av.Size=UDim2.new(0,36,0,36); av.Position=UDim2.new(0,10,0.5,-18)
	av.BackgroundColor3=T.Panel; av.ZIndex=4; av.Parent=up
	_corner(av,999); _stroke(av,1.5,0.50,T.Accent)
	task.spawn(function()
		local ok,img = pcall(function() return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)
		if ok then av.Image=img end
	end)
	local ud = Instance.new("Frame"); ud.Size=UDim2.new(0,2,0,30); ud.Position=UDim2.new(0,54,0.5,-15)
	ud.BackgroundColor3=T.Accent; ud.BackgroundTransparency=0.35; ud.BorderSizePixel=0; ud.ZIndex=4; ud.Parent=up
	_corner(ud,999)
	local un = Instance.new("TextLabel"); un.BackgroundTransparency=1; un.Size=UDim2.new(1,-68,0,18)
	un.Position=UDim2.new(0,64,0,10); un.Font=Enum.Font.GothamSemibold; un.Text=player.DisplayName
	un.TextSize=12; un.TextColor3=T.Text; un.TextXAlignment=Enum.TextXAlignment.Left
	un.TextTruncate=Enum.TextTruncate.AtEnd; un.ZIndex=4; un.Parent=up
	local ut = Instance.new("TextLabel"); ut.BackgroundTransparency=1; ut.Size=UDim2.new(1,-68,0,14)
	ut.Position=UDim2.new(0,64,0,30); ut.Font=Enum.Font.Gotham; ut.Text="@"..player.Name
	ut.TextSize=10; ut.TextColor3=T.Sub; ut.TextXAlignment=Enum.TextXAlignment.Left
	ut.TextTruncate=Enum.TextTruncate.AtEnd; ut.ZIndex=4; ut.Parent=up

	-- Body
	local body = Instance.new("Frame"); body.Size=UDim2.new(1,0,1,-48-56)
	body.Position=UDim2.new(0,0,0,48); body.BackgroundTransparency=1; body.Parent=main

	local spad = Instance.new("Frame"); spad.BackgroundTransparency=1; spad.Size=UDim2.new(0,160,1,0); spad.Parent=body
	_pad(spad,12)
	local tlist = Instance.new("UIListLayout"); tlist.Padding=UDim.new(0,8); tlist.SortOrder=Enum.SortOrder.LayoutOrder; tlist.Parent=spad

	local cpd = Instance.new("Frame"); cpd.BackgroundTransparency=1; cpd.Size=UDim2.new(1,-160,1,0)
	cpd.Position=UDim2.new(0,160,0,0); cpd.Parent=body; _pad(cpd,12)

	local pages = Instance.new("Folder"); pages.Parent=cpd

	local sdiv = Instance.new("Frame"); sdiv.Size=UDim2.new(0,1,1,-56); sdiv.Position=UDim2.new(0,160,0,0)
	sdiv.BackgroundColor3=T.Line; sdiv.BackgroundTransparency=0.5; sdiv.BorderSizePixel=0; sdiv.Parent=body

	self._spad  = spad
	self._pages = pages

	-- Minimizar com animação
	local minimized  = false
	local animActive = false
	local OPEN_POS   = main.Position
	local OPEN_SIZE  = main.Size

	local function setMin(state)
		if animActive then return end
		minimized = state; animActive = true
		_tween(icon, {BackgroundColor3 = state and Color3.fromRGB(40,34,60) or T.Panel2}, 0.15)
		local ix = icon.Position.X.Offset + icon.AbsoluteSize.X*0.5
		if state then
			main.ClipsDescendants = true
			_tween(main, {Position=UDim2.new(0,ix-26,0.5,-26), Size=UDim2.new(0,52,0,52)}, 0.22)
			task.delay(0.23, function()
				main.Visible=false; main.ClipsDescendants=false
				main.Position=OPEN_POS; main.Size=OPEN_SIZE; animActive=false
			end)
		else
			main.ClipsDescendants=true; main.Position=UDim2.new(0,ix-26,0.5,-26); main.Size=UDim2.new(0,52,0,52); main.Visible=true
			_tween(main, {Position=OPEN_POS, Size=OPEN_SIZE}, 0.25)
			task.delay(0.26, function() main.ClipsDescendants=false; animActive=false end)
		end
	end

	mb.MouseButton1Click:Connect(function() setMin(true) end)
	icon.MouseButton1Click:Connect(function() setMin(not minimized) end)
	UserInputService.InputBegan:Connect(function(inp,gp)
		if gp then return end
		if inp.KeyCode == Enum.KeyCode.RightShift then setMin(not minimized) end
	end)
	self._setMin = setMin
end

-- ── Toast ─────────────────────────────────────────────────────────────────────
function RefLib:Toast(icon, title, sub, accentColor)
	local T = self.Theme
	accentColor = accentColor or T.Accent
	local W, H = 260, 54
	local toast = Instance.new("Frame"); toast.Name="ref_toast"
	toast.Size=UDim2.new(0,W,0,H); toast.Position=UDim2.new(1,20,1,-80)
	toast.BackgroundColor3=T.Panel2; toast.BorderSizePixel=0; toast.ZIndex=200; toast.ClipsDescendants=true
	toast.Parent=self._sg; _corner(toast,10); _stroke(toast,1,0.6,T.Stroke)

	local bar=Instance.new("Frame"); bar.Size=UDim2.new(0,3,1,0); bar.BackgroundColor3=accentColor
	bar.BorderSizePixel=0; bar.ZIndex=201; bar.Parent=toast; _corner(bar,2)

	local img=Instance.new("ImageLabel"); img.Size=UDim2.new(0,34,0,34); img.Position=UDim2.new(0,12,0.5,-17)
	img.BackgroundColor3=T.Panel; img.BorderSizePixel=0; img.Image=icon or self._icon
	img.ScaleType=Enum.ScaleType.Fit; img.ZIndex=201; img.Parent=toast; _corner(img,6)

	local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-60,0,18); lbl.Position=UDim2.new(0,54,0,9)
	lbl.BackgroundTransparency=1; lbl.Text=title or ""; lbl.TextColor3=T.Text; lbl.TextSize=13
	lbl.Font=Enum.Font.GothamBold; lbl.TextXAlignment=Enum.TextXAlignment.Left
	lbl.TextTruncate=Enum.TextTruncate.AtEnd; lbl.ZIndex=201; lbl.Parent=toast

	local sub2=Instance.new("TextLabel"); sub2.Size=UDim2.new(1,-60,0,16); sub2.Position=UDim2.new(0,54,0,28)
	sub2.BackgroundTransparency=1; sub2.Text=sub or ""; sub2.TextColor3=T.Sub; sub2.TextSize=11
	sub2.Font=Enum.Font.Gotham; sub2.TextXAlignment=Enum.TextXAlignment.Left
	sub2.TextTruncate=Enum.TextTruncate.AtEnd; sub2.ZIndex=201; sub2.Parent=toast

	local pb=Instance.new("Frame"); pb.Size=UDim2.new(1,0,0,2); pb.Position=UDim2.new(0,0,1,-2)
	pb.BackgroundColor3=T.Panel; pb.BorderSizePixel=0; pb.ZIndex=202; pb.Parent=toast
	local pf=Instance.new("Frame"); pf.Size=UDim2.new(1,0,1,0); pf.BackgroundColor3=accentColor
	pf.BorderSizePixel=0; pf.ZIndex=203; pf.Parent=pb

	_tween(toast, {Position=UDim2.new(1,-(W+16),1,-80)}, 0.3)
	task.delay(0.3, function() _tween(pf, {Size=UDim2.new(0,0,1,0)}, 3.0) end)
	task.delay(3.3, function()
		_tween(toast, {Position=UDim2.new(1,20,1,-80)}, 0.25)
		task.delay(0.26, function() if toast and toast.Parent then toast:Destroy() end end)
	end)
end

-- ── CfgRegister ───────────────────────────────────────────────────────────────
function RefLib:CfgRegister(key, getfn, setfn)
	table.insert(self._configReg, {key=key, get=getfn, set=setfn})
end

-- ── Divider helper ────────────────────────────────────────────────────────────
function RefLib:_divider(parent, text)
	local T = self.Theme
	local w = Instance.new("Frame"); w.BackgroundTransparency=1; w.Size=UDim2.new(1,0,0,28); w.Parent=parent
	local ln = Instance.new("Frame"); ln.BorderSizePixel=0; ln.BackgroundColor3=T.Line
	ln.BackgroundTransparency=0.15; ln.Size=UDim2.new(1,0,0,1); ln.Position=UDim2.new(0,0,0.5,0); ln.Parent=w
	local g = Instance.new("UIGradient")
	g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,T.Panel2),ColorSequenceKeypoint.new(0.5,T.Line),ColorSequenceKeypoint.new(1,T.Panel2)})
	g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,1)})
	g.Parent=ln
	if text and text ~= "" then
		local lb = Instance.new("TextLabel"); lb.BackgroundColor3=T.Panel2; lb.BorderSizePixel=0
		lb.AnchorPoint=Vector2.new(0.5,0.5); lb.Position=UDim2.new(0.5,0,0.5,0); lb.Size=UDim2.new(0,140,0,20)
		lb.Font=Enum.Font.GothamSemibold; lb.Text=text; lb.TextSize=12; lb.TextColor3=T.Sub; lb.Parent=w
		_corner(lb,999); _stroke(lb,1,0.9,T.Stroke)
	end
	return w
end

-- ── Tab ───────────────────────────────────────────────────────────────────────
function RefLib:Tab(name)
	local T = self.Theme
	local tabBtn = Instance.new("TextButton"); tabBtn.Size=UDim2.new(1,0,0,36)
	tabBtn.BackgroundColor3=T.Panel2; tabBtn.Text=name; tabBtn.Font=Enum.Font.GothamSemibold
	tabBtn.TextSize=13; tabBtn.TextColor3=T.Sub; tabBtn.AutoButtonColor=false; tabBtn.Parent=self._spad
	_corner(tabBtn,10); local st=_stroke(tabBtn,1,0.86,T.Stroke)

	local page = Instance.new("ScrollingFrame"); page.Size=UDim2.new(1,0,1,0)
	page.BackgroundTransparency=1; page.ScrollBarThickness=3; page.ScrollBarImageTransparency=0.65
	page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false; page.Parent=self._pages
	local lay = Instance.new("UIListLayout"); lay.Padding=UDim.new(0,10); lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Parent=page
	lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+12)
	end)

	local active = self._activeTab
	local function setActive()
		if active.btn then _tween(active.btn,{BackgroundColor3=T.Panel2},0.12); active.btn.TextColor3=T.Sub end
		if active.page then active.page.Visible=false end
		active.btn, active.page = tabBtn, page
		page.Visible=true; _tween(tabBtn,{BackgroundColor3=Color3.fromRGB(34,34,46)},0.12)
		tabBtn.TextColor3=T.Text; st.Transparency=0.55
	end
	tabBtn.MouseEnter:Connect(function() if active.btn~=tabBtn then _tween(tabBtn,{BackgroundColor3=Color3.fromRGB(30,30,38)},0.12) end end)
	tabBtn.MouseLeave:Connect(function() if active.btn~=tabBtn then _tween(tabBtn,{BackgroundColor3=T.Panel2},0.12) end end)
	tabBtn.MouseButton1Click:Connect(setActive)

	-- Se for a primeira tab, ativa automaticamente
	if not active.btn then setActive() end

	local tabObj = {_page=page, _lib=self}

	-- Section
	function tabObj:Section(titleText)
		local T2 = self._lib.Theme
		local sec = Instance.new("Frame"); sec.BackgroundColor3=T2.Panel2; sec.Size=UDim2.new(1,0,0,44); sec.Parent=page
		_corner(sec,12); _stroke(sec,1,0.84,T2.Stroke)
		local pad = Instance.new("Frame"); pad.BackgroundTransparency=1; pad.Size=UDim2.new(1,0,1,0); pad.Parent=sec; _pad(pad,12)
		local tlbl = Instance.new("TextLabel"); tlbl.BackgroundTransparency=1; tlbl.Size=UDim2.new(1,0,0,18)
		tlbl.Font=Enum.Font.GothamSemibold; tlbl.Text=titleText; tlbl.TextSize=13; tlbl.TextColor3=T2.Text
		tlbl.TextXAlignment=Enum.TextXAlignment.Left; tlbl.Parent=pad
		local items = Instance.new("Frame"); items.BackgroundTransparency=1; items.Size=UDim2.new(1,0,1,-18)
		items.Position=UDim2.new(0,0,0,18); items.Parent=pad
		local il = Instance.new("UIListLayout"); il.Padding=UDim.new(0,8); il.SortOrder=Enum.SortOrder.LayoutOrder; il.Parent=items
		il:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			sec.Size=UDim2.new(1,0,0,il.AbsoluteContentSize.Y+18+24)
		end)

		local lib2 = self._lib
		local secObj = {_items=items, _lib=lib2}

		function secObj:Divider(text)
			return lib2:_divider(items, text)
		end

		function secObj:Toggle(text, default, callback)
			local T3=lib2.Theme
			local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=T3.Panel; row.Parent=items
			_corner(row,10); _stroke(row,1,0.86,T3.Stroke)
			local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-70,1,0)
			lbl.Position=UDim2.new(0,12,0,0); lbl.Font=Enum.Font.GothamSemibold; lbl.Text=text; lbl.TextSize=13
			lbl.TextColor3=T3.Text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
			local sw=Instance.new("Frame"); sw.Size=UDim2.new(0,44,0,22); sw.Position=UDim2.new(1,-56,0.5,-11)
			sw.BackgroundColor3=Color3.fromRGB(35,35,42); sw.Parent=row; _corner(sw,999); _stroke(sw,1,0.88,T3.Stroke)
			local kn=Instance.new("Frame"); kn.Size=UDim2.new(0,18,0,18); kn.Position=UDim2.new(0,2,0.5,-9)
			kn.BackgroundColor3=T3.Sub; kn.Parent=sw; _corner(kn,999)
			local state=default==true
			local function render()
				if state then _tween(sw,{BackgroundColor3=T3.Accent},0.12); _tween(kn,{Position=UDim2.new(1,-20,0.5,-9),BackgroundColor3=T3.Text},0.12)
				else _tween(sw,{BackgroundColor3=Color3.fromRGB(35,35,42)},0.12); _tween(kn,{Position=UDim2.new(0,2,0.5,-9),BackgroundColor3=T3.Sub},0.12) end
			end
			render()
			local click=Instance.new("TextButton"); click.BackgroundTransparency=1; click.Size=UDim2.new(1,0,1,0); click.Text=""; click.Parent=row
			click.MouseEnter:Connect(function() _tween(row,{BackgroundColor3=Color3.fromRGB(26,26,34)},0.12) end)
			click.MouseLeave:Connect(function() _tween(row,{BackgroundColor3=T3.Panel},0.12) end)
			click.MouseButton1Click:Connect(function() state=not state; render(); if callback then callback(state) end end)
			return {
				Get=function() return state end,
				Set=function(v) if state==v then return end; state=v; render(); if callback then callback(state) end end,
			}
		end

		function secObj:Slider(text, min, max, default, callback)
			local T3=lib2.Theme; min,max=min or 0,max or 100; default=math.clamp(default or min,min,max)
			local h=Instance.new("Frame"); h.Size=UDim2.new(1,0,0,48); h.BackgroundColor3=T3.Panel; h.Parent=items
			_corner(h,10); _stroke(h,1,0.86,T3.Stroke)
			local lb=Instance.new("TextLabel"); lb.BackgroundTransparency=1; lb.Size=UDim2.new(1,-80,0,18)
			lb.Position=UDim2.new(0,12,0,8); lb.Font=Enum.Font.GothamSemibold; lb.Text=text; lb.TextSize=13
			lb.TextColor3=T3.Text; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=h
			local vl=Instance.new("TextLabel"); vl.BackgroundTransparency=1; vl.Size=UDim2.new(0,60,0,18)
			vl.Position=UDim2.new(1,-72,0,8); vl.Font=Enum.Font.Gotham; vl.TextSize=12; vl.TextColor3=T3.Sub
			vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=h
			local bar=Instance.new("Frame"); bar.Size=UDim2.new(1,-24,0,8); bar.Position=UDim2.new(0,12,0,32)
			bar.BackgroundColor3=Color3.fromRGB(35,35,42); bar.Parent=h; _corner(bar,999)
			local fill=Instance.new("Frame"); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=T3.Accent; fill.Parent=bar; _corner(fill,999)
			local dragging,value=false,default
			local function setV(v)
				v=math.clamp(v,min,max); value=v
				vl.Text=tostring(math.floor(v+0.5))
				fill.Size=UDim2.new((v-min)/(max-min),0,1,0)
				if callback then callback(value) end
			end
			local function fromX(x)
				local r=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
				setV(min+(max-min)*r)
			end
			setV(default)
			bar.InputBegan:Connect(function(inp)
				if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true; fromX(inp.Position.X) end
			end)
			bar.InputEnded:Connect(function(inp)
				if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
			end)
			UserInputService.InputChanged:Connect(function(inp)
				if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then fromX(inp.Position.X) end
			end)
			h.MouseEnter:Connect(function() _tween(h,{BackgroundColor3=Color3.fromRGB(26,26,34)},0.12) end)
			h.MouseLeave:Connect(function() _tween(h,{BackgroundColor3=T3.Panel},0.12) end)
			return {Get=function() return value end, Set=setV}
		end

		function secObj:Button(labelText, callback)
			local T3=lib2.Theme
			local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=T3.Panel
			row.Text=""; row.AutoButtonColor=false; row.Parent=items; _corner(row,10); _stroke(row,1,0.86,T3.Stroke)
			local lb=Instance.new("TextLabel"); lb.BackgroundTransparency=1; lb.Size=UDim2.new(1,0,1,0)
			lb.Font=Enum.Font.GothamSemibold; lb.Text=labelText; lb.TextSize=13; lb.TextColor3=T3.Text; lb.Parent=row
			row.MouseEnter:Connect(function() _tween(row,{BackgroundColor3=Color3.fromRGB(30,26,48)},0.12) end)
			row.MouseLeave:Connect(function() _tween(row,{BackgroundColor3=T3.Panel},0.12) end)
			row.MouseButton1Click:Connect(function()
				_tween(row,{BackgroundColor3=T3.Accent},0.08)
				task.delay(0.12,function() _tween(row,{BackgroundColor3=T3.Panel},0.12) end)
				if callback then callback() end
			end)
		end

		function secObj:TextInput(labelText, placeholder, callback)
			local T3=lib2.Theme
			local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=T3.Panel; row.Parent=items
			_corner(row,10); _stroke(row,1,0.86,T3.Stroke)
			local lb=Instance.new("TextLabel"); lb.BackgroundTransparency=1; lb.Size=UDim2.new(0,80,1,0)
			lb.Position=UDim2.new(0,12,0,0); lb.Font=Enum.Font.GothamSemibold; lb.Text=labelText; lb.TextSize=12
			lb.TextColor3=T3.Sub; lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=row
			local box=Instance.new("TextBox"); box.Size=UDim2.new(1,-100,1,-8); box.Position=UDim2.new(0,90,0,4)
			box.BackgroundColor3=Color3.fromRGB(28,28,36); box.Font=Enum.Font.Gotham; box.TextSize=12
			box.TextColor3=T3.Text; box.PlaceholderText=placeholder or ""; box.PlaceholderColor3=T3.Sub
			box.Text=""; box.ClearTextOnFocus=false; box.Parent=row; _corner(box,6); _stroke(box,1,0.80,T3.Stroke)
			local pd=Instance.new("UIPadding"); pd.PaddingLeft=UDim.new(0,6); pd.Parent=box
			box.Focused:Connect(function() _tween(box,{BackgroundColor3=Color3.fromRGB(34,34,48)},0.12) end)
			box.FocusLost:Connect(function(enter) _tween(box,{BackgroundColor3=Color3.fromRGB(28,28,36)},0.12); if callback then callback(box.Text,enter) end end)
			return {Get=function() return box.Text end, Set=function(v) box.Text=v end}
		end

		function secObj:SplitButton(btns)
			local T3=lib2.Theme
			local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,34); row.BackgroundTransparency=1; row.Parent=items
			local n,gap=#btns,4; local handles={}
			for i,info in ipairs(btns) do
				local b=Instance.new("TextButton")
				b.Position=UDim2.new((i-1)/n,i>1 and gap/2 or 0,0,0)
				b.Size=UDim2.new(1/n,i<n and -gap/2 or (i>1 and -gap/2 or 0),1,0)
				b.BackgroundColor3=T3.Panel; b.Text=info.text or ""; b.Font=Enum.Font.GothamSemibold
				b.TextSize=12; b.TextColor3=info.textColor or T3.Text; b.AutoButtonColor=false; b.Parent=row
				_corner(b,10); _stroke(b,1,0.86,T3.Stroke)
				b.MouseEnter:Connect(function() _tween(b,{BackgroundColor3=Color3.fromRGB(30,26,48)},0.12) end)
				b.MouseLeave:Connect(function() _tween(b,{BackgroundColor3=T3.Panel},0.12) end)
				local cb=info.callback
				b.MouseButton1Click:Connect(function()
					_tween(b,{BackgroundColor3=T3.Accent},0.08)
					task.delay(0.12,function() _tween(b,{BackgroundColor3=T3.Panel},0.12) end)
					if cb then cb(b) end
				end)
				handles[i]=b
			end
			return handles
		end

		function secObj:AvatarCard()
			local T3=lib2.Theme
			local card=Instance.new("Frame"); card.Size=UDim2.new(1,0,0,64); card.BackgroundColor3=Color3.fromRGB(20,20,26)
			card.Visible=false; card.Parent=items; _corner(card,10); _stroke(card,1,0.82,T3.Stroke)
			local av=Instance.new("ImageLabel"); av.Size=UDim2.new(0,44,0,44); av.Position=UDim2.new(0,10,0.5,-22)
			av.BackgroundColor3=T3.Panel; av.Image=""; av.Parent=card; _corner(av,999); _stroke(av,1.5,0.5,T3.Accent)
			local adiv=Instance.new("Frame"); adiv.Size=UDim2.new(0,2,0,28); adiv.Position=UDim2.new(0,62,0.5,-14)
			adiv.BackgroundColor3=T3.Accent; adiv.BackgroundTransparency=0.35; adiv.BorderSizePixel=0; adiv.Parent=card; _corner(adiv,999)
			local nm=Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,-76,0,18)
			nm.Position=UDim2.new(0,72,0,10); nm.Font=Enum.Font.GothamBold; nm.TextSize=12; nm.TextColor3=T3.Text
			nm.TextXAlignment=Enum.TextXAlignment.Left; nm.TextTruncate=Enum.TextTruncate.AtEnd; nm.Text="—"; nm.Parent=card
			local tg=Instance.new("TextLabel"); tg.BackgroundTransparency=1; tg.Size=UDim2.new(1,-76,0,13)
			tg.Position=UDim2.new(0,72,0,30); tg.Font=Enum.Font.Gotham; tg.TextSize=10; tg.TextColor3=T3.Sub
			tg.TextXAlignment=Enum.TextXAlignment.Left; tg.Text=""; tg.Parent=card
			local hp=Instance.new("TextLabel"); hp.BackgroundTransparency=1; hp.Size=UDim2.new(1,-76,0,13)
			hp.Position=UDim2.new(0,72,0,44); hp.Font=Enum.Font.Gotham; hp.TextSize=10; hp.TextColor3=T3.Accent
			hp.TextXAlignment=Enum.TextXAlignment.Left; hp.Text=""; hp.Parent=card
			return {
				Frame=card,
				Set=function(target)
					if not target then card.Visible=false; return end
					card.Visible=true; nm.Text=target.DisplayName; tg.Text="@"..target.Name
					local ch=target.Character; local hm=ch and ch:FindFirstChildOfClass("Humanoid")
					hp.Text=hm and ("hp: "..math.floor(hm.Health).."/"..math.floor(hm.MaxHealth)) or "no character"
					task.spawn(function()
						local ok,img=pcall(function() return Players:GetUserThumbnailAsync(target.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)
						if ok then av.Image=img end
					end)
				end,
				UpdateHp=function(target)
					if not target or not target.Character then return end
					local hm=target.Character:FindFirstChildOfClass("Humanoid")
					if hm then hp.Text="hp: "..math.floor(hm.Health).."/"..math.floor(hm.MaxHealth) end
				end,
			}
		end

		return secObj
	end

	tabObj._activate = setActive
	return tabObj
end

-- ── BuildConfigTab ─────────────────────────────────────────────────────────────
-- Cria a aba de config completa (save/load/dropdown) numa tab existente
function RefLib:BuildConfigTab(config_tab, saveDirName)
	local T    = self.Theme
	local reg  = self._configReg
	local sg   = self._sg
	saveDirName = saveDirName or "ref_ui_cfg"

	local function serialize(t)
		local parts={}
		for k,v in pairs(t) do
			local vs
			if type(v)=="boolean" then vs=v and "true" or "false"
			elseif type(v)=="number" then vs=tostring(v)
			elseif type(v)=="string" then vs='"'..v:gsub('"','\\"')..'"'
			else vs="null" end
			table.insert(parts,'"'..tostring(k)..'":' ..vs)
		end
		return "{"..table.concat(parts,",").."}"
	end
	local function deserialize(s)
		local t={}
		for k,vs in s:gmatch('"([^"]+)":([^,}]+)') do
			if vs=="true" then t[k]=true elseif vs=="false" then t[k]=false
			elseif tonumber(vs) then t[k]=tonumber(vs)
			elseif vs:match('^"(.*)"$') then t[k]=vs:match('^"(.*)"$') end
		end
		return t
	end

	local SAVE_FILE = saveDirName.."/configs.json"
	local MAX_CFG   = 5
	local fsOk = type(isfolder)=="function" and type(readfile)=="function" and type(writefile)=="function" and type(makefolder)=="function"
	if fsOk and not isfolder(saveDirName) then pcall(makefolder, saveDirName) end

	local function loadFile()
		if not fsOk then return _G["ref_cfg_"..saveDirName] or {} end
		local ok,data=pcall(readfile,SAVE_FILE)
		if not ok or not data or data=="" then return {} end
		local t={}
		for k,v in data:gmatch('"([^"]+)":"(.-)"[,}]') do t[k]=v:gsub('\\"','"') end
		return t
	end
	local function saveFile(t)
		if not fsOk then _G["ref_cfg_"..saveDirName]=t; return end
		local parts={}
		for k,v in pairs(t) do table.insert(parts,'"'..k..'":"'..v:gsub('"','\\"')..'"') end
		pcall(writefile,SAVE_FILE,"{"..table.concat(parts,",").."}")
	end

	local UserConfigs = loadFile()
	local function notify(txt)
		pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=self._name,Text=txt,Duration=2}) end)
	end
	local function getNames()
		local n={}; for k in pairs(UserConfigs) do table.insert(n,k) end; table.sort(n); return n
	end
	local function captureState()
		local s={}; for _,c in ipairs(reg) do s[c.key]=c.get() end; return s
	end
	local function applyState(s)
		for _,c in ipairs(reg) do if s[c.key]~=nil then pcall(c.set,s[c.key]) end end
	end

	local cfgSec = config_tab:Section("config")
	cfgSec:Divider("new")
	local nameInput = cfgSec:TextInput("name","config name (max 16 chars)",nil)
	cfgSec:Button("save", function()
		local name=nameInput.Get():gsub("%s+","_"):sub(1,16)
		if name=="" then notify("type a name first") return end
		if UserConfigs[name] then notify("name already exists") return end
		if #getNames()>=MAX_CFG then notify("max 5 configs") return end
		UserConfigs[name]=serialize(captureState()); saveFile(UserConfigs); notify("saved: "..name)
	end)

	local slotSec = config_tab:Section("slots")
	slotSec:Divider("select")
	local probe=slotSec:Divider(""); local ItemsFrame=probe.Parent; probe:Destroy()

	local selectedName=nil; local dropOpen=false; local itemFrames={}; local dropHeight=0

	local hdr=Instance.new("Frame"); hdr.Name="DropHeader"; hdr.Size=UDim2.new(1,0,0,34)
	hdr.BackgroundColor3=T.Panel; hdr.ClipsDescendants=false; hdr.ZIndex=2; hdr.Parent=ItemsFrame
	_corner(hdr,10); _stroke(hdr,1,0.82,T.Stroke)
	local hLbl=Instance.new("TextLabel"); hLbl.BackgroundTransparency=1; hLbl.Size=UDim2.new(1,-42,1,0)
	hLbl.Position=UDim2.new(0,12,0,0); hLbl.Font=Enum.Font.GothamSemibold; hLbl.Text="select config..."
	hLbl.TextSize=12; hLbl.TextColor3=T.Sub; hLbl.TextXAlignment=Enum.TextXAlignment.Left
	hLbl.TextTruncate=Enum.TextTruncate.AtEnd; hLbl.ZIndex=3; hLbl.Parent=hdr
	local aLbl=Instance.new("TextLabel"); aLbl.BackgroundTransparency=1; aLbl.Size=UDim2.new(0,30,1,0)
	aLbl.Position=UDim2.new(1,-32,0,0); aLbl.Font=Enum.Font.GothamBold; aLbl.Text="v"; aLbl.TextSize=13
	aLbl.TextColor3=T.Sub; aLbl.TextXAlignment=Enum.TextXAlignment.Center; aLbl.ZIndex=3; aLbl.Parent=hdr
	local hBtn=Instance.new("TextButton"); hBtn.BackgroundTransparency=1; hBtn.Size=UDim2.new(1,0,1,0)
	hBtn.Text=""; hBtn.ZIndex=4; hBtn.Parent=hdr

	local dlist=Instance.new("Frame"); dlist.Name="ref_DropList"; dlist.BackgroundColor3=T.Panel2
	dlist.BorderSizePixel=0; dlist.Size=UDim2.new(0,10,0,0); dlist.AnchorPoint=Vector2.new(0,0)
	dlist.Visible=false; dlist.ClipsDescendants=true; dlist.ZIndex=100; dlist.Parent=sg
	_corner(dlist,10); _stroke(dlist,1,0.70,T.Stroke)
	local dlayout=Instance.new("UIListLayout"); dlayout.Padding=UDim.new(0,2); dlayout.SortOrder=Enum.SortOrder.LayoutOrder; dlayout.Parent=dlist
	local dpad=Instance.new("UIPadding"); dpad.PaddingTop=UDim.new(0,6); dpad.PaddingBottom=UDim.new(0,6)
	dpad.PaddingLeft=UDim.new(0,6); dpad.PaddingRight=UDim.new(0,6); dpad.Parent=dlist

	local guiInset=game:GetService("GuiService"):GetGuiInset()
	RunService.RenderStepped:Connect(function()
		if not dropOpen then return end
		local abs=hdr.AbsolutePosition; local sz=hdr.AbsoluteSize
		dlist.Position=UDim2.new(0,abs.X,0,abs.Y+sz.Y+guiInset.Y+4); dlist.Size=UDim2.new(0,sz.X,0,dropHeight)
	end)

	local function rebuild()
		for _,f in ipairs(itemFrames) do if f and f.Parent then f:Destroy() end end; itemFrames={}
		local names=getNames()
		if #names==0 then
			local e=Instance.new("TextLabel"); e.BackgroundTransparency=1; e.Size=UDim2.new(1,0,0,28)
			e.Font=Enum.Font.Gotham; e.Text="no configs saved"; e.TextSize=11; e.TextColor3=T.Sub
			e.TextXAlignment=Enum.TextXAlignment.Center; e.ZIndex=101; e.Parent=dlist; table.insert(itemFrames,e); return
		end
		for _,name in ipairs(names) do
			local isSel=(selectedName==name)
			local item=Instance.new("Frame"); item.Size=UDim2.new(1,0,0,32)
			item.BackgroundColor3=isSel and Color3.fromRGB(32,26,52) or T.Panel; item.ZIndex=101; item.Parent=dlist
			_corner(item,8); table.insert(itemFrames,item)
			if isSel then
				local acc=Instance.new("Frame"); acc.Size=UDim2.new(0,2,0,18); acc.Position=UDim2.new(0,0,0.5,-9)
				acc.BackgroundColor3=T.Accent; acc.BorderSizePixel=0; acc.ZIndex=102; acc.Parent=item; _corner(acc,999)
			end
			local nLbl=Instance.new("TextLabel"); nLbl.BackgroundTransparency=1; nLbl.Size=UDim2.new(1,-68,1,0)
			nLbl.Position=UDim2.new(0,10,0,0); nLbl.Font=Enum.Font.GothamSemibold; nLbl.Text=name; nLbl.TextSize=12
			nLbl.TextColor3=isSel and T.Accent or T.Text; nLbl.TextXAlignment=Enum.TextXAlignment.Left
			nLbl.TextTruncate=Enum.TextTruncate.AtEnd; nLbl.ZIndex=102; nLbl.Parent=item
			local lBtn=Instance.new("TextButton"); lBtn.Size=UDim2.new(0,28,0,22); lBtn.Position=UDim2.new(1,-60,0.5,-11)
			lBtn.BackgroundColor3=Color3.fromRGB(28,52,36); lBtn.Text="load"; lBtn.Font=Enum.Font.GothamSemibold
			lBtn.TextSize=10; lBtn.TextColor3=Color3.fromRGB(80,210,110); lBtn.AutoButtonColor=false; lBtn.ZIndex=102; lBtn.Parent=item; _corner(lBtn,5)
			local dBtn=Instance.new("TextButton"); dBtn.Size=UDim2.new(0,28,0,22); dBtn.Position=UDim2.new(1,-28,0.5,-11)
			dBtn.BackgroundColor3=Color3.fromRGB(52,24,24); dBtn.Text="del"; dBtn.Font=Enum.Font.GothamSemibold
			dBtn.TextSize=10; dBtn.TextColor3=Color3.fromRGB(210,70,70); dBtn.AutoButtonColor=false; dBtn.ZIndex=102; dBtn.Parent=item; _corner(dBtn,5)
			local iClick=Instance.new("TextButton"); iClick.BackgroundTransparency=1; iClick.Size=UDim2.new(1,-68,1,0)
			iClick.Text=""; iClick.ZIndex=103; iClick.Parent=item
			local cn=name
			iClick.MouseEnter:Connect(function() if selectedName~=cn then _tween(item,{BackgroundColor3=Color3.fromRGB(26,26,38)},0.10) end end)
			iClick.MouseLeave:Connect(function() if selectedName~=cn then _tween(item,{BackgroundColor3=T.Panel},0.10) end end)
			iClick.MouseButton1Click:Connect(function()
				selectedName=cn; hLbl.Text=cn; hLbl.TextColor3=T.Text; _tween(aLbl,{TextColor3=T.Accent},0.12)
				nameInput.Set(cn); rebuild(); task.wait(); dropHeight=dlayout.AbsoluteContentSize.Y+12
			end)
			lBtn.MouseButton1Click:Connect(function()
				local json=UserConfigs[cn]; if json then applyState(deserialize(json)); notify("loaded: "..cn) end
			end)
			dBtn.MouseButton1Click:Connect(function()
				UserConfigs[cn]=nil; saveFile(UserConfigs)
				if selectedName==cn then selectedName=nil; hLbl.Text="select config..."; hLbl.TextColor3=T.Sub; _tween(aLbl,{TextColor3=T.Sub},0.12); nameInput.Set("") end
				notify("deleted: "..cn); rebuild(); task.wait(); dropHeight=dlayout.AbsoluteContentSize.Y+12
			end)
		end
	end

	local function closeDD()
		dropOpen=false; _tween(aLbl,{Rotation=0},0.14)
		local tw=TweenService:Create(dlist,TweenInfo.new(0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,hdr.AbsoluteSize.X,0,0)})
		tw:Play(); tw.Completed:Connect(function() dlist.Visible=false end); dropHeight=0
	end
	local function openDD()
		rebuild(); task.wait()
		local w=hdr.AbsoluteSize.X; local h=dlayout.AbsoluteContentSize.Y+12
		local abs=hdr.AbsolutePosition; local sz=hdr.AbsoluteSize
		dlist.Position=UDim2.new(0,abs.X,0,abs.Y+sz.Y+4); dlist.Size=UDim2.new(0,w,0,0); dlist.Visible=true
		dropOpen=true; dropHeight=h; _tween(aLbl,{Rotation=180},0.16)
	end

	hBtn.MouseButton1Click:Connect(function() if dropOpen then closeDD() else openDD() end end)
	hdr.MouseEnter:Connect(function() _tween(hdr,{BackgroundColor3=Color3.fromRGB(26,26,34)},0.12) end)
	hdr.MouseLeave:Connect(function() _tween(hdr,{BackgroundColor3=T.Panel},0.12) end)
	UserInputService.InputBegan:Connect(function(inp,gp)
		if gp then return end
		if inp.UserInputType==Enum.UserInputType.MouseButton1 and dropOpen then task.wait(); closeDD() end
	end)

	local actSec=config_tab:Section("actions"); actSec:Divider("selected")
	actSec:Button("load",function()
		if not selectedName then notify("select a config first") return end
		local json=UserConfigs[selectedName]; if not json then notify("not found") return end
		applyState(deserialize(json)); notify("loaded: "..selectedName)
	end)
	actSec:Button("overwrite",function()
		if not selectedName then notify("select a config first") return end
		UserConfigs[selectedName]=serialize(captureState()); saveFile(UserConfigs); notify("overwritten: "..selectedName)
	end)
	actSec:Button("delete",function()
		if not selectedName then notify("select a config first") return end
		UserConfigs[selectedName]=nil; saveFile(UserConfigs); notify("deleted: "..selectedName)
		selectedName=nil; hLbl.Text="select config..."; hLbl.TextColor3=T.Sub; _tween(aLbl,{TextColor3=T.Sub},0.12); nameInput.Set("")
		if dropOpen then rebuild(); task.wait(); dropHeight=dlayout.AbsoluteContentSize.Y+12 end
	end)
end

return RefLib
