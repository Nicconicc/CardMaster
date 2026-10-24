local _, Addon = ...

Addon.languageOptions = {
    {code="enUS",label="English"}, {code="deDE",label="Deutsch"}, {code="frFR",label="Français"},
    {code="esES",label="Español (EU)"}, {code="esMX",label="Español (LatAm)"},
    {code="itIT",label="Italiano"}, {code="ptBR",label="Português (BR)"},
    {code="ruRU",label="Русский"}, {code="koKR",label="한국어 (Korean)"},
    {code="zhCN",label="简体中文"}, {code="zhTW",label="繁體中文"},
}
local supported = {enGB=true}
for _, option in ipairs(Addon.languageOptions) do supported[option.code]=true end
function Addon:IsLanguageSupported(language) return supported[language] == true end
function Addon:ClientLanguage()
    local language = GetLocale and GetLocale() or "enUS"
    return self:IsLanguageSupported(language) and (language == "enGB" and "enUS" or language) or "enUS"
end
function Addon:EffectiveLanguage()
    local language = self.db and self.db.language
    return self:IsLanguageSupported(language) and (language == "enGB" and "enUS" or language) or self:ClientLanguage()
end
function Addon:IsChineseLanguage()
    local language = self:EffectiveLanguage()
    return language == "zhCN" or language == "zhTW"
end
function Addon:L(zh, en)
    local language = self:EffectiveLanguage()
    if language == "zhCN" then return zh end
    local catalog = self.localeTables and self.localeTables[language]
    return (catalog and catalog[en]) or en or zh
end
function Addon:T(key)
    local zh, en = self.strings.zhCN[key], self.strings.enUS[key]
    if zh then return self:L(zh, en or zh) end
    return self:L(key, (self.localeEnglish and self.localeEnglish[key]) or key)
end
function Addon:InterfaceFontPath(language)
    local root = "Interface\\AddOns\\CardMaster\\Textures\\Assets\\Fonts\\"
    language = language or self:EffectiveLanguage()
    if language == "koKR" then return root .. "NotoSerifCJKkr-Black.otf" end
    if language == "ruRU" then return root .. "NotoSerif-Black.ttf" end
    return root .. "ARHei.TTF"
end
function Addon:ApplyLocaleFont(label)
    if not (label and label.GetFont and label.SetFont) then return end
    local _, size, flags = label:GetFont()
    if not size then return end
    local nominal=label.cmInterfaceNominal
    if not nominal then
        nominal=size-self:ClientInterfaceFontSize(13)+13
        label.cmInterfaceNominal=nominal
    end
    size=self:ClientInterfaceFontSize(nominal)
    label.cmUnfittedSize=size
    label:SetFont(self:RegionFontPath(label), size, flags or "")
    if self.TrackInterfaceFont then self:TrackInterfaceFont(label,nominal,flags or "") end
end
function Addon:RegionFontPath(label)
    if label.cmLanguageChoiceCode then return self:InterfaceFontPath(label.cmLanguageChoiceCode) end
    -- Artwork/catalogue names are immutable and some have no English alias.
    -- Render such preserved CJK names without requiring the Russian face to
    -- contain CJK glyphs. Never translate or rename these identifiers.
    local text=label.GetText and label:GetText()
    if self:EffectiveLanguage()=="ruRU" and type(text)=="string" and text:find("[\228-\233][\128-\191][\128-\191]") then
        return self:InterfaceFontPath("zhCN")
    end
    return self:InterfaceFontPath()
end
function Addon:FitLocaleLabel(label, width)
    if not (label and label.GetFont and label.GetStringWidth and label.SetFont and width and width > 0) then return end
    local path, size, flags = label:GetFont()
    if not path or not size then return end
    label.cmUnfittedSize = label.cmUnfittedSize or size
    label.cmFitWidth = width
    label:SetFont(path, label.cmUnfittedSize, flags or "")
    local measured = label.GetUnboundedStringWidth and label:GetUnboundedStringWidth() or label:GetStringWidth()
    if type(measured)=="number" and measured > width and measured < math.huge then
        label:SetFont(path, math.max(1, label.cmUnfittedSize * (width-1) / measured), flags or "")
    end
    label:SetWordWrap(false)
end
-- Traverse only our own UI, never arbitrary mouse-focus or Blizzard trees.
function Addon:ApplyLocaleTree(root)
    if not root then return end
    local function label(region)
        if region.GetObjectType and region:GetObjectType()=="FontString" then
            self:ApplyLocaleFont(region)
            local width = region.GetWidth and region:GetWidth()
            if width and width > 0 and region.GetWordWrap and not region:GetWordWrap() then self:FitLocaleLabel(region,width) end
        end
    end
    local function visit(frame)
        if frame.IsForbidden and frame:IsForbidden() then return end
        for _, region in ipairs({frame:GetRegions()}) do label(region) end
        local kind=frame.GetObjectType and frame:GetObjectType()
        if (kind=="Button" or kind=="CheckButton") and frame.GetFontString then
            local text=frame:GetFontString()
            if text then self:ApplyLocaleFont(text);self:FitLocaleLabel(text,math.max(1,frame:GetWidth()-14)) end
        end
        if frame.GetObjectType and frame:GetObjectType()=="EditBox" then self:ApplyLocaleFont(frame) end
        for _, child in ipairs({frame:GetChildren()}) do visit(child) end
    end
    visit(root)
end
function Addon:RefreshLanguage()
    if self.RefreshInterfaceFonts then self:RefreshInterfaceFonts() end
    if self.RefreshOptions then self:RefreshOptions() end
    if self.settingsEntry and self.settingsEntry.refresh then self.settingsEntry.refresh() end
    if self.welcomeWindow and self.RefreshWelcomeWindow then self:RefreshWelcomeWindow() end
    self:ApplyLocaleTree(self.options)
    self:ApplyLocaleTree(self.welcomeWindow)
    self:ApplyLocaleTree(self.settingsEntry)
    self:ApplyLocaleTree(self.collectionPreview)
    local preview=self.collectionPreview
    if preview and preview.entry and preview:IsShown() then
        self:ShowCollectionPreview(preview.entry,preview.previewOwner,preview.pinned)
    end
end
function Addon:SetLanguage(language)
    if not self:IsLanguageSupported(language) or not self.db then return end
    self.db.language = language == "enGB" and "enUS" or language
    self:RefreshLanguage()
    if C_Timer and C_Timer.After and not self.localeRefreshQueued then
        self.localeRefreshQueued=true
        C_Timer.After(0,function()
            Addon.localeRefreshQueued=nil
            if Addon.db then Addon:RefreshLanguage() end
        end)
    end
end
