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

