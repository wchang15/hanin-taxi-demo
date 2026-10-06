import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/size.dart';
import '../utils/text_styles.dart';

// creating blue (success) or red (error) alert widget
class CustomAlert extends StatelessWidget {
  const CustomAlert({
    super.key,
    required this.bgColor,
    required this.color,
    required this.icon,
    required this.text,
    this.visible,
  });

  final Color bgColor;
  final Color color;
  final IconData icon;
  final String text;
  final bool? visible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible ?? true,
      child: buildAlert(),
    );
  }

  Widget buildAlert() {
    final alertText = text.length > 100 ? "error_restart".tr : text;
    return Container(
      margin: getMargin(left: 10, right: 10, bottom: 10),
      padding: getPadding(all: 13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: bgColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              alertText,
              textAlign: TextAlign.center,
              style: CustomTextStyle.txtBody1(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
