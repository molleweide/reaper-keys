local vkb_mode_layout = require("definitions.defaults.virtual_keyboard")

return {
	timeline_motion = {
		["0"] = "ProjectStart",
		["<C-$>"] = "ProjectEnd",

		["f"] = "PlayPosition",
		["x"] = "MousePosition",
		["["] = "LoopStart",
		["]"] = "LoopEnd",
		["<left>"] = "PrevMarker",
		["<right>"] = "NextMarker",
		["<M-left>"] = "PrevTimeSignatureMarker",
		["<M-right>"] = "NextTimeSignatureMarker",
		["<M-h>"] = "Left10Pix",
		["<M-l>"] = "Right10Pix",
		["<M-H>"] = "Left40Pix",
		["<M-L>"] = "Right40Pix",
		-- how do i change the grid??
		["h"] = "LeftGridDivision",
		["l"] = "RightGridDivision",

		-- NOTE: The following moves by measure length,
		-- -> I need motions that move to the next/prev measureStart
		["H"] = "PrevMeasure",
		["L"] = "NextMeasure",
		["<C-i>"] = "MoveRedo",
		["<C-o>"] = "MoveUndo",
		["<C-h>"] = "Prev4Beats",
		["<C-l>"] = "Next4Beats",
		["<C-H>"] = "Prev4Measures",
		["<C-L>"] = "Next4Measures",
		["`"] = "MarkedTimelinePosition",
	},
	timeline_operator = {
		["r"] = "Record",
		["<C-p>"] = "DuplicateTimeline",
		["t"] = "PlayAndLoop",
		["%"] = "CreateMeasures",
		["<C-%>"] = "CreateProjectTempo",
	},
	timeline_selector = {
		["~"] = "MarkedRegion",
		["!"] = "LoopSelection",
		["<S-right>"] = "NextRegion",
		["<S-left>"] = "PrevRegion",
		["<CS-right>"] = "TimeSelectionShiftedRight",
		["<CS-left>"] = "TimeSelectionShiftedLeft",
		["i"] = {
			"+inner",
			{
				["<M-w>"] = "AutomationItem",
				["l"] = "AllTrackItems",
				["r"] = "Region",
				["p"] = "ProjectTimeline",
				["w"] = "Item",
				["W"] = "BigItem",
				-- TODO:
				-- ["m"] = "Measure",
			},
		},
	},
	visual_timeline_command = {
		["v"] = "SetModeNormal",
		["o"] = "SwitchTimelineSelectionSide",
	},
	-- i named it vkb since it is outputting rk commands..
	vkb_command = vkb_mode_layout,
	command = {
		["."] = "RepeatLastCommand",
		["@"] = "PlayMacro",
		["q"] = "RecordMacro",
		["m"] = "Mark", -- m<char> creates mark at editcursor (region if visual mode)
		["~"] = "MarkedRegion",
		['<C-">'] = "DeleteMark",
		["<C-'>"] = "DeleteAllMarks",
		["<S-right>"] = "NextRegion",
		["<S-left>"] = "PrevRegion",
		["<C-r>"] = "Redo",
		["u"] = "Undo",
		["R"] = "ToggleRecord",
		["T"] = "Play",
		["<C-T>"] = "PlayAndSkipTimeSelection",
		["<M-t>"] = "PlayFromMousePosition",
		["<CM-t>"] = "PlayFromMouseAndSoloTrack",
		["<C-t>"] = "PlayFromEditCursorAndSoloTrackUnderMouse",
		["tt"] = "PlayFromTimeSelectionStart",
		["F"] = "Pause",
		["<C-z>"] = "ZoomUndo",
		["<C-Z>"] = "ZoomRedo",
		["v"] = "SetModeVisualTimeline",
		["<M-v>"] = "ClearTimelineSelectionAndSetModeVisualTimeline",
		["<C-SPC>"] = "ToggleViewMixer",
		["<ESC>"] = "Reset",
		["<return>"] = "StartStop",
		["X"] = "MoveToMousePositionAndPlay",
		["dr"] = "RemoveRegion",
		["!"] = "ToggleLoop",
		["<C-a>"] = "ToggleBetweenReadAndTouchAutomationMode",
		["<M-n>"] = "ShowNextFx",
		["<M-N>"] = "ShowPrevFx",
		["<M-g>"] = "FocusMain",
		["<M-f>"] = "ToggleShowFx",
		["<M-F>"] = "CloseFx",
		["<CM-f>"] = "MidiLearnLastTouchedFxParam",
		["<CM-F>"] = "ModulateLastTouchedFxParam",
		["<M-x>"] = "ShowBindingList",
		["<C-m>"] = "TapTempo",
		['"'] = {
			"+snapshots",
			{
				["j"] = "RecallNextSnapshot",
				["k"] = "RecallPreviousSnapshot",
				["D"] = "DeleteAllSnapshots",
				["t"] = "ToggleSnapshotsWindow",
				["y"] = "CopyCurrentSnapshot",
				["p"] = "PasteSnapshot",
				["r"] = "RecallCurrentSnapshot",
				["#"] = {
					"+recall #",
					{
						["1"] = "RecallSnapshot1",
						["2"] = "RecallSnapshot2",
						["3"] = "RecallSnapshot3",
						["4"] = "RecallSnapshot4",
						["5"] = "RecallSnapshot5",
						["6"] = "RecallSnapshot6",
						["7"] = "RecallSnapshot7",
						["8"] = "RecallSnapshot8",
						["9"] = "RecallSnapshot9",
					},
				},
			},
		},
		[","] = {
			"+options",
			{
				["p"] = "TogglePlaybackPreroll",
				["r"] = "ToggleRecordingPreroll",
				["z"] = "TogglePlaybackAutoScroll",
				["v"] = "ToggleLoopSelectionFollowsTimeSelection",
				["s"] = "ToggleSnap",
				["m"] = "ToggleMetronome",
				["t"] = "ToggleStopAtEndOfTimeSelectionIfNoRepeat",
				["x"] = "ToggleAutoCrossfade",
				["e"] = "ToggleEnvelopePointsMoveWithItems",
				["c"] = "CycleRippleEditMode",
				["f"] = "ResetFeedbackWindow",
			},
		},
		["<SPC>"] = {
			"+leader commands",
			{
				["<SPC>"] = "ShowActionList",
				-- TODO: picker for all actions, including defaults and user, so that you
				-- can always get back to an action even though you have forgotten what
				-- it is called.
				["X"] = "PickerAllStandaloneActions",
				["k"] = "RK_MASTER_MENU",
				["F"] = "RK_SAMPLE_LIB_BROWSER",
				["w"] = "SetModeVKB", -- FIX: delete this...
				["d"] = {
					"+development",
					{
						["t"] = "devLogVtt",
						["l"] = "devLogAllParamsOfLastTouchedFx",
						["L"] = "devLogLastTouchedFxParamDetailed",
						["p"] = "devLogPaths",
						["n"] = "devlogLastTouchedFxNamedConfigParams",
					},
				},
				["i"] = {
					"+i/o device",
					{
						["q"] = "TrackInSet_MIDI_QMK",
						["g"] = "TrackInSet_MIDI_GRAND_ROLAND",
						["v"] = "TrackInSet_MIDI_VIRTUAL",
						["d"] = "TrackInSet_MIDI_DEFAULT",
					},
				},
				["z"] = {
					"+zoom/scroll",
					{
						["t"] = "ScrollToPlayPosition",
						["e"] = "ScrollToEditCursor",
					},
				},
				["M"] = {
					"+Mixing",
					-- NOTE: create a UI window with RK gui that shows the value for each
					-- mix parameter and a legend with each
					{ ["M"] = "EnterMixMode" },
				},
				["m"] = {
					"+midi",
					{
						["F"] = "Midi_ChangeActiveSelection",
						["f"] = "MIDI_EditMidiAtCurPosForTrack",
						["r"] = "Midi_EditMidiForRegionsMarksAndSelectTrack",

						["g"] = "SetMidiGridDivision",
						["m"] = "SetModeMidi",
						["i"] = "MidiPatternInsertFromString",
						["q"] = "Quantize",
						["Q"] = "ToggleInputQuantize",
						["s"] = "MidiVoxSetCurrentDrumTrigNote",
						[","] = {
							"+options",
							{
								["g"] = "ToggleMidiEditorUsesMainGridDivision",
								["s"] = "ToggleMidiSnap",
							},
						},
					},
				},
				["r"] = {
					"+recording",
					{
						["o"] = "SetRecordMidiOutput",
						["d"] = "SetRecordMidiOverdub",
						["t"] = "SetRecordMidiTouchReplace",
						["R"] = "SetRecordMidiReplace",
						["v"] = "SetRecordMonitorOnly",
						["r"] = "SetRecordInput",
						[","] = {
							"+options",
							{
								["n"] = "SetRecordModeNormal",
								["s"] = "SetRecordModeItemSelectionAutoPunch",
								["v"] = "SetRecordModeTimeSelectionAutoPunch",
								["p"] = "ToggleRecordingPreroll",
								["z"] = "ToggleRecordingAutoScroll",
								["t"] = "ToggleRecordToTapeMode",
							},
						},
					},
				},
				["a"] = {
					"+automation",
					{
						["r"] = "SetAutomationModeTrimRead",
						["R"] = "SetAutomationModeRead",
						["l"] = "SetAutomationModeLatch",
						["g"] = "SetAutomationModeLatchAndArm",
						["p"] = "SetAutomationModeLatchPreview",
						["t"] = "SetAutomationModeTouch",
						["u"] = "AUTOMATION_UI",
						["w"] = "SetAutomationModeWrite",
					},
				},
				["S"] = {
					"+segments",
					{
						-- TEST: make sure that all these can be used with count prefix.
						["T"] = "RepeatInsertTimeSelection",
						-- TODO: these three
						["R"] = "Items_DuplicateCountTimes",
						["r"] = "Items_DuplicateCountTimesAndGlue",
						["l"] = "Items_LoopCountTimes",
						---------------------------------
						-- use this to controll the song structure with fuzzy finder.
						["i"] = "InsertNewRegionSectionAfterExistingRegionPicker",
					},
				},
				["s"] = {
					"+selected items",
					{
						["j"] = "NextTake",
						["k"] = "PrevTake",
						["m"] = "ToggleMuteItem",
						["d"] = "DeleteActiveTake",
						["S"] = "UnselectItems",
						["E"] = "OpenMidiEditor",
						["T"] = "OpenEmptyItemNoteEditor",
						["c"] = "CropToActiveTake",
						["n"] = "ItemNormalize",
						["g"] = "GroupItems",
						["q"] = "QuantizeItems",
						["h"] = "HealItemsSplits",
						["s"] = "ToggleSoloItem",
						["b"] = "MoveItemContentToEditCursor",
						["x"] = {
							"+explode takes",
							{
								["p"] = "ExplodeTakesInPlace",
								["o"] = "ExplodeTakesInOrder",
								["a"] = "ExplodeTakesInAcrossTracks",
							},
						},
						-- ["S"] = { -- duplicate index...
						--   "+stretch",
						--   {
						--     ["a"] = "AddStretchMarker",
						--     ["d"] = "DeleteStretchMarker",
						--   },
						-- },
						["#"] = {
							"+fade",
							{
								["i"] = "CycleItemFadeInShape",
								["o"] = "CycleItemFadeOutShape",
							},
						},
						["t"] = {
							"+transients",
							{
								["a"] = "AdjustTransientDetection",
								["t"] = "CalculateTransientGuides",
								["c"] = "ClearTransientGuides",
								["s"] = "SplitItemAtTransients",
							},
						},
						["e"] = {
							"+envelopes",
							{
								["s"] = "ViewTakeEnvelopes",
								["m"] = "ToggleTakeMuteEnvelope",
								["p"] = "ToggleTakePanEnvelope",
								["P"] = "ToggleTakePitchEnvelope",
								["v"] = "ToggleTakeVolumeEnvelope",
							},
						},
						["f"] = {
							"+fx",
							{
								["a"] = "ApplyFxToItem",
								["p"] = "PasteItemFxChain",
								["d"] = "CutItemFxChain",
								["y"] = "CopyItemFxChain",
								["c"] = "ToggleShowTakeFxChain",
								["b"] = "ToggleTakeFxBypass",
							},
						},
						["r"] = {
							"+rename",
							{
								["s"] = "RenameTakeSourceFile",
								["t"] = "RenameTake",
								["r"] = "RenameTakeAndSourceFile",
								["a"] = "AutoRenameTake",
							},
						},
						["B"] = {
							"+timebase",
							{
								["t"] = "SetItemsTimebaseToTime",
								["b"] = "SetItemsTimebaseToBeatsPos",
								["r"] = "SetItemsTimebaseToBeatsPosLengthAndRate",
							},
						},
					},
				},
				["t"] = {
					"+track",
					{
						["n"] = "ResetTrackToNormal",
						["R"] = "RenderTrack",
						["r"] = "UpdateTrackName",
						["p"] = "UpdateTrackNamePrefix",
						["z"] = "MinimizeTracks",
						["m"] = {
							"+track mixer",
							{
								["e"] = "PickerFirstEQ_focused_track",
								["c"] = "PickerFirstComp_focused_track",
								["u"] = "TrackMixerUI",
							},
						},
						["M"] = "CycleRecordMonitor",
						["f"] = "CycleFolderState",
						["S"] = "ShowTrackRecordingSettings",
						["i"] = "SetTrackInputToMatchFirstSelected",
						["y"] = "SaveTrackAsTemplate",
						["i"] = {
							"+insert",
							{
								["c"] = "InsertClickTrack",
								["t"] = "InsertTrackFromTemplate",
								["o"] = "InsertTrackBelow",
								["O"] = "InsertTrackAbove",
								["i"] = "InsertVirtualInstrumentTrack",
								["1"] = "InsertTrackFromTemplateSlot1",
								["2"] = "InsertTrackFromTemplateSlot2",
								["3"] = "InsertTrackFromTemplateSlot3",
								["4"] = "InsertTrackFromTemplateSlot4",
							},
						},
						["x"] = {
							"+routing",
							{
								["x"] = "RouteUpdate",
								["f"] = "OpenRoutingUI",
								["q"] = "RouteRemoveAllSends",
								["Q"] = "RouteRemoveAllRecieves",
								["l"] = "RouteLogSelection",
								["c"] = "RouteTestCodedT",
								["p"] = "TrackToggleSendToParent",
								["s"] = "ToggleShowTrackRouting",
							},
						},
						["X"] = "FocusedTrack_FX_UI",
						["F"] = {
							"+freeze",
							{
								["f"] = "FreezeTrack",
								["u"] = "UnfreezeTrack",
								["s"] = "ShowTrackFreezeDetails",
							},
						},
					},
				},
				["e"] = {
					"+envelopes",
					{
						["t"] = "ToggleShowAllEnvelope",
						["a"] = "ToggleArmAllEnvelopes",
						["A"] = "UnarmAllEnvelopes",
						["d"] = "ClearAllEnvelope",
						["v"] = "ToggleVolumeEnvelope",
						["p"] = "TogglePanEnvelope",
						["w"] = "SelectWidthEnvelope",
						["s"] = {
							"+selected",
							{
								["d"] = "ClearEnvelope",
								["a"] = "ToggleArmEnvelope",
								["y"] = "CopyEnvelope",
								["t"] = "ToggleShowSelectedEnvelope",
								["b"] = "ToggleEnvelopeBypass",
								["s"] = {
									"+shape",
									{
										["b"] = "SetEnvelopeShapeBezier",
										["e"] = "SetEnvelopeShapeFastEnd",
										["f"] = "SetEnvelopeShapeFastStart",
										["l"] = "SetEnvelopeShapeLinear",
										["s"] = "SetEnvelopeShapeSlowStart",
										["S"] = "SetEnvelopeShapeSquare",
									},
								},
							},
						},
					},
				},
				["f"] = {
					"+fx",
					{
						["a"] = "AddFx",
						["c"] = "ToggleShowFxChain",
						["x"] = "CloseFx",
						["d"] = "CutFxChain",
						["y"] = "CopyFxChain",
						["p"] = "PasteFxChain",
						["b"] = "ToggleFxBypass",
						["M"] = "ModulateLastTouchedFxParam",
						["m"] = "MidiLearnLastTouchedFxParam",
						["i"] = {
							"+input",
							{
								["s"] = "ToggleShowInputFxChain",
								["d"] = "CutInputFxChain",
							},
						},
						["s"] = {
							"+show",
							{
								["1"] = "ToggleShowFx1",
								["2"] = "ToggleShowFx2",
								["3"] = "ToggleShowFx3",
								["4"] = "ToggleShowFx4",
								["5"] = "ToggleShowFx5",
								["6"] = "ToggleShowFx6",
								["7"] = "ToggleShowFx7",
								["8"] = "ToggleShowFx8",
							},
						},
						["w"] = "RandomizeRs5kSampleForFocusedTracks",
						["W"] = "PickerSelectSampleForSamplerOnSelectOrFocusedTrack",
					},
				},
				["T"] = {
					"+timeline",
					{
						["e"] = "EditTimeSignatureMarker",
						["d"] = "DeleteTimeSignatureMarker",
						["s"] = "ToggleShowTempoEnvelope",
					},
				},

				-- NOTE: global mappings are things that apply to everything including
				-- reaper ext state. Only global reaper state can be modified under
				-- the obal leader, anything project related goes under leader p.
				["g"] = {
					"+global",
					{
						["Q"] = "Quit",
						["g"] = "SetGridDivision",
						["m"] = "MediaExplorerToggle",
						["r"] = "ResetControlDevices",
						[","] = "ShowPreferences",
						["S"] = "UnsoloAllItems",
						["s"] = {
							"+show/hide",
							{
								["x"] = "ToggleShowRoutingMatrix",
								["w"] = "ToggleShowWiringDiagram",
								["t"] = "ToggleShowTrackManager",
								["m"] = "ShowMasterTrack",
								["M"] = "HideMasterTrack",
								["r"] = "ToggleShowRegionMarkerManager",
							},
						},
						["f"] = {
							"+fx",
							{
								["x"] = "CloseAllFxChainsAndWindows",
								["c"] = "ViewFxChainMaster",
							},
						},
						["e"] = { "+envelope", {
							["t"] = "ToggleShowAllEnvelopeGlobal",
						} },
						["t"] = {
							"+track",
							{
								["t"] = "ToggleAutomaticRecordArm",
								["a"] = "ClearAllRecordArm",
								["s"] = "UnsoloAllTracks",
								["m"] = "UnmuteAllTracks",
							},
						},
						["T"] = {
							"+toggle/tweaks",
							{ ["W"] = "ToggleFollowMotions" },
						},
						["a"] = {
							"+automation",
							{
								["r"] = "SetGlobalAutomationModeTrimRead",
								["l"] = "SetGlobalAutomationModeLatch",
								["p"] = "SetGlobalAutomationModeLatchPreview",
								["t"] = "SetGlobalAutomationModeTouch",
								["R"] = "SetGlobalAutomationModeRead",
								["w"] = "SetGlobalAutomationModeWrite",
								["S"] = "SetGlobalAutomationModeOff",
							},
						},
						["l"] = {
							"+logging",
							{
								-- NOTE: it might be smarter to use fzf picker for these...
								-- I should only imlpement two of these as a toggle so that I
								-- can quickly toggle/switch log state, but
								--
								--
								-- TEST: it would be pretty cool to use the fzf `.ini` file
								-- parser to create this, ie. start using a new custom config
								-- file where I specify some of these things.
								-- >>> later, when I know more about treesitter, then I can
								-- do all of the parsing in lua instead...
								--
								["t"] = "SetLogLevelTrace",
								["d"] = "SetLogLevelDebug",
								["i"] = "SetLogLevelInfo",
								["w"] = "SetLogLevelWarn",
								["u"] = "SetLogLevelUser",
								["e"] = "SetLogLevelError",
								["f"] = "SetLogLevelFatal",
								["x"] = "CloseReaConsole",
								["C"] = "ClearConsole",
							},
						},
					},
				},

				-- NOTE: anything that saves to project state should be kept here under
				-- the `projects` leader.
				["p"] = {
					"+project",
					{
						[","] = "ShowProjectSettings",
						["a"] = {
							"+nodes (add)",
							{
								["n"] = "Nodes_Add_UserInput",
							},
						},
						["n"] = "NextTab",
						["p"] = "PrevTab",
						["s"] = "SaveProject",
						["S"] = "SaveProjectAs",
						["o"] = "OpenProject",
						["m"] = "INSERT_MIDI_BLOCK",
						["c"] = "NewProjectTab",
						["x"] = "CloseProject",
						["C"] = "CleanProjectDirectory",
						["S"] = "SaveProjectWithNewVersion",
						["t"] = {
							"+timebase",
							{
								["t"] = "SetProjectTimebaseToTime",
								["b"] = "SetProjectTimebaseToBeatsPos",
								["r"] = "SetProjectTimebaseToBeatsPosLengthAndRate",
							},
						},
						["r"] = {
							"+render",
							{
								["."] = "RenderProjectWithLastSetting",
								["r"] = "RenderProject",
							},
						},
						["R"] = "Regions_UI_string",
					},
				},
			},
		},
	},
}
