use std::time::{SystemTime, UNIX_EPOCH};

use serde::Serialize;

/// Mirrored by the `Greeting` interface in `src/lib/ipc.ts`.
///
/// `rename_all = "camelCase"` is the only reason `greeted_at` arrives in TypeScript as
/// `greetedAt`. Drop the attribute and the two sides stop matching — at runtime, silently,
/// with no compiler on either side to catch it.
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Greeting {
    message: String,
    greeted_at: u64,
}

/// The reference command.
///
/// Commands return `Result<T, String>` so that a failure reaches the frontend as a
/// rejected promise carrying a message the UI can show. `String` is the floor, not the
/// goal: past a couple of failure modes, replace it with an error enum that derives
/// `Serialize` — the `tauri-ipc` skill shows the shape.
///
/// Parameters are snake_case here and camelCase in the `invoke` call on the JS side;
/// Tauri converts between them.
#[tauri::command]
fn greet(name: &str) -> Result<Greeting, String> {
    let name = name.trim();
    if name.is_empty() {
        return Err("A name is required.".to_string());
    }

    let greeted_at = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|_| "System clock is set before 1970.".to_string())?
        .as_millis() as u64;

    Ok(Greeting {
        message: format!("Hello, {name}! You have been greeted from Rust."),
        greeted_at,
    })
}

/// Shared entry point for every platform.
///
/// `mobile_entry_point` is what the generated Android and iOS projects call; desktop
/// reaches it through `main.rs`. All builder setup belongs here — anything placed in
/// `main` runs on desktop only and is missing on mobile.
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![greet])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
