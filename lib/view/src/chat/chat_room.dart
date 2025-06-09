import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clone_insta/view/src/constant/const.dart';
import 'package:clone_insta/view/src/model/auth.dart';
import 'package:clone_insta/view/src/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:random_string/random_string.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

import '../../../theme/theme.dart';

// ignore: must_be_immutable
class ChatRoom extends StatefulWidget {
  String sendUserId, sendPic, sendName;
  ChatRoom(
      {super.key,
      required this.sendUserId,
      required this.sendName,
      required this.sendPic});
  @override
  // ignore: library_private_types_in_public_api
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  Stream? messageStream;
  String? myUserId, myName, myPhoto, myEmail, chatRoomId, messageId;
  TextEditingController messageController = TextEditingController();
  bool _isrecord = false;
  String? _filePath;
  final FlutterSoundRecord _recorder = FlutterSoundRecord();
  final Map<String, bool> _isPlayingMap = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingMessage;
  File? _selectImage;
  String? _selectedMessageId;
  UserModel? user;
  // ignore: non_constant_identifier_names
  Map<String, String>? user_data;

  onLoad() async {
    initlizedRecord();
    await fetchData();
    await getandSetMessage();
  }

  @override
  void initState() {
    super.initState();

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          if (_currentlyPlayingMessage != null) {
            _isPlayingMap[_currentlyPlayingMessage!] = false;
            _currentlyPlayingMessage = null;
          }
        });
      }
    });

    onLoad();
  }

  fetchData() async {
    user_data = await Db.getData();
    user = UserModel.fromJson(user_data!);
    chatRoomId = Db().getchatRoomIdByUserId(
      user!.id,
      widget.sendUserId,
      user!.name,
      widget.sendName,
    );
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

  addMessage(bool sendClicked) async {
    if (messageController.text != "") {
      String message = messageController.text;
      messageController.text = "";

      DateTime now = DateTime.now();
      String formatedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "data": "Message",
        "message": message,
        "sendBy": user!.name,
        "ts": formatedDate,
        "time": FieldValue.serverTimestamp(),
        "imageUrl": user!.imageUrl,
      };
      messageId = randomAlphaNumeric(10);
      await Db()
          .addMessage(chatRoomId!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": "Message",
          "lastMessageSendTs": formatedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": user!.name,
        };
        Db().updateLastMessageSend(chatRoomId!, lastMessageInfoMap);
        if (sendClicked) {
          message = "";
        }
      });
    }
    if (_selectImage != null) {
      String? imageUrl;
      String? base64Media;
      base64Media = await convertFileToBase64(_selectImage!);
      final url = Uri.parse('${Constants.url}insta_message.php');
      var imageId = "img_${randomAlphaNumeric(10)}";
      Map<String, dynamic> product = {
        "imageBase64": base64Media,
        "imageId": imageId
      };
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(product),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Success: ${response.body}');
        imageUrl = "messages/images/$imageId.jpg";
        // Optional: Delete the temp file
        if (await _selectImage!.exists()) {
          await _selectImage!.delete();
        }

        String message = imageUrl ?? "";

        DateTime now = DateTime.now();
        String formatedDate = DateFormat('h:mma').format(now);
        Map<String, dynamic> messageInfoMap = {
          "data": "Image",
          "message": message,
          "sendBy": user!.name,
          "ts": formatedDate,
          "time": FieldValue.serverTimestamp(),
          "imageUrl": user!.imageUrl,
        };
        messageId = randomAlphaNumeric(10);
        await Db()
            .addMessage(chatRoomId!, messageId!, messageInfoMap)
            .then((value) {
          Map<String, dynamic> lastMessageInfoMap = {
            "lastMessage": "Image",
            "lastMessageSendTs": formatedDate,
            "time": FieldValue.serverTimestamp(),
            "lastMessageSendBy": user!.name,
          };
          Db().updateLastMessageSend(chatRoomId!, lastMessageInfoMap);
          if (sendClicked) {
            setState(() {
              _selectImage = null;
            });
          }
        });
      }
    }
  }

  Widget chatMessageTile(
      String message, bool sendByMe, String data, String id) {
    return GestureDetector(
      onTap: () {
        if (_selectedMessageId != null) {
          setState(() => _selectedMessageId = null);
        }
      },
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        if (sendByMe) {
          setState(() {
            _selectedMessageId = id; // Store selected message ID
          });
        }
      },
      child: Column(
        children: [
          (_selectedMessageId != null && _selectedMessageId == id)
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Db().deleteMessage(chatRoomId!, _selectedMessageId!);
                    setState(() {
                      _selectedMessageId = null;
                    });
                  },
                )
              : Container(),
          Row(
            mainAxisAlignment:
                sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                    padding: const EdgeInsets.all(16),
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(24),
                          bottomRight: sendByMe
                              ? const Radius.circular(0)
                              : const Radius.circular(24),
                          topRight: const Radius.circular(24),
                          bottomLeft: sendByMe
                              ? const Radius.circular(24)
                              : const Radius.circular(0),
                        ),
                        color: sendByMe ? Colors.black45 : Colors.blueGrey),
                    child: data == "Message"
                        ? Text(
                            message,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold),
                          )
                        : data == "Audio"
                            ? GestureDetector(
                                onTap: () async {
                                  String audioPath = Constants.url + message;
                                  bool isPlaying =
                                      _isPlayingMap[audioPath] ?? false;

                                  if (isPlaying) {
                                    await _audioPlayer.stop();
                                    setState(() {
                                      _isPlayingMap[audioPath] = false;
                                      _currentlyPlayingMessage = null;
                                    });
                                  } else {
                                    try {
                                      // Stop previous if another is playing
                                      if (_currentlyPlayingMessage != null &&
                                          _currentlyPlayingMessage !=
                                              audioPath) {
                                        _isPlayingMap[
                                            _currentlyPlayingMessage!] = false;
                                      }

                                      await _audioPlayer.setUrl(
                                          audioPath);
                                      await _audioPlayer.play();

                                      setState(() {
                                        _isPlayingMap[audioPath] = true;
                                        _currentlyPlayingMessage = audioPath;
                                      });
                                    } catch (e) {
                                      print("Error playing audio: $e");
                                    }
                                  }
                                },
                                child: Row(
                                  children: [
                                    (_isPlayingMap[Constants.url + message] ??
                                            false)
                                        ? const Icon(Icons.pause,
                                            color: Colors.white)
                                        : const Icon(Icons.speaker,
                                            color: Colors.white),
                                    const SizedBox(width: 10.0),
                                    const Text(
                                      "Audio",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "popins",
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : Image(
                                image: CachedNetworkImageProvider(
                                    Constants.url + message),
                                height: 100,
                                width: 100,
                              )),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget chatMessage() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data.docs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  // ignore: avoid_print
                  print(ds.id);
                  // ignore: unrelated_type_equality_checks
                  return chatMessageTile(ds["message"],
                      user!.name == ds["sendBy"], ds['data'], ds.id);
                })
            : Container();
      },
    );
  }

  getandSetMessage() async {
    messageStream = await Db().getchatRoomMessages(chatRoomId);
    setState(() {});
  }

  Future<void> initlizedRecord() async {
    await _requestPermission();
    var tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio.aac';
  }

  Future<void> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _startRecording() async {
    await _recorder.start(path: _filePath);
    if (!mounted) return;
    setState(() {
      _isrecord = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _isrecord = false;
    });
  }

  Future<void> _uploadFile() async {
    if (!mounted) return;

    // Show snackbar to notify user
    Builder(
      builder: (BuildContext scaffoldContext) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Saving audio locally...",
            style: TextStyle(fontSize: 20.0),
          ),
        ));
        return const SizedBox.shrink(); // Return an empty widget
      },
    );

    try {
      // Ensure _filePath is not null
      if (_filePath == null) throw Exception("File path is null");

      File originalFile = File(_filePath!);

      String? base64Media;
      base64Media = await convertFileToBase64(originalFile);
      final url = Uri.parse('${Constants.url}insta_message.php');
      var audioId = "aud_${randomAlphaNumeric(10)}";
      Map<String, dynamic> product = {
        "audioBase64": base64Media,
        "audioId": audioId
      };
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(product),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Success: ${response.body}');

        DateTime now = DateTime.now();
        String formattedDate = DateFormat('h:mma').format(now);
        Map<String, dynamic> messageInfoMap = {
          "data": "Audio",
          "message": "messages/audio/$audioId.mp3",
          "sendBy": user!.name,
          "ts": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "imageUrl": user!.imageUrl,
        };
        messageId = randomAlphaNumeric(10);
        await Db().addMessage(chatRoomId!, messageId!, messageInfoMap);
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": "Audio",
          "lastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": user!.name,
        };

        await Db().updateLastMessageSend(chatRoomId!, lastMessageInfoMap);
      }
    } catch (e) {
      debugPrint("Error saving audio locally: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    final tempImage = File(pickedFile.path);

    setState(() {
      _selectImage = tempImage;
    });
  }

  Future openRecording(context) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Add Voice",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: "popins"),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    if (!mounted) return;
                    if (_isrecord) {
                      await _stopRecording();
                    } else {
                      await _startRecording();
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: Text(
                    _isrecord ? "Stop Record" : "Start Record",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: "popins"),
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    if (_isrecord) {
                      await _stopRecording();
                    }
                    await _uploadFile();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    "Upload Record",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: "popins"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.appTheme.primaryColor,
        resizeToAvoidBottomInset: true,
        body: Container(
          margin: const EdgeInsets.only(top: 40.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  children: [
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white)),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 5,
                    ),
                    Text(
                      widget.sendName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 10.0),
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30))),
                  child: Column(
                    children: [
                      Expanded(child: chatMessage()),
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            if (_selectImage != null)
                              Container(
                                width: MediaQuery.of(context).size.width,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 10),
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 163, 250, 214),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15.0),
                                    topRight: Radius.circular(15.0),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: FileImage(_selectImage!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectImage = null;
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black45,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () => openRecording(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: AppTheme.appTheme.primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(60)),
                                    child: const Icon(
                                      Icons.mic,
                                      color: Colors.white,
                                      size: 35,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 234, 234, 241),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: TextField(
                                      controller: messageController,
                                      decoration: InputDecoration(
                                        hintText: "Write somethings !!",
                                        suffixIcon: GestureDetector(
                                            onTap: () =>
                                                _pickImageFromGallery(),
                                            child:
                                                const Icon(Icons.attach_file)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              10), // Match container radius
                                          borderSide: BorderSide
                                              .none, // Optional: hide default border
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                      ),
                                      style: const TextStyle(
                                          color:
                                              Colors.black), // Optional styling
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    addMessage(true);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: AppTheme.appTheme.primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(60)),
                                    child: const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
