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

-- Safe File Storage Directory
local function EnsureFolder()
    if makefolder and isfolder and not isfolder(CONFIG_FOLDER) then
        pcall(function() makefolder(CONFIG_FOLDER) end)
    end
end
EnsureFolder()

-- Safe GUI Parent Detection
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
    -- Qb AB Engine Configuration
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

    -- Physics & Out Of Bounds Safety
    NoOOB = { Enabled = false, Keybind = Enum.KeyCode.Unknown },

    uwuMagnets = { Enabled = false, Power = 55, Range = 25, Keybind = Enum.KeyCode.F },
    BTP = { Enabled = false, MaxDist = 35, CatchArm = "RightHand", Keybind = Enum.KeyCode.E },
    Sticky = { Enabled = false, Range = 10, Smoothness = 12, Strength = 12, Keybind = Enum.KeyCode.Unknown },
    LegitPV = { Enabled = false, PullVec = 0.01, MaxDist = 25, Keybind = Enum.KeyCode.Unknown },
    
    -- Standalone Auto ST Configuration
    AutoST = { Enabled = true, DetectionRange = 45, Smoothness = 25, Keybind = Enum.KeyCode.V },
    
    -- HeadPull Configuration (Mid-Air Only)
    HeadPull = { Enabled = false, Range = 12, Smoothness = 15, MaxStrength = 55, Keybind = Enum.KeyCode.Unknown },
    
    TackleReach = { Enabled = false, SizeX = 2.52, SizeY = 5.4, SizeZ = 1.41, Transparency = 0.7, Keybind = Enum.KeyCode.Unknown },
    HeadHitbox = { Enabled = false, HeadSize = 3.0, Transparency = 0.5, Keybind = Enum.KeyCode.Unknown },
    Speed = { Enabled = false, SpeedVal = 22.2, Keybind = Enum.KeyCode.Unknown },
    Gravity = { Enabled = false, GravityVal = 178.4, Keybind = Enum.KeyCode.Unknown },
    JP = { Enabled = false, JumpPower = 50, Cooldown = 1.15, Keybind = Enum.KeyCode.Unknown },
    
    AutoStick = { Enabled = false, ActivateDist = 1.9, LockInDist = 5, MaxStrength = 55, OffsetY = 2.8, BalanceRadius = 3.75, VertMin = -4, VertMax = 4, CorrSpeed = 0.55, Keybind = Enum.KeyCode.Unknown },
    
    -- STICK BUMP SETTINGS
    StickBump = {
        Enabled = false,
        Range = 10,
        Smoothness = 12,
        BoostPower = 55,
        Cooldown = 3,
        Keybind = Enum.KeyCode.Unknown
    },

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

-- Destroy Existing GUI Instance
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

-- Football Detector Helper
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

-- Dive Animation Detector
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
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local name = tostring(track.Name):lower()
                local anim = track.Animation
                local animId = anim and tostring(anim.AnimationId):lower() or ""
                if name:find("dive") or name:find("layout") or animId:find("dive") or animId:find("layout") then
                    active = true
                    return
                end
            end
        end
    end)
    return active
end

-- Impulse Force Helpers
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
-- QB AIM MATH MODULE
-- ================================================================================
local QBAimMathModule = {}
do
    local ballGravity = 28
    local gravityVector = Vector3.new(0, -ballGravity, 0)
    local defaultBallSpeed = 95

    local function flat(v) return Vector3.new(v.X, 0, v.Z) end
    local function clampMagnitude(v, maxMagnitude)
        if not v then return Vector3.zero end
        if v.Magnitude > maxMagnitude and maxMagnitude > 0 then return v.Unit * maxMagnitude end
        return v
    end
    local function ballAt(originPosition, velocity, time) return originPosition + velocity * time + 0.5 * gravityVector * time * time end

    local function targetAtTime(params, receiverStart, wrVel, time)
        local delay = math.max(params.leadDelay or 0, 0)
        local target = receiverStart + flat(wrVel) * (time + delay)
        local catchY = (params.catchY or receiverStart.Y) + (params.solveYBias or 0)
        return Vector3.new(target.X, catchY, target.Z), delay
    end

    local function interceptCandidate(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, time)
        if time <= 0 then return nil end
        local inheritance = params.qbInheritance or 0
        local inheritedVelocity = flat(qbVel or Vector3.zero) * inheritance
        local target, receiverLeadDelay = targetAtTime(params, receiverStart, wrVel, time)
        local neededDisplacement = target - originPosition - inheritedVelocity * time - 0.5 * gravityVector * time * time
        local requiredVelocity = neededDisplacement / time
        local requiredSpeed = requiredVelocity.Magnitude
        if requiredSpeed <= 1e-6 then return nil end

        local direction = requiredVelocity.Unit
        local angle = math.deg(math.asin(math.clamp(direction.Y, -1, 1)))
        if angle < (params.minAngle or -5) or angle > (params.maxAngle or 55) then return nil end

        local throwVelocity = direction * ballSpeed
        local worldVelocity = throwVelocity + inheritedVelocity
        local catchPosition = ballAt(originPosition, worldVelocity, time)
        local targetMiss = (catchPosition - target).Magnitude

        return {
            score = targetMiss * 1000 + time * 0.5,
            time = time,
            origin = originPosition,
            target = target,
            aimPoint = originPosition + direction * (params.aimScale or 1000),
            mathOk = true
        }
    end

    function QBAimMathModule.solve(params)
        local ballSpeed = params.ballPower or defaultBallSpeed
        local wrVel = clampMagnitude(flat(params.targetVelocity or Vector3.zero), 21)
        local qbVel = clampMagnitude(flat(params.qbVelocity or Vector3.zero), 21)
        local originPosition = params.originPosition
        local receiverBasePosition = params.receiverAnchorPosition or params.receiverPosition
        if not (originPosition and receiverBasePosition) then return nil end

        local receiverStart = Vector3.new(receiverBasePosition.X, params.catchY or receiverBasePosition.Y, receiverBasePosition.Z)
        local best = nil
        for time = 0.35, 6, 0.05 do
            local candidate = interceptCandidate(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, time)
            if candidate and (not best or candidate.score < best.score) then
                best = candidate
            end
        end
        return best
    end
end
rawset(getfenv(), "QBAimMathModule", QBAimMathModule)

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
-- DYNAMIC CROZO HITBOX & HEAD TARGET POSITION ENGINE
-- ================================================================================
local function getStickyTargetPos(maxDist)
    local char, hrp = getChar()
    if not hrp then return nil end
    local bestPos, bestDist = nil, maxDist or 9999

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eHrp = p.Character:FindFirstChild("HumanoidRootPart")
            local eHead = p.Character:FindFirstChild("Head")
            if eHrp and eHead then
                local d = (hrp.Position - eHrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    -- Check if Crozo Hitbox Expander is active
                    if _G.HubConfig.HeadHitbox and _G.HubConfig.HeadHitbox.Enabled then
                        -- Stick to the TOP surface of the expanded Crozo Hitbox
                        local topHitboxY = (eHrp.Size.Y / 2) + 1.2
                        bestPos = eHrp.Position + Vector3.new(0, topHitboxY, 0)
                    else
                        -- Hitbox OFF: Stick directly to the Head
                        bestPos = eHead.Position + Vector3.new(0, 2.5, 0)
                    end
                end
            end
        end
    end
    return bestPos
end

-- ================================================================================
-- BACKEND MODULE LOGIC LOOPS
-- ================================================================================

----------------------------------------------------------------------------------
-- 1. LEGIT PULL VECTOR (HOLD KEYBIND MECHANIC)
----------------------------------------------------------------------------------
local pvHeld = false

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    local isM1 = inp.UserInputType == Enum.UserInputType.MouseButton1
    local isR2 = inp.UserInputType == Enum.UserInputType.Gamepad1 and inp.KeyCode == Enum.KeyCode.ButtonR2
    if isM1 or isR2 or inp.KeyCode == _G.HubConfig.LegitPV.Keybind then
        pvHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    local isM1 = inp.UserInputType == Enum.UserInputType.MouseButton1
    local isR2 = inp.UserInputType == Enum.UserInputType.Gamepad1 and inp.KeyCode == Enum.KeyCode.ButtonR2
    if isM1 or isR2 or inp.KeyCode == _G.HubConfig.LegitPV.Keybind then
        pvHeld = false
    end
end)

RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.LegitPV.Enabled or not pvHeld then return end
    local char, hrp = getChar()
    if not char or not hrp then return end

    local ball = findFootballPart()
    if ball then
        local dist = (hrp.Position - ball.Position).Magnitude
        if dist <= (tonumber(_G.HubConfig.LegitPV.MaxDist) or 25) then
            local pVec = tonumber(_G.HubConfig.LegitPV.PullVec) or 0.01
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hrp.Position, ball.Position), pVec)
        end
    end
end)

----------------------------------------------------------------------------------
-- 2. STICKY HEAD MECHANIC (HOLD KEYBIND)
----------------------------------------------------------------------------------
local stickyHeld = false

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.ButtonL1 or inp.KeyCode == _G.HubConfig.Sticky.Keybind then
        stickyHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.ButtonL1 or inp.KeyCode == _G.HubConfig.Sticky.Keybind then
        stickyHeld = false
    end
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

----------------------------------------------------------------------------------
-- 3. AUTO ST CORE ENGINE
----------------------------------------------------------------------------------
local GRAVITY_VEC = Vector3.new(0, -28, 0)
local autoSTHeld = false
local autoSTTgl = nil

local function getBallPosAtTime(p0, v0, t)
    return p0 + (v0 * t) + (0.5 * GRAVITY_VEC * (t * t))
end

local function solveInterceptPoint(originPos, ballPos, ballVel)
    local bestPoint = nil
    local minDistance = math.huge
    
    for t = 0.03, 1.2, 0.04 do
        local predictedPos = getBallPosAtTime(ballPos, ballVel, t)
        local dist = (predictedPos - originPos).Magnitude
        
        if dist < minDistance then
            minDistance = dist
            bestPoint = predictedPos
        end
    end
    
    return bestPoint
end

local function setHoldingState(state)
    autoSTHeld = state
    if autoSTTgl and autoSTTgl.SetState then
        autoSTTgl.SetState(state)
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local bind = _G.HubConfig.AutoST.Keybind
    if (bind and bind ~= Enum.KeyCode.Unknown and input.KeyCode == bind) or input.KeyCode == Enum.KeyCode.ButtonL2 then
        setHoldingState(true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local bind = _G.HubConfig.AutoST.Keybind
    if (bind and bind ~= Enum.KeyCode.Unknown and input.KeyCode == bind) or input.KeyCode == Enum.KeyCode.ButtonL2 then
        setHoldingState(false)
    end
end)

RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.AutoST.Enabled or not autoSTHeld then return end
    
    local char, hrp = getChar()
    if not char or not hrp then return end
    
    local ball = findFootballPart()
    if not ball then return end
    
    local hrpPos = hrp.Position
    local ballPos = ball.Position
    local ballVel = ball.AssemblyLinearVelocity or Vector3.zero
    local maxRange = tonumber(_G.HubConfig.AutoST.DetectionRange) or 45
    
    if (hrpPos - ballPos).Magnitude <= maxRange then
        local rightShoulderPos = hrpPos + (hrp.CFrame.RightVector * 1.5)
        local targetPos = solveInterceptPoint(rightShoulderPos, ballPos, ballVel) or ballPos
        local dirXZ = Vector3.new(targetPos.X - hrpPos.X, 0, targetPos.Z - hrpPos.Z)
        
        if dirXZ.Magnitude > 0.1 then
            local unitDir = dirXZ.Unit
            local naturalLook = Vector3.new(unitDir.Z, 0, -unitDir.X)
            local targetCFrame = CFrame.lookAt(hrpPos, hrpPos + naturalLook)
            
            local smoothVal = math.clamp(tonumber(_G.HubConfig.AutoST.Smoothness) or 25, 1, 100)
            local lerpAlpha = math.clamp((101 - smoothVal) / 100, 0.05, 1.0)
            
            hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, lerpAlpha)
        end
    end
end)

----------------------------------------------------------------------------------
-- 4. HEADPULL ENGINE (MID-AIR EXCLUSIVE MECHANIC)
----------------------------------------------------------------------------------
local headPullHeld = false
local headPullTgl = nil

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local bind = _G.HubConfig.HeadPull.Keybind
    if bind and bind ~= Enum.KeyCode.Unknown and input.KeyCode == bind then
        headPullHeld = true
        if headPullTgl and headPullTgl.SetState then headPullTgl.SetState(true) end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local bind = _G.HubConfig.HeadPull.Keybind
    if bind and bind ~= Enum.KeyCode.Unknown and input.KeyCode == bind then
        headPullHeld = false
        if headPullTgl and headPullTgl.SetState then headPullTgl.SetState(false) end
    end
end)

RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.HeadPull.Enabled or not headPullHeld then return end
    local char, hrp, hum = getChar()
    if not char or not hrp or not hum then return end

    -- STRICT MID-AIR CHECK: Only execute HeadPull when airborne
    local state = hum:GetState()
    local inAir = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping or hum.FloorMaterial == Enum.Material.Air)
    if not inAir then return end

    local range = tonumber(_G.HubConfig.HeadPull.Range) or 12
    local targetPos = getStickyTargetPos(range)
    if not targetPos then return end

    local smoothVal = math.clamp((tonumber(_G.HubConfig.HeadPull.Smoothness) or 15) / 100, 0.01, 1)
    local maxStr = tonumber(_G.HubConfig.HeadPull.MaxStrength) or 55

    -- 1. Mid-air CFrame position lerp directly onto hitbox top / head
    hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos), smoothVal)

    -- 2. Mid-air velocity pull to eliminate air drag
    local dir = (targetPos - hrp.Position)
    if dir.Magnitude > 0.1 then
        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(dir.Unit * maxStr, 0.35)
    end
end)

----------------------------------------------------------------------------------
-- 5. STANDALONE AUTO STICK ENGINE
----------------------------------------------------------------------------------
local nudgeActive = false

RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.AutoStick.Enabled then return end
    local char, hrp, hum = getChar()
    if not char or not hrp or not hum then return end

    local targetPos = getStickyTargetPos(tonumber(_G.HubConfig.AutoStick.BalanceRadius) or 10)
    if not targetPos then return end

    local state = hum:GetState()
    local inAir = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping)

    if inAir then
        local maxStr = tonumber(_G.HubConfig.AutoStick.MaxStrength) or 55
        local dir = (targetPos - hrp.Position)
        if dir.Magnitude > 0.1 then
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(dir.Unit * maxStr, 0.35)
            local lookGoal = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
            hrp.CFrame = hrp.CFrame:Lerp(lookGoal, 0.15)
        end
    end
end)

----------------------------------------------------------------------------------
-- 6. STICK BUMP ENGINE (MID-AIR BUMP BOOST RESTORED)
----------------------------------------------------------------------------------
local stickBumpHeld = false
local bumpOnCooldown = false
local cdRemaining = 0

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.ButtonL1 or inp.KeyCode == _G.HubConfig.StickBump.Keybind then
        stickBumpHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.ButtonL1 or inp.KeyCode == _G.HubConfig.StickBump.Keybind then
        stickBumpHeld = false
    end
end)

-- Heartbeat Position Tracking
RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.StickBump.Enabled or not stickBumpHeld or bumpOnCooldown then return end
    local char, hrp = getChar()
    if not char or not hrp then return end

    local targetPos = getStickyTargetPos(tonumber(_G.HubConfig.StickBump.Range) or 10)
    if targetPos then
        local smoothVal = math.clamp((tonumber(_G.HubConfig.StickBump.Smoothness) or 12) / 100, 0.01, 1)
        hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos), smoothVal)
    end
end)

local function doBumpBoost(rootPart)
    bumpOnCooldown = true
    local boostPwr = tonumber(_G.HubConfig.StickBump.BoostPower) or 55
    local cdTime = tonumber(_G.HubConfig.StickBump.Cooldown) or 3
    cdRemaining = cdTime

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, boostPwr, 0)
    bv.MaxForce = Vector3.new(0, 9e9, 0)
    bv.Parent = rootPart
    task.wait(0.25)
    bv:Destroy()

    task.delay(cdTime, function()
        bumpOnCooldown = false
    end)
end

local function feetOnHeadOrHitbox(myHRP, targetChar)
    local eHrp = targetChar:FindFirstChild("HumanoidRootPart")
    local eHead = targetChar:FindFirstChild("Head")
    if not eHrp or not eHead then return false end

    local myFeetY = myHRP.Position.Y - (myHRP.Size.Y / 2)
    local topY, boxSizeX, boxSizeZ

    if _G.HubConfig.HeadHitbox and _G.HubConfig.HeadHitbox.Enabled then
        topY = eHrp.Position.Y + (eHrp.Size.Y / 2)
        boxSizeX = eHrp.Size.X / 2 + 1.2
        boxSizeZ = eHrp.Size.Z / 2 + 1.2
    else
        topY = eHead.Position.Y + (eHead.Size.Y / 2)
        boxSizeX = eHead.Size.X / 2 + 1.2
        boxSizeZ = eHead.Size.Z / 2 + 1.2
    end

    local dy = myFeetY - topY
    if dy < -1.0 or dy > 2.5 then return false end

    local dx = math.abs(myHRP.Position.X - eHrp.Position.X)
    local dz = math.abs(myHRP.Position.Z - eHrp.Position.Z)

    return dx <= boxSizeX and dz <= boxSizeZ
end

RunService.Heartbeat:Connect(function(dt)
    if cdRemaining > 0 then
        cdRemaining = math.max(0, cdRemaining - dt)
    end

    if not _G.HubConfig.StickBump or not _G.HubConfig.StickBump.Enabled or bumpOnCooldown then return end

    local char, myHRP = getChar()
    if not char or not myHRP then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local pChar = p.Character
        if not pChar then continue end

        if feetOnHeadOrHitbox(myHRP, pChar) then
            doBumpBoost(myHRP)
            break
        end
    end
end)

----------------------------------------------------------------------------------
-- 7. AUTO ROCKET ENGINE
----------------------------------------------------------------------------------
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
            local rocketBV = hrp:FindFirstChild("IvyHub_AutoRocket")
            if not rocketBV then
                rocketBV = Instance.new("BodyVelocity")
                rocketBV.Name = "IvyHub_AutoRocket"
                rocketBV.MaxForce = Vector3.new(math.huge, 0, math.huge)
                rocketBV.Parent = hrp
            end
            rocketBV.Velocity = moveDir * (tonumber(_G.HubConfig.AutoRocket.Power) or 45)
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

----------------------------------------------------------------------------------
-- 8. UWU MAGNETS & BALL TP (BTP)
----------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    local char, hrp = getChar()
    if not char or not hrp then return end

    if _G.HubConfig.uwuMagnets.Enabled then
        local ball = findFootballPart()
        if ball then
            local dist = (hrp.Position - ball.Position).Magnitude
            local maxRange = tonumber(_G.HubConfig.uwuMagnets.Range) or 25
            if dist <= maxRange then
                local power = tonumber(_G.HubConfig.uwuMagnets.Power) or 55
                local dir = (hrp.Position - ball.Position).Unit
                ball.AssemblyLinearVelocity = dir * power
            end
        end
    end

    if _G.HubConfig.BTP.Enabled then
        local ball = findFootballPart()
        if ball then
            local catchArm = char:FindFirstChild(_G.HubConfig.BTP.CatchArm) or hrp
            local dist = (catchArm.Position - ball.Position).Magnitude
            if dist <= (tonumber(_G.HubConfig.BTP.MaxDist) or 35) then
                ball.CFrame = catchArm.CFrame
                ball.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
end)

----------------------------------------------------------------------------------
-- 9. TACKLE REACH ENGINE
----------------------------------------------------------------------------------
local reachWatchers = setmetatable({}, {__mode = "k"})
local reachOriginalParts = {
    Transparency = setmetatable({}, {__mode = "k"}),
    Size = setmetatable({}, {__mode = "k"})
}

local defaultSizeX = 2.52
local defaultSizeY = 5.4
local defaultSizeZ = 1.41
local defaultTransparency = 0.7

local function safeDisconnectConns(t)
    if not t then return end
    for _, conn in ipairs(t) do
        if conn and type(conn.Disconnect) == "function" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(t)
end

local function getTargetReachSize()
    local x = tonumber(_G.HubConfig.TackleReach.SizeX) or defaultSizeX
    local y = tonumber(_G.HubConfig.TackleReach.SizeY) or defaultSizeY
    local z = tonumber(_G.HubConfig.TackleReach.SizeZ) or defaultSizeZ
    return Vector3.new(x, y, z)
end

local function getTargetReachTransparency()
    return tonumber(_G.HubConfig.TackleReach.Transparency) or defaultTransparency
end

local function ensureReachWatcher(inst)
    if not reachWatchers[inst] then
        reachWatchers[inst] = {
            cons = {},
            parts = {},
            partConns = setmetatable({}, {__mode = "k"}),
            origT = setmetatable({}, {__mode = "k"}),
            origS = setmetatable({}, {__mode = "k"}),
            attached = false
        }
    end
    return reachWatchers[inst]
end

local function applyReachVisuals(w, on)
    if not w then return end
    local targetSize = getTargetReachSize()
    local targetTrans = getTargetReachTransparency()

    for i = #w.parts, 1, -1 do
        local part = w.parts[i]
        if not (part and part.Parent) then
            table.remove(w.parts, i)
        elseif part:IsA("BasePart") then
            if on then
                if part.Transparency ~= targetTrans then part.Transparency = targetTrans end
                if part.Size ~= targetSize then part.Size = targetSize end
            else
                if w.origT[part] ~= nil and part.Transparency ~= w.origT[part] then part.Transparency = w.origT[part] end
                if w.origS[part] ~= nil and part.Size ~= w.origS[part] then part.Size = w.origS[part] end
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

    if not w.partConns[part] then
        w.partConns[part] = {}

        table.insert(w.partConns[part], part:GetPropertyChangedSignal("Size"):Connect(function()
            if _G.HubConfig.TackleReach.Enabled then
                local sz = getTargetReachSize()
                if part.Size ~= sz then part.Size = sz end
            end
        end))

        table.insert(w.partConns[part], part:GetPropertyChangedSignal("Transparency"):Connect(function()
            if _G.HubConfig.TackleReach.Enabled then
                local tr = getTargetReachTransparency()
                if part.Transparency ~= tr then part.Transparency = tr end
            end
        end))
    end

    if _G.HubConfig.TackleReach.Enabled then
        part.Transparency = getTargetReachTransparency()
        part.Size = getTargetReachSize()
    end
end

local function attachReachNode(node)
    if not node then return end
    local w = ensureReachWatcher(node)
    if w.attached then
        applyReachVisuals(w, _G.HubConfig.TackleReach.Enabled)
        return
    end

    w.attached = true
    for _, descendant in ipairs(node:GetDescendants()) do
        if descendant:IsA("BasePart") then trackReachPart(w, descendant) end
    end
    if node:IsA("BasePart") then trackReachPart(w, node) end

    table.insert(w.cons, node.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then trackReachPart(w, descendant) end
    end))
    applyReachVisuals(w, _G.HubConfig.TackleReach.Enabled)
end

local function scanReachWorkspace()
    local games = Workspace:FindFirstChild("Games")
    if games then
        for _, gFolder in ipairs(games:GetChildren()) do
            local rep = gFolder:FindFirstChild("Replicated")
            local hb = rep and rep:FindFirstChild("Hitboxes")
            local myHb = hb and hb:FindFirstChild(LocalPlayer.Name)
            if myHb then attachReachNode(myHb) end
        end
    end
end

task.spawn(function()
    task.wait(0.5)
    scanReachWorkspace()
end)

RunService.Heartbeat:Connect(function()
    for _, w in pairs(reachWatchers) do
        if type(w) == "table" and w.parts then
            applyReachVisuals(w, _G.HubConfig.TackleReach.Enabled)
        end
    end
end)

----------------------------------------------------------------------------------
-- 10. QB AIM TARGETING & EXECUTION ENGINE LOOPS
----------------------------------------------------------------------------------
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
                    if d < bestDist then
                        bestDist = d
                        bestPlayer = p
                    end
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
        originPosition = ball.Position,
        receiverPosition = eHrp.Position,
        targetVelocity = eHrp.AssemblyLinearVelocity,
        qbVelocity = hrp.AssemblyLinearVelocity,
        ballPower = 95,
        leadDelay = tonumber(_G.HubConfig.QBAim.LeadDelay) or 0.38,
        catchY = eHrp.Position.Y + (tonumber(_G.HubConfig.QBAim.PeakHeight) or 14.00)
    })

    if plan and plan.aimPoint then
        local gameEv = nil
        pcall(function()
            for _, folder in ipairs({Workspace:FindFirstChild("Games"), ReplicatedStorage:FindFirstChild("Games")}) do
                if folder then
                    for _, gameInst in ipairs(folder:GetChildren()) do
                        local re = gameInst:FindFirstChild("ReEvent") or (gameInst:FindFirstChild("Replicated") and gameInst.Replicated:FindFirstChild("ReEvent"))
                        if re then gameEv = re break end
                    end
                end
            end
        end)

        if gameEv then
            gameEv:FireServer("Mechanics", "ThrowBall", { Target = plan.aimPoint, AutoThrow = false, Power = 100 })
        end
    end
end

----------------------------------------------------------------------------------
-- 11. NO OOB ENGINE
----------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if _G.HubConfig.NoOOB and _G.HubConfig.NoOOB.Enabled then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("BasePart") then
                    local name = obj.Name:lower()
                    if name:find("oob") or name:find("outofbounds") or name:find("sideline") then
                        if obj.CanTouch then obj.CanTouch = false end
                    end
                end
            end
        end
    end
end)

----------------------------------------------------------------------------------
-- 12. CROZO HITBOX ENGINE
----------------------------------------------------------------------------------
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
                        originalHitboxProperties[eHrp] = {
                            Size = eHrp.Size,
                            Transparency = eHrp.Transparency,
                            CanCollide = eHrp.CanCollide
                        }
                    end

                    if eHrp.Size ~= targetSize then eHrp.Size = targetSize end
                    if eHrp.Transparency ~= transVal then eHrp.Transparency = transVal end
                    eHrp.CanCollide = true
                end
            end
        end
    else
        if next(originalHitboxProperties) then
            for hrp, props in pairs(originalHitboxProperties) do
                if hrp and hrp.Parent then
                    pcall(function()
                        hrp.Size = props.Size
                        hrp.Transparency = props.Transparency
                        hrp.CanCollide = props.CanCollide
                    end)
                end
            end
            table.clear(originalHitboxProperties)
        end
    end
end)

----------------------------------------------------------------------------------
-- 13. VISUALS & ENVIRONMENT
----------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if _G.HubConfig.RedSky.Enabled then
            Lighting.Brightness = tonumber(_G.HubConfig.RedSky.Brightness) or 2
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 30, 30)
            Lighting.FogColor = Color3.fromRGB(150, 0, 0)
            Lighting.FogEnd = 500
        end

        if _G.HubConfig.PotatoGraphics.Enabled then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj:Destroy()
                end
            end
        end
    end
end)

----------------------------------------------------------------------------------
-- 14. MOVEMENT OVERRIDES
----------------------------------------------------------------------------------
local lastJumpTime = 0
UserInputService.JumpRequest:Connect(function()
    if not _G.HubConfig.JP.Enabled then return end
    local char, hrp, hum = getChar()
    if not char or not hrp or not hum then return end
    local cd = tonumber(_G.HubConfig.JP.Cooldown) or 1.15
    if tick() - lastJumpTime >= cd then
        lastJumpTime = tick()
        local jPower = tonumber(_G.HubConfig.JP.JumpPower) or 50
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, jPower, hrp.AssemblyLinearVelocity.Z)
    end
end)

RunService.Heartbeat:Connect(function()
    local char, hrp, hum = getChar()
    if not char or not hum then return end

    if _G.HubConfig.Speed.Enabled then
        hum.WalkSpeed = tonumber(_G.HubConfig.Speed.SpeedVal) or 22.2
    end
    if _G.HubConfig.Gravity.Enabled then
        Workspace.Gravity = tonumber(_G.HubConfig.Gravity.GravityVal) or 178.4
    end
end)

-- ================================================================================
-- IVY HUB COMPACT ORGANIC GUI FRAMEWORK
-- ================================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IVY_HUB_INTERFACE"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local THEME = {
    Bg = Color3.fromRGB(10, 15, 12),
    Main = Color3.fromRGB(14, 22, 17),
    Header = Color3.fromRGB(18, 30, 22),
    Sidebar = Color3.fromRGB(11, 18, 14),
    Card = Color3.fromRGB(18, 32, 24),
    Accent = Color3.fromRGB(50, 220, 110),
    Glow = Color3.fromRGB(0, 255, 140),
    DarkVine = Color3.fromRGB(22, 70, 40),
    Text = Color3.fromRGB(240, 250, 244),
    SubText = Color3.fromRGB(140, 180, 155),
    InputBg = Color3.fromRGB(12, 24, 18)
}

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 270)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -135)
MainFrame.BackgroundColor3 = THEME.Main
MainFrame.BackgroundTransparency = 0.05
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Header Bar
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = THEME.Header
Header.BackgroundTransparency = 0.2
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "🍃 IVY <font color=\"rgb(50, 220, 110)\">HUB</font> <font size=\"8\" color=\"rgb(140, 180, 155)\">V2</font>"
Title.RichText = true
Title.TextColor3 = THEME.Text
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 105, 1, -34)
Sidebar.Position = UDim2.new(0, 0, 0, 34)
Sidebar.BackgroundColor3 = THEME.Sidebar
Sidebar.BackgroundTransparency = 0.4
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)

local TabScroll = Instance.new("ScrollingFrame", Sidebar)
TabScroll.Size = UDim2.new(1, -4, 1, -6)
TabScroll.Position = UDim2.new(0, 2, 0, 3)
TabScroll.BackgroundTransparency = 1
TabScroll.ScrollBarThickness = 2
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local TabListLayout = Instance.new("UIListLayout", TabScroll)
TabListLayout.Padding = UDim.new(0, 3)

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size = UDim2.new(1, -112, 1, -38)
ContentArea.Position = UDim2.new(0, 110, 0, 34)
ContentArea.BackgroundTransparency = 1

local CyberGUI = { Tabs = {}, KeybindRegistry = {}, RefreshCallbacks = {} }

-- Keybind Registration Engine
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local code = input.KeyCode
    if code and code ~= Enum.KeyCode.Unknown then
        for featureName, bindData in pairs(CyberGUI.KeybindRegistry) do
            if bindData.Key == code then
                if bindData.IsHold then
                    if bindData.SetState then bindData.SetState(true) end
                elseif bindData.IsAction then
                    if bindData.Callback then bindData.Callback() end
                elseif bindData.Callback then
                    bindData.Callback()
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local code = input.KeyCode
    if code and code ~= Enum.KeyCode.Unknown then
        for featureName, bindData in pairs(CyberGUI.KeybindRegistry) do
            if bindData.Key == code and bindData.IsHold then
                if bindData.SetState then bindData.SetState(false) end
            end
        end
    end
end)

local function FormatKeyName(keyCode)
    if not keyCode or typeof(keyCode) ~= "EnumItem" or keyCode == Enum.KeyCode.Unknown then return "N/A" end
    return keyCode.Name:gsub("Button", ""):gsub("DPad", "DPad ")
end

function CyberGUI:RefreshAllUI()
    for _, callback in ipairs(CyberGUI.RefreshCallbacks) do pcall(callback) end
end

function CyberGUI:CreateTab(tabName)
    local TabButton = Instance.new("TextButton", TabScroll)
    TabButton.Size = UDim2.new(0.94, 0, 0, 22)
    TabButton.BackgroundColor3 = THEME.Card
    TabButton.BackgroundTransparency = 0.5
    TabButton.Text = "  " .. tabName
    TabButton.TextColor3 = THEME.SubText
    TabButton.Font = Enum.Font.GothamMedium
    TabButton.TextSize = 9
    TabButton.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 4)

    local Indicator = Instance.new("Frame", TabButton)
    Indicator.Size = UDim2.new(0, 2, 0.6, 0)
    Indicator.Position = UDim2.new(0, 2, 0.2, 0)
    Indicator.BackgroundColor3 = THEME.Accent
    Indicator.BackgroundTransparency = 1
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    local Container = Instance.new("ScrollingFrame", ContentArea)
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Visible = false
    Container.ScrollBarThickness = 2
    Container.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local ContainerList = Instance.new("UIListLayout", Container)
    ContainerList.Padding = UDim.new(0, 4)

    TabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(CyberGUI.Tabs) do
            tab.Button.BackgroundTransparency = 0.5
            tab.Button.TextColor3 = THEME.SubText
            tab.Indicator.BackgroundTransparency = 1
            tab.Container.Visible = false
        end
        TabButton.BackgroundTransparency = 0.1
        TabButton.TextColor3 = THEME.Accent
        Indicator.BackgroundTransparency = 0
        Container.Visible = true
    end)

    if #CyberGUI.Tabs == 0 then
        TabButton.BackgroundTransparency = 0.1
        TabButton.TextColor3 = THEME.Accent
        Indicator.BackgroundTransparency = 0
        Container.Visible = true
    end

    local TabObj = { Button = TabButton, Indicator = Indicator, Container = Container }

    function TabObj:AddToggle(labelName, configRef, configKey, onToggleCallback)
        local Card = Instance.new("Frame", Container)
        Card.Size = UDim2.new(0.97, 0, 0, 25)
        Card.BackgroundColor3 = THEME.Card
        Card.BackgroundTransparency = 0.2
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel", Card)
        Label.Size = UDim2.new(0.65, 0, 1, 0)
        Label.Position = UDim2.new(0, 6, 0, 0)
        Label.Text = labelName
        Label.TextColor3 = THEME.Text
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 9
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.BackgroundTransparency = 1

        local ToggleBtn = Instance.new("TextButton", Card)
        ToggleBtn.Size = UDim2.new(0, 32, 0, 15)
        ToggleBtn.Position = UDim2.new(1, -38, 0.5, -7)
        ToggleBtn.Text = ""
        Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

        local Knob = Instance.new("Frame", ToggleBtn)
        Knob.Size = UDim2.new(0, 11, 0, 11)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

        local function UpdateVisuals()
            local state = configRef[configKey] or false
            ToggleBtn.BackgroundColor3 = state and THEME.Accent or Color3.fromRGB(35, 50, 40)
            Knob.Position = state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
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
        Card.Size = UDim2.new(0.97, 0, 0, 25)
        Card.BackgroundColor3 = THEME.Card
        Card.BackgroundTransparency = 0.2
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel", Card)
        Label.Size = UDim2.new(0, 115, 1, 0)
        Label.Position = UDim2.new(0, 6, 0, 0)
        Label.Text = labelName
        Label.TextColor3 = THEME.Text
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 9
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.BackgroundTransparency = 1

        local InputBox = Instance.new("TextBox", Card)
        InputBox.Size = UDim2.new(0, 55, 0, 15)
        InputBox.Position = UDim2.new(1, -61, 0.5, -7)
        InputBox.BackgroundColor3 = THEME.InputBg
        InputBox.TextColor3 = THEME.Accent
        InputBox.Font = Enum.Font.GothamBold
        InputBox.TextSize = 9
        InputBox.ClearTextOnFocus = false
        Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 3)

        local function UpdateVisuals() InputBox.Text = tostring(configRef[configKey] or "") end
        local function UpdateValue()
            local num = tonumber(InputBox.Text)
            if num then configRef[configKey] = num else configRef[configKey] = InputBox.Text end
        end

        InputBox:GetPropertyChangedSignal("Text"):Connect(UpdateValue)
        InputBox.FocusLost:Connect(UpdateValue)
        table.insert(CyberGUI.RefreshCallbacks, UpdateVisuals)
        UpdateVisuals()
    end

    function TabObj:AddKeybinder(featureName, configRef, configKey, toggleRef, isHold, isAction, actionCallback)
        local Card = Instance.new("Frame", Container)
        Card.Size = UDim2.new(0.97, 0, 0, 25)
        Card.BackgroundColor3 = THEME.Card
        Card.BackgroundTransparency = 0.2
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 5)

        local Label = Instance.new("TextLabel", Card)
        Label.Size = UDim2.new(0.5, 0, 1, 0)
        Label.Position = UDim2.new(0, 6, 0, 0)
        Label.Text = featureName .. " Bind"
        Label.TextColor3 = THEME.Text
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 9
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.BackgroundTransparency = 1

        local BindBtn = Instance.new("TextButton", Card)
        BindBtn.Size = UDim2.new(0, 45, 0, 15)
        BindBtn.Position = UDim2.new(1, -66, 0.5, -7)
        BindBtn.BackgroundColor3 = THEME.InputBg
        BindBtn.TextColor3 = THEME.Accent
        BindBtn.Font = Enum.Font.GothamBold
        BindBtn.TextSize = 9
        Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 3)

        local ClearBtn = Instance.new("TextButton", Card)
        ClearBtn.Size = UDim2.new(0, 15, 0, 15)
        ClearBtn.Position = UDim2.new(1, -18, 0.5, -7)
        ClearBtn.BackgroundColor3 = Color3.fromRGB(70, 25, 30)
        ClearBtn.Text = "X"
        ClearBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
        ClearBtn.Font = Enum.Font.GothamBold
        ClearBtn.TextSize = 9
        Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 3)

        local function UpdateVisuals()
            BindBtn.Text = FormatKeyName(configRef[configKey])
            if CyberGUI.KeybindRegistry[featureName] then
                CyberGUI.KeybindRegistry[featureName].Key = configRef[configKey]
            end
        end

        CyberGUI.KeybindRegistry[featureName] = {
            Key = configRef[configKey],
            IsHold = isHold or false,
            IsAction = isAction or false,
            Callback = function()
                if isAction and actionCallback then
                    actionCallback()
                elseif toggleRef and type(toggleRef) == "table" and toggleRef.Toggle then
                    toggleRef.Toggle()
                end
            end,
            SetState = function(state)
                if toggleRef and type(toggleRef) == "table" and toggleRef.SetState then toggleRef.SetState(state) end
            end
        }

        BindBtn.MouseButton1Click:Connect(function()
            BindBtn.Text = "..."
            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                local code = input.KeyCode
                if code and code ~= Enum.KeyCode.Unknown then
                    configRef[configKey] = code
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
        Divider.Size = UDim2.new(0.97, 0, 0, 10)
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
-- TAB CONTROLS REGISTRATION (ALL VALUE CHANGERS RESTORED)
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
QbABTab:AddKeybinder("Throw Ball", _G.HubConfig.QBAim, "ThrowKeybind", nil, false, true, function() executeQBThrow() end)
QbABTab:AddKeybinder("Toggle Qb AB", _G.HubConfig.QBAim, "ToggleKeybind", qbEnableTgl)
QbABTab:AddDivider()

-- 2. Auto ST Tab
local AutoSTTab = CyberGUI:CreateTab("Auto ST")
autoSTTgl = AutoSTTab:AddToggle("Auto ST Active", _G.HubConfig.AutoST, "Enabled")
AutoSTTab:AddValueChanger("Detection Range", _G.HubConfig.AutoST, "DetectionRange")
AutoSTTab:AddValueChanger("Smoothness", _G.HubConfig.AutoST, "Smoothness")
AutoSTTab:AddKeybinder("Auto ST", _G.HubConfig.AutoST, "Keybind", autoSTTgl, true)
AutoSTTab:AddDivider()

-- 3. HeadPull Tab (Mid-Air Only)
local HeadPullTab = CyberGUI:CreateTab("HeadPull")
headPullTgl = HeadPullTab:AddToggle("HeadPull Active", _G.HubConfig.HeadPull, "Enabled")
HeadPullTab:AddValueChanger("Range", _G.HubConfig.HeadPull, "Range")
HeadPullTab:AddValueChanger("Smoothness", _G.HubConfig.HeadPull, "Smoothness")
HeadPullTab:AddValueChanger("Max Strength", _G.HubConfig.HeadPull, "MaxStrength")
HeadPullTab:AddKeybinder("HeadPull", _G.HubConfig.HeadPull, "Keybind", headPullTgl, true)
HeadPullTab:AddDivider()

-- 4. Auto Stick Tab (All Value Changers Restored)
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
AutoStickTab:AddDivider()

-- 5. Stick Bump Tab
local StickBumpTab = CyberGUI:CreateTab("Stick Bump")
local stickBumpTgl = StickBumpTab:AddToggle("Stick Bump", _G.HubConfig.StickBump, "Enabled")
StickBumpTab:AddValueChanger("Range", _G.HubConfig.StickBump, "Range")
StickBumpTab:AddValueChanger("Smoothness", _G.HubConfig.StickBump, "Smoothness")
StickBumpTab:AddValueChanger("Boost Power", _G.HubConfig.StickBump, "BoostPower")
StickBumpTab:AddValueChanger("Cooldown", _G.HubConfig.StickBump, "Cooldown")
StickBumpTab:AddKeybinder("Stick Bump", _G.HubConfig.StickBump, "Keybind", stickBumpTgl, true)
StickBumpTab:AddDivider()

-- 6. Tap Bumper Tab
local TapBumperTab = CyberGUI:CreateTab("Tap Bumper")
local tapBumperTgl = TapBumperTab:AddToggle("Tap Bumper", _G.HubConfig.TapBumper, "Enabled")
TapBumperTab:AddValueChanger("Launch Force", _G.HubConfig.TapBumper, "Force")
TapBumperTab:AddKeybinder("Tap Bumper", _G.HubConfig.TapBumper, "Keybind", nil, false, true, triggerTapBumperImpulse)
TapBumperTab:AddDivider()

-- 7. Auto Rocket Tab
local AutoRocketTab = CyberGUI:CreateTab("Auto Rocket")
local autoRocketTgl = AutoRocketTab:AddToggle("Auto Rocket", _G.HubConfig.AutoRocket, "Enabled")
AutoRocketTab:AddToggle("Head Only Velocity", _G.HubConfig.AutoRocket, "HeadOnly")
AutoRocketTab:AddValueChanger("Dive Power", _G.HubConfig.AutoRocket, "Power")
AutoRocketTab:AddKeybinder("Auto Rocket", _G.HubConfig.AutoRocket, "Keybind", autoRocketTgl)
AutoRocketTab:AddDivider()

-- 8. Fling Tab
local FlingTab = CyberGUI:CreateTab("Fling")
local flingTgl = FlingTab:AddToggle("Fling Active", _G.HubConfig.Fling, "Enabled")
FlingTab:AddValueChanger("Fling Power", _G.HubConfig.Fling, "Power")
FlingTab:AddKeybinder("Fling Action", _G.HubConfig.Fling, "Keybind", flingTgl, false, true, triggerFlingBoost)
FlingTab:AddDivider()

-- 9. Sticky Tab (Hold Keybind)
local StickyTab = CyberGUI:CreateTab("Sticky")
local stickyTgl = StickyTab:AddToggle("Sticky Head", _G.HubConfig.Sticky, "Enabled")
StickyTab:AddValueChanger("Detection Range", _G.HubConfig.Sticky, "Range")
StickyTab:AddValueChanger("Smoothness", _G.HubConfig.Sticky, "Smoothness")
StickyTab:AddValueChanger("Strength", _G.HubConfig.Sticky, "Strength")
StickyTab:AddKeybinder("Sticky Head", _G.HubConfig.Sticky, "Keybind", stickyTgl, true)
StickyTab:AddDivider()

-- 10. BTP & Magnet Tab
local MagnetTab = CyberGUI:CreateTab("BTP & Magnet")
local magTgl = MagnetTab:AddToggle("uwu magnets", _G.HubConfig.uwuMagnets, "Enabled")
MagnetTab:AddValueChanger("Magnet Power", _G.HubConfig.uwuMagnets, "Power")
MagnetTab:AddValueChanger("Magnet Range", _G.HubConfig.uwuMagnets, "Range")
MagnetTab:AddKeybinder("uwu magnets", _G.HubConfig.uwuMagnets, "Keybind", magTgl)
MagnetTab:AddDivider()

local btpTgl = MagnetTab:AddToggle("Ball TP", _G.HubConfig.BTP, "Enabled")
MagnetTab:AddValueChanger("Max Distance", _G.HubConfig.BTP, "MaxDist")
MagnetTab:AddValueChanger("Catch Arm", _G.HubConfig.BTP, "CatchArm")
MagnetTab:AddKeybinder("Ball TP", _G.HubConfig.BTP, "Keybind", btpTgl)
MagnetTab:AddDivider()

-- 11. LegitPV Tab
local PVTab = CyberGUI:CreateTab("LegitPV")
local pvTgl = PVTab:AddToggle("Pull Vector Assist", _G.HubConfig.LegitPV, "Enabled")
PVTab:AddValueChanger("Pull Vector Strength", _G.HubConfig.LegitPV, "PullVec")
PVTab:AddValueChanger("Max Distance", _G.HubConfig.LegitPV, "MaxDist")
PVTab:AddKeybinder("LegitPV", _G.HubConfig.LegitPV, "Keybind", pvTgl, true)
PVTab:AddDivider()

-- 12. Tackle Reach Tab
local ReachTab = CyberGUI:CreateTab("Tackle Reach")
local reachTgl = ReachTab:AddToggle("Tackle Reach", _G.HubConfig.TackleReach, "Enabled")
ReachTab:AddValueChanger("Reach Size X", _G.HubConfig.TackleReach, "SizeX")
ReachTab:AddValueChanger("Reach Size Y", _G.HubConfig.TackleReach, "SizeY")
ReachTab:AddValueChanger("Reach Size Z", _G.HubConfig.TackleReach, "SizeZ")
ReachTab:AddValueChanger("Transparency", _G.HubConfig.TackleReach, "Transparency")
ReachTab:AddKeybinder("Tackle Reach", _G.HubConfig.TackleReach, "Keybind", reachTgl)
ReachTab:AddDivider()

-- 13. Movement & Physics Tab
local MoveTab = CyberGUI:CreateTab("Movement")
local noOobTgl = MoveTab:AddToggle("NO OOB", _G.HubConfig.NoOOB, "Enabled")
MoveTab:AddKeybinder("NO OOB", _G.HubConfig.NoOOB, "Keybind", noOobTgl)
MoveTab:AddDivider()

local speedTgl = MoveTab:AddToggle("Loop Speed", _G.HubConfig.Speed, "Enabled")
MoveTab:AddValueChanger("Speed", _G.HubConfig.Speed, "SpeedVal")
MoveTab:AddKeybinder("Loop Speed", _G.HubConfig.Speed, "Keybind", speedTgl)
MoveTab:AddDivider()

local gravTgl = MoveTab:AddToggle("Gravity", _G.HubConfig.Gravity, "Enabled")
MoveTab:AddValueChanger("Gravity Value", _G.HubConfig.Gravity, "GravityVal")
MoveTab:AddKeybinder("Gravity", _G.HubConfig.Gravity, "Keybind", gravTgl)
MoveTab:AddDivider()

local jumpTgl = MoveTab:AddToggle("JP", _G.HubConfig.JP, "Enabled")
MoveTab:AddValueChanger("JP Power", _G.HubConfig.JP, "JumpPower")
MoveTab:AddValueChanger("Cooldown", _G.HubConfig.JP, "Cooldown")
MoveTab:AddKeybinder("JP", _G.HubConfig.JP, "Keybind", jumpTgl)
MoveTab:AddDivider()

-- 14. Visuals Tab
local VisualsTab = CyberGUI:CreateTab("Visuals")
local redSkyTgl = VisualsTab:AddToggle("Red Skybox", _G.HubConfig.RedSky, "Enabled")
VisualsTab:AddValueChanger("Sky Brightness", _G.HubConfig.RedSky, "Brightness")
VisualsTab:AddKeybinder("Red Sky", _G.HubConfig.RedSky, "Keybind", redSkyTgl)
VisualsTab:AddDivider()

local potatoTgl = VisualsTab:AddToggle("potato graphics", _G.HubConfig.PotatoGraphics, "Enabled")
VisualsTab:AddKeybinder("potato graphics", _G.HubConfig.PotatoGraphics, "Keybind", potatoTgl)
VisualsTab:AddDivider()

-- 15. Hitbox Expander Tab (Crozo Hitbox Engine)
local HitboxTab = CyberGUI:CreateTab("Hitbox")
local headTgl = HitboxTab:AddToggle("Hitbox Expander", _G.HubConfig.HeadHitbox, "Enabled")
HitboxTab:AddValueChanger("Hitbox Size", _G.HubConfig.HeadHitbox, "HeadSize")
HitboxTab:AddValueChanger("Transparency", _G.HubConfig.HeadHitbox, "Transparency")
HitboxTab:AddKeybinder("Hitbox Expander", _G.HubConfig.HeadHitbox, "Keybind", headTgl)
HitboxTab:AddDivider()

-- 16. Misc Tab & Complete Config System Engine
local MiscTab = CyberGUI:CreateTab("Misc")
MiscTab:AddKeybinder("Gui Toggle", _G.HubConfig.Misc, "Keybind", nil, false, true, function() MainFrame.Visible = not MainFrame.Visible end)
MiscTab:AddDivider()

local hiderTgl = MiscTab:AddToggle("Hider", _G.HubConfig.Misc, "Hider", function(state)
    if state then runHiderLogic() elseif hiderConnection then hiderConnection:Disconnect() hiderConnection = nil end
end)
MiscTab:AddKeybinder("Hider", _G.HubConfig.Misc, "HiderKeybind", hiderTgl)
MiscTab:AddDivider()

----------------------------------------------------------------------------------
-- ADVANCED CONFIG SYSTEM UI
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

-- 1. Config Name Input Card
local NameCard = Instance.new("Frame", MiscTab.Container)
NameCard.Size = UDim2.new(0.97, 0, 0, 25)
NameCard.BackgroundColor3 = THEME.Card
NameCard.BackgroundTransparency = 0.2
Instance.new("UICorner", NameCard).CornerRadius = UDim.new(0, 5)

local NameLabel = Instance.new("TextLabel", NameCard)
NameLabel.Size = UDim2.new(0, 95, 1, 0)
NameLabel.Position = UDim2.new(0, 6, 0, 0)
NameLabel.Text = "Config Name:"
NameLabel.TextColor3 = THEME.Text
NameLabel.Font = Enum.Font.GothamMedium
NameLabel.TextSize = 9
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.BackgroundTransparency = 1

local ConfigInputBox = Instance.new("TextBox", NameCard)
ConfigInputBox.Size = UDim2.new(0, 120, 0, 15)
ConfigInputBox.Position = UDim2.new(1, -126, 0.5, -7)
ConfigInputBox.BackgroundColor3 = THEME.InputBg
ConfigInputBox.TextColor3 = THEME.Accent
ConfigInputBox.Text = currentConfigName
ConfigInputBox.Font = Enum.Font.GothamBold
ConfigInputBox.TextSize = 9
ConfigInputBox.ClearTextOnFocus = false
Instance.new("UICorner", ConfigInputBox).CornerRadius = UDim.new(0, 3)

ConfigInputBox:GetPropertyChangedSignal("Text"):Connect(function() currentConfigName = ConfigInputBox.Text end)

-- 2. Dropdown List Card
local DropCard = Instance.new("Frame", MiscTab.Container)
DropCard.Size = UDim2.new(0.97, 0, 0, 25)
DropCard.BackgroundColor3 = THEME.Card
DropCard.BackgroundTransparency = 0.2
DropCard.ClipsDescendants = false
Instance.new("UICorner", DropCard).CornerRadius = UDim.new(0, 5)

local DropLabel = Instance.new("TextLabel", DropCard)
DropLabel.Size = UDim2.new(0, 95, 1, 0)
DropLabel.Position = UDim2.new(0, 6, 0, 0)
DropLabel.Text = "Select File:"
DropLabel.TextColor3 = THEME.Text
DropLabel.Font = Enum.Font.GothamMedium
DropLabel.TextSize = 9
DropLabel.TextXAlignment = Enum.TextXAlignment.Left
DropLabel.BackgroundTransparency = 1

local DropBtn = Instance.new("TextButton", DropCard)
DropBtn.Size = UDim2.new(0, 85, 0, 15)
DropBtn.Position = UDim2.new(1, -126, 0.5, -7)
DropBtn.BackgroundColor3 = THEME.InputBg
DropBtn.Text = "Choose... 📂"
DropBtn.TextColor3 = THEME.Accent
DropBtn.Font = Enum.Font.GothamBold
DropBtn.TextSize = 9
Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 3)

local RefreshBtn = Instance.new("TextButton", DropCard)
RefreshBtn.Size = UDim2.new(0, 30, 0, 15)
RefreshBtn.Position = UDim2.new(1, -36, 0.5, -7)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 45)
RefreshBtn.Text = "🔄"
RefreshBtn.TextColor3 = THEME.Text
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 9
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 3)

local DropContainer = Instance.new("ScrollingFrame", DropCard)
DropContainer.Size = UDim2.new(0, 120, 0, 70)
DropContainer.Position = UDim2.new(1, -126, 1, 2)
DropContainer.BackgroundColor3 = THEME.Header
DropContainer.BorderSizePixel = 1
DropContainer.BorderColor3 = THEME.Accent
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
    local cfgs = GetSavedConfigs()
    for _, name in ipairs(cfgs) do
        local ItemBtn = Instance.new("TextButton", DropContainer)
        ItemBtn.Size = UDim2.new(1, -4, 0, 16)
        ItemBtn.BackgroundColor3 = THEME.Card
        ItemBtn.Text = " " .. name
        ItemBtn.TextColor3 = THEME.Text
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

-- Status / Autoload Indicator
local StatusCard = Instance.new("Frame", MiscTab.Container)
StatusCard.Size = UDim2.new(0.97, 0, 0, 18)
StatusCard.BackgroundColor3 = THEME.Card
StatusCard.BackgroundTransparency = 0.5
Instance.new("UICorner", StatusCard).CornerRadius = UDim.new(0, 3)

local StatusLabel = Instance.new("TextLabel", StatusCard)
StatusLabel.Size = UDim2.new(1, -10, 1, 0)
StatusLabel.Position = UDim2.new(0, 5, 0, 0)
StatusLabel.Text = "Autoloading: " .. GetCurrentAutoload()
StatusLabel.TextColor3 = THEME.SubText
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 8
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.BackgroundTransparency = 1

local function UpdateAutoloadStatus()
    StatusLabel.Text = "Autoloading: " .. GetCurrentAutoload()
end

-- Config Buttons Helper
local function CreateActionButton(btnText, btnColor, callback)
    local Card = Instance.new("Frame", MiscTab.Container)
    Card.Size = UDim2.new(0.97, 0, 0, 22)
    Card.BackgroundColor3 = THEME.Card
    Card.BackgroundTransparency = 0.2
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 5)

    local ActionBtn = Instance.new("TextButton", Card)
    ActionBtn.Size = UDim2.new(1, -10, 1, -6)
    ActionBtn.Position = UDim2.new(0, 5, 0, 3)
    ActionBtn.BackgroundColor3 = btnColor
    ActionBtn.Text = btnText
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.TextSize = 9
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 3)
    ActionBtn.MouseButton1Click:Connect(callback)
end

-- Save Config
CreateActionButton("Save Config", Color3.fromRGB(35, 110, 65), function()
    if writefile then
        local name = currentConfigName ~= "" and currentConfigName or "default"
        writefile(CONFIG_FOLDER .. "/" .. name .. ".json", SerializeConfig(_G.HubConfig))
        PopulateDropdown()
    end
end)

-- Load Config
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

-- Delete Config
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

-- Set as Autoload
CreateActionButton("Set as Autoload", Color3.fromRGB(110, 85, 30), function()
    if writefile then
        local name = currentConfigName ~= "" and currentConfigName or "default"
        writefile(AUTOLOAD_FILE, name)
        UpdateAutoloadStatus()
    end
end)

-- Clear Autoload
CreateActionButton("Clear Autoload", Color3.fromRGB(70, 70, 80), function()
    if delfile and isfile and isfile(AUTOLOAD_FILE) then
        delfile(AUTOLOAD_FILE)
        UpdateAutoloadStatus()
    end
end)

MiscTab:AddDivider()

ScreenGui.Parent = targetParent
