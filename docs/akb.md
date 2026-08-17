# agent-kb

A local, fully offline knowledge base for AI coding agents. Point it at a tree
of documentation, and any agent that can run a shell command gets semantic,
keyword, or hybrid search over it with structured JSON output.

Built for framework documentation — the chunker understands headings and code
fences, and every result carries its breadcrumb (`React > Hooks > useEffect`)
and a `path:line` location — but nothing in it is specific to software docs.

```console
$ akb ingest ~/src/react/docs --collection react
✓ indexed 412 files (3,180 chunks) into react in 24.3s

$ akb query "how do I skip an effect until a value changes" -c react -k 3
 1  0.0323  react · Using the Effect Hook > Optimizing Performance
    ~/src/react/docs/hooks-effect.md:284
    You can tell React to skip applying an effect if certain values haven't
    changed between re-renders. To do so, pass an array as an optional second
    argument to useEffect …
```

## Why these choices

| Decision | Reason |
|---|---|
| SQLite + a raw `float32` file | One dependency (numpy). Exact search, not approximate. Both indexes live in one transaction so they cannot drift. Inspectable with any `sqlite3` client. |
| Brute-force cosine over `mmap` | Measured 4.7 ms at 100k chunks and 61 ms at 1M on two cores. An ANN index buys nothing at documentation scale and costs exact recall. |
| `float32`, not `float16`/`int8` | Measured **17× slower** at 100k chunks — numpy has no BLAS path for either and upcasts elementwise. Halving the file is not worth 80 ms. |
| FTS5 BM25 for keywords | Built into stdlib SQLite. Reciprocal Rank Fusion combines it with vectors without needing the two score scales to be comparable. |
| 256-token chunks | `all-MiniLM-L6-v2` truncates at 256 word-pieces. Larger chunks silently drop text from the embedding. Use `--expand` to widen context at read time instead. |

## Install

Requires [uv](https://docs.astral.sh/uv/) and Python 3.10+.

```bash
uv tool install . --torch-backend cpu
```

`--torch-backend cpu` matters: without it, uv resolves the CUDA build of torch
and pulls roughly 500 MB of `nvidia-*` wheels you will never use on CPU.

Then download the embedding model once, so every later run is fully offline:

```bash
akb model --download
akb doctor --probe
```

Both `akb` and `agent-kb` are installed as commands.

Measured footprint: **1.1 GB** for the tool environment (695 MB of that is CPU
torch, unpacked) plus **88 MB** for the cached model. agent-kb's own
dependencies are numpy and sentence-transformers; everything else is torch's
transitive closure.

## Use

### Ingest

```bash
akb ingest ./docs                             # into the "default" collection
akb ingest ~/src/django/docs -c django        # named collection per framework
akb ingest ./docs ./guides ./README.md -c mix # several roots at once
akb ingest ./repo -c repo --with-code         # index source files too
akb ingest ./site -c site --include '*.html'
akb ingest ./docs -c docs --dry-run           # see what would be indexed
```

Re-running is incremental. Each file is keyed on `sha256(content)` plus a
fingerprint of the chunker settings, so unchanged files cost nothing, changed
files are re-chunked, and files that disappeared are pruned from the index.
Changing `--chunk-tokens` correctly invalidates everything, because the
fingerprint changes.

```console
$ akb ingest ~/src/react/docs -c react
✓ indexed 3 files (24 chunks) into react in 0.9s
  409 unchanged, 0 skipped, 1 pruned, 31 chunks replaced/removed
```

Recognised out of the box: Markdown/MDX, HTML, reStructuredText, Jupyter
notebooks, and plain text; `--with-code` adds ~50 source languages;
`--all-text` attempts anything that is not binary. Directories like
`node_modules`, `.git`, `dist` and `.venv` are skipped by default, as are
lockfiles and minified bundles.

### Query

```bash
akb query "how do I memoize an expensive computation" -c react
akb query "useEffect cleanup" --mode keyword          # exact BM25 terms
akb query "state management" --mode semantic          # meaning only
akb query "middleware" -c django -c fastapi           # across collections
akb query "auth" -c all                               # every collection
```

Filters and context:

```bash
akb query "router" --lang typescript      # chunks whose code is TypeScript
akb query "install" --code                # only chunks containing code
akb query "hooks" --heading "Reference"   # breadcrumb contains "Reference"
akb query "config" --path '*guides*'      # path glob
akb query "signals" --expand 1            # stitch neighbouring chunks in
```

`--mode hybrid` (the default) runs both retrievers and fuses them with
Reciprocal Rank Fusion. Weight the halves with `--w-vector` / `--w-keyword`.

### For agents

Every command takes `--json`:

```console
$ akb query "useEffect dependencies" -c react -k 2 --json
{
  "query": "useEffect dependencies",
  "mode": "hybrid",
  "collections": ["react"],
  "count": 2,
  "elapsed_ms": 41.2,
  "results": [
    {
      "collection": "react",
      "score": 0.0328,
      "path": "/home/you/src/react/docs/hooks-effect.md",
      "rel_path": "hooks-effect.md",
      "title": "Using the Effect Hook",
      "heading_path": "Using the Effect Hook > Optimizing Performance",
      "location": "/home/you/src/react/docs/hooks-effect.md:284",
      "lines": [284, 301],
      "format": "markdown",
      "lang": "js",
      "has_code": true,
      "chunk_id": 918,
      "doc_id": 44,
      "ord": 12,
      "vector_score": 0.6142,
      "keyword_score": 8.31,
      "vector_rank": 2,
      "keyword_rank": 1,
      "text": "..."
    }
  ]
}
```

`location` is `path:line`, ready to hand to an editor. Follow a hit with
`akb get <path> -c <collection>` to read the whole document, or add `--expand N`
to the query to widen the returned window. `--no-text` drops chunk bodies when
you only want locations.

A CLAUDE.md entry that works well:

```markdown
Framework docs are indexed in agent-kb. Before answering questions about
React or Django, search it:
  akb query "<question>" -c react --json -k 5
Then read the full document for the best hit:
  akb get <rel_path> -c react
```

### Manage

```bash
akb collections            # what exists, how big
akb stats -c react         # formats, languages, chunk sizes, disk use
akb docs -c react --match '*hooks*'
akb get hooks-effect.md -c react
akb rm '*deprecated*' -c react
akb compact -c react       # reclaim space from deleted vectors
akb reindex -c react       # re-embed everything (after a model change)
akb drop react --yes
akb doctor --probe
```

## Configuration

| Variable | Default | Meaning |
|---|---|---|
| `AGENT_KB_HOME` | `~/.local/share/agent-kb` | Where collections live |
| `AGENT_KB_MODEL` | `sentence-transformers/all-MiniLM-L6-v2` | Embedding model |
| `AGENT_KB_DEVICE` | auto | Torch device (`cpu`, `cuda`, `mps`) |

Switching models requires `akb reindex --model <id>`; vectors from different
models are not comparable, so an ingest that would mix them is refused rather
than silently producing meaningless scores.

Queries ignore `AGENT_KB_MODEL` and use whichever model built the collection —
that is the only model whose vectors the stored ones can be compared against.
A single semantic query spanning collections built with *different* models is
refused; query them separately.

## On-disk layout

```
$AGENT_KB_HOME/collections/<name>/
    index.sqlite3    documents, chunks, tombstones, FTS5 keyword index
    vectors.f32      headerless float32 matrix, row i == chunks.vec_row i
    manifest.json    human-readable summary (SQLite meta is the source of truth)
```

The vector file is headerless so appends are a plain write with no header
rewrite. Deletes are tombstoned rather than compacted eagerly, so an ingest
never rewrites the matrix; `compact` reclaims the space, and ingest triggers it
automatically once a quarter of the rows are dead.

Nothing is hidden: `sqlite3 index.sqlite3 'select heading_path, start_line from
chunks limit 5'` works, which matters when you need to explain why an agent got
the chunk it got.

## Performance

All figures measured on two cores against a real 200,000-chunk collection.

| Operation | Time |
|---|---|
| Vector search, top-8 | 22 ms |
| Vector search + metadata filter | 39 ms |
| BM25 keyword search | 4 ms typical, 161 ms worst case¹ |
| **Cold `akb query --mode keyword`** (whole process) | **0.23 s** |
| **Cold `akb query --mode semantic`** (whole process) | **3.0 s** |

¹ 161 ms is a pathological corpus where *every* chunk matches every term. On
real documentation, keyword search is single-digit milliseconds.

The honest headline: **for semantic and hybrid queries, ~2.4 s of that 3.0 s is
importing torch**, before any of this project's code runs. Search itself is a
rounding error. Two consequences worth knowing:

- Keyword-only queries never import torch at all, which is why they return in
  under a quarter second. If an agent needs to fire many lookups, `--mode
  keyword` is dramatically cheaper.
- Re-ingesting an unchanged tree also skips the import entirely (measured at
  0.09 s for a corpus with nothing to do), because the model is only loaded
  once there is something to embed.

Hugging Face's offline mode is on by default. Loading the model with hub
checks enabled measured 4.87 s against 0.11 s offline — the difference is
purely network round-trips asking whether a cached model has a newer revision.
`akb model --download` and a genuinely missing model still fetch.

Ingest throughput is bounded by the embedding model, at roughly 23 chunks/sec
on two cores — FastAPI's 159-file documentation set took 111 s for 2,518
chunks. It parallelises with cores.

### Scaling

Brute-force search is linear in corpus size:

| Chunks | Search | Vector file |
|---|---|---|
| 10,000 | 0.4 ms | 15 MB |
| 100,000 | 4.7 ms | 154 MB |
| 1,000,000 | 61 ms | 1.5 GB |

For calibration, one large framework's docs chunk to roughly 5k–30k pieces.
Past a few million chunks you would want an ANN index, which this deliberately
does not have.
