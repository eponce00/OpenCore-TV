package tv.opencore.launcher;

import android.view.KeyEvent;

import java.util.List;

final class OpenCoreInputs {
    static final String PACKAGE_PREFIX = "opencore.input.";

    static final class Shortcut {
        final String packageName;
        final String fallbackLabel;
        final String inputId;

        Shortcut(String packageName, String fallbackLabel, String inputId) {
            this.packageName = packageName;
            this.fallbackLabel = fallbackLabel;
            this.inputId = inputId;
        }
    }

    static final List<Shortcut> SHORTCUTS = List.of(
            new Shortcut("opencore.input.hdmi1", "HDMI 1", "com.mediatek.tis/.HdmiInputService/HW2"),
            new Shortcut("opencore.input.hdmi2", "HDMI 2", "com.mediatek.tis/.HdmiInputService/HW3"),
            new Shortcut("opencore.input.hdmi3", "HDMI 3", "com.mediatek.tis/.HdmiInputService/HW4"),
            new Shortcut("opencore.input.hdmi4", "HDMI 4", "com.mediatek.tis/.HdmiInputService/HW5"),
            new Shortcut("opencore.input.antenna", "Antenna", "com.mediatek.dtv.tvinput.atsctuner/.AtscTunerInputService/HW0"),
            new Shortcut("opencore.input.composite", "Composite", "com.mediatek.tis/.CompositeInputService/HW6")
    );

    private OpenCoreInputs() {
    }

    static boolean isSyntheticInputPackage(String packageName) {
        return packageName != null && packageName.startsWith(PACKAGE_PREFIX);
    }

    static String inputIdForPackage(String packageName) {
        Shortcut shortcut = shortcutForPackage(packageName);
        return shortcut == null ? null : shortcut.inputId;
    }

    static String fallbackLabelForPackage(String packageName) {
        Shortcut shortcut = shortcutForPackage(packageName);
        return shortcut == null ? "Input" : shortcut.fallbackLabel;
    }

    static String inputIdForKeyCode(int keyCode) {
        return switch (keyCode) {
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_1 -> inputIdForPackage("opencore.input.hdmi1");
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_2 -> inputIdForPackage("opencore.input.hdmi2");
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_3 -> inputIdForPackage("opencore.input.hdmi3");
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_4 -> inputIdForPackage("opencore.input.hdmi4");
            default -> null;
        };
    }

    static String fallbackLabelForKeyCode(int keyCode) {
        return switch (keyCode) {
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_1 -> fallbackLabelForPackage("opencore.input.hdmi1");
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_2 -> fallbackLabelForPackage("opencore.input.hdmi2");
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_3 -> fallbackLabelForPackage("opencore.input.hdmi3");
            case KeyEvent.KEYCODE_TV_INPUT_HDMI_4 -> fallbackLabelForPackage("opencore.input.hdmi4");
            default -> "Input";
        };
    }

    private static Shortcut shortcutForPackage(String packageName) {
        for (Shortcut shortcut : SHORTCUTS) {
            if (shortcut.packageName.equals(packageName)) {
                return shortcut;
            }
        }
        return null;
    }
}
