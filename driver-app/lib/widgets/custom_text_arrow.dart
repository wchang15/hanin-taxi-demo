
import 'package:flutter/material.dart';

import '../utils/size.dart';
import '../utils/text_styles.dart';

// Text and > arrow button (Register > && find ID Password >)
class CustomTextArrow extends StatelessWidget {
  CustomTextArrow(
      {required this.firstWidget, required this.secondWidget, required this.onPressed, this.padding, this.alignment});

  Widget firstWidget;
  Widget secondWidget;
  VoidCallback? onPressed;
  EdgeInsetsGeometry? padding;
  Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: buildTextArrow(),
          )
        : buildTextArrow();
  }

  buildTextArrow() {
    return Padding(
      padding: padding ?? getPadding(left: 0, top: 5),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: firstWidget,
        label: secondWidget,
      ),
    );
  }
}
