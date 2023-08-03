local log = require("utils.log")

local utils_io = {}

-- this is a bit annoying to research but I guess this is because of all thennnn

utils_io.findWavFilesWithNameX = function(searchName)
	local packagesDir = os.getenv("HOME")

	if not packagesDir then
		log.warn("PACKAGES environment variable not set!!!")
		return {}
	end

	local sampleLibraryDirectory = packagesDir .. "/reaper/samples/1Shots Sampler Inst/WA - Complete Drums"

-- find /path/to/directory -type f -iname "*X*.wav"
	local command = string.format('find "%s" -type f -iname "*%s*.wav"', sampleLibraryDirectory, searchName)
	local handle = io.popen(command)
	local result = handle:read("*all")
	handle:close()

	local wavFiles = {}
	for path in result:gmatch("[^\r\n]+") do
		table.insert(wavFiles, path)
	end

  local p
	if #wavFiles > 0 then
    p = wavFiles[1]
  end

	-- log.user(searchName .. "| " .. #wavFiles, p)

	return wavFiles
end

return utils_io
