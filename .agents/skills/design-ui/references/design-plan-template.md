# Design plan — <App Name>

Write this to `design/PLAN.md` in the app, not in the harness. Keep it short enough that it
stays current; a plan nobody updates is worse than no plan.

## Brief

One paragraph: what the app is for, who uses it, and under what conditions (desk, one-handed
on a phone, noisy environment, occasional versus all day).

## Screens

For each screen:

| | |
|---|---|
| **Primary focus** | The one thing this screen is for, in a sentence. |
| **Visible without acting** | What the user must be able to read before touching anything. |
| **Next action** | The single obvious thing to do next, and where it sits. |
| **Empty state** | What is shown before there is any data, and how it teaches the first action. |
| **Failure state** | What is shown when the work fails, and how the user recovers. |

## Colour

Four to six values. Roles, not hues. Ratios measured against the surface each is used on.

The template's own palette, filled in as a worked example — replace the values, keep the
columns. Ratios are measured against `--surface` in each theme.

| Token | Light | Dark | Role | Light | Dark |
|---|---|---|---|---|---|
| `--surface` | `#ffffff` | `#0e1216` | Page ground | — | — |
| `--text` | `#14181c` | `#e6eaee` | Body copy | 17.84:1 | 15.55:1 |
| `--text-muted` | `#5a6570` | `#9aa5b1` | Secondary copy, hints | 5.95:1 | 7.51:1 |
| `--accent` | `#1a56c4` | `#7aa9ff` | Primary action only | 6.62:1 | 8.01:1 |
| `--danger` | `#b3261e` | `#ff8a80` | Destructive, errors | 6.54:1 | 8.24:1 |
| `--success` | `#16653f` | `#5ddba0` | Confirmed outcomes | 7.08:1 | 10.84:1 |
| `--border-strong` | `#7d868f` | `#616e7b` | Control boundaries | 3.70:1 | 3.60:1 |

Body text needs 4.5:1; large text, control boundaries and any border carrying meaning need
3:1 (WCAG 1.4.11). Purely decorative separators such as `--border` are exempt. **Measure,
do not estimate** — the harness's own `--border-strong` failed at 1.93:1 on first draft and
only the arithmetic caught it. Compute the ratio for each pair and record the number here.

## Type

| Role | Face | Used for | Sizes |
|---|---|---|---|
| Body / UI | system-ui stack | Everything by default | `--text-sm` … `--text-lg` |
| Utility | monospace stack | Data, timestamps, identifiers, code | `--text-xs`, `--text-sm` |
| Display *(optional)* | — | Screen titles only, if the brief justifies one | `--text-2xl` |

State the measure (line length) for reading surfaces — `--measure` defaults to 68ch.

## Layout

One sentence per screen describing the concept, then a sketch.

```
Desktop — <screen name>
┌────────────────────────────────────────────────────────────┐
│ App name            [search            ]      [Primary ▸]  │  header
├────────────────┬───────────────────────────────────────────┤
│ Filters        │ ONE PRIMARY FOCUS                         │
│  ▸ group       │                                           │
│  ▸ group       │ …content…                                 │  workspace
│                │                                           │
├────────────────┴───────────────────────────────────────────┤
│ 12 items · last synced 14:02                               │  footer/status
└────────────────────────────────────────────────────────────┘

Narrow — <screen name>
┌──────────────────────┐
│ App name        [⋯]  │
├──────────────────────┤
│ ONE PRIMARY FOCUS    │   filters collapse to a single
│                      │   labelled control above the list;
│ …content…            │   the status line moves under the
│                      │   title. Nothing is hidden behind
├──────────────────────┤   an unlabelled icon.
│ [ Primary action   ] │   full-width, thumb-reachable
└──────────────────────┘
```

Say explicitly what changes at the narrow size and why — adapt the layout, do not shrink it.

## Signature

One sentence. The thing that makes this app recognisably itself, at no cost to usability.

## Density

Which surfaces are dense (tables, lists) and which are calm (forms, detail panes), and what
keeps the dense ones scannable: alignment, grouping, and whitespace that preserves structure.

## Keyboard

The shortcuts this app defines, and the workflow each one serves. Every important workflow
must be completable without a mouse; list the ones you have checked.

## Open questions

What the brief did not settle, and what you assumed in the meantime.
