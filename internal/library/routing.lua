local ru = require('custom_actions.utils')
local log = require('utils.log')
local format = require('utils.format')
local routing_defaults = require('definitions.routing')

local routing = {}

-- MIDI VARIABLES
local TRACK_INFO_AUDIO_SRC_DISABLED = -1
local TRACK_INFO_MIDIFLAGS_ALL_CHANS = 0
local TRACK_INFO_MIDIFLAGS_DISABLED = 4177951
local TRACK_INFO_SEND_CATEGORY = 0 -- send


-- ROUTE VARIABLES
local test_str = "d180"
local route_help_str = "route params:\n" .. "\nk int  = category" .. "\ni int  = send idx"

-- ## TODO
--
--  - add number selection for source as well.
--
--  - prompt no tracks matched
--
--  - prompt if matched mult. tr
--
--  - create midi send
--    need change >> how take in midi params?
--
--  - create midi and audio send in on command
--
--  - list src/dest in confirmation prompt
--
--  - update already existing sends
--      mute/mono/stereo/
--
--        if SEND_IDX then update that if it exists
--
--
--  ## RNDM
--    function checkForFeedback()
--      how do I handle this problem.

-----------------------------------------------
-- SAFETY FUNCTIONS
function checkIfSendExists(src_tr, dest_tr)
  log.user('checkIfSendsExist')
  for i =1,  reaper.GetTrackNumSends( src_tr, 0 ) do
    local dest_tr_check = reaper.BR_GetMediaTrackSendInfo_Track( src_tr, 0, i-1, 1 )
    if dest_tr_check == dest_tr then return true end
  end
  return false
end

function preventRouteFeedback()
  -- ?????????
end

-----------------------------------------------

-- GET FIRST 5 BITS
function get_send_flags_src(flags) return flag & ((1 << 5)- 1) end

-- GET SECOND 5 BITS
function get_send_flags_dest(flags) return flags >> 5 end

-- GET SRC AND DEST BYTE PREPARED
function create_send_flags(src_ch, dest_ch) return (dest_ch << 5) | src_ch end

-----------------------------------------------

function isSel() return reaper.CountSelectedTracks(0) ~= 0 end

function routing.create()
  log.clear()
  log.user('createRouteFromUserInput')
  if not isSel() then return end
  local _, input_str = reaper.GetUserInputs("SPECIFY ROUTE:", 1, route_help_str, test_str)
  local new_route_params = extractSendParamsFromUserInput(input_str)
  prepareRouteComponents(new_route_params)
end

function routing.sidechainSelTrkToGhostSnareTrack()
  sidechainToTrackWithNameString('ghostSnare')
end

function routing.sidechainSelTrkToGhostKickTrack()
  sidechainToTrackWithNameString('ghostKick')
end

--  - add default source channel = all or 1?
function routing.createSingleMIDISend(src_obj_trk,dest_obj_trk,dest_chan)
  log.user('createSingleMIDISend')
  local midi_send_id = reaper.CreateTrackSend(src_obj_trk, dest_obj_trk) -- create send; return sendidx for reference
  local new_midi_flags = create_send_flags(0, dest_chan)
  reaper.SetTrackSendInfo_Value(src_obj_trk, TRACK_INFO_SEND_CATEGORY, midi_send_id, "I_MIDIFLAGS", new_midi_flags) -- set midi_flags on reference
  reaper.SetTrackSendInfo_Value(src_obj_trk, TRACK_INFO_SEND_CATEGORY, midi_send_id, "I_SRCCHAN", TRACK_INFO_AUDIO_SRC_DISABLED)
end


function removeSingleRoute()
end


-- TODO
--
--  tr
--    false = use selection
--    <track> = use track
--
--
--  kind
--    0 = sends
--    1 = recieves
--    2 = both
function routing.removeAll(tr, kind)
  log.clear()
  log.user('removeAll')
  local target_t = {}
  target_t[#target_t] = tr
  if not doubleParen then target_t = ru.getSelectedTracksGUIDs() end -- get table of src tracks

  log.user(format.block(target_t))
  for i = 1, #target_t do
    local tr = ru.getTrackByGUID(target_t[i])
    local num_sends = reaper.GetTrackNumSends(tr, TRACK_INFO_SEND_CATEGORY)
    if num_sends == 0 then return end
    while(num_sends > 0) do
      for si=0, num_sends-1 do
        local rm = reaper.RemoveTrackSend(tr, TRACK_INFO_SEND_CATEGORY, si)
      end
      num_sends = reaper.GetTrackNumSends(tr, TRACK_INFO_SEND_CATEGORY)
    end
  end
  return true
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
  --
end

function incrementDestChanToSrc(dest_tr, src_tr_ch)
  log.user('incrementDestChanToSrc')
  local dest_tr_ch = reaper.GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
  if dest_tr_ch < src_tr_ch then reaper.SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end
  return dest_tr_ch
end

-- create track route by `routeparams`
function createTheActualRoute(route_params, src_tr, src_tr_ch, dest_tr, dest_tr_ch)
  log.user('createTrackSend')
  local new_id = reaper.CreateTrackSend( src_tr, dest_tr )
  log.user(format.block(route_params))

  for _, p in pairs(route_params.default_params) do
    log.user(format.block(p))
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

--------------------------------------------------

-- if no destination >>> return
function prepareRouteComponents(route_params)
  log.user('prepareRouteComponents')
  local src_t
  local dest_t
  local dest_tr

  log.user(format.block(route_params))

  -- GET SRC TRACKS
  if route_params.src_guids ~= nil then
    local singleMatchedSource = #route_params.src_guids == 1
    if not singleMatchedSource then
      src_t = ru.getSelectedTracksGUIDs()
    else
      src_t = route_params.src_guids
    end
  else
    src_t = ru.getSelectedTracksGUIDs()
  end


  -- GET DEST TRACKS
  local singleMatchedDest = #route_params.dest_guids == 1
  if not singleMatchedDest then
    if route_params.default_params["d"].param_value == nil then return end
    dest_tr = reaper.GetTrack(0, math.floor(route_params.default_params["d"].param_value-1))
  else
    dest_tr = ru.getTrackByGUID(route_params.dest_guids[1])
  end

  local ret, dest_name = reaper.GetTrackName(dest_tr)
  log.user('>>> confirm route creation y/n')
  local help_str = "`"..dest_name .. "` (y/n)"
  local _, answer = reaper.GetUserInputs("Create new route for track:", 1, help_str, "")
  if answer ~= "y" then return end
  for i = 1, #src_t do
    local src_tr =  reaper.BR_GetMediaTrackByGUID( 0, src_t[i] )
    local src_tr_ch = reaper.GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
    local dest_tr_ch = incrementDestChanToSrc(dest_tr, src_tr_ch)
    local is_exist = checkIfSendExists(src_tr, dest_tr)
    if not is_exist then
      createTheActualRoute(route_params, src_tr, src_tr_ch, dest_tr, dest_tr_ch)
    end
    --   end -----------------------------------------------------------------------------
  end
end

function doesRouteAlreadyExist()
end

-------------------------------------------------

function getMatchedTrackGUIDs(search_name)
  if not search_name then return nil end
  local t = {}
  for i=0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, current_name = reaper.GetTrackName(tr)
    if current_name:match(search_name) then
      t[#t+1] = reaper.GetTrackGUID( tr )
    end
  end
  return t
end

function extractSendParamsFromUserInput(str)
  log.user('extractSendParamsFromUserInput')
  local new_route_params = routing_defaults
  local pcount = 0
  local pSrc
  local pDest
  for p in str:gmatch "%b()" do
    pcount = pcount + 1
    -- remove enclosing `()`
    if pcount == 1 then pDest = str.sub(p, 2, str.len(p) - 1) end
    if pcount == 2 then
      pSrc = pDest
      pDest = str.sub(p, 2, str.len(p) - 1)
      break
    end
  end
  for r in str:gmatch "%b()" do
    str = str:gsub("%("..r.."%)", "")
  end

  routing_defaults['src_guids'] = getMatchedTrackGUIDs(pSrc)
  if tonumber(pDest) ~= nil then
    -- use tr index for dest
    local tr = reaper.GetTrack(0, tonumber(pDest) - 1)
    routing_defaults['dest_guids'] = { reaper.GetTrackGUID( tr ) }
  else
  routing_defaults['dest_guids'] = getMatchedTrackGUIDs(pDest)
  end




  for key, val in pairs(new_route_params.default_params) do
    -- create uniq pattern for each config key
    local pattern = key .. "%d+%.?%d?%d?"
    local s, e = string.find(str, pattern)

    if s ~= nil and e ~= nil then
      log.user('\n\tkey: ' .. string.sub(str,s,s) .. ', val: ' .. string.sub(str,s+1,e) .. '\n')
      new_route_params.default_params[key].param_value = tonumber(string.sub(str,s+1,e))
    end
  end

  return new_route_params
end
------------------------------------------------------------------------
return routing
