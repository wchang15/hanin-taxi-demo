import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';
import 'package:tax_app/widgets/custom_text_arrow.dart';

import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/image_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_tap.dart';

class TermScreen extends StatefulWidget {
  const TermScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TermScreenState();
}

// ignore_for_file: must_be_immutable
class TermScreenState extends State<TermScreen> {
  final customerController = Get.find<CustomerController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //This needs to be changed to a new animation
    return Scaffold(
      backgroundColor: ColorConstant.WHITE,
      appBar: CustomAppBar(
        title: Text(customerController.terms[Get.arguments][0].tr, style: CustomTextStyle.txtTitle2()),
        leading: IconButton(
          icon: Icon(IconConstant.ArrowBack),
          iconSize: 24,
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: getPadding(left: 12, right: 12, top: 12, bottom: 100),
        child: SingleChildScrollView(
          child: Text(customerController.terms[Get.arguments][1], style: CustomTextStyle.txtBody2(height: 1.2)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomTap(
            color: ColorConstant.PRIMARY,
            onTap: () {
              customerController.termsCheck[Get.arguments] = true;
              Get.back();
            },
            child: Text("term_agree".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
          ),
        ],
      ),
    );
  }
}
