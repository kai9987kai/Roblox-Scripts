local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TS = game:GetService("TweenService")

--------------------------------------------------------------------------------
-- HYPERPARAMETERS
--------------------------------------------------------------------------------
local WORLD = {
    SPAWN_AREA = Vector3.new(500, 0, 500),
    MAX_ENTITIES = 200,
    BASE_MUTATION_RATE = 0.15,
    WEATHER_INFLUENCE_RADIUS = 300,
    PLAYER_THREAT_RADIUS = 45
}

local AGENT = {
    SIZE = Vector3.new(4,6,4),
    BASE_SPEED = 18,
    SENSOR_RANGE = 80,
    NEURAL_NODES = {4, 6, 4},  -- Input, Hidden, Output
    MEMORY_CAPACITY = 20
}

local ENV_VARS = {
    WEATHER_STATES = {
        STORM = {color=Color3.new(0.2,0.2,0.8), speedMult=0.7},
        DROUGHT = {color=Color3.new(0.8,0.5,0.2), energyDrain=0.3},
        BLIZZARD = {color=Color3.new(0.8,0.8,1), speedMult=0.5}
    },
    WORLD_PARAMS = {
        GRAVITY = workspace.Gravity,
        TIME_SCALE = 1
    }
}

--------------------------------------------------------------------------------
-- QUANTUM NEURAL AGENT
--------------------------------------------------------------------------------
local QAgent = {}
QAgent.__index = QAgent

function QAgent.new(generation)
    local self = setmetatable({}, QAgent)
    
    -- Neural Network
    self.brain = {
        weights1 = self:InitializeWeights(AGENT.NEURAL_NODES[1], AGENT.NEURAL_NODES[2]),
        weights2 = self:InitializeWeights(AGENT.NEURAL_NODES[2], AGENT.NEURAL_NODES[3]),
        bias1 = math.random(),
        bias2 = math.random()
    }
    
    -- Evolutionary Traits
    self.dna = {
        generation = generation or 1,
        weatherResistance = math.random(),
        playerThreatResponse = math.random(),
        environmentalInfluence = math.random()
    }
    
    -- World Interaction
    self.position = Vector3.new(
        math.random(-WORLD.SPAWN_AREA.X/2, WORLD.SPAWN_AREA.X/2),
        0,
        math.random(-WORLD.SPAWN_AREA.Z/2, WORLD.SPAWN_AREA.Z/2)
    )
    
    self:InitializeBody()
    self:ApplyMutations()
    return self
end

function QAgent:InitializeBody()
    self.part = Instance.new("Part")
    self.part.Shape = Enum.PartType.Block
    self.part.Size = AGENT.SIZE
    self.part.Color = Color3.new(0.8, 0.2, 0.2)
    self.part.Position = self.position
    self.part.Parent = workspace

    self.gui = Instance.new("BillboardGui")
    self.gui.Size = UDim2.new(4,0,2,0)
    self.gui.Adornee = self.part
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1,0,1,0)
    text.BackgroundTransparency = 1
    text.Text = "Gen: "..self.dna.generation
    text.Parent = self.gui
end

function QAgent:ForwardPropagate(inputs)
    local hidden = {}
    for i=1, AGENT.NEURAL_NODES[2] do
        local sum = self.brain.bias1
        for j=1, #inputs do
            sum += inputs[j] * self.brain.weights1[j][i]
        end
        hidden[i] = math.tanh(sum)
    end
    
    local output = {}
    for i=1, AGENT.NEURAL_NODES[3] do
        local sum = self.brain.bias2
        for j=1, #hidden do
            sum += hidden[j] * self.brain.weights2[j][i]
        end
        output[i] = 1/(1+math.exp(-sum))  -- Sigmoid
    end
    
    return output
end

function QAgent:BackPropagate(inputs, target)
    -- Deep Q-learning implementation
    local prediction = self:ForwardPropagate(inputs)
    local error = {}
    
    -- Calculate output errors
    for i=1, #prediction do
        error[i] = target[i] - prediction[i]
    end
    
    -- Update weights (simplified)
    for i=1, #self.brain.weights2 do
        for j=1, #self.brain.weights2[i] do
            self.brain.weights2[i][j] += error[j] * 0.1  -- Learning rate
        end
    end
end

--------------------------------------------------------------------------------
-- ENVIRONMENT CONTROLLER
--------------------------------------------------------------------------------
local World = {
    agents = {},
    players = {},
    resources = {},
    currentWeather = ENV_VARS.WEATHER_STATES.STORM,
    influenceZones = {}
}

function World:ApplyAgentInfluence()
    for _, agent in pairs(self.agents) do
        if agent.dna.environmentalInfluence > 0.7 then
            -- Create weather influence zone
            table.insert(self.influenceZones, {
                position = agent.position,
                radius = WORLD.WEATHER_INFLUENCE_RADIUS,
                effect = {
                    weatherChange = agent.dna.weatherResistance > 0.5 
                        and "CLEAR" 
                        or "STORM",
                    gravityMod = 0.5 + agent.dna.environmentalInfluence
                }
            })
        end
    end
    
    -- Update global weather based on influences
    local positiveInfluence = 0
    for _, zone in pairs(self.influenceZones) do
        positiveInfluence += zone.effect.weatherChange == "CLEAR" and 1 or -1
    end
    
    if positiveInfluence > #self.influenceZones/2 then
        self.currentWeather = ENV_VARS.WEATHER_STATES.DROUGHT
    else
        self.currentWeather = ENV_VARS.WEATHER_STATES.STORM
    end
end

function World:HandlePlayerInteraction()
    for _, player in pairs(Players:GetPlayers()) do
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local playerPos = char.HumanoidRootPart.Position
            
            -- Update agent memories about player positions
            for _, agent in pairs(self.agents) do
                local dist = (agent.position - playerPos).Magnitude
                if dist < WORLD.PLAYER_THREAT_RADIUS then
                    table.insert(agent.memory, {
                        type = "PLAYER_THREAT",
                        position = playerPos,
                        timestamp = time()
                    })
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- ADAPTIVE LEARNING SYSTEM
--------------------------------------------------------------------------------
local Learning = {
    rewardQueue = {},
    mutationSchedule = {},
    populationDiversity = 1.0
}

function Learning:CalculateReward(agent, action)
    local reward = 0
    
    -- Environmental adaptation reward
    reward += agent.dna.weatherResistance * 2
    
    -- Player threat avoidance reward
    local nearestPlayer = 9999
    for _, player in pairs(World.players) do
        local dist = (agent.position - player.position).Magnitude
        if dist < nearestPlayer then nearestPlayer = dist end
    end
    reward += (WORLD.PLAYER_THREAT_RADIUS - nearestPlayer)/10
    
    -- Resource gathering reward
    reward += #agent.inventory * 3
    
    return reward
end

function Learning:AdaptiveMutation(agent)
    local mutationRate = WORLD.BASE_MUTATION_RATE * (1 - Learning.populationDiversity)
    
    if math.random() < mutationRate then
        -- Structural mutation
        local layer = math.random(2)
        local neuron = math.random(AGENT.NEURAL_NODES[layer])
        
        if layer == 1 then
            agent.brain.weights1[neuron][math.random(AGENT.NEURAL_NODES[2])] = math.random(-1,1)
        else
            agent.brain.weights2[neuron][math.random(AGENT.NEURAL_NODES[3])] = math.random(-1,1)
        end
    end
end

--------------------------------------------------------------------------------
-- SIMULATION INITIALIZATION
--------------------------------------------------------------------------------
function Initialize()
    -- Spawn initial population
    for i=1, 30 do
        table.insert(World.agents, QAgent.new(1))
    end
    
    -- Player connection handler
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            table.insert(World.players, {
                player = player,
                position = char:WaitForChild("HumanoidRootPart").Position
            })
        end)
    end)

    -- Main simulation loop
    RunService.Heartbeat:Connect(function(dt)
        World:ApplyAgentInfluence()
        World:HandlePlayerInteraction()
        
        -- Agent decision cycle
        for _, agent in pairs(World.agents) do
            -- Neural network input
            local inputs = {
                agent.dna.weatherResistance,
                agent.dna.playerThreatResponse,
                #agent.memory/AGENT.MEMORY_CAPACITY,
                agent.energy/100
            }
            
            local outputs = agent:ForwardPropagate(inputs)
            
            -- Execute best action
            local bestAction = outputs[1]
            for i, val in pairs(outputs) do
                if val > bestAction then
                    bestAction = i
                end
            end
            
            -- Action execution
            if bestAction == 1 then
                agent:SeekResource()
            elseif bestAction == 2 then
                agent:FleePlayers()
            elseif bestAction == 3 then
                agent:InfluenceEnvironment()
            end
            
            -- Learning update
            Learning:AdaptiveMutation(agent)
        end
        
        -- Environmental updates
        Lighting.Ambient = World.currentWeather.color
        workspace.Gravity = ENV_VARS.WORLD_PARAMS.GRAVITY * 
            (World.currentWeather.gravityMod or 1)
    end)
end

Initialize()
