# codex-tauri-harness

A harness for building **Tauri 2 cross-platform desktop and mobile applications** with
**vanilla Svelte 5 + TypeScript** frontends on Vite.

**This repository is the harness, not an application.** Apps are created from `template/`
into their own directory outside this tree — ask the user where, and default to a sibling
directory. Never scaffold an app inside the harness.

## Stack

Fixed. A request that implies changing a row is a request to change this file first.

| Layer | Use | Never |
|---|---|---|
| Shell | Tauri 2 (`tauri.conf.json` `$schema: .../config/2`) | Tauri 1 config keys or the v1 allowlist |
| Frontend | Vanilla Svelte 5 with runes, on Vite | SvelteKit, `@sveltejs/kit`, file-system routing |
| Language | TypeScript, strict, `~6.0.2` | JavaScript components, `any` to silence a checker |
| IPC | `@tauri-apps/api/core` + typed wrappers in `src/lib/ipc.ts` | `window.__TAURI__`, raw `invoke` in components |
| Styling | Design tokens in `src/app.css` — always the source of truth | CSS-in-JS, a second token system, hard-coded colours or sizes |
| Components | Plain CSS by default; **shadcn-svelte on Tailwind 4 if the app was scaffolded `--shadcn`** | Any other component or CSS framework; mixing in a second one |

An app is on one of two frontend paths, fixed at scaffold time. Check which before writing
any UI: **`components.json` at the app root means shadcn-svelte is available.** On the plain
path there is no Tailwind, so a utility class does nothing at all — silently.

## Tools

**`akb`** — offline knowledge base over the official docs. Three collections are expected to
exist on this machine: **`tauri`**, **`svelte`**, **`tauri-examples`**. The harness never
ingests them; `scripts/doctor.sh` verifies them. If one is missing, say so and stop — do not
answer from memory in its place.

```bash
akb query "<question>" -c tauri --mode keyword --json -k 5   # start here: ~0.2s
akb query "<question>" -c svelte --json -k 5                 # hybrid; ~3s (torch import)
akb get <rel_path> -c tauri                                  # read the winning document
```

Keyword mode never loads torch and is roughly ten times faster. Escalate to the default
hybrid mode only when keyword results are thin or the question is conceptual.

**`npm`** for the frontend. **`npm run tauri …`** for the Tauri CLI — never a global `tauri`,
which drifts from the project's pinned `@tauri-apps/cli`.

## Rules

1. **Consult `akb` before writing any Tauri or Svelte API code, and cite `path:line`.** Both
   frameworks broke hard from their predecessors and model priors are saturated with the old
   idiom. An uncited API claim is a guess.
2. **`docs/ui-design-principles.md` is normative.** It outranks aesthetic preference and any
   "looks nicer" argument. Where a request conflicts with it, follow the spec and say what
   the trade-off was.
3. **`template/` is the pattern source.** New features copy the shapes already proven there —
   the typed IPC wrapper, the token layer, the visible-state form — rather than inventing a
   second way to do the same thing.
4. **`examples/` is read-only reference.** Search it and quote from it; never edit it, and
   never assume an example is on this stack — most Tauri examples in the wild are React,
   SvelteKit, or Svelte 4. Check before copying.
5. **Never introduce SvelteKit** or any dependency that pulls it in.
6. UI copy and documentation use **British English**.

## Gotchas

Each of these is verified and each fails quietly if ignored.

- **The official Tauri Svelte template is SvelteKit.** `create-tauri-app`'s
  `template-svelte-ts` ships `src/routes/+page.svelte`, `app.html` and `svelte.config.js`
  with the kit plugin. Do not run `create-tauri-app` and do not copy from it. `template/`
  here is create-vite's vanilla `template-svelte-ts` joined to Tauri's `_base_/src-tauri`.
- **Svelte 5 is not Svelte 4.** `onclick` not `on:click`; `$props()` not `export let`;
  `$state`/`$derived` not `let` + `$:`; `mount(App, …)` not `new App(…)`; `{@render
  children()}` not `<slot>`. Older blog posts and most examples predate this.
- **Template narrowing over runes is fragile.** Narrow a discriminated union into a
  `$derived` and test that, rather than narrowing `status.kind === 'x'` inside the markup.
- **The ACL governs plugin and core commands, not your own.** An app command needs only
  `#[tauri::command]` plus registration in `generate_handler!`. A *plugin* command is denied
  at runtime until a capability grants it — installing the plugin and calling
  `.plugin(…::init())` is not enough. Run
  `.agents/skills/tauri-ipc/scripts/check-acl.sh <app>/src-tauri` after touching either side.
- **A command in `lib.rs` must not be `pub`.** The glue-code macro collides with itself and
  the build fails with `error[E0255]: the name __cmd__<name> is defined multiple times`,
  which does not mention the `pub` that caused it.
- **Commands that create webview windows must be async.** Tauri runs a command
  without `async` on the main thread. On Windows, synchronously calling
  `WebviewWindowBuilder::build()` from an invoked command can deadlock WebView2 while it
  handles the new window's resource request. The symptom is a blank detached window that
  cannot close and eventually hangs the whole application; a dump can show
  `EmbeddedBrowserWebView!FireWebResourceRequestedEvent` together with
  `NtUserDestroyWindow`. Declare the command `async fn` (or use
  `#[tauri::command(async)]`) and keep its arguments owned where possible. This is about
  the command execution context, even when the builder call itself appears quick.
- **Desktop and mobile capabilities use different generated schemas** (`desktop-schema.json`
  vs `mobile-schema.json`), and a capability without a `platforms` key applies everywhere.
- **Mobile depends on two lines in `Cargo.toml` and one attribute.** `[lib] crate-type =
  ["staticlib", "cdylib", "rlib"]` and `#[cfg_attr(mobile, tauri::mobile_entry_point)]` on
  `run()`. Builder setup placed in `main()` instead of `run()` exists on desktop only.
- **`app.security.csp` applies to bundled builds, not to the dev server.** Tauri serves the
  header from its own protocol handler; under `tauri dev` the Vite dev server answers
  instead. A CSP mistake therefore appears as a blank window in production only.
- **TypeScript is pinned to `~6.0.2` on purpose.** `typescript@7` is the native rewrite and
  ships no `tsserver.js`, which breaks both `svelte-check` and TypeScript language servers.
  Never bump it to `^7` or install TypeScript globally to "fix" a language server.
- **`invoke` arguments are camelCase on the JS side and snake_case in Rust**, and returned
  structs only reach TypeScript in camelCase if they carry `#[serde(rename_all =
  "camelCase")]`. Neither compiler catches a mismatch.
- **v1 config keys silently do nothing in v2**: `devPath` → `devUrl`, `distDir` →
  `frontendDist`, `tauri.bundle` → `bundle`, and `tauri.allowlist` is gone entirely,
  replaced by capabilities.
- **`@tauri-apps/api` v2 import paths changed.** `@tauri-apps/api/core` holds `invoke`; the
  v1 `@tauri-apps/api/tauri` path no longer exists.

### On the shadcn-svelte path

- **Exclude Svelte virtual style modules from Tailwind's transform filter.** In dev mode,
  Svelte emits every component `<style>` block as a virtual
  `*.svelte?svelte&type=style&lang.css` module. Without the exclusion already implemented in
  `template-shadcn/vite.config.ts`, Tailwind's pre-transform can receive the component source
  instead of CSS and report Svelte declarations such as `onMount`, imports, or `{#if ...}` as
  `Invalid declaration`. Keep Tailwind before Svelte, create its plugin array once, append
  `/\.svelte\?svelte&type=style/` to each transform filter's `id.exclude`, and spread that
  filtered array into `plugins`. Do not replace this with a bare
  `plugins: [tailwindcss(), svelte()]`. Component styles use ordinary scoped CSS and design
  tokens; global `src/app.css` remains processed by Tailwind.
- **Never run `shadcn-svelte init`.** It asks for the global CSS file and then overwrites
  it — that file is `src/app.css`, the whole design-token layer. Everything `init` writes is
  already in place, so only `npm run ui add <component>` is ever needed. If someone runs it,
  restore `src/app.css` from `template-shadcn/`.
- **shadcn's `accent` is not our `accent`.** Theirs is a subtle hover background; ours is the
  primary action colour, which they call `primary`. The `@theme inline` block in `app.css`
  maps between them; never "correct" it to line the names up.
- **Tailwind's `--radius-*` and `--text-*` theme namespaces are the same names as our
  tokens.** That is why `rounded-lg` and `text-xl` follow our scale — the `:root` blocks are
  unlayered and beat Tailwind's `@layer theme`. Keep them unlayered and after the import.
- **Base element styles must stay inside `@layer base` on this path.** Unlayered, they beat
  Tailwind's utilities: `button { font: inherit }` silently overrides shadcn's `text-sm`.
  This is why the shadcn `app.css` drops the `:where()` wrapper the plain one uses.
- **`$lib` is declared in three files that must agree** — `vite.config.ts`,
  `tsconfig.json`, `tsconfig.app.json`. SvelteKit supplies it for free; vanilla Vite does
  not, and every generated component imports through it.
- **Do not add `baseUrl` to the tsconfigs**, though the shadcn docs tell you to. It is
  deprecated in TypeScript 6 and warns on every `svelte-check` run; `paths` alone works.
- **shadcn components are your code**, copied in, not a dependency. Edit them freely — but
  `npm run ui add -o <name>` overwrites local edits.

## Skills

`.agents/skills/` — invoke by name, or let the trigger phrase in each skill's description
route the request.

| When | Skill |
|---|---|
| Any Tauri or Svelte API question, before writing the code | **consult-docs** |
| Starting a new app | **scaffold-app** |
| A new screen, or the app's visual language | **design-ui** |
| Writing or changing a `.svelte` component | **build-component** |
| A frontend action that needs Rust, or a permissions error | **tauri-ipc** |
| Android or iOS targets, device testing, mobile-only bugs | **mobile-target** |
| Before calling a UI finished | **review-ui** |

## Layout

```
AGENTS.md              this file
docs/
  ui-design-principles.md   normative UI specification
  akb.md                    the knowledge-base tool's own documentation
template/              the verified starter, copied out by scaffold-app
template-shadcn/       overlay applied on top of it when scaffolding with --shadcn
examples/              user-curated reference projects (read-only, see examples/README.md)
scripts/doctor.sh      preconditions check
.agents/skills/        the seven skills
```
