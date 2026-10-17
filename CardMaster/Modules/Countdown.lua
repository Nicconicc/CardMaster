local _, Addon = ...

-- DBM's /pull command starts Blizzard's START_PLAYER_COUNTDOWN event.  This
-- module consumes that client event directly, so it follows DBM pull timers
-- without taking a hard dependency on DBM or its localized timer text.
Addon.Countdown = {}
local Countdown = Addon.Countdown

local ROOT = "Interface\\AddOns\\CardMaster\\"
local RAW_SIZE = 512
local CARD_COUNTDOWN_MAX = 10
local ENTER_TIME, HOLD_TIME, EXIT_TIME = 0.28, 0.40, 0.28
local cards, activeCountdown = {}, false
local countdownStart, countdownSeconds, lastSecond
local dragFrame
-- The visible cards and the green position canvas share this unscaled anchor.
-- This keeps their visual centre identical at every overall-scale value.
local positionAnchor = CreateFrame("Frame", "CardMasterCountdownAnchor", UIParent)
positionAnchor:SetSize(1, 1)

local function Config()
    return Addon.db and Addon.db.modules and Addon.db.modules.countdown
end

local function SetTexture(card, texture)
    card.texture:SetTexture(texture)
    card.texture:SetTexCoord(0, 1, 0, 1)
end

local function RandomSigned(amount)
    return math.random(-amount, amount)
end

local function GetAvailableCard()
    for _, card in ipairs(cards) do
        if not card.animating then return card end
    end

    local card = CreateFrame("Frame", nil, UIParent)
    card:SetSize(RAW_SIZE, RAW_SIZE)
    card:SetFrameStrata("FULLSCREEN_DIALOG")
    card:EnableMouse(false)
    card.texture = card:CreateTexture(nil, "ARTWORK")
    card.texture:SetAllPoints(card)
    card:Hide()
    card:SetScript("OnUpdate", function(self, elapsed)
        if not self.animating then return end
        local config = Config()
        if not config then self.animating = false; self:Hide(); return end

        self.elapsed = self.elapsed + elapsed * (config.speed or 1)
        local total = ENTER_TIME + HOLD_TIME + EXIT_TIME
        if self.elapsed >= total then
            self.animating = false
            self:Hide()
            return
        end

        local progress, x, y, rotation, xScale, yScale, alpha = 0, 0, 0, 0, 1, 1, 1
        local showingFront = true
        if self.elapsed < ENTER_TIME then
            progress = self.elapsed / ENTER_TIME
            local eased = 1 - (1 - progress) * (1 - progress)
            x = self.inX * (1 - eased)
            y = self.inY * (1 - eased)
            rotation = self.inRotation * (1 - eased)
            local zoom = math.sin(progress * math.pi)
            xScale = 1 + (self.inZoomX - 1) * zoom
            yScale = 1 + (self.inZoomY - 1) * zoom
            xScale = xScale * math.max(0.06, math.abs(math.cos((1 - progress) * math.pi)))
            alpha = math.min(1, progress * 3)
            showingFront = progress >= 0.5
        elseif self.elapsed >= ENTER_TIME + HOLD_TIME then
            progress = (self.elapsed - ENTER_TIME - HOLD_TIME) / EXIT_TIME
            x = self.outX * progress
            y = self.outY * progress
            rotation = self.outRotation * progress
            local shrink = 1 - 0.5 * progress
            xScale = shrink * math.max(0.06, math.abs(math.cos(progress * math.pi / 2)))
            yScale = shrink
            alpha = 1 - progress
            showingFront = progress < 0.55
        end

        SetTexture(self, showingFront and self.frontTexture or self.backTexture)
        self:ClearAllPoints()
        self:SetPoint("CENTER", positionAnchor, "CENTER", x, y)
        self:SetSize(RAW_SIZE * (config.scale or 0.7) * xScale, RAW_SIZE * (config.scale or 0.7) * yScale)
        self.texture:SetRotation(math.rad(rotation))
        self:SetAlpha(alpha)
    end)
    table.insert(cards, card)
    return card
end

function Countdown.ShowSecond(second)
    local config = Config()
    -- Pull timers may be longer than ten seconds.  Card artwork is reserved
    -- for 10..1, so the earlier part of a long pull deliberately stays quiet.
    if not config or not config.enabled or second < 1 or second > CARD_COUNTDOWN_MAX then return end
    local card = GetAvailableCard()
    card.elapsed = 0
    card.animating = true
    -- Every countdown card receives its own full-range entry motion.
    card.inX, card.inY = RandomSigned(500), RandomSigned(500)
    card.outX, card.outY = RandomSigned(220), RandomSigned(120)
    card.inRotation, card.outRotation = RandomSigned(42), RandomSigned(32)
    card.inZoomX = math.random(115, 170) / 100
    card.inZoomY = math.random(115, 170) / 100
    card.backTexture = Addon:GetCardBackTexture()
    -- One artwork set lives under each front style's Numbers folder.  The
    -- displayed number is therefore tied to the same style selected in
    -- “卡牌样式”, rather than being a random profession spell card.
    card.frontTexture = Addon:GetCountdownNumberTexture(second) or card.backTexture
    card:SetFrameLevel(20 + second)
    card:SetAlpha(1)
    card:Show()

    if config.soundEnabled ~= false then
        PlaySoundFile(ROOT .. "Audio\\card sound.ogg", "Master")
    end
end

local function StopCountdown()
    activeCountdown = false
    countdownStart, countdownSeconds, lastSecond = nil, nil, nil
end

local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, _)
    if not activeCountdown then return end
    local remaining = math.ceil(countdownSeconds - (GetTime() - countdownStart))
    if remaining < 1 then
        StopCountdown()
        return
    end
    if remaining ~= lastSecond then
        lastSecond = remaining
        Countdown.ShowSecond(remaining)
    end
end)

function Countdown.Start(seconds, preview)
    local config = Config()
    if not config or (not config.enabled and not preview) then return false end
    seconds = math.floor(tonumber(seconds) or 0)
    if seconds < 1 then return false end
    -- /pull normally permits up to 60 seconds.  For long pulls the ticker
    -- waits silently until the remaining time reaches ten.
    seconds = math.min(seconds, 60)
    StopCountdown()
    activeCountdown = true
    countdownSeconds = seconds
    countdownStart = GetTime()
    lastSecond = seconds
    if seconds <= CARD_COUNTDOWN_MAX then
        Countdown.ShowSecond(seconds)
    end
    return true
end

function Countdown.Stop()
    StopCountdown()
    for _, card in ipairs(cards) do
        card.animating = false
        card:Hide()
    end
    dragFrame:Hide()
    dragFrame:EnableMouse(false)
end

dragFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
dragFrame:SetSize(RAW_SIZE, RAW_SIZE)
dragFrame:SetFrameStrata("DIALOG")
Addon:CreateMoveCanvas(dragFrame, "countdown", function()
    local config = Config() or {}
    return config.posX or 0, config.posY or 200
end)
dragFrame:SetMovable(true)
dragFrame:RegisterForDrag("LeftButton")
dragFrame:EnableMouse(false)
dragFrame:Hide()

local startCursorX, startCursorY, startPosX, startPosY
local function UpdateDragPosition()
    local config = Config()
    if not config or not startCursorX then return end
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale() or 1
    config.posX = startPosX + (cursorX - startCursorX) / uiScale
    config.posY = startPosY + (cursorY - startCursorY) / uiScale
    Countdown.UpdateSettings()
end
dragFrame:SetScript("OnDragStart", function(self)
    local config = Config()
    startCursorX, startCursorY = GetCursorPosition()
    startPosX, startPosY = config.posX or 0, config.posY or 200
    self:SetScript("OnUpdate", UpdateDragPosition)
end)
dragFrame:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    UpdateDragPosition()
    startCursorX, startCursorY, startPosX, startPosY = nil, nil, nil, nil
end)

function Countdown.UpdateSettings()
    local config = Config()
    if not config then return end
    config.scale = math.max(0.3, math.min(1.5, tonumber(config.scale) or 0.7))
    config.speed = math.max(0.5, math.min(2, tonumber(config.speed) or 1))
    positionAnchor:ClearAllPoints()
    positionAnchor:SetPoint("CENTER", UIParent, "CENTER", config.posX or 0, config.posY or 200)
    if dragFrame:IsShown() then
        dragFrame:SetScale(config.scale)
        dragFrame:ClearAllPoints()
        dragFrame:SetPoint("CENTER", positionAnchor, "CENTER")
    end
end

function Countdown.ToggleDragMode()
    local config = Config()
    if not config or not config.enabled then return false end
    if dragFrame:IsShown() then
        dragFrame:SetScript("OnUpdate", nil)
        dragFrame:Hide()
        dragFrame:EnableMouse(false)
        return false
    end
    Countdown.UpdateSettings()
    dragFrame:SetScale(config.scale or 0.7)
    dragFrame:ClearAllPoints()
    dragFrame:SetPoint("CENTER", positionAnchor, "CENTER")
    dragFrame:Show()
    dragFrame:EnableMouse(true)
    return true
end

function Countdown.IsDragging()
    return dragFrame:IsShown()
end

function Countdown.ResetToDefault()
    local config = Config()
    if not config then return end
    local defaults = Addon.defaults.modules.countdown
    for key, value in pairs(defaults) do config[key] = value end
    Countdown.Stop()
    Countdown.UpdateSettings()
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(_, event, _, seconds)
    if event == "START_PLAYER_COUNTDOWN" then
        Countdown.Start(seconds)
    elseif event == "CANCEL_PLAYER_COUNTDOWN" then
        StopCountdown()
    end
end)

function Countdown.SetEnabled(enabled)
    local config = Config()
    if not config then return end
    config.enabled = enabled and true or false
    events:UnregisterAllEvents()
    Countdown.Stop()
    if config.enabled then
        events:RegisterEvent("START_PLAYER_COUNTDOWN")
        events:RegisterEvent("CANCEL_PLAYER_COUNTDOWN")
        Countdown.UpdateSettings()
    end
end

function Addon:InitCountdownModule()
    Countdown.SetEnabled(self.db and self.db.modules.countdown and self.db.modules.countdown.enabled)
end
