local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack")
local guiRoot = player:WaitForChild("PlayerGui")

local autoFishing = false
local autoIndicatorEnabled = false
local minimized = false
local fishingTool = nil
local blocker = nil
local holdingClick = false

local fishCount, trashCount, diamondCount = 0, 0, 0
local status
local fishIcon, trashIcon, diamondIcon
local elementsToToggle = {}
local toggleFishingFromKey

local function waitForFishing()
	while not workspace:FindFirstChild("fishing") do task.wait(0.05) end
end

local function startHolding()
	if not holdingClick then
		VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
		holdingClick = true
	end
end

local function stopHolding()
	if holdingClick then
		VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
		holdingClick = false
	end
end

local function getIndicatorState()
	local fishing = workspace:FindFirstChild("fishing")
	if not fishing then return "missing" end

	local bar = fishing:FindFirstChild("bar")
	local safeArea = bar and bar:FindFirstChild("safeArea")
	local indicator = bar and bar:FindFirstChild("indicator")

	if not safeArea or not indicator then return "missing" end

	local safeY = safeArea.Position.Y.Scale
	local safeH = safeArea.Size.Y.Scale
	local indicatorY = indicator.Position.Y.Scale

	local effectiveSize = math.max(safeH, 0.05)

	local margin = math.max(effectiveSize * 0.1, 0.015)
	local bufferApproach = effectiveSize * 0.06
	local bufferRisk = effectiveSize * 0.04

	local top = safeY + effectiveSize - margin
	local bottom = safeY + margin

	local approachingTop = top - bufferApproach
	local atRiskTop = top - bufferRisk
	local approachingBottom = bottom + bufferApproach
	local atRiskBottom = bottom + bufferRisk

	if indicatorY < approachingBottom or indicatorY > approachingTop then
		if indicatorY < atRiskBottom or indicatorY > atRiskTop then
			if indicatorY < bottom or indicatorY > top then
				return "out"
			end
			return "atRisk"
		end
		return "approaching"
	else
		return "safe"
	end
end

local function ensureIndicatorControl()
	RunService.Heartbeat:Connect(function()
		if not autoIndicatorEnabled then return end
		waitForFishing()

		local state = getIndicatorState()

		if state == "approaching" or state == "atRisk" then
			startHolding()
		elseif state == "safe" then
			stopHolding()
		elseif state == "out" then
			startHolding()
		end
	end)
end

local function updateLootVisual()
	fishIcon.Text = "🐟 " .. fishCount
	trashIcon.Text = "🗑️ " .. trashCount
	diamondIcon.Text = "💎 " .. diamondCount
end

local function applyHoverEffect(button)
	local originalColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = originalColor:Lerp(Color3.new(1, 1, 1), 0.1)
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = originalColor
		}):Play()
	end)
end

local function updateFishingButtonState(btn, active)
	local color = active and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 100, 200)
	TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = color}):Play()
end

local function toggleMinimize(frame, minimizeBtn)
	minimized = not minimized
	for _, ui in ipairs(elementsToToggle) do
		ui.Visible = not minimized
	end
	frame.Size = minimized and UDim2.new(0, 50, 0, 50) or UDim2.new(0, 270, 0, 260)
	minimizeBtn.Text = minimized and "+" or "-"
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

local function createBlocker()
	if blocker then blocker:Destroy() end
	blocker = Instance.new("TextButton")
	blocker.Name = "FishingBlocker"
	blocker.Size = UDim2.new(1, 0, 1, 0)
	blocker.Position = UDim2.new(0, 0, 0, 0)
	blocker.Text = ""
	blocker.BackgroundTransparency = 1
	blocker.AutoButtonColor = false
	blocker.ZIndex = 9999
	blocker.Parent = guiRoot
	blocker.Visible = false
end

local function startAutoFishing()
	autoFishing = true
	status.Text = "Status: Automático"
	if not blocker then createBlocker() end

	spawn(function()
		while autoFishing do
			blocker.Visible = true
			launchLine()
			local startTime = tick()

			spawn(function()
				while autoFishing do
					if not character:FindFirstChild("Fishing Rod") then
						equipRod()
						task.wait(0.2)
						if fishingTool then fishingTool:Activate() end
					end
					task.wait(1)
				end
			end)

			wait(61.1 - (tick() - startTime))
			blocker.Visible = false
		end
	end)
end

local function stopAutoFishing()
	autoFishing = false
	status.Text = "Status: Inativo"
	if blocker then blocker.Visible = false end
	stopHolding()
end

toggleFishingFromKey = function(buttonRef)
	if autoFishing then
		stopAutoFishing()
		if buttonRef then buttonRef.Text = "Ativar Pesca Automática" end
	else
		startAutoFishing()
		if buttonRef then buttonRef.Text = "Desativar Pesca" end
	end
	updateFishingButtonState(buttonRef, autoFishing)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.P then
		if guiRoot:FindFirstChild("FishingHUD") then
			local btn = guiRoot.FishingHUD:FindFirstChildWhichIsA("Frame"):FindFirstChild("TextButton")
			toggleFishingFromKey(btn)
		end
	end
end)

local function createGUI()
	local gui = Instance.new("ScreenGui", guiRoot)
	gui.Name = "FishingHUD"

	local frame = Instance.new("Frame", gui)
	frame.Position = UDim2.new(1, -290, 0.3, 0)
	frame.Size = UDim2.new(0, 270, 0, 260)
	frame.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Text = "Bigode X.  (v3.4)"
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
	applyHoverEffect(btnFishing)

	btnFishing.MouseButton1Click:Connect(function()
		toggleFishingFromKey(btnFishing)
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
	applyHoverEffect(btnIndicator)

	btnIndicator.MouseButton1Click:Connect(function()
		autoIndicatorEnabled = not autoIndicatorEnabled
		btnIndicator.Text = autoIndicatorEnabled and "Desativar Indicador" or "Ativar Indicador Automático"
		if autoIndicatorEnabled then
			ensureIndicatorControl()
		else
			stopHolding()
		end
	end)

	local aviso = Instance.new("TextLabel", frame)
	aviso.Position = UDim2.new(0.05, 0, 1, -35)
	aviso.Size = UDim2.new(0.9, 0, 0, 30)
	aviso.Text = "Caso bugue ou pare de pescar, é só executar novamente o script!"
	aviso.Font = Enum.Font.Gotham
	aviso.TextSize = 11
	aviso.TextColor3 = Color3.fromRGB(255, 80, 80)
	aviso.BackgroundTransparency = 1
	aviso.TextWrapped = true
	aviso.TextYAlignment = Enum.TextYAlignment.Center
	aviso.TextXAlignment = Enum.TextXAlignment.Center
	table.insert(elementsToToggle, aviso)

	ReplicatedStorage.Remotes.RemoteEvents.replicatedValue.OnClientEvent:Connect(function(data)
		if data and data.fishing then
			fishCount = data.fishing.Fish or 0
			trashCount = data.fishing.Trash or 0
			diamondCount = data.fishing.Diamond or 0
			updateLootVisual()
		end
	end)
end

-- INTRO Game UI com barra, animada e moderna
local function showAnimatedIntro(callback)
	local introGui = Instance.new("ScreenGui", guiRoot)
	introGui.Name = "BigodeIntro"
	introGui.IgnoreGuiInset = true

	local frame = Instance.new("Frame", introGui)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)

	local title = Instance.new("TextLabel", frame)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0.4, 0)
	title.Size = UDim2.new(0, 420, 0, 55)
	title.Text = "BIGODE HUB"
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = Color3.fromRGB(0, 180, 255)
	title.TextStrokeTransparency = 0.7
	title.TextSize = 40
	title.TextTransparency = 1
	title.BackgroundTransparency = 1

	local subtitle = Instance.new("TextLabel", frame)
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.Position = UDim2.new(0.5, 0, 0.47, 0)
	subtitle.Size = UDim2.new(0, 400, 0, 24)
	subtitle.Text = "Use e abuse com moderação 🎮"
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 210)
	subtitle.TextSize = 16
	subtitle.BackgroundTransparency = 1
	subtitle.TextTransparency = 1

	local barBack = Instance.new("Frame", frame)
	barBack.AnchorPoint = Vector2.new(0.5, 0.5)
	barBack.Position = UDim2.new(0.5, 0, 0.55, 0)
	barBack.Size = UDim2.new(0, 280, 0, 10)
	barBack.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	barBack.BorderSizePixel = 0
	Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 6)

	local barFill = Instance.new("Frame", barBack)
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
	barFill.BorderSizePixel = 0
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 6)

	frame.Parent = introGui
	introGui.Parent = guiRoot

	TweenService:Create(title, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
	task.wait(0.3)
	TweenService:Create(subtitle, TweenInfo.new(0.8), {TextTransparency = 0}):Play()

	spawn(function()
		for i = 1, 100 do
			barFill:TweenSize(UDim2.new(i / 100, 0, 1, 0), "Out", "Quad", 0.01, true)
			task.wait(0.01)
		end
		task.wait(0.4)
		TweenService:Create(title, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
		TweenService:Create(subtitle, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
		TweenService:Create(barBack, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
		TweenService:Create(barFill, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
		task.wait(0.6)
		introGui:Destroy()
		if callback then callback() end
	end)
end

showAnimatedIntro(function()
	createGUI()
end)
