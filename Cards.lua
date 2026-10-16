local _, Addon = ...

local BASE_WIDTH, BASE_HEIGHT = 260, 360
local GOLD = { 0.95, 0.68, 0.18 }
local MODULE_ICONS = {
    singleSpell = "Interface\\Icons\\Spell_Frost_FrostBolt02",
    inCombat = "Interface\\Icons\\Ability_Warrior_InnerRage",
    afk = "Interface\\Icons\\Spell_Nature_Sleep",
    boss = "Interface\\Icons\\Achievement_Boss_LichKing",
    loot = "Interface\\Icons\\INV_Misc_EngGizmos_17",
    levelUp = "Interface\\Icons\\Achievement_Level_80",
}
local TITLE_KEYS = {
    singleSpell = "singleTitle",
    inCombat = "combatTitle",
    afk = "afkTitle",
    boss = "bossTitle",
    loot = "lootTitle",
    levelUp = "levelTitle",
}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function lerp(startValue, endValue, progress)
    return startValue + (endValue - startValue) * progress
end

local function easeOut(progress)
    return 1 - (1 - progress) * (1 - progress) * (1 - progress)
end

local function addBackdrop(frame, edgeSize)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 16,
        edgeSize = edgeSize or 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
end

function Addon:CreateOneCard(moduleKey)
    local frame = CreateFrame("Frame", "CardMasterCard_" .. moduleKey, UIParent, "BackdropTemplate")
    frame:SetSize(BASE_WIDTH, BASE_HEIGHT)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:Hide()
    addBackdrop(frame, 28)

    frame.front = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.front:SetPoint("TOPLEFT", 8, -8)
    frame.front:SetPoint("BOTTOMRIGHT", -8, 8)
    frame.front:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })

    frame.frontGlow = frame.front:CreateTexture(nil, "BACKGROUND")
    frame.frontGlow:SetPoint("TOPLEFT", 2, -2)
    frame.frontGlow:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.frontGlow:SetTexture("Interface\\Buttons\\WHITE8X8")

    frame.iconBorder = CreateFrame("Frame", nil, frame.front, "BackdropTemplate")
    frame.iconBorder:SetSize(174, 174)
    frame.iconBorder:SetPoint("TOP", 0, -38)
    addBackdrop(frame.iconBorder, 22)
    frame.iconBorder:SetBackdropColor(0.02, 0.02, 0.02, 1)
    frame.iconBorder:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)

    frame.icon = frame.iconBorder:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 10, -10)
    frame.icon:SetPoint("BOTTOMRIGHT", -10, 10)
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    frame.title = frame.front:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", frame.iconBorder, "BOTTOM", 0, -24)
    frame.title:SetWidth(220)
    frame.title:SetTextColor(1, 0.78, 0.28)

    frame.subtitle = frame.front:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.subtitle:SetPoint("TOP", frame.title, "BOTTOM", 0, -12)
    frame.subtitle:SetWidth(210)
    frame.subtitle:SetJustifyH("CENTER")
    frame.subtitle:SetTextColor(0.9, 0.9, 0.86)

    frame.brand = frame.front:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.brand:SetPoint("BOTTOM", 0, 18)
    frame.brand:SetText("MANGUI • CARD MASTER")
    frame.brand:SetTextColor(0.72, 0.57, 0.27)

    frame.back = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.back:SetPoint("TOPLEFT", 8, -8)
    frame.back:SetPoint("BOTTOMRIGHT", -8, 8)
    frame.back:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    frame.backArt = frame.back:CreateTexture(nil, "ARTWORK")
    frame.backArt:SetAllPoints(frame.back)

    frame.backInner = CreateFrame("Frame", nil, frame.back, "BackdropTemplate")
    frame.backInner:SetPoint("TOPLEFT", 16, -16)
    frame.backInner:SetPoint("BOTTOMRIGHT", -16, 16)
    frame.backInner:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })

    frame.backRune = frame.backInner:CreateFontString(nil, "OVERLAY", "QuestFont_Enormous")
    frame.backRune:SetPoint("CENTER", 0, 12)
    frame.backRune:SetText("M")
    frame.backRune:SetTextColor(1, 0.74, 0.2)

    frame.backBrand = frame.backInner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.backBrand:SetPoint("CENTER", 0, -56)
    frame.backBrand:SetText("MANGUI")
    frame.backBrand:SetTextColor(0.9, 0.64, 0.2)

    frame.moduleKey = moduleKey
    frame:SetScript("OnUpdate", function(card, elapsed)
        Addon:UpdateCardAnimation(card, elapsed)
    end)
    self.cards[moduleKey] = frame
end

function Addon:CreateCardFrames()
    self.cards = {}
    self.anchors = {}
    self.cardQueue = {}
    self.activeCard = nil
    for _, moduleKey in ipairs({ "singleSpell", "inCombat", "loot" }) do
        self:CreateOneCard(moduleKey)
    end
    self:RefreshCardStyles()
end

function Addon:PlayNextQueuedCard()
    if self.activeCard and self.activeCard:IsShown() then return end
    local nextCard = table.remove(self.cardQueue, 1)
    if nextCard then
        self:ShowCard(nextCard.moduleKey, nextCard.payload, nextCard.force)
    end
end

function Addon:ApplyCardStyle(card)
    local frontStyle = self.db.cardStyles.front

    if frontStyle == 1 then
        card:SetBackdropColor(0.025, 0.025, 0.025, 0.98)
        card:SetBackdropBorderColor(1, 0.72, 0.2, 1)
        card.front:SetBackdropColor(0.07, 0.055, 0.035, 1)
        card.frontGlow:SetVertexColor(0.25, 0.16, 0.03, 0.34)
        card.icon:SetDesaturated(false)
    else
        card:SetBackdropColor(0.01, 0.01, 0.012, 1)
        card:SetBackdropBorderColor(0.58, 0.48, 0.28, 1)
        card.front:SetBackdropColor(0.018, 0.018, 0.022, 1)
        card.frontGlow:SetVertexColor(0.12, 0.12, 0.13, 0.48)
        card.icon:SetDesaturated(true)
    end

    card.back:SetBackdropColor(0, 0, 0, 0)
    card.backInner:Hide()
    card.backArt:SetTexture(self:GetCardBackTexture())
end

function Addon:RefreshCardStyles()
    if self.cards then
        for _, card in pairs(self.cards) do
            self:ApplyCardStyle(card)
        end
    end
    -- The AFK animation uses independent fullscreen card frames instead of
    -- the regular card pool, so it needs its own live style refresh.
    if self.AFK and self.AFK.RefreshCardTextures then
        self.AFK.RefreshCardTextures()
    end
end

function Addon:SetCardFace(card, showFront)
    card.front:SetShown(showFront)
    card.back:SetShown(not showFront)
end

function Addon:ShowCard(moduleKey, payload, force)
    if moduleKey == "boss" then
        return self.Boss.Play(payload and payload.subtitle, force)
    end
    if moduleKey == "afk" then
        self.AFK.RefreshState()
        return
    end
    if moduleKey == "levelUp" then
        return self.LevelUp.Play(payload and payload.subtitle, force)
    end
    if moduleKey == "singleSpell" then
        self.SingleSpell.TriggerAnimation(payload and payload.subtitle)
        return
    elseif moduleKey == "inCombat" then
        self.CombatIn.Play()
        return
    end
    local config = self.db.modules[moduleKey]
    local card = self.cards and self.cards[moduleKey]
    if not config or not card or (not force and not config.enabled) then
        self:PlayNextQueuedCard()
        return
    end
    if self.activeCard and self.activeCard:IsShown() and self.activeCard ~= card then
        table.insert(self.cardQueue, { moduleKey = moduleKey, payload = payload, force = force })
        return
    end

    payload = payload or {}
    card.title:SetText(payload.title or self:T(TITLE_KEYS[moduleKey]))
    card.subtitle:SetText(payload.subtitle or "")
    card.icon:SetTexture(payload.icon or MODULE_ICONS[moduleKey])
    card.elapsed = 0
    card.config = config
    card.inTime = 0.55
    card.holdTime = moduleKey == "singleSpell" and config.duration or 1.2
    card.outTime = 0.55
    if moduleKey == "inCombat" then
        local speed = clamp(config.animSpeed or 1, 0.5, 2)
        card.inTime = card.inTime / speed
        card.outTime = card.outTime / speed
    end
    self:ApplyCardStyle(card)
    card:SetAlpha(1)
    card:SetScale(config.scale or 1)
    self.activeCard = card
    card:Show()
end

function Addon:UpdateCardAnimation(card, elapsed)
    if not card.elapsed then return end
    card.elapsed = card.elapsed + elapsed
    local config = card.config
    local moduleKey = card.moduleKey
    local baseX, baseY = config.posX or 0, config.posY or 0
    local scale = config.scale or 1
    local inX = moduleKey == "singleSpell" and (config.inSlideX or 0) or -180
    local inY = moduleKey == "singleSpell" and (config.inSlideY or 0) or 35
    local outX = moduleKey == "singleSpell" and (config.outSlideX or 0) or 180
    local outY = moduleKey == "singleSpell" and (config.outSlideY or 0) or 20
    local inType = moduleKey == "singleSpell" and config.inZoomType or 1
    local outType = moduleKey == "singleSpell" and config.outZoomType or 1
    local widthFactor, heightFactor, x, y, alpha, rotation = 1, 1, baseX, baseY, 1, 0

    if card.elapsed < card.inTime then
        local progress = clamp(card.elapsed / card.inTime, 0, 1)
        local eased = easeOut(progress)
        x = baseX + lerp(inX, 0, eased)
        y = baseY + lerp(inY, 0, eased)
        local peakW = moduleKey == "singleSpell" and (config.inZoomW or 1) or 1.15
        local peakH = moduleKey == "singleSpell" and (config.inZoomH or 1) or 1.15
        if progress < 0.72 then
            widthFactor = lerp(0.32, peakW, easeOut(progress / 0.72))
            heightFactor = lerp(0.32, peakH, easeOut(progress / 0.72))
        else
            widthFactor = lerp(peakW, 1, (progress - 0.72) / 0.28)
            heightFactor = lerp(peakH, 1, (progress - 0.72) / 0.28)
        end
        alpha = clamp(progress * 3, 0, 1)
        rotation = math.rad(lerp(moduleKey == "singleSpell" and (config.inRotateAngle or 0) or -18, 0, eased))
        if inType == 1 then
            local flip = math.abs(math.cos(progress * math.pi))
            widthFactor = widthFactor * math.max(0.06, flip)
            self:SetCardFace(card, progress >= 0.5)
        else
            self:SetCardFace(card, true)
        end
    elseif card.elapsed < card.inTime + card.holdTime then
        self:SetCardFace(card, true)
    elseif card.elapsed < card.inTime + card.holdTime + card.outTime then
        local progress = clamp((card.elapsed - card.inTime - card.holdTime) / card.outTime, 0, 1)
        local eased = progress * progress
        x = baseX + lerp(0, outX, eased)
        y = baseY + lerp(0, outY, eased)
        local endScale = moduleKey == "singleSpell" and (config.outZoomScale or 0.5) or 0.7
        widthFactor = lerp(1, endScale, eased)
        heightFactor = lerp(1, endScale, eased)
        alpha = 1 - progress
        rotation = math.rad(lerp(0, moduleKey == "singleSpell" and (config.outRotateAngle or 0) or 16, eased))
        if outType == 1 then
            local flip = math.abs(math.cos(progress * math.pi / 2))
            widthFactor = widthFactor * math.max(0.04, flip)
            self:SetCardFace(card, progress < 0.55)
        else
            self:SetCardFace(card, true)
        end
    else
        card.elapsed = nil
        card:Hide()
        card:SetSize(BASE_WIDTH, BASE_HEIGHT)
        card:SetScale(1)
        card:SetAlpha(1)
        if self.activeCard == card then self.activeCard = nil end
        C_Timer.After(0.08, function() Addon:PlayNextQueuedCard() end)
        return
    end

    card:ClearAllPoints()
    card:SetPoint("CENTER", UIParent, "CENTER", x, y)
    card:SetScale(scale)
    card:SetSize(math.max(4, BASE_WIDTH * widthFactor), math.max(4, BASE_HEIGHT * heightFactor))
    card:SetAlpha(alpha)
    card.icon:SetRotation(rotation)
end

function Addon:CreateAnchor(moduleKey)
    local config = self.db.modules[moduleKey]
    local anchor = CreateFrame("Frame", "CardMasterAnchor_" .. moduleKey, UIParent, "BackdropTemplate")
    anchor:SetSize(220, 70)
    anchor:SetPoint("CENTER", UIParent, "CENTER", config.posX or 0, config.posY or 0)
    anchor:SetFrameStrata("DIALOG")
    local canvas = self:CreateMoveCanvas(anchor, moduleKey)
    anchor:EnableMouse(true)
    anchor:SetMovable(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetClampedToScreen(true)

    anchor.title = canvas.title
    anchor.hint = anchor:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    anchor.hint:SetPoint("CENTER", 0, -12)
    anchor.hint:SetText(self:T("dragHint"))
    anchor.hint:SetWidth(200)
    anchor.hint:Hide()

    anchor:SetScript("OnDragStart", anchor.StartMoving)
    anchor:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local centerX, centerY = frame:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        if centerX and parentX then
            config.posX = math.floor(centerX - parentX + 0.5)
            config.posY = math.floor(centerY - parentY + 0.5)
        end
    end)
    self.anchors[moduleKey] = anchor
    return anchor
end

function Addon:ToggleAnchor(moduleKey)
    local anchor = self.anchors[moduleKey]
    if anchor then
        if anchor:IsShown() then
            anchor:Hide()
        else
            local config = self.db.modules[moduleKey]
            anchor:ClearAllPoints()
            anchor:SetPoint("CENTER", UIParent, "CENTER", config.posX or 0, config.posY or 0)
            anchor:Show()
        end
    else
        self:CreateAnchor(moduleKey)
    end
end
