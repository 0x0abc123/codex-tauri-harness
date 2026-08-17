#!/usr/bin/env bash
# Copy the harness template into a new project and replace every placeholder.
#
#   new-app.sh <target-dir> <App Name> [bundle-identifier] [--shadcn]
#
# --shadcn additionally applies the template-shadcn overlay: Tailwind CSS 4, the
# shadcn-svelte CLI and the design-token bridge. Without it the app is plain CSS.
#
# Refuses to touch a non-empty target. Leaves no placeholder behind — it verifies that
# itself before reporting success.
set -euo pipefail

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

shadcn=0
positional=()
for argument in "$@"; do
  case "$argument" in
    --shadcn) shadcn=1 ;;
    --*) die "unknown option: $argument" ;;
    *) positional+=("$argument") ;;
  esac
done
set -- "${positional[@]+"${positional[@]}"}"

[ $# -ge 2 ] || die "usage: new-app.sh <target-dir> <App Name> [bundle-identifier] [--shadcn]"

target=$1
app_name=$2
harness_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
template="$harness_root/template"
overlay="$harness_root/template-shadcn"

[ -d "$template" ] || die "template not found at $template"
[ "$shadcn" -eq 0 ] || [ -d "$overlay" ] || die "overlay not found at $overlay"

# slug: lowercase, non-alphanumerics collapsed to a single hyphen, trimmed.
slug=$(printf '%s' "$app_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
[ -n "$slug" ] || die "app name '$app_name' contains no usable characters"
[[ $slug =~ ^[a-z] ]] || die "app name must start with a letter (derived slug: '$slug')"

crate_name=${slug//-/_}
lib_name="${crate_name}_lib"
identifier=${3:-com.example.$slug}

# Tauri identifiers are reverse-DNS and reach Apple bundle IDs verbatim: letters, digits,
# hyphens and dots only. An underscore here fails at `tauri ios init`, not here.
[[ $identifier =~ ^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$ && $identifier == *.* ]] ||
  die "identifier '$identifier' must be reverse-DNS: letters, digits, hyphens, dots"
[ "$identifier" != "com.tauri.dev" ] || die "com.tauri.dev is reserved by Tauri"

if [ -e "$target" ]; then
  [ -d "$target" ] || die "$target exists and is not a directory"
  [ -z "$(ls -A "$target")" ] || die "$target is not empty — refusing to overwrite"
else
  mkdir -p "$target"
fi
target=$(cd "$target" && pwd)

# Copy everything including dotfiles; the template carries no build output to skip.
cp -R "$template/." "$target/"

# The overlay replaces whole files rather than patching them, so it goes on second.
if [ "$shadcn" -eq 1 ]; then
  cp -R "$overlay/." "$target/"
  rm -f "$target/README.md"   # the overlay's README documents the overlay, not the app
fi

rm -rf "$target/node_modules" "$target/dist" "$target/src-tauri/target" "$target/src-tauri/gen"

# Substitute in text files only — the icons must not be touched.
while IFS= read -r -d '' file; do
  sed -i \
    -e "s|__APP_NAME__|$app_name|g" \
    -e "s|__APP_SLUG__|$slug|g" \
    -e "s|__APP_IDENTIFIER__|$identifier|g" \
    -e "s|__LIB_NAME__|$lib_name|g" \
    -e "s|__CRATE_NAME__|$crate_name|g" \
    "$file"
done < <(grep -rlZ -e '__APP_NAME__' -e '__APP_SLUG__' -e '__APP_IDENTIFIER__' \
  -e '__LIB_NAME__' -e '__CRATE_NAME__' "$target" 2>/dev/null || true)

if [ "$shadcn" -eq 1 ]; then
  ui_stack='vanilla Svelte 5 + TypeScript frontend, styled with design tokens and
shadcn-svelte components on Tailwind CSS 4.'
  ui_section='
## UI components

    npm run ui add button dialog     # adds shadcn-svelte components under src/lib/components/ui

**Never run `shadcn-svelte init`** — it overwrites `src/app.css`, which holds the design
tokens every component depends on. Everything `init` would create is already in place.

shadcn components read their colours from the `@theme inline` bridge at the foot of
`src/app.css`, so retheming is still one edit to the `:root` tokens.
'
else
  ui_stack='vanilla Svelte 5 + TypeScript frontend, styled with plain CSS and design tokens.'
  ui_section=''
fi

# template/README.md documents the template, not the app it produces.
cat >"$target/README.md" <<EOF
# $app_name

A Tauri 2 desktop and mobile application with a $ui_stack

    npm install
    npm run dev          # frontend alone, in a browser
    npm run tauri dev    # the actual app
    npm run check        # svelte-check + tsc
    npm run build        # frontend production build
    npm run tauri build  # installers for this platform

Mobile targets are initialised per platform and are not set up yet:

    npm run tauri android init
    npm run tauri ios init
$ui_section
## Layout

    src/app.css              design tokens; the single source of visual truth
    src/lib/ipc.ts           typed wrappers over invoke — one per Rust command
    src/lib/                 components
    src-tauri/src/lib.rs     commands and builder setup, in run()
    src-tauri/capabilities/  ACL grants for plugin and core commands

Components consume tokens and never hard-code colours or sizes; they call Rust through
\`src/lib/ipc.ts\` and never \`invoke\` directly.

The placeholder artwork in \`src-tauri/icons/\` should be replaced before release with
\`npm run tauri icon <path>\`.
EOF

leftover=$(grep -rl '__[A-Z_]\{3,\}__' "$target" 2>/dev/null || true)
[ -z "$leftover" ] || die "placeholders left unreplaced in:"$'\n'"$leftover"

cat <<EOF
Created $app_name at $target

  package       $slug
  crate         $crate_name (lib: $lib_name)
  identifier    $identifier
  frontend      $([ "$shadcn" -eq 1 ] && echo 'plain CSS tokens + shadcn-svelte on Tailwind 4' || echo 'plain CSS tokens')

Next:
  cd $target
  npm install
  npm run check          # svelte-check + tsc, expect zero errors
  npm run tauri dev      # desktop window with the reference command wired up
EOF

if [ "$shadcn" -eq 1 ]; then
  cat <<'EOF'

Add components as you need them — never run `shadcn-svelte init`, it overwrites app.css:
  npm run ui add button
EOF
fi

cat <<EOF

Before release, replace the placeholder artwork:
  npm run tauri icon path/to/icon.png
EOF
