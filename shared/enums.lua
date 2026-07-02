---@enum VehicleState
VehicleState = {
    OUT = 0,
    GARAGED = 1,
    IMPOUNDED = 2,
}

---@enum VehicleType
VehicleType = {
    CAR = 'car',
    AIR = 'air',
    SEA = 'sea',
    ALL = 'all',
}

---@enum GarageType
GarageType = {
    PUBLIC = 'public',
    DEPOT = 'depot',
    JOB = 'job',
    GANG = 'gang',
    PRIVATE = 'private',
}

---@enum InteractionType
InteractionType = {
    TEXTUI = 'textui',
    TARGET = 'target',
}
