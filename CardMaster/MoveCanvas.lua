local _, Addon = ...

local ROOT = "Interface\\AddOns\\CardMaster\\Textures\\Assets\\MoveCanvas\\"

function Addon:CreateMoveCanvas(owner, moduleKey, positionProvider)
    local canvas = CreateFrame("Frame", nil, owner)
    canvas:SetAllPoints(owner)
    canvas:SetFrameLevel(owner:GetFrameLevel() + 1)
    canvas:EnableMouse(false)
    canvas.textures = {}

    local uv = { 0, 10 / 32, 22 / 32, 1 }
    local skins = {
        { file = "MoveAreaFill.tga", layer = "BACKGROUND", color = { 0.08, 0.8, 0.25, 0.27 } },
        { file = "MoveAreaBorder.tga", layer = "OVERLAY", color = { 0.25, 1, 0.35, 0.95 } },
    }
    local function positionSlices(relativeScale)
        local radius = 10 / relativeScale
        local columns = {
            { "LEFT", 0, "LEFT", radius },
            { "LEFT", radius, "RIGHT", -radius },
            { "RIGHT", -radius, "RIGHT", 0 },
        }
        local rows = {
            { "TOP", 0, "TOP", -radius },
            { "TOP", -radius, "BOTTOM", radius },
            { "BOTTOM", radius, "BOTTOM", 0 },
        }
        local index = 0
        for _, skin in ipairs(skins) do
            for y, row in ipairs(rows) do
                for x, column in ipairs(columns) do
                    index = index + 1
                    local texture = canvas.textures[index]
                    if not texture then
                        texture = canvas:CreateTexture(nil, skin.layer)
                        texture:SetTexture(ROOT .. skin.file)
                        texture:SetTexCoord(uv[x], uv[x + 1], uv[y], uv[y + 1])
                        texture:SetVertexColor(unpack(skin.color))
                        canvas.textures[index] = texture
                    end
                    texture:ClearAllPoints()
                    texture:SetPoint("TOPLEFT", canvas, row[1] .. column[1], column[2], row[2])
                    texture:SetPoint("BOTTOMRIGHT", canvas, row[3] .. column[3], column[4], row[4])
                end
            end
        end
    end

    local _, _, flags = GameFontNormal:GetFont()
    local font = self:InterfaceFontPath()
    canvas.title = canvas:CreateFontString(nil, "OVERLAY")
    canvas.title:SetFont(font, self:ClientInterfaceFontSize(14), flags or "")
    canvas.title:SetPoint("BOTTOMLEFT", canvas, "TOPLEFT", 0, 4)
    canvas.title:SetJustifyH("LEFT")
    canvas.title:SetTextColor(1, 1, 1)
    canvas.coordinates = canvas:CreateFontString(nil, "OVERLAY")
    canvas.coordinates:SetFont(font, self:ClientInterfaceFontSize(12), flags or "")
    canvas.coordinates:SetPoint("LEFT", canvas.title, "RIGHT", 8, 0)
    canvas.coordinates:SetJustifyH("LEFT")
    canvas.coordinates:SetTextColor(1, 0.82, 0)

    local function update()
        local relativeScale = (owner:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
        if relativeScale <= 0 then relativeScale = 1 end
        local clientTitleSize = Addon:ClientInterfaceFontSize(14)
        font = Addon:InterfaceFontPath()
        if canvas.relativeScale ~= relativeScale or canvas.clientTitleSize ~= clientTitleSize or canvas.localeFont ~= font then
            canvas.localeFont = font
            canvas.clientTitleSize = clientTitleSize
            canvas.relativeScale = relativeScale
            positionSlices(relativeScale)
            -- Keep borders and coordinate labels the same size across module scales.
            canvas.title:SetFont(font, clientTitleSize / relativeScale, flags or "")
            canvas.coordinates:SetFont(font, Addon:ClientInterfaceFontSize(12) / relativeScale, flags or "")
            canvas.title:ClearAllPoints()
            canvas.title:SetPoint("BOTTOMLEFT", canvas, "TOPLEFT", 0, 4 / relativeScale)
            canvas.coordinates:ClearAllPoints()
            canvas.coordinates:SetPoint("LEFT", canvas.title, "RIGHT", 8 / relativeScale, 0)
        end
        canvas.title:SetText(Addon:T(moduleKey))
        local x, y
        if positionProvider then
            x, y = positionProvider(owner)
        else
            local cx, cy = owner:GetCenter()
            local ux, uy = UIParent:GetCenter()
            if cx and cy and ux and uy then
                x, y = cx * relativeScale - ux, cy * relativeScale - uy
            end
        end
        if x and y then
            if math.abs(x) < 0.0005 then x = 0 end
            if math.abs(y) < 0.0005 then y = 0 end
            local value = string.format("X: %g  Y: %g", x, y)
            if canvas.positionText ~= value then
                canvas.positionText = value
                canvas.coordinates:SetText(value)
            end
        end
    end
    canvas:SetScript("OnShow", update)
    local elapsed = 0
    canvas:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 1 / 30 then
            elapsed = 0
            update()
        end
    end)
    update()
    return canvas
end
