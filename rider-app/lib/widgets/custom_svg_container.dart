import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

// Used for SVG, text, text widget.
class CustomSVGContainer extends StatelessWidget {
  CustomSVGContainer(
      {required this.svg, required this.text, required this.amount, this.fillColor, this.borderColor, this.onTap});

  String svg;
  Color? fillColor;
  Color? borderColor;
  String text;
  String amount;
  GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: buildContainer(),
    );
  }

  buildContainer() {
    return Container(
      padding: getPadding(left: 24, top: 14, right: 24, bottom: 14),
      decoration: BoxDecoration(
        color: fillColor ?? ColorConstant.WHITE1,
        border: Border.all(color: borderColor ?? Colors.transparent),
        borderRadius: BorderRadius.circular(
          getHorizontalSize(24.00),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(svg, fit: BoxFit.contain),
          Padding(
            padding: getPadding(left: 8, top: 3, bottom: 4),
            child: Text(text,
                overflow: TextOverflow.ellipsis, textAlign: TextAlign.left, style: CustomTextStyle.txtBody1()),
          ),
          const Spacer(),
          Padding(
            padding: getPadding(top: 4, bottom: 4),
            child: Text(amount,
                overflow: TextOverflow.ellipsis, textAlign: TextAlign.left, style: CustomTextStyle.txtBody1()),
          ),
        ],
      ),
    );
  }
}
