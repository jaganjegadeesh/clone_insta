import 'package:clone_insta/theme/src/theme.dart';
import 'package:clone_insta/view/src/components/expend_text.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserBottomPost extends StatelessWidget {
  final int index;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;

  const UserBottomPost({
    super.key,
    required this.index,
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onLike,
                    child: Icon(
                      Icons.favorite,
                      color: liked ? Colors.red : AppTheme.appTheme.indicatorColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(FontAwesomeIcons.comment,
                      color: AppTheme.appTheme.indicatorColor, size: 20),
                  const SizedBox(width: 20),
                  Icon(FontAwesomeIcons.paperPlane,
                      color: AppTheme.appTheme.indicatorColor, size: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GestureDetector(
                onTap: onSave,
                child: Icon(
                  Icons.bookmark,
                  color: saved ? Colors.blue : AppTheme.appTheme.indicatorColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Liked by Your Friends and 100 others",
              style: TextStyle(
                color: AppTheme.appTheme.indicatorColor,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 20.0, top: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ExpandableText(
                size: 12,
                text:
                    "Wrap the entire scrollable content (both the horizontal stories and vertical posts) in a single ListView or SingleChildScrollView. Nesting vertical scrolls is problematic."),
          ),
        ),
      ],
    );
  }
}
