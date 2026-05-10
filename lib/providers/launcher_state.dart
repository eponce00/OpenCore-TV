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

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'apps_service.dart';

class LauncherState extends ChangeNotifier {
  bool _isDefaultLauncher;
  bool get isDefaultLauncher => _isDefaultLauncher;

  LauncherState() : _isDefaultLauncher = false;

  Future<void> refresh(AppsService appsService) async {
    _isDefaultLauncher = await appsService.isDefaultLauncher();
    notifyListeners();
  }

  void handleBackNavigation(BuildContext context) {
    AppsService appsService = context.read<AppsService>();
    refresh(appsService);
    // Back on the root launcher should be harmless. Nested settings/app panels
    // consume Back before this method is called.
  }
}
