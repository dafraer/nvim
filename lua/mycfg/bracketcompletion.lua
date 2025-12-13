
local M = {} -- Module table so you can require() this file.

local asymmetric = { -- Pairs where opening and closing chars are different.
  ["("] = ")", -- Round brackets.
  ["["] = "]", -- Square brackets.
  ["{"] = "}", -- Curly brackets.
} -- End asymmetric table.

local symmetric = { -- Pairs where opening and closing chars are the same.
  ['"'] = '"', -- Double quotes.
  ["'"] = "'", -- Single quotes.
  ["`"] = "`", -- Backticks.
} -- End symmetric table.

local function cursor_neighbors() -- Returns the char before and after the cursor.
  local pos = vim.api.nvim_win_get_cursor(0) -- Get cursor position: {row, col}.
  local col = pos[2] -- Column is 0-based.
  local line = vim.api.nvim_get_current_line() -- Current line as a Lua string.
  local prev = (col > 0) and line:sub(col, col) or "" -- Char before cursor (Lua is 1-based).
  local next = line:sub(col + 1, col + 1) -- Char after cursor.
  return prev, next -- Give both back to the caller.
end -- End cursor_neighbors().

local function imap_expr(lhs, rhs_fn) -- Helper to make a safe insert-mode expr mapping.
  vim.keymap.set("i", lhs, rhs_fn, { -- Create insert-mode mapping.
    expr = true, -- Use the function's return value as keys to feed.
    replace_keycodes = true, -- Convert "<Left>", "<BS>", etc. in that returned string. :contentReference[oaicite:1]{index=1}
    noremap = true, -- Don't allow recursive remaps.
    silent = true, -- Don't echo mapping output.
  }) -- End mapping options.
end -- End imap_expr().

local function map_open(open, close) -- Map an opening bracket to insert the pair.
  imap_expr(open, function() -- When user types the opening char...
    return open .. close .. "<Left>" -- Insert both, then move cursor between them.
  end) -- End mapping.
end -- End map_open().

local function map_close(close) -- Map a closing bracket to "skip" if it's already there.
  imap_expr(close, function() -- When user types the closing char...
    local _, next = cursor_neighbors() -- Look at the character after the cursor.
    if next == close then -- If the next char is already the same closing bracket...
      return "<Right>" -- Move over it instead of inserting another one.
    end -- End if.
    return close -- Otherwise insert it normally.
  end) -- End mapping.
end -- End map_close().

local function map_symmetric(ch) -- Map quotes/backticks (same open/close).
  imap_expr(ch, function() -- When user types the quote char...
    local _, next = cursor_neighbors() -- Check the char after the cursor.
    if next == ch then -- If the next char is already the same quote...
      return "<Right>" -- Skip over it.
    end -- End if.
    return ch .. ch .. "<Left>" -- Otherwise insert a pair and move into the middle.
  end) -- End mapping.
end -- End map_symmetric().

local function map_backspace() -- Make Backspace delete both sides when between an empty pair.
  imap_expr("<BS>", function() -- Intercept backspace in insert mode.
    local prev, next = cursor_neighbors() -- Read chars around the cursor.
    for open, close in pairs(asymmetric) do -- Check (), [], {} cases.
      if prev == open and next == close then -- If cursor is exactly between an empty pair...
        return "<BS><Del>" -- Delete left char (BS) then right char (Del).
      end -- End if.
    end -- End loop.
    for ch, _ in pairs(symmetric) do -- Check "", '', `` cases.
      if prev == ch and next == ch then -- If between two identical quotes...
        return "<BS><Del>" -- Delete both.
      end -- End if.
    end -- End loop.
    return "<BS>" -- Default: normal backspace.
  end) -- End mapping.
end -- End map_backspace().

function M.setup() -- Public setup function.
  for open, close in pairs(asymmetric) do -- For (), [], {}...
    map_open(open, close) -- Opening inserts the pair.
    map_close(close) -- Closing skips if already present.
  end -- End loop.
  for ch, _ in pairs(symmetric) do -- For quotes/backticks...
    map_symmetric(ch) -- Insert pair or skip.
  end -- End loop.
  map_backspace() -- Enable smart deletion.
end -- End setup().

return M -- Return the module.
