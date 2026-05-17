# Android TV / Google TV Setup

Use this path for Google TV and non-Fire Android TV devices.

## Enable ADB

1. Open the TV's system settings.
2. Go to About.
3. Select the build number repeatedly until developer options are enabled.
4. Open Developer options.
5. Enable USB debugging, ADB debugging, or Wireless debugging.

For classic wireless ADB:

```powershell
adb connect TV_IP:5555
adb devices -l
```

Approve the debugging prompt on the TV.

## Install OpenCore

```powershell
.\scripts\install-android-tv.ps1 -Device TV_IP
```

To ask Android to prefer OpenCore as the HOME activity without disabling the stock launcher:

```powershell
.\scripts\install-android-tv.ps1 -Device TV_IP -SetHome
```

You can also run the HOME assignment separately:

```powershell
.\scripts\set-default-launcher-android-tv.ps1 -Device TV_IP
```

## Important Boundary

Do not disable the stock Google TV launcher automatically. Some Google TV builds promote a setup/recovery launcher when the stock launcher is disabled, and the TV may restart parts of the user session.

If a Google TV launcher experiment goes sideways and ADB still works:

```powershell
.\scripts\recover-google-tv-launcher.ps1 -Device TV_IP
```

## Fleet Installs

Keep home device details in the gitignored local inventory:

```text
config\tv-fleet.local.yaml
```

Install on every configured TV:

```powershell
.\scripts\install-tv-fleet.ps1
```

Install on one named target:

```powershell
.\scripts\install-tv-fleet.ps1 -Targets upstairs_google_tv
```

Use `-SetHomeAndroidTv` only when you want the script to ask Android TV / Google TV devices to prefer OpenCore as HOME. The script never disables stock Google TV launcher packages.

The Android TV install scripts enable OpenCore's accessibility service so learned remote buttons can be captured before their default action, when Android exposes the button event.

## Current Behavior

OpenCore uses device profiles:

- Google TV and generic Android TV use standard Android settings intents.
- Fire TV-specific Home Guard repair is hidden on non-Fire devices.
- HDMI/input tiles appear only when the device exposes compatible TV inputs through Android's TV input framework.
