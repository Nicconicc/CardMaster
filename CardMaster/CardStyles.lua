local _, Addon = ...

local BACK_ROOT = "Interface\\AddOns\\CardMaster\\Textures\\Cardback\\"
local BACK_STYLE_COUNT = 19
local backStyles
local frontStyles = {
    {
        id = 1,
        folder = "cardfront1",
        bossFolder = "Boss",
        showFolder = "cardfrontshow\\cardfront1show",
        showNames = {
            "暴风雪", "冰川尖刺", "猎豹形态", "怒雷破", "威力感知",
            "伪装", "悬空", "意气风发", "镇压", "自然平衡",
        },
        nameZh = "UuoBros",
        nameEn = "UuoBros",
    },
    {
        id = 2,
        folder = "cardfront2",
        bossFolder = "Boss",
        -- New sets reuse the authoritative card list from style 1 until they
        -- provide their own catalogue. Missing art is shown as an uncollected
        -- card rather than creating a blank preview slot.
        catalogBase = 1,
        showFolder = "cardfrontshow\\cardfront2show",
        showNames = {
            "暴风雪", "冰川尖刺", "猎豹形态", "怒雷破", "威力感知",
            "伪装", "悬空", "意气风发", "镇压", "自然平衡",
        },
        nameZh = "NerfLegacy",
        nameEn = "NerfLegacy",
    },
}

function Addon:GetSharedCardFrontShowNames()
    local sharedNames = {}
    for _, name in ipairs(frontStyles[1].showNames or {}) do
        for _, style in ipairs(frontStyles) do
            local found = false
            for _, styleName in ipairs(style.showNames or {}) do
                if styleName == name then found = true; break end
            end
            if not found then break end
            if style == frontStyles[#frontStyles] then
                sharedNames[#sharedNames + 1] = name
            end
        end
    end
    return sharedNames
end

function Addon:GetCardFrontShowTexture(style, name)
    if not self:IsPackInstalled(style.id) then return self:GetUnknownCardTexture(style.id) end
    return self:GetPackRoot(style.id) .. "Textures\\Assets\\" .. style.showFolder .. "\\" .. name .. ".blp"
end

-- Choose one shared showcase card at login; each skin keeps its own art path.
function Addon:PickCardFrontShowPreviews()
    if self.cardFrontShowPreviewsPicked then return end
    local sharedNames = self:GetSharedCardFrontShowNames()
    local selectedName
    if #sharedNames > 0 then
        selectedName = sharedNames[random(#sharedNames)]
    end
    for _, style in ipairs(frontStyles) do
        if selectedName then
            style.preview = self:GetCardFrontShowTexture(style, selectedName)
        end
    end
    self.cardFrontShowcaseName = selectedName
    self.cardFrontShowPreviewsPicked = true
end

-- Add future front card sets here.  The collection page lays every entry out
-- vertically and shows each set's installed-card progress independently.
function Addon:GetCardFrontStyles()
    return frontStyles
end

function Addon:GetCardFrontStyle(styleID)
    for _, style in ipairs(self:GetCardFrontStyles()) do
        if style.id == styleID then return style end
    end
    return self:GetCardFrontStyles()[1]
end

function Addon:GetSelectedCardFrontStyle()
    local styleID = self.db and self.db.cardStyles and self.db.cardStyles.front
    return self:GetCardFrontStyle(styleID)
end

-- All skill cards are initially recorded against cardfront1.  Later sets can
-- inherit the same card names and folders, while retaining independent art and
-- collection progress.  A set can still supply a complete dedicated catalogue
-- by adding CardCatalog[styleID].
function Addon:GetCardCollectionCatalog(styleID)
    local catalog = self.CardCatalog and self.CardCatalog[styleID]
    if catalog then return catalog end
    local style = self:GetCardFrontStyle(styleID)
    local base = style and style.catalogBase and self.CardCatalog and self.CardCatalog[style.catalogBase]
    if not base then return nil end
    return {
        folder = style.folder,
        bossFolder = style.bossFolder,
        total = base.total,
        classes = base.classes,
    }
end

function Addon:ResolveCardFrontTexture(texture)
    local style = self:GetSelectedCardFrontStyle()
    if style and not self:IsPackInstalled(style.id) then return self:GetCardBackTexture() end
    return self:MapCardResourcePath(texture, style and style.id)
end

-- Countdown cards are authored separately from spell art.  Keep the artwork
-- lookup alongside the selected front-style logic so every module uses the
-- same style selection and future front sets need no Countdown.lua changes.
function Addon:GetCountdownNumberTexture(number)
    number = math.floor(tonumber(number) or 0)
    if number < 1 or number > 10 then return nil end
    local style = self:GetSelectedCardFrontStyle()
    if not style then return nil end
    if not self:IsPackInstalled(style.id) then return self:GetCardBackTexture() end
    return self:GetFrontArtPath(style.id, "Numbers\\Num" .. number .. ".blp")
end

-- The level-up animation has three authored card faces per front set.  Keep
-- their filenames stable so adding a future front style only requires its
-- Level folder, not a change to the animation code.
function Addon:GetLevelUpCardTextures()
    local style = self:GetSelectedCardFrontStyle()
    if not style then return nil end
    if not self:IsPackInstalled(style.id) then
        local back = self:GetCardBackTexture()
        return {leftCard = back, centerCard = back, rightCard = back}
    end
    local root = self:GetFrontArtPath(style.id, "Level\\")
    return {
        leftCard = root .. "牛头人升级.blp",
        centerCard = root .. "Level Up.blp",
        rightCard = root .. "暗夜精灵升级.blp",
    }
end

function Addon:GetCardBackStyles()
    if backStyles then return backStyles end
    backStyles = {}
    -- The supplied collection currently contains card_back1 through card_back19.
    -- Do not probe beyond this: SetTexture accepts an unresolved path and would
    -- otherwise create empty thumbnail slots for nonexistent files.
    for id = 1, BACK_STYLE_COUNT do
        local path = BACK_ROOT .. "card_back" .. id .. ".blp"
        backStyles[#backStyles + 1] = { id = id, texture = path }
    end
    return backStyles
end

function Addon:GetCardBackTexture()
    local id = self.db and self.db.cardStyles and self.db.cardStyles.back or 1
    return BACK_ROOT .. "card_back" .. id .. ".blp"
end

function Addon:UpdateCardBackAssets()
    local texture = self:GetCardBackTexture()
    if self.Spells then self.Spells.DEFAULT_TEXTURE = texture end
    if self.LootTextures then self.LootTextures.cardBack = texture end
    if self.LevelUpTextures then self.LevelUpTextures.cardBack = texture end
end

function Addon:SetCardBackStyle(id)
    for _, style in ipairs(self:GetCardBackStyles()) do
        if style.id == id then
            self.db.cardStyles.back = id
            self:UpdateCardBackAssets()
            if self.RefreshCardStyles then self:RefreshCardStyles() end
            return
        end
    end
end

function Addon:IsCardCollected(styleID, classToken, spellName)
    local entries = self:GetCardCollectionEntries(styleID)[classToken] or {}
    for _, entry in ipairs(entries) do
        if entry.name == spellName then return self:OwnsCollectionCard(entry.id) end
    end
    return false
end

function Addon:GetUnknownCardTexture(styleID)
    local style = self:GetCardFrontStyle(styleID)
    if not style then return nil end
    if self:IsPackInstalled(styleID) then return self:GetFrontArtPath(styleID, "cardunkown.blp") end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Catalogue names remain present even when their actual art is not installed.
function Addon:GetCardCollectionEntries(styleID)
    self.cardCollectionEntries = self.cardCollectionEntries or {}
    if self.cardCollectionEntries[styleID] then return self.cardCollectionEntries[styleID] end
    local catalog = self:GetCardCollectionCatalog(styleID)
    if not catalog then return {} end
    local groups = {}
    for token, class in pairs(catalog.classes) do
        local entries = {}
        groups[token] = entries
        for _, name in ipairs(class.names) do
            local classFolder = token == "BOSS" and (catalog.bossFolder or class.folder) or class.folder
            local sourceName = name
            local styleNames = class.styleFileNames and class.styleFileNames[styleID]
            if styleNames and styleNames[name] then sourceName = styleNames[name] end
            entries[#entries + 1] = {
                styleID = styleID,
                category = token,
                id = self:GetStableCardID(styleID, token, name),
                name = name,
                sourceTexture = self:GetFrontArtPath(styleID, classFolder .. "\\" .. sourceName .. ".blp"),
                available = false,
                checked = false,
                texture = self:GetUnknownCardTexture(styleID),
            }
        end
        table.sort(entries, function(a, b) return a.name < b.name end)
    end
    self.cardCollectionEntries[styleID] = groups
    return groups
end

-- SetTexture's return value and GetTexture's path do not prove a file exists.
-- Missing files render as a small green fallback texture, which also has
-- nonzero dimensions. All card art is at least 512x512, so count a card only
-- when the loaded native dimensions are large enough to be real card art.
-- SetSize(0, 0) after SetTexture asks the client for those native dimensions.
function Addon:StartCardAssetScan()
    -- The overview may open before the login delay has elapsed. Do not let
    -- that path bypass the same 10-second startup window.
    if not self.cardAssetScanReady or self.cardAssetScan then return end
    local scan = { queue = {}, active = {}, nextIndex = 1, running = true }
    self.cardAssetScan = scan
    for _, style in ipairs(self:GetCardFrontStyles()) do
        for _, entries in pairs(self:GetCardCollectionEntries(style.id)) do
            for _, entry in ipairs(entries) do
                scan.queue[#scan.queue + 1] = entry
            end
        end
    end

    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(1, 1)
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
    frame:SetAlpha(0)
    frame:EnableMouse(false)
    scan.frame = frame
    local updateElapsed, changed = 0, false

    local function finish(task, available)
        task.entry.available = available
        task.entry.checked = true
        task.entry.texture = available and task.entry.sourceTexture or self:GetUnknownCardTexture(task.entry.styleID)
        task.texture:SetTexture(nil)
        task.texture:Hide()
        changed = true
    end

    frame:SetScript("OnUpdate", function(_, delta)
        for index = #scan.active, 1, -1 do
            local task = scan.active[index]
            task.elapsed = task.elapsed + delta
            local width, height = task.texture:GetSize()
            local loaded = not task.texture.IsObjectLoaded or task.texture:IsObjectLoaded()
            if loaded and width >= 64 and height >= 64 then
                finish(task, true)
                table.remove(scan.active, index)
            elseif task.elapsed >= 5 then
                finish(task, false)
                table.remove(scan.active, index)
            end
        end

        -- Limit both in-flight textures and new requests per frame to keep the
        -- settings window responsive while checking the entire catalogue.
        local started = 0
        while #scan.active < 64 and scan.nextIndex <= #scan.queue and started < 12 do
            local entry = scan.queue[scan.nextIndex]
            scan.nextIndex = scan.nextIndex + 1
            started = started + 1
            local texture = frame:CreateTexture(nil, "ARTWORK")
            texture:SetPoint("TOPLEFT", frame, "TOPLEFT")
            texture:SetTexture(self:IsPackInstalled(entry.styleID) and entry.sourceTexture or nil)
            texture:SetSize(0, 0)
            scan.active[#scan.active + 1] = { entry = entry, texture = texture, elapsed = 0 }
        end

        updateElapsed = updateElapsed + delta
        local complete = scan.nextIndex > #scan.queue and #scan.active == 0
        if changed and (updateElapsed >= 0.1 or complete) then
            changed, updateElapsed = false, 0
            if self.OnCardAssetsChanged then self:OnCardAssetsChanged() end
        end
        if complete then
            scan.running = false
            frame:SetScript("OnUpdate", nil)
            frame:Hide()
        end
    end)
end

function Addon:GetCardCollectionProgress(styleID)
    local catalog = self:GetCardCollectionCatalog(styleID)
    if not catalog then return 0, 0 end
    local collected, total = 0, 0
    for _, entries in pairs(self:GetCardCollectionEntries(styleID)) do
        for _, entry in ipairs(entries) do
            total = total + 1
            if self:OwnsCollectionCard(entry.id) then
                collected = collected + 1
            end
        end
    end
    return collected, total, 0
end

function Addon:InitCardStyles()
    self:PickCardFrontShowPreviews()
    local selectedFront = self.db.cardStyles.front
    local hasSelectedFront = false
    for _, style in ipairs(self:GetCardFrontStyles()) do
        if style.id == selectedFront then hasSelectedFront = true; break end
    end
    if not hasSelectedFront then self.db.cardStyles.front = self:GetCardFrontStyles()[1].id end
    local selected = self.db.cardStyles.back
    local styles = self:GetCardBackStyles()
    for _, style in ipairs(styles) do
        if style.id == selected then
            self:UpdateCardBackAssets()
            return
        end
    end
    self.db.cardStyles.back = styles[1].id
    self:UpdateCardBackAssets()
end
