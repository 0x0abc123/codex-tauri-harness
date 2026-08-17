#!/usr/bin/env bash
# Report what this machine can and cannot do with the harness. Reports only — it installs
# nothing and changes nothing.
#
#   doctor.sh
#
# Exit 0 if every hard prerequisite is present, 1 otherwise. Missing mobile toolchains are
# warnings: plenty of useful work needs neither Android nor iOS.
set -uo pipefail

REQUIRED_COLLECTIONS=(tauri svelte tauri-examples)
# Only needed by apps scaffolded with --shadcn, and the docs are fetchable over HTTP as a
# fallback, so its absence is a warning rather than a failure.
OPTIONAL_COLLECTIONS=(shadcn-svelte)

missing=0
warnings=0

ok() { printf '  ok    %s\n' "$1"; }
bad() {
  printf '  MISS  %s\n' "$1"
  [ $# -gt 1 ] && printf '        %s\n' "$2"
  missing=$((missing + 1))
}
warn() {
  printf '  warn  %s\n' "$1"
  [ $# -gt 1 ] && printf '        %s\n' "$2"
  warnings=$((warnings + 1))
}

version_of() { "$1" --version 2>/dev/null | head -1; }

printf 'Knowledge base\n'
if command -v akb >/dev/null 2>&1; then
  ok "akb            $(version_of akb)"
  listing=$(akb collections --json 2>/dev/null)
  for collection in "${REQUIRED_COLLECTIONS[@]}"; do
    if printf '%s' "$listing" | grep -q "\"$collection\""; then
      ok "collection     $collection"
    else
      bad "collection     $collection" \
        "the skills query this by name; index the docs into it before relying on them"
    fi
  done
  for collection in "${OPTIONAL_COLLECTIONS[@]}"; do
    if printf '%s' "$listing" | grep -q "\"$collection\""; then
      ok "collection     $collection (optional)"
    else
      warn "collection     $collection (optional)" \
        'only needed for --shadcn apps; consult-docs falls back to shadcn-svelte.com/*.md'
    fi
  done
else
  bad 'akb' 'install agent-kb (see docs/akb.md), then index the three collections'
fi

printf '\nFrontend\n'
for tool in node npm; do
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$(printf '%-14s' "$tool")$(version_of "$tool")"
  else
    bad "$tool"
  fi
done

printf '\nRust\n'
if command -v cargo >/dev/null 2>&1; then
  ok "cargo          $(version_of cargo)"
  ok "rustc          $(version_of rustc)"
else
  bad 'cargo' 'install via https://rustup.rs — nothing in src-tauri can build without it'
fi

printf '\nAndroid (optional)\n'
android_targets='aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android'
if command -v rustup >/dev/null 2>&1; then
  installed=$(rustup target list --installed 2>/dev/null)
  absent=''
  for target in $android_targets; do
    printf '%s\n' "$installed" | grep -qx "$target" || absent="$absent $target"
  done
  [ -z "$absent" ] && ok 'rust targets' ||
    warn 'rust targets' "rustup target add$absent"
else
  warn 'rustup' 'needed to add the Android and iOS cross-compilation targets'
fi
for variable in JAVA_HOME ANDROID_HOME NDK_HOME; do
  if [ -n "${!variable:-}" ]; then
    ok "$(printf '%-14s' "$variable")${!variable}"
  else
    warn "$variable" 'required by `tauri android init` and `tauri android dev`'
  fi
done

printf '\niOS (optional, macOS only)\n'
if [ "$(uname -s)" = 'Darwin' ]; then
  if xcodebuild -version >/dev/null 2>&1; then
    ok "xcode          $(xcodebuild -version 2>/dev/null | head -1)"
  else
    warn 'xcode' 'install Xcode itself, not only the Command Line Tools'
  fi
  command -v pod >/dev/null 2>&1 && ok 'cocoapods' || warn 'cocoapods' 'brew install cocoapods'
  if command -v rustup >/dev/null 2>&1; then
    ios_absent=''
    for target in aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim; do
      rustup target list --installed 2>/dev/null | grep -qx "$target" || ios_absent="$ios_absent $target"
    done
    [ -z "$ios_absent" ] && ok 'rust targets' || warn 'rust targets' "rustup target add$ios_absent"
  fi
else
  printf '  n/a   iOS builds require macOS\n'
fi

printf '\n'
if [ "$missing" -gt 0 ]; then
  printf '%s hard prerequisite(s) missing, %s warning(s).\n' "$missing" "$warnings"
  printf 'Desktop builds and the doc-backed skills need these before the harness is usable.\n'
  exit 1
fi

printf 'All hard prerequisites present'
[ "$warnings" -gt 0 ] && printf ', %s optional item(s) missing' "$warnings"
printf '.\n'
exit 0
