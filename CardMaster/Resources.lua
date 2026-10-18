local _, Addon = ...
local roots = {
    [1] = "Interface\\AddOns\\CardMaster_HallowedForgeSeries\\",
    [2] = "Interface\\AddOns\\CardMaster_LustreSeries\\",
}
function Addon:GetPackRoot(id)
    local pack = CardMasterResourcePacks and CardMasterResourcePacks[id]
    return pack and pack.root or roots[id]
end
function Addon:IsPackInstalled(id)
    return CardMasterResourcePacks and CardMasterResourcePacks[id] ~= nil
end
function Addon:GetFrontArtPath(id, relative)
    return self:GetPackRoot(id) .. "Textures\\Cardfront\\" .. relative
end
function Addon:GetFrontHighlightRoot(id)
    return self:GetPackRoot(id) .. "Textures\\Assets\\cardfronthighlight\\cardfront" .. id .. "highlight"
end
-- Existing spell maps retain their names and Boss trigger IDs.
function Addon:MapCardResourcePath(path, styleID)
    if type(path) ~= "string" then return path end
    local id, relative = path:match("^Interface\\AddOns\\CardMaster\\Textures\\Cardfront\\cardfront(%d+)\\(.+)$")
    if id then return self:GetFrontArtPath(styleID or tonumber(id), relative) end
    return path
end
