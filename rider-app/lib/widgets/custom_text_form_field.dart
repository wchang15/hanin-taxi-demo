import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

// Text field
class CustomTextFormField extends StatelessWidget {
  CustomTextFormField({
    required this.controller,
    this.validate,
    required this.onChanged,
    required this.text,
    this.obscure,
    this.inputFormat,
    this.visible,
    this.enable,
    this.suffixIcon,
    this.onTap,
    this.readOnly,
    this.focusNode,
    this.prefixIcon,
    this.suffixText,
    this.suffixTextStyle,
  });

  TextEditingController controller;
  Function? validate;
  ValueChanged<String>? onChanged;
  String text;
  bool? obscure;
  List<TextInputFormatter>? inputFormat;
  bool? visible;
  bool? enable;
  Widget? prefixIcon;
  Widget? suffixIcon;
  String? suffixText;
  TextStyle? suffixTextStyle;
  GestureTapCallback? onTap;
  bool? readOnly;
  FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible ?? true,
      child: buildText(),
    );
  }

  buildText() {
    return TextFormField(
      enabled: enable ?? true,
      controller: controller,
      inputFormatters: inputFormat,
      decoration: InputDecoration(
        hintText: text,
        // errorText: validate(controller.value.text),
        hintStyle: CustomTextStyle.txtBody2(color: ColorConstant.GREY2),

        labelStyle: CustomTextStyle.txtBody2(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(getHorizontalSize(24.00)),
          borderSide: BorderSide.none,
        ),
        fillColor: ColorConstant.WHITE1,
        filled: true,
        contentPadding: getPadding(all: 13),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        suffixText: suffixText,
        suffixStyle: suffixTextStyle,
      ),
      obscureText: obscure ?? false,
      validator: (value) {
        return validate != null ? validate!(value) : null;
      },
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly ?? false,
      keyboardType: TextInputType.text,
      autofocus: true,
      focusNode: focusNode,
    );
  }
}
