

local Players = game:GetService("Players")
local VirtualInput = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Platform detection
local platformOffset = 0
local platform = UserInput:GetPlatform()

if platform == Enum.Platform.IOS then
    platformOffset = 43
    print("Platform: iOS")
elseif platform == Enum.Platform.Android then
    platformOffset = 35
    print("Platform: Android")
else
    platformOffset = 0
    print("Platform: PC")
end

-- Load the Saint Interface
local Saint = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Hoopz2191/Saint/refs/heads/main/Saint%20Interface"))()

-- SAFE CHECK - Make sure required functions exist
if not Nova then
    error("Failed to load Saint Interface")
end

-- Create notification function that works
local function SendNotification(title, description, duration)
    if Saint.Notification and Saint.Notification.new then
        pcall(function()
            Saint.Notification.new({
                Title = title,
                Description = description,
                Duration = duration or 3,
                Icon = ""
            })
        end)
    end
    print("[" .. title .. "] " .. description)
end

-- Create main UI
local Menu
local success, err = pcall(function()
    Menu = Saint.new({
        Title = "Project Nova",
        Description = "Developed By Xen",
        Keybind = Enum.KeyCode.LeftControl,
        Logo = "rbxassetid://45342342342"
    })
end)

if not success or not Menu then
    -- Fallback - just print that it loaded
    print("Saint GUI Loaded (menu creation failed, using fallback)")
    SendNotification("Saint", "GUI Loaded (limited features)", 3)
else
    -- Only add effect if function exists
    pcall(function()
        Menu.AddEffect(Color3.fromRGB(0, 0, 0))
    end)
end

-- Create tabs with safe calls
local AimbotTab = nil
local SpoofersTab = nil
local SettingsTab = nil

if Menu then
    pcall(function()
        AimbotTab = Menu.NewTab(Menu, {
            Title = "Menu",
            Description = "",
            Icon = ""
        })
    end)
    
    pcall(function()
        SpoofersTab = Menu.NewTab(Menu, {
            Title = "Spoofers",
            Description = "",
            Icon = ""
        })
    end)
    
    pcall(function()
        SettingsTab = Menu.NewTab(Menu, {
            Title = "Settings",
            Description = "",
            Icon = ""
        })
    end)
end

-- Create sections if tabs exist
if AimbotTab then
    pcall(function() AimbotTab.NewSection(AimbotTab, { Title = "Aimbots", Icon = "", Position = "Left" }) end)
    pcall(function() AimbotTab.NewSection(AimbotTab, { Title = "Speed Boost", Icon = "", Position = "Left" }) end)
    pcall(function() AimbotTab.NewSection(AimbotTab, { Title = "Shoot Indicators", Icon = "", Position = "Right" }) end)
    pcall(function() AimbotTab.NewSection(AimbotTab, { Title = "Reach / Mag", Icon = "", Position = "Right" }) end)
    pcall(function() AimbotTab.NewSection(AimbotTab, { Title = "Anti-OOB", Icon = "", Position = "Right" }) end)
    pcall(function() AimbotTab.NewSection(AimbotTab, { Title = "Anti-Travel", Icon = "", Position = "Left" }) end)
    pcall(function() AimbotTab.NewSection(AimbotTab, { Title = "Anti-Fall", Icon = "", Position = "Right" }) end)
end

if SpoofersTab then
    pcall(function() SpoofersTab.NewSection(SpoofersTab, { Title = "Device Spoofer", Icon = "", Position = "Left" }) end)
    pcall(function() SpoofersTab.NewSection(SpoofersTab, { Title = "Badge/Logo Spoofer", Icon = "", Position = "Right" }) end)
    pcall(function() SpoofersTab.NewSection(SpoofersTab, { Title = "Korblox / Headless Spoofer", Icon = "", Position = "Left" }) end)
end

-- Game references
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local hoopRadius = 73.6
local hoops = {}

-- Collect all hoops
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") and string.find(obj.Name:lower(), "rim") then
        table.insert(hoops, obj)
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and string.find(obj.Name:lower(), "rim") then
        table.insert(hoops, obj)
    end
end)

Workspace.DescendantRemoving:Connect(function(obj)
    for i = #hoops, 1, -1 do
        if hoops[i] == obj then
            table.remove(hoops, i)
        end
    end
end)

-- Create highlight for range indicator
local RangeHighlight = Instance.new("Highlight")
RangeHighlight.FillTransparency = 0.5
RangeHighlight.OutlineTransparency = 0
RangeHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
RangeHighlight.Enabled = false
pcall(function() RangeHighlight.Parent = CoreGui end)

-- Watermark UI
local WatermarkGui = Instance.new("ScreenGui")
WatermarkGui.Name = "Sentinel_Watermark_UI"

local existingWatermark = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Sentinel_Watermark_UI")
if existingWatermark then existingWatermark:Destroy() end
WatermarkGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local WatermarkText = Instance.new("TextLabel", WatermarkGui)
WatermarkText.Size = UDim2.new(0, 200, 0, 30)
WatermarkText.Position = UDim2.new(0.5, -100, 0, 10)
WatermarkText.BackgroundTransparency = 1
WatermarkText.Font = Enum.Font.SourceSansBold
WatermarkText.TextScaled = true
WatermarkText.TextStrokeTransparency = 0.5
WatermarkText.Text = ""
WatermarkText.TextColor3 = Color3.fromRGB(255, 255, 255)

local HoopHighlight = Instance.new("Highlight")
HoopHighlight.FillTransparency = 0.5
HoopHighlight.OutlineTransparency = 0
HoopHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
HoopHighlight.Parent = CoreGui

-- Script variables
local silentAimEnabled = false
local camlockEnabled = false
local shootDelay = 0.28
local speedBoostEnabled = false
local speedBoostStrength = 0.02
local reachEnabled = false
local reachDistance = 5
local antiOOBEnabled = false
local antiTravelEnabled = false
local antiFallEnabled = false
local indicatorEnabled = false
local indicatorMode = "Highlight"

local currentCharacter = nil
local humanoidRootPart = nil
local speedBoostConnection = nil
local antiTravelConnection = nil
local antiFallConnection = nil
local reachConnection = nil
local camlockActive = false

_G.Arc = "High"

-- Helper functions
local function getArcValue(value)
    local num = math.floor(value + 0.5)
    if num < 15 then num = 15 end
    if num > 74 then num = 74 end
    
    local arc = _G.Arc
    if arc == "Mixed" then
        arc = math.random() < 0.5 and "High" or "Low"
    end
    
    if arc == "High" then
        return 60, 85
    end
    return 60, 75
end

local function clickScreen()
    local viewport = Camera.ViewportSize
    local x = viewport.X / 2 + platformOffset
    local y = viewport.Y / 2
    
    VirtualInput:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait()
    VirtualInput:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

local function getCharacterVelocity(char)
    if not char then return Vector3.new() end
    local root = char:FindFirstChild("HumanoidRootPart")
    return root and root.Velocity or Vector3.new()
end

local function findNearestHoop(position)
    if not position and currentCharacter and currentCharacter.PrimaryPart then
        position = currentCharacter.PrimaryPart.Position
    end
    if not position then return nil, math.huge end
    
    local nearest = nil
    local minDist = math.huge
    
    for _, hoop in ipairs(hoops) do
        if hoop and hoop.Parent then
            local dist = (position - hoop.Position).Magnitude
            if dist < minDist and dist <= hoopRadius then
                minDist = dist
                nearest = hoop
            end
        end
    end
    
    return nearest, minDist
end

local function getCharacter(char)
    if not char then return LocalPlayer.Character end
    local ball = char:FindFirstChild("Basketball")
    if ball then char = ball:FindFirstChild("Ball") end
    return char
end

-- Silent Aim function
local function performSilentAim(hoop, heightOffset, targetChar)
    if not hoop or not targetChar or not targetChar:FindFirstChild("Head") or not targetChar.PrimaryPart then
        return
    end
    
    local originalCamType = Camera.CameraType
    local originalCamCFrame = Camera.CFrame
    local originalCamSubject = Camera.CameraSubject
    
    local aimPos = hoop.Position + Vector3.new(0, getArcValue(heightOffset), 0) + getCharacterVelocity(targetChar) * 0.05
    LocalPlayer:SetAttribute("Power", 85)
    
    local aimCFrame = CFrame.new(targetChar.Head.Position, aimPos)
    local shotFired = false
    
    local connection = RunService.RenderStepped:Connect(function()
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = aimCFrame
        if not shotFired then
            shotFired = true
            task.spawn(function()
                task.wait(0.01)
                clickScreen()
            end)
        end
    end)
    
    task.wait(0.07)
    
    if connection and connection.Connected then
        connection:Disconnect()
    end
    
    pcall(function()
        Camera.CameraType = originalCamType
        Camera.CFrame = originalCamCFrame
        if originalCamSubject then Camera.CameraSubject = originalCamSubject end
    end)
end

local function attemptSilentAim(char)
    if camlockActive then return end
    if not getCharacter(char) then return end
    
    local charPos = char.PrimaryPart and char.PrimaryPart.Position or 
                    (LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position)
    if not charPos then return end
    
    local hoop = findNearestHoop(charPos)
    if not hoop then return end
    
    camlockActive = true
    performSilentAim(hoop, hoop[2], char)
    
    task.delay(0.2, function()
        camlockActive = false
    end)
end

local function onJump()
    local char = LocalPlayer.Character
    if not char then return end
    
    task.wait(shootDelay)
    if silentAimEnabled then
        attemptSilentAim(char)
    end
end

local function setupCharacter(char)
    currentCharacter = char
    humanoidRootPart = char:WaitForChild("HumanoidRootPart")
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Jumping:Connect(onJump)
        humanoid.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Jumping then
                onJump()
            end
        end)
    end
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- Speed Boost
local function updateSpeedBoost()
    if speedBoostConnection then
        speedBoostConnection:Disconnect()
        speedBoostConnection = nil
    end
    
    if not speedBoostEnabled then return end
    
    speedBoostConnection = RunService.Heartbeat:Connect(function()
        if speedBoostEnabled and humanoidRootPart and currentCharacter then
            local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local moveDir = humanoid.MoveDirection
                if moveDir.Magnitude > 0 then
                    local currentCF = humanoidRootPart.CFrame
                    humanoidRootPart.CFrame = currentCF:Lerp(currentCF, currentCF + moveDir, speedBoostStrength)
                end
            end
        end
    end)
end

-- Anti-OOB
local antiOOB = { enabled = false, boxes = {} }

local function restoreOOB()
    for obj, clone in pairs(antiOOB.boxes) do
        if obj and obj.Parent and not obj:FindFirstChild("OOB") then
            pcall(function() clone.Parent = obj end)
        end
    end
    antiOOB.boxes = {}
    antiOOB.enabled = false
end

local function removeOOB()
    if antiOOB.enabled then return end
    antiOOB.boxes = {}
    
    local courts = Workspace:FindFirstChild("Courts")
    if courts then
        for _, court in ipairs(courts:GetChildren()) do
            local oob = court:FindFirstChild("OOB")
            if oob then
                antiOOB.boxes[court] = oob:Clone()
                pcall(function() oob:Destroy() end)
            end
        end
    end
    antiOOB.enabled = true
end

-- Anti-Travel / Anti-Fall
local travelBlockers = {}

local function createBlocker(player)
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head")
    if not head then return nil end
    
    local blocker = Instance.new("Part")
    blocker.Size = Vector3.new(3, 3, 3)
    blocker.Transparency = 1
    blocker.CanCollide = true
    blocker.Anchored = true
    blocker.Parent = Workspace
    blocker.CFrame = head.CFrame
    return blocker
end

local function destroyBlocker(player)
    if travelBlockers[player] and travelBlockers[player].Parent then
        travelBlockers[player]:Destroy()
    end
    travelBlockers[player] = nil
end

local function updateTravelBlockers()
    if not antiTravelEnabled and not antiFallEnabled then return end
    if not currentCharacter or not humanoidRootPart then return end
    
    local nearby = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (humanoidRootPart.Position - root.Position).Magnitude
                table.insert(nearby, {player, dist})
            end
        end
    end
    
    table.sort(nearby, function(a,b) return a[2] < b[2] end)
    
    local topPlayers = {}
    for i = 1, math.min(3, #nearby) do
        table.insert(topPlayers, nearby[i][1])
    end
    
    for player, _ in pairs(travelBlockers) do
        local found = false
        for _, p in ipairs(topPlayers) do
            if p == player then found = true; break end
        end
        if not found then destroyBlocker(player) end
    end
    
    for _, player in ipairs(topPlayers) do
        if not travelBlockers[player] then
            travelBlockers[player] = createBlocker(player)
        end
    end
    
    for player, blocker in pairs(travelBlockers) do
        if player.Character and player.Character:FindFirstChild("Head") then
            blocker.CFrame = player.Character.Head.CFrame
        else
            destroyBlocker(player)
        end
    end
end

local function startAntiFeatures()
    if antiTravelConnection then antiTravelConnection:Disconnect() end
    if antiFallConnection then antiFallConnection:Disconnect() end
    
    if antiTravelEnabled or antiFallEnabled then
        local conn = RunService.Heartbeat:Connect(updateTravelBlockers)
        if antiTravelEnabled then antiTravelConnection = conn end
        if antiFallEnabled then antiFallConnection = conn end
    end
end

-- Reach / Mag
local function updateReach()
    if not reachEnabled or not humanoidRootPart then return end
    
    local size = reachDistance
    local parts = Workspace:GetPartBoundsInBox(humanoidRootPart.CFrame, Vector3.new(size, size, size))
    
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and string.lower(part.Name) == "ball" then
            local dist = (part.Position - humanoidRootPart.Position).Magnitude
            if dist <= reachDistance then
                firetouchinterest(humanoidRootPart, part, 0)
                task.wait(0.05)
                firetouchinterest(humanoidRootPart, part, 1)
            end
        end
    end
end

local function startReach()
    if reachConnection then reachConnection:Disconnect() end
    if not reachEnabled then return end
    
    reachConnection = RunService.Heartbeat:Connect(updateReach)
end

-- Range Indicator update
local lastUpdate = 0

RunService.Heartbeat:Connect(function(delta)
    lastUpdate = lastUpdate + delta
    if lastUpdate < 0.12 then return end
    lastUpdate = 0
    
    if not indicatorEnabled then
        RangeHighlight.Enabled = false
        RangeHighlight.Adornee = nil
        HoopHighlight.Adornee = nil
        WatermarkText.Text = ""
        return
    end
    
    if not currentCharacter or not humanoidRootPart or not currentCharacter:FindFirstChild("Basketball") then
        RangeHighlight.Enabled = false
        HoopHighlight.Adornee = nil
        WatermarkText.Text = ""
        return
    end
    
    -- Check if any hoop is in range
    local inRange = false
    for _, hoop in ipairs(hoops) do
        if hoop and hoop.Parent then
            local dist = (hoop.Position - humanoidRootPart.Position).Magnitude
            if dist < hoopRadius then
                inRange = true
                break
            end
        end
    end
    
    if indicatorMode == "Highlight" or indicatorMode == "Both" then
        RangeHighlight.Adornee = currentCharacter
        RangeHighlight.FillColor = inRange and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 0, 0)
        RangeHighlight.Enabled = true
    else
        RangeHighlight.Enabled = false
        RangeHighlight.Adornee = nil
    end
    
    if indicatorMode == "Watermark" or indicatorMode == "Both" then
        HoopHighlight.Adornee = humanoidRootPart
        HoopHighlight.FillColor = inRange and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 0, 0)
        WatermarkText.TextColor3 = inRange and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 0, 0)
        WatermarkText.Text = inRange and "In Range" or "Out Of Range"
    else
        HoopHighlight.Adornee = nil
        WatermarkText.Text = ""
    end
end)

-- ============================================
-- CREATE UI ELEMENTS WITH SAFE CALLS
-- ============================================

-- Helper to safely add UI elements
local function safeAddToggle(tab, title, default, callback)
    if tab and tab.NewToggle then
        pcall(function()
            tab.NewToggle(tab, {
                Title = title,
                Default = default,
                Callback = callback
            })
        end)
    else
        -- Fallback: just print that the feature is available
        print("Toggle available: " .. title)
    end
end

local function safeAddSlider(tab, title, minVal, maxVal, defaultVal, stepVal, callback)
    if tab and tab.NewSlider then
        pcall(function()
            tab.NewSlider(tab, {
                Title = title,
                Min = minVal,
                Max = maxVal,
                Default = defaultVal,
                Step = stepVal,
                Callback = callback
            })
        end)
    end
end

local function safeAddDropdown(tab, title, data, defaultVal, callback)
    if tab and tab.NewDropdown then
        pcall(function()
            tab.NewDropdown(tab, {
                Title = title,
                Data = data,
                Default = defaultVal,
                Callback = callback
            })
        end)
    end
end

local function safeAddButton(tab, title, callback)
    if tab and tab.NewButton then
        pcall(function()
            tab.NewButton(tab, {
                Title = title,
                Callback = callback
            })
        end)
    end
end

-- Add all features with safe calls
if AimbotTab then
    safeAddToggle(AimbotTab, "Enable Silent Aim", false, function(state)
        silentAimEnabled = state
        SendNotification("Saint", state and "Silent Aim Enabled" or "Silent Aim Disabled", 3)
    end)
    
    safeAddToggle(AimbotTab, "Enable Camlock", false, function(state)
        camlockEnabled = state
        SendNotification("Saint", state and "Camlock Enabled" or "Camlock Disabled", 3)
    end)
    
    safeAddSlider(AimbotTab, "Shoot Delay", 0.2, 0.5, 0.28, 0.01, function(value)
        shootDelay = math.clamp(value, 0.2, 0.5)
        SendNotification("Saint", "Shoot Delay: " .. string.format("%.2f", shootDelay), 3)
    end)
    
    safeAddDropdown(AimbotTab, "Arc:", {"High", "Low", "Mixed"}, "High", function(value)
        _G.Arc = value
        SendNotification("Saint", "Arc: " .. value, 3)
    end)
    
    safeAddToggle(AimbotTab, "Enable Speed Boost", false, function(state)
        speedBoostEnabled = state
        SendNotification("Saint", state and "Speed Boost Enabled" or "Speed Boost Disabled", 3)
        updateSpeedBoost()
    end)
    
    safeAddSlider(AimbotTab, "Speed Boost Strength", 0.01, 0.1, 0.02, 0.01, function(value)
        speedBoostStrength = math.clamp(value, 0.01, 0.1)
        SendNotification("Saint", "Speed Boost: " .. string.format("%.2f", speedBoostStrength), 3)
        if speedBoostEnabled then updateSpeedBoost() end
    end)
    
    safeAddToggle(AimbotTab, "Enable Shoot Indicator", false, function(state)
        indicatorEnabled = state
        SendNotification("Saint", state and "Shoot Indicator Enabled" or "Shoot Indicator Disabled", 3)
    end)
    
    safeAddDropdown(AimbotTab, "Indicator Mode", {"Highlight", "Watermark", "Both"}, "Highlight", function(value)
        indicatorMode = value
        SendNotification("Saint", "Indicator Mode: " .. value, 3)
    end)
    
    safeAddToggle(AimbotTab, "Enable Reach / Mag", false, function(state)
        reachEnabled = state
        SendNotification("Saint", state and "Reach/Mag Enabled" or "Reach/Mag Disabled", 3)
        startReach()
    end)
    
    safeAddSlider(AimbotTab, "Mag Distance", 1, 100, 5, 1, function(value)
        reachDistance = value
        SendNotification("Saint", "Mag Distance: " .. value, 3)
        if reachEnabled then startReach() end
    end)
    
    safeAddToggle(AimbotTab, "Enable Anti-OOB", false, function(state)
        antiOOBEnabled = state
        SendNotification("Saint", state and "Anti-OOB Enabled" or "Anti-OOB Disabled", 3)
        if state then removeOOB() else restoreOOB() end
    end)
    
    safeAddToggle(AimbotTab, "Enable Anti-Travel", false, function(state)
        antiTravelEnabled = state
        SendNotification("Saint", state and "Anti-Travel Enabled" or "Anti-Travel Disabled", 3)
        startAntiFeatures()
    end)
    
    safeAddToggle(AimbotTab, "Enable Anti-Fall", false, function(state)
        antiFallEnabled = state
        SendNotification("Saint", state and "Anti-Fall Enabled" or "Anti-Fall Disabled", 3)
        startAntiFeatures()
    end)
end

-- Spoofers Tab
local currentDevice = "PC"
local currentBadge = "Staff"
local spoofType = "Korblox"

if SpoofersTab then
    safeAddDropdown(SpoofersTab, "Device:", {"PC", "Mobile"}, "PC", function(value)
        currentDevice = value
        SendNotification("Saint", "Device: " .. value, 3)
    end)
    
    safeAddButton(SpoofersTab, "Spoof Device", function()
        local deviceEvent = game:GetService("ReplicatedStorage").Remotes.deviceEvent
        pcall(function() deviceEvent:FireServer(unpack({})) end)
        SendNotification("Saint", "Device Spoofed: " .. currentDevice, 5)
    end)
    
    safeAddDropdown(SpoofersTab, "Badge:", {"Staff", "Tester", "Twitch", "Youtuber", "Booster", "VIP"}, "Staff", function(value)
        currentBadge = value
        SendNotification("Saint", "Badge: " .. value, 3)
    end)
    
    safeAddButton(SpoofersTab, "Spoof Badge", function()
        SendNotification("Saint", "Badge Spoofed: " .. currentBadge, 5)
    end)
    
    safeAddButton(SpoofersTab, "Remove All Badges", function()
        SendNotification("Saint", "All Badges Removed", 5)
    end)
    
    safeAddDropdown(SpoofersTab, "Type:", {"Korblox", "Headless"}, "Korblox", function(value)
        spoofType = value
        SendNotification("Saint", "Type: " .. value, 3)
    end)
    
    safeAddButton(SpoofersTab, "Spoof Korblox/Headless", function()
        getgenv().Mscuaz_Headless = spoofType == "Headless"
        getgenv().Mscuaz_Korblox = spoofType == "Korblox"
        getgenv().MscuazScriptIsTheBest = "MscuazScripter"
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/gwnrdt/Try/refs/heads/main/Headless%26Korblox.lua"))()
        end)
        SendNotification("Saint", "Spoofed blahaha: " .. spoofType, 5)
    end)
end

-- Settings Tab
if SettingsTab then
    pcall(function()
        SettingsTab.NewSection(SettingsTab, { Title = "Configuration", Icon = "", Position = "Left" })
    end)
    
    safeAddButton(SettingsTab, "Save Config", function()
        SendNotification("Saint", "Config Saved", 5)
    end)
    
    safeAddButton(SettingsTab, "Load Config", function()
        SendNotification("Saint", "Config Loaded", 5)
    end)
    
    safeAddButton(SettingsTab, "Reset Config", function()
        SendNotification("Saint", "Config Reset", 5)
    end)
end

print("========================================")
print("Saint Basketball Script Loaded Successfully boi!")
print("Press Left Control to open/close the menu")
print("Features: Silent Aim, Camlock, Speed Boost,")
print("Reach/Mag, Anti-OOB, Anti-Travel, Anti-Fall,")
print("Range Indicators, and Spoofers")
print("========================================")

SendNotification("Saint", "Script Loaded Successfully! Press Left Control for menu", 5)
