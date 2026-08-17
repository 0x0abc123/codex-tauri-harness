---
name: mobile-target
description: Initialise, run and debug the Android and iOS targets of a Tauri 2 app, including device dev servers, platform capabilities, native permissions and mobile-specific layout obligations. Use when the user says "run it on Android", "build for iOS", "test on my phone", when something works on desktop but not on a device, or invokes /mobile-target.
---

# Target Android and iOS

The same Rust and Svelte code ships to both; what differs is the toolchain, the capability
platform scoping, the native permissions and the layout constraints.

Done means: the app launches on the target device or emulator, the reference IPC call
round-trips there, and anything the platform still needs from the user is named explicitly.

## Before anything else

`scripts/doctor.sh` reports what is missing. Do not attempt to install an SDK, an NDK or
Xcode — name what is absent and let the user install it.

| | Android | iOS (macOS only) |
|---|---|---|
| Toolchain | Android Studio, SDK, NDK | Xcode — not just the Command Line Tools |
| Environment | `JAVA_HOME`, `ANDROID_HOME`, `NDK_HOME` | — |
| Rust targets | `aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android` | `aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim` |
| Also | — | CocoaPods (`brew install cocoapods`) |

```bash
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
```

## Process

**1. Confirm the app is mobile-ready.** The template already is; verify anyway, because
these are the failures that read as toolchain problems:

- `src-tauri/Cargo.toml` has `[lib] crate-type = ["staticlib", "cdylib", "rlib"]`.
- `src-tauri/src/lib.rs` has `#[cfg_attr(mobile, tauri::mobile_entry_point)]` on `run()`,
  and **all** builder setup lives in `run()`. Anything in `main()` exists on desktop only.
- `vite.config.ts` honours `TAURI_DEV_HOST` for `server.host` and the HMR websocket.

**2. Initialise.** Once per platform, per project:

```bash
npm run tauri android init
npm run tauri ios init
```

This generates `src-tauri/gen/android` and `src-tauri/gen/apple` — full Gradle and Xcode
projects. The template `.gitignore` excludes them, which is right until you hand-edit the
manifest, Gradle files or signing settings; from that point they must be committed. Say
which situation the project is in rather than leaving it implicit.

**3. Run.**

```bash
npm run tauri android dev            # emulator or attached device
npm run tauri ios dev                # simulator or attached device
npm run tauri android dev --open     # open the project in Android Studio / Xcode instead
```

A **physical iOS device** cannot reach `127.0.0.1`, so the CLI sets `TAURI_DEV_HOST` to a
reachable address and the Vite config must bind to it — it already does. If HMR hangs on a
device but works in the simulator, that binding is the first thing to check, followed by the
firewall on port 1420/1421.

**4. Scope capabilities per platform.** A capability with no `platforms` key applies
everywhere. Anything mobile-only belongs in its own file:

```json
{
  "$schema": "../gen/schemas/mobile-schema.json",
  "identifier": "mobile",
  "description": "Permissions that only make sense on a handset.",
  "platforms": ["iOS", "android"],
  "windows": ["main"],
  "permissions": ["core:default"]
}
```

Note the schema differs from the desktop one, and that `"iOS"` is capitalised that way while
`"android"` is not.

**5. Declare native permissions.** Camera, location, notifications and the rest need an
entry in the Android manifest (`src-tauri/gen/android/app/src/main/AndroidManifest.xml`) or
in the iOS `Info.plist` with a usage description string, *in addition to* the Tauri
capability. Missing the native half fails at the OS prompt, not in Tauri, so the error will
not mention Tauri at all. Check the plugin's own docs with `consult-docs -c tauri`.

**6. Check the layout on a handset**, not just a narrow desktop window:

- Safe areas: the template's shell already pads with `env(safe-area-inset-*)`, which needs
  `viewport-fit=cover` in `index.html` to have any effect. Both are present; keep them.
- Touch targets at `var(--touch-target-min)` (44px) minimum.
- The primary action should be reachable by thumb — bottom of the screen, not the top
  corner.
- The on-screen keyboard covers roughly half the viewport: ensure the focused field and its
  submit button stay visible.
- Test with the OS text size increased. `rem`-based tokens scale; hard-coded pixels do not.

**7. Debug what you cannot see.** The webview is inspectable: Chrome DevTools at
`chrome://inspect` for Android, Safari's Develop menu for iOS. Rust-side logging surfaces
through `adb logcat` and the Xcode console.

**8. Work through `references/mobile-checklist.md`** before calling the target done. It
covers build, dev server, permissions, layout, behaviour and release in the order they
usually break.

## Guardrails

- **Never commit signing material.** Keystores, provisioning profiles, `.p12` files and API
  keys stay out of the repository; wire them through environment variables or the platform's
  own secret storage.
- **Never edit `src-tauri/gen/` casually.** It regenerates. If a change must persist, say so
  explicitly and get the directory committed deliberately.
- **Never assume a desktop-passing build works on mobile.** Different webview engines, a
  different linker, and a different permission model. Claim it works only after it ran.
- **Do not install SDKs or accept licences on the user's behalf.** Report what is missing.
- **Do not change the bundle identifier after `init`.** The generated projects embed it;
  changing it means regenerating both platforms.
- **Do not paper over a device-only failure with a desktop-only code path.** One codebase.
