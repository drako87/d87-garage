-- =========================================================================
-- d87-garage Client NUI Handler
-- Handles communication between Lua and the web frontend.
-- =========================================================================

local Config = D87.Config
local Bridge = D87.Bridge

---@class NUI
local NUI = {}
NUI.isOpen = false
NUI.currentGarage = nil

function NUI.OpenGarageUI(garageName, garageData, vehicles)
    if NUI.isOpen then return end
    NUI.isOpen = true
    NUI.currentGarage = garageName

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        garage = {
            id = garageName,
            label = garageData.label,
            type = garageData.type,
        },
        vehicles = vehicles,
        config = {
            theme = Config.ui.theme,
            accentColor = Config.ui.accentColor,
            showFuel = Config.ui.showFuel,
            showEngine = Config.ui.showEngine,
            showBody = Config.ui.showBody,
            impoundEnabled = Config.impound.enabled,
            locales = {
                takeOut = locale('menu.take_out') or 'TAKE OUT',
                payImpound = locale('menu.pay_impound') or 'PAY IMPOUND',
                fuel = locale('menu.fuel') or 'Fuel',
                engine = locale('menu.engine') or 'Engine',
                body = locale('menu.body') or 'Body',
                search = locale('menu.search') or 'Search...',
                out = locale('menu.status_out') or 'OUT',
                garaged = locale('menu.status_garaged') or 'IN GARAGE',
                impounded = locale('menu.status_impounded') or 'IMPOUNDED',
            }
        }
    })
end

function NUI.CloseGarageUI()
    if not NUI.isOpen then return end
    NUI.isOpen = false
    NUI.currentGarage = nil

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- Close callback from UI
RegisterNUICallback('close', function(data, cb)
    NUI.CloseGarageUI()
    cb('ok')
end)

-- Take out vehicle callback
RegisterNUICallback('takeOutVehicle', function(data, cb)
    if not NUI.isOpen or not NUI.currentGarage then
        cb({ success = false, message = 'Menu not open properly' })
        return
    end

    local vehicleId = data.id
    local garageName = NUI.currentGarage

    NUI.CloseGarageUI()
    Bridge.Notify(locale('info.spawning') or 'Spawning vehicle...', 'inform')

    -- Call server to spawn
    lib.callback('d87-garage:server:spawnVehicle', false, function(success, result)
        if success then
            local netId = result
            -- Wait for entity to exist locally
            local veh = lib.waitFor(function()
                if NetworkDoesEntityExistWithNetworkId(netId) then
                    return NetToVeh(netId)
                end
            end, 'Waiting for vehicle spawn', 5000)

            if veh and veh > 0 then
                if Config.vehicle.engineOn then
                    SetVehicleEngineOn(veh, true, true, false)
                end
            else
                Bridge.Notify('Spawn failed locally', 'error')
            end
        else
            Bridge.Notify(result or 'Error spawning vehicle', 'error')
        end
    end, vehicleId, garageName)

    cb('ok')
end)

D87.NUI = NUI
