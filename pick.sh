#!/usr/bin/env bash
# Action entrypoint. Runs when the user triggers `url-picker.pick` (via a
# keybinding or `herdr plugin action invoke`).
#
# An action's stdout is captured, not shown, so it can't host fzf itself.
# Instead it captures the pane the user invoked from and opens the picker
# popup, handing that pane id over so the popup knows where to read URLs.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"

# focused_pane_id is the pane that had focus when the action fired — i.e. the
# one whose printed URLs the user wants to pick from.
pane_id="$(printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" | jq -r '.focused_pane_id // empty')"

if [ -z "$pane_id" ]; then
  echo "url-picker: no focused pane in invocation context" >&2
  exit 1
fi

exec "$herdr" plugin pane open \
  --plugin url-picker \
  --entrypoint picker \
  --env "URL_PICKER_SOURCE_PANE=$pane_id"
