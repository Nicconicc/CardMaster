local _, Addon = ...

-- Match MangUI 1.0.661/662: retain the template's actual circular opening,
-- not the center of its asymmetric decorative portrait border.
function Addon:ApplyWindowLogo(panel)
    if panel.logo then return end
    local name = panel:GetName()
    local portrait = panel.Portrait or (name and _G[name .. "Portrait"])
        or (panel.PortraitContainer and panel.PortraitContainer.portrait) or panel.portrait
    if not portrait then return end
    local interface = GetBuildInfo and select(4, GetBuildInfo())
    if interface == 38001 and not panel.PortraitContainer then
        portrait:ClearAllPoints()
        portrait:SetPoint("TOPLEFT", panel, "TOPLEFT", -10, 11)
    end
    local parent = portrait:GetParent()
    local opening = (panel.PortraitContainer and panel.PortraitContainer.CircleMask) or panel.CircleMask or portrait
    local background = parent:CreateTexture(nil, "OVERLAY", nil, -2)
    background:SetAllPoints(opening)
    background:SetColorTexture(27/255, 25/255, 26/255, 1)
    local logo = parent:CreateTexture(nil, "OVERLAY", nil, -1)
    logo:SetTexture("Interface\\AddOns\\CardMaster\\Textures\\Assets\\CMLogo.png")
    logo:SetTexCoord(.22, .78, .215, .775)
    logo:SetAllPoints(background)
    local mask = parent:CreateMaskTexture()
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(background)
    background:AddMaskTexture(mask)
    logo:AddMaskTexture(mask)
    portrait:Hide()
    panel.logo, panel.logoBackground, panel.logoMask = logo, background, mask
end

-- Standalone counterparts of MangUI's editor widgets; MangUI is not required.
local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end
local function mouseOver(frame)
    return frame:IsMouseOver()
end
function Addon:HasLegacyOptionsStyle(region)
    while region do
        if region.legacyOptionsStyle then return true end
        region = region:GetParent()
    end
    return false
end
local interfaceFonts = setmetatable({}, {__mode = "k"})
function Addon:BindInterfaceFont(region, nominal, path, flags)
    region.cmInterfaceNominal=nominal
    local record = {nominal = nominal, path = path, flags = flags or ""}
    interfaceFonts[region] = record
    record.size = self:ClientInterfaceFontSize(nominal)
    record.localePath = self:RegionFontPath(region)
    region:SetFont(record.localePath, record.size, record.flags)
end
function Addon:TrackInterfaceFont(region,nominal,flags)
    if interfaceFonts[region] then return end
    interfaceFonts[region]={nominal=nominal,flags=flags,localePath=self:RegionFontPath(region),size=self:ClientInterfaceFontSize(nominal)}
end
function Addon:UseInheritedInterfaceFont(region, object)
    interfaceFonts[region] = nil
    region:SetFontObject(object)
    region.cmInterfaceNominal=nil
    self:ApplyLocaleFont(region)
end
function Addon:RefreshInterfaceFonts()
    for region, record in pairs(interfaceFonts) do
        local size = self:ClientInterfaceFontSize(record.nominal)
        local path=self:RegionFontPath(region)
        if size ~= record.size or path ~= record.localePath then
            record.size = size
            record.localePath = path
            region.cmUnfittedSize = size
            region:SetFont(path, size, record.flags)
            if region.cmFitWidth then self:FitLocaleLabel(region,region.cmFitWidth) end
        end
    end
end
local fontWatcher = CreateFrame("Frame")
local fontElapsed = 0
fontWatcher:SetScript("OnUpdate", function(_, elapsed)
    fontElapsed = fontElapsed + elapsed
    if fontElapsed < 0.5 then return end
    fontElapsed = 0
    Addon:RefreshInterfaceFonts()
end)
function Addon:SetControlFont(region, size)
    if self:HasLegacyOptionsStyle(region) then self:ApplyLocaleFont(region);return end
    self:BindInterfaceFont(region, size or 12, STANDARD_TEXT_FONT or "Fonts\\ARKai_T.ttf", "")
end

function Addon:StyleButton(b, force)
    if not force and self:HasLegacyOptionsStyle(b) then return b end
    if b.panelButtonStyled then return b end
    b.panelButtonStyled=true;b.panelButtonHoverColor={1,1,1}
    local function CenterText(self)
        local text=self:GetFontString();if not text then return end
        text:ClearAllPoints();text:SetPoint("CENTER",self,"CENTER",self.panelButtonTextX or 0,self.panelButtonTextY or 0)
        text:SetSize(math.max(1,self:GetWidth()-10),self:GetHeight())
        text:SetJustifyH("CENTER");text:SetJustifyV("MIDDLE");text:SetWordWrap(false)
    end
    local function Paint(self)
        local hover=self.panelButtonHover and self:IsEnabled()
        local function TintRegions(frame)
            for _,region in ipairs({frame:GetRegions()}) do
                if region:GetObjectType()=="Texture" then region:SetDesaturated(not (hover or self.panelButtonFullColor)) end
            end
        end
        TintRegions(self)
        if self.NineSlice then TintRegions(self.NineSlice) end
        local text=self:GetFontString()
        if text then
            local color=hover and self.panelButtonHoverColor or self.panelButtonNormalTextColor or {1,1,1}
            text:SetTextColor(color[1],color[2],color[3],1)
            CenterText(self)
            Addon:SetControlFont(text)
            Addon:FitLocaleLabel(text,math.max(1,self:GetWidth()-14))
        end
    end
    function b:SetHoverTextColor(r,g,blue)
        self.panelButtonHoverColor={r,g,blue};Paint(self)
    end
    function b:SetFullColorStyle(r,g,blue)
        self.panelButtonFullColor=true
        self.panelButtonNormalTextColor={r,g,blue}
        self.panelButtonHoverColor={r,g,blue};Paint(self)
    end
    function b:SetTextCenterOffset(x,y)
        self.panelButtonTextX=x;self.panelButtonTextY=y;CenterText(self)
    end
    if b:GetFontString() then
        b:SetNormalFontObject(GameFontHighlight);b:SetHighlightFontObject(GameFontHighlight)
        b:SetPushedTextOffset(0,0)
    end
    b:HookScript("OnEnter",function(self)self.panelButtonHover=true;Paint(self)end)
    b:HookScript("OnLeave",function(self)self.panelButtonHover=false;Paint(self)end)
    b:HookScript("OnShow",function(self)self.panelButtonHover=self:IsMouseOver();Paint(self)end)
    b:HookScript("OnHide",function(self)self.panelButtonHover=false;Paint(self)end)
    b:HookScript("OnEnable",Paint);b:HookScript("OnDisable",Paint)
    b:HookScript("OnMouseDown",Paint);b:HookScript("OnMouseUp",Paint)
    b:HookScript("OnSizeChanged",CenterText)
    Paint(b);return b
end

function Addon:CreateChoiceSelect(parent, width, label, choices, selected, onChanged)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(width, 44)
    f.caption = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:SetControlFont(f.caption)
    f.caption:SetPoint("TOPLEFT", 0, 0)
    f.caption:SetHeight(18)
    f.caption:SetText(label)
    if self:HasLegacyOptionsStyle(f) then f.caption:SetTextColor(1, .82, 0)
    else f.caption:SetTextColor(1, 1, 1) end
    local skin = "Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame"
    local left = f:CreateTexture(nil, "ARTWORK")
    left:SetSize(25, 64);left:SetPoint("BOTTOMLEFT", -17, -21)
    left:SetTexture(skin);left:SetTexCoord(0, .1953125, 0, 1)
    local right = f:CreateTexture(nil, "ARTWORK")
    right:SetSize(25, 64);right:SetPoint("TOP", left, "TOP")
    right:SetPoint("RIGHT", f, "RIGHT", 17, 0)
    right:SetTexture(skin);right:SetTexCoord(.8046875, 1, 0, 1)
    local middle = f:CreateTexture(nil, "ARTWORK")
    middle:SetHeight(64);middle:SetPoint("TOP", left, "TOP")
    middle:SetPoint("LEFT", left, "RIGHT");middle:SetPoint("RIGHT", right, "LEFT")
    middle:SetTexture(skin);middle:SetTexCoord(.1953125, .8046875, 0, 1)
    f.valueText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self:SetControlFont(f.valueText)
    f.valueText:SetPoint("RIGHT", right, "RIGHT", -43, 1)
    f.valueText:SetPoint("LEFT", left, "LEFT", 26, 1)
    f.valueText:SetHeight(18);f.valueText:SetJustifyH("RIGHT")
    f.valueText:SetWordWrap(false);f.valueText:SetTextColor(1, 1, 1)
    function f:SetValue(index)
        self.value = index;self.valueText:SetText(choices[index] or "")
    end
    local function OpenMenu()
        if f.menu then f.menu:Hide();return end
        -- Match the font selector's plain checked rows, not red action buttons.
        -- Keep the popup outside the movable/scrolling options tree. Rebasing
        -- that window's levels must not lower choices beneath the independent
        -- outside-click layer, which would consume every attempted selection.
        local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        menu.legacyOptionsStyle = Addon:HasLegacyOptionsStyle(f)
        menu:SetScale(f:GetEffectiveScale() / UIParent:GetEffectiveScale())
        menu:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,
            insets={left=11,right=12,top=12,bottom=9}})
        menu:SetFrameStrata("TOOLTIP");menu:SetFrameLevel(9100)
        menu:SetClampedToScreen(true);menu:EnableMouse(true)
        menu:SetSize(math.max(188, width), #choices * 24 + 25)
        menu:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, 0)
        local dismiss = CreateFrame("Button", nil, UIParent)
        dismiss:SetAllPoints(UIParent);dismiss:SetFrameStrata("TOOLTIP");dismiss:SetFrameLevel(9000)
        dismiss:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        dismiss:SetScript("OnClick", function() menu:Hide() end)
        menu.rows = {}
        for index, choice in ipairs(choices) do
            local row = CreateFrame("Button", nil, menu)
            row:SetSize(math.max(188, width) - 28, 24)
            row:SetPoint("TOPLEFT", 14, -13 - (index - 1) * 24)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            row.check = row:CreateTexture(nil, "OVERLAY")
            row.check:SetSize(16, 16);row.check:SetPoint("LEFT", 1, -1)
            row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            row.check:SetShown(index == f.value)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            for _, option in ipairs(Addon.languageOptions) do
                if choice==option.label then row.label.cmLanguageChoiceCode=option.code;break end
            end
            Addon:SetControlFont(row.label)
            row.label:SetPoint("LEFT", row.check, "RIGHT", 1, 0)
            row.label:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            row.label:SetHeight(24);row.label:SetJustifyH("LEFT");row.label:SetJustifyV("MIDDLE")
            row.label:SetWordWrap(false);row.label:SetTextColor(1, 1, 1);row.label:SetText(choice)
            row:SetScript("OnClick", function()
                f:SetValue(index);menu:Hide();onChanged(index)
            end)
            menu.rows[index] = row
        end
        Addon:EnableWindowEscape(menu)
        menu:SetScript("OnHide", function()
            dismiss:Hide();if f.menu == menu then f.menu = nil end
        end)
        f.menu = menu
        Addon:ApplyLocaleTree(menu)
        for _, row in ipairs(menu.rows) do Addon:FitLocaleLabel(row.label,math.max(1,row:GetWidth()-28)) end
    end
    f.click = CreateFrame("Button", nil, f)
    f.click:SetPoint("BOTTOMLEFT");f.click:SetPoint("BOTTOMRIGHT");f.click:SetHeight(24)
    f.click:SetScript("OnClick", OpenMenu)
    f.arrow = CreateFrame("Button", nil, f);f.arrow:SetSize(24, 24)
    f.arrow:SetPoint("TOPRIGHT", right, "TOPRIGHT", -16, -18)
    f.arrow:SetFrameLevel(f.click:GetFrameLevel() + 1)
    f.arrow:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    f.arrow:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    f.arrow:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
    f.arrow:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    f.arrow:SetScript("OnClick", OpenMenu)
    f:SetScript("OnHide", function() if f.menu then f.menu:Hide() end end)
    f:SetValue(selected)
    return f
end

function Addon:CreateSpinBox(parent,width,minimum,maximum,step)
    local f=CreateFrame("Slider",nil,parent)
    local enabled=true
    f:SetSize(width or 200,19);f:SetOrientation("HORIZONTAL");f:EnableMouse(false)
    f:SetMinMaxValues(minimum or 0,maximum or 100);f:SetValueStep(step or 1)
    local skin="Interface\\AddOns\\CardMaster\\Textures\\Assets\\WAControls\\spinbox"
    local left=CreateFrame("Button",nil,f);left:SetSize(16,16);left:SetPoint("LEFT",2,0)
    local right=CreateFrame("Button",nil,f);right:SetSize(16,16);right:SetPoint("RIGHT",-2,0)
    for _,entry in ipairs({{left,"left"},{right,"right"}}) do
        entry[1]:SetNormalTexture(skin..entry[2]);entry[1]:SetHighlightTexture(skin..entry[2].."h")
        entry[1]:SetPushedTexture(skin..entry[2].."p");entry[1]:SetDisabledTexture(skin..entry[2].."p")
    end
    local edit=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal);edit:SetTextColor(1,1,1);edit:SetHeight(19)
    Addon:SetControlFont(edit)
    edit:SetJustifyH("CENTER");edit:SetTextInsets(0,0,3,3);edit:EnableMouse(true);edit:EnableMouseWheel(false)
    edit:SetPoint("LEFT",left,"RIGHT",8,0);edit:SetPoint("RIGHT",right,"LEFT",-2,0)
    local progress=edit:CreateTexture(nil,"ARTWORK")
    progress:SetTexture(skin.."overlay");progress:SetVertexColor(.5,.5,.5,1)
    progress:SetPoint("TOPLEFT",edit,"TOPLEFT",-2,-3);progress:SetPoint("BOTTOMLEFT",edit,"BOTTOMLEFT",-2,3)
    local handle=CreateFrame("Frame",nil,edit);handle:EnableMouse(true)
    handle:SetSize(28,28);handle:SetPoint("CENTER",progress,"RIGHT",0,0)
    local highlight=handle:CreateTexture(nil,"ARTWORK")
    highlight:SetAllPoints();highlight:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    handle:Hide()
    local function Update()
        local value=f:GetValue() or 0;local lo,hi=f:GetMinMaxValues()
        if not edit:HasFocus() then
            local number=math.floor(value*100+.5)/100
            edit:SetText(f.isPercent and tostring(math.floor(value*1000+.5)/10).."%" or tostring(number)..(f.suffix or ""))
        end
        left:SetEnabled(enabled and value>lo);right:SetEnabled(enabled and value<hi)
        local p=hi>lo and clamp((value-lo)/(hi-lo),0,1) or 0
        progress:SetWidth(math.max(1,p*math.max(1,f:GetWidth()-47)));progress:SetTexCoord(0,p,0,1)
    end
    local function Apply(value)
        if not enabled then Update();return end
        local lo,hi=f:GetMinMaxValues();local increment=f:GetValueStep()
        if increment and increment>0 then
            local units=value/increment
            value=(units>=0 and math.floor(units+.5) or math.ceil(units-.5))*increment
        end
        f:SetValue(clamp(value,lo,hi));Update()
    end
    left:SetScript("OnClick",function()edit:ClearFocus();Apply(f:GetValue()-f:GetValueStep())end)
    right:SetScript("OnClick",function()edit:ClearFocus();Apply(f:GetValue()+f:GetValueStep())end)
    edit:SetScript("OnEnterPressed",function(self)
        local text=self:GetText();if f.suffix and f.suffix~="" and text:sub(-#f.suffix)==f.suffix then text=text:sub(1,-#f.suffix-1) end
        local value=tonumber((text:gsub("%%","")))
        self:ClearFocus();if value then Apply(f.isPercent and value/100 or value) else Update() end
    end)
    edit:SetScript("OnEscapePressed",function(self)self:ClearFocus();Update()end)
    edit:SetScript("OnEditFocusLost",Update)
    edit:SetScript("OnEnter",function()if enabled and not edit:HasFocus() then handle:Show() end end)
    edit:SetScript("OnEditFocusGained",function()handle:Hide()end)
    handle:SetScript("OnMouseDown",function(self,button)
        if not enabled or button~="LeftButton" then return end
        edit:ClearFocus();self.dragging=true;self.startX=GetCursorPosition();self.original=f:GetValue()
    end)
    handle:SetScript("OnMouseUp",function(self,button)
        if button=="LeftButton" and self.dragging then self.dragging=false end
    end)
    handle:SetScript("OnUpdate",function(self)
        if not enabled then self.dragging=false;self:Hide();return end
        if self.dragging and not IsMouseButtonDown("LeftButton") then self.dragging=false end
        if self.dragging then
            local x=GetCursorPosition();local lo,hi=f:GetMinMaxValues();local increment=f:GetValueStep()
            local delta=(x-self.startX)/edit:GetEffectiveScale()/math.max(1,f:GetWidth()-47)*(hi-lo)
            Apply(self.original+delta)
        elseif edit:HasFocus() or not mouseOver(f) then self:Hide() end
        if self.dragging then highlight:SetVertexColor(1,.82,.4,1)
        elseif mouseOver(self) then highlight:SetVertexColor(1,1,.75,1)
        else highlight:SetVertexColor(1,1,1,1) end
    end)
    -- Refresh directly on programmatic changes, including while hidden. The
    -- caller installs its own OnValueChanged handler after constructing this control.
    local nativeSetValue,nativeSetMinMaxValues=f.SetValue,f.SetMinMaxValues
    function f:SetValue(value)nativeSetValue(self,value);Update()end
    function f:SetMinMaxValues(lo,hi)nativeSetMinMaxValues(self,lo,hi);Update()end
    f:HookScript("OnShow",Update);f:HookScript("OnSizeChanged",Update)
    f:HookScript("OnHide",function()handle.dragging=false;handle:Hide();edit:ClearFocus()end)
    function f:HasFocus()return edit:HasFocus()end
    function f:ClearFocus()edit:ClearFocus()end
    function f:IsEnabled()return enabled end
    function f:SetEnabled(value)
        enabled=value~=false
        if enabled then edit:Enable()
        else edit:ClearFocus();edit:Disable();handle.dragging=false;handle:Hide() end
        edit:EnableMouse(enabled);handle:EnableMouse(enabled)
        self:SetAlpha(enabled and 1 or .45);Update()
    end
    function f:SetText(value)
        local number=tonumber(value) or 0
        local updating=self.updating;self.updating=true;self:SetValue(number);self.updating=updating
        Update()
    end
    function f:SetIsPercent(value)self.isPercent=value;Update()end
    f.editbox=edit;f.leftbutton=left;f.rightbutton=right;f.handle=handle;f.progress=progress
    f:SetValue(minimum or 0);Update()
    return f
end
