import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_loading_dialog.dart';
import '../widgets/custom_switch.dart';
import '../widgets/custom_tap.dart';

class CardAddScreen extends StatefulWidget {
  const CardAddScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CardAddScreenState();
}

class CardAddScreenState extends State<CardAddScreen> {
  final customerController = Get.find<CustomerController>();
  final tripController = Get.find<TripController>();
  CardFormEditController cardFormEditController = CardFormEditController();
  String cardHolderName = '';
  String cardNumber = '';
  String cvvCode = '';
  String expiryDate = '';
  bool completed = false;
  bool isDefault = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title:
                Text("payment_add_card".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () => Get.back(),
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
                  text: customerController.errorResponse.value,
                  visible: customerController.errorResponse.value.isNotEmpty,
                ),
              ),
              CustomTap(
                color: completed ? ColorConstant.PRIMARY : ColorConstant.GREY2,
                onTap: completed
                    ? () async {
                        if (cardFormEditController.details.complete) {
                          final paymentMethod =
                              await Stripe.instance.createPaymentMethod(
                            params: const PaymentMethodParams.card(
                              paymentMethodData: PaymentMethodData(),
                            ),
                          );
                          var res = await customerController.saveCustomerCard(
                              paymentMethod, isDefault);
                          if (res) {
                            tripController.selectCustomerCard(customerController
                                .customer.value!.defaultCardID!);
                            Get.back();
                          }
                        } else {
                          customerController
                              .setError('card_detail_not_complete'.tr);
                        }
                      }
                    : null,
                child: Text("payment_add_card".tr,
                    style:
                        CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CardFormField(
                  controller: cardFormEditController,
                  onCardChanged: (details) => setState(() {
                    completed = details?.complete ?? false;
                  }),
                ),
                CustomSwtich(
                  text: 'card_default'.tr,
                  val: isDefault,
                  onChanged: (value) {
                    setState(() {
                      isDefault = value;
                    });
                  },
                ),
              ],
            ),
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
