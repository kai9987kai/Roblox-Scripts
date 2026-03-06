--[[
    TycoonGui.client — Client-Side HUD & Notifications
    =====================================================
    Place this as a LocalScript inside StarterPlayerScripts.

    Displays:
      • Cash counter (top of screen)
      • Rebirth button (bottom-right)
      • Notification popups (animated toasts)
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("TycoonRemotes")
local CashUpdateEvent     = Remotes:WaitForChild("CashUpdate")
local NotificationEvent   = Remotes:WaitForChild("Notification")
local RebirthRequestEvent = Remotes:WaitForChild("RebirthRequest")
local RebirthInfoEvent    = Remotes:WaitForChild("RebirthInfo")

---------------------------------------------------------------------------
-- CREATE SCREEN GUI
---------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TycoonHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

---------------------------------------------------------------------------
-- CASH DISPLAY (top center)
---------------------------------------------------------------------------
local cashFrame = Instance.new("Frame")
cashFrame.Name = "CashFrame"
cashFrame.Size = UDim2.new(0, 320, 0, 70)
cashFrame.Position = UDim2.new(0.5, -160, 0, 16)
cashFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
cashFrame.BackgroundTransparency = 0.15
cashFrame.BorderSizePixel = 0
cashFrame.Parent = screenGui

local cashCorner = Instance.new("UICorner")
cashCorner.CornerRadius = UDim.new(0, 16)
cashCorner.Parent = cashFrame

local cashGradient = Instance.new("UIGradient")
cashGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25)),
})
cashGradient.Rotation = 90
cashGradient.Parent = cashFrame

local cashStroke = Instance.new("UIStroke")
cashStroke.Color = Color3.fromRGB(255, 215, 0)
cashStroke.Thickness = 2
cashStroke.Transparency = 0.3
cashStroke.Parent = cashFrame

local cashIcon = Instance.new("TextLabel")
cashIcon.Name = "CashIcon"
cashIcon.Size = UDim2.new(0, 50, 1, 0)
cashIcon.Position = UDim2.new(0, 8, 0, 0)
cashIcon.BackgroundTransparency = 1
cashIcon.Text = "💰"
cashIcon.TextSize = 32
cashIcon.Font = Enum.Font.GothamBold
cashIcon.TextColor3 = Color3.new(1, 1, 1)
cashIcon.Parent = cashFrame

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(1, -66, 1, 0)
cashLabel.Position = UDim2.new(0, 58, 0, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "$0"
cashLabel.TextSize = 34
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = cashFrame

---------------------------------------------------------------------------
-- REBIRTH BUTTON (bottom right)
---------------------------------------------------------------------------
local rebirthFrame = Instance.new("Frame")
rebirthFrame.Name = "RebirthFrame"
rebirthFrame.Size = UDim2.new(0, 200, 0, 80)
rebirthFrame.Position = UDim2.new(1, -216, 1, -96)
rebirthFrame.BackgroundColor3 = Color3.fromRGB(25, 10, 40)
rebirthFrame.BackgroundTransparency = 0.1
rebirthFrame.BorderSizePixel = 0
rebirthFrame.Parent = screenGui

local rebirthCorner = Instance.new("UICorner")
rebirthCorner.CornerRadius = UDim.new(0, 14)
rebirthCorner.Parent = rebirthFrame

local rebirthGrad = Instance.new("UIGradient")
rebirthGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 20, 180)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 5, 80)),
})
rebirthGrad.Rotation = 135
rebirthGrad.Parent = rebirthFrame

local rebirthStroke = Instance.new("UIStroke")
rebirthStroke.Color = Color3.fromRGB(180, 100, 255)
rebirthStroke.Thickness = 2
rebirthStroke.Transparency = 0.2
rebirthStroke.Parent = rebirthFrame

local rebirthTitle = Instance.new("TextLabel")
rebirthTitle.Name = "Title"
rebirthTitle.Size = UDim2.new(1, 0, 0, 28)
rebirthTitle.Position = UDim2.new(0, 0, 0, 4)
rebirthTitle.BackgroundTransparency = 1
rebirthTitle.Text = "🌟 Rebirth"
rebirthTitle.TextSize = 20
rebirthTitle.Font = Enum.Font.GothamBold
rebirthTitle.TextColor3 = Color3.fromRGB(220, 180, 255)
rebirthTitle.Parent = rebirthFrame

local rebirthCostLabel = Instance.new("TextLabel")
rebirthCostLabel.Name = "CostLabel"
rebirthCostLabel.Size = UDim2.new(1, 0, 0, 18)
rebirthCostLabel.Position = UDim2.new(0, 0, 0, 30)
rebirthCostLabel.BackgroundTransparency = 1
rebirthCostLabel.Text = "Cost: $100,000"
rebirthCostLabel.TextSize = 14
rebirthCostLabel.Font = Enum.Font.Gotham
rebirthCostLabel.TextColor3 = Color3.fromRGB(180, 150, 220)
rebirthCostLabel.Parent = rebirthFrame

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthBtn"
rebirthButton.Size = UDim2.new(0.8, 0, 0, 26)
rebirthButton.Position = UDim2.new(0.1, 0, 1, -32)
rebirthButton.BackgroundColor3 = Color3.fromRGB(140, 60, 255)
rebirthButton.BorderSizePixel = 0
rebirthButton.Text = "REBIRTH"
rebirthButton.TextSize = 16
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.TextColor3 = Color3.new(1, 1, 1)
rebirthButton.AutoButtonColor = true
rebirthButton.Parent = rebirthFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = rebirthButton

-- Hover effect
rebirthButton.MouseEnter:Connect(function()
    TweenService:Create(rebirthButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(170, 90, 255)
    }):Play()
end)
rebirthButton.MouseLeave:Connect(function()
    TweenService:Create(rebirthButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(140, 60, 255)
    }):Play()
end)

rebirthButton.MouseButton1Click:Connect(function()
    RebirthRequestEvent:FireServer()
end)

---------------------------------------------------------------------------
-- NOTIFICATION SYSTEM (animated toasts)
---------------------------------------------------------------------------
local notifContainer = Instance.new("Frame")
notifContainer.Name = "Notifications"
notifContainer.Size = UDim2.new(0, 400, 1, 0)
notifContainer.Position = UDim2.new(0.5, -200, 0, 0)
notifContainer.BackgroundTransparency = 1
notifContainer.Parent = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0, 8)
notifLayout.Parent = notifContainer

local notifQueue = 0

local function showNotification(text, isPositive)
    notifQueue = notifQueue + 1
    local order = notifQueue

    local notif = Instance.new("Frame")
    notif.Name = "Notif_" .. order
    notif.Size = UDim2.new(1, 0, 0, 44)
    notif.BackgroundColor3 = isPositive and Color3.fromRGB(20, 60, 30) or Color3.fromRGB(70, 20, 20)
    notif.BackgroundTransparency = 0.15
    notif.BorderSizePixel = 0
    notif.LayoutOrder = order
    notif.Parent = notifContainer

    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = UDim.new(0, 10)
    nCorner.Parent = notif

    local nStroke = Instance.new("UIStroke")
    nStroke.Color = isPositive and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(244, 67, 54)
    nStroke.Thickness = 1.5
    nStroke.Parent = notif

    local nLabel = Instance.new("TextLabel")
    nLabel.Size = UDim2.new(1, -16, 1, 0)
    nLabel.Position = UDim2.new(0, 8, 0, 0)
    nLabel.BackgroundTransparency = 1
    nLabel.Text = text
    nLabel.TextSize = 18
    nLabel.Font = Enum.Font.GothamBold
    nLabel.TextColor3 = Color3.new(1, 1, 1)
    nLabel.TextXAlignment = Enum.TextXAlignment.Left
    nLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nLabel.Parent = notif

    -- Slide in from right
    notif.Position = UDim2.new(1, 0, 0, 0)
    TweenService:Create(notif, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    -- Fade out after 3 seconds
    task.delay(3, function()
        local fadeOut = TweenService:Create(notif, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
        })
        TweenService:Create(nLabel, TweenInfo.new(0.5), {
            TextTransparency = 1,
        }):Play()
        TweenService:Create(nStroke, TweenInfo.new(0.5), {
            Transparency = 1,
        }):Play()
        fadeOut:Play()
        fadeOut.Completed:Wait()
        notif:Destroy()
    end)
end

---------------------------------------------------------------------------
-- FORMAT NUMBER
---------------------------------------------------------------------------
local function formatCash(n)
    if n >= 1000000000 then
        return string.format("$%.1fB", n / 1000000000)
    elseif n >= 1000000 then
        return string.format("$%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("$%.1fK", n / 1000)
    else
        return "$" .. tostring(n)
    end
end

---------------------------------------------------------------------------
-- EVENT HANDLERS
---------------------------------------------------------------------------
CashUpdateEvent.OnClientEvent:Connect(function(cash, rebirths)
    -- Animate the cash label
    local oldText = cashLabel.Text
    cashLabel.Text = formatCash(cash)

    -- Pulse effect
    TweenService:Create(cashLabel, TweenInfo.new(0.1), {
        TextSize = 40,
    }):Play()
    task.delay(0.1, function()
        TweenService:Create(cashLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextSize = 34,
        }):Play()
    end)
end)

NotificationEvent.OnClientEvent:Connect(function(text, isPositive)
    showNotification(text, isPositive)
end)

RebirthInfoEvent.OnClientEvent:Connect(function(rebirths, cost)
    rebirthTitle.Text = "🌟 Rebirth #" .. (rebirths + 1)
    rebirthCostLabel.Text = "Cost: " .. formatCash(cost)
end)

---------------------------------------------------------------------------
-- INTRO SPLASH
---------------------------------------------------------------------------
task.delay(1, function()
    showNotification("🏭 Welcome to Factory Tycoon! Claim a plot to start!", true)
end)

print("[TycoonGui] HUD loaded!")
