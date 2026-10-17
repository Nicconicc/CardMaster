local _, Addon = ...

-- Shared only by the Card Master and MangUI options windows. Each visible
-- window receives a separate, compact range of frame levels.
local Stack = { windows = {}, registered = {}, pending = nil, scheduled = false }
_G.MangUIOptionsWindowStack = Stack

local function visibleFrames(window)
    local frames, levels, unique = {}, {}, {}
    local strata = window:GetFrameStrata()
    local function visit(frame)
        if not frame:IsShown() then return end
        if frame.GetFrameStrata and frame:GetFrameStrata() == strata
            and not (frame.IsForbidden and frame:IsForbidden()) then
            local level = frame:GetFrameLevel()
            frames[#frames + 1] = { frame = frame, level = level }
            if not unique[level] then
                unique[level] = true
                levels[#levels + 1] = level
            end
        end
        for _, child in ipairs({ frame:GetChildren() }) do visit(child) end
    end
    visit(window)
    table.sort(levels)
    return frames, levels
end

function Stack:Apply()
    if self.applying then return end
    self.applying = true
    local groups = {}
    -- Snapshot every tree before SetFrameLevel shifts inherited child levels.
    for _, window in ipairs(self.windows) do
        if window:IsShown() then
            local frames, levels = visibleFrames(window)
            groups[#groups + 1] = { frames = frames, levels = levels }
        end
    end
    local base = 100
    for _, group in ipairs(groups) do
        local mapped = {}
        for index, level in ipairs(group.levels) do mapped[level] = base + index - 1 end
        -- Preorder visits parents before children. Restore each child's
        -- relative drawing order after any automatic parent-level adjustment.
        for _, entry in ipairs(group.frames) do
            local level = mapped[entry.level]
            if entry.frame:GetFrameLevel() ~= level then entry.frame:SetFrameLevel(level) end
        end
        base = base + #group.levels + 32
    end
    self.applying = false
end

function Stack:Focus(window)
    if not self.registered[window] or not window:IsShown() then return end
    for index, candidate in ipairs(self.windows) do
        if candidate == window then table.remove(self.windows, index); break end
    end
    self.windows[#self.windows + 1] = window
    self:Apply()
end

function Stack:QueueFocus(window)
    if not self.registered[window] then return end
    self.pending = window
    if self.scheduled then return end
    self.scheduled = true
    C_Timer.After(0, function()
        self.scheduled = false
        local pending = self.pending
        self.pending = nil
        if pending and pending:IsShown() then self:Focus(pending) end
    end)
end

function Stack:Register(window)
    if not self.registered[window] then
        self.registered[window] = true
        self.windows[#self.windows + 1] = window
        window:SetToplevel(true)
        window:HookScript("OnShow", function(owner)
            self:Focus(owner)
            self:QueueFocus(owner)
        end)
        window:HookScript("OnMouseDown", function(owner) self:QueueFocus(owner) end)
        window:HookScript("OnDragStart", function(owner) self:QueueFocus(owner) end)
    end
    if window:IsShown() then
        self:Focus(window)
        self:QueueFocus(window)
    end
end

function Stack:WindowForFrame(frame)
    for _ = 1, 128 do
        if not frame then return end
        if self.registered[frame] then return frame end
        if not frame.GetParent then return end
        frame = frame:GetParent()
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("GLOBAL_MOUSE_DOWN")
driver:SetScript("OnEvent", function()
    if GetMouseFoci then
        for _, frame in ipairs(GetMouseFoci() or {}) do
            local window = Stack:WindowForFrame(frame)
            if window then Stack:QueueFocus(window); return end
        end
    elseif GetMouseFocus then
        local window = Stack:WindowForFrame(GetMouseFocus())
        if window then Stack:QueueFocus(window) end
    end
end)
Stack.driver = driver

function Addon:RegisterOptionsWindow(window)
    Stack:Register(window)
    if _G.MangUIUFOptions then Stack:Register(_G.MangUIUFOptions) end
end
