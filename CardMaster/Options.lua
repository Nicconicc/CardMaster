local _, Addon = ...
Addon.buildVersion = "1.1.185"

local MODULE_ORDER = { "singleSpell", "inCombat", "afk", "boss", "loot", "levelUp", "countdown" }
local MODULE_NAV_COLORS = {
    { 0.3, 0.9, 1 }, { 1, 0.8, 0.2 }, { 0.7, 0.4, 1 },
    { 1, 0.35, 0.35 }, { 1, 0.6, 0.3 }, { 0.4, 0.65, 1 }, { 0.35, 1, 0.45 },
}

-- The outer PortraitFrameTemplate owns its background and border.  Only the
-- inner BackdropTemplate panes use this backdrop definition.
local PANE_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 5, bottom = 3 },
}

local function addBackdrop(frame, edgeSize)
    local backdrop = PANE_BACKDROP
    if edgeSize then
        backdrop = {
            bgFile = PANE_BACKDROP.bgFile, edgeFile = PANE_BACKDROP.edgeFile,
            tile = true, tileSize = 16, edgeSize = edgeSize,
            insets = { left = 3, right = 3, top = 5, bottom = 3 },
        }
    end
    frame:SetBackdrop(backdrop)
    -- Match WeakAuras' muted charcoal panels while retaining the current
    -- control geometry and behavior.
    -- Secondary panes should remain visibly lighter than the 80% opaque
    -- outer PortraitFrameTemplate background.
    frame:SetBackdropColor(0.12, 0.12, 0.13, 0.6)
    frame:SetBackdropBorderColor(0.34, 0.34, 0.36, 0.9)
end

local function setButtonStyle(button, active)
    if button.kind == "navigation" then
        button.active = active
        button:RefreshHighlight()
        button.label:SetTextColor(0.92, 0.92, 0.92)
    elseif button.kind == "tab" then
        -- The inactive Blizzard tab image has different transparent padding,
        -- so equal texture dimensions still produce a visibly shorter frame.
        -- Use the same shell in both states; text and hover indicate selection.
        button.label:SetTextColor(1, active and 1 or 0.82, active and 1 or 0)
    end
    if button.label then
        Addon:ApplyLocaleFont(button.label)
        Addon:FitLocaleLabel(button.label,button:GetWidth()-(button.kind=="tab" and 12 or 34))
    end
end

function Addon:CreateTextButton(parent, width, height, text, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    local legacy = self:HasLegacyOptionsStyle(parent)
    button:SetSize(width, legacy and height or 24)
    button:SetText(text)
    button.label = button:GetFontString()
    if legacy then button.label:SetTextColor(1, 0.82, 0)
    else self:StyleButton(button) end
    button:SetScript("OnClick", onClick)
    return button
end

local function createNavigationButton(parent, width, height, text, onClick, kind)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    button.kind = kind
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:SetText(text)
    if kind == "tab" then
        local function tabTexture(texture, left, right)
            local region = button:CreateTexture(nil, "BORDER")
            region:SetTexture(texture)
            region:SetTexCoord(left, right, 0, 1)
            region:SetHeight(24)
            return region
        end
        -- One fixed shell for every tab, including unselected tabs.
        button.activeLeft = tabTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab", 0, 0.15625)
        button.activeMiddle = tabTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab", 0.15625, 0.84375)
        button.activeRight = tabTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab", 0.84375, 1)
        for _, trio in ipairs({
            { button.activeLeft, button.activeMiddle, button.activeRight },
        }) do
            trio[1]:SetPoint("LEFT", button, "LEFT")
            trio[1]:SetWidth(20)
            trio[3]:SetPoint("RIGHT", button, "RIGHT")
            trio[3]:SetWidth(20)
            trio[2]:SetPoint("LEFT", trio[1], "RIGHT")
            trio[2]:SetPoint("RIGHT", trio[3], "LEFT")
        end
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
        highlight:SetBlendMode("ADD")
        highlight:SetPoint("LEFT", button, "LEFT", 10, -4)
        highlight:SetPoint("RIGHT", button, "RIGHT", -10, -4)
        highlight:SetHeight(24)
        button.label:SetPoint("CENTER", 0, 0)
    else
        if not parent.selectionStyle then
            parent.selectionStyle = CreateFrame("Button", nil, parent, "OptionsListButtonTemplate")
            parent.selectionStyle:Hide()
        end
        local nativeHighlight = parent.selectionStyle:GetHighlightTexture()
        button.base = button:CreateTexture(nil, "BACKGROUND", nil, -2)
        button.base:SetAllPoints()
        button.base:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp")
        button.base:SetBlendMode("ADD")
        button.base:SetVertexColor(0.5, 0.5, 0.5, 0.125)
        button.selection = button:CreateTexture(nil, "BACKGROUND", nil, -1)
        button.selection:SetAllPoints()
        button.selection:SetTexture(nativeHighlight:GetTexture())
        button.selection:SetTexCoord(nativeHighlight:GetTexCoord())
        button.selection:SetBlendMode(nativeHighlight:GetBlendMode())
        button.selectionColor = { nativeHighlight:GetVertexColor() }
        function button:RefreshHighlight()
            self.selection:SetShown(self.active or self.hovered)
            self.selection:SetDesaturated(not self.active)
            local color = self.selectionColor
            if self.active then
                self.selection:SetVertexColor(unpack(color))
            else
                local gray = color[1] * 0.2126 + color[2] * 0.7152 + color[3] * 0.0722
                self.selection:SetVertexColor(gray, gray, gray, color[4])
            end
        end
        button.topEdge = button:CreateTexture(nil, "BORDER")
        button.topEdge:SetColorTexture(0.45, 0.45, 0.45, 0.15)
        button.topEdge:SetHeight(1)
        button.topEdge:SetPoint("TOPLEFT")
        button.topEdge:SetPoint("TOPRIGHT")
        button.bottomEdge = button:CreateTexture(nil, "BORDER")
        button.bottomEdge:SetColorTexture(0, 0, 0, 0.275)
        button.bottomEdge:SetHeight(1)
        button.bottomEdge:SetPoint("BOTTOMLEFT")
        button.bottomEdge:SetPoint("BOTTOMRIGHT")
        button.icon = button:CreateTexture(nil, "OVERLAY")
        button.icon:SetSize(19.2, 19.2)
        button.icon:SetPoint("LEFT", 4.4, 0)
        local atlasName = "UI-HUD-MicroMenu-Communities-Icon-Notification"
        local getAtlasInfo = (C_Texture and C_Texture.GetAtlasInfo) or GetAtlasInfo
        local atlasInfo
        if getAtlasInfo then
            local ok, info = pcall(getAtlasInfo, atlasName)
            if ok then atlasInfo = info end
        end
        if atlasInfo and button.icon.SetAtlas then
            button.icon:SetAtlas(atlasName, false)
            button.icon:SetDesaturated(true)
        else
            -- Classic clients without this atlas still display a colored diamond.
            button.icon:SetColorTexture(1, 1, 1, 1)
            button.icon:SetSize(8, 8)
            button.icon:ClearAllPoints()
            button.icon:SetPoint("LEFT", 10, 0)
            button.icon:SetRotation(math.pi / 4)
        end
        button.label:SetPoint("LEFT", 28, 0)
        button.label:SetPoint("RIGHT", -3, 0)
        button.label:SetHeight(height)
        button.label:SetJustifyH("LEFT")
        button.label:SetJustifyV("MIDDLE")
        button.label:SetWordWrap(false)
        button:SetScript("OnEnter", function(owner)
            owner.hovered = true
            owner:RefreshHighlight()
        end)
        button:SetScript("OnLeave", function(owner)
            owner.hovered = false
            owner:RefreshHighlight()
        end)
        button:SetScript("OnHide", function(owner)
            owner.hovered = false
            owner.selection:Hide()
        end)
    end
    button:SetScript("OnClick", onClick)
    setButtonStyle(button, false)
    return button
end

local function finishSection(parent, y)
    if parent.currentSection then
        parent.currentSection:SetHeight(math.max(30, parent.sectionTop - y - 8))
        parent.currentSection = nil
    end
end

function Addon:EnableWindowEscape(window, onClose)
    if not self:IsRetail() then return end
    window:EnableKeyboard(true)
    if not InCombatLockdown() then window:SetPropagateKeyboardInput(true) end
    window:HookScript("OnShow", function(owner)
        if not InCombatLockdown() then owner:SetPropagateKeyboardInput(true) end
    end)
    window:SetScript("OnKeyDown", function(owner, key)
        -- Changing keyboard propagation is protected during combat. Hiding
        -- our own unprotected window is still allowed.
        if not InCombatLockdown() then
            owner:SetPropagateKeyboardInput(key ~= "ESCAPE")
        end
        if key == "ESCAPE" then
            if onClose then onClose() else owner:Hide() end
            -- Restore propagation after this key has been consumed, so a
            -- later combat-time reopen does not inherit the Escape setting.
            C_Timer.After(0, function()
                if not InCombatLockdown() then owner:SetPropagateKeyboardInput(true) end
            end)
        end
    end)
end

function Addon:CreateOptions()
    local minWidth, minHeight = 900, 650
    -- WeakAuras builds its options window on PortraitFrameTemplate.  Besides
    -- the familiar metal frame, this provides a dedicated portrait region for
    -- the addon logo without changing the window's existing layout behavior.
    local panel = CreateFrame("Frame", "CardMasterOptions", UIParent, "PortraitFrameTemplate")
    panel:Hide()
    -- Open at the smallest allowed size on first login.  Players can still
    -- drag the resize grip to enlarge it for wider settings pages.
    panel:SetSize(minWidth, minHeight)
    -- The fixed content needs this much room to keep the navigation, sliders,
    -- and footer usable.  The body itself is anchored, so it grows with the panel.
    if panel.SetResizable then pcall(panel.SetResizable, panel, true) end
    local hasNativeMinResize = panel.SetMinResize and pcall(panel.SetMinResize, panel, minWidth, minHeight)
    if not hasNativeMinResize then
        -- Some Classic clients do not expose SetMinResize.  Enforce the same
        -- boundary here instead of allowing an unavailable API to stop loading.
        panel:HookScript("OnSizeChanged", function(self, width, height)
            local newWidth = math.max(minWidth, width)
            local newHeight = math.max(minHeight, height)
            if newWidth ~= width or newHeight ~= height then
                self:SetSize(newWidth, newHeight)
            end
        end)
    end
    panel:SetScale(math.min(1, (UIParent:GetWidth() - 32) / 1000, (UIParent:GetHeight() - 32) / 800))
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    -- Allow the player to park part of the settings panel beyond a screen
    -- edge, matching normal movable addon windows.
    panel:SetClampedToScreen(false)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    -- PortraitFrameTemplate does not supply BackdropTemplate methods on every
    -- Classic client.  Use its native Bg region, as WeakAuras does.
    if panel.Bg then
        -- WeakAuras' PortraitFrameTemplate options background uses 80% alpha.
        panel.Bg:SetColorTexture(0.12, 0.12, 0.13, 0.8)
    end
    self:ApplyWindowLogo(panel)
    panel:Hide()
    -- Modern clients close our window through its own keyboard handler.
    -- Classic clients retain their existing UISpecialFrames behavior.
    self:EnableWindowEscape(panel)
    if not self:IsRetail() and type(UISpecialFrames) == "table" then
        tinsert(UISpecialFrames, panel:GetName())
    end
    self.options = panel

    local title = panel.TitleText or _G[panel:GetName() .. "TitleText"]
    if not title then
        title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -5)
    end
    title:SetText(self:T("addonName") .. " - V" .. self.buildVersion .. " 2026/10/25 2049")
    title:SetTextColor(1, 0.82, 0)
    panel.title = title

    local close = panel.CloseButton or _G[panel:GetName() .. "CloseButton"]
    if not close then
        close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 3, 3)
    end
    -- Keep the native close button's normal, pressed and hover colors.
    close:SetScript("OnClick", function() panel:Hide() end)

    -- Keep resizing on a dedicated grip so normal left-dragging continues to move
    -- the window everywhere else.
    local resizeGrip = CreateFrame("Button", nil, panel)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", -5, 5)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    self:StyleButton(resizeGrip)
    resizeGrip:RegisterForDrag("LeftButton")
    resizeGrip:SetScript("OnDragStart", function()
        panel:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
    end)
    resizeGrip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(Addon:T("resizeHint"))
        GameTooltip:Show()
    end)
    resizeGrip:SetScript("OnLeave", GameTooltip_Hide)
    panel.resizeGrip = resizeGrip

    panel.tabs = {}
    for index, key in ipairs({ "gameplay", "styles", "collection", "misc" }) do
        local button = createNavigationButton(panel, 110, 28, self:T(key), function()
            Addon:SelectMainTab(key)
        end, "tab")
        -- Reserve the top-left portrait area, as WeakAuras does, so the logo
        -- and the first navigation tab never overlap.
        button:SetPoint("TOPLEFT", 72 + (index - 1) * 114, -36)
        panel.tabs[key] = button
    end

    panel.body = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    panel.body:SetPoint("TOPLEFT", 14, -61)
    panel.body:SetPoint("BOTTOMRIGHT", -14, 49)
    addBackdrop(panel.body)
    panel.body:SetBackdropColor(0, 0, 0, 0)

    panel.recycleBin = CreateFrame("Frame", nil, panel)
    panel.recycleBin:Hide()
    self:CreateOptionsFooter(panel)

    -- PortraitFrameTemplate can be shown again while the UI is being rebuilt
    -- by /reload.  Build the page only for an explicit settings open, after
    -- all addon modules and saved settings have finished initializing.
    panel:HookScript("OnShow", function()
        local opening = Addon.optionsOpening
        Addon.optionsOpening = nil
        if not opening then
            panel:Hide()
            return
        end
        Addon:SelectMainTab("collection")
    end)
    self:RegisterOptionsWindow(panel)
end

function Addon:ClearContainer(container)
    if not container then return end
    container.currentSection = nil
    local children = { container:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(self.options.recycleBin)
    end
    if container ~= self.options.body then
        local regions = { container:GetRegions() }
        for _, region in ipairs(regions) do
            region:Hide()
        end
    end
end

function Addon:CreateSectionTitle(parent, text, y)
    finishSection(parent, y)
    if self:HasLegacyOptionsStyle(parent) then
        local area = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        area:SetPoint("TOPLEFT", 4, y - 18)
        area:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, y - 18)
        area:SetHeight(30)
        area:SetFrameLevel(math.max(0, parent:GetFrameLevel() - 1))
        addBackdrop(area)
        area:SetBackdropColor(0.12, 0.12, 0.13, 0.75)
        parent.currentSection = area
        parent.sectionTop = y - 18
        local label = area:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("BOTTOMLEFT", area, "TOPLEFT", 3, 2)
        label:SetText(text)
        label:SetTextColor(1, 0.82, 0)
        return y - 30
    end
    local area = CreateFrame("Frame", nil, parent)
    area:SetPoint("TOPLEFT", 8, y)
    area:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
    area:SetHeight(18)
    local label = area:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(label)
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(1, 0.82, 0)
    -- Anchor each rule to the caption so the gap also follows translated text.
    local left = area:CreateTexture(nil, "ARTWORK")
    left:SetColorTexture(0.5, 0.5, 0.5, 0.45)
    left:SetHeight(1)
    left:SetPoint("LEFT", area, "LEFT")
    left:SetPoint("RIGHT", label, "LEFT", -8, 0)
    local right = area:CreateTexture(nil, "ARTWORK")
    right:SetColorTexture(0.5, 0.5, 0.5, 0.45)
    right:SetHeight(1)
    right:SetPoint("LEFT", label, "RIGHT", 8, 0)
    right:SetPoint("RIGHT", area, "RIGHT")
    return y - 30
end

function Addon:CreateCheckbox(parent, text, checked, onChanged, y)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 12, y)
    local legacy = self:HasLegacyOptionsStyle(parent)
    check:SetSize(legacy and 28 or 24, legacy and 28 or 24)
    check:SetChecked(checked)
    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(check.label)
    check.label:SetPoint("LEFT", check, "RIGHT", legacy and 5 or 0, 0)
    check.label:SetText(text)
    check.label:SetTextColor(1, 1, 1)
    local available = parent:GetWidth() - 62
    if available > 0 then self:FitLocaleLabel(check.label,available) end
    check:SetScript("OnClick", function(self) onChanged(self:GetChecked() and true or false) end)
    return y - (legacy and 38 or 34)
end

function Addon:CreateSlider(parent, labelText, minValue, maxValue, step, value, onChanged, y, suffix)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(240, 49)
    row:SetPoint("TOPLEFT", 16, y)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(label)
    label:SetPoint("TOPLEFT", 0, -3)
    label:SetText(labelText)
    label:SetTextColor(1, 1, 1)
    self:FitLocaleLabel(label,240)
    local slider = self:CreateSpinBox(row, 230, minValue, maxValue, step)
    slider:SetPoint("TOPLEFT", 4, -20)
    slider.suffix = suffix
    -- Initial construction must not change saved settings or trigger previews.
    slider:SetValue(value)
    slider:SetScript("OnValueChanged", function(owner, newValue)
        if not owner.silent then onChanged(newValue) end
    end)
    row.slider = slider
    return y - 49
end

function Addon:CreateDropdown(parent, labelText, choices, selected, onChanged, y)
    local legacy = self:HasLegacyOptionsStyle(parent)
    local dropdown = self:CreateChoiceSelect(parent, legacy and 360 or 230, labelText, choices, selected, onChanged)
    dropdown:SetPoint("TOPLEFT", 16, y)
    return y - (legacy and 72 or 54)
end

function Addon:CreateActionRow(parent, moduleKey, y)
    local test = self:CreateTextButton(parent, 150, 32, self:T("test"), function()
        Addon:ShowCard(moduleKey, nil, true)
    end)
    test:SetPoint("TOPLEFT", 16, y)
    local anchor = self.anchors[moduleKey]
    local move
    move = self:CreateTextButton(parent, 150, 32, anchor and anchor:IsShown() and self:T("lock") or self:T("move"), function()
        Addon:ToggleAnchor(moduleKey)
        local currentAnchor = Addon.anchors[moduleKey]
        move.label:SetText(currentAnchor and currentAnchor:IsShown() and Addon:T("lock") or Addon:T("move"))
    end)
    move:SetPoint("TOPLEFT", 178, y)
    return y - 48
end

-- Keep the enable checkbox and action buttons outside the
-- scrolling settings content.  The callbacks are supplied by each page, so
-- this is purely a presentation/interaction change.
function Addon:BuildPinnedModuleHeader(parent, moduleTitle, enabled, onEnabled, testText, testClick, resetText, resetClick, moveText, moveClick, moveUpdate, extraCheckText, extraCheckValue, extraCheckChanged)
    local header = parent.stickyHeader
    if not header then return -12 end
    self:ClearContainer(header)
    local y = -10
    local enableText = self:L("启动模块", "Enable module")
    y = self:CreateCheckbox(header, enableText, enabled, onEnabled, y)
    if extraCheckText then
        local extra = CreateFrame("CheckButton", nil, header, "UICheckButtonTemplate")
        extra:SetPoint("TOPLEFT", 176, y + 34)
        extra:SetSize(24, 24)
        extra:SetChecked(extraCheckValue and true or false)
        extra.label = extra:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        self:SetControlFont(extra.label)
        extra.label:SetPoint("LEFT", extra, "RIGHT", 0, 0)
        extra.label:SetText(extraCheckText)
        extra.label:SetTextColor(1, 1, 1)
        extra:SetScript("OnClick", function(self)
            extraCheckChanged(self:GetChecked() and true or false)
        end)
    end
    local buttonIndex = 0
    local function placeButton(button)
        button:SetPoint("TOPLEFT", 16 + buttonIndex * 162, y)
        buttonIndex = buttonIndex + 1
    end
    if testText then
        local test = self:CreateTextButton(header, 150, 28, self:T("test"), testClick)
        placeButton(test)
        if not enabled then test:Disable() end
    end
    if moveText then
        local move = self:CreateTextButton(header, 150, 28, moveText, moveClick)
        placeButton(move)
        if moveUpdate then move:SetScript("OnUpdate", moveUpdate) end
        if not enabled then move:Disable() end
    end
    if resetText then
        local reset = self:CreateTextButton(header, 150, 28, resetText, resetClick)
        placeButton(reset)
    end
    -- Reserve only the checkbox/button row and its lower spacing.
    local bottomY = y - 24
    finishSection(header, bottomY - 12)
    header:SetHeight(-bottomY + 12)
    return -12
end

function Addon:BuildIntegratedModulePage(parent, moduleKey)
    self:ClearContainer(parent)
    local single = moduleKey == "singleSpell"
    local module = single and self.SingleSpell or self.CombatIn
    local db = self.legacyDB
    local function text(zh, en) return self:L(zh, en) end
    local enabled = self:IsIntegratedEnabled(moduleKey)
    local y = self:BuildPinnedModuleHeader(parent, self:T(moduleKey), enabled, function(value)
        self:SetIntegratedEnabled(moduleKey, value)
        self:BuildModulePage(parent, moduleKey)
    end, text("测试效果", "Test effect"), function()
        if single then module.TriggerAnimation(nil) else module.Play() end
    end, text("恢复默认", "Reset module"), function()
        self:ResetIntegratedModule(moduleKey)
        self:BuildModulePage(parent, moduleKey)
    end, module.IsDragging() and self:T("lock") or self:T("move"), function(button)
        local dragging = module.ToggleDragMode()
        button.label:SetText(dragging and self:T("lock") or self:T("move"))
    end, function(button)
        local label = module.IsDragging() and self:T("lock") or self:T("move")
        if button.label:GetText() ~= label then button.label:SetText(label) end
    end, (not single) and text("最下层级显示（被其它UI遮挡）", "Show at bottom layer (behind other UI)") or nil, (not single) and (db.ciBottomLayer == true) or nil, (not single) and function(value)
        db.ciBottomLayer = value
        module.UpdateSettings()
    end)
    y = self:CreateSectionTitle(parent, self:T("appearance"), y)
    local function slider(key, zh, en, minimum, maximum, step, suffix)
        y = self:CreateSlider(parent, text(zh, en), minimum, maximum, step, db[key], function(value)
            db[key] = value
            if single then module.UpdateDragSize() else module.UpdateSettings() end
        end, y, suffix)
    end
    if single then
        slider("scale", "缩放", "Scale", 0.1, 1, 0.1)
        slider("rotateAngle", "旋转", "Rotation", -90, 90, 5, "°")
        y = self:CreateSectionTitle(parent, self:T("inAnimation"), y)
        slider("slideX", "入场偏移X", "Entry X offset", -500, 500, 10)
        slider("slideY", "入场偏移Y", "Entry Y offset", -500, 500, 10)
        y = self:CreateSectionTitle(parent, self:T("outAnimation"), y)
        slider("slideOutX", "出场偏移X", "Exit X offset", -500, 500, 10)
        slider("slideOutY", "出场偏移Y", "Exit Y offset", -500, 500, 10)
        slider("mainDuration", "停留时间", "Hold duration", 0.5, 3, 0.1, "s")
        y = self:CreateSectionTitle(parent, text("缩放与叠加", "Zoom and stacking"), y)
        y = self:CreateDropdown(parent, text("缩放动画类型", "Zoom animation type"), {text("旋转形态", "Flip"), text("正常形态", "Normal")}, db.zoomType, function(value) db.zoomType = value end, y)
        slider("zoomW", "缩放动画X", "Animation zoom X", 0.1, 2, 0.1)
        slider("zoomH", "缩放动画Y", "Animation zoom Y", 0.1, 2, 0.1)
        y = self:CreateDropdown(parent, text("多张卡牌叠加类型", "Card stacking type"), {text("横向排列", "Horizontal"), text("随机排列", "Random")}, db.stackType, function(value)
            db.stackType = value
            self:BuildIntegratedModulePage(parent, moduleKey)
        end, y)
        if db.stackType == 2 then
            slider("randomOffsetX", "随机X偏移", "Random X offset", 0, 500, 10)
            slider("randomOffsetY", "随机Y偏移", "Random Y offset", 0, 500, 10)
            slider("randomRotation", "随机旋转", "Random rotation", 0, 180, 5, "°")
        end
    else
        slider("ciScale", "缩放", "Scale", 0.5, 1, 0.1)
        slider("ciSpeed", "动画速度（60 为原速）", "Animation speed (60 = normal)", 15, 120, 5)
        slider("ciCardSpacing", "每张卡牌的间隔距离", "Card spacing", 50, 250, 10)
        slider("ciCardRandomX", "每张卡牌的X随机偏移", "Random X offset per card", 0, 200, 10)
        slider("ciCardRandomY", "每张卡牌的Y随机偏移", "Random Y offset per card", 0, 200, 10)
        slider("ciCardRandomRotation", "每张卡牌的随机旋转", "Random rotation per card", 0, 45, 1, "°")
        y = self:CreateSectionTitle(parent, self:T("trigger"), y)
        y = self:CreateCheckbox(parent, text("进入普通战斗时加载", "Play on normal combat"), db.ciNormalCombat, function(value) db.ciNormalCombat = value end, y)
        y = self:CreateCheckbox(parent, text("进入首领战斗时加载", "Play on boss combat"), db.ciBossCombat, function(value) db.ciBossCombat = value end, y)
    end
    local moduleConfig = self.db.modules[moduleKey]
    y = self:CreateSectionTitle(parent, text("声音", "Sound"), y)
    y = self:CreateCheckbox(parent, text("启动音效", "Enable sound"), moduleConfig.soundEnabled ~= false, function(value)
        moduleConfig.soundEnabled = value
    end, y)
    finishSection(parent, y)
    parent:SetHeight(math.max(580, -y + 32))
end


function Addon:BuildAFKPage(parent)
    self:ClearContainer(parent)
    local config = self.db.modules.afk
    local function text(zh, en) return self:L(zh, en) end
    local y = self:BuildPinnedModuleHeader(parent, self:T("afk"), config.enabled, function(value)
        self.AFK.SetEnabled(value)
    end, text("测试效果", "Test effect"), function()
        self.AFK.Test()
    end, text("恢复默认", "Reset module"), function()
        self.AFK.ResetToDefault()
        self:BuildAFKPage(parent)
    end)
    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(hint)
    y = -12
    hint:SetPoint("TOPLEFT", 16, y)
    hint:SetWidth(650)
    hint:SetJustifyH("LEFT")
    hint:SetText(text("进入暂离状态后，随机卡牌从左向右持续滚动；取消暂离时自动停止。", "Random cards scroll from left to right while AFK and stop when you return."))
    y = y - 44
    y = self:CreateSectionTitle(parent, text("卡牌滚动设置", "Scrolling card settings"), y)
    y = self:CreateSlider(parent, text("滚动速度", "Scroll speed"), 50, 500, 10, config.scrollSpeed, function(value)
        config.scrollSpeed = value
        self.AFK.UpdateSettings()
    end, y, text(" 像素/秒", " px/s"))
    y = self:CreateSlider(parent, text("卡牌间距", "Card spacing"), 200, 600, 10, config.spacing, function(value)
        config.spacing = value
        self.AFK.UpdateSettings()
    end, y, text(" 像素", " px"))
    y = self:CreateSlider(parent, text("卡牌缩放", "Card scale"), 0.5, 1.5, 0.1, config.scale, function(value)
        config.scale = value
        self.AFK.UpdateSettings()
    end, y, "x")
    y = self:CreateSectionTitle(parent, text("屏保显示设置", "Screensaver display"), y)
    y = self:CreateCheckbox(parent, text("显示Logo", "Show logo"), config.showLogo ~= false, function(value)
        config.showLogo = value
        self.AFK.UpdateSettings()
    end, y)
    y = self:CreateCheckbox(parent, text("显示黑色遮罩", "Show black overlay"), config.showMask ~= false, function(value)
        config.showMask = value
        self.AFK.UpdateSettings()
    end, y)
    y = self:CreateCheckbox(parent, text("显示UI界面", "Show UI"), config.showUI == true, function(value)
        config.showUI = value
        self.AFK.UpdateSettings()
    end, y)
    y = self:CreateSectionTitle(parent, text("声音", "Sound"), y)
    y = self:CreateCheckbox(parent, text("启动音效", "Enable sound"), config.soundEnabled ~= false, function(value)
        config.soundEnabled = value
    end, y)
    finishSection(parent, y)
    parent:SetHeight(math.max(580, -y + 32))
end

function Addon:BuildBossPage(parent)
    self:ClearContainer(parent)
    local config = self.db.modules.boss
    local function text(zh, en) return self:L(zh, en) end
    local y = self:BuildPinnedModuleHeader(parent, self:T("boss"), config.enabled, function(value)
        self.Boss.SetEnabled(value)
        self:BuildBossPage(parent)
    end, text("测试效果", "Test effect"), function()
        self.Boss.Play("妖术领主玛拉卡斯", true)
    end, text("恢复默认", "Reset module"), function()
        self.Boss.ResetToDefault()
        self:BuildBossPage(parent)
    end, self.Boss.IsDragging() and self:T("lock") or self:T("move"), function(button)
        local dragging = self.Boss.ToggleDragMode()
        button.label:SetText(dragging and self:T("lock") or self:T("move"))
    end, function(button)
        local label = self.Boss.IsDragging() and self:T("lock") or self:T("move")
        if button.label:GetText() ~= label then button.label:SetText(label) end
    end)
    y = self:CreateSectionTitle(parent, text("击杀动画设置", "Kill animation settings"), y)
    y = self:CreateSlider(parent, text("速度调节", "Animation speed"), 0.5, 2, 0.1, config.speed, function(value)
        config.speed = value
        self.Boss.UpdateSettings()
    end, y, "x")
    y = self:CreateSlider(parent, text("整体缩放", "Overall scale"), 0.5, 2, 0.1, config.scale, function(value)
        config.scale = value
        self.Boss.UpdateSettings()
    end, y, "x")
    y = self:CreateSectionTitle(parent, text("声音", "Sound"), y)
    y = self:CreateCheckbox(parent, text("启动音效", "Enable sound"), config.soundEnabled ~= false, function(value)
        config.soundEnabled = value
    end, y)
    finishSection(parent, y)
    parent:SetHeight(math.max(580, -y + 32))
end

function Addon:BuildLootPage(parent)
    self:ClearContainer(parent)
    local config = self.db.modules.loot
    local function text(zh, en) return self:L(zh, en) end
    local y = self:BuildPinnedModuleHeader(parent, self:T("loot"), config.enabled, function(value)
        self.Loot.SetEnabled(value)
        self:BuildLootPage(parent)
    end, text("测试效果", "Test effect"), function()
        self.Loot.Play("奥的灰烬", true)
    end, text("恢复默认", "Reset module"), function()
        self.Loot.ResetToDefault()
        self:BuildLootPage(parent)
    end, self.Loot.IsDragging() and self:T("lock") or self:T("move"), function(button)
        local dragging = self.Loot.ToggleDragMode()
        button.label:SetText(dragging and self:T("lock") or self:T("move"))
    end, function(button)
        local label = self.Loot.IsDragging() and self:T("lock") or self:T("move")
        if button.label:GetText() ~= label then button.label:SetText(label) end
    end)
    y = self:CreateSectionTitle(parent, text("掉落动画设置", "Loot animation settings"), y)
    y = self:CreateSlider(parent, text("速度调节", "Animation speed"), 0.5, 2, 0.1, config.speed, function(value)
        config.speed = value
        self.Loot.UpdateSettings()
    end, y, "x")
    y = self:CreateSlider(parent, text("整体缩放", "Overall scale"), 0.5, 2, 0.1, config.scale, function(value)
        config.scale = value
        self.Loot.UpdateSettings()
    end, y, "x")
    y = self:CreateSectionTitle(parent, text("声音", "Sound"), y)
    y = self:CreateCheckbox(parent, text("启动音效", "Enable sound"), config.soundEnabled ~= false, function(value)
        config.soundEnabled = value
    end, y)
    finishSection(parent, y)
    parent:SetHeight(math.max(580, -y + 32))
end

function Addon:BuildLevelUpPage(parent)
    self:ClearContainer(parent)
    local config = self.db.modules.levelUp
    local function text(zh, en) return self:L(zh, en) end
    local y = self:BuildPinnedModuleHeader(parent, self:T("levelUp"), config.enabled, function(value)
        self.LevelUp.SetEnabled(value)
        self:BuildLevelUpPage(parent)
    end, text("测试效果", "Test effect"), function()
        self.LevelUp.Play(nil, true)
    end, text("恢复默认", "Reset module"), function()
        self.LevelUp.ResetToDefault()
        self:BuildLevelUpPage(parent)
    end, self.LevelUp.IsDragging() and self:T("lock") or self:T("move"), function(button)
        local dragging = self.LevelUp.ToggleDragMode()
        button.label:SetText(dragging and self:T("lock") or self:T("move"))
    end, function(button)
        local label = self.LevelUp.IsDragging() and self:T("lock") or self:T("move")
        if button.label:GetText() ~= label then button.label:SetText(label) end
    end)
    y = self:CreateSectionTitle(parent, text("升级动画设置", "Level-up animation settings"), y)
    y = self:CreateSlider(parent, text("速度调节", "Animation speed"), 0.5, 2, 0.1, config.speed, function(value)
        config.speed = value
        self.LevelUp.UpdateSettings()
    end, y, "x")
    y = self:CreateSlider(parent, text("整体缩放", "Overall scale"), 0.5, 2, 0.1, config.scale, function(value)
        config.scale = value
        self.LevelUp.UpdateSettings()
    end, y, "x")
    y = self:CreateSectionTitle(parent, text("声音", "Sound"), y)
    y = self:CreateCheckbox(parent, text("启动音效", "Enable sound"), config.soundEnabled ~= false, function(value)
        config.soundEnabled = value
    end, y)
    finishSection(parent, y)
    parent:SetHeight(math.max(580, -y + 32))
end

function Addon:BuildCountdownPage(parent)
    self:ClearContainer(parent)
    local config = self.db.modules.countdown
    local function text(zh, en) return self:L(zh, en) end
    local y = self:BuildPinnedModuleHeader(parent, self:T("countdown"), config.enabled, function(value)
        self.Countdown.SetEnabled(value)
        self:BuildCountdownPage(parent)
    end, text("测试效果", "Test effect"), function()
        self.Countdown.Start(10, true)
    end, text("恢复默认", "Reset module"), function()
        self.Countdown.ResetToDefault()
        self:BuildCountdownPage(parent)
    end, self.Countdown.IsDragging() and self:T("lock") or self:T("move"), function(button)
        local dragging = self.Countdown.ToggleDragMode()
        button.label:SetText(dragging and self:T("lock") or self:T("move"))
    end, function(button)
        local label = self.Countdown.IsDragging() and self:T("lock") or self:T("move")
        if button.label:GetText() ~= label then button.label:SetText(label) end
    end)
    y = self:CreateSectionTitle(parent, text("倒数动画设置", "Countdown animation settings"), y)
    y = self:CreateSlider(parent, text("速度调节", "Animation speed"), 0.5, 2, 0.1, config.speed, function(value)
        config.speed = value
        self.Countdown.UpdateSettings()
    end, y, "x")
    y = self:CreateSlider(parent, text("整体缩放", "Overall scale"), 0.3, 1.5, 0.1, config.scale, function(value)
        config.scale = value
        self.Countdown.UpdateSettings()
    end, y, "x")
    y = self:CreateSectionTitle(parent, text("声音", "Sound"), y)
    y = self:CreateCheckbox(parent, text("启动音效", "Enable sound"), config.soundEnabled ~= false, function(value)
        config.soundEnabled = value
    end, y)
    finishSection(parent, y)
    parent:SetHeight(math.max(580, -y + 32))
end

function Addon:BuildModulePage(parent, moduleKey)
    if moduleKey == "boss" then self:BuildBossPage(parent); return end
    if moduleKey == "loot" then self:BuildLootPage(parent); return end
    if moduleKey == "levelUp" then self:BuildLevelUpPage(parent); return end
    if moduleKey == "countdown" then self:BuildCountdownPage(parent); return end
    if moduleKey == "afk" then
        self:BuildAFKPage(parent)
        return
    end
    if moduleKey == "singleSpell" or moduleKey == "inCombat" then
        self:BuildIntegratedModulePage(parent, moduleKey)
        return
    end
    self:ClearContainer(parent)
    local config = self.db.modules[moduleKey]
    local y = -12
    y = self:CreateCheckbox(parent, self:T("enabled"), config.enabled, function(value) config.enabled = value end, y)
    y = self:CreateActionRow(parent, moduleKey, y)

    y = self:CreateSectionTitle(parent, self:T("appearance"), y)
    local minScale = moduleKey == "singleSpell" and 0.1 or 0.5
    local maxScale = moduleKey == "singleSpell" and 1.0 or 2.0
    y = self:CreateSlider(parent, self:T("scale"), minScale, maxScale, 0.1, config.scale, function(value) config.scale = value end, y)

    if moduleKey == "singleSpell" then
        y = self:CreateSectionTitle(parent, self:T("inAnimation"), y)
        y = self:CreateSlider(parent, self:T("inSlideX"), -300, 300, 10, config.inSlideX, function(value) config.inSlideX = value end, y)
        y = self:CreateSlider(parent, self:T("inSlideY"), -300, 300, 10, config.inSlideY, function(value) config.inSlideY = value end, y)
        y = self:CreateSlider(parent, self:T("inRotateAngle"), -180, 180, 5, config.inRotateAngle, function(value) config.inRotateAngle = value end, y, "°")
        y = self:CreateSlider(parent, self:T("inZoomW"), 0.1, 2.0, 0.1, config.inZoomW, function(value) config.inZoomW = value end, y)
        y = self:CreateSlider(parent, self:T("inZoomH"), 0.1, 2.0, 0.1, config.inZoomH, function(value) config.inZoomH = value end, y)
        y = self:CreateDropdown(parent, self:T("inZoomType"), { self:T("rotateType"), self:T("scaleType") }, config.inZoomType, function(value) config.inZoomType = value end, y)

        y = self:CreateSectionTitle(parent, self:T("outAnimation"), y)
        y = self:CreateSlider(parent, self:T("duration"), 0.5, 3.0, 0.1, config.duration, function(value) config.duration = value end, y, "s")
        y = self:CreateSlider(parent, self:T("outSlideX"), -500, 500, 10, config.outSlideX, function(value) config.outSlideX = value end, y)
        y = self:CreateSlider(parent, self:T("outSlideY"), -500, 500, 10, config.outSlideY, function(value) config.outSlideY = value end, y)
        y = self:CreateSlider(parent, self:T("outRotateAngle"), -180, 180, 5, config.outRotateAngle, function(value) config.outRotateAngle = value end, y, "°")
        y = self:CreateSlider(parent, self:T("outZoomScale"), 0.1, 2.0, 0.1, config.outZoomScale, function(value) config.outZoomScale = value end, y)
        y = self:CreateDropdown(parent, self:T("outZoomType"), { self:T("rotateType"), self:T("scaleType") }, config.outZoomType, function(value) config.outZoomType = value end, y)
    elseif moduleKey == "inCombat" then
        y = self:CreateSlider(parent, self:T("animSpeed"), 0.5, 2.0, 0.1, config.animSpeed, function(value) config.animSpeed = value end, y, "x")
    end

    if moduleKey == "singleSpell" or moduleKey == "inCombat" then
        y = self:CreateSectionTitle(parent, self:T("trigger"), y)
        y = self:CreateCheckbox(parent, self:T("normalCombat"), config.normalCombat, function(value) config.normalCombat = value end, y)
        y = self:CreateCheckbox(parent, self:T("bossCombat"), config.bossCombat, function(value) config.bossCombat = value end, y)
    end
    finishSection(parent, y)
    parent:SetHeight(math.max(580, -y + 32))
end

function Addon:BuildGameplay()
    local body = self.options.body
    self:ClearContainer(body)
    local navigation = CreateFrame("Frame", nil, body, "BackdropTemplate")
    navigation:SetPoint("TOPLEFT", 0, 0)
    navigation:SetPoint("BOTTOMLEFT", 0, 0)
    navigation:SetWidth(245)
    addBackdrop(navigation)
    local navigationScroll = CreateFrame("ScrollFrame", nil, navigation, "UIPanelScrollFrameTemplate")
    navigationScroll:SetPoint("TOPLEFT", 9, -12)
    navigationScroll:SetPoint("BOTTOMRIGHT", -29, 12)
    local navigationContent = CreateFrame("Frame", nil, navigationScroll)
    navigationContent:SetSize(211, #MODULE_ORDER * 26)
    navigationScroll:SetScrollChild(navigationContent)

    local controlsPanel = CreateFrame("Frame", nil, body, "BackdropTemplate")
    controlsPanel:SetPoint("TOPLEFT", navigation, "TOPRIGHT", 6, 0)
    controlsPanel:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT")
    addBackdrop(controlsPanel)
    controlsPanel:SetFrameLevel(body:GetFrameLevel() + 1)
    local moduleHeader = CreateFrame("Frame", nil, body, "BackdropTemplate")
    moduleHeader:SetFrameLevel(controlsPanel:GetFrameLevel() + 1)
    moduleHeader:SetPoint("TOPLEFT", navigation, "TOPRIGHT", 6, -5)
    moduleHeader:SetPoint("TOPRIGHT", body, "TOPRIGHT", -34, -5)
    moduleHeader:SetHeight(128)
    -- The right pane has one background; no nested module/group borders.
    body.moduleHeader = moduleHeader

    local scroll = CreateFrame("ScrollFrame", nil, body, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", moduleHeader, "BOTTOMLEFT", 0, -5)
    scroll:SetPoint("BOTTOMRIGHT", -34, 0)
    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetFrameLevel(controlsPanel:GetFrameLevel() + 1)
    content:SetWidth(math.max(240, scroll:GetWidth()))
    scroll:HookScript("OnSizeChanged", function(owner, width)
        content:SetWidth(math.max(240, width))
    end)
    content:SetHeight(580)
    content.stickyHeader = moduleHeader
    scroll:SetScrollChild(content)
    body.moduleContent = content
    body.moduleButtons = {}

    for index, moduleKey in ipairs(MODULE_ORDER) do
        local button = createNavigationButton(navigationContent, 211, 24, self:T(moduleKey), function()
            Addon:SelectModule(moduleKey)
        end, "navigation")
        button:SetPoint("TOPLEFT", 0, -(index - 1) * 26)
        button.icon:SetVertexColor(unpack(MODULE_NAV_COLORS[index]))
        body.moduleButtons[moduleKey] = button
    end
    self:SelectModule(self.selectedModule or "singleSpell")
end

function Addon:SelectModule(moduleKey)
    self.selectedModule = moduleKey
    local body = self.options.body
    for key, button in pairs(body.moduleButtons or {}) do
        button.active = key == moduleKey
        setButtonStyle(button, button.active)
    end
    self:BuildModulePage(body.moduleContent, moduleKey)
    local scroll = body.moduleContent:GetParent()
    if scroll.SetVerticalScroll then scroll:SetVerticalScroll(0) end
end

function Addon:BuildStyles()
    local body = self.options.body
    self:ClearContainer(body)
    local function text(zh, en) return self:L(zh, en) end
    local host = CreateFrame("Frame", nil, body)
    host:SetPoint("TOPLEFT", 0, 0)
    host:SetPoint("BOTTOMRIGHT", 0, 0)

    local function panel(titleText, side)
        local pane = CreateFrame("Frame", nil, host, "BackdropTemplate")
        pane:SetPoint("TOP" .. side, host, "TOP" .. side)
        pane:SetPoint("BOTTOM" .. side, host, "BOTTOM" .. side)
        addBackdrop(pane)
        local title = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self:SetControlFont(title)
        title:SetPoint("TOPLEFT", 14, -12)
        title:SetText(titleText)
        return pane
    end
    local frontPanel = panel(self:T("frontStyle"), "LEFT")
    local backPanel = panel(self:T("backStyle"), "RIGHT")
    local frontScroll = CreateFrame("ScrollFrame", nil, frontPanel, "UIPanelScrollFrameTemplate")
    frontScroll:SetPoint("TOPLEFT", 10, -42)
    frontScroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local frontContent = CreateFrame("Frame", nil, frontScroll)
    frontContent:SetSize(1, 1)
    frontScroll:SetScrollChild(frontContent)
    local backScroll = CreateFrame("ScrollFrame", nil, backPanel, "UIPanelScrollFrameTemplate")
    backScroll:SetPoint("TOPLEFT", 10, -42)
    backScroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local backContent = CreateFrame("Frame", nil, backScroll)
    backContent:SetSize(1, 1)
    backScroll:SetScrollChild(backContent)

    local function thumbnail(owner, texture, caption, onClick)
        local button = CreateFrame("Button", nil, owner, "BackdropTemplate")
        button:SetSize(140, 164)
        addBackdrop(button)
        button.art = button:CreateTexture(nil, "ARTWORK")
        button.art:SetSize(128, 128)
        button.art:SetPoint("TOP", 0, -6)
        button.art:SetTexture(texture)
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self:SetControlFont(label)
        label:SetPoint("BOTTOMLEFT", 6, 10)
        label:SetPoint("BOTTOMRIGHT", -6, 10)
        label:SetJustifyH("CENTER")
        label:SetText(caption)
        button.label = label
        button.check = button:CreateTexture(nil, "OVERLAY")
        button.check:SetSize(24, 24)
        button.check:SetPoint("TOPRIGHT", -4, -4)
        button.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")
        highlight:SetAlpha(0.25)
        button:SetScript("OnClick", function()
            PlaySound(852)
            onClick()
        end)
        return button
    end
    local function selectThumbnail(button, selected)
        button.check:SetShown(selected)
        if selected then
            button:SetBackdropBorderColor(1, 0.82, 0, 1)
        else
            button:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
        end
    end

    local frontButtons, backButtons = {}, {}
    local refreshSelection
    for _, style in ipairs(self:GetCardFrontStyles()) do
        local id = style.id
        local button = thumbnail(frontContent, style.preview, text(style.nameZh, style.nameEn), function()
            self.db.cardStyles.front = id
            self:RefreshCardStyles()
            refreshSelection()
        end)
        -- Match the collection page's larger front-style preview exactly.
        -- Unlike the overview page, this picker has no progress bar or stars.
        -- Keep the same 150px preview and title font, but fit its frame to the
        -- content instead of leaving the overview's empty lower area.
        button:SetSize(220, 190)
        button.art:SetSize(150, 150)
        button.art:ClearAllPoints()
        button.art:SetPoint("TOP", 0, -8)
        button.label:ClearAllPoints()
        button.label:SetPoint("TOP", button, "TOP", 0, -162)
        button.label:SetWidth(200)
        self:UseInheritedInterfaceFont(button.label, GameFontHighlight)
        button.label:SetWordWrap(true)
        button.label:SetNonSpaceWrap(true)
        button.label:SetJustifyV("TOP")
        button.label:SetHeight(0)
        button:SetHeight(math.max(190, 174 + math.ceil(button.label:GetStringHeight())))
        button.styleID = id
        frontButtons[#frontButtons + 1] = button
    end
    refreshSelection = function()
        for _, button in ipairs(frontButtons) do
            selectThumbnail(button, button.styleID == self.db.cardStyles.front)
        end
        for _, button in ipairs(backButtons) do
            selectThumbnail(button, button.styleID == self.db.cardStyles.back)
        end
    end
    for _, style in ipairs(self:GetCardBackStyles()) do
        local id = style.id
        local button = thumbnail(backContent, style.texture, text("背面样式 ", "Back style ") .. id, function()
            self:SetCardBackStyle(id)
            refreshSelection()
        end)
        button.styleID = id
        button:SetScript("OnEnter", function(owner)
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
            GameTooltip:SetText("card_back" .. id .. ".blp")
            GameTooltip:AddLine(text("点击应用到所有使用背面贴图的卡牌。", "Click to apply to every card using a back texture."), 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", GameTooltip_Hide)
        backButtons[#backButtons + 1] = button
    end
    refreshSelection()

    local function layout()
        -- Reserve one third for the single front preview and two thirds for
        -- the selectable back collection.  At the default window size this
        -- gives the back panel enough width for three thumbnails per row.
        local contentWidth = math.max(3, host:GetWidth() - 16)
        local frontWidth = math.max(1, math.floor(contentWidth / 3))
        local backWidth = contentWidth - frontWidth
        frontPanel:SetWidth(frontWidth)
        backPanel:SetWidth(backWidth)
        local frontAvailable = math.max(220, frontPanel:GetWidth() - 40)
        frontContent:SetWidth(frontAvailable)
        local frontOffset = 0
        for index, button in ipairs(frontButtons) do
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", math.max(0, (frontAvailable - 220) / 2), -frontOffset)
            frontOffset = frontOffset + button:GetHeight() + 14
        end
        frontContent:SetHeight(math.max(1, frontOffset))
        local available = math.max(140, backWidth - 40)
        local columns = math.max(1, math.floor((available + 12) / 152))
        backContent:SetWidth(available)
        for index, button in ipairs(backButtons) do
            local row = math.floor((index - 1) / columns)
            local column = (index - 1) % columns
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", column * 152, -row * 176)
        end
        backContent:SetHeight(math.max(1, math.ceil(#backButtons / columns) * 176))
    end
    host:SetScript("OnSizeChanged", layout)
    layout()
end

function Addon:BuildCollection()
    local body = self.options.body
    self:ClearContainer(body)
    local function text(zh, en) return self:L(zh, en) end

    local host = CreateFrame("Frame", nil, body)
    host:SetPoint("TOPLEFT", 0, 0)
    host:SetPoint("BOTTOMRIGHT", 0, 0)

    local function panel(titleText, side)
        local pane = CreateFrame("Frame", nil, host, "BackdropTemplate")
        pane:SetPoint("TOP" .. side, host, "TOP" .. side)
        pane:SetPoint("BOTTOM" .. side, host, "BOTTOM" .. side)
        addBackdrop(pane)
        local title = pane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self:SetControlFont(title)
        title:SetPoint("TOPLEFT", 14, -12)
        title:SetText(titleText)
        return pane
    end

    local frontPanel = panel(self:T("frontStyle"), "LEFT")
    local cardsPanel = panel("", "RIGHT")
    local collectToggle = CreateFrame("CheckButton", nil, cardsPanel, "UICheckButtonTemplate")
    collectToggle:SetSize(24, 24)
    collectToggle:SetPoint("TOPLEFT", 12, -8)
    local collectLabel = collectToggle:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(collectLabel)
    collectLabel:SetPoint("LEFT", collectToggle, "RIGHT", 2, 0)
    collectLabel:SetText(text("开始收藏（勾选下方图标选择收藏范围）", "Collect cards (check categories below)"))
    collectToggle:SetScript("OnEnter", function(owner)
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetText(text("开始收藏", "Collect cards"))
        GameTooltip:AddLine(text("开启后，完成有效游玩活动有概率获得本套卡牌。勾选下方分类图标，将该分类尚未收藏的卡牌加入抽卡池；已收藏卡牌不会重复获得。概率固定，即卡牌总览中的所有勾选项的总和。", "Earn cards through eligible activities. Check categories to include their uncollected cards. All checked sets and categories share one fixed reward chance; duplicates are never awarded."), 1, 1, 1, true)
        if Addon.collectionStatus ~= "ready" then GameTooltip:AddLine(Addon:GetCollectionStatusText(), 1, 0.5, 0, true) end
        GameTooltip:Show()
    end)
    collectToggle:SetScript("OnLeave", GameTooltip_Hide)

    local frontScroll = CreateFrame("ScrollFrame", nil, frontPanel, "UIPanelScrollFrameTemplate")
    frontScroll:SetPoint("TOPLEFT", 10, -42)
    frontScroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local frontContent = CreateFrame("Frame", nil, frontScroll)
    frontContent:SetSize(1, 1)
    frontScroll:SetScrollChild(frontContent)

    local classTabs = CreateFrame("Frame", nil, cardsPanel)
    local classProgressText = cardsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(classProgressText)
    classProgressText:SetPoint("TOP", cardsPanel, "TOP", 0, -132)
    classProgressText:SetJustifyH("CENTER")
    local cardScroll = CreateFrame("ScrollFrame", nil, cardsPanel, "UIPanelScrollFrameTemplate")
    cardScroll:SetPoint("TOPLEFT", 10, -154)
    cardScroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local cardContent = CreateFrame("Frame", nil, cardScroll)
    cardContent:SetSize(1, 1)
    cardScroll:SetScrollChild(cardContent)

    -- Base classes first, followed by the classes in the order their games
    -- introduced them, then the shared Boss collection.
    local classes = {
        { token = "WARRIOR", zh = "战士", en = "Warrior" },
        { token = "PALADIN", zh = "圣骑士", en = "Paladin" },
        { token = "HUNTER", zh = "猎人", en = "Hunter" },
        { token = "ROGUE", zh = "潜行者", en = "Rogue" },
        { token = "PRIEST", zh = "牧师", en = "Priest" },
        { token = "SHAMAN", zh = "萨满祭司", en = "Shaman" },
        { token = "MAGE", zh = "法师", en = "Mage" },
        { token = "WARLOCK", zh = "术士", en = "Warlock" },
        { token = "DRUID", zh = "德鲁伊", en = "Druid" },
        { token = "DEATHKNIGHT", zh = "死亡骑士", en = "Death Knight" },
        { token = "MONK", zh = "武僧", en = "Monk" },
        { token = "DEMONHUNTER", zh = "恶魔猎手", en = "Demon Hunter" },
        { token = "EVOKER", zh = "唤魔师", en = "Evoker" },
        { token = "BOSS", zh = "首领", en = "Boss", texture = "Interface\\AddOns\\CardMaster\\Textures\\Assets\\Boss.blp" },
        { token = "LOOT", zh = "史诗", en = "Legendry", texture = "Interface\\AddOns\\CardMaster\\Textures\\Assets\\Legendry.blp" },
        { token = "RACE", zh = "种族技能和御龙术", en = "Racial abilities & Dragonriding", texture = "Interface\\AddOns\\CardMaster\\Textures\\Assets\\Race.blp" },
    }

    local styles = self:GetCardFrontStyles()
    self:StartCardAssetScan()
    local selectedStyleID = (self.db.cardStyles and self.db.cardStyles.front) or styles[1].id
    local selectedClass = select(2, UnitClass("player"))
    if not self:GetCardCollectionEntries(selectedStyleID)[selectedClass] then
        selectedClass = classes[1].token
    end

    local frontButtons, classButtons, previewCards = {}, {}, {}
    local rebuildCards, updateSelectedClassProgress

    local largePreview = self:GetCollectionPreview()
    self.collectionLargePreview = largePreview
    local function showLargePreview(entry)
        Addon:ShowCollectionPreview(entry, self.options)
    end
    collectToggle:SetScript("OnClick", function(owner)
        Addon:SetCollectionEnabled(selectedStyleID, owner:GetChecked() and true or false)
    end)

    local function refreshCardArt(card)
        local entry = card.entry
        local owned = self:OwnsCollectionCard(entry.id)
        local available = entry.available and self:IsPackInstalled(entry.styleID)
        local revealed = owned or (card.collectionPreviewHovered == true and available)
        local texture = revealed and available and entry.sourceTexture or self:GetUnknownCardTexture(entry.styleID)
        card.art:SetTexture(texture)
        card.art:SetDesaturated(not revealed)
        card.art:SetVertexColor(1, 1, 1, 1)
        card.shade:SetShown(not revealed)
        return available
    end

    local function cardDisplayName(entry)
        if self:IsChineseLanguage() then return entry.name end
        local displayNames = self.Spells and self.Spells.CardDisplayEnglish
        return (displayNames and displayNames[selectedClass] and displayNames[selectedClass][entry.name]) or entry.name
    end

    local function updateFrontProgress()
        for _, button in ipairs(frontButtons) do
            local collected, total, pending = self:GetCardCollectionProgress(button.styleID)
            local percent = total > 0 and math.floor(collected / total * 100 + 0.5) or 0
            button.progress:SetMinMaxValues(0, math.max(1, total))
            button.progress:SetValue(collected)
            button.progressText:SetText(pending > 0 and text("检查贴图中…", "Checking…") or
                string.format("%d/%d  %d%%", collected, total, percent))
            local litStars = math.min(5, math.floor(percent / 20))
            for index, star in ipairs(button.stars) do
                if index <= litStars then
                    star:SetDesaturated(false)
                    star:SetVertexColor(1, 0.82, 0, 1)
                else
                    star:SetDesaturated(true)
                    star:SetVertexColor(0.42, 0.42, 0.42, 1)
                end
            end
            local active = button.styleID == selectedStyleID
            button:SetBackdropBorderColor(active and 1 or 0.4, active and 0.82 or 0.4, active and 0 or 0.4, active and 1 or 0.8)
        end
    end

    local function updateClassTabs()
        local settings = self:GetCollectionSettings(selectedStyleID)
        collectToggle:SetChecked(settings.enabled)
        for _, button in ipairs(classButtons) do
            local check = button.collectCheck
            check:SetChecked(settings.categories[button.classToken])
            check:SetEnabled(settings.enabled)
            -- Keep the saved choices, but render disabled checks in grey.
            check:GetCheckedTexture():SetDesaturated(not settings.enabled)
            check:GetCheckedTexture():SetVertexColor(1, 1, 1, 1)
            local active = button.classToken == selectedClass
            button:SetBackdropBorderColor(active and 1 or 0.4, active and 0.82 or 0.4, active and 0 or 0.4, active and 1 or 0.8)
            local collected, total = 0, 0
            for _, entry in ipairs(self:GetCardCollectionEntries(selectedStyleID)[button.classToken] or {}) do
                total = total + 1
                if self:OwnsCollectionCard(entry.id) then collected = collected + 1 end
            end
            local percent = total > 0 and collected / total * 100 or 0
            if percent >= 100 then
                button.progressDot:Hide()
            elseif percent >= 50 then
                button.progressDot:Show()
                button.progressDot:SetVertexColor(1, 0.82, 0.08, 1)
            else
                button.progressDot:Show()
                button.progressDot:SetVertexColor(0.92, 0.18, 0.16, 1)
            end
        end
    end

    updateSelectedClassProgress = function()
        local entries = self:GetCardCollectionEntries(selectedStyleID)[selectedClass] or {}
        local collected = 0
        for _, entry in ipairs(entries) do
            if self:OwnsCollectionCard(entry.id) then collected = collected + 1 end
        end
        local total = #entries
        local percent = total > 0 and collected / total * 100 or 0
        local percentText = percent == math.floor(percent) and string.format("%d%%", percent) or string.format("%.1f%%", percent)
        local status = self:GetCollectionStatusText()
        classProgressText:SetText(status ~= "" and status or (total == 0 and text("暂无卡牌", "No cards") or string.format("%d/%d  %s", collected, total, percentText)))
    end

    rebuildCards = function()
        self:ClearContainer(cardContent)
        previewCards = {}
        local entries = self:GetCardCollectionEntries(selectedStyleID)[selectedClass] or {}
        updateSelectedClassProgress()

        local available = math.max(108, cardScroll:GetWidth() - 10)
        local columns = math.max(1, math.floor((available + 10) / 118))
        cardContent:SetWidth(available)
        for index, entry in ipairs(entries) do
            local row = math.floor((index - 1) / columns)
            local column = (index - 1) % columns
            local card = CreateFrame("Button", nil, cardContent, "BackdropTemplate")
            card:SetSize(108, 138)
            card:SetPoint("TOPLEFT", column * 118, -row * 150)
            addBackdrop(card)
            local art = card:CreateTexture(nil, "ARTWORK")
            art:SetSize(98, 98)
            art:SetPoint("TOP", 0, -5)
            local shade = card:CreateTexture(nil, "OVERLAY")
            shade:SetAllPoints(art)
            shade:SetColorTexture(0, 0, 0, 0.28)
            card.entry, card.art, card.shade = entry, art, shade
            previewCards[#previewCards + 1] = card
            refreshCardArt(card)
            local label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            self:SetControlFont(label)
            label:SetPoint("TOPLEFT", art, "BOTTOMLEFT", -2, -4)
            label:SetPoint("TOPRIGHT", art, "BOTTOMRIGHT", 2, -4)
            label:SetJustifyH("CENTER")
            label:SetText(cardDisplayName(entry))
            card:SetScript("OnEnter", function(owner)
                owner.collectionPreviewHovered = true
                GameTooltip_Hide()
                if not refreshCardArt(owner) then
                    largePreview:Hide()
                    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
                    GameTooltip:SetText(cardDisplayName(owner.entry))
                    GameTooltip:AddLine(text("贴图未安装或仍在检查", "Artwork missing or still being checked"), 1, 1, 1)
                    GameTooltip:Show()
                    return
                end
                showLargePreview(owner.entry)
            end)
            local function restoreCard(owner)
                if owner.collectionPreviewHovered ~= true then return end
                owner.collectionPreviewHovered = nil
                refreshCardArt(owner)
                if largePreview.entry == owner.entry and largePreview.previewOwner == self.options and not largePreview.pinned then largePreview:Hide() end
                GameTooltip_Hide()
            end
            card:SetScript("OnLeave", restoreCard)
            card:SetScript("OnHide", restoreCard)
        end
        cardContent:SetHeight(math.max(1, math.ceil(#entries / columns) * 150))
        updateClassTabs()
    end

    for _, class in ipairs(classes) do
        local classToken, classZh, classEn = class.token, class.zh, class.en
        local button = CreateFrame("Button", nil, classTabs, "BackdropTemplate")
        button:SetSize(34, 34)
        button.classToken = classToken
        addBackdrop(button, 8)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", -3, 3)
        icon:SetTexture(class.texture or
            ("Interface\\AddOns\\CardMaster\\Textures\\Assets\\" .. classToken .. ".blp"))
        icon:SetTexCoord(0, 1, 0, 1)
        local progressDot = button:CreateTexture(nil, "OVERLAY")
        progressDot:SetSize(10, 10)
        progressDot:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
        progressDot:SetTexture("Interface\\AddOns\\CardMaster\\Textures\\Assets\\Circle.png")
        button.progressDot = progressDot
        local check = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
        check:SetSize(20, 20)
        check:SetPoint("BOTTOMRIGHT", 5, -5)
        check:SetScript("OnClick", function(owner)
            local settings = Addon:GetCollectionSettings(selectedStyleID)
            if not settings.enabled then
                owner:SetChecked(settings.categories[classToken])
                return
            end
            Addon:SetCollectionCategory(selectedStyleID, classToken, owner:GetChecked() and true or false)
        end)
        check:SetScript("OnEnter", function(owner)
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
            GameTooltip:SetText(text("加入收藏范围：", "Include category: ") .. text(classZh, classEn))
            if not Addon:GetCollectionSettings(selectedStyleID).enabled then
                GameTooltip:AddLine(text("请先勾选“开始收藏”。", "Enable Collect cards first."), 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", GameTooltip_Hide)
        button.collectCheck = check
        button:SetScript("OnClick", function()
            selectedClass = classToken
            rebuildCards()
        end)
        button:SetScript("OnEnter", function(owner)
            GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
            GameTooltip:SetText(text(classZh, classEn))
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", GameTooltip_Hide)
        classButtons[#classButtons + 1] = button
    end

    for _, style in ipairs(styles) do
        local styleID, stylePreview, styleNameZh, styleNameEn = style.id, style.preview, style.nameZh, style.nameEn
        local button = CreateFrame("Button", nil, frontContent, "BackdropTemplate")
        button:SetSize(220, 262)
        button.styleID = styleID
        addBackdrop(button)
        local art = button:CreateTexture(nil, "ARTWORK")
        art:SetSize(150, 150)
        art:SetPoint("TOP", 0, -8)
        art:SetTexture(stylePreview)
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        -- Use the same font setup as the front-style labels in BuildStyles.
        self:SetControlFont(label)
        self:UseInheritedInterfaceFont(label, GameFontHighlight)
        label:SetPoint("TOP", button, "TOP", 0, -162)
        label:SetWidth(200)
        label:SetJustifyH("CENTER")
        label:SetJustifyV("TOP")
        label:SetWordWrap(true)
        label:SetNonSpaceWrap(true)
        label:SetText(text(styleNameZh, styleNameEn))
        label:SetHeight(0)
        button:SetHeight(math.max(262, 238 + math.ceil(label:GetStringHeight())))
        local progressFrame = CreateFrame("Frame", nil, button, "BackdropTemplate")
        progressFrame:SetSize(190, 11)
        progressFrame:SetPoint("TOP", label, "BOTTOM", 0, -13)
        progressFrame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
        progressFrame:SetBackdropColor(0.10, 0.10, 0.11, 0.96)
        button.progress = CreateFrame("StatusBar", nil, progressFrame)
        button.progress:SetPoint("TOPLEFT", 3, -3)
        button.progress:SetPoint("BOTTOMRIGHT", -3, 3)
        button.progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        button.progress:SetStatusBarColor(0.18, 0.70, 0.98, 1)
        button.progressText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self:SetControlFont(button.progressText)
        self:UseInheritedInterfaceFont(button.progressText, GameFontHighlight)
        button.progressText:SetSize(200, 16)
        button.progressText:SetPoint("TOP", progressFrame, "BOTTOM", 0, -5)
        button.progressText:SetJustifyH("CENTER")
        button.stars = {}
        local stars = CreateFrame("Frame", nil, button)
        stars:SetSize(110, 18)
        stars:SetPoint("TOP", button.progressText, "BOTTOM", 0, -2)
        for index = 1, 5 do
            local star = stars:CreateTexture(nil, "OVERLAY")
            star:SetSize(18, 18)
            star:SetPoint("LEFT", (index - 1) * 23, 0)
            star:SetTexture("Interface\\AddOns\\CardMaster\\Textures\\Assets\\star.blp")
            button.stars[index] = star
        end
        button:SetScript("OnClick", function()
            selectedStyleID = styleID
            updateFrontProgress()
            rebuildCards()
            frontScroll:SetVerticalScroll(0)
            cardScroll:SetVerticalScroll(0)
        end)
        frontButtons[#frontButtons + 1] = button
    end

    local function layout()
        local contentWidth = math.max(3, host:GetWidth() - 16)
        local frontWidth = math.max(250, math.floor(contentWidth / 3))
        local cardsWidth = contentWidth - frontWidth
        frontPanel:SetWidth(frontWidth)
        cardsPanel:SetWidth(cardsWidth)
        local frontAvailable = math.max(220, frontPanel:GetWidth() - 40)
        frontContent:SetWidth(frontAvailable)
        local frontOffset = 0
        for index, button in ipairs(frontButtons) do
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", math.max(0, (frontAvailable - 220) / 2), -frontOffset)
            frontOffset = frontOffset + button:GetHeight() + 14
        end
        frontContent:SetHeight(math.max(1, frontOffset))
        local firstRowCount = math.min(13, #classButtons)
        local secondRowCount = math.max(0, #classButtons - firstRowCount)
        local tabWidth = firstRowCount * 38 - 4
        classTabs:ClearAllPoints()
        classTabs:SetSize(tabWidth, 86)
        classTabs:SetPoint("TOP", cardsPanel, "TOP", 0, -40)
        for index, button in ipairs(classButtons) do
            button:ClearAllPoints()
            local row = math.floor((index - 1) / 13)
            local column = (index - 1) % 13
            local offsetX = column * 38
            if row == 1 then
                offsetX = (tabWidth - secondRowCount * 38) / 2 + offsetX
            end
            button:SetPoint("TOPLEFT", offsetX, -row * 38)
        end
        rebuildCards()
    end

    local function assetsChanged()
        if not host:IsShown() then return end
        updateFrontProgress()
        updateClassTabs()
        updateSelectedClassProgress()
        local hoveredEntry
        for _, card in ipairs(previewCards) do
            local available = refreshCardArt(card)
            if card.collectionPreviewHovered == true and available then hoveredEntry = card.entry end
        end
        if hoveredEntry then
            GameTooltip_Hide()
            showLargePreview(hoveredEntry)
        elseif largePreview:IsShown() and largePreview.entry then
            showLargePreview(largePreview.entry)
        end
    end
    self.OnCardAssetsChanged = assetsChanged
    self.OnCollectionChanged = assetsChanged
    host:SetScript("OnHide", function()
        if self.OnCardAssetsChanged == assetsChanged then self.OnCardAssetsChanged = nil end
        if self.OnCollectionChanged == assetsChanged then self.OnCollectionChanged = nil end
        largePreview:Hide()
    end)
    host:SetScript("OnShow", function()
        self.OnCardAssetsChanged = assetsChanged
    self.OnCollectionChanged = assetsChanged
        assetsChanged()
    end)
    host:SetScript("OnSizeChanged", layout)
    layout()
    updateFrontProgress()
end

local function wrapConfigStringForEditor(value, editor, measure)
    local header, hex = value:match("^(CMCFG1:[0-9A-Fa-f]+:)([0-9A-Fa-f]+)$")
    if not header then header, hex = value:match("^(MCMCFG1:[0-9A-Fa-f]+:)([0-9A-Fa-f]+)$") end
    if not header then return value end
    local available = math.max(100, editor:GetWidth() - 24)
    local lines = { header }
    local index = 1
    while index <= #hex do
        local low, high = 1, math.min(256, #hex - index + 1)
        local length = 1
        while low <= high do
            local middle = math.floor((low + high) / 2)
            measure:SetText(hex:sub(index, index + middle - 1))
            if measure:GetStringWidth() <= available then
                length = middle
                low = middle + 1
            else
                high = middle - 1
            end
        end
        lines[#lines + 1] = hex:sub(index, index + length - 1)
        index = index + length
    end
    return table.concat(lines, "\n")
end

function Addon:ShowConfigStringDialog(mode)
    local dialog = self.configStringDialog
    if not dialog then
        dialog = CreateFrame("Frame", "CardMasterConfigStringDialog", UIParent, "BackdropTemplate")
        dialog.legacyOptionsStyle = true
        dialog:SetSize(720, 430)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:EnableMouse(true)
        self:EnableWindowEscape(dialog)
        addBackdrop(dialog)
        dialog:SetBackdropColor(0.08, 0.08, 0.09, 0.96)

        dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self:SetControlFont(dialog.title)
        dialog.title:SetPoint("TOP", 0, -18)
        dialog.hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        self:SetControlFont(dialog.hint)
        dialog.hint:SetPoint("TOP", 0, -48)
        dialog.hint:SetWidth(670)
        dialog.hint:SetJustifyH("CENTER")

        local scroll = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 28, -78)
        scroll:SetPoint("BOTTOMRIGHT", -44, 70)
        local editBox = CreateFrame("EditBox", nil, scroll, "BackdropTemplate")
        editBox:SetPoint("TOPLEFT", 4, -4)
        editBox:SetSize(620, 560)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetMaxLetters(0)
        editBox:SetFontObject(GameFontHighlightSmall)
        self:SetControlFont(editBox)
        editBox:SetTextInsets(6, 6, 6, 6)
        editBox:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        editBox:SetBackdropColor(0.03, 0.03, 0.04, 0.95)
        dialog.measure = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self:SetControlFont(dialog.measure)
        dialog.measure:SetAlpha(0)
        scroll:SetScrollChild(editBox)
        scroll:SetScript("OnSizeChanged", function(owner)
            editBox:SetWidth(math.max(100, owner:GetWidth() - 20))
        end)
        dialog.scroll = scroll
        editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
        dialog.editBox = editBox

        dialog.status = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self:SetControlFont(dialog.status)
        dialog.status:SetPoint("TOP", scroll, "BOTTOM", 0, -4)
        dialog.status:SetWidth(670)
        dialog.status:SetJustifyH("CENTER")
        dialog.status:SetTextColor(1, 0.3, 0.3)

        dialog.action = self:CreateTextButton(dialog, 120, 26, "", function()
            if dialog.mode == "export" then
                dialog.editBox:SetFocus()
                dialog.editBox:HighlightText()
                return
            end
            local config = Addon:ImportConfigString(dialog.editBox:GetText())
            if not config then
                dialog.status:SetText(Addon:T("importInvalid"))
                return
            end
            dialog:Hide()
            Addon:ApplyDatabase(config)
            Addon:Print(Addon:T("importDone"))
        end)
        dialog.action:SetPoint("BOTTOM", -70, 14)
        dialog.cancel = self:CreateTextButton(dialog, 120, 26, CANCEL or "取消", function() dialog:Hide() end)
        dialog.cancel:SetPoint("BOTTOM", 70, 14)
        local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 2, 2)
        self:StyleButton(close)
        close:SetScript("OnClick", function() dialog:Hide() end)
        dialog:SetScript("OnHide", function() editBox:ClearFocus() end)
        self.configStringDialog = dialog
    end

    dialog.mode = mode
    dialog.title:SetText(self:T(mode == "export" and "exportConfig" or "importConfig"))
    dialog.hint:SetText(self:T(mode == "export" and "exportHint" or "importHint"))
    dialog.action:SetText(self:T(mode == "export" and "selectAll" or "importApply"))
    dialog.cancel:SetText(CANCEL or (self:L("取消", "Cancel")))
    dialog.status:SetText("")
    if mode == "export" then
        local value = self:ExportConfigString()
        dialog.editBox:SetText(value and wrapConfigStringForEditor(value, dialog.editBox, dialog.measure) or "")
        if not value then dialog.status:SetText(self:T("exportFailed")) end
    else
        dialog.editBox:SetText("")
    end
    dialog:Show()
    dialog.editBox:SetFocus()
    if mode == "export" then dialog.editBox:HighlightText() end
end


function Addon:BuildMisc()
    local body = self.options.body
    self:ClearContainer(body)
    local content = CreateFrame("Frame", nil, body)
    content.legacyOptionsStyle = true
    content:SetPoint("TOPLEFT", 35, -28)
    content:SetSize(760, 500)
    local y = 0
    y = self:CreateSectionTitle(content, self:T("system"), y)
    local selectedLanguage, labels = 1, {}
    for index, option in ipairs(self.languageOptions) do
        labels[index] = option.label
        if option.code == self:EffectiveLanguage() then selectedLanguage = index end
    end
    y = self:CreateDropdown(content, self:T("language"), labels, selectedLanguage, function(value)
        Addon:SetLanguage(Addon.languageOptions[value].code)
    end, y)
    y = self:CreateCheckbox(content, self:T("showMinimap"), self.db.showMinimapIcon, function(value)
        Addon.db.showMinimapIcon = value
        Addon:UpdateMinimapButton()
    end, y)
    y = self:CreateCheckbox(content, self:T("collectionBroadcast"), self.db.collectionBroadcast, function(value)
        Addon.db.collectionBroadcast = value
    end, y)
    finishSection(content, y)

    y = self:CreateSectionTitle(content, self:T("configShare"), y - 15)
    local export = self:CreateTextButton(content, 190, 32, self:T("exportConfig"), function()
        Addon:ShowConfigStringDialog("export")
    end)
    export:SetPoint("TOPLEFT", 16, y)
    self:StyleButton(export, true)
    local import = self:CreateTextButton(content, 190, 32, self:T("importConfig"), function()
        Addon:ShowConfigStringDialog("import")
    end)
    import:SetPoint("TOPLEFT", 216, y)
    self:StyleButton(import, true)
    local reset = self:CreateTextButton(content, 160, 32, self:T("resetAll"), function()
        StaticPopupDialogs.CARDMASTER_RESET_ALL = {
            text = Addon:T("resetConfirm"),
            button1 = ACCEPT or YES or "确定",
            button2 = CANCEL or NO or "取消",
            OnAccept = function() Addon:ResetDatabase() end,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1,
        }
        StaticPopup_Show("CARDMASTER_RESET_ALL")
    end)
    reset:SetScript("OnEnter", function(owner)
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetText(Addon:T("resetAll"))
        GameTooltip:AddLine(Addon:T("collectionResetHint"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    reset:SetScript("OnLeave", GameTooltip_Hide)
    reset:SetPoint("TOPLEFT", 416, y)
    self:StyleButton(reset, true)
    finishSection(content, y - 55)
end

function Addon:SelectMainTab(tabKey)
    self.selectedTab = tabKey
    -- Like MangUI, split pages own their pane backgrounds; the Other page
    -- has one 60% panel. Never stack an extra dark fill behind either.
    self.options.body:SetBackdropColor(0.12, 0.12, 0.13, tabKey == "misc" and 0.6 or 0)
    for key, button in pairs(self.options.tabs) do
        button.label:SetText(self:T(key))
        button.active = key == tabKey
        setButtonStyle(button, button.active)
    end
    if tabKey == "gameplay" then
        self:BuildGameplay()
    elseif tabKey == "styles" then
        self:BuildStyles()
    elseif tabKey == "collection" then
        self:BuildCollection()
    else
        self:BuildMisc()
    end
    self:ApplyLocaleTree(self.options)
end

function Addon:RefreshOptions()
    if not self.options then return end
    self.options.title:SetText(self:T("addonName") .. " - V" .. self.buildVersion .. " 2026/10/25 2049")
    self:RefreshOptionsFooter()
    self.options.tabs.gameplay.label:SetText(self:T("gameplay"))
    self.options.tabs.styles.label:SetText(self:T("styles"))
    self.options.tabs.collection.label:SetText(self:T("collection"))
    self.options.tabs.misc.label:SetText(self:T("misc"))
    for moduleKey, anchor in pairs(self.anchors or {}) do
        anchor.title:SetText(self:T(moduleKey))
        anchor.hint:SetText(self:T("dragHint"))
    end
    self:SelectMainTab(self.selectedTab or "gameplay")
end

function Addon:ToggleOptions()
    if self.welcomeWindow and self.welcomeWindow:IsShown() and self.DismissWelcomeWindow then
        self:DismissWelcomeWindow()
    end
    if not self.options then self:CreateOptions() end
    if self.options:IsShown() then
        self.options:Hide()
        return
    end
    -- OnShow builds the card overview after the panel has become visible, so
    -- a /reload never leaves a half-built page on screen.
    self.optionsOpening = true
    self.options:Show()
    self.optionsOpening = nil
end

function Addon:CreateMinimapButton()
    local button = _G.CardMasterMinimapButton
    if button then
        self.minimapButton = button
        self:UpdateMinimapButton()
        return
    end

    button = CreateFrame("Button", "CardMasterMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetPoint("CENTER", Minimap, "CENTER", -76, -62)
    button:SetFrameStrata("HIGH")
    -- Match the Classic LibDBIcon button regions.  HidingBar's settings preview
    -- draws its own tracking border; the real button needs one of its own when
    -- Masque skinning is disabled.  These standard textures also let HidingBar
    -- remove the original chrome when it applies a Masque skin.
    local background = button:CreateTexture("CardMasterMinimapButtonBackground", "BACKGROUND")
    background:SetSize(26, 26)
    background:SetPoint("CENTER", button, "CENTER", 0, 0)
    background:SetColorTexture(27/255, 25/255, 26/255, 1)
    button.background = background
    local icon = button:CreateTexture("CardMasterMinimapButtonIcon", "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\CardMaster\\Textures\\Assets\\CMLogo.png")
    -- Tighter than the window crop: only the central badge at minimap size.
    icon:SetTexCoord(.245, .755, .24, .75)
    icon:SetAllPoints(background)
    local mask = button:CreateMaskTexture()
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(background)
    background:AddMaskTexture(mask)
    icon:AddMaskTexture(mask)
    button.logo, button.logoBackground, button.logoMask = icon, background, mask
    button.icon = icon
    local border = button:CreateTexture("CardMasterMinimapButtonBorder", "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT")
    border:SetTexture(136430) -- MiniMap-TrackingBorder
    button.border = border
    button:SetHighlightTexture(136477) -- UI-Minimap-ZoomButton-Highlight
    button:SetScript("OnClick", function() Addon:ToggleOptions() end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(Addon:T("addonName"), 1, 0.76, 0.22)
        GameTooltip:AddLine(Addon:T("openSettings"), 0.85, 0.85, 0.82)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    self.minimapButton = button
    self:UpdateMinimapButton()
end

function Addon:UpdateMinimapButton()
    if self.minimapButton then
        if self.db and self.db.showMinimapIcon then
            self.minimapButton:Show()
        else
            self.minimapButton:Hide()
        end
    end
end
