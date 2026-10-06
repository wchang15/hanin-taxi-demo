import 'package:flutter/material.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

// Text Button with List Tile. Can have any order based on the child
class CustomTextButton extends StatelessWidget {
  CustomTextButton({required this.onPressed, required this.child, this.subtitle});

  VoidCallback? onPressed;
  Widget child;
  Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(padding: getPadding(all: 0)),
      onPressed: onPressed,
      child: ListTile(
        title: Padding(padding: getPadding(bottom: 10), child: child),
        subtitle: subtitle,
      ),
    );
  }
}
