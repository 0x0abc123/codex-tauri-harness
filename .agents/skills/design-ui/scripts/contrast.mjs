#!/usr/bin/env node
// WCAG 2.x contrast ratios. Measure the palette; never estimate it.
//
//   node contrast.mjs '#1a56c4' '#ffffff'          one pair
//   node contrast.mjs --tokens path/to/app.css     every colour token against its surface
//
// Thresholds: 4.5 body text, 3.0 large text (>=24px, or >=18.66px bold), 3.0 control
// boundaries and any border that carries meaning (WCAG 1.4.11).

import { readFileSync } from 'node:fs'
import process from 'node:process'

const channel = (v) => {
  const c = v / 255
  return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4
}

const luminance = (hex) => {
  const h = hex.replace('#', '')
  const full = h.length === 3 ? [...h].map((c) => c + c).join('') : h
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(full.slice(i, i + 2), 16))
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
}

const ratio = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x)
  return (hi + 0.05) / (lo + 0.05)
}

const verdict = (r) =>
  r >= 4.5 ? 'AA body' : r >= 3 ? 'AA large / boundary only' : 'FAILS'

const args = process.argv.slice(2)

if (args[0] === '--tokens') {
  const css = readFileSync(args[1] ?? 'src/app.css', 'utf8')

  // Each `:root`-ish block is a theme. Compare every colour token in it against the
  // --surface declared in the same block.
  const blocks = css.split(/(?=:root)/).filter((b) => b.includes('--surface:'))
  if (blocks.length === 0) {
    console.error('no theme block containing --surface: found')
    process.exit(1)
  }

  let failures = 0
  for (const [i, block] of blocks.entries()) {
    const tokens = new Map(
      [...block.matchAll(/(--[a-z0-9-]+)\s*:\s*(#[0-9a-fA-F]{3,8})\s*;/g)].map((m) => [
        m[1],
        m[2],
      ]),
    )
    const surface = tokens.get('--surface')
    const label = block.match(/^:root[^{]*/)?.[0].trim() ?? `block ${i}`
    console.log(`\n${label}  (against ${surface})`)

    for (const [name, value] of tokens) {
      if (name === '--surface' || name.startsWith('--surface-')) continue

      // `--x-contrast` is the text colour laid on `--x`, so measure it against that.
      const pairedWith = name.endsWith('-contrast')
        ? tokens.get(name.replace(/-contrast$/, ''))
        : undefined
      const against = pairedWith ?? surface
      const r = ratio(value, against)
      const v = verdict(r)
      // Decorative separators have no floor; everything else should clear 3:1 at least.
      const exempt = name === '--border'
      if (v === 'FAILS' && !exempt) failures++
      console.log(
        `  ${name.padEnd(18)} ${value.padEnd(9)} ${r.toFixed(2).padStart(6)}:1  ${
          exempt ? 'decorative' : v
        }${pairedWith ? `  (on ${pairedWith})` : ''}`,
      )
    }
  }
  console.log(failures ? `\n${failures} token(s) below 3:1` : '\nno token below 3:1')
  process.exit(failures ? 1 : 0)
}

if (args.length !== 2) {
  console.error("usage: contrast.mjs '#foreground' '#background' | --tokens <app.css>")
  process.exit(2)
}

const r = ratio(args[0], args[1])
console.log(`${args[0]} on ${args[1]}: ${r.toFixed(2)}:1  ${verdict(r)}`)
process.exit(r >= 3 ? 0 : 1)
