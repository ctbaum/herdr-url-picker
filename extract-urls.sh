#!/usr/bin/env bash
# Reads terminal text on stdin, writes one URL per line on stdout:
# newest-first, de-duplicated. Pure text transformation with no herdr
# dependency, so it can be unit-tested against fixtures.
#
# No `pipefail`: grep exiting 1 on "no matches" is a normal empty result, not
# a failure, so the script's status follows awk (always 0).
set -u

# URL schemes to pick up, as a grep ERE alternation.
#
# file:// is off by default because build tools spew file:// node_modules paths
# that drown out the links a person actually wants. Turn it on with
# URL_PICKER_INCLUDE_FILES=1. For full control, set URL_PICKER_SCHEMES to a grep
# ERE alternation directly, which overrides the flag.
default_schemes="https?|ftp"
case "${URL_PICKER_INCLUDE_FILES:-}" in
  1 | true | yes | on) default_schemes="https?|ftp|file" ;;
esac
schemes="${URL_PICKER_SCHEMES:-$default_schemes}"

# A URL runs until a delimiter that can't appear mid-URL. Terminal output embeds
# URLs in JSON and quotes ("https://x","next":...), so stopping only at
# whitespace would swallow the trailing JSON. Stop at quotes, backtick, angle
# and curly brackets, pipe, and caret too.
delim='[:space:]"'\''`<>{}|^'

grep -oiE "($schemes)://[^${delim}]+|[wW]{3}\.[^${delim}]+" \
  | sed -E 's/…+$//' \
  | sed -E "s/[]),.;:!?'\">}\\]+\$//" \
  | sed -E 's#^[Ww][Ww][Ww]\.#https://www.#' \
  | awk '{ lines[NR] = $0 }
         END { for (i = NR; i >= 1; i--) { l = lines[i]; if (l != "" && !seen[l]++) print l } }'
