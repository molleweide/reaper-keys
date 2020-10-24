# midi ideas for RK

- ability to jump to a note by number / pitch name

  eg. 48 -> move to C3
  eg. C3 -> move to note 48
  Use the one you feel most comfortable with...

- InsertNote -> InsertNote(s) / default note = 1
  create custom insert note action that works the exact same way
  as currently but allow for adding an additional param that is
  note relative to the current note.

- prevent the playCursor from being moved to the end of midi insert motion.
  Now you cannot program midi during playback because the playCursor is moved
  every time you insert a note.

  > > > if playBack > only move edit cursor.
