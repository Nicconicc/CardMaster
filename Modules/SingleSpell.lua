local _, Addon = ...
local soundHandle
Addon.SingleSpell = {}

local RAW_SIZE = 512
local CARD_SOUND_PATH = "Interface\\AddOns\\CardMaster\\Audio\\card sound.ogg"

local START_DURATION = 0.3
local FINISH_DURATION = 0.3

-- 全局卡牌生成计数器（用于严格循环 0~4 索引，解决第7张卡牌重叠问题）
local globalCardCount = 0

-------------------------------------------------------------------------------
-- 1. 卡牌对象池与 Drag 专用的主锚点 Frame
-------------------------------------------------------------------------------
local cardPool = {}
local isDragging = false

local dragAnchorFrame = CreateFrame("Frame", "CardMasterSingleSpellAnchor", UIParent)
dragAnchorFrame:SetSize(RAW_SIZE, RAW_SIZE)
dragAnchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
dragAnchorFrame:SetFrameStrata("HIGH")
dragAnchorFrame:SetAlpha(0)
dragAnchorFrame:SetMovable(true)
dragAnchorFrame:EnableMouse(false)
dragAnchorFrame:RegisterForDrag("LeftButton")

dragAnchorFrame:SetScript("OnDragStart", dragAnchorFrame.StartMoving)
dragAnchorFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if cx and ux and Addon.legacyDB then
        Addon.legacyDB.posX = math.floor(cx - ux + 0.5)
        Addon.legacyDB.posY = math.floor(cy - uy + 0.5)
    end
end)

local dragTexture = dragAnchorFrame:CreateTexture(nil, "ARTWORK")
dragTexture:SetAllPoints(dragAnchorFrame)

local dragOverlay = Addon:CreateMoveCanvas(dragAnchorFrame, "singleSpell")
dragOverlay:Hide()

-------------------------------------------------------------------------------
-- 2. 单张卡牌 Frame 的创建与 OnUpdate 动画逻辑
-------------------------------------------------------------------------------
local function SetCardTexture(f, tex)
    f.texture:SetTexture(tex)
    f.texture:SetTexCoord(0, 1, 0, 1)
end

local function OnCardUpdate(self, elapsed)
    if not self.isAnimating then return end

    self.animTime = self.animTime + elapsed

    local db = Addon.legacyDB or {}
    local mainDuration = db.mainDuration or 0.5
    local slideX = db.slideX or -150
    local slideY = db.slideY or 50
    local slideOutX = db.slideOutX or 300
    local slideOutY = db.slideOutY or -50
    local zoomW = db.zoomW or 1.5
    local zoomH = db.zoomH or 1.5
    local rotateAngle = db.rotateAngle or 0
    local zoomType = db.zoomType or 1

    local totalDuration = START_DURATION + mainDuration + FINISH_DURATION
    local finishStart = START_DURATION + mainDuration

    if self.animTime >= totalDuration then
        self.isAnimating = false
        self.triggerSpellName = nil
        self:SetAlpha(0)
        self:Hide()
        return
    end

    local alpha = 1
    local xOffset, yOffset, rotation = 0, 0, 0
    local xScale, yScale = 1.0, 1.0

    if self.animTime < START_DURATION then
        local progress = self.animTime / START_DURATION

        xOffset = slideX * (1 - progress)
        yOffset = slideY * (1 - progress)

        local zoomFactor = math.sin(progress * math.pi)
        local curZoomW = 1.0 + (zoomW - 1.0) * zoomFactor
        local curZoomH = 1.0 + (zoomH - 1.0) * zoomFactor

        rotation = rotateAngle * progress

        if zoomType == 1 then
            local flipAngle = (1 - progress) * math.pi
            xScale = curZoomW * math.abs(math.cos(flipAngle))
            yScale = curZoomH

            if flipAngle > (math.pi / 2) then
                SetCardTexture(self, Addon:GetCardBackTexture())
            else
                SetCardTexture(self, self.frontTexture)
            end
        else
            xScale = curZoomW
            yScale = curZoomH
            SetCardTexture(self, self.frontTexture)
        end

    elseif self.animTime < finishStart then
        xOffset = 0
        yOffset = 0
        xScale = 1.0
        yScale = 1.0
        rotation = rotateAngle
        SetCardTexture(self, self.frontTexture)

    else
        local progress = (self.animTime - finishStart) / FINISH_DURATION
        xOffset = slideOutX * progress
        yOffset = slideOutY * progress
        rotation = rotateAngle * (1 - progress)

        if zoomType == 1 then
            local flipAngle = progress * math.pi
            xScale = (1.0 - 0.5 * progress) * math.abs(math.cos(flipAngle))
            yScale = 1.0 - 0.5 * progress
            
            if flipAngle > (math.pi / 2) then
                SetCardTexture(self, Addon:GetCardBackTexture())
            else
                SetCardTexture(self, self.frontTexture)
            end
        else
            xScale = 1.0 - 0.5 * progress
            yScale = 1.0 - 0.5 * progress
            SetCardTexture(self, self.frontTexture)
        end
    end

    if xScale < 0.01 then xScale = 0.01 end
    if yScale < 0.01 then yScale = 0.01 end

    local currentScale = db.scale or 0.7
    local posX = (db.posX or 0) + (self.stackOffsetX or 0)
    local posY = (db.posY or 200) + (self.stackOffsetY or 0)
    local baseSize = RAW_SIZE * currentScale

    local finalRotation = rotation + (self.stackRotation or 0)

    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", posX + xOffset, posY + yOffset)
    self:SetAlpha(alpha)
    self:SetSize(baseSize * xScale, baseSize * yScale)
    self.texture:SetRotation(math.rad(finalRotation))
end

local function CreateNewCardFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(RAW_SIZE, RAW_SIZE)
    f:SetFrameStrata("HIGH")
    f:SetAlpha(0)
    f:EnableMouse(false)

    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(f)
    f.texture = tex

    f.animTime = 0
    f.isAnimating = false
    f.frontTexture = nil
    f.triggerSpellName = nil
    f.stackOffsetX = 0
    f.stackOffsetY = 0
    f.stackRotation = 0

    f:SetScript("OnUpdate", OnCardUpdate)
    table.insert(cardPool, f)
    return f
end

local function GetAvailableCardFrame()
    for _, f in ipairs(cardPool) do
        if not f.isAnimating then
            return f
        end
    end
    return CreateNewCardFrame()
end

-------------------------------------------------------------------------------
-- 3. 开放接口
-------------------------------------------------------------------------------
function Addon.SingleSpell.UpdateDragSize()
    if isDragging then
        local baseSize = RAW_SIZE * ((Addon.legacyDB and Addon.legacyDB.scale) or 0.7)
        local rotateAngle = (Addon.legacyDB and Addon.legacyDB.rotateAngle) or 0
        dragAnchorFrame:SetSize(baseSize, baseSize)
        dragTexture:SetRotation(math.rad(rotateAngle))
    end
end

function Addon.SingleSpell.TriggerAnimation(spellName)
    if not Addon:IsIntegratedEnabled("singleSpell") then return end

    if isDragging then
        isDragging = false
        dragOverlay:Hide()
        dragAnchorFrame:SetAlpha(0)
        dragAnchorFrame:EnableMouse(false)
    end

    local targetTexture = nil

    if spellName then
        if Addon.Spells then
            targetTexture = Addon.Spells.GetTextureForSpell(spellName)
        end
    else
        if Addon.Spells and Addon.Spells.GetRandomTexture then
            targetTexture = Addon.Spells.GetRandomTexture()
        end
    end

    if targetTexture and targetTexture ~= Addon.Spells.DEFAULT_TEXTURE then
        -- 同一个法术的一次施放可能在团队战斗中伴随多条相关战斗事件。
        -- 卡牌仍在播放时不重复创建同名法术；不同法术不共享冷却，可连续出现。
        if spellName then
            for _, activeCard in ipairs(cardPool) do
                if activeCard.isAnimating and activeCard.triggerSpellName == spellName then
                    return
                end
            end
        end

        -- 寻找当前在场卡牌中最高 FrameLevel，确保新卡牌始终盖在最上层
        local maxLevel = 10
        for _, card in ipairs(cardPool) do
            if card.isAnimating then
                local lvl = card:GetFrameLevel()
                if lvl > maxLevel then
                    maxLevel = lvl
                end
            end
        end

        -- 严格递增全局卡牌数，并计算当前卡牌在 0~4 环形队列中的精准位置
        local stackIndex = globalCardCount % 5
        globalCardCount = globalCardCount + 1

        local card = GetAvailableCardFrame()
        card.frontTexture = targetTexture
        card.triggerSpellName = spellName
        card.animTime = 0
        card.isAnimating = true
        
        local db = Addon.legacyDB or {}
        if db.stackType == 2 then
            -- 每张卡牌只在生成时随机一次，动画过程中保持稳定。
            local randomOffsetX = math.max(0, math.floor(tonumber(db.randomOffsetX) or 200))
            local randomOffsetY = math.max(0, math.floor(tonumber(db.randomOffsetY) or 50))
            local randomRotation = math.max(0, math.floor(tonumber(db.randomRotation) or 20))
            card.stackOffsetX = math.random(-randomOffsetX, randomOffsetX)
            card.stackOffsetY = math.random(-randomOffsetY, randomOffsetY)
            card.stackRotation = math.random(-randomRotation, randomRotation)
        else
            -- 保留每 5 张循环：X 偏移 0/-50/-100/-150/-200，旋转 0/5/10/15/20 度。
            card.stackOffsetX = -50 * stackIndex
            card.stackOffsetY = 0
            card.stackRotation = 5 * stackIndex
        end
        
        card:SetFrameLevel(maxLevel + 1)
        card:SetAlpha(1)
        OnCardUpdate(card, 0)
        card:Show()

        if not Addon.db or not Addon.db.modules.singleSpell or Addon.db.modules.singleSpell.soundEnabled ~= false then
            local _, handle = PlaySoundFile(CARD_SOUND_PATH, "Master")
            soundHandle = handle
        end
    end
end

function Addon.SingleSpell.ToggleDragMode()
    if not Addon:IsIntegratedEnabled("singleSpell") then return false end
    isDragging = not isDragging
    if isDragging then
        for _, card in ipairs(cardPool) do
            card.isAnimating = false
            card:Hide()
        end

        dragAnchorFrame:SetAlpha(1)
        dragAnchorFrame:EnableMouse(true)
        dragOverlay:Show()

        local randTex = Addon.Spells and Addon.Spells.GetRandomTexture() or "Interface\\Icons\\INV_Misc_QuestionMark"
        dragTexture:SetTexture(randTex)
        dragTexture:SetTexCoord(0, 1, 0, 1)
        
        local baseSize = RAW_SIZE * ((Addon.legacyDB and Addon.legacyDB.scale) or 0.7)
        local posX = (Addon.legacyDB and Addon.legacyDB.posX) or 0
        local posY = (Addon.legacyDB and Addon.legacyDB.posY) or 200

        dragAnchorFrame:ClearAllPoints()
        dragAnchorFrame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
        dragAnchorFrame:SetSize(baseSize, baseSize)
        dragTexture:SetRotation(math.rad((Addon.legacyDB and Addon.legacyDB.rotateAngle) or 0))
    else
        dragOverlay:Hide()
        dragAnchorFrame:SetAlpha(0)
        dragAnchorFrame:EnableMouse(false)
    end
    return isDragging
end

function Addon.SingleSpell.ResetToDefault()
    if isDragging then
        isDragging = false
        dragOverlay:Hide()
        dragAnchorFrame:EnableMouse(false)
        dragAnchorFrame:SetAlpha(0)
    end
    dragAnchorFrame:ClearAllPoints()
    dragAnchorFrame:SetPoint("CENTER", UIParent, "CENTER", Addon.IntegratedDefaults.DEFAULT_SKILL.posX, Addon.IntegratedDefaults.DEFAULT_SKILL.posY)
end

-------------------------------------------------------------------------------
-- 4. 事件监听
-------------------------------------------------------------------------------
local eventHandler = CreateFrame("Frame")

-- UNIT_AURA 是战斗记录之外的补充触发器。它只检测玩家身上“新获得”的增益，
-- 因此诸如猎人“假死”这类不会稳定写入战斗记录的技能也能正确出牌；不会把
-- 目标身上的减益、持续伤害跳数或既有光环的刷新误判为一次施法。
local activePlayerBuffs = {}

local function IsMappedPlayerSpell(spellName)
    if not spellName or not Addon.Spells or not Addon.Spells.GetTextureForSpell then
        return false
    end
    return Addon.Spells.GetTextureForSpell(spellName) ~= Addon.Spells.DEFAULT_TEXTURE
end

local function RecordPlayerBuff(currentBuffs, auraKey, spellName, spellID, triggerNewBuffs)
    if not spellName then return end
    auraKey = auraKey or spellID or spellName
    currentBuffs[auraKey] = true

    if triggerNewBuffs and not activePlayerBuffs[auraKey] and IsMappedPlayerSpell(spellName) then
        Addon.SingleSpell.TriggerAnimation(spellName)
    end
end

local function RefreshPlayerBuffs(triggerNewBuffs)
    local currentBuffs = {}

    if UnitBuff then
        -- 经典客户端仍使用旧接口；第十个返回值是法术 ID。
        for index = 1, 40 do
            local spellName, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", index)
            if not spellName then break end
            RecordPlayerBuff(currentBuffs, spellID, spellName, spellID, triggerNewBuffs)
        end
    end

    activePlayerBuffs = currentBuffs
end

function Addon.SingleSpell.Stop()
    for _, card in ipairs(cardPool) do
        card.isAnimating = false
        card.triggerSpellName = nil
        card:SetAlpha(0)
        card:Hide()
    end
    isDragging = false
    dragAnchorFrame:StopMovingOrSizing()
    dragOverlay:Hide()
    dragAnchorFrame:SetAlpha(0)
    dragAnchorFrame:EnableMouse(false)
    if soundHandle then StopSound(soundHandle); soundHandle = nil end
    globalCardCount = 0
    activePlayerBuffs = {}
end

function Addon.SingleSpell.IsDragging() return isDragging end

function Addon.SingleSpell.SetEnabled(enabled)
    eventHandler:UnregisterAllEvents()
    if enabled then
        -- 正式服和无限服使用安全的玩家施法事件；经典服使用玩家来源的战斗记录。
        -- UNIT_SPELLCAST_SUCCEEDED 能覆盖假死等玩家施法；现代客户端的
        -- 光环数据在战斗中可能是秘密值，绝不能枚举。经典服保留光环补充判断。
        if Addon:IsRetail() then
            eventHandler:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        else
            eventHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
            eventHandler:RegisterEvent("UNIT_AURA")
            -- 启用模块时只建立当前状态，不为登录前已有的增益补发卡牌。
            RefreshPlayerBuffs(false)
        end
    else
        Addon.SingleSpell.Stop()
    end
end

eventHandler:SetScript("OnEvent", function(self, event, ...)
    if not Addon:IsIntegratedEnabled("singleSpell") then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" and spellID then
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            local spellName = info and info.name
            if not spellName and GetSpellInfo then spellName = GetSpellInfo(spellID) end
            if spellName then Addon.SingleSpell.TriggerAnimation(spellName) end
        end
    elseif event == "UNIT_AURA" and not Addon:IsRetail() then
        local unit = ...
        if unit == "player" then
            RefreshPlayerBuffs(true)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, sourceGUID = CombatLogGetCurrentEventInfo()
        -- 仅玩家自己的“法术 / 施法成功”触发。SPELL_DAMAGE、SPELL_MISSED
        -- 会包含流血、毒药等持续效果的每一跳，绝不能用于发牌。
        if subevent == "SPELL_CAST_SUCCESS" and sourceGUID == UnitGUID("player") then
            local _, spellName = select(12, CombatLogGetCurrentEventInfo())
            if spellName then Addon.SingleSpell.TriggerAnimation(spellName) end
        end
    end
end)
