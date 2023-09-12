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

import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/device_grid/video_status_label.dart';
import 'package:bluecherry_client/widgets/downloads_manager.dart';
import 'package:bluecherry_client/widgets/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/widgets/hover_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/player/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class TimelineCard extends StatefulWidget {
  const TimelineCard({super.key, required this.tile, required this.timeline});

  final Timeline timeline;
  final TimelineTile tile;

  @override
  State<TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard> {
  UnityVideoFit? _fit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final downloadsManager = context.watch<DownloadsManager>();

    final device = widget.tile.device;
    final events = widget.tile.events;

    final currentEvent = events.firstWhereOrNull((event) {
      return event.isPlaying(widget.timeline.currentDate);
    });

    return Card(
      key: ValueKey(device),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: UnityVideoView(
        heroTag: device.streamURL,
        player: widget.tile.videoController,
        color: Colors.transparent,
        fit: _fit ?? settings.cameraViewFit,
        paneBuilder: (context, controller) {
          if (currentEvent == null) {
            return RepaintBoundary(
              child: Material(
                type: MaterialType.card,
                color: theme.colorScheme.surface,
                surfaceTintColor: theme.colorScheme.surfaceTint,
                elevation: 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(children: [
                    Text(
                      device.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    Center(
                      child: Text(
                        loc.noRecords,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }

          final isDownloaded = downloadsManager.isEventDownloaded(
            currentEvent.event.id,
          );
          final isDownloading = downloadsManager.isEventDownloading(
            currentEvent.event.id,
          );

          final video = UnityVideoView.of(context);

          return HoverButton(
            forceEnabled: true,
            margin: const EdgeInsets.all(16.0),
            builder: (_, states) => Stack(clipBehavior: Clip.none, children: [
              RichText(
                text: TextSpan(
                  text: '',
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: Colors.white,
                    shadows: outlinedText(strokeWidth: 0.75),
                  ),
                  children: [
                    TextSpan(
                      text: device.name,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: Colors.white,
                        shadows: outlinedText(strokeWidth: 0.75),
                      ),
                    ),
                    const TextSpan(text: '\n'),
                    if (states.isHovering)
                      TextSpan(
                        text: currentEvent
                            .position(widget.timeline.currentDate)
                            .humanReadableCompact(context),
                      ),
                    if (kDebugMode) ...[
                      const TextSpan(text: '\ndebug: '),
                      TextSpan(
                        text:
                            controller.currentPos.humanReadableCompact(context),
                      ),
                    ],
                  ],
                ),
              ),
              if (kDebugMode)
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Text(
                    'debug buffering: '
                    '${(widget.tile.videoController.currentBuffer.inMilliseconds / widget.tile.videoController.duration.inMilliseconds).toStringAsPrecision(2)}'
                    '\n${widget.tile.videoController.currentBuffer.humanReadableCompact(context)}',
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: Colors.white,
                      shadows: outlinedText(strokeWidth: 0.75),
                    ),
                  ),
                ),
              PositionedDirectional(
                end: 0,
                top: 0,
                height: 24.0,
                width: 24.0,
                child: () {
                  if (controller.isBuffering) {
                    return const CircularProgressIndicator.adaptive(
                      strokeWidth: 2.0,
                    );
                  }
                  if (isDownloaded || isDownloading || states.isHovering) {
                    DownloadIndicator(
                      event: currentEvent.event,
                      highlight: true,
                      small: true,
                    );
                  }
                  return const SizedBox.shrink();
                }(),
              ),
              if (states.isHovering)
                Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.labelLarge!.copyWith(
                        color: Colors.white,
                        shadows: outlinedText(strokeWidth: 0.75),
                      ),
                      children: [
                        TextSpan(text: '${loc.duration}: '),
                        TextSpan(
                            text: currentEvent.duration
                                .humanReadableCompact(context)),
                        const TextSpan(text: '\n'),
                        TextSpan(text: '${loc.eventType}: '),
                        TextSpan(
                          text: currentEvent.event.type.locale(context),
                        ),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: SizedBox(
                  height: 24.0,
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (states.isHovering) ...[
                      CameraViewFitButton(
                        fit: _fit ?? settings.cameraViewFit,
                        onChanged: (fit) => setState(() => _fit = fit),
                      ),
                      IconButton(
                        tooltip: loc.showFullscreenCamera,
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/events',
                            arguments: {'event': currentEvent.event},
                          );
                        },
                        iconSize: 18.0,
                        icon: Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          shadows: outlinedText(),
                        ),
                      )
                    ],
                    VideoStatusLabel(
                      video: video,
                      device: widget.tile.device,
                      event: currentEvent.event,
                    )
                  ]),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}