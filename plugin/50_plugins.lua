-- Make concise helpers for installing/adding plugins in two stages
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

-- Tree-sitter
now_if_args(function()
  add({
    source = "nvim-treesitter/nvim-treesitter",
    -- Use `main` branch since `master` branch is frozen, yet still default
    checkout = "main",
    -- Update tree-sitter parser after plugin is updated
    hooks = {
      post_checkout = function()
        vim.cmd("TSUpdate")
      end,
    },
  })
  add({
    source = "nvim-treesitter/nvim-treesitter-textobjects",
    -- Same logic as for 'nvim-treesitter'
    checkout = "main",
  })

  -- Define languages which will have parsers installed and auto enabled
  local languages = {
    -- These are already pre-installed with Neovim. Used as an example.
    "asm",
    "c",
    "cmake",
    "cpp",
    "css",
    "fish",
    "fortran",
    "git_config",
    "git_rebase",
    "gitattributes",
    "gitcommit",
    "gitignore",
    "gleam",
    "go",
    "haskell",
    "html",
    "ini",
    "java",
    "javadoc",
    "javascript",
    "json",
    "julia",
    "just",
    "kdl",
    "latex",
    "lua",
    "markdown",
    "meson",
    "nix",
    "ocaml",
    "pip_requirements",
    "python",
    "r",
    "rust",
    "sql",
    "sway",
    "typescript",
    "typst",
    "verilog",
    "vim",
    "vimdoc",
    "xml",
    "yaml",
    "zig",
  }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then
    require("nvim-treesitter").install(to_install)
  end

  -- Enable tree-sitter after opening a file for a target language
  local filetypes = {}
  for _, lang in ipairs(languages) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      table.insert(filetypes, ft)
    end
  end
  local ts_start = function(ev)
    vim.treesitter.start(ev.buf)
  end
  _G.Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
end)

-- Formatting =================================================================

later(function()
  add("stevearc/conform.nvim")

  require("conform").setup({
    notify_on_error = false,
    format_on_save = function(bufnr)
      local disable_filetypes = {} -- { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      else
        return {
          timeout_ms = 500,
          lsp_format = "fallback",
        }
      end
    end,
    formatters_by_ft = {
      lua = { "stylua" },
      cpp = { "clang-format" },
      bash = { "shfmt" },
      markdown = { "mdformat" },
      typst = { "typstyle" },
      nix = { "alejandra" },
    },
    formatters = {
      typstyle = {
        command = "typstyle",
        stdin = true,
        args = { "--wrap-text" },
      },
    },
  })
end)

-- Linting ====================================================================
later(
  function()
    add("mfussenegger/nvim-lint")

    require("lint").linters_by_ft = {
      markdown = { "markdownlint-cli2" },
      bash = { "shellcheck" },
      python = { "mypy" },
      javascript = { "oxlint", "eslint" },
      typscript = { "eslint" },
    }

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  end
)

-- Snippets ===================================================================

later(function()
  add("rafamadriz/friendly-snippets")
end)
