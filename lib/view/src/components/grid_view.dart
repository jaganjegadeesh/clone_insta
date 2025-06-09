import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GridVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const GridVideoPlayer({super.key, required this.controller});

  @override
  State<GridVideoPlayer> createState() => _GridVideoPlayerState();
}

class _GridVideoPlayerState extends State<GridVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VideoPlayer(widget.controller);
  }
}
