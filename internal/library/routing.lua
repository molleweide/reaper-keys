local ru = require('custom_actions.utils')
local tb = require('utils.table')
local log = require('utils.log')
local format = require('utils.format')
local routing_defaults = require('definitions.routing')

local routing = {}

local div = '##########################################'
local div2 = '---------------------------------'

-- TODO
--
-- move these to configs

local TRACK_INFO_AUDIO_SRC_DISABLED = -1
local TRACK_INFO_MIDIFLAGS_ALL_CH = 0
local TRACK_INFO_MIDIFLAGS_DISABLED = 4177951
local TRACK_INFO_CATEGORY_SEND = 0 -- send
local TRACK_INFO_CATEGORY_RECIEVE = -1 -- send
local TRACK_INFO_CATEGORY_HARDWARE = 1 -- send


-- ROUTE VARIABLES
local route_help_str = "route params:\n" .. "\nk int  = category" .. "\ni int  = send idx"

-- ## TODO
--
--    - if update eg 'a' put no ch are given >> only update params like phase/mono/etc. ??
-----------------------------------------------
function checkIfSendExists(src_tr, dest_tr)
  log.user('checkIfSendsExist')
  for si=0,  reaper.GetTrackNumSends( src_tr, 0 ) do

    local dest_tr_check = reaper.BR_GetMediaTrackSendInfo_Track( src_tr, 0, si, 1 )

    if dest_tr_check == dest_tr then
      local prev_params = {}

      -- put inside prev params
      local prev_src_midi_flags = reaper.GetTrackSendInfo_Value(src_tr, 0, si, 'I_MIDIFLAGS')
      local prev_src_audio_ch = reaper.GetTrackSendInfo_Value(src_tr, 0, si, 'I_SRCCHAN')
      -- local prev_src_dest_ch = -- TODO <<<<

      -- both audio and midi
      local retval = 3
      log.user(prev_src_midi_flags .. '    ' .. prev_src_audio_ch)

      local no_midi = prev_src_midi_flags == TRACK_INFO_MIDIFLAGS_DISABLED
      local no_audio = prev_src_audio_ch == TRACK_INFO_AUDIO_SRC_DISABLED
      -- only audio = 1
      if no_midi then retval = 1 end
      -- only midi = 2
      if no_audio then retval = 2 end


      -- TODO
      --
      -- return table filled with previous params

      log.user(tostring(si) .. '   ' .. tostring(no_midi) .. '   ' .. tostring(no_audio) .. '   ' .. tostring(retval))

      return retval, si, prev_params
    end
  end
  return false
end








function preventRouteFeedback()
  -- TODO ??
end

-- GET FIRST 5 BITS
function get_send_flags_src(flags) return flags & ((1 << 5)- 1) end

-- GET SECOND 5 BITS
function get_send_flags_dest(flags) return flags >> 5 end

-- GET SRC AND DEST BYTE PREPARED
function create_send_flags(src_ch, dest_ch) return (dest_ch << 5) | src_ch end

function isSel() return reaper.CountSelectedTracks(0) ~= 0 end

function routing.create()
  log.clear()
  log.user('create()')
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


-- the name of this function is stupid?!
function audioMidiBoth(rp)
  if (rp.INP['a'] ~= nil and rp.INP['m'] == nil) or (rp.INP['a'] == nil and rp.INP['m'] == nil) then
    return 'ONLY_AUDIO' -- default (audio atm)
  end
  if rp.INP['a'] == nil and rp.INP['m'] ~= nil then
    return 'ONLY_MIDI' -- only midi
  end
  if rp.INP['a'] == nil and rp.INP['m'] ~= nil then
    return 'BOTH_AUDIO_AND_MIDI' -- both audio and midi
  end
  return false
end




function routing.createRoutesLoop(rp, src_t, dest_tr)
  local df = routing_defaults.default_params
  for i = 1, #src_t do
    local src_tr =  reaper.BR_GetMediaTrackByGUID( 0, src_t[i] )
    -- why are these two put here. can they be put inside of  createisingle funcs??
    local src_tr_ch = reaper.GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
    local dest_tr_ch = incrementDestChanToSrc(dest_tr, src_tr_ch)
    -- currently route is always send // cat is not yet implemented
    local exists, old_route_id = checkIfSendExists(src_tr, dest_tr)
    if not exists then
      -- NEW //////////////////////////////////////////////////////////////////
      local new_route_id = reaper.CreateTrackSend(src_tr, dest_tr)
      if audioMidiBoth(rp) == 'ONLY_AUDIO' then
        if rp.INP['a'] == nil then rp.INP['a'] = df['a'] end
        rp.INP['m'] = df['m']
        rp.INP['m'].param_value = TRACK_INFO_MIDIFLAGS_DISABLED
      end
      if audioMidiBoth(rp) == 'ONLY_MIDI' then
        rp.INP['a'] = df['a']
        rp.INP['a'].param_value = TRACK_INFO_AUDIO_SRC_DISABLED
      end
      if audioMidiBoth(rp) == 'BOTH_AUDIO_AND_MIDI' then end
      createSingleTrackAudioRoute(new_route_id, rp, src_tr, src_tr_ch, dest_tr, dest_tr_ch)
    else
      log.user('\nEXISTS')
      -- ALREADY HAS AUDIO
      if exists == 1 then
        if audioMidiBoth(rp) == 'ONLY_AUDIO' then
          -- TODO
          -- and `u`
        end
        if audioMidiBoth(rp) == 'ONLY_MIDI' then
          routeUpdate('midi', old_route_id, rp, src_tr)
        end
      end
      -- ALREADY HAS MIDI
      if exists == 2 then
        if audioMidiBoth(rp) == 'ONLY_MIDI' then
          -- TODO
          -- and `u`
        end
        if audioMidiBoth(rp) == 'ONLY_AUDIO' then
          if rp.INP['a'] == nil then rp.INP['a'] = df['a'] end
          log.user('update audio <<<<<<<<<<<<')
          routeUpdate('audio', old_route_id, rp, src_tr)
        end
      end
      -- ALREADY HAS BOTH
      if exists == 3 then
        -- and `u`
      end
    end
  end
end

function routing.createSingleMIDISend(src_tr,dest_tr,dest_chan)
  log.user('createSingleMIDISend')
  local is_exist = checkIfSendExists(src_tr, dest_tr)

  -- TODO
  -- if dest_chan == nil then set to 0 (ALL)
  --

  log.user('midi sends exists ???????  : ' .. tostring(is_exist))
  if not is_exist then
    local midi_send_id = reaper.CreateTrackSend(src_tr, dest_tr) -- create send; return sendidx for reference
    local new_midi_flags = create_send_flags(0, dest_chan)
    reaper.SetTrackSendInfo_Value(src_tr, TRACK_INFO_CATEGORY_SEND, midi_send_id, "I_MIDIFLAGS", new_midi_flags) -- set midi_flags on reference
    reaper.SetTrackSendInfo_Value(src_tr, TRACK_INFO_CATEGORY_SEND, midi_send_id, "I_SRCCHAN", TRACK_INFO_AUDIO_SRC_DISABLED)
  end
end

-- hardware not working....
function getOtherTrack(tr, cat, si)
  local other_tr
  if cat == 0 then
    other_tr = reaper.BR_GetMediaTrackSendInfo_Track(tr, cat, si, 1)
  else
    other_tr = reaper.BR_GetMediaTrackSendInfo_Track(tr, cat, si, 0)
  end
  local other_tr_idx = reaper.GetMediaTrackInfo_Value(other_tr, "IP_TRACKNUMBER") - 1

  return other_tr, other_tr_idx
end

-- LINK > format numbers/decimals ::: https://stackoverflow.com/questions/18313171/lua-rounding-numbers-and-then-truncate
function logRoutesByCategory(tr, cat)
  local num_sends = reaper.GetTrackNumSends(tr, cat)
  if num_sends == 0 then
    -- log.user('\t\t--')
    return
  end
  for si = 0, num_sends-1 do

    if cat <= 0 then
      local other_tr, other_tr_idx = getOtherTrack(tr, cat, si)
      local _, other_tr_name = reaper.GetTrackName(other_tr)
      log.user('\n\t\t' .. si .. ' #' .. other_tr_idx .. ' ' .. tostring(other_tr_name))

      if cat == 0 then
        -- SEND ---------------------------------------------------
        local audio_out = reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_SRCCHAN')
        local send_in = reaper.GetTrackSendInfo_Value(other_tr, cat, si, 'I_SRCCHAN')
        local midi_flags_tr = reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_MIDIFLAGS')
        log.user('\t\t\tAUDIO_OUT ' .. tostring(audio_out) .. ' \t-> S_IN \t' .. send_in)
        log.user('\t\t\tMIDI_OUT: ' .. get_send_flags_src(midi_flags_tr) ..
          ' \t\t-> MS_IN \t' .. get_send_flags_dest(midi_flags_tr))
      elseif cat < 0 then
        -- RECIEVE ------------------------------------------------
        local rec_out = reaper.GetTrackSendInfo_Value(other_tr, cat, si, 'I_SRCCHAN')
        local audio_in =  reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_SRCCHAN')
        local midi_flags_tr = reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_MIDIFLAGS')
        log.user('\t\t\tSRC_OUT ' .. tostring(rec_out) .. ' \t\t-> AUDIO_IN ' .. audio_in)
        log.user('\t\t\tMSRC_OUT: ' .. get_send_flags_src(midi_flags_tr) ..
          ' \t\t-> MIDI_IN ' .. get_send_flags_dest(midi_flags_tr))
      end
    elseif cat > 0 then
      -- HARDWARE -------------------------------------
      -- TODO
    end
  end
end


function routing.logRoutingInfoForSelectedTracks()
  log.clear()
  local log_t = ru.getSelectedTracksGUIDs()
  for i = 1, #log_t do
    local tr, tr_idx = ru.getTrackByGUID(log_t[i])
    local _, current_name = reaper.GetTrackName(tr)
    log.user('\n\n'..div..'\n:: routes for track #' .. tr_idx+1 .. ' `' .. current_name .. '`:')

    log.user('\n\tSENDs:')
    logRoutesByCategory(tr, TRACK_INFO_CATEGORY_SEND)
    log.user('\n\tRECIEVEs:')
    logRoutesByCategory(tr, TRACK_INFO_CATEGORY_RECIEVE)
    log.user('\n\tHARDWARE:')
    logRoutesByCategory(tr, TRACK_INFO_CATEGORY_HARDWARE)
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

function routeUpdate(type, old_route_id, rp, src_tr)
  local m = rp.INP['m']
  local df = routing_defaults.default_params
  log.user('old route id: ' .. old_route_id)
  for k, p in pairs(rp.INP) do
    if k == 'm' then
      if type == 'midi' or type == 'both' then
        if k.param_value ~= nil then
          reaper.SetTrackSendInfo_Value(
            src_tr, 0, old_route_id, rp.INP[k].param_name, k.param_value)
        else
          reaper.SetTrackSendInfo_Value( -- if no value >> default
            src_tr, 0, old_route_id, df[k].param_name, df[k].param_value)
        end
      end
    else
      if type == 'audio' or type == 'both' then
        if k.param_value ~= nil then
          reaper.SetTrackSendInfo_Value(
            src_tr, 0, old_route_id, rp.INP[k].param_name, k.param_value)
        else
          reaper.SetTrackSendInfo_Value( -- if no value >> default
            src_tr, 0, old_route_id, df[k].param_name, df[k].param_value)
        end
      end
    end
  end
end

function createSingleTrackAudioRoute(new_rid, route_params, src_tr, src_tr_ch, dest_tr, dest_tr_ch)
  log.user('createTrackSend')
  local df = routing_defaults.default_params
  log.user(src_tr_ch, dest_tr_ch)
  -- log.user(format.block(route_params.INP))

  for k, p in pairs(route_params.INP) do

    if p.param_name == 'I_SRCCHAN' and p.param_value ~= TRACK_INFO_AUDIO_SRC_DISABLED then
      if dest_tr_ch == 2 then
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, 'I_SRCCHAN',0)
      else
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, 'I_SRCCHAN',0|(1024*math.floor(src_tr_ch/2)))
      end

    else
      if p.param_value ~= nil then
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, p.param_name, p.param_value)
      else
        -- if no value >> default
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, p.param_name, df[k].param_value)
      end
    end
  end
end

-- TODO if no destination >>> return ?????
function prepareRouteComponents(rp)
  log.user('prepareRouteComponents')
  local src_t
  local dest_t
  local dest_tr
  local dest_idx

  -- GET SRC TRACKS
  if rp.src_guids ~= nil then
    local singleMatchedSource = #rp.src_guids == 1
    if not singleMatchedSource then
      src_t = ru.getSelectedTracksGUIDs()
    else
      src_t = rp.src_guids
    end
  else
    src_t = ru.getSelectedTracksGUIDs()
  end
  log.user('list SRC tracks >>>>> \n')
  for i = 1, #src_t do
    local tr, tr_idx = ru.getTrackByGUID(src_t[i])
    local ret, src_name = reaper.GetTrackName(tr)
    log.user('\t' .. tr_idx .. ' - ' .. src_name)
  end

  -- GET DEST TRACKS
  dest_tr, dest_idx = ru.getTrackByGUID(rp.dest_guids[1])
  local ret, dest_name = reaper.GetTrackName(dest_tr)

  log.user('\nlist DEST tracks >>>>> \n')
  log.user('\t' .. dest_idx .. ' - ' .. dest_name)

  -- CONFIRM ROUTE CREATION
  log.user('\n>>> confirm route creation y/n')
  local help_str = "` #src: `" .. tostring(#src_t) ..
  "` #dest: `" .. tostring(#rp.dest_guids) ..
  "` dest[0]: "..dest_name .. "` (y/n)"
  local _, answer = reaper.GetUserInputs("Create new route for track:", 1, help_str, "")
  if answer ~= "y" then return end


  -- EXECUTE / UPDATE ROUTING STATE

  routing.createRoutesLoop(rp, src_t, dest_tr)

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

  new_route_params['INP'] = {}

  -- A. HANDLE SOURCE /DESTINATION
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

  -- B. HANDLE SEND PARAMS
  for key, val in pairs(new_route_params.default_params) do

    -- check for possible choices.
    --
    -- TODO
    --
    -- atm this is only a generic find char + double
    --
    -- but it would be nice to create a special type of patterns
    -- dedicated to taking input for specific types of send characteristics

    local pattern = key .. "%d?%.?%d?%d?"

    local s, e = string.find(str, pattern)
    if s ~= nil and e ~= nil then
      new_route_params.INP[key] = {
        description = val.description,
        param_name = val.param_name,
        param_value = tonumber(string.sub(str,s+1,e))
      }
    else
      -- don't exist
    end
  end
  log.user(format.block(new_route_params.INP))
  log.user('!!!!!!!!!!!!!!')
  return new_route_params
end
------------------------------------------------------------------------
return routing
