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
local heartbeatConnection

local COLORS = {
	bg = Color3.fromRGB(15, 15, 15),
	title = Color3.fromRGB(255, 40, 40),
	buttonPrimary = Color3.fromRGB(200, 50, 50),
	buttonSecondary = Color3.fromRGB(60, 60, 60),
	text = Color3.new(1, 1, 1)
}

local function animateLoot(icon)
	TweenService:Create(icon, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 18}):Play()
	task.wait(0.15)
	TweenService:Create(icon, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {TextSize = 14}):Play()
end

local function updateLootVisual()
	fishIcon.Text = "🐟 " .. fishCount
	trashIcon.Text = "🗑️ " .. trashCount
	diamondIcon.Text = "💎 " .. diamondCount
	animateLoot(fishIcon)
	animateLoot(trashIcon)
	animateLoot(diamondIcon)
end

local function applyHoverEffect(button)
	local originalColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = originalColor:Lerp(Color3.new(1, 0.3, 0.3), 0.1)
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = originalColor
		}):Play()
	end)
end

local function updateFishingButtonState(btn, active)
	local color = active and Color3.fromRGB(220, 60, 60) or COLORS.buttonPrimary
	TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = color}):Play()
end

local function toggleMinimize(frame, minimizeBtn)
	minimized = not minimized
	for _, ui in ipairs(elementsToToggle) do
		ui.Visible = not minimized
	end
	frame.Size = minimized and UDim2.new(0, 50, 0, 50) or UDim2.new(0, 280, 0, 270)
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
	if heartbeatConnection then heartbeatConnection:Disconnect() end
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not autoIndicatorEnabled then return end
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

local function onCharacterAdded(char)
	character = char
	if autoFishing then
		task.wait(1)
		equipRod()
	end
end

player.CharacterAdded:Connect(onCharacterAdded)

local function createGUI()
	local gui = Instance.new("ScreenGui", guiRoot)
	gui.Name = "FishingHUD"

	local frame = Instance.new("Frame", gui)
	frame.Position = UDim2.new(1, -300, 0.3, 0)
	frame.Size = UDim2.new(0, 280, 0, 270)
	frame.BackgroundColor3 = COLORS.bg
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Text = "BIGODE X"
	title.BackgroundColor3 = COLORS.title
	title.TextColor3 = COLORS.text
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	Instance.new("UICorner", title)
	table.insert(elementsToToggle, title)

	local minimize = Instance.new("TextButton", frame)
	minimize.Size = UDim2.new(0, 26, 0, 26)
	minimize.Position = UDim2.new(1, -30, 0, 2)
	minimize.BackgroundColor3 = COLORS.buttonSecondary
	minimize.Text = "-"
	minimize.TextColor3 = COLORS.text
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
	status.TextColor3 = COLORS.text
	status.Font = Enum.Font.Gotham
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(elementsToToggle, status)

	local lootBox = Instance.new("Frame", frame)
	lootBox.Position = UDim2.new(0.05, 0, 0, 70)
	lootBox.Size = UDim2.new(0.9, 0, 0, 36)
	lootBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	Instance.new("UICorner", lootBox)
	table.insert(elementsToToggle, lootBox)

	fishIcon = Instance.new("TextLabel", lootBox)
	fishIcon.Size = UDim2.new(0.33, 0, 1, 0)
	fishIcon.BackgroundTransparency = 1
	fishIcon.TextColor3 = COLORS.text
	fishIcon.Font = Enum.Font.GothamBold
	fishIcon.TextSize = 14

	trashIcon = Instance.new("TextLabel", lootBox)
	trashIcon.Position = UDim2.new(0.34, 0, 0, 0)
	trashIcon.Size = UDim2.new(0.33, 0, 1, 0)
	trashIcon.BackgroundTransparency = 1
	trashIcon.TextColor3 = COLORS.text
	trashIcon.Font = Enum.Font.GothamBold
	trashIcon.TextSize = 14

	diamondIcon = Instance.new("TextLabel", lootBox)
	diamondIcon.Position = UDim2.new(0.67, 0, 0, 0)
	diamondIcon.Size = UDim2.new(0.33, 0, 1, 0)
	diamondIcon.BackgroundTransparency = 1
	diamondIcon.TextColor3 = COLORS.text
	diamondIcon.Font = Enum.Font.GothamBold
	diamondIcon.TextSize = 14

	local btnFishing = Instance.new("TextButton", frame)
	btnFishing.Position = UDim2.new(0.05, 0, 0, 120)
	btnFishing.Size = UDim2.new(0.9, 0, 0, 36)
	btnFishing.BackgroundColor3 = COLORS.buttonPrimary
	btnFishing.TextColor3 = COLORS.text
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
	btnIndicator.BackgroundColor3 = COLORS.buttonSecondary
	btnIndicator.TextColor3 = COLORS.text
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
	aviso.TextColor3 = Color3.fromRGB(255, 60, 60)
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

local function showAnimatedIntro(callback)
	local introGui = Instance.new("ScreenGui", guiRoot)
	introGui.Name = "BigodeIntro"
	introGui.IgnoreGuiInset = true

	local frame = Instance.new("Frame", introGui)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = COLORS.bg

	local title = Instance.new("TextLabel", frame)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0.4, 0)
	title.Size = UDim2.new(0, 420, 0, 55)
	title.Text = "BIGODE HUB"
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = COLORS.title
	title.TextStrokeTransparency = 0.7
	title.TextSize = 40
	title.TextTransparency = 1
	title.BackgroundTransparency = 1

	local subtitle = Instance.new("TextLabel", frame)
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.Position = UDim2.new(0.5, 0, 0.47, 0)
	subtitle.Size = UDim2.new(0, 400, 0, 24)
	subtitle.Text = "[3.5] Update visual. Preto + vermelho. 03/05"
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextColor3 = Color3.fromRGB(220, 220, 220)
	subtitle.TextSize = 16
	subtitle.BackgroundTransparency = 1
	subtitle.TextTransparency = 1

	local spinner = Instance.new("Frame", frame)
	spinner.AnchorPoint = Vector2.new(0.5, 0.5)
	spinner.Position = UDim2.new(0.5, 0, 0.6, 0)
	spinner.Size = UDim2.new(0, 40, 0, 40)
	spinner.BackgroundColor3 = COLORS.title
	spinner.BackgroundTransparency = 1
	spinner.BorderSizePixel = 0
	Instance.new("UICorner", spinner).CornerRadius = UDim.new(1, 0)

	local angle = 0
	local running = true
	local conn = RunService.RenderStepped:Connect(function(dt)
		if not running then return end
		angle = (angle + dt * 300) % 360
		spinner.Rotation = angle
	end)

	frame.Parent = introGui
	introGui.Parent = guiRoot

	TweenService:Create(title, TweenInfo.new(0.6), {TextTransparency = 0}):Play()
	TweenService:Create(subtitle, TweenInfo.new(0.6), {TextTransparency = 0}):Play()
	TweenService:Create(spinner, TweenInfo.new(0.6), {BackgroundTransparency = 0}):Play()

	task.wait(3.2)

	TweenService:Create(title, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(subtitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(spinner, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()

	task.delay(0.5, function()
		running = false
		conn:Disconnect()
		introGui:Destroy()
		if callback then callback() end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.P then
		local gui = guiRoot:FindFirstChild("FishingHUD")
		if gui then
			local btn = gui:FindFirstChildWhichIsA("Frame"):FindFirstChild("TextButton")
			if btn then toggleFishingFromKey(btn) end
		end
	end
end)

toggleFishingFromKey = function(buttonRef)
	if autoFishing then
		autoFishing = false
		status.Text = "Status: Inativo"
		if buttonRef then buttonRef.Text = "Ativar Pesca Automática" end
		if blocker then blocker.Visible = false end
		stopHolding()
	else
		autoFishing = true
		status.Text = "Status: Automático"
		if not blocker then createBlocker() end
		blocker.Visible = true
		if buttonRef then buttonRef.Text = "Desativar Pesca" end
		spawn(function()
			while autoFishing do
				launchLine()
				task.wait(62)
			end
		end)
	end
	updateFishingButtonState(buttonRef, autoFishing)
end

showAnimatedIntro(function()
	createGUI()
end)
