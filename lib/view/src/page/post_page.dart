import 'dart:convert';
import 'dart:io';

import 'package:clone_insta/view/src/constant/const.dart';
import 'package:clone_insta/view/src/model/auth.dart';
import 'package:clone_insta/view/src/model/user.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _content = TextEditingController();
  AssetEntity? _selectedMedia;
  List<AssetEntity> _mediaList = [];
  bool _isLoading = false;
  UserModel? user;
  // ignore: non_constant_identifier_names
  Map<String, String>? user_data;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    user_data = await Db.getData();
    user = UserModel.fromJson(user_data!);
    setState(() {
      user = user;
    });

    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (!ps.hasAccess) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text("Permission Needed"),
          content: const Text("Please allow media access to select photos."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                PhotoManager.openSetting();
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );
      return;
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.all,
      onlyAll: true,
    );

    if (albums.isEmpty) return;

    final AssetPathEntity album = albums.first;
    final int assetCount = await album.assetCountAsync;

    final List<AssetEntity> media = await album.getAssetListRange(
      start: 0,
      end: assetCount,
    );

    if (!mounted) return;

    setState(() {
      _mediaList = media;
      _selectedMedia = media.isNotEmpty ? media.first : null;
    });
  }

  Future<Widget> _buildThumbnail(AssetEntity entity, {int size = 200}) async {
    final thumbData = await entity.thumbnailDataWithSize(
      ThumbnailSize(size, size),
    );
    if (thumbData == null) return const SizedBox();

    Widget image = Image.memory(thumbData, fit: BoxFit.cover);

    if (entity.type == AssetType.video) {
      image = Stack(
        children: [
          Positioned.fill(child: image),
          const Center(
            child:
                Icon(Icons.play_circle_outline, size: 30, color: Colors.white),
          ),
        ],
      );
    }

    return image;
  }

  Future<Widget> _buildMediaPreview() async {
    if (_selectedMedia == null) {
      return const Center(child: Text("No media selected"));
    }
    return await _buildThumbnail(_selectedMedia!, size: 600);
  }

  Future<String?> convertFileToBase64(File file) async {
    try {
      List<int> fileBytes = await file.readAsBytes();
      return base64Encode(fileBytes);
    } catch (e) {
      debugPrint("Error converting file: $e");
      return null;
    }
  }

  Future<void> registervalidation(BuildContext context) async {
    // ignore: avoid_print
    print("Register validation called");
    setState(() {
      _isLoading = true;
    });

    try {
      String? base64Media;
      String? mediaType;
      final file = await _selectedMedia?.file;

      if (file != null) {
        base64Media = await convertFileToBase64(file);
        mediaType = _selectedMedia?.type == AssetType.video ? 'video' : 'image';
      }

      final url = Uri.parse('${Constants.url}image_post.php');

      Map<String, dynamic> product = {
        "name": user?.name ?? "Unknown User",
        "user_id": user?.id ?? 0,
        "caption": _content.text,
        if (base64Media != null && mediaType == 'image')
          "imageBase64": base64Media,
        if (base64Media != null && mediaType == 'video')
          "videoBase64": base64Media,
      };

      // ignore: avoid_print
      print("Product data: $product");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(product),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Success: ${response.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Align(
              alignment: Alignment.center,
              child: Text("Post uploaded successfully!"),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        debugPrint('Failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.black12,
            child: FutureBuilder<Widget>(
              future: _buildMediaPreview(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return snapshot.data!;
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              itemCount: _mediaList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                return FutureBuilder<Widget>(
                  future: _buildThumbnail(_mediaList[index], size: 200),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMedia = _mediaList[index];
                          });
                        },
                        child: snapshot.data!,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _content,
                    decoration: const InputDecoration(
                      hintText: "Write a caption...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.add_a_photo_outlined),
                  onPressed: _isLoading
                      ? null
                      : () {
                          registervalidation(context);
                        },
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
