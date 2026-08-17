<script lang="ts">
  import GreetForm from './lib/GreetForm.svelte'

  // The shell: header / workspace / footer, per docs/ui-design-principles.md > Layout.
  // Exactly one primary focus per screen — here, the greet form.
</script>

<a class="visually-hidden skip" href="#workspace">Skip to main content</a>

<div class="app">
  <header>
    <h1>__APP_NAME__</h1>
  </header>

  <main id="workspace" tabindex="-1">
    <section aria-labelledby="slice-heading">
      <h2 id="slice-heading">Call a Rust command</h2>
      <p class="lede">
        Replace this section with the app's primary task. Keep the pattern: one focus, the
        next action obvious, every state visible.
      </p>
      <GreetForm />
    </section>
  </main>

  <footer>
    <p>Tauri 2 · Svelte 5 · TypeScript</p>
  </footer>
</div>

<style>
  .app {
    display: grid;
    grid-template-rows: auto 1fr auto;
    min-height: 100dvh;
    /* Keeps content clear of notches, home indicators and rounded corners on mobile. */
    padding: env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom)
      env(safe-area-inset-left);
  }

  header {
    display: flex;
    align-items: center;
    gap: var(--space-4);
    padding: var(--space-4) var(--space-5);
    border-bottom: 1px solid var(--border);
  }

  header h1 {
    font-size: var(--text-lg);
  }

  main {
    padding: var(--space-6) var(--space-5);
  }

  section {
    display: flex;
    flex-direction: column;
    gap: var(--space-3);
  }

  .lede {
    color: var(--text-muted);
    margin-bottom: var(--space-2);
  }

  footer {
    padding: var(--space-3) var(--space-5);
    border-top: 1px solid var(--border);
    color: var(--text-muted);
    font-size: var(--text-sm);
  }

  .skip:focus {
    position: fixed;
    inset-block-start: var(--space-3);
    inset-inline-start: var(--space-3);
    z-index: 10;
    padding: var(--space-2) var(--space-3);
    background: var(--surface-raised);
    border-radius: var(--radius-md);
  }
</style>
