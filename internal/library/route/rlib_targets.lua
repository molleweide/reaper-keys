local ru = require('custom_actions.utils')
local log = require('utils.log')
local format = require('utils.format')
local tr_util = require('utils.track')
local table_util = require('utils.table')

local targets = {}

--    key = src_guid/dst_guids
--    new_track_data = (tr / tr_guid / tr_name / table)
function targets.setRouteTargetGuids(rp, key, new_tracks_data)
  local retval = false
  local log_str = 'new_tracks_data >>> '
  local tr_guids = {}

  if type(new_tracks_data) == 'string' then -- NOT TABLE ::::::::::::::

    -- single name str
    if tr_util.getMatchedTrackGUIDs(new_tracks_data) then
      local match_t = tr_util.getMatchedTrackGUIDs(new_tracks_data)
      if match_t ~= false then
         tr_guids = table_util.tableConcat(tr_guids, match_t)
      end

      -- single guid str
    elseif ru.getTrackByGUID(new_tracks_data) ~= false then
      retval = true
      local tr, tr_idx = ru.getTrackByGUID(new_tracks_data)
      local _, current_name = reaper.GetTrackName(tr)
      tr_guids = {{ name = current_name, guid = new_tracks_data }}

    else
      retval = false
      log.user('new tracks data NOT table but did not pass as STRING/GUID')
    end

  elseif type(new_tracks_data) == 'table' then -----------------------
    retval = true
    for i = 1, #new_tracks_data do

      -- table name string
      if tr_util.getMatchedTrackGUIDs(new_tracks_data[i]) then
        local match_t = tr_util.getMatchedTrackGUIDs(new_tracks_data[i])
        if match_t ~= false then
          tr_guids = table_util.tableConcat(tr_guids, match_t)
        end

        -- table id string
      elseif ru.getTrackByGUID(new_tracks_data[i]) ~= false then
        local tr, tr_idx = ru.getTrackByGUID(new_tracks_data[i])
        local _, current_name = reaper.GetTrackName(tr)
        tr_guids[i] = { name = current_name, guid = new_tracks_data[i] }

        -- table number string
      elseif tonumber(new_tracks_data[i]) ~= nil then
        local tr = reaper.GetTrack(0, tonumber(new_tracks_data[i]) - 1)
        local _, current_name = reaper.GetTrackName(tr)

        local guid_from_tr = ru.getGUIDByTrack(tr)
        tr_guids[i] = { name = current_name, guid = guid_from_tr }
      else
        -- retval = false
        log.user('new tracks data NOT table but did not pass as single string either')
      end
    end -- for
  end -- table

  if #tr_guids == 0 then retval = false end
  if retval then rp[key] = tr_guids end
  return retval, rp
end

return targets
