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
	frame.Size = minimized and UDim2.new(0, 50, 0, 50) or UDim2.new(0, 280, 0, 300)
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
	gui.ResetOnSpawn = false

	local frame = Instance.new("Frame", gui)
	frame.Position = UDim2.new(1, -300, 0.3, 0)
	frame.Size = UDim2.new(0, 280, 0, 300)
	frame.BackgroundColor3 = COLORS.bg
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	-- Perfil do jogador no topo
	local profileHolder = Instance.new("Frame", frame)
	profileHolder.Size = UDim2.new(1, 0, 0, 70)
	profileHolder.Position = UDim2.new(0, 0, 0, -70)
	profileHolder.BackgroundTransparency = 1

	local avatarFrame = Instance.new("ImageLabel", profileHolder)
	avatarFrame.Name = "Avatar"
	avatarFrame.Size = UDim2.new(0, 60, 0, 60)
	avatarFrame.Position = UDim2.new(0.5, -30, 0, 5)
	avatarFrame.BackgroundTransparency = 1
	avatarFrame.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"
	avatarFrame.ZIndex = 2

	local avatarMask = Instance.new("ImageLabel", avatarFrame)
	avatarMask.Size = UDim2.new(1, 0, 1, 0)
	avatarMask.BackgroundTransparency = 1
	avatarMask.Image = "rbxassetid://3570695787" -- círculo
	avatarMask.ImageColor3 = Color3.fromRGB(255, 255, 255)
	avatarMask.ScaleType = Enum.ScaleType.Fit
	avatarMask.ZIndex = 3

	local nameLabel = Instance.new("TextLabel", profileHolder)
	nameLabel.Position = UDim2.new(0.5, -100, 0, 65)
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.Text = player.DisplayName or player.Name
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.8
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.ZIndex = 2

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

local function createButton(text, yOffset, callback)
		local button = Instance.new("TextButton", frame)
		button.Size = UDim2.new(0.9, 0, 0, 30)
		button.Position = UDim2.new(0.05, 0, 0, yOffset)
		button.BackgroundColor3 = COLORS.button
		button.Text = text
		button.TextColor3 = COLORS.text
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.AutoButtonColor = true

		local corner = Instance.new("UICorner", button)
		corner.CornerRadius = UDim.new(0, 6)

		button.MouseButton1Click:Connect(callback)

		table.insert(elementsToToggle, button)

		return button
	end

	createButton("Ativar / Desativar", 115, function()
		autoFishing = not autoFishing
		status.Text = "Status: " .. (autoFishing and "Pescando..." or "Inativo")

		if autoFishing then
			fishLoop = task.spawn(startFishing)
			equipRod()
		else
			if fishLoop then
				task.cancel(fishLoop)
			end
		end
	end)

	createButton("Auto Vender", 150, function()
		autoSell = not autoSell
		updateLoot()
	end)

	createButton("Auto Jogar Vara", 185, function()
		autoCast = not autoCast
	end)

	createButton("Auto Equipar Vara", 220, function()
		autoEquip = not autoEquip
		if autoEquip and character then
			equipRod()
		end
	end)

	createButton("Fechar GUI", 255, function()
		gui:Destroy()
	end)
end

local function toggleMinimize()
	minimized = not minimized
	for _, element in pairs(elementsToToggle) do
		element.Visible = not minimized
	end
end

local function equipRod()
	if not character then return end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end

	for _, item in ipairs(backpack:GetChildren()) do
		if item:IsA("Tool") and item:FindFirstChild("Rod") then
			item.Parent = character
			break
		end
	end
end

local function startFishing()
	while autoFishing and task.wait() do
		local rod = getFishingRod()
		if not rod then
			if autoEquip then
				equipRod()
			end
			continue
		end

		if not rod:FindFirstChild("Handle") then continue end

		if autoCast then
			fireclickdetector(rod.Handle:FindFirstChildWhichIsA("ClickDetector"))
		end

		local success = waitForFish(rod)
		if success then
			fireclickdetector(rod.Handle:FindFirstChildWhichIsA("ClickDetector"))
		end

		if autoSell then
			sellFish()
		end
	end
end

local function getFishingRod()
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("Rod") then
			return tool
		end
	end
	return nil
end

local function waitForFish(rod)
	local result = false
	local timeout = 10
	local timer = 0

	while timer < timeout do
		task.wait(0.5)
		timer += 0.5

		if rod:FindFirstChild("Fish") then
			result = true
			break
		end
	end

	return result
end

local function sellFish()
	local sellPart = workspace:FindFirstChild("Sell")
	if sellPart and sellPart:IsA("BasePart") then
		character:PivotTo(sellPart.CFrame + Vector3.new(0, 3, 0))
		task.wait(1)
	end
end

local function updateLoot()
	local folder = player:FindFirstChild("FishInventory")
	if not folder then return end

	lootList.Text = ""
	for _, item in ipairs(folder:GetChildren()) do
		lootList.Text ..= item.Name .. " x" .. tostring(item.Value and item.Value.Value or 1) .. "\n"
	end
end

-- Atualiza referência do personagem
player.CharacterAdded:Connect(function(char)
	character = char
end)

-- Cria interface e inicia verificação de loot
createGUI()

-- Atualização periódica da lista de loot
task.spawn(function()
	while task.wait(2) do
		updateLoot()
	end
end)
