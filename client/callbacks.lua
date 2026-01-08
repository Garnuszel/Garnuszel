local RegisteredClientCallbacks = {}
local RegisteredEventHandlers = {}
local ActiveServerCallbacks = {}
local ServerCallbackId = 0

Core = Core or {}
Core.Callbacks = Core.Callbacks or {}
Core.Callbacks.Client = Core.Callbacks.Client or {}
Core.Callbacks.Server = Core.Callbacks.Server or {}
Core.Callbacks.Server.Async = Core.Callbacks.Server.Async or {}
Core.Callbacks.Server.Await = Core.Callbacks.Server.Await or {}

local CLIENT_EVENT_FORMAT = "rev-core:cb:client:%s"
local SERVER_EVENT_FORMAT = "rev-core:cb:server:%s"

function Core.Callbacks.Client:RegisterCallback(eventName, callback)
    local eventHandler = CLIENT_EVENT_FORMAT:format(eventName)
    local existingHandler = RegisteredEventHandlers[eventHandler]

    if existingHandler then
        print(string.format("Overwriting client callback %s", eventName))
        RemoveEventHandler(existingHandler)
    end

    RegisteredClientCallbacks[eventName] = callback
    RegisteredEventHandlers[eventHandler] = RegisterNetEvent(eventHandler, function(callbackId, ...)
        local result = { RegisteredClientCallbacks[eventName](...) }
        TriggerServerEvent("rev-core:clientCallbackReturn", callbackId, table.unpack(result))
    end)
end

function Core.Callbacks.Server.Async(eventName, callback, ...)
    local formattedEvent = SERVER_EVENT_FORMAT:format(eventName)
    ServerCallbackId = ServerCallbackId + 1

    ActiveServerCallbacks[ServerCallbackId] = {
        type = "async",
        callback = callback
    }

    TriggerServerEvent(formattedEvent, ServerCallbackId, ...)
end

function Core.Callbacks.Server.Await(eventName, ...)
    local formattedEvent = SERVER_EVENT_FORMAT:format(eventName)
    ServerCallbackId = ServerCallbackId + 1

    local p = promise.new()
    ActiveServerCallbacks[ServerCallbackId] = {
        type = "await",
        promise = p
    }

    TriggerServerEvent(formattedEvent, ServerCallbackId, ...)
    local result = Citizen.Await(p)
    return table.unpack(result)
end

RegisterNetEvent("rev-core:serverCallbackReturn", function(serverCallbackId, ...)
    local callbackData = ActiveServerCallbacks[serverCallbackId]

    if callbackData then
        if callbackData.type == "async" then
            callbackData.callback(...)
        elseif callbackData.type == "await" then
            callbackData.promise:resolve({...})
        end

        ActiveServerCallbacks[serverCallbackId] = nil
    end
end)
