import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

// dialog to cancel trip && send complaint
Future customCancelDialog({
  required VoidCallback? okayClick,
  required String title,
  String? body,
  required String cancelText,
  required String okayText,
  bool isContent = false,
  String? contentText,
  String? hintText,
  TextEditingController? controller,
  VoidCallback? cancelClick,
}) {
  return Get.defaultDialog(
    barrierDismissible: false,
    title: title,
    titlePadding: getPadding(top: 20),
    titleStyle: CustomTextStyle.txtTitle1(),
    middleText: body ?? "",
    middleTextStyle: CustomTextStyle.txtBody3(height: 2),
    content: isContent
        ? Padding(
            padding: getPadding(left: 12, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contentText ?? "",
                  softWrap: true,
                  style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK3),
                ),
                Container(
                  padding: getPadding(top: 10),
                  height: 200,
                  child: TextField(
                    controller: controller,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ColorConstant.WHITE1,
                      hintText: hintText ?? "",
                      hintStyle: CustomTextStyle.txtBody1(color: ColorConstant.GREY3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(getHorizontalSize(12.00)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: getPadding(all: 10),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    expands: true,
                  ),
                ),
              ],
            ),
          )
        : null,
    actions: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
            onPressed: okayClick,
            child: Text(okayText, style: CustomTextStyle.txtBody2(color: ColorConstant.RED)),
          ),
          TextButton(
            onPressed: () {
              if (controller != null) controller.clear();
              Get.back();
              cancelClick;
            },
            child: Text(cancelText, style: CustomTextStyle.txtBody2(color: ColorConstant.GREY3)),
          ),
        ],
      ),
    ],
  );
}
