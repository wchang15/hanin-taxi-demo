import 'package:flutter/material.dart';
import 'package:tax_app/utils/color_constants.dart';

// Loading Dialog for all api calls
class CustomLoadingDialog extends StatelessWidget {
  CustomLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return buildAlert();
  }

  buildAlert() {
    return Stack(
      children: [
        Opacity(
          opacity: 0.8,
          child: ModalBarrier(dismissible: false, color: ColorConstant.BLACK),
        ),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
