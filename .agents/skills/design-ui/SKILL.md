---
name: design-ui
description: Design an application's visual language and screen layouts before implementing them — palette, type roles, spacing and layout concept — as a written plan reviewed against the brief, then encoded as design tokens. Use when starting a new app's UI, adding a significant new screen, when the user says "design the interface", "how should this screen look", "make the UI coherent", or invokes /design-ui.
---

# Design a user interface

Two passes, in order: **plan, then build.** The plan is cheap to change and the code is not.

`docs/ui-design-principles.md` is normative for both passes. Read it before starting; do not
restate it here or paraphrase it into the plan — cite it when it decides something.

Done means: `design/PLAN.md` exists and the user has agreed to it, `src/app.css` tokens
match it, and every screen it covers has exactly one primary focus.

## Pass 1 — the plan

Do the exploration in your own reasoning. Show the user one confident proposal, not a menu
of half-formed ones. Use `references/design-plan-template.md` as the structure.

**1. State the task before the pixels.** For each screen: who is using it, what one thing
they came to do, what they must be able to see without acting, and what the next action is.
A screen whose primary focus you cannot name in one sentence is not ready to design.

**2. Colour — 4 to 6 named values.** Give each a role, not a hue name: surface, text,
accent, danger, and whatever else the app genuinely needs. Reserve saturation for primary
actions, warnings, destructive actions and success.

Measure every pair; do not estimate. 4.5:1 for body text, 3:1 for large text and for any
border that bounds a control or carries meaning (WCAG 1.4.11):

```bash
node .agents/skills/design-ui/scripts/contrast.mjs '#1a56c4' '#ffffff'
node .agents/skills/design-ui/scripts/contrast.mjs --tokens src/app.css   # every token, both themes
```

Record the numbers in the plan. This harness's own `--border-strong` shipped a first draft
at 1.93:1 against a white surface — it looked fine and only the arithmetic caught it.

**3. Type — at least two roles.** A body face optimised for reading, and a utility face for
data, captions and anything tabular. Add a characterful display face only when the brief
justifies one, and use it with restraint — headings only, never body copy. Six size steps is
plenty; more than that is not a hierarchy, it is noise.

**4. Layout — prose plus an ASCII wireframe per screen.** One sentence describing the
concept, then the sketch. Follow the spec's skeleton (header / workspace / footer) unless
you can say why this app differs. Sketch the small-screen arrangement too, and say what is
dropped or deferred there: primary task, then primary content, then secondary controls, then
decoration.

**5. Signature.** One idea that makes this app feel like itself and costs nothing in
usability — a consistent status treatment, a distinctive empty state, a considered density.
Not an animation, not a gradient.

## Review the plan before building

Against the brief: does every element serve the stated task? Against the spec's priority
order: has anything below **visual aesthetics** been bought at the price of anything above
it? Against the anti-pattern list: does the plan contain a carousel, a desktop hamburger,
hidden primary actions, icon-only navigation, or a modal chain?

Then show the user the plan — palette with contrast ratios, type roles, wireframes — and get
agreement. Only after that, write code.

## Pass 2 — build

**1. Tokens first.** Rewrite the token block at the top of `src/app.css` from the agreed
plan. Keep the existing token *names*; components, the `@theme inline` bridge and the
harness's own checks all depend on them. Update the dark palette in the same edit — both the
`prefers-color-scheme` block and the `[data-theme='dark']` block, or the explicit toggle
silently diverges from the OS setting.

This is the whole retheme, on both frontend paths. If the app has shadcn-svelte
(`components.json` at the root), its components read the same tokens through the `@theme
inline` block at the foot of the file — `bg-primary` resolves to `var(--accent)`. Do not
edit that bridge to change a colour, and never introduce shadcn's own `--background` /
`--primary` variables: two sources of truth is the failure this arrangement exists to avoid.

**2. Shell next.** `src/App.svelte` holds the header / workspace / footer skeleton, the skip
link and the safe-area padding. Screens slot into the workspace.

**3. Components last**, through `build-component`, one at a time, consuming tokens only. A
component that hard-codes a colour or a pixel size has broken the system.

**4. Verify** with `review-ui` before calling any of it finished.

## Guardrails

- **Hierarchy comes from spacing, typography, position and contrast — not colour.** A layout
  that reads correctly in greyscale is the test.
- **Never communicate meaning by colour alone.** Every state that has a colour also needs a
  word, an icon with a label, or a distinct shape.
- **No decorative elements.** If it does not aid comprehension, orientation or action, it
  does not ship. The spec's last checklist question — can anything be removed without
  reducing usability — is a build-time question, not a review-time one.
- **Do not add a CSS framework or a component library to an app that was not scaffolded for
  one.** The choice is made once, at scaffold time; shadcn-svelte on Tailwind 4 is the only
  supported option, and adding it by hand skips a cascade arrangement that fails silently.
- **The token block is the only place a colour is decided.** Not the bridge, not a
  component, not a Tailwind arbitrary value like `bg-[#1a56c4]`.
- **Watch selector specificity.** Base element styles in `app.css` are zero-specificity so
  component styles win. On the shadcn path they additionally sit inside `@layer base` so
  Tailwind utilities win too — do not lift them out, and do not introduce `!important` to
  break a tie you created by nesting type and class selectors.
- **Animation must carry meaning** — state, continuity, causality — and the reduced-motion
  block in `app.css` must keep working.
- **Show one proposal.** Iterating three mediocre directions in front of the user costs
  their attention and buys nothing.
