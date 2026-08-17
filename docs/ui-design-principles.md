# UI Design Specification for AI Coding Agents

> Purpose: Generate web user interfaces that maximize human productivity, minimize cognitive effort, and follow established cognitive science, HCI, accessibility, and UI/UX best practices.

Treat this specification as normative. Unless explicitly instructed otherwise, all generated user interfaces MUST comply with these requirements. If a requested design conflicts with this specification, prefer the specification and explain the tradeoff.

## Core Objective

Optimize for **task completion**, not visual novelty.

Every design decision SHOULD reduce cognitive load, improve comprehension, shorten interaction time, or prevent user error.

The interface is a tool, not a marketing asset.

---

# Priority Order

When tradeoffs exist, prioritize in this order:

1. Correctness
2. Usability
3. Clarity
4. Accessibility
5. Performance
6. Learnability
7. Visual aesthetics
8. Originality
    

Never sacrifice higher priorities for lower ones.

---

# General Rules

The generated interface MUST:

- minimize cognitive load
- maximize information clarity
- expose system state
- minimize interaction cost
- prevent errors
- be fully keyboard accessible
- be responsive
- use semantic HTML
- degrade gracefully
- remain usable without animations
    

The interface SHOULD require as little learning as possible.

---

# Cognitive Load

The UI MUST minimize working memory requirements.

The UI SHOULD:

- expose information rather than requiring recall
- chunk related information
- remove unnecessary choices
- avoid unnecessary configuration
- preserve user context
- avoid forcing users between multiple screens
    

Avoid:

- dashboard clutter
- decorative elements without function
- hidden state
- unnecessary navigation depth
- modal chains
- excessive scrolling
    

---

# Information Hierarchy

Every screen MUST have exactly one primary focus.

Hierarchy SHOULD primarily be created through:

- spacing
- typography
- position
- contrast

Hierarchy SHOULD NOT rely primarily on color.

Users MUST understand within a few seconds:

- where they are
- what they can do
- what is most important
- what changed

---

# Gestalt Principles

## Proximity

Related elements MUST be visually grouped.

Spacing SHOULD communicate relationships before borders do.

---

## Similarity

Elements with identical appearance MUST have identical behavior.

Different behaviors SHOULD look different.

---

## Common Region

Related controls SHOULD share a visual container.

Avoid mixing unrelated actions within the same region.

---

## Continuity

Layouts SHOULD create uninterrupted reading paths.

Prefer vertical alignment.

Maintain consistent grids.

---

## Figure–Ground

Primary content MUST visually dominate background elements.

Background decoration MUST NOT compete for attention.

---

## Common Fate

Elements that change together SHOULD animate together.

---

# Decision Complexity

Following Hick's Law:

The interface SHOULD minimize visible choices.

Large action sets SHOULD be organized using:

- grouping
- filtering
- search
- progressive disclosure

Rare actions SHOULD NOT dominate primary workflows.

---

# Target Acquisition

Following Fitts's Law:

Interactive targets MUST be easy to acquire.

Primary actions SHOULD be:

- large
- clearly separated
- near the user's current focus

Avoid small clickable regions.

---

# Recognition Over Recall

Users SHOULD never need to remember:

- IDs
- commands
- previous values
- navigation paths
- hidden shortcuts

Instead provide:

- autocomplete
- suggestions
- recent history
- visible state
- inline documentation

---

# Progressive Disclosure

Only present complexity when needed.

Beginner workflows SHOULD remain simple.

Advanced functionality SHOULD remain easily discoverable.

---

# Feedback

Every interaction MUST produce feedback.

Small actions:

- subtle visual confirmation

Long operations:

- progress indication

Completed operations:

- success confirmation

Errors:

- explain
- preserve work
- recommend recovery

The interface MUST never fail silently.

---

# Error Prevention

Prevent invalid actions whenever possible.

Prefer:

- constrained inputs
- inline validation
- previews
- safe defaults
- disabled impossible actions

Error dialogs SHOULD be rare.

---

# Consistency

Maintain consistent:

- spacing
- terminology
- typography
- iconography
- component behavior
- keyboard shortcuts
- interaction patterns

One concept SHOULD correspond to one visual treatment.

---

# Typography

Typography MUST optimize readability.

Prefer:

- short line lengths
- generous line spacing
- clear hierarchy
- left alignment
- limited font scales

Avoid excessive font weights and sizes.

---

# Color

Color MUST communicate meaning.

Reserve strong colors for:

- primary actions
- warnings
- destructive actions
- success

Never communicate meaning using color alone.

---

# Motion

Animation MUST communicate:

- state
- continuity
- hierarchy
- causality

Animation MUST NOT exist solely for decoration.

Respect reduced-motion preferences.

---

# Whitespace

Whitespace SHOULD improve grouping and scanning.

Do not add empty space that increases scrolling without improving comprehension.

Optimize information per eye movement rather than information per pixel.

---

# Forms

Forms SHOULD minimize typing.

Prefer:

- autocomplete
- smart defaults
- pickers
- toggles
- inferred values
- inline validation

Only request information that is required.

---

# Tables

Data tables SHOULD optimize scanning.

Provide:

- sticky headers
- sorting
- filtering
- resizing where useful
- keyboard navigation
- row selection
- responsive behavior

Numeric values SHOULD be right aligned.

---

# Search

Search SHOULD support:

- fuzzy matching
- synonyms
- partial matches
- autocomplete
- recent searches
- keyboard focus

Search SHOULD tolerate mistakes.

---

# Navigation

Navigation SHOULD minimize hierarchy depth.

Users SHOULD reach common destinations within one or two interactions.

Persistent navigation SHOULD remain predictable.

Avoid hidden navigation.

---

# Keyboard Support

Every important workflow MUST be executable entirely by keyboard.

Provide:

- logical tab order
- visible focus
- shortcuts for common actions
- command palette where appropriate

Mouse-only functionality is unacceptable.

---

# Accessibility

The interface MUST satisfy modern accessibility expectations.

Provide:

- semantic HTML
- ARIA only when necessary
- accessible names
- keyboard navigation
- visible focus
- sufficient contrast
- scalable typography
- screen reader compatibility

Accessibility MUST be considered during implementation, not after.

---

# Responsive Design

Design around content rather than devices.

Adapt layouts instead of shrinking them.

On smaller screens prioritize:

1. primary task
2. primary content
3. secondary controls
4. decoration

---

# Performance

Performance is a usability feature.

Optimize:

- initial render
- interaction latency
- perceived responsiveness

Prefer:

- optimistic updates
- lazy loading
- incremental rendering
- skeleton placeholders
- caching

Avoid layout shifts.

---

# AI Features

AI MUST reduce work rather than create work.

Good AI behaviors:

- summarize
- classify
- prioritize
- recommend
- autocomplete
- explain
- detect anomalies
- automate repetitive tasks

Bad AI behaviors:

- interrupt
- hide important information
- remove user agency
- fabricate certainty
- block manual workflows

Users MUST remain in control.

---

# Trust

The interface MUST clearly communicate:

- what happened
- why it happened
- what AI changed
- confidence when uncertain
- how to undo changes

Undo SHOULD be preferred over confirmation dialogs whenever feasible.

---

# Defaults

Prefer sensible defaults over empty configuration.

Automate repetitive decisions.

Remember user preferences when appropriate.

Never require users to configure settings before accomplishing basic tasks.

---

# Density

Productivity software MAY use high information density if:

- alignment is excellent
- grouping is clear
- typography remains readable
- whitespace preserves structure
- visual noise remains low

Avoid density that impairs scanning.

Avoid minimalism that wastes space.

---

# Components

Components SHOULD prioritize function over decoration.

Buttons:

- obvious
- clearly labeled
- consistent sizing

Dialogs:

- only when necessary
- easily dismissible
- focused on one task

Cards:

- only when they improve grouping
    

Tabs:

- few in number
- stable ordering

Icons:

- supplementary
- never the sole label

---

# Layout

Layouts SHOULD generally follow:

```
Header
 ├── Navigation
 ├── Search
 ├── Global Actions

Workspace
 ├── Primary Content
 ├── Contextual Controls
 ├── Details Panel (optional)

Footer
 └── Status / Secondary Information
```

Controls SHOULD remain close to the content they affect.

Avoid excessive cursor travel.

---

# Anti-Patterns

The agent MUST avoid generating:

- hamburger menus on desktop without justification
- carousels for core content
- auto-rotating elements 
- decorative animations
- glassmorphism that reduces readability
- low-contrast text
- hidden primary actions
- nested scrolling regions
- excessive modals
- confirmation dialogs for reversible actions
- inconsistent spacing
- icon-only navigation without labels
- infinite loading indicators
- skeletons that do not resemble final layouts
- placeholder text used as labels
- forms split across unnecessary steps
- dark patterns
- deceptive defaults

---

# Completion Checklist

Before considering a UI complete, verify:

- Is the primary task immediately obvious?
- Is the next action obvious?
- Can the workflow be completed entirely with a keyboard?
- Is every important state visible?
- Can users recover from mistakes?
- Are related elements grouped?
- Are interactions consistent?
- Is unnecessary complexity hidden?
- Is information easy to scan?
- Is the layout responsive?
- Is accessibility built in?
- Is every element justified?
- Can anything be removed without reducing usability?

If the answer to the last question is "yes," simplify the interface.

---

Work in two passes. First, brainstorm a short design plan based on the human's design brief: create a compact token system with color, type and layout, and signature. Color: describe the palette as 4–6 named hex values. Type: the typefaces for 2+ roles (a characterful display face that's used with restraint, a complementary body face, and a utility face for captions or data if needed). Layout: a layout concept, using one-sentence prose descriptions and ASCII wireframes to ideate and compare. 

Then review that plan against the brief before building. Only after you've confirmed your design plan should you start to write the code.

When writing the code, be careful of structuring your CSS selector specificities. It's easy to generate CSS classes that cancel each other out (especially with a type-based selector like .section and a element-based selector like .cta). This can happen often with paddings/margins between sections.

Try to do a lot of this planning and iteration in your thinking, and only show ideas to the user when you have higher confidence it'll delight them.

# Guiding Principle

**Generate interfaces that minimize thinking unrelated to the user's goal. Favor clarity over cleverness, recognition over recall, direct manipulation over configuration, and predictable interaction over visual novelty. Every component should reduce cognitive effort, preserve context, and make the next action obvious.**
