import 'package:flutter/material.dart';
import 'package:tax_app/utils/color_constants.dart';

import '../utils/size.dart';
import '../utils/text_styles.dart';
import 'custom_saved_location.dart';

/// Holds an editable saved location
class CustomEditableLocation extends StatelessWidget {
  CustomEditableLocation(
      {required this.icon,
      required this.leading,
      required this.text,
      required this.address,
      required this.trailing,
      required this.onPressed,
      required this.onTrailingPressed});

  Widget icon;
  String leading;
  String text;
  String address;
  String trailing;
  VoidCallback? onPressed;
  VoidCallback? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    return buildTextArrow();
  }

  buildTextArrow() {
    return Padding(
      padding: getPadding(bottom: 12),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomSavedLocation(
                      icon: icon,
                      text: leading,
                      onPressed: () {},
                    ),
                  ),
                  // Expanded(
                  //   flex: 2,
                  //   child: Text(
                  //     text,
                  //     overflow: TextOverflow.ellipsis,
                  //     textAlign: TextAlign.left,
                  //     style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK3),
                  //   ),
                  // ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK, weight: FontWeight.w400),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          address,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK3, weight: FontWeight.w400),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            TextButton(
              onPressed: onTrailingPressed,
              child: Text(
                trailing,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
