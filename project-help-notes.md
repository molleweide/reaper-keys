# project help noter

I have to make a diagram of the logic so that I can understand it because
this is quite complex

---

# root

---

## definitions/--------------

## actions

## config

## global

## main

## midi

---

# internals/-----------------

## command

- sequence_functions/global
  requires runner & state_interface
  runAction & runActionNTimes 

- builder
  req constants, sequences, utils.def, utils.getAction, 
  
  fn getActionKey & buildCommandWithActionSequence

- executor
    uses sequences & utils
      uses sequence_functions.context
        uses runner, state_interface, & def.conf
        

    

## custom_actions

## library

## saved/

## state_machine/

## utils

## vendor

---

## key_scripts/--------------

## scripts/------------------
