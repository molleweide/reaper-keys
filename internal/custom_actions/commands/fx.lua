local log = require("utils.log")
local format = require("utils.format")

local lib_tr = require("library.tracks")
local utils_io = require("utils.fs")
local rs5k = require("plugins.rs5k")
local lib_fx = require("library.fx")

local fx_commands = {}

fx_commands.randomizeRs5kSampleForFocusedTracks = function()
  -- TODO: refactor this into configurable funcs...
  require("library.tracks").focus_tracks_fx_do(_, {
    "RS5K",
    "updateSample",
  })
end

-- TODO: generalize this to PickerSoundSourceByTrackTypeAndName
--  ~ check if track is
--       sampler | vst | ??
--  ~ can this be facilitated via fx syntax string?
--  ~ create plugin module for massive
--  ~ save some synth patches manually
--     >>> in a smart manner/dir/file structure
--  ~
--
--  see where this ends up. potentially this will become a good
--  system for easilly switching sounds
--

fx_commands.pickerSelectSampleForSamplerOnSelectOrFocusedTrack = function()
  -- TODO: on up/down or change -> previow results[1] or scroll_selection.

  local focused_track_objects, _ = lib_tr.get_focused_track_objects()
  local focus_track_obj = focused_track_objects[1]

  local function get_basename_without_extension(filepath)
    local pattern = "[\\/]?([^\\/]+)%.(%w+)$" -- Pattern to match the last part of the path and the extension
    local basename, extension = string.match(filepath, pattern)
    return basename
  end

  -- if sx_utils.trackObjHasOption(g_obj, "m") and #t_fx_by_name > 0 then
  --   -- if i want to only allow on drum lanes?
  --   -- NOTE: but this should be a more general funcion so that it becomes
  --   -- easy and flexible to update any track with a sampler.
  -- end

  if focus_track_obj then
    local first_rs5k_fx_obj = lib_fx.get_fx_objs_by_name_string(focus_track_obj.guid, rs5k.PLUGIN_NAME)
    if first_rs5k_fx_obj then
      log.debug("select `sample` for:", first_rs5k_fx_obj.name)

      local wav_files_found = utils_io.findWavFilesWithNameX(focus_track_obj.name_components[1])

      local results_prepared = {}
      for i, wavf in ipairs(wav_files_found) do
        table.insert(results_prepared, {
          full_path = wavf,
          name = get_basename_without_extension(wavf),
        })
      end

      require("library.fzf").init({
        title = string.format("Change rs5k sample for track (%s)", focus_track_obj.name),
        results = results_prepared,
        on_select_func = function(self, i)
          local selection = self.t_search_results[i]

          rs5k.updateSample(focus_track_obj, first_rs5k_fx_obj.idx, selection.full_path)

          -- if opts.next then
          --   opts.next(meta, {
          --     selection = selection,
          --   })
          -- end
          return true
        end,
        sort_comp = "name",
        entry_maker = "name",
      })
    end
  end
end

return fx_commands
