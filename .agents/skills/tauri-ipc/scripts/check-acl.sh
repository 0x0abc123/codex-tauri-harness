#!/usr/bin/env bash
# Cross-check the three places a Tauri 2 command has to agree:
#
#   src/**/*.rs              #[tauri::command] definitions
#   generate_handler![…]     registration
#   capabilities/*.json      permissions — for plugin and core commands only
#
#   check-acl.sh [path/to/src-tauri]
#
# Exit 0 clean, 1 if anything is out of step. Text output; no dependencies beyond
# coreutils, grep and sed.
set -uo pipefail

root=${1:-src-tauri}
[ -d "$root" ] || {
  printf 'error: %s is not a directory\n' "$root" >&2
  exit 2
}

src="$root/src"
caps="$root/capabilities"
problems=0

note() { printf '  %s\n' "$1"; }
fail() {
  printf '\n%s\n' "$1"
  problems=$((problems + 1))
}

# --- 1. command definitions ---------------------------------------------------------
# The attribute and the fn signature are on separate lines, so pair them with grep -A1.
defined=$(grep -rh -A1 '^\s*#\[tauri::command' "$src" --include='*.rs' 2>/dev/null |
  grep -oE '\bfn\s+[a-z_][a-z0-9_]*' | awk '{print $2}' | sort -u)

# `pub fn` on a command in lib.rs collides with the generated glue macro (E0255).
public=$(grep -rh -A1 '^\s*#\[tauri::command' "$src" --include='*.rs' 2>/dev/null |
  grep -oE '\bpub(\([^)]*\))?\s+(async\s+)?fn\s+[a-z_][a-z0-9_]*' |
  grep -oE 'fn\s+[a-z_][a-z0-9_]*' | awk '{print $2}' | sort -u)

# --- 2. registration ----------------------------------------------------------------
# generate_handler![…] is routinely multi-line; flatten the file first.
registered=$(for file in $(grep -rl 'generate_handler!' "$src" --include='*.rs' 2>/dev/null); do
  tr '\n' ' ' <"$file" | grep -oE 'generate_handler!\[[^]]*\]'
done | sed -E 's/generate_handler!\[//; s/\]//' | tr ',' '\n' |
  sed -E 's/.*:://; s/[^a-zA-Z0-9_]//g' | grep -v '^$' | sort -u)

# --- 3. plugins and permissions -----------------------------------------------------
# `tauri_plugin_opener::init()` -> permission prefix `opener`.
plugins=$(grep -rhoE 'tauri_plugin_[a-z0-9_]+::init' "$src" --include='*.rs' 2>/dev/null |
  sed -E 's/tauri_plugin_//; s/::init//' | tr '_' '-' | sort -u)

granted=$(grep -rhoE '"[a-z0-9-]+:[a-z0-9:-]+"' "$caps" 2>/dev/null |
  tr -d '"' | sort -u)
granted_prefixes=$(printf '%s\n' "$granted" | cut -d: -f1 | sort -u)

printf 'ACL check: %s\n' "$root"
printf '  %s command(s) defined, %s registered, %s permission(s) granted\n' \
  "$(printf '%s\n' "$defined" | grep -c '[^[:space:]]')" \
  "$(printf '%s\n' "$registered" | grep -c '[^[:space:]]')" \
  "$(printf '%s\n' "$granted" | grep -c '[^[:space:]]')"

# --- findings -----------------------------------------------------------------------

unreachable=$(comm -23 <(printf '%s\n' "$defined") <(printf '%s\n' "$registered") | grep -v '^$')
if [ -n "$unreachable" ]; then
  fail 'Defined but not in generate_handler! — the frontend cannot call these:'
  printf '%s\n' "$unreachable" | while read -r name; do note "$name"; done
fi

missing=$(comm -13 <(printf '%s\n' "$defined") <(printf '%s\n' "$registered") | grep -v '^$')
if [ -n "$missing" ]; then
  fail 'In generate_handler! with no #[tauri::command] fn — this will not compile:'
  printf '%s\n' "$missing" | while read -r name; do note "$name"; done
fi

if [ -n "$public" ]; then
  fail 'Command declared pub — the glue macro collides with itself (E0255):'
  printf '%s\n' "$public" | while read -r name; do note "$name"; done
fi

if [ -n "$plugins" ]; then
  ungranted=$(comm -23 <(printf '%s\n' "$plugins") <(printf '%s\n' "$granted_prefixes") | grep -v '^$')
  if [ -n "$ungranted" ]; then
    fail 'Plugin initialised but no capability grants it — its commands are denied at runtime:'
    printf '%s\n' "$ungranted" | while read -r name; do note "$name — add \"$name:default\" to a capability"; done
  fi
fi

# A permission whose prefix is neither `core` nor an initialised plugin is dead weight,
# and usually a typo in the plugin name.
dead=$(printf '%s\n' "$granted_prefixes" | grep -v '^core$' | grep -v '^$' |
  { [ -n "$plugins" ] && comm -23 - <(printf '%s\n' "$plugins") || cat; })
if [ -n "$dead" ]; then
  fail 'Permission granted for a plugin that is not initialised in the builder:'
  printf '%s\n' "$dead" | while read -r name; do note "$name"; done
fi

if [ -d "$caps" ] && ! printf '%s\n' "$granted" | grep -q '^core:'; then
  fail 'No core: permission in any capability — window, event and path APIs will be denied.'
  note 'add "core:default" to capabilities/default.json'
fi

if [ "$problems" -eq 0 ]; then
  printf '\nno drift found\n'
  exit 0
fi

printf '\n%s problem(s)\n' "$problems"
printf 'Reminder: app commands need only generate_handler!. The ACL gates plugin and core commands.\n'
exit 1
