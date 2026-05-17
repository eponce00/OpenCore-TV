# OpenCore TV Custom Feature Tracker

Goal: turn this Hisense Fire TV into a clean, personal launcher for Jellyfin, YouTube, HDMI inputs, weather, and idle display.

## Now

- Status: imported 18 optimized wallpapers from `C:\Users\ernes\OneDrive\Imágenes\Backgrounds'` into `assets/wallpapers`.
- Status: imported wallpapers are now bundled as 4K launcher assets and selectable from OpenCore's own Wallpaper Library.
- Status: Jellyfin and YouTube are treated as default favorite apps when the Favorites row is empty.
- Status: Home Guard now uses a faster Home rescue path and broader accessibility window coverage for Amazon launcher/input windows.
- Status: HDMI/source entries are being modeled as synthetic OpenCore apps so they can be added to Favorites, reordered, hidden, and customized like normal apps.
- Status: HDMI/input tiles use OpenCore's own native `TvView` player and no longer route through Amazon passthrough UI.
- Status: Wallpaper rotation setting requested: enable/disable automatic rotation and choose a rotation frequency.
- Status: Physical Input/Source opens OpenCore's own input selector only when the user is outside OpenCore Home; on Home it is ignored because the input tiles are already visible in Favorites.
- Status: Home/Input handoffs now use a short accessibility overlay curtain to hide Fire OS launcher/input flashes.
- Status: Amazon launcher events are treated as Home rescue again; Input/Source menu only wins after a real input key or Amazon input package event.
- Status: Stock Amazon launcher disable/restore scripts are available in `scripts/`, but this TV blocks disabling `com.amazon.tv.launcher` as a protected package.
- Status: Added reversible user-0 stock launcher removal/restore scripts, mirroring the Launcher Manager style approach used with Projectivy setups.
- Status: Added Launcher-Manager-style log hook permissions (`READ_LOGS`, overlay app-op) and Home Guard log watcher for Amazon HOME/Input activity.
- Status: Weather widget is implemented on the home screen using a lightweight live weather service.
- Status: Idle home mode is implemented: app UI fades away, clock/weather remain over the wallpaper, and remote/pointer activity wakes it.
- Status: Wallpaper Library now supports optional timed rotation with adjustable frequency.
- Status: Wallpapers now use a catalog manifest with brightness and category tags; all current bundled wallpapers are classified as dark/art under `assets/wallpapers/dark`.
- Status: Appearance mode now supports Dark, Light, Auto by room light, and Auto by sunrise/sunset. The TV exposes a real `android.sensor.light` sensor (`S0-als-veml3235`), and OpenCore also requests Open-Meteo sunrise/sunset with `timezone=auto` as a fallback/alternate signal.
- Status: Input customization settings are implemented for HDMI/input labels and icon presets.
- Status: OpenCore input selector now reads saved input labels/icons, traps focus inside the available input tiles, closes on Back/Home/Menu, and uses OpenCore-owned styling.
- Status: Branded remote buttons can be remapped from Settings. This is a best-effort rescue path because Fire OS still receives the original hardware app key first on this TV.
- Status: Back navigation should stay inside OpenCore and no longer exit to black screen or briefly reveal Fire OS Home.
- Status: Fire OS Screensaver Settings entry is being replaced with OpenCore's own idle/screensaver settings.
- Status: TV-hostile dropdown controls are being replaced with remote-friendly full-row picker pages.
- Status: Main settings menu is being reorganized around OpenCore-owned features instead of inherited system-first menus.
- Status: Input customization now uses remote-friendly preset pages for labels and icons instead of a dialog dropdown.
- Status: Remote Menu/context key should open the same app action panel as long-press Select when Fire OS exposes it to Flutter.
- Status: Input app action panels now include a direct Customize Input entry.
- Status: Weather settings now include Reno, Nevada and a City/ZIP search flow for specific locations.
- Status: Native Android Dream metadata points at OpenCore-owned idle/screensaver settings instead of inherited package handlers.
- Status: OpenCore idle wake now uses a global hardware-key handler so remote keys should dismiss the overlay instead of navigating behind it.
- Status: OpenCore-owned input tiles no longer expose Android's broken gallery/file picker for custom banners.
- Status: Synthetic input banners use a quiet OpenCore dark card style instead of the blue/circle generated artwork.
- Status: Input name/icon changes now invalidate OpenCore's image cache so the home tile refreshes immediately.
- Status: Long-press Select uses an internal timer now, so it should open the side action menu even when Fire OS does not repeat key-down events.
- Status: Duplicate package problem found: old `tv.opencore.launcher` Home Guard was active while newer builds were installed as `tv.opencore.launcher.debug`.
- Status: Release builds are returning to the single final package id `tv.opencore.launcher`; duplicate debug package should be removed after install.
- Status: Pressing Home while already on OpenCore should request OpenCore idle/screensaver instead of relaunching Home.
- Status: Home-to-idle now treats an Amazon launcher rescue as idle if OpenCore was active recently, because Fire OS may not deliver HOME before switching windows.
- Status: Waking OpenCore idle now blocks activation briefly so the first Select press only wakes the launcher and does not launch the focused tile behind it.
- Status: Idle clock/weather cards no longer draw border outlines.
- Status: Idle weather now shows the configured location under the condition.
- Status: Old screensaver clock style page was removed and replaced with OpenCore Clock settings for size/date/24-hour options.
- Status: Network/Wi‑Fi status icon now opens an OpenCore network info panel instead of the broken Fire OS white Wi‑Fi screen.
- Status: Home weather now uses the full weather card with location, matching the idle/screensaver presentation.
- Status: OpenCore Clock settings now controls both Home clock and idle/screensaver clock.
- Status: Added `docs/SETTINGS_AUDIT.md` with the target final settings structure and inherited-menu cleanup notes.
- Status: Wallpaper rendering no longer forces a downscaled `ResizeImage`; bundled wallpapers now use the original PNG files from the PC.
- Status: Removed inherited Back button behavior menu; Back on Home is now intentionally a no-op and nested panels still close normally.
- Status: Removed inherited Interface/Status Bar/Misc settings pages and replaced them with a clearer Home Display page.
- Status: Removed the old alternate launcher clock view, Android Dream/screensaver bridge, and Android file picker dependency.
- Status: Input favorite cards launch the real full-screen `TvView` input successfully again.
- Status: Live HDMI preview experiments were removed from the shipping app. Diagnostics showed Fire OS/MediaTek accepts preview sessions but does not reliably compose HDMI video into a small launcher card, so input tiles now stay stable and open the full-screen OpenCore input player on Select.
- Status: Fire TV Settings was debugged at ActivityTaskManager level. The `KEYCODE_SETTINGS` path only opens Quick Settings, `com.amazon.tv.quicksettings.ui` root/fullscreen activities require Amazon signature permissions, and `com.amazon.tv.launcher/.ui.SettingsActivity` redirects through Amazon Home where Home Guard pulls back to OpenCore. OpenCore now uses a Native Fire TV Settings hub with direct callable Fire OS/Android sections instead of pretending the protected root hub is available to third-party launchers.
- Status: Home Guard was found disabled after reinstall (`enabled_accessibility_services=null`). It has been re-enabled on the TV, and `scripts/dev-install.ps1` now restores Home Guard, overlay app-op, and READ_LOGS after every install.
- Status: Added OpenCore Health settings page to check/repair Home Guard from the TV UI when the installer has granted `WRITE_SECURE_SETTINGS`; OpenCore now also repairs Home Guard on resume when that grant exists. Added `docs/HOME_GUARD_SETUP.md` with the ADB/manual recovery boundary.
- Status: Settings landing page was redesigned into a wider glassy OpenCore Control Center with time/date, Home Guard status, large quick tiles, and grouped settings cards.
- Status: Settings Control Center styling was tightened for the OLED/minimal launcher theme: smaller cards, near-black surfaces, neutral focus outlines, and no oversized colored glow.
- Status: Settings cleanup pass renamed the inherited `OpenCore System` catch-all into `Device Tools`, clarified its sections, and kept Fire TV native sections separate.
- Status: Repository formalization started: added `AGENTS.md`, GitHub Releases publish script, README release link, and removed inherited remote wiring.
- Status: Stale inherited widget/provider tests were removed and replaced with the current OpenCore-focused suite covering settings persistence and input selector focus behavior.
- Status: Public history cleanup requested: rewrite `main` as a clean OpenCore root commit and replace inherited tags/releases with OpenCore-owned releases.

## Backlog

- Learned remote-button remapping is the preferred path. Buttons Android never exposes to OpenCore cannot be remapped without a device-specific fallback.
- Keep reviewing deeper inherited settings pages, especially app section editing, for TV-hostile dropdowns/text fields.
- Weather widget on native Android Dream/screensaver service, if we decide to keep a separate system screensaver instead of OpenCore idle mode.
- Auto-detect additional TV inputs beyond the confirmed MediaTek HDMI/antenna/composite IDs.
- Confirm physical Home button behavior after Fire OS protected-package limitations.
- Confirm physical Input/Source behavior after Fire OS updates; OpenCore relies on the foreground activity plus Home Guard accessibility/log rescue path, not privileged system interception.
- Optional: allow custom image files for input icons instead of only built-in icon presets.
- Add a first light wallpaper pack and richer categories such as earth, city, space, abstract, and minimal.

## Next Test Pass

- Back button from OpenCore Home should do nothing by default, not open a black screen or Amazon Home.
- Back button inside OpenCore Settings should pop the current settings page first.
- Idle/screensaver should wake on remote arrows/select/back without launching the focused app underneath.
- Wallpaper rotation frequency should change through the full-row picker page.
- Appearance mode should show the live room lux reading and switch active wallpaper bucket without flicker.
- OpenCore idle / Screensaver should open OpenCore's own settings, not Fire OS screensaver settings.
- Fire OS native screensaver manager should no longer show a broken "no app installed to manage this" OpenCore Settings handler.
- Weather settings should allow unit and preset location changes.
- Input settings should allow label/icon preset changes with remote navigation.
- Long-press Select on an input favorite should open the side action menu with Customize Input.
- Input favorite cards should show the quiet OpenCore banner style, not the old blue/circle artwork.
- Physical Input/Source should do nothing visible on OpenCore Home, and should open the OpenCore selector from other apps/inputs.
- OpenCore input selector focus should stay inside its tiles and close on Back/Home/Menu.
- Branded remote buttons should route to the configured target with no repeated relaunch flashing.
- Only one OpenCore package should remain installed, and Home/manual launch should show the same UI.
- Press Home while already on OpenCore Home should enter OpenCore idle/screensaver.
- Wallpaper backgrounds should look sharper with original PNG assets and no forced downscale.
- Light appearance should use light-tagged wallpapers when available, and fall back to dark wallpapers when the light bucket is empty.
- OpenCore Clock settings should control idle clock size, date visibility, and 24-hour format.
- OpenCore Clock settings should control Home clock size, visibility, and date visibility.
- Wi‑Fi/status icon should open a dark OpenCore network panel, not a white unusable system panel.
- Fire TV Settings should open native Fire TV settings instead of falling back to Home/idle behavior.

## Design Notes

- Keep the home screen quiet and useful: Jellyfin, YouTube, inputs, settings, weather, and clock.
- Avoid store rows, ads, recommendations, subscriptions, and anything that feels like a shopping surface.
- Use couch-distance readability: large focus states, high contrast text, and no tiny controls.
- Prefer local-first behavior. Weather is the one likely online dependency.

## Technical Notes

- Weather starts with a simple live provider and cached fallback. Manual location/units can be added later.
- Weather requests now include `daily=sunrise,sunset` and `timezone=auto`, so OpenCore can drive sunrise/sunset appearance mode from the configured weather location.
- Wallpaper organization uses folders for browsing (`dark/`, `light/`) and `assets/wallpapers/catalog.json` as the source of truth for brightness/category tags.
- Idle mode lives inside the launcher first because it gives OpenCore control of wallpaper, clock, weather, and wake behavior without depending on Fire OS Dream routing.
- HDMI/input launching uses discovered MediaTek TV input IDs on this model: HDMI 1 = `HW2`, HDMI 2 = `HW3`, HDMI 3 = `HW4`, HDMI 4 = `HW5`.
- Full-screen HDMI/input launching works through OpenCore's `InputPlayerActivity`. Small live HDMI preview was removed after diagnostics indicated this Fire OS/MediaTek build only composes HDMI reliably as a full-screen input surface.
- Fire OS protects direct input tuning behind Amazon signature permissions. OpenCore uses its own `InputPlayerActivity` for the confirmed MediaTek input IDs and avoids the stock Fire TV input selector when possible.
- Intercepting the remote Input button is best-effort on Fire OS. OpenCore handles the key while foreground, then uses Home Guard accessibility/log detection to redirect Amazon input UI to the OpenCore selector when Fire OS wins first.
- Home Guard uses a short transition curtain to hide most Amazon Home/input flashes, but the protected Fire OS UI may still appear briefly before accessibility events are delivered.
- The current practical gates are `flutter test --no-pub` for the maintained OpenCore suite and `flutter build apk --release` for the TV install build.
- Next priority: user validation pass, then refine visual styling and add manual weather location if wanted.
- Home override likely needs a guard service because `cmd package resolve-activity` still chooses `com.amazon.tv.launcher/.ui.HomeActivity_vNext`.
- Fire OS marks `com.amazon.tv.launcher` as protected, so normal ADB cannot disable the package without root/elevated privileges. OpenCore should rely on HOME preference plus Home Guard rescue.
- Fire OS also blocks component-level disabling of `com.amazon.tv.launcher/.ui.HomeActivity_vNext` and `com.amazon.firehomestarter/.HomeStarterActivity`.
- Android role assignment did not override Fire OS HOME resolution on this model; `resolve-activity HOME` still returns Amazon's protected launcher.
- Without system-level privileges/root, Fire OS 8 can still briefly start Amazon's protected HOME activity. OpenCore masks that with an accessibility overlay, then reopens OpenCore.
- Projectivy's normal override is accessibility-based too. The truly seamless Fire TV reports usually use Launcher Manager style stock-launcher removal/disable; OpenCore now has scripts to attempt the reversible user-0 version of that.
- On this Fire OS 8.1.7.1 build, `pm disable-user`, component disable, and `pm uninstall -k --user 0` all fail against the protected Amazon launcher packages. The remaining non-root path is an accessibility/log hook.
- Avoid Flutter dropdowns for TV-critical settings. Use large focusable rows with checkmarks because Fire TV remote select does not reliably activate dropdown menus.
