-- local state_interface = require("state_machine.state_interface")
local on_command = require("library.on_command")

local pb = {}

pb.stop = function()
    on_command.main.stop_playback()
end

return pb
