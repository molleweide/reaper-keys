local format = require('utils.format')
local log = require('utils.log')
local utils = require('custom_actions.utils')

-- move everything here to the routing library

local sends = {}

local TRACK_INFO_AUDIO_SRC_DISABLED = -1
local TRACK_INFO_MIDIFLAGS_ALL_CHANS = 0
local TRACK_INFO_MIDIFLAGS_DISABLED = 4177951
local TRACK_INFO_SEND_CATEGORY = 0 -- send


function get_send_flags_dest(flags)
  return flags >> 5
end

function get_send_flags_src(flags)
  return flag & ((1 << 5) - 1) -- flag & 0x11111
end

function create_send_flags(src_chan, dest_chan)
  return (dest_chan << 5) | src_chan
end

-- TODO
--  - move this to library function?
--  - add default source channel = all or 1?
function sends.createSend(src_obj,dest_obj,dest_chan)
  -- log.user('>'..src_obj.name)
  -- log.user(dest_obj)
  local src_obj_trk, src_idx  =  utils.getTrackByGUID(src_obj.guid)-- reaper.GetTrack(0,src_obj.trackIndex)
  local dest_obj_trk, dst_idx = utils.getTrackByGUID(dest_obj.guid)--reaper.GetTrack(0,dest_obj.trackIndex)
  -- log.user('createSend() for: ' .. src_obj.name)

  local midi_send = reaper.CreateTrackSend(src_obj_trk, dest_obj_trk) -- create send; return sendidx for reference

  local new_midi_flags = create_send_flags(0, dest_chan) -- create new incremented midi channel

  reaper.SetTrackSendInfo_Value(src_obj_trk, TRACK_INFO_SEND_CATEGORY, midi_send, "I_MIDIFLAGS", new_midi_flags) -- set midi_flags on reference
  reaper.SetTrackSendInfo_Value(src_obj_trk, TRACK_INFO_SEND_CATEGORY, midi_send, "I_SRCCHAN", TRACK_INFO_AUDIO_SRC_DISABLED)
end


function sends.removeAllSends(trk_obj)
  local tr, tr_idx = utils.getTrackByGUID(trk_obj.guid)--reaper.GetTrack(0,trk_obj.trackIndex)
  local num_sends = reaper.GetTrackNumSends(tr, TRACK_INFO_SEND_CATEGORY)
  -- log.user('rm all s: ' .. trk_obj.trackIndex .. '|' .. trk_obj.name .. ' | num_s: ' .. num_sends)

  if num_sends == 0 then return end

  while(num_sends > 0)
    do
      for si=0, num_sends-1 do
        local rm = reaper.RemoveTrackSend(tr, TRACK_INFO_SEND_CATEGORY, si)
        --log.user('rm si: ' .. si ..', ' .. tostring(rm))
      end
      num_sends = reaper.GetTrackNumSends(tr, TRACK_INFO_SEND_CATEGORY)
    end
    --log.user('<DONE!>')
    return true
end

return sends
