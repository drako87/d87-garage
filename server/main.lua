-- =========================================================================
-- d87-garage Server Main
-- Core server logic, callbacks, and event handlers.
-- =========================================================================

local Config = D87.Config
local Bridge = D87.Bridge
local Storage = D87.Storage
local Spawn = D87.Spawn
local Cols = Config.database.columns

---@type table<string, table>
local Garages = Config.garages

-- Tracks players who currently have a spawn request in flight, so mashing
-- "Take Out" twice can't create a duplicate vehicle while the first one
-- is still being created.
local spawnLocks = {}

-- Returns garage definitions
lib.callback.register('d87-garage:server:getGarages', function(source)
    return Garages
end)

--- Checks if a plate exists on any spawned vehicle
local function findPlateOnServer(plate)
    local vehicles = GetAllVehicles()
    for i = 1, #vehicles do
        if plate == GetVehicleNumberPlateText(vehicles[i]) then
            return true
        end
    end
    return false
end

--- Checks whether any vehicle is already occupying the radius around a point.
--- Prevents vehicles spawning stacked/clipped into one another.
---@param coords vector3
---@param radius number
local function isSpawnPointClear(coords, radius)
    if not radius or radius <= 0 then return true end
    local vehicles = GetAllVehicles()
    for i = 1, #vehicles do
        local vCoords = GetEntityCoords(vehicles[i])
        if #(vCoords - coords) < radius then
            return false
        end
    end
    return true
end

--- Get vehicle type based on category/class (simplified for now)
local function getVehicleType(model)
    local hash = type(model) == 'string' and joaat(model) or model
    -- Basic classification, can be expanded if needed or retrieved from framework
    return VehicleType.CAR
end

--- Validates if a player can access a garage
local function canAccessGarage(source, garageName)
    local garage = Garages[garageName]
    if not garage then return false end

    -- Job/Gang check
    if garage.groups and not Bridge.HasGroup(source, garage.groups) then
        return false
    end

    return true
end

--- Validates the player is actually near the garage they claim to be using.
--- Callbacks can be invoked directly (e.g. via a trigger/exploit menu), so the
--- client-side zone check alone isn't enough to stop someone spawning a
--- vehicle from anywhere on the map.
---@param source number
---@param garage table
---@return boolean
local function isPlayerNearGarage(source, garage)
    local point = garage.menu or garage.entry
    if not point then return true end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local dist = #(GetEntityCoords(ped) - point.xyz)
    return dist <= (Config.vehicle.spawnDistanceCheck or 10.0)
end

-- Get player's vehicles for a specific garage
lib.callback.register('d87-garage:server:getVehicles', function(source, garageName)
    local garage = Garages[garageName]
    if not garage then return nil end

    if not canAccessGarage(source, garageName) then
        return nil
    end

    local citizenid = Bridge.GetIdentifier(source)
    if not citizenid then return nil end

    -- Filters
    local filterGarage = not garage.skipGarageCheck and garageName or nil
    local filterStates = garage.states or VehicleState.GARAGED

    local vehicles = Storage.GetPlayerVehicles(citizenid, filterGarage, filterStates)
    local result = {}

    for i = 1, #vehicles do
        local veh = vehicles[i]
        local plate = veh[Cols.plate]
        local model = veh[Cols.vehicle]
        
        -- Filter by type (CAR, AIR, SEA) if not ALL
        if garage.vehicleType == VehicleType.ALL or garage.vehicleType == getVehicleType(model) then
            -- Skip if it's already spawned (unless it's impound, but even then we don't want duplicates)
            if not findPlateOnServer(plate) then
                local vehData = {
                    id = veh[Cols.id],
                    plate = plate,
                    model = model,
                    label = Bridge.GetVehicleLabel(model),
                    state = veh[Cols.state],
                    depotPrice = veh[Cols.depotprice] or 0,
                    props = veh[Cols.props] or {},
                    fuel = veh.fuel or 100,
                    engine = veh.engine or 1000,
                    body = veh.body or 1000,
                }

                -- Auto-calculate depot price for OUT vehicles if not set
                if vehData.state == VehicleState.OUT and vehData.depotPrice <= 0 then
                    vehData.depotPrice = Spawn.CalculateImpoundFee(vehData.id, vehData.model)
                end

                result[#result + 1] = vehData
            end
        end
    end

    return result
end)

-- Spawn a vehicle from the garage
lib.callback.register('d87-garage:server:spawnVehicle', function(source, vehicleId, garageName)
    local garage = Garages[garageName]
    if not garage then return false, 'Garage not found' end

    local citizenid = Bridge.GetIdentifier(source)
    if not citizenid then return false, locale('error.not_owned') end

    -- Stop double-clicking "Take Out" from spawning two copies of the vehicle
    if spawnLocks[citizenid] then
        return false, locale('error.spawn_in_progress')
    end
    spawnLocks[citizenid] = true

    -- Small helper so every return path below releases the lock automatically
    local function finish(success, result)
        spawnLocks[citizenid] = nil
        return success, result
    end

    if not isPlayerNearGarage(source, garage) then
        return finish(false, locale('error.no_access'))
    end

    -- Fetch vehicle data
    local vehicles = Storage.GetPlayerVehicles(citizenid)
    local vehData = nil

    for i = 1, #vehicles do
        if vehicles[i][Cols.id] == vehicleId then
            vehData = vehicles[i]
            break
        end
    end

    if not vehData then
        return finish(false, locale('error.not_owned'))
    end

    local plate = vehData[Cols.plate]

    if garage.type == GarageType.DEPOT and findPlateOnServer(plate) then
        return finish(false, locale('error.not_impound'))
    end

    if garage.type == GarageType.DEPOT then
        local depotPrice = vehData[Cols.depotprice] or 0
        if depotPrice <= 0 then
            depotPrice = Spawn.CalculateImpoundFee(vehicleId, vehData[Cols.vehicle])
        end

        if not Spawn.PayDepotPrice(source, depotPrice) then
            return finish(false, locale('error.not_enough'))
        end
    end

    local spawnCoords = garage.exit
    if not spawnCoords then
        return finish(false, 'No exit point defined')
    end

    if not isSpawnPointClear(spawnCoords.xyz, Config.vehicle.distanceCheck) then
        return finish(false, locale('error.no_space'))
    end

    local props = vehData[Cols.props] or {}
    props.plate = plate
    
    local netId, entity = Bridge.SpawnVehicle(source, vehData[Cols.vehicle], spawnCoords, props)
    if not netId or not entity or not DoesEntityExist(entity) then
        return finish(false, locale('error.spawn_failed'))
    end

    -- Always enforce an explicit lock state: freshly created vehicles can
    -- otherwise spawn locked by default depending on the model/game build.
    if Config.vehicle.doorsLocked then
        SetVehicleDoorsLocked(entity, 2)
    else
        SetVehicleDoorsLocked(entity, 1)
    end

    Entity(entity).state:set('vehicleid', vehicleId, false)
    Spawn.SetVehicleStateToOut(vehicleId, entity, vehData[Cols.vehicle])

    -- Send props/plate along so the client can apply full properties and
    -- warp the player in once the vehicle has actually streamed in for them.
    return finish(true, { netId = netId, props = props })
end)

-- Park a vehicle
lib.callback.register('d87-garage:server:parkVehicle', function(source, netId, garageName, props)
    local garage = Garages[garageName]
    if not garage then return false, 'Garage not found' end

    if garage.type == GarageType.DEPOT then
        return false, 'Cannot park in a depot'
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return false, 'Entity not found'
    end

    local plate = GetVehicleNumberPlateText(entity)
    -- Remove trailing spaces from plate if any
    plate = plate:gsub('^%s*(.-)%s*$', '%1')

    local vehData = Storage.GetVehicleByPlate(plate)
    if not vehData then
        return false, locale('error.not_owned')
    end

    local citizenid = Bridge.GetIdentifier(source)
    if vehData[Cols.citizenid] ~= citizenid then
        return false, locale('error.not_owned')
    end

    -- Update DB
    Storage.SetVehicleGarage(vehData[Cols.id], garageName, VehicleState.GARAGED)
    if props then
        Storage.SetVehicleProps(vehData[Cols.id], props)
    end

    -- The DB writes above are async and take a moment, so re-check the entity
    -- still exists before touching it again (avoids "no such entity" natives
    -- warnings if it somehow got cleaned up in the meantime).
    if DoesEntityExist(entity) then
        Bridge.DeleteVehicle(entity)
    end

    return true, locale('success.vehicle_parked')
end)

-- Initialize
AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end
    
    if Config.general.autoRespawn then
        Storage.MoveOutVehiclesIntoGarages()
        print('^2[d87-garage]^0 Auto-respawned OUT vehicles into garages.')
    end
end)

-- Clean up any dangling spawn locks if a player drops mid-request
AddEventHandler('playerDropped', function()
    local citizenid = Bridge.GetIdentifier(source)
    if citizenid then
        spawnLocks[citizenid] = nil
    end
end)

-- Exports
exports('GetGarages', function() return Garages end)
exports('SetVehicleGarage', Storage.SetVehicleGarage)
exports('SetVehicleDepotPrice', Storage.SetVehicleDepotPrice)
