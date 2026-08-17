#!/usr/bin/env bash
# Mechanical UI checks over Svelte, CSS and HTML sources.
#
#   ui-audit.sh [--include-ui] [path ...]        default: src index.html
#
# Catches only what a grep can prove. It cannot tell you whether the screen has one primary
# focus, whether the error message helps, or whether the layout is scannable — that is the
# reviewer's job, and review-ui/SKILL.md lists what to look at by hand.
#
# src/lib/components/ui/ is skipped by default: it holds shadcn-svelte components as the
# registry generated them, and auditing upstream code reports things you did not write and
# would lose on the next `ui add -o`. Pass --include-ui once you have edited them.
#
# Exit 0 clean, 1 with findings.
set -uo pipefail

include_ui=0
targets=()
for argument in "$@"; do
  case "$argument" in
    --include-ui) include_ui=1 ;;
    *) targets+=("$argument") ;;
  esac
done
[ ${#targets[@]} -gt 0 ] || targets=(src index.html)

found=0

# report <rule> <why> <grep-output>
report() {
  local rule=$1 why=$2 hits=$3
  [ -n "$hits" ] || return 0
  found=$((found + 1))
  printf '\n%s\n  %s\n' "$rule" "$why"
  printf '%s\n' "$hits" | sed 's/^/    /'
}

scan() { # scan <extension-glob> <pattern>  -> file:line:text, comment lines dropped
  local include=$1 pattern=$2
  grep -rnE --include="$include" "$pattern" "${targets[@]}" 2>/dev/null |
    grep -vE '^[^:]+:[0-9]+:[[:space:]]*(/\*|\*[^/]|//|<!--)' |
    { [ "$include_ui" -eq 1 ] && cat || grep -v '/components/ui/'; }
}

# ---------------------------------------------------------------- Svelte 4 leftovers

report 'Svelte 4 event directive' \
  'Svelte 5 uses onclick/oninput/onsubmit — no colon. `on:x` does not compile.' \
  "$(scan '*.svelte' 'on:[a-z]+[=|]')"

report 'Svelte 4 prop declaration' \
  'Use `let { … }: Props = $props()`. `export let` is Svelte 4.' \
  "$(scan '*.svelte' '^\s*export\s+let\s')"

report 'Svelte 4 slot' \
  'Use a Snippet prop and {@render children()}.' \
  "$(scan '*.svelte' '<slot[ />]')"

report 'Svelte 4 event dispatcher' \
  'Pass callback props (onselect, onclose) instead of createEventDispatcher.' \
  "$(scan '*.svelte' 'createEventDispatcher')"

report 'Reactive statement' \
  'Use $derived. `$:` is Svelte 4 and does not track runes.' \
  "$(scan '*.svelte' '^\s*\$:')"

# ---------------------------------------------------------------- accessibility

report 'Focus ring removed' \
  'Never `outline: none` without replacing the ring in the same rule.' \
  "$(scan '*' 'outline:\s*(none|0)' | grep -v 'outline:\s*none;\s*/\* replaced' || true)"

report 'Positive tabindex' \
  'Positive tabindex fights the document order. Use 0 or -1 and fix the markup order.' \
  "$(scan '*' 'tabindex=["'"'"']?[1-9]')"

report 'Zoom disabled' \
  'user-scalable=no and maximum-scale trap users who need to magnify text.' \
  "$(scan '*' 'user-scalable\s*=\s*no|maximum-scale')"

report 'Image without alt' \
  'Every <img> needs alt — empty alt="" if it is purely decorative.' \
  "$(scan '*' '<img[[:space:]]' | grep -v 'alt=' || true)"

report 'Interactive role on a generic element' \
  'Use <button>/<a>. A div with role="button" needs tabindex, Enter, Space and focus styling.' \
  "$(scan '*.svelte' '<(div|span)[^>]*role=["'"'"'](button|link|checkbox|tab)')"

# Anchored on </button> rather than on <button …>, because Svelte attribute expressions
# contain `>` (`onclick={() => …}`) and would end the tag early for any naive matcher.
report 'Icon-only control' \
  'An icon is never the sole label. Add visible text or an aria-label.' \
  "$(scan '*.svelte' '>[[:space:]]*(<svg|&#[^;]+;|[^<>[:alnum:][:space:]]{1,4})[[:space:]]*</button>' |
    grep -v 'aria-label' || true)"

# A placeholder is not a label: it vanishes on the first keystroke.
placeholders=$(scan '*.svelte' '<input[^>]*placeholder=' || true)
if [ -n "$placeholders" ]; then
  unlabelled=$(printf '%s\n' "$placeholders" | while IFS=: read -r file line rest; do
    id=$(printf '%s' "$rest" | grep -oE 'id="[^"]+"' | head -1 | cut -d'"' -f2)
    if [ -z "$id" ]; then
      printf '%s:%s: input has a placeholder and no id to label\n' "$file" "$line"
    elif ! grep -q "for=\"$id\"\|for={\`\?$id" "$file" 2>/dev/null; then
      printf '%s:%s: no <label for="%s"> in this file\n' "$file" "$line" "$id"
    fi
  done)
  report 'Placeholder without a label' \
    'Placeholder text disappears exactly when it is needed. Add a <label for>.' \
    "$unlabelled"
fi

# ---------------------------------------------------------------- design system

report 'Hard-coded colour' \
  'Use a token from app.css. A literal colour cannot follow the theme.' \
  "$(scan '*.svelte' ':\s*(#[0-9a-fA-F]{3,8}|rgba?\()' | grep -v 'rgb(0 0 0 /' || true)"

report 'Hard-coded font size' \
  'Use --text-* tokens so type scales with the user’s OS setting.' \
  "$(scan '*.svelte' 'font-size:\s*[0-9]')"

report '!important' \
  'Base styles in app.css are :where()-wrapped and zero-specificity — you never need this.' \
  "$(scan '*.svelte' '!important')"

report 'Text selection disabled' \
  'Users copy text out of apps. Do not take that away.' \
  "$(scan '*' 'user-select:\s*none')"

# ---------------------------------------------------------------- tailwind / shadcn

report 'Arbitrary Tailwind value' \
  'bg-[#…], text-[13px], p-[7px] bypass the token layer exactly as a hard-coded CSS value does.' \
  "$(scan '*.svelte' '\b(bg|text|border|ring|fill|stroke|shadow|p|px|py|pt|pb|pl|pr|m|mx|my|gap|w|h|min-w|min-h|max-w|max-h|rounded)-\[[^]]+\]')"

# Utility classes in a project with no Tailwind compile to nothing at all, and the
# component renders unstyled with no error anywhere.
if ! grep -rqE "@import ['\"]tailwindcss" "${targets[@]}" 2>/dev/null &&
  ! [ -f components.json ]; then
  report 'Tailwind utilities without Tailwind' \
    'This app is on the plain-CSS path, so these class names do nothing. Use a <style> block and tokens.' \
    "$(scan '*.svelte' 'class="[^"]*\b(bg-(primary|background|muted|card|destructive|accent|secondary)|text-(foreground|muted-foreground|primary-foreground)|border-(border|input)|ring-ring)\b')"
fi

# ---------------------------------------------------------------- motion

motion=$(scan '*' 'transition:|animation:' || true)
if [ -n "$motion" ]; then
  if ! grep -rq 'prefers-reduced-motion' "${targets[@]}" 2>/dev/null; then
    report 'Motion without a reduced-motion escape' \
      'Something animates but nothing honours prefers-reduced-motion.' \
      "$(printf '%s\n' "$motion" | head -5)"
  fi
fi

# ---------------------------------------------------------------- document

for entry in "${targets[@]}"; do
  [ -f "$entry" ] && case "$entry" in *.html)
    grep -q '<html[^>]*\blang=' "$entry" ||
      report 'Document without a language' \
        'Screen readers pick pronunciation from <html lang>.' "$entry:1"
    ;;
  esac
done

skipped=0
if [ "$include_ui" -eq 0 ]; then
  skipped=$(grep -rl --include='*.svelte' '' "${targets[@]}" 2>/dev/null |
    grep -c '/components/ui/' || true)
fi
note_skipped() {
  [ "$skipped" -gt 0 ] &&
    printf '\n%s shadcn component file(s) under components/ui/ were skipped; --include-ui to audit them.\n' "$skipped"
  return 0
}

if [ "$found" -eq 0 ]; then
  printf 'ui-audit: clean (%s)\n' "${targets[*]}"
  note_skipped
  exit 0
fi

note_skipped
printf '\nui-audit: %s rule(s) with findings\n' "$found"
printf 'These are the mechanical checks only. Work through the judgement checks in\n'
printf 'review-ui/SKILL.md before calling the interface done.\n'
exit 1
