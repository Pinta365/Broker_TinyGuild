-- Utils.lua
-- Utility functions for Broker_TinyGuild

local addonName, AddonTable = ...

-- Debug helper function
function AddonTable.debugPrint(message)
    if BrokerTinyGuildDB and BrokerTinyGuildDB.debug then
        print("Broker_TinyGuild: " .. tostring(message))
    end
end

-- Timerunning icon functionality
function AddonTable.addTimerunningIcon(name)
    if name and name ~= "" then
        return "|TInterface\\AddOns\\Broker_TinyFriends\\Textures\\timerunning-glues-icon-small.png:9:9|t" .. name
    end
    return name
end

-- Sanitize name to remove duplicate realm suffixes (e.g., "Name-Realm-Realm-Realm" -> "Name-Realm")
-- This is to prevent duplicate realm names when we get faulty data from the API.
-- Some rainy day I will find the root cause of this and fix it.
function AddonTable.sanitizeName(name)
    if not name or name == "" then
        return name
    end
    
    local parts = {}
    for part in name:gmatch("([^-]+)") do
        table.insert(parts, part)
    end
    
    if #parts >= 2 then
        return parts[1] .. "-" .. parts[2]
    end

    return name
end

