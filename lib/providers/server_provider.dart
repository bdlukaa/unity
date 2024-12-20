/*
 * This file is a part of Bluecherry Client (https://github.com/bluecherrydvr/unity).
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

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:flutter/foundation.dart';

class ServersProvider extends UnityProvider {
  ServersProvider._();
  ServersProvider.dump();

  static late ServersProvider instance;
  static Future<ServersProvider> ensureInitialized() async {
    instance = ServersProvider._();
    await instance.initialize();
    debugPrint('ServersProvider initialized');
    return instance;
  }

  /// Whether any server is added.
  bool get hasServers => servers.isNotEmpty;

  List<Server> servers = <Server>[];

  /// The list of servers that are being loaded
  List<String> loadingServer = <String>[];

  bool isServerLoading(Server server) => loadingServer.contains(server.id);

  /// Called by [ensureInitialized].
  @override
  Future<void> initialize() async {
    await initializeStorage(kStorageServers);
    refreshDevices(startup: true);
  }

  /// Adds a new [Server] to the cache.
  /// Also registers the Firebase Messaging token for the server, to receive the notifications.
  Future<void> add(Server server) async {
    if (servers.contains(server)) return;

    servers.add(server);
    await save();
    await refreshDevices(ids: [server.id]);

    if (isMobilePlatform) {
      // Register notification token.
      try {
        final notificationToken = await secureStorage.read(
          key: kStorageNotificationToken,
        );
        assert(
          notificationToken != null,
          '[kStorageNotificationToken] is null.',
        );
        if (notificationToken != null) {
          // release safety
          await API.instance.registerNotificationToken(
            server,
            notificationToken,
          );
        }
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
      }
    }
  }

  /// Removes a [Server] from the cache.
  /// Also un-registers the Firebase Messaging token for the server, to stop receiving the notifications.
  Future<void> remove(Server server) async {
    servers.remove(server);
    await save();

    // Remove the device camera tiles showing devices from this server.
    try {
      final provider = MobileViewProvider.instance;
      final view = {...provider.devices};
      for (final tab in view.keys) {
        final devices = view[tab]!;
        for (var i = 0; i < devices.length; i++) {
          final device = devices[i];
          if (device?.server == server) {
            await provider.remove(tab, i);
          }
        }
      }

      final desktopProvider = DesktopViewProvider.instance;
      await desktopProvider.removeDevices(server.devices);
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

  /// Updates the given [server] in the cache.
  Future<void> update(Server server) async {
    // If not found, add it
    if (!servers.any((s) => s.ip == server.ip && s.port == server.port)) {
      return add(server);
    }

    final s = servers.firstWhere(
      (s) => s.ip == server.ip && s.port == server.port,
      orElse: () => server,
    );
    final serverIndex = servers.indexOf(s);

    for (final device in server.devices) {
      device.server = server;
      if (UnityPlayers.players.keys.contains(device.uuid)) {
        UnityPlayers.reloadDevice(device);
      }
    }

    servers[serverIndex] = server;

    await save();
    UnityPlayers.reloadAll();
  }

  /// If [ids] is provided, only the provided ids will be refreshed
  Future<List<Server>> refreshDevices({
    bool startup = false,
    Iterable<String>? ids,
  }) async {
    final replacehold = <String, Server>{};
    await Future.wait(servers.map((target) async {
      if (ids != null && !ids.contains(target.id)) return;
      if (startup && !target.additionalSettings.connectAutomaticallyAtStartup) {
        target.devices.clear();
        target.online = false;
        return;
      }

      if (!loadingServer.contains(target.id)) {
        loadingServer.add(target.id);
        notifyListeners();
      }

      var (_, server) = await API.instance.checkServerCredentials(target);
      final devices = await API.instance.getDevices(server);
      if (devices != null) {
        debugPrint(devices.length.toString());
        replacehold[target.id] = server;
      }

      if (loadingServer.contains(server.id)) {
        loadingServer.remove(server.id);
        notifyListeners();
      }
    }));

    for (final entry in replacehold.entries) {
      final server = entry.value;
      final index = servers.indexWhere((s) => s.id == server.id);
      servers[index] = server;
    }

    await save();

    return servers;
  }

  Future<void> disconnectServer(Server server) async {
    final index = servers.indexWhere((s) => s.id == server.id);
    if (index == -1) return;

    final s = servers[index].copyWith(
      devices: [],
      online: false,
    );
    servers[index] = s;

    await save();
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    await write({
      kStorageServers: jsonEncode(
        servers.map((server) => server.toJson()).toList(),
      ),
    });
    super.save(notifyListeners: notifyListeners);
  }

  /// Restore currently added [Server]s from `package:hive` cache.
  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await secureStorage.read(key: kStorageServers);
    final serversData = data == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await compute(jsonDecode, data) as List,
          );
    servers = serversData.map<Server>(Server.fromJson).toList();
    super.restore(notifyListeners: notifyListeners);
  }
}
