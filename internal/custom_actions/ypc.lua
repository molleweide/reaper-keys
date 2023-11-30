local ypc = {}

local USE_NATIVE_YPC = false

ypc.yank = function(meta, opts)
	local sx_tracks = require("syntax.tracks")
	local libtr = require("library.tracks")
	-- local log = require("utils.log")
	-- local format = require("utils.format")
	local t_foc_tr, t_obj_list = libtr.get_focused_track_objects()
	sx_tracks.getVerifiedTree(t_obj_list) -- make this an opt param in get_focused_track_objects

	-- log.user(format.block(t_foc_tr))

	local t_single_track_data = libtr.get_single_track_data_for_yanking(t_foc_tr[1])

	local log = require("utils.log")
	local format = require("utils.format")

	-- TODO: later account for multiple tracks

	-- log.user(format.block(t_single_track_data.item_objs))

	-- for k, v in pairs(t_single_track_data) do
	-- 	log.user("yank", k, format.block(v))
	-- end

	require("utils.project_state").overwrite("ypc", "tracks", t_single_track_data)
end

ypc.put = function(meta, opts)

	-- a. insert track
	-- ??

	-- b. if drum lanes shift midi accordingly
	--       > ignore for now...

	-- c. insert new midi
	--
	--
	-- just see if this is possible
	--

	-- d. update ui
	--
	--
	--
end

ypc.cut = function(meta, opts)
	-- a. perform yank
	-- b. remove track
	-- c. if drum lanes shift midi accordingly.
	-- d. ui update
end
ypc.insertTrackAbove = function(meta, opts)
	-- a.
end
ypc.insertTrackBelow = function(meta, opts)
	-- a.
end

return ypc
