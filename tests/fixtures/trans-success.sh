#!/bin/sh
set -eu

if [ -n "${TMUX_TRANSLATE_TRANS_LOG:-}" ]; then
  printf '%s\n' "$@" > "$TMUX_TRANSLATE_TRANS_LOG"
fi

cat >/dev/null
printf '%s\n' 'Xin chao'
