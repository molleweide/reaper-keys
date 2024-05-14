--- User Settings
local set_start = true
local set_end = true
-----------------

function print(...)
    local t = {}
    for i, v in ipairs( { ... } ) do
        t[i] = tostring( v )
    end
    reaper.ShowConsoleMsg( table.concat( t, " " ) .. "\n" )
end
-------------------------
-------- Iterate MIDI Functions
-------------------------

---Iterate this function it will return the takes open in midi_editor window.
--editable_only == get only the editables
---@param midi_editor midi_editor midi_editor window
---@param editable_only boolean If true get only takes that are editable in midi_editor
---@return function iterate takes
function enumMIDITakes(midi_editor, editable_only)
    local i = -1
    return function()
        i = i + 1
        return reaper.MIDIEditor_EnumTakes(midi_editor, i, editable_only)
    end
end

---This is the simple version that haves no filter besides the last event.
---Easy to understand and if you want to check the difference in performance
---with my IterateMIDI function. Or if you want to filter yourself.
---@param MIDIstring string string with all MIDI events (use reaper.MIDI_GetAllEvts)
---@param filter_midiend boolean Filter Last MIDI message (reaper automatically add a message when item ends 'CC123')
---@return function
function IterateAllMIDI(MIDIstring,filter_midiend)
    -- Should it iterate the last midi 123 ? it just say when the item ends
    local MIDIlen = MIDIstring:len()
    if filter_midiend then MIDIlen = MIDIlen - 12 end
    local iteration_stringPos = 1
    local offset_count = 0
    return function ()
        if iteration_stringPos < MIDIlen then
            local offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, iteration_stringPos)
            iteration_stringPos = stringPos
            offset_count = offset + offset_count
            return  offset, offset_count, flags, msg, stringPos
        else -- Ends the iteration
            return nil
        end
    end
end

-------------------------
-------- Pack/Unpack MIDI/Flags Functions
-------------------------

---Unpack a packed string MIDI message in different values
---@param msg string midi as packed string
---@return number msg_type midi message type: Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15.
---@return number msg_ch midi message channel 1 based (1-16)
---@return number data2 databyte1 -- like note pitch, cc num
---@return number data3 databyte2 -- like note velocity, cc val. Some midi messages dont have databyte2 and this will return nill. For getting the value of the pitchbend do databyte1 + databyte2
---@return string text if message is a text return the text
---@return table allbytes all bytes in a table in order, starting with statusbyte. usefull for longer midi messages like text
local function UnpackMIDIMessage(msg)
    local msg_type = msg:byte(1)>>4
    local msg_ch = (msg:byte(1)&0x0F)+1 --msg:byte(1)&0x0F -- 0x0F = 0000 1111 in binary. this is a bitmask. +1 to be 1 based
    local text
    if msg_type == 15 then
        text = msg:sub(3)
    end
    local val1 = msg:byte(2)
    local val2 = (msg_type ~= 15) and msg:byte(3) -- return nil if is text
    return msg_type,msg_ch,val1,val2,text,msg
end

---Receives numbers(0-255). or strings. and return them in a string as bytes
---@param ... number
---@return string
function PackMessage(...)
    local msg = ''
    for i, v in ipairs( { ... } ) do
        local new_val
        if type(v) == 'number' then
            new_val = string.char(v)
        elseif type(v) == 'string' then -- In case it is a string (useful for midi text where each byte is a character)
            new_val = v
        elseif not v then -- in case some of the messages is nil. No problem! This is useful as PackMIDITable will send .val2 and .text. not all midi have val2 and not all midi have .text
            new_val = ''
        end
        msg = msg..new_val
    end
    return msg
end

---Pack a midi message in a string form. Each character is a midi byte. Can receive as many data bytes needed. Just join midi_type and midi_ch in the status bytes and thow it in PackMessage.
---@param midi_type number midi message type: Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15.
---@param midi_ch number midi ch 1-16 (1 based.)
---@param ... number sequence of data bytes can be number (will be converted to string(a character with the equivalent byte)) or can be a string that will be added to the message (useful for midi text where each byte is a character).
function PackMIDIMessage(midi_type,midi_ch,...)
    local midi_ch = midi_ch - 1 -- make it 0 based
    local status_byte = (midi_type<<4)+midi_ch -- where is your bitwise operation god now?
    return PackMessage(status_byte,...)
end

---Unpack flags into selected, muted, curve_shape
---@param flag number
---@return boolean selected is selected
---@return boolean muted is muted
---@return integer curve_shape curve type 0square, 1linear, 2slow start/end, 3fast start, 4fast end, 5bezier
local function UnpackFlags(flag)
    local selected =  flag&1 == 1   -- AND operation with  1 (1 in binary) (return the first bit val)
    local muted =  flag&2 == 2      -- AND operation with 10 (2 in binary) (return the second bit val + 1 bit as 0 I could also move it to the void)
    -- cc_string
    local curve_shape = flag>>4 -- Void the first 4 bits as they dont matter for cc curve and get the value. If is flags from something without curve shape like notes will just return 0, as square
    return selected, muted, curve_shape
end

---Pack options into flags
---@param selected boolean is selected
---@param muted boolean is muted
---@param curve_shape number curve type 0square, 1linear, 2slow start/end, 3fast start, 4fast end, 5bezier
---@return integer flags flags number
function PackFlags(selected, muted, curve_shape)
    local flags = curve_shape and curve_shape<<4 or 0
    flags = flags|(muted and 2 or 0)|(selected and 1 or 0) -- if selected or muted are true return number. this is a OR operation flags|2or0|1or0 (2 = 10 ; 1 = 1)
    return flags
end

---------------------
----------------- MIDI Table Handling
---------------------
-- ADD
--PutMIDI: Use this function to insert the midi in the table with the same offset that it had.
--InsertMIDIUnsorted: Use this function to add a NEW midi message to the take. It will use place holders to keep the offset of the current messages right
-- SET
--SetMIDIUnsorted: Use this function to Change the position of a midi message.
--It will use place holders to keep the offset of the other messages right
-- DELETE
--InsertPlaceHolder: Use this function to delete MIDI Messages. It just add an empty message(place holder) that will be deleted at MIDI Sorting
-- PACK
--PackPackedMIDITable: Makes a string packing the midi table
-- Internal:
--TableInsertWithPlaceHolder Don't use this function directly, it is called at InsertMIDIUnsorted and SetMIDIUnsorted.

---Insert in the table normally without changing position (just to make a nice abstraction)
---@param midi_table table with all midi events
---@param offset number offset from last message
---@param offset_count number optional total offset
---@param flags number --flags message, packed
---@param msg string midi message packed
function PutMIDI(midi_table,offset,offset_count,flags,msg)
    midi_table[#midi_table+1] = { offset = offset, offset_count = offset_count, flags = flags, msg = msg}
end

---Insert MIDI and a placeholder At the end of the table. The midi will happen at ppq from the start of the item. The place holder will compensate back to position the table endded. table needs to have .offset_count
---@param midi_table table table with all midi events
---@param ppq number  when in ppq insert the message
---@param midi_msg string midi message.
---@param flags string flags message.
function InsertMIDIUnsorted(midi_table,ppq,midi_msg,flags)
    local last_offset_count
    if #midi_table > 0  then
        last_offset_count = midi_table[#midi_table].offset_count -- ppq position of the last element
    else
        last_offset_count = 0
    end
    local new_offset = ppq - last_offset_count -- Diference between desired position and end.
    TableInsertWithPlaceHolder(midi_table,new_offset,ppq,new_offset,midi_msg,flags,nil) -- Insert with new_offset and insert placeholder with -new_offset
end

---Insert MIDI and a placeholder At the end of the table. If want to change the
--value of something that already was in the list the place holder need to be
--positioned to compensate the diference over the original ppq. Using
--InsertMIDIUnsorted will give the wrong result
---@param midi_table table table with all midi events
---@param ppq number  when in ppq insert the message
---@param original_ppq number  when in ppq was the original message
---@param midi_msg string midi message.
---@param flags string flags message.
---@param pos any -- optional position on the list to be insert. pos = 3 will insert this message at position 3 and Place holder at 4 else will be added at the end of the list. with pos this is slower, optionally you can always insert at the end and calculate the delta from the last element and insert it at the end!
local function SetMIDIUnsorted(midi_table,ppq,original_ppq,midi_msg,flags,pos)
    local last_offset_count
    if #midi_table > 0  then
        last_offset_count = midi_table[#midi_table].offset_count -- ppq position of the last element
    else
        last_offset_count = 0
    end
    local new_offset = ppq - last_offset_count -- Diference between desired position and end.
    local delta = ppq - original_ppq
    TableInsertWithPlaceHolder(midi_table,new_offset,ppq,delta,midi_msg,flags,pos) -- Insert with new_offset and insert placeholder with -new_offset
end

---Insert in a table with a place holder. This is the way to delete events. Place holder is always one key after compensating the delta so the offset of the next message dont need to change, or even calculate! e.g: insert a message 960ppq after previous message. would make next message be 960ppq latter. This function will insert the message with offset = 960 and a placeholder with offset = -960, so next message already is with the right offset.
---@param midi_table table with all midi events
---@param offset number offset from last message
---@param offset_count number optional total offset
---@param delta number distance in ppq from place holder. Inserting delta = offset. Setting delta = offset - old_offset!  negative is the place holder happens after delta ppq. positive place holder happens before delta ppq.
---@param midi_msg any --midi message, packed
---@param flags any --flags message, packed
---@param pos any -- optional position on the list to be insert. pos = 3 will insert this message at position 3 and Place holder at 4 else will be added at the end of the list. with pos this is slower, optionally you can always insert at the end and calculate the delta from the last element and insert it at the end!
function TableInsertWithPlaceHolder(midi_table,offset,offset_count,delta,midi_msg,flags,pos)
    local message = {offset = offset ,msg = midi_msg, flags = flags, offset_count = offset_count}
    local offset_count_holder = offset_count and (offset_count - delta) or nil
    local holder = {offset = -delta ,msg = '', flags = 0, offset_count = offset_count_holder}
    if not pos then
        midi_table[#midi_table+1] = message -- new_offset = offset + delta. new  difference from last midi message
        midi_table[#midi_table+1] = holder-- put a place holder nothing message that get deleted where this message originally was. so dont need to sort next midi message
    else
        table.insert(midi_table,pos,message)
        table.insert(midi_table,pos+1,holder)
    end
end

---Use to delete elements that existed previusly, without needing to change any offset. Can also use SetMIDIUnsorted with a '' (empty string) at the midi_msg value. Can insert it a table as last position or change some element to placeholder(that will get deleted) in the list. If going to change put the pos of the element and dont put offset and offset_count
---@param midi_table new midi table to insert this event
---@param offset number offset from last message
---@param offset_count number optional total offset
---@param pos number optional position in the new list to be changed to a place holder.
function InsertPlaceHolder(midi_table,offset,offset_count,pos)
    if pos then
        offset = midi_table[pos].offset
        offset_count = midi_table[pos].offset_count
    end
    pos = pos or (#midi_table+1)
    local holder = {offset = offset ,msg = '', flags = 0, offset_count = offset_count}
    midi_table[#midi_table+1] = holder
end

---------------------
----------------- MIDI Table Handling
---------------------

---This function get the packed midi_table(.msg and .flags are already packed) and return it to string packed formated to be feeded at MIDI_SetAllEvts
---@param midi_table table midi_table packed
---@return string
function PackPackedMIDITable(midi_table)
    local packed_table = {}
    for i, value in pairs(midi_table) do
        packed_table[#packed_table+1] = string.pack("i4Bs4", midi_table[i].offset, midi_table[i].flags, midi_table[i].msg)
    end
    return table.concat(packed_table) -- I didnt remove the last val at CreateMIDITable so everything should be here! If remove add it here, calculating offset.
end

--------------------
---------------- META Messages
--------------------

---For CC Meta-messages Gets all the midi text message like 'CCBZ  \�B�' and returns the bezier type and the tension.
---@param text string all midi text, as returned by UnpackMIDIMessage
---@return number bezier_type normally 0
---@return number tension float
function UnpackCCBZ(text)
    local bezier_type = text:sub(6,6):byte()
    local tension = string.unpack('f', text:sub(7,10))

    return bezier_type, tension
end

---------------------
----------------- Tables
---------------------

---Check for indexes inside a table. ex: TableCheckValues(t, 1) checks if t[1]. TableCheckValues(t, 2,3,5) checks if t[2][3][5]. This function dont throw any erros. Like if you try to t[2][3][5] but t[2] or t[2][3] isnt a table, it will throw an  error.
---@param t table
---@param ... any numbers or strings indexes to check.
---@return any return nil if it cant get the value. return the value if it can get to it
function TableCheckValues(t, ...) -- Made by CF
    for i = 1, select('#', ...) do -- Loop though all the arguments
        if type(t) ~= 'table' then return  end
        t = t[select(i, ...)] -- select(i, ...) will get the next value in the vararg list. (this function actually returns many values (from i to #...) but inside the [] of a table it will only get the first one )  array = array[select(i, ...)] will change array to be that new value
    end
    return t
end

---Insert a value in a table, can contain a inner table that didnt exist previouslly. like TableInsert(t, 1, 2, 3)
---@param t any
---@param ... any
function TableInsert(t, ...)
    local n = select('#', ...)
    for i = 1, n - 2 do
        local k = select(i, ...)
        local v = t[k]
        if type(v) ~= 'table' then
            assert(not v)
            v = {}
            t[k] = v
        end
        t = v
    end
    t[select(n - 1, ...)] = select(n, ...)
end

local proj = 0

reaper.Undo_BeginBlock2(proj)

local cur_pos = reaper.GetCursorPosition()
local midi_editor = reaper.MIDIEditor_GetActive()
for take in enumMIDITakes(midi_editor, true) do
    local cur_pos_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, cur_pos)
    cur_pos_ppq = math.floor(cur_pos_ppq+0.5)
    cur_pos_ppq = cur_pos_ppq >= 0 and cur_pos_ppq or 0
    local retval, midi_str = reaper.MIDI_GetAllEvts(take)
    local new_midi = {}
    local notes = {}
    --[[
        notes:
            ch*:
                pitch*: true
    ]]
    for offset, offset_count, flags, msg, stringPos in IterateAllMIDI(midi_str, false) do
        local was_added = false
        if set_start then
            if cur_pos_ppq < offset_count then
                local msg_type,msg_ch,val1,val2,text = UnpackMIDIMessage(msg)
                local selected = UnpackFlags(flags)
                if selected and msg_type == 9 and val2 ~= 0 then
                    SetMIDIUnsorted(new_midi, cur_pos_ppq, offset_count, msg, flags) -- Insert the note with the new position
                    TableInsert(notes,msg_ch,val1,true) -- For managing Meta messages
                    was_added = true
                elseif msg_type == 15 and msg_ch == 16 and text:match('^NOTE ') then
                    local ch, pitch = text:match('^NOTE (%d+) (%d+)')
                    ch, pitch = tonumber(ch) + 1, tonumber(pitch)
                    if TableCheckValues(notes,ch,pitch) then
                        SetMIDIUnsorted(new_midi, cur_pos_ppq, offset_count, msg, flags) -- Insert the note with the new position
                        was_added = true
                    end
                end
            end
        end

        -- if set_end then
        --     if cur_pos_ppq > offset_count then
        --         local msg_type,msg_ch,val1,val2,text = UnpackMIDIMessage(msg)
        --         local selected = UnpackFlags(flags)
        --         if (selected) and ((msg_type == 8) or (msg_type == 9 and val2 == 0)) then
        --             SetMIDIUnsorted(new_midi, cur_pos_ppq, offset_count, msg, flags) -- Insert the note with the new position
        --             was_added = true
        --         end
        --     end
        -- end
        --
        if not was_added then
            PutMIDI(new_midi,offset,offset_count,flags,msg)
        end
    end

    new_midi = PackPackedMIDITable(new_midi)
    reaper.MIDI_SetAllEvts(take, new_midi)
    reaper.MIDI_Sort(take)
end

reaper.Undo_EndBlock2(proj, 'Selected Notes to Cursor editor', -1)
reaper.UpdateArrange()

