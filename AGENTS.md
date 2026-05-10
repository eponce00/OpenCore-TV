# AGENTS.md

Guidance for coding agents working on OpenCore TV.

## Project Identity

OpenCore TV is a Flutter/Android launcher for Fire TV / Android TV devices. This fork has diverged from the upstream launcher and should be treated as its own project.

Primary target device:

- Hisense Fire TV / Fire OS 8
- Package id: `tv.opencore.launcher`
- Main non-root Home override path: OpenCore `HomeGuardAccessibilityService`

## Development Commands

Use PowerShell on Windows.

```powershell
. .\scripts\arc-env.ps1
flutter build apk --release
```

Preferred install path for the development TV:

```powershell
.\scripts\dev-install.ps1
```

`dev-install.ps1` installs the APK, restores Home Guard, grants the development permissions needed for self-repair, and launches OpenCore.

## Release Builds

GitHub Releases are published with:

```powershell
.\scripts\publish-release.ps1
```

The script builds the release APK, creates/pushes a `v*` tag based on `pubspec.yaml`, and uploads the APK plus SHA1 file to the GitHub Release.

## Home Guard Rules

Fire OS resolves HOME to Amazon's protected launcher on this model. Normal ADB cannot disable `com.amazon.tv.launcher`, so OpenCore relies on:

- HOME preference where Fire OS honors it.
- `HomeGuardAccessibilityService` when Fire OS briefly opens Amazon Home.
- `WRITE_SECURE_SETTINGS` only when granted through ADB/development scripts.

Do not remove Home Guard or its setup scripts unless replacing the full Home override strategy.

## UX Direction

- OLED-first: dark, quiet, minimal surfaces.
- Avoid bright large glows and heavy colorful UI.
- Prefer large, remote-friendly focus targets.
- Keep settings organized around OpenCore-owned features, not inherited Android/Fire OS menus.
- Avoid TV-hostile dropdowns and file pickers. Use full-row picker pages and preset grids.

## Verification

At minimum for code changes:

```powershell
. .\scripts\arc-env.ps1
flutter build apk --release
```

`flutter analyze` currently reports pre-existing failures from stale inherited tests, so release build is the practical gate until tests are cleaned up.

For TV behavior, use ADB diagnostics instead of screenshots when possible:

```powershell
adb shell dumpsys activity activities
adb shell dumpsys window windows
adb shell dumpsys accessibility
```

## Git Safety

- Do not reintroduce upstream launcher branding.
- Do not commit keystores, local properties, screenshots containing precise personal location data, or build outputs.
- If publishing screenshots, redact exact ZIP/location text unless the user explicitly wants it public.
