-- ref universal v2 — reescrito usando RefLib
-- requer que RefLib seja carregada antes (loadstring ou require)

local RefLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Darkzx7/BigodHub/refs/heads/main/reflib.lua"))()
-- ou: local RefLib = require(path_to_reflib)

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")

local player = Players.LocalPlayer
local pg     = player:WaitForChild("PlayerGui")

-- ──────────────────────────────────────────────────────────────
-- INICIALIZA A LIB
-- ──────────────────────────────────────────────────────────────
local lib = RefLib.new("ref", "rbxassetid://131165537896572", "ref_ui_v2")
local T   = lib.Theme

-- ──────────────────────────────────────────────────────────────
-- TABS
-- ──────────────────────────────────────────────────────────────
local tab_uni    = lib:Tab("universal")
local tab_combat = lib:Tab("combat")
local tab_visual = lib:Tab("visual")
local tab_target = lib:Tab("target")
local tab_cfg    = lib:Tab("config")

tab_uni:Select()

-- ──────────────────────────────────────────────────────────────
-- HELPERS INTERNOS
-- ──────────────────────────────────────────────────────────────
local function getChar()  return player.Character end
local function getHRP()   local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function notify(title, sub, color)
    lib:Toast(lib._icon, title or "ref", sub or "", color or T.Accent)
end

-- ──────────────────────────────────────────────────────────────
-- UNIVERSAL — MOVEMENT
-- ──────────────────────────────────────────────────────────────
do
    local sec = tab_uni:Section("movement", true)

    -- ── anti-afk ──
    local afkOn = false
    player.Idled:Connect(function()
        if not afkOn then return end
        local cam = workspace.CurrentCamera
        if cam then cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(0.001), 0) end
    end)
    local t_afk = sec:Toggle("anti-afk", false, function(v) afkOn = v end)
    lib:CfgRegister("antiafk", function() return afkOn end, function(v) t_afk.Set(v) end)

    sec:Divider("walkspeed")

    -- ── walkspeed ──
    local DEFAULT_SPEED = 16
    local wsOn    = false
    local wsVal   = DEFAULT_SPEED
    local function applyWS()
        local h = getHum(); if not h then return end
        h.WalkSpeed = wsOn and wsVal or DEFAULT_SPEED
    end
    player.CharacterAdded:Connect(function(c)
        c:WaitForChild("Humanoid"); task.wait()
        applyWS()
    end)
    local t_ws = sec:Toggle("custom walkspeed", false, function(v) wsOn  = v; applyWS() end)
    local s_ws = sec:Slider("walk speed", 1, 250, DEFAULT_SPEED, 1, function(v) wsVal = v; if wsOn then applyWS() end end)
    lib:CfgRegister("ws_on",  function() return wsOn  end, function(v) t_ws.Set(v) end)
    lib:CfgRegister("ws_val", function() return wsVal end, function(v) s_ws.Set(v) end)

    sec:Divider("jump")

    -- ── jump height ──
    local DEFAULT_JUMP = 7.2
    local jhOn  = false
    local jhVal = DEFAULT_JUMP
    local function applyJH()
        local h = getHum(); if not h then return end
        h.JumpHeight = jhOn and jhVal or DEFAULT_JUMP
    end
    player.CharacterAdded:Connect(function(c)
        c:WaitForChild("Humanoid"); task.wait()
        applyJH()
    end)
    local t_jh = sec:Toggle("custom jump height", false, function(v) jhOn = v; applyJH() end)
    local s_jh = sec:Slider("jump height", 1, 100, DEFAULT_JUMP, 0.5, function(v) jhVal = v; if jhOn then applyJH() end end)
    lib:CfgRegister("jh_on",  function() return jhOn  end, function(v) t_jh.Set(v) end)
    lib:CfgRegister("jh_val", function() return jhVal end, function(v) s_jh.Set(v) end)

    -- ── infinite jump ──
    local ijOn   = false
    local ijConn = nil
    local function applyIJ()
        if ijConn then ijConn:Disconnect() ijConn = nil end
        if not ijOn then return end
        ijConn = UserInputService.JumpRequest:Connect(function()
            local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
    player.CharacterAdded:Connect(function() task.wait(); applyIJ() end)
    local t_ij = sec:Toggle("infinite jump", false, function(v) ijOn = v; applyIJ() end)
    lib:CfgRegister("infjump", function() return ijOn end, function(v) t_ij.Set(v) end)

    sec:Divider("fly")

    -- ── fly ──
    local flyOn    = false
    local flySpeed = 60
    local flyBV, flyBG, flyConn = nil, nil, nil
    local ControlModule = nil
    pcall(function()
        ControlModule = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
    end)
    local function getMoveVec()
        if ControlModule then
            local ok, v = pcall(function() return ControlModule:GetMoveVector() end)
            if ok and v then return v end
        end
        local mv = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv -= Vector3.new(0,0,1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv += Vector3.new(0,0,1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv -= Vector3.new(1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv += Vector3.new(1,0,0) end
        return mv
    end
    local function stopFly()
        flyOn = false
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBV and flyBV.Parent then flyBV.MaxForce = Vector3.zero end
        if flyBG and flyBG.Parent then flyBG.MaxTorque = Vector3.zero end
        local h = getHum(); if h then h.PlatformStand = false end
    end
    local function startFly()
        stopFly(); flyOn = true
        local hrp = getHRP(); local hum = getHum()
        if not hrp or not hum then return end
        flyBV = hrp:FindFirstChild("_ref_BV") or Instance.new("BodyVelocity")
        flyBV.Name = "_ref_BV"; flyBV.MaxForce = Vector3.zero; flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
        flyBG = hrp:FindFirstChild("_ref_BG") or Instance.new("BodyGyro")
        flyBG.Name = "_ref_BG"; flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9); flyBG.P = 1000; flyBG.D = 50; flyBG.CFrame = hrp.CFrame; flyBG.Parent = hrp
        hum.PlatformStand = true
        flyConn = RunService.RenderStepped:Connect(function()
            if not flyOn then return end
            local c = getChar(); if not c then return end
            local h2 = c:FindFirstChild("HumanoidRootPart"); local hm = c:FindFirstChildOfClass("Humanoid")
            if not h2 or not hm then return end
            hm.PlatformStand = true
            flyBV.MaxForce  = Vector3.new(9e9,9e9,9e9)
            flyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
            local cam  = workspace.CurrentCamera
            local look = cam.CFrame.LookVector
            local mv   = getMoveVec()
            local baseCF = CFrame.new(h2.Position, h2.Position + Vector3.new(look.X,0,look.Z))
            local vel    = Vector3.zero
            local pose   = baseCF
            if mv.Magnitude > 0.01 then
                local tilt = mv.Z ~= 0 and (mv.Z > 0 and math.rad(-28) or math.rad(14)) or 0
                local roll = mv.X ~= 0 and (mv.X < 0 and math.rad(18) or math.rad(-18)) or 0
                pose = baseCF * CFrame.Angles(tilt, 0, roll)
                vel  = cam.CFrame.RightVector*(mv.X*flySpeed) - cam.CFrame.LookVector*(mv.Z*flySpeed)
                -- up/down com space/shift
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.new(0,flySpeed*0.7,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.new(0,flySpeed*0.7,0) end
            end
            flyBV.Velocity = vel
            flyBG.CFrame   = pose
        end)
    end
    player.CharacterAdded:Connect(function() task.wait(0.5); if flyOn then startFly() end end)
    local t_fly = sec:Toggle("fly", false, function(v) if v then startFly() else stopFly() end end)
    local s_fly = sec:Slider("fly speed", 5, 300, 60, 5, function(v) flySpeed = v end)
    lib:CfgRegister("fly_on",    function() return flyOn    end, function(v) t_fly.Set(v) end)
    lib:CfgRegister("fly_speed", function() return flySpeed end, function(v) s_fly.Set(v) end)

    -- keybind fly
    sec:Keybind("fly keybind", Enum.KeyCode.F, function(kc)
        lib:_conn(UserInputService.InputBegan, function(inp, gp)
            if gp or inp.KeyCode ~= kc then return end
            t_fly.Set(not flyOn)
        end)
    end)
end

-- ──────────────────────────────────────────────────────────────
-- UNIVERSAL — MISC
-- ──────────────────────────────────────────────────────────────
do
    local sec = tab_uni:Section("misc", true)

    -- ── noclip ──
    local ncOn = false
    RunService.Stepped:Connect(function()
        if not ncOn then return end
        local c = getChar(); if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end)
    local t_nc = sec:Toggle("noclip", false, function(v)
        ncOn = v
        if not v then
            local c = getChar(); if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end)
    lib:CfgRegister("noclip", function() return ncOn end, function(v) t_nc.Set(v) end)

    sec:Divider("spinbot")

    -- ── spinbot melhorado ──
    local spinOn    = false
    local spinSpeed = 10
    local spinAngle = 0
    local spinConn  = nil
    local t_spin = sec:Toggle("spinbot", false, function(v)
        spinOn = v
        if spinConn then spinConn:Disconnect() spinConn = nil end
        spinAngle = 0
        if not v then return end
        spinConn = RunService.Heartbeat:Connect(function(dt)
            if not spinOn then return end
            local hrp = getHRP(); if not hrp then return end
            spinAngle = (spinAngle + spinSpeed * dt * 60) % 360
            hrp.CFrame = CFrame.new(hrp.Position)
                * CFrame.fromEulerAnglesXYZ(0, math.rad(spinAngle), 0)
        end)
    end)
    local s_spin = sec:Slider("spin speed", 1, 50, 10, 1, function(v) spinSpeed = v end)
    lib:CfgRegister("spinbot",     function() return spinOn    end, function(v) t_spin.Set(v) end)
    lib:CfgRegister("spin_speed",  function() return spinSpeed end, function(v) s_spin.Set(v) end)

    sec:Divider("walk on water")

    -- ── walk on water ──
    local wowOn    = false
    local wowConn  = nil
    local wowTiles = {}
    local tileIdx  = {}
    local TILE_S   = 4
    local TILE_TTL = 1.2
    local WATER    = Enum.Material.Water

    local function getWaterY(pos)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local ex = {}; local c = getChar(); if c then table.insert(ex,c) end
        for _, t in ipairs(wowTiles) do if t.part and t.part.Parent then table.insert(ex,t.part) end end
        rp.FilterDescendantsInstances = ex
        local res = workspace:Raycast(Vector3.new(pos.X,pos.Y+10,pos.Z),Vector3.new(0,-80,0),rp)
        return res and res.Material == WATER and res.Position.Y or nil
    end
    local function spawnTile(gx,gz,wy)
        local key = gx..","..gz
        if tileIdx[key] then tileIdx[key].exp = tick()+TILE_TTL return end
        local p = Instance.new("Part")
        p.Name="ref_wow"; p.Size=Vector3.new(TILE_S,.2,TILE_S); p.Anchored=true
        p.CanCollide=true; p.CanQuery=false; p.CastShadow=false; p.Transparency=1
        p.CFrame=CFrame.new(gx*TILE_S+TILE_S/2,wy+.1,gz*TILE_S+TILE_S/2)
        p.Parent=workspace
        local e={part=p,exp=tick()+TILE_TTL,key=key}
        table.insert(wowTiles,e); tileIdx[key]=e
    end
    local function cleanTiles()
        local now=tick(); local i=1
        while i<=#wowTiles do
            local t=wowTiles[i]
            if now>=t.exp then
                if t.part and t.part.Parent then t.part:Destroy() end
                tileIdx[t.key]=nil; table.remove(wowTiles,i)
            else i+=1 end
        end
    end
    local function clearAllTiles()
        for _,t in ipairs(wowTiles) do if t.part and t.part.Parent then t.part:Destroy() end end
        wowTiles={}; tileIdx={}
    end
    local function startWow()
        wowOn=true
        wowConn=RunService.Heartbeat:Connect(function()
            if not wowOn then return end
            local c=getChar(); if not c then return end
            local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local pos=hrp.Position; local wy=getWaterY(pos)
            if wy then
                local gx=math.floor(pos.X/TILE_S); local gz=math.floor(pos.Z/TILE_S)
                spawnTile(gx,gz,wy)
                local vel=hrp.AssemblyLinearVelocity
                if vel.Magnitude>1 then
                    local fv=Vector3.new(vel.X,0,vel.Z)
                    if fv.Magnitude>.5 then
                        local d=fv.Unit
                        local a1=pos+d*TILE_S; spawnTile(math.floor(a1.X/TILE_S),math.floor(a1.Z/TILE_S),wy)
                        local a2=pos+d*TILE_S*2; spawnTile(math.floor(a2.X/TILE_S),math.floor(a2.Z/TILE_S),wy)
                    end
                end
            end
            cleanTiles()
        end)
    end
    local function stopWow()
        wowOn=false
        if wowConn then wowConn:Disconnect() wowConn=nil end
        clearAllTiles()
    end
    player.CharacterAdded:Connect(function() task.wait(.5); if wowOn then startWow() end end)
    sec:Toggle("walk on water", false, function(v) if v then startWow() else stopWow() end end)

    sec:Divider("gravity")

    -- ── gravity ──
    local gravOn  = false
    local gravVal = 196.2
    local function applyGrav()
        workspace.Gravity = gravOn and gravVal or 196.2
    end
    local t_grav = sec:Toggle("custom gravity", false, function(v) gravOn = v; applyGrav() end)
    local s_grav = sec:Slider("gravity", 0, 500, 196, 1, function(v) gravVal = v; if gravOn then applyGrav() end end)
    lib:CfgRegister("grav_on",  function() return gravOn  end, function(v) t_grav.Set(v) end)
    lib:CfgRegister("grav_val", function() return gravVal end, function(v) s_grav.Set(v) end)

    sec:Divider("misc")

    -- ── god mode (local) ──
    local godOn = false
    local godConn = nil
    local t_god = sec:Toggle("local god mode", false, function(v)
        godOn = v
        if godConn then godConn:Disconnect() godConn = nil end
        if not v then return end
        godConn = RunService.Heartbeat:Connect(function()
            if not godOn then return end
            local h = getHum(); if h then h.Health = h.MaxHealth end
        end)
    end)
    lib:CfgRegister("godmode", function() return godOn end, function(v) t_god.Set(v) end)

    -- ── auto-rejoin ──
    sec:Button("rejoin server", function()
        local ts = game:GetService("TeleportService")
        ts:Teleport(game.PlaceId, player)
    end)
end

-- ──────────────────────────────────────────────────────────────
-- COMBAT
-- ──────────────────────────────────────────────────────────────
do
    -- ── hitbox ──
    local secHit = tab_combat:Section("hitbox", true)
    secHit:Divider("settings")

    local hitOn   = false
    local hitSize = 10
    local hitVis  = false
    local origSz  = {}
    local hitParts = {}

    local function removeHitVis(t)
        if hitParts[t] and hitParts[t].Parent then hitParts[t]:Destroy() end
        hitParts[t] = nil
    end
    local function applyHitbox(t, sz)
        local c = t.Character; if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        if not origSz[hrp] then origSz[hrp] = hrp.Size end
        hrp.Size = Vector3.new(sz,sz,sz)
        if hitVis then
            if not hitParts[t] then
                local v = Instance.new("Part")
                v.Name="ref_hitvis"; v.Anchored=false; v.CanCollide=false; v.Massless=true
                v.Shape=Enum.PartType.Ball; v.Material=Enum.Material.ForceField
                v.Color=Color3.fromRGB(120,80,255); v.Transparency=0.5; v.CastShadow=false
                local w=Instance.new("WeldConstraint"); w.Part0=hrp; w.Part1=v; w.Parent=v
                v.CFrame=hrp.CFrame; v.Parent=c; hitParts[t]=v
            end
            hitParts[t].Size=Vector3.new(sz,sz,sz)
        else removeHitVis(t) end
    end
    local function revertHitbox(t)
        local c=t.Character; if not c then return end
        local hrp=c:FindFirstChild("HumanoidRootPart")
        if hrp and origSz[hrp] then hrp.Size=origSz[hrp]; origSz[hrp]=nil end
        removeHitVis(t)
    end
    local function refreshAll()
        for _,t in ipairs(Players:GetPlayers()) do
            if t~=player then if hitOn then applyHitbox(t,hitSize) else revertHitbox(t) end end
        end
    end
    for _,t in ipairs(Players:GetPlayers()) do
        if t~=player then t.CharacterAdded:Connect(function() task.wait(1); if hitOn then applyHitbox(t,hitSize) end end) end
    end
    Players.PlayerAdded:Connect(function(t)
        t.CharacterAdded:Connect(function() task.wait(1); if hitOn then applyHitbox(t,hitSize) end end)
    end)
    Players.PlayerRemoving:Connect(function(t) origSz[t]=nil; removeHitVis(t) end)

    local t_hit = secHit:Toggle("hitbox expander", false, function(v) hitOn=v; refreshAll() end)
    local s_hit = secHit:Slider("hitbox size", 4, 100, 10, 1, function(v) hitSize=v; if hitOn then refreshAll() end end)
    local t_hv  = secHit:Toggle("visualize hitbox", false, function(v) hitVis=v; if hitOn then refreshAll() end end)
    lib:CfgRegister("hit_on",   function() return hitOn   end, function(v) t_hit.Set(v) end)
    lib:CfgRegister("hit_size", function() return hitSize end, function(v) s_hit.Set(v) end)
    lib:CfgRegister("hit_vis",  function() return hitVis  end, function(v) t_hv.Set(v) end)

    -- ── silent aim ──
    local secAim = tab_combat:Section("silent aim", true)
    secAim:Divider("settings")

    local aimOn   = false
    local aimFOV  = 80
    local aimPart = "HumanoidRootPart"  -- alvo padrão

    local aimConn = nil
    local origIndex = nil
    local lastTarget = nil

    local function getBestTarget()
        local cam = workspace.CurrentCamera
        local best, bestDist = nil, math.huge
        for _,t in ipairs(Players:GetPlayers()) do
            if t==player then continue end
            local c=t.Character; if not c then continue end
            local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then continue end
            local sp, onScreen = cam:WorldToScreenPoint(hrp.Position)
            if not onScreen or sp.Z<0 then continue end
            local vp = cam.ViewportSize
            local dx = sp.X - vp.X/2; local dy = sp.Y - vp.Y/2
            local dist = math.sqrt(dx*dx+dy*dy)
            local fovPx = math.tan(math.rad(aimFOV/2)) * vp.Y
            if dist<fovPx and dist<bestDist then best=t; bestDist=dist end
        end
        return best
    end

    -- hook no mouse via metatable (silent aim real)
    local function hookAim()
        if origIndex then return end
        local mt = getrawmetatable and getrawmetatable(player:GetMouse())
        if not mt then return end
        local oldIndex = rawget(mt,"__index")
        setreadonly(mt, false)
        origIndex = oldIndex
        rawset(mt,"__index",newcclosure(function(self,key)
            if (key=="Hit" or key=="Target") and aimOn then
                local t = getBestTarget()
                if t and t.Character then
                    local part = t.Character:FindFirstChild(aimPart)
                           or t.Character:FindFirstChild("HumanoidRootPart")
                    if part then
                        if key=="Hit"    then return part.CFrame end
                        if key=="Target" then return part end
                    end
                end
            end
            return oldIndex(self,key)
        end))
        setreadonly(mt, true)
    end
    local function unhookAim()
        if not origIndex then return end
        local mt = getrawmetatable and getrawmetatable(player:GetMouse())
        if not mt then return end
        setreadonly(mt,false)
        rawset(mt,"__index",origIndex)
        setreadonly(mt,true)
        origIndex = nil
    end

    local t_aim = secAim:Toggle("silent aim", false, function(v)
        aimOn = v
        if v then hookAim() else unhookAim() end
    end)
    local s_fov = secAim:Slider("fov (px radius)", 10, 400, 80, 5, function(v) aimFOV = v end)
    secAim:Dropdown("aim part", {"HumanoidRootPart","Head","Torso","UpperTorso"}, "HumanoidRootPart", function(v) aimPart = v end)
    lib:CfgRegister("aim_on",  function() return aimOn  end, function(v) t_aim.Set(v) end)
    lib:CfgRegister("aim_fov", function() return aimFOV end, function(v) s_fov.Set(v) end)

    -- ── FOV circle visual ──
    local fovCircle = Drawing and Drawing.new("Circle") or nil
    if fovCircle then
        fovCircle.Visible     = false
        fovCircle.Thickness   = 1
        fovCircle.Color       = Color3.fromRGB(120,80,255)
        fovCircle.Transparency = 0.6
        fovCircle.NumSides    = 64
        local fovVisOn = false
        local t_fovv = secAim:Toggle("show fov circle", false, function(v)
            fovVisOn = v; fovCircle.Visible = v and aimOn
        end)
        RunService.RenderStepped:Connect(function()
            if not fovCircle then return end
            fovCircle.Visible = fovVisOn and aimOn
            if fovCircle.Visible then
                local vp = workspace.CurrentCamera.ViewportSize
                fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
                fovCircle.Radius   = math.tan(math.rad(aimFOV/2)) * vp.Y
            end
        end)
    end

    -- ── lock-on ──
    local secLock = tab_combat:Section("lock-on", true)
    secLock:Divider("controls")

    local lockOn   = false
    local lockConn = nil
    local lockRef  = nil
    local _silentStop = false

    local function getLockTarget() return _G.ref_lockTarget end
    local function stopLock(silent)
        lockOn = false
        if lockConn then lockConn:Disconnect() lockConn = nil end
        local cam = workspace.CurrentCamera
        if cam then cam.CameraType = Enum.CameraType.Custom end
        if not silent and lockRef then
            _silentStop = true; lockRef.Set(false); _silentStop = false
        end
    end
    local function startLock()
        lockOn = true
        local cam = workspace.CurrentCamera
        lockConn = RunService.RenderStepped:Connect(function()
            if not lockOn then return end
            local t = getLockTarget(); if not t or not t.Character then return end
            local thrp = t.Character:FindFirstChild("HumanoidRootPart"); if not thrp then return end
            local cp = cam.CFrame.Position
            local tp = thrp.Position + Vector3.new(0,1.5,0)
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cp,tp), 0.3)
        end)
    end
    lockRef = secLock:Toggle("lock-on (uses target tab)", false, function(v)
        if _silentStop then return end
        if v then
            if not getLockTarget() then
                _silentStop=true; lockRef.Set(false); _silentStop=false
                notify("ref","set a target first",T.Bad); return
            end
            startLock()
        else stopLock(true) end
    end)
    secLock:Keybind("lock-on keybind", Enum.KeyCode.Q, function(kc)
        lib:_conn(UserInputService.InputBegan, function(inp,gp)
            if gp or inp.KeyCode~=kc then return end
            if lockOn then stopLock() else
                if getLockTarget() then startLock(); lockRef.Set(true) end
            end
        end)
    end)
    Players.PlayerRemoving:Connect(function(p)
        if p==getLockTarget() and lockOn then stopLock() end
    end)
end

-- ──────────────────────────────────────────────────────────────
-- VISUAL — ESP
-- ──────────────────────────────────────────────────────────────
do
    local sec = tab_visual:Section("esp", true)
    sec:Divider("settings")

    local espOn      = false
    local espShowName = true
    local espShowDist = true
    local espShowHP   = true
    local espMaxDist  = 500
    local espColor    = Color3.fromRGB(120,80,255)
    local espData     = {}
    local camera      = workspace.CurrentCamera

    local function hpColor(hp,mhp)
        local p = math.clamp(hp/math.max(mhp,1),0,1)
        return p>.6 and Color3.fromRGB(80,220,80) or p>.3 and Color3.fromRGB(240,200,40) or Color3.fromRGB(220,60,60)
    end
    local function removeESP(t)
        local d=espData[t]; if not d then return end
        if d.hl  and d.hl.Parent  then d.hl:Destroy()  end
        if d.bb  and d.bb.Parent  then d.bb:Destroy()  end
        espData[t]=nil
    end
    local function createESP(t)
        if espData[t] then return end
        local c=t.Character; if not c then return end
        local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local hl=Instance.new("Highlight")
        hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.FillColor=espColor
        hl.OutlineColor=Color3.new(1,1,1); hl.FillTransparency=0.45; hl.Adornee=c; hl.Parent=c
        local bb=Instance.new("BillboardGui")
        bb.Size=UDim2.new(0,150,0,64); bb.StudsOffset=Vector3.new(0,3.5,0)
        bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Adornee=hrp; bb.Parent=hrp
        local nLbl=Instance.new("TextLabel"); nLbl.BackgroundTransparency=1
        nLbl.Size=UDim2.new(1,0,0,20); nLbl.Font=Enum.Font.GothamBold; nLbl.TextSize=13
        nLbl.TextColor3=Color3.new(1,1,1); nLbl.TextStrokeTransparency=0.1
        nLbl.TextStrokeColor3=Color3.new(0,0,0); nLbl.TextXAlignment=Enum.TextXAlignment.Center
        nLbl.Text=t.DisplayName; nLbl.Parent=bb
        local hpBg=Instance.new("Frame"); hpBg.BackgroundColor3=Color3.fromRGB(20,20,20)
        hpBg.BackgroundTransparency=0.3; hpBg.Size=UDim2.new(1,0,0,4); hpBg.Position=UDim2.new(0,0,0,24); hpBg.Parent=bb
        local hpFill=Instance.new("Frame"); hpFill.BackgroundColor3=Color3.fromRGB(80,220,80)
        hpFill.Size=UDim2.new(1,0,1,0); hpFill.Parent=hpBg
        local dLbl=Instance.new("TextLabel"); dLbl.BackgroundTransparency=1
        dLbl.Size=UDim2.new(1,0,0,14); dLbl.Position=UDim2.new(0,0,0,34)
        dLbl.Font=Enum.Font.Gotham; dLbl.TextSize=11; dLbl.TextColor3=Color3.fromRGB(200,200,220)
        dLbl.TextStrokeTransparency=0.2; dLbl.TextStrokeColor3=Color3.new(0,0,0)
        dLbl.TextXAlignment=Enum.TextXAlignment.Center; dLbl.Text=""; dLbl.Parent=bb
        espData[t]={hl=hl,bb=bb,nLbl=nLbl,hpBg=hpBg,hpFill=hpFill,dLbl=dLbl}
    end
    RunService.RenderStepped:Connect(function()
        if not espOn then return end
        for _,t in ipairs(Players:GetPlayers()) do
            if t==player then continue end
            local c=t.Character; local hum=c and c:FindFirstChildOfClass("Humanoid")
            local hrp=c and c:FindFirstChild("HumanoidRootPart")
            if not c or not hum or not hrp or hum.Health<=0 then removeESP(t); continue end
            local dist=math.floor((camera.CFrame.Position-hrp.Position).Magnitude)
            if dist>espMaxDist then removeESP(t); continue end
            if not espData[t] then createESP(t) end
            local d=espData[t]; if not d then continue end
            if d.hl.Adornee~=c   then d.hl.Adornee=c   end
            if d.bb.Adornee~=hrp then d.bb.Adornee=hrp  end
            d.hl.FillColor       = espColor
            d.nLbl.Visible       = espShowName
            d.nLbl.Text          = t.DisplayName
            local pct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
            d.hpBg.Visible       = espShowHP
            d.hpFill.Size        = UDim2.new(pct,0,1,0)
            d.hpFill.BackgroundColor3 = hpColor(hum.Health,hum.MaxHealth)
            d.dLbl.Visible       = espShowDist
            d.dLbl.Text          = dist.."m"
        end
    end)
    Players.PlayerRemoving:Connect(removeESP)
    local function watchChar(t)
        t.CharacterAdded:Connect(function() removeESP(t); task.wait(1); if espOn then createESP(t) end end)
    end
    for _,t in ipairs(Players:GetPlayers()) do if t~=player then watchChar(t) end end
    Players.PlayerAdded:Connect(watchChar)

    local t_esp      = sec:Toggle("player esp",     false, function(v) espOn=v; if not v then for t in pairs(espData) do removeESP(t) end end end)
    local t_espn     = sec:Toggle("show name",      true,  function(v) espShowName=v end)
    local t_esphp    = sec:Toggle("show health",    true,  function(v) espShowHP=v end)
    local t_espdist  = sec:Toggle("show distance",  true,  function(v) espShowDist=v end)
    local s_espdist  = sec:Slider("max distance",   50,1000,500,10, function(v) espMaxDist=v end)
    sec:ColorPicker("esp color", espColor, function(c) espColor=c end)

    lib:CfgRegister("esp_on",      function() return espOn      end, function(v) t_esp.Set(v)     end)
    lib:CfgRegister("esp_name",    function() return espShowName end, function(v) t_espn.Set(v)    end)
    lib:CfgRegister("esp_hp",      function() return espShowHP   end, function(v) t_esphp.Set(v)   end)
    lib:CfgRegister("esp_dist",    function() return espShowDist  end, function(v) t_espdist.Set(v) end)
    lib:CfgRegister("esp_maxdist", function() return espMaxDist   end, function(v) s_espdist.Set(v) end)

    -- ── chams ──
    local secW = tab_visual:Section("world", true)
    secW:Divider("chams")

    local chamsOn    = false
    local chamsColor = Color3.fromRGB(255,60,60)
    local chamsData  = {}
    local function removeChams(t)
        if chamsData[t] and chamsData[t].Parent then chamsData[t]:Destroy() end
        chamsData[t]=nil
    end
    local function applyChams(t)
        if chamsData[t] then return end
        local c=t.Character; if not c then return end
        local hl=Instance.new("Highlight")
        hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.FillColor=chamsColor
        hl.FillTransparency=0; hl.OutlineColor=Color3.new(1,1,1); hl.OutlineTransparency=0
        hl.Adornee=c; hl.Parent=c; chamsData[t]=hl
    end
    local function refreshChams()
        for _,t in ipairs(Players:GetPlayers()) do
            if t~=player then if chamsOn then applyChams(t) else removeChams(t) end end
        end
    end
    RunService.Heartbeat:Connect(function()
        if not chamsOn then return end
        for _,t in ipairs(Players:GetPlayers()) do
            if t~=player and chamsData[t] then chamsData[t].FillColor=chamsColor end
        end
    end)
    for _,t in ipairs(Players:GetPlayers()) do
        if t~=player then t.CharacterAdded:Connect(function() chamsData[t]=nil; task.wait(.5); if chamsOn then applyChams(t) end end) end
    end
    Players.PlayerAdded:Connect(function(t)
        t.CharacterAdded:Connect(function() chamsData[t]=nil; task.wait(.5); if chamsOn then applyChams(t) end end)
    end)
    Players.PlayerRemoving:Connect(removeChams)
    local t_ch = secW:Toggle("chams",false,function(v) chamsOn=v; refreshChams() end)
    secW:ColorPicker("chams color", chamsColor, function(c) chamsColor=c end)
    lib:CfgRegister("chams", function() return chamsOn end, function(v) t_ch.Set(v) end)

    -- ── fullbright ──
    secW:Divider("fullbright")
    local fbOn = false
    local fbOrig = {}
    local t_fb = secW:Toggle("fullbright", false, function(v)
        fbOn=v
        if v then
            fbOrig.amb = Lighting.Ambient; fbOrig.out = Lighting.OutdoorAmbient; fbOrig.br = Lighting.Brightness
            Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1); Lighting.Brightness=2
        else
            Lighting.Ambient        = fbOrig.amb or Color3.fromRGB(70,70,70)
            Lighting.OutdoorAmbient = fbOrig.out or Color3.fromRGB(70,70,70)
            Lighting.Brightness     = fbOrig.br  or 1
        end
    end)
    lib:CfgRegister("fullbright", function() return fbOn end, function(v) t_fb.Set(v) end)

    -- ── tracers ──
    secW:Divider("tracers")
    local tracersOn   = false
    local tracerData  = {}
    local tracerColor = Color3.fromRGB(120,80,255)
    local tracerGui   = Instance.new("ScreenGui")
    tracerGui.Name="ref_tracers"; tracerGui.IgnoreGuiInset=true
    tracerGui.ResetOnSpawn=false; tracerGui.DisplayOrder=998; tracerGui.Parent=pg
    local function removeTracer(t)
        if tracerData[t] then tracerData[t]:Destroy() tracerData[t]=nil end
    end
    RunService.RenderStepped:Connect(function()
        if not tracersOn then return end
        local cam=workspace.CurrentCamera; local vp=cam.ViewportSize
        for _,t in ipairs(Players:GetPlayers()) do
            if t==player then continue end
            local c=t.Character; local hrp=c and c:FindFirstChild("HumanoidRootPart")
            if not hrp then removeTracer(t); continue end
            local sp,onScreen=cam:WorldToScreenPoint(hrp.Position+Vector3.new(0,1.5,0))
            if not onScreen or sp.Z<0 then removeTracer(t); continue end
            if not tracerData[t] then
                local ln=Instance.new("Frame"); ln.BackgroundColor3=tracerColor
                ln.BorderSizePixel=0; ln.AnchorPoint=Vector2.new(0,0.5); ln.ZIndex=10; ln.Parent=tracerGui
                tracerData[t]=ln
            end
            local ln=tracerData[t]; ln.BackgroundColor3=tracerColor
            local ox=vp.X/2; local oy=vp.Y; local tx=sp.X; local ty=sp.Y
            local dx=tx-ox; local dy=ty-oy; local len=math.sqrt(dx*dx+dy*dy)
            ln.Position=UDim2.new(0,ox,0,oy); ln.Size=UDim2.new(0,len,0,2)
            ln.Rotation=math.deg(math.atan2(dy,dx))
        end
    end)
    local t_tr = secW:Toggle("tracers",false,function(v) tracersOn=v; if not v then for t in pairs(tracerData) do removeTracer(t) end end end)
    secW:ColorPicker("tracer color", tracerColor, function(c) tracerColor=c end)
    Players.PlayerRemoving:Connect(removeTracer)
    lib:CfgRegister("tracers", function() return tracersOn end, function(v) t_tr.Set(v) end)
end

-- ──────────────────────────────────────────────────────────────
-- TARGET
-- ──────────────────────────────────────────────────────────────
do
    local targetPlayer = nil
    local function setTarget(t)
        targetPlayer = t; _G.ref_lockTarget = t
    end

    -- ── search ──
    local secS = tab_target:Section("search")
    local card  = secS:AvatarCard()

    local function findPlayer(name)
        if not name or name=="" then return nil end
        local n=name:lower()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player then
                if p.Name:lower():find(n,1,true) or p.DisplayName:lower():find(n,1,true) then return p end
            end
        end
    end
    local function selectTarget(t)
        setTarget(t); card.Set(t)
        if t then
            notify("target selecionado", t.DisplayName.." (@"..t.Name..")", T.Good)
        else
            notify("target removido","nenhum target ativo", T.Sub)
        end
    end

    local nickInput = secS:TextInput("nick","username ou displayname",function(text,enter)
        if enter then selectTarget(findPlayer(text)) end
    end)

    local clickActive = false; local clickTool = nil
    local splitBtns = nil

    local function removeClickTool()
        clickActive=false
        if clickTool and clickTool.Parent then clickTool:Destroy() end
        clickTool=nil
        if splitBtns and splitBtns[2] then splitBtns[2].TextColor3=T.Sub end
    end
    local function equipClickTool()
        removeClickTool(); clickActive=true
        if splitBtns and splitBtns[2] then splitBtns[2].TextColor3=T.Accent end
        local tool=Instance.new("Tool"); tool.Name="ref_target_select"
        tool.CanBeDropped=false; tool.RequiresHandle=false
        tool.TextureId="rbxassetid://131165537896572"; tool.Parent=player.Backpack
        clickTool=tool
        tool.Activated:Connect(function()
            local mouse=player:GetMouse(); local hit=mouse.Target; if not hit then return end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=player and p.Character and hit:IsDescendantOf(p.Character) then
                    selectTarget(p); nickInput.Set(p.Name); return
                end
            end
        end)
        tool.AncestryChanged:Connect(function() if not tool.Parent then removeClickTool() end end)
    end

    splitBtns = secS:SplitButton({
        {text="search",     textColor=T.Text, callback=function() selectTarget(findPlayer(nickInput.Get())) end},
        {text="click tool", textColor=T.Sub,  callback=function() if clickActive then removeClickTool() else equipClickTool() end end},
        {text="clear",      textColor=T.Bad,  callback=function() selectTarget(nil); nickInput.Set("") end},
    })

    RunService.Heartbeat:Connect(function()
        if targetPlayer then card.UpdateHp(targetPlayer) end
    end)
    Players.PlayerRemoving:Connect(function(p) if p==targetPlayer then selectTarget(nil) end end)

    -- ── actions ──
    local secA = tab_target:Section("teleport")

    secA:Button("tp to target", function()
        if not targetPlayer then return end
        local hrp=getHRP(); local thrp=targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and thrp then hrp.CFrame=thrp.CFrame*CFrame.new(0,0,-3) end
    end)
    secA:Button("bring target", function()
        if not targetPlayer then return end
        local hrp=getHRP(); local thrp=targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and thrp then thrp.CFrame=hrp.CFrame*CFrame.new(3,0,0) end
    end)
    secA:Button("look at target", function()
        if not targetPlayer then return end
        local hrp=getHRP(); local thrp=targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and thrp then hrp.CFrame=CFrame.new(hrp.Position,thrp.Position) end
    end)

    -- ── follow ──
    local secMov = tab_target:Section("movement", true)
    local followOn   = false; local followConn = nil; local FOLLOW_SPD = 80
    local function stopFollow()
        followOn=false; if followConn then followConn:Disconnect() followConn=nil end
        local h=getHum(); if h then h.PlatformStand=false end
    end
    local function startFollow()
        stopFollow(); if not targetPlayer then return end
        followOn=true
        followConn=RunService.RenderStepped:Connect(function(dt)
            if not followOn then return end
            local hrp=getHRP(); local hm=getHum(); if not hrp or not hm then return end
            local tc=targetPlayer.Character; if not tc then return end
            local thrp=tc:FindFirstChild("HumanoidRootPart"); if not thrp then return end
            hm.PlatformStand=true
            local diff=thrp.Position-hrp.Position; local dist=diff.Magnitude
            if dist<=3 then return end
            local spd=math.min(FOLLOW_SPD,dist*6)*dt
            local np=hrp.Position+diff.Unit*spd
            local ld=Vector3.new(diff.X,0,diff.Z)
            hrp.CFrame=ld.Magnitude>.01 and CFrame.new(np,np+ld) or CFrame.new(np)
        end)
    end
    player.CharacterAdded:Connect(function() task.wait(.5); if followOn then startFollow() end end)
    secMov:Toggle("follow target",false,function(v) if v then startFollow() else stopFollow() end end)
    secMov:Slider("follow speed",30,300,80,5,function(v) FOLLOW_SPD=v end)

    -- ── orbit ──
    local orbitOn=false; local orbitConn=nil; local orbitAng=0; local orbitR=8; local orbitSpeed=1
    local function stopOrbit()
        orbitOn=false; if orbitConn then orbitConn:Disconnect() orbitConn=nil end
        local h=getHum(); if h then h.PlatformStand=false end
    end
    local function startOrbit()
        stopOrbit(); if not targetPlayer then return end; orbitOn=true
        local hum=getHum(); if hum then hum.PlatformStand=true end
        orbitConn=RunService.RenderStepped:Connect(function(dt)
            if not orbitOn then return end
            local hrp=getHRP(); if not hrp then return end
            local tc=targetPlayer.Character; if not tc then return end
            local thrp=tc:FindFirstChild("HumanoidRootPart"); if not thrp then return end
            local hm=getChar() and getChar():FindFirstChildOfClass("Humanoid")
            if hm then hm.PlatformStand=true end
            orbitAng=orbitAng+orbitSpeed*dt
            local center=thrp.Position+Vector3.new(0,1,0)
            local x=center.X+orbitR*math.cos(orbitAng); local z=center.Z+orbitR*math.sin(orbitAng)
            hrp.CFrame=CFrame.new(Vector3.new(x,center.Y,z),center)
        end)
    end
    secMov:Toggle("orbit target",false,function(v) if v then startOrbit() else stopOrbit() end end)
    secMov:Slider("orbit radius",2,30,8,1,function(v) orbitR=v end)
    secMov:Slider("orbit speed",0.2,5,1,0.1,function(v) orbitSpeed=v end)

    -- ── headsit ──
    local hsOn=false; local hsConn=nil; local hsAnim=nil
    local function stopHS()
        hsOn=false
        if hsConn then hsConn:Disconnect() hsConn=nil end
        if hsAnim then pcall(function() hsAnim:Stop(); hsAnim:Destroy() end) hsAnim=nil end
        local h=getHum(); if h then h.PlatformStand=false; h:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end
    local function startHS()
        stopHS(); if not targetPlayer or not targetPlayer.Character then return end
        local mc=getChar(); if not mc then return end
        local mh=mc:FindFirstChild("HumanoidRootPart"); local mhm=mc:FindFirstChildOfClass("Humanoid")
        if not mh or not mhm then return end
        hsOn=true; mhm.PlatformStand=true
        task.spawn(function()
            local hm=mc:FindFirstChildOfClass("Humanoid"); if not hm then return end
            local ok,anim=pcall(function()
                local a=Instance.new("Animation"); a.AnimationId="rbxassetid://2506281703"
                return hm:LoadAnimation(a)
            end)
            if ok and anim then hsAnim=anim; anim.Priority=Enum.AnimationPriority.Action; anim.Looped=true; anim:Play() end
        end)
        hsConn=RunService.RenderStepped:Connect(function()
            if not hsOn then return end
            local mc2=getChar(); if not mc2 then return end
            local mh2=mc2:FindFirstChild("HumanoidRootPart"); local mhm2=mc2:FindFirstChildOfClass("Humanoid")
            if not mh2 or not mhm2 then return end
            if not targetPlayer or not targetPlayer.Character then stopHS(); return end
            local thead=targetPlayer.Character:FindFirstChild("Head"); if not thead then stopHS(); return end
            mhm2.PlatformStand=true
            local hcf=thead.CFrame; local sp=hcf.Position+Vector3.new(0,2.2,0)
            local lk=hcf.LookVector; local fl=Vector3.new(lk.X,0,lk.Z)
            mh2.CFrame=fl.Magnitude>.01 and CFrame.lookAt(sp,sp+fl) or CFrame.new(sp)
            if hsAnim and not hsAnim.IsPlaying then hsAnim:Play() end
        end)
    end
    player.CharacterAdded:Connect(function() task.wait(.5); if hsOn then startHS() end end)
    secMov:Toggle("headsit",false,function(v) if v then startHS() else stopHS() end end)

    -- ── loop tp ──
    local ltpOn=false; local ltpConn=nil
    secMov:Toggle("loop teleport",false,function(v)
        ltpOn=v
        if ltpConn then ltpConn:Disconnect() ltpConn=nil end
        if not v then return end
        ltpConn=RunService.Heartbeat:Connect(function()
            if not ltpOn then return end
            local hrp=getHRP(); if not hrp then return end
            local tc=targetPlayer and targetPlayer.Character
            local thrp=tc and tc:FindFirstChild("HumanoidRootPart")
            if thrp then hrp.CFrame=thrp.CFrame*CFrame.new(0,0,-2) end
        end)
    end)

    -- ── spectate ──
    local secX = tab_target:Section("extras", true)
    local specOn=false; local specConn=nil
    local function stopSpec()
        specOn=false; if specConn then specConn:Disconnect() specConn=nil end
        workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
    end
    secX:Toggle("spectate target",false,function(v)
        if not v then stopSpec(); return end
        if not targetPlayer then return end
        specOn=true; workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
        specConn=RunService.RenderStepped:Connect(function()
            if not specOn then return end
            local tc=targetPlayer and targetPlayer.Character; if not tc then return end
            local thrp=tc:FindFirstChild("HumanoidRootPart"); if not thrp then return end
            local lk=Vector3.new(thrp.CFrame.LookVector.X,0,thrp.CFrame.LookVector.Z).Unit
            local cp=thrp.Position-lk*12+Vector3.new(0,4,0)
            local tp=thrp.Position+Vector3.new(0,1.5,0)
            workspace.CurrentCamera.CFrame=workspace.CurrentCamera.CFrame:Lerp(CFrame.new(cp,tp),0.15)
        end)
    end)

    -- ── fling ──
    local secFl = tab_target:Section("fling", true)
    secFl:Divider("settings")
    local flingPow  = 5e5; local flingRad = 50
    local flingOn   = false; local flingConn = nil
    secFl:Slider("fling power",1e4,2e6,5e5,1e4,function(v) flingPow=v end)
    secFl:Slider("radius (loop all)",5,500,50,5,function(v) flingRad=v end)
    secFl:Divider("actions")

    local function cleanFling()
        if flingConn then flingConn:Disconnect() flingConn=nil end
        local hrp=getHRP()
        if hrp then
            for _,cls in ipairs({"BodyThrust","BodyAngularVelocity","BodyVelocity"}) do
                local o=hrp:FindFirstChildOfClass(cls); if o then o:Destroy() end
            end
            hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
        end
        flingOn=false
    end
    local function doFling(target)
        cleanFling()
        if not target or not target.Character then return end
        local thrp=target.Character:FindFirstChild("HumanoidRootPart"); if not thrp then return end
        local hrp=getHRP(); if not hrp then return end
        flingOn=true; local saved=hrp.CFrame
        local bt=Instance.new("BodyThrust"); bt.Force=Vector3.new(flingPow,flingPow,flingPow)
        bt.Location=hrp.Position; bt.Parent=hrp
        local bav=Instance.new("BodyAngularVelocity"); bav.MaxTorque=Vector3.new(0,4e8,0)
        bav.AngularVelocity=Vector3.new(0,2e4,0); bav.P=4e8; bav.Parent=hrp
        hrp.CFrame=thrp.CFrame*CFrame.new(0,.5,0)
        local fr=0
        flingConn=RunService.Heartbeat:Connect(function()
            fr+=1
            if fr<=3 then if thrp.Parent then hrp.CFrame=thrp.CFrame*CFrame.new(0,.5,0) end return end
            if bt.Parent then bt:Destroy() end; if bav.Parent then bav:Destroy() end
            if flingConn then flingConn:Disconnect() flingConn=nil end
            if hrp.Parent then hrp.CFrame=saved; hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero end
            flingOn=false
        end)
    end
    secFl:Button("fling target",function() if targetPlayer then doFling(targetPlayer) end end)

    local flLoopTarget=false; local flLoopConn=nil
    secFl:Toggle("fling loop (target)",false,function(v)
        flLoopTarget=v
        if flLoopConn then flLoopConn:Disconnect() flLoopConn=nil end
        if not v then return end
        flLoopConn=RunService.Heartbeat:Connect(function()
            if not flLoopTarget or not targetPlayer or flingOn then return end
            doFling(targetPlayer)
        end)
    end)

    local flLoopAll=false; local flLoopAllConn=nil
    secFl:Toggle("fling loop (all in radius)",false,function(v)
        flLoopAll=v
        if flLoopAllConn then flLoopAllConn:Disconnect() flLoopAllConn=nil end
        if not v then return end
        flLoopAllConn=RunService.Heartbeat:Connect(function()
            if not flLoopAll or flingOn then return end
            local hrp=getHRP(); if not hrp then return end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=player and p.Character then
                    local ph=p.Character:FindFirstChild("HumanoidRootPart")
                    if ph and (ph.Position-hrp.Position).Magnitude<=flingRad then doFling(p); break end
                end
            end
        end)
    end)
end

-- ──────────────────────────────────────────────────────────────
-- CONFIG TAB
-- ──────────────────────────────────────────────────────────────
lib:BuildConfigTab(tab_cfg, "ref_ui_v2_cfg")

-- ──────────────────────────────────────────────────────────────
-- TOAST DE BOAS-VINDAS
-- ──────────────────────────────────────────────────────────────
task.delay(0.8, function()
    lib:Toast(lib._icon, "ref universal v2", "carregado — RightShift p/ toggle", T.Accent)
end)
