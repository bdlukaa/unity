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

part of 'settings.dart';

typedef OnRemoveServer = void Function(BuildContext, Server);

class ServersList extends StatelessWidget {
  const ServersList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final home = context.watch<HomeProvider>();
    final serversProvider = context.watch<ServersProvider>();

    return LayoutBuilder(builder: (context, consts) {
      if (consts.maxWidth >= 800) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Wrap(children: [
            ...serversProvider.servers.map((server) {
              return ServerCard(server: server, onRemoveServer: onRemoveServer);
            }),
            SizedBox(
              height: 180,
              width: 180,
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.0),
                  onTap: () => home.setTab(UnityTab.addServer.index, context),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Theme.of(context).iconTheme.color,
                          child: const Icon(Icons.add, size: 30.0),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          AppLocalizations.of(context).addNewServer,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 15.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      } else {
        return Column(children: [
          ...serversProvider.servers.map((server) {
            return ServerTile(
              server: server,
              onRemoveServer: onRemoveServer,
            );
          }),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).iconTheme.color,
              child: const Icon(Icons.add),
            ),
            title: Text(AppLocalizations.of(context).addNewServer),
            onTap: () => home.setTab(UnityTab.addServer.index, context),
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 8.0),
            child: Divider(
              height: 1.0,
              thickness: 1.0,
            ),
          ),
        ]);
      }
    });
  }

  Future<void> onRemoveServer(BuildContext context, Server server) {
    return showDialog(
      context: context,
      builder: (context) => ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300.0,
        ),
        child: AlertDialog(
          title: Text(AppLocalizations.of(context).remove),
          content: Text(
            AppLocalizations.of(context).removeServerDescription(server.name),
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.start,
          ),
          actions: [
            MaterialButton(
              onPressed: Navigator.of(context).maybePop,
              child: Text(
                AppLocalizations.of(context).no.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            MaterialButton(
              onPressed: () {
                ServersProvider.instance.remove(server);
                Navigator.of(context).maybePop();
              },
              child: Text(
                AppLocalizations.of(context).yes.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServerTile extends StatelessWidget {
  final Server server;
  final OnRemoveServer onRemoveServer;

  const ServerTile({
    Key? key,
    required this.server,
    required this.onRemoveServer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servers = context.watch<ServersProvider>();
    final isLoading = servers.isServerLoading(server);
    final loc = AppLocalizations.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        foregroundColor:
            server.online ? theme.iconTheme.color : theme.colorScheme.error,
        child: Icon(server.online ? Icons.dns : Icons.desktop_access_disabled),
      ),
      title: Text(
        server.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        !isLoading
            ? [
                if (server.name != server.ip) server.ip,
                if (server.online)
                  loc.nDevices(server.devices.length)
                else
                  loc.offline,
              ].join(' • ')
            : AppLocalizations.of(context).gettingDevices,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete,
          color: theme.colorScheme.error,
        ),
        tooltip: loc.disconnectServer,
        splashRadius: 24.0,
        onPressed: () => onRemoveServer(context, server),
      ),
      onTap: () {
        showEditServer(context, server);
      },
    );
  }
}

class ServerCard extends StatelessWidget {
  final Server server;
  final OnRemoveServer onRemoveServer;

  const ServerCard({
    Key? key,
    required this.server,
    required this.onRemoveServer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final home = context.watch<HomeProvider>();
    final servers = context.watch<ServersProvider>();

    final isLoading = servers.isServerLoading(server);

    final loc = AppLocalizations.of(context);

    return SizedBox(
      height: 180,
      width: 180,
      child: Card(
        child: Stack(children: [
          Positioned.fill(
            bottom: 8.0,
            left: 8.0,
            right: 8.0,
            top: 8.0,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.iconTheme.color,
                child: const Icon(Icons.dns, size: 30.0),
              ),
              const SizedBox(height: 8.0),
              Text(
                server.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                !isLoading
                    ? [
                        if (server.name != server.ip) server.ip,
                      ].join()
                    : loc.gettingDevices,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                !server.online
                    ? loc.offline
                    : !isLoading
                        ? loc.nDevices(server.devices.length)
                        : '',
                style: TextStyle(
                  color: !server.online ? theme.colorScheme.error : null,
                ),
              ),
              const SizedBox(height: 15.0),
              Transform.scale(
                scale: 0.9,
                child: OutlinedButton(
                  child: Text(loc.disconnectServer),
                  onPressed: () {
                    onRemoveServer(context, server);
                  },
                ),
              ),
            ]),
          ),
          PositionedDirectional(
            top: 4,
            end: 2,
            child: PopupMenuButton<Object>(
              iconSize: 20.0,
              splashRadius: 16.0,
              position: PopupMenuPosition.under,
              offset: const Offset(-128, 4.0),
              constraints: const BoxConstraints(maxWidth: 180.0),
              tooltip: loc.serverOptions,
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    child: Text(loc.editServerInfo),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        if (context.mounted) showEditServer(context, server);
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: Text(loc.disconnectServer),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        if (context.mounted) {
                          onRemoveServer(context, server);
                        }
                      });
                    },
                  ),
                  const PopupMenuDivider(height: 1.0),
                  PopupMenuItem(
                    child: Text(loc.browseEvents),
                    onTap: () {
                      home.setTab(UnityTab.eventsScreen.index, context);
                    },
                  ),
                  PopupMenuItem(
                    child: Text(loc.configureServer),
                    onTap: () {
                      launchUrl(Uri.parse(server.ip));
                    },
                  ),
                  const PopupMenuDivider(height: 1.0),
                  PopupMenuItem(
                    child: Text(loc.refreshDevices),
                    onTap: () async {
                      servers.refreshDevices([server.id]);
                    },
                  ),
                ];
              },
            ),
          ),
          if (isLoading)
            const PositionedDirectional(
              start: 10,
              top: 12,
              child: SizedBox(
                height: 18.0,
                width: 18.0,
                child: CircularProgressIndicator.adaptive(strokeWidth: 1.5),
              ),
            ),
        ]),
      ),
    );
  }
}
