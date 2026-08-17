---
name: consult-docs
description: Search the offline akb knowledge base for an authoritative answer from the official Tauri or Svelte documentation, or from curated example projects, before writing code. Use whenever a question touches a Tauri or Svelte API, when an API behaves unexpectedly, when the user says "check the docs", "how does X work in Tauri", "what's the Svelte 5 way to do X", or invokes /consult-docs.
---

# Consult the official documentation

Answer from the indexed docs, with a `path:line` citation, or say that the docs do not
cover it. Never from memory: Tauri 2 and Svelte 5 both broke from their predecessors and
recalled idiom is usually the old one.

Done means: every API claim in the answer traces to a chunk actually retrieved, and the
code written afterwards matches what that chunk says.

## Collections

| Collection | Holds | Ask it about |
|---|---|---|
| `tauri` | Official Tauri 2 documentation | config, commands, capabilities and permissions, plugins, windows, bundling, mobile, the JS API |
| `svelte` | Official Svelte 5 documentation and CLI docs | runes, components, snippets, transitions, bindings, `svelte/*` modules, compiler options |
| `tauri-examples` | The user's curated example projects in `examples/`, indexed with `--with-code` | how a real project wires something together |
| `shadcn-svelte` | **Optional.** Present only if the user indexed it | shadcn-svelte components, their props, theming and CLI |

If an app uses shadcn-svelte (`components.json` at its root) and no `shadcn-svelte`
collection exists, say so before answering. The docs are also served as plain Markdown, one
file per page, which is a reasonable fallback when the machine is online:

```bash
curl -sSL https://shadcn-svelte.com/docs/components/dialog.md
curl -sSL https://shadcn-svelte.com/llms.txt          # index of every page
```

Prefer the indexed collection when it exists — it is offline, faster, and citable by
`path:line` like everything else.

## Process

**1. Pick the collection.** Rust and native-shell questions go to `tauri`; component and
reactivity questions go to `svelte`; "how is this normally wired up" goes to
`tauri-examples`. Query several with repeated `-c` flags when the question spans the
boundary — `invoke` from a Svelte component is both.

**2. Keyword first.** It never loads torch, so it returns in about a fifth of a second
against roughly three seconds for hybrid:

```bash
akb query "capability permission window" -c tauri --mode keyword --json -k 5
```

Use the exact API identifiers as terms — `generate_handler`, `mobile_entry_point`,
`$derived.by`, `frontendDist`. Keyword search rewards precise names and punishes prose.

**3. Escalate only if that was thin.** Fewer than two relevant hits, or a conceptual
question ("when should state live in Rust rather than the frontend"), justifies the default
hybrid mode. Do not reach for it first out of habit.

**4. Read the winner in full.** Chunks are 256 tokens and routinely cut mid-procedure:

```bash
akb get <rel_path> -c tauri            # whole document
akb query "…" -c tauri --expand 1      # or widen the window in place
```

**5. Answer with citations.** Quote or paraphrase, then give the `location` field verbatim
(`<path>:<line>`). If the retrieved text does not actually answer the question, say so and
say what you searched — an unsupported answer is worse than a gap.

## Filters worth knowing

```bash
akb query "invoke" -c tauri --lang typescript   # chunks whose code block is TypeScript
akb query "capabilities" -c tauri --code        # only chunks containing code
akb query "runes" -c svelte --heading "Reference"
akb query "permissions" -c tauri --path '*security*'
akb query "greet" -c tauri-examples --no-text   # locations only, for a quick survey
```

`references/query-recipes.md` has starting queries for the questions that come up most.

## Guardrails

- **A missing collection is a stop, not a fallback.** If `akb collections` does not list the
  one needed, tell the user which is missing and how to build it. Answering from memory
  because the index is absent is the exact failure this harness exists to prevent.
- **Never cite a location you did not retrieve.** Fabricating a plausible doc path is worse
  than admitting the search failed.
- **Do not trust a hit's version.** Docs sets contain migration pages describing v1 and
  Svelte 4 behaviour in order to contrast it. Read enough surrounding text to know which
  version the passage is describing.
- **`tauri-examples` is community code, not specification.** It shows one way something was
  done, possibly on a different frontend stack and possibly out of date. Where an example
  and the official docs disagree, the docs win.
- **Do not ingest or modify collections.** The user curates them; the harness only reads.
