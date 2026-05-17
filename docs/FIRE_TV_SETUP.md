# Fire TV Setup

Use this path for the Hisense Fire TV / Fire OS target.

Fire OS may resolve HOME to Amazon's protected launcher even when OpenCore is installed as a launcher. OpenCore keeps the Fire TV flow usable through Home Guard, an accessibility-based rescue path.

## Install OpenCore

```powershell
.\scripts\install-fire-tv.ps1
```

This wraps the development Fire TV install flow:

- Builds the APK.
- Installs it on the configured Fire TV.
- Restores Home Guard.
- Grants development permissions used for self-repair.
- Launches OpenCore.

The older script remains available:

```powershell
.\scripts\dev-install.ps1
```

## Repair Home Guard

If Fire OS disables accessibility services after reinstall or update:

```powershell
.\scripts\enable-home-guard.ps1
```

More details live in [HOME_GUARD_SETUP.md](HOME_GUARD_SETUP.md).

## Fire TV-Specific Features

The Fire TV profile enables:

- Home Guard and optional ADB-granted self-repair.
- Amazon settings destinations that are callable from custom launchers.
- Hisense/MediaTek HDMI, antenna, and composite input shortcuts.
- Learned remote-button remapping for keys Android exposes to OpenCore.

These features are hidden or replaced with generic behavior on Google TV and generic Android TV profiles.
