local _, Addon = ...
local CPU = {}
Addon.CPUUsage = CPU

local clock = debugprofilestop
local activeSample

local function read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
end

local function isMeasurement(value)
    return type(value) == "number" and value >= 0 and value < math.huge
end

local function nativePercent()
    local profiler = C_AddOnProfiler
    local metric = Enum and Enum.AddOnProfilerMetric and Enum.AddOnProfilerMetric.RecentAverageTime
    if not profiler or not metric then return end
    if type(profiler.IsEnabled) == "function" and read(profiler.IsEnabled) ~= true then return end
    local milliseconds = read(profiler.GetAddOnMetric, Addon.name, metric)
    local fps = read(GetFramerate)
    if isMeasurement(milliseconds) and isMeasurement(fps) and fps > 0 then
        return math.min(100, milliseconds * fps / 10)
    end
end

-- Only used for event and animation callbacks, whose return values are ignored.
function CPU.Measure(callback)
    return function(...)
        local sample = activeSample
        if not sample then return callback(...) end
        local started = clock()
        callback(...)
        if sample == activeSample then
            sample.usedMs = sample.usedMs + math.max(0, clock() - started)
        end
    end
end

function CPU.Reset(sample)
    if activeSample == sample then activeSample = nil end
    sample.elapsed, sample.usedMs = 0, 0
    sample.percent, sample.reason = nil, nil
end

function CPU.Sample(sample)
    local native = nativePercent()
    if native then
        activeSample = nil
        sample.percent, sample.reason = native, "modern"
    elseif type(clock) == "function" then
        sample.percent = nil
        if activeSample == sample and sample.elapsed >= 1 then
            sample.percent = math.min(100, sample.usedMs / (sample.elapsed * 10))
        end
        activeSample, sample.reason = sample, "estimate"
    else
        activeSample = nil
        sample.percent, sample.reason = nil, "unavailable"
    end
    sample.elapsed, sample.usedMs = 0, 0
end
