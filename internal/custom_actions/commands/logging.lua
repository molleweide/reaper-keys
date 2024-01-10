local log = require("utils.log")
local format = require("utils.format")

local logging_commands = {}

logging_commands.setLogLevelTrace = function()
  reaper.SetExtState("reaper_keys_logging", "log_level", "trace", true)
end

logging_commands.setLogLevelDebug = function()
  reaper.SetExtState("reaper_keys_logging", "log_level", "debug", true)
end

logging_commands.setLogLevelInfo = function()
  reaper.SetExtState("reaper_keys_logging", "log_level", "info", true)
end

logging_commands.setLogLevelWarn = function()
  reaper.SetExtState("reaper_keys_logging", "log_level", "warn", true)
end

logging_commands.setLogLevelUser = function()
  reaper.SetExtState("reaper_keys_logging", "log_level", "user", true)
end

logging_commands.setLogLevelError = function()
  reaper.SetExtState("reaper_keys_logging", "log_level", "error", true)
end

logging_commands.setLogLevelFatal = function()
  reaper.SetExtState("reaper_keys_logging", "log_level", "fatal", true)
end

-- TODO: this should be moved into a util wrapper so that I can call
-- ultrashcall with one fn call.
logging_commands.closeReaConsole = function()
  dofile(reaper.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua")
  reaper.SetExtState("reaper_keys_logging", "log_level", "fatal", true)
  local retval = ultraschall.CloseReaScriptConsole()
end

logging_commands.clearConsole = function()
  log.clear()
end

return logging_commands
