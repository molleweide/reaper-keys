return {
  track_motion = {
    ["G"] = "LastTrack",
    ["gg"] = "FirstTrack",
    ["J"] = "NextFolderNear",
    ["K"] = "PrevFolderNear",
    ["/"] = "MatchedTrackForward",
    ["?"] = "MatchedTrackBackward",
    ["n"] = "NextTrackMatchForward",
    [":"] = "TrackWithNumber",
    ["N"] = "NextTrackMatchBackward",
    ["j"] = "NextTrack",
    ["k"] = "PrevTrack",
    ["<C-b>"] = "Prev10Track",
    ["<C-f>"] = "Next10Track",
    ["<C-d>"] = "Next5Track",
    ["<C-u>"] = "Prev5Track",
  },
  visual_track_command = {
    ["o"] = "SwitchTrackSelectionSide",
    ["V"] = "SetModeNormal",
  },
  track_selector = {
    ["V"] = "Selection",
    ["i"] = {"+inner", {
               ["f"] = "InnerFolder",
               ["F"] = "InnerFolderAndParent",
               ["g"] = "AllTracks",
    }},
    ["F"] = "SelectFolderParent",
  },
  track_operator = {
      ["z"] = "ZoomTrackSelection",
      ["<C-s>"] = "ToggleShowTracksInMixer",
      ["f"] = "MakeFolder",
      ["d"] = "CutTrack",
      ["a"] = "ArmTracks",
      ["s"] = "SelectTracks",
      ["S"] = "ToggleSolo",
      ["m"] = "ToggleMute",
      ["y"] = "CopyTrack",
      ["<M-C>"] = "ColorTrackGradient",
      ["<M-c>"] = "ColorTrack",
  },
  timeline_operator = {
    ["<M-i>"] = "InsertAutomationItem",
    ["s"] = "SelectItems",
    ["d"] = "CutItems",
    ["y"] = "CopyItems",
    ["<M-s>"] = "SelectEnvelopePoints",
    ["<M-d>"] = "CutEnvelopePoints",
    ["<M-y>"] = "CopyEnvelopePoints",
    ["g"] = "GlueItems",
    ["%"] = "HealSplits",
    ["#"] = "SetItemFadeBoundaries",
    [">"] = "GrowItemRight",
    ["<"] = "GrowItemLeft",
    [";"] = {"+fitting", {
            ["f"] = "FitByLoopingNoShift",
            ["l"] = "FitByLooping",
            ["p"] = "FitByPadding",
            ["y"] = "CopyAndFitByLooping",
            ["s"] = "FitByStretching",
    }},
    ["i"] = "InsertOrExtendMidiItem",
  },
  timeline_selector = {
    ["s"] = "SelectedItems",
    ["<M-s>"] = "AutomationItem",
  },
  timeline_motion = {
    ["B"] = "PrevBigItemStart",
    ["E"] = "NextBigItemEnd",
    ["W"] = "NextBigItemStart",
    ["b"] = "PrevItemStart",
    ["<CM-l>"] = "NextTransientInItem",
    ["<CM-h>"] = "PrevTransientInItem",
    ["<M-b>"] = "PrevEnvelopePoint",
    ["e"] = "NextItemEnd",
    ["w"] = "NextItemStart",
    ["<M-w>"] = "NextEnvelopePoint",
    ["<C-a>"] = "FirstItemStart",
    ["$"] = "LastItemEnd",
  },
  command = {
    ["<TAB>"] = "CycleFolderCollapsedState",
    ["<S-TAB>"] = "CycleFolderState",
    ["<M-S>"] = "UnselectEnvelopePoints",
    ["<up>"] = "PrevTake",
    ["<down>"] = "PrevTake",
    ["D"] = "CutSelectedItems",
    ["Y"] = "CopySelectedItems",
    ["V"] = "SetModeVisualTrack",
    ["<M-j>"] = "NextEnvelope",
    ["Z"] = "ZoomTimeAndTrackSelection",
    ["<M-k>"] = "PrevEnvelope",
    ["<C-+>"] = "ZoomInHoriz",
    ["<C-->"] = "ZoomOutHoriz",
    ["+"] = "ZoomInVert",
    ["-"] = "ZoomOutVert",
    ["<C-m>"] = "TapTempo",
    ["dd"] = "CutTrack",
    ["aa"] = "ArmTracks",
    ["O"] = "EnterTrackAbove",
    ["o"] = "EnterTrackBelow",
    ["p"] = "Paste",
    ["P"] = "PasteAbove",
    ["yy"] = "CopyTrack",
    ["zt"] = "ScrollToPlayPosition",
    ["zz"] = "ScrollToSelectedTracks",
  },
}
