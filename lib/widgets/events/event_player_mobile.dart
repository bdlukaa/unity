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

part of 'events_screen.dart';

class EventPlayerScreen extends StatelessWidget {
  final Event event;

  const EventPlayerScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return EventPlayerDesktop(event: event);
    } else {
      return _EventPlayerMobile(event: event);
    }
  }
}

class _EventPlayerMobile extends StatefulWidget {
  final Event event;

  const _EventPlayerMobile({Key? key, required this.event}) : super(key: key);

  @override
  State<_EventPlayerMobile> createState() => __EventPlayerMobileState();
}

class __EventPlayerMobileState extends State<_EventPlayerMobile> {
  final videoController = UnityVideoPlayer.create();

  @override
  void initState() {
    super.initState();
    debugPrint(widget.event.mediaURL.toString());
    videoController.setDataSource(
      widget.event.mediaURL.toString(),
      autoPlay: true,
    );
  }

  @override
  void dispose() {
    videoController.release();
    videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: Text(widget.event.deviceName)),
      body: Column(children: [
        const WindowButtons(),
        Expanded(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: UnityVideoView(
              player: videoController,
              fit: UnityVideoFit.contain,
              paneBuilder: (context, controller) {
                if (isDesktop) {
                  return _DesktopVideoViewport(
                    event: widget.event,
                    player: controller,
                  );
                } else {
                  return VideoViewport(player: controller);
                }
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class VideoViewport extends StatefulWidget {
  final UnityVideoPlayer player;

  const VideoViewport({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  _VideoViewportState createState() => _VideoViewportState();
}

class _VideoViewportState extends State<VideoViewport> {
  UnityVideoPlayer get player => widget.player;

  Duration position = Duration.zero;
  bool visible = true;
  Timer timer = Timer(Duration.zero, () {});

  @override
  void initState() {
    super.initState();
    // Set class attributes to match the current [FijkPlayer]'s state.
    position = widget.player.currentPos;
    widget.player.onCurrentPosUpdate.listen(currentPosListener);
    widget.player.onBufferStateUpdate.listen(bufferStateListener);
    timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          visible = false;
        });
      }
    });
  }

  void currentPosListener(Duration event) {
    if (mounted) {
      setState(() {
        position = event;
        // Deal with the [seekTo] condition inside the [Slider] [Widget] callback.
        // if (state == FijkState.idle) {
        //   state = FijkState.started;
        // }
      });
    }
  }

  void bufferStateListener(bool event) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (!visible) {
                  setState(() {
                    visible = true;
                  });
                  if (timer.isActive) timer.cancel();
                  timer = Timer(const Duration(seconds: 5), () {
                    setState(() {
                      visible = false;
                    });
                  });
                } else {
                  setState(() {
                    visible = false;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: visible
                      ? const LinearGradient(
                          stops: [
                            1.0,
                            0.8,
                            0.0,
                            0.8,
                            1.0,
                          ],
                          colors: [
                            Colors.black38,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black38,
                          ],
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (visible || player.isBuffering) ...[
            PositionedDirectional(
              top: 0.0,
              bottom: 0.0,
              start: 0.0,
              end: 0.0,
              child: () {
                if (player.error != null) {
                  return ErrorWarning(message: player.error!);
                } else if (player.isBuffering) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                } else {
                  return GestureDetector(
                    child: Icon(
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      shadows: const <Shadow>[
                        BoxShadow(
                            color: Colors.black54,
                            blurRadius: 15.0,
                            offset: Offset(0.0, 0.75)),
                      ],
                      size: 56.0,
                    ),
                    onTap: () {
                      if (player.isPlaying) {
                        widget.player.pause();
                      } else {
                        widget.player.start();
                      }
                    },
                  );
                }
              }(),
            ),
            if (player.duration != Duration.zero)
              PositionedDirectional(
                bottom: 0.0,
                start: 0.0,
                end: 0.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 16.0),
                    Container(
                      alignment: AlignmentDirectional.centerEnd,
                      height: 36.0,
                      child: Text(
                        player.currentPos.label,
                        style: Theme.of(context)
                            .textTheme
                            .headline4
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12.0),
                          overlayColor:
                              Theme.of(context).primaryColor.withOpacity(0.4),
                          thumbColor: Theme.of(context).primaryColor,
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor:
                              Theme.of(context).primaryColor.withOpacity(0.5),
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0,
                          ),
                        ),
                        child: Transform.translate(
                          offset: const Offset(0, 0.8),
                          child: Slider(
                            value: position.inMilliseconds.toDouble(),
                            min: 0.0,
                            max: player.duration.inMilliseconds.toDouble(),
                            onChanged: (value) async {
                              // setState(() {
                              //   state = FijkState.idle;
                              // });
                              position = Duration(milliseconds: value.toInt());
                              await player.seekTo(position);
                              await player.start();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      alignment: AlignmentDirectional.centerStart,
                      height: 36.0,
                      child: Text(
                        player.duration.label,
                        style: Theme.of(context)
                            .textTheme
                            .headline4
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // TODO: fullscreen. unity_video_player currently doesn't provide an
                    // interface for full screen handling
                    // IconButton(
                    //   padding: EdgeInsets.zero,
                    //   icon: Icon(
                    //     false
                    //         // widget.player.isFullScreen
                    //         ? Icons.fullscreen_exit
                    //         : Icons.fullscreen,
                    //     color: Colors.white,
                    //   ),
                    //   onPressed: () {
                    //     // if (widget.player.value.fullScreen) {
                    //     //   player.exitFullScreen();
                    //     // } else {
                    //     //   player.enterFullScreen();
                    //     // }
                    //   },
                    // ),
                    // const SizedBox(width: 8.0),
                  ],
                ),
              ),
          ],
        ]),
      ),
    );
  }

  @override
  void dispose() {
    // player.removeListener(listener);

    super.dispose();
  }
}

class _DesktopVideoViewport extends StatefulWidget {
  final Event event;
  final UnityVideoPlayer player;

  const _DesktopVideoViewport({
    Key? key,
    required this.event,
    required this.player,
  }) : super(key: key);

  @override
  State<_DesktopVideoViewport> createState() => __DesktopVideoViewportState();
}

class __DesktopVideoViewportState extends State<_DesktopVideoViewport> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Stack(children: [
      PositionedDirectional(
        bottom: 0,
        start: 12.0,
        end: 12.0,
        child: Row(children: [
          Text(settings.timeFormat.format(widget.event.published)),
          Expanded(
            child: Slider(
              value: widget.player.currentPos.inMilliseconds.toDouble(),
              min: 0,
              max: widget.player.duration.inMilliseconds.toDouble(),
              onChanged: (v) {
                widget.player.seekTo(Duration(milliseconds: v.toInt()));
              },
            ),
          ),
          Text(
            settings.timeFormat.format(
              widget.event.published
                  .add(widget.event.mediaDuration ?? Duration.zero),
            ),
          ),
        ]),
      ),
    ]);
  }
}