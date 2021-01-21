# RS YPC

now I have to sketch out the possible scenarios that can happen when I do the midi
thing and this is going to be interesting

`.............A............B.............C.............................D................`
finished`.....|+++++++++|..|+++++++++++|.|++++++++++++++++++++++++++|..|++++++++++++++|.`
itemParent`...|#########|.....|########|.|tS_#########_tE| |#######|......|#######|.....`
itemExtStat`..|@@@@@@@@@|..|@@@@@@@@|.......|sS_@@@@@@@@@@_sE|.........|@@@@@@@@@@@@@@|.`
midi-notes`...n__.n_.nn__....n__.n.n____....n.n_n_nnnnn_______.nn.n__...n.nn.n__.n.n__..`
`.......................................................................................`

##

- insert and extend current (target) item OR create new item.
- take data from ext state (source)
- L/R status / in what directions do we have overlap?
  first check for left overlap

```lua

-- variables
source_item_cnt = 0   -- index of the current source item I am pulling data from.
prev_insert_pos = 0       -- time ppq position after which it makes sense to look for a new target item when changing sourceItem
prev_insert_cnt = 0
left_overlap
right_ovrelap

vicinity_status = {}

for sourceItem
  local sourceStart = extState.pos
        sourceEnd   = sourceStart + extState.length
        targetStart =
        targetEnd   =


  -- >>>> for loop negative backwards
  if sourceEnd < targetStart then
    -- 1. no touch / target in future >> next
  else
    -- at least touching or beyond
    if sourceEnd <= targetEnd then
      if sourceStart < targetStart then
        -- 2. right overlap
      else
        -- 3. target fully over / extend on both sides
      end
    else
      if sourceStart <= targetStart then
        -- 4. target is inside of source
      else
        -- 5. left overlap
      end
    end
  end




    -- -- analyse the surrounding area of the source item
    -- targetItem = GetItem(tr_parent_group, prev_insert_cnt)

    -- if targetEnd < sourceStart then -- fully before
    --   next item, analysisDone=true
    -- else
    --  -- dest overlap rigth DOR
    --  if
    -- end



  -- if sourceItem.pos == targetItem.pos -- <=
  --   prev_insert_pos = targetItem.pos -- or source?
  --   insert all notes into targetItem

  source_item_counter++
end
```
