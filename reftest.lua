--// ref ui - LocalScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

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
	s.Color = color or Color3.fromRGB(255, 255, 255)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function addPadding(inst, p)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, p or 10)
	pad.PaddingRight  = UDim.new(0, p or 10)
	pad.PaddingTop    = UDim.new(0, p or 10)
	pad.PaddingBottom = UDim.new(0, p or 10)
	pad.Parent = inst
	return pad
end

local function makeDraggable(handle, frame)
	local dragging, dragStart, startPos = false, nil, nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos  = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

-- theme
local Theme = {
	Panel  = Color3.fromRGB(18, 18, 22),
	Panel2 = Color3.fromRGB(22, 22, 27),
	Stroke = Color3.fromRGB(255, 255, 255),
	Text   = Color3.fromRGB(235, 235, 240),
	Sub    = Color3.fromRGB(170, 170, 180),
	Accent = Color3.fromRGB(120, 80, 255),
	Line   = Color3.fromRGB(60, 60, 72),
}

-- ScreenGui principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ref_ui"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = pg

-- ScreenGui separado para ESP (AlwaysOnTop precisa de ScreenGui dedicada)
local EspGui = Instance.new("ScreenGui")
EspGui.Name = "ref_esp"
EspGui.IgnoreGuiInset = true
EspGui.ResetOnSpawn = false
EspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
EspGui.Parent = pg

-- ===== ÍCONE (sempre visível, sem sombra) =====
local IconBtn = Instance.new("ImageButton")
IconBtn.Name = "IconBtn"
IconBtn.Size = UDim2.new(0, 52, 0, 52)
IconBtn.Position = UDim2.new(0, 16, 0.5, -26)
IconBtn.BackgroundColor3 = Theme.Panel2
IconBtn.Image = "rbxassetid://131165537896572"
IconBtn.ScaleType = Enum.ScaleType.Fit
IconBtn.AutoButtonColor = false
IconBtn.ZIndex = 10
IconBtn.Parent = ScreenGui
addCorner(IconBtn, 14)
addStroke(IconBtn, 1, 0.70, Theme.Stroke)

makeDraggable(IconBtn, IconBtn)

IconBtn.MouseEnter:Connect(function()
	tween(IconBtn, {BackgroundColor3 = Color3.fromRGB(34, 34, 46)}, 0.12)
end)
IconBtn.MouseLeave:Connect(function()
	tween(IconBtn, {BackgroundColor3 = Theme.Panel2}, 0.12)
end)

-- ===== PAINEL DO USUÁRIO (canto inferior esquerdo) =====
local UserPanel = Instance.new("Frame")
UserPanel.Name = "UserPanel"
UserPanel.Size = UDim2.new(0, 160, 0, 52)
UserPanel.Position = UDim2.new(0, 16, 1, -68) -- 16px da esquerda, 16px do fundo
UserPanel.BackgroundColor3 = Theme.Panel2
UserPanel.ZIndex = 5
UserPanel.Parent = ScreenGui
addCorner(UserPanel, 12)
addStroke(UserPanel, 1, 0.78, Theme.Stroke)

-- avatar (thumbnail gerado via Players)
local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Name = "Avatar"
AvatarImg.Size = UDim2.new(0, 36, 0, 36)
AvatarImg.Position = UDim2.new(0, 8, 0.5, -18)
AvatarImg.BackgroundColor3 = Theme.Panel
AvatarImg.Image = Players:GetUserThumbnailAsync(
	player.UserId,
	Enum.ThumbnailType.HeadShot,
	Enum.ThumbnailSize.Size48x48
)
AvatarImg.ZIndex = 6
AvatarImg.Parent = UserPanel
addCorner(AvatarImg, 999) -- circular

addStroke(AvatarImg, 1.5, 0.60, Theme.Accent)

-- linha accent lateral esquerda
local UserAccent = Instance.new("Frame")
UserAccent.Size = UDim2.new(0, 2, 0, 28)
UserAccent.Position = UDim2.new(0, 52, 0.5, -14)
UserAccent.BackgroundColor3 = Theme.Accent
UserAccent.BorderSizePixel = 0
UserAccent.BackgroundTransparency = 0.30
UserAccent.ZIndex = 6
UserAccent.Parent = UserPanel
addCorner(UserAccent, 999)

-- nome do display
local UserName = Instance.new("TextLabel")
UserName.BackgroundTransparency = 1
UserName.Size = UDim2.new(1, -66, 0, 16)
UserName.Position = UDim2.new(0, 62, 0, 10)
UserName.Font = Enum.Font.GothamSemibold
UserName.Text = player.DisplayName
UserName.TextSize = 12
UserName.TextColor3 = Theme.Text
UserName.TextXAlignment = Enum.TextXAlignment.Left
UserName.TextTruncate = Enum.TextTruncate.AtEnd
UserName.ZIndex = 6
UserName.Parent = UserPanel

-- @username abaixo
local UserTag = Instance.new("TextLabel")
UserTag.BackgroundTransparency = 1
UserTag.Size = UDim2.new(1, -66, 0, 13)
UserTag.Position = UDim2.new(0, 62, 0, 28)
UserTag.Font = Enum.Font.Gotham
UserTag.Text = "@" .. player.Name
UserTag.TextSize = 10
UserTag.TextColor3 = Theme.Sub
UserTag.TextXAlignment = Enum.TextXAlignment.Left
UserTag.TextTruncate = Enum.TextTruncate.AtEnd
UserTag.ZIndex = 6
UserTag.Parent = UserPanel

-- ===== MAIN FRAME =====
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 540, 0, 340)
Main.Position = UDim2.new(0.5, -270, 0.5, -170)
Main.BackgroundColor3 = Theme.Panel
Main.Parent = ScreenGui
addCorner(Main, 14)
addStroke(Main, 1, 0.75, Theme.Stroke)

local Shadow = Instance.new("ImageLabel")
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://1316045217"
Shadow.ImageTransparency = 0.90
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.Size = UDim2.new(1, 34, 1, 34)
Shadow.Position = UDim2.new(0, -17, 0, -17)
Shadow.ZIndex = 0
Shadow.Parent = Main
Main.ZIndex = 1

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 48)
Topbar.BackgroundColor3 = Theme.Panel2
Topbar.Parent = Main
addCorner(Topbar, 14)

local AccentLine = Instance.new("Frame")
AccentLine.BackgroundColor3 = Theme.Accent
AccentLine.BorderSizePixel = 0
AccentLine.Size = UDim2.new(1, 0, 0, 1)
AccentLine.Position = UDim2.new(0, 0, 1, -1)
AccentLine.BackgroundTransparency = 0.35
AccentLine.Parent = Topbar

local TitleWrap = Instance.new("Frame")
TitleWrap.BackgroundTransparency = 1
TitleWrap.Size = UDim2.new(0, 180, 0, 24)
TitleWrap.AnchorPoint = Vector2.new(0.5, 0.5)
TitleWrap.Position = UDim2.new(0.5, 0, 0.5, 0)
TitleWrap.Parent = Topbar

local TitleA = Instance.new("TextLabel")
TitleA.BackgroundTransparency = 1
TitleA.Size = UDim2.new(0, 60, 1, 0)
TitleA.Position = UDim2.new(0.5, -30, 0, 0)
TitleA.Font = Enum.Font.GothamSemibold
TitleA.Text = "ref"
TitleA.TextSize = 18
TitleA.TextColor3 = Theme.Text
TitleA.TextXAlignment = Enum.TextXAlignment.Right
TitleA.Parent = TitleWrap

local TitleB = Instance.new("TextLabel")
TitleB.BackgroundTransparency = 1
TitleB.Size = UDim2.new(0, 50, 1, 0)
TitleB.Position = UDim2.new(0.5, 32, 0, 0)
TitleB.Font = Enum.Font.Gotham
TitleB.Text = "ui"
TitleB.TextSize = 14
TitleB.TextColor3 = Theme.Sub
TitleB.TextXAlignment = Enum.TextXAlignment.Left
TitleB.Parent = TitleWrap

local MinBtn = Instance.new("TextButton")
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
Body.Size = UDim2.new(1, 0, 1, -48)
Body.Position = UDim2.new(0, 0, 0, 48)
Body.BackgroundTransparency = 1
Body.Parent = Main

-- Sidebar
local SidePad = Instance.new("Frame")
SidePad.BackgroundTransparency = 1
SidePad.Size = UDim2.new(0, 160, 1, 0)
SidePad.Parent = Body
addPadding(SidePad, 12)

local TabsList = Instance.new("UIListLayout")
TabsList.Padding = UDim.new(0, 8)
TabsList.SortOrder = Enum.SortOrder.LayoutOrder
TabsList.Parent = SidePad

-- Content
local ContentPad = Instance.new("Frame")
ContentPad.BackgroundTransparency = 1
ContentPad.Size = UDim2.new(1, -160, 1, 0)
ContentPad.Position = UDim2.new(0, 160, 0, 0)
ContentPad.Parent = Body
addPadding(ContentPad, 12)

local Pages = Instance.new("Folder")
Pages.Parent = ContentPad

-- ===== LIBRARY =====
local Library = {}
local Active = {TabBtn = nil, Page = nil}

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
		local Lbl = Instance.new("TextLabel")
		Lbl.BackgroundColor3 = Theme.Panel2
		Lbl.BorderSizePixel = 0
		Lbl.AnchorPoint = Vector2.new(0.5, 0.5)
		Lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
		Lbl.Size = UDim2.new(0, 140, 0, 20)
		Lbl.Font = Enum.Font.GothamSemibold
		Lbl.Text = text
		Lbl.TextSize = 12
		Lbl.TextColor3 = Theme.Sub
		Lbl.Parent = Wrap
		addCorner(Lbl, 999)
		addStroke(Lbl, 1, 0.9, Theme.Stroke)
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
	TabBtn.TextColor3 = Theme.Sub
	TabBtn.AutoButtonColor = false
	TabBtn.Parent = SidePad
	addCorner(TabBtn, 10)
	local st = addStroke(TabBtn, 1, 0.86, Theme.Stroke)

	local Page = Instance.new("ScrollingFrame")
	Page.Size = UDim2.new(1, 0, 1, 0)
	Page.BackgroundTransparency = 1
	Page.ScrollBarThickness = 3
	Page.ScrollBarImageTransparency = 0.65
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
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
			Active.TabBtn.TextColor3 = Theme.Sub
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

		local TitleLbl = Instance.new("TextLabel")
		TitleLbl.BackgroundTransparency = 1
		TitleLbl.Size = UDim2.new(1, 0, 0, 18)
		TitleLbl.Font = Enum.Font.GothamSemibold
		TitleLbl.Text = titleText
		TitleLbl.TextSize = 13
		TitleLbl.TextColor3 = Theme.Text
		TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
		TitleLbl.Parent = Pad

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

			local Lbl = Instance.new("TextLabel")
			Lbl.BackgroundTransparency = 1
			Lbl.Size = UDim2.new(1, -70, 1, 0)
			Lbl.Position = UDim2.new(0, 12, 0, 0)
			Lbl.Font = Enum.Font.GothamSemibold
			Lbl.Text = text
			Lbl.TextSize = 13
			Lbl.TextColor3 = Theme.Text
			Lbl.TextXAlignment = Enum.TextXAlignment.Left
			Lbl.Parent = Row

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
			Knob.BackgroundColor3 = Theme.Sub
			Knob.Parent = Switch
			addCorner(Knob, 999)

			local state = default == true

			local function render()
				if state then
					tween(Switch, {BackgroundColor3 = Theme.Accent}, 0.12)
					tween(Knob, {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = Theme.Text}, 0.12)
				else
					tween(Switch, {BackgroundColor3 = Color3.fromRGB(35, 35, 42)}, 0.12)
					tween(Knob, {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Theme.Sub}, 0.12)
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
				Get = function() return state end,
				Set = function(v) state = v render() if callback then callback(state) end end,
			}
		end

		function secObj:Slider(text, min, max, default, callback)
			min, max = min or 0, max or 100
			default = math.clamp(default or min, min, max)

			local Holder = Instance.new("Frame")
			Holder.Size = UDim2.new(1, 0, 0, 48)
			Holder.BackgroundColor3 = Theme.Panel
			Holder.Parent = Items
			addCorner(Holder, 10)
			addStroke(Holder, 1, 0.86, Theme.Stroke)

			local Lbl = Instance.new("TextLabel")
			Lbl.BackgroundTransparency = 1
			Lbl.Size = UDim2.new(1, -80, 0, 18)
			Lbl.Position = UDim2.new(0, 12, 0, 8)
			Lbl.Font = Enum.Font.GothamSemibold
			Lbl.Text = text
			Lbl.TextSize = 13
			Lbl.TextColor3 = Theme.Text
			Lbl.TextXAlignment = Enum.TextXAlignment.Left
			Lbl.Parent = Holder

			local ValLbl = Instance.new("TextLabel")
			ValLbl.BackgroundTransparency = 1
			ValLbl.Size = UDim2.new(0, 60, 0, 18)
			ValLbl.Position = UDim2.new(1, -72, 0, 8)
			ValLbl.Font = Enum.Font.Gotham
			ValLbl.TextSize = 12
			ValLbl.TextColor3 = Theme.Sub
			ValLbl.TextXAlignment = Enum.TextXAlignment.Right
			ValLbl.Parent = Holder

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
				ValLbl.Text = tostring(math.floor(v + 0.5))
				Fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
				if callback then callback(value) end
			end

			local function updateFromX(x)
				local rel = math.clamp((x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
				setValue(min + (max - min) * rel)
			end

			setValue(default)

			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateFromX(input.Position.X)
				end
			end)
			Bar.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromX(input.Position.X)
				end
			end)

			Holder.MouseEnter:Connect(function()
				tween(Holder, {BackgroundColor3 = Color3.fromRGB(26, 26, 34)}, 0.12)
			end)
			Holder.MouseLeave:Connect(function()
				tween(Holder, {BackgroundColor3 = Theme.Panel}, 0.12)
			end)

			return { Get = function() return value end, Set = setValue }
		end

		return secObj
	end

	tabObj._activate = setActive
	return tabObj
end

-- ===== BUILD TABS =====
local universal = Library:CreateTab("universal")
local combat    = Library:CreateTab("combat")
local visual    = Library:CreateTab("visual")
universal._activate()

-- ===== UNIVERSAL =====
do
	local sec = universal:Section("essentials")
	sec:Divider("session")

	local afkEnabled = false
	player.Idled:Connect(function()
		if not afkEnabled then return end
		local cam = workspace.CurrentCamera
		if cam then
			cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(0.001), 0)
		end
	end)

	sec:Toggle("anti-afk", false, function(enabled)
		afkEnabled = enabled
	end)

	sec:Divider("movement")

	local DEFAULT_SPEED = 16
	local speedEnabled  = false
	local currentSpeed  = DEFAULT_SPEED

	local function applySpeed()
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = speedEnabled and currentSpeed or DEFAULT_SPEED
		end
	end

	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		task.wait()
		hum.WalkSpeed = speedEnabled and currentSpeed or DEFAULT_SPEED
	end)

	sec:Toggle("custom walkspeed", false, function(enabled)
		speedEnabled = enabled
		applySpeed()
	end)

	sec:Slider("walk speed", 8, 100, DEFAULT_SPEED, function(v)
		currentSpeed = v
		if speedEnabled then applySpeed() end
	end)
end

-- ===== COMBAT =====
do
	local sec = combat:Section("main")
	sec:Divider("controls")
	sec:Toggle("aim assist", false, function(v) print("aim assist:", v) end)
end

-- ===== VISUAL: ESP PROFISSIONAL =====
do
	local sec = visual:Section("esp")
	sec:Divider("players")

	-- Estado do ESP
	local espEnabled  = false
	local showName    = true
	local showDist    = true
	local showHealth  = true
	local showBox     = true
	local maxDist     = 500
	local espColor    = Color3.fromRGB(120, 80, 255)

	local camera = workspace.CurrentCamera
	local espObjects = {} -- [Player] = { highlight, bb, ... }

	-- Cores dinâmicas por vida (verde → amarelo → vermelho)
	local function healthColor(hp, maxHp)
		local pct = math.clamp(hp / math.max(maxHp, 1), 0, 1)
		if pct > 0.5 then
			return Color3.fromRGB(
				math.floor(255 * (1 - pct) * 2),
				220,
				80
			)
		else
			return Color3.fromRGB(
				220,
				math.floor(220 * pct * 2),
				40
			)
		end
	end

	local function createESP(target)
		if espObjects[target] then return end
		local char = target.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- ── Highlight (through-walls via AlwaysOnTop na EspGui) ──
		local hl = Instance.new("Highlight")
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- atravessa paredes
		hl.FillColor = espColor
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.55
		hl.OutlineTransparency = 0.0
		hl.Adornee = char
		hl.Parent = EspGui

		-- ── BillboardGui principal (sempre visível) ──
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 180, 0, 72)
		bb.StudsOffset = Vector3.new(0, 3.5, 0)
		bb.AlwaysOnTop = true  -- visível através das paredes
		bb.ResetOnSpawn = false
		bb.ClipsDescendants = false
		bb.Adornee = hrp
		bb.Parent = EspGui

		-- Fundo semi-transparente
		local bg = Instance.new("Frame")
		bg.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
		bg.BackgroundTransparency = 0.35
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.Parent = bb
		addCorner(bg, 6)
		addStroke(bg, 1, 0.65, espColor)

		-- Nome do player
		local nameLbl = Instance.new("TextLabel")
		nameLbl.BackgroundTransparency = 1
		nameLbl.Size = UDim2.new(1, -8, 0, 20)
		nameLbl.Position = UDim2.new(0, 4, 0, 4)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 14
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextStrokeTransparency = 0.3
		nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Center
		nameLbl.Text = target.DisplayName
		nameLbl.Parent = bg

		-- Barra de HP (fundo)
		local hpBarBg = Instance.new("Frame")
		hpBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		hpBarBg.BackgroundTransparency = 0.2
		hpBarBg.Size = UDim2.new(1, -8, 0, 7)
		hpBarBg.Position = UDim2.new(0, 4, 0, 28)
		hpBarBg.Parent = bg
		addCorner(hpBarBg, 999)

		-- Barra de HP (fill)
		local hpBarFill = Instance.new("Frame")
		hpBarFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
		hpBarFill.Size = UDim2.new(1, 0, 1, 0)
		hpBarFill.Parent = hpBarBg
		addCorner(hpBarFill, 999)

		-- Texto hp / dist
		local infoLbl = Instance.new("TextLabel")
		infoLbl.BackgroundTransparency = 1
		infoLbl.Size = UDim2.new(1, -8, 0, 16)
		infoLbl.Position = UDim2.new(0, 4, 0, 40)
		infoLbl.Font = Enum.Font.Gotham
		infoLbl.TextSize = 11
		infoLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
		infoLbl.TextStrokeTransparency = 0.4
		infoLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		infoLbl.TextXAlignment = Enum.TextXAlignment.Center
		infoLbl.Text = ""
		infoLbl.Parent = bg

		-- Distância no canto superior direito (pequena)
		local distLbl = Instance.new("TextLabel")
		distLbl.BackgroundTransparency = 1
		distLbl.Size = UDim2.new(0, 50, 0, 14)
		distLbl.Position = UDim2.new(1, -54, 0, 4)
		distLbl.Font = Enum.Font.Gotham
		distLbl.TextSize = 10
		distLbl.TextColor3 = Color3.fromRGB(170, 170, 200)
		distLbl.TextXAlignment = Enum.TextXAlignment.Right
		distLbl.Text = ""
		distLbl.Parent = bg

		espObjects[target] = {
			hl        = hl,
			bb        = bb,
			bg        = bg,
			bgStroke  = bg:FindFirstChildOfClass("UIStroke"),
			nameLbl   = nameLbl,
			hpBarBg   = hpBarBg,
			hpBarFill = hpBarFill,
			infoLbl   = infoLbl,
			distLbl   = distLbl,
		}
	end

	local function removeESP(target)
		local obj = espObjects[target]
		if not obj then return end
		obj.hl:Destroy()
		obj.bb:Destroy()
		espObjects[target] = nil
	end

	local function clearAllESP()
		for target in pairs(espObjects) do
			removeESP(target)
		end
	end

	-- Update loop
	RunService.RenderStepped:Connect(function()
		if not espEnabled then return end

		for _, target in ipairs(Players:GetPlayers()) do
			if target == player then continue end

			local char = target.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")

			-- Remove se inválido ou morto
			if not char or not hum or not hrp or hum.Health <= 0 then
				removeESP(target)
				continue
			end

			local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)
			if dist > maxDist then
				removeESP(target)
				continue
			end

			if not espObjects[target] then
				createESP(target)
			end

			local obj = espObjects[target]
			if not obj then continue end

			-- Atualiza cor do highlight
			obj.hl.FillColor = espColor
			obj.bgStroke.Color = espColor

			-- Reancora se personagem mudou (respawn)
			if obj.hl.Adornee ~= char then obj.hl.Adornee = char end
			if obj.bb.Adornee ~= hrp then obj.bb.Adornee = hrp end

			-- Nome
			obj.nameLbl.Visible = showName
			obj.nameLbl.Text = target.DisplayName

			-- HP bar
			local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
			obj.hpBarBg.Visible = showHealth
			obj.hpBarFill.Size = UDim2.new(hpPct, 0, 1, 0)
			obj.hpBarFill.BackgroundColor3 = healthColor(hum.Health, hum.MaxHealth)

			-- Info label (hp numérico)
			if showHealth then
				obj.infoLbl.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth) .. " hp"
			else
				obj.infoLbl.Text = ""
			end
			obj.infoLbl.Visible = showHealth

			-- Distância
			obj.distLbl.Visible = showDist
			obj.distLbl.Text = dist .. "m"

			-- Box: visibilidade do billboard
			obj.bb.Enabled = showBox
		end
	end)

	Players.PlayerRemoving:Connect(removeESP)

	-- Ao morrer e respawnar, recria o ESP
	Players.PlayerAdded:Connect(function(target)
		target.CharacterAdded:Connect(function()
			task.wait(1)
			removeESP(target)
			if espEnabled then createESP(target) end
		end)
	end)
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= player then
			target.CharacterAdded:Connect(function()
				task.wait(1)
				removeESP(target)
				if espEnabled then createESP(target) end
			end)
		end
	end

	-- UI toggles
	sec:Toggle("player esp", false, function(v)
		espEnabled = v
		if not v then clearAllESP() end
	end)

	sec:Toggle("show name", true, function(v) showName = v end)
	sec:Toggle("show health bar", true, function(v) showHealth = v end)
	sec:Toggle("show distance", true, function(v) showDist = v end)

	sec:Slider("max distance", 50, 1000, 500, function(v)
		maxDist = v
	end)
end

-- ===== MINIMIZE / ÍCONE TOGGLE =====
local minimized = false

local function setMinimized(state)
	minimized = state
	Main.Visible = not state
	tween(IconBtn, {
		BackgroundColor3 = state and Color3.fromRGB(40, 34, 60) or Theme.Panel2
	}, 0.15)
end

MinBtn.MouseButton1Click:Connect(function() setMinimized(true) end)
IconBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		setMinimized(not minimized)
	end
end)
