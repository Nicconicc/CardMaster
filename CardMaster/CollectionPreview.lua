local _, Addon = ...

function Addon:GetCollectionPreview()
    if self.collectionPreview then return self.collectionPreview end
    local frame = CreateFrame("Frame", "CardMasterCollectionPreview", UIParent)
    frame:SetSize(512, 536)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetClampedToScreen(true)
    frame.art = frame:CreateTexture(nil, "ARTWORK")
    frame.art:SetSize(512, 512)
    frame.art:SetPoint("TOP")
    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:ApplyLocaleFont(frame.label)
    frame.label:SetPoint("TOP", frame.art, "BOTTOM", 0, -2)
    frame.effects = {}
    if frame.CreateMaskTexture and frame.art.AddMaskTexture and frame.art.SetVertexOffset then
        for _, channel in ipairs({ {"frame", 180}, {"card", 360} }) do
            local mask = frame:CreateMaskTexture(nil, "OVERLAY")
            mask:SetAllPoints(frame.art)
            local band = frame:CreateTexture(nil, "OVERLAY")
            band:SetSize(channel[2], 760)
            band:SetTexture("Interface\\AddOns\\CardMaster\\Textures\\Assets\\gradient.tga", "MIRROR")
            band:SetTexCoord(-1, 1, 0, 1)
            band:SetBlendMode("ADD")
            band:SetVertexOffset(1, 130, 0); band:SetVertexOffset(3, 130, 0)
            band:SetVertexOffset(2, -130, 0); band:SetVertexOffset(4, -130, 0)
            band:AddMaskTexture(mask)
            local group = band:CreateAnimationGroup()
            local sweep = group:CreateAnimation("Translation")
            sweep:SetOffset(860, 0); sweep:SetDuration(2.1)
            group:SetScript("OnFinished", function() band:Hide() end)
            frame.effects[#frame.effects + 1] = {name = channel[1], mask = mask, band = band, animation = group}
        end
    end
    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", -10, -8)
    frame.close:SetScript("OnClick", function() frame:Hide() end)
    frame:SetScript("OnHide", function()
        for _, effect in ipairs(frame.effects) do effect.animation:Stop(); effect.band:Hide() end
        frame.entry, frame.pinned = nil, nil
    end)
    frame:SetScript("OnUpdate", function()
        local entry = frame.entry
        if entry and entry.available and not frame.showingArt then
            Addon:ShowCollectionPreview(entry, frame.previewOwner, frame.pinned)
        end
    end)
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, "CardMasterCollectionPreview")
    frame:Hide()
    self.collectionPreview = frame
    return frame
end

function Addon:ShowCollectionPreview(entry, owner, pinned)
    if not entry then return end
    local frame = self:GetCollectionPreview()
    if frame.pinned and not pinned then return end
    frame:Hide()
    frame:ClearAllPoints()
    if owner and owner ~= UIParent then
        frame:SetPoint("TOPLEFT", owner, "TOPRIGHT", -48, -78)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    frame.entry, frame.pinned = entry, pinned
    local available = entry.available and self:IsPackInstalled(entry.styleID)
    frame.showingArt, frame.previewOwner = available, owner
    frame.art:SetTexture(available and entry.sourceTexture or self:GetUnknownCardTexture(entry.styleID))
    frame.label:SetText(available and "" or self:CollectionText("已收藏，贴图未安装或仍在检查", "Collected; artwork missing or still being checked"))
    self:ApplyLocaleFont(frame.label)
    self:FitLocaleLabel(frame.label,500)
    frame.close:SetShown(pinned and true or false)
    frame:Show()
    if not available then return end
    local suffix = entry.styleID == 2 and (entry.category == "BOSS" or entry.category == "LOOT") and "_2" or ""
    for _, effect in ipairs(frame.effects) do
        effect.mask:SetTexture(self:GetFrontHighlightRoot(entry.styleID) .. effect.name .. suffix .. ".png")
        local alpha = effect.name == "frame" and (entry.styleID == 1 and 0.21 or 0.42) or (entry.styleID == 1 and 0.084 or 0.105)
        effect.band:SetVertexColor(1, 0.94, 0.78, alpha)
        effect.band:ClearAllPoints()
        effect.band:SetPoint("CENTER", frame.art, "CENTER", -430, 0)
        effect.band:Show(); effect.animation:Play()
    end
end
