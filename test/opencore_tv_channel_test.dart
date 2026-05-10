/*
 * OpenCoreTV
 * Copyright (C) 2021  Étienne Fesser
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

import 'package:opencore_tv/opencore_tv_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test("getApplications", () async {
    final channel = MethodChannel('tv.opencore.launcher/method');
    channel.setMockMethodCallHandler((call) async {
      if (call.method == "getApplications") {
        return [
          {'packageName': 'tv.opencore.launcher'}
        ];
      }
      fail("Unhandled method name");
    });
    final OpenCoreTVChannel = OpenCoreTVChannel();

    final apps = await OpenCoreTVChannel.getApplications();

    expect(apps, [
      {'packageName': 'tv.opencore.launcher'}
    ]);
  });

  test("launchApp", () async {
    final channel = MethodChannel('tv.opencore.launcher/method');
    String? packageName;
    channel.setMockMethodCallHandler((call) async {
      if (call.method == "launchApp") {
        packageName = call.arguments as String;
        return;
      }
      fail("Unhandled method name");
    });
    final OpenCoreTVChannel = OpenCoreTVChannel();

    await OpenCoreTVChannel.launchApp("tv.opencore.launcher");

    expect(packageName, "tv.opencore.launcher");
  });

  test("openSettings", () async {
    final channel = MethodChannel('tv.opencore.launcher/method');
    bool called = false;
    channel.setMockMethodCallHandler((call) async {
      if (call.method == "openSettings") {
        called = true;
        return;
      }
      fail("Unhandled method name");
    });
    final OpenCoreTVChannel = OpenCoreTVChannel();

    await OpenCoreTVChannel.openSettings();

    expect(called, isTrue);
  });

  test("openAppInfo", () async {
    final channel = MethodChannel('tv.opencore.launcher/method');
    String? packageName;
    channel.setMockMethodCallHandler((call) async {
      if (call.method == "openAppInfo") {
        packageName = call.arguments as String;
        return;
      }
      fail("Unhandled method name");
    });
    final OpenCoreTVChannel = OpenCoreTVChannel();

    await OpenCoreTVChannel.openAppInfo("tv.opencore.launcher");

    expect(packageName, "tv.opencore.launcher");
  });

  test("uninstallApp", () async {
    final channel = MethodChannel('tv.opencore.launcher/method');
    String? packageName;
    channel.setMockMethodCallHandler((call) async {
      if (call.method == "uninstallApp") {
        packageName = call.arguments as String;
        return;
      }
      fail("Unhandled method name");
    });
    final OpenCoreTVChannel = OpenCoreTVChannel();

    await OpenCoreTVChannel.uninstallApp("tv.opencore.launcher");

    expect(packageName, "tv.opencore.launcher");
  });

  test("isDefaultLauncher", () async {
    final channel = MethodChannel('tv.opencore.launcher/method');
    channel.setMockMethodCallHandler((call) async {
      if (call.method == "isDefaultLauncher") {
        return true;
      }
      fail("Unhandled method name");
    });
    final OpenCoreTVChannel = OpenCoreTVChannel();

    final isDefaultLauncher = await OpenCoreTVChannel.isDefaultLauncher();

    expect(isDefaultLauncher, isTrue);
  });

  test("checkForGetContentAvailability", () async {
    final channel = MethodChannel('tv.opencore.launcher/method');
    channel.setMockMethodCallHandler((call) async {
      if (call.method == "checkForGetContentAvailability") {
        return true;
      }
      fail("Unhandled method name");
    });
    final OpenCoreTVChannel = OpenCoreTVChannel();

    final getContentAvailable =
        await OpenCoreTVChannel.checkForGetContentAvailability();

    expect(getContentAvailable, isTrue);
  });

  test("startAmbientMode", () async {
    final channel = MethodChannel('tv.opencore.launcher/method');
    bool called = false;
    channel.setMockMethodCallHandler((call) async {
      if (call.method == "startAmbientMode") {
        called = true;
        return;
      }
      fail("Unhandled method name");
    });
    final OpenCoreTVChannel = OpenCoreTVChannel();

    await OpenCoreTVChannel.startAmbientMode();

    expect(called, isTrue);
  });
}
