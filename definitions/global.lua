return {
  timeline_motion = {
    ["0"] = "ProjectStart",
    ["<C-$>"] = "ProjectEnd",
    ["f"] = "PlayPosition",
    ["["] = "LoopStart",
    ["]"] = "LoopEnd",
    ["("] = "TimeSelectionStart",
    [")"] = "TimeSelectionEnd",
    ["x"] = "MouseAndSnap",
    ["X"] = "Mouse",
    ["<M-h>"] = "Left10Pix",
    ["<M-l>"] = "Right10Pix",
    ["<M-H>"] = "Left40Pix",
    ["<M-L>"] = "Right40Pix",
    ["h"] = "LeftGridDivision",
    ["l"] = "RightGridDivision",
    ["H"] = "PrevMeasure",
    ["L"] = "NextMeasure",
    ["<C-h>"] = "Prev4Beats",
    ["<C-l>"] = "Next4Beats",
    ["<C-H>"] = "Prev4Measures",
    ["<C-L>"] = "Next4Measures",
    ["'"] = "RecallMark",
    ["`"] = "MoveToMark",
  },
  timeline_operator = {
    ["r"] = "Record",
    ["t"] = "PlayAndLoop",
  },
  timeline_selector = {
    ["v"] = "TimeSelection",
    [";"] = "NextRegion",
    ["'"] = "RecallMark",
    [","] = "PrevRegion",
    ["!"] = "LoopSelection",
    ["i"] = {"+inner", {
               ["<M-w>"] = "AutomationItem",
               ["l"] = "AllTrackItems",
               ["r"] = "Region",
               ["p"] = "ProjectTimeline",
               ["w"] = "Item",
               ["W"] = "BigItem",
    }},
  },
  visual_timeline_command = {
    ["v"] = "SetModeNormal",
    ["o"] = "SwitchTimelineSelectionSide",
  },
  command = {
    ["."] = "RepeatLastCommand",
    ["@"] = "PlayMacro",
    ["m"] = "Mark",
    ["q"] = "RecordMacro",
    ["<C-'>"] = "DeleteMark",
    ["<C-r>"] = "Redo",
    ["u"] = "Undo",
    ["R"] = "RecordOrStop",
    ["T"] = "TransportPlay",
    ["tt"] = "PlayFromTimeSelectionStart",
    ["F"] = "TransportPause",
    ["zt"] = "ScrollToPlayPosition",
    ["<C-i>"] = "ZoomRedo",
    ["<C-o>"] = "ZoomUndo",
    ["<M-i>"] = "MoveRedo",
    ["<M-o>"] = "MoveUndo",
    [">"] = "ShiftTimeSelectionRight",
    ["v"] = "SetModeVisualTimeline",
    ["<"] = "ShiftTimeSelectionLeft",
    ["<C-SPC>"] = "ToggleViewMixer",
    ["<ESC>"] = "Reset",
    ["<return>"] = "StartStop",
    ["<M-T>"] = "MoveToMouseAndPlay",
    ["<M-t>"] = "PlayFromMouse",
    ["<M-m>"] = "MidiLearnLastTouchedFX",
    ["<M-M>"] = "ShowEnvelopeModulationLastTouchedFx",
    ["<M-g>"] = "FocusMain",
    ["<M-f>"] = "FxToggleShow",
    ["<M-F>"] = "FxClose",
    ["<M-n>"] = "FxShowNextSel",
    ["<M-N>"] = "FxShowPrevSel",
    ["dr"] = "RemoveRegion",
    ["!"] = "ToggleLoop",
    ["<SPC>"] = { "+leader commands", {
      ["<SPC>"] = "ShowActionList",
      ["h"] = "ShowReaperKeysHelp",
      ["m"] = { "+midi", {
                  ["x"] = "CloseWindow",
                  ["g"] = "SetMidiGridDivision",
                  [","] = {"+options", {
                             ["q"] = "Quantize",
                             ["g"] = "ToggleMidiEditorUsesMainGridDivision",
                             ["s"] = "ToggleMidiSnap",

                  }},
      }},
      ["r"] = { "+recording", {
                  ["o"] = "SetTrackRecMidiOutput",
                  ["d"] = "SetTrackRecMidiOverdub",
                  ["t"] = "SetTrackRecMidiTouchReplace",
                  ["r"] = "SetTrackRecMidiReplace",
                  ["m"] = "SetTrackRecMonitorOnly",
                  ["i"] = "SetTrackRecInput",
                  ["a"] = "SetTrackRecInput",
                  [","] = {"+options", {
                             ["p"] = "ToggleRecordingPreroll",
                             ["z"] = "ToggleRecordingAutoScroll",
                             ["n"] = "SetRecordModeNormal",
                  }},
      }},
      ["s"] = { "+item selection", {
                  ["ci"] = "CycleItemFadeInShape",
                  ["co"] = "CycleItemFadeOutShape",
                  ["j"] = "NextTake",
                  ["k"] = "PrevTake",
                  ["d"] = "DeleteActiveTake",
                  ["s"] = "CropToActiveTake",
                  ["e"] = "OpenMidiEditor",
                  ["n"] = "ItemNormalize",
                  ["r"] = "ItemApplyFX",
                  ["g"] = "GroupItems",
      }},
      ["t"] = { "+track", {
                  ["n"] = "ResetTrackToNormal",
                  ["R"] = "RenderTrack",
                  ["i"] = "AddTrackVirtualInstrument",
                  ["r"] = "RenameTrack",
                  ["z"] = "MinimizeTracks",
                  ["M"] = "CycleRecordMonitor",
                  ["f"] = "CycleFolderState",
                  ["x"] = {"+routing", {
                             ["i"] = "TrackSetInputToMatchFirstSelected",
                             ["s"] = "ShowTrackRouting",
                  }},
                  ["F"] = { "+freeze", {
                    ["f"] = "FreezeTrack",
                    ["u"] = "UnfreezeTrack",
                    ["s"] = "ShowTrackFreezeDetails",
                  }},
      }},
      ["a"] = { "+automation", {
                  ["r"] = "SetAutomationModeTrimRead",
                  ["R"] = "SetAutomationModeRead",
                  ["g"] = "SetAutomationModeLatchAndArm",
                  ["l"] = "SetAutomationModeLatch",
                  ["p"] = "SetAutomationModeLatchPreview",
                  ["t"] = "SetAutomationModeTouch",
                  ["c"] = "SetAutomationModeTouchAndArm",
                  ["w"] = "SetAutomationModeWrite",
      }},
      ["e"] = {"+envelopes", {
                 ["t"]  = "ToggleShowAllEnvelope",
                 ["a"] = "ToggleArmAllEnvelopes",
                 ["A"] = "UnarmAllEnvelopes",
                 ["d"] = "ClearAllEnvelope",
                 ["v"] = "ToggleVolumeEnvelope",
                 ["p"] = "TogglePanEnvelope",
                 ["s"] = {"+selected", {
                            ["d"] = "ClearEnvelope",
                            ["a"] = "ToggleArmEnvelope",
                            ["y"] = "CopyEnvelope",
                            ["t"] = "ToggleShowSelectedEnvelope",
                            ["s"] = {"+shape", {
                                       ["b"] = "SetEnvelopeShapeBezier",
                                       ["e"] = "SetEnvelopeShapeFastEnd",
                                       ["f"] = "SetEnvelopeShapeFastStart",
                                       ["l"] = "SetEnvelopeShapeLinear",
                                       ["s"] = "SetEnvelopeShapeSlowStart",
                                       ["S"] = "SetEnvelopeShapeSquare",
                            }},
                 }},
      }},
      ["f"] = { "+fx", {
                  ["a"] = "FxAdd",
                  ["b"] = "TrackToggleFXBypass",
                  ["c"] = {"+chain", {
                            ["s"] = "FxChainToggleShow",
                            ["i"] = "ViewFxChainInputCurrentTrack",
                            ["di"] = "ClearFxChainInputCurrentTrack",
                            ["d"] = "ClearFxChainCurrentTrack",
                            ["y"] = "CopyFxChain",
                            ["p"] = "PasteFxChain",
                  }},
                  ["s"] = {"+show", {
                             ["1"] = "FxToggleShow1",
                             ["2"] = "FxToggleShow2",
                             ["3"] = "FxToggleShow3",
                             ["4"] = "FxToggleShow4",
                             ["5"] = "FxToggleShow5",
                             ["6"] = "FxToggleShow6",
                             ["7"] = "FxToggleShow7",
                             ["8"] = "FxToggleShow8",
                  }},
      }},
      [","] = {"+options", {
                 ["p"] = "TogglePlaybackPreroll",
                 ["v"] = "ToggleLoopSelectionFollowsTimeSelection",
                 ["s"] = "ToggleSnap",
                 ["c"] = "CycleRippleEditMode",
                 ["m"] = "ToggleMetronome",
                 ["t"] = "ToggleStopAtEndOfTimeSelectionIfNoRepeat",
                 ["i"] = "ToggleAutoCrossfade",
                 ["zt"] = "TogglePlaybackAutoScroll",
                 ["e"] = "ToggleEnvelopePointsMoveWithItems",
      }},
      ["g"] = { "+global", {
                  ["g"] = "SetGridDivision",
                  ["dr"] = "ResetControlDevices",
                  ["s"] = {"+show", {
                             ["x"] = "ShowRoutingMatrix",
                             ["w"] = "ShowWiringDiagram",
                             ["t"] = "ShowTrackManager",
                             ["p"] = "Preferences",
                  }},
                  ["f"] = {"+fx", {
                             ["x"] = "FxCloseAll",
                             ["c"] = "ViewFxChainMaster",
                  }},
                  ["e"] = { "+envelope", {
                              ["s"] = "ToggleShowAllEnvelopeGlobal",
                  }},
                  ["t"] = { "+track", {
                      ["a"] = "ClearAllRecordArm",
                      ["s"] = "UnsoloAllTracks",
                      ["m"] = "UnmuteAllTracks",
                  }},
                  ["a"] = { "+automation", {
                              ["r"] = "SetGlobalAutomationModeTrimRead",
                              ["l"] = "SetGlobalAutomationModeLatch",
                              ["p"] = "SetGlobalAutomationModeLatchPreview",
                              ["t"] = "SetGlobalAutomationModeTouch",
                              ["R"] = "SetGlobalAutomationModeRead",
                              ["w"] = "SetGlobalAutomationModeWrite",
                              ["S"] = "SetGlobalAutomationModeOff",
                  }},
      }},
      ["p"] = { "+project", {
                ["r"] = { "+render", {
                            ["."] = "RenderProjectWithLastSetting",
                            ["r"] = "RenderProject",
                        }},
                ["n"] = "NextTab",
                ["p"] = "PrevTab",
                ["N"] = "PrevTab",
                ["s"] = "SaveProject",
                ["o"] = "OpenProject",
                ["c"] = "NewProjectTab",
                ["d"] = "CloseProject",
                ["x"] = "CleanProjectDirectory",
            }},
    }},
  },
}
