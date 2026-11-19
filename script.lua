-- ============================================================
-- BYTE.WTF UI  (drop-in replacement for the Airflow API)
-- Supports: CreateWindow, CreateTab, CreateSection, CreateToggle,
-- CreateSlider, CreateDropdown, CreateKeybind, CreateButton,
-- CreateButtonRow, CreateInput, CreateLabel, CreateDivider,
-- Window:Notify / SaveConfig / LoadConfig
-- ============================================================
local Airflow = (function()
    local Players          = game:GetService("Players")
    local UIS              = game:GetService("UserInputService")
    local TweenService     = game:GetService("TweenService")
    local HttpService      = game:GetService("HttpService")
    local CoreGui          = game:GetService("CoreGui")
    local LP               = Players.LocalPlayer

    local Lib = { Themes = {}, Assets = {} }
    function Lib:LoadFont() end

    -- palette (taken from the screenshot)
    local C = {
        Window    = Color3.fromRGB(13, 13, 16),
        TitleBar  = Color3.fromRGB(15, 15, 19),
        Panel     = Color3.fromRGB(16, 16, 20),
        Field     = Color3.fromRGB(23, 23, 29),
        Stroke    = Color3.fromRGB(38, 38, 47),
        StrokeLt  = Color3.fromRGB(50, 50, 62),
        Text      = Color3.fromRGB(228, 228, 234),
        Muted     = Color3.fromRGB(122, 122, 134),
        Header    = Color3.fromRGB(136, 136, 148),
        Accent    = Color3.fromRGB(102, 170, 255),
        AccentDk  = Color3.fromRGB(44, 74, 140),
        ToggleOn  = Color3.fromRGB(58, 98, 184),
        ToggleOff = Color3.fromRGB(40, 40, 49),
        TabOn     = Color3.fromRGB(34, 40, 56),
        TabOnStr  = Color3.fromRGB(66, 82, 120),
        BtnDark   = Color3.fromRGB(14, 22, 38),
    }

    local FAM = "rbxasset://fonts/families/GothamSSm.json"
    local function font(w) return Font.new(FAM, w or Enum.FontWeight.Medium) end

    local function new(class, props, kids)
        local o = Instance.new(class)
        local parent
        for k, v in pairs(props or {}) do
            if k == "Parent" then parent = v else o[k] = v end
        end
        for _, c in ipairs(kids or {}) do c.Parent = o end
        if parent then o.Parent = parent end
        return o
    end
    local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
    local function stroke(col, th) return new("UIStroke", { Color = col or C.Stroke, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) end
    local function pad(l, t, r, b) return new("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b) }) end
    local function text(parent, props)
        props.BackgroundTransparency = 1
        props.FontFace = props.FontFace or font()
        props.TextColor3 = props.TextColor3 or C.Text
        props.TextSize = props.TextSize or 14
        props.Parent = parent
        return new("TextLabel", props)
    end
    local function tween(o, t, props)
        TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end

    local function getGuiParent()
        local ok, h = pcall(function() return gethui and gethui() end)
        if ok and h then return h end
        local ok2 = pcall(function() return CoreGui.Name end)
        if ok2 then return CoreGui end
        return LP:WaitForChild("PlayerGui")
    end

    -- value (de)serialisation for configs
    local function ser(v)
        if typeof(v) == "EnumItem" then return { __key = v.Name } end
        return v
    end
    local function deser(v)
        if type(v) == "table" and v.__key then
            return Enum.KeyCode[v.__key]
        end
        return v
    end

    -- ----- baked-in logo (embedded PNG, loaded through the executor's file functions) -----
    local LOGO_B64 = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAALS0lEQVR42u2df6xcRRXHP3d3X1ueFFqoFmuRikCVij8wFiGKQTGNiRaiFMXUVgUrSquk1qIGEYzSxhYxkjSB1gA1pYqgNWJQDNQfYFWwYngQY620otjGgrYCQvt2xz/mTHb2dn/fubv37p5vsml3393Zufd8z5lzzpyZiYwxKIYXBX0ESgCFEkChBFAoARRKAIUSQKEEUCgBFEoAhRJAoQRQKAEUSgCFEkChBFAoARRKAIUSQNEjRGn/QEmfcaaFH4mSGnnVg1ELMLiW+RTgNBFypBZgsM28iRFgHDgfOAJ4WGQ1HvzHtSy8r4IvekL1iVAAKsDPgcnAGz2rYEIOAUqA/pn4EnAQmCBCftojQgU4Ejgg76cC//H8gU5g1AfIntZXRPjnAA8AL/U0vyDXvd2zCu/0HEINA3MseAOUgROBO4D7RPvHPLPvtPxi7/tL5LNSCLOvBOiPR18GjgJWATuB98nnX6szLJwKzPfaOBd4HfA8MBJSbuoDpKv1BRE8wAeB64GXxK47HvinaHVFhoOtwOzYdX8SIvzDi+AqbVgD9QH6IPiSZ+7PBh4CNtUR/g+Av8t1o8BSYEcd4QO8SkjwKWCaRA/tEEAtQA9R9DR+FrAGuKDJ9R8QAlwkFmJqm7/zb+BW4EdCrme93406sQBKgLDjfEUSN1cAX2rxnf0yrn8ZWNTl734f+Ayw2xN2RwTQISC5uR8RwVdEkI+3IXyA74ngFgMzgMvEGrTCv0ToM8WR3EXtXIGJvVp4CMboq/NXZIwpeu/PMsbcbzrDGdLOBK+dUWPMlU2+c41c4/pQkH+7vhcVZueCH/Hen2SM2Ww6x1hMiEVjzCRjTEk+X1bnOyvlbwW5LrHwjTHqA3Ro7l2adjKwEriyy7aWS0joQjl/SHZj+A7gBPn/XuDlntef2PtXH6Bz4bsHfyHwlwTCd85b3EGriCdvgEPAOu9vGyRBFHmEiQgwRawEaF/zjwfuBb5bJ57vBHeK81eKOW54uQPnJDrc7mUTg0LrAdpTkjJwNXaCJilujWl9vcxdJNHELgkrxzxljepca5QA6Wl/GTgWWBigvX3YCaCRFtrsEkr3YqeLK218RwmQovZfIIJIio2StZsk43zD6FxeP5Rr8Ry/oKVhGgW05/z9Hjg9QHtvwJZ3FRqY/zhGgYmS+o0aDAEts31KgO7gzPBc4LcB2vsDtrQralP4cSKSBgE0CmhuhgE+Eai9DV2a8FRlpBaguek/FtgTyFeaJeFfFKBvagF6YP4BFgQS/l1e7J85L1dxOFxt3iWB2luXWVOX8yGgW3Nq2nD+3gxsC9DHvdip23KKz2EoE0GJMmBtEGBxoPY2Y8u3Sg1IYBKQ3gyjBfBX0BS7DKnc0qtGw+Ix2OLLEMmf0yUEbNTXvgogjxaghM2iXSsh2jMd3IcrvlyDLc+OJ2Sc9r8nkPD/KMIvdEFUJUAD7T0kY+rn5bMpXbRzXxPnD+Cjgfr7Lc+qlLP4QPMWBbj+fjpBG/dgM3txrXQrcl4NvCVQf2+LEUsJkFD7K8B0YEWCdtY2iB7cZ0sC9fc7wFPUzvsrARIIf6I8yI8laOdRz/xX6pj/UeDDgfp8M9VikkavJKHs0BFgHLtk+ooE7ayWsbhQxxcy2KVXUwL090ns8q4oq2N/3pxAR4BFQoJusA/YQnWVbqGO+Q+V+fu2WJQJ0u9GNfoul9HMCqQ6fOQlDxBhCyP+LBFAN1gCrG/y9+nYiZ8QOA6bAYwrm/NjTAcCHnoCuNh8oWhWt9gG/Jfa0ut4aDknUJ83CZl2it8xRnUHkFIHQ4NJmwR5IIAzk9uxFTV5xPPAL7EFoVuA5zy/wygBWmv/POAnDAb2iCO7UUjgJ4kMtXX/Qz8EuOTM/cBZDBa2YJeEv0DtZpBBdwHLMwFcpu4cGqdu846fYucdKjGBx+v9TZoPOev4AoOLecAyGQKKfXGwMmoBnPa/HjubNsjYj90f4AV5X+nlEJB1C/BFBh9HY6uPyrTeGHooCOC0/zXAexkOnOJ5/kFW/eaZANEQab/DaC/MfR4I4GLi2dh1+MOCp2MK0LPZwlJGtT+p5/8O7J56EwlXjOHCspkSv38y4H3v6pcFyFIU4BygWcBfE7Rzl8TWaeM67FYvSTGOnTx6iupMZTwCMMNgAdxMWVLt/yrV3TrLKT2zcsDw9IEGwu8JShnT/pkkm5PfBvyG2rLv0A/VbeMyN1B7m2L+z1A6gU77Lw+g/Wnel+vnNODSQG3eIf9W+qV5WRH+DOwOmN3iMeyMYTFFTXJauhC7ZUtSrMdu/tC3wtEsEMCZ/8sStrNKhJNm2FTBViYtD9TeN/rl/WclCnDVOZOxe+B265PsBV6BLbyoN2aHgFva9S7gx4Gcv7fSfO+/gZ8NdKVRSxM6pGuB/5HujJrL0V8eqL1VpHgeYB4sgLvxFwFPkKwcexrVjZTSiKPdMHUqtr4vCcrAh7CrhgscXgE0NBbACWtRQuGvjcXRacymRYG0/x5somtzk7g/rXvIlAVwS7RHsCnbExK0dSI2lTpCtQY/pA/ghD9N/JRu8XHgJvm/2/SxnoYHXf+fVQvgTN/8hMJfj91S1c/6hdYeJ5CPdPn9u4FXivBHqC5yaeVrDLwFMNis3RkJ2jlNxuRik/HSJOyn6+tu7IbRnTiNS7Dbw+HlJ0YlWol6LeysWADnUJ2ZUPg/o/bAxTTgQr8FHQp/q2j9Bs+CzAG+KSFv373/fhHAP/70cwnbWk1t7XwlsCY5jZ0O3NLB95ZhdxV/XN5PBW7A7hYyS3IWmVkyXuoDAcrYM/DmJ2jnQeAX3tgfqnjCL8YYlxD1buyW7a3wK+yWNY96n10iUcrR8v56soYen7njzsS5wSTD+d6ZO2n1da4xZkeb/VkZ++48Y8z22DWPyNlA/mFPUcr30PJV6vFwM449GnVpgnaexE77TqH2EIV2TappYvKPwm7ovLBNC/UQdsOKh+X9bOw5gPXK2TaItUqrTiHzQ4A7GDnpGvwZ2LN2CWT2u8VVwFeEUFOxh0g18msOYreMwYv/e7L2LysEcGPqMVR39woRm/cDj2C3kdku7xfL2N7s2Nd14vy5qCLKigUo9PB3KtiTLo8gv1gNvFaEf7aY/ltofebv1zl8pi8TewT1ygJUhP2fzangdwLvx54cMhNbEHphB6R5guoxMVGWbqwXFsBl6c4FTs6h8K8FThLhXyXCbFf4+7DTviVqaxT9nMXA+wDuBlfkTPC7gfMkgbNAsnjHddjGIuAA1QOm+y7wXlsAl/adIxYgL1gjWbsidr7i9i6Ef7UkkUqe52/o8dq/flsAV+60PCeC3wO8G3uM+23ARV22cx1wDbXbxGUShZTbLgMvI9zmy2liHTaR8zYhQhLhrxDrMU79beH6PgvYCwuQdB69V9gHXIxdR7iDZOcCXwrcKB7/QTrbD7AvSKsewI1zJeBv2Bm1LOJO7FrCJdjp6W6xFZvefozm1T6ZQ1oWwJn/8zIs/I3YeYmbE7TxoISJW7znOZ6nUCdNC2CA3wFvyuB978QWbHSD/WI5NmKnpH1fql6a1wwbAVza90zg1+QbRsgyJuHgNiG1W4DiTvYer+P7DC0B/I0UTsbufhXFtMP96y/kSHtZF95vutCsUKdfFUnePCcO4oEm0VOlifM7tAQYRBSp3enbtBH9KAFa5BnqFXH0MkNm6vQhisXqmRdglvMAjUykIkPQs4OVAAolgEIJoFACKJQACiWAQgmgUAIolAAKJYBCCaBQAiiUAAolgEIJoFACKJQACiWAYmAJEOkjGWjE5Vss1fljrsqaFR3ByXIS8GJgcgm7W/ezwDNUjzBXDB4mYfcpPhK7A2oBOPR/M+6dnPVCQwcAAAAASUVORK5CYII="
    local function b64decode(data)
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local lookup = {}
        for i = 1, #chars do lookup[chars:sub(i, i)] = i - 1 end
        data = (data:gsub("[^%w%+/=]", ""))
        local out = {}
        for i = 1, #data, 4 do
            local a, b = lookup[data:sub(i, i)], lookup[data:sub(i + 1, i + 1)]
            local c, d = lookup[data:sub(i + 2, i + 2)], lookup[data:sub(i + 3, i + 3)]
            local n = a * 262144 + b * 4096 + (c or 0) * 64 + (d or 0)
            out[#out + 1] = string.char(math.floor(n / 65536) % 256)
            if c then out[#out + 1] = string.char(math.floor(n / 256) % 256) end
            if d then out[#out + 1] = string.char(n % 256) end
        end
        return table.concat(out)
    end
    local logoAsset
    local function getLogo()
        if logoAsset ~= nil then return logoAsset or nil end
        local ok, res = pcall(function()
            local gca = getcustomasset or getsynasset
            if not (writefile and gca) then return nil end
            if makefolder and isfolder and not isfolder("Byte.WTF") then makefolder("Byte.WTF") end
            writefile("Byte.WTF/logo.png", b64decode(LOGO_B64))
            return gca("Byte.WTF/logo.png")
        end)
        logoAsset = (ok and res) or false
        return logoAsset or nil
    end

    function Lib:CreateWindow(opts)
        opts = opts or {}
        local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
        local Window = { Flags = {} }
        local flags = Window.Flags

        local gui = new("ScreenGui", {
            Name = "ByteWTF_" .. tostring(math.random(1000, 9999)),
            ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
        })
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
        gui.Parent = getGuiParent()
        Window.Gui = gui

        local W, H = 780, 520
        local scaleVal = 1
        local function calcScale()
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            scaleVal = math.clamp(math.min(vp.X / (W + 40), vp.Y / (H + 40)), 0.45, 1)
            return scaleVal
        end

        local root = new("Frame", {
            Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(W, H), BackgroundColor3 = C.Window, BorderSizePixel = 0, Parent = gui,
        }, { corner(12), stroke(C.Stroke, 1) })
        local uiScale = new("UIScale", { Scale = calcScale(), Parent = root })
        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() uiScale.Scale = calcScale() end)
        end

        -- title bar
        local titleBar = new("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = C.TitleBar, BorderSizePixel = 0, Parent = root },
            { new("UICorner", { CornerRadius = UDim.new(0, 12) }) })
        new("Frame", { Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = C.TitleBar, BorderSizePixel = 0, Parent = titleBar })
        new("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke, BorderSizePixel = 0, Parent = titleBar })
        local logo = getLogo()
        if logo then
            new("ImageLabel", { Position = UDim2.fromOffset(24, 11), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, Image = logo, ScaleType = Enum.ScaleType.Fit, Parent = titleBar })
        end
        text(titleBar, { Text = opts.Name or "Byte.WTF", TextSize = 16, FontFace = font(Enum.FontWeight.Bold), TextColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(logo and 66 or 28, 0), Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })

        -- dragging
        do
            local dragging, dragStart, startPos
            titleBar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging, dragStart, startPos = true, i.Position, root.Position
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local d = (i.Position - dragStart) / uiScale.Scale
                    root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
        end

        -- tab bar + content area
        local tabBar = new("ScrollingFrame", {
            Position = UDim2.fromOffset(28, 70), Size = UDim2.new(1, -56, 0, 34), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.X, Parent = root,
        }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }) })

        local content = new("Frame", {
            Position = UDim2.fromOffset(28, 122), Size = UDim2.new(1, -56, 1, -142), BackgroundTransparency = 1, Parent = root,
        })

        -- overlay for dropdown popups
        local overlay = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Visible = false, ZIndex = 50, AutoButtonColor = false, Parent = gui })
        local openPopup
        local function closePopup()
            if openPopup then openPopup:Destroy(); openPopup = nil end
            overlay.Visible = false
        end
        overlay.MouseButton1Click:Connect(closePopup)

        -- toggle keybind + mobile button
        local toggleKey = opts.ToggleUIKeybind
        if type(toggleKey) == "string" then toggleKey = Enum.KeyCode[toggleKey] end
        local uiReady = true
        local function toggleUI() if not uiReady then return end closePopup(); root.Visible = not root.Visible end
        UIS.InputBegan:Connect(function(i, gp)
            if gp then return end
            if toggleKey and i.KeyCode == toggleKey then toggleUI() end
        end)
        if isMobile then
            local b = new("TextButton", {
                Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0, 14, 0.5, -20), BackgroundColor3 = C.Panel, Text = "UI",
                TextColor3 = C.Accent, TextSize = 14, FontFace = font(Enum.FontWeight.Bold), AutoButtonColor = false, Parent = gui,
            }, { corner(20), stroke(C.StrokeLt) })
            if logo then
                b.Text = ""
                new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, Image = logo, Parent = b })
            end
            b.MouseButton1Click:Connect(toggleUI)
        end

        -- loading screen
        if opts.LoadingEnabled ~= false then
            uiReady = false
            root.Visible = false
            local yOff = logo and 0 or -34
            local loader = new("CanvasGroup", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(380, 232 + yOff),
                BackgroundColor3 = C.Window, BorderSizePixel = 0, GroupTransparency = 1, Parent = gui,
            }, { corner(14), stroke(C.Stroke), new("UIScale", { Scale = uiScale.Scale }) })
            if logo then
                new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 28), Size = UDim2.fromOffset(64, 64), BackgroundTransparency = 1, Image = logo, ScaleType = Enum.ScaleType.Fit, Parent = loader })
            end
            text(loader, { Text = opts.Name or "Byte.WTF", TextSize = 22, FontFace = font(Enum.FontWeight.Bold), TextColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(0, 102 + yOff), Size = UDim2.new(1, 0, 0, 28) })
            text(loader, { Text = opts.LoadingSubtitle or "Loading", TextSize = 13, TextColor3 = C.Muted, Position = UDim2.fromOffset(0, 132 + yOff), Size = UDim2.new(1, 0, 0, 20) })
            local barTrack = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 174 + yOff), Size = UDim2.fromOffset(280, 6), BackgroundColor3 = Color3.fromRGB(34, 34, 43), BorderSizePixel = 0, Parent = loader }, { corner(3) })
            local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = barTrack }, {
                corner(3), new("UIGradient", { Color = ColorSequence.new(C.AccentDk, C.Accent) }),
            })
            local statusLbl = text(loader, { Text = "Initializing", TextSize = 12, TextColor3 = C.Muted, Position = UDim2.fromOffset(0, 190 + yOff), Size = UDim2.new(1, 0, 0, 20) })

            task.spawn(function()
                tween(loader, 0.3, { GroupTransparency = 0 })
                local steps = {
                    { "Initializing", 0.18 }, { "Loading modules", 0.46 }, { "Building interface", 0.76 },
                    { "Applying theme", 0.93 }, { "Ready", 1 },
                }
                for _, st in ipairs(steps) do
                    statusLbl.Text = st[1]
                    tween(barFill, 0.4, { Size = UDim2.fromScale(st[2], 1) })
                    task.wait(0.45)
                end
                task.wait(0.2)
                tween(loader, 0.3, { GroupTransparency = 1 })
                task.wait(0.32)
                loader:Destroy()
                uiScale.Scale = calcScale() * 0.94
                root.Visible = true
                uiReady = true
                tween(uiScale, 0.22, { Scale = calcScale() })
            end)
        end

        -- notifications
        local toasts = new("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(260, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = gui,
        }, { new("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }) })
        function Window:Notify(p)
            p = p or {}
            local t = new("CanvasGroup", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Panel, BorderSizePixel = 0,
                GroupTransparency = 1, Parent = toasts,
            }, { corner(8), stroke(C.StrokeLt), pad(12, 10, 12, 10), new("UIListLayout", { Padding = UDim.new(0, 2) }) })
            text(t, { Text = tostring(p.title or p.Title or "Notice"), FontFace = font(Enum.FontWeight.Bold), TextSize = 13, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 })
            text(t, { Text = tostring(p.content or p.Content or ""), TextSize = 12, TextColor3 = C.Muted, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2 })
            tween(t, 0.2, { GroupTransparency = 0 })
            task.delay(tonumber(p.duration or p.Duration) or 3, function()
                if t.Parent then tween(t, 0.25, { GroupTransparency = 1 }); task.wait(0.3); t:Destroy() end
            end)
        end

        -- configs
        local cfgCfg = opts.ConfigurationSaving or {}
        local folder = cfgCfg.FolderName or "Byte.WTF"
        function Window:SaveConfig(name)
            name = (name and name ~= "") and name or "default"
            local data = {}
            for flag, obj in pairs(flags) do data[flag] = ser(obj.Get()) end
            if makefolder and not (isfolder and isfolder(folder)) then pcall(makefolder, folder) end
            writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        end
        function Window:LoadConfig(name)
            name = (name and name ~= "") and name or "default"
            local raw = readfile(folder .. "/" .. name .. ".json")
            local data = HttpService:JSONDecode(raw)
            for flag, v in pairs(data) do
                local obj = flags[flag]
                if obj then pcall(obj.Set, deser(v)) end
            end
        end
        function Window:Destroy() gui:Destroy() end

        -- tabs
        local tabs, activeTab = {}, nil
        local index = {} -- search registry: every control gets an entry
        local function selectTab(t)
            closePopup()
            activeTab = t
            for _, o in ipairs(tabs) do
                local on = (o == t)
                o.Page.Visible = on
                tween(o.Btn, 0.12, { BackgroundColor3 = on and C.TabOn or C.Panel, TextColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 210) })
                o.BtnStroke.Color = on and C.TabOnStr or C.Stroke
            end
        end

        function Window:CreateTab(p)
            p = p or {}
            local Tab = { Panels = {}, Order = 0 }
            local btn = new("TextButton", {
                Text = p.Name or "Tab", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 34),
                BackgroundColor3 = C.Panel, TextColor3 = Color3.fromRGB(200, 200, 210), TextSize = 14, FontFace = font(Enum.FontWeight.Medium),
                AutoButtonColor = false, LayoutOrder = #tabs + 1, Parent = tabBar,
            }, { corner(8), pad(20, 0, 20, 0) })
            local bs = stroke(C.Stroke); bs.Parent = btn
            Tab.Btn, Tab.BtnStroke = btn, bs

            local page = new("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
                ScrollBarImageColor3 = C.StrokeLt, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
                ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, Parent = content,
            }, { pad(0, 0, 4, 4) })
            Tab.Page = page
            local function column(x, w)
                return new("Frame", {
                    Position = x, Size = w, AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = page,
                }, { new("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }) })
            end
            local colL = column(UDim2.fromOffset(0, 0), UDim2.new(0.5, -8, 0, 0))
            local colR = column(UDim2.new(0.5, 8, 0, 0), UDim2.new(0.5, -8, 0, 0))

            local pending = false
            local function relayout()
                if pending then return end
                pending = true
                task.defer(function()
                    pending = false
                    local hL, hR = 0, 0
                    for i, pn in ipairs(Tab.Panels) do
                        local toRight
                        if pn.Pin == "Right" then toRight = true
                        elseif pn.Pin == "Left" then toRight = false
                        else toRight = hR < hL end
                        local h = 60 + pn.Est
                        pn.Frame.LayoutOrder = i
                        pn.Frame.Parent = toRight and colR or colL
                        if toRight then hR = hR + h + 16 else hL = hL + h + 16 end
                    end
                end)
            end

            local function newPanel(name, pin)
                local f = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Panel, BorderSizePixel = 0,
                }, { corner(10), stroke(C.Stroke), pad(20, 20, 20, 20), new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }) })
                text(f, { Text = string.upper(name), TextSize = 12, FontFace = font(Enum.FontWeight.Bold), TextColor3 = C.Header, Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 })
                local pn = { Frame = f, Est = 0, Pin = pin, Order = 0, Name = name }
                table.insert(Tab.Panels, pn)
                relayout()
                return pn
            end

            local function addItem(pn, h)
                pn.Order = pn.Order + 1
                pn.Est = pn.Est + h + 14
                relayout()
                return pn.Order
            end

            local function reg(flag, getter, setter)
                if flag then flags[flag] = { Get = getter, Set = setter } end
            end

            -- builders; each takes the panel they belong to
            local B = {}

            function B.Toggle(pn, o)
                local hasDesc = o.Desc and o.Desc ~= ""
                local h = hasDesc and 54 or 34
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Toggle", Position = UDim2.fromOffset(0, hasDesc and 2 or 0), Size = UDim2.new(1, -60, 0, hasDesc and 22 or h), TextXAlignment = Enum.TextXAlignment.Left })
                if hasDesc then
                    text(row, { Text = o.Desc, TextSize = 12, TextColor3 = C.Muted, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, -60, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
                end
                local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(42, 24), BackgroundColor3 = C.ToggleOff, BorderSizePixel = 0, Parent = row }, { corner(12) })
                local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.fromRGB(150, 150, 162), BorderSizePixel = 0, Parent = track }, { corner(8) })
                local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row })
                local state = o.CurrentValue == true
                local obj = {}
                local function render(animate)
                    local tp = { BackgroundColor3 = state and C.ToggleOn or C.ToggleOff }
                    local kp = { Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 4, 0.5, 0), BackgroundColor3 = state and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 162) }
                    if animate then tween(track, 0.15, tp); tween(knob, 0.15, kp)
                    else for k, v in pairs(tp) do track[k] = v end for k, v in pairs(kp) do knob[k] = v end end
                end
                render(false)
                function obj:Set(v)
                    v = v == true
                    if v == state then return end
                    state = v; render(true)
                    if o.Callback then task.spawn(o.Callback, state) end
                end
                function obj:Get() return state end
                hit.MouseButton1Click:Connect(function() obj:Set(not state) end)
                reg(o.Flag, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            function B.Slider(pn, o)
                local h = 54
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Slider", Size = UDim2.new(0.65, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left })
                local valLbl = text(row, { Text = "", TextSize = 13, TextColor3 = C.Muted, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.35, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Right })
                local min, max = (o.Range and o.Range[1]) or 0, (o.Range and o.Range[2]) or 100
                local inc = o.Increment or 1
                local dec = #((tostring(inc):match("%.(%d+)")) or "")
                local suffix = (o.Suffix and o.Suffix ~= "") and (" " .. o.Suffix) or ""
                local track = new("Frame", { Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = Color3.fromRGB(38, 38, 48), BorderSizePixel = 0, Parent = row }, { corner(2) })
                local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track }, {
                    corner(2),
                    new("UIGradient", { Color = ColorSequence.new(C.AccentDk, C.Accent) }),
                })
                local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = track }, { corner(7), stroke(C.Accent, 2) })
                local hit = new("TextButton", { Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", Parent = row })

                local value = math.clamp(o.CurrentValue or min, min, max)
                local obj = {}
                local function snap(v)
                    v = math.clamp(math.floor((v - min) / inc + 0.5) * inc + min, min, max)
                    return tonumber(string.format("%." .. dec .. "f", v))
                end
                local function render()
                    local a = (max == min) and 0 or (value - min) / (max - min)
                    fill.Size = UDim2.fromScale(a, 1)
                    knob.Position = UDim2.new(a, 0, 0.5, 0)
                    valLbl.Text = string.format("%." .. dec .. "f", value) .. suffix
                end
                render()
                function obj:Set(v, silent)
                    v = snap(tonumber(v) or min)
                    if v == value then return end
                    value = v; render()
                    if o.Callback and not silent then task.spawn(o.Callback, value) end
                end
                function obj:Get() return value end

                local dragging = false
                local function fromInput(i)
                    local a = math.clamp((i.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                    obj:Set(min + (max - min) * a)
                end
                hit.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; page.ScrollingEnabled = false; fromInput(i)
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromInput(i) end
                end)
                UIS.InputEnded:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                        dragging = false; page.ScrollingEnabled = true
                    end
                end)
                reg(o.Flag, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            function B.Dropdown(pn, o)
                local h = 36
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Dropdown", Size = UDim2.new(1, -176, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
                local box = new("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(164, 32),
                    BackgroundColor3 = C.Field, Text = "", AutoButtonColor = false, Parent = row,
                }, { corner(7), stroke(C.Stroke) })
                local valLbl = text(box, { Text = "", TextSize = 13, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -36, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
                do -- chevron drawn from two thin bars (no font glyphs)
                    local chev = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(10, 6), BackgroundTransparency = 1, Parent = box })
                    for _, d in ipairs({ { 3, 40 }, { 7, -40 } }) do
                        new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(d[1], 3), Size = UDim2.fromOffset(7, 2), Rotation = d[2], BackgroundColor3 = C.Muted, BorderSizePixel = 0, Parent = chev }, { corner(1) })
                    end
                end

                local options = o.Options or {}
                local current = o.CurrentValue
                if type(current) == "table" then current = current[1] end
                local obj = {}
                local function render()
                    if current ~= nil and current ~= "" then
                        valLbl.Text = tostring(current); valLbl.TextColor3 = C.Text
                    else
                        valLbl.Text = o.Placeholder or "Select"; valLbl.TextColor3 = C.Muted
                    end
                end
                render()
                function obj:Set(v, silent)
                    current = v; render()
                    if o.Callback and not silent then task.spawn(o.Callback, v) end
                end
                function obj:Get() return current end
                function obj:Refresh(list) options = list or {} end

                box.MouseButton1Click:Connect(function()
                    if openPopup then closePopup() return end
                    if o.Dynamic then
                        local ok, list = pcall(o.Dynamic)
                        if ok and type(list) == "table" then options = list end
                    end
                    local s = uiScale.Scale
                    local shown = math.min(#options, 6)
                    local ph = math.max(shown, 1) * 32 + 10
                    local pop = new("Frame", {
                        Position = UDim2.fromOffset(box.AbsolutePosition.X, box.AbsolutePosition.Y + box.AbsoluteSize.Y + 4),
                        Size = UDim2.fromOffset(box.AbsoluteSize.X / s, ph), BackgroundColor3 = C.Field, BorderSizePixel = 0, ZIndex = 51, Parent = overlay,
                    }, { corner(7), stroke(C.StrokeLt), new("UIScale", { Scale = s }) })
                    local list = new("ScrollingFrame", {
                        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
                        ScrollBarImageColor3 = C.StrokeLt, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 52, Parent = pop,
                    }, { pad(5, 5, 5, 5), new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }) })
                    if #options == 0 then
                        text(list, { Text = "No options", TextSize = 12, TextColor3 = C.Muted, Size = UDim2.new(1, 0, 0, 32), ZIndex = 53 })
                    end
                    for i, name in ipairs(options) do
                        local b = new("TextButton", {
                            Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.TabOn, BackgroundTransparency = 1, Text = tostring(name),
                            TextColor3 = (name == current) and C.Accent or C.Text, TextSize = 13, FontFace = font(), AutoButtonColor = false,
                            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i, ZIndex = 53, Parent = list,
                        }, { corner(6), pad(10, 0, 10, 0) })
                        b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
                        b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
                        b.MouseButton1Click:Connect(function() closePopup(); obj:Set(name) end)
                    end
                    openPopup = pop
                    overlay.Visible = true
                end)
                reg(o.Flag, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            function B.Keybind(pn, o)
                local h = 36
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Keybind", Size = UDim2.new(1, -130, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
                local box = new("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(112, 30),
                    BackgroundColor3 = C.Field, TextColor3 = C.Text, TextSize = 13, FontFace = font(), AutoButtonColor = false, Text = "", Parent = row,
                }, { corner(6), stroke(C.Stroke) })
                local key = o.CurrentValue
                if type(key) == "string" then key = Enum.KeyCode[key] end
                local function render() box.Text = key and key.Name or "None" end
                render()
                local obj = {}
                function obj:Set(k, silent)
                    if type(k) == "string" then k = Enum.KeyCode[k] end
                    key = k; render()
                    if o.Callback and not silent and k then task.spawn(o.Callback, k) end
                end
                function obj:Get() return key end
                local listening = false
                box.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true; box.Text = "..."; box.TextColor3 = C.Accent
                    local conn
                    conn = UIS.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.Keyboard then
                            conn:Disconnect(); listening = false; box.TextColor3 = C.Text
                            if i.KeyCode ~= Enum.KeyCode.Escape then obj:Set(i.KeyCode) else render() end
                        end
                    end)
                end)
                reg(o.Flag, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            function B.Input(pn, o)
                local h = 72
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Input", Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left })
                local tb = new("TextBox", {
                    Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.Field, Text = tostring(o.CurrentValue or ""),
                    PlaceholderText = o.Placeholder or "", PlaceholderColor3 = Color3.fromRGB(100, 100, 112), TextColor3 = C.Text,
                    TextSize = 13, FontFace = font(), ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                }, { corner(7), stroke(C.Stroke), pad(12, 0, 12, 0) })
                local obj = {}
                function obj:Set(v) tb.Text = tostring(v or "") end
                function obj:Get() return tb.Text end
                tb.Focused:Connect(function() tb.UIStroke.Color = C.Accent end)
                tb.FocusLost:Connect(function()
                    tb.UIStroke.Color = C.Stroke
                    if o.Callback then task.spawn(o.Callback, tb.Text) end
                    if o.RemoveTextAfterFocusLost then tb.Text = "" end
                end)
                reg(o.Flag, obj.Get, function(v) tb.Text = tostring(v or ""); if o.Callback then task.spawn(o.Callback, tb.Text) end end)
                return obj
            end

            local function makeButton(parent, b, size, pos)
                local primary = (b.Style ~= "Secondary")
                local btn = new("TextButton", {
                    Size = size, Position = pos or UDim2.new(), BackgroundColor3 = primary and C.Accent or C.Field, Text = b.Name or "Button",
                    TextColor3 = primary and C.BtnDark or C.Text, TextSize = 13, FontFace = font(Enum.FontWeight.Bold), AutoButtonColor = false, Parent = parent,
                }, { corner(7) })
                if not primary then stroke(C.Stroke).Parent = btn end
                local base = btn.BackgroundColor3
                btn.MouseEnter:Connect(function() tween(btn, 0.1, { BackgroundColor3 = primary and Color3.fromRGB(128, 186, 255) or Color3.fromRGB(32, 32, 40) }) end)
                btn.MouseLeave:Connect(function() tween(btn, 0.1, { BackgroundColor3 = base }) end)
                btn.MouseButton1Click:Connect(function() if b.Callback then task.spawn(b.Callback) end end)
                return btn
            end

            function B.Button(pn, o)
                local h = 40
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                makeButton(row, o, UDim2.fromScale(1, 1))
                return {}
            end

            -- { {Name=, Callback=, Style=}, {...} }  (first button wide, rest narrow, like the screenshot)
            function B.ButtonRow(pn, list)
                local h = 40
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
                local n = #list
                for i, b in ipairs(list) do
                    local w = (n == 1) and UDim2.fromScale(1, 1)
                        or (i == 1 and UDim2.new(0.62, -5, 1, 0) or UDim2.new(0.38 / (n - 1), -5, 1, 0))
                    local btn = makeButton(row, b, w)
                    btn.LayoutOrder = i
                end
                return {}
            end

            function B.Label(pn, o)
                local h = 22
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                local l = text(row, { Text = o.Name or o.Text or "", TextSize = 13, TextColor3 = C.Muted, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left })
                return { Set = function(_, t) l.Text = t end }
            end

            function B.Divider(pn)
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke, BorderSizePixel = 0, LayoutOrder = addItem(pn, 1), Parent = pn.Frame })
                return {}
            end

            local function install(target, getPanel)
                local function wrap(fn, kind)
                    return function(self, o)
                        local pn = getPanel()
                        local res = fn(pn, o)
                        if kind then
                            local row
                            for _, c in ipairs(pn.Frame:GetChildren()) do
                                if c:IsA("Frame") and c.LayoutOrder == pn.Order then row = c break end
                            end
                            if row then
                                local names = {}
                                if kind == "row" then
                                    for _, b in ipairs(o) do table.insert(names, b.Name or "Button") end
                                else
                                    table.insert(names, o.Name or "Item")
                                end
                                for _, nm in ipairs(names) do
                                    table.insert(index, {
                                        Name = nm, Desc = (kind == "item") and o.Desc or nil, Tab = Tab,
                                        TabName = p.Name or "Tab", Section = pn.Name, Row = row,
                                    })
                                end
                            end
                        end
                        return res
                    end
                end
                target.CreateToggle    = wrap(B.Toggle, "item")
                target.CreateSlider    = wrap(B.Slider, "item")
                target.CreateDropdown  = wrap(B.Dropdown, "item")
                target.CreateKeybind   = wrap(B.Keybind, "item")
                target.CreateInput     = wrap(B.Input, "item")
                target.CreateButton    = wrap(B.Button, "item")
                target.CreateButtonRow = wrap(B.ButtonRow, "row")
                target.CreateLabel     = wrap(B.Label)
                target.CreateParagraph = wrap(B.Label)
                target.CreateDivider   = wrap(B.Divider)
            end

            local current
            install(Tab, function()
                if not current then current = newPanel(p.Name or "Options") end
                return current
            end)

            function Tab:CreateSection(s)
                local name, pin = s, nil
                if type(s) == "table" then name, pin = s.Name or s.Title or "Section", s.Column end
                current = newPanel(tostring(name), pin)
                local Section = {}
                local mine = current
                install(Section, function() return mine end)
                return Section
            end

            btn.MouseButton1Click:Connect(function() selectTab(Tab) end)
            table.insert(tabs, Tab)
            if #tabs == 1 then selectTab(Tab) end
            return Tab
        end

        -- ===== search bar (top right of the title bar) =====
        do
            local bar = new("Frame", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0, 27), Size = UDim2.fromOffset(330, 34),
                BackgroundTransparency = 1, ZIndex = 5, Parent = root,
            })
            local box = new("TextBox", {
                Size = UDim2.new(1, -84, 1, 0), BackgroundColor3 = C.Field, Text = "", PlaceholderText = "Search features...", ZIndex = 6,
                PlaceholderColor3 = Color3.fromRGB(100, 100, 112), TextColor3 = C.Text, TextSize = 13, FontFace = font(),
                ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = bar,
            }, { corner(8), stroke(C.Stroke), pad(14, 0, 14, 0) })
            local goBtn = new("TextButton", {
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(76, 34), BackgroundColor3 = C.Accent, ZIndex = 6,
                Text = "Search", TextColor3 = C.BtnDark, TextSize = 13, FontFace = font(Enum.FontWeight.Bold), AutoButtonColor = false, Parent = bar,
            }, { corner(8) })

            local results = new("Frame", {
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 62), Size = UDim2.fromOffset(420, 0),
                BackgroundColor3 = C.Field, BorderSizePixel = 0, Visible = false, ZIndex = 40, ClipsDescendants = true, Parent = root,
            }, { corner(9), stroke(C.StrokeLt) })
            local list = new("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.StrokeLt,
                AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 41, Parent = results,
            }, { pad(6, 6, 6, 6), new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

            local current = {}
            local function jump(e)
                if not e then return end
                results.Visible = false
                box:ReleaseFocus()
                closePopup()
                selectTab(e.Tab)
                task.spawn(function()
                    task.wait(0.08)
                    local page = e.Tab.Page
                    local y = e.Row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 12
                    page.CanvasPosition = Vector2.new(0, math.max(0, y))
                    local hl = new("Frame", {
                        Size = UDim2.new(1, 16, 1, 10), Position = UDim2.fromOffset(-8, -5), BackgroundColor3 = C.Accent,
                        BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 5, Parent = e.Row,
                    }, { corner(8) })
                    task.wait(0.5)
                    tween(hl, 0.8, { BackgroundTransparency = 1 })
                    task.wait(0.9)
                    hl:Destroy()
                end)
            end

            local function refresh()
                for _, c in ipairs(list:GetChildren()) do
                    if c:IsA("GuiObject") then c:Destroy() end
                end
                local q = string.lower((box.Text:gsub("^%s+", ""):gsub("%s+$", "")))
                if q == "" then results.Visible = false; current = {} return end
                local scored = {}
                for _, e in ipairs(index) do
                    local n = string.lower(e.Name)
                    local sc
                    if n == q then sc = 1
                    elseif n:sub(1, #q) == q then sc = 2
                    elseif n:find(q, 1, true) then sc = 3
                    elseif string.lower(e.Section):find(q, 1, true) then sc = 4
                    elseif string.lower(e.TabName):find(q, 1, true) then sc = 5
                    elseif e.Desc and string.lower(e.Desc):find(q, 1, true) then sc = 6 end
                    if sc then table.insert(scored, { e = e, sc = sc }) end
                end
                table.sort(scored, function(a, b) if a.sc ~= b.sc then return a.sc < b.sc end return a.e.Name < b.e.Name end)
                current = {}
                local shown = math.min(#scored, 40)
                for i = 1, shown do
                    local e = scored[i].e
                    current[i] = e
                    local b = new("TextButton", {
                        Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.TabOn, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
                        LayoutOrder = i, ZIndex = 42, Parent = list,
                    }, { corner(6) })
                    text(b, { Text = e.Name, TextSize = 13, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.55, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 43 })
                    text(b, { Text = e.TabName .. " / " .. e.Section, TextSize = 12, TextColor3 = C.Muted, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.45, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 43 })
                    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
                    b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
                    b.MouseButton1Down:Connect(function() jump(e) end)
                end
                if shown == 0 then
                    text(list, { Text = "No matches", TextSize = 13, TextColor3 = C.Muted, Size = UDim2.new(1, 0, 0, 36), ZIndex = 42 })
                end
                results.Size = UDim2.fromOffset(420, math.min(math.max(shown, 1), 6) * 38 + 12)
                results.Visible = true
            end

            box:GetPropertyChangedSignal("Text"):Connect(refresh)
            box.Focused:Connect(function() box.UIStroke.Color = C.Accent; refresh() end)
            box.FocusLost:Connect(function(enter)
                box.UIStroke.Color = C.Stroke
                if enter and current[1] then jump(current[1]) return end
                task.delay(0.25, function() if not box:IsFocused() then results.Visible = false end end)
            end)
            goBtn.MouseButton1Click:Connect(function()
                if box.Text == "" then box:CaptureFocus() return end
                refresh()
                if current[1] then jump(current[1]) end
            end)
            goBtn.MouseEnter:Connect(function() tween(goBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(128, 186, 255) }) end)
            goBtn.MouseLeave:Connect(function() tween(goBtn, 0.1, { BackgroundColor3 = C.Accent }) end)
        end

        return Window
    end

    return Lib
end)()




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

    local Window = Airflow:CreateWindow({Name = "Byte.WTF", LoadingSubtitle = "Byte On Top", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "FatalLabs", FileName = "FatalLabs"}})

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

    local Window = Airflow:CreateWindow({Name = "Byte.WTF", LoadingSubtitle = "Byte On Top", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "FatalLabs", FileName = "FatalLabs"}})

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
    local DeviceEvent  = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("deviceEvent")

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
            BallMags = false, BallMagRange = 15, BallMagVisualizer = false, MagnetKeybind = "M",
            BallReach = false, BallReachRange = 10, BallReachVisualizer = false, ReachKeybind = "N",
        },
        MagV2 = { Enabled = false, BallName = "Ball", Reach = 20, Keybind = Enum.KeyCode.U },
        TPWalk = { Enabled = false, Speed = 0.01, Keybind = Enum.KeyCode.P },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1, Count = 2 },
        },
        Misc = { AntiModerator = false, DeviceSpoofer = false, Device = "PC", MobilePanel = true },
        Visuals = {
            ShotIndicator = false, IndicatorColor = "Purple",
            CustomName = false, CustomNameText = "",
            CustomRecord = false, CustomRecordText = "",
            CustomTitle = false, CustomTitleText = "",
            HideOwnNameplate = false,
        },
        Goal = { Enabled = false, SelectedEffect = "LightRay", CurrentEffect = "LightRay" },
        CourtSpoofer = { Enabled = false, SelectedCourt = "None", CurrentCourt = "None" },
        BallChanger = { Enabled = false, SelectedBall = "ForceField", CurrentBall = "ForceField" },
        TrailSpoofer = { Enabled = false, SelectedTrail = "None", CurrentTrail = "None" },
        BallAura = { Enabled = false, SelectedAura = "None", CurrentAura = "None" },
        BodyAura = { Enabled = false, Selected = "" },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {}, fns = {} }
    local function Track(c) table.insert(Cleanup.conns, c); return c end
    local function OnCleanup(fn) table.insert(Cleanup.fns, fn) end

    local setAural, setGuard, setMagnet, setReach, setTPWalk, setMagV2
    local MobileRefresh = function() end

    local IndicatorColors = {
        Blue = Color3.fromRGB(60, 150, 255),
        Purple = Color3.fromRGB(150, 80, 220),
        Green = Color3.fromRGB(0, 255, 128),
        Red = Color3.fromRGB(255, 60, 60),
        Yellow = Color3.fromRGB(255, 220, 0),
    }

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
        if character:FindFirstChild("ByteMagnet") then character.ByteMagnet:Destroy() end
        local head = character:FindFirstChild("Head")
        if not head then return end
        magnetHitbox = Instance.new("Part")
        magnetHitbox.Name = "ByteMagnet"
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
        local magnetBox = Instance.new("SelectionSphere")
        magnetBox.Name = "ByteMagnetBox"
        magnetBox.Adornee = magnetHitbox
        magnetBox.Color3 = Color3.fromRGB(242, 140, 62)
        magnetBox.Transparency = s.Ball.BallMagVisualizer and 0.2 or 1
        magnetBox.SurfaceTransparency = 1
        magnetBox.Parent = magnetHitbox
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
            if character and not character:FindFirstChild("ByteMagnet") then
                createMagnetHitbox(character)
            end
        end)
        Track(magnetConnection)
    end

    local function disableMagnet()
        if magnetConnection then magnetConnection:Disconnect(); magnetConnection = nil end
        if magnetHitbox then magnetHitbox:Destroy(); magnetHitbox = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("ByteMagnet") then
            LocalPlayer.Character.ByteMagnet:Destroy()
        end
    end

    local reachVisualizer, reachConnection = nil, nil

    local function removeReachVisualizer()
        if reachVisualizer then reachVisualizer:Destroy(); reachVisualizer = nil end
    end

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

    local function updateReachVisualizer()
        if not s.Ball.BallReachVisualizer then removeReachVisualizer(); return end
        local closest, closestDist = nil, math.huge
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot then
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer then continue end
                local c = p.Character
                local b = c and c:FindFirstChild("Basketball")
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if b and r then
                    local d = (myRoot.Position - r.Position).Magnitude
                    if d < closestDist then closestDist = d; closest = p end
                end
            end
        end
        local ballPart = nil
        if closest and closest.Character then
            local oppBall = closest.Character:FindFirstChild("Basketball")
            if oppBall then ballPart = oppBall:FindFirstChild("Ball") end
        end
        if not ballPart then removeReachVisualizer(); return end
        local range = s.Ball.BallReachRange or 10
        if not reachVisualizer or not reachVisualizer.Parent then
            reachVisualizer = Instance.new("Part")
            reachVisualizer.Name = "ReachBallVisualizer"
            reachVisualizer.Shape = Enum.PartType.Ball
            reachVisualizer.Size = Vector3.new(range, range, range)
            reachVisualizer.Transparency = 1
            reachVisualizer.CanCollide = false
            reachVisualizer.CanTouch = false
            reachVisualizer.CanQuery = false
            reachVisualizer.CastShadow = false
            reachVisualizer.Massless = true
            reachVisualizer.Anchored = true
            reachVisualizer.Color = Color3.fromRGB(242, 140, 62)
            reachVisualizer.Parent = workspace
            local sphereBox = Instance.new("SelectionSphere")
            sphereBox.Name = "ByteReachSphere"
            sphereBox.Adornee = reachVisualizer
            sphereBox.Transparency = 0.75
            sphereBox.SurfaceTransparency = 1
            sphereBox.Color3 = Color3.fromRGB(242, 140, 62)
            sphereBox.Parent = reachVisualizer
        end
        reachVisualizer.Size = Vector3.new(range, range, range)
        reachVisualizer.CFrame = ballPart.CFrame
    end

    local function enableReach()
        local char = LocalPlayer.Character
        if not char then return end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("ByteReach") then
            LocalPlayer.Character.ByteReach:Destroy()
        end
        if reachConnection then reachConnection:Disconnect(); reachConnection = nil end
        reachConnection = RunService.Heartbeat:Connect(function()
            if not s.Ball.BallReach and not s.Ball.BallReachVisualizer then return end
            if s.Ball.BallReach then performReachSteal() end
            if s.Ball.BallReachVisualizer then updateReachVisualizer() else removeReachVisualizer() end
        end)
        Track(reachConnection)
    end

    local function disableReach()
        if reachConnection then reachConnection:Disconnect(); reachConnection = nil end
        removeReachVisualizer()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("ByteReach") then
            LocalPlayer.Character.ByteReach:Destroy()
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

    local magV2Connection = nil

    local function magV2Tick()
        if not s.MagV2.Enabled then return end
        local character, _, touchPart = getChar()
        if not character or not touchPart then return end
        local ballName = s.MagV2.BallName
        local reach = tonumber(s.MagV2.Reach) or 20
        for _, object in pairs(workspace:GetDescendants()) do
            if object.Name == ballName and object:IsA("BasePart") then
                if object:FindFirstChildWhichIsA("TouchTransmitter") or object:FindFirstChild("TouchInterest") then
                    if (touchPart.Position - object.Position).Magnitude <= reach then
                        firetouchinterest(touchPart, object, 0)
                        task.wait()
                        firetouchinterest(touchPart, object, 1)
                    end
                end
            end
        end
    end

    local function enableMagV2()
        if magV2Connection then magV2Connection:Disconnect(); magV2Connection = nil end
        magV2Connection = RunService.Heartbeat:Connect(function() pcall(magV2Tick) end)
        Track(magV2Connection)
    end

    local function disableMagV2()
        if magV2Connection then magV2Connection:Disconnect(); magV2Connection = nil end
    end

    local Effects = {}
    local function loadEffects()
        pcall(function()
            local folder = ReplicatedStorage.ShopItems.Effect
            for _, eff in folder:GetChildren() do
                Effects[eff.Name:gsub("Effect_", "")] = eff
            end
        end)
    end
    loadEffects()

    local goalEventHook = nil

    local function applyGoalEffect()
        if not Effects[s.Goal.CurrentEffect] then return end
        pcall(function()
            local PlayerData = require(ReplicatedStorage.Util.PlayerData)
            PlayerData.storedData["Equipping"]["Effect"] = Effects[s.Goal.CurrentEffect].Name
            PlayerData.storedData["Inventory"][Effects[s.Goal.CurrentEffect].Name] = 1
        end)
        if goalEventHook then return end
        pcall(function()
            local connections = getconnections(ReplicatedStorage.Remotes.goalEvent.OnClientEvent)
            if connections and connections[1] then
                local old
                old = hookfunction(connections[1].Function, function(Player, Court, Goal, XYZ, GoalEffect, Unknown)
                    if Player == LocalPlayer and s.Goal.Enabled then
                        GoalEffect = Effects[s.Goal.CurrentEffect].Value
                    end
                    return old(Player, Court, Goal, XYZ, GoalEffect, Unknown)
                end)
                goalEventHook = old
            end
        end)
    end

    local function resetGoalEffect()
        pcall(function()
            local PlayerData = require(ReplicatedStorage.Util.PlayerData)
            PlayerData.storedData["Equipping"]["Effect"] = Effects["LightRay"].Name
            PlayerData.storedData["Inventory"][Effects["LightRay"].Name] = 1
        end)
    end

    local function SpoofDevice()
        if not s.Misc.DeviceSpoofer then return end
        local device = s.Misc.Device
        if device == "PC" then DeviceEvent:FireServer("Desktop")
        elseif device == "Mobile" then DeviceEvent:FireServer("Mobile")
        elseif device == "Gamepad" then DeviceEvent:FireServer("Gamepad") end
    end

    local Moderators = {
        "izzran", "wistfulmikk", "Bibliogical", "aepione", "kyraizo",
        "ar1sxm", "westline60s", "Iukejdjd", "Ninja215215"
    }
    local antiModTask = nil
    local Notify

    local function startAntiMod()
        if antiModTask then return end
        antiModTask = task.spawn(function()
            local detected = {}
            while s.Misc.AntiModerator do
                task.wait(1)
                for _, moderator in next, Players:GetPlayers() do
                    if table.find(Moderators, moderator.Name) and not detected[moderator.UserId] then
                        detected[moderator.UserId] = true
                        if Notify then
                            Notify({ title = "Moderator Detected", content = moderator.Name .. " is in the server.", duration = 5 })
                        end 
                    end
                end
            end
        end)
    end

    local function stopAntiMod()
        s.Misc.AntiModerator = false
        if antiModTask then task.cancel(antiModTask); antiModTask = nil end
    end

    local Balls, BallNames = {}, {}
    local Trails, TrailNames = {}, {}
    local Auras, AuraNames = {}, {}
    local Courts, CourtNames = {}, {}
    local OriginalReplicateBall, Replicator = nil, nil
    local OriginalReplicateTrail = nil
    local OriginalReplicateAura = nil
    local OriginalReplicateCourt = nil

    pcall(function()
        Replicator = require(ReplicatedStorage.Util.Replicator)
        OriginalReplicateBall = Replicator["ReplicateBall"]
        OriginalReplicateTrail = Replicator["ReplicateTrail"]
        OriginalReplicateAura = Replicator["ReplicateAura"]
        OriginalReplicateCourt = Replicator["ReplicateCourt"]

        for _, ballItem in ReplicatedStorage.ShopItems.Ball:GetChildren() do
            local name = ballItem.Name:gsub("Ball_", "")
            Balls[name] = ballItem.Name
            table.insert(BallNames, name)
        end
        table.sort(BallNames)

        local trailFolder = ReplicatedStorage.ShopItems:FindFirstChild("Trail")
        if trailFolder then
            for _, item in trailFolder:GetChildren() do
                local name = item.Name:gsub("Trail_", "")
                Trails[name] = item.Name
                table.insert(TrailNames, name)
            end
            table.sort(TrailNames)
        end

        local auraFolder = ReplicatedStorage.ShopItems:FindFirstChild("Aura")
        if auraFolder then
            for _, item in auraFolder:GetChildren() do
                local name = item.Name:gsub("Aura_", "")
                Auras[name] = item.Name
                table.insert(AuraNames, name)
            end
            table.sort(AuraNames)
        end

        -- Court skin list: try multiple known folder names
        local function addCourtFolder(folder)
            if not folder then return end
            for _, item in folder:GetChildren() do
                local name = item.Name:gsub("^CourtSkin_", ""):gsub("^Court_", ""):gsub("^Skin_", "")
                if not Courts[name] then
                    Courts[name] = item.Name
                    table.insert(CourtNames, name)
                end
            end
        end
        local shop = ReplicatedStorage:FindFirstChild("ShopItems")
        if shop then
            addCourtFolder(shop:FindFirstChild("CourtSkin"))
            addCourtFolder(shop:FindFirstChild("Courts"))
            addCourtFolder(shop:FindFirstChild("Court"))
        end
        -- Fallback: scan any folder named Court* under ReplicatedStorage
        if #CourtNames == 0 then
            for _, inst in ReplicatedStorage:GetDescendants() do
                if inst:IsA("Folder") and inst.Name:lower():find("court", 1, true) and inst.Parent then
                    addCourtFolder(inst)
                end
            end
        end
        table.sort(CourtNames)
        if #CourtNames > 0 and (s.CourtSpoofer.SelectedCourt == "None" or s.CourtSpoofer.CurrentCourt == "None") then
            s.CourtSpoofer.SelectedCourt = CourtNames[1]
            s.CourtSpoofer.CurrentCourt = CourtNames[1]
        end
    end)

    local function ownerOfParent(parent)
        local node = parent
        for _ = 1, 6 do
            if not node then break end
            if node:IsA("Model") then
                local plr = Players:GetPlayerFromCharacter(node)
                if plr then return plr end
            end
            node = node.Parent
        end
        return nil
    end

    local function applyBallChanger()
        if not Replicator or not OriginalReplicateBall then return end
        Replicator["ReplicateBall"] = function(Parent, Name)
            if ownerOfParent(Parent) == LocalPlayer then
                local spoofed = Balls[s.BallChanger.CurrentBall]
                if spoofed then Name = spoofed end
            end
            return OriginalReplicateBall(Parent, Name)
        end
    end

    local function resetBallChanger()
        if not Replicator or not OriginalReplicateBall then return end
        Replicator["ReplicateBall"] = OriginalReplicateBall
    end

    local function applyTrailSpoofer()
        if not Replicator or not OriginalReplicateTrail then return end
        Replicator["ReplicateTrail"] = function(Parent, Name)
            if ownerOfParent(Parent) == LocalPlayer then
                local spoofed = Trails[s.TrailSpoofer.CurrentTrail]
                if spoofed then Name = spoofed end
            end
            return OriginalReplicateTrail(Parent, Name)
        end
    end

    local function resetTrailSpoofer()
        if not Replicator or not OriginalReplicateTrail then return end
        Replicator["ReplicateTrail"] = OriginalReplicateTrail
    end

    local function applyBallAura()
        if not Replicator or not OriginalReplicateAura then return end
        Replicator["ReplicateAura"] = function(Parent, Name)
            if ownerOfParent(Parent) == LocalPlayer then
                local spoofed = Auras[s.BallAura.CurrentAura]
                if spoofed then Name = spoofed end
            end
            return OriginalReplicateAura(Parent, Name)
        end
    end

    local function resetBallAura()
        if not Replicator or not OriginalReplicateAura then return end
        Replicator["ReplicateAura"] = OriginalReplicateAura
    end

    -- ============================================================
    -- COURT SKIN SPOOFER (Replicator hook + PlayerData fallback)
    -- ============================================================
    local function applyCourtSpoofer()
        local target = Courts[s.CourtSpoofer.CurrentCourt]
        if not target then
            Notify({ title = "Court Spoofer", content = "Selected court not found.", duration = 3 })
            return
        end
        if Replicator and OriginalReplicateCourt then
            Replicator["ReplicateCourt"] = function(Parent, Name)
                if ownerOfParent(Parent) == LocalPlayer then
                    local spoofed = Courts[s.CourtSpoofer.CurrentCourt]
                    if spoofed then Name = spoofed end
                end
                return OriginalReplicateCourt(Parent, Name)
            end
        end
        pcall(function()
            local PlayerData = require(ReplicatedStorage.Util.PlayerData)
            PlayerData.storedData["Equipping"]["CourtSkin"] = target
            PlayerData.storedData["Inventory"][target] = 1
        end)
        Notify({ title = "Court Spoofer", content = "Applied: " .. s.CourtSpoofer.CurrentCourt, duration = 2.5 })
    end

    local function resetCourtSpoofer()
        if Replicator and OriginalReplicateCourt then
            Replicator["ReplicateCourt"] = OriginalReplicateCourt
        end
        pcall(function()
            local PlayerData = require(ReplicatedStorage.Util.PlayerData)
            PlayerData.storedData["Equipping"]["CourtSkin"] = nil
        end)
    end

    local indicator = Instance.new("BillboardGui")
    indicator.Name = "RangeIndicator"
    indicator.Size = UDim2.fromOffset(90, 90)
    indicator.AlwaysOnTop = true
    indicator.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)

    local indicatorRing = Instance.new("ImageLabel")
    indicatorRing.Name = "Ring"
    indicatorRing.Size = UDim2.fromScale(1, 1)
    indicatorRing.BackgroundTransparency = 1
    indicatorRing.Image = "rbxassetid://3570695787"
    indicatorRing.ImageColor3 = Color3.fromRGB(242, 140, 62)
    indicatorRing.ImageTransparency = 0.15
    indicatorRing.ScaleType = Enum.ScaleType.Fit
    indicatorRing.Parent = indicator

    local indicatorDot = Instance.new("Frame")
    indicatorDot.Name = "Dot"
    indicatorDot.Size = UDim2.fromOffset(6, 6)
    indicatorDot.AnchorPoint = Vector2.new(0.5, 0.5)
    indicatorDot.Position = UDim2.fromScale(0.5, 0.5)
    indicatorDot.BackgroundColor3 = Color3.fromRGB(242, 140, 62)
    indicatorDot.BorderSizePixel = 0
    indicatorDot.Parent = indicator
    local indicatorDotCorner = Instance.new("UICorner")
    indicatorDotCorner.CornerRadius = UDim.new(1, 0)
    indicatorDotCorner.Parent = indicatorDot

    local rangeConnection = nil

    local function applyIndicatorColor()
        local col = IndicatorColors[s.Visuals.IndicatorColor] or Color3.fromRGB(242, 140, 62)
        indicatorRing.ImageColor3 = col
        indicatorDot.BackgroundColor3 = col
    end

    local function setShotIndicator(value)
        s.Visuals.ShotIndicator = value
        if rangeConnection then rangeConnection:Disconnect(); rangeConnection = nil end
        indicator.Parent = nil
        if not value then return end
        local throttle = 0
        rangeConnection = RunService.Heartbeat:Connect(function(dt)
            throttle += dt
            if throttle < 0.05 then return end
            throttle = 0
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root or not hasball(character) then indicator.Parent = nil; return end
            local goal, distance = nearestgoal(root)
            if goal and distance >= 12 and distance <= 73 then
                applyIndicatorColor()
                if indicator.Parent ~= character then
                    indicator.Adornee = character
                    indicator.Parent = character
                end
            else
                indicator.Parent = nil
            end
        end)
        Track(rangeConnection)
    end

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
        getgenv().__bytewtf_aiming = true
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
            getgenv().__bytewtf_aiming = false
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
local st = registry:GetSharedTable(__bytewtfaimtable)
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
        local code = "local __bytewtfaimtable = " .. string.format("%q", state.actorname) .. " " .. actorcode
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

    local textListeners = {}
    local originalNameTexts, originalRecordTexts, originalTitleTexts = {}, {}, {}

    local function formatStrokeText(orig, custom)
        if not custom or custom == "" then return orig end
        if orig and orig:match("^<stroke>") and orig:match("</stroke>$") then
            return "<stroke>" .. custom .. "</stroke>"
        end
        return custom
    end

    local function applyOwnNameplate()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local nameTag = hrp:FindFirstChild("NameTag")
        if not nameTag or not nameTag:IsA("BillboardGui") then return end
        for _, tagName in ipairs({"NameTag", "CreatorTag", "TeamSpot"}) do
            local tag = hrp:FindFirstChild(tagName)
            if tag and tag:IsA("BillboardGui") then
                tag.Enabled = not s.Visuals.HideOwnNameplate
            end
        end
        local mainFrame = nameTag:FindFirstChild("MainFrame")
        local gameFrame = nameTag:FindFirstChild("GameFrame")
        local subFrame = mainFrame and mainFrame:FindFirstChild("Frame")
        local nameLabels = {}
        if mainFrame and mainFrame:FindFirstChild("NameLabel") then table.insert(nameLabels, mainFrame.NameLabel) end
        if gameFrame and gameFrame:FindFirstChild("NameLabel") then table.insert(nameLabels, gameFrame.NameLabel) end
        for _, obj in ipairs(nameTag:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "NameLabel" and not table.find(nameLabels, obj) then
                table.insert(nameLabels, obj)
            end
        end
        for _, obj in ipairs(nameLabels) do
            if not originalNameTexts[obj] then originalNameTexts[obj] = obj.Text end
            local target = (s.Visuals.CustomNameText ~= "") and s.Visuals.CustomNameText or originalNameTexts[obj]
            if obj.Text ~= target then obj.Text = target end
            if not textListeners[obj] then
                textListeners[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function()
                    if s.Visuals.CustomNameText ~= "" and obj.Text ~= s.Visuals.CustomNameText then
                        obj.Text = s.Visuals.CustomNameText
                    end
                end)
            end
        end
        local recordLabels = {}
        if subFrame and subFrame:FindFirstChild("RecordLabel") then table.insert(recordLabels, subFrame.RecordLabel) end
        for _, obj in ipairs(nameTag:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "RecordLabel" and not table.find(recordLabels, obj) then
                table.insert(recordLabels, obj)
            end
        end
        for _, obj in ipairs(recordLabels) do
            if not originalRecordTexts[obj] then originalRecordTexts[obj] = obj.Text end
            local target = formatStrokeText(originalRecordTexts[obj], s.Visuals.CustomRecordText)
            if obj.Text ~= target then obj.Text = target end
            if not textListeners[obj] then
                textListeners[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function()
                    if s.Visuals.CustomRecordText ~= "" then
                        local expected = formatStrokeText(originalRecordTexts[obj], s.Visuals.CustomRecordText)
                        if obj.Text ~= expected then obj.Text = expected end
                    end
                end)
            end
        end
        local titleLabels = {}
        if subFrame and subFrame:FindFirstChild("AchievementName") then table.insert(titleLabels, subFrame.AchievementName) end
        for _, obj in ipairs(nameTag:GetDescendants()) do
            if obj:IsA("TextLabel") and (obj.Name == "AchievementName" or obj.Name == "TitleLabel") and not table.find(titleLabels, obj) then
                table.insert(titleLabels, obj)
            end
        end
        for _, obj in ipairs(titleLabels) do
            if not originalTitleTexts[obj] then originalTitleTexts[obj] = obj.Text end
            local target = formatStrokeText(originalTitleTexts[obj], s.Visuals.CustomTitleText)
            if obj.Text ~= target then obj.Text = target end
            if not textListeners[obj] then
                textListeners[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function()
                    if s.Visuals.CustomTitleText ~= "" then
                        local expected = formatStrokeText(originalTitleTexts[obj], s.Visuals.CustomTitleText)
                        if obj.Text ~= expected then obj.Text = expected end
                    end
                end)
            end
        end
    end

    local ownNameplateConnection = nil

    local function setupOwnNameplateListener()
        if ownNameplateConnection then return end
        local function onChar(char)
            task.wait(0.2)
            applyOwnNameplate()
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                hrp.ChildAdded:Connect(function(child)
                    if child:IsA("BillboardGui") then
                        task.wait(0.05)
                        applyOwnNameplate()
                    end
                end)
                local nameTag = hrp:WaitForChild("NameTag", 5)
                if nameTag then
                    nameTag.DescendantAdded:Connect(function()
                        task.wait(0.05)
                        applyOwnNameplate()
                    end)
                end
            end
        end
        if LocalPlayer.Character then task.spawn(onChar, LocalPlayer.Character) end
        ownNameplateConnection = LocalPlayer.CharacterAdded:Connect(onChar)
        Track(ownNameplateConnection)
    end
    setupOwnNameplateListener()

    -- ============================================================
    -- BODY AURA CHANGER (cosmetic, client-side)
    -- ============================================================
    local baScan, baApply, baEnable, baDisable
    local BodyAuraList = {}
    do
        local BodyAura = {
            active = false,
            selected = nil,
            container = nil,
            charAddedConn = nil,
            list = {},
            lookup = {},
        }

        local function ba_hidePlastic(container)
            if not container then return end
            local hideList, hasReal = {}, false
            for _, child in pairs(container:GetDescendants()) do
                if child:IsA("BasePart") then
                    local plastic = child.Material == Enum.Material.Plastic
                    local placeholder = child.Name:lower() == "aura"
                    if plastic or placeholder then
                        table.insert(hideList, child)
                    elseif child.Transparency < 1 then
                        hasReal = true
                    end
                elseif child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail") then
                    hasReal = true
                end
            end
            -- If everything is plastic, those parts ARE the aura, so keep them.
            if not hasReal then return end
            for _, part in ipairs(hideList) do
                part.Transparency = 1; part.CanCollide = false
            end
        end

        local function ba_cleanCharacter(char)
            if not char then return end
            local realHead = char:FindFirstChild("Head")
            for _, child in pairs(char:GetChildren()) do
                if child:IsA("Part") or child:IsA("MeshPart") then
                    if child.Name:lower():find("head") and child ~= realHead then
                        child.Transparency = 1; child.CanCollide = false
                    end
                    if child.Name:lower() == "aura" then
                        child.Transparency = 1; child.CanCollide = false
                    end
                end
            end
            local realHum = char:FindFirstChildOfClass("Humanoid")
            for _, child in pairs(char:GetChildren()) do
                if child:IsA("Humanoid") and child ~= realHum then child:Destroy() end
            end
        end

        local function ba_findRig(auraModel)
            for _, child in pairs(auraModel:GetChildren()) do
                if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then return child end
            end
            if auraModel:FindFirstChildOfClass("Humanoid") then return auraModel end
            local hum = auraModel:FindFirstChildWhichIsA("Humanoid", true)
            if hum and hum.Parent then return hum.Parent end
            return nil
        end

        local function ba_rigParts(rigModel)
            local parts = {}
            for _, name in pairs({"Head","LeftArm","RightArm","Torso","LeftLeg","RightLeg","HumanoidRootPart"}) do
                local part = rigModel:FindFirstChild(name)
                if part and part:IsA("BasePart") then parts[name] = part end
            end
            return parts
        end

        local function ba_charParts(char)
            local parts = {}
            for _, name in pairs({"Head","LeftArm","RightArm","Torso","UpperTorso","LeftLeg","RightLeg","HumanoidRootPart"}) do
                local part = char:FindFirstChild(name)
                if part and part:IsA("BasePart") then parts[name] = part end
            end
            return parts
        end

        local function ba_stripFace(part)
            if not part then return end
            for _, child in pairs(part:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
                    child:Destroy()
                end
            end
            if part:FindFirstChild("face") then part.face:Destroy() end
        end

        local function ba_destroyContainer()
            BodyAura.container = nil
            local char = LocalPlayer.Character
            if char then
                local c = char:FindFirstChild("AuraVisuals")
                if c then c:Destroy() end
            end
        end

        local function ba_norm(name)
            return (name:lower():gsub("[%s_]", ""))
        end

        local function ba_isHeadish(name)
            local n = name:lower()
            return n:find("head") or n:find("hair") or n:find("hat")
        end

        -- Builds the aura on your character. Returns true, or false plus the reason.
        local function ba_build(auraModel)
            local char = LocalPlayer.Character
            if not char or not char.Parent then return false, "no character" end
            local native = char:FindFirstChild("bodyaura")
            if native and native:IsA("LocalScript") then native.Disabled = true end
            ba_destroyContainer()
            ba_cleanCharacter(char)

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return false, "no HumanoidRootPart" end

            local rig = ba_findRig(auraModel)
            local source = rig or auraModel

            -- every visual part of the aura (skip parts nested inside another part)
            local items = {}
            local function collect(inst)
                if inst:IsA("BasePart") then
                    local p, nested = inst.Parent, false
                    while p and p ~= source do
                        if p:IsA("BasePart") then nested = true; break end
                        p = p.Parent
                    end
                    if not nested then table.insert(items, inst) end
                end
            end
            collect(source)
            for _, d in ipairs(source:GetDescendants()) do collect(d) end
            if #items == 0 then return false, "aura has no parts" end

            -- reference point of the aura model
            local rigRoot = rig and (rig:FindFirstChild("HumanoidRootPart") or rig.PrimaryPart
                or rig:FindFirstChild("Torso") or rig:FindFirstChild("UpperTorso"))
            local pivot
            if rigRoot and rigRoot:IsA("BasePart") then
                pivot = rigRoot.CFrame
            else
                local sum = Vector3.zero
                for _, p in ipairs(items) do sum += p.Position end
                pivot = CFrame.new(sum / #items)
            end

            -- your character's parts, by normalised name ("Left Arm" == "LeftArm")
            local charByName = {}
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then charByName[ba_norm(p.Name)] = p end
            end
            local rigHead = rig and rig:FindFirstChild("Head")
            local charHead = char:FindFirstChild("Head")

            local container = Instance.new("Model")
            container.Name = "AuraVisuals"
            container.Parent = char
            BodyAura.container = container

            local built = 0
            for _, auraPart in ipairs(items) do
                local newPart = auraPart:Clone()
                -- drop anything that could fight your character
                for _, d in ipairs(newPart:GetDescendants()) do
                    if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Humanoid")
                        or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                        d:Destroy()
                    end
                end
                newPart.Anchored = false
                newPart.CanCollide = false
                newPart.CanTouch = false
                newPart.CanQuery = false
                newPart.Massless = true
                newPart.Parent = container

                local isRoot = auraPart == rigRoot or auraPart.Name == "HumanoidRootPart"
                if isRoot then newPart.Transparency = 1 end
                if ba_isHeadish(auraPart.Name) then ba_stripFace(newPart) end

                local weld = Instance.new("Weld")
                weld.Part1 = newPart
                local direct = (auraPart.Parent == source) and charByName[ba_norm(auraPart.Name)]
                if direct then
                    -- same body part on both sides: sit exactly on it
                    weld.Part0 = direct
                    weld.C0 = CFrame.new()
                elseif ba_isHeadish(auraPart.Name) and charHead then
                    -- hair / hat style parts follow your head
                    weld.Part0 = charHead
                    local ref = rigHead and rigHead.CFrame or pivot
                    weld.C0 = ref:ToObjectSpace(auraPart.CFrame)
                else
                    -- everything else keeps its place relative to the aura's centre
                    weld.Part0 = hrp
                    weld.C0 = pivot:ToObjectSpace(auraPart.CFrame)
                end
                weld.Parent = newPart
                built += 1
            end

            ba_hidePlastic(container)
            if built == 0 then return false, "nothing built" end
            return true
        end

        local function ba_scanList()
            table.clear(BodyAura.list)
            table.clear(BodyAura.lookup)
            local ShopItems = ReplicatedStorage:FindFirstChild("ShopItems") or ReplicatedStorage:WaitForChild("ShopItems", 5)
            if not ShopItems then return end
            local folder = ShopItems:FindFirstChild("Aura") or ShopItems:WaitForChild("Aura", 5)
            if not folder then return end
            for _, child in pairs(folder:GetChildren()) do
                local name = child.Name:gsub("^Aura_", "")
                BodyAura.lookup[name] = child
                table.insert(BodyAura.list, name)
            end
            table.sort(BodyAura.list)
        end

        local function ba_applyByName(name)
            local model = BodyAura.lookup[name]
            if not model then return false, "aura not found" end
            BodyAura.selected = name
            if not BodyAura.active then return false, "disabled" end
            return ba_build(model)
        end

        local function ba_enable(name)
            ba_scanList()
            BodyAura.active = true
            if name and BodyAura.lookup[name] then
                BodyAura.selected = name
            elseif not BodyAura.selected and #BodyAura.list > 0 then
                BodyAura.selected = BodyAura.list[1]
            end
            local ok, why = true, nil
            if BodyAura.selected then ok, why = ba_applyByName(BodyAura.selected) end
            if not BodyAura.charAddedConn then
                BodyAura.charAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
                    char:WaitForChild("HumanoidRootPart", 5)
                    task.wait(1)
                    if BodyAura.active and BodyAura.selected then ba_applyByName(BodyAura.selected) end
                end)
            end
            return ok, why
        end

        local function ba_disable()
            BodyAura.active = false
            if BodyAura.charAddedConn then
                BodyAura.charAddedConn:Disconnect(); BodyAura.charAddedConn = nil
            end
            ba_destroyContainer()
        end

        baScan, baApply, baEnable, baDisable = ba_scanList, ba_applyByName, ba_enable, ba_disable
        BodyAuraList = BodyAura.list
    end
    baScan()

    -- ============================================================
    -- NAMETAG LOGO CHANGER (client-side only: edits your own CreatorTag icons)
    -- ============================================================
    local LogoNames = { "Booster", "Staff", "Tester", "Twitch", "VIP", "Youtuber" }
    local LogoOriginal, LogoWanted = {}, {}
    local applyLogo, resetLogos, logoDefault

    do
        local function getCreatorTag()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            return hrp and hrp:FindFirstChild("CreatorTag")
        end

        local function setIcon(name, on)
            local tag = getCreatorTag()
            if not tag then return end
            for _, v in ipairs(tag:GetChildren()) do
                if v:IsA("ImageLabel") and v.Name == name then v.Visible = on end
            end
        end

        local function snapshot()
            local tag = getCreatorTag()
            if not tag then return end
            for _, n in ipairs(LogoNames) do
                if LogoOriginal[n] == nil then
                    local lbl = tag:FindFirstChild(n)
                    LogoOriginal[n] = (lbl and lbl:IsA("ImageLabel")) and lbl.Visible or false
                end
            end
        end
        snapshot()

        logoDefault = function(name) return LogoOriginal[name] == true end

        applyLogo = function(name, on)
            snapshot()
            LogoWanted[name] = on
            pcall(function() LocalPlayer:SetAttribute(name, on) end)
            setIcon(name, on)
        end

        resetLogos = function()
            for _, n in ipairs(LogoNames) do
                local orig = LogoOriginal[n] == true
                LogoWanted[n] = nil
                pcall(function() LocalPlayer:SetAttribute(n, orig) end)
                setIcon(n, orig)
            end
        end

        -- Re-apply chosen icons after respawn (the tag is rebuilt each life).
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            local tag = hrp and hrp:WaitForChild("CreatorTag", 5)
            if not tag then return end
            task.wait(0.3)
            for n, on in pairs(LogoWanted) do setIcon(n, on) end
        end))
    end

    local Window = Airflow:CreateWindow({Name = "Byte.WTF", LoadingSubtitle = "Byte On Top", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "Byte.WTF", FileName = "Byte.WTF"}})

    Notify = function(props) Window:Notify(props) end

    local CombatTab = Window:CreateTab({ Name = "Main", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "HVH", Icon = "activity" })
    local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "eye" })
    local PrivacyTab = Window:CreateTab({ Name = "Privacy", Icon = "user" })
    local UtilityTab = Window:CreateTab({ Name = "Utility", Icon = "list" })

    CombatTab:CreateSection("Silent Aim")
    CombatTab:CreateToggle({
        Name = "Enable Silent Aim",
        Desc = "Automatically Shoots when you Jump",
        Flag = "bytewtf_aural",
        CurrentValue = s.Shooting.AuralEnabled,
        Callback = function(v) setAural(v) end,
    })
    CombatTab:CreateKeybind({
        Name = "Aimbot keybind",
        Flag = "bytewtf_aural_key",
        CurrentValue = s.Shooting.AuralKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AuralKeybind = key end
        end,
    })
    CombatTab:CreateToggle({
        Name = "EBL Hop", Desc = "Require second jump before firing.",
        Flag = "bytewtf_ebl", CurrentValue = s.Shooting.EBLHop,
        Callback = function(v) s.Shooting.EBLHop = v end,
    })
    CombatTab:CreateSlider({
        Name = "Shot delay",
        Range = { 0.15, 0.42 }, Increment = 0.01, Suffix = "s",
        CurrentValue = s.Shooting.ShotDelay, Flag = "bytewtf_delay",
        Callback = function(v) s.Shooting.ShotDelay = v end,
    })
    CombatTab:CreateSection("Shot Timing")
    CombatTab:CreateToggle({
        Name = "Randomize shot delay", Flag = "bytewtf_randdelay",
        CurrentValue = s.Shooting.RandomizeShotDelay,
        Callback = function(v) s.Shooting.RandomizeShotDelay = v end,
    })
    CombatTab:CreateSlider({
        Name = "Min delay", Range = { 0, 1 }, Increment = 0.05, Suffix = "s",
        CurrentValue = s.Shooting.ShotDelayMin, Flag = "bytewtf_mindelay",
        Callback = function(v) s.Shooting.ShotDelayMin = v end,
    })
    CombatTab:CreateSlider({
        Name = "Max delay", Range = { 0, 1 }, Increment = 0.05, Suffix = "s",
        CurrentValue = s.Shooting.ShotDelayMax, Flag = "bytewtf_maxdelay",
        Callback = function(v) s.Shooting.ShotDelayMax = v end,
    })
    CombatTab:CreateSection("Humanize")
    CombatTab:CreateToggle({
        Name = "Humanize aim", Flag = "bytewtf_human",
        CurrentValue = s.Shooting.HumanizeAim,
        Callback = function(v) s.Shooting.HumanizeAim = v end,
    })
    CombatTab:CreateSlider({
        Name = "Humanize strength", Range = { 0.2, 5 }, Increment = 0.1,
        CurrentValue = s.Shooting.HumanizeStrength, Flag = "bytewtf_hstr",
        Callback = function(v) s.Shooting.HumanizeStrength = v end,
    })
    CombatTab:CreateSlider({
        Name = "Miss chance", Range = { 0, 80 }, Increment = 1, Suffix = "%",
        CurrentValue = s.Shooting.MissChance, Flag = "bytewtf_miss",
        Callback = function(v) s.Shooting.MissChance = v end,
    })

    CombatTab:CreateSection("Auto Guard")
    CombatTab:CreateToggle({
        Name = "Auto guard", Flag = "bytewtf_guard", CurrentValue = s.Defending.AutoGuard,
        Callback = function(v) setGuard(v) end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto guard keybind", Flag = "bytewtf_guard_key",
        CurrentValue = s.Defending.GuardKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Defending.GuardKeybind = key end
        end,
    })
    CombatTab:CreateDropdown({
        Name = "Guard mode", Options = { "Reactive", "Balanced", "Aggressive" },
        CurrentValue = s.Defending.AutoGuardMode, Flag = "bytewtf_guard_mode",
        Callback = function(v) s.Defending.AutoGuardMode = v end,
    })
    CombatTab:CreateToggle({
        Name = "Guard nearest if no dribbler", Flag = "bytewtf_guard_near",
        CurrentValue = s.Defending.AutoGuardNearest,
        Callback = function(v) s.Defending.AutoGuardNearest = v end,
    })
    CombatTab:CreateSlider({
        Name = "Guard range", Range = { 10, 60 }, Increment = 1,
        CurrentValue = s.Defending.AutoGuardRange, Flag = "bytewtf_guard_range",
        Callback = function(v) s.Defending.AutoGuardRange = v end,
    })
    CombatTab:CreateSlider({
        Name = "Prediction strength", Range = { 0.1, 1 }, Increment = 0.05,
        CurrentValue = s.Defending.GuardPrediction, Flag = "bytewtf_guard_pred",
        Callback = function(v) s.Defending.GuardPrediction = v end,
    })

    BallTab:CreateSection("Ball Magnet")
    BallTab:CreateToggle({
        Name = "Ball magnet", Flag = "bytewtf_mag", CurrentValue = s.Ball.BallMags,
        Callback = function(v) setMagnet(v) end,
    })
    BallTab:CreateKeybind({
        Name = "Magnet keybind", Flag = "bytewtf_mag_key", CurrentValue = Enum.KeyCode.M,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Ball.MagnetKeybind = key.Name end
        end,
    })
    BallTab:CreateSlider({
        Name = "Magnet size", Range = { 1, 50 }, Increment = 1,
        CurrentValue = s.Ball.BallMagRange, Flag = "bytewtf_mag_size",
        Callback = function(v)
            s.Ball.BallMagRange = v
            if magnetHitbox then magnetHitbox.Size = Vector3.new(v, v, v) end
        end,
    })
    BallTab:CreateToggle({
        Name = "Show magnet visualizer", Flag = "bytewtf_mag_vis",
        CurrentValue = s.Ball.BallMagVisualizer,
        Callback = function(v)
            s.Ball.BallMagVisualizer = v
            if magnetHitbox then
                local box = magnetHitbox:FindFirstChild("ByteMagnetBox")
                if box then box.Transparency = v and 0.2 or 1 end
            end
        end,
    })

    BallTab:CreateSection("Mag V2")
    BallTab:CreateToggle({
        Name = "Mag V2",
        Desc = "Standalone touch-magnet. Uses its own ball name & reach.",
        Flag = "bytewtf_magv2", CurrentValue = s.MagV2.Enabled,
        Callback = function(v) setMagV2(v) end,
    })
    BallTab:CreateKeybind({
        Name = "Mag V2 keybind", Desc = "Default U. Toggle Mag V2 on/off.",
        Flag = "bytewtf_magv2_key", CurrentValue = s.MagV2.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.MagV2.Keybind = key end
        end,
    })
    BallTab:CreateInput({
        Name = "Mag V2 ball name", Placeholder = "Ball",
        CurrentValue = s.MagV2.BallName, Flag = "bytewtf_magv2_name",
        Callback = function(text)
            if text ~= "" then s.MagV2.BallName = text end
        end,
    })
    BallTab:CreateSlider({
        Name = "Mag V2 reach", Range = { 1, 100 }, Increment = 1,
        CurrentValue = s.MagV2.Reach, Flag = "bytewtf_magv2_reach",
        Callback = function(v) s.MagV2.Reach = v end,
    })

    BallTab:CreateSection("Ball Reach")
    BallTab:CreateToggle({
        Name = "Ball reach", Flag = "bytewtf_reach", CurrentValue = s.Ball.BallReach,
        Callback = function(v) setReach(v) end,
    })
    BallTab:CreateKeybind({
        Name = "Reach keybind", Flag = "bytewtf_reach_key", CurrentValue = Enum.KeyCode.N,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Ball.ReachKeybind = key.Name end
        end,
    })
    BallTab:CreateSlider({
        Name = "Reach size", Range = { 1, 30 }, Increment = 1,
        CurrentValue = s.Ball.BallReachRange, Flag = "bytewtf_reach_size",
        Callback = function(v) s.Ball.BallReachRange = v end,
    })
    BallTab:CreateToggle({
        Name = "Show reach visualizer", Flag = "bytewtf_reach_vis",
        CurrentValue = s.Ball.BallReachVisualizer,
        Callback = function(v)
            s.Ball.BallReachVisualizer = v
            if v then
                enableReach()
            else
                removeReachVisualizer()
                if not s.Ball.BallReach then disableReach() end
            end
        end,
    })

    BallTab:CreateSection("TPWalk")
    BallTab:CreateToggle({
        Name = "tpwalk",
        Desc = "Teleport-walk; nudges your root part each frame for a smooth glide.",
        Flag = "bytewtf_tpwalk", CurrentValue = s.TPWalk.Enabled,
        Callback = function(v) setTPWalk(v) end,
    })
    BallTab:CreateKeybind({
        Name = "tpwalk keybind", Flag = "bytewtf_tpwalk_key",
        CurrentValue = s.TPWalk.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.TPWalk.Keybind = key end
        end,
    })
    BallTab:CreateSlider({
        Name = "tpwalk speed", Desc = "Step distance per frame (0.001 – 0.06).",
        Range = { 0.001, 0.06 }, Increment = 0.001,
        CurrentValue = s.TPWalk.Speed, Flag = "bytewtf_tpwalk_speed",
        Callback = function(v) s.TPWalk.Speed = v end,
    })

    buildHVHTab(HVHTab, s.HVH)

    VisualsTab:CreateSection("Aimbot Range Indicator")
    VisualsTab:CreateToggle({
        Name = "Aimbot range indicator", Flag = "bytewtf_ind",
        CurrentValue = s.Visuals.ShotIndicator,
        Callback = setShotIndicator,
    })
    VisualsTab:CreateDropdown({
        Name = "Indicator color",
        Options = { "Blue", "Purple", "Green", "Red", "Yellow" },
        CurrentValue = s.Visuals.IndicatorColor, Flag = "bytewtf_ind_col",
        Callback = function(v) s.Visuals.IndicatorColor = v; applyIndicatorColor() end,
    })

    VisualsTab:CreateSection("Goal Effect")
    local function getEffectNames()
        local names = {}
        for k in pairs(Effects) do table.insert(names, k) end
        table.sort(names)
        return names
    end
    VisualsTab:CreateDropdown({
        Name = "Select effect", Options = getEffectNames(),
        CurrentValue = s.Goal.SelectedEffect, Flag = "bytewtf_goal_sel",
        Callback = function(v)
            s.Goal.SelectedEffect = v
            s.Goal.CurrentEffect = v
            if s.Goal.Enabled then pcall(applyGoalEffect) end
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Enable goal effect changer", Flag = "bytewtf_goal",
        CurrentValue = s.Goal.Enabled,
        Callback = function(v)
            s.Goal.Enabled = v
            if v then pcall(applyGoalEffect) else pcall(resetGoalEffect) end
        end,
    })
    VisualsTab:CreateButton({
        Name = "Reset goal effect",
        Callback = function()
            s.Goal.Enabled = false
            s.Goal.SelectedEffect = "LightRay"
            s.Goal.CurrentEffect = "LightRay"
            pcall(resetGoalEffect)
        end,
    })

    VisualsTab:CreateSection("Body Aura")
    VisualsTab:CreateDropdown({
        Name = "Aura", Options = #BodyAuraList > 0 and BodyAuraList or { "None" },
        CurrentValue = s.BodyAura.Selected ~= "" and s.BodyAura.Selected or nil, Flag = "bytewtf_bodyaura_sel",
        Callback = function(v)
            s.BodyAura.Selected = v
            if s.BodyAura.Enabled then
                local ok, why = baApply(v)
                if not ok then Notify({ title = "Body Aura", content = "Could not apply " .. tostring(v) .. ": " .. tostring(why), duration = 4 }) end
            end
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Enable body aura", Flag = "bytewtf_bodyaura", CurrentValue = s.BodyAura.Enabled,
        Callback = function(v)
            s.BodyAura.Enabled = v
            if v then
                local ok, why = baEnable(s.BodyAura.Selected ~= "" and s.BodyAura.Selected or nil)
                if not ok then Notify({ title = "Body Aura", content = "Could not apply: " .. tostring(why), duration = 4 }) end
            else
                baDisable()
            end
        end,
    })
    VisualsTab:CreateButton({
        Name = "Reset body aura",
        Callback = function()
            s.BodyAura.Enabled = false
            s.BodyAura.Selected = ""
            baDisable()
        end,
    })

    VisualsTab:CreateSection("Court Spoofer")
    VisualsTab:CreateDropdown({
        Name = "Select court", Options = #CourtNames > 0 and CourtNames or { "None" },
        CurrentValue = s.CourtSpoofer.SelectedCourt, Flag = "bytewtf_court_sel",
        Callback = function(v)
            s.CourtSpoofer.SelectedCourt = v
            s.CourtSpoofer.CurrentCourt = v
            if s.CourtSpoofer.Enabled then pcall(applyCourtSpoofer) end
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Enable court spoofer", Flag = "bytewtf_court",
        CurrentValue = s.CourtSpoofer.Enabled,
        Callback = function(v)
            s.CourtSpoofer.Enabled = v
            if v then pcall(applyCourtSpoofer) else pcall(resetCourtSpoofer) end
        end,
    })
    VisualsTab:CreateButton({
        Name = "Reset court",
        Callback = function()
            s.CourtSpoofer.Enabled = false
            s.CourtSpoofer.SelectedCourt = "None"
            s.CourtSpoofer.CurrentCourt = "None"
            pcall(resetCourtSpoofer)
        end,
    })

    VisualsTab:CreateSection("Nameplate & Title")
    VisualsTab:CreateToggle({
        Name = "Hide my nameplate & tags", Flag = "bytewtf_np_hide",
        CurrentValue = s.Visuals.HideOwnNameplate,
        Callback = function(v) s.Visuals.HideOwnNameplate = v; applyOwnNameplate() end,
    })
    VisualsTab:CreateInput({
        Name = "Custom username", Placeholder = "e.g. Byte",
        CurrentValue = s.Visuals.CustomNameText, Flag = "bytewtf_np_name",
        Callback = function(text)
            s.Visuals.CustomNameText = text
            s.Visuals.CustomName = (text ~= "")
            applyOwnNameplate()
        end,
    })
    VisualsTab:CreateInput({
        Name = "Custom record", Placeholder = "e.g. 99-0",
        CurrentValue = s.Visuals.CustomRecordText, Flag = "bytewtf_np_rec",
        Callback = function(text)
            s.Visuals.CustomRecordText = text
            s.Visuals.CustomRecord = (text ~= "")
            applyOwnNameplate()
        end,
    })
    VisualsTab:CreateInput({
        Name = "Custom title", Placeholder = "e.g. Byte Elite",
        CurrentValue = s.Visuals.CustomTitleText, Flag = "bytewtf_np_title",
        Callback = function(text)
            s.Visuals.CustomTitleText = text
            s.Visuals.CustomTitle = (text ~= "")
            applyOwnNameplate()
        end,
    })


    -- ============================================================
    -- PLAYER MORPH (client-side avatar change)
    -- ============================================================
    do
        VisualsTab:CreateSection("Player Morph")
        local morphOriginal
        local typedName = ""
        local pickedPlayer

        local function morphNotify(t, c)
            pcall(function() Notify({ title = t, content = c, duration = 3 }) end)
        end

        local function applyUser(userId)
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return false, "No character found." end
            if not morphOriginal then
                local okO, d = pcall(function() return hum:GetAppliedDescription() end)
                if okO then morphOriginal = d end
            end
            local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
            if not ok or not desc then return false, "Couldn't load that avatar." end
            local ok2, err = pcall(function() hum:ApplyDescriptionReset(desc) end)
            if not ok2 then return false, tostring(err) end
            return true
        end

        local function resetAvatar()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return false, "No character found." end
            local desc = morphOriginal
            if not desc then
                local ok, d = pcall(function() return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId) end)
                if ok then desc = d end
            end
            if not desc then return false, "Couldn't load your avatar." end
            local ok2, err = pcall(function() hum:ApplyDescriptionReset(desc) end)
            if not ok2 then return false, tostring(err) end
            return true
        end

        local function doReset()
            task.spawn(function()
                local ok, why = resetAvatar()
                morphNotify("Player Morph", ok and "Avatar reset." or (why or "Reset failed."))
            end)
        end

        VisualsTab:CreateInput({
            Name = "Username", Placeholder = "any Roblox username",
            CurrentValue = "", Flag = "bytewtf_morph_name",
            Callback = function(t) typedName = t end,
        })
        VisualsTab:CreateButtonRow({
            { Name = "Morph into username", Callback = function()
                task.spawn(function()
                    local name = typedName
                    if not name or name == "" then morphNotify("Player Morph", "Enter a username first.") return end
                    local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
                    if not ok or not id then morphNotify("Player Morph", "User not found.") return end
                    local done, why = applyUser(id)
                    morphNotify("Player Morph", done and ("Morphed into " .. name) or (why or "Morph failed."))
                end)
            end },
            { Name = "Reset avatar", Style = "Secondary", Callback = doReset },
        })
        VisualsTab:CreateDivider()
        VisualsTab:CreateDropdown({
            Name = "Select player", Placeholder = "In this server", Options = {},
            Dynamic = function()
                local list = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then table.insert(list, p.Name) end
                end
                table.sort(list)
                return list
            end,
            Callback = function(v) pickedPlayer = v end,
        })
        VisualsTab:CreateButtonRow({
            { Name = "Morph into player", Callback = function()
                task.spawn(function()
                    local plr = pickedPlayer and Players:FindFirstChild(pickedPlayer)
                    if not plr then morphNotify("Player Morph", "Pick a player first.") return end
                    local done, why = applyUser(plr.UserId)
                    morphNotify("Player Morph", done and ("Morphed into " .. plr.Name) or (why or "Morph failed."))
                end)
            end },
            { Name = "Reset avatar", Style = "Secondary", Callback = doReset },
        })
    end

    PrivacyTab:CreateSection("Device Spoofer")
    PrivacyTab:CreateToggle({
        Name = "Device spoofer", Flag = "bytewtf_dev", CurrentValue = s.Misc.DeviceSpoofer,
        Callback = function(v) s.Misc.DeviceSpoofer = v; SpoofDevice() end,
    })
    PrivacyTab:CreateDropdown({
        Name = "Device", Options = { "PC", "Mobile", "Gamepad" },
        CurrentValue = s.Misc.Device, Flag = "bytewtf_dev_sel",
        Callback = function(v) s.Misc.Device = v; SpoofDevice() end,
    })

    PrivacyTab:CreateSection("Logo Changer")
    for _, n in ipairs(LogoNames) do
        PrivacyTab:CreateToggle({
            Name = n .. " logo", Desc = "Shows the " .. n .. " icon on your own nametag (only you see it).",
            Flag = "bytewtf_logo_" .. n:lower(), CurrentValue = logoDefault(n),
            Callback = function(v) applyLogo(n, v) end,
        })
    end
    PrivacyTab:CreateButton({
        Name = "Reset logos",
        Callback = function() resetLogos() end,
    })

    PrivacyTab:CreateSection("Ball Changer")
    PrivacyTab:CreateDropdown({
        Name = "Select ball", Options = #BallNames > 0 and BallNames or { "None" },
        CurrentValue = s.BallChanger.SelectedBall, Flag = "bytewtf_ball_sel",
        Callback = function(v)
            s.BallChanger.SelectedBall = v
            s.BallChanger.CurrentBall = v
            if s.BallChanger.Enabled then pcall(applyBallChanger) end
        end,
    })
    PrivacyTab:CreateToggle({
        Name = "Enable ball changer", Flag = "bytewtf_ball",
        CurrentValue = s.BallChanger.Enabled,
        Callback = function(v)
            s.BallChanger.Enabled = v
            if v then pcall(applyBallChanger) else pcall(resetBallChanger) end
        end,
    })
    PrivacyTab:CreateButton({
        Name = "Reset ball",
        Callback = function()
            s.BallChanger.Enabled = false
            s.BallChanger.SelectedBall = "ForceField"
            s.BallChanger.CurrentBall = "ForceField"
            pcall(resetBallChanger)
        end,
    })

    PrivacyTab:CreateSection("Trail Spoofer")
    PrivacyTab:CreateDropdown({
        Name = "Select trail", Options = #TrailNames > 0 and TrailNames or { "None" },
        CurrentValue = s.TrailSpoofer.SelectedTrail, Flag = "bytewtf_trail_sel",
        Callback = function(v)
            s.TrailSpoofer.SelectedTrail = v
            s.TrailSpoofer.CurrentTrail = v
            if s.TrailSpoofer.Enabled then pcall(applyTrailSpoofer) end
        end,
    })
    PrivacyTab:CreateToggle({
        Name = "Enable trail spoofer", Flag = "bytewtf_trail",
        CurrentValue = s.TrailSpoofer.Enabled,
        Callback = function(v)
            s.TrailSpoofer.Enabled = v
            if v then pcall(applyTrailSpoofer) else pcall(resetTrailSpoofer) end
        end,
    })
    PrivacyTab:CreateButton({
        Name = "Reset trail",
        Callback = function()
            s.TrailSpoofer.Enabled = false
            s.TrailSpoofer.SelectedTrail = "None"
            s.TrailSpoofer.CurrentTrail = "None"
            pcall(resetTrailSpoofer)
        end,
    })

    PrivacyTab:CreateSection("Ball Aura Spoofer")
    PrivacyTab:CreateDropdown({
        Name = "Select aura", Options = #AuraNames > 0 and AuraNames or { "None" },
        CurrentValue = s.BallAura.SelectedAura, Flag = "bytewtf_aura_sel",
        Callback = function(v)
            s.BallAura.SelectedAura = v
            s.BallAura.CurrentAura = v
            if s.BallAura.Enabled then pcall(applyBallAura) end
        end,
    })
    PrivacyTab:CreateToggle({
        Name = "Enable ball aura spoofer", Flag = "bytewtf_aura",
        CurrentValue = s.BallAura.Enabled,
        Callback = function(v)
            s.BallAura.Enabled = v
            if v then pcall(applyBallAura) else pcall(resetBallAura) end
        end,
    })
    PrivacyTab:CreateButton({
        Name = "Reset ball aura",
        Callback = function()
            s.BallAura.Enabled = false
            s.BallAura.SelectedAura = "None"
            s.BallAura.CurrentAura = "None"
            pcall(resetBallAura)
        end,
    })

    UtilityTab:CreateSection("Anti Moderator")
    UtilityTab:CreateToggle({
        Name = "Anti moderator", Desc = "Notifies when a moderator is in the server.",
        Flag = "bytewtf_mod", CurrentValue = s.Misc.AntiModerator,
        Callback = function(v)
            s.Misc.AntiModerator = v
            if v then startAntiMod() else stopAntiMod() end
        end,
    })

    UtilityTab:CreateSection("Config Saver")
    local ConfigName = "default"
    UtilityTab:CreateInput({
        Name = "Config name", Placeholder = "default",
        CurrentValue = "default", Flag = "bytewtf_cfg_name",
        Callback = function(v) ConfigName = (v ~= "") and v or "default" end,
    })
    UtilityTab:CreateButton({
        Name = "Save config",
        Callback = function()
            local ok = pcall(function() Window:SaveConfig(ConfigName) end)
            Notify({ title = "Config", content = ok and ("Saved: " .. ConfigName) or "Save failed.", duration = 3 })
        end,
    })
    UtilityTab:CreateButton({
        Name = "Load config",
        Callback = function()
            local ok = pcall(function() Window:LoadConfig(ConfigName) end)
            Notify({ title = "Config", content = ok and ("Loaded: " .. ConfigName) or "Load failed.", duration = 3 })
        end,
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
    setMagV2 = function(on)
        s.MagV2.Enabled = (on == nil) and (not s.MagV2.Enabled) or on
        if s.MagV2.Enabled then enableMagV2() else disableMagV2() end
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
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == s.MagV2.Keybind then setMagV2() end
    end)

    if isMobile then
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "Byte.WTFMobile"
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
        Panel.Size = UDim2.fromOffset(52, 320)
        Panel.Position = UDim2.new(1, -64, 0.5, -160)
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
            Button.BackgroundColor3 = isOn and Color3.fromRGB(242, 140, 62) or Color3.fromRGB(22, 14, 36)
            Button.BackgroundTransparency = 0.05
            Button.Text = label
            Button.TextColor3 = isOn and Color3.fromRGB(24, 10, 40) or Color3.fromRGB(242, 232, 255)
            Button.TextSize = 12
            Button.Font = Enum.Font.GothamBold
            Button.AutoButtonColor = false
            Button.LayoutOrder = order
            Button.Parent = Panel
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(1, 0)
            Corner.Parent = Button
            local Stroke = Instance.new("UIStroke")
            Stroke.Color = isOn and Color3.fromRGB(255, 185, 115) or Color3.fromRGB(92, 52, 132)
            Stroke.Thickness = 1.2
            Stroke.Transparency = 0.15
            Stroke.Parent = Button
            Button.MouseButton1Click:Connect(onClick)
            return Button, Stroke
        end

        local Aim, AimS = makeButton("Aim", 1, function() setAural() end, s.Shooting.AuralEnabled)
        local Guard, GuardS = makeButton("Guard", 2, function() setGuard() end, s.Defending.AutoGuard)
        local Mag, MagS = makeButton("Mag", 3, function() setMagnet() end, s.Ball.BallMags)
        local MagV2, MagV2S = makeButton("MagV2", 4, function() setMagV2() end, s.MagV2.Enabled)
        local Reach, ReachS = makeButton("Reach", 5, function() setReach() end, s.Ball.BallReach)
        local TPW, TPWS = makeButton("TPWalk", 6, function() setTPWalk() end, s.TPWalk.Enabled)

        local function paint(btn, stroke, on)
            btn.BackgroundColor3 = on and Color3.fromRGB(242, 140, 62) or Color3.fromRGB(22, 14, 36)
            btn.TextColor3 = on and Color3.fromRGB(24, 10, 40) or Color3.fromRGB(242, 232, 255)
            stroke.Color = on and Color3.fromRGB(255, 185, 115) or Color3.fromRGB(92, 52, 132)
        end

        MobileRefresh = function()
            paint(Aim, AimS, s.Shooting.AuralEnabled)
            paint(Guard, GuardS, s.Defending.AutoGuard)
            paint(Mag, MagS, s.Ball.BallMags)
            paint(MagV2, MagV2S, s.MagV2.Enabled)
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
        pcall(disableMagV2)
        pcall(disableReach)
        pcall(disableTPWalk)
        pcall(hvhResetAll)
        pcall(hvhStop)
        pcall(resetBallChanger)
        pcall(resetTrailSpoofer)
        pcall(resetBallAura)
        pcall(resetGoalEffect)
        pcall(resetCourtSpoofer)
        pcall(stopAntiMod)
        pcall(baDisable)
        pcall(resetLogos)
        pcall(function() setShotIndicator(false) end)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end)
end
