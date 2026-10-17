local _, Addon = ...

-- Assets copied from the original level-up WeakAura.  Keeping every path here
-- makes the animation module independent of WeakAuras and of the old MangUI5
-- addon it was originally authored for.
local ROOT = "Interface\\AddOns\\CardMaster\\"

Addon.LevelUpTextures = {
    leftCard = ROOT .. "Textures\\Assets\\牛头人升级.blp",
    centerCard = ROOT .. "Textures\\Assets\\Level Up.blp",
    rightCard = ROOT .. "Textures\\Assets\\暗夜精灵升级.blp",
    cardBack = ROOT .. "Textures\\Cardback\\card_back1.blp",
    gradient = ROOT .. "Textures\\Assets\\Square_AlphaGradient.tga",
    particles = ROOT .. "Textures\\Assets\\TargetHPParticular.blp",
    flipSound = ROOT .. "Audio\\LevelUp\\throwknife.ogg",
    fanfareSound = ROOT .. "Audio\\LevelUp\\TadaFanfare.ogg",
    font = ROOT .. "Textures\\Assets\\Myriad.ttf",
}
