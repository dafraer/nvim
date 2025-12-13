
local M = {} -- Create a module table so we can expose a setup() function.

local function notify(msg, level) -- Small helper to show messages to you.
  vim.notify(msg, level or vim.log.levels.INFO) -- Use Neovim's built-in notification system.
end -- End notify().

local function is_go_buffer(bufnr) -- Check whether a buffer is a Go file.
  if not vim.api.nvim_buf_is_valid(bufnr) then -- If the buffer handle is invalid...
    return false -- ...it's not usable.
  end -- End validity check.
  if vim.bo[bufnr].filetype == "go" then -- If Neovim detected Go filetype...
    return true -- ...treat it as Go.
  end -- End filetype check.
  local name = vim.api.nvim_buf_get_name(bufnr) -- Get the full path of the file behind this buffer.
  return name:sub(-3) == ".go" -- Fallback: treat it as Go if it ends with ".go".
end -- End is_go_buffer().

local function gofmt_buffer(bufnr) -- Run gofmt on the current buffer content.
  if not is_go_buffer(bufnr) then -- If it's not a Go buffer...
    return -- ...do nothing.
  end -- End Go buffer check.

  if vim.fn.executable("gofmt") ~= 1 then -- If "gofmt" is not available in PATH...
    notify("gofmt_on_save: gofmt not found in PATH", vim.log.levels.WARN) -- Warn you.
    return -- And stop.
  end -- End executable check.

  local view = vim.fn.winsaveview() -- Save cursor/scroll position so formatting doesn't jump you around.
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) -- Read all buffer lines.
  local input = table.concat(lines, "\n") .. "\n" -- Join with newlines and ensure trailing newline for gofmt.

  local output = vim.fn.systemlist({ "gofmt" }, input) -- Run: gofmt (stdin = input), capture output as list of lines.
  local err = vim.v.shell_error -- Read the shell exit code from the last system/systemlist call.

  if err ~= 0 then -- If gofmt failed...
    local msg = table.concat(output, "\n") -- gofmt usually prints errors to stderr; Neovim may surface it here.
    if msg == "" then msg = "unknown error" end -- Fallback in case no message came through.
    notify("gofmt_on_save: gofmt failed:\n" .. msg, vim.log.levels.ERROR) -- Show the error.
    vim.fn.winrestview(view) -- Restore your view even on failure.
    return -- Don't change the buffer.
  end -- End error handling.

  -- Only update the buffer if formatting actually changed something.
  local changed = (#output ~= #lines) -- Quick check: different line count implies change.
  if not changed then -- If line counts match...
    for i = 1, #lines do -- Compare line-by-line.
      if output[i] ~= lines[i] then -- If any line differs...
        changed = true -- Mark as changed.
        break -- Stop comparing early.
      end -- End diff check.
    end -- End loop.
  end -- End compare.

  if changed then -- If gofmt produced different content...
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output) -- Replace entire buffer with formatted output.
  end -- End apply changes.

  vim.fn.winrestview(view) -- Restore cursor/scroll position after formatting.
end -- End gofmt_buffer().

function M.setup() -- Public setup function: sets up the auto-command.
  local group = vim.api.nvim_create_augroup("GofmtOnSave", { clear = true }) -- Create/replace an augroup to avoid duplicates.

  vim.api.nvim_create_autocmd("BufWritePre", { -- Create an autocmd that runs *before* the file is written.
    group = group, -- Put it in our augroup.
    pattern = "*.go", -- Only trigger for filenames ending in .go.
    callback = function(args) -- Neovim calls this Lua function on each matching save.
      gofmt_buffer(args.buf) -- Format the buffer that is being saved.
    end, -- End callback.
    desc = "Run gofmt on Go files before saving", -- Human-readable description (shows up in :autocmd).
  }) -- End autocmd.
end -- End setup().

return M -- Return the module so require("gofmt_on_save") works.
