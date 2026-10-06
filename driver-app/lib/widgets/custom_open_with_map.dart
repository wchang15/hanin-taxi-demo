import 'package:driverapp/controllers/driver_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:map_launcher/map_launcher.dart';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

class CustomOpenWithMap extends StatefulWidget {
  final List<SupportedMap> data;
  const CustomOpenWithMap({Key? key, required this.data}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CustomOpenWithMapState();
}

class CustomOpenWithMapState extends State<CustomOpenWithMap> {
  DriverController driverController = Get.find<DriverController>();
  @override
  Widget build(BuildContext context) {
    return buildOpenWith();
  }

  buildOpenWith() {
    return Container(
      padding: getPadding(all: 20),
      decoration: BoxDecoration(
          color: ColorConstant.WHITE1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("choose_map".tr,
              style: CustomTextStyle.txtTitle2(
                  color: ColorConstant.BLACK, weight: FontWeight.w500)),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              primary: false,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              children: [
                for (SupportedMap map in widget.data)
                  Container(
                    decoration: BoxDecoration(
                        color: driverController.map.value?.id == map.map.id
                            ? ColorConstant.GREY2
                            : null),
                    child: TextButton(
                      onPressed: () async {
                        await driverController.setMapWithMap(map);

                        setState(() {});
                        Get.back();
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.memory(
                            map.iconBytes,
                            height: 40.0,
                            width: 40.0,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            map.name,
                            style: CustomTextStyle.txtCaption2(
                                color: ColorConstant.BLACK,
                                weight: FontWeight.w400),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
