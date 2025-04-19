
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
local fishingTool = nil

local fishCount, trashCount, diamondCount = 0, 0, 0

-- Referências da GUI
local status, toast
local fishIcon, trashIcon, diamondIcon

local function updateLootVisual()
	fishIcon.Text = "🐟 " .. fishCount
	trashIcon.Text = "🗑️ " .. trashCount
	diamondIcon.Text = "💎 " .. diamondCount
end

local function showToast(msg)
	toast.Text = msg
	toast.Visible = true
	TweenService:Create(toast, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.2,
		TextTransparency = 0
	}):Play()
	task.delay(1.2, function()
		TweenService:Create(toast, TweenInfo.new(0.3), {
			BackgroundTransparency = 1,
			TextTransparency = 1
		}):Play()
		task.wait(0.3)
		toast.Visible = false
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
		showToast("Linha lançada!")
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

local function createGUI()
	local gui = Instance.new("ScreenGui", guiRoot)
	gui.Name = "FishingHUDModern"

	local frame = Instance.new("Frame", gui)
	frame.Position = UDim2.new(1, -290, 0.25, 0)
	frame.Size = UDim2.new(0, 260, 0, 240)
	frame.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Text = "Bigode X"
	title.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

	status = Instance.new("TextLabel", frame)
	status.Position = UDim2.new(0, 10, 0, 40)
	status.Size = UDim2.new(1, -20, 0, 20)
	status.BackgroundTransparency = 1
	status.Text = "Status: Inativo"
	status.TextColor3 = Color3.fromRGB(200, 220, 255)
	status.Font = Enum.Font.Gotham
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left

	local lootBox = Instance.new("Frame", frame)
	lootBox.Position = UDim2.new(0.05, 0, 0, 70)
	lootBox.Size = UDim2.new(0.9, 0, 0, 36)
	lootBox.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
	lootBox.BorderSizePixel = 0
	Instance.new("UICorner", lootBox).CornerRadius = UDim.new(0, 6)

	fishIcon = Instance.new("TextLabel", lootBox)
	fishIcon.Size = UDim2.new(0.33, 0, 1, 0)
	fishIcon.Text = "🐟 0"
	fishIcon.BackgroundTransparency = 1
	fishIcon.TextColor3 = Color3.new(1, 1, 1)
	fishIcon.Font = Enum.Font.GothamBold
	fishIcon.TextSize = 14

	trashIcon = Instance.new("TextLabel", lootBox)
	trashIcon.Position = UDim2.new(0.34, 0, 0, 0)
	trashIcon.Size = UDim2.new(0.33, 0, 1, 0)
	trashIcon.Text = "🗑️ 0"
	trashIcon.BackgroundTransparency = 1
	trashIcon.TextColor3 = Color3.new(1, 1, 1)
	trashIcon.Font = Enum.Font.GothamBold
	trashIcon.TextSize = 14

	diamondIcon = Instance.new("TextLabel", lootBox)
	diamondIcon.Position = UDim2.new(0.67, 0, 0, 0)
	diamondIcon.Size = UDim2.new(0.33, 0, 1, 0)
	diamondIcon.Text = "💎 0"
	diamondIcon.BackgroundTransparency = 1
	diamondIcon.TextColor3 = Color3.new(1, 1, 1)
	diamondIcon.Font = Enum.Font.GothamBold
	diamondIcon.TextSize = 14

	toast = Instance.new("TextLabel", gui)
	toast.Size = UDim2.new(0, 240, 0, 40)
	toast.Position = UDim2.new(0.5, -120, 0.88, 0)
	toast.BackgroundColor3 = Color3.fromRGB(30, 100, 180)
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.TextSize = 14
	toast.Font = Enum.Font.GothamBold
	toast.BackgroundTransparency = 1
	toast.TextTransparency = 1
	toast.Visible = false
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)

	local btnFishing = Instance.new("TextButton", frame)
	btnFishing.Position = UDim2.new(0.05, 0, 0, 120)
	btnFishing.Size = UDim2.new(0.9, 0, 0, 36)
	btnFishing.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
	btnFishing.TextColor3 = Color3.new(1, 1, 1)
	btnFishing.Font = Enum.Font.GothamBold
	btnFishing.TextSize = 14
	btnFishing.Text = "Ativar Pesca Automática"
	Instance.new("UICorner", btnFishing).CornerRadius = UDim.new(0, 6)

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
	Instance.new("UICorner", btnIndicator).CornerRadius = UDim.new(0, 6)

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
							task.wait(0.008)
							VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
						end
					end
					task.wait(0.02)
				end
			end)
		end
	end)

	-- Atualização em tempo real do loot
	ReplicatedStorage.Remotes.RemoteEvents.replicatedValue.OnClientEvent:Connect(function(data)
		if data and data.fishing then
			fishCount = data.fishing.Fish or 0
			trashCount = data.fishing.Trash or 0
			diamondCount = data.fishing.Diamond or 0
			updateLootVisual()
		end
	end)
end

createGUI()
