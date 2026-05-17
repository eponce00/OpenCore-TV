# AGENTS.md

Guidance for coding agents working on OpenCore TV.

## Project Identity

OpenCore TV is a Flutter/Android launcher for Fire TV, Google TV, and generic Android TV devices. Treat it as its own project with its own UX, package identity, release process, and documentation.

Supported device profiles:

- Fire TV / Fire OS: includes Home Guard and Fire OS-specific settings/input behavior.
- Google TV / generic Android TV: uses standard Android settings, default-launcher setup, and discovered TV inputs where available.
- Package id for all profiles: `tv.opencore.launcher`

## Development Commands

Use PowerShell on Windows.

```powershell
. .\scripts\arc-env.ps1
flutter build apk --release
```

Preferred install path for the Fire TV development device:

```powershell
.\scripts\dev-install.ps1
```

`dev-install.ps1` installs the APK, restores Home Guard, grants the development permissions needed for self-repair, and launches OpenCore.

Preferred install path for Google TV / generic Android TV devices:

```powershell
.\scripts\install-android-tv.ps1 -Device <ip-address>
```

## Release Builds

GitHub Releases are published with:

```powershell
.\scripts\publish-release.ps1
```

The script builds the release APK, creates/pushes a `v*` tag based on `pubspec.yaml`, and uploads the APK plus SHA1 file to the GitHub Release.

## Device Profile Rules

Fire OS resolves HOME to Amazon's protected launcher on this model. Normal ADB cannot disable `com.amazon.tv.launcher`, so OpenCore relies on:

- HOME preference where Fire OS honors it.
- `HomeGuardAccessibilityService` when Fire OS briefly opens Amazon Home.
- `WRITE_SECURE_SETTINGS` only when granted through ADB/development scripts.

Do not remove Home Guard or its setup scripts unless replacing the full Home override strategy.

Do not run Home Guard repair or stock-launcher removal flows on Google TV / generic Android TV. Those devices should use standard HOME/default-launcher setup and reversible recovery scripts.

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
flutter test --no-pub
flutter build apk --release
```

`flutter analyze` may still surface inherited cleanup work; the maintained OpenCore test suite plus release build are the practical gates.

For TV behavior, use ADB diagnostics instead of screenshots when possible:

```powershell
adb shell dumpsys activity activities
adb shell dumpsys window windows
adb shell dumpsys accessibility
```

## Git Safety

- Do not reintroduce old launcher branding outside the README credits section.
- Do not commit keystores, local properties, screenshots containing precise personal location data, or build outputs.
- If publishing screenshots, redact exact ZIP/location text unless the user explicitly wants it public.
