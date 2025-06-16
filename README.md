# rambo.nvim

**insert mode with no mercy.**

_A Neovim plugin that supercharges Insert Mode with modern editing behavior._

![Alt text](https://i.imgur.com/w6gPgFJ.jpeg)

## Vision

- **Normal Mode**: stays pure, maintain your Vim proficiency and benefit from its full power. Use hjkl + Vim's keybindings.
- **Insert Mode**: becomes fluid, intuitive, and modern (like Sublime Text, Notepad++, or other contemporary editors). Use `← ↓ ↑ →` , `Ctrl` for jumps, `Shift` for selections, plus *motion helpers* like `Home`, `End`, `PageUp`, `PageDown`.

The idea isn't to replace Normal Mode, but to **elevate Insert Mode**, making it ideal for lightweight, quick and (maybe not so) dirty edits without leaving insert mode.

## Why this approach?

- Normal Mode is where Vim shines — efficient, modal, powerful. Overloading it with arrow keys or modern behavior is a waste of potential. Insert Mode, in contrast, is underpowered: one is often forced to leave it to do also basic things in normal mode.
- For most non-vim users these days selecting with Shift+motion is natural; also the behavior of Select mode feel natural. So this plugin could serve also as a gentle bridge to bring more people into Vim by offering a modern editing experience.
- Friendly even for non-coding workflows — from quick text edits to note-taking.
- without violating the Vim philosophy.
- Rambo is based on keys always available also on not US keyboards.

## Features

**Outside Insert Mode, everything behaves as expected.**  
**Inside Insert Mode, you get enhanced, modern editing capabilities:**

- **Text selection** using `Shift + Arrow Keys`.
- When a selection is active, **typing replaces the selection** — *without modifying Vim registers*.
- **Fast cursor movement** with `Ctrl + Arrow Keys`. Note: it relies on what set in `vim.opt.iskeyword`.
- **Word-wise selection** with `Ctrl + Shift + Arrow Keys`.
- Full support for `Home`, `End`, `Page Up`, and `Page Down`.
  `Ctrl + Home` jumps to the beginning of the file, `Ctrl + End` to the end.
- **Clipboard integration**: `Ctrl + C`, `Ctrl + V`, and `Ctrl + X` for copy, paste, and cut — fully compatible with the **system clipboard**.
- **Wrapping utilities**: after selecting text, press `)` to wrap it in parentheses — **selection remains active**, allowing for rapid repeated operations.
- **Search navigation** with `F2` and `F3`. Press `F4` to exit highlight mode (if enabled).
- `Ctrl + F` opens the search prompt. If text is selected, it is used as the search query.
- **Undo/Redo** with `Ctrl + Z` and `Ctrl + Y`. Note: it's reccomanded to set undo breakpoints in insert mode.
- **Move lines up/down** with `Alt + ↑ / ↓`. Works on single or multiple selected lines.
- While selecting one or more lines, use `Tab` and `Shift + Tab` to **indent or dedent**.
