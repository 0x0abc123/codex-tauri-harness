# Mobile checklist

Work through this before claiming a mobile target is done. Anything not actually run on a
device or emulator is unverified — say so rather than implying otherwise.

## Build

- [ ] `[lib] crate-type = ["staticlib", "cdylib", "rlib"]` in `src-tauri/Cargo.toml`
- [ ] `#[cfg_attr(mobile, tauri::mobile_entry_point)]` on `run()`
- [ ] Every builder call (`.plugin`, `.manage`, `.setup`, `.invoke_handler`) is inside
      `run()`, not `main()`
- [ ] Rust cross-compilation targets installed for the platform
- [ ] `npm run tauri android init` / `ios init` completed without error
- [ ] Decision recorded on whether `src-tauri/gen/` is committed — required once the
      manifest, Gradle files or signing settings are hand-edited

## Dev server

- [ ] `vite.config.ts` uses `process.env.TAURI_DEV_HOST` for `server.host`
- [ ] HMR websocket configured on port 1421 when that host is set
- [ ] Physical iOS device reaches the dev server (this is what `TAURI_DEV_HOST` exists for)
- [ ] Firewall allows 1420 and 1421 on the development machine

## Permissions

- [ ] Mobile-only capabilities in their own file with `"platforms": ["iOS", "android"]`
- [ ] That file uses `../gen/schemas/mobile-schema.json`, not the desktop schema
- [ ] Every plugin used has its permission granted (`check-acl.sh`)
- [ ] Android manifest entries added for native permissions the app requests
- [ ] `Info.plist` usage-description strings added for every iOS permission — the OS refuses
      the request without one, and the failure never mentions Tauri

## Layout

- [ ] `viewport-fit=cover` in `index.html` (without it, `env(safe-area-inset-*)` is zero)
- [ ] Shell padded with `env(safe-area-inset-*)` — notch, home indicator, rounded corners
- [ ] Every touch target at least `var(--touch-target-min)` (44px)
- [ ] Primary action reachable by thumb, not stranded in a top corner
- [ ] Focused field and its submit button stay visible with the keyboard open
- [ ] Layout adapts rather than shrinking: primary task, primary content, secondary
      controls, decoration — in that order
- [ ] Readable with the OS text size increased (tokens are `rem`-based; hard-coded pixels
      are not)
- [ ] Landscape checked as well as portrait

## Behaviour

- [ ] Reference IPC call round-trips on the device, not only on the desktop build
- [ ] App survives backgrounding and resuming
- [ ] Slow and offline network handled with visible state, not a silent hang
- [ ] Back gesture / hardware back button does something sensible on Android

## Release

- [ ] Placeholder artwork replaced (`npm run tauri icon <path>`)
- [ ] Bundle identifier final — changing it after `init` means regenerating both platforms
- [ ] No keystore, provisioning profile or API key committed
- [ ] Version numbers aligned across `tauri.conf.json`, `package.json` and `Cargo.toml`
