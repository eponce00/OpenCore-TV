package tv.opencore.launcher;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityEvent;

import java.io.BufferedReader;
import java.io.InputStreamReader;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class HomeGuardAccessibilityService extends AccessibilityService {
    private static final String TRACE_TAG = "OpenCoreTrace";
    private static final boolean VERBOSE_ACCESSIBILITY_LOGS = false;
    private static final String AMAZON_LAUNCHER_PACKAGE = "com.amazon.tv.launcher";
    private static final String AMAZON_INPUT_PACKAGE = "com.amazon.tv.inputpreference.service";
    private static final long HOME_LAUNCH_DEBOUNCE_MS = 80;
    private static final long INPUT_MENU_DEBOUNCE_MS = 500;
    private static final long INPUT_FLOW_SUPPRESS_HOME_MS = 15000;
    private static final long CURTAIN_HIDE_DELAY_MS = 900;
    private static final long OPENCORE_RECENT_WINDOW_MS = 2500;
    private static final long LEARNING_RETURN_RETRY_MS = 350;
    private static final String FLUTTER_PREFS = "FlutterSharedPreferences";
    private static final String LEARNED_REMOTE_BUTTONS_PREF = "flutter.learned_remote_buttons";
    private static final String REMOTE_BUTTON_LEARNING_ACTIVE_PREF = "flutter.remote_button_learning_active";
    private static final String REMOTE_BUTTON_PENDING_CAPTURE_PREF = "flutter.remote_button_pending_capture";

    private long lastHomeLaunchTimeMs = 0;
    private long lastInputMenuLaunchTimeMs = 0;
    private long lastInputFlowTimeMs = 0;
    private long lastOpenCoreWindowTimeMs = 0;
    private String currentPackageName = "";
    private String currentClassName = "";
    private String previousForegroundPackageName = "";
    private String previousForegroundClassName = "";
    private String lastStableOpenCoreActivityClassName = "";
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private WindowManager windowManager;
    private View transitionCurtain;
    private Process logcatProcess;
    private Thread logcatThread;

    @Override
    public void onCreate() {
        super.onCreate();
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        startLogcatHook();
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        CharSequence packageName = event.getPackageName();
        CharSequence className = event.getClassName();
        if (packageName != null) {
            String nextPackageName = packageName.toString();
            String nextClassName = className == null ? "" : className.toString();
            String priorPackageName = currentPackageName;
            String priorClassName = currentClassName;
            if (!nextPackageName.equals(currentPackageName) ||
                    !nextClassName.equals(currentClassName)) {
                previousForegroundPackageName = priorPackageName;
                previousForegroundClassName = priorClassName;
                currentPackageName = nextPackageName;
                currentClassName = nextClassName;
            }
            if (VERBOSE_ACCESSIBILITY_LOGS) {
                Log.w(TRACE_TAG, "accessibility event type=" + event.getEventType()
                        + " package=" + currentPackageName
                        + " class=" + currentClassName
                        + " previous=" + previousForegroundPackageName
                        + " previousClass=" + previousForegroundClassName
                        + " stableOpenCoreClass=" + lastStableOpenCoreActivityClassName
                        + " openCoreRecent=" + wasOpenCoreRecentlyActive());
            }
            if (isOpenCorePackage(currentPackageName)) {
                lastOpenCoreWindowTimeMs = System.currentTimeMillis();
                if (isOpenCoreActivityClass(currentClassName)) {
                    lastStableOpenCoreActivityClassName = currentClassName;
                }
            }
        }
        if (isRemoteButtonLearningActive()
                && !isOpenCorePackage(currentPackageName)
                && currentPackageName != null
                && !currentPackageName.isBlank()) {
            captureLearningLaunch(currentPackageName, currentClassName);
            return;
        }
        if (!isOpenCorePackage(currentPackageName)
                && launchLearnedRemoteLaunch(currentPackageName, currentClassName)) {
            return;
        }
        if (packageName != null && AMAZON_INPUT_PACKAGE.contentEquals(packageName)) {
            handleAmazonInputWindow();
            return;
        }
        if (packageName != null && AMAZON_LAUNCHER_PACKAGE.contentEquals(packageName)) {
            handleAmazonLauncherWindow();
        }
    }

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
        if (isRemoteButtonLearningActive()) {
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                if (isLearnableRemoteButton(event.getKeyCode())) {
                    captureLearningKey(event);
                    return true;
                }
            }
            return super.onKeyEvent(event);
        }

        if (event.getAction() == KeyEvent.ACTION_DOWN && launchLearnedRemoteButton(event)) {
            return true;
        }

        if (event.getKeyCode() == KeyEvent.KEYCODE_HOME) {
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                Log.w(TRACE_TAG, "home key down currentPackage=" + currentPackageName
                        + " currentClass=" + currentClassName
                        + " isOpenCore=" + isOpenCorePackage(currentPackageName)
                        + " openCoreRecent=" + wasOpenCoreRecentlyActive());
                if (MainActivity.isPanelOpen()) {
                    launchOpenCoreDismissPanel();
                } else if (isOpenCoreHomeForeground()) {
                    launchOpenCoreIdle();
                } else {
                    launchOpenCoreHome();
                }
            }
            return true;
        }

        if (isInputMenuKey(event.getKeyCode())) {
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                lastInputFlowTimeMs = System.currentTimeMillis();
                launchOpenCoreInputMenu();
            }
            return true;
        }

        String directInputId = OpenCoreInputs.inputIdForKeyCode(event.getKeyCode());
        if (directInputId != null) {
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                lastInputFlowTimeMs = System.currentTimeMillis();
                launchOpenCoreInput(directInputId, OpenCoreInputs.fallbackLabelForKeyCode(event.getKeyCode()));
            }
            return true;
        }

        return super.onKeyEvent(event);
    }

    @Override
    public void onInterrupt() {
    }

    @Override
    public void onDestroy() {
        stopLogcatHook();
        super.onDestroy();
    }

    private SharedPreferences flutterPrefs() {
        return getSharedPreferences(FLUTTER_PREFS, MODE_PRIVATE);
    }

    private boolean isRemoteButtonLearningActive() {
        return flutterPrefs().getBoolean(REMOTE_BUTTON_LEARNING_ACTIVE_PREF, false);
    }

    private void captureLearningKey(KeyEvent event) {
        try {
            JSONObject capture = new JSONObject()
                    .put("keyCode", event.getKeyCode())
                    .put("scanCode", event.getScanCode())
                    .put("deviceId", event.getDeviceId())
                    .put("source", event.getSource())
                    .put("displayLabel", KeyEvent.keyCodeToString(event.getKeyCode()));
            flutterPrefs().edit()
                    .putBoolean(REMOTE_BUTTON_LEARNING_ACTIVE_PREF, false)
                    .putString(REMOTE_BUTTON_PENDING_CAPTURE_PREF, capture.toString())
                    .apply();
        } catch (JSONException exception) {
            Log.w(TRACE_TAG, "Unable to capture learning key", exception);
            flutterPrefs().edit()
                    .putBoolean(REMOTE_BUTTON_LEARNING_ACTIVE_PREF, false)
                    .remove(REMOTE_BUTTON_PENDING_CAPTURE_PREF)
                    .apply();
        }

        returnToRemoteButtonLearning();
    }

    private void captureLearningLaunch(String packageName, String className) {
        try {
            JSONObject capture = new JSONObject()
                    .put("keyCode", 0)
                    .put("scanCode", 0)
                    .put("deviceId", 0)
                    .put("source", 0)
                    .put("triggerPackage", packageName)
                    .put("triggerClass", className == null ? "" : className)
                    .put("displayLabel", packageName);
            flutterPrefs().edit()
                    .putBoolean(REMOTE_BUTTON_LEARNING_ACTIVE_PREF, false)
                    .putString(REMOTE_BUTTON_PENDING_CAPTURE_PREF, capture.toString())
                    .apply();
        } catch (JSONException exception) {
            Log.w(TRACE_TAG, "Unable to capture learning launch", exception);
            flutterPrefs().edit()
                    .putBoolean(REMOTE_BUTTON_LEARNING_ACTIVE_PREF, false)
                    .remove(REMOTE_BUTTON_PENDING_CAPTURE_PREF)
                    .apply();
        }

        returnToRemoteButtonLearning();
    }

    private void returnToRemoteButtonLearning() {
        performGlobalAction(GLOBAL_ACTION_HOME);
        startRemoteButtonLearningActivity();
        mainHandler.postDelayed(this::startRemoteButtonLearningActivity, LEARNING_RETURN_RETRY_MS);
        mainHandler.postDelayed(this::startRemoteButtonLearningActivity, LEARNING_RETURN_RETRY_MS * 2);
    }

    private void startRemoteButtonLearningActivity() {
        Intent intent = new Intent(this, MainActivity.class)
                .setAction(MainActivity.ACTION_REMOTE_BUTTON_CAPTURED)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                        | Intent.FLAG_ACTIVITY_SINGLE_TOP
                        | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(intent);
    }

    private boolean isLearnableRemoteButton(int keyCode) {
        return switch (keyCode) {
            case KeyEvent.KEYCODE_HOME,
                    KeyEvent.KEYCODE_BACK,
                    KeyEvent.KEYCODE_DPAD_UP,
                    KeyEvent.KEYCODE_DPAD_DOWN,
                    KeyEvent.KEYCODE_DPAD_LEFT,
                    KeyEvent.KEYCODE_DPAD_RIGHT,
                    KeyEvent.KEYCODE_DPAD_CENTER,
                    KeyEvent.KEYCODE_ENTER,
                    KeyEvent.KEYCODE_NUMPAD_ENTER,
                    KeyEvent.KEYCODE_BUTTON_A -> false;
            default -> true;
        };
    }

    private boolean launchLearnedRemoteButton(KeyEvent event) {
        if (!isLearnableRemoteButton(event.getKeyCode())) {
            return false;
        }
        String packageName = learnedRemoteButtonPackage(event);
        if (packageName == null || packageName.isBlank()) {
            return false;
        }
        Log.w(TRACE_TAG, "learned remote button keyCode=" + event.getKeyCode()
                + " scanCode=" + event.getScanCode()
                + " assignment=" + packageName);
        return launchPackageAssignment(packageName);
    }

    private boolean launchLearnedRemoteLaunch(String packageName, String className) {
        String assignment = learnedRemoteLaunchPackage(packageName, className);
        if (assignment == null || assignment.isBlank() || assignment.equals(packageName)) {
            return false;
        }
        Log.w(TRACE_TAG, "learned remote launch package=" + packageName
                + " class=" + className
                + " assignment=" + assignment);
        showTransitionCurtain();
        boolean launched = launchPackageAssignment(assignment);
        if (!launched || !OpenCoreInputs.isSyntheticInputPackage(assignment)) {
            hideTransitionCurtainSoon();
        }
        return launched;
    }

    private String learnedRemoteButtonPackage(KeyEvent event) {
        String mappings = flutterPrefs().getString(LEARNED_REMOTE_BUTTONS_PREF, "[]");
        if (mappings == null || mappings.isBlank()) {
            return null;
        }
        try {
            JSONArray buttons = new JSONArray(mappings);
            for (int i = 0; i < buttons.length(); i++) {
                JSONObject button = buttons.optJSONObject(i);
                if (button == null) {
                    continue;
                }
                if (button.optInt("keyCode", KeyEvent.KEYCODE_UNKNOWN) != event.getKeyCode()) {
                    continue;
                }
                int scanCode = button.optInt("scanCode", 0);
                if (scanCode != 0 && event.getScanCode() != 0 && scanCode != event.getScanCode()) {
                    continue;
                }
                return button.optString("packageName", "");
            }
        } catch (JSONException exception) {
            Log.w(TRACE_TAG, "Unable to parse learned remote buttons", exception);
        }
        return null;
    }

    private String learnedRemoteLaunchPackage(String packageName, String className) {
        String mappings = flutterPrefs().getString(LEARNED_REMOTE_BUTTONS_PREF, "[]");
        if (mappings == null || mappings.isBlank()) {
            return null;
        }
        try {
            JSONArray buttons = new JSONArray(mappings);
            for (int i = 0; i < buttons.length(); i++) {
                JSONObject button = buttons.optJSONObject(i);
                if (button == null) {
                    continue;
                }
                String triggerPackage = button.optString("triggerPackage", "");
                if (!packageName.equals(triggerPackage)) {
                    continue;
                }
                String triggerClass = button.optString("triggerClass", "");
                if (!triggerClass.isBlank()
                        && className != null
                        && !triggerClass.equals(className)) {
                    continue;
                }
                return button.optString("packageName", "");
            }
        } catch (JSONException exception) {
            Log.w(TRACE_TAG, "Unable to parse learned remote launches", exception);
        }
        return null;
    }

    private boolean launchPackageAssignment(String packageName) {
        if (OpenCoreInputs.isSyntheticInputPackage(packageName)) {
            String inputId = OpenCoreInputs.inputIdForPackage(packageName);
            if (inputId == null) {
                return false;
            }
            launchOpenCoreInput(inputId, OpenCoreInputs.fallbackLabelForPackage(packageName));
            return true;
        }

        Intent intent = getPackageManager().getLeanbackLaunchIntentForPackage(packageName);
        if (intent == null) {
            intent = getPackageManager().getLaunchIntentForPackage(packageName);
        }
        if (intent == null) {
            return false;
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                | Intent.FLAG_ACTIVITY_CLEAR_TOP
                | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        startActivity(intent);
        return true;
    }

    private void launchOpenCoreHome() {
        long now = System.currentTimeMillis();
        if (now - lastHomeLaunchTimeMs < HOME_LAUNCH_DEBOUNCE_MS) {
            Log.w(TRACE_TAG, "launchOpenCoreHome debounced");
            return;
        }

        lastHomeLaunchTimeMs = now;
        Log.w(TRACE_TAG, "launchOpenCoreHome start");
        showTransitionCurtain();
        Intent intent = new Intent(this, MainActivity.class)
                .setAction(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                        | Intent.FLAG_ACTIVITY_CLEAR_TOP
                        | Intent.FLAG_ACTIVITY_SINGLE_TOP
                        | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
        startActivity(intent);
        hideTransitionCurtainSoon();
    }

    private void launchOpenCoreIdle() {
        long now = System.currentTimeMillis();
        if (now - lastHomeLaunchTimeMs < HOME_LAUNCH_DEBOUNCE_MS) {
            Log.w(TRACE_TAG, "launchOpenCoreIdle debounced");
            return;
        }

        lastHomeLaunchTimeMs = now;
        Log.w(TRACE_TAG, "launchOpenCoreIdle start");
        Intent intent = new Intent(this, MainActivity.class)
                .setAction(MainActivity.ACTION_ENTER_IDLE)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                        | Intent.FLAG_ACTIVITY_SINGLE_TOP
                        | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(intent);
    }

    private void launchOpenCoreDismissPanel() {
        long now = System.currentTimeMillis();
        if (now - lastHomeLaunchTimeMs < HOME_LAUNCH_DEBOUNCE_MS) {
            Log.w(TRACE_TAG, "launchOpenCoreDismissPanel debounced");
            return;
        }

        lastHomeLaunchTimeMs = now;
        Log.w(TRACE_TAG, "launchOpenCoreDismissPanel start");
        Intent intent = new Intent(this, MainActivity.class)
                .setAction(MainActivity.ACTION_DISMISS_PANEL)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                        | Intent.FLAG_ACTIVITY_SINGLE_TOP
                        | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(intent);
    }

    private void returnToOpenCoreHomeFromInputBlock() {
        long now = System.currentTimeMillis();
        if (now - lastHomeLaunchTimeMs < HOME_LAUNCH_DEBOUNCE_MS) {
            Log.w(TRACE_TAG, "returnToOpenCoreHomeFromInputBlock debounced");
            return;
        }

        lastHomeLaunchTimeMs = now;
        Log.w(TRACE_TAG, "returnToOpenCoreHomeFromInputBlock start");
        showTransitionCurtain();
        Intent intent = new Intent(this, MainActivity.class)
                .setAction(MainActivity.ACTION_RETURN_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                        | Intent.FLAG_ACTIVITY_CLEAR_TOP
                        | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        startActivity(intent);
        hideTransitionCurtainSoon();
    }

    private boolean isOpenCorePackage(String packageName) {
        return getPackageName().equals(packageName)
                || "tv.opencore.launcher".equals(packageName)
                || "tv.opencore.launcher.debug".equals(packageName);
    }

    private boolean wasOpenCoreRecentlyActive() {
        return System.currentTimeMillis() - lastOpenCoreWindowTimeMs < OPENCORE_RECENT_WINDOW_MS;
    }

    private boolean wasOpenCoreHomeRecentlyActive() {
        return wasOpenCoreRecentlyActive() && wasLastStableOpenCoreActivityHome();
    }

    private boolean isOpenCoreHomeForeground() {
        return isOpenCorePackage(currentPackageName) && wasLastStableOpenCoreActivityHome();
    }

    private boolean wasPreviousForegroundOpenCoreHome() {
        return isOpenCorePackage(previousForegroundPackageName)
                && wasLastStableOpenCoreActivityHome();
    }

    private boolean isOpenCoreHomeClass(String className) {
        return className != null && className.contains("MainActivity");
    }

    private boolean wasLastStableOpenCoreActivityHome() {
        return isOpenCoreHomeClass(lastStableOpenCoreActivityClassName);
    }

    private boolean isOpenCoreActivityClass(String className) {
        return className != null && className.startsWith(getPackageName() + ".");
    }

    private boolean isAmazonSettingsClass(String className) {
        return className != null && className.contains("SettingsActivity");
    }

    private boolean isAmazonPassthroughClass(String className) {
        return className != null && className.contains("PassthroughPlayerActivity");
    }

    private boolean isAmazonInputMenuLauncherClass(String className) {
        return className != null
                && className.contains("RecentDeepLinkActivityDI");
    }

    private void handleAmazonInputWindow() {
        if (isAmazonPassthroughClass(currentClassName)) {
            lastInputFlowTimeMs = System.currentTimeMillis();
            return;
        }
        launchOpenCoreInputMenu();
    }

    private void handleAmazonLauncherWindow() {
        if (isAmazonSettingsClass(currentClassName)) {
            return;
        }
        if (isAmazonInputMenuLauncherClass(currentClassName)
                || isAmazonInputMenuLauncherClass(previousForegroundClassName)) {
            launchOpenCoreInputMenu();
            return;
        }
        if (isInsideInputFlow()) {
            return;
        }
        if (MainActivity.isPanelOpen()) {
            launchOpenCoreDismissPanel();
            return;
        }
        if (wasPreviousForegroundOpenCoreHome()) {
            launchOpenCoreIdle();
            return;
        }
        launchOpenCoreHome();
    }

    private boolean isInputMenuKey(int keyCode) {
        return keyCode == KeyEvent.KEYCODE_TV_INPUT
                || keyCode == KeyEvent.KEYCODE_STB_INPUT
                || keyCode == KeyEvent.KEYCODE_AVR_INPUT;
    }

    private void launchOpenCoreInputMenu() {
        if (shouldBlockInputMenuForOpenCoreHome()) {
            Log.w(TRACE_TAG, "launchOpenCoreInputMenu blocked on OpenCore home");
            if (!isOpenCoreHomeForeground()) {
                returnToOpenCoreHomeFromInputBlock();
            }
            return;
        }

        long now = System.currentTimeMillis();
        if (now - lastInputMenuLaunchTimeMs < INPUT_MENU_DEBOUNCE_MS) {
            Log.w(TRACE_TAG, "launchOpenCoreInputMenu debounced");
            return;
        }

        lastInputMenuLaunchTimeMs = now;
        lastInputFlowTimeMs = now;
        Log.w(TRACE_TAG, "launchOpenCoreInputMenu start");
        showTransitionCurtain();
        Intent intent = new Intent(this, MainActivity.class)
                .setAction(MainActivity.ACTION_SHOW_INPUT_SELECTOR)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                        | Intent.FLAG_ACTIVITY_CLEAR_TOP
                        | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        startActivity(intent);
        hideTransitionCurtainSoon();
    }

    private boolean shouldBlockInputMenuForOpenCoreHome() {
        return isOpenCoreHomeForeground()
                || wasPreviousForegroundOpenCoreHome()
                || wasOpenCoreHomeRecentlyActive();
    }

    private void launchOpenCoreInput(String inputId, String label) {
        lastInputFlowTimeMs = System.currentTimeMillis();
        showTransitionCurtain();
        Intent intent = new Intent(this, InputPlayerActivity.class)
                .putExtra(InputPlayerActivity.EXTRA_INPUT_ID, inputId)
                .putExtra(InputPlayerActivity.EXTRA_INPUT_LABEL, label)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                        | Intent.FLAG_ACTIVITY_CLEAR_TOP
                        | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        startActivity(intent);
        hideTransitionCurtainSoon();
    }

    private boolean isInsideInputFlow() {
        return System.currentTimeMillis() - lastInputFlowTimeMs < INPUT_FLOW_SUPPRESS_HOME_MS;
    }

    private void showTransitionCurtain() {
        mainHandler.post(() -> {
            if (transitionCurtain != null || windowManager == null) {
                return;
            }

            transitionCurtain = new View(this);
            transitionCurtain.setBackgroundColor(Color.BLACK);
            WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                            | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                            | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                            | WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    PixelFormat.OPAQUE);
            params.gravity = Gravity.TOP | Gravity.START;

            try {
                windowManager.addView(transitionCurtain, params);
            } catch (RuntimeException ignored) {
                transitionCurtain = null;
            }
        });
    }

    private void hideTransitionCurtainSoon() {
        mainHandler.postDelayed(() -> {
            if (transitionCurtain == null || windowManager == null) {
                return;
            }

            try {
                windowManager.removeView(transitionCurtain);
            } catch (RuntimeException ignored) {
            } finally {
                transitionCurtain = null;
            }
        }, CURTAIN_HIDE_DELAY_MS);
    }

    private void startLogcatHook() {
        if (logcatThread != null) {
            return;
        }

        logcatThread = new Thread(() -> {
            try {
                logcatProcess = new ProcessBuilder("logcat", "-v", "brief", "ActivityTaskManager:I", "ActivityManager:I", "*:S")
                        .redirectErrorStream(true)
                        .start();
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(logcatProcess.getInputStream()))) {
                    String line;
                    while ((line = reader.readLine()) != null && !Thread.currentThread().isInterrupted()) {
                        handleLogLine(line);
                    }
                }
            } catch (Exception ignored) {
                // READ_LOGS is optional. Accessibility still handles the fallback path.
            }
        }, "OpenCoreHomeLogHook");
        logcatThread.setDaemon(true);
        logcatThread.start();
    }

    private void stopLogcatHook() {
        if (logcatThread != null) {
            logcatThread.interrupt();
            logcatThread = null;
        }
        if (logcatProcess != null) {
            logcatProcess.destroy();
            logcatProcess = null;
        }
    }

    private void handleLogLine(String line) {
        if (line.contains("com.amazon.tv.action.NAVIGATE_TO_INPUTS")
                || line.contains("com.amazon.tv.inputpreference.action.LAUNCH_INPUTS")) {
            lastInputFlowTimeMs = System.currentTimeMillis();
            mainHandler.post(this::launchOpenCoreInputMenu);
            return;
        }

        if (line.contains("com.amazon.tv.inputpreference.service")) {
            if (line.contains("PassthroughPlayerActivity")) {
                lastInputFlowTimeMs = System.currentTimeMillis();
            } else {
                mainHandler.post(this::launchOpenCoreInputMenu);
            }
            return;
        }

        if (line.contains("android.intent.category.HOME")
                && line.contains("com.amazon.tv.launcher")) {
            mainHandler.post(this::launchOpenCoreHome);
        }
    }

}
