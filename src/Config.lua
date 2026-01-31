-- Config.lua
-- Default settings and configuration

local addonName, AddonTable = ...

-- Default settings
AddonTable.defaultSettings = {
    showOfficerNotes = true,
    debug = false,
    backgroundOpacity = 0.8,  -- Default tooltip transparency (0.0 = transparent, 1.0 = opaque)
    scale = 1.0               -- Panel scale multiplier (1.0 = match UI scale, 0.5–1.5 = 50%–150%)
}

-- Initialize saved variables
function AddonTable.initSettings()
    BrokerTinyGuildDB = BrokerTinyGuildDB or {}
    
    -- Merge defaults with existing settings
    for key, value in pairs(AddonTable.defaultSettings) do
        if BrokerTinyGuildDB[key] == nil then
            BrokerTinyGuildDB[key] = value
        end
    end
end

