# Incselect for Neovim

Incselect lets you incrementally select tree-sitter nodes.

> If you've come here in search of something that will bring back the original `incremental_selection` module of [nvim-treesitter:master](https://github.com/nvim-treesitter/nvim-treesitter/tree/master), consider [treesitter-modules.nvim](https://github.com/MeanderingProgrammer/treesitter-modules.nvim).

## Setup

There is no `setup()` function, as there are no configuration options for now. Just install the plugin and set your preferred keymaps (no defaults).

```lua
vim.keymap.set("n", "<CR>", require("incselect").init)
vim.keymap.set("x", "<CR>", require("incselect").parent)
vim.keymap.set("x", "<S-CR>", require("incselect").child)
vim.keymap.set("x", "<Tab>", require("incselect").next)
vim.keymap.set("x", "<S-Tab>", require("incselect").prev)
vim.keymap.set("x", "<M-CR>", require("incselect").undo)
```

Mind that not all terminals support modifiers for `<CR>` and other keys.

## Usage

All functions in this section return a boolean result, which means you could fall back to other editor capabilities when the function fails to select (no parser available, no valid node found, etc).

You could fall back to regular `<CR>`:

```lua
vim.keymap.set("n", "<CR>", function()
  if not require("incselect").init() then
    vim.cmd("normal! j_")
  end
end)
```

Or select inside WORD:

```lua
vim.keymap.set("n", "<CR>", function()
  if not require("incselect").init() then
    vim.cmd("normal! viW")
  end
end)
```

### init()

Selects node around cursor and clears history.

### parent()

If node is selected, selects its parent. Otherwise, selects node for range and clears history.

### child()

If node is selected, selects its first child. Otherwise, selects node for range and clears history.

If you need a quick way to access the last child, use:

```lua
vim.keymap.set("x", "<M-BS>", function()
  if require("incselect").child() then
      require("incselect").prev()
  end
end)
```

### next()

If node is selected, selects its next sibling. If on last sibling, selects first sibling. Otherwise, selects node for range and clears history.

### prev()

If node is selected, selects its previous sibling. If on first sibling, selects last sibling. Otherwise, selects node for range and clears history.

### undo()

If history has at least two nodes, selects previous node.
Otherwise, keeps current selection.

## Considerations

- Needs thorough testing.
- No goals to cover every possible use case.
