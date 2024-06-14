local log = require("utils.log")
local format = require("utils.format")
local path = require("utils.path")

local lib_tr = require("library.tracks")
local utils_io = require("utils.fs")
local rs5k = require("plugins.rs5k")
local lib_fx = require("library.fx")

local rk_config = require("definitions.config")

local fx_commands = {}

-- move to util; there are prolly better utils in some luarock?
local function get_basename_without_extension(filepath)
  local pattern = "[\\/]?([^\\/]+)%.(%w+)$"   -- Pattern to match the last part of the path and the extension
  local basename, extension = string.match(filepath, pattern)
  return basename
end

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
--  ~ filter / exclude filetypes
--  ~ toggle live preview of sample
--  ~ mapping programmatically preview a sample. eg. if not playback..

fx_commands.pickerSelectSampleForSamplerOnSelectOrFocusedTrack = function()
  -- TODO: on up/down or change -> previow results[1] or scroll_selection.
  --

  log.clear()

  local prev_sample_path

  -- get target track
  local focused_track_objects, _ = lib_tr.get_focused_track_objects()
  local focus_track_obj = focused_track_objects[1]
  if not focus_track_obj then
    return
  end

  local function restore_sample()
    rs5k.updateSample(focus_track_obj, first_rs5k_fx_obj.idx, selection.full_path)
  end

  -- if sx_utils.trackObjHasOption(g_obj, "m") and #t_fx_by_name > 0 then
  --   -- if i want to only allow on drum lanes?
  --   -- NOTE: but this should be a more general funcion so that it becomes
  --   -- easy and flexible to update any track with a sampler.
  -- end

  local first_rs5k_fx_obj = lib_fx.get_fx_objs_by_name_string(focus_track_obj.guid, rs5k.PLUGIN_NAME)
  if not first_rs5k_fx_obj then
    return
  end

  local sample_exists, prev_sample_path = rs5k.hasSampleLoaded(focus_track_obj, first_rs5k_fx_obj.idx)

  local prev_sample_parent_dir

  if sample_exists then
    prev_sample_parent_dir = path.get_parent_dir(prev_sample_path)
  end

  log.user(string.format("sample exists = %s, prev sample = %s", sample_exists, prev_sample_parent_dir))

  -- TODO: prev_sample_path = get current sample here

  log.debug("select `sample` for:", first_rs5k_fx_obj.name)

  -- NOTE: All of this can be replaced with the file browsers internal file
  -- selection mechanism, and filtering/hiding specific filetypes..

  -- local wav_files_found = utils_io.findWavFilesWithNameX(focus_track_obj.name_components[1])
  -- local results_prepared = {}
  -- for i, wavf in ipairs(wav_files_found) do
  --     table.insert(results_prepared, {
  --         full_path = wavf,
  --         name = get_basename_without_extension(wavf),
  --     })
  -- end
  -- require("library.fzf").init({
  --     title = string.format("Change rs5k sample for track (%s)", focus_track_obj.name),
  --     results = results_prepared,
  --     on_select_func = function(self, i)
  --         local selection = self.t_search_results[i]
  --         rs5k.updateSample(focus_track_obj, first_rs5k_fx_obj.idx, selection.full_path)
  --         -- if opts.next then
  --         --   opts.next(meta, {
  --         --     selection = selection,
  --         --   })
  --         -- end
  --         return true
  --     end,
  --     sort_comp = "name",
  --     entry_maker = "name",
  -- })

  -- FIX: if playback
  --           update the real sample.
  --       else
  --          programmatically preview the sounds.

  -- TODO: Where did i implement the [x] selected ??

  local path_start = prev_sample_parent_dir or rk_config.paths.sample_lib

  -- the new improved sample browser.
  require("pickers.pickers").file_browser({

    cwd = path_start,

    -- todo
    restrict_to_dir = rk_config.paths.sample_lib,

    on_focus_next = function(gui)
      local entry = gui:get_currently_focused_entry()
      -- log.user("[on_focus_next]: entry =", format.block(entry))
      if path.check_file_ext(entry.full_path, "wav") then
        -- log.user("is wav file")
      rs5k.updateSample(focus_track_obj, first_rs5k_fx_obj.idx, entry.full_path)
      end
    end,

    on_select_files = function(files)
      -- log.user("files:", files)
      return true
    end,

    -- i dont need to impl this...
    on_select_dirs = function(dirs)
      log.user("dirs:", dirs)
    end,
    on_exit_callback = function()
      -- log.user("sample picker on exit")
      -- restore_sample()
      if path.check_file_ext(prev_sample_path, "wav") then
        -- log.user("is wav file")
      rs5k.updateSample(focus_track_obj, first_rs5k_fx_obj.idx, prev_sample_path)
      end
    end,
  })
end

return fx_commands
