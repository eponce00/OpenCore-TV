# Google TV Home Override Notes

These notes come from testing OpenCore TV on the Google TV device at `192.168.1.12`.

## What Works

- Wireless ADB works after enabling Developer options and Wireless debugging / network ADB.
- OpenCore installs and launches with:

```powershell
.\scripts\install-android-tv.ps1 -Device 192.168.1.12
```

- OpenCore can ask Android to prefer its HOME activity:

```powershell
.\scripts\set-default-launcher-android-tv.ps1 -Device 192.168.1.12
```

## Observed Google TV Behavior

On this device, `cmd package set-home-activity` can report success and OpenCore can appear in preferred activity state, but HOME may still resolve to Google's launcher because the stock launcher is assigned a higher resolver priority.

This is different from Fire TV:

- Fire TV needs Home Guard because Amazon Home is protected and may reopen after HOME.
- Google TV should use normal Android launcher preference first.
- Google TV should not use OpenCore's Fire TV Home Guard repair flow.

## Safe Policy For This Repo

OpenCore should ship one universal APK for now:

- Fire TV profile: enable Home Guard, Fire OS settings destinations, and static Hisense input shortcuts.
- Google TV profile: use standard settings intents, default-launcher checks, and discovered `TvInputManager` inputs.
- Generic Android TV profile: same standard Android behavior, with fewer assumptions.

Do not automatically disable, uninstall, or hide the stock Google TV launcher from install scripts. If a manual experiment leaves the TV without a visible launcher path, use:

```powershell
.\scripts\recover-google-tv-launcher.ps1 -Device 192.168.1.12
```

## Diagnostics

Useful ADB checks:

```powershell
adb -s 192.168.1.12:5555 shell cmd package resolve-activity --user 0 --brief -a android.intent.action.MAIN -c android.intent.category.HOME -c android.intent.category.DEFAULT
adb -s 192.168.1.12:5555 shell dumpsys package preferred-xml --full
adb -s 192.168.1.12:5555 shell cmd package dump tv.opencore.launcher
```
