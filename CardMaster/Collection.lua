local _, Addon = ...
local chances = { 15, 50, 15, 15, 100, 100 }
local categories = {
    WARRIOR = {"战士", "Warrior"}, PALADIN = {"圣骑士", "Paladin"}, HUNTER = {"猎人", "Hunter"},
    ROGUE = {"潜行者", "Rogue"}, PRIEST = {"牧师", "Priest"}, SHAMAN = {"萨满祭司", "Shaman"},
    MAGE = {"法师", "Mage"}, WARLOCK = {"术士", "Warlock"}, DRUID = {"德鲁伊", "Druid"},
    DEATHKNIGHT = {"死亡骑士", "Death Knight"}, MONK = {"武僧", "Monk"},
    DEMONHUNTER = {"恶魔猎手", "Demon Hunter"}, EVOKER = {"唤魔师", "Evoker"},
    BOSS = {"首领", "Boss"}, LOOT = {"史诗", "Legendry"}, RACE = {"种族技能和御龙术", "Racial abilities & Dragonriding"},
}
Addon.CollectionCategories = categories

function Addon:CollectionChinese()
    local locale = GetLocale and GetLocale() or "enUS"
    return locale == "zhCN" or locale == "zhTW"
end

function Addon:CollectionText(zh, en)
    return self:CollectionChinese() and zh or en
end

function Addon:CollectionPrint(message, reward)
    if DEFAULT_CHAT_FRAME then
        local prefix = reward and ("|TInterface\\AddOns\\CardMaster\\Textures\\Assets\\CMLogo.png:20:20:0:0|t |cffffd100" .. self:CollectionText("卡牌大师", "CardMaster") .. "|r ")
            or "|cffffd100【" .. self:CollectionText("卡牌大师", "CardMaster") .. "】|r"
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. message)
    end
end

function Addon:GetCollectionCategoryName(token)
    local names = categories[token]
    return names and self:CollectionText(names[1], names[2]) or tostring(token)
end

function Addon:GetCollectionSettingsSchema()
    local settings = {}
    for _, style in ipairs(self:GetCardFrontStyles()) do
        local selected = {}
        for token in pairs((self:GetCardCollectionCatalog(style.id) or {}).classes or {}) do selected[token] = true end
        settings[style.id] = { enabled = true, categories = selected }
    end
    return settings
end

function Addon:RefreshCollectionSettings()
    local schema = self:GetCollectionSettingsSchema()
    self.defaults.collectionSettings = schema
    if type(self.db.collectionSettings) ~= "table" then self.db.collectionSettings = {} end
    for id, default in pairs(schema) do
        local settings = self.db.collectionSettings[id]
        if type(settings) ~= "table" then settings = {}; self.db.collectionSettings[id] = settings end
        if type(settings.enabled) ~= "boolean" then settings.enabled = true end
        if type(settings.categories) ~= "table" then settings.categories = {} end
        for token in pairs(default.categories) do
            if type(settings.categories[token]) ~= "boolean" then settings.categories[token] = true end
        end
    end
    self.collectionPool = nil
    if self.OnCollectionChanged then self:OnCollectionChanged() end
end

function Addon:GetCollectionSettings(id)
    local settings = self.db.collectionSettings and self.db.collectionSettings[id]
    if not settings then self:RefreshCollectionSettings(); settings = self.db.collectionSettings[id] end
    return settings or {enabled = false, categories = {}}
end

function Addon:SetCollectionEnabled(id, value)
    self:GetCollectionSettings(id).enabled = value and true or false
    self.collectionPool = nil
    if self.OnCollectionChanged then self:OnCollectionChanged() end
end

function Addon:SetCollectionCategory(id, token, value)
    self:GetCollectionSettings(id).categories[token] = value and true or false
    self.collectionPool = nil
    if self.OnCollectionChanged then self:OnCollectionChanged() end
end

function Addon:OwnsCollectionCard(id)
    local db = self.collectionDB
    local record = id and db and db.cards and db.cards[id]
    return type(record) == "table" and type(record.at) == "number" and record.at > 0
        and type(record.source) == "number" and chances[record.source] ~= nil
        and self.collectionStatus ~= "mismatch"
end

function Addon:GetCollectionClassProgress(id, category)
    local have, total = 0, 0
    for _, entry in ipairs(self:GetCardCollectionEntries(id)[category] or {}) do
        if entry.id then
            total = total + 1
            if self:OwnsCollectionCard(entry.id) then have = have + 1 end
        end
    end
    return have, total
end

function Addon:GetCollectionPool()
    if self.collectionPool then return self.collectionPool end
    local pool = {}
    for _, style in ipairs(self:GetCardFrontStyles()) do
        local settings = self:GetCollectionSettings(style.id)
        if settings.enabled then
            for token, entries in pairs(self:GetCardCollectionEntries(style.id)) do
                if settings.categories[token] then
                    for _, entry in ipairs(entries) do
                        if entry.id and not self:OwnsCollectionCard(entry.id) then pool[#pool + 1] = entry end
                    end
                end
            end
        end
    end
    self.collectionPool = pool
    return pool
end

function Addon:GetCollectionStatusText()
    local status = self.collectionStatus
    if status == "ready" then
        return #self:GetCollectionPool() == 0 and self:CollectionText("当前没有可收集卡牌", "No cards available in selected categories") or ""
    elseif status == "mismatch" then
        return self:CollectionText("收藏存档与当前战网账号不匹配。原数据已保留，收藏暂停。", "Collection belongs to another BattleTag. Original data preserved; collection paused.")
    elseif status == "storage" then
        return self:CollectionText("收藏存档模块未加载，请启用 CardMasterCollection 并重载。", "Enable CardMasterCollection and reload to collect cards.")
    elseif status == "damaged" then
        return self:CollectionText("收藏存档版本或格式异常，数据已保留，请先备份。", "Collection save has an unsupported version or format. Data preserved; back it up before recovery.")
    end
    return self:CollectionText("正在等待战网身份信息，收藏暂未开始。", "Waiting for BattleTag; collection has not started yet.")
end

function Addon:CheckCollectionIdentity()
    if not self.collectionDB then return end
    local previous = self.collectionStatus
    local tag
    if BNGetInfo then
        local ok, _, value = pcall(BNGetInfo)
        if ok and type(value) == "string" and value:find("#", 1, true) then tag = value end
    end
    if not tag then
        self.collectionStatus = "identity"
    elseif self.collectionDB.owner and self.collectionDB.owner:lower() ~= tag:lower() then
        self.collectionStatus = "mismatch"
    else
        self.collectionDB.owner = tag
        self.collectionStatus = "ready"
    end
    if previous ~= self.collectionStatus then
        self.collectionPool = nil
        if self.OnCollectionChanged then self:OnCollectionChanged() end
        if self.collectionStatus == "mismatch" then self:CollectionPrint(self:GetCollectionStatusText()) end
    end
end

function Addon:InitCollection()
    self:RefreshCollectionSettings()
    if not CardMasterCollectionStorageReady then self.collectionStatus = "storage"; return end
    local db = CardMasterCollectionDB
    if type(db) ~= "table" or db.version ~= 1 or type(db.cards) ~= "table"
        or type(db.seen) ~= "table" or (db.owner ~= nil and type(db.owner) ~= "string") then
        self.collectionStatus = "damaged"
        return
    end
    self.collectionDB = db
    self.collectionIndex = {}
    for _, style in ipairs(self:GetCardFrontStyles()) do
        for _, entries in pairs(self:GetCardCollectionEntries(style.id)) do
            for _, entry in ipairs(entries) do
                if entry.id then self.collectionIndex[entry.id] = entry end
            end
        end
    end
    -- Unknown IDs remain as retired history. Invalid records are not counted,
    -- and are kept verbatim rather than deleting the player's save.
    local now = time()
    for key, stamp in pairs(db.seen) do
        if type(stamp) ~= "number" or stamp < now - 86400 then db.seen[key] = nil end
    end
    self:CheckCollectionIdentity()
    if self.InitCollectionEvents then self:InitCollectionEvents() end
    if self.InitCollectionSocial then self:InitCollectionSocial() end
    C_Timer.After(12, function()
        if Addon.collectionStatus ~= "ready" then Addon:CollectionPrint(Addon:GetCollectionStatusText()) end
    end)
end

-- Sources are protocol ordinals; probabilities are not imported settings.
function Addon:CollectionAttempt(source, eventKey)
    if self.collectionStatus ~= "ready" or not chances[source] then return nil end
    if type(eventKey) ~= "string" or #eventKey > 180 then return nil end
    local db, now = self.collectionDB, time()
    local key = tostring(source) .. ":" .. eventKey
    if db.seen[key] then return nil end
    db.seen[key] = now -- Also settle failed rolls, so replay cannot reroll them.
    local pool = self:GetCollectionPool()
    if #pool == 0 or math.random(100) > chances[source] then return nil end
    local index = math.random(#pool)
    local entry = pool[index]
    local last = #pool
    pool[index] = pool[last]
    pool[last] = nil
    db.cards[entry.id] = { at = now, source = source }
    local have, total = self:GetCollectionClassProgress(entry.styleID, entry.category)
    local all, maximum = self:GetCardCollectionProgress(entry.styleID)
    self.collectionNotices = self.collectionNotices or {}
    self.collectionNotices[#self.collectionNotices + 1] = { entry = entry, have = have, total = total, all = all, maximum = maximum }
    if not self.collectionNoticeTimer then
        self.collectionNoticeTimer = true
        -- Batch only awards from this frame; local feedback is safe in combat.
        C_Timer.After(0, function()
            Addon.collectionNoticeTimer = nil
            Addon:FlushCollectionNotices()
        end)
    end
    if self.OnCollectionChanged then self:OnCollectionChanged() end
    if self.ScheduleCollectionSummary then self:ScheduleCollectionSummary() end
    return entry
end
