-- BrokerTinyGuild.lua

local addonName, AddonTable = ...
local rosterFrame
local tempFontString

local nameMaxWidth = 0
local rankMaxWidth = 0
local zoneMaxWidth = 0
local publicNoteMaxWidth = 200

local function UpdateGuildRoster()
    local newRoster = {}

    local numGuildMembers, numOnlineGuildMembers = GetNumGuildMembers()
    local showOffline = GetGuildRosterShowOffline()
    local totalToScan = showOffline and numGuildMembers or numOnlineGuildMembers

    for i = 1, totalToScan do
        local name, rankName, _, level, classDisplayName, zone,
              publicNote, _, isOnline, _, classLocalizationIndependent = GetGuildRosterInfo(i)

        if isOnline then

            if publicNote and #publicNote > 200 then
                publicNote = string.sub(publicNote, 1, 197) .. "..."
            end

            newRoster[i] = {
                name = name,
                level = level,
                rankName = rankName,
                classDisplayName = classDisplayName,
                classLocalizationIndependent = classLocalizationIndependent,
                zone = zone,
                publicNote = publicNote,
            }
        end
    end

    sort(newRoster, function(a, b)
        if AddonTable.SortOrder == "name" then
            return (AddonTable.SortAscending and a.name < b.name) or (not AddonTable.SortAscending and a.name > b.name)
        elseif AddonTable.SortOrder == "level" then
            return (AddonTable.SortAscending and a.level < b.level) or (not AddonTable.SortAscending and a.level > b.level)
        elseif AddonTable.SortOrder == "rank" then
            return (AddonTable.SortAscending and a.rankName < b.rankName) or (not AddonTable.SortAscending and a.rankName > b.rankName)
        elseif AddonTable.SortOrder == "zone" then
            return (AddonTable.SortAscending and a.zone < b.zone) or (not AddonTable.SortAscending and a.zone > b.zone)
        elseif AddonTable.SortOrder == "note" then
            return (AddonTable.SortAscending and a.publicNote < b.publicNote) or (not AddonTable.SortAscending and a.publicNote > b.publicNote)
        else
            return a.name < b.name
        end
    end)

    wipe(AddonTable.guildRoster)

    for i, member in ipairs(newRoster) do
        AddonTable.guildRoster[i] = member
    end

    nameMaxWidth = 0
    rankMaxWidth = 0
    zoneMaxWidth = 0
    publicNoteMaxWidth = 200

    for i, member in ipairs(newRoster) do
        tempFontString:SetText(member.name)
        nameMaxWidth = max(nameMaxWidth, tempFontString:GetStringWidth())

        tempFontString:SetText(member.rankName)
        rankMaxWidth = max(rankMaxWidth, tempFontString:GetStringWidth())

        tempFontString:SetText(member.zone)
        zoneMaxWidth = max(zoneMaxWidth, tempFontString:GetStringWidth())

        tempFontString:SetText(member.publicNote)
        publicNoteMaxWidth = max(publicNoteMaxWidth, tempFontString:GetStringWidth())
    end

    nameMaxWidth = nameMaxWidth + 15
    rankMaxWidth = rankMaxWidth + 15
    zoneMaxWidth = zoneMaxWidth + 15

    return #newRoster, numGuildMembers
end

local function AnchorRosterFrame(ldbObject)
    local isTop = select(2, ldbObject:GetCenter()) > UIParent:GetHeight() / 2
    rosterFrame:ClearAllPoints()
    rosterFrame:SetPoint(isTop and "TOP" or "BOTTOM", ldbObject, isTop and "BOTTOM" or "TOP", 0, 0)
end

local function updateGMOTD()
    AddonTable.GMOTD = GetGuildRosterMOTD()
end

local function updateGuildName()
    AddonTable.guildName = GetGuildInfo("player") or "No Guild"
end

local function updateGuildOnline()
    local online, _ = UpdateGuildRoster()
    if online > 0 then
        AddonTable.online = online
    else
        AddonTable.online = nil
    end
end

local function ShowGuildRoster(ldbObject)
    if rosterFrame then
        rosterFrame:Hide()
        rosterFrame:SetParent(nil)
        rosterFrame = nil
    end

    local function SortByHeader(self, button)
        if AddonTable.SortOrder == self.sortType then
            AddonTable.SortAscending = not AddonTable.SortAscending
        else
            AddonTable.SortOrder = self.sortType
            AddonTable.SortAscending = true
        end

        sort(AddonTable.guildRoster, function(a, b) 
            if AddonTable.SortOrder == "name" then
                return (AddonTable.SortAscending and a.name < b.name) or (not AddonTable.SortAscending and a.name > b.name)
            elseif AddonTable.SortOrder == "level" then
                return (AddonTable.SortAscending and a.level < b.level) or (not AddonTable.SortAscending and a.level > b.level)
            elseif AddonTable.SortOrder == "rank" then
                return (AddonTable.SortAscending and a.rankName < b.rankName) or (not AddonTable.SortAscending and a.rankName > b.rankName)
            elseif AddonTable.SortOrder == "zone" then
                return (AddonTable.SortAscending and a.zone < b.zone) or (not AddonTable.SortAscending and a.zone > b.zone)
            elseif AddonTable.SortOrder == "note" then
                return (AddonTable.SortAscending and a.publicNote < b.publicNote) or (not AddonTable.SortAscending and a.publicNote > b.publicNote)
            else
                return a.name < b.name
            end
        end)
        ShowGuildRoster(ldbObject)
    end

    local headerPadding = 10
    local nameHorizontalPosition = 0
    local levelHorizontalPosition = nameMaxWidth
    local RankHorizontalPosition = levelHorizontalPosition+40
    local zoneorizontalPosition = RankHorizontalPosition+rankMaxWidth+10
    local publicNoteHorizontalPosition = zoneorizontalPosition+10+zoneMaxWidth

    local verticalOffset = 25
    local verticalIncrement = 15
    local horizontalOffset = 15

    local totalHeight = #AddonTable.guildRoster * verticalIncrement + 50

    rosterFrame = CreateFrame("Frame", nil, UIParent, "TooltipBorderedFrameTemplate")
    rosterFrame:SetSize(publicNoteHorizontalPosition + publicNoteMaxWidth + headerPadding, totalHeight)

    if AddonTable.GMOTD then
        local motdHeader = rosterFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        motdHeader:SetPoint("TOPLEFT", 10, -10) 
        motdHeader:SetText(WrapTextInColorCode(AddonTable.GMOTD, "ff19ff19"))
        motdHeader:SetWordWrap(true)
        motdHeader:SetWidth(rosterFrame:GetWidth() - 20)

        verticalOffset = verticalOffset + motdHeader:GetStringHeight() + 10
        totalHeight = totalHeight +motdHeader:GetStringHeight() + 10
        rosterFrame:SetSize(publicNoteHorizontalPosition + publicNoteMaxWidth + headerPadding, totalHeight)
    end

    local nameHeader = CreateFrame("Button", nil, rosterFrame)  
    local nameHeaderText = nameHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    nameHeader:SetPoint("TOPLEFT", nameHorizontalPosition + headerPadding, -(verticalOffset - 15))
    nameHeader:RegisterForClicks("LeftButtonUp")
    nameHeaderText:SetPoint("LEFT", 0, 0)
    nameHeaderText:SetText("Name")
    nameHeader:SetSize(nameHeaderText:GetStringWidth() + 10, 15)
    nameHeader:SetScript("OnClick", SortByHeader)
    nameHeader.sortType = "name"

    local levelHeader = CreateFrame("Button", nil, rosterFrame)
    local levelHeaderText = levelHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    levelHeader:SetPoint("TOPLEFT", levelHorizontalPosition + headerPadding, -(verticalOffset - 15))
    levelHeader:RegisterForClicks("LeftButtonUp")
    levelHeaderText:SetPoint("LEFT", 0, 0)
    levelHeaderText:SetText("Level")
    levelHeader:SetSize(levelHeaderText:GetStringWidth() + 10, 15)
    levelHeader:SetScript("OnClick", SortByHeader)
    levelHeader.sortType = "level"

    local RankHeader = CreateFrame("Button", nil, rosterFrame)
    local RankHeaderText = RankHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    RankHeader:SetPoint("TOPLEFT", RankHorizontalPosition + headerPadding, -(verticalOffset - 15))
    RankHeader:RegisterForClicks("LeftButtonUp")
    RankHeaderText:SetPoint("LEFT", 0, 0)
    RankHeaderText:SetText("Rank")
    RankHeader:SetSize(RankHeaderText:GetStringWidth() + 10, 15)
    RankHeader:SetScript("OnClick", SortByHeader)
    RankHeader.sortType = "rank"

    local zoneHeader = CreateFrame("Button", nil, rosterFrame)
    local zoneHeaderText = zoneHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    zoneHeader:SetPoint("TOPLEFT", zoneorizontalPosition + headerPadding, -(verticalOffset - 15))
    zoneHeader:RegisterForClicks("LeftButtonUp")
    zoneHeaderText:SetPoint("LEFT", 0, 0)
    zoneHeaderText:SetText("Zone")
    zoneHeader:SetSize(zoneHeaderText:GetStringWidth() + 10, 15)
    zoneHeader:SetScript("OnClick", SortByHeader)
    zoneHeader.sortType = "zone"

    local publicNoteHeader = CreateFrame("Button", nil, rosterFrame)
    local publicNoteHeaderText = publicNoteHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    publicNoteHeader:SetPoint("TOPLEFT", publicNoteHorizontalPosition + headerPadding, -(verticalOffset - 15))
    publicNoteHeader:RegisterForClicks("LeftButtonUp")
    publicNoteHeaderText:SetPoint("LEFT", 0, 0)
    publicNoteHeaderText:SetText("Public Note")
    publicNoteHeader:SetSize(publicNoteHeaderText:GetStringWidth() + 10, 15)
    publicNoteHeader:SetScript("OnClick", SortByHeader)
    publicNoteHeader.sortType = "note"

    for i, member in ipairs(AddonTable.guildRoster) do
        local memberFrame = CreateFrame("Button", nil, rosterFrame)
        memberFrame:SetPoint("TOPLEFT", horizontalOffset, -verticalOffset)
        local rowWidth = rosterFrame:GetWidth() - (2 * horizontalOffset)
        memberFrame:SetSize(rowWidth, 15)
        memberFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        local nameText = memberFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", nameHorizontalPosition, 0)
        memberFrame.nameText = nameText

        local levelText = memberFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        levelText:SetPoint("LEFT", levelHorizontalPosition, 0)
        memberFrame.levelText = levelText

        local rankText = memberFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        rankText:SetPoint("LEFT", RankHorizontalPosition, 0)
        memberFrame.rankText = rankText

        local zoneText = memberFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        zoneText:SetPoint("LEFT", zoneorizontalPosition, 0)
        memberFrame.zoneText = zoneText

        local publicNoteText = memberFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        publicNoteText:SetPoint("LEFT", publicNoteHorizontalPosition, 0)
        memberFrame.publicNoteText = publicNoteText

        local classColor = C_ClassColor.GetClassColor(member.classLocalizationIndependent)
        if classColor then
            nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
        end

        if i % 2 == 0 then
            local bgTexture = memberFrame:CreateTexture(nil, "BACKGROUND")
            bgTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
            bgTexture:SetVertexColor(0, 0, 0, 0.2)
            bgTexture:SetAllPoints(memberFrame)
        end

        nameText:SetText(member.name)
        levelText:SetText(member.level)
        rankText:SetText(member.rankName)
        zoneText:SetText(member.zone)
        publicNoteText:SetText(member.publicNote)

        local highlight = memberFrame:CreateTexture(nil, "BACKGROUND")
        highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight:SetVertexColor(0.2, 0.2, 0.2, 1)
        highlight:SetAllPoints(memberFrame)
        highlight:Hide() 
        memberFrame.highlight = highlight

        memberFrame:SetScript("OnEnter", function(self)
            self.highlight:Show()
        end)

        memberFrame:SetScript("OnLeave", function(self)
            self.highlight:Hide()
        end)

        memberFrame:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                ChatFrame_SendTell(member.name)
            elseif button == "RightButton" then
                C_PartyInfo.InviteUnit(member.name)
            end
        end)

        verticalOffset = verticalOffset + verticalIncrement
    end
    
    local footerText = rosterFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        footerText:SetPoint("BOTTOMRIGHT", rosterFrame, "BOTTOMRIGHT", -10, 10)
        footerText:SetText("|cFFAAAAAALeft-Click to whisper | Right-Click to invite|r")
        footerText:SetJustifyH("RIGHT")
        rosterFrame.footerText = footerText
        
    rosterFrame:Show()
    rosterFrame:SetClampedToScreen(true)

    AnchorRosterFrame(ldbObject)

    rosterFrame:HookScript("OnEnter", function()
        GameTooltip:Show()
    end)

    rosterFrame:HookScript("OnLeave", function()
        if not rosterFrame:IsMouseOver() and not GameTooltip:IsMouseOver() then
            C_Timer.After(0.1, function()
                if not rosterFrame:IsMouseOver() and 
                not GameTooltip:IsMouseOver() then   
                    rosterFrame:Hide()
                end
            end)
        end
    end)
end

local function InitBroker()
    local LDB = LibStub("LibDataBroker-1.1")     
    AddonTable.BrokerTinyGuild = LDB:NewDataObject("Broker_TinyGuild", {
        type = "data source",
        text = "TinyGuild",
        icon = "Interface\\AddOns\\KeystoneRoulette\\Textures\\pinta",

        OnClick = function(self, button)
            --Open guild & communities tab?
        end,

        OnEnter = function(self)
            if IsInGuild() then
                ShowGuildRoster(self)
            end
        end,

        OnLeave = function(self)
            if IsInGuild() and rosterFrame and not rosterFrame:IsMouseOver() then
                rosterFrame:Hide()
            end
        end,
    })
end

local function updateBrokerText()
    if IsInGuild() then
        if (AddonTable.online) then
            AddonTable.BrokerTinyGuild.text = string.format(WrapTextInColorCode("%s:", "ff19ff19") .. " %d Online", AddonTable.guildName, AddonTable.online)
        else
            AddonTable.BrokerTinyGuild.text = string.format(WrapTextInColorCode("%s", "ff19ff19"), AddonTable.guildName)
        end
    else
        AddonTable.BrokerTinyGuild.text = "No Guild"
    end
end

local function InitTinyGuild()
    AddonTable.SortOrder = "name"
    AddonTable.SortAscending = true
    AddonTable.guildRoster = {}
    tempFontString = UIParent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    C_GuildInfo.GuildRoster()
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        InitTinyGuild()
        InitBroker()
    elseif event == "GUILD_MOTD" then
        updateGMOTD()
    elseif event == "PLAYER_ENTERING_WORLD" then
        updateGuildName()
        updateBrokerText()
    elseif event == "PLAYER_GUILD_UPDATE" then
        updateGMOTD()
        updateGuildName()
        updateGuildOnline()
        updateBrokerText()
    elseif IsInGuild() and
            (event == "GUILD_ROSTER_UPDATE" or
            event == "GUILD_RANKS_UPDATE") then
        updateGMOTD()
        updateGuildName()
        updateGuildOnline()
        updateBrokerText()
    end
end

local f = CreateFrame("Frame", "BrokerTinyGuild")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GUILD_MOTD")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GUILD_ROSTER_UPDATE")
f:RegisterEvent("GUILD_RANKS_UPDATE")
f:RegisterEvent("PLAYER_GUILD_UPDATE")

f:SetScript("OnEvent", OnEvent)