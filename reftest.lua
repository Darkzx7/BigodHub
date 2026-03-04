local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("ref_ui")
if old then old:Destroy() end
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
local ConfigRegistry = {}
local function cfgRegister(key, get, set)
	table.insert(ConfigRegistry, {key=key, get=get, set=set})
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ref_ui"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = pg
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
-- FIX 1: título = ícone centralizado, sem texto
local TitleIcon = Instance.new("ImageLabel")
TitleIcon.BackgroundTransparency = 1
TitleIcon.Size = UDim2.new(0, 28, 0, 28)
TitleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
TitleIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
TitleIcon.Image = "rbxassetid://131165537896572"
TitleIcon.ScaleType = Enum.ScaleType.Fit
TitleIcon.ImageTransparency = 0
TitleIcon.Parent = Topbar
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
				Set = function(v)
					if state == v then return end
					state = v
					render()
					if callback then callback(state) end
				end,
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
		-- SplitButton: lista de {text, textColor, callback} lado a lado
		function secObj:SplitButton(btns)
			local Row = Instance.new("Frame")
			Row.Size = UDim2.new(1, 0, 0, 34)
			Row.BackgroundTransparency = 1
			Row.Parent = Items
			local n   = #btns
			local gap = 4
			local handles = {}
			for i, info in ipairs(btns) do
				local bg = Theme.Panel
				local tc = info.textColor or Theme.Text
				local b  = Instance.new("TextButton")
				local xOff = (i - 1) * gap / 2
				local wOff = -gap / 2
				b.Position = UDim2.new((i-1)/n, i > 1 and gap/2 or 0, 0, 0)
				b.Size     = UDim2.new(1/n,     i < n and -gap/2 or (i > 1 and -gap/2 or 0), 1, 0)
				b.BackgroundColor3 = bg
				b.Text     = info.text or ""
				b.Font     = Enum.Font.GothamSemibold
				b.TextSize = 12
				b.TextColor3 = tc
				b.AutoButtonColor = false
				b.Parent   = Row
				addCorner(b, 10)
				addStroke(b, 1, 0.86, Theme.Stroke)
				b.MouseEnter:Connect(function()
					tween(b, {BackgroundColor3 = Color3.fromRGB(30,26,48)}, 0.12)
				end)
				b.MouseLeave:Connect(function()
					tween(b, {BackgroundColor3 = bg}, 0.12)
				end)
				local cb = info.callback
				b.MouseButton1Click:Connect(function()
					tween(b, {BackgroundColor3 = Theme.Accent}, 0.08)
					task.delay(0.12, function() tween(b, {BackgroundColor3 = bg}, 0.12) end)
					if cb then cb(b) end
				end)
				handles[i] = b
			end
			return handles
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
local universal  = Library:CreateTab("universal")
local combat     = Library:CreateTab("combat")
local visual     = Library:CreateTab("visual")
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
		if cam then cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(0.001), 0) end
	end)
	local t_afk = sec:Toggle("anti-afk", false, function(v) afkEnabled = v end)
	cfgRegister("antiafk", function() return afkEnabled end, function(v) t_afk.Set(v) end)

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
	local t_wspd = sec:Toggle("custom walkspeed", false, function(v)
		speedEnabled = v
		applySpeed()
	end)
	cfgRegister("walkspeed_on", function() return speedEnabled end, function(v) t_wspd.Set(v) end)
	local s_wspd = sec:Slider("walk speed", 8, 100, DEFAULT_SPEED, function(v)
		currentSpeed = v
		if speedEnabled then applySpeed() end
	end)
	cfgRegister("walkspeed_val", function() return currentSpeed end, function(v) s_wspd.Set(v) end)

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
			if jumpConn then jumpConn:Disconnect() jumpConn = nil end
		end
	end
	player.CharacterAdded:Connect(function() task.wait() applyJump() end)
	local t_jump = sec:Toggle("infinite jump", false, function(v)
		jumpEnabled = v
		applyJump()
	end)
	cfgRegister("infjump", function() return jumpEnabled end, function(v) t_jump.Set(v) end)

	sec:Divider("fly")
	local flyEnabled = false
	local flySpeed   = 50
	local flyBV, flyBG, flyConn = nil, nil, nil
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
		if flyBV and flyBV.Parent then flyBV.MaxForce = Vector3.zero flyBV.Velocity = Vector3.zero end
		if flyBG and flyBG.Parent then flyBG.MaxTorque = Vector3.zero end
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
		flyBV = hrp:FindFirstChild("VelocityHandler_ref") or Instance.new("BodyVelocity")
		flyBV.Name = "VelocityHandler_ref"
		flyBV.MaxForce = Vector3.zero
		flyBV.Velocity = Vector3.zero
		flyBV.Parent = hrp
		flyBG = hrp:FindFirstChild("GyroHandler_ref") or Instance.new("BodyGyro")
		flyBG.Name = "GyroHandler_ref"
		flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		flyBG.P = 1000
		flyBG.D = 50
		flyBG.CFrame = hrp.CFrame
		flyBG.Parent = hrp
		hum.PlatformStand = true
		flyConn = RunService.RenderStepped:Connect(function()
			if not flyEnabled then return end
			local c = player.Character
			if not c then return end
			local h  = c:FindFirstChild("HumanoidRootPart")
			local hm = c:FindFirstChildOfClass("Humanoid")
			if not h or not hm then return end
			hm.PlatformStand = true
			flyBV.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
			flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			local camCF  = workspace.CurrentCamera.CFrame
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
				velocity = camCF.RightVector * (moveVec.X * flySpeed) - camCF.LookVector * (moveVec.Z * flySpeed)
			end
			flyBV.Velocity = velocity
			flyBG.CFrame   = poseCF
		end)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if flyEnabled then startFly() end
	end)
	local t_fly = sec:Toggle("fly", false, function(v)
		if v then startFly() else stopFly() end
	end)
	cfgRegister("fly_on", function() return flyEnabled end, function(v) t_fly.Set(v) end)
	local s_fly = sec:Slider("fly speed", 10, 200, 50, function(v) flySpeed = v end)
	cfgRegister("fly_speed", function() return flySpeed end, function(v) s_fly.Set(v) end)

	sec:Divider("misc")
	-- Walk on Water
	-- Detecta se o personagem está sobre água (Terrain water ou Part com Material Water)
	-- e ajusta a posição Y para flutuar na superfície
	local wowEnabled  = false
	local wowConn     = nil
	local wowTiles    = {}   -- pool de tiles ativos {part, expireTime}
	local WATER_MAT   = Enum.Material.Water
	local TILE_SIZE   = 4    -- tamanho de cada tile
	local TILE_TTL    = 1.2  -- segundos até sumir após ser criado
	local TILE_FADE   = 0.35 -- segundos da animação de fade ao sumir

	local function getWaterY(pos)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = {}
		local char = player.Character
		if char then table.insert(excludeList, char) end
		for _, t in ipairs(wowTiles) do
			if t.part and t.part.Parent then table.insert(excludeList, t.part) end
		end
		rp.FilterDescendantsInstances = excludeList
		local res = workspace:Raycast(
			Vector3.new(pos.X, pos.Y + 10, pos.Z),
			Vector3.new(0, -80, 0), rp
		)
		if res and res.Material == WATER_MAT then return res.Position.Y end
		return nil
	end

	-- Cria um tile na posição de grid dada (snap ao grid TILE_SIZE)
	local tileIndex = {}  -- chave "x,z" → tile, evita duplicatas
	local function spawnTile(gridX, gridZ, waterY)
		local key = gridX .. "," .. gridZ
		if tileIndex[key] then
			-- Já existe: renova o tempo de vida
			tileIndex[key].expireTime = tick() + TILE_TTL
			return
		end
		local p = Instance.new("Part")
		p.Name         = "ref_wow_tile"
		p.Size         = Vector3.new(TILE_SIZE, 0.2, TILE_SIZE)
		p.Anchored     = true
		p.CanCollide   = true
		p.CanQuery     = false
		p.CastShadow   = false
		p.Transparency = 1
		p.Material     = Enum.Material.SmoothPlastic
		p.CFrame       = CFrame.new(
			gridX * TILE_SIZE + TILE_SIZE/2,
			waterY + 0.1,
			gridZ * TILE_SIZE + TILE_SIZE/2
		)
		p.Parent = workspace
		local entry = {part = p, expireTime = tick() + TILE_TTL, key = key}
		table.insert(wowTiles, entry)
		tileIndex[key] = entry
	end

	local function cleanTiles()
		local now = tick()
		local i = 1
		while i <= #wowTiles do
			local t = wowTiles[i]
			if now >= t.expireTime then
				-- Fade out e destroi
				if t.part and t.part.Parent then
					local p = t.part
					task.delay(TILE_FADE, function()
						if p and p.Parent then p:Destroy() end
					end)
				end
				tileIndex[t.key] = nil
				table.remove(wowTiles, i)
			else
				i = i + 1
			end
		end
	end

	local function clearAllTiles()
		for _, t in ipairs(wowTiles) do
			if t.part and t.part.Parent then t.part:Destroy() end
		end
		wowTiles  = {}
		tileIndex = {}
	end

	local function stopWow()
		wowEnabled = false
		if wowConn then wowConn:Disconnect() wowConn = nil end
		clearAllTiles()
	end

	local function startWow()
		stopWow()
		wowEnabled = true

		wowConn = RunService.Heartbeat:Connect(function()
			if not wowEnabled then return end
			local char = player.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			local pos    = hrp.Position
			local waterY = getWaterY(pos)

			if waterY then
				-- Grid snap: descobre em qual célula o player está
				local gx = math.floor(pos.X / TILE_SIZE)
				local gz = math.floor(pos.Z / TILE_SIZE)

				-- Cria tile na célula atual + predict 1 célula à frente na direção de movimento
				spawnTile(gx, gz, waterY)

				-- Predict: usa a velocidade do HRP pra saber pra onde vai
				local vel = hrp.AssemblyLinearVelocity
				if vel.Magnitude > 1 then
					local flatVel = Vector3.new(vel.X, 0, vel.Z)
					if flatVel.Magnitude > 0.5 then
						local dir    = flatVel.Unit
						-- 1 tile à frente
						local ahead1 = pos + dir * TILE_SIZE
						spawnTile(math.floor(ahead1.X/TILE_SIZE), math.floor(ahead1.Z/TILE_SIZE), waterY)
						-- 2 tiles à frente (pra velocidades altas)
						local ahead2 = pos + dir * TILE_SIZE * 2
						spawnTile(math.floor(ahead2.X/TILE_SIZE), math.floor(ahead2.Z/TILE_SIZE), waterY)
					end
				end
			end

			-- Limpa tiles velhos a cada frame
			cleanTiles()
		end)
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if wowEnabled then startWow() end
	end)
	sec:Toggle("walk on water", false, function(v)
		if v then startWow() else stopWow() end
	end)

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
	local t_noclip = sec:Toggle("noclip", false, function(v)
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
	cfgRegister("noclip", function() return noclipEnabled end, function(v) t_noclip.Set(v) end)

	-- FIX 2: Spinbot — Heartbeat + ângulo acumulado, funciona mesmo movendo
	local spinEnabled = false
	local spinConn    = nil
	local spinSpeed   = 10
	local spinAngle   = 0
	local t_spin = sec:Toggle("spinbot", false, function(v)
		spinEnabled = v
		if not v then
			if spinConn then spinConn:Disconnect() spinConn = nil end
			spinAngle = 0
			return
		end
		if spinConn then spinConn:Disconnect() end
		spinConn = RunService.Heartbeat:Connect(function(dt)
			if not spinEnabled then return end
			local char = player.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			spinAngle = spinAngle + spinSpeed * dt * 60
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
		end)
	end)
	cfgRegister("spinbot", function() return spinEnabled end, function(v) t_spin.Set(v) end)
	local s_spin = sec:Slider("spin speed", 1, 30, 10, function(v) spinSpeed = v end)
	cfgRegister("spin_speed", function() return spinSpeed end, function(v) s_spin.Set(v) end)
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
		if not originalSizes[hrp] then originalSizes[hrp] = hrp.Size end
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
				if hitboxEnabled then applyHitbox(t, hitboxSize) else revertHitbox(t) end
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
	local t_hitbox = sec:Toggle("hitbox expander", false, function(v)
		hitboxEnabled = v
		if v then refreshAll() else revertAll() end
	end)
	cfgRegister("hitbox_on", function() return hitboxEnabled end, function(v) t_hitbox.Set(v) end)
	local s_hitbox = sec:Slider("hitbox size", 4, 60, 10, function(v)
		hitboxSize = v
		if hitboxEnabled then refreshAll() end
	end)
	cfgRegister("hitbox_size", function() return hitboxSize end, function(v) s_hitbox.Set(v) end)
	local t_vis = sec:Toggle("visualize range", false, function(v)
		visualizeRange = v
		if hitboxEnabled then refreshAll() end
	end)
	cfgRegister("hitbox_vis", function() return visualizeRange end, function(v) t_vis.Set(v) end)

	sec:Divider("lock-on")
	local lockEnabled    = false
	local lockConn       = nil
	local lockToggleRef  = nil
	local lockSilentStop = false
	local function getLockTarget() return _G.ref_lockTarget end
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
		if input.KeyCode == Enum.KeyCode.Q and lockEnabled then stopLock() end
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

	-- Search + Click Tool lado a lado via SplitButton da library
	local clickToolActive = false
	local clickToolInst   = nil
	local _splitBtns      = nil

	local function removeClickTool()
		clickToolActive = false
		if clickToolInst and clickToolInst.Parent then clickToolInst:Destroy() end
		clickToolInst = nil
		if _splitBtns and _splitBtns[2] then
			tween(_splitBtns[2], {TextColor3 = Theme.Sub}, 0.12)
		end
	end

	local function equipClickTool()
		removeClickTool()
		clickToolActive = true
		if _splitBtns and _splitBtns[2] then
			tween(_splitBtns[2], {TextColor3 = Theme.Accent}, 0.12)
		end

		local tool = Instance.new("Tool")
		tool.Name            = "Target Selector"
		tool.ToolTip         = "clique num player para selecionar target"
		tool.CanBeDropped    = false
		tool.RequiresHandle  = false
		tool.TextureId       = "rbxassetid://131165537896572"  -- ícone ref ui
		tool.Parent          = player.Backpack
		clickToolInst        = tool

		tool.Activated:Connect(function()
			-- Sempre tenta selecionar, independente de quantas vezes já usou
			local mouse = player:GetMouse()
			local hit   = mouse.Target
			if not hit then return end
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character and hit:IsDescendantOf(p.Character) then
					setTarget(p)
					nickInput.Set(p.Name)
					-- Flash no botão para feedback visual mas mantém ativa
					if _splitBtns and _splitBtns[2] then
						tween(_splitBtns[2], {TextColor3 = Color3.fromRGB(80,255,120)}, 0.1)
						task.delay(0.4, function()
							if clickToolActive then
								tween(_splitBtns[2], {TextColor3 = Theme.Accent}, 0.2)
							end
						end)
					end
					return
				end
			end
		end)

		-- Remove a tool se desquipar manualmente do inventário
		tool.Unequipped:Connect(function()
			-- Pequeno delay para não conflitar com Activated
			task.wait(0.05)
			-- Se a tool ainda existe no backpack, não faz nada (só foi trocada de slot)
			-- Se saiu do backpack/character, remove
			if tool.Parent ~= player.Backpack and tool.Parent ~= player.Character then
				removeClickTool()
			end
		end)

		tool.AncestryChanged:Connect(function()
			if not tool.Parent then
				clickToolActive = false
				clickToolInst   = nil
				if _splitBtns and _splitBtns[2] then
					tween(_splitBtns[2], {TextColor3 = Theme.Sub}, 0.12)
				end
			end
		end)
	end

	_splitBtns = searchSec:SplitButton({
		{text = "search",     color = Theme.Panel, textColor = Theme.Text, callback = function()
			setTarget(findPlayer(nickInput.Get()))
		end},
		{text = "click tool", color = Theme.Panel, textColor = Theme.Sub,  callback = function()
			if clickToolActive then removeClickTool() else equipClickTool() end
		end},
	})
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
		if hrp and thrp then hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, -3) end
	end)
	actionSec:Button("bring target to me", function()
		if not targetPlayer then return end
		local hrp  = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local thrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and thrp then thrp.CFrame = hrp.CFrame * CFrame.new(3, 0, 0) end
	end)
	actionSec:Divider("movement")
	actionSec:Button("look at target", function()
		if not targetPlayer then return end
		local hrp  = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local thrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and thrp then hrp.CFrame = CFrame.new(hrp.Position, thrp.Position) end
	end)

	-- ── FOLLOW TARGET ──────────────────────────────────────────────────
	-- Usa CFrame direto no RenderStepped + PlatformStand
	-- Sem BodyVelocity/BodyGyro depreciados
	local followEnabled   = false
	local followConn      = nil
	local FOLLOW_SPEED    = 80   -- studs/s
	local FOLLOW_STOP_DST = 3    -- para quando chegar aqui

	local function stopFollow()
		followEnabled = false
		if followConn then followConn:Disconnect() followConn = nil end
		local char = player.Character
		if not char then return end
		local hm = char:FindFirstChildOfClass("Humanoid")
		if hm then hm.PlatformStand = false end
	end

	local function startFollow()
		stopFollow()
		if not targetPlayer then return end
		followEnabled = true
		followConn = RunService.RenderStepped:Connect(function(dt)
			if not followEnabled then return end
			local c = player.Character
			if not c then return end
			local hrp = c:FindFirstChild("HumanoidRootPart")
			local hm  = c:FindFirstChildOfClass("Humanoid")
			if not hrp or not hm then return end
			local tc = targetPlayer.Character
			if not tc then return end
			local thrp = tc:FindFirstChild("HumanoidRootPart")
			if not thrp then return end

			hm.PlatformStand = true

			local diff = thrp.Position - hrp.Position
			local dist = diff.Magnitude
			if dist <= FOLLOW_STOP_DST then return end

			-- Move na direção do target com velocidade proporcional (suaviza perto)
			local spd    = math.min(FOLLOW_SPEED, dist * 6) * dt
			local newPos = hrp.Position + diff.Unit * spd
			-- Olha para o target (Y zerado para não inclinar)
			local lookDir = Vector3.new(diff.X, 0, diff.Z)
			if lookDir.Magnitude > 0.01 then
				hrp.CFrame = CFrame.new(newPos, newPos + lookDir)
			else
				hrp.CFrame = CFrame.new(newPos)
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
	actionSec:Slider("follow speed", 30, 200, 80, function(v) FOLLOW_SPEED = v end)

	-- ── HEADSIT ──────────────────────────────────────────────────────
	-- Teletransporta o HRP para cima da cabeça do target a cada frame
	-- + animação sit em loop
	local headsitActive = false
	local headsitConn   = nil
	local headsitAnim   = nil

	local function stopHeadsit()
		headsitActive = false
		if headsitConn then headsitConn:Disconnect() headsitConn = nil end
		if headsitAnim then
			pcall(function()
				headsitAnim:Stop()
				headsitAnim:Destroy()
			end)
			headsitAnim = nil
		end
		local char = player.Character
		if not char then return end
		local hm = char:FindFirstChildOfClass("Humanoid")
		if hm then
			hm.PlatformStand = false
			-- Força o humanoid a voltar ao estado normal de chão
			hm:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end

	local function startHeadsit()
		stopHeadsit()
		if not targetPlayer or not targetPlayer.Character then return end
		local myChar = player.Character
		if not myChar then return end
		local myHRP = myChar:FindFirstChild("HumanoidRootPart")
		local myHum = myChar:FindFirstChildOfClass("Humanoid")
		if not myHRP or not myHum then return end

		headsitActive = true
		myHum.PlatformStand = true

		-- Carrega animação sit (R15 padrão Roblox)
		task.spawn(function()
			local hum = myChar:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			local ok, anim = pcall(function()
				local a = Instance.new("Animation")
				a.AnimationId = "rbxassetid://2506281703"
				return hum:LoadAnimation(a)
			end)
			if ok and anim then
				headsitAnim = anim
				anim.Priority = Enum.AnimationPriority.Action
				anim.Looped   = true
				anim:Play()
			end
		end)

		headsitConn = RunService.RenderStepped:Connect(function()
			if not headsitActive then return end
			local mc = player.Character
			if not mc then return end
			local mh  = mc:FindFirstChild("HumanoidRootPart")
			local mhm = mc:FindFirstChildOfClass("Humanoid")
			if not mh or not mhm then return end

			if not targetPlayer or not targetPlayer.Character then
				stopHeadsit() return
			end
			local tHead = targetPlayer.Character:FindFirstChild("Head")
			if not tHead then stopHeadsit() return end

			mhm.PlatformStand = true

			-- Posição exata no topo da cabeça: usa o CFrame da Head diretamente
			-- offset +2.2 Y (ajustado pra encaixar bem na cabeça na visão dos outros)
			local headCF  = tHead.CFrame
			local seatPos = headCF.Position + Vector3.new(0, 2.2, 0)

			-- Rotação: só yaw do target, sem pitch/roll
			local look     = headCF.LookVector
			local flatLook = Vector3.new(look.X, 0, look.Z)
			local newCF
			if flatLook.Magnitude > 0.01 then
				newCF = CFrame.lookAt(seatPos, seatPos + flatLook)
			else
				newCF = CFrame.new(seatPos)
			end

			-- Sem lerp: posição exata a cada frame (lerp causava delay visível pra outros)
			mh.CFrame = newCF

			-- Mantém animação rodando se parou
			if headsitAnim and not headsitAnim.IsPlaying then
				headsitAnim:Play()
			end
		end)
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if headsitActive then startHeadsit() end
	end)
	actionSec:Toggle("headsit", false, function(v)
		if v then startHeadsit() else stopHeadsit() end
	end)

	-- ── FLING ────────────────────────────────────────────────────────
	local flingSec = target_tab:Section("fling")
	flingSec:Divider("settings")

	local flingPower  = 9e4
	local flingRadius = 30

	flingSec:Slider("power", 1e4, 5e5, 9e4, function(v) flingPower = v end)
	flingSec:Slider("radius (loop all)", 5, 150, 30, function(v) flingRadius = v end)

	flingSec:Divider("actions")

	local flingActive     = false
	local flingLoopActive = false
	local flingLoopConn   = nil

	-- Limpa qualquer lixo de fling anterior do HRP
	local function cleanFlingDebris(hrp)
		for _, n in ipairs({"ref_fling_thrust", "ref_fling_bv", "ref_fling_bg"}) do
			local obj = hrp:FindFirstChild(n)
			if obj then obj:Destroy() end
		end
	end

	local function doFling(target)
		if flingActive then return end
		if not target or not target.Character then return end
		local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
		if not tHRP then return end

		local myChar = player.Character
		if not myChar then return end
		local myHRP = myChar:FindFirstChild("HumanoidRootPart")
		if not myHRP then return end

		flingActive = true
		cleanFlingDebris(myHRP)

		local savedCF = myHRP.CFrame

		-- BodyGyro: trava a rotação do nosso HRP no lugar
		local bg        = Instance.new("BodyGyro")
		bg.Name         = "ref_fling_bg"
		bg.MaxTorque    = Vector3.new(math.huge, math.huge, math.huge)
		bg.CFrame       = savedCF
		bg.P            = math.huge
		bg.D            = 999
		bg.Parent       = myHRP

		-- BodyVelocity: zera a velocidade do nosso char durante o fling
		local bv        = Instance.new("BodyVelocity")
		bv.Name         = "ref_fling_bv"
		bv.MaxForce     = Vector3.new(math.huge, math.huge, math.huge)
		bv.Velocity     = Vector3.zero
		bv.P            = math.huge
		bv.Parent       = myHRP

		-- BodyThrust no nosso HRP: força enorme que colide com o target
		local thrust    = Instance.new("BodyThrust")
		thrust.Name     = "ref_fling_thrust"
		thrust.Force    = Vector3.new(flingPower, flingPower * 0.3, flingPower)
		thrust.Location = Vector3.zero
		thrust.Parent   = myHRP

		-- Teleporta pro target
		myHRP.CFrame = tHRP.CFrame

		-- Após 5 frames: cleanup completo e volta pra posição original
		local frames = 0
		local conn
		conn = RunService.Heartbeat:Connect(function()
			frames += 1
			if frames < 5 then return end
			conn:Disconnect()

			-- Destroi tudo antes de mover
			cleanFlingDebris(myHRP)

			-- Volta pra posição salva e zera tudo
			if myHRP and myHRP.Parent then
				myHRP.CFrame                  = savedCF
				myHRP.AssemblyLinearVelocity  = Vector3.zero
				myHRP.AssemblyAngularVelocity = Vector3.zero
			end

			flingActive = false
		end)
	end

	flingSec:Button("fling target", function()
		if not targetPlayer then return end
		doFling(targetPlayer)
	end)

	-- Loop target
	flingSec:Toggle("fling loop (target)", false, function(v)
		flingLoopActive = v
		if not v then
			if flingLoopConn then flingLoopConn:Disconnect() flingLoopConn = nil end
			return
		end
		if flingLoopConn then flingLoopConn:Disconnect() end
		flingLoopConn = RunService.Heartbeat:Connect(function()
			if not flingLoopActive or not targetPlayer then return end
			if not flingActive then doFling(targetPlayer) end
		end)
	end)

	-- Loop all no raio
	flingSec:Toggle("fling loop (all in radius)", false, function(v)
		flingLoopActive = v
		if not v then
			if flingLoopConn then flingLoopConn:Disconnect() flingLoopConn = nil end
			return
		end
		if flingLoopConn then flingLoopConn:Disconnect() end
		flingLoopConn = RunService.Heartbeat:Connect(function()
			if not flingLoopActive then return end
			if flingActive then return end
			local myChar2 = player.Character
			local myHRP2  = myChar2 and myChar2:FindFirstChild("HumanoidRootPart")
			if not myHRP2 then return end
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
					if pHRP and (pHRP.Position - myHRP2.Position).Magnitude <= flingRadius then
						doFling(p)
						break  -- um por heartbeat
					end
				end
			end
		end)
	end)

	local extraSec = target_tab:Section("extras")
	extraSec:Divider("spectate / orbit")
	local spectateConn   = nil
	local spectateActive = false
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
			local camPos  = thrp.Position - lookDir * 12 + Vector3.new(0, 4, 0)
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
		if pct > 0.6 then return Color3.fromRGB(80, 220, 80)
		elseif pct > 0.3 then return Color3.fromRGB(240, 200, 40)
		else return Color3.fromRGB(220, 60, 60) end
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
			highlight = hl, billboard = bb,
			nameLbl = nameLbl, hpBg = hpBg, hpFill = hpFill, distLbl = distLbl,
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
				removeESP(target) continue
			end
			local dist = math.floor((camera.CFrame.Position - hrp.Position).Magnitude)
			if dist > maxDist then removeESP(target) continue end
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
	local t_esp = sec:Toggle("player esp", false, function(v)
		espEnabled = v
		if not v then clearAll() end
	end)
	cfgRegister("esp_on", function() return espEnabled end, function(v) t_esp.Set(v) end)
	local t_espname = sec:Toggle("show name", true, function(v) showName = v end)
	cfgRegister("esp_name", function() return showName end, function(v) t_espname.Set(v) end)
	local t_esphp = sec:Toggle("show health", true, function(v) showHealth = v end)
	cfgRegister("esp_health", function() return showHealth end, function(v) t_esphp.Set(v) end)
	local t_espdist = sec:Toggle("show distance", true, function(v) showDist = v end)
	cfgRegister("esp_dist", function() return showDist end, function(v) t_espdist.Set(v) end)
	local s_espdist = sec:Slider("max distance", 50, 1000, 500, function(v) maxDist = v end)
	cfgRegister("esp_maxdist", function() return maxDist end, function(v) s_espdist.Set(v) end)
end

-- ===== VISUAL: EXTRAS =====
do
	local sec2 = visual:Section("world")
	sec2:Divider("fullbright")
	local origAmbient, origOutdoor
	local fbEnabled = false
	local t_fb = sec2:Toggle("fullbright", false, function(v)
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
	cfgRegister("fullbright", function() return fbEnabled end, function(v) t_fb.Set(v) end)

	sec2:Divider("chams")
	local chamsEnabled = false
	local chamsColor   = Color3.fromRGB(255, 60, 60)
	local chamsData    = {}
	local function removeChams(target)
		if chamsData[target] and chamsData[target].Parent then chamsData[target]:Destroy() end
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
	local t_chams = sec2:Toggle("chams", false, function(v)
		chamsEnabled = v
		refreshChams()
	end)
	cfgRegister("chams", function() return chamsEnabled end, function(v) t_chams.Set(v) end)

	-- FIX 4: Tracers — WorldToScreenPoint + coordenadas corretas
	sec2:Divider("tracers")
	local tracersEnabled = false
	local tracerData     = {}
	local tracerGui = Instance.new("ScreenGui")
	tracerGui.Name           = "ref_tracers"
	tracerGui.IgnoreGuiInset = true
	tracerGui.ResetOnSpawn   = false
	tracerGui.DisplayOrder   = 999
	tracerGui.Parent         = pg
	local function removeTracer(t)
		if tracerData[t] then tracerData[t]:Destroy() tracerData[t] = nil end
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
			-- WorldToScreenPoint: coordenadas de tela reais, compatíveis com IgnoreGuiInset=true
			local screenPos, onScreen = cam:WorldToScreenPoint(hrp.Position + Vector3.new(0, 1.5, 0))
			if not onScreen or screenPos.Z < 0 then removeTracer(t) continue end
			if not tracerData[t] then
				local line = Instance.new("Frame")
				line.BackgroundColor3 = Theme.Accent
				line.BorderSizePixel  = 0
				line.AnchorPoint      = Vector2.new(0, 0.5)
				line.ZIndex           = 10
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
	local t_tracers = sec2:Toggle("tracers", false, function(v)
		tracersEnabled = v
		if not v then clearTracers() end
	end)
	cfgRegister("tracers", function() return tracersEnabled end, function(v) t_tracers.Set(v) end)
	Players.PlayerRemoving:Connect(function(p) removeTracer(p) end)
end

-- ===== CONFIG =====
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
	local SAVE_DIR  = "ref_ui"
	local SAVE_FILE = SAVE_DIR .. "/configs.json"
	local MAX_CONFIGS = 5

	-- Suporte a filesystem varia por executor; usa _G como fallback
	local fsOk = type(isfolder)   == "function"
		and type(readfile)   == "function"
		and type(writefile)  == "function"
		and type(makefolder) == "function"

	if fsOk and not isfolder(SAVE_DIR) then
		pcall(makefolder, SAVE_DIR)
	end

	local function loadFile()
		if not fsOk then
			-- Fallback: persiste na sessão via _G
			return _G.ref_ui_configs or {}
		end
		local ok, data = pcall(readfile, SAVE_FILE)
		if not ok or not data or data == "" then return {} end
		local t = {}
		for k, v in data:gmatch('"([^"]+)":"(.-)"[,}]') do
			t[k] = v:gsub('\\"', '"')
		end
		return t
	end

	local function saveFile(t)
		if not fsOk then
			-- Fallback: salva na sessão via _G
			_G.ref_ui_configs = t
			return
		end
		local parts = {}
		for k, v in pairs(t) do
			table.insert(parts, '"' .. k .. '":"' .. v:gsub('"', '\\"') .. '"')
		end
		pcall(writefile, SAVE_FILE, "{" .. table.concat(parts, ",") .. "}")
	end

	local UserConfigs = loadFile()
	local function notify(text)
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {Title="ref ui",Text=text,Duration=2})
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
	local cfgSec = config_tab:Section("config")
	cfgSec:Divider("new")
	local cfgNameInput = cfgSec:TextInput("name", "config name (max 16 chars)", nil)
	cfgSec:Button("save", function()
		local name = cfgNameInput.Get():gsub("%s+", "_"):sub(1, 16)
		if name == "" then notify("type a config name first") return end
		if UserConfigs[name] then notify("name already exists") return end
		if #getConfigNames() >= MAX_CONFIGS then notify("max 5 configs — delete one first") return end
		UserConfigs[name] = serialize(captureState())
		saveFile(UserConfigs)
		notify("saved: " .. name)
	end)
	local slotSec = config_tab:Section("slots")
	slotSec:Divider("select")
	local probeDivider2 = slotSec:Divider("")
	local ItemsFrame = probeDivider2.Parent
	probeDivider2:Destroy()
	local selectedName = nil
	local dropOpen     = false
	local itemFrames   = {}
	local dropHeight   = 0
	local HeaderRow = Instance.new("Frame")
	HeaderRow.Name = "DropHeader"
	HeaderRow.Size = UDim2.new(1, 0, 0, 34)
	HeaderRow.BackgroundColor3 = Theme.Panel
	HeaderRow.ClipsDescendants = false
	HeaderRow.ZIndex = 2
	HeaderRow.Parent = ItemsFrame
	addCorner(HeaderRow, 10)
	addStroke(HeaderRow, 1, 0.82, Theme.Stroke)
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
	local ArrowLbl = Instance.new("TextLabel")
	ArrowLbl.BackgroundTransparency = 1
	ArrowLbl.Size = UDim2.new(0, 30, 1, 0)
	ArrowLbl.Position = UDim2.new(1, -32, 0, 0)
	ArrowLbl.Font = Enum.Font.GothamBold
	ArrowLbl.Text = "v"
	ArrowLbl.TextSize = 13
	ArrowLbl.TextColor3 = Theme.Sub
	ArrowLbl.TextXAlignment = Enum.TextXAlignment.Center
	ArrowLbl.ZIndex = 3
	ArrowLbl.Parent = HeaderRow
	local HeaderBtn = Instance.new("TextButton")
	HeaderBtn.BackgroundTransparency = 1
	HeaderBtn.Size = UDim2.new(1, 0, 1, 0)
	HeaderBtn.Text = ""
	HeaderBtn.ZIndex = 4
	HeaderBtn.Parent = HeaderRow
	local DropList = Instance.new("Frame")
	DropList.Name = "ref_DropList"
	DropList.BackgroundColor3 = Theme.Panel2
	DropList.BorderSizePixel = 0
	DropList.Size = UDim2.new(0, 10, 0, 0)
	DropList.AnchorPoint = Vector2.new(0, 0)
	DropList.Visible = false
	DropList.ClipsDescendants = true
	DropList.ZIndex = 100
	DropList.Parent = ScreenGui
	addCorner(DropList, 10)
	addStroke(DropList, 1, 0.70, Theme.Stroke)
	local DropLayout = Instance.new("UIListLayout")
	DropLayout.Padding = UDim.new(0, 2)
	DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
	DropLayout.Parent = DropList
	local DropPadding = Instance.new("UIPadding")
	DropPadding.PaddingTop = UDim.new(0, 6)
	DropPadding.PaddingBottom = UDim.new(0, 6)
	DropPadding.PaddingLeft = UDim.new(0, 6)
	DropPadding.PaddingRight = UDim.new(0, 6)
	DropPadding.Parent = DropList
	local GuiInset = game:GetService("GuiService"):GetGuiInset()
	RunService.RenderStepped:Connect(function()
		if not dropOpen then return end
		local abs = HeaderRow.AbsolutePosition
		local sz  = HeaderRow.AbsoluteSize
		DropList.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + GuiInset.Y + 4)
		DropList.Size = UDim2.new(0, sz.X, 0, dropHeight)
	end)
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
			local isSel = (selectedName == name)
			local Item = Instance.new("Frame")
			Item.Size = UDim2.new(1, 0, 0, 32)
			Item.BackgroundColor3 = isSel and Color3.fromRGB(32, 26, 52) or Theme.Panel
			Item.ZIndex = 101
			Item.Parent = DropList
			addCorner(Item, 8)
			table.insert(itemFrames, Item)
			if isSel then
				local acc = Instance.new("Frame")
				acc.Size = UDim2.new(0, 2, 0, 18)
				acc.Position = UDim2.new(0, 0, 0.5, -9)
				acc.BackgroundColor3 = Theme.Accent
				acc.BorderSizePixel = 0
				acc.ZIndex = 102
				acc.Parent = Item
				addCorner(acc, 999)
			end
			local NameLbl = Instance.new("TextLabel")
			NameLbl.BackgroundTransparency = 1
			NameLbl.Size = UDim2.new(1, -68, 1, 0)
			NameLbl.Position = UDim2.new(0, 10, 0, 0)
			NameLbl.Font = Enum.Font.GothamSemibold
			NameLbl.Text = name
			NameLbl.TextSize = 12
			NameLbl.TextColor3 = isSel and Theme.Accent or Theme.Text
			NameLbl.TextXAlignment = Enum.TextXAlignment.Left
			NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			NameLbl.ZIndex = 102
			NameLbl.Parent = Item
			local LoadBtn = Instance.new("TextButton")
			LoadBtn.Size = UDim2.new(0, 28, 0, 22)
			LoadBtn.Position = UDim2.new(1, -60, 0.5, -11)
			LoadBtn.BackgroundColor3 = Color3.fromRGB(28, 52, 36)
			LoadBtn.Text = "load"
			LoadBtn.Font = Enum.Font.GothamSemibold
			LoadBtn.TextSize = 10
			LoadBtn.TextColor3 = Color3.fromRGB(80, 210, 110)
			LoadBtn.AutoButtonColor = false
			LoadBtn.ZIndex = 102
			LoadBtn.Parent = Item
			addCorner(LoadBtn, 5)
			local DelBtn = Instance.new("TextButton")
			DelBtn.Size = UDim2.new(0, 28, 0, 22)
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
			local ItemClick = Instance.new("TextButton")
			ItemClick.BackgroundTransparency = 1
			ItemClick.Size = UDim2.new(1, -68, 1, 0)
			ItemClick.Text = ""
			ItemClick.ZIndex = 103
			ItemClick.Parent = Item
			local cn = name
			ItemClick.MouseEnter:Connect(function()
				if selectedName ~= cn then tween(Item, {BackgroundColor3 = Color3.fromRGB(26,26,38)}, 0.10) end
			end)
			ItemClick.MouseLeave:Connect(function()
				if selectedName ~= cn then tween(Item, {BackgroundColor3 = Theme.Panel}, 0.10) end
			end)
			ItemClick.MouseButton1Click:Connect(function()
				selectedName = cn
				HeaderLbl.Text = cn
				HeaderLbl.TextColor3 = Theme.Text
				tween(ArrowLbl, {TextColor3 = Theme.Accent}, 0.12)
				cfgNameInput.Set(cn)
				rebuildItems()
				task.wait()
				dropHeight = DropLayout.AbsoluteContentSize.Y + 12
			end)
			LoadBtn.MouseButton1Click:Connect(function()
				local json = UserConfigs[cn]
				if json then applyState(deserialize(json)) notify("loaded: "..cn) end
			end)
			DelBtn.MouseButton1Click:Connect(function()
				UserConfigs[cn] = nil
				saveFile(UserConfigs)
				if selectedName == cn then
					selectedName = nil
					HeaderLbl.Text = "select config..."
					HeaderLbl.TextColor3 = Theme.Sub
					tween(ArrowLbl, {TextColor3 = Theme.Sub}, 0.12)
					cfgNameInput.Set("")
				end
				notify("deleted: "..cn)
				rebuildItems()
				task.wait()
				dropHeight = DropLayout.AbsoluteContentSize.Y + 12
			end)
		end
	end
	local function closeDropdown()
		dropOpen = false
		tween(ArrowLbl, {Rotation = 0}, 0.14)
		local tw = TweenService:Create(DropList, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, HeaderRow.AbsoluteSize.X, 0, 0)})
		tw:Play()
		tw.Completed:Connect(function() DropList.Visible = false end)
		dropHeight = 0
	end
	local function openDropdown()
		rebuildItems()
		task.wait()
		local w = HeaderRow.AbsoluteSize.X
		local h = DropLayout.AbsoluteContentSize.Y + 12
		local abs = HeaderRow.AbsolutePosition
		local sz  = HeaderRow.AbsoluteSize
		DropList.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
		DropList.Size = UDim2.new(0, w, 0, 0)
		DropList.Visible = true
		dropOpen = true
		dropHeight = h
		tween(ArrowLbl, {Rotation = 180}, 0.16)
	end
	HeaderBtn.MouseButton1Click:Connect(function()
		if dropOpen then closeDropdown() else openDropdown() end
	end)
	HeaderRow.MouseEnter:Connect(function() tween(HeaderRow, {BackgroundColor3 = Color3.fromRGB(26,26,34)}, 0.12) end)
	HeaderRow.MouseLeave:Connect(function() tween(HeaderRow, {BackgroundColor3 = Theme.Panel}, 0.12) end)
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 and dropOpen then
			task.wait()
			closeDropdown()
		end
	end)
	local actSec = config_tab:Section("actions")
	actSec:Divider("selected")
	actSec:Button("load", function()
		if not selectedName then notify("select a config first") return end
		local json = UserConfigs[selectedName]
		if not json then notify("not found") return end
		applyState(deserialize(json))
		notify("loaded: "..selectedName)
	end)
	actSec:Button("overwrite", function()
		if not selectedName then notify("select a config first") return end
		UserConfigs[selectedName] = serialize(captureState())
		saveFile(UserConfigs)
		notify("overwritten: "..selectedName)
	end)
	actSec:Button("delete", function()
		if not selectedName then notify("select a config first") return end
		UserConfigs[selectedName] = nil
		saveFile(UserConfigs)
		notify("deleted: "..selectedName)
		selectedName = nil
		HeaderLbl.Text = "select config..."
		HeaderLbl.TextColor3 = Theme.Sub
		tween(ArrowLbl, {TextColor3 = Theme.Sub}, 0.12)
		cfgNameInput.Set("")
		if dropOpen then
			rebuildItems()
			task.wait()
			dropHeight = DropLayout.AbsoluteContentSize.Y + 12
		end
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
