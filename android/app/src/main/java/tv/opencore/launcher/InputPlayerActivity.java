package tv.opencore.launcher;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.media.tv.TvView;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;

public class InputPlayerActivity extends Activity {
    public static final String EXTRA_INPUT_ID = "tv.opencore.launcher.extra.INPUT_ID";
    public static final String EXTRA_INPUT_LABEL = "tv.opencore.launcher.extra.INPUT_LABEL";
    public static final String EXTRA_INPUT_ICON = "tv.opencore.launcher.extra.INPUT_ICON";
    private static final long INPUT_BADGE_VISIBLE_MS = 2200;
    private static final long INPUT_BADGE_FADE_MS = 450;

    private TvView tvView;
    private FrameLayout root;
    private View inputBadge;
    private final Handler handler = new Handler(Looper.getMainLooper());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        root = new FrameLayout(this);
        tvView = new TvView(this);
        root.addView(tvView, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
        ));

        showInputBadge();

        setContentView(root);
        tune();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        if (tvView != null) {
            tvView.reset();
            tune();
        }
        showInputBadge();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (tvView != null) {
            tvView.setStreamVolume(1.0f);
            tvView.reset();
            tune();
        }
    }

    @Override
    protected void onPause() {
        handler.removeCallbacksAndMessages(null);
        if (tvView != null) {
            tvView.reset();
        }
        super.onPause();
    }

    private void scheduleBadgeFade() {
        handler.postDelayed(() -> {
            if (inputBadge == null) {
                return;
            }

            inputBadge.animate()
                    .alpha(0f)
                    .setDuration(INPUT_BADGE_FADE_MS)
                    .withEndAction(() -> {
                        if (inputBadge != null) {
                            inputBadge.setVisibility(View.GONE);
                        }
                    })
                    .start();
        }, INPUT_BADGE_VISIBLE_MS);
    }

    private void showInputBadge() {
        if (root == null) {
            return;
        }

        handler.removeCallbacksAndMessages(null);
        if (inputBadge != null) {
            root.removeView(inputBadge);
            inputBadge = null;
        }

        String label = getIntent().getStringExtra(EXTRA_INPUT_LABEL);
        if (label == null) {
            return;
        }

        String icon = getIntent().getStringExtra(EXTRA_INPUT_ICON);
        inputBadge = new InputBadgeView(this, label, icon == null ? "tv" : icon);

        FrameLayout.LayoutParams badgeParams = new FrameLayout.LayoutParams(
                260,
                72,
                Gravity.TOP | Gravity.START
        );
        badgeParams.setMargins(32, 32, 0, 0);
        root.addView(inputBadge, badgeParams);
        scheduleBadgeFade();
    }

    private void tune() {
        String inputId = getIntent().getStringExtra(EXTRA_INPUT_ID);
        if (inputId != null && !inputId.isEmpty()) {
            tvView.tune(inputId, Uri.EMPTY);
        }
    }

    private static class InputBadgeView extends View {
        private final String label;
        private final String icon;
        private final Paint background = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint iconPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint textPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Rect textBounds = new Rect();

        InputBadgeView(Context context, String label, String icon) {
            super(context);
            this.label = label;
            this.icon = icon;
            background.setColor(Color.argb(168, 0, 0, 0));
            iconPaint.setColor(Color.WHITE);
            iconPaint.setStyle(Paint.Style.STROKE);
            iconPaint.setStrokeWidth(4f);
            iconPaint.setStrokeCap(Paint.Cap.ROUND);
            iconPaint.setStrokeJoin(Paint.Join.ROUND);
            textPaint.setColor(Color.WHITE);
            textPaint.setTextSize(26f);
            textPaint.setFakeBoldText(true);
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            canvas.drawRoundRect(0, 0, getWidth(), getHeight(), 18, 18, background);
            drawIcon(canvas, 42, getHeight() / 2f, 18);

            textPaint.getTextBounds(label, 0, label.length(), textBounds);
            float textY = getHeight() / 2f - textBounds.exactCenterY();
            canvas.drawText(label, 82, textY, textPaint);
        }

        private void drawIcon(Canvas canvas, float cx, float cy, float size) {
            switch (icon) {
                case "game" -> {
                    canvas.drawRoundRect(cx - size * 1.25f, cy - size * 0.58f, cx + size * 1.25f, cy + size * 0.58f, size * 0.35f, size * 0.35f, iconPaint);
                    canvas.drawLine(cx - size * 0.78f, cy, cx - size * 0.24f, cy, iconPaint);
                    canvas.drawLine(cx - size * 0.51f, cy - size * 0.27f, cx - size * 0.51f, cy + size * 0.27f, iconPaint);
                    canvas.drawCircle(cx + size * 0.52f, cy - size * 0.12f, size * 0.1f, iconPaint);
                    canvas.drawCircle(cx + size * 0.82f, cy + size * 0.12f, size * 0.1f, iconPaint);
                }
                case "movie" -> {
                    canvas.drawRoundRect(cx - size, cy - size * 0.65f, cx + size, cy + size * 0.65f, size * 0.16f, size * 0.16f, iconPaint);
                    canvas.drawLine(cx - size * 0.34f, cy - size * 0.65f, cx - size * 0.34f, cy + size * 0.65f, iconPaint);
                    canvas.drawLine(cx + size * 0.34f, cy - size * 0.65f, cx + size * 0.34f, cy + size * 0.65f, iconPaint);
                }
                case "computer" -> {
                    canvas.drawRect(cx - size, cy - size * 0.65f, cx + size, cy + size * 0.45f, iconPaint);
                    canvas.drawLine(cx - size * 0.35f, cy + size * 0.75f, cx + size * 0.35f, cy + size * 0.75f, iconPaint);
                    canvas.drawLine(cx, cy + size * 0.45f, cx, cy + size * 0.75f, iconPaint);
                }
                case "antenna" -> {
                    canvas.drawCircle(cx, cy - size * 0.35f, size * 0.16f, iconPaint);
                    canvas.drawLine(cx, cy - size * 0.2f, cx, cy + size * 0.9f, iconPaint);
                    canvas.drawLine(cx, cy + size * 0.15f, cx - size * 0.8f, cy + size * 0.9f, iconPaint);
                    canvas.drawLine(cx, cy + size * 0.15f, cx + size * 0.8f, cy + size * 0.9f, iconPaint);
                }
                case "camera" -> {
                    canvas.drawRoundRect(cx - size, cy - size * 0.58f, cx + size * 0.55f, cy + size * 0.58f, size * 0.18f, size * 0.18f, iconPaint);
                    canvas.drawLine(cx + size * 0.55f, cy - size * 0.2f, cx + size, cy - size * 0.5f, iconPaint);
                    canvas.drawLine(cx + size * 0.55f, cy + size * 0.2f, cx + size, cy + size * 0.5f, iconPaint);
                }
                default -> {
                    canvas.drawRoundRect(cx - size, cy - size * 0.65f, cx + size, cy + size * 0.65f, size * 0.18f, size * 0.18f, iconPaint);
                    canvas.drawLine(cx - size * 0.45f, cy + size * 0.9f, cx + size * 0.45f, cy + size * 0.9f, iconPaint);
                    canvas.drawLine(cx, cy + size * 0.65f, cx, cy + size * 0.9f, iconPaint);
                }
            }
        }
    }
}
