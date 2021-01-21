# SYNTAX

https://forum.cockos.com/showthread.php?t=212174
https://forum.cockos.com/showthread.php?t=176878

---

- move new naming function over to SYNTAX/actions

  - after each naming >> check comparison with previous tack find by GUID
    create a true diff check a la REACT

    ***

    change name > only change name / preserve prefix/opt
    change class
    change option

## fallback routes

- new group option 's'

  send new sub tracks to `B::<group_name>_sum`
  create if doesn't exist

> make sure a track is always routed somehow

priority list???

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
