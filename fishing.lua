local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack")
local guiRoot = player:WaitForChild("PlayerGui")

local autoFishing = false
local autoIndicator = false
local minimized = false
local fishingTool = nil

local fishCount, trashCount, diamondCount = 0, 0, 0
local status, toast
local fishIcon, trashIcon, diamondIcon
local elementsToToggle = {}


local function showAnimatedIntro(callback)
	local introGui = Instance.new("ScreenGui", guiRoot)
	introGui.Name = "BigodeIntroV2"
	introGui.IgnoreGuiInset = true

	local frame = Instance.new("Frame", introGui)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1

	local title = Instance.new("TextLabel", frame)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0.4, 0)
	title.Size = UDim2.new(0, 400, 0, 50)
	title.Text = "Bigode Hub"
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = Color3.fromRGB(100, 200, 255)
	title.TextSize = 38
	title.BackgroundTransparency = 1
	title.TextTransparency = 1

	local subtitle = Instance.new("TextLabel", frame)
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.Position = UDim2.new(0.5, 0, 0.47, 0)
	subtitle.Size = UDim2.new(0, 400, 0, 25)
	subtitle.Text = "Use e abuse com moderação"
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitle.TextSize = 16
	subtitle.BackgroundTransparency = 1
	subtitle.TextTransparency = 1

	local barBack = Instance.new("Frame", frame)
	barBack.AnchorPoint = Vector2.new(0.5, 0.5)
	barBack.Position = UDim2.new(0.5, 0, 0.55, 0)
	barBack.Size = UDim2.new(0, 300, 0, 10)
	barBack.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	barBack.BorderSizePixel = 0
	Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 6)

	local barFill = Instance.new("Frame", barBack)
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	barFill.BorderSizePixel = 0
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 6)

	TweenService:Create(title, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
	task.wait(0.4)
	TweenService:Create(subtitle, TweenInfo.new(0.8), {TextTransparency = 0}):Play()

	spawn(function()
		for i = 1, 100 do
			barFill:TweenSize(UDim2.new(i / 100, 0, 1, 0), "Out", "Quad", 0.02, true)
			wait(0.02)
		end
		wait(0.5)
		TweenService:Create(title, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(subtitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TweenService:Create(barBack, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		TweenService:Create(barFill, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		wait(0.5)
		introGui:Destroy()
		if callback then callback() end
	end)
end


local function equipRod()
	local tool = character:FindFirstChild("Fishing Rod") or backpack:FindFirstChild("Fishing Rod")
	if tool then
		tool.Parent = character
		task.wait(0.3)
		return tool
	end
	return nil
end

local function launchLine()
	fishingTool = equipRod()
	if fishingTool and fishingTool:IsDescendantOf(character) then
		fishingTool:Activate()
		status.Text = "Status: Linha lançada!"
	end
end

local function startAutoFishing()
	autoFishing = true
	status.Text = "Status: Automático"
	spawn(function()
		while autoFishing do
			launchLine()
			wait(61.1)
		end
	end)
end

local function stopAutoFishing()
	autoFishing = false
	status.Text = "Status: Inativo"
end


local function toggleMinimize(frame, minimizeBtn)
	minimized = not minimized
	for _, ui in ipairs(elementsToToggle) do
		ui.Visible = not minimized
	end
	frame.Size = minimized and UDim2.new(0, 50, 0, 50) or UDim2.new(0, 270, 0, 240)
	minimizeBtn.Text = minimized and "+" or "-"
end

local function updateLootVisual()
	fishIcon.Text = "🐟 " .. fishCount
	trashIcon.Text = "🗑️ " .. trashCount
	diamondIcon.Text = "💎 " .. diamondCount
end

local function createGUI()
	local gui = Instance.new("ScreenGui", guiRoot)
	gui.Name = "FishingHUD"

	local frame = Instance.new("Frame", gui)
	frame.Position = UDim2.new(1, -290, 0.3, 0)
	frame.Size = UDim2.new(0, 270, 0, 240)
	frame.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Text = "Bigode X.  (v1.2)"
	title.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	Instance.new("UICorner", title)
	table.insert(elementsToToggle, title)

	local minimize = Instance.new("TextButton", frame)
	minimize.Size = UDim2.new(0, 26, 0, 26)
	minimize.Position = UDim2.new(1, -30, 0, 2)
	minimize.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	minimize.Text = "-"
	minimize.TextColor3 = Color3.new(1, 1, 1)
	minimize.Font = Enum.Font.GothamBold
	minimize.TextSize = 16
	Instance.new("UICorner", minimize).CornerRadius = UDim.new(1, 0)
	minimize.MouseButton1Click:Connect(function()
		toggleMinimize(frame, minimize)
	end)

	status = Instance.new("TextLabel", frame)
	status.Position = UDim2.new(0, 10, 0, 40)
	status.Size = UDim2.new(1, -20, 0, 20)
	status.BackgroundTransparency = 1
	status.Text = "Status: Inativo"
	status.TextColor3 = Color3.fromRGB(200, 220, 255)
	status.Font = Enum.Font.Gotham
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(elementsToToggle, status)

	local lootBox = Instance.new("Frame", frame)
	lootBox.Position = UDim2.new(0.05, 0, 0, 70)
	lootBox.Size = UDim2.new(0.9, 0, 0, 36)
	lootBox.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
	Instance.new("UICorner", lootBox)
	table.insert(elementsToToggle, lootBox)

	fishIcon = Instance.new("TextLabel", lootBox)
	fishIcon.Size = UDim2.new(0.33, 0, 1, 0)
	fishIcon.BackgroundTransparency = 1
	fishIcon.TextColor3 = Color3.new(1, 1, 1)
	fishIcon.Font = Enum.Font.GothamBold
	fishIcon.TextSize = 14

	trashIcon = Instance.new("TextLabel", lootBox)
	trashIcon.Position = UDim2.new(0.34, 0, 0, 0)
	trashIcon.Size = UDim2.new(0.33, 0, 1, 0)
	trashIcon.BackgroundTransparency = 1
	trashIcon.TextColor3 = Color3.new(1, 1, 1)
	trashIcon.Font = Enum.Font.GothamBold
	trashIcon.TextSize = 14

	diamondIcon = Instance.new("TextLabel", lootBox)
	diamondIcon.Position = UDim2.new(0.67, 0, 0, 0)
	diamondIcon.Size = UDim2.new(0.33, 0, 1, 0)
	diamondIcon.BackgroundTransparency = 1
	diamondIcon.TextColor3 = Color3.new(1, 1, 1)
	diamondIcon.Font = Enum.Font.GothamBold
	diamondIcon.TextSize = 14

	local btnFishing = Instance.new("TextButton", frame)
	btnFishing.Position = UDim2.new(0.05, 0, 0, 120)
	btnFishing.Size = UDim2.new(0.9, 0, 0, 36)
	btnFishing.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
	btnFishing.TextColor3 = Color3.new(1, 1, 1)
	btnFishing.Font = Enum.Font.GothamBold
	btnFishing.TextSize = 14
	btnFishing.Text = "Ativar Pesca Automática"
	Instance.new("UICorner", btnFishing)
	table.insert(elementsToToggle, btnFishing)

	btnFishing.MouseButton1Click:Connect(function()
		if autoFishing then
			stopAutoFishing()
			btnFishing.Text = "Ativar Pesca Automática"
		else
			startAutoFishing()
			btnFishing.Text = "Desativar Pesca"
		end
	end)

	local btnIndicator = Instance.new("TextButton", frame)
	btnIndicator.Position = UDim2.new(0.05, 0, 0, 165)
	btnIndicator.Size = UDim2.new(0.9, 0, 0, 36)
	btnIndicator.BackgroundColor3 = Color3.fromRGB(40, 60, 120)
	btnIndicator.TextColor3 = Color3.new(1, 1, 1)
	btnIndicator.Font = Enum.Font.GothamBold
	btnIndicator.TextSize = 14
	btnIndicator.Text = "Ativar Indicador Automático"
	Instance.new("UICorner", btnIndicator)
	table.insert(elementsToToggle, btnIndicator)

	btnIndicator.MouseButton1Click:Connect(function()
		autoIndicator = not autoIndicator
		btnIndicator.Text = autoIndicator and "Desativar Indicador" or "Ativar Indicador Automático"
		if autoIndicator then
			spawn(function()
				while autoIndicator do
					local fishing = workspace:FindFirstChild("fishing")
					local bar = fishing and fishing:FindFirstChild("bar")
					local indicator = bar and bar:FindFirstChild("indicator")
					local safe = bar and bar:FindFirstChild("safeArea")
					if indicator and safe then
						local y = indicator.Position.Y.Scale
						local top = safe.Position.Y.Scale + safe.Size.Y.Scale * 0.9
						local bottom = safe.Position.Y.Scale + safe.Size.Y.Scale * 0.1
						if y < bottom or y > top then
							VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
							wait(0.008)
							VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
						end
					end
					wait(0.02)
				end
			end)
		end
	end)

	ReplicatedStorage.Remotes.RemoteEvents.replicatedValue.OnClientEvent:Connect(function(data)
		if data and data.fishing then
			fishCount = data.fishing.Fish or 0
			trashCount = data.fishing.Trash or 0
			diamondCount = data.fishing.Diamond or 0
			updateLootVisual()
		end
	end)
end


showAnimatedIntro(function()
	createGUI()
end)
