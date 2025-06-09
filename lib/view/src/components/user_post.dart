import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:clone_insta/view/src/constant/const.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:uuid/uuid.dart';

class UserPost extends StatefulWidget {
  final int index;
  final bool liked;
  final bool showHeart;
  final VoidCallback onDoubleTap;
  final String name;
  final String media;
  final String profile;
  final String caption;
  final String type; // "image" or "video"

  const UserPost({
    super.key,
    required this.index,
    required this.liked,
    required this.showHeart,
    required this.onDoubleTap,
    required this.name,
    required this.caption,
    required this.type,
    required this.profile,
    required this.media,
  });

  @override
  State<UserPost> createState() => _UserPostState();
}

class _UserPostState extends State<UserPost> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isMuted = true;
  final String _visibilityKey = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    if (widget.type == "video") {
      // ignore: deprecated_member_use
      _videoController = VideoPlayerController.network(widget.media);
      _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
        setState(() {});
        _videoController!.setLooping(true);
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _handleVisibility(double visibleFraction) {
    if (_videoController == null) return;

    if (visibleFraction >= 0.7) {
      // Visible: play
      if (!_videoController!.value.isPlaying) {
        _videoController!.play();
      }
    } else {
      // Not visible: pause
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: VisibilityDetector(
        key: Key(_visibilityKey),
        onVisibilityChanged: (info) {
          final visibleFraction = info.visibleFraction;
          _handleVisibility(visibleFraction);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              width: double.infinity,
              child: widget.type == "image"
                  ? Container(
                      height: 400,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(widget.media),
                          fit: BoxFit.cover,
                          colorFilter: const ColorFilter.mode(
                            Colors.black38,
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: _buildHeaderOverlay(),
                    )
                  : _videoController != null
                      ? FutureBuilder(
                          future: _initializeVideoPlayerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final aspectRatio =
                                      _videoController!.value.aspectRatio;
                                  final height =
                                      constraints.maxWidth / aspectRatio;

                                  return SizedBox(
                                    height: height,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        VideoPlayer(_videoController!),
                                        Container(
                                          color: Colors.black38,
                                          child: _buildHeaderOverlay(),
                                        ),
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: IconButton(
                                            icon: Icon(
                                              _isMuted
                                                  ? Icons.volume_off
                                                  : Icons.volume_up,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                            onPressed: _toggleMute,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } else {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                          },
                        )
                      : const Center(child: CircularProgressIndicator()),
            ),
            AnimatedOpacity(
              opacity: widget.showHeart ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 150,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderOverlay() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  backgroundImage: widget.profile != ''
                      ? CachedNetworkImageProvider(Constants.url + widget.profile)
                      : const AssetImage("asset/images/zoro.jpg")
                          as ImageProvider,
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    widget.caption,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
