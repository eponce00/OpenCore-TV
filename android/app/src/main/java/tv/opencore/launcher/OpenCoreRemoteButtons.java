package tv.opencore.launcher;

final class OpenCoreRemoteButtons {
    private OpenCoreRemoteButtons() {
    }

    static String buttonIdForActivityLogLine(String line) {
        if (!line.contains("com.amazon.venezia/.pdi.AppLaunchActivity")
                && !line.contains("com.amazon.firebatcore.deeplink.DeepLinkRoutingActivity")) {
            return null;
        }

        if (line.contains("deeplink_prime_video")) {
            return "prime";
        }
        if (line.contains("asin=B00OGRMULA")) {
            return "netflix";
        }
        if (line.contains("asin=B07Y8SJGCV")) {
            return "disney";
        }
        if (line.contains("asin=B08BG9MPT9")) {
            return "peacock";
        }
        return null;
    }
}
