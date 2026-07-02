-- =========================================================================
-- d87-garage Server Spawn Logic
-- Handles vehicle spawning, state updates, and impound logic.
-- =========================================================================

local Config = D87.Config
local Bridge = D87.Bridge
local Storage = D87.Storage
local Cols = Config.database.columns

---@class Spawn
local Spawn = {}

---Calculates the impound fee based on the configuration
---@param vehicleId number
---@param model string
---@return number
function Spawn.CalculateImpoundFee(vehicleId, model)
    if not Config.impound.enabled then return 0 end

    if not Config.impound.usePercent then
        return Config.impound.baseFee
    end

    local price = Bridge.GetVehiclePrice(model)
    if price > 0 then
        return math.floor(price * Config.impound.feePercent)
    end

    return Config.impound.baseFee
end

---Sets a vehicle's state to OUT and calculates its depot price for the future
---@param vehicleId integer
---@param entity number
---@param model string
function Spawn.SetVehicleStateToOut(vehicleId, entity, model)
    local depotPrice = Spawn.CalculateImpoundFee(vehicleId, model)
    Storage.SetVehicleState(vehicleId, VehicleState.OUT)
    Storage.SetVehicleDepotPrice(vehicleId, depotPrice)
end

---Attempts to pay the depot price for a vehicle
---@param source number
---@param price number
---@return boolean success
function Spawn.PayDepotPrice(source, price)
    if price <= 0 then return true end

    if Bridge.GetMoney(source, 'cash') >= price then
        return Bridge.RemoveMoney(source, 'cash', price, 'paid-depot')
    elseif Bridge.GetMoney(source, 'bank') >= price then
        return Bridge.RemoveMoney(source, 'bank', price, 'paid-depot')
    end

    return false
end

D87.Spawn = Spawn
