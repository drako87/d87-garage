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

    -- Fetch vehicle data
    local citizenid = Bridge.GetIdentifier(source)
    local vehicles = Storage.GetPlayerVehicles(citizenid)
    local vehData = nil

    for i = 1, #vehicles do
        if vehicles[i][Cols.id] == vehicleId then
            vehData = vehicles[i]
            break
        end
    end

    if not vehData then
        return false, locale('error.not_owned')
    end

    local plate = vehData[Cols.plate]

    if garage.type == GarageType.DEPOT and findPlateOnServer(plate) then
        return false, locale('error.not_impound')
    end

    if garage.type == GarageType.DEPOT then
        local depotPrice = vehData[Cols.depotprice] or 0
        if depotPrice <= 0 then
            depotPrice = Spawn.CalculateImpoundFee(vehicleId, vehData[Cols.vehicle])
        end

        if not Spawn.PayDepotPrice(source, depotPrice) then
            return false, locale('error.not_enough')
        end
    end

    local spawnCoords = garage.exit
    if not spawnCoords then
        return false, 'No exit point defined'
    end

    -- Distance check server-side logic could be added here, but usually done client-side first for feedback

    local props = vehData[Cols.props] or {}
    props.plate = plate
    
    local netId, entity = Bridge.SpawnVehicle(source, vehData[Cols.vehicle], spawnCoords, props)
    if not netId then
        return false, 'Spawn failed'
    end

    if Config.vehicle.doorsLocked then
        SetVehicleDoorsLocked(entity, 2)
    end

    Entity(entity).state:set('vehicleid', vehicleId, false)
    Spawn.SetVehicleStateToOut(vehicleId, entity, vehData[Cols.vehicle])

    return true, netId
end)

-- Park a vehicle
lib.callback.register('d87-garage:server:parkVehicle', function(source, netId, garageName, props)
    local garage = Garages[garageName]
    if not garage then return false, 'Garage not found' end

    if garage.type == GarageType.DEPOT then
        return false, 'Cannot park in a depot'
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or not DoesEntityExist(entity) then
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

    Bridge.DeleteVehicle(entity)
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

-- Exports
exports('GetGarages', function() return Garages end)
exports('SetVehicleGarage', Storage.SetVehicleGarage)
exports('SetVehicleDepotPrice', Storage.SetVehicleDepotPrice)