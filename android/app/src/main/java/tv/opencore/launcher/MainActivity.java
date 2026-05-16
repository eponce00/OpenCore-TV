/*
 * OpenCoreTV
 * Copyright (C) 2021  Oscar Rojas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package tv.opencore.launcher;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.*;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.util.Log;
import android.util.Pair;
import android.view.KeyEvent;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.io.ByteArrayOutputStream;
import java.io.File;
import android.app.usage.NetworkStats;
import android.app.usage.NetworkStatsManager;
import android.app.AppOpsManager;
import android.os.RemoteException;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import java.io.ByteArrayOutputStream;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletionService;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorCompletionService;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class MainActivity extends FlutterActivity {
    private static final String TRACE_TAG = "OpenCoreTrace";
    private final String METHOD_CHANNEL = "tv.opencore.launcher/method";
    private final String APPS_EVENT_CHANNEL = "tv.opencore.launcher/event_apps";
    private final String NETWORK_EVENT_CHANNEL = "tv.opencore.launcher/event_network";
    private final String LIGHT_SENSOR_EVENT_CHANNEL = "tv.opencore.launcher/event_light_sensor";
    static final String ACTION_ENTER_IDLE = "tv.opencore.launcher.action.ENTER_IDLE";
    static final String ACTION_DISMISS_PANEL = "tv.opencore.launcher.action.DISMISS_PANEL";
    static final String ACTION_SHOW_INPUT_SELECTOR = "tv.opencore.launcher.action.SHOW_INPUT_SELECTOR";
    static final String ACTION_RETURN_HOME = "tv.opencore.launcher.action.RETURN_HOME";
    private static volatile boolean panelOpen = false;
    private MethodChannel methodChannel;
    private boolean activityResumed = false;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();

        methodChannel = new MethodChannel(messenger, METHOD_CHANNEL);
        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "getApplications" -> result.success(getApplications());
                case "getApplicationBanner" -> result.success(getApplicationBanner(call.arguments()));
                case "getApplicationIcon" -> result.success(getApplicationIcon(call.arguments()));
                case "applicationExists" -> result.success(applicationExists(call.arguments()));
                case "launchActivityFromAction" -> result.success(launchActivityFromAction(call.arguments()));
                case "launchApp" -> result.success(launchApp(call.arguments()));
                case "openSettings" -> result.success(openSettings());
                case "setPanelOpen" -> {
                    panelOpen = Boolean.TRUE.equals(call.arguments());
                    result.success(null);
                }
                case "isHomeGuardEnabled" -> result.success(isHomeGuardEnabled());
                case "repairHomeGuard" -> result.success(repairHomeGuard());
                case "openAccessibilitySettings" -> result.success(openAccessibilitySettings());
                case "installApk" -> result.success(installApk(call.arguments()));
                case "requestInstallUnknownAppsPermission" -> {
                    requestInstallUnknownAppsPermission();
                    result.success(null);
                }
                case "openAppInfo" -> result.success(openAppInfo(call.arguments()));
                case "uninstallApp" -> result.success(uninstallApp(call.arguments()));
                case "isDefaultLauncher" -> result.success(isDefaultLauncher());
                case "getActiveNetworkInformation" -> result.success(getActiveNetworkInformation());
                case "getDailyWifiUsage" -> {
                    long usage = getDailyWifiUsage();
                    if (usage == -1) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                    } else {
                        result.success(usage);
                    }
                }
                case "getWeeklyWifiUsage" -> {
                    long usage = getWeeklyWifiUsage();
                    if (usage == -1) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                    } else {
                        result.success(usage);
                    }
                }
                case "getMonthlyWifiUsage" -> {
                    long usage = getMonthlyWifiUsage();
                    if (usage == -1) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                    } else {
                        result.success(usage);
                    }
                }
                case "checkUsageStatsPermission" -> result.success(checkUsageStatsPermission());
                case "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission();
                    result.success(null);
                }
                case "checkWriteSettingsPermission" -> result.success(checkWriteSettingsPermission());
                case "requestWriteSettingsPermission" -> {
                    requestWriteSettingsPermission();
                    result.success(null);
                }
                case "setSystemBrightness" -> {
                    int brightness = call.argument("brightness");
                    result.success(setSystemBrightness(brightness));
                }
                case "openWifiSettings" -> result.success(openWifiSettings());
                default -> throw new IllegalArgumentException();
            }
        });

        new EventChannel(messenger, APPS_EVENT_CHANNEL).setStreamHandler(
                new LauncherAppsEventStreamHandler(this));

        new EventChannel(messenger, NETWORK_EVENT_CHANNEL).setStreamHandler(
                new NetworkEventStreamHandler(this));

        new EventChannel(messenger, LIGHT_SENSOR_EVENT_CHANNEL).setStreamHandler(
                new LightSensorEventStreamHandler(this));

        Log.w(TRACE_TAG, "configureFlutterEngine initialIntent=" + describeIntent(getIntent()));
        handleIntent(getIntent(), false);
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        Log.w(TRACE_TAG, "onNewIntent resumed=" + activityResumed
                + " intent=" + describeIntent(intent));
        setIntent(intent);
        handleIntent(intent, true);
    }

    @Override
    protected void onResume() {
        super.onResume();
        activityResumed = true;
        Log.w(TRACE_TAG, "MainActivity onResume");
        repairHomeGuard();
        if (ACTION_SHOW_INPUT_SELECTOR.equals(getIntent().getAction())) {
            mainHandler.postDelayed(this::sendShowInputSelectorToFlutter, 250);
        }
    }

    @Override
    protected void onPause() {
        activityResumed = false;
        Log.w(TRACE_TAG, "MainActivity onPause");
        super.onPause();
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getKeyCode() == KeyEvent.KEYCODE_MENU) {
            if (event.getAction() == KeyEvent.ACTION_DOWN && methodChannel != null) {
                methodChannel.invokeMethod("remoteMenu", null);
            }
            return true;
        }
        if (isInputMenuKey(event.getKeyCode())) {
            return true;
        }
        return super.dispatchKeyEvent(event);
    }

    private void handleIntent(Intent intent, boolean fromNewIntent) {
        if (intent == null || methodChannel == null) {
            Log.w(TRACE_TAG, "handleIntent ignored null/channel intent=" + describeIntent(intent)
                    + " channelReady=" + (methodChannel != null));
            return;
        }

        if (ACTION_ENTER_IDLE.equals(intent.getAction())) {
            Log.w(TRACE_TAG, "handleIntent enterIdle action fromNewIntent=" + fromNewIntent);
            sendEnterIdleToFlutter("action");
            return;
        }

        if (ACTION_DISMISS_PANEL.equals(intent.getAction())) {
            Log.w(TRACE_TAG, "handleIntent dismissPanel action fromNewIntent=" + fromNewIntent);
            sendDismissPanelToFlutter();
            return;
        }

        if (ACTION_SHOW_INPUT_SELECTOR.equals(intent.getAction())) {
            Log.w(TRACE_TAG, "handleIntent showInputSelector action fromNewIntent=" + fromNewIntent);
            sendShowInputSelectorToFlutter();
            return;
        }

        if (ACTION_RETURN_HOME.equals(intent.getAction())) {
            Log.w(TRACE_TAG, "handleIntent returnHome action fromNewIntent=" + fromNewIntent);
            return;
        }

        if (fromNewIntent && activityResumed && isHomeIntent(intent)) {
            Log.w(TRACE_TAG, "handleIntent repeated HOME while resumed -> enterIdle");
            sendEnterIdleToFlutter("repeatedHome");
        } else {
            Log.w(TRACE_TAG, "handleIntent no-op fromNewIntent=" + fromNewIntent
                    + " resumed=" + activityResumed
                    + " isHomeIntent=" + isHomeIntent(intent));
        }
    }

    private boolean isHomeIntent(Intent intent) {
        return Intent.ACTION_MAIN.equals(intent.getAction())
                && intent.hasCategory(Intent.CATEGORY_HOME);
    }

    private boolean isInputMenuKey(int keyCode) {
        return keyCode == KeyEvent.KEYCODE_TV_INPUT
                || keyCode == KeyEvent.KEYCODE_STB_INPUT
                || keyCode == KeyEvent.KEYCODE_AVR_INPUT;
    }

    static boolean isPanelOpen() {
        return panelOpen;
    }

    private String homeGuardServiceName() {
        return getPackageName() + "/" + getPackageName() + ".HomeGuardAccessibilityService";
    }

    private boolean isHomeGuardEnabled() {
        String enabledServices = Settings.Secure.getString(
                getContentResolver(),
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        int accessibilityEnabled = Settings.Secure.getInt(
                getContentResolver(),
                Settings.Secure.ACCESSIBILITY_ENABLED,
                0);
        return accessibilityEnabled == 1
                && enabledServices != null
                && enabledServices.contains(homeGuardServiceName());
    }

    private boolean repairHomeGuard() {
        try {
            Settings.Secure.putInt(
                    getContentResolver(),
                    Settings.Secure.ACCESSIBILITY_ENABLED,
                    1);

            String enabledServices = Settings.Secure.getString(
                    getContentResolver(),
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
            String homeGuard = homeGuardServiceName();
            if (enabledServices == null || enabledServices.isBlank()) {
                enabledServices = homeGuard;
            } else if (!enabledServices.contains(homeGuard)) {
                enabledServices = enabledServices + ":" + homeGuard;
            }

            Settings.Secure.putString(
                    getContentResolver(),
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                    enabledServices);
        } catch (SecurityException exception) {
            Log.w(TRACE_TAG, "repairHomeGuard blocked by missing WRITE_SECURE_SETTINGS", exception);
            return false;
        }

        return isHomeGuardEnabled();
    }

    private boolean openAccessibilitySettings() {
        Intent intent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return tryStartActivity(intent);
    }

    private void sendEnterIdleToFlutter(String reason) {
        methodChannel.invokeMethod("enterIdle", null, new MethodChannel.Result() {
            @Override
            public void success(Object result) {
                Log.w(TRACE_TAG, "enterIdle delivered to Flutter reason=" + reason);
            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {
                Log.w(TRACE_TAG, "enterIdle Flutter error reason=" + reason
                        + " code=" + errorCode
                        + " message=" + errorMessage);
            }

            @Override
            public void notImplemented() {
                Log.w(TRACE_TAG, "enterIdle not implemented in Flutter reason=" + reason);
            }
        });
    }

    private void sendDismissPanelToFlutter() {
        methodChannel.invokeMethod("dismissPanel", null, new MethodChannel.Result() {
            @Override
            public void success(Object result) {
                Log.w(TRACE_TAG, "dismissPanel delivered to Flutter");
            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {
                Log.w(TRACE_TAG, "dismissPanel Flutter error code=" + errorCode
                        + " message=" + errorMessage);
            }

            @Override
            public void notImplemented() {
                Log.w(TRACE_TAG, "dismissPanel not implemented in Flutter");
            }
        });
    }

    private void sendShowInputSelectorToFlutter() {
        methodChannel.invokeMethod("showInputSelector", null, new MethodChannel.Result() {
            @Override
            public void success(Object result) {
                Log.w(TRACE_TAG, "showInputSelector delivered to Flutter");
            }

            @Override
            public void error(String errorCode, String errorMessage, Object errorDetails) {
                Log.w(TRACE_TAG, "showInputSelector Flutter error code=" + errorCode
                        + " message=" + errorMessage);
            }

            @Override
            public void notImplemented() {
                Log.w(TRACE_TAG, "showInputSelector not implemented in Flutter");
            }
        });
    }

    private String describeIntent(Intent intent) {
        if (intent == null) {
            return "null";
        }
        return "action=" + intent.getAction()
                + " categories=" + intent.getCategories()
                + " flags=0x" + Integer.toHexString(intent.getFlags());
    }

    private List<Map<String, Serializable>> getApplications() {
        ExecutorService executor = Executors.newFixedThreadPool(4);
        CompletionService<Pair<Boolean, List<ResolveInfo>>> queryIntentActivitiesCompletionService = new ExecutorCompletionService<>(
                executor);
        queryIntentActivitiesCompletionService.submit(() -> Pair.create(false, queryIntentActivities(false)));
        queryIntentActivitiesCompletionService.submit(() -> Pair.create(true, queryIntentActivities(true)));
        List<ResolveInfo> tvActivitiesInfo = null;
        List<ResolveInfo> nonTvActivitiesInfo = null;

        int completed = 0;
        while (completed < 2) {
            try {
                var activitiesInfo = queryIntentActivitiesCompletionService.take().get();

                if (!activitiesInfo.first) {
                    tvActivitiesInfo = activitiesInfo.second;
                } else {
                    nonTvActivitiesInfo = activitiesInfo.second;
                }
            } catch (InterruptedException | ExecutionException ignored) {
            } finally {
                completed += 1;
            }
        }

        CompletionService<Map<String, Serializable>> completionService = new ExecutorCompletionService<>(executor);

        List<Map<String, Serializable>> applications = new ArrayList<>(
                tvActivitiesInfo.size() + nonTvActivitiesInfo.size());

        boolean settingsPresent = false;
        int appCount = 0;
        for (ResolveInfo tvActivityInfo : tvActivitiesInfo) {
            if (!settingsPresent) {
                settingsPresent = tvActivityInfo.activityInfo.packageName.equals("com.android.tv.settings");
            }

            completionService.submit(() -> buildAppMap(tvActivityInfo.activityInfo, false, null));
            appCount += 1;
        }

        for (ResolveInfo nonTvActivityInfo : nonTvActivitiesInfo) {
            boolean nonDuplicate = true;

            if (!settingsPresent) {
                settingsPresent = nonTvActivityInfo.activityInfo.packageName.equals("com.android.settings");
            }

            for (ResolveInfo tvActivityInfo : tvActivitiesInfo) {
                if (tvActivityInfo.activityInfo.packageName.equals(nonTvActivityInfo.activityInfo.packageName)) {
                    nonDuplicate = false;
                    break;
                }
            }

            if (nonDuplicate) {
                appCount += 1;
                completionService.submit(() -> buildAppMap(nonTvActivityInfo.activityInfo, true, null));
            }
        }

        while (appCount > 0) {
            try {
                Future<Map<String, Serializable>> appMap = completionService.take();
                applications.add(appMap.get());
            } catch (InterruptedException | ExecutionException ignored) {
            } finally {
                appCount -= 1;
            }
        }

        executor.shutdown();

        if (!settingsPresent) {
            PackageManager packageManager = getPackageManager();
            Intent settingsIntent = new Intent(Settings.ACTION_SETTINGS);
            ActivityInfo activityInfo = settingsIntent.resolveActivityInfo(packageManager, 0);

            if (activityInfo != null) {
                applications.add(buildAppMap(activityInfo, false, Settings.ACTION_SETTINGS));
            }
        }

        applications.addAll(buildInputAppMaps());

        return applications;
    }

    public Map<String, Serializable> getApplication(String packageName) {
        Map<String, Serializable> map = Map.of();
        PackageManager packageManager = getPackageManager();
        Intent intent = packageManager.getLeanbackLaunchIntentForPackage(packageName);

        if (intent == null) {
            intent = packageManager.getLaunchIntentForPackage(packageName);
        }

        if (intent != null) {
            ActivityInfo activityInfo = intent.resolveActivityInfo(getPackageManager(), 0);

            if (activityInfo != null) {
                map = buildAppMap(activityInfo, false, null);
            }
        }

        return map;
    }

    private byte[] getApplicationBanner(String packageName) {
        if (OpenCoreInputs.isSyntheticInputPackage(packageName)) {
            return buildSyntheticInputImage(packageName, true);
        }

        byte[] imageBytes = new byte[0];

        PackageManager packageManager = getPackageManager();
        try {
            ApplicationInfo info = packageManager.getApplicationInfo(packageName, 0);
            Drawable drawable = info.loadBanner(packageManager);

            if (drawable != null) {
                imageBytes = drawableToByteArray(drawable);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        return imageBytes;
    }

    private byte[] getApplicationIcon(String packageName) {
        if (OpenCoreInputs.isSyntheticInputPackage(packageName)) {
            return buildSyntheticInputImage(packageName, false);
        }

        byte[] imageBytes = new byte[0];

        PackageManager packageManager = getPackageManager();
        try {
            ApplicationInfo info = packageManager.getApplicationInfo(packageName, 0);
            Drawable drawable = info.loadIcon(packageManager);

            if (drawable != null) {
                imageBytes = drawableToByteArray(drawable);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        return imageBytes;
    }

    private boolean applicationExists(String packageName) {
        if (OpenCoreInputs.isSyntheticInputPackage(packageName)) {
            return OpenCoreInputs.inputIdForPackage(packageName) != null;
        }

        int flags;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            flags = PackageManager.MATCH_UNINSTALLED_PACKAGES;
        } else {
            flags = PackageManager.GET_UNINSTALLED_PACKAGES;
        }

        try {
            getPackageManager().getApplicationInfo(packageName, flags);
            return true;
        } catch (PackageManager.NameNotFoundException ignored) {
            return false;
        }
    }

    private List<ResolveInfo> queryIntentActivities(boolean sideloaded) {
        String category;
        if (sideloaded) {
            category = Intent.CATEGORY_LAUNCHER;
        } else {
            category = Intent.CATEGORY_LEANBACK_LAUNCHER;
        }

        // NOTE: Would be nice to query the applications that match *either* of the
        // above categories
        // but from the addCategory function documentation, it says that it will "use
        // activities
        // that provide *all* the requested categories"
        Intent intent = new Intent(Intent.ACTION_MAIN)
                .addCategory(category);

        return getPackageManager()
                .queryIntentActivities(intent, 0);
    }

    private Map<String, Serializable> buildAppMap(ActivityInfo activityInfo, boolean sideloaded, String action) {
        PackageManager packageManager = getPackageManager();

        String applicationName = activityInfo.loadLabel(packageManager).toString(),
                applicationVersionName = "";
        try {
            applicationVersionName = packageManager.getPackageInfo(activityInfo.packageName, 0).versionName;
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        Map<String, Serializable> appMap = new HashMap<>();
        appMap.put("name", applicationName);
        appMap.put("packageName", activityInfo.packageName);
        appMap.put("version", applicationVersionName);
        appMap.put("sideloaded", sideloaded);

        if (action != null) {
            appMap.put("action", action);
        }
        return appMap;
    }

    private boolean launchActivityFromAction(String action) {
        Intent intent = new Intent(action)
                .addCategory(Intent.CATEGORY_DEFAULT)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        if (action.startsWith("com.amazon.device.settings.action.")
                || action.startsWith("android.settings.")) {
            intent.setPackage("com.amazon.tv.settings.v2");
        }
        return tryStartActivity("action " + action, intent);
    }

    private boolean launchApp(String packageName) {
        if (OpenCoreInputs.isSyntheticInputPackage(packageName)) {
            return launchSyntheticInput(packageName);
        }

        PackageManager packageManager = getPackageManager();
        Intent intent = packageManager.getLeanbackLaunchIntentForPackage(packageName);

        if (intent == null) {
            intent = packageManager.getLaunchIntentForPackage(packageName);
        }

        return tryStartActivity(intent);
    }

    private List<Map<String, Serializable>> buildInputAppMaps() {
        List<Map<String, Serializable>> inputs = new ArrayList<>();
        for (OpenCoreInputs.Shortcut shortcut : OpenCoreInputs.SHORTCUTS) {
            inputs.add(buildSyntheticInputApp(shortcut.packageName));
        }
        return inputs;
    }

    private Map<String, Serializable> buildSyntheticInputApp(String packageName) {
        Map<String, Serializable> appMap = new HashMap<>();
        appMap.put("name", syntheticInputLabel(packageName));
        appMap.put("packageName", packageName);
        appMap.put("version", "1");
        appMap.put("sideloaded", false);
        return appMap;
    }

    private boolean launchSyntheticInput(String packageName) {
        String inputId = OpenCoreInputs.inputIdForPackage(packageName);
        if (inputId == null) {
            return false;
        }

        Intent intent = new Intent(this, InputPlayerActivity.class)
                .putExtra(InputPlayerActivity.EXTRA_INPUT_ID, inputId)
                .putExtra(InputPlayerActivity.EXTRA_INPUT_LABEL, syntheticInputLabel(packageName))
                .putExtra(InputPlayerActivity.EXTRA_INPUT_ICON, syntheticInputIcon(packageName))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                        | Intent.FLAG_ACTIVITY_CLEAR_TOP
                        | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        return tryStartActivity(intent);
    }

    private boolean openSettings() {
        panelOpen = false;

        Intent fireSettingsV2 = new Intent("com.amazon.device.settings.action.DEVICE")
                .addCategory(Intent.CATEGORY_DEFAULT)
                .setPackage("com.amazon.tv.settings.v2")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        if (tryStartActivity("Fire TV settings v2 action", fireSettingsV2)) {
            return true;
        }

        Intent fireSettingsDevice = new Intent("com.amazon.device.settings.action.DEVICE")
                .addCategory(Intent.CATEGORY_DEFAULT)
                .setComponent(new ComponentName(
                        "com.amazon.tv.settings.v2",
                        "com.amazon.tv.settings.v2.tv.device.DeviceActivity"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        if (tryStartActivity("Fire TV settings v2 DeviceActivity", fireSettingsDevice)) {
            return true;
        }

        Log.w(TRACE_TAG, "openSettings falling back to Android ACTION_SETTINGS; Fire OS may route this through Amazon launcher");
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean installApk(String apkPath) {
        File apkFile = new File(apkPath);
        if (!apkFile.exists()) {
            return false;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !getPackageManager().canRequestPackageInstalls()) {
            return false;
        }

        Uri apkUri = FileProvider.getUriForFile(
                this,
                getPackageName() + ".fileprovider",
                apkFile
        );

        Intent installIntent = new Intent(Intent.ACTION_VIEW)
                .setDataAndType(apkUri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        return tryStartActivity(installIntent);
    }

    private void requestInstallUnknownAppsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                    .setData(Uri.parse("package:" + getPackageName()));
            tryStartActivity(intent);
        }
    }

    private boolean openAppInfo(String packageName) {
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null));

        return tryStartActivity(intent);
    }

    private boolean uninstallApp(String packageName) {
        Intent intent = new Intent(Intent.ACTION_DELETE)
                .setData(Uri.fromParts("package", packageName, null));

        return tryStartActivity(intent);
    }

    private boolean isDefaultLauncher() {
        Intent intent = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME);
        ResolveInfo defaultLauncher = getPackageManager().resolveActivity(intent, 0);

        if (defaultLauncher != null && defaultLauncher.activityInfo != null) {
            return defaultLauncher.activityInfo.packageName.equals(getPackageName());
        }

        return false;
    }

    private Map<String, Object> getActiveNetworkInformation() {
        ConnectivityManager connectivityManager = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return NetworkUtils.getNetworkInformation(this, connectivityManager.getActiveNetwork());
        } else {
            // noinspection deprecation
            return NetworkUtils.getNetworkInformation(this, connectivityManager.getActiveNetworkInfo());
        }
    }

    private boolean tryStartActivity(Intent intent) {
        return tryStartActivity("activity", intent);
    }

    private boolean tryStartActivity(String label, Intent intent) {
        try {
            Log.w(TRACE_TAG, "tryStartActivity " + label + " intent=" + describeIntent(intent));
            startActivity(intent);
            return true;
        } catch (Exception ignored) {
            Log.w(TRACE_TAG, "tryStartActivity failed " + label + " intent=" + describeIntent(intent), ignored);
            return false;
        }
    }

    private byte[] drawableToByteArray(Drawable drawable) {
        if (drawable.getIntrinsicWidth() <= 0 || drawable.getIntrinsicHeight() <= 0) {
            return new byte[0];
        }

        Bitmap bitmap;
        if (drawable instanceof BitmapDrawable bitmapDrawable) {
            bitmap = bitmapDrawable.getBitmap();
        } else {
            bitmap = drawableToBitmap(drawable);
        }
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        return stream.toByteArray();
    }

    private byte[] buildSyntheticInputImage(String packageName, boolean banner) {
        int width = banner ? 960 : 384;
        int height = banner ? 540 : 384;
        String label = syntheticInputLabel(packageName);
        String icon = syntheticInputIcon(packageName);

        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);

        Paint background = new Paint(Paint.ANTI_ALIAS_FLAG);
        background.setColor(Color.rgb(5, 6, 8));
        canvas.drawRect(0, 0, width, height, background);

        Paint iconPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        iconPaint.setColor(Color.argb(215, 255, 255, 255));
        iconPaint.setStyle(Paint.Style.STROKE);
        iconPaint.setStrokeWidth(banner ? 10 : 6);
        iconPaint.setStrokeCap(Paint.Cap.ROUND);
        iconPaint.setStrokeJoin(Paint.Join.ROUND);
        float iconCenterX = width / 2f;
        float iconCenterY = banner ? height * 0.34f : height * 0.33f;
        float iconSize = banner ? 82 : 50;
        drawSyntheticInputIcon(canvas, iconPaint, icon, iconCenterX, iconCenterY, iconSize);

        Paint text = new Paint(Paint.ANTI_ALIAS_FLAG);
        text.setColor(Color.WHITE);
        text.setTextAlign(Paint.Align.CENTER);
        text.setFakeBoldText(true);
        text.setTextSize(banner ? 70 : 42);

        Rect bounds = new Rect();
        text.getTextBounds(label, 0, label.length(), bounds);
        float x = width / 2f;
        float y = (banner ? height * 0.68f : height * 0.67f) - bounds.exactCenterY();
        canvas.drawText(label, x, y, text);

        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        return stream.toByteArray();
    }

    private String syntheticInputLabel(String packageName) {
        String fallback = OpenCoreInputs.fallbackLabelForPackage(packageName);
        return flutterPrefs().getString("flutter.input_label_" + packageName, fallback);
    }

    private String syntheticInputIcon(String packageName) {
        return flutterPrefs().getString("flutter.input_icon_" + packageName, "tv");
    }

    private SharedPreferences flutterPrefs() {
        return getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
    }

    private void drawSyntheticInputIcon(Canvas canvas, Paint paint, String icon, float cx, float cy, float size) {
        switch (icon) {
            case "game" -> {
                canvas.drawRoundRect(cx - size * 1.2f, cy - size * 0.55f, cx + size * 1.2f, cy + size * 0.55f, size * 0.35f, size * 0.35f, paint);
                canvas.drawLine(cx - size * 0.75f, cy, cx - size * 0.25f, cy, paint);
                canvas.drawLine(cx - size * 0.5f, cy - size * 0.25f, cx - size * 0.5f, cy + size * 0.25f, paint);
                canvas.drawCircle(cx + size * 0.5f, cy - size * 0.12f, size * 0.08f, paint);
                canvas.drawCircle(cx + size * 0.78f, cy + size * 0.12f, size * 0.08f, paint);
            }
            case "movie" -> {
                canvas.drawRoundRect(cx - size, cy - size * 0.65f, cx + size, cy + size * 0.65f, size * 0.14f, size * 0.14f, paint);
                canvas.drawLine(cx - size * 0.3f, cy - size * 0.65f, cx - size * 0.3f, cy + size * 0.65f, paint);
                canvas.drawLine(cx + size * 0.35f, cy - size * 0.65f, cx + size * 0.35f, cy + size * 0.65f, paint);
            }
            case "computer" -> {
                canvas.drawRect(cx - size, cy - size * 0.65f, cx + size, cy + size * 0.45f, paint);
                canvas.drawLine(cx - size * 0.35f, cy + size * 0.75f, cx + size * 0.35f, cy + size * 0.75f, paint);
                canvas.drawLine(cx, cy + size * 0.45f, cx, cy + size * 0.75f, paint);
            }
            case "antenna" -> {
                canvas.drawCircle(cx, cy - size * 0.35f, size * 0.16f, paint);
                canvas.drawLine(cx, cy - size * 0.2f, cx, cy + size * 0.9f, paint);
                canvas.drawLine(cx, cy + size * 0.15f, cx - size * 0.8f, cy + size * 0.9f, paint);
                canvas.drawLine(cx, cy + size * 0.15f, cx + size * 0.8f, cy + size * 0.9f, paint);
            }
            case "camera" -> {
                canvas.drawRoundRect(cx - size, cy - size * 0.58f, cx + size * 0.55f, cy + size * 0.58f, size * 0.18f, size * 0.18f, paint);
                canvas.drawLine(cx + size * 0.55f, cy - size * 0.2f, cx + size, cy - size * 0.5f, paint);
                canvas.drawLine(cx + size * 0.55f, cy + size * 0.2f, cx + size, cy + size * 0.5f, paint);
            }
            default -> {
                canvas.drawRoundRect(cx - size, cy - size * 0.65f, cx + size, cy + size * 0.65f, size * 0.18f, size * 0.18f, paint);
                canvas.drawLine(cx - size * 0.45f, cy + size * 0.9f, cx + size * 0.45f, cy + size * 0.9f, paint);
                canvas.drawLine(cx, cy + size * 0.65f, cx, cy + size * 0.9f, paint);
            }
        }
    }

    Bitmap drawableToBitmap(Drawable drawable) {
        Bitmap bitmap = Bitmap.createBitmap(
                drawable.getIntrinsicWidth(),
                drawable.getIntrinsicHeight(),
                Bitmap.Config.ARGB_8888);

        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);
        return bitmap;
    }

    private long getDailyWifiUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;

        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket bucket = networkStatsManager.querySummaryForDevice(
                    NetworkCapabilities.TRANSPORT_WIFI,
                    "",
                    startTime,
                    endTime);
            totalBytes = bucket.getRxBytes() + bucket.getTxBytes();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    private long getWeeklyWifiUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;

        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.DAY_OF_WEEK, calendar.getFirstDayOfWeek());
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket bucket = networkStatsManager.querySummaryForDevice(
                    NetworkCapabilities.TRANSPORT_WIFI,
                    "",
                    startTime,
                    endTime);
            totalBytes = bucket.getRxBytes() + bucket.getTxBytes();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    private long getMonthlyWifiUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;

        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.DAY_OF_MONTH, 1);
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket bucket = networkStatsManager.querySummaryForDevice(
                    NetworkCapabilities.TRANSPORT_WIFI,
                    "",
                    startTime,
                    endTime);
            totalBytes = bucket.getRxBytes() + bucket.getTxBytes();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    private boolean checkUsageStatsPermission() {
        AppOpsManager appOps = (AppOpsManager) getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(), getPackageName());
        return mode == AppOpsManager.MODE_ALLOWED;
    }

    private void requestUsageStatsPermission() {
        Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
        tryStartActivity(intent);
    }

    private boolean checkWriteSettingsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return Settings.System.canWrite(this);
        }
        return true;
    }

    private void requestWriteSettingsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS);
            intent.setData(Uri.parse("package:" + getPackageName()));
            tryStartActivity(intent);
        }
    }

    private boolean setSystemBrightness(int brightness) {
        if (checkWriteSettingsPermission()) {
            try {
                android.content.ContentResolver resolver = getContentResolver();
                // 1. Standard Android brightness
                Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS_MODE, Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL);
                Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS, brightness);
                
                // 2. Try common TV "Backlight" keys (Vendor specific)
                Settings.System.putInt(resolver, "backlight", brightness);
                Settings.System.putInt(resolver, "backlight_level", brightness);
                
                return true;
            } catch (Exception e) {
                // Ignore errors on specific keys as they may not exist
                return true; 
            }
        }
        return false;
    }

    private boolean openWifiSettings() {
        // Fire OS 8 routes the standard Wi-Fi action to this native network submenu.
        Intent fireTvNetwork = new Intent(Settings.ACTION_WIFI_SETTINGS)
                .addCategory(Intent.CATEGORY_DEFAULT)
                .setComponent(new ComponentName(
                        "com.amazon.tv.settings.v2",
                        "com.amazon.tv.settings.v2.tv.network.NetworkActivity"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        if (tryStartActivity("Fire TV NetworkActivity", fireTvNetwork)) {
            return true;
        }

        Intent wifiIntent = new Intent(Settings.ACTION_WIFI_SETTINGS)
                .addCategory(Intent.CATEGORY_DEFAULT)
                .setPackage("com.amazon.tv.settings.v2")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        if (tryStartActivity(wifiIntent)) {
            return true;
        }

        Intent wirelessIntent = new Intent(Settings.ACTION_WIRELESS_SETTINGS)
                .addCategory(Intent.CATEGORY_DEFAULT)
                .setPackage("com.amazon.tv.settings.v2")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        if (tryStartActivity(wirelessIntent)) {
            return true;
        }

        // 4. Final fallback - open main settings
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

}
