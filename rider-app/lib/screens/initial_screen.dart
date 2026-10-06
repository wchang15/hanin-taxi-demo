import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_app/controllers/customer_controller.dart';

import '../utils/constants.dart';
import '../utils/image_constants.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InitialScreenState();
}

// ignore_for_file: must_be_immutable
class InitialScreenState extends State<InitialScreen> {
  final customerController = Get.find<CustomerController>();

  @override
  void initState() {
    once(customerController.isRefreshSuccess, (res) {
      if (res == true) {
        if (customerController.customer.value!.isVerified) {
          Get.offNamed(HOME);
        } else {
          Get.offNamed(LOGIN);
          Get.offNamed(TERMS);
          Get.toNamed(REGISTER);
          Get.toNamed(PHONE);
        }
      } else {
        customerController.setError("");
        Get.offNamed(LOGIN);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //This needs to be changed to a new animation
    return Scaffold(body: Lottie.asset(ImageConstant.animationOnboarding));
  }
}
