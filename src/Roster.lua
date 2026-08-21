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

local function getCommunityMembers()
    if not IsInGuild() or AddonTable.isRestricted("Chat") then
        return nil
    end

    if not (C_Club and C_Club.GetGuildClubId and CommunitiesUtil and CommunitiesUtil.GetAndSortMemberInfo) then
        return nil
    end

    local clubId = C_Club.GetGuildClubId()
    if not clubId then
        return nil
    end

    local members = AddonTable.guard("club-members", CommunitiesUtil.GetAndSortMemberInfo, clubId, nil)
    if type(members) ~= "table" or AddonTable.isSecretTable(members) then
        return nil
    end

    return members
end

local function isTimerunning(communityMembers, guid)
    if not communityMembers or guid == nil or AddonTable.isSecret(guid) then
        return false
    end

    for _, memberInfo in ipairs(communityMembers) do
        if AddonTable.isSecret(memberInfo) then
            return false
        end

        local memberGuid = memberInfo.guid
        if not AddonTable.isSecret(memberGuid) and memberGuid == guid
                and memberInfo.timerunningSeasonID then
            return true
        end
    end

    return false
end

local function truncateNote(note)
    if not note or AddonTable.isSecret(note) then
        return note
    end

    if #note > 200 then
        return string.sub(note, 1, 197) .. "..."
    end

    return note
end

local function measure(value, currentMax)
    if value == nil or AddonTable.isSecret(value) then
        return currentMax
    end

    AddonTable.tempFontString:SetText(value)

    local width = AddonTable.tempFontString:GetStringWidth()
    if not AddonTable.isUsableNumber(width) then
        return currentMax
    end

    return max(currentMax, width)
end

function AddonTable.updateGuildRoster()
    local newRoster = {}
    local numGuildMembers, _ = GetNumGuildMembers()

    local communityMembers = getCommunityMembers()

    AddonTable.hasOfficerNotes = false

    for i = 1, numGuildMembers do
        local name, rankName, rankIndex, level, classDisplayName, zone,
              publicNote, officerNote, isOnline, status, classLocalizationIndependent,
              _, _, _, _, _, guid = GetGuildRosterInfo(i)

        if (isOnline) and name then
            name = AddonTable.sanitizeName(name)
            if Ambiguate and not AddonTable.isSecret(name) then
                name = Ambiguate(name, "none")
            end

            local isDuplicate = false
            if not AddonTable.isSecret(name) then
                for _, existingMember in ipairs(newRoster) do
                    if not AddonTable.isSecret(existingMember.name) and existingMember.name == name then
                        isDuplicate = true
                        break
                    end
                end
            end

            if not isDuplicate then
                local factionName
                if guid and not AddonTable.isSecret(guid) then
                    local raceId = C_PlayerInfo.GetRace(PlayerLocation:CreateFromGUID(guid))
                    if raceId and not AddonTable.isSecret(raceId) then
                        local factionInfo = C_CreatureInfo.GetFactionInfo(raceId)
                        factionName = factionInfo and factionInfo.groupTag
                    end
                end

                publicNote = truncateNote(publicNote)
                officerNote = truncateNote(officerNote)

                if officerNote and AddonTable.hasOfficerNotes == false
                        and (AddonTable.isSecret(officerNote) or officerNote ~= "") then
                    AddonTable.hasOfficerNotes = true
                end

                table.insert(newRoster, {
                    name = name,
                    status = status,
                    level = level,
                    rankIndex = rankIndex,
                    rankName = rankName,
                    classDisplayName = classDisplayName,
                    classLocalizationIndependent = classLocalizationIndependent,
                    factionName = factionName,
                    zone = zone,
                    publicNote = publicNote,
                    officerNote = officerNote,
                    isInTimerunning = isTimerunning(communityMembers, guid),
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
        AddonTable.nameMaxWidth = measure(member.name, AddonTable.nameMaxWidth)
        AddonTable.rankMaxWidth = measure(member.rankName, AddonTable.rankMaxWidth)
        AddonTable.zoneMaxWidth = measure(member.zone, AddonTable.zoneMaxWidth)
        AddonTable.publicNoteMaxWidth = measure(member.publicNote, AddonTable.publicNoteMaxWidth)

        if AddonTable.hasOfficerNotes and BrokerTinyGuildDB.showOfficerNotes then
            AddonTable.officerNoteMaxWidth = measure(member.officerNote or "", AddonTable.officerNoteMaxWidth)
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
    if not InCombatLockdown() then
        local motd = (C_GuildInfo and C_GuildInfo.GetMOTD) and C_GuildInfo.GetMOTD() or GetGuildRosterMOTD()
        if motd then AddonTable.GMOTD = motd end
    end
end

function AddonTable.updateGuildName()
    AddonTable.guildName = GetGuildInfo("player") or "No Guild"
end

function AddonTable.updateBrokerText()
    if IsInGuild() then
        if (AddonTable.online) then
            local formatIndex = BrokerTinyGuildDB.brokerTextFormat or 1
            local formatEntry = AddonTable.brokerTextFormats[formatIndex] or AddonTable.brokerTextFormats[1]
            AddonTable.BrokerTinyGuild.text = formatEntry.format(AddonTable.guildName, AddonTable.online, AddonTable.numGuildMembers or 0)
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
            local online, numGuildMembers = AddonTable.guard("roster-update", AddonTable.updateGuildRoster)
            if online and online > 0 then
                AddonTable.online = online
            else
                AddonTable.online = nil
            end
            AddonTable.numGuildMembers = numGuildMembers or AddonTable.numGuildMembers
            AddonTable.updateGMOTD()
            AddonTable.updateGuildName()
            AddonTable.updateBrokerText()
            AddonTable.guildListUpdateTimer = nil
        end)
    end
end
