local log = require("utils.log")
local format = require("utils.format")
local tl = require("library.timeline")
local envelopes = require("library.envelopes")
local lib_tr = require("library.tracks")

local automation_actions = {}

-- TODO: these actions should be added to `<leader>ai<key>`
-- so that I can just play around and build up the library and see what
-- little tweaks have to be made over time. and then i will be able to
-- fucking push the mix and mastering up so fucking hard.
-- --
-- ~ Delete all points for env
-- ~ Insert template for current measure.
-- ~ Remove template at cursor.
-- ~ Add template for region.
-- ~ Add template for motion.
-- ~ Move cursor to next/prev template start.
-- ~
--

automation_actions.test = function()
  local cursor_info = tl.get_cursor_info()
  local msr_start_pos = cursor_info.msr.start
  local msr_end_pos = cursor_info.msr._end
  local cursor_position = cursor_info.cursor_pos

  local BUILTIN_ENVELOPE_NAMES = {
    volume_pre_fx = { name = "Volume (Pre-FX)", search_string = "<VOLENV" },
    pan = { name = "Pan", search_string = "<PANENV" },
  }

  local t_foc_tr = lib_tr.get_focused_track_objects()

  local tr = t_foc_tr[1].tr

  local t_envs = envelopes.fltr_track_envelopes(tr)

  -- get volume envelope
  local volenv = reaper.GetTrackEnvelopeByChunkName(tr, "<VOLENV2")

  local all_builtin_envs = envelopes.track_get_all_builtin_envs(tr)

  -- if t_envs == nil or #t_envs == 0 then
  --     log.user("No envelopes found")
  --     return
  -- end

  log.user("automation test -> t_envs:", format.block(t_envs))

  --
  -- Insert points to volume curve and see what happens.
  --
  log.user("# TEST INSERT")
  envelopes.fltr_single_envelope({
    target_env = volenv,
    insert = { { position = cursor_position, param_val = 0.5 } },
  })

  --
  -- Remove points
  --
  log.user("# TEST RM MSR")
  envelopes.fltr_single_envelope({
    target_env = volenv,
    remove = { { msr_start_pos, msr_end_pos } },     -- TODO: pass the range in which to remove
  })

  --
  -- Insert multiple points
  --
  log.user("# TEST insert mult points")
  envelopes.fltr_single_envelope({
    target_env = volenv,
    insert = {
      { position = cursor_position + 2.5, param_val = 0.4 },
      { position = cursor_position + 3,   param_val = 0.6 },
    },
  })

  --
  -- Transform notes
  --
  log.user("# TEST transform points before cursor ")
  envelopes.fltr_single_envelope({
    target_env = volenv,
    filter = function(point)
      return point.position < cursor_position
    end,
    transform = { param_val = 300 },
    -- transform = { param_val = { 200, "force"} },
  })

  -- TEST: Transform in time
  log.user("# TEST transform points in time.")
  envelopes.fltr_single_envelope({
    target_env = volenv,
    filter = function(point)
      return point.position > cursor_position
    end,
    -- This should move events forward by one measure/ four QNs.
    transform = { position = 2 },
  })

  -- --   --
  -- -- 6. TODO: picker select fx param insert env points
  -- -- ------
  -- --    a. Get/select list of all possible parameters/envelopes
  -- --         -> Combine listing of [volume, pan, FX1, ..., FX2].
  -- --         -> If you select an FX, chain FX parameter selection.
  -- --      b. Prompt -> specify values to insert.
  -- --      c. Parse string.
  -- --      d. insert env points
  -- -- 7. Prompt env point substitute command.
  -- -- 8. Use motion as timeline edges
  -- --    a.
  -- -- 9. Use region as timeline edges.
  -- -- 10. Picker/prompt apply specific type of curve.
  --
  -- -- TODO: combine fltr track envs with fltr env points
  -- --
  -- envelopes.fltr_track_envelopes({
  --     target_track = "selected", -- default -> unnecessary...
  --     -- target both track volume and table -> fx name/param
  --     target_envs = { "volume", { name = "Reasamplo55000", param = 10 } },
  --     env_fltr = {
  --         filter = function(point)
  --             return point.position > cursor_position
  --         end,
  --         transform = { { right = 0.25, param_val = 0.4 } },
  --     },
  -- })
end

-- HACK: First, implement everything for basic CC curves, then
-- add -> pitch bend / channel pressure, etc..
automation_actions.midi_cc_test = function()
  local cursor_info = tl.get_cursor_info()
  local ms = cursor_info.msr.start
  local me = cursor_info.msr._end
  local cursor_position = cursor_info.cursor_pos

  log.user("###### [midi_cc_test] ######")

  local ret, ctxm = require("library.midi_editor").getMidiValidContext()
  if not ret then
    log.user("[midi_cc_test]: NO midi context could be collected.")
    return
  end

  -- TEST: MIDI CC TEST BELOW
  -- Midi cc testing should initially be done within ME so that I can see
  -- what happens when creating events but later, I could also do it from
  -- the main area.

  --
  -- Insert array of CC values
  --

  envelopes.midi_take_fltr_cc({
    take = ctxm.take,
  })

  -- envelopes.midi_take_fltr_cc({
  --   take = ctxm.take,
  --   -- This is where I specify which curve to target, what should be a
  --   -- good default here if no curve is supplied??
  --   target_curve = 5,
  --   insert = { { position = ms, param_val = 0.5 }, { position = me, param_val = 0.5 } },
  -- })

  --
  -- Remove CC events
  --

  --
  -- Transform CC events
  --

  -- -- 3. Insert values at timeselection
  -- envelopes.midi_take_fltr_cc({
  --     take = ctxm.take,
  --     preserve_edges = true,
  --     insert = "timeline_selection", -- or ts / time_sel / tsel
  -- })
  -- -- 4. Insert values at motion
  -- envelopes.midi_take_fltr_cc({
  --     take = ctxm.take,
  --     insert = "motion", -- or ts / time_sel / tsel
  -- })
  -- -- 5. Insert values at region
  -- -- 6. Insert pitch bend
  -- -- 7. delete CC values in range
  -- envelopes.midi_take_fltr_cc({
  --     take = ctxm.take,
  --     remove = { { ms, me } }, -- or ts / time_sel / tsel
  -- })
  -- -- 8. transform CC values in range.
  -- envelopes.midi_take_fltr_cc({
  --     take = ctxm.take,
  --     filter = { { ms, me } }, -- or ts / time_sel / tsel
  --     transform = 5,
  -- })
end

-- TODO: Select
-- 1. tracks
-- 2. select which types of params to randomize.
-- 3. apply fltr calls on each track.
automation_actions.picker_add_random_curves_to_selection = function() end

automation_actions.picker_builtins_add_curve = function()
  -- TODO: from the picker select which one (<CR>) extend with a
  -- new random curve
end

automation_actions.picker_add_env_curve_for_fx_param = function()
  -- TODO: Reuse my current FX -> FX param picker.
  -- 1. Insert point at cursor for selection. <CR>
end

return automation_actions
