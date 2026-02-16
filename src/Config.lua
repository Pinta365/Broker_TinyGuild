-- Config.lua
-- Default settings and configuration

local addonName, AddonTable = ...

-- Broker text format options
AddonTable.brokerTextFormats = {
    { label = "Guild: 15/100 Online", format = function(name, online, total) return string.format(WrapTextInColorCode("%s:", "ff40FF40") .. " %d/%d Online", name, online, total) end },
    { label = "Guild: 15 Online",     format = function(name, online, total) return string.format(WrapTextInColorCode("%s:", "ff40FF40") .. " %d Online", name, online) end },
    { label = "Guild: 15",            format = function(name, online, total) return string.format(WrapTextInColorCode("%s:", "ff40FF40") .. " %d", name, online) end },
    { label = "G: 15",                format = function(name, online, total) return string.format(WrapTextInColorCode("%s:", "ff40FF40") .. " %d", "G", online) end },
    { label = "15 Online",            format = function(name, online, total) return string.format("%d Online", online) end },
    { label = "15",                   format = function(name, online, total) return tostring(online) end },
}

-- Default settings
AddonTable.defaultSettings = {
    showOfficerNotes = true,
    debug = false,
    backgroundOpacity = 0.8,  -- Default tooltip transparency (0.0 = transparent, 1.0 = opaque)
    scale = 1.0,              -- Panel scale multiplier (1.0 = match UI scale, 0.5–1.5 = 50%–150%)
    brokerTextFormat = 1,     -- Index into brokerTextFormats (1 = "Guild: 15/100 Online")
    sortOrder = "name",       -- Column to sort by (name, level, rank, zone, note, officerNote)
    sortAscending = true      -- Sort direction (true = ascending, false = descending)
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

