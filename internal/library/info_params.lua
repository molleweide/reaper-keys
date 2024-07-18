local log = require("utils.log")
local format = require("utils.format")

-- NOTE: This file contains lib for managing reaper object info params and
-- similar, eg. media track info params.
--

local M = {}

-- FIX:Some params eg. `t` is a pointer to a jGui picker, so this should not be
-- passed to here, instead i should pass the minimal set of necessary params
-- data.
--
---comment
---@param t table
---@param amount number The value by which floats/doubles should b shifted.
---@param direction boolean|nil move value up or down. nudge/cycle/shift..
---@param supplied_key string|nil
M.handle_keys = function(t, amount, direction, supplied_key)
    -- TODO: check if main prompt OR focus control -> determines how I
    -- should get the entry object.
    -- local sel = t.gui_ref:get_on_enter_selection()

    local gui = t.gui_ref

    log.user(">>>>>>>>>", format.block(gui.meta))

    local sel = gui:get_currently_focused_entry()

    local dir_mult = direction and -1 or 1

    local ip_meta = supplied_key and sel.info_params[supplied_key]._meta or sel._meta
    local info_param_type = supplied_key and sel.info_params[supplied_key].type or sel.type
    local info_param_value_current = supplied_key and sel.info_params[supplied_key].value or sel.value
    local ip_max = supplied_key and sel.info_params[supplied_key].max or sel.max
    local ip_min = supplied_key and sel.info_params[supplied_key].min or sel.min

    local newval

    if info_param_type == "bool" then
        newval = info_param_value_current == 0 and 1 or 0
    end

    if info_param_type == "int" or info_param_type == "char" then
        local int_shift_amount = 1
        if ip_max or ip_min then
            local reverse = direction
            local oldval = info_param_value_current
            if reverse then
                newval = (oldval - int_shift_amount) % ip_max -- Cycle through 2, 1, 0
                if newval < ip_min then
                    newval = ip_max
                end
            else
                newval = (oldval + int_shift_amount) % ip_max -- Cycle through 0, 1, 2
            end
        else
            newval = info_param_value_current + dir_mult * int_shift_amount
        end
    end

    if info_param_type == "double" or info_param_type == "float" then
        local nudge = dir_mult * amount
        if sel.compute then
            newval = sel.compute(info_param_value_current, nudge)
        else
            newval = info_param_value_current + nudge
        end
        if newval > ip_max then
            newval = ip_max
        end
        if newval < ip_min then
            newval = ip_min
        end
    end

    log.user(string.format("[%s]: %s -> %s", info_param_type, info_param_value_current, newval))

    if newval and not sel.read_only and not sel.wip then
        log.user(".meta = ", format.block(t.gui_ref.meta))
        if ip_meta.cat == "track" then
            reaper.SetMediaTrackInfo_Value(gui.meta.track, sel.key, newval)
        end
        if ip_meta.cat == "item" then
            reaper.SetMediaItemInfo_Value(gui.meta.item, sel.key, value)
        end
        if ip_meta.cat == "take" then
            reaper.SetMediaItemTakeInfo_Value(gui.meta.take, sel.key, newval)
        end
        if ip_meta.cat == "route" then
            -- route info params
            if supplied_key then
                reaper.SetTrackSendInfo_Value(gui.meta.track, sel.cat, sel.index, sel.info_params[supplied_key].key, newval)
            else
                reaper.SetTrackSendInfo_Value(gui.meta.track, sel.cat, sel.index, sel.key, newval)
            end
        end

        if supplied_key then
            log.user("sup")
            sel.info_params[supplied_key].value = newval
        else
            sel.value = newval
        end
        UPDATE_RESULTS = true

        -- NOTE: If I set the control values directly, then i would not have to refrsesh the
        -- whole picker but i would have to ensure there are no out of sync issues
        -- then
        -- local c = gui:get_currently_focused_control()
        -- log.user(format.block(c[1]))
        -- log.user("=", c[1].label)
        -- c[1]:_draw()

        -- c:_draw()
    end

    -- for key, value in pairs(sel.info_params) do
    --     log.user(value.value)
    -- end

    --
end

return M
