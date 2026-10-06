import 'dart:ui';
import 'package:flutter/material.dart';

class ColorConstant {
  static Color PRIMARY = fromHex('#F1955A');
  static Color YELLOW = fromHex('#FFF7EA');

  static Color WHITE = fromHex('#FFFFFF');
  static Color WHITE1 = fromHex('#FBFAFA');
  static Color GREY = fromHex('#F5F5F5');
  static Color GREY1 = fromHex('#EEEEEE');
  static Color GREY2 = fromHex('#E0E0E0');
  static Color GREY3 = fromHex('#9E9E9E');
  static Color BLACK = fromHex('#212121');
  static Color BLACK1 = fromHex('#424242');
  static Color BLACK2 = fromHex('#616161');
  static Color BLACK3 = fromHex('#9398A1');

  static Color RED = fromHex('#D14343');
  static Color RED1 = fromHex('#FBEAEA');
  static Color BLUE = fromHex('#64B6F7');
  static Color BLUE1 = fromHex('#E6F3FA');
  static Color GREEN = fromHex('#14B8A6');
  static Color GREEN1 = fromHex('#EAF2EA');

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
