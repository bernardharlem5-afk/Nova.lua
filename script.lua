-- ===== LOAD MUSIC =====
-- Paste a Roblox audio ID (numbers only, keep the quotes) to play it when the UI finishes loading.
-- Leave it as "0" for no music.
local LOAD_MUSIC_ID     = "0"
local LOAD_MUSIC_VOLUME = 0.6

-- ============================================================
-- PHANTOMDUELS UI  (drop-in replacement for the Airflow API)
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
        Window    = Color3.fromRGB(11, 11, 13),
        TitleBar  = Color3.fromRGB(9, 9, 11),
        Panel     = Color3.fromRGB(15, 15, 18),
        Field     = Color3.fromRGB(21, 21, 25),
        Stroke    = Color3.fromRGB(36, 36, 42),
        StrokeLt  = Color3.fromRGB(54, 54, 62),
        Text      = Color3.fromRGB(236, 236, 240),
        Muted     = Color3.fromRGB(128, 128, 138),
        Header    = Color3.fromRGB(150, 150, 160),
        Accent    = Color3.fromRGB(236, 236, 240),
        AccentDk  = Color3.fromRGB(196, 196, 204),
        ToggleOn  = Color3.fromRGB(232, 232, 236),
        ToggleOff = Color3.fromRGB(44, 44, 50),
        TabOn     = Color3.fromRGB(23, 23, 28),
        TabOnStr  = Color3.fromRGB(66, 66, 75),
        BtnDark   = Color3.fromRGB(8, 8, 10),
        SliderTrack = Color3.fromRGB(40, 40, 46),
        LoadTrack   = Color3.fromRGB(30, 30, 36),
        KnobOff     = Color3.fromRGB(118, 118, 128),
        TabText     = Color3.fromRGB(190, 190, 198),
        Placeholder = Color3.fromRGB(96, 96, 106),
        AccentHover = Color3.fromRGB(250, 250, 252),
        BtnHover    = Color3.fromRGB(32, 32, 38),
        Title       = Color3.fromRGB(255, 255, 253),
        TabSelText  = Color3.fromRGB(255, 254, 255),
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
    local LOGO_B64 = "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"
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
            if makefolder and isfolder and not isfolder("PhantomDuels") then makefolder("PhantomDuels") end
            writefile("PhantomDuels/pd_logo.png", b64decode(LOGO_B64))
            return gca("PhantomDuels/pd_logo.png")
        end)
        logoAsset = (ok and res) or false
        return logoAsset or nil
    end


    -- ============================================================
    -- THEME ENGINE
    -- Every colour in the UI comes from the palette table `C`.
    -- Switching a theme rewrites C, then recolours everything that
    -- already exists (matching old palette colour -> new one).
    -- ============================================================
    local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
    local function rgbOf(c) return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) end
    local function ckey(c) local r, g, b = rgbOf(c); return r * 65536 + g * 256 + b end
    local function mix(a, b, t) return a:Lerp(b, t) end
    local function shift(c, dr, dg, db)
        local r, g, b = rgbOf(c)
        return Color3.fromRGB(math.clamp(r + dr, 0, 255), math.clamp(g + dg, 0, 255), math.clamp(b + db, 0, 255))
    end
    local function copyT(t) local n = {} for k, v in pairs(t) do n[k] = v end return n end
    local function toHex(c) local r, g, b = rgbOf(c); return string.format("#%02X%02X%02X", r, g, b) end
    local function parseHex(str)
        str = (tostring(str or ""):gsub("%s", "")):gsub("^#", "")
        if #str == 3 then str = str:gsub(".", function(ch) return ch .. ch end) end
        if not str:match("^%x%x%x%x%x%x$") then return nil end
        return Color3.fromRGB(tonumber(str:sub(1, 2), 16), tonumber(str:sub(3, 4), 16), tonumber(str:sub(5, 6), 16))
    end

    -- guarantee every palette colour is unique so old->new mapping is never ambiguous
    local function uniq(p)
        local used = { [ckey(WHITE)] = true }
        local keys = {}
        for k in pairs(p) do keys[#keys + 1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local r, g, b = rgbOf(p[k])
            local guard = 0
            while used[r * 65536 + g * 256 + b] and guard < 600 do
                guard += 1
                if b > 0 then b -= 1 else g = (g + 1) % 256 end
            end
            used[r * 65536 + g * 256 + b] = true
            p[k] = Color3.fromRGB(r, g, b)
        end
        return p
    end

    local function neutrals(spec)
        local bg, flat = spec.bg, spec.flat
        local function S(dr, dg, db) if flat then return shift(bg, dr, dr, dr) end return shift(bg, dr, dg, db) end
        return {
            Window = bg, TitleBar = S(2, 2, 3), Panel = S(3, 3, 4), Field = S(10, 10, 13),
            Stroke = S(25, 25, 31), StrokeLt = S(37, 37, 46), ToggleOff = S(27, 27, 33),
            SliderTrack = S(25, 25, 32), LoadTrack = S(21, 21, 27), BtnHover = S(19, 19, 24),
            Text = spec.text or Color3.fromRGB(228, 228, 234),
            Muted = mix(bg, WHITE, 0.45), Header = mix(bg, WHITE, 0.51), KnobOff = mix(bg, WHITE, 0.58),
            TabText = mix(bg, WHITE, 0.78), Placeholder = mix(bg, WHITE, 0.38),
            Title = Color3.fromRGB(255, 255, 253), TabSelText = Color3.fromRGB(255, 254, 255),
        }
    end

    local function accentize(p, a, light)
        local bg = p.Window
        p.Accent      = a
        p.AccentDk    = light and mix(a, BLACK, 0.35) or mix(a, bg, 0.5)
        p.ToggleOn    = light and a or mix(a, bg, 0.3)
        p.TabOn       = mix(bg, a, 0.22)
        p.TabOnStr    = mix(bg, a, light and 0.45 or 0.4)
        p.BtnDark     = light and WHITE or mix(a, BLACK, 0.85)
        p.AccentHover = light and mix(a, BLACK, 0.12) or mix(a, WHITE, 0.17)
    end

    local DefaultPalette = copyT(C)
    local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

    local ThemeOrder = {
        "Default", "Midnight", "Crimson", "Emerald", "Ocean", "Sunset", "Rose",
        "Amethyst", "Cyber Yellow", "Mono", "Dracula", "Nord", "Light",
    }
    local Specs = {
        ["Default"]      = { palette = DefaultPalette },
        ["Midnight"]     = { bg = rgb(8, 9, 18),    accent = rgb(112, 128, 255) },
        ["Crimson"]      = { bg = rgb(16, 11, 12),  accent = rgb(235, 64, 82) },
        ["Emerald"]      = { bg = rgb(10, 15, 13),  accent = rgb(46, 204, 133) },
        ["Ocean"]        = { bg = rgb(9, 14, 19),   accent = rgb(30, 190, 210) },
        ["Sunset"]       = { bg = rgb(17, 12, 10),  accent = rgb(255, 140, 60) },
        ["Rose"]         = { bg = rgb(17, 11, 15),  accent = rgb(255, 105, 160) },
        ["Amethyst"]     = { bg = rgb(14, 11, 19),  accent = rgb(168, 110, 255) },
        ["Cyber Yellow"] = { bg = rgb(12, 12, 10),  accent = rgb(252, 238, 10) },
        ["Mono"]         = { bg = rgb(14, 14, 14),  accent = rgb(205, 205, 205), flat = true },
        ["Dracula"]      = { bg = rgb(24, 25, 33),  accent = rgb(189, 147, 249), text = rgb(248, 248, 242) },
        ["Nord"]         = { bg = rgb(30, 34, 42),  accent = rgb(136, 192, 208), text = rgb(216, 222, 233) },
        ["Light"] = {
            bg = rgb(238, 240, 245), accent = rgb(46, 108, 232), light = true,
            fixed = {
                TitleBar = rgb(246, 247, 251), Panel = rgb(250, 251, 254), Field = rgb(230, 233, 240),
                Stroke = rgb(208, 213, 224), StrokeLt = rgb(190, 197, 212), Text = rgb(28, 31, 40),
                Muted = rgb(108, 115, 132), Header = rgb(88, 96, 114), ToggleOff = rgb(198, 203, 214),
                SliderTrack = rgb(205, 210, 221), LoadTrack = rgb(214, 218, 228), KnobOff = rgb(146, 153, 168),
                TabText = rgb(62, 68, 84), Placeholder = rgb(138, 145, 160), BtnHover = rgb(220, 224, 233),
                Title = rgb(20, 22, 32), TabSelText = rgb(18, 26, 48),
            },
        },
    }

    local function build(spec, accentOverride)
        local p = spec.palette and copyT(spec.palette) or neutrals(spec)
        for k, v in pairs(spec.fixed or {}) do p[k] = v end
        local acc = accentOverride or ((not spec.palette) and spec.accent) or nil
        if acc then accentize(p, acc, spec.light) end
        return uniq(p)
    end

    local Active = { name = "Default", accent = nil }
    Lib._guis = {}

    local function recolor(gui, map)
        local function fix(c) return map[ckey(c)] end
        local function seq(cs)
            local pts, changed = {}, false
            for i, kp in ipairs(cs.Keypoints) do
                local n = fix(kp.Value)
                if n then changed = true end
                pts[i] = ColorSequenceKeypoint.new(kp.Time, n or kp.Value)
            end
            return changed and ColorSequence.new(pts) or nil
        end
        for _, d in ipairs(gui:GetDescendants()) do
            pcall(function()
                if d:IsA("GuiObject") then
                    local n = fix(d.BackgroundColor3); if n then d.BackgroundColor3 = n end
                    if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                        n = fix(d.TextColor3); if n then d.TextColor3 = n end
                        if d:IsA("TextBox") then n = fix(d.PlaceholderColor3); if n then d.PlaceholderColor3 = n end end
                    elseif d:IsA("ScrollingFrame") then
                        n = fix(d.ScrollBarImageColor3); if n then d.ScrollBarImageColor3 = n end
                    elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                        n = fix(d.ImageColor3); if n then d.ImageColor3 = n end
                    end
                elseif d:IsA("UIStroke") then
                    local n = fix(d.Color); if n then d.Color = n end
                elseif d:IsA("UIGradient") then
                    local n = seq(d.Color); if n then d.Color = n end
                end
            end)
        end
    end

    local function applyPalette(newP)
        local map = {}
        for k, old in pairs(C) do
            local nv = newP[k]
            if nv and ckey(old) ~= ckey(nv) then map[ckey(old)] = nv end
        end
        for k, v in pairs(newP) do C[k] = v end
        for i = #Lib._guis, 1, -1 do
            local g = Lib._guis[i]
            if g.Parent then recolor(g, map) else table.remove(Lib._guis, i) end
        end
    end

    local function persist()
        pcall(function()
            if not (writefile and Lib._folder) then return end
            if makefolder and isfolder and not isfolder(Lib._folder) then makefolder(Lib._folder) end
            writefile(Lib._folder .. "/theme.json", HttpService:JSONEncode({
                name = Active.name, accent = Active.accent and toHex(Active.accent) or nil,
            }))
        end)
    end

    function Lib:GetThemeNames() return ThemeOrder end
    function Lib:GetTheme() return Active.name, Active.accent end
    function Lib:SetTheme(name)
        local spec = Specs[name]
        if not spec then return false end
        Active.name, Active.accent = name, nil
        applyPalette(build(spec))
        persist()
        return true
    end
    -- color: Color3, hex string, or nil (nil = remove accent override)
    function Lib:SetAccent(color)
        if type(color) == "string" then
            if color:gsub("%s", "") == "" then color = nil else
                color = parseHex(color)
                if not color then return false end
            end
        end
        Active.accent = color
        applyPalette(build(Specs[Active.name], color))
        persist()
        return true
    end
    function Lib:ResetTheme()
        Active.name, Active.accent = "Default", nil
        applyPalette(build(Specs["Default"]))
        persist()
    end
    function Lib:LoadSavedTheme()
        pcall(function()
            if not (isfile and readfile and Lib._folder) then return end
            local path = Lib._folder .. "/theme.json"
            if not isfile(path) then return end
            local d = HttpService:JSONDecode(readfile(path))
            local spec = d and Specs[d.name]
            if not spec then return end
            Active.name = d.name
            Active.accent = d.accent and parseHex(d.accent) or nil
            applyPalette(build(spec, Active.accent))
        end)
    end
    Lib.ToHex, Lib.ParseHex = toHex, parseHex

    function Lib:CreateWindow(opts)
        opts = opts or {}
        local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
        local Window = { Flags = {} }
        local flags = Window.Flags

        local gui = new("ScreenGui", {
            Name = "PhantomDuels_" .. tostring(math.random(1000, 9999)),
            ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
        })
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
        gui.Parent = getGuiParent()
        Window.Gui = gui
        table.insert(Lib._guis, gui)

        local W, H = 880, 560
        local SB, HD = 216, 66 -- sidebar width, header height
        local scaleVal = 1
        local function calcScale()
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            scaleVal = math.clamp(math.min(vp.X / (W + 40), vp.Y / (H + 40)), 0.45, 1)
            return scaleVal
        end

        local root = new("Frame", {
            Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(W, H), BackgroundColor3 = C.Window, BorderSizePixel = 0, Parent = gui,
        }, { corner(14), stroke(C.Stroke, 1) })
        local uiScale = new("UIScale", { Scale = calcScale(), Parent = root })
        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() uiScale.Scale = calcScale() end)
        end

        -- ===== left sidebar =====
        local sidebar = new("Frame", { Size = UDim2.new(0, SB, 1, 0), BackgroundColor3 = C.TitleBar, BorderSizePixel = 0, Parent = root }, { corner(14) })
        new("Frame", { Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 14, 1, 0), BackgroundColor3 = C.TitleBar, BorderSizePixel = 0, Parent = sidebar })
        new("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.Stroke, BorderSizePixel = 0, ZIndex = 2, Parent = sidebar })

        local brandZone = new("Frame", { Size = UDim2.new(1, 0, 0, 90), BackgroundTransparency = 1, Parent = sidebar })
        local logo = getLogo()
        local brand = new("Frame", {
            Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0, ClipsDescendants = true, Parent = sidebar,
        }, { corner(14), stroke(C.Stroke) })
        if logo then
            new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = logo, ScaleType = Enum.ScaleType.Fit, Parent = brand }, { corner(14) })
        else
            text(brand, { Text = "B", TextSize = 26, FontFace = font(Enum.FontWeight.Bold), TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1) })
        end
        text(sidebar, { Text = opts.Name or "PhantomDuels", TextSize = 18, FontFace = font(Enum.FontWeight.Bold), TextColor3 = C.Title, Position = UDim2.fromOffset(82, 21), Size = UDim2.new(1, -92, 0, 24), TextXAlignment = Enum.TextXAlignment.Left })
        text(sidebar, { Text = opts.LoadingSubtitle or "PhantomDuels On Top", TextSize = 12, TextColor3 = C.Muted, Position = UDim2.fromOffset(82, 46), Size = UDim2.new(1, -92, 0, 18), TextXAlignment = Enum.TextXAlignment.Left })

        local tabBar = new("ScrollingFrame", {
            Position = UDim2.fromOffset(12, 96), Size = UDim2.new(1, -24, 1, -178), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, Parent = sidebar,
        }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

        -- user card (bottom of sidebar)
        do
            local card = new("Frame", {
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(1, -24, 0, 60),
                BackgroundColor3 = C.Panel, BorderSizePixel = 0, Parent = sidebar,
            }, { corner(12), stroke(C.Stroke) })
            local av = new("ImageLabel", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = C.Field, BorderSizePixel = 0, Parent = card }, { corner(18) })
            task.spawn(function()
                local ok, img = pcall(function()
                    return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
                if ok and img and av.Parent then av.Image = img end
            end)
            text(card, { Text = LP.DisplayName, TextSize = 13, FontFace = font(Enum.FontWeight.Bold), Position = UDim2.fromOffset(58, 12), Size = UDim2.new(1, -66, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
            text(card, { Text = "@" .. LP.Name, TextSize = 11, TextColor3 = C.Muted, Position = UDim2.fromOffset(58, 31), Size = UDim2.new(1, -66, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
        end

        -- ===== header (page title, search, minimize, close) =====
        local header = new("Frame", { Position = UDim2.fromOffset(SB, 0), Size = UDim2.new(1, -SB, 0, HD), BackgroundTransparency = 1, Parent = root })
        local headerTitle = text(header, { Text = "", TextSize = 20, FontFace = font(Enum.FontWeight.Bold), TextColor3 = C.Title, Position = UDim2.fromOffset(26, 0), Size = UDim2.new(0, 200, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })

        local function winBtn(offsetRight)
            local b = new("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -offsetRight, 0.5, 0), Size = UDim2.fromOffset(38, 38),
                BackgroundColor3 = C.Field, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = header,
            }, { corner(10), stroke(C.Stroke) })
            b.MouseEnter:Connect(function() tween(b, 0.1, { BackgroundColor3 = C.BtnHover }) end)
            b.MouseLeave:Connect(function() tween(b, 0.1, { BackgroundColor3 = C.Field }) end)
            return b
        end
        local closeB = winBtn(20)
        local minB = winBtn(66)
        new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2), BackgroundColor3 = C.Header, BorderSizePixel = 0, ZIndex = 6, Parent = minB }, { corner(1) })
        for _, r in ipairs({ 45, -45 }) do
            new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(15, 2), Rotation = r, BackgroundColor3 = C.Header, BorderSizePixel = 0, ZIndex = 6, Parent = closeB }, { corner(1) })
        end

        -- dragging (header + logo area)
        do
            local dragging, dragStart, startPos
            local function bind(h)
                h.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging, dragStart, startPos = true, i.Position, root.Position
                    end
                end)
            end
            bind(header); bind(brandZone)
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

        local content = new("Frame", {
            Position = UDim2.fromOffset(SB + 22, HD + 6), Size = UDim2.new(1, -(SB + 44), 1, -(HD + 26)), BackgroundTransparency = 1, Parent = root,
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
        local function hideUI() if not uiReady then return end closePopup(); root.Visible = false end

        -- floating circle that reopens the menu (shown whenever the window is hidden)
        local openBtn = new("TextButton", {
            Size = UDim2.fromOffset(50, 50), Position = UDim2.new(0, 18, 0.5, -25), BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            Text = "", AutoButtonColor = false, Visible = false, ZIndex = 60, ClipsDescendants = true, Parent = gui,
        }, { corner(25), stroke(C.StrokeLt, 1.5) })
        if logo then
            new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = logo, ScaleType = Enum.ScaleType.Fit, ZIndex = 61, Parent = openBtn }, { corner(25) })
        else
            text(openBtn, { Text = "B", TextSize = 20, FontFace = font(Enum.FontWeight.Bold), TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), ZIndex = 61 })
        end
        local function syncOpenBtn() openBtn.Visible = uiReady and not root.Visible end
        root:GetPropertyChangedSignal("Visible"):Connect(syncOpenBtn)
        syncOpenBtn()
        do -- click opens, drag moves
            local down, moved, startIn, startPos
            openBtn.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    down, moved, startIn, startPos = true, false, i.Position, openBtn.Position
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if down and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local d = i.Position - startIn
                    if moved or d.Magnitude > 6 then
                        moved = true
                        openBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                    end
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if down and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                    down = false
                    if not moved then toggleUI() end
                end
            end)
        end

        local function playLoadMusic()
            local id = tostring(LOAD_MUSIC_ID):gsub("%D", "")
            if id == "" or tonumber(id) == 0 then return end
            pcall(function()
                local snd = Instance.new("Sound")
                snd.Name = "PhantomDuels_LoadMusic"
                snd.SoundId = "rbxassetid://" .. id
                snd.Volume = LOAD_MUSIC_VOLUME
                snd.Looped = false
                snd.Parent = game:GetService("SoundService")
                snd.Ended:Connect(function() snd:Destroy() end)
                snd:Play()
            end)
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
            text(loader, { Text = opts.Name or "PhantomDuels", TextSize = 22, FontFace = font(Enum.FontWeight.Bold), TextColor3 = C.Title, Position = UDim2.fromOffset(0, 102 + yOff), Size = UDim2.new(1, 0, 0, 28) })
            text(loader, { Text = opts.LoadingSubtitle or "Loading", TextSize = 13, TextColor3 = C.Muted, Position = UDim2.fromOffset(0, 132 + yOff), Size = UDim2.new(1, 0, 0, 20) })
            local barTrack = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 174 + yOff), Size = UDim2.fromOffset(280, 6), BackgroundColor3 = C.LoadTrack, BorderSizePixel = 0, Parent = loader }, { corner(3) })
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
                playLoadMusic()
            end)
        else
            playLoadMusic()
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
        local folder = cfgCfg.FolderName or "PhantomDuels"
        Lib._folder = folder
        Lib:LoadSavedTheme() -- re-applies the last theme the user picked
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
            headerTitle.Text = t.Name or ""
            for _, o in ipairs(tabs) do
                local on = (o == t)
                o.Page.Visible = on
                tween(o.Btn, 0.12, { BackgroundTransparency = on and 0 or 1, TextColor3 = on and C.TabSelText or C.TabText })
                tween(o.BtnStroke, 0.12, { Transparency = on and 0 or 1 })
            end
        end

        function Window:CreateTab(p)
            p = p or {}
            local Tab = { Panels = {}, Order = 0 }
            Tab.Name = p.Name or "Tab"
            local btn = new("TextButton", {
                Text = p.Name or "Tab", Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = C.TabOn, BackgroundTransparency = 1, TextColor3 = C.TabText, TextSize = 14, FontFace = font(Enum.FontWeight.Medium),
                AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = #tabs + 1, Parent = tabBar,
            }, { corner(10), pad(18, 0, 12, 0) })
            local bs = stroke(C.TabOnStr); bs.Transparency = 1; bs.Parent = btn
            Tab.Btn, Tab.BtnStroke = btn, bs
            btn.MouseEnter:Connect(function() if activeTab ~= Tab then tween(btn, 0.1, { TextColor3 = C.Text }) end end)
            btn.MouseLeave:Connect(function() if activeTab ~= Tab then tween(btn, 0.1, { TextColor3 = C.TabText }) end end)

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
                }, { corner(12), stroke(C.Stroke), pad(20, 20, 20, 20), new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }) })
                text(f, { Text = name, TextSize = 15, FontFace = font(Enum.FontWeight.Bold), TextColor3 = C.Text, Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 })
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
                local checkbox = (o.Style == "Checkbox") or o.Checkbox == true
                local hasDesc = o.Desc and o.Desc ~= ""
                local h = hasDesc and 54 or 34
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Toggle", Position = UDim2.fromOffset(0, hasDesc and 2 or 0), Size = UDim2.new(1, -70, 0, hasDesc and 22 or h), TextXAlignment = Enum.TextXAlignment.Left })
                if hasDesc then
                    text(row, { Text = o.Desc, TextSize = 12, TextColor3 = C.Muted, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, -70, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
                end
                local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row })
                local state = o.CurrentValue == true
                local obj = {}
                local render
                if checkbox then
                    local box = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = C.ToggleOff, BorderSizePixel = 0, Parent = row }, { corner(6), stroke(C.StrokeLt) })
                    local c1 = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(8, 13), Size = UDim2.fromOffset(6, 2), Rotation = 45, BackgroundColor3 = C.BtnDark, BorderSizePixel = 0, Parent = box })
                    local c2 = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(13, 11), Size = UDim2.fromOffset(11, 2), Rotation = -45, BackgroundColor3 = C.BtnDark, BorderSizePixel = 0, Parent = box })
                    render = function(animate)
                        c1.Visible, c2.Visible = state, state
                        local col = state and C.ToggleOn or C.ToggleOff
                        if animate then tween(box, 0.12, { BackgroundColor3 = col }) else box.BackgroundColor3 = col end
                    end
                else
                    local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(44, 24), BackgroundColor3 = C.ToggleOff, BorderSizePixel = 0, Parent = row }, { corner(12) })
                    local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = C.KnobOff, BorderSizePixel = 0, Parent = track }, { corner(8) })
                    render = function(animate)
                        local tp = { BackgroundColor3 = state and C.ToggleOn or C.ToggleOff }
                        local kp = { Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 4, 0.5, 0), BackgroundColor3 = state and C.BtnDark or C.KnobOff }
                        if animate then tween(track, 0.15, tp); tween(knob, 0.15, kp)
                        else for k, v in pairs(tp) do track[k] = v end for k, v in pairs(kp) do knob[k] = v end end
                    end
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
                local track = new("Frame", { Position = UDim2.new(0, 0, 0, 35), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = C.SliderTrack, BorderSizePixel = 0, Parent = row }, { corner(2) })
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
                local h = 68
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Dropdown", Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left })
                local box = new("TextButton", {
                    Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 38),
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
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(88, 30),
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
                    PlaceholderText = o.Placeholder or "", PlaceholderColor3 = C.Placeholder, TextColor3 = C.Text,
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
                -- read colours at hover time so buttons follow theme changes
                btn.MouseEnter:Connect(function() tween(btn, 0.1, { BackgroundColor3 = primary and C.AccentHover or C.BtnHover }) end)
                btn.MouseLeave:Connect(function() tween(btn, 0.1, { BackgroundColor3 = primary and C.Accent or C.Field }) end)
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
            local box = new("TextBox", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -114, 0.5, 0), Size = UDim2.fromOffset(300, 38),
                BackgroundColor3 = C.Field, Text = "", PlaceholderText = "Search Functions...", ZIndex = 6,
                PlaceholderColor3 = C.Placeholder, TextColor3 = C.Text, TextSize = 13, FontFace = font(),
                ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
            }, { corner(10), stroke(C.Stroke), pad(42, 0, 14, 0) })
            do -- magnifier icon drawn from frames
                local ic = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, -(114 + 300 - 15), 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, ZIndex = 7, Parent = header })
                new("Frame", { Size = UDim2.fromOffset(11, 11), BackgroundTransparency = 1, ZIndex = 7, Parent = ic }, { corner(6), stroke(C.Header, 1.5) })
                new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(12.5, 12.5), Size = UDim2.fromOffset(6, 2), Rotation = 45, BackgroundColor3 = C.Header, BorderSizePixel = 0, ZIndex = 7, Parent = ic }, { corner(1) })
            end

            local results = new("Frame", {
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -114, 0, 58), Size = UDim2.fromOffset(420, 0),
                BackgroundColor3 = C.Field, BorderSizePixel = 0, Visible = false, ZIndex = 40, ClipsDescendants = true, Parent = root,
            }, { corner(9), stroke(C.StrokeLt) })
            local list = new("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.StrokeLt,
                AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 41, Parent = results,
            }, { pad(6, 6, 6, 6), new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

            -- block everything behind the results while they're open
            results.Active = true
            list.Active = true
            local blocker = new("TextButton", {
                Position = UDim2.fromOffset(0, HD), Size = UDim2.new(1, 0, 1, -HD), BackgroundTransparency = 1, Text = "",
                AutoButtonColor = false, Active = true, Visible = false, ZIndex = 30, Parent = root,
            })
            blocker.MouseButton1Click:Connect(function() results.Visible = false; box:ReleaseFocus() end)
            results:GetPropertyChangedSignal("Visible"):Connect(function() blocker.Visible = results.Visible end)

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
                    b.Activated:Connect(function() jump(e) end)
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
                if enter and current[1] then jump(current[1]) end
            end)
        end

        -- minimize / close
        minB.MouseButton1Click:Connect(hideUI)
        closeB.MouseButton1Click:Connect(hideUI)


        -- ===== theme API + ready-made Theme tab =====
        function Window:SetTheme(n) return Lib:SetTheme(n) end
        function Window:SetAccent(c) return Lib:SetAccent(c) end
        function Window:ResetTheme() return Lib:ResetTheme() end
        function Window:GetTheme() return Lib:GetTheme() end

        function Window:CreateThemeTab(tabName)
            local Tab = Window:CreateTab({ Name = tabName or "Theme", Icon = "palette" })
            local function describe()
                local n, a = Lib:GetTheme()
                return "Active theme: " .. n .. (a and ("  (accent " .. Lib.ToHex(a) .. ")") or "")
            end

            -- left column: presets + reset
            Tab:CreateSection({ Name = "Themes", Column = "Left" })
            local status
            local accentBox
            local dd = Tab:CreateDropdown({
                Name = "Theme", Options = Lib:GetThemeNames(), CurrentValue = (Lib:GetTheme()),
                Callback = function(v)
                    if Lib:SetTheme(v) then
                        if accentBox then accentBox:Set("") end
                        if status then status:Set(describe()) end
                        Window:Notify({ title = "Theme", content = "Applied " .. tostring(v), duration = 2 })
                    end
                end,
            })
            status = Tab:CreateLabel({ Name = describe() })
            Tab:CreateButton({
                Name = "Reset Theme",
                Callback = function()
                    Lib:ResetTheme()
                    dd:Set("Default", true)
                    if accentBox then accentBox:Set("") end
                    status:Set(describe())
                    Window:Notify({ title = "Theme", content = "Reset to the default theme", duration = 2 })
                end,
            })

            -- right column: custom accent colour
            Tab:CreateSection({ Name = "Custom Accent", Column = "Right" })
            accentBox = Tab:CreateInput({
                Name = "Accent color (hex)", Placeholder = "#66AAFF", CurrentValue = "",
            })
            local function applyAccent(val)
                if Lib:SetAccent(val) then
                    status:Set(describe())
                    return true
                end
                Window:Notify({ title = "Theme", content = "Invalid hex color. Try something like #FF4466", duration = 3 })
                return false
            end
            Tab:CreateButtonRow({
                { Name = "Apply accent", Callback = function()
                    local v = accentBox:Get()
                    if (v:gsub("%s", "")) == "" then
                        Window:Notify({ title = "Theme", content = "Type a hex color first (e.g. #FF4466)", duration = 3 })
                        return
                    end
                    applyAccent(v)
                end },
                { Name = "Random", Style = "Secondary", Callback = function()
                    local c = Color3.fromHSV(math.random(), 0.55 + math.random() * 0.4, 1)
                    accentBox:Set(Lib.ToHex(c))
                    applyAccent(c)
                end },
            })
            Tab:CreateLabel({ Name = "Accent recolors buttons, sliders, toggles and highlights." })

            -- live preview so people can see what a theme does without leaving the tab
            Tab:CreateSection({ Name = "Preview", Column = "Left" })
            Tab:CreateToggle({ Name = "Preview toggle", Desc = "Just for showing the theme", CurrentValue = true })
            Tab:CreateSlider({ Name = "Preview slider", Range = { 0, 100 }, Increment = 1, CurrentValue = 60 })
            Tab:CreateButton({ Name = "Preview button", Style = "Secondary" })
            return Tab
        end

        return Window
    end

    return Lib
end)()
-- ### BLACKLIST SYSTEM ###
local BlacklistedIDs = {
    ["5913858916"] = true,
    -- Add more IDs here: ["ID_HERE"] = true,
}

if BlacklistedIDs[tostring(game.GameId)] or BlacklistedIDs[tostring(game.PlaceId)] then
    game:GetService("Players").LocalPlayer:Kick("Game Blacklisted")
    return
end
-- ########################

getgenv().Aimbot = {
    Status = true,
    Keybind  = 'C',
    Hitpart = 'HumanoidRootPart',
    ['Prediction'] = {
        X = 0.165,
        Y = 0.1,
    },
}

getgenv().Triggerbot = {
    Enabled = false,
    Keybind = 'O'
}

getgenv().ESP = {
    Enabled = false,
    Keybind = 'B',
}

getgenv().Fly = {
    Enabled = false,
    Keybind = 'V',
    Speed = 250
}

getgenv().Noclip = {
    Enabled = false,
    Keybind = 'Z'
}

getgenv().FakeMacro = {
    Enabled = false,
    Keybind = 'U',
    SpeedMultiplier = 20
}

getgenv().LoopKill = {
    Enabled = false,
    Keybind = 'L'
}

getgenv().Tornado = {
    Enabled = false,
    Keybind = 'T'
}

getgenv().Armor = {
    Keybind = 'K'
}

getgenv().Settings = {
    MinimizeKey = 'Y',
    IsVisible = true,
    Transparency = 0
}

getgenv().Visuals = {
    Tracers = {
        Enabled = false,
        Color = Color3.fromRGB(0, 170, 255),
        Thickness = 1,
        From = "Bottom"  -- Options: "Bottom", "Center", "Mouse"
    },
    Skeletons = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1
    },
    Chams = {
        Enabled = false,
        Color = Color3.fromRGB(0, 170, 255),
        Transparency = 0.5
    },
    HeadDots = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
        Size = 5,
        Filled = true
    },
    HealthBars = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
        Width = 5
    },
    DistanceText = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255)
    },
    WeaponText = {
        Enabled = false,
        Color = Color3.fromRGB(200, 200, 200)
    }
}


-- ============================================================
-- SERVICES / SHARED STATE
-- ============================================================
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local Workspace    = game:GetService("Workspace")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local TargetPlayer = nil
local SelectedPlayerForTP = nil

-- remove any old PhantomDuels window from a previous execution
pcall(function()
    for _, parent in ipairs({ game:GetService("CoreGui"), (gethui and gethui()) or nil }) do
        for _, g in ipairs(parent:GetChildren()) do
            if g.Name:sub(1, 13) == "PhantomDuels_" then g:Destroy() end
        end
    end
end)

-- ============================================================
-- FEATURE LOGIC (idempotent setters so UI + hotkeys stay in sync)
-- ============================================================
local Window -- assigned below
local T = {}  -- toggle objects by name, used to mirror hotkey changes into the UI

local function Notify(title, content)
    if Window then pcall(function() Window:Notify({ title = title, content = content, duration = 2.5 }) end) end
end
local function syncToggle(name, v)
    if T[name] then pcall(function() T[name]:Set(v) end) end
end

local function GetClosestPlayer()
    local ClosestDist, Closest = 1000, nil
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local Pos, Vis = Camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
            if Vis then
                local Dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(Pos.X, Pos.Y)).Magnitude
                if Dist < ClosestDist then ClosestDist = Dist Closest = v end
            end
        end
    end
    return Closest
end

local function setAimbot(on)
    if on then
        TargetPlayer = TargetPlayer or GetClosestPlayer()
        if not TargetPlayer then
            Notify("Aimbot", "No player on screen to lock onto.")
            syncToggle("Aimbot", false)
        end
    else
        TargetPlayer = nil
    end
    syncToggle("Aimbot", TargetPlayer ~= nil)
end

local function setFly(on)
    if on == getgenv().Fly.Enabled then return end
    getgenv().Fly.Enabled = on
    local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if on and Root then
        local BV = Root:FindFirstChild("phantomduels_FlyBV") or Instance.new("BodyVelocity")
        BV.Name = "phantomduels_FlyBV"
        BV.Parent = Root
        BV.MaxForce = Vector3.new(1e8, 1e8, 1e8)

        local BG = Root:FindFirstChild("phantomduels_FlyBG") or Instance.new("BodyGyro")
        BG.Name = "phantomduels_FlyBG"
        BG.Parent = Root
        BG.MaxTorque = Vector3.new(1e8, 1e8, 1e8)

        task.spawn(function()
            while getgenv().Fly.Enabled and Root.Parent do
                local Dir = Vector3.new(0, 0, 0)
                if UIS:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + Camera.CFrame.RightVector end
                BV.Velocity = Dir * getgenv().Fly.Speed
                BG.CFrame = Camera.CFrame
                RunService.RenderStepped:Wait()
            end
            if BV then BV:Destroy() end
            if BG then BG:Destroy() end
        end)
    end
    syncToggle("Fly", getgenv().Fly.Enabled)
end

local function setSimple(name, tbl, on)
    tbl.Enabled = on
    syncToggle(name, on)
end

local function setLoopKill(on)
    getgenv().LoopKill.Enabled = on
    if on then getgenv().Tornado.Enabled = false; syncToggle("Tornado", false) end
    syncToggle("Loop Kill", on)
end

local function setTornado(on)
    getgenv().Tornado.Enabled = on
    if on then getgenv().LoopKill.Enabled = false; syncToggle("Loop Kill", false) end
    syncToggle("Tornado", on)
end

local function GetArmor()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local shops = Workspace:FindFirstChild("Ignored") and Workspace.Ignored:FindFirstChild("Shop")
        if shops then
            for _, v in pairs(shops:GetChildren()) do
                if v.Name:find("Armor") and v:FindFirstChild("Head") and v:FindFirstChild("ClickDetector") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = v.Head.CFrame * CFrame.new(0, 3, 0)
                    task.wait(0.1)
                    fireclickdetector(v.ClickDetector)
                    return
                end
            end
        end
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-607, 21, -633)
    end
end

-- ============================================================
-- WINDOW
-- ============================================================
Window = Airflow:CreateWindow({
    Name = "PhantomDuels",
    LoadingSubtitle = "V7 Premier Edition",
    Theme = "FatalBlue",
    ToggleUIKeybind = tostring(getgenv().Settings.MinimizeKey),
    ConfigurationSaving = { Enabled = true, FolderName = "PhantomDuels", FileName = "PhantomDuels" },
})

local ExploitsTab = Window:CreateTab({ Name = "Exploits", Icon = "swords" })
local VisualsTab  = Window:CreateTab({ Name = "Visuals",  Icon = "eye" })
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings" })
local CreditsTab  = Window:CreateTab({ Name = "Credits",  Icon = "info" })
pcall(function() Window:CreateThemeTab() end)

-- helper: R/G/B sliders that write a Color3 into config[key]
local function AddColor(tab, label, cfg, key, flag)
    local function upd(ch, v)
        local c = cfg[key]
        local r, g, b = c.R * 255, c.G * 255, c.B * 255
        if ch == "R" then r = v elseif ch == "G" then g = v else b = v end
        cfg[key] = Color3.fromRGB(r, g, b)
    end
    local c0 = cfg[key]
    tab:CreateSlider({ Name = label .. " (R)", Range = { 0, 255 }, Increment = 1, CurrentValue = math.floor(c0.R * 255 + 0.5), Flag = flag .. "_r", Callback = function(v) upd("R", v) end })
    tab:CreateSlider({ Name = label .. " (G)", Range = { 0, 255 }, Increment = 1, CurrentValue = math.floor(c0.G * 255 + 0.5), Flag = flag .. "_g", Callback = function(v) upd("G", v) end })
    tab:CreateSlider({ Name = label .. " (B)", Range = { 0, 255 }, Increment = 1, CurrentValue = math.floor(c0.B * 255 + 0.5), Flag = flag .. "_b", Callback = function(v) upd("B", v) end })
end

local function AddBind(tab, label, tbl, key, flag)
    tab:CreateKeybind({
        Name = label, Flag = flag, CurrentValue = tbl[key],
        Callback = function(k) if typeof(k) == "EnumItem" then tbl[key] = k.Name end end,
    })
end

-- ===== EXPLOITS =====
ExploitsTab:CreateSection("Combat")
T["Aimbot"] = ExploitsTab:CreateToggle({
    Name = "Aimbot", Desc = "Locks camera to closest player", Flag = "ex_aimbot", CurrentValue = false,
    Callback = function(v) setAimbot(v) end,
})
T["Triggerbot"] = ExploitsTab:CreateToggle({
    Name = "Triggerbot", Desc = "Auto-clicks on player parts", Flag = "ex_trigger", CurrentValue = getgenv().Triggerbot.Enabled,
    Callback = function(v) getgenv().Triggerbot.Enabled = v end,
})
T["ESP"] = ExploitsTab:CreateToggle({
    Name = "ESP", Desc = "Highlights players with boxes", Flag = "ex_esp", CurrentValue = getgenv().ESP.Enabled,
    Callback = function(v) getgenv().ESP.Enabled = v end,
})

ExploitsTab:CreateSection("Movement")
T["Fly"] = ExploitsTab:CreateToggle({
    Name = "Fly", Desc = "Enables flying with WASD", Flag = "ex_fly", CurrentValue = false,
    Callback = function(v) setFly(v) end,
})
T["Noclip"] = ExploitsTab:CreateToggle({
    Name = "Noclip", Desc = "Walk through walls", Flag = "ex_noclip", CurrentValue = getgenv().Noclip.Enabled,
    Callback = function(v) getgenv().Noclip.Enabled = v end,
})
T["Fake Macro"] = ExploitsTab:CreateToggle({
    Name = "Fake Macro", Desc = "Boosts movement speed", Flag = "ex_macro", CurrentValue = getgenv().FakeMacro.Enabled,
    Callback = function(v) getgenv().FakeMacro.Enabled = v end,
})

ExploitsTab:CreateSection("Kill")
ExploitsTab:CreateDropdown({
    Name = "Target player", Placeholder = "Select a player", Flag = "ex_target",
    Options = {},
    Dynamic = function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(list, p.DisplayName) end
        end
        return list
    end,
    Callback = function(name)
        SelectedPlayerForTP = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.DisplayName == name then SelectedPlayerForTP = p break end
        end
    end,
})
T["Loop Kill"] = ExploitsTab:CreateToggle({
    Name = "Loop Kill", Desc = "Teleports to target repeatedly", Flag = "ex_loopkill", CurrentValue = false,
    Callback = function(v) setLoopKill(v) end,
})
T["Tornado"] = ExploitsTab:CreateToggle({
    Name = "Tornado", Desc = "Circles around target", Flag = "ex_tornado", CurrentValue = false,
    Callback = function(v) setTornado(v) end,
})

ExploitsTab:CreateSection("Utility")
ExploitsTab:CreateButton({ Name = "Buy Armor", Style = "Secondary", Callback = function() task.spawn(GetArmor) end })

-- ===== VISUALS =====
local V = getgenv().Visuals

VisualsTab:CreateSection("Tracers")
VisualsTab:CreateToggle({ Name = "Tracers", Desc = "Draws lines to players", Flag = "vis_tracers", CurrentValue = V.Tracers.Enabled, Callback = function(v) V.Tracers.Enabled = v end })
VisualsTab:CreateDropdown({ Name = "Tracer origin", Options = { "Bottom", "Center", "Mouse" }, CurrentValue = V.Tracers.From, Flag = "vis_tracers_from", Callback = function(v) V.Tracers.From = v end })
VisualsTab:CreateSlider({ Name = "Thickness", Range = { 1, 5 }, Increment = 1, CurrentValue = V.Tracers.Thickness, Flag = "vis_tracers_th", Callback = function(v) V.Tracers.Thickness = v end })
AddColor(VisualsTab, "Tracer color", V.Tracers, "Color", "vis_tracers_col")

VisualsTab:CreateSection("Skeletons")
VisualsTab:CreateToggle({ Name = "Skeletons", Desc = "Draws player skeletons", Flag = "vis_skel", CurrentValue = V.Skeletons.Enabled, Callback = function(v) V.Skeletons.Enabled = v end })
VisualsTab:CreateSlider({ Name = "Thickness", Range = { 1, 5 }, Increment = 1, CurrentValue = V.Skeletons.Thickness, Flag = "vis_skel_th", Callback = function(v) V.Skeletons.Thickness = v end })
AddColor(VisualsTab, "Skeleton color", V.Skeletons, "Color", "vis_skel_col")

VisualsTab:CreateSection("Chams")
VisualsTab:CreateToggle({ Name = "Chams", Desc = "Highlights player models", Flag = "vis_chams", CurrentValue = V.Chams.Enabled, Callback = function(v) V.Chams.Enabled = v end })
VisualsTab:CreateSlider({ Name = "Transparency", Range = { 0, 1 }, Increment = 0.05, CurrentValue = V.Chams.Transparency, Flag = "vis_chams_tr", Callback = function(v) V.Chams.Transparency = v end })
AddColor(VisualsTab, "Chams color", V.Chams, "Color", "vis_chams_col")

VisualsTab:CreateSection("Head Dots")
VisualsTab:CreateToggle({ Name = "Head Dots", Desc = "Draws dots on heads", Flag = "vis_head", CurrentValue = V.HeadDots.Enabled, Callback = function(v) V.HeadDots.Enabled = v end })
VisualsTab:CreateSlider({ Name = "Size", Range = { 1, 10 }, Increment = 1, CurrentValue = V.HeadDots.Size, Flag = "vis_head_sz", Callback = function(v) V.HeadDots.Size = v end })
AddColor(VisualsTab, "Head dot color", V.HeadDots, "Color", "vis_head_col")

VisualsTab:CreateSection("Health Bars")
VisualsTab:CreateToggle({ Name = "Health Bars", Desc = "Draws health bars", Flag = "vis_hp", CurrentValue = V.HealthBars.Enabled, Callback = function(v) V.HealthBars.Enabled = v end })
VisualsTab:CreateSlider({ Name = "Width", Range = { 1, 10 }, Increment = 1, CurrentValue = V.HealthBars.Width, Flag = "vis_hp_w", Callback = function(v) V.HealthBars.Width = v end })
AddColor(VisualsTab, "Health bar color", V.HealthBars, "Color", "vis_hp_col")

VisualsTab:CreateSection("Text")
VisualsTab:CreateToggle({ Name = "Distance Text", Desc = "Shows distance to players", Flag = "vis_dist", CurrentValue = V.DistanceText.Enabled, Callback = function(v) V.DistanceText.Enabled = v end })
AddColor(VisualsTab, "Distance color", V.DistanceText, "Color", "vis_dist_col")
VisualsTab:CreateToggle({ Name = "Weapon Text", Desc = "Shows held weapons", Flag = "vis_wep", CurrentValue = V.WeaponText.Enabled, Callback = function(v) V.WeaponText.Enabled = v end })
AddColor(VisualsTab, "Weapon color", V.WeaponText, "Color", "vis_wep_col")

-- ===== SETTINGS =====
SettingsTab:CreateSection("Core Bindings")
SettingsTab:CreateLabel({ Name = "Menu toggle key: " .. tostring(getgenv().Settings.MinimizeKey) .. " (set at load)" })
AddBind(SettingsTab, "Aimbot",     getgenv().Aimbot,     "Keybind", "kb_aimbot")
AddBind(SettingsTab, "Triggerbot", getgenv().Triggerbot, "Keybind", "kb_trigger")
AddBind(SettingsTab, "ESP",        getgenv().ESP,        "Keybind", "kb_esp")
AddBind(SettingsTab, "Fly",        getgenv().Fly,        "Keybind", "kb_fly")
AddBind(SettingsTab, "Noclip",     getgenv().Noclip,     "Keybind", "kb_noclip")
AddBind(SettingsTab, "Fake Macro", getgenv().FakeMacro,  "Keybind", "kb_macro")
AddBind(SettingsTab, "Loop Kill",  getgenv().LoopKill,   "Keybind", "kb_loopkill")
AddBind(SettingsTab, "Tornado",    getgenv().Tornado,    "Keybind", "kb_tornado")
AddBind(SettingsTab, "Buy Armor",  getgenv().Armor,      "Keybind", "kb_armor")

SettingsTab:CreateSection("Feature Values")
SettingsTab:CreateSlider({ Name = "Aimbot Prediction X", Range = { 0, 1 }, Increment = 0.005, CurrentValue = getgenv().Aimbot.Prediction.X, Flag = "val_predx", Callback = function(v) getgenv().Aimbot.Prediction.X = v end })
SettingsTab:CreateSlider({ Name = "Aimbot Prediction Y", Range = { 0, 1 }, Increment = 0.005, CurrentValue = getgenv().Aimbot.Prediction.Y, Flag = "val_predy", Callback = function(v) getgenv().Aimbot.Prediction.Y = v end })
SettingsTab:CreateSlider({ Name = "Fly Speed", Range = { 50, 500 }, Increment = 5, CurrentValue = getgenv().Fly.Speed, Flag = "val_fly", Callback = function(v) getgenv().Fly.Speed = v end })
SettingsTab:CreateSlider({ Name = "Fake Macro Speed", Range = { 10, 50 }, Increment = 1, CurrentValue = getgenv().FakeMacro.SpeedMultiplier, Flag = "val_macro", Callback = function(v) getgenv().FakeMacro.SpeedMultiplier = v end })

SettingsTab:CreateSection("Config")
SettingsTab:CreateButtonRow({
    { Name = "Save config", Callback = function() pcall(function() Window:SaveConfig("default") end) Notify("Config", "Saved.") end },
    { Name = "Load config", Style = "Secondary", Callback = function()
        local ok = pcall(function() Window:LoadConfig("default") end)
        Notify("Config", ok and "Loaded." or "No saved config found.")
    end },
})
SettingsTab:CreateButton({
    Name = "Emergency server rejoin", Style = "Secondary",
    Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end,
})

-- ===== CREDITS =====
CreditsTab:CreateSection("Core Team")
CreditsTab:CreateLabel({ Name = "Head Dev: Vantablade" })
CreditsTab:CreateLabel({ Name = "UI Design: Vantablade & Community" })
CreditsTab:CreateLabel({ Name = "Optimization: Core Engine Team" })
CreditsTab:CreateSection("Socials")
CreditsTab:CreateLabel({ Name = "YouTube: @VantabladeYT" })
CreditsTab:CreateLabel({ Name = "Discord: discord.gg/ERNQpp8NpE" })
CreditsTab:CreateSection("Special Thanks")
CreditsTab:CreateLabel({ Name = "Testers: Vanta Elite Group" })
CreditsTab:CreateLabel({ Name = "Legacy Support: Jace Scripts" })
CreditsTab:CreateLabel({ Name = "Version: PhantomDuels Premier Edition v7.0.0" })

--- ### GAME RENDER LOOPS
local function GetHealthColor(percent)
    if percent > 0.7 then return Color3.fromRGB(0, 255, 127) 
    elseif percent > 0.3 then return Color3.fromRGB(255, 255, 0)
    else return Color3.fromRGB(255, 60, 60) end
end

local function CreateESP(Player)
    local Box, Name = Drawing.new("Square"), Drawing.new("Text")
    local Tracer = Drawing.new("Line")
    local HeadDot = Drawing.new("Circle")
    local HealthBarBack = Drawing.new("Square")
    local HealthBarFill = Drawing.new("Square")
    local DistanceText = Drawing.new("Text")
    local WeaponText = Drawing.new("Text")
    local SkeletonLines = {}
    local ChamHighlight = Instance.new("Highlight")
    ChamHighlight.Parent = game.CoreGui
    ChamHighlight.Enabled = false

    local bones = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LowerTorso", "RightUpperLeg"},
        {"UpperTorso", "LeftUpperArm"},
        {"UpperTorso", "RightUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"RightLowerArm", "RightHand"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"RightLowerLeg", "RightFoot"}
    }

    for _, bonePair in ipairs(bones) do
        local line = Drawing.new("Line")
        line.Visible = false
        table.insert(SkeletonLines, line)
    end

    local Connection
    Connection = RunService.RenderStepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player ~= LocalPlayer then
            local RootPart = Player.Character.HumanoidRootPart
            local Hum = Player.Character:FindFirstChildOfClass("Humanoid")
            local Head = Player.Character:FindFirstChild("Head")
            if not Hum or not Head then 
                Box.Visible = false Name.Visible = false Tracer.Visible = false HeadDot.Visible = false
                HealthBarBack.Visible = false HealthBarFill.Visible = false DistanceText.Visible = false WeaponText.Visible = false
                for _, line in ipairs(SkeletonLines) do line.Visible = false end
                ChamHighlight.Enabled = false
                return 
            end
            local RootPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
            if OnScreen then
                local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
                local LegPos = Camera:WorldToViewportPoint(RootPart.Position - Vector3.new(0, 3, 0))
                local BoxHeight = math.abs(HeadPos.Y - LegPos.Y)
                local BoxWidth = BoxHeight / 1.6
                local Color = GetHealthColor(Hum.Health / Hum.MaxHealth)

                -- Original ESP (unchanged)
                if getgenv().ESP.Enabled then
                    Box.Visible = true Box.Color = Color Box.Size = Vector2.new(BoxWidth, BoxHeight)
                    Box.Position = Vector2.new(RootPos.X - BoxWidth / 2, RootPos.Y - BoxHeight / 2)
                    Box.Thickness = 1
                    Name.Visible = true Name.Text = Player.DisplayName .. "\n" .. math.floor(Hum.Health) .. " HP"
                    Name.Size = 15 Name.Center = true Name.Outline = true Name.Color = Color
                    Name.Position = Vector2.new(RootPos.X, RootPos.Y - (BoxHeight / 2) - 35)
                else
                    Box.Visible = false Name.Visible = false
                end

                -- Tracers
                if getgenv().Visuals.Tracers.Enabled then
                    local fromPos
                    if getgenv().Visuals.Tracers.From == "Bottom" then
                        fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    elseif getgenv().Visuals.Tracers.From == "Center" then
                        fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    else  -- Mouse
                        fromPos = Vector2.new(Mouse.X, Mouse.Y)
                    end
                    Tracer.Visible = true
                    Tracer.Color = getgenv().Visuals.Tracers.Color
                    Tracer.Thickness = getgenv().Visuals.Tracers.Thickness
                    Tracer.From = fromPos
                    Tracer.To = Vector2.new(RootPos.X, RootPos.Y)
                else
                    Tracer.Visible = false
                end

                -- Head Dots
                if getgenv().Visuals.HeadDots.Enabled then
                    local headScreen = Camera:WorldToViewportPoint(Head.Position)
                    HeadDot.Visible = true
                    HeadDot.Color = getgenv().Visuals.HeadDots.Color
                    HeadDot.Radius = getgenv().Visuals.HeadDots.Size
                    HeadDot.Filled = getgenv().Visuals.HeadDots.Filled
                    HeadDot.Position = Vector2.new(headScreen.X, headScreen.Y)
                else
                    HeadDot.Visible = false
                end

                -- Health Bars
                if getgenv().Visuals.HealthBars.Enabled then
                    local healthPercent = Hum.Health / Hum.MaxHealth
                    HealthBarBack.Visible = true
                    HealthBarBack.Color = Color3.fromRGB(50, 50, 50)
                    HealthBarBack.Size = Vector2.new(getgenv().Visuals.HealthBars.Width, BoxHeight)
                    HealthBarBack.Position = Vector2.new(RootPos.X - BoxWidth / 2 - getgenv().Visuals.HealthBars.Width - 2, RootPos.Y - BoxHeight / 2)
                    HealthBarBack.Thickness = 1
                    HealthBarBack.Filled = true

                    HealthBarFill.Visible = true
                    HealthBarFill.Color = getgenv().Visuals.HealthBars.Color
                    HealthBarFill.Size = Vector2.new(getgenv().Visuals.HealthBars.Width, BoxHeight * healthPercent)
                    HealthBarFill.Position = HealthBarBack.Position + Vector2.new(0, BoxHeight - BoxHeight * healthPercent)
                    HealthBarFill.Thickness = 1
                    HealthBarFill.Filled = true
                else
                    HealthBarBack.Visible = false
                    HealthBarFill.Visible = false
                end

                -- Distance Text
                if getgenv().Visuals.DistanceText.Enabled then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - RootPart.Position).Magnitude
                    DistanceText.Visible = true
                    DistanceText.Text = math.floor(distance) .. " studs"
                    DistanceText.Size = 14
                    DistanceText.Center = true
                    DistanceText.Outline = true
                    DistanceText.Color = getgenv().Visuals.DistanceText.Color
                    DistanceText.Position = Vector2.new(RootPos.X, RootPos.Y + BoxHeight / 2 + 5)
                else
                    DistanceText.Visible = false
                end

                -- Weapon Text
                if getgenv().Visuals.WeaponText.Enabled then
                    local tool = Player.Character:FindFirstChildOfClass("Tool")
                    local weaponName = tool and tool.Name or "None"
                    WeaponText.Visible = true
                    WeaponText.Text = "Weapon: " .. weaponName
                    WeaponText.Size = 14
                    WeaponText.Center = true
                    WeaponText.Outline = true
                    WeaponText.Color = getgenv().Visuals.WeaponText.Color
                    WeaponText.Position = Vector2.new(RootPos.X, RootPos.Y + BoxHeight / 2 + 20)
                else
                    WeaponText.Visible = false
                end

                -- Skeletons
                if getgenv().Visuals.Skeletons.Enabled then
                    for i, bonePair in ipairs(bones) do
                        local part1 = Player.Character:FindFirstChild(bonePair[1])
                        local part2 = Player.Character:FindFirstChild(bonePair[2])
                        if part1 and part2 then
                            local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)
                            if vis1 and vis2 then
                                SkeletonLines[i].Visible = true
                                SkeletonLines[i].Color = getgenv().Visuals.Skeletons.Color
                                SkeletonLines[i].Thickness = getgenv().Visuals.Skeletons.Thickness
                                SkeletonLines[i].From = Vector2.new(pos1.X, pos1.Y)
                                SkeletonLines[i].To = Vector2.new(pos2.X, pos2.Y)
                            else
                                SkeletonLines[i].Visible = false
                            end
                        else
                            SkeletonLines[i].Visible = false
                        end
                    end
                else
                    for _, line in ipairs(SkeletonLines) do line.Visible = false end
                end

                -- Chams
                if getgenv().Visuals.Chams.Enabled then
                    ChamHighlight.Adornee = Player.Character
                    ChamHighlight.FillColor = getgenv().Visuals.Chams.Color
                    ChamHighlight.FillTransparency = getgenv().Visuals.Chams.Transparency
                    ChamHighlight.OutlineColor = getgenv().Visuals.Chams.Color
                    ChamHighlight.OutlineTransparency = 0
                    ChamHighlight.Enabled = true
                else
                    ChamHighlight.Enabled = false
                end

            else
                Box.Visible = false Name.Visible = false Tracer.Visible = false HeadDot.Visible = false
                HealthBarBack.Visible = false HealthBarFill.Visible = false DistanceText.Visible = false WeaponText.Visible = false
                for _, line in ipairs(SkeletonLines) do line.Visible = false end
                ChamHighlight.Enabled = false
            end
        else
            Box.Visible = false Name.Visible = false Tracer.Visible = false HeadDot.Visible = false
            HealthBarBack.Visible = false HealthBarFill.Visible = false DistanceText.Visible = false WeaponText.Visible = false
            for _, line in ipairs(SkeletonLines) do line.Visible = false end
            ChamHighlight.Enabled = false
            if not Player.Parent then 
                Box:Remove() Name:Remove() Tracer:Remove() HeadDot:Remove()
                HealthBarBack:Remove() HealthBarFill:Remove() DistanceText:Remove() WeaponText:Remove()
                for _, line in ipairs(SkeletonLines) do line:Remove() end
                ChamHighlight:Destroy()
                Connection:Disconnect() 
            end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)


-- ============================================================
-- HOTKEYS
-- ============================================================
local function keyOf(name)
    if typeof(name) == "EnumItem" then return name end
    local n = tostring(name)
    local ok, kc = pcall(function() return Enum.KeyCode[n] end)
    if ok and kc then return kc end
    ok, kc = pcall(function() return Enum.KeyCode[n:upper()] end)
    return ok and kc or nil
end

UIS.InputBegan:Connect(function(i, g)
    if g then return end
    local key = i.KeyCode
    if key == Enum.KeyCode.Unknown then return end
    local G = getgenv()

    if key == keyOf(G.Aimbot.Keybind) then setAimbot(TargetPlayer == nil)
    elseif key == keyOf(G.Triggerbot.Keybind) then setSimple("Triggerbot", G.Triggerbot, not G.Triggerbot.Enabled)
    elseif key == keyOf(G.ESP.Keybind) then setSimple("ESP", G.ESP, not G.ESP.Enabled)
    elseif key == keyOf(G.Fly.Keybind) then setFly(not G.Fly.Enabled)
    elseif key == keyOf(G.Noclip.Keybind) then setSimple("Noclip", G.Noclip, not G.Noclip.Enabled)
    elseif key == keyOf(G.FakeMacro.Keybind) then setSimple("Fake Macro", G.FakeMacro, not G.FakeMacro.Enabled)
    elseif key == keyOf(G.LoopKill.Keybind) then setLoopKill(not G.LoopKill.Enabled)
    elseif key == keyOf(G.Tornado.Keybind) then setTornado(not G.Tornado.Enabled)
    elseif key == keyOf(G.Armor.Keybind) then task.spawn(GetArmor)
    end
end)

local tornadoAngle, LastClickTime, ClickDelay = 0, 0, 0

RunService.Heartbeat:Connect(function()
    if getgenv().Noclip.Enabled and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
    if getgenv().LoopKill.Enabled and SelectedPlayerForTP and SelectedPlayerForTP.Character and SelectedPlayerForTP.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = SelectedPlayerForTP.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    end
    if getgenv().Tornado.Enabled and SelectedPlayerForTP and SelectedPlayerForTP.Character and SelectedPlayerForTP.Character:FindFirstChild("HumanoidRootPart") then
        local targetRoot = SelectedPlayerForTP.Character.HumanoidRootPart
        tornadoAngle = tornadoAngle + 0.1
        local targetPos = targetRoot.Position + Vector3.new(math.cos(tornadoAngle) * 7.5, 0, math.sin(tornadoAngle) * 7.5)
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos, targetRoot.Position)
    end
    if getgenv().FakeMacro.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if Hum and Hum.MoveDirection.Magnitude > 0 then
            LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + (Hum.MoveDirection * (getgenv().FakeMacro.SpeedMultiplier / 10))
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if TargetPlayer and getgenv().Aimbot.Status and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild(getgenv().Aimbot.Hitpart) then
        local Part = TargetPlayer.Character[getgenv().Aimbot.Hitpart]
        local predictedPos = Part.Position + (Part.Velocity * Vector3.new(getgenv().Aimbot.Prediction.X, getgenv().Aimbot.Prediction.Y, getgenv().Aimbot.Prediction.X))
        local dist = (Camera.CFrame.Position - Part.Position).Magnitude
        if dist > 5 then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
        end
    end
    if getgenv().Triggerbot.Enabled then
        local MouseRay = Camera:ViewportPointToRay(Mouse.X, Mouse.Y)
        local RaycastParamsInstance = RaycastParams.new() -- Integrated from PhantomDuels triggerbot.lua
        RaycastParamsInstance.FilterType = Enum.RaycastFilterType.Include
        local filters = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                table.insert(filters, p.Character)
            end
        end
        RaycastParamsInstance.FilterDescendantsInstances = filters

        local Result = Workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 1000, RaycastParamsInstance)
        if Result and Result.Instance then
            local HitPart = Result.Instance
            local HitModel = HitPart:FindFirstAncestorOfClass("Model")
            local HitPlayer = Players:GetPlayerFromCharacter(HitModel)
            
            -- Detect any player part (Head, Torso, Arms, etc.) excluding self
            if HitPlayer and HitPlayer ~= LocalPlayer then
                if tick() - LastClickTime >= ClickDelay then
                    mouse1press()
                    mouse1release()
                    LastClickTime = tick()
                end
            end
        end
    end
end)

