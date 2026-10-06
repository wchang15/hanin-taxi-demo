import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:get/get.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/services/customer_service.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';

import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/secure_storage.dart';
import '../utils/validate_text.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_tap.dart';
import '../widgets/custom_text_arrow.dart';
import '../widgets/custom_text_form_field.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PhoneVerificationScreenState();
}

// ignore_for_file: must_be_immutable
class PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final otpFieldController = OtpFieldController();
  final customerController = Get.find<CustomerController>();
  bool timerRunning = false;
  String pin = "";
  Timer? countdownTimer;
  Duration duration = const Duration(seconds: 30);

  var isAlert = true;
  var isSuccess = true;
  var alertMsg = "otp_sent".tr;

  void startTimer() => countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => setCountDown());

  void setCountDown() {
    const reduceSecondsBy = 1;
    setState(() {
      final seconds = duration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        countdownTimer!.cancel();
        countdownTimer = null;
        timerRunning = false;
      } else {
        duration = Duration(seconds: seconds);
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    //phoneNumberController.text = customerController.customer.value!.phoneNumber;
    //startTimer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = duration.inSeconds == 0 ? "" : duration.inSeconds;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title: Text("phone_header".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () {
                customerController.setError("");
                Get.back();
              },
            ),
          ),
          body: Container(
            width: SIZE.width,
            //alignment: Alignment.center,
            padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
            child: ListView(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Obx(
                  () => Text(
                    "${"phone_phone".tr}: ${customerController.customer.value!.phoneNumber}",
                    style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK, weight: FontWeight.w400),
                  ),
                ),
                const SizedBox(height: 100),
                OTPTextField(
                  length: 5,
                  controller: otpFieldController,
                  width: SIZE.width,
                  style: const TextStyle(fontSize: 17),
                  textFieldAlignment: MainAxisAlignment.spaceAround,
                  fieldStyle: FieldStyle.box,
                  onChanged: (change) {
                    setState(() {
                      customerController.setError("");
                      if (change.length != 5) {
                        pin = change;
                      }
                    });
                  },
                  onCompleted: (curpin) {
                    setState(() {
                      pin = curpin;
                    });
                  },
                ),
                const SizedBox(height: 10),
                CustomTextArrow(
                  firstWidget: Text("${"phone_reverification".tr} $seconds",
                      style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK3)),
                  secondWidget: const SizedBox(),
                  onPressed: !timerRunning
                      ? () async {
                          var res = await CustomerServices.resendOTP();

                          if (res == "") {
                            //success
                            setState(() {
                              isAlert = true;
                              isSuccess = true;
                              alertMsg = "otp_sent".tr;
                              timerRunning = true;
                              duration = const Duration(seconds: 30);
                            });
                            startTimer();
                          } else {
                            setState(() {
                              isAlert = true;
                              isSuccess = false;
                              alertMsg = "otp_send_fail".tr;
                            });
                          }
                        }
                      : null,
                  alignment: Alignment.center,
                ),
                const SizedBox(height: 140),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomAlert(
                bgColor: isSuccess ? ColorConstant.BLUE1 : ColorConstant.RED1,
                color: isSuccess ? ColorConstant.BLUE : ColorConstant.RED,
                icon: isSuccess ? IconConstant.CheckCircle : IconConstant.Error,
                text: alertMsg,
                visible: isAlert,
              ),
              CustomTap(
                color: pin.length == 5 && customerController.customer.value!.phoneNumber != null
                    ? ColorConstant.PRIMARY
                    : ColorConstant.GREY2,
                onTap: pin.length == 5 && customerController.customer.value!.phoneNumber != null
                    ? () async {
                        await customerController.verifyPhone(pin);
                        if (customerController.customer.value != null &&
                            customerController.customer.value!.isVerified) {
                          setState(() {
                            countdownTimer?.cancel();
                            countdownTimer = null;
                            timerRunning = false;
                          });

                          Get.offNamed(HOME);
                        } else {
                          setState(() {
                            pin = "";
                            otpFieldController.clear();
                            isAlert = true;
                            isSuccess = false;
                            alertMsg = "phone_error".tr;
                          });
                        }
                      }
                    : null,
                child: Text("phone_verify".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
              ),
            ],
          ),
        ),
        Obx(
          () {
            if (customerController.isLoading.value) {
              return CustomLoadingDialog();
            } else {
              return const Center();
            }
          },
        )
      ],
    );
  }
}
