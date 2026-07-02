-- =========================================================================
-- d87-garage Client Main
-- Handles zones (entry/exit/menu), blips, and player interaction.
-- =========================================================================

local Config = D87.Config
local Bridge = D87.Bridge
local NUI = D87.NUI

local Zones = {}
local Blips = {}

local function createBlip(coords, data)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, data.sprite or 357)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, data.scale or 0.65)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, data.color or 3)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.name or 'Garage')
    EndTextCommandSetBlipName(blip)
    return blip
end

local function drawMarker(coords, markerConfig)
    if not Config.markers.enabled then return end
    DrawMarker(
        markerConfig.type,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        markerConfig.size.x, markerConfig.size.y, markerConfig.size.z,
        markerConfig.color.r, markerConfig.color.g, markerConfig.color.b, markerConfig.color.a,
        markerConfig.bob, false, 2, markerConfig.rotate, nil, nil, false
    )
end

--- Safely gets the driver out of the vehicle before it's parked/deleted.
--- Deleting a networked vehicle server-side while its driver is still
--- seated in it is what causes the client to spam natives warnings
--- (NETWORK_GET_NETWORK_ID_FROM_ENTITY / GetNetworkObject / fuel level)
--- and can glitch the ped, since the vehicle vanishes from under them.
local function ensureDriverIsOut(vehicle, ped)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then return end

    FreezeEntityPosition(vehicle, true)
    TaskLeaveVehicle(ped, vehicle, 16)

    local timeout = GetGameTimer() + 3000
    while DoesEntityExist(vehicle) and GetVehiclePedIsIn(ped, false) == vehicle and GetGameTimer() < timeout do
        Wait(0)
    end

    if DoesEntityExist(vehicle) then
        FreezeEntityPosition(vehicle, false)
    end
end

local function parkVehicle(vehicle, garageName)
    if not DoesEntityExist(vehicle) or not NetworkGetEntityIsNetworked(vehicle) then
        Bridge.Notify(locale('error.not_owned') or 'This vehicle can\'t be stored', 'error')
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then return end

    -- Capture live vehicle properties (fuel, mods, etc.) before doing anything else
    local props = Bridge.GetVehicleProperties(vehicle)

    ensureDriverIsOut(vehicle, cache.ped)

    lib.callback('d87-garage:server:parkVehicle', false, function(success, result)
        if success then
            Bridge.Notify(result, 'success')
        else
            Bridge.Notify(result, 'error')
        end
    end, netId, garageName, props)
end

local function setupGarages()
    local garages = lib.callback.await('d87-garage:server:getGarages', false)
    if not garages then return end

    for id, garage in pairs(garages) do
        -- 1. Create Blip
        if Config.blips.enabled and garage.blip then
            Blips[id] = createBlip(garage.menu or garage.entry, garage.blip)
        end

        -- 2. Menu Zone (On Foot)
        if garage.menu then
            local menuPoint = lib.points.new({
                coords = garage.menu.xyz,
                distance = Config.interaction.drawDistance,
                garageId = id,
                garage = garage,
            })

            function menuPoint:nearby()
                if cache.vehicle then return end -- Only accessible on foot
                drawMarker(self.coords, Config.markers.menu)

                if self.currentDistance < Config.interaction.menuDistance then
                    if Config.interaction.type == 'textui' then
                        if not self.textUIVisible then
                            lib.showTextUI(locale('info.car_e') or '[E] Open Garage')
                            self.textUIVisible = true
                        end
                        if IsControlJustReleased(0, Config.interaction.key) then
                            lib.hideTextUI()
                            self.textUIVisible = false
                            
                            -- Fetch vehicles and open NUI
                            local vehicles = lib.callback.await('d87-garage:server:getVehicles', false, self.garageId)
                            if vehicles then
                                NUI.OpenGarageUI(self.garageId, self.garage, vehicles)
                            else
                                Bridge.Notify(locale('error.no_access') or 'No access', 'error')
                            end
                        end
                    end
                elseif self.textUIVisible then
                    lib.hideTextUI()
                    self.textUIVisible = false
                end
            end
            
            Zones[id .. '_menu'] = menuPoint
        end

        -- 3. Entry Zone (In Vehicle)
        if garage.entry and garage.type ~= GarageType.DEPOT then
            local entryPoint = lib.points.new({
                coords = garage.entry.xyz,
                distance = Config.interaction.drawDistance,
                garageId = id,
                garage = garage,
            })

            function entryPoint:nearby()
                if not cache.vehicle then return end -- Only accessible in vehicle
                drawMarker(self.coords, Config.markers.entry)

                if self.currentDistance < Config.interaction.entryDistance then
                    if Config.interaction.type == 'textui' then
                        if not self.textUIVisible then
                            lib.showTextUI(locale('info.park_e') or '[E] Park Vehicle')
                            self.textUIVisible = true
                        end
                        if IsControlJustReleased(0, Config.interaction.key) then
                            -- Park vehicle logic
                            if GetPedInVehicleSeat(cache.vehicle, -1) == cache.ped then
                                parkVehicle(cache.vehicle, self.garageId)
                                lib.hideTextUI()
                                self.textUIVisible = false
                            end
                        end
                    end
                elseif self.textUIVisible then
                    lib.hideTextUI()
                    self.textUIVisible = false
                end
            end
            
            Zones[id .. '_entry'] = entryPoint
        end
        
        -- Note: Exit zone is only used by server for coords, no marker/interaction needed usually, 
        -- but if you want to draw a marker where cars spawn, you could add it here.
    end
end

CreateThread(function()
    setupGarages()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for _, blip in pairs(Blips) do
        RemoveBlip(blip)
    end
    lib.hideTextUI()
end)
