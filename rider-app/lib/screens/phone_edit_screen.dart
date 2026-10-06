import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:get/get.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:tax_app/controllers/customer_controller.dart';
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

class PhoneEditScreen extends StatefulWidget {
  const PhoneEditScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PhoneEditScreenState();
}

enum PhoneNumberStatus { edit, complete, verifyRequested }

// ignore_for_file: must_be_immutable
class PhoneEditScreenState extends State<PhoneEditScreen> {
  final otpFieldController = OtpFieldController();
  final phoneNumberController = TextEditingController();
  final customerController = Get.find<CustomerController>();
  PhoneNumberStatus phoneStatus = PhoneNumberStatus.edit;
  bool timerRunning = false;
  bool phoneNumberEdited = false;
  String pin = "";
  Timer? countdownTimer;
  Duration duration = const Duration(seconds: 30);
  final errorText = "phone_error".tr;
  var savePhoneNumber = "";

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
    phoneNumberController.text = customerController.customer.value!.phoneNumber!;
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
              onPressed: () => Get.back(),
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
                Padding(
                  padding: getPadding(left: 8, top: 23, bottom: 10),
                  child: Text("phone_phone".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomTextFormField(
                        controller: phoneNumberController,
                        validate: validateText,
                        onChanged: (text) {
                          customerController.setError("");
                          phoneNumberEdited = true;
                          if (text.length == 12) {
                            phoneStatus = PhoneNumberStatus.complete;
                          } else {
                            phoneStatus = PhoneNumberStatus.edit;
                          }
                          setState(() {});
                        },
                        inputFormat: [MaskedInputFormatter('###-###-####', allowedCharMatcher: RegExp(r'^[0-9]+$'))],
                        text: "phone_phone".tr,
                      ),
                    ),
                  ],
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
                    customerController.setError("");
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
                  firstWidget: Text("${"phone_verificationcode".tr} $seconds",
                      style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK3)),
                  secondWidget: const SizedBox(),
                  onPressed: phoneStatus == PhoneNumberStatus.complete && !timerRunning
                      ? () async {
                          if (phoneNumberEdited) {
                            await customerController.editPhone(phoneNumberController.value.text, isVerified: true);
                          }
                          //await customerController.requestVerification();
                          if (customerController.errorResponse.value.isEmpty) {
                            setState(() {
                              timerRunning = true;
                              duration = const Duration(seconds: 30);
                              savePhoneNumber = phoneNumberController.value.text;
                            });
                            startTimer();
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
              Obx(
                () => CustomAlert(
                  bgColor: ColorConstant.RED1,
                  color: ColorConstant.RED,
                  icon: IconConstant.Notification,
                  text: customerController.errorResponse.value,
                  visible: customerController.errorResponse.value != "",
                ),
              ),
              CustomTap(
                color: pin.length == 5 &&
                        phoneStatus == PhoneNumberStatus.complete &&
                        customerController.customer.value!.phoneNumber != null
                    ? ColorConstant.PRIMARY
                    : ColorConstant.GREY2,
                onTap: pin.length == 5 &&
                        phoneStatus == PhoneNumberStatus.complete &&
                        customerController.customer.value!.phoneNumber != null
                    ? () async {
                        await customerController.verifyPhone(pin, isVerified: true, phoneNumber: savePhoneNumber);
                        if (customerController.customer.value != null &&
                            customerController.customer.value!.isVerified) {
                          setState(() {
                            countdownTimer?.cancel();
                            countdownTimer = null;
                            timerRunning = false;
                          });
                          customerController.customer.value!.phoneNumber = savePhoneNumber;
                          Get.back();
                        } else {
                          setState(() {
                            pin = "";
                            otpFieldController.clear();
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
