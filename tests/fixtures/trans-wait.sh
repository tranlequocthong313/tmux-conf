#!/bin/sh
set -eu

: "${TMUX_TRANSLATE_TRANS_STARTED:?}"
: "${TMUX_TRANSLATE_TRANS_RELEASE:?}"
: "${TMUX_TRANSLATE_TRANS_LOG:?}"

printf '%s\n' "$@" > "$TMUX_TRANSLATE_TRANS_LOG"
cat >/dev/null
: > "$TMUX_TRANSLATE_TRANS_STARTED"

while [ ! -f "$TMUX_TRANSLATE_TRANS_RELEASE" ]; do
  sleep 0.02
done

printf '%s\n' 'Xin chao'
