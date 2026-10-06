import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tax_app/services/redirect_service.dart';
import 'package:tax_app/utils/icon_constants.dart';
import 'package:tax_app/widgets/custom_saved_location.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

// creating blue (success) or red (error) alert widget
class CustomDriverCard extends StatelessWidget {
  CustomDriverCard({
    required this.licensePlate,
    required this.carAndColor,
    required this.companyName,
    required this.driverName,
    required this.phoneNumber,
    required this.photo,
    this.isFull = false,
  });

  String licensePlate;
  String carAndColor;
  String companyName;
  String driverName;
  String phoneNumber;
  String photo;
  bool isFull;
  // Color bgColor;
  // Color color;
  // IconData icon;
  // String text;
  // bool? visible;

  @override
  Widget build(BuildContext context) {
    return isFull ? buildFullCard() : buildSmallCard();
  }

  buildFullCard() {
    return Container(
      margin: getMargin(left: 10, right: 10, bottom: 10),
      padding: getPadding(all: 13),
      alignment: Alignment.center,
      child: Padding(
        padding: getPadding(left: 18, right: 12, top: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.red,
              radius: 50,
              child: SizedBox(
                width: 150,
                height: 150,
                child: ClipOval(child: Image.memory(base64Decode(baseImage()), fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(licensePlate, style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK1)),
                const SizedBox(
                  height: 20,
                  child: VerticalDivider(thickness: 1),
                ),
                Text(carAndColor, style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK1)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("$driverName${"drivernumber".tr}", style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK1)),
                const SizedBox(width: 10),
                Text(companyName, style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: getPadding(all: 2),
                  decoration: BoxDecoration(
                    color: ColorConstant.PRIMARY.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(IconConstant.Phone, color: ColorConstant.PRIMARY, size: 18),
                ),
                const SizedBox(width: 5),
                TextButton(
                  child: Text('+1 $phoneNumber', style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK1)),
                  onPressed: () async {
                    await RedirectService.makeCall(phoneNumber);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  buildSmallCard() {
    return Container(
      margin: getMargin(top: 10, left: 10, right: 10, bottom: 10),
      padding: getPadding(all: 13),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red,
            radius: 40,
            child: SizedBox(
              width: 150,
              height: 150,
              child: ClipOval(child: Image.memory(base64Decode(baseImage()), fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(licensePlate, style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK1)),
                  const SizedBox(
                    height: 20,
                    child: VerticalDivider(thickness: 1),
                  ),
                  Text(carAndColor, style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK1)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(companyName, style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3)),
                  const SizedBox(width: 10),
                  Text("$driverName${"drivernumber".tr}", style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK1)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: getPadding(all: 2),
                    decoration: BoxDecoration(
                      color: ColorConstant.PRIMARY.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(IconConstant.Phone, color: ColorConstant.PRIMARY, size: 18),
                  ),
                  const SizedBox(width: 5),
                  TextButton(
                    child: Text('+1 $phoneNumber', style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK1)),
                    onPressed: () async {
                      await RedirectService.makeCall(phoneNumber);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  baseImage() =>
      "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";
}
