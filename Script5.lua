--// DepthOfFieldController (LocalScript in StarterPlayerScripts)

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Create the DepthOfField effect (if one doesn't already exist)
local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "PlayerFocusDOF"
dof.Parent = Lighting

-- Adjust the blur intensities as desired
dof.FarIntensity = 0.75     -- how strong the blur is for distant objects
dof.NearIntensity = 0.5     -- how strong the blur is for objects very close
dof.InFocusRadius = 10      -- how wide the "sharp" zone is around the focus distance
dof.FocusDistance = 20      -- initial guess for focus distance

RunService.RenderStepped:Connect(function()
	-- Make sure we have a character and HumanoidRootPart
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local rootPart = player.Character.HumanoidRootPart
	-- Calculate distance from camera to player's root
	local distance = (camera.CFrame.Position - rootPart.Position).Magnitude

	-- Set the DepthOfField focus distance to match that
	dof.FocusDistance = distance
end)
