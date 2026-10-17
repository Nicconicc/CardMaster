-- This addon owns the save file. Collection logic lives in CardMaster.
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, _, name)
    if name ~= "CardMasterCollection" then return end
    if CardMasterCollectionDB == nil then
        CardMasterCollectionDB = { version = 1, cards = {}, seen = {}, quarantine = {} }
    end
    CardMasterCollectionStorageReady = true
    self:UnregisterEvent("ADDON_LOADED")
end)
