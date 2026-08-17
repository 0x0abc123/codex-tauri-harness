<script lang="ts">
  import type { Snippet } from 'svelte'

  // Native <dialog> in modal mode. The platform gives us, for free and correctly:
  // focus moved in, focus trapped, the rest of the page inert, Escape to dismiss, and
  // focus returned to whatever opened it. A div-based modal reimplements all of that,
  // usually incompletely.
  //
  // Use a dialog only for a single task that genuinely blocks. For anything reversible,
  // act immediately and offer undo instead — see docs/ui-design-principles.md > Trust.

  interface Props {
    open: boolean
    title: string
    children: Snippet
    /** Buttons for the footer. The primary action goes last, nearest the ready hand. */
    actions?: Snippet
  }

  let { open = $bindable(), title, children, actions }: Props = $props()

  let node: HTMLDialogElement | null = $state(null)
  const titleId = 'dialog-title'

  // Keep the DOM state in step with the prop in both directions.
  $effect(() => {
    if (!node) return
    if (open && !node.open) node.showModal()
    if (!open && node.open) node.close()
  })
</script>

<dialog bind:this={node} aria-labelledby={titleId} onclose={() => (open = false)}>
  <header>
    <h2 id={titleId}>{title}</h2>
  </header>

  <div class="body">
    {@render children()}
  </div>

  {#if actions}
    <footer>
      {@render actions()}
    </footer>
  {:else}
    <footer>
      <button type="button" onclick={() => (open = false)}>Close</button>
    </footer>
  {/if}
</dialog>

<style>
  dialog {
    max-width: min(32rem, calc(100vw - var(--space-6)));
    padding: 0;
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    background: var(--surface);
    color: var(--text);
    box-shadow: var(--shadow-raised);
  }

  dialog::backdrop {
    background: rgb(0 0 0 / 0.4);
  }

  header,
  footer {
    padding: var(--space-4) var(--space-5);
  }

  header {
    border-bottom: 1px solid var(--border);
  }

  footer {
    display: flex;
    justify-content: flex-end;
    gap: var(--space-2);
    border-top: 1px solid var(--border);
  }

  .body {
    padding: var(--space-5);
  }

  button {
    min-height: max(var(--control-height), var(--touch-target-min));
    padding: 0 var(--space-4);
    border: 1px solid var(--border-strong);
    border-radius: var(--radius-md);
    background: var(--surface-raised);
    cursor: pointer;
  }
</style>
