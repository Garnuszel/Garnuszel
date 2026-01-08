local RegisteredServerCallbacks = {}
local RegisteredEventHandlers = {}
local ActiveClientCallbacks = {}
local ClientCallbackId = 0

Core = Core or {}
Core.Callbacks = Core.Callbacks or {}
Core.Callbacks.Server = Core.Callbacks.Server or {}
Core.Callbacks.Client = Core.Callbacks.Client or {}
Core.Callbacks.Client.Async = Core.Callbacks.Client.Async or {}
Core.Callbacks.Client.Await = Core.Callbacks.Client.Await or {}

local CLIENT_EVENT_FORMAT = "rev-core:cb:client:%s"
local SERVER_EVENT_FORMAT = "rev-core:cb:server:%s"

function Core.Callbacks.Server:RegisterCallback(eventName, callback)
    local eventHandler = SERVER_EVENT_FORMAT:format(eventName)
    local existingHandler = RegisteredEventHandlers[eventHandler]

    if existingHandler then
        print(string.format("Overwriting server callback %s", eventName))
        RemoveEventHandler(existingHandler)
    end

    RegisteredServerCallbacks[eventName] = callback
    RegisteredEventHandlers[eventHandler] = RegisterNetEvent(eventHandler, function(serverCallbackId, ...)
        local src = source
        local results = { RegisteredServerCallbacks[eventName](src, ...) }
        TriggerClientEvent("rev-core:serverCallbackReturn", src, serverCallbackId, table.unpack(results))
    end)
end

function Core.Callbacks.Client.Async(eventName, target, callback, ...)
    local formattedEvent = CLIENT_EVENT_FORMAT:format(eventName)
    ClientCallbackId = ClientCallbackId + 1

    ActiveClientCallbacks[ClientCallbackId] = {
        type = "async",
        callback = callback,
        source = target
    }

    TriggerClientEvent(formattedEvent, target, ClientCallbackId, ...)
end

function Core.Callbacks.Client.Await(eventName, target, ...)
    local formattedEvent = CLIENT_EVENT_FORMAT:format(eventName)
    ClientCallbackId = ClientCallbackId + 1

    local p = promise.new()
    ActiveClientCallbacks[ClientCallbackId] = {
        type = "await",
        promise = p,
        source = target
    }

    TriggerClientEvent(formattedEvent, target, ClientCallbackId, ...)
    local result = Citizen.Await(p)
    return table.unpack(result)
end

RegisterNetEvent("rev-core:clientCallbackReturn", function(callbackId, ...)
    local callbackData = ActiveClientCallbacks[callbackId]

    if callbackData then
        if callbackData.type == "async" then
            callbackData.callback(...)
        elseif callbackData.type == "await" then
            callbackData.promise:resolve({...})
        end

        ActiveClientCallbacks[callbackId] = nil
    end
end)
