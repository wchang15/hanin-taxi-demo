import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';

import '../services/customer_service.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/image_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_app_bar.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LanguageScreenState();
}

// ignore_for_file: must_be_immutable
class LanguageScreenState extends State<LanguageScreen> {
  final customerController = Get.find<CustomerController>();

  //Need to match the order with DB
  final languages = ['English', '한국어', 'Español'];

  @override
  void initState() {
    if (customerController.customer.value != null) {
      customerController.language.value = customerController.customer.value!.language;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //This needs to be changed to a new animation
    return Scaffold(
      backgroundColor: ColorConstant.WHITE,
      appBar: CustomAppBar(
        title: Text("Login_Header".tr, style: CustomTextStyle.txtTitle2()),
        leading: IconButton(
            icon: Icon(IconConstant.ArrowBack),
            iconSize: 24,
            onPressed: () {
              if (customerController.customer.value != null) {
                if (customerController.customer.value!.language != customerController.language.value) {
                  //update database;
                  CustomerServices.updateLanguage(customerController.language.value);
                  customerController.customer.value!.language = customerController.language.value;
                  customerController.updateLanguageWithLanguage();
                }
              } else {
                customerController.updateLanguageWithLanguage();
              }
              Get.back();
            }),
      ),
      body: Container(
        width: SIZE.width,
        padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < languages.length; index++)
              Obx(
                () => Padding(
                  padding: getPadding(bottom: 10, left: 10, right: 10),
                  child: TextButton(
                    onPressed: () {
                      customerController.language.value = index + 1;
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(languages[index],
                            style: CustomTextStyle.txtBody2(
                                color: index + 1 == customerController.language.value
                                    ? ColorConstant.PRIMARY
                                    : ColorConstant.BLACK1)),
                        Icon(IconConstant.Check,
                            color: index + 1 == customerController.language.value
                                ? ColorConstant.PRIMARY
                                : ColorConstant.BLACK1),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
