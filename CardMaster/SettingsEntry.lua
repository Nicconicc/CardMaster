local _, Addon = ...

local function CloseNativePanel(frame)
    if not frame or not frame:IsShown() then return end
    if HideUIPanel then HideUIPanel(frame) else frame:Hide() end
end

function Addon:RegisterSettingsEntry()
    if self.settingsCategory or not self.db then return end
    local modern = Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory
    if not modern and not InterfaceOptions_AddCategory then return end

    local panel = self.settingsEntry
    if not panel then
        panel = CreateFrame("Frame", "CardMasterSettingsEntry", UIParent)
        panel.name = self.name
        panel:Hide()
        self.settingsEntry = panel
        local content = CreateFrame("Frame", nil, panel)
        content:SetPoint("CENTER", panel, "CENTER")
        panel.content = content

        local logo = content:CreateTexture(nil, "ARTWORK")
        logo:SetTexture("Interface\\AddOns\\CardMaster\\Textures\\Assets\\CMLogo.png")
        logo:SetSize(140, 140)
        local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetTextColor(1, .82, 0)
        local version = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        version:SetTextColor(1, 1, 1)
        local instructions = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        instructions:SetTextColor(1, 1, 1)
        for _, label in ipairs({title, version, instructions}) do label:SetJustifyH("CENTER") end
        local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        button:SetSize(300, 44)
        panel.logo, panel.title, panel.version = logo, title, version
        panel.instructions, panel.openButton = instructions, button

        local function Layout()
            local parts = {logo, title, version, instructions, button}
            local gaps = {14, 28, 14, 24}
            local heights = {logo:GetHeight(), title:GetStringHeight(), version:GetStringHeight(), instructions:GetStringHeight(), button:GetHeight()}
            local height = 0
            for index, h in ipairs(heights) do height = height + h + (gaps[index] or 0) end
            local width = math.max(logo:GetWidth(), title:GetStringWidth(), version:GetStringWidth(), instructions:GetStringWidth(), button:GetWidth())
            content:SetSize(width, height)
            content:SetScale(math.min(1, math.max(1, panel:GetWidth() - 32) / width, math.max(1, panel:GetHeight() - 32) / height))
            local top = height / 2
            for index, part in ipairs(parts) do
                part:ClearAllPoints()
                part:SetPoint("CENTER", content, "CENTER", 0, top - heights[index] / 2)
                top = top - heights[index] - (gaps[index] or 0)
            end
        end
        local function Refresh()
            local english = Addon.db and Addon.db.language == "enUS"
            local font = STANDARD_TEXT_FONT or "Fonts\\ARKai_T.ttf"
            Addon:BindInterfaceFont(title, 36, font, "OUTLINE")
            title:SetText(Addon:T("addonName"))
            Addon:BindInterfaceFont(version, 16, font, "")
            version:SetText((english and "Version: " or "版本：") .. (Addon.buildVersion or Addon.version))
            Addon:BindInterfaceFont(instructions, 16, font, "")
            instructions:SetText(english and "Type /cm to open options" or "输入 /cm 打开选项")
            button:SetText(english and "Open options" or "打开选项")
            local label = button:GetFontString()
            if label then Addon:BindInterfaceFont(label, 22, font, ""); label:SetTextColor(1, .82, 0) end
            Layout()
            if C_Timer and C_Timer.After and not panel.layoutQueued then
                panel.layoutQueued = true
                C_Timer.After(0, function() panel.layoutQueued = nil; Layout() end)
            end
        end
        panel:SetScript("OnSizeChanged", Layout)
        panel:SetScript("OnShow", Refresh)
        button:SetScript("OnClick", function()
            CloseNativePanel(SettingsPanel)
            CloseNativePanel(InterfaceOptionsFrame)
            CloseNativePanel(GameMenuFrame)
            -- This is an open action, not a toggle: an existing window stays open.
            if not (Addon.options and Addon.options:IsShown()) then Addon:ToggleOptions() end
        end)
        panel.OnCommit = function() end
        panel.OnDefault = function() end
        panel.OnRefresh, panel.refresh = Refresh, Refresh
        Refresh()
    end

    if modern then
        local category = Settings.RegisterCanvasLayoutCategory(panel, self.name)
        Settings.RegisterAddOnCategory(category)
        self.settingsCategory = category
    else
        InterfaceOptions_AddCategory(panel)
        self.settingsCategory = panel
    end
end
