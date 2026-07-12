-- =========================================================================
-- d87-garage Server Bridge
-- Abstracts framework-specific server operations into a unified API.
-- =========================================================================

local Config = D87.Config

---@class ServerBridge
local Bridge = {}

-- =========================================================================
-- QBCore / QBX
-- =========================================================================
if D87.Framework == 'qb' or D87.Framework == 'qbx' then
    local QBCore = nil

    if D87.Framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    end

    function Bridge.GetPlayer(source)
        if D87.Framework == 'qbx' then
            return exports.qbx_core:GetPlayer(source)
        end
        return QBCore.Functions.GetPlayer(source)
    end

    function Bridge.GetIdentifier(source)
        local player = Bridge.GetPlayer(source)
        if player then
            return player.PlayerData.citizenid
        end
        return nil
    end

    function Bridge.Notify(source, msg, nType, duration)
        if D87.Framework == 'qbx' then
            exports.qbx_core:Notify(source, msg, nType, duration)
        else
            TriggerClientEvent('QBCore:Notify', source, msg, nType, duration)
        end
    end

    function Bridge.RemoveMoney(source, moneyType, amount, reason)
        local player = Bridge.GetPlayer(source)
        if not player then return false end
        return player.Functions.RemoveMoney(moneyType, amount, reason or 'd87-garage')
    end

    function Bridge.GetMoney(source, moneyType)
        local player = Bridge.GetPlayer(source)
        if not player then return 0 end
        return player.PlayerData.money[moneyType] or 0
    end

    function Bridge.HasGroup(source, groups)
        if D87.Framework == 'qbx' then
            return exports.qbx_core:HasPrimaryGroup(source, groups)
        end
        local player = Bridge.GetPlayer(source)
        if not player then return false end
        if type(groups) == 'string' then
            return (player.PlayerData.job and player.PlayerData.job.name == groups)
                or (player.PlayerData.gang and player.PlayerData.gang.name == groups)
        end
        if type(groups) == 'table' then
            for _, g in pairs(groups) do
                if (player.PlayerData.job and player.PlayerData.job.name == g)
                or (player.PlayerData.gang and player.PlayerData.gang.name == g) then
                    return true
                end
            end
        end
        return false
    end

    -- NOTE: on qbx we intentionally do NOT use qbx_core's own
    -- `spawnVehicle`/persistence exports. This resource stores and owns
    -- vehicles in its own `player_vehicles` table, and letting qbx_core
    -- register the entity in its own vehicle-persistence system caused a
    -- race in qbx_vehicles/qbx_core (GetVehicleIdByPlate -> trim on a nil
    -- plate) when the vehicle was later deleted by this resource. Spawning
    -- it manually keeps it fully outside qbx_core's tracking.
    function Bridge.SpawnVehicle(source, model, coords, props)
        local hash = type(model) == 'string' and joaat(model) or model
        -- Use the model's real class (car/bike/boat/heli/plane) instead of a
        -- hardcoded 'automobile' type, otherwise motorcycles get created
        -- with the wrong pop-type and can end up stuck in a locked state
        -- regardless of Config.vehicle.doorsLocked.
        local spawnType = D87.GetVehicleSpawnType(hash)
        local veh = CreateVehicleServerSetter(hash, spawnType, coords.x, coords.y, coords.z, coords.w)
        local attempts = 0
        while not DoesEntityExist(veh) and attempts < 100 do
            Wait(10)
            attempts = attempts + 1
        end
        if not DoesEntityExist(veh) then return nil, nil end

        if props and props.plate then
            SetVehicleNumberPlateText(veh, props.plate)
        end

        local netId = NetworkGetNetworkIdFromEntity(veh)
        attempts = 0
        while (not netId or netId == 0) and attempts < 100 do
            Wait(10)
            netId = NetworkGetNetworkIdFromEntity(veh)
            attempts = attempts + 1
        end
        -- Warping the ped is handled client-side once the vehicle has
        -- actually streamed in for that player; doing it here immediately
        -- after CreateVehicleServerSetter is unreliable because the entity
        -- often hasn't reached the client yet.
        return netId, veh
    end

    function Bridge.DeleteVehicle(vehicle)
        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
        DeleteEntity(vehicle)
    end

    function Bridge.GetVehicleLabel(model)
        if D87.Framework == 'qbx' then
            local vehicles = exports.qbx_core:GetVehiclesByName()
            local data = vehicles and vehicles[model]
            if data then
                return ('%s %s'):format(data.brand or '', data.name or model):gsub('^%s+', '')
            end
        elseif QBCore then
            local vehicles = QBCore.Shared.Vehicles
            if vehicles and vehicles[model] then
                return ('%s %s'):format(vehicles[model].brand or '', vehicles[model].name or model):gsub('^%s+', '')
            end
        end
        return model
    end

    function Bridge.GetVehiclePrice(model)
        if D87.Framework == 'qbx' then
            local vehicles = exports.qbx_core:GetVehiclesByName()
            local data = vehicles and vehicles[model]
            return data and data.price or 0
        elseif QBCore then
            local vehicles = QBCore.Shared.Vehicles
            if vehicles and vehicles[model] then
                return vehicles[model].price or 0
            end
        end
        return 0
    end

-- =========================================================================
-- ESX
-- =========================================================================
elseif D87.Framework == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()

    function Bridge.GetPlayer(source)
        return ESX.GetPlayerFromId(source)
    end

    function Bridge.GetIdentifier(source)
        local xPlayer = Bridge.GetPlayer(source)
        return xPlayer and xPlayer.identifier or nil
    end

    function Bridge.Notify(source, msg, nType, duration)
        TriggerClientEvent('esx:showNotification', source, msg)
    end

    function Bridge.RemoveMoney(source, moneyType, amount, reason)
        local xPlayer = Bridge.GetPlayer(source)
        if not xPlayer then return false end
        if moneyType == 'cash' or moneyType == 'money' then
            xPlayer.removeMoney(amount, reason or 'd87-garage')
        else
            xPlayer.removeAccountMoney('bank', amount, reason or 'd87-garage')
        end
        return true
    end

    function Bridge.GetMoney(source, moneyType)
        local xPlayer = Bridge.GetPlayer(source)
        if not xPlayer then return 0 end
        if moneyType == 'cash' or moneyType == 'money' then
            return xPlayer.getMoney()
        end
        return xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0
    end

    function Bridge.HasGroup(source, groups)
        local xPlayer = Bridge.GetPlayer(source)
        if not xPlayer then return false end
        local job = xPlayer.getJob()
        if not job then return false end
        if type(groups) == 'string' then
            return job.name == groups
        end
        if type(groups) == 'table' then
            for _, g in pairs(groups) do
                if job.name == g then return true end
            end
        end
        return false
    end

    function Bridge.SpawnVehicle(source, model, coords, props)
        local hash = type(model) == 'string' and joaat(model) or model
        -- Use the model's real class (car/bike/boat/heli/plane) instead of a
        -- hardcoded 'automobile' type, otherwise motorcycles get created
        -- with the wrong pop-type and can end up stuck in a locked state
        -- regardless of Config.vehicle.doorsLocked.
        local spawnType = D87.GetVehicleSpawnType(hash)
        local veh = CreateVehicleServerSetter(hash, spawnType, coords.x, coords.y, coords.z, coords.w)
        local attempts = 0
        while not DoesEntityExist(veh) and attempts < 100 do
            Wait(10)
            attempts = attempts + 1
        end
        if not DoesEntityExist(veh) then return nil, nil end

        if props and props.plate then
            SetVehicleNumberPlateText(veh, props.plate)
        end

        local netId = NetworkGetNetworkIdFromEntity(veh)
        attempts = 0
        while (not netId or netId == 0) and attempts < 100 do
            Wait(10)
            netId = NetworkGetNetworkIdFromEntity(veh)
            attempts = attempts + 1
        end
        return netId, veh
    end

    function Bridge.DeleteVehicle(vehicle)
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end

    function Bridge.GetVehicleLabel(model)
        return model
    end

    function Bridge.GetVehiclePrice(model)
        return 0
    end

-- =========================================================================
-- Standalone
-- =========================================================================
else
    function Bridge.GetPlayer(source)
        return { source = source }
    end

    function Bridge.GetIdentifier(source)
        for _, id in pairs(GetPlayerIdentifiers(source)) do
            if string.find(id, 'license:') then return id end
        end
        return tostring(source)
    end

    function Bridge.Notify(source, msg, nType, duration)
        TriggerClientEvent('d87-garage:client:notify', source, msg, nType)
    end

    function Bridge.RemoveMoney(_, _, _, _)
        return true
    end

    function Bridge.GetMoney(_, _)
        return 999999
    end

    function Bridge.HasGroup(_, _)
        return true
    end

    function Bridge.SpawnVehicle(source, model, coords, props)
        local hash = type(model) == 'string' and joaat(model) or model
        -- Use the model's real class (car/bike/boat/heli/plane) instead of a
        -- hardcoded 'automobile' type, otherwise motorcycles get created
        -- with the wrong pop-type and can end up stuck in a locked state
        -- regardless of Config.vehicle.doorsLocked.
        local spawnType = D87.GetVehicleSpawnType(hash)
        local veh = CreateVehicleServerSetter(hash, spawnType, coords.x, coords.y, coords.z, coords.w)
        local attempts = 0
        while not DoesEntityExist(veh) and attempts < 100 do
            Wait(10)
            attempts = attempts + 1
        end
        if not DoesEntityExist(veh) then return nil, nil end

        if props and props.plate then
            SetVehicleNumberPlateText(veh, props.plate)
        end

        local netId = NetworkGetNetworkIdFromEntity(veh)
        attempts = 0
        while (not netId or netId == 0) and attempts < 100 do
            Wait(10)
            netId = NetworkGetNetworkIdFromEntity(veh)
            attempts = attempts + 1
        end

        return netId, veh
    end

    function Bridge.DeleteVehicle(vehicle)
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end

    function Bridge.GetVehicleLabel(model)
        return model
    end

    function Bridge.GetVehiclePrice(_)
        return 0
    end
end

D87.Bridge = Bridge
