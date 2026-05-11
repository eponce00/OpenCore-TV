package tv.opencore.launcher;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
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

public class HomeGuardAccessibilityService extends AccessibilityService {
    private static final String TRACE_TAG = "OpenCoreTrace";
    private static final String AMAZON_LAUNCHER_PACKAGE = "com.amazon.tv.launcher";
    private static final String AMAZON_INPUT_PACKAGE = "com.amazon.tv.inputpreference.service";
    private static final long HOME_LAUNCH_DEBOUNCE_MS = 80;
    private static final long INPUT_MENU_DEBOUNCE_MS = 500;
    private static final long INPUT_FLOW_SUPPRESS_HOME_MS = 3500;
    private static final long CURTAIN_HIDE_DELAY_MS = 900;
    private static final long OPENCORE_RECENT_WINDOW_MS = 2500;

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
            Log.w(TRACE_TAG, "accessibility event type=" + event.getEventType()
                    + " package=" + currentPackageName
                    + " class=" + currentClassName
                    + " previous=" + previousForegroundPackageName
                    + " previousClass=" + previousForegroundClassName
                    + " stableOpenCoreClass=" + lastStableOpenCoreActivityClassName
                    + " openCoreRecent=" + wasOpenCoreRecentlyActive());
            if (isOpenCorePackage(currentPackageName)) {
                lastOpenCoreWindowTimeMs = System.currentTimeMillis();
                if (isOpenCoreActivityClass(currentClassName)) {
                    lastStableOpenCoreActivityClassName = currentClassName;
                }
            }
        }
        if (packageName != null && AMAZON_INPUT_PACKAGE.contentEquals(packageName)) {
            lastInputFlowTimeMs = System.currentTimeMillis();
            launchOpenCoreInputMenu();
            return;
        }
        if (packageName != null && AMAZON_LAUNCHER_PACKAGE.contentEquals(packageName)) {
            if (isAmazonSettingsClass(currentClassName)) {
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
    }

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
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

        String directInputId = directInputIdForKey(event.getKeyCode());
        if (directInputId != null) {
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                lastInputFlowTimeMs = System.currentTimeMillis();
                launchOpenCoreInput(directInputId, directInputLabelForKey(event.getKeyCode()));
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

    private boolean isInputMenuKey(int keyCode) {
        return keyCode == KeyEvent.KEYCODE_TV_INPUT
                || keyCode == KeyEvent.KEYCODE_STB_INPUT
                || keyCode == KeyEvent.KEYCODE_AVR_INPUT;
    }

    private String directInputIdForKey(int keyCode) {
        return switch (keyCode) {
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_1 -> "com.mediatek.tis/.HdmiInputService/HW2";
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_2 -> "com.mediatek.tis/.HdmiInputService/HW3";
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_3 -> "com.mediatek.tis/.HdmiInputService/HW4";
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_4 -> "com.mediatek.tis/.HdmiInputService/HW5";
            default -> null;
        };
    }

    private String directInputLabelForKey(int keyCode) {
        return switch (keyCode) {
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_1 -> "HDMI 1";
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_2 -> "HDMI 2";
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_3 -> "HDMI 3";
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_4 -> "HDMI 4";
            default -> "Input";
        };
    }

    private void launchOpenCoreInputMenu() {
        launchOpenCoreHome();
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
                || line.contains("com.amazon.tv.inputpreference.action.LAUNCH_INPUTS")
                || line.contains("com.amazon.tv.inputpreference.service")) {
            lastInputFlowTimeMs = System.currentTimeMillis();
            mainHandler.post(this::launchOpenCoreInputMenu);
            return;
        }

        if (line.contains("android.intent.category.HOME")
                && line.contains("com.amazon.tv.launcher")) {
            mainHandler.post(this::launchOpenCoreHome);
        }
    }
}
