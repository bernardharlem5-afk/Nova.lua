local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/PookiePepelsss/Airflow-UI/refs/heads/main/Source.luau"))()
Airflow:LoadFont({Name = "ValleySans"})

local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local autoTime = {
	Enabled = false,
	ReleaseTime = 0.55,
	ShootKey = Enum.KeyCode.E,
	isShooting = false
}

local glide = {
	Enabled = false,
	GlideForce = 50,
	FloatHeight = 1.5,
	OriginalHipHeight = 2,
	GlideAttachment = nil,
	GlideVelocity = nil,
	Connection = nil
}

local shootKeys = {
	E = Enum.KeyCode.E,
	Space = Enum.KeyCode.Space,
	F = Enum.KeyCode.F,
	G = Enum.KeyCode.G
}

local Window = Airflow:Window({
	Name = "Byte.WTF",
	Subtitle = "Made By Xen",
	LoadingTitle = "BYTE.WTF On Top",
	LoadingSubtitle = "Made By Xen",
	Keybind = "RightControl"
})

-- Auto Timing tab
local TimingTab = Window:Tab({Name = "Auto Timing", Icon = "timer"})

TimingTab:Paragraph({
	Title = "⚠️ Important Note",
	Content = "You have to configure the timing for the shots you want to do like fade aways, mids, and three pointers. This script isn't a guaranteed green and you have to have good timing for your shot. You aren't going to green it in someone's face although it's possible but very unlikely, and you cannot drain it from half court every time. Contest and range still matter!"
})

TimingTab:Toggle({
	Name = "Auto Time Shots",
	Default = false,
	Flag = "AutoTimeToggle",
	Callback = function(value)
		autoTime.Enabled = value
	end
})

TimingTab:Slider({
	Name = "Release Time (Seconds)",
	Min = 0.1,
	Max = 1.5,
	Step = 0.01,
	Suffix = "s",
	Default = 0.55,
	Flag = "ReleaseTimeSlider",
	Callback = function(value)
		autoTime.ReleaseTime = value
	end
})

TimingTab:Dropdown({
	Name = "Game Shoot Key",
	Options = {"E", "Space", "F", "G"},
	Default = "E",
	Flag = "ShootKeyDropdown",
	Callback = function(option)
		autoTime.ShootKey = shootKeys[option] or Enum.KeyCode.E
	end
})

TimingTab:Keybind({
	Name = "Trigger Auto-Shoot",
	Default = "CapsLock",
	Flag = "TriggerKeybind",
	Callback = function()
		if not autoTime.Enabled or autoTime.isShooting then
			return
		end

		autoTime.isShooting = true
		VirtualInputManager:SendKeyEvent(true, autoTime.ShootKey, false, game)
		task.wait(autoTime.ReleaseTime)
		VirtualInputManager:SendKeyEvent(false, autoTime.ShootKey, false, game)
		autoTime.isShooting = false
	end
})

-- Dribble Glide tab
local GlideTab = Window:Tab({Name = "Dribble Glide", Icon = "wind"})

GlideTab:Toggle({
	Name = "Enable Dribble Glide",
	Default = false,
	Flag = "ExtenderToggle",
	Callback = function(value)
		glide.Enabled = value

		if value then
			return
		end

		if glide.GlideVelocity then
			glide.GlideVelocity.VectorVelocity = Vector3.new(0, 0, 0)
		end

		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.HipHeight = glide.OriginalHipHeight
		end
	end
})

GlideTab:Slider({
	Name = "Glide / Slide Force",
	Min = 10,
	Max = 150,
	Step = 5,
	Suffix = " Force",
	Default = 50,
	Flag = "GlideSlider",
	Callback = function(value)
		glide.GlideForce = value
	end
})

GlideTab:Slider({
	Name = "Float Height",
	Min = 0,
	Max = 5,
	Step = 0.25,
	Suffix = " Studs",
	Default = 1.5,
	Flag = "FloatSlider",
	Callback = function(value)
		glide.FloatHeight = value
	end
})

-- Character setup
local function setupGlide(character)
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	glide.OriginalHipHeight = humanoid.HipHeight

	local existing = rootPart:FindFirstChild("GlideAttachment")
	if not existing then
		glide.GlideAttachment = Instance.new("Attachment", rootPart)
		glide.GlideAttachment.Name = "GlideAttachment"
		glide.GlideVelocity = Instance.new("LinearVelocity", glide.GlideAttachment)
		glide.GlideVelocity.MaxForce = 1000000
		glide.GlideVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		glide.GlideVelocity.VectorVelocity = Vector3.new(0, 0, 0)
	end

	if glide.Connection then
		glide.Connection:Disconnect()
	end

	glide.Connection = RunService.Heartbeat:Connect(function()
		if not glide.Enabled or LocalPlayer.Character ~= character then
			return
		end

		humanoid.HipHeight = glide.OriginalHipHeight + glide.FloatHeight

		local moveDirection = humanoid.MoveDirection
		if moveDirection.Magnitude > 0 then
			glide.GlideVelocity.VectorVelocity = moveDirection * glide.GlideForce
		else
			glide.GlideVelocity.VectorVelocity = Vector3.new(0, 0, 0)
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(setupGlide)

if LocalPlayer.Character then
	task.spawn(setupGlide, LocalPlayer.Character)
end

Airflow:Notify({
	Title = "Loaded Successfully",
	Content = "All things are ready!",
	Duration = 5,
	Type = "Success"
})
