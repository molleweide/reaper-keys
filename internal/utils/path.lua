
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

function path.check_file_ext(filePath, desiredExtension)
    -- Get the file extension
    local extension = filePath:match("%.([^%.]+)$")

    -- If extension exists and matches desiredExtension
    if extension and extension == desiredExtension then
        return true
    else
        return false
    end
end

        -- local function get_parent_dir(path)
        --   return path:match("(.+)/[^/]+$")
        -- end

function path.trim_path_from_left(filePath)
    local parts = {}

    -- Split the path by '/'
    for part in filePath:gmatch("[^/]+") do
        table.insert(parts, part)
    end

    -- If fewer than 5 parts, return the original path
    if #parts <= 4 then
        return filePath
    end

    -- Keep only the last 4 parts
    local trimmedPath = table.concat({ parts[#parts - 3], parts[#parts - 2], parts[#parts - 1], parts[#parts] }, "/")

    -- Add leading '/' if original path starts with '/'
    if filePath:sub(1, 1) == "/" then
        trimmedPath = "/" .. trimmedPath
    end

    return trimmedPath
end

return path
