local log = require("utils.log")
local format = require("utils.format")

local s = require("utils.string")

local midi_editor = require("library.midi_editor")
local midi_patterns = require("library.midi_patterns")

local state_interface = require("state_machine.state_interface")
local project_state = require("utils.project_state")
local tbl = require("utils.table")

--
-- UTILITY FOR DEALING WITH MIDI DATA
--

-- TODO: look at chordgun for good midi library functions
--

-- TODO: remove all the old midi stuff functions

-- /////////////////////////////////

local function wait(seconds)
  local start_time = os.clock()
  while os.clock() - start_time < seconds do
  end
end

-- local function wait2(secs, callback, ...)
--   local target_time = reaper.time_precise() + secs
--   local args = {...}
--   local function poll_time()
--     if reaper.time_precise() >= target_time then
--       callback(table.unpack(args))
--     else
--       reaper.defer(poll_time)
--     end
--   end
--   reaper.defer(poll_time)
-- end
-- -- wait(1, function() reaper.MB('Welcome to the future!', 'My script', 0) end)

-- /////////////////////////////////

-- NOTE: For midi preview to work IAC virtual midi bus has to be engaged for
-- both input and output.

-- NOTE: reaper.StuffMIDIMessage( mode, msg1, msg2, msg3 )
-- Stuffs a 3 byte MIDI message into either the Virtual MIDI Keyboard queue, or
-- the MIDI-as-control input queue, or sends to a MIDI hardware output. mode=0 for
-- VKB, 1 for control (actions map etc), 2 for VKB-on-current-channel; 16 for
-- external MIDI device 0, 17 for external MIDI device 1, etc; see
--
-- TODO: move midi constants to own file

-- // MIDI HELPER VARIABLE
-- WAS_FILTERED = 1024;  // array for storing which notes are filtered
-- PASS_THRU_CC = 0;

local MODE = 0 -- send notes to VKB

-- TYPE_MASK=0xF0;
-- CHANNEL_MASK=0x0F;
-- //OMNI=0x00;
local NOTE_ON = 0x90
local NOTE_OFF = 0x80
local VEL = 0x50 -- dec 80
-- //IN_GM=0x00;
-- //ORPHAN_KILL=0x00;
-- //ORPHAN_REMAP=0x01;
-- //OUT_AD=0x00;
-- //OUT_BFD=0x01;
-- //OUT_SD=0x02;

local midi = {}

-- for i=0, 127 do
--    midi['vkb_send_note_' .. i] = function() sendMidiNote(i) end
-- end
--
--  [1] = { val = function(note_start_index, range)
--          return note_start_index + range - 1 end} -- high thresh

function midi.sendMidiNote_71()
  sendMidiNote(61)
end

function midi.sendMidiNote_70()
  sendMidiNote(70)
end

function midi.sendMidiNote_69()
  sendMidiNote(69)
end

function midi.sendMidiNote_68()
  sendMidiNote(68)
end

function midi.sendMidiNote_67()
  sendMidiNote(67)
end

function midi.sendMidiNote_66()
  sendMidiNote(66)
end

function midi.sendMidiNote_65()
  sendMidiNote(65)
end

function midi.sendMidiNote_64()
  sendMidiNote(64)
end

function midi.sendMidiNote_63()
  sendMidiNote(63)
end

function midi.sendMidiNote_62()
  sendMidiNote(62)
end

function midi.sendMidiNote_61()
  sendMidiNote(61)
end

function midi.sendMidiNote_60()
  sendMidiNote(60)
end

function midi.sendMidiNote_59()
  sendMidiNote(59)
end

function midi.sendMidiNote_58()
  sendMidiNote(58)
end

function midi.sendMidiNote_57()
  sendMidiNote(57)
end

function midi.sendMidiNote_56()
  sendMidiNote(56)
end

function midi.sendMidiNote_55()
  sendMidiNote(55)
end

function midi.sendMidiNote_54()
  sendMidiNote(54)
end

function midi.sendMidiNote_53()
  sendMidiNote(53)
end

function midi.sendMidiNote_52()
  sendMidiNote(52)
end

function midi.sendMidiNote_51()
  sendMidiNote(51)
end

function midi.sendMidiNote_50()
  sendMidiNote(50)
end

function midi.sendMidiNote_49()
  sendMidiNote(49)
end

function midi.sendMidiNote_48()
  sendMidiNote(48)
end

function midi.sendMidiNote_47()
  sendMidiNote(47)
end

function midi.sendMidiNote_46()
  sendMidiNote(46)
end

function midi.sendMidiNote_45()
  sendMidiNote(45)
end

function midi.sendMidiNote_44()
  sendMidiNote(44)
end

function midi.sendMidiNote_43()
  sendMidiNote(43)
end

function midi.sendMidiNote_42()
  sendMidiNote(42)
end

function midi.sendMidiNote_41()
  sendMidiNote(41)
end

function midi.sendMidiNote_40()
  sendMidiNote(40)
end

function midi.sendMidiNote_39()
  sendMidiNote(39)
end

function midi.sendMidiNote_38()
  sendMidiNote(38)
end

function midi.sendMidiNote_37()
  sendMidiNote(37)
end

function midi.sendMidiNote_36()
  sendMidiNote(36)
end

function midi.sendMidiNote_35()
  sendMidiNote(35)
end

function midi.sendMidiNote_34()
  sendMidiNote(34)
end

function midi.sendMidiNote_33()
  sendMidiNote(33)
end

function midi.sendMidiNote_32()
  sendMidiNote(32)
end

function midi.sendMidiNote_31()
  sendMidiNote(31)
end

function midi.sendMidiNote_30()
  sendMidiNote(30)
end

function midi.sendMidiNote_29()
  sendMidiNote(29)
end

function midi.sendMidiNote_28()
  sendMidiNote(28)
end

function midi.sendMidiNote_27()
  sendMidiNote(27)
end

function midi.sendMidiNote_26()
  sendMidiNote(26)
end

function midi.sendMidiNote_25()
  sendMidiNote(25)
end

function midi.sendMidiNote_24()
  sendMidiNote(24)
end

function midi.sendMidiNote_23()
  sendMidiNote(23)
end

function midi.sendMidiNote_22()
  sendMidiNote(22)
end

function midi.sendMidiNote_21()
  sendMidiNote(21)
end

function midi.sendMidiNote_20()
  sendMidiNote(20)
end

function midi.sendMidiNote_19()
  sendMidiNote(19)
end

function midi.sendMidiNote_18()
  sendMidiNote(18)
end

function midi.sendMidiNote_17()
  sendMidiNote(17)
end

function midi.sendMidiNote_16()
  sendMidiNote(16)
end

function midi.sendMidiNote_15()
  sendMidiNote(15)
end

function midi.sendMidiNote_14()
  sendMidiNote(14)
end

function midi.sendMidiNote_13()
  sendMidiNote(13)
end

function midi.sendMidiNote_12()
  sendMidiNote(12)
end

function midi.sendMidiNote_11()
  sendMidiNote(11)
end

function midi.sendMidiNote_10()
  sendMidiNote(10)
end

function midi.sendMidiNote_09()
  sendMidiNote(9)
end

function midi.sendMidiNote_08()
  sendMidiNote(8)
end

function midi.sendMidiNote_07()
  sendMidiNote(7)
end

function midi.sendMidiNote_06()
  sendMidiNote(6)
end

function midi.sendMidiNote_05()
  sendMidiNote(5)
end

function midi.sendMidiNote_04()
  sendMidiNote(4)
end

function midi.sendMidiNote_03()
  sendMidiNote(3)
end

function midi.sendMidiNote_02()
  sendMidiNote(2)
end

function midi.sendMidiNote_01()
  sendMidiNote(1)
end

function midi.sendMidiNote_00()
  sendMidiNote(0)
end

--  TODO
--
--    how can I use key-release here??
--      write an issue > ask Mike about this

function sendMidiNote(note_num)
  reaper.StuffMIDIMessage(MODE, NOTE_ON, note_num, VEL)
  -- wait()
  reaper.StuffMIDIMessage(MODE, NOTE_OFF, note_num, VEL)
end

-- this string color makes it easier to read...
local easy_read = [[
\*\ eaper.StuffMIDIMessage(integer mode, integer msg1, integer msg2, integer msg3)

  Stuffs a 3 byte MIDI message into either the Virtual MIDI Keyboard queue, or
  the MIDI-as-control input queue, or sends to a MIDI hardware output.  mode=0
  for VKB, 1 for control (actions map etc), 2 for VKB-on-current-channel; 16
  for external MIDI device 0, 17 for external MIDI device 1, etc; see
  GetNumMIDIOutputs, GetMIDIOutputName.

\*\ integer reaper.GetNumMIDIOutputs()

  returns max number of real midi hardware outputs

\*\ boolean retval, string nameout = reaper.GetMIDIOutputName(integer dev, string nameout)

  returns true if device present
]]

-- -- this is a test function i copied from MPLs scripts
-- midi.reorderNotes = function()
-- 	-- for key in pairs(reaper) do
-- 	-- 	_G[key] = reaper[key]
-- 	-- end
--
-- 	function ReorderNotes(percent)
-- 		local ME = reaper.MIDIEditor_GetActive()
-- 		if not ME then
-- 			return
-- 		end
-- 		local take = reaper.MIDIEditor_GetTake(ME)
-- 		if not take or not reaper.TakeIsMIDI(take) then
-- 			return
-- 		end
--
-- 		local last_t
-- 		for i = 1, ({ reaper.MIDI_CountEvts(take) })[2] do
-- 			local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = MIDI_GetNote(take, i - 1)
-- 			if selected and i > 1 then
-- 				local len = endppqpos - startppqpos
-- 				startppqpos = last_t.endppqpos + 1
-- 				endppqpos = startppqpos + len
-- 				reaper.MIDI_SetNote(take, i - 1, true, muted, startppqpos, endppqpos, chan, pitch, vel, true)
-- 			end
-- 			last_t = { startppqpos = startppqpos, endppqpos = endppqpos }
-- 		end
-- 		reaper.MIDI_Sort(take)
-- 	end
--
-- 	Undo_BeginBlock()
-- 	ReorderNotes()
-- 	Undo_EndBlock("Reorder notes", 0)
-- end

--
-- operator / command
--
-- insert chunks of midi notes
--

-- TODO: make sure I don't use midi step state when executing as a regular
-- command. >>> maybe the midi_step_state should be passed down to the
-- insertMidiNoteChunk func - then i can just chek if meta.mode == midi_step,
-- and then also only retrieve the state if the correct mode
--
-- rename: buildNoteChunkForInsertion()??
--
function midi.insertMidiNoteChunk(meta, opts)
  opts = opts or {}

  log.debug("insertMidiNoteChunk opts", format.block(opts))

  -- could this also be passed as an arg?
  local ret, ctxm = require("library.midi_editor").getMidiValidContext()
  if not ret then
    return
  end

  -- TODO: move to
  -- lib/cursor.get()
  -- lib/midi.get_active_note_row()
  -- lib/midi.get_important_contexts() -- merge getMidiValidContext with these and return table.
  local cursor_pos = reaper.GetCursorPosition()
  local active_note_row = reaper.MIDIEditor_GetSetting_int(ctxm.editor, "active_note_row")

  local t_note_pitches = {}
  local t_midi_notes = {}

  local sixteen_note_len = 0.25 / 2

  --

  local step_len = opts.note_duration ~= nil and opts.note_duration or sixteen_note_len
  local step_len_time_abs = reaper.TimeMap_QNToTime_abs(0, step_len)

  local note_end_gap = opts.staccatto and step_len * 0.50 or step_len * 0.005

  local note_duration = step_len - note_end_gap -- only used if midi step
  local note_duration_time_abs = reaper.TimeMap_QNToTime_abs(0, note_duration)

  -- This should be done inside of the action IDs themselves, and then they're
  -- passed as params to this func.
  local direction_mult = 1
  if opts.ascending ~= nil then
    direction_mult = opts.ascending and 1 or -1
  elseif opts.direction ~= nil then
    direction_mult = opts.direction
  end

  local octave_add = type(opts.octave_next) == "number" and (opts.octave_next * 12) or 0

  if opts.move_cursor then
    local new_pos = meta.end_pos and meta.endpos or reaper.GetCursorPosition() + step_len
    if meta.end_pos then
      new_pos = meta.end_pos
    elseif opts.note_duration then
      -- log.user("... opts.note_duration")
      new_pos = reaper.GetCursorPosition() + step_len_time_abs
      -- log.user("DUR:", reaper.GetCursorPosition(), opts.note_duration, new_pos)
    else
      -- log.user("opts.move_cursor else...")
      new_pos = reaper.GetCursorPosition() + step_len
    end
    reaper.SetEditCurPos(new_pos, false, false)
  end

  if opts.silent then
    return
  end

  -- fix: handle incoming chord here...
  --
  -- fix: handle single incoming pitches as well??
  --
  -- fix: handle direction ->
  --
  --
  -- FIX: If chord, then we don't move the pitch/active or whatever,
  -- ONLY if single note?
  -- Or should there be a possible to insert a chord and also move the
  -- active center pitch all at once?

  if opts.note_chunk then
    for _, chord_rel_pitch in ipairs(opts.note_chunk.relative_intervals) do
      -- TODO: ADD OCTAVE
      local new_pitch = active_note_row + octave_add + chord_rel_pitch * direction_mult

      table.insert(t_note_pitches, new_pitch)
    end
  else
    table.insert(t_note_pitches, active_note_row)
  end

  -- if opts.move_note_row...
  reaper.MIDIEditor_SetSetting_int(
    ctxm.editor,
    "active_note_row",
    active_note_row + octave_add + opts.note_chunk.relative_intervals[1] * direction_mult
  )

  -- compute note duration
  -- can I do the action_type differentiation in the action handlers, and pass
  -- all args via the opts table.
  local note_start_pos, note_end_pos
  if meta.action_type == "timeline_operator" then
    note_start_pos = meta.start_pos
    note_end_pos = meta.end_pos
  else
    note_start_pos = cursor_pos
    if opts.note_duration then
      note_end_pos = cursor_pos + note_duration_time_abs
    elseif meta.action_type:match("command$") then
      -- I should always use opts.note_duration, so this clause should never be reached mostly.
      note_end_pos = cursor_pos + note_duration
    else
      log.debug("No duration for insertMidiNoteChunk could be computed!")
      return
    end
  end

  -- MOVE CURSOR / ROW

  --
  -- BUILD / INSERT NOTES
  --

  for i in ipairs(t_note_pitches) do
    local t_new_note = {}
    t_new_note.pitch = t_note_pitches[i]
    t_new_note.time_pos_start = note_start_pos
    t_new_note.time_pos_end = note_end_pos
    table.insert(t_midi_notes, t_new_note)
  end
  log.user("[ insertMidiNoteChunk ]: t_midi_notes =", format.block(t_midi_notes))

  -- FIX: use midi.take_transform instead and return the indices of inserted pitches,
  -- so that user can get back to most recently inserted notes.
  midi.insert_notes({
    take = ctxm.take,
    notes = t_midi_notes,
  })

  if opts.playback then
    for _, note in ipairs(t_midi_notes) do
      reaper.StuffMIDIMessage(MODE, NOTE_ON, note.pitch, VEL)
    end
    wait(0.5)
    for _, note in ipairs(t_midi_notes) do
      reaper.StuffMIDIMessage(MODE, NOTE_OFF, note.pitch, VEL)
    end
  end

  return opts, t_midi_notes
end

-------------------------------------------------------
-------------------------------------------------------

-- TODO: migrate this to RK state interface and keep everything in the
-- main state table.
--
-- i need to do this so that everything can be reset when running the
-- goToNormal command

-- midi.set_step_state = function(state)
-- 	project_state.overwrite("mode_state", "midi_step", state)
-- end

midi.get_midi_step_state = function()
  local did_exist, midi_step_state = project_state.get("mode_state", "midi_step")
  if not did_exist then
    midi_step_state = {
      silent = false,
      direction = true,
    }
  end
  return did_exist, midi_step_state
end

-------------------------------------------------------
-------------------------------------------------------

midi.insert_notes = function(opts)
  if not opts.notes then
    return
  end
  local note_defaults = require("constants.constants").midi_note_defaults

  local take

  if opts.item then
    take = reaper.GetMediaItemTake(opts.item, 0)
  elseif opts.take then
    take = opts.take
  end

  -- local take = opts.take

  for _, t_note in ipairs(opts.notes) do
    if not t_note.silent then
      if type(t_note.pitch) == "table" then
        for _, pitch in ipairs(t_note.pitch) do
          local t_new_note = tbl.copy(t_note)
          t_new_note.pitch = pitch
          midi.insert_single_note(take, t_new_note)
        end
      else
        midi.insert_single_note(take, t_note, false)
      end

      -- local ret = reaper.MIDI_InsertNote(
      --   take,
      --   note_defaults.selected,
      --   note_defaults.muted,
      --   reaper.MIDI_GetPPQPosFromProjTime(take, t_note.ppq_s),
      --   reaper.MIDI_GetPPQPosFromProjTime(take, t_note.ppq_e),
      --   note_defaults.chan,
      --   t_note.pitch,
      --   note_defaults.velocity,
      --   note_defaults.noSortIn
      -- )
    end
  end
  if opts.sort ~= false then
    reaper.MIDI_Sort(take)
  end
end

midi.insert_single_note = function(take, note, noSortIn)
  local note_defaults = require("constants.constants").midi_note_defaults
  return reaper.MIDI_InsertNote(
    take,
    note.sel and note.sel or note_defaults.selected,
    note.muted and note.muted or note_defaults.muted,
    note.ppq_s and note.ppq_s or reaper.MIDI_GetPPQPosFromProjTime(take, note.time_pos_start),
    note.ppq_e and note.ppq_e or reaper.MIDI_GetPPQPosFromProjTime(take, note.time_pos_end),
    note.ch and note.ch or note_defaults.chan,
    note.pitch and note.pitch or note_defaults.pitch,
    note.vel and note.vel or note_defaults.velocity,
    noSortIn and noSortIn or note_defaults.noSortIn
  )
end

-- TODO: move to midi library and rename to midi.remove_notes({opts})
-- improve by adding a range from [60, 64]
-- range opt
-- note filter opt, eg notes outside of scale or predicate.

midi.remove_notes = function(take, t_midi_events, active_note_row, filter_indices)
  if not t_midi_events then
    return
  end

  -- log.user("tme",format.block(t_midi_events))

  for i = 1, t_midi_events[2] do
    local note_idx = i - 1
    local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)
    if pitch == active_note_row then
      reaper.MIDI_DeleteNote(take, note_idx)
    end
  end
end

--
-- midi selection
--

-- make it easier to select midi chunks close in time proximity
midi.select_notes = function()

  -- vertical | chords
  -- similar onset time or playing simultaneously

  -- horizontal | scales / patterns
  --
end

--- Deleting notes needs to be done from the end of the array to
--- preserve indices of existing notes.
---
---@param take userdata
---@param t_notes table
midi.delete_notes = function(take, t_notes)
  for i = #t_notes, 1, -1 do
    reaper.MIDI_DeleteNote(take, t_notes[i].index)
  end
end

-- midi.insert_notes = function(take, t_notes)
--       for i, note in ipairs(t_notes) do
--         midi.insert_single_note(take, note)
--       end
-- end

-------------------------------------------------------------------------------
-- API: This is the main midi_function for managing midi data.
-- It can do the following:
-- 1. filter input
-- 2. transform filtered events
-- 3. remove filtered events
-- 4. insert new events
--
-- Some, functionalities can be applied together or at once.
-------------------------------------------------------------------------------
--

-- this function should prolly go into lib/items
--
--
-- note_filters = takes parameters
--     ~ bool
--     ~ number
--     ~ table of numbers or sub-tables with a two digit range to filter out.
--         >> you can supply multiple ranges.
--
--  FIX:I need to do error handling, eg. ranges, and values.
--
--- Currently returns the data filter output.
---
---@param take userdata
---@param opts table
---@return table | nil
midi.midi_take_filter_transform = function(take, opts)
  if not take or not reaper.TakeIsMIDI(take) then -- or midi take...
    log.debug("No take was supplied to midi.midi_take_filter_transform")
    return
  end
  if opts.insert and opts.remove then
    log.debug("midi transform filter: you cannot INSERT and REMOVE at same time")
    return
  end

  -- FIX: you can insert and transform at same time, ie the insertion data will
  -- be pre transformed. BUT you cannot transform and delete at the same time.
  --
  -- FIX: only one type notes/cc/syx can be handled at once??

  local filter = opts.filter or {}
  local note_filter = filter.notes or {}
  local cc_filter = filter.cc or {}
  local syx_filter = filter.syx or {}

  log.user(format.block(opts), "*********")

  -- NOTE: Hmmm, by doing type = { notes|cc|syx }, it allows me to do removal
  -- and insertion of differnt types at once.

  if opts.remove and (opts.transform or opts.insert) then
    -- if transform and insert -> transform needs to be done first!
    log.debug("MIDI (filter/transform): Cannot remove and transform together! Abort..")
    return
  end

  local remove = opts.remove or {}
  local transform = opts.transform or {}
  local insert = opts.insert or {}

  --

  -- you can either

  local no_filters = not note_filter and not cc_filter and not syx_filter

  local t_notes = {}
  local t_cc = {}
  local t_syx = {}

  log.debug(string.format([[midi_take_filter_transform; filter=%s, noflt=%s ]], filter, no_filters))

  --
  -- ENSURE MIDI DATA: COLLECT ALL NOTES IN TAKE || ASSIGN INSERTION DATA
  --

  if not opts.insert then
    local ret, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
    for i = 0, notecnt do
      local ret, sel, muted, ppq_s, ppq_e, ch, pitch, vel = reaper.MIDI_GetNote(take, i)
      -- if filt_low <= pitch and pitch <= filt_high then
      table.insert(t_notes, {
        index = i,
        muted = muted,
        ppq_s = ppq_s,
        ppq_e = ppq_e,
        ch = ch,
        -- real_pitch = pitch,
        pitch = pitch,
        vel = vel,
        sel = sel,
      })
      -- end
    end
  else
    -- NOTE: Pass notes for insertion.
    -- It is important here that I have a unified way for setting up midi data.
    --
    -- this means that an item hass been passed and I want to insert notes.
    -- This api is a bit unclear but i have to look at this later.
    log.user("did we get here?")
    t_notes = opts.insert.midi_data.notes
  end

  ---------------------------------------------------------
  -- FILTER MIDI NOTE DATA
  --

  -- remove filtered data
  if remove.notes then
    note_filter = remove.notes
  end

  if no_filters or note_filter then
    for k, v in pairs(note_filter) do
      if type(v) == "boolean" then
        t_notes = tbl.filter(t_notes, function(note)
          return note[k] == v
        end)
      elseif type(v) == "number" then
        t_notes = tbl.filter(t_notes, function(note)
          return note[k] == v
        end)
      elseif type(v) == "table" then
        -- FIX: since there can be multiple ranges, i need to collect the filtered
        -- values and then assign them to t_notes at the end
        for _, subv in pairs(v) do
          if type(subv) == "number" then
            t_notes = tbl.filter(t_notes, function(note)
              return note[k] == subv
            end)
          elseif type(subv) == "table" then
            t_notes = tbl.filter(t_notes, function(note)
              return subv[1] <= note[k] and note[k] <= subv[2]
            end)
          end
        end
      elseif type(v) == "function" then
        log.user("?????????")
        t_notes = tbl.filter(t_notes, v) -- pass filter func
      end
    end
  end

  if no_filters or cc_filter then
    for k, v in pairs(cc_filter) do
    end
  end

  if no_filters or syx_filter then
    for k, v in pairs(syx_filter) do
    end
  end

  ---------------------------------------------------------
  -- HANDLE MIDI NOTE DATA
  --

  -- delete filtered notes
  if remove.notes then
    midi.delete_notes(take, t_notes)

    -- TODO: insert.notes is not yet implemented. Atm midi data is assigned
    -- to insert = {data}, but I should make it possible to do this with
    --    -> insert {notes|cc|syx}
  elseif transform.notes or insert.notes then
  end

  local notes_updated = 0
  if transform.notes then
    for i, note in ipairs(t_notes) do
      local update = false
      for k, v in pairs(transform.notes) do
        if type(v) == "boolean" then
          log.trace("midi take transform: set bool:", i, note[k], "->", v)
          note[k] = v -- set bool value
          update = true
        elseif type(v) == "number" then
          log.trace("midi take transform: shift num:", i, note[k], "->", note[k] + v)
          note[k] = note[k] + v -- shift by number
          update = true
        elseif type(v) == "table" then
          log.trace("midi take transform: force const:", i, note[k], "->", v[1])
          note[k] = v[2] == "force" and v[1] -- { number, "force"} means force all notes to value
          update = true
        elseif type(v) == "function" then
          log.trace("midi take transform: func:", i, note[k], "->", v(note))
          note[k] = v(note) -- apply function transform per note
          update = true
        end
        if update then
          -- i am not sure if this is useful to keep a counter
          notes_updated = notes_updated + 1
        end
      end -- transform.notes -> k, v
    end -- t_notes -> i, note
  end

  if (notes_updated > 0 or opts.insert) and not opts.dry_run then
    if not opts.insert then
      midi.delete_notes(take, t_notes)
    end
    log.user("just before inserting notes")
    midi.insert_notes({
      take = take,
      notes = t_notes,
    })
  end

  ---------------------------------------------------------
  -- HANDLE MIDI CC DATA
  --

  ---------------------------------------------------------
  -- HANDLE MIDI SYX DATA
  --

  return {
    notes = t_notes,
    cc = t_cc,
    syx = t_syx,
  }
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------
-- Utility functions built with the above midi data interface
---------

midi.delete_notes_in_pitch_range = function(take, range_start, range_end, dry_run)
  local tr = reaper.GetMediaItemTake_Track(take)
  local index = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") - 1

  local n1 = reaper.GetTrackMIDINoteName(index, range_start, 0)
  -- reaper.GetTrackMIDINoteNameEx( proj, track, pitch, chan )

  log.user(string.format("delete_notes_in_pitch_range: [%s (%s), %s]", range_start, n1, range_end))

  return midi.midi_take_filter_transform(take, {
    dry_run = not dry_run and false or true,
    remove = {
      notes = { pitch = { { range_start, range_end } } },
    },
  })
end

midi.delete_notes_for_channel = function(take, ch, dry_run)
  return midi.midi_take_filter_transform(take, {
    dry_run = not dry_run and false or true,
    remove = {
      notes = { ch = ch },
    },
  })
end

-- func name is ambiguous
midi.shift_channels_above = function(take, chan_thresh, shift_amount, dry_run)
  return midi.midi_take_filter_transform(take, {
    dry_run = not dry_run and false or true,
    filter = {
      notes = {
        ch = function(note)
          return chan_thresh < note.ch
        end,
      },
    },
    transform = { notes = { ch = shift_amount } },
  })
end

midi.shift_pitches_above_including = function(take, pitch_thresh, shift_amount, dry_run)
  local tr = reaper.GetMediaItemTake_Track(take)
  local index = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") - 1
  local n1 = reaper.GetTrackMIDINoteName(index, pitch_thresh, 0)

  log.user(string.format("shift_pitches_above_including: %s (%s)", pitch_thresh, n1))

  require("library.midi").midi_take_filter_transform(take, {
    dry_run = dry_run,
    filter = {
      notes = {
        pitch = function(note)
          return pitch_thresh <= note.pitch
        end,
      },
    },
    transform = { notes = { pitch = shift_amount } },
  })
end

midi.shift_insert_notes = function(take, item_data, shift_amount, dry_run)
  midi.midi_take_filter_transform(take, {
    dry_run = dry_run,
    insert = item_data, -- do i need to pass midi data, or can I check inside midi transform?
    transform = {
      notes = { pitch = shift_amount },
    },
  })
end

midi.insert_notes_force_chan = function(take, force_ch, item_data, dry_run)
  midi.midi_take_filter_transform(take, {
    dry_run = not dry_run and false or true,
    insert = item_data,
    transform = {
      notes = { ch = { force_ch, "force" } },
    },
  })
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

midi.set_note_row = function(ME, pitch)
  reaper.MIDIEditor_SetSetting_int(ME.editor, "active_note_row", pitch)
end

-- Used as a pitch motion so recieves Meta.
midi.get_or_jump_current_note_row = function(amount, set_note_row)
  -- midi.get_or_jump_current_note_row = function(amount, move_cursor)
  local midi_editor = require("library.midi_editor")

  -- log.user("meta = ", format.block(meta), "opts = ", format.block(opts))

  local ME_EXISTS, ME = midi_editor.getMidiValidContext()
  if not ME_EXISTS then
    log.debug("ME did not exist in `get_or_jump_current_note_row")
    return
  end

  -- 1. if `move_with_motions`
  --       move cursor/row with motions
  -- 2.

  local follow_motions = state_interface.getKey("ME_follow_motions")

  -- log.user("follow_motions:", follow_motions)

  if set_note_row then
    local row = reaper.MIDIEditor_GetSetting_int(ME.editor, "active_note_row")
    -- midi.set_note_row(ME, pitch)

    reaper.MIDIEditor_SetSetting_int(ME.editor, "active_note_row", row + amount)
  end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- JUMP TO MIDI GRID POSITION
--
-- FIX: use while loop -> so that user doesn't send empty string...
--
-- FIX: use while loop so that user can modify their erroneous promt
-- if it doesn't validate.
--
-- TODO: refactor and improve
--
midi.jump_to_position_and_insert_by_string = function()
  opts = opts or {}

  local ret, ME_CONTEXT = require("library.midi_editor").getMidiValidContext()
  if not ret then
    return
  end

  local PATTERN_SPEC = {
    user_input = {
      title = "ME go -> insert:",
      num_inputs = 1,
      placeholder = "?", -- what would be the smartest place holder??
      input_field_width = "extrawidth=350",
      retvals_csv = "",
    },
    pattern_sep = ";", -- whitespace
  }
  PATTERN_SPEC.user_input.caption_csv =
  string.format("%s,%s", PATTERN_SPEC.user_input.placeholder, PATTERN_SPEC.user_input.input_field_width)

  local str_pat_input = opts.pattern or nil

  if not str_pat_input then
    _, str_pat_input = reaper.GetUserInputs(
      PATTERN_SPEC.user_input.title,
      PATTERN_SPEC.user_input.num_inputs,
      PATTERN_SPEC.user_input.caption_csv,
      PATTERN_SPEC.user_input.retvals_csv
    )
  end

  -- TODO:
  -- This function shall serve as the fastest method for reaching any position
  -- in a currently open ME.
  -- Needs to specify:
  --   ~ note row
  --   ~ timeline position
  --   ~ insert note
  --
  -- Later, i can combine this with:
  --   ~ chords
  --   ~ note duration
  --   ~ rhythm pattern.
  --
  -- When combining strings i only have to come up with a smart prefix OR
  -- divider, eg. `//` so that I know that anything that comes after is eg.
  -- a pattern string.
  --
  -- position -> pitches/chord -> pattern

  local t_segments = s.split(str_pat_input, PATTERN_SPEC.pattern_sep)

  local s_go_to_position = t_segments[1]

  local note_row_regex = "[abcdefg][sx]?%d"
  local timeline_regex = "%d%d"

  -- look for note row
  local row_start, row_end = string.find(s_go_to_position, note_row_regex)
  local row_match
  if row_start then
    row_match = string.sub(s_go_to_position, row_start, row_end)
    s_go_to_position = string.gsub(s_go_to_position, note_row_regex, "", 1)
  end

  -- look for timeline_operator
  local tl_start, tl_end = string.find(s_go_to_position, timeline_regex)
  local tl_match
  if tl_start then
    tl_match = string.sub(s_go_to_position, tl_start, tl_end)
  end

  log.user(row_match, tl_match)

  local function decode_pitch_step(s)
    local natural_step = string.sub(s, 1, 1)
    local accidental
    if #s > 1 then
      accidental = string.sub(s, 2, 2)
    end

    local natural_num

    if natural_step == "c" then
      natural_num = 1
    end
    if natural_step == "d" then
      natural_num = 3
    end
    if natural_step == "e" then
      natural_num = 5
    end
    if natural_step == "f" then
      natural_num = 6
    end
    if natural_step == "g" then
      natural_num = 8
    end
    if natural_step == "a" then
      natural_num = 10
    end
    if natural_step == "b" then
      natural_num = 12
    end

    if accidental then
      if accidental == "s" then
        natural_num = natural_num + 1
      end
      if accidental == "x" then
        natural_num = natural_num - 1
      end
    end

    return natural_num
  end

  local cursor_info = require("library.timeline").get_cursor_info()
  log.user(format.block(cursor_info))

  local t_results = {}

  if row_start then
    t_results.row_octave = tonumber(string.sub(row_match, #row_match, #row_match))
    t_results.row_pitch = decode_pitch_step(string.sub(row_match, 1, #row_match - 1))
    local row_final = (t_results.row_octave * 12) + t_results.row_pitch - 1
    reaper.MIDIEditor_SetSetting_int(ME_CONTEXT.editor, "active_note_row", row_final)
  end

  if tl_start then
    t_results.tl_beat = cursor_info.msr.qn_start + (tonumber(string.sub(tl_match, 1, 1) - 1))
    t_results.tl_division = 1 / 4 * (tonumber(string.sub(tl_match, 2, 2)) - 1)
    local tl_pos_qn = t_results.tl_beat + t_results.tl_division
    local tl_pos_time = reaper.TimeMap2_QNToTime(0, tl_pos_qn)

    reaper.SetEditCurPos(tl_pos_time, true, false)
  end

  log.user(format.block(t_results))
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local state_table_name = "midipatterns"

midi.create_insert_midi_pattern_by_string = function(meta, opts)
  opts = opts or {}
  local ok, t_midi_context = midi_editor.getMidiValidContext()

  log.user(format.block(t_midi_context))

  if not ok and not opts.dry_run then
    return
  end

  -- local midi_patterns_state = reaper_state.get(state_table_name)
  -- -- log.user("PREV PATTERN:", format.block(midi_patterns_state))

  local t_patterns_state, t_midi_notes = midi_patterns.parse(_, {
    pattern = opts.pattern,
    midi_context = t_midi_context,
    start_at_measure = opts.start_at_measure,
    -- HACK: Again, this is a temporary solution to have all midi data be
    -- generated from zero, so that `apply_music_transform` can shift &&
    -- insert data for each target region
    start_at_zero = opts.start_at_zero,
  })

  --
  -- FIX: Everything bellow here should go into `lib/midi.lua`
  --

  if not opts.dry_run then
    local pattern_start_ppq = reaper.MIDI_GetPPQPosFromProjTime(t_midi_context.take, t_midi_notes[1].time_pos_start)

    local pattern_end_ppq =
    reaper.MIDI_GetPPQPosFromProjTime(t_midi_context.take, t_midi_notes[#t_midi_notes].time_pos_end_without_gap)

    midi.midi_take_filter_transform(t_midi_context.take, {
      remove = {
        notes = {
          pitch = function(note)
            return note.pitch == t_midi_context.note_row
                and (pattern_start_ppq <= note.ppq_s and note.ppq_e <= pattern_end_ppq)
          end,
        },
      },
    })

    midi.insert_notes({
      take = t_midi_context.take,
      notes = t_midi_notes,
    })
    -- FIX: design a better overall stategy for managing patterns and recalling
    -- them...
    -- project_state.overwrite(state_table_name, { prev_pattern_string = t_patterns_state.input_string })
  end

  return t_patterns_state, t_midi_notes
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- NOTE: this is currently the function used by `apply_music_transform` to
-- insert complex midi into a project.

midi.parse_and_render_midi_notes_block_from_string = function(insert_midi_str)
  log.user("MIDI BLOCK STRING:", insert_midi_str)
  local return_code = false

  local main_divider = "/"

  local function countCharInString(inputString, charToCount)
    local count = 0
    local prev = 0
    local t_res = {}

    for i = 1, #inputString do
      if string.sub(inputString, i, i) == charToCount then
        count = count + 1
        if i - prev < 2 then
          table.insert(t_res, "")
        else
          table.insert(t_res, inputString:sub(prev + 1, i - 1))
        end
        prev = i
      end
      if i == #inputString then
        if i - prev < 2 then
          table.insert(t_res, "")
        else
          table.insert(t_res, inputString:sub(prev + 1, i))
        end
      end
    end
    return count, t_res
  end

  -- TODO: if no input_pattern, then fill the measure with a full measure note.
  local function parse_pattern(input_pattern)
    local t_pattern_midi_notes
    if input_pattern == "" then
      -- todo ...
    else
      _, t_pattern_midi_notes = midi.create_insert_midi_pattern_by_string(_, {
        pattern = input_pattern,
        dry_run = true, -- only return data, DON'T try insert any midi
        start_at_zero = true, -- HACK: temporary fix to make midi data be generated from timeline=0
      })
    end
    return t_pattern_midi_notes
  end

  -- ~ I need a way to specifically target chords / scale
  -- ~ Add octave number to the initial pitch
  local function parse_note_pool(note_pool_str)
    local root_pitch, note_pool_found
    local default_pitch = 60

    if note_pool_str == nil or note_pool_str == "" then
      return {
        root_pitch = default_pitch,
        note_pool = nil,
      }
    else
      local t_parsed_pool = s.split(note_pool_str, " ")

      -- log.user("t parsed pool:", format.block(t_parsed_pool))

      local parsed_pool

      if #t_parsed_pool == 1 then
        root_pitch = default_pitch
        parsed_pool = t_parsed_pool[1]
      elseif #t_parsed_pool > 1 then
        root_pitch = t_parsed_pool[1]
        parsed_pool = t_parsed_pool[2]
      end

      local all_note_pools = require("constants.all_note_pools")()
      local found_np = false

      for _, np in ipairs(all_note_pools) do
        if np.name_short:lower():match("^" .. parsed_pool) then
          note_pool_found = np
          found_np = true
        end
      end
    end

    if note_pool_found then
      for i, pitch in ipairs(note_pool_found.relative_intervals) do
        note_pool_found.relative_intervals[i] = pitch + default_pitch
      end
    end
    return {
      root_pitch = root_pitch,
      note_pool = note_pool_found,
    }
  end

  -- 0. SPLIT INPUT && ASSIGN `PATTERN/POOL/ARP`

  if insert_midi_str == "" then
    return
  end
  local _, input_units = countCharInString(insert_midi_str, main_divider)
  local input_pattern
  local input_note_pool
  local input_arp_expr
  if #input_units == 1 then
    input_pattern = input_units[1]
  elseif #input_units == 2 then
    input_pattern = input_units[1]
    input_note_pool = input_units[2]
  elseif #input_units > 2 then
    input_pattern = input_units[1]
    input_note_pool = input_units[2]
    input_arp_expr = input_units[3]
  end
  local use_expr = input_arp_expr == "" and false

  log.user("midi_block", #input_units, format.block(input_units))

  -------------------------------------------------------

  local pattern = parse_pattern(input_pattern)
  local note_pool = parse_note_pool(input_note_pool)

  log.user("NOTE POOL:", format.block(note_pool))

  if not pattern then
    log.debug("Pattern returnd in [insert_midi_block] was nil.")
    return
  end

  -------------------------------------------------------
  -- Merge pattern with note pool
  --

  local t_final_rendered_notes = {}

  if note_pool then
    if use_expr then
      -- parse expr
      -- apply expr
    else
      if note_pool.note_pool then
        local pitches = note_pool.note_pool.relative_intervals

        for _, atom in ipairs(pattern) do
          for _, pitch_num in ipairs(pitches) do
            local t_new_note = tbl.copy(atom)
            t_new_note.pitch = pitch_num
            table.insert(t_final_rendered_notes, t_new_note)
            -- log.user("ATOM:", format.block(atom), format.block(pitches))
          end
        end
      end
    end
  end

  return_code = true

  return return_code, t_final_rendered_notes
end

return midi
