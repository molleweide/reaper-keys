local s = require("utils.string")

return function(prompt_string)
    -- TODO: move these to user configs
    --
    -- START ---------------------------------------------------------------
    -- move this to library.parsers.get_new_region_options.

    local opts = {
        name_string = nil,
        after_current = true, -- Insert region after current or before.
        at_beginning = false,
        at_the_end = false,
        register = nil,
        num_measures = 2,
        new_region_start = nil,
    }

    -- TODO: reuse flag parsers from music apply transform

    -- PARSE STRING
    -- [<jump_char>][-^$][<measures_count>]/[<name>]

    local s_split = s.split(prompt_string, ";")

    if #s_split == 1 then
        opts.name_string = s_split[1]
    elseif #s_split > 1 then
        opts.name_string = s_split[2]
        local a = s_split[1]
        -- local b = s_split[2]
        if a:match("%+") then
            opts.after_current = true
        end
        if a:match("%-") then
            opts.after_current = false
        end
        opts.at_beginning = a:find("%^") and true or false
        opts.at_the_end = a:find("%$") and true or false
        opts.register = a:match("%a") -- match a single char
        local num_found = a:match("(%d+)") -- match the largest sequence of consecutive digits
        if num_found then
            opts.num_measures = num_found and tonumber(num_found)
        end
    end

    return opts
end
