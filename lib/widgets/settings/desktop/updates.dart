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

import 'dart:io' hide Link;

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/settings/desktop/settings.dart';
import 'package:bluecherry_client/widgets/settings/shared/update.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';

class UpdatesSettings extends StatelessWidget {
  const UpdatesSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return ListView(padding: DesktopSettings.verticalPadding, children: [
      if (kIsWeb) ...[
        Padding(
          padding: DesktopSettings.horizontalPadding,
          child: Text(
            'Download native app',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: DesktopSettings.horizontalPadding,
          child: Text(
            'The web version of Bluecherry Client is limited in functionality. '
            'Download the native app for the best experience, which includes: \n'
            '  •  Better video performance and resource management\n'
            '  •  Better integration with the operating system\n'
            '  •  Matrix Zoom\n',
            style: theme.textTheme.labelSmall,
          ),
        ),
        ...<(TargetPlatform platform, String link, String locale)>[
          (
            TargetPlatform.linux,
            'https://github.com/bluecherrydvr/unity/releases/download/bleeding_edge/bluecherry-linux-x86_64.deb',
            loc.linux('')
          ),
          (
            TargetPlatform.windows,
            'https://github.com/bluecherrydvr/unity/releases/download/bleeding_edge/bluecherry-windows-setup.exe',
            loc.windows
          ),
          (
            TargetPlatform.macOS,
            'https://github.com/bluecherrydvr/unity/releases/download/bleeding_edge/bluecherry-macos.7z',
            loc.macOS,
          ),
          (
            TargetPlatform.iOS,
            'https://apps.apple.com/us/app/bluecherry-mobile/id1555805139',
            loc.iOS,
          ),
          (
            TargetPlatform.android,
            'https://github.com/bluecherrydvr/unity/releases/download/bleeding_edge/bluecherry-android-arm64-v8a-release.apk',
            loc.android,
          ),
        ].where((item) => defaultTargetPlatform == item.$1).map((item) {
          return Padding(
            padding: DesktopSettings.horizontalPadding,
            child: Link(
              uri: Uri.parse(item.$2),
              builder: (context, followLink) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    onPressed: followLink,
                    child: Text(loc.downloadForPlatform(item.$3)),
                  ),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 12.0),
      ] else ...[
        Padding(
          padding: DesktopSettings.horizontalPadding,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              loc.updates,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              loc.runningOn(() {
                if (kIsWeb) {
                  return loc.web;
                } else if (Platform.isLinux) {
                  return loc.linux(UpdateManager.linuxEnvironment.name);
                } else if (Platform.isWindows) {
                  return loc.windows;
                }

                return defaultTargetPlatform.name;
              }()),
              style: theme.textTheme.labelSmall,
            ),
          ]),
        ),
        const AppUpdateCard(),
        const AppUpdateOptions(),
      ],
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text('Beta Features', style: theme.textTheme.titleMedium),
      ),
      const BetaFeatures(),
      const Divider(),
      const About(),
    ]);
  }
}

class BetaFeatures extends StatelessWidget {
  const BetaFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!kIsWeb)
        CheckboxListTile.adaptive(
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.crop),
          ),
          title: Text(loc.matrixedViewZoom),
          subtitle: Text(loc.matrixedViewZoomDescription),
          value: settings.betaMatrixedZoomEnabled,
          onChanged: (value) {
            if (value != null) {
              settings.betaMatrixedZoomEnabled = value;
            }
          },
        ),
      ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.developer_mode),
        ),
        title: const Text('Developer options'),
        subtitle:
            const Text('Most of these options are for debugging purposes'),
        children: [
          if (!kIsWeb)
            FutureBuilder(
              future: getLogFile(),
              builder: (context, snapshot) {
                return ListTile(
                  contentPadding: const EdgeInsetsDirectional.only(
                    start: 68.0,
                    end: 26.0,
                  ),
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Open log file'),
                  subtitle: Text(snapshot.data?.path ?? loc.loading),
                  trailing: const Icon(Icons.navigate_next),
                  dense: false,
                  onTap: snapshot.data == null
                      ? null
                      : () {
                          launchFileExplorer(snapshot.data!.path);
                        },
                );
              },
            ),
          CheckboxListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: 68.0,
              end: 26.0,
            ),
            secondary: const Icon(Icons.adb),
            title: const Text('Show debug info'),
            subtitle: const Text('Display useful information for debugging'),
            value: settings.showDebugInfo,
            onChanged: (v) {
              if (v != null) {
                settings.showDebugInfo = v;
              }
            },
            dense: false,
          )
        ],
      ),
    ]);
  }
}
