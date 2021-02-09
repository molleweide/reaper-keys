---
title: Routing
nav_order: 4
---

# Routing

You need to assign `routing.create()`


## source / destination tracks

(1,5,46,trX,trY)


(trA,45)(trX,trY,15,16)


## set channels

### AUDIO

(1,5,46,trX,trY)[]

### MIDI

(trA,45)(trX,trY,15,16){}

## disable

Apply disable prop to affected targets

For audio and midi this value ! turns audio off. If both audio and midi off
then delete route index

(1,5,46,trX,trY)

## remove

## set values

Use any of `amv` flags to set values manually.

eg `(15)a0d2` send selected track ch 1/2 into track #15 ch 3/4

## toggle values

## nudge values

## combine w/ other functions

- sidechain selected tracks to match

    1. apply reacomp to last fx
    2. rename to `COMP_SC_KICK`
    3. route to track match kick

## TODO

- how escape brackets?
    why? -> currently `|` pipe is used for separating targets and channel inputs.
    This is because I don't understand how to escape [] in strings for UserInput in
    testing. Brackets do not load in the input field, which only matters during testing,
    and it's also quite arbitrary but it would
- refactor into as small an concise reusable functions/modules as possible
- move util functions to utils
