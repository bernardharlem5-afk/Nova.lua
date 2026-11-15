
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// THEME -----------------------------------------------------
local C = {
	Bg       = Color3.fromRGB(10, 10, 10),
	Panel    = Color3.fromRGB(17, 17, 17),
	PanelAlt = Color3.fromRGB(24, 24, 24),
	Row      = Color3.fromRGB(28, 28, 28),
	Yellow   = Color3.fromRGB(255, 200, 40),
	White    = Color3.fromRGB(240, 240, 240),
	Dim      = Color3.fromRGB(140, 140, 140),
	Line     = Color3.fromRGB(40, 40, 40),
	Off      = Color3.fromRGB(48, 48, 48),
}

--// HELPERS ---------------------------------------------------
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then obj[k] = v end
	end
	obj.Parent = parent
	return obj
end

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
	return c
end

local function stroke(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or C.Yellow
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function fadeGroup(root, target, duration)
	for _, obj in ipairs(root:GetDescendants()) do
		local props = {}
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			props.TextTransparency = target
		end
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			props.ImageTransparency = target
		end
		if obj:IsA("Frame") then
			props.BackgroundTransparency = target
		end
		if obj:IsA("UIStroke") then
			props.Transparency = target
		end
		if next(props) then
			TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad), props):Play()
		end
	end
end

--// GUI ROOT --------------------------------------------------
local existing = playerGui:FindFirstChild("UtilityLabs")
if existing then existing:Destroy() end

local gui = make("ScreenGui", {
	Name = "UtilityLabs",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, playerGui)

--=============================================================
--  LOADING SCREEN
--=============================================================
local loading = make("Frame", {
	Name = "Loading",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	BorderSizePixel = 0,
	ZIndex = 50,
}, gui)

local titleHolder = make("Frame", {
	Size = UDim2.new(1, 0, 0, 120),
	Position = UDim2.new(0.5, 0, 0.5, -110),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	ZIndex = 51,
}, loading)

make("TextLabel", {
	Text = "Utility Labs",
	Font = Enum.Font.GothamBlack,
	TextSize = 44,
	TextColor3 = C.White,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 52),
	ZIndex = 51,
}, titleHolder)

local underline = make("Frame", {
	Size = UDim2.fromOffset(64, 3),
	Position = UDim2.new(0.5, 0, 0, 62),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = C.Yellow,
	BorderSizePixel = 0,
	ZIndex = 51,
}, titleHolder)
corner(underline, 2)

-- progress bar
local barHolder = make("Frame", {
	Size = UDim2.fromOffset(320, 6),
	Position = UDim2.new(0.5, 0, 0.5, 44),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	ZIndex = 51,
}, loading)
corner(barHolder, 3)

local fill = make("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = C.Yellow,
	BorderSizePixel = 0,
	ZIndex = 52,
}, barHolder)
corner(fill, 3)

local pct = make("TextLabel", {
	Text = "0%",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = C.Dim,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 1, 12),
	ZIndex = 51,
}, barHolder)

-- loading animation (calm, time based)
local DURATION = 2.8
local startTime = os.clock()

while true do
	local t = math.clamp((os.clock() - startTime) / DURATION, 0, 1)
	fill.Size = UDim2.fromScale(t, 1)
	pct.Text = tostring(math.floor(t * 100)) .. "%"
	if t >= 1 then break end
	task.wait()
end

pct.Text = "100%"
task.wait(0.4)

--=============================================================
--  MENU
--=============================================================
local function buildMenu()
	local main = make("Frame", {
		Name = "Menu",
		Size = UDim2.fromOffset(620, 400),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(12, 12, 12),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	}, gui)
	corner(main, 10)
	stroke(main, C.Line, 1, 0)

	--// TOP BAR
	local topBar = make("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = C.Panel,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, main)

	local accent = make("Frame", {
		Size = UDim2.fromOffset(3, 18),
		Position = UDim2.fromOffset(16, 15),
		BackgroundColor3 = C.Yellow,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, topBar)
	corner(accent, 2)

	make("TextLabel", {
		Text = "Utility Labs",
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextColor3 = C.White,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(28, 0),
		Size = UDim2.new(0, 220, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, topBar)

	local close = make("TextButton", {
		Text = "✕",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = C.Dim,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(40, 48),
		Position = UDim2.new(1, -44, 0, 0),
		AutoButtonColor = false,
		ZIndex = 3,
	}, topBar)

	close.MouseEnter:Connect(function() close.TextColor3 = C.White end)
	close.MouseLeave:Connect(function() close.TextColor3 = C.Dim end)
	close.MouseButton1Click:Connect(function() gui:Destroy() end)

	make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 48),
		BackgroundColor3 = C.Line,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, main)

	--// SIDEBAR
	local sidebar = make("Frame", {
		Size = UDim2.new(0, 150, 1, -79),
		Position = UDim2.fromOffset(0, 49),
		BackgroundColor3 = Color3.fromRGB(14, 14, 14),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, main)

	--// CONTENT
	local content = make("Frame", {
		Size = UDim2.new(1, -150, 1, -79),
		Position = UDim2.fromOffset(150, 49),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, main)

	--// FOOTER
	local footer = make("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 1, -30),
		BackgroundColor3 = C.Panel,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, main)

	make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = C.Line,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, footer)

	make("TextLabel", {
		Text = "discord.gg/utilityhub",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.Yellow,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
	}, footer)

	make("TextLabel", {
		Text = "v1.0.0",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.Dim,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0, 60, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, footer)

	--// BUBBLE EFFECT
	local inset = Vector2.new(0, 0)
	local okInset, insetVal = pcall(function() return GuiService:GetGuiInset() end)
	if okInset and typeof(insetVal) == "Vector2" then inset = insetVal end

	local function spawnBubble(parent)
		local m = UserInputService:GetMouseLocation() + inset
		local rel = m - parent.AbsolutePosition
		if rel.X < 0 or rel.Y < 0 or rel.X > parent.AbsoluteSize.X or rel.Y > parent.AbsoluteSize.Y then
			rel = parent.AbsoluteSize / 2
		end

		local bubble = make("Frame", {
			Size = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(rel.X, rel.Y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = C.Yellow,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 20,
		}, parent)
		corner(bubble, 999)

		local size = 260
		TweenService:Create(bubble, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
		}):Play()

		task.delay(0.6, function()
			if bubble then bubble:Destroy() end
		end)
	end

	--// TAB DEFINITIONS
	local TABS = { "Main", "Combat", "Visuals", "Misc", "Settings" }

	local PAGES = {
		Main = {
			{ Type = "Header", Text = "Utility Labs", Sub = "Clean tools, calm interface." },
			{ Type = "Toggle", Text = "Enable Features", Default = true },
			{ Type = "Toggle", Text = "Streamer Mode", Default = false },
			{ Type = "Slider", Text = "Interface Scale", Value = 0.6 },
			{ Type = "Button", Text = "Execute" },
		},
		Combat = {
			{ Type = "Header", Text = "Combat", Sub = "Precision helpers." },
			{ Type = "Toggle", Text = "Aim Assist", Default = true },
			{ Type = "Toggle", Text = "Silent Aim", Default = false },
			{ Type = "Slider", Text = "Field of View", Value = 0.35 },
			{ Type = "Slider", Text = "Smoothing", Value = 0.7 },
		},
		Visuals = {
			{ Type = "Header", Text = "Visuals", Sub = "See what matters." },
			{ Type = "Toggle", Text = "Player ESP", Default = true },
			{ Type = "Toggle", Text = "Fullbright", Default = false },
			{ Type = "Slider", Text = "Render Distance", Value = 0.5 },
		},
		Misc = {
			{ Type = "Header", Text = "Misc", Sub = "Quality of life." },
			{ Type = "Toggle", Text = "Infinite Jump", Default = false },
			{ Type = "Toggle", Text = "Walk Speed +", Default = false },
			{ Type = "Slider", Text = "Walk Speed", Value = 0.4 },
		},
		Settings = {
			{ Type = "Header", Text = "Settings", Sub = "Version 1.0.0" },
			{ Type = "Toggle", Text = "Auto Save Config", Default = true },
			{ Type = "Toggle", Text = "Discord Rich Presence", Default = true },
			{ Type = "Button", Text = "Reset to Defaults" },
		},
	}

	--// PAGE BUILDER
	local function buildPage(page, items)
		local y = 16

		for _, item in ipairs(items) do
			if item.Type == "Header" then
				make("TextLabel", {
					Text = item.Text,
					Font = Enum.Font.GothamBold,
					TextSize = 16,
					TextColor3 = C.White,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(1, -28, 0, 20),
					Position = UDim2.fromOffset(14, y),
					ZIndex = 3,
				}, page)

				if item.Sub then
					make("TextLabel", {
						Text = item.Sub,
						Font = Enum.Font.Gotham,
						TextSize = 12,
						TextColor3 = C.Dim,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						Size = UDim2.new(1, -28, 0, 18),
						Position = UDim2.fromOffset(14, y + 21),
						ZIndex = 3,
					}, page)
					y = y + 22
				end
				y = y + 30

			elseif item.Type == "Toggle" then
				local row = make("Frame", {
					Size = UDim2.new(1, -28, 0, 40),
					Position = UDim2.fromOffset(14, y),
					BackgroundColor3 = C.PanelAlt,
					BorderSizePixel = 0,
					ZIndex = 3,
				}, page)
				corner(row, 6)

				make("TextLabel", {
					Text = item.Text,
					Font = Enum.Font.GothamMedium,
					TextSize = 13,
					TextColor3 = C.White,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(12, 0),
					Size = UDim2.new(1, -80, 1, 0),
					ZIndex = 4,
				}, row)

				local pill = make("Frame", {
					Size = UDim2.fromOffset(38, 20),
					Position = UDim2.new(1, -50, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = C.Off,
					BorderSizePixel = 0,
					ZIndex = 4,
				}, row)
				corner(pill, 10)

				local knob = make("Frame", {
					Size = UDim2.fromOffset(14, 14),
					Position = UDim2.fromOffset(3, 3),
					BackgroundColor3 = C.Dim,
					BorderSizePixel = 0,
					ZIndex = 5,
				}, pill)
				corner(knob, 7)

				local click = make("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 6,
				}, row)

				local state = item.Default or false
				local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

				local function apply()
					TweenService:Create(pill, ti, {
						BackgroundColor3 = state and C.Yellow or C.Off,
					}):Play()
					TweenService:Create(knob, ti, {
						Position = UDim2.fromOffset(state and 21 or 3, 3),
						BackgroundColor3 = state and Color3.fromRGB(15, 15, 15) or C.Dim,
					}):Play()
				end
				apply()

				click.MouseButton1Click:Connect(function()
					state = not state
					apply()
				end)

				y = y + 50

			elseif item.Type == "Slider" then
				local row = make("Frame", {
					Size = UDim2.new(1, -28, 0, 52),
					Position = UDim2.fromOffset(14, y),
					BackgroundColor3 = C.PanelAlt,
					BorderSizePixel = 0,
					ZIndex = 3,
				}, page)
				corner(row, 6)

				make("TextLabel", {
					Text = item.Text,
					Font = Enum.Font.GothamMedium,
					TextSize = 13,
					TextColor3 = C.White,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.fromOffset(12, 8),
					Size = UDim2.new(1, -100, 0, 18),
					ZIndex = 4,
				}, row)

				local valueText = make("TextLabel", {
					Text = "0%",
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextColor3 = C.Yellow,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.new(1, -60, 0, 8),
					Size = UDim2.new(0, 48, 0, 18),
					ZIndex = 4,
				}, row)

				local track = make("Frame", {
					Size = UDim2.new(1, -24, 0, 4),
					Position = UDim2.new(0, 12, 1, -16),
					BackgroundColor3 = Color3.fromRGB(45, 45, 45),
					BorderSizePixel = 0,
					ZIndex = 4,
				}, row)
				corner(track, 2)

				local trackFill = make("Frame", {
					Size = UDim2.fromScale(item.Value or 0.5, 1),
					BackgroundColor3 = C.Yellow,
					BorderSizePixel = 0,
					ZIndex = 5,
				}, track)
				corner(trackFill, 2)

				local knob = make("Frame", {
					Size = UDim2.fromOffset(12, 12),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(item.Value or 0.5, 0, 0.5, 0),
					BackgroundColor3 = C.Yellow,
					BorderSizePixel = 0,
					ZIndex = 6,
				}, track)
				corner(knob, 6)

				local value = item.Value or 0.5
				local function setValue(v)
					value = math.clamp(v, 0, 1)
					trackFill.Size = UDim2.fromScale(value, 1)
					knob.Position = UDim2.new(value, 0, 0.5, 0)
					valueText.Text = tostring(math.floor(value * 100)) .. "%"
				end
				setValue(value)

				local hit = make("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 24),
					Position = UDim2.new(0, 0, 1, -28),
					ZIndex = 7,
				}, row)

				local dragging = false

				local function setFromMouse()
					if not track.Parent then return end
					local m = UserInputService:GetMouseLocation()
					local relX = (m.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
					setValue(relX)
				end

				hit.MouseButton1Down:Connect(function()
					dragging = true
					setFromMouse()
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch) then
						setFromMouse()
					end
				end)

				y = y + 60

			elseif item.Type == "Button" then
				local btn = make("TextButton", {
					Text = item.Text,
					Font = Enum.Font.GothamBold,
					TextSize = 13,
					TextColor3 = Color3.fromRGB(20, 20, 20),
					BackgroundColor3 = C.Yellow,
					Size = UDim2.new(1, -28, 0, 38),
					Position = UDim2.fromOffset(14, y),
					AutoButtonColor = false,
					ZIndex = 3,
				}, page)
				corner(btn, 6)

				btn.MouseEnter:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.15), {
						BackgroundColor3 = Color3.fromRGB(255, 218, 90),
					}):Play()
				end)
				btn.MouseLeave:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.15), {
						BackgroundColor3 = C.Yellow,
					}):Play()
				end)

				y = y + 48
			end
		end
	end

	--// BUILD TABS + PAGES
	local tabButtons = {}
	local pages = {}

	for i, name in ipairs(TABS) do
		local btn = make("TextButton", {
			Name = name,
			Text = "",
			Size = UDim2.new(1, -20, 0, 34),
			Position = UDim2.fromOffset(10, 10 + (i - 1) * 38),
			BackgroundColor3 = Color3.fromRGB(34, 30, 18),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			ZIndex = 3,
		}, sidebar)
		corner(btn, 6)

		local indicator = make("Frame", {
			Size = UDim2.fromOffset(3, 16),
			Position = UDim2.new(0, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = C.Yellow,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, btn)
		corner(indicator, 2)

		local label = make("TextLabel", {
			Text = name,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = C.Dim,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(16, 0),
			Size = UDim2.new(1, -20, 1, 0),
			ZIndex = 4,
		}, btn)

		local page = make("Frame", {
			Name = name .. "Page",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = (i == 1),
			ZIndex = 2,
		}, content)

		buildPage(page, PAGES[name] or {})

		tabButtons[name] = { Button = btn, Label = label, Indicator = indicator }
		pages[name] = page

		btn.MouseButton1Down:Connect(function()
			spawnBubble(btn)

			for tabName, refs in pairs(tabButtons) do
				local selected = (tabName == name)
				local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

				TweenService:Create(refs.Button, ti, {
					BackgroundTransparency = selected and 0 or 1,
				}):Play()
				TweenService:Create(refs.Label, ti, {
					TextColor3 = selected and C.Yellow or C.Dim,
				}):Play()
				TweenService:Create(refs.Indicator, ti, {
					BackgroundTransparency = selected and 0 or 1,
				}):Play()

				pages[tabName].Visible = selected
			end
		end)
	end

	--// DRAGGING
	local dragging, dragStart, startPos

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--=============================================================
--  TRANSITION: fade loading out -> fade menu in
--=============================================================
fadeGroup(loading, 1, 0.45)
task.wait(0.5)

buildMenu()

local fade = TweenService:Create(loading, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {
	BackgroundTransparency = 1,
})
fade:Play()
fade.Completed:Wait()

loading:Destroy()
