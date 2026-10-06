import 'package:flutter/material.dart';

import '../models/event.dart';
import '../utils/color_constants.dart';
import '../utils/icon_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

class CustomEvent extends StatefulWidget {
  final Event event;
  const CustomEvent({Key? key, required this.event}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CustomEventState();
}

// ignore_for_file: must_be_immutable
class CustomEventState extends State<CustomEvent> {
  bool isDescription = false;

  @override
  Widget build(BuildContext context) {
    return buildEvent(widget.event);
  }

  buildEvent(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        event.eventStartDate != null
            ? Text(event.getDate(), style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3))
            : const Center(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
                child:
                    Text(event.eventName, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1, height: 1.2))),
            IconButton(
              icon: Icon(
                isDescription ? IconConstant.ArrowUp : IconConstant.ArrowDown,
                color: ColorConstant.BLACK3,
              ),
              onPressed: () {
                setState(() {
                  isDescription = !isDescription;
                });
              },
            )
          ],
        ),
        isDescription
            ? Text(event.eventDescription, style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK1, height: 1.5))
            : const Center(),
        const Divider(),
        const SizedBox(height: 5),
      ],
    );
  }
}
