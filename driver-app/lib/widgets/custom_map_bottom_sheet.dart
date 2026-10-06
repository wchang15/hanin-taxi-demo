import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:map_launcher/map_launcher.dart';

import 'dart:ui';

import '../utils/color_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';

// Future customCancelDialog() async {
//   final List<AvailableMap> availableMaps = await MapLauncher.installedMaps;
//   return Get.bottomSheet(ListView(
//     children: [
//       for (AvailableMap map in availableMaps)
//         ListTile(
//           onTap: () => map.showDirections(
//             destination: Coords(latitude, longitude),
//           ),
//           title: Text(map.mapName),
//           leading: SvgPicture.asset(
//             map.icon,
//             height: 30.0,
//             width: 30.0,
//           ),
//         )
//     ],
//   ));
// }
