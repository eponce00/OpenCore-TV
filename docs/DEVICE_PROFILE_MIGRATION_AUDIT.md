# OpenCore TV Device Profile Migration Audit

Goal: evolve OpenCore TV from a Hisense Fire TV-first launcher into one codebase that supports Fire TV, Google TV, and generic Android TV without losing the Fire OS rescue work that makes the primary TV usable.

## Recommendation

Keep one repo, one product identity, and one package id for now:

- Repo: `OpenCore-TV`
- App: `OpenCore TV`
- Package id: `tv.opencore.launcher`
- Default release: one universal APK

Do not split into a second repo yet. The core launcher experience, Flutter UI, app organization, wallpapers, idle overlay, weather, and settings shell are shared. The platform-specific parts should be isolated behind device profiles and capability checks.

Add build flavors later only if there is a concrete reason, such as Play Store policy, manifest permission cleanup, or materially different release behavior.

## Implementation Status

Initial migration is implemented and verified locally:

- Native `MainActivity` exposes `getDeviceCapabilities` over the existing method channel.
- Runtime profiles detect Fire TV, Google TV, and generic Android TV.
- Fire TV keeps Home Guard, Amazon settings destinations, static Hisense/MediaTek inputs, and remote-button remap hooks.
- Google TV and generic Android TV use standard Android settings intents, default-launcher checks, and discovered `TvInputManager` inputs when available.
- Home Guard repair is gated to Fire TV and no longer runs on every resume for non-Fire devices.
- Settings copy and routes now use generic `System Settings` and `Launcher Protection` labels, with Fire-specific details only when the active profile supports them.
- New install/recovery docs and scripts separate Fire TV and Android TV setup paths.
- Verification completed with `flutter test --no-pub` and `flutter build apk --release`.

## Target Architecture

Introduce a small native/device abstraction layer:

- `DeviceProfile`
- `FireTvProfile`
- `GoogleTvProfile`
- `GenericAndroidTvProfile`

Expose the active profile and capabilities to Flutter through the existing method channel.

Suggested capability fields:

- `deviceProfile`: `fireTv`, `googleTv`, `androidTv`
- `deviceLabel`: display name such as `Fire TV`, `Google TV`, `Android TV`
- `supportsHomeGuard`
- `supportsHomeSelfRepair`
- `supportsStockLauncherDisable`
- `supportsAmazonSettings`
- `supportsTvInputDiscovery`
- `supportsStaticHisenseInputs`
- `supportsRemoteButtonRemap`
- `supportsUsageStats`
- `supportsSystemBrightness`

The Flutter UI should render from capabilities rather than hardcoded platform names.

## Current Fire TV-Specific Assumptions

### Flutter UI And Settings

Files with visible Fire TV wording or Fire-only concepts:

- `lib/widgets/settings/settings_panel_page.dart`
  - Shows `Home Guard`.
  - Shows `Native Fire TV`.
  - Always queries Home Guard health.
- `lib/widgets/settings/opencore_health_page.dart`
  - Copy refers to `Home Guard`, `Fire OS`, and `Fire TV Home button`.
  - Repair flow assumes ADB-granted `WRITE_SECURE_SETTINGS`.
- `lib/widgets/settings/native_fire_tv_settings_page.dart`
  - Entire page is Fire TV-specific.
  - Uses Amazon settings actions such as `com.amazon.device.settings.action.DEVICE`.
- `lib/widgets/settings/general_settings_page.dart`
  - Mentions Native Fire TV sections and Fire TV system settings.
- `lib/widgets/settings/remote_buttons_settings_page.dart`
  - Originally used Fire TV branded button presets.
  - Migrated to learned remote buttons so each TV remote can define its own mappings.
- `lib/widgets/network_info_panel.dart`
  - Button says `Open Fire TV Network Settings`.
- `lib/widgets/application_info_panel.dart`
  - Copy says custom banner picking is disabled on this Fire TV.
- `lib/widgets/settings/opencore_about_dialog.dart`
  - Legalese says built for a customized Fire TV setup.
- `lib/providers/apps_service.dart`
  - Default favorites include Amazon YouTube package `com.amazon.firetv.youtube`.

Recommended UI replacements:

- Rename visible `Home Guard` to `Home Button Control` or `Launcher Protection`.
- Rename `Native Fire TV` to `System Settings` or `Device Settings`.
- Keep Fire-specific detail inside a Fire TV-only subsection.
- Hide Home Guard repair on Google TV unless the active profile says it is supported.
- Use `Open Network Settings`, not `Open Fire TV Network Settings`.
- Use `device` wording for generic limitations.
- Build default app favorites from installed package candidates, not a Fire-only package preference.

### Android Native Layer

Manifest assumptions in `android/app/src/main/AndroidManifest.xml`:

- `WRITE_SECURE_SETTINGS`, `READ_LOGS`, and `SYSTEM_ALERT_WINDOW` are development/Firebase style permissions; normal Android TV installs will not get them.
- Amazon permissions are declared:
  - `com.amazon.tv.permission.TUNE_INPUT`
  - `com.amazon.tv.livetv.permission.TUNE_CHANNEL`
  - `com.amazon.tv.inputpreference.permission.LAUNCH_INPUTS`
- Amazon packages are queried:
  - `com.amazon.tv.inputpreference.service`
  - `com.amazon.tv.livetv`

Native Fire TV assumptions:

- `HomeGuardAccessibilityService.java`
  - Watches `com.amazon.tv.launcher`.
  - Watches `com.amazon.tv.inputpreference.service`.
  - Uses Amazon class heuristics: `SettingsActivity`, `PassthroughPlayerActivity`, `RecentDeepLinkActivityDI`.
  - Uses logcat hooks for Amazon launcher/input/remote-button activity.
  - Consumes HOME and input keys when enabled.
- `MainActivity.java`
  - `repairHomeGuard()` writes secure accessibility settings.
  - `launchActivityFromAction()` pins `android.settings.*` actions to `com.amazon.tv.settings.v2`.
  - `openSettings()` and `openWifiSettings()` try Amazon settings components first.
  - Always appends synthetic input apps.
  - Writes vendor-ish brightness keys such as `backlight` and `backlight_level`.
- `OpenCoreInputs.java`
  - Hardcodes Hisense/MediaTek input IDs:
    - HDMI 1: `com.mediatek.tis/.HdmiInputService/HW2`
    - HDMI 2: `com.mediatek.tis/.HdmiInputService/HW3`
    - HDMI 3: `com.mediatek.tis/.HdmiInputService/HW4`
    - HDMI 4: `com.mediatek.tis/.HdmiInputService/HW5`
    - Antenna: `com.mediatek.dtv.tvinput.atsctuner/.AtscTunerInputService/HW0`
    - Composite: `com.mediatek.tis/.CompositeInputService/HW6`
- `OpenCoreRemoteButtons.java`
  - Removed after learned remote buttons replaced Amazon ASIN/deeplink parsing.

Highest-risk portability bug:

- `MainActivity.launchActivityFromAction()` currently forces all `android.settings.*` intents into `com.amazon.tv.settings.v2`. On Google TV this can break otherwise-valid standard Android settings actions.

### Scripts And Release Workflow

Fire TV-specific scripts:

- `scripts/dev-install.ps1`
  - Hardcodes Fire TV dev IP.
  - Grants Home Guard permissions.
  - Restores Home Guard after install.
- `scripts/enable-home-guard.ps1`
- `scripts/disable-stock-launcher.ps1`
- `scripts/remove-stock-launchers-for-user.ps1`
- `scripts/restore-stock-launcher.ps1`
- `scripts/restore-stock-launchers-for-user.ps1`

Shared scripts with light cleanup:

- `scripts/publish-release.ps1`
  - Mostly shared.
  - Release notes mention Home Guard; make generic or profile-aware.
- `scripts/launch.ps1`
  - Should default to release package `tv.opencore.launcher`, not debug package unless requested.
- `scripts/screenshot.ps1`
  - Shared, parameterize device.

Recommended script layout:

- `scripts/install-android-tv.ps1`
  - Build/install/launch only.
  - Optional `-SetHome` that runs the safe `cmd package set-home-activity` command.
  - No launcher disabling by default.
- `scripts/install-fire-tv.ps1`
  - Build/install/launch.
  - Restore Home Guard.
  - Grant development permissions.
  - Fire OS recovery notes.
- `scripts/set-default-launcher-android-tv.ps1`
  - Safe default launcher assignment.
  - Never disables stock launcher unless passed an explicit dangerous flag.
- `scripts/recover-google-tv-launcher.ps1`
  - Re-enable known Google TV launcher packages after experiments.

### Documentation And Metadata

Docs to split or reframe:

- `README.md`
  - Make the top-level README universal.
  - Add sections for Fire TV setup and Android TV/Google TV setup.
- `AGENTS.md`
  - Keep shared project identity.
  - Move Hisense Fire TV and Home Guard rules into a Fire TV-specific section.
- `docs/HOME_GUARD_SETUP.md`
  - Rename or clearly scope as Fire TV Home Guard setup.
- `docs/FEATURE_TRACKER.md`
  - Split current Hisense/Fire TV notes from shared roadmap.
- `docs/SETTINGS_AUDIT.md`
  - Split Fire TV settings limitations from general settings UX.
- `docs/CUSTOMIZATION_PLAN.md`
  - Keep as Hisense-specific notes, not general product guidance.
- `fastlane/metadata/android/en-US/full_description.txt`
  - Make Home Guard a Fire TV capability, not the universal headline.

Docs to add:

- `docs/ANDROID_TV_SETUP.md`
- `docs/FIRE_TV_SETUP.md`
- `docs/DEVICE_PROFILES.md`
- `docs/GOOGLE_TV_HOME_OVERRIDE_NOTES.md`

## Google TV Findings From The Upstairs TV

Device:

- IP used: `192.168.1.12`
- Model reported by ADB: `SmartTV_4K_FFM`
- Product/device: `hengshan`

What worked:

- ADB over TCP port `5555`.
- APK install.
- OpenCore launch by package.
- OpenCore was registered as HOME-capable.
- `cmd package set-home-activity --user 0 tv.opencore.launcher` returned `Success`.
- Preferred activities XML showed `tv.opencore.launcher/.MainActivity`.

What did not work cleanly:

- HOME still resolved to Google TV launcher because Google's launcher was priority `2`.
- Disabling `com.google.android.apps.tv.launcherx` caused `com.google.android.tungsten.setupwraith/.RecoveryActivity` to become HOME.
- Disabling setupwraith left OpenCore as the top HOME candidate, but the TV dropped from the network/ADB after that experiment.

Policy for future scripts:

- Safe scripts may run `cmd package set-home-activity`.
- Scripts must not disable Google launcher or setupwraith by default.
- Any stock-launcher disable path must require an explicit scary flag and print recovery commands first.

Recovery commands for that Google TV family:

```powershell
adb connect 192.168.1.12:5555
adb shell pm enable --user 0 com.google.android.apps.tv.launcherx
adb shell pm enable --user 0 com.google.android.tungsten.setupwraith
adb shell input keyevent HOME
```

## Migration Plan

### Phase 1: Safe Copy And Settings Generalization

- Rename visible settings copy:
  - `Native Fire TV` -> `System Settings`
  - `Home Guard` -> `Home Button Control` or `Launcher Protection`
  - Fire-specific messages -> generic device messages with Fire-only details when profile is Fire TV.
- Rename `NativeFireTvSettingsPage` to `NativeDeviceSettingsPage`.
- Keep Amazon destinations, but show them only on Fire TV.
- Make network/settings buttons use generic labels.
- Update About dialog legalese.
- Update docs and metadata to describe Android TV plus Fire TV.

### Phase 2: Device Profile Detection

Add native method-channel calls:

- `getDeviceProfile`
- `getDeviceCapabilities`
- `getSystemSettingsDestinations`
- `getHomeOverrideState`

Profile detection heuristics:

- Fire TV if Amazon launcher/settings/input packages exist.
- Google TV if `com.google.android.apps.tv.launcherx` exists or manufacturer/build points to Google TV.
- Generic Android TV otherwise.

Flutter should cache the profile in a provider and drive settings visibility from it.

### Phase 3: Settings Launcher Abstraction

Create a native `SettingsLauncher`:

- Try profile-specific destinations first.
- Fall back to standard Android settings intents without forcing Amazon package.
- Return success/failure so Flutter can show only callable settings.

Fix immediately:

- Do not set package `com.amazon.tv.settings.v2` for every `android.settings.*` action on non-Fire profiles.

### Phase 4: Input Discovery

Replace static input list with a hybrid model:

- Use `TvInputManager.getTvInputList()` to discover real inputs.
- Keep Hisense/MediaTek aliases for Fire TV profile.
- Hide synthetic inputs when no compatible TV inputs are available.
- Add error handling in `InputPlayerActivity` for invalid input IDs.

### Phase 5: Home Override Strategies

Create `HomeOverrideStrategy`:

- Fire TV:
  - Home Guard accessibility rescue.
  - Optional ADB self-repair when `WRITE_SECURE_SETTINGS` was granted.
  - Amazon launcher/input/log handling.
- Google TV:
  - Default launcher role/preferred activity checks.
  - Safe instructions and ADB command helpers.
  - No Home Guard by default.
- Generic Android TV:
  - Normal default launcher detection.
  - Manual setup guidance.

### Phase 6: Remote Button Strategies

Create `RemoteButtonMapper`:

- Amazon logcat parser for Fire TV.
- Standard keycode mapper where devices expose shortcut buttons as key events.
- No-op fallback when unsupported.

Hide the remote-button remap settings when no strategy is available.

### Phase 7: Scripts And Docs

- Add `install-android-tv.ps1`.
- Rename or wrap current `dev-install.ps1` as Fire TV-specific.
- Add Android TV setup docs.
- Add Fire TV setup docs.
- Add Google TV recovery notes.
- Update release notes to avoid implying every device needs Home Guard.

## Release Strategy

Short term:

- Continue one universal GitHub Release APK.
- Keep package id `tv.opencore.launcher`.
- Release notes mention profile-aware support.

Medium term:

- Consider Android product flavors only if needed:
  - `universal`
  - `fireTv`
  - `androidTv`

Reasons to add flavors:

- Remove Amazon permissions from clean Android TV builds.
- Ship Fire TV-only accessibility service metadata only in Fire TV builds.
- Different Play Store / sideload metadata.

Reasons not to add flavors yet:

- More release complexity.
- More testing matrix.
- Most differences can be capability-gated in one APK.

## Open Questions

- What exact Google TV launcher packages should be supported in recovery scripts?
- Can the upstairs TV be recovered/reconnected and tested after stock launcher re-enable?
- Which Android TV devices expose useful `TvInputManager` inputs to third-party launchers?
- Should Home Guard be installable but hidden on non-Fire devices, or moved to a Fire flavor later?
- Should OpenCore inputs be a feature users enable per device rather than always present?

## Suggested First Implementation PR

Small, safe first PR:

- Add `DeviceProfile` method channel and Flutter provider.
- Detect Fire TV vs Google TV vs generic Android TV.
- Rename visible Fire TV settings copy to generic copy.
- Hide Fire-only settings destinations on non-Fire profiles.
- Fix `launchActivityFromAction()` so standard Android settings actions are not Amazon-pinned outside Fire TV.
- Add `scripts/install-android-tv.ps1`.

This makes the app feel correct on both TVs without changing the risky Home override behavior yet.
