# OpenCore TV Settings Audit

Goal: make settings feel like they belong to this Hisense Fire TV launcher, not a pile of inherited Android TV options.

## Proposed Top-Level Structure

- Home Screen: favorites row, app sections, app labels, dock blur, focus animation, key click sound.
- Clock: Home clock size/visibility, Home date visibility, idle clock size/date/24-hour format.
- Wallpaper: bundled wallpaper library, rotation, gradients.
- Idle / Screensaver: enable idle, idle timeout, Home button enters idle, clock shortcut, weather placement.
- Weather: units, current location, city/ZIP search, refresh status.
- Inputs: HDMI/input names, icons, favorites organization, future custom icons.
- Apps: show/hide apps, app categories, favorites, reorder.
- Network: connection status, network indicator visibility, usage period, link to Fire TV settings only as an escape hatch.
- Device Tools: brightness scheduler, date/time format, network usage period.
- Native Fire TV Settings: direct callable Fire OS sections only, not the protected root hub.
- About / Health: version, license, Home Guard status and repair.

## Current Cleanup Notes

- `InterfaceSettingsPage` was removed because the top-level `OpenCore Settings` page now owns the structure.
- `GeneralSettingsPage` has been cleaned up into a user-facing `Device Tools` page while keeping the route stable.
- `StatusBarPanelPage` was removed; useful Home/status toggles moved into `Home Display`, `Clock`, and `System`.
- `MiscPanelPage` was renamed and refocused as `Home Display`.
- Old screensaver clock styles were removed because OpenCore idle uses its own overlay now.
- Old Back button action settings were removed because Back on Home should be a safe no-op, while settings panels already pop normally.
- Any setting that launches broken Fire OS panels should either be removed or clearly labeled as an external escape hatch.
- The protected Fire TV root settings hub is intentionally not exposed as a fake "main settings" shortcut because Fire OS redirects it through Amazon Home.

## Immediate Direction

- Keep the top-level page flat and obvious for TV remote use.
- Prefer full-row picker pages over dropdowns.
- Avoid Android file pickers unless there is no TV-safe alternative.
- Keep settings labels user-facing and concrete: "Clock", "Inputs", "Weather", not "Miscellaneous" or "Status Bar".
- Keep inherited route names only when useful for stability; user-facing labels should be OpenCore-owned.
