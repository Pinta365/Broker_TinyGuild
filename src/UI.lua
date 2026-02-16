-- UI.lua
-- Roster frame UI and display management

local addonName, AddonTable = ...

local function openWhisper(targetName)
    if not targetName or targetName == "" then return end
    if ChatFrameUtil and ChatFrameUtil.SendTell then
        ChatFrameUtil.SendTell(targetName)
    else
        ChatFrame_OpenChat("/w " .. targetName .. " ")
    end
end

-- Mouseover hide timer
AddonTable.hideTimer = nil

function AddonTable.anchorRosterFrame(ldbObject)
    if not AddonTable.rosterFrame then return end
    local isTop = select(2, ldbObject:GetCenter()) > UIParent:GetHeight() / 2
    AddonTable.rosterFrame:ClearAllPoints()
    AddonTable.rosterFrame:SetPoint(isTop and "TOP" or "BOTTOM", ldbObject, isTop and "BOTTOM" or "TOP", 0, 0)
end

function AddonTable.cancelHideTimer()
    if AddonTable.hideTimer then
        AddonTable.hideTimer:Cancel()
        AddonTable.hideTimer = nil
    end
end

function AddonTable.scheduleHide()
    AddonTable.cancelHideTimer()
    AddonTable.hideTimer = C_Timer.NewTimer(0.2, function()
        if AddonTable.rosterFrame and AddonTable.rosterFrame:IsShown() then
            local isOverFrame = AddonTable.rosterFrame:IsMouseOver()
            
            if not isOverFrame then
                AddonTable.rosterFrame:Hide()
            end
        end
        AddonTable.hideTimer = nil
    end)
end

function AddonTable.showGuildRoster(ldbObject)
    if AddonTable.rosterFrame then
        AddonTable.rosterFrame:Hide()
        AddonTable.rosterFrame:SetParent(nil)
        AddonTable.rosterFrame = nil
    end

    local function sortRoster()
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
            elseif AddonTable.SortOrder == "officerNote" then
                return (AddonTable.SortAscending and a.officerNote < b.officerNote) or (not AddonTable.SortAscending and a.officerNote > b.officerNote)
            else
                return a.name < b.name
            end
        end)
    end

    local function sortByHeader(self, button)
        if AddonTable.SortOrder == self.sortType then
            AddonTable.SortAscending = not AddonTable.SortAscending
        else
            AddonTable.SortOrder = self.sortType
            AddonTable.SortAscending = true
        end
        BrokerTinyGuildDB.sortOrder = AddonTable.SortOrder
        BrokerTinyGuildDB.sortAscending = AddonTable.SortAscending
        sortRoster()
        AddonTable.showGuildRoster(ldbObject)
    end

    if AddonTable.SortOrder == "officerNote" and not (AddonTable.hasOfficerNotes and BrokerTinyGuildDB.showOfficerNotes) then
        AddonTable.SortOrder = "name"
        AddonTable.SortAscending = true
    end

    sortRoster()

    AddonTable.currentLDBObject = ldbObject

    local headerPadding = 10
    local nameHorizontalPosition = 10
    local levelHorizontalPosition = AddonTable.nameMaxWidth + 20
    local RankHorizontalPosition = levelHorizontalPosition+40
    local zoneHorizontalPosition = RankHorizontalPosition+AddonTable.rankMaxWidth+10
    local publicNoteHorizontalPosition = zoneHorizontalPosition + AddonTable.zoneMaxWidth + 10
    local officerNoteHorizontalPosition = 0
    local totalWidth
  
    local verticalOffset = 25
    local verticalIncrement = 15
    local horizontalOffset = 15

    if AddonTable.hasOfficerNotes and BrokerTinyGuildDB.showOfficerNotes then
        officerNoteHorizontalPosition = publicNoteHorizontalPosition + AddonTable.publicNoteMaxWidth + 10
        totalWidth = officerNoteHorizontalPosition + AddonTable.officerNoteMaxWidth + headerPadding
    else
        totalWidth = publicNoteHorizontalPosition + AddonTable.publicNoteMaxWidth + headerPadding
    end
    local totalHeight = #AddonTable.guildRoster * verticalIncrement + 60
    
    AddonTable.rosterFrame = CreateFrame("Frame", nil, BrokerTinyGuild, "TooltipBorderedFrameTemplate")
    AddonTable.rosterFrame:SetFrameStrata("HIGH")
    AddonTable.rosterFrame:SetSize(totalWidth, totalHeight)
    
    local opacity = (BrokerTinyGuildDB and BrokerTinyGuildDB.backgroundOpacity) or 0.8
    AddonTable.rosterFrame:SetBackdropColor(0, 0, 0, opacity)

    if AddonTable.GMOTD then
        local motdHeader = AddonTable.rosterFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        motdHeader:SetPoint("TOPLEFT", 10, -10) 
        motdHeader:SetText(WrapTextInColorCode(AddonTable.GMOTD, "ff19ff19"))
        motdHeader:SetWordWrap(true)
        motdHeader:SetWidth(AddonTable.rosterFrame:GetWidth() - 20)

        verticalOffset = verticalOffset + motdHeader:GetStringHeight() + 10
        totalHeight = totalHeight +motdHeader:GetStringHeight() + 10
        AddonTable.rosterFrame:SetSize(totalWidth, totalHeight)
    end

    local function createSortHeader(label, sortType, xPos)
        local header = CreateFrame("Button", nil, AddonTable.rosterFrame)
        local headerText = header:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        header:SetPoint("TOPLEFT", xPos + headerPadding, -(verticalOffset - 15))
        header:RegisterForClicks("LeftButtonUp")
        headerText:SetPoint("LEFT", 0, 0)
        headerText:SetText(label)
        header.sortType = sortType
        header:SetScript("OnClick", sortByHeader)

        local arrow = header:CreateTexture(nil, "ARTWORK")
        arrow:SetAtlas("auctionhouse-ui-sortarrow")
        arrow:SetSize(9, 9)
        arrow:SetPoint("LEFT", headerText, "RIGHT", 3, 0)

        if AddonTable.SortOrder == sortType then
            arrow:Show()
            if AddonTable.SortAscending then
                arrow:SetTexCoord(0, 1, 1, 0)
            else
                arrow:SetTexCoord(0, 1, 0, 1)
            end
        else
            arrow:Hide()
        end

        header:SetSize(headerText:GetStringWidth() + 20, 15)
        return header
    end

    createSortHeader("Name", "name", nameHorizontalPosition)
    createSortHeader("Level", "level", levelHorizontalPosition)
    createSortHeader("Rank", "rank", RankHorizontalPosition)
    createSortHeader("Zone", "zone", zoneHorizontalPosition)
    createSortHeader("Public Note", "note", publicNoteHorizontalPosition)

    if AddonTable.hasOfficerNotes and BrokerTinyGuildDB.showOfficerNotes then
        createSortHeader("Officer Note", "officerNote", officerNoteHorizontalPosition)
    end

    local headerAreaHeight = verticalOffset
    local footerHeight = 30
    local contentHeight = #AddonTable.guildRoster * verticalIncrement
    local scrollbarWidth = 16
    local maxScrollArea = (UIParent:GetHeight() * 0.6) - headerAreaHeight - footerHeight
    local needsScroll = contentHeight > maxScrollArea
    local scrollAreaHeight = needsScroll and maxScrollArea or contentHeight

    if needsScroll then
        totalWidth = totalWidth + scrollbarWidth
    end

    totalHeight = headerAreaHeight + scrollAreaHeight + footerHeight
    AddonTable.rosterFrame:SetSize(totalWidth, totalHeight)

    local scrollFrame = CreateFrame("ScrollFrame", nil, AddonTable.rosterFrame)
    scrollFrame:SetPoint("TOPLEFT", 0, -headerAreaHeight)
    scrollFrame:SetPoint("TOPRIGHT", needsScroll and -scrollbarWidth or 0, -headerAreaHeight)
    scrollFrame:SetHeight(scrollAreaHeight)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(totalWidth - (needsScroll and scrollbarWidth or 0))
    scrollChild:SetHeight(contentHeight)
    scrollFrame:SetScrollChild(scrollChild)

    if needsScroll then
        local scrollbar = CreateFrame("Slider", nil, AddonTable.rosterFrame)
        scrollbar:SetPoint("TOPRIGHT", -4, -headerAreaHeight)
        scrollbar:SetPoint("BOTTOMRIGHT", -4, footerHeight)
        scrollbar:SetWidth(scrollbarWidth)
        scrollbar:SetMinMaxValues(0, contentHeight - scrollAreaHeight)
        scrollbar:SetValueStep(verticalIncrement)
        scrollbar:SetObeyStepOnDrag(true)
        scrollbar:SetValue(0)

        local thumbTexture = scrollbar:CreateTexture(nil, "ARTWORK")
        thumbTexture:SetColorTexture(0.5, 0.5, 0.5, 0.7)
        thumbTexture:SetSize(scrollbarWidth - 4, 40)
        scrollbar:SetThumbTexture(thumbTexture)

        scrollbar:SetScript("OnValueChanged", function(self, value)
            scrollFrame:SetVerticalScroll(value)
        end)

        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local current = scrollbar:GetValue()
            local step = verticalIncrement * 3
            scrollbar:SetValue(current - (delta * step))
        end)
    end

    local rowOffset = 0
    for i, member in ipairs(AddonTable.guildRoster) do
        local memberFrame = CreateFrame("Button", nil, scrollChild)
        memberFrame:SetPoint("TOPLEFT", horizontalOffset, -rowOffset)
        local rowWidth = scrollChild:GetWidth() - (2 * horizontalOffset)
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
        zoneText:SetPoint("LEFT", zoneHorizontalPosition, 0)
        memberFrame.zoneText = zoneText

        local publicNoteText = memberFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        publicNoteText:SetPoint("LEFT", publicNoteHorizontalPosition, 0)
        memberFrame.publicNoteText = publicNoteText

        if AddonTable.hasOfficerNotes and BrokerTinyGuildDB.showOfficerNotes then
            local officerNoteText = memberFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            officerNoteText:SetPoint("LEFT", officerNoteHorizontalPosition, 0)
            officerNoteText:SetText(member.officerNote)
            memberFrame.officerNoteText = officerNoteText
        end

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

        local groupIndicatorName = nil
        if member.name then
            if Ambiguate then
                groupIndicatorName = Ambiguate(member.name, "short")
            else
                local dashPos = string.find(member.name, "-")
                if dashPos then
                    groupIndicatorName = string.sub(member.name, 1, dashPos - 1)
                else
                    groupIndicatorName = member.name
                end
            end
        end

        local displayName = member.name

        if member.isInTimerunning then
            displayName = AddonTable.addTimerunningIcon(displayName)
        end

        if groupIndicatorName then
            if UnitInParty(groupIndicatorName) or UnitInRaid(groupIndicatorName) then
                nameText:SetText("*" .. displayName)
            else
                nameText:SetText(displayName)
            end
        else
            nameText:SetText(displayName)
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
                openWhisper(member.name)
            elseif button == "RightButton" then
                C_PartyInfo.InviteUnit(member.name)
            end
        end)

        rowOffset = rowOffset + verticalIncrement
    end

    local footer = CreateFrame("Frame", nil, AddonTable.rosterFrame)
    footer:SetPoint("BOTTOMLEFT", AddonTable.rosterFrame, "BOTTOMLEFT", 10, 10)
    footer:SetPoint("BOTTOMRIGHT", AddonTable.rosterFrame, "BOTTOMRIGHT", -10, 10)
    footer:SetHeight(20)

    local footerHint = footer:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footerHint:SetPoint("LEFT")
    footerHint:SetText("|cFFAAAAAALeft-Click to whisper | Right-Click to invite|r")

    local optionsButton = CreateFrame("Button", nil, footer)
    optionsButton:SetPoint("RIGHT")
    optionsButton:SetSize(60, 20)

    local optionsText = optionsButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    optionsText:SetPoint("CENTER")
    optionsText:SetText("Options")
    optionsText:SetJustifyH("RIGHT")

    optionsButton:SetScript("OnEnter", function()
        AddonTable.cancelHideTimer()
    end)

    optionsButton:SetScript("OnLeave", function()
        AddonTable.scheduleHide()
    end)

    optionsButton:SetScript("OnClick", function(self, button)
        -- Support both Modern Settings API and Legacy Interface Options
        if Settings and AddonTable.settingsCategory then
            -- Modern Settings API (Retail)
            Settings.OpenToCategory(AddonTable.settingsCategory.ID)
        elseif AddonTable.optionsPanel then
            -- Legacy Interface Options (Classic/Vanilla)
            InterfaceOptionsFrame_OpenToCategory(AddonTable.optionsPanel)
        elseif InterfaceOptionsFrame_OpenToCategory then
            -- Fallback: try by name
            InterfaceOptionsFrame_OpenToCategory("TinyGuild")
        end
    end)

    AddonTable.cancelHideTimer()
    AddonTable.rosterFrame:Show()
    AddonTable.rosterFrame:SetClampedToScreen(true)

    AddonTable.anchorRosterFrame(ldbObject)

    AddonTable.rosterFrame:HookScript("OnEnter", function()
        AddonTable.cancelHideTimer()
    end)

    AddonTable.rosterFrame:HookScript("OnLeave", function()
        AddonTable.scheduleHide()
    end)

    AddonTable.rosterFrame:HookScript("OnHide", function()
        AddonTable.cancelHideTimer()
    end)
end

