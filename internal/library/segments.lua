local marks = require("library.marks")
local log = require("utils.log")
local format = require("utils.format")

-- TODO: Move all of this into `lib/timeline.lua`

-- start, end = reaper.GetSet_LoopTimeRange(boolean isSet, boolean isLoop, number start, number end, boolean allowautoseek)

-- functions related to moving segments and sections of a song

local segments = {}

local function insert_empty_space_at_time_selection_by_pushing_existing_forward()
    reaper.Main_OnCommand(40200, 0) -- Time selection: Insert empty space at time selection (moving later items)
end

-- TODO: Document what happens here???
--
--
function segments.insertSpaceAtEditCursorFromTimeSelection()
    log.user("fn insert space")

    local tstart, tend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    reaper.PreventUIRefresh(1)

    local curPos = reaper.GetCursorPosition()
    reaper.GetSet_LoopTimeRange(true, false, curPos, curPos + (tend - tstart), false)

    reaper.Main_OnCommand(40200, 0) -- Time selection: Insert empty space at time selection (moving later items)

    reaper.GetSet_LoopTimeRange(true, false, tstart, tend, false)

    reaper.PreventUIRefresh(-1)
end

function segments.insert_x_num_empty_measures_at_pos(pos_start, pos_end)
    -- save time sel
    -- TODO: move into util
    local save_start_sel, save_end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    reaper.PreventUIRefresh(1)

    local real_length = pos_end - pos_start

    -- set temporary sel
    reaper.GetSet_LoopTimeRange(true, false, pos_start, pos_start + real_length, false)

    insert_empty_space_at_time_selection_by_pushing_existing_forward()

    local shift = save_start_sel < pos_start and 0 or real_length

    -- restore sel
    reaper.GetSet_LoopTimeRange(true, false, save_start_sel + shift, save_end_sel + shift, false)

    reaper.PreventUIRefresh(-1)
end

-- TODO: Document clearly what this command does???
--
-- get this to work now
function segments.repeatShiftAllItemsInTimeSelectionByTrackByTimeSel()
    log.user("---first---")
    -- 1. if item pos is before time sel start  skip
    -- 2. add time_sel_len
    local start_sel, end_sel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)

    log.user("start", start_sel)
    log.user("end", end_sel)

    local data = {}
    if reaper.CountSelectedMediaItems(0) < 1 then
        return
    end

    data = collectMediaItemData(data)

    log.user("!!!!!!!!")

    local measure_shift, end_fullbeatsmax = CalcMeasureShift(data)
    local increment_measure = OverlapCheck(data, measure_shift, end_fullbeatsmax)

    DuplicateItems(data, end_sel - start_sel)
end

function collectMediaItemData(data)
    for i = 1, reaper.CountSelectedMediaItems(0) do
        local item = reaper.GetSelectedMediaItem(0, i - 1)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local GUID = reaper.BR_GetMediaItemGUID(item)

        local pos_beats_t = { reaper.TimeMap2_timeToBeats(0, pos) }
        local end_beats_t = { reaper.TimeMap2_timeToBeats(0, pos + len) }

        log.user("#######")

        data[i] = {
            src_tr = reaper.GetMediaItem_Track(item),
            chunk = ({ reaper.GetItemStateChunk(item, "", false) })[2],
            group_ID = reaper.GetMediaItemInfo_Value(item, "I_GROUPID"),
            col = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR"),
            start_t = pos,
            end_t = pos + len,
            pos_conv = {
                pos_conv_beats = pos_beats_t[1],
                pos_conv_measure = pos_beats_t[2],
                pos_conv_fullbeats = pos_beats_t[4],
            },
            end_conv = {
                end_conv_beats = end_beats_t[1],
                end_conv_measure = end_beats_t[2],
                end_conv_fullbeats = end_beats_t[4],
            },
            GUID = reaper.BR_GetMediaItemGUID(item),
        }
    end
    log.user(format.block(data))
    return data
end

function CalcMeasureShift(data)
    local meas_min = math.huge
    local meas_max = 0
    local end_fullbeatsmax = 0
    for i = 1, #data do
        meas_min = math.min(meas_min, data[i].pos_conv.pos_conv_measure)
        meas_max = math.max(meas_max, data[i].end_conv.end_conv_measure)
        end_fullbeatsmax = math.max(end_fullbeatsmax, data[i].end_conv.end_conv_fullbeats)
    end
    local measure_shift = math.max(1, meas_max - meas_min)
    return measure_shift, end_fullbeatsmax
end

function OverlapCheck(data, measure_shift, end_fullbeatsmax)
    reaper.ClearConsole()
    for i = 1, #data do
        local shifted_pos = reaper.TimeMap2_beatsToTime(
            0,
            data[i].pos_conv.pos_conv_beats,
            data[i].pos_conv.pos_conv_measure + measure_shift
        )
        if shifted_pos < reaper.TimeMap2_beatsToTime(0, end_fullbeatsmax) then
            return 1
        end
    end
    return 0
end

-- NOTE: should this be exposed in the module?
--  (repeatable) action duplicate items at intervals
function DuplicateItems(data, measure_shift)
    for i = 1, #data do
        local new_it = reaper.AddMediaItemToTrack(data[i].src_tr)
        reaper.SetItemStateChunk(new_it, data[i].chunk, false)

        log.user(
            ">>>",
            measure_shift,
            data[i].pos_conv.pos_conv_beats,
            data[i].pos_conv.pos_conv_measure,
            data[i].pos_conv.pos_conv_beats,
            data[i].end_conv.end_conv_measure
        )

        -- this works!!
        local new_pos = data[i].start_t + measure_shift
        local new_end = data[i].end_t + measure_shift

        -- i get wierd errors when i use below beat to time.
        -- log msg don't show and the error comes from after logs. hhmmm..
        --
        -- local new_pos = reaper.TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].pos_conv.pos_conv_measure + measure_shift )
        -- local new_end = reaper.TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].end_conv.end_conv_measure + measure_shift )
        -- local new_pos = reaper.TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_measure + measure_shift )
        -- local new_end = reaper.TimeMap2_beatsToTime( 0, data[i].end_conv.end_conv_measure + measure_shift )
        reaper.SetMediaItemInfo_Value(new_it, "D_POSITION", new_pos)
        reaper.SetMediaItemInfo_Value(new_it, "D_LENGTH", new_end - new_pos)
        --SetMediaItemInfo_Value( new_it, 'I_CUSTOMCOLOR', data[i].col )
    end
end

--
-- NOTE: compute new region insertion points
-- 2. Take the regions selection as arg.
-- 3. move new regions ranges into a table array
-- 4. if multiple selected -> create multiple region ranges.
--
-- TODO: Instead of attaching keys -> return an array of region datas
--
-- TODO: This is going to have to become a larger API for generating multiple
-- regions, and so I just need to bite the bullet and do this the right way.
--
-- TODO: Take a table of region info that I want to create with variable
-- lengths for each region, so that I can create a list of regions in a prompt,
-- and then render everything.
--
-- TODO: If each provided region description has a register then use it,
-- otherwise, if only a single register is supplied, then use it for the
-- first region inserted - I will evaluate what to do later...

-- TODO: create new regios data from list of regions specs

-- WARN: Currently, creates only ONE region, unless multiple regions have
-- been picked via picker, then we attach this single region to every
-- selected region, effectively creating multiple regions.
-- >>> We are not YET creating multiple regions from a spec list

segments.compute_new_regions_data_for_insertion = function(region_opts, selected_regions)
    local rd = {} -- new regions data

    -- log.user("sr", format.block(selected_regions))

    local function get_region_length(num_msrs)
        local _, _, qn_end = reaper.TimeMap_GetMeasureInfo(0, num_msrs)
        local measures_length = reaper.TimeMap2_QNToTime(0, qn_end)
        return measures_length - 2
    end

    -- NOTE: Currently, all new regions are made of same length
    local function add_region(s, n, r)
        if region_opts.register and not selected_regions then
            r = region_opts.register
        end

        table.insert(rd, {
            type = "region",
            register = r,
            name = n,
            left = s,
            right = s + get_region_length(region_opts.num_measures),
        })
    end

    -- I. BEGINNING -------------------------------------------------------
    if region_opts.at_beginning then
        region_opts.new_region_start = 0
        add_region(0, region_opts.name_string)
    else
        local tl = require("library.timeline")

        local t_regions = marks.get_all_manually_without_state(true)
        local no_regions = #t_regions == 0
        local cursor_info = tl.get_cursor_info()

        -- II. No regions?? --------------------------------------------
        if no_regions then
            region_opts.new_region_start = cursor_info.msr.start
            add_region(cursor_info.msr.start, region_opts.name_string)

        -- III. At the end. ------------------------------------------
        elseif region_opts.at_the_end then
            region_opts.new_region_start = t_regions[#t_regions].rgnend
            add_region(t_regions[#t_regions].rgnend, region_opts.name_string)

        -- IV. At specific regions.
        else
            --   Selected region table structure.
            --   {
            --     color = 0,
            --     id = 17,
            --     isrgn = true,
            --     mark_region_idx = 16,
            --     name = "S # ???",
            --     pos = 0.0,
            --     rgnend = 4.0,
            --     selected = true
            --   }

            if selected_regions then
                for i, rg in ipairs(selected_regions) do
                    local first_register = i == 1 and region_opts.register or nil
                    if region_opts.after_current then
                        -- after selected region
                        add_region(rg.rgnend, region_opts.name_string, first_register)
                    else
                        -- before selected region
                        add_region(rg.pos, region_opts.name_string, first_register)
                    end
                end
            else
                local current_region
                for _, reg in ipairs(t_regions) do
                    if reg.pos <= cursor_info.cursor_pos and reg.rgnend >= cursor_info.cursor_pos then
                        current_region = reg
                    end
                end

                if not current_region then
                    region_opts.new_region_start = cursor_info.msr.start
                    add_region(cursor_info.msr.start, region_opts.name_string)
                elseif region_opts.after_current then
                    region_opts.new_region_start = current_region.rgnend
                    add_region(current_region.rgnend, region_opts.name_string)
                else
                    region_opts.new_region_start = current_region.pos
                    add_region(current_region.pos, region_opts.name_string)
                end
            end
        end
    end

    -- region_opts.new_region_end = region_opts.new_region_start + get_region_length(region_opts.num_measures)

    log.user("insert_region_opts", format.block(region_opts))

    return rd
end

segments.create_sequence_of_regions_from_list_spec = function(spec, at_cursor) end

--- Creates a <ReaperRegion> based on table with region opts.
segments.inject_new_empty_region = function(region_data)
    -- {
    --     type = "region",
    --     register = region_opts.register,
    --     name = region_opts.name_string,
    --     left = region_opts.new_region_start,
    --     right = region_opts.new_region_end,
    -- }
    segments.insert_x_num_empty_measures_at_pos(region_data.left, region_data.right)
    return marks.create(region_data)
end

segments.modify_length_of_region_by_N_measures = function()
end

-- segments.

return segments
