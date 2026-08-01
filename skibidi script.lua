-- ================================================================================
-- IVY HUB V2 - COMPLETE AUDIO VISUALIZER BEAT EDITION
-- Features: Smooth Ambient Beat Engine, Grounded Top-Dock Navigation,
--           Collidable Crozo Engine, Dynamic Target Sticking, Complete QB Engine,
--           Tackle Reach Hooks, Movement Overrides, Hider Engine & Config Manager
-- ================================================================================

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local CONFIG_FOLDER = "IvyHub_Configs"
local AUTOLOAD_FILE = CONFIG_FOLDER .. "/autoload.txt"

-- Safe Storage Engine
local function EnsureFolder()
    if makefolder and isfolder and not isfolder(CONFIG_FOLDER) then
        pcall(function() makefolder(CONFIG_FOLDER) end)
    end
end
EnsureFolder()

-- Safe Parent Detection
local function GetSafeParent()
    if gethui then
        local success, hui = pcall(gethui)
        if success and hui then return hui end
    end
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui then return coreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ================================================================================
-- MASTER CONFIGURATION TABLE
-- ================================================================================
_G.HubConfig = _G.HubConfig or {
    QBAim = {
        Enabled = false,
        TeamFilter = true,
        ShowArc = true,
        SafeArc = true,
        TargetHighlight = true,
        LeadDelay = 0.38,
        PeakHeight = 14.00,
        QBDrift = 0.00,
        LockKeybind = Enum.KeyCode.H,
        ThrowKeybind = Enum.KeyCode.T,
        ToggleKeybind = Enum.KeyCode.P
    },
    NoOOB = { Enabled = false, Keybind = Enum.KeyCode.Unknown },
    uwuMagnets = { Enabled = false, Power = 55, Range = 25, Keybind = Enum.KeyCode.F },
    BTP = { Enabled = false, MaxDist = 35, CatchArm = "RightHand", Keybind = Enum.KeyCode.E },
    Sticky = { Enabled = false, Range = 10, Smoothness = 12, Strength = 12, Keybind = Enum.KeyCode.Unknown },
    LegitPV = { Enabled = false, PullVec = 0.01, MaxDist = 25, Keybind = Enum.KeyCode.Unknown },
    TackleReach = { Enabled = false, SizeX = 2.52, SizeY = 5.4, SizeZ = 1.41, Transparency = 0.7, Keybind = Enum.KeyCode.Unknown },
    HeadHitbox = { Enabled = false, HeadSize = 3.0, Transparency = 0.5, Keybind = Enum.KeyCode.Unknown },
    Speed = { Enabled = false, SpeedVal = 22.2, Keybind = Enum.KeyCode.Unknown },
    Gravity = { Enabled = false, GravityVal = 178.4, Keybind = Enum.KeyCode.Unknown },
    JP = { Enabled = false, JumpPower = 50, Cooldown = 1.15, Keybind = Enum.KeyCode.Unknown },
    AutoStick = { Enabled = false, ActivateDist = 1.9, LockInDist = 5, MaxStrength = 55, OffsetY = 2.8, BalanceRadius = 3.75, VertMin = -4, VertMax = 4, CorrSpeed = 0.55, Keybind = Enum.KeyCode.Unknown },
    TapBumper = { Enabled = false, Force = 5000, Keybind = Enum.KeyCode.N },
    AutoRocket = { Enabled = false, HeadOnly = false, Power = 45, Keybind = Enum.KeyCode.Unknown },
    Fling = { Enabled = false, Power = 1000, Keybind = Enum.KeyCode.X },
    RedSky = { Enabled = false, Brightness = 2, Keybind = Enum.KeyCode.Unknown },
    PotatoGraphics = { Enabled = false, Keybind = Enum.KeyCode.Unknown },
    Misc = { Keybind = Enum.KeyCode.RightShift, Hider = false, HiderKeybind = Enum.KeyCode.Unknown }
}

-- Config Serialization Engine
local function SerializeConfig(cfg)
    local copy = {}
    for cat, data in pairs(cfg) do
        copy[cat] = {}
        for k, v in pairs(data) do
            if typeof(v) == "EnumItem" then
                copy[cat][k] = "Enum.KeyCode." .. v.Name
            else
                copy[cat][k] = v
            end
        end
    end
    return HttpService:JSONEncode(copy)
end

local function DeserializeConfig(jsonStr)
    local decoded = HttpService:JSONDecode(jsonStr)
    for cat, data in pairs(decoded) do
        if _G.HubConfig[cat] then
            for k, v in pairs(data) do
                if type(v) == "string" and v:sub(1, 13) == "Enum.KeyCode." then
                    _G.HubConfig[cat][k] = Enum.KeyCode[v:sub(14)] or Enum.KeyCode.Unknown
                else
                    _G.HubConfig[cat][k] = v
                end
            end
        end
    end
end

-- Destroy Old GUI Instance
local targetParent = GetSafeParent()
local oldGui = targetParent:FindFirstChild("IVY_HUB_INTERFACE")
if oldGui then oldGui:Destroy() end

-- Helper Character Getters
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hrp, hum
end

local function findFootballPart()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("ball") or name:find("football") or name:find("handle") then
                return obj
            end
        end
    end
    return nil
end

local function isPlayerDiving(hum)
    if not hum then return false end
    local active = false
    pcall(function()
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local name = tostring(track.Name):lower()
            local anim = track.Animation
            local animId = anim and tostring(anim.AnimationId):lower() or ""
            if name:find("dive") or name:find("layout") or animId:find("dive") or animId:find("layout") then
                active = true
                return
            end
        end
    end)
    return active
end

local function triggerFlingBoost()
    if not _G.HubConfig.Fling.Enabled then return end
    local char, hrp, hum = getChar()
    if hrp and hum then
        local pwr = tonumber(_G.HubConfig.Fling.Power) or 1000
        local moveDir = hum.MoveDirection.Magnitude > 0 and hum.MoveDirection or hrp.CFrame.LookVector
        local flingBV = Instance.new("BodyVelocity")
        flingBV.Name = "IvyHub_FlingRocket"
        flingBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flingBV.Velocity = moveDir * pwr + Vector3.new(0, pwr * 0.3, 0)
        flingBV.Parent = hrp
        task.delay(0.25, function()
            if flingBV and flingBV.Parent then flingBV:Destroy() end
        end)
    end
end

local function triggerTapBumperImpulse()
    if not _G.HubConfig.TapBumper.Enabled then return end
    local char, hrp = getChar()
    if hrp then
        local forceVal = tonumber(_G.HubConfig.TapBumper.Force) or 5000
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(hrp.AssemblyLinearVelocity.X, forceVal, hrp.AssemblyLinearVelocity.Z)
        bv.Parent = hrp
        task.delay(0.1, function()
            if bv and bv.Parent then bv:Destroy() end
        end)
    end
end

-- ================================================================================
-- QB AB MATH MODULE
-- ================================================================================
local QBAimMathModule = {}
do
    local ballGravity = 28
    local gravityVector = Vector3.new(0, -ballGravity, 0)
    local defaultBallSpeed = 95

    local function flat(v) return Vector3.new(v.X, 0, v.Z) end
    local function clampMagnitude(v, maxMag) return (v and v.Magnitude > maxMag and maxMag > 0) and (v.Unit * maxMag) or (v or Vector3.zero) end
    local function ballAt(orig, vel, t) return orig + vel * t + 0.5 * gravityVector * t * t end
    local function landing(orig, vel)
        local disc = vel.Y * vel.Y + 2 * ballGravity * orig.Y
        if disc < 0 then return nil, nil end
        local t = (vel.Y + math.sqrt(disc)) / ballGravity
        return t > 0 and ballAt(orig, vel, t) or nil, t
    end

    local function targetAtTime(params, receiverStart, wrVel, t)
        local delay = math.max(params.leadDelay or 0, 0)
        local target = receiverStart + flat(wrVel) * (t + delay)
        local catchY = (params.catchY or receiverStart.Y) + (params.solveYBias or 0)
        return Vector3.new(target.X, catchY, target.Z), delay
    end

    local function interceptValue(params, orig, receiverStart, wrVel, qbVel, speed, t)
        local inherited = flat(qbVel or Vector3.zero) * (params.qbInheritance or 0)
        local target = targetAtTime(params, receiverStart, wrVel, t)
        local displacement = target - orig - inherited * t - 0.5 * gravityVector * t * t
        return displacement:Dot(displacement) - speed * speed * t * t
    end

    function QBAimMathModule.solve(params)
        local speed = params.ballPower or defaultBallSpeed
        local wrVel = clampMagnitude(flat(params.targetVelocity or Vector3.zero), params.maxRunSpeed or 21)
        local qbVel = clampMagnitude(flat(params.qbVelocity or Vector3.zero), params.maxRunSpeed or 21)
        local orig = params.originPosition
        local receiverPos = params.receiverAnchorPosition or params.receiverPosition
        if not orig or not receiverPos then return nil end

        local receiverStart = Vector3.new(receiverPos.X, params.catchY or receiverPos.Y, receiverPos.Z)
        local minT, maxT, dt = params.minTime or 0.35, params.maxTime or 6, params.dt or 0.01
        local bestRoot, bestNear = nil, nil

        for t = minT, maxT, dt do
            local val = interceptValue(params, orig, receiverStart, wrVel, qbVel, speed, t)
            local target, delay = targetAtTime(params, receiverStart, wrVel, t)
            local displacement = target - orig - flat(qbVel) * (params.qbInheritance or 0) * t - 0.5 * gravityVector * t * t
            local reqVel = displacement / t
            local reqSpeed = reqVel.Magnitude

            if reqSpeed > 1e-6 then
                local dir = reqVel.Unit
                local angle = math.deg(math.asin(math.clamp(dir.Y, -1, 1)))
                if angle >= (params.minAngle or -5) and angle <= (params.maxAngle or 55) then
                    local throwVel = dir * speed
                    local catchPos = ballAt(orig, throwVel, t)
                    local miss = (catchPos - target).Magnitude
                    local candidate = {
                        time = t, origin = orig, target = target, c1Point = target,
                        velocity = throwVel, speed = speed, aimPoint = orig + dir * (params.aimScale or 1000),
                        angleDeg = angle, targetMiss = miss, yError = math.abs(catchPos.Y - target.Y),
                        landing = landing(orig, throwVel)
                    }
                    if miss <= (params.nearTargetMissTolerance or 0.05) and (not bestNear or miss < bestNear.targetMiss) then
                        bestNear = candidate
                    elseif miss <= (params.targetMissTolerance or 0.35) and (not bestRoot or miss < bestRoot.targetMiss) then
                        bestRoot = candidate
                    end
                end
            end
        end
        return bestRoot or bestNear
    end
end

-- ================================================================================
-- HIDER LOGIC ENGINE
-- ================================================================================
local hiderConnection = nil
local function runHiderLogic()
    local hui = gethui and gethui() or game:GetService("CoreGui")
    if hui then
        for _, v in ipairs(hui:GetDescendants()) do
            if v:IsA("ScreenGui") and v.Name ~= "IVY_HUB_INTERFACE" then
                pcall(function() v:Destroy() end)
            end
        end
        if hiderConnection then hiderConnection:Disconnect() end
        hiderConnection = hui.ChildAdded:Connect(function(c)
            task.wait()
            if c:IsA("ScreenGui") and c.Name ~= "IVY_HUB_INTERFACE" then
                pcall(function() c:Destroy() end)
            end
        end)
    end
end

-- ================================================================================
-- BACKEND MODULE LOOPS
-- ================================================================================

-- 1. LEGIT PV
local pvHeld = false
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    local isM1 = inp.UserInputType == Enum.UserInputType.MouseButton1
    local isR2 = inp.UserInputType == Enum.UserInputType.Gamepad1 and inp.KeyCode == Enum.KeyCode.ButtonR2
    if isM1 or isR2 or inp.KeyCode == _G.HubConfig.LegitPV.Keybind then pvHeld = true end
end)
UserInputService.InputEnded:Connect(function(inp, gpe)
    local isM1 = inp.UserInputType == Enum.UserInputType.MouseButton1
    local isR2 = inp.UserInputType == Enum.UserInputType.Gamepad1 and inp.KeyCode == Enum.KeyCode.ButtonR2
    if isM1 or isR2 or inp.KeyCode == _G.HubConfig.LegitPV.Keybind then pvHeld = false end
end)
RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.LegitPV.Enabled or not pvHeld then return end
    local char, hrp = getChar()
    if not char or not hrp then return end
    local ball = findFootballPart()
    if ball and (hrp.Position - ball.Position).Magnitude <= (tonumber(_G.HubConfig.LegitPV.MaxDist) or 25) then
        local pVec = tonumber(_G.HubConfig.LegitPV.PullVec) or 0.01
        hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, ball.Position), pVec)
    end
end)

-- 2. STICKY HEAD (DYNAMIC EXPANDED HITBOX SWITCHING)
local stickyHeld = false
local function getStickyTargetPos(maxDist)
    local char, hrp = getChar()
    if not hrp then return nil end
    local bestPos, bestDist = nil, maxDist or 9999
    local useHitbox = _G.HubConfig.HeadHitbox.Enabled

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eHrp = p.Character:FindFirstChild("HumanoidRootPart")
            local eHead = p.Character:FindFirstChild("Head")
            if eHrp and eHead then
                local d = (hrp.Position - eHrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    if useHitbox then
                        bestPos = eHrp.Position + Vector3.new(0, (eHrp.Size.Y / 2) + 2.5, 0)
                    else
                        bestPos = eHead.Position + Vector3.new(0, 2.5, 0)
                    end
                end
            end
        end
    end
    return bestPos
end

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.ButtonL1 or inp.KeyCode == _G.HubConfig.Sticky.Keybind then stickyHeld = true end
end)
UserInputService.InputEnded:Connect(function(inp, gpe)
    if inp.KeyCode == Enum.KeyCode.ButtonL1 or inp.KeyCode == _G.HubConfig.Sticky.Keybind then stickyHeld = false end
end)
RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.Sticky.Enabled or not stickyHeld then return end
    local char, hrp = getChar()
    if not char or not hrp then return end
    local targetPos = getStickyTargetPos(tonumber(_G.HubConfig.Sticky.Range) or 10)
    if targetPos then
        local smoothVal = math.clamp((tonumber(_G.HubConfig.Sticky.Smoothness) or 12) / 100, 0.01, 1)
        hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos), smoothVal)
    end
end)

-- 3. AUTO STICK ENGINE (DYNAMIC EXPANDED HITBOX SWITCHING)
local nudgeActive = false
RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.AutoStick.Enabled then return end
    local char, hrp, hum = getChar()
    if not char or not hrp or not hum then return end

    local function isTargetRising(targetHrp)
        return targetHrp and targetHrp.AssemblyLinearVelocity.Y > 0.5
    end

    local function isLocalPlayerRising()
        return hrp.AssemblyLinearVelocity.Y > 0.5
    end

    local function findClosestAutoStickTarget()
        local closestChar, closestPos, shortestDist = nil, nil, math.huge
        local balRad = tonumber(_G.HubConfig.AutoStick.BalanceRadius) or 3.75
        local useHitbox = _G.HubConfig.HeadHitbox.Enabled

        for _, op in pairs(Players:GetPlayers()) do
            if op ~= LocalPlayer and op.Character then
                local eHrp = op.Character:FindFirstChild("HumanoidRootPart")
                local eHead = op.Character:FindFirstChild("Head")
                if eHrp and eHead then
                    local basePos = useHitbox and (eHrp.Position + Vector3.new(0, eHrp.Size.Y / 2, 0)) or eHead.Position
                    local dist = (basePos - hrp.Position).Magnitude
                    if dist < balRad and dist < shortestDist then
                        shortestDist = dist
                        closestChar = op.Character
                        closestPos = basePos
                    end
                end
            end
        end
        return closestChar, closestPos
    end

    local targetChar, targetPos = findClosestAutoStickTarget()
    local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    local targetRising = isTargetRising(targetHrp)
    local selfRising = isLocalPlayerRising()
    local bothRising = targetRising and selfRising
    local state = hum:GetState()
    local inAir = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping)

    if inAir and bothRising and targetPos then
        local actDist = tonumber(_G.HubConfig.AutoStick.ActivateDist) or 1.9
        if (hrp.Position - targetPos).Magnitude < actDist then
            local lockDist = tonumber(_G.HubConfig.AutoStick.LockInDist) or 5
            local dist = (hrp.Position - targetPos).Magnitude
            local lerpIntensity = (dist < lockDist) and 0.35 or 0.08
            local wagerOffsetY = tonumber(_G.HubConfig.AutoStick.OffsetY) or 2.8
            local goalPos = targetPos + Vector3.new(0, wagerOffsetY, 0)
            local direction = (goalPos - hrp.Position).Unit
            local maxStr = tonumber(_G.HubConfig.AutoStick.MaxStrength) or 55
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(direction * maxStr, lerpIntensity)
            local lookGoal = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
            hrp.CFrame = hrp.CFrame:Lerp(lookGoal, 0.15)
        end
    end

    if nudgeActive then
        if not targetRising and not selfRising then
            if (hum.MoveDirection.Magnitude > 0) or isPlayerDiving(hum) then nudgeActive = false end
        end
        if targetPos and bothRising then
            local corrSpd = tonumber(_G.HubConfig.AutoStick.CorrSpeed) or 0.55
            local goalPoint = Vector3.new(targetPos.X + (math.random() - 0.5) * 0.15, hrp.Position.Y, targetPos.Z + (math.random() - 0.5) * 0.15)
            local newPos = hrp.Position:Lerp(goalPoint, corrSpd)
            hrp.CFrame = CFrame.new(newPos, newPos + hrp.CFrame.LookVector)
        end
    elseif targetPos and bothRising then
        local verticalDiff = hrp.Position.Y - targetPos.Y
        local vMin = tonumber(_G.HubConfig.AutoStick.VertMin) or -4
        local vMax = tonumber(_G.HubConfig.AutoStick.VertMax) or 4
        if verticalDiff > vMin and verticalDiff < vMax then
            local wagerOffsetY = tonumber(_G.HubConfig.AutoStick.OffsetY) or 2.8
            local corrSpd = tonumber(_G.HubConfig.AutoStick.CorrSpeed) or 0.55
            local goalPoint = Vector3.new(targetPos.X + (math.random() - 0.5) * 0.15, targetPos.Y + wagerOffsetY, targetPos.Z + (math.random() - 0.5) * 0.15)
            local newPos = hrp.Position:Lerp(goalPoint, corrSpd)
            hrp.CFrame = CFrame.new(newPos, newPos + hrp.CFrame.LookVector)
            if Vector3.new(hrp.Position.X - targetPos.X, 0, hrp.Position.Z - targetPos.Z).Magnitude < 0.5 then
                nudgeActive = true
            end
        else
            nudgeActive = false
        end
    else
        nudgeActive = false
    end
end)

-- 4. AUTO ROCKET
local currentDiveTime = 0
local lastIsDiving = false
RunService.Heartbeat:Connect(function(dt)
    if not _G.HubConfig.AutoRocket.Enabled then return end
    local char, hrp, hum = getChar()
    if not char or not hrp or not hum then return end
    local diving = isPlayerDiving(hum)
    if diving then
        if not lastIsDiving then currentDiveTime = 0 else currentDiveTime = currentDiveTime + dt end
        if currentDiveTime <= 0.4 then
            local moveDir = hum.MoveDirection.Magnitude > 0 and hum.MoveDirection or hrp.CFrame.LookVector
            local rocketBV = hrp:FindFirstChild("IvyHub_AutoRocket") or Instance.new("BodyVelocity")
            rocketBV.Name = "IvyHub_AutoRocket"
            rocketBV.MaxForce = Vector3.new(math.huge, 0, math.huge)
            rocketBV.Velocity = moveDir * (tonumber(_G.HubConfig.AutoRocket.Power) or 45)
            rocketBV.Parent = hrp
        else
            local rocketBV = hrp:FindFirstChild("IvyHub_AutoRocket")
            if rocketBV then rocketBV:Destroy() end
        end
    else
        currentDiveTime = 0
        local rocketBV = hrp:FindFirstChild("IvyHub_AutoRocket")
        if rocketBV then rocketBV:Destroy() end
    end
    lastIsDiving = diving
end)

-- 5. UWU MAGNETS & BALL TP
RunService.Heartbeat:Connect(function()
    local char, hrp = getChar()
    if not char or not hrp then return end
    if _G.HubConfig.uwuMagnets.Enabled then
        local ball = findFootballPart()
        if ball and (hrp.Position - ball.Position).Magnitude <= (tonumber(_G.HubConfig.uwuMagnets.Range) or 25) then
            ball.AssemblyLinearVelocity = (hrp.Position - ball.Position).Unit * (tonumber(_G.HubConfig.uwuMagnets.Power) or 55)
        end
    end
    if _G.HubConfig.BTP.Enabled then
        local ball = findFootballPart()
        if ball then
            local catchArm = char:FindFirstChild(_G.HubConfig.BTP.CatchArm) or hrp
            if (catchArm.Position - ball.Position).Magnitude <= (tonumber(_G.HubConfig.BTP.MaxDist) or 35) then
                ball.CFrame = catchArm.CFrame
                ball.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end)

-- 6. TACKLE REACH ENGINE
local reachWatchers = setmetatable({}, {__mode = "k"})
local reachOriginalParts = { Transparency = setmetatable({}, {__mode = "k"}), Size = setmetatable({}, {__mode = "k"}) }
local function getTargetReachSize()
    return Vector3.new(tonumber(_G.HubConfig.TackleReach.SizeX) or 2.52, tonumber(_G.HubConfig.TackleReach.SizeY) or 5.4, tonumber(_G.HubConfig.TackleReach.SizeZ) or 1.41)
end
local function applyReachVisuals(w, on)
    if not w then return end
    local targetSize = getTargetReachSize()
    local targetTrans = tonumber(_G.HubConfig.TackleReach.Transparency) or 0.7
    for i = #w.parts, 1, -1 do
        local part = w.parts[i]
        if part and part.Parent and part:IsA("BasePart") then
            if on then
                if part.Transparency ~= targetTrans then part.Transparency = targetTrans end
                if part.Size ~= targetSize then part.Size = targetSize end
            else
                if w.origT[part] and part.Transparency ~= w.origT[part] then part.Transparency = w.origT[part] end
                if w.origS[part] and part.Size ~= w.origS[part] then part.Size = w.origS[part] end
            end
        end
    end
end
local function trackReachPart(w, part)
    if not part:IsA("BasePart") then return end
    if not table.find(w.parts, part) then table.insert(w.parts, part) end
    if reachOriginalParts.Transparency[part] == nil then reachOriginalParts.Transparency[part] = part.Transparency end
    if reachOriginalParts.Size[part] == nil then reachOriginalParts.Size[part] = part.Size end
    w.origT[part] = reachOriginalParts.Transparency[part]
    w.origS[part] = reachOriginalParts.Size[part]
    if _G.HubConfig.TackleReach.Enabled then
        part.Transparency = tonumber(_G.HubConfig.TackleReach.Transparency) or 0.7
        part.Size = getTargetReachSize()
    end
end
local function attachReachNode(node)
    if not node then return end
    local w = reachWatchers[node] or { cons = {}, parts = {}, origT = setmetatable({}, {__mode = "k"}), origS = setmetatable({}, {__mode = "k"}), attached = false }
    reachWatchers[node] = w
    if w.attached then applyReachVisuals(w, _G.HubConfig.TackleReach.Enabled) return end
    w.attached = true
    for _, desc in ipairs(node:GetDescendants()) do if desc:IsA("BasePart") then trackReachPart(w, desc) end end
    if node:IsA("BasePart") then trackReachPart(w, node) end
    applyReachVisuals(w, _G.HubConfig.TackleReach.Enabled)
end
local function scanReachWorkspace()
    local games = Workspace:FindFirstChild("Games") or Workspace:FindFirstChild("MiniGames")
    if games then for _, gFolder in ipairs(games:GetChildren()) do attachReachNode(gFolder) end end
end
task.spawn(function() task.wait(0.5) scanReachWorkspace() end)
RunService.Heartbeat:Connect(function() for _, w in pairs(reachWatchers) do applyReachVisuals(w, _G.HubConfig.TackleReach.Enabled) end end)

-- 7. QB AB TRACKING
local qbTargetPlayer = nil
local function getBestQBTarget()
    local char, hrp = getChar()
    if not hrp then return nil end
    local camera = Workspace.CurrentCamera
    local mouse = LocalPlayer:GetMouse()
    local bestPlayer, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eHrp = p.Character:FindFirstChild("HumanoidRootPart")
            if eHrp and camera then
                local sPos, onScreen = camera:WorldToViewportPoint(eHrp.Position)
                if onScreen then
                    local d = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(sPos.X, sPos.Y)).Magnitude
                    if d < bestDist then bestDist = d bestPlayer = p end
                end
            end
        end
    end
    return bestPlayer
end

local function executeQBThrow()
    if not _G.HubConfig.QBAim.Enabled or not qbTargetPlayer or not qbTargetPlayer.Character then return end
    local char, hrp = getChar()
    local eHrp = qbTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local ball = findFootballPart()
    if not hrp or not eHrp or not ball then return end

    local plan = QBAimMathModule.solve({
        originPosition = ball.Position, receiverPosition = eHrp.Position,
        targetVelocity = eHrp.AssemblyLinearVelocity, qbVelocity = hrp.AssemblyLinearVelocity,
        ballPower = 95, leadDelay = tonumber(_G.HubConfig.QBAim.LeadDelay) or 0.38,
        catchY = eHrp.Position.Y + (tonumber(_G.HubConfig.QBAim.PeakHeight) or 14.00)
    })

    if plan and plan.aimPoint then
        pcall(function()
            for _, folder in ipairs({Workspace:FindFirstChild("Games"), ReplicatedStorage:FindFirstChild("Games")}) do
                if folder then
                    for _, gameInst in ipairs(folder:GetChildren()) do
                        local re = gameInst:FindFirstChild("ReEvent") or (gameInst:FindFirstChild("Replicated") and gameInst.Replicated:FindFirstChild("ReEvent"))
                        if re then re:FireServer("Mechanics", "ThrowBall", { Target = plan.aimPoint, AutoThrow = false, Power = 100 }) break end
                    end
                end
            end
        end)
    end
end

-- 8. NO OOB
RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.NoOOB or not _G.HubConfig.NoOOB.Enabled then return end
    local ball = findFootballPart()
    local char, hrp = getChar()
    if not char or not hrp or not ball then return end
    if (ball.Position - hrp.Position).Magnitude > 10 and not ball:IsDescendantOf(char) then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("oob") or name:find("outofbounds") or name:find("sideline") then obj.CanTouch = false end
        end
    end
end)

-- 9. CROZO HITBOX ENGINE (COLLIDABLE HUMANOIDROOTPART OVERRIDE)
local originalHitboxProperties = {}
RunService.RenderStepped:Connect(function()
    if _G.HubConfig.HeadHitbox.Enabled then
        local szVal = tonumber(_G.HubConfig.HeadHitbox.HeadSize) or 3.0
        local transVal = tonumber(_G.HubConfig.HeadHitbox.Transparency) or 0.5
        local targetSize = Vector3.new(szVal, szVal, szVal)

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local eHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if eHrp then
                    if not originalHitboxProperties[eHrp] then
                        originalHitboxProperties[eHrp] = { Size = eHrp.Size, Transparency = eHrp.Transparency, CanCollide = eHrp.CanCollide }
                    end
                    if eHrp.Size ~= targetSize then eHrp.Size = targetSize end
                    if eHrp.Transparency ~= transVal then eHrp.Transparency = transVal end
                    if eHrp.CanCollide ~= true then eHrp.CanCollide = true end
                end
            end
        end
    else
        if next(originalHitboxProperties) then
            for hrp, props in pairs(originalHitboxProperties) do
                if hrp and hrp.Parent then
                    pcall(function() hrp.Size = props.Size hrp.Transparency = props.Transparency hrp.CanCollide = props.CanCollide end)
                end
            end
            table.clear(originalHitboxProperties)
        end
    end
end)

-- 10. VISUALS & ENVIRONMENT
task.spawn(function()
    while task.wait(1) do
        if _G.HubConfig.RedSky.Enabled then
            Lighting.Brightness = tonumber(_G.HubConfig.RedSky.Brightness) or 2
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 30, 30)
            local currentSky = Lighting:FindFirstChildOfClass("Sky")
            if not currentSky or currentSky.Name ~= "IvyRedSky" then
                if currentSky then currentSky:Destroy() end
                local redSkyObj = Instance.new("Sky")
                redSkyObj.Name = "IvyRedSky"
                redSkyObj.SkyboxBk = "rbxassetid://252765961"
                redSkyObj.SkyboxDn = "rbxassetid://252763782"
                redSkyObj.SkyboxFt = "rbxassetid://252763580"
                redSkyObj.SkyboxLf = "rbxassetid://252763467"
                redSkyObj.SkyboxRt = "rbxassetid://252763325"
                redSkyObj.SkyboxUp = "rbxassetid://252763962"
                redSkyObj.Parent = Lighting
            end
        end
        if _G.HubConfig.PotatoGraphics.Enabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then obj.Material = Enum.Material.SmoothPlastic
                elseif obj:IsA("Decal") or obj:IsA("Texture") then obj:Destroy() end
            end
        end
    end
end)

-- 11. MOVEMENT & PHYSICS
local lastJumpTime = 0
UserInputService.JumpRequest:Connect(function()
    if not _G.HubConfig.JP.Enabled then return end
    local char, hrp, hum = getChar()
    if not char or not hrp or not hum then return end
    if tick() - lastJumpTime >= (tonumber(_G.HubConfig.JP.Cooldown) or 1.15) then
        lastJumpTime = tick()
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, tonumber(_G.HubConfig.JP.JumpPower) or 50, hrp.AssemblyLinearVelocity.Z)
    end
end)
RunService.Heartbeat:Connect(function()
    local char, hrp, hum = getChar()
    if not char or not hum then return end
    if _G.HubConfig.Speed.Enabled then hum.WalkSpeed = tonumber(_G.HubConfig.Speed.SpeedVal) or 22.2 end
    if _G.HubConfig.Gravity.Enabled then Workspace.Gravity = tonumber(_G.HubConfig.Gravity.GravityVal) or 178.4 end
end)

-- ================================================================================
-- IVY HUB COMPACT AUDIO VISUALIZER BEAT GUI FRAMEWORK
-- ================================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IVY_HUB_INTERFACE"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local THEME = {
    GlassBg = Color3.fromRGB(10, 16, 13),
    HeaderBg = Color3.fromRGB(14, 24, 18),
    DockBg = Color3.fromRGB(12, 20, 15),
    CardBg = Color3.fromRGB(16, 30, 22),
    AccentGlow = Color3.fromRGB(50, 230, 120),
    MintGlow = Color3.fromRGB(110, 255, 170),
    DarkVine = Color3.fromRGB(22, 65, 38),
    TextMain = Color3.fromRGB(240, 255, 245),
    TextSub = Color3.fromRGB(130, 180, 150),
    InputBg = Color3.fromRGB(12, 22, 17)
}

-- Compact Main Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 365, 0, 250)
MainFrame.Position = UDim2.new(0.5, -182, 0.5, -125)
MainFrame.BackgroundColor3 = THEME.GlassBg
MainFrame.BackgroundTransparency = 0.1
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Animated Spore Background
local ParticleCanvas = Instance.new("Frame", MainFrame)
ParticleCanvas.Name = "ParticleCanvas"
ParticleCanvas.Size = UDim2.new(1, 0, 1, 0)
ParticleCanvas.BackgroundTransparency = 1
ParticleCanvas.ClipsDescendants = true
ParticleCanvas.ZIndex = 0
Instance.new("UICorner", ParticleCanvas).CornerRadius = UDim.new(0, 12)

local function SpawnBioSpores()
    local Spore = Instance.new("Frame", ParticleCanvas)
    Spore.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
    Spore.Position = UDim2.new(math.random(), 0, 1, 5)
    Spore.BackgroundColor3 = THEME.AccentGlow
    Spore.BackgroundTransparency = 0.4
    Instance.new("UICorner", Spore).CornerRadius = UDim.new(1, 0)

    local speed = math.random(10, 20)
    local startX = Spore.Position.X.Scale
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not Spore or not Spore.Parent then conn:Disconnect() return end
        local newY = Spore.Position.Y.Scale - (dt * (speed / 100))
        local sway = math.sin(tick() * 2 + speed) * 0.015
        Spore.Position = UDim2.new(startX + sway, 0, newY, 0)
        if newY < -0.1 then Spore:Destroy() conn:Disconnect() end
    end)
end

task.spawn(function()
    while MainFrame and MainFrame.Parent do
        SpawnBioSpores()
        task.wait(1.0)
    end
end)

-- Outer Beat Stroke & Gradient
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 2.0
MainStroke.Transparency = 0.1

local VineGradient = Instance.new("UIGradient", MainStroke)
VineGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.DarkVine),
    ColorSequenceKeypoint.new(0.3, THEME.AccentGlow),
    ColorSequenceKeypoint.new(0.6, THEME.MintGlow),
    ColorSequenceKeypoint.new(1, THEME.DarkVine)
})
VineGradient.Rotation = 45

-- AUDIO VISUALIZER SLOW AMBIENT BEAT ENGINE
local beatTimer = 0
RunService.RenderStepped:Connect(function(dt)
    beatTimer = beatTimer + dt * 1.5 -- Slower tempo speed
    local pulse = (math.sin(beatTimer) + 1) / 2 -- Smooth 0 to 1 wave
    local beatVal = pulse^2.5 -- Natural rhythmic swell

    MainStroke.Thickness = 1.5 + (beatVal * 2.5)
    MainStroke.Transparency = 0.05 + (0.3 * (1 - beatVal))
    VineGradient.Rotation = (VineGradient.Rotation + dt * 20) % 360

    local bumpW = math.floor(beatVal * 3)
    local bumpH = math.floor(beatVal * 2)
    MainFrame.Size = UDim2.new(0, 365 + bumpW, 0, 250 + bumpH)
end)

-- Header Bar
local Header = Instance.new("Frame", MainFrame)
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 28)
Header.BackgroundColor3 = THEME.HeaderBg
Header.BackgroundTransparency = 0.3
Header.ZIndex = 2
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0, 180, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "🍃 IVY <font color=\"rgb(50, 230, 120)\">HUB</font>"
Title.RichText = true
Title.TextColor3 = THEME.TextMain
Title.TextSize = 11
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

-- STABILIZED GROUNDED TOP DOCK
local TopDock = Instance.new("Frame", MainFrame)
TopDock.Name = "TopDock"
TopDock.Size = UDim2.new(1, -16, 0, 22)
TopDock.Position = UDim2.new(0, 8, 0, 32)
TopDock.BackgroundColor3 = THEME.DockBg
TopDock.BackgroundTransparency = 0.4
TopDock.ZIndex = 2
Instance.new("UICorner", TopDock).CornerRadius = UDim.new(0, 6)

local DockScroll = Instance.new("ScrollingFrame", TopDock)
DockScroll.Size = UDim2.new(1, -6, 1, 0)
DockScroll.Position = UDim2.new(0, 3, 0, 0)
DockScroll.BackgroundTransparency = 1
DockScroll.ScrollBarThickness = 0
DockScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
DockScroll.AutomaticCanvasSize = Enum.AutomaticSize.X

local DockListLayout = Instance.new("UIListLayout", DockScroll)
DockListLayout.FillDirection = Enum.FillDirection.Horizontal
DockListLayout.Padding = UDim.new(0, 3)
DockListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -16, 1, -62)
ContentArea.Position = UDim2.new(0, 8, 0, 58)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 2

local CyberGUI = { Tabs = {}, KeybindRegistry = {}, RefreshCallbacks = {} }

-- Keybind Manager
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local code = input.KeyCode
    if code and code ~= Enum.KeyCode.Unknown then
        for name, bind in pairs(CyberGUI.KeybindRegistry) do
            if bind.Key == code then
                if bind.IsHold and bind.SetState then bind.SetState(true)
                elseif bind.Callback then bind.Callback() end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then return end
    local code = input.KeyCode
    if code and code ~= Enum.KeyCode.Unknown then
        for name, bind in pairs(CyberGUI.KeybindRegistry) do
            if bind.Key == code and bind.IsHold and bind.SetState then bind.SetState(false) end
        end
    end
end)

local function FormatKeyName(code)
    if not code or code == Enum.KeyCode.Unknown then return "N/A" end
    return code.Name:gsub("Button", ""):gsub("DPad", "")
end

function CyberGUI:RefreshAllUI()
    for _, cb in ipairs(CyberGUI.RefreshCallbacks) do pcall(cb) end
end

function CyberGUI:CreateTab(tabName)
    local DockButton = Instance.new("TextButton", DockScroll)
    DockButton.Size = UDim2.new(0, 68, 0, 18)
    DockButton.BackgroundColor3 = THEME.CardBg
    DockButton.BackgroundTransparency = 0.6
    DockButton.Text = tabName
    DockButton.TextColor3 = THEME.TextSub
    DockButton.Font = Enum.Font.GothamMedium
    DockButton.TextSize = 8
    Instance.new("UICorner", DockButton).CornerRadius = UDim.new(0, 4)

    local Container = Instance.new("ScrollingFrame", ContentArea)
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Visible = false
    Container.ScrollBarThickness = 2
    Container.ScrollBarImageColor3 = THEME.AccentGlow
    Container.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local ContainerList = Instance.new("UIListLayout", Container)
    ContainerList.Padding = UDim.new(0, 3)

    DockButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(CyberGUI.Tabs) do
            tab.Button.BackgroundTransparency = 0.6
            tab.Button.TextColor3 = THEME.TextSub
            tab.Container.Visible = false
        end
        DockButton.BackgroundTransparency = 0.1
        DockButton.TextColor3 = THEME.AccentGlow
        Container.Visible = true
    end)

    if #CyberGUI.Tabs == 0 then
        DockButton.BackgroundTransparency = 0.1
        DockButton.TextColor3 = THEME.AccentGlow
        Container.Visible = true
    end

    local TabObj = { Button = DockButton, Container = Container }

    function TabObj:AddToggle(labelName, configRef, configKey, onToggleCallback)
        local Card = Instance.new("Frame", Container)
        Card.Size = UDim2.new(0.98, 0, 0, 24)
        Card.BackgroundColor3 = THEME.CardBg
        Card.BackgroundTransparency = 0.3
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel", Card)
        Label.Size = UDim2.new(0.65, 0, 1, 0)
        Label.Position = UDim2.new(0, 8, 0, 0)
        Label.Text = labelName
        Label.TextColor3 = THEME.TextMain
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 8
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.BackgroundTransparency = 1

        local ToggleBtn = Instance.new("TextButton", Card)
        ToggleBtn.Size = UDim2.new(0, 30, 0, 14)
        ToggleBtn.Position = UDim2.new(1, -36, 0.5, -7)
        ToggleBtn.Text = ""
        Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

        local Knob = Instance.new("Frame", ToggleBtn)
        Knob.Size = UDim2.new(0, 10, 0, 10)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

        local function UpdateVisuals()
            local state = configRef[configKey] or false
            TweenService:Create(ToggleBtn, TweenInfo.new(0.18), { BackgroundColor3 = state and THEME.AccentGlow or Color3.fromRGB(35, 55, 42) }):Play()
            TweenService:Create(Knob, TweenInfo.new(0.18), { Position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5) }):Play()
        end

        local function SetState(state)
            configRef[configKey] = state
            UpdateVisuals()
            if onToggleCallback then onToggleCallback(state) end
        end

        local function ToggleAction()
            configRef[configKey] = not configRef[configKey]
            UpdateVisuals()
            if onToggleCallback then onToggleCallback(configRef[configKey]) end
        end

        ToggleBtn.MouseButton1Click:Connect(ToggleAction)
        table.insert(CyberGUI.RefreshCallbacks, UpdateVisuals)
        UpdateVisuals()
        return { Toggle = ToggleAction, SetState = SetState }
    end

    function TabObj:AddValueChanger(labelName, configRef, configKey)
        local Card = Instance.new("Frame", Container)
        Card.Size = UDim2.new(0.98, 0, 0, 24)
        Card.BackgroundColor3 = THEME.CardBg
        Card.BackgroundTransparency = 0.3
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel", Card)
        Label.Size = UDim2.new(0, 140, 1, 0)
        Label.Position = UDim2.new(0, 8, 0, 0)
        Label.Text = labelName
        Label.TextColor3 = THEME.TextMain
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 8
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.BackgroundTransparency = 1

        local InputBox = Instance.new("TextBox", Card)
        InputBox.Size = UDim2.new(0, 55, 0, 14)
        InputBox.Position = UDim2.new(1, -61, 0.5, -7)
        InputBox.BackgroundColor3 = THEME.InputBg
        InputBox.TextColor3 = THEME.AccentGlow
        InputBox.Font = Enum.Font.GothamBold
        InputBox.TextSize = 8
        InputBox.ClearTextOnFocus = false
        Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 3)

        local function UpdateVisuals() InputBox.Text = tostring(configRef[configKey] or "") end
        local function UpdateValue()
            local num = tonumber(InputBox.Text)
            configRef[configKey] = num or InputBox.Text
        end

        InputBox:GetPropertyChangedSignal("Text"):Connect(UpdateValue)
        InputBox.FocusLost:Connect(UpdateValue)
        table.insert(CyberGUI.RefreshCallbacks, UpdateVisuals)
        UpdateVisuals()
    end

    function TabObj:AddKeybinder(featureName, configRef, configKey, toggleRef, isHold, isAction, actionCallback)
        local Card = Instance.new("Frame", Container)
        Card.Size = UDim2.new(0.98, 0, 0, 24)
        Card.BackgroundColor3 = THEME.CardBg
        Card.BackgroundTransparency = 0.3
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel", Card)
        Label.Size = UDim2.new(0.5, 0, 1, 0)
        Label.Position = UDim2.new(0, 8, 0, 0)
        Label.Text = featureName .. " Bind"
        Label.TextColor3 = THEME.TextMain
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 8
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.BackgroundTransparency = 1

        local BindBtn = Instance.new("TextButton", Card)
        BindBtn.Size = UDim2.new(0, 42, 0, 14)
        BindBtn.Position = UDim2.new(1, -64, 0.5, -7)
        BindBtn.BackgroundColor3 = THEME.InputBg
        BindBtn.TextColor3 = THEME.AccentGlow
        BindBtn.Font = Enum.Font.GothamBold
        BindBtn.TextSize = 8
        Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 3)

        local ClearBtn = Instance.new("TextButton", Card)
        ClearBtn.Size = UDim2.new(0, 14, 0, 14)
        ClearBtn.Position = UDim2.new(1, -18, 0.5, -7)
        ClearBtn.BackgroundColor3 = Color3.fromRGB(75, 25, 30)
        ClearBtn.Text = "X"
        ClearBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
        ClearBtn.Font = Enum.Font.GothamBold
        ClearBtn.TextSize = 8
        Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 3)

        local function UpdateVisuals()
            BindBtn.Text = FormatKeyName(configRef[configKey])
            if CyberGUI.KeybindRegistry[featureName] then CyberGUI.KeybindRegistry[featureName].Key = configRef[configKey] end
        end

        CyberGUI.KeybindRegistry[featureName] = {
            Key = configRef[configKey], IsHold = isHold or false,
            Callback = function()
                if isAction and actionCallback then actionCallback()
                elseif toggleRef and toggleRef.Toggle then toggleRef.Toggle() end
            end,
            SetState = function(state) if toggleRef and toggleRef.SetState then toggleRef.SetState(state) end end
        }

        BindBtn.MouseButton1Click:Connect(function()
            BindBtn.Text = "..."
            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    configRef[configKey] = input.KeyCode
                    UpdateVisuals()
                    conn:Disconnect()
                end
            end)
        end)

        ClearBtn.MouseButton1Click:Connect(function()
            configRef[configKey] = Enum.KeyCode.Unknown
            UpdateVisuals()
        end)

        table.insert(CyberGUI.RefreshCallbacks, UpdateVisuals)
        UpdateVisuals()
    end

    function TabObj:AddDivider()
        local Divider = Instance.new("Frame", Container)
        Divider.Size = UDim2.new(0.98, 0, 0, 6)
        Divider.BackgroundTransparency = 1

        local Line = Instance.new("Frame", Divider)
        Line.Size = UDim2.new(1, -20, 0, 1)
        Line.Position = UDim2.new(0, 10, 0.5, 0)
        Line.BackgroundColor3 = THEME.DarkVine
        Line.BorderSizePixel = 0
    end

    table.insert(CyberGUI.Tabs, TabObj)
    return TabObj
end

-- ================================================================================
-- TAB CONTROLS REGISTRATION
-- ================================================================================

-- 1. Qb AB Tab
local QbABTab = CyberGUI:CreateTab("Qb AB")
local qbEnableTgl = QbABTab:AddToggle("Qb AB Enabled", _G.HubConfig.QBAim, "Enabled")
QbABTab:AddToggle("Team Filter", _G.HubConfig.QBAim, "TeamFilter")
QbABTab:AddToggle("Show Arc", _G.HubConfig.QBAim, "ShowArc")
QbABTab:AddToggle("Safe Arc", _G.HubConfig.QBAim, "SafeArc")
QbABTab:AddToggle("Target Highlight", _G.HubConfig.QBAim, "TargetHighlight")
QbABTab:AddValueChanger("Lead Adjust", _G.HubConfig.QBAim, "LeadDelay")
QbABTab:AddValueChanger("Peak Height", _G.HubConfig.QBAim, "PeakHeight")
QbABTab:AddValueChanger("XYZ Drift", _G.HubConfig.QBAim, "QBDrift")
QbABTab:AddKeybinder("Lock WR", _G.HubConfig.QBAim, "LockKeybind", nil, false, true, function() qbTargetPlayer = getBestQBTarget() end)
QbABTab:AddKeybinder("Throw Ball", _G.HubConfig.QBAim, "ThrowKeybind", nil, false, true, executeQBThrow)
QbABTab:AddKeybinder("Toggle Qb AB", _G.HubConfig.QBAim, "ToggleKeybind", qbEnableTgl)

-- 2. Auto Stick Tab
local AutoStickTab = CyberGUI:CreateTab("Auto Stick")
local autoStickTgl = AutoStickTab:AddToggle("Auto Stick", _G.HubConfig.AutoStick, "Enabled")
AutoStickTab:AddValueChanger("Activate Dist", _G.HubConfig.AutoStick, "ActivateDist")
AutoStickTab:AddValueChanger("Lock In Dist", _G.HubConfig.AutoStick, "LockInDist")
AutoStickTab:AddValueChanger("Max Strength", _G.HubConfig.AutoStick, "MaxStrength")
AutoStickTab:AddValueChanger("Target Offset Y", _G.HubConfig.AutoStick, "OffsetY")
AutoStickTab:AddValueChanger("Balance Radius", _G.HubConfig.AutoStick, "BalanceRadius")
AutoStickTab:AddValueChanger("Vertical Min", _G.HubConfig.AutoStick, "VertMin")
AutoStickTab:AddValueChanger("Vertical Max", _G.HubConfig.AutoStick, "VertMax")
AutoStickTab:AddValueChanger("Correction Speed", _G.HubConfig.AutoStick, "CorrSpeed")
AutoStickTab:AddKeybinder("Auto Stick", _G.HubConfig.AutoStick, "Keybind", autoStickTgl)

-- 3. Tap Bumper Tab
local TapBumperTab = CyberGUI:CreateTab("Tap Bumper")
local tapBumperTgl = TapBumperTab:AddToggle("Tap Bumper", _G.HubConfig.TapBumper, "Enabled")
TapBumperTab:AddValueChanger("Launch Force", _G.HubConfig.TapBumper, "Force")
TapBumperTab:AddKeybinder("Tap Bumper", _G.HubConfig.TapBumper, "Keybind", nil, false, true, triggerTapBumperImpulse)

-- 4. Auto Rocket Tab
local AutoRocketTab = CyberGUI:CreateTab("Auto Rocket")
local autoRocketTgl = AutoRocketTab:AddToggle("Auto Rocket", _G.HubConfig.AutoRocket, "Enabled")
AutoRocketTab:AddToggle("Head Only Velocity", _G.HubConfig.AutoRocket, "HeadOnly")
AutoRocketTab:AddValueChanger("Dive Power", _G.HubConfig.AutoRocket, "Power")
AutoRocketTab:AddKeybinder("Auto Rocket", _G.HubConfig.AutoRocket, "Keybind", autoRocketTgl)

-- 5. Fling Tab
local FlingTab = CyberGUI:CreateTab("Fling")
local flingTgl = FlingTab:AddToggle("Fling Active", _G.HubConfig.Fling, "Enabled")
FlingTab:AddValueChanger("Fling Power", _G.HubConfig.Fling, "Power")
FlingTab:AddKeybinder("Fling Action", _G.HubConfig.Fling, "Keybind", flingTgl, false, true, triggerFlingBoost)

-- 6. Sticky Tab
local StickyTab = CyberGUI:CreateTab("Sticky")
local stickyTgl = StickyTab:AddToggle("Sticky Head", _G.HubConfig.Sticky, "Enabled")
StickyTab:AddValueChanger("Detection Range", _G.HubConfig.Sticky, "Range")
StickyTab:AddValueChanger("Smoothness", _G.HubConfig.Sticky, "Smoothness")
StickyTab:AddValueChanger("Strength", _G.HubConfig.Sticky, "Strength")
StickyTab:AddKeybinder("Sticky Head", _G.HubConfig.Sticky, "Keybind", stickyTgl, true)

-- 7. Magnet & TP Tab
local MagnetTab = CyberGUI:CreateTab("Magnet & TP")
local magTgl = MagnetTab:AddToggle("uwu magnets", _G.HubConfig.uwuMagnets, "Enabled")
MagnetTab:AddValueChanger("Magnet Power", _G.HubConfig.uwuMagnets, "Power")
MagnetTab:AddValueChanger("Magnet Range", _G.HubConfig.uwuMagnets, "Range")
MagnetTab:AddKeybinder("uwu magnets", _G.HubConfig.uwuMagnets, "Keybind", magTgl)
MagnetTab:AddDivider()
local btpTgl = MagnetTab:AddToggle("Ball TP", _G.HubConfig.BTP, "Enabled")
MagnetTab:AddValueChanger("Max Distance", _G.HubConfig.BTP, "MaxDist")
MagnetTab:AddValueChanger("Catch Arm", _G.HubConfig.BTP, "CatchArm")
MagnetTab:AddKeybinder("Ball TP", _G.HubConfig.BTP, "Keybind", btpTgl)

-- 8. LegitPV Tab
local PVTab = CyberGUI:CreateTab("LegitPV")
local pvTgl = PVTab:AddToggle("Pull Vector Assist", _G.HubConfig.LegitPV, "Enabled")
PVTab:AddValueChanger("Pull Vector Strength", _G.HubConfig.LegitPV, "PullVec")
PVTab:AddValueChanger("Max Distance", _G.HubConfig.LegitPV, "MaxDist")
PVTab:AddKeybinder("LegitPV", _G.HubConfig.LegitPV, "Keybind", pvTgl, true)

-- 9. Tackle Reach Tab
local ReachTab = CyberGUI:CreateTab("Reach")
local reachTgl = ReachTab:AddToggle("Tackle Reach", _G.HubConfig.TackleReach, "Enabled")
ReachTab:AddValueChanger("Reach Size X", _G.HubConfig.TackleReach, "SizeX")
ReachTab:AddValueChanger("Reach Size Y", _G.HubConfig.TackleReach, "SizeY")
ReachTab:AddValueChanger("Reach Size Z", _G.HubConfig.TackleReach, "SizeZ")
ReachTab:AddValueChanger("Transparency", _G.HubConfig.TackleReach, "Transparency")
ReachTab:AddKeybinder("Tackle Reach", _G.HubConfig.TackleReach, "Keybind", reachTgl)

-- 10. Hitbox Expander Tab
local HitboxTab = CyberGUI:CreateTab("Hitbox")
local headTgl = HitboxTab:AddToggle("Hitbox Expander", _G.HubConfig.HeadHitbox, "Enabled")
HitboxTab:AddValueChanger("Hitbox Size", _G.HubConfig.HeadHitbox, "HeadSize")
HitboxTab:AddValueChanger("Transparency", _G.HubConfig.HeadHitbox, "Transparency")
HitboxTab:AddKeybinder("Hitbox Expander", _G.HubConfig.HeadHitbox, "Keybind", headTgl)

-- 11. Movement Tab
local MoveTab = CyberGUI:CreateTab("Movement")
local noOobTgl = MoveTab:AddToggle("NO OOB", _G.HubConfig.NoOOB, "Enabled")
MoveTab:AddKeybinder("NO OOB", _G.HubConfig.NoOOB, "Keybind", noOobTgl)
MoveTab:AddDivider()
local speedTgl = MoveTab:AddToggle("Loop Speed", _G.HubConfig.Speed, "Enabled")
MoveTab:AddValueChanger("Speed Value", _G.HubConfig.Speed, "SpeedVal")
MoveTab:AddKeybinder("Loop Speed", _G.HubConfig.Speed, "Keybind", speedTgl)
MoveTab:AddDivider()
local gravTgl = MoveTab:AddToggle("Gravity", _G.HubConfig.Gravity, "Enabled")
MoveTab:AddValueChanger("Gravity Value", _G.HubConfig.Gravity, "GravityVal")
MoveTab:AddKeybinder("Gravity", _G.HubConfig.Gravity, "Keybind", gravTgl)
MoveTab:AddDivider()
local jumpTgl = MoveTab:AddToggle("Jump Power", _G.HubConfig.JP, "Enabled")
MoveTab:AddValueChanger("JP Value", _G.HubConfig.JP, "JumpPower")
MoveTab:AddValueChanger("JP Cooldown", _G.HubConfig.JP, "Cooldown")
MoveTab:AddKeybinder("JP", _G.HubConfig.JP, "Keybind", jumpTgl)

-- 12. Visuals Tab
local VisualsTab = CyberGUI:CreateTab("Visuals")
local redSkyTgl = VisualsTab:AddToggle("Red Skybox", _G.HubConfig.RedSky, "Enabled")
VisualsTab:AddValueChanger("Brightness", _G.HubConfig.RedSky, "Brightness")
VisualsTab:AddKeybinder("Red Sky", _G.HubConfig.RedSky, "Keybind", redSkyTgl)
VisualsTab:AddDivider()
local potatoTgl = VisualsTab:AddToggle("potato graphics", _G.HubConfig.PotatoGraphics, "Enabled")
VisualsTab:AddKeybinder("potato graphics", _G.HubConfig.PotatoGraphics, "Keybind", potatoTgl)

-- 13. Misc & Config Tab
local MiscTab = CyberGUI:CreateTab("Misc")
MiscTab:AddKeybinder("Gui Toggle", _G.HubConfig.Misc, "Keybind", nil, false, true, function()
    MainFrame.Visible = not MainFrame.Visible
end)
MiscTab:AddDivider()

local hiderTgl = MiscTab:AddToggle("Hider", _G.HubConfig.Misc, "Hider", function(state)
    if state then runHiderLogic()
    elseif hiderConnection then hiderConnection:Disconnect() hiderConnection = nil end
end)
MiscTab:AddKeybinder("Hider", _G.HubConfig.Misc, "HiderKeybind", hiderTgl)
MiscTab:AddDivider()

----------------------------------------------------------------------------------
-- ADVANCED CONFIG MANAGER SECTION
----------------------------------------------------------------------------------
local currentConfigName = "default"

local function GetSavedConfigs()
    local cfgs = {}
    if listfiles and isfolder and isfolder(CONFIG_FOLDER) then
        pcall(function()
            for _, filePath in ipairs(listfiles(CONFIG_FOLDER)) do
                if filePath:sub(-5) == ".json" then
                    local fileName = filePath:match("([^/\\]+)%.json$")
                    if fileName then table.insert(cfgs, fileName) end
                end
            end
        end)
    end
    if #cfgs == 0 then table.insert(cfgs, "default") end
    return cfgs
end

local function GetCurrentAutoload()
    if isfile and isfile(AUTOLOAD_FILE) and readfile then
        local name = readfile(AUTOLOAD_FILE)
        if name and #name > 0 then return name end
    end
    return "None"
end

-- 1. Editable Config Name Input Card
local NameCard = Instance.new("Frame", MiscTab.Container)
NameCard.Size = UDim2.new(0.98, 0, 0, 24)
NameCard.BackgroundColor3 = THEME.CardBg
NameCard.BackgroundTransparency = 0.3
Instance.new("UICorner", NameCard).CornerRadius = UDim.new(0, 5)

local NameLabel = Instance.new("TextLabel", NameCard)
NameLabel.Size = UDim2.new(0, 90, 1, 0)
NameLabel.Position = UDim2.new(0, 8, 0, 0)
NameLabel.Text = "Config Name:"
NameLabel.TextColor3 = THEME.TextMain
NameLabel.Font = Enum.Font.GothamMedium
NameLabel.TextSize = 8
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.BackgroundTransparency = 1

local ConfigInputBox = Instance.new("TextBox", NameCard)
ConfigInputBox.Size = UDim2.new(0, 100, 0, 14)
ConfigInputBox.Position = UDim2.new(1, -106, 0.5, -7)
ConfigInputBox.BackgroundColor3 = THEME.InputBg
ConfigInputBox.TextColor3 = THEME.AccentGlow
ConfigInputBox.Text = currentConfigName
ConfigInputBox.Font = Enum.Font.GothamBold
ConfigInputBox.TextSize = 8
ConfigInputBox.ClearTextOnFocus = false
Instance.new("UICorner", ConfigInputBox).CornerRadius = UDim.new(0, 3)

ConfigInputBox:GetPropertyChangedSignal("Text"):Connect(function() currentConfigName = ConfigInputBox.Text end)

-- 2. Dropdown List Card
local DropCard = Instance.new("Frame", MiscTab.Container)
DropCard.Size = UDim2.new(0.98, 0, 0, 24)
DropCard.BackgroundColor3 = THEME.CardBg
DropCard.BackgroundTransparency = 0.3
DropCard.ClipsDescendants = false
Instance.new("UICorner", DropCard).CornerRadius = UDim.new(0, 5)

local DropLabel = Instance.new("TextLabel", DropCard)
DropLabel.Size = UDim2.new(0, 90, 1, 0)
DropLabel.Position = UDim2.new(0, 8, 0, 0)
DropLabel.Text = "Select File:"
DropLabel.TextColor3 = THEME.TextMain
DropLabel.Font = Enum.Font.GothamMedium
DropLabel.TextSize = 8
DropLabel.TextXAlignment = Enum.TextXAlignment.Left
DropLabel.BackgroundTransparency = 1

local DropBtn = Instance.new("TextButton", DropCard)
DropBtn.Size = UDim2.new(0, 70, 0, 14)
DropBtn.Position = UDim2.new(1, -106, 0.5, -7)
DropBtn.BackgroundColor3 = THEME.InputBg
DropBtn.Text = "Choose... 🔻"
DropBtn.TextColor3 = THEME.AccentGlow
DropBtn.Font = Enum.Font.GothamBold
DropBtn.TextSize = 8
Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 3)

local RefreshBtn = Instance.new("TextButton", DropCard)
RefreshBtn.Size = UDim2.new(0, 28, 0, 14)
RefreshBtn.Position = UDim2.new(1, -32, 0.5, -7)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 45)
RefreshBtn.Text = "🔄"
RefreshBtn.TextColor3 = THEME.TextMain
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 8
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 3)

local DropContainer = Instance.new("ScrollingFrame", DropCard)
DropContainer.Size = UDim2.new(0, 102, 0, 60)
DropContainer.Position = UDim2.new(1, -106, 1, 2)
DropContainer.BackgroundColor3 = THEME.HeaderBg
DropContainer.BorderSizePixel = 1
DropContainer.BorderColor3 = THEME.AccentGlow
DropContainer.Visible = false
DropContainer.ZIndex = 10
DropContainer.ScrollBarThickness = 2
DropContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", DropContainer).CornerRadius = UDim.new(0, 3)

local DropListLayout = Instance.new("UIListLayout", DropContainer)
DropListLayout.Padding = UDim.new(0, 2)

local function PopulateDropdown()
    for _, child in ipairs(DropContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, name in ipairs(GetSavedConfigs()) do
        local ItemBtn = Instance.new("TextButton", DropContainer)
        ItemBtn.Size = UDim2.new(1, -4, 0, 15)
        ItemBtn.BackgroundColor3 = THEME.CardBg
        ItemBtn.Text = " " .. name
        ItemBtn.TextColor3 = THEME.TextMain
        ItemBtn.Font = Enum.Font.GothamMedium
        ItemBtn.TextSize = 8
        ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
        ItemBtn.ZIndex = 11
        Instance.new("UICorner", ItemBtn).CornerRadius = UDim.new(0, 3)

        ItemBtn.MouseButton1Click:Connect(function()
            currentConfigName = name
            ConfigInputBox.Text = name
            DropContainer.Visible = false
        end)
    end
end

DropBtn.MouseButton1Click:Connect(function()
    PopulateDropdown()
    DropContainer.Visible = not DropContainer.Visible
end)
RefreshBtn.MouseButton1Click:Connect(PopulateDropdown)

-- Status / Autoload Indicator Card
local StatusCard = Instance.new("Frame", MiscTab.Container)
StatusCard.Size = UDim2.new(0.98, 0, 0, 16)
StatusCard.BackgroundColor3 = THEME.CardBg
StatusCard.BackgroundTransparency = 0.5
Instance.new("UICorner", StatusCard).CornerRadius = UDim.new(0, 3)

local StatusLabel = Instance.new("TextLabel", StatusCard)
StatusLabel.Size = UDim2.new(1, -10, 1, 0)
StatusLabel.Position = UDim2.new(0, 5, 0, 0)
StatusLabel.Text = "Autoloading: " .. GetCurrentAutoload()
StatusLabel.TextColor3 = THEME.TextSub
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 8
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.BackgroundTransparency = 1

local function UpdateAutoloadStatus()
    StatusLabel.Text = "Autoloading: " .. GetCurrentAutoload()
end

-- Config Action Buttons
local function CreateActionButton(btnText, btnColor, callback)
    local Card = Instance.new("Frame", MiscTab.Container)
    Card.Size = UDim2.new(0.98, 0, 0, 20)
    Card.BackgroundColor3 = THEME.CardBg
    Card.BackgroundTransparency = 0.3
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 5)

    local ActionBtn = Instance.new("TextButton", Card)
    ActionBtn.Size = UDim2.new(1, -10, 1, -4)
    ActionBtn.Position = UDim2.new(0, 5, 0, 2)
    ActionBtn.BackgroundColor3 = btnColor
    ActionBtn.Text = btnText
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.TextSize = 8
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 3)
    ActionBtn.MouseButton1Click:Connect(callback)
end

CreateActionButton("Save Config", Color3.fromRGB(35, 110, 65), function()
    if writefile then
        local name = currentConfigName ~= "" and currentConfigName or "default"
        writefile(CONFIG_FOLDER .. "/" .. name .. ".json", SerializeConfig(_G.HubConfig))
        PopulateDropdown()
    end
end)

CreateActionButton("Load Config", Color3.fromRGB(40, 90, 150), function()
    if readfile and isfile then
        local name = currentConfigName ~= "" and currentConfigName or "default"
        local path = CONFIG_FOLDER .. "/" .. name .. ".json"
        if isfile(path) then
            DeserializeConfig(readfile(path))
            CyberGUI:RefreshAllUI()
        end
    end
end)

CreateActionButton("Delete Config", Color3.fromRGB(150, 45, 50), function()
    if delfile and isfile then
        local name = currentConfigName ~= "" and currentConfigName or "default"
        local path = CONFIG_FOLDER .. "/" .. name .. ".json"
        if isfile(path) then
            delfile(path)
            PopulateDropdown()
        end
    end
end)

CreateActionButton("Set as Autoload", Color3.fromRGB(110, 85, 30), function()
    if writefile then
        local name = currentConfigName ~= "" and currentConfigName or "default"
        writefile(AUTOLOAD_FILE, name)
        UpdateAutoloadStatus()
    end
end)

CreateActionButton("Clear Autoload", Color3.fromRGB(70, 70, 80), function()
    if delfile and isfile and isfile(AUTOLOAD_FILE) then
        delfile(AUTOLOAD_FILE)
        UpdateAutoloadStatus()
    end
end)

-- Autoload Execution
task.spawn(function()
    task.wait(0.2)
    if isfile and isfile(AUTOLOAD_FILE) and readfile then
        local autoName = readfile(AUTOLOAD_FILE)
        if autoName and #autoName > 0 then
            local autoPath = CONFIG_FOLDER .. "/" .. autoName .. ".json"
            if isfile(autoPath) then
                pcall(function()
                    DeserializeConfig(readfile(autoPath))
                    CyberGUI:RefreshAllUI()
                end)
            end
        end
    end
end)

ScreenGui.Parent = targetParent
