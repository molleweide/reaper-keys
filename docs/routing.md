---
title: Routing
nav_order: 4
---

# Routing

You need to assign `routing.create()`

## category ##################################################

- TODO: use capital S/R for category = send/recieve


## SOURCE / DESTINATION TRACKS ##################################


(5,tr_name)               selection send to track #5 and match:tr_name

(trA,45)(trX,trY,15,16)   source / dest complex arguments


if S

()        send from sel -> ()
(A)(B)    send from (A) -> (B)

if R

(other)        selection recieves ()
(A)(other)    A recieves the other


## SET CHANNELS ################################################

### AUDIO -----------


(1,5,46,trX,trY)[0,2]

send selection to match:tr_name src ch 3/4 to dst ch 5/6

(tr_name)a2d4

- TODO: rename a to s ((s)rc/(d)st)

### MIDI -----------

(trA)(trX){5,6}   create midi send from match:trA ch5 to match:trX ch 6

## UPDATE ROUTE ###############################################

(tr_name)ua2      force update sel src ch to src ch = 3/4 (dst ch default)

## DISABLE ###################################################

Apply disable prop to affected targets

For audio and midi this value ! turns audio off. If both audio and midi off
then delete route index

(tr_name)!a     only midi send to match:tr_name

## REMOVE ####################################################

-             remove all sends / recieves of selection, or coded sources
-S            remove all sends on sel tr | or code
-R            remove all recieves on sel tr | or code
-(ghost)R     delete all recieves from track match:ghost to selection
-(kick)S      delete all sends on match:tr_name to sel
-(A)(B)       delete all A recieves from B


## set values ----------------

Use any of `admv` flags to set values manually.

eg `(15)a0d2` send selected track ch 1/2 into track #15 ch 3/4

## toggle values

mute
phase

## nudge values ###############################################

volume
pan

## pre / post ##################################################


## COMBINE W/ OTHER FUNCTIONS ##################################

- sidechain selected tracks to match

    1. apply reacomp to last fx
    2. rename to `COMP_SC_KICK`
    3. route to track match kick

- `if track num_sends == 0 and name match:drum_categories` send to DRUMS_ALL

    get tracks that match drum categories
    
      `routing.create('(DRUMS_ALL){0,0}', list_drum_tracks)`


## TODO

- how escape brackets?
    why? -> currently `|` pipe is used for separating targets and channel inputs.
    This is because I don't understand how to escape [] in strings for UserInput in
    testing. Brackets do not load in the input field, which only matters during testing,
    and it's also quite arbitrary but it would
- refactor into as small an concise reusable functions/modules as possible
- move util functions to utils
