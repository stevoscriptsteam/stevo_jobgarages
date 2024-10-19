return {

    progressCircle = false, -- If lib progressCircle should be used instead of progressBar
    openDistance = 1, -- Open distance on foot
    vehicleOpenDistance = 5, -- Open Distance in vehicle
    minimumPlateGrade = 0, -- Minimum grade to change plate
    repairTime = 5, -- Repair Time in seconds

    garages = {
        { -- Police Garage Example

            groupRequired = 'police', -- Can be a job or gang role
            name = 'MRPD Garage',
            distance = 5,
            plate = 'MRPD '..math.random(000, 999), -- Generated Random Plate like "MRPD 452" or "MRPD 259"

            marker = {
                type = 36,
                size = 1.5,
                r = 66, 
                g = 135, 
                b = 245,
                alpha = 80
            },

            categories = {
                {
                    name = 'General Duties',
                    icon = 'car',
                    iconColor = '#1372ad',
                    gradeRequired = 0,
                    
                    vehicles = {
                        {model = 'police', label = 'Police Cruiser', icon = 'circle', iconColor = '#7a5f15', mods = {livery = 4, extras = {{id = 1, disabled = false}, {id = 2, disabled = true}}}}
                    }
                },
                {
                    name = 'Highway Patrol',
                    icon = 'car',
                    iconColor = '#c9c304',
                    gradeRequired = 5,

                    vehicles = {
                        {model = 'police', label = 'Police Cruiser', icon = 'circle', iconColor = '#7a5f15'}
                    }
                }
                
            },

            locations = {
                {menuCoords = vec3(1768.2677, 2657.9072, 45.5649), spawnCoords = vec4(1769.0909, 2662.9456, 45.5649, 300.1206), label = 'City Station'}
            }
        }
    },

    giveVehicleKeys = function(entity, plate)
        -- Wasabi Carlock
        -- exports.wasabi_carlock:GiveKey(plate)
    end,

    removeVehicleKeys = function(entity, plate)
        -- Wasabi Carlock
        -- exports.wasabi_carlock:RemoveKey(plate)
    end,
    
}