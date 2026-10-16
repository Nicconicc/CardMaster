local _, Addon = ...
local Animation = Addon.CombatInAnimation
local SOUND_PATH = "Interface\\AddOns\\CardMaster\\Audio\\TCG.ogg"
local soundHandle
local playbackRate, animationTime = 1, 0

-- Do not use a ScrollFrame here: it crops the lower part of a card at the
-- original 512px comp boundary. A normal frame lets the complete card art
-- extend past that guide while still remaining non-interactive.
local mainFrame = CreateFrame("Frame", "CardMasterCombatInFrame", UIParent)
mainFrame:SetSize(Animation.width, Animation.height)
mainFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, -50)
mainFrame:EnableMouse(false)
mainFrame:Hide()
local stage = CreateFrame("Frame", nil, mainFrame)
stage:SetSize(Animation.width, Animation.height)
-- SetScrollChild used to supply this anchor automatically. A normal frame
-- needs an explicit anchor or its card children have no screen position.
stage:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
stage:EnableMouse(false)

local cards = {}
-- Four strips per card approximate perspective without pre-rendered frames.
-- Separate frame levels keep one card's strips together in the stack.
local STRIPS = 4
local hasVertexOffsets
for index = 1, Animation.cardCount do
    local frame = CreateFrame("Frame", nil, stage)
    frame:SetAllPoints(stage)
    frame:SetFrameLevel(stage:GetFrameLevel() + index)
    frame:EnableMouse(false)
    local card = { frame = frame, textures = {}, state = {} }
    for strip = 1, STRIPS do
        local texture = frame:CreateTexture(nil, "ARTWORK")
        texture:SetSize(1, 1)
        texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        card.textures[strip] = texture
        if hasVertexOffsets == nil then
            hasVertexOffsets = texture.SetVertexOffset ~= nil
                and UPPER_LEFT_VERTEX ~= nil and LOWER_LEFT_VERTEX ~= nil
                and UPPER_RIGHT_VERTEX ~= nil and LOWER_RIGHT_VERTEX ~= nil
        end
    end
    frame:Hide()
    cards[index] = card
end

local function SetCorner(texture, vertex, x, y, baseX, baseY)
    -- AE coordinates grow downwards; WoW vertex offsets grow upwards.
    texture:SetVertexOffset(vertex, x - baseX, baseY - y)
end

local function DrawCard(card, state)
    local path = state.back and card.backTexture or card.frontTexture
    if path ~= card.currentTexture then
        for _, texture in ipairs(card.textures) do texture:SetTexture(path) end
        card.currentTexture = path
    end
    if hasVertexOffsets then
        for strip, texture in ipairs(card.textures) do
            local u0, u1 = (strip - 1) / STRIPS, strip / STRIPS
            local left, right = u0, u1
            if state.back then left, right = 1 - u0, 1 - u1 end
            texture:SetTexCoord(left, right, 0, 1)
            local x, y = Animation.Project(state, u0, 0)
            SetCorner(texture, UPPER_LEFT_VERTEX, x, y, 0, 0)
            x, y = Animation.Project(state, u0, 1)
            SetCorner(texture, LOWER_LEFT_VERTEX, x, y, 0, 1)
            x, y = Animation.Project(state, u1, 0)
            SetCorner(texture, UPPER_RIGHT_VERTEX, x, y, 1, 0)
            x, y = Animation.Project(state, u1, 1)
            SetCorner(texture, LOWER_RIGHT_VERTEX, x, y, 1, 1)
            texture:Show()
        end
    else
        -- Compatibility fallback for clients without texture vertex offsets.
        local texture = card.textures[1]
        texture:ClearAllPoints()
        texture:SetPoint("CENTER", card.frame, "TOPLEFT", state.x, -state.y)
        texture:SetSize(math.max(0.5, Animation.cardSize * math.abs(math.cos(math.rad(state.yaw)))), Animation.cardSize)
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetRotation(-math.rad(state.roll))
        texture:Show()
        for strip = 2, STRIPS do card.textures[strip]:Hide() end
    end
    card.frame:Show()
end

local function Render(time)
    for index, card in ipairs(cards) do
        local state = Animation.Sample(index, time, card.state, card.layout)
        if state.visible and card.frontTexture then DrawCard(card, state) else card.frame:Hide() end
    end
end

local function StopAnimation()
    mainFrame:SetScript("OnUpdate", nil)
    mainFrame:Hide()
    for _, card in ipairs(cards) do card.frame:Hide() end
    animationTime = 0
    if soundHandle then StopSound(soundHandle); soundHandle = nil end
end

local function OnUpdate(_, elapsed)
    animationTime = animationTime + elapsed * playbackRate
    if animationTime >= Animation.duration then
        StopAnimation()
    else
        Render(animationTime)
    end
end

local dragFrame = CreateFrame("Frame", "CardMasterCombatInDragFrame", UIParent)
dragFrame:SetSize(Animation.width, Animation.height)
dragFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, -50)
dragFrame:SetMovable(true)
dragFrame:EnableMouse(false)
dragFrame:RegisterForDrag("LeftButton")
Addon:CreateMoveCanvas(dragFrame, "inCombat", function()
    local db = Addon.legacyDB or {}
    return db.ciPosX or 0, db.ciPosY or -50
end)
dragFrame:Hide()

-- Move the preview from the mouse delta rather than using StartMoving().
-- StartMoving() stores anchors in the scaled frame space; when these anchors
-- were converted back to ciPosX/ciPosY, the preview jumped on mouse release.
local dragStartCursorX, dragStartCursorY, dragStartPosX, dragStartPosY
local function UpdateDragPosition()
    local db = Addon.legacyDB
    if not db or not dragStartCursorX or not dragStartCursorY then return end
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale() or 1
    db.ciPosX = dragStartPosX + (cursorX - dragStartCursorX) / uiScale
    db.ciPosY = dragStartPosY + (cursorY - dragStartCursorY) / uiScale
    Addon.CombatIn.UpdateSettings()
end
dragFrame:SetScript("OnDragStart", function(self)
    local db = Addon.legacyDB or {}
    dragStartCursorX, dragStartCursorY = GetCursorPosition()
    dragStartPosX, dragStartPosY = db.ciPosX or 0, db.ciPosY or -50
    self:SetScript("OnUpdate", UpdateDragPosition)
end)
dragFrame:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    UpdateDragPosition()
    dragStartCursorX, dragStartCursorY, dragStartPosX, dragStartPosY = nil, nil, nil, nil
end)

Addon.CombatIn = {}
local CombatIn = Addon.CombatIn

function CombatIn.UpdateSettings()
    local db = Addon.legacyDB or {}
    local scale = math.max(0.5, math.min(1, tonumber(db.ciScale) or 0.7))
    -- Preserve saved values: the old default 60 now means 1x playback.
    -- Motion follows elapsed time, independently of the game's rendering FPS.
    playbackRate = math.max(15, math.min(120, tonumber(db.ciSpeed) or 60)) / 60
    -- Only the real animation changes layer.  The green move canvas remains
    -- interactive above the UI even when the animation itself is background.
    local animationStrata = db.ciBottomLayer and "BACKGROUND" or "FULLSCREEN_DIALOG"
    mainFrame:SetFrameStrata(animationStrata)
    mainFrame:SetFrameLevel(db.ciBottomLayer and 0 or 10)
    stage:SetFrameStrata(animationStrata)
    for _, card in ipairs(cards) do card.frame:SetFrameStrata(animationStrata) end
    mainFrame:SetScale(scale)
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", db.ciPosX or 0, db.ciPosY or -50)
    dragFrame:SetScale(scale)
    dragFrame:ClearAllPoints()
    dragFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", db.ciPosX or 0, db.ciPosY or -50)
end

function CombatIn.Play()
    if not Addon:IsIntegratedEnabled("inCombat") then return end
    StopAnimation()
    CombatIn.UpdateSettings()
    local deck = Animation.GetRandomClassDeck(Animation.cardCount)
    local layout = Animation.CreateDealLayout()
    local back = Addon:GetCardBackTexture()
    for index, card in ipairs(cards) do
        local selected = deck[index]
        card.frontTexture = selected and selected.texture or nil
        card.spellName = selected and selected.name or nil
        card.layout = layout[index]
        card.backTexture = back
        card.currentTexture = nil
    end
    local config = Addon.db and Addon.db.modules and Addon.db.modules.inCombat
    if not config or config.soundEnabled ~= false then
        local _, handle = PlaySoundFile(SOUND_PATH, "Master")
        soundHandle = handle
    end
    Render(0)
    mainFrame:SetScript("OnUpdate", OnUpdate)
    mainFrame:Show()
end

function CombatIn.ToggleDragMode()
    if not Addon:IsIntegratedEnabled("inCombat") then return false end
    CombatIn.UpdateSettings()
    local dragging = not dragFrame:IsShown()
    if dragging then
        dragFrame:Show()
    else
        dragFrame:StopMovingOrSizing()
        dragFrame:SetScript("OnUpdate", nil)
        dragFrame:Hide()
    end
    dragFrame:EnableMouse(dragging)
    return dragging
end

function CombatIn.Stop()
    StopAnimation()
    dragFrame:StopMovingOrSizing()
    dragFrame:SetScript("OnUpdate", nil)
    dragFrame:Hide()
    dragFrame:EnableMouse(false)
end

function CombatIn.IsDragging() return dragFrame:IsShown() end

-- Keep the original normal-combat / boss-combat trigger conditions.
local isBossCombat = false
local eventHandler = CreateFrame("Frame")
eventHandler:SetScript("OnEvent", function(_, event)
    if not Addon:IsIntegratedEnabled("inCombat") then return end
    if event == "ENCOUNTER_START" then
        isBossCombat = true
    elseif event == "ENCOUNTER_END" then
        isBossCombat = false
    elseif event == "PLAYER_REGEN_DISABLED" then
        local db = Addon.legacyDB
        if not db then return end
        -- Retail 12.x protects boss-unit state. ENCOUNTER_START is the safe
        -- authoritative signal there; Classic keeps its boss1 fallback.
        local boss = isBossCombat or (not Addon:IsRetail() and UnitExists("boss1") and true or false)
        if (boss and db.ciBossCombat ~= false) or (not boss and db.ciNormalCombat ~= false) then
            CombatIn.Play()
        end
    end
end)

function CombatIn.SetEnabled(enabled)
    eventHandler:UnregisterAllEvents()
    if enabled then
        isBossCombat = Addon.encounterActive or (not Addon:IsRetail() and UnitExists("boss1") and true or false)
        CombatIn.UpdateSettings()
        eventHandler:RegisterEvent("PLAYER_REGEN_DISABLED")
        eventHandler:RegisterEvent("ENCOUNTER_START")
        eventHandler:RegisterEvent("ENCOUNTER_END")
    else
        CombatIn.Stop()
    end
end
