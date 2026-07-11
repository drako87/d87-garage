-- =========================================================================
-- d87-garage Server Storage
-- Handles all database interactions.
-- =========================================================================

local Config = D87.Config
local Cols = Config.database.columns

---@class Storage
local Storage = {}

---@async
---@param citizenid string
---@param garage? string
---@param states? VehicleState|VehicleState[]
---@return table[] vehicles
function Storage.GetPlayerVehicles(citizenid, garage, states)
    local query = 'SELECT * FROM ' .. Config.database.table .. ' WHERE ' .. Cols.citizenid .. ' = ?'
    local params = { citizenid }

    if garage then
        query = query .. ' AND ' .. Cols.garage .. ' = ?'
        params[#params + 1] = garage
    end

    if states then
        if type(states) == 'table' then
            local placeholders = {}
            for i = 1, #states do
                placeholders[i] = '?'
                params[#params + 1] = states[i]
            end
            query = query .. ' AND ' .. Cols.state .. ' IN (' .. table.concat(placeholders, ',') .. ')'
        else
            query = query .. ' AND ' .. Cols.state .. ' = ?'
            params[#params + 1] = states
        end
    end

    local result = MySQL.query.await(query, params)
    if not result then return {} end
    
    -- Format props for easier usage if needed
    for i = 1, #result do
        local v = result[i]
        if v[Cols.props] and type(v[Cols.props]) == 'string' then
            local success, decoded = pcall(json.decode, v[Cols.props])
            if success and decoded then
                v[Cols.props] = decoded
            end
        end
    end

    return result
end

---@async
---@param plate string
---@return table? vehicle
function Storage.GetVehicleByPlate(plate)
    local query = 'SELECT * FROM ' .. Config.database.table .. ' WHERE ' .. Cols.plate .. ' = ? LIMIT 1'
    local result = MySQL.query.await(query, { plate })
    if result and result[1] then
        local v = result[1]
        if v[Cols.props] and type(v[Cols.props]) == 'string' then
            local success, decoded = pcall(json.decode, v[Cols.props])
            if success and decoded then
                v[Cols.props] = decoded
            end
        end
        return v
    end
    return nil
end

---@param id integer
---@param garageName string
---@param state VehicleState
---@return integer numRowsAffected
function Storage.SetVehicleGarage(id, garageName, state)
    local query = 'UPDATE ' .. Config.database.table .. ' SET ' .. Cols.garage .. ' = ?, ' .. Cols.state .. ' = ? WHERE ' .. Cols.id .. ' = ?'
    return MySQL.update.await(query, { garageName, state, id })
end

---@param id integer
---@param state VehicleState
---@return integer numRowsAffected
function Storage.SetVehicleState(id, state)
    local query = 'UPDATE ' .. Config.database.table .. ' SET ' .. Cols.state .. ' = ? WHERE ' .. Cols.id .. ' = ?'
    return MySQL.update.await(query, { state, id })
end

---@param id integer
---@param depotPrice integer
---@return integer numRowsAffected
function Storage.SetVehicleDepotPrice(id, depotPrice)
    local query = 'UPDATE ' .. Config.database.table .. ' SET ' .. Cols.depotprice .. ' = ? WHERE ' .. Cols.id .. ' = ? AND ' .. Cols.state .. ' != ?'
    return MySQL.update.await(query, { depotPrice, id, VehicleState.GARAGED })
end

---Saves the raw properties AND syncs the standalone fuel/engine/body columns
---used by the garage list/details UI from those same properties, so what
---the menu shows always matches what was actually captured off the vehicle
---(previously these columns were never touched after row creation, so the
---UI kept showing stale/default values while the real data only lived
---inside the `mods` json).
---@param id integer
---@param props table
---@return integer numRowsAffected
function Storage.SetVehicleProps(id, props)
    local propsStr = json.encode(props)
    local fuel = props.fuelLevel or props.fuel or 100
    local engine = props.engineHealth or 1000
    local body = props.bodyHealth or 1000

    local query = 'UPDATE ' .. Config.database.table .. ' SET '
        .. Cols.props .. ' = ?, fuel = ?, engine = ?, body = ? WHERE ' .. Cols.id .. ' = ?'
    return MySQL.update.await(query, { propsStr, fuel, engine, body, id })
end

---Persists the vehicle's total distance travelled (km), read from its
---'odometer' entity statebag right before it's parked/deleted.
---@param id integer
---@param odometer number
---@return integer numRowsAffected
function Storage.SetVehicleOdometer(id, odometer)
    local query = 'UPDATE ' .. Config.database.table .. ' SET odometer = ? WHERE ' .. Cols.id .. ' = ?'
    return MySQL.update.await(query, { odometer, id })
end

---@async
---@return integer numRowsAffected
function Storage.MoveOutVehiclesIntoGarages()
    local query = 'UPDATE ' .. Config.database.table .. ' SET ' .. Cols.state .. ' = ? WHERE ' .. Cols.state .. ' = ?'
    return MySQL.update.await(query, { VehicleState.GARAGED, VehicleState.OUT })
end

D87.Storage = Storage
