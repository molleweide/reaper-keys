local ru = require('custom_actions.utils')
local tb = require('utils.table')
local log = require('utils.log')
local format = require('utils.format')
local rc = require('definitions.routing')

local routing = {}

local input_placeholder = "(176)[2|4]{-5|11}"
local route_help_str = "route params:\n" .. "\nk int  = category" .. "\ni int  = send idx"
local div = '##########################################'
local div2 = '---------------------------------'

--  !!!!!!
--
--      using midi busses is not supported
--
--  EXERCISES
--
--  read more vimscript <<<<<<<<<<<<<<<<<<<<<
--
--      if only audio >> midi doesn't update?? now u is req but it shouldn't be
--      since midi doesn't exist already
--
--
--        pattern: how take midi ch input from user???
--          eg. if `m[1,16]`
--
--      - update send by id?
--
--      - many 2 many >>> pattern name/num separators (**)
--
--      PATTERN
--
--        (**)    src/dest list separators
--
--      CUSTOM_ACTION
--
--      - sidechain selected tracks to <ghostkick>
--          connect plugin to auxiliary channel.
--
--      SYNTAX
--
--      - syntax.lua > auto send > drums/music/fx
--
--
--      MUTE SEND
--
--        - nudge send params
--      - nudge volume
--      - nudge pan
--
--      TOGGLE SEND PARAMS
--        - mono / stereo
--        - mute
--        - flip phase
--
--
-- LINK > format numbers/decimals ::: https://stackoverflow.com/questions/18313171/lua-rounding-numbers-and-then-truncate

--////////////////////////////////////////////////////////////////////////
--  UTILS
--/////////

function isSel() return reaper.CountSelectedTracks(0) ~= 0 end

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

-- mv to utils
-- this function alse is defined in syntax/syntax
function getStringSplitPattern(pString, pPattern)
  local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pPattern
  local last_end = 1
  local s, e, cap = pString:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(Table,cap)
    end
    last_end = e+1
    s, e, cap = pString:find(fpat, last_end)
  end
  if last_end <= #pString then
    cap = pString:sub(last_end)
    table.insert(Table, cap)
  end
  return Table
end
--//////////////////////////////////////////////////////////////////////
--  MIDI FLAGS
--//////////////
--
--
--  the get functions return the `normal` decimal value
--  of the midi flag, eg src ch 1, dest ch 6, etc..
--
--  the input is the output from `I_MIDIFLAGS`

--  GET FIRST 5 BITS
function get_send_flags_src(flags) return flags & ((1 << 5)- 1) end

--  GET SECOND 5 BITS
function get_send_flags_dest(flags) return flags >> 5 end

--  GET SRC AND DEST BYTE PREPARED
function create_send_flags(src_ch, dest_ch) return (dest_ch << 5) | src_ch end

--//////////////////////////////////////////////////////////////////////
--  LOGGING
--///////////

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

-- TODO
--
-- if no audio / midi >>> don't show audio/midi
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

      if cat == 0 then
        -- SEND ---------------------------------------------------
        local audio_out     = reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_SRCCHAN')
        local send_in       = reaper.GetTrackSendInfo_Value(other_tr, cat, si, 'I_SRCCHAN')
        local midi_flags_tr = reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_MIDIFLAGS')
        log.user(string.format("\n\t\tto (#%i) `%s`", other_tr_idx, other_tr_name))
        log.user(
          string.format(
            "\t\t\t%i :: AUDIO_OUT: %i -> %i | MIDI_OUT: %i -> %i",
            si, audio_out, send_in,
            get_send_flags_src(midi_flags_tr),
            get_send_flags_dest(midi_flags_tr)
            )
          )
      elseif cat < 0 then
        -- RECIEVE ------------------------------------------------
        local rec_out = reaper.GetTrackSendInfo_Value(other_tr, cat, si, 'I_SRCCHAN')
        local audio_in =  reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_SRCCHAN')
        local midi_flags_tr = reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_MIDIFLAGS')
        log.user(string.format("\n\t\tfrom (#%i) `%s`", other_tr_idx, other_tr_name))
        log.user(
          string.format(
            "\t\t\t%i :: %i -> %i AUDIO_IN | %i -> %i MIDI_IN",
            si, rec_out, audio_in,
            get_send_flags_src(midi_flags_tr),
            get_send_flags_dest(midi_flags_tr)
            )
          )

      end
    elseif cat > 0 then
      -- HARDWARE -------------------------------------
      --
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
    logRoutesByCategory(tr, rc.flags.CAT_SEND)
    log.user('\n\tRECIEVEs:')
    logRoutesByCategory(tr, rc.flags.CAT_REC)
    log.user('\n\tHARDWARE:')
    logRoutesByCategory(tr, rc.flags.CAT_HW)
  end
end

--//////////////////////////////////////////////////////////////////////
--  CREATE ROUTE
--////////////////

function checkIfSendExists(src_tr, dest_tr)
  log.user('checkIfSendsExist')
  for si=0,  reaper.GetTrackNumSends( src_tr, 0 ) do
    local dest_tr_check = reaper.BR_GetMediaTrackSendInfo_Track( src_tr, 0, si, 1 )
    if dest_tr_check == dest_tr then
      local prev_src_midi_flags = reaper.GetTrackSendInfo_Value(src_tr, 0, si, 'I_MIDIFLAGS')
      local prev_src_audio_ch = reaper.GetTrackSendInfo_Value(src_tr, 0, si, 'I_SRCCHAN')
      -- both audio and midi
      local retval = 3
      local no_midi = prev_src_midi_flags == rc.flags.MIDI_OFF
      local no_audio = prev_src_audio_ch ==  rc.flags.AUDIO_SRC_OFF
      -- only audio = 1
      if no_midi then retval = 1 end
      -- only midi = 2
      if no_audio then retval = 2 end
      -- log.user(tostring(si) .. '   ' .. tostring(no_midi) .. '   ' .. tostring(no_audio) .. '   ' .. tostring(retval))
      return retval, si, prev_params
    end
  end
  return false
end

-- TODO
--
-- pass input str to create
--
--
--    a. call function with keybinding
--
--    b. call function with prewritten string
--
--    c.
function routing.create()
  log.clear()
  log.user('create()')

  -- TODO
  --
  -- this `selection` check is not goot
  -- it prevents calling create(str)
  --
  -- ...rm
  if not isSel() then return end

  local _, input_str = reaper.GetUserInputs("ENTER ROUTE STRING:", 1, route_help_str, input_placeholder)
  -- new route params
  local nrp = extractSendParamsFromUserInput(input_str)
  prepareRouteComponents(nrp)
end


function removeEnclosureFromString(str, encl_type)
  for r in str:gmatch ("%b"..encl_type) do
    str = str:gsub("%("..r.."%)", "")
  end
  return str
end

function getParens(str)
  local pcount = 0
  for p in str:gmatch "%b()" do
    pcount = pcount + 1
    if pcount == 1 then pDest = str.sub(p, 2, str.len(p) - 1) end
    if pcount == 2 then
      pSrc = pDest
      pDest = str.sub(p, 2, str.len(p) - 1)
      break
    end
  end
  str = removeEnclosureFromString(str, '()')
  return retval, pSrc, pDest, str
end

function getCurly(str)
  local data
  for p in str:gmatch "%b{}" do
    data = str.sub(p, 2, str.len(p) - 1)
  end
  str = removeEnclosureFromString(str, '{}')
  return data, str
end

function getBrackets(str)
  local data
  for p in str:gmatch "%b[]" do
    data = str.sub(p, 2, str.len(p) - 1)
  end
  str = removeEnclosureFromString(str, '[]')
  return data, str
end

function extractSendParamsFromUserInput(str)
  log.user('extractSendParamsFromUserInput')
  local nrp = rc; nrp['INP'] = {}

  -- LOOK FOR ()
  local ret, pSrc, pDest, str = getParens(str) -- (){}[]

  --  gmatch comma separated list
  --    if num >> get track by gui index
  --    if str >> get match tracks
  --      add all tracks
  --        if >1 >>> prompt user >>> ARE YOU SURE?????
  --
  --        make nice log statement > easy visualize
  --
  -- SRC IS NUM ELSE ------------------------------------------
  if tonumber(pSrc) ~= nil then
    local tr = reaper.GetTrack(0, tonumber(pSrc) - 1)
    rc['src_guids'] = { reaper.GetTrackGUID( tr ) }
  else
    rc['src_guids'] = getMatchedTrackGUIDs(pSrc)
  end
  -- DEST IS NUM ELSE
  if tonumber(pDest) ~= nil then
    local tr = reaper.GetTrack(0, tonumber(pDest) - 1)
    rc['dest_guids'] = { reaper.GetTrackGUID( tr ) }
  else
    rc['dest_guids'] = getMatchedTrackGUIDs(pDest)
  end

  -- CHECK FOR [] AND ()
  --
  -- TODO
  --
  --    assign to route_params
  --
  --    create check for {} and [] in route loop
  --
  --      ignore regular a/m if {[]}
  --
  -- AUDIO CH
  local dataBracket, str = getBrackets(str)
  if dataBracket ~= nil then
    local bSrc, bDst
    local dataBracketSplit = getStringSplitPattern(dataBracket, "|")
    for d=1, #dataBracketSplit do
      local D = tonumber(dataBracketSplit[d])
      -- come up with better ranges / limits / restrictions for
      -- I_SRCCHAN
      if D < 0 or D > 4 then D = 0 end
      if d==1 then
        if D ~= nil then bDst = D else bDst = 0 end
      end
      if d==2 then
        bSrc = bDst
        if D ~= nil then bDst = D else bDst = 0 end
        break
      end
    end
    log.user('bracket: ' .. bSrc .. ' > ' .. bDst)

    -- TODO assign to rc here
    nrp.brackets = { src = bSrc, dst = bDst }
  end

  -- MIDI CH VALUES
  local dataCurly, str = getCurly(str)
  if dataCurly ~= nil then
    local cSrc, cDst
    local dataCurlySplit = getStringSplitPattern(dataCurly, "|")
    for d=1, #dataCurlySplit do
      local D = tonumber(dataCurlySplit[d])
      if D < 0 or D > 16 then D = 0 end
      if d==1 then
        if D ~= nil then cDst = D else cDst = 0 end
      end
      if d==2 then
        cSrc = cDst
        if D ~= nil then cDst = D else cDst = 0 end
        break
      end
    end
    log.user('curly: ' .. cSrc .. ' > ' .. cDst)
    -- TODO assign to rc here
    nrp.curly = { src = cSrc, dst = cDst }
  end

  -- HANDLE KEY PARAMS ------------------------------
  for key, val in pairs(nrp.default_params) do

    local pattern = "!?" .. key .. "%d?%.?%d?%d?%d?%d?" -- very generic pattern
    local s, e = string.find(str, pattern)

    if s ~= nil and e ~= nil then
      local sub_pattern = string.sub(str,s,e)
      local prefix = string.sub(sub_pattern,0,1)
      local mv_offset = 1

      if prefix == '!' then mv_offset = 2 end
      local matched_value = string.sub(str,s+mv_offset,e)

      -- TODO
      --
      -- assign [] and {} to src_ch_flags and dest_ch_flags
      --
      --   >>> then just make a check for these before a,m, and d are set in
      --   the route creation loop

      -- if a and [] ?????
      --
      -- set matched_value
      -- if [] >> set `d` flag setWithBrackest = true >>> ignore regular `d` param

      nrp.INP[key] = {
        description = val.description,
        param_name = val.param_name,
        param_value = tonumber(matched_value),
        disable = prefix == '!'
      }
    end
  end
  log.user(format.block(nrp))
  return nrp
end

function prepareRouteComponents(rp)
  log.user('prepareRouteComponents')
  local src_t
  local dest_t
  local dest_tr
  local dest_idx

  -- GET SRC TRACKS -------------------------------------------
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



function rType(rp, check_str)
  if (rp.INP['a'] ~= nil and rp.INP['m'] == nil) or (rp.INP['a'] == nil and rp.INP['m'] == nil) then
    return 'ONLY_AUDIO' == check_str -- default (audio atm)
  end
  if rp.INP['a'] == nil and rp.INP['m'] ~= nil then
    return 'ONLY_MIDI' == check_str -- only midi
  end
  if rp.INP['a'] == nil and rp.INP['m'] ~= nil then
    return 'BOTH_AUDIO_AND_MIDI' == check_str -- both audio and midi
  end
  return false
end

function routing.createRoutesLoop(rp, src_t, dest_tr)
  local df = rc.default_params
  for i = 1, #src_t do
    local src_tr =  reaper.BR_GetMediaTrackByGUID( 0, src_t[i] )
    -- why are these two put here. can they be put inside of  createisingle funcs??
    local src_tr_ch = reaper.GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
    local dest_tr_ch = incrementDestChanToSrc(dest_tr, src_tr_ch)

    local exists, old_route_id = checkIfSendExists(src_tr, dest_tr)
    if not exists then
      -- NEW //////////////////////////////////////////////////////////////////
      local new_route_id = reaper.CreateTrackSend(src_tr, dest_tr)
      if rType(rp, 'ONLY_AUDIO') then
        if rp.INP['a'] == nil then rp.INP['a'] = df['a'] end
        rp.INP['m'] = df['m']
        rp.INP['m'].param_value = rc.flags.MIDI_OFF
      end
      if rType(rp, 'ONLY_MIDI') then
        rp.INP['a'] = df['a']
        rp.INP['a'].param_value = rc.flags.AUDIO_SRC_OFF
      end
      if rType(rp, 'BOTH_AUDIO_AND_MIDI') then end
      createSingleTrackAudioRoute(new_route_id, rp, src_tr, src_tr_ch, dest_tr, dest_tr_ch)
    else
      log.user('\nEXISTS')
      -- make exists >> return strings >> easier to read
      if exists == 1 then -- ALREADY HAS AUDIO
        if rType(rp, 'ONLY_AUDIO') and rp.INP['u'] ~= nil then
          routeUpdate('audio', old_route_id, rp, src_tr)
        end
        if rType(rp,'ONLY_MIDI') then
          if rp.INP['m'] == nil then rp.INP['m'] = df['m'] end
          routeUpdate('midi', old_route_id, rp, src_tr)
        end
      elseif exists == 2 then -- ALREADY HAS MIDI
        if rType(rp, 'ONLY_MIDI') and rp.INP['u'] ~= nil then
          routeUpdate('midi', old_route_id, rp, src_tr)
        end
        if rType(rp,'ONLY_AUDIO') then
          if rp.INP['a'] == nil then rp.INP['a'] = df['a'] end
          routeUpdate('audio', old_route_id, rp, src_tr)
        end
      elseif exists == 3 then -- ALREADY HAS BOTH
        if rType(rp,'ONLY_AUDIO') and rp.INP['u'] ~= nil then
          routeUpdate('audio', old_route_id, rp, src_tr)
        end
        if rType(rp,'ONLY_MIDI') and rp.INP['u'] ~= nil then
          routeUpdate('midi', old_route_id, rp, src_tr)
        end
      end

      -- DELETE SEND IF EMPTY
      local i_src_ch = reaper.GetTrackSendInfo_Value(src_tr, 0, old_route_id, 'I_SRCCHAN')
      local i_src_midi = reaper.GetTrackSendInfo_Value(src_tr, 0, old_route_id, 'I_MIDIFLAGS')
      if i_src_ch == rc.flags.AUDIO_SRC_OFF and i_src_midi == rc.flags.MIDI_OFF then
        log.user('::delete send ' .. old_route_id .. '::')
        removeSingle(src_tr, 0, old_route_id)
      end
    end
  end
end

--////////////////////////////////////////////////////////////////////
--  REMOVE ROUTES
--/////////////////

function removeSingle(tr, cat, sendidx)
  local ret = reaper.RemoveTrackSend(tr, cat, sendidx)
end


-- all these 3 functions can be refactored into one
-- tiny function if I create a good pattern for handling
-- the removal/disabling of a send/recieve.
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
      deleteByCategory(tr, rc.flags.CAT_SEND)
    elseif kind == 1 then
      deleteByCategory(tr, rc.flags.CAT_REC)
    elseif kind == 2 then
      deleteByCategory(tr, rc.flags.CAT_SEND)
      deleteByCategory(tr, rc.flags.CAT_REC)
    end
  end
  return true
end

--///////////////////////////////////////////////////////////////////////
--  HANDLE SINGLE TRACK
--///////////////////////

function incrementDestChanToSrc(dest_tr, src_tr_ch)
  log.user('incrementDestChanToSrc')
  local dest_tr_ch = reaper.GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
  if dest_tr_ch < src_tr_ch then reaper.SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end
  return dest_tr_ch
end

function routeUpdate(type, old_route_id, rp, src_tr)
  local m = rp.INP['m']
  local df = rc.default_params
  log.user('old route id: ' .. old_route_id)
  for k, p in pairs(rp.INP) do
    log.user(p.param_name .. '  ' .. tostring(p.param_value))
    if k == 'u' then goto continue end
    if k == 'm' then -- MIDI /////////////////////////////////
      if type == 'midi' or type == 'both' then
        if p.disable then
          log.user('midi disable')
          reaper.SetTrackSendInfo_Value(
            src_tr, 0, old_route_id, p.param_name, df[k].disable_value)
        elseif p.param_value ~= nil then
          reaper.SetTrackSendInfo_Value(
            src_tr, 0, old_route_id, p.param_name, p.param_value)
        else
          reaper.SetTrackSendInfo_Value( -- if no value >> default
            src_tr, 0, old_route_id, df[k].param_name, df[k].param_value)
        end
      end
    else -- AUDIO ////////////////////////////////////////////
      if type == 'audio' or type == 'both' then
        if p.disable then
          log.user('audio disable')
          reaper.SetTrackSendInfo_Value(
            src_tr, 0, old_route_id, p.param_name, df[k].disable_value)
        elseif p.param_value ~= nil then
          reaper.SetTrackSendInfo_Value(
            src_tr, 0, old_route_id, p.param_name, p.param_value)
        else
          reaper.SetTrackSendInfo_Value( -- if no value >> default
            src_tr, 0, old_route_id, df[k].param_name, df[k].param_value)
        end
      end
    end
    :: continue ::
  end
end

function createSingleTrackAudioRoute(new_rid, route_params, src_tr, src_tr_ch, dest_tr, dest_tr_ch)
  log.user('createTrackSend')
  local df = rc.default_params
  for k, p in pairs(route_params.INP) do
    if k == 'u' then goto continue end
    if p.param_name == 'I_SRCCHAN' and p.param_value ~= rc.flags.AUDIO_SRC_OFF then
      if p.param_value ~= nil then
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, p.param_name, p.param_value)
      else
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, p.param_name, df[k].param_value)
      end
      -- if dest_tr_ch == 2 then
      --   reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, 'I_SRCCHAN',0)
      -- else
      --   reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, 'I_SRCCHAN',0|(1024*math.floor(src_tr_ch/2)))
      -- end
    else
      if p.param_value ~= nil then
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, p.param_name, p.param_value)
      else
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, p.param_name, df[k].param_value)
      end
    end
    :: continue ::
  end
end

--//////////////////////////////////////////////////////////////////////
--  FUTURE??
--////////////

-- TODO
--
-- remove this function

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
    reaper.SetTrackSendInfo_Value(src_tr, rc.flags.CAT_SEND, midi_send_id, "I_MIDIFLAGS", new_midi_flags) -- set midi_flags on reference
    reaper.SetTrackSendInfo_Value(src_tr, rc.flags.CAT_SEND, midi_send_id, "I_SRCCHAN", rc.flags.AUDIO_SRC_OFF)
  end
end

function preventRouteFeedback()
end

function doesRouteAlreadyExist()
end

function sidechainToTrackWithNameString(str)
end

function routing.sidechainSelTrkToGhostSnareTrack()
  sidechainToTrackWithNameString('ghostSnare')
end

function routing.sidechainSelTrkToGhostKickTrack()
  sidechainToTrackWithNameString('ghostKick')
end
------------------------------------------------------------------------
return routing
