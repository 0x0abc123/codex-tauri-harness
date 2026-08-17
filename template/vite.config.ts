import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import process from 'node:process'

// Set by `tauri android dev` / `tauri ios dev` when targeting a physical device.
// Without it the dev server binds to 127.0.0.1 and the handset cannot reach it.
const host = process.env.TAURI_DEV_HOST

// https://vite.dev/config/
export default defineConfig({
  plugins: [svelte()],

  // Tauri-specific options. Applied always, but only matter under `tauri dev`/`tauri build`.
  //
  // 1. Do not let Vite clear the screen — it eats Rust compiler errors.
  clearScreen: false,
  // 2. Tauri reads a fixed port from tauri.conf.json > build.devUrl. Fail loudly rather
  //    than silently serving on a port Tauri will not open.
  server: {
    port: 1420,
    strictPort: true,
    host: host || '127.0.0.1',
    hmr: host
      ? {
          protocol: 'ws',
          host,
          port: 1421,
        }
      : undefined,
    watch: {
      // 3. src-tauri is Cargo's business; watching it triggers pointless frontend reloads.
      ignored: ['**/src-tauri/**'],
    },
  },
})
