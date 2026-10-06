import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';

import '../services/customer_service.dart';
import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

// Making Credit card images.
class CustomCard extends StatelessWidget {
  CustomCard({
    this.fillColor,
    this.borderColor,
    required this.image,
    required this.number,
    this.visible,
    this.onTap,
    required this.disabled,
    required this.cardID,
    required this.isDefault,
  });

  final customerController = Get.find<CustomerController>();
  final tripController = Get.find<TripController>();

  Color? fillColor;
  Color? borderColor;
  String image;
  Widget number;
  bool? visible;
  GestureTapCallback? onTap;
  bool disabled;
  int cardID;
  bool isDefault;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: buildCard(),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text("Make Default"),
                onTap: () async {
                  await customerController.updateDefaultCard(cardID);
                  tripController.selectCustomerCard(
                      customerController.customer.value!.defaultCardID!);
                },
              ),
              PopupMenuItem(
                child: Text("Delete"),
                onTap: () async {
                  await customerController.deleteCard(cardID);
                  tripController.setCustomerCardID(
                      customerController.customer.value!.defaultCardID!);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  buildCard() {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: getMargin(bottom: 16),
        padding: getPadding(left: 16, top: 19, right: 16, bottom: 19),
        decoration: BoxDecoration(
          color: fillColor ?? ColorConstant.WHITE1,
          border:
              Border.all(color: borderColor ?? Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [stringToImage(), number],
        ),
      ),
    );
  }

  stringToImage() {
    return Text("$image ${isDefault ? "(D)" : ""}");
  }
}
