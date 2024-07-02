return function(item)
    local val_str
    if item.val then
        val_str = tostring(item.val)

        if #val_str > 5 then
            val_str = string.sub(val_str, 1, 5)
        end
        if #val_str < 5 then
            local diff = 5 - #val_str
            val_str = val_str .. string.rep("0", diff)
        end

    end

    return {
        { string.format("[%s]", item.index), 10 },
        { string.format("parm:[%s]", item.name), 30 },
        { string.format("val:[ %s ]", val_str), 15 },
        { string.format("valf:[ %s ]", item.valf), 17 },
        { string.format("env:[%s]", item.envelope and "x" or " "), 20 },
    }
end
