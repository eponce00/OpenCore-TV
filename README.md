# OpenCore TV

OpenCore TV is a custom Android/Fire TV launcher built around a clean home screen, high-resolution wallpapers, local input shortcuts, weather, and an integrated idle/screensaver mode.

This repo is tuned first for a Hisense Fire TV setup, especially Fire OS devices where the stock launcher cannot be fully disabled without system privileges. OpenCore uses its own Home Guard service to keep the TV centered on the custom launcher.

## Screenshots

| Home | Idle / Screensaver | Control Center |
| --- | --- | --- |
| ![OpenCore TV home](docs/images/opencore-home.png) | ![OpenCore TV idle mode](docs/images/opencore-idle.png) | ![OpenCore TV control center](docs/images/opencore-settings.png) |

## What It Does

- Replaces the stock TV home flow with a custom launcher experience.
- Shows apps and HDMI/source shortcuts together so inputs can live in Favorites.
- Lets input tiles use custom labels and icons.
- Uses bundled high-resolution wallpapers instead of relying on broken Android TV wallpaper pickers.
- Adds weather, clock, and location-aware home/idle widgets.
- Turns the launcher into its own idle/screensaver surface instead of depending on Fire OS screensaver routing.
- Includes Home Guard accessibility support to pull the TV back into OpenCore TV when Fire OS tries to show the stock launcher.
- Adds an OpenCore Health settings page to verify and repair Home Guard after reinstalls.
- Ships development scripts that restore the ADB-granted permissions Fire OS requires for a seamless Home button flow.

## Build

Stable APKs are published on the [GitHub Releases page](https://github.com/eponce00/OpenCore-TV/releases). Use the local build flow when developing or testing changes directly on the TV.

To publish a new GitHub Release:

```powershell
.\scripts\publish-release.ps1
```

```powershell
. .\scripts\arc-env.ps1
flutter pub get --offline
flutter build apk --release
```

The release APK is generated at:

```text
build\app\outputs\flutter-apk\app-release.apk
```

## Install / Update

```powershell
.\scripts\dev-install.ps1
```

`dev-install.ps1` builds the release APK, installs it, restores Home Guard, grants the development permissions used by the Home rescue flow, and launches OpenCore.

If Fire OS ever disables Home Guard after an update or reinstall:

```powershell
.\scripts\enable-home-guard.ps1
```

Details and manual recovery commands live in [docs/HOME_GUARD_SETUP.md](docs/HOME_GUARD_SETUP.md).

## Development Notes

- Package id: `tv.opencore.launcher`
- Flutter package: `opencore_tv`
- Agent/project guide: [AGENTS.md](AGENTS.md)
- Feature tracker: [docs/FEATURE_TRACKER.md](docs/FEATURE_TRACKER.md)
- Home Guard setup: [docs/HOME_GUARD_SETUP.md](docs/HOME_GUARD_SETUP.md)
- Settings audit: [docs/SETTINGS_AUDIT.md](docs/SETTINGS_AUDIT.md)

## Credits

OpenCore TV is now maintained as its own project, but it stands on work from several open-source Android TV launcher projects:

- [FLauncher](https://gitlab.com/etienn01/flauncher) by etienn01: original project lineage.
- [FLauncher fork](https://github.com/osrosal/flauncher) by osrosal: community fork with additional features.
- [LTvLauncher](https://github.com/LeanBitLab/LTvLauncher) by LeanBitLab: base used by later forks.
- [ArcLauncher](https://github.com/meddouribadis/arclauncher) by meddouribadis: direct starting point for OpenCore TV.

## License

This project is GPL-3.0-or-later. See [LICENSE](LICENSE).
