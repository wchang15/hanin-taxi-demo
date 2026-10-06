import 'dart:convert';

import 'package:driverapp/utils/icon_constants.dart';
import 'package:flutter/material.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

class CustomTaxiCard extends StatelessWidget {
  CustomTaxiCard({
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.color,
  });

  String licensePlate;
  String make;
  String model;
  String color;

  @override
  Widget build(BuildContext context) {
    return buildSmallCard();
  }

  buildSmallCard() {
    return Container(
      width: SIZE.width,
      //alignment: Alignment.center,
      color: ColorConstant.WHITE1,
      padding: getPadding(all: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: getPadding(all: 3),
            decoration: BoxDecoration(
              color: ColorConstant.YELLOW,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(IconConstant.Car, color: ColorConstant.SECONDARY, size: 18),
          ),
          const SizedBox(height: 10),
          Text(licensePlate, style: CustomTextStyle.txtTitle3(color: ColorConstant.BLACK1)),
          const SizedBox(height: 10),
          Text('$make $model $color', style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK1)),
        ],
      ),
    );
  }
}
