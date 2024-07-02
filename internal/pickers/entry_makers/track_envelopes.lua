return function(item)

    return {
        { string.format("type:[%s]", item.type_name), 16 },
        { string.format("name:[%s]", item.name), 38 },
        { string.format("active:[%s]", item.active and "x" or " "), 6 },
    }
end
