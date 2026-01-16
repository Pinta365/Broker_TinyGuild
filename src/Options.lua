-- Options.lua
-- Options panel management

local addonName, AddonTable = ...

function AddonTable.initOptionsPanel()
    -- Create the main options panel frame
    -- Use parent only for modern Settings API (Retail), not for Legacy (Classic/Vanilla)
    local parent = (Settings and Settings.RegisterCanvasLayoutCategory) and InterfaceOptionsFramePanelContainer or nil
    local optionsPanel = CreateFrame("Frame", "BrokerTinyGuildOptionsPanel", parent)
    optionsPanel.name = "TinyGuild"
    
    -- Header
    local header = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    header:SetPoint("TOPLEFT", 16, -16)
    header:SetText("TinyGuild Options")
    
    local yOffset = -50
    
    -- Show Officer Notes checkbox
    local officerNotesCheckbox = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    officerNotesCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    officerNotesCheckbox.Text:SetText("Show Officer Notes")
    officerNotesCheckbox.Text:SetFontObject("GameFontHighlightSmall")
    officerNotesCheckbox:SetScript("OnClick", function(self)
        BrokerTinyGuildDB.showOfficerNotes = self:GetChecked()
    end)
    optionsPanel.officerNotesCheckbox = officerNotesCheckbox
    yOffset = yOffset - 30
    
    -- Show Debug Messages checkbox
    local debugCheckbox = CreateFrame("CheckButton", nil, optionsPanel, "InterfaceOptionsCheckButtonTemplate")
    debugCheckbox:SetPoint("TOPLEFT", 16, yOffset)
    debugCheckbox.Text:SetText("Show Debug Messages")
    debugCheckbox.Text:SetFontObject("GameFontHighlightSmall")
    debugCheckbox:SetScript("OnClick", function(self)
        BrokerTinyGuildDB.debug = self:GetChecked()
        print("Broker_TinyGuild: Debug mode " .. (BrokerTinyGuildDB.debug and "enabled" or "disabled"))
    end)
    optionsPanel.debugCheckbox = debugCheckbox
    yOffset = yOffset - 50
    
    -- Background Opacity slider
    local opacityLabel = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    opacityLabel:SetPoint("TOPLEFT", 16, yOffset)
    opacityLabel:SetText("Background Opacity")
    
    local opacitySlider = CreateFrame("Slider", nil, optionsPanel, "OptionsSliderTemplate")
    opacitySlider:SetPoint("TOPLEFT", opacityLabel, "BOTTOMLEFT", 0, -8)
    opacitySlider:SetWidth(200)
    opacitySlider:SetMinMaxValues(0, 100)
    opacitySlider:SetValueStep(5)
    opacitySlider:SetObeyStepOnDrag(true)
    
    -- Load saved value
    local currentOpacity = (BrokerTinyGuildDB.backgroundOpacity or 0.8) * 100
    opacitySlider:SetValue(currentOpacity)
    
    -- Value display
    local valueText = opacitySlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", opacitySlider, "RIGHT", 10, 0)
    
    -- Slider labels
    local lowLabel = opacitySlider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lowLabel:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", 0, -10)
    lowLabel:SetText("Transparent")
    
    local highLabel = opacitySlider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    highLabel:SetPoint("TOPRIGHT", opacitySlider, "BOTTOMRIGHT", 0, -10)
    highLabel:SetText("Opaque")
    
    local function UpdateOpacityValue()
        local value = opacitySlider:GetValue()
        valueText:SetText(string.format("%d%%", value))
    end
    UpdateOpacityValue()
    
    opacitySlider:SetScript("OnValueChanged", function(self, value)
        local opacity = value / 100
        BrokerTinyGuildDB.backgroundOpacity = opacity
        UpdateOpacityValue()
        
        if AddonTable.rosterFrame and AddonTable.rosterFrame:IsShown() then
            AddonTable.rosterFrame:SetBackdropColor(0, 0, 0, opacity)
        end
    end)
    
    optionsPanel.opacitySlider = opacitySlider
    optionsPanel.opacityValueText = valueText
    
    -- Refresh function to update all controls from database
    local function RefreshOptions()
        if optionsPanel.officerNotesCheckbox then
            optionsPanel.officerNotesCheckbox:SetChecked(BrokerTinyGuildDB.showOfficerNotes ~= false)  -- Default to true
        end
        if optionsPanel.debugCheckbox then
            optionsPanel.debugCheckbox:SetChecked(BrokerTinyGuildDB.debug == true)  -- Default to false
        end
        if optionsPanel.opacitySlider then
            local opacity = (BrokerTinyGuildDB.backgroundOpacity or 0.8) * 100
            optionsPanel.opacitySlider:SetValue(opacity)
            if optionsPanel.opacityValueText then
                optionsPanel.opacityValueText:SetText(string.format("%d%%", opacity))
            end
        end
    end
    
    optionsPanel:SetScript("OnShow", RefreshOptions)
    
    RefreshOptions()
    
    -- Register based on available API
    if Settings and Settings.RegisterCanvasLayoutCategory then
        -- Modern Settings API (Retail)
        local category, layout = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
        Settings.RegisterAddOnCategory(category)
        AddonTable.settingsCategory = category
    else
        -- Legacy Interface Options (Classic/Vanilla)
        InterfaceOptions_AddCategory(optionsPanel)
        AddonTable.optionsPanel = optionsPanel  -- Store reference for opening
    end
end

