-- Broker_TinyGuild.lua
-- Main initialization and event handling

local addonName, AddonTable = ...

local function initTinyGuild()
    AddonTable.guildRoster = {}
    AddonTable.tempFontString = BrokerTinyGuild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    C_GuildInfo.GuildRoster()

    -- Initialize saved variables
    AddonTable.initSettings()

    -- Load persisted sort settings
    AddonTable.SortOrder = BrokerTinyGuildDB.sortOrder or "name"
    AddonTable.SortAscending = BrokerTinyGuildDB.sortAscending
    if AddonTable.SortAscending == nil then AddonTable.SortAscending = true end
end

local function onEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        initTinyGuild()
        AddonTable.initBroker()
        AddonTable.initOptionsPanel()
    elseif event == "GUILD_MOTD" then
        AddonTable.updateGMOTD()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local scaleMult = BrokerTinyGuildDB and BrokerTinyGuildDB.scale or 1
        self:SetScale(UIParent:GetScale() * scaleMult)
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
