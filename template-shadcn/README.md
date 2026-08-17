# template-shadcn/

The overlay applied on top of `template/` when an app is scaffolded with `--shadcn`. It is
not a complete project on its own — the base template supplies everything not listed here.

```bash
.agents/skills/scaffold-app/scripts/new-app.sh <target> "<App Name>" [identifier] --shadcn
```

## What the overlay replaces or adds

| File | Why |
|---|---|
| `package.json` | Adds `tailwindcss`, `@tailwindcss/vite`, `shadcn-svelte`, `clsx`, `tailwind-merge`, `tailwind-variants`, and a `ui` script |
| `vite.config.ts` | Adds the Tailwind plugin and the `$lib` alias |
| `tsconfig.json`, `tsconfig.app.json` | `$lib` path mapping for the compiler and the editor |
| `index.html` | Resolves `[data-theme]` before first paint |
| `src/app.css` | Tailwind import, layered base styles, and the `@theme inline` token bridge |
| `src/lib/utils.ts` | `cn()` and the type helpers generated components import |
| `components.json` | Configuration the `shadcn-svelte` CLI reads |

## Why `init` is never run

The official flow is `shadcn-svelte init`, which asks for a global CSS file and then
**overwrites it**. That file is `src/app.css` — the design-token layer the whole harness is
built on. So the overlay pre-writes everything `init` produces (`components.json`,
`utils.ts`, the Tailwind import and theme bridge), and apps only ever run:

```bash
npm run ui add button dialog          # or: npx shadcn-svelte@latest add …
```

`add` reads `components.json` and never touches the CSS. **Do not run `init` in a scaffolded
app.** If someone does, restore `src/app.css` from this overlay.

## The token bridge

`src/app.css` is the single source of truth. shadcn's utilities are mapped onto our tokens
through `@theme inline`, so shadcn's own variables are never defined:

| Tailwind utility | Resolves to |
|---|---|
| `bg-primary` / `text-primary-foreground` | `--accent` / `--accent-contrast` |
| `bg-background` / `text-foreground` | `--surface` / `--text` |
| `text-muted-foreground` | `--text-muted` |
| `bg-accent` | `--surface-sunken` |
| `bg-destructive` | `--danger` |
| `border-border` / `border-input` | `--border` / `--border-strong` |
| `ring-ring` | `--focus-ring` |
| `rounded-*`, `text-*` | our `--radius-*` and `--text-*` tokens directly |

Note the deliberate crossing: shadcn's `accent` means "subtle hover background", ours means
"primary action colour". shadcn's `primary` is what we call `accent`. Mapping through
`@theme inline` is what keeps both meanings intact without a name collision.

Retheming the app is still one edit to the `:root` tokens; every shadcn component follows.

## Verified

Scaffolded, `npm install`, `npm run ui add button`, `npm run check` (0 errors, 0 warnings),
`npm run build`. The compiled CSS was inspected to confirm `bg-primary` resolves to
`var(--accent)` and that the cascade order works out — see the header comment in
`src/app.css` for the three ordering rules that make that true.
