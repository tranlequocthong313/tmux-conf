#!/bin/sh
set -eu

helper="/Users/thong/.local/bin/tmux-translate-selection"
fixtures="/Users/thong/.config/tmux/tests/fixtures"

if [ ! -x "$helper" ]; then
  echo "tmux translation helper must be executable" >&2
  exit 1
fi

original_clipboard="$(pbpaste)"
test_dir="$(mktemp -d)"
helper_pid=""
popup_dir=""
restore_clipboard() {
  : > "$trans_release"
  if [ -n "$helper_pid" ]; then
    wait "$helper_pid" || true
  fi
  if [ -z "$popup_dir" ] && [ -f "$tmux_log" ]; then
    popup_dir="$(sed -n 's/^TMUX_TRANSLATE_DIR=//p' "$tmux_log")"
  fi
  if [ -n "$popup_dir" ] && [ -d "$popup_dir" ]; then
    rm -rf "$popup_dir"
  fi
  printf '%s' "$original_clipboard" | pbcopy
  rm -rf "$test_dir"
}
trap restore_clipboard EXIT

tmux_log="$test_dir/tmux.log"
trans_log="$test_dir/trans.log"
trans_started="$test_dir/trans.started"
trans_release="$test_dir/trans.release"

printf '%s' 'Hello' | env \
  TMUX_TRANSLATE_TRANS_CMD="$fixtures/trans-wait.sh" \
  TMUX_TRANSLATE_TMUX_CMD="$fixtures/tmux-capture.sh" \
  TMUX_TRANSLATE_TMUX_LOG="$tmux_log" \
  TMUX_TRANSLATE_TRANS_LOG="$trans_log" \
  TMUX_TRANSLATE_TRANS_STARTED="$trans_started" \
  TMUX_TRANSLATE_TRANS_RELEASE="$trans_release" \
  TMUX_TRANSLATE_VIEWER="/usr/bin/true" \
  "$helper" &
helper_pid="$!"

attempt=0
while [ ! -f "$trans_started" ] && [ "$attempt" -lt 100 ]; do
  sleep 0.02
  attempt=$((attempt + 1))
done
[ -f "$trans_started" ]
[ -s "$tmux_log" ] || {
  echo "popup must open before the translation finishes" >&2
  exit 1
}

grep -Fx 'display-popup' "$tmux_log"
grep -Fx -- '-E' "$tmux_log"
grep -Fx -- '-w' "$tmux_log"
grep -Fx '70%' "$tmux_log"
grep -Fx -- '-h' "$tmux_log"
grep -Fx '60%' "$tmux_log"
grep -Fx -- '-e' "$tmux_log"
grep -F 'TMUX_TRANSLATE_DIR=' "$tmux_log"
grep -Fx '/usr/bin/true' "$tmux_log"

popup_dir="$(sed -n 's/^TMUX_TRANSLATE_DIR=//p' "$tmux_log")"
[ -d "$popup_dir" ]
[ "$(cat "$popup_dir/translation.txt")" = 'Đang dịch bằng Google…' ]
[ "$(pbpaste)" = "$original_clipboard" ]

: > "$trans_release"
wait "$helper_pid"
helper_pid=""

attempt=0
while [ "$(cat "$popup_dir/translation.txt")" != 'Xin chao' ] && [ "$attempt" -lt 100 ]; do
  sleep 0.02
  attempt=$((attempt + 1))
done
[ "$(cat "$popup_dir/translation.txt")" = 'Xin chao' ]

attempt=0
while [ "$(pbpaste)" != 'Xin chao' ] && [ "$attempt" -lt 100 ]; do
  sleep 0.02
  attempt=$((attempt + 1))
done
[ "$(pbpaste)" = 'Xin chao' ]
grep -Fx -- '-e' "$trans_log"
grep -Fx 'google' "$trans_log"
grep -Fx -- '-brief' "$trans_log"
grep -Fx ':vi' "$trans_log"

if printf '' | env \
  TMUX_TRANSLATE_TMUX_CMD="$fixtures/tmux-capture.sh" \
  TMUX_TRANSLATE_TMUX_LOG="$tmux_log" \
  "$helper"; then
  echo "empty selections must fail" >&2
  exit 1
fi
[ "$(pbpaste)" = 'Xin chao' ]

viewer="/Users/thong/.local/bin/tmux-translate-viewer"
viewer_dir="$(mktemp -d "${TMPDIR:-/tmp}/tmux-translate.XXXXXX")"
printf '%s' 'Hello' > "$viewer_dir/source.txt"
printf '%s' 'Xin chao' > "$viewer_dir/translation.txt"
TMUX_TRANSLATE_DIR="$viewer_dir" PATH="$fixtures:$PATH" "$viewer"
[ ! -d "$viewer_dir" ]

failed_tmux_log="$test_dir/failed-tmux.log"
printf '%s' 'Hello' | env \
  TMUX_TRANSLATE_TRANS_CMD="$fixtures/trans-fail.sh" \
  TMUX_TRANSLATE_TMUX_CMD="$fixtures/tmux-capture.sh" \
  TMUX_TRANSLATE_TMUX_LOG="$failed_tmux_log" \
  TMUX_TRANSLATE_VIEWER="/usr/bin/true" \
  "$helper"

failed_popup_dir="$(sed -n 's/^TMUX_TRANSLATE_DIR=//p' "$failed_tmux_log")"
[ -d "$failed_popup_dir" ]
attempt=0
while [ "$(cat "$failed_popup_dir/translation.txt")" != 'Không thể dịch bằng Google.' ] && [ "$attempt" -lt 100 ]; do
  sleep 0.02
  attempt=$((attempt + 1))
done
[ "$(cat "$failed_popup_dir/translation.txt")" = 'Không thể dịch bằng Google.' ]
rm -rf "$failed_popup_dir"
