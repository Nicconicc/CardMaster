local _, Addon = ...

local ASSET_ROOT = "Interface\\AddOns\\CardMaster\\Textures\\Assets\\"
local WINDOW_WIDTH, WINDOW_HEIGHT = 960, 860
local FRONT_ART_SIZE = 420

local CHOICE_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function StyleChoice(button, selected)
    button.check:SetShown(selected)
    if selected then
        button:SetBackdropBorderColor(1, 0.82, 0, 1)
        button:SetBackdropColor(0.16, 0.13, 0.07, 0.82)
    else
        button:SetBackdropBorderColor(0.38, 0.38, 0.40, 0.9)
        button:SetBackdropColor(0.10, 0.10, 0.11, 0.72)
    end
end

local function AddFrontSweep(panel, button, art, styleID)
    if not button.CreateMaskTexture or not art.AddMaskTexture or not art.SetVertexOffset then return end
    local factor = FRONT_ART_SIZE / 512
    local root = Addon:GetFrontHighlightRoot(styleID)
    local effects = {}
    for _, channel in ipairs({
        { name = "frame", width = 180, alpha = styleID == 1 and 0.21 or 0.42 },
        { name = "card", width = 360, alpha = styleID == 1 and 0.084 or 0.105 },
    }) do
        local mask = button:CreateMaskTexture(nil, "OVERLAY")
        mask:SetAllPoints(art)
        mask:SetTexture(root .. channel.name .. ".png")

        local band = button:CreateTexture(nil, "OVERLAY")
        band:SetSize(channel.width * factor, 760 * factor)
        band:SetTexture(ASSET_ROOT .. "gradient.tga", "MIRROR")
        band:SetTexCoord(-1, 1, 0, 1)
        band:SetVertexColor(1, 0.94, 0.78, channel.alpha)
        band:SetBlendMode("ADD")
        band:SetPoint("CENTER", art, "CENTER", -430 * factor, 0)
        band:SetVertexOffset(1, 130 * factor, 0)
        band:SetVertexOffset(3, 130 * factor, 0)
        band:SetVertexOffset(2, -130 * factor, 0)
        band:SetVertexOffset(4, -130 * factor, 0)
        band:AddMaskTexture(mask)

        local animation = band:CreateAnimationGroup()
        local sweep = animation:CreateAnimation("Translation")
        sweep:SetOffset(860 * factor, 0)
        sweep:SetDuration(2.8)
        if sweep.SetSmoothing then sweep:SetSmoothing("NONE") end
        if animation.SetLooping then
            animation:SetLooping("REPEAT")
        else
            animation:SetScript("OnFinished", function() animation:Play() end)
        end
        panel.sweepGroups[#panel.sweepGroups + 1] = animation
        effects[#effects + 1] = { name = channel.name, mask = mask, band = band, animation = animation }
    end
    return effects
end

local function SetFrontSweepMode(panel, art, effects, styleID, special)
    if not effects then return end
    local factor = FRONT_ART_SIZE / 512
    local suffix = special and "_2" or ""
    for _, effect in ipairs(effects) do
        effect.animation:Stop()
        effect.mask:SetTexture(Addon:GetFrontHighlightRoot(styleID) .. effect.name .. suffix .. ".png")
        effect.band:ClearAllPoints()
        effect.band:SetPoint("CENTER", art, "CENTER", -430 * factor, 0)
        if panel:IsShown() then effect.animation:Play() end
    end
end

function Addon:DismissWelcomeWindow()
    self.welcomeForcePending = nil
    self.eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if self.welcomeWindow then self.welcomeWindow:Hide() end
end

function Addon:CreateWelcomeWindow()
    if self.welcomeWindow then return self.welcomeWindow end
    self:PickCardFrontShowPreviews()

    local panel = CreateFrame("Frame", "CardMasterWelcome", UIParent, "PortraitFrameTemplate")
    panel:Hide()
    panel:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    panel:SetScale(math.min(1, (UIParent:GetWidth() - 32) / WINDOW_WIDTH,
        (UIParent:GetHeight() - 32) / WINDOW_HEIGHT))
    -- Extend the window downward so the front-choice area keeps its screen position.
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, -30)
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    self:EnableWindowEscape(panel, function() Addon:DismissWelcomeWindow() end)
    if panel.Bg then panel.Bg:SetColorTexture(0.12, 0.12, 0.13, 0.86) end
    self:ApplyWindowLogo(panel)
    local title = panel.TitleText or _G[panel:GetName() .. "TitleText"]
    if title then
        title:SetText(self:T("firstRunTitle"))
        title:SetTextColor(1, 0.82, 0)
    end
    local close = panel.CloseButton or _G[panel:GetName() .. "CloseButton"]
    if close then
        self:StyleButton(close)
        close:SetScript("OnClick", function() Addon:DismissWelcomeWindow() end)
    end
    panel.sweepGroups = {}
    self.welcomeWindow = panel

    local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(intro)
    intro:SetPoint("TOP", panel, "TOP", 0, -51)
    intro:SetText(self:T("firstRunIntro"))

    local frontPanel = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    frontPanel:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -78)
    frontPanel:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -78)
    frontPanel:SetHeight(478)
    frontPanel:SetBackdrop(CHOICE_BACKDROP)
    frontPanel:SetBackdropColor(0.08, 0.08, 0.09, 0.58)
    frontPanel:SetBackdropBorderColor(0.35, 0.35, 0.37, 0.85)

    local frontButtons, backButtons = {}, {}
    local refreshChoices
    local frontStyles = self:GetCardFrontStyles()
    for index, style in ipairs(frontStyles) do
        local id = style.id
        local button = CreateFrame("Button", nil, frontPanel, "BackdropTemplate")
        button:SetSize(440, 442)
        button:SetPoint("TOP", frontPanel, "TOP", (index - 1.5) * 456, -15)
        button:SetBackdrop(CHOICE_BACKDROP)
        local art = button:CreateTexture(nil, "ARTWORK")
        art:SetSize(FRONT_ART_SIZE, FRONT_ART_SIZE)
        art:SetPoint("TOP", 0, -7)
        -- The showcase skill is shared, but each preview uses its own style's
        -- art so the two card fronts remain visually distinct.
        art:SetTexture(style.preview)
        button.art = art
        button.normalPreview = style.preview
        button.check = button:CreateTexture(nil, "OVERLAY")
        button.check:SetSize(24, 24)
        button.check:SetPoint("TOPRIGHT", -4, -4)
        button.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        button:SetScript("OnClick", function()
            Addon.db.cardStyles.front = id
            Addon:RefreshCardStyles()
            refreshChoices()
        end)
        local sweepEffects = AddFrontSweep(panel, button, art, id)
        if id == 2 then
            local previousName = {}
            local function showSpecial(token)
                local specialEntries = Addon:GetCardCollectionEntries(id)
                local entries = specialEntries[token] or {}
                local available = {}
                for _, entry in ipairs(entries) do
                    if entry.available then available[#available + 1] = entry end
                end
                local candidates = #available > 0 and available or entries
                if #candidates == 0 then return end
                local index = random(#candidates)
                if #candidates > 1 and candidates[index].name == previousName[token] then
                    index = index % #candidates + 1
                end
                local entry = candidates[index]
                previousName[token] = entry.name
                art:SetTexture(entry.sourceTexture)
                SetFrontSweepMode(panel, art, sweepEffects, id, true)
            end
            local function restoreFront()
                button:SetScript("OnUpdate", nil)
                button.hoverTime = nil
                art:SetTexture(button.normalPreview)
                SetFrontSweepMode(panel, art, sweepEffects, id, false)
            end
            button.restoreFront = restoreFront
            button:SetScript("OnEnter", function(owner)
                owner.hoverTime = 0
                owner.hoverToken = random(2) == 1 and "BOSS" or "LOOT"
                showSpecial(owner.hoverToken)
                owner:SetScript("OnUpdate", function(self, elapsed)
                    self.hoverTime = self.hoverTime + elapsed
                    if self.hoverTime >= 3 then
                        self.hoverTime = self.hoverTime - 3
                        self.hoverToken = self.hoverToken == "BOSS" and "LOOT" or "BOSS"
                        showSpecial(self.hoverToken)
                    end
                end)
            end)
            button:SetScript("OnLeave", restoreFront)
        end
        frontButtons[#frontButtons + 1] = button
    end

    local showcaseNames = self:GetSharedCardFrontShowNames()
    local currentShowcaseName = self.cardFrontShowcaseName
    local function rotateFrontPreviews()
        if #showcaseNames == 0 then return end
        local index = random(#showcaseNames)
        if #showcaseNames > 1 and showcaseNames[index] == currentShowcaseName then
            index = index % #showcaseNames + 1
        end
        currentShowcaseName = showcaseNames[index]
        for buttonIndex, style in ipairs(frontStyles) do
            local button = frontButtons[buttonIndex]
            button.normalPreview = Addon:GetCardFrontShowTexture(style, currentShowcaseName)
            if not button.hoverTime then
                button.art:SetTexture(button.normalPreview)
            end
        end
    end

    local function scheduleFrontPreviewRotation(generation)
        C_Timer.After(10, function()
            if panel.previewGeneration ~= generation or not panel:IsShown() then return end
            rotateFrontPreviews()
            scheduleFrontPreviewRotation(generation)
        end)
    end

    local backPanel = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    backPanel:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -580)
    backPanel:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -580)
    backPanel:SetHeight(160)
    backPanel:SetBackdrop(CHOICE_BACKDROP)
    backPanel:SetBackdropColor(0.08, 0.08, 0.09, 0.58)
    backPanel:SetBackdropBorderColor(0.35, 0.35, 0.37, 0.85)
    local backScroll = CreateFrame("ScrollFrame", nil, backPanel)
    backScroll:SetPoint("TOPLEFT", backPanel, "TOPLEFT", 28, -14)
    backScroll:SetPoint("TOPRIGHT", backPanel, "TOPRIGHT", -28, -14)
    backScroll:SetHeight(92)
    local backStyles = self:GetCardBackStyles()
    local backContent = CreateFrame("Frame", nil, backScroll)
    backContent:SetHeight(92)
    backContent:SetWidth(#backStyles * 102)
    backScroll:SetScrollChild(backContent)
    for index, style in ipairs(backStyles) do
        local id = style.id
        local button = CreateFrame("Button", nil, backContent, "BackdropTemplate")
        button:SetSize(90, 90)
        button:SetPoint("LEFT", backContent, "LEFT", (index - 1) * 102, 0)
        button:SetBackdrop(CHOICE_BACKDROP)
        local art = button:CreateTexture(nil, "ARTWORK")
        art:SetSize(81, 81)
        art:SetPoint("CENTER")
        art:SetTexture(style.texture)
        button.check = button:CreateTexture(nil, "OVERLAY")
        button.check:SetSize(24, 24)
        button.check:SetPoint("TOPRIGHT", 0, 0)
        button.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        button:SetScript("OnClick", function()
            Addon:SetCardBackStyle(id)
            refreshChoices()
        end)
        button:SetScript("OnEnter", function(owner)
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
            GameTooltip:SetText(Addon:T("backStyle") .. " " .. id)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", GameTooltip_Hide)
        backButtons[#backButtons + 1] = button
    end

    local backSlider
    local leftScrollButton = CreateFrame("Button", nil, backPanel)
    leftScrollButton:SetSize(24, 24)
    leftScrollButton:SetPoint("LEFT", backScroll, "LEFT", -23, -72)
    leftScrollButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    leftScrollButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
    leftScrollButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
    local leftArrow = leftScrollButton:GetNormalTexture()
    if leftArrow and leftArrow.SetRotation then leftArrow:SetRotation(-math.pi / 2) end
    local leftPushedArrow = leftScrollButton:GetPushedTexture()
    if leftPushedArrow and leftPushedArrow.SetRotation then leftPushedArrow:SetRotation(-math.pi / 2) end
    leftScrollButton:SetScript("OnClick", function()
        backSlider:SetValue(math.max(0, backSlider:GetValue() - 102))
    end)

    local rightScrollButton = CreateFrame("Button", nil, backPanel)
    rightScrollButton:SetSize(24, 24)
    rightScrollButton:SetPoint("RIGHT", backScroll, "RIGHT", 23, -72)
    rightScrollButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    rightScrollButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    rightScrollButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
    local rightArrow = rightScrollButton:GetNormalTexture()
    if rightArrow and rightArrow.SetRotation then rightArrow:SetRotation(-math.pi / 2) end
    local rightPushedArrow = rightScrollButton:GetPushedTexture()
    if rightPushedArrow and rightPushedArrow.SetRotation then rightPushedArrow:SetRotation(-math.pi / 2) end
    rightScrollButton:SetScript("OnClick", function()
        local _, maximum = backSlider:GetMinMaxValues()
        backSlider:SetValue(math.min(backSlider:GetValue() + 102, maximum))
    end)

    backSlider = CreateFrame("Slider", nil, backPanel)
    backSlider:SetOrientation("HORIZONTAL")
    backSlider:SetPoint("LEFT", leftScrollButton, "RIGHT", 4, 0)
    backSlider:SetPoint("RIGHT", rightScrollButton, "LEFT", -4, 0)
    backSlider:SetPoint("TOP", backPanel, "TOP", 0, -126)
    backSlider:SetHeight(12)
    backSlider:SetMinMaxValues(0, math.max(0, backContent:GetWidth() - backScroll:GetWidth()))
    backSlider:SetValueStep(1)
    if backSlider.SetObeyStepOnDrag then backSlider:SetObeyStepOnDrag(true) end
    backSlider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    local sliderThumb = backSlider:GetThumbTexture()
    if sliderThumb then sliderThumb:SetSize(24, 24) end
    local sliderTrack = backSlider:CreateTexture(nil, "BACKGROUND")
    sliderTrack:SetColorTexture(0.10, 0.10, 0.11, 0.95)
    sliderTrack:SetPoint("LEFT", 0, 0)
    sliderTrack:SetPoint("RIGHT", 0, 0)
    sliderTrack:SetHeight(6)
    backSlider:SetScript("OnValueChanged", function(_, value)
        backScroll:SetHorizontalScroll(value)
    end)
    local function updateBackScrollRange()
        local maximum = math.max(0, backContent:GetWidth() - backScroll:GetWidth())
        backSlider:SetMinMaxValues(0, maximum)
        backSlider:SetValue(math.min(backSlider:GetValue(), maximum))
    end
    backScroll:HookScript("OnSizeChanged", updateBackScrollRange)

    refreshChoices = function()
        for _, button in ipairs(frontButtons) do
            StyleChoice(button, button == frontButtons[Addon.db.cardStyles.front])
        end
        for _, button in ipairs(backButtons) do
            StyleChoice(button, button == backButtons[Addon.db.cardStyles.back])
        end
    end
    refreshChoices()
    panel.refreshChoices = refreshChoices

    local guide = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(guide)
    guide:SetSize(WINDOW_WIDTH - 70, 24)
    guide:SetPoint("TOP", panel, "TOP", 0, -765)
    guide:SetJustifyH("CENTER")
    guide:SetText("|T" .. ASSET_ROOT .. "CMLogo.png:18:18|t  " .. self:T("firstRunGuide"))
    guide:SetTextColor(0.62, 0.86, 1)

    local done = self:CreateTextButton(panel, 150, 28, self:T("firstRunDone"), function()
        Addon:DismissWelcomeWindow()
    end)
    done:SetPoint("BOTTOM", panel, "BOTTOM", -94, 16)
    local settings = self:CreateTextButton(panel, 160, 28, self:T("firstRunSettings"), function()
        Addon:DismissWelcomeWindow()
        Addon:ToggleOptions()
    end)
    settings:SetPoint("BOTTOM", panel, "BOTTOM", 92, 16)

    local hideWelcome = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    hideWelcome:SetSize(24, 24)
    hideWelcome:SetPoint("BOTTOMLEFT", panel, "BOTTOM", 205, 16)
    hideWelcome:SetChecked(self.db.hideWelcomeOnLogin and true or false)
    hideWelcome:SetScript("OnClick", function(owner)
        Addon.db.hideWelcomeOnLogin = owner:GetChecked() and true or false
    end)
    local hideWelcomeLabel = hideWelcome:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(hideWelcomeLabel)
    hideWelcomeLabel:SetPoint("LEFT", hideWelcome, "RIGHT", 5, 0)
    hideWelcomeLabel:SetText(self:T("hideWelcomeOnLogin"))
    hideWelcomeLabel:SetTextColor(1, 1, 1)
    hideWelcome.label = hideWelcomeLabel

    function panel:RefreshLocale()
        if title then title:SetText(Addon:T("firstRunTitle")) end
        intro:SetText(Addon:T("firstRunIntro"))
        guide:SetText("|T" .. ASSET_ROOT .. "CMLogo.png:18:18|t  " .. Addon:T("firstRunGuide"))
        done:SetText(Addon:T("firstRunDone"))
        settings:SetText(Addon:T("firstRunSettings"))
        hideWelcomeLabel:SetText(Addon:T("hideWelcomeOnLogin"))
        Addon:ApplyLocaleTree(self)
        Addon:FitLocaleLabel(intro, WINDOW_WIDTH-70)
        Addon:FitLocaleLabel(guide, WINDOW_WIDTH-70)
        Addon:FitLocaleLabel(hideWelcomeLabel, 230)
    end
    panel:RefreshLocale()

    panel:HookScript("OnShow", updateBackScrollRange)

    panel:HookScript("OnShow", function()
        panel.refreshChoices()
        panel.previewGeneration = (panel.previewGeneration or 0) + 1
        scheduleFrontPreviewRotation(panel.previewGeneration)
        for _, animation in ipairs(panel.sweepGroups) do animation:Play() end
    end)
    panel:HookScript("OnHide", function()
        panel.previewGeneration = (panel.previewGeneration or 0) + 1
        if frontButtons[2] and frontButtons[2].restoreFront then
            frontButtons[2].restoreFront()
        end
        for _, animation in ipairs(panel.sweepGroups) do animation:Stop() end
    end)
    return panel
end

function Addon:ShowWelcomeWindow(force)
    if not self.db or (self.db.hideWelcomeOnLogin and not force) then return end
    local panel = self:CreateWelcomeWindow()
    panel:RefreshLocale()
    panel:SetScale(math.min(1, (UIParent:GetWidth() - 32) / WINDOW_WIDTH,
        (UIParent:GetHeight() - 32) / WINDOW_HEIGHT))
    panel:Show()
end

function Addon:RefreshWelcomeWindow()
    if self.welcomeWindow then self.welcomeWindow:RefreshLocale() end
end
