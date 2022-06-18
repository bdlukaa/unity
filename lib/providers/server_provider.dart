/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
 *
 * Copyright 2022 Bluecherry, LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';

/// This class manages & saves (caching) the currently added [Server]s by the user.
///
class ServersProvider extends ChangeNotifier {
  /// `late` initialized [ServersProvider] instance.
  static late final ServersProvider instance;

  /// Initializes the [ServersProvider] instance & fetches state from `async`
  /// `package:shared_preferences` method-calls. Called before [runApp].
  static Future<ServersProvider> ensureInitialized() async {
    instance = ServersProvider();
    await instance.initialize();
    return instance;
  }

  bool get serverAdded => servers.isNotEmpty;

  List<Server> servers = <Server>[];

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    if (!sharedPreferences.containsKey(kSharedPreferencesServers)) {
      await _save();
    } else {
      await _restore();
    }
  }

  /// Adds a new [Server] to the cache.
  /// Also registers the Firebase Messaging token for the server, to receive the notifications.
  Future<void> add(Server server) async {
    // Prevent duplicates.
    if (servers.contains(server)) {
      return Future.value(null);
    }
    servers.add(server);
    await _save();
    // Register notification token.
    try {
      final instance = await SharedPreferences.getInstance();
      final notificationToken = instance.getString(
        kSharedPreferencesNotificationToken,
      );
      assert(
        notificationToken != null,
        "[kSharedPreferencesNotificationToken] is null.",
      );
      await API.instance.registerNotificationToken(server, notificationToken!);
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }

  /// Removes a [Server] from the cache.
  /// Also un-registers the Firebase Messaging token for the server, to stop receiving the notifications.
  Future<void> remove(Server server) async {
    servers.remove(server);
    await _save();
    // Remove the device camera tiles showing devices from this server.
    try {
      final provider = MobileViewProvider.instance;
      final view = {...provider.devices};
      for (final tab in view.keys) {
        final devices = view[tab]!;
        for (int i = 0; i < devices.length; i++) {
          final device = devices[i];
          if (device?.server == server) {
            await provider.remove(tab, i);
          }
        }
      }
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
    // Unregister notification token.
    try {
      await API.instance.unregisterNotificationToken(server);
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }

  /// Save currently added [Server]s to `package:shared_preferences` cache.
  Future<void> _save() async {
    final instance = await SharedPreferences.getInstance();
    await instance.setString(
      kSharedPreferencesServers,
      jsonEncode(servers.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  /// Restore currently added [Server]s from `package:shared_preferences` cache.
  Future<void> _restore() async {
    final instance = await SharedPreferences.getInstance();
    servers = jsonDecode(instance.getString(kSharedPreferencesServers)!)
        .map((e) => Server.fromJson(e))
        .toList()
        .cast<Server>();
    notifyListeners();
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}
