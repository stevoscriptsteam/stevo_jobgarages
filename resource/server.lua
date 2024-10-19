if not lib.checkDependency('stevo_lib', '1.7.1') then error('stevo_lib 1.7.1 required for stevo_portablemoneywash') end
lib.versionCheck('stevoscriptsteam/stevo_portablemoneywash')
lib.locale()
local stevo_lib = exports['stevo_lib']:import()
local config = lib.require('config')
local WashingMachines = {}

---@param source number
local function handleCheater(source)
    local name = GetPlayerName(source)
    local identifier = stevo_lib.GetIdentifier(source)

    lib.print.info(('User: %s (%s) tried to exploit stevo_portablemoneywash'):format(name, identifier))

    if config.dropCheaters then 
        DropPlayer(source, 'Trying to exploit stevo_portablemoneywash')
    end

    return false
end

---@param unixTimestamp number
local function formatTimestamp(unixTimestamp) -- courtesy of ChatGPT (Could not be bothered)
    local dateTable = os.date("*t", unixTimestamp)

    local daySuffixes = { "st", "nd", "rd", "th" }
    local day = dateTable.day
    local suffix

    if day % 10 == 1 and day ~= 11 then
        suffix = daySuffixes[1]
    elseif day % 10 == 2 and day ~= 12 then
        suffix = daySuffixes[2]
    elseif day % 10 == 3 and day ~= 13 then
        suffix = daySuffixes[3]
    else
        suffix = daySuffixes[4]
    end

    local hour = dateTable.hour % 12
    if hour == 0 then hour = 12 end

    local period = dateTable.hour < 12 and "am" or "pm"
    local formattedDate = os.date("%A", unixTimestamp) .. " " .. day .. suffix .. ", " .. hour .. ':'.. os.date("%M", unixTimestamp) .. period

    return formattedDate
end

local function generateUniqueWasherId()
    local id
    repeat
        id = math.random(100000, 999999)
    until not WashingMachines[id] 
    return id
end

---@param source number
---@param type string
---@param washerCoords string
---@param washerHeading string
lib.callback.register('stevo_portablemoneywash:placed', function(source, type, washerCoords, washerHeading)
    local washerConfig = config.washingMachines[type]

    if stevo_lib.HasItem(source, type) < 1 then return handleCheater(source) end


    stevo_lib.RemoveItem(source, type, 1)

    local washerEntity = CreateObject(washerConfig.model, washerCoords.x, washerCoords.y, washerCoords.z-1, true, true)
    SetEntityHeading(washerEntity, washerHeading)
    FreezeEntityPosition(washerEntity, true)

    local identifier = stevo_lib.GetIdentifier(source)
    local name = stevo_lib.GetName(source)
    local id = generateUniqueWasherId()

    local washer = {
        id = id,
        type = type,
        name = name,
        owner = identifier,
        data = {locked = true, keys = {}, currentWash = {active = false}},
        entity = washerEntity,
        coords = vec3(washerCoords.x, washerCoords.y, washerCoords.z-1)
    }

    WashingMachines[washer.id] = washer

    TriggerClientEvent('stevo_portablemoneywash:addTarget', -1, washer)


    MySQL.insert.await('INSERT INTO `stevo_portable_moneywash` (id, type, owner, name, data, coords, heading) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        id, washer.type, washer.owner, washer.name, json.encode(washer.data), json.encode(vec3(washerCoords.x, washerCoords.y, washerCoords.z-1)), washerHeading
    })

    return true
end)


lib.callback.register('stevo_portablemoneywash:getWashers', function()
    if #WashingMachines < 1 then 
        local washers = MySQL.query.await('SELECT * FROM `stevo_portable_moneywash`', {})

        if washers then
            for i = 1, #washers do
                local washer =  washers[i]
                local washerConfig = config.washingMachines[washer.type]
                local washerCoords = json.decode(washer.coords)
                local washerHeading = json.decode(washer.heading)
    
                local washerEntity = CreateObject(washerConfig.model, washerCoords.x, washerCoords.y, washerCoords.z, true, true)
                SetEntityHeading(washerEntity, washerHeading)
                FreezeEntityPosition(washerEntity, true)
    
                
                local washerTable = {
                    id = washer.id,
                    type = washer.type,
                    name = washer.name,
                    owner = washer.owner,
                    data = json.decode(washer.data),
                    coords = json.decode(washer.coords),
                    entity = washerEntity
                }
    
                WashingMachines[washer.id] = washerTable
            end
        end
    end
    return WashingMachines
end)

---@param source number
---@param id number
lib.callback.register('stevo_portablemoneywash:getWasherData', function(source, id)
    local identifier = stevo_lib.GetIdentifier(source)
    local washer = WashingMachines[id]
    local isOwner = identifier == washer.owner and true or false
    local hasKey = false


    if not isOwner then 
        for _, key in pairs(washer.data.keys) do
            if key.identifier == identifier then 
                hasKey = true
            end
        end
    else 
        hasKey = true
    end

    return washer, isOwner, hasKey, os.time()
end)

---@param source number
---@param id number
lib.callback.register('stevo_portablemoneywash:getMoneyBalance', function(source, id)
    local balance = stevo_lib.HasItem(source, config.dirtyMoneyItem)

    return balance > 0 and balance or false, WashingMachines[id].type
end)

---@param source number
---@param id number
---@param washAmount number
lib.callback.register('stevo_portablemoneywash:startedWash', function(source, id, washAmount)
    local washer = WashingMachines[id]
    local washTax = math.floor(washAmount * config.washingMachines[washer.type].washTax)
    local washReturn = washAmount - washTax
    local washTime = config.washingMachines[washer.type].msecPer * washAmount
    local time = os.time()
    local finishTime = math.floor(time + washTime / 1000)
    local name = stevo_lib.GetName(source)
    local identifier = stevo_lib.GetIdentifier(source)
    local isOwner = identifier == washer.owner and true or false
    local hasKey = false

    if not isOwner then 
        for _, key in pairs(washer.data.keys) do
            if key.identifier == identifier then 
                hasKey = true
            end
        end
    else 
        hasKey = true 
    end

    if not hasKey then 
        return handleCheater(source)
    end

    if stevo_lib.HasItem(source, config.dirtyMoneyItem) < washAmount then 
        return handleCheater(source)
    end

    stevo_lib.RemoveItem(source, config.dirtyMoneyItem, washAmount)

    washer.data.currentWash = {active = true, amount = washAmount, washReturn = washReturn, start = time, startFormatted = formatTimestamp(time), finish = finishTime, finishFormatted = formatTimestamp(finishTime), startedBy = name}

    MySQL.update.await('UPDATE stevo_portable_moneywash SET data = ? WHERE id = ?', {
        json.encode(washer.data), id
    })

    return washer, os.time()
end)

---@param source number 
---@param id number
lib.callback.register('stevo_portablemoneywash:moneyUnloaded', function(source, id)
    local washer = WashingMachines[id]
    local identifier = stevo_lib.GetIdentifier(source)
    local isOwner = identifier == washer.owner and true or false

    local hasKey = false

    if not isOwner then 
        for _, key in pairs(washer.data.keys) do
            if key.identifier == identifier then 
                hasKey = true
            end
        end
    else 
        hasKey = true 
    end

    if not hasKey then 
        return handleCheater(source)
    end

    if not washer.data.currentWash.active then 
        return washer, os.time()
    end

    if washer.data.currentWash.finish > os.time() then 
        return handleCheater(source)
    end

    stevo_lib.AddItem(source, config.moneyItem, washer.data.currentWash.washReturn)

    washer.data.currentWash = {active = false, amount = 0, washReturn = 0, start = 0, startFormatted = '', finish = 0, finishFormatted = '', startedBy = ''}

    MySQL.update.await('UPDATE stevo_portable_moneywash SET data = ? WHERE id = ?', {
        json.encode(washer.data), id
    })


    return washer, os.time()
end)

---@param source number 
---@param id number
lib.callback.register('stevo_portablemoneywash:washCancelled', function(source, id)
    local washer = WashingMachines[id]
    local identifier = stevo_lib.GetIdentifier(source)
    local isOwner = identifier == washer.owner and true or false

    local hasKey = false

    if not isOwner then 
        for _, key in pairs(washer.data.keys) do
            if key.identifier == identifier then 
                hasKey = true
            end
        end
    else 
        hasKey = true 
    end

    if not hasKey then 
        return handleCheater(source)
    end

    if not washer.data.currentWash.active then 
        return washer, os.time()
    end

    stevo_lib.AddItem(source, config.dirtyMoneyItem, washer.data.currentWash.amount)

    washer.data.currentWash = {active = false, amount = 0, washReturn = 0, start = 0, startFormatted = '', finish = 0, finishFormatted = '', startedBy = ''}

    MySQL.update.await('UPDATE stevo_portable_moneywash SET data = ? WHERE id = ?', {
        json.encode(washer.data), id
    })


    return washer, os.time()
end)

---@param source number 
---@param action string 
---@param actiondata string 
---@param id number
lib.callback.register('stevo_portablemoneywash:washerActionModified', function(source, action, actiondata, id)
    local identifier = stevo_lib.GetIdentifier(source)
    local washer = WashingMachines[id]
    local isOwner = identifier == washer.owner and true or false
    local hasKey = false

    if not isOwner then 
        for _, key in pairs(washer.data.keys) do
            if key.identifier == identifier then 
                hasKey = true
            end
        end
    else 
        hasKey = true 
    end

    if not hasKey then 
        return handleCheater(source)
    end

    if action == 'lockstatus' then 
        washer.data.locked = not washer.data.locked
    end

    if action == 'addkey' then 
        local identifier = stevo_lib.GetIdentifier(actiondata)
        local name = stevo_lib.GetName(actiondata)
        local noExist = true

        for _, key in pairs(washer.data.keys) do
            if key.identifier == identifier then 
                TriggerClientEvent('stevo_portablemoneywash:notify', source, locale("notify.keyalreadyexists"), 'error', 3000)
                noExist = false
            end
        end

        if noExist then 
            TriggerClientEvent('stevo_portablemoneywash:notify', source, locale("notify.gavekey", name), 'success', 3000)
            table.insert(washer.data.keys, {name = name, identifier = identifier})
        end
    end

    if action == 'removekey' then 

        local keyRemoved = false
        local name = ''

        for _, key in pairs(washer.data.keys) do
            if key.identifier == actiondata then 
                table.remove(washer.data.keys, _)
                keyRemoved = true
                name = key.name
            end
        end

        if keyRemoved then 
            TriggerClientEvent('stevo_portablemoneywash:notify', source, locale("notify.removedkey", name), 'success', 3000)
        else
            TriggerClientEvent('stevo_portablemoneywash:notify', source, locale("notify.cantremovekey"), 'error', 3000)
        end
    end

    MySQL.update.await('UPDATE stevo_portable_moneywash SET data = ? WHERE id = ?', {
        json.encode(washer.data), id
    })
    
    return washer, os.time()
end)

---@param source number 
---@param closestPlayers table
lib.callback.register('stevo_portablemoneywash:formatClosestPlayers', function(source, closestPlayers)
    local formattedPlayers = {}


    for _, player in pairs(closestPlayers) do 
        local id = player.value
        local name = stevo_lib.GetName(id)
        formattedPlayers[_] = {label = name..' - '..player.label, value = player.value}
    end 


    return formattedPlayers
end)

---@param source number 
---@param id number
lib.callback.register('stevo_portablemoneywash:pickedupWasher', function(source, id)
    local washer = WashingMachines[id]
    local identifier = stevo_lib.GetIdentifier(source)
    local isOwner = identifier == washer.owner and true or false

    local hasKey = false

    if not isOwner then 
        for _, key in pairs(washer.data.keys) do
            if key.identifier == identifier then 
                hasKey = true
            end
        end
    else 
        hasKey = true 
    end

    if not hasKey then 
        return handleCheater(source)
    end

    if washer.data.currentWash.active then 
        stevo_lib.AddItem(source, config.dirtyMoneyItem, washer.data.currentWash.amount)
    end

    if DoesEntityExist(washer.entity) then 
        DeleteEntity(washer.entity)
    end

    TriggerClientEvent('stevo_portablemoneywash:deleteWasher', -1, id)

    stevo_lib.AddItem(source, washer.type, 1)

    MySQL.rawExecute.await('DELETE FROM `stevo_portable_moneywash` WHERE id = ?', {
        id
    })

    return true
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end

    local success, _ = pcall(MySQL.scalar.await, 'SELECT 1 FROM stevo_portable_moneywash')

        if not success then
            MySQL.query([[CREATE TABLE IF NOT EXISTS `stevo_portable_moneywash` (
                `id` INT NOT NULL,
                `type` TEXT NOT NULL,
                `owner` VARCHAR(50) NOT NULL,
                `name` VARCHAR(50) NOT NULL,
                `data` TEXT NOT NULL,
                `coords` TEXT NOT NULL,
                `heading` TEXT NOT NULL,
                PRIMARY KEY (`id`)
            )]])

            lib.print.info('[Stevo Scripts] Deployed database table for stevo_portablemoneywash')
        end

    for washertype, washer in pairs(config.washingMachines) do
        stevo_lib.RegisterUsableItem(washertype, function(source)
            TriggerClientEvent('stevo_portablemoneywash:useItem', source, washertype)
        end)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for _, washer in pairs(WashingMachines) do 
        if DoesEntityExist(washer.entity) then
            DeleteEntity(washer.entity)
        end
    end
end)


 