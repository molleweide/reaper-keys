return function(item)
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

    local name_prefix_is_group = item.class == "G" and "(G)" or "   "
    name_prefix_is_group = item.class == "C" and "(C)" or name_prefix_is_group

    return {
        item.zone.name,
        item.group and item.group.name or "",
        show,
        string.format("%s %s %s", name_prefix_is_group, item.name, post_name),
    }
end
