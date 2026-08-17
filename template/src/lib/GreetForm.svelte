<script lang="ts">
  import { greet, type Greeting } from './ipc'

  // The reference vertical slice: form -> typed IPC wrapper -> Rust command, with every
  // state the call can be in made visible. Copy this shape for real features.

  type Status =
    | { kind: 'idle' }
    | { kind: 'busy' }
    | { kind: 'done'; greeting: Greeting }
    | { kind: 'failed'; message: string }

  let name = $state('')
  let status = $state<Status>({ kind: 'idle' })

  // Narrow once here rather than in the markup — template narrowing over runes is fragile.
  const busy = $derived(status.kind === 'busy')
  const greeting = $derived(status.kind === 'done' ? status.greeting : null)
  const failure = $derived(status.kind === 'failed' ? status.message : null)
  const canSubmit = $derived(name.trim().length > 0 && !busy)

  const time = new Intl.DateTimeFormat(undefined, { timeStyle: 'medium' })

  async function submit(event: SubmitEvent) {
    event.preventDefault()
    if (!canSubmit) return
    status = { kind: 'busy' }
    try {
      status = { kind: 'done', greeting: await greet(name) }
    } catch (error) {
      // The typed value in the field is never cleared — failing must not destroy work.
      status = { kind: 'failed', message: String(error) }
    }
  }
</script>

<form class="greet" onsubmit={submit}>
  <div class="field">
    <label for="greet-name">Your name</label>
    <input
      id="greet-name"
      name="name"
      type="text"
      autocomplete="name"
      bind:value={name}
      aria-describedby="greet-hint"
      aria-invalid={failure ? 'true' : undefined}
    />
    <p id="greet-hint" class="hint">Sent to the Rust backend over Tauri's IPC bridge.</p>
  </div>

  <button type="submit" class="primary" disabled={!canSubmit}>
    {busy ? 'Greeting…' : 'Greet'}
  </button>

  <!-- One live region for outcomes. Assertive for errors, polite for success, so a
       screen reader is interrupted only when something went wrong. -->
  {#if failure}
    <p class="outcome failure" role="alert">
      <strong>Could not greet.</strong>
      {failure} Your name is still in the field — try again.
    </p>
  {:else if greeting}
    <p class="outcome success" role="status">
      <strong>{greeting.message}</strong>
      <span class="stamp">at {time.format(new Date(greeting.greetedAt))}</span>
    </p>
  {/if}
</form>

<style>
  .greet {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
    max-width: var(--measure);
  }

  .field {
    display: flex;
    flex-direction: column;
    gap: var(--space-1);
  }

  label {
    font-size: var(--text-sm);
    font-weight: var(--weight-medium);
  }

  input {
    min-height: max(var(--control-height), var(--touch-target-min));
    padding: 0 var(--space-3);
    background: var(--surface);
    border: 1px solid var(--border-strong);
    border-radius: var(--radius-md);
  }

  .hint {
    color: var(--text-muted);
    font-size: var(--text-sm);
  }

  button.primary {
    align-self: flex-start;
    min-height: max(var(--control-height), var(--touch-target-min));
    padding: 0 var(--space-5);
    background: var(--accent);
    color: var(--accent-contrast);
    border: 1px solid transparent;
    border-radius: var(--radius-md);
    font-weight: var(--weight-medium);
    cursor: pointer;
    transition: background var(--motion-fast) var(--ease);
  }

  button.primary:hover:not(:disabled) {
    background: var(--accent-hover);
  }

  .outcome {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
    align-items: baseline;
    margin: 0;
    padding: var(--space-3);
    border-radius: var(--radius-md);
    border-inline-start: 3px solid;
    background: var(--surface-raised);
    font-size: var(--text-sm);
  }

  /* Colour is never the only signal — each outcome also carries its own wording and a
     distinct leading rule. */
  .outcome.failure {
    border-color: var(--danger);
    color: var(--danger);
  }

  .outcome.success {
    border-color: var(--success);
    color: var(--success);
  }

  .stamp {
    color: var(--text-muted);
    font-family: var(--font-mono);
    font-size: var(--text-xs);
  }
</style>
