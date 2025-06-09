import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Db {
  static Future<SharedPreferences> connect() async {
    return await SharedPreferences.getInstance();
  }

  static Future<bool> checkLogin() async {
    var cn = await connect();
    bool? r = cn.getBool('login');
    return r ?? false;
  }

  static Future setLogin({required LoginModel model}) async {
    var cn = await connect();
    cn.setString('email', model.email ?? "");
    cn.setString('password', model.password ?? "");
    cn.setString('name', model.name ?? "");
    cn.setString('phone', model.phone ?? "");
    cn.setString('dob', model.dob ?? "");
    cn.setString('gender', model.gender ?? "");
    cn.setString('id', model.id ?? "");
    cn.setString('imageUrl', model.imageUrl ?? "");
    cn.setBool('login', true);
  }

  static Future<Map<String, String>?> getData() async {
    var cn = await connect();
    final String? email = cn.getString('email');
    final String? name = cn.getString('name');
    final String? phone = cn.getString('phone');
    final String? dob = cn.getString('dob');
    final String? gender = cn.getString('gender');
    final String? id = cn.getString('id');
    final String? imageUrl = cn.getString('imageUrl');

    if (email != null &&
        name != null &&
        phone != null &&
        id != null &&
        gender != null &&
        dob != null) {
      return {
        'email': email,
        'name': name,
        'phone': phone,
        'id': id,
        'gender': gender,
        'dob': dob,
        'imageUrl': imageUrl ?? "",
      };
    } else {
      return null;
    }
  }

  static Future<bool> clearDb() async {
    var cn = await connect();
    return cn.clear();
  }

  String getchatRoomIdByUserId(String a, String b, String c, String d) {
    if (a.compareTo(b) > 0) {
      return "${b}_${d}__${a}_$c";
    } else {
      return "${a}_${c}__${b}_$d";
    }
  }


   Future addMessage(String chatRoomId, String messageId,
      Map<String, dynamic> messageInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("insta_chatrooms")
        .doc(chatRoomId)
        .collection("chat")
        .doc(messageId)
        .set(messageInfoMap);
  }

  updateLastMessageSend(
      String chatRoomId, Map<String, dynamic> lastMessageInfoMap) async {
    return FirebaseFirestore.instance
        .collection("insta_chatrooms")
        .doc(chatRoomId)
        .update(lastMessageInfoMap);
  }

  createChatRoom(
      String chatRoomId, Map<String, dynamic> chatRoomInfoMap) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('insta_chatrooms')
        .doc(chatRoomId)
        .get();
    if (snapshot.exists) {
      return true;
    } else {
      return FirebaseFirestore.instance
          .collection('insta_chatrooms')
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
    }
  }

  Future<Stream<QuerySnapshot>> getchatRoomMessages(chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("insta_chatrooms")
        .doc(chatRoomId)
        .collection("chat")
        .orderBy("time", descending: true)
        .snapshots();
  }

  Future deleteMessage(String chatRoomId, String messageId) {
    return FirebaseFirestore.instance
        .collection("insta_chatrooms")
        .doc(chatRoomId)
        .collection("chat")
        .doc(messageId)
        .delete();
  }
  
}

class LoginModel {
  String? id;
  String? email;
  String? phone;
  String? dob;
  String? gender;
  String? password;
  String? name;
  String? imageUrl;
  LoginModel({
    this.id,
    this.email,
    this.password,
    this.phone,
    this.name,
    this.dob,
    this.gender,
    this.imageUrl,
  });
}