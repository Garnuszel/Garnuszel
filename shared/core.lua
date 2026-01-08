Core = Core or {}
Core.Utils = Core.Utils or {}
Core.Players = Core.Players or {}

-- Removes items from an array table while keeping order stable based on a callback decision.
Core.Utils.ArrayRemove = function(array, predicate)
    local writeIndex = 1
    local length = #array

    for readIndex = 1, length do
        if predicate(array, readIndex, writeIndex) then
            if readIndex ~= writeIndex then
                array[writeIndex] = array[readIndex]
                array[readIndex] = nil
            end
            writeIndex = writeIndex + 1
        end
    end

    return array
end

-- Legacy-style shared object access for other resources (client and server)
if GetCurrentResourceName() == "rev-core" then
    AddEventHandler("rev-core:getSharedObject", function(cb)
        cb(Core)
    end)

    AddEventHandler("rev-core:updateSharedObject", function(cb)
        cb(Core)
    end)
end

-- Deep copies a table, preserving function references provided by FiveM when needed.
Core.Utils.CopyTable = function(source, destination)
    destination = destination or {}

    if type(source) ~= "table" then
        return source
    end

    local meta = getmetatable(source)
    if meta and meta.__cfx_functionReference then
        DuplicateFunctionReference(meta.__cfx_functionReference)
        return source
    end

    for key, value in pairs(source) do
        if type(value) == "table" then
            destination[key] = destination[key] or {}
            Core.Utils.CopyTable(value, destination[key])
        else
            destination[key] = value
        end
    end

    setmetatable(destination, meta)
    return destination
end

Core.Utils.MathRound = function(number, precision)
    if precision then
        local multiplier = 10 ^ precision
        return math.floor(number * multiplier + 0.5) / multiplier
    end

    return math.floor(number + 0.5)
end

Core.Utils.FormatDate = function(timestamp, includeTime)
    local format = includeTime and "%d.%m.%Y, %H:%M" or "%d.%m.%Y"
    return os.date(format, timestamp)
end

Core.Utils.FormatFromMilliseconds = function(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local hours = math.floor(minutes / 60)

    local seconds = totalSeconds % 60
    minutes = minutes % 60
    local msRemainder = milliseconds % 1000

    return string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, msRemainder)
end

Core.Utils.FormatToMilliseconds = function(hours, minutes, seconds)
    return (hours * 3600 + minutes * 60 + seconds) * 1000
end

if not IsDuplicityVersion() then
    Core.Player = Core.Player or {}

    RegisterNetEvent("rev-core:setPlayerValue", function(key, value)
        Core.Player[key] = value
    end)

    Core.Utils.HasJob = function(jobName, requireDuty)
        local playerJobs = Core.Player.jobs
        if not playerJobs then return false end

        for job, jobData in pairs(playerJobs) do
            if job == jobName then
                if not requireDuty then
                    return true
                end

                if jobData.grade and jobData.flags and jobData.flags.duty then
                    return true
                end
            end
        end

        return false
    end

    Core.Utils.HasJobFromCategory = function(categoryName)
        local playerJobs = Core.Player.jobs
        if not playerJobs then return false end

        for job, jobData in pairs(playerJobs) do
            if jobData.jobCategory == categoryName then
                return true, job
            end
        end

        return false
    end
end

Core.Print = function(...)
    local args = {...}
    print(string.format("^5[%s]^7", GetInvokingResource()))

    if #args == 0 then
        print("^1No data to print^7")
        return
    end

    for i = 1, #args do
        print(json.encode(args[i], { indent = true }))
    end
end
