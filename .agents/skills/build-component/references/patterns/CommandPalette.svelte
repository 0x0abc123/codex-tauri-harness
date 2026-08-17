<script lang="ts">
  // Recognition over recall: a searchable list of everything the app can do, reachable
  // from one shortcut. The combobox/listbox pattern below is the ARIA one — focus stays
  // in the input and `aria-activedescendant` points at the highlighted option, so typing
  // and arrowing work at the same time.
  //
  // A palette supplements visible controls; it never replaces them. Any action reachable
  // only here is a hidden action.

  interface Command {
    id: string
    label: string
    /** Shown right-aligned, e.g. "Ctrl K". Never the only way to discover the action. */
    hint?: string
    run: () => void
  }

  interface Props {
    commands: Command[]
    open: boolean
  }

  let { commands, open = $bindable() }: Props = $props()

  let query = $state('')
  let active = $state(0)
  let input: HTMLInputElement | null = $state(null)

  // Subsequence match, so "opf" finds "Open file" — tolerant of mistakes, per the spec.
  function matches(label: string, term: string) {
    if (!term) return true
    const haystack = label.toLowerCase()
    let at = 0
    for (const character of term.toLowerCase()) {
      at = haystack.indexOf(character, at)
      if (at === -1) return false
      at += 1
    }
    return true
  }

  const results = $derived(commands.filter((command) => matches(command.label, query)))
  const activeId = $derived(results[active]?.id)

  $effect(() => {
    if (open) input?.focus()
  })

  // Clamp the highlight whenever the result set shrinks under it.
  $effect(() => {
    if (active > results.length - 1) active = Math.max(0, results.length - 1)
  })

  function choose(command: Command | undefined) {
    if (!command) return
    open = false
    query = ''
    command.run()
  }

  function onkeydown(event: KeyboardEvent) {
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      active = Math.min(active + 1, results.length - 1)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      active = Math.max(active - 1, 0)
    } else if (event.key === 'Enter') {
      event.preventDefault()
      choose(results[active])
    } else if (event.key === 'Escape') {
      event.preventDefault()
      open = false
    }
  }
</script>

{#if open}
  <div class="scrim">
    <div class="palette">
      <label class="visually-hidden" for="palette-input">Search commands</label>
      <input
        id="palette-input"
        bind:this={input}
        bind:value={query}
        {onkeydown}
        type="text"
        role="combobox"
        aria-expanded="true"
        aria-controls="palette-list"
        aria-activedescendant={activeId}
        autocomplete="off"
        placeholder="Type a command"
      />

      <ul id="palette-list" role="listbox" aria-label="Commands">
        {#each results as command, index (command.id)}
          <!-- Keyboard interaction for the whole listbox lives on the combobox input:
               focus never leaves it, and aria-activedescendant points here. An option
               with its own key handler would be unreachable by definition. -->
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <li
            id={command.id}
            role="option"
            aria-selected={index === active}
            class:active={index === active}
            onclick={() => choose(command)}
            onmouseenter={() => (active = index)}
          >
            <span>{command.label}</span>
            {#if command.hint}<kbd>{command.hint}</kbd>{/if}
          </li>
        {/each}

        {#if results.length === 0}
          <li class="empty" role="presentation">No command matches “{query}”.</li>
        {/if}
      </ul>
    </div>
  </div>
{/if}

<style>
  .scrim {
    position: fixed;
    inset: 0;
    display: grid;
    justify-items: center;
    align-content: start;
    padding-top: 12vh;
    background: rgb(0 0 0 / 0.4);
  }

  .palette {
    width: min(34rem, calc(100vw - var(--space-6)));
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-raised);
    overflow: hidden;
  }

  input {
    width: 100%;
    min-height: max(var(--control-height), var(--touch-target-min));
    padding: 0 var(--space-4);
    border: 0;
    border-bottom: 1px solid var(--border);
    background: var(--surface);
  }

  ul {
    max-height: 50vh;
    overflow-y: auto;
    margin: 0;
    padding: var(--space-1);
    list-style: none;
  }

  li {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: var(--space-3);
    min-height: var(--touch-target-min);
    padding: 0 var(--space-3);
    border-radius: var(--radius-sm);
    cursor: pointer;
  }

  li.active {
    background: var(--surface-sunken);
    box-shadow: inset 3px 0 0 var(--accent);
  }

  li.empty {
    color: var(--text-muted);
    cursor: default;
  }

  kbd {
    color: var(--text-muted);
    font-size: var(--text-xs);
  }
</style>
