# template/

The starter the `scaffold-app` skill copies out. **Do not build in this directory** — it
carries `__PLACEHOLDER__` tokens and is not a valid project until they are replaced.

```bash
.agents/skills/scaffold-app/scripts/new-app.sh <target-dir> "<App Name>" [identifier]
```

This is the **plain-CSS** path: design tokens and scoped `<style>` blocks, no CSS framework.
Adding `--shadcn` applies the `template-shadcn/` overlay on top of everything here, bringing
Tailwind CSS 4 and the shadcn-svelte CLI while keeping these tokens as the source of truth.

## Placeholders

| Token | Becomes | Appears in |
|---|---|---|
| `__APP_NAME__` | `Field Notes` | `tauri.conf.json`, `index.html`, `App.svelte`, `Cargo.toml` |
| `__APP_SLUG__` | `field-notes` | `package.json` |
| `__APP_IDENTIFIER__` | `au.com.example.fieldnotes` | `tauri.conf.json` |
| `__CRATE_NAME__` | `field_notes` | `Cargo.toml` package name |
| `__LIB_NAME__` | `field_notes_lib` | `Cargo.toml` lib name, `main.rs` |

The script derives all five from the app name and verifies none survives.

## What is here and why

```
package.json            npm scripts and pinned dependencies
vite.config.ts          Tauri's port, host and watch conventions, incl. TAURI_DEV_HOST
tsconfig*.json          three-file split: app (Svelte) and node (vite.config) checked apart
index.html              viewport-fit=cover, required for the safe-area padding to apply
src/app.css             design tokens + zero-specificity base styles
src/main.ts             Svelte 5 mount()
src/App.svelte          header / workspace / footer shell, skip link, safe areas
src/lib/ipc.ts          typed wrappers over invoke — one per Rust command
src/lib/GreetForm.svelte  the reference vertical slice, all four states visible
src-tauri/Cargo.toml    mobile-capable crate-type, release profile
src-tauri/tauri.conf.json  v2 schema, CSP, window defaults
src-tauri/capabilities/default.json  the baseline ACL grant
src-tauri/src/lib.rs    run() with the mobile entry point; the reference command
src-tauri/src/main.rs   desktop entry, delegates straight to run()
src-tauri/icons/        Tauri's default artwork — placeholder, replace before release
```

## Deliberate choices

- **Not SvelteKit.** The frontend is create-vite's vanilla `template-svelte-ts` joined to
  Tauri's `_base_/src-tauri`. `create-tauri-app`'s own Svelte template is SvelteKit and
  cannot be used here.
- **TypeScript pinned to `~6.0.2`.** `typescript@7` is the native rewrite and ships no
  `tsserver.js`, which breaks `svelte-check` and every TypeScript language server.
- **A real CSP** (`default-src 'self'; connect-src ipc: http://ipc.localhost`) rather than
  `null`. Note it applies to bundled builds only — Tauri serves that header from its own
  protocol handler, so under `tauri dev` the Vite dev server answers instead and a CSP
  mistake shows up in production only.
- **No plugins.** Nothing is installed that the app does not use. `tauri-ipc` covers adding
  one, including the capability grant it needs.
- **`src-tauri/gen/` is gitignored.** Correct until you hand-edit the Android manifest,
  Gradle files or signing settings; commit it deliberately from that point.

## Before release

```bash
npm run tauri icon path/to/icon.png    # replaces every placeholder icon
```

Also check that the version is consistent across `package.json`, `tauri.conf.json` and
`Cargo.toml` — nothing keeps them in step for you.
