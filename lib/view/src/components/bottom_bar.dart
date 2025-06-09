import 'package:cached_network_image/cached_network_image.dart';
import 'package:clone_insta/theme/src/theme.dart';
import 'package:clone_insta/view/src/auth/login.dart';
import 'package:clone_insta/view/src/model/auth.dart';
import 'package:clone_insta/view/src/page/post_page.dart';
import 'package:clone_insta/view/src/page/profile.dart';
import 'package:clone_insta/view/src/page/reels_page.dart';
import 'package:clone_insta/view/src/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_icon_class/font_awesome_icon_class.dart';

// ignore: must_be_immutable
class BottomBar extends StatelessWidget {
  String profile;
  // ignore: use_super_parameters
  // const BottomBar(String profile, {Key? key}) : super(key: key)required this.text,;

  BottomBar(
    String s, {
    super.key,
    required this.profile,
  });

  void logout(BuildContext context) async {
    await Db.clearDb();
    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppTheme.appTheme.primaryColor,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.home, color: AppTheme.appTheme.indicatorColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.appTheme.indicatorColor),
            onPressed: () {},
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.add_box, color: AppTheme.appTheme.indicatorColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PostPage()),
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: Icon(FontAwesomeIcons.film,
                color: AppTheme.appTheme.indicatorColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InstaReels()),
              );
            },
          ),
          const Spacer(),
          GestureDetector(
            onLongPress: () => logout(context),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Profile()),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundImage: profile != ''
                  ? CachedNetworkImageProvider(profile)
                  : const AssetImage("asset/images/zoro.jpg"),
            ),
          ),
        ],
      ),
    );
  }
}
