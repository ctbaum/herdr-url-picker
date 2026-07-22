#!/usr/bin/env bash
# Unit test for extract-urls.sh: feed known terminal text, assert the exact
# URL list (newest-first, de-duplicated, trailing punctuation stripped).
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
extract="$here/../extract-urls.sh"

fail=0
check() {
  local name="$1" input="$2" expected="$3"
  local actual
  actual="$(printf '%s' "$input" | "$extract")"
  if [ "$actual" = "$expected" ]; then
    printf 'ok   - %s\n' "$name"
  else
    printf 'FAIL - %s\n' "$name"
    printf '  expected:\n%s\n  actual:\n%s\n' "$expected" "$actual"
    fail=1
  fi
}

# Newest-first ordering, dedup, trailing-punctuation and www handling all at once.
read -r -d '' mixed_input <<'EOF' || true
Visit https://example.com/docs for details.
See (https://github.com/foo/bar) and http://old.test
Check out www.wikipedia.org today
Markdown: [link](https://example.com/page)
Repeat https://example.com/docs again
EOF
read -r -d '' mixed_expected <<'EOF' || true
https://example.com/docs
https://example.com/page
https://www.wikipedia.org
http://old.test
https://github.com/foo/bar
EOF
check "mixed: order, dedup, punctuation, www" "$mixed_input" "$mixed_expected"

# No URLs -> empty output, exit 0.
check "no urls -> empty" "just some plain text, nothing to see" ""

# A trailing slash is significant and must be preserved.
check "trailing slash preserved" "go to https://example.com/" "https://example.com/"

# ftp is recognized; file:// is off by default (build-tool noise).
check "ftp kept, file dropped by default" "ftp://ftp.gnu.org/pub and file:///etc/hosts" "ftp://ftp.gnu.org/pub"

# The friendly flag opts file:// back in.
URL_PICKER_INCLUDE_FILES=1 \
  check "file:// via URL_PICKER_INCLUDE_FILES" "see file:///etc/hosts here" "file:///etc/hosts"

# The advanced override also works.
URL_PICKER_SCHEMES="https?|ftp|file" \
  check "file:// via URL_PICKER_SCHEMES" "see file:///etc/hosts here" "file:///etc/hosts"

# Explicit URL_PICKER_SCHEMES wins over the flag.
URL_PICKER_SCHEMES="https?" URL_PICKER_INCLUDE_FILES=1 \
  check "explicit schemes overrides flag" "http://x.test and file:///etc/hosts" "http://x.test"

# A URL embedded in JSON stops at the closing quote, not the next space.
check "json-embedded url stops at quote" \
  '{"url":"https://example.com/flaky","error":{"code":1}}' \
  "https://example.com/flaky"

# Query strings with & = + survive; trailing JSON is dropped at the quote.
check "query string preserved, json tail dropped" \
  'log: "https://api.test/search?term=Nortal+AS&pageSize=10","message":"Fetching"' \
  "https://api.test/search?term=Nortal+AS&pageSize=10"

# A trailing line-continuation backslash is not part of the URL.
check "trailing backslash stripped" "curl https://example.com/api?t=32s\\" "https://example.com/api?t=32s"

# A TUI-truncation ellipsis is stripped from the tail.
check "trailing ellipsis stripped" "see https://example.com/very/long/pa…" "https://example.com/very/long/pa"

if [ "$fail" -ne 0 ]; then
  printf '\nTESTS FAILED\n' >&2
  exit 1
fi
printf '\nAll tests passed.\n'
