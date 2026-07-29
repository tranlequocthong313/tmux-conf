local temp_dir = vim.fn.tempname()
assert(vim.fn.mkdir(temp_dir, "p") == 1)

local source_file = temp_dir .. "/source.txt"
local translation_file = temp_dir .. "/translation.txt"
local source_lines = {}
local translation_lines = {}

for line = 1, 50 do
  source_lines[line] = "Source line " .. line
  translation_lines[line] = "Vietnamese line " .. line
end

vim.fn.writefile(source_lines, source_file)
vim.fn.writefile(translation_lines, translation_file)
vim.env.TMUX_TRANSLATE_SOURCE = source_file
vim.env.TMUX_TRANSLATE_TRANSLATION = translation_file

dofile("/Users/thong/.local/bin/tmux-translate-viewer.lua")

local windows = vim.api.nvim_tabpage_list_wins(0)
assert(#windows == 2, "viewer must use exactly two panes")

local original_win
local vietnamese_win

for _, win in ipairs(windows) do
  if vim.wo[win].winbar == " Original " then
    original_win = win
  elseif vim.wo[win].winbar == " Vietnamese " then
    vietnamese_win = win
  end
end

assert(original_win, "viewer must label the original pane")
assert(vietnamese_win, "viewer must label the translation pane")
assert(
  vim.api.nvim_win_get_position(original_win)[2] < vim.api.nvim_win_get_position(vietnamese_win)[2],
  "viewer must place the original pane on the left"
)
assert(vim.wo[original_win].scrollbind, "original pane must be scrollbound")
assert(vim.wo[vietnamese_win].scrollbind, "translation pane must be scrollbound")

for _, win in ipairs(windows) do
  local buffer = vim.api.nvim_win_get_buf(win)
  assert(vim.bo[buffer].readonly, "translation panes must be read-only")
  assert(not vim.bo[buffer].modifiable, "translation panes must be non-modifiable")
  assert(vim.wo[win].wrap, "translation panes must wrap long text")
  assert(vim.wo[win].linebreak, "translation panes must wrap at word boundaries")
end

local vietnamese_buffer = vim.api.nvim_win_get_buf(vietnamese_win)
translation_lines[1] = "Translation completed"
vim.fn.writefile(translation_lines, translation_file)
assert(
  vim.wait(1000, function()
    return vim.api.nvim_buf_get_lines(vietnamese_buffer, 0, 1, false)[1] == "Translation completed"
  end, 10),
  "viewer must refresh the translation pane when the result arrives"
)

vim.api.nvim_set_current_win(original_win)
vim.cmd("normal! 30G")
assert(
  vim.api.nvim_win_call(original_win, function()
    return vim.fn.line("w0")
  end) == vim.api.nvim_win_call(vietnamese_win, function()
    return vim.fn.line("w0")
  end),
  "scrolling the original pane must synchronize the translation pane"
)

vim.fn.delete(temp_dir, "rf")
