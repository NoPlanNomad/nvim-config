-- [[ Setting options ]]
-- See `:help vim.o` or `:help vim.opt`
-- See `:help option-list` for more options
-- NOTE: You can cnange these options as you wish!

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.o.number = true
-- Enable relative numbers
vim.o.relativenumber = true

-- Wrap lines by default
vim.o.wrap = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Hide the mode for it is in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
-- See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C ore search contains capital
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
-- Display which-key popup sooner
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
-- See `:help 'list'`
-- See `:help 'listchars'`
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screenlines to keep above and below the cursor.
vim.o.scrolloff = 10

-- Set completeopt to have a better completetion experience
vim.o.completeopt = "menuone,noselect"

-- NOTE: You should make sure your terminal suports this
vim.o.termguicolors = true
