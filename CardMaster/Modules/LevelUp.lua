local _, Addon = ...

Addon.LevelUp = {}
local LevelUp = Addon.LevelUp

local FRAME_DURATION = 5.0
-- WA's fade preset supplies its own duration and discards the other saved
-- custom-animation fields (including translation, rotation and scaling).
local EXIT_DURATION = 0.25
local TOTAL_DURATION = FRAME_DURATION + EXIT_DURATION
local PARTICLE_ROWS, PARTICLE_FPS = 64, 40
-- Card-only sizing: do not scale the text, gradient, spacing or particles.
local CARD_SCALE = 0.8
local SIDE_CARD_SIZE, CENTER_CARD_SIZE = 500 * CARD_SCALE, 600 * CARD_SCALE
local TITLE_ALPHA = 0.5

local frame = CreateFrame("Frame", "CardMasterLevelUpFrame", UIParent)
frame:SetSize(1, 1)
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:EnableMouse(false)
frame:Hide()
local dragFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
dragFrame:SetSize(800, 650)
dragFrame:SetFrameStrata("DIALOG")
Addon:CreateMoveCanvas(dragFrame, "levelUp", function()
    local config = Addon.db and Addon.db.modules and Addon.db.modules.levelUp or {}
    return config.posX or 0, config.posY or 200
end)
if dragFrame.SetClampedToScreen then dragFrame:SetClampedToScreen(false) end
dragFrame:EnableMouse(false)
dragFrame:SetMovable(true)
dragFrame:RegisterForDrag("LeftButton")
-- GetCenter() is expressed in the scaled frame's coordinate space.  Saving it
-- directly made the preview snap away after a drag whenever the module scale
-- was not 1.  Keep the unscaled saved position and apply the mouse delta
-- instead, which is always in UIParent screen coordinates.
local dragStartCursorX, dragStartCursorY, dragStartPosX, dragStartPosY
local function UpdateDragPosition()
    local config = Addon.db and Addon.db.modules and Addon.db.modules.levelUp
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale() or 1
    if config and dragStartCursorX and dragStartCursorY then
        config.posX = dragStartPosX + (cursorX - dragStartCursorX) / uiScale
        config.posY = dragStartPosY + (cursorY - dragStartCursorY) / uiScale
        LevelUp.UpdateSettings()
    end
end
dragFrame:SetScript("OnDragStart", function(self)
    local config = Addon.db and Addon.db.modules and Addon.db.modules.levelUp
    dragStartCursorX, dragStartCursorY = GetCursorPosition()
    dragStartPosX = config and (config.posX or 0) or 0
    dragStartPosY = config and (config.posY or 200) or 200
    -- Do not use StartMoving here.  Blizzard's scaled-frame movement stores a
    -- second, rounded anchor which causes a small snap when it is released.
    self:SetScript("OnUpdate", UpdateDragPosition)
end)
dragFrame:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    UpdateDragPosition()
    dragStartCursorX, dragStartCursorY, dragStartPosX, dragStartPosY = nil, nil, nil, nil
end)
dragFrame:Hide()

-- Keep the cards in a higher frame as well as a higher draw layer, so no
-- FontString ordering rule can put Congratulations over their artwork.
local cardLayer = CreateFrame("Frame", nil, frame)
cardLayer:SetAllPoints(frame)
cardLayer:SetFrameLevel(frame:GetFrameLevel() + 1)
cardLayer:EnableMouse(false)

local function Config()
    return Addon.db and Addon.db.modules.levelUp
end

local function Clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function EaseInOut(progress)
    -- WeakAuras' easeOutIn curve, strength 3; apply before the pulse function.
    if progress < 0.5 then return (progress * 2)^3 * 0.5 end
    return 1 - ((1 - progress) * 2)^3 * 0.5
end

local function MakeTexture(width, height, x, y, texture, layer, blend, owner)
    local region = (owner or frame):CreateTexture(nil, layer or "ARTWORK")
    region:SetSize(width, height)
    region:SetPoint("CENTER", frame, "CENTER", x, y)
    region:SetTexture(texture)
    if blend then region:SetBlendMode(blend) end
    region:Hide()
    return region
end

local assets = Addon.LevelUpTextures
local function RefreshLevelCardTextures()
    local cards = Addon:GetLevelUpCardTextures()
    if not cards then return end
    assets.leftCard = cards.leftCard
    assets.centerCard = cards.centerCard
    assets.rightCard = cards.rightCard
end
-- The root already holds the WA's y = 200 anchor.  Child offsets are local;
-- adding another 200 here used to place the entire animation twice as high.
local rightBand = MakeTexture(600, 250, 299, 0, assets.gradient, "BACKGROUND")
rightBand:SetVertexColor(1, 0.5960784554, 0.2431372702, 1)
local leftBand = MakeTexture(600, 250, -299, 0, assets.gradient, "BACKGROUND")
leftBand:SetVertexColor(1, 0.5960784554, 0.2431372702, 1)
leftBand:SetRotation(math.pi)

-- Explicit draw layers: orange gradient < translucent text < side cards <
-- center card.  Auto width keeps the full word centered without wrapping.
local title = frame:CreateFontString(nil, "BORDER")
title:SetPoint("CENTER", frame, "CENTER", 0, 0)
title:SetFont(assets.font, 100, "")
title:SetText("Congratulations")
-- SetAlpha is animated below; put the 50% opacity in that single channel so
-- the animation cannot replace it with full opacity on the client.
title:SetTextColor(0, 0, 0, 1)
title:SetAlpha(TITLE_ALPHA)
title:SetJustifyH("CENTER")
title:Hide()

local leftCard = MakeTexture(SIDE_CARD_SIZE, SIDE_CARD_SIZE, -200, 0, assets.leftCard, "ARTWORK", nil, cardLayer)
local rightCard = MakeTexture(SIDE_CARD_SIZE, SIDE_CARD_SIZE, 200, 0, assets.rightCard, "ARTWORK", nil, cardLayer)
local centerCard = MakeTexture(CENTER_CARD_SIZE, CENTER_CARD_SIZE, 0, 0, assets.centerCard, "ARTWORK", nil, cardLayer)
centerCard:SetDrawLayer("ARTWORK", 1)

local leftParticles = MakeTexture(720, 180, -370, 0, assets.particles, "OVERLAY", "ADD")
local rightParticles = MakeTexture(720, 180, 370, 0, assets.particles, "OVERLAY", "ADD")

local displayRegions = {
    rightBand, leftBand, leftCard, centerCard, rightCard, leftParticles, rightParticles,
}

local function SetShown(shown)
    for _, region in ipairs(displayRegions) do region:SetShown(shown) end
    title:SetShown(shown)
end

local function SetRegionTransform(region, width, height, x, y, scaleX, scaleY, rotation, alpha)
    region:SetSize(math.max(1, width * math.abs(scaleX)), math.max(1, height * math.abs(scaleY)))
    region:ClearAllPoints()
    region:SetPoint("CENTER", frame, "CENTER", x, y)
    region:SetTexCoord(0, 1, 0, 1)
    region:SetRotation(math.rad(rotation or 0))
    region:SetAlpha(Clamp(alpha or 1, 0, 1))
end

local cardFaces = {}
local function SetCardFace(region, frontTexture, scaleX)
    -- Negative fauxspin scale is the rear-facing half of the turn.  Use the
    -- real card back instead of a horizontally mirrored copy of the front.
    local texture = scaleX < 0 and Addon:GetCardBackTexture() or frontTexture
    if cardFaces[region] ~= texture then
        region:SetTexture(texture)
        cardFaces[region] = texture
    end
end

local function RenderBands(time)
    local scaleY, alpha = 1, 1
    if time < 0.3 then
        -- WA reverses start progress before applying easeOut, strength 3.
        scaleY = (time / 0.3)^3
    elseif time > FRAME_DURATION then
        local progress = Clamp((time - FRAME_DURATION) / EXIT_DURATION, 0, 1)
        alpha = 1 - progress
    end
    SetRegionTransform(leftBand, 600, 250, -299, 0, 1, scaleY, 180, alpha)
    SetRegionTransform(rightBand, 600, 250, 299, 0, 1, scaleY, 0, alpha)
end

local function RenderSideCard(region, frontTexture, baseX, baseRotation, startX, startRotation, mainRotation, time)
    local x, scaleX, rotation, alpha = baseX, 1, baseRotation, 1
    if time < 0.5 then
        local progress = 1 - Clamp(time / 0.5, 0, 1)
        scaleX = math.cos(progress * 2 * math.pi)
        x = baseX + startX * progress
        rotation = baseRotation + startRotation * progress
        alpha = 1 - progress
    else
        -- Side cards enable only wobble during main, not the saved scale
        -- parameters.  Hold the last pose throughout the pure-alpha exit.
        local progress = (math.min(time, FRAME_DURATION) - 0.5) / 10
        rotation = baseRotation + math.sin(progress * 2 * math.pi) * mainRotation
        alpha = 1 - Clamp((time - FRAME_DURATION) / EXIT_DURATION, 0, 1)
    end
    SetCardFace(region, frontTexture, scaleX)
    SetRegionTransform(region, SIDE_CARD_SIZE, SIDE_CARD_SIZE, x, 0, scaleX, 1, rotation, alpha)
end

local function RenderCenterCard(time)
    local scaleX, scaleY, alpha = 1, 1, 1
    if time < 1 then
        -- The start is inverted by WA BEFORE easing.  With easeIn strength
        -- 5, height contracts 3 -> 1; it must not grow 1 -> 3 while fading in.
        local progress = (1 - Clamp(time, 0, 1))^5
        scaleX = math.cos(progress * 2 * math.pi)
        scaleY = 1 + progress * 2
        alpha = 1 - progress
    else
        -- Main: 0.8-second pulse, 1.15 x 1.15, easeOutIn strength 3.
        local cycle = ((math.min(time, FRAME_DURATION) - 1) % 0.8) / 0.8
        local progress = EaseInOut(cycle)
        local pulse = ((math.sin(progress * 2 * math.pi - math.pi / 2) + 1) / 2) * 0.15
        scaleX, scaleY = 1 + pulse, 1 + pulse
        alpha = 1 - Clamp((time - FRAME_DURATION) / EXIT_DURATION, 0, 1)
    end
    SetCardFace(centerCard, assets.centerCard, scaleX)
    SetRegionTransform(centerCard, CENTER_CARD_SIZE, CENTER_CARD_SIZE, 0, 0, scaleX, scaleY, 0, alpha)
end

local function RenderParticles(time)
    local frameIndex = math.floor(time * PARTICLE_FPS) % PARTICLE_ROWS
    local function SetParticle(region, reverse)
        local index = reverse and (PARTICLE_ROWS - 1 - frameIndex) or frameIndex
        local top, bottom = index / PARTICLE_ROWS, (index + 1) / PARTICLE_ROWS
        region:SetTexCoord(0, 1, top, bottom)
        region:SetAlpha(time < FRAME_DURATION and 1 or 0)
    end
    SetParticle(leftParticles, true)
    SetParticle(rightParticles, false)
end

local elapsed = 0

local function Render(time)
    RenderBands(time)
    RenderSideCard(leftCard, assets.leftCard, -200, 20, -500, 60, -5, time)
    RenderSideCard(rightCard, assets.rightCard, 200, 340, 500, -60, 5, time)
    RenderCenterCard(time)
    RenderParticles(time)
    local titleAlpha = Clamp(time / EXIT_DURATION, 0, 1)
    if time > FRAME_DURATION then titleAlpha = 1 - Clamp((time - FRAME_DURATION) / EXIT_DURATION, 0, 1) end
    title:SetAlpha(titleAlpha * TITLE_ALPHA)
end

local function OnUpdate(_, delta)
    local config = Config()
    if not config or not config.enabled then LevelUp.Stop(); return end
    elapsed = elapsed + delta * (config.speed or 1)
    if elapsed >= TOTAL_DURATION then
        LevelUp.Stop()
        return
    end
    Render(elapsed)
end

function LevelUp.UpdateSettings()
    local config = Config()
    if not config then return end
    config.speed = Clamp(tonumber(config.speed) or 1, 0.5, 2)
    config.scale = Clamp(tonumber(config.scale) or 1, 0.5, 2)
    frame:SetScale(config.scale)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", config.posX or 0, config.posY or 200)
    if dragFrame:IsShown() then
        dragFrame:SetScale(config.scale)
        dragFrame:ClearAllPoints()
        dragFrame:SetPoint("CENTER", UIParent, "CENTER", config.posX or 0, config.posY or 200)
    end
end

function LevelUp.ToggleDragMode()
    local config = Config()
    if not config or not config.enabled then return false end
    if dragFrame:IsShown() then
        dragFrame:StopMovingOrSizing()
        dragFrame:SetScript("OnUpdate", nil)
        dragFrame:Hide()
        dragFrame:EnableMouse(false)
        return false
    end
    LevelUp.UpdateSettings()
    dragFrame:SetScale(config.scale or 1)
    dragFrame:ClearAllPoints()
    dragFrame:SetPoint("CENTER", UIParent, "CENTER", config.posX or 0, config.posY or 200)
    dragFrame:Show()
    dragFrame:EnableMouse(true)
    return true
end

function LevelUp.IsDragging() return dragFrame:IsShown() end

function LevelUp.Stop()
    elapsed = 0
    frame:SetScript("OnUpdate", nil)
    dragFrame:StopMovingOrSizing()
    dragFrame:SetScript("OnUpdate", nil)
    dragFrame:Hide()
    dragFrame:EnableMouse(false)
    SetShown(false)
    frame:Hide()
end

function LevelUp.Play(_, preview)
    local config = Config()
    if not config or (not config.enabled and not preview) then return false end
    LevelUp.Stop()
    -- Resolve the three faces at play time.  This makes the animation follow
    -- the front style selected in 卡牌样式, including a change made moments
    -- before clicking 测试效果.
    RefreshLevelCardTextures()
    LevelUp.UpdateSettings()
    elapsed = 0
    Render(0)
    SetShown(true)
    frame:Show()
    if config.soundEnabled ~= false then
        PlaySoundFile(assets.flipSound, "Master")
        PlaySoundFile(assets.fanfareSound, "Master")
    end
    frame:SetScript("OnUpdate", OnUpdate)
    return true
end

function LevelUp.SetEnabled(enabled)
    local config = Config()
    if not config then return end
    config.enabled = enabled and true or false
    if not config.enabled then LevelUp.Stop() else LevelUp.UpdateSettings() end
end

function LevelUp.ResetToDefault()
    LevelUp.Stop()
    local config = Config()
    for key, value in pairs(Addon.defaults.modules.levelUp) do
        if key ~= "enabled" then config[key] = value end
    end
    LevelUp.UpdateSettings()
end

function Addon:InitLevelUpModule()
    self.LevelUp.UpdateSettings()
    self.LevelUp.SetEnabled(self.db.modules.levelUp.enabled)
end
