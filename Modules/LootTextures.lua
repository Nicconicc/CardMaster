local _, Addon = ...

local ROOT = "Interface\\AddOns\\CardMaster\\"
-- Loot cards now live inside the front-style sets.  Keep the authoritative
-- paths on cardfront1; Loot.lua resolves them to the selected front style.
local CARD_ROOT = ROOT .. "Textures\\Cardfront\\cardfront1\\Loot\\"

Addon.LootTextures = {
    cards = {
        ["阿曼尼雷霆"] = CARD_ROOT .. "阿曼尼雷霆.blp", ["阿曼尼烈火"] = CARD_ROOT .. "阿曼尼烈火.blp",
        ["埃提耶什的碎片"] = CARD_ROOT .. "埃提耶什的碎片.blp", ["艾瑞达之心"] = CARD_ROOT .. "艾瑞达之心.blp",
        ["奥的灰烬"] = CARD_ROOT .. "奥的灰烬.blp", ["不死鸟之焰"] = CARD_ROOT .. "不死鸟之焰.blp",
        ["夺灵者碎片"] = CARD_ROOT .. "夺灵者碎片.blp", ["堕落者烈火"] = CARD_ROOT .. "堕落者烈火.blp",
        ["风吻之刃"] = CARD_ROOT .. "风吻之刃.blp", ["缚灵碎片护符"] = CARD_ROOT .. "缚灵碎片护符.blp",
        ["黑暗纳鲁碎片"] = CARD_ROOT .. "黑暗纳鲁碎片.blp", ["黑曜石烈焰"] = CARD_ROOT .. "黑曜石烈焰.blp",
        ["洪流碎片"] = CARD_ROOT .. "洪流碎片.blp", ["雷霆的回响"] = CARD_ROOT .. "雷霆的回响.blp",
        ["魔法的碎片"] = CARD_ROOT .. "魔法的碎片.blp", ["欺诈者水晶"] = CARD_ROOT .. "欺诈者水晶.blp",
        ["萨弗拉斯之眼"] = CARD_ROOT .. "萨弗拉斯之眼.blp", ["萨弗隆铁锭"] = CARD_ROOT .. "萨弗隆铁锭.blp",
        ["索利达尔，群星之怒"] = CARD_ROOT .. "索利达尔，群星之怒.blp", ["瓦格里雷霆"] = CARD_ROOT .. "瓦格里雷霆.blp",
        ["织法者裂片"] = CARD_ROOT .. "织法者裂片.blp", ["蛛魔裂片"] = CARD_ROOT .. "蛛魔裂片.blp",
    },
    cardBack = ROOT .. "Textures\\Cardback\\card_back1.blp",
    gradient = ROOT .. "Textures\\Assets\\Square_AlphaGradient.tga",
    particles = ROOT .. "Textures\\Assets\\TargetHPParticular.blp",
    throwknifeSound = ROOT .. "Audio\\LevelUp\\throwknife.ogg",
    fanfareSound = ROOT .. "Audio\\LevelUp\\TadaFanfare.ogg",
    font = ROOT .. "Textures\\Assets\\Myriad.ttf",
}
