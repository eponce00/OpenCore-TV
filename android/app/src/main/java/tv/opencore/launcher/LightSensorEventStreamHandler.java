package tv.opencore.launcher;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Handler;
import android.os.Looper;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

public class LightSensorEventStreamHandler implements EventChannel.StreamHandler {
    private final SensorManager sensorManager;
    private final Sensor lightSensor;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private SensorEventListener listener;

    public LightSensorEventStreamHandler(Context context) {
        sensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
        lightSensor = sensorManager == null ? null : sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT);
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        if (sensorManager == null || lightSensor == null) {
            Map<String, Object> event = new HashMap<>();
            event.put("available", false);
            event.put("lux", null);
            event.put("sensorName", "");
            events.success(event);
            return;
        }

        listener = new SensorEventListener() {
            @Override
            public void onSensorChanged(SensorEvent sensorEvent) {
                if (sensorEvent.values.length == 0) return;
                float lux = sensorEvent.values[0];
                mainHandler.post(() -> {
                    Map<String, Object> event = new HashMap<>();
                    event.put("available", true);
                    event.put("lux", lux);
                    event.put("sensorName", lightSensor.getName());
                    events.success(event);
                });
            }

            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {
            }
        };

        sensorManager.registerListener(
                listener,
                lightSensor,
                SensorManager.SENSOR_DELAY_NORMAL,
                mainHandler
        );
    }

    @Override
    public void onCancel(Object arguments) {
        if (sensorManager != null && listener != null) {
            sensorManager.unregisterListener(listener);
            listener = null;
        }
    }
}
