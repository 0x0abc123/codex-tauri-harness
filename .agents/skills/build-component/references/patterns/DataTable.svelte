<script lang="ts" generics="Row extends { id: string }">
  // A scannable table: sticky header, sortable columns, right-aligned numbers, keyboard
  // row selection. Built on a real <table> so screen readers announce row and column
  // position without any ARIA at all.
  //
  // `generics="Row extends { id: string }"` on the script tag is how Svelte 5 declares a
  // generic component. Rows are identified by `id`, never by array index.

  interface Column {
    key: string
    label: string
    /** Right-aligns the column and sorts it numerically. */
    numeric?: boolean
    value: (row: Row) => string | number
  }

  interface Props {
    /** Describes the table for screen readers. Visible by default — it aids everyone. */
    caption: string
    columns: Column[]
    rows: Row[]
    selectedId?: string | null
  }

  let { caption, columns, rows, selectedId = $bindable(null) }: Props = $props()

  // Null means "no explicit choice yet"; the effective key is derived, so reading a prop
  // here does not freeze its initial value. Initialising state directly from a prop is
  // the commonest runes mistake — svelte-check flags it as `state_referenced_locally`.
  let sortKey = $state<string | null>(null)
  let ascending = $state(true)

  const activeKey = $derived(sortKey ?? columns[0]?.key ?? '')

  const sorted = $derived.by(() => {
    const column = columns.find((c) => c.key === activeKey)
    if (!column) return rows
    const direction = ascending ? 1 : -1
    return [...rows].sort((a, b) => {
      const left = column.value(a)
      const right = column.value(b)
      if (typeof left === 'number' && typeof right === 'number') {
        return (left - right) * direction
      }
      return String(left).localeCompare(String(right), undefined, { numeric: true }) * direction
    })
  })

  function sortBy(key: string) {
    if (activeKey === key) ascending = !ascending
    else {
      sortKey = key
      ascending = true
    }
  }

  function onRowKeydown(event: KeyboardEvent, index: number) {
    const last = sorted.length - 1
    let next: number | null = null
    if (event.key === 'ArrowDown') next = Math.min(index + 1, last)
    else if (event.key === 'ArrowUp') next = Math.max(index - 1, 0)
    else if (event.key === 'Home') next = 0
    else if (event.key === 'End') next = last
    else if (event.key === ' ' || event.key === 'Enter') {
      event.preventDefault()
      selectedId = sorted[index]?.id ?? null
      return
    }
    if (next === null) return
    event.preventDefault()
    const row = sorted[next]
    if (!row) return
    selectedId = row.id
    document.getElementById(`row-${row.id}`)?.focus()
  }
</script>

<div class="scroll">
  <table>
    <caption>{caption}</caption>
    <thead>
      <tr>
        {#each columns as column (column.key)}
          <th
            scope="col"
            class:numeric={column.numeric}
            aria-sort={activeKey === column.key
              ? ascending
                ? 'ascending'
                : 'descending'
              : 'none'}
          >
            <button type="button" onclick={() => sortBy(column.key)}>
              {column.label}
              <!-- The arrow is decorative; aria-sort carries the meaning. -->
              <span aria-hidden="true">
                {activeKey === column.key ? (ascending ? '▲' : '▼') : ''}
              </span>
            </button>
          </th>
        {/each}
      </tr>
    </thead>
    <tbody>
      {#each sorted as row, index (row.id)}
        <!-- aria-current, not aria-selected: a row only supports aria-selected inside a
             role="grid", and declaring a grid commits you to cell-level focus management. -->
        <tr
          id="row-{row.id}"
          tabindex={index === 0 || row.id === selectedId ? 0 : -1}
          aria-current={row.id === selectedId ? 'true' : undefined}
          class:selected={row.id === selectedId}
          onclick={() => (selectedId = row.id)}
          onkeydown={(event) => onRowKeydown(event, index)}
        >
          {#each columns as column (column.key)}
            <td class:numeric={column.numeric}>{column.value(row)}</td>
          {/each}
        </tr>
      {/each}
    </tbody>
  </table>

  {#if sorted.length === 0}
    <p class="empty">Nothing to show yet.</p>
  {/if}
</div>

<style>
  /* One scroll container. Nested scrolling regions are an anti-pattern. */
  .scroll {
    overflow: auto;
    max-height: 60vh;
    border: 1px solid var(--border);
    border-radius: var(--radius-md);
  }

  table {
    width: 100%;
    border-collapse: collapse;
    font-size: var(--text-sm);
  }

  caption {
    padding: var(--space-3) var(--space-4);
    text-align: left;
    font-weight: var(--weight-medium);
  }

  th {
    position: sticky;
    top: 0;
    z-index: 1;
    padding: 0;
    background: var(--surface-raised);
    border-bottom: 1px solid var(--border-strong);
    text-align: left;
    white-space: nowrap;
  }

  th button {
    width: 100%;
    min-height: var(--touch-target-min);
    padding: 0 var(--space-3);
    background: none;
    border: 0;
    font-weight: var(--weight-medium);
    text-align: inherit;
    cursor: pointer;
  }

  td {
    padding: var(--space-2) var(--space-3);
    border-bottom: 1px solid var(--border);
  }

  /* Numbers align on their last digit so magnitudes can be compared by eye. */
  .numeric,
  .numeric button {
    text-align: right;
    font-variant-numeric: tabular-nums;
  }

  tr.selected {
    /* Selection is marked by weight and a rule as well as by tint. */
    background: var(--surface-sunken);
    box-shadow: inset 3px 0 0 var(--accent);
  }

  .empty {
    padding: var(--space-5);
    color: var(--text-muted);
    text-align: center;
  }
</style>
