# REAPER KEYS TODO

## practice

recording modes > dummy record as much as possible

## new actions

- create new take in selected region

- match tr idx >> add scroll to position

## i need to have full alphabet marks for all types of selection markers

## Learn RK in depth.

1. I have to learn snippets with neovim
2. Put snippets all over RK to actually get a feel for whats happening.
3.

## section management / @ edit cursor

`necessary commands for fast shuffle around project segments`

- insert space
- paste time sel
- insert space AND paste time sel

## regions

- add ability to save notes to the region. ?
  `-----------------------------------------------------------------`

# unused keys

folder keys f/c/<TAB>
enter track o/O

## RK internals

how does state_machine get the actual key press sent to it?

`-----------------------------------------------------------------`
`-----------------------------------------------------------------`
`-----------------------------------------------------------------`

# REAPER-AUTO-SYNTAX TODO

https://forum.cockos.com/showthread.php?t=212174
https://forum.cockos.com/showthread.php?t=176878

---

2. organize synths
3. set levels
4. syncthing
5. improve channel splitters
6. I need to improve the mouse mode asap.
7. move new naming function over to SYNTAX/actions

   - after each naming >> check comparison with previous tack find by GUID

     ***

     change name > only change name / preserve prefix/opt
     change class
     change option

## YPCI

- item extension
- ypc insert new?

## FX SYNTAX

channel splitter >>> does it work now?
make sure it works now with F-commands

name index fx starting from 1, not 0

- make fx config into functions that return based on what `otion flags` are being used
  if 'm' then return x num of fx

## CLASSES

!!! rm C >>> and use an option again. this would make handling configs easier
I can handle all things in one place
Both GROUP 'm' option and MIDI 'c' option will be handled both in the midi config

## midi

- add piano roll info to group objects 'm' option in configs???
- build kompose midi plugin > piano range > map to channel > route to various tracks

## general

all util funcs should take syntax_obj as inputs, not tracks hmmm.. ??

mv REAPER-SYNTAX into root dir of REAPER-KEYS/internal/syntax/ ...hhmmmmm ????
mv track obj .lua to syntax/

## reaper keys

custom action that makes parent group movement work for all tracks OR mode??
inside within 'm' groups. >>> BIG

## syntax state vars

is there a way that I can keep track of whether track names has changed or trace numbers has changed.
so that I don't need to run the full track tree function before I do something every time...

# add pitch name in piano roll mappes so I always know which keys to hit.

## bulk/groupTarget turn on/off FX

fx naming > ability to turn on/off FX of different types based on syntax selection.

## sidechain function

create fuzzy find window for sending channels that works kind of like the
s/ command in vim. so that I by specifying a specific string to the function
I can use regex to tell what kind of send I want/ mono/stere/midi/in/out/etc...

it can really become an awesome extension to reaper. I could achieve this by looking at
the RFUZZ and then modify it so it can be used for sends. just modify the syntax to create
sends instead of searching for fx.

## bulk mute/solo/etc. based on syntax criterion.

eg. based on FX type.

- object that holds all possible FX class names.

## create / converst / render new tracks.

Something interesting will be to create converstion function
that take one track and converts it into the other.

eg.

1. take a M:/A: track and create a new A: track from it.

> reduce computations

2. take and A: track and create midi from it?

This is the type of functions that really you can nest quite deep since they won't
be used all the time.

```

```

## FAST PRODUCTION SETUP ==========================

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

## ================================================

## RNDM

this is going to be so fucking awesome. because the more I use it the more it becomes like
an instrument. the new system for managing regions is awesome. and I have access to like
20-30 marks per row which is absolutely amazing.

oooh, i just realized that I will be able to make my own key map with Hammerspoon? Right?
And when I have the same types of layer pads then I will have the exact same layout on laptop and on qmk,
which is pretty much insane.

That could actually be an awesome open source project to have for mirroring layouts between
qmk and laptop.

I know that if I use reaper keys more and more.

I solve small problems along the way and this will become like a super instrument
that I will be able to use to create shit so fast the better I become.
It is actually insane what a nasty exponential learning curve it has.
But exponential always wins in the long run especially since we can compose
commands. that is the amazing aspect of this library that if you have a good
workflow of note taking in parallell then you will always be able to have
the exact tools that you want.
