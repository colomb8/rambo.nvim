# rambo.nvim - insert mode with no mercy

A Neovim plugin that supercharges Insert Mode with modern editing behavior.
<p align="center"><img src="media/Rambo-1200x900.jpg" alt="insert mode with no mercy" width="300"/></p>

>Image used under fair use, for illustrative and non-commercial purposes. All rights to the character and image belong to their respective owners.

## Vision

- **Normal Mode**: Stay true to Vim, maintain your Vim proficiency and benefit from its full power. Use `hjkl` and all of Vim's native keybindings.
- **Insert Mode**: Becomes fluid, intuitive, and modern (like Sublime Text, Notepad++, or other contemporary editors). Use `← ↓ ↑ →` , `Ctrl` for jumps, `Shift` for selections, plus *motion helpers* like `Home`, `End`, `PageUp`, `PageDown`.
In addition, Rambo provides advanced moving features triggered with `Meta (Alt)`.

The idea isn't to replace Normal Mode, but to elevate Insert Mode - making it ideal for lightweight, quick and (perhaps not-so) dirty edits without ever leaving it.

<p align="center"><img src="media/lovethesekeys.jpg" alt="Love these keys..." width="200"/></p>

## Why this approach?

- Normal Mode is where Vim shines - efficient, modal, powerful. Overloading it with arrow keys or modern behavior is a waste of potential. Insert Mode, in contrast, is underpowered - users are often forced to exit it just to perform basic actions.
- For most non-vim users, selecting with `Shift` + motion is second nature. also the behavior of Select mode feel natural. Combined with the natural feel of Select Mode, this plugin offers a gentle bridge into Vim, making it more accessible to newcomers.
- Friendly even for non-coding workflows - ideal for quick edits, note-taking and general text manipulation.
- All this, without compromising Vim's philosophy.

**Outside Insert Mode, everything behaves as expected.**
**Inside Insert Mode, you get enhanced with modern editing capabilities:**

## Features

### Move Cursor

- **Fast cursor movement** with `Ctrl` + `←` and `→` (similar to Vim's `b` and `e` but enhanced) Notes: (1) it relies on what set in `vim.opt.iskeyword`; (2) The `Ctrl-Right` motion is available in two variants, depending on the configuration.
- **Jump between paragraphs** with `Ctrl` + `↓` and `↑` (same as vim's `{` and `}`).
### Select Text

- **Text selection** using `Shift` + `Arrow Keys`.
- When a selection is active, **typing replaces the selection** - as in any modern editor.
- **Word-wise selection** with `Ctrl` + `Shift` + `Arrow Keys`.
- Full support for `Home`, `End`, `Page Up`, and `Page Down`.
- `Ctrl` + `Home` jumps to the beginning of the file, `Ctrl` + `End` to the end. Obviously, they can combined with `Shift` for Select mode.
- `Ctrl` + `a` for select all.
- `Shift` + `space` for toggle Select <-> S-Line.

### Operations
- **Copy/Cut/Paste op.**: `Ctrl` + `C`, `Ctrl` + `V`, and `Ctrl` + `X` for copy, paste, and cut - fully compatible with the **system clipboard**. Note: these operations rely on a *internal register* which smartly interacts with Vim registers. For example, replacing selected text by typing new content does not affect the Rambo register.
- `Ctrl-s` for save current file.

### Wrapping
- **Wrapping utilities**: after selecting text, press a character like `)` to wrap it in parentheses — the **selection remains active**, allowing for quick chained operations. For example, pressing `)` followed by `"` results in `("ciao")`.

### Search text
- In insert mode, `Ctrl + F` opens the search prompt. If **text is selected**, it is used as the search query.
- Navigate results with `F3` and `F2`. Press `F4` to exit highlight mode (if enabled).

- **Undo/Redo** with `Ctrl + Z` and `Ctrl + Y`. Note: it's reccomanded to set undo breakpoints in insert mode for a better experience. See Tips in README or documentation.

### Moving Text
- **Move lines up/down** with `Alt + ↑ / ↓`. Works on single or multiple selected lines.
- While selecting one or more lines, use `Tab` and `Shift` + `Tab` to **indent or dedent**.
- `Insert` key allows to quickly switch between Select and Visual mode (it is also handy to enter insert mode when in normal).
- `Meta (Alt)` + `Shift` + `↑ / ↓` for scroll window.

## Installation and Configuration

Using [**lazy.nvim**](https://github.com/folke/lazy.nvim):

```lua
{
  "colomb8/rambo.nvim",
  config = function()
    require("rambo").setup({
      -- c_right_mode = 'bow', -- 'bow' or 'eow'
      -- op_prefix = '', -- '' or '<C-q>' or '<C-g>'
      -- hl_select_spec = { -- hl_spec or false
      --   bg = '#732BF5', -- Neon Violet
      -- },
    })
  end,
},
```

>setup() is required - call it without arguments to use the default behavior.

Configuration:
- `c_right_mode`: controls how the `C-Right` motion behaves. With `bow` the cursor jumps to the begining of next word. With `eow` the cursor jumps to the end of next word. Default is `bow`.
- `op_prefix`: it specifies a prefix for operations like Copy, Cut, Paste, Save, etc. As an example, if `op_prefix` is empty string, user can copy selection with `<C-c>`; if otherwise `op_prefix` is `<C-q>`, the operation of copy is achieved with `<C-q>c`. Default is empty string.
- `hl_select_spec`: it specifies a formatting for selected area; default is `#732BF5` (Neon Violet).

## Tips

- For a better experience in using undo/redo in Rambo, set undo breakpoints in insert mode with:

```lua
for _, char in ipairs({ "<CR>", ",", ".", ";", " " }) do
  vim.keymap.set("i", char, char .. "<C-g>u")
end
```

## Roadmap

- `:help` Vim documentation – provide Vim help file (`:help rambo`) for discoverability.
- Full unicode support – extend compatibility beyond ASCII for smooth editing also in international contexts.
- Simple multicursor support – implement basic but handy multicursor editing.
- Home, End, Up, Down should support line wrap.

## License

[MIT](LICENSE)
