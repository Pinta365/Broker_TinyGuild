-- BrokerTinyGuild.lua

local addonName, AddonTable = ...
local rosterFrame
local tempFontString

local nameMaxWidth
local rankMaxWidth
local zoneMaxWidth
local publicNoteMaxWidth

local function updateGuildRoster()
    local newRoster = {}
    local numGuildMembers, numOnlineGuildMembers = GetNumGuildMembers()
    local showOffline = GetGuildRosterShowOffline()
    local totalToScan = showOffline and numGuildMembers or numOnlineGuildMembers

    for i = 1, totalToScan do
        local name, rankName, _, level, classDisplayName, zone,
              publicNote, _, isOnline, status, classLocalizationIndependent,
              _, _, _, _, _, guid = GetGuildRosterInfo(i)

        if isOnline then         
            local raceId = guid and C_PlayerInfo.GetRace(PlayerLocation:CreateFromGUID(guid));
            local factionInfo = raceId and C_CreatureInfo.GetFactionInfo(raceId)
            local factionName = factionInfo and factionInfo.groupTag

            if publicNote and #publicNote > 200 then
                publicNote = string.sub(publicNote, 1, 197) .. "..."
            end

            table.insert(newRoster, {
                name = name,
                status = status,
                level = level,
                rankName = rankName,
                classDisplayName = classDisplayName,
                classLocalizationIndependent = classLocalizationIndependent,
                factionName = factionName,
                zone = zone,
                publicNote = publicNote,
            })
        end
    end

    wipe(AddonTable.guildRoster)

    for i, member in ipairs(newRoster) do
        AddonTable.guildRoster[i] = member
    end

    nameMaxWidth = 50
    rankMaxWidth = 20
    zoneMaxWidth = 35
    publicNoteMaxWidth = 200

    for _, member in ipairs(newRoster) do
        tempFontString:SetText(member.name)
        nameMaxWidth = max(nameMaxWidth, tempFontString:GetStringWidth())

        tempFontString:SetText(member.rankName)
        rankMaxWidth = max(rankMaxWidth, tempFontString:GetStringWidth())

        tempFontString:SetText(member.zone)
        zoneMaxWidth = max(zoneMaxWidth, tempFontString:GetStringWidth())

        tempFontString:SetText(member.publicNote)
        publicNoteMaxWidth = max(publicNoteMaxWidth, tempFontString:GetStringWidth())

        if member.factionName == "Alliance" then
            member.factionIcon = "Interface\\FriendsFrame\\PlusManz-Alliance.blp"
        elseif member.factionName == "Horde" then
            member.factionIcon = "Interface\\FriendsFrame\\PlusManz-Horde.blp"
        else
            member.factionIcon = nil
        end
    end

    nameMaxWidth = nameMaxWidth + 15
    rankMaxWidth = rankMaxWidth + 15
    zoneMaxWidth = zoneMaxWidth + 15

    return #newRoster, numGuildMembers
end

local function anchorRosterFrame(ldbObject)
    local isTop = select(2, ldbObject:GetCenter()) > UIParent:GetHeight() / 2
    rosterFrame:ClearAllPoints()
    rosterFrame:SetPoint(isTop and "TOP" or "BOTTOM", ldbObject, isTop and "BOTTOM" or "TOP", 0, 0)
end

local function updateBrokerText()
    if IsInGuild() then
        if (AddonTable.online) then
            if (AddonTable.numGuildMembers > 0) then
                AddonTable.BrokerTinyGuild.text = string.format(WrapTextInColorCode("%s:", "ff40FF40") .. " %d/%d Online", AddonTable.guildName, AddonTable.online, AddonTable.numGuildMembers)
            else
                AddonTable.BrokerTinyGuild.text = string.format(WrapTextInColorCode("%s:", "ff40FF40") .. " %d Online", AddonTable.guildName, AddonTable.online)
            end
        else
            AddonTable.BrokerTinyGuild.text = string.format(WrapTextInColorCode("%s", "ff40FF40"), AddonTable.guildName)
        end
    else
        AddonTable.BrokerTinyGuild.text = "No Guild"
    end
end

local function updateGMOTD()
    AddonTable.GMOTD = GetGuildRosterMOTD()
end

local function updateGuildName()
    AddonTable.guildName = GetGuildInfo("player") or "No Guild"
end

local function updateGuildOnline()

    --delayed throttling so we always got the latest data but after short delay to prevent spamming and resource hogging.
    if not AddonTable.guildListUpdateTimer then
        AddonTable.guildListUpdateTimer = C_Timer.NewTimer(4, function()
            local online, numGuildMembers = updateGuildRoster()
            if online > 0 then
                AddonTable.online = online
                AddonTable.numGuildMembers = numGuildMembers
            else
                AddonTable.online = nil
                AddonTable.numGuildMembers = numGuildMembers
            end
            updateGMOTD()
            updateGuildName()
            updateBrokerText()
            AddonTable.guildListUpdateTimer = nil
        end)
    end

end

local function showGuildRoster(ldbObject)
    if rosterFrame then
        rosterFrame:Hide()
        rosterFrame:SetParent(nil)
        rosterFrame = nil
    end

    local function sortByHeader(self, button)
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
        showGuildRoster(ldbObject)
    end

    local headerPadding = 10
    local nameHorizontalPosition = 10
    local levelHorizontalPosition = nameMaxWidth + 20
    local RankHorizontalPosition = levelHorizontalPosition+40
    local zoneorizontalPosition = RankHorizontalPosition+rankMaxWidth+10
    local publicNoteHorizontalPosition = zoneorizontalPosition+10+zoneMaxWidth

    local verticalOffset = 25
    local verticalIncrement = 15
    local horizontalOffset = 15

    local totalHeight = #AddonTable.guildRoster * verticalIncrement + 60
    local totalWidth = publicNoteHorizontalPosition + publicNoteMaxWidth + headerPadding

    rosterFrame = CreateFrame("Frame", nil, UIParent, "TooltipBorderedFrameTemplate")
    rosterFrame:SetFrameStrata("HIGH")
    rosterFrame:SetSize(totalWidth, totalHeight)

    if AddonTable.GMOTD then
        local motdHeader = rosterFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        motdHeader:SetPoint("TOPLEFT", 10, -10) 
        motdHeader:SetText(WrapTextInColorCode(AddonTable.GMOTD, "ff19ff19"))
        motdHeader:SetWordWrap(true)
        motdHeader:SetWidth(rosterFrame:GetWidth() - 20)

        verticalOffset = verticalOffset + motdHeader:GetStringHeight() + 10
        totalHeight = totalHeight +motdHeader:GetStringHeight() + 10
        rosterFrame:SetSize(totalWidth, totalHeight)
    end

    local nameHeader = CreateFrame("Button", nil, rosterFrame)
    local nameHeaderText = nameHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    nameHeader:SetPoint("TOPLEFT", nameHorizontalPosition + headerPadding, -(verticalOffset - 15))
    nameHeader:RegisterForClicks("LeftButtonUp")
    nameHeaderText:SetPoint("LEFT", 0, 0)
    nameHeaderText:SetText("Name")
    nameHeader:SetSize(nameHeaderText:GetStringWidth() + 10, 15)
    nameHeader.sortType = "name"
    nameHeader:SetScript("OnClick", sortByHeader)

    local levelHeader = CreateFrame("Button", nil, rosterFrame)
    local levelHeaderText = levelHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    levelHeader:SetPoint("TOPLEFT", levelHorizontalPosition + headerPadding, -(verticalOffset - 15))
    levelHeader:RegisterForClicks("LeftButtonUp")
    levelHeaderText:SetPoint("LEFT", 0, 0)
    levelHeaderText:SetText("Level")
    levelHeader:SetSize(levelHeaderText:GetStringWidth() + 10, 15)
    levelHeader.sortType = "level"
    levelHeader:SetScript("OnClick", sortByHeader)

    local RankHeader = CreateFrame("Button", nil, rosterFrame)
    local RankHeaderText = RankHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    RankHeader:SetPoint("TOPLEFT", RankHorizontalPosition + headerPadding, -(verticalOffset - 15))
    RankHeader:RegisterForClicks("LeftButtonUp")
    RankHeaderText:SetPoint("LEFT", 0, 0)
    RankHeaderText:SetText("Rank")
    RankHeader:SetSize(RankHeaderText:GetStringWidth() + 10, 15)
    RankHeader.sortType = "rank"
    RankHeader:SetScript("OnClick", sortByHeader)

    local zoneHeader = CreateFrame("Button", nil, rosterFrame)
    local zoneHeaderText = zoneHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    zoneHeader:SetPoint("TOPLEFT", zoneorizontalPosition + headerPadding, -(verticalOffset - 15))
    zoneHeader:RegisterForClicks("LeftButtonUp")
    zoneHeaderText:SetPoint("LEFT", 0, 0)
    zoneHeaderText:SetText("Zone")
    zoneHeader:SetSize(zoneHeaderText:GetStringWidth() + 10, 15)
    zoneHeader.sortType = "zone"
    zoneHeader:SetScript("OnClick", sortByHeader)

    local publicNoteHeader = CreateFrame("Button", nil, rosterFrame)
    local publicNoteHeaderText = publicNoteHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    publicNoteHeader:SetPoint("TOPLEFT", publicNoteHorizontalPosition + headerPadding, -(verticalOffset - 15))
    publicNoteHeader:RegisterForClicks("LeftButtonUp")
    publicNoteHeaderText:SetPoint("LEFT", 0, 0)
    publicNoteHeaderText:SetText("Public Note")
    publicNoteHeader:SetSize(publicNoteHeaderText:GetStringWidth() + 10, 15)
    publicNoteHeader.sortType = "note"
    publicNoteHeader:SetScript("OnClick", sortByHeader)

    for i, member in ipairs(AddonTable.guildRoster) do
        local memberFrame = CreateFrame("Button", nil, rosterFrame)
        memberFrame:SetPoint("TOPLEFT", horizontalOffset, -verticalOffset)
        local rowWidth = rosterFrame:GetWidth() - (2 * horizontalOffset)
        memberFrame:SetSize(rowWidth, 15)
        memberFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        if member.status and (member.status == 1  or member.status == 2) then
            local statusIcon = memberFrame:CreateTexture(nil, "ARTWORK")
            statusIcon:SetPoint("LEFT", nameHorizontalPosition - 15, 0)
            statusIcon:SetSize(15, 15)
            if member.status == 1 then
                statusIcon:SetTexture(FRIENDS_TEXTURE_AFK)
            else
                statusIcon:SetTexture(FRIENDS_TEXTURE_DND)
            end
        end

        local nameText = memberFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", nameHorizontalPosition, 0)
        memberFrame.nameText = nameText

        local factionIcon = memberFrame:CreateTexture(nil, "ARTWORK")
        factionIcon:SetPoint("LEFT", levelHorizontalPosition - 20, 0)
        factionIcon:SetSize(15, 15)
        if member.factionIcon then
            factionIcon:SetTexture(member.factionIcon)
        end

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

        local classColor = RAID_CLASS_COLORS[member.classLocalizationIndependent]
        if classColor then
            nameText:SetTextColor(classColor.r, classColor.g, classColor.b)
        end

        if i % 2 == 0 then
            local bgTexture = memberFrame:CreateTexture(nil, "BACKGROUND")
            bgTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
            bgTexture:SetVertexColor(0, 0, 0, 0.2)
            bgTexture:SetAllPoints(memberFrame)
        end

        local groupIndicatorName = member.name and string.sub(member.name, 1, string.find(member.name, "-") - 1)

        if groupIndicatorName then
            if UnitInParty(groupIndicatorName) or UnitInRaid(groupIndicatorName) then
                nameText:SetText("*" .. member.name)
            else
                nameText:SetText(member.name)
            end
        end

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

    anchorRosterFrame(ldbObject)

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

local function initBroker()
    local LDB = LibStub("LibDataBroker-1.1")     
    AddonTable.BrokerTinyGuild = LDB:NewDataObject("Broker_TinyGuild", {
        type = "data source",
        text = "TinyGuild Loading",
        icon = "Interface\\AddOns\\KeystoneRoulette\\Textures\\pinta",

        OnClick = function(self, button)
            ToggleGuildFrame()
        end,

        OnEnter = function(self)
            if IsInGuild() and AddonTable.online then
                showGuildRoster(self)
            end
        end,

        OnLeave = function(self)
            if IsInGuild() and rosterFrame and not rosterFrame:IsMouseOver() then
                rosterFrame:Hide()
            end
        end,
    })
end

local function initTinyGuild()
    AddonTable.SortOrder = "name"
    AddonTable.SortAscending = true
    AddonTable.guildRoster = {}
    tempFontString = UIParent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    C_GuildInfo.GuildRoster()
end

local function onEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        initTinyGuild()
        initBroker()
    elseif event == "GUILD_MOTD" then
        updateGMOTD()
    elseif event == "PLAYER_ENTERING_WORLD" then
        --Dirty fix for unguilded, IsInGuild() is not up to speed right away.
        C_Timer.NewTimer(4, function()
            if not IsInGuild() then
                AddonTable.guildName = "No Guild"
                AddonTable.BrokerTinyGuild.text = "No Guild"
            end
        end)
    elseif event == "PLAYER_GUILD_UPDATE" or 
            (IsInGuild() and (event == "GUILD_ROSTER_UPDATE" or
                 event == "GUILD_RANKS_UPDATE")) then
        updateGuildOnline()
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