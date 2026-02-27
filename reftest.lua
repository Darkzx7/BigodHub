--// ref ui (library-like) - LocalScript

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- cleanup (opcional: remove UI antiga)
local old = pg:FindFirstChild("ref_ui")
if old then old:Destroy() end

--// helpers
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
	s.Transparency = tr or 0.6
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

--// theme
local Theme = {
	BG = Color3.fromRGB(14, 14, 16),
	Panel = Color3.fromRGB(18, 18, 22),
	Panel2 = Color3.fromRGB(22, 22, 27),
	Stroke = Color3.fromRGB(255, 255, 255),

	Text = Color3.fromRGB(235, 235, 240),
	SubText = Color3.fromRGB(170, 170, 180),

	Accent = Color3.fromRGB(120, 80, 255), -- roxo "library"
	Accent2 = Color3.fromRGB(80, 180, 255),

	Good = Color3.fromRGB(70, 200, 120),
	Bad = Color3.fromRGB(255, 90, 110),
}

--// ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ref_ui"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = pg

--// Main window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 520, 0, 330)
Main.Position = UDim2.new(0.5, -260, 0.5, -165)
Main.BackgroundColor3 = Theme.Panel
Main.Parent = ScreenGui
addCorner(Main, 14)
addStroke(Main, 1, 0.75, Theme.Stroke)

local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://1316045217"
Shadow.ImageTransparency = 0.82
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.Size = UDim2.new(1, 28, 1, 28)
Shadow.Position = UDim2.new(0, -14, 0, -14)
Shadow.Parent = Main

--// Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 46)
Topbar.BackgroundColor3 = Theme.Panel2
Topbar.Parent = Main
addCorner(Topbar, 14)

-- fix corner clipping (top only)
local TopbarMask = Instance.new("Frame")
TopbarMask.BackgroundColor3 = Theme.Panel2
TopbarMask.BorderSizePixel = 0
TopbarMask.Size = UDim2.new(1, 0, 0, 14)
TopbarMask.Position = UDim2.new(0, 0, 1, -14)
TopbarMask.Parent = Topbar

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.Font = Enum.Font.GothamSemibold
Title.Text = "ref"
Title.TextSize = 16
Title.TextColor3 = Theme.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Size = UDim2.new(1, -120, 1, 0)
Subtitle.Position = UDim2.new(0, 16, 0, 16)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "ui"
Subtitle.TextSize = 12
Subtitle.TextColor3 = Theme.SubText
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Topbar

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "Minimize"
MinBtn.Size = UDim2.new(0, 34, 0, 26)
MinBtn.Position = UDim2.new(1, -44, 0.5, -13)
MinBtn.BackgroundColor3 = Theme.Panel
MinBtn.Text = "–"
MinBtn.Font = Enum.Font.GothamSemibold
MinBtn.TextSize = 18
MinBtn.TextColor3 = Theme.Text
MinBtn.AutoButtonColor = false
MinBtn.Parent = Topbar
addCorner(MinBtn, 8)
addStroke(MinBtn, 1, 0.8, Theme.Stroke)

MinBtn.MouseEnter:Connect(function()
	tween(MinBtn, {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}, 0.12)
end)
MinBtn.MouseLeave:Connect(function()
	tween(MinBtn, {BackgroundColor3 = Theme.Panel}, 0.12)
end)

-- draggable
makeDraggable(Topbar, Main)

--// Body
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -46)
Body.Position = UDim2.new(0, 0, 0, 46)
Body.BackgroundTransparency = 1
Body.Parent = Main

-- Sidebar tabs
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 150, 1, 0)
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

-- Content area
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -150, 1, 0)
Content.Position = UDim2.new(0, 150, 0, 0)
Content.BackgroundTransparency = 1
Content.Parent = Body

local ContentPad = Instance.new("Frame")
ContentPad.BackgroundTransparency = 1
ContentPad.Size = UDim2.new(1, 0, 1, 0)
ContentPad.Parent = Content
addPadding(ContentPad, 12)

-- Pages container
local Pages = Instance.new("Folder")
Pages.Name = "Pages"
Pages.Parent = ContentPad

--// components factory (estilo library)
local Library = {}

function Library:CreateTab(name)
	-- tab button
	local TabBtn = Instance.new("TextButton")
	TabBtn.Name = "Tab_"..name
	TabBtn.Size = UDim2.new(1, 0, 0, 36)
	TabBtn.BackgroundColor3 = Theme.Panel2
	TabBtn.Text = name
	TabBtn.Font = Enum.Font.GothamSemibold
	TabBtn.TextSize = 13
	TabBtn.TextColor3 = Theme.SubText
	TabBtn.AutoButtonColor = false
	TabBtn.Parent = SidePad
	addCorner(TabBtn, 10)
	local st = addStroke(TabBtn, 1, 0.85, Theme.Stroke)

	-- page
	local Page = Instance.new("ScrollingFrame")
	Page.Name = "Page_"..name
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
		Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
	end)

	-- hover
	TabBtn.MouseEnter:Connect(function()
		tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}, 0.12)
	end)
	TabBtn.MouseLeave:Connect(function()
		-- não sobrescreve se estiver ativo
	end)

	local tabObj = {}

	function tabObj:SetActive(active)
		if active then
			Page.Visible = true
			tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(34, 34, 46)}, 0.12)
			TabBtn.TextColor3 = Theme.Text
			st.Transparency = 0.55
		else
			Page.Visible = false
			tween(TabBtn, {BackgroundColor3 = Theme.Panel2}, 0.12)
			TabBtn.TextColor3 = Theme.SubText
			st.Transparency = 0.85
		end
	end

	function tabObj:Section(titleText)
		local Section = Instance.new("Frame")
		Section.BackgroundColor3 = Theme.Panel2
		Section.Size = UDim2.new(1, 0, 0, 44)
		Section.Parent = Page
		addCorner(Section, 12)
		addStroke(Section, 1, 0.82, Theme.Stroke)

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

		function secObj:Button(text, callback)
			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 0, 34)
			Btn.BackgroundColor3 = Theme.Panel
			Btn.Text = text
			Btn.Font = Enum.Font.GothamSemibold
			Btn.TextSize = 13
			Btn.TextColor3 = Theme.Text
			Btn.AutoButtonColor = false
			Btn.Parent = Items
			addCorner(Btn, 10)
			addStroke(Btn, 1, 0.85, Theme.Stroke)

			Btn.MouseEnter:Connect(function()
				tween(Btn, {BackgroundColor3 = Color3.fromRGB(26, 26, 34)}, 0.12)
			end)
			Btn.MouseLeave:Connect(function()
				tween(Btn, {BackgroundColor3 = Theme.Panel}, 0.12)
			end)

			Btn.MouseButton1Down:Connect(function()
				tween(Btn, {Size = UDim2.new(1, -2, 0, 33)}, 0.06)
			end)
			Btn.MouseButton1Up:Connect(function()
				tween(Btn, {Size = UDim2.new(1, 0, 0, 34)}, 0.08)
			end)

			Btn.MouseButton1Click:Connect(function()
				if callback then callback() end
			end)
		end

		function secObj:Toggle(text, default, callback)
			local Row = Instance.new("Frame")
			Row.Size = UDim2.new(1, 0, 0, 34)
			Row.BackgroundColor3 = Theme.Panel
			Row.Parent = Items
			addCorner(Row, 10)
			addStroke(Row, 1, 0.85, Theme.Stroke)

			local Label = Instance.new("TextLabel")
			Label.BackgroundTransparency = 1
			Label.Size = UDim2.new(1, -64, 1, 0)
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
			addStroke(Switch, 1, 0.85, Theme.Stroke)

			local Knob = Instance.new("Frame")
			Knob.Size = UDim2.new(0, 18, 0, 18)
			Knob.Position = UDim2.new(0, 2, 0.5, -9)
			Knob.BackgroundColor3 = Theme.SubText
			Knob.Parent = Switch
			addCorner(Knob, 999)

			local state = default and true or false

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

			return {
				Set = function(_, v)
					state = (v == true)
					render()
				end,
				Get = function()
					return state
				end
			}
		end

		function secObj:Slider(text, min, max, default, callback)
			min = min or 0
			max = max or 100
			default = default or min

			local Holder = Instance.new("Frame")
			Holder.Size = UDim2.new(1, 0, 0, 48)
			Holder.BackgroundColor3 = Theme.Panel
			Holder.Parent = Items
			addCorner(Holder, 10)
			addStroke(Holder, 1, 0.85, Theme.Stroke)

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
				ValLabel.Text = tostring(math.floor(v))
				local alpha = (v - min) / (max - min)
				Fill.Size = UDim2.new(alpha, 0, 1, 0)
				if callback then callback(value) end
			end

			setValue(default)

			local function updateFromX(x)
				local rel = (x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X
				local v = min + (max - min) * rel
				setValue(v)
			end

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

			return {
				Set = function(_, v) setValue(v) end,
				Get = function() return value end
			}
		end

		return secObj
	end

	-- click: switch pages
	TabBtn.MouseButton1Click:Connect(function()
		for _, p in ipairs(Pages:GetChildren()) do
			if p:IsA("ScrollingFrame") then p.Visible = false end
		end
		for _, b in ipairs(SidePad:GetChildren()) do
			if b:IsA("TextButton") then
				tween(b, {BackgroundColor3 = Theme.Panel2}, 0.12)
				b.TextColor3 = Theme.SubText
			end
		end
		Page.Visible = true
		tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(34, 34, 46)}, 0.12)
		TabBtn.TextColor3 = Theme.Text
	end)

	return tabObj, TabBtn, Page
end

--// build example
local tabs = {}

local combatTab = Library:CreateTab("combat")
tabs[#tabs+1] = combatTab

local visualTab = Library:CreateTab("visual")
tabs[#tabs+1] = visualTab

-- activate first tab by default
do
	-- manually click first
	for i, child in ipairs(SidePad:GetChildren()) do
		if child:IsA("TextButton") then
			child:Activate()
			child:CaptureFocus()
			child.MouseButton1Click:Fire()
			break
		end
	end
	-- fallback:
	for _, p in ipairs(Pages:GetChildren()) do
		if p:IsA("ScrollingFrame") then
			p.Visible = (p.Name == "Page_combat")
		end
	end
end

-- sections + controls
do
	local sec = combatTab:Section("main")
	sec:Toggle("aim assist", false, function(v)
		print("aim assist:", v)
	end)
	sec:Slider("fov", 30, 180, 90, function(v)
		-- print("fov:", v)
	end)
	sec:Button("do action", function()
		print("clicked")
	end)
end

do
	local sec = visualTab:Section("esp")
	sec:Toggle("items esp", false, function(v)
		print("items esp:", v)
	end)
	sec:Slider("distance", 50, 2000, 600, function(v)
		-- print("distance:", v)
	end)
end

-- minimize behavior
local minimized = false
local originalSize = Main.Size

MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		tween(Main, {Size = UDim2.new(0, 520, 0, 46)}, 0.18)
		for _, ch in ipairs(Body:GetChildren()) do ch.Visible = false end
	else
		for _, ch in ipairs(Body:GetChildren()) do ch.Visible = true end
		tween(Main, {Size = originalSize}, 0.18)
	end
end)

-- hotkey (RightShift)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		ScreenGui.Enabled = not ScreenGui.Enabled
	end
end)
