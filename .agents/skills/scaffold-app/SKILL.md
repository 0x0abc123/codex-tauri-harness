---
name: scaffold-app
description: Create a new Tauri 2 + vanilla Svelte 5 + TypeScript application from the harness template, rename it, verify it builds, and optionally initialise the Android and iOS targets. Use when the user says "start a new app", "scaffold a Tauri app", "create a new project", or invokes /scaffold-app.
---

# Scaffold a new application

Copy `template/` into a new project, rename it throughout, and prove it builds before
handing it over. One app per run.

Done means: `npm run check` reports zero errors, `cargo check` compiles, `npm run build`
produces `dist/`, and no `__PLACEHOLDER__` token survives anywhere in the tree.

## Process

**1. Collect four things.** Ask for whatever the request did not carry:

- **App name** — human-readable, e.g. `Field Notes`. Becomes `productName`, the window
  title and the `<h1>`.
- **Target directory** — outside this harness. Default to a sibling of the harness and
  confirm it. Never scaffold into the harness tree.
- **Bundle identifier** — reverse-DNS, e.g. `au.com.example.fieldnotes`. Default
  `com.example.<slug>` and say so. It reaches Apple bundle IDs verbatim, so letters,
  digits, hyphens and dots only; an underscore fails later at `tauri ios init`, not now.
- **Frontend path** — plain CSS, or shadcn-svelte. Ask; do not assume. This is fixed at
  scaffold time and awkward to change later, so put the trade-off plainly:

  | | Plain CSS (default) | `--shadcn` |
  |---|---|---|
  | Ships | Tokens, hand-written components | The above **plus** Tailwind 4, the shadcn CLI, the token bridge |
  | Good for | Small or highly custom UIs; a handful of controls; smallest dependency surface | Apps needing dialogs, tables, comboboxes, date pickers — the accessible primitives are expensive to hand-build |
  | Cost | Every non-trivial component is yours to build and to get right | Tailwind in the build, `bits-ui` at runtime, utility classes in the markup |

  Both honour `docs/ui-design-principles.md`, and both take their colours from the same
  `src/app.css` tokens. Choosing shadcn does not licence a different design language.

**2. Run the script.** Never copy the template by hand — the script derives the crate name,
the `_lib` suffix and the slug consistently, and it verifies no placeholder survives:

```bash
.agents/skills/scaffold-app/scripts/new-app.sh <target-dir> "<App Name>" [identifier] [--shadcn]
```

`--shadcn` copies `template-shadcn/` over the base template after it: a replaced
`package.json`, `vite.config.ts`, both tsconfigs, `index.html` and `src/app.css`, plus
`components.json` and `src/lib/utils.ts`.

It refuses a non-empty target. If the user genuinely wants to scaffold into an occupied
directory, get that confirmed and clear the directory first — do not work around the guard
by copying files manually.

**3. Install and verify the frontend.**

```bash
cd <target-dir>
npm install
npm run check     # svelte-check + tsc, expect 0 errors 0 warnings
npm run build     # expect dist/ with extracted CSS
```

A `svelte-check` warning is a failure here. The template starts clean, so anything reported
came from this run.

On the shadcn path, add the components the app actually needs and re-check:

```bash
npm run ui add button dialog        # local CLI; -o overwrites local edits
```

**Never run `shadcn-svelte init`.** It overwrites the global CSS file, which here is the
design-token layer. The overlay already wrote everything `init` would.

**4. Verify the Rust side.**

```bash
cd src-tauri && cargo check
```

First run downloads and compiles the Tauri crate tree and takes several minutes; say so
before starting it rather than letting it look hung. If `cargo` is absent, stop and tell the
user what to install — do not report the app as verified.

**5. Offer a run.** `npm run tauri dev` opens the window with the reference command wired
up. Confirm the greet form round-trips before declaring success; that single exchange
proves the config, the ACL, the IPC wrapper and the build pipeline all at once.

**6. Initialise mobile only if asked.** `mobile-target` covers this. Do not run
`tauri android init` speculatively — it generates a large Gradle project that the template
`.gitignore` deliberately excludes.

**7. Hand over.** Report the paths, what was verified, and the two things the user must do
themselves: replace the placeholder artwork (`npm run tauri icon <path>`) and decide whether
`src-tauri/gen/` should be committed.

## What the template already gives you

Do not rebuild these; extend them.

- `src/app.css` — the design-token layer and base element styles. `design-ui` rewrites the
  tokens; components consume them and hard-code nothing.
- `src/lib/ipc.ts` — typed wrappers over `invoke`. Every command gets one; components never
  call `invoke` directly.
- `src/lib/GreetForm.svelte` — the reference vertical slice: a form whose every state
  (idle, busy, failed, done) is visible, with the error path preserving typed input.
- `src/App.svelte` — the header / workspace / footer shell with a skip link and safe-area
  padding.
- `src-tauri/src/lib.rs` — `run()` carrying the `mobile_entry_point` attribute, with the
  command registered in `generate_handler!`.
- `src-tauri/capabilities/default.json` — the baseline capability the ACL requires.

On the `--shadcn` path, additionally:

- `components.json` — CLI configuration; its presence is how any later skill detects the path.
- `src/lib/utils.ts` — `cn()` and the type helpers generated components import.
- the `@theme inline` block at the foot of `src/app.css` — the token bridge. Colours are
  still decided once, in the `:root` tokens above it.

The shell and the reference slice stay plain CSS on both paths. That is deliberate: it shows
the two styling approaches coexisting, which is what a real shadcn project looks like.

## Guardrails

- **Never run `create-tauri-app` or copy from it.** Its Svelte template is SvelteKit. This
  is the single most likely way to silently violate the stack contract.
- **Never scaffold inside the harness.** The harness is reusable across many apps; an app
  living in it corrupts that.
- **Do not swap the package manager or the build tool.** npm and Vite are what the template
  and every skill assume.
- **Do not add Tailwind or shadcn by hand to a plain-CSS app.** The overlay encodes a
  cascade-order arrangement that is not obvious and fails silently when got wrong — see the
  header comment in `template-shadcn/src/app.css`. Re-scaffold with `--shadcn` and move the
  source across, or copy the overlay files verbatim.
- **Do not choose the frontend path on the user's behalf.** It is fixed at scaffold time.
- **Do not "upgrade" the pinned TypeScript.** `~6.0.2` is deliberate; `typescript@7` ships
  no `tsserver.js` and breaks `svelte-check`.
- **Do not report success on a partial verification.** If `cargo check` could not run, say
  which half was verified and which was not.
