local _, Addon = ...

local ROOT = "Interface\\AddOns\\CardMaster\\Textures\\Assets\\Footer\\"
local ENTRIES = {
    { id = "mangui", zh = "MangUI", en = "MangUI", fullColor = true, copyText = "MangUI" },
    { id = "afdian", zh = "爱发电", en = "Afdian", url = "https://ifdian.net/a/cardmaster" },
    { id = "patreon", zh = "Patreon", en = "Patreon", pending = true },
    { id = "discord", zh = "Discord", en = "Discord", pending = true },
    { id = "kook", zh = "KOOK", en = "KOOK", url = "https://kook.vip/DqQ5U4" },
    { id = "github", zh = "GitHub", en = "GitHub", url = "https://github.com/Nicconicc/CardMaster" },
}

local function text(zh, en)
    return Addon.db and Addon.db.language == "enUS" and en or zh
end

local function call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, result = pcall(fn, ...)
    if ok then return result end
end

local function number(value)
    if issecretvalue and issecretvalue(value) then return end
    if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then return end
    return value
end

local function resetSample(sample)
    sample.total, sample.time, sample.percent, sample.reason = nil, nil, nil, nil
    sample.elapsed = 0
end

local function sampleCPU(sample)
    local profiler = C_AddOnProfiler
    local metric = Enum and Enum.AddOnProfilerMetric and Enum.AddOnProfilerMetric.RecentAverageTime
    if profiler and type(profiler.GetAddOnMetric) == "function" and metric ~= nil
        and (type(profiler.IsEnabled) ~= "function" or call(profiler.IsEnabled) == true) then
        local ms = number(call(profiler.GetAddOnMetric, Addon.name, metric))
        local fps = number(call(GetFramerate))
        if ms and fps and fps > 0 then
            sample.total, sample.time, sample.reason = nil, nil, "modern"
            sample.percent = math.max(0, math.min(100, ms * fps / 10))
            return
        end
    end
    local enabled = call(GetCVar or (C_CVar and C_CVar.GetCVar), "scriptProfile")
    if enabled ~= "1" and enabled ~= 1 and enabled ~= true then
        resetSample(sample)
        sample.reason = "disabled"
        return
    end
    local update = UpdateAddOnCPUUsage or (C_AddOns and C_AddOns.UpdateAddOnCPUUsage)
    local get = GetAddOnCPUUsage or (C_AddOns and C_AddOns.GetAddOnCPUUsage)
    if type(update) ~= "function" or type(get) ~= "function" then
        resetSample(sample)
        sample.reason = "unavailable"
        return
    end
    local ok = pcall(update)
    local total = ok and number(call(get, Addon.name))
    local now = number(call(GetTime))
    if not total or not now then
        resetSample(sample)
        sample.reason = "unavailable"
        return
    end
    local elapsed = sample.time and now - sample.time
    local used = sample.total and total - sample.total
    sample.total, sample.time, sample.reason = total, now, "legacy"
    if elapsed and elapsed > 0 and used and used >= 0 then
        sample.percent = math.max(0, math.min(100, used / (elapsed * 10)))
    else
        sample.percent = nil
    end
end

local function panel(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.025, 0.025, 0.035, 0.98)
    frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
    return frame
end

local function highlight(button, active)
    local entry = button.entry
    button.icon:SetTexture(entry.fullColor and (ROOT .. "MangUI.png") or
        (ROOT .. entry.id .. (active and "_white" or "") .. ".tga"))
    button.icon:SetDesaturated(not entry.fullColor)
    button.icon:SetAlpha(entry.fullColor and 1 or (active and 1 or 0.65))
    button.glow:SetShown(active)
    if button.shine then button.shine:SetShown(active) end
end

function Addon:CreateOptionsFooter(window)
    local cpu = CreateFrame("Frame", nil, window)
    cpu:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 18, 14)
    cpu:SetSize(210, 20)
    cpu:EnableMouse(true)
    cpu.icon = cpu:CreateTexture(nil, "ARTWORK")
    cpu.icon:SetSize(18, 18)
    cpu.icon:SetPoint("LEFT", 0, 0)
    local atlasInfo = call((C_Texture and C_Texture.GetAtlasInfo) or GetAtlasInfo, "AzeriteSpawning")
    if atlasInfo and cpu.icon.SetAtlas then
        cpu.icon:SetAtlas("AzeriteSpawning", false)
    else
        cpu.icon:SetTexture("Interface\\Icons\\INV_Misc_Quill_01")
        cpu.icon:SetDesaturated(true)
    end
    cpu.label = cpu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local cpuFont = STANDARD_TEXT_FONT or select(1, cpu.label:GetFont())
    cpu.label:SetFont(cpuFont, 11, "")
    cpu.label:SetPoint("LEFT", 23, 0)
    cpu.label:SetJustifyV("MIDDLE")
    cpu.label:SetTextColor(0.7, 0.75, 0.8)
    cpu.sample = { elapsed = 0 }
    local function updateCPU()
        sampleCPU(cpu.sample)
        local value = cpu.sample.percent
        cpu.label:SetText("CPU Usage : |cffffffff" .. (value and string.format("%.2f%%", value) or "--%") .. "|r")
    end
    cpu:SetScript("OnShow", function() resetSample(cpu.sample); updateCPU() end)
    cpu:SetScript("OnHide", function() resetSample(cpu.sample); GameTooltip:Hide() end)
    cpu:SetScript("OnUpdate", function(_, elapsed)
        cpu.sample.elapsed = cpu.sample.elapsed + elapsed
        if cpu.sample.elapsed >= 1 then
            cpu.sample.elapsed = 0
            updateCPU()
        end
    end)
    cpu:SetScript("OnEnter", function(owner)
        GameTooltip:SetOwner(owner, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("CPU Usage", 1, 0.82, 0)
        GameTooltip:AddLine(text("卡牌大师的 CPU 使用率，每秒更新。", "Card Master's CPU usage, updated once per second."), 1, 1, 1, true)
        GameTooltip:AddLine(text("按插件执行时间占单线程时间的比例计算。", "Addon execution time as a percentage of one CPU thread."), 0.8, 0.8, 0.8, true)
        if cpu.sample.reason == "disabled" then
            GameTooltip:AddLine(text("CPU 统计未开启。输入 /console scriptProfile 1 后 /reload。", "CPU profiling is disabled. Use /console scriptProfile 1, then /reload."), 0.8, 0.8, 0.8, true)
        elseif cpu.sample.reason == "unavailable" then
            GameTooltip:AddLine(text("当前客户端未提供可用的 CPU 统计数据。", "CPU profiling data is unavailable on this client."), 0.8, 0.8, 0.8, true)
        elseif cpu.sample.percent == nil then
            GameTooltip:AddLine(text("正在采集 CPU 数据…", "Collecting CPU data…"), 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)
    cpu:SetScript("OnLeave", function() GameTooltip:Hide() end)
    updateCPU()
    window.cpuFooter = cpu

    local bar = CreateFrame("Frame", nil, window)
    bar:SetSize((#ENTRIES - 1) * 42 + 32, 30)
    bar:SetPoint("BOTTOMRIGHT", -20, 12)
    bar.buttons = {}
    window.footerLinks = bar
    bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.label:SetPoint("RIGHT", bar, "LEFT", -12, 0)
    bar.label:SetText(text("社区及捐助", "Community & Support"))
    bar.label:SetTextColor(0.7, 0.75, 0.8)

    local popup = panel(bar)
    popup:SetSize(380, 138)
    popup:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 5)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:Hide()
    self:EnableWindowEscape(popup)
    popup.title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popup.title:SetPoint("TOPLEFT", 12, -12)
    popup.description = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    popup.description:SetPoint("TOPLEFT", 12, -35)
    popup.description:SetSize(356, 40)
    popup.description:SetJustifyH("LEFT")
    popup.description:SetWordWrap(true)
    popup.hint = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    popup.hint:SetPoint("BOTTOMLEFT", 12, 10)
    local address = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
    address:SetPoint("TOPLEFT", 16, -81)
    address:SetSize(348, 23)
    address:SetFontObject(GameFontHighlightSmall)
    address:SetAutoFocus(false)
    address:SetScript("OnEscapePressed", function() popup:Hide() end)
    address:SetScript("OnEditFocusGained", function(owner) owner:HighlightText() end)
    address:SetScript("OnMouseUp", function(owner) owner:SetFocus(); owner:HighlightText() end)
    address:SetScript("OnTextChanged", function(owner, userInput)
        if userInput and popup.copyText then owner:SetText(popup.copyText); owner:HighlightText() end
    end)
    local close = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetSize(24, 24)
    self:StyleButton(close)
    close:SetScript("OnClick", function() popup:Hide() end)
    popup:SetScript("OnHide", function()
        address:ClearFocus()
        if popup.owner then highlight(popup.owner, false) end
        popup.owner, popup.copyText = nil, nil
    end)
    bar.popup = popup

    for index, entry in ipairs(ENTRIES) do
        local button = CreateFrame("Button", nil, bar)
        button.entry = entry
        button:SetSize(32, 30)
        button:SetPoint("LEFT", bar, "LEFT", (index - 1) * 42, 0)
        button.glow = button:CreateTexture(nil, "BACKGROUND")
        button.glow:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        button.glow:SetBlendMode("ADD")
        button.glow:SetVertexColor(1, 1, 1, 0.25)
        button.glow:SetAllPoints()
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetSize(30, 30)
        button.icon:SetPoint("CENTER")
        if entry.fullColor then
            button.shine = button:CreateTexture(nil, "OVERLAY")
            button.shine:SetAllPoints(button.icon)
            button.shine:SetTexture(ROOT .. "MangUI.png")
            button.shine:SetBlendMode("ADD")
            button.shine:SetAlpha(0.25)
        end
        highlight(button, false)
        button:SetScript("OnEnter", function(owner)
            highlight(owner, true)
            GameTooltip:SetOwner(owner, "ANCHOR_TOP")
            GameTooltip:SetText(text(entry.zh, entry.en), 1, 0.82, 0)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(owner)
            highlight(owner, popup:IsShown() and popup.owner == owner)
            GameTooltip:Hide()
        end)
        button:SetScript("OnClick", function(owner)
            GameTooltip:Hide()
            if popup.owner and popup.owner ~= owner then highlight(popup.owner, false) end
            popup.owner = owner
            popup.title:SetText(text(entry.zh, entry.en))
            if entry.copyText then
                popup.description:SetText(text("复制插件名，在插件平台搜索 MangUI。", "Copy the addon name and search for MangUI on an addon platform."))
                popup.copyText = entry.copyText
            elseif entry.pending then
                popup.description:SetText(text("创建中，请等待", "Coming soon, please wait"))
                popup.copyText = nil
            else
                popup.description:SetText(text("复制下方网址，在浏览器中打开。", "Copy the website address below and open it in your browser."))
                popup.copyText = entry.url
            end
            popup.hint:SetText(popup.copyText and text("按 Ctrl+C 复制", "Press Ctrl+C to copy") or "")
            address:ClearFocus()
            address:SetText(popup.copyText or "")
            address:SetShown(popup.copyText ~= nil)
            popup:Show()
            highlight(owner, true)
            if popup.copyText then
                address:SetFocus()
                address:HighlightText()
            end
        end)
        bar.buttons[index] = button
    end
    bar:SetScript("OnHide", function() popup:Hide(); GameTooltip:Hide() end)
end

function Addon:RefreshOptionsFooter()
    local bar = self.options and self.options.footerLinks
    if not bar then return end
    bar.label:SetText(text("社区及捐助", "Community & Support"))
    bar.popup:Hide()
    GameTooltip:Hide()
end
