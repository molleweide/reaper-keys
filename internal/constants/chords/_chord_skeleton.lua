this is a chord template in lua:

```

local chord_template = {
  name_long = "",
  name_short = "",
type = "", -- eg. triad
  notes = { } -- list of notes starting from zero, major chord = [0, 4, 7]
}
```
The interval numbers are relative steps - not absolute pitches.

Can you give me a table of all possible triads following this pattern.
Only reply with the code output.
