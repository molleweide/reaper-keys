-- local log = require("utils.log")
-- local format = require("utils.format")
-- local fu = require("utils.fzf")
-- local sf = require("utils.j_string_functions")
local su = require("utils.string")

return function(label_str, item)
    local function add(s)
        label_str = label_str .. s
    end

    local function gutter(first)
        if first == 1 then
            add("| ")
        elseif first == 2 then
            add(" |")
        else
            add(" | ")
        end
    end

    gutter(1)

    if item.zone then
        local part = "Z:" .. item.zone.name
        label_str = label_str .. su.makeStringLength(part, 9)
    end

    gutter()

    if item.group then
        local part = "G:" .. item.group.name
        label_str = label_str .. su.makeStringLength(part, 10)
    else
        -- local part = "G:" .. item.group.name
        label_str = label_str .. su.makeStringLength("", 10)
    end

    gutter()
    -- MIDI EDITOR STATE
    local show
    local post_name

    if item._midi_editor_active then
        show = "<ACTIVE>"
        post_name = "<------"
    elseif item._midi_editor_editable then
        show = "$edit"
        post_name = "$"
    elseif item._midi_editor_visible then
        show = "<o>"
        post_name = "<o>"
    else
        show = ""
        post_name = "  "
    end

    -- SHOW STATE
    label_str = label_str .. su.makeStringLength(show, 8)
    gutter()

    -- NAME
    local name_prefix_is_group = item.class == "G" and "(G)" or "   "
    name_prefix_is_group = item.class == "C" and "(C)" or name_prefix_is_group
    label_str = label_str
        .. su.makeStringLength(string.format("NAME: %s %s %s", name_prefix_is_group, item.name, post_name), 32)

    gutter(2)

    return label_str
end
