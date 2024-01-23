return {
  track_motion = {
    ["G"] = "LastTrack",
    ["gg"] = "FirstTrack",
    -- i don't use folders so I could replace these.
    -- ["J"] = "NextFolderNear",
    -- ["K"] = "PrevFolderNear",
    ["/"] = "MatchedTrackForward",
    ["?"] = "MatchedTrackBackward",
    ["n"] = "NextTrackMatchForward",
    ["N"] = "NextTrackMatchBackward",

    -- TODO: additional action prefixRepetitionCount mode
    -- pass number as arg to function.
    -- I don't want repeat action.
    -- I want to use the prefix number as an argument to the
    -- command action.
    -- >>> Then, : and G would become the same action, and work for both
    -- main and midi.
    [":"] = "TrackWithNumber",

    ["j"] = "NextTrack",
    ["k"] = "PrevTrack",
    -- the num X by which I jump could be stored in a config or ini, and altered with fzf
    ["<C-b>"] = "Prev10Track",
    ["<C-f>"] = "Next10Track",
    ["<C-d>"] = "Next5Track",
    ["<C-u>"] = "Prev5Track",

    -- ["???"] = "NextZone",
    -- ["???"] = "PrevZone",
    -- ["???"] = "NextGroup",
    -- ["???"] = "PrevGroup",
    -- ["???"] = "NextMCAB_M",
    -- ["???"] = "PrevMCAB_M",
    -- ["???"] = "NextMCAB_MC",
    -- ["???"] = "PrevMCAB_MC",
    -- ["???"] = "NextMCAB_A",
    -- ["???"] = "PrevMCAB_A",
    -- ["???"] = "NextMCAB_B",
    -- ["???"] = "PrevMCAB_B",
    -- ["???"] = "NextMCAB_T",
    -- ["???"] = "PrevMCAB_T",
  },
  visual_track_command = {
    ["V"] = "SetModeNormal",
    -- add these to pickers.track_params
    ["<C-h>"] = "NudgeTrackPanLeft",
    ["<C-l>"] = "NudgeTrackPanRight",
    ["<C-H>"] = "NudgeTrackPanLeft10Times",
    ["<C-L>"] = "NudgeTrackPanRight10Times",
  },
  track_selector = {
    ["'"] = "MarkedTracks",
    ["c"] = "FolderChildren",
    ["F"] = "FolderParent",
    ["F"] = "Folder",
    ["i"] = {
      "+inner",
      {
        ["c"] = "InnerFolder",
        ["f"] = "InnerFolderAndParent",
        ["g"] = "AllTracks",
        ["Z"] = "InnerZoneTracks",
        ["G"] = "InnerGroupTracks",
        ["S"] = "InnerSplitTracks",
      },
    },
    -- ["I"] = {
    --   "+a/outer",
    --   {
    --     ["G"] = "OuterGroupTracks",
    --   }
    -- },
  },
  track_operator = {
    ['"'] = {
      "+snapshots",
      {
        ["s"] = "SaveTracksToCurrentSnapshot",
        ["c"] = "CreateNewSnapshotWithTracks",
        ["d"] = "DeleteTracksFromCurrentSnapshot",
      },
    },
    ["z"] = "ZoomTrackSelection",
    ["<TAB>"] = "MakeFolder",
    ["d"] = "CutTrack",
    ["a"] = "ArmTracks",
    ["s"] = "SelectTracks",
    ["S"] = "ToggleSolo",
    ["M"] = "ToggleMute",
    ["y"] = "CopyTrack",
    ["<M-C>"] = "ColorTrackGradient",
    ["<M-c>"] = "ColorTrack",
  },
  timeline_operator = {
    ["s"] = "SelectItemsAndSplit",
    ["<M-p>"] = "CopyAndFitByLooping",
    ["<M-s>"] = "SelectEnvelopePoints",
    ["d"] = "CutItems",
    ["y"] = "CopyItems",
    ["<C-c>"] = "CopyItems",
    ["<M-d>"] = "CutEnvelopePoints",
    ["<M-y>"] = "CopyEnvelopePoints",
    ["<C-D>"] = "DeleteTimeline",
    ["g"] = "GlueItems",
    ["#"] = "SetItemFadeBoundaries",
    ["z"] = "ZoomTimeSelection",
    ["Z"] = "ZoomTimeAndTrackSelection",
    ["a"] = "InsertOrExtendMidiItem",
    ["A"] = "InsertEmptyItem",
    ["<M-a>"] = "InsertAutomationItem",
    ["c"] = {
      "+change/fit",
      {
        ["a"] = "InsertOrExtendMidiItem",
        ["c"] = "FitByLoopingNoExtend",
        ["f"] = "FitByLooping",
        ["p"] = "FitByPadding",
        ["s"] = "FitByStretching",
      },
    },
  },
  timeline_selector = {
    ["s"] = "SelectedItems",
  },

  timeline_motion = {
    ["<CM-l>"] = "NextTransientInItem",
    ["<CM-h>"] = "PrevTransientInItem",
    ["<CM-L>"] = "NextTransientInItemMinusFadeTime",
    ["<CM-H>"] = "PrevTransientInItemMinusFadeTime",
    ["B"] = "PrevBigItemStart",
    ["E"] = "NextBigItemEnd",
    ["W"] = "NextBigItemStart",
    ["b"] = "PrevItemStart",
    ["<M-b>"] = "PrevEnvelopePoint",
    ["e"] = "NextItemEnd",
    ["w"] = "NextItemStart",
    ["<M-w>"] = "NextEnvelopePoint",
    ["$"] = "LastItemEnd", -- rename: LastItemOfCurrentTrackEnd
    -- ["$t"] = "LastItemOfProject"
    ["("] = "TimeSelectionStart",
    [")"] = "TimeSelectionEnd",
  },
  command = {
    [">"] = "TrimItemRightEdge",
    ["<"] = "TrimItemLeftEdge",
    ["<TAB>"] = "CycleFolderCollapsedState",
    ["zp"] = "ZoomProject",
    ["D"] = "CutSelectedItems",
    ["Y"] = "CopySelectedItems",
    ["V"] = "SetModeVisualTrack",
    ["<M-j>"] = "NextEnvelope",
    ["<M-k>"] = "PrevEnvelope",
    ["<C-+>"] = "ZoomInVert",
    ["<C-->"] = "ZoomOutVert",
    ["<CM-+>"] = "ZoomInTrackVert",
    ["<CM-->"] = "ZoomOutTrackVert",
    ["+"] = "ZoomInHoriz",
    ["-"] = "ZoomOutHoriz",
    [";"] = "MoveItemToEditCursor", -- put this at <leader>;
    ["dd"] = "CutTrack",
    ["d"] = {
      "+delete",
      { ["d"] = "CutTrack", ["C"] = "CmdCustomCutTrack" },
    },
    ["aa"] = "ArmTracks",
    -- ["O"] = "EnterTrackAbove",
    -- ["o"] = "EnterTrackBelow",
    ["o"] = {
      "+track_insert",
      {
        ["o"] = "EnterTrackBelow",
        ["O"] = "EnterTrackAbove",
        -- FIX: implement these!!
        -- This should work with count prefix just as the o/O commands above.
        ["c"] = "CmdCustomInsertTrackBelow",
        ["C"] = "CmdCustomInsertTrackAbove",
      },
    },
    ["I"] = {
      "+main_insert",
      {
        ["f"] = "InsertAudioFile_File_Browser",

        ["m"] = "PickFullSongs",
        ["g"] = "GetAudioFromInternet", -- ?????/

        ["d"] = {
          "+drum_samples",
          { ["k"] = "InsertAudioFile_Fzf_Kicks", ["s"] = "InsertAudioFile_Fzf_Snare" },
        },
        ["x"] = {
          "+fx_samples",
          {
            ["u"] = "InsertAudioFile_Fzf_lifter",
            ["d"] = "InsertAudioFile_Fzf_downer",
            ["t"] = "InsertAudioFile_Fzf_transient",
            ["n"] = "InsertAudioFile_Fzf_noise_etc",
          },
        },
        ["a"] = {
          -- Eg. atmospheres/wierd noises
          "+various",
          { ["u"] = "InsertAudioFile_Fzf_lifter", ["d"] = "InsertAudioFile_Fzf_downer" },
        },

        ["e"] = "InsertEmptyMeasures",
      },
    },
    -- ["p"] = "Paste",
    ["p"] = {
      "+put",
      { ["p"] = "Paste", ["C"] = "CmdCustomPutTrack" },
    },
    -- ["<C-v>"] = "Paste",
    -- ["yy"] = "CopyTrack",
    ["y"] = {
      "+yank",
      {
        ["y"] = "CopyTrack",
        ["C"] = "CmdCustomYankTrack",
      },
    },
    ["zz"] = "ScrollToSelectedTracks",
    ["|"] = "SplitItemsAtEditCursor",
    ["~"] = "MarkedRegion",
    ["<C-j>"] = "NudgeTrackVolumeDownBy1Tenth",
    ["<C-k>"] = "NudgeTrackVolumeUpBy1Tenth",
    ["<C-J>"] = "NudgeTrackVolumeDownBy1",
    ["<C-K>"] = "NudgeTrackVolumeUpBy1",
    ["<CM-j>"] = "ShiftEnvelopePointsDownATinyBit",
    ["<CM-k>"] = "ShiftEnvelopePointsUpATinyBit",
    ["<CM-J>"] = "ShiftEnvelopePointsDown",
    ["<CM-K>"] = "ShiftEnvelopePointsUp",
    ["<M-S>"] = "SelectItemsUnderEditCursor",
    ["'"] = "MarkedTracks",

    -- TODO: select all items that are adjacent.
    -- This is a bit experimental,
    -- Select all items that can be reached by touching
    -- subsequent items. >> Start with the first item that is positionned
    -- at track/cursor intersection.
    -- ["?"] = "SelectAdjacentItems",

  },
}
