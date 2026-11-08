local ADDON_NAME, Addon = ...

Addon.name = ADDON_NAME
Addon.version = "190"
-- Movers are constructed at file load, before UIStyles.lua in the TOC.
-- Keep this dependency-free size resolver available from the first file.
function Addon:ClientInterfaceFontSize(nominal)
    local size
    if GameFontNormal and GameFontNormal.GetFont then
        local _, current = GameFontNormal:GetFont()
        if type(current) == "number" and current > 0 then size = current end
    end
    return math.max(1, (size or 13) + (nominal or 13) - 13)
end
Addon.eventFrame = CreateFrame("Frame")
Addon.pendingItems = {}
Addon.encounterActive = false

local defaults = {
    language = "zhCN",
    showMinimapIcon = true,
    hideWelcomeOnLogin = false,
    cardStyles = { front = 1, back = 1 },
    cardCollection = {},
    collectionBroadcast = true,
    collectionSoundEnabled = true,
    collectionSettings = {},
    modules = {
        singleSpell = {
            enabled = true,
            soundEnabled = true,
            scale = 0.7,
            inSlideX = -150,
            inSlideY = 50,
            inRotateAngle = 0,
            inZoomW = 1.5,
            inZoomH = 1.5,
            inZoomType = 1,
            duration = 1.0,
            outSlideX = 300,
            outSlideY = -50,
            outRotateAngle = -10,
            outZoomScale = 0.5,
            outZoomType = 1,
            normalCombat = true,
            bossCombat = true,
            posX = 0,
            posY = 200,
        },
        inCombat = {
            enabled = true,
            soundEnabled = true,
            scale = 1.0,
            animSpeed = 1.0,
            normalCombat = true,
            bossCombat = true,
            posX = 0,
            posY = 200,
        },
        afk = { enabled = true, soundEnabled = true, scale = 1.0, scrollSpeed = 250, spacing = 400, showLogo = true, showMask = true, showUI = false, posX = 0, posY = 0 },
        boss = { enabled = true, soundEnabled = true, scale = 1.0, speed = 1.0, posX = 0, posY = 200 },
        loot = { enabled = true, soundEnabled = true, scale = 1.0, speed = 1.0, posX = 0, posY = 200, layoutVersion = 1 },
        levelUp = { enabled = true, soundEnabled = true, scale = 1.0, speed = 1.0, posX = 0, posY = 200, layoutVersion = 1 },
        countdown = { enabled = true, soundEnabled = true, scale = 0.7, speed = 1.0, posX = 0, posY = 200 },
    },
}
Addon.defaults = defaults

Addon.strings = {
    zhCN = {
        addonName = "卡牌大师",
        gameplay = "玩法设置",
        styles = "卡牌样式",
        collection = "卡牌总览",
        misc = "其他",
        enabled = "启用模块",
        test = "测试效果",
        move = "移动位置",
        lock = "锁定位置",
        appearance = "外观与动画",
        trigger = "触发环境",
        normalCombat = "普通战斗",
        bossCombat = "首领战斗",
        scale = "卡牌缩放",
        animSpeed = "动画速度",
        inAnimation = "入场动画设置",
        outAnimation = "出场动画设置",
        inSlideX = "入场 Slide X 偏移",
        inSlideY = "入场 Slide Y 偏移",
        inRotateAngle = "入场 Rotate 旋转角度",
        inZoomW = "入场 Zoom 峰值宽度比例",
        inZoomH = "入场 Zoom 峰值高度比例",
        inZoomType = "入场 Zoom 动画形态",
        duration = "停留时间 (秒)",
        outSlideX = "出场 Slide Out X 偏移",
        outSlideY = "出场 Slide Out Y 偏移",
        outRotateAngle = "出场 Rotate 旋转角度",
        outZoomScale = "出场 Zoom 消失缩放比例",
        outZoomType = "出场 Zoom 动画形态",
        rotateType = "旋转形态 (Flip & Rotate)",
        scaleType = "正常形态 (Pure Scale)",
        frontStyle = "正面样式",
        backStyle = "背面样式",
        front1 = "备选 1（经典高光）",
        front2 = "备选 2（暗黑质感）",
        back1 = "备选 1（符文密印）",
        back2 = "备选 2（金色战徽）",
        globalStyleHint = "修改后将应用至所有开启的卡牌模块。",
        language = "语言版本",
        chinese = "中文 (zhCN)",
        english = "English (enUS)",
        showMinimap = "显示小地图图标",
        system = "系统设置",
        configShare = "配置分享",
        exportConfig = "导出配置",
        importConfig = "导入配置",
        resetAll = "恢复全部默认",
        exportHint = "按 Ctrl+C 复制下方字符串，分享给其他用户。",
        importHint = "粘贴配置字符串；导入后将覆盖当前全部设置。",
        importApply = "确认导入",
        importDone = "配置导入成功。",
        importInvalid = "配置字符串无效或已损坏，请检查是否完整复制。",
        exportFailed = "当前配置无法导出，请检查配置数据。",
        selectAll = "全选",
        resetConfirm = "确定恢复全部默认设置吗？当前配置将被覆盖。",
        singleSpell = "单张技能卡牌",
        inCombat = "进战斗动画卡牌",
        afk = "暂离屏保卡牌",
        boss = "副本 BOSS 卡牌",
        loot = "橙色物品掉落卡牌",
        levelUp = "升级彩蛋卡牌",
        countdown = "倒计时卡牌",
        singleTitle = "技能触发",
        combatTitle = "战斗开始",
        afkTitle = "暂离模式",
        bossTitle = "首领现身",
        bossDefeated = "首领击败",
        lootTitle = "珍稀战利品",
        levelTitle = "等级提升",
        countdownTitle = "倒计时",
        dragHint = "拖动此框调整位置，再次点击“移动位置”锁定",
        resizeHint = "拖住右下角调整窗口大小",
        openSettings = "左键点击打开设置",
        resetDone = "配置已恢复默认值。",
        welcome = "欢迎使用卡牌大师，/cm或小地图按钮，选择不同卡牌皮肤，并对卡牌动画进行设置，“卡牌总览”展示当前收藏进度。您的卡牌发现之旅正式开启，祝好运！",
        collectionBroadcast = "其他玩家可见卡牌收集播报",
        collectionResetHint = "将所有插件设置恢复为默认值，不会清空已获得的收藏卡牌及收藏进度。",
        firstRunTitle = "欢迎使用 CardMaster 卡牌大师",
        firstRunIntro = "选择喜欢的卡牌外观，之后可以随时更换。",
        firstRunFront = "选择正面样式",
        firstRunBack = "选择背面样式",
        firstRunGuide = "以后点击小地图按钮或输入 /cm，即可打开卡牌窗口，调整皮肤和动画。",
        firstRunDone = "开始使用",
        firstRunSettings = "打开完整设置",
        hideWelcomeOnLogin = "以后登录不再显示",
    },
    enUS = {
        addonName = "CardMaster",
        gameplay = "Gameplay",
        styles = "Card Styles",
        collection = "Card overview",
        misc = "Other",
        enabled = "Enable module",
        test = "Test Effect",
        move = "Move Position",
        lock = "Lock Position",
        appearance = "Appearance & Animation",
        trigger = "Trigger Environment",
        normalCombat = "Normal combat",
        bossCombat = "Boss combat",
        scale = "Card scale",
        animSpeed = "Animation speed",
        inAnimation = "In-Animation",
        outAnimation = "Out-Animation",
        inSlideX = "In Slide X offset",
        inSlideY = "In Slide Y offset",
        inRotateAngle = "In Rotate angle",
        inZoomW = "In Zoom peak width",
        inZoomH = "In Zoom peak height",
        inZoomType = "In Zoom animation type",
        duration = "Hold duration (seconds)",
        outSlideX = "Out Slide X offset",
        outSlideY = "Out Slide Y offset",
        outRotateAngle = "Out Rotate angle",
        outZoomScale = "Out Zoom final scale",
        outZoomType = "Out Zoom animation type",
        rotateType = "Flip & Rotate",
        scaleType = "Pure Scale",
        frontStyle = "Front style",
        backStyle = "Back style",
        front1 = "Option 1 (Classic Glow)",
        front2 = "Option 2 (Dark Texture)",
        back1 = "Option 1 (Rune Seal)",
        back2 = "Option 2 (Golden Crest)",
        globalStyleHint = "Changes apply to every enabled card module.",
        language = "Language",
        chinese = "中文 (zhCN)",
        english = "English (enUS)",
        showMinimap = "Show minimap icon",
        system = "System",
        configShare = "Share configuration",
        exportConfig = "Export settings",
        importConfig = "Import settings",
        resetAll = "Restore all defaults",
        exportHint = "Press Ctrl+C to copy this string and share it with another player.",
        importHint = "Paste a configuration string. Importing replaces all current settings.",
        importApply = "Import settings",
        importDone = "Configuration imported successfully.",
        importInvalid = "Invalid or damaged configuration string. Check that it was copied in full.",
        exportFailed = "Could not export the current configuration. Check the saved settings.",
        selectAll = "Select all",
        resetConfirm = "Restore every setting to its default? Your current configuration will be replaced.",
        singleSpell = "Single Spell Card",
        inCombat = "In-Combat Card",
        afk = "AFK Screensaver Card",
        boss = "Dungeon Boss Card",
        loot = "Legendary Loot Card",
        levelUp = "Level-Up Easter Egg Card",
        countdown = "Countdown Card",
        singleTitle = "SPELL TRIGGERED",
        combatTitle = "ENTERING COMBAT",
        afkTitle = "AWAY",
        bossTitle = "BOSS ENCOUNTER",
        bossDefeated = "BOSS DEFEATED",
        lootTitle = "RARE LOOT",
        levelTitle = "LEVEL UP",
        countdownTitle = "COUNTDOWN",
        dragHint = "Drag this anchor, then click Move Position again to lock",
        resizeHint = "Drag to resize the window",
        openSettings = "Left-click to open settings",
        resetDone = "Settings restored to defaults.",
        welcome = "Welcome to CardMaster! Use /cm or the minimap button to choose card skins and customize card animations. Check Card Overview to view your collection progress. Your card discovery journey begins—good luck!",
        collectionBroadcast = "Share card collection announcements with other players",
        collectionResetHint = "Restore all addon settings. Collected cards and collection progress will be preserved.",
        firstRunTitle = "Welcome to CardMaster",
        firstRunIntro = "Choose your card appearance. You can change it any time.",
        firstRunFront = "Choose a front style",
        firstRunBack = "Choose a back style",
        firstRunGuide = "Later, click the minimap button or enter /cm to open card settings and animations.",
        firstRunDone = "Start using",
        firstRunSettings = "Open full settings",
        hideWelcomeOnLogin = "Don't show on future logins",
    },
}

local function copyDefaults(target, source)
    if type(target) ~= "table" then
        target = {}
    end
    for key, value in pairs(source) do
        if type(value) == "table" then
            target[key] = copyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

local function replaceWithDefaults(target, source)
    for key in pairs(target) do
        target[key] = nil
    end
    copyDefaults(target, source)
end

function Addon:T(key)
    local language = self.db and self.db.language or "zhCN"
    local set = self.strings[language] or self.strings.zhCN
    return set[key] or self.strings.zhCN[key] or key
end

function Addon:Print(message)
    local icon = "|TInterface\\AddOns\\CardMaster\\Textures\\Assets\\CMLogo.png:16:16:0:0|t"
    local name = self:T("addonName")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffc34d" .. name .. "|r " .. icon .. " " .. tostring(message))
end

-- Select modern API restrictions for Retail and Forever. Forever now has its
-- own project ID (Camelot), but still requires the same safe event/UI paths.
function Addon:IsRetail()
    if WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return true end
    if WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then return true end
    -- Also support Forever builds without the Camelot global.
    local interfaceVersion = GetBuildInfo and select(4, GetBuildInfo())
    return interfaceVersion == 16000 or interfaceVersion == 16001
end

function Addon:IsBossCombat()
    if self.encounterActive then
        return true
    end
    if self:IsRetail() then return false end
    if UnitExists("boss1") then return true end
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "party" or instanceType == "raid") and UnitExists("boss1")
end

function Addon:CombatAllowed(config)
    if self:IsBossCombat() then
        return config.bossCombat
    end
    return config.normalCombat
end

function Addon:ApplyDatabase(database)
    self.SingleSpell.Stop()
    self.CombatIn.Stop()
    self.AFK.Stop()
    self.Boss.Stop()
    self.Loot.Stop()
    self.LevelUp.Stop()
    self.Countdown.Stop()
    replaceWithDefaults(self.db, database or defaults)
    copyDefaults(self.db, defaults)
    self:InitCardStyles()
    if self.RefreshCollectionSettings then self:RefreshCollectionSettings() end
    self:InitIntegratedModules()
    self:InitAFKModule()
    self:InitBossModule()
    self:InitLootModule()
    self:InitLevelUpModule()
    self:InitCountdownModule()
    if self.RefreshOptions then self:RefreshOptions() end
    if self.RefreshCardStyles then self:RefreshCardStyles() end
    if self.UpdateMinimapButton then self:UpdateMinimapButton() end
end

function Addon:ResetDatabase()
    self:ApplyDatabase(defaults)
    self:Print(self:T("resetDone"))
end

function Addon:HandleLoot(message)
    local itemLink = message and message:match("(|c%x+|Hitem:.-|h.-|h|r)")
    if not itemLink then return end

    local itemID = tonumber(itemLink:match("item:(%d+)"))
    local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(itemLink)
    if quality then
        if quality == 5 and self.Loot then
            self.Loot.Play(name)
        end
    elseif itemID then
        self.pendingItems[itemID] = itemLink
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end
    end
end

function Addon:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName ~= ADDON_NAME then return end
        self:MigrateSavedVariables()
        self.defaults.language = self:ClientLanguage()

        -- Earlier builds reserved these modules for the generic card renderer
        -- at y = 100.  Their imported WA layouts are anchored at y = 200, so
        -- migrate that unused legacy position once without touching later choices.
        local savedLoot = CardMasterDB and CardMasterDB.modules and CardMasterDB.modules.loot
        if savedLoot and not savedLoot.layoutVersion then
            savedLoot.posX, savedLoot.posY, savedLoot.layoutVersion = 0, 200, 1
        end
        local savedLevelUp = CardMasterDB and CardMasterDB.modules and CardMasterDB.modules.levelUp
        if savedLevelUp and not savedLevelUp.layoutVersion then
            savedLevelUp.posX, savedLevelUp.posY, savedLevelUp.layoutVersion = 0, 200, 1
        end
        CardMasterDB = copyDefaults(CardMasterDB, defaults)
        self.db = CardMasterDB
        -- Match MangUI: client language at every login/reload; manual selection
        -- and imported language remain available for the current session.
        self.db.language = self:ClientLanguage()
        self:InitCardStyles()
        self:InitCollection()
        self:InitIntegratedModules()
        self:InitAFKModule()
        self:InitBossModule()
        self:InitLootModule()
        self:InitLevelUpModule()
        self:InitCountdownModule()
        self.lastSpellCard = 0
        self.lastCombatCard = 0

        local events = {
            "ENCOUNTER_START", "ENCOUNTER_END", "PLAYER_LEVEL_UP", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD",
        }
        for _, eventName in ipairs(events) do
            self.eventFrame:RegisterEvent(eventName)
        end

        self:CreateCardFrames()
        self:CreateMinimapButton()
        self:RegisterSettingsEntry()

        SLASH_CARDMASTER1 = "/cm"
        SlashCmdList.CARDMASTER = function(command)
            command = strtrim(command or ""):lower()
            if command == "reset" then
                Addon:ResetDatabase()
            elseif command == "welcome" then
                -- Open the welcome window on demand, even if it was disabled
                -- for automatic display at login.
                if InCombatLockdown() then
                    Addon.welcomeForcePending = true
                    Addon.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                else
                    Addon:ShowWelcomeWindow(true)
                end
            else
                Addon:ToggleOptions()
            end
        end
    elseif not self.db then
        return
    elseif event == "PLAYER_LOGIN" then
        -- Retry if this client's native settings API was not ready at addon load.
        self:RegisterSettingsEntry()
        if self.collectionStatus == "storage" or self.collectionStatus == "damaged" then
            self:CollectionPrint(self:GetCollectionStatusText())
        end
        for _, style in ipairs(self:GetCardFrontStyles()) do
            if not self:IsPackInstalled(style.id) then
                self:CollectionPrint(self:CollectionText(style.nameZh, style.nameEn) .. self:CollectionText(" 资源包未加载；收藏数据保留，缺图使用占位显示。", " artwork pack is not loaded; collection is preserved and placeholders will be used."))
            elseif CardMasterResourcePacks[style.id].version ~= 1 then
                self:CollectionPrint(self:CollectionText(style.nameZh, style.nameEn) .. self:CollectionText(" 资源版本与主插件不一致，请检查更新。", " artwork version differs; check for updates."))
            end
        end
        if not self.db.hideWelcomeOnLogin then
            C_Timer.After(1.5, function()
                if not Addon.db or Addon.db.hideWelcomeOnLogin then return end
                if InCombatLockdown() then
                    Addon.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                else
                    Addon:ShowWelcomeWindow()
                end
            end)
        end
        -- Let other addons finish their login notices first so this welcome
        -- line appears at the end of the startup messages.
        C_Timer.After(5, function()
            if Addon.db then Addon:Print(Addon:T("welcome")) end
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        self.eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        local force = self.welcomeForcePending
        self.welcomeForcePending = nil
        if force or not self.db.hideWelcomeOnLogin then self:ShowWelcomeWindow(force) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- PLAYER_ENTERING_WORLD fires both during a fresh login and after
        -- /reload. Delay the catalogue scan so it does not compete with
        -- other addons' startup work. Zoning must not restart this timer.
        if not self.cardAssetScanScheduled then
            self.cardAssetScanScheduled = true
            C_Timer.After(10, function()
                Addon.cardAssetScanReady = true
                if Addon.db then
                    Addon:StartCardAssetScan()
                end
            end)
        end
    elseif event == "ENCOUNTER_START" then
        local _, encounterName = ...
        self.encounterActive = true
    elseif event == "ENCOUNTER_END" then
        self.encounterActive = false
    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        if self.db.modules.levelUp.enabled then
            self.LevelUp.Play(level)
        end
    end
end

Addon.eventFrame:SetScript("OnEvent", function(_, event, ...)
    Addon:OnEvent(event, ...)
end)
Addon.eventFrame:RegisterEvent("ADDON_LOADED")
