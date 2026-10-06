import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/services/general_service.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';
import 'package:tax_app/widgets/custom_text_arrow.dart';

import '../models/event.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/image_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_event.dart';
import '../widgets/custom_tap.dart';

class CustomerServiceScreen extends StatefulWidget {
  const CustomerServiceScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CustomerServiceScreenState();
}

// ignore_for_file: must_be_immutable
class CustomerServiceScreenState extends State<CustomerServiceScreen> {
  List<Event> events = [
    Event(
        eventName: "질문1",
        eventDescription:
            "어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요 "),
    Event(
        eventName: "질문2",
        eventDescription:
            "어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요 "),
    Event(
        eventName: "질문3",
        eventDescription:
            "어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요 "),
    Event(
        eventName: "질문4",
        eventDescription:
            "어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요 "),
    Event(
        eventName: "질문5 어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다",
        eventDescription:
            "어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요어쩌구입니다 더미텍스트입니다 안녕하세요 어쩌구입니다 더미텍스트입니다 안녕하세요 "),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //This needs to be changed to a new animation
    return Scaffold(
        backgroundColor: ColorConstant.WHITE,
        appBar: CustomAppBar(
          title: Text("customer_service_header".tr, style: CustomTextStyle.txtTitle2()),
          leading: IconButton(
            icon: Icon(IconConstant.ArrowBack),
            iconSize: 24,
            onPressed: () => Get.back(),
          ),
        ),
        body: Padding(
          padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
          child: ListView(
            children: [for (var event in events) CustomEvent(event: event)],
          ),
        ));
  }
}
