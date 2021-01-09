-- FXSYN

local new_name, old_name

-- PRE
if prev_fx == PRE then -- # # # # # # # # # # # # # #

  if prev_pre_fx_count <= NEW_PRE_FX_COUNT then -- :::::::::::::::::::::::::::
    -- WITHIN >>> insert at last neww rs prev idx
    if new_pre_fx_name ~= prev_pre_fx_name then
      -- RS name missmatch > replaceFxAtIndex()
    end
    if prev_pre_fx_count < NEW_PRE_FX_COUNT then
      -- insertFxAtIndex() after existing
    end
  end

  -- do this in MID_FX ??
  -- if NEW_PRE_FX_COUNT < prev_pre_fx_count then -- ::::::::::::::::::::::::::::
  --   -- EXCESSIVE >>> rm overflow
  --   removeFxAtIndex(prev_fx_idx)
  -- end

end



if prev_fx == PRE and prev_pre_fx_count < new_pre_fx_count then
  -- less >>> need to insert
  insertFxAtIndex()

end



-- MID
if prev_fx == MID then end
-- POST
if prev_fx == POST then end -- rm overflow
