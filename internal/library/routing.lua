local reaper_utils = require('custom_actions.utils')
local log = require('utils.log')
local format = require('utils.format')
local routing_defaults = require('definitions.routing')

local routing = {}

-- ## todo
--
--    1. clean up code as much as possible.
--
--        - needs to be renamed into syntaxAddMidiSend so that I don't mix things up
--        - put all vars on top.
--        - what can be put in configs?
--
--    2. fix rm usage of syntax objects inside of createMidiSends.
--      otherwise it becomes locked to syntax and not modular.
--
--    3.
--

--------------------------------------------------

local TRACK_INFO_AUDIO_SRC_DISABLED = -1
local TRACK_INFO_MIDIFLAGS_ALL_CHANS = 0
local TRACK_INFO_MIDIFLAGS_DISABLED = 4177951
local TRACK_INFO_SEND_CATEGORY = 0 -- send

-----------------------------------------------
-- public

function routing.addRouteForSelectedTracks()
  local num_sel = reaper.CountSelectedTracks(0)
  if num_sel == 0 then return end
  local src_GUID = GetSrcTrGUID() -- get table of src tracks

  local route_help_str = "route params:\n" ..
  "\nk int  = category" ..
  "\ni int  = send idx" -- this is not displaying properly...

  local test_str = "xxi5c...C555555C5.54v^#$∞¶M1a1.4s5.555d44.456P12.456789"
  local _, input_str = reaper.GetUserInputs("SPECIFY ROUTE:", 1, route_help_str, test_str)

  local new_route_params = getSendParamsFromUserInput(input_str)

  addRoutes(new_route_params, src_GUID)
end

-- mv to custom_actions?
function routing.sidechainSelTrkToGhostSnareTrack()
  sidechainToTrackWithNameString('ghostSnare')
end

-- mv to custom_actions?
function routing.sidechainSelTrkToGhostKickTrack()
  sidechainToTrackWithNameString('ghostKick')
end

--  !!! needs to be renamed into syntaxAddMidiSend so that I don't mix things up
--  - add default source channel = all or 1?
function routing.createSend(src_obj,dest_obj,dest_chan)
  -- log.user('>'..src_obj.name)
  -- log.user(dest_obj)
  local src_obj_trk, src_idx  =  reaper_utils.getTrackByGUID(src_obj.guid)-- reaper.GetTrack(0,src_obj.trackIndex)
  local dest_obj_trk, dst_idx = reaper_utils.getTrackByGUID(dest_obj.guid)--reaper.GetTrack(0,dest_obj.trackIndex)
  -- log.user('createSend() for: ' .. src_obj.name)

  local midi_send = reaper.CreateTrackSend(src_obj_trk, dest_obj_trk) -- create send; return sendidx for reference

  local new_midi_flags = create_send_flags(0, dest_chan) -- create new incremented midi channel

  reaper.SetTrackSendInfo_Value(src_obj_trk, TRACK_INFO_SEND_CATEGORY, midi_send, "I_MIDIFLAGS", new_midi_flags) -- set midi_flags on reference
  reaper.SetTrackSendInfo_Value(src_obj_trk, TRACK_INFO_SEND_CATEGORY, midi_send, "I_SRCCHAN", TRACK_INFO_AUDIO_SRC_DISABLED)
end


function routing.removeAllSends(trk_obj)
  local tr, tr_idx = reaper_utils.getTrackByGUID(trk_obj.guid)--reaper.GetTrack(0,trk_obj.trackIndex)
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


------------------------------------------------------------------------
-- internal

function get_send_flags_dest(flags)
  return flags >> 5
end

function get_send_flags_src(flags)
  return flag & ((1 << 5) - 1) -- flag & 0x11111
end

function create_send_flags(src_chan, dest_chan)
  return (dest_chan << 5) | src_chan
end

-- mv to custom_actions?
function sidechainToTrackWithNameString(str)
  --  1. find track w name containing 'str'
  --    if not has_no_name and current_name:match(search_name:lower()) then
  --      return track
  --    end
  --  x. if doesn't exist >> prompt ghostKick doesn't exist
  --  2. add receive into ch 3/4 on sel track
  --  3. add reacomp on sel track
  --  4. rename fx to 'SIDECHAIN_TO_GHOSTKICK'
  --  5. create check for name. if exists don't create
  --
end

function addRoutes(route_params, src_t, dest_t)
  log.user(format.block(route_params))

  if route_params["d"].param_value == nil then return end

  local dest_tr = reaper.GetTrack(0, math.floor(route_params["d"].param_value-1))
  local ret, dest_name = reaper.GetTrackName(dest_tr)
  local help_str = "`"..dest_name .. "` (y/n)"
  local _, answer = reaper.GetUserInputs("Create new route for track:", 1, help_str, "")

  if answer ~= "y" then return end

  for i = 1, #src_t do
    --   local src_tr =  BR_GetMediaTrackByGUID( 0, src_t[i] )
    --   local src_tr_ch = GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
    local src_tr =  reaper.BR_GetMediaTrackByGUID( 0, src_t[i] )
    local src_tr_ch = reaper.GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')

    --   for i = 1, #dest_t do
    -- !!! only one dest track possible !!!

    -- increase ch up to src track
    local dest_tr_ch = reaper.GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
    if dest_tr_ch < src_tr_ch then reaper.SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end

    log.user(src_tr_ch, dest_tr_ch)

    -- check for existing sends
    local is_exist = false
    for i =1,  reaper.GetTrackNumSends( src_tr, 0 ) do
      local dest_tr_check = reaper.BR_GetMediaTrackSendInfo_Track( src_tr, 0, i-1, 1 )
      if dest_tr_check == dest_tr then is_exist = true break end
    end

    -- create send
    if not is_exist then

      local new_id = reaper.CreateTrackSend( src_tr, dest_tr )

      for _, p in pairs(route_params) do
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_id, p.param_name, p.param_value)

        if p.param_name == 'I_SRCCHAN' then
          if dest_tr_ch == 2 then
            reaper.SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',0)
          else
            reaper.SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',0|(1024*math.floor(src_tr_ch/2)))
          end
        end
      end
    end
    --   end -----------------------------------------------------------------------------
  end
end

-- mv util
function GetDestTrGUID()
  --   local t = {}
  --   local _, sendidx = reaper.GetUserInputs("Send track dest idx:", 1, "send idx", "")
  --   local dest_track = reaper.GetTrack(0, sendidx-1)
  --   if dest_track  then t[1] = reaper.GetTrackGUID( dest_track  ) end
  --   return t
end

-- mv util
function GetSrcTrGUID()
  local t = {}
  for i = 1, reaper.CountSelectedTracks(0) do
    local tr = reaper.GetSelectedTrack(0,i-1)
    t[#t+1] = reaper.GetTrackGUID( tr )
  end
  return t
end

function getSendParamsFromUserInput(str)
  local new_route_params = routing_defaults.default_params
  for key, val in pairs(new_route_params) do

    local pattern = key .. "%d+%.?%d?%d?"

    local s, e = string.find(str, pattern)
    if s ~= nil and e ~= nil then
      -- log.user('key: ' .. string.sub(str,s,s) .. ', val: ' .. string.sub(str,s+1,e))
      new_route_params[key].param_value = tonumber(string.sub(str,s+1,e))
    end
  end

  return new_route_params
end
------------------------------------------------------------------------
return routing
