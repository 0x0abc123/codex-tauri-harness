# Component patterns

Four worked components in `patterns/`. Each compiles clean under `svelte-check` with zero
errors and zero warnings, uses only tokens from `app.css`, and is operable by keyboard.

Copy one into the app and adapt it. Do not import from this directory — it lives in the
harness, not in any app.

| File | Use it for | The part that is easy to get wrong | shadcn equivalent |
|---|---|---|---|
| `FormField.svelte` | Any labelled input, select or textarea | The `label for` / `aria-describedby` / `aria-invalid` wiring, and passing the control in as a `Snippet` so one field component serves every input type | `label`, `input`, `form` |
| `Dialog.svelte` | A single blocking task | Using native `<dialog>` + `showModal()` so focus trapping, inert background, Escape and focus return come from the platform | `dialog`, `sheet`, `alert-dialog` |
| `DataTable.svelte` | Scannable rows of data | `aria-sort` on the header, right-aligned tabular numerals, roving `tabindex` for row navigation, and deriving the sort key instead of seeding state from a prop | `table`, `data-table` |
| `CommandPalette.svelte` | Reaching any action without hunting for it | The combobox/listbox pairing: focus stays in the input and `aria-activedescendant` names the highlighted option | `command`, `dialog` |

## Which to use

These four are the reference for the **plain-CSS path**, and they stay correct there.

In an app scaffolded with `--shadcn` (look for `components.json`), prefer the shadcn
component for **Dialog**, **DataTable** and **CommandPalette** — focus trapping, typeahead
and the listbox ARIA relationships are exactly the work `bits-ui` has already done, and
these three files exist partly to show how much of it there is. **FormField** is a fair
fight: shadcn's `form` is heavier and assumes a form library, so the pattern here is often
the better choice even when shadcn is available.

Either way the accessibility of what ships is yours to verify — a shadcn component is copied
into your source tree, not a black box, so `review-ui` applies to it exactly as it does to
anything you wrote.

## What each demonstrates beyond its own job

**`FormField.svelte`** — a snippet-with-arguments prop (`Snippet<[ControlArgs]>`), which is
the Svelte 5 replacement for a slot that needs to pass values back up. Also shows the
required-field marker done properly: an `aria-hidden` asterisk for sighted users plus a
visually hidden word for everyone else.

**`Dialog.svelte`** — `$bindable()` for two-way `open`, and an `$effect` used correctly: to
push state into an imperative DOM API (`showModal()` / `close()`) that Svelte cannot
express declaratively. That is what `$effect` is for. Deriving one piece of state from
another is not.

**`DataTable.svelte`** — generics via `<script lang="ts" generics="Row extends { id: string
}">`, `$derived.by` for a multi-statement computation, and roving `tabindex` so the table is
one tab stop with arrow-key navigation inside it. Note `aria-current` rather than
`aria-selected`: rows only support `aria-selected` inside a `role="grid"`, and declaring a
grid commits you to cell-level focus management.

**`CommandPalette.svelte`** — subsequence matching so "opf" finds "Open file", a second
`$effect` that clamps the highlight when the result set shrinks under it, and the one
sanctioned use of `svelte-ignore`: a rule that genuinely does not apply, with a comment
saying why. An option in a listbox cannot carry its own key handler, because focus never
reaches it.

## Conventions these share

- Props are one `interface Props` and one destructured `$props()` call.
- Callbacks (`onselect`, `onclose`) rather than `createEventDispatcher`.
- Every interactive element clears `max(var(--control-height), var(--touch-target-min))`.
- Selection and state are marked by more than colour — a rule, a weight, a word.
- One scroll container per component; nested scrolling regions are an anti-pattern.
- Empty states say what to do next rather than showing an empty box.
