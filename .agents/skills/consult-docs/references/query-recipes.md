# Query recipes

Starting points, not incantations. Adjust the terms; keep the collection and the mode.

## Tauri

```bash
# Commands and IPC
akb query "command invoke_handler generate_handler" -c tauri --mode keyword --json -k 5
akb query "async command State managed" -c tauri --mode keyword --json -k 5
akb query "command error Result serialize" -c tauri --json -k 5

# Capabilities, permissions, the ACL
akb query "capability permissions window identifier" -c tauri --mode keyword --json -k 5
akb query "permission denied not allowed capability" -c tauri --json -k 5
akb query "platforms android ios capability" -c tauri --mode keyword --json -k 5

# Configuration
akb query "frontendDist devUrl beforeDevCommand" -c tauri --mode keyword --json -k 5
akb query "content security policy csp" -c tauri --json -k 5
akb query "window label title decorations" -c tauri --mode keyword --json -k 5

# Events and state
akb query "emit listen event payload" -c tauri --mode keyword --json -k 5
akb query "Manager state Mutex shared" -c tauri --json -k 5

# Plugins
akb query "plugin init permissions default" -c tauri --mode keyword --json -k 5
akb query "tauri-plugin-store persist" -c tauri --mode keyword --json -k 5

# Mobile
akb query "android init dev TAURI_DEV_HOST" -c tauri --mode keyword --json -k 5
akb query "ios development team signing" -c tauri --mode keyword --json -k 5
akb query "android permissions manifest" -c tauri --mode keyword --json -k 5

# Distribution
akb query "bundle targets appimage dmg msi" -c tauri --mode keyword --json -k 5
akb query "updater signing key" -c tauri --json -k 5
```

## Svelte

```bash
# Runes
akb query "$state $derived $effect" -c svelte --mode keyword --json -k 5
akb query "$props bindable children" -c svelte --mode keyword --json -k 5
akb query "$derived.by expensive computation" -c svelte --json -k 5
akb query "$state.raw deep reactivity proxy" -c svelte --json -k 5

# Components
akb query "snippet render children" -c svelte --mode keyword --json -k 5
akb query "component events callback props" -c svelte --json -k 5
akb query "bind:value bind:this" -c svelte --mode keyword --json -k 5

# Shared state outside components
akb query "svelte.js state class shared module" -c svelte --json -k 5

# Lists, transitions, actions
akb query "each key block" -c svelte --mode keyword --json -k 5
akb query "transition in out reduced motion" -c svelte --json -k 5
akb query "use action directive" -c svelte --mode keyword --json -k 5

# TypeScript
akb query "typescript component props interface" -c svelte --json -k 5
akb query "svelte-check errors" -c svelte --mode keyword --json -k 5
```

## shadcn-svelte (optional collection)

```bash
akb query "dialog trigger portal" -c shadcn-svelte --mode keyword --json -k 5
akb query "theming css variables" -c shadcn-svelte --json -k 5
akb query "data table sorting" -c shadcn-svelte --mode keyword --json -k 5
akb query "form field validation" -c shadcn-svelte --json -k 5
akb query "components.json aliases" -c shadcn-svelte --mode keyword --json -k 5
```

If the collection does not exist, the same pages are plain Markdown over HTTP:

```bash
curl -sSL https://shadcn-svelte.com/llms.txt                       # page index
curl -sSL https://shadcn-svelte.com/docs/components/<name>.md      # one component
```

Component behaviour questions ("how does the dialog trap focus") usually belong in
`bits-ui`'s documentation rather than shadcn's — shadcn styles the primitives, `bits-ui`
implements them.

## Examples

```bash
# What does a real project do?
akb query "invoke" -c tauri-examples --lang typescript --json -k 8
akb query "tauri::command" -c tauri-examples --code --json -k 8
akb query "capabilities permissions" -c tauri-examples --json -k 5

# Survey which projects touch a topic at all, cheaply
akb query "sqlite" -c tauri-examples --no-text --json -k 10
```

## Cross-cutting

```bash
# A question that spans both frameworks
akb query "call rust command from component" -c tauri -c svelte --json -k 6
```

A semantic or hybrid query spanning collections built with different embedding models is
refused by `akb`. If that happens, query them one at a time.
