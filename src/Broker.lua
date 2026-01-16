-- Broker.lua
-- LibDataBroker initialization

local addonName, AddonTable = ...

function AddonTable.initBroker()
    local LDB = LibStub("LibDataBroker-1.1")     
    AddonTable.BrokerTinyGuild = LDB:NewDataObject("Broker_TinyGuild", {
        type = "data source",
        text = "TinyGuild Loading",
        icon = "Interface\\AddOns\\KeystoneRoulette\\Textures\\pinta",

        OnClick = function(self, button)
            ToggleGuildFrame()
        end,

        OnEnter = function(self)
            AddonTable.cancelHideTimer()
            if IsInGuild() and AddonTable.online then
                AddonTable.showGuildRoster(self)
            end
        end,

        OnLeave = function(self)
            AddonTable.scheduleHide()
        end,
    })
end

