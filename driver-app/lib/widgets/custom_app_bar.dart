import 'package:flutter/material.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';

// Creating white app bar.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  CustomAppBar({this.leading, this.title, this.centerTitle, this.actions});

  Widget? leading;

  Widget? title;

  bool? centerTitle;

  List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorConstant.WHITE,
      foregroundColor: ColorConstant.BLACK,
      elevation: 0,
      title: title,
      centerTitle: centerTitle ?? false,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Size get preferredSize => Size(SIZE.width, 50);
}
