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
    -- local window, segment, details = r.BR_GetMouseCursorContext()
    -- local env, takeEnv = r.BR_GetMouseCursorContext_Envelope()
    -- if takeEnv then return end
    reaper.ClearConsole()

    -- if not env then
    --     return
    -- end

    if not reaper.ValidatePtr(env, "TrackEnvelope*") then
        return
    end

    reaper.PreventUIRefresh(1)

    local tr = reaper.Envelope_GetParentTrack(env)

    local envs = reaper.CountTrackEnvelopes(tr)

    local num

  local target_guid = require("utils.arrange_funcs").GetEnvelopeGUID(env)

    for i = 0, envs - 1 do
        local tr_env = reaper.GetTrackEnvelope(tr, i)
        if tr_env == env then
            num = i
            break
        end
    end

    local chunk = GetTrackChunk(tr)

    if not chunk then
        return
    end

    local x = -1
    for env_chunk in chunk:gmatch("<PARMENV.->") do
        x = x + 1

        local guid = chunk_functions.get_chunk_val(env_chunk, "EGUID")
        -- log.user(num, x, env_chunk, " GUID =",guid, target_guid == guid)
        log.user(string.format([[=========
        %s
        ----
        %s
        %s
        %s
        ]], env_chunk, target_guid, guid, target_guid == guid))

        if target_guid == guid then
            chunk = chunk:gsub(esc(env_chunk) .. "\n", "", 1)
            break
        end
    end

    SetTrackChunk(tr, chunk)

    reaper.PreventUIRefresh(-1)
end
