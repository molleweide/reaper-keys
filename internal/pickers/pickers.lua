local project_state = require("utils.project_state")
local log = require("utils.log")
local format = require("utils.format")
local path = require("utils.path")

local fzf = require("library.fzf")
local fu = require("utils.fzf")
local tbl = require("utils.table")
local str = require("utils.string")

local ip = require("library.info_params")

local fx_util = require("library.fx")
local lib_items = require("library.items")
local marks = require("utils.marks_regions")

-- Does some nested requires that requires fzf to be loaded first, (for now...)
require("gui2.JProjectClass")

local syntax = require("syntax.tracks")

-- !!! Because pickers operate outside of the vim loop, I need
-- to explicitly set undo points again here to make sure that each
-- picker operation is properly captured and can be undone easilly.

-- !!! Mouse scroll makes indices get whacky when selecting stuff.

local data_loaders = require("pickers.data.load_plugins_data")

local pickers = {}

pickers.add_track_fx = function(meta)
  -- Creates a global table with plugins data...
  local ok, plugins_data = data_loaders.load_plugins_data()

  if not ok then
    msg(
      "Something went wrong with loading of settings, aborting. Please check your settings file: \n"
    -- .. SETTINGS_INI_FILE
    )
    return false
  end

  fzf.init(tbl.deep_extend({
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
  }, opts))
end

pickers.test_picker = function()
  fzf.init({
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
-- todo: add all_tracks

pickers.all_tracks = function(meta, opts)
  opts = opts or {}
  local vtt = opts.vtt or syntax.getVerifiedTree()
  local t_picker_results = vtt.track_list
  log.user("<PICKER: ALL TRACKS>")

  -- TODO: Add
  -- a. Tracks that HAVE items in CURRENT region
  -- a2. Tracks that DO NOT HAVE items in CURRENT region
  -- b. Tracks that HAVE items CROSSING edit cursor

  -- TODO: should the filter be passed as a param to syntax.get_list_of_track_objects(filter)
  if opts.filter then
    if type(opts.filter) == "string" then
      t_picker_results = tbl.filter(vtt.track_list, function(o)
        return str.strHasOneOfChars(o.class, opts.filter)
      end)
    elseif type(opts.filter) == "function" then
      t_picker_results = tbl.filter(vtt.track_list, opts.filter)
    end
  end

  -- log.user(format.block(t_track_objects))
  fzf.init(tbl.deep_extend({
    title = opts.title or "All Tracks (Default)",
    results = t_picker_results,
    -- move into module
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

    -- TODO: add zone/group name before each track name
    entry_maker = require("pickers.entry_makers.track_nodes"),
  }, opts))
end
pickers.all_track_objects = pickers.all_tracks

pickers.track_fx = function(meta, opts)
  opts = opts or {}
  local fx_results = fx_util.get_track_fx_chain_info()
  -- log.user(opts.title, format.block(fx_results))
  fzf.init(tbl.deep_extend({
    title = "Browse track FX list",
    width = 1300,
    height = 700,
    x = 0,
    y = 1100,
    results = opts.results or fx_results,
    on_select_func = opts.on_select_func or function(self, i)
      local selection = self.t_search_results[i]
      if opts then
        if opts.next then
          opts.next(meta, {
            selection = selection,
          }, self)
        end
      end
      return false
    end,
    next_is_picker = opts.next_is_picker or false,
    sort_comp = "idx",
    entry_maker = function(item)
      return {
        item.idx,
        item.name,
        item.pname,
      }
    end,
    results_filter = require("pickers.results_filter.track_fx"),
  }, opts))
end

---@param tr userdata
---@param fx_idx number
pickers.track_fx_params = function(meta, opts)
  opts = opts or {}
  if not opts.node or not opts.fx_index then
    log.debug("[pickers.track_fx_params]: Requires both a track node and target fx_index!")
    return
  end
  local node = opts.node

  local t_fx_params = fx_util.get_track_fx_info(node.tr, opts.fx_index)

  -- log.user(format.block(t_fx_params))
  fzf.init(tbl.deep_extend({
    meta = {
      node = node,
      fx_index = opts.fx_index,
    },
    title = require("pickers.title_makers.track_node")(node, t_fx_params),
    width = 900,
    height = 700,
    x = 0,
    y = 1100,
    results = t_fx_params.parameters,
    on_select_func = false,
    sort_comp = "name",
    -- TODO: show if has envelope
    entry_maker = require("pickers.entry_makers.fx_parameters"),
    attach_mappings = require("pickers.attach_mappings.fx_parameters"),
    -- since i am doing deep extend I dont think I need to have opts such as
    -- extended mappings here - it will be merged in anyways..
    extended_mappings = opts.extended_mappings or nil,
  }, opts))
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
  fzf.init(tbl.deep_extend({
    title = "Track params for track: <trackname>",
    results = {},
  }, opts))
end

-- TEST: ~ SYNTAX BASED HIDING -> picker all tracks > manage track_params
--   eg. show/hide/solo/mute/volume/phase/
--
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
    title = "Track attributes (tr: <trackname>)",
    results = {},
  })
end

-- Each result entry table needs to contain all of the necessary info
-- in order to be able to dynamically update it later with a single set of
-- flexible key bindings.
-- Handle each type [toggle|spectrum|string]
pickers.track_attributes_and_parameters = function()
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
  fzf.init(tbl.deep_extend({
    title = "Track params for track: <trackname>",
    results = {},
  }, opts))
end

-- revisit my route lib
-- get all routes for track
-- reuse my track logging function but here instead.
pickers.track_routing = function()
  fzf.init(tbl.deep_extend({
    title = "Routing @track: <trackname>",
    results = {},
  }, opts))
end

-- TODO: mapping -> cycle pickers -> rec | send | hw | all |
pickers.single_track_routes = function(opts)
  local convert = require("utils.conversion")

  local tr_routes
  opts = opts or {}

  -- if not opts.result_routes then
  local tr = reaper.GetSelectedTrack(0, 0)
  local route = require("library.routing")
  tr_routes = route.get_route_object_for_track(tr)
  -- else
  --     tr_routes = opts.result_routes
  -- end

  -- log.user(format.block(tr_routes))
  fzf.init({
    meta = { track = tr },
    title = "Single track routes",
    x = -100,
    -- y = 0,
    width = 1700,
    height = 450,
    results = tr_routes,
    on_select_func = function(gui)
      log.user(format.block(gui:get_on_enter_selection()))
      return false
    end,
    sort_comp = "other_tr_name",
    results_filter = "other_tr_name",
    -- having to set enabled here is a bit stupid
    column_legend_enabled = true,
    columns_legend = {
      { 2,  "#" },
      { 14, "type/index" },
      { 24, "other_name" },
      { 4,  "src_ch" },
      { 4,  "dst_ch" },
      { 1,  "m" },
      { 1,  "p" },
      { 1,  "M" },
      { 4,  "vol" },
      { 4,  "dB" },
      { 3,  "S_m" },
      { 3,  "A_m" },
      { 5,  "m_fl" },
    },
    entry_maker = function(item)
      local ti = str.makeStringLength(tostring(item.other_tr_idx), 3)
      if ti:match("%.") then
        ti = ti:sub(0, -2)
        ti = "0" .. ti
      end
      local other = string.format("(#%s) %s", ti, item.other_tr_name)

      local int_pattern = "^%-?%d+"
      local src_chan = tostring(item.src_chan):match(int_pattern)       --:sub(1,1) -- if -1 -> <no_audio>
      local dst_chan = tostring(item.dst_chan):match(int_pattern)

      local mute = item.info_params.B_MUTE.value
      mute = mute == 1 and "x" or " "

      local phase = item.info_params.B_PHASE.value
      phase = phase == 1 and "x" or " "

      local mono = item.info_params.B_MONO.value
      mono = mono == 1 and "x" or " "

      -- todo: Reuse logic from info_params -> convert to unit = dB..
      local vol = item.info_params.D_VOL.value
      local unit = ""
      if item.unit then
        unit = " (" .. item.unit .. ")"
      end
      local vol_fmt_out = ""
      local fmt = item.info_params.D_VOL.formatted
      if fmt then
        vol_fmt_out = tostring(fmt(item.info_params.D_VOL.value)) .. unit
      end

      local sendmode = tostring(item.info_params.I_SENDMODE.value):match(int_pattern)
      local automode = tostring(item.info_params.I_AUTOMODE.value):match(int_pattern)
      local midiflags = tostring(item.info_params.I_MIDIFLAGS.value):match(int_pattern)

      return {
        item.index,
        item.type == "recieve" and "recieving from" or "sending to",
        other,
        src_chan,         -- if -1 -> <no_audio>
        dst_chan,
        mute,
        phase,
        mono,
        vol,
        vol_fmt_out,
        sendmode,
        automode,
        midiflags,
      }
    end,
    extended_mappings = {
      ["C-w"] = function(t) end,
      ["C-e"] = function(t) end,
      ["C-t"] = function(t)
        ip.handle_keys(t, _, _, "B_MUTE")
      end,
      ["C-d"] = function(t) end,
      ["C-u"] = function(t) end,
      ["C-f"] = function(t)
        ip.handle_keys(t, 0.1, _, "D_VOL")
      end,
      ["C-b"] = function(t)
        ip.handle_keys(t, 0.1, true, "D_VOL")
      end,
    },
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

  fzf.init(tbl.deep_extend({
    title = "Projects listing",
    results = {},
  }, opts))
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
    title = "syntax. zones",
    results = {},
  })
end

pickers.vtt_groups = function() end

pickers.vtt_mcsab_by_group_name = function()
  fzf.init({
    title = "syntax. MSCAB",
    results = {},
  })
end

pickers.vtt_all_fx_tracks = function() end

pickers.vtt_utils = function() end

pickers.vtt_drum_kits = function()
  fzf.init({
    title = "drum kits",
    results = {},
  })
end

pickers.marks = function()
  local t_marks = marks.get_all(false)

  fzf.init(tbl.deep_extend({

    title = "project marks",
    results = t_marks,
    sort_comp = "pos",
    entry_maker = { "isrgn", "mark_region_idx", "name", "pos" },
  }, opts))
end

pickers.regions = function(_, opts)
  local t_regions = marks.get_all(true)
  fzf.init(tbl.deep_extend({

    title = "project regions",
    results = t_regions,
    sort_comp = "pos",
    entry_maker = { "mark_region_idx", "name", "pos" },
  }, opts))
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
  fzf.init(tbl.deep_extend({
    calling_command_meta = meta,

    title = "project marks",
    results = marks_final,
    results_filter = "name",
    sort_comp = "position",                                       -- rk new
    entry_maker = { "register", "type", "name", "position" },     -- rk new
  }, opts))
end

-- get patterns from the midi patterns config file
-- definitions/midi_patterns.lua
pickers.midi_patterns = function()
  fzf.init(tbl.deep_extend({

    title = "midi patterns",
    results = {},
  }, opts))
end

-- start building out basic atomic (very important) progressions
-- that can be picked to insert chord data. Should be usable
-- with motion so that you can do `apply progression to` motion, eg beats, bar, or region.
pickers.chord_progression = function()
  fzf.init({

    title = "chord progressions",
    results = {},
  })
end

pickers.chord = function(meta, opts)
  local all_chords = require("constants.chords.chords")()
  log.debug(format.block(all_chords))
  fzf.init(tbl.deep_extend({
    title = string.format("%s: chord", meta.action_type),
    results = all_chords,
    on_select_func = function(self, i)
      local chord = self.t_search_results[i]
      if opts.next then
        opts.next(meta, {
          note_chunk = chord,
          move_cursor = opts.move_cursor,
        })
      end
    end,
    results_filter = "name_long",
    sort_comp = "name_short",
    -- chords picker should also display the step-array last in a nice manner.
    entry_maker = { "type", "name_long", "name_short" },
  }, opts))
end

pickers.scales = function(meta, opts)
  local all_scales = require("constants.scales.scales")()
  log.debug(format.block(all_scales))
  fzf.init(tbl.deep_extend({
    title = string.format("%s: scale picker", meta.action_type),
    results = all_scales,
    on_select_func = function(self, i)
      local scale = self.t_search_results[i]
      if opts.next then
        opts.next(meta, {
          scale = scale,
          move_cursor = opts.move_cursor,
        })
      end
    end,
    results_filter = "name_long",
    sort_comp = "name_short",

    -- scale picker should also display the step-array last in a nice manner.
    entry_maker = { "type", "name_long", "name_short" },
  }, opts))
end

pickers.envelope_templates = function(opts)
  local t_env_templates = require("constants.envelope_templates").TEMPLATES
  -- log.user("from inside envelope_templates", format.block(t_env_templates))
  fzf.init(tbl.deep_extend({
    title = "Envelope templates",
    results = t_env_templates,
    -- results_filter = "name",
    sort_comp = "name",
    entry_maker = function(item)
      return { item.name }
    end,
  }, opts))
end

pickers.midi_note_articulation = function()
  -- definitions/midi_articulations.lua
  local t_midi_articulations = {}
end

pickers.all_items = function()
  local t_track_objects = syntax.get_list_of_track_objects()
  local t_all_items = lib_items.get_items_in_track_objects(t_track_objects)
  log.user(format.block(t_all_items))
  fzf.init(tbl.deep_extend({
    title = "all items",
    results = t_all_items,
    sort_comp = "name",
    entry_maker = "name",
  }, opts))
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

  fzf.init(tbl.deep_extend({
    title = "visible items (lightspeed)",
    results = {},
  }, opts))
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

  fzf.init(tbl.deep_extend({
    title = "item params for: <item>",
    results = {},
  }, opts))
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

pickers.sample_selector_from_track_name = function() end

pickers.file_browser = function(opts)
  opts = opts or {}

  -- TODO: ~ opts.allow_multiple_select
  -- ~ on_wav_select

  log.user(string.format(
    [["NEW FILE BROWSER" -----
      cwd = %s
  end -------]],
    opts.cwd
  ))
  -- TODO: Add opts.restrict_to_dir.

  if not opts.cwd then
    log.debug("picker file browser requires an `opts.start_at_path` param.")
    return
  end

  -- TODO:
  -- 1. add sample library dir to def/config
  -- 2. on selection -> recursive call picker with the selected dir.
  -----
  -- On C-z, if previous dir is beyond base sample dir, don't do anything,
  -- else move back one step.
  -----
  -- C-f, preview sample,
  --      Hit C-f again to stop current preview, eg. if file is a loop.
  -----
  -- C-t, toggle play selected sample on change.
  --

  -- add ability to exclude/filter file types
  --
  local function enum_files(path)
    local i = -1
    return function()
      i = i + 1
      return reaper.EnumerateFiles(path, i)
    end
  end
  local function enum_sub_dirs(path)
    local i = -1
    return function()
      i = i + 1
      return reaper.EnumerateSubdirectories(path, i)
    end
  end

  local function scan_dir(path)
    local t_dir_scanned = {}
    for p in enum_sub_dirs(path) do
      table.insert(
        t_dir_scanned,
        { name = p, full_path = string.format("%s/%s", path, p), type = "dir", type_formatted = "dir  :" }
      )
    end

    -- TODO: ignore eg. .DS_Store
    for p in enum_files(path) do
      if p:match("DS_Store") then
        goto continue
      end

      table.insert(
        t_dir_scanned,
        { name = p, full_path = string.format("%s/%s", path, p), type = "file", type_formatted = "file :" }
      )
      ::continue::
    end
    return t_dir_scanned
  end

  local start_dir = scan_dir(opts.cwd)

  local cwd_is_ceiling = opts.cwd == opts.restrict_to_dir and "^" or ""

  -- log.user(format.block(subdirs))

  --
  --
  --
  fzf.init(tbl.deep_extend({

    title = string.format("BROWSE: %s[%s]", cwd_is_ceiling, path.trim_path_from_left(opts.cwd)),
    width = 1000,
    height = 800,
    x = 0,
    y = 1100,
    results = start_dir,
    on_select_func = function(gui)
      local _, main_input = gui:controlGetByName("main_input")
      if main_input then
      end
      local sel

      -- this pattern occurs so often that i should maybe add it to GUI?
      if gui:has_mult_select() then
        sel = gui:get_mult_select()
      else
        sel = { gui:get_on_enter_selection() }
      end

      -- log.user(format.block(sel), sel[1].type == "dir")
      -- if #sel > 1 hasFiles then
      --     get first selected wav file.

      -- get selected dirs
      local sel_dirs = tbl.filter(sel, function(o)
        return o.type == "dir"
      end)

      local sel_files = tbl.filter(sel, function(o)
        return o.type == "file"
      end)

      -- log.user("browser selection:")

      if #sel_files > 0 then
        -- if opts.mult select?
        for i, s in ipairs(sel_files) do
          log.user("FILE: Do something with file:", s.full_path)
        end
        if opts.on_select_files then
          local ret = opts.on_select_files(sel_files)
          if ret then
            return true
          end
        end
      elseif #sel_dirs > 0 then
        -- if opts.mult select?
        -- TODO: This should be a callback so that one can specify what should happen
        -- to the selection.
        local the_sel = sel_dirs[1]
        log.user("DIR", format.block(the_sel))

        opts.cwd = the_sel.full_path
        pickers.file_browser(opts)
        -- pickers.file_browser({
        --   cwd = the_sel.full_path,
        --
        --   restrict_to_dir = opts.restrict_to_dir,
        -- })
        if opts.on_select_dirs then
          opts.on_select_dirs(sel_dirs)
        end
      else
        log.debug("It seems something went wrong with processing the picker selection?!")
      end

      -- if #sel == 1 then
      --     local the_sel = sel[1]
      --     if the_sel.type == "dir" then
      --         log.user("NEW DIR")
      --         pickers.file_browser({ cwd = the_sel[1].full_path })
      --     else
      --     end
      -- else
      -- end

      return false
    end,
    sort_comp = "name",

    -- TODO: Important to show state `selected = true/false`, so that I can
    -- show this in the picker.
    entry_maker = { "type_formatted", "name" },
    -- NOTE: since this is the base implementation of the file browser, I should
    -- use the `attach_mappings` instead of extend mappings

    -- attach_mappings = require("pickers.attach_mappings.fx_parameters"),
    extended_mappings = {
      ["C-z"] = function()
        local function get_parent_dir(path)
          return path:match("(.+)/[^/]+$")
        end

        local parent_path = path.get_parent_dir(opts.cwd)
        parent_path = path.trim_trailing_slash(parent_path)

        -- log.user(string.format(
        --   [[GO BACK ------------
        -- CWD = %s
        --
        -- RESTRICTED TO = %s
        --
        -- PARENT PATH = %s
        --
        -- --]],
        --   opts.cwd,
        --   opts.restrict_to_dir,
        --   parent_path
        -- ))

        if opts.cwd == opts.restrict_to_dir then
          log.user("RESTRICTED / CANT MOVE UP")
          return
        end

        -- log.user("<C-z> goto:", parent_path)
        opts.cwd = parent_path
        pickers.file_browser(opts)
        -- pickers.file_browser({
        --   cwd = parent_path,
        --   restrict_to_dir = opts.restrict_to_dir,
        -- })
      end,
    },
  }, opts))
end

pickers.basic_prompt = function(opts)
  fzf.init(tbl.deep_extend({
    title = "Basic prompt",
    x = 200,
    width = 1000,
    height = 75,
    on_select_func = function(self)
      local _, main_input = tbl.findIndexOf(GUI.controls, "title", "main_input")
      if main_input then
        local ret, data = opts.callback(main_input.value)
        return ret
      end
      return true
    end,
  }, opts))
end

-- TODO: result entries passed need to have their categories assigned so
-- that I can have reusable mappings.
pickers.info_params = function(opts)
  local s = require("utils.string")
  log.user("pickers.info_params")

  -- ---comment
  -- ---@param t table
  -- ---@param amount number The value by which floats/doubles should b shifted.
  -- ---@param direction boolean|nil move value up or down. nudge/cycle/shift..
  -- local function handle_keys(t, amount, direction)
  --     -- TODO: check if main prompt OR focus control -> determines how I
  --     -- should get the entry object.
  --     -- local sel = t.gui_ref:get_on_enter_selection()
  --
  --     local gui = t.gui_ref
  --
  --     log.user(">>>>>>>>>", format.block(gui.meta))
  --
  --     local sel = gui:get_currently_focused_entry()
  --
  --     local dir_mult = direction and -1 or 1
  --
  --     local newval
  --
  --     if sel.type == "bool" then
  --         newval = sel.value == 0 and 1 or 0
  --     end
  --
  --     if sel.type == "int" or sel.type == "char" then
  --         local int_shift_amount = 1
  --         if sel.max or sel.min then
  --             local reverse = direction
  --             local oldval = sel.value
  --             if reverse then
  --                 newval = (oldval - int_shift_amount) % sel.max -- Cycle through 2, 1, 0
  --                 if newval < sel.min then
  --                     newval = sel.max
  --                 end
  --             else
  --                 newval = (oldval + int_shift_amount) % sel.max -- Cycle through 0, 1, 2
  --             end
  --         else
  --             newval = sel.value + dir_mult * int_shift_amount
  --         end
  --     end
  --
  --     if sel.type == "double" or sel.type == "float" then
  --         local nudge = dir_mult * amount
  --         if sel.compute then
  --             newval = sel.compute(sel.value, nudge)
  --         else
  --             newval = sel.value + nudge
  --         end
  --         if newval > sel.max then
  --             newval = sel.max
  --         end
  --         if newval < sel.min then
  --             newval = sel.min
  --         end
  --     end
  --
  --     log.user(string.format("[%s]: %s -> %s", sel.type, sel.value, newval))
  --
  --     if newval and not sel.read_only and not sel.wip then
  --         log.user(".meta = ", format.block(t.gui_ref.meta))
  --         if sel._meta.cat == "track" then
  --             reaper.SetMediaTrackInfo_Value(gui.meta.track, sel.key, newval)
  --         end
  --         if sel._meta.cat == "item" then
  --             reaper.SetMediaItemInfo_Value(gui.meta.item, sel.key, value)
  --         end
  --         if sel._meta.cat == "take" then
  --             reaper.SetMediaItemTakeInfo_Value(gui.meta.take, sel.key, newval)
  --         end
  --
  --         sel.value = newval
  --         UPDATE_RESULTS = true
  --     end
  --
  --     --
  -- end

  local title = opts.title or "INFO PARAMS"

  fzf.init(tbl.deep_extend({
    title = title,
    x = 0,
    width = 800,
    height = 1000,
    results = opts.results,
    results_filter = "name",
    sort_comp = "name",
    -- This option has to be movend into a columns subtable
    columns_ignore_last_sep = true,
    columns_legend = {
      { 16, "type" },
      { 20, "name" },
      { 8,  "value" },
      { 16, "formatted" },
    },
    entry_maker = function(item)
      local unit = ""
      if item.unit then
        unit = " (" .. item.unit .. ")"
      end
      local val_out = s.makeStringLength(tostring(item.value), 6)
      local val_fmt_out = ""
      if item.formatted then
        val_fmt_out = tostring(item.formatted(item.value)) .. unit
      end

      return { item.type, item.name, val_out, val_fmt_out }
    end,
    -- on_select_func = function(gui) end,
    -- This also has to go into a context helper subtable
    context_helper_font_size = 20,
    context_helpers = {
      {
        on_focus_change = true,
        position = "right",
        width = "700",
        func = function(gui, prompt_str, elem)
          local descr = gui:get_currently_focused_entry().description
          descr = s.insert_linebreak_at_nth_chart_closest_word_end(descr, 50)
          -- log.user("->", type(descr), format.block(descr))
          elem.label = descr or ""           --format.block(descr)
        end,
      },
    },
    extended_mappings = {
      -- NOTE: all binds that change a value will flip a boolean toggle param.
      -- SMALL UP/DOWN
      -- TODO: prompt -> custom set value
      -- TODO: add specific values to each binding.
      ["C-w"] = function(t)
        -- handle_keys(t)
      end,
      ["C-e"] = function(t)
        -- handle_keys(t)
      end,
      -- MEDIUM UP/DOWN
      ["C-d"] = function(t)
        -- handle_keys(t)
      end,
      ["C-u"] = function(t)
        -- handle_keys(t)
      end,
      -- BIG UP/DOWN
      ["C-f"] = function(t)
        ip.handle_keys(t, 0.1)
      end,
      ["C-b"] = function(t)
        -- log.user(format.block(t))
        ip.handle_keys(t, 0.1, true)
      end,
    },
  }, opts))
end

return pickers
