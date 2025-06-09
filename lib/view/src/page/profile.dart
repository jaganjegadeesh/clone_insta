import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clone_insta/theme/src/theme.dart';
import 'package:clone_insta/view/src/components/bottom_bar.dart';
import 'package:clone_insta/view/src/constant/const.dart';
import 'package:clone_insta/view/src/model/auth.dart';
import 'package:clone_insta/view/src/model/user.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // ignore: non_constant_identifier_names
  final List<Map<String, String>> _user_posts = [];
  // ignore: non_constant_identifier_names
  final List<Map<String, String>> _user_reels = [];
  // ignore: non_constant_identifier_names
  String src_url = "";
  // ignore: non_constant_identifier_names
  Map<String, String>? user_data;
  UserModel? user;
  final List<VideoPlayerController?> _videoControllers = [];
  final List<VideoPlayerController?> _reelsControllers = [];

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  @override
  void dispose() {
    for (var controller in _videoControllers) {
      controller?.dispose();
    }
    // ignore: non_constant_identifier_names
    for (var reels_controller in _reelsControllers) {
      reels_controller?.dispose();
    }
    super.dispose();
  }

  Future<void> fetchItems() async {
    user_data = await Db.getData();
    user = UserModel.fromJson(user_data!);
    setState(() {}); // Update user data display

    // Fetch posts
    final url = Uri.parse(
        "${Constants.url}image_post.php?all_post=1&user_id=${user!.id}");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _user_posts.clear();
        _videoControllers.clear();
        List<Future<void>> initFutures = [];

        for (var item in data) {
          _user_posts.add({
            "type": item['type'] ?? '',
            "media": item['media'] ?? '',
          });

          if (item['type'] == 'video') {
            // ignore: deprecated_member_use
            final controller = VideoPlayerController.network(
              "${Constants.url}${item['media']}",
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            );

            _videoControllers.add(controller);
            initFutures.add(controller.initialize().then((_) {
              controller.setLooping(true);
              controller.setVolume(0);
              controller.play();

              controller.addListener(() {
                if (controller.value.isInitialized) {
                  setState(() {}); // Refresh UI when video is ready
                }
              });
            }));
          } else {
            _videoControllers.add(null); // for image posts
          }
        }

        await Future.wait(initFutures);
        setState(
            () {}); // Refresh UI after all posts' video controllers initialized
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }

    // Fetch reels
    final url1 = Uri.parse(
        "${Constants.url}image_post.php?all_reels=1&user_id=${user!.id}");
    try {
      final response = await http.get(url1);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _user_reels.clear();
        _reelsControllers.clear();
        List<Future<void>> reelsInitFutures = [];

        for (var item in data) {
          _user_reels.add({"media": item['media'] ?? ''});
          // ignore: deprecated_member_use
          final reelsController = VideoPlayerController.network(
            "${Constants.url}${item['media']}",
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );

          _reelsControllers.add(reelsController);
          reelsInitFutures.add(
            reelsController.initialize().then((_) {
              reelsController.setLooping(true);
              reelsController.setVolume(0);
              reelsController.play();
              reelsController.addListener(() {
                if (reelsController.value.isInitialized) setState(() {});
              });
            }).catchError((e) {
              debugPrint('Reel video failed to initialize: $e');
            }),
          );
        }

        await Future.wait(reelsInitFutures);
        setState(() {
          src_url = Constants.url; // Update base URL after reels
        });
      }
    } catch (e) {
      debugPrint('Error fetching reels: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appTheme.primaryColor,
      body: ListView(
        children: [
          SafeArea(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Text(
                    user?.name ?? "Instagrams",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.appTheme.indicatorColor,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.squarePlus,
                      color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.bars, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20, left: 40),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(user?.imageUrl != null
                              ? "${Constants.url}${user?.imageUrl}"
                              : 'https://via.placeholder.com/150'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 10),
                              CircleAvatar(
                                radius: 8,
                                backgroundColor:
                                    AppTheme.appTheme.indicatorColor,
                                child: Icon(Icons.add,
                                    size: 15,
                                    color: AppTheme.appTheme.primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0, top: 8.0),
                    child: Text(
                      user?.name ?? 'Your Name',
                      style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.appTheme.indicatorColor),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    _user_posts.length < 10
                        ? "0${_user_posts.length}"
                        : _user_posts.length.toString(),
                    style: TextStyle(
                        fontSize: 20,
                        color: AppTheme.appTheme.indicatorColor,
                        fontWeight: FontWeight.bold),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 10.0, top: 8.0),
                    child: Text("Posts",
                        style: TextStyle(fontSize: 15, color: Colors.white)),
                  )
                ],
              ),
              const SizedBox(width: 20),
              const Column(
                children: [
                  Text("9999",
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0, top: 8.0),
                    child: Text("Followers",
                        style: TextStyle(fontSize: 15, color: Colors.white)),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'This is your bio or description. You can write something about yourself here.',
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      backgroundColor: AppTheme.appTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    child: const Text("Edit Profile",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      backgroundColor: AppTheme.appTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    child: const Text("Share Profile",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 5),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    backgroundColor: AppTheme.appTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  child:
                      const Icon(Icons.person_add_alt_1, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.video_library)),
                  ],
                ),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    children: [
                      _user_posts.isEmpty ||
                              _videoControllers.length != _user_posts.length
                          ? const Center(child: CircularProgressIndicator())
                          : GridView.builder(
                              itemCount: _user_posts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                              itemBuilder: (context, index) {
                                final post = _user_posts[index];
                                final type = post['type'];
                                final mediaUrl = "$src_url${post['media']}";

                                return AspectRatio(
                                  aspectRatio: 1,
                                  child: type == 'video'
                                      ? (_videoControllers[index] != null &&
                                              _videoControllers[index]!
                                                  .value
                                                  .isInitialized
                                          ? VideoPlayer(
                                              _videoControllers[index]!)
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator()))
                                      : Container(
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: CachedNetworkImageProvider(mediaUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                );
                              }),
                      _user_reels.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: GridView.builder(
                                itemCount: _reelsControllers.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                  childAspectRatio:
                                      0.5,
                                ),
                                itemBuilder: (context, index) {
                                  return _reelsControllers[index] != null &&
                                          _reelsControllers[index]!
                                              .value
                                              .isInitialized
                                      ? VideoPlayer(_reelsControllers[index]!)
                                      : const Center(
                                          child: CircularProgressIndicator());
                                },
                              ),
                            )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        user?.imageUrl ?? '',
        profile: user?.imageUrl != null
            ? "${Constants.url}${user?.imageUrl}"
            : "https://via.placeholder.com/150",
      ),
    );
  }
}
