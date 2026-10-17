local _, Addon = ...

Addon.AFK = {}
local AFK = Addon.AFK
local RAW_SIZE = 512
local cards = {}
local activeCount = 0
local lastTextureIndex
local size, spacing, speed, screenWidth, offsetY

local frame = CreateFrame("Frame", "CardMasterAFKFrame", UIParent)
-- Keep the custom AFK frame under UIParent.  Detaching it during addon load
-- taints the Retail 12.x UI hierarchy and can block unrelated Blizzard actions.
frame:SetScale(1)
frame:SetAllPoints(UIParent)
frame:SetFrameStrata("BACKGROUND")
frame:EnableMouse(false)
frame:EnableKeyboard(false)
if frame.SetPropagateKeyboardInput then frame:SetPropagateKeyboardInput(true) end
frame:Hide()

local events = CreateFrame("Frame")
local restoreEvents = CreateFrame("Frame")
local savedUIAlpha, hidUIParent
local logoVisible, maskVisible = false, false
local logoFade, maskFade = 0, 0
local testMode = false
local FADE_DURATION = 1
local isRetail = Addon:IsRetail()
local SHINE_GRADIENT = "Interface\\AddOns\\CardMaster\\Textures\\Assets\\gradient.tga"

if isRetail then
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
else
    -- 经典客户端的 AFK 模式会隐藏 UIParent；动画层必须脱离它，
    -- 否则卡牌、遮罩与 Logo 都会跟着一起消失。
    frame:SetParent(nil)
    frame:SetScale(UIParent:GetEffectiveScale())
end

local function RestoreUI()
    if isRetail then
        savedUIAlpha, hidUIParent = nil, nil
        restoreEvents:UnregisterAllEvents()
        return
    end
    if savedUIAlpha == nil then return end
    UIParent:SetAlpha(savedUIAlpha)
    if hidUIParent then
        if InCombatLockdown() then
            restoreEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        UIParent:Show()
    end
    savedUIAlpha, hidUIParent = nil, nil
    restoreEvents:UnregisterAllEvents()
end

local function UpdateUIVisibility()
    local config = Addon.db and Addon.db.modules.afk
    if not frame:IsShown() or not config or not config.enabled or config.showUI then
        RestoreUI()
        return
    end
    -- The Retail root is Blizzard-owned.  The AFK frame itself is a fullscreen
    -- visual overlay there, so it never needs to change UIParent visibility.
    if isRetail then return end
    if savedUIAlpha == nil then savedUIAlpha = UIParent:GetAlpha() end
    UIParent:SetAlpha(0)
    -- Protected visibility changes must wait for combat to end. Alpha still
    -- hides the UI visually if AFK starts while combat lockdown is active.
    if not InCombatLockdown() and UIParent:IsShown() then
        hidUIParent = true
        UIParent:Hide()
    end
end

restoreEvents:SetScript("OnEvent", function()
    RestoreUI()
    UpdateUIVisibility()
end)

-- Two full-width gradients meet at the screen center: black alpha .3 there,
-- increasing to .8 at both edges. Card child frames render above these textures.
local upperMask = frame:CreateTexture(nil, "BACKGROUND")
upperMask:SetPoint("TOPLEFT", frame, "TOPLEFT")
upperMask:SetPoint("BOTTOMRIGHT", frame, "RIGHT")
local lowerMask = frame:CreateTexture(nil, "BACKGROUND")
lowerMask:SetPoint("TOPLEFT", frame, "LEFT")
lowerMask:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
local function SetMaskGradient(texture, bottomAlpha, topAlpha)
    texture:SetColorTexture(1, 1, 1, 1)
    if texture.SetGradient and CreateColor then
        texture:SetGradient("VERTICAL", CreateColor(0, 0, 0, bottomAlpha), CreateColor(0, 0, 0, topAlpha))
    else
        texture:SetGradientAlpha("VERTICAL", 0, 0, 0, bottomAlpha, 0, 0, 0, topAlpha)
    end
end
SetMaskGradient(upperMask, 0.3, 0.8)
SetMaskGradient(lowerMask, 0.8, 0.3)

local logo = CreateFrame("Frame", "CardMasterAFKLogo", frame)
logo:EnableMouse(false)
logo:SetFrameLevel(frame:GetFrameLevel() + 2)
local logoTexture = logo:CreateTexture(nil, "ARTWORK")
logoTexture:SetAllPoints(logo)
logoTexture:SetTexture("Interface\\AddOns\\CardMaster\\Textures\\Assets\\MangUI5_AFK.blp")

local function UpdateVisuals(restart)
    local config = Addon.db.modules.afk
    local showLogo, showMask = config.showLogo ~= false, config.showMask ~= false
    if restart or (showLogo and not logoVisible) then
        logoFade = 0
        logo:SetAlpha(0)
    end
    if restart or (showMask and not maskVisible) then
        maskFade = 0
        upperMask:SetAlpha(0)
        lowerMask:SetAlpha(0)
    end
    logoVisible, maskVisible = showLogo, showMask
    logo:SetShown(showLogo)
    upperMask:SetShown(showMask)
    lowerMask:SetShown(showMask)
end

local function Settings()
    return Addon.db and Addon.db.modules.afk
end

local function Clamp(value, default, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or default))
end

local function RandomBossTexture()
    local chosen, count
    for bossName, texture in pairs(Addon.BossTextures or {}) do
        -- 阵营冠军未制作专属卡面；不把未知占位图混入暂离动画。
        if bossName ~= "阵营冠军" then
            count = (count or 0) + 1
            if math.random(count) == 1 then chosen = texture end
        end
    end
    if not chosen then return nil end
    if Addon.ResolveBossFrontTexture then
        return Addon:ResolveBossFrontTexture(chosen)
    end
    return Addon:ResolveCardFrontTexture(chosen)
end

local function RandomCatalogTexture(token)
    local style = Addon:GetSelectedCardFrontStyle()
    if not style or not Addon.GetCardCollectionEntries or not Addon:IsPackInstalled(style.id) then return nil end
    local entries = Addon:GetCardCollectionEntries(style.id)[token] or {}
    if #entries == 0 then return nil end
    return entries[math.random(#entries)].sourceTexture
end

-- The light stays at the center of the screen. Each card only reveals the
-- portion of that light which falls inside its frame/artwork alpha mask.
local function CreateCardShine(card)
    if not card.CreateMaskTexture or not card.texture.AddMaskTexture
        or not card.texture.SetVertexOffset then return end

    card.shine = {}
    for _, channel in ipairs({ { "frame", 180 }, { "card", 360 } }) do
        local mask = card:CreateMaskTexture(nil, "OVERLAY")
        mask:SetAllPoints(card.texture)
        local bands = {}
        for index = 1, 3 do
            local band = card:CreateTexture(nil, "OVERLAY")
            band:SetTexture(SHINE_GRADIENT, "MIRROR")
            band:SetTexCoord(-1, 1, 0, 1)
            band:SetBlendMode("ADD")
            band:AddMaskTexture(mask)
            band:Hide()
            bands[index] = band
        end
        card.shine[channel[1]] = { mask = mask, bands = bands, width = channel[2] }
    end
end

local function SetCardShineKind(card, kind)
    card.shineKind = kind
    if not card.shine then return end
    if not kind then
        for _, channel in pairs(card.shine) do
            for _, band in ipairs(channel.bands) do band:Hide() end
        end
        return
    end
    local styleID = Addon:GetSelectedCardFrontStyle().id
    local suffix = styleID == 2 and kind == "special" and "_2" or ""
    local root = Addon:GetFrontHighlightRoot(styleID)
    if card.shineStyle ~= styleID or card.shineSuffix ~= suffix then
        card.shine.frame.mask:SetTexture(root .. "frame" .. suffix .. ".png")
        card.shine.card.mask:SetTexture(root .. "card" .. suffix .. ".png")
        card.shineStyle, card.shineSuffix = styleID, suffix
    end
end

local function LightCardBand(card, band, alpha, brightness, lightX)
    if brightness <= 0 then
        band:Hide()
        return
    end
    band:SetVertexColor(1, 0.94, 0.78, alpha * brightness)
    band:ClearAllPoints()
    band:SetPoint("CENTER", card, "CENTER", lightX - card.x, 0)
    band:Show()
end

local function UpdateCardShine(card)
    if not card.shine or not card.shineKind then return end
    local reach = size * 0.5 + 180 * (size / RAW_SIZE)
    local quarter = screenWidth * 0.25
    local left = math.max(0, 1 - math.abs(card.x + quarter) / reach)
    local center = math.max(0, 1 - math.abs(card.x) / reach)
    local right = math.max(0, 1 - math.abs(card.x - quarter) / reach)
    left, center, right = left * left * (3 - 2 * left), center * center * (3 - 2 * center), right * right * (3 - 2 * right)
    local total = left + center + right
    local normalize = total > 1 and 1 / total or 1
    left, center, right = left * normalize, center * normalize, right * normalize
    local styleID = card.shineStyle or 1
    local frameAlpha = styleID == 1 and 0.21 or 0.42
    local cardAlpha = styleID == 1 and 0.084 or 0.105
    local frameBands, cardBands = card.shine.frame.bands, card.shine.card.bands
    LightCardBand(card, frameBands[1], frameAlpha, left, -quarter)
    LightCardBand(card, frameBands[2], frameAlpha, center, 0)
    LightCardBand(card, frameBands[3], frameAlpha, right, quarter)
    LightCardBand(card, cardBands[1], cardAlpha, left, -quarter)
    LightCardBand(card, cardBands[2], cardAlpha, center, 0)
    LightCardBand(card, cardBands[3], cardAlpha, right, quarter)
end

local function SizeCardShine(card)
    if not card.shine then return end
    local factor = size / RAW_SIZE
    for _, effect in pairs(card.shine) do
        for _, band in ipairs(effect.bands) do
            band:SetSize(effect.width * factor, 760 * factor)
            band:SetVertexOffset(1, 130 * factor, 0)
            band:SetVertexOffset(3, 130 * factor, 0)
            band:SetVertexOffset(2, -130 * factor, 0)
            band:SetVertexOffset(4, -130 * factor, 0)
        end
    end
end

local function RandomTexture(card)
    local textures = Addon.AFKTextures or {}
    local count = #textures
    if count == 0 then return end

    -- Most front cards stay in the normal class pool. Boss, legendary loot,
    -- and racial/dragonriding cards are mixed in as independent random pools.
    local roll = math.random(8)
    local specialTexture
    if roll == 1 then
        specialTexture = RandomBossTexture()
    elseif roll == 2 then
        specialTexture = RandomCatalogTexture("LOOT")
    elseif roll == 3 then
        specialTexture = RandomCatalogTexture("RACE")
    end
    if specialTexture then
        card.texture:SetTexture(specialTexture)
        card.texture:SetTexCoord(0, 1, 0, 1)
        SetCardShineKind(card, (roll == 1 or roll == 2) and "special" or "normal")
        return
    end

    local index = math.random(count)
    -- Avoid an immediate repeat, while still sampling every class folder.
    if count > 1 and index == lastTextureIndex then
        index = (index + math.random(count - 1) - 1) % count + 1
    end
    lastTextureIndex = index
    -- AFKTextures is the authoritative style-1 catalogue.  Resolve it at
    -- display time so the same card selection uses cardfront2 whenever the
    -- player has selected 正面样式 2 HD高清.
    card.texture:SetTexture(Addon:ResolveCardFrontTexture(textures[index]))
    card.texture:SetTexCoord(0, 1, 0, 1)
    SetCardShineKind(card, "normal")
end

function AFK.RefreshCardTextures()
    for _, card in ipairs(cards) do
        if card:IsShown() then RandomTexture(card) end
    end
end

local function Position(card)
    card:ClearAllPoints()
    card:SetPoint("CENTER", UIParent, "CENTER", card.x, offsetY)
end

-- Let the client interpolate the card itself. Lua still tracks its position
-- for the stationary shine zones, but only changes the anchor when the card
-- is placed offscreen or the layout/speed changes.
local function StartCardMotion(card, x)
    card.motion:Stop()
    card.x = x
    Position(card)
    local travel = screenWidth / 2 + size / 2 + spacing - x
    card.motionTranslation:SetOffset(travel, 0)
    card.motionTranslation:SetDuration(travel / speed)
    card.motionStartX = x
    card.motionSpeed = speed
    card.motionStartTime = GetTime()
    card.motion:Play()
end

local function Layout()
    -- Keep enough cards off screen to form a seamless, evenly spaced loop.
    activeCount = math.max(2, math.ceil((screenWidth + size) / spacing) + 2)
    local left = -screenWidth / 2 - size / 2
    for i = 1, activeCount do
        local card = cards[i]
        if not card then
            card = CreateFrame("Frame", nil, frame)
            card:EnableMouse(false)
            card.texture = card:CreateTexture(nil, "ARTWORK")
            card.texture:SetAllPoints(card)
            CreateCardShine(card)
            card.motion = card:CreateAnimationGroup()
            card.motionTranslation = card.motion:CreateAnimation("Translation")
            if card.motionTranslation.SetSmoothing then
                card.motionTranslation:SetSmoothing("NONE")
            end
            cards[i] = card
        end
        card:SetSize(size, size)
        SizeCardShine(card)
        RandomTexture(card)
        card:Show()
        StartCardMotion(card, left - (i - 1) * spacing)
        UpdateCardShine(card)
    end
    for i = activeCount + 1, #cards do
        cards[i].motion:Stop()
        cards[i]:Hide()
    end
end

function AFK.Stop()
    testMode = false
    events:UnregisterEvent("PLAYER_STARTED_MOVING")
    frame:EnableKeyboard(false)
    frame:SetScript("OnUpdate", nil)
    frame:Hide()
    for _, card in ipairs(cards) do
        card.motion:Stop()
        card:Hide()
    end
    activeCount = 0
    logoVisible, maskVisible = false, false
    RestoreUI()
end

local function OnUpdate(self, elapsed)
    local config = Settings()
    if not config or not config.enabled or (not testMode and not UnitIsAFK("player")) then
        AFK.Stop()
        return
    end
    UpdateUIVisibility()
    if logoVisible then
        logoFade = math.min(FADE_DURATION, logoFade + elapsed)
        logo:SetAlpha(logoFade / FADE_DURATION)
    end
    if maskVisible then
        maskFade = math.min(FADE_DURATION, maskFade + elapsed)
        upperMask:SetAlpha(maskFade / FADE_DURATION)
        lowerMask:SetAlpha(maskFade / FADE_DURATION)
    end
    local now = GetTime()
    local right = screenWidth / 2 + size / 2
    local length = activeCount * spacing
    for i = 1, activeCount do
        local card = cards[i]
        card.x = card.motionStartX + (now - card.motionStartTime) * card.motionSpeed
        if card.x > right then
            -- Arithmetic wrapping also handles long frame stalls without loops.
            local wrappedX = card.x - math.ceil((card.x - right) / length) * length
            RandomTexture(card)
            StartCardMotion(card, wrappedX)
        end
        UpdateCardShine(card)
    end
end

function AFK.UpdateSettings()
    local config = Settings()
    if not config then return end
    config.scale = Clamp(config.scale, 1, 0.5, 1.5)
    config.spacing = Clamp(config.spacing, 400, 200, 600)
    config.scrollSpeed = Clamp(config.scrollSpeed, 250, 50, 500)
    local newSize = RAW_SIZE * config.scale
    local newSpacing = config.spacing
    local newWidth = UIParent:GetWidth()
    -- Modern clients retain UIParent and inherit its scale automatically.
    -- Only the detached Classic overlay needs an explicit root scale.
    local newFrameScale = isRetail and 1 or UIParent:GetEffectiveScale()
    local scaleChanged = frame:GetScale() ~= newFrameScale
    frame:SetScale(newFrameScale)
    local newY = tonumber(config.posY) or 0
    local changed = newSize ~= size or newSpacing ~= spacing or newWidth ~= screenWidth or newY ~= offsetY or scaleChanged
    local speedChanged = speed ~= config.scrollSpeed
    size, spacing, screenWidth, offsetY = newSize, newSpacing, newWidth, newY
    speed = config.scrollSpeed
    -- Original WA logo: 716 x 272, centered at Y +400. Fit it on short/narrow screens.
    local fit = math.min(1, UIParent:GetWidth() / 1920, UIParent:GetHeight() / 1080)
    logo:SetSize(716 * fit, 272 * fit)
    logo:ClearAllPoints()
    logo:SetPoint("CENTER", UIParent, "CENTER", 0, 400 * fit)
    UpdateVisuals(false)
    UpdateUIVisibility()
    if frame:IsShown() then
        if changed then
            Layout()
        elseif speedChanged then
            local now = GetTime()
            for i = 1, activeCount do
                local card = cards[i]
                local x = card.motionStartX + (now - card.motionStartTime) * card.motionSpeed
                StartCardMotion(card, x)
                UpdateCardShine(card)
            end
        end
    end
end

function AFK.RefreshState()
    local config = Settings()
    if not config or not config.enabled or not UnitIsAFK("player") or #(Addon.AFKTextures or {}) == 0 then
        AFK.Stop()
        return
    end
    AFK.UpdateSettings()
    if not frame:IsShown() then
        frame:Show()
        Layout()
        frame:SetScript("OnUpdate", OnUpdate)
        UpdateVisuals(true)
    end
    UpdateUIVisibility()
end

function AFK.Test()
    local config = Settings()
    if not config or not config.enabled or #(Addon.AFKTextures or {}) == 0 then return end
    testMode = true
    events:RegisterEvent("PLAYER_STARTED_MOVING")
    frame:EnableKeyboard(true)
    AFK.UpdateSettings()
    frame:Show()
    Layout()
    frame:SetScript("OnUpdate", OnUpdate)
    UpdateVisuals(true)
end

frame:SetScript("OnKeyDown", function(_, key)
    if testMode and key == "ESCAPE" then
        AFK.Stop()
    end
end)

function AFK.SetEnabled(enabled)
    local config = Settings()
    if config then config.enabled = enabled and true or false end
    events:UnregisterAllEvents()
    if enabled then
        events:RegisterEvent("PLAYER_FLAGS_CHANGED")
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        events:RegisterEvent("DISPLAY_SIZE_CHANGED")
        events:RegisterEvent("UI_SCALE_CHANGED")
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        events:RegisterEvent("PLAYER_LEAVING_WORLD")
        AFK.RefreshState()
    else
        AFK.Stop()
    end
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LEAVING_WORLD" then AFK.Stop(); return end
    if event == "PLAYER_STARTED_MOVING" and testMode then AFK.Stop(); return end
    if event == "PLAYER_FLAGS_CHANGED" and unit ~= "player" then return end
    AFK.RefreshState()
end)

function Addon:InitAFKModule()
    self.AFK.UpdateSettings()
    self.AFK.SetEnabled(self.db.modules.afk.enabled)
end

function AFK.ResetToDefault()
    AFK.Stop()
    local config = Settings()
    for key, value in pairs(Addon.defaults.modules.afk) do
        if key ~= "enabled" then config[key] = value end
    end
    AFK.UpdateSettings()
    AFK.SetEnabled(config.enabled)
end
