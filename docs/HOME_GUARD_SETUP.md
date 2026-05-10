# OpenCore Home Guard Setup

OpenCore uses `HomeGuardAccessibilityService` to keep the Fire TV Home button on OpenCore. Fire OS still resolves HOME to Amazon's protected launcher, and this TV blocks disabling or uninstalling Amazon Home without elevated privileges, so Home Guard is the non-root rescue layer.

## What The App Can Do

- Detect whether Home Guard is enabled.
- Try to repair Home Guard automatically if `WRITE_SECURE_SETTINGS` was granted by ADB after install.
- Repair Home Guard on OpenCore resume when that ADB-granted permission is available.
- Open Android/Fire OS Accessibility settings so Home Guard can be enabled manually.
- Mask brief Amazon Home flashes with the accessibility overlay while it rescues OpenCore.

## What The App Cannot Do By Itself

- Silently enable Accessibility forever on a normal consumer install.
- Grant itself `WRITE_SECURE_SETTINGS`, `READ_LOGS`, or overlay app-ops.
- Disable `com.amazon.tv.launcher` on this Fire OS 8.1.7.1 build.

Those actions require ADB, root, or system/privileged app status. For our development TV, the install scripts grant what OpenCore needs after each APK install.

## Recovery Commands

Preferred one-command recovery:

```powershell
.\scripts\enable-home-guard.ps1
```

Manual equivalent:

```powershell
adb shell settings put secure accessibility_enabled 1
adb shell settings put secure enabled_accessibility_services tv.opencore.launcher/tv.opencore.launcher.HomeGuardAccessibilityService
adb shell appops set tv.opencore.launcher SYSTEM_ALERT_WINDOW allow
adb shell pm grant tv.opencore.launcher android.permission.READ_LOGS
adb shell pm grant tv.opencore.launcher android.permission.WRITE_SECURE_SETTINGS
adb shell monkey -p tv.opencore.launcher -c android.intent.category.LAUNCHER 1
```

## Development Rule

Use `scripts/dev-install.ps1` for future installs instead of raw `adb install -r`. The script rebuilds, installs, restores Home Guard, grants the needed development permissions, and launches OpenCore.
