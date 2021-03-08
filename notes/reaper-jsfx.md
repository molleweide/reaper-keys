# MIDI_CONTROLLER

plug Js: MIDI EXAMINER >>> log events

- either I can use a single track as arouter with only one pre processor, OR I
  can quite easilly fix this by adding the preprocessor to my syntax fx. Then
  the problem is solved. And then later if reaper updates with this ability I can
  also easilly change to using a router when that is available. Nice! I can relax!

- insert `MY_MIDI_PRE_PROCESSOR` jsfx on all tracks when I update tree.
  put inside config -> as first plugin always.

- the only thing I have to do is start an FX project and then add the file to
  the SYNTAX.

## TODO

4. action > connecting midi router to record enablede tracks.

   - onRecArmTrack
     increment ARMEDTRACKSCOUNT + 1
     check if midi router is routed to track

   - onUnarmTrack
     decr ARMEDTRACKSCOUNT - 1
     disconnect track from midirouter

   - onUnarmAllTrack

## MIDI ROUTER GUI

get list of routed tracks > make selectable what send to what destination.

## INTERACTION TREE

- DEVICE

  EZ / KEYS / KIT

- ELEMENT

  RHYTHM / MUSIC / FX

- voices

  EZ
  KEYS
  KIT

## piano mode

## change channel / sound / articulation L/R

use one hand for selecting velocity or have switches.

and then play pitches with the other hand.

two different synths per side. w scale. this could be great for creating heavy.
riffs.

## drum single

creat a mode for creating very dynamic drums where I can do a single pitch per side?
and then control velocity on the other side.

## full drum kit

double thumb kicks
left hand snare.
right hand hihat.
a couple of toms
crash / ride
percs
