local _, Addon = ...

local PREFIX = "CMCFG1:"
local MAX_TEXT_LENGTH = 32000
local MAX_DEPTH = 8

local function getSchema()
    local integrated = {}
    for _, group in ipairs({ Addon.IntegratedDefaults.DEFAULT_SKILL, Addon.IntegratedDefaults.DEFAULT_COMBAT }) do
        for key, value in pairs(group) do integrated[key] = value end
    end
    return {
        language = Addon.defaults.language,
        showMinimapIcon = Addon.defaults.showMinimapIcon,
        hideWelcomeOnLogin = Addon.defaults.hideWelcomeOnLogin,
        collectionBroadcast = Addon.defaults.collectionBroadcast,
        collectionSettings = Addon:GetCollectionSettingsSchema(),
        cardStyles = Addon.defaults.cardStyles,
        modules = Addon.defaults.modules,
        integratedCards = integrated,
    }
end

-- Copy only supported settings. Never import arbitrary SavedVariables fields.
local function filtered(value, schema)
    if type(schema) == "table" then
        if value ~= nil and type(value) ~= "table" then return nil, false end
        local result = {}
        for key, default in pairs(schema) do
            local child, valid = filtered(value and value[key], default)
            if not valid then return nil, false end
            result[key] = child
        end
        return result, true
    end
    if value == nil then value = schema end
    if type(value) ~= type(schema) then return nil, false end
    if type(value) == "number" then
        if value ~= value or value == math.huge or value == -math.huge or math.abs(value) > 100000 then
            return nil, false
        end
    elseif type(value) == "string" and #value > 256 then
        return nil, false
    end
    return value, true
end

local function serialize(value, output, depth)
    if depth > MAX_DEPTH then error("configuration too deep") end
    local kind = type(value)
    if kind == "table" then
        output[#output + 1] = "{"
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys)
        for _, key in ipairs(keys) do
            serialize(key, output, depth + 1)
            serialize(value[key], output, depth + 1)
        end
        output[#output + 1] = "}"
    elseif kind == "string" then
        output[#output + 1] = "s" .. #value .. ":" .. value
    elseif kind == "number" then
        output[#output + 1] = "n" .. tostring(value) .. ";"
    elseif kind == "boolean" then
        output[#output + 1] = value and "t" or "f"
    else
        error("unsupported configuration value")
    end
end

local function parse(data, position, depth)
    if depth > MAX_DEPTH then error("configuration too deep") end
    local tag = data:sub(position, position)
    position = position + 1
    if tag == "{" then
        local result, count = {}, 0
        while data:sub(position, position) ~= "}" do
            if position > #data or count >= 512 then error("invalid table") end
            local key, value
            key, position = parse(data, position, depth + 1)
            value, position = parse(data, position, depth + 1)
            local validKey = type(key) == "string" or (type(key) == "number" and key >= 1 and key <= 1000 and key == math.floor(key))
            if not validKey or result[key] ~= nil then error("invalid key") end
            result[key] = value
            count = count + 1
        end
        return result, position + 1
    elseif tag == "s" then
        local colon = data:find(":", position, true)
        if not colon or colon - position > 5 then error("invalid string") end
        local length = tonumber(data:sub(position, colon - 1))
        if not length or length < 0 or length > MAX_TEXT_LENGTH or colon + length > #data then
            error("invalid string length")
        end
        return data:sub(colon + 1, colon + length), colon + length + 1
    elseif tag == "n" then
        local terminator = data:find(";", position, true)
        if not terminator or terminator - position > 24 then error("invalid number") end
        local raw = data:sub(position, terminator - 1)
        if not raw:match("^[%+%-%d%.eE]+$") then error("invalid number") end
        local value = tonumber(raw)
        if not value then error("invalid number") end
        return value, terminator + 1
    elseif tag == "t" then
        return true, position
    elseif tag == "f" then
        return false, position
    end
    error("invalid value")
end

local function checksum(data)
    local a, b = 1, 0
    for index = 1, #data do
        a = (a + data:byte(index)) % 65521
        b = (b + a) % 65521
    end
    return string.format("%04X%04X", b, a)
end

function Addon:ExportConfigString()
    local config, valid = filtered(self.db, getSchema())
    if not valid then return nil end
    local parts = {}
    serialize(config, parts, 0)
    local payload = table.concat(parts)
    if #payload > MAX_TEXT_LENGTH then return nil end
    local hex = payload:gsub(".", function(character)
        return string.format("%02X", character:byte())
    end)
    return PREFIX .. checksum(payload) .. ":" .. hex
end

function Addon:ImportConfigString(input)
    if type(input) ~= "string" then return nil end
    local compact = input:gsub("%s+", "")
    if #compact > MAX_TEXT_LENGTH * 2 + #("MCMCFG1:") + 9 then return nil end
    local suppliedChecksum, hex = compact:match("^CMCFG1:([0-9A-Fa-f]+):([0-9A-Fa-f]+)$")
    if not suppliedChecksum then suppliedChecksum, hex = compact:match("^MCMCFG1:([0-9A-Fa-f]+):([0-9A-Fa-f]+)$") end
    if not suppliedChecksum or #suppliedChecksum ~= 8 or #hex % 2 ~= 0 then return nil end
    local payload = hex:gsub("..", function(pair)
        return string.char(tonumber(pair, 16))
    end)
    if checksum(payload) ~= suppliedChecksum:upper() then return nil end
    local ok, config, position = pcall(parse, payload, 1, 0)
    if not ok or position ~= #payload + 1 or type(config) ~= "table" then return nil end
    if type(config.cardStyles) ~= "table" or type(config.modules) ~= "table"
        or type(config.integratedCards) ~= "table" then return nil end
    local clean, valid = filtered(config, getSchema())
    if not valid then return nil end
    if clean.language ~= "zhCN" and clean.language ~= "enUS" then return nil end
    return clean
end
