-- Roster.lua
-- Guild roster data management

local addonName, AddonTable = ...

-- Width tracking variables
AddonTable.nameMaxWidth = 50
AddonTable.rankMaxWidth = 20
AddonTable.zoneMaxWidth = 35
AddonTable.publicNoteMaxWidth = 200
AddonTable.officerNoteMaxWidth = 200
AddonTable.hasOfficerNotes = false

function AddonTable.updateGuildRoster()
    local newRoster = {}
    local numGuildMembers, _ = GetNumGuildMembers()
    
    local communityMembers = {}
    if IsInGuild() and C_Club and C_Club.GetGuildClubId and CommunitiesUtil and CommunitiesUtil.GetAndSortMemberInfo then
        local clubId = C_Club.GetGuildClubId()
        if clubId then
            communityMembers = CommunitiesUtil.GetAndSortMemberInfo(clubId, nil) or {}
        end
    end
    
    AddonTable.hasOfficerNotes = false
    
    for i = 1, numGuildMembers do
        local name, rankName, _, level, classDisplayName, zone,
              publicNote, officerNote, isOnline, status, classLocalizationIndependent,
              _, _, _, _, _, guid = GetGuildRosterInfo(i)

        if (isOnline) and name then
            name = AddonTable.sanitizeName(name)
            if Ambiguate then
                name = Ambiguate(name, "none")
            end
            
            local isDuplicate = false
            for _, existingMember in ipairs(newRoster) do
                if existingMember.name == name then
                    isDuplicate = true
                    break
                end
            end
            
            if not isDuplicate then
                local raceId = guid and C_PlayerInfo.GetRace(PlayerLocation:CreateFromGUID(guid));
                local factionInfo = raceId and C_CreatureInfo.GetFactionInfo(raceId)
                local factionName = factionInfo and factionInfo.groupTag

                if publicNote and #publicNote > 200 then
                    publicNote = string.sub(publicNote, 1, 197) .. "..."
                end
                if officerNote and #officerNote > 200 then
                    officerNote = string.sub(officerNote, 1, 197) .. "..."
                end

                if officerNote and officerNote ~= "" and AddonTable.hasOfficerNotes == false then
                    AddonTable.hasOfficerNotes = true
                end

                local isInTimerunning = false
                
                for _, memberInfo in ipairs(communityMembers) do
                    if memberInfo.guid == guid and memberInfo.timerunningSeasonID then
                        isInTimerunning = true
                        break
                    end
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
                    officerNote = officerNote,
                    isInTimerunning = isInTimerunning,
                })
            end
        end
    end

    wipe(AddonTable.guildRoster)

    for i, member in ipairs(newRoster) do
        AddonTable.guildRoster[i] = member
    end

    AddonTable.nameMaxWidth = 50
    AddonTable.rankMaxWidth = 20
    AddonTable.zoneMaxWidth = 35
    AddonTable.publicNoteMaxWidth = 200
    AddonTable.officerNoteMaxWidth = 200

    for _, member in ipairs(newRoster) do
        AddonTable.tempFontString:SetText(member.name)
        AddonTable.nameMaxWidth = max(AddonTable.nameMaxWidth, AddonTable.tempFontString:GetStringWidth())

        AddonTable.tempFontString:SetText(member.rankName)
        AddonTable.rankMaxWidth = max(AddonTable.rankMaxWidth, AddonTable.tempFontString:GetStringWidth())

        AddonTable.tempFontString:SetText(member.zone)
        AddonTable.zoneMaxWidth = max(AddonTable.zoneMaxWidth, AddonTable.tempFontString:GetStringWidth())

        AddonTable.tempFontString:SetText(member.publicNote)
        AddonTable.publicNoteMaxWidth = max(AddonTable.publicNoteMaxWidth, AddonTable.tempFontString:GetStringWidth())

        if AddonTable.hasOfficerNotes and BrokerTinyGuildDB.showOfficerNotes then
            AddonTable.tempFontString:SetText(member.officerNote or "")
            AddonTable.officerNoteMaxWidth = math.max(AddonTable.officerNoteMaxWidth, AddonTable.tempFontString:GetStringWidth())
        end
        
        if member.factionName == "Alliance" then
            member.factionIcon = "Interface\\FriendsFrame\\PlusManz-Alliance.blp"
        elseif member.factionName == "Horde" then
            member.factionIcon = "Interface\\FriendsFrame\\PlusManz-Horde.blp"
        else
            member.factionIcon = nil
        end
    end

    AddonTable.nameMaxWidth = AddonTable.nameMaxWidth + 15
    AddonTable.rankMaxWidth = AddonTable.rankMaxWidth + 15
    AddonTable.zoneMaxWidth = AddonTable.zoneMaxWidth + 15
    
    return #newRoster, numGuildMembers
end

function AddonTable.updateGMOTD()
    AddonTable.GMOTD = GetGuildRosterMOTD()
end

function AddonTable.updateGuildName()
    AddonTable.guildName = GetGuildInfo("player") or "No Guild"
end

function AddonTable.updateBrokerText()
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

function AddonTable.updateGuildOnline()
    -- Delayed throttling so we always got the latest data but after short delay to prevent spamming and resource hogging.
    if not AddonTable.guildListUpdateTimer then
        AddonTable.guildListUpdateTimer = C_Timer.NewTimer(4, function()
            local online, numGuildMembers = AddonTable.updateGuildRoster()
            if online > 0 then
                AddonTable.online = online
                AddonTable.numGuildMembers = numGuildMembers
            else
                AddonTable.online = nil
                AddonTable.numGuildMembers = numGuildMembers
            end
            AddonTable.updateGMOTD()
            AddonTable.updateGuildName()
            AddonTable.updateBrokerText()
            AddonTable.guildListUpdateTimer = nil
        end)
    end
end

