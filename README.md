# URL Picker

A [herdr](https://herdr.dev) plugin. Press a key, get an fzf list of every URL
printed in the current pane, filter, hit Enter — it opens in your default
browser.

## Requirements

These must be on your `PATH` (herdr does not install them):

- **herdr** `>= 0.7.4` — needs `herdr pane read`.
- **fzf** — the picker UI.
- **jq** — parsing herdr's invocation context.
- A browser opener: `open` (macOS) or `xdg-open` (Linux).

## Install

Link it from a local checkout (for development):

```bash
herdr plugin link /path/to/url-picker
```

Or install it from GitHub:

```bash
herdr plugin install abrose/herdr-url-picker --yes
```

## Bind a key

herdr plugins can't ship a default keybinding — you add one to your herdr
`config.toml`. For `<prefix>u`:

```toml
[[keys.command]]
key = "prefix+u"
type = "plugin_action"
command = "url-picker.pick"
description = "pick a url"
```

Reload herdr config. Now `<prefix>u` opens the picker for the focused pane.

## Configuration

Optional. Copy `.env.example` into the plugin's config dir and edit it:

```bash
cp .env.example "$(herdr plugin config-dir url-picker)/.env"
```

Reopen the picker to pick up changes — no relink needed. Settings:

- `URL_PICKER_INCLUDE_FILES` — set to `1` to also list `file://` URLs. Off by
  default because build tools print many `file://` node_modules paths that
  drown out real links.
- `URL_PICKER_LINES` — how many lines of scrollback to scan. Default `2000`.
- `URL_PICKER_SCHEMES` — advanced: the grep ERE alternation of schemes to
  match (default `https?|ftp`). Overrides `URL_PICKER_INCLUDE_FILES`.

By default only `http`, `https`, and `ftp` URLs are surfaced.

## How it works

Two stages, because an action's stdout is captured (no TTY) and so can't host
fzf:

1. **`pick.sh`** (the `pick` action) reads `focused_pane_id` from the
   invocation context and opens the picker popup, passing that pane id along
   in `URL_PICKER_SOURCE_PANE`.
2. **`picker.sh`** (the `picker` popup — a real PTY) runs
   `herdr pane read <pane> --source recent-unwrapped`, pipes the text through
   `extract-urls.sh`, shows fzf, and opens your pick with `open`/`xdg-open`.

`extract-urls.sh` is a pure stdin→stdout transformation (URLs, newest-first,
de-duplicated, trailing punctuation stripped), which is why it has real unit
tests in `test/`.

## Limitations

- It can only see what the terminal actually rendered. If a TUI *displayed* a
  URL truncated with an ellipsis (`…`), the full URL was never on screen and
  cannot be recovered — the picker strips the `…` but the result is still the
  truncated form. Plain printed URLs (the common case) are unaffected;
  soft-wrapped ones are rejoined via `recent-unwrapped`.

## Development

```bash
./test/extract-urls.test.sh              # unit tests for URL extraction
herdr plugin link "$PWD"                 # (re)register after manifest edits
herdr plugin action list --plugin url-picker
herdr plugin log list --plugin url-picker --limit 5   # stdout/stderr/exit_code
```

Plugin stdout/stderr is captured, not printed — `herdr plugin log list` is the
place to debug.
