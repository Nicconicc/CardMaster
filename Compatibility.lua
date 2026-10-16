local _, Addon = ...

-- Only these legacy references remain; the active addon, frames and assets
-- all use CardMaster. Old exported settings and copied WTF data stay usable.
local oldRoot = "Interface\\AddOns\\MangUICardMaster\\"
local newRoot = "Interface\\AddOns\\CardMaster\\"
local function RenameTexturePath(value)
    if type(value) == "string" and value:sub(1, #oldRoot) == oldRoot then
        return newRoot .. value:sub(#oldRoot + 1):gsub("MCMLogo", "CMLogo")
    end
    return value
end
local function MigratePaths(data, seen)
    if seen[data] then return end
    seen[data] = true
    local renamed = {}
    for key, value in pairs(data) do
        local newKey = RenameTexturePath(key)
        if type(value) == "table" then MigratePaths(value, seen)
        else value = RenameTexturePath(value) end
        if newKey ~= key then
            renamed[#renamed + 1] = {key, newKey, value}
        else data[key] = value end
    end
    for _, entry in ipairs(renamed) do
        if data[entry[2]] == nil then data[entry[2]] = entry[3] end
        data[entry[1]] = nil
    end
end
function Addon:MigrateSavedVariables()
    if type(CardMasterDB) ~= "table" and type(MangUICardMasterDB) == "table" then
        CardMasterDB = MangUICardMasterDB
    end
    if type(CardMasterDB) == "table" then MigratePaths(CardMasterDB, {}) end
    MangUICardMasterDB = nil
end
