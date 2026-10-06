import 'package:flutter/material.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

// Create a switch with Primary color.
class CustomSwtich extends StatelessWidget {
  CustomSwtich({this.text, required this.val, this.onChanged});

  String? text;
  bool val;
  ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return buildSwitch();
  }

  buildSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(text ?? "", style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
        Padding(
          padding: getPadding(right: 12),
          child: Switch(
            value: val,
            onChanged: onChanged,
            activeTrackColor: ColorConstant.YELLOW,
            activeColor: ColorConstant.PRIMARY,
          ),
        ),
      ],
    );
  }
}
