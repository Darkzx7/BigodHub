local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua", true))()
if not RefLib then error("[EggCollector] RefLib failed to load.") end

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")

local SAVE_FILE = "egg_collector_save.json"

local function saveCollected(n)
	pcall(function() writefile(SAVE_FILE, tostring(n)) end)
end

local function loadCollected()
	local ok, data = pcall(function() return readfile(SAVE_FILE) end)
	if ok and data then
		local n = tonumber(data)
		if n then return n end
	end
	return 0
end

local UI_ASSET_ID = "rbxassetid://131165537896572"
local ui = RefLib.new("egg collector", UI_ASSET_ID, "egg_collector_cfg")

local ZONES = {
	{ name = "Zone A", pos = Vector3.new(-207, 4,   872) },
	{ name = "Zone B", pos = Vector3.new( 100, 18,  600) },
	{ name = "Zone C", pos = Vector3.new(  -6, 16,  490) },
	{ name = "Zone D", pos = Vector3.new(-120, 8,   650) },
	{ name = "Zone E", pos = Vector3.new( 420, 6,   720) },
	{ name = "Zone F", pos = Vector3.new( -64, 19,  350) },
	{ name = "Zone G", pos = Vector3.new(-250, 25,  820) },
	{ name = "Zone H", pos = Vector3.new( 160, 24,  900) },
}

local ZONE_RADIUS          = 140
local ZONE_WAIT            = 20
local COLLECT_DELAY        = 0.50
local MANUAL_COLLECT_DELAY = 0.015
local VOID_THRESHOLD       = -30
local PROXIMITY_RADIUS     = 80

local collectOn       = false
local proximityOn     = false
local collected       = 0
local collectDelay    = COLLECT_DELAY
local statusLabel     = nil

local lastSafePos     = nil
local eggSpawnFolder  = nil
local proximityThread = nil

local function myHRP()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function isAlive()
	local chr = player.Character; if not chr then return false end
	local hum = chr:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function setCollision(on)
	local chr = player.Character; if not chr then return end
	for _, p in ipairs(chr:GetDescendants()) do
		if p:IsA("BasePart") then pcall(function() p.CanCollide = on end) end
	end
end

RunService.Heartbeat:Connect(function()
	local hrp = myHRP()
	if hrp and hrp.Position.Y > 10 then lastSafePos = hrp.CFrame end
end)

RunService.Heartbeat:Connect(function()
	local hrp = myHRP()
	if hrp and hrp.Position.Y < VOID_THRESHOLD and lastSafePos then
		hrp.CFrame = lastSafePos
	end
end)

local function hasGroundAt(pos)
	local p1 = RaycastParams.new()
	p1.FilterType = Enum.RaycastFilterType.Exclude
	pcall(function() p1.FilterDescendantsInstances = { player.Character } end)
	if workspace:Raycast(Vector3.new(pos.X, pos.Y + 60, pos.Z), Vector3.new(0, -200, 0), p1) then return true end
	local p2 = RaycastParams.new()
	p2.FilterType = Enum.RaycastFilterType.Include
	pcall(function() p2.FilterDescendantsInstances = { workspace.Terrain } end)
	return workspace:Raycast(Vector3.new(pos.X, pos.Y + 60, pos.Z), Vector3.new(0, -200, 0), p2) ~= nil
end

local function teleportTo(pos)
	local hrp = myHRP(); if not hrp then return false end
	if pos.Y < VOID_THRESHOLD then
		ui:Toast(UI_ASSET_ID, "Zone skipped", "Position below void threshold")
		return false
	end
	if not hasGroundAt(pos) then
		ui:Toast(UI_ASSET_ID, "Zone skipped", "No ground detected")
		return false
	end
	local fallback = hrp.CFrame
	setCollision(false)
	hrp.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)
	for _ = 1, 6 do
		task.wait()
		hrp = myHRP()
		if not hrp then setCollision(true); return false end
		if hrp.Position.Y < VOID_THRESHOLD then
			hrp.CFrame = fallback
			setCollision(true)
			ui:Toast(UI_ASSET_ID, "Teleport reverted", "Fell into void — skipped")
			return false
		end
	end
	setCollision(true)
	return true
end

local function updateStatus()
	if statusLabel then statusLabel.Set("collected: " .. collected) end
	saveCollected(collected)
end

local function detectEggFolder()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "EggTemplate" and obj.Parent and obj.Parent ~= workspace then
			local ovo = obj:FindFirstChild("Ovo") or obj:FindFirstChild("Ovo2")
			if ovo and ovo:IsA("BasePart") then
				eggSpawnFolder = obj.Parent
				return eggSpawnFolder
			end
		end
	end
	return nil
end

local function findAllEggs(center)
	local folder = eggSpawnFolder or detectEggFolder()
	if not folder or not folder.Parent then
		eggSpawnFolder = nil
		folder = detectEggFolder()
		if not folder then return {} end
	end
	local eggs, seen = {}, {}
	for _, obj in ipairs(folder:GetDescendants()) do
		pcall(function()
			if obj.Name == "EggTemplate" and not seen[obj] and obj.Parent then
				local ovo = obj:FindFirstChild("Ovo") or obj:FindFirstChild("Ovo2")
				if ovo and ovo:IsA("BasePart") and ovo.Position.Y > VOID_THRESHOLD then
					seen[obj] = true
					local dist = (ovo.Position - center).Magnitude
					table.insert(eggs, { model = obj, part = ovo, pos = ovo.Position, dist = dist })
				end
			end
		end)
	end
	table.sort(eggs, function(a, b) return a.dist < b.dist end)
	return eggs
end

local function findEggsInRadius(center, radius)
	local out = {}
	for _, e in ipairs(findAllEggs(center)) do
		if e.dist <= radius then table.insert(out, e) end
	end
	return out
end

local function collectEgg(eggData)
	local hrp = myHRP(); if not hrp then return false end
	if not eggData.model.Parent then return false end
	local part = eggData.model:FindFirstChild("Ovo") or eggData.model:FindFirstChild("Ovo2")
	if not part or not part.Parent then return false end
	local target = part.Position + Vector3.new(0, 2.5, 0)
	if target.Y < VOID_THRESHOLD then return false end
	if not hasGroundAt(part.Position) then return false end
	local fallback = hrp.CFrame
	setCollision(false)
	hrp.CFrame = CFrame.new(target)
	task.wait(0.06)
	hrp = myHRP()
	if hrp and hrp.Position.Y < VOID_THRESHOLD then
		hrp.CFrame = fallback
		setCollision(true)
		return false
	end
	if hrp then
		hrp.CFrame = CFrame.new(target + Vector3.new(0.4, 0, 0))
		task.wait(0.05)
		hrp = myHRP()
		if hrp then hrp.CFrame = CFrame.new(target) end
		task.wait(0.05)
	end
	setCollision(true)
	return true
end

local function startProximityLoop()
	if proximityThread then return end
	proximityThread = task.spawn(function()
		while proximityOn do
			if isAlive() then
				local hrp = myHRP()
				if hrp then
					for _, eggData in ipairs(findEggsInRadius(hrp.Position, PROXIMITY_RADIUS)) do
						if not proximityOn then break end
						if not isAlive() then break end
						if collectEgg(eggData) then
							collected = collected + 1
							updateStatus()
						end
						task.wait(0.05)
					end
				end
			end
			task.wait(0.5)
		end
		proximityThread = nil
	end)
end

local function stopProximityLoop()
	proximityOn     = false
	proximityThread = nil
end

local function collectLoop()
	if not eggSpawnFolder then detectEggFolder() end
	while collectOn do
		if not isAlive() then
			ui:Toast(UI_ASSET_ID, "Waiting", "Dead — waiting for respawn...")
			task.wait(2)
			continue
		end
		for _, zone in ipairs(ZONES) do
			if not collectOn then break end
			if not isAlive() then break end
			local ok = teleportTo(zone.pos)
			if not ok then continue end
			ui:Toast(UI_ASSET_ID, "→ " .. zone.name, "Scanning for eggs...")
			local waited, foundAny = 0, false
			while collectOn and waited < ZONE_WAIT do
				if not isAlive() then break end
				local eggs = findAllEggs(zone.pos)
				if #eggs > 0 then
					foundAny = true
					ui:Toast(UI_ASSET_ID, zone.name .. " — " .. #eggs .. " egg(s)", "Collecting...")
					for _, eggData in ipairs(eggs) do
						if not collectOn then break end
						if not isAlive() then break end
						if collectEgg(eggData) then
							collected = collected + 1
							updateStatus()
						end
						task.wait(collectDelay)
					end
				end
				task.wait(2)
				waited = waited + 2
			end
			if not foundAny then
				ui:Toast(UI_ASSET_ID, zone.name .. " — empty", "Moving on...")
			else
				ui:Toast(UI_ASSET_ID, zone.name .. " — done", "Total: " .. collected)
			end
			task.wait(0.4)
		end
		if collectOn then
			ui:Toast(UI_ASSET_ID, "Cycle complete", "Collected: " .. collected .. " | Restarting...")
			task.wait(1)
		end
	end
end

task.spawn(function()
	local saved = loadCollected()
	if saved > 0 then
		collected = saved
		updateStatus()
		ui:Toast(UI_ASSET_ID, "Progress restored", "Loaded " .. saved .. " collected eggs")
	end
end)

local tab = ui:Tab("eggs")
local sec = tab:Section("auto egg collector")

statusLabel = sec:Label("collected: 0")

sec:Divider("farm")

local t_collect = sec:Toggle("auto collect", false, function(v)
	collectOn = v
	if v then
		task.spawn(collectLoop)
		ui:Toast(UI_ASSET_ID, "Farm started", "Scanning " .. #ZONES .. " zones")
	else
		ui:Toast(UI_ASSET_ID, "Farm stopped", "Total collected: " .. collected)
	end
end)
ui:CfgRegister("egg_collect", function() return collectOn end, function(v) t_collect.Set(v) end)

sec:Divider("proximity")

local t_proximity = sec:Toggle("proximity collect", false, function(v)
	proximityOn = v
	if v then
		startProximityLoop()
		ui:Toast(UI_ASSET_ID, "Proximity ON", "Radius: " .. PROXIMITY_RADIUS .. " studs")
	else
		stopProximityLoop()
		ui:Toast(UI_ASSET_ID, "Proximity OFF", "Stopped")
	end
end)
ui:CfgRegister("egg_proximity", function() return proximityOn end, function(v) t_proximity.Set(v) end)

sec:Divider("delay")

local currentDelayTicks = 10

local sliderRef = sec:Slider("delay (x0.05s)", 1, 20, currentDelayTicks, 1, function(v)
	currentDelayTicks = v
	collectDelay = v * 0.05
end)
ui:CfgRegister("egg_delay", function() return currentDelayTicks end, function(v) sliderRef.Set(v) end)

sec:Divider("manual teleport")

for _, zone in ipairs(ZONES) do
	local z = zone
	sec:Button("→ " .. z.name, function()
		if not isAlive() then
			ui:Toast(UI_ASSET_ID, "Error", "You are dead")
			return
		end
		local ok = teleportTo(z.pos)
		if not ok then return end
		ui:Toast(UI_ASSET_ID, "→ " .. z.name, "Collecting eggs nearby...")
		task.spawn(function()
			local list = findAllEggs(z.pos)
			if #list == 0 then
				ui:Toast(UI_ASSET_ID, z.name .. " — empty", "No eggs found")
				return
			end
			for _, eggData in ipairs(list) do
				if collectEgg(eggData) then collected = collected + 1 end
				updateStatus()
				task.wait(MANUAL_COLLECT_DELAY)
			end
			ui:Toast(UI_ASSET_ID, z.name .. " — done", "Total: " .. collected)
		end)
	end)
end

sec:Divider("utils")

sec:Button("reset counter", function()
	collected = 0
	updateStatus()
	pcall(function() writefile(SAVE_FILE, "0") end)
	ui:Toast(UI_ASSET_ID, "Counter reset", "Cleared — save wiped")
end)

sec:Button("detect egg folder", function()
	eggSpawnFolder = nil
	local folder = detectEggFolder()
	if folder then
		ui:Toast(UI_ASSET_ID, "Folder detected", folder.Name .. " — " .. #folder:GetDescendants() .. " descendants")
	else
		ui:Toast(UI_ASSET_ID, "Not found", "No EggTemplate in workspace")
	end
end)

local tabCfg = ui:Tab("config")
ui:BuildConfigTab(tabCfg, "egg_collector_cfg")
