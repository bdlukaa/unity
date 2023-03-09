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

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DirectCameraScreen extends StatefulWidget {
  const DirectCameraScreen({Key? key}) : super(key: key);

  @override
  State<DirectCameraScreen> createState() => _DirectCameraScreenState();
}

class _DirectCameraScreenState extends State<DirectCameraScreen> {
  @override
  Widget build(BuildContext context) {
    final serversProviders = context.watch<ServersProvider>();

    return Scaffold(
      appBar: showIf(
        isMobile,
        child: AppBar(
          leading: Scaffold.of(context).hasDrawer
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  splashRadius: 20.0,
                  onPressed: Scaffold.of(context).openDrawer,
                )
              : null,
          title: Text(AppLocalizations.of(context).directCamera),
        ),
      ),
      body: () {
        if (serversProviders.servers.isEmpty) {
          return const NoServerWarning();
        } else {
          return RefreshIndicator(
            onRefresh: serversProviders.refreshDevices,
            child: ListView.builder(
              padding: MediaQuery.viewPaddingOf(context),
              itemCount: serversProviders.servers.length,
              itemBuilder: (context, i) {
                final server = serversProviders.servers[i];
                return _DevicesForServer(server: server);
              },
            ),
          );
        }
      }(),
    );
  }
}

class _DevicesForServer extends StatelessWidget {
  final Server server;

  const _DevicesForServer({Key? key, required this.server}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servers = context.watch<ServersProvider>();

    final isLoading = servers.isServerLoading(server);

    final serverIndicator = SubHeader(
      server.name,
      subtext: server.online
          ? AppLocalizations.of(context).nDevices(
              server.devices.length,
            )
          : AppLocalizations.of(context).offline,
      subtextStyle: TextStyle(
        color: !server.online ? theme.colorScheme.error : null,
      ),
      trailing: isLoading
          ? const SizedBox(
              height: 16.0,
              width: 16.0,
              child: CircularProgressIndicator.adaptive(strokeWidth: 1.5),
            )
          : null,
    );

    if (isLoading || !server.online) return serverIndicator;

    if (server.devices.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        serverIndicator,
        SizedBox(
          height: 72.0,
          child: Center(
            child: Text(
              AppLocalizations.of(context).noDevices,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 16.0),
            ),
          ),
        ),
      ]);
    }

    final devices = server.devices.sorted();
    return LayoutBuilder(builder: (context, consts) {
      if (consts.maxWidth >= 800) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          serverIndicator,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Wrap(
              children: devices.map<Widget>((device) {
                final foregroundColor = device.status
                    ? colorFromBrightness(
                        context,
                        light: Colors.green.shade400,
                        dark: Colors.green.shade100,
                      )
                    : colorFromBrightness(
                        context,
                        light: Colors.red.withOpacity(0.75),
                        dark: Colors.red.shade400,
                      );

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.0),
                    onTap: device.status ? () => onTap(context, device) : null,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: 8.0,
                        // top: 8.0,
                        // bottom: 8.0,
                      ),
                      child: Column(children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.transparent,
                              foregroundColor: foregroundColor,
                              child: const Icon(Icons.camera_alt),
                            ),
                            Text(
                              device.name,
                              style: TextStyle(
                                color: foregroundColor,
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]);
      }

      return Column(children: [
        SubHeader(server.name),
        ...devices.map((device) {
          return ListTile(
            enabled: device.status,
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).iconTheme.color,
              child: const Icon(Icons.camera_alt),
            ),
            title: Text(
              device.name.uppercaseFirst(),
            ),
            subtitle: Text([
              device.status
                  ? AppLocalizations.of(context).online
                  : AppLocalizations.of(context).offline,
              device.uri,
              '${device.resolutionX}x${device.resolutionY}',
            ].join(' • ')),
            onTap: () => onTap(context, device),
          );
        }),
      ]);
    });
  }

  Future<void> onTap(BuildContext context, Device device) async {
    final player = getVideoPlayerControllerForDevice(
      device,
    );

    await Navigator.of(context).pushNamed(
      '/fullscreen',
      arguments: {
        'device': device,
        'player': player,
      },
    );
    await player.release();
  }
}
