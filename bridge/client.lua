-- =========================================================================
-- d87-garage Client Bridge
-- Abstracts framework-specific client operations into a unified API.
-- =========================================================================

local Config = D87.Config

---@class ClientBridge
local Bridge = {}

-- =========================================================================
-- QBCore / QBX
-- =========================================================================
if D87.Framework == 'qb' or D87.Framework == 'qbx' then
    local QBCore = nil

    if D87.Framework == 'qbx' then
        -- QBX uses exports directly, no core object needed
    else
        QBCore = exports['qb-core']:GetCoreObject()
    end

    function Bridge.Notify(msg, nType, duration)
        if D87.Framework == 'qbx' then
            exports.qbx_core:Notify(msg, nType, duration)
        else
            QBCore.Functions.Notify(msg, nType, duration)
        end
    end

    function Bridge.GetPlayerData()
        if D87.Framework == 'qbx' then
            return exports.qbx_core:GetPlayerData()
        else
            return QBCore.Functions.GetPlayerData()
        end
    end

    function Bridge.HasGroup(groups)
        if D87.Framework == 'qbx' then
            return exports.qbx_core:HasPrimaryGroup(groups)
        else
            local pd = Bridge.GetPlayerData()
            if not pd then return false end
            if type(groups) == 'string' then
                return (pd.job and pd.job.name == groups)
                    or (pd.gang and pd.gang.name == groups)
            end
            if type(groups) == 'table' then
                for _, g in pairs(groups) do
                    if (pd.job and pd.job.name == g)
                    or (pd.gang and pd.gang.name == g) then
                        return true
                    end
                end
            end
            return false
        end
    end

    function Bridge.GetVehicleProperties(vehicle)
        if GetResourceState('ox_lib') == 'started' then
            return lib.getVehicleProperties(vehicle)
        end
        if QBCore then
            return QBCore.Functions.GetVehicleProperties(vehicle)
        end
        return {}
    end

    function Bridge.SetVehicleProperties(vehicle, props)
        if GetResourceState('ox_lib') == 'started' then
            return lib.setVehicleProperties(vehicle, props)
        end
        if QBCore then
            return QBCore.Functions.SetVehicleProperties(vehicle, props)
        end
    end

-- =========================================================================
-- ESX
-- =========================================================================
elseif D87.Framework == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()

    function Bridge.Notify(msg, nType, duration)
        if GetResourceState('ox_lib') == 'started' then
            lib.notify({ description = msg, type = nType, duration = duration })
        else
            ESX.ShowNotification(msg)
        end
    end

    function Bridge.GetPlayerData()
        return ESX.GetPlayerData()
    end

    function Bridge.HasGroup(groups)
        local pd = ESX.GetPlayerData()
        if not pd or not pd.job then return false end
        if type(groups) == 'string' then
            return pd.job.name == groups
        end
        if type(groups) == 'table' then
            for _, g in pairs(groups) do
                if pd.job.name == g then return true end
            end
        end
        return false
    end

    function Bridge.GetVehicleProperties(vehicle)
        if GetResourceState('ox_lib') == 'started' then
            return lib.getVehicleProperties(vehicle)
        end
        return ESX.Game.GetVehicleProperties(vehicle)
    end

    function Bridge.SetVehicleProperties(vehicle, props)
        if GetResourceState('ox_lib') == 'started' then
            return lib.setVehicleProperties(vehicle, props)
        end
        return ESX.Game.SetVehicleProperties(vehicle, props)
    end

-- =========================================================================
-- Standalone
-- =========================================================================
else
    function Bridge.Notify(msg, nType, duration)
        if GetResourceState('ox_lib') == 'started' then
            lib.notify({ description = msg, type = nType, duration = duration })
        else
            SetNotificationTextEntry('STRING')
            AddTextComponentString(msg)
            DrawNotification(false, true)
        end
    end

    function Bridge.GetPlayerData()
        return {}
    end

    function Bridge.HasGroup(_)
        return true
    end

    function Bridge.GetVehicleProperties(vehicle)
        if GetResourceState('ox_lib') == 'started' then
            return lib.getVehicleProperties(vehicle)
        end
        return {}
    end

    function Bridge.SetVehicleProperties(vehicle, props)
        if GetResourceState('ox_lib') == 'started' then
            return lib.setVehicleProperties(vehicle, props)
        end
    end
end

D87.Bridge = Bridge
