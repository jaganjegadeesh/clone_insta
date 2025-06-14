import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clone_insta/view/src/constant/const.dart';
import 'package:clone_insta/view/src/model/auth.dart';
import 'package:clone_insta/view/src/model/user.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class StoryPost extends StatefulWidget {
  // ignore: non_constant_identifier_names
  const StoryPost({super.key, String? MyId});

  @override
  State<StoryPost> createState() => _StoryPostState();
}

class _StoryPostState extends State<StoryPost> {
  final ImagePicker _picker = ImagePicker();
  List<AssetEntity> _galleryAssets = [];

  @override
  void initState() {
    super.initState();
    
    _fetchGallery();
  }

  Future<void> _fetchGallery() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.all, // ✅ Get both images and videos
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (albums.isEmpty) return;

    // ✅ Fetch ALL assets — large enough page size
    final media = await albums.first.getAssetListPaged(
      page: 0,
      size: 10000,
    );

    setState(() {
      _galleryAssets = media;
    });
  }

  Future<void> _addFromCamera(bool isVideo) async {
    final pickedFile = isVideo
        ? await _picker.pickVideo(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryViewer(
            file: file,
            isVideo: isVideo,
          ),
        ),
      );
    }
  }

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                _addFromCamera(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text("Record Video"),
              onTap: () {
                Navigator.pop(context);
                _addFromCamera(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _galleryAssets.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: _showCameraOptions,
            child: Container(
              color: Colors.grey[300],
              child: const Icon(Icons.camera_alt, size: 40),
            ),
          );
        } else {
          final asset = _galleryAssets[index - 1];
          return FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
            builder: (_, snapshot) {
              final bytes = snapshot.data;
              if (bytes == null) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () async {
                  final file = await asset.file;
                  if (file == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryViewer(
                        file: file,
                        isVideo: asset.type == AssetType.video,
                      ),
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes, fit: BoxFit.cover),
                    if (asset.type == AssetType.video)
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.play_circle_fill, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Story'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildGalleryGrid(),
    );
  }
}

class StoryViewer extends StatefulWidget {
  final File file;
  final bool isVideo;

  const StoryViewer({
    super.key,
    required this.file,
    required this.isVideo,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  // ignore: non_constant_identifier_names
  Map<String, String>? user_data;
  UserModel? user;

  @override
  void initState() {
    super.initState();
    _loadMedia();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          _videoController?.setLooping(true); 
          setState(() {});
          _videoController?.play();
        });
    }
  }

  Future<void> _loadMedia() async {
    user_data = await Db.getData();
    user = UserModel.fromJson(user_data!);
    setState(() {});
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

  Future<void> poststory(BuildContext context) async {
    debugPrint("Post story called");
    setState(() {
      _isLoading = true;
    });

    try {
      final base64Media = await convertFileToBase64(widget.file);
      final mediaType = widget.isVideo ? 'video' : 'image';

      final url = Uri.parse('${Constants.url}story_post.php');

      final product = {
        "name": user?.name ?? "Unknown User",
        "user_id": user?.id ?? 0,
        if (base64Media != null && mediaType == 'image')
          "imageBase64": base64Media,
        if (base64Media != null && mediaType == 'video')
          "videoBase64": base64Media,
      };

      debugPrint("Product data: $product");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(product),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Success: ${response.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post uploaded successfully!")),
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
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Story Viewer'),
      ),
      body: Center(
        child: widget.isVideo
            ? (_videoController != null && _videoController!.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : const CircularProgressIndicator()
            : Image.file(widget.file, fit: BoxFit.contain),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  poststory(context);
                },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Post'),
        ),
      ),
    );
  }
}
