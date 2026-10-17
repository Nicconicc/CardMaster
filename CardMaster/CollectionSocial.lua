local _, Addon = ...
local PREFIX = "CMCOL1"
local peers, lastRequest, receiveTimes = {}, {}, {}
local function safe(value)
    return not (issecretvalue and issecretvalue(value))
end
local function channel()
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end
local function send(message)
    local distribution = channel()
    if not distribution then return end
    if C_ChatInfo and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted() then return end
    local fn = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
    if fn then pcall(fn, PREFIX, message, distribution) end
end

function Addon:GetCollectionDisplayName(entry)
    if self:CollectionChinese() then return entry.name end
    local names = self.Spells and self.Spells.CardDisplayEnglish
    return (names and names[entry.category] and names[entry.category][entry.name]) or entry.name
end

function Addon:FormatCollectionNotice(notice, plain)
    local entry = notice.entry
    local name = self:GetCollectionDisplayName(entry)
    local card = "[" .. name .. "]"
    if not plain then card = "|cff71d5ff|Hcmcard:" .. entry.id .. "|h" .. card .. "|h|r" end
    return string.format(self:CollectionText(
        "获得第%d套（%s）新收藏：%s！%s收藏进度：%d/%d，总体收藏进度：%d/%d。",
        "New collection in set %d (%s): %s! %s: %d/%d; overall: %d/%d."),
        entry.styleID, self:GetCardFrontStyle(entry.styleID).nameEn, card,
        self:GetCollectionCategoryName(entry.category), notice.have, notice.total, notice.all, notice.maximum)
end

function Addon:SendCollectionEmote(text)
    if not self.db.collectionBroadcast then return end
    local sender = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    local ok, result
    if sender then ok, result = pcall(sender, "【" .. self:CollectionText("卡牌大师", "CardMaster") .. "】" .. text, "EMOTE") end
    -- Chat sending can require a hardware action on newer clients.
    if not ok or result == false or (type(result) == "number" and result ~= 0) then
        if not self.collectionSendWarning then
            self.collectionSendWarning = true
            self:CollectionPrint(self:CollectionText("当前客户端限制自动播报，本地收藏及提示正常。", "Automatic announcements are restricted; local collection is unaffected."))
        end
    end
end

function Addon:FlushCollectionNotices()
    local notices = self.collectionNotices or {}
    if #notices == 0 then return end
    self.collectionNotices = {}
    local totals = {}
    for _, notice in ipairs(notices) do
        self:CollectionPrint(self:FormatCollectionNotice(notice))
        local id = notice.entry.styleID
        totals[id] = (totals[id] or 0) + 1
    end
    if PlaySoundFile then
        local media = LibStub and LibStub("LibSharedMedia-3.0", true)
        local sound = media and media:Fetch("sound", "Xylophone", true)
        PlaySoundFile(sound or "Interface\\AddOns\\CardMaster\\Audio\\Xylophone.wav", "Master")
    end
    if #notices == 1 then self:SendCollectionEmote(self:FormatCollectionNotice(notices[1], true)); return end
    local segments = {}
    for _, style in ipairs(self:GetCardFrontStyles()) do
        if totals[style.id] then
            local have, total = self:GetCardCollectionProgress(style.id)
            segments[#segments + 1] = string.format(self:CollectionText("%s 新增%d张，进度：%d/%d", "%s +%d, progress: %d/%d"), style.nameEn, totals[style.id], have, total)
        end
    end
    local header = string.format(self:CollectionText("获得%d张新收藏！", "Collected %d new cards! "), #notices)
    -- Keep UTF-8 intact by splitting only between complete set summaries.
    local chunks, message = {}, header
    for _, segment in ipairs(segments) do
        if #message + #segment > 210 then chunks[#chunks + 1] = message; message = "" end
        message = message .. segment .. self:CollectionText("；", "; ")
    end
    if message ~= "" then chunks[#chunks + 1] = message end
    for i, chunk in ipairs(chunks) do
        local content = chunk
        C_Timer.After((i - 1) * 3, function() Addon:SendCollectionEmote(content) end)
    end
end

function Addon:ScheduleCollectionSummary()
    if self.collectionSummaryPending then return end
    self.collectionSummaryPending = true
    C_Timer.After(10, function()
        Addon.collectionSummaryPending = nil
        if Addon.collectionStatus ~= "ready" then return end
        local pieces = {"S", tostring(Addon.CardCatalogVersion)}
        for _, style in ipairs(Addon:GetCardFrontStyles()) do
            local have, total = Addon:GetCardCollectionProgress(style.id)
            pieces[#pieces + 1] = style.id .. "," .. have .. "," .. total
        end
        send(table.concat(pieces, "|"))
    end)
end

local function member(sender)
    if not safe(sender) or type(sender) ~= "string" then return false end
    for _, token in ipairs(Addon:GetCollectionGroupUnits()) do
        local name, realm = UnitFullName(token)
        if safe(name) and safe(realm) and name then
            realm = realm and realm ~= "" and realm or GetNormalizedRealmName()
            if sender == name or sender == name .. "-" .. realm then return true end
        end
    end
    return false
end

function Addon:CollectionReceive(prefix, message, distribution, sender)
    if prefix ~= PREFIX or type(message) ~= "string" or #message > 240 or not member(sender) then return end
    if distribution ~= "PARTY" and distribution ~= "RAID" and distribution ~= "INSTANCE_CHAT" then return end
    local now = GetTime()
    if receiveTimes[sender] and now - receiveTimes[sender] < 2 then return end
    receiveTimes[sender] = now
    if message == "Q" then self:ScheduleCollectionSummary(); return end
    local version, body = message:match("^S|(%d+)|(.+)$")
    if not version then return end
    local data = { at = now, version = tonumber(version), sets = {} }
    for part in body:gmatch("[^|]+") do
        local id, have, total = part:match("^(%d+),(%d+),(%d+)$")
        id, have, total = tonumber(id), tonumber(have), tonumber(total)
        if not id or not have or not total or have > total or total > 100000 or not self.CardCatalog[id] then return end
        data.sets[id] = {have, total}
    end
    peers[sender] = data
end

function Addon:CollectionTooltip(tooltip, unit)
    if not unit or not UnitIsPlayer(unit) then return end
    local name, realm = UnitFullName(unit)
    if not safe(name) or not safe(realm) or not name then return end
    realm = realm and realm ~= "" and realm or GetNormalizedRealmName()
    local peer = peers[name .. "-" .. realm] or peers[name]
    if not peer or GetTime() - peer.at > 120 then
        if channel() and (not lastRequest.group or GetTime() - lastRequest.group > 30) then lastRequest.group = GetTime(); send("Q") end
        return
    end
    tooltip:AddLine(self:CollectionText("卡牌大师收藏", "CardMaster collection"), 1, 0.82, 0)
    for _, style in ipairs(self:GetCardFrontStyles()) do
        local progress = peer.sets[style.id]
        if progress then tooltip:AddLine(string.format("%s: %d/%d (%.1f%%)", style.nameEn, progress[1], progress[2], progress[2] > 0 and progress[1] / progress[2] * 100 or 0), 1, 1, 1) end
    end
    if peer.version ~= self.CardCatalogVersion then tooltip:AddLine(self:CollectionText("卡牌目录版本不同", "Different catalogue version"), 1, 0.6, 0) end
    tooltip:Show()
end

function Addon:InitCollectionSocial()
    local register = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
    if register then pcall(register, PREFIX) end
    local function entryFor(link)
        if type(link) ~= "string" then return nil end
        local id = link:match("^cmcard:(%d+:C%d+)$")
        return id and Addon.collectionIndex and Addon.collectionIndex[id]
    end
    local function installChat(chat)
        if not chat or not chat.HookScript then return end
        -- ScrollingMessageFrame can accept clicks while hover callbacks are
        -- disabled. Explicitly opt in on clients that expose this switch.
        if chat.SetHyperlinksEnabled then chat:SetHyperlinksEnabled(true) end
        if chat.cardMasterCollectionLinks then return end
        chat.cardMasterCollectionLinks = true
        chat:HookScript("OnHyperlinkEnter", function(self, link)
            local entry = entryFor(link)
            if entry then
                self.cardMasterCollectionHoverEntry = entry
                Addon:ShowCollectionPreview(entry, UIParent)
            end
        end)
        local function leave(self)
            -- Some clients supply no link argument on OnHyperlinkLeave.
            local entry = self.cardMasterCollectionHoverEntry
            self.cardMasterCollectionHoverEntry = nil
            local preview = Addon.collectionPreview
            if entry and preview and preview.entry == entry and not preview.pinned then preview:Hide() end
        end
        chat:HookScript("OnHyperlinkLeave", leave)
        chat:HookScript("OnHide", leave)
    end
    local function install()
        for i = 1, NUM_CHAT_WINDOWS or 10 do
            installChat(_G["ChatFrame" .. i])
        end
        installChat(DEFAULT_CHAT_FRAME)
        for _, name in ipairs(CHAT_FRAMES or {}) do installChat(_G[name]) end
    end
    install()
    if FCF_OpenTemporaryWindow and hooksecurefunc then hooksecurefunc("FCF_OpenTemporaryWindow", install) end
    if FCF_OpenNewWindow and hooksecurefunc then hooksecurefunc("FCF_OpenNewWindow", install) end
    local original = SetItemRef
    if original then
        SetItemRef = function(link, ...)
            local entry = entryFor(link)
            if entry then Addon:ShowCollectionPreview(entry, UIParent, true); return end
            return original(link, ...)
        end
    end
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            local _, unit = tooltip:GetUnit(); Addon:CollectionTooltip(tooltip, unit)
        end)
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
            local _, unit = tooltip:GetUnit(); Addon:CollectionTooltip(tooltip, unit)
        end)
    end
end
