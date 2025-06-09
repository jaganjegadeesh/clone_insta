import 'package:clone_insta/theme/src/theme.dart';
import 'package:clone_insta/view/src/auth/login.dart';
import 'package:clone_insta/view/src/model/auth.dart';
import 'package:clone_insta/view/src/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loading = true;
  bool _login = false;

  @override
  void initState() {
    super.initState();
    initaialfun();
  }

  void initaialfun() async {
    var login = await Db.checkLogin();
    setState(() {
      _login = login;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat App',
      theme: AppTheme.appTheme,
      debugShowCheckedModeBanner: false,
      home: _loading
          ? Scaffold(
              body: Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                  color: const Color.fromARGB(255, 252, 75, 75),
                  size: 60,
                ),
              ),
            )
          : _login
              ? const HomePage()
              : const Login(),
    );
  }
}
