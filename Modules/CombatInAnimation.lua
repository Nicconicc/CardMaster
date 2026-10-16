local _, Addon = ...

-- Code-driven version of 战斗开始卡牌动画_test.aep / Final.
-- Composition pixels/seconds, not sprite frames. Source artwork: 2675px at 20%.
local Animation = {
    width = 2048, height = 512, duration = 5.12, cardSize = 535,
    cardCount = 11,
}
Addon.CombatInAnimation = Animation

local function Ease(value)
    value = math.max(0, math.min(1, value))
    return value * value * (3 - 2 * value)
end

local function GetSelectedFrontFolder()
    local folder = "cardfront1"
    local selected = Addon.db and Addon.db.cardStyles and Addon.db.cardStyles.front or 1
    if Addon.GetCardFrontStyles then
        for _, style in ipairs(Addon:GetCardFrontStyles()) do
            if style.id == selected then folder = style.folder; break end
        end
    end
    return folder
end

-- Shuffle the logged-in character's own class cards.  A card is removed from
-- the candidate pool as soon as it is selected, so a single deal has no repeats.
function Animation.GetRandomClassDeck(count)
    local _, classToken = UnitClass("player")
    local classCards = Addon.Spells and Addon.Spells.ClassSpellTextures
        and Addon.Spells.ClassSpellTextures[classToken]
    if not classCards then return {} end

    local pool = {}
    local folder = GetSelectedFrontFolder()
    for spellName, texture in pairs(classCards) do
        -- Each card set keeps the same class/skill relative path.
        texture = texture:gsub("\\cardfront1\\", "\\" .. folder .. "\\", 1)
        pool[#pool + 1] = { name = spellName, texture = texture }
    end
    for index = #pool, 2, -1 do
        local replacement = math.random(index)
        pool[index], pool[replacement] = pool[replacement], pool[index]
    end

    local deck = {}
    for index = 1, math.min(count or Animation.cardCount, #pool) do
        deck[index] = pool[index]
    end
    return deck
end

local function RandomSigned(limit)
    limit = math.floor((tonumber(limit) or 0) + 0.5)
    if limit <= 0 then return 0 end
    return math.random(-limit, limit)
end

-- A layout is created once per deal, so offsets remain stable through the
-- entire rise, flip and exit of that card.
function Animation.CreateDealLayout()
    local db = Addon.legacyDB or {}
    local spacing = math.max(50, math.min(250, tonumber(db.ciCardSpacing) or 150))
    local randomX = math.max(0, math.min(200, tonumber(db.ciCardRandomX) or 0))
    local randomY = math.max(0, math.min(200, tonumber(db.ciCardRandomY) or 0))
    local randomRotation = math.max(0, math.min(45, tonumber(db.ciCardRandomRotation) or 0))
    local layout = {}
    for index = 1, Animation.cardCount do
        layout[index] = {
            spacing = spacing,
            x = RandomSigned(randomX),
            y = RandomSigned(randomY),
            rotation = RandomSigned(randomRotation),
        }
    end
    return layout
end

-- Reuse state tables instead of allocating them on every frame.
function Animation.Sample(index, time, state, layout)
    state = state or {}
    layout = layout or { spacing = 150, x = 0, y = 0, rotation = 0 }
    local order = index - 1
    local start = 0.96 + order * 0.04
    state.visible = time >= (index == 1 and 0 or start) and time < Animation.duration
    if not state.visible then return state end
    local spread = Ease((time - start) / 0.96)
    local distance = math.abs(order - 5)
    local finalY = 300 + distance * 5
    state.x = 1790 + (300 + order * layout.spacing + layout.x - 1790) * spread
    state.y = 325 + (finalY + layout.y - 325) * spread
    state.yaw = -120 + 120 * spread
    -- Follow the rendered video's +20 degree fan at the right edge.
    state.roll = -20 + order * 4 + layout.rotation * spread
    if index == 1 and time < 0.96 then
        local rise = Ease(time / 0.76)
        state.y = 806 + (325 - 806) * rise
        state.yaw = -180 + 60 * rise
        state.roll = -20 * rise
    end
    state.y = state.y + 359 * Ease((time - (4.20 + distance * 0.04)) / 0.68)
    state.back = state.yaw < -90
    return state
end

-- Perspective yaw followed by in-plane rotation, rendered with UI vertices.
function Animation.Project(state, u, v)
    local yaw, roll = math.rad(state.yaw), math.rad(state.roll)
    local x = (u - 0.5) * Animation.cardSize
    local y = (v - 0.5) * Animation.cardSize
    local rotatedX, depth = x * math.cos(yaw), -x * math.sin(yaw)
    local worldX = state.x + rotatedX * math.cos(roll) - y * math.sin(roll)
    local worldY = state.y + rotatedX * math.sin(roll) + y * math.cos(roll)
    local zoom = Animation.width * 50 / 36
    local perspective = zoom / (zoom + depth)
    return Animation.width / 2 + (worldX - Animation.width / 2) * perspective,
        Animation.height / 2 + (worldY - Animation.height / 2) * perspective
end
