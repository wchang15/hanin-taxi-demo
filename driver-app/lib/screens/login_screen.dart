import 'package:driverapp/controllers/driver_controller.dart';
import 'package:driverapp/utils/icon_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user_login.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/validate_text.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_loading_dialog.dart';
import '../widgets/custom_tap.dart';
import '../widgets/custom_text_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LoginScreenState();
}

// ignore_for_file: must_be_immutable
class LoginScreenState extends State<LoginScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final formGlobalKey = GlobalKey<FormState>();
  final driverController = Get.find<DriverController>();
  bool isFormReady = false;
  AutovalidateMode autoValidate = AutovalidateMode.disabled;
  final errorText = "아이디 또는 비밀번호가 올바르지 않습니다";

  void formReady() {
    if (usernameController.value.text.isNotEmpty &&
        passwordController.value.text.isNotEmpty) {
      setState(() {
        isFormReady = true;
      });
    } else {
      setState(() {
        isFormReady = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title: Text("Login_Header".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () => Get.back(),
            ),
          ),
          body: Form(
            autovalidateMode: autoValidate,
            key: formGlobalKey,
            child: Container(
              width: SIZE.width,
              padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
              child: ListView(
                children: [
                  Container(
                    width: getHorizontalSize(188.00),
                    child: Text("Login_Text".tr,
                        maxLines: null,
                        style: CustomTextStyle.txtTitle2(height: 1.5)),
                  ),
                  Padding(
                    padding: getPadding(left: 8, top: 34, bottom: 10),
                    child: Text("Login_ID".tr,
                        style: CustomTextStyle.txtBody3(
                            color: ColorConstant.BLACK1)),
                  ),
                  CustomTextFormField(
                    controller: usernameController,
                    text: 'Login_ID_Hint'.tr,
                    validate: validateText,
                    onChanged: (text) => setState(() {
                      driverController.setError("");
                      formReady();
                    }),
                    suffixIcon: usernameController.value.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              IconConstant.Clear,
                              color: ColorConstant.BLACK,
                            ),
                            onPressed: () => setState(
                              () {
                                usernameController.clear();
                              },
                            ),
                          )
                        : null,
                  ),
                  Padding(
                    padding: getPadding(left: 8, top: 23, bottom: 10),
                    child: Text("Login_PWD".tr,
                        style: CustomTextStyle.txtBody3(
                            color: ColorConstant.BLACK1)),
                  ),
                  CustomTextFormField(
                    controller: passwordController,
                    text: 'Login_PWD_Hint'.tr,
                    validate: validatePassword,
                    onChanged: (text) => setState(() {
                      driverController.setError("");
                      formReady();
                    }),
                    obscure: true,
                    suffixIcon: passwordController.value.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              IconConstant.Clear,
                              color: ColorConstant.BLACK,
                            ),
                            onPressed: () => setState(
                              () {
                                passwordController.clear();
                              },
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Obx(
                () => CustomAlert(
                  bgColor: ColorConstant.RED1,
                  color: ColorConstant.RED,
                  icon: IconConstant.Notification,
                  text: driverController.errorResponse.value,
                  visible: driverController.errorResponse.value.isNotEmpty,
                ),
              ),
              Obx(
                () => CustomTap(
                  color:
                      isFormReady ? ColorConstant.PRIMARY : ColorConstant.GREY2,
                  onTap: !driverController.isLoading.value && isFormReady
                      ? () async {
                          driverController.isLoading.value = true;
                          autoValidate = AutovalidateMode.onUserInteraction;
                          if (formGlobalKey.currentState!.validate()) {
                            final userLogin = UserLogin(
                                username: usernameController.value.text,
                                password: passwordController.value.text);
                            await driverController.login(userLogin);
                            if (driverController.driver.value != null) {
                              driverController.setError("");
                              Get.offAllNamed(HOME);
                            } else {
                              //driverController.setError(errorText);
                            }
                          } else {
                            driverController.setError(errorText);
                          }
                          driverController.isLoading.value = false;
                        }
                      : null,
                  child: Text("Login_Button".tr,
                      style:
                          CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
                ),
              ),
            ],
          ),
        ),
        // Obx(
        //   () {
        //     if (driverController.isLoading.value) {
        //       return CustomLoadingDialog();
        //     } else {
        //       return const Center();
        //     }
        //   },
        // ),
        Obx(() => Visibility(
            visible: driverController.isLoading.value,
            child: CustomLoadingDialog())),
      ],
    );
  }
}
