import 'package:opencore_tv/widgets/date_time_widget.dart';
import 'package:opencore_tv/widgets/weather_widget.dart';
import 'package:flutter/material.dart';
import 'package:opencore_tv/providers/settings_service.dart';
import 'package:provider/provider.dart';

class IdleOverlay extends StatelessWidget {
  const IdleOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final clockSize = switch (settings.idleClockSize) {
      "medium" => 56.0,
      "huge" => 92.0,
      _ => 74.0,
    };
    final clockFormat = settings.idleClockUse24Hour ? "HH:mm" : "h:mm a";

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(42),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DateTimeWidget(
                        clockFormat,
                        textStyle:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontSize: clockSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -2,
                                ),
                        animate: true,
                      ),
                      if (settings.idleClockShowDate) ...[
                        const SizedBox(height: 4),
                        DateTimeWidget(
                          "EEEE, MMMM d",
                          textStyle:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.72),
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: const WeatherWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
