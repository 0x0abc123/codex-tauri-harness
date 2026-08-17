# examples/

Reference Tauri projects you curate. **Read-only** for the agent: search them, quote them,
copy patterns out of them — never edit them, and never build in them.

Nothing is vendored here by default. What you put in is what the agent sees.

## Adding an example

```bash
git clone --depth 1 <url> examples/<short-name>
rm -rf examples/<short-name>/.git        # avoid a nested repository
```

Then index it so the agent can search it semantically:

```bash
akb ingest examples --collection tauri-examples --with-code
```

`--with-code` is what makes the Rust and Svelte sources searchable rather than just the
READMEs. Re-running is incremental: unchanged files cost nothing, changed files are
re-chunked, and deleted ones are pruned.

Then note what each project is for in `INDEX.md` beside this file — one line per project,
covering the stack it actually uses. The agent reads that before assuming anything:

```markdown
- `tauri-api-example/` — official; vanilla JS frontend; broad plugin and IPC surface
- `notes-app/` — real app; Svelte 5 + TS; SQLite via tauri-plugin-sql; Android target
- `old-dashboard/` — Svelte 4, Tauri 1. Useful for architecture only; APIs are stale.
```

## What examples are and are not

They show **one way** something was done, in one project, at one point in time. They are not
specification. Where an example and the official documentation disagree, the documentation
wins — see the `consult-docs` skill.

Most Tauri examples in the wild are on a different stack from this harness: React,
SvelteKit, Svelte 4, or Tauri 1. That does not make them useless — architecture, ACL wiring
and mobile configuration transfer fine — but code copied without checking the version will
not compile, or worse, will compile and behave differently. Record the stack in `INDEX.md`
so the agent knows before it copies.

## Searching them

```bash
akb query "invoke typed command" -c tauri-examples --lang typescript --json -k 8
akb query "tauri::command" -c tauri-examples --code --json -k 8
akb query "sqlite" -c tauri-examples --no-text --json -k 10   # which projects touch it
```

## Housekeeping

Examples are heavy — `node_modules` and `target/` in particular. `akb` skips those
directories when indexing, but they still cost disk here, so prefer shallow clones and
delete build output. If this directory is inside a git repository, consider ignoring it and
keeping only `README.md` and `INDEX.md` tracked.
