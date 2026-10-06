import 'package:flutter/material.dart';
import 'package:tax_app/utils/size.dart';

class CustomTextStyle {
  static TextStyle txtCaption1(
          {Color color = const Color(0xFF000000), FontWeight weight = FontWeight.w700, double height = 1}) =>
      TextStyle(
        color: color,
        fontSize: getFontSize(11),
        fontFamily: 'Roboto',
        fontWeight: weight,
        height: getVerticalSize(height),
      );
  static TextStyle txtCaption2(
          {Color color = const Color(0xFF000000), FontWeight weight = FontWeight.w700, double height = 1}) =>
      TextStyle(
        color: color,
        fontSize: getFontSize(12),
        fontFamily: 'Roboto',
        fontWeight: weight,
        height: getVerticalSize(height),
      );
  static TextStyle txtBody1(
          {Color color = const Color(0xFF000000), FontWeight weight = FontWeight.w700, double height = 1}) =>
      TextStyle(
        color: color,
        fontSize: getFontSize(14),
        fontFamily: 'Roboto',
        fontWeight: weight,
        height: getVerticalSize(height),
      );
  static TextStyle txtBody2(
          {Color color = const Color(0xFF000000), FontWeight weight = FontWeight.w700, double height = 1}) =>
      TextStyle(
        color: color,
        fontSize: getFontSize(15),
        fontFamily: 'Roboto',
        fontWeight: weight,
        height: getVerticalSize(height),
      );
  static TextStyle txtBody3(
          {Color? color = const Color(0xFF000000), FontWeight weight = FontWeight.w700, double height = 1}) =>
      TextStyle(
        color: color,
        fontSize: getFontSize(16),
        fontFamily: 'Roboto',
        fontWeight: weight,
        height: getVerticalSize(height),
      );
  static TextStyle txtTitle1(
          {Color color = const Color(0xFF000000), FontWeight weight = FontWeight.w700, double height = 1}) =>
      TextStyle(
        color: color,
        fontSize: getFontSize(20),
        fontFamily: 'Roboto',
        fontWeight: weight,
        height: getVerticalSize(height),
      );
  static TextStyle txtTitle2(
          {Color color = const Color(0xFF000000), FontWeight weight = FontWeight.w700, double height = 1}) =>
      TextStyle(
        color: color,
        fontSize: getFontSize(22),
        fontFamily: 'Roboto',
        fontWeight: weight,
        height: getVerticalSize(height),
      );
  static TextStyle txtTitle3(
          {Color color = const Color(0xFF000000), FontWeight weight = FontWeight.w700, double height = 1}) =>
      TextStyle(
        color: color,
        fontSize: getFontSize(24),
        fontFamily: 'Roboto',
        fontWeight: weight,
        height: getVerticalSize(height),
      );
  static TextStyle txtTitle4(
          {Color color = const Color(0xFF000000), FontWeight weight = FontWeight.w700, double height = 1}) =>
      TextStyle(
        color: color,
        fontSize: getFontSize(28),
        fontFamily: 'Roboto',
        fontWeight: weight,
        height: getVerticalSize(height),
      );
}
