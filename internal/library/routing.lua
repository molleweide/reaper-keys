local ru = require('custom_actions.utils')
local log = require('utils.log')
-- local str_util = require('utils.string')
local format = require('utils.format')
-- local config = require('definitions.config')
local rc = require('definitions.routing')
local df = rc.default_params

local rlib = require('library.route.rlib')
local rlog = require('library.route.rlib_log')
local rlib_targets = require('library.route.rlib_targets')
local rlib_string = require('library.route.rlib_string')

local routing = {}

local input_placeholder = "(176)" -- used for testing purps

-- I was trying format the text box but I did not get it to work
local route_help_str = "route params:\n" .. "\nk int  = category" .. "\ni int  = send idx"
local div = '\n##########################################\n\n'
-- local div2 = '---------------------------------'

-- local USER_INPUT_TARGETS_DIV = '|'

--
--      REAPER BUG
--
--        create ticket on forum
--        upon writing a lot of send funcs I find that CreateTrackSend(track, nil)
--          creates a wierd kind of hwout that i have to remove manually.
--          it does not show up when logging route states
--          no error hmmm
--
--      TODO
--
--
--      inform user about feedback points
--        make it easy to manage feedback routes safely
--          list all feedback points
--            i need to learn gui asap
--
--
--      NUDGE VALUES
--
--      nudge volume
--      nudge pan
--
--      TOGGLE PARAMS
--
--      - mono / stereo
--      - mute
--      - flip phase

--  PUBLIC | move to custom.lua ???

-- func for testing that coded targets are working.
-- ie. using routing.updateState within code instead
-- of using it in-app.
function routing.testCodedTargets()
  log.user('test coded targets')
  local guid_src = getMatchedTrackGUIDs('TEST_A')
  local guid_dst = getMatchedTrackGUIDs('TEST_B')

  log.user(format.block(guid_src[1]))
  -- log.user(guid_src)

  routing.create('[0|2]R', guid_src[#guid_src].guid, guid_dst[#guid_dst].guid)
end


function routing.updateState(route_str, coded_sources, coded_dests)
  -- log.clear()
  local rp = rc
  local _

  -- !!!!
  --  I set remove_routes explicitly here. Why?
  --    Because on my second laptop this prop gets converted
  --    to true even though i never set it to true. I don't understad why.
  --    This is really wierd. Anyways, luckilly it works by setting it here
  rp.remove_routes = false

  if route_str == nil then
    rp.user_input = true
    _, route_str = reaper.GetUserInputs("ENTER ROUTE STRING:", 1, route_help_str, input_placeholder)
    if not _ then return end
  end

  local ret
  ret, rp = rlib_string.extractParamsFromString(rp, route_str)
  if not ret then return end -- something went wrong

  if coded_sources ~= nil then
    rp.coded_targets = true
    ret, rp = rlib_targets.setRouteTargetGuids(rp, 'src_guids', coded_sources)
  end
  if coded_dests ~= nil then
    rp.coded_targets = true
    ret, rp = rlib_targets.setRouteTargetGuids(rp, 'dst_guids', coded_dests)
  end

  if rp.remove_routes then
    rlib.handleRemoval(rp)
  elseif not rp.user_input then
    rlib.targetLoop(rp)
  elseif rlib.confirmRouteCreation(rp) then
    rlib.targetLoop(rp)
  else
    log.user('<ROUTE COMMAND ABORTED>')
  end
end

function routing.trackHasSends(guid, cat)
  local tr, tr_idx = ru.getTrackByGUID(guid)
  local num_routes_by_cat = reaper.GetTrackNumSends( tr, cat )
  if num_routes_by_cat > 0 then
    return true
  end
  return false
end

-- refactor these into one with variable arguments
function routing.removeAllSends(tr) rlib.removeAllRoutesTrack(tr) end
function routing.removeAllRecieves(tr) rlib.removeAllRoutesTrack(tr, 1) end
function routing.removeAllBoth(tr) rlib.removeAllRoutesTrack(tr, 2) end

-- refactor and put back to log
function routing.logRoutingInfoForSelectedTracks()
  -- log.clear()
  local log_t = ru.getSelectedTracksGUIDs()

  for i = 1, #log_t do
    local tr, tr_idx = ru.getTrackByGUID(log_t[i].guid)
    local _, current_name = reaper.GetTrackName(tr)

    log.user('\n'..div..'\n:: routes for track #' .. tr_idx+1 .. ' `' .. current_name .. '`:')
    log.user('\n\tSENDs:')
    rlog.logRoutesByCategory(tr, rc.flags.CAT_SEND)
    log.user('\tRECIEVEs:')
    rlog.logRoutesByCategory(tr, rc.flags.CAT_REC)
    log.user('\tHARDWARE:')
    rlog.logRoutesByCategory(tr, rc.flags.CAT_HW)
  end
end

return routing
