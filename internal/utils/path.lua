
local path = {}


-- move to util; there are prolly better utils in some luarock?
function path.get_basename_without_extension(filepath)
    local pattern = "[\\/]?([^\\/]+)%.(%w+)$" -- Pattern to match the last part of the path and the extension
    local basename, extension = string.match(filepath, pattern)
    return basename
end

function path.get_parent_dir(filePath)
    return filePath:match("(.*/)")
        --   return path:match("(.+)/[^/]+$")
end

function path.trim_trailing_slash(path)
    return path:gsub("[/\\]+$", "")
end


        -- local function get_parent_dir(path)
        --   return path:match("(.+)/[^/]+$")
        -- end


return path
