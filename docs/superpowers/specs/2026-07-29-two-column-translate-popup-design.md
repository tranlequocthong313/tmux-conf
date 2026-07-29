# Two-column Translate Shell popup

## Goal

Replace the transient tmux status-message translation preview with a persistent, Pantran-like view for text selected from w3m.

## User flow

1. In tmux copy-mode, select text with `v` and press `T`.
2. Translate Shell translates the selection from an inferred source language to Vietnamese.
3. A tmux popup opens at 70% width and 60% height.
4. Neovim presents the original text on the left and the translation on the right.
5. Scrolls are synchronized; `q` or `Esc` closes the popup.

The full translation is also copied to the macOS clipboard.

## Implementation

- Keep the `copy-mode-vi T` tmux binding.
- Change the selection helper to write source and translated text to a private temporary directory, copy the translation with `pbcopy`, then open a tmux popup.
- Add a viewer helper that starts `nvim -u NONE` in the popup, opens the two temporary files in vertical splits, makes both panes read-only, and enables Neovim `scrollbind` in each pane.
- The viewer removes its temporary directory when Neovim exits.
- Use `display-popup -E` only for the viewer: it closes the popup after the user quits Neovim, rather than immediately after translation.

## Error handling

- Empty selections or translation failures leave the clipboard unchanged and show a short tmux status error.
- If the popup viewer cannot start, the helper reports the failure and removes the temporary directory.
- Translation text never appears in a shell command; it is passed through files to avoid quoting and injection issues.

## Verification

- Shell tests cover success, empty selection, failed translation, and temporary-file cleanup.
- A temporary tmux server confirms the copy-mode binding.
- A headless Neovim command validates the viewer setup commands and scrollbind configuration.
