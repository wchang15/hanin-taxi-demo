import 'package:flutter/material.dart';

import '../utils/size.dart';

// Custom button usually used on the bottom of the page.
class CustomTap extends StatelessWidget {
  CustomTap({
    required this.color,
    required this.onTap,
    required this.child,
    this.circular,
    this.isNotCenter,
    this.width,
    this.borderRadius,
  });

  Color color;
  VoidCallback? onTap;
  Widget child;
  BorderRadius? circular;
  bool? isNotCenter;
  double? width;
  double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Container(
        width: width ?? SIZE.width,
        height: 50,
        alignment: isNotCenter ?? false ? null : Alignment.center,
        padding: getPadding(all: 0),
        decoration: BoxDecoration(
          borderRadius: circular ?? BorderRadius.circular(getHorizontalSize(borderRadius ?? 24.00)),
          color: color,
        ),
        child: child,
      ),
    );
  }
}
