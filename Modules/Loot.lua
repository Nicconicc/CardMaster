local _, Addon = ...

Addon.Loot = {}
local Loot = Addon.Loot

local DISPLAY_DURATION, FADE_DURATION = 5.0, 0.25
local TOTAL_DURATION = DISPLAY_DURATION + FADE_DURATION
local PARTICLE_ROWS, PARTICLE_FPS = 64, 40
local CARD_SCALE = 0.8
local SIDE_CARD_SIZE, CENTER_CARD_SIZE = 500 * CARD_SCALE, 600 * CARD_SCALE
local TITLE_ALPHA = 0.5

local frame = CreateFrame("Frame", "CardMasterLootFrame", UIParent)
frame:SetSize(1, 1)
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:EnableMouse(false)
frame:Hide()
local dragFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
dragFrame:SetSize(800, 650)
dragFrame:SetFrameStrata("DIALOG")
Addon:CreateMoveCanvas(dragFrame, "loot")
if dragFrame.SetClampedToScreen then dragFrame:SetClampedToScreen(false) end
dragFrame:EnableMouse(false)
dragFrame:SetMovable(true)
dragFrame:RegisterForDrag("LeftButton")
dragFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
dragFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local config = Addon.db and Addon.db.modules and Addon.db.modules.loot
    local x, y = self:GetCenter()
    local cx, cy = UIParent:GetCenter()
    if config and x and y and cx and cy then
        config.posX, config.posY = x - cx, y - cy
        Loot.UpdateSettings()
    end
end)
dragFrame:Hide()

local cardLayer = CreateFrame("Frame", nil, frame)
cardLayer:SetAllPoints(frame)
cardLayer:SetFrameLevel(frame:GetFrameLevel() + 1)
cardLayer:EnableMouse(false)

local function Config() return Addon.db and Addon.db.modules.loot end
local function Clamp(value, low, high) return math.max(low, math.min(high, value)) end
local function IsRaidInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == "raid"
end
local function EaseInOut(progress)
    if progress < 0.5 then return (progress * 2)^3 * 0.5 end
    return 1 - ((1 - progress) * 2)^3 * 0.5
end

local assets = Addon.LootTextures
local function MakeTexture(width, height, x, y, texture, layer, blend, owner)
    local region = (owner or frame):CreateTexture(nil, layer or "ARTWORK")
    region:SetSize(width, height)
    region:SetPoint("CENTER", frame, "CENTER", x, y)
    region:SetTexture(texture)
    if blend then region:SetBlendMode(blend) end
    region:Hide()
    return region
end

local rightBand = MakeTexture(600, 250, 299, 0, assets.gradient, "BACKGROUND")
rightBand:SetVertexColor(1, 0.5960784554, 0.2431372702, 1)
local leftBand = MakeTexture(600, 250, -299, 0, assets.gradient, "BACKGROUND")
leftBand:SetVertexColor(1, 0.5960784554, 0.2431372702, 1)

local title = frame:CreateFontString(nil, "BORDER")
title:SetPoint("CENTER", frame, "CENTER")
title:SetFont(assets.font, 100, "")
title:SetText("Congratulations")
title:SetTextColor(0, 0, 0, 1)
title:SetJustifyH("CENTER")
title:Hide()

local leftCard = MakeTexture(SIDE_CARD_SIZE, SIDE_CARD_SIZE, -200, 0, nil, "ARTWORK", nil, cardLayer)
local rightCard = MakeTexture(SIDE_CARD_SIZE, SIDE_CARD_SIZE, 200, 0, nil, "ARTWORK", nil, cardLayer)
local centerCard = MakeTexture(CENTER_CARD_SIZE, CENTER_CARD_SIZE, 0, 0, nil, "ARTWORK", nil, cardLayer)
centerCard:SetDrawLayer("ARTWORK", 1)
local leftParticles = MakeTexture(720, 180, -370, 0, assets.particles, "OVERLAY", "ADD")
local rightParticles = MakeTexture(720, 180, 370, 0, assets.particles, "OVERLAY", "ADD")

local displayRegions = { rightBand, leftBand, leftCard, rightCard, centerCard, leftParticles, rightParticles }
local function SetShown(shown)
    for _, region in ipairs(displayRegions) do region:SetShown(shown) end
    title:SetShown(shown)
end
local function SetTransform(region, width, height, x, y, scaleX, scaleY, rotation, alpha)
    region:SetSize(math.max(1, width * math.abs(scaleX)), math.max(1, height * math.abs(scaleY)))
    region:ClearAllPoints()
    region:SetPoint("CENTER", frame, "CENTER", x, y)
    region:SetTexCoord(0, 1, 0, 1)
    region:SetRotation(math.rad(rotation or 0))
    region:SetAlpha(Clamp(alpha or 1, 0, 1))
end

local currentTexture, cardFaces = nil, {}
local function SetCardFace(region, scaleX)
    local texture = scaleX < 0 and Addon:GetCardBackTexture() or currentTexture
    if cardFaces[region] ~= texture then
        region:SetTexture(texture)
        cardFaces[region] = texture
    end
end
local function RenderBands(time)
    local scaleY, alpha = 1, 1
    if time < 0.3 then
        scaleY = (time / 0.3)^3
    elseif time > DISPLAY_DURATION then
        alpha = 1 - Clamp((time - DISPLAY_DURATION) / FADE_DURATION, 0, 1)
    end
    SetTransform(leftBand, 600, 250, -299, 0, 1, scaleY, 180, alpha)
    SetTransform(rightBand, 600, 250, 299, 0, 1, scaleY, 0, alpha)
end
local function RenderSideCard(region, baseX, baseRotation, startX, startRotation, mainRotation, time)
    local x, scaleX, rotation, alpha = baseX, 1, baseRotation, 1
    if time < 0.5 then
        local progress = 1 - Clamp(time / 0.5, 0, 1)
        scaleX = math.cos(progress * 2 * math.pi)
        x = baseX + startX * progress
        rotation = baseRotation + startRotation * progress
        alpha = 1 - progress
    else
        local progress = (math.min(time, DISPLAY_DURATION) - 0.5) / 10
        rotation = baseRotation + math.sin(progress * 2 * math.pi) * mainRotation
        alpha = 1 - Clamp((time - DISPLAY_DURATION) / FADE_DURATION, 0, 1)
    end
    SetCardFace(region, scaleX)
    SetTransform(region, SIDE_CARD_SIZE, SIDE_CARD_SIZE, x, 0, scaleX, 1, rotation, alpha)
end
local function RenderCenterCard(time)
    local scaleX, scaleY, alpha = 1, 1, 1
    if time < 1 then
        local progress = (1 - Clamp(time, 0, 1))^5
        scaleX = math.cos(progress * 2 * math.pi)
        scaleY = 1 + progress * 2
        alpha = 1 - progress
    else
        local cycle = ((math.min(time, DISPLAY_DURATION) - 1) % 0.8) / 0.8
        local progress = EaseInOut(cycle)
        local pulse = ((math.sin(progress * 2 * math.pi - math.pi / 2) + 1) / 2) * 0.15
        scaleX, scaleY = 1 + pulse, 1 + pulse
        alpha = 1 - Clamp((time - DISPLAY_DURATION) / FADE_DURATION, 0, 1)
    end
    SetCardFace(centerCard, scaleX)
    SetTransform(centerCard, CENTER_CARD_SIZE, CENTER_CARD_SIZE, 0, 0, scaleX, scaleY, 0, alpha)
end
local function RenderParticles(time)
    local frameIndex = math.floor(time * PARTICLE_FPS) % PARTICLE_ROWS
    local function SetParticle(region, reverse)
        local index = reverse and (PARTICLE_ROWS - 1 - frameIndex) or frameIndex
        region:SetTexCoord(0, 1, index / PARTICLE_ROWS, (index + 1) / PARTICLE_ROWS)
        region:SetAlpha(time < DISPLAY_DURATION and 1 or 0)
    end
    SetParticle(leftParticles, true)
    SetParticle(rightParticles, false)
end

local elapsed, previewing = 0, false
local function Render(time)
    RenderBands(time)
    RenderSideCard(leftCard, -200, 20, -500, 60, -5, time)
    RenderSideCard(rightCard, 200, 340, 500, -60, 5, time)
    RenderCenterCard(time)
    RenderParticles(time)
    local titleAlpha = Clamp(time / FADE_DURATION, 0, 1)
    if time > DISPLAY_DURATION then titleAlpha = 1 - Clamp((time - DISPLAY_DURATION) / FADE_DURATION, 0, 1) end
    title:SetAlpha(titleAlpha * TITLE_ALPHA)
end
local function OnUpdate(_, delta)
    local config = Config()
    if not config or (not config.enabled and not previewing) then Loot.Stop(); return end
    elapsed = elapsed + delta * (config.speed or 1)
    if elapsed >= TOTAL_DURATION then Loot.Stop(); return end
    Render(elapsed)
end

function Loot.UpdateSettings()
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

function Loot.ToggleDragMode()
    local config = Config()
    if not config or not config.enabled then return false end
    if dragFrame:IsShown() then
        dragFrame:StopMovingOrSizing()
        dragFrame:Hide()
        dragFrame:EnableMouse(false)
        return false
    end
    Loot.UpdateSettings()
    dragFrame:SetScale(config.scale or 1)
    dragFrame:ClearAllPoints()
    dragFrame:SetPoint("CENTER", UIParent, "CENTER", config.posX or 0, config.posY or 200)
    dragFrame:Show()
    dragFrame:EnableMouse(true)
    return true
end

function Loot.IsDragging() return dragFrame:IsShown() end
function Loot.Stop()
    elapsed, previewing, currentTexture = 0, false, nil
    frame:SetScript("OnUpdate", nil)
    dragFrame:StopMovingOrSizing()
    dragFrame:Hide()
    dragFrame:EnableMouse(false)
    SetShown(false)
    frame:Hide()
end

local function RandomPreviewItemName()
    local chosen, count
    for itemName in pairs(assets.cards) do
        count = (count or 0) + 1
        if math.random(count) == 1 then chosen = itemName end
    end
    return chosen
end

function Loot.Play(itemName, preview)
    local config = Config()
    if not config or (not config.enabled and not preview) then return false end
    if not preview and not IsRaidInstance() then return false end
    if preview then itemName = RandomPreviewItemName() end
    local texture = assets.cards[itemName]
    if not texture then return false end
    Loot.Stop()
    currentTexture = Addon:ResolveCardFrontTexture(texture)
    previewing = preview and true or false
    Loot.UpdateSettings()
    Render(0)
    SetShown(true)
    frame:Show()
    if config.soundEnabled ~= false then
        PlaySoundFile(assets.throwknifeSound, "Master")
        PlaySoundFile(assets.fanfareSound, "Master")
    end
    frame:SetScript("OnUpdate", OnUpdate)
    return true
end

local events, recent = CreateFrame("Frame"), {}
local function HandleMessage(message)
    if type(message) ~= "string" or not IsRaidInstance() then return end
    for itemName in pairs(assets.cards) do
        if message:find(itemName, 1, true) then
            local now = GetTime()
            if not recent[itemName] or now - recent[itemName] > 1 then
                recent[itemName] = now
                C_Timer.After(0.6, function()
                    if Config() and Config().enabled and IsRaidInstance() then Loot.Play(itemName) end
                end)
            end
            return
        end
    end
end
events:SetScript("OnEvent", function(_, _, message) HandleMessage(message) end)
function Loot.SetEnabled(enabled)
    local config = Config()
    if not config then return end
    config.enabled = enabled and true or false
    events:UnregisterAllEvents()
    if not config.enabled then Loot.Stop(); return end
    events:RegisterEvent("CHAT_MSG_LOOT")
    events:RegisterEvent("CHAT_MSG_RAID")
    events:RegisterEvent("CHAT_MSG_RAID_LEADER")
    Loot.UpdateSettings()
end
function Loot.ResetToDefault()
    Loot.Stop()
    local config = Config()
    for key, value in pairs(Addon.defaults.modules.loot) do
        if key ~= "enabled" then config[key] = value end
    end
    Loot.UpdateSettings()
end
function Addon:InitLootModule()
    self.Loot.UpdateSettings()
    self.Loot.SetEnabled(self.db.modules.loot.enabled)
end
