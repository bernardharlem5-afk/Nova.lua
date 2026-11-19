

local lib = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local t1 = {
	Enabled = false,
	ReleaseTime = 0.55,
	ShootKey = Enum.KeyCode.E,
	isShooting = false
}
local t2 = {
	Enabled = false,
	GlideForce = 50,
	FloatHeight = 1.5,
	OriginalHipHeight = 2,
	GlideAttachment = nil,
	GlideVelocity = nil
}
local t3 = {
	Name = "Byte.WTF",
	LoadingTitle = "BYTE.WTF On Top",
	LoadingSubtitle = "Made By Xen",
	ConfigurationSaving = {
		Enabled = false
	},
	KeySystem = false,
	KeySettings = {
		Title = "Maddura Basketball",
		Subtitle = "Key System",
		Note = "Enter the key to access the script join discord.gg/maddura for key",
		FileName = "MadduraKeyConfig",
		Key = { "maddurabasketball" }
	}
}
local v8 = lib.CreateWindow(lib, t3)
local v9 = v8:CreateTab("Auto Timing", 4483362458)

v9:CreateParagraph({
	Title = "⚠️ Important Note",
	Content = "You have to configure the timing for the shots you want to do like fade aways, mids, and three pointers. This script isn\'t a guaranteed green and you have to have good timing for your shot. You aren\'t going to green it in someone\'s face although it\'s possible but very unlikely, and you cannot drain it from half court every time. Contest and range still matter!"
})
v9.CreateToggle(v9, {
	Name = "Auto Time Shots",
	CurrentValue = false,
	Flag = "AutoTimeToggle",
	Callback = function(p1)
		t1.Enabled = p1
	end
})
v9.CreateSlider(v9, {
	Name = "Release Time (Seconds)",
	Range = { 0.1, 1.5 },
	Increment = 0.01,
	Suffix = "s",
	CurrentValue = 0.55,
	Flag = "ReleaseTimeSlider",
	Callback = function(p2)
		t1.ReleaseTime = p2
	end
})
v9.CreateDropdown(v9, {
	Name = "Game Shoot Key",
	Options = {
		"E",
		"Space",
		"F",
		"G"
	},
	CurrentOption = "E",
	Flag = "ShootKeyDropdown",
	Callback = function(p3)
		local v10 = p3[1]

		if v10 == "E" then
			t1.ShootKey = Enum.KeyCode.E

			return
		end

		if v10 == "Space" then
			t1.ShootKey = Enum.KeyCode.Space

			return
		end

		if v10 == "F" then
			t1.ShootKey = Enum.KeyCode.F

			return
		end

		if v10 ~= "G" then
			return
		end

		t1.ShootKey = Enum.KeyCode.G
	end
})
v9.CreateKeybind(v9, {
	Name = "Trigger Auto-Shoot",
	CurrentKeybind = "CapsLock",
	HoldToInteract = false,
	Flag = "TriggerKeybind",
	Callback = function(_)
		if t1.Enabled then
			if t1.isShooting then
				return
			else
				t1.isShooting = true
				VirtualInputManager:SendKeyEvent(true, t1.ShootKey, false, game)
				task.wait(t1.ReleaseTime)
				VirtualInputManager:SendKeyEvent(false, t1.ShootKey, false, game)
				t1.isShooting = false

				return
			end
		end
	end
})

local v11 = v8:CreateTab("Dribble Glide", 4483362458)

v11.CreateToggle(v11, {
	Name = "Enable Dribble Glide",
	CurrentValue = false,
	Flag = "ExtenderToggle",
	Callback = function(p4)
		t2.Enabled = p4

		if p4 then
			return
		end

		if t2.GlideVelocity then
			t2.GlideVelocity.VectorVelocity = Vector3.new(0, 0, 0)
		end

		local Character = LocalPlayer.Character

		if Character then
			Character = Character:FindFirstChildOfClass("Humanoid")
		end

		if not Character then
			return
		end

		Character.HipHeight = t2.OriginalHipHeight
	end
})
v11.CreateSlider(v11, {
	Name = "Glide / Slide Force",
	Range = { 10, 150 },
	Increment = 5,
	Suffix = " Force",
	CurrentValue = 50,
	Flag = "GlideSlider",
	Callback = function(p5)
		t2.GlideForce = p5
	end
})
v11.CreateSlider(v11, {
	Name = "Float Height",
	Range = { 0, 5 },
	Increment = 0.25,
	Suffix = " Studs",
	CurrentValue = 1.5,
	Flag = "FloatSlider",
	Callback = function(p6)
		t2.FloatHeight = p6
	end
})

local function v13(p7)
	local Humanoid = p7:WaitForChild("Humanoid")
	local HumanoidRootPart = p7:WaitForChild("HumanoidRootPart")

	t2.OriginalHipHeight = Humanoid.HipHeight

	if not HumanoidRootPart:FindFirstChild("GlideAttachment") then
		t2.GlideAttachment = Instance.new("Attachment", HumanoidRootPart)
		t2.GlideAttachment.Name = "GlideAttachment"
		t2.GlideVelocity = Instance.new("LinearVelocity", t2.GlideAttachment)
		t2.GlideVelocity.MaxForce = 1000000
		t2.GlideVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		t2.GlideVelocity.VectorVelocity = Vector3.new(0, 0, 0)
	end

	RunService.Heartbeat:Connect(function()
		if not (not t2.Enabled or LocalPlayer.Character ~= p7) then
			Humanoid.HipHeight = t2.OriginalHipHeight + t2.FloatHeight

			local MoveDirection = Humanoid.MoveDirection

			if MoveDirection.Magnitude > 0 then
				t2.GlideVelocity.VectorVelocity = MoveDirection * t2.GlideForce

				return
			else
				t2.GlideVelocity.VectorVelocity = Vector3.new(0, 0, 0)

				return
			end
		end
	end)
end
local function v17(character)
	character:WaitForChild("HumanoidRootPart")
	character:WaitForChild("Humanoid")
	v13(character)
end

if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Connect(v17)
	lib.Notify(lib, {
		Title = "Loaded Successfully",
		Content = "All things are ready!",
		Duration = 5,
		Image = 4483362458,
		Actions = {}
	})

	return
end

v17(LocalPlayer.Character)
LocalPlayer.CharacterAdded:Connect(v17)
lib.Notify(lib, {
	Title = "Loaded Successfully",
	Content = "All things are ready!",
	Duration = 5,
	Image = 4483362458,
	Actions = {}
})
