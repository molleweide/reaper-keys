# REAPER KEYS VIM IDEAS

## marks ideas

custom edit region text >> insert after register char

eg. `c - chorus; d - dropHard`

how many possible registers are there?

# fx mode. create a mode for navigating fx?

`does rk commands not work when fx window is focused??!`

5 moveNext
2 delete movePrev
rename fx
select Next Param
select prev Param
increment selecterd fx param.
insert fx chain before selected
insert fx chain after selected
save selecterd as fx chain.

select audio file > open up from path.

## text mode ??

OpenMidiEditor ->> OpenItemEditor >> if empty open add text???

## programmatically save eg. trackTemplate

    reaper.Main_openProject(string name)
    `opens a project. will prompt the user to save, etc. if you pass a .RTrackTemplate file then it adds that to the project instead.`
    reaper.Main_SaveProject(ReaProject proj, boolean forceSaveAsIn)

    > > > test if the same works for SAVE

# hide track sets???

used in conjuction with syntax?

## add sends.

1. add send
2. add receive
3. remove send/receive

## switch focus to reaConsole

so that one can close it easilly
