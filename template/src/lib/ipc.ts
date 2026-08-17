import { invoke } from '@tauri-apps/api/core'

/**
 * Typed wrappers for every Rust command in `src-tauri/src/lib.rs`.
 *
 * Components import from here and never call `invoke` directly, so that:
 *   - the argument and return shapes are checked at compile time,
 *   - the string command names live in exactly one place,
 *   - a command that is renamed in Rust breaks the build rather than at runtime.
 *
 * Two conversions to keep in mind (both are Tauri/serde behaviour, not ours):
 *   - Argument keys are camelCase here and arrive as snake_case parameters in Rust.
 *   - Returned struct fields are snake_case in Rust; they are camelCase here because the
 *     structs carry `#[serde(rename_all = "camelCase")]`. Drop that attribute and this
 *     interface silently stops matching.
 */

export interface Greeting {
  message: string
  /** Epoch milliseconds, from Rust's `greeted_at`. */
  greetedAt: number
}

/**
 * Rejects with the `Err(String)` returned by the Rust command. Callers are expected to
 * catch and surface the message — see `GreetForm.svelte`.
 */
export async function greet(name: string): Promise<Greeting> {
  return await invoke<Greeting>('greet', { name })
}
