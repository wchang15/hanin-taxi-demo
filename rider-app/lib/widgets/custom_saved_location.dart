import 'package:flutter/material.dart';
import 'package:tax_app/utils/color_constants.dart';

import '../utils/size.dart';
import '../utils/text_styles.dart';

// Circular Primary Icon with Text Button
class CustomSavedLocation extends StatelessWidget {
  CustomSavedLocation({required this.icon, required this.text, required this.onPressed});

  Widget icon;
  String text;
  VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return buildTextArrow();
  }

  buildTextArrow() {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        children: [
          Container(
            padding: getPadding(all: 3),
            decoration: BoxDecoration(
              color: ColorConstant.PRIMARY.withOpacity(0.3),
              borderRadius: BorderRadius.circular(25),
            ),
            child: icon,
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            text,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK1),
          )
        ],
      ),
    );
  }
}
