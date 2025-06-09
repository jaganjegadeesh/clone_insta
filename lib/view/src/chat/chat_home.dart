import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clone_insta/theme/src/theme.dart';
import 'package:clone_insta/theme/theme.dart';
import 'package:clone_insta/view/src/chat/chat_room.dart';
import 'package:clone_insta/view/src/constant/const.dart';
import 'package:clone_insta/view/src/model/auth.dart';
import 'package:clone_insta/view/src/model/user.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class ChatHome extends StatefulWidget {
  const ChatHome({super.key});

  @override
  State<ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  bool _isLoading = true;
  bool _isSearchLoading = false;
  String search = "";
  UserModel? user;
    // ignore: non_constant_identifier_names
  Map<String, String>? user_data;
  // ignore: non_constant_identifier_names
  String src_url = "";
  // ignore: non_constant_identifier_names
  final List<Map<String, String>> search_friends = [];
  final List<Map<String, String>> friends = [];



  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    user_data = await Db.getData();
    user = UserModel.fromJson(user_data!);
    final url = Uri.parse('${Constants.url}insta_chat.php?all_users=&my_id=${user!.id}');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print(response.body);
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          src_url = Constants.url;
          for (var item in data) {
            friends.add({
              "id": item['id'] ?? '',
              "name": item['name'] ?? '',
              "profile": item['profile'] ?? '',
            });
          }
          // ignore: avoid_print
          print("friends URLs: $friends");
        }
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
    setState(() {
      user = user;
      _isLoading = false;
    });
  }

  Future<void> searchMyFriends(String value) async {
    setState(() {
      _isSearchLoading = true;
    });
    final url =
        Uri.parse('${Constants.url}insta_chat.php?search_friends=$value');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          src_url = Constants.url;
          for (var item in data) {
            search_friends.add({
              "id": item['id'] ?? '',
              "name": item['name'] ?? '',
              "profile": item['profile'] ?? '',
            });
          }
          // ignore: avoid_print
          print("friends URLs: $search_friends");
          setState(() {
            _isSearchLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      setState(() {
        _isSearchLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat Box",
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.appTheme.indicatorColor),
      ),
      body: Container(
        decoration: BoxDecoration(color: AppTheme.appTheme.primaryColor),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
                onChanged: (value) {
                  setState(() {
                    search = value;
                    searchMyFriends(value);
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search By Name',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: LoadingAnimationWidget.twistingDots(
                        leftDotColor: const Color.fromARGB(255, 188, 188, 228),
                        rightDotColor: const Color(0xFFEA3799),
                        size: 50,
                      ),
                    )
                  : friends.isEmpty
                      ? Center(
                          child: Text(
                            "No chat data available",
                            style: TextStyle(
                                color: AppTheme.appTheme.indicatorColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final data = friends[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 1.0,
                                horizontal: 4.0,
                              ),
                              child: Card(
                                child: ListTile(
                                  onTap: () async {
                                    var chatRoomId = Db().getchatRoomIdByUserId(
                                        user!.id,
                                        data['id']!,
                                        user!.name,
                                        data['name']!);
                                    Map<String, dynamic> chatInfoMap = {
                                      "users": [user?.id, data['id']],
                                    };
                                    await Db().createChatRoom(
                                        chatRoomId, chatInfoMap);
                                        print(chatInfoMap);
                                        print(chatRoomId);
                                    Navigator.push(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatRoom(
                                          sendUserId: data['id']!,
                                          sendName: data['name']!,
                                          sendPic: data['profile']!,
                                        ),
                                      ),
                                    );
                                  },
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(data['name'] ?? ''),
                                      Text(data['email'] ?? ''),
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundImage: data['profile'] != null
                                        ? CachedNetworkImageProvider(
                                            "${Constants.url}${data['profile']}")
                                        : const AssetImage(
                                                'asset/images/zoro.jpg')
                                            as ImageProvider,
                                  ),
                                  trailing:
                                      const Icon(Icons.play_arrow_rounded),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
