#!/bin/sh
set -eu

: "${TMUX_TRANSLATE_TMUX_LOG:?}"
printf '%s\n' "$@" >> "$TMUX_TRANSLATE_TMUX_LOG"
