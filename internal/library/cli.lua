local log = require("utils.log")
local format = require("utils.format")

local cli = {}

function execute_command(command)
  -- log.user("command:" .. command)

  -- local tmpfile = os.tmpname()
  os.execute(command .. " 2>&1")

  -- local handle = io.popen(command .. " 2>&1")

  local handle = io.open("/Users/hjalmarjakobsson/reaper/tmp/cli/launcher.txt", "r")

  local result = handle:read("*a")
  handle:close()

  -- os.remove(tmpfile)

  return result
end

function run_custom_launcher()
  local homedir = os.getenv("HOME")
  if not homedir then
    log.warn("PACKAGES environment variable not set!!!")
    return {}
  end

  local command = homedir .. "/.config/dorothy/commands/launcher"
  return execute_command(command)
end

cli.run_launcher = function()
  -- local massivePath = require("definitions.config").path_presets.massive

  -- local success, result = pcall(run_custom_launcher)
  local output = run_custom_launcher()

  local selected_item = output:match("[^\r\n]+") -- This captures the first line of the output

  log.user("LAUNCHER:", selected_item)
end

cli.run_neovim_telescope = function() end

return cli
