-- Basic MIDI-Controller v0.9 in Lua
-- Meo-Ada Mespotine 27th of September 2020
-- licensed under MIT-license

-- some velocities are limited, maybe I'll fix it at some point

-- you can change these:
midichannel=0           -- default midi-channel is 1
mode=0                  -- default target is 0(vkb), see StuffMidiMessage in the API-docs for other ones
keysize=27              -- the size of the keys, minimum is 20
KeyboardXDrawOffset=612 -- the left side of the shown keyboard, currently set to show C4 in the middle.
KeyboardYDrawOffset=300 -- the y-offset of the keyboard. This is locked to the bottom of the window!
LockMode=false          -- Midi-note-lockmode, default is unlocked


-- now the actual script comes
if WinX==nil then WinX=10 end
if WinY==nil then WinY=10 end
if WinW==nil then WinW=700 end
if WinH==nil then WinH=310 end

KeyTable={}

gfx.init("Midi Controller", WinW, WinH, 0, WinX, WinY)
gfx.setfont(1,"Arial", 15, 1)
Maxsize=0               -- just keep that
MidiNotes_Strings={"C","C#","D","D#","E","F","F#","G","G#","A","A#","H"} -- notenames
OldMidiNote=0           -- temporary note-name for lockmode management

-- resize the used framebuffers
gfx.setimgdim(1,8100,512)
gfx.setimgdim(2,8100,512)


function DrawGradient(x,y,w,h,note)
  -- draw gradient-key into framebuffer 1, which will be read for note and velocity values
  gfx.dest=1
  local step=(h/128)
  local start=0
  local note=note/255
  for i=1, 128 do
    gfx.set(note, i/255, 0.8)
    gfx.rect(x,y+math.floor(start),w,math.ceil(step),1)
    start=start+step
  end
  gfx.set(0)
  gfx.rect(x,y,w,h,0)
  gfx.dest=-1
  Maxsize=x+w
end

function DrawKeys(x,y,w,h,color,shownote,oct)
  -- draw the actual shown key into framebuffer 2
  if color==0 then bgcolor=1 else bgcolor=0 end
  gfx.dest=2
  local step=(h/128)
  local start=0
  for i=1, 128 do
    gfx.set(color)
    gfx.rect(x,y+math.floor(start),w,math.ceil(step),1)
    start=start+step
  end
  gfx.set(0.7)
  gfx.roundrect(x,y,w,h,0)
  gfx.set(0.4)
  if shownote==1 then gfx.x=x+2 gfx.y=y+h-gfx.texth gfx.drawstr("C"..math.floor(oct/12)) end
  gfx.dest=-1
end

function DrawKeyboard()
  -- draw the gradient and the shown keyboard
  local i=1
  local Pattern={0,1,0,1,0,0,1,0,1,0,1,0}
  local step=0
  local patcount=1

  -- white keys(they are simpler)
  for i=1, 128 do
    if Pattern[patcount]==0 then
      step=step+keysize
      KeyTable[i]=keysize+step
      DrawGradient(keysize+step,gfx.h-200,keysize,178,i)
      DrawKeys(keysize+step,gfx.h-200,keysize,178,1, patcount, i)
    else
    end
    patcount=patcount+1
    if patcount>12 then patcount=1 end
  end

  -- black keys(they are more sophisticated)
  step=keysize>>1
  patcount=1
  for i=1, 128 do
    if Pattern[patcount]==0 then
      step=step+keysize
    else
      KeyTable[i]=keysize+step
      DrawGradient(keysize+step,gfx.h-200,keysize,128,i)
      DrawKeys(keysize+step,gfx.h-200,keysize,128,0)
    end
    patcount=patcount+1
    if patcount>12 then patcount=1 end
  end
end

function main()
  -- clear window with gray background
  gfx.set(0.25)
  gfx.rect(0,0,gfx.w,gfx.h,1)

  -- get the current note-mode from keyboard-modifier
  if gfx.mouse_cap&8==8 then CC=32 CCMode="CC"
  elseif gfx.mouse_cap&4==4 then CC=48 CCMode="PC"
  elseif gfx.mouse_cap&16==16 then CC=80 CCMode="Pitch"
  else CC=0 CCMode="Note"
  end

  -- correct position of the drawnkeyboard in relation to window-height
  if KeyboardXDrawOffset<40 then KeyboardXDrawOffset=40 end
  if KeyboardXDrawOffset>Maxsize-gfx.h then KeyboardXDrawOffset=Maxsize-gfx.h end

  -- do some key-input-management
  A=gfx.getchar()

  -- tab locks/unlocks the clicked key
  if     A==9.0 and LockMode==false then LockMode=true
  elseif A==9.0 and LockMode==true then LockMode=false
  end

  -- Offset the shown keyboard, so you can look at other octaves
  if A==1818584692.0 and gfx.mouse_cap==0 then KeyboardXDrawOffset=KeyboardXDrawOffset-1 end -- small steps
  if A==1919379572.0 and gfx.mouse_cap==0 then KeyboardXDrawOffset=KeyboardXDrawOffset+1 end -- small steps
  if A==1818584692.0 and gfx.mouse_cap&4==4 then KeyboardXDrawOffset=KeyboardXDrawOffset-gfx.w+50 end -- huge steps
  if A==1919379572.0 and gfx.mouse_cap&4==4 then KeyboardXDrawOffset=KeyboardXDrawOffset+gfx.w-50 end -- huge steps
  if A==1818584692.0 and gfx.mouse_cap&8==8 then KeyboardXDrawOffset=KeyboardXDrawOffset-40 end -- smaller steps
  if A==1919379572.0 and gfx.mouse_cap&8==8 then KeyboardXDrawOffset=KeyboardXDrawOffset+40 end -- smaller steps

  -- Select MIDI-channel
  if A==1685026670.0 and gfx.mouse_cap==0 then midichannel=midichannel-1 if midichannel<0 then midichannel=0 end end
  if A==30064.0 and gfx.mouse_cap==0 then midichannel=midichannel+1 if midichannel>15 then midichannel=15 end end

  -- Select destination
  if A==1685026670.0 and gfx.mouse_cap&4==4 then mode=mode-1 if mode<0 then mode=0 end end
  if A==30064.0 and gfx.mouse_cap&4==4 then mode=mode+1 end

-- zoom in keysize; works only with Reaper 6.14+ due increasing of image-size
--  if A==43.0 then keysize=keysize+10 if keysize>80 then keysize=80 end DrawKeyboard() end
--  if A==45.0 then keysize=keysize-10 if keysize<20 then keysize=20 end DrawKeyboard() end

  -- keep in mind old midi-note(for later prevention of hanging notes)
  if MidiNote~=0 then
    OldMidiNote=MidiNote
  end

  -- get current mousepositon in relation to gradient-keyboard-framebuffer-coordinates
  gfx.x=gfx.mouse_x-10+KeyboardXDrawOffset
  gfx.y=KeyboardYDrawOffset-gfx.h+gfx.mouse_y

  -- get the note and velocity of the currently clicked note. For that, we read the color-value store at this coordinate in
  -- framebuffer 1. red=note, green=velocity, blue=unused
  gfx.dest=1
  NewMidiNote, MidiVelocity2, MidiLastVal=gfx.getpixel(1,1,1)

  -- with lockmode enabled, a clicked note will not be changed, even if mouse hovers over other notes
  -- with lockmode disabled, the note currently clicked will be played, even if the mouse moves to another note
  if LockMode==true and gfx.mouse_cap&1==0 then
    MidiNote=NewMidiNote
    MidiNote=math.floor(MidiNote*255)
    MidiNotes_String=MidiNotes_Strings[MidiNote%12]
  elseif LockMode==false then
    MidiNote=NewMidiNote
    MidiNote=math.floor(MidiNote*255)
    MidiNotes_String=MidiNotes_Strings[MidiNote%12]
  end

  -- in case of lockmode, we still want to be able to get the current velocity
  -- does this always work?
  _, MidiVelocity2, MidiLastVal=gfx.getpixel(1,1,1)
  MidiVelocity=math.floor(MidiVelocity2*255)

  -- draw keyboard
  gfx.dest=-1
  gfx.x=10
  gfx.y=gfx.h-KeyboardYDrawOffset
  gfx.blit(2,1,0,KeyboardXDrawOffset,0,gfx.w-40,512)

  -- draw spot when clicking and play note
  if gfx.mouse_cap&1==1 and MidiNote~=0 then
    -- draw spot
    gfx.set(MidiVelocity2*2,0, MidiVelocity*2)
    gfx.circle(gfx.mouse_x, gfx.mouse_y, 4, 1)
    gfx.set(1)
    gfx.circle(gfx.mouse_x, gfx.mouse_y, 4, 0)

    -- send notes
    reaper.StuffMIDIMessage(mode,144+midichannel+CC, OldMidiNote-1, 0) -- stop old midi-note
    reaper.StuffMIDIMessage(mode,144+midichannel+CC, MidiNote-1, MidiVelocity-1) -- play new midi note
  else
    reaper.StuffMIDIMessage(mode,144+midichannel+CC, MidiNote-1, 0) -- stop midi-note, when not clicked
  end

  -- draw messages

  -- first, midi-states
  gfx.x=gfx.w-245
  gfx.y=gfx.h-KeyboardYDrawOffset+30
  gfx.set(1)
  if MidiNotes_String==nil then MidiNotes_String="   " end
  if mode==0 then showmode="Virtual keyboard"
  elseif mode==1 then showmode="Control input"
  elseif mode==2 then showmode="Virtual keyboard(cur channel)"
  elseif mode>15 then showmode="Ext MIDI device #"..mode-15
  else showmode="Unknown #"..mode-2
  end
  if LockMode==true then Locked="locked" else Locked="unlocked" end
  if gfx.mouse_cap&1==1 and MidiNotes_String~="   " then clicked="(clicked)" else clicked="" end
  gfx.drawstr("Current Notemode: "..CCMode.."\nCurrent MIDI-Channel: "..midichannel.."\nDestination: "..showmode.."\nNote ("..Locked.."): "..MidiNotes_String..clicked.."\nVelocity: "..MidiVelocity)

  -- now the introduction
  gfx.x=10
  gfx.y=gfx.h-KeyboardYDrawOffset+15
  gfx.drawstr("Usage:\n   1) Hold keyboard-modifier to select NoteMode(Note, CC, PC, Pitch)\n   2) Left/right; Shift+left/right; Ctrl+left/right to move keyboard\n   3) Up/down to select MIDI-channel\n   4) Ctrl/Cmd+up/down - select destination\n   5) Tab locks clicked midi-note")

  -- now the header
  gfx.x=10
  gfx.y=4
  gfx.drawstr("Basic MIDI-controller in Lua - Meo-Ada Mespotine 26th of September 2020")

  -- prevent window from being resized too small
  if gfx.h<295 then gfx.init("", gfx.w, 295) end
  if gfx.w<637 then gfx.init("", 637, gfx.h) end

  -- if esc is hit, end script, otherwise continue
  if A~=27 then
    reaper.defer(main)
  else
    gfx.quit()
  end
end

-- startup and here we go
DrawKeyboard()
main()
