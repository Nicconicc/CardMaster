local _, Addon = ...
Addon.Boss = {}
local Boss = Addon.Boss
local ROOT = "Interface\\AddOns\\CardMaster\\"
local textures = {
    ["克尔苏加德"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\克尔苏加德.blp",
    ["冰吼"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\冰吼.blp",
    ["加亚莱"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\加亚莱.blp",
    ["加兹兰卡"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\加兹兰卡.blp",
    ["加拉克苏斯大王"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\加拉克苏斯大王.blp",
    ["卡雷苟斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\卡雷苟斯.blp",
    ["哈卡"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\哈卡.blp",
    ["哈尔拉兹"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\哈尔拉兹.blp",
    ["埃基尔松"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\埃基尔松.blp",
    ["基尔加丹"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\基尔加丹.blp",
    ["塔迪乌斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\塔迪乌斯.blp",
    ["天启四骑士"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\天启四骑士.blp",
    ["妖术师金度"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\妖术师金度.blp",
    ["妖术领主玛拉卡斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\妖术领主玛拉卡斯.blp",
    ["布鲁塔卢斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\布鲁塔卢斯.blp",
    ["帕奇维克"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\帕奇维克.blp",
    ["收割者戈提克"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\收割者戈提克.blp",
    ["教官拉苏维奥斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\教官拉苏维奥斯.blp",
    ["格拉斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\格拉斯.blp",
    ["格罗布鲁斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\格罗布鲁斯.blp",
    ["洛欧塞布"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\洛欧塞布.blp",
    ["熵魔"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\熵魔.blp",
    ["玛里苟斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\玛里苟斯.blp",
    ["瓦格里双子"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\瓦格里双子.blp",
    ["祖尔金"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\祖尔金.blp",
    ["穿刺者戈莫克"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\穿刺者戈莫克.blp",
    ["纳洛拉克"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\纳洛拉克.blp",
    ["肮脏的希尔盖"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\肮脏的希尔盖.blp",
    ["艾瑞达双子"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\艾瑞达双子.blp",
    ["药剂师诺斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\药剂师诺斯.blp",
    ["菲米丝"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\菲米丝.blp",
    ["萨塔里奥"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\萨塔里奥.blp",
    ["萨菲隆"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\萨菲隆.blp",
    ["血领主曼多基尔"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\血领主曼多基尔.blp",
    ["迈克斯纳"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\迈克斯纳.blp",
    ["酸喉&恐鳞"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\酸喉&恐鳞.blp",
    ["阵营冠军"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\阵营冠军.blp",
    ["阿努巴拉克"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\阿努巴拉克.blp",
    ["阿努布雷坎"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\阿努布雷坎.blp",
    ["高阶祭司塞卡尔"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\高阶祭司塞卡尔.blp",
    ["高阶祭司娅尔罗"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\高阶祭司娅尔罗.blp",
    ["高阶祭司温诺希斯"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\高阶祭司温诺希斯.blp",
    ["高阶祭司玛尔里"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\高阶祭司玛尔里.blp",
    ["高阶祭司耶克里克"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\高阶祭司耶克里克.blp",
    ["黑女巫法琳娜"] = ROOT .. "Textures\\Cardfront\\cardfront1\\cardboss1\\黑女巫法琳娜.blp",
}
Addon.BossTextures = textures

-- Boss触发名称与贴图文件名历史上并不完全一致。先把旧目录转换为
-- 当前的Boss目录，再交给正面样式解析器，以便自动跟随卡牌样式选择。
-- 这不会影响Boss名称、NPC ID、遭遇战ID或触发逻辑。
function Addon:ResolveBossFrontTexture(texture)
    if not texture then
        return Addon:GetCardBackTexture()
    end

    texture = texture:gsub("\\cardboss1\\", "\\Boss\\")
    texture = texture:gsub("\\熵魔%.blp$", "\\穆鲁.blp")
    texture = texture:gsub("\\Boss\\阵营冠军%.blp$", "\\cardunkown.blp")

    if Addon.ResolveCardFrontTexture then
        return Addon:ResolveCardFrontTexture(texture)
    end
    return texture
end

local aliases = {
    ["加拉克苏斯"] = "加拉克苏斯大王",
    ["北地猛兽"] = "冰吼",
    ["玛克斯纳"] = "迈克斯纳",
    ["瓦格里双子"] = "瓦格里双子",
    ["瘟疫使者诺斯"] = "药剂师诺斯",
    ["穆鲁"] = "熵魔",
    ["艾瑞达双子"] = "艾瑞达双子",
    ["诺斯"] = "药剂师诺斯",
    ["诺森德猛兽"] = "冰吼",
    ["酸喉和恐鳞"] = "酸喉&恐鳞",
    ["阿努巴拉克"] = "阿努巴拉克",
    ["高阶女祭司娅尔罗"] = "高阶祭司娅尔罗",
    ["高阶女祭司玛尔里"] = "高阶祭司玛尔里",
    ["高阶女祭司耶克里克"] = "高阶祭司耶克里克",
}
local npcNames = {
    [11380] = "妖术师金度",
    [11382] = "血领主曼多基尔",
    [14507] = "高阶祭司温诺希斯",
    [14509] = "高阶祭司塞卡尔",
    [14510] = "高阶祭司玛尔里",
    [14515] = "高阶祭司娅尔罗",
    [14517] = "高阶祭司耶克里克",
    [14834] = "哈卡",
    [15114] = "加兹兰卡",
    [15928] = "塔迪乌斯",
    [15931] = "格罗布鲁斯",
    [15932] = "格拉斯",
    [15936] = "肮脏的希尔盖",
    [15952] = "迈克斯纳",
    [15953] = "黑女巫法琳娜",
    [15954] = "药剂师诺斯",
    [15956] = "阿努布雷坎",
    [15989] = "萨菲隆",
    [15990] = "克尔苏加德",
    [16011] = "洛欧塞布",
    [16028] = "帕奇维克",
    [16060] = "收割者戈提克",
    [16061] = "教官拉苏维奥斯",
    [16062] = "天启四骑士",
    [16063] = "天启四骑士",
    [16064] = "天启四骑士",
    [16065] = "天启四骑士",
    [17544] = "熵魔",
    [20350] = "克尔苏加德",
    [20423] = "克尔苏加德",
    [23574] = "埃基尔松",
    [23576] = "纳洛拉克",
    [23577] = "哈尔拉兹",
    [23578] = "加亚莱",
    [23863] = "祖尔金",
    [24144] = "哈尔拉兹",
    [24239] = "妖术领主玛拉卡斯",
    [24363] = "妖术领主玛拉卡斯",
    [24844] = "卡雷苟斯",
    [24848] = "卡雷苟斯",
    [24850] = "卡雷苟斯",
    [24882] = "布鲁塔卢斯",
    [24891] = "卡雷苟斯",
    [25038] = "菲米丝",
    [25158] = "布鲁塔卢斯",
    [25165] = "艾瑞达双子",
    [25166] = "艾瑞达双子",
    [25315] = "基尔加丹",
    [25319] = "卡雷苟斯",
    [25465] = "克尔苏加德",
    [25608] = "基尔加丹",
    [25741] = "熵魔",
    [25840] = "熵魔",
    [25960] = "熵魔",
    [26310] = "玛里苟斯",
    [28357] = "教官拉苏维奥斯",
    [28514] = "纳洛拉克",
    [28515] = "加亚莱",
    [28516] = "埃基尔松",
    [28517] = "哈尔拉兹",
    [28658] = "收割者戈提克",
    [28859] = "玛里苟斯",
    [28860] = "萨塔里奥",
    [28890] = "收割者戈提克",
    [28919] = "药剂师诺斯",
    [29021] = "埃基尔松",
    [29022] = "哈尔拉兹",
    [29023] = "加亚莱",
    [29024] = "纳洛拉克",
    [29112] = "收割者戈提克",
    [29113] = "药剂师诺斯",
    [29120] = "阿努巴拉克",
    [29655] = "玛里苟斯",
    [30549] = "天启四骑士",
    [31099] = "帕奇维克",
    [31734] = "玛里苟斯",
    [33535] = "玛里苟斯",
    [34496] = "瓦格里双子",
    [34497] = "瓦格里双子",
    [34564] = "阿努巴拉克",
    [34660] = "阿努巴拉克",
    [34780] = "加拉克苏斯大王",
    [34796] = "穿刺者戈莫克",
    [34797] = "冰吼",
    [34799] = "酸喉&恐鳞",
    [35144] = "酸喉&恐鳞",
    [35469] = "穿刺者戈莫克",
    [35470] = "冰吼",
    [38017] = "卡雷苟斯",
}
local encounterNames = {
    [629] = "冰吼",
    [633] = "加拉克苏斯大王",
    [637] = "阵营冠军",
    [641] = "瓦格里双子",
    [645] = "阿努巴拉克",
    [724] = "卡雷苟斯",
    [725] = "布鲁塔卢斯",
    [726] = "菲米丝",
    [727] = "艾瑞达双子",
    [728] = "熵魔",
    [729] = "基尔加丹",
    [784] = "高阶祭司温诺希斯",
    [785] = "高阶祭司耶克里克",
    [786] = "高阶祭司玛尔里",
    [787] = "血领主曼多基尔",
    [789] = "高阶祭司塞卡尔",
    [790] = "加兹兰卡",
    [791] = "高阶祭司娅尔罗",
    [792] = "妖术师金度",
    [793] = "哈卡",
    [1085] = "阿努巴拉克",
    [1086] = "阵营冠军",
    [1087] = "加拉克苏斯大王",
    [1088] = "冰吼",
    [1089] = "瓦格里双子",
    [1090] = "萨塔里奥",
    [1094] = "玛里苟斯",
    [1107] = "阿努布雷坎",
    [1108] = "格拉斯",
    [1109] = "收割者戈提克",
    [1110] = "黑女巫法琳娜",
    [1111] = "格罗布鲁斯",
    [1112] = "肮脏的希尔盖",
    [1113] = "教官拉苏维奥斯",
    [1114] = "克尔苏加德",
    [1115] = "洛欧塞布",
    [1116] = "迈克斯纳",
    [1117] = "药剂师诺斯",
    [1118] = "帕奇维克",
    [1119] = "萨菲隆",
    [1120] = "塔迪乌斯",
    [1121] = "天启四骑士",
    [1189] = "埃基尔松",
    [1190] = "纳洛拉克",
    [1191] = "加亚莱",
    [1192] = "哈尔拉兹",
    [1193] = "妖术领主玛拉卡斯",
    [1194] = "祖尔金",
    [2482] = "埃基尔松",
    [2483] = "纳洛拉克",
    [2484] = "加亚莱",
    [2485] = "哈尔拉兹",
    [2486] = "妖术领主玛拉卡斯",
    [2487] = "祖尔金",
    [2488] = "卡雷苟斯",
    [2489] = "布鲁塔卢斯",
    [2490] = "菲米丝",
    [2491] = "艾瑞达双子",
    [2492] = "熵魔",
    [2493] = "基尔加丹",
}
local groupMembers = {
    [16062] = {"天启四骑士", 4, 4},
    [16063] = {"天启四骑士", 1, 4},
    [16064] = {"天启四骑士", 2, 4},
    [16065] = {"天启四骑士", 3, 4},
    [25165] = {"艾瑞达双子", 1, 2},
    [25166] = {"艾瑞达双子", 2, 2},
    [30549] = {"天启四骑士", 4, 4},
    [34496] = {"瓦格里双子", 2, 2},
    [34497] = {"瓦格里双子", 1, 2},
    [34799] = {"酸喉&恐鳞", 2, 2},
    [35144] = {"酸喉&恐鳞", 1, 2},
}
local championIDs = { [34458] = true, [34451] = true, [34459] = true, [34448] = true, [34449] = true, [34445] = true, [34456] = true, [34447] = true, [34441] = true, [34454] = true, [34444] = true, [34455] = true, [34450] = true, [34453] = true, [34461] = true, [34460] = true, [34469] = true, [34467] = true, [34468] = true, [34471] = true, [34465] = true, [34466] = true, [34473] = true, [34472] = true, [34470] = true, [34463] = true, [34474] = true, [34475] = true }
local queue, recent, deadMembers = {}, {}, {}
local championCombat = false
local current, elapsed = nil, 0
local sounds = {}
local events = CreateFrame("Frame")
local frame = CreateFrame("Frame", "CardMasterBossFrame", UIParent)
frame:SetSize(1, 1)
-- Boss loot is usually clicked the instant the encounter ends.  Keep this
-- celebratory animation beneath every normal game dialog, especially loot
-- windows, so it can never cover their controls.
frame:SetFrameStrata("BACKGROUND")
frame:EnableMouse(false)
frame:Hide()
local dragFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
dragFrame:SetSize(1200, 500)
dragFrame:SetFrameStrata("DIALOG")
Addon:CreateMoveCanvas(dragFrame, "boss")
if dragFrame.SetClampedToScreen then dragFrame:SetClampedToScreen(false) end
dragFrame:EnableMouse(false)
dragFrame:SetMovable(true)
dragFrame:RegisterForDrag("LeftButton")
dragFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
dragFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local c = Addon.db and Addon.db.modules and Addon.db.modules.boss
    local x, y = self:GetCenter()
    local cx, cy = UIParent:GetCenter()
    if c and x and y and cx and cy then
        c.posX, c.posY = x - cx, y - cy
        Boss.UpdateSettings()
    end
end)
dragFrame:Hide()

local function Config() return Addon.db and Addon.db.modules.boss end
local function Enabled() local c = Config(); return c and c.enabled end
local function Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function Element(width, height, x, y, texture, level, blend)
    local f = CreateFrame("Frame", nil, frame)
    f:SetSize(width, height)
    f:SetPoint("CENTER", frame, "CENTER", x, y)
    f:SetFrameLevel(frame:GetFrameLevel() + level)
    f:EnableMouse(false)
    f.texture = f:CreateTexture(nil, "ARTWORK")
    f.texture:SetAllPoints(f)
    f.texture:SetTexture(texture)
    f.texture:SetBlendMode(blend or "BLEND")
    f:Hide()
    return f
end

local rightBand = Element(600, 250, 299, 0, ROOT .. "Textures\\Assets\\gradient.tga", 1)
local leftBand = Element(600, 250, -299, 0, ROOT .. "Textures\\Assets\\gradient.tga", 1)
rightBand.texture:SetVertexColor(0, 0, 0, 1)
leftBand.texture:SetVertexColor(0, 0, 0, 1)
leftBand.texture:SetRotation(math.pi)
local textFrame = CreateFrame("Frame", nil, frame)
textFrame:SetAllPoints(frame)
textFrame:SetFrameLevel(frame:GetFrameLevel() + 2)
textFrame.text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
textFrame.text:SetFont(ROOT .. "Textures\\Assets\\Myriad.ttf", 100, "")
textFrame.text:SetPoint("CENTER", textFrame, "CENTER")
textFrame.text:SetText("Encounter slain")
textFrame.text:SetTextColor(1, 1, 1, 0.6764707)
local leftParticles = Element(720, 180, -370, 0, ROOT .. "Textures\\Assets\\particles.blp", 3, "ADD")
local rightParticles = Element(720, 180, 370, 0, ROOT .. "Textures\\Assets\\particles.blp", 3, "ADD")
local card = Element(470, 470, 0, 0, nil, 4)
local kick = Element(200, 50, 0, -52, ROOT .. "Textures\\Assets\\kick.blp", 5)
local elements = {leftBand, rightBand, textFrame, leftParticles, rightParticles, card, kick}

local function HideElements()
    for _, f in ipairs(elements) do f:Hide() end
end

-- Sprite layouts and timing are taken from the supplied WA export.
local function Sprite(f, t, fps, rows, columns, reverse, loop)
    local index = math.floor(math.max(0, t) * fps)
    if loop then index = index % 64 else index = math.min(63, index) end
    if reverse then index = 63 - index end
    local col, row = index % columns, math.floor(index / columns)
    f.texture:SetTexCoord(col / columns, (col + 1) / columns, row / rows, (row + 1) / rows)
end

local function SoundOnce(key, path)
    if current[key] then return end
    local config = Config()
    if not config or config.soundEnabled == false then return end
    current[key] = true
    local _, handle = PlaySoundFile(ROOT .. "Audio\\Boss\\" .. path, "Master")
    if handle then sounds[#sounds + 1] = handle end
end

-- The card stays two seconds less; background effects remain three seconds longer.
local EFFECT_START, EFFECT_FADE_START, EFFECT_END = 2, 7.5, 7.75
local CARD_START, CARD_ENTRY_END = 3.5, 3.9
-- Keep the card on screen two seconds longer before its exit animation.
local CARD_EXIT_START, CARD_END = 8.5, 8.8
-- Kick is shifted 1.5 seconds earlier as a complete animation segment.
local KICK_START, KICK_FADE_START, KICK_END = CARD_START + 0.5, 6, 6.25

local function Render(t)
    HideElements()
    if t >= EFFECT_START and t < EFFECT_END then
        local u = t - EFFECT_START
        local alpha = t < EFFECT_FADE_START and 1 or Clamp((EFFECT_END - t) / 0.25, 0, 1)
        local height = 250 * (u < 0.3 and (1 - (1 - u / 0.3)^3) or 1)
        for _, f in ipairs({leftBand, rightBand}) do
            f:SetSize(600, math.max(1, height)); f:SetAlpha(alpha); f:Show()
        end
        textFrame:SetAlpha(math.min(1, u / 0.25) * alpha)
        textFrame:Show()
        if t < EFFECT_FADE_START then
            Sprite(leftParticles, u, 40, 64, 1, true, true)
            Sprite(rightParticles, u, 40, 64, 1, false, true)
            leftParticles:SetAlpha(1); rightParticles:SetAlpha(1)
            leftParticles:Show(); rightParticles:Show()
        end
        SoundOnce("textSound", "sonar.ogg")
    end
    if t >= KICK_START and t < KICK_END then
        Sprite(kick, t - KICK_START, 32, 16, 4, false, false)
        kick:SetAlpha(t < KICK_FADE_START and 1 or Clamp((KICK_END - t) / 0.25, 0, 1))
        kick:Show()
        SoundOnce("kickSound", "throwknife.ogg")
    end
    if t >= CARD_START and t < CARD_END then
        local x, y, sx, sy, rotation, alpha = 0, 0, 1, 1, 0, 1
        if t < CARD_ENTRY_END then
            local p = Clamp((t - CARD_START) / 0.4, 0, 1)
            local q = 1 - p -- WA reverses progress for start animations.
            x, y = -150 * math.sin(q * math.pi), 50 * math.sin(q * math.pi)
            local flipAngle = q * math.pi
            sx, sy = 0.7 * math.abs(math.cos(flipAngle)), 1 - 0.3 * q
            rotation, alpha = 10 * math.sin(q * 2 * math.pi), p
            -- As in the single-spell card, the first half of the flip uses the back.
            card.texture:SetTexture(flipAngle > (math.pi / 2) and Addon:GetCardBackTexture() or card.frontTexture)
        elseif t >= CARD_EXIT_START then
            local p = Clamp((t - CARD_EXIT_START) / 0.3, 0, 1)
            x, y = 50 * p, -50 * p
            sx, sy = 0.7 * math.cos(p * 2 * math.pi), 1 - 0.3 * p
            rotation, alpha = 10 * p, 1 - p
            card.texture:SetTexture(card.frontTexture)
        else
            card.texture:SetTexture(card.frontTexture)
        end
        card:SetSize(470 * math.max(0.01, math.abs(sx)), 470 * sy)
        card:ClearAllPoints()
        card:SetPoint("CENTER", frame, "CENTER", x, y)
        card.texture:SetTexCoord(0, 1, 0, 1)
        card.texture:SetRotation(math.rad(rotation))
        card:SetAlpha(alpha)
        card:Show()
        SoundOnce("cardSound", "Next.ogg")
    end
end

function Boss.UpdateSettings()
    local c = Config()
    if not c then return end
    c.speed = Clamp(tonumber(c.speed) or 1, 0.5, 2)
    c.scale = Clamp(tonumber(c.scale) or 1, 0.5, 2)
    frame:SetScale(c.scale)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", c.posX or 0, c.posY or 200)
    if dragFrame:IsShown() then
        dragFrame:SetScale(c.scale)
        dragFrame:ClearAllPoints()
        dragFrame:SetPoint("CENTER", UIParent, "CENTER", c.posX or 0, c.posY or 200)
    end
end

function Boss.ToggleDragMode()
    if not Enabled() then return false end
    local c = Config()
    if dragFrame:IsShown() then
        dragFrame:StopMovingOrSizing()
        dragFrame:Hide()
        dragFrame:EnableMouse(false)
        return false
    end
    Boss.UpdateSettings()
    dragFrame:SetScale(c.scale or 1)
    dragFrame:ClearAllPoints()
    dragFrame:SetPoint("CENTER", UIParent, "CENTER", c.posX or 0, c.posY or 200)
    dragFrame:Show()
    dragFrame:EnableMouse(true)
    return true
end

function Boss.IsDragging() return dragFrame:IsShown() end

local function StartNext()
    sounds = {}
    current = table.remove(queue, 1)
    elapsed = 0
    HideElements()
    if not current then frame:Hide(); frame:SetScript("OnUpdate", nil); return end
    card.frontTexture = Addon:ResolveBossFrontTexture(textures[current.name])
    card.texture:SetTexture(card.frontTexture)
    Boss.UpdateSettings()
    frame:Show()
end

local function OnUpdate(_, delta)
    if not Enabled() then Boss.Stop(); return end
    elapsed = elapsed + delta * (Config().speed or 1)
    if elapsed >= CARD_END then StartNext() else Render(elapsed) end
end

function Boss.Stop()
    queue, current, recent, deadMembers = {}, nil, {}, {}
    championCombat = false
    frame:SetScript("OnUpdate", nil)
    dragFrame:StopMovingOrSizing()
    dragFrame:Hide()
    dragFrame:EnableMouse(false)
    HideElements()
    frame:Hide()
    for _, handle in ipairs(sounds) do StopSound(handle) end
    sounds = {}
end

local function Resolve(name, encounterID)
    return encounterNames[encounterID] or aliases[name] or (textures[name] and name)
end

local function RandomPreviewBossName()
    local chosen, count
    for bossName in pairs(textures) do
        -- 阵营冠军没有独立正面图，只在实际触发时显示未知卡面。
        if bossName ~= "阵营冠军" then
            count = (count or 0) + 1
            if math.random(count) == 1 then chosen = bossName end
        end
    end
    return chosen
end

function Boss.Play(name, preview)
    if not Enabled() then return false end
    if preview then name = RandomPreviewBossName() end
    local canonical = Resolve(name)
    if not canonical and preview then canonical = "妖术领主玛拉卡斯" end
    if not canonical or not textures[canonical] then return false end
    local now = GetTime()
    if not preview and recent[canonical] and now - recent[canonical] < 30 then return false end
    if not preview then recent[canonical] = now end
    queue[#queue + 1] = {name = canonical}
    if not current then StartNext(); frame:SetScript("OnUpdate", OnUpdate) end
    return true
end

local function NpcID(guid)
    if type(guid) ~= "string" then return end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
end

events:SetScript("OnEvent", function(_, event, ...)
    if not Enabled() then return end
    if event == "PLAYER_LEAVING_WORLD" then Boss.Stop(); return end
    if event == "ENCOUNTER_START" then
        deadMembers = {}; championCombat = false
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        deadMembers = {}
        return
    end
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "raid" and instanceType ~= "party") then return end
    if event == "BOSS_KILL" then
        local id, name = ...
        Boss.Play(Resolve(name, id))
    elseif event == "ENCOUNTER_END" then
        local id, name, _, _, success = ...
        if success == 1 then Boss.Play(Resolve(name, id)) end
        deadMembers = {}; championCombat = false
    elseif event == "CHAT_MSG_MONSTER_YELL" then
        local message = ...
        -- Older Coliseum clients may only signal champions completion via this yell.
        if championCombat and GetTime() - championCombat < 30 and (message == "荣耀归于联盟！" or message == "那只是让你们知道将来必须面对的命运。为了部落！") then
            Boss.Play("阵营冠军"); championCombat = false
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, sourceGUID, _, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
        local id, sourceID = NpcID(destGUID), NpcID(sourceGUID)
        if championIDs[id] or championIDs[sourceID] then championCombat = GetTime() end
        if subevent ~= "UNIT_DIED" or not id then return end
        local member = groupMembers[id]
        if member then
            local name, slot, required = unpack(member)
            deadMembers[name] = deadMembers[name] or {}
            deadMembers[name][slot] = true
            local count = 0
            for _ in pairs(deadMembers[name]) do count = count + 1 end
            if count >= required then Boss.Play(name) end
        elseif id ~= 25741 and not championIDs[id] then
            -- Entropius, not M'uru's first phase, completes that encounter.
            Boss.Play(npcNames[id] or Resolve(destName))
        end
    end
end)

function Boss.SetEnabled(enabled)
    if Config() then Config().enabled = enabled and true or false end
    events:UnregisterAllEvents()
    if not enabled then Boss.Stop(); return end
    local eventList = {"BOSS_KILL", "ENCOUNTER_END", "ENCOUNTER_START", "PLAYER_REGEN_ENABLED", "PLAYER_LEAVING_WORLD"}
    -- Retail boss/encounter events identify completed encounters without
    -- reading secret combat-log unit identities. Classic retains its special
    -- encounter fallbacks below.
    if not Addon:IsRetail() then
        eventList[#eventList + 1] = "COMBAT_LOG_EVENT_UNFILTERED"
        eventList[#eventList + 1] = "CHAT_MSG_MONSTER_YELL"
    end
    for _, event in ipairs(eventList) do
        events:RegisterEvent(event)
    end
    Boss.UpdateSettings()
end

function Boss.ResetToDefault()
    Boss.Stop()
    local c = Config()
    for key, value in pairs(Addon.defaults.modules.boss) do
        if key ~= "enabled" then c[key] = value end
    end
    Boss.UpdateSettings()
end

function Addon:InitBossModule() self.Boss.SetEnabled(self.db.modules.boss.enabled) end
