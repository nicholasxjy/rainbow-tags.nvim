# rainbow-tags.nvim

Fast rainbow highlights for JSX/TSX tag names in Neovim.

`rainbow-tags.nvim` uses Tree-sitter and ephemeral extmarks to highlight JSX
tag names such as `<Helloworld />` and `<Tag />` in `typescriptreact` buffers.
It renders only the visible window range, so it stays light even in large TSX
files.

## Requirements

- Neovim 0.10+
- `nvim-treesitter` TSX parser, or any setup that provides Neovim's `tsx`
  Tree-sitter parser

## Installation

With `lazy.nvim`:

```lua
{
  "your-name/rainbow-tags.nvim",
  opts = {
    highlight_groups = {
      "RainbowDelimiterRed",
      "RainbowDelimiterCyan",
      "RainbowDelimiterYellow",
      "RainbowDelimiterGreen",
      "RainbowDelimiterOrange",
      "RainbowDelimiterViolet",
      "RainbowDelimiterBlue",
    },
  },
}
```

## Configuration

```lua
require("rainbow-tags").setup({
  enabled = true,
  filetypes = { "typescriptreact", "javascriptreact", "tsx" },
  lang = "tsx",
  include_intrinsic = true,
  strategy = "name",
  create_default_highlights = true,
  highlight_groups = {
    "RainbowDelimiterRed",
    "RainbowDelimiterCyan",
    "RainbowDelimiterYellow",
    "RainbowDelimiterGreen",
    "RainbowDelimiterOrange",
    "RainbowDelimiterViolet",
    "RainbowDelimiterBlue",
  },
})
```

Options:

- `highlight_groups`: Highlight groups used for the rainbow colors.
- `strategy`: `"name"` keeps a tag name on a stable color. `"sequence"` cycles
  through groups in visible order.
- `include_intrinsic`: Set to `false` to skip lowercase HTML-like tags such as
  `<div />` and highlight only custom components such as `<Tag />`.
- `create_default_highlights`: Set to `false` if your colorscheme or another
  plugin already defines the configured groups.

Example custom groups:

```lua
vim.api.nvim_set_hl(0, "MyTagRed", { fg = "#ff6b6b", bold = true })
vim.api.nvim_set_hl(0, "MyTagBlue", { fg = "#4dabf7", bold = true })

require("rainbow-tags").setup({
  highlight_groups = { "MyTagRed", "MyTagBlue" },
})
```

## Commands

- `:RainbowTagsEnable [bufnr]`
- `:RainbowTagsDisable [bufnr]`
- `:RainbowTagsToggle [bufnr]`

## Disabling Auto Setup

The plugin calls `setup({})` automatically so it works out of the box. To fully
control setup timing:

```lua
vim.g.rainbow_tags_disable_auto_setup = 1
require("rainbow-tags").setup({ ... })
```
