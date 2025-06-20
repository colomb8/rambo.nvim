# rambo.nvim - insert mode with no mercy

A Neovim plugin that supercharges Insert Mode with modern editing behavior.
<p align="center"><img src="media/Rambo-1200x900.jpg" alt="insert mode with no mercy" width="300"/></p>

>Image used under fair use, for illustrative and non-commercial purposes. All rights to the character and image belong to their respective owners.

## Vision

- **Normal Mode**: Stay true to Vim, maintain your Vim proficiency and benefit from its full power. Use `hjkl` and all of Vim's native keybindings.
- **Insert Mode**: Becomes fluid, intuitive, and modern (like Sublime Text, Notepad++, or other contemporary editors). Use `← ↓ ↑ →` , `Ctrl` for jumps, `Shift` for selections, plus *motion helpers* like `Home`, `End`, `PageUp`, `PageDown`.

The idea isn't to replace Normal Mode, but to elevate Insert Mode - making it ideal for lightweight, quick and (perhaps not-so) dirty edits without ever leaving it.

<p align="center"><img src="media/lovethesekeys.jpg" alt="Love these keys..." width="200"/></p>

## Why this approach?

- Normal Mode is where Vim shines - efficient, modal, powerful. Overloading it with arrow keys or modern behavior is a waste of potential. Insert Mode, in contrast, is underpowered - users are often forced to exit it just to perform basic actions.
- For most non-vim users, selecting with `Shift` + motion is second nature. also the behavior of Select mode feel natural. Combined with the natural feel of Select Mode, this plugin offers a gentle bridge into Vim, making it more accessible to newcomers.
- Friendly even for non-coding workflows - ideal for quick edits, note-taking and general text manipulation.
- All this, without compromising Vim's philosophy.

## Features

**Outside Insert Mode, everything behaves as expected.**
**Inside Insert Mode, you get enhanced with modern editing capabilities:**

- **Text selection** using `Shift` + `Arrow Keys`.
- When a selection is active, **typing replaces the selection** - without modifying Vim registers.
- **Fast cursor movement** with `Ctrl` + `←` and `→` (similar to Vim's `b` and `e` but enhanced) Note: it relies on what set in `vim.opt.iskeyword`.
- **Jump between paragraphs** with `Ctrl` + `↓` and `↑` (same as vim's `{` and `}`).
- **Word-wise selection** with `Ctrl` + `Shift` + `Arrow Keys`.
- Full support for `Home`, `End`, `Page Up`, and `Page Down`.
  `Ctrl` + `Home` jumps to the beginning of the file, `Ctrl` + `End` to the end. Obviously, they can combined with `Shift` for Select mode.
- **Copy/Cut/Paste op.**: `Ctrl` + `C`, `Ctrl` + `V`, and `Ctrl` + `X` for copy, paste, and cut - fully compatible with the **system clipboard**. (*)
- **Wrapping utilities**: after selecting text, press e.g. `)` to wrap it in parentheses - **selection remains active**, allowing for rapid combined operations, i.e. `)` and then `"` does `("ciao")`.
- **Search navigation** with `F3` and `F2` (or `Shift-F3`). Press `F4` to exit highlight mode (if enabled).
- `Ctrl + F` opens the search prompt. If text is selected, it is used as the search query. (*)
- **Undo/Redo** with `Ctrl + Z` and `Ctrl + Y`. Note: it's reccomanded to set undo breakpoints in insert mode for a better experience. (*)
- **Move lines up/down** with `Alt Shift + ↑ / ↓`. Works on single or multiple selected lines.
- While selecting one or more lines, use `Tab` and `Shift` + `Tab` to **indent or dedent**.
- `Ctrl` + `a` for select all. (*)
- `Ctrl` + `l` for convert Select to S-Line. (*)
- `Insert` key allows to quickly switch between Select and Visual mode.
- `Meta (Alt)` + `↑ / ↓` for scroll window.

(*) Note: `Ctrl` can be replaced with `Meta (alt)` with `operations_key` setting.

## Tips

- Set undo breakpoints in insert mode with:

```lua
for _, char in ipairs({ ",", ".", ";", " " }) do
  vim.keymap.set("i", char, char .. "<C-g>u")
end
```

- Set different highlights to Visual vs Select mode with:

```lua
local bg_visual = '#004D8A'
local bg_select =  '#732BF5'
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:[vV\22]*",
  callback = function(args)
      vim.api.nvim_set_hl(0, 'Visual', {
        bg = bg_visual,
        -- fg = '#FFFFFF',
      })
  end
})
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:[sS\19]*",
  callback = function(args)
      vim.api.nvim_set_hl(0, 'Visual', {
        bg = bg_select,
        -- fg = '#FFFFFF',
      })
  end
})
```

## Installation and Config

Using [**lazy.nvim**](https://github.com/folke/lazy.nvim):

```lua
{
  "colomb8/rambo.nvim",
  config = function()
    require("rambo").setup({
      -- operations_key = 'C', -- 'C' or 'M'
    })
  end,
},
```

>setup() is required - call it without arguments to use the default behavior.

Configuration:
- `operations_key`: `C` for `Ctrl` or `M` for `Meta (Alt)`. It sets the key for Copy/Cut/Paste, Undo/Redo, Search, Select All and convert Select to S-Line. Default is `C`.

## Roadmap

- `:help` Vim documentation – provide Vim help file (`:help rambo`) for discoverability.
- Horizontal move when selection is on one line only (like matze/vim-move)
- In case of line wrap, Up/Down should follow virtual text (like `gj` and `gk`).
- Plugin custom configuration – allow users to customize some key mappings and behavior via `setup`.
- Unicode support – extend compatibility beyond ASCII for smooth editing also in international contexts.
- Simple multicursor support – implement basic but handy multicursor editing.

## License

[MIT](LICENSE)
