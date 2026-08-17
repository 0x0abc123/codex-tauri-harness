---
name: build-component
description: Write or change a Svelte 5 component in TypeScript with runes, semantic HTML, full keyboard operability and design tokens. Use when adding a screen, control, form, dialog, table or list to a Tauri app, when the user says "build a component", "add a screen", "make this accessible", or invokes /build-component.
---

# Build a Svelte 5 component

Semantic HTML first, runes for state, tokens for style, keyboard for everything.
`docs/ui-design-principles.md` is normative; `references/component-patterns.md` holds worked
examples of the four shapes that come up most.

Done means: `npm run check` is clean, the component is operable from the keyboard alone,
every state it can be in is visible, and it hard-codes no colour, size or spacing.

## Process

**1. Name the job.** What is this component for, what states can it be in (empty, loading,
partial, error, full), and what is the next action from each? A component whose error state
you have not designed is not designed.

**2. Reach for the platform first.** `<button>`, `<dialog>`, `<details>`, `<input
type="search">`, `<table>` bring focus handling, keyboard behaviour and screen-reader
semantics for free. A `<div>` with `role="button"` needs tabindex, Enter, Space, focus
styling and a name — all of which you will get wrong more often than the browser does.

**2a. Then decide where the component comes from.** Check the app root: **`components.json`
present means shadcn-svelte is available.** On the plain-CSS path it is not, and a utility
class in the markup does nothing at all — silently.

Order of preference, on either path:

1. **A plain HTML element**, if one does the job. `<button>` beats an imported Button.
2. **A shadcn component**, if the app has the path and the thing is one of the hard ones —
   dialog, combobox, select, date picker, tooltip, command palette, data table. These need
   focus management, typeahead and ARIA relationships that take real effort to get right;
   shadcn builds them on `bits-ui`, which handles that layer.
3. **Hand-written**, otherwise — and always on the plain path. Use
   `references/component-patterns.md`.

Do not import a shadcn component for something the platform already does, and do not
hand-roll a combobox in an app that has shadcn installed. Both are the same mistake.

```bash
npm run ui add dialog        # adds it under src/lib/components/ui/dialog
```

A shadcn component is **your code**, copied in — read it, and edit it when the app needs
something different. Two consequences: the accessibility of what ships is still yours to
verify, and `npm run ui add -o <name>` will overwrite your edits.

**3. Check the API before writing it.** Runes and Svelte 5 component syntax changed
substantially; `consult-docs` against `-c svelte` is faster than debugging a Svelte 4 idiom
that no longer compiles.

**4. Write it.**

```svelte
<script lang="ts">
  interface Props {
    label: string
    items: Item[]
    selected?: string | null      // optional
    onselect?: (id: string) => void   // callbacks, not createEventDispatcher
  }

  let { label, items, selected = $bindable(null), onselect }: Props = $props()

  let query = $state('')
  const matches = $derived(items.filter((i) => i.name.includes(query)))
</script>
```

- `$props()` with a typed `Props` interface. `export let` is Svelte 4.
- `$state` for what changes, `$derived` for what follows from it. Never mirror one piece of
  state into another with `$effect` — that is the commonest runes bug and it loops.
- `$effect` only for genuine side effects outside Svelte: a subscription, a timer, an
  imperative DOM call. Reach for it third, not first.
- Events are `onclick`, `oninput`, `onsubmit` — no colon. Child-to-parent communication is a
  callback prop, not `createEventDispatcher`.
- Children come through `{@render children()}` with a `Snippet` prop, not `<slot>`.
- Narrow discriminated unions into a `$derived` and test that; narrowing inside the markup
  over a rune is unreliable.

**5. Style with tokens.** Component `<style>` blocks are scoped by Svelte. Use
`var(--space-*)`, `var(--text-*)`, `var(--surface)` and friends. Base element styles in
`app.css` are zero-specificity (`:where()`-wrapped on the plain path, inside `@layer base`
on the shadcn path), so a plain class selector wins — you never need `!important` or
`:global`.

On the shadcn path you have two ways to style and should not mix them within one component:
a scoped `<style>` block using tokens, or Tailwind utilities. Utilities resolve to the same
tokens through the bridge, so `bg-primary` and `background: var(--accent)` are the same
colour. Prefer utilities when adjusting a shadcn component so it stays consistent with the
rest of that component, and a `<style>` block for anything hand-written.

Never hard-code a value in either idiom — `text-[#1a56c4]` and `color: #1a56c4` are the same
violation, and an arbitrary Tailwind value bypasses the token layer just as completely.

**6. Check the keyboard yourself.** Tab through it in order, operate every control, confirm
focus stays visible and never lands somewhere invisible. Then run `npm run check`.

## Non-negotiables

- **Every control has an accessible name.** A `<label for>` tied to the input's `id`, or
  `aria-label` where no visible text exists. Placeholder text is not a label — it disappears
  on the first keystroke, exactly when it is needed.
- **Icons are never the only label.** Pair with text, or give a visible tooltip *and* an
  accessible name.
- **Focus is always visible.** The `:focus-visible` rule in `app.css` covers the app; never
  set `outline: none` without replacing the ring in the same rule.
- **Touch targets are at least 44px** on any surface reachable on mobile: `min-height:
  max(var(--control-height), var(--touch-target-min))`.
- **Colour is never the only signal.** Error, warning and success states carry wording or
  shape as well.
- **Long operations show progress; completed ones confirm; failures explain, preserve the
  user's work and say how to recover.** Nothing fails silently.
- **Disable what is impossible** rather than allowing it and rejecting it, and say in visible
  text what would enable it.
- **Live regions**: `role="status"` for routine outcomes, `role="alert"` for failures. One
  region per surface — competing live regions talk over each other.

## Guardrails

- **No Svelte 4 idiom**: `on:click`, `export let`, `$:`, stores as default state, `<slot>`,
  `createEventDispatcher`, `new Component()`. All either fail to compile or behave subtly
  differently.
- **No `any` to quiet the checker**, and no `svelte-ignore` without a comment saying why the
  rule does not apply. `svelte-check` warnings are failures.
- **No component-level `invoke`.** Backend calls go through a typed wrapper in
  `src/lib/ipc.ts` — see `tauri-ipc`.
- **No new dependency for something the platform does.** Disclosure, date inputs and simple
  sorting do not need a library — on either path.
- **No component library other than shadcn-svelte**, and only in an app scaffolded for it.
  Adding a second one means two design systems in one binary.
- **No Tailwind utilities in a plain-CSS app.** They compile to nothing and the component
  silently renders unstyled.
- **No arbitrary Tailwind values for colour, size or spacing** — `bg-[#fff]`, `text-[13px]`,
  `p-[7px]`. Use the token or add one.
- **Do not disable text selection or zoom**, and do not trap focus outside a modal context.
- **Do not add animation that carries no information**, and do not defeat the reduced-motion
  block in `app.css`.
