return {

    progressCircle = false, -- If lib progressCircle should be used instead of progressBar
    openDistance = 1, -- Open distance on foot
    vehicleOpenDistance = 5, -- Open Distance in vehicle
    minimumPlateGrade = 0, -- Minimum grade to change plate
    repairTime = 5, -- Repair Time in seconds

    garages = {
        { -- Police Garage Example

            groupRequired = 'police', -- Can be a job or gang role
            name = 'Fire Garage',
            distance = 5,
            plate = 'Fire '..math.random(000, 999), -- Generated Random Plate like "MRPD 452" or "MRPD 259"

            marker = {
                type = 36,
                size = 1.5,
                r = 66, 
                g = 0, 
                b = 0,
                alpha = 80
            },

            categories = {
                {
                    name = 'Ambulances',
                    icon = 'star-of-life',
                    iconColor = '#1372ad',
                    gradeRequired = 0,
                    
                    vehicles = {
                        {model = 'aambulance', label = 'Vapid Ambulance', icon = 'https://cdn.discordapp.com/attachments/1091282605657301013/1297171341610582067/Vapid-GTAO-Logo.webp?ex=6714f474&is=6713a2f4&hm=6549c146e19b5948849731b11ba64a7305e5457aec5bae7459ad39890fced32b&', iconColor = '#7a5f15', mods = {livery = 4, extras = {  {id = 1, disabled = false},
                        {id = 2, disabled = false},
                        {id = 3, disabled = false},
                        {id = 4, disabled = false},
                        {id = 5, disabled = false},
                        {id = 6, disabled = false},
                        {id = 7, disabled = false},
                        {id = 8, disabled = false}, {id = 2, disabled = true}}}},
                        {model = 'nkscout2020', label = 'Ambulance Gauntlet Scout', icon = 'https://cdn.discordapp.com/attachments/1091282605657301013/1297171445977190441/Bravado-GTAO-Logo.webp?ex=6714f48d&is=6713a30d&hm=d766b3b81b4b368a52594e96b380e6d5372b47023c3e7b8f5cd7f8f09eeafd9c&', iconColor = '#7a5f15', mods = {livery = 4, extras = {{id = 1, disabled = false}, {id = 2, disabled = true}}}}
                    }
                },
                {
                    name = 'Fire Trucks',
                    icon = 'fire',
                    iconColor = '#c9c304',
                    gradeRequired = 5,

                    vehicles = {
                        {model = 'police', label = 'Police Cruiser', icon = 'circle', iconColor = '#7a5f15'}
                    }
                }
                
            },

            locations = {
                {menuCoords = vec3(1157.6926, -1467.0543, 34.6925), spawnCoords = vec4(1151.3429, -1466.6206, 34.6925, 356.3958), label = 'City Station'}
            }
        },
        { -- Ambulance Garage Example

        groupRequired = 'ambulance', -- Can be a job or gang role
        name = 'DVPD Garage',
        distance = 5,
        plate = 'DVPD '..math.random(000, 999), -- Generated Random Plate like "MRPD 452" or "MRPD 259"

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
            {menuCoords = vec3(383.7571, -1613.8743, 29.2919), spawnCoords = vec4(392.8316, -1617.8042, 29.2919, 320.2001), label = 'City Station'}
        }
    },
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