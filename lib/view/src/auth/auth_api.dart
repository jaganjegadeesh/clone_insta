import 'dart:convert';
import 'package:clone_insta/view/src/constant/const.dart';
import 'package:http/http.dart' as http;

class AuthAPI {
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final url = Uri.parse(
        "${Constants.url}user_auth.php"); // Replace with real endpoint
    // ignore: avoid_print
    print(url);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'type': "login",
      }),
    );

    // ignore: avoid_print
    print(
      jsonEncode({
        'email': email,
        'password': password,
        'type': "login",
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
