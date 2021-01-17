# REAPER KEYS TODO

`always always always handle tracks by ID, never track indeces.`

## TODO

hook setup midi router when pressing record.

- routing.lua

- segments

- midi

- fx > toggle bypass fx super important.

  A new track fx mode would be ideal i think. So that I can use regular
  up down commands to navigate the fx list.

- fx > config state > log touched parameter

  very interesting config variable for ui dev

## QUESTIONS

`can I rename the reaper.app file. eg. duplicate and rename reaper dir when new version??`

- parent track (A) | don't record any midi to here. no midi items

  input from midi keyboard

  note repeater < has no effect?!

- child track (B) | I want to record midi to this track, i.e. create midi items here

  arpegiator

- grand child track (C)

  midi synth

## regions =================================================

- add ability to save notes to the region. ?

# UNUSED KEYS ==============================================

folder keys f/c/<TAB>
enter track o/O

## RK internals

how does state_machine get the actual key press sent to it?

## FAST PRODUCTION SETUP ===================================

- sends

  util > ghost_xxxxxxxx
  util > ghost_kick
  util > ghost_snare

  action > sidechain to track name > find track with name 'ghost' && 'kick/snare/'

- templates

  create a function that takes and saves all components of the project.

  master
  drums
  music
  fx

  ```lua
  -- auto store and create importable modules of the current project
  -- increment names in
  for each zone
  for each group
  ```

## RNDM ====================================================

and I will do this later, but when these bases are started then mike will probably
appreciate my work and he might critique my code or refactor it.
