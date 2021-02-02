local ru = require('custom_actions.utils')
local log = require('utils.log')
local format = require('utils.format')
local routing_defaults = require('definitions.routing')



local routing = {}

local TRACK_INFO_AUDIO_SRC_DISABLED = -1
local TRACK_INFO_MIDIFLAGS_ALL_CHANS = 0
local TRACK_INFO_MIDIFLAGS_DISABLED = 4177951
local TRACK_INFO_CATEGORY_SEND = 0 -- send
local TRACK_INFO_CATEGORY_RECIEVE = -1 -- send
local TRACK_INFO_CATEGORY_HARDWARE = 1 -- send


-- ROUTE VARIABLES
local route_help_str = "route params:\n" .. "\nk int  = category" .. "\ni int  = send idx"




-- ## TODO
--
--  - before confirm log src / dest name list
--
--  - prompt no tracks matched
--
--  - bug > are there more midi sends being created than I expect???
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
--  - mult src/dest comma sep mix strings and numbers

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
  -- TODO ??
end

-- GET FIRST 5 BITS
function get_send_flags_src(flags) return flag & ((1 << 5)- 1) end

-- GET SECOND 5 BITS
function get_send_flags_dest(flags) return flags >> 5 end

-- GET SRC AND DEST BYTE PREPARED
function create_send_flags(src_ch, dest_ch) return (dest_ch << 5) | src_ch end

function isSel() return reaper.CountSelectedTracks(0) ~= 0 end

function routing.create()
  log.clear()
  log.user('createRouteFromUserInput')
  if not isSel() then return end
  local _, input_str = reaper.GetUserInputs("SPECIFY ROUTE:", 1, route_help_str, "")
  local new_route_params = extractSendParamsFromUserInput(input_str)
  prepareRouteComponents(new_route_params)
end

function routing.sidechainSelTrkToGhostSnareTrack()
  sidechainToTrackWithNameString('ghostSnare')
end

function routing.sidechainSelTrkToGhostKickTrack()
  sidechainToTrackWithNameString('ghostKick')
end

-- TODO
--
--  check if route exists already
--
--
--  - add default source channel = all or 1?
function routing.createSingleMIDISend(src_tr,dest_tr,dest_chan)
  log.user('createSingleMIDISend')

  local is_exist = checkIfSendExists(src_tr, dest_tr)


  log.user('midi sends exists ???????  : ' .. tostring(is_exist))
  if not is_exist then
    local midi_send_id = reaper.CreateTrackSend(src_tr, dest_tr) -- create send; return sendidx for reference
    local new_midi_flags = create_send_flags(0, dest_chan)
    reaper.SetTrackSendInfo_Value(src_tr, TRACK_INFO_CATEGORY_SEND, midi_send_id, "I_MIDIFLAGS", new_midi_flags) -- set midi_flags on reference
    reaper.SetTrackSendInfo_Value(src_tr, TRACK_INFO_CATEGORY_SEND, midi_send_id, "I_SRCCHAN", TRACK_INFO_AUDIO_SRC_DISABLED)
  end


end

function routing.removeSingle(send_idx)
  -- TODO
end

function routing.removeAllSends(tr)
  removeAll(tr)
end

function routing.removeAllRecieves(tr)
  removeAll(tr, 1)
end

function routing.removeAllBoth(tr)
  removeAll(tr, 2)
end

function deleteByCategory(tr, cat)
  local num_sends = reaper.GetTrackNumSends(tr, cat)
  -- if num_sends == 0 then return end
  while(num_sends > 0) do
    for si=0, num_sends-1 do
      local rm = reaper.RemoveTrackSend(tr, cat, si)
    end
    num_sends = reaper.GetTrackNumSends(tr, cat)
  end
end


function removeAll(tr, kind)
  log.clear()
  log.user('removeAll')
  local target_t = {}
  target_t[#target_t] = tr

  if tr == nil or tr == false then target_t = ru.getSelectedTracksGUIDs() end -- get table of src tracks

  -- FOR EACH TRACK WE WANT TO TARGET
  for i = 1, #target_t do
    local tr = ru.getTrackByGUID(target_t[i])
    if kind == nil or kind == 0 then
      deleteByCategory(tr, TRACK_INFO_CATEGORY_SEND)
    elseif kind == 1 then
      deleteByCategory(tr, TRACK_INFO_CATEGORY_RECIEVE)
    elseif kind == 2 then
      deleteByCategory(tr, TRACK_INFO_CATEGORY_SEND)
      deleteByCategory(tr, TRACK_INFO_CATEGORY_RECIEVE)
    end
  end

  return true
end

function sidechainToTrackWithNameString(str)
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

-- TODO if no destination >>> return ?????
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
    -- this is obsolete
    if route_params.default_params["d"].param_value == nil then return end
    dest_tr = reaper.GetTrack(0, math.floor(route_params.default_params["d"].param_value-1))
  else
    dest_tr = ru.getTrackByGUID(route_params.dest_guids[1])
  end
  local ret, dest_name = reaper.GetTrackName(dest_tr)

  -- CONFIRM ROUTE CREATION
  log.user('>>> confirm route creation y/n')
  local help_str = "` #src: `" .. tostring(#src_t) ..
  "` #dest: `" .. tostring(#route_params.dest_guids) ..
  "` dest[0]: "..dest_name .. "` (y/n)"
  local _, answer = reaper.GetUserInputs("Create new route for track:", 1, help_str, "")
  if answer ~= "y" then return end



  -- FOR EACH SOURCE CREATE ROUTE TO ALL DEST TRACKS
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

  -- SRC IS NUM ELSE
  if tonumber(pSrc) ~= nil then
    local tr = reaper.GetTrack(0, tonumber(pSrc) - 1)
    routing_defaults['src_guids'] = { reaper.GetTrackGUID( tr ) }
  else
    routing_defaults['src_guids'] = getMatchedTrackGUIDs(pSrc)
  end
  -- DEST IS NUM ELSE
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
