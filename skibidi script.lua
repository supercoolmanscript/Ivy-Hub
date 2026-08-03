-- ================================================================================
-- IVY HUB V2 - COMPACT EDITION (AUTO ST UNTOUCHED SNIPPET INTEGRATION)
-- Features: QB Aim (Exact Source Math & Engine), Auto ST (100% Untouched Engine),
--           NO OOB, Hider, uwu Magnets, Ball TP, Sticky Head, LegitPV, Advanced Tackle Reach,
--           Hitbox Expander, Loop Speed, Gravity, JP, Auto Stick, Tap Bumper, Auto Rocket,
--           Fling, Red Skybox, Potato Graphics, Stick Bump, Config Manager
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
    
    TackleReach = { Enabled = false, SizeX = 2.52, SizeY = 5.4, SizeZ = 1.41, Transparency = 0.7, Keybind = Enum.KeyCode.Unknown },
    HeadHitbox = { Enabled = false, HeadSize = 3.0, Transparency = 0.5, Keybind = Enum.KeyCode.Unknown },
    Speed = { Enabled = false, SpeedVal = 22.2, Keybind = Enum.KeyCode.Unknown },
    Gravity = { Enabled = false, GravityVal = 178.4, Keybind = Enum.KeyCode.Unknown },
    JP = { Enabled = false, JumpPower = 50, Cooldown = 1.15, Keybind = Enum.KeyCode.Unknown },
    
    AutoStick = { Enabled = false, ActivateDist = 1.9, LockInDist = 5, MaxStrength = 55, OffsetY = 2.8, BalanceRadius = 3.75, VertMin = -4, VertMax = 4, CorrSpeed = 0.55, Keybind = Enum.KeyCode.Unknown },
    StickBump = { Enabled = false, Power = 55, Range = 15, Keybind = Enum.KeyCode.Unknown },
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

-- ================================================================================
-- UNTOUCHED FOOTBALL DETECTOR (EXACT SNIPPET LOGIC)
-- ================================================================================
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
-- UNTOUCHED QB AIM MATH MODULE (EXACT SOURCE INTEGRATION)
-- ================================================================================
local QBAimMathModule = {}
do
    local ballGravity = 28
    local gravityVector = Vector3.new(0, -ballGravity, 0)
    local defaultBallSpeed = 95

    local function flat(v)
        return Vector3.new(v.X, 0, v.Z)
    end

    local function unit(v, fallback)
        if v.Magnitude < 1e-6 then
            return fallback or Vector3.new(1, 0, 0)
        end
        return v.Unit
    end

    local function clampMagnitude(v, maxMagnitude)
        if not v then
            return Vector3.zero
        end
        if v.Magnitude > maxMagnitude and maxMagnitude > 0 then
            return v.Unit * maxMagnitude
        end
        return v
    end

    local function distXZ(a, b)
        return (flat(b) - flat(a)).Magnitude
    end

    local function ballAt(originPosition, velocity, time)
        return originPosition + velocity * time + 0.5 * gravityVector * time * time
    end

    local function landing(originPosition, velocity)
        local discriminant = velocity.Y * velocity.Y + 2 * ballGravity * originPosition.Y
        if discriminant < 0 then return nil, nil end

        local time = (velocity.Y + math.sqrt(discriminant)) / ballGravity
        if time <= 0 then return nil, nil end

        return ballAt(originPosition, velocity, time), time
    end

    local function leadDelay(params, time)
        return math.max(params.leadDelay or 0, 0)
    end

    local function receiverMaxAt(position, catchY)
        return Vector3.new(position.X, catchY, position.Z)
    end

    local function targetAtTime(params, receiverStart, wrVel, time)
        local delay = leadDelay(params, time)
        local target = receiverStart + flat(wrVel) * (time + delay)
        local catchY = (params.catchY or receiverStart.Y) + (params.solveYBias or 0)
        return Vector3.new(target.X, catchY, target.Z), delay
    end

    local function interceptValue(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, time)
        local inheritance = params.qbInheritance or 0
        local inheritedVelocity = flat(qbVel or Vector3.zero) * inheritance
        local target = targetAtTime(params, receiverStart, wrVel, time)
        local neededDisplacement = target - originPosition - inheritedVelocity * time - 0.5 * gravityVector * time * time
        return neededDisplacement:Dot(neededDisplacement) - ballSpeed * ballSpeed * time * time
    end

    local function interceptLeadInfo(params, originPosition, target, wrVel, time, predictorState)
        local wrFlat = flat(wrVel)
        local speed = math.max(wrFlat.Magnitude, 1e-6)
        local losVector = flat(target - originPosition)
        local losDir = unit(losVector, wrFlat.Magnitude > 0 and wrFlat.Unit or Vector3.new(1, 0, 0))
        local away = wrFlat:Dot(losDir)
        local awayShare = math.clamp(away / speed, -1, 1)
        local lateralSpeed = (wrFlat - losDir * away).Magnitude
        local lateralShare = math.clamp(lateralSpeed / speed, 0, 1)
        local receiverPredictionDelay = leadDelay(params, time)
        local confidenceMin = params.predictorConfidenceMin or 0.30
        local confidenceMax = params.predictorConfidenceMax or 1.00
        local predictorConfidence = math.clamp(predictorState and predictorState.confidence or 1, confidenceMin, confidenceMax)
        local catchY = params.catchY or target.Y
        local leadBaseline = math.max(params.leadDelayBaseline or 0.01, 0.01)
        local leadValue = params.leadDelay or 0
        local tangentDenominator = awayShare * awayShare + lateralShare * lateralShare + (params.tangentDominanceEpsilon or 1e-6)

        return {
            flightLeadXZ = wrFlat * time,
            accelerationLeadXZ = Vector3.zero,
            extraLeadXZ = wrFlat * receiverPredictionDelay,
            radialExtraLeadXZ = Vector3.zero,
            tangentExtraLeadXZ = wrFlat * receiverPredictionDelay,
            extraLeadTime = receiverPredictionDelay,
            radialExtraTime = 0,
            tangentExtraTime = receiverPredictionDelay,
            tangentBaseTime = 0,
            tangentReactiveTime = receiverPredictionDelay,
            radialBaseTime = 0,
            radialLDTime = 0,
            adaptiveLeadScale = 1,
            leadUserScale = math.clamp(leadValue / leadBaseline, 0, 2.25),
            predictorConfidence = predictorConfidence,
            radialFlightScale = 1,
            tangentFlightScale = 1,
            accelTime = 0,
            magnitudeChangePotential = 0,
            c1Height = catchY,
            c1HeightMin = catchY,
            c1HeightMax = catchY,
            c1SolveYBias = params.solveYBias or 0,
            distance3DNow = (target - originPosition).Magnitude,
            distanceXZNow = distXZ(originPosition, target),
            distanceScale = 1,
            awayShare = awayShare,
            positiveAwayShare = math.clamp(awayShare, 0, 1),
            radialShareAbs = math.abs(awayShare),
            lateralShare = lateralShare,
            routeBalance = 1 - math.abs(math.abs(awayShare) - lateralShare),
            balanceLeadScale = 1,
            radialGain = 0,
            tangentGain = 0,
            losRate = 0,
            losDamping = 1,
            reactiveLosDamping = 1,
            tangentAlignment = 1,
            tangentAlignmentBoost = 1,
            tangentBalanceBoost = 1,
            tangentDominance = (lateralShare * lateralShare) / tangentDenominator,
            tangentBalancePeak = 1,
            tangentDominanceScale = 1,
            closingShare = math.clamp(-awayShare, 0, 1),
            tangentClosingScale = 1,
            tangentSignedScale = 1,
            routeAway = away,
            routeSide = lateralSpeed,
            routeElevation = 0,
            routeSpeed = wrFlat.Magnitude,
            fixedIntercept = true,
            mathOk = true,
            receiverPredictionDelay = receiverPredictionDelay,
            receiverPredictionDelayScale = leadValue > 0 and receiverPredictionDelay / leadValue or 0,
        }
    end

    local function interceptCandidate(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, time, shape, predictorState, includeLeadInfo)
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
        local catchY = (params.catchY or receiverStart.Y) + (params.solveYBias or 0)
        local yError = math.abs(catchPosition.Y - catchY)
        local speedError = math.abs(requiredSpeed - ballSpeed)
        local residual = math.abs(interceptValue(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, time))
        local verticalVelocityAtCatch = worldVelocity.Y + gravityVector.Y * time
        local landingPosition, landingTime = landing(originPosition, worldVelocity)
        local leadDistance = flat(wrVel).Magnitude * receiverLeadDelay

        return {
            score = targetMiss * 1000 + speedError * 100 + time * 0.5 + math.max(verticalVelocityAtCatch - 10, 0) * 0.25,
            time = time,
            totalLeadTime = time + receiverLeadDelay,
            receiverPredictionDelay = receiverLeadDelay,
            receiverPredictionDelayScale = (params.leadDelay or 0) > 0 and receiverLeadDelay / (params.leadDelay or 1) or 0,
            receiverLeadDistance = leadDistance,
            origin = originPosition,
            target = target,
            c1Point = target,
            requiredVelocity = requiredVelocity,
            requiredSpeed = requiredSpeed,
            direction = direction,
            throwVelocity = throwVelocity,
            worldVelocity = worldVelocity,
            velocity = worldVelocity,
            speed = ballSpeed,
            aimPoint = originPosition + direction * (params.aimScale or 1000),
            angleDeg = angle,
            preferredAngle = angle,
            minDesiredAngle = params.minAngle or -5,
            maxAngle = params.maxAngle or 55,
            totalErr = targetMiss,
            targetMiss = targetMiss,
            yError = yError,
            speedError = speedError,
            verticalVelocityAtCatch = verticalVelocityAtCatch,
            interceptResidual = residual,
            missEstimate = targetMiss,
            ballAtCatch = catchPosition,
            landing = landingPosition,
            landingTime = landingTime,
            flatDistNow = distXZ(originPosition, receiverStart),
            movementShape = shape,
            predictorState = predictorState,
            leadInfo = includeLeadInfo and interceptLeadInfo(params, originPosition, target, wrVel, time, predictorState) or nil,
            mathOk = true,
        }
    end

    local function betterIntercept(candidate, current)
        if not current then return true end
        if candidate.score + 1e-6 < current.score then return true end
        if current.score + 1e-6 < candidate.score then return false end
        return candidate.time < current.time
    end

    local function refineInterceptTime(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, lo, hi, loValue)
        local low = lo
        local high = hi
        local lowValue = loValue or interceptValue(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, low)

        for _ = 1, (params.bisectionSteps or 12) do
            local mid = (low + high) * 0.5
            local midValue = interceptValue(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, mid)

            if math.abs(midValue) < 1e-5 then
                return mid
            end

            if (lowValue < 0 and midValue > 0) or (lowValue > 0 and midValue < 0) then
                high = mid
            else
                low = mid
                lowValue = midValue
            end
        end

        return (low + high) * 0.5
    end

    function QBAimMathModule.ballAt(originPosition, velocity, time)
        return ballAt(originPosition, velocity, time)
    end

    function QBAimMathModule.solve(params)
        local ballSpeed = params.ballPower or defaultBallSpeed
        local qbReleaseOffset = params.qbReleaseOffset or 0
        local receiverReleaseOffset = params.receiverReleaseOffset
        if receiverReleaseOffset == nil then
            receiverReleaseOffset = qbReleaseOffset
        end

        local maxRunSpeed = params.maxRunSpeed or 21
        local wrVel = clampMagnitude(flat(params.targetVelocity or Vector3.zero), maxRunSpeed)
        local qbVel = clampMagnitude(flat(params.qbVelocity or Vector3.zero), maxRunSpeed)
        local originPosition = params.originPosition
        local receiverBasePosition = params.receiverAnchorPosition or params.receiverPosition
        if not (originPosition and receiverBasePosition) then
            return nil
        end

        local receiverReleasePosition = receiverBasePosition + wrVel * receiverReleaseOffset
        local receiverStart = receiverMaxAt(receiverReleasePosition, params.catchY or receiverReleasePosition.Y)
        local bestRoot = nil
        local bestNear = nil
        local minT = params.minTime or 0.35
        local maxT = params.maxTime or 6
        local dt = params.dt or 0.01
        local previousTime = minT
        local previousValue = interceptValue(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, previousTime)

        local function considerNear(time)
            local candidate = interceptCandidate(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, time, params.shape, params.predictorState, false)
            if candidate and candidate.targetMiss <= (params.nearTargetMissTolerance or 0.05) and candidate.yError <= (params.catchYTolerance or 0.35) and betterIntercept(candidate, bestNear) then
                bestNear = candidate
            end
        end

        local function considerRoot(time)
            local candidate = interceptCandidate(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, time, params.shape, params.predictorState, false)
            if candidate and candidate.targetMiss <= (params.targetMissTolerance or 0.35) and candidate.yError <= (params.catchYTolerance or 0.35) and betterIntercept(candidate, bestRoot) then
                bestRoot = candidate
            end
        end

        considerNear(previousTime)

        for time = minT + dt, maxT, dt do
            local value = interceptValue(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, time)
            considerNear(time)

            if math.abs(value) < 1e-8 then
                considerRoot(time)
            elseif math.abs(previousValue) < 1e-8 then
                considerRoot(previousTime)
            elseif (previousValue < 0 and value > 0) or (previousValue > 0 and value < 0) then
                considerRoot(refineInterceptTime(params, originPosition, receiverStart, wrVel, qbVel, ballSpeed, previousTime, time, previousValue))
            end

            previousTime = time
            previousValue = value
        end

        local best = bestRoot or bestNear
        if best and not best.leadInfo then
            best.leadInfo = interceptLeadInfo(params, originPosition, best.target, wrVel, best.time, params.predictorState)
        end
        if best then
            best.qbReleaseOffset = qbReleaseOffset
            best.qbSharedReleaseOffset = qbReleaseOffset
            best.receiverReleaseOffset = receiverReleaseOffset
            best.receiverAnchorSource = params.receiverAnchorSource or "root"
            best.receiverAnchorPosition = receiverBasePosition
            best.futureReleaseOriginLatch = qbReleaseOffset > 0
            best.remoteFireDelayed = params.remoteFireDelayed ~= false
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
-- 2. STICKY HEAD MECHANIC (HOLD KEYBIND - DYNAMIC HITBOX SWITCHING)
----------------------------------------------------------------------------------
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
-- 3. UNTOUCHED AUTO ST CORE ENGINE (EXACT KINEMATIC SOLVER & ALIGNMENT)
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
        -- 1. Calculate Estimated Right Shoulder Position (~1.5 studs to local right)
        local rightShoulderPos = hrpPos + (hrp.CFrame.RightVector * 1.5)
        
        -- 2. Solve Trajectory Intercept relative to the Right Shoulder
        local targetPos = solveInterceptPoint(rightShoulderPos, ballPos, ballVel) or ballPos
        local dirXZ = Vector3.new(targetPos.X - hrpPos.X, 0, targetPos.Z - hrpPos.Z)
        
        if dirXZ.Magnitude > 0.1 then
            local unitDir = dirXZ.Unit
            
            -- 3. Dead-Center Alignment: Orient LookVector perpendicular so Right Arm points directly at ball
            local naturalLook = Vector3.new(unitDir.Z, 0, -unitDir.X)
            local targetCFrame = CFrame.lookAt(hrpPos, hrpPos + naturalLook)
            
            -- 4. Smoothness Math: Converts 1-100 scale to Lerp Alpha
            local smoothVal = math.clamp(tonumber(_G.HubConfig.AutoST.Smoothness) or 25, 1, 100)
            local lerpAlpha = math.clamp((101 - smoothVal) / 100, 0.05, 1.0)
            
            -- Apply smooth horizontal alignment
            hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, lerpAlpha)
        end
    end
end)

----------------------------------------------------------------------------------
-- 4. AUTO STICK ENGINE (DYNAMIC HITBOX SWITCHING)
----------------------------------------------------------------------------------
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
            if (hum.MoveDirection.Magnitude > 0) or isPlayerDiving(hum) then
                nudgeActive = false
            end
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

----------------------------------------------------------------------------------
-- STICK BUMP ENGINE
----------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.StickBump or not _G.HubConfig.StickBump.Enabled then return end
    local char, hrp, hum = getChar()
    if not char or not hrp or not hum then return end

    local range = tonumber(_G.HubConfig.StickBump.Range) or 15
    local power = tonumber(_G.HubConfig.StickBump.Power) or 55

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eHrp = p.Character:FindFirstChild("HumanoidRootPart")
            if eHrp then
                local dist = (hrp.Position - eHrp.Position).Magnitude
                if dist <= range then
                    local dir = (eHrp.Position - hrp.Position).Unit
                    hrp.AssemblyLinearVelocity = Vector3.new(dir.X * power, hrp.AssemblyLinearVelocity.Y, dir.Z * power)
                    break
                end
            end
        end
    end
end)

----------------------------------------------------------------------------------
-- 5. AUTO ROCKET ENGINE
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
-- 6. UWU MAGNETS & BALL TP (BTP)
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
-- 7. TACKLE REACH ENGINE (ADVANCED WORKSPACE HITBOX OVERRIDE SYSTEM)
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
                if part.Transparency ~= targetTrans then
                    part.Transparency = targetTrans
                end
                if part.Size ~= targetSize then
                    part.Size = targetSize
                end
            else
                if w.origT[part] ~= nil and part.Transparency ~= w.origT[part] then
                    part.Transparency = w.origT[part]
                end
                if w.origS[part] ~= nil and part.Size ~= w.origS[part] then
                    part.Size = w.origS[part]
                end
            end
        end
    end
end

local function trackReachPart(w, part)
    if not part:IsA("BasePart") then return end

    if not table.find(w.parts, part) then
        table.insert(w.parts, part)
    end

    if reachOriginalParts.Transparency[part] == nil then
        reachOriginalParts.Transparency[part] = part.Transparency
    end
    if reachOriginalParts.Size[part] == nil then
        reachOriginalParts.Size[part] = part.Size
    end

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

        table.insert(w.partConns[part], part.AncestryChanged:Connect(function(_, instParent)
            if instParent == nil then
                safeDisconnectConns(w.partConns[part])
                w.partConns[part] = nil
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
        if descendant:IsA("BasePart") then
            trackReachPart(w, descendant)
        end
    end

    if node:IsA("BasePart") then
        trackReachPart(w, node)
    end

    table.insert(w.cons, node.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            trackReachPart(w, descendant)
        end
    end))

    table.insert(w.cons, node.AncestryChanged:Connect(function(_, instParent)
        if instParent == nil then
            applyReachVisuals(w, false)
            for _, conns in pairs(w.partConns) do
                safeDisconnectConns(conns)
            end
            w.partConns = setmetatable({}, {__mode = "k"})
            safeDisconnectConns(w.cons)
            reachWatchers[node] = nil
        end
    end))

    applyReachVisuals(w, _G.HubConfig.TackleReach.Enabled)
end

local function hookHitboxesFolder(hitboxes)
    if not hitboxes then return end
    local w = ensureReachWatcher(hitboxes)
    if w.attached then return end
    w.attached = true

    local myNode = hitboxes:FindFirstChild(LocalPlayer.Name)
    if myNode then
        attachReachNode(myNode)
    end

    table.insert(w.cons, hitboxes.ChildAdded:Connect(function(child)
        if child.Name == LocalPlayer.Name then
            attachReachNode(child)
        end
    end))

    table.insert(w.cons, hitboxes.AncestryChanged:Connect(function(_, instParent)
        if instParent == nil then
            safeDisconnectConns(w.cons)
            reachWatchers[hitboxes] = nil
        end
    end))
end

local function attachReachGameFolder(gameFolder)
    if not gameFolder then return end
    local w = ensureReachWatcher(gameFolder)
    if w.attached then return end
    w.attached = true

    local replicated = gameFolder:FindFirstChild("Replicated")
    local hitboxes = replicated and replicated:FindFirstChild("Hitboxes")
    if hitboxes then hookHitboxesFolder(hitboxes) end

    table.insert(w.cons, gameFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Folder") or descendant:IsA("Model") then
            if descendant.Name == "Hitboxes" and descendant.Parent and descendant.Parent.Name == "Replicated" then
                hookHitboxesFolder(descendant)
            elseif descendant.Name == LocalPlayer.Name and descendant.Parent and descendant.Parent.Name == "Hitboxes" then
                attachReachNode(descendant)
            end
        end
    end))

    table.insert(w.cons, gameFolder.AncestryChanged:Connect(function(_, instParent)
        if instParent == nil then
            safeDisconnectConns(w.cons)
            reachWatchers[gameFolder] = nil
        end
    end))
end

local function attachReachMiniGameFolder(miniGameFolder)
    if not miniGameFolder then return end
    local w = ensureReachWatcher(miniGameFolder)
    if w.attached then return end
    w.attached = true

    local replicated = miniGameFolder:FindFirstChild("Replicated")
    local hitboxes = replicated and replicated:FindFirstChild("Hitboxes")
    if hitboxes then hookHitboxesFolder(hitboxes) end

    table.insert(w.cons, miniGameFolder.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Folder") or descendant:IsA("Model") then
            if descendant.Name == "Hitboxes" and descendant.Parent and descendant.Parent.Name == "Replicated" and descendant.Parent.Parent == miniGameFolder then
                hookHitboxesFolder(descendant)
            elseif descendant.Name == LocalPlayer.Name and descendant.Parent and descendant.Parent.Name == "Hitboxes" and descendant.Parent.Parent and descendant.Parent.Parent.Name == "Replicated" and descendant.Parent.Parent.Parent == miniGameFolder then
                attachReachNode(descendant)
            end
        end
    end))

    table.insert(w.cons, miniGameFolder.AncestryChanged:Connect(function(_, instParent)
        if instParent == nil then
            safeDisconnectConns(w.cons)
            reachWatchers[miniGameFolder] = nil
        end
    end))
end

local function updateAllReachWatchers()
    for _, w in pairs(reachWatchers) do
        if type(w) == "table" and w.parts then
            applyReachVisuals(w, _G.HubConfig.TackleReach.Enabled)
        end
    end
end

local function scanReachWorkspace()
    local games = Workspace:FindFirstChild("Games")
    if games then
        local w = ensureReachWatcher(games)
        if not w.attached then
            w.attached = true
            table.insert(w.cons, games.ChildAdded:Connect(function(gFolder) attachReachGameFolder(gFolder) end))
        end
        for _, gFolder in ipairs(games:GetChildren()) do attachReachGameFolder(gFolder) end
    end

    local miniGames = Workspace:FindFirstChild("MiniGames")
    if miniGames then
        local w = ensureReachWatcher(miniGames)
        if not w.attached then
            w.attached = true
            table.insert(w.cons, miniGames.ChildAdded:Connect(function(mgFolder) attachReachMiniGameFolder(mgFolder) end))
        end
        for _, mgFolder in ipairs(miniGames:GetChildren()) do attachReachMiniGameFolder(mgFolder) end
    end
end

-- Initialize Workspace Watcher Loop for Tackle Reach
task.spawn(function()
    task.wait(0.5)
    scanReachWorkspace()
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "Games" or child.Name == "MiniGames" then
            task.defer(scanReachWorkspace)
        end
    end)
end)

-- Continuous state listener / refresh loop
RunService.Heartbeat:Connect(function()
    updateAllReachWatchers()
end)

----------------------------------------------------------------------------------
-- 8. QB AIM TARGETING & EXECUTION ENGINE LOOPS
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
                local sameTeam = false
                pcall(function()
                    local myTeam = LocalPlayer:FindFirstChild("Replicated") and LocalPlayer.Replicated:FindFirstChild("TeamID") and LocalPlayer.Replicated.TeamID.Value
                    local pTeam = p:FindFirstChild("Replicated") and p.Replicated:FindFirstChild("TeamID") and p.Replicated.TeamID.Value
                    if myTeam and pTeam and myTeam == pTeam then sameTeam = true end
                end)

                if not _G.HubConfig.QBAim.TeamFilter or sameTeam then
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
            for _, folder in ipairs({Workspace:FindFirstChild("Games"), ReplicatedStorage:FindFirstChild("Games"), Workspace:FindFirstChild("MiniGames"), ReplicatedStorage:FindFirstChild("MiniGames")}) do
                if folder then
                    for _, gameInst in ipairs(folder:GetChildren()) do
                        local re = gameInst:FindFirstChild("ReEvent") or (gameInst:FindFirstChild("Replicated") and gameInst.Replicated:FindFirstChild("ReEvent"))
                        if re then gameEv = re break end
                    end
                end
            end
        end)

        if gameEv then
            gameEv:FireServer("Mechanics", "ThrowBall", {
                Target = plan.aimPoint,
                AutoThrow = false,
                Power = 100
            })
        end
    end
end

----------------------------------------------------------------------------------
-- 9. NO OOB (NO OUT OF BOUNDS) ENGINE (OPTIMIZED TO PREVENT LAG)
----------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if _G.HubConfig.NoOOB and _G.HubConfig.NoOOB.Enabled then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("BasePart") then
                    local name = obj.Name:lower()
                    if name:find("oob") or name:find("outofbounds") or name:find("out_of_bounds") or name:find("sideline") or name:find("border") then
                        if obj.CanTouch then
                            obj.CanTouch = false
                        end
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not _G.HubConfig.NoOOB or not _G.HubConfig.NoOOB.Enabled then return end

    local ball = findFootballPart()
    local char, hrp = getChar()
    if not char or not hrp or not ball then return end

    local isHolding = (ball.Position - hrp.Position).Magnitude <= 10 or ball:IsDescendantOf(char)
    if not isHolding then return end

    local ray = Workspace:Raycast(hrp.Position + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0))
    if ray and ray.Instance then
        local hitName = ray.Instance.Name:lower()
        if hitName:find("oob") or hitName:find("out") or hitName:find("sideline") then
            local pushDir = (Vector3.new(0, hrp.Position.Y, 0) - hrp.Position).Unit
            hrp.AssemblyLinearVelocity = Vector3.new(pushDir.X * 15, hrp.AssemblyLinearVelocity.Y, pushDir.Z * 15)
        end
    end
end)

----------------------------------------------------------------------------------
-- 10. CROZO HITBOX ENGINE (COLLIDABLE HUMANOIDROOTPART SYSTEM)
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

                    if eHrp.Size ~= targetSize then
                        eHrp.Size = targetSize
                    end
                    if eHrp.Transparency ~= transVal then
                        eHrp.Transparency = transVal
                    end
                    if eHrp.CanCollide ~= true then
                        eHrp.CanCollide = true
                    end
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
-- 11. VISUALS & ENVIRONMENT
----------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if _G.HubConfig.RedSky.Enabled then
            Lighting.Brightness = tonumber(_G.HubConfig.RedSky.Brightness) or 2
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 30, 30)
            Lighting.FogColor = Color3.fromRGB(150, 0, 0)
            Lighting.FogEnd = 500
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
-- 12. MOVEMENT & PHYSICAL OVERRIDES
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
-- IVY HUB COMPACT ORGANIC GUI FRAMEWORK (TOP-LAYER PRIORITY)
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
    CardHover = Color3.fromRGB(24, 42, 31),
    Accent = Color3.fromRGB(50, 220, 110),
    Glow = Color3.fromRGB(0, 255, 140),
    DarkVine = Color3.fromRGB(22, 70, 40),
    Text = Color3.fromRGB(240, 250, 244),
    SubText = Color3.fromRGB(140, 180, 155),
    InputBg = Color3.fromRGB(12, 24, 18)
}

-- Compact Main Window Frame
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

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)

-- Animated Moving Vine Background Canvas Engine
local VineCanvas = Instance.new("Frame", MainFrame)
VineCanvas.Name = "VineCanvas"
VineCanvas.Size = UDim2.new(1, 0, 1, 0)
VineCanvas.BackgroundTransparency = 1
VineCanvas.ClipsDescendants = true
VineCanvas.ZIndex = 0

local function SpawnMovingVineLeaf()
    local Leaf = Instance.new("TextLabel", VineCanvas)
    Leaf.Size = UDim2.new(0, 14, 0, 14)
    Leaf.Position = UDim2.new(math.random(), 0, 1, 10)
    Leaf.Text = "🌿"
    Leaf.TextSize = math.random(8, 12)
    Leaf.BackgroundTransparency = 1
    Leaf.TextTransparency = 0.75
    Leaf.Rotation = math.random(0, 360)

    local speed = math.random(8, 15)
    local swayAmplitude = math.random(10, 25)
    local startX = Leaf.Position.X.Scale
    local conn

    conn = RunService.RenderStepped:Connect(function(dt)
        if not Leaf or not Leaf.Parent then conn:Disconnect() return end
        local newY = Leaf.Position.Y.Scale - (dt * (speed / 100))
        local sway = math.sin(tick() * 2 + speed) * (swayAmplitude / 1000)
        Leaf.Position = UDim2.new(startX + sway, 0, newY, 0)
        Leaf.Rotation = (Leaf.Rotation + dt * 25) % 360
        if newY < -0.1 then
            Leaf:Destroy()
            conn:Disconnect()
        end
    end)
end

task.spawn(function()
    while MainFrame and MainFrame.Parent do
        SpawnMovingVineLeaf()
        task.wait(1.5)
    end
end)

-- Pulsating Glowing Vine Border
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 2.0
MainStroke.Transparency = 0.1

local VineGradient = Instance.new("UIGradient", MainStroke)
VineGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.DarkVine),
    ColorSequenceKeypoint.new(0.25, THEME.Accent),
    ColorSequenceKeypoint.new(0.5, THEME.Glow),
    ColorSequenceKeypoint.new(0.75, THEME.Accent),
    ColorSequenceKeypoint.new(1, THEME.DarkVine)
})
VineGradient.Rotation = 45

local step = 0
RunService.RenderStepped:Connect(function(dt)
    step = (step + dt * 0.4) % 1
    VineGradient.Offset = Vector2.new(math.sin(step * math.pi * 2) * 0.5, math.cos(step * math.pi * 2) * 0.5)
    VineGradient.Rotation = (VineGradient.Rotation + dt * 25) % 360
end)

-- Compact Header Bar
local Header = Instance.new("Frame", MainFrame)
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = THEME.Header
Header.BackgroundTransparency = 0.2
Header.ZIndex = 2
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "🌿 IVY <font color=\"rgb(50, 220, 110)\">HUB</font> <font size=\"8\" color=\"rgb(140, 180, 155)\">V2</font>"
Title.RichText = true
Title.TextColor3 = THEME.Text
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

-- Compact Sidebar Panel
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 105, 1, -34)
Sidebar.Position = UDim2.new(0, 0, 0, 34)
Sidebar.BackgroundColor3 = THEME.Sidebar
Sidebar.BackgroundTransparency = 0.4
Sidebar.ZIndex = 2
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)

local TabScroll = Instance.new("ScrollingFrame", Sidebar)
TabScroll.Size = UDim2.new(1, -4, 1, -6)
TabScroll.Position = UDim2.new(0, 2, 0, 3)
TabScroll.BackgroundTransparency = 1
TabScroll.ScrollBarThickness = 2
TabScroll.ScrollBarImageColor3 = THEME.Accent
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local TabListLayout = Instance.new("UIListLayout", TabScroll)
TabListLayout.Padding = UDim.new(0, 3)
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -112, 1, -38)
ContentArea.Position = UDim2.new(0, 110, 0, 34)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 2

local CyberGUI = { Tabs = {}, KeybindRegistry = {}, RefreshCallbacks = {} }

-- Keybind Listener System (Unblocked InputEnded)
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
    if not keyCode or typeof(keyCode) ~= "EnumItem" or keyCode == Enum.KeyCode.Unknown then
        return "N/A"
    end
    return keyCode.Name:gsub("Button", ""):gsub("DPad", "DPad ")
end

function CyberGUI:RefreshAllUI()
    for _, callback in ipairs(CyberGUI.RefreshCallbacks) do
        pcall(callback)
    end
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
    Container.ScrollBarImageColor3 = THEME.Accent
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

        local CardStroke = Instance.new("UIStroke", Card)
        CardStroke.Color = THEME.DarkVine
        CardStroke.Thickness = 1

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
            TweenService:Create(ToggleBtn, TweenInfo.new(0.18), {
                BackgroundColor3 = state and THEME.Accent or Color3.fromRGB(35, 50, 40)
            }):Play()
            TweenService:Create(Knob, TweenInfo.new(0.18), {
                Position = state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
            }):Play()
            TweenService:Create(CardStroke, TweenInfo.new(0.18), {
                Color = state and THEME.Accent or THEME.DarkVine
            }):Play()
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

        local function UpdateVisuals()
            InputBox.Text = tostring(configRef[configKey] or "")
        end

        local function UpdateValue()
            local rawText = InputBox.Text
            local num = tonumber(rawText)
            if num then
                configRef[configKey] = num
            else
                configRef[configKey] = rawText
            end
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
                if toggleRef and type(toggleRef) == "table" and toggleRef.SetState then 
                    toggleRef.SetState(state) 
                end
            end
        }

        BindBtn.MouseButton1Click:Connect(function()
            BindBtn.Text = "..."
            BindBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
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

        local LineGradient = Instance.new("UIGradient", Line)
        LineGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 22, 17)),
            ColorSequenceKeypoint.new(0.5, THEME.Accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 22, 17))
        })

        local CenterDot = Instance.new("TextLabel", Divider)
        CenterDot.Size = UDim2.new(0, 10, 0, 10)
        CenterDot.Position = UDim2.new(0.5, -5, 0.5, -5)
        CenterDot.Text = "🌿"
        CenterDot.TextSize = 7
        CenterDot.BackgroundTransparency = 1
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
QbABTab:AddKeybinder("Lock WR", _G.HubConfig.QBAim, "LockKeybind", nil, false, true, function()
    qbTargetPlayer = getBestQBTarget()
end)
QbABTab:AddKeybinder("Throw Ball", _G.HubConfig.QBAim, "ThrowKeybind", nil, false, true, function()
    executeQBThrow()
end)
QbABTab:AddKeybinder("Toggle Qb AB", _G.HubConfig.QBAim, "ToggleKeybind", qbEnableTgl)
QbABTab:AddDivider()

-- 2. Auto ST Tab
local AutoSTTab = CyberGUI:CreateTab("Auto ST")
autoSTTgl = AutoSTTab:AddToggle("Auto ST Active", _G.HubConfig.AutoST, "Enabled")
AutoSTTab:AddValueChanger("Detection Range", _G.HubConfig.AutoST, "DetectionRange")
AutoSTTab:AddValueChanger("Smoothness", _G.HubConfig.AutoST, "Smoothness")
AutoSTTab:AddKeybinder("Auto ST", _G.HubConfig.AutoST, "Keybind", autoSTTgl, true)
AutoSTTab:AddDivider()

-- 3. Auto Stick Tab
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

-- 4. Stick Bump Tab
local StickBumpTab = CyberGUI:CreateTab("Stick Bump")
local stickBumpTgl = StickBumpTab:AddToggle("Stick Bump", _G.HubConfig.StickBump, "Enabled")
StickBumpTab:AddValueChanger("Bump Power", _G.HubConfig.StickBump, "Power")
StickBumpTab:AddValueChanger("Detection Range", _G.HubConfig.StickBump, "Range")
StickBumpTab:AddKeybinder("Stick Bump", _G.HubConfig.StickBump, "Keybind", stickBumpTgl)
StickBumpTab:AddDivider()

-- 5. Tap Bumper Tab
local TapBumperTab = CyberGUI:CreateTab("Tap Bumper")
local tapBumperTgl = TapBumperTab:AddToggle("Tap Bumper", _G.HubConfig.TapBumper, "Enabled")
TapBumperTab:AddValueChanger("Launch Force", _G.HubConfig.TapBumper, "Force")
TapBumperTab:AddKeybinder("Tap Bumper", _G.HubConfig.TapBumper, "Keybind", nil, false, true, triggerTapBumperImpulse)
TapBumperTab:AddDivider()

-- 6. Auto Rocket Tab
local AutoRocketTab = CyberGUI:CreateTab("Auto Rocket")
local autoRocketTgl = AutoRocketTab:AddToggle("Auto Rocket", _G.HubConfig.AutoRocket, "Enabled")
AutoRocketTab:AddToggle("Head Only Velocity", _G.HubConfig.AutoRocket, "HeadOnly")
AutoRocketTab:AddValueChanger("Dive Power", _G.HubConfig.AutoRocket, "Power")
AutoRocketTab:AddKeybinder("Auto Rocket", _G.HubConfig.AutoRocket, "Keybind", autoRocketTgl)
AutoRocketTab:AddDivider()

-- 7. Fling Tab
local FlingTab = CyberGUI:CreateTab("Fling")
local flingTgl = FlingTab:AddToggle("Fling Active", _G.HubConfig.Fling, "Enabled")
FlingTab:AddValueChanger("Fling Power", _G.HubConfig.Fling, "Power")
FlingTab:AddKeybinder("Fling Action", _G.HubConfig.Fling, "Keybind", flingTgl, false, true, triggerFlingBoost)
FlingTab:AddDivider()

-- 8. Sticky Tab (Hold Keybind)
local StickyTab = CyberGUI:CreateTab("Sticky")
local stickyTgl = StickyTab:AddToggle("Sticky Head", _G.HubConfig.Sticky, "Enabled")
StickyTab:AddValueChanger("Detection Range", _G.HubConfig.Sticky, "Range")
StickyTab:AddValueChanger("Smoothness", _G.HubConfig.Sticky, "Smoothness")
StickyTab:AddValueChanger("Strength", _G.HubConfig.Sticky, "Strength")
StickyTab:AddKeybinder("Sticky Head", _G.HubConfig.Sticky, "Keybind", stickyTgl, true)
StickyTab:AddDivider()

-- 9. BTP & Magnet Tab
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

-- 10. LegitPV Tab (Hold Keybind)
local PVTab = CyberGUI:CreateTab("LegitPV")
local pvTgl = PVTab:AddToggle("Pull Vector Assist", _G.HubConfig.LegitPV, "Enabled")
PVTab:AddValueChanger("Pull Vector Strength", _G.HubConfig.LegitPV, "PullVec")
PVTab:AddValueChanger("Max Distance", _G.HubConfig.LegitPV, "MaxDist")
PVTab:AddKeybinder("LegitPV", _G.HubConfig.LegitPV, "Keybind", pvTgl, true)
PVTab:AddDivider()

-- 11. Tackle Reach Tab
local ReachTab = CyberGUI:CreateTab("Tackle Reach")
local reachTgl = ReachTab:AddToggle("Tackle Reach", _G.HubConfig.TackleReach, "Enabled")
ReachTab:AddValueChanger("Reach Size X", _G.HubConfig.TackleReach, "SizeX")
ReachTab:AddValueChanger("Reach Size Y", _G.HubConfig.TackleReach, "SizeY")
ReachTab:AddValueChanger("Reach Size Z", _G.HubConfig.TackleReach, "SizeZ")
ReachTab:AddValueChanger("Transparency", _G.HubConfig.TackleReach, "Transparency")
ReachTab:AddKeybinder("Tackle Reach", _G.HubConfig.TackleReach, "Keybind", reachTgl)
ReachTab:AddDivider()

-- 12. Movement & Physics Tab
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

-- 13. Visuals Tab
local VisualsTab = CyberGUI:CreateTab("Visuals")
local redSkyTgl = VisualsTab:AddToggle("Red Skybox", _G.HubConfig.RedSky, "Enabled")
VisualsTab:AddValueChanger("Sky Brightness", _G.HubConfig.RedSky, "Brightness")
VisualsTab:AddKeybinder("Red Sky", _G.HubConfig.RedSky, "Keybind", redSkyTgl)
VisualsTab:AddDivider()

local potatoTgl = VisualsTab:AddToggle("potato graphics", _G.HubConfig.PotatoGraphics, "Enabled")
VisualsTab:AddKeybinder("potato graphics", _G.HubConfig.PotatoGraphics, "Keybind", potatoTgl)
VisualsTab:AddDivider()

-- 14. Hitbox Expander Tab
local HitboxTab = CyberGUI:CreateTab("Hitbox")
local headTgl = HitboxTab:AddToggle("Hitbox Expander", _G.HubConfig.HeadHitbox, "Enabled")
HitboxTab:AddValueChanger("Hitbox Size", _G.HubConfig.HeadHitbox, "HeadSize")
HitboxTab:AddValueChanger("Transparency", _G.HubConfig.HeadHitbox, "Transparency")
HitboxTab:AddKeybinder("Hitbox Expander", _G.HubConfig.HeadHitbox, "Keybind", headTgl)
HitboxTab:AddDivider()

-- 15. Misc Tab & Config Manager Engine
local MiscTab = CyberGUI:CreateTab("Misc")

MiscTab:AddKeybinder("Gui Toggle", _G.HubConfig.Misc, "Keybind", nil, false, true, function()
    MainFrame.Visible = not MainFrame.Visible
end)
MiscTab:AddDivider()

-- HIDER FEATURE
local hiderTgl = MiscTab:AddToggle("Hider", _G.HubConfig.Misc, "Hider", function(state)
    if state then
        runHiderLogic()
    elseif hiderConnection then
        hiderConnection:Disconnect()
        hiderConnection = nil
    end
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
                    if fileName then
                        table.insert(cfgs, fileName)
                    end
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

ConfigInputBox:GetPropertyChangedSignal("Text"):Connect(function()
    currentConfigName = ConfigInputBox.Text
end)

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
DropBtn.Text = "Choose... 🔻"
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

-- Status / Autoload Indicator Card
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

-- Config Action Buttons Builder
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

-- ================================================================================
-- AUTOLOAD EXECUTION ON BOOT
-- ================================================================================
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
