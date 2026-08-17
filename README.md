# codex-tauri-harness

An agent harness for building **Tauri 2 cross-platform desktop and mobile applications**
with **vanilla Svelte 5 + TypeScript** frontends on Vite.

This repository is instructions, skills, scripts and a verified starter template. It is not
an application, and apps built with it live in their own directories elsewhere.

Any agent that reads `AGENTS.md` and `.agents/skills/` can drive it — Codex CLI is the
target; Claude Code reads the same files.

## Why

Agents building on this stack fail in three predictable ways, and the harness answers each:

1. **Plausible, wrong API code.** Tauri 2 replaced the v1 allowlist with capabilities;
   Svelte 5 replaced stores and `on:click` with runes. Model priors are saturated with the
   old idiom. → `akb` is the source of truth, consulted before writing and cited by
   `path:line`.
2. **Decorative rather than usable interfaces.** → `docs/ui-design-principles.md` is
   normative, enforced by a design skill, a component skill and an audit script.
3. **Scaffolding re-derived and subtly broken every time.** → a verified `template/` that
   the scaffold skill copies out.

## Two frontend paths

Chosen once, at scaffold time. Both take their colours from the same `src/app.css` tokens
and both are held to `docs/ui-design-principles.md`.

| | Plain CSS (default) | `--shadcn` |
|---|---|---|
| Styling | Design tokens + scoped `<style>` blocks | The same tokens, plus Tailwind CSS 4 utilities mapped onto them |
| Components | Hand-written; four worked patterns ship with the harness | `shadcn-svelte` components added on demand with `npm run ui add` |
| Suits | Small or highly custom UIs, minimal dependencies | Apps needing dialogs, tables, comboboxes, date pickers |

`components.json` at an app's root is how every skill tells which path it is on.

On the shadcn path the token layer stays the single source of truth: shadcn's utilities are
mapped onto our tokens through `@theme inline`, so `bg-primary` resolves to `var(--accent)`
and retheming is still one edit. `shadcn-svelte init` is never run — it would overwrite
`src/app.css` — so the overlay pre-writes everything it would have generated. See
`template-shadcn/README.md`.

## Prerequisites

Run the check first; it reports and installs nothing:

```bash
bash scripts/doctor.sh
```

**Hard requirements**

- `node` and `npm`
- `cargo` and `rustc` — via [rustup](https://rustup.rs)
- [`agent-kb`](./docs/akb.md) on `PATH` as `akb`, with three collections indexed:
  **`tauri`**, **`svelte`**, **`tauri-examples`**

The three collections are assumed to exist; the harness reads them and never ingests. Point
them at the official Tauri and Svelte documentation, and at whatever you put in `examples/`
(see `examples/README.md`).

**Optional, for mobile**

Android Studio with the SDK and NDK plus `JAVA_HOME`/`ANDROID_HOME`/`NDK_HOME`; Xcode and
CocoaPods on macOS for iOS; the Rust cross-compilation targets for both. `doctor.sh` lists
exactly which are missing.

## Use

Start an agent in this directory and describe the app. It will route through the skills
itself; you can also name one directly.

```
> scaffold a new app called Field Notes in ../field-notes
> design the interface for a note list with a search field
> add a command that saves a note to disk
> run it on Android
> review the UI
```

## What is here

```
AGENTS.md                     the contract: stack, tools, rules, gotchas, skill routing
docs/ui-design-principles.md  normative UI specification
docs/akb.md                   the knowledge-base tool's documentation
template/                     verified Tauri 2 + Svelte 5 + TS starter
template-shadcn/              overlay adding Tailwind 4 + shadcn-svelte + token bridge
examples/                     your curated reference projects (read-only)
scripts/doctor.sh             prerequisite check
.agents/skills/               seven skills
```

| Skill | For |
|---|---|
| `consult-docs` | Any Tauri or Svelte API question, before the code is written |
| `scaffold-app` | Creating a new app from `template/` |
| `design-ui` | Palette, type, layout — planned before it is built |
| `build-component` | Writing Svelte 5 components that are accessible by construction |
| `tauri-ipc` | Rust commands, typed wrappers, capability permissions |
| `mobile-target` | Android and iOS: init, device dev, native permissions, layout |
| `review-ui` | Auditing an interface against the specification |

Three skills ship an executable check, usable on their own:

```bash
bash scripts/doctor.sh
bash .agents/skills/tauri-ipc/scripts/check-acl.sh <app>/src-tauri
bash .agents/skills/review-ui/scripts/ui-audit.sh <app>/src <app>/index.html
node .agents/skills/design-ui/scripts/contrast.mjs --tokens <app>/src/app.css
```

## Verifying the harness itself

Everything below was run against this tree except where noted.

```bash
bash scripts/doctor.sh                                          # honest failure list
.agents/skills/scaffold-app/scripts/new-app.sh /tmp/probe "Probe App"
cd /tmp/probe && npm install && npm run check && npm run build   # 0 errors, 0 warnings
bash .agents/skills/review-ui/scripts/ui-audit.sh template/src template/index.html
bash .agents/skills/tauri-ipc/scripts/check-acl.sh template/src-tauri
node .agents/skills/design-ui/scripts/contrast.mjs --tokens template/src/app.css

# and the shadcn path, end to end
.agents/skills/scaffold-app/scripts/new-app.sh /tmp/probe2 "Probe Two" --shadcn
cd /tmp/probe2 && npm install && npm run ui add button -y && npm run check && npm run build
```

The Rust half needs a toolchain and has not been run here:

```bash
cd /tmp/probe/src-tauri && cargo check
cd /tmp/probe && npm run tauri dev        # the greet form should round-trip
```

## Extending it

Skills are plain directories under `.agents/skills/<name>/` with a `SKILL.md` carrying
`name` and `description` frontmatter, optionally `scripts/` and `references/`. Follow the
existing shape: a **Process** of numbered steps and a **Guardrails** list of the things that
fail quietly. Add the skill to the routing tables in `AGENTS.md` and here.
