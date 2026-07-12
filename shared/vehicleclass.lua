-- =========================================================================
-- d87-garage Vehicle Spawn Type
-- CreateVehicleServerSetter necesita el "tipo" real del vehículo
-- (automobile/bike/boat/heli/plane). Antes se pasaba 'automobile' fijo
-- para todo, lo que hace que las motos se creen con el pop-type
-- equivocado y el motor las trate como bloqueadas aunque
-- doorsLocked = false. Esto obtiene el tipo real a partir de la clase
-- del modelo, sin necesidad de spawnear el vehículo.
-- =========================================================================

D87 = D87 or {}

---@param model string|number
---@return string spawnType -- 'automobile' | 'bike' | 'boat' | 'heli' | 'plane'
function D87.GetVehicleSpawnType(model)
    local hash = type(model) == 'string' and joaat(model) or model
    local class = GetVehicleClassFromName(hash)

    if class == 8 or class == 13 then return 'bike' end  -- Motorcycles / Cycles
    if class == 14 then return 'boat' end                 -- Boats
    if class == 15 then return 'heli' end                 -- Helicopters
    if class == 16 then return 'plane' end                -- Planes

    return 'automobile'
end
