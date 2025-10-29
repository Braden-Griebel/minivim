-- Configure Neovim Builtin Options

-- General Settings ----------------------------------------------

-- Map leader keys (used as <leader> in keybinds)
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Enable mouse
vim.o.mouse = "a"
-- Change how many lines the mouse scrolls
vim.o.mousescroll = "ver:25,hor:6"
-- Change buffer switching behavior
-- This option uses already opened tabs when jumping (for e.g. quickfix)
vim.o.switchbuf = "usetab"
-- Use a file to store undo information in a persistant way
vim.o.undofile = true

-- Limit ShaDa file
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h"

-- Enable all filetype plugins
vim.cmd("filetype plugin indent on")
if vim.fn.exists("syntax_on") ~= 1 then
  vim.cmd("syntax enable")
end

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- UI Settings ----------------------------------------------------
vim.o.breakindent = true                  -- Indent wrapped lines to match line start
vim.o.breakindentopt = "list:-1"          -- Add padding for lists (if 'wrap' is set)
vim.o.colorcolumn = "+1"                  -- Draw column on the right of maximum width
vim.o.cursorline = true                   -- Enable current line highlighting
vim.o.linebreak = true                    -- Wrap lines at 'breakat' (if 'wrap' is set)
vim.o.list = true                         -- Show helpful text indicators
vim.o.number = true                       -- Show line numbers
vim.o.pumheight = 10                      -- Make popup menu smaller
vim.o.ruler = false                       -- Don't show cursor coordinates
vim.o.shortmess = "CFOSWaco"              -- Disable some built-in completion messages
vim.o.showmode = false                    -- Don't show mode in command line
vim.o.signcolumn = "yes"                  -- Always show signcolumn (less flicker)
vim.o.splitbelow = true                   -- Horizontal splits will be below
vim.o.splitkeep = "screen"                -- Reduce scroll during window split
vim.o.splitright = true                   -- Vertical splits will be to the right
vim.o.winborder = "single"                -- Use border in floating windows
vim.o.wrap = false                        -- Don't visually wrap lines (toggle with \w)

vim.o.cursorlineopt = "screenline,number" -- Show cursor line per screen line

-- Special UI symbols. More is set via 'mini.basics' later.
vim.o.fillchars = "eob: ,fold:╌"
vim.o.listchars = "extends:…,nbsp:␣,precedes:…,tab:> "

-- Editing --------------------------------------------------------
vim.o.autoindent = true                 -- Use auto indent
vim.o.expandtab = true                  -- Convert tabs to spaces
vim.o.formatoptions = "rqnl1j"          -- Improve comment editing
vim.o.ignorecase = true                 -- Ignore case during search
vim.o.incsearch = true                  -- Show search matches while typing
vim.o.infercase = true                  -- Infer case in built-in completion
vim.o.shiftwidth = 2                    -- Use this number of spaces for indentation
vim.o.smartcase = true                  -- Respect case if search pattern has upper case
vim.o.smartindent = true                -- Make indenting smart
vim.o.spelloptions = "camel"            -- Treat camelCase word parts as separate words
vim.o.tabstop = 2                       -- Show tab as this number of spaces
vim.o.virtualedit = "block"             -- Allow going past end of line in blockwise mode
-- TODO: Maybe change this ↓
vim.o.iskeyword = "@,48-57,_,192-255,-" -- Treat dash as `word` textobject part

-- Pattern for start of numbered list
vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]

-- Built-in completion
vim.o.complete = ".,w,b,kspell"                     -- Use less sources
vim.o.completeopt = "menuone,noselect,fuzzy,nosort" -- Use custom behavior

-- Autocommands ---------------------------------------------------

-- Don't auto-wrap comments and don't insert comment leader after hitting 'o'.
-- Do on `FileType` to always override these changes from filetype plugins.
local f = function()
  vim.cmd("setlocal formatoptions-=c formatoptions-=o")
end
_G.Config.new_autocmd("FileType", nil, f, "Proper 'formatoptions'")

-- Diagnostics ----------------------------------------------------
local diagnostic_opts = {
  -- Show signs on top of any other sign, but only for warnings and errors
  signs = { priority = 9999, severity = { min = "WARN", max = "ERROR" } },

  -- Show all diagnostics as underline (for their messages type `<Leader>ld`)
  underline = { severity = { min = "HINT", max = "ERROR" } },

  -- Show more details immediately for errors on the current line
  virtual_lines = false,
  virtual_text = {
    current_line = true,
    severity = { min = "ERROR", max = "ERROR" },
  },

  -- Don't update diagnostics when typing
  update_in_insert = false,
}

-- Use `later()` to avoid sourcing `vim.diagnostic` on startup
MiniDeps.later(function()
  vim.diagnostic.config(diagnostic_opts)
end)
