# MiniVim

Neovim Config Based on Mini Plugin Suite

Based on the [MiniMax](https://github.com/nvim-mini/MiniMax) config from mini.nvim

## Installation

### Dependencies

Install needed dependencies:

- fd
- lazygit
- ripgrep

### Clone RPO

Simply clone into ~/.config/nvim

```bash
git clone https://github.com/Braden-Griebel/minivim.git ~/.config/nvim
```

Then open Neovim, running MasonToolsInstall should install
all needed LSPs/Formatters/Linters

## Languages

This config currently sets up LSPs/settings for

- C
- C++
- Go
- Lean
- Markdown
- Ocaml
- Python
- R
- Rust
- Typst

## Integrations

Tmux is the default terminal multiplexer used by this config.
Tmux-navigator is used to move between tmux panes, and
vim-slime defaults to using tmux as its target.
