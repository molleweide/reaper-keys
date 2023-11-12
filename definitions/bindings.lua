-- bindings in this file are prioritized over the default bindings
-- if you need help, check out the documentation https://gwatcha.github.io/reaper-keys/configuration/bindings.html
-- check out the ./defaults directory to see examples
return {
	global = {
		timeline_motion = {},
		timeline_operator = {},
		timeline_selector = {},
		visual_timeline_command = {},
		command = {

      -- TODO: add binds for resetting eg. routes
      -- >> remove all routes for all
      -- tracks, to sort of reset the project if I am unsure that I have
      -- cluttered shit up or something.
      -- >> remove all plugins on all tracks.

			["<SPC>"] = {
				"+leader commands",
				{
					["j"] = {
						"+jjjjj",
						{
							["f"] = "PickerAddTrackFx",
							["w"] = "PickerTest",

							-- TODO: modify `tracks` picker so that I can jump from inside
							-- midi editor and change focus to the selected track, and if
							-- there is any midi item in the same position, otherwise create
							-- one.
							["t"] = "PickerAllTracks",
							--
							-- FIX: below later...
							-- ...
							["r"] = "PickerRegions",
							["q"] = "PickerMarks",

							["x"] = "PickerTrackFx",
							["i"] = "PickerTrackFxParams", -- todo!!

							["I"] = "PickerTrackAttr",

							["a"] = "PickerTrackRoutes", -- todos!!
							["p"] = "PickerReaperProjects",
							["d"] = "PickerDrums",
							["m"] = "PickerMusic",
							["A"] = "PickerAllItems",
							["v"] = "PickerAllItemsVisible",
							["s"] = "PickerSamples",
							[";"] = "PickerFileBrowser",
							["n"] = "PickerNewTracksFromPreset.",
						},
					},
				},
			},
		},
	},
	main = {
		track_motion = {},
		visual_track_command = {
			["<C-,>"] = {
				"+trkop",
				{
					["d"] = "gCut",
					["p"] = "gPut",
					["y"] = "gYank",
				},
			},
		},
		track_selector = {},
		track_operator = {
			-- ["a"] = "ArmTracksWithMidiRouter",
		},
		timeline_operator = {},
		timeline_selector = {},
		timeline_motion = {},
		command = {
			-- ["aa"] = "ArmTracksWithMidiRouter", -- only works for command right now.
			["zp"] = "ZoomProjectCustom",
			["<SPC>"] = {
				"+leader commands",
				{
					["ll"] = "Launcher",
					["X"] = { "+TESTING", {
						["T"] = "ReaperTesting",
					} },
				},
			},
			["<C-,>"] = {
				"+cmd",
				{
					["c"] = "LogWhatever",
					["C"] = "CloseReaConsole",
					["f"] = "FuzzyFx",
					["l"] = "LogLastTouchFxParams",
					["mq"] = "TrackInSet_MIDI_QMK",
					["mg"] = "TrackInSet_MIDI_GRAND_ROLAND",
					["mv"] = "TrackInSet_MIDI_VIRTUAL",
					["md"] = "TrackInSet_MIDI_DEFAULT",
					["R"] = "RepeatInsertTimeSelection",
					["S"] = "SaveAllTracksAsTemplate",
					["w"] = "ApplyConfigs",
					["sk"] = "sidechainToGhostKick",
				},
			},
		},
	},
	midi = {
		timeline_selector = {},
		timeline_operator = {},
		timeline_motion = {},
		command = {},
	},
}
