local RunService = game:GetService("RunService")
local ScriptContext = game:GetService("ScriptContext")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

-- Configuration
local MAX_PARALLEL_SCRIPTS = 50
local ERROR_CORRECTION_DELAY = 0.1
local SAFE_MEMORY_LIMIT = 10^6 -- 1MB

-- Runtime state
local scriptQueue = {}
local activeScripts = {}
local errorRegistry = {}
local protectedProperties = {}

local function createSandbox(scriptObj)
    local env = getfenv(0)
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)
    
    mt.__index = function(_, key)
        if protectedProperties[key] then
            error("Protected property access: "..key)
        end
        return env[key]
    end
    
    mt.__newindex = function(_, key, value)
        if protectedProperties[key] then
            error("Protected property modification: "..key)
        end
        env[key] = value
    end
    
    return setmetatable({script=scriptObj}, mt)
end

local function heuristicPatch(errorMsg, stackTrace)
    -- Common error pattern matching
    if errorMsg:find("attempt to index nil") then
        local varName = errorMsg:match("'(.+)'")
        return [[
            local ]]..varName..[[ = ]]..varName..[[ or {}
            setmetatable(]]..varName..[[, {__mode = "v"})
        ]]
    end
    
    if errorMsg:find("Invalid property") then
        local prop, class = errorMsg:match("'(.+)'.+class '(.+)'")
        return string.format([[
            if not %s:IsA("%s") then
                %s.%s = nil
            end
        ]], "script", class, "script", prop)
    end
    
    if errorMsg:find("Infinite yield") then
        return [[
            wait():Timeout(5)
        ]]
    end
    
    return nil
end

local function runScriptSafe(scriptObj)
    local success, result = pcall(function()
        -- Memory guard
        debug.setmemorycategory(scriptObj:GetFullName())
        debug.setmemorymax(SAFE_MEMORY_LIMIT)
        
        -- Create execution environment
        local env = createSandbox(scriptObj)
        local fn = loadstring(scriptObj.Source, scriptObj:GetFullName())
        setfenv(fn, env)
        
        -- Parallel yield management
        coroutine.wrap(function()
            while true do
                wait(5)
                env.script:SetAttribute("Heartbeat", tick())
            end
        end)()
        
        return fn()
    end)
    
    if not success then
        local errorId = HttpService:GenerateGUID()
        errorRegistry[errorId] = {
            message = result,
            script = scriptObj,
            timestamp = tick(),
            corrections = 0
        }
        
        -- Attempt automatic correction
        local correction = heuristicPatch(result, debug.traceback())
        if correction then
            wait(ERROR_CORRECTION_DELAY)
            scriptObj.Source = correction.."\n-- Auto-corrected error: "..errorId.."\n"..scriptObj.Source
            errorRegistry[errorId].corrections += 1
            runScriptSafe(scriptObj)
        end
    end
end

local function conflictResolver(scriptObj)
    -- Property access tracking
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)
    
    mt.__index = function(_, key)
        protectedProperties[key] = true
        return game:GetService(key) or game[key]
    end
    
    mt.__newindex = function(_, key, value)
        if protectedProperties[key] then
            warn("Conflict detected on "..key.." - Using queued modification")
            delay(0, function() 
                rawset(game, key, value) 
            end)
        else
            rawset(game, key, value)
        end
    end
    
    return proxy
end

local function manageScriptExecution()
    while #scriptQueue > 0 do
        if #activeScripts < MAX_PARALLEL_SCRIPTS then
            local scriptObj = table.remove(scriptQueue, 1)
            local thread = coroutine.create(runScriptSafe)
            activeScripts[scriptObj] = {
                thread = thread,
                env = conflictResolver(scriptObj)
            }
            
            coroutine.resume(thread, scriptObj)
        end
        wait()
    end
end

-- Main system initialization
game.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("LuaSourceContainer") then
        table.insert(scriptQueue, descendant)
    end
end)

for _, scriptObj in ipairs(game:GetDescendants()) do
    if scriptObj:IsA("LuaSourceContainer") then
        table.insert(scriptQueue, scriptObj)
    end
end

coroutine.wrap(manageScriptExecution)()
