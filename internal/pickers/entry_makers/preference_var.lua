return function(item)
    local rv = item.real_value
    local val_fmt
    if item.is_mult then
        val_fmt = "<" .. tostring(rv) .. ">"
    else
        if rv == 0 then
            val_fmt = "On"
        elseif rv == 1 then
            val_fmt = "Off"
        end
    end
    local opts_str = ""
    if item.is_mult and item.var_def.options ~= nil then
        for idx, v in ipairs(item.var_def.options) do
            if rv + 1 == idx then
                opts_str = string.format("%s", v)
            end
        end
    end
    return {
        string.format("%s -> %s", item.cat, item.subcat),
        item.key,
        item.var_name,
        val_fmt,
        opts_str,
    }
end
