// ignore_for_file: prefer_is_not_empty

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clone_insta/theme/src/theme.dart';
import 'package:clone_insta/view/src/chat/chat_home.dart';
import 'package:clone_insta/view/src/components/bottom_bar.dart';
import 'package:clone_insta/view/src/components/user_bottom_post.dart';
import 'package:clone_insta/view/src/components/user_post.dart';
import 'package:clone_insta/view/src/constant/const.dart';
import 'package:clone_insta/view/src/model/auth.dart';
import 'package:clone_insta/view/src/model/user.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_icon_class/font_awesome_icon_class.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<bool> _likedPosts = List<bool>.filled(100, false);
  final List<bool> _savedPosts = List<bool>.filled(100, false);
  final List<bool> _showHeart = List<bool>.filled(100, false);
  final List<Map<String, String>> _users = [];
  // ignore: non_constant_identifier_names
  String src_url = "";
  // ignore: non_constant_identifier_names
  Map<String, String>? user_data;
  UserModel? user;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  // List<Map<String, String>> _users = [
  //   {
  //     "name": "Alice Johnson",
  //     "image":
  //         "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Bob Smith",
  //     "image":
  //         "https://images.unsplash.com/photo-1520813792240-56fc4a3765a7?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Charlie Brown",
  //     "image":
  //         "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Diana Prince",
  //     "image":
  //         "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Ethan Hunt",
  //     "image":
  //         "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Fiona Gallagher",
  //     "image":
  //         "https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "George Martin",
  //     "image":
  //         "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Hannah Baker",
  //     "image":
  //         "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Ian Wright",
  //     "image":
  //         "https://images.unsplash.com/photo-1511367461989-f85a21fda167?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Jenna Coleman",
  //     "image":
  //         "https://images.unsplash.com/photo-1520813792240-56fc4a3765a7?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Kevin Durant",
  //     "image":
  //         "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Laura Palmer",
  //     "image":
  //         "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Michael Scott",
  //     "image":
  //         "https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Nina Dobrev",
  //     "image":
  //         "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&h=400",
  //   },
  //   {
  //     "name": "Oscar Wilde",
  //     "image":
  //         "https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?auto=format&fit=crop&w=400&h=400",
  //   },
  // ];

  Future<void> fetchItems() async {
    user_data = await Db.getData();

    user = UserModel.fromJson(user_data!);
    debugPrint("User data: ${user.toString()}");

    setState(() {
      user = user;
    });

    final url = Uri.parse("${Constants.url}image_post.php?post=all");
    debugPrint("Fetching posts from: $url");
    try {
      final response = await http.get(url);
      // print(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // ignore: avoid_print
        print("Fetched posts: $data items");
        if (!data.isEmpty) {
          setState(() {
            src_url = Constants.url;
            _users.clear();
            for (var item in data) {
              _users.add({
                "profile": item['profile'] ?? '',
                "name": item['name'] ?? '',
                "type": item['type'] ?? '',
                "caption": item['caption'] ?? '',
                "media": item['media'] ?? '',
              });
            }
          });
          // ignore: avoid_print
          print(_users);
        }
      } else {
        debugPrint('Failed to load posts: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  void _toggleLike(int index) {
    setState(() {
      _likedPosts[index] = !_likedPosts[index];
    });
  }

  void _setLike(int index, bool value) {
    setState(() {
      _likedPosts[index] = value;
      _showHeart[index] = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _showHeart[index] = false;
      });
    });
  }

  void _toggleSave(int index) {
    setState(() {
      _savedPosts[index] = !_savedPosts[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appTheme.primaryColor,
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Text(
                    "Instagram",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.appTheme.indicatorColor,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.facebookMessenger,
                      color: Colors.white),
                  onPressed: () {
                     Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatHome()),
                  );
                  },
                ),
              ],
            ),
            // Horizontal stories section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Your Profile Story
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20, left: 20),
                        child: Container(
                          width: 60,
                          height: 60,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(width: 10),
                                  CircleAvatar(
                                    radius: 8,
                                    backgroundColor:
                                        AppTheme.appTheme.indicatorColor,
                                    child: Icon(
                                      Icons.add,
                                      size: 15,
                                      color: AppTheme.appTheme.primaryColor,
                                    ),
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
                              fontSize: 12,
                              color: AppTheme.appTheme.indicatorColor),
                        ),
                      )
                    ],
                  ),

                  // Other User Stories
                  Row(
                    children: List.generate(
                      _users.length,
                      (i) => Column(
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(_users[i]['image'] ??
                                        'https://via.placeholder.com/150'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 15.0, top: 8.0),
                            child: Text(
                              _users[i]['name'] ?? 'User ${i + 1}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.appTheme.indicatorColor),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Posts list
            ...List.generate(
              _users.length,
              (i) => Column(
                children: [
                  UserPost(
                    index: i,
                    liked: _likedPosts[i],
                    showHeart: _showHeart[i],
                    profile: _users[i]['profile'] ?? '',
                    name: _users[i]['name'] ?? 'User ${i + 1}',
                    caption: _users[i]['caption'] ?? 'caption ${i + 1}',
                    type: _users[i]['type'] ?? 'image',
                    media: _users[i]['media'] != null
                        ? "$src_url${_users[i]['media']}"
                        : 'asset/images/zoro.jpg',
                    onDoubleTap: () => _setLike(i, true),
                  ),
                  const SizedBox(height: 15),
                  UserBottomPost(
                    index: i,
                    liked: _likedPosts[i],
                    saved: _savedPosts[i],
                    onLike: () => _toggleLike(i),
                    onSave: () => _toggleSave(i),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),

            // Footer Text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome to the Home Page',
                style: TextStyle(
                  color: AppTheme.appTheme.indicatorColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        user?.imageUrl != null ? "${user?.imageUrl}" : '',
        profile: user?.imageUrl != null
            ? "${Constants.url}${user?.imageUrl}"
            : "https://via.placeholder.com/150",
      ),
    );
  }
}
