import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clone_insta/view/src/constant/const.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StoryRoom extends StatefulWidget {
  // ignore: non_constant_identifier_names
  final int CIndex; // Initial story index
  // ignore: non_constant_identifier_names
  final List<Map<String, dynamic>> AllStory;

  const StoryRoom({
    super.key,
    // ignore: non_constant_identifier_names
    required this.CIndex,
    // ignore: non_constant_identifier_names
    required this.AllStory,
  });

  @override
  State<StoryRoom> createState() => _StoryRoomState();
}

class _StoryRoomState extends State<StoryRoom> {
  late final PageController _pageController;
  // ignore: unused_field
  late int _currentStoryIndex;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.CIndex;
    _pageController = PageController(initialPage: widget.CIndex);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentStoryIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.AllStory.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return StoryPlayer(
            story: widget.AllStory[index],
            onStoryFinished: () {
              if (index + 1 < widget.AllStory.length) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              } else {
                Navigator.pop(context);
              }
            },
          );
        },
      ),
    );
  }
}

class StoryPlayer extends StatefulWidget {
  final Map<String, dynamic> story;
  final VoidCallback onStoryFinished;

  const StoryPlayer({
    super.key,
    required this.story,
    required this.onStoryFinished,
  });

  @override
  State<StoryPlayer> createState() => _StoryPlayerState();
}

class _StoryPlayerState extends State<StoryPlayer> {
  late final List<Map<String, String>> clips;
  final List<VideoPlayerController?> _controllers = [];
  int _currentClip = 0;
  bool _isLoading = true;
  Timer? _imageTimer;

  @override
  void initState() {
    super.initState();
    clips = List<Map<String, String>>.from(widget.story['media']);
    _initClips();
  }

  Future<void> _initClips() async {
    for (final media in clips) {
      if (media.containsKey('video')) {
        // ignore: deprecated_member_use
        final ctrl = VideoPlayerController.network(Constants.url + media['video']!);
        try {
          await ctrl.initialize();
        } catch (e) {
          debugPrint('Video failed to load: $e');
        }
        ctrl.setLooping(false);
        ctrl.addListener(() => _videoListener(ctrl));
        _controllers.add(ctrl);
      } else {
        _controllers.add(null); // For images
      }
    }

    _playCurrent();
    setState(() {
      _isLoading = false;
    });
  }

  void _playCurrent() {
    final ctrl = _controllers[_currentClip];
    if (ctrl != null) {
      ctrl.play();
    } else {
      _imageTimer?.cancel();
      _imageTimer = Timer(const Duration(seconds: 5), _nextClip);
    }
  }

  void _videoListener(VideoPlayerController ctrl) {
    if (!mounted) return;
    if (ctrl.value.position >= ctrl.value.duration) {
      _nextClip();
    } else {
      setState(() {}); // to update progress bar
    }
  }

  void _nextClip() {
    if (!mounted) return;
    _stopCurrent();
    if (_currentClip + 1 < clips.length) {
      setState(() {
        _currentClip++;
      });
      _playCurrent();
    } else {
      widget.onStoryFinished();
    }
  }

  void _stopCurrent() {
    _imageTimer?.cancel();
    final ctrl = _controllers[_currentClip];
    if (ctrl != null) {
      ctrl.pause();
      ctrl.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers) {
      ctrl?.dispose();
    }
    _imageTimer?.cancel();
    super.dispose();
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 40,
      left: 10,
      right: 10,
      child: Row(
        children: clips.asMap().entries.map((entry) {
          final idx = entry.key;
          double progress = 0.0;

          if (idx < _currentClip) {
            progress = 1.0;
          } else if (idx == _currentClip) {
            final ctrl = _controllers[_currentClip];
            if (ctrl != null) {
              if (ctrl.value.isInitialized &&
                  ctrl.value.duration.inMilliseconds > 0) {
                progress = ctrl.value.position.inMilliseconds /
                    ctrl.value.duration.inMilliseconds;
              }
            } else {
              // For image, approximate progress
              progress =
                  0.5; // You can enhance this with a custom animation if desired
            }
          }

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final media = clips[_currentClip];
    final ctrl = _controllers[_currentClip];

    return GestureDetector(
      onTap: _nextClip,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ctrl != null && ctrl.value.isInitialized)
            FittedBox(
              fit: ctrl.value.size.height >= MediaQuery.of(context).size.height
                  ? BoxFit.cover
                  : BoxFit.contain,
              child: SizedBox(
                width: ctrl.value.size.width,
                height: ctrl.value.size.height,
                child: VideoPlayer(ctrl),
              ),
            )
          else if (media.containsKey('image'))
            CachedNetworkImage(
              imageUrl: Constants.url + media['image']!,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error, color: Colors.white)),
            ),
          _buildProgressBar(),
          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(Constants.url + widget.story["profile"]),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.story["name"] ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
