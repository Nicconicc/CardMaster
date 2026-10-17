local _, Addon = ...
local units, activeEncounter, harvest, lootAction = {}, nil, nil, nil
local function public(value) return not (issecretvalue and issecretvalue(value)) end
local function call(fn, ...)
    if not fn then return nil end
    local ok, value = pcall(fn, ...)
    if ok and public(value) then return value end
end
local function stamp() return tostring(time()) .. ":" .. tostring(math.floor(GetTime() * 1000)) end

function Addon:GetCollectionGroupUnits()
    local result = {"player", "pet"}
    if IsInRaid and IsInRaid() then
        for i = 1, GetNumGroupMembers() do result[#result + 1] = "raid" .. i; result[#result + 1] = "raidpet" .. i end
    else
        for i = 1, 4 do result[#result + 1] = "party" .. i; result[#result + 1] = "partypet" .. i end
    end
    return result
end

function Addon:CollectionRememberUnit(unit)
    if type(unit) ~= "string" or not UnitExists(unit) then return end
    local guid = call(UnitGUID, unit)
    if type(guid) ~= "string" or not guid:match("^Creature%-") then return end
    local trivial = call(UnitIsTrivial, unit)
    local player = call(UnitIsPlayer, unit)
    local denied = call(UnitIsTapDenied, unit)
    local level = call(UnitLevel, unit)
    local eligible = trivial == false and player == false and denied ~= true
    if trivial == nil and type(level) == "number" then
        local own = UnitLevel("player")
        local grey = own <= 5 and 0 or (own <= 39 and own - 5 - math.floor(own / 10) or (own <= 59 and own - 1 - math.floor(own / 5) or own - 9))
        eligible = (level == -1 or level > grey) and player ~= true and denied ~= true
    end
    local previous = units[guid]
    units[guid] = { eligible = eligible, token = unit, at = GetTime(), involved = previous and previous.involved,
        name = call(UnitName, unit) }
end

function Addon:CollectionKill(guid, confirmedGroupKill)
    if not public(guid) then
        if not self.collectionRestrictedKillWarning then
            self.collectionRestrictedKillWarning = true
            self:CollectionPrint(self:CollectionText("客户端正在隐藏击杀身份，受限期间暂停击杀抽卡；其他收藏来源正常。", "Kill identities are restricted by the client. Kill rewards are paused while restricted; other collection sources remain available."))
        end
        return
    end
    if type(guid) ~= "string" or not guid:match("^Creature%-") then return end
    local info = units[guid]
    local npcText = select(6, strsplit("-", guid))
    local npc = tonumber(npcText)
    if confirmedGroupKill or (info and info.involved) then self:CollectionLegacyFinal(npc) end
    if not info or not info.eligible or GetTime() - info.at > 180 then return end
    if not confirmedGroupKill and not info.involved then return end
    self:CollectionAttempt(1, guid)
end

-- Numeric completion facts for clients without an Encounter Journal.
-- Multiple IDs are allowed only where a dungeon has genuinely separate exits
-- or a version replaced the final boss. No dependency on DBM is required.
local finalNPC = {
    [33] = {4275, 46964}, [34] = {1716, 46254}, [36] = {639, 645, 49541}, [43] = {3654},
    [47] = {4421}, [48] = {4829, 75408, 213334}, [70] = {2748}, [90] = {7800, 218537},
    [109] = {5709, 221394}, [129] = {7358, 74434}, [189] = {4543, 3977, 3976, 6487},
    [209] = {7267}, [229] = {9568, 10363}, [230] = {9019}, [249] = {10184},
    [269] = {17881}, [289] = {1853}, [309] = {14834}, [329] = {10440, 10813},
    [349] = {12201}, [389] = {11519, 61528}, [409] = {11502, 227939},
    [429] = {11492, 11496, 11501}, [469] = {11583}, [509] = {15339}, [531] = {15727},
    [532] = {15690}, [533] = {15990}, [534] = {17968}, [540] = {16808}, [542] = {17377},
    [543] = {17537}, [544] = {17257}, [545] = {17798}, [546] = {17882}, [547] = {17942},
    [548] = {21212}, [550] = {19622}, [552] = {20912}, [553] = {17977}, [554] = {19220},
    [555] = {18708}, [556] = {18473}, [557] = {18344}, [558] = {18373}, [560] = {18096},
    [564] = {22917}, [565] = {19044}, [568] = {23863}, [574] = {23954}, [575] = {26861},
    [576] = {26723}, [578] = {27656}, [580] = {25315}, [585] = {24664}, [595] = {26533},
    [599] = {27978}, [600] = {26632}, [601] = {29120}, [602] = {28923}, [603] = {33288},
    [604] = {29306}, [608] = {31134}, [615] = {28860}, [616] = {28859}, [619] = {29311},
    [624] = {38433}, [631] = {36597}, [632] = {36502}, [649] = {34564}, [650] = {35451},
    [658] = {36658}, [668] = {36954}, [724] = {39863},
    [643] = {42172, 213770}, [644] = {39378}, [645] = {39705}, [657] = {43875},
    [669] = {41376}, [670] = {40484}, [671] = {43324, 45213}, [725] = {42333},
    [754] = {46753}, [755] = {44819}, [757] = {55869}, [859] = {52148},
    [938] = {54432}, [939] = {54969}, [940] = {54938}, [967] = {56173},
    [960] = {56439}, [961] = {59479}, [959] = {56884}, [962] = {56877},
    [994] = {61398}, [1001] = {59150}, [1004] = {3977, 60040}, [1007] = {59080},
    [1011] = {62205}, [1008] = {60399, 60400}, [1009] = {62837}, [996] = {60999},
    [1098] = {68397, 69473}, [1136] = {71865},
}
local finalEncounter = { [2959] = 3312, [2998] = 3482, [2999] = 3412, [3065] = 3496 }

function Addon:CollectionZone()
    local db = self.collectionDB
    if not db then return end
    local _, kind, difficulty, _, _, _, _, map = GetInstanceInfo()
    local lfg = call(GetLFGDungeonID) or 0
    local key = (kind or "none") .. ":" .. tostring(map or 0) .. ":" .. tostring(difficulty or 0) .. ":" .. tostring(lfg)
    local run = db.run
    if kind ~= "party" and kind ~= "raid" and kind ~= "pvp" then db.run = nil; return end
    if type(run) ~= "table" or run.context ~= key then
        db.run = {context = key, key = stamp(), map = map, kind = kind, difficulty = difficulty, started = time()}
    end
    self:ScheduleCollectionSummary()
end

function Addon:CollectionInstanceComplete()
    local run = self.collectionDB and self.collectionDB.run
    if not run or (run.kind ~= "party" and run.kind ~= "raid") or run.done then return end
    -- Presence in the encounter or recent combat is required, not a final hit.
    if not run.participated then return end
    run.done = true
    self:CollectionAttempt(5, "instance:" .. run.context .. ":" .. run.key)
end

function Addon:CollectionLegacyFinal(npc)
    local run = self.collectionDB and self.collectionDB.run
    if not run or not npc then return end
    if run.map == 36 and run.difficulty == 2 and npc ~= 49541 then return end
    if run.map == 671 and (run.difficulty == 5 or run.difficulty == 6) and npc == 43324 then return end
    if run.map == 1098 and (run.difficulty == 5 or run.difficulty == 6) and npc == 68397 then return end
    for _, final in ipairs(finalNPC[run.map] or {}) do
        if npc == final then self:CollectionInstanceComplete(); return end
    end
end

function Addon:IsCollectionFinalEncounter(encounterName, encounterID)
    local run = self.collectionDB and self.collectionDB.run
    if not run then return false end
    if finalEncounter[run.map] == encounterID then return true end
    if C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap and EJ_GetEncounterInfoByIndex then
        local instance = call(C_EncounterJournal.GetInstanceForGameMap, run.map)
        if instance then
            local last
            for i = 1, 50 do
                local name = call(EJ_GetEncounterInfoByIndex, i, instance)
                if not name then break end
                last = name
            end
            if last and last == encounterName then return true end
        end
    end
    -- Also use the client's lock encounter list when available in Classic.
    if GetInstanceLockTimeRemaining and GetInstanceLockTimeRemainingEncounter then
        local _, count = GetInstanceLockTimeRemaining()
        if type(count) == "number" and count > 0 then
            local name = GetInstanceLockTimeRemainingEncounter(count)
            if name == encounterName then return true end
        end
    end
    return false
end

local function spellName(id)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(id)
        return info and info.name
    end
    return GetSpellInfo and GetSpellInfo(id)
end
local function harvestKind(id)
    if id == 7620 or id == 131474 then return 4 end
    if id == 2575 or id == 2366 or id == 8613 then return 3 end
    local name = spellName(id)
    if type(name) ~= "string" then return nil end
    for _, base in ipairs({2575, 2366, 8613}) do
        local match = spellName(base)
        if match and name:find(match, 1, true) then return 3 end
    end
    local fishing = spellName(7620)
    if fishing and name:find(fishing, 1, true) then return 4 end
end

function Addon:CollectionBattlegroundComplete()
    local run = self.collectionDB and self.collectionDB.run
    if not run or run.kind ~= "pvp" or run.done or not run.participated then return end
    if IsWargame and IsWargame() then return end
    if C_PvP and C_PvP.IsInBrawl and C_PvP.IsInBrawl() and C_PvP.GetActiveBrawlInfo then
        local info = C_PvP.GetActiveBrawlInfo()
        -- Comp Stomp is the player-versus-AI Arathi Basin variant.
        if info and info.brawlID == 15 then return end
    end
    run.done = true
    self:CollectionAttempt(6, "battleground:" .. run.context .. ":" .. run.key)
end

function Addon:CollectionCombatLog()
    if not CombatLogGetCurrentEventInfo then return end
    local _, sub, _, attacker, _, flags, _, target = CombatLogGetCurrentEventInfo()
    if not public(sub) or not public(target) or not public(attacker) then return end
    local grouped = false
    if type(flags) == "number" and public(flags) and bit then grouped = bit.band(flags, 7) ~= 0 end
    if sub == "PARTY_KILL" then self:CollectionKill(target, grouped); return end
    if sub == "UNIT_DIED" then self:CollectionKill(target, false); return end
    if grouped and units[target] then units[target].involved = true end
end

function Addon:CollectionEvent(event, ...)
    if event == "BN_CONNECTED" or event == "BN_INFO_CHANGED" or event == "PLAYER_LOGIN" then
        self:CheckCollectionIdentity()
        return
    elseif event == "CHAT_MSG_ADDON" then self:CollectionReceive(...); return
    elseif event == "GROUP_ROSTER_UPDATE" then self:ScheduleCollectionSummary(); return
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then self:CollectionZone(); return
    elseif event == "PLAYER_REGEN_ENABLED" then self:FlushCollectionNotices(); return
    elseif event == "PLAYER_REGEN_DISABLED" then
        local run = self.collectionDB and self.collectionDB.run
        if run then run.participated = true end
    elseif event == "PLAYER_TARGET_CHANGED" then self:CollectionRememberUnit("target")
    elseif event == "NAME_PLATE_UNIT_ADDED" then self:CollectionRememberUnit(...)
    elseif event == "UNIT_TARGET" then
        local unit = ...
        if public(unit) and type(unit) == "string" and (unit:match("^party%d+$") or unit:match("^raid%d+$")) then self:CollectionRememberUnit(unit .. "target") end
    elseif event == "PARTY_KILL" then
        local _, victim = ...
        self:CollectionKill(victim, true)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then self:CollectionCombatLog()
    elseif event == "QUEST_TURNED_IN" then
        local id = ...
        if public(id) and type(id) == "number" then self:CollectionAttempt(2, "quest:" .. id .. ":" .. time()) end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, cast, id = ...
        if unit == "player" and public(id) and type(id) == "number" then
            local kind = harvestKind(id)
            if kind then
                local key = public(cast) and type(cast) == "string" and cast or stamp()
                if not harvest or harvest.key ~= key then harvest = {source = kind, key = key} end
                harvest.at = GetTime()
                if event == "UNIT_SPELLCAST_SUCCEEDED" then
                    harvest.complete = true
                    if lootAction and lootAction.key == key and lootAction.taken and not lootAction.done then
                        lootAction.done = true; self:CollectionAttempt(kind, "harvest:" .. key)
                    end
                end
            end
        end
    elseif event == "LOOT_READY" or event == "LOOT_OPENED" then
        if not lootAction then
            local fishing = call(IsFishingLoot)
            if fishing then
                lootAction = {source = 4, key = harvest and harvest.source == 4 and harvest.key or stamp(), complete = true}
            elseif harvest and harvest.source == 3 and GetTime() - harvest.at < 8 then
                lootAction = harvest
            end
        end
    elseif event == "LOOT_SLOT_CLEARED" then
        if lootAction and not lootAction.done then
            lootAction.taken = true
            if lootAction.complete then lootAction.done = true; self:CollectionAttempt(lootAction.source, "harvest:" .. lootAction.key) end
        end
    elseif event == "LOOT_CLOSED" then lootAction, harvest = nil, nil
    elseif event == "ENCOUNTER_START" then
        local id, name = ...
        activeEncounter = {id = id, name = name, bosses = {}}
        local run = self.collectionDB and self.collectionDB.run
        if run and (run.kind == "party" or run.kind == "raid") then
            run.participated = call(UnitAffectingCombat, "player") and true or false
        end
        for i = 1, 8 do
            self:CollectionRememberUnit("boss" .. i)
            local guid = call(UnitGUID, "boss" .. i)
            if type(guid) == "string" then activeEncounter.bosses[#activeEncounter.bosses + 1] = guid end
        end
    elseif event == "ENCOUNTER_END" then
        local id, name, _, _, success = ...
        if success == 1 and activeEncounter and activeEncounter.id == id then
            if self:IsCollectionFinalEncounter(name, id) then self:CollectionInstanceComplete() end
            for _, guid in ipairs(activeEncounter.bosses) do
                local info = units[guid]
                if info and info.name == name then
                    -- Successful encounters can end without a physical death
                    -- (e.g. Mal'Ganis). Only this encounter's cached boss counts.
                    self:CollectionKill(guid, true)
                end
            end
        end
        activeEncounter = nil
    elseif event == "BOSS_KILL" then
        local id, name = ...
        if public(id) and public(name) and self:IsCollectionFinalEncounter(name, id) then self:CollectionInstanceComplete() end
    elseif event == "LFG_COMPLETION_REWARD" or event == "CHALLENGE_MODE_COMPLETED" then self:CollectionInstanceComplete()
    elseif event == "PVP_MATCH_COMPLETE" then self:CollectionBattlegroundComplete()
    elseif event == "UPDATE_BATTLEFIELD_STATUS" then
        if GetBattlefieldWinner and GetBattlefieldWinner() ~= nil then self:CollectionBattlegroundComplete() end
    end
end

function Addon:InitCollectionEvents()
    local frame = CreateFrame("Frame")
    self.collectionEventFrame = frame
    self.collectionEventSupport = {}
    for _, event in ipairs({"PLAYER_LOGIN", "BN_CONNECTED", "BN_INFO_CHANGED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
        "PLAYER_TARGET_CHANGED", "NAME_PLATE_UNIT_ADDED", "UNIT_TARGET", "PARTY_KILL", "QUEST_TURNED_IN",
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_SUCCEEDED", "LOOT_READY", "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_CLOSED",
        "ENCOUNTER_START", "ENCOUNTER_END", "BOSS_KILL", "LFG_COMPLETION_REWARD", "CHALLENGE_MODE_COMPLETED",
        "PVP_MATCH_COMPLETE", "UPDATE_BATTLEFIELD_STATUS", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
        "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE"}) do
        self.collectionEventSupport[event] = pcall(frame.RegisterEvent, frame, event)
    end
    if not self:IsRetail() then pcall(frame.RegisterEvent, frame, "COMBAT_LOG_EVENT_UNFILTERED") end
    frame:SetScript("OnEvent", function(_, event, ...) Addon:CollectionEvent(event, ...) end)
    -- Refresh visible target metadata sparingly; do not scan textures here.
    local elapsed, identityElapsed = 0, 0
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed, identityElapsed = elapsed + delta, identityElapsed + delta
        if identityElapsed >= 10 then identityElapsed = 0; Addon:CheckCollectionIdentity() end
        if elapsed < 0.5 then return end
        elapsed = 0
        Addon:CollectionRememberUnit("target")
        for guid, info in pairs(units) do if GetTime() - info.at > 180 then units[guid] = nil end end
    end)
end
