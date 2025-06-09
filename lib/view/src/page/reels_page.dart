import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clone_insta/theme/src/theme.dart';
import 'package:clone_insta/view/src/components/bottom_bar.dart';
import 'package:clone_insta/view/src/components/expend_text.dart';
import 'package:clone_insta/view/src/components/scroll_text.dart';
import 'package:clone_insta/view/src/constant/const.dart';
import 'package:clone_insta/view/src/model/auth.dart';
import 'package:clone_insta/view/src/model/user.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_icon_class/font_awesome_icon_class.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class InstaReels extends StatefulWidget {
  const InstaReels({super.key});

  @override
  State<InstaReels> createState() => _InstaReelsState();
}

class _InstaReelsState extends State<InstaReels> with WidgetsBindingObserver {
  // ignore: non_constant_identifier_names
  Map<String, String>? user_data;
  UserModel? user;
  // ignore: non_constant_identifier_names
  String src_url = "";
  final List<Map<String, String>> videoUrls = [];
  final List<VideoPlayerController?> _controllers = [];
  int _currentIndex = 0;
  bool _showHeart = false;
  static final List<bool> _likedPosts = List<bool>.filled(100, false);
  static final List<bool> _savedPosts = List<bool>.filled(100, false);
  static final List<bool> _followUser = List<bool>.filled(100, false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchItems();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _controllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  Future<void> fetchItems() async {
    user_data = await Db.getData();
    user = UserModel.fromJson(user_data!);

    final url = Uri.parse("${Constants.url}image_post.php?reels=1");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          src_url = Constants.url;
          videoUrls.clear();
          for (var item in data) {
            videoUrls.add({
              "url": item['url'] ?? '',
              "name": item['name'] ?? '',
              "caption": item['caption'] ?? '',
              "profile": item['profile'] ?? '',
            });
          }
          // ignore: avoid_print
          print("Video URLs: $videoUrls");
          await _initializeVideos();
        }
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  Future<void> _initializeVideos() async {
    _controllers.clear();
    for (var video in videoUrls) {
      try {
        final controller =
            // ignore: deprecated_member_use
            VideoPlayerController.network(src_url + video["url"]!);
        await controller.initialize();
        controller.setLooping(true);
        _controllers.add(controller);
      } catch (e) {
        _controllers.add(null);
      }
    }
    if (_controllers[_currentIndex] != null) {
      _controllers[_currentIndex]!.play();
    }
    setState(() {});
  }

  void _onPageChanged(int index) {
    if (index != _currentIndex) {
      if (_controllers[_currentIndex] != null) {
        _controllers[_currentIndex]!.pause();
      }
      if (_controllers[index] != null) {
        _controllers[index]!.play();
      }
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controllers.length != videoUrls.length
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: videoUrls.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final controller = _controllers[index];
                return Stack(fit: StackFit.expand, children: [
                  controller != null && controller.value.isInitialized
                      ? FittedBox(
                          fit: controller.value.size.height >=
                                  MediaQuery.of(context).size.height
                              ? BoxFit.cover
                              : BoxFit.contain,
                          child: SizedBox(
                            width: controller.value.size.width,
                            height: controller.value.size.height,
                            child: VideoPlayer(controller),
                          ),
                        )
                      : Container(color: Colors.black),
                  GestureDetector(
                    onDoubleTap: () {
                      setState(() {
                        _likedPosts[index] = true;
                        _showHeart = true;
                      });
                      Future.delayed(const Duration(milliseconds: 800), () {
                        setState(() {
                          _showHeart = false;
                        });
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          color: Colors.black45,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_ios,
                                        color: Colors.white, size: 20),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildActionButton(Icons.favorite,
                                      _likedPosts[index], Colors.red, () {
                                    setState(() => _likedPosts[index] =
                                        !_likedPosts[index]);
                                  }),
                                  _buildActionButton(Icons.bookmark,
                                      _savedPosts[index], Colors.blue, () {
                                    setState(() => _savedPosts[index] =
                                        !_savedPosts[index]);
                                  }),
                                  _buildIconLabel(
                                      FontAwesomeIcons.comment, "100K"),
                                  _buildIconLabel(
                                      FontAwesomeIcons.paperPlane, "100K"),
                                  _buildProfileRow(index),
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 20.0, top: 10),
                                    child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: ExpandableText(
                                            size: 12,
                                            text:
                                                "Wrap the entire scrollable content if you have to say something long")),
                                  ),
                                  const SizedBox(height: 15),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: _showHeart ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(Icons.favorite,
                              color: Colors.red, size: 150),
                        ),
                      ],
                    ),
                  ),
                ]);
              },
            ),
      bottomNavigationBar: BottomBar(
        user?.imageUrl != null ? "${user?.imageUrl}" : '',
        profile: user?.imageUrl != null
            ? "${Constants.url}${user?.imageUrl}"
            : "https://via.placeholder.com/150",
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, bool active, Color activeColor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Icon(icon,
                color: active ? activeColor : AppTheme.appTheme.indicatorColor,
                size: 20),
          ),
          const Text("100K",
              style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProfileRow(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: (videoUrls[index]['profile'] ?? '').isNotEmpty
                  ? CachedNetworkImageProvider(
                      src_url + videoUrls[index]['profile']!)
                  : const AssetImage("asset/images/zoro.jpg"),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    (videoUrls[index]['name'] ?? '').isNotEmpty
                        ? videoUrls[index]['name']!
                        : "Profile",
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                ScrollingText(
                  text: (videoUrls[index]['caption'] ?? '').isNotEmpty
                      ? videoUrls[index]['caption']!
                      : "Wrap the entire scrollable content...",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            TextButton(
              onPressed: () =>
                  setState(() => _followUser[index] = !_followUser[index]),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: _followUser[index] ? Colors.blue : Colors.grey,
                      width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _followUser[index] ? "Following" : "Follow",
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
        IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {}),
      ],
    );
  }
}
