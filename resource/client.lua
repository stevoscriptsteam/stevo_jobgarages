if not lib.checkDependency('stevo_lib', '1.7.2) then error('stevo_lib 1.7.2 required for stevo_jobgarages') end
lib.locale()
local config = require('config')
local stevo_lib = exports['stevo_lib']:import()
local progress = config.progressCircle and lib.progressCircle or lib.progressBar
local garagePoints = {}
local textUIShowing = false
local menuOpen = false
local spawnCoords = vec4(0.0, 0.0, 0.0, 0.0)


local function toggleExtra(data)
    SetVehicleExtra(cache.vehicle, data.extra, data.state)
    changeExtras()
end

local function toggleLivery(data)
    SetVehicleLivery(cache.vehicle, data.livery)
    changeLiveries()
end

function changeLiveries()
	local liveries = {}
	local liveryCount = GetVehicleLiveryCount(cache.vehicle)		

	for i = 1, liveryCount do
		local vehicleLivery = GetVehicleLivery(cache.vehicle)
        local currentLivery = vehicleLivery == i

        local livery = {
            title = locale("menu.livery", i),
            icon = currentLivery and 'check' or 'x',
            iconColor = currentLivery and '#00a859' or '#a7171a',
            onSelect = toggleLivery,
            args = {livery = i}
        }
        table.insert(liveries, livery)
	end

	lib.registerContext({
		id = 'stevo_jobgarages_liveries',
		title = locale("menu.mechanicTitle"),
        menu = 'stevo_jobgarages_mechanic',
        options = liveries
	})
	lib.showContext('stevo_jobgarages_liveries')
end

function changeExtras()
	local extras = {}

	for id = 0, 12 do
		if DoesExtraExist(cache.vehicle, id) then
			local state = IsVehicleExtraTurnedOn(cache.vehicle, id) 
            local extra = {
                title = locale("menu.extra", id),
                icon = state and 'check' or 'x',
                iconColor = state and '#00a859' or '#a7171a',
                onSelect = toggleExtra,
                args = {
                    extra = id,
                    state = state,
                }
            }
            table.insert(extras, extra)
		end
	end

	lib.registerContext({
		id = 'stevo_jobgarages_extras',
		title = locale("menu.mechanicTitle"),
        menu = 'stevo_jobgarages_mechanic',
        options = extras
	})
	lib.showContext('stevo_jobgarages_extras')
end

local function hex2rgb(hex)
    local hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

local function storeVehicle()
    local plate = GetVehicleNumberPlateText(cache.vehicle)

    config.removeVehicleKeys(cache.vehicle, plate)
    DeleteVehicle(cache.vehicle)
    stevo_lib.Notify(locale("notify.storeVehicle"), "success", 3000)
end

local function changeColor(data)
	local input = lib.inputDialog(locale("input.color"), {
		{type = 'color', label = locale("input.colorLabel"), default = '#eb4034'},
	})
	if input then
		local r, g, b = hex2rgb(input[1])
		if data.primary then
			SetVehicleCustomPrimaryColour(cache.vehicle, r or 255, g or 0, b or 0)
			lib.showContext('stevo_jobgarages_paint')
		else
			SetVehicleCustomSecondaryColour(cache.vehicle, r or 255, g or 0, b or 0)
			lib.showContext('stevo_jobgarages_paint')
		end
	end
end

local function changePlate()
    local groupInfo = stevo_lib.GetPlayerGroupInfo(true)

    if groupInfo.grade < config.minimumPlateGrade then lib.showContext('stevo_jobgarages_mechanic') return stevo_lib.Notify(locale("notify.notAuthorized"), "error", 5000) end 

    local vehicle = GetVehiclePedIsIn(cache.ped, false)

    local input = lib.inputDialog(locale("input.plate"), {
        {type = 'input', label = locale("input.plate"), description = locale("input.plateDescription"), required = true, min = 1, max = 8},
    })

    config.removeVehicleKeys(cache.vehicle, GetVehicleNumberPlateText(cache.vehicle))
       
    if input then
        SetVehicleNumberPlateText(cache.vehicle, input[1])
        config.giveVehicleKeys(cache.vehicle, input[1])
        stevo_lib.Notify(locale("notify.setPlate", input[1]), 'info', 4000)
    else
        lib.showContext('stevo_jobgarages_mechanic')
    end
end

local function repairVehicle()

    if progress({
        duration = config.repairTime * 1000,
        position = 'bottom',
        label = locale('progress.repairingVehicle'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true, },
    }) then    
        SetVehicleFixed(cache.vehicle)
        stevo_lib.Notify(locale("notify.vehicleRepaired"), 'success', 3000)
        lib.showContext('stevo_jobgarages_mechanic')
    else
        stevo_lib.Notify(locale("notify.vehicleRepairCancelled"), 'error', 3000)
        lib.showContext('stevo_jobgarages_mechanic')
    end
end

local function applyMods(vehicle, mods)
    if mods.extras then
        for _, extra in ipairs(mods.extras) do
            SetVehicleExtra(vehicle, extra.id, extra.disabled)
        end   
    end
    if mods.livery then
        SetVehicleLivery(vehicle, mods.livery)
    end
    if mods.color then
        SetVehicleColours(vehicle, mods.color, 0)
    end
end

local function selectVehicle(data)
    menuOpen = true
    local model = lib.requestModel(data.model)
    local coords = spawnCoords
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, false, true)
    

	SetVehicleNumberPlateText(vehicle, 'PREVIEW')
	SetPedIntoVehicle(cache.ped, vehicle, -1)
	SetVehicleEngineOn(vehicle, false, false, true)
    SetVehicleHandbrake(vehicle, true)
    SetVehicleInteriorlight(vehicle, true)
    FreezeEntityPosition(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, true)
	if data.mods then 
    	applyMods(vehicle, data.mods)
			end
    SetVehicleDirtLevel(vehicle, 0)

    local alert = lib.alertDialog({
        header = data.garageName,
        content = locale("alert.confirmSpawnTitle", data.label),
        centered = true,
        cancel = true,
        labels = {
            cancel = locale('alert.cancelSpawn'),
            confirm = locale('alert.confirmSpawn')
        }
    })

    if alert ~= 'confirm' then 
        DeleteVehicle(vehicle)
        lib.showContext(data.categoryMenuId)

        return stevo_lib.Notify(locale("notify.cancelledSpawn"), "error", 3000)
    end 

    math.random()
    DeleteVehicle(vehicle)
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, true)

    SetVehicleNumberPlateText(vehicle, data.plate)

    SetPedIntoVehicle(cache.ped, vehicle, -1)
	SetVehicleEngineOn(vehicle, true, true, true)
    applyMods(vehicle, data.mods)
    SetVehicleDirtLevel(vehicle, 0)
    config.giveVehicleKeys(vehicle, data.plate)

    stevo_lib.Notify(locale("notify.vehicleSpawned", data.label), "success", 3000)
    menuOpen = false
end

local function openCategory(data)
    local groupInfo = stevo_lib.GetPlayerGroupInfo(true)

    if groupInfo.grade < data.gradeRequired then lib.showContext(data.garageMenuId) return stevo_lib.Notify(locale("notify.notAuthorized"), "error", 5000) end 

    lib.showContext(data.categoryMenuId)
end

local function onEnter(self)
    local groupInfo = stevo_lib.GetPlayerGroupInfo(true)
    self.playerGroup = groupInfo.name

end
 
local function onExit(self)
    self.playerGroup = false

    if textUIShowing then 
        lib.hideTextUI()
        textUIShowing = false
    end
end
 
local function nearby(self)
    if self.playerGroup ~= self.groupRequired then return end

    local openDistance = cache.vehicle and config.vehicleOpenDistance or config.openDistance

    DrawMarker(self.garageMarker.type, self.menuCoords.x, self.menuCoords.y, self.menuCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, self.garageMarker.size, self.garageMarker.size, self.garageMarker.size, self.garageMarker.r, self.garageMarker.g, self.garageMarker.b, self.garageMarker.alpha, false, true, 2, false, nil, nil, false)
 
    if self.currentDistance < openDistance and not textUIShowing and not menuOpen then 
        lib.showTextUI(locale("textui.opengarage"))
        textUIShowing = true
    end

    if self.currentDistance > openDistance and textUIShowing then 
        lib.hideTextUI()
        textUIShowing = false
    end
    
    if self.currentDistance < openDistance and IsControlJustReleased(0, 38) then

        spawnCoords = self.spawnCoords
        if cache.vehicle then 
            lib.showContext('stevo_jobgarages_invehicle')
        else 
            lib.showContext(self.garageMenuId)
        end
        menuOpen = true
    end
end

local function initGarages()
    for garageId, garage in pairs(config.garages) do 
        local garageCategories = {}
        local garageMenuId = 'stevo_jobgarages_'..garageId

        for categoryId, category in pairs(garage.categories) do 
            local categoryMenuId = 'stevo_jobgarages_'..garageId..'_'..categoryId
            local categoryVehicles = {}
            local newCategory = {
                title = category.name,
                icon = category.icon,
                iconColor = category.iconColor,
                onSelect = openCategory,
                args = {garageMenuId = garageMenuId, categoryMenuId = categoryMenuId, groupRequired = garage.groupRequired, gradeRequired = category.gradeRequired}
            }
            table.insert(garageCategories, newCategory)

            for _, vehicle in pairs(category.vehicles) do 
                local newVehicle = {
                    title = vehicle.label,
                    icon = vehicle.icon,
                    iconColor = vehicle.iconColor,
                    onSelect = selectVehicle,
                    args = {model = vehicle.model, label = vehicle.label, mods = vehicle.mods, garageName = garage.name, categoryMenuId = categoryMenuId, plate = garage.plate}
                }
                table.insert(categoryVehicles, newVehicle)
            end

            lib.registerContext({
                id = categoryMenuId,
                menu = garageMenuId,
                title = category.name,
                options = categoryVehicles,
                onExit = function()
                    menuOpen = false
                end
            })
        end


        lib.registerContext({
            id = garageMenuId,
            title = garage.name,
            options = garageCategories,
            onExit = function()
                menuOpen = false
            end
        })

        for locationId, location in pairs(garage.locations) do 
            garagePoints[locationId] = lib.points.new({
                coords = location.menuCoords,
                distance = garage.distance,
                label = location.label,
                garageMenuId = garageMenuId,
                groupRequired = garage.groupRequired,
                menuCoords = location.menuCoords,
                playerGroup = false,
                spawnCoords = location.spawnCoords,
                garageMarker = garage.marker,
                onEnter = onEnter,
                onExit = onExit,
                nearby = nearby
            })
        end
    end
end

lib.registerContext({
	id = 'stevo_jobgarages_paint',
    menu = 'stevo_jobgarages_mechanic',
	title = locale("menu.mechanicTitle"),
	options = {
	  {
		title = locale("menu.changePrimaryColor"),
		icon = '1',
		onSelect = changeColor,
        args = {primary = true}
	  },
	  {
		title = locale("menu.changeSecondaryColor"),
		icon = '2',
		onSelect = changeColor,
        args = {primary = false}
	  },
	}
})

lib.registerContext({
	id = 'stevo_jobgarages_invehicle',
	title = locale("menu.inVehicle"),
	options = {
	  {
		title = locale("menu.mechanicTitle"),
		icon = 'toolbox',
        menu = 'stevo_jobgarages_mechanic'
	  },
	  {
		title = locale("menu.storeVehicle"),
		icon = 'x',
        arrow = true,
        onSelect = storeVehicle
	  },
	}
})

lib.registerContext({
	id = 'stevo_jobgarages_mechanic',
	title = locale("menu.mechanicTitle"),
	options = {
	    {
            title = locale("menu.changeExtras"),
            icon = 'plus',
            onSelect = changeExtras,
            arrow = true
	    },
	    {
            title = locale("menu.changeLivery"),
            icon = 'note-sticky',
            onSelect = changeLiveries,
            arrow = true
	    },
	    {
            title = locale("menu.changeColor"),
            icon = 'brush',
            menu = 'stevo_jobgarages_paint'
	    },
	    {
            title = locale("menu.repairVehicle"),
            icon = 'toolbox',
            onSelect = repairVehicle,
            arrow = true
	    },
	    {
            title = locale("menu.changePlate"),
            icon = 't',
            onSelect = changePlate,
            arrow = true
	    }
	}
})

RegisterNetEvent('stevo_lib:playerLoaded', function()
    initGarages()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end

    initGarages()
end)


