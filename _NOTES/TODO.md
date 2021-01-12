# REAPER KEYS TODO

## TODO

- routing.lua

  1. clean up code as much as possible.

     - put all vars on top.
     - what can be put in configs?

  2. fix rm usage of syntax objects inside of createMidiSends.
     otherwise it becomes locked to syntax and not modular.

- routing > fix sidechain function > make pr > comment about my ideas + fuzzy

- segments > bug

- midi > learn how to program

- syntax > auto fallback routing

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
