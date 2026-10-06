import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';

import '../models/user_login.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/validate_text.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_tap.dart';
import '../widgets/custom_text_arrow.dart';
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
  final customerController = Get.find<CustomerController>();
  bool isFormReady = false;
  AutovalidateMode autoValidate = AutovalidateMode.disabled;
  final errorText = "login_error".tr;

  void formReady() {
    if (usernameController.value.text.isNotEmpty && passwordController.value.text.isNotEmpty) {
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
            actions: [
              Padding(
                padding: getPadding(right: 20, top: 10),
                child: Container(
                  decoration: BoxDecoration(color: ColorConstant.WHITE1, borderRadius: BorderRadius.circular(25)),
                  child: TextButton.icon(
                    onPressed: () {
                      Get.toNamed(LANGUAGE);
                    },
                    icon: Icon(IconConstant.Language, color: ColorConstant.BLACK3),
                    label: Text("language".tr, style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3)),
                  ),
                ),
              ),
            ],
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
                    child: Text("Login_Text".tr, maxLines: null, style: CustomTextStyle.txtTitle2(height: 1.5)),
                  ),
                  Padding(
                    padding: getPadding(left: 8, top: 34, bottom: 10),
                    child: Text("Login_ID".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  CustomTextFormField(
                    controller: usernameController,
                    text: 'Login_ID_Hint'.tr,
                    validate: validateText,
                    onChanged: (text) => setState(() {
                      customerController.setError("");
                      formReady();
                    }),
                  ),
                  Padding(
                    padding: getPadding(left: 8, top: 23, bottom: 10),
                    child: Text("Login_PWD".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  CustomTextFormField(
                    controller: passwordController,
                    text: 'Login_PWD_Hint'.tr,
                    validate: validatePassword,
                    onChanged: (text) => setState(() {
                      customerController.setError("");
                      formReady();
                    }),
                    obscure: true,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomTextArrow(
                        firstWidget: Text("Login_Find_ID_PWD".tr,
                            style: CustomTextStyle.txtCaption2(color: ColorConstant.GREY3)),
                        secondWidget: Icon(IconConstant.ArrowForward, size: 12, color: ColorConstant.GREY3),
                        alignment: Alignment.centerLeft,
                        onPressed: () => Get.toNamed(FINDIDPWD),
                      ),
                      CustomTextArrow(
                        firstWidget:
                            Text("Login_Register".tr, style: CustomTextStyle.txtCaption2(color: ColorConstant.GREY3)),
                        secondWidget: Icon(IconConstant.ArrowForward, size: 12, color: ColorConstant.GREY3),
                        onPressed: () => Get.toNamed(TERMS),
                        alignment: Alignment.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 140),
                ],
              ),
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
                  visible: customerController.errorResponse.value.isNotEmpty,
                ),
              ),
              CustomTap(
                color: isFormReady ? ColorConstant.PRIMARY : ColorConstant.GREY2,
                onTap: isFormReady
                    ? () async {
                        autoValidate = AutovalidateMode.onUserInteraction;
                        if (formGlobalKey.currentState!.validate()) {
                          final userLogin = UserLogin(
                              username: usernameController.value.text, password: passwordController.value.text);
                          await customerController.login(userLogin);
                          if (customerController.customer.value != null) {
                            customerController.setError("");
                            if (customerController.customer.value!.isVerified) {
                              Get.offNamed(HOME);
                            } else {
                              Get.offNamed(LOGIN);
                              Get.offNamed(TERMS);
                              Get.toNamed(REGISTER);
                              Get.toNamed(PHONE);
                            }
                          } else {
                            //customerController.setError(errorText);
                          }
                        } else {
                          customerController.setError(errorText);
                        }
                      }
                    : null,
                child: Text("Login_Button".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
              ),
            ],
          ),
        ),
        Obx(
          () {
            if (customerController.isLoading.value) {
              return CustomLoadingDialog();
            } else {
              return Center();
            }
          },
        )
      ],
    );
  }
}
