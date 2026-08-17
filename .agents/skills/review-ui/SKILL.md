---
name: review-ui
description: Audit a built interface against the normative UI specification — mechanically for Svelte 5, accessibility and design-token violations, then by judgement for hierarchy, states, keyboard operability and unnecessary complexity. Use before calling a UI finished, when the user says "review the UI", "is this accessible", "check the design", or invokes /review-ui.
---

# Review a user interface

Two passes: what a script can prove, then what only reading can. Report findings; do not fix
them unless asked, and never quietly rewrite while reviewing.

`docs/ui-design-principles.md` is the standard being applied — in particular its
**Completion Checklist** and **Anti-Patterns** sections.

Done means: the mechanical audit is clean or every remaining finding is justified in
writing, each judgement question below has been answered against the actual code, and the
findings are reported worst-first with a `file:line` and a concrete fix.

## Pass 1 — mechanical

```bash
.agents/skills/review-ui/scripts/ui-audit.sh src index.html
npm run check                       # svelte-check warnings are findings too
```

The audit covers Svelte 4 leftovers, removed focus rings, positive `tabindex`, disabled
zoom, images without `alt`, interactive roles on generic elements, icon-only controls,
placeholder-as-label, hard-coded colours and font sizes, arbitrary Tailwind values,
Tailwind utilities in an app with no Tailwind, `!important`, disabled text selection, motion
with no reduced-motion escape, and a missing `<html lang>`.

`src/lib/components/ui/` is skipped by default — that is shadcn-svelte's generated code, and
findings there are upstream's, not yours. Once you have edited a component, audit it too:

```bash
.agents/skills/review-ui/scripts/ui-audit.sh --include-ui src index.html
```

It proves nothing about whether the interface is any good. That is pass 2.

## Pass 2 — judgement

Read the screens. For each, answer with evidence, not assertion:

**Focus and hierarchy**
- Is there exactly one primary focus? Name it. Two competing focal points is a finding.
- Does the hierarchy survive in greyscale? If removing colour destroys it, it was built on
  colour rather than on spacing, type, position and contrast.
- Within a few seconds, can a new user tell where they are, what they can do, what matters
  most, and what changed?

**States**
- Does every asynchronous surface show idle, busy, empty, error and success — and does the
  empty state teach the first action rather than showing an empty box?
- Do errors explain what happened, preserve the user's work, and say how to recover?
- Does anything fail silently? Nothing may.

**Interaction**
- Can every important workflow be completed by keyboard alone? Walk the tab order and say
  where it goes.
- Is focus visible at every stop, and does it never land somewhere off-screen or invisible?
- Are primary actions large, separated, and near where the user's attention already is?
- Are impossible actions disabled, with visible text saying what would enable them?

**Structure**
- Are related controls grouped by proximity before borders are reached for?
- Do identical-looking elements behave identically, and different behaviours look different?
- Is there a confirmation dialog where an undo would serve better?
- Is any navigation, or any action, reachable only from a palette or a shortcut? That is a
  hidden action.

**Content and density**
- Are line lengths short, alignment consistent, and the type scale limited?
- Is dense information still scannable — alignment excellent, grouping clear, noise low?
- Is any whitespace adding scrolling without adding comprehension?

**Mobile**, if the app targets it
- Do touch targets clear 44px on every reachable surface?
- Does the layout adapt rather than shrink, keeping primary task and content above
  secondary controls and decoration?
- Do safe-area insets keep content clear of notches and home indicators?

**If the app uses shadcn-svelte** (`components.json` at the root)
- Do the imported components and the hand-written ones look like one system? Two focus
  treatments, two button heights or two dialog styles in one app is a finding.
- Is anything imported that the platform already does — a Button where `<button>` would
  serve, a wrapper around `<input>` that adds nothing?
- Does every colour still trace to a `:root` token? A shadcn component restyled with an
  arbitrary value has left the design system.
- Have the imported components actually been read? They are your source code, and their
  keyboard and screen-reader behaviour ships under your name.

**The last question**
- Can anything be removed without reducing usability? If yes, that is the top finding.

## Reporting

Worst first. One line each, then the detail:

```
src/lib/Toolbar.svelte:34  Icon-only controls
  Five buttons carry only an icon and no accessible name, so a screen reader
  announces "button" five times and the meaning is unavailable to anyone who
  does not already know the icon set.
  Fix: add visible labels, or aria-label plus a visible tooltip.
```

State what you checked and could not verify — a running app, a real device, a screen reader
— rather than implying coverage you did not have.

## Guardrails

- **Do not fix while reviewing** unless the user asked for fixes. A review that silently
  rewrites the code cannot be evaluated.
- **Do not report style preferences as findings.** Every finding cites a rule from the
  specification or a concrete failure a user would hit.
- **Do not accept a `svelte-ignore` or an audit exception without a written reason.** The
  exception is fine; the silence is not.
- **Do not claim keyboard operability without walking the tab order**, or accessibility
  without checking names and focus.
- **Do not confuse "passes the audit" with "is good".** The script catches the mechanical
  failures only, and a clean run is the beginning of the review.
