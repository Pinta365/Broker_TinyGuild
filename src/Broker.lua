-- Broker.lua
-- LibDataBroker initialization

local addonName, AddonTable = ...

function AddonTable.initBroker()
    local LDB = LibStub("LibDataBroker-1.1")     
    AddonTable.BrokerTinyGuild = LDB:NewDataObject("Broker_TinyGuild", {
        type = "data source",
        text = "TinyGuild Loading",
        icon = "Interface\\AddOns\\Broker_TinyGuild\\Textures\\pinta",

        OnClick = function(self, button)
            if AddonTable.isRestricted("Chat") then
                print("|cff45D388TinyGuild|r: guild frame is blocked by addon restrictions here. Use the micro menu.")
                return
            end
            ToggleGuildFrame()
        end,

        OnEnter = function(self)
            AddonTable.cancelHideTimer()
            if IsInGuild() and AddonTable.online then
                AddonTable.guard("show-roster", AddonTable.showGuildRoster, self)
            end
        end,

        OnLeave = function(self)
            AddonTable.scheduleHide()
        end,
    })
end

