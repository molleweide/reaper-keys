local retval   =  {};
local sel      =  {};
local mute     =  {};
local startppq =  {};
local endppq   =  {};
local chan     =  {};
local pitch    =  {};
local vel      =  {};
local semitone = val;
local Undo_BegBlock ;


for i = 1,CountItem do;
  local item = reaper.GetMediaItem(0,i-1);
  local CountTake = reaper.CountTakes(item);
  for i2 = 1,CountTake do;
    local take = reaper.GetMediaItemTake(item,i2-1);
    local midi = reaper.TakeIsMIDI(take);
    if midi then;
      local ret,notecnt,ccevtcnt,textsyxevtcnt = reaper.MIDI_CountEvts(take);
      for i3 = notecnt-1,0,-1 do;
        retval  [i3],
        sel     [i3],
        mute    [i3],
        startppq[i3],
        endppq  [i3],
        chan    [i3],
        pitch   [i3],
        vel     [i3] = reaper.MIDI_GetNote(take,i3);
        reaper.MIDI_DeleteNote(take,i3);
      end;
      for i4 = notecnt-1,0,-1 do;
        reaper.MIDI_InsertNote(take,
          sel     [i4],
          mute    [i4],
          startppq[i4],
          endppq  [i4],
          chan    [i4],
          pitch   [i4]+semitone,
          vel     [i4],
          true);
      end;
      reaper.MIDI_Sort(take);
      Undo_BegBlock = "Active";
    end;
  end
end; 


reaper.UpdateArrange();
