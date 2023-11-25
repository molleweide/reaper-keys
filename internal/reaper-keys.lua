-- NOTE: This line uses the debug.getinfo function to retrieve information about the
-- currently executing Lua script. The first argument 1 specifies the level of
-- the stack frame to retrieve information for (in this case, the current stack
-- frame). The second argument 'S' indicates that you want to include the
-- source field in the retrieved information. The source field represents the
-- source file from which the script is being executed.

local info = debug.getinfo(1,'S');

local internal_root_path = info.source:match(".*reaper.keys[^\\/]*[\\/]internal[\\/]"):sub(2)

-- NOTE: Append necessary paths to the package.path string, which is used by Lua to
-- locate and load modules - it allows Lua to search for modules in the
-- specified paths

package.path = package.path .. ";" .. internal_root_path .. '?.lua'

local windows_files = internal_root_path:match("\\$")
if windows_files then
  package.path = package.path .. ";" .. internal_root_path .. "..\\definitions\\?.lua"
  package.path = package.path .. ";" .. internal_root_path .. "?\\?.lua"
  package.path = package.path .. ";" .. internal_root_path .. "vendor\\share\\lua\\5.3\\?.lua"
  package.path = package.path .. ";" .. internal_root_path .. "vendor\\share\\lua\\5.3\\?\\init.lua"
  package.path = package.path .. ";" .. internal_root_path .. "vendor\\scythe\\?.lua"
else
  package.path = package.path .. ";" .. internal_root_path .. "../definitions/?.lua"
  package.path = package.path .. ";" .. internal_root_path .. "?/?.lua"
  package.path = package.path .. ";" .. internal_root_path .. "vendor/share/lua/5.3/?.lua"
  package.path = package.path .. ";" .. internal_root_path .. "vendor/share/lua/5.3/?/init.lua"
  package.path = package.path .. ";" .. internal_root_path .. "vendor/scythe/?.lua"
  -- package.path = package.path .. ";" .. internal_root_path .. "SYNTAX.tracks_actions.lua"
end

local input = require('state_machine')
local log = require('utils.log')

local function errorHandler(err)
  log.error(err)
  log.error(debug.traceback())
end

-- Xpcall is used to protect code execution from errors - the errorHandler
-- function will be called instead.
local function doInput(key_press)
  xpcall(input, errorHandler, key_press)
end

return doInput
