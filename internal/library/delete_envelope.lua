-- @description Delete envelope at mouse
-- @version 1.2
-- @author me2beats
-- @changelog
--  + init

local log = require("utils.log")
local chunk_functions = require("utils.chunk_functions")
local function GetTrackChunk(track)
    if not track then
        return
    end
    local fast_str, track_chunk
    fast_str = reaper.SNM_CreateFastString("")
    if reaper.SNM_GetSetObjectState(track, fast_str, false, false) then
        track_chunk = reaper.SNM_GetFastString(fast_str)
    end
    reaper.SNM_DeleteFastString(fast_str)
    return track_chunk
end

local function SetTrackChunk(track, track_chunk)
    if not (track and track_chunk) then
        return
    end
    local fast_str, ret
    fast_str = reaper.SNM_CreateFastString("")
    if reaper.SNM_SetFastString(fast_str, track_chunk) then
        ret = reaper.SNM_GetSetObjectState(track, fast_str, true, false)
    end
    reaper.SNM_DeleteFastString(fast_str)
    return ret
end

local function esc(str)
    str = str:gsub("%(", "%%(")
    str = str:gsub("%)", "%%)")
    str = str:gsub("%.", "%%.")
    str = str:gsub("%+", "%%+")
    str = str:gsub("%-", "%%-")
    str = str:gsub("%$", "%%$")
    str = str:gsub("%[", "%%[")
    str = str:gsub("%]", "%%]")
    str = str:gsub("%*", "%%*")
    str = str:gsub("%?", "%%?")
    str = str:gsub("%^", "%%^")
    str = str:gsub("/", "%%/")
    return str
end

return function(env)
    reaper.ClearConsole()
    if not reaper.ValidatePtr(env, "TrackEnvelope*") then
        return
    end

    reaper.PreventUIRefresh(1)

    local tr = reaper.Envelope_GetParentTrack(env)
    local chunk = GetTrackChunk(tr)

    if not chunk then
        return
    end

    local target_guid = require("utils.arrange_funcs").GetEnvelopeGUID(env)

    -- TODO: here I need to check for builtins as well, eg vol/pan/route, etc.

    -- local ranges = {
    --     "PARMENV",
    --     "VOLENV",
    --     "PANENV",
    --     "WIDTHENV",
    --     "MUTEENV",
    --     "SPEEDENV",
    --     "PITCHENV",
    --     "TEMPOENV",
    -- }

    local x = -1
    for env_chunk in chunk:gmatch("<PARMENV.->") do
        x = x + 1
        local guid = chunk_functions.get_chunk_val(env_chunk, "EGUID")
        if target_guid == guid then
            chunk = chunk:gsub(esc(env_chunk) .. "\n", "", 1)
            break
        end
    end

    SetTrackChunk(tr, chunk)

    reaper.PreventUIRefresh(-1)
end
