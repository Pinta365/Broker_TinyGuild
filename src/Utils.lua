-- Utils.lua
-- Utility functions for Broker_TinyGuild

local addonName, AddonTable = ...

-- Secret value helpers
function AddonTable.isSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end

function AddonTable.isSecretTable(value)
    return issecrettable ~= nil and issecrettable(value) == true
end

-- type() reports the real type of a secret, so numbers need both checks.
function AddonTable.isUsableNumber(value)
    return type(value) == "number" and not AddonTable.isSecret(value)
end

function AddonTable.isRestricted(restrictionName)
    local restrictions = C_RestrictedActions
    local restrictionTypes = Enum and Enum.AddOnRestrictionType
    if not (restrictions and restrictionTypes) then
        return false
    end

    local restrictionType = restrictionTypes[restrictionName]
    if restrictionType == nil then
        return false
    end

    local states = Enum.AddOnRestrictionState
    if restrictions.GetAddOnRestrictionState and states then
        return restrictions.GetAddOnRestrictionState(restrictionType) ~= states.Inactive
    end

    return restrictions.IsAddOnRestrictionActive ~= nil
        and restrictions.IsAddOnRestrictionActive(restrictionType) == true
end

function AddonTable.guard(tag, fn, ...)
    local results = { pcall(fn, ...) }

    if results[1] then
        return unpack(results, 2)
    end

    if BrokerTinyGuildDB and BrokerTinyGuildDB.debug then
        local err = results[2]
        if AddonTable.isSecret(err) or type(err) ~= "string" then
            err = "<error message was secret>"
        end
        print("|cffff4040TinyGuild|r [" .. tag .. "] " .. err)
    end

    return nil
end

-- Debug helper function
function AddonTable.debugPrint(message)
    if BrokerTinyGuildDB and BrokerTinyGuildDB.debug then
        print("Broker_TinyGuild: " .. tostring(message))
    end
end

-- Timerunning icon functionality
function AddonTable.addTimerunningIcon(name)
    if name and (AddonTable.isSecret(name) or name ~= "") then
        return "|TInterface\\AddOns\\Broker_TinyGuild\\Textures\\timerunning-glues-icon-small.png:9:9|t" .. name
    end
    return name
end

-- Sanitize name to remove duplicate realm suffixes (e.g., "Name-Realm-Realm-Realm" -> "Name-Realm")
-- This is to prevent duplicate realm names when we get faulty data from the API.
-- Some rainy day I will find the root cause of this and fix it.
function AddonTable.sanitizeName(name)
    if not name or AddonTable.isSecret(name) or name == "" then
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
