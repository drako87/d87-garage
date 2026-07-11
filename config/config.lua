return {
    ---------------------------------------------------------------------------
    -- General Settings
    ---------------------------------------------------------------------------
    general = {
        debug = false,                      -- Enable debug mode (shows zones, extra logs)
        locale = 'es',                      -- Default language ('en', 'es')
        autoRespawn = false,                -- Auto-respawn OUT vehicles to garage on resource restart
        framework = 'auto',                -- 'auto', 'qb', 'qbx', 'esx', 'standalone'
    },

    ---------------------------------------------------------------------------
    -- Interaction Settings
    ---------------------------------------------------------------------------
    interaction = {
        type = 'textui',                    -- 'textui' or 'target' (ox_target / qb-target)
        key = 38,                           -- Key to interact (38 = E)
        menuDistance = 2.0,                 -- Radius for menu interaction zone
        entryDistance = 3.0,                -- Radius for vehicle entry zone
        drawDistance = 50.0,                -- Distance to start drawing markers
    },

    ---------------------------------------------------------------------------
    -- Vehicle Settings
    ---------------------------------------------------------------------------
    vehicle = {
        engineOn = true,                    -- Engine on when taking vehicle out
        doorsLocked = true,                 -- Doors locked when taking vehicle out
        warpInVehicle = true,               -- Warp player into vehicle on take out
        distanceCheck = 5.0,                -- Min clear distance for spawn point (prevents stacking)
        spawnDistanceCheck = 10.0,          -- Max distance player can be from menu point to spawn
    },

    ---------------------------------------------------------------------------
    -- Impound / Depot Settings
    ---------------------------------------------------------------------------
    impound = {
        enabled = true,                     -- Enable impound system
        baseFee = 500,                      -- Fixed impound fee (used when usePercent = false)
        feePercent = 0.02,                  -- Fee as % of vehicle price (2%)
        usePercent = true,                  -- true = percentage, false = fixed baseFee
    },

    ---------------------------------------------------------------------------
    -- Blip Defaults
    ---------------------------------------------------------------------------
    blips = {
        enabled = true,                     -- Show blips on the map
        defaults = {
            car   = { sprite = 357, color = 3,  scale = 0.65 },
            air   = { sprite = 360, color = 3,  scale = 0.65 },
            sea   = { sprite = 356, color = 3,  scale = 0.65 },
            depot = { sprite = 68,  color = 1,  scale = 0.65 },
        },
    },

    ---------------------------------------------------------------------------
    -- Marker Settings (per zone type)
    ---------------------------------------------------------------------------
    markers = {
        enabled = true,
        menu = {
            type   = 27,
            color  = { r = 20, g = 200, b = 255, a = 180 },    -- Cyan
            size   = vec3(1.0, 1.0, 0.5),
            bob    = true,
            rotate = true,
        },
        entry = {
            type   = 36,
            color  = { r = 50, g = 255, b = 100, a = 180 },    -- Green
            size   = vec3(1.5, 1.5, 0.5),
            bob    = true,
            rotate = true,
        },
        exit = {
            type   = 36,
            color  = { r = 255, g = 150, b = 0, a = 180 },     -- Orange
            size   = vec3(1.5, 1.5, 0.5),
            bob    = true,
            rotate = true,
        },
    },

    ---------------------------------------------------------------------------
    -- NUI / Interface Settings
    ---------------------------------------------------------------------------
    ui = {
        theme          = 'dark',            -- 'dark' or 'light'
        accentColor    = '#00d4ff',         -- Primary accent color
        accentGradient = '#0088ff',         -- Secondary accent for gradients
        showFuel       = true,
        showEngine     = true,
        showBody       = true,
        enableSounds   = true,
    },

    ---------------------------------------------------------------------------
    -- Logging (server-side)
    ---------------------------------------------------------------------------
    logging = {
        webhook = {
            error     = nil,                -- Discord webhook URL for errors
            default   = nil,                -- Discord webhook URL for general logs
            anticheat = nil,                -- Discord webhook URL for suspicious activity
        },
    },

    ---------------------------------------------------------------------------
    -- Database Column Mapping
    -- Adjust these if your player_vehicles table uses different column names.
    ---------------------------------------------------------------------------
    database = {
        table = 'player_vehicles',
        columns = {
            id         = 'id',
            citizenid  = 'citizenid',
            vehicle    = 'vehicle',
            garage     = 'garage',
            state      = 'state',
            props      = 'mods',
            plate      = 'plate',
            depotprice = 'depotprice',
        },
    },

    ---------------------------------------------------------------------------
    -- Garage Definitions
    --
    -- Each garage has 3 separate coordinate points:
    --   menu  = vec4(x, y, z, heading) → Where to open the NUI (on foot)
    --   entry = vec4(x, y, z, heading) → Where to park the vehicle (drive in)
    --   exit  = vec4(x, y, z, heading) → Where the vehicle spawns (drive out)
    ---------------------------------------------------------------------------
    garages = {
        -- =================================================================
        -- PUBLIC GARAGES
        -- =================================================================
        motelgarage = {
            label       = 'Motel Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(275.58, -344.74, 45.17, 70.0),
            entry       = vec4(270.51, -343.06, 43.92, 339.86),
            exit        = vec4(285.41, -348.8, 43.98, 158.59),
        },

        sapcounsel = {
            label       = 'San Andreas Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(-330.67, -781.12, 33.96, 40.46),
            entry       = vec4(-337.11, -775.34, 33.56, 132.09),
            exit        = vec4(-333.0, -778.0, 33.56, 132.09),
        },

        spanishave = {
            label       = 'Spanish Ave Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(-1160.46, -741.04, 19.95, 41.26),
            entry       = vec4(-1170.01, -734.78, 19.13, 217.33),
            exit        = vec4(-1169.67, -747.2, 18.45, 310.12),
        },

        caears24 = {
            label       = 'Caears 24 Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(68.08, 13.15, 69.21, 160.44),
            entry       = vec4(68.58, 24.18, 68.5, 72.06),
            exit        = vec4(69.15, 17.84, 68.21, 249.59),
        },

        littleseoul = {
            label       = 'Little Seoul Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(-463.51, -808.2, 30.54, 0.0),
            entry       = vec4(-472.24, -813.61, 30.3, 179.88),
            exit        = vec4(-468.0, -810.0, 30.3, 179.88),
        },

        lagunapi = {
            label       = 'Laguna Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(363.85, 297.97, 103.5, 341.39),
            entry       = vec4(363.73, 284.03, 102.38, 159.33),
            exit        = vec4(374.9, 288.95, 102.23, 71.02),
        },

        airportp = {
            label       = 'Airport Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(-796.07, -2023.26, 9.17, 55.18),
            entry       = vec4(-787.38, -2032.45, 7.87, 244.88),
            exit        = vec4(-786.97, -2025.12, 7.87, 53.29),
        },

        beachp = {
            label       = 'Beach Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(-1184.21, -1509.65, 4.65, 303.72),
            entry       = vec4(-1184.4, -1501.88, 4.39, 214.7),
            exit        = vec4(-1180.0, -1505.0, 4.39, 214.7),
        },

        pillboxgarage = {
            label       = 'Pillbox Garage Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(215.71, -810.16, 29.73, 335.85),
            entry       = vec4(215.12, -791.53, 29.84, 160.81),
            exit        = vec4(229.25, -800.83, 29.57, 160.33),
        },

        vespucciparking = {
            label       = 'Vespucci Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(-281.17, -888.25, 30.32, 154.2),
            entry       = vec4(-293.38, -891.37, 30.08, 79.69),
            exit        = vec4(-303.39, -893.2, 30.08, 257.12),
        },

        senorawayparking = {
            label       = 'Señora Way Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(2542.51, 2628.08, 36.94, 279.28),
            entry       = vec4(2539.19, 2619.38, 36.94, 291.7),
            exit        = vec4(2540.72, 2634.79, 36.94, 282.11),
        },

        marinadriveparking = {
            label       = 'Marina Drive Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(1508.72, 3768.47, 33.14, 195.63),
            entry       = vec4(1505.52, 3763.51, 33.0, 39.63),
            exit        = vec4(1500.86, 3762.16, 32.98, 213.96),
        },

        paletostationparking = {
            label       = 'Paleto Station Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(141.63, 6616.05, 31.09, 350.51),
            entry       = vec4(136.36, 6619.27, 30.8, 146.69),
            exit        = vec4(135.17, 6607.58, 30.85, 182.85),
        },

        greatoceanparking = {
            label       = 'Great Ocean Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(-276.8, 6073.59, 30.43, 186.01),
            entry       = vec4(-273.72, 6062.57, 30.47, 232.35),
            exit        = vec4(-284.55, 6050.96, 30.51, 45.38),
        },

        inesenoparking = {
            label       = 'Ineseno Road Parking',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.CAR,
            blip        = { name = 'Public Parking' },
            menu        = vec4(-3047.86, 610.06, 6.21, 190.38),
            entry       = vec4(-3044.49, 605.28, 6.33, 102.82),
            exit        = vec4(-3042.47, 599.41, 6.53, 289.38),
        },

        -- =================================================================
        -- AIR GARAGES
        -- =================================================================
        intairport = {
            label       = 'Airport Hangar',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.AIR,
            blip        = { name = 'Hangar', sprite = 360 },
            menu        = vec4(-1025.34, -3017.0, 13.95, 331.99),
            entry       = vec4(-979.2, -2995.51, 13.95, 52.19),
            exit        = vec4(-990.0, -3000.0, 13.95, 52.19),
        },

        higginsheli = {
            label       = 'Higgins Helitours',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.AIR,
            blip        = { name = 'Hangar', sprite = 360 },
            menu        = vec4(-722.12, -1472.74, 5.0, 140.0),
            entry       = vec4(-724.83, -1443.89, 5.0, 140.0),
            exit        = vec4(-720.0, -1460.0, 5.0, 140.0),
        },

        -- =================================================================
        -- SEA GARAGES
        -- =================================================================
        lsymc = {
            label       = 'LSYMC Boathouse',
            type        = GarageType.PUBLIC,
            vehicleType = VehicleType.SEA,
            blip        = { name = 'Boathouse', sprite = 356 },
            menu        = vec4(-794.64, -1510.89, 1.6, 201.55),
            entry       = vec4(-793.58, -1501.4, 0.12, 111.5),
            exit        = vec4(-790.0, -1505.0, 0.12, 111.5),
        },

        -- =================================================================
        -- JOB GARAGES
        -- =================================================================
        police = {
            label       = 'Police Garage',
            type        = GarageType.JOB,
            vehicleType = VehicleType.CAR,
            groups      = 'police',
            menu        = vec4(454.6, -1017.4, 28.4, 0),
            entry       = vec4(438.4, -1018.3, 27.7, 90.0),
            exit        = vec4(445.0, -1020.0, 27.7, 90.0),
        },

        -- =================================================================
        -- IMPOUND / DEPOT
        -- =================================================================
        impoundlot = {
            label          = 'Impound Lot',
            type           = GarageType.DEPOT,
            vehicleType    = VehicleType.CAR,
            states         = { VehicleState.OUT, VehicleState.IMPOUNDED },
            skipGarageCheck = true,
            blip           = { name = 'Impound Lot', sprite = 68, color = 1 },
            menu           = vec4(400.45, -1630.87, 29.29, 228.88),
            entry          = vec4(400.45, -1630.87, 29.29, 228.88),
            exit           = vec4(407.2, -1645.58, 29.31, 228.28),
        },

        airdepot = {
            label          = 'Air Depot',
            type           = GarageType.DEPOT,
            vehicleType    = VehicleType.AIR,
            states         = { VehicleState.OUT, VehicleState.IMPOUNDED },
            skipGarageCheck = true,
            blip           = { name = 'Air Depot', sprite = 359, color = 1 },
            menu           = vec4(-1244.35, -3391.39, 13.94, 59.26),
            entry          = vec4(-1244.35, -3391.39, 13.94, 59.26),
            exit           = vec4(-1269.03, -3376.7, 13.94, 330.32),
        },

        seadepot = {
            label          = 'LSYMC Depot',
            type           = GarageType.DEPOT,
            vehicleType    = VehicleType.SEA,
            states         = { VehicleState.OUT, VehicleState.IMPOUNDED },
            skipGarageCheck = true,
            blip           = { name = 'LSYMC Depot', sprite = 356, color = 1 },
            menu           = vec4(-772.71, -1431.11, 1.6, 48.03),
            entry          = vec4(-772.71, -1431.11, 1.6, 48.03),
            exit           = vec4(-729.77, -1355.49, 1.19, 142.5),
        },
    },
}
