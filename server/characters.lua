Core = Core or {}
Core.Characters = Core.Characters or {}
Core.Players = Core.Players or {}

local CharacterStore = {}

local function getIdentifier(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local identifier = GetPlayerIdentifier(src, i)
        if identifier and identifier:find("license:") then
            return identifier
        end
    end

    return ("temp:%s"):format(src)
end

local function getCharacterList(identifier)
    CharacterStore[identifier] = CharacterStore[identifier] or {}
    return CharacterStore[identifier]
end

local function attachPlayer(source, character)
    Core.Players[source] = Core.Players[source] or {}
    Core.Players[source].identifier = getIdentifier(source)
    Core.Players[source].character = character

    TriggerClientEvent("rev-core:setPlayerValue", source, "character", character)
end

Core.Characters.Create = function(source, data)
    local identifier = getIdentifier(source)
    local characters = getCharacterList(identifier)
    local charId = (os.time() % 100000) .. tostring(#characters + 1)

    local character = {
        id = charId,
        firstname = data.firstname or "John",
        lastname = data.lastname or "Doe",
        dateofbirth = data.dateofbirth or "1990-01-01",
        job = data.job or "unemployed",
        job_grade = data.job_grade or 0,
        money = {
            cash = data.cash or 0,
            bank = data.bank or 0
        },
        position = data.position or { x = 0.0, y = 0.0, z = 0.0 }
    }

    table.insert(characters, character)
    attachPlayer(source, character)
    return character
end

Core.Characters.GetForSource = function(source)
    local identifier = getIdentifier(source)
    return getCharacterList(identifier)
end

Core.Characters.Select = function(source, charId)
    local identifier = getIdentifier(source)
    local characters = getCharacterList(identifier)

    for _, character in ipairs(characters) do
        if tostring(character.id) == tostring(charId) then
            attachPlayer(source, character)
            return character
        end
    end

    return nil
end

Core.Characters.Delete = function(source, charId)
    local identifier = getIdentifier(source)
    local characters = getCharacterList(identifier)

    Core.Utils.ArrayRemove(characters, function(_, readIndex)
        return tostring(characters[readIndex].id) ~= tostring(charId)
    end)

    if Core.Players[source] and Core.Players[source].character and tostring(Core.Players[source].character.id) == tostring(charId) then
        Core.Players[source].character = nil
        TriggerClientEvent("rev-core:setPlayerValue", source, "character", nil)
    end

    return characters
end

Core.Characters.SaveValue = function(source, key, value)
    local player = Core.Players[source]
    if not player or not player.character then return false end

    player.character[key] = value
    TriggerClientEvent("rev-core:setPlayerValue", source, key, value)
    return true
end

-- Callback endpoints
Core.Callbacks.Server:RegisterCallback("characters:get", function(src)
    local characters = Core.Characters.GetForSource(src)
    return characters
end)

Core.Callbacks.Server:RegisterCallback("characters:create", function(src, data)
    local character = Core.Characters.Create(src, data or {})
    return character
end)

Core.Callbacks.Server:RegisterCallback("characters:select", function(src, charId)
    return Core.Characters.Select(src, charId)
end)

Core.Callbacks.Server:RegisterCallback("characters:delete", function(src, charId)
    return Core.Characters.Delete(src, charId)
end)

Core.Callbacks.Server:RegisterCallback("characters:saveValue", function(src, key, value)
    return Core.Characters.SaveValue(src, key, value)
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    if Core.Players[src] then
        Core.Players[src] = nil
    end
end)
