-- =========================================================================
-- d87-garage Vehicle Spawn Type
-- CreateVehicleServerSetter necesita el "tipo" real del vehículo
-- (automobile/bike/boat/heli/plane). Antes se pasaba 'automobile' fijo
-- para todo, lo que hace que las motos se creen con el pop-type
-- equivocado y el motor las trate como bloqueadas aunque
-- doorsLocked = false.
--
-- Los natives GetVehicleClassFromName / IsThisModelABike (etc.) no están
-- disponibles en el contexto server en FXServer, así que se usa una
-- lista estática de nombres de modelo (vanilla GTA V) en su lugar.
-- Si añades vehículos de un DLC/addon que no estén en estas listas,
-- simplemente añade su nombre de modelo (en minúsculas) al array
-- correspondiente.
-- =========================================================================

D87 = D87 or {}

local BikeModels = {
    'akuma', 'avarus', 'bagger', 'bati', 'bati2', 'bf400', 'carbonrs',
    'cliffhanger', 'daemon', 'daemon2', 'defiler', 'diablous', 'diablous2',
    'double', 'enduro', 'esskey', 'faggio', 'faggio2', 'faggio3', 'fcr',
    'fcr2', 'gargoyle', 'hakuchou', 'hakuchou2', 'hexer', 'innovation',
    'lectro', 'manchez', 'manchez2', 'nemesis', 'nightblade', 'oppressor',
    'oppressor2', 'pcj', 'ratbike', 'reever', 'ruffian', 'sanchez',
    'sanchez2', 'sanctus', 'shinobi', 'sovereign', 'stryder', 'thrust',
    'vader', 'vindicator', 'vortex', 'wolfsbane', 'zombiea', 'zombieb',
}

local BoatModels = {
    'dinghy', 'dinghy2', 'dinghy3', 'dinghy4', 'jetmax', 'kosatka',
    'longfin', 'marquis', 'patrolboat', 'predator', 'seashark', 'seashark2',
    'seashark3', 'speeder', 'speeder2', 'squalo', 'submersible',
    'submersible2', 'suntrap', 'toro', 'toro2', 'tropic', 'tropic2', 'tug',
    'tuner',
}

local HeliModels = {
    'annihilator', 'annihilator2', 'buzzard', 'buzzard2', 'cargobob',
    'cargobob2', 'cargobob3', 'cargobob4', 'frogger', 'frogger2', 'havok',
    'hunter', 'maverick', 'nokota', 'polmav', 'savage', 'seasparrow',
    'seasparrow2', 'seasparrow3', 'skylift', 'supervolito', 'supervolito2',
    'swift', 'swift2', 'valkyrie', 'valkyrie2', 'volatus',
}

local PlaneModels = {
    'alphaz1', 'avenger', 'avenger2', 'besra', 'blimp', 'blimp2', 'blimp3',
    'bombushka', 'cargoplane', 'cuban800', 'dodo', 'duster', 'howard',
    'hydra', 'jet', 'lazer', 'luxor', 'luxor2', 'mammatus', 'microlight',
    'miljet', 'mogul', 'molotok', 'nimbus', 'pyro', 'rogue', 'seabreeze',
    'shamal', 'starling', 'strikeforce', 'stunt', 'titan', 'tula', 'velum',
    'velum2', 'vestra', 'volatol',
}

local function toSet(list)
    local set = {}
    for i = 1, #list do
        set[list[i]] = true
    end
    return set
end

BikeModels = toSet(BikeModels)
BoatModels = toSet(BoatModels)
HeliModels = toSet(HeliModels)
PlaneModels = toSet(PlaneModels)

---@param model string|number
---@return string spawnType -- 'automobile' | 'bike' | 'boat' | 'heli' | 'plane'
function D87.GetVehicleSpawnType(model)
    if type(model) ~= 'string' then
        -- Solo tenemos nombres, no hashes; si no viene como string no
        -- podemos clasificarlo, así que se mantiene el comportamiento
        -- anterior (automobile) en vez de romper el spawn.
        return 'automobile'
    end

    local name = model:lower()

    if BikeModels[name] then return 'bike' end
    if BoatModels[name] then return 'boat' end
    if HeliModels[name] then return 'heli' end
    if PlaneModels[name] then return 'plane' end

    return 'automobile'
end
