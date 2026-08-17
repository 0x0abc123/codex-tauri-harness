<script lang="ts">
  import type { Snippet } from 'svelte'

  // A labelled field with a hint and an inline error, wiring the accessibility
  // relationships that are easy to forget: label/for, aria-describedby, aria-invalid.
  //
  // The control itself is passed in as a snippet so this works for input, select,
  // textarea and anything custom, without a prop for every HTML attribute.

  interface ControlArgs {
    id: string
    describedBy: string | undefined
    invalid: boolean
  }

  interface Props {
    label: string
    /** Must be unique on the page — it ties the label to the control. */
    id: string
    hint?: string
    /** Null when valid. Shown inline; never in a dialog. */
    error?: string | null
    required?: boolean
    control: Snippet<[ControlArgs]>
  }

  let { label, id, hint, error = null, required = false, control }: Props = $props()

  const hintId = $derived(hint ? `${id}-hint` : undefined)
  const errorId = $derived(error ? `${id}-error` : undefined)
  const describedBy = $derived([hintId, errorId].filter(Boolean).join(' ') || undefined)
</script>

<div class="field">
  <label for={id}>
    {label}
    {#if required}
      <!-- The asterisk is decorative; the word is what a screen reader announces. -->
      <span aria-hidden="true">*</span>
      <span class="visually-hidden">(required)</span>
    {/if}
  </label>

  {@render control({ id, describedBy, invalid: Boolean(error) })}

  {#if hint}
    <p class="hint" id={hintId}>{hint}</p>
  {/if}

  {#if error}
    <!-- Described by the control rather than announced as an alert: on a form with
         several fields, competing alerts talk over each other. -->
    <p class="error" id={errorId}>{error}</p>
  {/if}
</div>

<style>
  .field {
    display: flex;
    flex-direction: column;
    gap: var(--space-1);
  }

  label {
    font-size: var(--text-sm);
    font-weight: var(--weight-medium);
  }

  .hint {
    color: var(--text-muted);
    font-size: var(--text-sm);
  }

  .error {
    color: var(--danger);
    font-size: var(--text-sm);
    font-weight: var(--weight-medium);
  }
</style>
