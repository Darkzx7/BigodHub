--// ref ui (repaginada) - LocalScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- remove UI antiga
local old = pg:FindFirstChild("ref_ui")
if old then old:Destroy() end

-- helpers
local function tween(obj, props, t, style, dir)
	t = t or 0.15
	style = style or Enum.EasingStyle.Quad
	dir = dir or Enum.EasingDirection.Out
	local tw = TweenService:Create(obj, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
end

local function addCorner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = inst
	return c
end

local function addStroke(inst, th, tr, color)
	local s = Instance.new("UIStroke")
	s.Thickness = th or 1
	s.Transparency = tr or 0.65
	s.Color = color or Color3.fromRGB(255,255,255)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function addPadding(inst, p)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, p or 10)
	pad.PaddingRight = UDim.new(0, p or 10)
	pad.PaddingTop = UDim.new(0, p or 10)
	pad.PaddingBottom = UDim.new(0, p or 10)
	pad.Parent = inst
	return pad
end

local function makeDraggable(topbar, frame)
	local dragging = false
	local dragStart, startPos

	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- theme
local Theme = {
	BG = Color3.fromRGB(14, 14, 16),
	Panel = Color3.fromRGB(18, 18, 22),
	Panel2 = Color3.fromRGB(22, 22, 27),
	Stroke = Color3.fromRGB(255, 255, 255),

	Text = Color3.fromRGB(235, 235, 240),
	SubText = Color3.fromRGB(170, 170, 180),

	Accent = Color3.fromRGB(120, 80, 255),
	Line = Color3.fromRGB(60, 60, 72),
}

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ref_ui"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = pg

-- Main
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 540, 0, 340)
Main.Position = UDim2.new(0.5, -270, 0.5, -170)
Main.BackgroundColor3 = Theme.Panel
Main.Parent = ScreenGui
addCorner(Main, 14)
addStroke(Main, 1, 0.75, Theme.Stroke)

-- Shadow (sem halo branco)
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://1316045217" -- soft shadow
Shadow.ImageTransparency = 0.90        -- mais suave
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0) -- força sombra preta (evita “borda branca”)
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.Size = UDim2.new(1, 34, 1, 34)
Shadow.Position = UDim2.new(0, -17, 0, -17)
Shadow.ZIndex = 0
Shadow.Parent = Main
Main.ZIndex = 1

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 48)
Topbar.BackgroundColor3 = Theme.Panel2
Topbar.Parent = Main
addCorner(Topbar, 14)

-- linha accent sutil
local AccentLine = Instance.new("Frame")
AccentLine.BackgroundColor3 = Theme.Accent
AccentLine.BorderSizePixel = 0
AccentLine.Size = UDim2.new(1, 0, 0, 1)
AccentLine.Position = UDim2.new(0, 0, 1, -1)
AccentLine.BackgroundTransparency = 0.35
AccentLine.Parent = Topbar

-- título centralizado (ref + ui)
local TitleWrap = Instance.new("Frame")
TitleWrap.BackgroundTransparency = 1
TitleWrap.Size = UDim2.new(0, 180, 0, 24)
TitleWrap.AnchorPoint = Vector2.new(0.5, 0.5)
TitleWrap.Position = UDim2.new(0.5, 0, 0.5, 0)
TitleWrap.Parent = Topbar

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(0, 60, 1, 0)
Title.Position = UDim2.new(0.5, -30, 0, 0)
Title.Font = Enum.Font.GothamSemibold
Title.Text = "ref"
Title.TextSize = 18
Title.TextColor3 = Theme.Text
Title.TextXAlignment = Enum.TextXAlignment.Right
Title.Parent = TitleWrap

local TitleSmall = Instance.new("TextLabel")
TitleSmall.BackgroundTransparency = 1
TitleSmall.Size = UDim2.new(0, 50, 1, 0)
TitleSmall.Position = UDim2.new(0.5, 32, 0, 0)
TitleSmall.Font = Enum.Font.Gotham
TitleSmall.Text = "ui"
TitleSmall.TextSize = 14
TitleSmall.TextColor3 = Theme.SubText
TitleSmall.TextXAlignment = Enum.TextXAlignment.Left
TitleSmall.Parent = TitleWrap

-- minimizar
local MinBtn = Instance.new("TextButton")
MinBtn.Name = "Minimize"
MinBtn.Size = UDim2.new(0, 36, 0, 28)
MinBtn.Position = UDim2.new(1, -48, 0.5, -14)
MinBtn.BackgroundColor3 = Theme.Panel
MinBtn.Text = "–"
MinBtn.Font = Enum.Font.GothamSemibold
MinBtn.TextSize = 18
MinBtn.TextColor3 = Theme.Text
MinBtn.AutoButtonColor = false
MinBtn.Parent = Topbar
addCorner(MinBtn, 9)
addStroke(MinBtn, 1, 0.82, Theme.Stroke)

MinBtn.MouseEnter:Connect(function()
	tween(MinBtn, {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}, 0.12)
end)
MinBtn.MouseLeave:Connect(function()
	tween(MinBtn, {BackgroundColor3 = Theme.Panel}, 0.12)
end)

makeDraggable(Topbar, Main)

-- Body
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -48)
Body.Position = UDim2.new(0, 0, 0, 48)
Body.BackgroundTransparency = 1
Body.Parent = Main

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundTransparency = 1
Sidebar.Parent = Body

local SidePad = Instance.new("Frame")
SidePad.BackgroundTransparency = 1
SidePad.Size = UDim2.new(1, 0, 1, 0)
SidePad.Parent = Sidebar
addPadding(SidePad, 12)

local TabsList = Instance.new("UIListLayout")
TabsList.Padding = UDim.new(0, 8)
TabsList.SortOrder = Enum.SortOrder.LayoutOrder
TabsList.Parent = SidePad

-- Content
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -160, 1, 0)
Content.Position = UDim2.new(0, 160, 0, 0)
Content.BackgroundTransparency = 1
Content.Parent = Body

local ContentPad = Instance.new("Frame")
ContentPad.BackgroundTransparency = 1
ContentPad.Size = UDim2.new(1, 0, 1, 0)
ContentPad.Parent = Content
addPadding(ContentPad, 12)

local Pages = Instance.new("Folder")
Pages.Name = "Pages"
Pages.Parent = ContentPad

-- Library
local Library = {}
local Active = {TabBtn=nil, Page=nil}

function Library:Divider(parent, text)
	local Wrap = Instance.new("Frame")
	Wrap.BackgroundTransparency = 1
	Wrap.Size = UDim2.new(1, 0, 0, 28)
	Wrap.Parent = parent

	local Line = Instance.new("Frame")
	Line.BorderSizePixel = 0
	Line.BackgroundColor3 = Theme.Line
	Line.BackgroundTransparency = 0.15
	Line.Size = UDim2.new(1, 0, 0, 1)
	Line.Position = UDim2.new(0, 0, 0.5, 0)
	Line.Parent = Wrap

	local Grad = Instance.new("UIGradient")
	Grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Panel2),
		ColorSequenceKeypoint.new(0.5, Theme.Line),
		ColorSequenceKeypoint.new(1, Theme.Panel2),
	})
	Grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	Grad.Parent = Line

	if text and text ~= "" then
		local Label = Instance.new("TextLabel")
		Label.BackgroundColor3 = Theme.Panel2
		Label.BorderSizePixel = 0
		Label.AnchorPoint = Vector2.new(0.5, 0.5)
		Label.Position = UDim2.new(0.5, 0, 0.5, 0)
		Label.Size = UDim2.new(0, 140, 0, 20)
		Label.Font = Enum.Font.GothamSemibold
		Label.Text = text
		Label.TextSize = 12
		Label.TextColor3 = Theme.SubText
		Label.Parent = Wrap
		addCorner(Label, 999)
		addStroke(Label, 1, 0.9, Theme.Stroke)
	end

	return Wrap
end

function Library:CreateTab(name)
	local TabBtn = Instance.new("TextButton")
	TabBtn.Size = UDim2.new(1, 0, 0, 36)
	TabBtn.BackgroundColor3 = Theme.Panel2
	TabBtn.Text = name
	TabBtn.Font = Enum.Font.GothamSemibold
	TabBtn.TextSize = 13
	TabBtn.TextColor3 = Theme.SubText
	TabBtn.AutoButtonColor = false
	TabBtn.Parent = SidePad
	addCorner(TabBtn, 10)
	local st = addStroke(TabBtn, 1, 0.86, Theme.Stroke)

	local Page = Instance.new("ScrollingFrame")
	Page.Size = UDim2.new(1, 0, 1, 0)
	Page.BackgroundTransparency = 1
	Page.ScrollBarThickness = 3
	Page.ScrollBarImageTransparency = 0.65
	Page.CanvasSize = UDim2.new(0,0,0,0)
	Page.Visible = false
	Page.Parent = Pages

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 10)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Page

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 12)
	end)

	local function setActive()
		if Active.TabBtn then
			tween(Active.TabBtn, {BackgroundColor3 = Theme.Panel2}, 0.12)
			Active.TabBtn.TextColor3 = Theme.SubText
		end
		if Active.Page then Active.Page.Visible = false end

		Active.TabBtn, Active.Page = TabBtn, Page
		Page.Visible = true
		tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(34, 34, 46)}, 0.12)
		TabBtn.TextColor3 = Theme.Text
		st.Transparency = 0.55
	end

	TabBtn.MouseEnter:Connect(function()
		if Active.TabBtn ~= TabBtn then
			tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}, 0.12)
		end
	end)
	TabBtn.MouseLeave:Connect(function()
		if Active.TabBtn ~= TabBtn then
			tween(TabBtn, {BackgroundColor3 = Theme.Panel2}, 0.12)
		end
	end)

	TabBtn.MouseButton1Click:Connect(setActive)

	local tabObj = {}

	function tabObj:Section(titleText)
		local Section = Instance.new("Frame")
		Section.BackgroundColor3 = Theme.Panel2
		Section.Size = UDim2.new(1, 0, 0, 44)
		Section.Parent = Page
		addCorner(Section, 12)
		addStroke(Section, 1, 0.84, Theme.Stroke)

		local Pad = Instance.new("Frame")
		Pad.BackgroundTransparency = 1
		Pad.Size = UDim2.new(1, 0, 1, 0)
		Pad.Parent = Section
		addPadding(Pad, 12)

		local TitleLabel = Instance.new("TextLabel")
		TitleLabel.BackgroundTransparency = 1
		TitleLabel.Size = UDim2.new(1, 0, 0, 18)
		TitleLabel.Font = Enum.Font.GothamSemibold
		TitleLabel.Text = titleText
		TitleLabel.TextSize = 13
		TitleLabel.TextColor3 = Theme.Text
		TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		TitleLabel.Parent = Pad

		local Items = Instance.new("Frame")
		Items.BackgroundTransparency = 1
		Items.Size = UDim2.new(1, 0, 1, -18)
		Items.Position = UDim2.new(0, 0, 0, 18)
		Items.Parent = Pad

		local ItemsLayout = Instance.new("UIListLayout")
		ItemsLayout.Padding = UDim.new(0, 8)
		ItemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ItemsLayout.Parent = Items

		ItemsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Section.Size = UDim2.new(1, 0, 0, ItemsLayout.AbsoluteContentSize.Y + 18 + 24)
		end)

		local secObj = {}

		function secObj:Divider(text)
			return Library:Divider(Items, text)
		end

		function secObj:Toggle(text, default, callback)
			local Row = Instance.new("Frame")
			Row.Size = UDim2.new(1, 0, 0, 34)
			Row.BackgroundColor3 = Theme.Panel
			Row.Parent = Items
			addCorner(Row, 10)
			addStroke(Row, 1, 0.86, Theme.Stroke)

			local Label = Instance.new("TextLabel")
			Label.BackgroundTransparency = 1
			Label.Size = UDim2.new(1, -70, 1, 0)
			Label.Position = UDim2.new(0, 12, 0, 0)
			Label.Font = Enum.Font.GothamSemibold
			Label.Text = text
			Label.TextSize = 13
			Label.TextColor3 = Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = Row

			local Switch = Instance.new("Frame")
			Switch.Size = UDim2.new(0, 44, 0, 22)
			Switch.Position = UDim2.new(1, -56, 0.5, -11)
			Switch.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
			Switch.Parent = Row
			addCorner(Switch, 999)
			addStroke(Switch, 1, 0.88, Theme.Stroke)

			local Knob = Instance.new("Frame")
			Knob.Size = UDim2.new(0, 18, 0, 18)
			Knob.Position = UDim2.new(0, 2, 0.5, -9)
			Knob.BackgroundColor3 = Theme.SubText
			Knob.Parent = Switch
			addCorner(Knob, 999)

			local state = default == true

			local function render()
				if state then
					tween(Switch, {BackgroundColor3 = Theme.Accent}, 0.12)
					tween(Knob, {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = Theme.Text}, 0.12)
				else
					tween(Switch, {BackgroundColor3 = Color3.fromRGB(35, 35, 42)}, 0.12)
					tween(Knob, {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Theme.SubText}, 0.12)
				end
			end
			render()

			local Click = Instance.new("TextButton")
			Click.BackgroundTransparency = 1
			Click.Size = UDim2.new(1, 0, 1, 0)
			Click.Text = ""
			Click.Parent = Row

			Click.MouseEnter:Connect(function()
				tween(Row, {BackgroundColor3 = Color3.fromRGB(26, 26, 34)}, 0.12)
			end)
			Click.MouseLeave:Connect(function()
				tween(Row, {BackgroundColor3 = Theme.Panel}, 0.12)
			end)

			Click.MouseButton1Click:Connect(function()
				state = not state
				render()
				if callback then callback(state) end
			end)

			return { Get=function() return state end }
		end

		function secObj:Slider(text, min, max, default, callback)
			min, max = min or 0, max or 100
			default = default or min

			local Holder = Instance.new("Frame")
			Holder.Size = UDim2.new(1, 0, 0, 48)
			Holder.BackgroundColor3 = Theme.Panel
			Holder.Parent = Items
			addCorner(Holder, 10)
			addStroke(Holder, 1, 0.86, Theme.Stroke)

			local Label = Instance.new("TextLabel")
			Label.BackgroundTransparency = 1
			Label.Size = UDim2.new(1, -80, 0, 18)
			Label.Position = UDim2.new(0, 12, 0, 8)
			Label.Font = Enum.Font.GothamSemibold
			Label.Text = text
			Label.TextSize = 13
			Label.TextColor3 = Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = Holder

			local ValLabel = Instance.new("TextLabel")
			ValLabel.BackgroundTransparency = 1
			ValLabel.Size = UDim2.new(0, 60, 0, 18)
			ValLabel.Position = UDim2.new(1, -72, 0, 8)
			ValLabel.Font = Enum.Font.Gotham
			ValLabel.Text = tostring(default)
			ValLabel.TextSize = 12
			ValLabel.TextColor3 = Theme.SubText
			ValLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValLabel.Parent = Holder

			local Bar = Instance.new("Frame")
			Bar.Size = UDim2.new(1, -24, 0, 8)
			Bar.Position = UDim2.new(0, 12, 0, 32)
			Bar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
			Bar.Parent = Holder
			addCorner(Bar, 999)

			local Fill = Instance.new("Frame")
			Fill.Size = UDim2.new(0, 0, 1, 0)
			Fill.BackgroundColor3 = Theme.Accent
			Fill.Parent = Bar
			addCorner(Fill, 999)

			local dragging = false
			local value = default

			local function setValue(v)
				v = math.clamp(v, min, max)
				value = v
				ValLabel.Text = tostring(math.floor(v + 0.5))
				local a = (v - min) / (max - min)
				Fill.Size = UDim2.new(a, 0, 1, 0)
				if callback then callback(value) end
			end

			local function updateFromX(x)
				local rel = (x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X
				setValue(min + (max - min) * rel)
			end

			setValue(default)

			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateFromX(input.Position.X)
				end
			end)

			Bar.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromX(input.Position.X)
				end
			end)

			Holder.MouseEnter:Connect(function()
				tween(Holder, {BackgroundColor3 = Color3.fromRGB(26, 26, 34)}, 0.12)
			end)
			Holder.MouseLeave:Connect(function()
				tween(Holder, {BackgroundColor3 = Theme.Panel}, 0.12)
			end)

			return { Get=function() return value end, Set=setValue }
		end

		return secObj
	end

	tabObj._activate = setActive
	return tabObj
end

-- ===== BUILD TABS =====
local universal = Library:CreateTab("universal")
local combat = Library:CreateTab("combat")
local visual = Library:CreateTab("visual")

-- ativar primeira tab
universal._activate()

-- ===== UNIVERSAL CONTENT =====
do
	local sec = universal:Section("essentials")

	sec:Divider("session")

	-- Anti-AFK (callback seguro: você liga no seu sistema / seu jogo)
	sec:Toggle("anti-afk", false, function(enabled)
		-- ⚠️ Use isso apenas no seu jogo/experiência ou em testes com permissão.
		print("anti-afk:", enabled)
	end)

	sec:Divider("movement")

	-- WalkSpeed (callback)
	sec:Slider("walk speed", 8, 32, 16, function(v)
		-- ⚠️ Ideal é controlar isso pelo SERVIDOR no seu jogo.
		-- Aqui é só callback de UI.
		print("walk speed:", v)
	end)
end

-- ===== EXEMPLOS OUTRAS TABS =====
do
	local sec = combat:Section("main")
	sec:Divider("controls")
	sec:Toggle("aim assist", false, function(v) print("aim assist:", v) end)
end

do
	local sec = visual:Section("esp")
	sec:Divider("options")
	sec:Toggle("items esp", false, function(v) print("items esp:", v) end)
end

-- ===== MINIMIZE FIX =====
local minimized = false
local originalSize = Main.Size
local bodyVisible = true

local function setBodyVisible(v)
	bodyVisible = v
	for _, ch in ipairs(Body:GetChildren()) do
		ch.Visible = v
	end
end

MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		setBodyVisible(false)
		tween(Main, {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 48)}, 0.18)
	else
		tween(Main, {Size = originalSize}, 0.18)
		task.delay(0.14, function()
			if not minimized then setBodyVisible(true) end
		end)
	end
end)

-- hotkey: RightShift
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		ScreenGui.Enabled = not ScreenGui.Enabled
	end
end)
