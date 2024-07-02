return function(item)
    return {
        { string.format("#%s", item.pt_idx), 8 },
        { string.format("pos:[%s]", item.real_pos), 12 },
        { string.format("[%s]", item.name), 18 },
        { string.format("pt_idices:[%s, %s]", item.pt_idx, item.pt_idx2), 20 },
        { string.format("pt_pos:[%s, %s]", tostring(item.tpos), tostring(item.tpos2)), 18 },
    }
end
