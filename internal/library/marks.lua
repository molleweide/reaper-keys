local project_state = require("utils.project_state")
local state_interface = require("state_machine.state_interface")
local reaper_utils = require("custom_actions.utils")
local log = require("utils.log")
local format = require("utils.format")

-- NOTE: Maybe I should move the CRUD api under lib/api/...

-- BUG: For some reason all markers are returned as capitalized keys which
-- prevents one from using both small and big letters with markers.
-- I dunno why this is..

-- FIX: I need to overhaul this file and ensure that marks can be used reliably
-- through this API.

-- TODO: Maybe add double char sequences so that I can ensure that it is
-- very unlikely that one runs out of accessor keys.

local serpent = require("serpent")

local marks = {}

local function get_unused_register()
    local valid_registers = "ABCDEFGHIJKLMNOPQRSTUVXYZ"
    local _, all_project_marks = project_state.getAll("marks")
    -- log.user(format.block(all_project_marks))
    for char in valid_registers:gmatch(".") do
        if all_project_marks[char] == nil then
            log.user("found char ->", char)
            return char
        end
    end
    return false
end

local function deleteMarkIndications(mark)
    if mark.index then
        if mark.type == "region" then
            reaper.DeleteProjectMarker(0, mark.index, true)
        elseif mark.type == "timeline_position" then
            reaper.DeleteProjectMarker(0, mark.index, false)
        end
    end
end

local function create_project_region(left, right, name_string)
    reaper.AddProjectMarker(0, true, left, right, name_string, -1)
end

local function update_project_region(rg)
  local rg_flags = false
    reaper.SetProjectMarker3(0, rg.mark_region_idx, rg.isrgn, rg.pos, rg.rgnend, rg.name, rg.color)--, rg_flags)
end

local function create_project_mark(pos, name_string)
    return reaper.AddProjectMarker(0, false, pos, pos, name_string, -1)
end

local function make_marker_name(register, name_string)
    return string.format("%s # %s", register, name_string)
end

local function overwriteMark(mark, register)
    local mode = state_interface.getMode()

    -- build and apply mark
    if mark.type == "region" or mode == "visual_timeline" then
        local region_name = string.format("%s # %s", register, mark.name)
        mark["type"] = "region"
        mark["index"] = create_project_region(mark.left, mark.right, make_marker_name(register, mark.name))
    elseif mark.type == "track_selection" or mode == "visual_track" then
        mark["type"] = "track_selection"
    else
        mark["type"] = "timeline_position"
        mark["index"] = create_project_mark(mark.position, make_marker_name(register, mark.name))
    end
    mark["register"] = register
    mark["time"] = os.time()

    -- delete old
    local ok, old_mark = project_state.get("marks", register)
    if ok and old_mark then
        deleteMarkIndications(old_mark)
    end

    -- add new
    project_state.overwrite("marks", register, mark)
    state_interface.setMode("normal")

    -- debug
    local _, all_project_marks = project_state.getAll("marks")
    log.trace("New Marks State: " .. format.block(all_project_marks))

    return mark
end

---Save a marker to data of type [mark | region | track selection]
---This function is used to save a mark to a register by key-binds.
---@param register string
function marks.save(register)
    local time_left, time_right = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    local _, marks_named_input = reaper.GetUserInputs(
        "Name for new region:",
        1, -- num inputs
        "region " .. register, -- placeholder
        ""
    )

    local mark = {
        name = marks_named_input,
        left = time_left,
        right = time_right,
        position = reaper.GetCursorPosition(),
        track_position = reaper_utils.getTrackPosition(),
        track_selection = reaper_utils.getSelectedTrackIndices(),
    }

    overwriteMark(mark, register)
end

-- FIX: Validation: I need to validate that the necessary information has
-- been supplied depending on which type user wants.
--
---CREATE marker | Use this function to programmatically create markers
---@param marker_opts any
function marks.create(opts)
    if not opts.register then
        local r = get_unused_register()
        if not r then
            log.debug("WARNING: Ran out of registers!!")
        else
            opts.register = r
        end
    end

    if not opts.name then
        opts.name = "[no name]"
    end

    -- log.user("?????")

    return overwriteMark(opts, opts.register)
end

---Update/modify marker
function marks.update(opts)
    -- reaper.SetProjectMarker4( proj, markrgnindexnumber, isrgn, pos, rgnend, name, color, flags )
    --
    -- TODO: update region | mark
end

-- a filter can be:
--     region at current cursor
--
-- These are the props of a region.
--     - isrgn = isrgn,
--     - pos = pos,
--     - rgnend = rgnend,
--     - name = name,
--     - mark_region_idx = markrgnindexnumber,
--     - color = color,
--
-- NOTE: This transform can be used for pretty much any operations on regions
-- which means this is going to be flexible.
--
---Flexible API for doing most types of transform upon sets of project regions.
---The aim is to make an API func making project region management a little bit easier.
---Opts can take:
---     - target region, if you already know/have what to act upon.
---     - apply transforms to a subset of all regions.
--- @param opts table
function marks.filter_transform_project_regions(opts)
    opts = opts or {}
    local t_res = {}
    local op_on_regions = true

    local filter = opts.filter or {}
    local remove = opts.remove or {}

    -- compute target set
    local function filter_get_all_regions()
        log.user("?")
        local t_results = {}
        local ret, num_markers, num_regions = reaper.CountProjectMarkers(0)
        local num_total = num_markers + num_regions
        if num_regions > 0 then
            local i = 0
            while i < num_total do
                local _, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)

                if isrgn then
                    local add_current = false
                    if opts.filter then
                    else
                        add_current = true
                    end
                    if add_current then
                        table.insert(t_results, {
                            isrgn = isrgn,
                            pos = pos,
                            rgnend = rgnend,
                            name = name,
                            mark_region_idx = markrgnindexnumber,
                            color = color,
                        })
                    end
                end
                i = i + 1
            end
        else
            log.debug("Project has no regions!")
        end
        return t_results
    end
    local regions_target_set = opts.target_region and opts.target_region or filter_get_all_regions()

    -- if opts.remove then
    --     remove
    --       return
    --
    --       >>>> use: deleteMarkIndications(mark)

    -- if opts.transform
    --      check params
    --          apply changes to region targets
    --
    log.user(":::::::::::::::: pre transform :::::::::::::::::")
    log.user("[ filter_transform_project_regions ]", format.block(opts), format.block(regions_target_set))

    local targets_updated = 0
    if opts.transform then
        local transform = opts.transform

        -- NOTE:
        -- - a single number means shift.

        for i, rg in ipairs(regions_target_set) do
            local update = false
            for k, v in pairs(transform) do
                if type(v) == "boolean" then
                    log.trace("fltr regions [transform] section: set bool:", i, rg[k], "->", v)
                    rg[k] = v -- set bool value
                    update = true
                elseif type(v) == "number" then
                    log.trace("fltr regions [transform] section: shift num:", i, rg[k], "->", rg[k] + v)
                    rg[k] = rg[k] + v -- shift by number
                    update = true
                elseif type(v) == "table" then
                    log.trace("fltr regions [transform] section: force const:", i, rg[k], "->", v[1])
                    rg[k] = v[2] == "force" and v[1] -- { number, "force"} means force all notes to value
                    update = true
                elseif type(v) == "function" then
                    log.trace("fltr regions [transform] section: func:", i, rg[k], "->", v(rg))
                    rg[k] = v(rg) -- apply function transform per note
                    update = true
                end
                if update then
                    targets_updated = targets_updated + 1
                end
            end
        end
    end

    log.user(":::::::::::::::: post transform :::::::::::::::::")
    log.user("[ filter_transform_project_regions ]", format.block(opts), format.block(regions_target_set))

    -- if insert or transforms requested
    --        apply transform of the real regions space.
    --        >>>> use: reaper.SetProjectMarker4( proj, markrgnindexnumber, isrgn, pos, rgnend, name, color, flags )
    --        >>>> use: create_project_region(left, right, name_string)

    if (targets_updated > 0 or opts.insert) and not opts.dry_run then
        -- if not opts.insert then
        --     midi.delete_notes(take, t_notes)
        -- end
        log.user("just before inserting notes")
        -- midi.insert_notes({
        --     take = take,
        --     notes = t_notes,
        -- })
        if targets_updated then
            for _, rg in ipairs(regions_target_set) do
                -- all the data has been prepared/transformed so I only need to send it
                -- to be writtene here/now.
                update_project_region(rg)
            end
        end
    end

    -- return all_regions, filtered_regions
end

function marks.filter_transform_project_marks(opts) end

function marks.delete(register)
    local ok, old_mark = project_state.get("marks", register)
    if ok and old_mark then
        deleteMarkIndications(old_mark)
    end
    project_state.delete("marks", register)
end

marks.deleteAll = function()
    local ok, all_marks = project_state.getAll("marks")
    -- log.user("delete all ->", ok, format.block(all_marks))
    if ok and all_marks then
        for register, the_mark in pairs(all_marks) do
            log.user(register, format.block(the_mark))
            marks.delete(register)
            -- project_state.delete("marks", register)
        end
    end
    -- force remove all regions/markers manually
    marks.delete_all_markers_manually()

    -- reset the ext state marks table
    project_state.deleteExt("marks")
end

function marks.recallMarkedTimelinePosition(register)
    local ok, mark = project_state.get("marks", register)
    if not ok or not mark then
        return
    end

    local target_pos = mark.position
    if mark.type == "region" then
        target_pos = mark.left
    end

    reaper.SetEditCurPos(target_pos, true, false)
end

function marks.recallMarkedRegion(register)
    local ok, mark = project_state.get("marks", register)
    if not ok or not mark then
        return
    end

    reaper.GetSet_LoopTimeRange(true, false, mark.left, mark.right, false)
    reaper_utils.scrollToPosition(mark.left)
end

function marks.recallMarkedTracks(register)
    local ok, mark = project_state.get("marks", register)
    if not ok or not mark then
        return
    end

    reaper_utils.setCurrentTrack(mark.track_position)
    reaper_utils.setTrackSelection(mark.track_selection)
end

--
-- TODO: "regions" |"marks" |"both"
--
-- FIX: redo this with the existing api
--

---Enumerates markers chronologically.
---@param user_wants any
---@return table
marks.get_all_manually_without_state = function(user_wants)
    local t_results = {}
    local ret, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local num_total = num_markers + num_regions
    if num_regions > 0 then
        local i = 0
        while i < num_total do
            local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
            local t_prepare = {
                isrgn = isrgn,
                pos = pos,
                rgnend = rgnend,
                name = name,
                mark_region_idx = markrgnindexnumber,
                color = color,
            }
            if user_wants == isrgn then
                -- log.user("#region = ", markrgnindexnumber)
                table.insert(t_results, t_prepare)
            end
            i = i + 1
        end
    else
        log.debug("Project has no regions!")
    end
    return t_results
end

marks.delete_all_markers_manually = function()
    local ret, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local num_total = num_markers + num_regions

    local i = 0
    while i < num_total do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
        reaper.DeleteProjectMarkerByIndex(proj, i)
        -- reaper.DeleteProjectMarker(0, mark.index, true)
        i = i + 1
    end
end

---Returns index of region for a specific timeline position or the current position.
---The returned region-index is zero-based.
---@param pos number | nil
---@return number | nil
function marks.get_region_for_pos_or_current(pos)
    pos = pos or reaper.GetCursorPosition()
    local ret, region_id = reaper.GetLastMarkerAndCurRegion(0, pos)
    return region_id
end

-- ---Get the region table object for id. If not id then get for current position.
-- ---@param id number
-- ---@return
-- function marks.get_region_object(id)
--   -- marks.get_region_for_pos_or_current(pos)
-- end

---Get the Nth region after timeline position. N == 0 means get current region
---(ie. the region the edit cursor resides within), N == 1 means get the next
---region, etc..
---@param pos any
---@param n any
marks.get_nth_region_for_pos = function(pos, n)
    n = n or 0
    pos = pos or reaper.GetCursorPosition()

    -- returns zero indexed region number
    local regidx = marks.get_region_for_pos_or_current(pos)

    -- log.user("regidx =", regidx)

    if not regidx then
        return false
    end

    local all_regions = marks.get_all_manually_without_state(true)

    -- log.user(format.block(all_regions))

    if #all_regions == 0 then
        return false
    end

    -- We need to add `one` to regidx because each regions "mark_region_idx" is
    -- one based.
    regidx = regidx + 1

    local found_count = 0
    local found_n = false

    for _, reg in ipairs(all_regions) do
        -- for each region that we look at, check if cursor pos is after or equal
        -- and increment count
        if reg.pos <= pos then
            found_count = found_count + 1

            -- if count == n + 1 then we stop counting
            if found_count == (n + 1) then
                found_n = true
            end
        end

        -- check that we are inside the Nth count region by comparing both start,
        -- and end point to position/cursor.
        if found_n and reg.pos <= pos and pos < reg.rgnend then
            return reg
        end

        -- if reg.mark_region_idx == (regidx + n) then
        --     return reg
        -- end
    end
    return false
end

return marks
