local reaper_state = require('utils.reaper_state')
local format = require('utils.format')
local log = require('utils.log')
local syntax = require('SYNTAX.syntax.syntax')
-- local midi = require('SYNTAX.lib.midi')
local utils = require('custom_actions.utils')
local syntax_utils = require('SYNTAX.lib.util')
-- local config = require('SYNTAX.config.config')

local ypc = {}

function ypc.customGroupYpc(ypc_type)
  local vtt = syntax.getVerifiedTree()
  local tr_idx_first, tr_idx_last = syntax_utils.getTrackIndicesOfTrackSel()
  local LVL2_parent_obj, tr_parent_group, group_tr_idx = syntax_utils.getParentGroupByTrIdx(vtt, tr_idx_first)
  local T_YPC = { ypc_type = ypc_type }
  -- log.user('\n\n >>> YPC: ' .. ypc_type .. ' --------------------\n\n')
  if not syntax_utils.trackObjHasOption(LVL2_parent_obj, 'm') then
    log.user('YpcError; requires opt \'m\'') return
  end
  T_YPC["t_ypc_segments"] = ypcMidiSegments(LVL2_parent_obj, tr_idx_first, tr_idx_last, MIDI_LOW_btm)
  ypcReaperMainCommands(ypc_type) -- where can I run this best??
  --log.user('T_YPC: ' .. format.block(T_YPC))
  T_YPC["parent_items"] = ypcHandleParentItems(tr_parent_group, T_YPC)
  ypcInsertMidiFromExtState(tr_parent_group, LVL2_parent_obj, T_YPC)

  if ypc_type == "yank" or ypc_type == "cut" then
    -- log.user('>> write ypc table..')
    reaper_state.set("RS_YPC_TABLE_PREV", T_YPC)
  end
end

function ypcMidiSegments(LVL2_parent_obj, tr_idx_first, tr_idx_last, MIDI_LOW_btm)
    local MC_SEL_COUNT = 0
    local MIDI_HIGH = 0
    local MIDI_HIGH_top
    local MIDI_HIGH_btm
    local MIDI_SEL = 0
    local MIDI_SEL_top
    local MIDI_SEL_btm
    local MIDI_LOW = 0
    local MIDI_LOW_top
    local MIDI_LOW_btm = 24 -- config.pianoroll bottom...
    local MIDI_RANGE_TOT = 0 -- mv to ypcMidiSegments

    -- log.user('LVL2_parent_obj', format.block(LVL2_parent_obj))

    for k, LVL3_obj in pairs(LVL2_parent_obj.children) do ----------- lvl 3 ------------
      if syntax_utils.strHasOneOfChars(LVL3_obj.class, 'MC') then
        local LVL3_obj = LVL2_parent_obj.children[k]
        local LVL3_tr, LVL3_tr_idx = utils.getTrackByGUID(LVL3_obj.guid)
        -- log.user(LVL3_tr, LVL3_tr_idx)
        local range = 1
        if syntax_utils.trackObjHasOption(LVL3_obj, 'nr') then range = LVL3_obj.options.nr end

        -- log.user(LVL3_tr_idx, tr_idx_first, tr_idx_last)

        if LVL3_tr_idx < tr_idx_first then -- above sel
          MIDI_HIGH = MIDI_HIGH + range

        elseif tr_idx_last < LVL3_tr_idx then -- below sel
          MIDI_LOW = MIDI_LOW + range

        else                                  -- in sel
          MC_SEL_COUNT = MC_SEL_COUNT + 1
          MIDI_SEL = MIDI_SEL + range
        end
        MIDI_RANGE_TOT = MIDI_RANGE_TOT + range
      end
    end

    MIDI_LOW_top  = MIDI_LOW_btm  + MIDI_LOW   - 1
    MIDI_SEL_btm  = MIDI_LOW_btm  + MIDI_LOW
    MIDI_SEL_top  = MIDI_SEL_btm  + MIDI_SEL - 1
    MIDI_HIGH_btm = MIDI_SEL_btm  + MIDI_SEL
    MIDI_HIGH_top = MIDI_HIGH_btm + MIDI_HIGH - 1

    local tmp = {
      MIDI_HIGH = MIDI_HIGH,
      MIDI_HIGH_top = MIDI_HIGH_top,
      MIDI_HIGH_btm = MIDI_HIGH_btm,
      MC_SEL_COUNT = MC_SEL_COUNT,
      MIDI_SEL = MIDI_SEL,
      MIDI_SEL_top = MIDI_SEL_top,
      MIDI_SEL_btm = MIDI_SEL_btm,
      MIDI_LOW = MIDI_LOW,
      MIDI_LOW_top = MIDI_LOW_top,
      MIDI_LOW_btm = MIDI_LOW_btm,
      MIDI_RANGE_TOT = MIDI_RANGE_TOT,
    }
    -- log.user(format.block(tmp))
    return tmp
  end

  function ypcReaperMainCommands(ypc_type)
    if ypc_type == "yank" then
      reaper.Main_OnCommandEx(40210, 1, 0) -- copy tracks
    elseif ypc_type == "put" then
      numeric_id = reaper.NamedCommandLookup("_SWS_AWPASTE")
      if numeric_id == 0 then
        log.error("Could not find action in reaper or action list for: " .. id)
        return false
      end
      reaper.Main_OnCommand(numeric_id, 0) -- paste tracks
    elseif ypc_type == "cut" then
      reaper.Main_OnCommandEx(40210, 1, 0) -- copy tracks
      reaper.Main_OnCommandEx(40005, 1, 0) -- remove tracks
      reaper.Main_OnCommandEx(40505, 1, 0) -- select last touched track
    end
    return true
  end

  function ypcGetNotesInSelFromTake(LVL2_parent_take, T_YPC, i1)
    local midi_notes = {}
    local ret,notecnt,ccevtcnt,textsyxevtcnt = reaper.MIDI_CountEvts(LVL2_parent_take);
    for i2 = 0, notecnt do
      local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(LVL2_parent_take, i2)
      if T_YPC.t_ypc_segments.MIDI_SEL_btm <= pitch and pitch <= T_YPC.t_ypc_segments.MIDI_SEL_top then
        -- the order used by insert shouldn't really matter
        table.insert(midi_notes, {
            startppqpos = startppqpos,
            endppqpos = endppqpos,
            chan = chan,
            real_pitch = pitch,
            pitch = pitch - T_YPC.t_ypc_segments.MIDI_SEL_btm,
            vel = vel,
          })
      end
    end
    return midi_notes
  end

  function ypcPutShiftInsert2(take, midi_notes, shift)
    -- log.user('insert item midi..')
    for i, note in ipairs(midi_notes) do
      reaper.MIDI_InsertNote(
        take,
        false,
        false,
        note.startppqpos,
        note.endppqpos,
        note.chan,
        note.pitch + shift, -- notice that I add the new T_YPC sel bottom value
        note.vel,
        true);
    end
  end

  function ypcPutShiftNotes(LVL2_parent_take, T_YPC)
    local T_YPC_PREV    = reaper_state.get("RS_YPC_TABLE_PREV")
    local midi_notes_tmp = {}
    local ret,notecnt,ccevtcnt,textsyxevtcnt = reaper.MIDI_CountEvts(LVL2_parent_take)
    -- DELETE
    for i2 = 0, notecnt - 1 do
      local ret, sel, mute, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(LVL2_parent_take, i2)
      if T_YPC.t_ypc_segments.MIDI_SEL_btm <= pitch then -- SELECTION AND ABOVE

        local new_pitch = pitch + T_YPC_PREV.t_ypc_segments.MIDI_SEL
        reaper.MIDI_SetNote(LVL2_parent_take, i2, nil, nil, nil, nil, nil, new_pitch)

        -- table.insert(midi_notes_tmp,{
            --     mute     = mute,
            --     startppq = startppq,
            --     endppq   = endppq,
            --     chan     = chan,
            --     pitch    = pitch,
            --     vel      = vel
          --   })
        -- reaper.MIDI_DeleteNote(LVL2_parent_take,i2);
      end
    end
    -- INSERT
    -- for i3, note in ipairs(midi_notes_tmp) do
      --   reaper.MIDI_InsertNote(LVL2_parent_take,
        --     false,
        --     note.mute ,
        --     note.startppq,
        --     note.endppq,
        --     note.chan,
        --     note.pitch + T_YPC_PREV.t_ypc_segments.MIDI_SEL, -- ADD
        --     note.vel,
        --     true)
    -- end
    --
    --
  end

  function ypcCutShiftAndRemoveNotes(LVL2_parent_take, T_YPC)
    local midi_notes_tmp = {}
    local ret,notecnt,ccevtcnt,textsyxevtcnt = reaper.MIDI_CountEvts(LVL2_parent_take)

    -- DELETE SELECTION
    for i = 0, notecnt do
      local ret, sel, mute, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(LVL2_parent_take, i)

      if T_YPC.t_ypc_segments.MIDI_SEL_btm <= pitch and
        pitch <= T_YPC.t_ypc_segments.MIDI_SEL_top then ------------------------------- IN RANGE SEL
        reaper.MIDI_DeleteNote(LVL2_parent_take, i)
      end

    end

    local ret,notecnt,ccevtcnt,textsyxevtcnt = reaper.MIDI_CountEvts(LVL2_parent_take)
    -- SHIFT
    for j = 0, notecnt do
      local ret, sel, mute, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(LVL2_parent_take, j)
      if T_YPC.t_ypc_segments.MIDI_SEL_top < pitch then ------------- ABOVE
        local new_pitch = pitch - T_YPC.t_ypc_segments.MIDI_SEL
        reaper.MIDI_SetNote(LVL2_parent_take, j, nil, nil, nil, nil, nil, new_pitch)
      end
    end -- i2
  end

  function ypcHandleParentItems(tr_parent_group, T_YPC)
    -- local T_YPC         = T_YPC
    local item_count    = reaper.CountTrackMediaItems(tr_parent_group)
    local parent_items  = {}

    for i1=0, item_count - 1 do -- does parent_item_cnt need to be stored????

      local LVL2_parent_item  = reaper.GetTrackMediaItem(tr_parent_group, i1)
      local LVL2_parent_take  = reaper.GetMediaItemTake(LVL2_parent_item,0); -- active take?
      local take_is_midi      = reaper.TakeIsMIDI(LVL2_parent_take);

      if take_is_midi then;
        local group_item_pos      = reaper.GetMediaItemInfo_Value(LVL2_parent_item, "D_POSITION")
        local group_item_length   = reaper.GetMediaItemInfo_Value(LVL2_parent_item, "D_LENGTH")
        local new_item_tmp = {
          item_pos = group_item_pos,
          item_length = group_item_length,
        }

        -- copy midi from selection
        if T_YPC.ypc_type == "yank" or T_YPC.ypc_type == "cut" then
          new_item_tmp["midi_notes"] = ypcGetNotesInSelFromTake(LVL2_parent_take, T_YPC, i1)
          if #new_item_tmp.midi_notes ~= 0 then table.insert(parent_items, new_item_tmp) end
        end
        -- shift and delete
        if T_YPC.ypc_type == "put" then
          ypcPutShiftNotes(LVL2_parent_take, T_YPC)
        end
        if T_YPC.ypc_type == "cut" then
          ypcCutShiftAndRemoveNotes(LVL2_parent_take, T_YPC)
        end
      end -- is midi
    end -- each item


    return parent_items
  end

  function getDestItemRelativeInfo(sS,sE,dS,dE)
    local status = ''
    local ss_str = tostring(sS)
    local se_str = tostring(sE)
    local ds_str = tostring(dS)
    local de_str = tostring(dE)

    if sE < dS then -- or se_str == de_str
      status = 'AFTER' -- next
    else
      if sE <= dE or se_str == de_str then
        if sS < dS then
          status =  'RIGHT' -- >>>>>>>>> extend destination item to source start and insert
          -- ypcPutShiftInsert2(d_item_take, sourceItem.midi_notes, T_YPC.t_ypc_segments.MIDI_SEL_btm)
        else
          status = 'UNDER' -- >>>>>>>>> insert midi / inga konstigheter
          -- ypcPutShiftInsert2(d_item_take, sourceItem.midi_notes, T_YPC.t_ypc_segments.MIDI_SEL_btm)
        end
      else
        if dE < sS or de_str == ss_str then
          status =  'BEFORE' -- next
        else
          if dS < sS and dE < sE or ds_str == ss_str then
          status =  'LEFT' -- >>>>>>>> extend dest to source end and insert
          -- ypcPutShiftInsert2(d_item_take, sourceItem.midi_notes, T_YPC.t_ypc_segments.MIDI_SEL_btm)
        else
          status =  'OVER' -- >>>>>>>> dest inside src | extend both sides and insert
          -- ypcPutShiftInsert2(d_item_take, sourceItem.midi_notes, T_YPC.t_ypc_segments.MIDI_SEL_btm)
        end
      end
    end
  end

  return status
end

function ypcInsertMidiFromExtState(tr_parent_group, LVL2_parent_obj, T_YPC)
  local T_YPC_PREV = reaper_state.get("RS_YPC_TABLE_PREV")
  if T_YPC.ypc_type == "put" then -- INSERT MIDI -----------------------------------

    -- s = source; d = destination
    -- log.user('SOURCE: ' .. format.block(T_YPC_PREV))

    local source_item_cnt = 0
    local prev_insert_pos = 0
    local prev_insert_cnt = 0
    local left_overlap
    local right_ovrelap

    local target_tr_media_cnt      = reaper.CountTrackMediaItems(tr_parent_group)

    for s1, sourceItem in ipairs(T_YPC_PREV.parent_items) do
      local sS = sourceItem.item_pos
      local sE = sS + sourceItem.item_length

      for d1 = target_tr_media_cnt-1, 0, -1 do
        -- log.user(d1)
        local d_item  = reaper.GetTrackMediaItem(tr_parent_group, d1)
        local d_item_take  = reaper.GetMediaItemTake(d_item,0); -- active take?
        local take_is_midi  = reaper.TakeIsMIDI(d_item_take);
        local d_item_pos    = reaper.GetMediaItemInfo_Value(d_item, "D_POSITION")
        local d_item_len    = reaper.GetMediaItemInfo_Value(d_item, "D_LENGTH")
        local dS = d_item_pos
        local dE = dS + d_item_len
        local dest_rel_status = getDestItemRelativeInfo(sS,sE,dS,dE)

        if take_is_midi then
          -- log.user('status: ' .. dest_rel_status)

          if dest_rel_status == 'RIGHT' or
            dest_rel_status == 'LEFT' or
            dest_rel_status == 'OVER' or
            dest_rel_status == 'UNDER' then
            ypcPutShiftInsert2(d_item_take, sourceItem.midi_notes, T_YPC.t_ypc_segments.MIDI_SEL_btm)
          end

          break -- break out of d1 - dest items
        end
      end

    end

  end

end

return ypc
