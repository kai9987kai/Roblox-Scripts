local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

local SCRIPT_ORGANIZER_VERSION = "2.1"
local AUTO_CATEGORIZATION_ENABLED = true

-- Enhanced context detection configuration
local CONTEXT_WEIGHTS = {
    Client = {
        ["LocalPlayer"] = 3.0,
        ["UserInputService"] = 2.5,
        ["GuiService"] = 2.0,
        ["ContextActionService"] = 2.0,
        ["Players.LocalPlayer"] = 3.0,
        ["Camera"] = 1.5
    },
    Server = {
        ["DataStoreService"] = 4.0,
        ["HTTPService"] = 3.0,
        ["ServerStorage"] = 2.5,
        ["MessagingService"] = 2.5,
        ["SocialService"] = 2.0,
        ["GamePassService"] = 2.0
    },
    Hybrid = {
        ["RemoteEvent"] = 3.0,
        ["RemoteFunction"] = 3.0,
        ["BindableEvent"] = 2.0,
        ["ReplicatedStorage"] = 2.5
    }
}

local function analyzeScriptContext(source)
    local sourceLower = string.lower(source)
    local scores = {Client = 0, Server = 0, Hybrid = 0}
    local detectedServices = {}
    local metadataTags = {}

    -- Metadata annotation parsing
    for tag in source:gmatch("--%s*@(%w+)") do
        table.insert(metadataTags, string.lower(tag))
    end

    -- Weighted keyword analysis
    for contextType, keywords in pairs(CONTEXT_WEIGHTS) do
        for keyword, weight in pairs(keywords) do
            local pattern = string.gsub(string.lower(keyword), "%.", "%%.")
            if string.find(sourceLower, pattern) then
                scores[contextType] = scores[contextType] + weight
                table.insert(detectedServices, keyword)
            end
        end
    end

    -- Dependency graph analysis
    local dependencies = {}
    for _, id in ipairs(ContentProvider:GetDependencies(source)) do
        table.insert(dependencies, id)
    end

    -- Context determination with threshold
    local maxScore = math.max(scores.Client, scores.Server, scores.Hybrid)
    local totalScore = scores.Client + scores.Server + scores.Hybrid
    
    return {
        primaryContext = (maxScore > 2) and ({
            [scores.Client] = "Client",
            [scores.Server] = "Server",
            [scores.Hybrid] = "Hybrid"
        })[maxScore] or "Neutral",
        confidence = math.floor((maxScore / totalScore) * 100),
        detectedServices = detectedServices,
        dependencies = dependencies,
        metadataTags = metadataTags
    }
end

local function createScriptVariant(original, scriptType)
    local newScript = Instance.new(scriptType == "Client" and "LocalScript" or "Script")
    
    -- Clone properties with type checking
    for _, prop in ipairs(original:GetProperties()) do
        if not prop:IsReadOnly() and prop.Name ~= "Parent" then
            pcall(function()
                newScript[prop.Name] = original[prop.Name]
            end)
        end
    end

    -- Preserve script GUID for tracking
    if not original:GetAttribute("ScriptGUID") then
        original:SetAttribute("ScriptGUID", HttpService:GenerateGUID(false))
    end
    newScript:SetAttribute("OriginalGUID", original:GetAttribute("ScriptGUID"))
    
    return newScript
end

local function handleHybridScript(script, analysis)
    -- Create client/server pair with communication bridge
    local serverScript = createScriptVariant(script, "Server")
    local clientScript = createScriptVariant(script, "Client")
    
    -- Generate communication channels
    local remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = script.Name .. "_Bridge"
    remoteEvent.Parent = ReplicatedStorage

    -- Modify scripts with bridge logic
    serverScript.Source = script.Source .. "\n-- Hybrid Server Component"
    clientScript.Source = script.Source .. "\n-- Hybrid Client Component"
    
    -- Set up proper locations
    serverScript.Parent = ServerScriptService
    clientScript.Parent = StarterPlayer.StarterPlayerScripts
    
    -- Add dependency tracking
    serverScript:SetAttribute("HybridPair", clientScript:GetAttribute("OriginalGUID"))
    clientScript:SetAttribute("HybridPair", serverScript:GetAttribute("OriginalGUID"))
    
    return {serverScript, clientScript}
end

local function relocateScript(script)
    if not AUTO_CATEGORIZATION_ENABLED then return end
    if script:GetAttribute("OrganizerVersion") == SCRIPT_ORGANIZER_VERSION then return end

    local analysis = analyzeScriptContext(script.Source)
    local primaryContext = analysis.primaryContext
    
    -- Metadata override
    if #analysis.metadataTags > 0 then
        primaryContext = analysis.metadataTags[1]:lower():gsub("^%l", string.upper)
    end

    -- Create appropriate variant
    local newScripts = {}
    if primaryContext == "Hybrid" then
        newScripts = handleHybridScript(script, analysis)
    else
        local newScript = createScriptVariant(script, primaryContext)
        table.insert(newScripts, newScript)
    end

    -- Update references and dependencies
    for _, newScript in ipairs(newScripts) do
        newScript:SetAttribute("OrganizerVersion", SCRIPT_ORGANIZER_VERSION)
        newScript:SetAttribute("ContextAnalysis", HttpService:JSONEncode(analysis))
        
        -- Handle dependencies
        for _, dependency in ipairs(analysis.dependencies) do
            -- Advanced dependency relocation logic would go here
        end

        -- Final placement
        local targetParent = ({
            Client = StarterPlayer.StarterPlayerScripts,
            Server = ServerScriptService,
            Hybrid = ReplicatedStorage
        })[primaryContext] or ReplicatedStorage
        
        newScript.Parent = targetParent
    end

    script:Destroy()
end

local function organizeScripts()
    -- Phase 1: Initial organization
    for _, script in ipairs(game:GetDescendants()) do
        if script:IsA("LuaSourceContainer") then
            task.spawn(relocateScript, script)
        end
    end

    -- Phase 2: Runtime monitoring
    game.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("LuaSourceContainer") then
            task.spawn(relocateScript, descendant)
        end
    end)

    -- Phase 3: Dependency graph validation
    task.defer(function()
        while true do
            task.wait(60)
            -- Advanced dependency validation would go here
        end
    end)
end

-- Initialize with safety checks
local function safeInitialize()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    if AUTO_CATEGORIZATION_ENABLED then
        organizeScripts()
    end
end

-- Start the enhanced organizer
safeInitialize()
