import 'dart:async';

import 'package:flutter/gestures.dart';
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

class FindIDPWDScreen extends StatefulWidget {
  const FindIDPWDScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => FindIDPWDScreenState();
}

enum PhoneNumberStatus { edit, complete, verifyRequested }

enum PasswordMatch { none, match, fail }

// ignore_for_file: must_be_immutable
class FindIDPWDScreenState extends State<FindIDPWDScreen> {
  final idOtpFieldController = OtpFieldController();
  final idPhoneNumberController = TextEditingController();
  final usernameController = TextEditingController();
  final pwdOtpFieldController = OtpFieldController();
  final pwdPhoneNumberController = TextEditingController();

  String idPhoneNumber = "";
  String pwdUserName = "";
  String pwdPhoneNumber = "";

  bool isAlert = false;
  bool isSuccess = false;
  String alertMsg = "";

  bool idIsPhoneComplete = false;
  bool pwdIsPhoneComplete = false;

  String idPin = "";
  String pwdPin = "";

  bool idTimerRunning = false;
  Duration idDuration = const Duration(seconds: 30);
  Timer? idCountdownTimer;
  bool isIDSuccess = false;
  String username = "";

  bool pwdTimerRunning = false;
  Duration pwdDuration = const Duration(seconds: 30);
  Timer? pwdCountdownTimer;
  bool isPWDSuccess = false;
  PasswordMatch isPasswordMatch = PasswordMatch.none;
  int customerID = 0;
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmController = TextEditingController();

  String errorText = "";

  int tabIndex = 0;

  void checkPasswordMatch() {
    if (passwordController.value.text.isNotEmpty && passwordConfirmController.value.text.isNotEmpty) {
      if (passwordController.value.text != passwordConfirmController.value.text) {
        setState(() {
          isPasswordMatch = PasswordMatch.fail;
        });
      } else {
        setState(() {
          isPasswordMatch = PasswordMatch.match;
        });
      }
    } else {
      setState(() {
        isPasswordMatch = PasswordMatch.none;
      });
    }
  }

  void idStartTimer() => idCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => idSetCountDown());

  void pwdStartTimer() => pwdCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => pwdSetCountDown());

  void idSetCountDown() {
    const reduceSecondsBy = 1;
    setState(() {
      final seconds = idDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        idCountdownTimer?.cancel();
        idCountdownTimer = null;
        idTimerRunning = false;
      } else {
        idDuration = Duration(seconds: seconds);
      }
    });
  }

  void pwdSetCountDown() {
    const reduceSecondsBy = 1;
    setState(() {
      final seconds = pwdDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        pwdCountdownTimer?.cancel();
        pwdCountdownTimer = null;
        pwdTimerRunning = false;
      } else {
        pwdDuration = Duration(seconds: seconds);
      }
    });
  }

  @override
  void dispose() {
    pwdCountdownTimer?.cancel();
    idCountdownTimer?.cancel();
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
    final idSeconds = idDuration.inSeconds == 0 ? "" : idDuration.inSeconds;
    final pwdSeconds = pwdDuration.inSeconds == 0 ? "" : pwdDuration.inSeconds;
    var idFind = Container(
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
                  controller: idPhoneNumberController,
                  validate: validateText,
                  onChanged: (text) {
                    setState(() {
                      idIsPhoneComplete = text.length == 12;
                    });
                  },
                  inputFormat: [MaskedInputFormatter('###-###-####', allowedCharMatcher: RegExp(r'^[0-9]+$'))],
                  text: "phone_phone".tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          OTPTextField(
            length: 5,
            controller: idOtpFieldController,
            width: SIZE.width,
            style: const TextStyle(fontSize: 17),
            textFieldAlignment: MainAxisAlignment.spaceAround,
            fieldStyle: FieldStyle.box,
            onChanged: (change) {
              setState(() {
                if (change.length != 5) {
                  idPin = change;
                }
              });
            },
            onCompleted: (curpin) {
              setState(() {
                idPin = curpin;
              });
            },
          ),
          const SizedBox(height: 10),
          CustomTextArrow(
            firstWidget: Text("${"phone_verificationcode".tr} ${idSeconds.toString()}",
                style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK3)),
            secondWidget: const SizedBox(),
            onPressed: idIsPhoneComplete && !idTimerRunning
                ? () async {
                    idPhoneNumber = idPhoneNumberController.value.text;
                    var res = await CustomerServices.getOTP(idPhoneNumber, null);

                    if (res == "") {
                      //success
                      setState(() {
                        idTimerRunning = true;
                        idDuration = const Duration(seconds: 30);
                        isSuccess = true;
                        isAlert = true;
                        alertMsg = "otp_sent".tr;
                      });
                      idStartTimer();
                    } else {
                      setState(() {
                        isSuccess = false;
                        isAlert = true;
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
    );
    var pwdFind = Container(
      width: SIZE.width,
      //alignment: Alignment.center,
      padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: getPadding(left: 8, top: 23, bottom: 10),
            child: Text("register_id".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
          ),
          CustomTextFormField(
            controller: usernameController,
            text: 'Login_ID_Hint'.tr,
            validate: validateText,
            onChanged: (text) => setState(() {}),
          ),
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
                  controller: pwdPhoneNumberController,
                  validate: validateText,
                  onChanged: (text) {
                    setState(() {
                      pwdIsPhoneComplete = text.length == 12;
                    });
                  },
                  inputFormat: [MaskedInputFormatter('###-###-####', allowedCharMatcher: RegExp(r'^[0-9]+$'))],
                  text: "phone_phone".tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          OTPTextField(
            length: 5,
            controller: pwdOtpFieldController,
            width: SIZE.width,
            style: const TextStyle(fontSize: 17),
            textFieldAlignment: MainAxisAlignment.spaceAround,
            fieldStyle: FieldStyle.box,
            onChanged: (change) {
              setState(() {
                if (change.length != 5) {
                  pwdPin = change;
                }
              });
            },
            onCompleted: (curpin) {
              setState(() {
                pwdPin = curpin;
              });
            },
          ),
          const SizedBox(height: 10),
          CustomTextArrow(
            firstWidget: Text("${"phone_verificationcode".tr} ${pwdSeconds.toString()}",
                style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK3)),
            secondWidget: const SizedBox(),
            onPressed: pwdIsPhoneComplete && !pwdTimerRunning
                ? () async {
                    pwdPhoneNumber = pwdPhoneNumberController.value.text;
                    pwdUserName = usernameController.value.text;
                    var res = await CustomerServices.getOTP(pwdPhoneNumber, pwdUserName);

                    if (res == "") {
                      //success
                      setState(() {
                        isAlert = true;
                        isSuccess = true;
                        alertMsg = "otp_sent".tr;
                        pwdTimerRunning = true;
                        pwdDuration = const Duration(seconds: 30);
                      });
                      pwdStartTimer();
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
    );
    var idFound = Container(
      padding: getPadding(left: 16, top: 100, right: 16, bottom: 24),
      color: ColorConstant.WHITE1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("register_id".tr, style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3)),
          const SizedBox(height: 10),
          Text(username, style: CustomTextStyle.txtTitle3(color: ColorConstant.BLACK1)),
        ],
      ),
    );
    var pwdReset = Padding(
      padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: getPadding(left: 8, top: 23, bottom: 10),
            child: Text("register_password".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
          ),
          CustomTextFormField(
            controller: passwordController,
            text: 'register_password_hint1'.tr,
            validate: validatePassword,
            obscure: true,
            onChanged: (text) => setState(() {
              checkPasswordMatch();
            }),
          ),
          const SizedBox(height: 5),
          CustomTextFormField(
            controller: passwordConfirmController,
            text: 'register_password_hint2'.tr,
            validate: validatePassword,
            obscure: true,
            onChanged: (text) => setState(() {
              checkPasswordMatch();
            }),
          ),
          Padding(
            padding: getPadding(left: 8, top: 10),
            child: isPasswordMatch == PasswordMatch.none
                ? Text('register_password_validate'.tr, style: CustomTextStyle.txtCaption1(color: ColorConstant.GREY3))
                : isPasswordMatch == PasswordMatch.fail
                    ? Text('register_password_not_match'.tr,
                        style: CustomTextStyle.txtCaption1(color: ColorConstant.RED))
                    : Text('register_password_match'.tr, style: CustomTextStyle.txtCaption1(color: ColorConstant.BLUE)),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title: Text("find_id_pwd".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () {
                StorageService.deleteAllSecureData();
                Get.toNamed(LOGIN);
              },
            ),
          ),
          body: Padding(
            padding: getPadding(top: 10),
            child: DefaultTabController(
              length: 2,
              child: Scaffold(
                backgroundColor: ColorConstant.WHITE,
                appBar: TabBar(
                  labelColor: ColorConstant.BLACK1,
                  indicatorColor: ColorConstant.PRIMARY,
                  indicatorSize: TabBarIndicatorSize.tab,
                  unselectedLabelColor: ColorConstant.BLACK3,
                  onTap: (int index) {
                    setState(() {
                      tabIndex = index;
                    });
                  },
                  tabs: [
                    Tab(child: Text("register_id".tr, style: CustomTextStyle.txtBody3(color: null))),
                    Tab(child: Text("register_password".tr, style: CustomTextStyle.txtBody3(color: null))),
                  ],
                ),
                body: TabBarView(
                  children: [
                    //ID
                    isIDSuccess ? idFound : idFind,
                    // Password
                    isPWDSuccess ? pwdReset : pwdFind
                  ],
                ),
              ),
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
              isIDSuccess && tabIndex == 0
                  // When ID find is success
                  ? const Center()
                  : CustomTap(
                      color: tabIndex == 0
                          ? idPin.length == 5
                              ? ColorConstant.PRIMARY
                              : ColorConstant.GREY2
                          : isPWDSuccess
                              ? alertMsg == "reset_pwd_success".tr
                                  ? ColorConstant.GREY2
                                  : isPasswordMatch == PasswordMatch.match
                                      ? ColorConstant.PRIMARY
                                      : ColorConstant.GREY2
                              : pwdPin.length == 5 && pwdUserName.isNotEmpty
                                  ? ColorConstant.PRIMARY
                                  : ColorConstant.GREY2,
                      onTap: tabIndex == 0
                          ? idPin.length == 5
                              ? () async {
                                  var res = await CustomerServices.getUsername(idPin, idPhoneNumber);
                                  if (res != "") {
                                    //success
                                    setState(() {
                                      isAlert = false;
                                      isSuccess = true;
                                      username = res;
                                      isIDSuccess = true;
                                      idCountdownTimer?.cancel();
                                      idCountdownTimer = null;
                                      idTimerRunning = false;
                                    });
                                  } else {
                                    //fail
                                    setState(() {
                                      isAlert = true;
                                      isSuccess = false;
                                      alertMsg = "otp_wrong".tr;
                                      idPin = "";
                                      idOtpFieldController.clear();
                                    });
                                  }
                                }
                              : null
                          : isPWDSuccess
                              ? isPasswordMatch == PasswordMatch.match
                                  ? alertMsg == "reset_pwd_success".tr
                                      ? null
                                      : () async {
                                          var res = await CustomerServices.resetPassword(
                                              passwordController.value.text, customerID);
                                          if (res == "") {
                                            //success
                                            setState(() {
                                              isAlert = true;
                                              isSuccess = true;
                                              alertMsg = "reset_pwd_success".tr;
                                            });
                                          } else {
                                            //error
                                            setState(() {
                                              isAlert = true;
                                              isSuccess = false;
                                              alertMsg = "reset_pwd_fail".tr;
                                            });
                                          }
                                        }
                                  : null
                              : pwdPin.length == 5 && pwdUserName.isNotEmpty
                                  ? () async {
                                      var res = await CustomerServices.resetPasswordVerifyPhone(pwdPin, pwdPhoneNumber);
                                      if (res != 0) {
                                        //success
                                        setState(() {
                                          isAlert = false;
                                          isSuccess = true;
                                          customerID = res;
                                          isPWDSuccess = true;
                                          pwdCountdownTimer?.cancel();
                                          pwdCountdownTimer = null;
                                          pwdTimerRunning = false;
                                        });
                                      } else {
                                        //fail
                                        setState(() {
                                          isAlert = true;
                                          isSuccess = false;
                                          alertMsg = "otp_wrong".tr;
                                          pwdPin = "";
                                          pwdOtpFieldController.clear();
                                        });
                                      }
                                    }
                                  : null,
                      child: Text(
                          tabIndex == 0
                              ? "find_id".tr
                              : isPWDSuccess
                                  ? "reset_pwd".tr
                                  : "find_pwd".tr,
                          style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
                    ),
            ],
          ),
        ),
        // Obx(
        //   () {
        //     if (customerController.isLoading.value) {
        //       return CustomLoadingDialog();
        //     } else {
        //       return const Center();
        //     }
        //   },
        // )
      ],
    );
  }
}
