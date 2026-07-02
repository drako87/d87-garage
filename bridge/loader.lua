-- =========================================================================
-- d87-garage Bridge Loader
-- Auto-detects the active framework and loads configuration.
-- Runs as a shared script (both client and server).
-- =========================================================================

D87 = D87 or {}

---@param configFramework string|nil
---@return string
local function detectFramework(configFramework)
    if configFramework and configFramework ~= 'auto' then
        return configFramework
    end

    if GetResourceState('qbx_core') == 'started' then
        return 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    else
        return 'standalone'
    end
end

-- Load config
D87.Config = require 'config.config'

-- Detect framework (config may override auto-detection)
D87.Framework = detectFramework(D87.Config.general.framework)

-- Debug print
if D87.Config.general.debug then
    print(('[^2d87-garage^0] Framework: ^3%s^0'):format(D87.Framework))
end
