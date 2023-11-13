local project_state = require("utils.project_state")
local log = require("utils.log")
local format = require("utils.format")

local fzf = require("library.fzf")
local fu = require("utils.fzf")
local tbl = require("utils.table")
local str = require("utils.string")

local fx_util = require("library.fx")
local lib_items = require("library.items")
local marks = require("utils.marks_regions")

local syntax = require("SYNTAX.syntax.syntax")

-- FIX: because pickers operate outside of the vim loop, I need
-- to explicitly set undo points again here to make sure that each
-- picker operation is properly captured and can be undone easilly.

local data_loaders = require("pickers.data.load_plugins_data")

-- FIX: mouse scroll makes indices get whacky when selecting stuff.

-- does some nested requires that requires fzf to be loaded first, (for now...)
require("gui2.JProjectClass")

local home = os.getenv("HOME")

local definitions_dir = "/reaper/packages/reaper-keys/definitions"

-- move this to definitions dir
local RK_FZF_ENV = {
  SETTINGS_INI_FILE = home .. definitions_dir .. "/fx-finder-settings.ini",
  SETTINGS_DEFAULT_FILE = home .. definitions_dir .. "/defaults/fx-finder-settings-default.ini",
  RK_DATA = home .. "/reaper/packages/reaper-keys/data",
}

local pickers = {}

pickers.add_track_fx = function(meta)
  -- TODO: maybe plugins data loading should go into the PROJECTS class?
  local ok, plugins_data = data_loaders.load_plugins_data(RK_FZF_ENV)
  if not ok then
    msg(
      "Something went wrong with loading of settings, aborting. Please check your settings file: \n"
    -- .. SETTINGS_INI_FILE
    )
    return false
  end

  fzf.init({
    env = RK_FZF_ENV,
    title = "Fast FX Finder",
    width = 1000,
    height = 700,
    x = 400,
    y = 1100,
    on_select_func = require("pickers.selectors.add_fx"),
    results = require("library.fx_plugins").get_all_plugins_data(),
    entry_maker = require("pickers.entry_makers.add_fx"),
    sort_comp = function(a, b)
      if a.rating > b.rating then
        return true
      elseif a.rating == b.rating then
        return a.name < b.name
      else
        return false
      end
    end,
    results_filter = require("pickers.results_filter.add_fx"),
    on_exit_callback = function(self)
      if UPDATE_RATINGS then
        table.sort(self.t_results_data, self.sort_comp)
        fu.jWriteVstData(pluginsData.DATA_INI_FILE, self.t_results_data)
        log.user("Updated ratings file!!")
      end
    end,
  })
end

pickers.test_picker = function()
  fzf.init({
    env = RK_FZF_ENV,
    title = "Test Picker",
    results = { "this", "is", "a" },
  })
end

-- TODO:
-- 1. make this picker so that I can pass opts to it so that i jump to selected
-- track in main.
-- 2. only list relevant tracks when it pertains to midi, ie. pass an option to filter
-- by track object classes. >>> syntax > get track objects list > filter classes, eg. MCAB > jump to tracks.
--

pickers.all_tracks = function(meta, opts)
  local t_track_objects = syntax.get_list_of_track_objects()

  if opts.filter then
    -- TODO: 1. move track objects filter to syntax utils `track_objs_filter_by_class(t_trk_objs, opts.filter)`
    -- 2. move put the specific filter back into ChangeActiveSelection
    t_track_objects = tbl.filter(t_track_objects, function(o)
      return str.strHasOneOfChars(o.class, opts.filter)
    end)
  end

  -- log.user(format.block(t_track_objects))

  fzf.init({
    title = opts.title or "All Tracks (Default)",
    results = t_track_objects,

    -- TODO: could passing a calback to next be moved into the default
    -- selector function?

    on_select_func = function(self, i)
      local selection = self.t_search_results[i]
      if opts.next then
        opts.next(meta, {
          selection = selection,
        })
      end
      return true
    end,
    sort_comp = "name",
    entry_maker = "name",
  })
end

pickers.browse_reaper_preferences = function()
  -- todo: read the plugins data and

  -- local RK_FZF_ENV = {
  --   SETTINGS_INI_FILE = home .. definitions_dir .. "/fx-finder-settings.ini",
  --   SETTINGS_DEFAULT_FILE = home .. definitions_dir .. "/defaults/fx-finder-settings-default.ini",
  --   RK_DATA = home .. "/reaper/packages/reaper-keys/data",
  -- }

  --  	local SETTINGS_INI_FILE = env.SETTINGS_INI_FILE
  -- local SETTINGS_DEFAULT_FILE = env.SETTINGS_DEFAULT_FILE
  --
  -- log.user(SETTINGS_INI_FILE, SETTINGS_DEFAULT_FILE)
  --
  -- settings.jSettingsCreate(SETTINGS_INI_FILE, SETTINGS_DEFAULT_FILE)
  -- SETTINGS = assert(settings.jSettingsReadFromFile(SETTINGS_INI_FILE), "Could not open settings file.")

  fzf.init({
    env = RK_FZF_ENV,
    title = "Reaper preferences",
    results = {},
  })
end

pickers.track_fx = function()
  local fx_results = fx_util.get_track_fx_chain_info()

  log.user(format.block(fx_results))

  fzf.init({
    title = "Browse track FX list",
    results = fx_results,
    sort_comp = "idx",
    entry_maker = { "idx", "name", "pname" },
  })
end

pickers.track_fx_params = function()
  local t_fx_params
  fzf.init({
    env = RK_FZF_ENV,
    title = "Fx params for <fx_name> on track <track_name>",
    results = {},
  })
end

-- ~ create list of relevant track params
-- ~ figure out how i can show them all in one picker.
pickers.track_channel_mix_params = function()
  local t_track_params = {
    -- volume =
    -- pan =
    -- phase =
    -- solo =
    -- mute =
    -- active =
    -- armed =
    -- record_monitoring =
    -- fx = next > fx menu
    -- routing
  }
  fzf.init({
    env = RK_FZF_ENV,
    title = "Track params for track: <trackname>",
    results = {},
  })
end

pickers.track_attributes = function()
  --   boolean retval, string stringNeedBig = reaper.GetSetMediaTrackInfo_String(MediaTrack tr, string parmname, string stringNeedBig, boolean setNewValue)
  -- Get or set track string attributes.
  -- P_NAME : char * : track name (on master returns NULL)
  -- P_ICON : const char * : track icon (full filename, or relative to resource_path/data/track_icons)
  -- P_MCP_LAYOUT : const char * : layout name
  -- P_RAZOREDITS : const char * : list of razor edit areas, as space-separated triples of start time, end time, and envelope GUID string.
  -- Example: "0.0 1.0 \"\" 0.0 1.0 "{xyz-...}"
  -- P_RAZOREDITS_EXT : const char * : list of razor edit areas, as comma-separated sets of space-separated tuples of start time, end time, optional: envelope GUID string, fixed/fipm top y-position, fixed/fipm bottom y-position.
  -- Example: "0.0 1.0,0.0 1.0 "{xyz-...}",1.0 2.0 "" 0.25 0.75"
  -- P_TCP_LAYOUT : const char * : layout name
  -- P_EXT:xyz : char * : extension-specific persistent data
  -- P_UI_RECT:tcp.mute : char * : read-only, allows querying screen position + size of track WALTER elements (tcp.size queries screen position and size of entire TCP, etc).
  -- GUID : GUID * : 16-byte GUID, can query or update. If using a _String() function, GUID is a string {xyz-...}.

  fzf.init({
    env = RK_FZF_ENV,
    title = "Track attributes (tr: <trackname>)",
    results = {},
  })
end

-- revisit my route lib
-- get all routes for track
-- reuse my track logging function but here instead.
pickers.track_routing = function()
  fzf.init({
    env = RK_FZF_ENV,
    title = "Routing @track: <trackname>",
    results = {},
  })
end

pickers.midi_editor_take_screensets = function()
  --
end

pickers.track_list_ui = function() end

pickers.projects = function()
  -- ReaProject retval, optional string projfn = reaper.EnumProjects(integer idx)
  -- -- idx=-1 for current project,projfn can be NULL if not interested in filename. use idx 0x40000000 for currently rendering project, if any.

  -- maybe i just need to do a bash script to collect all projects from
  -- my projects dir.

  fzf.init({
    env = RK_FZF_ENV,
    title = "Projects listing",
    results = {},
  })
end

-- 	FIX: make vtt into a class
-- 	I need to make the vtt into a class so that I can attach methods to it
-- 	that make it a bit easier to filter the tree.

pickers.track_syntax = function()
  -- 	local vtt = syntax.getVerifiedTree()
  -- 	vtt.for_each_real_track()
  -- 	   ie. loop zone > G > collect all real tracks (classes AM).
  -- 	   put these in picker.
  --
end

pickers.vtt_zones = function()
  fzf.init({
    env = RK_FZF_ENV,
    title = "syntax: zones",
    results = {},
  })
end

pickers.vtt_groups = function() end

pickers.vtt_mcsab_by_group_name = function()
  fzf.init({
    env = RK_FZF_ENV,
    title = "syntax: MSCAB",
    results = {},
  })
end

pickers.vtt_all_fx_tracks = function() end

pickers.vtt_utils = function() end

pickers.vtt_drum_kits = function()
  fzf.init({
    env = RK_FZF_ENV,
    title = "drum kits",
    results = {},
  })
end

pickers.marks = function()
  local t_marks = marks.get_all(false)

  fzf.init({
    env = RK_FZF_ENV,
    title = "project marks",
    results = t_marks,
    sort_comp = "pos",
    entry_maker = { "isrgn", "mark_region_idx", "name", "pos" },
  })
end

pickers.regions = function()
  local t_regions = marks.get_all(true)

  fzf.init({
    env = RK_FZF_ENV,
    title = "project regions",
    results = t_regions,
    sort_comp = "pos",
    entry_maker = { "mark_region_idx", "name", "pos" },
  })
end

pickers.marks_and_regions = function(meta, opts)
  local ok, all_marks = project_state.getAll("marks")
  if not ok or not all_marks then
    return
  end
  local marks_final = {}
  for _, m in pairs(all_marks) do
    table.insert(marks_final, m)
  end

  fzf.init({
    env = RK_FZF_ENV,
    title = "project marks",

    on_select_func = function(self, i)
      local selection = self.t_search_results[i]
      if opts then
        if opts.next then
          opts.next(meta, {
            selection = selection,
          })
        end
      end
      return true
    end,

    results = marks_final,
    results_filter = "name",
    -- sort_comp = "pos", -- old
    sort_comp = "position", -- rk new
    -- entry_maker = { "isrgn", "mark_region_idx", "name", "pos" }, -- old
    entry_maker = { "register", "type", "name", "position" }, -- rk new
  })
end

-- get patterns from the midi patterns config file
-- definitions/midi_patterns.lua
pickers.midi_patterns = function()
  fzf.init({
    env = RK_FZF_ENV,
    title = "midi patterns",
    results = {},
  })
end

-- start building out basic atomic (very important) progressions
-- that can be picked to insert chord data. Should be usable
-- with motion so that you can do `apply progression to` motion, eg beats, bar, or region.
pickers.chord_progression = function()
  fzf.init({
    env = RK_FZF_ENV,
    title = "chord progressions",
    results = {},
  })
end

pickers.chord = function(meta, opts)
  fzf.init({
    env = RK_FZF_ENV,
    title = string.format("%s: chord", meta.action_type),
    on_select_func = function(self, i)
      local chord = self.t_search_results[i]

      if opts.next then
        opts.next(meta, {
          chord = chord,
          move_cursor = opts.move_cursor,
        })
      end
    end,
    results = require("definitions.chords"),
    results_filter = 1,
    sort_comp = 1,
    -- RENAME: vstTable...
    entry_maker = 1,
  })
end

pickers.envelope_template = function()
  local t_env_templates = {}
end

pickers.midi_cc_templates = function()
  -- i can start sketching these out in a config table.
  -- definitions/midi_cc_curves.lua
  local t_midi_cc_curves = {}
end

pickers.midi_note_articulation = function()
  -- definitions/midi_articulations.lua
  local t_midi_articulations = {}
end

pickers.all_items = function()
  local t_track_objects = syntax.get_list_of_track_objects()
  local t_all_items = lib_items.get_items_in_track_objects(t_track_objects)
  log.user(format.block(t_all_items))
  fzf.init({
    env = RK_FZF_ENV,
    title = "all items",
    results = t_all_items,
    sort_comp = "name",
    entry_maker = "name",
  })
end

pickers.all_visible_items = function()
  local windows = require("library.windows")
  local mtracks = require("library.tracks")

  local t_track_objects = syntax.get_list_of_track_objects()

  local tracks_cnt = reaper.GetNumTracks()

  reaper.PreventUIRefresh(1)

  local _, _, tcp_height = windows.get_main_tcp_size()

  local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)

  local prev_tr_visible = false

  for tr = 0, tracks_cnt - 1 do
    local track = reaper.GetTrack(0, tr)

    local t_tr_dim = mtracks.get_dimensions_for(track)

    if reaper.IsTrackVisible(track, false) and t_tr_dim.tcp_win_y >= 0 and t_tr_dim.tcp_win_yh <= tcp_height then
      prev_tr_visible = true
      local item_cnt = reaper.GetTrackNumMediaItems(track)
      local prev_visible = false

      for i = 0, item_cnt - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local t_item_dims = lib_items.get_dimensions(item)

        if t_item_dims.start >= start_time and t_item_dims._end <= end_time then
          reaper.SetMediaItemSelected(item, true)
          prev_visible = true
        else
          if prev_visible then
            break
          end
        end
      end
    else
      if prev_tr_visible then
        break
      end
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()

  fzf.init({
    env = RK_FZF_ENV,
    title = "visible items (lightspeed)",
    results = {},
  })
end

pickers.item_parameters = function()
  -- number reaper.GetMediaItemInfo_Value(MediaItem item, string parmname)
  -- Get media item numerical-value attributes.
  local t_item_params = {
    -- B_MUTE : bool * : muted (item solo overrides). setting this value will clear C_MUTE_SOLO.
    -- B_MUTE_ACTUAL : bool * : muted (ignores solo). setting this value will not affect C_MUTE_SOLO.
    -- C_LANEPLAYS : char * : in fixed lane tracks, 0=this item lane does not play, 1=this item lane plays exclusively, 2=this item lane plays and other lanes also play (read-only)
    -- C_MUTE_SOLO : char * : solo override (-1=soloed, 0=no override, 1=unsoloed). note that this API does not automatically unsolo other items when soloing (nor clear the unsolos when clearing the last soloed item), it must be done by the caller via action or via this API.
    -- B_LOOPSRC : bool * : loop source
    -- B_ALLTAKESPLAY : bool * : all takes play
    -- B_UISEL : bool * : selected in arrange view
    -- C_BEATATTACHMODE : char * : item timebase, -1=track or project default, 1=beats (position, length, rate), 2=beats (position only). for auto-stretch timebase: C_BEATATTACHMODE=1, C_AUTOSTRETCH=1
    -- C_AUTOSTRETCH: : char * : auto-stretch at project tempo changes, 1=enabled, requires C_BEATATTACHMODE=1
    -- C_LOCK : char * : locked, &1=locked
    -- D_VOL : double * : item volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc
    -- D_POSITION : double * : item position in seconds
    -- D_LENGTH : double * : item length in seconds
    -- D_SNAPOFFSET : double * : item snap offset in seconds
    -- D_FADEINLEN : double * : item manual fadein length in seconds
    -- D_FADEOUTLEN : double * : item manual fadeout length in seconds
    -- D_FADEINDIR : double * : item fadein curvature, -1..1
    -- D_FADEOUTDIR : double * : item fadeout curvature, -1..1
    -- D_FADEINLEN_AUTO : double * : item auto-fadein length in seconds, -1=no auto-fadein
    -- D_FADEOUTLEN_AUTO : double * : item auto-fadeout length in seconds, -1=no auto-fadeout
    -- C_FADEINSHAPE : int * : fadein shape, 0..6, 0=linear
    -- C_FADEOUTSHAPE : int * : fadeout shape, 0..6, 0=linear
    -- I_GROUPID : int * : group ID, 0=no group
    -- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
    -- I_LASTH : int * : height in pixels (read-only)
    -- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
    -- I_CURTAKE : int * : active take number
    -- IP_ITEMNUMBER : int : item number on this track (read-only, returns the item number directly)
    -- F_FREEMODE_Y : float * : free item positioning or fixed lane Y-position. 0=top of track, 1.0=bottom of track
    -- F_FREEMODE_H : float * : free item positioning or fixed lane height. 0.5=half the track height, 1.0=full track height
    -- I_FIXEDLANE : int * : fixed lane of item (fine to call with setNewValue, but returned value is read-only)
    -- B_FIXEDLANE_HIDDEN : bool * : true if displaying only one fixed lane and this item is in a different lane (read-only)
    -- P_TRACK : MediaTrack * : (read-only)
  }

  fzf.init({
    env = RK_FZF_ENV,
    title = "item params for: <item>",
    results = {},
  })
end

pickers.take_parameters = function()
  -- number reaper.GetMediaItemTakeInfo_Value(MediaItem_Take take, string parmname)
  -- Get media item take numerical-value attributes.
  local t_take_params = {
    -- D_STARTOFFS : double * : start offset in source media, in seconds
    -- D_VOL : double * : take volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc, negative if take polarity is flipped
    -- D_PAN : double * : take pan, -1..1
    -- D_PANLAW : double * : take pan law, -1=default, 0.5=-6dB, 1.0=+0dB, etc
    -- D_PLAYRATE : double * : take playback rate, 0.5=half speed, 1=normal, 2=double speed, etc
    -- D_PITCH : double * : take pitch adjustment in semitones, -12=one octave down, 0=normal, +12=one octave up, etc
    -- B_PPITCH : bool * : preserve pitch when changing playback rate
    -- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
    -- I_LASTH : int * : height in pixels (read-only)
    -- I_CHANMODE : int * : channel mode, 0=normal, 1=reverse stereo, 2=downmix, 3=left, 4=right
    -- I_PITCHMODE : int * : pitch shifter mode, -1=projext default, otherwise high 2 bytes=shifter, low 2 bytes=parameter
    -- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
    -- IP_TAKENUMBER : int : take number (read-only, returns the take number directly)
    -- P_TRACK : pointer to MediaTrack (read-only)
    -- P_ITEM : pointer to MediaItem (read-only)
    -- P_SOURCE : PCM_source *. Note that if setting this, you should first retrieve the old source, set the new, THEN delete the old.
  }

  fzf.init({
    env = RK_FZF_ENV,
    title = "take params for: <take>",
    results = {},
  })
end

pickers.load_track_from_presets = function()

  -- how are track templates/presets loaded and created in fzf?
  --
  --
  -- Archie_Track;  Smart template - Load Track template by name.lua
end

pickers.samples_explorer = function()
  -- NOTE: this script supposedly show you how to preview audio samples.
  -- /Users/hjalmarjakobsson/reaper/app/reaper/Scripts/ReaTeam Scripts/Project Properties/solger_ReaLauncher.lua

  -- 1. make locateDb out of media samples.
  -- (!)  set samples dir in user config + cronjob that updates this
  -- 2. pass locate db output to picker.
  -- 3. on select -> preview sample AND close
end

pickers.sample_selector = function() end
pickers.file_browser = function() end

return pickers
