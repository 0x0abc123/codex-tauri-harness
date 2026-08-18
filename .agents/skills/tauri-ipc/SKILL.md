---
name: tauri-ipc
description: Add or change a Rust command and its typed TypeScript wrapper, wire shared state and events, and grant the capability permissions a plugin needs. Use when a frontend action needs the filesystem, the network, the OS or any native capability, when an invoke call fails with a "not allowed" error, when the user says "add a command", "call Rust from the frontend", "the plugin is denied", or invokes /tauri-ipc.
---

# Wire the frontend to Rust

A backend capability lands in one atomic change: the Rust command, its registration, the
typed wrapper, the caller, and any permission a plugin needs. A change that stops halfway
compiles and fails at runtime.

Done means: `cargo check` compiles, `npm run check` is clean, `scripts/check-acl.sh` reports
no drift, and the call has been exercised at least once in a running app.

## What the ACL actually gates

This is the part that is most often got wrong.

- **Your own commands need no permission.** `#[tauri::command]` plus a place in
  `generate_handler!` makes a command callable. There is nothing to add to a capability.
- **Plugin and core commands are denied until a capability grants them.** Adding the crate
  and calling `.plugin(tauri_plugin_x::init())` is not enough; the frontend call fails at
  runtime with a not-allowed error naming the command.
- Grant the narrowest thing that works: `x:allow-<command>` in preference to `x:default`
  when only one command is used.

```bash
.agents/skills/tauri-ipc/scripts/check-acl.sh src-tauri
```

Run that after touching commands, the builder or a capability. It reports commands that are
defined but unregistered, registered but undefined, declared `pub` (which fails to build),
plugins with no grant, and grants for plugins that are not installed.

## Process

**1. Decide it belongs in Rust.** Native access, secrets, heavy computation, or work that
must survive a window reload belong in Rust. Anything the webview can do perfectly well
should stay in the frontend — an IPC hop costs latency and a serialisation boundary.

**2. Check the API.** `consult-docs` against `-c tauri` before writing. Command signatures,
state access and error handling all changed in v2.

**3. Write the command** in `src-tauri/src/lib.rs` (or a module it declares):

```rust
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]   // without this, snake_case reaches TypeScript
pub struct Note {
    id: String,
    created_at: u64,
}

#[tauri::command]                     // never `pub fn` in lib.rs — E0255
async fn save_note(body: String, state: tauri::State<'_, Db>) -> Result<Note, String> {
    …
}
```

- `Result<T, E>` where `E: Serialize`. `String` is fine for one or two failure modes; past
  that, an enum deriving `Serialize` (usually via `thiserror` plus a manual `Serialize`)
  gives the frontend something it can branch on.
- An `async` command taking `State` needs the `'_` lifetime, as above.
- Shared state goes in `.manage(…)` at startup and arrives as `tauri::State<'_, T>`. Use
  interior mutability (`Mutex`, `RwLock`) — `State` hands out a shared reference.
- Long work must not block: make the command `async`, or move it to
  `tauri::async_runtime::spawn_blocking`, and report progress with an event.
- A command that creates a webview window must be `async`. Tauri executes a non-async
  command on the main thread; on Windows, invoking `WebviewWindowBuilder::build()` there
  can deadlock WebView2's resource-request callback and leave a blank, uncloseable window
  while the application hangs. Prefer owned command arguments because async commands
  cannot accept borrowed arguments without a workaround.

**4. Register it** in `generate_handler![…]` inside `run()`, not in `main()`.

**5. Add the typed wrapper** to `src/lib/ipc.ts` — one exported function per command, no
exceptions:

```ts
export interface Note {
  id: string
  createdAt: number
}

export async function saveNote(body: string): Promise<Note> {
  return await invoke<Note>('save_note', { body })
}
```

The command name is the Rust function name as a string. Argument *keys* are camelCase here
and snake_case in Rust; Tauri converts them. Nothing checks that the TypeScript interface
matches the Rust struct, so change them in the same edit, always.

**6. Call it from a component** through the wrapper, with all four states visible — see
`src/lib/GreetForm.svelte`. Never `invoke` directly from a component.

**7. Verify**: `cargo check`, `npm run check`, `check-acl.sh`, then run it.

## Events, when a command will not do

Commands are request/response. For progress, streaming or backend-initiated updates, emit
from Rust and listen in the frontend — and unlisten in the `$effect` cleanup, or the
listener leaks across navigations:

```ts
$effect(() => {
  const stop = listen<Progress>('import://progress', (e) => (progress = e.payload))
  return () => void stop.then((unlisten) => unlisten())
})
```

## Adding a plugin

1. `cargo add tauri-plugin-x` in `src-tauri`, and `npm i @tauri-apps/plugin-x` if it has a
   JS API.
2. `.plugin(tauri_plugin_x::init())` in `run()`.
3. Grant `x:default` (or narrower) in `src-tauri/capabilities/default.json`.
4. `check-acl.sh` to confirm, then exercise it.

Mobile plugins may also need entries in the Android manifest or `Info.plist` — that is
`mobile-target`'s territory.

## Guardrails

- **Never widen a capability to make an error go away.** Read which command was denied and
  grant exactly that. `"permissions": ["core:default", "fs:default"]` added blindly is how
  an app ends up with filesystem access it never uses.
- **Never expose a command that takes a path or a shell string from the frontend without
  validating it in Rust.** The webview is the untrusted side of this boundary; a command is
  an API, not a private function.
- **Never mark a command `pub` in `lib.rs`.** The build error names a macro, not the cause.
- **Never leave the TypeScript wrapper and the Rust signature edited apart.** No compiler
  spans the gap.
- **Never put builder setup in `main()`.** It must be in `run()` or mobile silently loses it.
- **Never build a webview window in a synchronous invoked command.** Make the command async
  and include a detached-window open/close test on Windows. A successful Linux test does
  not exercise WebView2 or rule out this deadlock.
- **Do not swallow errors into `unwrap()`.** A panic in a command takes the whole app down;
  return the error and let the UI explain it.
