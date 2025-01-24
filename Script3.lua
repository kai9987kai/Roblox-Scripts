local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local AGEING_RATE = 0.1 -- Age increase per second (1.0 = 100% per second)
local UPDATE_INTERVAL = 1 -- Seconds between updates

local DIRT_COLOR = Color3.new(0.3, 0.25, 0.2)
local RUST_COLOR = Color3.new(0.5, 0.3, 0.1)
local WEATHER_MATERIALS = {
    "Plastic",
    "Wood",
    "Metal",
    "Concrete"
}

local function applyDirtEffect(part, age)
    if not part:FindFirstChild("OriginalColor") then
        local colorValue = Instance.new("Color3Value")
        colorValue.Name = "OriginalColor"
        colorValue.Value = part.Color
        colorValue.Parent = part
    end

    local targetColor = part.Color:Lerp(DIRT_COLOR, math.clamp(age * 0.1, 0, 0.6))
    part.Color = targetColor
end

local function applySurfaceWeathering(part, age)
    if math.random() < age * 0.02 then
        local material = part.Material.Name
        if table.find(WEATHER_MATERIALS, material) then
            part.Material = Enum.Material[material .. "Corroded"] or Enum.Material.DiamondPlate
        end
    end
end

local function applyStructuralDamage(part, age)
    if age > 0.5 and math.random() < 0.1 then
        if part:IsA("UnionOperation") then
            part:BreakApart()
        else
            part.CanCollide = age > 0.8 and false or part.CanCollide
            part.Anchored = age > 0.7 and false or part.Anchored
        end
    end
end

local function createCracks(part)
    local crack = Instance.new("Decal")
    crack.Texture = "rbxassetid://261920162" -- Crack texture
    crack.Transparency = 0.7
    crack.Color3 = Color3.new(0.2, 0.2, 0.2)
    crack.Parent = part
end

local function ageModel(model, age)
    if age > 0.9 and math.random() < 0.3 then
        for _, child in pairs(model:GetChildren()) do
            if child:IsA("BasePart") then
                child.Parent = workspace
                child.Anchored = false
            end
        end
        model:Destroy()
    end
end

local function processObject(obj)
    if not obj:FindFirstChild("Age") then
        local ageValue = Instance.new("NumberValue")
        ageValue.Name = "Age"
        ageValue.Value = 0
        ageValue.Parent = obj
    end

    local age = obj.Age.Value
    age = age + (AGEING_RATE * UPDATE_INTERVAL)
    obj.Age.Value = age

    if obj:IsA("BasePart") then
        applyDirtEffect(obj, age)
        applySurfaceWeathering(obj, age)
        applyStructuralDamage(obj, age)
        
        if age > 0.4 and not obj:FindFirstChild("CrackDecal") then
            createCracks(obj)
        end
    elseif obj:IsA("Model") then
        ageModel(obj, age)
    end
end

local function initializeAgeing()
    while true do
        task.wait(UPDATE_INTERVAL)
        
        -- Process all eligible objects
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj:IsA("BasePart") or obj:IsA("Model")) and obj.Parent == workspace then
                coroutine.wrap(processObject)(obj)
            end
        end
    end
end

-- Start ageing system
initializeAgeing()
