import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user_location.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

class CustomLocation extends StatelessWidget {
  CustomLocation({required this.userLocation});

  UserLocation userLocation;

  @override
  Widget build(BuildContext context) {
    return buildLocation();
  }

  buildLocation() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildIcon(),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(child: Text(userLocation.name, style: CustomTextStyle.txtBody3())),
                Flexible(child: Text(userLocation.address, style: CustomTextStyle.txtBody2(weight: FontWeight.w400))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildIcon() {
    if (userLocation.locationType == EnumLocationType.AIRPORT) return Icon(Icons.local_airport);
    if (userLocation.locationType == EnumLocationType.RESTAURANT) return Icon(Icons.local_restaurant);
    if (userLocation.locationType == EnumLocationType.STORE) return Icon(Icons.store);
    if (userLocation.locationType == EnumLocationType.PARK) return Icon(Icons.park);
    if (userLocation.locationType == EnumLocationType.SCHOOL) return Icon(Icons.school);
    if (userLocation.locationType == EnumLocationType.HOSPITAL) return Icon(Icons.local_hospital);
    if (userLocation.locationType == EnumLocationType.OTHER) return Icon(Icons.location_on);
  }
}
