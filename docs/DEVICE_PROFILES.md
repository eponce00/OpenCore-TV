# Device Profiles

OpenCore TV uses runtime device profiles so one APK can support Fire TV, Google TV, and generic Android TV devices.

## Profiles

### Fire TV

Detected when Amazon launcher/settings packages are installed or the manufacturer identifies as Amazon.

Capabilities:

- Home Guard accessibility rescue.
- Optional Home Guard self-repair when `WRITE_SECURE_SETTINGS` was granted by ADB.
- Amazon settings destinations.
- Hisense/MediaTek static input shortcuts on the current target TV.
- Fire OS remote-button remap hooks.

### Google TV

Detected when `com.google.android.apps.tv.launcherx` is installed.

Capabilities:

- Standard Android settings intents.
- Default-launcher checking.
- TV input discovery when Android exposes `TvInputManager` entries.

Home Guard is hidden by default.

### Generic Android TV

Fallback profile.

Capabilities:

- Standard Android settings intents.
- Default-launcher checking.
- TV input discovery when Android exposes `TvInputManager` entries.

## Flutter Surface

The native layer exposes capabilities through the `getDeviceCapabilities` method channel call. `AppsService` caches the result as `deviceProfile`.

Settings pages should check capabilities instead of checking platform names directly.

## Native Surface

`MainActivity` currently owns profile detection and settings/input behavior. If the native layer grows, split this into focused strategy classes:

- `DeviceProfile`
- `SettingsLauncher`
- `InputRepository`
- `HomeOverrideStrategy`
- `RemoteButtonMapper`

## Release Strategy

One universal APK remains the default. Add product flavors only if manifest permissions, Play policy, or release packaging require separate Fire TV and Android TV artifacts.
