import 'package:driverapp/controllers/driver_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../controllers/trip_controller.dart';
import '../utils/constants.dart';
import '../utils/image_constants.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InitialScreenState();
}

// ignore_for_file: must_be_immutable
class InitialScreenState extends State<InitialScreen> {
  final driverController = Get.find<DriverController>();
  final tripController = Get.find<TripController>();
  @override
  void initState() {
    once(driverController.isRefreshSuccess, (res) {
      if (res!) {
        Get.offNamed(HOME);
      } else {
        driverController.setError("");
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
