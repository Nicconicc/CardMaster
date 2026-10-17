local _, Addon = ...
local PREFIX = "CMCOL1"
local peers, lastRequest, receiveTimes = {}, {}, {}
local classColors = {
    WARRIOR="c79c6e", PALADIN="f58cba", HUNTER="abd473", ROGUE="fff569",
    PRIEST="ffffff", SHAMAN="0070de", MAGE="69ccf0", WARLOCK="9482c9",
    DRUID="ff7d0a", DEATHKNIGHT="c41f3b", MONK="00ff96", DEMONHUNTER="a330c9", EVOKER="33937f",
}
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
    local category = self:GetCollectionCategoryName(entry.category)
    local progress = string.format("%d/%d", notice.have, notice.total)
    local overall = string.format("%d/%d", notice.all, notice.maximum)
    if not plain then
        card = "|cff71d5ff|Hcmcard:" .. entry.id .. "|h" .. card .. "|h|r"
        local color = classColors[entry.category] or "a335ee"
        local class = classColors[entry.category] and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.category]
        if class then
            color = string.format("%02x%02x%02x", math.floor(class.r * 255 + 0.5), math.floor(class.g * 255 + 0.5), math.floor(class.b * 255 + 0.5))
        end
        category = "|cff" .. color .. category .. "|r"
        progress = self:ColorCollectionProgress(progress, notice.have, notice.total)
        overall = self:ColorCollectionProgress(overall, notice.all, notice.maximum)
    end
    return string.format(self:CollectionText(
        "获得第%d套卡牌新收藏：%s！%s收藏进度：%s，总体收藏进度：%s。",
        "New card collected in set %d: %s! %s collection: %s; overall: %s."),
        entry.styleID, card, category, progress, overall)
end

function Addon:ColorCollectionProgress(text, have, total)
    local color = total > 0 and have >= total and "00ff00"
        or (total > 0 and have / total >= 0.5 and "ffd114" or "eb2e29")
    return "|cff" .. color .. text .. "|r"
end

function Addon:FlushCollectionNotices()
    local notices = self.collectionNotices or {}
    if #notices == 0 then return end
    self.collectionNotices = {}
    local now = GetTime()
    if PlaySoundFile and (not self.collectionNoticeSoundAt or now - self.collectionNoticeSoundAt >= 0.75) then
        self.collectionNoticeSoundAt = now
        local media = LibStub and LibStub("LibSharedMedia-3.0", true)
        local sound = media and media:Fetch("sound", "Xylophone", true)
        PlaySoundFile(sound or "Interface\\AddOns\\CardMaster\\Audio\\Xylophone.wav", "Master")
    end
    -- Local messages only: no automatic protected EMOTE send or share footer.
    for _, notice in ipairs(notices) do
        local hint = " |Hcmcard:" .. notice.entry.id .. "|h" .. self:CollectionText("点击文字可预览卡牌", "Click text to preview the card") .. "|h"
        self:CollectionPrint(self:FormatCollectionNotice(notice) .. hint, true)
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
        if not safe(link) or type(link) ~= "string" then return nil end
        local id = link:match("^cmcard:(%d+:C%d+)$") or link:match("|Hcmcard:(%d+:C%d+)|h")
        return id and Addon.collectionIndex and Addon.collectionIndex[id]
    end
    local function enter(self, link)
        local entry = entryFor(link)
        if entry then
            local preview = Addon.collectionPreview
            if self.cardMasterCollectionHoverEntry == entry and preview and preview.entry == entry and preview:IsShown() then return end
            self.cardMasterCollectionHoverEntry = entry
            Addon:ShowCollectionPreview(entry, UIParent)
        end
    end
    local function leave(self)
        -- Some clients supply no link argument on OnHyperlinkLeave.
        local entry = self.cardMasterCollectionHoverEntry
        self.cardMasterCollectionHoverEntry = nil
        local preview = Addon.collectionPreview
        if entry and preview and preview.entry == entry and not preview.pinned then preview:Hide() end
    end
    local function installChat(chat)
        if not chat or not chat.HookScript then return end
        -- ScrollingMessageFrame can accept clicks while hover callbacks are
        -- disabled. Explicitly opt in on clients that expose this switch.
        if chat.SetHyperlinksEnabled and not (InCombatLockdown and InCombatLockdown()) then chat:SetHyperlinksEnabled(true) end
        if chat.cardMasterCollectionLinks then return end
        chat.cardMasterCollectionLinks = true
        chat:HookScript("OnHyperlinkEnter", enter)
        chat:HookScript("OnHyperlinkLeave", leave)
        chat:HookScript("OnHide", leave)
    end
    local install
    local function installGlass()
        local glass = _G.Glass
        if not glass or not glass.GetModule then return end
        -- Glass hides ChatFrameN and renders independent, pooled message lines.
        -- Hook those actual lines, including ones created after this addon loads.
        local manager = glass:GetModule("UIManager", true)
        if manager then
            if not manager.cardMasterCollectionAdapter and manager.OnEnable and hooksecurefunc then
                manager.cardMasterCollectionAdapter = true
                hooksecurefunc(manager, "OnEnable", function() install() end)
            end
            local function scan(smf)
                for _, message in ipairs(smf.state and smf.state.messages or {}) do
                    if not message.cardMasterCollectionLinks then installChat(message) end
                end
            end
            for _, group in ipairs({"frames", "temporaryFrames"}) do
                for _, smf in pairs(manager.state and manager.state[group] or {}) do
                    scan(smf)
                    if not smf.cardMasterCollectionAdapter and smf.Update and hooksecurefunc then
                        smf.cardMasterCollectionAdapter = true
                        hooksecurefunc(smf, "Update", function() scan(smf) end)
                    end
                end
            end
        end
        if glass.Subscribe and not glass.cardMasterCollectionAdapter then
            glass.cardMasterCollectionAdapter = true
            local owner = {}
            glass:Subscribe("Glass/HYPERLINK_ENTER", function(payload)
                if type(payload) == "table" then enter(owner, payload[1]) end
            end)
            glass:Subscribe("Glass/HYPERLINK_LEAVE", function() leave(owner) end)
            glass:Subscribe("Glass/MOUSE_LEAVE", function() leave(owner) end)
        end
    end
    install = function()
        for i = 1, NUM_CHAT_WINDOWS or 10 do
            installChat(_G["ChatFrame" .. i])
        end
        installChat(DEFAULT_CHAT_FRAME)
        for _, name in ipairs(CHAT_FRAMES or {}) do installChat(_G[name]) end
        installGlass()
    end
    install()
    local function refresh()
        install()
        if C_Timer and C_Timer.After then C_Timer.After(0, install) end
    end
    if FCF_OpenTemporaryWindow and hooksecurefunc then hooksecurefunc("FCF_OpenTemporaryWindow", refresh) end
    if FCF_OpenNewWindow and hooksecurefunc then hooksecurefunc("FCF_OpenNewWindow", refresh) end
    if EventRegistry and EventRegistry.RegisterCallback then
        local owner = {}
        EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkEnter", function(_, chat, link) enter(chat or owner, link) end, owner)
        EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkLeave", function(_, chat) leave(chat or owner) end, owner)
    end
    local adapter = CreateFrame("Frame")
    adapter:RegisterEvent("ADDON_LOADED")
    adapter:RegisterEvent("PLAYER_LOGIN")
    adapter:RegisterEvent("PLAYER_ENTERING_WORLD")
    adapter:RegisterEvent("UPDATE_CHAT_WINDOWS")
    adapter:RegisterEvent("PLAYER_REGEN_ENABLED")
    adapter:SetScript("OnEvent", function(_, event, name)
        if event ~= "ADDON_LOADED" or name == "Glass" then refresh() end
    end)
    self.collectionChatAdapterFrame = adapter
    local original = SetItemRef
    if original then
        SetItemRef = function(link, text, button, chatFrame, ...)
            -- Older chat-history entries can still contain the removed footer.
            if safe(link) and type(link) == "string" and link:match("^cmshare:%d+$") then
                Addon:CollectionPrint(Addon:CollectionText("通告入口已移除。", "The announcement shortcut has been removed."))
                return
            end
            local entry = entryFor(link)
            if entry then Addon:ShowCollectionPreview(entry, UIParent, true); return end
            return original(link, text, button, chatFrame, ...)
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
