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

import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/servers/edit_server.dart';
import 'package:bluecherry_client/widgets/settings/desktop/date_language.dart';
import 'package:bluecherry_client/widgets/settings/mobile/update.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';
import 'package:url_launcher/url_launcher.dart';

part '../shared/server_tile.dart';
part 'date_time.dart';

class MobileSettings extends StatefulWidget {
  const MobileSettings({super.key});

  @override
  State<MobileSettings> createState() => _MobileSettingsState();
}

class _MobileSettingsState extends State<MobileSettings> {
  @override
  void initState() {
    super.initState();
    SettingsProvider.instance.reload();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final update = context.watch<UpdateManager>();
    final servers = context.watch<ServersProvider>();

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Column(children: [
          if (Scaffold.of(context).hasDrawer)
            AppBar(
              leading: MaybeUnityDrawerButton(context),
              title: Text(loc.settings),
            ),
          Expanded(
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: SubHeader(
                  loc.servers,
                  subtext: loc.nServers(servers.servers.length),
                ),
              ),
              const SliverToBoxAdapter(child: ServersList()),
              SliverToBoxAdapter(
                child: SubHeader(loc.theme, subtext: loc.themeDescription),
              ),
              SliverList.list(
                  children: ThemeMode.values.map((e) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.iconTheme.color,
                    child: Icon(switch (e) {
                      ThemeMode.system => Icons.brightness_auto,
                      ThemeMode.light => Icons.light_mode,
                      ThemeMode.dark => Icons.dark_mode,
                    }),
                  ),
                  onTap: () => settings.themeMode = e,
                  trailing: Radio(
                    value: e,
                    groupValue: settings.themeMode,
                    onChanged: (value) {
                      settings.themeMode = e;
                    },
                  ),
                  title: Text(switch (e) {
                    ThemeMode.system => loc.system,
                    ThemeMode.light => loc.light,
                    ThemeMode.dark => loc.dark,
                  }),
                  subtitle: e == ThemeMode.system
                      ? Text(switch (MediaQuery.platformBrightnessOf(context)) {
                          Brightness.dark => loc.dark,
                          Brightness.light => loc.light,
                        })
                      : null,
                );
              }).toList()),
              SliverToBoxAdapter(child: SubHeader(loc.miscellaneous)),
              SliverList.list(children: [
                CorrectedListTile(
                  iconData: Icons.notifications_paused,
                  onTap: () async {
                    if (settings.snoozedUntil.isAfter(DateTime.now())) {
                      settings.snoozedUntil =
                          SettingsProvider.defaultSnoozedUntil;
                    } else {
                      final timeOfDay = await showTimePicker(
                        context: context,
                        helpText: loc.snoozeNotificationsUntil.toUpperCase(),
                        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                        useRootNavigator: false,
                      );
                      if (timeOfDay != null) {
                        settings.snoozedUntil = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          timeOfDay.hour,
                          timeOfDay.minute,
                        );
                      }
                    }
                  },
                  title: loc.snoozeNotifications,
                  height: 72.0,
                  subtitle: settings.snoozedUntil.isAfter(DateTime.now())
                      ? loc.snoozedUntil([
                          if (settings.snoozedUntil.difference(DateTime.now()) >
                              const Duration(hours: 24))
                            settings.formatDate(settings.snoozedUntil),
                          settings.formatTime(settings.snoozedUntil),
                        ].join(' '))
                      : loc.notSnoozed,
                ),
                ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.iconTheme.color,
                    child: const Icon(Icons.beenhere_rounded),
                  ),
                  title: Text(loc.notificationClickBehavior),
                  textColor: theme.textTheme.bodyLarge?.color,
                  subtitle: Text(
                    settings.notificationClickBehavior.locale(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  children: NotificationClickBehavior.values.map((behavior) {
                    return RadioListTile(
                      contentPadding: const EdgeInsetsDirectional.only(
                        start: 68.0,
                        end: 16.0,
                      ),
                      value: behavior,
                      groupValue: settings.notificationClickBehavior,
                      onChanged: (value) {
                        settings.notificationClickBehavior = behavior;
                      },
                      secondary: Icon(behavior.icon),
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 16.0),
                        child: Text(behavior.locale(context)),
                      ),
                    );
                  }).toList(),
                ),
                ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
                    foregroundColor: theme.iconTheme.color,
                    child: const Icon(Icons.fit_screen),
                  ),
                  title: Text(loc.cameraViewFit),
                  textColor: theme.textTheme.bodyLarge?.color,
                  subtitle: Text(
                    settings.cameraViewFit.locale(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  children: UnityVideoFit.values.map((e) {
                    return RadioListTile(
                      contentPadding: const EdgeInsetsDirectional.only(
                        start: 68.0,
                        end: 16.0,
                      ),
                      value: e,
                      groupValue: settings.cameraViewFit,
                      onChanged: (_) => settings.cameraViewFit = e,
                      secondary: Icon(e.icon),
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 16.0),
                        child: Text(e.locale(context)),
                      ),
                    );
                  }).toList(),
                ),
                CorrectedListTile(
                  iconData: Icons.folder,
                  trailing: Icons.navigate_next,
                  title: loc.downloadPath,
                  subtitle: settings.downloadsDirectory,
                  height: 72.0,
                  onTap: () async {
                    final selectedDirectory =
                        await FilePicker.platform.getDirectoryPath(
                      dialogTitle: loc.downloadPath,
                      initialDirectory: settings.downloadsDirectory,
                      lockParentWindow: true,
                    );

                    if (selectedDirectory != null) {
                      settings.downloadsDirectory =
                          Directory(selectedDirectory).path;
                    }
                  },
                ),
                ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundColor: theme.iconTheme.color,
                    child: const Icon(Icons.timelapse),
                  ),
                  title: Text(loc.cycleTogglePeriod),
                  textColor: theme.textTheme.bodyLarge?.color,
                  subtitle: Text(
                    settings.layoutCyclingTogglePeriod.humanReadable(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  children: [5, 10, 30, 60, 60 * 5].map((e) {
                    final dur = Duration(seconds: e);
                    return RadioListTile(
                      value: dur,
                      groupValue: settings.layoutCyclingTogglePeriod,
                      onChanged: (value) {
                        settings.layoutCyclingTogglePeriod = dur;
                      },
                      secondary: const Icon(null),
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 16.0),
                        child: Text(dur.humanReadable(context)),
                      ),
                    );
                  }).toList(),
                ),
              ]),
              SliverToBoxAdapter(
                child: CorrectedListTile(
                  iconData: Icons.language,
                  trailing: Icons.navigate_next,
                  title: loc.dateLanguage,
                  subtitle: '${settings.dateFormat.format(DateTime.now())} '
                      '${settings.timeFormat.format(DateTime.now())}; '
                      '${LocaleNames.of(context)!.nameOf(settings.locale.toLanguageTag())}',
                  height: 80.0,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (context) {
                        return DraggableScrollableSheet(
                          expand: false,
                          maxChildSize: 0.8,
                          minChildSize: 0.8,
                          initialChildSize: 0.8,
                          builder: (context, controller) {
                            return LocalizationSettings(controller: controller);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              if (update.isUpdatingSupported) ...[
                SliverToBoxAdapter(
                  child: SubHeader(
                    loc.updates,
                    subtext: loc.runningOn(() {
                      if (Platform.isLinux) {
                        return loc.linux(update.linuxEnvironment ?? '');
                      } else if (Platform.isWindows) {
                        return loc.windows;
                      }

                      return defaultTargetPlatform.name;
                    }()),
                  ),
                ),
                const SliverToBoxAdapter(child: AppUpdateCard()),
                const SliverToBoxAdapter(child: AppUpdateOptions()),
              ],
              SliverToBoxAdapter(child: SubHeader(loc.about)),
              const SliverToBoxAdapter(child: About()),
              const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
            ]),
          ),
        ]),
      ),
    );
  }
}