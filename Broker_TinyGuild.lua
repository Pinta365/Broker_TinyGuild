-- Broker_TinyGuild.lua
-- Main initialization and event handling

local addonName, AddonTable = ...

local function initTinyGuild()
    AddonTable.SortOrder = "name"
    AddonTable.SortAscending = true
    AddonTable.guildRoster = {}
    AddonTable.tempFontString = UIParent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    C_GuildInfo.GuildRoster()
    
    -- Initialize saved variables
    AddonTable.initSettings()
end

local function onEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        initTinyGuild()
        AddonTable.initBroker()
        AddonTable.initOptionsPanel()
    elseif event == "GUILD_MOTD" then
        AddonTable.updateGMOTD()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Dirty fix for unguilded, IsInGuild() is not up to speed right away.
        C_Timer.NewTimer(4, function()
            if not IsInGuild() then
                AddonTable.guildName = "No Guild"
                AddonTable.BrokerTinyGuild.text = "No Guild"
            end
        end)
    elseif event == "PLAYER_GUILD_UPDATE" or 
            (IsInGuild() and (event == "GUILD_ROSTER_UPDATE" or
                 event == "GUILD_RANKS_UPDATE")) then
        AddonTable.updateGuildOnline()
    end
end

local f = CreateFrame("Frame", "BrokerTinyGuild")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GUILD_MOTD")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GUILD_ROSTER_UPDATE")
f:RegisterEvent("GUILD_RANKS_UPDATE")
f:RegisterEvent("PLAYER_GUILD_UPDATE")

f:SetScript("OnEvent", onEvent)
