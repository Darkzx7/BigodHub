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
	TweenService:Create(obj, TweenInfo.new(t, style, dir), props):Play()
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
			dragging  = true
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

local Theme = {
	Panel  = Color3.fromRGB(18, 18, 22),
	Panel2 = Color3.fromRGB(22, 22, 27),
	Stroke = Color3.fromRGB(255, 255, 255),
	Text   = Color3.fromRGB(235, 235, 240),
	Sub    = Color3.fromRGB(170, 170, 180),
	Accent = Color3.fromRGB(120, 80, 255),
	Line   = Color3.fromRGB(60, 60, 72),
}

-- ===== CONFIG REGISTRY (definido cedo para poder ser usado em qualquer aba) =====
local ConfigRegistry = {}
local function cfgRegister(key, get, set)
	table.insert(ConfigRegistry, {key=key, get=get, set=set})
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ref_ui"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = pg

-- ===== ÍCONE (sempre visível) =====
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

-- ===== MAIN FRAME =====
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 540, 0, 380)
Main.Position = UDim2.new(0.5, -270, 0.5, -190)
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

-- ===== PAINEL DO USUÁRIO =====
local UserPanel = Instance.new("Frame")
UserPanel.Name = "UserPanel"
UserPanel.Size = UDim2.new(0, 160, 0, 56)
UserPanel.Position = UDim2.new(0, 0, 1, -56)
UserPanel.BackgroundColor3 = Theme.Panel
UserPanel.ZIndex = 3
UserPanel.ClipsDescendants = true
UserPanel.BorderSizePixel = 0
UserPanel.Parent = Main

local UserTopLine = Instance.new("Frame")
UserTopLine.Size = UDim2.new(1, 0, 0, 1)
UserTopLine.BackgroundColor3 = Theme.Line
UserTopLine.BackgroundTransparency = 0.4
UserTopLine.BorderSizePixel = 0
UserTopLine.ZIndex = 4
UserTopLine.Parent = UserPanel

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Name = "Avatar"
AvatarImg.Size = UDim2.new(0, 36, 0, 36)
AvatarImg.Position = UDim2.new(0, 10, 0.5, -18)
AvatarImg.BackgroundColor3 = Theme.Panel
AvatarImg.ZIndex = 4
AvatarImg.Parent = UserPanel
addCorner(AvatarImg, 999)
addStroke(AvatarImg, 1.5, 0.50, Theme.Accent)

task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size48x48
		)
	end)
	if ok then AvatarImg.Image = img end
end)

local UserDivider = Instance.new("Frame")
UserDivider.Size = UDim2.new(0, 2, 0, 30)
UserDivider.Position = UDim2.new(0, 54, 0.5, -15)
UserDivider.BackgroundColor3 = Theme.Accent
UserDivider.BackgroundTransparency = 0.35
UserDivider.BorderSizePixel = 0
UserDivider.ZIndex = 4
UserDivider.Parent = UserPanel
addCorner(UserDivider, 999)

local UserName = Instance.new("TextLabel")
UserName.BackgroundTransparency = 1
UserName.Size = UDim2.new(1, -68, 0, 18)
UserName.Position = UDim2.new(0, 64, 0, 10)
UserName.Font = Enum.Font.GothamSemibold
UserName.Text = player.DisplayName
UserName.TextSize = 12
UserName.TextColor3 = Theme.Text
UserName.TextXAlignment = Enum.TextXAlignment.Left
UserName.TextTruncate = Enum.TextTruncate.AtEnd
UserName.ZIndex = 4
UserName.Parent = UserPanel

local UserTag = Instance.new("TextLabel")
UserTag.BackgroundTransparency = 1
UserTag.Size = UDim2.new(1, -68, 0, 14)
UserTag.Position = UDim2.new(0, 64, 0, 30)
UserTag.Font = Enum.Font.Gotham
UserTag.Text = "@" .. player.Name
UserTag.TextSize = 10
UserTag.TextColor3 = Theme.Sub
UserTag.TextXAlignment = Enum.TextXAlignment.Left
UserTag.TextTruncate = Enum.TextTruncate.AtEnd
UserTag.ZIndex = 4
UserTag.Parent = UserPanel

-- ===== BODY =====
local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, 0, 1, -48 - 56)
Body.Position = UDim2.new(0, 0, 0, 48)
Body.BackgroundTransparency = 1
Body.Parent = Main

local SidePad = Instance.new("Frame")
SidePad.BackgroundTransparency = 1
SidePad.Size = UDim2.new(0, 160, 1, 0)
SidePad.Parent = Body
addPadding(SidePad, 12)

local TabsList = Instance.new("UIListLayout")
TabsList.Padding = UDim.new(0, 8)
TabsList.SortOrder = Enum.SortOrder.LayoutOrder
TabsList.Parent = SidePad

local ContentPad = Instance.new("Frame")
ContentPad.BackgroundTransparency = 1
ContentPad.Size = UDim2.new(1, -160, 1, 0)
ContentPad.Position = UDim2.new(0, 160, 0, 0)
ContentPad.Parent = Body
addPadding(ContentPad, 12)

local Pages = Instance.new("Folder")
Pages.Parent = ContentPad

local SideDiv = Instance.new("Frame")
SideDiv.Size = UDim2.new(0, 1, 1, -56)
SideDiv.Position = UDim2.new(0, 160, 0, 0)
SideDiv.BackgroundColor3 = Theme.Line
SideDiv.BackgroundTransparency = 0.5
SideDiv.BorderSizePixel = 0
SideDiv.Parent = Body

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

	local setActive
	setActive = function()
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

			local dragging, value = false, default

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

		function secObj:TextInput(labelText, placeholder, callback)
			local Row = Instance.new("Frame")
			Row.Size = UDim2.new(1, 0, 0, 34)
			Row.BackgroundColor3 = Theme.Panel
			Row.Parent = Items
			addCorner(Row, 10)
			addStroke(Row, 1, 0.86, Theme.Stroke)

			local Lbl = Instance.new("TextLabel")
			Lbl.BackgroundTransparency = 1
			Lbl.Size = UDim2.new(0, 80, 1, 0)
			Lbl.Position = UDim2.new(0, 12, 0, 0)
			Lbl.Font = Enum.Font.GothamSemibold
			Lbl.Text = labelText
			Lbl.TextSize = 12
			Lbl.TextColor3 = Theme.Sub
			Lbl.TextXAlignment = Enum.TextXAlignment.Left
			Lbl.Parent = Row

			local Box = Instance.new("TextBox")
			Box.Size = UDim2.new(1, -100, 1, -8)
			Box.Position = UDim2.new(0, 90, 0, 4)
			Box.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
			Box.Font = Enum.Font.Gotham
			Box.TextSize = 12
			Box.TextColor3 = Theme.Text
			Box.PlaceholderText = placeholder or ""
			Box.PlaceholderColor3 = Theme.Sub
			Box.Text = ""
			Box.ClearTextOnFocus = false
			Box.Parent = Row
			addCorner(Box, 6)
			addStroke(Box, 1, 0.80, Theme.Stroke)

			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 6)
			pad.Parent = Box

			Box.Focused:Connect(function()
				tween(Box, {BackgroundColor3 = Color3.fromRGB(34, 34, 48)}, 0.12)
			end)
			Box.FocusLost:Connect(function(enter)
				tween(Box, {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}, 0.12)
				if callback then callback(Box.Text, enter) end
			end)

			return {
				Get = function() return Box.Text end,
				Set = function(v) Box.Text = v end,
			}
		end

		function secObj:Button(labelText, callback)
			local Row = Instance.new("TextButton")
			Row.Size = UDim2.new(1, 0, 0, 34)
			Row.BackgroundColor3 = Theme.Panel
			Row.Text = ""
			Row.AutoButtonColor = false
			Row.Parent = Items
			addCorner(Row, 10)
			addStroke(Row, 1, 0.86, Theme.Stroke)

			local Lbl = Instance.new("TextLabel")
			Lbl.BackgroundTransparency = 1
			Lbl.Size = UDim2.new(1, 0, 1, 0)
			Lbl.Font = Enum.Font.GothamSemibold
			Lbl.Text = labelText
			Lbl.TextSize = 13
			Lbl.TextColor3 = Theme.Text
			Lbl.Parent = Row

			Row.MouseEnter:Connect(function()
				tween(Row, {BackgroundColor3 = Color3.fromRGB(30, 26, 48)}, 0.12)
			end)
			Row.MouseLeave:Connect(function()
				tween(Row, {BackgroundColor3 = Theme.Panel}, 0.12)
			end)
			Row.MouseButton1Click:Connect(function()
				tween(Row, {BackgroundColor3 = Theme.Accent}, 0.08)
				task.delay(0.12, function()
					tween(Row, {BackgroundColor3 = Theme.Panel}, 0.12)
				end)
				if callback then callback() end
			end)
		end

		function secObj:AvatarCard()
			local Card = Instance.new("Frame")
			Card.Size = UDim2.new(1, 0, 0, 64)
			Card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
			Card.Visible = false
			Card.Parent = Items
			addCorner(Card, 10)
			addStroke(Card, 1, 0.82, Theme.Stroke)

			local Av = Instance.new("ImageLabel")
			Av.Size = UDim2.new(0, 44, 0, 44)
			Av.Position = UDim2.new(0, 10, 0.5, -22)
			Av.BackgroundColor3 = Theme.Panel
			Av.Image = ""
			Av.Parent = Card
			addCorner(Av, 999)
			addStroke(Av, 1.5, 0.5, Theme.Accent)

			local AccDiv = Instance.new("Frame")
			AccDiv.Size = UDim2.new(0, 2, 0, 28)
			AccDiv.Position = UDim2.new(0, 62, 0.5, -14)
			AccDiv.BackgroundColor3 = Theme.Accent
			AccDiv.BackgroundTransparency = 0.35
			AccDiv.BorderSizePixel = 0
			AccDiv.Parent = Card
			addCorner(AccDiv, 999)

			local NameLbl = Instance.new("TextLabel")
			NameLbl.BackgroundTransparency = 1
			NameLbl.Size = UDim2.new(1, -76, 0, 18)
			NameLbl.Position = UDim2.new(0, 72, 0, 10)
			NameLbl.Font = Enum.Font.GothamBold
			NameLbl.TextSize = 12
			NameLbl.TextColor3 = Theme.Text
			NameLbl.TextXAlignment = Enum.TextXAlignment.Left
			NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			NameLbl.Text = "—"
			NameLbl.Parent = Card

			local TagLbl = Instance.new("TextLabel")
			TagLbl.BackgroundTransparency = 1
			TagLbl.Size = UDim2.new(1, -76, 0, 13)
			TagLbl.Position = UDim2.new(0, 72, 0, 30)
			TagLbl.Font = Enum.Font.Gotham
			TagLbl.TextSize = 10
			TagLbl.TextColor3 = Theme.Sub
			TagLbl.TextXAlignment = Enum.TextXAlignment.Left
			TagLbl.Text = ""
			TagLbl.Parent = Card

			local HpLbl = Instance.new("TextLabel")
			HpLbl.BackgroundTransparency = 1
			HpLbl.Size = UDim2.new(1, -76, 0, 13)
			HpLbl.Position = UDim2.new(0, 72, 0, 44)
			HpLbl.Font = Enum.Font.Gotham
			HpLbl.TextSize = 10
			HpLbl.TextColor3 = Theme.Accent
			HpLbl.TextXAlignment = Enum.TextXAlignment.Left
			HpLbl.Text = ""
			HpLbl.Parent = Card

			return {
				Frame = Card,
				Set = function(target)
					if not target then
						Card.Visible = false
						return
					end
					Card.Visible = true
					NameLbl.Text = target.DisplayName
					TagLbl.Text = "@" .. target.Name
					local char = target.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					HpLbl.Text = hum and ("hp: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)) or "no character"
					task.spawn(function()
						local ok, img = pcall(function()
							return Players:GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
						end)
						if ok then Av.Image = img end
					end)
				end,
				UpdateHp = function(target)
					if not target or not target.Character then return end
					local hum = target.Character:FindFirstChildOfClass("Humanoid")
					if hum then HpLbl.Text = "hp: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth) end
				end,
			}
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
local target_tab = Library:CreateTab("target")
local config_tab = Library:CreateTab("config")
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
	sec:Toggle("anti-afk", false, function(v) afkEnabled = v end)
	cfgRegister("antiafk", function() return afkEnabled end, function(v) afkEnabled = v end)

	sec:Divider("movement")

	local DEFAULT_SPEED = 16
	local speedEnabled, currentSpeed = false, DEFAULT_SPEED

	local function applySpeed()
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = speedEnabled and currentSpeed or DEFAULT_SPEED end
	end

	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		task.wait()
		hum.WalkSpeed = speedEnabled and currentSpeed or DEFAULT_SPEED
	end)

	sec:Toggle("custom walkspeed", false, function(v)
		speedEnabled = v
		applySpeed()
	end)
	cfgRegister("walkspeed_on", function() return speedEnabled end, function(v) speedEnabled = v applySpeed() end)
	cfgRegister("walkspeed_val", function() return currentSpeed end, function(v) currentSpeed = v applySpeed() end)
	sec:Slider("walk speed", 8, 100, DEFAULT_SPEED, function(v)
		currentSpeed = v
		if speedEnabled then applySpeed() end
	end)

	-- Infinite Jump
	local jumpEnabled = false
	local jumpConn = nil

	local function applyJump()
		if jumpEnabled then
			if jumpConn then jumpConn:Disconnect() end
			jumpConn = UserInputService.JumpRequest:Connect(function()
				local c = player.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			end)
		else
			if jumpConn then
				jumpConn:Disconnect()
				jumpConn = nil
			end
		end
	end

	player.CharacterAdded:Connect(function()
		task.wait()
		applyJump()
	end)

	sec:Toggle("infinite jump", false, function(v)
		jumpEnabled = v
		applyJump()
	end)
	cfgRegister("infjump", function() return jumpEnabled end, function(v) jumpEnabled = v applyJump() end)

	sec:Divider("fly")

	local flyEnabled = false
	local flySpeed   = 50
	local flyBV   = nil
	local flyBG   = nil
	local flyConn = nil

	local ControlModule = nil
	local cmOk = pcall(function()
		ControlModule = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
	end)

	local function getMoveVec()
		if ControlModule and cmOk then
			local ok, v = pcall(function() return ControlModule:GetMoveVector() end)
			if ok then return v end
		end
		local mv = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv - Vector3.new(0,0,1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv + Vector3.new(0,0,1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - Vector3.new(1,0,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + Vector3.new(1,0,0) end
		return mv
	end

	local function stopFly()
		flyEnabled = false
		if flyConn then flyConn:Disconnect() flyConn = nil end
		if flyBV and flyBV.Parent then
			flyBV.MaxForce = Vector3.zero
			flyBV.Velocity = Vector3.zero
		end
		if flyBG and flyBG.Parent then
			flyBG.MaxTorque = Vector3.zero
		end
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.PlatformStand = false end
		end
	end

	local function startFly()
		stopFly()
		flyEnabled = true
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end

		flyBV = hrp:FindFirstChild("VelocityHandler_ref")
		if not flyBV then
			flyBV = Instance.new("BodyVelocity")
			flyBV.Name = "VelocityHandler_ref"
			flyBV.Parent = hrp
		end
		flyBV.MaxForce = Vector3.zero
		flyBV.Velocity = Vector3.zero

		flyBG = hrp:FindFirstChild("GyroHandler_ref")
		if not flyBG then
			flyBG = Instance.new("BodyGyro")
			flyBG.Name = "GyroHandler_ref"
			flyBG.Parent = hrp
		end
		flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		flyBG.P   = 1000
		flyBG.D   = 50
		flyBG.CFrame = hrp.CFrame

		hum.PlatformStand = true

		flyConn = RunService.RenderStepped:Connect(function()
			if not flyEnabled then return end
			local c = player.Character
			if not c then return end
			local h  = c:FindFirstChild("HumanoidRootPart")
			local hm = c:FindFirstChildOfClass("Humanoid")
			if not h or not hm then return end

			hm.PlatformStand = true
			flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)

			local camCF   = workspace.CurrentCamera.CFrame
			local lookVec = camCF.LookVector
			local moveVec = getMoveVec()

			local baseCF = CFrame.new(h.Position, h.Position + Vector3.new(lookVec.X, 0, lookVec.Z))
			local poseCF = baseCF
			local velocity = Vector3.zero

			if moveVec.Magnitude > 0.01 then
				if moveVec.Z > 0 then
					poseCF = baseCF * CFrame.Angles(math.rad(-30), 0, 0)
				elseif moveVec.Z < 0 then
					poseCF = baseCF * CFrame.Angles(math.rad(15), 0, 0)
				elseif moveVec.X < 0 then
					poseCF = baseCF * CFrame.Angles(0, 0, math.rad(20))
				elseif moveVec.X > 0 then
					poseCF = baseCF * CFrame.Angles(0, 0, math.rad(-20))
				end
				velocity = camCF.RightVector * (moveVec.X * flySpeed)
					- camCF.LookVector    * (moveVec.Z * flySpeed)
			end

			flyBV.Velocity = velocity
			flyBG.CFrame   = poseCF
		end)
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if flyEnabled then startFly() end
	end)

	sec:Toggle("fly", false, function(v)
		if v then startFly() else stopFly() end
	end)

	sec:Slider("fly speed", 10, 200, 50, function(v)
		flySpeed = v
	end)

	sec:Divider("misc")

	-- Noclip
	local noclipEnabled = false
	RunService.Stepped:Connect(function()
		if not noclipEnabled then return end
		local char = player.Character
		if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
		end
	end)
	sec:Toggle("noclip", false, function(v)
		noclipEnabled = v
		if not v then
			local char = player.Character
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = true end
				end
			end
		end
	end)
	cfgRegister("noclip", function() return noclipEnabled end, function(v) noclipEnabled = v end)

	-- Spinbot
	local spinEnabled = false
	local spinConn    = nil
	local spinSpeed   = 10
	sec:Toggle("spinbot", false, function(v)
		spinEnabled = v
		if v then
			spinConn = RunService.RenderStepped:Connect(function()
				if not spinEnabled then return end
				local char = player.Character
				local hrp  = char and char:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
			end)
		else
			if spinConn then spinConn:Disconnect() spinConn = nil end
		end
	end)
	sec:Slider("spin speed", 1, 30, 10, function(v) spinSpeed = v end)
end

-- ===== COMBAT =====
do
	local sec = combat:Section("main")
	sec:Divider("controls")
	sec:Toggle("aim assist", false, function(v) print("aim assist:", v) end)

	sec:Divider("hitbox")

	local hitboxEnabled  = false
	local hitboxSize     = 10
	local visualizeRange = false
	local hitboxParts    = {}
	local originalSizes  = {}

	local function removeVisual(target)
		local p = hitboxParts[target]
		if p and p.Parent then p:Destroy() end
		hitboxParts[target] = nil
	end

	local function clearVisuals()
		for t in pairs(hitboxParts) do removeVisual(t) end
	end

	local function applyHitbox(target, size)
		local char = target.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		if not originalSizes[hrp] then
			originalSizes[hrp] = hrp.Size
		end
		hrp.Size = Vector3.new(size, size, size)

		if visualizeRange then
			if not hitboxParts[target] then
				local vis = Instance.new("Part")
				vis.Name = "ref_hitbox_vis"
				vis.Anchored = false
				vis.CanCollide = false
				vis.Massless = true
				vis.Shape = Enum.PartType.Ball
				vis.Material = Enum.Material.ForceField
				vis.Color = Color3.fromRGB(120, 80, 255)
				vis.Transparency = 0.55
				vis.CastShadow = false
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = hrp
				weld.Part1 = vis
				weld.Parent = vis
				vis.CFrame = hrp.CFrame
				vis.Parent = char
				hitboxParts[target] = vis
			end
			hitboxParts[target].Size = Vector3.new(size, size, size)
		else
			removeVisual(target)
		end
	end

	local function revertHitbox(target)
		local char = target.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and originalSizes[hrp] then
			hrp.Size = originalSizes[hrp]
			originalSizes[hrp] = nil
		end
		removeVisual(target)
	end

	local function revertAll()
		for _, t in ipairs(Players:GetPlayers()) do
			if t ~= player then revertHitbox(t) end
		end
		clearVisuals()
	end

	local function refreshAll()
		for _, t in ipairs(Players:GetPlayers()) do
			if t ~= player then
				if hitboxEnabled then
					applyHitbox(t, hitboxSize)
				else
					revertHitbox(t)
				end
			end
		end
	end

	Players.PlayerAdded:Connect(function(t)
		t.CharacterAdded:Connect(function()
			task.wait(1)
			if hitboxEnabled then applyHitbox(t, hitboxSize) end
		end)
	end)
	for _, t in ipairs(Players:GetPlayers()) do
		if t ~= player then
			t.CharacterAdded:Connect(function()
				task.wait(1)
				if hitboxEnabled then applyHitbox(t, hitboxSize) end
			end)
		end
	end
	Players.PlayerRemoving:Connect(function(t)
		originalSizes[t] = nil
		removeVisual(t)
	end)

	sec:Toggle("hitbox expander", false, function(v)
		hitboxEnabled = v
		if v then refreshAll() else revertAll() end
	end)
	cfgRegister("hitbox_on", function() return hitboxEnabled end, function(v) hitboxEnabled = v if v then refreshAll() else revertAll() end end)
	cfgRegister("hitbox_size", function() return hitboxSize end, function(v) hitboxSize = v if hitboxEnabled then refreshAll() end end)

	sec:Slider("hitbox size", 4, 60, 10, function(v)
		hitboxSize = v
		if hitboxEnabled then refreshAll() end
	end)

	sec:Toggle("visualize range", false, function(v)
		visualizeRange = v
		if hitboxEnabled then refreshAll() end
	end)

	sec:Divider("lock-on")

	local lockEnabled    = false
	local lockConn       = nil
	local lockToggleRef  = nil
	local lockSilentStop = false

	local function getLockTarget()
		return _G.ref_lockTarget
	end

	local function stopLock()
		if lockSilentStop then return end
		lockEnabled = false
		if lockConn then lockConn:Disconnect() lockConn = nil end
		local cam = workspace.CurrentCamera
		if cam then cam.CameraType = Enum.CameraType.Custom end
		if lockToggleRef then
			lockSilentStop = true
			lockToggleRef.Set(false)
			lockSilentStop = false
		end
	end

	local function startLock()
		lockEnabled = true
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom

		lockConn = RunService.RenderStepped:Connect(function()
			if not lockEnabled then return end
			local t = getLockTarget()
			if not t or not t.Character then return end
			local thrp = t.Character:FindFirstChild("HumanoidRootPart")
			if not thrp then return end

			local camPos    = cam.CFrame.Position
			local targetPos = thrp.Position + Vector3.new(0, 1.5, 0)
			if (camPos - targetPos).Magnitude < 0.5 then return end

			cam.CFrame = cam.CFrame:Lerp(CFrame.new(camPos, targetPos), 0.35)
		end)
	end

	lockToggleRef = sec:Toggle("lock-on (target tab)", false, function(v)
		if lockSilentStop then return end
		if v then
			if not getLockTarget() then
				lockSilentStop = true
				lockToggleRef.Set(false)
				lockSilentStop = false
				return
			end
			startLock()
		else
			lockEnabled = false
			if lockConn then lockConn:Disconnect() lockConn = nil end
			local cam = workspace.CurrentCamera
			if cam then cam.CameraType = Enum.CameraType.Custom end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.Q and lockEnabled then
			stopLock()
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		if p == getLockTarget() and lockEnabled then stopLock() end
	end)
end

-- ===== TARGET =====
do
	local targetPlayer = nil

	local searchSec = target_tab:Section("search")
	local card = searchSec:AvatarCard()

	local function findPlayer(name)
		if not name or name == "" then return nil end
		name = name:lower()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				if p.Name:lower():find(name, 1, true)
					or p.DisplayName:lower():find(name, 1, true) then
					return p
				end
			end
		end
		return nil
	end

	local function setTarget(t)
		targetPlayer = t
		_G.ref_lockTarget = t
		card.Set(t)
	end

	local nickInput = searchSec:TextInput("nick", "username ou displayname", function(text, enter)
		if enter then setTarget(findPlayer(text)) end
	end)

	searchSec:Button("search", function()
		setTarget(findPlayer(nickInput.Get()))
	end)

	RunService.Heartbeat:Connect(function()
		if targetPlayer then card.UpdateHp(targetPlayer) end
	end)

	Players.PlayerRemoving:Connect(function(p)
		if p == targetPlayer then setTarget(nil) end
	end)

	local actionSec = target_tab:Section("actions")
	actionSec:Divider("teleport")

	actionSec:Button("teleport to target", function()
		if not targetPlayer then return end
		local hrp  = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local thrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and thrp then
			hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, -3)
		end
	end)

	actionSec:Button("bring target to me", function()
		if not targetPlayer then return end
		local hrp  = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local thrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and thrp then
			thrp.CFrame = hrp.CFrame * CFrame.new(3, 0, 0)
		end
	end)

	actionSec:Divider("movement")

	actionSec:Button("look at target", function()
		if not targetPlayer then return end
		local hrp  = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local thrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and thrp then
			hrp.CFrame = CFrame.new(hrp.Position, thrp.Position)
		end
	end)

	local followEnabled   = false
	local followBodyVel   = nil
	local followBodyGyro  = nil
	local followConn      = nil
	local FOLLOW_SPEED    = 80
	local FOLLOW_STOP_DST = 3

	local function stopFollow()
		followEnabled = false
		if followConn then followConn:Disconnect() followConn = nil end
		if followBodyVel  and followBodyVel.Parent  then followBodyVel:Destroy()  end
		if followBodyGyro and followBodyGyro.Parent then followBodyGyro:Destroy() end
		followBodyVel  = nil
		followBodyGyro = nil
		local char = player.Character
		if char then
			local hm = char:FindFirstChildOfClass("Humanoid")
			if hm then hm.PlatformStand = false end
		end
	end

	local function startFollow()
		stopFollow()
		followEnabled = true
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end

		if targetPlayer and targetPlayer.Character then
			local thrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if thrp then
				hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, FOLLOW_STOP_DST + 0.5)
			end
		end

		hum.PlatformStand = true

		followBodyVel = Instance.new("BodyVelocity")
		followBodyVel.Velocity  = Vector3.zero
		followBodyVel.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
		followBodyVel.P         = 5e4
		followBodyVel.Parent    = hrp

		followBodyGyro = Instance.new("BodyGyro")
		followBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
		followBodyGyro.P         = 2e4
		followBodyGyro.D         = 500
		followBodyGyro.CFrame    = hrp.CFrame
		followBodyGyro.Parent    = hrp

		followConn = RunService.RenderStepped:Connect(function()
			if not followEnabled then return end
			local c = player.Character
			if not c then return end
			local h = c:FindFirstChild("HumanoidRootPart")
			local hm = c:FindFirstChildOfClass("Humanoid")
			if not h or not hm then return end

			if not targetPlayer or not targetPlayer.Character then
				followBodyVel.Velocity = Vector3.zero
				return
			end

			local thrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not thrp then
				followBodyVel.Velocity = Vector3.zero
				return
			end

			hm.PlatformStand = true

			local diff = thrp.Position - h.Position
			local dist = diff.Magnitude

			if dist <= FOLLOW_STOP_DST then
				followBodyVel.Velocity = Vector3.zero
			else
				followBodyVel.Velocity = diff.Unit * FOLLOW_SPEED
				local look = Vector3.new(diff.X, 0, diff.Z)
				if look.Magnitude > 0.01 then
					followBodyGyro.CFrame = CFrame.new(Vector3.zero, look)
				end
			end
		end)
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if followEnabled then startFollow() end
	end)

	actionSec:Toggle("follow target", false, function(v)
		if v then startFollow() else stopFollow() end
	end)

	local extraSec = target_tab:Section("extras")
	extraSec:Divider("spectate / orbit")

	local spectateConn   = nil
	local spectateActive = false
	local spectateDist   = 12
	local function stopSpectate()
		spectateActive = false
		if spectateConn then spectateConn:Disconnect() spectateConn = nil end
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end
	extraSec:Toggle("spectate target", false, function(v)
		if not v then stopSpectate() return end
		if not targetPlayer then return end
		spectateActive = true
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		spectateConn = RunService.RenderStepped:Connect(function()
			if not spectateActive then return end
			local t = targetPlayer
			if not t or not t.Character then return end
			local thrp = t.Character:FindFirstChild("HumanoidRootPart")
			if not thrp then return end
			local lookDir = Vector3.new(thrp.CFrame.LookVector.X, 0, thrp.CFrame.LookVector.Z).Unit
			local camPos  = thrp.Position - lookDir * spectateDist + Vector3.new(0, 4, 0)
			local targetPos = thrp.Position + Vector3.new(0, 1.5, 0)
			workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(
				CFrame.new(camPos, targetPos), 0.15
			)
		end)
	end)

	local orbitConn   = nil
	local orbitActive = false
	local orbitAngle  = 0
	local orbitRadius = 8
	local function stopOrbit()
		orbitActive = false
		if orbitConn then orbitConn:Disconnect() orbitConn = nil end
		local char = player.Character
		if char then
			local hm = char:FindFirstChildOfClass("Humanoid")
			if hm then hm.PlatformStand = false end
		end
	end
	extraSec:Toggle("orbit target", false, function(v)
		if not v then stopOrbit() return end
		if not targetPlayer then return end
		orbitActive = true
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = true end
		orbitConn = RunService.RenderStepped:Connect(function()
			if not orbitActive then return end
			local c = player.Character
			if not c then return end
			local hrp = c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local t = targetPlayer
			if not t or not t.Character then return end
			local thrp = t.Character:FindFirstChild("HumanoidRootPart")
			if not thrp then return end
			local hm = c:FindFirstChildOfClass("Humanoid")
			if hm then hm.PlatformStand = true end
			orbitAngle = orbitAngle + 0.03
			local center = thrp.Position + Vector3.new(0, 1, 0)
			local x = center.X + orbitRadius * math.cos(orbitAngle)
			local z = center.Z + orbitRadius * math.sin(orbitAngle)
			hrp.CFrame = CFrame.new(Vector3.new(x, center.Y, z), center)
		end)
	end)
	extraSec:Slider("orbit radius", 3, 25, 8, function(v) orbitRadius = v end)

	extraSec:Divider("loop tp")
	local loopTpActive = false
	local loopTpConn   = nil
	local function stopLoopTp()
		loopTpActive = false
		if loopTpConn then loopTpConn:Disconnect() loopTpConn = nil end
	end
	extraSec:Toggle("loop teleport", false, function(v)
		if not v then stopLoopTp() return end
		if not targetPlayer then return end
		loopTpActive = true
		loopTpConn = RunService.Heartbeat:Connect(function()
			if not loopTpActive then return end
			local c = player.Character
			if not c then return end
			local hrp = c:FindFirstChild("HumanoidRootPart")
			local t = targetPlayer
			if not t or not t.Character then return end
			local thrp = t.Character:FindFirstChild("HumanoidRootPart")
			if hrp and thrp then
				hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, -2)
			end
		end)
	end)
end

-- ===== VISUAL: ESP =====
do
	local sec = visual:Section("esp")
	sec:Divider("players")

	local espEnabled = false
	local showName   = true
	local showDist   = true
	local showHealth = true
	local maxDist    = 500
	local espColor   = Color3.fromRGB(120, 80, 255)

	local camera  = workspace.CurrentCamera
	local espData = {}

	local function hpColor(hp, maxHp)
		local pct = math.clamp(hp / math.max(maxHp, 1), 0, 1)
		if pct > 0.6 then
			return Color3.fromRGB(80, 220, 80)
		elseif pct > 0.3 then
			return Color3.fromRGB(240, 200, 40)
		else
			return Color3.fromRGB(220, 60, 60)
		end
	end

	local function removeESP(target)
		local d = espData[target]
		if not d then return end
		if d.highlight and d.highlight.Parent then d.highlight:Destroy() end
		if d.billboard and d.billboard.Parent then d.billboard:Destroy() end
		espData[target] = nil
	end

	local function clearAll()
		for t in pairs(espData) do removeESP(t) end
	end

	local function createESP(target)
		if espData[target] then return end
		local char = target.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local hl = Instance.new("Highlight")
		hl.Name = "ref_esp_hl"
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillColor = espColor
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.45
		hl.OutlineTransparency = 0.0
		hl.Adornee = char
		hl.Parent = char

		local bb = Instance.new("BillboardGui")
		bb.Name = "ref_esp_bb"
		bb.Size = UDim2.new(0, 140, 0, 60)
		bb.StudsOffset = Vector3.new(0, 3.2, 0)
		bb.AlwaysOnTop = true
		bb.ResetOnSpawn = false
		bb.Adornee = hrp
		bb.Parent = hrp

		local nameLbl = Instance.new("TextLabel")
		nameLbl.BackgroundTransparency = 1
		nameLbl.Size = UDim2.new(1, 0, 0, 20)
		nameLbl.Position = UDim2.new(0, 0, 0, 0)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 14
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextStrokeTransparency = 0.2
		nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Center
		nameLbl.Text = target.DisplayName
		nameLbl.Parent = bb

		local hpBg = Instance.new("Frame")
		hpBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		hpBg.BackgroundTransparency = 0.3
		hpBg.Size = UDim2.new(1, 0, 0, 4)
		hpBg.Position = UDim2.new(0, 0, 0, 24)
		hpBg.Parent = bb
		addCorner(hpBg, 999)

		local hpFill = Instance.new("Frame")
		hpFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
		hpFill.Size = UDim2.new(1, 0, 1, 0)
		hpFill.Parent = hpBg
		addCorner(hpFill, 999)

		local distLbl = Instance.new("TextLabel")
		distLbl.BackgroundTransparency = 1
		distLbl.Size = UDim2.new(1, 0, 0, 14)
		distLbl.Position = UDim2.new(0, 0, 0, 34)
		distLbl.Font = Enum.Font.Gotham
		distLbl.TextSize = 11
		distLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
		distLbl.TextStrokeTransparency = 0.3
		distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		distLbl.TextXAlignment = Enum.TextXAlignment.Center
		distLbl.Text = ""
		distLbl.Parent = bb

		espData[target] = {
			highlight = hl,
			billboard = bb,
			nameLbl   = nameLbl,
			hpBg      = hpBg,
			hpFill    = hpFill,
			distLbl   = distLbl,
		}
	end

	RunService.RenderStepped:Connect(function()
		if not espEnabled then return end

		for _, target in ipairs(Players:GetPlayers()) do
			if target == player then continue end

			local char = target.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")

			if not char or not hum or not hrp or hum.Health <= 0 then
				removeESP(target)
				continue
			end

			local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)
			if dist > maxDist then
				removeESP(target)
				continue
			end

			if not espData[target] then createESP(target) end
			local d = espData[target]
			if not d then continue end

			if d.highlight.Adornee ~= char then d.highlight.Adornee = char end
			if d.billboard.Adornee ~= hrp  then d.billboard.Adornee = hrp  end

			d.highlight.FillColor = espColor
			d.nameLbl.Visible = showName
			d.nameLbl.Text = target.DisplayName

			local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
			d.hpBg.Visible   = showHealth
			d.hpFill.Size    = UDim2.new(pct, 0, 1, 0)
			d.hpFill.BackgroundColor3 = hpColor(hum.Health, hum.MaxHealth)

			d.distLbl.Visible = showDist
			d.distLbl.Text    = dist .. "m"
		end
	end)

	Players.PlayerRemoving:Connect(removeESP)

	local function watchCharacter(target)
		target.CharacterAdded:Connect(function()
			removeESP(target)
			task.wait(1)
			if espEnabled then createESP(target) end
		end)
	end
	for _, t in ipairs(Players:GetPlayers()) do
		if t ~= player then watchCharacter(t) end
	end
	Players.PlayerAdded:Connect(watchCharacter)

	sec:Toggle("player esp", false, function(v)
		espEnabled = v
		if not v then clearAll() end
	end)
	cfgRegister("esp_on", function() return espEnabled end, function(v) espEnabled = v if not v then clearAll() end end)
	sec:Toggle("show name", true, function(v) showName = v end)
	sec:Toggle("show health", true, function(v) showHealth = v end)
	sec:Toggle("show distance", true, function(v) showDist = v end)
	sec:Slider("max distance", 50, 1000, 500, function(v) maxDist = v end)
end

-- ===== VISUAL: WORLD (fullbright, chams, tracers) =====
do
	local sec2 = visual:Section("world")
	sec2:Divider("fullbright")

	local origAmbient, origOutdoor
	local fbEnabled = false
	-- FIX: fechamento correto do toggle (end) em vez de só `)`
	sec2:Toggle("fullbright", false, function(v)
		fbEnabled = v
		if v then
			origAmbient = game:GetService("Lighting").Ambient
			origOutdoor = game:GetService("Lighting").OutdoorAmbient
			game:GetService("Lighting").Ambient        = Color3.fromRGB(255, 255, 255)
			game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(255, 255, 255)
			game:GetService("Lighting").Brightness     = 2
		else
			game:GetService("Lighting").Ambient        = origAmbient or Color3.fromRGB(70, 70, 70)
			game:GetService("Lighting").OutdoorAmbient = origOutdoor or Color3.fromRGB(70, 70, 70)
			game:GetService("Lighting").Brightness     = 1
		end
	end)
	cfgRegister("fullbright", function() return fbEnabled end, function(v)
		fbEnabled = v
		if v then
			game:GetService("Lighting").Ambient        = Color3.fromRGB(255, 255, 255)
			game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(255, 255, 255)
			game:GetService("Lighting").Brightness     = 2
		else
			game:GetService("Lighting").Ambient        = Color3.fromRGB(70, 70, 70)
			game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(70, 70, 70)
			game:GetService("Lighting").Brightness     = 1
		end
	end)

	sec2:Divider("chams")

	local chamsEnabled  = false
	local chamsColor    = Color3.fromRGB(255, 60, 60)
	local chamsData     = {}

	local function removeChams(target)
		if chamsData[target] and chamsData[target].Parent then
			chamsData[target]:Destroy()
		end
		chamsData[target] = nil
	end

	local function applyChams(target)
		if chamsData[target] then return end
		local char = target.Character
		if not char then return end
		local hl = Instance.new("Highlight")
		hl.Name               = "ref_chams"
		hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillColor          = chamsColor
		hl.FillTransparency   = 0
		hl.OutlineColor       = Color3.fromRGB(255, 255, 255)
		hl.OutlineTransparency = 0
		hl.Adornee            = char
		hl.Parent             = char
		chamsData[target]     = hl
	end

	local function refreshChams()
		for _, t in ipairs(Players:GetPlayers()) do
			if t ~= player then
				if chamsEnabled then applyChams(t) else removeChams(t) end
			end
		end
	end

	RunService.Heartbeat:Connect(function()
		if not chamsEnabled then return end
		for _, t in ipairs(Players:GetPlayers()) do
			if t ~= player and chamsData[t] then
				chamsData[t].FillColor = chamsColor
				if not chamsData[t].Parent then chamsData[t] = nil end
			end
		end
	end)

	for _, t in ipairs(Players:GetPlayers()) do
		if t ~= player then
			t.CharacterAdded:Connect(function()
				chamsData[t] = nil
				task.wait(0.5)
				if chamsEnabled then applyChams(t) end
			end)
		end
	end
	Players.PlayerAdded:Connect(function(t)
		t.CharacterAdded:Connect(function()
			chamsData[t] = nil
			task.wait(0.5)
			if chamsEnabled then applyChams(t) end
		end)
	end)
	Players.PlayerRemoving:Connect(removeChams)

	sec2:Toggle("chams", false, function(v)
		chamsEnabled = v
		refreshChams()
	end)
	cfgRegister("chams", function() return chamsEnabled end, function(v) chamsEnabled = v refreshChams() end)

	sec2:Divider("tracers")
	local tracersEnabled = false
	local tracerData     = {}
	local tracerGui = Instance.new("ScreenGui")
	tracerGui.Name           = "ref_tracers"
	tracerGui.IgnoreGuiInset = true
	tracerGui.ResetOnSpawn   = false
	tracerGui.Parent         = pg

	local function removeTracer(t)
		if tracerData[t] then
			tracerData[t]:Destroy()
			tracerData[t] = nil
		end
	end

	local function clearTracers()
		for t in pairs(tracerData) do removeTracer(t) end
	end

	RunService.RenderStepped:Connect(function()
		if not tracersEnabled then return end
		local cam = workspace.CurrentCamera
		local vp  = cam.ViewportSize

		for _, t in ipairs(Players:GetPlayers()) do
			if t == player then continue end
			local char = t.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then removeTracer(t) continue end

			local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0,2,0))
			if not onScreen or screenPos.Z < 0 then removeTracer(t) continue end

			if not tracerData[t] then
				local line = Instance.new("Frame")
				line.BackgroundColor3 = Theme.Accent
				line.BorderSizePixel  = 0
				line.AnchorPoint      = Vector2.new(0, 0.5)
				line.ZIndex           = 5
				line.Parent           = tracerGui
				tracerData[t]         = line
			end

			local line = tracerData[t]
			local ox = vp.X / 2
			local oy = vp.Y
			local tx = screenPos.X
			local ty = screenPos.Y
			local dx     = tx - ox
			local dy     = ty - oy
			local length = math.sqrt(dx*dx + dy*dy)
			local angle  = math.deg(math.atan2(dy, dx))

			line.Position = UDim2.new(0, ox, 0, oy)
			line.Size     = UDim2.new(0, length, 0, 2)
			line.Rotation = angle
		end
	end)

	sec2:Toggle("tracers", false, function(v)
		tracersEnabled = v
		if not v then clearTracers() end
	end)

	Players.PlayerRemoving:Connect(function(p)
		removeTracer(p)
	end)
end

-- ===== CONFIG TAB =====
do
	local function serialize(t)
		local parts = {}
		for k, v in pairs(t) do
			local vstr
			if type(v) == "boolean" then vstr = v and "true" or "false"
			elseif type(v) == "number" then vstr = tostring(v)
			elseif type(v) == "string" then vstr = '"' .. v:gsub('"','\\"') .. '"'
			else vstr = "null" end
			table.insert(parts, '"' .. tostring(k) .. '":' .. vstr)
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end

	local function deserialize(s)
		local t = {}
		for k, vstr in s:gmatch('"([^"]+)":([^,}]+)') do
			if vstr == "true" then t[k] = true
			elseif vstr == "false" then t[k] = false
			elseif tonumber(vstr) then t[k] = tonumber(vstr)
			elseif vstr:match('^"(.*)"$') then t[k] = vstr:match('^"(.*)"$')
			end
		end
		return t
	end

	-- ── Persistência real em arquivo no executor ──
	local SAVE_DIR  = "ref_ui"
	local SAVE_FILE = SAVE_DIR .. "/configs.json"
	local MAX_CONFIGS = 5

	-- Garante que a pasta existe
	if not isfolder(SAVE_DIR) then pcall(makefolder, SAVE_DIR) end

	-- Parse simples do JSON de configs salvas
	local function loadFile()
		local ok, content = pcall(readfile, SAVE_FILE)
		if not ok or not content or content == "" then return {} end
		local t = {}
		-- formato interno: { "nome": "jsonstring_escapada", ... }
		for k, v in content:gmatch('"([^"]+)":"(.-)"[,}]') do
			t[k] = v:gsub('\\"', '"')
		end
		return t
	end

	-- Serializa a tabela de configs pra disco
	local function saveFile(t)
		local parts = {}
		for k, v in pairs(t) do
			local escaped = v:gsub('"', '\\"')
			table.insert(parts, '"' .. k .. '":"' .. escaped .. '"')
		end
		pcall(writefile, SAVE_FILE, "{" .. table.concat(parts, ",") .. "}")
	end

	local UserConfigs = loadFile()

	local function notify(text)
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "ref ui", Text = text, Duration = 2,
			})
		end)
	end

	local function getConfigNames()
		local names = {}
		for k in pairs(UserConfigs) do table.insert(names, k) end
		table.sort(names)
		return names
	end

	local function captureState()
		local state = {}
		for _, c in ipairs(ConfigRegistry) do state[c.key] = c.get() end
		return state
	end

	local function applyState(state)
		for _, c in ipairs(ConfigRegistry) do
			if state[c.key] ~= nil then pcall(c.set, state[c.key]) end
		end
	end

	-- ── Section: novo config ──
	local cfgSec = config_tab:Section("config")
	cfgSec:Divider("new")
	local cfgNameInput = cfgSec:TextInput("name", "config name (max 16 chars)", nil)

	cfgSec:Button("save", function()
		local name = cfgNameInput.Get():gsub("%s+", "_"):sub(1, 16)
		if name == "" then notify("type a config name first") return end
		if UserConfigs[name] then notify("name already exists — pick another") return end
		if #getConfigNames() >= MAX_CONFIGS then notify("max 5 configs — delete one first") return end
		UserConfigs[name] = serialize(captureState())
		saveFile(UserConfigs)
		notify("saved: " .. name)
	end)

	-- ── Section: dropdown de slots ──
	local slotSec = config_tab:Section("slots")
	slotSec:Divider("select")

	-- Descobrir o frame Items da section via probe
	local probeDivider2 = slotSec:Divider("")
	local ItemsFrame = probeDivider2.Parent
	probeDivider2:Destroy()

	local selectedName = nil
	local dropOpen     = false
	local itemFrames   = {}

	-- ── Header do dropdown ──
	local HeaderRow = Instance.new("Frame")
	HeaderRow.Name = "DropHeader"
	HeaderRow.Size = UDim2.new(1, 0, 0, 34)
	HeaderRow.BackgroundColor3 = Theme.Panel
	HeaderRow.ClipsDescendants = false   -- CRÍTICO: deixa a lista vazar pra cima
	HeaderRow.ZIndex = 2
	HeaderRow.Parent = ItemsFrame
	addCorner(HeaderRow, 10)
	addStroke(HeaderRow, 1, 0.82, Theme.Stroke)

	-- Texto da seleção atual
	local HeaderLbl = Instance.new("TextLabel")
	HeaderLbl.BackgroundTransparency = 1
	HeaderLbl.Size = UDim2.new(1, -42, 1, 0)
	HeaderLbl.Position = UDim2.new(0, 12, 0, 0)
	HeaderLbl.Font = Enum.Font.GothamSemibold
	HeaderLbl.Text = "select config..."
	HeaderLbl.TextSize = 12
	HeaderLbl.TextColor3 = Theme.Sub
	HeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
	HeaderLbl.TextTruncate = Enum.TextTruncate.AtEnd
	HeaderLbl.ZIndex = 3
	HeaderLbl.Parent = HeaderRow

	-- Seta: triangle feito com UICorner + rotação (sem depender de unicode)
	local ArrowBox = Instance.new("Frame")
	ArrowBox.Size = UDim2.new(0, 30, 0, 30)
	ArrowBox.Position = UDim2.new(1, -32, 0.5, -15)
	ArrowBox.BackgroundTransparency = 1
	ArrowBox.ZIndex = 3
	ArrowBox.Parent = HeaderRow

	-- Triângulo via 3 linhas (Frame rotacionado) — mais simples e confiável no Roblox
	local ArrowImg = Instance.new("ImageLabel")
	ArrowImg.BackgroundTransparency = 1
	ArrowImg.Size = UDim2.new(0, 14, 0, 8)
	ArrowImg.AnchorPoint = Vector2.new(0.5, 0.5)
	ArrowImg.Position = UDim2.new(0.5, 0, 0.5, 0)
	-- Triângulo apontando pra baixo usando Image asset padrão do Roblox
	ArrowImg.Image = "rbxassetid://3926305904"  -- chevron down (Roblox default icons sheet)
	ArrowImg.ImageRectOffset = Vector2.new(964, 764)
	ArrowImg.ImageRectSize = Vector2.new(36, 36)
	ArrowImg.ImageColor3 = Theme.Sub
	ArrowImg.ZIndex = 3
	ArrowImg.Parent = ArrowBox

	-- Botão invisível sobre o header inteiro para capturar clique
	local HeaderBtn = Instance.new("TextButton")
	HeaderBtn.BackgroundTransparency = 1
	HeaderBtn.Size = UDim2.new(1, 0, 1, 0)
	HeaderBtn.Text = ""
	HeaderBtn.ZIndex = 4
	HeaderBtn.Parent = HeaderRow

	-- ── DropList: filho do ScreenGui, flutua por cima de tudo, abre pra BAIXO ──
	local DropList = Instance.new("Frame")
	DropList.Name = "DropList"
	DropList.BackgroundColor3 = Theme.Panel2
	DropList.BorderSizePixel = 0
	DropList.Size = UDim2.new(0, 1, 0, 0)   -- começa colapsado
	DropList.AnchorPoint = Vector2.new(0, 0)  -- ancora no topo (cresce pra baixo)
	DropList.Visible = false
	DropList.ClipsDescendants = true
	DropList.ZIndex = 100
	DropList.Parent = ScreenGui   -- filho do ScreenGui = sempre por cima
	addCorner(DropList, 10)
	addStroke(DropList, 1, 0.70, Theme.Stroke)

	local DropLayout = Instance.new("UIListLayout")
	DropLayout.Padding = UDim.new(0, 2)
	DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
	DropLayout.Parent = DropList

	local DropPadding = Instance.new("UIPadding")
	DropPadding.PaddingTop    = UDim.new(0, 6)
	DropPadding.PaddingBottom = UDim.new(0, 6)
	DropPadding.PaddingLeft   = UDim.new(0, 6)
	DropPadding.PaddingRight  = UDim.new(0, 6)
	DropPadding.Parent = DropList

	-- Posiciona o DropList logo abaixo do HeaderRow na tela
	local function repositionDropList()
		local abs     = HeaderRow.AbsolutePosition
		local absSize = HeaderRow.AbsoluteSize
		-- topo do DropList = borda inferior do header + 4px de gap
		DropList.Position = UDim2.new(0, abs.X, 0, abs.Y + absSize.Y + 4)
		DropList.AnchorPoint = Vector2.new(0, 0)
		DropList.Size = UDim2.new(0, absSize.X, 0, 0)
	end

	local function rebuildItems()
		for _, f in ipairs(itemFrames) do
			if f and f.Parent then f:Destroy() end
		end
		itemFrames = {}

		local names = getConfigNames()

		if #names == 0 then
			local empty = Instance.new("TextLabel")
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, 0, 0, 28)
			empty.Font = Enum.Font.Gotham
			empty.Text = "no configs saved"
			empty.TextSize = 11
			empty.TextColor3 = Theme.Sub
			empty.TextXAlignment = Enum.TextXAlignment.Center
			empty.ZIndex = 101
			empty.Parent = DropList
			table.insert(itemFrames, empty)
			return
		end

		for _, name in ipairs(names) do
			local isSelected = (selectedName == name)

			local Item = Instance.new("Frame")
			Item.Size = UDim2.new(1, 0, 0, 32)
			Item.BackgroundColor3 = isSelected and Color3.fromRGB(32, 26, 52) or Theme.Panel
			Item.ZIndex = 101
			Item.Parent = DropList
			addCorner(Item, 8)
			table.insert(itemFrames, Item)

			-- Barra accent lateral se selecionado
			if isSelected then
				local accent = Instance.new("Frame")
				accent.Size = UDim2.new(0, 2, 0, 18)
				accent.Position = UDim2.new(0, 0, 0.5, -9)
				accent.BackgroundColor3 = Theme.Accent
				accent.BorderSizePixel = 0
				accent.ZIndex = 102
				accent.Parent = Item
				addCorner(accent, 999)
			end

			local NameLbl = Instance.new("TextLabel")
			NameLbl.BackgroundTransparency = 1
			NameLbl.Size = UDim2.new(1, -68, 1, 0)
			NameLbl.Position = UDim2.new(0, 10, 0, 0)
			NameLbl.Font = Enum.Font.GothamSemibold
			NameLbl.Text = name
			NameLbl.TextSize = 12
			NameLbl.TextColor3 = isSelected and Theme.Accent or Theme.Text
			NameLbl.TextXAlignment = Enum.TextXAlignment.Left
			NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			NameLbl.ZIndex = 102
			NameLbl.Parent = Item

			-- Botão LOAD (verde)
			local LoadBtn = Instance.new("TextButton")
			LoadBtn.Size = UDim2.new(0, 26, 0, 22)
			LoadBtn.Position = UDim2.new(1, -58, 0.5, -11)
			LoadBtn.BackgroundColor3 = Color3.fromRGB(28, 52, 36)
			LoadBtn.Text = "load"
			LoadBtn.Font = Enum.Font.GothamSemibold
			LoadBtn.TextSize = 10
			LoadBtn.TextColor3 = Color3.fromRGB(80, 210, 110)
			LoadBtn.AutoButtonColor = false
			LoadBtn.ZIndex = 102
			LoadBtn.Parent = Item
			addCorner(LoadBtn, 5)

			-- Botão DEL (vermelho)
			local DelBtn = Instance.new("TextButton")
			DelBtn.Size = UDim2.new(0, 26, 0, 22)
			DelBtn.Position = UDim2.new(1, -28, 0.5, -11)
			DelBtn.BackgroundColor3 = Color3.fromRGB(52, 24, 24)
			DelBtn.Text = "del"
			DelBtn.Font = Enum.Font.GothamSemibold
			DelBtn.TextSize = 10
			DelBtn.TextColor3 = Color3.fromRGB(210, 70, 70)
			DelBtn.AutoButtonColor = false
			DelBtn.ZIndex = 102
			DelBtn.Parent = Item
			addCorner(DelBtn, 5)

			-- Clique no item = seleciona (área esquerda)
			local ItemClick = Instance.new("TextButton")
			ItemClick.BackgroundTransparency = 1
			ItemClick.Size = UDim2.new(1, -68, 1, 0)
			ItemClick.Text = ""
			ItemClick.ZIndex = 103
			ItemClick.Parent = Item

			local cn = name -- capture

			ItemClick.MouseEnter:Connect(function()
				if not isSelected then tween(Item, {BackgroundColor3 = Color3.fromRGB(26, 26, 38)}, 0.10) end
			end)
			ItemClick.MouseLeave:Connect(function()
				if not isSelected then tween(Item, {BackgroundColor3 = Theme.Panel}, 0.10) end
			end)
			ItemClick.MouseButton1Click:Connect(function()
				selectedName = cn
				HeaderLbl.Text = cn
				HeaderLbl.TextColor3 = Theme.Text
				tween(ArrowImg, {ImageColor3 = Theme.Accent}, 0.12)
				cfgNameInput.Set(cn)
				rebuildItems()
				task.wait()
				local newH = DropLayout.AbsoluteContentSize.Y + 12
				tween(DropList, {Size = UDim2.new(0, HeaderRow.AbsoluteSize.X, 0, newH)}, 0.10)
			end)

			LoadBtn.MouseButton1Click:Connect(function()
				local json = UserConfigs[cn]
				if json then applyState(deserialize(json)) notify("loaded: " .. cn) end
			end)

			DelBtn.MouseButton1Click:Connect(function()
				UserConfigs[cn] = nil
				saveFile(UserConfigs)
				if selectedName == cn then
					selectedName = nil
					HeaderLbl.Text = "select config..."
					HeaderLbl.TextColor3 = Theme.Sub
					tween(ArrowImg, {ImageColor3 = Theme.Sub}, 0.12)
					cfgNameInput.Set("")
				end
				notify("deleted: " .. cn)
				rebuildItems()
				task.wait()
				local newH = DropLayout.AbsoluteContentSize.Y + 12
				if newH < 20 then newH = 36 end
				tween(DropList, {Size = UDim2.new(0, HeaderRow.AbsoluteSize.X, 0, newH)}, 0.10)
			end)
		end
	end

	local function closeDropdown()
		dropOpen = false
		tween(DropList, {Size = UDim2.new(0, DropList.AbsoluteSize.X, 0, 0)}, 0.14)
		tween(ArrowImg, {Rotation = 0}, 0.14)
		task.delay(0.15, function() if not dropOpen then DropList.Visible = false end end)
	end

	local function openDropdown()
		dropOpen = true
		repositionDropList()
		rebuildItems()
		DropList.Visible = true
		DropList.Size = UDim2.new(0, HeaderRow.AbsoluteSize.X, 0, 0)
		task.wait()  -- deixa layout calcular altura
		local h = DropLayout.AbsoluteContentSize.Y + 12
		tween(DropList, {Size = UDim2.new(0, HeaderRow.AbsoluteSize.X, 0, h)}, 0.16)
		tween(ArrowImg, {Rotation = 180}, 0.16)
	end

	HeaderBtn.MouseButton1Click:Connect(function()
		if dropOpen then closeDropdown() else openDropdown() end
	end)

	HeaderRow.MouseEnter:Connect(function()
		tween(HeaderRow, {BackgroundColor3 = Color3.fromRGB(26, 26, 34)}, 0.12)
	end)
	HeaderRow.MouseLeave:Connect(function()
		tween(HeaderRow, {BackgroundColor3 = Theme.Panel}, 0.12)
	end)

	-- Fecha dropdown ao clicar fora
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 and dropOpen then
			task.wait()  -- espera um frame pra ver se foi clique interno
			closeDropdown()
		end
	end)

	-- ── Section: ações rápidas ──
	local actSec = config_tab:Section("actions")
	actSec:Divider("selected")

	actSec:Button("load", function()
		if not selectedName then notify("select a config first") return end
		local json = UserConfigs[selectedName]
		if not json then notify("not found") return end
		applyState(deserialize(json))
		notify("loaded: " .. selectedName)
	end)

	actSec:Button("overwrite", function()
		if not selectedName then notify("select a config first") return end
		UserConfigs[selectedName] = serialize(captureState())
		saveFile(UserConfigs)
		notify("overwritten: " .. selectedName)
	end)

	actSec:Button("delete", function()
		if not selectedName then notify("select a config first") return end
		UserConfigs[selectedName] = nil
		saveFile(UserConfigs)
		notify("deleted: " .. selectedName)
		if dropOpen then
			rebuildItems()
			task.wait()
			local newH = DropLayout.AbsoluteContentSize.Y + 12
			tween(DropList, {Size = UDim2.new(0, HeaderRow.AbsoluteSize.X, 0, newH)}, 0.10)
		end
		selectedName = nil
		HeaderLbl.Text = "select config..."
		HeaderLbl.TextColor3 = Theme.Sub
		tween(ArrowImg, {ImageColor3 = Theme.Sub}, 0.12)
		cfgNameInput.Set("")
	end)
end

-- ===== MINIMIZE =====
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
