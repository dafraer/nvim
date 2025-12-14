
local M = {} -- Module table so you can require() this file.

local function notify(msg, level) -- Helper to show a message in Neovim.
  vim.notify(msg, level or vim.log.levels.INFO) -- Use Neovim's built-in notify().
end -- End notify().

local function is_go(bufnr) -- Returns true if this buffer is a Go file.
  if not vim.api.nvim_buf_is_valid(bufnr) then -- If buffer handle is invalid...
    return false -- ...stop.
  end -- End validity check.
  if vim.bo[bufnr].filetype == "go" then -- If Neovim detected filetype=go...
    return true -- ...it's Go.
  end -- End filetype check.
  local name = vim.api.nvim_buf_get_name(bufnr) -- Get full file path for this buffer.
  return name:sub(-3) == ".go" -- Fallback: treat it as Go if it ends with ".go".
end -- End is_go().

local function run_goimports(bufnr) -- Run goimports and replace buffer with formatted output.
  if not is_go(bufnr) then -- If not a Go buffer...
    return -- ...do nothing.
  end -- End Go check.

  local filename = vim.api.nvim_buf_get_name(bufnr) -- Get file path (used to compute srcdir).
  if filename == "" then -- If buffer has no name (like [No Name])...
    return -- ...skip (goimports works best with a real path).
  end -- End unnamed buffer check.

  if vim.fn.executable("goimports") ~= 1 then -- If goimports isn't in PATH...
    notify("goimports_on_save: goimports not found in PATH", vim.log.levels.WARN) -- Warn once.
    return -- And stop.
  end -- End executable check.

  local view = vim.fn.winsaveview() -- Save cursor/scroll position so formatting doesn't jump you.
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) -- Read entire buffer as list of lines.
  local input = table.concat(lines, "\n") .. "\n" -- Join lines and ensure trailing newline.

  local srcdir = vim.fn.fnamemodify(filename, ":p:h") -- Directory of the file (helps goimports resolve local imports).
  local cmd = { "goimports", "-srcdir", srcdir } -- Command to run (reads stdin, prints formatted code to stdout).

  local output = vim.fn.systemlist(cmd, input) -- Run goimports with stdin=input, capture stdout as list of lines.
  local code = vim.v.shell_error -- Exit code of the last system/systemlist call.

  if code ~= 0 then -- If goimports failed...
    local msg = table.concat(output, "\n") -- Try to show whatever came back as an error message.
    if msg == "" then msg = "unknown error" end -- Fallback if message is empty.
    notify("goimports_on_save: goimports failed:\n" .. msg, vim.log.levels.ERROR) -- Show the error.
    vim.fn.winrestview(view) -- Restore your view even on failure.
    return -- Do not change the buffer.
  end -- End error handling.

  local changed = (#output ~= #lines) -- Quick check: different line count => definitely changed.
  if not changed then -- If line counts are same...
    for i = 1, #lines do -- Compare line-by-line.
      if output[i] ~= lines[i] then -- If any line differs...
        changed = true -- Mark changed.
        break -- Stop early.
      end -- End diff check.
    end -- End loop.
  end -- End comparison.

  if changed then -- If formatting actually changed content...
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output) -- Replace whole buffer with goimports output.
  end -- End apply.

  vim.fn.winrestview(view) -- Restore cursor/scroll position.
end -- End run_goimports().

function M.setup() -- Public setup function you call from init.lua.
  local group = vim.api.nvim_create_augroup("GoImportsOnSave", { clear = true }) -- Create augroup (prevents duplicates).
  vim.api.nvim_create_autocmd("BufWritePre", { -- Run before saving the file to disk.
    group = group, -- Put autocmd into our augroup.
    pattern = "*.go", -- Trigger only for Go files by name.
    callback = function(args) -- Neovim calls this on save.
      run_goimports(args.buf) -- Format that buffer with goimports.
    end, -- End callback.
    desc = "Run goimports on Go files before saving", -- Description for :autocmd.
  }) -- End autocmd.
end -- End setup().

return M -- Return module table.
