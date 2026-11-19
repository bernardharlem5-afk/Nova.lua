

local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/PookiePepelsss/Airflow-UI/refs/heads/main/Source.luau"))()
Airflow:LoadFont({Name = "ValleySans"})

Airflow.Themes.FatalBlue = {
    Background  = Color3.fromRGB(5,   10,  22),
    Surface     = Color3.fromRGB(9,   16,  34),
    Surface2    = Color3.fromRGB(13,  22,  45),
    Surface3    = Color3.fromRGB(20,  32,  60),
    Stroke      = Color3.fromRGB(28,  45,  90),
    StrokeHover = Color3.fromRGB(55,  90, 180),
    Accent      = Color3.fromRGB(60,  120, 255),
    AccentDark  = Color3.fromRGB(8,   18,  50),
    Text        = Color3.fromRGB(220, 230, 255),
    Muted       = Color3.fromRGB(110, 140, 200),
    Glow        = Color3.fromRGB(60,  120, 255),
    Warning     = Color3.fromRGB(240, 176, 108),
    Success     = Color3.fromRGB(150, 220, 170),
    Error       = Color3.fromRGB(240, 120, 120),
}

Airflow.Assets.Logo = "rbxassetid://85087336560627"

-- ============================================================
-- GAME ID WHITELIST
-- ============================================================
local ARCADE_IDS = {
    [134558434771720] = true,
    [130736793665498] = true,
    [92216849541624]  = true,
    [95439417741900]  = true,
}

local BL_IDS = {
    [14386691987]    = true,
    [71832465156084] = true,
    [17652855195]    = true,
}

local isArcade = ARCADE_IDS[game.PlaceId] == true
local isBL     = BL_IDS[game.PlaceId] == true

-- ============================================================
-- SHARED THEME
-- ============================================================


-- ============================================================
-- SHARED SERVICES
-- ============================================================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInput        = game:GetService("VirtualInputManager")
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local CoreGui             = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local isMobile    = UserInputService.TouchEnabled

-- ============================================================
-- SHARED HVH ENGINE (HipHeight + Swim + Speed + InfJump)
-- ============================================================
local HVH = {
    active = false,
    conn = nil,
    swimEngaged = false,
    infJumpState = {
        conn = nil,
        charBind = nil,
    },
    cfg = nil,
}

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char,
        char:FindFirstChild("Humanoid"),
        char:FindFirstChild("HumanoidRootPart")
end

-- One extra jump while airborne. Sets a fixed upward speed (a normal jump times the
-- Infinite Jump power) once, with a cooldown, so it can never build up or run away.
local function infJumpTry(hum, hrp, onlyWhenFalling)
    local cfg = HVH.cfg
    if not cfg or not cfg.InfiniteJump.Enabled then return end
    local now = os.clock()
    if now - (HVH.lastInfJump or 0) < 0.25 then return end
    -- Only a limited number of air jumps; landing resets the count.
    if (HVH.airJumps or 0) >= (cfg.InfiniteJump.Count or 2) then return end
    local st = hum:GetState()
    if st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Jumping then
        return
    end
    local v = hrp.AssemblyLinearVelocity
    if onlyWhenFalling and v.Y > 0 then return end
    HVH.lastInfJump = now
    HVH.airJumps = (HVH.airJumps or 0) + 1
    local base = hum.UseJumpPower and hum.JumpPower
        or math.sqrt(2 * workspace.Gravity * hum.JumpHeight)
    local jumpSpeed = math.clamp(base * (cfg.InfiniteJump.Power or 1), 10, 120)
    hrp.AssemblyLinearVelocity = Vector3.new(v.X, jumpSpeed, v.Z)
end

local function hvhStart()
    if HVH.conn then HVH.conn:Disconnect(); HVH.conn = nil end
    if HVH.infJumpState.conn then HVH.infJumpState.conn:Disconnect(); HVH.infJumpState.conn = nil end
    if not HVH.cfg then return end

    -- Every jump press (space or the mobile jump button). On the ground this just
    -- starts the cooldown so the normal jump never double-fires; in the air it gives
    -- one extra jump per press.
    HVH.infJumpState.conn = UserInputService.JumpRequest:Connect(function()
        local cfg = HVH.cfg
        if not cfg or not cfg.InfiniteJump.Enabled then return end
        local _, hum, hrp = getChar()
        if not hum or not hrp then return end
        if hum.FloorMaterial ~= Enum.Material.Air then
            HVH.lastInfJump = os.clock()
            HVH.airJumps = 0
            return
        end
        infJumpTry(hum, hrp, false)
    end)

    HVH.active = true
    HVH.swimEngaged = false

    HVH.conn = RunService.Heartbeat:Connect(function()
        local cfg = HVH.cfg
        if not cfg then return end

        local char, hum, hrp = getChar()

        if cfg.HipHeight.Enabled and hum then
            if hum.HipHeight ~= cfg.HipHeight.Value then
                hum.HipHeight = cfg.HipHeight.Value
            end
        end

        if not hum then return end

        if cfg.Swim.Enabled then
            if hum.FloorMaterial ~= Enum.Material.Air then
                HVH.swimEngaged = false
            else
                local st = hum:GetState()
                if st ~= Enum.HumanoidStateType.Swimming then
                    hum:ChangeState(Enum.HumanoidStateType.Swimming)
                    if not HVH.swimEngaged and hrp then
                        local v = hrp.AssemblyLinearVelocity
                        hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
                        HVH.swimEngaged = true
                    end
                end
                if hrp then
                    local v = hrp.AssemblyLinearVelocity
                    local cap = 20 * (cfg.Swim.Power or 1)
                    if v.Y > cap then
                        hrp.AssemblyLinearVelocity = Vector3.new(v.X, cap, v.Z)
                    end
                end
            end
        else
            HVH.swimEngaged = false
        end

        -- Landing gives the air jumps back.
        if hum.FloorMaterial ~= Enum.Material.Air then HVH.airJumps = 0 end

        -- Double jump, hold-to-repeat (keyboard). Re-jumps only once you are
        -- already falling, and only up to the air jump limit.
        -- Taps (keyboard or mobile button) are handled by the JumpRequest hook above.
        if cfg.InfiniteJump.Enabled and hrp and not isMobile
            and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            infJumpTry(hum, hrp, true)
        end

        if cfg.Speed.Enabled and hrp and hum.MoveDirection.Magnitude > 0.05 then
            local mult = cfg.Speed.Multiplier or 1.35
            local targetVel = hum.MoveDirection.Unit * (16 * mult)
            local y = hrp.AssemblyLinearVelocity.Y
            hrp.AssemblyLinearVelocity = Vector3.new(targetVel.X, y, targetVel.Z)
        end
    end)
end

local function hvhStop()
    HVH.active = false
    if HVH.conn then HVH.conn:Disconnect(); HVH.conn = nil end
    if HVH.infJumpState.conn then HVH.infJumpState.conn:Disconnect(); HVH.infJumpState.conn = nil end
    HVH.swimEngaged = false
end

local function hvhResetAll()
    local cfg = HVH.cfg
    if not cfg then return end
    cfg.HipHeight.Enabled = false
    cfg.Swim.Enabled = false
    cfg.InfiniteJump.Enabled = false
    cfg.Speed.Enabled = false
    local char, hum = getChar()
    if hum then
        hum.HipHeight = cfg.HipHeight.Default
        if hum:GetState() == Enum.HumanoidStateType.Swimming then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

local function buildHVHTab(tab, cfg)
    tab:CreateSection("HipHeight")
    tab:CreateToggle({
        Name = "HipHeight changer",
        Desc = "Overrides your Humanoid.HipHeight each frame.",
        Flag = "hvh_hipheight",
        CurrentValue = cfg.HipHeight.Enabled,
        Callback = function(v) cfg.HipHeight.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "HipHeight value",
        Range = { -5, 20 }, Increment = 0.5, Suffix = " studs",
        CurrentValue = cfg.HipHeight.Value, Flag = "hvh_hipheight_val",
        Callback = function(v)
            cfg.HipHeight.Value = v
            local _, hum = getChar()
            if hum and cfg.HipHeight.Enabled then hum.HipHeight = v end
        end,
    })

    tab:CreateSection("Swim")
    tab:CreateToggle({
        Name = "Swim",
        Desc = "Forces swimming while airborne. Velocity is clamped to prevent launch.",
        Flag = "hvh_swim",
        CurrentValue = cfg.Swim.Enabled,
        Callback = function(v) cfg.Swim.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "Swim power",
        Desc = "Caps upward velocity while swimming (lower = less launch).",
        Range = { 0.1, 5 }, Increment = 0.1,
        CurrentValue = cfg.Swim.Power, Flag = "hvh_swim_power",
        Callback = function(v) cfg.Swim.Power = v end,
    })

    tab:CreateSection("Speed")
    tab:CreateToggle({
        Name = "Speed boost",
        Flag = "hvh_ws",
        CurrentValue = cfg.Speed.Enabled,
        Callback = function(v) cfg.Speed.Enabled = v end,
    })
    tab:CreateKeybind({
        Name = "Speed keybind",
        Flag = "hvh_ws_key",
        CurrentValue = cfg.Speed.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then cfg.Speed.Keybind = key end
        end,
    })
    tab:CreateSlider({
        Name = "Speed multiplier",
        Range = { 1, 3 }, Increment = 0.05,
        CurrentValue = cfg.Speed.Multiplier, Flag = "hvh_ws_val",
        Callback = function(v) cfg.Speed.Multiplier = v end,
    })

    tab:CreateSection("Double Jump")
    tab:CreateToggle({
        Name = "Double jump",
        Desc = "Jump again in mid-air, up to the air jump limit. Landing resets it.",
        Flag = "hvh_infjump",
        CurrentValue = cfg.InfiniteJump.Enabled,
        Callback = function(v) cfg.InfiniteJump.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "Air jumps",
        Desc = "How many extra jumps you get in the air before it stops (1 = classic double jump).",
        Range = { 1, 5 }, Increment = 1,
        CurrentValue = cfg.InfiniteJump.Count, Flag = "hvh_infjump_count",
        Callback = function(v) cfg.InfiniteJump.Count = v end,
    })
    tab:CreateSlider({
        Name = "Double jump strength",
        Desc = "Strength of each extra jump (1 = a normal jump).",
        Range = { 0.1, 5 }, Increment = 0.1,
        CurrentValue = cfg.InfiniteJump.Power, Flag = "hvh_infjump_power",
        Callback = function(v) cfg.InfiniteJump.Power = v end,
    })
end

-- ============================================================
-- BRANCH: ARCADE BASKETBALL
-- ============================================================
if isArcade then
    local Settings = {
        Shooting = {
            AutoGreen = false,
            AutoGreenKeybind = Enum.KeyCode.E,
            AutoGreenOnShootButton = true,
        },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1, Count = 2 },
        },
        AntiContest = {
            Enabled = false,
            Keybind = Enum.KeyCode.E,
            Height = 25,
        },
        BallSize = {
            Enabled = false,
            Size = 6,
            Transparency = 0.5,
        },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {} }
    local function Track(c) if c then table.insert(Cleanup.conns, c) end return c end

    local ShootRemote = nil
    local function resolveShootRemote()
        if ShootRemote and ShootRemote.Parent then return ShootRemote end
        pcall(function()
            local Events = ReplicatedStorage:FindFirstChild("Events")
            ShootRemote = Events and Events:FindFirstChild("Shoot")
        end)
        return ShootRemote
    end

    local function fireAutoGreen()
        local remote = resolveShootRemote()
        if not remote then return false end
        local ok = pcall(function()
            remote:FireServer(true, 100, false)
        end)
        pcall(function()
            remote:FireServer(false, -1, true)
        end)
        return ok
    end

    local greenLock = false
    local function fireAutoGreenSafe()
        if greenLock then return end
        greenLock = true
        fireAutoGreen()
        task.delay(0.15, function() greenLock = false end)
    end

    local ballResizeConn = nil
    local trackedBalls = {}
    local origData     = {}

    local function isBallPart(inst)
        if not inst:IsA("BasePart") then return false end
        return string.lower(inst.Name):find("ball", 1, true) ~= nil
    end

    local function addTrackedBall(inst)
        if not isBallPart(inst) or trackedBalls[inst] then return end
        trackedBalls[inst] = true
        origData[inst] = { Size = inst.Size, Transparency = inst.Transparency }
        if s.BallSize.Enabled then
            local size = tonumber(s.BallSize.Size) or 6
            local trans = tonumber(s.BallSize.Transparency) or 0.5
            pcall(function()
                inst.Size = Vector3.new(size, size, size)
                inst.Transparency = trans
            end)
        end
    end

    local function removeTrackedBall(inst)
        trackedBalls[inst] = nil
        origData[inst] = nil
    end

    local function applyBallSize()
        local size = tonumber(s.BallSize.Size) or 6
        local trans = tonumber(s.BallSize.Transparency) or 0.5
        for part in pairs(trackedBalls) do
            if part.Parent then
                pcall(function()
                    part.Size = Vector3.new(size, size, size)
                    part.Transparency = trans
                end)
            else
                removeTrackedBall(part)
            end
        end
    end

    local function restoreBallSize()
        for part, data in pairs(origData) do
            if part.Parent then
                pcall(function()
                    part.Size = data.Size
                    part.Transparency = data.Transparency
                end)
            end
        end
        table.clear(origData)
        table.clear(trackedBalls)
    end

    local ballAddedConn, ballRemovedConn = nil, nil
    local function enableBallResizer()
        for _, inst in ipairs(workspace:GetDescendants()) do addTrackedBall(inst) end
        ballAddedConn = workspace.DescendantAdded:Connect(function(inst)
            if isBallPart(inst) then
                task.defer(function() addTrackedBall(inst) end)
            end
        end)
        ballRemovedConn = workspace.DescendantRemoving:Connect(function(inst)
            if isBallPart(inst) then removeTrackedBall(inst) end
        end)
        applyBallSize()
        if ballResizeConn then ballResizeConn:Disconnect() end
        ballResizeConn = RunService.Heartbeat:Connect(function()
            if s.BallSize.Enabled then applyBallSize() end
        end)
        Track(ballResizeConn)
    end

    local function disableBallResizer()
        if ballAddedConn then ballAddedConn:Disconnect(); ballAddedConn = nil end
        if ballRemovedConn then ballRemovedConn:Disconnect(); ballRemovedConn = nil end
        if ballResizeConn then ballResizeConn:Disconnect(); ballResizeConn = nil end
        restoreBallSize()
    end

    local antiContestLock = false
    local function doAntiContest()
        if antiContestLock then return end
        antiContestLock = true
        task.delay(0.1, function() antiContestLock = false end)
        local _, _, hrp = getChar()
        if not hrp then return end
        local height = tonumber(s.AntiContest.Height) or 25
        hrp.CFrame = hrp.CFrame + Vector3.new(0, height, 0)
    end

    local Window = Airflow:CreateWindow({Name = "Fatal Labs", LoadingSubtitle = "Fatal Labs basketball suite", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "FatalLabs", FileName = "FatalLabs"}})

    local Notify = function(props) pcall(function() Window:Notify(props) end) end

    local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "Movement", Icon = "activity" })

    CombatTab:CreateSection("Auto Green")
    CombatTab:CreateToggle({
        Name = "Auto Green",
        Desc = "Fires Events.Shoot with the perfect-shot sequence.",
        Flag = "ab_autogreen",
        CurrentValue = s.Shooting.AutoGreen,
        Callback = function(v) s.Shooting.AutoGreen = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto Green keybind",
        Desc = "Hold then RELEASE this key to fire a green shot.",
        Flag = "ab_autogreen_key",
        CurrentValue = s.Shooting.AutoGreenKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AutoGreenKeybind = key end
        end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Shoot button",
        Desc = "Fires the remote INSTANTLY when you RELEASE the in-game Shoot button.",
        Flag = "ab_autogreen_btn",
        CurrentValue = s.Shooting.AutoGreenOnShootButton,
        Callback = function(v) s.Shooting.AutoGreenOnShootButton = v end,
    })
    CombatTab:CreateButton({
        Name = "Fire Green Now",
        Callback = function()
            if fireAutoGreen() then
                Notify({ title = "Auto Green", content = "Shot fired.", duration = 2 })
            else
                Notify({ title = "Auto Green", content = "Remote not found.", duration = 3 })
            end
        end,
    })

    CombatTab:CreateSection("Anti Contest")
    CombatTab:CreateToggle({
        Name = "Anti Contest",
        Desc = "Press E to teleport straight up (dodges contests).",
        Flag = "ab_ac",
        CurrentValue = s.AntiContest.Enabled,
        Callback = function(v) s.AntiContest.Enabled = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Anti Contest keybind",
        Desc = "Press this key to jump straight up.",
        Flag = "ab_ac_key",
        CurrentValue = s.AntiContest.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.AntiContest.Keybind = key end
        end,
    })
    CombatTab:CreateSlider({
        Name = "Anti Contest height",
        Range = { 1, 25 }, Increment = 1, Suffix = " studs",
        CurrentValue = s.AntiContest.Height, Flag = "ab_ac_h",
        Callback = function(v) s.AntiContest.Height = v end,
    })

    BallTab:CreateSection("Ball Resizer")
    BallTab:CreateToggle({
        Name = "Ball Resizer",
        Desc = "Scales every ball part and sets its transparency to 0.5.",
        Flag = "ab_ballsize",
        CurrentValue = s.BallSize.Enabled,
        Callback = function(v)
            s.BallSize.Enabled = v
            if v then enableBallResizer() else disableBallResizer() end
        end,
    })
    BallTab:CreateSlider({
        Name = "Ball size",
        Range = { 1, 12 }, Increment = 1, Suffix = " studs",
        CurrentValue = s.BallSize.Size, Flag = "ab_ballsize_val",
        Callback = function(v)
            s.BallSize.Size = v
            if s.BallSize.Enabled then applyBallSize() end
        end,
    })

    buildHVHTab(HVHTab, s.HVH)

    do
        local hookedButtons = {}
        local pressedButtons = {}

        local function matchesShoot(inst)
            if not (inst:IsA("GuiButton") or inst:IsA("ImageButton")) then return false end
            local n = string.lower(inst.Name)
            if n == "shoot" or n:find("shoot", 1, true) then return true end
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    if string.lower(d.Text or ""):find("shoot", 1, true) then return true end
                end
            end
            return false
        end

        local function onPress(inst)
            if not s.Shooting.AutoGreen then return end
            if not s.Shooting.AutoGreenOnShootButton then return end
            pressedButtons[inst] = true
        end

        local function onRelease(inst)
            if not s.Shooting.AutoGreen then return end
            if not s.Shooting.AutoGreenOnShootButton then return end
            if not pressedButtons[inst] then return end
            pressedButtons[inst] = nil
            fireAutoGreenSafe()
        end

        local function tryHook(inst)
            if hookedButtons[inst] then return end
            if not matchesShoot(inst) then return end
            hookedButtons[inst] = true
            Track(inst.MouseButton1Down:Connect(function() onPress(inst) end))
            Track(inst.MouseButton1Up:Connect(function() onRelease(inst) end))
            Track(inst.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onPress(inst)
                end
            end))
            Track(inst.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onRelease(inst)
                end
            end))
            Track(inst.MouseLeave:Connect(function()
                if pressedButtons[inst] then onRelease(inst) end
            end))
        end

        local function scanAndHook(root)
            if not root then return end
            for _, inst in ipairs(root:GetDescendants()) do tryHook(inst) end
        end

        local function watchRoot(root)
            if not root then return end
            Track(root.DescendantAdded:Connect(function(inst)
                task.wait(0.05)
                tryHook(inst)
            end))
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then scanAndHook(pg); watchRoot(pg) end
        Track(LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                task.wait(0.5)
                scanAndHook(child); watchRoot(child)
            end
        end))

        scanAndHook(workspace); watchRoot(workspace)
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            scanAndHook(char); watchRoot(char)
        end))

        pcall(function()
            scanAndHook(CoreGui); watchRoot(CoreGui)
        end)
    end

    local eWasHeld = false

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local hvhCfg = s.HVH

        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey then
            if s.Shooting.AutoGreen then eWasHeld = true end
            if s.AntiContest.Enabled then
                local acBind = s.AntiContest.Keybind
                local acKey = (type(acBind) == "string") and Enum.KeyCode[acBind] or acBind
                if input.KeyCode == acKey then doAntiContest() end
            end
            return
        end

        local acBind = s.AntiContest.Keybind
        local acKey = (type(acBind) == "string") and Enum.KeyCode[acBind] or acBind
        if input.KeyCode == acKey and s.AntiContest.Enabled then
            doAntiContest(); return
        end

        local speedBind = hvhCfg.Speed.Keybind
        local speedKey = (type(speedBind) == "string") and Enum.KeyCode[speedBind] or speedBind
        if input.KeyCode == speedKey then
            hvhCfg.Speed.Enabled = not hvhCfg.Speed.Enabled
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey and eWasHeld then
            eWasHeld = false
            if s.Shooting.AutoGreen then fireAutoGreenSafe() end
        end
    end)

    hvhStart()

    local function cleanup()
        pcall(disableBallResizer)
        pcall(hvhResetAll)
        pcall(hvhStop)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end
    Track(LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then cleanup() end
    end))

-- ============================================================
-- BRANCH: BASKETBALL LEGENDS
-- ============================================================
elseif isBL then
    local Settings = {
        Shooting = {
            AutoGreen = false,
            AutoGreenKeybind = Enum.KeyCode.E,
            AutoGreenOnJump = false,
            AutoGreenOnShootButton = true,
        },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1, Count = 2 },
        },
        Mag = {
            Enabled = false,
            BallName = "Ball",
            Reach = 20,
            Keybind = Enum.KeyCode.L,
        },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {} }
    local function Track(c) if c then table.insert(Cleanup.conns, c) end return c end

    local ShootRemote = nil
    local function resolveShootRemote()
        if ShootRemote and ShootRemote.Parent then return ShootRemote end
        pcall(function()
            local Packages = ReplicatedStorage:FindFirstChild("Packages")
            local Knit = Packages and Packages:FindFirstChild("Knit")
            local Services = Knit and Knit:FindFirstChild("Services")
            local ControlService = Services and Services:FindFirstChild("ControlService")
            local RE = ControlService and ControlService:FindFirstChild("RE")
            ShootRemote = RE and RE:FindFirstChild("Shoot")
        end)
        return ShootRemote
    end

    local function fireAutoGreen()
        local remote = resolveShootRemote()
        if not remote then return false end
        return pcall(function() remote:FireServer(1) end)
    end

    local greenLock = false
    local function fireAutoGreenSafe()
        if greenLock then return end
        greenLock = true
        fireAutoGreen()
        task.delay(0.15, function() greenLock = false end)
    end

    local magConnection = nil
    local magRefreshThread = nil
    local magCache = {}

    local function rebuildMagCache()
        table.clear(magCache)
        local targetName = s.Mag.BallName
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("BasePart") and inst.Name == targetName then
                if inst:FindFirstChildWhichIsA("TouchTransmitter")
                    or inst:FindFirstChild("TouchInterest") then
                    magCache[#magCache + 1] = inst
                end
            end
        end
    end

    local function magTick()
        if not s.Mag.Enabled then return end
        local character, _, touchPart = getChar()
        if not character or not touchPart then return end
        if character:FindFirstChild("Basketball") then return end
        local reach = tonumber(s.Mag.Reach) or 20
        local reachSq = reach * reach
        local origin = touchPart.Position
        for i = #magCache, 1, -1 do
            local part = magCache[i]
            if not part or not part.Parent then
                table.remove(magCache, i)
            else
                local d = origin - part.Position
                if (d.X*d.X + d.Y*d.Y + d.Z*d.Z) <= reachSq then
                    pcall(function()
                        firetouchinterest(touchPart, part, 0)
                        firetouchinterest(touchPart, part, 1)
                    end)
                    if not part.Anchored then
                        part.AssemblyLinearVelocity = (touchPart.Position - part.Position) * 30
                    end
                end
            end
        end
    end

    local function enableMag()
        if magConnection then magConnection:Disconnect(); magConnection = nil end
        if magRefreshThread then task.cancel(magRefreshThread); magRefreshThread = nil end
        rebuildMagCache()
        magRefreshThread = task.spawn(function()
            while s.Mag.Enabled do
                task.wait(0.5)
                if s.Mag.Enabled then rebuildMagCache() end
            end
        end)
        magConnection = RunService.Heartbeat:Connect(function() pcall(magTick) end)
        Track(magConnection)
    end

    local function disableMag()
        if magConnection then magConnection:Disconnect(); magConnection = nil end
        if magRefreshThread then task.cancel(magRefreshThread); magRefreshThread = nil end
        table.clear(magCache)
    end

    local Window = Airflow:CreateWindow({Name = "Fatal Labs", LoadingSubtitle = "Fatal Labs basketball suite", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "FatalLabs", FileName = "FatalLabs"}})

    local Notify = function(props) pcall(function() Window:Notify(props) end) end

    local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "Movement", Icon = "activity" })

    CombatTab:CreateSection("Auto Green")
    CombatTab:CreateToggle({
        Name = "Auto Green",
        Desc = "Fires ControlService.RE.Shoot with argument 1 (perfect shot).",
        Flag = "bl_autogreen",
        CurrentValue = s.Shooting.AutoGreen,
        Callback = function(v) s.Shooting.AutoGreen = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto Green keybind",
        Desc = "Hold then RELEASE this key to fire a green shot.",
        Flag = "bl_autogreen_key",
        CurrentValue = s.Shooting.AutoGreenKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AutoGreenKeybind = key end
        end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Jump",
        Desc = "Fires the remote automatically after you jump-shot.",
        Flag = "bl_autogreen_jump",
        CurrentValue = s.Shooting.AutoGreenOnJump,
        Callback = function(v) s.Shooting.AutoGreenOnJump = v end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Shoot button",
        Desc = "Fires the remote INSTANTLY when you RELEASE the in-game Shoot button.",
        Flag = "bl_autogreen_btn",
        CurrentValue = s.Shooting.AutoGreenOnShootButton,
        Callback = function(v) s.Shooting.AutoGreenOnShootButton = v end,
    })
    CombatTab:CreateButton({
        Name = "Fire Green Now",
        Callback = function()
            if fireAutoGreen() then
                Notify({ title = "Auto Green", content = "Shot fired.", duration = 2 })
            else
                Notify({ title = "Auto Green", content = "Remote not found.", duration = 3 })
            end
        end,
    })

    BallTab:CreateSection("Mag")
    BallTab:CreateToggle({
        Name = "Mag",
        Desc = "Fast cached magnet. Auto firetouchinterest on nearby balls.",
        Flag = "bl_mag",
        CurrentValue = s.Mag.Enabled,
        Callback = function(v)
            s.Mag.Enabled = v
            if v then enableMag() else disableMag() end
        end,
    })
    BallTab:CreateKeybind({
        Name = "Mag keybind",
        Desc = "Press this key to toggle Mag on/off.",
        Flag = "bl_mag_key",
        CurrentValue = s.Mag.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Mag.Keybind = key end
        end,
    })
    BallTab:CreateInput({
        Name = "Ball name",
        Desc = "Name of the part to magnet (default: Ball).",
        Placeholder = "Ball",
        CurrentValue = s.Mag.BallName,
        Flag = "bl_mag_name",
        Callback = function(text)
            if text ~= "" then
                s.Mag.BallName = text
                if s.Mag.Enabled then rebuildMagCache() end
            end
        end,
    })
    BallTab:CreateSlider({
        Name = "Reach (studs)",
        Range = { 1, 100 }, Increment = 1,
        CurrentValue = s.Mag.Reach, Flag = "bl_mag_reach",
        Callback = function(v) s.Mag.Reach = v end,
    })

    buildHVHTab(HVHTab, s.HVH)

    local function setupAutoGreenChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        Track(hum.Jumping:Connect(function(active)
            if not active then return end
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnJump then return end
            if not char:FindFirstChild("Basketball") then return end
            fireAutoGreenSafe()
        end))
    end
    if LocalPlayer.Character then setupAutoGreenChar(LocalPlayer.Character) end
    Track(LocalPlayer.CharacterAdded:Connect(setupAutoGreenChar))

    do
        local hookedButtons = {}
        local pressedButtons = {}

        local function matchesShoot(inst)
            if not (inst:IsA("GuiButton") or inst:IsA("ImageButton")) then return false end
            local n = string.lower(inst.Name)
            if n == "shoot" or n:find("shoot", 1, true) then return true end
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    if string.lower(d.Text or ""):find("shoot", 1, true) then return true end
                end
            end
            return false
        end

        local function onPress(inst)
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnShootButton then return end
            pressedButtons[inst] = true
        end

        local function onRelease(inst)
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnShootButton then return end
            if not pressedButtons[inst] then return end
            pressedButtons[inst] = nil
            fireAutoGreenSafe()
        end

        local function tryHook(inst)
            if hookedButtons[inst] or not matchesShoot(inst) then return end
            hookedButtons[inst] = true
            Track(inst.MouseButton1Down:Connect(function() onPress(inst) end))
            Track(inst.MouseButton1Up:Connect(function() onRelease(inst) end))
            Track(inst.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onPress(inst)
                end
            end))
            Track(inst.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onRelease(inst)
                end
            end))
            Track(inst.MouseLeave:Connect(function()
                if pressedButtons[inst] then onRelease(inst) end
            end))
        end

        local function scanAndHook(root)
            if not root then return end
            for _, inst in ipairs(root:GetDescendants()) do tryHook(inst) end
        end

        local function watchRoot(root)
            if not root then return end
            Track(root.DescendantAdded:Connect(function(inst)
                task.wait(0.05)
                tryHook(inst)
            end))
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then scanAndHook(pg); watchRoot(pg) end
        Track(LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                task.wait(0.5)
                scanAndHook(child); watchRoot(child)
            end
        end))

        scanAndHook(workspace); watchRoot(workspace)
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            scanAndHook(char); watchRoot(char)
        end))

        pcall(function()
            scanAndHook(CoreGui); watchRoot(CoreGui)
        end)
    end

    local eWasHeld = false

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey then
            if s.Shooting.AutoGreen then eWasHeld = true end
            return
        end

        local magBind = s.Mag.Keybind
        local magKey = (type(magBind) == "string") and Enum.KeyCode[magBind] or magBind
        if input.KeyCode == magKey then
            s.Mag.Enabled = not s.Mag.Enabled
            if s.Mag.Enabled then enableMag() else disableMag() end
            return
        end

        local speedBind = s.HVH.Speed.Keybind
        local speedKey = (type(speedBind) == "string") and Enum.KeyCode[speedBind] or speedBind
        if input.KeyCode == speedKey then
            s.HVH.Speed.Enabled = not s.HVH.Speed.Enabled
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey and eWasHeld then
            eWasHeld = false
            if s.Shooting.AutoGreen then fireAutoGreenSafe() end
        end
    end)

    hvhStart()

    local function cleanup()
        pcall(disableMag)
        pcall(hvhResetAll)
        pcall(hvhStop)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end
    Track(LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then cleanup() end
    end))

-- ============================================================
-- BRANCH: HOOPZ
-- ============================================================
else
    local TweenService = game:GetService("TweenService")
    local HttpService  = game:GetService("HttpService")

    local Settings = {
        Shooting = {
            AuralEnabled = false, AuralKeybind = Enum.KeyCode.X,
            ShotYAxis = 0, ShotDelay = 0.32, EBLHop = false,
            HumanizeAim = false, HumanizeStrength = 1.2, MissChance = 0,
            RandomizeShotDelay = false, ShotDelayMin = 0.25, ShotDelayMax = 0.38,
        },
        Defending = {
            AutoGuard = false, AutoGuardButton = false, AutoGuardNearest = false,
            AutoGuardMode = "Balanced", AutoGuardRange = 33, GuardPrediction = 0.58,
            GuardKeybind = Enum.KeyCode.K,
        },
        Ball = {
            BallMags = false, BallMagRange = 15, MagnetKeybind = "M",
            BallReach = false, BallReachRange = 10, ReachKeybind = "N",
        },
        TPWalk = { Enabled = false, Speed = 0.01, Keybind = Enum.KeyCode.P },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1, Count = 2 },
        },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {}, fns = {} }
    local function Track(c) table.insert(Cleanup.conns, c); return c end
    local function OnCleanup(fn) table.insert(Cleanup.fns, fn) end

    local setAural, setGuard, setMagnet, setReach, setTPWalk
    local MobileRefresh = function() end


    local function hasball(char) return char and char:FindFirstChild("Basketball") ~= nil end

    local fieldGoals = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst.Name == "FieldGoal" and inst:IsA("BasePart") then
            table.insert(fieldGoals, inst)
        end
    end

    local goals = {}
    local goalsDirty = true

    local function validgoal(o)
        if not o:IsA("BasePart") then return false end
        local n = string.lower(o.Name)
        if n ~= "goal" and n ~= "goalhome" and n ~= "goalaway" then return false end
        local p = o.Parent
        for _ = 1, 5 do
            if not p then break end
            local pn = string.lower(p.Name)
            if string.find(pn, "hitbox", 1, true) or string.find(pn, "fieldgoal", 1, true) then return true end
            p = p.Parent
        end
        return false
    end

    local function rebuildGoals()
        table.clear(goals)
        for _, o in workspace:GetDescendants() do
            if validgoal(o) then table.insert(goals, o) end
        end
        goalsDirty = false
    end
    rebuildGoals()

    Track(workspace.DescendantAdded:Connect(function(o)
        if validgoal(o) then
            table.insert(goals, o)
        elseif o:IsA("BasePart") and string.find(string.lower(o.Name), "goal", 1, true) then
            goalsDirty = true
        end
    end))

    local courtPlayerCache = {}
    local function rebuildCourtCache()
        table.clear(courtPlayerCache)
        for _, inst in next, workspace:GetChildren() do
            if inst.Name == "Courts" then
                for _, court in next, inst:GetChildren() do
                    local cp = court:FindFirstChild("_CourtPlayers")
                    if cp then table.insert(courtPlayerCache, cp) end
                end
            end
        end
    end
    rebuildCourtCache()

    Track(workspace.DescendantAdded:Connect(function(o)
        if o.Name == "_CourtPlayers" then
            table.insert(courtPlayerCache, o)
        end
    end))

    local function nearestgoal(root)
        if goalsDirty then rebuildGoals() end
        local rootPos = root.Position
        local best, bestDist = nil, math.huge
        for i = #goals, 1, -1 do
            local goal = goals[i]
            if not goal or not goal.Parent then table.remove(goals, i); continue end
            local delta = goal.Position - rootPos
            local flat = delta.X * delta.X + delta.Z * delta.Z
            if flat < bestDist then best, bestDist = goal, flat end
        end
        if best then return best, math.sqrt(bestDist) end
        return nil, math.huge
    end

    local function teamOf(nm)
        if nm:find("^Home") then return "Home" end
        if nm:find("^Away") then return "Away" end
        return nil
    end

    local function getTeammates()
        local tms = {}
        for _, cp in next, courtPlayerCache do
            if not cp.Parent then continue end
            local myTeam = nil
            for _, v in next, cp:GetChildren() do
                if v:IsA("ObjectValue") and v.Value == LocalPlayer then
                    myTeam = teamOf(v.Name)
                    break
                end
            end
            if not myTeam then continue end
            for _, tm in next, cp:GetChildren() do
                if tm:IsA("ObjectValue") and typeof(tm.Value) == "Instance"
                    and tm.Value:IsA("Player") and tm.Value ~= LocalPlayer
                    and teamOf(tm.Name) == myTeam then
                    table.insert(tms, tm.Value)
                end
            end
            break
        end
        return tms
    end

    local teammatesCache = { list = nil }
    local lastTeammateRefresh = 0

    local function isTeammatePlayer(player)
        local now = os.clock()
        if now - lastTeammateRefresh > 0.5 or not teammatesCache.list then
            teammatesCache.list = getTeammates()
            lastTeammateRefresh = now
        end
        for _, tm in ipairs(teammatesCache.list) do
            if tm == player then return true end
        end
        return false
    end

    local function getClosestDribbler()
        local char, _, root = getChar()
        if not root then return nil end
        local closestPlayer, closestDistance = nil, math.huge
        for _, part in workspace:GetPartBoundsInRadius(root.Position, s.Defending.AutoGuardRange) do
            if part:IsA("BasePart") and part.Name == "Ball" and part.Parent:IsA("Folder") then
                local holder = part.Parent.Parent
                local holderRoot = holder and holder:FindFirstChild("HumanoidRootPart")
                if holderRoot then
                    local distance = (holderRoot.Position - root.Position).Magnitude
                    if distance < closestDistance then
                        local holderPlayer = Players:GetPlayerFromCharacter(holder)
                        if holderPlayer and not isTeammatePlayer(holderPlayer) then
                            closestDistance = distance
                            closestPlayer = holderPlayer
                        end
                    end
                end
            end
        end
        return closestPlayer
    end

    local function getClosestPlayer()
        local char, _, root = getChar()
        if not root then return nil end
        local closestPlayer, closestDistance = nil, math.huge
        local rootPos = root.Position
        local range = s.Defending.AutoGuardRange
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local c = player.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - rootPos).Magnitude
                if dist < range and dist < closestDistance and not isTeammatePlayer(player) then
                    closestDistance = dist
                    closestPlayer = player
                end
            end
        end
        return closestPlayer
    end

    local function getGuardMode()
        local lowered = tostring(s.Defending.AutoGuardMode or "Balanced"):lower()
        if lowered == "reactive" then return "legit" end
        if lowered == "aggressive" then return "blatant" end
        return "prediction"
    end

    local function getGuardPosition(target)
        if not target then return nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Basketball") then return nil end
        local targetChar = target.Character
        if not targetChar then return nil end
        local targetBall = targetChar:FindFirstChild("Basketball") and targetChar.Basketball:FindFirstChild("Ball")
        if not targetBall then return nil end
        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar:FindFirstChild("Humanoid")
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not targetHrp or not targetHum or not myHrp or not myHum then return nil end
        local mode = getGuardMode()
        local ballPos = targetBall.Position
        local vel = targetHrp.AssemblyLinearVelocity
        local speed = targetHum.WalkSpeed
        local moveDir = targetHum.MoveDirection
        local myPos = myHrp.Position
        local mySpeed = myHum.WalkSpeed
        local distance = (ballPos - myPos).Magnitude
        local timeToReach = distance / (mySpeed + 10)
        local predictionScale = s.Defending.GuardPrediction or 0.58
        if mode == "legit" then
            predictionScale = predictionScale * 0.7
            timeToReach = distance / (mySpeed + 12)
        elseif mode == "blatant" then
            predictionScale = predictionScale * 1.75
            timeToReach = distance / (mySpeed + 18)
        end
        local predictedMove = moveDir * speed * predictionScale + Vector3.new(vel.X, 0, vel.Z) * 0.5
        local interceptPos = targetHrp.Position + predictedMove * timeToReach
        local offsetDir = (moveDir.Magnitude > 0 and moveDir.Unit or Vector3.new(0, 0, 1)) * ((mode == "blatant") and 4 or 2)
        return Vector3.new(interceptPos.X + offsetDir.X, ballPos.Y, interceptPos.Z + offsetDir.Z)
    end

    local function getNearestGuardPosition(target)
        if not target then return nil end
        local targetChar = target.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHrp or not targetHum or not myHrp then return nil end
        local moveDir = targetHum.MoveDirection
        local vel = Vector3.new(targetHrp.AssemblyLinearVelocity.X, 0, targetHrp.AssemblyLinearVelocity.Z)
        local dist = (targetHrp.Position - myHrp.Position).Magnitude
        local timeToReach = dist / (targetHum.WalkSpeed + 10)
        local predictionScale = (getGuardMode() == "blatant") and (s.Defending.GuardPrediction * 1.5) or s.Defending.GuardPrediction
        local predicted = targetHrp.Position + (moveDir * targetHum.WalkSpeed * predictionScale + vel * 0.5) * timeToReach
        local facing = (moveDir.Magnitude > 0) and moveDir.Unit or (targetHrp.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
        local offset = facing * ((getGuardMode() == "blatant") and 4 or 2)
        return Vector3.new(predicted.X + offset.X, targetHrp.Position.Y, predicted.Z + offset.Z)
    end

    local guardConnection = nil

    local function enableAutoGuard()
        if guardConnection then guardConnection:Disconnect(); guardConnection = nil end
        local frameSkip = 0
        guardConnection = RunService.Stepped:Connect(function()
            if not s.Defending.AutoGuard then return end
            frameSkip += 1
            if frameSkip < 3 then return end
            frameSkip = 0
            local char, myHum = getChar()
            if not myHum or hasball(char) then return end
            local mode = getGuardMode()
            local closestDribbler = getClosestDribbler()
            if closestDribbler then
                local guardPos
                if mode == "legit" then
                    guardPos = getNearestGuardPosition(closestDribbler)
                elseif mode == "blatant" then
                    guardPos = getGuardPosition(closestDribbler)
                    if guardPos and closestDribbler.Character and closestDribbler.Character:FindFirstChild("HumanoidRootPart") then
                        local targetRoot = closestDribbler.Character.HumanoidRootPart
                        local myRoot = char:FindFirstChild("HumanoidRootPart")
                        if myRoot and (targetRoot.Position - myRoot.Position).Magnitude < 18 then
                            guardPos = targetRoot.Position + (targetRoot.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * 3
                        end
                    end
                else
                    guardPos = getGuardPosition(closestDribbler)
                end
                if guardPos then myHum:MoveTo(guardPos) end
                return
            end
            if s.Defending.AutoGuardNearest then
                local nearest = getClosestPlayer()
                if nearest then
                    local guardPos
                    if mode == "legit" then
                        guardPos = getNearestGuardPosition(nearest)
                    elseif mode == "blatant" then
                        guardPos = getNearestGuardPosition(nearest)
                        if guardPos then
                            local myRoot = char:FindFirstChild("HumanoidRootPart")
                            if myRoot then
                                local targetRoot = nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart")
                                if targetRoot and (targetRoot.Position - myRoot.Position).Magnitude < 20 then
                                    guardPos = targetRoot.Position + targetRoot.CFrame.LookVector * 4
                                end
                            end
                        end
                    else
                        guardPos = getNearestGuardPosition(nearest)
                    end
                end
            end
        end)
    end
    Track(guardConnection)

    local function disableAutoGuard()
        if guardConnection then guardConnection:Disconnect(); guardConnection = nil end
    end

    local magnetHitbox, magnetConnection = nil, nil

    local function createMagnetHitbox(character)
        if magnetHitbox then magnetHitbox:Destroy(); magnetHitbox = nil end
        if character:FindFirstChild("FatalMagnet") then character.FatalMagnet:Destroy() end
        local head = character:FindFirstChild("Head")
        if not head then return end
        magnetHitbox = Instance.new("Part")
        magnetHitbox.Name = "FatalMagnet"
        magnetHitbox.Shape = Enum.PartType.Ball
        magnetHitbox.Size = Vector3.new(s.Ball.BallMagRange, s.Ball.BallMagRange, s.Ball.BallMagRange)
        magnetHitbox.Transparency = 1
        magnetHitbox.CanCollide = false
        magnetHitbox.CanQuery = false
        magnetHitbox.Massless = true
        magnetHitbox.Parent = character
        local weld = Instance.new("Weld")
        weld.Part0 = head
        weld.Part1 = magnetHitbox
        weld.Parent = magnetHitbox
        magnetHitbox.Touched:Connect(function(part)
            if not s.Ball.BallMags or hasball(LocalPlayer.Character) then return end
            if part.Name == "Ball" or (part.Parent and part.Parent.Name == "Basketball") then
                firetouchinterest(head, part, 0)
                task.wait()
                firetouchinterest(head, part, 1)
            end
        end)
    end

    local function enableMagnet()
        local char = LocalPlayer.Character
        if not char then return end
        createMagnetHitbox(char)
        if magnetConnection then magnetConnection:Disconnect(); magnetConnection = nil end
        magnetConnection = RunService.Heartbeat:Connect(function()
            if not s.Ball.BallMags then return end
            local character = LocalPlayer.Character
            if character and not character:FindFirstChild("FatalMagnet") then
                createMagnetHitbox(character)
            end
        end)
        Track(magnetConnection)
    end

    local function disableMagnet()
        if magnetConnection then magnetConnection:Disconnect(); magnetConnection = nil end
        if magnetHitbox then magnetHitbox:Destroy(); magnetHitbox = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("FatalMagnet") then
            LocalPlayer.Character.FatalMagnet:Destroy()
        end
    end

    local reachConnection = nil

    local function performReachSteal()
        if not s.Ball.BallReach then return end
        local char = LocalPlayer.Character
        if not char or char:FindFirstChild("Basketball") then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        local range = s.Ball.BallReachRange or 10
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local pChar = player.Character
            if pChar then
                local basketball = pChar:FindFirstChild("Basketball")
                if basketball then
                    local ballPart = basketball:FindFirstChild("Ball") or basketball:FindFirstChildOfClass("BasePart")
                    if ballPart and (head.Position - ballPart.Position).Magnitude <= range then
                        firetouchinterest(head, ballPart, 0)
                        task.wait()
                        firetouchinterest(head, ballPart, 1)
                        return
                    end
                end
            end
        end
    end

    local function enableReach()
        local char = LocalPlayer.Character
        if not char then return end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("FatalReach") then
            LocalPlayer.Character.FatalReach:Destroy()
        end
        if reachConnection then reachConnection:Disconnect(); reachConnection = nil end
        reachConnection = RunService.Heartbeat:Connect(function()
            if not s.Ball.BallReach then return end
            performReachSteal()
        end)
        Track(reachConnection)
    end

    local function disableReach()
        if reachConnection then reachConnection:Disconnect(); reachConnection = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("FatalReach") then
            LocalPlayer.Character.FatalReach:Destroy()
        end
    end

    local tpWalkConnection = nil

    local function enableTPWalk()
        if tpWalkConnection then tpWalkConnection:Disconnect(); tpWalkConnection = nil end
        tpWalkConnection = RunService.Heartbeat:Connect(function()
            if not s.TPWalk.Enabled then return end
            local character = LocalPlayer.Character
            if not character then return end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                rootPart.CFrame = rootPart.CFrame + humanoid.MoveDirection * s.TPWalk.Speed
            end
        end)
        Track(tpWalkConnection)
    end

    local function disableTPWalk()
        if tpWalkConnection then tpWalkConnection:Disconnect(); tpWalkConnection = nil end
    end

    local Notify

    local AURAL_MIN_DIST = 12
    local AURAL_MAX_DIST = 73

    local shot_data = {
        [59]=83,[60]=81,[61]=82,[62]=79,[63]=78.8,[64]=75,[65]=74.8,[66]=71,
        [67]=70.8,[68]=66,[69]=62,[70]=59,[71]=51,[72]=51,[73]=51
    }

    local inner_arc_data = {
        [7]=123,[8]=122,[9]=121,[10]=120,[11]=119,[12]=118,[13]=117,[14]=116,[15]=115,[16]=114,
        [17]=113,[18]=112,[19]=111,[20]=110,[21]=109,[22]=108,[23]=107,[24]=106,[25]=105,
        [26]=105,
        [27]=106,[28]=106,[29]=107,[30]=107,[31]=106,[32]=105,[33]=105,[34]=104,[35]=103,
        [36]=103,
        [37]=102,[38]=102,[39]=101,[40]=101,[41]=100,[42]=99,[43]=99,[44]=98,[45]=97,[46]=96,
        [47]=95,[48]=95,[49]=94,[50]=93,[51]=91,[52]=90,[53]=88,[54]=87,[55]=85,[56]=84,[57]=82,
        [58]=81
    }

    local mobileArcs = {
        [30]=38,[31]=38,[32]=38,[33]=38,[34]=38,[35]=38,[36]=38,[37]=38,[38]=38,[39]=38,
        [40]=39,[41]=38,[42]=38,[43]=38,[44]=38,[45]=38,[46]=38,[47]=38,[48]=38,[49]=38,
        [50]=38,[51]=37,[52]=37,[53]=37,[54]=36,[55]=34,[56]=34,[57]=34,[58]=34,[59]=31,
        [60]=31,[61]=31,[62]=31,[63]=29,[64]=29,[65]=29,[66]=26,[67]=26,[68]=24,[69]=24,
        [70]=21,[71]=21,[72]=19,[73]=19
    }

    local function getArcOffset(dist)
        if isMobile then
            local d = math.floor(dist + 0.5)
            if d < 30 then d = 30 end
            if d > 73 then d = 73 end
            return mobileArcs[d] or 37
        end
        if inner_arc_data[dist] then return inner_arc_data[dist] end
        if shot_data[dist] then return shot_data[dist] end
        if dist < 7 then return 122 end
        if dist > 73 then return math.max(20, 50 - (dist - 73) * 1.5) end
        local lower, upper
        for d in pairs(inner_arc_data) do
            if d <= dist and (not lower or d > lower) then lower = d end
            if d >= dist and (not upper or d < upper) then upper = d end
        end
        for d in pairs(shot_data) do
            if d <= dist and (not lower or d > lower) then lower = d end
            if d >= dist and (not upper or d < upper) then upper = d end
        end
        if lower and upper and lower ~= upper then
            local lowerVal = inner_arc_data[lower] or shot_data[lower] or 0
            local upperVal = inner_arc_data[upper] or shot_data[upper] or 0
            return lowerVal + (upperVal - lowerVal) * ((dist - lower) / (upper - lower))
        elseif lower then
            return inner_arc_data[lower] or shot_data[lower] or 0
        elseif upper then
            return inner_arc_data[upper] or shot_data[upper] or 0
        end
        return 100
    end

    local Icon = nil
    local IconCenter = nil
    do
        pcall(function()
            local PowerUI = LocalPlayer.PlayerGui:WaitForChild("PowerUI")
            Icon = PowerUI:WaitForChild("CursorIcon")
            local CursorIcon2 = PowerUI:WaitForChild("CursorIcon2")
            task.delay(5, function()
                if Icon then
                    IconCenter = Vector2.new(Icon.AbsolutePosition.X + Icon.AbsoluteSize.X / 2, Icon.AbsolutePosition.Y + Icon.AbsoluteSize.Y / 2)
                    Icon:Destroy()
                end
                if CursorIcon2 then CursorIcon2.Visible = false end
            end)
        end)
    end

    local state = {
        target = nil, connections = {}, actorst = nil, actorname = nil,
        actors = {}, oldnewindex = nil, active = true, clicking = false
    }
    local function addconnection(c) table.insert(state.connections, c); return c end

    local function settarget(target)
        state.target = target
        if state.actorst then pcall(function() state.actorst.t = target end) end
    end

    local function doClick()
        if state.clicking then return end
        state.clicking = true
        getgenv().__fatal_aiming = true
        if isMobile then
            if Icon then
                local pos = Vector2.new(Icon.AbsolutePosition.X + Icon.AbsoluteSize.X / 2, Icon.AbsolutePosition.Y + Icon.AbsoluteSize.Y / 2)
                VirtualInput:SendTouchEvent(1, 0, pos.X, pos.Y)
                VirtualInput:SendTouchEvent(1, 2, pos.X, pos.Y)
            elseif IconCenter then
                VirtualInput:SendTouchEvent(1, 0, IconCenter.X, IconCenter.Y)
                VirtualInput:SendTouchEvent(1, 2, IconCenter.X, IconCenter.Y)
            end
        else
            local vp = Camera.ViewportSize
            VirtualInput:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 1)
            VirtualInput:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 1)
        end
        task.delay(0.35, function()
            state.clicking = false
            getgenv().__fatal_aiming = false
        end)
    end

    local function velocify(target, dist)
        local _, _, hrp = getChar()
        if not hrp then return target end
        local v = hrp.AssemblyLinearVelocity
        local prediction = (dist / 50) * 0.06
        return target + Vector3.new(v.X * prediction, 0, v.Z * prediction)
    end

    local auralTick = 0
    local function updateAuralTarget(dt)
        if not state.active or not s.Shooting.AuralEnabled then
            if state.target ~= nil then settarget(nil) end
            return
        end
        auralTick += dt
        if auralTick < 0.05 then return end
        auralTick = 0
        local char, hum = getChar()
        if not char or not hum or not hasball(char) then
            if state.target ~= nil then settarget(nil) end
            return
        end
        if hum.FloorMaterial ~= Enum.Material.Air and not hum.Jump then
            if state.target ~= nil then settarget(nil) end
            return
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then settarget(nil); return end
        local goal, distance = nearestgoal(root)
        if not goal or distance < AURAL_MIN_DIST or distance > AURAL_MAX_DIST then
            if state.target ~= nil then settarget(nil) end
            return
        end
        local offset = getArcOffset(distance) + s.Shooting.ShotYAxis
        if s.Shooting.HumanizeAim then
            local strength = s.Shooting.HumanizeStrength or 1.2
            local missChance = (s.Shooting.MissChance or 12) / 100
            if math.random() < missChance then
                if math.random() < 0.5 then
                    offset += strength * 3 + math.random() * strength * 2
                else
                    offset -= strength * 3 + math.random() * strength * 2
                end
            else
                offset += (math.random() * 2 - 1) * strength
            end
        end
        settarget(velocify(goal.Position + Vector3.new(0, offset, 0), distance))
    end

    local actorcode = [==[
local registry = game:GetService("SharedTableRegistry")
local players = game:GetService("Players")
local st = registry:GetSharedTable(__fatalaimtable)
local camera = workspace.CurrentCamera
local function target() local v = st.t return typeof(v) == "Vector3" and v or nil end
local function aimcframe()
    local v = target()
    local char = players.LocalPlayer.Character
    local head = char and char:FindFirstChild("Head")
    if v and head then return CFrame.new(head.Position, v) end
end
pcall(function()
    local oldrender
    oldrender = hookfunction(camera.GetRenderCFrame, function(self, ...) return aimcframe() or oldrender(self, ...) end)
    local oldscreen
    oldscreen = hookfunction(camera.ScreenPointToRay, function(self, ...)
        local v = aimcframe()
        if v then return Ray.new(v.Position, v.LookVector) end
        return oldscreen(self, ...)
    end)
    local oldviewport
    oldviewport = hookfunction(camera.ViewportPointToRay, function(self, ...)
        local v = aimcframe()
        if v then return Ray.new(v.Position, v.LookVector) end
        return oldviewport(self, ...)
    end)
    local cameradata = registry:GetSharedTable("CameraData")
    local history = cameradata.CameraHistory
    local meta = getrawmetatable(cameradata)
    local oldnewindex
    oldnewindex = hookfunction(meta.__newindex, newcclosure(function(tab, key, value)
        local current = tab == cameradata and key == "CameraCFrame"
        local previous = history ~= nil and tab == history and type(key) == "number"
        local aimed = aimcframe()
        if aimed and (current or previous) then return oldnewindex(tab, key, aimed) end
        return oldnewindex(tab, key, value)
    end))
end)
]==]

    local function hookmain()
        pcall(function()
            state.actorname = "sa" .. tostring(math.floor(os.clock() * 100000)) .. tostring(math.random(10000, 99999))
            state.actorst = SharedTableRegistry:GetSharedTable(state.actorname)
            state.actorst.t = nil
            local cameradata = SharedTableRegistry:GetSharedTable("CameraData")
            local history = cameradata.CameraHistory
            local meta = getrawmetatable(cameradata)
            state.oldnewindex = hookfunction(meta.__newindex, newcclosure(function(tab, key, value)
                local current = tab == cameradata and key == "CameraCFrame"
                local previous = history ~= nil and tab == history and type(key) == "number"
                local tgt = state.target
                if tgt and (current or previous) and typeof(value) == "CFrame" then
                    local char = LocalPlayer.Character
                    local head = char and char:FindFirstChild("Head")
                    if head then
                        return state.oldnewindex(tab, key, CFrame.new(head.Position, tgt))
                    end
                end
                return state.oldnewindex(tab, key, value)
            end))
        end)
    end

    local function hookactors()
        if type(getactors) ~= "function" or type(run_on_actor) ~= "function" or not state.actorname then return end
        local ok, actors = pcall(getactors)
        if not ok or type(actors) ~= "table" then return end
        local code = "local __fatalaimtable = " .. string.format("%q", state.actorname) .. " " .. actorcode
        for _, actor in actors do
            if not state.actors[actor] then
                if pcall(run_on_actor, actor, code) then
                    state.actors[actor] = true
                end
            end
        end
    end

    hookmain()
    hookactors()

    addconnection(Players.PlayerAdded:Connect(function() task.defer(hookactors) end))
    addconnection(RunService.Heartbeat:Connect(updateAuralTarget))

    local function setupCharacterAural(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        local jumps = 0
        addconnection(hum.Jumping:Connect(function(active)
            if not active then return end
            if not s.Shooting.AuralEnabled or not hasball(char) then return end
            if s.Shooting.EBLHop then
                jumps += 1
                if jumps < 2 then return end
                jumps = 0
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local goal, distance = nearestgoal(root)
            local minDist = isMobile and 30 or AURAL_MIN_DIST
            if not goal or distance < minDist or distance > AURAL_MAX_DIST then return end
            local arc = getArcOffset(distance) + s.Shooting.ShotYAxis
            local targetPos = nil
            if s.Shooting.HumanizeAim then
                local strength = s.Shooting.HumanizeStrength or 1.2
                local missChance = (s.Shooting.MissChance or 12) / 100
                if math.random() < missChance then
                    local mode = math.random(1, 3)
                    if mode == 1 then
                        arc += strength * 3 + math.random() * strength * 2
                    elseif mode == 2 then
                        arc -= strength * 3 + math.random() * strength * 2
                    else
                        local side = (math.random() < 0.5) and -1 or 1
                        targetPos = goal.Position
                            + Vector3.new(0, getArcOffset(distance) + s.Shooting.ShotYAxis, 0)
                            + Camera.CFrame.RightVector * (side * (strength * 2 + math.random() * 2))
                    end
                else
                    arc += (math.random() * 2 - 1) * strength
                end
            end
            targetPos = targetPos or goal.Position + Vector3.new(0, arc, 0)
            settarget(targetPos)
            task.wait(0.05)
            LocalPlayer:SetAttribute("Power", 85)
            local shotdelay = s.Shooting.ShotDelay or 0.25
            if s.Shooting.RandomizeShotDelay then
                local mn = s.Shooting.ShotDelayMin or 0.15
                local mx = s.Shooting.ShotDelayMax or 0.35
                if mx < mn then mx = mn end
                shotdelay = mn + math.random() * (mx - mn)
            end
            task.wait(shotdelay)
            doClick()
            task.wait(0.1)
            updateAuralTarget(0.1)
        end))
    end

    if LocalPlayer.Character then setupCharacterAural(LocalPlayer.Character) end
    addconnection(LocalPlayer.CharacterAdded:Connect(setupCharacterAural))

    local Window = Airflow:CreateWindow({Name = "ByteWtf", LoadingSubtitle = "Byte On Top", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "FatalLabs", FileName = "FatalLabs"}})

    Notify = function(props) Window:Notify(props) end

    local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local MoveTab = Window:CreateTab({ Name = "Movement", Icon = "activity" })

    CombatTab:CreateSection("Silent Aim")
    CombatTab:CreateToggle({
        Name = "Enable Silent Aim",
        Desc = "Automatically Shoots when you Jump",
        Flag = "fatal_aural",
        CurrentValue = s.Shooting.AuralEnabled,
        Callback = function(v) setAural(v) end,
    })
    CombatTab:CreateKeybind({
        Name = "Aimbot keybind",
        Flag = "fatal_aural_key",
        CurrentValue = s.Shooting.AuralKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AuralKeybind = key end
        end,
    })
    CombatTab:CreateSlider({
        Name = "Shot delay",
        Range = { 0.15, 0.42 }, Increment = 0.01, Suffix = "s",
        CurrentValue = s.Shooting.ShotDelay, Flag = "fatal_delay",
        Callback = function(v) s.Shooting.ShotDelay = v end,
    })
    CombatTab:CreateToggle({
        Name = "Randomize shot delay", Flag = "fatal_randdelay",
        CurrentValue = s.Shooting.RandomizeShotDelay,
        Callback = function(v) s.Shooting.RandomizeShotDelay = v end,
    })
    CombatTab:CreateSlider({
        Name = "Min delay", Range = { 0, 1 }, Increment = 0.05, Suffix = "s",
        CurrentValue = s.Shooting.ShotDelayMin, Flag = "fatal_mindelay",
        Callback = function(v) s.Shooting.ShotDelayMin = v end,
    })
    CombatTab:CreateSlider({
        Name = "Max delay", Range = { 0, 1 }, Increment = 0.05, Suffix = "s",
        CurrentValue = s.Shooting.ShotDelayMax, Flag = "fatal_maxdelay",
        Callback = function(v) s.Shooting.ShotDelayMax = v end,
    })
    CombatTab:CreateToggle({
        Name = "EBL Hop", Desc = "Require second jump before firing.",
        Flag = "fatal_ebl", CurrentValue = s.Shooting.EBLHop,
        Callback = function(v) s.Shooting.EBLHop = v end,
    })
    CombatTab:CreateToggle({
        Name = "Humanize aim", Flag = "fatal_human",
        CurrentValue = s.Shooting.HumanizeAim,
        Callback = function(v) s.Shooting.HumanizeAim = v end,
    })
    CombatTab:CreateSlider({
        Name = "Humanize strength", Range = { 0.2, 5 }, Increment = 0.1,
        CurrentValue = s.Shooting.HumanizeStrength, Flag = "fatal_hstr",
        Callback = function(v) s.Shooting.HumanizeStrength = v end,
    })
    CombatTab:CreateSlider({
        Name = "Miss chance", Range = { 0, 80 }, Increment = 1, Suffix = "%",
        CurrentValue = s.Shooting.MissChance, Flag = "fatal_miss",
        Callback = function(v) s.Shooting.MissChance = v end,
    })

    CombatTab:CreateSection("Auto Guard")
    CombatTab:CreateToggle({
        Name = "Auto guard", Flag = "fatal_guard", CurrentValue = s.Defending.AutoGuard,
        Callback = function(v) setGuard(v) end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto guard keybind", Flag = "fatal_guard_key",
        CurrentValue = s.Defending.GuardKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Defending.GuardKeybind = key end
        end,
    })
    CombatTab:CreateDropdown({
        Name = "Guard mode", Options = { "Reactive", "Balanced", "Aggressive" },
        CurrentValue = s.Defending.AutoGuardMode, Flag = "fatal_guard_mode",
        Callback = function(v) s.Defending.AutoGuardMode = v end,
    })
    CombatTab:CreateToggle({
        Name = "Guard nearest if no dribbler", Flag = "fatal_guard_near",
        CurrentValue = s.Defending.AutoGuardNearest,
        Callback = function(v) s.Defending.AutoGuardNearest = v end,
    })
    CombatTab:CreateSlider({
        Name = "Guard range", Range = { 10, 60 }, Increment = 1,
        CurrentValue = s.Defending.AutoGuardRange, Flag = "fatal_guard_range",
        Callback = function(v) s.Defending.AutoGuardRange = v end,
    })
    CombatTab:CreateSlider({
        Name = "Prediction strength", Range = { 0.1, 1 }, Increment = 0.05,
        CurrentValue = s.Defending.GuardPrediction, Flag = "fatal_guard_pred",
        Callback = function(v) s.Defending.GuardPrediction = v end,
    })

    BallTab:CreateSection("Ball Magnet")
    BallTab:CreateToggle({
        Name = "Ball magnet", Flag = "fatal_mag", CurrentValue = s.Ball.BallMags,
        Callback = function(v) setMagnet(v) end,
    })
    BallTab:CreateKeybind({
        Name = "Magnet keybind", Flag = "fatal_mag_key", CurrentValue = Enum.KeyCode.M,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Ball.MagnetKeybind = key.Name end
        end,
    })
    BallTab:CreateSlider({
        Name = "Magnet size", Range = { 1, 50 }, Increment = 1,
        CurrentValue = s.Ball.BallMagRange, Flag = "fatal_mag_size",
        Callback = function(v)
            s.Ball.BallMagRange = v
            if magnetHitbox then magnetHitbox.Size = Vector3.new(v, v, v) end
        end,
    })
    BallTab:CreateSection("Ball Reach")
    BallTab:CreateToggle({
        Name = "Ball reach", Flag = "fatal_reach", CurrentValue = s.Ball.BallReach,
        Callback = function(v) setReach(v) end,
    })
    BallTab:CreateKeybind({
        Name = "Reach keybind", Flag = "fatal_reach_key", CurrentValue = Enum.KeyCode.N,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Ball.ReachKeybind = key.Name end
        end,
    })
    BallTab:CreateSlider({
        Name = "Reach size", Range = { 1, 30 }, Increment = 1,
        CurrentValue = s.Ball.BallReachRange, Flag = "fatal_reach_size",
        Callback = function(v) s.Ball.BallReachRange = v end,
    })

    buildHVHTab(MoveTab, s.HVH)

    MoveTab:CreateSection("TPWalk")
    MoveTab:CreateToggle({
        Name = "tpwalk",
        Desc = "Teleport-walk; nudges your root part each frame for a smooth glide.",
        Flag = "fatal_tpwalk", CurrentValue = s.TPWalk.Enabled,
        Callback = function(v) setTPWalk(v) end,
    })
    MoveTab:CreateKeybind({
        Name = "tpwalk keybind", Flag = "fatal_tpwalk_key",
        CurrentValue = s.TPWalk.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.TPWalk.Keybind = key end
        end,
    })
    MoveTab:CreateSlider({
        Name = "tpwalk speed", Desc = "Step distance per frame (0.001 – 0.06).",
        Range = { 0.001, 0.06 }, Increment = 0.001,
        CurrentValue = s.TPWalk.Speed, Flag = "fatal_tpwalk_speed",
        Callback = function(v) s.TPWalk.Speed = v end,
    })

    setAural = function(on)
        s.Shooting.AuralEnabled = (on == nil) and (not s.Shooting.AuralEnabled) or on
        MobileRefresh()
    end
    setGuard = function(on)
        s.Defending.AutoGuard = (on == nil) and (not s.Defending.AutoGuard) or on
        if s.Defending.AutoGuard then enableAutoGuard() else disableAutoGuard() end
        MobileRefresh()
    end
    setMagnet = function(on)
        s.Ball.BallMags = (on == nil) and (not s.Ball.BallMags) or on
        if s.Ball.BallMags then enableMagnet() else disableMagnet() end
        MobileRefresh()
    end
    setReach = function(on)
        s.Ball.BallReach = (on == nil) and (not s.Ball.BallReach) or on
        if s.Ball.BallReach then enableReach() else disableReach() end
        MobileRefresh()
    end
    setTPWalk = function(on)
        s.TPWalk.Enabled = (on == nil) and (not s.TPWalk.Enabled) or on
        if s.TPWalk.Enabled then enableTPWalk() else disableTPWalk() end
        MobileRefresh()
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local magKey = s.Ball.MagnetKeybind
        if magKey and input.KeyCode == Enum.KeyCode[magKey] then setMagnet() end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local bind = s.Shooting.AuralKeybind
        local targetKey = (type(bind) == "string") and Enum.KeyCode[bind] or bind
        if input.KeyCode == targetKey then setAural() end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local bind = s.Defending.GuardKeybind
        local targetKey = (type(bind) == "string") and Enum.KeyCode[bind] or bind
        if input.KeyCode == targetKey then setGuard() end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local bind = s.HVH.Speed.Keybind
        local targetKey = (type(bind) == "string") and Enum.KeyCode[bind] or bind
        if input.KeyCode == targetKey then
            s.HVH.Speed.Enabled = not s.HVH.Speed.Enabled
        end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == s.TPWalk.Keybind then setTPWalk() end
    end)

    if isMobile then
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "ByteMobile"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.DisplayOrder = 200
        pcall(function()
            if gethui then ScreenGui.Parent = gethui()
            else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
        end)

        local Panel = Instance.new("Frame")
        Panel.Name = "Panel"
        Panel.Size = UDim2.fromOffset(52, 270)
        Panel.Position = UDim2.new(1, -64, 0.5, -135)
        Panel.BackgroundTransparency = 1
        Panel.Parent = ScreenGui

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 5)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Panel

        local function makeButton(label, order, onClick, isOn)
            local Button = Instance.new("TextButton")
            Button.Name = label
            Button.Size = UDim2.fromOffset(52, 40)
            Button.BackgroundColor3 = isOn and Color3.fromRGB(190, 165, 240) or Color3.fromRGB(26, 26, 28)
            Button.BackgroundTransparency = 0.05
            Button.Text = label
            Button.TextColor3 = isOn and Color3.fromRGB(20, 15, 30) or Color3.fromRGB(235, 230, 255)
            Button.TextSize = 12
            Button.Font = Enum.Font.GothamBold
            Button.AutoButtonColor = false
            Button.LayoutOrder = order
            Button.Parent = Panel
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(1, 0)
            Corner.Parent = Button
            local Stroke = Instance.new("UIStroke")
            Stroke.Color = isOn and Color3.fromRGB(220, 200, 255) or Color3.fromRGB(100, 88, 130)
            Stroke.Thickness = 1.2
            Stroke.Transparency = 0.15
            Stroke.Parent = Button
            Button.MouseButton1Click:Connect(onClick)
            return Button, Stroke
        end

        local Aim, AimS = makeButton("Aim", 1, function() setAural() end, s.Shooting.AuralEnabled)
        local Guard, GuardS = makeButton("Guard", 2, function() setGuard() end, s.Defending.AutoGuard)
        local Mag, MagS = makeButton("Mag", 3, function() setMagnet() end, s.Ball.BallMags)
        local Reach, ReachS = makeButton("Reach", 4, function() setReach() end, s.Ball.BallReach)
        local TPW, TPWS = makeButton("TPWalk", 5, function() setTPWalk() end, s.TPWalk.Enabled)

        local function paint(btn, stroke, on)
            btn.BackgroundColor3 = on and Color3.fromRGB(190, 165, 240) or Color3.fromRGB(26, 26, 28)
            btn.TextColor3 = on and Color3.fromRGB(20, 15, 30) or Color3.fromRGB(235, 230, 255)
            stroke.Color = on and Color3.fromRGB(220, 200, 255) or Color3.fromRGB(100, 88, 130)
        end

        MobileRefresh = function()
            paint(Aim, AimS, s.Shooting.AuralEnabled)
            paint(Guard, GuardS, s.Defending.AutoGuard)
            paint(Mag, MagS, s.Ball.BallMags)
            paint(Reach, ReachS, s.Ball.BallReach)
            paint(TPW, TPWS, s.TPWalk.Enabled)
        end

        local dragging = false
        local dragStart, startPos
        Panel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Panel.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStart
                Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        OnCleanup(function()
            pcall(function() ScreenGui:Destroy() end)
        end)
    end

    hvhStart()

    OnCleanup(function()
        pcall(disableAutoGuard)
        pcall(disableMagnet)
        pcall(disableReach)
        pcall(disableTPWalk)
        pcall(hvhResetAll)
        pcall(hvhStop)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end)
end
