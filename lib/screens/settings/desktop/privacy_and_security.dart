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

import 'package:bluecherry_client/screens/settings/desktop/settings.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:flutter/material.dart';

class PrivacySecuritySettings extends StatelessWidget {
  const PrivacySecuritySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(children: [
      CheckboxListTile.adaptive(
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.crop),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: const Text('Use data'),
        subtitle: const Text(
          'Allow Bluecherry to collect data to improve the app and provide '
          'better services. Data is collected anonymously and does not contain '
          'any personal information.',
        ),
        isThreeLine: true,
        value: true,
        onChanged: (value) {},
      ),
      OptionsChooserTile(
        title: 'Automatically report errors',
        icon: Icons.error,
        value: 'On',
        values: ['On', 'Ask', 'Error'].map((e) => Option(text: e, value: e)),
        onChanged: (v) {},
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.privacy_tip),
        title: const Text('Privacy Policy'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
      ListTile(
        leading: const Icon(Icons.policy),
        title: const Text('Terms of Service'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    ]);
  }
}
