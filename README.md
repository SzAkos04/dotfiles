# dotfiles

Personal macOS dotfiles: Alacritty, tmux, Neovim, Zsh (Starship + zinit), git, gh, clangd, fastfetch.
All configs use a consistent Catppuccin-Mocha-style palette.

## Quick start

```bash
git clone https://github.com/SzAkos04/dotfiles.git
cd dotfiles
./install.sh
```

You'll get an interactive checklist — pick whichever packages you want, and the
script does the rest:

- installs missing Homebrew dependencies for each package you chose
- backs up any file it would overwrite to `~/.dotfiles-backup/<timestamp>/`
- symlinks the configs into place (edit the files in this repo afterwards
  and your changes apply immediately — nothing gets copied)
- for `tmux`: installs the plugin manager (TPM) and session-persistence plugins
- for `git`: prompts for your name/email so commits aren't attributed to me

Other ways to run it:

```bash
./install.sh --all         # install everything, no prompts
./install.sh --list        # show packages and what they do
./install.sh --uninstall   # remove the symlinks this script created
```

## Packages

| Package     | What it configures                                               |
|-------------|-------------------------------------------------------------------|
| `alacritty` | GPU-accelerated terminal: font, transparency, colors               |
| `clangd`    | C/C++ language server settings                                    |
| `fastfetch` | System info banner shown at the start of every shell session      |
| `gh`        | GitHub CLI defaults                                                |
| `git`       | Global `.gitconfig` (name/email set by the installer)              |
| `nvim`      | LSP, Telescope, Treesitter, statusline, dashboard, autoformatting  |
| `tmux`      | Vi-mode copy, seamless nvim-pane navigation, session persistence   |
| `zsh`       | Starship prompt, zinit plugins, fzf, eza/bat/zoxide aliases        |

## Highlights

**Shell (zsh):** Starship prompt with a plain-prompt fallback if it isn't
installed yet, fzf-tab completion, autosuggestions, syntax highlighting,
history substring search, and a handful of functions (`fe` fuzzy-open a file,
`fkill` fuzzy-kill a process, `fcd` zoxide + fzf directory jump, `glog` fzf git log).

**tmux:** vi-style copy mode, `Ctrl-h/j/k/l` moves seamlessly between tmux
panes and Neovim splits, and (new) automatic session save/restore via
tmux-resurrect + tmux-continuum — close your terminal, reopen tomorrow, same
panes and layout. The status bar now shows a `PREFIX` badge while you're mid
key-chord and a `ZOOM` badge when a pane is zoomed, so you always know what
state tmux is in.

**Neovim:** LSP (clangd, lua_ls, rust_analyzer) via mason, Telescope, Trouble,
which-key, format-on-save, and a dashboard on startup.

## Requirements

- macOS with [Homebrew](https://brew.sh) (the installer will offer to install it if missing)
- A [Nerd Font](https://www.nerdfonts.com) for the icons in Alacritty/Starship/eza to render correctly

## Uninstalling

```bash
./install.sh --uninstall
```

This only removes symlinks that point back into this repo — anything that
was backed up during install stays untouched in `~/.dotfiles-backup/`.
