# Translate selected w3m text with Translate Shell

## Goal

Translate text selected in a w3m tmux pane without opening a popup or extra pane.

## User flow

1. Enter tmux copy-mode with `Ctrl-A [`.
2. Start a selection with `v`, move to the end of a word, sentence, or paragraph.
3. Press `T` in copy-mode.
4. The selection is translated automatically from an inferred source language to Vietnamese.

For short text, tmux displays the first line of the translation in its status message. The complete translation replaces the macOS clipboard contents so it can be pasted anywhere. The existing `y` mapping remains unchanged and still copies the original selection.

## Implementation

- Add an executable helper at `~/.local/bin/tmux-translate-selection`.
- The helper reads the selected text from standard input, invokes `trans -brief :vi`, copies a successful result through `pbcopy`, and emits a concise tmux status message.
- Add `T` to the `copy-mode-vi` key table using `copy-pipe-and-cancel` to pass the selected text to the helper and return to w3m.
- Remove the unrelated prefix-table `T` refresh binding and the prior popup binding so key behavior is unambiguous.

## Error handling

- An empty selection reports a tmux status error without changing the clipboard.
- A failed `trans` invocation reports a tmux status error without changing the clipboard.
- Newlines are compacted only in the status preview; the full clipboard translation is preserved.

## Verification

- A shell test stubs `trans`, `pbcopy`, and `tmux` to verify success, empty-input, and failed-translation behavior.
- A separate tmux server loads the config and confirms `copy-mode-vi T` invokes `copy-pipe-and-cancel` with the helper.
