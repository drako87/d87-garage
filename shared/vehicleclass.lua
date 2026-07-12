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

    -- GetVehicleClassFromName is client-only; estos IsThisModelA* sí
    -- funcionan en el servidor porque solo leen la info estática del
    -- modelo, no requieren que exista ninguna entidad.
    if IsThisModelABike(hash) then return 'bike' end
    if IsThisModelABoat(hash) then return 'boat' end
    if IsThisModelAHeli(hash) then return 'heli' end
    if IsThisModelAPlane(hash) then return 'plane' end

    return 'automobile'
end
